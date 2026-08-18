import SwiftUI
import UniformTypeIdentifiers
import Network

// MARK: - Datenstrukturen & Navigation

/// Aufzählung aller Kategorien/Abschnitte im Einstellungsfenster
enum SettingsSection: String, CaseIterable, Identifiable {
    case udp = "UDP Server"
    case cluster = "DX Cluster"
    case telnet = "Telnet Server"
    case sync = "Logbuch-Sync"
    case qth = "Eigenes QTH (Maidenhead)"
    case mostWanted = "Most Wanted & Priorität"
    case storage = "Speicherort & iCloud"
    case options = "Auto Mode Optionen"
    case appearance = "Ansicht"
    
    var id: String { rawValue }
    
    /// Zuordnung der SFSymbols-Icons für die linke Navigationsleiste
    var icon: String {
        switch self {
        case .udp: return "network"
        case .cluster: return "antenna.radiowaves.left.and.right"
        case .telnet: return "terminal"
        case .sync: return "arrow.triangle.2.circlepath"
        case .qth: return "mappin.and.ellipse"
        case .mostWanted: return "flame.fill"
        case .storage: return "folder.fill"
        case .options: return "slider.horizontal.3"
        case .appearance: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Hauptansicht für Einstellungen

struct SettingsView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    // Lokaler Zustand der UI
    @State private var selectedSection: SettingsSection = .udp
    @State private var showResetAlert = false
    @State private var showDeleteLogbookAlert = false
    @State private var showQTHPickerSheet = false
    
    // MARK: - Persistent gespeicherte Einstellungen (@AppStorage)
    
    // WSJT-X UDP Einstellungen
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("udpBridgePort") private var udpBridgePort = 0
    
    // Logbuch & Dienst-Zugangsdaten
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    
    // Telnet & Cluster allgemeine Optionen
    @AppStorage("clusterCallsign") private var clusterCallsign = "GUEST"
    @AppStorage("telnetServerPort") private var telnetServerPort = 8000
    @AppStorage("isWsjtTelnetOutputEnabled") private var isWsjtTelnetOutputEnabled = false
    
    // Erscheinungsbild & UI-Größen
    @AppStorage("isNewestOnTop") private var isNewestOnTop = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("fontSizeTable") private var fontSizeTable = 11.0
    @AppStorage("fontSizeLog") private var fontSizeLog = 11.0
    @AppStorage("gridOverlayFontSize") private var gridOverlayFontSize = 11.0
    @AppStorage("gridOverlayShowPill") private var gridOverlayShowPill = true
    
    // Aktive Upstream DX Clusters (1 - 3)
    @AppStorage("isCluster1Enabled") private var isCluster1Enabled = false
    @AppStorage("cluster1Host") private var cluster1Host = "telnet.reversebeacon.net"
    @AppStorage("cluster1Port") private var cluster1Port = 7000
    
    @AppStorage("isCluster2Enabled") private var isCluster2Enabled = false
    @AppStorage("cluster2Host") private var cluster2Host = "dxc.ve7cc.net"
    @AppStorage("cluster2Port") private var cluster2Port = 23
    
    @AppStorage("isCluster3Enabled") private var isCluster3Enabled = false
    @AppStorage("cluster3Host") private var cluster3Host = "dx.k3lr.com"
    @AppStorage("cluster3Port") private var cluster3Port = 23
    
    // Standortspezifische & Priorisierungs-Parameter
    @AppStorage("myGridLocator") private var myGridLocator = "JO31"
    @AppStorage("highlightMostWanted") private var highlightMostWanted = true
    @AppStorage("prioritizeMostWanted") private var prioritizeMostWanted = true
    @AppStorage("onlyMostWanted") private var onlyMostWanted = false
    @AppStorage("maxMostWantedRank") private var maxMostWantedRank = 100
    
    // Datenbank Pfade & Modus
    @AppStorage("storageLocationMode") private var storageLocationMode = "default"
    @AppStorage("customStoragePath") private var customStoragePath = ""
    
    // MARK: - Berechnete Eigenschaften
    
    /// Hilfseigenschaft zur Ermittlung, ob die eingegebene IP eine Multicast-Adresse ist (224.x.x.x - 239.x.x.x)
    private var isMulticastAddress: Bool {
        if let firstOctetStr = udpAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
           let firstOctet = Int(firstOctetStr) {
            return firstOctet >= 224 && firstOctet <= 239
        }
        return false
    }
    
    // MARK: - Layout Body
    
    var body: some View {
        HStack(spacing: 0) {
            // Linke Navigations-Sidebar (feste Breite)
            VStack(alignment: .leading, spacing: 6) {
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
            .frame(width: 200)
            .fixedSize(horizontal: true, vertical: false) // Verhindert ungewolltes Dehnen der Sidebar
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Rechter Detail-Inhaltsbereich
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    detailView(for: selectedSection)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 740, minHeight: 380)
        .sheet(isPresented: $showQTHPickerSheet) {
            InteractiveQTHPickerView(myGridLocator: $myGridLocator)
        }
    }
    
    private func resolutionDescription(for length: Int) -> String {
        switch length {
        case 2: return "2-Stellen Field"
        case 4: return "4-Stellen Square"
        case 6: return "6-Stellen Subsquare"
        case 8...: return "8-Stellen Extended Subsquare (Präzise)"
        default: return "\(length)-Stellen"
        }
    }
    
    // MARK: - Subviews für Detailbereiche
    
    /// Generiert den passenden Inhaltsbereich basierend auf der selektierten Kategorie
    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
            
        // --- 1. WSJT-X UDP Server ---
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
                    NumericTextField("2237", value: $udpPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("UDP Bridge Weiterleitungs-Port (0 = Aus):")
                        .font(.headline)
                    NumericTextField("z.B. 2238", value: $udpBridgePort)
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
            
        // --- 2. DX Cluster Konfiguration ---
        case .cluster:
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("DX Cluster")
                        .font(.title2)
                        .bold()
                    
                    Text("Upstream DX Clusters")
                        .font(.title3)
                        .bold()
                        .padding(.top, 4)
                    
                    // Auswahl Cluster 1
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cluster 1:")
                            .font(.headline)
                        Picker("", selection: Binding(
                            get: {
                                viewModel.availableClusters.first { $0.host == cluster1Host && $0.port == cluster1Port && isCluster1Enabled }
                            },
                            set: { newValue in
                                if let cluster = newValue {
                                    cluster1Host = cluster.host
                                    cluster1Port = Int(cluster.port)
                                    isCluster1Enabled = true
                                } else {
                                    isCluster1Enabled = false
                                }
                                viewModel.reconnectClusters()
                            }
                        )) {
                            Text("Keiner (Deaktiviert)").tag(ClusterServer?.none)
                            ForEach(viewModel.availableClusters) { cluster in
                                Text(cluster.name).tag(ClusterServer?.some(cluster))
                            }
                        }
                        .frame(maxWidth: 280)
                    }
                    
                    // Auswahl Cluster 2
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cluster 2:")
                            .font(.headline)
                        Picker("", selection: Binding(
                            get: {
                                viewModel.availableClusters.first { $0.host == cluster2Host && $0.port == cluster2Port && isCluster2Enabled }
                            },
                            set: { newValue in
                                if let cluster = newValue {
                                    cluster2Host = cluster.host
                                    cluster2Port = Int(cluster.port)
                                    isCluster2Enabled = true
                                } else {
                                    isCluster2Enabled = false
                                }
                                viewModel.reconnectClusters()
                            }
                        )) {
                            Text("Keiner (Deaktiviert)").tag(ClusterServer?.none)
                            ForEach(viewModel.availableClusters) { cluster in
                                Text(cluster.name).tag(ClusterServer?.some(cluster))
                            }
                        }
                        .frame(maxWidth: 280)
                    }
                    
                    // Auswahl Cluster 3
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cluster 3:")
                            .font(.headline)
                        Picker("", selection: Binding(
                            get: {
                                viewModel.availableClusters.first { $0.host == cluster3Host && $0.port == cluster3Port && isCluster3Enabled }
                            },
                            set: { newValue in
                                if let cluster = newValue {
                                    cluster3Host = cluster.host
                                    cluster3Port = Int(cluster.port)
                                    isCluster3Enabled = true
                                } else {
                                    isCluster3Enabled = false
                                }
                                viewModel.reconnectClusters()
                            }
                        )) {
                            Text("Keiner (Deaktiviert)").tag(ClusterServer?.none)
                            ForEach(viewModel.availableClusters) { cluster in
                                Text(cluster.name).tag(ClusterServer?.some(cluster))
                            }
                        }
                        .frame(maxWidth: 280)
                    }
                    
                    Divider()
                    
                    Text("DX Cluster verwalten")
                        .font(.title3)
                        .bold()
                        .padding(.top, 4)
                    
                    // Einbindung des Verwaltungs-Subviews
                    ClusterManagerView(viewModel: viewModel)
                }
                .padding(.trailing, 16)
            }
            
        // --- 3. Telnet Server ---
        case .telnet:
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Telnet Server")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Telnet Server Port (Default 8000):")
                            .font(.headline)
                        NumericTextField("8000", value: $telnetServerPort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: telnetServerPort) { _, _ in
                                viewModel.startTelnetServer()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rufzeichen für Login (Default GUEST):")
                            .font(.headline)
                        TextField("GUEST", text: $clusterCallsign)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 240)
                            .onChange(of: clusterCallsign) { _, _ in
                                viewModel.reconnectClusters()
                            }
                    }
                    
                    Toggle("WSJT-X Decodes über Telnet ausgeben", isOn: $isWsjtTelnetOutputEnabled)
                        .padding(.top, 4)
                }
                .padding(.trailing, 16)
            }
            
        // --- 4. Logbuch-Synchronisation & Daten-Import ---
        case .sync:
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    
                    // LoTW Abgleich
                    VStack(alignment: .leading, spacing: 10) {
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
                            Button("LoTW Logbuch Synchronisieren (Vollständig ab 1900)") {
                                viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword, fullSync: true)
                            }
                            .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 4)
                    }
                    
                    Divider()
                    
                    // QRZ.com API
                    VStack(alignment: .leading, spacing: 10) {
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
                            Button("QRZ.com Logbuch Synchronisieren (Vollständig ab 1900)") {
                                viewModel.syncQRZ(apiKey: qrzApiKey, fullSync: true)
                            }
                            .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 4)
                    }
                    
                    Divider()
                    
                    // Manueller ADIF-Datei Import
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ADIF-Datei importieren")
                            .font(.title2)
                            .bold()
                        
                        Text("Importiere QSOs aus einer lokalen .adi oder .adif Datei direkt in die SQLite-Datenbank.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("ADIF-Datei auswählen & importieren...") {
                            importADIFFile()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    // Lokale Datenbank zurücksetzen
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lokales Logbuch löschen")
                            .font(.title2)
                            .bold()
                        
                        Text("Achtung: Dies löscht unwiderruflich alle lokal gespeicherten QSOs aus der SQLite-Datenbank.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(role: .destructive) {
                            showDeleteLogbookAlert = true
                        } label: {
                            Label("Logbuch löschen", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(.trailing, 16)
            }
            .alert("Logbuch wirklich löschen?", isPresented: $showDeleteLogbookAlert) {
                Button("Abbrechen", role: .cancel) { }
                Button("Löschen", role: .destructive) {
                    let count = DatabaseManager.shared.clearAllQSOs()
                    viewModel.lotwManager.loadLog()
                    viewModel.lotwManager.addLog("Lokales Logbuch manuell gelöscht (\(count) Einträge entfernt).")
                }
            } message: {
                Text("Alle lokal gespeicherten QSOs werden unwiderruflich gelöscht. Dies betrifft nicht deine Logbücher auf LoTW oder QRZ.com.")
            }
            
        // --- Eigenes QTH (Maidenhead) ---
        case .qth:
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Eigenes QTH (Maidenhead Locator)")
                        .font(.title2)
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Maidenhead Locator (max. 8 Zeichen):")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        TextField("z.B. JO31AA00 oder JO31", text: Binding(
                            get: { myGridLocator },
                            set: { newValue in
                                let cleaned = newValue.replacingOccurrences(of: " ", with: "").uppercased()
                                myGridLocator = String(cleaned.prefix(8))
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: 220)
                        
                        Button(action: { showQTHPickerSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "map.fill")
                                Text("Interaktive Karte zum Wählen 🗺️")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    Text("Geben Sie Ihren präzisen Standorts-Locator ein (2- bis 8-Stellen).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Standort-Analyse & Koordinaten
                VStack(alignment: .leading, spacing: 10) {
                    Text("Standort-Analyse & Auflösung:")
                        .font(.headline)
                    
                    let cleanGrid = myGridLocator.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    if let coords = Maidenhead.locatorToLatLon(cleanGrid) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Breitengrad (Lat):")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(String(format: "%.5f° %@", abs(coords.lat), coords.lat >= 0 ? "N" : "S"))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Längengrad (Lon):")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(String(format: "%.5f° %@", abs(coords.lon), coords.lon >= 0 ? "E" : "W"))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Gültiger Locator: \(cleanGrid) (\(resolutionDescription(for: cleanGrid.count)))")
                                .font(.subheadline)
                                .bold()
                        }
                    } else if !cleanGrid.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Ungültiges Locator-Format (z.B. JO31, JO31AA oder JO31AA00 verwenden)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verwendung in AutoQSO:")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 5)
                            Text("Großkreis-Entfernungsberechnung (km) zu allen empfangenen Stationen und Spots.")
                        }
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 5)
                            Text("Visualisierung des eigenen Standorts (MY QTH) und der aktiven QSO-Verbindungspfade auf der Ausbreitungskarte (2D & 3D Globus).")
                        }
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 5)
                            Text("Unterstützt präzise Positionierung bis zu 8-Stellen Subsquare Resolution (ca. 925m × 462m).")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

        // --- 5. Most Wanted & Prioritäts-Filter ---
        case .mostWanted:
            VStack(alignment: .leading, spacing: 16) {
                Text("Most Wanted & Priorisierung")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Eigener Maidenhead Locator (Grid Square):")
                        .font(.headline)
                    HStack(spacing: 8) {
                        TextField("z.B. JO31 oder JO31AA", text: Binding(
                            get: { myGridLocator },
                            set: { newValue in
                                let cleaned = newValue.replacingOccurrences(of: " ", with: "").uppercased()
                                myGridLocator = String(cleaned.prefix(8))
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: 180)
                        
                        Button("Details im QTH-Tab ↗") {
                            selectedSection = .qth
                        }
                        .buttonStyle(.borderless)
                    }
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
                    
                    Toggle("Ausschließlich Most Wanted Stationen anrufen (Strikter DXCC-Filter)", isOn: $onlyMostWanted)
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
                
                // Info-Box zur Regellogik
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
            
        // --- 6. Speicherort & Datenbank ---
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
            
        // --- 7. Auto QSO Betriebsoptionen ---
        case .options:
            VStack(alignment: .leading, spacing: 14) {
                Text("Auto QSO Optionen")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 8) {
                    Text("Sperrdauer für abgebrochene QSOs:")
                        .font(.headline)
                    NumericTextField("10", value: $retryCooldownMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("Minuten")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                Toggle("Nur ungearbeitete 4-Stellen Grids durchlassen (z.B. JO31)", isOn: Binding(
                    get: { viewModel.isNew4CharGridOnlyFilterEnabled },
                    set: { viewModel.isNew4CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                ))
                .font(.headline)

                Toggle("Nur ungearbeitete 6-Stellen Grids durchlassen (z.B. JO31aa)", isOn: Binding(
                    get: { viewModel.isNew6CharGridOnlyFilterEnabled },
                    set: { viewModel.isNew6CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                ))
                .font(.headline)
            }
            
        // --- 8. Ansicht, Schriftgrößen & Farbanpassungen ---
        case .appearance:
            VStack(alignment: .leading, spacing: 20) {
                // 1. System-Farbschema & Ansichts-Optionen
                VStack(alignment: .leading, spacing: 12) {
                    Text("Farbschema & Darstellung")
                        .font(.title2)
                        .bold()
                    
                    Picker("Darstellung:", selection: $appColorScheme) {
                        Text("System").tag("system")
                        Text("Hell").tag("light")
                        Text("Dunkel").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                    
                    Toggle("Neueste Einträge oben anzeigen (Tabelle & Logfenster)", isOn: $isNewestOnTop)
                        .font(.subheadline)
                }
                
                Divider()
                
                // 2. Listen-Ansicht (Haupttabelle & Log-Konsole: Schriftgrößen + Farbanpassungen)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Listen-Ansicht (Haupttabelle & Log-Konsole)")
                        .font(.title2)
                        .bold()
                    
                    Text("Schriftgrößen:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tabelle Schriftgröße:")
                                .frame(width: 160, alignment: .leading)
                            Slider(value: $fontSizeTable, in: 8...20, step: 1) { Text("") }
                                .frame(width: 150)
                            Text("\(Int(fontSizeTable)) pt")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Logs Schriftgröße:")
                                .frame(width: 160, alignment: .leading)
                            Slider(value: $fontSizeLog, in: 8...20, step: 1) { Text("") }
                                .frame(width: 150)
                            Text("\(Int(fontSizeLog)) pt")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Farbanpassungen:")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    Text("Haupttabelle:")
                        .font(.subheadline).bold()
                        .foregroundColor(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("Standard-Text")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableStandard", defaultColor: .primary))
                                .labelsHidden()
                            
                            Text("Most Wanted (🔥)")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableMostWanted", defaultColor: .red))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text("Interessante (CQ)")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableCQ", defaultColor: .green))
                                .labelsHidden()
                            
                            Text("Gearbeitete Stationen")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableWorked", defaultColor: .red.opacity(0.5)))
                                .labelsHidden()
                        }
                    }
                    
                    Text("Log-Konsole:")
                        .font(.subheadline).bold()
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("Konsolen-Hintergrund")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogBackground", defaultColor: Color(NSColor.textBackgroundColor)))
                                .labelsHidden()
                            
                            Text("System-Logs")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogSystem", defaultColor: .primary))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text("WSJT-X Dekodierungen")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogWsjtxDecode", defaultColor: .green))
                                .labelsHidden()
                            
                            Text("WSJT-X Eingehend")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogWsjtxIncoming", defaultColor: .blue))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text("WSJT-X Ausgehend")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogWsjtxOutgoing", defaultColor: .orange))
                                .labelsHidden()
                            
                            Text("Cluster-Spots")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogCluster", defaultColor: .primary))
                                .labelsHidden()
                        }
                    }
                    
                    Button("Listen-Ansicht auf Standard zurücksetzen") {
                        fontSizeTable = 11.0
                        fontSizeLog = 11.0
                        UserDefaults.standard.removeObject(forKey: "colorTableStandard")
                        UserDefaults.standard.removeObject(forKey: "colorTableMostWanted")
                        UserDefaults.standard.removeObject(forKey: "colorTableWorked")
                        UserDefaults.standard.removeObject(forKey: "colorTableCQ")
                        UserDefaults.standard.removeObject(forKey: "colorLogBackground")
                        UserDefaults.standard.removeObject(forKey: "colorLogSystem")
                        UserDefaults.standard.removeObject(forKey: "colorLogWsjtxDecode")
                        UserDefaults.standard.removeObject(forKey: "colorLogWsjtxIncoming")
                        UserDefaults.standard.removeObject(forKey: "colorLogWsjtxOutgoing")
                        UserDefaults.standard.removeObject(forKey: "colorLogCluster")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 6)
                }
                
                Divider()
                
                // 3. Landkarten-Ansicht (Maidenhead Grid-Overlay)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Landkarten-Ansicht (Maidenhead Grid-Overlay)")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text("Gitter Schriftgröße:")
                            .frame(width: 180, alignment: .leading)
                        Slider(value: $gridOverlayFontSize, in: 8...22, step: 1) { Text("") }
                            .frame(width: 150)
                        Text("\(Int(gridOverlayFontSize)) pt")
                            .foregroundColor(.secondary)
                    }
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("Beschriftung-Farbe:")
                            ColorPicker("", selection: colorBinding(forKey: "gridOverlayTextColor", defaultColor: Color(red: 1.0, green: 0.85, blue: 0.2)))
                                .labelsHidden()
                            
                            Text("Gitterlinien-Farbe:")
                            ColorPicker("", selection: colorBinding(forKey: "gridOverlayLineColor", defaultColor: .cyan))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text("Badge-Hintergrundfarbe:")
                            ColorPicker("", selection: colorBinding(forKey: "gridOverlayBadgeColor", defaultColor: .black))
                                .labelsHidden()
                            
                            Text("Gearbeitete Grid-Felder:")
                            ColorPicker("", selection: colorBinding(forKey: "workedGridShadeColor", defaultColor: Color(red: 1.0, green: 0.35, blue: 0.15)))
                                .labelsHidden()
                        }
                    }
                    
                    Toggle("Dunkle Lesbarkeits-Badges hinter Schrift anzeigen", isOn: $gridOverlayShowPill)
                        .toggleStyle(.checkbox)
                        .padding(.top, 4)
                    
                    Button("Karten-Ansicht auf Standard zurücksetzen") {
                        gridOverlayFontSize = 11.0
                        gridOverlayShowPill = true
                        UserDefaults.standard.removeObject(forKey: "gridOverlayTextColor")
                        UserDefaults.standard.removeObject(forKey: "gridOverlayLineColor")
                        UserDefaults.standard.removeObject(forKey: "gridOverlayBadgeColor")
                        UserDefaults.standard.removeObject(forKey: "workedGridShadeColor")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 6)
                }
            }
        }
    }
    
    // MARK: - Hilfsfunktionen
    
    /// Erstellt ein Binding für ColorPickers mit automatischer Konvertierung von/zu Hex-Strings in UserDefaults
    private func colorBinding(forKey key: String, defaultColor: Color) -> Binding<Color> {
        Binding(
            get: {
                let hex = UserDefaults.standard.string(forKey: key) ?? ""
                return hex.isEmpty ? defaultColor : Color(hex: hex, defaultColor: defaultColor)
            },
            set: { newColor in
                if let hex = newColor.toHex() {
                    UserDefaults.standard.set(hex, forKey: key)
                }
            }
        )
    }

    /// Öffnet den macOS Datei-Dialog zur Auswahl eines benutzerdefinierten Speicherorts
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
    
    /// Öffnet den Dateiauswahldialog für ADIF-Logbuch-Importe
    private func importADIFFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "adi")!, UTType(filenameExtension: "adif")!].compactMap { $0 }
        panel.prompt = "Importieren"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let entries = ADIFParser.parseQSOs(from: content)
                guard !entries.isEmpty else {
                    let alert = NSAlert()
                    alert.messageText = "ADIF Import"
                    alert.informativeText = "Es wurden keine gültigen QSOs in der Datei gefunden."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    return
                }
                
                let inserted = DatabaseManager.shared.insertQSOs(entries)
                viewModel.lotwManager.loadLog()
                
                viewModel.lotwManager.addLog("ADIF Import: \(inserted) von \(entries.count) QSOs erfolgreich importiert.")
                
                let alert = NSAlert()
                alert.messageText = "ADIF Import erfolgreich"
                alert.informativeText = "\(inserted) von \(entries.count) QSOs wurden erfolgreich in das lokale Logbuch importiert."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
                
            } catch {
                let alert = NSAlert()
                alert.messageText = "Fehler beim Lesen der Datei"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}

// MARK: - Subview: DX Cluster Manager

/// View zur Bearbeitung, Sortierung und Hinzufügen von DX Cluster Servern
struct ClusterManagerView: View {
    @ObservedObject var viewModel: DecodeViewModel
    @State private var newName = ""
    @State private var newHost = ""
    @State private var newPort = "7373"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Steuerungs-Buttons (Aktionen)
            HStack(spacing: 8) {
                Button("Zurücksetzen (Restore Defaults)") {
                    viewModel.restoreDefaultClusters()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("A-Z sortieren") {
                    viewModel.sortClusters()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Formularkarte: Neuen Cluster anlegen
            VStack(alignment: .leading, spacing: 6) {
                Text("Neuen Cluster registrieren:")
                    .font(.subheadline)
                    .bold()
                
                HStack(spacing: 8) {
                    TextField("Name", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                        .controlSize(.small)
                    
                    TextField("Host (z.B. dxc.example.com)", text: $newHost)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                        .controlSize(.small)
                    
                    TextField("Port", text: $newPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .controlSize(.small)
                    
                    Button {
                        if let portVal = UInt16(newPort), !newName.isEmpty, !newHost.isEmpty {
                            viewModel.addCluster(name: newName, host: newHost, port: portVal)
                            newName = ""
                            newHost = ""
                            newPort = "7373"
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .disabled(newName.isEmpty || newHost.isEmpty || UInt16(newPort) == nil)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            
            // Liste der registrierten Cluster mit Bearbeiten-/Löschen-Funktion
            VStack(alignment: .leading, spacing: 6) {
                Text("Registrierte Cluster:")
                    .font(.subheadline)
                    .bold()
                
                List {
                    ForEach(viewModel.availableClusters) { cluster in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cluster.name)
                                    .bold()
                                Text("\(cluster.host):\(String(cluster.port))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // Edit-Button (Überträgt Werte ins Formular)
                            Button {
                                newName = cluster.name
                                newHost = cluster.host
                                newPort = String(cluster.port)
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                            
                            // Delete-Button
                            Button(role: .destructive) {
                                viewModel.removeCluster(cluster)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { indices, newOffset in
                        viewModel.moveCluster(from: indices, to: newOffset)
                    }
                }
                .frame(minHeight: 250, maxHeight: 400)
                .cornerRadius(4)
            }
        }
    }
}
