import Foundation
import Combine

class WSJTXServer: ObservableObject {
    @Published var decodes: [WSJTXDecode] = []
    @Published var activeDxCall: String = ""
    @Published var isTransmitting: Bool = false
    @Published var isTxEnabled: Bool = false
    
    var onQSOLogged: (([QSOEntry]) -> Void)?
    var onHaltTx: (() -> Void)?
    var onDecodeReceived: ((WSJTXDecode, Data) -> Void)?
    var onRawLogReceived: ((WSJTXRawLogType, String) -> Void)?
    
    private let queue = DispatchQueue(label: "com.autoqso.wsjtx", qos: .userInitiated)
    private var wsjtSocketFd: Int32 = -1
    private var readSource: DispatchSourceRead?
    @Published var wsjtxClientId: String = ""
    private var lastWSJTClientAddr: sockaddr_in?
    private var recentlyLoggedCalls = [String: Date]()
    
    private var currentPort: UInt16 = 0
    private var currentAddress: String = ""
    
    func start(port: UInt16, address: String) {
        let actualPort = port == 0 ? UInt16(2237) : port
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let actualAddress = trimmedAddress.isEmpty ? "224.0.0.1" : trimmedAddress
        
        if wsjtSocketFd >= 0 && currentPort == actualPort && currentAddress == actualAddress {
            print("Socket bereits aktiv auf Port \(actualPort) (\(actualAddress))")
            return
        }
        
        currentPort = actualPort
        currentAddress = actualAddress
        
        stop()
        
        queue.async { [weak self] in
            guard let self = self else { return }
                let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
                guard fd >= 0 else {
                    let errMsg = "Fehler: UDP Socket konnte nicht erstellt werden (errno=\(errno))"
                    print(errMsg)
                    self.logRaw(.incoming, errMsg)
                    return
                }
                
                var reuse: Int32 = 1
                setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &reuse, socklen_t(MemoryLayout<Int32>.size))
                setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
                
                var broadcastOn: Int32 = 1
                setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &broadcastOn, socklen_t(MemoryLayout<Int32>.size))
                
                let flags = fcntl(fd, F_GETFL)
                _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
                
                var bindAddr = sockaddr_in()
                bindAddr.sin_family = sa_family_t(AF_INET)
                bindAddr.sin_port = actualPort.bigEndian
                bindAddr.sin_addr.s_addr = inet_addr("0.0.0.0") // Listen on all interfaces
                
                var bindResult: Int32 = -1
                for attempt in 1...5 {
                    bindResult = withUnsafePointer(to: &bindAddr) {
                        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                            Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                        }
                    }
                    if bindResult == 0 { break }
                    let attemptMsg = "bind() Versuch \(attempt) fehlgeschlagen (errno=\(errno)), erneuter Versuch in 200ms..."
                    print(attemptMsg)
                    self.logRaw(.incoming, attemptMsg)
                    usleep(200_000)
                }
                
                guard bindResult == 0 else {
                    close(fd)
                    let errMsg = "Fehler: Konnte Port \(actualPort) nach 5 Versuchen nicht binden (errno=\(errno)). Eventuell blockiert eine andere App (z.B. RUMlogNG) diesen Port."
                    print(errMsg)
                    self.logRaw(.incoming, errMsg)
                    return
                }
                
                self.wsjtSocketFd = fd
                
                let isMulticast: Bool = {
                    if let firstOctet = Int(actualAddress.components(separatedBy: ".").first ?? "") {
                        return firstOctet >= 224 && firstOctet <= 239
                    }
                    return false
                }()
                
                var ttl: UInt8 = 4
                setsockopt(fd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, socklen_t(MemoryLayout<UInt8>.size))
                var loop: UInt8 = 1
                setsockopt(fd, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, socklen_t(MemoryLayout<UInt8>.size))
                
                if isMulticast {
                    var mreq = ip_mreq()
                    mreq.imr_multiaddr.s_addr = inet_addr(actualAddress)
                    mreq.imr_interface.s_addr = inet_addr("0.0.0.0")
                    let joinResult = setsockopt(fd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, socklen_t(MemoryLayout<ip_mreq>.size))
                    if joinResult == 0 {
                        let okMsg = "Multicast-Gruppe \(actualAddress) auf Port \(actualPort) erfolgreich beigetreten"
                        print(okMsg)
                        self.logRaw(.incoming, okMsg)
                    } else {
                        let errMsg = "Fehler: Konnte Multicast-Gruppe \(actualAddress) auf Port \(actualPort) nicht beitreten (errno=\(errno))"
                        print(errMsg)
                        self.logRaw(.incoming, errMsg)
                    }
                } else {
                    let unicastMsg = "Server gestartet im Unicast-Modus auf Port \(actualPort) (IP: \(actualAddress))"
                    print(unicastMsg)
                    self.logRaw(.incoming, unicastMsg)
                }
                
                let source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: self.queue)
                source.setEventHandler { [weak self] in
                    self?.readSocket()
                }
                source.resume()
                
                DispatchQueue.main.async {
                    self.readSource = source
                    print("POSIX UDP Socket listening on port \(port)")
                }
        }
    }
    
    func stop() {
        currentPort = 0
        currentAddress = ""
        if wsjtSocketFd >= 0 {
            let fd = wsjtSocketFd
            wsjtSocketFd = -1
            readSource?.cancel()
            readSource = nil
            close(fd)
            print("Socket stopped")
        }
    }
    
    private var pendingRawLogs: [(WSJTXRawLogType, String)] = []
    private var isRawLogFlushScheduled = false
    
    private func logRaw(_ type: WSJTXRawLogType, _ message: String) {
        pendingRawLogs.append((type, message))
        guard !isRawLogFlushScheduled else { return }
        isRawLogFlushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.isRawLogFlushScheduled = false
            let logs = self.pendingRawLogs
            self.pendingRawLogs.removeAll(keepingCapacity: true)
            for (t, m) in logs {
                self.onRawLogReceived?(t, m)
            }
        }
    }
    
    func sendRaw(data: Data, toPort port: UInt16, address: String = "127.0.0.1") {
        let trimmedAddr = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetAddr = trimmedAddr.isEmpty ? "127.0.0.1" : trimmedAddr
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else { return }
        defer { close(fd) }
        
        var broadcastOn: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &broadcastOn, socklen_t(MemoryLayout<Int32>.size))
        
        var ttl: UInt8 = 4
        setsockopt(fd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, socklen_t(MemoryLayout<UInt8>.size))
        var loop: UInt8 = 1
        setsockopt(fd, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, socklen_t(MemoryLayout<UInt8>.size))
        
        var dest = sockaddr_in()
        dest.sin_family = sa_family_t(AF_INET)
        dest.sin_port = port.bigEndian
        dest.sin_addr.s_addr = inet_addr(targetAddr)
        
        let sent = withUnsafePointer(to: &dest) { destPtr in
            destPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                sendto(fd, Array(data), data.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if sent >= 0 {
            self.logRaw(.outgoing, "Bridge: sent \(data.count) bytes to \(targetAddr):\(port)")
        } else {
            self.logRaw(.outgoing, "Bridge failed (errno=\(errno)): to \(targetAddr):\(port)")
        }
    }
    
    private func readSocket() {
        let fd = self.wsjtSocketFd
        guard fd >= 0 else { return }
        
        var buffer = [UInt8](repeating: 0, count: 65536)
        var srcAddr = sockaddr_in()
        var srcLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        while true {
            let bytesRead = withUnsafeMutablePointer(to: &srcAddr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    recvfrom(fd, &buffer, buffer.count, 0, sa, &srcLen)
                }
            }
            guard bytesRead > 0 else { break }
            
            let data = Data(bytes: buffer, count: bytesRead)
            self.lastWSJTClientAddr = srcAddr
            self.parse(data)
        }
    }
    
    private var currentDialFrequency: UInt64 = 0
    
    private func parse(_ data: Data) {
        var reader = QDataStreamReader(data: data)
        
        guard let magic = reader.readUInt32() else { return }
        guard magic == 0xADBCCBDA else { return }
        
        guard let _ = reader.readUInt32() else { return }
        
        guard let msgTypeVal = reader.readUInt32() else { return }
        guard let msgType = WSJTXMessageType(rawValue: msgTypeVal) else { return }
        
        guard let clientId = reader.readString() else { return }
        if self.wsjtxClientId != clientId {
            DispatchQueue.main.async {
                self.wsjtxClientId = clientId
            }
        }
        
        switch msgType {
        case .status:
            if let dialFreq = reader.readUInt64() {
                self.currentDialFrequency = dialFreq
            }
            let mode = reader.readString() ?? ""
            let dxCall = reader.readString() ?? ""
            let _ = reader.readString() // report
            let _ = reader.readString() // txMode
            let txEnabled = reader.readBool() ?? false
            let transmitting = reader.readBool() ?? false
            
            let freqMhz = Double(self.currentDialFrequency) / 1_000_000.0
            self.logRaw(.incoming, "Status: client=\(clientId) freq=\(String(format: "%.6f", freqMhz))MHz mode=\(mode) txEnabled=\(txEnabled) transmitting=\(transmitting) dxCall=\(dxCall)")
            
            DispatchQueue.main.async {
                if self.isTxEnabled != txEnabled { self.isTxEnabled = txEnabled }
                if self.isTransmitting != transmitting { self.isTransmitting = transmitting }
                if !dxCall.isEmpty && self.activeDxCall != dxCall {
                    self.activeDxCall = dxCall
                }
            }
        case .haltTx:
            self.logRaw(.incoming, "Halt TX: client=\(clientId)")
            DispatchQueue.main.async {
                self.onHaltTx?()
            }
        case .clear:
            // Typ 3: WSJT-X signalisiert Beginn eines neuen Decode-Fensters
            let _ = reader.readUInt8() // window type (optional, ignorieren)
            self.logRaw(.incoming, "Clear: client=\(clientId)")
            // Liste wird nicht mehr zyklisch gelöscht – ältere Einträge fallen unten heraus (FIFO 250)
            
        case .decode:
            // isNew=true  → frischer Decode aus aktuellem 15s-Fenster
            // isNew=false → Replay eines älteren Decodes (Knopf "Replay" in WSJT-X)
            let isNew = reader.readBool() ?? true
            let time = reader.readTime() ?? 0
            let snr = reader.readInt32() ?? 0
            let dt = reader.readDouble() ?? 0.0
            let df = reader.readUInt32() ?? 0
            let mode = reader.readString() ?? ""
            let message = reader.readString() ?? ""
            let lowConf = reader.readBool() ?? false
            let offAir = reader.readBool() ?? false
            
            guard !message.isEmpty else { return }
            
            let decode = WSJTXDecode(
                time: time,
                snr: snr,
                deltaTime: dt,
                deltaFrequency: df,
                dialFrequency: self.currentDialFrequency,
                mode: mode,
                message: message,
                lowConfidence: lowConf,
                offAir: offAir
            )
            
            let freqMhz = Double(decode.totalFrequencyHz) / 1_000_000.0
            self.logRaw(.decode, "Decode: client=\(clientId) msg=\"\(message)\" snr=\(snr) dt=\(dt) freq=\(String(format: "%.6f", freqMhz))MHz mode=\(mode) isNew=\(isNew)")
            
            DispatchQueue.main.async {
                // Doubletten verhindern: gleiche Nachricht + Zeit + Frequenz
                let isDuplicate = self.decodes.contains { existing in
                    existing.message == decode.message &&
                    existing.time == decode.time &&
                    existing.deltaFrequency == decode.deltaFrequency
                }
                guard !isDuplicate else { return }
                
                self.decodes.insert(decode, at: 0)
                self.onDecodeReceived?(decode, data)
                if self.decodes.count > 250 {
                    self.decodes.removeSubrange(250...)
                }
            }
        case .loggedAdif:
            if let adifText = reader.readString() {
                let entries = ADIFParser.parseQSOs(from: adifText)
                self.logRaw(.incoming, "Logged ADIF: client=\(clientId), entries=\(entries.count)")
                for entry in entries {
                    self.recentlyLoggedCalls[entry.callsign.uppercased()] = Date()
                }
                DispatchQueue.main.async {
                    self.onQSOLogged?(entries)
                }
            }
        case .qsoLogged:
            _ = reader.readUInt64() // DateTime off
            if let dxCall = reader.readString(),
               let _ = reader.readString(), // grid
               let freq = reader.readUInt64(), // freq
               let mode = reader.readString() {
                
                let callUpper = dxCall.uppercased()
                if let lastTime = self.recentlyLoggedCalls[callUpper], Date().timeIntervalSince(lastTime) < 15.0 {
                    self.logRaw(.incoming, "Ignored duplicate qsoLogged for \(dxCall) (already processed via loggedAdif)")
                    return
                }
                self.recentlyLoggedCalls[callUpper] = Date()
                
                let actualFreq = freq > 0 ? freq : self.currentDialFrequency
                let actualBand = WSJTXDecode.bandFromFrequency(actualFreq)
                
                let fmt = DateFormatter()
                fmt.timeZone = TimeZone(secondsFromGMT: 0)
                fmt.dateFormat = "yyyyMMdd"
                let dateStr = fmt.string(from: Date())
                fmt.dateFormat = "HHmm"
                let timeStr = fmt.string(from: Date())
                
                let entry = QSOEntry(
                    callsign: dxCall,
                    band: actualBand,
                    mode: mode,
                    qsoDate: dateStr,
                    timeOn: timeStr,
                    dxcc: ""
                )
                self.logRaw(.incoming, "QSO Logged: client=\(clientId) call=\(dxCall) band=\(actualBand) mode=\(mode)")
                DispatchQueue.main.async {
                    self.onQSOLogged?([entry])
                }
            }
        case .reply, .enableTx:
            self.logRaw(.incoming, "Ignored Packet \(msgType) from client \(clientId)")
            return
        case .heartbeat:
            self.logRaw(.incoming, "Heartbeat: client=\(clientId)")
        default:
            self.logRaw(.incoming, "Unhandled Packet (\(msgType)): client=\(clientId)")
        }
    }
    
    func sendReply(_ reply: WSJTXReply) {
        var rep = reply
        rep.id = self.wsjtxClientId
        let data = rep.serialize()
        
        guard wsjtSocketFd >= 0, let clientAddr = lastWSJTClientAddr else {
            print("Cannot send reply: socket not ready or client address unknown")
            self.logRaw(.outgoing, "Reply failed: socket not ready/address unknown")
            return
        }
        var addr = clientAddr
        
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    let sent = sendto(wsjtSocketFd, baseAddress, data.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    if sent < 0 {
                        print("Error sending reply: errno=\(errno)")
                        self.logRaw(.outgoing, "Reply failed (errno=\(errno)): client=\(self.wsjtxClientId) msg=\"\(reply.message)\"")
                    } else {
                        print("Sent reply of \(sent) bytes back to WSJT-X client")
                        self.logRaw(.outgoing, "Reply: client=\(self.wsjtxClientId) msg=\"\(reply.message)\" freq=\(reply.deltaFrequency)Hz mode=\(reply.mode)")
                    }
                }
            }
        }
    }
    
    func sendHaltTx(autoTxOnly: Bool = false) {
        let halt = WSJTXHaltTx(id: self.wsjtxClientId, autoTxOnly: autoTxOnly)
        let data = halt.serialize()
        
        guard wsjtSocketFd >= 0, let clientAddr = lastWSJTClientAddr else {
            print("Cannot send haltTx: socket not ready or client address unknown")
            self.logRaw(.outgoing, "HaltTx failed: socket not ready/address unknown")
            return
        }
        var addr = clientAddr
        
        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }
            withUnsafePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    let sent = sendto(wsjtSocketFd, baseAddress, data.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    if sent < 0 {
                        print("Error sending haltTx: errno=\(errno)")
                        self.logRaw(.outgoing, "HaltTx failed (errno=\(errno)): client=\(self.wsjtxClientId)")
                    } else {
                        print("Sent haltTx of \(sent) bytes back to WSJT-X client")
                        self.logRaw(.outgoing, "HaltTx: client=\(self.wsjtxClientId) autoTxOnly=\(autoTxOnly)")
                    }
                }
            }
        }
    }
}

