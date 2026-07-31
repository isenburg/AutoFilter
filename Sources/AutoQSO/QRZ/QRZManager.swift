import Foundation
import Combine

class QRZManager: ObservableObject {
    @Published var isDownloading = false
    @Published var errorMessage: String?
    @Published var logHistory: [String] = []
    
    private func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.logHistory.append("[\(ts)] \(message)")
        }
    }
    
    func downloadQRZ(apiKey: String, completion: @escaping ([QSOEntry]) -> Void) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            addLog("Fehler: Kein QRZ API Key angegeben")
            return
        }
        
        let allowedCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?/#"))
        let safeKey = trimmedKey.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? trimmedKey
        
        let startDateStr = getStartDateString()
        
        guard let url = URL(string: "https://logbook.qrz.com/api?KEY=\(safeKey)&ACTION=FETCH&OPTION=TYPE:ADIF,MODSINCE:\(startDateStr)") else {
            addLog("Fehler: Ungültiger QRZ API Key")
            return
        }
        
        isDownloading = true
        errorMessage = nil
        addLog("Starte QRZ.com Logbuch Sync (ab Startdatum: \(startDateStr))...")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.addLog("QRZ Netzwerkfehler: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data, let str = String(data: data, encoding: .utf8) else {
                    self?.errorMessage = "Ungültige Daten von QRZ.com empfangen"
                    self?.addLog("Fehler: Ungültige Antwort von QRZ.com")
                    return
                }
                
                if str.contains("RESULT=FAIL") || str.contains("RESULT=AUTH") {
                    let reason = self?.extractParam("REASON", from: str) ?? "Authentifizierung fehlgeschlagen"
                    self?.errorMessage = "QRZ Fehler: \(reason)"
                    self?.addLog("QRZ Fehler: \(reason)")
                    return
                }
                
                self?.addLog("QRZ Daten empfangen (\(data.count / 1024) KB). Parse ADIF...")
                
                DispatchQueue.global(qos: .userInitiated).async {
                    var adifText = str
                    if let dataRange = str.range(of: "DATA=") {
                        let rawData = String(str[dataRange.upperBound...])
                        adifText = rawData.removingPercentEncoding ?? rawData
                    } else {
                        adifText = str.removingPercentEncoding ?? str
                    }
                    
                    let newEntries = ADIFParser.parseQSOs(from: adifText)
                    DispatchQueue.main.async {
                        self?.addLog("QRZ Sync abgeschlossen: \(newEntries.count) QSOs verarbeitet.")
                        completion(newEntries)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func getStartDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let latestDate = DatabaseManager.shared.getLatestQSODate(),
           let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: latestDate) {
            return formatter.string(from: oneDayBefore)
        }
        
        return "1900-01-01"
    }
    
    private func extractParam(_ param: String, from text: String) -> String? {
        let prefix = "\(param)="
        guard let range = text.range(of: prefix) else { return nil }
        let tail = text[range.upperBound...]
        let line = tail.components(separatedBy: .newlines).first ?? String(tail)
        return line.components(separatedBy: "&").first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
