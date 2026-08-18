import SwiftUI
import MapKit

struct PropagationMapView: View {
    @ObservedObject var viewModel: DecodeViewModel
    @State private var now = Date()
    @State private var refreshTimer: Timer?
    @State private var sortMode = 0 // 0: Continent, 1: A–Z, 2: Spots
    @State private var showList = true
    @State private var expandedContinents: Set<String> = ["EUROPE", "NORTH AMERICA", "ASIA", "SOUTH AMERICA", "AFRICA", "OCEANIA", "ANTARCTICA", "OTHER"]

    @AppStorage("mapTimeWindow") private var mapTimeWindow = 30
    @AppStorage("mapCountWorkedBefore") private var mapCountWorkedBefore = false
    @AppStorage("fontSizeTable") private var fontSizeTable = 11.0
    @AppStorage("propagationMapStyle") private var selectedMapStyleRaw: String = MapStyleOption.standard.rawValue

    private var selectedMapStyle: MapStyleOption {
        MapStyleOption(rawValue: selectedMapStyleRaw) ?? .standard
    }

    @State private var displayClusters: [CountryCluster] = []
    @State private var cachedGlobeSpotItems: [GlobeSpotItem] = []
    @State private var showMaidenheadOverlay = false
    @State private var showPropagationChart = false
    @State private var currentRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.0, longitude: 10.0), span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 40.0))

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
        return (Int(round(Double(viewModel.totalReceived) / hours)), Int(round(Double(viewModel.totalForwarded) / hours)))
    }

    var body: some View {
        HSplitView {
            // Main Map Area
            mapSection
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

            // Sidebar Area
            if showList {
                sidebarSection
                    .frame(minWidth: 200, idealWidth: 260, maxWidth: 320)
                    .transition(.move(edge: .trailing))
            } else {
                Color.clear.frame(width: 0.1)
            }
        }
        .onAppear {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in 
                now = Date() 
            }
            displayClusters = viewModel.propagationClusters
            viewModel.updatePropagationClusters()
        }
        .onDisappear {
            refreshTimer?.invalidate(); refreshTimer = nil
        }
        .onChange(of: viewModel.propagationClusters) { _, newClusters in
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
    private func renderMapView(proxy: MapProxy) -> some View {
        if selectedMapStyle == .globus {
            GlobeMapViewContainer(
                region: $currentRegion,
                showGridOverlay: showMaidenheadOverlay,
                spotItems: cachedGlobeSpotItems,
                activeQSOPath: viewModel.activeQSOPath
            )
            .id("propagation-globe-map-instance")
        } else {
            Map {
                let topCount = min(displayClusters.count, 20)
                let detailClusters = displayClusters.prefix(topCount)
                let backgroundClusters = displayClusters.dropFirst(topCount)

                ForEach(detailClusters) { cluster in
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: cluster.latitude,
                        longitude: cluster.longitude
                    )) {
                        CountryMarkerView(cluster: cluster, fontSize: fontSizeTable)
                            .drawingGroup()
                    }
                }

                ForEach(backgroundClusters) { cluster in
                    Marker(cluster.country, coordinate: CLLocationCoordinate2D(
                        latitude: cluster.latitude,
                        longitude: cluster.longitude
                    ))
                    .tint(colorForBandName(cluster.bands.first?.name ?? ""))
                }

                if let path = viewModel.activeQSOPath {
                    let pathCoords = geodesicCoordinates(from: path.myCoordinate, to: path.targetCoordinate)
                    MapPolyline(coordinates: pathCoords)
                        .stroke(.yellow, lineWidth: 3.5)

                    Annotation("", coordinate: path.myCoordinate) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.green, in: Circle())
                            .shadow(color: .black.opacity(0.4), radius: 3)
                    }

                    Annotation("", coordinate: path.targetCoordinate) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(.yellow)
                            Text("\(path.targetCall)\(path.targetGrid != nil ? " (\(path.targetGrid!))" : "")")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.9), in: Capsule())
                        .overlay(Capsule().stroke(Color.yellow, lineWidth: 1.5))
                        .shadow(color: .orange.opacity(0.6), radius: 6)
                    }
                }
            }
            .id("propagation-map-instance")
            .mapStyle(selectedMapStyle.mapStyle)
            .onMapCameraChange { context in
                currentRegion = context.region
            }
        }
    }

    private var mapSection: some View {
        MapReader { proxy in
            ZStack(alignment: .bottom) {
                renderMapView(proxy: proxy)
                .overlay {
                    if showMaidenheadOverlay && selectedMapStyle != .globus {
                        MaidenheadGridCanvasView(proxy: proxy, region: currentRegion)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(alignment: .top) {
                    if let path = viewModel.activeQSOPath {
                        HStack(spacing: 8) {
                            Circle().fill(Color.orange).frame(width: 8, height: 8)
                            Text("⚡ AKTIVES QSO:").font(.caption).bold().foregroundColor(.orange)
                            Text("\(path.myGrid) ➔ \(path.targetCall)\(path.targetGrid != nil ? " (\(path.targetGrid!))" : "")")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                            if let dist = path.distanceKm {
                                Text("·  \(Int(round(dist))) km")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.orange.opacity(0.6), lineWidth: 1))
                        .shadow(color: .orange.opacity(0.3), radius: 6)
                        .padding(.top, 8)
                    }
                }
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(displayClusters.count) Länder").font(.caption).bold().lineLimit(1)
                            Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                            
                            Stepper(value: $mapTimeWindow, in: 5...120, step: 5) {
                                Text("Fenster: \(mapTimeWindow) Min.").font(.caption2).lineLimit(1)
                            }
                            .onChange(of: mapTimeWindow) { _, _ in
                                viewModel.updatePropagationClusters()
                            }
                            
                            Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                            
                            Toggle("Gearbeitete mitzählen", isOn: $mapCountWorkedBefore)
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .toggleStyle(.checkbox)
                                .controlSize(.small)
                                .onChange(of: mapCountWorkedBefore) { _, _ in
                                    viewModel.updatePropagationClusters()
                                }
                            
                            Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                            
                            StatRow(label: "Empf.", value: "\(viewModel.totalReceived)", rate: "\(spotsPerHour.received)/h")
                            StatRow(label: "Durchg.", value: "\(viewModel.totalForwarded)", rate: "\(spotsPerHour.filtered)/h", color: .green)
                        }
                        .fixedSize()
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

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
                                        Text(style.rawValue)
                                        if selectedMapStyleRaw == style.rawValue {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(MapStyleOption(rawValue: selectedMapStyleRaw)?.rawValue ?? "Standard")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5.5)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .menuStyle(.borderlessButton)
                        .help("Kartenstil auswählen")

                        Button(action: {
                            withAnimation {
                                showPropagationChart.toggle()
                            }
                        }) {
                            Image(systemName: showPropagationChart ? "chart.bar.fill" : "chart.bar.xaxis")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                .foregroundColor(showPropagationChart ? .orange : .primary)
                        }
                        .buttonStyle(.plain)
                        .help("Ausbreitungsdiagramm (Propagation Chart) ein/ausblenden")

                        Button(action: {
                            withAnimation {
                                showMaidenheadOverlay.toggle()
                            }
                        }) {
                            Image(systemName: showMaidenheadOverlay ? "grid.circle.fill" : "grid.circle")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                                .foregroundColor(showMaidenheadOverlay ? .blue : .primary)
                        }
                        .buttonStyle(.plain)
                        .help("Maidenhead Grid-Gitter ein/ausblenden (bis 8-Stellen Resolution)")

                        if !showList {
                            Button(action: { withAnimation { showList = true } }) {
                                Image(systemName: "sidebar.trailing")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .help("Liste einblenden")
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(8)
                }

                VStack(spacing: 6) {
                    if showMaidenheadOverlay {
                        GridOverlaySettingsBar()
                    }

                    HStack(spacing: 10) {
                        ForEach(allBands, id: \.name) { band in
                            HStack(spacing: 4) {
                                Circle().fill(band.color).frame(width: 8, height: 8)
                                Text(band.name).font(.system(size: 9, weight: .medium))
                            }
                        }
                    }
                    .padding(6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.bottom, 24)
            }
        }
    }

    private var sidebarSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Aktive Länder").font(.headline)
                Spacer()
                Button(action: { withAnimation { showList = false } }) {
                    Image(systemName: "sidebar.trailing")
                }
                .buttonStyle(.plain)
                .help("Liste ausblenden")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            Picker("Sortierung", selection: $sortMode) {
                Label("Kontinent", systemImage: "globe.americas").tag(0)
                Label("A–Z", systemImage: "textformat.abc").tag(1)
                Label("Spots", systemImage: "number").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            
            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)

            if displayClusters.isEmpty {
                Spacer()
                Text("Noch keine Spots").foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    if sortMode == 0 {
                        ForEach(clustersByContinent, id: \.continent) { group in
                            let isExpanded = expandedContinents.contains(group.continent)
                            Section(header: 
                                Button(action: {
                                    if isExpanded {
                                        expandedContinents.remove(group.continent)
                                    } else {
                                        expandedContinents.insert(group.continent)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(group.continent)
                                            .font(.system(size: CGFloat(fontSizeTable), weight: .black))
                                            .foregroundColor(.primary.opacity(0.7))
                                        Spacer()
                                        Text("\(group.clusters.count)").font(.system(size: CGFloat(max(8, fontSizeTable - 2)))).foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(continentColor(for: group.continent))
                                    .cornerRadius(4)
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
                        .foregroundColor(.white)
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
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 4) {
                ForEach(cluster.bands, id: \.name) { band in
                    let bColor = colorForBandName(band.name)
                    Text("\(band.name) (\(band.count))")
                        .font(.system(size: CGFloat(max(6, fontSize - 3)), weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(bColor.opacity(0.2))
                        .foregroundColor(bColor)
                        .cornerRadius(3)
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
            Text(label + ":").font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1).frame(width: 52, alignment: .leading)
            Text(value).font(.system(size: 10, weight: .bold)).foregroundColor(color)
            Spacer()
            Text(rate).font(.system(size: 9)).lineLimit(1).foregroundColor(.secondary)
        }
    }
}
