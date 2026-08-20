import SwiftUI
import MapKit

enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case satellite = "Satellit"
    case hybrid = "Hybrid"
    case muted = "Muted"
    case globus = "Globus"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return L("map.style.standard")
        case .satellite: return L("map.style.satellite")
        case .hybrid: return L("map.style.hybrid")
        case .muted: return "Muted"
        case .globus: return L("map.style.globe")
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .flat)
        case .satellite:
            return .imagery(elevation: .flat)
        case .hybrid:
            return .hybrid(elevation: .flat)
        case .muted:
            return .standard(elevation: .flat, emphasis: .muted)
        case .globus:
            return .hybrid(elevation: .realistic)
        }
    }
}
