import SwiftUI

struct LogbookView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @State private var sortOrder = [KeyPathComparator(\QSOEntry.qsoDate, order: .reverse)]
    @AppStorage("logbook_column_customization") private var columnCustomization: TableColumnCustomization<QSOEntry>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LoTW Logbuch (\(viewModel.lotwManager.logbook.count) Einträge)")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            Table(viewModel.lotwManager.logbook, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
                TableColumn("Rufzeichen", value: \.callsign) { qso in
                    Text(qso.callsign).textSelection(.enabled)
                }
                .width(min: 80, ideal: 120, max: 200)
                .customizationID("callsign")
                
                TableColumn("Band", value: \.band) { qso in
                    Text(qso.band)
                }
                .width(min: 50, ideal: 70, max: 120)
                .customizationID("band")
                
                TableColumn("Mode", value: \.mode) { qso in
                    Text(qso.mode)
                }
                .width(min: 50, ideal: 80, max: 120)
                .customizationID("mode")
                
                TableColumn("Datum", value: \.qsoDate) { qso in
                    Text(qso.formattedDate)
                }
                .width(min: 80, ideal: 110, max: 160)
                .customizationID("qsoDate")
                
                TableColumn("Zeit", value: \.timeOn) { qso in
                    Text(qso.formattedTime)
                }
                .width(min: 60, ideal: 90, max: 130)
                .customizationID("timeOn")
                
                TableColumn("DXCC", value: \.dxcc) { qso in
                    Text(qso.dxcc)
                }
                .width(min: 50, ideal: 70, max: 120)
                .customizationID("dxcc")
            }
            .onChange(of: sortOrder) { _, newOrder in
                viewModel.lotwManager.logbook.sort(using: newOrder)
            }
            .onAppear {
                viewModel.lotwManager.logbook.sort(using: sortOrder)
            }
        }
        .frame(minWidth: 650, minHeight: 450)
    }
}
