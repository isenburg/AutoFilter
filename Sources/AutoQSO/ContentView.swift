import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    @AppStorage("mostWantedPanelHeight") private var mostWantedPanelHeight: Double = 120.0
    @AppStorage("decode_column_customization") private var decodeColumnCustomization: TableColumnCustomization<WSJTXDecode>
    @AppStorage("compact_decode_column_customization") private var compactDecodeColumnCustomization: TableColumnCustomization<WSJTXDecode>
    
    @State private var tableSelection: WSJTXDecode.ID? = nil
    
    @AppStorage("isSidebarVisible") private var isSidebarVisible = true
    @AppStorage("isLeftSidebarVisible") private var isLeftSidebarVisible = true
    @AppStorage("leftSidebarWidth") private var leftSidebarWidth: Double = 240.0
    @AppStorage("rightSidebarWidth") private var rightSidebarWidth: Double = 280.0
    @AppStorage("udpBridgePort") private var udpBridgePort = 0
    @State private var rightSidebarTab = 0
    
    // Console Tabs: 0 = System, 1 = WSJT-X, 2 = Cluster-Spots
    @AppStorage("logConsoleTab") private var consoleTab = 0
    @AppStorage("isLogConsoleDetached") private var isLogConsoleDetached = false
    @AppStorage("isNewestOnTop") private var isNewestOnTop = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("mainTab") private var mainTab = 0
    @AppStorage("logConsoleHeight") private var logConsoleHeight = 150.0
    @AppStorage("fontSizeTable") private var fontSizeTable = 11.0
    @AppStorage("fontSizeLog") private var fontSizeLog = 11.0
    @AppStorage("colorTableStandard") private var colorTableStandard = ""
    @AppStorage("colorTableCQ") private var colorTableCQ = ""
    @AppStorage("colorTableWorked") private var colorTableWorked = ""
    @AppStorage("colorTableMostWanted") private var colorTableMostWanted = ""
    @AppStorage("highlightMostWanted") private var highlightMostWanted = true
    @AppStorage("wsjtxShowDecodes") private var wsjtxShowDecodes = true
    @AppStorage("wsjtxShowIncoming") private var wsjtxShowIncoming = true
    @AppStorage("wsjtxShowOutgoing") private var wsjtxShowOutgoing = true
    
    @AppStorage("clusterCallsign") private var clusterCallsign = "GUEST"
    @AppStorage("telnetServerPort") private var telnetServerPort = 8000
    @AppStorage("isWsjtTelnetOutputEnabled") private var isWsjtTelnetOutputEnabled = false
    
    @AppStorage("isCluster1Enabled") private var isCluster1Enabled = false
    @AppStorage("cluster1Host") private var cluster1Host = "telnet.reversebeacon.net"
    @AppStorage("cluster1Port") private var cluster1Port = 7000
    
    @AppStorage("isCluster2Enabled") private var isCluster2Enabled = false
    @AppStorage("cluster2Host") private var cluster2Host = "dxc.ve7cc.net"
    @AppStorage("cluster2Port") private var cluster2Port = 23
    
    @AppStorage("isCluster3Enabled") private var isCluster3Enabled = false
    @AppStorage("cluster3Host") private var cluster3Host = "dx.k3lr.com"
    @AppStorage("cluster3Port") private var cluster3Port = 23
    
    // Left Sidebar Expanded sections
    @AppStorage("isWsjtxServerExpanded") private var isWsjtxServerExpanded = true
    @AppStorage("isUdpBridgeExpanded") private var isUdpBridgeExpanded = true
    @AppStorage("isDxClusterExpanded") private var isDxClusterExpanded = true
    @AppStorage("isTelnetServerExpanded") private var isTelnetServerExpanded = true
    
    // Expanded sections
    @AppStorage("isBlockedCountriesExpanded") private var isBlockedCountriesExpanded = true
    @AppStorage("isAllowedDXCountriesExpanded") private var isAllowedDXCountriesExpanded = true
    @AppStorage("isContinentFilterExpanded") private var isContinentFilterExpanded = true
    @AppStorage("isBlockedCQZonesExpanded") private var isBlockedCQZonesExpanded = true
    @AppStorage("isBlockedITUZonesExpanded") private var isBlockedITUZonesExpanded = true
    @AppStorage("isWsjtSpecialFilterExpanded") private var isWsjtSpecialFilterExpanded = true
    @AppStorage("isNewGridFilterExpanded") private var isNewGridFilterExpanded = true
    @AppStorage("isDuplicateFilterExpanded") private var isDuplicateFilterExpanded = true
    @AppStorage("isAllowedDXCallsignsExpanded") private var isAllowedDXCallsignsExpanded = true
    @AppStorage("isAllowedSpotterCountriesExpanded") private var isAllowedSpotterCountriesExpanded = true
    @AppStorage("isAllowedSpotterCallsignsExpanded") private var isAllowedSpotterCallsignsExpanded = true
    
    // Form Inputs
    @State private var newCountry = ""
    @State private var newAllowedDXCountry = ""
    @State private var newCQZone = ""
    @State private var newITUZone = ""
    @State private var newAllowedDXCallsign = ""
    @State private var newSpotterCountry = ""
    @State private var newAllowedSpotterCallsign = ""
    
    @Environment(\.openWindow) private var openWindow
    @AppStorage("isCompactMode") private var isCompactMode = false
    @AppStorage("normalWindowWidth") private var normalWindowWidth = 850.0
    @AppStorage("normalWindowHeight") private var normalWindowHeight = 600.0
    @AppStorage("compactWindowWidth") private var compactWindowWidth = 500.0
    @AppStorage("compactWindowHeight") private var compactWindowHeight = 350.0
    @AppStorage("compactMostWantedHeight") private var compactMostWantedHeight = 60.0
    
    @State private var hostingWindow: NSWindow? = nil
    @State private var isTransitioningMode = true
    @State private var isClusterSendSheetPresented = false
    
    private var isMulticastAddress: Bool {
        if let firstOctetStr = udpAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
           let firstOctet = Int(firstOctetStr) {
            return firstOctet >= 224 && firstOctet <= 239
        }
        return false
    }
    
    @AppStorage("showOnlyAcceptedSpots") private var showOnlyAcceptedSpots = false
    
    private var displayDecodes: [WSJTXDecode] {
        let baseList: [WSJTXDecode]
        if viewModel.isMainTableScrollPaused, let frozen = viewModel.frozenMainDecodes {
            baseList = frozen
        } else {
            baseList = viewModel.server.decodes
        }
        
        let query = viewModel.mainTableSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var filtered: [WSJTXDecode]
        
        if showOnlyAcceptedSpots {
            filtered = baseList.filter { viewModel.shouldAccept(decode: $0, recordDuplicates: false) }
        } else {
            filtered = baseList
        }
        
        if !query.isEmpty {
            filtered = filtered.filter { decode in
                decode.callsign.lowercased().contains(query) ||
                decode.country.lowercased().contains(query) ||
                decode.spotter.lowercased().contains(query) ||
                (decode.grid?.lowercased().contains(query) ?? false) ||
                decode.message.lowercased().contains(query)
            }
        }
        
        return isNewestOnTop ? filtered : filtered.reversed()
    }
    
    private var preferredScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    @ViewBuilder
    private var topToolbarView: some View {
        HStack(alignment: .center, spacing: 0) {
            // 1. LEFT SIDEBAR TOGGLE: Connection (Verbindung) button aligned above connection sidebar
            HStack {
                if isLeftSidebarVisible {
                    Button(action: {
                        isLeftSidebarVisible.toggle()
                    }) {
                        Image(systemName: "sidebar.left")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Verbindungs-Seitenleiste ausblenden")
                } else {
                    Button(action: {
                        isLeftSidebarVisible.toggle()
                    }) {
                        Image(systemName: "sidebar.left")
                    }
                    .buttonStyle(.bordered)
                    .help("Verbindungs-Seitenleiste einblenden")
                }
            }
            .frame(width: isLeftSidebarVisible ? CGFloat(leftSidebarWidth) : 100, alignment: .leading)
            
            Spacer()
            
            // 2. CENTER: AutoQSO / WSJTX Auto Transmit, Logbook, Sortierung, and standard window buttons (all centered on one single line!)
            HStack(alignment: .center, spacing: 12) {
                // WSJTX Auto Mode Section (AutoQSO)
                HStack(spacing: 6) {
                    Button(action: {
                        viewModel.isAutoModeEnabled.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isAutoModeEnabled ? "play.circle.fill" : "play.circle")
                            Text(viewModel.isAutoModeEnabled ? "Auto ON" : "Auto OFF")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isAutoModeEnabled ? .green : .gray)
                    
                    NumericTextField("10", value: $retryCooldownMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 45)
                    
                    Text("Min. Sperre")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                // Sort Order & Pause Section
                Button(action: {
                    isNewestOnTop.toggle()
                }) {
                    Image(systemName: isNewestOnTop ? "arrow.up" : "arrow.down")
                }
                .buttonStyle(.bordered)
                .help(isNewestOnTop ? "Sortierung: Neueste unten" : "Sortierung: Neueste oben")
                
                Button(action: {
                    viewModel.isMainTableScrollPaused.toggle()
                }) {
                    Image(systemName: viewModel.isMainTableScrollPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.bordered)
                .foregroundColor(viewModel.isMainTableScrollPaused ? .orange : .primary)
                .help(viewModel.isMainTableScrollPaused ? "Auto-Scroll fortsetzen" : "Auto-Scroll anhalten")
                
                // Filter Switch: Nur akzeptierte/gefilterte Spots anzeigen (links von Suchen)
                if showOnlyAcceptedSpots {
                    Button(action: {
                        showOnlyAcceptedSpots.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Nur gefilterte Spots anzeigen (Aktiv) – Klicken, um alle Spots anzuzeigen")
                } else {
                    Button(action: {
                        showOnlyAcceptedSpots.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .buttonStyle(.bordered)
                    .help("Alle Spots anzeigen – Klicken, um nur gefilterte Spots anzuzeigen")
                }

                // Search field (shortened placeholder to "Suchen...")
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Suchen...", text: $viewModel.mainTableSearchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                        .frame(width: 120)
                    if !viewModel.mainTableSearchText.isEmpty {
                        Button(action: { viewModel.mainTableSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                
                Button(action: {
                    viewModel.clearTable()
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help("Dekodierte Stationen aus der Tabelle löschen")
                
                Divider()
                    .frame(height: 20)
                
                // Standard Window buttons (centered)
                HStack(spacing: 6) {
                    Button(action: {
                        openWindow(id: "logbook")
                    }) {
                        Image(systemName: "book")
                    }
                    .buttonStyle(.bordered)
                    .help("LoTW Logbuch öffnen")

                    Button(action: {
                        openWindow(id: "propagation_map")
                    }) {
                        Image(systemName: "map")
                    }
                    .buttonStyle(.bordered)
                    .help("Ausbreitungskarte in eigenem Fenster öffnen")
                    
                    Button(action: {
                        openWindow(id: "new_grid_map")
                    }) {
                        Image(systemName: "square.grid.3x3.topleft.filled")
                    }
                    .buttonStyle(.bordered)
                    .help("Neue 4-Stellen Grid-Karte in eigenem Fenster öffnen")
                    
                    Button(action: {
                        toggleCompactMode(toCompact: true)
                    }) {
                        Image(systemName: "rectangle.compress.vertical")
                    }
                    .buttonStyle(.bordered)
                    .help("Kompaktmodus aktivieren")
                    
                    Button(action: {
                        openWindow(id: "settings")
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .help("Einstellungen öffnen")
                    
                    Button(action: {
                        openWindow(id: "help")
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .help("Hilfe & Info öffnen")
                }
            }
            
            Spacer()
            
            // 3. RIGHT SIDEBAR TOGGLE: Filter (DX-Filter) button aligned above filter sidebar
            HStack {
                if isSidebarVisible {
                    Button(action: {
                        isSidebarVisible.toggle()
                    }) {
                        Image(systemName: "sidebar.right")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .help("Filter-Seitenleiste ausblenden")
                } else {
                    Button(action: {
                        isSidebarVisible.toggle()
                    }) {
                        Image(systemName: "sidebar.right")
                    }
                    .buttonStyle(.bordered)
                    .help("Filter-Seitenleiste einblenden")
                }
            }
            .frame(width: isSidebarVisible ? CGFloat(rightSidebarWidth) : 100, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor))
    }

    @ViewBuilder
    private var displayBannerView: some View {
        if !viewModel.displayCallsign.isEmpty {
            let displayCall = viewModel.displayCallsign
            let workedBands = Set(viewModel.lotwManager.workedBands(for: displayCall))
            let allBands = ["160M", "80M", "60M", "40M", "30M", "20M", "17M", "15M", "12M", "10M", "6M"]
            let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
            
            // Find matching decode to get grid locator and calculate distance
            let matchingDecode = viewModel.server.decodes.first(where: { $0.callsign.uppercased() == displayCall.uppercased() })
            let grid = matchingDecode?.grid
            let distanceKm = matchingDecode?.distanceKm(myGrid: myGrid)
            let mwRank = MostWantedManager.shared.rankForCallsign(displayCall)
            
            HStack(spacing: 14) {
                HStack(spacing: 8) {
                    Text(displayCall)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(mwRank != nil ? .red : .orange)
                    
                    if let rank = mwRank {
                        Text("🔥 #\(rank)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    Button(action: {
                        openQRZ(callsign: displayCall)
                    }) {
                        Label("QRZ.com", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
                
                Divider()
                    .frame(height: 20)
                
                // Distance & Grid Badge
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    if let dist = distanceKm {
                        Text(String(format: "%.0f km", dist))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                        if let g = grid {
                            Text("(\(g))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else if let g = grid {
                        Text("Grid: \(g)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Entfernung: -")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                
                Divider()
                    .frame(height: 20)
                
                Text("LoTW / QRZ Bänder:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(allBands, id: \.self) { band in
                            let isWorked = workedBands.contains(band)
                            Text(band)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(isWorked ? Color.green : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(isWorked ? .white : .secondary)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(isWorked ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            Divider()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isCompactMode {
                compactMainView
            } else {
                normalMainView
            }
        }
        .onChange(of: viewModel.totalReceived) { _, _ in
            guard !viewModel.isMainTableScrollPaused else { return }
            self.scrollToNewestRow()
        }
        .onChange(of: viewModel.isMainTableScrollPaused) { _, isPaused in
            if !isPaused {
                self.scrollToNewestRow()
            }
        }
        .onChange(of: isNewestOnTop) { _, _ in
            if !viewModel.isMainTableScrollPaused {
                self.scrollToNewestRow()
            }
        }
        .alert("Fehler beim LoTW Sync", isPresented: Binding(
            get: { viewModel.lotwManager.errorMessage != nil },
            set: { if !$0 { viewModel.lotwManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.lotwManager.errorMessage ?? "")
        }
        .onAppear {
            viewModel.retryCooldownMinutes = retryCooldownMinutes
            viewModel.startServer(port: UInt16(udpPort), address: udpAddress)
        }
        .onChange(of: tableSelection) { _, newID in
            // Banner auf angeklickte Zeile aktualisieren
            if let id = newID,
               let decode = viewModel.server.decodes.first(where: { $0.id == id }) {
                viewModel.selectedCallsign = decode.callsign
            } else {
                // Keine Selektion → zurück auf aktiven DX-Call
                viewModel.selectedCallsign = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenHelpWindow"))) { _ in
            openWindow(id: "help")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenSettingsWindow"))) { _ in
            openWindow(id: "settings")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenLogbookWindow"))) { _ in
            openWindow(id: "logbook")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPropagationMapWindow"))) { _ in
            openWindow(id: "propagation_map")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenNewGridMapWindow"))) { _ in
            openWindow(id: "new_grid_map")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenLogsRawWindow"))) { _ in
            openWindow(id: "logs_raw")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleCompactMode"))) { _ in
            toggleCompactMode(toCompact: !isCompactMode)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleLeftSidebar"))) { _ in
            isLeftSidebarVisible.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleRightSidebar"))) { _ in
            isSidebarVisible.toggle()
        }
        .onChange(of: retryCooldownMinutes) { _, newValue in
            viewModel.retryCooldownMinutes = newValue
        }
        .onChange(of: viewModel.selectedCallsign) { _, newValue in
            if newValue.isEmpty {
                tableSelection = nil
            }
        }
        .onChange(of: udpPort) { _, newValue in
            viewModel.startServer(port: UInt16(newValue), address: udpAddress)
        }
        .onChange(of: udpAddress) { _, newValue in
            viewModel.startServer(port: UInt16(udpPort), address: newValue)
        }
        .preferredColorScheme(preferredScheme)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.size) { _, newSize in
                        guard !self.isTransitioningMode else { return }
                        if self.isCompactMode {
                            if newSize.width >= 480 && newSize.height >= 320 {
                                self.compactWindowWidth = Double(newSize.width)
                                self.compactWindowHeight = Double(newSize.height)
                            }
                        } else {
                            if newSize.width >= 550 && newSize.height >= 500 {
                                self.normalWindowWidth = Double(newSize.width)
                                self.normalWindowHeight = Double(newSize.height)
                            }
                        }
                    }
            }
        )
        .background(WindowAccessor { window in
            if self.hostingWindow == nil {
                self.hostingWindow = window
                let targetWidth = self.isCompactMode ? self.compactWindowWidth : self.normalWindowWidth
                let targetHeight = self.isCompactMode ? self.compactWindowHeight : self.normalWindowHeight
                let currentFrame = window.frame
                let newY = currentFrame.maxY - CGFloat(targetHeight)
                let newFrame = NSRect(
                    x: currentFrame.minX,
                    y: newY,
                    width: CGFloat(targetWidth),
                    height: CGFloat(targetHeight)
                )
                window.setFrame(newFrame, display: true)
                
                // Allow layout to stabilize before enabling tracking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isTransitioningMode = false
                }
            }
        })
        .frame(
            minWidth: isCompactMode ? 480 : (800 + (isLeftSidebarVisible ? 220 : 0) + (isSidebarVisible ? 250 : 0)),
            idealWidth: isCompactMode ? 520 : 1380,
            minHeight: isCompactMode ? 320 : 650,
            idealHeight: isCompactMode ? 380 : 750
        )
    }

    @ViewBuilder
    private var normalMainView: some View {
        topToolbarView
        Divider()
        displayBannerView
        
        HSplitView {
            if isLeftSidebarVisible {
                leftSidebar
                    .frame(minWidth: 220, idealWidth: CGFloat(leftSidebarWidth), maxWidth: 300, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: LeftSidebarWidthPreferenceKey.self, value: geo.size.width)
                        }
                    )
                    .onPreferenceChange(LeftSidebarWidthPreferenceKey.self) { width in
                        guard isLeftSidebarVisible else { return }
                        if width >= 220 {
                            leftSidebarWidth = Double(width)
                        }
                    }
                    .layoutPriority(0)
            }
            
            VStack(spacing: 0) {
                if isLogConsoleDetached {
                    HStack(spacing: 8) {
                        Text("Logs laufen in separatem Fenster.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Wieder andocken") {
                            isLogConsoleDetached = false
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    Divider()
                }
                
                VSplitView {
                    if !isLogConsoleDetached {
                        logConsoleView
                            .frame(minHeight: 80, idealHeight: CGFloat(logConsoleHeight), maxHeight: 450)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: ConsoleHeightPreferenceKey.self, value: geo.size.height)
                                }
                            )
                            .onPreferenceChange(ConsoleHeightPreferenceKey.self) { height in
                                if height >= 80 {
                                    logConsoleHeight = Double(height)
                                }
                            }
                    }
                    
                    Table(displayDecodes, selection: $tableSelection, columnCustomization: $decodeColumnCustomization) {
                        TableColumn("Zeit") { decode in
                            timeCell(for: decode)
                        }
                        .width(min: 65, ideal: 75, max: 100)
                        .customizationID("time")
                        
                        TableColumn("DX Call") { decode in
                            dxCallCell(for: decode)
                        }
                        .width(min: 80, ideal: 105, max: 180)
                        .customizationID("callsign")
                        
                        TableColumn("Land") { decode in
                            landCell(for: decode)
                        }
                        .width(min: 80, ideal: 120, max: 200)
                        .customizationID("country")
                        
                        TableColumn("Spotter") { decode in
                            spotterCell(for: decode)
                        }
                        .width(min: 60, ideal: 80, max: 120)
                        .customizationID("spotter")
                        
                        TableColumn("Most Wanted") { decode in
                            mostWantedCell(for: decode)
                        }
                        .width(min: 75, ideal: 95, max: 130)
                        .customizationID("mostwanted")
                        
                        TableColumn("Entfernung") { decode in
                            distanceCell(for: decode)
                        }
                        .width(min: 65, ideal: 85, max: 120)
                        .customizationID("distance")
                        
                        TableColumn("SNR") { decode in
                            snrCell(for: decode)
                        }
                        .width(min: 40, ideal: 55, max: 80)
                        .customizationID("snr")
                        
                        TableColumn("DT") { decode in
                            dtCell(for: decode)
                        }
                        .width(min: 40, ideal: 55, max: 80)
                        .customizationID("dt")
                        
                        TableColumn("HF (Audio)") { decode in
                            frequencyCell(for: decode)
                        }
                        .width(min: 100, ideal: 130, max: 180)
                        .customizationID("frequency")
                        
                        TableColumn("Nachricht") { decode in
                            messageCell(for: decode)
                        }
                        .width(min: 120, ideal: 260, max: 2000)
                        .customizationID("message")
                    }
                    .layoutPriority(1)
                    
                    // Dedicated Most Wanted Section under the Main Table — dedupliziert nach Rufzeichen (bestes SNR pro Call)
                    let mostWantedDecodes = viewModel.mostWantedDecodes
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Header
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 14, weight: .bold))
                            
                            Text("MOST WANTED STATIONEN (UNGEARBEITET AUF DIESEM BAND)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.red)
                            
                            Text("\(mostWantedDecodes.count)")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(mostWantedDecodes.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            
                            Spacer()
                            
                            let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                            Text("Basis-Locator: \(myGrid)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        Divider()
                        
                        if mostWantedDecodes.isEmpty {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text("Keine ungearbeiteten Most Wanted Decodes oder Spots empfangen.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(mostWantedDecodes, id: \.id) { decode in
                                        let mwRank = MostWantedManager.shared.rankForCallsign(decode.callsign)
                                        let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                                        let dist = decode.distanceKm(myGrid: myGrid)
                                        
                                        HStack(spacing: 8) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                HStack(spacing: 4) {
                                                    Text(decode.callsign)
                                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                        .foregroundColor(.primary)
                                                    if let rank = mwRank {
                                                        Text("#\(rank)")
                                                            .font(.system(size: 8, weight: .bold))
                                                            .padding(.horizontal, 4)
                                                            .padding(.vertical, 1)
                                                            .background(Color.red)
                                                            .foregroundColor(.white)
                                                            .cornerRadius(3)
                                                    }
                                                }
                                                Text(decode.message)
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(decode.snr) dB")
                                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.15))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(4)
                                                
                                                if let d = dist {
                                                    Text(String(format: "%.0f km", d))
                                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            // Call Button / Spotter Badge
                                            if decode.isClusterSpot {
                                                Text(decode.spotter.isEmpty ? "SPOT" : "de \(decode.spotter)")
                                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(Color.purple.opacity(0.15))
                                                    .foregroundColor(.purple)
                                                    .cornerRadius(4)
                                            } else {
                                                Button(action: {
                                                    viewModel.sendReply(for: decode)
                                                }) {
                                                    Label("Anrufen", systemImage: "arrow.up.message.fill")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                }
                                                .buttonStyle(.borderedProminent)
                                                .tint(.red)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(6)
                                        .onTapGesture(count: 2) {
                                            if !decode.isClusterSpot {
                                                viewModel.sendReply(for: decode)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.bottom, 8)
                            }
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(minHeight: 80, idealHeight: CGFloat(mostWantedPanelHeight), maxHeight: 300)
                    .background(Color(NSColor.windowBackgroundColor))
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: MostWantedHeightPreferenceKey.self, value: geo.size.height)
                        }
                    )
                    .onPreferenceChange(MostWantedHeightPreferenceKey.self) { height in
                        if height >= 80 {
                            mostWantedPanelHeight = Double(height)
                        }
                    }
                }
            }
            .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
            
            if isSidebarVisible {
                rightSidebar
                    .frame(minWidth: 250, idealWidth: CGFloat(rightSidebarWidth), maxWidth: 400, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: RightSidebarWidthPreferenceKey.self, value: geo.size.width)
                        }
                    )
                    .onPreferenceChange(RightSidebarWidthPreferenceKey.self) { width in
                        guard isSidebarVisible else { return }
                        if width >= 250 {
                            rightSidebarWidth = Double(width)
                        }
                    }
                    .layoutPriority(0)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        
        Divider()
        bottomStatusBar
    }

    @ViewBuilder
    private var compactMainView: some View {
        compactToolbarView
        Divider()
        
        if !viewModel.displayCallsign.isEmpty {
            displayBannerView
            Divider()
        }
        
        VSplitView {
            Table(displayDecodes, selection: $tableSelection, columnCustomization: $compactDecodeColumnCustomization) {
                TableColumn("Zeit") { decode in
                    timeCell(for: decode)
                }
                .width(min: 50, ideal: 60, max: 70)
                .customizationID("time")
                
                TableColumn("DX Call") { decode in
                    dxCallCell(for: decode)
                }
                .width(min: 75, ideal: 90, max: 120)
                .customizationID("callsign")
                
                TableColumn("Land") { decode in
                    landCell(for: decode)
                }
                .width(min: 70, ideal: 100, max: 150)
                .customizationID("country")
                
                TableColumn("SNR") { decode in
                    snrCell(for: decode)
                }
                .width(min: 35, ideal: 45, max: 60)
                .customizationID("snr")
                
                TableColumn("Nachricht") { decode in
                    messageCell(for: decode)
                }
                .width(min: 100, ideal: 200, max: 1000)
                .customizationID("message")
            }
            .layoutPriority(1)
            
            compactMostWantedView
                .frame(minHeight: 50, idealHeight: CGFloat(compactMostWantedHeight), maxHeight: 150)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: CompactMostWantedHeightPreferenceKey.self, value: geo.size.height)
                    }
                )
                .onPreferenceChange(CompactMostWantedHeightPreferenceKey.self) { height in
                    if height >= 50 {
                        compactMostWantedHeight = Double(height)
                    }
                }
        }
    }

    @ViewBuilder
    private var compactToolbarView: some View {
        HStack(spacing: 6) {
            // WSJTX Auto Transmit
            Button(action: {
                viewModel.isAutoModeEnabled.toggle()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isAutoModeEnabled ? "play.circle.fill" : "play.circle")
                    Text(viewModel.isAutoModeEnabled ? "Auto ON" : "Auto OFF")
                        .fontWeight(.bold)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isAutoModeEnabled ? .green : .gray)
            .controlSize(.small)
            
            NumericTextField("10", value: $retryCooldownMinutes)
                .textFieldStyle(.roundedBorder)
                .frame(width: 38)
                .controlSize(.small)
            
            // Sort Order
            Button(action: {
                isNewestOnTop.toggle()
            }) {
                Image(systemName: isNewestOnTop ? "arrow.up" : "arrow.down")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(isNewestOnTop ? "Sortierung: Neueste unten" : "Sortierung: Neueste oben")
            
            // Pause / Freeze
            Button(action: {
                viewModel.isMainTableScrollPaused.toggle()
            }) {
                Image(systemName: viewModel.isMainTableScrollPaused ? "play.circle" : "pause.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(viewModel.isMainTableScrollPaused ? .orange : .primary)
            .help(viewModel.isMainTableScrollPaused ? "Auto-Scroll fortsetzen" : "Auto-Scroll anhalten")
            
            // Filter-Toggle
            if showOnlyAcceptedSpots {
                Button(action: {
                    showOnlyAcceptedSpots.toggle()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
                .help("Nur gefilterte Spots anzeigen (Aktiv)")
            } else {
                Button(action: {
                    showOnlyAcceptedSpots.toggle()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Alle Spots anzeigen")
            }
            
            // Search field
            HStack(spacing: 3) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("Suchen...", text: $viewModel.mainTableSearchText)
                    .font(.system(size: 10))
                    .textFieldStyle(.plain)
                    .frame(width: 75)
                if !viewModel.mainTableSearchText.isEmpty {
                    Button(action: { viewModel.mainTableSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(4)
            
            // Clear table
            Button(action: {
                viewModel.clearTable()
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Dekodierte Stationen aus der Tabelle löschen")

            Divider().frame(height: 16)

            // Right Icon Buttons Row (Logbook, Propagation Map, Grid Map, Normal Mode, Settings, Help)
            Button(action: {
                openWindow(id: "logbook")
            }) {
                Image(systemName: "book")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("LoTW Logbuch öffnen")
            
            Button(action: {
                openWindow(id: "propagation_map")
            }) {
                Image(systemName: "map")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Ausbreitungskarte in eigenem Fenster öffnen")
            
            Button(action: {
                openWindow(id: "new_grid_map")
            }) {
                Image(systemName: "square.grid.3x3.topleft.filled")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Neue 4-Stellen Grid-Karte in eigenem Fenster öffnen")
            
            Button(action: {
                toggleCompactMode(toCompact: false)
            }) {
                Image(systemName: "rectangle.expand.vertical")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Normalen Modus aktivieren")
            
            Button(action: {
                openWindow(id: "settings")
            }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Einstellungen öffnen")
            
            Button(action: {
                openWindow(id: "help")
            }) {
                Image(systemName: "questionmark.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Hilfe & Info öffnen")

            Spacer()

            // Connection & TX Status
            HStack(spacing: 4) {
                if !viewModel.server.wsjtxClientId.isEmpty {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .help("WSJT-X verbunden (ID: \(viewModel.server.wsjtxClientId))")
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .help("WSJT-X nicht verbunden")
                }
                
                if viewModel.server.isTransmitting {
                    Text("TX")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                        .help("SENDET (TX)")
                } else if viewModel.server.isTxEnabled {
                    Text("TX")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                        .help("TX BEREIT")
                } else {
                    Text("TX")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(3)
                        .help("TX AUS")
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private var compactMostWantedView: some View {
        let mostWantedDecodes = viewModel.mostWantedDecodes
        
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 11, weight: .bold))
                
                Text("MOST WANTED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                
                Text("\(mostWantedDecodes.count)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(mostWantedDecodes.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            Divider()
            
            if mostWantedDecodes.isEmpty {
                HStack {
                    Spacer()
                    Text("Keine Most Wanted Stationen.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(mostWantedDecodes, id: \.id) { decode in
                            let mwRank = MostWantedManager.shared.rankForCallsign(decode.callsign)
                            Button(action: {
                                viewModel.selectedCallsign = decode.callsign
                            }) {
                                HStack(spacing: 4) {
                                    Text(decode.callsign)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    if let rank = mwRank {
                                        Text("#\(rank)")
                                            .font(.system(size: 7, weight: .bold))
                                            .padding(.horizontal, 3)
                                            .padding(.vertical, 0.5)
                                            .background(Color.red)
                                            .foregroundColor(.white)
                                            .cornerRadius(2)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private var bottomStatusBar: some View {
        HStack(spacing: 12) {
            // Left Side: QSO Status
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                Text(viewModel.currentQSOStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Right Side: WSJT-X Connection & TX Status Indicators
            HStack(spacing: 10) {
                // WSJT-X Client Connection
                if !viewModel.server.wsjtxClientId.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("WSJT-X: \(viewModel.server.wsjtxClientId)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("WSJT-X: Keine Verbindung")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                
                // TX Status Indicator
                if viewModel.server.isTransmitting {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("SENDET (TX)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .shadow(color: .red.opacity(0.5), radius: 2)
                } else if viewModel.server.isTxEnabled {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("TX BEREIT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                        Text("TX AUS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func dxCallCell(for decode: WSJTXDecode) -> some View {
        HStack(spacing: 4) {
            cellText(decode.callsign, decode: decode)
            if decode.isMostWanted {
                Text("🔥")
                    .font(.caption2)
            }
        }
    }
    
    @ViewBuilder
    private func landCell(for decode: WSJTXDecode) -> some View {
        cellText(decode.country.isEmpty ? "Unbekannt" : decode.country, decode: decode)
    }
    
    @ViewBuilder
    private func mostWantedCell(for decode: WSJTXDecode) -> some View {
        if let rank = decode.mostWantedRank {
            HStack(spacing: 4) {
                Text("🔥 #\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        } else {
            Text("-")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func distanceCell(for decode: WSJTXDecode) -> some View {
        let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
        if let dist = decode.distanceKm(myGrid: myGrid) {
            cellText(String(format: "%.0f km", dist), decode: decode)
        } else {
            cellText("-", decode: decode)
        }
    }
    
    @ViewBuilder
    private func timeCell(for decode: WSJTXDecode) -> some View {
        cellText(formatTime(decode.time), decode: decode)
    }
    
    @ViewBuilder
    private func spotterCell(for decode: WSJTXDecode) -> some View {
        cellText(decode.spotter, decode: decode)
    }
    
    @ViewBuilder
    private func snrCell(for decode: WSJTXDecode) -> some View {
        cellText("\(decode.snr)", decode: decode)
    }
    
    @ViewBuilder
    private func dtCell(for decode: WSJTXDecode) -> some View {
        cellText(String(format: "%.1f", decode.deltaTime), decode: decode)
    }
    
    @ViewBuilder
    private func frequencyCell(for decode: WSJTXDecode) -> some View {
        HStack(spacing: 3) {
            cellText(decode.formattedHfFrequency, decode: decode)
            if decode.deltaFrequency > 0 {
                Text("(+\(decode.deltaFrequency)Hz)")
                    .font(.system(size: max(8, CGFloat(fontSizeTable) - 2), design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func messageCell(for decode: WSJTXDecode) -> some View {
        cellText(decode.message, decode: decode)
    }

    private func cellText(_ text: String, decode: WSJTXDecode) -> some View {
        Text(text)
            .font(.system(size: CGFloat(fontSizeTable)))
            .foregroundStyle(rowColor(for: decode))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                viewModel.sendReply(for: decode)
            }
            .onTapGesture(count: 1) {
                selectAndLookup(decode: decode)
            }
    }
    
    private func selectAndLookup(decode: WSJTXDecode) {
        let call = decode.callsign
        guard !call.isEmpty else { return }
        viewModel.selectedCallsign = call
    }
    
    private func openQRZ(callsign: String) {
        guard !callsign.isEmpty, let url = URL(string: "https://www.qrz.com/db/\(callsign)") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private var standardColor: Color {
        colorTableStandard.isEmpty ? .primary : Color(hex: colorTableStandard)
    }
    private var cqColor: Color {
        colorTableCQ.isEmpty ? .green : Color(hex: colorTableCQ)
    }
    private var workedColor: Color {
        colorTableWorked.isEmpty ? .red.opacity(0.5) : Color(hex: colorTableWorked)
    }
    private var mostWantedColor: Color {
        colorTableMostWanted.isEmpty ? .red : Color(hex: colorTableMostWanted)
    }
    
    private func rowColor(for decode: WSJTXDecode) -> Color {
        let call = decode.callsign
        if call.isEmpty {
            return standardColor
        }
        
        let eval = viewModel.evaluateDecodeFast(decode)
        if eval.isInteresting {
            return cqColor
        }
        
        if eval.isWorked {
            return workedColor
        }
        
        if !eval.shouldAccept {
            return .gray.opacity(0.6)
        }
        
        if highlightMostWanted && decode.isMostWanted {
            return mostWantedColor
        }
        
        return standardColor
    }
    
    private func formatTime(_ ms: UInt32) -> String {
        let seconds = ms / 1000
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("Fehler") || log.contains("⚠️") {
            return .red
        } else if log.contains("🚀") {
            return .green
        } else if log.contains("Auswertung") {
            return .secondary
        } else {
            let hex = UserDefaults.standard.string(forKey: "colorLogSystem") ?? ""
            return hex.isEmpty ? .primary : Color(hex: hex)
        }
    }
    
    private func wsjtxLogColor(for type: WSJTXRawLogType) -> Color {
        switch type {
        case .decode:
            let hex = UserDefaults.standard.string(forKey: "colorLogWsjtxDecode") ?? ""
            return hex.isEmpty ? .green : Color(hex: hex)
        case .incoming:
            let hex = UserDefaults.standard.string(forKey: "colorLogWsjtxIncoming") ?? ""
            return hex.isEmpty ? .blue : Color(hex: hex)
        case .outgoing:
            let hex = UserDefaults.standard.string(forKey: "colorLogWsjtxOutgoing") ?? ""
            return hex.isEmpty ? .orange : Color(hex: hex)
        }
    }
    
    private func formatLogTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    // MARK: - DX Filter Sidebar Layout & Views

    @ViewBuilder
    private var rightSidebar: some View {
        VStack(spacing: 0) {
            Text("Filter")
                .font(.headline)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            VStack(spacing: 8) {
                Toggle(isOn: $viewModel.isFiltersEnabled) {
                    Text("Filter anwenden").bold().font(.caption)
                }
                .toggleStyle(.switch)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .controlSize(.small)
                .onChange(of: viewModel.isFiltersEnabled) { _, _ in
                    viewModel.saveFilters()
                }
                
                Picker("", selection: $rightSidebarTab) {
                    Text("DX-Call").tag(0)
                    Text("Spotter").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 4)
                .controlSize(.small)
                
                Divider()
            }

            if rightSidebarTab == 0, let conflict = viewModel.dxCallFilterConflict {
                conflictBanner(conflict)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            } else if rightSidebarTab == 1, let conflict = viewModel.spotterFilterConflict {
                conflictBanner(conflict)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }

            List {
                if rightSidebarTab == 0 {
                    countryFilterContent
                } else {
                    spotterFilterContent
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func conflictBanner(_ conflict: DecodeViewModel.FilterConflict) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(conflict.isTotalConflict ? "Filter-Konflikt: Blockiert alles!" : "Filter-Warnung")
                    .font(.caption).bold()
                    .foregroundColor(.orange)
            }
            Text(String(format: conflict.isTotalConflict ? 
                (rightSidebarTab == 0 ? 
                    "Erlaubtes DX-Rufzeichen '%@' ist aus %@, was nicht in den erlaubten Ländern (%@) enthalten ist." :
                    "Erlaubter Spotter '%@' ist aus %@, was nicht in den erlaubten Ländern (%@) enthalten ist.") :
                (rightSidebarTab == 0 ? 
                    "DX-Rufzeichen '%@' ist aus %@, was nicht in den erlaubten Ländern (%@) enthalten ist." :
                    "Spotter '%@' ist aus %@, was nicht in den erlaubten Ländern (%@) enthalten ist."),
                conflict.callsign, conflict.callsignCountry, conflict.allowedCountriesText))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.orange.opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.orange.opacity(0.4), lineWidth: 1))
        .cornerRadius(6)
    }

    private let continentCodes: [(code: String, nameKey: String)] = [
        ("AF", "Afrika"),
        ("AN", "Antarktis"),
        ("AS", "Asien"),
        ("EU", "Europa"),
        ("NA", "Nordamerika"),
        ("OC", "Ozeanien"),
        ("SA", "Südamerika")
    ]

    @ViewBuilder
    private var countryFilterContent: some View {
        Section(isExpanded: $isBlockedCountriesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Blacklist-Modus").font(.caption).bold()
                Text("Stationen aus diesen Ländern werden blockiert.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.red.opacity(0.05)).cornerRadius(6)
            
            ForEach(viewModel.blockedCountries, id: \.self) { country in
                HStack {
                    Text(country).font(.system(size: 11))
                    Spacer()
                    Button { viewModel.removeBlockedCountry(country) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Land blockieren").font(.caption2).foregroundColor(.secondary)
                CountryInputField(text: $newCountry, suggestions: viewModel.countrySuggestions(for: newCountry)) {
                    viewModel.addBlockedCountry(newCountry)
                    newCountry = ""
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Gesperrte Länder", isExpanded: $isBlockedCountriesExpanded, activeCount: viewModel.blockedCountries.count)
        }

        Section(isExpanded: $isAllowedDXCountriesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whitelist-Modus").font(.caption).bold()
                Text("Wenn befüllt, werden NUR Signale aus diesen Ländern durchgelassen.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)

            ForEach(viewModel.allowedCountries, id: \.self) { country in
                HStack {
                    Text(country).font(.system(size: 11))
                    Spacer()
                    Button { viewModel.removeAllowedCountry(country) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DX-Land erlauben").font(.caption2).foregroundColor(.secondary)
                CountryInputField(text: $newAllowedDXCountry, suggestions: viewModel.countrySuggestions(for: newAllowedDXCountry)) {
                    viewModel.addAllowedCountry(newAllowedDXCountry)
                    newAllowedDXCountry = ""
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Erlaubte DX-Länder", isExpanded: $isAllowedDXCountriesExpanded, activeCount: viewModel.allowedCountries.count)
        }

        Section(isExpanded: $isContinentFilterExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Erlaubte Kontinente an- oder abwählen.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)

            ForEach(continentCodes, id: \.code) { item in
                Toggle(isOn: Binding(
                    get: { !viewModel.disabledContinents.contains(item.code) },
                    set: { _ in viewModel.toggleContinent(item.code) }
                )) {
                    Text("\(item.nameKey) (\(item.code))").font(.system(size: 11))
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
            }

            HStack {
                Button("Alle an") { viewModel.setAllContinents(enabled: true) }
                    .buttonStyle(.bordered).controlSize(.small)
                Button("Alle aus") { viewModel.setAllContinents(enabled: false) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
            .padding(.top, 2)
        } header: {
            sidebarHeader("Kontinent-Filter", isExpanded: $isContinentFilterExpanded, activeCount: viewModel.disabledContinents.count)
        }

        Section(isExpanded: $isBlockedCQZonesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Signale aus diesen CQ-Zonen werden blockiert.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.red.opacity(0.05)).cornerRadius(6)

            ForEach(viewModel.blockedCQZones, id: \.self) { zone in
                HStack {
                    Text("CQ-Zone \(zone)").font(.system(size: 11))
                    Spacer()
                    Button { viewModel.removeBlockedCQZone(zone) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CQ-Zone blockieren").font(.caption2).foregroundColor(.secondary)
                HStack {
                    TextField("z.B. 14", text: $newCQZone)
                        .textFieldStyle(UnifiedTextFieldStyle())
                        .controlSize(.small)
                    Button(action: {
                        if let z = Int(newCQZone.trimmingCharacters(in: .whitespaces)), z >= 1 && z <= 40 {
                            viewModel.addBlockedCQZone(z)
                            newCQZone = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .disabled(Int(newCQZone.trimmingCharacters(in: .whitespaces)) == nil)
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Gesperrte CQ-Zonen", isExpanded: $isBlockedCQZonesExpanded, activeCount: viewModel.blockedCQZones.count)
        }

        Section(isExpanded: $isBlockedITUZonesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Signale aus diesen ITU-Zonen werden blockiert.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.red.opacity(0.05)).cornerRadius(6)

            ForEach(viewModel.blockedITUZones, id: \.self) { zone in
                HStack {
                    Text("ITU-Zone \(zone)").font(.system(size: 11))
                    Spacer()
                    Button { viewModel.removeBlockedITUZone(zone) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ITU-Zone blockieren").font(.caption2).foregroundColor(.secondary)
                HStack {
                    TextField("z.B. 28", text: $newITUZone)
                        .textFieldStyle(UnifiedTextFieldStyle())
                        .controlSize(.small)
                    Button(action: {
                        if let z = Int(newITUZone.trimmingCharacters(in: .whitespaces)), z >= 1 && z <= 90 {
                            viewModel.addBlockedITUZone(z)
                            newITUZone = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .disabled(Int(newITUZone.trimmingCharacters(in: .whitespaces)) == nil)
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Gesperrte ITU-Zonen", isExpanded: $isBlockedITUZonesExpanded, activeCount: viewModel.blockedITUZones.count)
        }

        Section(isExpanded: $isWsjtSpecialFilterExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(
                    get: { viewModel.isWsjtSpecialFilterEnabled },
                    set: { viewModel.isWsjtSpecialFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                )) {
                    Text("Nur CQ, RRR, RR73, 73").font(.system(size: 11)).bold()
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                Text("Filtert alle Dekodierungen heraus, die keine CQ-Rufe oder QSO-Beendigungen sind.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)
        } header: {
            sidebarHeader("WSJT-X Spezialfilter", isExpanded: $isWsjtSpecialFilterExpanded, activeCount: viewModel.isWsjtSpecialFilterEnabled ? 1 : 0)
        }

        Section(isExpanded: $isNewGridFilterExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(
                    get: { viewModel.isNew4CharGridOnlyFilterEnabled },
                    set: { viewModel.isNew4CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                )) {
                    Text("Nur neue 4-Stellen Grids (z.B. JO31)").font(.system(size: 11)).bold()
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                Toggle(isOn: Binding(
                    get: { viewModel.isNew6CharGridOnlyFilterEnabled },
                    set: { viewModel.isNew6CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                )) {
                    Text("Nur neue 6-Stellen Grids (z.B. JO31aa)").font(.system(size: 11)).bold()
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                Text("Lässt nur Stationen aus Maidenhead Grids durch, die in dieser Auflösung noch nicht im Logbuch gearbeitet wurden.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)
        } header: {
            sidebarHeader("Maidenhead Grid-Filter", isExpanded: $isNewGridFilterExpanded, activeCount: (viewModel.isNew4CharGridOnlyFilterEnabled ? 1 : 0) + (viewModel.isNew6CharGridOnlyFilterEnabled ? 1 : 0))
        }

        Section(isExpanded: $isDuplicateFilterExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: Binding(
                    get: { viewModel.isDuplicateFilterEnabled },
                    set: { viewModel.isDuplicateFilterEnabled = $0; viewModel.saveFilters() }
                )) {
                    Text("Doubletten ausfiltern").font(.system(size: 11)).bold()
                }
                .toggleStyle(.switch)
                .controlSize(.mini)

                HStack {
                    Text("Toleranz:").font(.system(size: 10))
                    Picker("", selection: Binding(get: { viewModel.duplicateSpotFrequencyTolerance }, set: { viewModel.duplicateSpotFrequencyTolerance = $0; viewModel.saveFilters() })) {
                        Text("0.5 kHz").tag(0.5)
                        Text("1.0 kHz").tag(1.0)
                        Text("1.5 kHz").tag(1.5)
                        Text("2.0 kHz").tag(2.0)
                        Text("3.0 kHz").tag(3.0)
                    }
                    .pickerStyle(.menu)
                    .controlSize(.mini)
                }

                HStack {
                    Text("Zeitfenster:").font(.system(size: 10))
                    Picker("", selection: Binding(get: { viewModel.duplicateSpotWindowMinutes }, set: { viewModel.duplicateSpotWindowMinutes = $0; viewModel.saveFilters() })) {
                        Text("1 Min").tag(1)
                        Text("3 Min").tag(3)
                        Text("5 Min").tag(5)
                        Text("10 Min").tag(10)
                        Text("15 Min").tag(15)
                    }
                    .pickerStyle(.menu)
                    .controlSize(.mini)
                }

                Text("Verhindert doppelte Dekodierungen des gleichen Rufzeichens auf der gleichen Frequenz im gewählten Zeitfenster.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)
        } header: {
            sidebarHeader("Doubletten-Filter", isExpanded: $isDuplicateFilterExpanded, activeCount: viewModel.isDuplicateFilterEnabled ? 1 : 0)
        }

        Section(isExpanded: $isAllowedDXCallsignsExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whitelist-Modus").font(.caption).bold()
                Text("NUR Rufzeichen, die mit diesen Präfixen beginnen, werden durchgelassen.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)

            ForEach(viewModel.allowedDXCallsigns, id: \.self) { callsign in
                HStack {
                    Text(callsign).font(.system(size: 11, design: .monospaced)).bold()
                    Spacer()
                    Button { viewModel.removeAllowedDXCallsign(callsign) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DX-Rufzeichen erlauben").font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 4) {
                    TextField("z.B. DP0, K1, DL1ABC", text: $newAllowedDXCallsign)
                        .textFieldStyle(UnifiedTextFieldStyle())
                        .onSubmit {
                            viewModel.addAllowedDXCallsign(newAllowedDXCallsign)
                            newAllowedDXCallsign = ""
                        }
                    Button {
                        viewModel.addAllowedDXCallsign(newAllowedDXCallsign)
                        newAllowedDXCallsign = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newAllowedDXCallsign.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newAllowedDXCallsign.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Erlaubte DX-Rufzeichen", isExpanded: $isAllowedDXCallsignsExpanded, activeCount: viewModel.allowedDXCallsigns.count)
        }
    }

    @ViewBuilder
    private var spotterFilterContent: some View {
        Section(isExpanded: $isAllowedSpotterCountriesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whitelist-Modus").font(.caption).bold()
                Text("NUR Dekodierungen, deren lokaler Spotter (Eigene Station) aus diesen Ländern ist, werden durchgelassen.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)
            
            ForEach(viewModel.allowedSpotterCountries, id: \.self) { country in
                HStack {
                    Text(country).font(.system(size: 11))
                    Spacer()
                    Button { viewModel.removeAllowedSpotterCountry(country) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Spotter-Land erlauben").font(.caption2).foregroundColor(.secondary)
                CountryInputField(text: $newSpotterCountry, suggestions: viewModel.countrySuggestions(for: newSpotterCountry)) {
                    viewModel.addAllowedSpotterCountry(newSpotterCountry)
                    newSpotterCountry = ""
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Erlaubte Spotter-Länder", isExpanded: $isAllowedSpotterCountriesExpanded, activeCount: viewModel.allowedSpotterCountries.count)
        }

        Section(isExpanded: $isAllowedSpotterCallsignsExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whitelist-Modus").font(.caption).bold()
                Text("NUR Dekodierungen, deren lokaler Spotter-Rufzeichen mit diesen übereinstimmt, werden durchgelassen.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).cornerRadius(6)

            ForEach(viewModel.allowedSpotterCallsigns, id: \.self) { callsign in
                HStack {
                    Text(callsign).font(.system(size: 11, design: .monospaced)).bold()
                    Spacer()
                    Button { viewModel.removeAllowedSpotterCallsign(callsign) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Spotter erlauben").font(.caption2).foregroundColor(.secondary)
                HStack(spacing: 4) {
                    TextField("z.B. DJ6GI", text: $newAllowedSpotterCallsign)
                        .textFieldStyle(UnifiedTextFieldStyle())
                        .onSubmit {
                            viewModel.addAllowedSpotterCallsign(newAllowedSpotterCallsign)
                            newAllowedSpotterCallsign = ""
                        }
                    Button {
                        viewModel.addAllowedSpotterCallsign(newAllowedSpotterCallsign)
                        newAllowedSpotterCallsign = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(newAllowedSpotterCallsign.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newAllowedSpotterCallsign.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Erlaubte Spotter-Rufzeichen", isExpanded: $isAllowedSpotterCallsignsExpanded, activeCount: viewModel.allowedSpotterCallsigns.count)
        }
    }

    private func sidebarHeader(_ title: String, isExpanded: Binding<Bool>, activeCount: Int = 0) -> some View {
        HStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.primary)
                .textCase(.uppercase)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if !isExpanded.wrappedValue && activeCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "funnel.fill")
                        .font(.system(size: 8))
                    Text("\(activeCount)")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.blue)
                .cornerRadius(4)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.wrappedValue.toggle()
        }
    }

    @ViewBuilder
    private var leftSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("VERBINDUNG & BRIDGE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            List {
                Section(isExpanded: $isWsjtxServerExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UDP IP-Adresse").font(.caption).foregroundColor(.secondary)
                            TextField("224.0.0.1", text: $udpAddress)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UDP Port").font(.caption).foregroundColor(.secondary)
                            NumericTextField("2237", value: $udpPort)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                        }
                        
                        let isMulticastAddress = {
                            if let firstOctetStr = udpAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
                               let firstOctet = Int(firstOctetStr) {
                                return firstOctet >= 224 && firstOctet <= 239
                            }
                            return false
                        }()
                        
                        HStack {
                            Text("Modus:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(isMulticastAddress ? "Multicast (MC)" : "Unicast (UC)")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(isMulticastAddress ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                                .foregroundColor(isMulticastAddress ? .blue : .orange)
                                .cornerRadius(3)
                        }
                        
                        Button("Neu verbinden / Starten") {
                            viewModel.startServer(port: UInt16(udpPort), address: udpAddress)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    sidebarHeader("WSJT-X UDP Server", isExpanded: $isWsjtxServerExpanded)
                }
                
                Section(isExpanded: $isUdpBridgeExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weiterleitungs-Port (Bridge)").font(.caption).foregroundColor(.secondary)
                            NumericTextField("z.B. 2238 (0 = Aus)", value: $udpBridgePort)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                        }
                        
                        let isBridgeActive = udpBridgePort > 0
                        HStack {
                            Text("Status:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(isBridgeActive ? "AKTIV (Port \(udpBridgePort))" : "DEAKTIVIERT")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(isBridgeActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                                .foregroundColor(isBridgeActive ? .green : .gray)
                                .cornerRadius(3)
                        }
                        
                        Text("Leitet alle empfangenen FT8/FT4 Dekodierungen, welche die aktiven DX-Filter passiert haben, an diesen lokalen UDP-Port (localhost) weiter.")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    sidebarHeader("UDP Bridge (Weiterleitung)", isExpanded: $isUdpBridgeExpanded, activeCount: udpBridgePort > 0 ? 1 : 0)
                }
                
                Section(isExpanded: $isDxClusterExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Cluster 1
                        HStack(spacing: 6) {
                            Circle()
                                .fill(!isCluster1Enabled ? .gray : (viewModel.isConnected1 ? .green : (viewModel.clusterError1 != nil ? .red : .orange)))
                                .frame(width: 7, height: 7)
                            Text("C1:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
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
                                Text("Deaktiviert").tag(ClusterServer?.none)
                                ForEach(viewModel.availableClusters) { cluster in
                                    Text(cluster.name).tag(ClusterServer?.some(cluster))
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .controlSize(.small)
                        }
                        
                        // Cluster 2
                        HStack(spacing: 6) {
                            Circle()
                                .fill(!isCluster2Enabled ? .gray : (viewModel.isConnected2 ? .green : (viewModel.clusterError2 != nil ? .red : .orange)))
                                .frame(width: 7, height: 7)
                            Text("C2:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
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
                                Text("Deaktiviert").tag(ClusterServer?.none)
                                ForEach(viewModel.availableClusters) { cluster in
                                    Text(cluster.name).tag(ClusterServer?.some(cluster))
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .controlSize(.small)
                        }
                        
                        // Cluster 3
                        HStack(spacing: 6) {
                            Circle()
                                .fill(!isCluster3Enabled ? .gray : (viewModel.isConnected3 ? .green : (viewModel.clusterError3 != nil ? .red : .orange)))
                                .frame(width: 7, height: 7)
                            Text("C3:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
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
                                Text("Deaktiviert").tag(ClusterServer?.none)
                                ForEach(viewModel.availableClusters) { cluster in
                                    Text(cluster.name).tag(ClusterServer?.some(cluster))
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .controlSize(.small)
                        }
                    }
                } header: {
                    let activeCount = (isCluster1Enabled ? 1 : 0) + (isCluster2Enabled ? 1 : 0) + (isCluster3Enabled ? 1 : 0)
                    sidebarHeader("DX Cluster", isExpanded: $isDxClusterExpanded, activeCount: activeCount)
                }
                
                Section(isExpanded: $isTelnetServerExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Telnet Server Port").font(.caption).foregroundColor(.secondary)
                            TextField("8000", value: $telnetServerPort, format: .number.grouping(.never))
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                                .onChange(of: telnetServerPort) { _, _ in
                                    viewModel.startTelnetServer()
                                }
                        }
                        
                        let isTelnetActive = viewModel.telnetServerError == nil
                        HStack {
                            Text("Server Status:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(isTelnetActive ? "AKTIV (Clients: \(viewModel.telnetClientCount))" : "FEHLER")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(isTelnetActive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                .foregroundColor(isTelnetActive ? .green : .red)
                                .cornerRadius(3)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Rufzeichen für Login").font(.caption).foregroundColor(.secondary)
                            TextField("GUEST", text: $clusterCallsign)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                                .onChange(of: clusterCallsign) { _, _ in
                                    viewModel.reconnectClusters()
                                }
                        }
                        
                        Toggle("WSJT-X Decodes über Telnet ausgeben", isOn: $isWsjtTelnetOutputEnabled)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                            .font(.system(size: 10.5))
                    }
                } header: {
                    sidebarHeader("Telnet Server", isExpanded: $isTelnetServerExpanded, activeCount: viewModel.telnetClientCount > 0 ? 1 : 0)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var logConsoleView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if consoleTab == 1 {
                    HStack(spacing: 8) {
                        Toggle("Decodes", isOn: $wsjtxShowDecodes)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                        Toggle("Eingang", isOn: $wsjtxShowIncoming)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                        Toggle("Ausgang", isOn: $wsjtxShowOutgoing)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                    }
                } else {
                    Spacer().frame(width: 1)
                }
                
                Spacer()
                
                Picker("", selection: $consoleTab) {
                    Text("System-Logs").tag(0)
                    Text("WSJT-X Rohdaten").tag(1)
                    Text("Cluster-Spots").tag(2)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 320)
                
                Spacer()
                
                // Auto-scroll pause button
                Button(action: {
                    viewModel.isLogScrollPaused.toggle()
                }) {
                    Image(systemName: viewModel.isLogScrollPaused ? "play.circle" : "pause.circle")
                        .foregroundColor(viewModel.isLogScrollPaused ? .orange : .primary)
                }
                .buttonStyle(.plain)
                .help(viewModel.isLogScrollPaused ? "Auto-Scroll fortsetzen" : "Auto-Scroll anhalten")
                .padding(.trailing, 4)
                
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Protokoll durchsuchen...", text: $viewModel.logConsoleSearchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                    if !viewModel.logConsoleSearchText.isEmpty {
                        Button(action: { viewModel.logConsoleSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .padding(.trailing, 4)
                
                if consoleTab == 2 {
                    Button(action: {
                        isClusterSendSheetPresented = true
                    }) {
                        Image(systemName: "paperplane")
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .help("Befehl an DX-Cluster senden")
                    .padding(.trailing, 4)
                }
                
                // Detach button
                Button(action: {
                    isLogConsoleDetached = true
                    openWindow(id: "logs_raw")
                }) {
                    Image(systemName: "macwindow.badge.plus")
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .help("In eigenem Fenster öffnen (ausklappen)")
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            
            Group {
                if consoleTab == 0 {
                    LogConsoleTextView(
                        lines: systemLogLines,
                        isPaused: viewModel.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                } else if consoleTab == 1 {
                    LogConsoleTextView(
                        lines: wsjtxLogLines,
                        isPaused: viewModel.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                } else {
                    LogConsoleTextView(
                        lines: clusterLogLines,
                        isPaused: viewModel.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $isClusterSendSheetPresented) {
            ClusterSendDialog(viewModel: viewModel)
        }
    }

    private func toggleCompactMode(toCompact: Bool) {
        self.isTransitioningMode = true
        self.isCompactMode = toCompact
        
        DispatchQueue.main.async {
            if let window = self.hostingWindow {
                let currentFrame = window.frame
                let targetWidth = toCompact ? self.compactWindowWidth : self.normalWindowWidth
                let targetHeight = toCompact ? self.compactWindowHeight : self.normalWindowHeight
                
                let newY = currentFrame.maxY - CGFloat(targetHeight)
                let newFrame = NSRect(
                    x: currentFrame.minX,
                    y: newY,
                    width: CGFloat(targetWidth),
                    height: CGFloat(targetHeight)
                )
                
                window.setFrame(newFrame, display: true, animate: true)
                
                // Allow the frame resize animation to finish before tracking user size updates again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isTransitioningMode = false
                }
            } else {
                self.isTransitioningMode = false
            }
        }
    }

    private func scrollToActive<T: Hashable>(proxy: ScrollViewProxy, count: Int, first: T?, last: T?) {
        guard count > 0 else { return }
        DispatchQueue.main.async {
            if self.isNewestOnTop {
                if let first = first {
                    proxy.scrollTo(first, anchor: .top)
                }
            } else {
                if let last = last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }

    private func scrollToNewestRow() {
        DispatchQueue.main.async {
            guard let tableView = self.findTableView(),
                  let scrollView = tableView.enclosingScrollView,
                  let clipView = scrollView.contentView as NSClipView? else { return }
            
            if self.isNewestOnTop {
                clipView.scroll(to: NSPoint(x: 0, y: 0))
                scrollView.reflectScrolledClipView(clipView)
            } else {
                let maxY = max(0, tableView.frame.height - clipView.bounds.height)
                clipView.scroll(to: NSPoint(x: 0, y: maxY))
                scrollView.reflectScrolledClipView(clipView)
            }
        }
    }

    private var systemLogLines: [LogLine] {
        let rawLogs: [String]
        if viewModel.isLogScrollPaused, let frozen = viewModel.frozenSystemLogs {
            rawLogs = frozen
        } else {
            rawLogs = (viewModel.logHistory + viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory).sorted()
        }
        
        let query = viewModel.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredLogs: [String]
        if query.isEmpty {
            filteredLogs = rawLogs
        } else {
            filteredLogs = rawLogs.filter { $0.lowercased().contains(query) }
        }
        
        let logs = isNewestOnTop ? Array(filteredLogs.reversed()) : filteredLogs
        return logs.map { LogLine(text: $0, color: logColor(for: $0)) }
    }
    
    private var wsjtxLogLines: [LogLine] {
        let rawWSJTXLogs: [WSJTXRawLogEntry]
        if viewModel.isLogScrollPaused, let frozen = viewModel.frozenWSJTXLogs {
            rawWSJTXLogs = frozen
        } else {
            rawWSJTXLogs = viewModel.wsjtxRawLogs
        }
        
        let activeTypeLogs = rawWSJTXLogs.filter { log in
            switch log.type {
            case .decode: return wsjtxShowDecodes
            case .incoming: return wsjtxShowIncoming
            case .outgoing: return wsjtxShowOutgoing
            }
        }
        
        let query = viewModel.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredLogs: [WSJTXRawLogEntry]
        if query.isEmpty {
            filteredLogs = activeTypeLogs
        } else {
            filteredLogs = activeTypeLogs.filter { $0.message.lowercased().contains(query) }
        }
        
        let logs = isNewestOnTop ? Array(filteredLogs.reversed()) : filteredLogs
        return logs.map { log in
            let ts = formatLogTime(log.timestamp)
            return LogLine(text: "[\(ts)] [\(log.type.rawValue)] \(log.message)", color: wsjtxLogColor(for: log.type))
        }
    }
    
    private var clusterLogLines: [LogLine] {
        let rawClusterLogs: [ClusterRawLogEntry]
        if viewModel.isLogScrollPaused, let frozen = viewModel.frozenClusterLogs {
            rawClusterLogs = frozen
        } else {
            rawClusterLogs = viewModel.clusterRawLogs
        }
        
        let query = viewModel.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredLogs: [ClusterRawLogEntry]
        if query.isEmpty {
            filteredLogs = rawClusterLogs
        } else {
            filteredLogs = rawClusterLogs.filter { $0.message.lowercased().contains(query) }
        }
        
        let logs = isNewestOnTop ? Array(filteredLogs.reversed()) : filteredLogs
        let clusterColor = Color(hex: UserDefaults.standard.string(forKey: "colorLogCluster") ?? "", defaultColor: .primary)
        return logs.map { LogLine(text: $0.message, color: clusterColor) }
    }

    private func findTableView() -> NSTableView? {
        guard let window = self.hostingWindow ?? NSApp.mainWindow ?? NSApp.keyWindow else { return nil }
        if let contentView = window.contentView {
            return findTableView(in: contentView)
        }
        return nil
    }

    private func findTableView(in view: NSView) -> NSTableView? {
        if let tableView = view as? NSTableView, tableView.tableColumns.count > 1 {
            return tableView
        }
        for subview in view.subviews {
            if let found = findTableView(in: subview) {
                return found
            }
        }
        return nil
    }
}

struct CountryInputField: View {
    @Binding var text: String
    let suggestions: [String]
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("z.B. Russia, Germany...", text: $text)
                    .textFieldStyle(UnifiedTextFieldStyle())
                    .controlSize(.small)
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text(suggestion)
                            .font(.caption)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .onTapGesture(count: 2) {
                                text = suggestion
                                onAdd()
                            }
                            .onTapGesture(count: 1) {
                                text = suggestion
                            }
                        Divider()
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            }
        }
    }
}

struct UnifiedTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.plain)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 4).fill(colorScheme == .light ? Color(white: 0.90) : Color(white: 0.18)))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
    }
}

struct LeftSidebarWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct RightSidebarWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ConsoleHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MostWantedHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct CompactMostWantedHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct WindowAccessor: NSViewRepresentable {
    var onChange: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onChange(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            onChange(window)
        }
    }
}


