import Foundation

struct ClusterServer: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var host: String
    var port: UInt16
    var username: String?
    var password: String?
    
    static var defaultClusters: [ClusterServer] {
        [
            ClusterServer(name: "Reverse Beacon Network", host: "telnet.reversebeacon.net", port: 7000, username: nil, password: nil),
            ClusterServer(name: "VE7CC-1", host: "dxc.ve7cc.net", port: 23, username: nil, password: nil),
            ClusterServer(name: "K3LR", host: "dx.k3lr.com", port: 23, username: nil, password: nil),
            ClusterServer(name: "W3LPL", host: "dxc.w3lpl.net", port: 7373, username: nil, password: nil),
            ClusterServer(name: "W1NR", host: "dx.w1nr.net", port: 7300, username: nil, password: nil),
            ClusterServer(name: "K1TTT", host: "k1ttt.net", port: 7373, username: nil, password: nil),
            ClusterServer(name: "PI4CC", host: "dxc.pi4cc.nl", port: 8000, username: nil, password: nil),
            ClusterServer(name: "SK3W", host: "sk3w.se", port: 8000, username: nil, password: nil),
            ClusterServer(name: "DXSpider UK", host: "dxspider.co.uk", port: 7300, username: nil, password: nil)
        ]
    }
}
