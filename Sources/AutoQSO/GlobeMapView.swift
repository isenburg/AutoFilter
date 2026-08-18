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

struct GlobeMapViewContainer: NSViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var showGridOverlay: Bool
    var workedGrids: Set<String> = []
    var showWorkedGridShading: Bool = false
    var spotItems: [GlobeSpotItem] = []
    var activeQSOPath: ActiveQSOPath? = nil
    var onSelectGrid: ((String) -> Void)? = nil

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let config = MKHybridMapConfiguration(elevationStyle: .realistic)
        mapView.preferredConfiguration = config
        mapView.region = region
        mapView.delegate = context.coordinator
        
        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(clickGesture)
        
        // Initial overlays & annotations
        context.coordinator.applyOverlays(mapView, showGrid: showGridOverlay, workedGrids: workedGrids, showShading: showWorkedGridShading, activeQSOPath: activeQSOPath, region: region)
        context.coordinator.applyAnnotations(mapView, spotItems: spotItems, activeQSOPath: activeQSOPath)
        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        let coord = context.coordinator

        if !(mapView.preferredConfiguration is MKHybridMapConfiguration) {
            let config = MKHybridMapConfiguration(elevationStyle: .realistic)
            mapView.preferredConfiguration = config
        }

        // Dirty-check overlays: only rebuild if inputs changed
        let overlaysDirty = coord.lastShowGrid != showGridOverlay
            || coord.lastShowShading != showWorkedGridShading
            || coord.lastWorkedGrids != workedGrids
            || coord.lastActiveQSOPath != activeQSOPath
        
        if overlaysDirty {
            coord.applyOverlays(mapView, showGrid: showGridOverlay, workedGrids: workedGrids, showShading: showWorkedGridShading, activeQSOPath: activeQSOPath, region: region)
        }

        // Dirty-check annotations: only rebuild if spot items or activeQSOPath changed
        if coord.lastSpotItems != spotItems || coord.lastActiveQSOPath != activeQSOPath {
            coord.applyAnnotations(mapView, spotItems: spotItems, activeQSOPath: activeQSOPath)
        }
    }

    static func generateWorkedGridPolygons(workedGrids: Set<String>) -> [MKPolygon] {
        var polygons: [MKPolygon] = []
        polygons.reserveCapacity(workedGrids.count)
        for grid4 in workedGrids {
            if let box = Maidenhead.grid4BoundingBox(grid4) {
                let coords = [
                    CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.minLon),
                    CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.maxLon),
                    CLLocationCoordinate2D(latitude: box.minLat, longitude: box.maxLon),
                    CLLocationCoordinate2D(latitude: box.minLat, longitude: box.minLon)
                ]
                let polygon = MKPolygon(coordinates: coords, count: 4)
                polygon.title = "WorkedGrid"
                polygons.append(polygon)
            }
        }
        return polygons
    }

    static func generateGridPolylines(for region: MKCoordinateRegion) -> [MKPolyline] {
        var polylines: [MKPolyline] = []
        let latDelta = region.span.latitudeDelta

        let lonStep: Double
        let latStep: Double

        if latDelta > 25.0 {
            lonStep = 20.0
            latStep = 10.0
        } else if latDelta > 3.0 {
            lonStep = 2.0
            latStep = 1.0
        } else {
            lonStep = 2.0 / 24.0
            latStep = 1.0 / 24.0
        }

        var lat = -80.0
        while lat <= 80.0 {
            var coords: [CLLocationCoordinate2D] = []
            var lon = -180.0
            while lon <= 180.0 {
                coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
                lon += 10.0
            }
            polylines.append(MKPolyline(coordinates: coords, count: coords.count))
            lat += latStep
        }

        var lon = -180.0
        while lon <= 180.0 {
            var coords: [CLLocationCoordinate2D] = []
            var l = -80.0
            while l <= 80.0 {
                coords.append(CLLocationCoordinate2D(latitude: l, longitude: lon))
                l += 5.0
            }
            polylines.append(MKPolyline(coordinates: coords, count: coords.count))
            lon += lonStep
        }

        return polylines
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GlobeMapViewContainer

        // Dirty-flag state for overlays
        var lastShowGrid: Bool = false
        var lastShowShading: Bool = false
        var lastWorkedGrids: Set<String> = []

        // Dirty-flag state for annotations
        var lastSpotItems: [GlobeSpotItem] = []
        var lastActiveQSOPath: ActiveQSOPath? = nil

        // Region debounce
        private var regionDebounceWorkItem: DispatchWorkItem?

        // Cached worked-grid shade color
        private var cachedShadeColor: NSColor?
        private var cachedShadeHex: String?

        init(_ parent: GlobeMapViewContainer) {
            self.parent = parent
        }

        func applyOverlays(_ mapView: MKMapView, showGrid: Bool, workedGrids: Set<String>, showShading: Bool, activeQSOPath: ActiveQSOPath?, region: MKCoordinateRegion) {
            mapView.removeOverlays(mapView.overlays)

            if showShading && !workedGrids.isEmpty {
                let polygons = GlobeMapViewContainer.generateWorkedGridPolygons(workedGrids: workedGrids)
                mapView.addOverlays(polygons, level: .aboveRoads)
            }

            if showGrid {
                let polylines = GlobeMapViewContainer.generateGridPolylines(for: region)
                mapView.addOverlays(polylines, level: .aboveLabels)
            }

            if let path = activeQSOPath {
                let pathCoords = Maidenhead.greatCirclePath(from: path.myCoordinate, to: path.targetCoordinate, steps: 60)
                let polyline = MKPolyline(coordinates: pathCoords, count: pathCoords.count)
                polyline.title = "ActiveQSOPath"
                mapView.addOverlay(polyline, level: .aboveLabels)
            }

            lastShowGrid = showGrid
            lastShowShading = showShading
            lastWorkedGrids = workedGrids
            lastActiveQSOPath = activeQSOPath
        }

        func applyAnnotations(_ mapView: MKMapView, spotItems: [GlobeSpotItem], activeQSOPath: ActiveQSOPath?) {
            mapView.removeAnnotations(mapView.annotations)
            var annotations = spotItems.map { GlobeSpotAnnotation(item: $0) }
            
            if let path = activeQSOPath {
                let mySpot = GlobeSpotItem(
                    id: "MY_QTH",
                    title: "MY QTH",
                    subtitle: path.myGrid,
                    latitude: path.myCoordinate.latitude,
                    longitude: path.myCoordinate.longitude,
                    bandName: "MY_QTH"
                )
                let targetSpot = GlobeSpotItem(
                    id: "TARGET_\(path.targetCall)",
                    title: path.targetCall,
                    subtitle: path.targetGrid ?? "",
                    latitude: path.targetCoordinate.latitude,
                    longitude: path.targetCoordinate.longitude,
                    bandName: "ACTIVE_QSO"
                )
                annotations.append(GlobeSpotAnnotation(item: mySpot))
                annotations.append(GlobeSpotAnnotation(item: targetSpot))
            }
            
            mapView.addAnnotations(annotations)
            lastSpotItems = spotItems
            lastActiveQSOPath = activeQSOPath
        }

        // Debounced region update: only fires after 0.2s of no further region changes
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            regionDebounceWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.parent.region = mapView.region
            }
            regionDebounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        }

        @objc func handleMapTap(_ gesture: NSClickGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            let grid4 = Maidenhead.latLonToLocator(lat: coord.latitude, lon: coord.longitude, length: 4)
            parent.onSelectGrid?(grid4)
        }

        private func resolveShadeColor() -> NSColor {
            let hex = UserDefaults.standard.string(forKey: "workedGridShadeColor") ?? ""
            if hex == cachedShadeHex, let cached = cachedShadeColor {
                return cached
            }
            let color = parseNSColor(hexString: hex, defaultColor: NSColor(red: 1.0, green: 0.35, blue: 0.15, alpha: 1.0))
            cachedShadeHex = hex
            cachedShadeColor = color
            return color
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline, polyline.title == "ActiveQSOPath" {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor.systemYellow
                renderer.lineWidth = 3.5
                return renderer
            }

            if let polygon = overlay as? MKPolygon, polygon.title == "WorkedGrid" {
                let renderer = MKPolygonRenderer(polygon: polygon)
                let shadeColor = resolveShadeColor()
                renderer.fillColor = shadeColor.withAlphaComponent(0.40)
                renderer.strokeColor = shadeColor.withAlphaComponent(0.75)
                renderer.lineWidth = 0.8
                return renderer
            }

            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = NSColor.cyan.withAlphaComponent(0.55)
                renderer.lineWidth = 1.2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let spot = annotation as? GlobeSpotAnnotation else { return nil }
            let identifier = "GlobeSpotMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: spot, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = spot
            }
            
            if spot.bandName == "MY_QTH" {
                annotationView?.glyphText = "🏠"
                annotationView?.markerTintColor = .systemGreen
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .adaptive
            } else if spot.bandName == "ACTIVE_QSO" {
                annotationView?.glyphText = "⚡"
                annotationView?.markerTintColor = .systemOrange
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .adaptive
            } else {
                annotationView?.glyphText = ""
                annotationView?.markerTintColor = nsColorForBand(spot.bandName)
                annotationView?.titleVisibility = .visible
                annotationView?.subtitleVisibility = .adaptive
            }
            return annotationView
        }
    }
}
