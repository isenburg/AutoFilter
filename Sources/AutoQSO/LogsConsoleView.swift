import SwiftUI

struct LogsConsoleView: View {
    @ObservedObject var viewModel: DecodeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("logConsoleTab") private var consoleTab = 0
    @AppStorage("isLogConsoleDetached") private var isLogConsoleDetached = false
    @AppStorage("wsjtxShowDecodes") private var wsjtxShowDecodes = true
    @AppStorage("wsjtxShowIncoming") private var wsjtxShowIncoming = true
    @AppStorage("wsjtxShowOutgoing") private var wsjtxShowOutgoing = true
    @AppStorage("isNewestOnTop") private var isNewestOnTop = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    
    private var preferredScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("Fehler") || log.contains("⚠️") {
            return .red
        } else if log.contains("🚀") {
            return .green
        } else if log.contains("Auswertung") {
            return .secondary
        } else {
            return .primary
        }
    }
    
    private func wsjtxLogColor(for type: WSJTXRawLogType) -> Color {
        switch type {
        case .decode:
            return .green
        case .incoming:
            return .blue
        case .outgoing:
            return .orange
        }
    }
    
    private func formatLogTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("", selection: $consoleTab) {
                    Text("System-Logs").tag(0)
                    Text("WSJT-X Rohdaten").tag(1)
                    Text("Cluster-Spots").tag(2)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 320)
                
                if consoleTab == 1 {
                    Toggle("Decodes", isOn: $wsjtxShowDecodes)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                    Toggle("Eingang", isOn: $wsjtxShowIncoming)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                    Toggle("Ausgang", isOn: $wsjtxShowOutgoing)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                }
                
                Spacer()
                
                // Dock back button
                Button("Andocken") {
                    isLogConsoleDetached = false
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if consoleTab == 0 {
                        let rawLogs = (viewModel.logHistory + viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory).sorted()
                        let logs = isNewestOnTop ? Array(rawLogs.reversed()) : rawLogs
                        if logs.isEmpty {
                            Text("Keine System-Logs vorhanden.")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 11))
                        } else {
                            ForEach(logs, id: \.self) { log in
                                Text(log)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(logColor(for: log))
                            }
                        }
                    } else if consoleTab == 1 {
                        let rawWSJTXLogs = viewModel.wsjtxRawLogs.filter { log in
                            switch log.type {
                            case .decode: return wsjtxShowDecodes
                            case .incoming: return wsjtxShowIncoming
                            case .outgoing: return wsjtxShowOutgoing
                            }
                        }
                        let filteredWSJTXLogs = isNewestOnTop ? Array(rawWSJTXLogs.reversed()) : rawWSJTXLogs
                        if filteredWSJTXLogs.isEmpty {
                            Text("Keine WSJT-X Rohdaten für die gewählten Filter.")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 11))
                        } else {
                            ForEach(filteredWSJTXLogs) { log in
                                let ts = formatLogTime(log.timestamp)
                                Text("[\(ts)] [\(log.type.rawValue)] \(log.message)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(wsjtxLogColor(for: log.type))
                            }
                        }
                    } else {
                        let clusterLogs = isNewestOnTop ? Array(viewModel.clusterRawLogs.reversed()) : viewModel.clusterRawLogs
                        if clusterLogs.isEmpty {
                            Text("Keine DX-Cluster Rohdaten vorhanden.")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.system(size: 11))
                        } else {
                            ForEach(clusterLogs) { log in
                                Text(log.message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 300)
        .preferredColorScheme(preferredScheme)
        .onDisappear {
            // When window is closed, mark it as docked back
            isLogConsoleDetached = false
        }
    }
}
