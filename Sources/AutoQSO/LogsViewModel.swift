import Observation
import Foundation
import Combine
import SwiftUI

@Observable
class LogsViewModel {
    var logHistory: [String] = []
    var wsjtxRawLogs: [WSJTXRawLogEntry] = []
    var clusterRawLogs: [ClusterRawLogEntry] = []
    
    var isLogConsoleDetached: Bool = UserDefaults.standard.bool(forKey: "isLogConsoleDetached") {
        didSet {
            UserDefaults.standard.set(isLogConsoleDetached, forKey: "isLogConsoleDetached")
        }
    }
    
    var isLogScrollPaused: Bool = false {
        didSet {
            if isLogScrollPaused {
                frozenSystemLogs = logHistory
                frozenWSJTXLogs = wsjtxRawLogs
                frozenClusterLogs = clusterRawLogs
            } else {
                frozenSystemLogs = nil
                frozenWSJTXLogs = nil
                frozenClusterLogs = nil
            }
        }
    }
    
    var logConsoleSearchText: String = ""
    var frozenSystemLogs: [String]? = nil
    var frozenWSJTXLogs: [WSJTXRawLogEntry]? = nil
    var frozenClusterLogs: [ClusterRawLogEntry]? = nil
    
    private let maxLogCount = 300
    
    init() {}
    
    func addLog(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logHistory.append(message)
            if self.logHistory.count > self.maxLogCount {
                self.logHistory.removeFirst(self.logHistory.count - self.maxLogCount)
            }
        }
    }
    
    func addWSJTXRawLog(type: WSJTXRawLogType, message: String) {
        let entry = WSJTXRawLogEntry(timestamp: Date(), type: type, message: message)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.wsjtxRawLogs.insert(entry, at: 0)
            if self.wsjtxRawLogs.count > self.maxLogCount {
                self.wsjtxRawLogs.removeSubrange(self.maxLogCount...)
            }
        }
    }
    
    func addClusterRawLog(message: String) {
        let entry = ClusterRawLogEntry(timestamp: Date(), message: message)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.clusterRawLogs.insert(entry, at: 0)
            if self.clusterRawLogs.count > self.maxLogCount {
                self.clusterRawLogs.removeSubrange(self.maxLogCount...)
            }
        }
    }
    
    func clearLogs(tab: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if tab == 0 {
                self.logHistory.removeAll()
            } else if tab == 1 {
                self.wsjtxRawLogs.removeAll()
            } else {
                self.clusterRawLogs.removeAll()
            }
        }
    }
}
