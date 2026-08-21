import SwiftUI

@main
struct AutoQSOApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel: DecodeViewModel
    @ObservedObject private var langManager = LanguageManager.shared
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    
    init() {
        _ = DatabaseManager.shared
        _viewModel = StateObject(wrappedValue: DecodeViewModel())
    }
    
    private var isDe: Bool { langManager.isGerman }
    
    var preferredScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var body: some Scene {
        WindowGroup("AutoQSO v\(APP_VERSION) (Build \(APP_BUILD_NUMBER))") {
            ContentView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        .commands {
            // App-Menü: Über AutoQSO mit Copyright-Info
            CommandGroup(replacing: .appInfo) {
                Button(isDe ? "Über AutoQSO" : "About AutoQSO") {
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
                Button(isDe ? "AutoQSO Hilfe" : "AutoQSO Help") {
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
    
    static func showAboutPanel() {
        let copyrightStr = "Copyright © 2026 Georg Isenbürger · DJ6GI"
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "AutoQSO",
            .applicationVersion: "Version \(APP_VERSION)",
            .version: "Build \(APP_BUILD_NUMBER)",
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): copyrightStr
        ])
    }
}
