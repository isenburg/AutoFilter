import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
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
        TabView {
            // Tab 1: UDP Server Settings
            Form {
                Section(header: Text("WSJT-X UDP SERVER VERBINDUNG").font(.headline)) {
                    TextField("UDP Adresse:", text: $udpAddress)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("UDP Port:", value: $udpPort, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Typ:")
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
                    .padding(.top, 4)
                }
            }
            .padding()
            .tabItem {
                Label("UDP Server", systemImage: "network")
            }
            
            // Tab 2: LoTW Zugangsdaten
            Form {
                Section(header: Text("LOGBOOK OF THE WORLD (LOTW) ZUGANGSDATEN").font(.headline)) {
                    TextField("Benutzername / Call:", text: $lotwUsername)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Passwort:", text: $lotwPassword)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("LoTW Logbuch Synchronisieren") {
                        viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword)
                    }
                    .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
            }
            .padding()
            .tabItem {
                Label("LoTW Sync", systemImage: "arrow.triangle.2.circlepath")
            }
            
            // Tab 3: QRZ.com Settings
            Form {
                Section(header: Text("QRZ.COM API KONFIGURATION").font(.headline)) {
                    SecureField("QRZ API Key:", text: $qrzApiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("QRZ.com Logbuch Synchronisieren") {
                        viewModel.syncQRZ(apiKey: qrzApiKey)
                    }
                    .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
            }
            .padding()
            .tabItem {
                Label("QRZ.com", systemImage: "key.fill")
            }
            
            // Tab 4: Speicherort & iCloud
            Form {
                Section(header: Text("DATENBANK & SPEICHERORT").font(.headline)) {
                    Picker("Speicherort wählen:", selection: $storageLocationMode) {
                        Text("Standard (~/Documents/AutoQSO)").tag("default")
                        Text("Benutzerdefinierter Ordner").tag("custom")
                        Text("iCloud Drive (Synchronisiert)").tag("icloud")
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: storageLocationMode) { _, _ in
                        DatabaseManager.shared.switchStorageLocation()
                        viewModel.lotwManager.loadLog()
                    }
                    
                    if storageLocationMode == "custom" {
                        HStack {
                            Text("Ordner:")
                            Text(customStoragePath.isEmpty ? "Kein Ordner gewählt" : customStoragePath)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Ordner wählen...") {
                                selectCustomFolder()
                            }
                        }
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
                    .padding(.top, 4)
                }
            }
            .padding()
            .tabItem {
                Label("Speicherort", systemImage: "folder.fill")
            }
            
            // Tab 5: Auto Mode Options
            Form {
                Section(header: Text("AUTO QSO OPTIONEN").font(.headline)) {
                    HStack {
                        Text("Sperrdauer (Fehlgeschlagene/Abgebrochene QSOs):")
                        TextField("Minuten", value: $retryCooldownMinutes, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("Minuten")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .tabItem {
                Label("Optionen", systemImage: "slider.horizontal.3")
            }
        }
        .frame(width: 540, height: 280)
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
