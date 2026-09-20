import SwiftUI

@main
struct AutoFilterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var viewModel = DecodeViewModel()
    private var langManager = LanguageManager.shared
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("appLanguage") private var appLanguage = "en"
    
    init() {
        UserDefaults.standard.register(defaults: [
            "NSInitialToolTipDelay": 150
        ])
        UserDefaults.standard.set(150, forKey: "NSInitialToolTipDelay")
        _ = DatabaseManager.shared
    }
    
    private var isDe: Bool { appLanguage == "de" }
    
    var preferredScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup("AutoFilter v\(APP_VERSION) (Build \(APP_BUILD_NUMBER))") {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        .commands {
            // App-Menü: Über AutoFilter mit Copyright-Info
            CommandGroup(replacing: .appInfo) {
                Button(isDe ? "Über AutoFilter" : "About AutoFilter") {
                    AppDelegate.showAboutPanel()
                }
            }
            
            // Clean up File menu
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .printItem) { }
            CommandGroup(replacing: .importExport) { }
            
            // Steuerung Menu
            CommandMenu(isDe ? "Steuerung" : "Control") {
                Button(viewModel.isAutoModeEnabled ? (isDe ? "Auto-Senden deaktivieren" : "Disable Auto Transmit") : (isDe ? "Auto-Senden aktivieren" : "Enable Auto Transmit")) {
                    viewModel.isAutoModeEnabled.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Button(viewModel.isFiltersEnabled ? (isDe ? "DX-Filter ausschalten" : "Disable DX Filters") : (isDe ? "DX-Filter einschalten" : "Enable DX Filters")) {
                    viewModel.isFiltersEnabled.toggle()
                    viewModel.saveFilters()
                    viewModel.clearBlockedDecodes()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
            
            // Ansicht Menu
            CommandMenu(isDe ? "Ansicht" : "View") {
                Button(isDe ? "Kompaktmodus umschalten" : "Toggle Compact Mode") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleCompactMode"), object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .option])
                
                Divider()
                
                Button(isDe ? "Verbindungs-Seitenleiste ein-/ausblenden" : "Toggle Connection Sidebar") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleLeftSidebar"), object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button(isDe ? "Filter-Seitenleiste ein-/ausblenden" : "Toggle Filter Sidebar") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleRightSidebar"), object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
            }
            
            // Custom additions to Window menu list
            CommandGroup(after: .windowList) {
                Divider()
                Button(isDe ? "Einstellungen..." : "Settings...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettingsWindow"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button(isDe ? "LoTW Logbuch" : "LoTW Logbook") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenLogbookWindow"), object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Button(isDe ? "Ausbreitungskarte" : "Propagation Map") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenPropagationMapWindow"), object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Button(isDe ? "Neue Maidenhead-Grids Karte" : "New Maidenhead Grids Map") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenNewGridMapWindow"), object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                
                Button(isDe ? "Logs & Rohdaten" : "Logs & Raw Data") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenLogsRawWindow"), object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            
            // Hilfe-Menü: Standard-Help-Eintrag mit eigenem Hilfe-Fenster verbinden
            CommandGroup(replacing: .help) {
                Button(isDe ? "AutoFilter Hilfe" : "AutoFilter Help") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenHelpWindow"), object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        
        Window(isDe ? "LoTW Logbuch" : "LoTW Logbook", id: "logbook") {
            LogbookView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        
        Window(isDe ? "Hilfe & Info" : "Help & Info", id: "help") {
            HelpView()
                .preferredColorScheme(preferredScheme)
        }
        .windowResizability(.contentSize)
        
        Window(isDe ? "Einstellungen" : "Settings", id: "settings") {
            SettingsView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        .windowResizability(.contentSize)
        
        Window(isDe ? "Logs & Rohdaten" : "Logs & Raw Data", id: "logs_raw") {
            LogsConsoleView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        
        Window(isDe ? "Ausbreitungskarte" : "Propagation Map", id: "propagation_map") {
            PropagationMapView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        .windowResizability(.contentSize)

        Window(isDe ? "Neue Maidenhead-Grids" : "New Maidenhead Grids", id: "new_grid_map") {
            NewGridMapView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        
        Settings {
            SettingsView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
    }
}

// AppDelegate für native macOS About-Dialog
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(150, forKey: "NSInitialToolTipDelay")
    }
    
    static func showAboutPanel() {
        let copyrightStr = "Copyright © 2026 Georg Isenbürger · DJ6GI"
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "AutoFilter",
            .applicationVersion: "Version \(APP_VERSION)",
            .version: "Build \(APP_BUILD_NUMBER)",
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): copyrightStr
        ])
    }
}
