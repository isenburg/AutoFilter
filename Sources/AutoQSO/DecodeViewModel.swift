import Foundation
import Combine

class DecodeViewModel: ObservableObject {
    @Published var server = WSJTXServer()
    @Published var lotwManager = LoTWManager()
    @Published var qrzManager = QRZManager()
    @Published var selectedCallsign: String = ""
    @Published var isAutoModeEnabled: Bool = false
    @Published var retryCooldownMinutes: Int = 10
    @Published var currentQSOStatus: String = "Bereit"
    
    private var blacklistedCalls: [String: Date] = [:]
    private var currentTargetCall: String = ""
    private var qsoStartTime: Date?
    
    var displayCallsign: String {
        if !selectedCallsign.isEmpty {
            return selectedCallsign
        }
        return server.activeDxCall
    }
    
    // Default band for now, WSJT-X Status message provides the actual band, but for simplicity we can assume a default or get it from decodes (though decodes don't explicitly send band, only freq).
    // Let's deduce band from frequency.
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Immediately start server on launch from UserDefaults with fallbacks
        let savedPort = UserDefaults.standard.integer(forKey: "udpPort")
        let actualPort = savedPort > 0 ? UInt16(savedPort) : UInt16(2237)
        let savedAddress = UserDefaults.standard.string(forKey: "udpAddress") ?? "224.0.0.1"
        server.start(port: actualPort, address: savedAddress)
        
        server.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                    self?.evaluateAutoQSO()
                }
            }
            .store(in: &cancellables)
            
        lotwManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        qrzManager.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        server.onQSOLogged = { [weak self] newEntries in
            guard let self = self else { return }
            self.lotwManager.mergeEntries(newEntries)
            
            for entry in newEntries {
                if entry.callsign.uppercased() == self.currentTargetCall.uppercased() || self.currentTargetCall.isEmpty {
                    self.currentQSOStatus = "QSO mit \(entry.callsign) erfolgreich beendet!"
                    self.currentTargetCall = ""
                    self.qsoStartTime = nil
                }
            }
            
            // Auto-trigger QRZ Sync on successful QSO
            let qrzKey = UserDefaults.standard.string(forKey: "qrzApiKey") ?? ""
            if !qrzKey.isEmpty {
                self.syncQRZ(apiKey: qrzKey)
            }
        }
        
        server.onHaltTx = { [weak self] in
            guard let self = self else { return }
            if !self.currentTargetCall.isEmpty {
                let call = self.currentTargetCall
                self.blacklistedCalls[call.uppercased()] = Date()
                self.currentQSOStatus = "QSO mit \(call) abgebrochen. Gesperrt für \(self.retryCooldownMinutes) Min."
                self.currentTargetCall = ""
                self.qsoStartTime = nil
            }
        }
    }
    
    func evaluateAutoQSO() {
        guard isAutoModeEnabled else { return }
        
        // If currently in an active QSO attempt, monitor status/timeout before starting any new target
        if !currentTargetCall.isEmpty {
            if let start = qsoStartTime, Date().timeIntervalSince(start) > 120.0 {
                let failedCall = currentTargetCall
                blacklistedCalls[failedCall.uppercased()] = Date()
                currentQSOStatus = "QSO mit \(failedCall) erfolglos (Timeout). Gesperrt für \(retryCooldownMinutes) Min."
                currentTargetCall = ""
                qsoStartTime = nil
            } else {
                // Still waiting for current QSO to complete, halt, or timeout
                return
            }
        }
        
        for decode in server.decodes {
            let call = decode.callsign.uppercased()
            guard !call.isEmpty else { continue }
            
            let upperMsg = decode.message.uppercased()
            let msgTokens = upperMsg.components(separatedBy: .whitespacesAndNewlines).map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
            
            let isCQ = upperMsg.contains("CQ ") || upperMsg.hasPrefix("CQ")
            let is73 = msgTokens.contains("73") || msgTokens.contains("RR73") || msgTokens.contains("RRR")
            
            if isCQ || is73 {
                // Check if not worked on this band
                if !lotwManager.hasWorked(callsign: call, band: decode.band) {
                    // Check if callsign is currently in failure/aborted cooldown
                    if let blacklistedAt = blacklistedCalls[call] {
                        let elapsedMinutes = Date().timeIntervalSince(blacklistedAt) / 60.0
                        if elapsedMinutes < Double(retryCooldownMinutes) {
                            continue // Still in retry cooldown
                        } else {
                            blacklistedCalls.removeValue(forKey: call) // Cooldown expired
                        }
                    }
                    
                    currentTargetCall = call
                    qsoStartTime = Date()
                    currentQSOStatus = "AutoQSO: Rufe \(call) (\(decode.band))..."
                    
                    print("AutoQSO Engine: Starte Anruf -> \(call) (\(decode.band)) [Msg: \(decode.message)]")
                    sendReply(for: decode)
                    break
                }
            }
        }
    }
    
    func syncQRZ(apiKey: String) {
        qrzManager.downloadQRZ(apiKey: apiKey) { [weak self] qrzEntries in
            self?.lotwManager.mergeEntries(qrzEntries)
        }
    }
    
    func startServer(port: UInt16, address: String) {
        server.start(port: port, address: address)
    }
    
    func getBand(from frequency: UInt32) -> String {
        // Simple mapping, WSJTX sends frequency in Hz? Actually, Decode message doesn't have absolute frequency, only DeltaFrequency.
        // Status message has dial frequency. We might need to listen to Status message to get current band.
        // For this minimal setup, let's assume we can map from a setting or just "20M".
        // To do this perfectly, we'd add parsing for Status message.
        return "20M" // Placeholder
    }
    
    func sendReply(for decode: WSJTXDecode) {
        server.activeDxCall = decode.callsign
        let reply = WSJTXReply(
            id: "AutoQSO",
            time: decode.time,
            snr: decode.snr,
            deltaTime: decode.deltaTime,
            deltaFrequency: decode.deltaFrequency,
            mode: decode.mode,
            message: decode.message,
            lowConfidence: decode.lowConfidence,
            modifiers: 0 // No modifiers
        )
        server.sendReply(reply)
    }
}
