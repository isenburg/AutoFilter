import Foundation
import Combine
import SwiftUI
import MapKit

public struct ActiveQSOPath: Equatable {
    public let myCall: String
    public let myGrid: String
    public let myCoordinate: CLLocationCoordinate2D
    public let targetCall: String
    public let targetGrid: String?
    public let targetCoordinate: CLLocationCoordinate2D
    public let distanceKm: Double?
    public let band: String

    public init(myCall: String, myGrid: String, myCoordinate: CLLocationCoordinate2D, targetCall: String, targetGrid: String?, targetCoordinate: CLLocationCoordinate2D, distanceKm: Double?, band: String) {
        self.myCall = myCall
        self.myGrid = myGrid
        self.myCoordinate = myCoordinate
        self.targetCall = targetCall
        self.targetGrid = targetGrid
        self.targetCoordinate = targetCoordinate
        self.distanceKm = distanceKm
        self.band = band
    }

    public static func == (lhs: ActiveQSOPath, rhs: ActiveQSOPath) -> Bool {
        lhs.targetCall == rhs.targetCall &&
        lhs.myGrid == rhs.myGrid &&
        lhs.myCoordinate.latitude == rhs.myCoordinate.latitude &&
        lhs.myCoordinate.longitude == rhs.myCoordinate.longitude &&
        lhs.targetCoordinate.latitude == rhs.targetCoordinate.latitude &&
        lhs.targetCoordinate.longitude == rhs.targetCoordinate.longitude
    }
}

struct CountryCluster: Identifiable, Equatable {
    let id: String // Ländername
    let country: String
    let continent: String
    let latitude: Double
    let longitude: Double
    let spotCount: Int
    let bands: [BandInfo]

    struct BandInfo: Hashable, Equatable {
        let name: String
        let count: Int
    }
}

struct NewGridCluster: Identifiable, Equatable {
    var id: String { "\(grid)_\(isBlocked ? "blocked" : "pass")" }
    let grid: String
    let is6Char: Bool
    let isBlocked: Bool
    let country: String
    let continent: String
    let latitude: Double
    let longitude: Double
    let spotCount: Int
    let calls: [String]
    let bands: [CountryCluster.BandInfo]
    let latestTime: Date

    var upperRightLatitude: Double {
        let latSpan: Double = is6Char ? (1.0 / 24.0) : 1.0
        return latitude + (latSpan * 0.35)
    }

    var upperRightLongitude: Double {
        let lonSpan: Double = is6Char ? (2.0 / 24.0) : 2.0
        return longitude + (lonSpan * 0.35)
    }
}

public struct PropagationChartItem: Identifiable, Equatable {
    public var id: String { "\(continent)-\(band)" }
    public let continent: String
    public let band: String
    public let count: Int

    public init(continent: String, band: String, count: Int) {
        self.continent = continent
        self.band = band
        self.count = count
    }
}

class DecodeViewModel: ObservableObject {
    @Published var server = WSJTXServer()
    @Published var lotwManager = LoTWManager()
    @Published var qrzManager = QRZManager()
    @Published var selectedCallsign: String = ""
    @Published var isAutoModeEnabled: Bool = false {
        didSet {
            if !isAutoModeEnabled {
                currentTargetCall = ""
                qsoStartTime = nil
                currentQSOStatus = "Bereit"
                addLog("Auto Mode deaktiviert. Aktiver Anruf zurückgesetzt.")
            } else {
                addLog("Auto Mode aktiviert.")
            }
        }
    }
    @Published var retryCooldownMinutes: Int = 10
    @Published var currentQSOStatus: String = "Bereit"
    @Published var logHistory: [String] = []
    
    // Filter Settings
    @Published var blockedCountries: [String] = []
    @Published var allowedCountries: [String] = []
    @Published var allowedSpotterCountries: [String] = []
    @Published var allowedDXCallsigns: [String] = []
    @Published var allowedSpotterCallsigns: [String] = []
    @Published var disabledContinents: [String] = []
    @Published var blockedCQZones: [Int] = []
    @Published var blockedITUZones: [Int] = []
    
    @Published var isFiltersEnabled: Bool = true
    @Published var isWsjtSpecialFilterEnabled: Bool = false
    @Published var isNew4CharGridOnlyFilterEnabled: Bool = false
    @Published var isNew6CharGridOnlyFilterEnabled: Bool = false
    @Published var isDuplicateFilterEnabled: Bool = true
    @Published var duplicateSpotWindowMinutes: Int = 1
    @Published var duplicateSpotFrequencyTolerance: Double = 0.5
    
    let matcher = PrefixMatcher.shared
    
    func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.logHistory.append("[\(ts)] \(message)")
            if self.logHistory.count > 150 {
                self.logHistory.removeFirst()
            }
        }
    }
    
    private var blacklistedCalls: [String: Date] = [:]
    private var currentTargetCall: String = "" {
        didSet {
            if !currentTargetCall.isEmpty {
                selectedCallsign = ""
            }
        }
    }
    private var qsoStartTime: Date?
    private var txTriggerAttempts: Int = 0
    private var lastTxTriggerTime: Date?
    private var lastTriggeredTarget: WSJTXDecode?
    private var txEnabledStartTime: Date?
    
    var displayCallsign: String {
        if !selectedCallsign.isEmpty {
            return selectedCallsign
        }
        return server.activeDxCall
    }
    
    // Default band for now, WSJT-X Status message provides the actual band, but for simplicity we can assume a default or get it from decodes (though decodes don't explicitly send band, only freq).
    // Let's deduce band from frequency.
    
    // Cluster properties
    @Published var isConnected1 = false
    @Published var isConnected2 = false
    @Published var isConnected3 = false
    
    @Published var clusterError1: String? = nil
    @Published var clusterError2: String? = nil
    @Published var clusterError3: String? = nil
    
    @Published var telnetClientCount = 0
    @Published var telnetServerError: String? = nil
    @Published var clusterSpots: [WSJTXDecode] = []
    @Published var propagationClusters: [CountryCluster] = []
    @Published var propagationChartData: [PropagationChartItem] = []
    @Published var newGridClusters: [NewGridCluster] = []
    @Published var mostWantedDecodes: [WSJTXDecode] = []
    @Published var isMainTableScrollPaused: Bool = false {
        didSet {
            if isMainTableScrollPaused {
                frozenMainDecodes = server.decodes
            } else {
                frozenMainDecodes = nil
            }
        }
    }
    @Published var isLogScrollPaused: Bool = false {
        didSet {
            if isLogScrollPaused {
                frozenSystemLogs = (logHistory + lotwManager.logHistory + qrzManager.logHistory).sorted()
                frozenWSJTXLogs = wsjtxRawLogs
                frozenClusterLogs = clusterRawLogs
            } else {
                frozenSystemLogs = nil
                frozenWSJTXLogs = nil
                frozenClusterLogs = nil
            }
        }
    }
    @Published var mainTableSearchText: String = ""
    @Published var logConsoleSearchText: String = ""
    @Published var frozenMainDecodes: [WSJTXDecode]? = nil
    @Published var frozenSystemLogs: [String]? = nil
    @Published var frozenWSJTXLogs: [WSJTXRawLogEntry]? = nil
    @Published var frozenClusterLogs: [ClusterRawLogEntry]? = nil
    private var pendingRecalculationWorkItem: DispatchWorkItem?
    @Published var totalReceived = 0
    @Published var totalForwarded = 0
    @Published var counterStartTime = Date()
    @Published var wsjtxRawLogs: [WSJTXRawLogEntry] = []
    @Published var clusterRawLogs: [ClusterRawLogEntry] = []
    
    let client1 = DXClusterClient()
    let client2 = DXClusterClient()
    let client3 = DXClusterClient()
    let telnetServer = DXClusterServer()
    @Published var availableClusters: [ClusterServer] = []

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "availableClusters"),
           let list = try? JSONDecoder().decode([ClusterServer].self, from: data) {
            self.availableClusters = list
        } else {
            self.availableClusters = ClusterServer.defaultClusters
            if let data = try? JSONEncoder().encode(ClusterServer.defaultClusters) {
                UserDefaults.standard.set(data, forKey: "availableClusters")
            }
        }
        
        // Load filter settings from UserDefaults
        loadFilters()
        
        // Load CTY.DAT cache & Auto-refresh if > 14 days
        loadCtyDatabase()
        
        // Setup DX Clusters and local Telnet Server
        setupClusters()
        
        // Immediately start server on launch from UserDefaults with fallbacks
        let savedPort = UserDefaults.standard.integer(forKey: "udpPort")
        let actualPort = savedPort > 0 ? UInt16(savedPort) : UInt16(2237)
        let savedAddress = UserDefaults.standard.string(forKey: "udpAddress") ?? "224.0.0.1"
        server.start(port: actualPort, address: savedAddress)
        
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.updatePropagationClusters()
        }
        
        server.onDecodeReceived = { [weak self] decode, rawData in
            guard let self = self else { return }
            let accepted = self.shouldAccept(decode: decode, recordDuplicates: true)
            self.bridgeDecodeIfEnabled(decode: decode, rawData: rawData, accepted: accepted)
            if !self.isFiltersEnabled || accepted {
                if UserDefaults.standard.bool(forKey: "isWsjtTelnetOutputEnabled") {
                    self.broadcastWSJTSpot(decode: decode)
                }
            }
            self.totalReceived += 1
            if accepted {
                self.totalForwarded += 1
            }
            self.updatePropagationClusters()

            // Sofortige Cooldown-Sperre, sobald die aktuelle Zielstation 73/RR73 sendet
            if !self.currentTargetCall.isEmpty {
                let targetUpper = self.currentTargetCall.uppercased()
                let msgUpper = decode.message.uppercased()
                if msgUpper.contains(targetUpper) {
                    let tokens = msgUpper.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
                    if tokens.contains("73") || tokens.contains("RR73") || tokens.contains("RRR") {
                        self.blacklistedCalls[targetUpper] = Date()
                    }
                }
            }
        }
        
        server.onRawLogReceived = { [weak self] type, message in
            guard let self = self else { return }
            let entry = WSJTXRawLogEntry(timestamp: Date(), type: type, message: message)
            self.wsjtxRawLogs.append(entry)
            if self.wsjtxRawLogs.count > 300 {
                self.wsjtxRawLogs.removeFirst()
            }
        }
        
        server.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                    self?.evaluateAutoQSO()
                }
            }
            .store(in: &cancellables)
            
        lotwManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        qrzManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        server.onQSOLogged = { [weak self] newEntries in
            guard let self = self else { return }
            self.lotwManager.mergeEntries(newEntries)
            
            for entry in newEntries {
                let callUpper = entry.callsign.uppercased()
                self.blacklistedCalls[callUpper] = Date()
                if callUpper == self.currentTargetCall.uppercased() || self.currentTargetCall.isEmpty {
                    self.currentQSOStatus = "QSO mit \(entry.callsign) erfolgreich beendet!"
                    self.currentTargetCall = ""
                    self.qsoStartTime = nil
                    self.txEnabledStartTime = nil
                    self.lastTriggeredTarget = nil
                    self.txTriggerAttempts = 0
                    self.lastTxTriggerTime = nil
                }
            }
            
            // Auto-trigger QRZ Sync on successful QSO
            let qrzKey = UserDefaults.standard.string(forKey: "qrzApiKey") ?? ""
            if !qrzKey.isEmpty {
                self.syncQRZ(apiKey: qrzKey)
            }
        }
        
        server.onHaltTx = { [weak self] in
            guard let self = self else { return }
            if !self.currentTargetCall.isEmpty {
                let call = self.currentTargetCall
                self.blacklistedCalls[call.uppercased()] = Date()
                self.currentQSOStatus = "QSO mit \(call) abgebrochen. Gesperrt für \(self.retryCooldownMinutes) Min."
                self.currentTargetCall = ""
                self.qsoStartTime = nil
                self.txEnabledStartTime = nil
                self.lastTriggeredTarget = nil
                self.txTriggerAttempts = 0
                self.lastTxTriggerTime = nil
            }
        }
    }

    var worked4CharGrids: Set<String> {
        lotwManager.workedGridsSet
    }
    
    var activeQSOPath: ActiveQSOPath? {
        let rawTarget = server.activeDxCall.isEmpty ? currentTargetCall : server.activeDxCall
        let targetCall = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !targetCall.isEmpty else { return nil }
        
        let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
        guard let myLatLon = Maidenhead.locatorToLatLon(myGrid) else { return nil }
        let myCoord = CLLocationCoordinate2D(latitude: myLatLon.lat, longitude: myLatLon.lon)
        
        var targetGrid: String? = nil
        var targetCoord: CLLocationCoordinate2D? = nil
        
        let allDecodes = server.decodes + clusterSpots
        if let matching = allDecodes.first(where: { $0.callsign.uppercased() == targetCall && $0.grid != nil && !($0.grid!.isEmpty) }),
           let g = matching.grid, g.count >= 4,
           let ll = Maidenhead.locatorToLatLon(g) {
            targetGrid = String(g.prefix(6)).uppercased()
            targetCoord = CLLocationCoordinate2D(latitude: ll.lat, longitude: ll.lon)
        }
        
        if targetCoord == nil {
            let country = matcher.country(for: targetCall)
            if let coords = matcher.coordinates(forCountry: country) {
                targetCoord = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
            }
        }
        
        guard let finalTargetCoord = targetCoord else { return nil }
        
        let dist: Double?
        if let tg = targetGrid {
            dist = Maidenhead.distanceKm(from: myGrid, to: tg)
        } else {
            dist = nil
        }
        
        let band = server.decodes.first(where: { $0.callsign.uppercased() == targetCall })?.band ?? ""
        
        return ActiveQSOPath(
            myCall: "MY QTH",
            myGrid: myGrid,
            myCoordinate: myCoord,
            targetCall: targetCall,
            targetGrid: targetGrid,
            targetCoordinate: finalTargetCoord,
            distanceKm: dist,
            band: band
        )
    }
    
    func evaluateAutoQSO() {
        guard isAutoModeEnabled else { return }
        
        // If currently in an active QSO attempt, monitor status/timeout/retries before starting any new target
        if !currentTargetCall.isEmpty {
            // Check if WSJT-X enabled TX (TX Bereit)
            let hasWSJTXAccepted = server.isTxEnabled
            
            if hasWSJTXAccepted {
                // Trigger war erfolgreich! Wiederholungs-Versuche zurücksetzen und deaktivieren.
                if txTriggerAttempts > 0 {
                    addLog("✅ WSJT-X Sende-Bereitschaft (TX BEREIT) erfolgreich erkannt.")
                }
                if txEnabledStartTime == nil {
                    txEnabledStartTime = Date()
                }
                txTriggerAttempts = 0
                lastTxTriggerTime = nil
                lastTriggeredTarget = nil
            } else {
                if let triggerTime = lastTxTriggerTime {
                    let elapsedSinceTrigger = Date().timeIntervalSince(triggerTime)
                    if elapsedSinceTrigger >= 3.0 { // Wait 3 seconds per trigger attempt
                        if txTriggerAttempts >= 3 {
                            let failedCall = currentTargetCall
                            blacklistedCalls[failedCall.uppercased()] = Date()
                            let msg = "WSJT-X hat den Anruf auf \(failedCall) nach 3 Versuchen nicht gestartet (Verbindung prüfen)."
                            currentQSOStatus = "Anruf-Trigger fehlgeschlagen."
                            addLog("⚠️ \(msg)")
                            
                            // Reset state
                            currentTargetCall = ""
                            qsoStartTime = nil
                            txEnabledStartTime = nil
                            lastTriggeredTarget = nil
                            txTriggerAttempts = 0
                            lastTxTriggerTime = nil
                            return
                        } else {
                            txTriggerAttempts += 1
                            lastTxTriggerTime = Date()
                            addLog("🔁 WSJT-X hat noch nicht gesendet. Erneuter Anruf-Versuch (\(txTriggerAttempts)/3) für \(currentTargetCall)...")
                            if let target = lastTriggeredTarget {
                                sendReply(for: target)
                            }
                            return
                        }
                    }
                } else if let enabledStart = txEnabledStartTime {
                    // Sende-Bereitschaft (TX BEREIT) war bereits aktiv, ist nun aber wieder aus!
                    let elapsed = Date().timeIntervalSince(enabledStart)
                    let failedCall = currentTargetCall
                    
                    // "wenn tx bereits nach einem zyklus wieder aus ist, dann hat wsjtx das senden abgebrochen. Dann die Station nicht in Quarantäne nehmen und mit der nächsten weitermachen."
                    if elapsed <= 25.0 {
                        let msg = "QSO mit \(failedCall) nach nur einem Sende-Zyklus (\(Int(elapsed))s) abgebrochen (Keine Quarantäne)."
                        currentQSOStatus = msg
                        addLog("ℹ️ \(msg)")
                    } else {
                        // "Wenn 'TX Bereit' danach wieder aus ist ohne das ein QSO geloggt wurde, Call in Cooldown nehmen."
                        blacklistedCalls[failedCall.uppercased()] = Date()
                        let msg = "QSO mit \(failedCall) nach \(Int(elapsed))s erfolglos beendet (TX Bereit aus). Gesperrt für \(retryCooldownMinutes) Min."
                        currentQSOStatus = msg
                        addLog("⚠️ \(msg)")
                    }
                    
                    // Reset target
                    currentTargetCall = ""
                    qsoStartTime = nil
                    txEnabledStartTime = nil
                    lastTriggeredTarget = nil
                    txTriggerAttempts = 0
                    lastTxTriggerTime = nil
                    return
                } else {
                    // stuck state workaround
                    currentTargetCall = ""
                    qsoStartTime = nil
                    txEnabledStartTime = nil
                    lastTriggeredTarget = nil
                    txTriggerAttempts = 0
                    lastTxTriggerTime = nil
                    return
                }
            }
            return
        }
        
        var candidates: [WSJTXDecode] = []
        let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
        let prioritizeMW = UserDefaults.standard.object(forKey: "prioritizeMostWanted") as? Bool ?? true
        let onlyMW = UserDefaults.standard.bool(forKey: "onlyMostWanted")
        let maxRank = UserDefaults.standard.integer(forKey: "maxMostWantedRank") > 0 ? UserDefaults.standard.integer(forKey: "maxMostWantedRank") : 100
        let ownCall = (UserDefaults.standard.string(forKey: "lotwUsername") ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        var skippedCounts = [String: Int]()
        var totalCQsOr73s = 0
        
        for decode in server.decodes {
            if decode.isClusterSpot { continue }
            let call = decode.callsign.uppercased()
            guard !call.isEmpty else { continue }
            if !ownCall.isEmpty && call == ownCall {
                skippedCounts["Eigenes Rufzeichen"] = (skippedCounts["Eigenes Rufzeichen"] ?? 0) + 1
                continue
            }
            
            let upperMsg = decode.message.uppercased()
            let msgTokens = upperMsg.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
            
            let isCQ = upperMsg.contains("CQ ") || upperMsg.hasPrefix("CQ")
            let is73 = msgTokens.contains("73") || msgTokens.contains("RR73") || msgTokens.contains("RRR")
            
            if isCQ || is73 {
                totalCQsOr73s += 1
                
                // DX Filter Check
                if !shouldAccept(decode: decode) {
                    skippedCounts["Durch DX-Filter blockiert"] = (skippedCounts["Durch DX-Filter blockiert"] ?? 0) + 1
                    continue
                }
                
                // Strikter DXCC / Most Wanted Filter wenn nur Most Wanted erlaubt
                if onlyMW {
                    guard MostWantedManager.shared.isMostWanted(callsign: call, maxRank: maxRank) else {
                        skippedCounts["Nicht in Most Wanted (\(maxRank))"] = (skippedCounts["Nicht in Most Wanted (\(maxRank))"] ?? 0) + 1
                        continue
                    }
                }
                
                // Check if not worked on this band
                if !lotwManager.hasWorked(callsign: call, band: decode.band) {
                    // Check if callsign is currently in failure/aborted cooldown
                    if let blacklistedAt = blacklistedCalls[call] {
                        let elapsedMinutes = Date().timeIntervalSince(blacklistedAt) / 60.0
                        if elapsedMinutes < Double(retryCooldownMinutes) {
                            skippedCounts["In Sperrzeit (\(Int(Double(retryCooldownMinutes) - elapsedMinutes) + 1) Min.)"] = (skippedCounts["In Sperrzeit (\(Int(Double(retryCooldownMinutes) - elapsedMinutes) + 1) Min.)"] ?? 0) + 1
                            continue // Still in retry cooldown
                        } else {
                            blacklistedCalls.removeValue(forKey: call) // Cooldown expired
                        }
                    }
                    candidates.append(decode)
                } else {
                    skippedCounts["Bereits auf \(decode.band) gearbeitet"] = (skippedCounts["Bereits auf \(decode.band) gearbeitet"] ?? 0) + 1
                }
            }
        }
        
        if candidates.isEmpty {
            if totalCQsOr73s > 0 {
                let reasons = skippedCounts.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                addLog("Auswertung: Keine Anruf-Kandidaten unter \(totalCQsOr73s) CQs/73s gefunden (\(reasons))")
            }
            return
        }
        
        // Sort candidates: Most Wanted Rank (1..100) first, then Furthest Distance (km) second, then SNR third
        candidates.sort { d1, d2 in
            let call1 = d1.callsign
            let call2 = d2.callsign
            
            let rank1 = MostWantedManager.shared.rankForCallsign(call1)
            let rank2 = MostWantedManager.shared.rankForCallsign(call2)
            
            let isMW1 = rank1 != nil && rank1! <= maxRank
            let isMW2 = rank2 != nil && rank2! <= maxRank
            
            if prioritizeMW {
                if isMW1 != isMW2 {
                    return isMW1 // Most Wanted station wins
                }
                if isMW1 && isMW2, let r1 = rank1, let r2 = rank2, r1 != r2 {
                    return r1 < r2 // Higher rank (closer to #1) wins
                }
            }
            
            // Weiteste Entfernung zuerst
            let dist1 = d1.distanceKm(myGrid: myGrid) ?? 0.0
            let dist2 = d2.distanceKm(myGrid: myGrid) ?? 0.0
            if abs(dist1 - dist2) > 50.0 { // Significant distance difference (>50 km)
                return dist1 > dist2
            }
            
            // Fallback: SNR
            return d1.snr > d2.snr
        }
        
        let bestTarget = candidates[0]
        let bestCall = bestTarget.callsign.uppercased()
        
        currentTargetCall = bestCall
        qsoStartTime = Date()
        lastTriggeredTarget = bestTarget
        txTriggerAttempts = 1
        lastTxTriggerTime = Date()
        
        let mwInfo: String
        if let rank = MostWantedManager.shared.rankForCallsign(bestCall) {
            mwInfo = " [🔥 MOST WANTED #\(rank)]"
        } else {
            mwInfo = ""
        }
        
        let distInfo: String
        if let dist = bestTarget.distanceKm(myGrid: myGrid) {
            distInfo = String(format: " [%.0f km]", dist)
        } else {
            distInfo = ""
        }
        
        currentQSOStatus = "AutoQSO: Rufe \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo)..."
        addLog("🚀 Rufe \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo) [Msg: \(bestTarget.message)]")
        
        print("AutoQSO Engine: Starte Anruf -> \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo) [Msg: \(bestTarget.message)]")
        sendReply(for: bestTarget)
    }
    
    func syncQRZ(apiKey: String, fullSync: Bool = true) {
        qrzManager.downloadQRZ(apiKey: apiKey, fullSync: fullSync) { [weak self] qrzEntries in
            self?.lotwManager.mergeEntries(qrzEntries)
        }
    }
    
    func startServer(port: UInt16, address: String) {
        server.start(port: port, address: address)
    }
    
    func getBand(from frequency: UInt32) -> String {
        return "20M"
    }
    
    
    func sendReply(for decode: WSJTXDecode) {
        server.activeDxCall = decode.callsign
        let reply = WSJTXReply(
            id: "AutoQSO",
            time: decode.time,
            snr: decode.snr,
            deltaTime: decode.deltaTime,
            deltaFrequency: decode.deltaFrequency,
            mode: decode.mode,
            message: decode.message,
            lowConfidence: decode.lowConfidence,
            modifiers: 0x01 // 0x01 = Shift Modifier -> erzwingt "Enable TX = ON" in WSJT-X!
        )
        // Verzögerung von 200ms, damit WSJT-X das CPU-intensive Decodieren/UI-Zeichnen abschließen kann,
        // bevor es das UDP-Paket verarbeitet. Verhindert Paketverluste.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.server.sendReply(reply)
        }
    }
    
    // MARK: - DX Filter System Logic

    private var ctyCacheURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("com.dj6gi.AutoQSO", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("cty_cache.dat")
    }

    func loadCtyDatabase() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let cacheURL = self.ctyCacheURL
            if let savedDate = UserDefaults.standard.object(forKey: "cty_cache_date") as? Date,
               let content = try? String(contentsOf: cacheURL, encoding: .utf8) {
                self.matcher.parseCtyDat(content)
                self.matcher.lastUpdate = savedDate
                self.addLog("CTY.DAT erfolgreich im Hintergrund geladen.")
                if abs(savedDate.timeIntervalSinceNow) > 1209600 {
                    self.updateCtyData()
                }
            } else {
                self.updateCtyData()
            }
        }
    }

    private func addClusterRawLog(_ line: String, sourceId: Int) {
        let label: String
        switch sourceId {
        case 1:
            label = UserDefaults.standard.string(forKey: "cluster1Host") ?? "dxc.ve7cc.net"
        case 2:
            label = UserDefaults.standard.string(forKey: "cluster2Host") ?? "dxc.ve7cc.net"
        case 3:
            label = UserDefaults.standard.string(forKey: "cluster3Host") ?? "dx.k3lr.com"
        default:
            label = "Cluster"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        
        DispatchQueue.main.async {
            self.clusterRawLogs.append(ClusterRawLogEntry(timestamp: Date(), message: "[\(ts)] [\(label)] \(line)"))
            if self.clusterRawLogs.count > 300 {
                self.clusterRawLogs.removeFirst()
            }
        }
    }

    func setupClusters() {
        client1.onLineReceived = { [weak self] line in
            self?.addClusterRawLog(line, sourceId: 1)
            self?.processClusterLine(line, sourceId: 1)
        }
        client1.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.isConnected1 = (state == .ready)
                if state == .ready { self?.clusterError1 = nil }
            }
        }
        client1.onError = { [weak self] error in
            DispatchQueue.main.async { self?.clusterError1 = error }
        }
        
        client2.onLineReceived = { [weak self] line in
            self?.addClusterRawLog(line, sourceId: 2)
            self?.processClusterLine(line, sourceId: 2)
        }
        client2.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.isConnected2 = (state == .ready)
                if state == .ready { self?.clusterError2 = nil }
            }
        }
        client2.onError = { [weak self] error in
            DispatchQueue.main.async { self?.clusterError2 = error }
        }
        
        client3.onLineReceived = { [weak self] line in
            self?.addClusterRawLog(line, sourceId: 3)
            self?.processClusterLine(line, sourceId: 3)
        }
        client3.onStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.isConnected3 = (state == .ready)
                if state == .ready { self?.clusterError3 = nil }
            }
        }
        client3.onError = { [weak self] error in
            DispatchQueue.main.async { self?.clusterError3 = error }
        }
        
        telnetServer.onStatusChange = { [weak self] error in
            DispatchQueue.main.async {
                self?.telnetServerError = error
            }
        }
        telnetServer.onClientCountChange = { [weak self] count in
            DispatchQueue.main.async {
                self?.telnetClientCount = count
            }
        }
        
        startTelnetServer()
        reconnectClusters()
    }
    
    func startTelnetServer() {
        telnetServer.stop()
        let port = UserDefaults.standard.integer(forKey: "telnetServerPort")
        let actualPort = port > 0 ? UInt16(port) : UInt16(8000)
        do {
            try telnetServer.start(port: actualPort)
            telnetServerError = nil
        } catch {
            telnetServerError = "Telnet Server: \(error.localizedDescription)"
        }
    }
    
    func reconnectClusters() {
        client1.disconnect()
        if UserDefaults.standard.bool(forKey: "isCluster1Enabled") {
            let host = UserDefaults.standard.string(forKey: "cluster1Host") ?? "telnet.reversebeacon.net"
            let port = UserDefaults.standard.integer(forKey: "cluster1Port")
            let actualPort = port > 0 ? UInt16(port) : UInt16(7000)
            client1.connect(host: host, port: actualPort)
        }
        
        client2.disconnect()
        if UserDefaults.standard.bool(forKey: "isCluster2Enabled") {
            let host = UserDefaults.standard.string(forKey: "cluster2Host") ?? "dxc.ve7cc.net"
            let port = UserDefaults.standard.integer(forKey: "cluster2Port")
            let actualPort = port > 0 ? UInt16(port) : UInt16(23)
            client2.connect(host: host, port: actualPort)
        }
        
        client3.disconnect()
        if UserDefaults.standard.bool(forKey: "isCluster3Enabled") {
            let host = UserDefaults.standard.string(forKey: "cluster3Host") ?? "dx.k3lr.com"
            let port = UserDefaults.standard.integer(forKey: "cluster3Port")
            let actualPort = port > 0 ? UInt16(port) : UInt16(23)
            client3.connect(host: host, port: actualPort)
        }
    }
    
    func saveClusters() {
        if let data = try? JSONEncoder().encode(availableClusters) {
            UserDefaults.standard.set(data, forKey: "availableClusters")
            self.objectWillChange.send()
        }
    }
    
    func addCluster(name: String, host: String, port: UInt16) {
        let newCluster = ClusterServer(name: name, host: host, port: port)
        if !availableClusters.contains(where: { $0.host == host && $0.port == port }) {
            availableClusters.append(newCluster)
            saveClusters()
        }
    }
    
    func removeCluster(_ cluster: ClusterServer) {
        availableClusters.removeAll { $0.id == cluster.id }
        saveClusters()
    }
    
    func restoreDefaultClusters() {
        availableClusters = ClusterServer.defaultClusters
        saveClusters()
    }
    
    func sortClusters() {
        availableClusters.sort { $0.name.lowercased() < $1.name.lowercased() }
        saveClusters()
    }
    
    func moveCluster(from source: IndexSet, to destination: Int) {
        availableClusters.move(fromOffsets: source, toOffset: destination)
        saveClusters()
    }
    
    private func processClusterLine(_ line: String, sourceId: Int) {
        let lower = line.lowercased()
        if lower.contains("login:") || lower.contains("enter your call") || lower.contains("callsign:") {
            let client: DXClusterClient
            switch sourceId {
            case 1: client = client1
            case 2: client = client2
            case 3: client = client3
            default: return
            }
            let loginCall = UserDefaults.standard.string(forKey: "clusterCallsign") ?? "GUEST"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                client.send(text: loginCall)
            }
            return
        }
        
        if line.range(of: "DX de", options: .caseInsensitive) != nil {
            parseLiveSpot(line)
        } else {
            parseTableSpot(line)
        }
    }
    
    private func parseLiveSpot(_ line: String) {
        guard let deRange = line.range(of: "DX de ", options: .caseInsensitive) else {
            parseGenericSpot(line)
            return
        }
        
        let afterDe = String(line[deRange.upperBound...])
        guard let colonIndex = afterDe.firstIndex(of: ":") else {
            parseGenericSpot(line)
            return
        }
        
        let spotter = String(afterDe[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        let afterColon = String(afterDe[afterDe.index(after: colonIndex)...])
        let components = afterColon.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard components.count >= 2 else { return }
        let freqStr = components[0].replacingOccurrences(of: ":", with: "")
        let dxCall = components[1]
        let freq = Double(freqStr) ?? 0.0
        
        guard freq > 0.0, !dxCall.isEmpty else { return }
        
        var comment = ""
        if components.count > 2 {
            comment = components[2...].joined(separator: " ")
        }
        
        createAndAddClusterSpot(call: dxCall, freq: freq, spotter: spotter, comment: comment, raw: line)
    }
    
    private func parseTableSpot(_ line: String) {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if components.count >= 2, let firstVal = Double(components[0].replacingOccurrences(of: ":", with: "")), firstVal > 10.0 {
            let freq = firstVal
            let dxCall = components[1]
            
            var spotter = "Cluster"
            if let startBracket = line.lastIndex(of: "<"), let endBracket = line.lastIndex(of: ">"), startBracket < endBracket {
                let range = line.index(after: startBracket)..<endBracket
                spotter = String(line[range]).trimmingCharacters(in: .whitespaces)
            }
            
            var comment = ""
            if let callIndex = components.firstIndex(of: dxCall), components.count > callIndex + 1 {
                let remaining = components[(callIndex + 1)..<components.count].joined(separator: " ")
                let datePattern = "\\d{1,2}-[A-Za-z]{3}-\\d{4}"
                comment = remaining.replacingOccurrences(of: datePattern, with: "", options: .regularExpression)
                comment = comment.replacingOccurrences(of: "\\d{4}Z", with: "", options: .regularExpression)
                if let bIndex = comment.firstIndex(of: "<") { comment = String(comment[..<bIndex]) }
                comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            createAndAddClusterSpot(call: dxCall, freq: freq, spotter: spotter, comment: comment, raw: line)
        } else {
            parseGenericSpot(line)
        }
    }

    private func parseGenericSpot(_ line: String) {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard components.count >= 2 else { return }
        
        var freq: Double? = nil
        var callIndex: Int? = nil
        
        for (idx, comp) in components.enumerated() {
            let clean = comp.replacingOccurrences(of: ":", with: "")
            if let f = Double(clean), f > 1.0 && f < 60000.0 {
                freq = f
                if idx + 1 < components.count {
                    callIndex = idx + 1
                }
                break
            }
        }
        
        guard let f = freq, let cIdx = callIndex else { return }
        let dxCall = components[cIdx].trimmingCharacters(in: CharacterSet.alphanumerics.inverted.subtracting(.init(charactersIn: "/")))
        guard !dxCall.isEmpty, dxCall.count >= 3 else { return }
        
        var comment = ""
        if cIdx + 1 < components.count {
            comment = components[(cIdx + 1)...].joined(separator: " ")
        }
        
        createAndAddClusterSpot(call: dxCall, freq: f, spotter: "Cluster", comment: comment, raw: line)
    }
    
    private func millisecondsSinceMidnightUTC() -> UInt32 {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let seconds = now.timeIntervalSince(startOfDay)
        return UInt32(seconds * 1000)
    }
    
    private func createAndAddClusterSpot(call: String, freq: Double, spotter: String, comment: String, raw: String) {
        let hfFreqHz = UInt64(freq * 1000)
        let cleanComment = comment.isEmpty ? "DX spot" : comment
        
        let decode = WSJTXDecode(
            time: millisecondsSinceMidnightUTC(),
            snr: 0,
            deltaTime: 0.0,
            deltaFrequency: 0,
            dialFrequency: hfFreqHz,
            mode: "SPOT",
            message: cleanComment,
            lowConfidence: false,
            offAir: false,
            isClusterSpot: true,
            spotter: spotter,
            customCallsign: call
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Unconditional insertion: All received spots appear in table list
            self.clusterSpots.insert(decode, at: 0)
            if self.clusterSpots.count > 500 {
                self.clusterSpots.removeSubrange(500...)
            }
            
            self.server.decodes.insert(decode, at: 0)
            if self.server.decodes.count > 500 {
                self.server.decodes.removeSubrange(500...)
            }
            
            self.totalReceived += 1
            
            let accepted = self.shouldAccept(decode: decode, recordDuplicates: false)
            if !self.isFiltersEnabled || accepted {
                self.totalForwarded += 1
                let resolvedCountry = self.matcher.country(for: call)
                let resolvedContinent = self.matcher.continent(for: call)
                let resolvedCq = self.matcher.cqZone(for: call)
                let resolvedItu = self.matcher.ituZone(for: call)
                let resolvedCoords = self.matcher.coordinates(forCountry: resolvedCountry)
                
                let spot = DXSpot(
                    dxCall: call,
                    country: resolvedCountry,
                    continent: resolvedContinent,
                    cqZone: resolvedCq,
                    ituZone: resolvedItu,
                    frequency: freq,
                    spotter: spotter,
                    timestamp: Date(),
                    rawLine: raw.isEmpty ? self.formatAsDXSpot(spotter: spotter, freq: freq, call: call, info: cleanComment) : raw,
                    isFiltered: false,
                    comment: cleanComment,
                    isWsjt: false,
                    latitude: resolvedCoords?.latitude,
                    longitude: resolvedCoords?.longitude
                )
                self.telnetServer.broadcast(spot: spot)
            }
            
            self.totalReceived += 1
            if accepted {
                self.totalForwarded += 1
            }
            self.updatePropagationClusters()
        }
    }

    private static let dxSpotTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HHmm"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private func formatAsDXSpot(spotter: String, freq: Double, call: String, info: String) -> String {
        let s = (spotter + ":").padding(toLength: 11, withPad: " ", startingAt: 0)
        let f = String(format: "%8.1f", freq).padding(toLength: 9, withPad: " ", startingAt: 0)
        let c = call.padding(toLength: 13, withPad: " ", startingAt: 0)
        let i = info.padding(toLength: 30, withPad: " ", startingAt: 0)
        let t = Self.dxSpotTimeFormatter.string(from: Date())
        return "DX de \(s) \(f) \(c) \(i) \(t)Z"
    }

    func broadcastWSJTSpot(decode: WSJTXDecode) {
        let mhz = Double(decode.totalFrequencyHz) / 1_000_000.0
        let khz = mhz * 1000.0
        let spotterName = UserDefaults.standard.string(forKey: "clusterCallsign") ?? "GUEST"
        let fullInfo = "\(decode.mode) \(decode.snr)dB \(decode.message)".trimmingCharacters(in: .whitespaces)
        let rawLine = formatAsDXSpot(spotter: spotterName, freq: khz, call: decode.callsign, info: fullInfo)
        
        let resolvedCountry = matcher.country(for: decode.callsign)
        let resolvedContinent = matcher.continent(for: decode.callsign)
        let resolvedCq = matcher.cqZone(for: decode.callsign)
        let resolvedItu = matcher.ituZone(for: decode.callsign)
        let resolvedCoords = matcher.coordinates(forCountry: resolvedCountry)
        
        let spot = DXSpot(
            dxCall: decode.callsign,
            country: resolvedCountry,
            continent: resolvedContinent,
            cqZone: resolvedCq,
            ituZone: resolvedItu,
            frequency: khz,
            spotter: spotterName,
            timestamp: Date(),
            rawLine: rawLine,
            isFiltered: false,
            comment: fullInfo,
            isWsjt: true,
            latitude: resolvedCoords?.latitude,
            longitude: resolvedCoords?.longitude
        )
        telnetServer.broadcast(spot: spot)
    }

    func updateCtyData() {
        let url = URL(string: "https://www.country-files.com/cty/cty.dat")!
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let content = String(data: data, encoding: .utf8) {
                let now = Date()
                try? content.write(to: self.ctyCacheURL, atomically: true, encoding: .utf8)
                UserDefaults.standard.set(now, forKey: "cty_cache_date")
                self.matcher.parseCtyDat(content)
                self.matcher.lastUpdate = now
                self.addLog("CTY.DAT erfolgreich im Hintergrund aktualisiert.")
            }
        }.resume()
    }

    func loadFilters() {
        let defaults = UserDefaults.standard
        isFiltersEnabled = defaults.object(forKey: "dx_filters_enabled_global") as? Bool ?? true
        blockedCountries = defaults.stringArray(forKey: "blockedCountries") ?? []
        allowedCountries = defaults.stringArray(forKey: "allowedCountries") ?? []
        allowedSpotterCountries = defaults.stringArray(forKey: "allowedSpotterCountries") ?? []
        allowedDXCallsigns = defaults.stringArray(forKey: "allowedDXCallsigns") ?? []
        allowedSpotterCallsigns = defaults.stringArray(forKey: "allowedSpotterCallsigns") ?? []
        disabledContinents = defaults.stringArray(forKey: "disabledContinents") ?? []
        blockedCQZones = defaults.array(forKey: "blockedCQZones") as? [Int] ?? []
        blockedITUZones = defaults.array(forKey: "blockedITUZones") as? [Int] ?? []
        
        isWsjtSpecialFilterEnabled = defaults.bool(forKey: "isWsjtSpecialFilterEnabled")
        isNew4CharGridOnlyFilterEnabled = defaults.bool(forKey: "isNew4CharGridOnlyFilterEnabled")
        isNew6CharGridOnlyFilterEnabled = defaults.bool(forKey: "isNew6CharGridOnlyFilterEnabled")
        isDuplicateFilterEnabled = defaults.object(forKey: "isDuplicateFilterEnabled") as? Bool ?? true
        duplicateSpotWindowMinutes = defaults.integer(forKey: "duplicateSpotWindowMinutes")
        if duplicateSpotWindowMinutes == 0 { duplicateSpotWindowMinutes = 1 }
        duplicateSpotFrequencyTolerance = defaults.double(forKey: "duplicateSpotFrequencyTolerance")
        if duplicateSpotFrequencyTolerance == 0.0 { duplicateSpotFrequencyTolerance = 0.5 }
    }
    
    func saveFilters() {
        let defaults = UserDefaults.standard
        defaults.set(isFiltersEnabled, forKey: "dx_filters_enabled_global")
        defaults.set(blockedCountries, forKey: "blockedCountries")
        defaults.set(allowedCountries, forKey: "allowedCountries")
        defaults.set(allowedSpotterCountries, forKey: "allowedSpotterCountries")
        defaults.set(allowedDXCallsigns, forKey: "allowedDXCallsigns")
        defaults.set(allowedSpotterCallsigns, forKey: "allowedSpotterCallsigns")
        defaults.set(disabledContinents, forKey: "disabledContinents")
        defaults.set(blockedCQZones, forKey: "blockedCQZones")
        defaults.set(blockedITUZones, forKey: "blockedITUZones")
        
        defaults.set(isWsjtSpecialFilterEnabled, forKey: "isWsjtSpecialFilterEnabled")
        defaults.set(isNew4CharGridOnlyFilterEnabled, forKey: "isNew4CharGridOnlyFilterEnabled")
        defaults.set(isNew6CharGridOnlyFilterEnabled, forKey: "isNew6CharGridOnlyFilterEnabled")
        defaults.set(isDuplicateFilterEnabled, forKey: "isDuplicateFilterEnabled")
        defaults.set(duplicateSpotWindowMinutes, forKey: "duplicateSpotWindowMinutes")
        defaults.set(duplicateSpotFrequencyTolerance, forKey: "duplicateSpotFrequencyTolerance")
        scheduleRecalculations()
    }

    func shouldAccept(decode: WSJTXDecode, recordDuplicates: Bool = false) -> Bool {
        guard isFiltersEnabled else { return true }
        
        let call = decode.callsign.uppercased()
        let comment = decode.message
        
        let country = matcher.country(for: call)
        let continent = matcher.continent(for: call)
        let cq = matcher.cqZone(for: call)
        let itu = matcher.ituZone(for: call)
        
        // 1. Continent Filter
        if disabledContinents.contains(continent) {
            return false
        }
        
        // 2. Blocked Countries (Blacklist)
        if isCountryBlocked(country) {
            return false
        }
        
        // 3. Allowed DX Countries (Whitelist)
        if !allowedCountries.isEmpty && !countryMatches(country, in: allowedCountries) {
            return false
        }
        
        // 4. Blocked CQ Zones
        if let cqVal = cq, blockedCQZones.contains(cqVal) {
            return false
        }
        
        // 5. Blocked ITU Zones
        if let ituVal = itu, blockedITUZones.contains(ituVal) {
            return false
        }
        
        // 6. Allowed DX Callsigns (Whitelist)
        if !allowedDXCallsigns.isEmpty && !callsignMatches(call, in: allowedDXCallsigns) {
            return false
        }
        
        // 7. Spotter Filter (applied to decode.spotter for clusters)
        if decode.isClusterSpot {
            let spotter = decode.spotter
            if isSpotterBlocked(spotter) {
                return false
            }
        }
        
        // 8. WSJT Special Filter (Show only CQ, RR, RR73, RRR, 73)
        if isWsjtSpecialFilterEnabled {
            let upper = comment.uppercased()
            let tokens = upper.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
            var passed = false
            for token in tokens {
                if token.hasPrefix("CQ") || token == "RR73" || token == "RRR" || token == "73" || token == "RR" {
                    passed = true
                    break
                }
            }
            if !passed { return false }
        }
        
        // 8.5. New 4 Character Maidenhead Grid Only Filter
        if isNew4CharGridOnlyFilterEnabled {
            guard let g = decode.grid, g.count >= 4 else { return false }
            let grid4 = String(g.prefix(4)).uppercased()
            if lotwManager.hasWorkedGrid(grid4) {
                return false
            }
        }
        
        // 8.6. New 6 Character Maidenhead Grid Only Filter
        if isNew6CharGridOnlyFilterEnabled {
            guard let g = decode.grid, g.count >= 6 else { return false }
            let grid6 = String(g.prefix(6)).uppercased()
            if lotwManager.hasWorkedGrid6(grid6) {
                return false
            }
        }
        
        // 9. Duplicate Filter
        if isDuplicateFilterEnabled {
            let freqMhz = Double(decode.dialFrequency) / 1_000_000.0 + Double(decode.deltaFrequency) / 1_000_000.0
            let freqKhz = freqMhz * 1000.0
            if isDuplicateSpot(id: decode.id, call: call, freq: freqKhz, record: recordDuplicates) {
                return false
            }
        }
        
        return true
    }

    func isAutoQSOInteresting(decode: WSJTXDecode) -> Bool {
        let call = decode.callsign.uppercased()
        guard !call.isEmpty else { return false }
        
        let ownCall = (UserDefaults.standard.string(forKey: "lotwUsername") ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !ownCall.isEmpty && call == ownCall {
            return false
        }
        
        if !decode.isClusterSpot {
            let upperMsg = decode.message.uppercased()
            let msgTokens = upperMsg.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
            
            let isCQ = upperMsg.contains("CQ ") || upperMsg.hasPrefix("CQ")
            let is73 = msgTokens.contains("73") || msgTokens.contains("RR73") || msgTokens.contains("RRR")
            
            guard isCQ || is73 else { return false }
        }
        
        // 1. Filtered out by DX Filters
        if !shouldAccept(decode: decode) {
            return false
        }
        
        // 2. Only Most Wanted filter active
        let onlyMW = UserDefaults.standard.bool(forKey: "onlyMostWanted")
        let maxRank = UserDefaults.standard.integer(forKey: "maxMostWantedRank") > 0 ? UserDefaults.standard.integer(forKey: "maxMostWantedRank") : 100
        if onlyMW {
            if !MostWantedManager.shared.isMostWanted(callsign: call, maxRank: maxRank) {
                return false
            }
        }
        
        // 3. Worked before on this band
        if lotwManager.hasWorked(callsign: call, band: decode.band) {
            return false
        }
        
        // 4. In cooldown blacklist
        if let blacklistedAt = blacklistedCalls[call] {
            let elapsedMinutes = Date().timeIntervalSince(blacklistedAt) / 60.0
            if elapsedMinutes < Double(retryCooldownMinutes) {
                return false
            }
        }
        
        return true
    }

    func bridgeDecodeIfEnabled(decode: WSJTXDecode, rawData: Data, accepted: Bool) {
        let bridgePort = UserDefaults.standard.integer(forKey: "udpBridgePort")
        guard bridgePort > 0 else { return }
        
        if isFiltersEnabled && !accepted {
            return
        }
        
        server.sendRaw(data: rawData, toPort: UInt16(bridgePort))
    }

    private let usSynonyms = Set(["usa", "united states", "us"])
    private let usRegions = ["alaska", "hawaii", "puerto rico", "virgin islands", "guam"]

    private func countryMatches(_ country: String, in filters: [String]) -> Bool {
        let cleanCountry = country.trimmingCharacters(in: .whitespaces).lowercased()
        return filters.contains(where: { filter in
            let cleanFilter = filter.trimmingCharacters(in: .whitespaces).lowercased()
            if cleanFilter.isEmpty { return false }
            if cleanCountry.contains(cleanFilter) || cleanFilter.contains(cleanCountry) { return true }
            if cleanFilter == "deutschland" && cleanCountry.contains("germany") { return true }
            if cleanFilter == "russia" || cleanFilter == "russland" {
                if cleanCountry.contains("russia") { return true }
            }
            if usSynonyms.contains(cleanFilter) {
                if cleanCountry.contains("united states") || usRegions.contains(where: { cleanCountry.contains($0) }) { return true }
            }
            return false
        })
    }

    private func isCountryBlocked(_ country: String) -> Bool {
        return countryMatches(country, in: blockedCountries)
    }

    private func callsignMatches(_ callsign: String, in filters: [String]) -> Bool {
        let cleanCall = callsign.trimmingCharacters(in: .whitespaces).uppercased()
        return filters.contains(where: { filter in
            let cleanFilter = filter.trimmingCharacters(in: .whitespaces).uppercased()
            if cleanFilter.isEmpty { return false }
            return cleanCall.hasPrefix(cleanFilter) || cleanCall == cleanFilter
        })
    }

    private func isSpotterBlocked(_ spotter: String) -> Bool {
        if !allowedSpotterCountries.isEmpty {
            let spotterCountry = matcher.country(for: spotter)
            if !countryMatches(spotterCountry, in: allowedSpotterCountries) {
                return true
            }
        }
        if !allowedSpotterCallsigns.isEmpty {
            let cleanSpotter = spotter.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces).uppercased()
            if !callsignMatches(cleanSpotter, in: allowedSpotterCallsigns) {
                return true
            }
        }
        return false
    }

    private var recentSpots: [(id: UUID, dxCall: String, freq: Double, time: Date)] = []
    private let recentSpotsLock = NSLock()

    private func isDuplicateSpot(id: UUID, call: String, freq: Double, record: Bool) -> Bool {
        let now = Date()
        recentSpotsLock.lock()
        defer { recentSpotsLock.unlock() }
        recentSpots.removeAll { now.timeIntervalSince($0.time) > Double(duplicateSpotWindowMinutes * 60) }
        let isDup = recentSpots.contains(where: { $0.id != id && $0.dxCall == call && abs($0.freq - freq) < duplicateSpotFrequencyTolerance })
        if !isDup && record {
            recentSpots.append((id: id, dxCall: call, freq: freq, time: now))
        }
        return isDup
    }

    // MARK: - UI helper actions

    func addBlockedCountry(_ country: String) {
        let trimmed = country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !blockedCountries.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            blockedCountries.append(trimmed)
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeBlockedCountry(_ country: String) {
        blockedCountries.removeAll { $0.caseInsensitiveCompare(country) == .orderedSame }
        saveFilters()
    }

    func addAllowedCountry(_ country: String) {
        let trimmed = country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !allowedCountries.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            allowedCountries.append(trimmed)
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeAllowedCountry(_ country: String) {
        allowedCountries.removeAll { $0.caseInsensitiveCompare(country) == .orderedSame }
        saveFilters()
    }

    func toggleContinent(_ continent: String) {
        if disabledContinents.contains(continent) {
            disabledContinents.removeAll { $0 == continent }
        } else {
            disabledContinents.append(continent)
        }
        saveFilters()
        clearBlockedDecodes()
    }

    func setAllContinents(enabled: Bool) {
        if enabled {
            disabledContinents.removeAll()
        } else {
            disabledContinents = ["AF", "AN", "AS", "EU", "NA", "OC", "SA"]
        }
        saveFilters()
        clearBlockedDecodes()
    }

    func addBlockedCQZone(_ zone: Int) {
        if !blockedCQZones.contains(zone) {
            blockedCQZones.append(zone)
            blockedCQZones.sort()
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeBlockedCQZone(_ zone: Int) {
        blockedCQZones.removeAll { $0 == zone }
        saveFilters()
    }

    func addBlockedITUZone(_ zone: Int) {
        if !blockedITUZones.contains(zone) {
            blockedITUZones.append(zone)
            blockedITUZones.sort()
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeBlockedITUZone(_ zone: Int) {
        blockedITUZones.removeAll { $0 == zone }
        saveFilters()
    }

    func addAllowedDXCallsign(_ callsign: String) {
        let trimmed = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        if !allowedDXCallsigns.contains(trimmed) {
            allowedDXCallsigns.append(trimmed)
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeAllowedDXCallsign(_ callsign: String) {
        allowedDXCallsigns.removeAll { $0 == callsign }
        saveFilters()
    }

    func addAllowedSpotterCountry(_ country: String) {
        let trimmed = country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !allowedSpotterCountries.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            allowedSpotterCountries.append(trimmed)
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeAllowedSpotterCountry(_ country: String) {
        allowedSpotterCountries.removeAll { $0.caseInsensitiveCompare(country) == .orderedSame }
        saveFilters()
    }

    func addAllowedSpotterCallsign(_ callsign: String) {
        let trimmed = callsign.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return }
        if !allowedSpotterCallsigns.contains(trimmed) {
            allowedSpotterCallsigns.append(trimmed)
            saveFilters()
            clearBlockedDecodes()
        }
    }

    func removeAllowedSpotterCallsign(_ callsign: String) {
        allowedSpotterCallsigns.removeAll { $0 == callsign }
        saveFilters()
    }

    func allCountries() -> [String] {
        return matcher.allCountries().sorted()
    }

    func countrySuggestions(for query: String) -> [String] {
        let clean = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !clean.isEmpty else { return [] }
        return matcher.allCountries().filter { $0.lowercased().contains(clean) }.prefix(10).map { $0 }
    }

    func clearBlockedDecodes() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    // Conflict checking
    struct FilterConflict {
        let callsign: String
        let callsignCountry: String
        let allowedCountriesText: String
        let isTotalConflict: Bool
    }

    var spotterFilterConflict: FilterConflict? {
        guard !allowedSpotterCountries.isEmpty, !allowedSpotterCallsigns.isEmpty else { return nil }
        var conflictingCallsigns: [(callsign: String, country: String)] = []
        var matchingCount = 0
        for callsign in allowedSpotterCallsigns {
            let cleanCall = callsign.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces).uppercased()
            let country = matcher.country(for: cleanCall)
            if countryMatches(country, in: allowedSpotterCountries) {
                matchingCount += 1
            } else {
                conflictingCallsigns.append((callsign: callsign, country: country))
            }
        }
        guard let firstConflict = conflictingCallsigns.first else { return nil }
        let countriesStr = allowedSpotterCountries.joined(separator: ", ")
        let isTotal = (matchingCount == 0)
        return FilterConflict(callsign: firstConflict.callsign, callsignCountry: firstConflict.country, allowedCountriesText: countriesStr, isTotalConflict: isTotal)
    }

    var dxCallFilterConflict: FilterConflict? {
        guard !allowedCountries.isEmpty, !allowedDXCallsigns.isEmpty else { return nil }
        var conflictingCallsigns: [(callsign: String, country: String)] = []
        var matchingCount = 0
        for callsign in allowedDXCallsigns {
            let cleanCall = callsign.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces).uppercased()
            let country = matcher.country(for: cleanCall)
            if countryMatches(country, in: allowedCountries) {
                matchingCount += 1
            } else {
                conflictingCallsigns.append((callsign: callsign, country: country))
            }
        }
        guard let firstConflict = conflictingCallsigns.first else { return nil }
        let countriesStr = allowedCountries.joined(separator: ", ")
        let isTotal = (matchingCount == 0)
        return FilterConflict(callsign: firstConflict.callsign, callsignCountry: firstConflict.country, allowedCountriesText: countriesStr, isTotalConflict: isTotal)
    }

    func updatePropagationClusters() {
        scheduleRecalculations()
    }
    
    private func scheduleRecalculations() {
        pendingRecalculationWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.performRecalculations()
        }
        pendingRecalculationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func performRecalculations() {
        recalculatePropagationClusters()
        recalculateMostWantedDecodes()
        recalculateNewGridClusters()
    }
    
    private func recalculatePropagationClusters() {
        let currentDecodes = self.server.decodes
        let currentSpots = self.clusterSpots
        
        let window = UserDefaults.standard.integer(forKey: "mapTimeWindow") == 0 ? 30 : UserDefaults.standard.integer(forKey: "mapTimeWindow")
        let countWorkedBefore = UserDefaults.standard.bool(forKey: "mapCountWorkedBefore")
        
        let now = Date()
        let cutoff = now.addingTimeInterval(-Double(window) * 60)
        
        let allItems = currentDecodes + currentSpots
        
        let filteredItems = allItems.filter { decode in
            guard decode.receivedAt > cutoff else { return false }
            guard shouldAccept(decode: decode, recordDuplicates: false) else { return false }
            if !countWorkedBefore {
                let call = decode.callsign
                if !call.isEmpty && lotwManager.hasWorked(callsign: call, band: decode.band) {
                    return false
                }
            }
            return true
        }
        
        let grouped = Dictionary(grouping: filteredItems) { decode in
            decode.country
        }
        
        let clusters: [CountryCluster] = grouped.compactMap { (countryName, decodes) -> CountryCluster? in
            guard countryName != "OTHER", !countryName.isEmpty else { return nil }
            guard let coords = self.matcher.coordinates(forCountry: countryName) else { return nil }
            let first = decodes.first!
            let continent = first.continent
            
            var bandCounts: [String: Int] = [:]
            for d in decodes {
                bandCounts[d.band, default: 0] += 1
            }
            
            let bands = bandCounts.map { bandName, count in
                CountryCluster.BandInfo(name: bandName, count: count)
            }.sorted { self.bandOrder($0.name) < self.bandOrder($1.name) }
            
            return CountryCluster(
                id: countryName,
                country: countryName,
                continent: continent,
                latitude: coords.latitude,
                longitude: coords.longitude,
                spotCount: decodes.count,
                bands: bands
            )
        }
        
        self.propagationClusters = clusters.sorted { $0.country < $1.country }

        // Build propagation chart data by continent & band for accepted items ONLY
        let allContinentsList = ["EU", "NA", "AS", "SA", "AF", "OC", "AN"]
        var chartCounts: [String: [String: Int]] = [:]

        for decode in filteredItems {
            let rawCont = decode.continent.uppercased()
            let cont = allContinentsList.contains(rawCont) ? rawCont : "OTHER"
            let band = decode.band
            guard !band.isEmpty else { continue }
            chartCounts[cont, default: [:]][band, default: 0] += 1
        }

        var chartItems: [PropagationChartItem] = []
        for cont in allContinentsList + ["OTHER"] {
            if let bandMap = chartCounts[cont] {
                for (band, count) in bandMap {
                    chartItems.append(PropagationChartItem(continent: cont, band: band, count: count))
                }
            }
        }
        self.propagationChartData = chartItems
    }
    
    private func recalculateMostWantedDecodes() {
        var seen = Set<String>()
        var result: [WSJTXDecode] = []
        let combined = self.server.decodes + self.clusterSpots
        let filtered = combined
            .filter { decode in
                let call = decode.callsign
                guard !call.isEmpty else { return false }
                let isMW = decode.isMostWanted
                let hasWorkedOnBand = lotwManager.hasWorked(callsign: call, band: decode.band)
                return isMW && !hasWorkedOnBand && shouldAccept(decode: decode)
            }
            .sorted { a, b in
                a.snr > b.snr
            }
        for decode in filtered {
            let call = decode.callsign.uppercased()
            if !seen.contains(call) {
                seen.insert(call)
                result.append(decode)
            }
        }
        self.mostWantedDecodes = result.sorted { a, b in
            let rankA = a.mostWantedRank ?? 999
            let rankB = b.mostWantedRank ?? 999
            return rankA < rankB
        }
    }

    private func recalculateNewGridClusters() {
        let currentDecodes = self.server.decodes
        let currentSpots = self.clusterSpots
        
        let window = UserDefaults.standard.integer(forKey: "mapTimeWindow") == 0 ? 30 : UserDefaults.standard.integer(forKey: "mapTimeWindow")
        let now = Date()
        let cutoff = now.addingTimeInterval(-Double(window) * 60)
        let is4CharOnly = UserDefaults.standard.bool(forKey: "isNew4CharGridOnlyFilterEnabled")
        let is6CharOnly = UserDefaults.standard.bool(forKey: "isNew6CharGridOnlyFilterEnabled")
        
        let allItems = currentDecodes + currentSpots
        
        let filteredItems = allItems.filter { decode in
            guard decode.receivedAt > cutoff else { return false }
            guard let g = decode.grid, g.count >= 4 else { return false }
            let grid4 = String(g.prefix(4)).uppercased()
            
            if is6CharOnly {
                guard g.count >= 6 else { return false }
                let grid6 = String(g.prefix(6)).uppercased()
                guard !lotwManager.hasWorkedGrid6(grid6) else { return false }
            } else if is4CharOnly {
                guard !lotwManager.hasWorkedGrid(grid4) else { return false }
            } else {
                let grid6 = g.count >= 6 ? String(g.prefix(6)).uppercased() : nil
                let is4Worked = lotwManager.hasWorkedGrid(grid4)
                let is6Worked = grid6 != nil ? lotwManager.hasWorkedGrid6(grid6!) : true
                guard !is4Worked || !is6Worked else { return false }
            }
            
            guard shouldAccept(decode: decode, recordDuplicates: false) else { return false }
            return true
        }
        
        let grouped = Dictionary(grouping: filteredItems) { decode -> String in
            let g = decode.grid!.uppercased()
            if is6CharOnly && g.count >= 6 {
                return String(g.prefix(6))
            } else if g.count >= 6 && !lotwManager.hasWorkedGrid6(String(g.prefix(6))) {
                return String(g.prefix(6))
            }
            return String(g.prefix(4))
        }
        
        let clusters: [NewGridCluster] = grouped.compactMap { (gridKey, decodes) -> NewGridCluster? in
            guard let latLon = Maidenhead.locatorToLatLon(gridKey) else { return nil }
            let first = decodes.first!
            let country = first.country
            let continent = first.continent
            let is6Char = gridKey.count >= 6
            
            var bandCounts: [String: Int] = [:]
            var callSet = Set<String>()
            var latest = first.receivedAt
            
            for d in decodes {
                bandCounts[d.band, default: 0] += 1
                if !d.callsign.isEmpty {
                    callSet.insert(d.callsign.uppercased())
                }
                if d.receivedAt > latest {
                    latest = d.receivedAt
                }
            }
            
            let sortedBands = bandCounts.map { bandName, count in
                CountryCluster.BandInfo(name: bandName, count: count)
            }.sorted { self.bandOrder($0.name) < self.bandOrder($1.name) }
            
            return NewGridCluster(
                grid: gridKey,
                is6Char: is6Char,
                isBlocked: false,
                country: country,
                continent: continent,
                latitude: latLon.lat,
                longitude: latLon.lon,
                spotCount: decodes.count,
                calls: callSet.sorted(),
                bands: sortedBands,
                latestTime: latest
            )
        }
        
        self.newGridClusters = clusters.sorted { $0.grid < $1.grid }
    }

    func colorForBand(_ band: String) -> Color {
        switch band.uppercased() {
        case "160M": return Color(red: 0.4, green: 0.4, blue: 0.4)
        case "80M": return Color(red: 0.5, green: 0.0, blue: 0.5)
        case "60M": return Color(red: 0.0, green: 0.3, blue: 0.6)
        case "40M": return .blue
        case "30M": return Color(red: 0.0, green: 0.6, blue: 0.6)
        case "20M": return Color(red: 0.0, green: 0.7, blue: 0.0)
        case "17M": return Color(red: 0.6, green: 0.8, blue: 0.0)
        case "15M": return .orange
        case "12M": return Color(red: 0.9, green: 0.4, blue: 0.0)
        case "10M": return .red
        case "6M": return Color(red: 0.3, green: 0.3, blue: 0.3)
        default: return .gray
        }
    }

    func bandOrder(_ name: String) -> Int {
        switch name.uppercased() {
        case "160M": return 0; case "80M": return 1; case "60M": return 2; case "40M": return 3; case "30M": return 4
        case "20M": return 5; case "17M": return 6; case "15M": return 7; case "12M": return 8; case "10M": return 9; case "6M": return 10
        default: return 99
        }
    }

    func continentName(for code: String) -> String {
        switch code.uppercased() {
        case "EU": return "EUROPE"
        case "NA": return "NORTH AMERICA"
        case "AS": return "ASIA"
        case "SA": return "SOUTH AMERICA"
        case "AF": return "AFRICA"
        case "OC": return "OCEANIA"
        case "AN": return "ANTARCTICA"
        default: return "OTHER"
        }
    }

    func clearTable() {
        DispatchQueue.main.async {
            self.server.decodes.removeAll()
            self.clusterSpots.removeAll()
            self.mostWantedDecodes.removeAll()
            self.propagationClusters.removeAll()
        }
    }

    func sendToCluster(index: Int, text: String) {
        guard !text.isEmpty else { return }
        switch index {
        case 1:
            client1.send(text: text)
            addLog("Gesendet an Cluster 1: \(text)")
        case 2:
            client2.send(text: text)
            addLog("Gesendet an Cluster 2: \(text)")
        case 3:
            client3.send(text: text)
            addLog("Gesendet an Cluster 3: \(text)")
        default:
            break
        }
    }
}

