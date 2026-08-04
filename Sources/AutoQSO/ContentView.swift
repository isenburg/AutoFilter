import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    @AppStorage("mostWantedPanelHeight") private var mostWantedPanelHeight: Double = 120.0
    @AppStorage("decode_column_customization") private var decodeColumnCustomization: TableColumnCustomization<WSJTXDecode>
    
    @State private var tableSelection: WSJTXDecode.ID? = nil
    
    @Environment(\.openWindow) private var openWindow
    
    private var isMulticastAddress: Bool {
        if let firstOctetStr = udpAddress.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".").first,
           let firstOctet = Int(firstOctetStr) {
            return firstOctet >= 224 && firstOctet <= 239
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar (Clean & Spacious)
            HStack(alignment: .center, spacing: 14) {
                // Auto Mode Section
                VStack(alignment: .leading, spacing: 3) {
                    Text("AUTO MODE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Button(action: {
                            viewModel.isAutoModeEnabled.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.isAutoModeEnabled ? "play.circle.fill" : "play.circle")
                                Text(viewModel.isAutoModeEnabled ? "AUTO AKTIV" : "AUTO AUS")
                                    .fontWeight(.bold)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.isAutoModeEnabled ? .green : .gray)
                        
                        TextField("10", value: $retryCooldownMinutes, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 45)
                        Text("Min. Sperre")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                    .frame(height: 36)
                
                // Synchronisation Actions
                VStack(alignment: .leading, spacing: 3) {
                    Text("SYNCHRONISATION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Button(action: {
                            viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword)
                        }) {
                            Label("LoTW Sync", systemImage: "arrow.clockwise")
                        }
                        .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            viewModel.syncQRZ(apiKey: qrzApiKey)
                        }) {
                            Label("QRZ Sync", systemImage: "arrow.clockwise")
                        }
                        .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                        .buttonStyle(.bordered)
                    }
                }
                
                Divider()
                    .frame(height: 36)
                
                // Logbook Section
                VStack(alignment: .leading, spacing: 3) {
                    Text("LOGBUCH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    Button("Öffnen ↗") {
                        openWindow(id: "logbook")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                // Settings & Info Buttons
                VStack(alignment: .trailing, spacing: 3) {
                    Text("FENSTER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Button(action: {
                            openWindow(id: "settings")
                        }) {
                            Label("Einstellungen", systemImage: "gearshape")
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            openWindow(id: "help")
                        }) {
                            Label("Info", systemImage: "questionmark.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Dedicated Station Evaluation Banner Line
            if !viewModel.displayCallsign.isEmpty {
                let displayCall = viewModel.displayCallsign
                let workedBands = Set(viewModel.lotwManager.workedBands(for: displayCall))
                let allBands = ["160M", "80M", "60M", "40M", "30M", "20M", "17M", "15M", "12M", "10M", "6M"]
                let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                
                // Find matching decode to get grid locator and calculate distance
                let matchingDecode = viewModel.server.decodes.first(where: { $0.callsign.uppercased() == displayCall.uppercased() })
                let grid = matchingDecode?.grid
                let distanceKm = matchingDecode?.distanceKm(myGrid: myGrid)
                let mwRank = MostWantedManager.shared.rankForCallsign(displayCall)
                
                HStack(spacing: 14) {
                    HStack(spacing: 8) {
                        Text(displayCall)
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(mwRank != nil ? .red : .orange)
                        
                        if let rank = mwRank {
                            Text("🔥 #\(rank)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Button(action: {
                            openQRZ(callsign: displayCall)
                        }) {
                            Label("QRZ.com", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Distance & Grid Badge
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        if let dist = distanceKm {
                            Text(String(format: "%.0f km", dist))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                            if let g = grid {
                                Text("(\(g))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else if let g = grid {
                            Text("Grid: \(g)")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Entfernung: -")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                    
                    Divider()
                        .frame(height: 20)
                    
                    Text("LoTW / QRZ Bänder:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(allBands, id: \.self) { band in
                                let isWorked = workedBands.contains(band)
                                Text(band)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(isWorked ? Color.green : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(isWorked ? .white : .secondary)
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(isWorked ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                Divider()
            }
            
            // Log History Terminal (LoTW + QRZ + Engine)
            let logs = (viewModel.logHistory + viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory).sorted()
            if !logs.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(logs, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(
                                    log.contains("Fehler") || log.contains("⚠️") ? .red :
                                    log.contains("🚀") ? .green :
                                    log.contains("Auswertung") ? .secondary : .primary
                                )
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 80)
                .background(Color(NSColor.textBackgroundColor))
                Divider()
            }
            
            // Decodes Table
            Table(viewModel.server.decodes, selection: $tableSelection, columnCustomization: $decodeColumnCustomization) {
                TableColumn("Zeit") { decode in
                    cellText(formatTime(decode.time), decode: decode)
                }
                .width(min: 65, ideal: 75, max: 100)
                .customizationID("time")
                
                TableColumn("DX Call") { decode in
                    HStack(spacing: 4) {
                        cellText(decode.callsign, decode: decode)
                        if MostWantedManager.shared.isMostWanted(callsign: decode.callsign) {
                            Text("🔥")
                                .font(.caption2)
                        }
                    }
                }
                .width(min: 80, ideal: 105, max: 180)
                .customizationID("callsign")
                
                TableColumn("Most Wanted") { decode in
                    if let rank = MostWantedManager.shared.rankForCallsign(decode.callsign) {
                        HStack(spacing: 4) {
                            Text("🔥 #\(rank)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    } else {
                        Text("-")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 75, ideal: 95, max: 130)
                .customizationID("mostwanted")
                
                TableColumn("Entfernung") { decode in
                    let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                    if let dist = decode.distanceKm(myGrid: myGrid) {
                        cellText(String(format: "%.0f km", dist), decode: decode)
                    } else {
                        cellText("-", decode: decode)
                    }
                }
                .width(min: 65, ideal: 85, max: 120)
                .customizationID("distance")
                
                TableColumn("SNR") { decode in
                    cellText("\(decode.snr)", decode: decode)
                }
                .width(min: 40, ideal: 55, max: 80)
                .customizationID("snr")
                
                TableColumn("DT") { decode in
                    cellText(String(format: "%.1f", decode.deltaTime), decode: decode)
                }
                .width(min: 40, ideal: 55, max: 80)
                .customizationID("dt")
                
                TableColumn("HF Freq") { decode in
                    cellText(decode.formattedHfFrequency, decode: decode)
                }
                .width(min: 90, ideal: 110, max: 160)
                .customizationID("hfFreq")
                
                TableColumn("Audio (Hz)") { decode in
                    cellText("\(decode.deltaFrequency)", decode: decode)
                }
                .width(min: 60, ideal: 75, max: 110)
                .customizationID("audioFreq")
                
                TableColumn("Nachricht") { decode in
                    cellText(decode.message, decode: decode)
                }
                .width(min: 120, ideal: 260, max: 2000)
                .customizationID("message")
            }
            
            Divider()
            
            // Dedicated Most Wanted Section under the Main Table — dedupliziert nach Rufzeichen (bestes SNR pro Call)
            let mostWantedDecodes: [WSJTXDecode] = {
                var seen = Set<String>()
                var result: [WSJTXDecode] = []
                let filtered = viewModel.server.decodes
                    .filter { decode in
                        let call = decode.callsign
                        guard !call.isEmpty else { return false }
                        let isMW = MostWantedManager.shared.isMostWanted(callsign: call)
                        let hasWorkedOnBand = viewModel.lotwManager.hasWorked(callsign: call, band: decode.band)
                        return isMW && !hasWorkedOnBand
                    }
                    .sorted { a, b in
                        // Bestes SNR pro Callsign bevorzugen
                        a.snr > b.snr
                    }
                for decode in filtered {
                    let call = decode.callsign.uppercased()
                    if !seen.contains(call) {
                        seen.insert(call)
                        result.append(decode)
                    }
                }
                // Danach nach Most Wanted Rang sortieren
                return result.sorted { a, b in
                    let rankA = MostWantedManager.shared.rankForCallsign(a.callsign) ?? 999
                    let rankB = MostWantedManager.shared.rankForCallsign(b.callsign) ?? 999
                    return rankA < rankB
                }
            }()
            
            VStack(alignment: .leading, spacing: 4) {
                // Header & Draggable Resize Bar
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("MOST WANTED STATIONEN (UNGEARBEITET AUF DIESEM BAND)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("\(mostWantedDecodes.count)")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(mostWantedDecodes.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                    Text("Basis-Locator: \(myGrid)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Text("\(Int(mostWantedPanelHeight)) pt")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 12)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            let newHeight = mostWantedPanelHeight - value.translation.height
                            mostWantedPanelHeight = max(50.0, min(500.0, newHeight))
                        }
                )
                
                if mostWantedDecodes.isEmpty {
                    HStack {
                        Spacer()
                        Text("Keine ungearbeiteten Most Wanted Stationen auf diesem Band empfangen")
                            .font(.caption)
                            .italic()
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 12)
                        Spacer()
                    }
                    .frame(height: max(45, CGFloat(mostWantedPanelHeight)))
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 4) {
                            ForEach(mostWantedDecodes) { decode in
                                let call = decode.callsign
                                let rank = MostWantedManager.shared.rankForCallsign(call) ?? 999
                                let entity = MostWantedManager.shared.entityForCallsign(call)
                                let myGrid = UserDefaults.standard.string(forKey: "myGridLocator") ?? "JO31"
                                let dist = decode.distanceKm(myGrid: myGrid)
                                
                                HStack(spacing: 12) {
                                    // Rank Badge
                                    Text("🔥 RANG #\(rank)")
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                    
                                    // Callsign & Territory
                                    VStack(alignment: .leading, spacing: 1) {
                                        HStack(spacing: 6) {
                                            Text(call)
                                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                .foregroundColor(.red)
                                            if let ent = entity {
                                                Text("(\(ent.name) - \(ent.continent))")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Text(decode.message)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    // Band & Distance
                                    VStack(alignment: .trailing, spacing: 1) {
                                        Text(decode.band)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.15))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                        
                                        if let d = dist {
                                            Text(String(format: "%.0f km", d))
                                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    // Call Button
                                    Button(action: {
                                        viewModel.sendReply(for: decode)
                                    }) {
                                        Label("Anrufen", systemImage: "arrow.up.message.fill")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(6)
                                .onTapGesture(count: 2) {
                                    viewModel.sendReply(for: decode)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                    }
                    .frame(height: CGFloat(mostWantedPanelHeight))
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            bottomStatusBar
        }
        .alert("Fehler beim LoTW Sync", isPresented: Binding(
            get: { viewModel.lotwManager.errorMessage != nil },
            set: { if !$0 { viewModel.lotwManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.lotwManager.errorMessage ?? "")
        }
        .onAppear {
            viewModel.retryCooldownMinutes = retryCooldownMinutes
            viewModel.startServer(port: UInt16(udpPort), address: udpAddress)
        }
        .onChange(of: tableSelection) { _, newID in
            // Banner auf angeklickte Zeile aktualisieren
            if let id = newID,
               let decode = viewModel.server.decodes.first(where: { $0.id == id }) {
                viewModel.selectedCallsign = decode.callsign
            } else {
                // Keine Selektion → zurück auf aktiven DX-Call
                viewModel.selectedCallsign = ""
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenHelpWindow"))) { _ in
            openWindow(id: "help")
        }
        .onChange(of: retryCooldownMinutes) { _, newValue in
            viewModel.retryCooldownMinutes = newValue
        }
        .onChange(of: viewModel.server.decodes) { _, _ in
            // Beim nächsten Decode-Fenster immer auf aktuellen DX-Call zurücksetzen
            tableSelection = nil
            viewModel.selectedCallsign = ""
        }
        .onChange(of: udpPort) { _, newValue in
            viewModel.startServer(port: UInt16(newValue), address: udpAddress)
        }
        .onChange(of: udpAddress) { _, newValue in
            viewModel.startServer(port: UInt16(udpPort), address: newValue)
        }
        .frame(minWidth: 800, minHeight: 500)
    }
    
    @ViewBuilder
    private var bottomStatusBar: some View {
        HStack(spacing: 12) {
            // Left Side: QSO Status
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 11))
                Text(viewModel.currentQSOStatus)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Right Side: WSJT-X Connection & TX Status Indicators
            HStack(spacing: 10) {
                // WSJT-X Client Connection
                if !viewModel.server.wsjtxClientId.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("WSJT-X: \(viewModel.server.wsjtxClientId)")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("WSJT-X: Keine Verbindung")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.red.opacity(0.8))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                
                // TX Status Indicator
                if viewModel.server.isTransmitting {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("SENDET (TX)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .shadow(color: .red.opacity(0.5), radius: 2)
                } else if viewModel.server.isTxEnabled {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("TX BEREIT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                        Text("TX AUS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.15))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func cellText(_ text: String, decode: WSJTXDecode) -> some View {
        Text(text)
            .foregroundStyle(rowColor(for: decode))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                viewModel.sendReply(for: decode)
            }
            .onTapGesture(count: 1) {
                selectAndLookup(decode: decode)
            }
    }
    
    private func selectAndLookup(decode: WSJTXDecode) {
        let call = decode.callsign
        guard !call.isEmpty else { return }
        viewModel.selectedCallsign = call
    }
    
    private func openQRZ(callsign: String) {
        guard !callsign.isEmpty, let url = URL(string: "https://www.qrz.com/db/\(callsign)") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func rowColor(for decode: WSJTXDecode) -> Color {
        let call = decode.callsign
        if call.isEmpty { return .primary }
        
        if viewModel.lotwManager.hasWorked(callsign: call, band: decode.band) {
            return .gray
        }
        
        let highlightMW = UserDefaults.standard.object(forKey: "highlightMostWanted") as? Bool ?? true
        if highlightMW && MostWantedManager.shared.isMostWanted(callsign: call) {
            return .red
        }
        
        return .primary
    }
    
    private func formatTime(_ ms: UInt32) -> String {
        let seconds = ms / 1000
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
