import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case udp = "UDP Server"
    case lotw = "LoTW Sync"
    case qrz = "QRZ.com"
    case storage = "Speicherort & iCloud"
    case options = "Auto Mode Optionen"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .udp: return "network"
        case .lotw: return "arrow.triangle.2.circlepath"
        case .qrz: return "key.fill"
        case .storage: return "folder.fill"
        case .options: return "slider.horizontal.3"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @State private var selectedSection: SettingsSection = .udp
    
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    
    @AppStorage("storageLocationMode") private var storageLocationMode = "default"
    @AppStorage("customStoragePath") private var customStoragePath = ""
    
    private var isMulticastAddress: Bool {
        if let firstOctetStr = udpAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
           let firstOctet = Int(firstOctetStr) {
            return firstOctet >= 224 && firstOctet <= 239
        }
        return false
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Non-collapsible Left Sidebar
            VStack(alignment: .leading, spacing: 6) {
                Text("Einstellungen")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                
                List(SettingsSection.allCases, selection: $selectedSection) { section in
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .foregroundColor(selectedSection == section ? .accentColor : .secondary)
                            .frame(width: 18)
                        Text(section.rawValue)
                            .font(.body)
                    }
                    .tag(section)
                }
                .listStyle(.sidebar)
                
                Spacer(minLength: 0)
            }
            .frame(width: 190)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content Form View
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailView(for: selectedSection)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 620, minHeight: 380)
    }
    
    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
        case .udp:
            VStack(alignment: .leading, spacing: 14) {
                Text("WSJT-X UDP Server Verbindung")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("UDP Adresse:")
                        .font(.headline)
                    TextField("224.0.0.1", text: $udpAddress)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("UDP Port:")
                        .font(.headline)
                    TextField("2237", value: $udpPort, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("Typ:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(isMulticastAddress ? "Multicast (MC)" : "Unicast (UC)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isMulticastAddress ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundColor(isMulticastAddress ? .blue : .orange)
                        .cornerRadius(4)
                }
                
                Button("Server Verbinden / Neu Starten") {
                    let portVal = UInt16(udpPort)
                    viewModel.startServer(port: portVal, address: udpAddress)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
            
        case .lotw:
            VStack(alignment: .leading, spacing: 14) {
                Text("Logbook of The World (LoTW)")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Benutzername / Callsign:")
                        .font(.headline)
                    TextField("Benutzername", text: $lotwUsername)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Passwort:")
                        .font(.headline)
                    SecureField("Passwort", text: $lotwPassword)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                }
                
                Button("LoTW Logbuch Synchronisieren") {
                    viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword)
                }
                .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
            
        case .qrz:
            VStack(alignment: .leading, spacing: 14) {
                Text("QRZ.com API Konfiguration")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("QRZ API Key:")
                        .font(.headline)
                    SecureField("API Key", text: $qrzApiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 280)
                }
                
                Button("QRZ.com Logbuch Synchronisieren") {
                    viewModel.syncQRZ(apiKey: qrzApiKey)
                }
                .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
            
        case .storage:
            VStack(alignment: .leading, spacing: 14) {
                Text("Datenbank & Speicherort")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Speicherort wählen:")
                        .font(.headline)
                    
                    Picker("", selection: $storageLocationMode) {
                        Text("Standard (~/Documents/AutoQSO)").tag("default")
                        Text("Benutzerdefinierter Ordner").tag("custom")
                        Text("iCloud Drive (Synchronisiert)").tag("icloud")
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: storageLocationMode) { _, _ in
                        DatabaseManager.shared.switchStorageLocation()
                        viewModel.lotwManager.loadLog()
                    }
                }
                
                if storageLocationMode == "custom" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ausgewählter Pfad:")
                            .font(.subheadline)
                        HStack {
                            Text(customStoragePath.isEmpty ? "Kein Ordner gewählt" : customStoragePath)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Ordner wählen...") {
                                selectCustomFolder()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktueller SQLite Pfad:")
                        .font(.caption)
                        .bold()
                    Text(DatabaseManager.shared.currentDbPath)
                        .font(.caption2)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            
        case .options:
            VStack(alignment: .leading, spacing: 14) {
                Text("Auto QSO Optionen")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 8) {
                    Text("Sperrdauer für abgebrochene QSOs:")
                        .font(.headline)
                    TextField("10", value: $retryCooldownMinutes, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("Minuten")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Wählen"
        
        if panel.runModal() == .OK, let url = panel.url {
            customStoragePath = url.path
            storageLocationMode = "custom"
            DatabaseManager.shared.switchStorageLocation()
            viewModel.lotwManager.loadLog()
        }
    }
}
