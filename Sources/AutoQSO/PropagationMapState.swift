import Observation
import Foundation
import Combine
import SwiftUI

@Observable
class PropagationMapState {
    var propagationClusters: [CountryCluster] = []
    var propagationChartData: [PropagationChartItem] = []
    var newGridClusters: [NewGridCluster] = []
    var totalReceived: Int = 0
    var totalForwarded: Int = 0
    
    init() {}
}
