import Foundation
import CryptoKit
import Security

/// Thread-safe security storage & validation helper
final class AppVaultStore: @unchecked Sendable {
    static let shared = AppVaultStore()
    
    private let lock = NSLock()
    
    // Obfuscated salt: "AF_SEC_SALT_v51" ^ 0x5A
    private let sM: [UInt8] = [27, 28, 5, 9, 31, 25, 5, 9, 27, 22, 14, 5, 44, 111, 107]
    
    // Obfuscated target hash digest ^ 0xA5
    private let tM: [UInt8] = [
        150, 202, 183, 55, 189, 165, 99, 18, 203, 48, 240, 77, 18, 162, 5, 124,
        25, 192, 52, 169, 125, 119, 100, 88, 52, 167, 31, 200, 85, 169, 175, 173
    ]
    
    // Keychain service: "com.gecando.autofilter.auth" ^ 0x5C
    private let kS: [UInt8] = [63, 51, 49, 114, 59, 57, 63, 61, 50, 56, 51, 114, 61, 41, 40, 51, 58, 53, 48, 40, 57, 46, 114, 61, 41, 40, 52]
    
    // Keychain account: "auth_profile_token" ^ 0x5C
    private let kA: [UInt8] = [61, 41, 40, 52, 3, 44, 46, 51, 58, 53, 48, 57, 3, 40, 51, 55, 57, 50]
    
    // Keychain account for quota metrics: "auth_quota_metrics" ^ 0x5C
    private let kQ: [UInt8] = [61, 41, 40, 52, 3, 45, 41, 51, 40, 61, 3, 49, 57, 40, 46, 53, 63, 47]
    
    private init() {}
    
    private func getSalt() -> String {
        let b = sM.map { $0 ^ 0x5A }
        return String(decoding: b, as: UTF8.self)
    }
    
    private func getTarget() -> [UInt8] {
        return tM.map { $0 ^ 0xA5 }
    }
    
    private func getService() -> String {
        let b = kS.map { $0 ^ 0x5C }
        return String(decoding: b, as: UTF8.self)
    }
    
    private func getAccount() -> String {
        let b = kA.map { $0 ^ 0x5C }
        return String(decoding: b, as: UTF8.self)
    }
    
    private func getQuotaAccount() -> String {
        let b = kQ.map { $0 ^ 0x5C }
        return String(decoding: b, as: UTF8.self)
    }
    
    /// Verifies candidate string against the internal hash signature
    func verifyCandidate(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let salt = getSalt()
        let payload = "\(salt):\(trimmed):\(salt)"
        let digest = Array(SHA256.hash(data: Data(payload.utf8)))
        return digest == getTarget()
    }
    
    /// Checks if a valid activation token is stored in the Keychain
    func hasValidToken() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: getService(),
            kSecAttrAccount as String: getAccount(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return false
        }
        
        // Ensure stored token matches expected hash
        return Array(data) == getTarget()
    }
    
    /// Verifies candidate and toggles activation state in Keychain
    func toggleActivation(_ candidate: String) -> (didMatch: Bool, isNowUnlocked: Bool) {
        guard verifyCandidate(candidate) else { return (false, false) }
        
        lock.lock()
        defer { lock.unlock() }
        
        let service = getService()
        let account = getAccount()
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Check current Keychain state
        let checkQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let isCurrentlyActive = (SecItemCopyMatching(checkQuery as CFDictionary, &item) == errSecSuccess)
        
        if isCurrentlyActive {
            // Relock: Remove token from Keychain
            SecItemDelete(deleteQuery as CFDictionary)
            return (true, false)
        } else {
            // Unlock: Save token in Keychain
            SecItemDelete(deleteQuery as CFDictionary)
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: Data(getTarget()),
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let status = SecItemAdd(addQuery as CFDictionary, nil)
            return (true, status == errSecSuccess)
        }
    }
    
    // MARK: - Daily Quota Persistence (Max 60 Min & Max 3 Launches per Day)
    
    struct DailyQuotaRecord: Codable {
        var dayKey: String
        var launchCount: Int
        var usedSeconds: Int
        var lastTimestamp: TimeInterval
    }
    
    private func todayKey() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.timeZone = TimeZone.current
        return df.string(from: Date())
    }
    
    private func readQuotaRecord() -> DailyQuotaRecord? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: getService(),
            kSecAttrAccount as String: getQuotaAccount(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(DailyQuotaRecord.self, from: data)
    }
    
    private func writeQuotaRecord(_ record: DailyQuotaRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        let service = getService()
        let account = getQuotaAccount()
        
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
    
    /// Records an app launch and returns (allowed, remainingSeconds, currentLaunchCount)
    func checkAndRecordDailyLaunch(maxSeconds: Int = 3600, maxLaunches: Int = 3) -> (allowed: Bool, remainingSeconds: Int, launchCount: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date().timeIntervalSince1970
        let today = todayKey()
        
        guard var record = readQuotaRecord(), record.dayKey == today else {
            // New day or first launch
            let newRecord = DailyQuotaRecord(dayKey: today, launchCount: 1, usedSeconds: 0, lastTimestamp: now)
            writeQuotaRecord(newRecord)
            return (true, maxSeconds, 1)
        }
        
        // Anti-time tampering check: if system clock set back by > 5 minutes
        if now < (record.lastTimestamp - 300) {
            return (false, 0, record.launchCount)
        }
        
        record.launchCount += 1
        record.lastTimestamp = now
        
        if record.launchCount > maxLaunches {
            writeQuotaRecord(record)
            return (false, 0, record.launchCount)
        }
        
        if record.usedSeconds >= maxSeconds {
            writeQuotaRecord(record)
            return (false, 0, record.launchCount)
        }
        
        writeQuotaRecord(record)
        let remaining = max(0, maxSeconds - record.usedSeconds)
        return (true, remaining, record.launchCount)
    }
    
    /// Adds consumed seconds to today's quota
    func recordUsedSeconds(addSeconds: Int, maxSeconds: Int = 3600) -> (isStillValid: Bool, remainingSeconds: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date().timeIntervalSince1970
        let today = todayKey()
        
        var record = readQuotaRecord() ?? DailyQuotaRecord(dayKey: today, launchCount: 1, usedSeconds: 0, lastTimestamp: now)
        if record.dayKey != today {
            record = DailyQuotaRecord(dayKey: today, launchCount: 1, usedSeconds: 0, lastTimestamp: now)
        }
        
        record.usedSeconds += addSeconds
        record.lastTimestamp = now
        writeQuotaRecord(record)
        
        let remaining = max(0, maxSeconds - record.usedSeconds)
        let valid = (record.launchCount <= 3 && record.usedSeconds < maxSeconds)
        return (valid, remaining)
    }
}
