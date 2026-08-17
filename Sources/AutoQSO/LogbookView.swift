import SwiftUI

struct LogbookView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @State private var selection = Set<QSOEntry.ID>()
    @State private var sortOrder = [KeyPathComparator(\QSOEntry.qsoDate, order: .reverse)]
    @AppStorage("logbook_column_customization") private var columnCustomization: TableColumnCustomization<QSOEntry>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Logbuch (\(viewModel.lotwManager.logbook.count) Einträge)")
                    .font(.headline)
                
                Spacer()
                
                if !selection.isEmpty {
                    Button(role: .destructive) {
                        deleteSelectedQSOs()
                    } label: {
                        Label("\(selection.count) Ausgewählte löschen", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            Table(viewModel.lotwManager.logbook, selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
                TableColumn("Rufzeichen", value: \.callsign) { qso in
                    Text(qso.callsign).textSelection(.enabled)
                }
                .width(min: 80, ideal: 120, max: 200)
                .customizationID("callsign")
                
                TableColumn("Grid", value: \.grid) { qso in
                    Text(qso.grid)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 60, ideal: 80, max: 120)
                .customizationID("grid")
                
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
                
                TableColumn("Löschen") { qso in
                    Button(role: .destructive) {
                        viewModel.lotwManager.deleteQSOs(ids: [qso.id])
                        selection.remove(qso.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Diesen Eintrag löschen")
                }
                .width(50)
                .customizationID("deleteAction")
            }
            .contextMenu(forSelectionType: QSOEntry.ID.self) { selectedIds in
                if !selectedIds.isEmpty {
                    Button(role: .destructive) {
                        viewModel.lotwManager.deleteQSOs(ids: selectedIds)
                        selection.subtract(selectedIds)
                    } label: {
                        Label("\(selectedIds.count) Eintrag/Einträge löschen", systemImage: "trash")
                    }
                }
            }
            .onDeleteCommand {
                deleteSelectedQSOs()
            }
            .onChange(of: sortOrder) { _, newOrder in
                viewModel.lotwManager.logbook.sort(using: newOrder)
            }
            .onAppear {
                viewModel.lotwManager.logbook.sort(using: sortOrder)
            }
        }
        .frame(minWidth: 700, minHeight: 480)
    }
    
    private func deleteSelectedQSOs() {
        guard !selection.isEmpty else { return }
        viewModel.lotwManager.deleteQSOs(ids: selection)
        selection.removeAll()
    }
}
