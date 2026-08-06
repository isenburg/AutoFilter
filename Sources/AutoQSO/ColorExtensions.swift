import SwiftUI

extension Color {
    init(hex: String, defaultColor: Color = .primary) {
        let r, g, b, a: Double
        
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6 || cleaned.count == 8 else {
            self = defaultColor
            return
        }
        
        let scanner = Scanner(string: cleaned)
        var hexNumber: UInt64 = 0
        
        if scanner.scanHexInt64(&hexNumber) {
            if cleaned.count == 6 {
                r = Double((hexNumber & 0xff0000) >> 16) / 255.0
                g = Double((hexNumber & 0x00ff00) >> 8) / 255.0
                b = Double(hexNumber & 0x0000ff) / 255.0
                a = 1.0
            } else {
                r = Double((hexNumber & 0xff000000) >> 24) / 255.0
                g = Double((hexNumber & 0x00ff0000) >> 16) / 255.0
                b = Double((hexNumber & 0x0000ff00) >> 8) / 255.0
                a = Double(hexNumber & 0x000000ff) / 255.0
            }
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        } else {
            self = defaultColor
        }
    }
    
    func toHex() -> String? {
        guard let cgColor = self.cgColor else {
            let nsColor = NSColor(self)
            guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return nil }
            let r = Int(rgbColor.redComponent * 255.0)
            let g = Int(rgbColor.greenComponent * 255.0)
            let b = Int(rgbColor.blueComponent * 255.0)
            let a = Int(rgbColor.alphaComponent * 255.0)
            if a == 255 {
                return String(format: "#%02X%02X%02X", r, g, b)
            } else {
                return String(format: "#%02X%02X%02X%02X", r, g, b, a)
            }
        }
        
        let components = cgColor.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255.0)
        let g = components.count > 1 ? Int(components[1] * 255.0) : r
        let b = components.count > 2 ? Int(components[2] * 255.0) : r
        let a = components.count > 3 ? Int(components[3] * 255.0) : 255
        
        if a == 255 {
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
    }
}
