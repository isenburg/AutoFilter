import SwiftUI
import MapKit

public struct MaidenheadGridCanvasView: View {
    public let proxy: MapProxy
    public let region: MKCoordinateRegion
    public let workedGrids: Set<String>

    @AppStorage("gridOverlayFontSize") private var gridOverlayFontSize = 11.0
    @AppStorage("gridOverlayShowPill") private var gridOverlayShowPill = true
    @AppStorage("showWorkedGridShading") private var showWorkedGridShading = false
    @AppStorage("gridOverlayTextColor") private var gridOverlayTextColor = ""
    @AppStorage("gridOverlayLineColor") private var gridOverlayLineColor = ""
    @AppStorage("gridOverlayBadgeColor") private var gridOverlayBadgeColor = ""
    @AppStorage("workedGridShadeColor") private var workedGridShadeColorRaw = ""

    public init(proxy: MapProxy, region: MKCoordinateRegion, workedGrids: Set<String> = []) {
        self.proxy = proxy
        self.region = region
        self.workedGrids = workedGrids
    }

    private var gridTextColor: Color {
        gridOverlayTextColor.isEmpty ? Color(red: 1.0, green: 0.85, blue: 0.2) : Color(hex: gridOverlayTextColor, defaultColor: Color(red: 1.0, green: 0.85, blue: 0.2))
    }

    private var gridLineColor: Color {
        gridOverlayLineColor.isEmpty ? Color.cyan : Color(hex: gridOverlayLineColor, defaultColor: Color.cyan)
    }

    private var gridBadgeColor: Color {
        gridOverlayBadgeColor.isEmpty ? Color.black : Color(hex: gridOverlayBadgeColor, defaultColor: Color.black)
    }

    private var workedGridShadeColor: Color {
        workedGridShadeColorRaw.isEmpty ? Color(red: 1.0, green: 0.35, blue: 0.15) : Color(hex: workedGridShadeColorRaw, defaultColor: Color(red: 1.0, green: 0.35, blue: 0.15))
    }

    private func normalizeLongitude(_ lon: Double) -> Double {
        var l = lon.truncatingRemainder(dividingBy: 360.0)
        if l > 180.0 { l -= 360.0 }
        if l <= -180.0 { l += 360.0 }
        return l
    }

    public var body: some View {
        Canvas { context, size in
            let latDelta = region.span.latitudeDelta
            let lonDelta = region.span.longitudeDelta
            guard latDelta > 0.0001 && lonDelta > 0.0001 else { return }

            // 0. Draw Worked Grid Shading (Layer 0 - Bottom)
            if showWorkedGridShading && !workedGrids.isEmpty {
                let shadeCol = workedGridShadeColor.opacity(0.35)
                // Pre-compute visible lat/lon bounds to skip grids outside viewport before expensive proxy.convert()
                let center = region.center
                let viewMinLat = center.latitude - latDelta * 0.9
                let viewMaxLat = center.latitude + latDelta * 0.9
                let viewMinLon = center.longitude - lonDelta * 0.9
                let viewMaxLon = center.longitude + lonDelta * 0.9
                
                for grid4 in workedGrids {
                    if let box = Maidenhead.grid4BoundingBox(grid4) {
                        // Quick reject: skip grids entirely outside the visible viewport
                        if box.maxLat < viewMinLat || box.minLat > viewMaxLat { continue }
                        if box.maxLon < viewMinLon || box.minLon > viewMaxLon { continue }
                        
                        let pTL = CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.minLon)
                        let pTR = CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.maxLon)
                        let pBR = CLLocationCoordinate2D(latitude: box.minLat, longitude: box.maxLon)
                        let pBL = CLLocationCoordinate2D(latitude: box.minLat, longitude: box.minLon)
                        
                        if let ptTL = proxy.convert(pTL, to: .local),
                           let ptTR = proxy.convert(pTR, to: .local),
                           let ptBR = proxy.convert(pBR, to: .local),
                           let ptBL = proxy.convert(pBL, to: .local) {
                            
                            let polyWidth = max(abs(ptTR.x - ptTL.x), abs(ptBR.x - ptBL.x))
                            let polyHeight = max(abs(ptBL.y - ptTL.y), abs(ptBR.y - ptTR.y))
                            
                            // Verhindert Projektions-Streifen (Wrap-Around über die Datumsgrenze/Projektionsränder)
                            if polyWidth < size.width * 0.35 && polyHeight < size.height * 0.35 {
                                var polyPath = Path()
                                polyPath.move(to: ptTL)
                                polyPath.addLine(to: ptTR)
                                polyPath.addLine(to: ptBR)
                                polyPath.addLine(to: ptBL)
                                polyPath.closeSubpath()
                                
                                context.fill(polyPath, with: .color(shadeCol))
                            }
                        }
                    }
                }
            }

            // Calculate approximate pixel dimensions for each Maidenhead tier on screen
            let pxWidth8 = (size.width / lonDelta) * (2.0 / 240.0)
            let pxHeight8 = (size.height / latDelta) * (1.0 / 240.0)

            let pxWidth6 = (size.width / lonDelta) * (2.0 / 24.0)
            let pxHeight6 = (size.height / latDelta) * (1.0 / 24.0)

            let pxWidth4 = (size.width / lonDelta) * 2.0
            let pxHeight4 = (size.height / latDelta) * 1.0

            let lonStep: Double
            let latStep: Double
            let labelLength: Int
            let baseFontSize: Double

            // Choose the finest tier where cells are sufficiently large on screen to avoid crowding
            if pxWidth8 >= 60 && pxHeight8 >= 40 {
                lonStep = 2.0 / 240.0
                latStep = 1.0 / 240.0
                labelLength = 8
                baseFontSize = 8.5
            } else if pxWidth6 >= 60 && pxHeight6 >= 40 {
                lonStep = 2.0 / 24.0
                latStep = 1.0 / 24.0
                labelLength = 6
                baseFontSize = 9.5
            } else if pxWidth4 >= 50 && pxHeight4 >= 35 {
                lonStep = 2.0
                latStep = 1.0
                labelLength = 4
                baseFontSize = 10.5
            } else {
                lonStep = 20.0
                latStep = 10.0
                labelLength = 2
                baseFontSize = 12.0
            }

            let effectiveFontSize = max(7.0, baseFontSize * (gridOverlayFontSize / 11.0))
            let lineCol = gridLineColor
            let textCol = gridTextColor
            let badgeCol = gridBadgeColor

            let center = region.center
            let minLat = max(-85.0, center.latitude - latDelta * 0.85)
            let maxLat = min(85.0, center.latitude + latDelta * 0.85)
            let rawMinLon = center.longitude - lonDelta * 0.85
            let rawMaxLon = center.longitude + lonDelta * 0.85

            let startLat = floor(minLat / latStep) * latStep
            let endLat = ceil(maxLat / latStep) * latStep
            let startLon = floor(rawMinLon / lonStep) * lonStep
            let endLon = ceil(rawMaxLon / lonStep) * lonStep

            // 1. Draw Latitude Lines (horizontal)
            var lat = startLat
            while lat <= endLat {
                let normCenterLon = normalizeLongitude(center.longitude)
                let pRef = CLLocationCoordinate2D(latitude: lat, longitude: normCenterLon)
                if let ptRef = proxy.convert(pRef, to: .local) {
                    var path = Path()
                    path.move(to: CGPoint(x: -100, y: ptRef.y))
                    path.addLine(to: CGPoint(x: size.width + 100, y: ptRef.y))
                    let isMajor = (labelLength == 4 && abs(lat.truncatingRemainder(dividingBy: 10.0)) < 0.0001) ||
                                  (labelLength == 6 && abs(lat.truncatingRemainder(dividingBy: 1.0)) < 0.0001)
                    let lineColor: Color = isMajor ? lineCol.opacity(0.85) : lineCol.opacity(0.4)
                    let lineWidth: CGFloat = isMajor ? 1.5 : 0.8
                    context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
                }
                lat += latStep
            }

            // 2. Draw Longitude Lines (vertical)
            var lon = startLon
            while lon <= endLon {
                let normLon = normalizeLongitude(lon)
                let p1 = CLLocationCoordinate2D(latitude: max(-85.0, minLat - latStep), longitude: normLon)
                let p2 = CLLocationCoordinate2D(latitude: min(85.0, maxLat + latStep), longitude: normLon)
                if let pt1 = proxy.convert(p1, to: .local),
                   let pt2 = proxy.convert(p2, to: .local) {
                    var path = Path()
                    path.move(to: pt1)
                    path.addLine(to: pt2)
                    let isMajor = (labelLength == 4 && abs(normLon.truncatingRemainder(dividingBy: 20.0)) < 0.0001) ||
                                  (labelLength == 6 && abs(normLon.truncatingRemainder(dividingBy: 2.0)) < 0.0001)
                    let lineColor: Color = isMajor ? lineCol.opacity(0.85) : lineCol.opacity(0.4)
                    let lineWidth: CGFloat = isMajor ? 1.5 : 0.8
                    context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
                }
                lon += lonStep
            }

            // 3. Draw Centered Cell Labels with High-Contrast Background Badges
            var currentLat = startLat
            while currentLat < endLat {
                var currentLon = startLon
                while currentLon < endLon {
                    let cLat = currentLat + latStep * 0.5
                    let cLon = currentLon + lonStep * 0.5
                    let normCLon = normalizeLongitude(cLon)
                    if cLat >= -85.0 && cLat <= 85.0 {
                        let coord = CLLocationCoordinate2D(latitude: cLat, longitude: normCLon)
                        if let pt = proxy.convert(coord, to: .local) {
                            if pt.x >= -30 && pt.x <= size.width + 30 && pt.y >= -20 && pt.y <= size.height + 20 {
                                let locText = Maidenhead.latLonToLocator(lat: cLat, lon: normCLon, length: labelLength)
                                let resolvedText = Text(locText)
                                    .font(.system(size: effectiveFontSize, weight: .black, design: .monospaced))
                                    .foregroundColor(textCol)
                                
                                if gridOverlayShowPill {
                                    let approxWidth = CGFloat(locText.count) * (effectiveFontSize * 0.65) + 8.0
                                    let approxHeight = effectiveFontSize + 5.0
                                    let bgRect = CGRect(
                                        x: pt.x - approxWidth / 2.0,
                                        y: pt.y - approxHeight / 2.0,
                                        width: approxWidth,
                                        height: approxHeight
                                    )
                                    let bgPath = Path(roundedRect: bgRect, cornerRadius: 4)
                                    context.fill(bgPath, with: .color(badgeCol.opacity(0.55)))
                                    context.stroke(bgPath, with: .color(lineCol.opacity(0.35)), lineWidth: 0.75)
                                }
                                
                                context.draw(resolvedText, at: pt, anchor: .center)
                            }
                        }
                    }
                    currentLon += lonStep
                }
                currentLat += latStep
            }
        }
    }
}

public class MaidenheadGridGenerator {
    public static func resolutionText(for latDelta: Double, lonDelta: Double = 1.0, size: CGSize = CGSize(width: 800, height: 600)) -> String {
        let pxHeight8 = (size.height / latDelta) * (1.0 / 240.0)
        let pxHeight6 = (size.height / latDelta) * (1.0 / 24.0)
        let pxHeight4 = (size.height / latDelta) * 1.0
        
        if pxHeight8 >= 40 {
            return "8-Stellen (Extended)"
        } else if pxHeight6 >= 40 {
            return "6-Stellen (Subsquare)"
        } else if pxHeight4 >= 35 {
            return "4-Stellen (Square)"
        } else {
            return "2-Stellen (Field)"
        }
    }
}

public struct GridOverlaySettingsBar: View {
    @AppStorage("gridOverlayFontSize") private var gridOverlayFontSize = 11.0
    @AppStorage("gridOverlayShowPill") private var gridOverlayShowPill = true

    public init() {}

    private var gridTextColorBinding: Binding<Color> {
        Binding(
            get: {
                let hex = UserDefaults.standard.string(forKey: "gridOverlayTextColor") ?? ""
                return hex.isEmpty ? Color(red: 1.0, green: 0.85, blue: 0.2) : Color(hex: hex, defaultColor: Color(red: 1.0, green: 0.85, blue: 0.2))
            },
            set: { newColor in
                if let hex = newColor.toHex() {
                    UserDefaults.standard.set(hex, forKey: "gridOverlayTextColor")
                }
            }
        )
    }

    private var gridLineColorBinding: Binding<Color> {
        Binding(
            get: {
                let hex = UserDefaults.standard.string(forKey: "gridOverlayLineColor") ?? ""
                return hex.isEmpty ? Color.cyan : Color(hex: hex, defaultColor: Color.cyan)
            },
            set: { newColor in
                if let hex = newColor.toHex() {
                    UserDefaults.standard.set(hex, forKey: "gridOverlayLineColor")
                }
            }
        )
    }

    private var gridBadgeColorBinding: Binding<Color> {
        Binding(
            get: {
                let hex = UserDefaults.standard.string(forKey: "gridOverlayBadgeColor") ?? ""
                return hex.isEmpty ? Color.black : Color(hex: hex, defaultColor: Color.black)
            },
            set: { newColor in
                if let hex = newColor.toHex() {
                    UserDefaults.standard.set(hex, forKey: "gridOverlayBadgeColor")
                }
            }
        )
    }

    private var workedGridShadeColorBinding: Binding<Color> {
        Binding(
            get: {
                let hex = UserDefaults.standard.string(forKey: "workedGridShadeColor") ?? ""
                return hex.isEmpty ? Color(red: 1.0, green: 0.35, blue: 0.15) : Color(hex: hex, defaultColor: Color(red: 1.0, green: 0.35, blue: 0.15))
            },
            set: { newColor in
                if let hex = newColor.toHex() {
                    UserDefaults.standard.set(hex, forKey: "workedGridShadeColor")
                }
            }
        )
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "grid")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)

                Text("Gitter:")
                    .font(.system(size: 10, weight: .bold))
            }

            // Font size stepper
            HStack(spacing: 4) {
                Button(action: { if gridOverlayFontSize > 8 { gridOverlayFontSize -= 1 } }) {
                    Text("A-").font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)

                Text("\(Int(gridOverlayFontSize))pt")
                    .font(.system(size: 9, weight: .black, design: .monospaced))

                Button(action: { if gridOverlayFontSize < 22 { gridOverlayFontSize += 1 } }) {
                    Text("A+").font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(5)

            // Text color picker
            ColorPicker("Text", selection: gridTextColorBinding)
                .font(.system(size: 10, weight: .medium))

            // Line color picker
            ColorPicker("Linie", selection: gridLineColorBinding)
                .font(.system(size: 10, weight: .medium))

            // Badge color picker & toggle
            if gridOverlayShowPill {
                ColorPicker("Badge", selection: gridBadgeColorBinding)
                    .font(.system(size: 10, weight: .medium))
            }

            ColorPicker("Gearbeitet", selection: workedGridShadeColorBinding)
                .font(.system(size: 10, weight: .medium))

            Toggle("Badges", isOn: $gridOverlayShowPill)
                .font(.system(size: 10, weight: .medium))
                .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

public struct Maidenhead {
    public static func grid4BoundingBox(_ grid4: String) -> (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)? {
        let clean = grid4.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count >= 4 else { return nil }
        let bytes = Array(clean.utf8)
        guard bytes[0] >= 65 && bytes[0] <= 82, // A-R
              bytes[1] >= 65 && bytes[1] <= 82, // A-R
              bytes[2] >= 48 && bytes[2] <= 57, // 0-9
              bytes[3] >= 48 && bytes[3] <= 57  // 0-9
        else { return nil }
        
        let minLon = Double(bytes[0] - 65) * 20.0 - 180.0 + Double(bytes[2] - 48) * 2.0
        let minLat = Double(bytes[1] - 65) * 10.0 - 90.0 + Double(bytes[3] - 48) * 1.0
        let maxLon = minLon + 2.0
        let maxLat = minLat + 1.0
        return (minLat, maxLat, minLon, maxLon)
    }

    public static func extractGrid(from message: String) -> String? {
        let tokens = message.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased() }
        let gridPattern = "^[A-R]{2}[0-9]{2}([A-X]{2})?$"
        for token in tokens.reversed() {
            if token.range(of: gridPattern, options: .regularExpression) != nil {
                return token
            }
        }
        return nil
    }
    
    public static func locatorToLatLon(_ grid: String) -> (lat: Double, lon: Double)? {
        let clean = grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count >= 4 else { return nil }
        
        let bytes = Array(clean.utf8)
        guard bytes[0] >= 65 && bytes[0] <= 82, // A-R
              bytes[1] >= 65 && bytes[1] <= 82, // A-R
              bytes[2] >= 48 && bytes[2] <= 57, // 0-9
              bytes[3] >= 48 && bytes[3] <= 57  // 0-9
        else { return nil }
        
        let lonField = Double(bytes[0] - 65) * 20.0 - 180.0
        let latField = Double(bytes[1] - 65) * 10.0 - 90.0
        let lonSquare = Double(bytes[2] - 48) * 2.0
        let latSquare = Double(bytes[3] - 48) * 1.0
        
        var lon = lonField + lonSquare + 1.0 // center of square
        var lat = latField + latSquare + 0.5
        
        if clean.count >= 6 {
            guard bytes[4] >= 65 && bytes[4] <= 88, // A-X
                  bytes[5] >= 65 && bytes[5] <= 88  // A-X
            else { return (lat, lon) }
            
            let lonSub = Double(bytes[4] - 65) * (2.0 / 24.0)
            let latSub = Double(bytes[5] - 65) * (1.0 / 24.0)
            lon = lonField + lonSquare + lonSub + (1.0 / 24.0)
            lat = latField + latSquare + latSub + (0.5 / 24.0)
            
            if clean.count >= 8 {
                guard bytes[6] >= 48 && bytes[6] <= 57, // 0-9
                      bytes[7] >= 48 && bytes[7] <= 57  // 0-9
                else { return (lat, lon) }
                
                let lonExt = Double(bytes[6] - 48) * (2.0 / 240.0)
                let latExt = Double(bytes[7] - 48) * (1.0 / 240.0)
                lon = lonField + lonSquare + lonSub + lonExt + (1.0 / 240.0)
                lat = latField + latSquare + latSub + latExt + (0.5 / 240.0)
            }
        }
        
        return (lat, lon)
    }

    public static func latLonToLocator(lat: Double, lon: Double, length: Int = 8) -> String {
        var normLon = lon
        while normLon < -180.0 { normLon += 360.0 }
        while normLon >= 180.0 { normLon -= 360.0 }
        normLon += 180.0
        
        var normLat = lat
        if normLat < -90.0 { normLat = -90.0 }
        if normLat > 90.0 { normLat = 90.0 }
        normLat += 90.0
        
        let fLon = Int(floor(normLon / 20.0))
        let fLat = Int(floor(normLat / 10.0))
        let char1 = Character(UnicodeScalar(65 + max(0, min(17, fLon)))!)
        let char2 = Character(UnicodeScalar(65 + max(0, min(17, fLat)))!)
        
        guard length > 2 else { return String([char1, char2]) }
        
        let rLon = normLon - Double(fLon) * 20.0
        let rLat = normLat - Double(fLat) * 10.0
        let sLon = Int(floor(rLon / 2.0))
        let sLat = Int(floor(rLat / 1.0))
        let char3 = Character(UnicodeScalar(48 + max(0, min(9, sLon)))!)
        let char4 = Character(UnicodeScalar(48 + max(0, min(9, sLat)))!)
        
        guard length > 4 else { return String([char1, char2, char3, char4]) }
        
        let rLon2 = rLon - Double(sLon) * 2.0
        let rLat2 = rLat - Double(sLat) * 1.0
        let subLon = Int(floor(rLon2 / (2.0 / 24.0)))
        let subLat = Int(floor(rLat2 / (1.0 / 24.0)))
        let char5 = Character(UnicodeScalar(97 + max(0, min(23, subLon)))!).uppercased()
        let char6 = Character(UnicodeScalar(97 + max(0, min(23, subLat)))!).uppercased()
        
        guard length > 6 else { return "\(char1)\(char2)\(char3)\(char4)\(char5)\(char6)" }
        
        let rLon3 = rLon2 - Double(subLon) * (2.0 / 24.0)
        let rLat3 = rLat2 - Double(subLat) * (1.0 / 24.0)
        let extLon = Int(floor(rLon3 / (2.0 / 240.0)))
        let extLat = Int(floor(rLat3 / (1.0 / 240.0)))
        let char7 = Character(UnicodeScalar(48 + max(0, min(9, extLon)))!)
        let char8 = Character(UnicodeScalar(48 + max(0, min(9, extLat)))!)
        
        return "\(char1)\(char2)\(char3)\(char4)\(char5)\(char6)\(char7)\(char8)"
    }
    
    public static func distanceKm(from grid1: String, to grid2: String) -> Double? {
        guard let p1 = locatorToLatLon(grid1), let p2 = locatorToLatLon(grid2) else { return nil }
        let R = 6371.0 // Earth radius in km
        let dLat = (p2.lat - p1.lat) * .pi / 180.0
        let dLon = (p2.lon - p1.lon) * .pi / 180.0
        let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
                cos(p1.lat * .pi / 180.0) * cos(p2.lat * .pi / 180.0) *
                sin(dLon / 2.0) * sin(dLon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return R * c
    }

    public static func bearingDeg(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180.0
        let lon1 = from.longitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0
        let lon2 = to.longitude * .pi / 180.0
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        let degrees = radians * 180.0 / .pi
        return (degrees + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    public static func distanceKm(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let R = 6371.0
        let dLat = (to.latitude - from.latitude) * .pi / 180.0
        let dLon = (to.longitude - from.longitude) * .pi / 180.0
        let a = sin(dLat / 2.0) * sin(dLat / 2.0) +
                cos(from.latitude * .pi / 180.0) * cos(to.latitude * .pi / 180.0) *
                sin(dLon / 2.0) * sin(dLon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return R * c
    }

    public static func greatCirclePath(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, steps: Int = 60) -> [CLLocationCoordinate2D] {
        let lat1 = start.latitude * .pi / 180.0
        let lon1 = start.longitude * .pi / 180.0
        let lat2 = end.latitude * .pi / 180.0
        let lon2 = end.longitude * .pi / 180.0

        let x1 = cos(lat1) * cos(lon1)
        let y1 = cos(lat1) * sin(lon1)
        let z1 = sin(lat1)

        let x2 = cos(lat2) * cos(lon2)
        let y2 = cos(lat2) * sin(lon2)
        let z2 = sin(lat2)

        let dot = max(-1.0, min(1.0, x1 * x2 + y1 * y2 + z1 * z2))
        let omega = acos(dot)

        guard omega > 1e-6 else {
            return [start, end]
        }

        let sinOmega = sin(omega)
        var result: [CLLocationCoordinate2D] = []
        result.reserveCapacity(steps + 1)

        for i in 0...steps {
            let f = Double(i) / Double(steps)
            let a = sin((1.0 - f) * omega) / sinOmega
            let b = sin(f * omega) / sinOmega

            let x = a * x1 + b * x2
            let y = a * y1 + b * y2
            let z = a * z1 + b * z2

            let lat = atan2(z, sqrt(x * x + y * y)) * 180.0 / .pi
            let lon = atan2(y, x) * 180.0 / .pi

            result.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }

        return result
    }
}
