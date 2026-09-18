import Observation
import SwiftUI
import Combine

/// Unterstützte Sprachen in AutoFilter
public enum AppLanguage: String, CaseIterable, Identifiable {
    case de = "de"
    case en = "en"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .de:
            return "🇩🇪 Deutsch"
        case .en:
            return "🇬🇧 English"
        }
    }
}

/// Zentraler Manager für die Mehrsprachigkeit (Deutsch & Englisch) in AutoFilter
@Observable
public class LanguageManager {
    public static let shared = LanguageManager()
    
    private let userDefaultsKey = "appLanguage"
    
    public var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: userDefaultsKey)
        }
    }
    
    private static func defaultLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return preferred.hasPrefix("de") ? .de : .en
    }
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: userDefaultsKey)
        if let saved = saved, let lang = AppLanguage(rawValue: saved) {
            self.selectedLanguage = lang
        } else {
            let def = LanguageManager.defaultLanguage()
            self.selectedLanguage = def
            UserDefaults.standard.set(def.rawValue, forKey: userDefaultsKey)
        }
    }
    
    /// Lädt die Spracheinstellung bei Datenbank-Aktualisierungen neu aus UserDefaults
    public func reloadLanguageFromDefaults() {
        let saved = UserDefaults.standard.string(forKey: userDefaultsKey)
        let newLang: AppLanguage
        if let saved = saved, let lang = AppLanguage(rawValue: saved) {
            newLang = lang
        } else {
            newLang = LanguageManager.defaultLanguage()
        }
        if selectedLanguage != newLang {
            selectedLanguage = newLang
        }
    }
    
    /// Gibt die effektiv aktive Sprache (de oder en) zurück
    public var effectiveLanguage: AppLanguage {
        selectedLanguage
    }
    
    /// Prüft, ob Deutsch aktuell aktiv ist
    public var isGerman: Bool {
        selectedLanguage == .de
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
