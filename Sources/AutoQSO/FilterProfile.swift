import Foundation

/// A complete, serializable snapshot of all AutoQSO filter settings and pipeline ordering.
public struct FilterProfile: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var isSystem: Bool
    public var iconName: String
    public var autoBand: String?  // e.g. "6m", "20m", or nil
    public var autoMode: String?  // e.g. "FT8", "SSB", or nil
    public var updatedAt: Date

    // Whitelists
    public var allowedDXCallsigns: [String]
    public var allowedGrids: [String]
    public var allowedCountries: [String]
    public var allowedSpotterCountries: [String]
    public var allowedSpotterCallsigns: [String]

    // Message Content Filter
    public var isMessageFilterEnabled: Bool
    public var messageFilterQuery: String

    // Blacklists
    public var blockedCountries: [String]
    public var disabledContinents: [String]
    public var blockedCQZones: [Int]
    public var blockedITUZones: [Int]

    // Special Rules
    public var isOnlyMostWantedFilterEnabled: Bool
    public var maxMostWantedRank: Int

    public var isWorkedBeforeFilterEnabled: Bool
    public var workedBeforeDuration: Int
    public var workedBeforeUnit: String

    public var isNew4CharGridOnlyFilterEnabled: Bool
    public var isNew6CharGridOnlyFilterEnabled: Bool

    public var isWsjtSpecialFilterEnabled: Bool

    public var isDuplicateFilterEnabled: Bool
    public var duplicateSpotWindowMinutes: Int
    public var duplicateSpotFrequencyTolerance: Double

    // Reordered Pipeline Sequence
    public var filterOrder: [String]

    public init(
        id: String = UUID().uuidString,
        name: String,
        isSystem: Bool = false,
        iconName: String = "line.3.horizontal.decrease.circle",
        autoBand: String? = nil,
        autoMode: String? = nil,
        updatedAt: Date = Date(),
        allowedDXCallsigns: [String] = [],
        allowedGrids: [String] = [],
        allowedCountries: [String] = [],
        allowedSpotterCountries: [String] = [],
        allowedSpotterCallsigns: [String] = [],
        isMessageFilterEnabled: Bool = false,
        messageFilterQuery: String = "",
        blockedCountries: [String] = [],
        disabledContinents: [String] = [],
        blockedCQZones: [Int] = [],
        blockedITUZones: [Int] = [],
        isOnlyMostWantedFilterEnabled: Bool = false,
        maxMostWantedRank: Int = 100,
        isWorkedBeforeFilterEnabled: Bool = false,
        workedBeforeDuration: Int = 1,
        workedBeforeUnit: String = "months",
        isNew4CharGridOnlyFilterEnabled: Bool = false,
        isNew6CharGridOnlyFilterEnabled: Bool = false,
        isWsjtSpecialFilterEnabled: Bool = false,
        isDuplicateFilterEnabled: Bool = true,
        duplicateSpotWindowMinutes: Int = 1,
        duplicateSpotFrequencyTolerance: Double = 0.5,
        filterOrder: [String] = DXFilterSectionId.defaultOrder.map { $0.rawValue }
    ) {
        self.id = id
        self.name = name
        self.isSystem = isSystem
        self.iconName = iconName
        self.autoBand = autoBand
        self.autoMode = autoMode
        self.updatedAt = updatedAt
        self.allowedDXCallsigns = allowedDXCallsigns
        self.allowedGrids = allowedGrids
        self.allowedCountries = allowedCountries
        self.allowedSpotterCountries = allowedSpotterCountries
        self.allowedSpotterCallsigns = allowedSpotterCallsigns
        self.isMessageFilterEnabled = isMessageFilterEnabled
        self.messageFilterQuery = messageFilterQuery
        self.blockedCountries = blockedCountries
        self.disabledContinents = disabledContinents
        self.blockedCQZones = blockedCQZones
        self.blockedITUZones = blockedITUZones
        self.isOnlyMostWantedFilterEnabled = isOnlyMostWantedFilterEnabled
        self.maxMostWantedRank = maxMostWantedRank
        self.isWorkedBeforeFilterEnabled = isWorkedBeforeFilterEnabled
        self.workedBeforeDuration = workedBeforeDuration
        self.workedBeforeUnit = workedBeforeUnit
        self.isNew4CharGridOnlyFilterEnabled = isNew4CharGridOnlyFilterEnabled
        self.isNew6CharGridOnlyFilterEnabled = isNew6CharGridOnlyFilterEnabled
        self.isWsjtSpecialFilterEnabled = isWsjtSpecialFilterEnabled
        self.isDuplicateFilterEnabled = isDuplicateFilterEnabled
        self.duplicateSpotWindowMinutes = duplicateSpotWindowMinutes
        self.duplicateSpotFrequencyTolerance = duplicateSpotFrequencyTolerance
        self.filterOrder = filterOrder
    }
}

// MARK: - Built-in System Templates
extension FilterProfile {
    public static let systemTemplates: [FilterProfile] = [
        // 1. Allround (Standard)
        FilterProfile(
            id: "system_allround",
            name: "Allround (Standard)",
            isSystem: true,
            iconName: "globe.europe.africa.fill",
            isDuplicateFilterEnabled: true,
            duplicateSpotWindowMinutes: 1,
            duplicateSpotFrequencyTolerance: 0.5,
            filterOrder: DXFilterSectionId.defaultOrder.map { $0.rawValue }
        ),
        
        // 2. DXpedition & Seltene DXCC
        FilterProfile(
            id: "system_dxpedition",
            name: "DXpedition & Seltene DXCC",
            isSystem: true,
            iconName: "bolt.fill",
            isMessageFilterEnabled: true,
            messageFilterQuery: "\"split\" OR \"up\"",
            isOnlyMostWantedFilterEnabled: true,
            maxMostWantedRank: 50,
            isWorkedBeforeFilterEnabled: false,
            isDuplicateFilterEnabled: true,
            duplicateSpotWindowMinutes: 2,
            filterOrder: [
                DXFilterSectionId.mostWantedOnly.rawValue,
                DXFilterSectionId.messageFilter.rawValue,
                DXFilterSectionId.allowedGrids.rawValue,
                DXFilterSectionId.allowedCallsigns.rawValue,
                DXFilterSectionId.allowedCountries.rawValue,
                DXFilterSectionId.continents.rawValue,
                DXFilterSectionId.blockedCountries.rawValue,
                DXFilterSectionId.blockedCQZones.rawValue,
                DXFilterSectionId.blockedITUZones.rawValue,
                DXFilterSectionId.workedBefore.rawValue,
                DXFilterSectionId.gridFilter.rawValue,
                DXFilterSectionId.wsjtCQ.rawValue,
                DXFilterSectionId.duplicates.rawValue
            ]
        ),
        
        // 3. Contest / High-Rate
        FilterProfile(
            id: "system_contest",
            name: "Contest / High-Rate",
            isSystem: true,
            iconName: "trophy.fill",
            isMessageFilterEnabled: false,
            isOnlyMostWantedFilterEnabled: false,
            isWorkedBeforeFilterEnabled: false,
            isDuplicateFilterEnabled: true,
            duplicateSpotWindowMinutes: 1,
            duplicateSpotFrequencyTolerance: 0.5,
            filterOrder: DXFilterSectionId.defaultOrder.map { $0.rawValue }
        ),
        
        // 4. Grid Hunting (WAS / Neuland)
        FilterProfile(
            id: "system_grid_hunting",
            name: "Grid Hunting (WAS / Neuland)",
            isSystem: true,
            iconName: "map.fill",
            isWorkedBeforeFilterEnabled: true,
            workedBeforeDuration: 12,
            workedBeforeUnit: "months",
            isNew4CharGridOnlyFilterEnabled: true,
            isDuplicateFilterEnabled: true,
            filterOrder: [
                DXFilterSectionId.gridFilter.rawValue,
                DXFilterSectionId.allowedGrids.rawValue,
                DXFilterSectionId.allowedCallsigns.rawValue,
                DXFilterSectionId.allowedCountries.rawValue,
                DXFilterSectionId.messageFilter.rawValue,
                DXFilterSectionId.continents.rawValue,
                DXFilterSectionId.blockedCountries.rawValue,
                DXFilterSectionId.blockedCQZones.rawValue,
                DXFilterSectionId.blockedITUZones.rawValue,
                DXFilterSectionId.mostWantedOnly.rawValue,
                DXFilterSectionId.workedBefore.rawValue,
                DXFilterSectionId.wsjtCQ.rawValue,
                DXFilterSectionId.duplicates.rawValue
            ]
        ),
        
        // 5. Phone / SSB Only
        FilterProfile(
            id: "system_phone_ssb",
            name: "Phone / SSB Only",
            isSystem: true,
            iconName: "mic.fill",
            isMessageFilterEnabled: true,
            messageFilterQuery: "\"SSB\" OR \"USB\" OR \"LSB\" OR \"phone\"",
            isDuplicateFilterEnabled: true,
            filterOrder: [
                DXFilterSectionId.messageFilter.rawValue,
                DXFilterSectionId.allowedGrids.rawValue,
                DXFilterSectionId.allowedCallsigns.rawValue,
                DXFilterSectionId.allowedCountries.rawValue,
                DXFilterSectionId.continents.rawValue,
                DXFilterSectionId.blockedCountries.rawValue,
                DXFilterSectionId.blockedCQZones.rawValue,
                DXFilterSectionId.blockedITUZones.rawValue,
                DXFilterSectionId.mostWantedOnly.rawValue,
                DXFilterSectionId.workedBefore.rawValue,
                DXFilterSectionId.gridFilter.rawValue,
                DXFilterSectionId.wsjtCQ.rawValue,
                DXFilterSectionId.duplicates.rawValue
            ]
        )
    ]
}
