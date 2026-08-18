import SwiftUI
import MapKit

enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case satellite = "Satellit"
    case hybrid = "Hybrid"
    case muted = "Muted"
    case globus = "Globus"

    var id: String { rawValue }

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
