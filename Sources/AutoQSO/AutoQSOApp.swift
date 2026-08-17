import SwiftUI

@main
struct AutoQSOApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = DecodeViewModel()
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    
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
                Button("Über AutoQSO") {
                    AppDelegate.showAboutPanel()
                }
            }
            
            // Clean up File menu
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .printItem) { }
            CommandGroup(replacing: .importExport) { }
            
            // Steuerung Menu
            CommandMenu("Steuerung") {
                Button(viewModel.isAutoModeEnabled ? "Auto-Senden deaktivieren" : "Auto-Senden aktivieren") {
                    viewModel.isAutoModeEnabled.toggle()
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Button(viewModel.isFiltersEnabled ? "DX-Filter ausschalten" : "DX-Filter einschalten") {
                    viewModel.isFiltersEnabled.toggle()
                    viewModel.saveFilters()
                    viewModel.clearBlockedDecodes()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
            
            // Ansicht Menu
            CommandMenu("Ansicht") {
                Button("Kompaktmodus umschalten") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleCompactMode"), object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command, .option])
                
                Divider()
                
                Button("Verbindungs-Seitenleiste ein-/ausblenden") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleLeftSidebar"), object: nil)
                }
                .keyboardShortcut("1", modifiers: [.command, .option])
                
                Button("Filter-Seitenleiste ein-/ausblenden") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleRightSidebar"), object: nil)
                }
                .keyboardShortcut("2", modifiers: [.command, .option])
            }
            
            // Custom additions to Window menu list
            CommandGroup(after: .windowList) {
                Divider()
                Button("Einstellungen...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettingsWindow"), object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button("LoTW Logbuch") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenLogbookWindow"), object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Button("Ausbreitungskarte") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenPropagationMapWindow"), object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                Button("Neue Maidenhead-Grids Karte") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenNewGridMapWindow"), object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                
                Button("Logs & Rohdaten") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenLogsRawWindow"), object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
            
            // Hilfe-Menü: Standard-Help-Eintrag mit eigenem Hilfe-Fenster verbinden
            CommandGroup(replacing: .help) {
                Button("AutoQSO Hilfe") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenHelpWindow"), object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        
        Window("LoTW Logbuch", id: "logbook") {
            LogbookView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        
        Window("Hilfe & Info", id: "help") {
            HelpView()
                .preferredColorScheme(preferredScheme)
        }
        .windowResizability(.contentSize)
        
        Window("Einstellungen", id: "settings") {
            SettingsView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        .windowResizability(.contentSize)
        
        Window("Logs & Rohdaten", id: "logs_raw") {
            LogsConsoleView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        
        Window("Ausbreitungskarte", id: "propagation_map") {
            PropagationMapView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }

        Window("Neue Maidenhead-Grids", id: "new_grid_map") {
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
