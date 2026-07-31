import Foundation

public struct Maidenhead {
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
        }
        
        return (lat, lon)
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
