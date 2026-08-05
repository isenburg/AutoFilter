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
            
            // Hilfe-Menü: Standard-Help-Eintrag mit eigenem Hilfe-Fenster verbinden
            CommandGroup(replacing: .help) {
                Button("AutoQSO Hilfe") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenHelpWindow"), object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Divider()
                
                Button("Changelog") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenHelpWindow"), object: nil)
                }
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
        
        Window("Einstellungen", id: "settings") {
            SettingsView(viewModel: viewModel)
                .preferredColorScheme(preferredScheme)
        }
        .windowResizability(.contentSize)
        
        Window("Logs & Rohdaten", id: "logs_raw") {
            LogsConsoleView(viewModel: viewModel)
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
        let credits = NSAttributedString(
            string: "Copyright © 2024–2026 Georg Isenbürger · DJ6GI",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "AutoQSO",
            .applicationVersion: "Version \(APP_VERSION)",
            .version: "Build \(APP_BUILD_NUMBER)",
            .credits: credits
        ])
    }
}
