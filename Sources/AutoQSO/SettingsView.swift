import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case udp = "UDP Server"
    case lotw = "LoTW Sync"
    case qrz = "QRZ.com"
    case mostWanted = "Most Wanted & Priorität"
    case storage = "Speicherort & iCloud"
    case options = "Auto Mode Optionen"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .udp: return "network"
        case .lotw: return "arrow.triangle.2.circlepath"
        case .qrz: return "key.fill"
        case .mostWanted: return "flame.fill"
        case .storage: return "folder.fill"
        case .options: return "slider.horizontal.3"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @State private var selectedSection: SettingsSection = .udp
    @State private var showResetAlert = false
    
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    
    @AppStorage("myGridLocator") private var myGridLocator = "JO31"
    @AppStorage("highlightMostWanted") private var highlightMostWanted = true
    @AppStorage("prioritizeMostWanted") private var prioritizeMostWanted = true
    @AppStorage("maxMostWantedRank") private var maxMostWantedRank = 100
    
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
                
                HStack(spacing: 8) {
                    Button("LoTW Logbuch Synchronisieren") {
                        viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword)
                    }
                    .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                    .buttonStyle(.borderedProminent)
                    
                    Button("Sync-Datum auf 1900 zurücksetzen") {
                        viewModel.lotwManager.resetSyncDateTo1900()
                    }
                    .buttonStyle(.bordered)
                }
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
                
                HStack(spacing: 8) {
                    Button("QRZ.com Logbuch Synchronisieren") {
                        viewModel.syncQRZ(apiKey: qrzApiKey)
                    }
                    .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                    .buttonStyle(.borderedProminent)
                    
                    Button("Sync-Datum auf 1900 zurücksetzen") {
                        viewModel.qrzManager.resetSyncDateTo1900()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 6)
            }
            
        case .mostWanted:
            VStack(alignment: .leading, spacing: 16) {
                Text("Most Wanted & Priorisierung")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Eigener Maidenhead Locator (Grid Square):")
                        .font(.headline)
                    TextField("z.B. JO31 oder JO31AA", text: $myGridLocator)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 180)
                    Text("Wird für die Entfernungsberechnung (km) zu decodierten Stationen genutzt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hervorhebung & Sortierung:")
                        .font(.headline)
                    
                    Toggle("Most Wanted Stationen rot hervorheben (🔥)", isOn: $highlightMostWanted)
                        .toggleStyle(.checkbox)
                    
                    Toggle("Priorität: Most Wanted zuerst, danach weiteste Entfernung", isOn: $prioritizeMostWanted)
                        .toggleStyle(.checkbox)
                    
                    HStack {
                        Text("Most Wanted Schwelle:")
                            .font(.subheadline)
                        Picker("", selection: $maxMostWantedRank) {
                            Text("Top 10 Most Wanted").tag(10)
                            Text("Top 20 Most Wanted").tag(20)
                            Text("Top 50 Most Wanted").tag(50)
                            Text("Top 100 Most Wanted").tag(100)
                        }
                        .frame(width: 180)
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Such- & Priorisierungs-Reihenfolge:")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("1.")
                                .bold()
                            Text("Most Wanted Entitäten (Top \(maxMostWantedRank))")
                                .bold()
                                .foregroundColor(.red)
                        }
                        HStack {
                            Text("2.")
                                .bold()
                            Text("Weiteste Entfernung (km basierend auf \(myGridLocator.isEmpty ? "JO31" : myGridLocator))")
                                .bold()
                                .foregroundColor(.blue)
                        }
                        HStack {
                            Text("3.")
                                .bold()
                            Text("Stärkstes Signal (SNR dB)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
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
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Logbuch Neu-Initialisierung:")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Button("Sync-Datum auf 1900 zurücksetzen") {
                            viewModel.lotwManager.resetSyncDateTo1900()
                        }
                        .buttonStyle(.bordered)
                        
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            Label("Logbuch leeren & Re-Sync", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(.top, 4)
                .alert("Logbuch wirklich zurücksetzen?", isPresented: $showResetAlert) {
                    Button("Abbrechen", role: .cancel) { }
                    Button("Logbuch leeren & Re-Sync", role: .destructive) {
                        viewModel.lotwManager.clearLogbookAndResetSync()
                    }
                } message: {
                    Text("Alle lokal gespeicherten QSOs werden gelöscht und das Logbuch wird beim nächsten Sync mit LoTW oder QRZ von 1900-01-01 an neu aufgebaut.")
                }
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
