import Foundation

enum WSJTXMessageType: UInt32 {
    case heartbeat = 0
    case status = 1
    case decode = 2
    case clear = 3
    case reply = 4
    case qsoLogged = 5
    case close = 6
    case replay = 7
    case haltTx = 8
    case freeText = 9
    case wsprDecode = 10
    case location = 11
    case loggedAdif = 12
    case highlightCallsign = 13
    case switchConfiguration = 14
    case configure = 15
    case enableTx = 16
}

struct WSJTXDecode: Identifiable, Equatable {
    let id: UUID
    var time: UInt32
    var snr: Int32
    var deltaTime: Double
    var deltaFrequency: UInt32
    var dialFrequency: UInt64
    var mode: String
    var message: String
    var lowConfidence: Bool
    var offAir: Bool
    var isClusterSpot: Bool
    var spotter: String
    var receivedAt: Date
    var customCallsign: String
    
    // Stored precalculated fields
    let callsign: String
    let country: String
    let continent: String
    let cqZone: Int?
    let ituZone: Int?
    let mostWantedRank: Int?
    let isMostWanted: Bool
    let grid: String?
    
    init(
        id: UUID = UUID(),
        time: UInt32,
        snr: Int32,
        deltaTime: Double,
        deltaFrequency: UInt32,
        dialFrequency: UInt64,
        mode: String,
        message: String,
        lowConfidence: Bool,
        offAir: Bool,
        isClusterSpot: Bool = false,
        spotter: String = "WSJTX",
        receivedAt: Date = Date(),
        customCallsign: String = ""
    ) {
        self.id = id
        self.time = time
        self.snr = snr
        self.deltaTime = deltaTime
        self.deltaFrequency = deltaFrequency
        self.dialFrequency = dialFrequency
        self.mode = mode
        self.message = message
        self.lowConfidence = lowConfidence
        self.offAir = offAir
        self.isClusterSpot = isClusterSpot
        self.spotter = spotter
        self.receivedAt = receivedAt
        self.customCallsign = customCallsign
        
        let call = !customCallsign.isEmpty ? customCallsign : WSJTXDecode.parseWSJTDecodeMessage(message)
        self.callsign = call
        
        let matcher = PrefixMatcher.shared
        self.country = matcher.country(for: call)
        self.continent = matcher.continent(for: call)
        self.cqZone = matcher.cqZone(for: call)
        self.ituZone = matcher.ituZone(for: call)
        self.mostWantedRank = MostWantedManager.shared.rankForCallsign(call)
        self.isMostWanted = self.mostWantedRank != nil
        self.grid = Maidenhead.extractGrid(from: message)
    }
    
    func distanceKm(myGrid: String) -> Double? {
        guard let g = grid else { return nil }
        return Maidenhead.distanceKm(from: myGrid, to: g)
    }
    
    var totalFrequencyHz: UInt64 {
        return dialFrequency > 0 ? dialFrequency + UInt64(deltaFrequency) : 0
    }
    
    var formattedHfFrequency: String {
        guard totalFrequencyHz > 0 else { return "-" }
        let mhz = Double(totalFrequencyHz) / 1_000_000.0
        return String(format: "%.6f MHz", mhz)
    }
    
    var band: String {
        return WSJTXDecode.bandFromFrequency(totalFrequencyHz)
    }
    
    static func bandFromFrequency(_ totalFrequencyHz: UInt64) -> String {
        guard totalFrequencyHz > 0 else { return "20M" }
        let mhz = Double(totalFrequencyHz) / 1_000_000.0
        switch mhz {
        case 1.800...2.000: return "160M"
        case 3.500...4.000: return "80M"
        case 5.300...5.450: return "60M"
        case 7.000...7.300: return "40M"
        case 10.100...10.150: return "30M"
        case 14.000...14.350: return "20M"
        case 18.068...18.168: return "17M"
        case 21.000...21.450: return "15M"
        case 24.890...24.990: return "12M"
        case 28.000...29.700: return "10M"
        case 50.000...54.000: return "6M"
        case 144.000...148.000: return "2M"
        case 430.000...450.000: return "70CM"
        default: return "20M"
        }
    }
    
    private static func parseWSJTDecodeMessage(_ message: String) -> String {
        let cleanMsg = message.replacingOccurrences(of: "<", with: " ").replacingOccurrences(of: ">", with: " ")
        let tokens = cleanMsg.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return "" }
        
        let firstToken = tokens[0].uppercased()
        if firstToken == "CQ" || firstToken.hasPrefix("CQ") {
            for i in 1..<tokens.count {
                let candidate = tokens[i].trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                if isValidCallsign(candidate) {
                    return candidate.uppercased()
                }
            }
        }
        
        var validCalls: [String] = []
        for token in tokens {
            let candidate = token.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if isValidCallsign(candidate) {
                validCalls.append(candidate.uppercased())
            }
        }
        
        return validCalls.last ?? ""
    }

    private static func isValidCallsign(_ word: String) -> Bool {
        let clean = word.uppercased().trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count >= 3 && clean.count <= 10 else { return false }
        
        let gridPattern = "^[A-R]{2}[0-9]{2}([A-X]{2})?$"
        if clean.range(of: gridPattern, options: .regularExpression) != nil {
            return false
        }
        
        let keywords = Set(["CQ", "CQDX", "TEST", "DX", "NA", "SA", "EU", "AS", "AF", "OC", "JA", "US", "POTA", "SOTA", "WW", "RRR", "RR73", "73"])
        if keywords.contains(clean) { return false }
        if clean.hasPrefix("-") || clean.hasPrefix("+") || clean.hasPrefix("R-") || clean.hasPrefix("R+") { return false }
        
        let callPattern = "^[A-Z0-9]{1,3}[0-9][A-Z]{1,4}(/[A-Z0-9]+)?$"
        return clean.range(of: callPattern, options: .regularExpression) != nil
    }
}

struct WSJTXReply {
    var id: String
    var time: UInt32
    var snr: Int32
    var deltaTime: Double
    var deltaFrequency: UInt32
    var mode: String
    var message: String
    var lowConfidence: Bool
    var modifiers: UInt8
    
    func serialize() -> Data {
        var writer = QDataStreamWriter()
        writer.writeUInt32(0xADBCCBDA) // Magic
        writer.writeUInt32(2) // Schema version
        writer.writeUInt32(WSJTXMessageType.reply.rawValue)
        writer.writeString(id)
        writer.writeTime(time)
        writer.writeInt32(snr)
        writer.writeDouble(deltaTime)
        writer.writeUInt32(deltaFrequency)
        writer.writeString(mode)
        writer.writeString(message)
        writer.writeBool(lowConfidence)
        writer.writeUInt8(modifiers)
        return writer.data
    }
}

struct WSJTXHaltTx {
    var id: String
    var autoTxOnly: Bool
    
    func serialize() -> Data {
        var writer = QDataStreamWriter()
        writer.writeUInt32(0xADBCCBDA) // Magic
        writer.writeUInt32(2)          // Schema
        writer.writeUInt32(WSJTXMessageType.haltTx.rawValue)
        writer.writeString(id)
        writer.writeBool(autoTxOnly)
        return writer.data
    }
}

enum WSJTXRawLogType: String, Codable {
    case decode = "Decode"
    case incoming = "Eingang"
    case outgoing = "Ausgang"
}

struct WSJTXRawLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let type: WSJTXRawLogType
    let message: String
}

struct ClusterRawLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let message: String
}
