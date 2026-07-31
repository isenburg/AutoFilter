import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.autoqso.database", qos: .userInitiated)
    
    private let dbPath: String = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("autoqso_log.sqlite").path
    }()
    
    init() {
        openDatabase()
        createTables()
        migrateJSONIfNeeded()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Fehler beim Öffnen der SQLite Datenbank")
        } else {
            print("SQLite Datenbank geöffnet: \(dbPath)")
        }
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
        
        var insertedCount = 0
        dbQueue.sync {
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            let insertSQL = "INSERT OR IGNORE INTO qsos (id, callsign, band, mode, qso_date, time_on, dxcc, unique_key) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
                for qso in entries {
                    let idStr = qso.id.uuidString
                    let callStr = qso.callsign.uppercased()
                    let bandStr = qso.band.uppercased()
                    let modeStr = qso.mode.uppercased()
                    let keyStr = qso.uniqueKey
                    
                    sqlite3_bind_text(statement, 1, (idStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 2, (callStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 3, (bandStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 4, (modeStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 5, (qso.qsoDate as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 6, (qso.timeOn as NSString).utf8String, -1, nil)
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
}
