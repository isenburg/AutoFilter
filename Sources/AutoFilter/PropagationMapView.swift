import SwiftUI
import MapKit

struct PropagationMapView: View {
    @Bindable var viewModel: DecodeViewModel
    private var isDe: Bool { LanguageManager.shared.isGerman }

    init(viewModel: DecodeViewModel) {
        self.viewModel = viewModel
    }
    @State private var now = Date()
    @State private var refreshTimer: Timer?
    @State private var sortMode = 0 // 0: Continent, 1: A–Z, 2: Spots
    @State private var showList = true

    @AppStorage("mapTimeWindow") private var mapTimeWindow = 30
    @AppStorage("mapCountWorkedBefore") private var mapCountWorkedBefore = false
    @AppStorage("mapSpotPointSize") private var mapSpotPointSize = 12.0
    @AppStorage("fontSizeTable") private var fontSizeTable = 11.0
    @AppStorage("propagationMapStyle") private var selectedMapStyleRaw: String = MapStyleOption.standard.rawValue

    private var selectedMapStyle: MapStyleOption {
        MapStyleOption(rawValue: selectedMapStyleRaw) ?? .standard
    }

    @State private var displayClusters: [CountryCluster] = []
    @State private var cachedGlobeSpotItems: [GlobeSpotItem] = []
    @State private var showMaidenheadOverlay = false
    @AppStorage("gridOverlayShowPill") private var gridOverlayShowPill = true
    @AppStorage("gridOverlayTextColor") private var gridOverlayTextColor = ""
    @AppStorage("gridOverlayLineColor") private var gridOverlayLineColor = ""
    @AppStorage("gridOverlayBadgeColor") private var gridOverlayBadgeColor = ""
    @AppStorage("gridOverlayFontSize") private var gridOverlayFontSize = 11.0
    @State private var showPropagationChart = false
    @State private var programmaticRegion: MKCoordinateRegion? = nil
    @State private var cameraPosition: MapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.0, longitude: 10.0), span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 40.0)))

    static func centerRegionForQSO(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let greatCircleCoords = Maidenhead.greatCirclePath(from: coord1, to: coord2, steps: 30)
        let midIdx = max(0, greatCircleCoords.count / 2)
        let midCoord = greatCircleCoords.indices.contains(midIdx) ? greatCircleCoords[midIdx] : CLLocationCoordinate2D(
            latitude: (coord1.latitude + coord2.latitude) / 2.0,
            longitude: (coord1.longitude + coord2.longitude) / 2.0
        )
        
        var minLat = min(coord1.latitude, coord2.latitude)
        var maxLat = max(coord1.latitude, coord2.latitude)
        var minLon = min(coord1.longitude, coord2.longitude)
        var maxLon = max(coord1.longitude, coord2.longitude)
        
        for c in greatCircleCoords {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        
        let latDelta = max(abs(maxLat - minLat) * 1.5, 30.0)
        let lonDelta = max(abs(maxLon - minLon) * 1.5, 45.0)
        
        return MKCoordinateRegion(
            center: midCoord,
            span: MKCoordinateSpan(latitudeDelta: min(latDelta, 140.0), longitudeDelta: min(lonDelta, 240.0))
        )
    }

    private func centerOnActiveQSO(_ path: ActiveQSOPath) {
        let qsoRegion = PropagationMapView.centerRegionForQSO(from: path.myCoordinate, to: path.targetCoordinate)
        withAnimation(.easeInOut(duration: 0.8)) {
            programmaticRegion = qsoRegion
            cameraPosition = .region(qsoRegion)
        }
    }

    struct BandLegendInfo: Hashable {
        let name: String
        let color: Color
    }
    
    private let allBands: [BandLegendInfo] = [
        BandLegendInfo(name: "160M", color: Color(red: 0.4, green: 0.4, blue: 0.4)),
        BandLegendInfo(name: "80M", color: Color(red: 0.5, green: 0.0, blue: 0.5)),
        BandLegendInfo(name: "60M", color: Color(red: 0.0, green: 0.3, blue: 0.6)),
        BandLegendInfo(name: "40M", color: .blue),
        BandLegendInfo(name: "30M", color: Color(red: 0.0, green: 0.6, blue: 0.6)),
        BandLegendInfo(name: "20M", color: Color(red: 0.0, green: 0.7, blue: 0.0)),
        BandLegendInfo(name: "17M", color: Color(red: 0.6, green: 0.8, blue: 0.0)),
        BandLegendInfo(name: "15M", color: .orange),
        BandLegendInfo(name: "12M", color: Color(red: 0.9, green: 0.4, blue: 0.0)),
        BandLegendInfo(name: "10M", color: .red),
        BandLegendInfo(name: "6M", color: Color(red: 0.3, green: 0.3, blue: 0.3))
    ]

    private var sortedClusters: [CountryCluster] {
        displayClusters.sorted {
            switch sortMode {
            case 0: // Continent
                if $0.continent == $1.continent { return $0.country < $1.country }
                return $0.continent < $1.continent
            case 1: // A–Z
                return $0.country < $1.country
            default: // Spots (2)
                return $0.spotCount > $1.spotCount
            }
        }
    }

    private var clustersByContinent: [(continent: String, clusters: [CountryCluster])] {
        let grouped = Dictionary(grouping: sortedClusters) { viewModel.continentName(for: $0.continent) }
        return grouped.map { (continent: $0.key, clusters: $0.value) }
            .sorted { a, b in
                if a.continent == "OTHER" { return false }
                if b.continent == "OTHER" { return true }
                return a.continent < b.continent
            }
    }

    private var spotsPerHour: (received: Int, filtered: Int) {
        let elapsed = now.timeIntervalSince(viewModel.counterStartTime)
        let hours = max(elapsed / 3600.0, 1.0 / 60.0)
        return (Int(round(Double(viewModel.mapState.totalReceived) / hours)), Int(round(Double(viewModel.mapState.totalForwarded) / hours)))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main Map Area
            mapSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Sidebar Area
            if showList {
                Divider()
                PropagationSidebarView(
                    clusters: displayClusters,
                    fontSizeTable: fontSizeTable,
                    continentNameProvider: { viewModel.continentName(for: $0) },
                    onClose: { withAnimation { showList = false } }
                )
                .equatable()
                .frame(width: 240)
                .transition(.move(edge: .trailing))
            }
        }
        .frame(minWidth: 840, minHeight: 380)
        .onAppear {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in 
                now = Date() 
            }
            displayClusters = viewModel.mapState.propagationClusters
            viewModel.updatePropagationClusters()
            if let path = viewModel.activeQSOPath {
                centerOnActiveQSO(path)
            }
        }
        .onDisappear {
            refreshTimer?.invalidate(); refreshTimer = nil
        }
        .onChange(of: viewModel.activeQSOPath) { _, newPath in
            if let path = newPath {
                centerOnActiveQSO(path)
            }
        }
        .onChange(of: viewModel.mapState.propagationClusters) { _, newClusters in
            displayClusters = newClusters
            cachedGlobeSpotItems = newClusters.map { cluster in
                let band = cluster.bands.first?.name ?? ""
                let sub = cluster.bands.map { "\($0.name):\($0.count)" }.joined(separator: " ")
                return GlobeSpotItem(
                    id: cluster.country,
                    title: cluster.country,
                    subtitle: "\(cluster.spotCount) Spots (\(sub))",
                    latitude: cluster.latitude,
                    longitude: cluster.longitude,
                    bandName: band
                )
            }
        }
    }

    private func geodesicCoordinates(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        return Maidenhead.greatCirclePath(from: from, to: to, steps: 60)
    }

    @ViewBuilder
    private func renderMapView() -> some View {
        GlobeMapViewContainer(
            programmaticRegion: programmaticRegion,
            showGridOverlay: showMaidenheadOverlay,
            showBadges: gridOverlayShowPill,
            gridTextColor: gridOverlayTextColor,
            gridLineColor: gridOverlayLineColor,
            gridBadgeColor: gridOverlayBadgeColor,
            gridFontSize: gridOverlayFontSize,
            spotPointSize: mapSpotPointSize,
            spotItems: cachedGlobeSpotItems,
            activeQSOPath: viewModel.activeQSOPath,
            mapStyle: selectedMapStyle
        )
    }

    private var mapSection: some View {
        ZStack(alignment: .bottom) {
            renderMapView()
                .overlay(alignment: .top) {
                    if let path = viewModel.activeQSOPath {
                        Button(action: {
                            centerOnActiveQSO(path)
                        }) {
                            HStack(spacing: 8) {
                                Circle().fill(Color.orange).frame(width: 8, height: 8)
                                Text(isDe ? "⚡ AKTIVES QSO:" : "⚡ ACTIVE QSO:").font(.caption).bold().foregroundStyle(.orange)
                                let locLabel = path.targetGrid ?? path.targetCountry ?? ""
                                Text("\(path.myGrid) ➔ \(path.targetCall)\(!locLabel.isEmpty ? " (\(locLabel))" : "")")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                if let dist = path.distanceKm {
                                    Text("·  \(Int(round(dist))) km")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "scope")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.orange.opacity(0.6), lineWidth: 1))
                            .shadow(color: .orange.opacity(0.3), radius: 6)
                            .padding(.top, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isDe ? "\(displayClusters.count) Länder" : "\(displayClusters.count) Countries").font(.caption).bold().lineLimit(1)
                            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                            
                            Stepper(value: $mapTimeWindow, in: 5...120, step: 5) {
                                Text(isDe ? "Fenster: \(mapTimeWindow) Min." : "Window: \(mapTimeWindow) min.").font(.caption2).lineLimit(1)
                            }
                            .onChange(of: mapTimeWindow) { _, _ in
                                viewModel.updatePropagationClusters()
                            }
                            
                            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                            
                            Toggle(isDe ? "Gearbeitete mitzählen" : "Include worked", isOn: $mapCountWorkedBefore)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .toggleStyle(.checkbox)
                                .controlSize(.small)
                                .onChange(of: mapCountWorkedBefore) { _, _ in
                                    viewModel.updatePropagationClusters()
                                }
                            
                            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)

                            Stepper(value: $mapSpotPointSize, in: 6...24, step: 1) {
                                Text(isDe ? "Punktgröße: \(Int(mapSpotPointSize)) pt" : "Dot size: \(Int(mapSpotPointSize)) pt").font(.caption2).lineLimit(1)
                            }
                            
                            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                            
                            StatRow(label: isDe ? "Empf." : "Recv.", value: "\(viewModel.mapState.totalReceived)", rate: "\(spotsPerHour.received)/h")
                            StatRow(label: isDe ? "Durchg." : "Pass", value: "\(viewModel.mapState.totalForwarded)", rate: "\(spotsPerHour.filtered)/h", color: .green)
                        }
                        .fixedSize()
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                        if showPropagationChart {
                            PropagationChartView(viewModel: viewModel)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(8)
                }
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 6) {
                        Menu {
                            ForEach(MapStyleOption.allCases) { style in
                                Button(action: {
                                    selectedMapStyleRaw = style.rawValue
                                }) {
                                    HStack {
                                        Text(style.title)
                                        if selectedMapStyleRaw == style.rawValue {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedMapStyle.title)
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5.5)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        }
                        .menuStyle(.borderlessButton)
                        .help(isDe ? "Kartenstil auswählen" : "Select map style")

                        Button(action: {
                            withAnimation {
                                showPropagationChart.toggle()
                            }
                        }) {
                            Image(systemName: showPropagationChart ? "chart.bar.fill" : "chart.bar.xaxis")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                .foregroundStyle(showPropagationChart ? .orange : .primary)
                        }
                        .buttonStyle(.plain)
                        .help(isDe ? "Ausbreitungsdiagramm ein/ausblenden" : "Toggle propagation chart")

                        Button(action: {
                            withAnimation {
                                showMaidenheadOverlay.toggle()
                            }
                        }) {
                            Image(systemName: showMaidenheadOverlay ? "grid.circle.fill" : "grid.circle")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                .foregroundStyle(showMaidenheadOverlay ? .blue : .primary)
                        }
                        .buttonStyle(.plain)
                        .help(isDe ? "Maidenhead Grid-Gitter ein/ausblenden (bis 8-Stellen Resolution)" : "Toggle Maidenhead grid overlay (up to 8-digit resolution)")

                        if !showList {
                            Button(action: { withAnimation { showList = true } }) {
                                Image(systemName: "sidebar.trailing")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .help(isDe ? "Liste einblenden" : "Show sidebar")
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .padding(8)
                }

                VStack(spacing: 6) {
                    if showMaidenheadOverlay {
                        GridOverlaySettingsBar()
                    }

                    HStack(spacing: 10) {
                        ForEach(allBands, id: \.name) { band in
                            HStack(spacing: 4) {
                                Circle().fill(band.color).frame(width: max(6, min(14, mapSpotPointSize * 0.7)), height: max(6, min(14, mapSpotPointSize * 0.7)))
                                Text(band.name).font(.system(size: 9, weight: .medium))
                            }
                        }

                        Divider().frame(height: 12)

                        HStack(spacing: 4) {
                            Button(action: { if mapSpotPointSize > 6 { mapSpotPointSize -= 1 } }) {
                                Image(systemName: "minus.circle").font(.system(size: 10, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .help(isDe ? "Band-Punktgröße verkleinern" : "Decrease spot dot size")

                            Text("● \(Int(mapSpotPointSize))pt")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))

                            Button(action: { if mapSpotPointSize < 24 { mapSpotPointSize += 1 } }) {
                                Image(systemName: "plus.circle").font(.system(size: 10, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .help(isDe ? "Band-Punktgröße vergrößern" : "Increase spot dot size")
                        }
                    }
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 1)
                }
                .padding(.bottom, 24)
            }
        }
}

private struct PropagationSidebarView: View, Equatable {
    let clusters: [CountryCluster]
    let fontSizeTable: Double
    let continentNameProvider: (String) -> String
    let onClose: () -> Void

    private var isDe: Bool { LanguageManager.shared.isGerman }

    @State private var sortMode = 0 // 0: Continent, 1: A–Z, 2: Spots
    @State private var collapsedContinents: Set<String> = []

    static func == (lhs: PropagationSidebarView, rhs: PropagationSidebarView) -> Bool {
        return lhs.clusters == rhs.clusters && lhs.fontSizeTable == rhs.fontSizeTable
    }

    private var sortedClusters: [CountryCluster] {
        clusters.sorted {
            switch sortMode {
            case 0:
                if $0.continent == $1.continent { return $0.country < $1.country }
                return $0.continent < $1.continent
            case 1:
                return $0.country < $1.country
            default:
                return $0.spotCount > $1.spotCount
            }
        }
    }

    private var clustersByContinent: [(continent: String, clusters: [CountryCluster])] {
        let grouped = Dictionary(grouping: sortedClusters) { continentNameProvider($0.continent) }
        return grouped.map { (continent: $0.key, clusters: $0.value) }
            .sorted { a, b in
                let otherDe = "ANDERE"
                let otherEn = "OTHER"
                if a.continent == otherDe || a.continent == otherEn { return false }
                if b.continent == otherDe || b.continent == otherEn { return true }
                return a.continent < b.continent
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isDe ? "Aktive Länder" : "Active Countries").font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "sidebar.trailing")
                }
                .buttonStyle(.plain)
                .help(isDe ? "Liste ausblenden" : "Hide sidebar")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            Picker(isDe ? "Sortierung" : "Sort", selection: $sortMode) {
                Label(isDe ? "Kontinent" : "Continent", systemImage: "globe.americas").tag(0)
                Label("A–Z", systemImage: "textformat.abc").tag(1)
                Label("Spots", systemImage: "number").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            
            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)

            if clusters.isEmpty {
                Spacer()
                Text(isDe ? "Noch keine Spots" : "No spots yet").foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    if sortMode == 0 {
                        ForEach(clustersByContinent, id: \.continent) { group in
                            let isExpanded = !collapsedContinents.contains(group.continent)
                            Section(header: 
                                Button(action: {
                                    if isExpanded {
                                        collapsedContinents.insert(group.continent)
                                    } else {
                                        collapsedContinents.remove(group.continent)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(group.continent)
                                            .font(.system(size: CGFloat(fontSizeTable), weight: .black))
                                            .foregroundStyle(.primary.opacity(0.7))
                                        Spacer()
                                        Text("\(group.clusters.count)").font(.system(size: CGFloat(max(8, fontSizeTable - 2)))).foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(continentColor(for: group.continent))
                                    .clipShape(.rect(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, -4)
                            ) {
                                if isExpanded {
                                    ForEach(group.clusters) { cluster in
                                        CountryListRow(cluster: cluster, fontSize: fontSizeTable)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(sortedClusters) { cluster in
                            CountryListRow(cluster: cluster, fontSize: fontSizeTable)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func continentColor(for continent: String) -> Color {
        switch continent {
        case "EUROPE": return Color.blue.opacity(0.2)
        case "NORTH AMERICA": return Color.red.opacity(0.2)
        case "ASIA": return Color.orange.opacity(0.2)
        case "SOUTH AMERICA": return Color.yellow.opacity(0.2)
        case "AFRICA": return Color.green.opacity(0.2)
        case "OCEANIA": return Color.purple.opacity(0.2)
        case "ANTARCTICA": return Color.cyan.opacity(0.2)
        default: return Color.gray.opacity(0.2)
        }
    }
}

func colorForBandName(_ name: String) -> Color {
    switch name.uppercased() {
    case "160M": return Color(red: 0.4, green: 0.4, blue: 0.4)
    case "80M": return Color(red: 0.5, green: 0.0, blue: 0.5)
    case "60M": return Color(red: 0.0, green: 0.3, blue: 0.6)
    case "40M": return .blue
    case "30M": return Color(red: 0.0, green: 0.6, blue: 0.6)
    case "20M": return Color(red: 0.0, green: 0.7, blue: 0.0)
    case "17M": return Color(red: 0.6, green: 0.8, blue: 0.0)
    case "15M": return .orange
    case "12M": return Color(red: 0.9, green: 0.4, blue: 0.0)
    case "10M": return .red
    case "6M": return Color(red: 0.3, green: 0.3, blue: 0.3)
    default: return .gray
    }
}

private struct CountryMarkerView: View, Equatable {
    let cluster: CountryCluster
    let fontSize: Double

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                ForEach(cluster.bands, id: \.name) { band in
                    Text("\(band.name):\(band.count)")
                        .font(.system(size: CGFloat(max(6, fontSize - 3)), weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(colorForBandName(band.name), in: RoundedRectangle(cornerRadius: 3))
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
    }
}

private struct CountryListRow: View, Equatable {
    let cluster: CountryCluster
    let fontSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cluster.country)
                    .font(.system(size: CGFloat(fontSize), weight: .bold))
                Spacer()
                Text("\(cluster.spotCount)")
                    .font(.system(size: CGFloat(max(8, fontSize - 2))))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(cluster.bands, id: \.name) { band in
                    let bColor = colorForBandName(band.name)
                    Text("\(band.name) (\(band.count))")
                        .font(.system(size: CGFloat(max(6, fontSize - 3)), weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(bColor.opacity(0.2))
                        .foregroundStyle(bColor)
                        .clipShape(.rect(cornerRadius: 3))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let rate: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label + ":").font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1).frame(width: 52, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
            Spacer()
            Text(rate).font(.system(size: 9)).lineLimit(1).foregroundStyle(.secondary)
        }
    }
}
