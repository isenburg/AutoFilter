import Foundation
import Combine

class WSJTXServer: ObservableObject {
    @Published var decodes: [WSJTXDecode] = []
    @Published var activeDxCall: String = ""
    @Published var isTransmitting: Bool = false
    @Published var isTxEnabled: Bool = false
    
    var onQSOLogged: (([QSOEntry]) -> Void)?
    var onHaltTx: (() -> Void)?
    
    private let queue = DispatchQueue(label: "com.autoqso.wsjtx", qos: .userInitiated)
    private var wsjtSocketFd: Int32 = -1
    private var readSource: DispatchSourceRead?
    @Published var wsjtxClientId: String = ""
    private var lastWSJTClientAddr: sockaddr_in?
    
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
                    print("Failed to create socket: errno=\(errno)")
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
                    print("bind() attempt \(attempt) failed (errno=\(errno)), retrying in 200ms...")
                    usleep(200_000)
                }
                
                guard bindResult == 0 else {
                    close(fd)
                    print("bind() error: Konnte Port \(actualPort) nach 5 Versuchen nicht binden (errno=\(errno))")
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
                        print("Multicast-Gruppe \(actualAddress) auf Port \(actualPort) beigetreten")
                    } else {
                        print("IP_ADD_MEMBERSHIP fehlgeschlagen: errno=\(errno)")
                    }
                } else {
                    print("Unicast-Modus auf Port \(actualPort) (IP: \(actualAddress))")
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
        print("UDP Paket empfangen: \(data.count) Bytes")
        var reader = QDataStreamReader(data: data)
        
        guard let magic = reader.readUInt32() else { print("Fehler: Konnte Magic nicht lesen"); return }
        guard magic == 0xADBCCBDA else {
            print("Fehler: Magic Number stimmt nicht überein (Gelesen: \(String(format: "%08X", magic)))")
            return
        }
        
        guard let schema = reader.readUInt32() else { print("Fehler: Konnte Schema nicht lesen"); return }
        print("Schema Version: \(schema)")
        
        guard let msgTypeVal = reader.readUInt32() else { print("Fehler: Konnte MessageType nicht lesen"); return }
        guard let msgType = WSJTXMessageType(rawValue: msgTypeVal) else {
            print("Ignoriere unbekannten MessageType: \(msgTypeVal)")
            return
        }
        
        print("Message Type erkannt: \(msgType)")
        
        guard let clientId = reader.readString() else { print("Fehler: Konnte Client ID nicht lesen"); return }
        DispatchQueue.main.async {
            self.wsjtxClientId = clientId
        }
        
        switch msgType {
        case .status:
            if let dialFreq = reader.readUInt64() {
                self.currentDialFrequency = dialFreq
            }
            let _ = reader.readString() // mode
            let dxCall = reader.readString() ?? ""
            let _ = reader.readString() // report
            let _ = reader.readString() // txMode
            let txEnabled = reader.readBool() ?? false
            let transmitting = reader.readBool() ?? false
            
            DispatchQueue.main.async {
                self.isTxEnabled = txEnabled
                self.isTransmitting = transmitting
                if !dxCall.isEmpty {
                    self.activeDxCall = dxCall
                }
            }
        case .haltTx:
            print("WSJT-X Halt TX empfangen")
            DispatchQueue.main.async {
                self.onHaltTx?()
            }
        case .clear:
            // Typ 3: WSJT-X signalisiert Beginn eines neuen Decode-Fensters → Liste leeren
            let _ = reader.readUInt8() // window type (optional, ignorieren)
            print("WSJT-X Clear empfangen → Decode-Liste wird geleert")
            DispatchQueue.main.async {
                self.decodes.removeAll()
            }
            
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
            
            print("Decode (isNew=\(isNew)): \(message)")
            DispatchQueue.main.async {
                // Doubletten verhindern: gleiche Nachricht + Zeit + Frequenz
                let isDuplicate = self.decodes.contains { existing in
                    existing.message == decode.message &&
                    existing.time == decode.time &&
                    existing.deltaFrequency == decode.deltaFrequency
                }
                guard !isDuplicate else { return }
                
                self.decodes.insert(decode, at: 0)
                if self.decodes.count > 500 {
                    self.decodes.removeSubrange(500...)
                }
            }
        case .loggedAdif:
            if let adifText = reader.readString() {
                let entries = ADIFParser.parseQSOs(from: adifText)
                print("WSJT-X Logged ADIF empfangen (\(entries.count) QSOs)")
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
                print("WSJT-X QSO Logged: \(dxCall) auf \(actualBand)")
                DispatchQueue.main.async {
                    self.onQSOLogged?([entry])
                }
            }
        case .reply, .enableTx:
            // Nachführung/Verwerfung: Empfangene EnableTx / Reply-Pakete auf dem UDP-Port ignorieren
            print("WSJT-X EnableTx / Reply Paket auf UDP-Port empfangen → wird ignoriert/verworfen")
            return
            
        default:
            break
        }
    }
    
    func sendReply(_ reply: WSJTXReply) {
        var rep = reply
        rep.id = self.wsjtxClientId
        let data = rep.serialize()
        
        guard wsjtSocketFd >= 0, let clientAddr = lastWSJTClientAddr else {
            print("Cannot send reply: socket not ready or client address unknown")
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
                    } else {
                        print("Sent reply of \(sent) bytes back to WSJT-X client")
                    }
                }
            }
        }
    }
}
