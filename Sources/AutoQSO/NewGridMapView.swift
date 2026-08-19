import SwiftUI
import MapKit
import Network

struct NewGridMapView: View {
    @ObservedObject var viewModel: DecodeViewModel
    @State private var now = Date()
    @State private var refreshTimer: Timer?
    @State private var sortMode = 0 // 0: Grid (A-Z), 1: Spots, 2: Kontinent
    @State private var showList = true
    @State private var searchText = ""
    @State private var collapsedContinents: Set<String> = []
    @State private var cameraPosition: MapCameraPosition = .automatic

    @State private var showMaidenheadOverlay = true
    @State private var currentRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.0, longitude: 10.0), span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 40.0))

    @AppStorage("mapTimeWindow") private var mapTimeWindow = 30
    @AppStorage("fontSizeTable") private var fontSizeTable = 11.0
    @AppStorage("showBlockedGridSpots") private var showBlockedGridSpots = true
    @AppStorage("showWorkedGridShading") private var showWorkedGridShading = false
    @AppStorage("newGridMapStyle") private var selectedMapStyleRaw: String = MapStyleOption.standard.rawValue
    @AppStorage("myGridLocator") private var myGridLocator = "JO31"
    @AppStorage("newGridSidebarCompact") private var isCompactMode = false

    private var selectedMapStyle: MapStyleOption {
        MapStyleOption(rawValue: selectedMapStyleRaw) ?? .standard
    }

    private var homeCoordinate: CLLocationCoordinate2D? {
        if let coord = Maidenhead.locatorToLatLon(myGridLocator) {
            return CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lon)
        }
        return nil
    }

    private let availableBands = ["ALL", "160M", "80M", "60M", "40M", "30M", "20M", "17M", "15M", "12M", "10M", "6M"]
    @State private var selectedBand = "ALL"
    @State private var displayGridClusters: [NewGridCluster] = []

    private var bandFilteredClusters: [NewGridCluster] {
        if selectedBand == "ALL" {
            return displayGridClusters
        }
        return displayGridClusters.filter { cluster in
            cluster.bands.contains(where: { $0.name.uppercased() == selectedBand.uppercased() })
        }
    }

    var body: some View {
        HSplitView {
            // Main Map Area
            mapSection
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

            // Sidebar Area
            if showList {
                NewGridSidebarView(
                    clusters: bandFilteredClusters,
                    fontSizeTable: fontSizeTable,
                    homeCoordinate: homeCoordinate,
                    isCompactMode: $isCompactMode,
                    continentNameProvider: { viewModel.continentName(for: $0) },
                    onSelectCluster: { cluster in
                        centerOnCluster(cluster)
                    },
                    onClose: { withAnimation { showList = false } }
                )
                .equatable()
                .frame(minWidth: 220, idealWidth: 280, maxWidth: 350)
                .transition(.move(edge: .trailing))
            } else {
                Color.clear.frame(width: 0.1)
            }
        }
        .onAppear {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                now = Date()
            }
            displayGridClusters = viewModel.newGridClusters
            viewModel.updatePropagationClusters()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
        .onChange(of: viewModel.newGridClusters) { _, newClusters in
            displayGridClusters = newClusters
            cachedGlobeSpotItems = newClusters.map { cluster in
                let band = cluster.bands.first?.name ?? ""
                let sub = cluster.bands.map { "\($0.name):\($0.count)" }.joined(separator: " ")
                return GlobeSpotItem(
                    id: cluster.grid,
                    title: cluster.grid,
                    subtitle: "\(cluster.country) (\(sub))",
                    latitude: cluster.upperRightLatitude,
                    longitude: cluster.upperRightLongitude,
                    bandName: band
                )
            }
        }
        .sheet(item: Binding(
            get: { selectedWorkedGrid.map { WorkedGridItem(grid: $0) } },
            set: { selectedWorkedGrid = $0?.grid }
        )) { item in
            WorkedGridDetailView(
                grid: item.grid,
                qsos: viewModel.lotwManager.logbook.filter {
                    $0.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix(item.grid)
                }
            )
        }
    }

    @State private var selectedWorkedGrid: String? = nil
    @State private var inspectedGrid: GridInspectorInfo? = nil
    @State private var cachedGlobeSpotItems: [GlobeSpotItem] = []

    private struct WorkedGridItem: Identifiable {
        let grid: String
        var id: String { grid }
    }

    private func inspectCoordinate(_ coord: CLLocationCoordinate2D) {
        let span = currentRegion.span.latitudeDelta
        let length = span < 3.0 ? 6 : 4
        let grid = Maidenhead.latLonToLocator(lat: coord.latitude, lon: coord.longitude, length: length)
        let grid4 = String(grid.prefix(4))
        
        let center = Maidenhead.locatorToLatLon(grid)
        let gridCenterCoord = center.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) } ?? coord
        
        let matchingQSOs = viewModel.lotwManager.logbook.filter {
            $0.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix(grid4)
        }
        
        let activeCluster = displayGridClusters.first(where: {
            $0.grid == grid || $0.grid == grid4
        })
        
        var country = activeCluster?.country ?? ""
        var continent = activeCluster?.continent ?? ""
        
        if country.isEmpty || country == "DX", let firstCall = matchingQSOs.first?.callsign, !firstCall.isEmpty {
            let matchedCountry = PrefixMatcher.shared.country(for: firstCall)
            if matchedCountry != "OTHER" && !matchedCountry.isEmpty {
                country = matchedCountry
            }
            let matchedContinent = PrefixMatcher.shared.continent(for: firstCall)
            if matchedContinent != "OTHER" && !matchedContinent.isEmpty {
                continent = matchedContinent
            }
        }
        
        if country.isEmpty {
            if let dxccId = matchingQSOs.first?.dxcc, !dxccId.isEmpty {
                country = "DXCC \(dxccId)"
            } else {
                country = "DX"
            }
        }
        
        inspectedGrid = GridInspectorInfo(
            grid: grid,
            coordinate: gridCenterCoord,
            is6Char: length == 6,
            country: country,
            continent: continent,
            isWorked: !matchingQSOs.isEmpty,
            workedCount: matchingQSOs.count,
            activeCluster: activeCluster
        )
    }

    private func inspectCluster(_ cluster: NewGridCluster) {
        let coord = CLLocationCoordinate2D(latitude: cluster.latitude, longitude: cluster.longitude)
        let grid4 = String(cluster.grid.prefix(4))
        let matchingQSOs = viewModel.lotwManager.logbook.filter {
            $0.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix(grid4)
        }
        inspectedGrid = GridInspectorInfo(
            grid: cluster.grid,
            coordinate: coord,
            is6Char: cluster.is6Char,
            country: cluster.country,
            continent: cluster.continent,
            isWorked: !matchingQSOs.isEmpty,
            workedCount: matchingQSOs.count,
            activeCluster: cluster
        )
    }

    private func openQRZ(for callsign: String) {
        let cleanCall = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCall.isEmpty else { return }
        
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetCheckQueue")
        monitor.pathUpdateHandler = { path in
            monitor.cancel()
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if let url = URL(string: "https://www.qrz.com/db/\(cleanCall)") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }

    @ViewBuilder
    private func renderMapView(proxy: MapProxy) -> some View {
        if selectedMapStyle == .globus {
            GlobeMapViewContainer(
                region: $currentRegion,
                showGridOverlay: showMaidenheadOverlay,
                workedGrids: viewModel.worked4CharGrids,
                showWorkedGridShading: showWorkedGridShading,
                spotItems: cachedGlobeSpotItems,
                onSelectGrid: { grid4 in
                    let matching = viewModel.lotwManager.logbook.filter {
                        $0.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix(grid4)
                    }
                    if !matching.isEmpty {
                        selectedWorkedGrid = grid4
                    }
                }
            )
            .id("new-grid-globe-map-instance")
        } else {
            Map(position: $cameraPosition) {
                ForEach(bandFilteredClusters) { cluster in
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: cluster.upperRightLatitude,
                        longitude: cluster.upperRightLongitude
                    )) {
                        GridMarkerView(cluster: cluster)
                            .drawingGroup()
                            .onTapGesture {
                                inspectCluster(cluster)
                            }
                    }
                }
                
                if let info = inspectedGrid {
                    Annotation("", coordinate: info.coordinate) {
                        Circle()
                            .fill(Color.yellow.opacity(0.15))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.yellow, lineWidth: 2)
                            )
                            .popover(isPresented: Binding(
                                get: { inspectedGrid != nil },
                                set: { if !$0 { inspectedGrid = nil } }
                            )) {
                                GridDetailInspectorPopover(
                                    info: info,
                                    homeCoordinate: homeCoordinate,
                                    onShowWorkedQSOs: {
                                        selectedWorkedGrid = String(info.grid.prefix(4))
                                    },
                                    onCenterMap: {
                                        withAnimation {
                                            cameraPosition = .region(MKCoordinateRegion(
                                                center: info.coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: info.is6Char ? 1.5 : 5.0, longitudeDelta: info.is6Char ? 1.5 : 5.0)
                                            ))
                                        }
                                    },
                                    onOpenQRZ: { call in
                                        openQRZ(for: call)
                                    }
                                )
                            }
                    }
                }
            }
            .id("new-grid-map-instance")
            .mapStyle(selectedMapStyle.mapStyle)
            .onMapCameraChange { context in
                currentRegion = context.region
            }
            .onTapGesture { position in
                if let coord = proxy.convert(position, from: .local) {
                    inspectCoordinate(coord)
                }
            }
        }
    }

    private var mapSection: some View {
        MapReader { proxy in
            ZStack(alignment: .bottom) {
                renderMapView(proxy: proxy)
                .overlay {
                    if showMaidenheadOverlay && selectedMapStyle != .globus {
                        MaidenheadGridCanvasView(
                            proxy: proxy,
                            region: currentRegion,
                            workedGrids: showWorkedGridShading ? viewModel.worked4CharGrids : []
                        )
                        .allowsHitTesting(false)
                    }
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
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        }
                        .menuStyle(.borderlessButton)
                        .help("Kartenstil auswählen")

                        Button(action: {
                            withAnimation {
                                showWorkedGridShading.toggle()
                            }
                        }) {
                            Image(systemName: showWorkedGridShading ? "checkmark.square.fill" : "checkmark.square")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                .foregroundColor(showWorkedGridShading ? .green : .primary)
                        }
                        .buttonStyle(.plain)
                        .help("Gearbeitete 4-Stellen Grid-Felder (aus Logbuch) einfärben")

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
                                .foregroundColor(showMaidenheadOverlay ? .blue : .primary)
                        }
                        .buttonStyle(.plain)
                        .help("Maidenhead Grid-Gitter ein/ausblenden (bis 8-Stellen Resolution)")

                        if !showList {
                            Button(action: { withAnimation { showList = true } }) {
                                Image(systemName: "sidebar.trailing")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(6)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .help("Liste einblenden")
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .padding(8)
                }
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.3x3.topleft.filled")
                                .foregroundColor(.green)
                            Text("Neue Maidenhead Grids").font(.caption).bold()
                        }
                        
                        let count4 = bandFilteredClusters.filter { !$0.is6Char }.count
                        let count6 = bandFilteredClusters.filter { $0.is6Char }.count
                        
                        Text("\(bandFilteredClusters.count) ungearbeitete Grids\(selectedBand == "ALL" ? "" : " (\(selectedBand))")")
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        
                        if count4 > 0 || count6 > 0 {
                            Text("4-Stellen: \(count4)  ·  6-Stellen: \(count6)")
                                .font(.system(size: 9))
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                        
                        if showMaidenheadOverlay {
                            Text("Grid Overlay: \(MaidenheadGridGenerator.resolutionText(for: currentRegion.span.latitudeDelta))")
                                .font(.system(size: 9, weight: .bold))
                                .lineLimit(1)
                                .foregroundColor(.cyan)
                        }
                        
                        Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                        
                        Stepper(value: $mapTimeWindow, in: 5...120, step: 5) {
                            Text("Zeitfenster: \(mapTimeWindow) Min.").font(.caption2).lineLimit(1)
                        }
                        .onChange(of: mapTimeWindow) { _, _ in
                            viewModel.updatePropagationClusters()
                        }
                    }
                    .fixedSize()
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .padding(8)
                }

                VStack(spacing: 6) {
                    // Band Quick-Filter Pill Bar
                    HStack(spacing: 4) {
                        ForEach(availableBands, id: \.self) { band in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedBand = band
                                }
                            }) {
                                Text(band)
                                    .font(.system(size: 9.5, weight: selectedBand == band ? .bold : .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        selectedBand == band
                                        ? (band == "ALL" ? Color.blue : colorForBandName(band))
                                        : Color.clear,
                                        in: Capsule()
                                    )
                                    .foregroundColor(selectedBand == band ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.1), radius: 3, y: 1)

                    if showMaidenheadOverlay {
                        GridOverlaySettingsBar()
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    private func centerOnCluster(_ cluster: NewGridCluster) {
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: cluster.latitude, longitude: cluster.longitude),
                span: MKCoordinateSpan(latitudeDelta: cluster.is6Char ? 2.0 : 8.0, longitudeDelta: cluster.is6Char ? 2.0 : 8.0)
            ))
        }
    }
}

private struct NewGridSidebarView: View, Equatable {
    let clusters: [NewGridCluster]
    let fontSizeTable: Double
    let homeCoordinate: CLLocationCoordinate2D?
    @Binding var isCompactMode: Bool
    let continentNameProvider: (String) -> String
    let onSelectCluster: (NewGridCluster) -> Void
    let onClose: () -> Void

    @State private var searchText = ""
    @State private var sortMode = 0 // 0: Grid (A-Z), 1: Spots, 2: Kontinent
    @State private var collapsedContinents: Set<String> = []

    static func == (lhs: NewGridSidebarView, rhs: NewGridSidebarView) -> Bool {
        return lhs.clusters == rhs.clusters &&
               lhs.fontSizeTable == rhs.fontSizeTable &&
               lhs.homeCoordinate?.latitude == rhs.homeCoordinate?.latitude &&
               lhs.homeCoordinate?.longitude == rhs.homeCoordinate?.longitude &&
               lhs.isCompactMode == rhs.isCompactMode
    }

    private var filteredClusters: [NewGridCluster] {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanQuery.isEmpty {
            return clusters
        }
        return clusters.filter { cluster in
            cluster.grid.contains(cleanQuery) ||
            cluster.country.uppercased().contains(cleanQuery) ||
            cluster.calls.contains(where: { $0.contains(cleanQuery) })
        }
    }

    private var sortedClusters: [NewGridCluster] {
        filteredClusters.sorted {
            switch sortMode {
            case 0: // A-Z by Grid
                return $0.grid < $1.grid
            case 1: // Spots count
                return $0.spotCount > $1.spotCount
            default: // Kontinent
                if $0.continent == $1.continent { return $0.grid < $1.grid }
                return $0.continent < $1.continent
            }
        }
    }

    private var clustersByContinent: [(continent: String, clusters: [NewGridCluster])] {
        let grouped = Dictionary(grouping: sortedClusters) { continentNameProvider($0.continent) }
        return grouped.map { (continent: $0.key, clusters: $0.value) }
            .sorted { a, b in
                if a.continent == "OTHER" { return false }
                if b.continent == "OTHER" { return true }
                return a.continent < b.continent
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text("Neue Grids (\(clusters.count))").font(.headline)
                }
                Spacer()

                Button(action: { isCompactMode.toggle() }) {
                    Image(systemName: isCompactMode ? "rectangle.grid.1x2" : "list.bullet")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help(isCompactMode ? "Erweiterte Detail-Ansicht" : "Kompakte Listen-Ansicht")

                Button(action: onClose) {
                    Image(systemName: "sidebar.trailing")
                }
                .buttonStyle(.plain)
                .help("Liste ausblenden")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Grid oder Callsign filtern...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            
            Picker("Sortierung", selection: $sortMode) {
                Label("Grid (A-Z)", systemImage: "square.grid.2x2").tag(0)
                Label("Spots", systemImage: "number").tag(1)
                Label("Kontinent", systemImage: "globe").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
            
            Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)

            if clusters.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal")
                        .font(.largeTitle)
                        .foregroundColor(.green.opacity(0.6))
                    Text("Keine aktiven Grids im Zeitfenster")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if sortedClusters.isEmpty {
                Spacer()
                Text("Kein Treffer für '\(searchText)'").foregroundColor(.secondary)
                Spacer()
            } else {
                List {
                    if sortMode == 2 {
                        ForEach(clustersByContinent, id: \.continent) { group in
                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: { !collapsedContinents.contains(group.continent) },
                                    set: { isExpanded in
                                        if isExpanded {
                                            collapsedContinents.remove(group.continent)
                                        } else {
                                            collapsedContinents.insert(group.continent)
                                        }
                                    }
                                )
                            ) {
                                ForEach(group.clusters) { cluster in
                                    NewGridListRow(
                                        cluster: cluster,
                                        fontSize: fontSizeTable,
                                        homeCoordinate: homeCoordinate,
                                        isCompact: isCompactMode
                                    ) {
                                        onSelectCluster(cluster)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(group.continent)
                                        .font(.caption)
                                        .bold()
                                    Spacer()
                                    Text("\(group.clusters.count)")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(Color.secondary.opacity(0.15), in: Capsule())
                                }
                            }
                        }
                    } else {
                        ForEach(sortedClusters) { cluster in
                            NewGridListRow(
                                cluster: cluster,
                                fontSize: fontSizeTable,
                                homeCoordinate: homeCoordinate,
                                isCompact: isCompactMode
                            ) {
                                onSelectCluster(cluster)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct GridMarkerView: View, Equatable {
    let cluster: NewGridCluster

    private var ageSeconds: TimeInterval {
        Date().timeIntervalSince(cluster.latestTime)
    }

    private var isFresh: Bool {
        ageSeconds < 180 // < 3 Min.
    }

    private var markerOpacity: Double {
        if isFresh { return 1.0 }
        if ageSeconds < 600 { return 0.95 }
        return 0.75
    }

    var body: some View {
        HStack(spacing: 4) {
            if cluster.isBlocked {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white)
            }

            if isFresh {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
            }

            if let firstCall = cluster.calls.first {
                Text(firstCall)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        cluster.isBlocked
                        ? Color.orange
                        : (cluster.is6Char ? Color.blue : Color.green),
                        in: Capsule()
                    )

                if cluster.calls.count > 1 {
                    Text("+\(cluster.calls.count - 1)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.trailing, 4)
                }
            } else {
                Text("\(cluster.spotCount) Spots")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        cluster.is6Char ? Color.blue : Color.green,
                        in: Capsule()
                    )
            }
        }
        .padding(2)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(isFresh ? Color.yellow.opacity(0.8) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: isFresh ? Color.yellow.opacity(0.4) : Color.black.opacity(0.3), radius: isFresh ? 5 : 3, x: 0, y: 1)
        .opacity(markerOpacity)
    }
}

private struct NewGridListRow: View, Equatable {
    let cluster: NewGridCluster
    let fontSize: Double
    let homeCoordinate: CLLocationCoordinate2D?
    let isCompact: Bool
    let onSelect: () -> Void

    static func == (lhs: NewGridListRow, rhs: NewGridListRow) -> Bool {
        lhs.cluster == rhs.cluster &&
        lhs.fontSize == rhs.fontSize &&
        lhs.isCompact == rhs.isCompact &&
        lhs.homeCoordinate?.latitude == rhs.homeCoordinate?.latitude &&
        lhs.homeCoordinate?.longitude == rhs.homeCoordinate?.longitude
    }

    private var ageSeconds: TimeInterval {
        Date().timeIntervalSince(cluster.latestTime)
    }

    private var isFresh: Bool {
        ageSeconds < 180 // < 3 Min.
    }

    private var headingAndDistance: String? {
        guard let home = homeCoordinate else { return nil }
        let target = CLLocationCoordinate2D(latitude: cluster.latitude, longitude: cluster.longitude)
        let heading = Int(round(Maidenhead.bearingDeg(from: home, to: target)))
        let dist = Int(round(Maidenhead.distanceKm(from: home, to: target)))
        return "\(heading)° · \(dist)km"
    }

    var body: some View {
        Button(action: onSelect) {
            if isCompact {
                // Kompakte Ansicht (1 Zeile)
                HStack(spacing: 6) {
                    Text(cluster.grid)
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            cluster.isBlocked
                            ? Color.orange.opacity(0.2)
                            : (cluster.is6Char ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        )
                        .foregroundColor(
                            cluster.isBlocked
                            ? .orange
                            : (cluster.is6Char ? .blue : .green)
                        )
                        .cornerRadius(4)

                    if let beam = headingAndDistance {
                        Text(beam)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Text(cluster.country)
                        .font(.system(size: CGFloat(fontSize), weight: .medium))
                        .lineLimit(1)

                    Spacer()

                    if isFresh {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.yellow)
                    }

                    HStack(spacing: 3) {
                        ForEach(cluster.bands, id: \.name) { band in
                            Text(band.name)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(colorForBandName(band.name).opacity(0.25))
                                .foregroundColor(colorForBandName(band.name))
                                .cornerRadius(3)
                        }
                    }
                }
                .padding(.vertical, 3)
                .opacity(isFresh ? 1.0 : (ageSeconds > 600 ? 0.75 : 0.95))
            } else {
                // Detaillierte Ansicht
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(cluster.grid)
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                cluster.isBlocked
                                ? Color.orange.opacity(0.2)
                                : (cluster.is6Char ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                            )
                            .foregroundColor(
                                cluster.isBlocked
                                ? .orange
                                : (cluster.is6Char ? .blue : .green)
                            )
                            .cornerRadius(4)
                        
                        Text(cluster.isBlocked ? "Ausgefiltert" : (cluster.is6Char ? "6-Stellen" : "4-Stellen"))
                            .font(.system(size: 8, weight: .semibold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(cluster.isBlocked ? Color.orange.opacity(0.15) : Color.secondary.opacity(0.15))
                            .foregroundColor(cluster.isBlocked ? .orange : .secondary)
                            .cornerRadius(3)
                        
                        if isFresh {
                            HStack(spacing: 2) {
                                Image(systemName: "bolt.fill").font(.system(size: 7))
                                Text("NEU").font(.system(size: 8, weight: .black))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.yellow.opacity(0.25))
                            .foregroundColor(.yellow)
                            .cornerRadius(3)
                        }

                        Text(cluster.country)
                            .font(.system(size: CGFloat(fontSize), weight: .semibold))
                        
                        Spacer()
                        
                        Text("\(cluster.spotCount) Spot\(cluster.spotCount == 1 ? "" : "s")")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    if let beam = headingAndDistance {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Text("Peilung: \(beam)")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    if !cluster.calls.isEmpty {
                        Text("Stationen: " + cluster.calls.joined(separator: ", "))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(cluster.bands, id: \.name) { band in
                            Text("\(band.name): \(band.count)")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(colorForBandName(band.name).opacity(0.2))
                                .foregroundColor(colorForBandName(band.name))
                                .cornerRadius(3)
                        }
                    }
                }
                .padding(.vertical, 4)
                .opacity(isFresh ? 1.0 : (ageSeconds > 600 ? 0.75 : 0.95))
            }
        }
        .buttonStyle(.plain)
    }
}

struct GridInspectorInfo: Identifiable, Equatable {
    var id: String { grid }
    let grid: String
    let coordinate: CLLocationCoordinate2D
    let is6Char: Bool
    let country: String
    let continent: String
    let isWorked: Bool
    let workedCount: Int
    let activeCluster: NewGridCluster?
    
    static func == (lhs: GridInspectorInfo, rhs: GridInspectorInfo) -> Bool {
        lhs.grid == rhs.grid &&
        lhs.isWorked == rhs.isWorked &&
        lhs.workedCount == rhs.workedCount &&
        lhs.activeCluster == rhs.activeCluster
    }
}

struct GridDetailInspectorPopover: View {
    let info: GridInspectorInfo
    let homeCoordinate: CLLocationCoordinate2D?
    let onShowWorkedQSOs: () -> Void
    let onCenterMap: () -> Void
    let onOpenQRZ: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private var headingAndDistance: String? {
        guard let home = homeCoordinate else { return nil }
        let heading = Int(round(Maidenhead.bearingDeg(from: home, to: info.coordinate)))
        let dist = Int(round(Maidenhead.distanceKm(from: home, to: info.coordinate)))
        return "\(heading)° · \(dist) km"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Text(info.grid)
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow.opacity(0.8), lineWidth: 1.5))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.country)
                        .font(.headline)
                        .bold()
                    if !info.continent.isEmpty {
                        Text(info.continent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Status & Peilung
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if info.isWorked {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Gearbeitet (\(info.workedCount) QSO\(info.workedCount == 1 ? "" : "s"))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15), in: Capsule())
                        
                        Button("QSOs anzeigen") {
                            dismiss()
                            onShowWorkedQSOs()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            Text("Ungearbeitetes Grid")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                }
                
                if let beam = headingAndDistance {
                    HStack(spacing: 4) {
                        Image(systemName: "safari.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 11))
                        Text("Peilung / Distanz:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(beam)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                }
            }
            
            // Aktive Spots / Stationen
            if let cluster = info.activeCluster, !cluster.calls.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Aktive Stationen (\(cluster.spotCount) Spots):")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Klick = QRZ.com")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(cluster.calls, id: \.self) { call in
                                Button(action: { onOpenQRZ(call) }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 8))
                                        Text(call)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                                    .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .help("QRZ.com für \(call) öffnen")
                            }
                        }
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(cluster.bands, id: \.name) { band in
                            Text("\(band.name): \(band.count)")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(colorForBandName(band.name).opacity(0.2))
                                .foregroundColor(colorForBandName(band.name))
                                .cornerRadius(3)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    dismiss()
                    onCenterMap()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "scope")
                        Text("Hierhin zentrieren")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
            }
        }
        .padding(14)
        .frame(width: 320)
    }
}

struct WorkedGridDetailView: View {
    let grid: String
    let qsos: [QSOEntry]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedQSOID: QSOEntry.ID?
    @State private var showAlert = false
    @State private var alertTitle = "Fehler"
    @State private var alertMessage = ""

    private var filteredQSOs: [QSOEntry] {
        let clean = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if clean.isEmpty { return qsos }
        return qsos.filter {
            $0.callsign.uppercased().contains(clean) ||
            $0.band.uppercased().contains(clean) ||
            $0.mode.uppercased().contains(clean) ||
            $0.dxcc.uppercased().contains(clean) ||
            $0.grid.uppercased().contains(clean)
        }
    }

    private func openQRZ(for callsign: String) {
        let cleanCall = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleanCall.isEmpty else { return }
        
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "InternetCheckQueue")
        monitor.pathUpdateHandler = { path in
            monitor.cancel()
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    if let url = URL(string: "https://www.qrz.com/db/\(cleanCall)") {
                        NSWorkspace.shared.open(url)
                    }
                } else {
                    alertTitle = "Keine Internetverbindung"
                    alertMessage = "Es besteht keine aktive Internetverbindung. Die QRZ.com-Detailseite für '\(cleanCall)' kann nicht geöffnet werden."
                    showAlert = true
                }
            }
        }
        monitor.start(queue: queue)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.square.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Gearbeitete Stationen in Grid \(grid)")
                            .font(.title2)
                            .bold()
                    }
                    Text("\(qsos.count) QSO\(qsos.count == 1 ? "" : "s") im Logbuch · Doppelklick öffnet QRZ.com")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Schließen") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Search Filter Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Rufzeichen, Band oder Land filtern...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Table of Worked QSOs
            Table(filteredQSOs, selection: $selectedQSOID) {
                TableColumn("Rufzeichen") { qso in
                    HStack {
                        Text(qso.callsign).bold()
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
                TableColumn("Grid") { qso in
                    HStack {
                        Text(qso.grid)
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
                TableColumn("Band") { qso in
                    HStack {
                        Text(qso.band)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
                TableColumn("Mode") { qso in
                    HStack {
                        Text(qso.mode)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
                TableColumn("Datum") { qso in
                    HStack {
                        Text(qso.formattedDate)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
                TableColumn("Uhrzeit") { qso in
                    HStack {
                        Text(qso.formattedTime)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
                TableColumn("DXCC") { qso in
                    HStack {
                        Text(qso.dxcc)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        openQRZ(for: qso.callsign)
                    }
                }
            }
        }
        .frame(minWidth: 680, minHeight: 420)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
