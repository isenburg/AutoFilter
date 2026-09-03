struct ConsoleHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 180
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 60 {
            value = next
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var viewModel: DecodeViewModel
    var langManager = LanguageManager.shared
    private var isDe: Bool { langManager.isGerman }
    
    @State private var draggedFilterSection: DXFilterSectionId? = nil
    
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    @AppStorage("mostWantedPanelHeight") private var mostWantedPanelHeight: Double = 120.0
    @AppStorage("decode_column_customization") private var decodeColumnCustomization: TableColumnCustomization<SpotRowData>
    @AppStorage("compact_decode_column_customization") private var compactDecodeColumnCustomization: TableColumnCustomization<SpotRowData>
    
    @State private var tableSelection: SpotRowData.ID? = nil
    
    @AppStorage("isSidebarVisible") private var isSidebarVisible = true
    @AppStorage("isLeftSidebarVisible") private var isLeftSidebarVisible = true
    @AppStorage("leftSidebarWidth") private var leftSidebarWidth: Double = 240.0
    @AppStorage("rightSidebarWidth") private var rightSidebarWidth: Double = 280.0
    @AppStorage("udpBridgeAddress") private var udpBridgeAddress = "127.0.0.1"
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
    @AppStorage("isMessageFilterExpanded") private var isMessageFilterExpanded = true
    @State private var isShowingProfileManagerSheet = false
    @State private var isShowingNewProfileAlert = false
    @State private var newProfileName = ""
    @AppStorage("isBlockedCQZonesExpanded") private var isBlockedCQZonesExpanded = true
    @AppStorage("isBlockedITUZonesExpanded") private var isBlockedITUZonesExpanded = true
    @AppStorage("isWsjtSpecialFilterExpanded") private var isWsjtSpecialFilterExpanded = true
    @AppStorage("isNewGridFilterExpanded") private var isNewGridFilterExpanded = true
    @AppStorage("isWorkedBeforeFilterExpanded") private var isWorkedBeforeFilterExpanded = true
    @AppStorage("isDuplicateFilterExpanded") private var isDuplicateFilterExpanded = true
    @AppStorage("isAllowedDXCallsignsExpanded") private var isAllowedDXCallsignsExpanded = true
    @AppStorage("isAllowedGridsExpanded") private var isAllowedGridsExpanded = true
    @AppStorage("isMostWantedOnlyExpanded") private var isMostWantedOnlyExpanded = true
    @AppStorage("isAllowedSpotterCountriesExpanded") private var isAllowedSpotterCountriesExpanded = true
    @AppStorage("isAllowedSpotterCallsignsExpanded") private var isAllowedSpotterCallsignsExpanded = true
    
    // Form Inputs
    @State private var newCountry = ""
    @State private var newAllowedDXCountry = ""
    @State private var newAllowedGrid = ""
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
    
    private var displayRows: [SpotRowData] {
        let baseList = viewModel.displaySpots
        let query = viewModel.mainTableSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var filtered: [SpotRowData]
        
        if showOnlyAcceptedSpots {
            filtered = baseList.filter { $0.isAccepted }
        } else {
            filtered = baseList
        }
        
        if !query.isEmpty {
            filtered = filtered.filter { row in
                row.callsign.lowercased().contains(query) ||
                row.country.lowercased().contains(query) ||
                row.spotter.lowercased().contains(query) ||
                (row.grid?.lowercased().contains(query) ?? false) ||
                row.message.lowercased().contains(query)
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
                    .help(L("toolbar.connectionSidebar"))
                } else {
                    Button(action: {
                        isLeftSidebarVisible.toggle()
                    }) {
                        Image(systemName: "sidebar.left")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.connectionSidebar"))
                }
            }
            .frame(width: isLeftSidebarVisible ? CGFloat(leftSidebarWidth) : 100, alignment: .leading)
            
            Spacer()
            
            // 2. CENTER: AutoQSO / WSJTX Auto Transmit, Logbook, Sortierung, and standard window buttons (all centered on one single line!)
            HStack(alignment: .center, spacing: 12) {
                // WSJTX Auto Mode Section (AutoQSO)
                Button(action: {
                    viewModel.isAutoModeEnabled.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isAutoModeEnabled ? "play.circle.fill" : "play.circle")
                        if viewModel.isAutoModeEnabled && viewModel.isAutoModeOnlyCQEnabled {
                            VStack(alignment: .leading, spacing: -1) {
                                Text("Auto ON")
                                    .font(.system(size: 10, weight: .bold))
                                Text("CQ Only")
                                    .font(.system(size: 8, weight: .semibold))
                            }
                        } else {
                            Text(viewModel.isAutoModeEnabled ? "Auto ON" : "Auto OFF")
                                .fontWeight(.bold)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isAutoModeEnabled ? .green : .gray)
                .help(L("toolbar.autoTransmit.tooltip"))
                
                // Sort Order & Pause Section
                Button(action: {
                    isNewestOnTop.toggle()
                }) {
                    Image(systemName: isNewestOnTop ? "arrow.up" : "arrow.down")
                }
                .buttonStyle(.bordered)
                .help(isNewestOnTop ? L("toolbar.sort.newestBottom") : L("toolbar.sort.newestTop"))
                
                Button(action: {
                    viewModel.isMainTableScrollPaused.toggle()
                }) {
                    Image(systemName: viewModel.isMainTableScrollPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.bordered)
                .foregroundStyle(viewModel.isMainTableScrollPaused ? .orange : .primary)
                .help(viewModel.isMainTableScrollPaused ? L("toolbar.freeze.tooltip.resume") : L("toolbar.freeze.tooltip.pause"))
                
                // Filter Switch: Nur akzeptierte/gefilterte Spots anzeigen (links von Suchen)
                if showOnlyAcceptedSpots {
                    Button(action: {
                        showOnlyAcceptedSpots.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else {
                    Button(action: {
                        showOnlyAcceptedSpots.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .buttonStyle(.bordered)
                }

                // Search field
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(L("toolbar.search.placeholder"), text: $viewModel.mainTableSearchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                        .frame(width: 120)
                    if !viewModel.mainTableSearchText.isEmpty {
                        Button(action: { viewModel.mainTableSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(.rect(cornerRadius: 6))
                
                Button(action: {
                    viewModel.clearTable()
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .help(L("toolbar.clearTable.tooltip"))
                
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
                    .help(L("toolbar.logbook"))

                    Button(action: {
                        openWindow(id: "propagation_map")
                    }) {
                        Image(systemName: "map")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.propMap"))
                    
                    Button(action: {
                        openWindow(id: "new_grid_map")
                    }) {
                        Image(systemName: "square.grid.3x3.topleft.filled")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.gridMap"))
                    
                    Button(action: {
                        toggleCompactMode(toCompact: true)
                    }) {
                        Image(systemName: "rectangle.compress.vertical")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.compact"))
                    
                    Button(action: {
                        openWindow(id: "settings")
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.settings"))
                    
                    Button(action: {
                        openWindow(id: "help")
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.help"))
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
                    .help(L("toolbar.filterSidebar"))
                } else {
                    Button(action: {
                        isSidebarVisible.toggle()
                    }) {
                        Image(systemName: "sidebar.right")
                    }
                    .buttonStyle(.bordered)
                    .help(L("toolbar.filterSidebar"))
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
                        .foregroundStyle(mwRank != nil ? .red : .orange)
                    
                    if let rank = mwRank {
                        Text("🔥 #\(rank)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 4))
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
                        .foregroundStyle(.blue)
                    
                    if let dist = distanceKm {
                        Text(String(format: "%.0f km", dist))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.blue)
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
                        Text(L("banner.distance.none"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(.rect(cornerRadius: 6))
                
                Divider()
                    .frame(height: 20)
                
                Text(L("banner.bands"))
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
                                .foregroundStyle(isWorked ? .white : .secondary)
                                .clipShape(.rect(cornerRadius: 4))
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
        rootContent
            .preferredColorScheme(preferredScheme)
            .frame(
                minWidth: isCompactMode ? 480 : (800 + (isLeftSidebarVisible ? 220 : 0) + (isSidebarVisible ? 250 : 0)),
                idealWidth: isCompactMode ? 520 : 1380,
                minHeight: isCompactMode ? 320 : 650,
                idealHeight: isCompactMode ? 380 : 750
            )
    }

    @ViewBuilder
    private var rootContent: some View {
        VStack(spacing: 0) {
            if isCompactMode {
                compactMainView
            } else {
                normalMainView
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
        .onAppear(perform: handleOnAppear)
        .onChange(of: tableSelection, handleTableSelectionChange)
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
        .background(WindowAccessor { window in
            if self.hostingWindow == nil {
                self.hostingWindow = window
            }
        })
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
            withAnimation(.easeInOut(duration: 0.2)) {
                isLeftSidebarVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleRightSidebar"))) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isSidebarVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification), perform: handleWindowResize)
        .sheet(isPresented: $isShowingProfileManagerSheet) {
            FilterProfileManagerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingNewProfileAlert) {
            SaveNewProfileSheet(viewModel: viewModel)
        }
    }

    private func handleOnAppear() {
        viewModel.retryCooldownMinutes = retryCooldownMinutes
        viewModel.startServer(port: UInt16(udpPort), address: udpAddress)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isTransitioningMode = false
        }
    }

    private func handleTableSelectionChange(_: WSJTXDecode.ID?, newID: WSJTXDecode.ID?) {
        if let id = newID,
           let decode = viewModel.server.decodes.first(where: { $0.id == id }) {
            viewModel.selectedCallsign = decode.callsign
        } else {
            viewModel.selectedCallsign = ""
        }
    }

    private func handleWindowResize(_ notification: Notification) {
        guard !isTransitioningMode else { return }
        if let window = notification.object as? NSWindow, window == self.hostingWindow {
            if isCompactMode {
                self.compactWindowWidth = Double(window.frame.width)
                self.compactWindowHeight = Double(window.frame.height)
            } else {
                self.normalWindowWidth = Double(window.frame.width)
                self.normalWindowHeight = Double(window.frame.height)
            }
        }
    }

    private var normalMainView: some View {
        VStack(spacing: 0) {
            topToolbarView
            Divider()
            displayBannerView
            
            HSplitView {
                if isLeftSidebarVisible {
                    leftSidebar
                        .frame(minWidth: 220, idealWidth: CGFloat(leftSidebarWidth), maxWidth: 300, maxHeight: .infinity)
                        .background(Color(NSColor.windowBackgroundColor))
                        .layoutPriority(0)
                }
                
                VStack(spacing: 0) {
                    if isLogConsoleDetached {
                        HStack(spacing: 8) {
                            Text(L("logs.detached.banner"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(L("logs.attach")) {
                                isLogConsoleDetached = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                        }
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor))
                        Divider()
                        
                        VSplitView {
                            mainFullTableView
                                .frame(minHeight: 200, maxHeight: .infinity)
                                .layoutPriority(1)
                            
                            mostWantedSectionView
                                .frame(minHeight: 60, idealHeight: CGFloat(mostWantedPanelHeight), maxHeight: 300)
                                .layoutPriority(0)
                        }
                        .id("main_vsplit_detached")
                        .background(SplitViewAutosaver(name: "AutoQSO_Main_VSplit_Detached"))
                    } else {
                        VSplitView {
                            let initialH = UserDefaults.standard.double(forKey: "AutoQSO_SplitPos_AutoQSO_Main_VSplit_Docked")
                            let targetH: CGFloat = initialH >= 70 ? CGFloat(initialH) : 180.0
                            
                            LogsConsoleView(viewModel: viewModel, isEmbedded: true)
                                .frame(minHeight: 80, idealHeight: targetH, maxHeight: 450)
                                .layoutPriority(0)
                                .background(SplitViewAutosaver(name: "AutoQSO_Main_VSplit_Docked"))
                            
                            mainFullTableView
                                .frame(minHeight: 200, maxHeight: .infinity)
                                .layoutPriority(1)
                            
                            mostWantedSectionView
                                .frame(minHeight: 60, idealHeight: CGFloat(mostWantedPanelHeight), maxHeight: 300)
                                .layoutPriority(0)
                        }
                        .id("main_vsplit_docked")
                    }
                }
                .frame(minWidth: 500, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                
                if isSidebarVisible {
                    rightSidebar
                        .frame(minWidth: 250, idealWidth: CGFloat(rightSidebarWidth), maxWidth: 400, maxHeight: .infinity)
                        .background(Color(NSColor.windowBackgroundColor))
                        .layoutPriority(0)
                }
            }
            .background(SplitViewAutosaver(name: "AutoQSO_Main_HSplitView"))
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            bottomStatusBar
        }
    }

        private var mainFullTableView: some View {
        Table(displayRows, selection: $tableSelection, columnCustomization: $decodeColumnCustomization) {
            TableColumn(L("table.col.time")) { decode in
                timeCell(for: decode)
            }
            .width(min: 65, ideal: 75, max: 100)
            .customizationID("time")
            
            TableColumn("DX Call") { decode in
                dxCallCell(for: decode)
            }
            .width(min: 80, ideal: 105, max: 180)
            .customizationID("callsign")
            
            TableColumn(L("table.col.country")) { decode in
                landCell(for: decode)
            }
            .width(min: 80, ideal: 120, max: 200)
            .customizationID("country")
            
            TableColumn(L("table.col.spotter")) { decode in
                spotterCell(for: decode)
            }
            .width(min: 60, ideal: 80, max: 120)
            .customizationID("spotter")
            
            TableColumn("Most Wanted") { decode in
                mostWantedCell(for: decode)
            }
            .width(min: 75, ideal: 95, max: 130)
            .customizationID("mostwanted")
            
            TableColumn(L("table.col.distance")) { decode in
                distanceCell(for: decode)
            }
            .width(min: 65, ideal: 85, max: 120)
            .customizationID("distance")
            
            TableColumn(L("table.col.snr")) { decode in
                snrCell(for: decode)
            }
            .width(min: 40, ideal: 55, max: 80)
            .customizationID("snr")
            
            TableColumn(L("table.col.dt")) { decode in
                dtCell(for: decode)
            }
            .width(min: 40, ideal: 55, max: 80)
            .customizationID("dt")
            
            TableColumn(L("table.col.freq")) { decode in
                frequencyCell(for: decode)
            }
            .width(min: 100, ideal: 130, max: 180)
            .customizationID("frequency")
            
            TableColumn(L("table.col.message")) { decode in
                messageCell(for: decode)
            }
            .width(min: 120, ideal: 260, max: 2000)
            .customizationID("message")
        }
    }

    private var compactMainView: some View {
        VStack(spacing: 0) {
            compactToolbarView
            Divider()
            
            if !viewModel.displayCallsign.isEmpty {
                displayBannerView
                Divider()
            }
            
            VSplitView {
                Table(displayRows, selection: $tableSelection, columnCustomization: $compactDecodeColumnCustomization) {
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
                    
                    TableColumn(L("table.col.country")) { decode in
                        landCell(for: decode)
                    }
                    .width(min: 70, ideal: 100, max: 150)
                    .customizationID("country")
                    
                    TableColumn("SNR") { decode in
                        snrCell(for: decode)
                    }
                    .width(min: 35, ideal: 45, max: 60)
                    .customizationID("snr")
                    
                    TableColumn(L("table.col.message")) { decode in
                        messageCell(for: decode)
                    }
                    .width(min: 100, ideal: 200, max: 1000)
                    .customizationID("message")
                }
                .layoutPriority(1)
                
                compactMostWantedView
                    .frame(minHeight: 40, idealHeight: CGFloat(compactMostWantedHeight), maxHeight: 150)
                    .layoutPriority(0)
            }
            .background(SplitViewAutosaver(name: "AutoQSO_Compact_VSplitView"))
        }
    }

    private var mostWantedSectionView: some View {
        let mostWantedDecodes = viewModel.mostWantedDecodes
        return VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 14, weight: .bold))
                
                Text(L("mostWanted.title"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.red)
                
                Text("\(mostWantedDecodes.count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(mostWantedDecodes.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 10))
                
                Spacer()
                
                let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                Text("QTH: \(myGrid)")
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
                        Text(L("mostWanted.empty"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                                            .foregroundStyle(.primary)
                                        if let rank = mwRank {
                                            Text("#\(rank)")
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.red)
                                                .foregroundStyle(.white)
                                                .clipShape(.rect(cornerRadius: 3))
                                        }
                                    }
                                    Text(decode.message)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(decode.snr) dB")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundStyle(.blue)
                                        .clipShape(.rect(cornerRadius: 4))
                                    
                                    if let d = dist {
                                        Text(String(format: "%.0f km", d))
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                // Call Button / Spotter Badge
                                if decode.isClusterSpot {
                                    Text(decode.spotter.isEmpty ? "SPOT" : "de \(decode.spotter)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundStyle(.purple)
                                        .clipShape(.rect(cornerRadius: 4))
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
                            .clipShape(.rect(cornerRadius: 6))
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
        .background(Color(NSColor.windowBackgroundColor))
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
                    if viewModel.isAutoModeEnabled && viewModel.isAutoModeOnlyCQEnabled {
                        VStack(alignment: .leading, spacing: -1) {
                            Text("Auto ON")
                                .font(.system(size: 9, weight: .bold))
                            Text("CQ Only")
                                .font(.system(size: 7, weight: .semibold))
                        }
                    } else {
                        Text(viewModel.isAutoModeEnabled ? "Auto ON" : "Auto OFF")
                            .fontWeight(.bold)
                    }
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
            .foregroundStyle(viewModel.isMainTableScrollPaused ? .orange : .primary)
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
                    .foregroundStyle(.secondary)
                TextField("Suchen...", text: $viewModel.mainTableSearchText)
                    .font(.system(size: 10))
                    .textFieldStyle(.plain)
                    .frame(width: 75)
                if !viewModel.mainTableSearchText.isEmpty {
                    Button(action: { viewModel.mainTableSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(.rect(cornerRadius: 4))
            
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
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 3))
                        .help(L("status.tx.transmitting"))
                } else if viewModel.server.isTxEnabled {
                    Text("TX")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 3))
                        .help(L("status.tx.ready"))
                } else {
                    Text("TX")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 3))
                        .help(L("status.tx.off"))
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
                    .foregroundStyle(.red)
                    .font(.system(size: 11, weight: .bold))
                
                Text("MOST WANTED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.red)
                
                Text("\(mostWantedDecodes.count)")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(mostWantedDecodes.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 8))
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            Divider()
            
            if mostWantedDecodes.isEmpty {
                HStack {
                    Spacer()
                    Text("Keine Most Wanted Stationen.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
                                            .foregroundStyle(.white)
                                            .clipShape(.rect(cornerRadius: 2))
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.08))
                                .clipShape(.rect(cornerRadius: 4))
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
                    .foregroundStyle(.blue)
                    .font(.system(size: 11))
                Text(viewModel.currentQSOStatus == "Bereit" ? L("status.sync.ready") : viewModel.currentQSOStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.primary)
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
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 4))
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text(L("status.wsjtx.disconnected"))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.8))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 4))
                }
                
                // TX Status Indicator
                if viewModel.server.isTransmitting {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(L("status.tx.transmitting"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 4))
                    .shadow(color: .red.opacity(0.5), radius: 2)
                } else if viewModel.server.isTxEnabled {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text(L("status.tx.ready"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(.rect(cornerRadius: 4))
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                        Text(L("status.tx.off"))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.15))
                    .foregroundStyle(.secondary)
                    .clipShape(.rect(cornerRadius: 4))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func dxCallCell(for row: SpotRowData) -> some View {
        HStack(spacing: 4) {
            cellText(row.callsign, row: row)
            if row.isMostWanted {
                Text("🔥")
                    .font(.caption2)
            }
        }
    }
    
    @ViewBuilder
    private func landCell(for row: SpotRowData) -> some View {
        cellText(row.country, row: row)
    }
    
    @ViewBuilder
    private func mostWantedCell(for row: SpotRowData) -> some View {
        if let rank = row.mostWantedRank {
            HStack(spacing: 4) {
                Text("🔥 #\(rank)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 4))
            }
        } else {
            Text("-")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func distanceCell(for row: SpotRowData) -> some View {
        cellText(row.distanceText, row: row)
    }
    
    @ViewBuilder
    private func timeCell(for row: SpotRowData) -> some View {
        cellText(row.timeString, row: row)
    }
    
    @ViewBuilder
    private func spotterCell(for row: SpotRowData) -> some View {
        cellText(row.spotter, row: row)
    }
    
    @ViewBuilder
    private func snrCell(for row: SpotRowData) -> some View {
        cellText(row.snrString, row: row)
    }
    
    @ViewBuilder
    private func dtCell(for row: SpotRowData) -> some View {
        cellText(row.dtString, row: row)
    }
    
    @ViewBuilder
    private func frequencyCell(for row: SpotRowData) -> some View {
        HStack(spacing: 3) {
            cellText(row.formattedHfFrequency, row: row)
            if row.deltaFrequency > 0 {
                Text("(+\(row.deltaFrequency)Hz)")
                    .font(.system(size: max(8, CGFloat(fontSizeTable) - 2), design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func messageCell(for row: SpotRowData) -> some View {
        cellText(row.message, row: row)
    }

    private func cellText(_ text: String, row: SpotRowData) -> some View {
        Text(text)
            .font(.system(size: CGFloat(fontSizeTable)))
            .foregroundStyle(rowColor(for: row))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                viewModel.sendReply(for: row.rawDecode)
            }
            .onTapGesture(count: 1) {
                selectAndLookup(row: row)
            }
    }
    
    private func selectAndLookup(row: SpotRowData) {
        let call = row.callsign
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
    
    private func rowColor(for row: SpotRowData) -> Color {
        switch row.status {
        case .mostWanted:
            return highlightMostWanted ? mostWantedColor : standardColor
        case .interestingCQ:
            return cqColor
        case .worked:
            return workedColor
        case .filteredOut:
            return .gray.opacity(0.6)
        case .normal:
            return standardColor
        }
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
            Text(L("sidebar.right.title"))
                .font(.headline)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            VStack(spacing: 8) {
                Toggle(isOn: $viewModel.isFiltersEnabled) {
                    Text(L("common.apply")).bold().font(.caption)
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
                
                if rightSidebarTab == 0 {
                    HStack(spacing: 6) {
                        Menu {
                            // System Presets
                            Section(isDe ? "System-Vorlagen" : "System Presets") {
                                ForEach(viewModel.filterProfiles.filter { $0.isSystem }) { profile in
                                    Button {
                                        viewModel.applyFilterProfile(profile)
                                    } label: {
                                        HStack {
                                            Label(profile.name, systemImage: profile.iconName)
                                            if profile.id == viewModel.activeFilterProfileId {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // User Custom Profiles
                            let customProfiles = viewModel.filterProfiles.filter { !$0.isSystem }
                            if !customProfiles.isEmpty {
                                Section(isDe ? "Eigene Profile" : "Custom Profiles") {
                                    ForEach(customProfiles) { profile in
                                        Button {
                                            viewModel.applyFilterProfile(profile)
                                        } label: {
                                            HStack {
                                                Label(profile.name, systemImage: profile.iconName)
                                                if profile.id == viewModel.activeFilterProfileId {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            // Actions
                            if viewModel.isFilterProfileModified {
                                Button {
                                    viewModel.saveCurrentSettingsToActiveProfile()
                                } label: {
                                    Label(
                                        isDe ? "Änderungen in '\(viewModel.activeFilterProfile?.name ?? "Profil")' speichern" : "Save Changes to '\(viewModel.activeFilterProfile?.name ?? "Profile")'",
                                        systemImage: "square.and.arrow.down"
                                    )
                                }
                                
                                Button {
                                    viewModel.resetActiveProfileToOriginal()
                                } label: {
                                    Label(isDe ? "Auf Originalzustand zurücksetzen" : "Reset to Original", systemImage: "arrow.counterclockwise")
                                }
                                
                                Divider()
                            }
                            
                            Button {
                                newProfileName = (viewModel.activeFilterProfile?.name ?? "Profil") + (isDe ? " (Kopie)" : " (Copy)")
                                isShowingNewProfileAlert = true
                            } label: {
                                Label(isDe ? "Als neues Profil speichern..." : "Save as New Profile...", systemImage: "plus.square")
                            }
                            
                            Button {
                                isShowingProfileManagerSheet = true
                            } label: {
                                Label(isDe ? "Profile verwalten..." : "Manage Profiles...", systemImage: "slider.horizontal.2.square")
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: viewModel.activeFilterProfile?.iconName ?? "bookmark.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.blue)
                                
                                Text(viewModel.activeFilterProfile?.name ?? "Allround")
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                                
                                if viewModel.isFilterProfileModified {
                                    Text("*")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.orange)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(.rect(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(viewModel.isFilterProfileModified ? Color.orange.opacity(0.6) : Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                        .help(isDe ? "Aktives Filter-Profil wählen oder anpassen" : "Select or manage active filter profile")
                        
                        Button {
                            newProfileName = (viewModel.activeFilterProfile?.name ?? "Profil") + (isDe ? " (Kopie)" : " (Copy)")
                            isShowingNewProfileAlert = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                                .padding(5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(.rect(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(isDe ? "Aktuelle Einstellungen als neues Profil speichern" : "Save current settings as new profile")
                        
                        Button {
                            isShowingProfileManagerSheet = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 10))
                                .padding(5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(.rect(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(isDe ? "Profile verwalten (Umbenennen, Duplizieren, Export/Import)" : "Manage Profiles (Rename, Duplicate, Export/Import)")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
                
                Divider()
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


    private var continentCodes: [(code: String, nameKey: String)] {
        [
            ("AF", L("continent.AF")),
            ("AN", L("continent.AN")),
            ("AS", L("continent.AS")),
            ("EU", L("continent.EU")),
            ("NA", L("continent.NA")),
            ("OC", L("continent.OC")),
            ("SA", L("continent.SA"))
        ]
    }

    @ViewBuilder
    private var countryFilterContent: some View {
        ForEach(Array(viewModel.activeFilterOrder.enumerated()), id: \.element) { index, sectionId in
            filterSectionView(for: sectionId, index: index)
        }
    }

    private func sidebarHeader(_ title: String, isExpanded: Binding<Bool>, activeCount: Int = 0, sectionId: DXFilterSectionId? = nil) -> some View {
        HStack(alignment: .center, spacing: 6) {
            if let sec = sectionId {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
                    .onDrag {
                        self.draggedFilterSection = sec
                        return NSItemProvider(object: sec.rawValue as NSString)
                    }
                    .help(L("filter.order.dragHint"))
            }

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.primary)
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
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color.blue)
                .clipShape(.rect(cornerRadius: 4))
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.wrappedValue.toggle()
        }
        .onDrop(of: [UTType.plainText, UTType.text], delegate: FilterSectionDropDelegate(targetSection: sectionId ?? .continents, viewModel: viewModel, draggedSection: $draggedFilterSection))
    }

    @ViewBuilder
    private func filterSectionView(for sectionId: DXFilterSectionId, index: Int) -> some View {
        switch sectionId {
        case .messageFilter:
            Section(isExpanded: $isMessageFilterExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isMessageFilterEnabled },
                        set: { viewModel.isMessageFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    )) {
                        Text(isDe ? "Nachrichten-Inhalt filtern" : "Filter Message Content")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    
                    Text(isDe ? "Filtert Spots nach Text im Nachrichten-/Kommentarfeld (Groß-/Kleinschreibung egal). Unterstützt boolesche Logik: AND, OR, () und Phrasen in \"\" (z. B. \"5 up\")." : "Filters spots by text in message/comment field (case-insensitive). Supports boolean logic: AND, OR, () and quoted phrases (e.g. \"5 up\").")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        
                        TextField(isDe ? "z. B. SSB OR RTTY OR \"5 up\"" : "e.g. SSB OR RTTY OR \"5 up\"", text: Binding(
                            get: { viewModel.messageFilterQuery },
                            set: { viewModel.messageFilterQuery = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        
                        if !viewModel.messageFilterQuery.isEmpty {
                            Button(action: {
                                viewModel.messageFilterQuery = ""
                                viewModel.saveFilters()
                                viewModel.clearBlockedDecodes()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(5)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(.rect(cornerRadius: 5))
                }
                .padding(6)
                .background(Color.blue.opacity(0.04))
                .clipShape(.rect(cornerRadius: 6))
            } header: {
                let sectionTitle = "\(index + 1). \(L("filter.section.messageFilter"))"
                sidebarHeader(
                    sectionTitle,
                    isExpanded: $isMessageFilterExpanded,
                    activeCount: (viewModel.isMessageFilterEnabled && !viewModel.messageFilterQuery.trimmingCharacters(in: .whitespaces).isEmpty) ? 1 : 0,
                    sectionId: sectionId
                )
            }

        case .continents:
            Section(isExpanded: $isContinentFilterExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.continents.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

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
                    Button(L("filter.continents.allOn")) { viewModel.setAllContinents(enabled: true) }
                        .buttonStyle(.bordered).controlSize(.small)
                    Button(L("filter.continents.allOff")) { viewModel.setAllContinents(enabled: false) }
                        .buttonStyle(.bordered).controlSize(.small)
                }
                .padding(.top, 2)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.continents"))", isExpanded: $isContinentFilterExpanded, activeCount: viewModel.disabledContinents.count, sectionId: sectionId)
            }

        case .blockedCountries:
            Section(isExpanded: $isBlockedCountriesExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Blacklist-Modus").font(.caption).bold()
                    Text(L("filter.blacklist.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.red.opacity(0.05)).clipShape(.rect(cornerRadius: 6))
                
                ForEach(viewModel.blockedCountries, id: \.self) { country in
                    HStack {
                        Text(country).font(.system(size: 11))
                        Spacer()
                        Button { viewModel.removeBlockedCountry(country) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.blockCountry.label")).font(.caption2).foregroundStyle(.secondary)
                    CountryInputField(text: $newCountry, suggestions: viewModel.countrySuggestions(for: newCountry)) {
                        viewModel.addBlockedCountry(newCountry)
                        newCountry = ""
                    }
                }.padding(.vertical, 4)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.blockedCountries"))", isExpanded: $isBlockedCountriesExpanded, activeCount: viewModel.blockedCountries.count, sectionId: sectionId)
            }

        case .allowedCountries:
            Section(isExpanded: $isAllowedDXCountriesExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP").font(.caption).bold().foregroundStyle(.blue)
                    Text(L("filter.whitelist.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

                ForEach(viewModel.allowedCountries, id: \.self) { country in
                    HStack {
                        Text(country).font(.system(size: 11))
                        Spacer()
                        Button { viewModel.removeAllowedCountry(country) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.allowCountry.label")).font(.caption2).foregroundStyle(.secondary)
                    CountryInputField(text: $newAllowedDXCountry, suggestions: viewModel.countrySuggestions(for: newAllowedDXCountry)) {
                        viewModel.addAllowedCountry(newAllowedDXCountry)
                        newAllowedDXCountry = ""
                    }
                }.padding(.vertical, 4)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.allowedCountries"))", isExpanded: $isAllowedDXCountriesExpanded, activeCount: viewModel.allowedCountries.count, sectionId: sectionId)
            }

        case .blockedCQZones:
            Section(isExpanded: $isBlockedCQZonesExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.cqZone.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.red.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

                ForEach(viewModel.blockedCQZones, id: \.self) { zone in
                    HStack {
                        Text("CQ-Zone \(zone)").font(.system(size: 11))
                        Spacer()
                        Button { viewModel.removeBlockedCQZone(zone) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.cqZone.label")).font(.caption2).foregroundStyle(.secondary)
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
                        .foregroundStyle(.blue)
                        .disabled(Int(newCQZone.trimmingCharacters(in: .whitespaces)) == nil)
                    }
                }.padding(.vertical, 4)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.blockedCQZones"))", isExpanded: $isBlockedCQZonesExpanded, activeCount: viewModel.blockedCQZones.count, sectionId: sectionId)
            }

        case .blockedITUZones:
            Section(isExpanded: $isBlockedITUZonesExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.ituZone.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.red.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

                ForEach(viewModel.blockedITUZones, id: \.self) { zone in
                    HStack {
                        Text("ITU-Zone \(zone)").font(.system(size: 11))
                        Spacer()
                        Button { viewModel.removeBlockedITUZone(zone) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.ituZone.label")).font(.caption2).foregroundStyle(.secondary)
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
                        .foregroundStyle(.blue)
                        .disabled(Int(newITUZone.trimmingCharacters(in: .whitespaces)) == nil)
                    }
                }.padding(.vertical, 4)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.blockedITUZones"))", isExpanded: $isBlockedITUZonesExpanded, activeCount: viewModel.blockedITUZones.count, sectionId: sectionId)
            }

        case .allowedCallsigns:
            Section(isExpanded: $isAllowedDXCallsignsExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP").font(.caption).bold().foregroundStyle(.blue)
                    Text(L("filter.callsigns.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

                ForEach(viewModel.allowedDXCallsigns, id: \.self) { callsign in
                    HStack {
                        Text(callsign).font(.system(size: 11, design: .monospaced)).bold()
                        Spacer()
                        Button { viewModel.removeAllowedDXCallsign(callsign) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.callsigns.label")).font(.caption2).foregroundStyle(.secondary)
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
                                .foregroundStyle(newAllowedDXCallsign.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(newAllowedDXCallsign.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }.padding(.vertical, 4)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.allowedCallsigns"))", isExpanded: $isAllowedDXCallsignsExpanded, activeCount: viewModel.allowedDXCallsigns.count, sectionId: sectionId)
            }

        case .allowedGrids:
            Section(isExpanded: $isAllowedGridsExpanded) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VIP").font(.caption).bold().foregroundStyle(.blue)
                    Text(L("filter.allowedGrids.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

                ForEach(viewModel.allowedGrids, id: \.self) { grid in
                    HStack {
                        Text(grid).font(.system(size: 11, design: .monospaced)).bold()
                        Spacer()
                        Button { viewModel.removeAllowedGrid(grid) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("filter.allowedGrids.label")).font(.caption2).foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("z.B. DN61-DN74 oder KN64, KN67", text: $newAllowedGrid)
                            .textFieldStyle(UnifiedTextFieldStyle())
                            .onSubmit {
                                viewModel.addAllowedGrid(newAllowedGrid)
                                newAllowedGrid = ""
                            }
                        Button {
                            viewModel.addAllowedGrid(newAllowedGrid)
                            newAllowedGrid = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(newAllowedGrid.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(newAllowedGrid.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }.padding(.vertical, 4)
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.allowedGrids"))", isExpanded: $isAllowedGridsExpanded, activeCount: viewModel.allowedGrids.count, sectionId: sectionId)
            }

        case .mostWantedOnly:
            Section(isExpanded: $isMostWantedOnlyExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isOnlyMostWantedFilterEnabled },
                        set: { viewModel.isOnlyMostWantedFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    )) {
                        Text(L("filter.mostWantedOnly.toggle")).font(.system(size: 11)).bold()
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    HStack(spacing: 6) {
                        Text(L("filter.mostWantedOnly.threshold")).font(.system(size: 10))
                        
                        Picker("", selection: Binding(
                            get: { viewModel.maxMostWantedRank },
                            set: { viewModel.maxMostWantedRank = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                        )) {
                            Text("Top 10").tag(10)
                            Text("Top 20").tag(20)
                            Text("Top 50").tag(50)
                            Text("Top 100").tag(100)
                        }
                        .pickerStyle(.menu)
                        .controlSize(.mini)
                    }

                    Text(L("filter.mostWantedOnly.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.mostWantedOnly"))", isExpanded: $isMostWantedOnlyExpanded, activeCount: viewModel.isOnlyMostWantedFilterEnabled ? 1 : 0, sectionId: sectionId)
            }

        case .workedBefore:
            Section(isExpanded: $isWorkedBeforeFilterExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isWorkedBeforeFilterEnabled },
                        set: { viewModel.isWorkedBeforeFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    )) {
                        Text(L("filter.workedBefore.toggle")).font(.system(size: 11)).bold()
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    HStack(spacing: 6) {
                        Text(L("filter.workedBefore.timespan")).font(.system(size: 10))
                        
                        NumericTextField("1", value: Binding(
                            get: { viewModel.workedBeforeDuration },
                            set: { viewModel.workedBeforeDuration = max(0, min(999, $0)); viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                        ), range: 0...999)
                        .textFieldStyle(UnifiedTextFieldStyle())
                        .frame(width: 42)
                        .controlSize(.mini)
                        
                        Picker("", selection: Binding(
                            get: { viewModel.workedBeforeUnit },
                            set: { viewModel.workedBeforeUnit = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                        )) {
                            ForEach(WorkedBeforeUnit.allCases) { unit in
                                Text(viewModel.workedBeforeDuration == 1 ? unit.singularTitle : unit.title).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .controlSize(.mini)
                    }

                    Text(L("filter.workedBefore.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.workedBefore"))", isExpanded: $isWorkedBeforeFilterExpanded, activeCount: viewModel.isWorkedBeforeFilterEnabled ? 1 : 0, sectionId: sectionId)
            }

        case .gridFilter:
            Section(isExpanded: $isNewGridFilterExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isNew4CharGridOnlyFilterEnabled },
                        set: { viewModel.isNew4CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    )) {
                        Text(L("filter.grid.4char")).font(.system(size: 11)).bold()
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    Toggle(isOn: Binding(
                        get: { viewModel.isNew6CharGridOnlyFilterEnabled },
                        set: { viewModel.isNew6CharGridOnlyFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    )) {
                        Text(L("filter.grid.6char")).font(.system(size: 11)).bold()
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    Text(L("filter.grid.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.gridFilter"))", isExpanded: $isNewGridFilterExpanded, activeCount: (viewModel.isNew4CharGridOnlyFilterEnabled ? 1 : 0) + (viewModel.isNew6CharGridOnlyFilterEnabled ? 1 : 0), sectionId: sectionId)
            }

        case .wsjtCQ:
            Section(isExpanded: $isWsjtSpecialFilterExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isWsjtSpecialFilterEnabled },
                        set: { viewModel.isWsjtSpecialFilterEnabled = $0; viewModel.saveFilters(); viewModel.clearBlockedDecodes() }
                    )) {
                        Text(L("filter.wsjtCQ.toggle")).font(.system(size: 11)).bold()
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    Text(L("filter.wsjtCQ.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.wsjtCQ"))", isExpanded: $isWsjtSpecialFilterExpanded, activeCount: viewModel.isWsjtSpecialFilterEnabled ? 1 : 0, sectionId: sectionId)
            }

        case .duplicates:
            Section(isExpanded: $isDuplicateFilterExpanded) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { viewModel.isDuplicateFilterEnabled },
                        set: { viewModel.isDuplicateFilterEnabled = $0; viewModel.saveFilters() }
                    )) {
                        Text(L("filter.duplicates.toggle")).font(.system(size: 11)).bold()
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                    HStack {
                        Text(L("filter.duplicates.tolerance")).font(.system(size: 10))
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
                        Text(L("filter.duplicates.window")).font(.system(size: 10))
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

                    Text(L("filter.duplicates.desc"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .italic()
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))
            } header: {
                sidebarHeader("\(index + 1). \(L("filter.section.duplicates"))", isExpanded: $isDuplicateFilterExpanded, activeCount: viewModel.isDuplicateFilterEnabled ? 1 : 0, sectionId: sectionId)
            }
        }
    }

    @ViewBuilder
    private var spotterFilterContent: some View {
        Section(isExpanded: $isAllowedSpotterCountriesExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whitelist-Modus").font(.caption).bold()
                Text(L("filter.spotter.desc"))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

            ForEach(viewModel.allowedSpotterCountries, id: \.self) { country in
                HStack {
                    Text(country).font(.system(size: 11))
                    Spacer()
                    Button { viewModel.removeAllowedSpotterCountry(country) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("filter.spotter.label")).font(.caption2).foregroundStyle(.secondary)
                CountryInputField(text: $newSpotterCountry, suggestions: viewModel.countrySuggestions(for: newSpotterCountry)) {
                    viewModel.addAllowedSpotterCountry(newSpotterCountry)
                    newSpotterCountry = ""
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader(L("filter.section.spotterCountries"), isExpanded: $isAllowedSpotterCountriesExpanded, activeCount: viewModel.allowedSpotterCountries.count)
        }

        Section(isExpanded: $isAllowedSpotterCallsignsExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Whitelist-Modus").font(.caption).bold()
                Text("NUR Dekodierungen, deren lokaler Spotter-Rufzeichen mit diesen übereinstimmt, werden durchgelassen.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(6).background(Color.blue.opacity(0.05)).clipShape(.rect(cornerRadius: 6))

            ForEach(viewModel.allowedSpotterCallsigns, id: \.self) { callsign in
                HStack {
                    Text(callsign).font(.system(size: 11, design: .monospaced)).bold()
                    Spacer()
                    Button { viewModel.removeAllowedSpotterCallsign(callsign) } label: { Image(systemName: "minus.circle") }.buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Spotter erlauben").font(.caption2).foregroundStyle(.secondary)
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
                            .foregroundStyle(newAllowedSpotterCallsign.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(newAllowedSpotterCallsign.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }.padding(.vertical, 4)
        } header: {
            sidebarHeader("Erlaubte Spotter-Rufzeichen", isExpanded: $isAllowedSpotterCallsignsExpanded, activeCount: viewModel.allowedSpotterCallsigns.count)
        }
    }

    @ViewBuilder
    private var leftSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("sidebar.left.title").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.primary)
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
                            Text("UDP IP-Adresse").font(.caption).foregroundStyle(.secondary)
                            TextField("224.0.0.1", text: $udpAddress)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("UDP Port").font(.caption).foregroundStyle(.secondary)
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
                                .foregroundStyle(isMulticastAddress ? .blue : .orange)
                                .clipShape(.rect(cornerRadius: 3))
                        }
                        
                        Button(L("sidebar.left.connect")) {
                            viewModel.startServer(port: UInt16(udpPort), address: udpAddress)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    sidebarHeader(L("sidebar.left.wsjtx"), isExpanded: $isWsjtxServerExpanded)
                }
                
                Section(isExpanded: $isUdpBridgeExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isDe ? "UDP Weiterleitungs-IP" : "UDP Forwarding IP").font(.caption).foregroundStyle(.secondary)
                            TextField("127.0.0.1", text: $udpBridgeAddress)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isDe ? "Weiterleitungs-Port (Bridge)" : "Forwarding Port (Bridge)").font(.caption).foregroundStyle(.secondary)
                            NumericTextField(isDe ? "z.B. 2238 (0 = Aus)" : "e.g. 2238 (0 = Off)", value: $udpBridgePort)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                        }
                        
                        let isMulticastBridge = {
                            if let firstOctetStr = udpBridgeAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
                               let firstOctet = Int(firstOctetStr) {
                                return firstOctet >= 224 && firstOctet <= 239
                            }
                            return false
                        }()
                        
                        let isBridgeActive = udpBridgePort > 0
                        HStack {
                            Text(isDe ? "Status:" : "Status:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(isBridgeActive ? (isDe ? "AKTIV (Port \(udpBridgePort))" : "ACTIVE (Port \(udpBridgePort))") : L("status.cluster.disabled").uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(isBridgeActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                                .foregroundStyle(isBridgeActive ? .green : .gray)
                                .clipShape(.rect(cornerRadius: 3))
                            
                            if isBridgeActive {
                                Text(isMulticastBridge ? "MC" : "UC")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(isMulticastBridge ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                                    .foregroundStyle(isMulticastBridge ? .blue : .orange)
                                    .clipShape(.rect(cornerRadius: 3))
                            }
                        }
                        
                        Text(isDe ? "Leitet alle empfangenen FT8/FT4 Dekodierungen, welche die aktiven DX-Filter passiert haben, an diesen UDP-Port weiter." : "Forwards all received FT8/FT4 decodes passing active DX filters to this UDP port.")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    sidebarHeader(L("sidebar.left.udpBridge"), isExpanded: $isUdpBridgeExpanded, activeCount: udpBridgePort > 0 ? 1 : 0)
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
                                .foregroundStyle(.secondary)
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
                                Text(L("status.cluster.disabled")).tag(ClusterServer?.none)
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
                                .foregroundStyle(.secondary)
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
                                Text(L("status.cluster.disabled")).tag(ClusterServer?.none)
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
                                .foregroundStyle(.secondary)
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
                                Text(L("status.cluster.disabled")).tag(ClusterServer?.none)
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
                    sidebarHeader(L("sidebar.left.cluster"), isExpanded: $isDxClusterExpanded, activeCount: activeCount)
                }
                
                Section(isExpanded: $isTelnetServerExpanded) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("settings.telnet.port")).font(.caption).foregroundStyle(.secondary)
                            TextField("8000", value: $telnetServerPort, format: .number.grouping(.never))
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                                .onChange(of: telnetServerPort) { _, _ in
                                    viewModel.startTelnetServer()
                                }
                        }
                        
                        let isTelnetActive = viewModel.telnetServerError == nil
                        HStack {
                            Text(isDe ? "Server Status:" : "Server Status:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(isTelnetActive ? (isDe ? "AKTIV (Clients: \(viewModel.telnetClientCount))" : "ACTIVE (Clients: \(viewModel.telnetClientCount))") : (isDe ? "FEHLER" : "ERROR"))
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(isTelnetActive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                .foregroundStyle(isTelnetActive ? .green : .red)
                                .clipShape(.rect(cornerRadius: 3))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("settings.telnet.callsign")).font(.caption).foregroundStyle(.secondary)
                            TextField("GUEST", text: $clusterCallsign)
                                .textFieldStyle(UnifiedTextFieldStyle())
                                .controlSize(.small)
                                .onChange(of: clusterCallsign) { _, _ in
                                    viewModel.reconnectClusters()
                                }
                        }
                        
                        Toggle(L("settings.telnet.forwardDecodes"), isOn: $isWsjtTelnetOutputEnabled)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                            .font(.system(size: 10.5))
                    }
                } header: {
                    sidebarHeader(L("sidebar.left.telnetServer"), isExpanded: $isTelnetServerExpanded, activeCount: viewModel.telnetClientCount > 0 ? 1 : 0)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
        }
    }

    private func toggleCompactMode(toCompact: Bool) {
        self.isTransitioningMode = true
        self.isCompactMode = toCompact
        
        DispatchQueue.main.async {
            guard let window = self.hostingWindow ?? NSApp.mainWindow ?? NSApp.keyWindow else {
                self.isTransitioningMode = false
                return
            }
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                self.isTransitioningMode = false
            }
        }
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
                .foregroundStyle(.blue)
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
                .clipShape(.rect(cornerRadius: 4))
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

struct FilterSectionDropDelegate: DropDelegate {
    let targetSection: DXFilterSectionId
    let viewModel: DecodeViewModel
    @Binding var draggedSection: DXFilterSectionId?
    
    func dropEntered(info: DropInfo) {
        guard let dragged = draggedSection, dragged != targetSection else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.moveFilterSection(dragged: dragged, to: targetSection)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedSection = nil
        return true
    }
}







