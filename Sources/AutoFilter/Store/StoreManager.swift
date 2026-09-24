import Foundation
import StoreKit
import SwiftUI

private final class TrialStateStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var isUnlocked: Bool = false
    private var isTrialExpired: Bool = false
    private var remainingSeconds: Int = StoreManager.defaultTrialDurationSeconds
    
    func getIsTrialExpired() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isTrialExpired
    }
    
    func getIsUnlocked() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isUnlocked
    }
    
    func reset(initialSeconds: Int = StoreManager.defaultTrialDurationSeconds) {
        lock.lock()
        defer { lock.unlock() }
        remainingSeconds = initialSeconds
        isTrialExpired = (initialSeconds <= 0)
    }
    
    func setExpired() {
        lock.lock()
        defer { lock.unlock() }
        isTrialExpired = true
        remainingSeconds = 0
    }
    
    func setUnlocked() {
        lock.lock()
        defer { lock.unlock() }
        isUnlocked = true
        isTrialExpired = false
    }
    
    func setLocked() {
        lock.lock()
        defer { lock.unlock() }
        isUnlocked = false
        isTrialExpired = false
        remainingSeconds = StoreManager.defaultTrialDurationSeconds
    }
    
    func tick() -> (shouldStop: Bool, currentSec: Int, hasExpiredNow: Bool) {
        lock.lock()
        defer { lock.unlock() }
        
        if isUnlocked {
            isTrialExpired = false
            return (true, remainingSeconds, false)
        }
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }
        let current = remainingSeconds
        var expired = false
        if remainingSeconds <= 0 && !isTrialExpired {
            isTrialExpired = true
            expired = true
        }
        return (false, current, expired)
    }
}

@MainActor
public final class StoreManager: ObservableObject {
    nonisolated public static let shared: StoreManager = MainActor.assumeIsolated { StoreManager() }
    
    nonisolated public static let productID = "com.gecando.autofilter.pro"
    nonisolated public static let defaultTrialDurationSeconds: Int = 3600 // 60 minutes
    
    private let storage = TrialStateStorage()
    
    // License state
    @Published public private(set) var isUnlocked: Bool = false
    @Published public private(set) var licenseInfoText: String = "Testversion (60 Min. Sitzung)"
    @Published public private(set) var product: Product?
    @Published public private(set) var isPurchasing: Bool = false
    @Published public var errorMessage: String?
    
    // Model A: Daily Quota Trial (60 Minutes & 3 Launches per Day)
    @Published public private(set) var remainingSeconds: Int = defaultTrialDurationSeconds
    @Published public private(set) var isTrialExpiredState: Bool = false
    @Published public private(set) var dailyLaunchCount: Int = 1
    
    // Nonisolated thread-safe getter for DecodeViewModel
    nonisolated public var isTrialExpired: Bool {
        storage.getIsTrialExpired()
    }
    
    nonisolated public var isUnlockedSafe: Bool {
        storage.getIsUnlocked()
    }
    
    // UI trigger
    @Published public var showPurchaseSheet: Bool = false
    
    nonisolated public func triggerPurchasePrompt() {
        Task { @MainActor in
            self.showPurchaseSheet = true
        }
    }
    
    // Callback to notify ViewModel when trial expires
    public var onTrialExpired: (@MainActor () -> Void)?
    
    private var timerTask: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?
    
    @discardableResult
    nonisolated public func processInputToken(_ rawInput: String) -> Bool {
        let (didMatch, isNowUnlocked) = AppVaultStore.shared.toggleActivation(rawInput)
        guard didMatch else { return false }
        
        if isNowUnlocked {
            storage.setUnlocked()
            Task { @MainActor in
                self.isUnlocked = true
                self.remainingSeconds = 0
                self.isTrialExpiredState = false
                self.licenseInfoText = "Promo-Lizenz (Autorisiert)"
                self.timerTask?.cancel()
                self.timerTask = nil
                self.showPurchaseSheet = false
            }
        } else {
            storage.setLocked()
            Task { @MainActor in
                self.isUnlocked = false
                self.remainingSeconds = Self.defaultTrialDurationSeconds
                self.isTrialExpiredState = false
                self.licenseInfoText = "Testversion (60 Min. Sitzung)"
                self.startSessionTimer()
            }
        }
        return true
    }
    
    private init() {
        if AppVaultStore.shared.hasValidToken() {
            storage.setUnlocked()
            self.isUnlocked = true
            self.remainingSeconds = 0
            self.isTrialExpiredState = false
            self.licenseInfoText = "Promo-Lizenz (Autorisiert)"
        } else {
            let quota = AppVaultStore.shared.checkAndRecordDailyLaunch(maxSeconds: Self.defaultTrialDurationSeconds, maxLaunches: 3)
            self.dailyLaunchCount = quota.launchCount
            if !quota.allowed {
                storage.setExpired()
                self.remainingSeconds = 0
                self.isTrialExpiredState = true
                let isDe = LanguageManager.shared.isGerman
                self.licenseInfoText = quota.launchCount > 3
                    ? (isDe ? "Tageslimit (3/3 Starts verbraucht)" : "Daily limit (3/3 launches used)")
                    : (isDe ? "Tageslimit (60 Min. abgelaufen)" : "Daily limit (60 min expired)")
            } else {
                startSessionTimer(initialSeconds: quota.remainingSeconds)
            }
        }
        listenForTransactions()
        Task {
            await checkCurrentEntitlements()
            await loadProducts()
        }
    }
    
    deinit {
        timerTask?.cancel()
        updatesTask?.cancel()
    }
    
    // MARK: - Session Timer
    public func startSessionTimer(initialSeconds: Int? = nil) {
        timerTask?.cancel()
        let secs = initialSeconds ?? Self.defaultTrialDurationSeconds
        storage.reset(initialSeconds: secs)
        remainingSeconds = secs
        isTrialExpiredState = (secs <= 0)
        if secs <= 0 {
            return
        }
        
        timerTask = Task { [weak self] in
            var elapsedSeconds = 0
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self else { break }
                
                let (shouldStop, currentSec, hasExpiredNow) = self.storage.tick()
                if shouldStop {
                    break
                }
                
                self.remainingSeconds = currentSec
                elapsedSeconds += 1
                
                // Flush consumed time to Keychain every 10 seconds
                if elapsedSeconds >= 10 {
                    elapsedSeconds = 0
                    let (stillValid, rem) = AppVaultStore.shared.recordUsedSeconds(addSeconds: 10, maxSeconds: Self.defaultTrialDurationSeconds)
                    if !stillValid || rem <= 0 {
                        self.isTrialExpiredState = true
                        self.showPurchaseSheet = true
                        self.onTrialExpired?()
                        break
                    }
                }
                
                if hasExpiredNow {
                    self.isTrialExpiredState = true
                    self.showPurchaseSheet = true
                    self.onTrialExpired?()
                }
            }
        }
    }
    
    public var formattedRemainingTime: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    // MARK: - StoreKit 2
    public func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            self.product = products.first
        } catch {
            print("StoreManager: Failed to load product: \(error)")
        }
    }
    
    public func checkCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Self.productID && transaction.revocationDate == nil {
                    storage.setUnlocked()
                    self.isUnlocked = true
                    self.isTrialExpiredState = false
                    self.timerTask?.cancel()
                    let dStr = transaction.originalPurchaseDate.formatted(date: .abbreviated, time: .omitted)
                    self.licenseInfoText = "Mac App Store (Tx #\(transaction.id), \(dStr))"
                    return
                }
            }
        }
    }
    
    private func listenForTransactions() {
        updatesTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.checkCurrentEntitlements()
                }
            }
        }
    }
    
    public func purchase() async -> Bool {
        guard let product = product else {
            await loadProducts()
            guard let product = product else {
                self.errorMessage = LanguageManager.shared.isGerman
                    ? "Produkt im App Store momentan nicht erreichbar."
                    : "Product not available in App Store."
                return false
            }
            return await doPurchase(product: product)
        }
        return await doPurchase(product: product)
    }
    
    private func doPurchase(product: Product) async -> Bool {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    storage.setUnlocked()
                    self.isUnlocked = true
                    self.isTrialExpiredState = false
                    self.showPurchaseSheet = false
                    self.timerTask?.cancel()
                    return true
                } else {
                    self.errorMessage = LanguageManager.shared.isGerman
                        ? "Transaktion konnte nicht verifiziert werden."
                        : "Transaction could not be verified."
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                self.errorMessage = LanguageManager.shared.isGerman
                    ? "Kauf wird von Apple geprüft..."
                    : "Purchase is pending approval..."
                return false
            @unknown default:
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func restorePurchases() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        
        do {
            try await AppStore.sync()
            await checkCurrentEntitlements()
            if isUnlocked {
                showPurchaseSheet = false
            } else {
                errorMessage = LanguageManager.shared.isGerman
                    ? "Kein vorheriger Kauf für diesen Apple-Account gefunden."
                    : "No previous purchase found for this Apple account."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
