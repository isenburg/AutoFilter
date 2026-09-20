import SwiftUI
import Charts

struct PropagationChartView: View {
    var viewModel: DecodeViewModel
    var mapState: PropagationMapState
    private var isDe: Bool { LanguageManager.shared.isGerman }
    @State private var isStacked = false
    @State private var isInteracting = false
    @State private var frozenChartData: [PropagationChartItem] = []

    private let allContinents = ["EU", "NA", "AS", "SA", "AF", "OC", "AN", "OTHER"]

    init(viewModel: DecodeViewModel) {
        self.viewModel = viewModel
        self.mapState = viewModel.mapState
    }

    private var chartData: [PropagationChartItem] {
        isInteracting ? frozenChartData : mapState.propagationChartData
    }

    var body: some View {
        let timeWindow = UserDefaults.standard.integer(forKey: "mapTimeWindow") == 0 ? 30 : UserDefaults.standard.integer(forKey: "mapTimeWindow")
        VStack(alignment: .leading, spacing: 10) {
            // Header with View Mode Toggle
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isStacked ? (isDe ? "Ausbreitungsdichte (Gestapelt)" : "Propagation Density (Stacked)") : (isDe ? "Ausbreitung nach Kontinent" : "Propagation by Continent"))
                        .font(.headline)
                    Text(isDe ? "Gefilterte Spots im \(timeWindow) Min. Zeitfenster" : "Filtered spots in \(timeWindow) min time window")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                HStack(spacing: 8) {
                    // View Mode Toggle
                    Button(action: { isStacked.toggle() }) {
                        Image(systemName: isStacked ? "chart.bar.fill" : "chart.bar.xaxis")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isStacked ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .background(Circle().fill(Color.secondary.opacity(0.12)))
                    .help(isStacked ? (isDe ? "Zur gruppierten Ansicht wechseln" : "Switch to grouped view") : (isDe ? "Zur gestapelten Ansicht wechseln" : "Switch to stacked view"))

                    // Refresh Button
                    Button(action: { viewModel.updatePropagationClusters() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .background(Circle().fill(Color.secondary.opacity(0.12)))
                    .help(isDe ? "Aktualisieren" : "Refresh")
                }
            }
            .padding([.horizontal, .top], 12)

            Chart {
                ForEach(chartData) { item in
                    if isStacked {
                        BarMark(
                            x: .value(isDe ? "Kontinent" : "Continent", item.continent),
                            y: .value("Spots", min(item.count, 200))
                        )
                        .foregroundStyle(by: .value("Band", item.band))
                        .clipShape(.rect(cornerRadius: 3))
                    } else {
                        BarMark(
                            x: .value(isDe ? "Kontinent" : "Continent", item.continent),
                            y: .value("Spots", min(item.count, 200)),
                            width: .fixed(12)
                        )
                        .foregroundStyle(by: .value("Band", item.band))
                        .position(by: .value("Band", item.band))
                    }
                }
            }
            .chartXScale(domain: allContinents)
            .chartForegroundStyleScale(mapping: { (band: String) -> Color in
                viewModel.colorForBand(band)
            })
            .chartLegend(position: .bottom, alignment: .center, spacing: 10)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    AxisValueLabel().font(.system(size: 8))
                }
            }
            .chartXAxis {
                AxisMarks(values: allContinents) { _ in
                    AxisValueLabel().font(.system(size: 9, weight: .bold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: isStacked ? 320 : 400, maxHeight: 190)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMoveNotification)) { _ in
            if !isInteracting {
                frozenChartData = viewModel.mapState.propagationChartData
                isInteracting = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didMoveNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInteracting = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willStartLiveResizeNotification)) { _ in
            if !isInteracting {
                frozenChartData = viewModel.mapState.propagationChartData
                isInteracting = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEndLiveResizeNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInteracting = false
            }
        }
    }
}
