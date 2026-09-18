import Observation
import Foundation
import Combine
import AppKit

@Observable
class RUMlogManager {
    var isDownloading: Bool = false
    var errorMessage: String? = nil
    var logHistory: [String] = []
    
    private let userDefaultsLastSyncKey = "rumlogLastSyncTimestamp"
    private var isDe: Bool { LanguageManager.shared.isGerman }

    init() {}
    
    func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let formatted = "[\(timestamp)] [RUMlogNG] \(message)"
        DispatchQueue.main.async {
            self.logHistory.append(formatted)
            if self.logHistory.count > 500 {
                self.logHistory.removeFirst(self.logHistory.count - 500)
            }
        }
    }
    
    func syncRUMlog(fullSync: Bool = false, completion: @escaping ([QSOEntry]) -> Void) {
        guard !isDownloading else { return }
        
        isDownloading = true
        errorMessage = nil
        
        let sinceString: String
        if fullSync {
            sinceString = "1900-01-01 00:00:00"
            addLog(isDe ? "Starte vollständigen RUMlogNG Sync ab 1900-01-01..." : "Starting full RUMlogNG sync from 1900-01-01...")
        } else {
            let saved = UserDefaults.standard.string(forKey: userDefaultsLastSyncKey)
            sinceString = saved ?? "1900-01-01 00:00:00"
            addLog(isDe ? "Starte inkrementellen RUMlogNG Sync ab \(sinceString)..." : "Starting incremental RUMlogNG sync from \(sinceString)...")
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Überprüfe, ob RUMlogNG läuft
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "de.dl2rum.RUMlogNG")
            if runningApps.isEmpty {
                // Auch prüfen auf Bundle-Name falls abweichend
                let anyRumlog = NSWorkspace.shared.runningApplications.contains { app in
                    app.localizedName?.lowercased().contains("rumlog") == true
                }
                if !anyRumlog {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        let err = self.isDe
                            ? "RUMlogNG ist nicht gestartet. Bitte starte RUMlogNG und versuche es erneut."
                            : "RUMlogNG is not running. Please start RUMlogNG and try again."
                        self.errorMessage = err
                        self.addLog(self.isDe ? "Fehler: \(err)" : "Error: \(err)")
                    }
                    return
                }
            }
            
            let scriptText = """
            tell application id "de.dl2rum.RUMlogNG"
                set adifText to ReadAdif ("\(sinceString)")
                return adifText
            end tell
            """
            
            var errorDict: NSDictionary?
            guard let appleScript = NSAppleScript(source: scriptText) else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    let err = self.isDe ? "Fehler beim Erstellen des AppleScripts für RUMlogNG." : "Error creating AppleScript for RUMlogNG."
                    self.errorMessage = err
                    self.addLog(self.isDe ? "Fehler: \(err)" : "Error: \(err)")
                }
                return
            }
            
            let descriptor = appleScript.executeAndReturnError(&errorDict)
            
            if let error = errorDict {
                let errDescription = error[NSAppleScript.errorMessage] as? String ?? (self.isDe ? "Unbekannter AppleScript Fehler" : "Unknown AppleScript error")
                let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                
                let err: String
                if errorNumber == -1743 || errDescription.lowercased().contains("not authorized") {
                    err = self.isDe
                        ? "Berechtigung fehlt: macOS blockiert Apple Events an RUMlogNG. Bitte öffne Systemeinstellungen ➔ Datenschutz & Sicherheit ➔ Automation und aktiviere 'RUMlogNG' unter 'AutoFilter'."
                        : "Permission missing: macOS is blocking Apple Events to RUMlogNG. Please open System Settings ➔ Privacy & Security ➔ Automation and enable 'RUMlogNG' under 'AutoFilter'."
                } else {
                    err = self.isDe ? "AppleScript Fehler bei RUMlogNG: \(errDescription)" : "AppleScript error with RUMlogNG: \(errDescription)"
                }
                
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.errorMessage = err
                    self.addLog(self.isDe ? "Fehler: \(err)" : "Error: \(err)")
                }
                return
            }
            
            guard let adifOutput = descriptor.stringValue, !adifOutput.isEmpty else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.addLog(self.isDe
                        ? "RUMlogNG hat keine Daten zurückgegeben (Logbuch möglicherweise leer)."
                        : "RUMlogNG returned no data (logbook may be empty).")
                    completion([])
                }
                return
            }
            
            self.addLog(self.isDe
                ? "ADIF Daten von RUMlogNG empfangen (\(adifOutput.count / 1024) KB). Parse QSOs..."
                : "ADIF data received from RUMlogNG (\(adifOutput.count / 1024) KB). Parsing QSOs...")
            
            let entries = ADIFParser.parseQSOs(from: adifOutput)
            
            // Aktualisiere Sync-Zeitstempel
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            let nowUtc = formatter.string(from: Date())
            UserDefaults.standard.set(nowUtc, forKey: self.userDefaultsLastSyncKey)
            
            DispatchQueue.main.async {
                self.isDownloading = false
                self.addLog(self.isDe
                    ? "RUMlogNG Sync erfolgreich: \(entries.count) QSOs importiert."
                    : "RUMlogNG sync successful: \(entries.count) QSOs imported.")
                completion(entries)
            }
        }
    }
}
