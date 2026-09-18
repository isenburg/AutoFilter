import SwiftUI
import StoreKit

public struct PurchaseView: View {
    @ObservedObject var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var isDe: Bool { LanguageManager.shared.isGerman }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 16) {
                if let appIcon = NSImage(named: "AppIcon") {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(14)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isDe ? "AutoFilter Vollversion" : "AutoFilter Pro Version")
                        .font(.title2.bold())
                    Text(isDe ? "Einmaliger Kauf für unbegrenzten Funkbetrieb" : "One-time purchase for unlimited amateur radio operation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Divider()
            
            // Trial Status Info
            if storeManager.isTrialExpired {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    Text(isDe
                        ? "Die 60-minütige Testphase dieser Sitzung ist abgelaufen. Filter und AutoQSO sind deaktiviert."
                        : "The 60-minute trial for this session has expired. Filters and AutoQSO are disabled.")
                        .font(.callout)
                        .foregroundColor(.primary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
                .padding(.horizontal)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .foregroundColor(.accentColor)
                    Text(isDe
                        ? "Verbleibende Testzeit dieser Sitzung: \(storeManager.formattedRemainingTime) Min."
                        : "Remaining trial time for this session: \(storeManager.formattedRemainingTime) min.")
                        .font(.callout)
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Benefits List
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(
                    icon: "line.3.horizontal.decrease.circle.fill",
                    color: .green,
                    title: isDe ? "Unbegrenzte Filterfunktionen" : "Unlimited Filter Engine",
                    subtitle: isDe ? "Dauerhafter Spot-Filter ohne 60-Minuten-Abschaltung" : "Continuous spot filtering without 60-minute timeout"
                )
                FeatureRow(
                    icon: "play.circle.fill",
                    color: .blue,
                    title: isDe ? "Volle AutoQSO-Automatisierung" : "Full AutoQSO Automation",
                    subtitle: isDe ? "Unterbrechungsfreies automatisches Anrufen von Stationen" : "Uninterrupted automated calling of target stations"
                )
                FeatureRow(
                    icon: "sparkles",
                    color: .orange,
                    title: isDe ? "Lebenslange Lizenz" : "Lifetime License",
                    subtitle: isDe ? "Einmalig bezahlen, kein Abonnement, alle Updates inklusive" : "Pay once, no subscription, all updates included"
                )
            }
            .padding(.horizontal)
            
            if let error = storeManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 14) {
                Button(isDe ? "Käufe wiederherstellen" : "Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
                .buttonStyle(.link)
                .disabled(storeManager.isPurchasing)
                
                Spacer()
                
                Button(isDe ? "Später" : "Later") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(storeManager.isPurchasing)
                
                Button(action: {
                    Task {
                        _ = await storeManager.purchase()
                    }
                }) {
                    HStack(spacing: 6) {
                        if storeManager.isPurchasing {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(storeManager.product?.displayPrice != nil
                            ? (isDe ? "Jetzt kaufen (\(storeManager.product!.displayPrice))" : "Buy Now (\(storeManager.product!.displayPrice))")
                            : (isDe ? "Jetzt freischalten" : "Unlock Now"))
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .keyboardShortcut(.defaultAction)
                .disabled(storeManager.isPurchasing)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(width: 520)
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
