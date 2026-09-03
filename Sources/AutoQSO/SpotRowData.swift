import Foundation
import SwiftUI

enum SpotRowStatus: String, Equatable {
    case mostWanted
    case interestingCQ
    case worked
    case normal
    case filteredOut
}

struct SpotRowData: Identifiable, Equatable {
    let id: UUID
    let timeString: String
    let callsign: String
    let message: String
    let snrString: String
    let dtString: String
    let country: String
    let spotter: String
    let mostWantedRank: Int?
    let isMostWanted: Bool
    let distanceKm: Double?
    let distanceText: String
    let grid: String?
    let band: String
    let formattedHfFrequency: String
    let deltaFrequency: UInt32
    let isAccepted: Bool
    let status: SpotRowStatus
    let receivedAt: Date
    let rawDecode: WSJTXDecode

    static func from(
        decode: WSJTXDecode,
        myGrid: String,
        isAccepted: Bool,
        isWorked: Bool,
        isInteresting: Bool,
        highlightMostWanted: Bool
    ) -> SpotRowData {
        let seconds = decode.time / 1000
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        let timeStr = String(format: "%02d:%02d:%02d", h, m, s)
        
        let dist = decode.distanceKm(myGrid: myGrid)
        let distStr = dist != nil ? String(format: "%.0f km", dist!) : "-"
        
        let mwRank = decode.mostWantedRank
        let isMW = mwRank != nil
        
        let status: SpotRowStatus
        if isMW && highlightMostWanted {
            status = .mostWanted
        } else if isInteresting {
            status = .interestingCQ
        } else if isWorked {
            status = .worked
        } else if !isAccepted {
            status = .filteredOut
        } else {
            status = .normal
        }
        
        return SpotRowData(
            id: decode.id,
            timeString: timeStr,
            callsign: decode.callsign,
            message: decode.message,
            snrString: "\(decode.snr)",
            dtString: String(format: "%.1f", decode.deltaTime),
            country: decode.country.isEmpty ? "Unbekannt" : decode.country,
            spotter: decode.spotter,
            mostWantedRank: mwRank,
            isMostWanted: isMW,
            distanceKm: dist,
            distanceText: distStr,
            grid: decode.grid,
            band: decode.band,
            formattedHfFrequency: decode.formattedHfFrequency,
            deltaFrequency: decode.deltaFrequency,
            isAccepted: isAccepted,
            status: status,
            receivedAt: decode.receivedAt,
            rawDecode: decode
        )
    }
}
