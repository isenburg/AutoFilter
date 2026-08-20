import SwiftUI

struct LogsConsoleView: View {
    @ObservedObject var viewModel: DecodeViewModel
    @ObservedObject private var langManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    
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
        if log.contains("Fehler") || log.contains("⚠️") {
            return .red
        } else if log.contains("🚀") {
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
                if consoleTab == 1 {
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
                    viewModel.isLogScrollPaused.toggle()
                }) {
                    Image(systemName: viewModel.isLogScrollPaused ? "play.circle" : "pause.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(viewModel.isLogScrollPaused ? .orange : .primary)
                .help(viewModel.isLogScrollPaused ? L("toolbar.freeze.tooltip.resume") : L("toolbar.freeze.tooltip.pause"))
                
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(L("logs.search"), text: $viewModel.logConsoleSearchText)
                        .font(.system(size: 11))
                        .textFieldStyle(.plain)
                        .frame(width: 150)
                    if !viewModel.logConsoleSearchText.isEmpty {
                        Button(action: { viewModel.logConsoleSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                
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
                        viewModel.logHistory.removeAll()
                        viewModel.lotwManager.logHistory.removeAll()
                        viewModel.qrzManager.logHistory.removeAll()
                        viewModel.rumlogManager.logHistory.removeAll()
                    } else if consoleTab == 1 {
                        viewModel.wsjtxRawLogs.removeAll()
                    } else {
                        viewModel.clusterRawLogs.removeAll()
                    }
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(L("logs.clear"))
                
                Button(L("logs.attach")) {
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
            
            Group {
                if consoleTab == 0 {
                    LogConsoleTextView(
                        lines: systemLogLines,
                        isPaused: viewModel.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                } else if consoleTab == 1 {
                    LogConsoleTextView(
                        lines: wsjtxLogLines,
                        isPaused: viewModel.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                } else {
                    LogConsoleTextView(
                        lines: clusterLogLines,
                        isPaused: viewModel.isLogScrollPaused,
                        fontSize: fontSizeLog,
                        isNewestOnTop: isNewestOnTop,
                        backgroundColor: Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: UserDefaults.standard.string(forKey: "colorLogBackground") ?? "", defaultColor: Color(NSColor.textBackgroundColor)))
        }
        .frame(minWidth: 500, minHeight: 300)
        .preferredColorScheme(preferredScheme)
        .sheet(isPresented: $isClusterSendSheetPresented) {
            ClusterSendDialog(viewModel: viewModel)
        }
        .onDisappear {
            // When window is closed, mark it as docked back
            isLogConsoleDetached = false
        }
    }

    private var systemLogLines: [LogLine] {
        let rawLogs: [String]
        if viewModel.isLogScrollPaused, let frozen = viewModel.frozenSystemLogs {
            rawLogs = frozen
        } else {
            rawLogs = (viewModel.logHistory + viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory + viewModel.rumlogManager.logHistory).sorted()
        }
        
        let query = viewModel.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
        if viewModel.isLogScrollPaused, let frozen = viewModel.frozenWSJTXLogs {
            rawWSJTXLogs = frozen
        } else {
            rawWSJTXLogs = viewModel.wsjtxRawLogs
        }
        
        let activeTypeLogs = rawWSJTXLogs.filter { log in
            switch log.type {
            case .decode: return wsjtxShowDecodes
            case .incoming: return wsjtxShowIncoming
            case .outgoing: return wsjtxShowOutgoing
            }
        }
        
        let query = viewModel.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
        if viewModel.isLogScrollPaused, let frozen = viewModel.frozenClusterLogs {
            rawClusterLogs = frozen
        } else {
            rawClusterLogs = viewModel.clusterRawLogs
        }
        
        let query = viewModel.logConsoleSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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
