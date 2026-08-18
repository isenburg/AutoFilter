import Foundation
import Network
import Combine

class DXClusterClient: ObservableObject {
    private var connection: NWConnection?
    private let clientQueue = DispatchQueue(label: "com.dxfilter.client", qos: .userInitiated)
    private var receiveBuffer = ""
    var onLineReceived: ((String) -> Void)?
    var onStateChange: ((NWConnection.State) -> Void)?
    var onError: ((String) -> Void)?

    func connect(host: String, port: UInt16) {
        disconnect()
        
        let nwHost = NWEndpoint.Host(host)
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
        
        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
        self.receiveBuffer = ""
        connection?.stateUpdateHandler = { [weak self] state in
            self?.onStateChange?(state)
            if case .failed(let error) = state {
                let detailedMsg = self?.detailedErrorMessage(for: error) ?? error.localizedDescription
                self?.onError?("Connection to \(host):\(port) failed: \(detailedMsg)")
            } else if case .waiting(let error) = state {
                let detailedMsg = self?.detailedErrorMessage(for: error) ?? error.localizedDescription
                self?.onError?("Connection to \(host):\(port) waiting: \(detailedMsg)")
            }
        }
        
        setupReceive()
        connection?.start(queue: clientQueue)
    }

    func logoutAndDisconnect() {
        if connection?.state == .ready {
            send(text: "BYE")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.disconnect()
            }
        } else {
            disconnect()
        }
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
    }

    func send(text: String) {
        let data = (text + "\r\n").data(using: .utf8)
        connection?.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Send Error: \(error)")
            }
        }))
    }

    private func setupReceive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if let data = data, let newStr = String(data: data, encoding: .utf8) {
                self.receiveBuffer += newStr
                
                var components = self.receiveBuffer.components(separatedBy: .newlines)
                self.receiveBuffer = components.removeLast()
                
                for line in components {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        self.onLineReceived?(trimmed)
                    }
                }
                
                let lowerBuffer = self.receiveBuffer.lowercased()
                if lowerBuffer.contains("login:") || lowerBuffer.contains("call:") || lowerBuffer.contains("enter your call") {
                    self.onLineReceived?(self.receiveBuffer)
                    self.receiveBuffer = ""
                }
            }
            if error == nil && !isComplete {
                self.setupReceive()
            }
        }
    }

    private func detailedErrorMessage(for error: NWError) -> String {
        switch error {
        case .posix(let code):
            switch code {
            case .ECONNREFUSED: return "Connection refused (Port may be closed or server offline)"
            case .ETIMEDOUT: return "Connection timed out (Server unresponsive)"
            case .ENETUNREACH: return "Network unreachable (Check your internet connection)"
            case .EHOSTUNREACH: return "Host unreachable (Server may be down)"
            case .ECONNRESET: return "Connection reset by peer"
            default: return "POSIX Error \(code.rawValue): \(error.localizedDescription)"
            }
        case .dns(let code):
            return "DNS Resolution Failed (Code \(code)): \(error.localizedDescription)"
        case .tls(let status):
            return "TLS Security Error (\(status)): \(error.localizedDescription)"
        case .wifiAware(let code):
            return "WiFi Aware Error (\(code)): \(error.localizedDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }
}
