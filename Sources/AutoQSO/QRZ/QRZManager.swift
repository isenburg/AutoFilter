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
    
    func downloadQRZ(apiKey: String, fullSync: Bool = true, completion: @escaping ([QSOEntry]) -> Void) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            addLog("Fehler: Kein QRZ API Key angegeben")
            return
        }
        
        let allowedCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?/#"))
        let safeKey = trimmedKey.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? trimmedKey
        
        let startDateStr = fullSync ? "1900-01-01" : getStartDateString()
        
        guard let url = URL(string: "https://logbook.qrz.com/api?KEY=\(safeKey)&ACTION=FETCH&OPTION=TYPE:ADIF,MODSINCE:\(startDateStr)") else {
            addLog("Fehler: Ungültiger QRZ API Key")
            return
        }
        
        isDownloading = true
        errorMessage = nil
        addLog("Starte QRZ.com Logbuch Sync (Vollständig ab \(startDateStr))...")
        
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
                        adifText = QRZManager.robustURLDecode(rawData)
                    } else {
                        adifText = QRZManager.robustURLDecode(str)
                    }
                    
                    let newEntries = ADIFParser.parseQSOs(from: adifText)
                    DispatchQueue.main.async {
                        self?.addLog("QRZ Sync abgeschlossen: \(newEntries.count) QSOs aus QRZ.com geladen.")
                        completion(newEntries)
                    }
                }
            }
        }
        task.resume()
    }
    
    static func robustURLDecode(_ input: String) -> String {
        if let decoded = input.removingPercentEncoding {
            return decoded
        }
        
        var s = input
        s = s.replacingOccurrences(of: "&lt;", with: "<", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "&gt;", with: ">", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "&amp;", with: "&", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "%3c", with: "<", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "%3e", with: ">", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "%3a", with: ":", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "%20", with: " ")
        s = s.replacingOccurrences(of: "%0d", with: "\r", options: .caseInsensitive)
        s = s.replacingOccurrences(of: "%0a", with: "\n", options: .caseInsensitive)
        
        let regex = try? NSRegularExpression(pattern: "%([0-9A-Fa-f]{2})")
        if let regex = regex {
            let nsString = s as NSString
            let matches = regex.matches(in: s, options: [], range: NSRange(location: 0, length: nsString.length)).reversed()
            for match in matches {
                let hexStr = nsString.substring(with: match.range(at: 1))
                if let byteVal = UInt8(hexStr, radix: 16) {
                    let charStr = String(UnicodeScalar(byteVal))
                    let fullRange = match.range(at: 0)
                    s = (s as NSString).replacingCharacters(in: fullRange, with: charStr)
                }
            }
        }
        return s
    }
    
    func resetSyncDateTo1900() {
        UserDefaults.standard.set("1900-01-01", forKey: "overrideSyncStartDate")
        addLog("QRZ Sync-Startdatum zurückgesetzt auf 1900-01-01.")
    }
    
    private func getStartDateString() -> String {
        if let overrideDate = UserDefaults.standard.string(forKey: "overrideSyncStartDate"), !overrideDate.isEmpty {
            UserDefaults.standard.removeObject(forKey: "overrideSyncStartDate")
            return overrideDate
        }
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let latestDate = DatabaseManager.shared.getLatestQSODate(),
           let twoDaysBefore = calendar.date(byAdding: .day, value: -2, to: latestDate) {
            return formatter.string(from: twoDaysBefore)
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
