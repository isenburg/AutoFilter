import Foundation
import Combine

class LoTWManager: ObservableObject {
    @Published var isDownloading = false
    @Published var errorMessage: String?
    @Published var logHistory: [String] = []
    @Published var logbook: [QSOEntry] = []
    
    private var workedSet = Set<String>()
    
    init() {
        loadLog()
    }
    
    private func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.logHistory.append("[\(ts)] \(message)")
        }
    }
    
    func loadLog() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let qsos = DatabaseManager.shared.fetchAllQSOs()
            var newSet = Set<String>()
            newSet.reserveCapacity(qsos.count)
            for qso in qsos {
                newSet.insert("\(qso.callsign.uppercased())_\(qso.band.uppercased())")
            }
            
            DispatchQueue.main.async {
                self?.logbook = qsos
                self?.workedSet = newSet
                self?.addLog("SQLite Logbuch geladen: \(qsos.count) QSOs.")
            }
        }
    }
    
    func downloadLoTW(username: String, password: String) {
        let allowedCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?/#"))
        let safeUser = username.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? username
        let safePass = password.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? password
        
        let startDateStr = getStartDateString()
        
        guard let url = URL(string: "https://lotw.arrl.org/lotwuser/lotwreport.adi?login=\(safeUser)&password=\(safePass)&qso_query=1&qso_qsos=1&qso_startdate=\(startDateStr)") else {
            addLog("Fehler: Ungültige Zugangsdaten für URL")
            return
        }
        
        isDownloading = true
        errorMessage = nil
        addLog("Starte LoTW Sync für User '\(username)' (ab Startdatum: \(startDateStr))...")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.addLog("Netzwerkfehler: \(error.localizedDescription)")
                    return
                }
                guard let data = data, let str = String(data: data, encoding: .utf8) else {
                    self?.errorMessage = "Invalid data received"
                    self?.addLog("Fehler: Ungültige Daten empfangen")
                    return
                }
                
                if str.contains("Username/Password Incorrect") || str.contains("Error") {
                    self?.errorMessage = "LoTW Login Failed"
                    self?.addLog("Fehler: Benutzername oder Passwort falsch")
                    return
                }
                
                self?.addLog("Daten empfangen (\(data.count / 1024) KB). Parse ADIF...")
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let newEntries = ADIFParser.parseQSOs(from: str)
                    self?.mergeEntries(newEntries)
                }
            }
        }
        task.resume()
    }
    
    func mergeEntries(_ newEntries: [QSOEntry]) {
        guard !newEntries.isEmpty else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let addedCount = DatabaseManager.shared.insertQSOs(newEntries)
            let updatedLog = DatabaseManager.shared.fetchAllQSOs()
            
            var newSet = Set<String>()
            newSet.reserveCapacity(updatedLog.count)
            for qso in updatedLog {
                newSet.insert("\(qso.callsign.uppercased())_\(qso.band.uppercased())")
            }
            
            DispatchQueue.main.async {
                self?.logbook = updatedLog
                self?.workedSet = newSet
                self?.addLog("SQLite Logbuch aktualisiert: +\(addedCount) neue QSOs. Gesamt: \(updatedLog.count) QSOs.")
            }
        }
    }
    
    func hasWorked(callsign: String, band: String) -> Bool {
        guard !callsign.isEmpty, !band.isEmpty else { return false }
        return workedSet.contains("\(callsign.uppercased())_\(band.uppercased())")
    }
    
    func workedBands(for callsign: String) -> [String] {
        guard !callsign.isEmpty else { return [] }
        let target = callsign.uppercased()
        return logbook
            .filter { $0.callsign.uppercased() == target }
            .map { $0.band.uppercased() }
            .reduce(into: Set<String>()) { $0.insert($1) }
            .sorted()
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
    
    func deleteQSOs(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let deletedCount = DatabaseManager.shared.deleteQSOs(ids: ids)
            let updatedLog = DatabaseManager.shared.fetchAllQSOs()
            
            var newSet = Set<String>()
            newSet.reserveCapacity(updatedLog.count)
            for qso in updatedLog {
                newSet.insert("\(qso.callsign.uppercased())_\(qso.band.uppercased())")
            }
            
            DispatchQueue.main.async {
                self?.logbook = updatedLog
                self?.workedSet = newSet
                self?.addLog("Logbuch: \(deletedCount) Eintrag/Einträge gelöscht.")
            }
        }
    }
}
