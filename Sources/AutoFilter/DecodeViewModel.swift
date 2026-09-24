import Observation
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
    public let targetCountry: String?
    public let targetCoordinate: CLLocationCoordinate2D
    public let distanceKm: Double?
    public let band: String

    public init(myCall: String, myGrid: String, myCoordinate: CLLocationCoordinate2D, targetCall: String, targetGrid: String?, targetCountry: String? = nil, targetCoordinate: CLLocationCoordinate2D, distanceKm: Double?, band: String) {
        self.myCall = myCall
        self.myGrid = myGrid
        self.myCoordinate = myCoordinate
        self.targetCall = targetCall
        self.targetGrid = targetGrid
        self.targetCountry = targetCountry
        self.targetCoordinate = targetCoordinate
        self.distanceKm = distanceKm
        self.band = band
    }

    public static func == (lhs: ActiveQSOPath, rhs: ActiveQSOPath) -> Bool {
        lhs.targetCall == rhs.targetCall &&
        lhs.myGrid == rhs.myGrid &&
        lhs.targetGrid == rhs.targetGrid &&
        lhs.targetCountry == rhs.targetCountry &&
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

public enum LogbookProvider: String, CaseIterable, Identifiable {
    case rumlog = "RUMlogNG"
    case lotw = "LoTW"
    case qrz = "QRZ.com"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .rumlog: return "RUMlogNG (macOS)"
        case .lotw: return "ARRL LoTW"
        case .qrz: return "QRZ.com"
        }
    }
    
    public var iconName: String {
        switch self {
        case .rumlog: return "macbook.and.iphone"
        case .lotw: return "globe.americas.fill"
        case .qrz: return "antenna.radiowaves.left.and.right"
        }
    }
}

public enum DXFilterSectionId: String, CaseIterable, Codable, Identifiable {
    case continents = "continents"
    case blockedCountries = "blockedCountries"
    case allowedCountries = "allowedCountries"
    case blockedCQZones = "blockedCQZones"
    case blockedITUZones = "blockedITUZones"
    case allowedCallsigns = "allowedCallsigns"
    case allowedGrids = "allowedGrids"
    case messageFilter = "messageFilter"
    case mostWantedOnly = "mostWantedOnly"
    case workedBefore = "workedBefore"
    case gridFilter = "gridFilter"
    case wsjtCQ = "wsjtCQ"
    case duplicates = "duplicates"
    
    public var id: String { rawValue }
    
    public static let defaultOrder: [DXFilterSectionId] = [
        .allowedGrids,
        .allowedCallsigns,
        .allowedCountries,
        .messageFilter,
        .continents,
        .blockedCountries,
        .blockedCQZones,
        .blockedITUZones,
        .mostWantedOnly,
        .workedBefore,
        .gridFilter,
        .wsjtCQ,
        .duplicates
    ]
}

public enum FilterOrderMode: String, Codable {
    case defaultOrder = "default"
    case custom = "custom"
}

@Observable
class DecodeViewModel {
    var displaySpots: [SpotRowData] = []
    private let maxDisplaySpots = 300
    func makeSpotRowData(for decode: WSJTXDecode, recordDuplicates: Bool = false) -> SpotRowData {
        let accepted = self.shouldAccept(decode: decode, recordDuplicates: recordDuplicates)
        let isWorked = self.lotwManager.hasWorkedRecently(callsign: decode.callsign, band: decode.band, duration: self.workedBeforeDuration, unit: self.workedBeforeUnit)
        
        let commentUpper = decode.message.uppercased()
        let isInteresting = commentUpper.contains("CQ") || commentUpper.contains("QRZ") || commentUpper.contains("TEST")
        
        let highlightMW = UserDefaults.standard.bool(forKey: "highlightMostWanted")
        let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
        
        return SpotRowData.from(
            decode: decode,
            myGrid: myGrid,
            isAccepted: accepted,
            isWorked: isWorked,
            isInteresting: isInteresting,
            highlightMostWanted: highlightMW
        )
    }
    
    func refreshDisplaySpotsBackground() {
        let current = self.displaySpots
        guard !current.isEmpty else { return }
        recalcQueue.async { [weak self] in
            guard let self = self else { return }
            let updated = current.map { self.makeSpotRowData(for: $0.rawDecode, recordDuplicates: false) }
            DispatchQueue.main.async {
                self.displaySpots = updated
            }
        }
    }


    private func checkActiveTargetCall(decode: WSJTXDecode) {
        if !self.currentTargetCall.isEmpty {
            let targetUpper = self.currentTargetCall.uppercased()
            let ownCall = (UserDefaults.standard.string(forKey: "lotwUsername") ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let msgUpper = decode.message.uppercased()
            let tokens = msgUpper.components(separatedBy: .whitespacesAndNewlines)
                .map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
                .filter { !$0.isEmpty }
            
            let isFromTarget = (decode.callsign.uppercased() == targetUpper) || (tokens.count >= 2 && tokens[1] == targetUpper)
            
            if isFromTarget && tokens.count >= 2 {
                let recipient = tokens[0]
                let isCQ = recipient.hasPrefix("CQ") || recipient == "QRZ" || recipient == "DE"
                let isForMe = !ownCall.isEmpty && (recipient == ownCall || recipient.contains(ownCall))
                if isForMe {
                    if !self.targetHasAnswered {
                        self.targetHasAnswered = true
                        self.addLog(self.isDe
                            ? "🤝 Antwort von \(targetUpper) empfangen! QSO läuft (Anrufer-Vorrang gesperrt)."
                            : "🤝 Reply from \(targetUpper) received! QSO active (inbound preemption locked).")
                    }
                } else if !isCQ {
                    let otherCall = recipient
                    let msg = self.isDe
                        ? "QSO abgebrochen: \(targetUpper) antwortet \(otherCall) (Kein Cooldown, bereit für nächsten Trigger)."
                        : "QSO aborted: \(targetUpper) replied to \(otherCall) (No cooldown, ready for next trigger)."
                    self.currentQSOStatus = msg
                    self.addLog("ℹ️ \(msg)")
                    
                    self.currentTargetCall = ""
                    self.targetHasAnswered = false
                    self.unansweredTargetAttempts = 0
                    self.qsoStartTime = nil
                    self.txEnabledStartTime = nil
                    self.lastTriggeredTarget = nil
                    self.txTriggerAttempts = 0
                    self.lastTxTriggerTime = nil
                    
                    self.server.sendHaltTx(autoTxOnly: false)
                }
            }
        }
    }

    // Cluster ingest buffering
    private var pendingClusterDecodes: [WSJTXDecode] = []
    private var pendingClusterReceivedDelta = 0
    private var pendingClusterForwardedDelta = 0
    private var isClusterFlushScheduled = false
    private let clusterIngestLock = NSLock()

    public let logsViewModel = LogsViewModel()
    public var isLogConsoleDetached: Bool {
        get { logsViewModel.isLogConsoleDetached }
        set { logsViewModel.isLogConsoleDetached = newValue }
    }
    public let mapState = PropagationMapState()

    var server = WSJTXServer()
    var lotwManager = LoTWManager()
    var qrzManager = QRZManager()
    var rumlogManager = RUMlogManager()
    var selectedCallsign: String = ""
    private var recalculationTimer: Timer?
    private var needsRecalculation = false
    private var isRecalculating = false
    private let recalcQueue = DispatchQueue(label: "com.autofilter.recalc", qos: .userInitiated)
    private var isDe: Bool { LanguageManager.shared.isGerman }
    var isAutoModeEnabled: Bool = false {
        didSet {
            if isAutoModeEnabled && StoreManager.shared.isTrialExpired {
                isAutoModeEnabled = false
                StoreManager.shared.triggerPurchasePrompt()
                return
            }
            if !isAutoModeEnabled {
                currentTargetCall = ""
                targetHasAnswered = false
                unansweredTargetAttempts = 0
                qsoStartTime = nil
                currentQSOStatus = isDe ? "Bereit" : "Ready"
                addLog(isDe ? "Auto Mode deaktiviert. Aktiver Anruf zurückgesetzt." : "Auto mode disabled. Active call reset.")
            } else {
                addLog(isDe ? "Auto Mode aktiviert." : "Auto mode enabled.")
            }
        }
    }
    var retryCooldownMinutes: Int = 10
    var currentQSOStatus: String = "Bereit"
    var logHistory: [String] = []
    
    // Filter Settings
    var blockedCountries: [String] = []
    var allowedCountries: [String] = []
    var allowedGrids: [String] = []
    var allowedSpotterCountries: [String] = []
    var allowedDXCallsigns: [String] = []
    var allowedSpotterCallsigns: [String] = []
    var disabledContinents: [String] = []
    var blockedCQZones: [Int] = []
    var blockedITUZones: [Int] = []
    
    var isFiltersEnabled: Bool = true {
        didSet {
            if isFiltersEnabled && StoreManager.shared.isTrialExpired {
                isFiltersEnabled = false
                StoreManager.shared.triggerPurchasePrompt()
            }
        }
    }
    var isWsjtSpecialFilterEnabled: Bool = false
    var isMessageFilterEnabled: Bool = false
    var messageFilterQuery: String = ""
    var isAutoModeOnlyCQEnabled: Bool = false
    var isAutoModeAnswerCallersEnabled: Bool = true
    var isAutoModePreemptInboundEnabled: Bool = true
    var autoModePreemptMaxAttempts: Int = 2
    var isAutoModePreemptInstantForMostWanted: Bool = true
    var isOnlyMostWantedFilterEnabled: Bool = false
    var maxMostWantedRank: Int = 100
    var isNew4CharGridOnlyFilterEnabled: Bool = false
    var isNew6CharGridOnlyFilterEnabled: Bool = false
    var isWorkedBeforeFilterEnabled: Bool = false
    var workedBeforeDuration: Int = 1
    var workedBeforeUnit: WorkedBeforeUnit = .months
    var isDuplicateFilterEnabled: Bool = true
    var duplicateSpotWindowMinutes: Int = 1
    var duplicateSpotFrequencyTolerance: Double = 0.5
    var isFilterDebugLoggingEnabled: Bool = false
    
    // Filter Order & Presets (First-Match Pipeline)
    var activeFilterOrderMode: FilterOrderMode = .defaultOrder
    var customFilterOrder: [DXFilterSectionId] = DXFilterSectionId.defaultOrder
    
    // Filter Profiles & Smart Presets
    var filterProfiles: [FilterProfile] = []
    var activeFilterProfileId: String = "system_allround"
    var isFilterProfileModified: Bool = false
    
    var activeFilterProfile: FilterProfile? {
        filterProfiles.first(where: { $0.id == activeFilterProfileId }) ?? filterProfiles.first
    }
    
    var activeFilterOrder: [DXFilterSectionId] {
        activeFilterOrderMode == .defaultOrder ? DXFilterSectionId.defaultOrder : customFilterOrder
    }
    
    func setFilterOrderMode(_ mode: FilterOrderMode) {
        activeFilterOrderMode = mode
        saveFilters()
    }
    
    func moveFilterSection(from source: IndexSet, to destination: Int) {
        var newOrder = activeFilterOrder
        newOrder.move(fromOffsets: source, toOffset: destination)
        customFilterOrder = newOrder
        activeFilterOrderMode = .custom
        saveFilters()
    }
    
    func moveFilterSection(id: DXFilterSectionId, direction: Int) {
        var current = activeFilterOrder
        guard let idx = current.firstIndex(of: id) else { return }
        let targetIdx = idx + direction
        guard targetIdx >= 0 && targetIdx < current.count else { return }
        let item = current.remove(at: idx)
        current.insert(item, at: targetIdx)
        customFilterOrder = current
        activeFilterOrderMode = .custom
        saveFilters()
    }
    
    func moveFilterSection(dragged: DXFilterSectionId, to target: DXFilterSectionId) {
        var order = activeFilterOrder
        guard let fromIndex = order.firstIndex(of: dragged),
              let toIndex = order.firstIndex(of: target),
              fromIndex != toIndex else { return }
        order.remove(at: fromIndex)
        order.insert(dragged, at: toIndex)
        customFilterOrder = order
        activeFilterOrderMode = .custom
        saveFilters()
    }
    
    let matcher = PrefixMatcher.shared
    
    private var pendingLogHistory: [String] = []
    private var pendingWsjtxLogs: [WSJTXRawLogEntry] = []
    private var pendingClusterLogs: [ClusterRawLogEntry] = []
    private var isLogFlushScheduled = false
    
    private func scheduleLogFlush() {
        guard !isLogFlushScheduled else { return }
        isLogFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.isLogFlushScheduled = false
            
            if !self.pendingLogHistory.isEmpty {
                self.logsViewModel.logHistory.append(contentsOf: self.pendingLogHistory)
                if self.logsViewModel.logHistory.count > 300 {
                    self.logsViewModel.logHistory.removeFirst(self.logsViewModel.logHistory.count - 300)
                }
                self.logHistory = self.logsViewModel.logHistory
                self.pendingLogHistory.removeAll()
            }
            if !self.pendingWsjtxLogs.isEmpty {
                self.logsViewModel.wsjtxRawLogs.append(contentsOf: self.pendingWsjtxLogs)
                if self.logsViewModel.wsjtxRawLogs.count > 300 {
                    self.logsViewModel.wsjtxRawLogs.removeFirst(self.logsViewModel.wsjtxRawLogs.count - 300)
                }
                self.wsjtxRawLogs = self.logsViewModel.wsjtxRawLogs
                self.pendingWsjtxLogs.removeAll()
            }
            if !self.pendingClusterLogs.isEmpty {
                self.logsViewModel.clusterRawLogs.append(contentsOf: self.pendingClusterLogs)
                if self.logsViewModel.clusterRawLogs.count > 300 {
                    self.logsViewModel.clusterRawLogs.removeFirst(self.logsViewModel.clusterRawLogs.count - 300)
                }
                self.clusterRawLogs = self.logsViewModel.clusterRawLogs
                self.pendingClusterLogs.removeAll()
            }
        }
    }
    
    func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.pendingLogHistory.append("[\(ts)] \(message)")
            self.scheduleLogFlush()
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
    private var targetHasAnswered: Bool = false
    private var unansweredTargetAttempts: Int = 0
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
    var isConnected1 = false
    var isConnected2 = false
    var isConnected3 = false
    
    var clusterError1: String? = nil
    var clusterError2: String? = nil
    var clusterError3: String? = nil
    
    var telnetClientCount = 0
    var telnetServerError: String? = nil
    var clusterSpots: [WSJTXDecode] = []
    var propagationClusters: [CountryCluster] = []
    var propagationChartData: [PropagationChartItem] = []
    var newGridClusters: [NewGridCluster] = []
    var mostWantedDecodes: [WSJTXDecode] = []
    var isMainTableScrollPaused: Bool = false {
        didSet {
            if isMainTableScrollPaused {
                frozenDisplaySpots = displaySpots
                frozenMainDecodes = server.decodes
            } else {
                frozenDisplaySpots = nil
                frozenMainDecodes = nil
            }
        }
    }
    var isLogScrollPaused: Bool = false {
        didSet {
            if isLogScrollPaused {
                frozenSystemLogs = (logHistory + lotwManager.logHistory + qrzManager.logHistory + rumlogManager.logHistory).sorted()
                frozenWSJTXLogs = wsjtxRawLogs
                frozenClusterLogs = clusterRawLogs
            } else {
                frozenSystemLogs = nil
                frozenWSJTXLogs = nil
                frozenClusterLogs = nil
            }
        }
    }
    var mainTableSearchText: String = ""
    var logConsoleSearchText: String = ""
    var frozenDisplaySpots: [SpotRowData]? = nil
    var frozenMainDecodes: [WSJTXDecode]? = nil
    var frozenSystemLogs: [String]? = nil
    var frozenWSJTXLogs: [WSJTXRawLogEntry]? = nil
    var frozenClusterLogs: [ClusterRawLogEntry]? = nil
    private var pendingRecalculationWorkItem: DispatchWorkItem?
    var totalReceived = 0
    var totalForwarded = 0
    var counterStartTime = Date()
    var wsjtxRawLogs: [WSJTXRawLogEntry] = []
    var clusterRawLogs: [ClusterRawLogEntry] = []
    
    let client1 = DXClusterClient()
    let client2 = DXClusterClient()
    let client3 = DXClusterClient()
    let telnetServer = DXClusterServer()
    var availableClusters: [ClusterServer] = []

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.currentQSOStatus = LanguageManager.shared.isGerman ? "Bereit" : "Ready"
        loadAvailableClusters()
        
        // Load filter settings from UserDefaults
        loadFilters()
        
        // Listen for trial expiration
        Task { @MainActor [weak self] in
            StoreManager.shared.onTrialExpired = { [weak self] in
                guard let self = self else { return }
                self.isFiltersEnabled = false
                self.isAutoModeEnabled = false
                self.addLog(LanguageManager.shared.isGerman
                    ? "⚠️ 60-Minuten-Testzeit abgelaufen. Filter auf Durchzug geschaltet & AutoQSO deaktiviert."
                    : "⚠️ 60-minute trial expired. Filters disabled (pass-through) & AutoQSO deactivated.")
            }
        }
        
        // Load CTY.DAT cache & Auto-refresh if > 14 days
        loadCtyDatabase()
        
        // Setup DX Clusters and local Telnet Server
        setupClusters()
        
        // Immediately start server on launch from UserDefaults with fallbacks
        let savedPort = UserDefaults.standard.integer(forKey: "udpPort")
        let actualPort = savedPort > 0 ? UInt16(savedPort) : UInt16(2237)
        let savedAddress = UserDefaults.standard.string(forKey: "udpAddress") ?? "224.0.0.1"
        server.start(port: actualPort, address: savedAddress)
        
        setupRecalculationTimer()
        
                server.onDecodesBatchReceived = { [weak self] batch in
            guard let self = self else { return }
            var acceptedCount = 0
            var newRows: [SpotRowData] = []
            
            for (decode, rawData) in batch {
                let row = self.makeSpotRowData(for: decode, recordDuplicates: true)
                newRows.append(row)
                
                self.bridgeDecodeIfEnabled(decode: decode, rawData: rawData, accepted: row.isAccepted)
                if !self.isFiltersEnabled || row.isAccepted {
                    acceptedCount += 1
                    if UserDefaults.standard.bool(forKey: "isWsjtTelnetOutputEnabled") {
                        self.broadcastWSJTSpot(decode: decode)
                    }
                }
                self.checkActiveTargetCall(decode: decode)
            }
            
            let window = UserDefaults.standard.integer(forKey: "mapTimeWindow") == 0 ? 30 : UserDefaults.standard.integer(forKey: "mapTimeWindow")
            let cutoff = Date().addingTimeInterval(-Double(window) * 60)
            
            var combined = (newRows + self.displaySpots).filter { $0.receivedAt >= cutoff }
            if combined.count > self.maxDisplaySpots {
                combined.removeSubrange(self.maxDisplaySpots...)
            }
            self.displaySpots = combined
            
            self.mapState.totalReceived += batch.count
            self.mapState.totalForwarded += acceptedCount
            self.updatePropagationClusters()
            self.handleDecodesBatchForAutoQSO(batch.map { $0.0 })
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
            self.mapState.totalReceived += 1
            if accepted {
                self.mapState.totalForwarded += 1
            }
            self.updatePropagationClusters()
            self.checkActiveTargetCall(decode: decode)
        }
        
        server.onRawLogReceived = { [weak self] type, message in
            guard let self = self else { return }
            let entry = WSJTXRawLogEntry(timestamp: Date(), type: type, message: message)
            self.pendingWsjtxLogs.append(entry)
            self.scheduleLogFlush()
        }
        
        server.objectWillChange
            .throttle(for: .seconds(3), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                self?.evaluateAutoQSO()
            }
            .store(in: &cancellables)
            
        server.onQSOLogged = { [weak self] newEntries in
            guard let self = self else { return }
            self.lotwManager.mergeEntries(newEntries)
            
            for entry in newEntries {
                let callUpper = entry.callsign.uppercased()
                self.blacklistedCalls[callUpper] = Date()
                if callUpper == self.currentTargetCall.uppercased() || self.currentTargetCall.isEmpty {
                    self.currentQSOStatus = self.isDe
                        ? "QSO mit \(entry.callsign) erfolgreich beendet!"
                        : "QSO with \(entry.callsign) successfully completed!"
                    self.currentTargetCall = ""
                    self.targetHasAnswered = false
                    self.unansweredTargetAttempts = 0
                    self.qsoStartTime = nil
                    self.txEnabledStartTime = nil
                    self.lastTriggeredTarget = nil
                    self.txTriggerAttempts = 0
                    self.lastTxTriggerTime = nil
                }
            }
            
            // Auto-trigger Logbook Sync depending on active logbook provider
            let providerRaw = UserDefaults.standard.string(forKey: "activeLogbookProvider") ?? LogbookProvider.rumlog.rawValue
            let provider = LogbookProvider(rawValue: providerRaw) ?? .rumlog
            
            switch provider {
            case .rumlog:
                self.syncRUMLog(fullSync: false)
            case .qrz:
                let qrzKey = UserDefaults.standard.string(forKey: "qrzApiKey") ?? ""
                if !qrzKey.isEmpty {
                    self.syncQRZ(apiKey: qrzKey, fullSync: false)
                }
            case .lotw:
                let user = UserDefaults.standard.string(forKey: "lotwUsername") ?? ""
                let pass = UserDefaults.standard.string(forKey: "lotwPassword") ?? ""
                if !user.isEmpty && !pass.isEmpty {
                    self.lotwManager.downloadLoTW(username: user, password: pass, fullSync: false)
                }
            }
        }
        
        server.onHaltTx = { [weak self] in
            guard let self = self else { return }
            if !self.currentTargetCall.isEmpty {
                let call = self.currentTargetCall
                self.blacklistedCalls[call.uppercased()] = Date()
                self.currentQSOStatus = self.isDe
                    ? "QSO mit \(call) abgebrochen. Gesperrt für \(self.retryCooldownMinutes) Min."
                    : "QSO with \(call) aborted. Blocked for \(self.retryCooldownMinutes) min."
                self.currentTargetCall = ""
                self.targetHasAnswered = false
                self.unansweredTargetAttempts = 0
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
        var targetCountry: String? = nil
        
        var matching: WSJTXDecode? = server.decodes.first(where: { $0.callsign.uppercased() == targetCall && $0.grid != nil && !($0.grid!.isEmpty) })
        if matching == nil {
            matching = clusterSpots.first(where: { $0.callsign.uppercased() == targetCall && $0.grid != nil && !($0.grid!.isEmpty) })
        }
        
        if let matching = matching,
           let g = matching.grid, g.count >= 4,
           let ll = Maidenhead.locatorToLatLon(g) {
            targetGrid = String(g.prefix(6)).uppercased()
            targetCoord = CLLocationCoordinate2D(latitude: ll.lat, longitude: ll.lon)
        }
        
        let resolvedCountry = matcher.country(for: targetCall)
        if resolvedCountry != "OTHER" && !resolvedCountry.isEmpty {
            targetCountry = resolvedCountry
        }
        
        if targetCoord == nil {
            if let c = targetCountry, let coords = matcher.coordinates(forCountry: c) {
                targetCoord = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
            } else if let coords = matcher.coordinates(for: targetCall) {
                targetCoord = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
            }
        }
        
        guard let finalTargetCoord = targetCoord else { return nil }
        
        let dist: Double?
        if let tg = targetGrid {
            dist = Maidenhead.distanceKm(from: myGrid, to: tg)
        } else {
            dist = Maidenhead.distanceKm(from: myCoord, to: finalTargetCoord)
        }
        
        let band = server.decodes.first(where: { $0.callsign.uppercased() == targetCall })?.band ?? ""
        
        return ActiveQSOPath(
            myCall: "MY QTH",
            myGrid: myGrid,
            myCoordinate: myCoord,
            targetCall: targetCall,
            targetGrid: targetGrid,
            targetCountry: targetCountry,
            targetCoordinate: finalTargetCoord,
            distanceKm: dist,
            band: band
        )
    }
    

    func isInboundCallToMe(_ decode: WSJTXDecode, ownCall: String) -> Bool {
        guard !ownCall.isEmpty else { return false }
        let clean = decode.message.replacingOccurrences(of: "<", with: " ").replacingOccurrences(of: ">", with: " ").uppercased()
        let tokens = clean.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }.filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return false }
        let targetCall = decode.callsign.uppercased()
        guard !targetCall.isEmpty && targetCall != ownCall else { return false }
        return tokens[0] == ownCall
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
                    addLog(isDe ? "✅ WSJT-X Sende-Bereitschaft (TX BEREIT) erfolgreich erkannt." : "✅ WSJT-X transmit readiness (TX READY) successfully detected.")
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
                            let msg = isDe
                                ? "WSJT-X hat den Anruf auf \(failedCall) nach 3 Versuchen nicht gestartet (Verbindung prüfen)."
                                : "WSJT-X did not start call to \(failedCall) after 3 attempts (check connection)."
                            currentQSOStatus = isDe ? "Anruf-Trigger fehlgeschlagen." : "Call trigger failed."
                            addLog("⚠️ \(msg)")
                            
                            // Reset state
                            currentTargetCall = ""
                            targetHasAnswered = false
                            unansweredTargetAttempts = 0
                            qsoStartTime = nil
                            txEnabledStartTime = nil
                            lastTriggeredTarget = nil
                            txTriggerAttempts = 0
                            lastTxTriggerTime = nil
                            return
                        } else {
                            txTriggerAttempts += 1
                            lastTxTriggerTime = Date()
                            addLog(isDe
                                ? "🔁 WSJT-X hat noch nicht gesendet. Erneuter Anruf-Versuch (\(txTriggerAttempts)/3) für \(currentTargetCall)..."
                                : "🔁 WSJT-X has not transmitted yet. Retrying call (\(txTriggerAttempts)/3) for \(currentTargetCall)...")
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
                        let msg = isDe
                            ? "QSO mit \(failedCall) nach nur einem Sende-Zyklus (\(Int(elapsed))s) abgebrochen (Keine Quarantäne)."
                            : "QSO with \(failedCall) aborted after single transmit cycle (\(Int(elapsed))s) (No quarantine)."
                        currentQSOStatus = msg
                        addLog("ℹ️ \(msg)")
                    } else {
                        // "Wenn 'TX Bereit' danach wieder aus ist ohne das ein QSO geloggt wurde, Call in Cooldown nehmen."
                        blacklistedCalls[failedCall.uppercased()] = Date()
                        let msg = isDe
                            ? "QSO mit \(failedCall) nach \(Int(elapsed))s erfolglos beendet (TX Bereit aus). Gesperrt für \(retryCooldownMinutes) Min."
                            : "QSO with \(failedCall) ended unsuccessfully after \(Int(elapsed))s (TX Ready off). Blocked for \(retryCooldownMinutes) min."
                        currentQSOStatus = msg
                        addLog("⚠️ \(msg)")
                    }
                    
                    // Reset target
                    currentTargetCall = ""
                    targetHasAnswered = false
                    unansweredTargetAttempts = 0
                    qsoStartTime = nil
                    txEnabledStartTime = nil
                    lastTriggeredTarget = nil
                    txTriggerAttempts = 0
                    lastTxTriggerTime = nil
                    return
                } else {
                    // stuck state workaround
                    currentTargetCall = ""
                    targetHasAnswered = false
                    unansweredTargetAttempts = 0
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
        let onlyMW = isOnlyMostWantedFilterEnabled
        let maxRank = maxMostWantedRank
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
            let isInbound = isAutoModeAnswerCallersEnabled && isInboundCallToMe(decode, ownCall: ownCall)
            
            let isEligible = isAutoModeOnlyCQEnabled ? (isCQ || isInbound) : (isCQ || is73 || isInbound)
            
            if isEligible {
                totalCQsOr73s += 1
                
                // DX Filter Check
                if !shouldAccept(decode: decode) {
                    let key = isDe ? "Durch DX-Filter blockiert" : "Blocked by DX filter"
                    skippedCounts[key] = (skippedCounts[key] ?? 0) + 1
                    continue
                }
                
                // Strikter DXCC / Most Wanted Filter wenn nur Most Wanted erlaubt
                if onlyMW {
                    guard MostWantedManager.shared.isMostWanted(callsign: call, maxRank: maxRank) else {
                        let key = isDe ? "Nicht in Most Wanted (\(maxRank))" : "Not in Most Wanted (\(maxRank))"
                        skippedCounts[key] = (skippedCounts[key] ?? 0) + 1
                        continue
                    }
                }
                
                // Check if not worked on this band (or meets the worked-before threshold)
                let isWorkedBlocked: Bool
                if isWorkedBeforeFilterEnabled {
                    isWorkedBlocked = lotwManager.hasWorkedRecently(callsign: call, band: decode.band, duration: workedBeforeDuration, unit: workedBeforeUnit)
                } else {
                    isWorkedBlocked = lotwManager.hasWorked(callsign: call, band: decode.band)
                }
                
                if !isWorkedBlocked {
                    // Check if callsign is currently in failure/aborted cooldown
                    if let blacklistedAt = blacklistedCalls[call] {
                        if isInbound {
                            // Station is actively calling us! Lift quarantine cooldown immediately.
                            blacklistedCalls.removeValue(forKey: call)
                            addLog(isDe
                                ? "ℹ️ Eingehender Anruf von \(call): Sperrzeit aufgehoben, da Station uns aktiv anruft."
                                : "ℹ️ Incoming call from \(call): Quarantine lifted because station is calling us directly.")
                        } else {
                            let elapsedMinutes = Date().timeIntervalSince(blacklistedAt) / 60.0
                            if elapsedMinutes < Double(retryCooldownMinutes) {
                                let key = isDe ? "In Sperrzeit (\(Int(Double(retryCooldownMinutes) - elapsedMinutes) + 1) Min.)" : "In quarantine (\(Int(Double(retryCooldownMinutes) - elapsedMinutes) + 1) min.)"
                                skippedCounts[key] = (skippedCounts[key] ?? 0) + 1
                                continue // Still in retry cooldown
                            } else {
                                blacklistedCalls.removeValue(forKey: call) // Cooldown expired
                            }
                        }
                    }
                    candidates.append(decode)
                } else {
                    let msg: String
                    if isDe {
                        msg = isWorkedBeforeFilterEnabled ? "Vor kurzem auf \(decode.band) gearbeitet" : "Bereits auf \(decode.band) gearbeitet"
                    } else {
                        msg = isWorkedBeforeFilterEnabled ? "Recently worked on \(decode.band)" : "Already worked on \(decode.band)"
                    }
                    skippedCounts[msg] = (skippedCounts[msg] ?? 0) + 1
                }
            }
        }
        
        if candidates.isEmpty {
            if totalCQsOr73s > 0 {
                let reasons = skippedCounts.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                let targetType = isAutoModeOnlyCQEnabled ? "CQs" : "CQs/73s"
                let evalMsg = isDe
                    ? "Auswertung: Keine Anruf-Kandidaten unter \(totalCQsOr73s) \(targetType) gefunden (\(reasons))"
                    : "Evaluation: No calling candidates among \(totalCQsOr73s) \(targetType) found (\(reasons))"
                logFilterDecision(evalMsg)
            }
            return
        }
        
        let sortedCandidates = rankCandidates(candidates, ownCall: ownCall)
        let bestTarget = sortedCandidates[0]
        let bestCall = bestTarget.callsign.uppercased()
        
        currentTargetCall = bestCall
        targetHasAnswered = false
        unansweredTargetAttempts = 1
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
        
        currentQSOStatus = isDe
            ? "AutoQSO: Rufe \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo)..."
            : "AutoQSO: Calling \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo)..."
        addLog(isDe
            ? "🚀 Rufe \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo) [Msg: \(bestTarget.message)]"
            : "🚀 Calling \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo) [Msg: \(bestTarget.message)]")
        
        print("AutoQSO Engine: Starte Anruf -> \(bestCall) (\(bestTarget.band))\(mwInfo)\(distInfo) [Msg: \(bestTarget.message)]")
        sendReply(for: bestTarget)
    }
    
    func rankCandidates(_ decodes: [WSJTXDecode], ownCall: String) -> [WSJTXDecode] {
        let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
        let prioritizeMW = UserDefaults.standard.object(forKey: "prioritizeMostWanted") as? Bool ?? true
        let maxRank = maxMostWantedRank
        
        return decodes.sorted { d1, d2 in
            let inb1 = self.isInboundCallToMe(d1, ownCall: ownCall)
            let inb2 = self.isInboundCallToMe(d2, ownCall: ownCall)
            if inb1 != inb2 {
                return inb1 && !inb2 // Direct inbound caller takes top priority
            }
            
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
    }
    
    private func handleDecodesBatchForAutoQSO(_ decodes: [WSJTXDecode]) {
        guard isAutoModeEnabled else { return }
        let ownCall = (UserDefaults.standard.string(forKey: "lotwUsername") ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ownCall.isEmpty else { return }
        
        // 1. Wenn kein Anruf aktiv ist, sofort Auswertung für nächsten Trigger starten
        if currentTargetCall.isEmpty {
            evaluateAutoQSO()
            return
        }
        
        // 2. Aktiven Anruf auf Antwort prüfen
        let targetUpper = currentTargetCall.uppercased()
        for decode in decodes {
            let decodeCall = decode.callsign.uppercased()
            let clean = decode.message.replacingOccurrences(of: "<", with: " ").replacingOccurrences(of: ">", with: " ").uppercased()
            let tokens = clean.components(separatedBy: .whitespacesAndNewlines)
                .map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
                .filter { !$0.isEmpty }
            
            let isFromTarget = (decodeCall == targetUpper) || (tokens.count >= 2 && tokens[1] == targetUpper)
            if isFromTarget && tokens.count >= 2 {
                let recipient = tokens[0]
                let isForMe = recipient == ownCall || recipient.contains(ownCall)
                if isForMe {
                    if !targetHasAnswered {
                        targetHasAnswered = true
                        addLog(isDe
                            ? "🤝 Antwort von \(targetUpper) empfangen! QSO läuft (Anrufer-Vorrang gesperrt)."
                            : "🤝 Reply from \(targetUpper) received! QSO active (inbound preemption locked).")
                    }
                }
            }
        }
        
        // 3. Wenn Zielstation geantwortet hat: QSO ist etabliert -> nicht abbrechen!
        if targetHasAnswered {
            return
        }
        
        // 4. Zielstation hat in diesem Zyklus nicht geantwortet.
        if server.isTxEnabled || txEnabledStartTime != nil {
            unansweredTargetAttempts += 1
        }
        
        // 5. Prüfen ob Inbound Preemption aktiviert ist
        guard isAutoModePreemptInboundEnabled && isAutoModeAnswerCallersEnabled else { return }
        
        // 6. Eingehende Anrufer suchen, die durch den Filter kommen
        var inboundCandidates: [WSJTXDecode] = []
        for decode in decodes {
            if decode.isClusterSpot { continue }
            let caller = decode.callsign.uppercased()
            guard !caller.isEmpty && caller != ownCall && caller != targetUpper else { continue }
            guard isInboundCallToMe(decode, ownCall: ownCall) else { continue }
            guard isAutoQSOInteresting(decode: decode) else { continue }
            inboundCandidates.append(decode)
        }
        
        guard !inboundCandidates.isEmpty else { return }
        
        // 7. Prüfen ob Wechselkriterium erfüllt ist (Versuchsschwelle erreicht oder Most Wanted Sofort-Wechsel)
        let maxRank = maxMostWantedRank
        let hasMWCaller = inboundCandidates.contains {
            MostWantedManager.shared.isMostWanted(callsign: $0.callsign, maxRank: maxRank)
        }
        
        let shouldJump = (unansweredTargetAttempts >= autoModePreemptMaxAttempts) || (isAutoModePreemptInstantForMostWanted && hasMWCaller)
        
        if shouldJump {
            let rankedInbound = rankCandidates(inboundCandidates, ownCall: ownCall)
            guard let bestCaller = rankedInbound.first else { return }
            let bestCall = bestCaller.callsign.uppercased()
            let oldTarget = currentTargetCall
            let attemptsDone = unansweredTargetAttempts
            
            // Alte Station in kurzen Soft-Cooldown (2 Minuten) setzen
            let softCooldownSec = 120.0
            let totalCooldownSec = Double(retryCooldownMinutes * 60)
            let offset = totalCooldownSec - softCooldownSec
            blacklistedCalls[oldTarget] = Date().addingTimeInterval(-max(0, offset))
            
            let mwTag: String
            if let rank = MostWantedManager.shared.rankForCallsign(bestCall), rank <= maxRank {
                mwTag = " [🔥 MOST WANTED #\(rank)]"
            } else {
                mwTag = ""
            }
            
            let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
            let distInfo = bestCaller.distanceKm(myGrid: myGrid).map { String(format: " [%.0f km]", $0) } ?? ""
            
            let jumpMsg = isDe
                ? "🔀 Vorrang für Anrufer: \(oldTarget) antwortet nach \(attemptsDone) Versuchen nicht -> Wechsel zu Anrufer \(bestCall)\(mwTag)\(distInfo) (\(bestCaller.band))!"
                : "🔀 Inbound preemption: \(oldTarget) did not answer after \(attemptsDone) attempts -> Switching to caller \(bestCall)\(mwTag)\(distInfo) (\(bestCaller.band))!"
            addLog(jumpMsg)
            currentQSOStatus = jumpMsg
            
            // Neuen Zielzustand setzen
            currentTargetCall = bestCall
            targetHasAnswered = false
            unansweredTargetAttempts = 1
            qsoStartTime = Date()
            lastTriggeredTarget = bestCaller
            txTriggerAttempts = 1
            lastTxTriggerTime = Date()
            txEnabledStartTime = Date()
            
            // Anruf sofort an WSJT-X senden
            sendReply(for: bestCaller)
        } else {
            let callerNames = inboundCandidates.map { $0.callsign }.joined(separator: ", ")
            addLog(isDe
                ? "⏳ Anruf von \(callerNames) empfangen. Warte auf Antwort von \(targetUpper) (Versuch \(unansweredTargetAttempts)/\(autoModePreemptMaxAttempts))..."
                : "⏳ Inbound call from \(callerNames) received. Waiting for \(targetUpper) (Attempt \(unansweredTargetAttempts)/\(autoModePreemptMaxAttempts))...")
        }
    }
    
    func syncQRZ(apiKey: String, fullSync: Bool = true) {
        qrzManager.downloadQRZ(apiKey: apiKey, fullSync: fullSync) { [weak self] qrzEntries in
            self?.lotwManager.mergeEntries(qrzEntries)
        }
    }
    
    func syncRUMLog(fullSync: Bool = true) {
        rumlogManager.syncRUMlog(fullSync: fullSync) { [weak self] rumlogEntries in
            self?.lotwManager.mergeEntries(rumlogEntries)
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
            id: "AutoFilter",
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
        let appSupport = paths[0].appendingPathComponent("com.gecando.autofilter", isDirectory: true)
        let legacyFilterSupport = paths[0].appendingPathComponent("com.dj6gi.AutoFilter", isDirectory: true)
        let legacyQsoSupport = paths[0].appendingPathComponent("com.dj6gi.AutoQSO", isDirectory: true)
        if !FileManager.default.fileExists(atPath: appSupport.path) {
            if FileManager.default.fileExists(atPath: legacyFilterSupport.path) {
                try? FileManager.default.copyItem(at: legacyFilterSupport, to: appSupport)
            } else if FileManager.default.fileExists(atPath: legacyQsoSupport.path) {
                try? FileManager.default.copyItem(at: legacyQsoSupport, to: appSupport)
            }
        }
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
                self.addLog(self.isDe ? "CTY.DAT erfolgreich im Hintergrund geladen." : "CTY.DAT successfully loaded in background.")
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
            self.pendingClusterLogs.append(ClusterRawLogEntry(timestamp: Date(), message: "[\(ts)] [\(label)] \(line)"))
            self.scheduleLogFlush()
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
            // Updated via @Observable
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
        
        // Filter evaluation and telnet broadcast directly on background queue
        let accepted = self.shouldAccept(decode: decode, recordDuplicates: true)
        if !self.isFiltersEnabled || accepted {
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
        
        clusterIngestLock.lock()
        pendingClusterDecodes.append(decode)
        pendingClusterReceivedDelta += 1
        if !self.isFiltersEnabled || accepted {
            pendingClusterForwardedDelta += 1
        }
        let schedule = !isClusterFlushScheduled
        isClusterFlushScheduled = true
        clusterIngestLock.unlock()
        
        guard schedule else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            self.clusterIngestLock.lock()
            self.isClusterFlushScheduled = false
            let batch = self.pendingClusterDecodes
            let recDelta = self.pendingClusterReceivedDelta
            let fwdDelta = self.pendingClusterForwardedDelta
            self.pendingClusterDecodes.removeAll(keepingCapacity: true)
            self.pendingClusterReceivedDelta = 0
            self.pendingClusterForwardedDelta = 0
            self.clusterIngestLock.unlock()
            
            guard !batch.isEmpty else { return }
            
            let window = UserDefaults.standard.integer(forKey: "mapTimeWindow") == 0 ? 30 : UserDefaults.standard.integer(forKey: "mapTimeWindow")
            let cutoff = Date().addingTimeInterval(-Double(window) * 60)
            
            var newClusterSpots = (batch + self.clusterSpots).filter { $0.receivedAt >= cutoff }
            if newClusterSpots.count > 300 {
                newClusterSpots.removeSubrange(300...)
            }
            self.clusterSpots = newClusterSpots
            
            var newServerDecodes = (batch + self.server.decodes).filter { $0.receivedAt >= cutoff }
            if newServerDecodes.count > 300 {
                newServerDecodes.removeSubrange(300...)
            }
            self.server.decodes = newServerDecodes
            
            let newRows = batch.map { self.makeSpotRowData(for: $0, recordDuplicates: false) }
            var combined = (newRows + self.displaySpots).filter { $0.receivedAt >= cutoff }
            if combined.count > self.maxDisplaySpots {
                combined.removeSubrange(self.maxDisplaySpots...)
            }
            self.displaySpots = combined
            
            self.mapState.totalReceived += recDelta
            self.mapState.totalForwarded += fwdDelta
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
                self.addLog(self.isDe ? "CTY.DAT erfolgreich im Hintergrund aktualisiert." : "CTY.DAT successfully updated in background.")
            }
        }.resume()
    }
    
    func loadAvailableClusters() {
        if let data = UserDefaults.standard.data(forKey: "availableClusters"),
           let list = try? JSONDecoder().decode([ClusterServer].self, from: data) {
            self.availableClusters = list
        } else {
            self.availableClusters = ClusterServer.defaultClusters
            if let data = try? JSONEncoder().encode(ClusterServer.defaultClusters) {
                UserDefaults.standard.set(data, forKey: "availableClusters")
            }
        }
    }
    
    /// Lädt alle Einstellungen und Zustände neu aus den synchronisierten Speichern
    func reloadAllSettingsFromStorage() {
        loadAvailableClusters()
        loadFilters()
        reconnectClusters()
        lotwManager.loadLog()
    }

    func loadFilters() {
        let defaults = UserDefaults.standard
        isFiltersEnabled = defaults.object(forKey: "dx_filters_enabled_global") as? Bool ?? true
        blockedCountries = defaults.stringArray(forKey: "blockedCountries") ?? []
        allowedCountries = defaults.stringArray(forKey: "allowedCountries") ?? []
        allowedGrids = defaults.stringArray(forKey: "allowedGrids") ?? []
        allowedSpotterCountries = defaults.stringArray(forKey: "allowedSpotterCountries") ?? []
        allowedDXCallsigns = defaults.stringArray(forKey: "allowedDXCallsigns") ?? []
        allowedSpotterCallsigns = defaults.stringArray(forKey: "allowedSpotterCallsigns") ?? []
        disabledContinents = defaults.stringArray(forKey: "disabledContinents") ?? []
        blockedCQZones = defaults.array(forKey: "blockedCQZones") as? [Int] ?? []
        blockedITUZones = defaults.array(forKey: "blockedITUZones") as? [Int] ?? []
        
        isWsjtSpecialFilterEnabled = defaults.bool(forKey: "isWsjtSpecialFilterEnabled")
        isMessageFilterEnabled = defaults.bool(forKey: "isMessageFilterEnabled")
        messageFilterQuery = defaults.string(forKey: "messageFilterQuery") ?? ""
        isAutoModeOnlyCQEnabled = defaults.bool(forKey: "isAutoModeOnlyCQEnabled")
        isAutoModeAnswerCallersEnabled = defaults.object(forKey: "isAutoModeAnswerCallersEnabled") as? Bool ?? true
        isAutoModePreemptInboundEnabled = defaults.object(forKey: "isAutoModePreemptInboundEnabled") as? Bool ?? true
        autoModePreemptMaxAttempts = defaults.integer(forKey: "autoModePreemptMaxAttempts") > 0 ? defaults.integer(forKey: "autoModePreemptMaxAttempts") : 2
        isAutoModePreemptInstantForMostWanted = defaults.object(forKey: "isAutoModePreemptInstantForMostWanted") as? Bool ?? true
        isOnlyMostWantedFilterEnabled = defaults.bool(forKey: "onlyMostWanted")
        maxMostWantedRank = defaults.integer(forKey: "maxMostWantedRank") > 0 ? defaults.integer(forKey: "maxMostWantedRank") : 100
        isNew4CharGridOnlyFilterEnabled = defaults.bool(forKey: "isNew4CharGridOnlyFilterEnabled")
        isNew6CharGridOnlyFilterEnabled = defaults.bool(forKey: "isNew6CharGridOnlyFilterEnabled")
        isWorkedBeforeFilterEnabled = defaults.bool(forKey: "isWorkedBeforeFilterEnabled")
        if defaults.object(forKey: "workedBeforeDuration") != nil {
            workedBeforeDuration = max(0, min(999, defaults.integer(forKey: "workedBeforeDuration")))
        } else {
            workedBeforeDuration = 1
        }
        if let unitStr = defaults.string(forKey: "workedBeforeUnit"), let unit = WorkedBeforeUnit(rawValue: unitStr) {
            workedBeforeUnit = unit
        } else {
            workedBeforeUnit = .months
        }
        isDuplicateFilterEnabled = defaults.object(forKey: "isDuplicateFilterEnabled") as? Bool ?? true
        duplicateSpotWindowMinutes = defaults.integer(forKey: "duplicateSpotWindowMinutes")
        if duplicateSpotWindowMinutes == 0 { duplicateSpotWindowMinutes = 1 }
        duplicateSpotFrequencyTolerance = defaults.double(forKey: "duplicateSpotFrequencyTolerance")
        if duplicateSpotFrequencyTolerance == 0.0 { duplicateSpotFrequencyTolerance = 0.5 }
        isFilterDebugLoggingEnabled = defaults.bool(forKey: "isFilterDebugLoggingEnabled")
        
        if let modeStr = defaults.string(forKey: "filterOrderMode"), let mode = FilterOrderMode(rawValue: modeStr) {
            activeFilterOrderMode = mode
        } else {
            activeFilterOrderMode = .defaultOrder
        }
        
        if let savedCustom = defaults.stringArray(forKey: "customFilterOrder") {
            let parsed = savedCustom.compactMap { DXFilterSectionId(rawValue: $0) }
            var completeOrder = parsed
            for section in DXFilterSectionId.defaultOrder {
                if !completeOrder.contains(section) {
                    completeOrder.append(section)
                }
            }
            customFilterOrder = completeOrder
        } else {
            customFilterOrder = DXFilterSectionId.defaultOrder
        }
        loadFilterProfiles()
    }
    
    func saveFilters() {
        let defaults = UserDefaults.standard
        defaults.set(isFiltersEnabled, forKey: "dx_filters_enabled_global")
        defaults.set(blockedCountries, forKey: "blockedCountries")
        defaults.set(allowedCountries, forKey: "allowedCountries")
        defaults.set(allowedGrids, forKey: "allowedGrids")
        defaults.set(allowedSpotterCountries, forKey: "allowedSpotterCountries")
        defaults.set(allowedDXCallsigns, forKey: "allowedDXCallsigns")
        defaults.set(allowedSpotterCallsigns, forKey: "allowedSpotterCallsigns")
        defaults.set(disabledContinents, forKey: "disabledContinents")
        defaults.set(blockedCQZones, forKey: "blockedCQZones")
        defaults.set(blockedITUZones, forKey: "blockedITUZones")
        
        defaults.set(isWsjtSpecialFilterEnabled, forKey: "isWsjtSpecialFilterEnabled")
        defaults.set(isMessageFilterEnabled, forKey: "isMessageFilterEnabled")
        defaults.set(messageFilterQuery, forKey: "messageFilterQuery")
        defaults.set(isAutoModeOnlyCQEnabled, forKey: "isAutoModeOnlyCQEnabled")
        defaults.set(isAutoModeAnswerCallersEnabled, forKey: "isAutoModeAnswerCallersEnabled")
        defaults.set(isAutoModePreemptInboundEnabled, forKey: "isAutoModePreemptInboundEnabled")
        defaults.set(autoModePreemptMaxAttempts, forKey: "autoModePreemptMaxAttempts")
        defaults.set(isAutoModePreemptInstantForMostWanted, forKey: "isAutoModePreemptInstantForMostWanted")
        defaults.set(isOnlyMostWantedFilterEnabled, forKey: "onlyMostWanted")
        defaults.set(maxMostWantedRank, forKey: "maxMostWantedRank")
        defaults.set(isNew4CharGridOnlyFilterEnabled, forKey: "isNew4CharGridOnlyFilterEnabled")
        defaults.set(isNew6CharGridOnlyFilterEnabled, forKey: "isNew6CharGridOnlyFilterEnabled")
        defaults.set(isWorkedBeforeFilterEnabled, forKey: "isWorkedBeforeFilterEnabled")
        defaults.set(workedBeforeDuration, forKey: "workedBeforeDuration")
        defaults.set(workedBeforeUnit.rawValue, forKey: "workedBeforeUnit")
        defaults.set(isDuplicateFilterEnabled, forKey: "isDuplicateFilterEnabled")
        defaults.set(duplicateSpotWindowMinutes, forKey: "duplicateSpotWindowMinutes")
        defaults.set(duplicateSpotFrequencyTolerance, forKey: "duplicateSpotFrequencyTolerance")
        defaults.set(isFilterDebugLoggingEnabled, forKey: "isFilterDebugLoggingEnabled")
        
        defaults.set(activeFilterOrderMode.rawValue, forKey: "filterOrderMode")
        defaults.set(customFilterOrder.map { $0.rawValue }, forKey: "customFilterOrder")
        
        clearEvaluationCache()
        scheduleRecalculations()
        self.isFilterProfileModified = checkIsFilterProfileModified()
    }

    // MARK: - Filter Profile Management
    
    func loadFilterProfiles() {
        let loaded = DatabaseManager.shared.loadFilterProfiles()
        self.filterProfiles = loaded
        
        if let savedId = UserDefaults.standard.string(forKey: "activeFilterProfileId"),
           loaded.contains(where: { $0.id == savedId }) {
            self.activeFilterProfileId = savedId
        } else {
            self.activeFilterProfileId = "system_allround"
        }
        
        self.isFilterProfileModified = checkIsFilterProfileModified()
    }
    
    func applyFilterProfile(id: String) {
        guard let profile = filterProfiles.first(where: { $0.id == id }) else { return }
        applyFilterProfile(profile)
    }
    
    func applyFilterProfile(_ profile: FilterProfile) {
        self.activeFilterProfileId = profile.id
        UserDefaults.standard.set(profile.id, forKey: "activeFilterProfileId")
        
        // Apply Whitelists
        self.allowedDXCallsigns = profile.allowedDXCallsigns
        self.allowedGrids = profile.allowedGrids
        self.allowedCountries = profile.allowedCountries
        self.allowedSpotterCountries = profile.allowedSpotterCountries
        self.allowedSpotterCallsigns = profile.allowedSpotterCallsigns
        
        // Apply Message Filter
        self.isMessageFilterEnabled = profile.isMessageFilterEnabled
        self.messageFilterQuery = profile.messageFilterQuery
        
        // Apply Blacklists
        self.blockedCountries = profile.blockedCountries
        self.disabledContinents = profile.disabledContinents
        self.blockedCQZones = profile.blockedCQZones
        self.blockedITUZones = profile.blockedITUZones
        
        // Apply Special Rules
        self.isOnlyMostWantedFilterEnabled = profile.isOnlyMostWantedFilterEnabled
        self.maxMostWantedRank = profile.maxMostWantedRank
        self.isWorkedBeforeFilterEnabled = profile.isWorkedBeforeFilterEnabled
        self.workedBeforeDuration = profile.workedBeforeDuration
        self.workedBeforeUnit = WorkedBeforeUnit(rawValue: profile.workedBeforeUnit) ?? .months
        self.isNew4CharGridOnlyFilterEnabled = profile.isNew4CharGridOnlyFilterEnabled
        self.isNew6CharGridOnlyFilterEnabled = profile.isNew6CharGridOnlyFilterEnabled
        self.isWsjtSpecialFilterEnabled = profile.isWsjtSpecialFilterEnabled
        self.isDuplicateFilterEnabled = profile.isDuplicateFilterEnabled
        self.duplicateSpotWindowMinutes = profile.duplicateSpotWindowMinutes
        self.duplicateSpotFrequencyTolerance = profile.duplicateSpotFrequencyTolerance
        
        // Apply Pipeline Order
        let parsed = profile.filterOrder.compactMap { DXFilterSectionId(rawValue: $0) }
        var completeOrder = parsed
        for s in DXFilterSectionId.defaultOrder {
            if !completeOrder.contains(s) {
                completeOrder.append(s)
            }
        }
        self.customFilterOrder = completeOrder
        self.activeFilterOrderMode = .custom
        
        self.saveFilters()
        self.isFilterProfileModified = false
        self.clearBlockedDecodes()
    }
    
    func saveCurrentSettingsToActiveProfile() {
        guard let current = activeFilterProfile else { return }
        
        if current.isSystem {
            // Cannot overwrite read-only system profile; create a user copy
            let newName = "\(current.name) (Kopie)"
            saveCurrentSettingsAsNewProfile(name: newName, iconName: current.iconName)
            return
        }
        
        var updated = current
        updated.updatedAt = Date()
        populateProfileFields(into: &updated)
        
        DatabaseManager.shared.saveFilterProfile(updated)
        
        if let idx = filterProfiles.firstIndex(where: { $0.id == updated.id }) {
            filterProfiles[idx] = updated
        }
        self.isFilterProfileModified = false
    }
    
    func saveCurrentSettingsAsNewProfile(name: String, iconName: String = "bookmark.fill", autoBand: String? = nil, autoMode: String? = nil) {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }
        
        var newProfile = FilterProfile(
            id: UUID().uuidString,
            name: cleanName,
            isSystem: false,
            iconName: iconName,
            autoBand: autoBand,
            autoMode: autoMode,
            updatedAt: Date()
        )
        populateProfileFields(into: &newProfile)
        
        DatabaseManager.shared.saveFilterProfile(newProfile)
        self.filterProfiles.append(newProfile)
        self.activeFilterProfileId = newProfile.id
        UserDefaults.standard.set(newProfile.id, forKey: "activeFilterProfileId")
        self.isFilterProfileModified = false
    }
    
    func resetActiveProfileToOriginal() {
        guard let original = activeFilterProfile else { return }
        applyFilterProfile(original)
    }
    
    func deleteFilterProfile(id: String) {
        guard let p = filterProfiles.first(where: { $0.id == id }), !p.isSystem else { return }
        DatabaseManager.shared.deleteFilterProfile(id: id)
        filterProfiles.removeAll(where: { $0.id == id })
        
        if activeFilterProfileId == id {
            applyFilterProfile(id: "system_allround")
        }
    }
    
    private func populateProfileFields(into profile: inout FilterProfile) {
        profile.allowedDXCallsigns = self.allowedDXCallsigns
        profile.allowedGrids = self.allowedGrids
        profile.allowedCountries = self.allowedCountries
        profile.allowedSpotterCountries = self.allowedSpotterCountries
        profile.allowedSpotterCallsigns = self.allowedSpotterCallsigns
        
        profile.isMessageFilterEnabled = self.isMessageFilterEnabled
        profile.messageFilterQuery = self.messageFilterQuery
        
        profile.blockedCountries = self.blockedCountries
        profile.disabledContinents = self.disabledContinents
        profile.blockedCQZones = self.blockedCQZones
        profile.blockedITUZones = self.blockedITUZones
        
        profile.isOnlyMostWantedFilterEnabled = self.isOnlyMostWantedFilterEnabled
        profile.maxMostWantedRank = self.maxMostWantedRank
        profile.isWorkedBeforeFilterEnabled = self.isWorkedBeforeFilterEnabled
        profile.workedBeforeDuration = self.workedBeforeDuration
        profile.workedBeforeUnit = self.workedBeforeUnit.rawValue
        profile.isNew4CharGridOnlyFilterEnabled = self.isNew4CharGridOnlyFilterEnabled
        profile.isNew6CharGridOnlyFilterEnabled = self.isNew6CharGridOnlyFilterEnabled
        profile.isWsjtSpecialFilterEnabled = self.isWsjtSpecialFilterEnabled
        profile.isDuplicateFilterEnabled = self.isDuplicateFilterEnabled
        profile.duplicateSpotWindowMinutes = self.duplicateSpotWindowMinutes
        profile.duplicateSpotFrequencyTolerance = self.duplicateSpotFrequencyTolerance
        profile.filterOrder = self.activeFilterOrder.map { $0.rawValue }
    }
    
    func checkIsFilterProfileModified() -> Bool {
        guard let original = activeFilterProfile else { return false }
        
        if original.allowedDXCallsigns != self.allowedDXCallsigns { return true }
        if original.allowedGrids != self.allowedGrids { return true }
        if original.allowedCountries != self.allowedCountries { return true }
        if original.allowedSpotterCountries != self.allowedSpotterCountries { return true }
        if original.allowedSpotterCallsigns != self.allowedSpotterCallsigns { return true }
        
        if original.isMessageFilterEnabled != self.isMessageFilterEnabled { return true }
        if original.messageFilterQuery != self.messageFilterQuery { return true }
        
        if original.blockedCountries != self.blockedCountries { return true }
        if original.disabledContinents != self.disabledContinents { return true }
        if original.blockedCQZones != self.blockedCQZones { return true }
        if original.blockedITUZones != self.blockedITUZones { return true }
        
        if original.isOnlyMostWantedFilterEnabled != self.isOnlyMostWantedFilterEnabled { return true }
        if original.maxMostWantedRank != self.maxMostWantedRank { return true }
        if original.isWorkedBeforeFilterEnabled != self.isWorkedBeforeFilterEnabled { return true }
        if original.workedBeforeDuration != self.workedBeforeDuration { return true }
        if original.workedBeforeUnit != self.workedBeforeUnit.rawValue { return true }
        if original.isNew4CharGridOnlyFilterEnabled != self.isNew4CharGridOnlyFilterEnabled { return true }
        if original.isNew6CharGridOnlyFilterEnabled != self.isNew6CharGridOnlyFilterEnabled { return true }
        if original.isWsjtSpecialFilterEnabled != self.isWsjtSpecialFilterEnabled { return true }
        if original.isDuplicateFilterEnabled != self.isDuplicateFilterEnabled { return true }
        
        let currentOrderStrs = self.activeFilterOrder.map { $0.rawValue }
        if original.filterOrder != currentOrderStrs { return true }
        
        return false
    }
    
    func checkAutoProfileSwitch(band: String, mode: String) {
        let cleanBand = band.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanMode = mode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard let matching = filterProfiles.first(where: { profile in
            if let b = profile.autoBand?.lowercased(), !b.isEmpty, b == cleanBand {
                return true
            }
            if let m = profile.autoMode?.uppercased(), !m.isEmpty, m == cleanMode {
                return true
            }
            return false
        }) else { return }
        
        if matching.id != activeFilterProfileId {
            print("Auto-Switching filter profile to: \(matching.name) (triggered by Band: \(band), Mode: \(mode))")
            applyFilterProfile(matching)
        }
    }


    private var lastLoggedFilterMessages: [String: Date] = [:]
    
    private func logFilterDecision(_ message: String) {
        let now = Date()
        if let last = lastLoggedFilterMessages[message], now.timeIntervalSince(last) < 2.0 {
            return
        }
        lastLoggedFilterMessages[message] = now
        if lastLoggedFilterMessages.count > 150 {
            lastLoggedFilterMessages = lastLoggedFilterMessages.filter { now.timeIntervalSince($0.value) < 5.0 }
        }
        addLog(message)
    }

    func shouldAccept(decode: WSJTXDecode, recordDuplicates: Bool = false, isTrace: Bool = false) -> Bool {
        guard isFiltersEnabled else { return true }
        
        let call = decode.callsign.uppercased()
        let comment = decode.message
        
        let country = matcher.country(for: call)
        let continent = matcher.continent(for: call)
        let cq = matcher.cqZone(for: call)
        let itu = matcher.ituZone(for: call)
        
        // Logge NUR bei neu eintreffenden Dekodierungen (recordDuplicates: true) oder explizitem Trace, niemals bei UI-Renders
        let shouldLog = isTrace || (isFilterDebugLoggingEnabled && recordDuplicates)
        
        // Spotter Filter (angewendet auf decode.spotter bei Cluster-Spots)
        if decode.isClusterSpot {
            let spotter = decode.spotter
            if isSpotterBlocked(spotter) {
                if shouldLog {
                    logFilterDecision(isDe
                        ? "[Filter ❌ DROP] Spot \(call) verworfen: Spotter \(spotter) gesperrt"
                        : "[Filter ❌ DROP] Spot \(call) dropped: Spotter \(spotter) blocked")
                }
                return false
            }
        }
        
        // First-Match Auswertungs-Pipeline gemäß aktiver Reihenfolge
        for (index, section) in activeFilterOrder.enumerated() {
            let pos = index + 1
            switch section {
            case .allowedCallsigns:
                if !allowedDXCallsigns.isEmpty {
                    if callsignMatches(call, in: allowedDXCallsigns) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ✅ PASS] \(call) (\(country)) passiert via Pos. \(pos) (Erlaubte DX-Rufzeichen)"
                                : "[Filter ✅ PASS] \(call) (\(country)) passed via pos. \(pos) (Allowed DX callsigns)")
                        }
                        return true // Whitelist-Treffer -> Sofort-Pass (Bypass / Ausnahme)
                    }
                }
                
            case .allowedCountries:
                if !allowedCountries.isEmpty {
                    if countryMatches(country, in: allowedCountries) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ✅ PASS] \(call) (\(country)) passiert via Pos. \(pos) (Erlaubte DX-Länder: \(country))"
                                : "[Filter ✅ PASS] \(call) (\(country)) passed via pos. \(pos) (Allowed DX countries: \(country))")
                        }
                        return true // Whitelist-Treffer -> Sofort-Pass (Bypass / Ausnahme)
                    }
                }
                
            case .allowedGrids:
                if !allowedGrids.isEmpty {
                    if let g = decode.grid, gridMatches(g, in: allowedGrids) {
                        let g4 = String(g.prefix(4)).uppercased()
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ✅ PASS] \(call) (Grid \(g4)) passiert via Pos. \(pos) (Erlaubte Grids)"
                                : "[Filter ✅ PASS] \(call) (Grid \(g4)) passed via pos. \(pos) (Allowed grids)")
                        }
                        return true // Whitelist-Treffer -> Sofort-Pass (Bypass / Ausnahme)
                    }
                }
                
            case .messageFilter:
                if isMessageFilterEnabled && !messageFilterQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if !MessageFilterEvaluator.evaluate(message: comment, query: messageFilterQuery) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Nachricht \"\(comment)\" entspricht nicht: \(messageFilterQuery))"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Message \"\(comment)\" does not match: \(messageFilterQuery))")
                        }
                        return false
                    }
                }
                
            case .blockedCountries:
                if isCountryBlocked(country) {
                    if shouldLog {
                        logFilterDecision(isDe
                            ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Gesperrtes Land: \(country))"
                            : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Blocked country: \(country))")
                    }
                    return false
                }
                
            case .continents:
                if !continent.isEmpty && disabledContinents.contains(continent) {
                    if shouldLog {
                        logFilterDecision(isDe
                            ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Gesperrter Kontinent: \(continent))"
                            : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Blocked continent: \(continent))")
                    }
                    return false
                }
                
            case .blockedCQZones:
                if let cqVal = cq, blockedCQZones.contains(cqVal) {
                    if shouldLog {
                        logFilterDecision(isDe
                            ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Gesperrte CQ-Zone: \(cqVal))"
                            : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Blocked CQ zone: \(cqVal))")
                    }
                    return false
                }
                
            case .blockedITUZones:
                if let ituVal = itu, blockedITUZones.contains(ituVal) {
                    if shouldLog {
                        logFilterDecision(isDe
                            ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Gesperrte ITU-Zone: \(ituVal))"
                            : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Blocked ITU zone: \(ituVal))")
                    }
                    return false
                }
                
            case .mostWantedOnly:
                if isOnlyMostWantedFilterEnabled {
                    if !MostWantedManager.shared.isMostWanted(callsign: call, maxRank: maxMostWantedRank) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Nicht in Most-Wanted Top \(maxMostWantedRank))"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Not in Most-Wanted top \(maxMostWantedRank))")
                        }
                        return false
                    }
                }
                
            case .workedBefore:
                if isWorkedBeforeFilterEnabled {
                    if lotwManager.hasWorkedRecently(callsign: call, band: decode.band, duration: workedBeforeDuration, unit: workedBeforeUnit) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Bereits auf \(decode.band) gearbeitet)"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Already worked on \(decode.band))")
                        }
                        return false
                    }
                }
                
            case .gridFilter:
                if isNew4CharGridOnlyFilterEnabled {
                    guard let g = decode.grid, g.count >= 4 else {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Kein 4-Stellen Grid)"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (No 4-char grid)")
                        }
                        return false
                    }
                    let grid4 = String(g.prefix(4)).uppercased()
                    if lotwManager.hasWorkedGrid(grid4) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (4-Stellen Grid \(grid4) bereits gearbeitet)"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (4-char grid \(grid4) already worked)")
                        }
                        return false
                    }
                }
                if isNew6CharGridOnlyFilterEnabled {
                    guard let g = decode.grid, g.count >= 6 else {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Kein 6-Stellen Grid)"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (No 6-char grid)")
                        }
                        return false
                    }
                    let grid6 = String(g.prefix(6)).uppercased()
                    if lotwManager.hasWorkedGrid6(grid6) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (6-Stellen Grid \(grid6) bereits gearbeitet)"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (6-char grid \(grid6) already worked)")
                        }
                        return false
                    }
                }
                
            case .wsjtCQ:
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
                    if !passed {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Kein CQ/73-Signal: \"\(comment)\")"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (No CQ/73 signal: \"\(comment)\")")
                        }
                        return false
                    }
                }
                
            case .duplicates:
                if isDuplicateFilterEnabled {
                    let freqMhz = Double(decode.dialFrequency) / 1_000_000.0 + Double(decode.deltaFrequency) / 1_000_000.0
                    let freqKhz = freqMhz * 1000.0
                    if isDuplicateSpot(id: decode.id, call: call, freq: freqKhz, record: recordDuplicates) {
                        if shouldLog {
                            logFilterDecision(isDe
                                ? "[Filter ❌ DROP] \(call) verworfen via Pos. \(pos) (Doublette auf \(String(format: "%.1f", freqKhz)) kHz)"
                                : "[Filter ❌ DROP] \(call) dropped via pos. \(pos) (Duplicate on \(String(format: "%.1f", freqKhz)) kHz)")
                        }
                        return false
                    }
                }
            }
        }
        
        if shouldLog {
            logFilterDecision(isDe
                ? "[Filter ✅ PASS] \(call) (\(country)) passiert alle Filter"
                : "[Filter ✅ PASS] \(call) (\(country)) passed all filters")
        }
        return true
    }

    // Performance Cache: Memoized evaluation for UI rendering
    private var decodeEvalCache: [UUID: (isInteresting: Bool, isWorked: Bool, shouldAccept: Bool)] = [:]
    private let evalCacheLock = NSLock()
    
    func clearEvaluationCache() {
        evalCacheLock.lock()
        decodeEvalCache.removeAll(keepingCapacity: true)
        evalCacheLock.unlock()
    }

    func evaluateDecodeFast(_ decode: WSJTXDecode) -> (isInteresting: Bool, isWorked: Bool, shouldAccept: Bool) {
        evalCacheLock.lock()
        if let cached = decodeEvalCache[decode.id] {
            evalCacheLock.unlock()
            return cached
        }
        evalCacheLock.unlock()
        
        let accepted = shouldAccept(decode: decode)
        let workedEver = lotwManager.hasWorked(callsign: decode.callsign, band: decode.band)
        let workedBlocked = isWorkedBeforeFilterEnabled ?
            lotwManager.hasWorkedRecently(callsign: decode.callsign, band: decode.band, duration: workedBeforeDuration, unit: workedBeforeUnit) :
            workedEver
        let interesting = isAutoQSOInterestingEvaluated(decode: decode, accepted: accepted, workedBlocked: workedBlocked)
        let result = (isInteresting: interesting, isWorked: workedEver, shouldAccept: accepted)
        
        evalCacheLock.lock()
        if decodeEvalCache.count > 1000 {
            decodeEvalCache.removeAll(keepingCapacity: true)
        }
        decodeEvalCache[decode.id] = result
        evalCacheLock.unlock()
        
        return result
    }

    func isAutoQSOInteresting(decode: WSJTXDecode) -> Bool {
        let eval = evaluateDecodeFast(decode)
        return eval.isInteresting
    }

    private func isAutoQSOInterestingEvaluated(decode: WSJTXDecode, accepted: Bool, workedBlocked: Bool) -> Bool {
        let call = decode.callsign.uppercased()
        guard !call.isEmpty else { return false }
        
        let ownCall = (UserDefaults.standard.string(forKey: "lotwUsername") ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if !ownCall.isEmpty && call == ownCall {
            return false
        }
        
        let isInbound = isAutoModeAnswerCallersEnabled && isInboundCallToMe(decode, ownCall: ownCall)
        
        if !decode.isClusterSpot {
            let upperMsg = decode.message.uppercased()
            let msgTokens = upperMsg.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
            
            let isCQ = upperMsg.contains("CQ ") || upperMsg.hasPrefix("CQ")
            let is73 = msgTokens.contains("73") || msgTokens.contains("RR73") || msgTokens.contains("RRR")
            
            let isEligible = isAutoModeOnlyCQEnabled ? (isCQ || isInbound) : (isCQ || is73 || isInbound)
            guard isEligible else { return false }
        }
        
        // 1. Filtered out by DX Filters
        if !accepted {
            return false
        }
        
        // 2. Only Most Wanted filter active
        if isOnlyMostWantedFilterEnabled {
            if !decode.isMostWanted || (decode.mostWantedRank ?? 999) > maxMostWantedRank {
                return false
            }
        }
        
        // 3. Worked before on this band
        if workedBlocked {
            return false
        }
        
        // 4. In cooldown blacklist (bypassed if station calls us directly)
        if let blacklistedAt = blacklistedCalls[call] {
            if !isInbound {
                let elapsedMinutes = Date().timeIntervalSince(blacklistedAt) / 60.0
                if elapsedMinutes < Double(retryCooldownMinutes) {
                    return false
                }
            }
        }
        
        return true
    }

    func bridgeDecodeIfEnabled(decode: WSJTXDecode, rawData: Data, accepted: Bool) {
        let bridgePort = UserDefaults.standard.integer(forKey: "udpBridgePort")
        guard bridgePort > 0 else { return }
        let bridgeAddress = UserDefaults.standard.string(forKey: "udpBridgeAddress") ?? "127.0.0.1"
        
        if isFiltersEnabled && !accepted {
            return
        }
        
        server.sendRaw(data: rawData, toPort: UInt16(bridgePort), address: bridgeAddress)
    }

    private let usSynonyms = Set(["usa", "united states", "us"])

    private func countryMatches(_ country: String, in filters: [String]) -> Bool {
        let cleanCountry = country.trimmingCharacters(in: .whitespaces).lowercased()
        return filters.contains(where: { filter in
            let cleanFilter = filter.trimmingCharacters(in: .whitespaces).lowercased()
            if cleanFilter.isEmpty { return false }
            if cleanCountry == cleanFilter { return true }
            if cleanCountry.contains(cleanFilter) || cleanFilter.contains(cleanCountry) { return true }
            if cleanFilter == "deutschland" && cleanCountry.contains("germany") { return true }
            if cleanFilter == "russia" || cleanFilter == "russland" {
                if cleanCountry.contains("russia") { return true }
            }
            if usSynonyms.contains(cleanFilter) {
                if cleanCountry.contains("united states") { return true }
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
        let cleanSpotter = spotter.components(separatedBy: "-")[0].trimmingCharacters(in: .whitespaces).uppercased()
        
        // Explizit erlaubte Spotter-Rufzeichen erhalten sofortigen VIP-Pass
        if !allowedSpotterCallsigns.isEmpty && callsignMatches(cleanSpotter, in: allowedSpotterCallsigns) {
            return false
        }
        
        // Falls Spotter-Länder-Whitelist aktiv ist
        if !allowedSpotterCountries.isEmpty {
            let spotterCountry = matcher.country(for: cleanSpotter)
            if !countryMatches(spotterCountry, in: allowedSpotterCountries) {
                return true
            }
        } else if !allowedSpotterCallsigns.isEmpty {
            // Nur Rufzeichen-Whitelist aktiv und Spotter nicht drin
            return true
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

    public static func grid4Coordinates(_ grid: String) -> (col: Int, row: Int)? {
        let clean = grid.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count >= 4 else { return nil }
        let chars = Array(clean)
        guard let f1 = chars[0].asciiValue, f1 >= 65 && f1 <= 82, // A..R
              let f2 = chars[1].asciiValue, f2 >= 65 && f2 <= 82, // A..R
              let s1 = chars[2].wholeNumberValue, s1 >= 0 && s1 <= 9,
              let s2 = chars[3].wholeNumberValue, s2 >= 0 && s2 <= 9 else {
            return nil
        }
        let col = Int(f1 - 65) * 10 + s1
        let row = Int(f2 - 65) * 10 + s2
        return (col, row)
    }

    public func gridMatches(_ grid: String?, in patterns: [String]) -> Bool {
        guard let grid = grid, !grid.isEmpty else { return false }
        guard let targetCoords = DecodeViewModel.grid4Coordinates(grid) else { return false }
        let target4 = String(grid.trimmingCharacters(in: .whitespacesAndNewlines).prefix(4)).uppercased()
        
        for rawPattern in patterns {
            let subPatterns = rawPattern.components(separatedBy: CharacterSet(charactersIn: ",; ")).filter { !$0.isEmpty }
            for pattern in subPatterns {
                let p = pattern.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                if p.contains("-") {
                    let parts = p.components(separatedBy: "-")
                    if parts.count == 2,
                       let c1 = DecodeViewModel.grid4Coordinates(parts[0]),
                       let c2 = DecodeViewModel.grid4Coordinates(parts[1]) {
                        let minCol = min(c1.col, c2.col)
                        let maxCol = max(c1.col, c2.col)
                        let minRow = min(c1.row, c2.row)
                        let maxRow = max(c1.row, c2.row)
                        let inCol = targetCoords.col >= minCol && targetCoords.col <= maxCol
                        let inRow = targetCoords.row >= minRow && targetCoords.row <= maxRow
                        if inCol && inRow {
                            return true
                        }
                    }
                } else if p.count >= 4 {
                    let prefix4 = String(p.prefix(4))
                    if target4 == prefix4 {
                        return true
                    }
                } else if !p.isEmpty && target4.hasPrefix(p) {
                    return true
                }
            }
        }
        return false
    }

    func addAllowedGrid(_ input: String) {
        let items = input.components(separatedBy: CharacterSet(charactersIn: ",; "))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }
        for item in items {
            if !allowedGrids.contains(item) {
                allowedGrids.append(item)
            }
        }
        saveFilters()
        clearBlockedDecodes()
    }

    func removeAllowedGrid(_ item: String) {
        allowedGrids.removeAll { $0 == item }
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
        DispatchQueue.main.async {
            // Updated via @Observable
        }
    }
    
    func updatePropagationClusters() {
        needsRecalculation = true
    }
    
    private func setupRecalculationTimer() {
        recalculationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.pruneOldData()
            
            if self.needsRecalculation && !self.isRecalculating {
                self.needsRecalculation = false
                self.isRecalculating = true
                
                let currentDecodes = self.server.decodes
                let currentSpots = self.clusterSpots
                
                self.recalcQueue.async {
                    self.performRecalculationsBackground(currentDecodes: currentDecodes, currentSpots: currentSpots)
                }
            }
        }
    }
    
    private func pruneOldData() {
        let now = Date()
        let window = UserDefaults.standard.integer(forKey: "mapTimeWindow") == 0 ? 30 : UserDefaults.standard.integer(forKey: "mapTimeWindow")
        let cutoff = now.addingTimeInterval(-Double(window) * 60)
        
        let initialClusterCount = clusterSpots.count
        clusterSpots.removeAll { $0.receivedAt < cutoff }
        
        let initialServerCount = server.decodes.count
        server.decodes.removeAll { $0.receivedAt < cutoff }
        
        let initialDisplayCount = displaySpots.count
        displaySpots.removeAll { $0.receivedAt < cutoff }
        
        // Prune blacklistedCalls older than retry cooldown
        let blacklistCutoff = now.addingTimeInterval(-Double(retryCooldownMinutes * 60))
        blacklistedCalls = blacklistedCalls.filter { $0.value > blacklistCutoff }
        
        // Prune filter log deduplication dictionary
        let logCutoff = now.addingTimeInterval(-10.0)
        lastLoggedFilterMessages = lastLoggedFilterMessages.filter { $0.value > logCutoff }
        
        // Periodic cache trim
        if decodeEvalCache.count > 1000 {
            clearEvaluationCache()
        }
        
        if clusterSpots.count != initialClusterCount || server.decodes.count != initialServerCount || displaySpots.count != initialDisplayCount {
            needsRecalculation = true
        }
    }
    
    private func scheduleRecalculations() {
        needsRecalculation = true
    }
    
    private func performRecalculationsBackground(currentDecodes: [WSJTXDecode], currentSpots: [WSJTXDecode]) {
        self.clearEvaluationCache()
        
        let newPropData = recalculatePropagationClusters(currentDecodes: currentDecodes, currentSpots: currentSpots)
        let newMostWanted = recalculateMostWantedDecodes(currentDecodes: currentDecodes, currentSpots: currentSpots)
        let newGridClusters = recalculateNewGridClusters(currentDecodes: currentDecodes, currentSpots: currentSpots)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.mapState.propagationClusters = newPropData.clusters
            self.mapState.propagationChartData = newPropData.chartItems
            self.mapState.newGridClusters = newGridClusters
            self.mostWantedDecodes = newMostWanted
            self.isRecalculating = false
        }
    }
    
    private func recalculatePropagationClusters(currentDecodes: [WSJTXDecode], currentSpots: [WSJTXDecode]) -> (clusters: [CountryCluster], chartItems: [PropagationChartItem]) {
        
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
        
        let sortedClusters = clusters.sorted { $0.country < $1.country }

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
        return (sortedClusters, chartItems)
    }
    
    private func recalculateMostWantedDecodes(currentDecodes: [WSJTXDecode], currentSpots: [WSJTXDecode]) -> [WSJTXDecode] {
        var seen = Set<String>()
        var result: [WSJTXDecode] = []
        let combined = currentDecodes + currentSpots
        let filtered = combined
            .filter { decode in
                let call = decode.callsign
                guard !call.isEmpty else { return false }
                let isMW = decode.isMostWanted
                let hasWorkedOnBand = isWorkedBeforeFilterEnabled ?
                    lotwManager.hasWorkedRecently(callsign: call, band: decode.band, duration: workedBeforeDuration, unit: workedBeforeUnit) :
                    lotwManager.hasWorked(callsign: call, band: decode.band)
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
        return result.sorted { a, b in
            let rankA = a.mostWantedRank ?? 999
            let rankB = b.mostWantedRank ?? 999
            return rankA < rankB
        }
    }

    private func recalculateNewGridClusters(currentDecodes: [WSJTXDecode], currentSpots: [WSJTXDecode]) -> [NewGridCluster] {
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
        
        return clusters.sorted { $0.grid < $1.grid }
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
        case "EU": return L("continent.EU").uppercased()
        case "NA": return L("continent.NA").uppercased()
        case "AS": return L("continent.AS").uppercased()
        case "SA": return L("continent.SA").uppercased()
        case "AF": return L("continent.AF").uppercased()
        case "OC": return L("continent.OC").uppercased()
        case "AN": return L("continent.AN").uppercased()
        default: return "OTHER"
        }
    }

    func clearTable() {
        DispatchQueue.main.async {
            self.displaySpots.removeAll()
            self.frozenDisplaySpots = nil
            self.server.decodes.removeAll()
            self.clusterSpots.removeAll()
            self.mostWantedDecodes.removeAll()
            self.propagationClusters.removeAll()
            self.newGridClusters.removeAll()
        }
    }

    func sendToCluster(index: Int, text: String) {
        guard !text.isEmpty else { return }
        switch index {
        case 1:
            client1.send(text: text)
            addLog(isDe ? "Gesendet an Cluster 1: \(text)" : "Sent to Cluster 1: \(text)")
        case 2:
            client2.send(text: text)
            addLog(isDe ? "Gesendet an Cluster 2: \(text)" : "Sent to Cluster 2: \(text)")
        case 3:
            client3.send(text: text)
            addLog(isDe ? "Gesendet an Cluster 3: \(text)" : "Sent to Cluster 3: \(text)")
        default:
            break
        }
    }
}

