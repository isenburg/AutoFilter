import SwiftUI
import MapKit

public struct MaidenheadGridCanvasView: View {
    public let proxy: MapProxy
    public let region: MKCoordinateRegion
    public let workedGrids: Set<String>

    @AppStorage("gridOverlayFontSize") private var gridOverlayFontSize = 11.0
    @AppStorage("gridOverlayShowPill") private var gridOverlayShowPill = true
    @AppStorage("showWorkedGridShading") private var showWorkedGridShading = false

    public init(proxy: MapProxy, region: MKCoordinateRegion, workedGrids: Set<String> = []) {
        self.proxy = proxy
        self.region = region
        self.workedGrids = workedGrids
    }

    private var gridTextColor: Color {
        let hex = UserDefaults.standard.string(forKey: "gridOverlayTextColor") ?? ""
        return hex.isEmpty ? Color(red: 1.0, green: 0.85, blue: 0.2) : Color(hex: hex, defaultColor: Color(red: 1.0, green: 0.85, blue: 0.2))
    }

    private var gridLineColor: Color {
        let hex = UserDefaults.standard.string(forKey: "gridOverlayLineColor") ?? ""
        return hex.isEmpty ? Color.cyan : Color(hex: hex, defaultColor: Color.cyan)
    }

    private var gridBadgeColor: Color {
        let hex = UserDefaults.standard.string(forKey: "gridOverlayBadgeColor") ?? ""
        return hex.isEmpty ? Color.black : Color(hex: hex, defaultColor: Color.black)
    }

    private var workedGridShadeColor: Color {
        let hex = UserDefaults.standard.string(forKey: "workedGridShadeColor") ?? ""
        return hex.isEmpty ? Color(red: 1.0, green: 0.35, blue: 0.15) : Color(hex: hex, defaultColor: Color(red: 1.0, green: 0.35, blue: 0.15))
    }

    public var body: some View {
        Canvas { context, size in
            let latDelta = region.span.latitudeDelta
            let lonDelta = region.span.longitudeDelta
            guard latDelta > 0.0001 && lonDelta > 0.0001 else { return }

            // 0. Draw Worked Grid Shading (Layer 0 - Bottom)
            if showWorkedGridShading && !workedGrids.isEmpty {
                let shadeCol = workedGridShadeColor.opacity(0.35)
                for grid4 in workedGrids {
                    if let box = Maidenhead.grid4BoundingBox(grid4) {
                        let pTL = CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.minLon)
                        let pTR = CLLocationCoordinate2D(latitude: box.maxLat, longitude: box.maxLon)
                        let pBR = CLLocationCoordinate2D(latitude: box.minLat, longitude: box.maxLon)
                        let pBL = CLLocationCoordinate2D(latitude: box.minLat, longitude: box.minLon)
                        
                        if let ptTL = proxy.convert(pTL, to: .local),
                           let ptTR = proxy.convert(pTR, to: .local),
                           let ptBR = proxy.convert(pBR, to: .local),
                           let ptBL = proxy.convert(pBL, to: .local) {
                            
                            // Nur im/am sichtbaren Bereich zeichnen
                            let margin: CGFloat = 100
                            if (ptTL.x >= -margin || ptTR.x >= -margin || ptBL.x >= -margin || ptBR.x >= -margin) &&
                               (ptTL.x <= size.width + margin || ptTR.x <= size.width + margin || ptBL.x <= size.width + margin || ptBR.x <= size.width + margin) &&
                               (ptTL.y >= -margin || ptTR.y >= -margin || ptBL.y >= -margin || ptBR.y >= -margin) &&
                               (ptTL.y <= size.height + margin || ptTR.y <= size.height + margin || ptBL.y <= size.height + margin || ptBR.y <= size.height + margin) {
                                
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
            }

            let lonStep: Double
            let latStep: Double
            let labelLength: Int
            let baseFontSize: Double

            if latDelta > 20.0 {
                lonStep = 20.0
                latStep = 10.0
                labelLength = 2
                baseFontSize = 12
            } else if latDelta > 2.0 {
                lonStep = 2.0
                latStep = 1.0
                labelLength = 4
                baseFontSize = 10
            } else if latDelta > 0.2 {
                lonStep = 2.0 / 24.0
                latStep = 1.0 / 24.0
                labelLength = 6
                baseFontSize = 9
            } else {
                lonStep = 2.0 / 240.0
                latStep = 1.0 / 240.0
                labelLength = 8
                baseFontSize = 8
            }

            let effectiveFontSize = max(7.0, baseFontSize * (gridOverlayFontSize / 11.0))
            let lineCol = gridLineColor
            let textCol = gridTextColor
            let badgeCol = gridBadgeColor

            let center = region.center
            let minLat = max(-85.0, center.latitude - latDelta * 0.75)
            let maxLat = min(85.0, center.latitude + latDelta * 0.75)
            let minLon = max(-180.0, center.longitude - lonDelta * 0.75)
            let maxLon = min(180.0, center.longitude + lonDelta * 0.75)

            let startLat = floor(minLat / latStep) * latStep
            let endLat = ceil(maxLat / latStep) * latStep
            let startLon = floor(minLon / lonStep) * lonStep
            let endLon = ceil(maxLon / lonStep) * lonStep

            // 1. Draw Latitude Lines (horizontal)
            var lat = startLat
            while lat <= endLat {
                let p1 = CLLocationCoordinate2D(latitude: lat, longitude: max(-180.0, minLon - lonStep))
                let p2 = CLLocationCoordinate2D(latitude: lat, longitude: min(180.0, maxLon + lonStep))
                if let pt1 = proxy.convert(p1, to: .local),
                   let pt2 = proxy.convert(p2, to: .local) {
                    var path = Path()
                    path.move(to: pt1)
                    path.addLine(to: pt2)
                    let isMajor = (labelLength == 4 && abs(lat.truncatingRemainder(dividingBy: 10.0)) < 0.0001) ||
                                  (labelLength == 6 && abs(lat.truncatingRemainder(dividingBy: 1.0)) < 0.0001)
                    let lineColor: Color = isMajor ? lineCol.opacity(0.85) : lineCol.opacity(0.45)
                    let lineWidth: CGFloat = isMajor ? 1.8 : 1.0
                    context.stroke(path, with: .color(lineColor), lineWidth: lineWidth)
                }
                lat += latStep
            }

            // 2. Draw Longitude Lines (vertical)
            var lon = startLon
            while lon <= endLon {
                let p1 = CLLocationCoordinate2D(latitude: max(-85.0, minLat - latStep), longitude: lon)
                let p2 = CLLocationCoordinate2D(latitude: min(85.0, maxLat + latStep), longitude: lon)
                if let pt1 = proxy.convert(p1, to: .local),
                   let pt2 = proxy.convert(p2, to: .local) {
                    var path = Path()
                    path.move(to: pt1)
                    path.addLine(to: pt2)
                    let isMajor = (labelLength == 4 && abs(lon.truncatingRemainder(dividingBy: 20.0)) < 0.0001) ||
                                  (labelLength == 6 && abs(lon.truncatingRemainder(dividingBy: 2.0)) < 0.0001)
                    let lineColor: Color = isMajor ? lineCol.opacity(0.85) : lineCol.opacity(0.45)
                    let lineWidth: CGFloat = isMajor ? 1.8 : 1.0
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
                    if cLat >= -85.0 && cLat <= 85.0 && cLon >= -180.0 && cLon <= 180.0 {
                        let coord = CLLocationCoordinate2D(latitude: cLat, longitude: cLon)
                        if let pt = proxy.convert(coord, to: .local) {
                            if pt.x >= -30 && pt.x <= size.width + 30 && pt.y >= -20 && pt.y <= size.height + 20 {
                                let locText = Maidenhead.latLonToLocator(lat: cLat, lon: cLon, length: labelLength)
                                let resolvedText = Text(locText)
                                    .font(.system(size: effectiveFontSize, weight: .black, design: .monospaced))
                                    .foregroundColor(textCol)
                                
                                if gridOverlayShowPill {
                                    let approxWidth = CGFloat(locText.count) * (effectiveFontSize * 0.65) + 8.0
                                    let approxHeight = effectiveFontSize + 6.0
                                    let bgRect = CGRect(
                                        x: pt.x - approxWidth / 2.0,
                                        y: pt.y - approxHeight / 2.0,
                                        width: approxWidth,
                                        height: approxHeight
                                    )
                                    let bgPath = Path(roundedRect: bgRect, cornerRadius: 4)
                                    context.fill(bgPath, with: .color(badgeCol.opacity(0.75)))
                                    context.stroke(bgPath, with: .color(lineCol.opacity(0.5)), lineWidth: 0.8)
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
    public static func resolutionText(for latDelta: Double) -> String {
        if latDelta > 20.0 {
            return "2-Stellen (Field)"
        } else if latDelta > 2.0 {
            return "4-Stellen (Square)"
        } else if latDelta > 0.2 {
            return "6-Stellen (Subsquare)"
        } else {
            return "8-Stellen (Extended Subsquare)"
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
}
