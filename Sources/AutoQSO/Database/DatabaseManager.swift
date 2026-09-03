import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.autoqso.database", qos: .userInitiated)
    
    private(set) var currentDbPath: String = ""
    
    private var userDefaultsObserver: NSObjectProtocol?
    private var isSyncingFromDB = false
    private var debounceWorkItem: DispatchWorkItem?
    
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
        cleanupExistingDuplicates()
        
        // Initialer Abgleich zwischen SQLite Datenbank und UserDefaults
        let existingSettings = getAllSettings()
        if !existingSettings.isEmpty {
            syncDatabaseToUserDefaults()
        } else {
            syncUserDefaultsToDatabase()
        }
        
        startObservingUserDefaults()
    }
    
    deinit {
        stopObservingUserDefaults()
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
        
        stopObservingUserDefaults()
        
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
        
        let existingSettings = getAllSettings()
        if !existingSettings.isEmpty {
            syncDatabaseToUserDefaults()
        } else {
            syncUserDefaultsToDatabase()
        }
        
        startObservingUserDefaults()
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
            grid TEXT,
            unique_key TEXT UNIQUE NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_call_band ON qsos(callsign, band);
        CREATE INDEX IF NOT EXISTS idx_unique_key ON qsos(unique_key);
        
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key);
        
        CREATE TABLE IF NOT EXISTS filter_profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            is_system INTEGER NOT NULL,
            auto_band TEXT,
            auto_mode TEXT,
            data_json TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_filter_profiles_id ON filter_profiles(id);
        """
        
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, createTableSQL, nil, nil, &errMsg) != SQLITE_OK {
            if let error = errMsg {
                print("Fehler beim Erstellen der Tabellen: \(String(cString: error))")
                sqlite3_free(errMsg)
            }
        }
        // Migration for existing tables created without grid column
        sqlite3_exec(db, "ALTER TABLE qsos ADD COLUMN grid TEXT;", nil, nil, nil)
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
    
    static func timeMinutes(from timeStr: String) -> Int? {
        let clean = timeStr.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count >= 4 else { return nil }
        guard let hour = Int(clean.prefix(2)), let min = Int(clean.dropFirst(2).prefix(2)) else { return nil }
        return hour * 60 + min
    }

    static func isSameQSO(time1: String, time2: String) -> Bool {
        guard let m1 = timeMinutes(from: time1), let m2 = timeMinutes(from: time2) else {
            return time1.prefix(4) == time2.prefix(4)
        }
        let diff = abs(m1 - m2)
        return diff <= 5 || diff >= (1440 - 5) // Innerhalb von 5 Minuten (inkl. Mitternachts-Umschlag)
    }

    @discardableResult
    func insertQSOs(_ entries: [QSOEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        var insertedCount = 0
        dbQueue.sync {
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            let findMatchSQL = "SELECT id, time_on, dxcc, grid FROM qsos WHERE callsign = ? AND band = ? AND mode = ? AND qso_date = ?;"
            let updateSQL = "UPDATE qsos SET grid = CASE WHEN (grid IS NULL OR grid = '') AND ? != '' THEN ? ELSE grid END, dxcc = CASE WHEN (dxcc IS NULL OR dxcc = '') AND ? != '' THEN ? ELSE dxcc END WHERE id = ?;"
            let insertSQL = """
            INSERT INTO qsos (id, callsign, band, mode, qso_date, time_on, dxcc, grid, unique_key)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(unique_key) DO UPDATE SET
            grid = CASE WHEN (qsos.grid IS NULL OR qsos.grid = '') AND excluded.grid != '' THEN excluded.grid ELSE qsos.grid END,
            dxcc = CASE WHEN (qsos.dxcc IS NULL OR qsos.dxcc = '') AND excluded.dxcc != '' THEN excluded.dxcc ELSE qsos.dxcc END;
            """
            
            var findStmt: OpaquePointer?
            var updateStmt: OpaquePointer?
            var insertStmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, findMatchSQL, -1, &findStmt, nil) == SQLITE_OK,
               sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, nil) == SQLITE_OK,
               sqlite3_prepare_v2(db, insertSQL, -1, &insertStmt, nil) == SQLITE_OK {
                
                for qso in entries {
                    let idStr = qso.id.uuidString
                    let callStr = qso.callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let bandStr = qso.band.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                                        .replacingOccurrences(of: " ", with: "")
                    let modeStr = qso.mode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    var cleanDate = qso.qsoDate
                        .replacingOccurrences(of: "-", with: "")
                        .replacingOccurrences(of: "/", with: "")
                        .replacingOccurrences(of: ".", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleanDate.isEmpty {
                        let fmt = DateFormatter()
                        fmt.timeZone = TimeZone(secondsFromGMT: 0)
                        fmt.dateFormat = "yyyyMMdd"
                        cleanDate = fmt.string(from: Date())
                    }
                    
                    var rawTime = qso.timeOn.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if rawTime.isEmpty {
                        let fmt = DateFormatter()
                        fmt.timeZone = TimeZone(secondsFromGMT: 0)
                        fmt.dateFormat = "HHmm"
                        rawTime = fmt.string(from: Date())
                    }
                    let timeNorm = rawTime.count >= 4 ? String(rawTime.prefix(4)) : rawTime
                    let keyStr = "\(callStr)_\(bandStr)_\(modeStr)_\(cleanDate)_\(timeNorm)"
                    let gridStr = qso.grid.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let dxccStr = qso.dxcc.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !callStr.isEmpty, !bandStr.isEmpty else { continue }
                    
                    // 1. Prüfen, ob bereits ein gleiches QSO innerhalb eines 5-Minuten-Zeitfensters existiert
                    sqlite3_bind_text(findStmt, 1, (callStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(findStmt, 2, (bandStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(findStmt, 3, (modeStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(findStmt, 4, (cleanDate as NSString).utf8String, -1, nil)
                    
                    var matchedExistingId: String? = nil
                    while sqlite3_step(findStmt) == SQLITE_ROW {
                        let existingId = String(cString: sqlite3_column_text(findStmt, 0))
                        let existingTime = String(cString: sqlite3_column_text(findStmt, 1))
                        
                        if DatabaseManager.isSameQSO(time1: existingTime, time2: timeNorm) {
                            matchedExistingId = existingId
                            break
                        }
                    }
                    sqlite3_reset(findStmt)
                    
                    if let existingId = matchedExistingId {
                        // Vorhandenen Datensatz mit ggf. neuem Grid oder DXCC aktualisieren
                        sqlite3_bind_text(updateStmt, 1, (gridStr as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(updateStmt, 2, (gridStr as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(updateStmt, 3, (dxccStr as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(updateStmt, 4, (dxccStr as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(updateStmt, 5, (existingId as NSString).utf8String, -1, nil)
                        sqlite3_step(updateStmt)
                        sqlite3_reset(updateStmt)
                        continue
                    }
                    
                    // 2. Neuer Datensatz einfügen
                    sqlite3_bind_text(insertStmt, 1, (idStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 2, (callStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 3, (bandStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 4, (modeStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 5, (cleanDate as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 6, (timeNorm as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 7, (dxccStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 8, (gridStr as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(insertStmt, 9, (keyStr as NSString).utf8String, -1, nil)
                    
                    if sqlite3_step(insertStmt) == SQLITE_DONE {
                        if sqlite3_changes(db) > 0 {
                            insertedCount += 1
                        }
                    }
                    sqlite3_reset(insertStmt)
                }
                sqlite3_finalize(findStmt)
                sqlite3_finalize(updateStmt)
                sqlite3_finalize(insertStmt)
            }
            
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
        return insertedCount
    }
    
    @discardableResult
    func cleanupExistingDuplicates() -> Int {
        var removedCount = 0
        dbQueue.sync {
            let dupGroupSQL = """
            SELECT callsign, band, mode, qso_date, COUNT(*) as cnt
            FROM qsos
            GROUP BY callsign, band, mode, qso_date
            HAVING cnt > 1;
            """
            
            var groups = [(call: String, band: String, mode: String, date: String)]()
            var groupStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, dupGroupSQL, -1, &groupStmt, nil) == SQLITE_OK {
                while sqlite3_step(groupStmt) == SQLITE_ROW {
                    let call = String(cString: sqlite3_column_text(groupStmt, 0))
                    let band = String(cString: sqlite3_column_text(groupStmt, 1))
                    let mode = String(cString: sqlite3_column_text(groupStmt, 2))
                    let date = String(cString: sqlite3_column_text(groupStmt, 3))
                    groups.append((call, band, mode, date))
                }
                sqlite3_finalize(groupStmt)
            }
            
            guard !groups.isEmpty else { return }
            
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            let selectRowsSQL = "SELECT id, time_on, dxcc, grid FROM qsos WHERE callsign = ? AND band = ? AND mode = ? AND qso_date = ? ORDER BY time_on ASC;"
            let updateMergedSQL = "UPDATE qsos SET grid = ?, dxcc = ? WHERE id = ?;"
            let deleteRowSQL = "DELETE FROM qsos WHERE id = ?;"
            
            var selectStmt: OpaquePointer?
            var updateStmt: OpaquePointer?
            var deleteStmt: OpaquePointer?
            
            if sqlite3_prepare_v2(db, selectRowsSQL, -1, &selectStmt, nil) == SQLITE_OK,
               sqlite3_prepare_v2(db, updateMergedSQL, -1, &updateStmt, nil) == SQLITE_OK,
               sqlite3_prepare_v2(db, deleteRowSQL, -1, &deleteStmt, nil) == SQLITE_OK {
                
                for group in groups {
                    sqlite3_bind_text(selectStmt, 1, (group.call as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(selectStmt, 2, (group.band as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(selectStmt, 3, (group.mode as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(selectStmt, 4, (group.date as NSString).utf8String, -1, nil)
                    
                    var rows = [(id: String, time: String, dxcc: String, grid: String)]()
                    while sqlite3_step(selectStmt) == SQLITE_ROW {
                        let id = String(cString: sqlite3_column_text(selectStmt, 0))
                        let time = String(cString: sqlite3_column_text(selectStmt, 1))
                        let dxcc = sqlite3_column_text(selectStmt, 2) != nil ? String(cString: sqlite3_column_text(selectStmt, 2)) : ""
                        let grid = sqlite3_column_text(selectStmt, 3) != nil ? String(cString: sqlite3_column_text(selectStmt, 3)) : ""
                        rows.append((id, time, dxcc, grid))
                    }
                    sqlite3_reset(selectStmt)
                    
                    guard rows.count > 1 else { continue }
                    
                    var keptIndices = [Int]()
                    
                    for i in 0..<rows.count {
                        let current = rows[i]
                        var merged = false
                        
                        for keptIdx in keptIndices {
                            let target = rows[keptIdx]
                            if DatabaseManager.isSameQSO(time1: target.time, time2: current.time) {
                                let mergedGrid = !target.grid.isEmpty ? target.grid : current.grid
                                let mergedDXCC = !target.dxcc.isEmpty ? target.dxcc : current.dxcc
                                rows[keptIdx].grid = mergedGrid
                                rows[keptIdx].dxcc = mergedDXCC
                                
                                sqlite3_bind_text(updateStmt, 1, (mergedGrid as NSString).utf8String, -1, nil)
                                sqlite3_bind_text(updateStmt, 2, (mergedDXCC as NSString).utf8String, -1, nil)
                                sqlite3_bind_text(updateStmt, 3, (target.id as NSString).utf8String, -1, nil)
                                sqlite3_step(updateStmt)
                                sqlite3_reset(updateStmt)
                                
                                sqlite3_bind_text(deleteStmt, 1, (current.id as NSString).utf8String, -1, nil)
                                sqlite3_step(deleteStmt)
                                sqlite3_reset(deleteStmt)
                                
                                removedCount += 1
                                merged = true
                                break
                            }
                        }
                        
                        if !merged {
                            keptIndices.append(i)
                        }
                    }
                }
                
                sqlite3_finalize(selectStmt)
                sqlite3_finalize(updateStmt)
                sqlite3_finalize(deleteStmt)
            }
            
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
            print("AutoQSO Bereinigung: \(removedCount) doppelte QSOs dedupliziert.")
        }
        return removedCount
    }
    
    func fetchAllQSOs() -> [QSOEntry] {
        var results = [QSOEntry]()
        dbQueue.sync {
            let querySQL = "SELECT id, callsign, band, mode, qso_date, time_on, dxcc, grid FROM qsos ORDER BY qso_date DESC, time_on DESC;"
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
                    let grid = sqlite3_column_text(statement, 7) != nil ? String(cString: sqlite3_column_text(statement, 7)) : ""
                    
                    let uuid = UUID(uuidString: idStr) ?? UUID()
                    let qso = QSOEntry(id: uuid, callsign: call, band: band, mode: mode, qsoDate: qsoDate, timeOn: timeOn, dxcc: dxcc, grid: grid)
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
    
    // MARK: - Einstellungen & Konfiguration (Settings in SQLite)
    
    /// Prüft, ob ein UserDefaults-Schlüssel zu den anwendungsrelevanten Einstellungen von AutoQSO gehört
    static func isAppSettingKey(_ key: String) -> Bool {
        if key.hasPrefix("NS") ||
           key.hasPrefix("Apple") ||
           key.hasPrefix("AK") ||
           key.hasPrefix("com.apple") ||
           key.hasPrefix("WebKit") ||
           key.hasPrefix("PK") ||
           key.hasPrefix("Metal") ||
           key.hasPrefix("CA_") ||
           key.hasPrefix("NSToolbar") {
            return false
        }
        return true
    }
    
    /// Kodiert beliebige Einstellungswerte in ein typsicheres JSON-Objekt für die SQLite-Datenbank
    static func encodeSettingValue(_ value: Any) -> String? {
        var dict: [String: Any] = [:]
        
        if let data = value as? Data {
            dict = ["type": "data", "val": data.base64EncodedString()]
        } else if let date = value as? Date {
            dict = ["type": "date", "val": ISO8601DateFormatter().string(from: date)]
        } else if let str = value as? String {
            dict = ["type": "string", "val": str]
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                dict = ["type": "bool", "val": num.boolValue]
            } else if CFNumberIsFloatType(num as CFNumber) {
                dict = ["type": "double", "val": num.doubleValue]
            } else {
                dict = ["type": "int", "val": num.intValue]
            }
        } else if let arr = value as? [String] {
            dict = ["type": "stringArray", "val": arr]
        } else if let arr = value as? [Int] {
            dict = ["type": "intArray", "val": arr]
        } else if let arr = value as? [Double] {
            dict = ["type": "json", "val": arr]
        } else if let d = value as? [String: Any], JSONSerialization.isValidJSONObject(d) {
            dict = ["type": "json", "val": d]
        } else if let a = value as? [Any], JSONSerialization.isValidJSONObject(a) {
            dict = ["type": "json", "val": a]
        } else {
            return nil
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            return jsonStr
        }
        return nil
    }
    
    /// Liest eine einzelne Einstellung aus der SQLite-Datenbank
    func getSetting(key: String) -> String? {
        var result: String?
        dbQueue.sync {
            let querySQL = "SELECT value FROM settings WHERE key = ? LIMIT 1;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = String(cString: sqlite3_column_text(statement, 0))
                }
                sqlite3_finalize(statement)
            }
        }
        return result
    }
    
    /// Liest alle gespeicherten Einstellungen aus der SQLite-Datenbank
    func getAllSettings() -> [String: String] {
        var results = [String: String]()
        dbQueue.sync {
            let querySQL = "SELECT key, value FROM settings;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let k = String(cString: sqlite3_column_text(statement, 0))
                    let v = String(cString: sqlite3_column_text(statement, 1))
                    results[k] = v
                }
                sqlite3_finalize(statement)
            }
        }
        return results
    }
    
    /// Gibt alle in der SQLite-Datenbank vorhandenen Einstellungsschlüssel zurück
    func getAllSettingKeys() -> [String] {
        var keys = [String]()
        dbQueue.sync {
            let querySQL = "SELECT key FROM settings;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let k = String(cString: sqlite3_column_text(statement, 0))
                    keys.append(k)
                }
                sqlite3_finalize(statement)
            }
        }
        return keys
    }
    
    /// Speichert oder aktualisiert eine Einstellung in der SQLite-Datenbank
    func setSetting(key: String, value: Any) {
        guard let encoded = DatabaseManager.encodeSettingValue(value) else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        dbQueue.sync {
            let insertSQL = """
            INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (encoded as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (now as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    /// Löscht eine Einstellung aus der SQLite-Datenbank
    func deleteSetting(key: String) {
        dbQueue.sync {
            let deleteSQL = "DELETE FROM settings WHERE key = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    /// Lädt alle in der SQLite-Datenbank gespeicherten Einstellungen in UserDefaults.standard
    func syncDatabaseToUserDefaults() {
        isSyncingFromDB = true
        defer { isSyncingFromDB = false }
        
        let all = getAllSettings()
        guard !all.isEmpty else { return }
        
        let defaults = UserDefaults.standard
        for (key, jsonString) in all {
            guard let data = jsonString.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = dict["type"] as? String,
                  let val = dict["val"] else {
                continue
            }
            
            switch type {
            case "bool":
                if let b = val as? Bool { defaults.set(b, forKey: key) }
            case "int":
                if let n = val as? NSNumber { defaults.set(n.intValue, forKey: key) }
            case "double":
                if let n = val as? NSNumber { defaults.set(n.doubleValue, forKey: key) }
            case "string":
                if let s = val as? String { defaults.set(s, forKey: key) }
            case "stringArray":
                if let arr = val as? [String] { defaults.set(arr, forKey: key) }
            case "intArray":
                if let arr = val as? [Int] { defaults.set(arr, forKey: key) }
            case "data":
                if let b64 = val as? String, let d = Data(base64Encoded: b64) {
                    defaults.set(d, forKey: key)
                }
            case "date":
                if let iso = val as? String, let d = ISO8601DateFormatter().date(from: iso) {
                    defaults.set(d, forKey: key)
                }
            case "json":
                defaults.set(val, forKey: key)
            default:
                defaults.set(val, forKey: key)
            }
        }
        
        DispatchQueue.main.async {
            LanguageManager.shared.reloadLanguageFromDefaults()
        }
    }
    
    /// Schreibt alle anwendungsrelevanten Einstellungen aus UserDefaults.standard in die SQLite-Datenbank
    func syncUserDefaultsToDatabase() {
        guard !isSyncingFromDB else { return }
        let defaults = UserDefaults.standard
        let currentDefaults = defaults.dictionaryRepresentation()
        let now = ISO8601DateFormatter().string(from: Date())
        
        var toSave: [(key: String, value: String)] = []
        for (key, value) in currentDefaults {
            guard DatabaseManager.isAppSettingKey(key) else { continue }
            if let encoded = DatabaseManager.encodeSettingValue(value) {
                toSave.append((key: key, value: encoded))
            }
        }
        
        let dbKeys = getAllSettingKeys()
        var toDelete: [String] = []
        for dbKey in dbKeys {
            if DatabaseManager.isAppSettingKey(dbKey) && currentDefaults[dbKey] == nil {
                toDelete.append(dbKey)
            }
        }
        
        guard !toSave.isEmpty || !toDelete.isEmpty else { return }
        
        dbQueue.sync {
            sqlite3_exec(db, "BEGIN TRANSACTION;", nil, nil, nil)
            
            if !toSave.isEmpty {
                let sql = """
                INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at;
                """
                var stmt: OpaquePointer?
                if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                    for item in toSave {
                        sqlite3_bind_text(stmt, 1, (item.key as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(stmt, 2, (item.value as NSString).utf8String, -1, nil)
                        sqlite3_bind_text(stmt, 3, (now as NSString).utf8String, -1, nil)
                        sqlite3_step(stmt)
                        sqlite3_reset(stmt)
                    }
                    sqlite3_finalize(stmt)
                }
            }
            
            if !toDelete.isEmpty {
                let deleteSql = "DELETE FROM settings WHERE key = ?;"
                var delStmt: OpaquePointer?
                if sqlite3_prepare_v2(db, deleteSql, -1, &delStmt, nil) == SQLITE_OK {
                    for delKey in toDelete {
                        sqlite3_bind_text(delStmt, 1, (delKey as NSString).utf8String, -1, nil)
                        sqlite3_step(delStmt)
                        sqlite3_reset(delStmt)
                    }
                    sqlite3_finalize(delStmt)
                }
            }
            
            sqlite3_exec(db, "COMMIT;", nil, nil, nil)
        }
    }
    
    private func startObservingUserDefaults() {
        stopObservingUserDefaults()
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: nil
        ) { [weak self] _ in
            guard let self = self, !self.isSyncingFromDB else { return }
            self.debounceSyncToDatabase()
        }
    }
    
    private func stopObservingUserDefaults() {
        if let observer = userDefaultsObserver {
            NotificationCenter.default.removeObserver(observer)
            userDefaultsObserver = nil
        }
    }
    
    private func debounceSyncToDatabase() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.syncUserDefaultsToDatabase()
        }
        debounceWorkItem = workItem
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    // MARK: - Filter Profiles
    
    /// Lädt alle Filter-Profile aus der SQLite-Datenbank
    func loadFilterProfiles() -> [FilterProfile] {
        var profiles: [FilterProfile] = []
        dbQueue.sync {
            let querySQL = "SELECT data_json FROM filter_profiles ORDER BY is_system DESC, name ASC;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, querySQL, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let text = sqlite3_column_text(statement, 0) {
                        let jsonStr = String(cString: text)
                        if let data = jsonStr.data(using: .utf8),
                           let profile = try? JSONDecoder().decode(FilterProfile.self, from: data) {
                            profiles.append(profile)
                        }
                    }
                }
                sqlite3_finalize(statement)
            }
        }
        
        // Wenn noch keine Profile existieren, initialisiere die Standard-Vorlagen
        if profiles.isEmpty {
            for template in FilterProfile.systemTemplates {
                saveFilterProfile(template)
                profiles.append(template)
            }
        }
        
        return profiles
    }
    
    /// Speichert ein Filter-Profil in der SQLite-Datenbank
    func saveFilterProfile(_ profile: FilterProfile) {
        guard let data = try? JSONEncoder().encode(profile),
              let jsonStr = String(data: data, encoding: .utf8) else { return }
        
        let nowStr = ISO8601DateFormatter().string(from: profile.updatedAt)
        let isSystemInt = profile.isSystem ? 1 : 0
        
        dbQueue.sync {
            let insertSQL = """
            INSERT OR REPLACE INTO filter_profiles (id, name, is_system, auto_band, auto_mode, data_json, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (profile.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (profile.name as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 3, Int32(isSystemInt))
                if let band = profile.autoBand {
                    sqlite3_bind_text(statement, 4, (band as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                if let mode = profile.autoMode {
                    sqlite3_bind_text(statement, 5, (mode as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 5)
                }
                sqlite3_bind_text(statement, 6, (jsonStr as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 7, (nowStr as NSString).utf8String, -1, nil)
                
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
    
    /// Löscht ein Profil aus der Datenbank (System-Profile sind geschützt)
    func deleteFilterProfile(id: String) {
        dbQueue.sync {
            let deleteSQL = "DELETE FROM filter_profiles WHERE id = ? AND is_system = 0;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }
}
