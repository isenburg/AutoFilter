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
    case language = "Sprache"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .udp: return L("settings.tab.udp")
        case .cluster: return L("settings.tab.cluster")
        case .telnet: return L("settings.tab.telnet")
        case .sync: return L("settings.tab.sync")
        case .qth: return L("settings.tab.qth")
        case .mostWanted: return L("settings.tab.mostWanted")
        case .storage: return L("settings.tab.storage")
        case .options: return L("settings.tab.options")
        case .appearance: return L("settings.tab.appearance")
        case .language: return L("settings.tab.language")
        }
    }
    
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
        case .appearance: return "paintpalette"
        case .language: return "globe"
        }
    }
}

// MARK: - Hauptansicht für Einstellungen

struct SettingsView: View {
    @ObservedObject var viewModel: DecodeViewModel
    @ObservedObject private var langManager = LanguageManager.shared
    
    // Lokaler Zustand der UI & gespeicherte Ziel-Sektion
    @AppStorage("settingsSelectedSection") private var selectedSectionRaw: String = SettingsSection.udp.rawValue
    @State private var selectedSection: SettingsSection = .udp
    @State private var showResetAlert = false
    @State private var showDeleteLogbookAlert = false
    @State private var showQTHPickerSheet = false
    
    // MARK: - Persistent gespeicherte Einstellungen (@AppStorage)
    
    // WSJT-X UDP Einstellungen
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("udpBridgeAddress") private var udpBridgeAddress = "127.0.0.1"
    @AppStorage("udpBridgePort") private var udpBridgePort = 0
    
    // Logbuch & Dienst-Zugangsdaten
    @AppStorage("activeLogbookProvider") private var activeLogbookProvider: String = LogbookProvider.rumlog.rawValue
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
                        Text(section.title)
                            .font(.body)
                    }
                    .tag(section)
                }
                .listStyle(.sidebar)
                
                Spacer(minLength: 0)
            }
            .frame(width: 210)
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
        .onAppear {
            if let savedSection = SettingsSection(rawValue: selectedSectionRaw) {
                selectedSection = savedSection
            }
        }
        .onChange(of: selectedSection) { _, newSection in
            selectedSectionRaw = newSection.rawValue
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettingsSection"))) { note in
            if let targetRaw = note.object as? String, let targetSection = SettingsSection(rawValue: targetRaw) {
                selectedSection = targetSection
                selectedSectionRaw = targetSection.rawValue
            }
        }
    }
    
    private func resolutionDescription(for length: Int) -> String {
        let isDe = langManager.isGerman
        switch length {
        case 2: return isDe ? "2-Stellen Field" : "2-char Field"
        case 4: return isDe ? "4-Stellen Square" : "4-char Square"
        case 6: return isDe ? "6-Stellen Subsquare" : "6-char Subsquare"
        case 8...: return isDe ? "8-Stellen Extended Subsquare (Präzise)" : "8-char Extended Subsquare (Precise)"
        default: return "\(length)" + (isDe ? "-Stellen" : "-char")
        }
    }
    
    // MARK: - Subviews für Detailbereiche
    
    /// Generiert den passenden Inhaltsbereich basierend auf der selektierten Kategorie
    @ViewBuilder
    private func detailView(for section: SettingsSection) -> some View {
        switch section {
            
        // --- 1. WSJT-X UDP Server ---
        case .udp:
            let isDe = langManager.isGerman
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "WSJT-X UDP Server Verbindung" : "WSJT-X UDP Server Connection")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(isDe ? "UDP Server Adresse:" : "UDP Server Address:")
                        .font(.headline)
                    TextField("224.0.0.1", text: $udpAddress)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("UDP Server Port:")
                        .font(.headline)
                    NumericTextField("2237", value: $udpPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                HStack {
                    Text(isDe ? "Server-Typ:" : "Server Type:")
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
                
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(isDe ? "UDP Bridge Weiterleitungs-IP:" : "UDP Bridge Forwarding IP:")
                        .font(.headline)
                    TextField("127.0.0.1", text: $udpBridgeAddress)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(isDe ? "UDP Bridge Weiterleitungs-Port (0 = Aus):" : "UDP Bridge Forwarding Port (0 = Off):")
                        .font(.headline)
                    NumericTextField("z.B. 2238", value: $udpBridgePort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }
                
                let isMulticastBridge = {
                    if let firstOctetStr = udpBridgeAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
                       let firstOctet = Int(firstOctetStr) {
                        return firstOctet >= 224 && firstOctet <= 239
                    }
                    return false
                }()
                
                HStack {
                    Text(isDe ? "Bridge-Typ:" : "Bridge Type:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(isMulticastBridge ? "Multicast (MC)" : "Unicast (UC)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(isMulticastBridge ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                        .foregroundColor(isMulticastBridge ? .blue : .orange)
                        .cornerRadius(4)
                }
                
                Button(isDe ? "Server Verbinden / Neu Starten" : "Connect / Restart Server") {
                    let portVal = UInt16(udpPort)
                    viewModel.startServer(port: portVal, address: udpAddress)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
            
        // --- 2. DX Cluster Konfiguration ---
        case .cluster:
            let isDe = langManager.isGerman
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
                            Text(isDe ? "Keiner (Deaktiviert)" : "None (Disabled)").tag(ClusterServer?.none)
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
                            Text(isDe ? "Keiner (Deaktiviert)" : "None (Disabled)").tag(ClusterServer?.none)
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
                            Text(isDe ? "Keiner (Deaktiviert)" : "None (Disabled)").tag(ClusterServer?.none)
                            ForEach(viewModel.availableClusters) { cluster in
                                Text(cluster.name).tag(ClusterServer?.some(cluster))
                            }
                        }
                        .frame(maxWidth: 280)
                    }
                    
                    Divider()
                    
                    Text(isDe ? "DX Cluster verwalten" : "Manage DX Clusters")
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
            let isDe = langManager.isGerman
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Telnet Server")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "Telnet Server Port (Standard 8000):" : "Telnet Server Port (Default 8000):")
                            .font(.headline)
                        NumericTextField("8000", value: $telnetServerPort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: telnetServerPort) { _, _ in
                                viewModel.startTelnetServer()
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "Rufzeichen für Login (Standard GUEST):" : "Callsign for Login (Default GUEST):")
                            .font(.headline)
                        TextField("GUEST", text: $clusterCallsign)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 240)
                            .onChange(of: clusterCallsign) { _, _ in
                                viewModel.reconnectClusters()
                            }
                    }
                    
                    Toggle(isDe ? "WSJT-X Decodes über Telnet ausgeben" : "Broadcast WSJT-X decodes via Telnet", isOn: $isWsjtTelnetOutputEnabled)
                        .padding(.top, 4)
                }
                .padding(.trailing, 16)
            }
            
        // --- 4. Logbuch-Synchronisation & Daten-Import ---
        case .sync:
            let isDe = langManager.isGerman
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isDe ? "Aktive Logbuch-Quelle" : "Active Logbook Source")
                            .font(.title2)
                            .bold()
                        
                        Text(isDe ? "Wähle deine primäre Logbuch-Quelle für den automatischen Abgleich gearbeiteter Stationen und Grids:" : "Select your primary logbook source for automatic cross-referencing of worked stations and grids:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker(isDe ? "Logbuch-Quelle" : "Logbook Source", selection: $activeLogbookProvider) {
                            ForEach(LogbookProvider.allCases) { provider in
                                Label(provider.displayName, systemImage: provider.iconName).tag(provider.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 480)
                    }
                    
                    Divider()
                    
                    switch LogbookProvider(rawValue: activeLogbookProvider) ?? .rumlog {
                    case .rumlog:
                        // RUMlogNG macOS Integration
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "macbook.and.iphone")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                Text("RUMlogNG (macOS App)")
                                    .font(.title2)
                                    .bold()
                            }
                            
                            Text(isDe ? "Synchronisiert alle QSOs über die native macOS AppleScript-Schnittstelle direkt aus deiner lokal laufenden RUMlogNG-Anwendung." : "Synchronizes all QSOs via native macOS AppleScript directly from your locally running RUMlogNG app.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.syncRUMLog(fullSync: false)
                                }) {
                                    HStack(spacing: 6) {
                                        if viewModel.rumlogManager.isDownloading {
                                            ProgressView().controlSize(.small)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                        }
                                        Text(isDe ? "Inkrementeller Sync (Seit letztem Mal)" : "Incremental Sync (Since last sync)")
                                    }
                                }
                                .disabled(viewModel.rumlogManager.isDownloading)
                                .buttonStyle(.borderedProminent)
                                
                                Button(isDe ? "Vollständiger Sync (ab 1900)" : "Full Sync (since 1900)") {
                                    viewModel.syncRUMLog(fullSync: true)
                                }
                                .disabled(viewModel.rumlogManager.isDownloading)
                                .buttonStyle(.bordered)
                            }
                            .padding(.top, 4)
                            
                            if let error = viewModel.rumlogManager.errorMessage {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    
                                    if error.contains("Berechtigung") || error.contains("Automation") || error.contains("Permission") {
                                        Button(action: {
                                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                                                NSWorkspace.shared.open(url)
                                            }
                                        }) {
                                            Label(isDe ? "Systemeinstellungen (Automation) öffnen..." : "Open System Settings (Automation)...", systemImage: "lock.shield")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                    case .lotw:
                        // LoTW Abgleich
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "globe.americas.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                Text("Logbook of The World (LoTW)")
                                    .font(.title2)
                                    .bold()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isDe ? "Benutzername / Rufzeichen:" : "Username / Callsign:")
                                    .font(.headline)
                                TextField(isDe ? "Benutzername" : "Username", text: $lotwUsername)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 240)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isDe ? "Passwort:" : "Password:")
                                    .font(.headline)
                                SecureField(isDe ? "Passwort" : "Password", text: $lotwPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 240)
                            }
                            
                            HStack(spacing: 8) {
                                Button(isDe ? "LoTW Logbuch Synchronisieren (Vollständig ab 1900)" : "Sync LoTW Logbook (Full sync since 1900)") {
                                    viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword, fullSync: true)
                                }
                                .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 4)
                        }
                        
                    case .qrz:
                        // QRZ.com API
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                Text("QRZ.com Logbuch")
                                    .font(.title2)
                                    .bold()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("QRZ API Key:")
                                    .font(.headline)
                                SecureField("API Key", text: $qrzApiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 280)
                            }
                            
                            HStack(spacing: 8) {
                                Button(isDe ? "QRZ.com Logbuch Synchronisieren (Vollständig ab 1900)" : "Sync QRZ.com Logbook (Full sync since 1900)") {
                                    viewModel.syncQRZ(apiKey: qrzApiKey, fullSync: true)
                                }
                                .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    Divider()
                    
                    // Manueller ADIF-Datei Import
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isDe ? "Manueller ADIF-Datei Import" : "Manual ADIF File Import")
                            .font(.title3)
                            .bold()
                        
                        Text(isDe ? "Importiere QSOs aus einer lokalen .adi oder .adif Datei direkt in die SQLite-Datenbank." : "Import QSOs from a local .adi or .adif file directly into SQLite database.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(isDe ? "ADIF-Datei auswählen & importieren..." : "Select & Import ADIF File...") {
                            importADIFFile()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    // Lokale Datenbank zurücksetzen
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isDe ? "Lokales Logbuch löschen" : "Delete Local Logbook")
                            .font(.title3)
                            .bold()
                        
                        Text(isDe ? "Achtung: Dies löscht unwiderruflich alle lokal gespeicherten QSOs aus der SQLite-Datenbank." : "Warning: This permanently deletes all locally stored QSOs from the SQLite database.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(role: .destructive) {
                            showDeleteLogbookAlert = true
                        } label: {
                            Label(isDe ? "Logbuch löschen" : "Delete Logbook", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding(.trailing, 16)
            }
            .alert(isDe ? "Logbuch wirklich löschen?" : "Delete logbook permanently?", isPresented: $showDeleteLogbookAlert) {
                Button(isDe ? "Abbrechen" : "Cancel", role: .cancel) { }
                Button(isDe ? "Löschen" : "Delete", role: .destructive) {
                    let count = DatabaseManager.shared.clearAllQSOs()
                    viewModel.lotwManager.loadLog()
                    viewModel.lotwManager.addLog("Lokales Logbuch manuell gelöscht (\(count) Einträge entfernt).")
                }
            } message: {
                Text(isDe ? "Alle lokal gespeicherten QSOs werden unwiderruflich gelöscht. Dies betrifft nicht deine Logbücher auf LoTW oder QRZ.com." : "All locally stored QSOs will be deleted permanently. This does not affect your online logbooks on LoTW or QRZ.com.")
            }
            
        // --- Eigenes QTH (Maidenhead) ---
        case .qth:
            let isDe = langManager.isGerman
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text(isDe ? "Eigenes QTH (Maidenhead Locator)" : "Home QTH (Maidenhead Locator)")
                        .font(.title2)
                        .bold()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(isDe ? "Maidenhead Locator (max. 8 Zeichen):" : "Maidenhead Locator (max. 8 characters):")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        TextField(isDe ? "z.B. JO31AA00 oder JO31" : "e.g. JO31AA00 or JO31", text: Binding(
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
                                Text(isDe ? "Interaktive Karte zum Wählen 🗺️" : "Interactive Map Picker 🗺️")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    Text(isDe ? "Gib deinen präzisen Standorts-Locator ein (2- bis 8-Stellen)." : "Enter your precise station locator (2 to 8 characters).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Standort-Analyse & Koordinaten
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "Standort-Analyse & Auflösung:" : "Location Analysis & Resolution:")
                        .font(.headline)
                    
                    let cleanGrid = myGridLocator.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    if let coords = Maidenhead.locatorToLatLon(cleanGrid) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isDe ? "Breitengrad (Lat):" : "Latitude (Lat):")
                                    .font(.caption).foregroundColor(.secondary)
                                Text(String(format: "%.5f° %@", abs(coords.lat), coords.lat >= 0 ? "N" : "S"))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isDe ? "Längengrad (Lon):" : "Longitude (Lon):")
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
                            Text(isDe ? "Gültiger Locator: \(cleanGrid) (\(resolutionDescription(for: cleanGrid.count)))" : "Valid Locator: \(cleanGrid) (\(resolutionDescription(for: cleanGrid.count)))")
                                .font(.subheadline)
                                .bold()
                        }
                    } else if !cleanGrid.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(isDe ? "Ungültiges Locator-Format (z.B. JO31, JO31AA oder JO31AA00 verwenden)" : "Invalid locator format (e.g. use JO31, JO31AA or JO31AA00)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(isDe ? "Verwendung in AutoQSO:" : "Usage in AutoQSO:")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 5)
                            Text(isDe ? "Großkreis-Entfernungsberechnung (km) zu allen empfangenen Stationen und Spots." : "Great-circle distance calculation (km) to all received stations and spots.")
                        }
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 5)
                            Text(isDe ? "Visualisierung des eigenen Standorts (MY QTH) und der aktiven QSO-Verbindungspfade auf der Ausbreitungskarte (2D & 3D Globus)." : "Visualization of home station (MY QTH) and active QSO paths on propagation maps (2D & 3D Globe).")
                        }
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 5)
                            Text(isDe ? "Unterstützt präzise Positionierung bis zu 8-Stellen Subsquare Resolution (ca. 925m × 462m)." : "Supports precise positioning up to 8-character subsquare resolution (approx. 925m × 462m).")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

        // --- 5. Most Wanted & Prioritäts-Filter ---
        case .mostWanted:
            let isDe = langManager.isGerman
            VStack(alignment: .leading, spacing: 16) {
                Text(isDe ? "Most Wanted & Priorisierung" : "Most Wanted & Priority")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(isDe ? "Eigener Maidenhead Locator (Grid Square):" : "Home Maidenhead Locator (Grid Square):")
                        .font(.headline)
                    HStack(spacing: 8) {
                        TextField(isDe ? "z.B. JO31 oder JO31AA" : "e.g. JO31 or JO31AA", text: Binding(
                            get: { myGridLocator },
                            set: { newValue in
                                let cleaned = newValue.replacingOccurrences(of: " ", with: "").uppercased()
                                myGridLocator = String(cleaned.prefix(8))
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: 180)
                        
                        Button(isDe ? "Details im QTH-Tab ↗" : "Details in QTH Tab ↗") {
                            selectedSection = .qth
                        }
                        .buttonStyle(.borderless)
                    }
                    Text(isDe ? "Wird für die Entfernungsberechnung (km) zu decodierten Stationen genutzt." : "Used for distance calculation (km) to decoded stations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "Hervorhebung & Sortierung:" : "Highlighting & Sorting:")
                        .font(.headline)
                    
                    Toggle(isDe ? "Most Wanted Stationen rot hervorheben (🔥)" : "Highlight Most Wanted stations in red (🔥)", isOn: $highlightMostWanted)
                        .toggleStyle(.checkbox)
                    
                    Toggle(isDe ? "Priorität: Most Wanted zuerst, danach weiteste Entfernung" : "Priority: Most Wanted first, then furthest distance", isOn: $prioritizeMostWanted)
                        .toggleStyle(.checkbox)
                    
                    Toggle(isDe ? "Ausschließlich Most Wanted Stationen anrufen (Strikter DXCC-Filter)" : "Call Most Wanted stations only (Strict DXCC filter)", isOn: Binding(
                        get: { viewModel.isOnlyMostWantedFilterEnabled },
                        set: { viewModel.isOnlyMostWantedFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    ))
                        .toggleStyle(.checkbox)
                    
                    HStack {
                        Text(isDe ? "Most Wanted Schwelle:" : "Most Wanted Threshold:")
                            .font(.subheadline)
                        Picker("", selection: Binding(
                            get: { viewModel.maxMostWantedRank },
                            set: { viewModel.maxMostWantedRank = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                        )) {
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
                    Text(isDe ? "Such- & Priorisierungs-Reihenfolge:" : "Search & Priority Order:")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("1.")
                                .bold()
                            Text(isDe ? "Most Wanted Entitäten (Top \(viewModel.maxMostWantedRank))" : "Most Wanted Entities (Top \(viewModel.maxMostWantedRank))")
                                .bold()
                                .foregroundColor(.red)
                        }
                        HStack {
                            Text("2.")
                                .bold()
                            Text(isDe ? "Weiteste Entfernung (km basierend auf \(myGridLocator.isEmpty ? "JO31" : myGridLocator))" : "Furthest Distance (km based on \(myGridLocator.isEmpty ? "JO31" : myGridLocator))")
                                .bold()
                                .foregroundColor(.blue)
                        }
                        HStack {
                            Text("3.")
                                .bold()
                            Text(isDe ? "Stärkstes Signal (SNR dB)" : "Strongest Signal (SNR dB)")
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
            let isDe = langManager.isGerman
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "Datenbank & Speicherort" : "Database & Storage Location")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "Speicherort wählen:" : "Choose Storage Location:")
                        .font(.headline)
                    
                    Picker("", selection: $storageLocationMode) {
                        Text(isDe ? "Standard (~/Documents/AutoQSO)" : "Default (~/Documents/AutoQSO)").tag("default")
                        Text(isDe ? "Benutzerdefinierter Ordner" : "Custom Folder").tag("custom")
                        Text(isDe ? "iCloud Drive (Synchronisiert)" : "iCloud Drive (Synchronized)").tag("icloud")
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: storageLocationMode) { _, _ in
                        DatabaseManager.shared.switchStorageLocation()
                        viewModel.lotwManager.loadLog()
                    }
                }
                
                if storageLocationMode == "custom" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "Ausgewählter Pfad:" : "Selected Path:")
                            .font(.subheadline)
                        HStack {
                            Text(customStoragePath.isEmpty ? (isDe ? "Kein Ordner gewählt" : "No folder selected") : customStoragePath)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(isDe ? "Ordner wählen..." : "Choose Folder...") {
                                selectCustomFolder()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isDe ? "Aktueller SQLite Pfad:" : "Current SQLite Path:")
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
            let isDe = langManager.isGerman
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "Auto QSO Optionen" : "Auto QSO Options")
                    .font(.title2)
                    .bold()
                
                HStack(spacing: 8) {
                    Text(isDe ? "Sperrdauer für abgebrochene QSOs:" : "Cooldown for aborted QSOs:")
                        .font(.headline)
                    NumericTextField("10", value: $retryCooldownMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text(isDe ? "Minuten" : "Minutes")
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(L("settings.options.onlyCQ"), isOn: Binding(
                        get: { viewModel.isAutoModeOnlyCQEnabled },
                        set: { viewModel.isAutoModeOnlyCQEnabled = $0; viewModel.saveFilters() }
                    ))
                    .font(.headline)
                    
                    Text(L("settings.options.onlyCQ.desc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                Toggle(isDe ? "Nur ungearbeitete 4-Stellen Grids durchlassen (z.B. JO31)" : "Only allow unworked 4-char Grids (e.g. JO31)", isOn: Binding(
                    get: { viewModel.isNew4CharGridOnlyFilterEnabled },
                    set: { viewModel.isNew4CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                ))
                .font(.headline)

                Toggle(isDe ? "Nur ungearbeitete 6-Stellen Grids durchlassen (z.B. JO31aa)" : "Only allow unworked 6-char Grids (e.g. JO31aa)", isOn: Binding(
                    get: { viewModel.isNew6CharGridOnlyFilterEnabled },
                    set: { viewModel.isNew6CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                ))
                .font(.headline)
            }
            
        // --- 8. Ansicht, Schriftgrößen & Farbanpassungen ---
        case .appearance:
            let isDe = langManager.isGerman
            VStack(alignment: .leading, spacing: 20) {
                // 1. System-Farbschema & Ansichts-Optionen
                VStack(alignment: .leading, spacing: 12) {
                    Text(isDe ? "Farbschema & Darstellung" : "Theme & Appearance")
                        .font(.title2)
                        .bold()
                    
                    Picker(isDe ? "Darstellung:" : "Appearance:", selection: $appColorScheme) {
                        Text(isDe ? "System" : "System").tag("system")
                        Text(isDe ? "Hell" : "Light").tag("light")
                        Text(isDe ? "Dunkel" : "Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                    
                    Toggle(isDe ? "Neueste Einträge oben anzeigen (Tabelle & Logfenster)" : "Show newest entries on top (Table & Log console)", isOn: $isNewestOnTop)
                        .font(.subheadline)
                }
                
                Divider()
                
                // 2. Listen-Ansicht (Haupttabelle & Log-Konsole: Schriftgrößen + Farbanpassungen)
                VStack(alignment: .leading, spacing: 14) {
                    Text(isDe ? "Listen-Ansicht (Haupttabelle & Log-Konsole)" : "Table & Log Console Styling")
                        .font(.title2)
                        .bold()
                    
                    Text(isDe ? "Schriftgrößen:" : "Font Sizes:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(isDe ? "Tabelle Schriftgröße:" : "Table Font Size:")
                                .frame(width: 160, alignment: .leading)
                            Slider(value: $fontSizeTable, in: 8...20, step: 1) { Text("") }
                                .frame(width: 150)
                            Text("\(Int(fontSizeTable)) pt")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(isDe ? "Logs Schriftgröße:" : "Logs Font Size:")
                                .frame(width: 160, alignment: .leading)
                            Slider(value: $fontSizeLog, in: 8...20, step: 1) { Text("") }
                                .frame(width: 150)
                            Text("\(Int(fontSizeLog)) pt")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(isDe ? "Farbanpassungen:" : "Custom Colors:")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    Text(isDe ? "Haupttabelle:" : "Main Table:")
                        .font(.subheadline).bold()
                        .foregroundColor(.secondary)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text(isDe ? "Standard-Text" : "Standard Text")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableStandard", defaultColor: .primary))
                                .labelsHidden()
                            
                            Text("Most Wanted (🔥)")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableMostWanted", defaultColor: .red))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text(isDe ? "Interessante (CQ)" : "Interesting (CQ)")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableCQ", defaultColor: .green))
                                .labelsHidden()
                            
                            Text(isDe ? "Gearbeitete Stationen" : "Worked Stations")
                            ColorPicker("", selection: colorBinding(forKey: "colorTableWorked", defaultColor: .red.opacity(0.5)))
                                .labelsHidden()
                        }
                    }
                    
                    Text(isDe ? "Log-Konsole:" : "Log Console:")
                        .font(.subheadline).bold()
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text(isDe ? "Konsolen-Hintergrund" : "Console Background")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogBackground", defaultColor: Color(NSColor.textBackgroundColor)))
                                .labelsHidden()
                            
                            Text(isDe ? "System-Logs" : "System Logs")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogSystem", defaultColor: .primary))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text(isDe ? "WSJT-X Dekodierungen" : "WSJT-X Decodes")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogWsjtxDecode", defaultColor: .green))
                                .labelsHidden()
                            
                            Text(isDe ? "WSJT-X Eingehend" : "WSJT-X Incoming")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogWsjtxIncoming", defaultColor: .blue))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text(isDe ? "WSJT-X Ausgehend" : "WSJT-X Outgoing")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogWsjtxOutgoing", defaultColor: .orange))
                                .labelsHidden()
                            
                            Text(isDe ? "Cluster-Spots" : "Cluster Spots")
                            ColorPicker("", selection: colorBinding(forKey: "colorLogCluster", defaultColor: .primary))
                                .labelsHidden()
                        }
                    }
                    
                    Button(isDe ? "Listen-Ansicht auf Standard zurücksetzen" : "Reset Table & Log View to Defaults") {
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
                    Text(isDe ? "Landkarten-Ansicht (Maidenhead Grid-Overlay)" : "Map View (Maidenhead Grid Overlay)")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Text(isDe ? "Gitter Schriftgröße:" : "Grid Font Size:")
                            .frame(width: 180, alignment: .leading)
                        Slider(value: $gridOverlayFontSize, in: 8...22, step: 1) { Text("") }
                            .frame(width: 150)
                        Text("\(Int(gridOverlayFontSize)) pt")
                            .foregroundColor(.secondary)
                    }
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text(isDe ? "Beschriftung-Farbe:" : "Label Color:")
                            ColorPicker("", selection: colorBinding(forKey: "gridOverlayTextColor", defaultColor: Color(red: 1.0, green: 0.85, blue: 0.2)))
                                .labelsHidden()
                            
                            Text(isDe ? "Gitterlinien-Farbe:" : "Grid Line Color:")
                            ColorPicker("", selection: colorBinding(forKey: "gridOverlayLineColor", defaultColor: .cyan))
                                .labelsHidden()
                        }
                        
                        GridRow {
                            Text(isDe ? "Badge-Hintergrundfarbe:" : "Badge Background:")
                            ColorPicker("", selection: colorBinding(forKey: "gridOverlayBadgeColor", defaultColor: .black))
                                .labelsHidden()
                            
                            Text(isDe ? "Gearbeitete Grid-Felder:" : "Worked Grids:")
                            ColorPicker("", selection: colorBinding(forKey: "workedGridShadeColor", defaultColor: Color(red: 1.0, green: 0.35, blue: 0.15)))
                                .labelsHidden()
                        }
                    }
                    
                    Toggle(isDe ? "Dunkle Lesbarkeits-Badges hinter Schrift anzeigen" : "Show dark readability badges behind labels", isOn: $gridOverlayShowPill)
                        .toggleStyle(.checkbox)
                        .padding(.top, 4)
                    
                    Button(isDe ? "Karten-Ansicht auf Standard zurücksetzen" : "Reset Map View to Defaults") {
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
            
        // --- 9. Sprache / Language ---
        case .language:
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("settings.language.header"))
                        .font(.title2)
                        .bold()
                    
                    HStack(spacing: 12) {
                        Text(L("settings.language.select"))
                            .font(.headline)
                        
                        Picker("", selection: $langManager.selectedLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.title).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 280)
                    }
                    
                    Text(L("settings.language.desc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                
                Spacer()
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
    @ObservedObject private var langManager = LanguageManager.shared
    @State private var newName = ""
    @State private var newHost = ""
    @State private var newPort = "7373"
    
    private var isDe: Bool { langManager.isGerman }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Steuerungs-Buttons (Aktionen)
            HStack(spacing: 8) {
                Button(isDe ? "Zurücksetzen (Werkseinstellungen)" : "Restore Defaults") {
                    viewModel.restoreDefaultClusters()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(isDe ? "A-Z sortieren" : "Sort A-Z") {
                    viewModel.sortClusters()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Formularkarte: Neuen Cluster anlegen
            VStack(alignment: .leading, spacing: 6) {
                Text(isDe ? "Neuen Cluster registrieren:" : "Register New Cluster:")
                    .font(.subheadline)
                    .bold()
                
                HStack(spacing: 8) {
                    TextField(isDe ? "Name" : "Name", text: $newName)
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
                Text(isDe ? "Registrierte Cluster:" : "Registered Clusters:")
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
