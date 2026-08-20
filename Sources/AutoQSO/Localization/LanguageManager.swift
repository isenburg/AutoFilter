import SwiftUI
import Combine

/// Unterstützte Sprachen in AutoQSO
public enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case de = "de"
    case en = "en"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .system:
            return "🌐 System (Standard / Default)"
        case .de:
            return "🇩🇪 Deutsch"
        case .en:
            return "🇬🇧 English"
        }
    }
}

/// Zentraler Manager für die Mehrsprachigkeit (Deutsch & Englisch) in AutoQSO
public class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()
    
    private let userDefaultsKey = "appLanguage"
    
    @Published public var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: userDefaultsKey)
        }
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AppLanguage.system.rawValue
        self.selectedLanguage = AppLanguage(rawValue: saved) ?? .system
    }
    
    /// Gibt die effektiv aktive Sprache (de oder en) zurück
    public var effectiveLanguage: AppLanguage {
        switch selectedLanguage {
        case .de:
            return .de
        case .en:
            return .en
        case .system:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if preferred.hasPrefix("de") {
                return .de
            } else {
                return .en
            }
        }
    }
    
    /// Prüft, ob Deutsch aktuell aktiv ist
    public var isGerman: Bool {
        effectiveLanguage == .de
    }
    
    /// Übersetzt einen Schlüssel anhand des aktiven Wörterbuchs
    public func tr(_ key: String, _ args: CVarArg...) -> String {
        let lang = effectiveLanguage
        let dict = (lang == .de) ? LocalizationDictionary.german : LocalizationDictionary.english
        
        let format = dict[key] ?? LocalizationDictionary.german[key] ?? key
        if args.isEmpty {
            return format
        }
        return String(format: format, arguments: args)
    }
}

/// Globale Kurzfunktion für Lokalisierung in allen Views
public func L(_ key: String, _ args: CVarArg...) -> String {
    if args.isEmpty {
        return LanguageManager.shared.tr(key)
    }
    let manager = LanguageManager.shared
    let lang = manager.effectiveLanguage
    let dict = (lang == .de) ? LocalizationDictionary.german : LocalizationDictionary.english
    let format = dict[key] ?? LocalizationDictionary.german[key] ?? key
    return String(format: format, arguments: args)
}
