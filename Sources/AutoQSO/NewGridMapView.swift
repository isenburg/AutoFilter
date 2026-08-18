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

    private var selectedMapStyle: MapStyleOption {
        MapStyleOption(rawValue: selectedMapStyleRaw) ?? .standard
    }

    @State private var displayGridClusters: [NewGridCluster] = []

    private var filteredClusters: [NewGridCluster] {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanQuery.isEmpty {
            return displayGridClusters
        }
        return displayGridClusters.filter { cluster in
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
        let grouped = Dictionary(grouping: sortedClusters) { viewModel.continentName(for: $0.continent) }
        return grouped.map { (continent: $0.key, clusters: $0.value) }
            .sorted { a, b in
                if a.continent == "OTHER" { return false }
                if b.continent == "OTHER" { return true }
                return a.continent < b.continent
            }
    }

    var body: some View {
        HSplitView {
            // Main Map Area
            mapSection
                .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)

            // Sidebar Area
            if showList {
                sidebarSection
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
    @State private var cachedGlobeSpotItems: [GlobeSpotItem] = []

    private struct WorkedGridItem: Identifiable {
        let grid: String
        var id: String { grid }
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
                ForEach(displayGridClusters) { cluster in
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: cluster.upperRightLatitude,
                        longitude: cluster.upperRightLongitude
                    )) {
                        GridMarkerView(cluster: cluster)
                            .drawingGroup()
                            .onTapGesture {
                                centerOnCluster(cluster)
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
                    let grid4 = Maidenhead.latLonToLocator(lat: coord.latitude, lon: coord.longitude, length: 4)
                    let matching = viewModel.lotwManager.logbook.filter {
                        $0.grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix(grid4)
                    }
                    if !matching.isEmpty {
                        selectedWorkedGrid = grid4
                    }
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
                        MaidenheadGridCanvasView(proxy: proxy, region: currentRegion, workedGrids: viewModel.worked4CharGrids)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 6) {
                        Picker("Kartenstil", selection: $selectedMapStyleRaw) {
                            ForEach(MapStyleOption.allCases) { style in
                                Text(style.rawValue).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                        .help("Kartenstil auswählen")

                        Button(action: {
                            withAnimation {
                                showWorkedGridShading.toggle()
                            }
                        }) {
                            Image(systemName: showWorkedGridShading ? "checkmark.square.fill" : "checkmark.square")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(6)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
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
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.3x3.topleft.filled")
                                .foregroundColor(.green)
                            Text("Neue Maidenhead Grids").font(.caption).bold()
                        }
                        
                        let count4 = displayGridClusters.filter { !$0.is6Char }.count
                        let count6 = displayGridClusters.filter { $0.is6Char }.count
                        
                        Text("\(displayGridClusters.count) ungearbeitete Grids")
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
                        
                        Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                        
                        Stepper(value: $mapTimeWindow, in: 5...120, step: 5) {
                            Text("Zeitfenster: \(mapTimeWindow) Min.").font(.caption2).lineLimit(1)
                        }
                        .onChange(of: mapTimeWindow) { _, _ in
                            viewModel.updatePropagationClusters()
                        }
                    }
                    .fixedSize()
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .padding(8)
                }

                if showMaidenheadOverlay {
                    GridOverlaySettingsBar()
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private var sidebarSection: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text("Neue Grids (\(displayGridClusters.count))").font(.headline)
                }
                Spacer()
                Button(action: { withAnimation { showList = false } }) {
                    Image(systemName: "sidebar.trailing")
                }
                .buttonStyle(.plain)
                .help("Liste ausblenden")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            // Search Bar
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

            if displayGridClusters.isEmpty {
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
                                    NewGridListRow(cluster: cluster, fontSize: fontSizeTable) {
                                        centerOnCluster(cluster)
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
                            NewGridListRow(cluster: cluster, fontSize: fontSizeTable) {
                                centerOnCluster(cluster)
                            }
                        }
                    }
                }
                .listStyle(.plain)
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

private struct GridMarkerView: View, Equatable {
    let cluster: NewGridCluster

    var body: some View {
        HStack(spacing: 4) {
            if cluster.isBlocked {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.white)
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
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

private struct NewGridListRow: View, Equatable {
    let cluster: NewGridCluster
    let fontSize: Double
    let onSelect: () -> Void

    static func == (lhs: NewGridListRow, rhs: NewGridListRow) -> Bool {
        lhs.cluster == rhs.cluster && lhs.fontSize == rhs.fontSize
    }

    var body: some View {
        Button(action: onSelect) {
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
                    
                    Text(cluster.country)
                        .font(.system(size: CGFloat(fontSize), weight: .semibold))
                    
                    Spacer()
                    
                    Text("\(cluster.spotCount) Spot\(cluster.spotCount == 1 ? "" : "s")")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
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
                            .background(cluster.isBlocked ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                            .foregroundColor(cluster.isBlocked ? .orange : .blue)
                            .cornerRadius(3)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
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
