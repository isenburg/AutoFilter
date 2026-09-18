import Foundation
import Network

class DXClusterServer {
    private var listener: NWListener?
    private var connectedClients: [NWConnection] = []
    var onStatusChange: ((String?) -> Void)?
    var onClientCountChange: ((Int) -> Void)?
    var onCommandReceived: ((String, NWConnection) -> Void)?
    
    private let serverQueue = DispatchQueue(label: "com.dxfilter.server", qos: .userInitiated)
    
    func start(port: UInt16) throws {
        stop()
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true
        
        let nwPort = NWEndpoint.Port(rawValue: port)!
        listener = try NWListener(using: parameters, on: nwPort)
        
        listener?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.onStatusChange?(nil)
                    print("Server listening on port \(port)")
                case .failed(let error):
                    self?.onStatusChange?("Server error: \(error.localizedDescription)")
                case .cancelled:
                    break
                default:
                    break
                }
            }
        }
        
        listener?.newConnectionHandler = { [weak self] newConnection in
            self?.setupNewClient(newConnection)
        }
        
        listener?.start(queue: serverQueue)
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        serverQueue.sync {
            for client in connectedClients {
                client.cancel()
            }
            connectedClients.removeAll()
        }
    }
    
    private func setupNewClient(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            print("Client \(connection.endpoint) state: \(state)")
            
            switch state {
            case .failed, .cancelled:
                self?.removeClient(connection)
            case .ready:
                print("Client \(connection.endpoint) connected and READY")
                self?.sendWelcome(to: connection)
                self?.setupReceive(for: connection)
                DispatchQueue.main.async {
                    self?.onClientCountChange?(self?.connectedClients.count ?? 0)
                }
            default:
                break
            }
        }
        
        connectedClients.append(connection)
        connection.start(queue: serverQueue)
    }
    
    private func setupReceive(for connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                let command = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !command.isEmpty {
                    self?.onCommandReceived?(command, connection)
                }
            }
            if error == nil && !isComplete {
                self?.setupReceive(for: connection)
            }
        }
    }
    
    private func removeClient(_ connection: NWConnection) {
        serverQueue.async {
            self.connectedClients.removeAll { $0 === connection }
            print("Client disconnected. Remaining: \(self.connectedClients.count)")
            DispatchQueue.main.async {
                self.onClientCountChange?(self.connectedClients.count)
            }
        }
    }
    
    private func sendWelcome(to connection: NWConnection) {
        let welcome = "Welcome to AutoFilter DX-Cluster Telnet Server\r\nCopyright 2026 by Georg Isenbuerger - DJ6GI\r\n\r\n"
        if let data = welcome.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    print("Welcome send failed: \(error)")
                } else {
                    print("Welcome sent to \(connection.endpoint)")
                }
            }))
        }
    }
    
    func broadcast(spot: DXSpot) {
        let cleanLine = spot.rawLine.trimmingCharacters(in: .newlines)
        let formattedLine = cleanLine + "\r\n"
        
        guard let data = formattedLine.data(using: .utf8) else { return }
        
        serverQueue.async {
            let readyClients = self.connectedClients.filter { $0.state == .ready }
            
            for client in readyClients {
                client.send(content: data, completion: .contentProcessed({ error in
                    if let error = error {
                        print("Send to \(client.endpoint) failed: \(error)")
                    }
                }))
            }
        }
    }
    
    func broadcastRaw(line: String) {
        let cleanLine = line.trimmingCharacters(in: .newlines)
        let formattedLine = cleanLine + "\r\n"
        guard let data = formattedLine.data(using: .utf8) else { return }
        
        serverQueue.async {
            let readyClients = self.connectedClients.filter { $0.state == .ready }
            for client in readyClients {
                client.send(content: data, completion: .contentProcessed({ error in
                    if let _ = error {}
                }))
            }
        }
    }
}
