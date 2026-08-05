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
    
    @State private var tableSelection: WSJTXDecode.ID? = nil
    
    @AppStorage("isSidebarVisible") private var isSidebarVisible = false
    @AppStorage("isLeftSidebarVisible") private var isLeftSidebarVisible = false
    @AppStorage("leftSidebarWidth") private var leftSidebarWidth: Double = 240.0
    @AppStorage("rightSidebarWidth") private var rightSidebarWidth: Double = 280.0
    @AppStorage("udpBridgePort") private var udpBridgePort = 0
    @State private var rightSidebarTab = 0
    
    // Console Tabs: 0 = System, 1 = WSJT-X, 2 = Cluster-Spots
    @AppStorage("logConsoleTab") private var consoleTab = 0
    @AppStorage("isLogConsoleDetached") private var isLogConsoleDetached = false
    @AppStorage("isNewestOnTop") private var isNewestOnTop = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("logConsoleHeight") private var logConsoleHeight = 150.0
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
    
    private var isMulticastAddress: Bool {
        if let firstOctetStr = udpAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
           let firstOctet = Int(firstOctetStr) {
            return firstOctet >= 224 && firstOctet <= 239
        }
        return false
    }
    
    private var displayDecodes: [WSJTXDecode] {
        isNewestOnTop ? viewModel.server.decodes : Array(viewModel.server.decodes.reversed())
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
        HStack(alignment: .center, spacing: 14) {
            // WSJTX Auto Mode Section
            VStack(alignment: .leading, spacing: 3) {
                Text("WSJTX AUTO TRANSMIT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Button(action: {
                        viewModel.isAutoModeEnabled.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isAutoModeEnabled ? "play.circle.fill" : "play.circle")
                            Text(viewModel.isAutoModeEnabled ? "WSJTX AUTO TRANSMIT AKTIV" : "WSJTX AUTO TRANSMIT AUS")
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isAutoModeEnabled ? .green : .gray)
                    
                    TextField("10", value: $retryCooldownMinutes, format: .number.grouping(.never))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 45)
                    Text("Min. Sperre")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Divider()
                .frame(height: 36)
            
            // Logbook Section
            VStack(alignment: .leading, spacing: 3) {
                Text("LOGBUCH")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Button("Öffnen ↗") {
                    openWindow(id: "logbook")
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
                .frame(height: 36)
            
            // Sort Order Section
            VStack(alignment: .leading, spacing: 3) {
                Text("SORTIERUNG")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Button(action: {
                    isNewestOnTop.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isNewestOnTop ? "arrow.up" : "arrow.down")
                        Text(isNewestOnTop ? "Neu oben" : "Neu unten")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.bordered)
                .help("Reihenfolge der Tabelleneinträge und Logs umschalten (neueste oben/unten)")
            }
            
            Spacer()
            
            // Settings, Filter & Info Buttons
            VStack(alignment: .trailing, spacing: 3) {
                Text("FENSTER")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    if isLeftSidebarVisible {
                        Button(action: {
                            isLeftSidebarVisible.toggle()
                        }) {
                            Label("Verbindung", systemImage: "sidebar.left")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    } else {
                        Button(action: {
                            isLeftSidebarVisible.toggle()
                        }) {
                            Label("Verbindung", systemImage: "sidebar.left")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if isSidebarVisible {
                        Button(action: {
                            isSidebarVisible.toggle()
                        }) {
                            Label("DX-Filter", systemImage: "sidebar.right")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    } else {
                        Button(action: {
                            isSidebarVisible.toggle()
                        }) {
                            Label("DX-Filter", systemImage: "sidebar.right")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: {
                        openWindow(id: "settings")
                    }) {
                        Label("Einstellungen", systemImage: "gearshape")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        openWindow(id: "help")
                    }) {
                        Label("Info", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
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
                            
                            Group {
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
                                
                                TableColumn("HF Freq") { decode in
                                    hfFreqCell(for: decode)
                                }
                                .width(min: 90, ideal: 110, max: 160)
                                .customizationID("hfFreq")
                                
                                TableColumn("Audio (Hz)") { decode in
                                    audioFreqCell(for: decode)
                                }
                                .width(min: 60, ideal: 75, max: 110)
                                .customizationID("audioFreq")
                                
                                TableColumn("Nachricht") { decode in
                                    messageCell(for: decode)
                                }
                                .width(min: 120, ideal: 260, max: 2000)
                                .customizationID("message")
                            }
                        }
                        .layoutPriority(1)
                        
                        // Dedicated Most Wanted Section under the Main Table — dedupliziert nach Rufzeichen (bestes SNR pro Call)
                        let mostWantedDecodes: [WSJTXDecode] = {
                            var seen = Set<String>()
                            var result: [WSJTXDecode] = []
                            let combined = viewModel.server.decodes + viewModel.clusterSpots
                            let filtered = combined
                                .filter { decode in
                                    let call = decode.callsign
                                    guard !call.isEmpty else { return false }
                                    let isMW = MostWantedManager.shared.isMostWanted(callsign: call)
                                    let hasWorkedOnBand = viewModel.lotwManager.hasWorked(callsign: call, band: decode.band)
                                    return isMW && !hasWorkedOnBand && viewModel.shouldAccept(decode: decode)
                                }
                                .sorted { a, b in
                                    // Bestes SNR pro Callsign bevorzugen
                                    a.snr > b.snr
                                }
                            for decode in filtered {
                                let call = decode.callsign.uppercased()
                                if !seen.contains(call) {
                                    seen.insert(call)
                                    result.append(decode)
                                }
                            }
                            // Danach nach Most Wanted Rang sortieren
                            return result.sorted { a, b in
                                let rankA = MostWantedManager.shared.rankForCallsign(a.callsign) ?? 999
                                let rankB = MostWantedManager.shared.rankForCallsign(b.callsign) ?? 999
                                return rankA < rankB
                            }
                        }()
                        
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
        .onChange(of: retryCooldownMinutes) { _, newValue in
            viewModel.retryCooldownMinutes = newValue
        }
        .onChange(of: viewModel.server.decodes) { _, _ in
            // Beim nächsten Decode-Fenster immer auf aktuellen DX-Call zurücksetzen
            tableSelection = nil
            viewModel.selectedCallsign = ""
        }
        .onChange(of: udpPort) { _, newValue in
            viewModel.startServer(port: UInt16(newValue), address: udpAddress)
        }
        .onChange(of: udpAddress) { _, newValue in
            viewModel.startServer(port: UInt16(udpPort), address: newValue)
        }
        .preferredColorScheme(preferredScheme)
        .frame(
            minWidth: 550 + (isLeftSidebarVisible ? 220 : 0) + (isSidebarVisible ? 250 : 0),
            minHeight: 500
        )
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
            if MostWantedManager.shared.isMostWanted(callsign: decode.callsign) {
                Text("🔥")
                    .font(.caption2)
            }
        }
    }
    
    @ViewBuilder
    private func landCell(for decode: WSJTXDecode) -> some View {
        let country = viewModel.matcher.country(for: decode.callsign)
        cellText(country.isEmpty ? "Unbekannt" : country, decode: decode)
    }
    
    @ViewBuilder
    private func mostWantedCell(for decode: WSJTXDecode) -> some View {
        if let rank = MostWantedManager.shared.rankForCallsign(decode.callsign) {
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
    private func hfFreqCell(for decode: WSJTXDecode) -> some View {
        cellText(decode.formattedHfFrequency, decode: decode)
    }
    
    @ViewBuilder
    private func audioFreqCell(for decode: WSJTXDecode) -> some View {
        cellText("\(decode.deltaFrequency)", decode: decode)
    }
    
    @ViewBuilder
    private func messageCell(for decode: WSJTXDecode) -> some View {
        cellText(decode.message, decode: decode)
    }

    private func cellText(_ text: String, decode: WSJTXDecode) -> some View {
        Text(text)
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
    
    private func rowColor(for decode: WSJTXDecode) -> Color {
        let call = decode.callsign
        if call.isEmpty { return .primary }
        
        if viewModel.isAutoQSOInteresting(decode: decode) {
            return .green
        }
        
        if viewModel.lotwManager.hasWorked(callsign: call, band: decode.band) {
            return .red.opacity(0.5)
        }
        
        if !viewModel.shouldAccept(decode: decode) {
            return .gray.opacity(0.6)
        }
        
        let highlightMW = UserDefaults.standard.object(forKey: "highlightMostWanted") as? Bool ?? true
        if highlightMW && MostWantedManager.shared.isMostWanted(callsign: call) {
            return .red
        }
        
        return .primary
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
            return .primary
        }
    }
    
    private func wsjtxLogColor(for type: WSJTXRawLogType) -> Color {
        switch type {
        case .decode:
            return .green
        case .incoming:
            return .blue
        case .outgoing:
            return .orange
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
            Text("DX-Filter")
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
                            TextField("2237", value: $udpPort, format: .number.grouping(.never))
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
                            TextField("z.B. 2238 (0 = Aus)", value: $udpBridgePort, format: .number.grouping(.never))
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
                Picker("", selection: $consoleTab) {
                    Text("System-Logs").tag(0)
                    Text("WSJT-X Rohdaten").tag(1)
                    Text("Cluster-Spots").tag(2)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 320)
                
                if consoleTab == 1 {
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
                
                Spacer()
                
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
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if consoleTab == 0 {
                        let rawLogs = (viewModel.logHistory + viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory).sorted()
                        let logs = isNewestOnTop ? Array(rawLogs.reversed()) : rawLogs
                        if logs.isEmpty {
                            Text("Keine System-Logs vorhanden.")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 11))
                        } else {
                            ForEach(logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(logColor(for: log))
                            }
                        }
                    } else if consoleTab == 1 {
                        let rawWSJTXLogs = viewModel.wsjtxRawLogs.filter { log in
                            switch log.type {
                            case .decode: return wsjtxShowDecodes
                            case .incoming: return wsjtxShowIncoming
                            case .outgoing: return wsjtxShowOutgoing
                            }
                        }
                        let filteredWSJTXLogs = isNewestOnTop ? Array(rawWSJTXLogs.reversed()) : rawWSJTXLogs
                        if filteredWSJTXLogs.isEmpty {
                            Text("Keine WSJT-X Rohdaten für die gewählten Filter.")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 11))
                        } else {
                            ForEach(filteredWSJTXLogs) { log in
                                let ts = formatLogTime(log.timestamp)
                                Text("[\(ts)] [\(log.type.rawValue)] \(log.message)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(wsjtxLogColor(for: log.type))
                            }
                        }
                    } else {
                        let clusterLogs = isNewestOnTop ? Array(viewModel.clusterRawLogs.reversed()) : viewModel.clusterRawLogs
                        if clusterLogs.isEmpty {
                            Text("Keine DX-Cluster Rohdaten vorhanden.")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 11))
                        } else {
                            ForEach(clusterLogs) { log in
                                Text(log.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
        }
    }
}

struct CountryInputField: View {
    @Binding var text: String
    let suggestions: [String]
    let onAdd: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("z.B. Germany", text: $text)
                    .textFieldStyle(UnifiedTextFieldStyle())
                    .controlSize(.small)
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
                .disabled(text.isEmpty)
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
                .padding(.top, 2)
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
