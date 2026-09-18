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
    
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        remainingSeconds = StoreManager.defaultTrialDurationSeconds
        isTrialExpired = false
    }
    
    func setUnlocked() {
        lock.lock()
        defer { lock.unlock() }
        isUnlocked = true
        isTrialExpired = false
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
    @Published public private(set) var product: Product?
    @Published public private(set) var isPurchasing: Bool = false
    @Published public var errorMessage: String?
    
    // Model A: 60-Minute Session Trial
    @Published public private(set) var remainingSeconds: Int = defaultTrialDurationSeconds
    @Published public private(set) var isTrialExpiredState: Bool = false
    
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
    
    private init() {
        startSessionTimer()
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
    public func startSessionTimer() {
        timerTask?.cancel()
        storage.reset()
        remainingSeconds = Self.defaultTrialDurationSeconds
        isTrialExpiredState = false
        
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self = self else { break }
                
                let (shouldStop, currentSec, hasExpiredNow) = self.storage.tick()
                if shouldStop {
                    break
                }
                
                self.remainingSeconds = currentSec
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
