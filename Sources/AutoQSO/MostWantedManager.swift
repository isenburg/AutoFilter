import Foundation

public struct MostWantedEntity: Identifiable, Codable {
    public var id: Int // Rank 1..100
    public var dxccId: Int
    public var prefix: String
    public var name: String
    public var continent: String
}

public class MostWantedManager: ObservableObject {
    public static let shared = MostWantedManager()
    
    @Published public var mostWantedList: [MostWantedEntity] = []
    
    private var prefixToRank: [String: Int] = [:]
    private var dxccIdToRank: [Int: Int] = [:]
    
    public init() {
        loadDefaultTop100()
    }
    
    public func isMostWanted(callsign: String, maxRank: Int = 100) -> Bool {
        guard let rank = rankForCallsign(callsign) else { return false }
        return rank <= maxRank
    }
    
    public func rankForCallsign(_ callsign: String) -> Int? {
        let upper = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !upper.isEmpty else { return nil }
        
        // 1. Direct prefix matching against Most Wanted prefixes (longest prefix match first)
        let sortedPrefixes = prefixToRank.keys.sorted { $0.count > $1.count }
        for p in sortedPrefixes {
            if upper == p || upper.hasPrefix(p + "/") || upper.hasSuffix("/" + p) || upper.hasPrefix(p) {
                return prefixToRank[p]
            }
        }
        return nil
    }
    
    public func entityForCallsign(_ callsign: String) -> MostWantedEntity? {
        guard let rank = rankForCallsign(callsign) else { return nil }
        return mostWantedList.first(where: { $0.id == rank })
    }
    
    private func loadDefaultTop100() {
        let rawList: [(rank: Int, dxcc: Int, prefix: String, name: String, cont: String)] = [
            (1, 344, "P5", "Dem. People's Rep. of Korea", "AS"),
            (2, 123, "KH3", "Johnston Island", "OC"),
            (3, 138, "KH7K", "Kure Island", "OC"),
            (4, 217, "CE0X", "San Felix & San Ambrosio", "SA"),
            (5, 131, "FT/X", "Kerguelen Islands", "AF"),
            (6, 506, "BS7H", "Scarborough Reef", "AS"),
            (7, 199, "3Y/P", "Peter 1 Island", "AN"),
            (8, 17, "YV0", "Aves Island", "NA"),
            (9, 505, "BV9P", "Pratas Island", "AS"),
            (10, 174, "KH4", "Midway Island", "OC"),
            (11, 153, "VK0M", "Macquarie Island", "OC"),
            (12, 280, "EZ", "Turkmenistan", "AS"),
            (13, 253, "PY0S", "St. Peter & St. Paul Rocks", "SA"),
            (14, 240, "VP8/S", "South Sandwich Islands", "SA"),
            (15, 384, "YK", "Syria", "AS"),
            (16, 16, "ZL9", "NZ Subantarctic Islands", "OC"),
            (17, 276, "FT/T", "Tromelin Island", "AF"),
            (18, 111, "VK0H", "Heard Island", "AF"),
            (19, 20, "KH1", "Baker & Howland Islands", "OC"),
            (20, 512, "FK/C", "Chesterfield Islands", "OC"),
            (21, 204, "XF4", "Revillagigedo Islands", "NA"),
            (22, 133, "ZL8", "Kermadec Islands", "OC"),
            (23, 235, "VP8/G", "South Georgia Island", "SA"),
            (24, 201, "ZS8", "Prince Edward & Marion Is.", "AF"),
            (25, 41, "FT/W", "Crozet Island", "AF"),
            (26, 171, "VK9M", "Mellish Reef", "OC"),
            (27, 124, "FT/J", "Juan de Nova, Europa", "AF"),
            (28, 182, "KP1", "Navassa Island", "NA"),
            (29, 273, "PY0T", "Trindade & Martim Vaz Is.", "SA"),
            (30, 177, "JD/M", "Minami Torishima", "OC"),
            (31, 161, "HK0/M", "Malpelo Island", "SA"),
            (32, 180, "SV/A", "Mount Athos", "EU"),
            (33, 37, "TI9", "Cocos Island", "NA"),
            (34, 297, "KH9", "Wake Island", "OC"),
            (35, 4, "1A0", "Sov. Mil. Order of Malta", "EU"),
            (36, 303, "VK9W", "Willis Island", "OC"),
            (37, 99, "FT/G", "Glorioso Islands", "AF"),
            (38, 24, "3Y/B", "Bouvet Island", "AF"),
            (39, 238, "VP8/O", "South Orkney Islands", "SA"),
            (40, 270, "ZK3", "Tokelau Islands", "OC"),
            (41, 309, "XZ", "Myanmar", "AS"),
            (42, 195, "3C0", "Annobon Island", "AF"),
            (43, 43, "KP5", "Desecheo Island", "NA"),
            (44, 61, "R1FJ", "Franz Josef Land", "EU"),
            (45, 247, "1S", "Spratly Islands", "AS"),
            (46, 197, "KH5", "Palmyra & Jarvis Islands", "OC"),
            (47, 490, "T31", "Banaba Island", "OC"),
            (48, 51, "E3", "Eritrea", "AF"),
            (49, 507, "H40", "Temotu Province", "OC"),
            (50, 33, "VQ9", "Chagos Islands", "AF"),
            (51, 515, "KH8/S", "Swains Island", "OC"),
            (52, 118, "JX", "Jan Mayen", "EU"),
            (53, 36, "FO/C", "Clipperton Island", "NA"),
            (54, 274, "ZD9", "Tristan da Cunha & Gough", "AF"),
            (55, 513, "VP6/D", "Ducie Island", "OC"),
            (56, 489, "3D2/C", "Conway Reef", "OC"),
            (57, 232, "T5", "Somalia", "AF"),
            (58, 492, "7O", "Yemen", "AS"),
            (59, 142, "VU4", "Lakshadweep Islands", "AS"),
            (60, 147, "VK9L", "Lord Howe Island", "OC"),
            (61, 252, "CY9", "St. Paul Island", "NA"),
            (62, 187, "5N", "Niger", "AF"),
            (63, 125, "CE0Z", "Juan Fernandez Islands", "SA"),
            (64, 509, "FO/M", "Marquesas Islands", "OC"),
            (65, 172, "VP6", "Pitcairn Island", "OC"),
            (66, 436, "5A", "Libya", "AF"),
            (67, 31, "T31", "Central Kiribati", "OC"),
            (68, 191, "E5/N", "North Cook Islands", "OC"),
            (69, 211, "CY0", "Sable Island", "NA"),
            (70, 241, "VP8/H", "South Shetland Islands", "SA"),
            (71, 295, "HV", "Vatican City", "EU"),
            (72, 35, "VK9X", "Christmas Island", "OC"),
            (73, 105, "KG4", "Guantanamo Bay", "NA"),
            (74, 9, "4U1UN", "United Nations HQ", "NA"),
            (75, 521, "ST0", "South Sudan", "AF"),
            (76, 185, "H44", "Solomon Islands", "OC"),
            (77, 282, "T2", "Tuvalu", "OC"),
            (78, 107, "3C", "Equatorial Guinea", "AF"),
            (79, 460, "3D2/R", "Rotuma Island", "OC"),
            (80, 38, "VK9C", "Cocos (Keeling) Islands", "OC"),
            (81, 508, "FO/A", "Austral Islands", "OC"),
            (82, 414, "TN", "Dem. Rep. of Congo", "AF"),
            (83, 382, "J2", "Djibouti", "AF"),
            (84, 152, "XX9", "Macao", "AS"),
            (85, 306, "A5", "Bhutan", "AS"),
            (86, 298, "FW", "Wallis & Futuna Islands", "OC"),
            (87, 117, "4U1ITU", "ITU HQ Geneva", "EU"),
            (88, 34, "ZL7", "Chatham Islands", "OC"),
            (89, 53, "ET", "Ethiopia", "AF"),
            (90, 466, "ST", "Sudan", "AF"),
            (91, 173, "V6", "Micronesia", "OC"),
            (92, 428, "TU", "Cote d'Ivoire", "AF"),
            (93, 205, "ZD8", "Ascension Island", "AF"),
            (94, 160, "A3", "Tonga", "OC"),
            (95, 510, "E4", "Palestine", "AS"),
            (96, 458, "9L", "Sierra Leone", "AF"),
            (97, 302, "S0", "Western Sahara", "AF"),
            (98, 109, "J5", "Guinea-Bissau", "AF"),
            (99, 442, "5T", "Mauritania", "AF"),
            (100, 422, "EL", "Liberia", "AF")
        ]
        
        var list: [MostWantedEntity] = []
        var pMap: [String: Int] = [:]
        var dMap: [Int: Int] = [:]
        
        for item in rawList {
            let entity = MostWantedEntity(id: item.rank, dxccId: item.dxcc, prefix: item.prefix, name: item.name, continent: item.cont)
            list.append(entity)
            pMap[item.prefix.uppercased()] = item.rank
            dMap[item.dxcc] = item.rank
        }
        
        self.mostWantedList = list
        self.prefixToRank = pMap
        self.dxccIdToRank = dMap
    }
}
