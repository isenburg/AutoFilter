import SwiftUI
import MapKit

struct GlobeSpotItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    let bandName: String
}

class GlobeSpotAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let bandName: String

    init(item: GlobeSpotItem) {
        self.title = item.title
        self.subtitle = item.subtitle
        self.coordinate = CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude)
        self.bandName = item.bandName
    }
}

private func parseNSColor(hexString: String, defaultColor: NSColor) -> NSColor {
    let cleaned = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
    guard cleaned.count == 6 || cleaned.count == 8 else {
        return defaultColor
    }
    let scanner = Scanner(string: cleaned)
    var hexNumber: UInt64 = 0
    if scanner.scanHexInt64(&hexNumber) {
        let r, g, b, a: CGFloat
        if cleaned.count == 6 {
            r = CGFloat((hexNumber & 0xff0000) >> 16) / 255.0
            g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255.0
            b = CGFloat(hexNumber & 0x0000ff) / 255.0
            a = 1.0
        } else {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255.0
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255.0
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255.0
            a = CGFloat(hexNumber & 0x000000ff) / 255.0
        }
        return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
    }
    return defaultColor
}

private func nsColorForBand(_ band: String) -> NSColor {
    switch band.uppercased() {
    case "MY_QTH": return .systemGreen
    case "ACTIVE_QSO": return .systemOrange
    case "160M": return NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    case "80M":  return NSColor(red: 0.5, green: 0.0, blue: 0.5, alpha: 1.0)
    case "60M":  return NSColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 1.0)
    case "40M":  return .systemBlue
    case "30M":  return NSColor(red: 0.0, green: 0.6, blue: 0.6, alpha: 1.0)
    case "20M":  return NSColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)
    case "17M":  return NSColor(red: 0.6, green: 0.8, blue: 0.0, alpha: 1.0)
    case "15M":  return .systemOrange
    case "12M":  return NSColor(red: 0.9, green: 0.4, blue: 0.0, alpha: 1.0)
    case "10M":  return .systemRed
    case "6M":   return NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
    default:     return .systemTeal
    }
}

// MARK: - Persistent Maidenhead Geometry Cache (Calculated ONCE and stored permanently)
final class MaidenheadGeometryCache {
    static let shared = MaidenheadGeometryCache()
    private var grid4Cache: [String: PreProjectedWorkedGrid] = [:]
    private var grid6Cache: [String: PreProjectedWorkedGrid] = [:]
    private let lock = NSLock()

    func projectedGrid4(_ grid4: String) -> PreProjectedWorkedGrid? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = grid4Cache[grid4] {
            return cached
        }
        guard let box = Maidenhead.grid4BoundingBox(grid4) else { return nil }
        let p0 = MKMapPoint(CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.minLon))
        let p1 = MKMapPoint(CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.maxLon))
        let p2 = MKMapPoint(CLLocationCoordinate2D(latitude: box.minLat, longitude: box.maxLon))
        let p3 = MKMapPoint(CLLocationCoordinate2D(latitude: box.minLat, longitude: box.minLon))
        
        let minX = min(p0.x, p1.x, p2.x, p3.x)
        let maxX = max(p0.x, p1.x, p2.x, p3.x)
        let minY = min(p0.y, p1.y, p2.y, p3.y)
        let maxY = max(p0.y, p1.y, p2.y, p3.y)
        let rect = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        let item = PreProjectedWorkedGrid(mapRect: rect, points: (p0, p1, p2, p3))
        grid4Cache[grid4] = item
        return item
    }

    func projectedGrid6(_ grid6: String) -> PreProjectedWorkedGrid? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = grid6Cache[grid6] {
            return cached
        }
        guard let box = Maidenhead.grid6BoundingBox(grid6) else { return nil }
        let p0 = MKMapPoint(CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.minLon))
        let p1 = MKMapPoint(CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.maxLon))
        let p2 = MKMapPoint(CLLocationCoordinate2D(latitude: box.minLat, longitude: box.maxLon))
        let p3 = MKMapPoint(CLLocationCoordinate2D(latitude: box.minLat, longitude: box.minLon))
        
        let minX = min(p0.x, p1.x, p2.x, p3.x)
        let maxX = max(p0.x, p1.x, p2.x, p3.x)
        let minY = min(p0.y, p1.y, p2.y, p3.y)
        let maxY = max(p0.y, p1.y, p2.y, p3.y)
        let rect = MKMapRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        let item = PreProjectedWorkedGrid(mapRect: rect, points: (p0, p1, p2, p3))
        grid6Cache[grid6] = item
        return item
    }
}

// MARK: - 1. Pre-Projected Geometry Primitives
struct PreProjectedWorkedGrid {
    let mapRect: MKMapRect
    let points: (MKMapPoint, MKMapPoint, MKMapPoint, MKMapPoint)
}

struct PreProjectedGridLine {
    let mapRect: MKMapRect
    let p1: MKMapPoint
    let p2: MKMapPoint
}

struct PreProjectedGridLabel {
    let mapRect: MKMapRect
    let point: MKMapPoint
    let text: String
    let fontSize: CGFloat
}

struct PreProjectedSpot {
    let mapRect: MKMapRect
    let point: MKMapPoint
    let color: NSColor
    let title: String
}

// MARK: - 2. Lock-Free Immutable Geometry Snapshot
final class GeometrySnapshot {
    let workedGrids: [PreProjectedWorkedGrid]
    let gridLines: [PreProjectedGridLine]
    let labels: [PreProjectedGridLabel]
    let spots: [PreProjectedSpot]
    let showWorkedGridShading: Bool
    let showGridOverlay: Bool
    let showBadges: Bool
    let shadeColor: NSColor
    let textColor: NSColor
    let lineColor: NSColor
    let badgeColor: NSColor
    let spotPointSize: Double
    let signature: Int

    init(
        workedGrids: [PreProjectedWorkedGrid] = [],
        gridLines: [PreProjectedGridLine] = [],
        labels: [PreProjectedGridLabel] = [],
        spots: [PreProjectedSpot] = [],
        showWorkedGridShading: Bool = false,
        showGridOverlay: Bool = false,
        showBadges: Bool = true,
        shadeColor: NSColor = .systemOrange,
        textColor: NSColor = .systemYellow,
        lineColor: NSColor = .systemTeal,
        badgeColor: NSColor = .black,
        spotPointSize: Double = 12.0
    ) {
        self.workedGrids = workedGrids
        self.gridLines = gridLines
        self.labels = labels
        self.spots = spots
        self.showWorkedGridShading = showWorkedGridShading
        self.showGridOverlay = showGridOverlay
        self.showBadges = showBadges
        self.shadeColor = shadeColor
        self.textColor = textColor
        self.lineColor = lineColor
        self.badgeColor = badgeColor
        self.spotPointSize = spotPointSize
        
        var hasher = Hasher()
        hasher.combine(workedGrids.count)
        hasher.combine(gridLines.count)
        hasher.combine(labels.count)
        hasher.combine(spots.count)
        hasher.combine(showWorkedGridShading)
        hasher.combine(showGridOverlay)
        hasher.combine(showBadges)
        hasher.combine(shadeColor)
        hasher.combine(textColor)
        hasher.combine(lineColor)
        hasher.combine(badgeColor)
        hasher.combine(spotPointSize)
        if let firstLabel = labels.first {
            hasher.combine(firstLabel.text)
        }
        if let lastLabel = labels.last {
            hasher.combine(lastLabel.text)
        }
        if let firstSpot = spots.first {
            hasher.combine(firstSpot.title)
        }
        if let lastSpot = spots.last {
            hasher.combine(lastSpot.title)
        }
        self.signature = hasher.finalize()
    }
}

// MARK: - 3. Persistent Single Mutable MKOverlay (Lock-Free Double-Buffered)
final class MaidenheadVectorOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: 0, longitude: 0) }
    var boundingMapRect: MKMapRect { MKMapRect.world }
    
    // Atomic snapshot pointer swap: reads in draw() are completely lock-free
    private(set) var snapshot = GeometrySnapshot()

    func setSnapshot(_ newSnapshot: GeometrySnapshot) {
        self.snapshot = newSnapshot
    }
}

// MARK: - 4. Zero-Allocation GPU/CoreGraphics Overlay Renderer
final class MaidenheadVectorOverlayRenderer: MKOverlayRenderer {
    private var vectorOverlay: MaidenheadVectorOverlay {
        overlay as! MaidenheadVectorOverlay
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Lock-free read of current immutable snapshot
        let snap = vectorOverlay.snapshot
        
        // Layer 0: Worked Grid Shading
        if snap.showWorkedGridShading && !snap.workedGrids.isEmpty {
            let fillCol = snap.shadeColor.withAlphaComponent(0.38).cgColor
            let strokeCol = snap.shadeColor.withAlphaComponent(0.70).cgColor
            context.setFillColor(fillCol)
            context.setStrokeColor(strokeCol)
            context.setLineWidth(0.8 / zoomScale)
            
            for grid in snap.workedGrids {
                if grid.mapRect.intersects(mapRect) {
                    let pt0 = self.point(for: grid.points.0)
                    let pt1 = self.point(for: grid.points.1)
                    let pt2 = self.point(for: grid.points.2)
                    let pt3 = self.point(for: grid.points.3)
                    
                    context.beginPath()
                    context.move(to: pt0)
                    context.addLine(to: pt1)
                    context.addLine(to: pt2)
                    context.addLine(to: pt3)
                    context.closePath()
                    context.drawPath(using: .fillStroke)
                }
            }
        }
        
        // Layer 1: Maidenhead Grid Lines & Labels
        if snap.showGridOverlay {
            if !snap.gridLines.isEmpty {
                context.setStrokeColor(snap.lineColor.withAlphaComponent(0.55).cgColor)
                context.setLineWidth(1.0 / zoomScale)
                
                for line in snap.gridLines {
                    if line.mapRect.intersects(mapRect) {
                        let pt1 = self.point(for: line.p1)
                        let pt2 = self.point(for: line.p2)
                        
                        context.beginPath()
                        context.move(to: pt1)
                        context.addLine(to: pt2)
                        context.strokePath()
                    }
                }
            }

            if !snap.labels.isEmpty {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center

                for label in snap.labels {
                    if label.mapRect.intersects(mapRect) {
                        let pt = self.point(for: label.point)
                        
                        context.saveGState()
                        context.translateBy(x: pt.x, y: pt.y)
                        // Scale to 1:1 screen pixels for crisp, predictable typography
                        context.scaleBy(x: 1.0 / zoomScale, y: -1.0 / zoomScale)
                        
                        let font = NSFont.monospacedSystemFont(ofSize: label.fontSize, weight: .bold)
                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: font,
                            .foregroundColor: snap.textColor,
                            .paragraphStyle: paragraphStyle
                        ]
                        let str = NSAttributedString(string: label.text, attributes: attrs)
                        let size = str.size()
                        let drawRect = CGRect(x: -size.width / 2.0, y: -size.height / 2.0, width: size.width, height: size.height)
                        
                        // Render readability badge background pill if enabled
                        if snap.showBadges {
                            let padX: CGFloat = 4.0
                            let padY: CGFloat = 2.0
                            let badgeRect = CGRect(
                                x: drawRect.minX - padX,
                                y: drawRect.minY - padY,
                                width: drawRect.width + padX * 2,
                                height: drawRect.height + padY * 2
                            )
                            let cornerR: CGFloat = 3.5
                            let path = CGPath(roundedRect: badgeRect, cornerWidth: cornerR, cornerHeight: cornerR, transform: nil)
                            
                            context.addPath(path)
                            context.setFillColor(snap.badgeColor.withAlphaComponent(0.65).cgColor)
                            context.fillPath()
                            
                            context.addPath(path)
                            context.setStrokeColor(snap.lineColor.withAlphaComponent(0.40).cgColor)
                            context.setLineWidth(0.8)
                            context.strokePath()
                        }

                        // Activate NSGraphicsContext for CoreGraphics drawing buffer
                        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
                        let prevContext = NSGraphicsContext.current
                        NSGraphicsContext.current = nsContext
                        str.draw(in: drawRect)
                        NSGraphicsContext.current = prevContext
                        
                        context.restoreGState()
                    }
                }
            }
        }

        // Layer 2: Vector Spots (Direct GPU Circle Drawing - 0 NSViews!)
        if !snap.spots.isEmpty {
            let pointDiameter = snap.spotPointSize > 0 ? snap.spotPointSize : 12.0
            let spotRadius = (pointDiameter / 2.0) / zoomScale
            let spotDiameter = spotRadius * 2.0
            
            for spot in snap.spots {
                if spot.mapRect.intersects(mapRect) {
                    let pt = self.point(for: spot.point)
                    let circleRect = CGRect(x: pt.x - spotRadius, y: pt.y - spotRadius, width: spotDiameter, height: spotDiameter)
                    
                    context.setFillColor(spot.color.cgColor)
                    context.setStrokeColor(NSColor.black.withAlphaComponent(0.8).cgColor)
                    context.setLineWidth(1.0 / zoomScale)
                    
                    context.fillEllipse(in: circleRect)
                    context.strokeEllipse(in: circleRect)
                }
            }
        }
    }
}

// MARK: - 5. GlobeMapViewContainer NSViewRepresentable
struct GlobeMapViewContainer: NSViewRepresentable {
    var initialRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.0, longitude: 10.0), span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 30.0))
    var programmaticRegion: MKCoordinateRegion? = nil
    var showGridOverlay: Bool
    var workedGrids: Set<String> = []
    var workedGrids6: Set<String> = []
    var showWorkedGridShading: Bool = false
    var showBadges: Bool = true
    var gridTextColor: String = ""
    var gridLineColor: String = ""
    var gridBadgeColor: String = ""
    var gridFontSize: Double = 11.0
    var spotPointSize: Double = 12.0
    var spotItems: [GlobeSpotItem] = []
    var activeQSOPath: ActiveQSOPath? = nil
    var mapStyle: MapStyleOption = .globus
    var onSelectGrid: ((String) -> Void)? = nil
    var onSelectCoordinate: ((CLLocationCoordinate2D, CGPoint) -> Void)? = nil
    var inspectPopoverBuilder: ((CLLocationCoordinate2D, Double, @escaping () -> Void) -> AnyView)? = nil

    static func applyConfiguration(_ mapView: MKMapView, style: MapStyleOption) {
        switch style {
        case .globus:
            if let config = mapView.preferredConfiguration as? MKHybridMapConfiguration, config.elevationStyle == .realistic {
                // already 3D globe
            } else {
                mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .realistic)
            }
        case .satellite:
            if !(mapView.preferredConfiguration is MKImageryMapConfiguration) {
                mapView.preferredConfiguration = MKImageryMapConfiguration(elevationStyle: .flat)
            }
        case .hybrid:
            if let config = mapView.preferredConfiguration as? MKHybridMapConfiguration, config.elevationStyle == .flat {
                // already flat hybrid
            } else {
                mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .flat)
            }
        case .standard:
            if let config = mapView.preferredConfiguration as? MKStandardMapConfiguration, config.emphasisStyle != .muted {
                // already standard flat
            } else if !(mapView.preferredConfiguration is MKStandardMapConfiguration) {
                mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat)
            }
        case .muted:
            if let config = mapView.preferredConfiguration as? MKStandardMapConfiguration, config.emphasisStyle == .muted {
                // already applied
            } else {
                mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
            }
        }
    }

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        GlobeMapViewContainer.applyConfiguration(mapView, style: mapStyle)
        let startingRegion = programmaticRegion ?? initialRegion
        mapView.region = startingRegion
        mapView.delegate = context.coordinator
        
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(clickGesture)
        
        if let path = activeQSOPath {
            let qsoRegion = PropagationMapView.centerRegionForQSO(from: path.myCoordinate, to: path.targetCoordinate)
            mapView.region = qsoRegion
        }
        
        // Register single persistent vector overlay ONCE
        context.coordinator.setupPersistentOverlay(mapView)
        context.coordinator.scheduleBackgroundSnapshotUpdate(
            showGrid: showGridOverlay,
            workedGrids: workedGrids,
            workedGrids6: workedGrids6,
            showShading: showWorkedGridShading,
            showBadges: showBadges,
            gridTextColor: gridTextColor,
            gridLineColor: gridLineColor,
            gridBadgeColor: gridBadgeColor,
            gridFontSize: gridFontSize,
            spotPointSize: spotPointSize,
            spotItems: spotItems,
            region: startingRegion
        )
        context.coordinator.updateActiveQSO(mapView, activeQSOPath: activeQSOPath)
        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        let coord = context.coordinator

        GlobeMapViewContainer.applyConfiguration(mapView, style: mapStyle)

        // Programmatic region change (only when explicitly requested)
        if let prog = programmaticRegion, coord.lastProgrammaticRegion?.center.latitude != prog.center.latitude || coord.lastProgrammaticRegion?.center.longitude != prog.center.longitude {
            coord.lastProgrammaticRegion = prog
            mapView.setRegion(prog, animated: true)
        }

        // Active QSO changes (auto-center, annotations, polyline)
        if coord.lastActiveQSOPath != activeQSOPath {
            coord.updateActiveQSO(mapView, activeQSOPath: activeQSOPath)
            if let path = activeQSOPath {
                let qsoRegion = PropagationMapView.centerRegionForQSO(from: path.myCoordinate, to: path.targetCoordinate)
                mapView.setRegion(qsoRegion, animated: true)
            }
        }

        // Check what changed for vector overlay
        let spotItemsChanged = coord.lastSpotItems != spotItems
        let settingsChanged = coord.lastShowGrid != showGridOverlay
            || coord.lastShowShading != showWorkedGridShading
            || coord.lastWorkedGrids != workedGrids
            || coord.lastWorkedGrids6 != workedGrids6
            || coord.lastShowBadges != showBadges
            || coord.lastGridTextColor != gridTextColor
            || coord.lastGridLineColor != gridLineColor
            || coord.lastGridBadgeColor != gridBadgeColor
            || coord.lastGridFontSize != gridFontSize
            || coord.lastSpotPointSize != spotPointSize

        if coord.isMapInteracting {
            // Map is moving or zooming: FREEZE live spot updates and buffer them
            if spotItemsChanged {
                coord.bufferedSpotItems = spotItems
            }
            // If user explicitly changed a setting (e.g. grid toggle), allow it immediately
            if settingsChanged {
                coord.scheduleBackgroundSnapshotUpdate(
                    showGrid: showGridOverlay,
                    workedGrids: workedGrids,
                    workedGrids6: workedGrids6,
                    showShading: showWorkedGridShading,
                    showBadges: showBadges,
                    gridTextColor: gridTextColor,
                    gridLineColor: gridLineColor,
                    gridBadgeColor: gridBadgeColor,
                    gridFontSize: gridFontSize,
                    spotPointSize: spotPointSize,
                    spotItems: coord.lastSpotItems, // keep frozen spots
                    region: mapView.region
                )
            }
        } else {
            // Map is stationary: apply changes directly
            if settingsChanged || spotItemsChanged {
                let spotsToApply = spotItemsChanged ? spotItems : (coord.bufferedSpotItems ?? spotItems)
                coord.bufferedSpotItems = nil
                coord.scheduleBackgroundSnapshotUpdate(
                    showGrid: showGridOverlay,
                    workedGrids: workedGrids,
                    workedGrids6: workedGrids6,
                    showShading: showWorkedGridShading,
                    showBadges: showBadges,
                    gridTextColor: gridTextColor,
                    gridLineColor: gridLineColor,
                    gridBadgeColor: gridBadgeColor,
                    gridFontSize: gridFontSize,
                    spotPointSize: spotPointSize,
                    spotItems: spotsToApply,
                    region: mapView.region
                )
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GlobeMapViewContainer
        let vectorOverlay = MaidenheadVectorOverlay()
        private var cachedVectorRenderer: MaidenheadVectorOverlayRenderer?
        weak var currentMapView: MKMapView?

        // Active QSO polyline
        private var activeQSOPolyline: MKPolyline?

        // Dirty-flag state
        var lastShowGrid: Bool = false
        var lastShowShading: Bool = false
        var lastWorkedGrids: Set<String> = []
        var lastWorkedGrids6: Set<String> = []
        private var cachedWorkedGridsGeometry: [PreProjectedWorkedGrid] = []
        private var cachedWorkedGridsSet: Set<String> = []
        private var cachedWorkedGrids6Geometry: [PreProjectedWorkedGrid] = []
        private var cachedWorkedGrids6Set: Set<String> = []
        private var cachedWorkedGridsShading: Bool = false
        var lastShowBadges: Bool = true
        var lastGridTextColor: String = ""
        var lastGridLineColor: String = ""
        var lastGridBadgeColor: String = ""
        var lastGridFontSize: Double = 11.0
        var lastSpotPointSize: Double = 12.0
        var lastSpotItems: [GlobeSpotItem] = []
        var lastActiveQSOPath: ActiveQSOPath? = nil
        var lastProgrammaticRegion: MKCoordinateRegion? = nil
        var activePopover: NSPopover? = nil

        // Throttle / Debounce & Spot Hysteresis
        private var regionDebounceWorkItem: DispatchWorkItem?
        private var unfreezeWorkItem: DispatchWorkItem?
        var isMapInteracting: Bool = false
        var bufferedSpotItems: [GlobeSpotItem]? = nil
        var lastRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))
        private var lastSnapshotSignature: Int = 0
        private var lastFullInvalidationTime: Date = .distantPast

        init(_ parent: GlobeMapViewContainer) {
            self.parent = parent
        }

        func setupPersistentOverlay(_ mapView: MKMapView) {
            self.currentMapView = mapView
            mapView.addOverlay(vectorOverlay, level: .aboveLabels)
        }

        func scheduleBackgroundSnapshotUpdate(
            showGrid: Bool,
            workedGrids: Set<String>,
            workedGrids6: Set<String> = [],
            showShading: Bool,
            showBadges: Bool = true,
            gridTextColor: String = "",
            gridLineColor: String = "",
            gridBadgeColor: String = "",
            gridFontSize: Double = 11.0,
            spotPointSize: Double = 12.0,
            spotItems: [GlobeSpotItem] = [],
            region: MKCoordinateRegion
        ) {
            let settingsChanged = self.lastSpotPointSize != spotPointSize
                || self.lastGridFontSize != gridFontSize
                || self.lastShowGrid != showGrid
                || self.lastShowShading != showShading
                || self.lastWorkedGrids != workedGrids
                || self.lastWorkedGrids6 != workedGrids6
                || self.lastShowBadges != showBadges
                || self.lastGridTextColor != gridTextColor
                || self.lastGridLineColor != gridLineColor
                || self.lastGridBadgeColor != gridBadgeColor

            self.lastShowGrid = showGrid
            self.lastShowShading = showShading
            self.lastWorkedGrids = workedGrids
            self.lastWorkedGrids6 = workedGrids6
            self.lastShowBadges = showBadges
            self.lastGridTextColor = gridTextColor
            self.lastGridLineColor = gridLineColor
            self.lastGridBadgeColor = gridBadgeColor
            self.lastGridFontSize = gridFontSize
            self.lastSpotPointSize = spotPointSize
            self.lastSpotItems = spotItems

            let shadeColor = resolveShadeColor()
            let textColor = parseNSColor(hexString: gridTextColor, defaultColor: NSColor.systemYellow)
            let lineColor = parseNSColor(hexString: gridLineColor, defaultColor: NSColor.systemTeal)
            let badgeColor = parseNSColor(hexString: gridBadgeColor, defaultColor: NSColor.black)

            // Build immutable snapshot completely in background task
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                // 0. Determine zoom level & locator length first
                let latDelta = region.span.latitudeDelta
                let lonDelta = region.span.longitudeDelta
                
                let lonStep: Double
                let latStep: Double
                let locatorLength: Int
                let fontSize: CGFloat

                if latDelta > 25.0 {
                    // 2-character Fields (e.g. JO)
                    lonStep = 20.0
                    latStep = 10.0
                    locatorLength = 2
                    fontSize = 14.0
                } else if latDelta > 1.2 {
                    // 4-character Squares (e.g. JO31)
                    lonStep = 2.0
                    latStep = 1.0
                    locatorLength = 4
                    fontSize = 12.0
                } else {
                    // 6-character Subsquares (e.g. JO31aa)
                    lonStep = 2.0 / 24.0   // 0.08333 deg
                    latStep = 1.0 / 24.0   // 0.04167 deg
                    locatorLength = 6
                    fontSize = 10.0
                }

                // 1. Project worked grids (INSTANT O(1) from persistent cache)
                var projectedGrids: [PreProjectedWorkedGrid] = []
                if showShading {
                    if locatorLength == 6 {
                        if !workedGrids6.isEmpty {
                            if self.cachedWorkedGrids6Set != workedGrids6 || self.cachedWorkedGridsShading != showShading {
                                var projected: [PreProjectedWorkedGrid] = []
                                projected.reserveCapacity(workedGrids6.count)
                                for grid6 in workedGrids6 {
                                    if let item = MaidenheadGeometryCache.shared.projectedGrid6(grid6) {
                                        projected.append(item)
                                    }
                                }
                                self.cachedWorkedGrids6Geometry = projected
                                self.cachedWorkedGrids6Set = workedGrids6
                            }
                            projectedGrids = self.cachedWorkedGrids6Geometry
                        }
                    } else {
                        if !workedGrids.isEmpty {
                            if self.cachedWorkedGridsSet != workedGrids || self.cachedWorkedGridsShading != showShading {
                                var projected: [PreProjectedWorkedGrid] = []
                                projected.reserveCapacity(workedGrids.count)
                                for grid4 in workedGrids {
                                    if let item = MaidenheadGeometryCache.shared.projectedGrid4(grid4) {
                                        projected.append(item)
                                    }
                                }
                                self.cachedWorkedGridsGeometry = projected
                                self.cachedWorkedGridsSet = workedGrids
                            }
                            projectedGrids = self.cachedWorkedGridsGeometry
                        }
                    }
                    self.cachedWorkedGridsShading = showShading
                } else {
                    self.cachedWorkedGridsGeometry = []
                    self.cachedWorkedGrids6Geometry = []
                    self.cachedWorkedGridsSet = []
                    self.cachedWorkedGrids6Set = []
                    self.cachedWorkedGridsShading = false
                }

                // 2. Project grid lines & labels (up to 6-digit precision)
                var projectedLines: [PreProjectedGridLine] = []
                var projectedLabels: [PreProjectedGridLabel] = []

                if showGrid {
                    let center = region.center
                    let minLat = max(-80.0, floor((center.latitude - latDelta * 1.0) / latStep) * latStep)
                    let maxLat = min(80.0, ceil((center.latitude + latDelta * 1.0) / latStep) * latStep)
                    let minLon = max(-180.0, floor((center.longitude - lonDelta * 1.0) / lonStep) * lonStep)
                    let maxLon = min(180.0, ceil((center.longitude + lonDelta * 1.0) / lonStep) * lonStep)
                    
                    // Horizontal Latitude Lines
                    var lat = minLat
                    while lat <= maxLat + 0.0001 {
                        let p1 = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: minLon))
                        let p2 = MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: maxLon))
                        let rect = MKMapRect(x: min(p1.x, p2.x), y: min(p1.y, p2.y) - 500, width: abs(p2.x - p1.x), height: 1000)
                        projectedLines.append(PreProjectedGridLine(mapRect: rect, p1: p1, p2: p2))
                        lat += latStep
                    }
                    
                    // Vertical Longitude Lines
                    var lon = minLon
                    while lon <= maxLon + 0.0001 {
                        let p1 = MKMapPoint(CLLocationCoordinate2D(latitude: minLat, longitude: lon))
                        let p2 = MKMapPoint(CLLocationCoordinate2D(latitude: maxLat, longitude: lon))
                        let rect = MKMapRect(x: min(p1.x, p2.x) - 500, y: min(p1.y, p2.y), width: 1000, height: abs(p2.y - p1.y))
                        projectedLines.append(PreProjectedGridLine(mapRect: rect, p1: p1, p2: p2))
                        lon += lonStep
                    }

                    // Grid Center Labels
                    var cLat = minLat + latStep / 2.0
                    while cLat < maxLat {
                        var cLon = minLon + lonStep / 2.0
                        while cLon < maxLon {
                            let loc = Maidenhead.latLonToLocator(lat: cLat, lon: cLon, length: locatorLength)
                            if locatorLength == 6 {
                                // Sobald 6-stellige Grids angezeigt werden, nur noch die bereits gearbeiteten Grids anzeigen
                                if workedGrids6.contains(loc) {
                                    let pt = MKMapPoint(CLLocationCoordinate2D(latitude: cLat, longitude: cLon))
                                    let labelRect = MKMapRect(x: pt.x - 30000, y: pt.y - 15000, width: 60000, height: 30000)
                                    projectedLabels.append(PreProjectedGridLabel(mapRect: labelRect, point: pt, text: loc, fontSize: fontSize))
                                }
                            } else {
                                let pt = MKMapPoint(CLLocationCoordinate2D(latitude: cLat, longitude: cLon))
                                let labelRect = MKMapRect(x: pt.x - 30000, y: pt.y - 15000, width: 60000, height: 30000)
                                projectedLabels.append(PreProjectedGridLabel(mapRect: labelRect, point: pt, text: loc, fontSize: fontSize))
                            }
                            cLon += lonStep
                        }
                        cLat += latStep
                    }
                }

                // 3. Project spots directly into vector primitives (Zero NSViews!)
                var projectedSpots: [PreProjectedSpot] = []
                projectedSpots.reserveCapacity(spotItems.count)
                for item in spotItems {
                    let pt = MKMapPoint(CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude))
                    let spotMapRect = MKMapRect(x: pt.x - 25000, y: pt.y - 25000, width: 50000, height: 50000)
                    let col = nsColorForBand(item.bandName)
                    projectedSpots.append(PreProjectedSpot(mapRect: spotMapRect, point: pt, color: col, title: item.title))
                }

                // 4. Create immutable snapshot
                let newSnapshot = GeometrySnapshot(
                    workedGrids: projectedGrids,
                    gridLines: projectedLines,
                    labels: projectedLabels,
                    spots: projectedSpots,
                    showWorkedGridShading: showShading,
                    showGridOverlay: showGrid,
                    showBadges: showBadges,
                    shadeColor: shadeColor,
                    textColor: textColor,
                    lineColor: lineColor,
                    badgeColor: badgeColor,
                    spotPointSize: spotPointSize
                )

                // 5. Atomic pointer swap on MainActor with signature dirty-check
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    let changed = self.lastSnapshotSignature != newSnapshot.signature
                    self.vectorOverlay.setSnapshot(newSnapshot)
                    
                    if changed {
                        self.lastSnapshotSignature = newSnapshot.signature
                        let now = Date()
                        // Immediate redraw on settings change, or throttled to 3s for streaming spot changes
                        if settingsChanged || now.timeIntervalSince(self.lastFullInvalidationTime) > 3.0 {
                            self.lastFullInvalidationTime = now
                            self.cachedVectorRenderer?.setNeedsDisplay()
                            self.currentMapView?.setNeedsDisplay(self.currentMapView?.bounds ?? .zero)
                        }
                    }
                }
            }
        }

        func updateActiveQSO(_ mapView: MKMapView, activeQSOPath: ActiveQSOPath?) {
            self.lastActiveQSOPath = activeQSOPath

            // 1. Synchronously update interactive annotations (🏠 MY QTH and ⚡ ACTIVE QSO)
            let existingKeyAnnotations = mapView.annotations.filter { $0 is GlobeSpotAnnotation }
            if !existingKeyAnnotations.isEmpty {
                mapView.removeAnnotations(existingKeyAnnotations)
            }

            if let path = activeQSOPath {
                let mySpot = GlobeSpotItem(
                    id: "MY_QTH",
                    title: "MY QTH",
                    subtitle: path.myGrid,
                    latitude: path.myCoordinate.latitude,
                    longitude: path.myCoordinate.longitude,
                    bandName: "MY_QTH"
                )
                let targetSubtitle = path.targetGrid ?? path.targetCountry ?? ""
                let targetSpot = GlobeSpotItem(
                    id: "TARGET_\(path.targetCall)",
                    title: path.targetCall,
                    subtitle: targetSubtitle,
                    latitude: path.targetCoordinate.latitude,
                    longitude: path.targetCoordinate.longitude,
                    bandName: "ACTIVE_QSO"
                )
                mapView.addAnnotations([GlobeSpotAnnotation(item: mySpot), GlobeSpotAnnotation(item: targetSpot)])
            }

            // 2. Synchronously update Active QSO Great Circle Polyline
            if let oldPath = self.activeQSOPolyline {
                mapView.removeOverlay(oldPath)
                self.activeQSOPolyline = nil
            }
            if let path = activeQSOPath {
                let pathCoords = Maidenhead.greatCirclePath(from: path.myCoordinate, to: path.targetCoordinate, steps: 60)
                let polyline = MKPolyline(coordinates: pathCoords, count: pathCoords.count)
                polyline.title = "ActiveQSOPath"
                mapView.addOverlay(polyline, level: .aboveLabels)
                self.activeQSOPolyline = polyline
            }
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            // Immediately freeze spot updates upon movement or zoom
            self.isMapInteracting = true
            self.lastRegion = mapView.region

            unfreezeWorkItem?.cancel()
            let unfreeze = DispatchWorkItem { [weak self, weak mapView] in
                guard let self = self else { return }
                // 1.0 second hysteresis elapsed without any motion
                self.isMapInteracting = false
                
                let targetRegion = mapView?.region ?? self.lastRegion
                let spotsToApply = self.bufferedSpotItems ?? self.lastSpotItems
                self.bufferedSpotItems = nil

                self.scheduleBackgroundSnapshotUpdate(
                    showGrid: self.lastShowGrid,
                    workedGrids: self.lastWorkedGrids,
                    workedGrids6: self.lastWorkedGrids6,
                    showShading: self.lastShowShading,
                    showBadges: self.lastShowBadges,
                    gridTextColor: self.lastGridTextColor,
                    gridLineColor: self.lastGridLineColor,
                    gridBadgeColor: self.lastGridBadgeColor,
                    gridFontSize: self.lastGridFontSize,
                    spotPointSize: self.lastSpotPointSize,
                    spotItems: spotsToApply,
                    region: targetRegion
                )
            }
            unfreezeWorkItem = unfreeze
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: unfreeze)
        }

        @objc func handleMapTap(_ gesture: NSClickGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            
            activePopover?.close()
            activePopover = nil
            
            if let builder = parent.inspectPopoverBuilder {
                let popover = NSPopover()
                let closeAction: () -> Void = { [weak popover] in
                    popover?.close()
                }
                let spanDelta = mapView.region.span.latitudeDelta
                let view = builder(coord, spanDelta, closeAction)
                let hosting = NSHostingController(rootView: view)
                popover.contentViewController = hosting
                popover.behavior = .transient
                popover.animates = true
                
                let rect = CGRect(x: point.x, y: point.y, width: 1, height: 1)
                popover.show(relativeTo: rect, of: mapView, preferredEdge: .maxY)
                self.activePopover = popover
            } else if let onCoord = parent.onSelectCoordinate {
                onCoord(coord, point)
            } else {
                let grid4 = Maidenhead.latLonToLocator(lat: coord.latitude, lon: coord.longitude, length: 4)
                parent.onSelectGrid?(grid4)
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let spot = view.annotation as? GlobeSpotAnnotation else { return }
            activePopover?.close()
            activePopover = nil
            
            if let builder = parent.inspectPopoverBuilder {
                let popover = NSPopover()
                let closeAction: () -> Void = { [weak popover, weak mapView, weak view] in
                    popover?.close()
                    if let v = view, let ann = v.annotation {
                        mapView?.deselectAnnotation(ann, animated: false)
                    }
                }
                let spanDelta = mapView.region.span.latitudeDelta
                let viewContent = builder(spot.coordinate, spanDelta, closeAction)
                let hosting = NSHostingController(rootView: viewContent)
                popover.contentViewController = hosting
                popover.behavior = .transient
                popover.animates = true
                popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
                self.activePopover = popover
            }
        }

        private func resolveShadeColor() -> NSColor {
            let hex = UserDefaults.standard.string(forKey: "workedGridShadeColor") ?? ""
            return parseNSColor(hexString: hex, defaultColor: NSColor(red: 1.0, green: 0.35, blue: 0.15, alpha: 1.0))
        }

        private func resolveGridTextColor() -> NSColor {
            let hex = UserDefaults.standard.string(forKey: "gridOverlayTextColor") ?? ""
            return parseNSColor(hexString: hex, defaultColor: NSColor.systemYellow)
        }

        private func resolveGridLineColor() -> NSColor {
            let hex = UserDefaults.standard.string(forKey: "gridOverlayLineColor") ?? ""
            return parseNSColor(hexString: hex, defaultColor: NSColor.systemTeal)
        }

        private func resolveGridBadgeColor() -> NSColor {
            let hex = UserDefaults.standard.string(forKey: "gridOverlayBadgeColor") ?? ""
            return parseNSColor(hexString: hex, defaultColor: NSColor.black)
        }

        private func resolveShowBadges() -> Bool {
            if UserDefaults.standard.object(forKey: "gridOverlayShowPill") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "gridOverlayShowPill")
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MaidenheadVectorOverlay {
                if let existing = self.cachedVectorRenderer {
                    return existing
                }
                let rend = MaidenheadVectorOverlayRenderer(overlay: overlay)
                self.cachedVectorRenderer = rend
                return rend
            }

            if let polyline = overlay as? MKPolyline, polyline.title == "ActiveQSOPath" {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor.systemYellow
                renderer.lineWidth = 3.5
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let spot = annotation as? GlobeSpotAnnotation else { return nil }
            let identifier = spot.bandName == "MY_QTH" ? "GlobeMyQTHMarker" : "GlobeActiveQSOMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: spot, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = spot
            }
            
            if spot.bandName == "MY_QTH" {
                annotationView?.glyphText = "🏠"
                annotationView?.markerTintColor = .systemGreen
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .adaptive
                annotationView?.zPriority = .max
                annotationView?.displayPriority = .required
            } else if spot.bandName == "ACTIVE_QSO" {
                annotationView?.glyphText = "⚡"
                annotationView?.markerTintColor = .systemOrange
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .adaptive
                annotationView?.zPriority = .max
                annotationView?.displayPriority = .required
            }
            return annotationView
        }
    }
}
