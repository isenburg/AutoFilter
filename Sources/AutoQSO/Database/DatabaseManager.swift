import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.autoqso.database", qos: .userInitiated)
    
    private(set) var currentDbPath: String = ""
    
    static func getStorageDirectory() -> URL {
        let mode = UserDefaults.standard.string(forKey: "storageLocationMode") ?? "default"
        
        var targetURL: URL
        if mode == "icloud" {
            if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/AutoQSO") {
                targetURL = ubiquityURL
            } else {
                let home = FileManager.default.homeDirectoryForCurrentUser
                targetURL = home.appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/AutoQSO")
            }
        } else if mode == "custom", let customPath = UserDefaults.standard.string(forKey: "customStoragePath"), !customPath.isEmpty {
            targetURL = URL(fileURLWithPath: customPath)
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            targetURL = docs.appendingPathComponent("AutoQSO")
        }
        
        try? FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)
        return targetURL
    }
    
    init() {
        let targetDir = DatabaseManager.getStorageDirectory()
        currentDbPath = targetDir.appendingPathComponent("autoqso_log.sqlite").path
        openDatabase(at: currentDbPath)
        createTables()
        migrateJSONIfNeeded()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase(at path: String) {
        dbQueue.sync {
            if sqlite3_open(path, &db) != SQLITE_OK {
                print("Fehler beim Öffnen der SQLite Datenbank an \(path)")
            } else {
                print("SQLite Datenbank geöffnet: \(path)")
            }
        }
    }
    
    func switchStorageLocation() {
        let newDir = DatabaseManager.getStorageDirectory()
        let newPath = newDir.appendingPathComponent("autoqso_log.sqlite").path
        
        guard newPath != currentDbPath else { return }
        
        let oldPath = currentDbPath
        dbQueue.sync {
            if db != nil {
                sqlite3_close(db)
                db = nil
            }
            
            if FileManager.default.fileExists(atPath: oldPath) && !FileManager.default.fileExists(atPath: newPath) {
                try? FileManager.default.copyItem(atPath: oldPath, toPath: newPath)
                print("SQLite Datenbank kopiert von \(oldPath) nach: \(newPath)")
            }
            
            currentDbPath = newPath
            if sqlite3_open(currentDbPath, &db) != SQLITE_OK {
                print("Fehler beim Öffnen der neuen SQLite Datenbank")
            } else {
                print("Erfolgreich gewechselt zu SQLite Datenbank: \(currentDbPath)")
            }
        }
        createTables()
    }
    
    private func createTables() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS qsos (
            id TEXT PRIMARY KEY,
            callsign TEXT NOT NULL,
            band TEXT NOT NULL,
            mode TEXT NOT NULL,
            qso_date TEXT NOT NULL,
            time_on TEXT NOT NULL,
            dxcc TEXT,
            unique_key TEXT UNIQUE NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_call_band ON qsos(callsign, band);
        CREATE INDEX IF NOT EXISTS idx_unique_key ON qsos(unique_key);
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createTableSQL, nil, nil, &errMsg) != SQLITE_OK {
            if let error = errMsg {
                print("Fehler beim Erstellen der Tabelle: \(String(cString: error))")
                sqlite3_free(errMsg)
            }
        }
    }
    
    private func migrateJSONIfNeeded() {
        let jsonURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("autoqso_log.json")
        guard FileManager.default.fileExists(atPath: jsonURL.path) else { return }
        
        print("Starte JSON-zu-SQLite Migration...")
        guard let data = try? Data(contentsOf: jsonURL),
              let saved = try? JSONDecoder().decode([QSOEntry].self, from: data), !saved.isEmpty else {
            try? FileManager.default.removeItem(at: jsonURL)
            return
        }
        
        let inserted = insertQSOs(saved)
        print("Migration abgeschlossen: \(inserted) QSOs in SQLite importiert.")
        
        // Rename json file to mark migration complete
        let backupURL = jsonURL.deletingPathExtension().appendingPathExtension("json.bak")
        try? FileManager.default.moveItem(at: jsonURL, to: backupURL)
    }
    
    @discardableResult
    func insertQSOs(_ entries: [QSOEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        // In-Memory Deduplication: nur eindeutige uniqueKeys aus dieser Charge behalten
        var seenKeys = Set<String>()
        let deduped = entries.filter { qso in
            let key = qso.uniqueKey
            guard !key.isEmpty else { return false }
            if seenKeys.contains(key) { return false }
            seenKeys.insert(key)
            return true
        }
        
        var insertedCount = 0
        dbQueue.sync {
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            // INSERT OR IGNORE verhindert Doubletten via unique_key UNIQUE Constraint
            let insertSQL = """
            INSERT OR IGNORE INTO qsos (id, callsign, band, mode, qso_date, time_on, dxcc, unique_key)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
            """
            
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
                for qso in deduped {
                    let idStr = qso.id.uuidString
                    // Normalisierung: Großschreibung, Leerzeichen entfernen
                    let callStr = qso.callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let bandStr = qso.band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                        .replacingOccurrences(of: " ", with: "")
                    let modeStr = qso.mode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanDate = qso.qsoDate
                        .replacingOccurrences(of: "-", with: "")
                        .replacingOccurrences(of: "/", with: "")
                        .replacingOccurrences(of: ".", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    // Zeitformat auf HHMM normalisieren (Sekunden weglassen)
                    let rawTime = qso.timeOn.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let timeNorm = rawTime.count >= 4 ? String(rawTime.prefix(4)) : rawTime
                    let keyStr = "\(callStr)_\(bandStr)_\(modeStr)_\(cleanDate)_\(timeNorm)"
                    
                    guard !callStr.isEmpty, !bandStr.isEmpty, !cleanDate.isEmpty else { continue }
                    
                    sqlite3_bind_text(statement, 1, (idStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 2, (callStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 3, (bandStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 4, (modeStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 5, (cleanDate as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 6, (timeNorm as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 7, (qso.dxcc as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 8, (keyStr as NSString).utf8String, -1, nil)
                    
                    if sqlite3_step(statement) == SQLITE_DONE {
                        if sqlite3_changes(db) > 0 {
                            insertedCount += 1
                        }
                    }
                    sqlite3_reset(statement)
                }
                sqlite3_finalize(statement)
            }
            
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
        return insertedCount
    }
    
    func fetchAllQSOs() -> [QSOEntry] {
        var results = [QSOEntry]()
        dbQueue.sync {
            let querySQL = "SELECT id, callsign, band, mode, qso_date, time_on, dxcc FROM qsos ORDER BY qso_date DESC, time_on DESC;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let idStr = String(cString: sqlite3_column_text(statement, 0))
                    let call = String(cString: sqlite3_column_text(statement, 1))
                    let band = String(cString: sqlite3_column_text(statement, 2))
                    let mode = String(cString: sqlite3_column_text(statement, 3))
                    let qsoDate = String(cString: sqlite3_column_text(statement, 4))
                    let timeOn = String(cString: sqlite3_column_text(statement, 5))
                    let dxcc = sqlite3_column_text(statement, 6) != nil ? String(cString: sqlite3_column_text(statement, 6)) : ""
                    
                    let uuid = UUID(uuidString: idStr) ?? UUID()
                    let qso = QSOEntry(id: uuid, callsign: call, band: band, mode: mode, qsoDate: qsoDate, timeOn: timeOn, dxcc: dxcc)
                    results.append(qso)
                }
                sqlite3_finalize(statement)
            }
        }
        return results
    }
    
    func hasWorked(callsign: String, band: String) -> Bool {
        guard !callsign.isEmpty, !band.isEmpty else { return false }
        var found = false
        dbQueue.sync {
            let querySQL = "SELECT 1 FROM qsos WHERE callsign = ? AND band = ? LIMIT 1;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                let callUpper = callsign.uppercased()
                let bandUpper = band.uppercased()
                sqlite3_bind_text(statement, 1, (callUpper as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (bandUpper as NSString).utf8String, -1, nil)
                
                if sqlite3_step(statement) == SQLITE_ROW {
                    found = true
                }
                sqlite3_finalize(statement)
            }
        }
        return found
    }
    
    func workedBands(for callsign: String) -> [String] {
        guard !callsign.isEmpty else { return [] }
        var bands = [String]()
        dbQueue.sync {
            let querySQL = "SELECT DISTINCT band FROM qsos WHERE callsign = ? ORDER BY band ASC;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                let callUpper = callsign.uppercased()
                sqlite3_bind_text(statement, 1, (callUpper as NSString).utf8String, -1, nil)
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    let band = String(cString: sqlite3_column_text(statement, 0))
                    bands.append(band)
                }
                sqlite3_finalize(statement)
            }
        }
        return bands
    }
    
    func getLatestQSODate() -> Date? {
        var latestDateStr: String?
        dbQueue.sync {
            let querySQL = "SELECT qso_date FROM qsos WHERE qso_date IS NOT NULL AND qso_date != '' ORDER BY qso_date DESC LIMIT 50;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let rawDate = String(cString: sqlite3_column_text(statement, 0))
                    let clean = rawDate.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !clean.isEmpty {
                        latestDateStr = clean
                        break
                    }
                }
                sqlite3_finalize(statement)
            }
        }
        
        guard let str = latestDateStr else { return nil }
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if str.count >= 8 {
            let yearMonthDay = String(str.prefix(8))
            formatter.dateFormat = "yyyyMMdd"
            if let date = formatter.date(from: yearMonthDay) {
                return date
            }
        }
        
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }
    
    @discardableResult
    func deleteQSOs(ids: Set<UUID>) -> Int {
        guard !ids.isEmpty else { return 0 }
        var deletedCount = 0
        dbQueue.sync {
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            let deleteSQL = "DELETE FROM qsos WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
                for id in ids {
                    let idStr = id.uuidString
                    sqlite3_bind_text(statement, 1, (idStr as NSString).utf8String, -1, nil)
                    if sqlite3_step(statement) == SQLITE_DONE {
                        if sqlite3_changes(db) > 0 {
                            deletedCount += 1
                        }
                    }
                    sqlite3_reset(statement)
                }
                sqlite3_finalize(statement)
            }
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
        return deletedCount
    }
    
    @discardableResult
    func clearAllQSOs() -> Int {
        var count = 0
        dbQueue.sync {
            let countSQL = "SELECT COUNT(*) FROM qsos;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, countSQL, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(stmt, 0))
                }
                sqlite3_finalize(stmt)
            }
            
            sqlite3_exec(db, "DELETE FROM qsos;", nil, nil, nil)
        }
        return count
    }
}
