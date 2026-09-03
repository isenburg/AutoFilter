import SwiftUI

struct LogsConsoleView: View {
    var viewModel: DecodeViewModel
    @Bindable var logs: LogsViewModel
    var isEmbedded: Bool = false

    init(viewModel: DecodeViewModel, isEmbedded: Bool = false) {
        self.viewModel = viewModel
        self.logs = viewModel.logsViewModel
        self.isEmbedded = isEmbedded
    }
    private var langManager = LanguageManager.shared
    private var isDe: Bool { langManager.isGerman }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    
    @AppStorage("logConsoleTab") private var consoleTab = 0
    @AppStorage("isLogConsoleDetached") private var isLogConsoleDetached = false
    @AppStorage("wsjtxShowDecodes") private var wsjtxShowDecodes = true
    @AppStorage("wsjtxShowIncoming") private var wsjtxShowIncoming = true
    @AppStorage("wsjtxShowOutgoing") private var wsjtxShowOutgoing = true
    @AppStorage("isNewestOnTop") private var isNewestOnTop = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("fontSizeLog") private var fontSizeLog = 11.0
    @State private var isClusterSendSheetPresented = false
    
    private var preferredScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("Fehler") || log.contains("⚠️") || log.contains("❌") {
            return .red
        } else if log.contains("🚀") || log.contains("✅") {
            return .green
        } else if log.contains("Auswertung") {
            return .secondary
        } else {
            let hex = UserDefaults.standard.string(forKey: "colorLogSystem") ?? ""
            return hex.isEmpty ? .primary : Color(hex: hex)
        }
    }
    
    private func wsjtxLogColor(for type: WSJTXRawLogType) -> Color {
        switch type {
        case .decode:
            let hex = UserDefaults.standard.string(forKey: "colorLogWsjtxDecode") ?? ""
            return hex.isEmpty ? .green : Color(hex: hex)
        case .incoming:
            let hex = UserDefaults.standard.string(forKey: "colorLogWsjtxIncoming") ?? ""
            return hex.isEmpty ? .blue : Color(hex: hex)
        case .outgoing:
            let hex = UserDefaults.standard.string(forKey: "colorLogWsjtxOutgoing") ?? ""
            return hex.isEmpty ? .orange : Color(hex: hex)
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
                if consoleTab == 0 {
                    Toggle(L("logs.filter.tracing"), isOn: Binding(
                        get: { viewModel.isFilterDebugLoggingEnabled },
                        set: { viewModel.isFilterDebugLoggingEnabled = $0; viewModel.saveFilters() }
                    ))
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .help(L("logs.filter.tracing.help"))
                } else if consoleTab == 1 {
                    HStack(spacing: 8) {
                        Toggle(L("logs.filter.decodes"), isOn: $wsjtxShowDecodes)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                        Toggle(L("logs.filter.in"), isOn: $wsjtxShowIncoming)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                        Toggle(L("logs.filter.out"), isOn: $wsjtxShowOutgoing)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                    }
                } else {
                    Spacer().frame(width: 1)
                }
                
                Spacer()
                
                Picker("", selection: $consoleTab) {
                    Text(L("logs.tab.system")).tag(0)
                    Text(L("logs.tab.wsjtx")).tag(1)
                    Text(L("logs.tab.cluster")).tag(2)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 320)
                
                Spacer()
                
                Button(action: {
                    logs.isLogScrollPaused.toggle()
                }) {
                    Image(systemName: logs.isLogScrollPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(logs.isLogScrollPaused ? .orange : .primary)
                .help(logs.isLogScrollPaused ? L("toolbar.freeze.tooltip.resume") : L("toolbar.freeze.tooltip.pause"))
                
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(L("logs.search"), text: $logs.logConsoleSearchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                    if !logs.logConsoleSearchText.isEmpty {
                        Button(action: { logs.logConsoleSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.textBackgroundColor))
                .clipShape(.rect(cornerRadius: 6))
                
                if consoleTab == 2 {
                    Button(action: {
                        isClusterSendSheetPresented = true
                    }) {
                        Image(systemName: "paperplane")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(L("sidebar.left.sendSpot"))
                }
                
                Button(action: {
                    if consoleTab == 0 {
                        logs.logHistory.removeAll()
                        viewModel.lotwManager.logHistory.removeAll()
                        viewModel.qrzManager.logHistory.removeAll()
                        viewModel.rumlogManager.logHistory.removeAll()
                    } else if consoleTab == 1 {
                        logs.wsjtxRawLogs.removeAll()
                    } else {
                        logs.clusterRawLogs.removeAll()
                    }
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(L("logs.clear"))
                
                if isEmbedded {
                    Button(action: {
                        isLogConsoleDetached = true
                        openWindow(id: "logs_raw")
                    }) {
                        Label(isDe ? "Konsole abdocken" : "Detach Console", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.trailing, 8)
                } else {
                    Button(action: {
                        isLogConsoleDetached = false
                        dismiss()
                    }) {
                        Label(isDe ? "Konsole andocken" : "Attach Console", systemImage: "arrow.down.left.square")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            Group {
                if consoleTab == 0 {
                    LogConsoleTextView(
                        lines: systemLogLines,
                        isPaused: logs.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                } else if consoleTab == 1 {
                    LogConsoleTextView(
                        lines: wsjtxLogLines,
                        isPaused: logs.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                } else {
                    LogConsoleTextView(
                        lines: clusterLogLines,
                        isPaused: logs.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor)))
        }
        .preferredColorScheme(preferredScheme)
        .sheet(isPresented: $isClusterSendSheetPresented) {
            ClusterSendDialog(viewModel: viewModel)
        }
    }

    private var systemLogLines: [LogLine] {
        let rawLogs: [String]
        if logs.isLogScrollPaused, let frozen = logs.frozenSystemLogs {
            rawLogs = frozen
        } else {
            rawLogs = (logs.logHistory + viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory + viewModel.rumlogManager.logHistory).sorted()
        }
        
        let query = logs.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredLogs: [String]
        if query.isEmpty {
            filteredLogs = rawLogs
        } else {
            filteredLogs = rawLogs.filter { $0.lowercased().contains(query) }
        }
        
        let logs = isNewestOnTop ? Array(filteredLogs.reversed()) : filteredLogs
        return logs.map { LogLine(text: $0, color: logColor(for: $0)) }
    }
    
    private var wsjtxLogLines: [LogLine] {
        let rawWSJTXLogs: [WSJTXRawLogEntry]
        if logs.isLogScrollPaused, let frozen = logs.frozenWSJTXLogs {
            rawWSJTXLogs = frozen
        } else {
            rawWSJTXLogs = logs.wsjtxRawLogs
        }
        
        let activeTypeLogs = rawWSJTXLogs.filter { log in
            switch log.type {
            case .decode: return wsjtxShowDecodes
            case .incoming: return wsjtxShowIncoming
            case .outgoing: return wsjtxShowOutgoing
            }
        }
        
        let query = logs.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredLogs: [WSJTXRawLogEntry]
        if query.isEmpty {
            filteredLogs = activeTypeLogs
        } else {
            filteredLogs = activeTypeLogs.filter { $0.message.lowercased().contains(query) }
        }
        
        let logs = isNewestOnTop ? Array(filteredLogs.reversed()) : filteredLogs
        return logs.map { log in
            let ts = formatLogTime(log.timestamp)
            return LogLine(text: "[\(ts)] [\(log.type.rawValue)] \(log.message)", color: wsjtxLogColor(for: log.type))
        }
    }
    
    private var clusterLogLines: [LogLine] {
        let rawClusterLogs: [ClusterRawLogEntry]
        if logs.isLogScrollPaused, let frozen = logs.frozenClusterLogs {
            rawClusterLogs = frozen
        } else {
            rawClusterLogs = logs.clusterRawLogs
        }
        
        let query = logs.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filteredLogs: [ClusterRawLogEntry]
        if query.isEmpty {
            filteredLogs = rawClusterLogs
        } else {
            filteredLogs = rawClusterLogs.filter { $0.message.lowercased().contains(query) }
        }
        
        let logs = isNewestOnTop ? Array(filteredLogs.reversed()) : filteredLogs
        let clusterColor = Color(hex: UserDefaults.standard.string(forKey: "colorLogCluster") ?? "", defaultColor: .primary)
        return logs.map { LogLine(text: $0.message, color: clusterColor) }
    }

    private func scrollToActive<T: Hashable>(proxy: ScrollViewProxy, count: Int, first: T?, last: T?) {
        guard count > 0 else { return }
        DispatchQueue.main.async {
            if self.isNewestOnTop {
                if let first = first {
                    proxy.scrollTo(first, anchor: .top)
                }
            } else {
                if let last = last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }
}
