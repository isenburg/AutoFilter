import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: DecodeViewModel
    
    @AppStorage("lotwUsername") private var lotwUsername = ""
    @AppStorage("lotwPassword") private var lotwPassword = ""
    @AppStorage("qrzApiKey") private var qrzApiKey = ""
    @AppStorage("udpPort") private var udpPort: Int = 2237
    @AppStorage("udpAddress") private var udpAddress = "224.0.0.1"
    @AppStorage("retryCooldownMinutes") private var retryCooldownMinutes: Int = 10
    @AppStorage("decode_column_customization") private var decodeColumnCustomization: TableColumnCustomization<WSJTXDecode>
    
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
            // Top Settings Bar (Harmonious & Perfectly Aligned)
            HStack(alignment: .center, spacing: 14) {
                // UDP Section
                VStack(alignment: .leading, spacing: 3) {
                    Text("UDP SERVER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        TextField("224.0.0.1", text: $udpAddress)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 95)
                        
                        Text(":")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("2237", value: $udpPort, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                        
                        Text(isMulticastAddress ? "MC" : "UC")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(isMulticastAddress ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundColor(isMulticastAddress ? .blue : .orange)
                            .cornerRadius(4)
                    }
                }
                
                Divider()
                    .frame(height: 36)
                
                // LoTW Section
                VStack(alignment: .leading, spacing: 3) {
                    Text("LOTW ZUGANGSDATEN")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        TextField("User", text: $lotwUsername)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 85)
                        SecureField("Pass", text: $lotwPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 85)
                        Button("LoTW Sync") {
                            viewModel.lotwManager.downloadLoTW(username: lotwUsername, password: lotwPassword)
                        }
                        .disabled(lotwUsername.isEmpty || lotwPassword.isEmpty || viewModel.lotwManager.isDownloading)
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                Divider()
                    .frame(height: 36)
                
                // QRZ Section
                VStack(alignment: .leading, spacing: 3) {
                    Text("QRZ.COM API KEY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        SecureField("API Key", text: $qrzApiKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        Button("QRZ Sync") {
                            viewModel.syncQRZ(apiKey: qrzApiKey)
                        }
                        .disabled(qrzApiKey.isEmpty || viewModel.qrzManager.isDownloading)
                        .buttonStyle(.borderedProminent)
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
                
                Divider()
                    .frame(height: 36)
                
                // Auto QSO Section
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
                
                Spacer()
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
                
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Text(displayCall)
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.orange)
                        
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
            
            // Log History Terminal (LoTW + QRZ)
            let logs = (viewModel.lotwManager.logHistory + viewModel.qrzManager.logHistory)
            if !logs.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(logs, id: \.self) { log in
                            Text(log)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(log.contains("Fehler") ? .red : .primary)
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
            Table(viewModel.server.decodes, columnCustomization: $decodeColumnCustomization) {
                TableColumn("Zeit") { decode in
                    cellText(formatTime(decode.time), decode: decode)
                }
                .width(min: 70, ideal: 85, max: 120)
                .customizationID("time")
                
                TableColumn("DX Call") { decode in
                    cellText(decode.callsign, decode: decode)
                }
                .width(min: 80, ideal: 100, max: 180)
                .customizationID("callsign")
                
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
                .width(min: 90, ideal: 120, max: 180)
                .customizationID("hfFreq")
                
                TableColumn("Audio (Hz)") { decode in
                    cellText("\(decode.deltaFrequency)", decode: decode)
                }
                .width(min: 60, ideal: 80, max: 120)
                .customizationID("audioFreq")
                
                TableColumn("Nachricht") { decode in
                    cellText(decode.message, decode: decode)
                }
                .width(min: 120, ideal: 300, max: 2000)
                .customizationID("message")
            }
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
        .onChange(of: retryCooldownMinutes) { _, newValue in
            viewModel.retryCooldownMinutes = newValue
        }
        .onChange(of: udpPort) { _, newValue in
            viewModel.startServer(port: UInt16(newValue), address: udpAddress)
        }
        .onChange(of: udpAddress) { _, newValue in
            viewModel.startServer(port: UInt16(udpPort), address: newValue)
        }
        .frame(minWidth: 800, minHeight: 500)
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
