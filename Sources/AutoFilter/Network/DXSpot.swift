import Foundation

struct DXSpot: Identifiable, Hashable {
    let id = UUID()
    let dxCall: String
    let country: String
    let continent: String
    let cqZone: Int?
    let ituZone: Int?
    let frequency: Double
    let spotter: String
    let timestamp: Date
    let rawLine: String
    var isFiltered: Bool = false
    var comment: String = ""
    var isWsjt: Bool = false
    let latitude: Double?
    let longitude: Double?
    
    init(dxCall: String, country: String, continent: String = "Unknown",
         cqZone: Int? = nil, ituZone: Int? = nil,
         frequency: Double, spotter: String,
         timestamp: Date, rawLine: String, isFiltered: Bool = false,
         comment: String = "", isWsjt: Bool = false,
         latitude: Double? = nil, longitude: Double? = nil) {
        self.dxCall = dxCall
        self.country = country
        self.continent = continent
        self.cqZone = cqZone
        self.ituZone = ituZone
        self.frequency = frequency
        self.spotter = spotter
        self.timestamp = timestamp
        self.rawLine = rawLine
        self.isFiltered = isFiltered
        self.comment = comment
        self.isWsjt = isWsjt
        self.latitude = latitude
        self.longitude = longitude
    }
}
