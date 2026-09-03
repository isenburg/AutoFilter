import SwiftUI

struct LogbookView: View {
    @Bindable var viewModel: DecodeViewModel
    var langManager = LanguageManager.shared
    
    @State private var selection = Set<QSOEntry.ID>()
    @State private var sortOrder = [KeyPathComparator(\QSOEntry.qsoDate, order: .reverse)]
    @AppStorage("logbook_column_customization") private var columnCustomization: TableColumnCustomization<QSOEntry>
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("settings.sync.qsoCount", viewModel.lotwManager.logbook.count))
                    .font(.headline)
                
                Spacer()
                
                if !selection.isEmpty {
                    Button(role: .destructive) {
                        deleteSelectedQSOs()
                    } label: {
                        Label(L("common.delete"), systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            Table(viewModel.lotwManager.logbook, selection: $selection, sortOrder: $sortOrder, columnCustomization: $columnCustomization) {
                TableColumn(L("table.col.callsign"), value: \.callsign) { qso in
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
                
                TableColumn(L("table.col.band"), value: \.band) { qso in
                    Text(qso.band)
                }
                .width(min: 50, ideal: 70, max: 120)
                .customizationID("band")
                
                TableColumn(L("table.col.mode"), value: \.mode) { qso in
                    Text(qso.mode)
                }
                .width(min: 50, ideal: 80, max: 120)
                .customizationID("mode")
                
                TableColumn("Datum / Date", value: \.qsoDate) { qso in
                    Text(qso.formattedDate)
                }
                .width(min: 80, ideal: 110, max: 160)
                .customizationID("qsoDate")
                
                TableColumn(L("table.col.time"), value: \.timeOn) { qso in
                    Text(qso.formattedTime)
                }
                .width(min: 60, ideal: 90, max: 130)
                .customizationID("timeOn")
                
                TableColumn("DXCC", value: \.dxcc) { qso in
                    Text(qso.dxcc)
                }
                .width(min: 50, ideal: 70, max: 120)
                .customizationID("dxcc")
                
                TableColumn(L("common.delete")) { qso in
                    Button(role: .destructive) {
                        viewModel.lotwManager.deleteQSOs(ids: [qso.id])
                        selection.remove(qso.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help(L("logbook.delete"))
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
                        Label(L("common.delete"), systemImage: "trash")
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
