import Foundation

class PrefixMatcher {
    static let shared = PrefixMatcher()
    
    private let lock = NSLock()
    private var database: [String: String] = [:]
    private var continentDatabase: [String: String] = [:]
    private var cqZoneDatabase: [String: Int] = [:]
    private var ituZoneDatabase: [String: Int] = [:]
    private var countryCoordinates: [String: (latitude: Double, longitude: Double)] = [:]
    var lastUpdate: Date?
    
    init() {
        loadBasicData()
    }
    
    func copyData(from other: PrefixMatcher) {
        lock.lock()
        defer { lock.unlock() }
        other.lock.lock()
        defer { other.lock.unlock() }
        self.database = other.database
        self.continentDatabase = other.continentDatabase
        self.cqZoneDatabase = other.cqZoneDatabase
        self.ituZoneDatabase = other.ituZoneDatabase
        self.countryCoordinates = other.countryCoordinates
    }
    
    func country(for callsign: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return database[prefix] ?? "OTHER"
    }
    
    func continent(for callsign: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return continentDatabase[prefix] ?? "OTHER"
    }
    
    func cqZone(for callsign: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return cqZoneDatabase[prefix]
    }
    
    func ituZone(for callsign: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return ituZoneDatabase[prefix]
    }
    
    func coordinates(for callsign: String) -> (latitude: Double, longitude: Double)? {
        let countryName = country(for: callsign)
        guard countryName != "OTHER" && !countryName.isEmpty else { return nil }
        return coordinates(forCountry: countryName)
    }
    
    private func findPrefix(for callsign: String) -> String {
        let rawCall = callsign.uppercased().trimmingCharacters(in: .whitespaces)
        if rawCall.isEmpty { return "" }
        
        let parts = rawCall.components(separatedBy: "/")
        if parts.count >= 2 {
            let p0 = parts[0]
            let p1 = parts[1]
            let modifiers = ["P", "M", "MM", "AM", "QRP", "LH", "LGT", "R", "B"]
            if p0.count <= 4 && !modifiers.contains(p0) {
                let match0 = matchPrefix(p0)
                if !match0.isEmpty && database[match0] != nil {
                    return match0
                }
            }
            if p1.count <= 4 && !modifiers.contains(p1) {
                let match1 = matchPrefix(p1)
                if !match1.isEmpty && database[match1] != nil {
                    return match1
                }
            }
            let mainPart = p0.count >= p1.count ? p0 : p1
            return matchPrefix(mainPart)
        }
        
        return matchPrefix(rawCall)
    }

    private func matchPrefix(_ call: String) -> String {
        for length in (1...6).reversed() {
            if call.count >= length {
                let prefix = String(call.prefix(length))
                if database[prefix] != nil { return prefix }
            }
        }
        return ""
    }
    
    func parseCtyDat(_ content: String) {
        var newDatabase: [String: String] = [:]
        var newContinents: [String: String] = [:]
        var newCQZones: [String: Int] = [:]
        var newITUZones: [String: Int] = [:]
        var newCoordinates: [String: (latitude: Double, longitude: Double)] = [:]
        
        let lines = content.components(separatedBy: .newlines)
        var currentCountry = ""
        var currentContinent = ""
        var currentCQZone: Int? = nil
        var currentITUZone: Int? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if line.starts(with: " ") || line.starts(with: "\t") {
                if !currentCountry.isEmpty {
                    let prefixes = trimmed.replacingOccurrences(of: ";", with: "").components(separatedBy: ",")
                    for p in prefixes {
                        let cleanPrefix = p.trimmingCharacters(in: .whitespaces)
                        if !cleanPrefix.isEmpty {
                            var prefixContinent = currentContinent
                            if let startBracket = cleanPrefix.firstIndex(of: "["), 
                               let endBracket = cleanPrefix.firstIndex(of: "]") {
                                let override = String(cleanPrefix[cleanPrefix.index(after: startBracket)..<endBracket])
                                if override.count == 2 { prefixContinent = override }
                            }

                            var prefixCQZone = currentCQZone
                            if let startParen = cleanPrefix.firstIndex(of: "("), 
                               let endParen = cleanPrefix.firstIndex(of: ")") {
                                let override = String(cleanPrefix[cleanPrefix.index(after: startParen)..<endParen])
                                if let z = Int(override) { prefixCQZone = z }
                            }

                            var prefixITUZone = currentITUZone
                            if let startBrace = cleanPrefix.firstIndex(of: "{"), 
                               let endBrace = cleanPrefix.firstIndex(of: "}") {
                                let override = String(cleanPrefix[cleanPrefix.index(after: startBrace)..<endBrace])
                                if let z = Int(override) { prefixITUZone = z }
                            }
                            
                            let basePrefix = cleanPrefix.components(separatedBy: "(").first!
                                                        .components(separatedBy: "[").first!
                                                        .components(separatedBy: "{").first!
                                                        .trimmingCharacters(in: .whitespaces)
                            newDatabase[basePrefix] = currentCountry
                            newContinents[basePrefix] = prefixContinent
                            if let cq = prefixCQZone { newCQZones[basePrefix] = cq }
                            if let itu = prefixITUZone { newITUZones[basePrefix] = itu }
                        }
                    }
                }
            } else {
                let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 8 {
                    currentCountry = parts[0]
                    currentCQZone = Int(parts[1])
                    currentITUZone = Int(parts[2])
                    currentContinent = parts[3]
                    let primaryPrefix = parts[7]
                    
                    newDatabase[primaryPrefix] = currentCountry
                    newContinents[primaryPrefix] = currentContinent
                    if let cq = currentCQZone { newCQZones[primaryPrefix] = cq }
                    if let itu = currentITUZone { newITUZones[primaryPrefix] = itu }
                    
                    if let lat = Double(parts[4]), let lon = Double(parts[5]) {
                        newCoordinates[currentCountry] = (latitude: lat, longitude: -lon)
                    }
                }
            }
        }
        
        if !newDatabase.isEmpty {
            lock.lock()
            self.database = newDatabase
            self.continentDatabase = newContinents
            self.cqZoneDatabase = newCQZones
            self.ituZoneDatabase = newITUZones
            self.countryCoordinates = newCoordinates
            lock.unlock()
            print("CTY.dat erfolgreich verarbeitet: \(newDatabase.count) Präfixe.")
        }
    }
    
    private func loadBasicData() {
        let basic = "Germany: 14: 28: EU: 51.0: -10.0: -1.0: DL:\r\n DA,DB,DC,DD,DE,DF,DG,DH,DI,DJ,DK,DL,DM,DN,DO,DP,DQ,DR,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9;\r\n" +
                    "Russia: 16: 20: EU: 55.0: -37.0: -3.0: UA:\r\n R,UA,UB,UC,UD,UE,UF,UG,UH,UI,RA,RN,RU,RV,RW,RX,RY,RZ;\r\n" +
                    "United States: 05: 08: NA: 40.0: 100.0: 5.0: K:\r\n K,W,N,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL;\r\n" +
                    "Spain: 14: 37: EU: 40.0: 4.0: 0.0: EA:\r\n EA,EB,EC,ED,EE,EF,EG,EH,AM,AN,AO;\r\n" +
                    "Italy: 15: 28: EU: 43.0: -12.0: -1.0: I:\r\n I,IK,IZ,IU,IA,IB,IC,ID,IE,IF,IG,IH,II,IL,IM,IN,IO,IP,IQ,IR,IS,IT,IV,IW,IX,IY;\r\n" +
                    "France: 14: 27: EU: 46.0: -2.0: -1.0: F:\r\n F,HW,HX,HY,TK,TM,TO,TP,TQ,TV,TX;\r\n" +
                    "United Kingdom: 14: 27: EU: 54.0: 2.0: 0.0: G:\r\n G,GX,M,MQ,2A,2E,2I,2M,2O,2Q,2W;\r\n" +
                    "China: 24: 44: AS: 35.0: -105.0: -8.0: BY:\r\n B,BA,BD,BG,BH,BI,BJ,BL,BM,BN,BO,BP,BQ,BR,BS,BT,BU,BV,BW,BX,BY,BZ,XS;\r\n" +
                    "Japan: 25: 45: AS: 36.0: -138.0: -9.0: JA:\r\n JA,JE,JF,JG,JH,JI,JJ,JK,JL,JM,JN,JO,JP,JQ,JR,JS,7J,7K,7L,7M,7N,8J,8K,8L,8M,8N;\r\n" +
                    "Canada: 05: 09: NA: 60.0: 95.0: 5.0: VE:\r\n VE,VA,VO,VY,XJ,XK,XL,XM,XN,XO;\r\n" +
                    "Madeira Islands: 33: 36: AF: 32.7: 16.8: 0.0: CT3:\r\n CT3,CQ3,CR3,CS3;\r\n"
        parseCtyDat(basic)
    }
    
    func coordinates(forCountry country: String) -> (latitude: Double, longitude: Double)? {
        lock.lock()
        defer { lock.unlock() }
        return countryCoordinates[country]
    }
    
    var prefixCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return database.count
    }
    
    func allCountries() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(Set(database.values)).sorted()
    }
}
