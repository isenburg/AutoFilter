import Foundation
import Combine

enum WorkedBeforeUnit: String, CaseIterable, Identifiable, Codable {
    case hours = "hours"
    case days = "days"
    case months = "months"
    case years = "years"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .hours: return L("unit.hour.plural")
        case .days: return L("unit.day.plural")
        case .months: return L("unit.month.plural")
        case .years: return L("unit.year.plural")
        }
    }
    
    var singularTitle: String {
        switch self {
        case .hours: return L("unit.hour.singular")
        case .days: return L("unit.day.singular")
        case .months: return L("unit.month.singular")
        case .years: return L("unit.year.singular")
        }
    }
    
    func cutoffDate(duration: Int, from date: Date = Date()) -> Date? {
        let calendar = Calendar.current
        let val = max(0, min(999, duration))
        switch self {
        case .hours:
            return calendar.date(byAdding: .hour, value: -val, to: date)
        case .days:
            return calendar.date(byAdding: .day, value: -val, to: date)
        case .months:
            return calendar.date(byAdding: .month, value: -val, to: date)
        case .years:
            return calendar.date(byAdding: .year, value: -val, to: date)
        }
    }
}

class LoTWManager: ObservableObject {
    @Published var isDownloading = false
    @Published var errorMessage: String?
    @Published var logHistory: [String] = []
    @Published var logbook: [QSOEntry] = []
    
    private var workedSet = Set<String>()
    private(set) var workedGridsSet = Set<String>()
    private(set) var workedGrids6Set = Set<String>()
    private(set) var latestQSOByCallBand: [String: Date] = [:]
    
    init() {
        loadLog()
    }
    
    func addLog(_ message: String) {
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
            var newGrids = Set<String>()
            var newGrids6 = Set<String>()
            var newLatestQSO = [String: Date]()
            newSet.reserveCapacity(qsos.count)
            newLatestQSO.reserveCapacity(qsos.count)
            for qso in qsos {
                let call = qso.callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let b = qso.band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                if !call.isEmpty && !b.isEmpty {
                    let key = "\(call)_\(b)"
                    newSet.insert(key)
                    if let dt = qso.qsoDateTime {
                        if let existing = newLatestQSO[key] {
                            if dt > existing {
                                newLatestQSO[key] = dt
                            }
                        } else {
                            newLatestQSO[key] = dt
                        }
                    }
                }
                let cleanGrid = qso.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if cleanGrid.count >= 4 {
                    newGrids.insert(String(cleanGrid.prefix(4)))
                }
                if cleanGrid.count >= 6 {
                    newGrids6.insert(String(cleanGrid.prefix(6)))
                }
            }
            
            DispatchQueue.main.async {
                self?.logbook = qsos
                self?.workedSet = newSet
                self?.workedGridsSet = newGrids
                self?.workedGrids6Set = newGrids6
                self?.latestQSOByCallBand = newLatestQSO
                self?.addLog("SQLite Logbuch geladen: \(qsos.count) QSOs (\(newGrids.count) 4-Stellen Grids / \(newGrids6.count) 6-Stellen Grids).")
            }
        }
    }
    
    func downloadLoTW(username: String, password: String, fullSync: Bool = true) {
        let allowedCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+=?/#"))
        let safeUser = username.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? username
        let safePass = password.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? password
        
        let startDateStr = fullSync ? "1900-01-01" : getStartDateString()
        
        guard let url = URL(string: "https://lotw.arrl.org/lotwuser/lotwreport.adi?login=\(safeUser)&password=\(safePass)&qso_query=1&qso_qsos=1&qso_startdate=\(startDateStr)") else {
            addLog("Fehler: Ungültige Zugangsdaten für URL")
            return
        }
        
        isDownloading = true
        errorMessage = nil
        addLog("Starte LoTW Sync für User '\(username)' (Vollständig ab \(startDateStr))...")
        
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
        
        // Sofort im Speicher-Set registrieren (damit hasWorked / hasWorkedGrid sofort true liefert!)
        DispatchQueue.main.async { [weak self] in
            for entry in newEntries {
                let call = entry.callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let b = entry.band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                if !call.isEmpty && !b.isEmpty {
                    let key = "\(call)_\(b)"
                    self?.workedSet.insert(key)
                    if let dt = entry.qsoDateTime {
                        if let existing = self?.latestQSOByCallBand[key] {
                            if dt > existing {
                                self?.latestQSOByCallBand[key] = dt
                            }
                        } else {
                            self?.latestQSOByCallBand[key] = dt
                        }
                    }
                }
                let cleanGrid = entry.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if cleanGrid.count >= 4 {
                    self?.workedGridsSet.insert(String(cleanGrid.prefix(4)))
                }
                if cleanGrid.count >= 6 {
                    self?.workedGrids6Set.insert(String(cleanGrid.prefix(6)))
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let addedCount = DatabaseManager.shared.insertQSOs(newEntries)
            let updatedLog = DatabaseManager.shared.fetchAllQSOs()
            
            var newSet = Set<String>()
            var newGrids = Set<String>()
            var newGrids6 = Set<String>()
            var newLatestQSO = [String: Date]()
            newSet.reserveCapacity(updatedLog.count)
            newLatestQSO.reserveCapacity(updatedLog.count)
            for qso in updatedLog {
                let call = qso.callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let b = qso.band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                if !call.isEmpty && !b.isEmpty {
                    let key = "\(call)_\(b)"
                    newSet.insert(key)
                    if let dt = qso.qsoDateTime {
                        if let existing = newLatestQSO[key] {
                            if dt > existing {
                                newLatestQSO[key] = dt
                            }
                        } else {
                            newLatestQSO[key] = dt
                        }
                    }
                }
                let cleanGrid = qso.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if cleanGrid.count >= 4 {
                    newGrids.insert(String(cleanGrid.prefix(4)))
                }
                if cleanGrid.count >= 6 {
                    newGrids6.insert(String(cleanGrid.prefix(6)))
                }
            }
            
            DispatchQueue.main.async {
                self?.logbook = updatedLog
                self?.workedSet = newSet
                self?.workedGridsSet = newGrids
                self?.workedGrids6Set = newGrids6
                self?.latestQSOByCallBand = newLatestQSO
                self?.addLog("SQLite Logbuch aktualisiert: +\(addedCount) neue QSOs. Gesamt: \(updatedLog.count) QSOs (\(newGrids.count) 4-Stellen Grids / \(newGrids6.count) 6-Stellen Grids).")
            }
        }
    }
    
    func hasWorked(callsign: String, band: String) -> Bool {
        guard !callsign.isEmpty, !band.isEmpty else { return false }
        let cleanCall = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBand = band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        return workedSet.contains("\(cleanCall)_\(cleanBand)")
    }
    
    func lastWorkedDate(callsign: String, band: String) -> Date? {
        guard !callsign.isEmpty, !band.isEmpty else { return nil }
        let cleanCall = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanBand = band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        return latestQSOByCallBand["\(cleanCall)_\(cleanBand)"]
    }
    
    func hasWorkedRecently(callsign: String, band: String, duration: Int, unit: WorkedBeforeUnit) -> Bool {
        guard !callsign.isEmpty, !band.isEmpty else { return false }
        guard hasWorked(callsign: callsign, band: band) else { return false }
        guard let cutoff = unit.cutoffDate(duration: duration) else { return true }
        
        if let lastDate = lastWorkedDate(callsign: callsign, band: band) {
            return lastDate > cutoff
        }
        return true
    }

    func hasWorkedGrid(_ grid: String) -> Bool {
        let clean = grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count >= 4 else { return false }
        let grid4 = String(clean.prefix(4))
        return workedGridsSet.contains(grid4)
    }

    func hasWorkedGrid6(_ grid: String) -> Bool {
        let clean = grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count >= 6 else { return false }
        let grid6 = String(clean.prefix(6))
        return workedGrids6Set.contains(grid6)
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
    
    func resetSyncDateTo1900() {
        UserDefaults.standard.set("1900-01-01", forKey: "overrideSyncStartDate")
        addLog("Sync-Startdatum zurückgesetzt auf 1900-01-01.")
    }
    
    func clearLogbookAndResetSync() {
        let deletedCount = DatabaseManager.shared.clearAllQSOs()
        UserDefaults.standard.set("1900-01-01", forKey: "overrideSyncStartDate")
        loadLog()
        addLog("Logbuch zurückgesetzt (\(deletedCount) Einträge geleert). Sync-Startdatum auf 1900-01-01 gesetzt.")
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
