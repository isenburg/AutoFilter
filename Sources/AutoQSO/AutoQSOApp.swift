import SwiftUI

@main
struct AutoQSOApp: App {
    @StateObject private var viewModel = DecodeViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        
        Window("LoTW Logbuch", id: "logbook") {
            LogbookView(viewModel: viewModel)
        }
        
        Window("Hilfe & Info", id: "help") {
            HelpView()
        }
        
        Window("Einstellungen", id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        
        Settings {
            SettingsView(viewModel: viewModel)
        }
    }
}
