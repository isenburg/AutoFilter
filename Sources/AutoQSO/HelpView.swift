import SwiftUI
import AppKit

enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Übersicht"
    case quickstart = "Quickstart"
    case toolbar = "Toolbar & Bedienung"
    case wsjtx = "WSJT-X Setup"
    case triggers = "Auto QSO Triggers"
    case filterProfiles = "Filter-Profile & Presets"
    case filterLogic = "Filter-Logik & Pipeline"
    case cluster = "DX Cluster"
    case telnet = "Telnet Server"
    case propagationMap = "Ausbreitungskarte & Grid-Map"
    case compactMode = "Kompaktmodus"
    case logbook = "Logbuch & Sync"
    case storage = "Speicherort & iCloud"
    case appearance = "Ansicht & Farbschema"
    case support = "Support"
    case disclaimer = "Rechtlicher Hinweis"
    case changelog = "Changelog"
    case copyright = "Copyright & Lizenz"
    
    var id: String { rawValue }
    
    var title: String {
        let isDe = LanguageManager.shared.isGerman
        switch self {
        case .overview: return isDe ? "Übersicht" : "Overview"
        case .quickstart: return isDe ? "Quickstart" : "Quickstart"
        case .toolbar: return isDe ? "Toolbar & Bedienung" : "Toolbar & Controls"
        case .wsjtx: return "WSJT-X Setup"
        case .triggers: return "Auto QSO Triggers"
        case .filterProfiles: return isDe ? "Filter-Profile & Presets" : "Filter Profiles & Presets"
        case .filterLogic: return isDe ? "Filter-Logik & Pipeline" : "Filter Logic & Pipeline"
        case .cluster: return "DX Cluster"
        case .telnet: return "Telnet Server"
        case .propagationMap: return isDe ? "Ausbreitungskarte & Grid-Map" : "Propagation & Grid Map"
        case .compactMode: return isDe ? "Kompaktmodus" : "Compact Mode"
        case .logbook: return isDe ? "Logbuch & Sync" : "Logbook & Sync"
        case .storage: return isDe ? "Speicherort & iCloud" : "Storage & iCloud"
        case .appearance: return isDe ? "Ansicht & Farbschema" : "Appearance & Theme"
        case .support: return "Support"
        case .disclaimer: return isDe ? "Rechtlicher Hinweis" : "Legal Disclaimer"
        case .changelog: return "Changelog"
        case .copyright: return isDe ? "Copyright & Lizenz" : "Copyright & License"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .quickstart: return "bolt.circle"
        case .toolbar: return "command"
        case .wsjtx: return "antenna.radiowaves.left.and.right"
        case .triggers: return "bolt.horizontal"
        case .filterProfiles: return "bookmark.circle.fill"
        case .filterLogic: return "slider.horizontal.3"
        case .cluster: return "list.bullet.rectangle.portrait"
        case .telnet: return "terminal"
        case .propagationMap: return "map"
        case .compactMode: return "rectangle.compress.vertical"
        case .logbook: return "book.closed"
        case .storage: return "folder.fill"
        case .appearance: return "paintpalette"
        case .support: return "lifepreserver"
        case .disclaimer: return "exclamationmark.triangle"
        case .changelog: return "clock"
        case .copyright: return "c.circle"
        }
    }
    
    /// Umfassende Such-Keywords für die Hilfethemen (DE & EN)
    var searchKeywords: [String] {
        switch self {
        case .overview:
            return ["übersicht", "overview", "system", "dx-filter", "auto qso", "wsjt-x", "wsjtx", "ft8", "ft4", "sqlite", "most wanted", "entfernung", "distance", "telnet", "farbschema", "theme", "hauptfunktionen", "features", "filter-pipeline", "whitelist", "vip-pass"]
        case .quickstart:
            return ["quickstart", "schnellstart", "mindesteinstellungen", "minimum setup", "schritte", "steps", "rufzeichen", "callsign", "qth", "locator", "wsjt-x udp", "logbuch", "logbook sync", "cluster", "c1", "c2", "c3", "setup", "anleitung", "guide"]
        case .toolbar:
            return ["toolbar", "bedienung", "controls", "buttons", "verbindungs-sidebar", "auto transmit", "auto on", "auto off", "cq only", "freeze", "pause", "suche", "search", "suchfeld", "logbuch", "sortierung", "sort order", "tabelle löschen", "clear", "ausbreitungskarte", "kompaktmodus", "einstellungen", "settings", "filter-sidebar", "klick", "click", "doppelklick", "shortcuts", "tastatur", "maus"]
        case .wsjtx:
            return ["wsjt-x", "wsjtx", "setup", "konfiguration", "reporting", "udp server", "224.0.0.1", "2237", "multicast", "unicast", "127.0.0.1", "accept udp requests", "prompt me to log", "bandwechsel", "ft8", "ft4", "rig", "audio", "ports", "ip-adresse", "bridge"]
        case .triggers:
            return ["triggers", "auto qso triggers", "auslöser", "cq anruf", "73", "rr73", "rrr", "auto-antwort", "tx cycle", "sendezyklus", "timeout", "cooldown", "priorität", "priority", "most wanted trigger", "sende-engine", "transmit", "automatisierung"]
        case .filterProfiles:
            return ["filter-profile", "filter profiles", "presets", "profile", "vorlagen", "system-vorlagen", "smart recall", "allround", "dxpedition", "contest", "grid hunting", "phone", "ssb", "dirty indicator", "auto-band", "auto-mode", "export", "import"]
        case .filterLogic:
            return ["filter-logik", "filter logic", "nachrichten-filter", "message filter", "boolean", "boolesch", "textfilter", "pipeline", "first-match", "whitelist", "blacklist", "vip pass", "ausnahmen", "exceptions", "presets", "reorder", "sortierbar", "bandfilter", "modusfilter", "kontinente", "continents", "dxcc", "spotter", "cq-zone", "itu-zone", "snr", "signal-to-noise", "entfernungsfilter", "azimut", "bearing", "peilung", "lotw-user", "worked before", "gearbeitet"]
        case .cluster:
            return ["cluster", "dx cluster", "upstream", "c1", "c2", "c3", "telnet", "reversebeacon", "rbn", "ve7cc", "k3lr", "spots", "dx spots", "reconnect", "status", "clustermanager", "sh/dx", "dx cluster server", "login"]
        case .telnet:
            return ["telnet", "telnet server", "port 8000", "externe logger", "external loggers", "n1mm", "log4om", "rumlogng", "macloggerdx", "qdatastream", "decodes weiterleiten", "broadcast", "spotting", "terminal", "login", "guest"]
        case .propagationMap:
            return ["ausbreitungskarte", "propagation map", "grid-map", "karte", "3d globus", "globe", "maidenhead", "gitter", "subsquare", "heatmap", "bänder", "bands", "farben", "cluster", "160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "aktives qso", "great circle", "großkreis", "day night terminator", "sonnenstand"]
        case .compactMode:
            return ["kompaktmodus", "compact mode", "mini-fenster", "minimal", "toolbar", "float on top", "schwebend", "platzsparend", "status", "reduzieren", "ansicht", "layout"]
        case .logbook:
            return ["logbuch", "logbook", "sync", "lotw", "logbook of the world", "rumlog", "rumlogng", "qrz", "qrz.com", "adif", "import", "sqlite", "gearbeitet", "worked before", "band-statistik", "dupe check", "abgleich", "qso history"]
        case .storage:
            return ["storage", "speicherort", "icloud", "icloud drive", "dateipfade", "paths", "autoqso.sqlite", "backup", "datenbank", "sync über geräte", "permissions", "berechtigungen", "app sandbox", "custom folder"]
        case .appearance:
            return ["appearance", "ansicht", "farbschema", "theme", "dark mode", "light mode", "dunkelmodus", "hell", "system", "schriftgröße", "font size", "kontrast", "tabellenzeilen", "custom colors", "farben", "look and feel"]
        case .support:
            return ["support", "hilfe", "kontakt", "contact", "github", "issues", "bug report", "fehler melden", "feature request", "faq", "community", "mail", "entwickler"]
        case .disclaimer:
            return ["rechtlicher hinweis", "legal disclaimer", "amateurfunk", "iaru", "lizenzbestimmungen", "ham radio regulations", "unbeaufsichtigter sendebetrieb", "unattended operation", "eigenverantwortung", "remote", "cept"]
        case .changelog:
            return ["changelog", "versionen", "versions", "release notes", "build", "neuigkeiten", "updates", "historie", "whats new", "improvements", "fixes"]
        case .copyright:
            return ["copyright", "lizenz", "license", "mit", "open source", "autor", "author", "entwickler", "developer", "credits", "third-party", "danksagung", "afis", "afx"]
        }
    }

    func matches(query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return true }
        if rawValue.lowercased().contains(q) { return true }
        if title.lowercased().contains(q) { return true }
        return searchKeywords.contains { $0.lowercased().contains(q) }
    }
}

struct HelpView: View {
    private var langManager = LanguageManager.shared
    @Environment(\.openWindow) private var openWindow
    @State private var selectedSection: HelpSection = .overview
    @State private var searchText = ""
    
    private var isDe: Bool { langManager.isGerman }
    
    private var filteredSections: [HelpSection] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return HelpSection.allCases
        }
        return HelpSection.allCases.filter { $0.matches(query: trimmed) }
    }
    
    private func openSettings(to section: SettingsSection? = nil) {
        if let section = section {
            UserDefaults.standard.set(section.rawValue, forKey: "settingsSelectedSection")
            NotificationCenter.default.post(name: NSNotification.Name("OpenSettingsSection"), object: section.rawValue)
        }
        openWindow(id: "settings")
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NotificationCenter.default.post(name: NSNotification.Name("OpenSettingsWindow"), object: nil)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Non-collapsible Left Sidebar
            VStack(alignment: .leading, spacing: 4) {
                // Search Input Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 11))
                    TextField(isDe ? "Hilfe durchsuchen..." : "Search help topics...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 2)
                
                if filteredSections.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(isDe ? "Keine Treffer" : "No matches")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(isDe ? "Suche leeren" : "Clear") {
                            searchText = ""
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    List(filteredSections, selection: $selectedSection) { section in
                        HStack(spacing: 8) {
                            Image(systemName: section.icon)
                                .foregroundColor(selectedSection == section ? .accentColor : .secondary)
                                .frame(width: 18)
                            Text(section.title)
                                .font(.body)
                            Spacer()
                        }
                        .tag(section)
                    }
                    .listStyle(.sidebar)
                }
                
                Spacer(minLength: 0)
                
                Divider()
                
                // Footer in Sidebar
                VStack(alignment: .leading, spacing: 2) {
                    Text("AutoQSO v\(APP_VERSION)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("Build \(APP_BUILD_NUMBER)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
            .frame(width: 245)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content View
            ScrollView {
                if filteredSections.isEmpty {
                    VStack(spacing: 12) {
                        Spacer(minLength: 40)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary)
                        Text(isDe ? "Keine passenden Hilfethemen für „\(searchText)“" : "No matching help topics for “\(searchText)”")
                            .font(.title3)
                            .bold()
                        Text(isDe ? "Versuche Begriffe wie Quickstart, WSJT-X, Filter, Cluster, Logbuch, Karte, Triggers oder Shortcuts." : "Try topics like Quickstart, WSJT-X, Filters, Cluster, Logbook, Map, Triggers, or Shortcuts.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(isDe ? "Suche zurücksetzen" : "Reset Search") {
                            searchText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 6)
                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(30)
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkle.magnifyingglass")
                                    .foregroundColor(.accentColor)
                                Text(isDe ? "Themen gefiltert nach „\(searchText)“ (\(filteredSections.count) Treffer)" : "Topics filtered by “\(searchText)” (\(filteredSections.count) matches)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: { searchText = "" }) {
                                    Text(isDe ? "Alle anzeigen" : "Show all")
                                        .font(.caption2)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.08))
                            .cornerRadius(6)
                        }
                        detailView(for: selectedSection)
                    }
                    .padding(22)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 890, height: 620)
        .onChange(of: searchText) { _, _ in
            let matching = filteredSections
            if !matching.isEmpty && !matching.contains(selectedSection) {
                if let first = matching.first {
                    selectedSection = first
                }
            }
        }
    }

    @ViewBuilder
    private func detailView(for section: HelpSection) -> some View {
        let isDe = langManager.isGerman
        switch section {
        case .overview:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "System-Übersicht" : "System Overview")
                    .font(.title2)
                    .bold()
                Text(isDe ? 
                    "AutoQSO ist eine macOS-Anwendung für Funkamateure. Die **Hauptfunktion ist der DX-Filter** zur intelligenten Auswertung, Klassifizierung und Filterung von Spots und Dekodierungen. **Für WSJT-X steht die automatisierte Auto QSO Sende-Engine** zur Verfügung." :
                    "AutoQSO is a macOS application for amateur radio operators. The **main feature is the DX Filter** for intelligent evaluation, classification, and filtering of spots and decodes. **For WSJT-X, the automated Auto QSO Transmit Engine** is available.")
                    .font(.body)
                
                // Quickstart Callout
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isDe ? "Neu bei AutoQSO? Schnellstart in 4 Schritten:" : "New to AutoQSO? Quickstart in 4 steps:")
                            .font(.headline)
                        Text(isDe ? "Erfahre, welche Mindesteinstellungen (Rufzeichen, QTH, WSJT-X, Logbuch) du für den Betrieb benötigst." : "Learn what minimum settings (callsign, QTH, WSJT-X, logbook) you need for operation.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(isDe ? "Quickstart öffnen" : "Open Quickstart") {
                        selectedSection = .quickstart
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(12)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                
                Text(isDe ? "Hauptfunktionen:" : "Key Features:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    bullet(isDe ? "DX-Filter (Hauptfunktion): Intelligente Auswertung, Klassifizierung & Weiterleitung von DX-Spots & Decodes" : "DX Filter (Main Feature): Intelligent evaluation, classification & forwarding of DX spots & decodes")
                    bullet(isDe ? "Sortierbare First-Match Filter-Pipeline: Frei reorderbare Filtersektionen mit sofortiger Whitelist-Ausnahme-Logik (VIP-Pass) & Presets" : "Sortable First-Match Filter Pipeline: Fully reorderable filter sections with instant whitelist exception logic (VIP pass) & presets")
                    bullet(isDe ? "Auto QSO für WSJT-X: Automatisierte Sende-Engine für FT8 & FT4" : "Auto QSO for WSJT-X: Automated transmit engine for FT8 & FT4")
                    bullet(isDe ? "Prüfung gegen SQLite-Logbuch (bereits auf Band gearbeitet)" : "Verification against SQLite logbook (already worked on band)")
                    bullet(isDe ? "Detektieren von CQ, 73, RR73 und RRR Decodes" : "Detection of CQ, 73, RR73, and RRR decodes")
                    bullet(isDe ? "Top 100 Most Wanted DXCC – Rote Hervorhebung (🔥) & Priorität" : "Top 100 Most Wanted DXCC – Red highlight (🔥) & priority")
                    bullet(isDe ? "Maidenhead Locator → km Entfernungsberechnung" : "Maidenhead Locator → km distance calculation")
                    bullet(isDe ? "Gesondertes Most-Wanted-Panel (höhenverstellbar via VSplitView) unter der Tabelle" : "Dedicated Most-Wanted panel (resizable via VSplitView) below the table")
                    bullet(isDe ? "DX Cluster Slots (C1, C2, C3) per Dropdown-Picker und Live-Status" : "DX Cluster slots (C1, C2, C3) via dropdown pickers and live status")
                    bullet(isDe ? "Laufender Telnet-Server zur Spotting-Weiterleitung an externe Programme" : "Built-in Telnet server for spot forwarding to external loggers")
                    bullet(isDe ? "Umschaltbare Log-Diagnose (System, WSJT-X-Rohdaten, Cluster-Spots)" : "Switchable log diagnosis (System, WSJT-X raw data, Cluster spots)")
                    bullet(isDe ? "Abkoppelbare Log-Konsole als eigenständiges, positionierbares Fenster" : "Detachable log console as a standalone, positionable window")
                    bullet(isDe ? "Chronologische Sortierung wählbar (Neueste oben oder unten)" : "Chronological sorting selectable (Newest on top or bottom)")
                    bullet(isDe ? "Unterstützung von Hell-, Dunkel- und System-Farbschemata" : "Support for Light, Dark, and System color schemes")
                }
            }
            
        case .quickstart:
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isDe ? "Quickstart – Mindesteinstellungen" : "Quickstart – Minimum Setup")
                            .font(.title2)
                            .bold()
                        Text(isDe ? "Vier grundlegende Schritte zum sofortigen Funkbetrieb mit AutoQSO." : "Four basic steps for immediate radio operation with AutoQSO.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { openSettings() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                            Text(isDe ? "Einstellungen öffnen ⚙️" : "Open Settings ⚙️")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // 1. Eigenes Rufzeichen & QTH
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(isDe ? "1. Rufzeichen & Heimat-QTH" : "1. Callsign & Home QTH", systemImage: "location.circle.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .telnet) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text(isDe ? "Rufzeichen" : "Callsign")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { openSettings(to: .qth) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("QTH")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(isDe ? "Hilfe" : "Help") {
                            selectedSection = .propagationMap
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text(isDe ? 
                        "• **Eigenes Rufzeichen**: Trage dein Rufzeichen unter **Einstellungen (⚙️) -> Telnet Server** (*Rufzeichen für Login*) ein. Es wird für Cluster-Verbindungen und den integrierten Telnet-Server genutzt." :
                        "• **Callsign**: Enter your callsign under **Settings (⚙️) -> Telnet Server** (*Callsign for login*). It is used for cluster logins and the built-in Telnet server.")
                        .font(.subheadline)
                    Text(isDe ? 
                        "• **Grid-Locator (Heimat-QTH)**: Öffne **Einstellungen (⚙️) -> Eigenes QTH (Maidenhead)** und trage deinen 4- bis 8-stelligen Locator ein (z. B. `JO31AA24`), oder nutze die interaktive Karte mit Drop-Pin (🗺️). Dies ermöglicht die präzise Entfernungs- und Peilungsberechnung zu allen Stationen." :
                        "• **Grid Locator (Home QTH)**: Open **Settings (⚙️) -> Home QTH (Maidenhead)** and enter your 4- to 8-character locator (e.g. `JO31AA24`), or use the interactive map with drop-pin (🗺️). This enables accurate bearing and distance calculations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                
                // 2. WSJT-X Setup
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(isDe ? "2. WSJT-X UDP-Verbindung (Rx & Auto TX)" : "2. WSJT-X UDP Connection (Rx & Auto TX)", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .udp) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text(isDe ? "UDP-Setup" : "UDP Setup")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(isDe ? "WSJT-X Hilfe" : "WSJT-X Guide") {
                            selectedSection = .wsjtx
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text(isDe ? 
                        "• **Zweck**: Empfängt Live-Dekodierungen (FT8/FT4) und sendet automatische Antwortkommandos (Auto QSO)." :
                        "• **Purpose**: Receives live decodes (FT8/FT4) and sends automated reply commands (Auto QSO).")
                        .font(.subheadline)
                    Text(isDe ? 
                        "• **Einstellung in WSJT-X**: Öffne in WSJT-X **Settings -> Reporting** und aktiviere:\n  1. `Prompt me to log QSO` [x]\n  2. `Accept UDP requests` [x]\n  3. `UDP Server Address: 224.0.0.1` (Multicast) oder `127.0.0.1` (Unicast)\n  4. `UDP Server Port: 2237`" :
                        "• **Setup in WSJT-X**: In WSJT-X open **Settings -> Reporting** and check:\n  1. `Prompt me to log QSO` [x]\n  2. `Accept UDP requests` [x]\n  3. `UDP Server Address: 224.0.0.1` (Multicast) or `127.0.0.1` (Unicast)\n  4. `UDP Server Port: 2237`")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                
                // 3. Logbuch-Sync
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(isDe ? "3. Logbuch-Sync (RUMlog / LoTW / QRZ)" : "3. Logbook Sync (RUMlog / LoTW / QRZ)", systemImage: "book.closed.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .sync) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text(isDe ? "Sync-Setup" : "Sync Setup")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(isDe ? "Hilfe" : "Help") {
                            selectedSection = .logbook
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text(isDe ? 
                        "• **Zweck**: Gleicht eingehende Stationen in Echtzeit mit bereits getätigten QSOs auf dem Band ab, verhindert Doppel-QSOs und markiert ungearbeitete Länder/Grids farbig." :
                        "• **Purpose**: Cross-references incoming stations in real-time with already worked QSOs on the band, prevents duplicate QSOs, and highlights new DXCCs/grids.")
                        .font(.subheadline)
                    Text(isDe ? 
                        "• **Einstellung**: Öffne **Einstellungen (⚙️) -> Logbuch-Sync**, wähle deine Quelle (**RUMlogNG**, **LoTW** oder **QRZ.com**) und starte den Sync (oder lade ein bestehendes Logbuch über *ADIF-Datei importieren* hoch)." :
                        "• **Setup**: Open **Settings (⚙️) -> Logbook Sync**, choose your source (**RUMlogNG**, **LoTW**, or **QRZ.com**) and start the sync (or upload an existing logbook via *Import ADIF File*).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
                
                // 4. DX Cluster & Filter
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(isDe ? "4. DX Cluster & Filter (Optional)" : "4. DX Cluster & Filters (Optional)", systemImage: "list.bullet.rectangle.portrait.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .cluster) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text(isDe ? "Cluster-Setup" : "Cluster Setup")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(isDe ? "Hilfe" : "Help") {
                            selectedSection = .cluster
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text(isDe ? 
                        "• **Zweck**: Paralleler Empfang weltweiter DX-Spots über bis zu drei Cluster (C1, C2, C3) zur Live-Ausbreitungsanalyse." :
                        "• **Purpose**: Parallel reception of worldwide DX spots via up to three clusters (C1, C2, C3) for live propagation analysis.")
                        .font(.subheadline)
                    Text(isDe ? 
                        "• **Einstellung**: Wähle in der linken Seitenleiste oder unter **Einstellungen (⚙️) -> DX Cluster** deine gewünschten Cluster per Dropdown aus." :
                        "• **Setup**: Select your preferred clusters via the dropdown menus in the left sidebar or under **Settings (⚙️) -> DX Cluster**.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
            }
            
        case .toolbar:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Toolbar & Bedienung" : "Toolbar & Controls")
                    .font(.title2)
                    .bold()
                Text(isDe ? "Hier findest du eine Übersicht über alle Steuerungselemente und Interaktionen in AutoQSO." : "Here you will find an overview of all controls and interactions in AutoQSO.")
                    .font(.body)
                
                toolbarIllustrationCard(isDe: isDe)
                
                Text(isDe ? "Bedienelemente der Toolbar:" : "Toolbar Controls:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    iconBullet(icon: "sidebar.left", text: isDe ? "**Verbindungs-Sidebar**: Blendet die linke Status- und Konfigurations-Seitenleiste ein oder aus." : "**Connection Sidebar**: Toggles the left status and connection sidebar.")
                    iconBullet(icon: "play.circle", text: isDe ? "**Auto Transmit Toggle (Auto ON / Auto OFF)**: Aktiviert oder deaktiviert die automatische Sende-Engine. Ist in den Auto Mode Optionen „Nur Stationen anrufen, die CQ rufen“ aktiv, wird der Button kompakt zweizeilig als **Auto ON / CQ Only** dargestellt." : "**Auto Transmit Toggle (Auto ON / Auto OFF)**: Activates or deactivates the automated transmit engine. If “Only call stations calling CQ” is active in settings, the button dynamically displays **Auto ON / CQ Only** on two lines.")
                    iconBullet(icon: "pause.circle", text: isDe ? "**Freeze / Pause Toggle**: Friert die Ansicht der Dekodiertabelle & Logs mit einem statischen Snapshot ein (Auto-Scroll aus). Hintergrunddaten werden weiter empfangen. Erneuter Klick schaltet zurück auf Live-Scrollen." : "**Freeze / Pause Toggle**: Freezes the decode table and logs with a static snapshot (auto-scroll off). Incoming data continues to be received in the background.")
                    iconBullet(icon: "magnifyingglass", text: isDe ? "**Echtzeit-Suchfeld**: Ermöglicht das sofortige Durchsuchen der Tabelle oder Logs nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text – sowohl im Live- als auch im Freeze-Modus." : "**Real-Time Search Field**: Instantly filters the table or logs by callsign, country, spotter, grid locator, or message text.")
                    iconBullet(icon: "book", text: isDe ? "**Logbuch**: Öffnet das LoTW/QRZ-Logbuchfenster zur Ansicht der getätigten QSOs." : "**Logbook**: Opens the logbook window to view worked QSOs.")
                    iconBullet(icon: "arrow.up", text: isDe ? "**Sortierung**: Schaltet die chronologische Sortierung der Tabelleneinträge und Logs um (Neueste oben oder unten)." : "**Sort Order**: Toggles chronological sorting of table entries and logs (newest on top or bottom).")
                    iconBullet(icon: "trash", text: isDe ? "**Tabelle löschen**: Leert die Liste der empfangenen Dekodierungen und Spots." : "**Clear Table**: Clears the list of received decodes and spots.")
                    iconBullet(icon: "map", text: isDe ? "**Ausbreitungskarte**: Öffnet die Live-Karte zur Visualisierung empfangener Spots." : "**Propagation Map**: Opens the live map to visualize received spots.")
                    iconBullet(icon: "rectangle.compress.vertical", text: isDe ? "**Kompaktmodus**: Reduziert das Layout auf eine minimale Steuerleiste und Spot-Tabelle." : "**Compact Mode**: Minimizes the window to an ultra-compact control bar and spot list.")
                    iconBullet(icon: "gearshape", text: isDe ? "**Einstellungen**: Öffnet den Einstellungsdialog zur Konfiguration der Syncs, Cluster und Farben." : "**Settings**: Opens the settings dialog for sync, cluster, and color configuration.")
                    iconBullet(icon: "questionmark.circle", text: isDe ? "**Hilfe**: Öffnet dieses Hilfe- und Changelog-Fenster." : "**Help**: Opens this help and changelog window.")
                    iconBullet(icon: "sidebar.right", text: isDe ? "**Filter-Sidebar**: Blendet das rechte Panel zur Konfiguration von Rufzeichen-, DX- und Spotter-Filtern ein oder aus." : "**Filter Sidebar**: Toggles the right sidebar for DX, zone, and spotter filters.")
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Text(isDe ? "Tastatur- & Maus-Bedienung (Spot-Tabelle):" : "Mouse & Keyboard Controls (Spot Table):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Einfacher Klick**: Wählt eine Station in der Tabelle aus. Dies lädt ihre Details in den Detail-Banner, aktualisiert die QRZ/LoTW-Daten und hebt das Rufzeichen hervor." : "**Single Click**: Selects a station in the table. Loads details into the detail banner, updates QRZ/LoTW info, and highlights the callsign.")
                    bullet(isDe ? "**Doppelklick**: Löst die manuelle Antwort (**Manual Reply**) aus. AutoQSO sendet ein UDP-Reply-Kommando an WSJT-X, wodurch WSJT-X sofort auf die entsprechende Frequenz springt und den Sendezyklus startet." : "**Double Click**: Triggers **Manual Reply**. AutoQSO sends a UDP reply command to WSJT-X, making WSJT-X tune immediately and initiate transmission.")
                }
            }
            
        case .wsjtx:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "WSJT-X Konfiguration" : "WSJT-X Configuration")
                    .font(.title2)
                    .bold()
                Text(isDe ? "In WSJT-X unter Settings -> Reporting:" : "In WSJT-X under Settings -> Reporting:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    numberedItem("1.", isDe ? "Option 'Prompt me to log QSO' aktivieren." : "Check 'Prompt me to log QSO'.")
                    numberedItem("2.", isDe ? "Option 'Accept UDP requests' aktivieren." : "Check 'Accept UDP requests'.")
                    numberedItem("3.", isDe ? "UDP Server Address: `224.0.0.1` (Multicast) oder `127.0.0.1` (Unicast)." : "UDP Server Address: `224.0.0.1` (Multicast) or `127.0.0.1` (Unicast).")
                    numberedItem("4.", isDe ? "UDP Server Port: `2237`." : "UDP Server Port: `2237`.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }
            
        case .triggers:
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "Auto QSO Trigger Logik & Einstellungen" : "Auto QSO Trigger Logic & Settings")
                    .font(.title2)
                    .bold()
                
                Text(isDe ? "Im automatischen QSO-Modus (Auto Mode) analysiert AutoQSO nach jedem 15-Sekunden-Empfangsfenster alle eintreffenden WSJT-X Dekodierungen, bewertet potenzielle Anruf-Kandidaten und steuert WSJT-X vollautomatisch an." : "In Auto Mode, AutoQSO evaluates all incoming WSJT-X decodes after every 15-second reception window, scores eligible targets, and controls WSJT-X automatically.")
                    .font(.body)
                
                // 1. Erkannte Nachrichtentypen & Signal-Trigger
                Text(isDe ? "1. Erkannte Meldungstypen & Signal-Trigger:" : "1. Supported Message Types & Triggers:")
                    .font(.headline)
                
                autoModeButtonsIllustrationCard(isDe: isDe)
                
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Echte CQ-Rufe**: Alle CQ-Formate (`CQ`, `CQ DX`, `CQ POTA`, `CQ NA`, `CQ TEST`, etc.) inklusive des mitgesendeten Maidenhead-Locators." : "**Active CQ Calls**: All standard CQ formats (`CQ`, `CQ DX`, `CQ POTA`, `CQ NA`, `CQ TEST`, etc.) with grid locators.")
                    bullet(isDe ? "**QSO-Abschlussmeldungen (Tail-Ending)**: Stationen, die ein QSO mit `73`, `RR73` oder `RRR` beenden (z. B. `DL1ABC G4XYZ 73`), werden direkt nach QSO-Ende angerufen." : "**QSO Termination (Tail-Ending)**: Stations concluding QSOs with `73`, `RR73`, or `RRR` (e.g. `DL1ABC G4XYZ 73`) can be called immediately upon completion.")
                    bullet(isDe ? "**Direkte Anrufe (Inbound Calls)**: Stationen, die direkt unser Rufzeichen anrufen (z. B. `<MYCALL> <THEIRCALL> <GRID/RPRT>`). Wenn aktiviert, werden eingehende Anrufe nach Filterprüfung mit höchster Priorität beantwortet." : "**Direct Inbound Calls**: Stations calling your callsign directly (e.g. `<MYCALL> <THEIRCALL> <GRID/RPRT>`). When enabled, inbound callers are answered with top priority if they pass your filters.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                tableRowsIllustrationCard(isDe: isDe)
                
                // 2. Verfügbare Einstellungen (Einstellungen -> Auto Mode Optionen & Filter)
                Text(isDe ? "2. Konfigurierbare Auto-Mode-Einstellungen:" : "2. Configurable Auto Mode Settings:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 10) {
                    bullet(isDe ? "**Nur Stationen anrufen, die CQ rufen** (*Einstellungen → Auto Mode Optionen*): Schränkt den automatischen Anruf strikt auf echte CQ-Rufe ein und ignoriert `73`/`RR73`-Abschlussmeldungen (der grüne Hauptschalter signalisiert dies zweizeilig als **Auto ON / CQ Only**). *Hinweis*: Beim Anrufen am QSO-Ende fehlt der Grid-Locator und muss bei Bedarf manuell ergänzt werden." : "**Only call stations calling CQ** (*Settings → Auto Mode Options*): Strictly limits automatic calling to active CQ callers, ignoring `73`/`RR73` completion messages (the green toolbar button displays **Auto ON / CQ Only** on two lines). *Note*: Calling stations at their end of a QSO omits the grid locator, which can be added manually if desired.")
                    
                    bullet(isDe ? "**Eingehende Anrufer automatisch beantworten** (*Einstellungen → Auto Mode Optionen*): Beantwortet direkte Anrufe auf unser Rufzeichen automatisch, sofern sie die aktiven DX- und Gearbeitet-Filter erfüllen. Bei einem direkten Anruf wird eine eventuell bestehende Sperrzeit (Cooldown) für diese Station automatisch aufgehoben." : "**Auto-Answer Inbound Callers** (*Settings → Auto Mode Options*): Automatically answers stations calling you directly if they pass active DX and worked filters. Automatically lifts cooldown if a previously unanswered station returns and calls you.")
                    
                    bullet(isDe ? "**Sperrdauer für abgebrochene QSOs (Cooldown)** (*Einstellungen → Auto Mode Optionen*): Legt die Wartezeit in Minuten (z. B. 10 Min.) fest, für die ein Rufzeichen nach einem erfolglosen oder abgebrochenen Anruf gesperrt wird, um Endlosschleifen zu verhindern." : "**Cooldown for aborted QSOs** (*Settings → Auto Mode Options*): Sets the duration in minutes (e.g. 10 min) to temporarily blacklist a callsign after an aborted or unanswered transmission to prevent calling loops.")
                    
                    bullet(isDe ? "**Most-Wanted-Priorisierung & Only-Mode** (*Einstellungen → Most Wanted & Priorität*):\n• *Priorisiere Most Wanted*: Seltene, ungearbeitete DXCCs aus den Top 100 erhalten stets Vorrang vor normalen Stationen.\n• *Nur Most Wanted anrufen*: Ruft im Auto-Modus ausschließlich Stationen bis zum gewählten Rang-Cutoff (z. B. Top 50) an." : "**Most Wanted Priority & Only-Mode** (*Settings → Most Wanted & Priority*):\n• *Prioritize Most Wanted*: Unworked rare DXCC entities from the Top 100 always take precedence.\n• *Only Call Most Wanted*: Strictly calls stations matching your configured Most Wanted rank cutoff (e.g. Top 50).")
                    
                    bullet(isDe ? "**Bereits gearbeitete Stationen (Worked Before Filter)** (*Filter-Seitenleiste*):\n• *Standard*: Verhindert das erneute Arbeiten von Stationen, die auf dem Band bereits im Logbuch stehen.\n• *Zeitschwelle*: Erlaubt erneutes Arbeiten nach Ablauf einer frei wählbaren Zeitspanne (0–999 Stunden, Tage, Monate oder Jahre)." : "**Worked Station Filter (Worked Before)** (*Filter Sidebar*):\n• *Default*: Prevents re-calling stations already logged on the current band.\n• *Time Threshold*: Allows re-working stations after a customizable duration (0–999 hours, days, months, or years).")
                    
                    bullet(isDe ? "**Maidenhead Grid-Filter** (*Filter-Seitenleiste & Einstellungen*):\n• *Nur ungearbeitete 4-Stellen Grids* (z. B. JO31)\n• *Nur ungearbeitete 6-Stellen Grids* (z. B. JO31aa)" : "**Maidenhead Grid Filters** (*Filter Sidebar & Settings*):\n• *Only unworked 4-char Grids* (e.g. JO31)\n• *Only unworked 6-char Grids* (e.g. JO31aa)")
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
                
                // 3. Automatischer Ablauf & Priorisierung
                Text(isDe ? "3. Auswertungs- & Priorisierungs-Ablauf:" : "3. Decision Workflow & Scoring Order:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    numberedItem("1.", isDe ? "**Filterung**: Prüfung gegen geografische DX-Filter (Kontinente, gesperrte/erlaubte Länder, Zonen), Logbuch-Historie und aktive Sperrzeiten (Cooldowns)." : "**Filter Validation**: Verifies geographical filters (continents, allowed/blocked countries, zones), logbook history, and active cooldowns.")
                    numberedItem("2.", isDe ? "**Priorisierung**: 1. Direkte eingehende Anrufer (höchste Priorität) → 2. Most-Wanted-Rang (seltenste DXCCs zuerst) → 3. Größte Großkreis-Entfernung (km) → 4. Signalstärke (SNR)." : "**Target Ranking**: 1. Direct Inbound Callers (highest priority) → 2. Most Wanted Rank (rarest entity first) → 3. Furthest Great Circle distance (km) → 4. Signal-to-noise ratio (SNR).")
                    numberedItem("3.", isDe ? "**WSJT-X Steuerung**: Sendet das `Reply`-Kommando an WSJT-X und überwacht die Aktivierung der Sende-Bereitschaft (`TX BEREIT`)." : "**WSJT-X Control**: Dispatches the `Reply` UDP command to WSJT-X and monitors transmit readiness (`TX ENABLED`).")
                    numberedItem("4.", isDe ? "**Intelligenter Sende-Schutz**: Bricht WSJT-X nach nur einem Sende-Zyklus ab, greift keine Quarantäne; nach längerer Nicht-Antwort wird die Station für die eingestellte Cooldown-Dauer gesperrt." : "**Smart Retry Protection**: If WSJT-X halts after a single cycle, no cooldown is applied; extended non-responses enter the configured cooldown.")
                    numberedItem("5.", isDe ? "**Sofort-Abbruch ohne Cooldown (HaltTx)**: Antwortet die angerufene Zielstation einer anderen Station, stoppt AutoQSO das Senden sofort per `HaltTx`, verhängt **keine** Cooldown-Sperre und steht direkt für den nächsten Trigger bereit." : "**Instant Abort without Cooldown (HaltTx)**: If the called target station answers another party, AutoQSO immediately halts transmission via `HaltTx`, applies **no** cooldown quarantine, and is instantly ready for the next trigger.")
                }
                
                // 4. Sortierbare Filter-Pipeline & First-Match-Prinzip
                Text(isDe ? "4. Sortierbare Filter-Pipeline & First-Match-Prinzip:" : "4. Sortable Filter Pipeline & First-Match Principle:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**First-Match Boolean-Evaluation**: Was weiter oben steht, entscheidet zuerst. Steht eine Whitelist (*Erlaubte DX-Rufzeichen*, *Erlaubte Länder*) über einer Blacklist (*Gesperrte Länder*), greift die Whitelist als **Ausnahme / Sofort-Pass** (`return true`)." : "**First-Match Boolean Evaluation**: Higher sections evaluate first. When a whitelist (*Allowed DX Calls*, *Allowed Countries*) is placed above a blacklist (*Blocked Countries*), it acts as an **Instant-Pass / Exception Override** (`return true`).")
                    bullet(isDe ? "Ausführliche Erläuterungen, Diagramme und Praxisbeispiele findest du im separaten Hilfebereich **Filter-Logik & Pipeline**." : "Detailed explanations, diagrams, and practical examples can be found in the dedicated **Filter Logic & Pipeline** section.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }
            
        case .filterProfiles:
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "Intelligente Filter-Profile & Presets" : "Intelligent Filter Profiles & Presets")
                    .font(.title2)
                    .bold()
                
                Text(isDe ? 
                    "AutoQSO ermöglicht das Speichern und blitzschnelle Wiederaufrufen vollständiger Filter-Snapshots. Statt nur zwischen zwei starren Reihenfolgen zu wechseln, umfasst jedes Profil den Gesamtzustand aller 13 Filterregeln, Suchbegriffe und die individuelle Pipeline-Sortierung." : 
                    "AutoQSO allows you to save and instantly recall complete filter snapshots. Instead of switching between just two static orders, each profile captures the entire state of all 13 filter rules, search queries, and custom pipeline sequencing.")
                    .font(.body)
                
                // 1. Die 5 System-Vorlagen
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "🌟 Die 5 vorkonfigurierten System-Vorlagen:" : "🌟 The 5 Built-in System Presets:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**Allround (Standard)**" : "**Allround (Standard)**")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isDe ? "Ausgewogener Alltagsbetrieb über alle Bänder mit Standard-Filterreihenfolge und 1-Minuten-Doublettenfilter. Ideal für den regulären Funkbetrieb." : "Balanced everyday operation across all bands with default filter ordering and 1-minute duplicate filter. Ideal for daily QSOs.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "bolt.fill")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**DXpedition & Seltene DXCC**" : "**DXpedition & Rare DXCC**")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isDe ? "Fokussiert auf seltene Stationen (Top 50 Most Wanted). Der Nachrichten-Filter sucht automatisch nach \"split\" OR \"up\". Die Worked-Before-Sperre ist deaktiviert, damit Expeditionsstationen auf verschiedenen Bändern immer angezeigt werden." : "Focused on rare stations (Top 50 Most Wanted). Message filter searches for \"split\" OR \"up\". Worked-before suppression is disabled to spot expeditions across all bands.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "trophy.fill")
                                .font(.title3)
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**Contest / High-Rate**" : "**Contest / High-Rate**")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isDe ? "Maximale Durchlassrate für Wettbewerbe. Länder- und Kontinentsperren sowie Worked-Before sind abgeschaltet. Nur echte Doubletten werden innerhalb von 60 Sekunden gefiltert." : "Maximum decode pass-through for contests. Country/continent blocks and worked-before are disabled; only duplicate transmissions within 60s are suppressed.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "map.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**Grid Hunting (WAS / Neuland)**" : "**Grid Hunting (WAS / Unworked)**")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isDe ? "Ideal für das Sammeln von Planquadraten (z. B. WAS-Diplom). Lässt nur ungearbeitete 4-Stellen-Grids passieren und setzt den Grid-Filter an Position 1 der Pipeline." : "Ideal for locator hunting (e.g. WAS award). Lets through only unworked 4-digit grids with the Maidenhead grid filter prioritized at Position 1.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**Phone / SSB Only**" : "**Phone / SSB Only**")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isDe ? "Filtert gezielt Sprechfunk-Spots aus dem DX-Cluster. Der Nachrichtenfilter ist auf \"SSB\" OR \"USB\" OR \"LSB\" OR \"phone\" vorkonfiguriert." : "Filters specifically for phone/voice spots from DX clusters. Pre-configured with message filter query \"SSB\" OR \"USB\" OR \"LSB\" OR \"phone\".")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.06))
                    .cornerRadius(8)
                }
                
                // 2. Bedienung & Modifiziert-Indikator
                Text(isDe ? "Bedienung der Profil-Leiste:" : "Sidebar Profile Controls:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? 
                        "**Profil-Dropdown (`▾`)**: Klicke auf das Profil-Menü oben in der rechten Seitenleiste, um mit einem Klick zwischen System-Vorlagen und deinen eigenen Profilen zu wechseln." : 
                        "**Profile Dropdown (`▾`)**: Click the profile button at the top of the right sidebar to switch between system presets and custom user profiles instantly.")
                    
                    bullet(isDe ? 
                        "**Der Modifiziert-Indikator (`*`)**: Wenn du spontan eine Filter-Einstellung änderst (z. B. einen Kontinent deaktivierst oder einen Suchtext eingibst), erscheint neben dem Profil-Namen ein oranger Stern (`*`). Das Menü bietet dir dann folgende Aktionen:\n• **Änderungen in 'Profil' speichern**: Übernimmt deine Anpassungen dauerhaft in das Profil.\n• **Auf Originalzustand zurücksetzen**: Verwirft alle spontanen Tweaks und stellt das gespeicherte Profil exakt wieder her.\n• **Als neues Profil speichern...**: Erzeugt ein eigenständiges neues Benutzer-Profil mit deinen Änderungen." : 
                        "**The Dirty Indicator (`*`)**: If you tweak any filter parameter (e.g. disable a continent or change a search term), an orange asterisk (`*`) appears. The menu then offers:\n• **Save Changes to 'Profile'**: Permanently updates the profile with your tweaks.\n• **Reset to Original**: Instantly discards changes and restores the saved profile.\n• **Save as New Profile...**: Creates a brand new custom profile from the current state.")
                    
                    bullet(isDe ? 
                        "**Schnell-Taste `[ + ]`**: Öffnet direkt den Dialog zum Anlegen eines neuen Profils aus den aktuellen Filtereinstellungen." : 
                        "**Quick Add `[ + ]`**: Opens the modal dialog to save the current filter setup as a new custom profile.")
                    
                    bullet(isDe ? 
                        "**Verwaltungs-Taste `[ ⚙️ ]`**: Öffnet das Profil-Verwaltungsfenster." : 
                        "**Manage Button `[ ⚙️ ]`**: Opens the dedicated Profile Manager sheet.")
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                
                // 3. Smart Recall (Auto-Band & Auto-Mode)
                Text(isDe ? "Smart Recall (Automatische Band- & Mode-Aktivierung):" : "Smart Recall (Automatic Band & Mode Activation):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? 
                        "Im Verwaltungs-Sheet kannst du jedem eigenen Profil optional ein **Auto-Band** (z. B. `6m`, `10m`) oder einen **Auto-Mode** (z. B. `FT8`, `SSB`) zuweisen." : 
                        "In the Profile Manager sheet, you can optionally assign an **Auto-Band** (e.g. `6m`, `10m`) or **Auto-Mode** (e.g. `FT8`, `SSB`) to any custom profile.")
                    
                    bullet(isDe ? 
                        "Sobald du in WSJT-X oder über deine Transceiver-CAT-Steuerung das Band wechselst, erkennt AutoQSO den Frequenzwechsel und **aktiviert vollautomatisch das passende Profil** (z. B. automatische Umschaltung auf '6m Magic Band' beim Wechsel auf 50 MHz)." : 
                        "Whenever you change bands in WSJT-X or via radio CAT control, AutoQSO detects the frequency and **automatically switches to the matching profile** (e.g. activates '6m Magic Band' upon tuning to 50 MHz).")
                }
                .padding()
                .background(Color.green.opacity(0.06))
                .cornerRadius(8)
                
                // 4. Export & Import
                Text(isDe ? "Sichern & Teilen (Export / Import):" : "Backup & Sharing (Export / Import):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? 
                        "**Dateiformat (`.autoqso-filter.json`)**: Profile können über den Button *Als Datei exportieren...* als standardisierte JSON-Datei gesichert werden." : 
                        "**File Format (`.autoqso-filter.json`)**: Profiles can be saved as standard JSON files via *Export to File...*.")
                    
                    bullet(isDe ? 
                        "**Importieren**: Über *Importieren...* können Filterkonfigurationen von Vereinskollegen, Contest-Teams oder aus Online-Foren direkt geladen werden." : 
                        "**Importing**: Via *Import...*, you can load filter configurations shared by club members, contest teams, or online communities.")
                    
                    bullet(isDe ? 
                        "**iCloud- & SQLite-Sicherheit**: Alle Profile werden in der zentralen Datenbank (`autoqso_log.sqlite`) gespeichert und bleiben bei Software-Updates oder Neustarts dauerhaft erhalten." : 
                        "**iCloud & SQLite Persistence**: All profiles reside in the local SQLite database (`autoqso_log.sqlite`) and persist permanently across app updates.")
                }
                .padding()
                .background(Color.indigo.opacity(0.06))
                .cornerRadius(8)
            }

        case .filterLogic:
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "DX Filter-Logik & Pipeline-Auswertung" : "DX Filter Logic & Pipeline Evaluation")
                    .font(.title2)
                    .bold()
                Text(isDe ? 
                    "AutoQSO verfügt über eine frei sortierbare First-Match Filter-Pipeline. Alle 11 Filtersektionen in der rechten Seitenleiste werden streng sequentiell **von oben nach unten** ausgewertet. Die erste Regel, die auf ein empfangenes Signal zutrifft, entscheidet sofort." : 
                    "AutoQSO features a fully reorderable First-Match filter pipeline. All 11 filter sections in the right sidebar evaluate sequentially **from top to bottom**. The first rule that matches an incoming decode makes an immediate final decision.")
                    .font(.body)
                
                // Diagramm / Flow-Karte
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "⚡ Das First-Match-Prinzip im Überblick:" : "⚡ First-Match Principle at a Glance:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("1.")
                                .bold()
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**VIP-Whitelist: Treffer → SOFORT-PASS (return true)**" : "**VIP Whitelist: Match → INSTANT PASS (return true)**")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isDe ? "Trifft ein VIP-Filter (*Erlaubte Maidenhead-Grids*, *Erlaubte DX-Rufzeichen*, *Erlaubte Länder*) zu, passiert die Station sofort (**VIP-Pass**). Alle darunter liegenden Sperren werden übersprungen." : "If a VIP filter (*Allowed Maidenhead Grids*, *Allowed DX Calls*, *Allowed Countries*) matches, the station passes immediately (**VIP Pass**). All subsequent blacklists below are bypassed.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text("2.")
                                .bold()
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**VIP-Whitelist: Nicht-Treffer → WEITERLEITUNG an nächste Filter**" : "**VIP Whitelist: Non-Match → PASS-THROUGH to next filters**")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isDe ? "Trifft eine Station **nicht** auf die VIP-Whitelist zu, wird sie **nicht** verworfen, sondern läuft neutral zur nächsten Filter-Sektion nach unten weiter. Erst wenn dort eine Sperre greift, wird sie blockiert." : "Stations that do **not** match a VIP Whitelist are **not** dropped; they cleanly fall through to the next filter section below, where subsequent rules evaluate them.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text("3.")
                                .bold()
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**Blacklist-Treffer → SOFORT-DROP (return false)**" : "**Blacklist Match → INSTANT DROP (return false)**")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isDe ? "Trifft eine Sperre (*Gesperrte Länder*, *Gesperrte Kontinente*, *Zonen*, *Worked Before*, *Grid*, *Doubletten*, *Most Wanted*) zu, wird das Signal sofort blockiert und verworfen." : "If a blacklist (*Blocked Countries*, *Continents*, *Zones*, *Worked Before*, *Grid*, *Duplicates*, *Most Wanted*) matches, the signal is dropped immediately.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text("4.")
                                .bold()
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isDe ? "**Ende der Pipeline → PASS**" : "**End of Pipeline → PASS**")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isDe ? "Passiert ein Signal alle aktiven Filter ohne Blacklist-Treffer, wird es am Ende der Pipeline akzeptiert." : "If a decode traverses all active sections without hitting any blacklist, it is accepted at the end of the pipeline.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)
                }
                
                // Praxis-Beispiele
                Text(isDe ? "Praxis-Beispiele:" : "Practical Use Cases:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 10) {
                    bullet(isDe ? 
                        "**Szenario 1: USA generell blockieren, aber Stationen aus Wyoming (Maidenhead-Grids) erlauben**:\n• *Problem*: Du möchtest keine Routine-QSOs mit den USA, suchst aber noch das seltene Wyoming für dein WAS-Diplom.\n• *Lösung*: Schiebe die Sektion **Erlaubte Maidenhead-Grids** an Pos. 1 (ganz nach oben) und trage `DN61-DN74` (den geografischen Planquadrat-Bereich von Wyoming) ein. Setze **Gesperrte Länder** mit `United States` an Pos. 2.\n• *Ergebnis*: Signale aus Wyoming senden ihr Locator-Grid (z. B. `DN71`), treffen auf Pos. 1 und **passieren sofort** (VIP-Bypass). Alle anderen US-Signale laufen weiter zu Pos. 2 und werden dort **geblockt**.\n• *Eingabeformate*: Unterstützt Einzel-Grids (`DN71`), Bereiche (`DN61-DN74`, `KN64-KN71`) und Kombinationen (`DN61-DN74, EN10`)." : 
                        "**Scenario 1: Block USA in general, but allow Wyoming stations via Maidenhead Grids**:\n• *Goal*: Avoid common USA QSOs while still hunting rare Wyoming for your WAS award.\n• *Solution*: Move **Allowed Maidenhead Grids** to Pos. 1 (very top) and enter `DN61-DN74` (the grid range covering Wyoming). Place **Blocked Countries** with `United States` at Pos. 2.\n• *Result*: Wyoming stations transmit their grid (e.g. `DN71`), match Pos. 1, and **pass immediately** (VIP bypass). All other US stations fall through to Pos. 2 and are **blocked**.\n• *Supported Formats*: Single grids (`DN71`), ranges (`DN61-DN74`, `KN64-KN71`), and combinations (`DN61-DN74, EN10`).")
                    
                    bullet(isDe ? 
                        "**Szenario 2: Nur Most Wanted jagen, aber Clubstationen / Freunde immer anrufen**:\n• *Lösung*: Sektion **Erlaubte DX-Rufzeichen** auf Pos. 1 (z. B. mit `DL0ABC, DP0GVN`) und **Most Wanted Only** auf Pos. 2.\n• *Ergebnis*: Befreundete Rufzeichen passieren direkt auf Pos. 1, während alle anderen Stationen strikt durch den Most-Wanted-Filter gefiltert werden." : 
                        "**Scenario 2: Hunt Most Wanted only, but always allow club/friend callsigns**:\n• *Solution*: Place **Allowed DX Callsigns** on Pos. 1 (with `DL0ABC, DP0GVN`) and **Most Wanted Only** on Pos. 2.\n• *Result*: Friend callsigns pass immediately at Pos. 1, while other stations are strictly evaluated by Most Wanted rankings.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                // Bedienung & Sortierung
                Text(isDe ? "Bedienung & Sortierung:" : "Controls & Reordering:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Drag & Drop (`☰`)**: Klicke und ziehe das horizontale Griff-Symbol (`line.3.horizontal`) vor jedem Filter-Header, um Sektionen in beliebiger Reihenfolge anzuordnen." : "**Drag & Drop (`☰`)**: Click and drag the horizontal handle (`line.3.horizontal`) in any filter header to reorder sections freely.")
                    bullet(isDe ? "**Standard (Default)**: Stellt mit einem Klick die VIP-First Standard-Reihenfolge (VIP-Grids → VIP-Rufzeichen → VIP-Länder → Kontinente → Länder → Zonen → Most Wanted → Gearbeitet → Spezialfilter → Doubletten) wieder her." : "**Default Preset**: 1-click restore of the VIP-First standard order (VIP Grids → VIP Calls → VIP Countries → Continents → Countries → Zones → Most Wanted → Worked → Special Filters → Duplicates).")
                    bullet(isDe ? "**Benutzerdefiniert (Custom)**: Schaltet jederzeit auf deine gespeicherte individuelle Sortierung um." : "**Custom Preset**: Switches back to your personalized custom order at any time.")
                    bullet(isDe ? "**Filter-Tracing im System-Log**: Aktiviere im Tab *System-Logs* der Konsole die Checkbox **Filter-Tracing**, um den genauen Entscheidungsweg (✅ PASS / ❌ DROP mit Regel- und Positionsnummer) live für jedes empfangene Signal mitzuverfolgen." : "**Filter Tracing in System Log**: Enable **Filter Tracing** in the *System Logs* console tab to monitor real-time decisions (✅ PASS / ❌ DROP with section position and matching rule details) for every decode.")
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
            }
            
        case .cluster:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "DX Cluster & Spot-Verarbeitung" : "DX Cluster & Spot Processing")
                    .font(.title2)
                    .bold()
                Text(isDe ? "AutoQSO ermöglicht den parallelen Empfang von bis zu drei DX-Cluster-Verbindungen (C1, C2, C3) sowie den WSJT-X Dekodierungen." : "AutoQSO allows parallel reception of up to three DX Cluster connections (C1, C2, C3) alongside WSJT-X decodes.")
                    .font(.body)
                
                Text(isDe ? "Zuweisung & Status:" : "Assignment & Status:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "In der linken Sidebar oder den Einstellungen wählst du die gewünschten Cluster aus einem Dropdown-Menü." : "Select your desired clusters from dropdown menus in the left sidebar or Settings.")
                    bullet(isDe ? "**Status-Indikatoren** zeigen an, ob die Verbindung aktiv ist (Grau = Aus, Orange = Verbindungsaufbau, Grün = Verbunden, Rot = Verbindungsfehler)." : "**Status Indicators** show connection health (Gray = Off, Orange = Connecting, Green = Connected, Red = Error).")
                    bullet(isDe ? "**Universelles Spot-Parsing**: Alle eintreffenden Spots gängiger Knoten-Formate (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider) werden automatisch erfasst." : "**Universal Spot Parsing**: All incoming spots from major cluster formats (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider) are automatically parsed.")
                }
                
                Text(isDe ? "Vollständige Listenanzeige & Farbkodierung:" : "Table Display & Color Coding:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Vollständige Anzeige**: Alle empfangenen Spots und Dekodierungen werden ohne Vorab-Löschung in der Haupttabelle dargestellt." : "**Full Display**: All received spots and decodes are shown in the main table without premature pruning.")
                    bullet(isDe ? "**Grün**: CQ-Anrufe und potenzielle AutoQSO-Kandidaten." : "**Green**: CQ calls and potential AutoQSO candidates.")
                    bullet(isDe ? "**Rot / Fett**: Ungearbeitete seltene Most Wanted Entitäten." : "**Red / Bold**: Unworked rare Most Wanted entities.")
                    bullet(isDe ? "**Blasses Rot**: Stationen, die auf dem aktuellen Band bereits im Logbuch stehen." : "**Pale Red**: Stations already worked on the current band in your logbook.")
                    bullet(isDe ? "**Grau / Muted**: Von den aktiven DX- oder Spotter-Filtern blockierte Stationen." : "**Gray / Muted**: Stations blocked by active DX or spotter filters.")
                    bullet(isDe ? "**Standard**: Normale empfangene Dekodierungen und Spots." : "**Standard**: Standard received decodes and spots.")
                }
                
                Text(isDe ? "Länder- & Spotter-Filterung:" : "Country & Spotter Filtering:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Intelligente Autovervollständigung**: Beim Tippen in den Länderfeldern (Gesperrte Länder, Erlaubte DX-Länder, Erlaubte Spotter-Länder) werden passende Länder sofort vorgeschlagen." : "**Intelligent Autocomplete**: Typing in country fields suggests matching countries immediately.")
                    bullet(isDe ? "**Teilstring- & Regionenerkennung**: Eingaben wie `Russia` oder `Russland` stimmen automatisch sowohl mit `European Russia` als auch `Asiatic Russia` überein. Genauso lassen sich Teilbegriffe gezielt filtern." : "**Substring Matching**: Inputs like `Russia` automatically match both `European Russia` and `Asiatic Russia`.")
                }
                
                Text(isDe ? "Listen-Manager (Einstellungen -> DX Cluster):" : "List Manager (Settings -> DX Cluster):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Hinzufügen & Bearbeiten**: Du kannst eigene Cluster mit Name, Host und Port registrieren." : "**Add & Edit**: Register custom cluster nodes with Name, Host, and Port.")
                    bullet(isDe ? "**Drag-and-Drop**: Die Reihenfolge der Cluster kann direkt in der Tabelle per Maus verschoben und angepasst werden." : "**Drag and Drop**: Reorder cluster priority directly via drag and drop.")
                    bullet(isDe ? "**Zurücksetzen (Restore Defaults)**: Stellt die ursprüngliche Liste der vordefinierten Standard-Cluster wieder her." : "**Restore Defaults**: Restores the default factory list of reliable cluster nodes.")
                }
            }
            
        case .telnet:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Telnet Server & Spotting-Ausgabe" : "Telnet Server & Spotting Output")
                    .font(.title2)
                    .bold()
                Text(isDe ? "AutoQSO läuft als lokaler Telnet-Cluster-Server, an den du externe Log-Software (z.B. MacLoggerDX) koppeln kannst." : "AutoQSO runs as a local Telnet cluster server to feed spots into external logging tools (e.g. MacLoggerDX).")
                    .font(.body)
                
                Text(isDe ? "Konfiguration:" : "Configuration:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Port & Login**: Der Server horcht standardmäßig auf Port 8000. Das Login-Rufzeichen (z.B. GUEST) kann in den Einstellungen angepasst werden." : "**Port & Login**: Listens on port 8000 by default. Login callsign (e.g. GUEST) can be customized in Settings.")
                    bullet(isDe ? "**Client-Tracking**: Der Live-Status im linken Sidepanel zeigt die Anzahl der aktuell verbundenen externen Programme an." : "**Client Tracking**: Live status in the left sidebar displays the number of connected external clients.")
                }
                
                Text(isDe ? "WSJT-X Spotter Telnet-Ausgabe:" : "WSJT-X Decodes Telnet Forwarding:")
                    .font(.headline)
                bullet(isDe ? "Ist dieser Schalter aktiviert, werden alle gefilterten WSJT-X Dekodierungen als rohe DX-Spots im Telnet-Format ausgegeben, sodass sie sofort in deinem Log-Programm auf der Karte erscheinen. Standardmäßig ist diese Option deaktiviert (keine Ausgabe)." : "When enabled, all filtered WSJT-X decodes are broadcast as Telnet DX spots, displaying them on external logbook maps in real time.")
            }
            
        case .propagationMap:
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "Ausbreitungskarte & Maidenhead Grid-Map" : "Propagation Map & Maidenhead Grid Map")
                    .font(.title2)
                    .bold()
                Text(isDe ? "AutoQSO bietet zwei spezialisierte interaktive Kartenansichten, die über die Toolbar-Buttons **Karte ↗** und **Grid-Map ↗** als eigenständige Fenster geöffnet werden können." : "AutoQSO offers two specialized interactive map views available via the **Map ↗** and **Grid Map ↗** toolbar buttons.")
                    .font(.body)
                
                activeQSOPathIllustrationCard(isDe: isDe)
                
                Text(isDe ? "1. Ausbreitungskarte (Propagation Map):" : "1. Propagation Map:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Länder-Cluster**: Stellt aktive DX-Entitäten visuell auf einer Weltkarte dar mit farblich codierten Band-Badges." : "**Country Clusters**: Shows active DX entities visually on a world map with color-coded band badges.")
                    bullet(isDe ? "**Zeitfenster-Steuerung**: Einstellbar von 5 bis 120 Minuten." : "**Time Window**: Adjustable from 5 to 120 minutes.")
                    bullet(isDe ? "**Gearbeitete mitzählen**: Umschalter zur Anzeige bereits gearbeiteter Länder auf der Karte." : "**Show Worked**: Toggle to display or hide already worked DXCC entities.")
                    bullet(isDe ? "**Seitenleiste**: Übersichtliche Gruppierung nach Kontinent, A–Z oder Spot-Anzahl." : "**Sidebar**: Clean grouping by continent, alphabetical, or spot count.")
                }
                
                Text(isDe ? "2. Neue Maidenhead Grid-Map:" : "2. Maidenhead Grid Map:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Ungearbeitete Maidenhead Grids**: Visualisiert gezielt noch ungearbeitete 4-Stellen (`JO31`) und 6-Stellen (`JO31AA`) Maidenhead-Lokaltore auf der Weltkarte." : "**Unworked Maidenhead Grids**: Visualizes unworked 4-char (`JO31`) and 6-char (`JO31AA`) grids worldwide.")
                    bullet(isDe ? "**Interaktiver Grid-Inspector (Klick auf Grid)**: Ein Klick auf ein beliebiges Grid-Feld oder Marker-Badge auf der Karte öffnet ein Info-Popover mit Status (gearbeitet/ungearbeitet), Peilung & Distanz, Band-Aufteilung, Liste aller aktiven Stationen inklusive Direktaufruf von QRZ.com und Zentrier-Schaltfläche." : "**Interactive Grid Inspector**: Clicking any grid square or marker opens a popover with worked status, bearing & distance, active stations, and 1-click QRZ.com lookup.")
                    bullet(isDe ? "**Band-Schnellfilter**: Schwebende Pill-Leiste (`ALL`, `160M`–`6M`), um die Karte und Seitenleiste mit einem Klick auf das gewünschte Band zu filtern." : "**Band Quick Filter**: Floating pill bar (`ALL`, `160M`–`6M`) to filter map and sidebar by band instantly.")
                    bullet(isDe ? "**Peilung & Distanz**: Anzeige von Azimut und Großkreis-Entfernung bezogen auf das eigene Heimat-QTH (`🧭 285° · 4.210 km`) direkt in jeder Zeile." : "**Bearing & Distance**: Shows azimuth and great-circle distance from home QTH (`🧭 285° · 4,210 km`) in each row.")
                    bullet(isDe ? "**Spot-Frische & Age-Decay**: Brandneue Spots (< 3 Min.) werden durch ein leuchtendes `⚡ NEU`-Badge und Umrandung hervorgehoben; ältere Spots (> 10 Min.) blenden dezent ab." : "**Spot Age Decay**: Fresh spots (< 3 min) glow with a `⚡ NEW` badge; older spots fade gracefully.")
                    bullet(isDe ? "**Kompakt- / Detail-Umschalter**: Schaltfläche in der Sidebar-Kopfleiste zum Wechseln zwischen einer kompakten 1-Zeilen-Übersicht und einer ausführlichen Detailkarte mit allen Rufzeichen." : "**Compact / Detail View**: Toggle between 1-line summary and detailed multi-callsign cards.")
                    bullet(isDe ? "**Farbkodierung**: 4-Stellen Grids werden grün hervorgehoben, 6-Stellen Grids blau." : "**Color Coding**: 4-character grids are green, 6-character grids blue.")
                    bullet(isDe ? "**Echtzeit-Suchleiste**: Schnellsuche nach Grid-Locatoren oder Rufzeichen in der rechten Seitenleiste." : "**Real-Time Search**: Fast filtering of grids and callsigns in the map sidebar.")
                    bullet(isDe ? "**Fokussierung**: Klick auf eine Zeile oder ein Marker-Badge zentriert die Karte direkt auf den ausgewählten Locator." : "**Centering**: Clicking a row or badge centers the map on the selected locator.")
                }
                
                Text(isDe ? "3. Dynamisches Maidenhead Grid-Overlay (GridTracker-Stil):" : "3. Dynamic Maidenhead Grid Overlay:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Lückenlose Kartenabdeckung**: Hardwarebeschleunigtes Canvas-Gitter im GridTracker-Stil über der gesamten Karte." : "**Seamless Hardware Canvas**: High-performance GridTracker-style vector grid overlay.")
                    bullet(isDe ? "**Standardmäßig aktiv**: In der Grid-Map beim Öffnen automatisch eingeschaltet (über das Grid-Icon `grid.circle` in der oberen rechten Ecke umschaltbar)." : "**Active by Default**: Enabled automatically in Grid Map (toggleable via the `grid.circle` icon).")
                    bullet(isDe ? "**Pixel-dynamische Auflösung**: Automatischer Wechsel von 2-Stellen (`JO`), 4-Stellen (`JO31`), 6-Stellen (`JO31AA`) bis hin zu 8-Stellen Resolution (`JO31AA11`)." : "**Adaptive Resolution**: Dynamically scales from 2-char (`JO`) to 4-char (`JO31`), 6-char (`JO31AA`), and 8-char (`JO31AA11`) based on zoom.")
                    bullet(isDe ? "**Dezente Lesbarkeits-Badges**: Transparente Unterlegungen (`opacity: 0.55`) sorgen für optimale Lesbarkeit, ohne die Karte zu verdecken." : "**Readability Badges**: Subtle translucent badges guarantee legibility over land and satellite imagery.")
                    bullet(isDe ? "**Gearbeitete Grid-Schattierung**: Über das Häkchen-Icon (`checkmark.square`) lassen sich bereits gearbeitete 4-Stellen Grids aus dem Logbuch auf der Karte farbig schattieren." : "**Worked Grid Shading**: Highlights worked 4-character grids from your logbook in customizable tint.")
                    bullet(isDe ? "**Klick auf gearbeitetes Grid**: Ein Klick auf ein schattiertes/gearbeitetes Grid-Feld öffnet ein Detailfenster (**WorkedGridDetailView**) mit allen im Logbuch enthaltenen QSOs für diesen Maidenhead-Locator inklusive Such- und Filterfunktion." : "**Worked Grid Detail**: Clicking a shaded grid opens the QSO history for that square.")
                    bullet(isDe ? "**Doppelklick für QRZ.com**: Ein Doppelklick auf eine Station im Grid-Logbuchfenster öffnet direkt deren QRZ.com-Seite im Browser." : "**Double Click QRZ Lookup**: Double-clicking any station opens its QRZ.com profile.")
                    bullet(isDe ? "**Schnellsteuerungs-Leiste am Kartenrand**: Live-Anpassung der Schriftgröße (`A-`/`A+`), der Textfarbe, der Gitterlinienfarbe, der Badge-Farbe sowie der Schattierungsfarbe für gearbeitete Grids." : "**Quick Toolbar**: Real-time adjustments for font size (`A-`/`A+`), text color, grid line color, and shading.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Text(isDe ? "Filter-Garantie:" : "Filter Guarantee:")
                    .font(.headline)
                bullet(isDe ? "Beide Karten aggregieren ausschließlich Dekodierungen und DX-Spots, die alle deine aktiven DX-Filterregeln erfolgreich bestanden haben." : "Both maps strictly display spots and decodes that pass all active DX filter criteria.")
            }
            
        case .compactMode:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Kompaktmodus (Compact Mode)" : "Compact Mode")
                    .font(.title2)
                    .bold()
                Text(isDe ? "Der Kompaktmodus reduziert den Platzbedarf von AutoQSO auf ein absolutes Minimum." : "Compact Mode minimizes AutoQSO window footprint down to 480x320 pixels.")
                    .font(.body)
                
                Text(isDe ? "Funktionsumfang im Kompaktmodus:" : "Compact Mode Features:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Kompakte Steuerleiste**: Bietet Zugriff auf Auto Transmit (Auto ON/OFF), den globalen Filter-Schalter, das Öffnen der Ausbreitungskarte und die Verbindungs-/TX-Statuslämpchen." : "**Compact Control Bar**: Quick toggles for Auto Transmit, Filters, Map window, and TX indicators.")
                    bullet(isDe ? "**Reduzierte Tabelle**: Zeigt eine fokussierte Tabelle mit Zeit, DX Call, Land, SNR und Nachricht." : "**Streamlined Table**: Focused columns for Time, Callsign, Country, SNR, and Message.")
                    bullet(isDe ? "**Ticker für Most Wanted**: Unten scrollt eine Zeile mit ungearbeiteten seltenen Stationen durch. Durch Doppelklick/Anklicken kannst du diese anrufen bzw. im Banner fokussieren." : "**Most Wanted Ticker**: Ticker strip at the bottom highlighting rare unworked entities.")
                    bullet(isDe ? "**Minimalmaße**: Das Hauptfenster lässt sich bis auf 480x320 Pixel herunterskalieren, um perfekt in einer Bildschirmecke Platz zu finden." : "**Ultra-Small Footprint**: Scales down to 480x320 pixels for seamless corner placement.")
                    bullet(isDe ? "**Zurückwechseln & Layout-Wiederherstellung**: Über das Pfeilsymbol ganz rechts in der kompakten Leiste gelangst du wieder in die Normalansicht. Sämtliche Trennlinien (Log-Konsole, Most-Wanted-Panel) und Seitenleistenbreiten werden exakt wiederhergestellt." : "**Expand Back & Layout Restoration**: The expand button restores standard window layout instantly. All inner split dividers (Log Console, Most Wanted Panel) and sidebar widths are preserved and restored cleanly.")
                }
            }
            
        case .logbook:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Logbuch Management & Synchronisation" : "Logbook Management & Sync")
                    .font(.title2)
                    .bold()
                
                Text(isDe ? "Logbuch-Quellen (Umschaltbar):" : "Logbook Sources (Switchable):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**RUMlogNG (macOS App)**: Direkte 1-Klick-Synchronisation über die native AppleScript-Schnittstelle von RUMlogNG (`ReadAdif`). RUMlogNG muss lediglich geöffnet sein." : "**RUMlogNG (macOS App)**: Direct 1-click sync via native AppleScript API (`ReadAdif`).")
                    bullet(isDe ? "**ARRL LoTW**: Automatischer Download deiner bestätigten und hochgeladenen QSOs vom ARRL Logbook of The World." : "**ARRL LoTW**: Automated download of confirmed QSOs from ARRL Logbook of The World.")
                    bullet(isDe ? "**QRZ.com**: API-basierter Abgleich deiner QSOs über deinen QRZ.com API Key." : "**QRZ.com**: Cloud sync of your logbook using the official QRZ.com Logbook API.")
                }
                
                Text(isDe ? "Vollständiger Sync & Inkrementeller Sync:" : "Full Sync & Incremental Sync:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Vollständiger Sync (ab 1900)**: Lädt das gesamte Logbuch ab `1900-01-01` herunter bzw. aus RUMlogNG." : "**Full Sync (since 1900)**: Downloads entire QSO history since `1900-01-01`.")
                    bullet(isDe ? "**Intelligentes SQLite-Upsert**: Bei bestehenden Einträgen werden fehlende Attribute (wie z. B. Grid-Locatoren) automatisch ergänzt, ohne doppelte QSOs zu erzeugen (`ON CONFLICT DO UPDATE`)." : "**Smart SQLite Upsert**: Fills missing attributes without duplicating existing QSO records.")
                    bullet(isDe ? "**Inkrementeller Sync**: Synchronisiert automatisch nur neuere QSOs ab dem Datum des letzten Logbucheintrags." : "**Incremental Sync**: Efficiently syncs only newer QSOs since the latest log date.")
                }
                
                Text(isDe ? "ADIF-Datei importieren:" : "Import ADIF File:")
                    .font(.headline)
                bullet(isDe ? "Über den Button '**ADIF-Datei auswählen & importieren...**' kannst du bestehende Logbücher im `.adi` / `.adif` Format in deine lokale SQLite-Datenbank einspielen. Duplikate werden anhand des eindeutigen Schlüssels (Call, Band, Mode, Zeit) automatisch aussortiert." : "Import existing logbooks in `.adi`/`.adif` format directly into the SQLite database. Duplicates are filtered automatically.")
                
                Text(isDe ? "Logbuch leeren / Löschen:" : "Clear / Delete Logbook:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Löschen (🗑️)**: QSOs können im Logbuch-Fenster einzeln oder über Mehrfachauswahl gelöscht werden." : "**Delete Selected (🗑️)**: Delete individual or batch selections directly in the logbook table.")
                    bullet(isDe ? "**Logbuch löschen**: Der Button in den Einstellungen entfernt alle lokalen QSOs aus der Datenbank nach Bestätigung eines Sicherheitsdialogs." : "**Purge Logbook**: Removes all local records from SQLite following a safety confirmation.")
                }
            }
            
        case .storage:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Speicherort, SQLite-Datenbank & iCloud Sync" : "Storage, SQLite Database & iCloud Sync")
                    .font(.title2)
                    .bold()
                
                Text(isDe ? "AutoQSO speichert alle QSOs, Konfigurationen und Einstellungen in einer einheitlichen SQLite-Datenbank (`autoqso_log.sqlite`)." : "AutoQSO stores all QSOs, configurations, and settings in a single unified SQLite database (`autoqso_log.sqlite`).")
                    .font(.body)
                
                Text(isDe ? "Konfiguration im Einstellungen-Dialog (Seitenleiste -> Speicherort & iCloud):" : "Configuration in Settings (Sidebar -> Storage & iCloud):")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    bullet(isDe ? "**Standard-Ordner**: Speichert die Datenbank unter `~/Documents/AutoQSO`." : "**Default Folder**: Stores the SQLite database in `~/Documents/AutoQSO`.")
                    bullet(isDe ? "**Benutzerdefinierter Ordner**: Freie Wahl eines lokalen Ordners via macOS Dialog." : "**Custom Folder**: Select any local directory via native macOS folder picker.")
                    bullet(isDe ? "**iCloud Drive**: Speichert in `iCloud Drive/AutoQSO` zur automatischen Synchronisation von QSOs, Filtern und Einstellungen zwischen mehreren Macs." : "**iCloud Drive**: Stores in `iCloud Drive/AutoQSO` for automatic synchronization of QSOs, filters, and settings across your Macs.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Text(isDe ? "Hinweis: Sämtliche Einstellungen werden in Echtzeit mit der Datenbank synchronisiert. Beim Wechsel des Speicherorts wird die bestehende Datenbank automatisch an den neuen Zielort kopiert und alle Konfigurationen sofort übernommen." : "Note: All settings are synchronized with the database in real time. Switching storage locations automatically copies the existing database and applies all configurations immediately.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .appearance:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Ansicht & Farbanpassungen" : "Appearance & Theme Customization")
                    .font(.title2)
                    .bold()
                Text(isDe ? "Im Einstellungsmenü unter **Ansicht** kannst du das gesamte Erscheinungsbild von AutoQSO deinen individuellen Wünschen anpassen." : "In Settings under **Appearance & Theme**, customize the full visual presentation of AutoQSO.")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "1. Farbschema & Darstellung:" : "1. Theme & Presentation:")
                        .font(.headline)
                    bullet(isDe ? "Auswahl zwischen **System**, **Hell** und **Dunkel**." : "Select between **System**, **Light**, and **Dark**.")
                    bullet(isDe ? "Umschaltung der Sortierrichtung: Neueste Einträge oben oder unten in Haupttabelle und Logfenster." : "Sort order toggle: Newest entries on top or bottom in the main table and log console.")
                    
                    Text(isDe ? "2. Listen-Ansicht (Haupttabelle & Log-Konsole):" : "2. Table & Log Console Styling:")
                        .font(.headline)
                    bullet(isDe ? "**Schriftgrößen**: Stufenlose Regelung der Tabellen- und Protokoll-Schriftgrößen (8 pt bis 20 pt)." : "**Font Sizes**: Independent font size sliders for table and log entries (8 pt to 20 pt).")
                    bullet(isDe ? "**Farbanpassungen Haupttabelle**: Individuelle Farbwahl für Standard-Text, Most Wanted (🔥), CQ-Aufrufe und bereits gearbeitete Stationen." : "**Table Colors**: Custom color pickers for standard text, Most Wanted (🔥), CQ calls, and worked stations.")
                    bullet(isDe ? "**Farbanpassungen Log-Konsole**: Einstellbare Farben für Konsolen-Hintergrund, System-Logs, WSJT-X Dekodierungen, eingehenden/ausgehenden Traffic und Cluster-Spots." : "**Log Colors**: Customizable colors for background, system logs, decodes, traffic, and spots.")
                    bullet(isDe ? "**Unabhängiges Zurücksetzen**: Eigener Button 'Listen-Ansicht auf Standard zurücksetzen' zur Wiederherstellung der Tabellen- und Logfarben." : "**Reset Defaults**: Independent button to restore factory font sizes and colors.")
                    
                    Text(isDe ? "3. Landkarten-Ansicht (Maidenhead Grid-Overlay):" : "3. Map View (Maidenhead Grid Overlay):")
                        .font(.headline)
                    bullet(isDe ? "**Gitter-Schriftgröße**: Slider zur Skalierung der Locator-Beschriftungen (8 pt bis 22 pt)." : "**Grid Font Size**: Slider to adjust locator label sizes (8 pt to 22 pt).")
                    bullet(isDe ? "**Farb-Customizing**: Separate Farbwahl für Gitter-Beschriftungen, Gitterlinien, Badge-Hintergründe und gearbeitete Grids." : "**Custom Colors**: Color pickers for grid labels, lines, badges, and worked grid shading.")
                    bullet(isDe ? "**Lesbarkeits-Badges**: Ein- und Ausschalten der dunklen Hintergründe hinter Locator-Texten." : "**Readability Badges**: Toggle background pills behind locator labels.")
                    bullet(isDe ? "**Unabhängiges Zurücksetzen**: Eigener Button 'Karten-Ansicht auf Standard zurücksetzen' für alle Karteneinstellungen." : "**Reset Map Defaults**: Restores all map colors and font settings.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }

        case .support:
            VStack(alignment: .leading, spacing: 14) {
                Text(isDe ? "Support & Hilfestellung" : "Support & Assistance")
                    .font(.title2)
                    .bold()
                
                Text(isDe ? "Hast du Fragen, Probleme oder Feedback zu AutoQSO? Über den unten stehenden Button kannst du direkt eine E-Mail an unseren Support senden." : "Have questions, issues, or feedback regarding AutoQSO? Click the button below to compose a support email.")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(isDe ? "Automatisch übermittelte Systeminformationen:" : "Automatically Attached Diagnostics:")
                        .font(.headline)
                    bullet("App Version & Build (`AutoQSO v\(APP_VERSION) (Build \(APP_BUILD_NUMBER))`)")
                    bullet(isDe ? "macOS-Version & Build-Nummer" : "macOS Version & Build Number")
                    bullet(isDe ? "Hardware-Informationen (Mac-Modell/Hostname, Prozessortyp, CPU-Kerne, Arbeitsspeicher)" : "Hardware Details (Mac Model, Architecture, CPU Cores, RAM)")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Button(action: sendSupportEmail) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Text(isDe ? "Support-E-Mail senden" : "Send Support Email")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
        case .disclaimer:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Rechtlicher Hinweis & Haftungsausschluss" : "Legal Notice & Disclaimer")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(isDe ? "Nutzung auf eigene Verantwortung:" : "Operation Under Own Responsibility:")
                        .font(.headline)
                    Text(isDe ? 
                        "Die Nutzung von AutoQSO und insbesondere der automatisierten Sendefunktion (**Auto QSO für WSJT-X**) erfolgt ausschließlich auf eigene Gefahr und Verantwortung des jeweiligen lizenzierten Funkamateurs." :
                        "The operation of AutoQSO, and specifically the automated transmission engine (**Auto QSO for WSJT-X**), is strictly at the sole risk and responsibility of the licensed amateur radio control operator.")
                        .font(.body)
                    
                    Text(isDe ? "Einhaltung der Amateurfunkbestimmungen:" : "Regulatory Compliance:")
                        .font(.headline)
                    Text(isDe ? 
                        "Der Betreiber ist verpflichtet, die geltenden Gesetze, Bestimmungen der Bundesnetzagentur (bzw. der zuständigen nationalen Fernmeldebehörde) sowie die IARU-Bandpläne einzuhalten. Eine ständige Beaufsichtigung der Sendestation durch den Funkamateur ist sicherzustellen." :
                        "Operators must strictly adhere to national telecommunications laws (e.g. BNetzA, FCC) and IARU band plans. Continuous control and supervision of automated transmissions must be ensured at all times.")
                        .font(.body)
                    
                    Text(isDe ? "Haftungsausschluss:" : "Limitation of Liability:")
                        .font(.headline)
                    Text(isDe ? 
                        "Der Entwickler übernimmt keinerlei Haftung für direkte oder indirekte Schäden, Frequenzstörungen, Fehlbedienungen, Bandplanverletzungen oder sonstige Nachteile, die aus der Nutzung der Software resultieren." :
                        "The author accepts no liability for direct or indirect damages, frequency interference, operator error, band plan infractions, or other consequences arising from the use of this software.")
                        .font(.body)
                }
                .padding()
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
            
        case .changelog:
            VStack(alignment: .leading, spacing: 16) {
                Text(isDe ? "Versionshistorie (Changelog)" : "Version History (Changelog)")
                    .font(.title2)
                    .bold()
                
                // Version 4.5.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.5.0")
                            .font(.headline)
                            .bold()
                        Text("(Build \(APP_BUILD_NUMBER))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(isDe ? "AKTUELL" : "CURRENT")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Intelligente Filter-Profile & Presets: Speichern und Wiederaufrufen vollständiger Filter-Snapshots (Whitelists, Blacklists, Spezialfilter, Textfilter und Pipeline-Sortierung). Enthält 5 System-Vorlagen (Allround, DXpedition, Contest, Grid Hunting, Phone/SSB), eigene Benutzer-Profile, Modifiziert-Indikator (*), optionale automatische Band-/Mode-Aktivierung und JSON-Export/Import." : "Intelligent Filter Profiles & Presets: Save and recall complete filter snapshots (Whitelists, Blacklists, Special rules, Message filter, and pipeline ordering). Includes 5 system presets (Allround, DXpedition, Contest, Grid Hunting, Phone/SSB), custom user profiles, dirty indicator (*), optional automatic band/mode recall, and JSON export/import.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Aufgeräumte Seitenleiste: Entfernen der alten redundanten Default/Custom-Buttons am unteren Rand für mehr vertikalen Platz und klare Profil-Steuerung oben." : "Streamlined Sidebar: Removed legacy redundant Default/Custom order buttons at the bottom for more vertical space and centralized profile management.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
                
                // Version 4.4.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.4.0")
                            .font(.headline)
                            .bold()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen" : "✨ New Features")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Neuer Nachrichten-Filter (Message Content Filter): Durchsucht das Kommentarfeld nach frei definierbaren Begriffen mit boolescher Logik (AND, OR, Phrasen in Anführungszeichen wie \"5 up\"). Lässt nur passende Signale passieren." : "New Message Content Filter: Searches the message/comment field using case-insensitive Boolean logic (AND, OR, quoted phrases like \"5 up\"). Lets only matching spots pass through.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
                
                // Version 4.3.2
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.3.2")
                            .font(.headline)
                            .bold()
                        Text("(Build \(APP_BUILD_NUMBER))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(isDe ? "AKTUELL" : "CURRENT")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Konsequente Daten- und Anzeige-Entkopplung: Vorberechnetes Display-Modell (SpotRowData) für absolut flüssiges UI-Rendering ohne CPU-Overhead bei vielen Spots." : "Decoupled Data & Display Model: Pre-computed SpotRowData for zero-overhead, buttery smooth UI table rendering.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "100% GPU-beschleunigte MapKit-Karten: Native Metal-Overlays für Maidenhead-Gitter und gearbeitete Grids ohne Wisch-Verzögerung oder Ruckeln." : "100% GPU-Accelerated MapKit Overlays: Native Metal renderers for Maidenhead grids and worked shading with zero gesture lag.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "O(1) Grid- & QSO-Indexierung: Blitzschnelle Grid-Inspektion und Popover-Anzeige direkt an der Kartenposition." : "O(1) Grid & QSO Indexing: Instantaneous grid popover inspection anchored directly to the clicked map coordinate.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
                
                // Version 4.3.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.3.1")
                            .font(.headline)
                            .bold()
                        Text(isDe ? "(Vorherige)" : "(Previous)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Kontinuierlicher Rollpuffer (FIFO 250 Einträge): Die Tabelle gefilterter Stationen wird bei neuen WSJT-X Sendezyklen (Clear) nicht mehr zyklisch geleert. Frische Dekodierungen schieben ältere Einträge nach unten, ab Position 250 fallen ältere Stationen automatisch heraus." : "Continuous Rolling Decode Buffer (FIFO 250 entries): The decode table is no longer wiped every cycle on WSJT-X Clear signals. New decodes smoothly push older entries down, and entries beyond 250 records drop off the bottom.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Manuelles Leeren: Ein vollständiges Zurücksetzen der Tabelle ist weiterhin jederzeit über das Mülleimer-Symbol (🗑️) in der Toolbar möglich." : "Manual Table Clear: Full table clearing remains available at any time via the toolbar trash button (🗑️).", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
                
                Divider()

                // Version 4.3.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.3.0")
                            .font(.headline)
                            .bold()
                        Text("(Build 500)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Automatische Beantwortung eingehender Anrufe: Erkennt direkte Anrufe auf das eigene Rufzeichen (<MYCALL> <THEIRCALL> <GRID/RPRT>) und beantwortet diese mit höchster Priorität, sofern die Station die konfigurierten DX- und Gearbeitet-Filter passiert." : "Auto-Answer Inbound Callers: Detects direct incoming calls to your callsign (<MYCALL> <THEIRCALL> <GRID/RPRT>) and answers them with top priority if they pass your active DX and worked filters.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Automatischer Cooldown-Bypass für aktive Anrufer: Befindet sich eine Station in der Sperrzeit (Cooldown), ruft uns nun jedoch aktiv an, wird die Sperrzeit sofort aufgehoben und das QSO gestartet." : "Automatic Cooldown Bypass for Returning Callers: If a station in cooldown quarantine actively calls you, the cooldown is immediately lifted and the QSO is initiated.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Konfigurierbare Betriebsoption: Ein-/Ausschaltbar unter Einstellungen → Auto QSO Optionen mit zweisprachiger Unterstützung (DE/EN)." : "Configurable Operation Option: Toggle under Settings → Auto QSO Options with full bilingual support (DE/EN).", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
                
                Divider()

                // Version 4.2.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.2.0")
                            .font(.headline)
                            .bold()
                        Text("(Build 498)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Durchsuchbare Einstellungen & Hilfebereich: Integrierte Echtzeit-Suche in den Einstellungs- und Hilfe-Fenstern mit zweisprachiger Volltext-Indexierung (DE/EN), dynamischer Live-Filterung der Seitenleiste und automatischer Kategorie-Auswahl." : "Searchable Settings & Help: Real-time search across Settings and Help dialogs with deep bilingual keyword indexing (DE/EN), live sidebar filtering, and dynamic section auto-selection.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Priorisiertes Vordergrund-Layering auf Karten: Die gerufene Station (⚡) und aktive QSO-Großkreispfade werden auf der 2D-Ausbreitungskarte und dem 3D-Globus garantiert immer über den allgemeinen Länder-Aktivitätsbadges und Grid-Markern dargestellt." : "Foreground Called Station Layering: Called station markers (⚡) and active QSO great-circle paths are guaranteed to render in the foreground above background country activity badges and grid markers.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Optimiertes Map-Rendering: Entfernung von Metal-Texturlayer-Kollisionen (.drawingGroup) für absolut flüssiges Pan/Zoom und verlässliche CoreAnimation-Z-Index-Hierarchie." : "Optimized Map Layering: Removed Metal drawingGroup layer promotion overrides for smooth panning/zooming and rock-solid z-index layering.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
                
                Divider()

                // Version 4.1.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.1.1")
                            .font(.headline)
                            .bold()
                        Text("(Build 494)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Konfiguration & Einstellungen in SQLite-Datenbank: Sämtliche App-Einstellungen, Filter-Regeln, UDP/Telnet/Cluster-Konfigurationen, Farbschemata und UI-Optionen werden nun persistent in der SQLite-Datenbank (`autoqso_log.sqlite`) gespeichert und in Echtzeit synchronisiert." : "Configuration & Settings in SQLite Database: All application settings, filter rules, UDP/Telnet/Cluster configurations, color themes, and UI options are now persistently stored in the SQLite database (`autoqso_log.sqlite`) with real-time synchronization.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Nahtlose iCloud & Multi-Geräte Synchronisation: Beim Wechsel des Speicherorts oder Synchronisieren via iCloud Drive werden alle Konfigurationen automatisch aus der Datenbank geladen und übernommen." : "Seamless iCloud & Multi-Device Sync: When changing the storage location or syncing via iCloud Drive, all configurations are automatically loaded and applied from the database.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Präzise Trennlinien-Wiederherstellung (Kompaktmodus): Beim Verlassen des Kompaktmodus werden alle Trennlinien (Log-Konsole, Most-Wanted-Panel) und Seitenleistenbreiten exakt auf die zuvor eingestellten Maße zurückgesetzt." : "Precise Split Divider Restoration (Compact Mode): Exiting compact mode cleanly restores all inner window dividers (Log Console, Most Wanted Panel) and sidebar widths to their saved dimensions.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Robuster Installer mit Administrator-Rechten: `AutoQSO Installer.app` und `Install AutoQSO.command` fordern bei geschützten Zielverzeichnissen (z. B. `/Applications/AFU`) automatisch erweiterte Rechte an, um bestehende Versionen sauber zu ersetzen." : "Robust Installer Privilege Elevation: Both `AutoQSO Installer.app` and `Install AutoQSO.command` request administrator privileges on protected destination directories (e.g. `/Applications/AFU`) to cleanly overwrite existing versions.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
                
                Divider()

                // Version 4.1.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.1.0")
                            .font(.headline)
                            .bold()
                        Text("(Build 478)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "VIP: Erlaubte Maidenhead-Grids Filter: Neuer Filter für Einzel-Grids (`DN71`), Bounding-Box Bereiche (`DN61-DN74`, `KN64-KN71`) und Listen (`DN61-DN74, EN10`) mit sofortigem VIP-Pass bei Treffer und neutraler Weiterleitung an nachfolgende Filter bei Nicht-Treffer." : "VIP: Allowed Maidenhead Grids Filter: Dedicated filter for single grids (`DN71`), bounding-box ranges (`DN61-DN74`, `KN64-KN71`), and lists (`DN61-DN74, EN10`) with instant VIP pass on match and clean passthrough to next filters on non-match.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Sortierbare Filter-Pipeline & First-Match Boolean-Logik: Alle 12 Filter-Sektionen der rechten Seitenleiste sind per Drag & Drop (`☰`) in beliebiger Reihenfolge anordenbar. Die Auswertung erfolgt sequentiell von oben nach unten (First-Match)." : "Sortable Filter Pipeline & First-Match Boolean Logic: All 12 filter sections in the right sidebar can be freely reordered via drag & drop (`☰`). Evaluation proceeds sequentially from top to bottom (First-Match).", font: .subheadline, color: .secondary)
                        bullet(isDe ? "VIP-First Standard-Reihenfolge & Umschalt-Presets (Default vs. Custom): Das Default-Preset platziert VIP-Ausnahmen (Grids, Rufzeichen, Länder) an Position 1–3 über Makro-Ländersperren, sodass Ausnahmen sofort greifen. Umschalter wechselt nahtlos zwischen Default und Custom." : "VIP-First Standard Order & Presets (Default vs. Custom): The Default preset places VIP exceptions (Grids, Calls, Countries) on positions 1–3 above general country blocks for instant exception overrides. Presets toggle seamlessly.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Echtzeit Filter-Tracing im System-Log: Checkbox „Filter-Tracing“ im Reiter System-Logs protokolliert jede Filter-Entscheidung live mit Farbcodierung (✅ Grün = PASS, ❌ Rot = DROP), Sektions-Position und Begründung." : "Real-Time Filter Tracing in System Log: “Filter Tracing” checkbox in the System Logs tab logs live filter decisions with color-coded status (✅ PASS, ❌ DROP), section index, and matching rule details.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Strikte CTY.DAT DXCC-Ländertrennung: Ländersperren (z. B. United States / USA) trennen eigenständige DXCC-Inseln und -Gebiete (Puerto Rico KP4, Alaska KL7, Hawaii KH6, Guam KH2, Virgin Islands KP2) sauber vom US-Festland ab." : "Strict CTY.DAT DXCC Entity Separation: Country filters strictly separate autonomous DXCC entities (Puerto Rico KP4, Alaska KL7, Hawaii KH6, Guam KH2, Virgin Islands KP2) from mainland USA.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Automatischer QSO-Abbruch ohne Cooldown (HaltTx): Antwortet eine angerufene Station einer anderen Gegenstation, stoppt AutoQSO die Sendung via HaltTx sofort, verzichtet auf eine Cooldown-Sperre und wartet direkt auf den nächsten Trigger." : "Automatic QSO Abort without Cooldown (HaltTx): If a called target station is answered by another station, AutoQSO halts transmission immediately via HaltTx, skips cooldown quarantine, and stands ready for the next trigger.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(8)
                
                Divider()

                // Version 4.0.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.0.1")
                            .font(.headline)
                            .bold()
                        Text("(Build 459)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Fehlerbehebungen & Verbesserungen" : "✨ Bug Fixes & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Visuelle Hilfegrafiken & optimiertes Fensterlayout: Das Hilfefenster wurde auf 860 × 620 px vergrößert und um anschauliche UI-Grafiken für Toolbar, Auto-Sende-Schalter, Tabellen-Farblegende und Live-Statusbanner erweitert." : "Visual Help Illustrations & Optimized Layout: Help window expanded to 860 × 620 px with native UI illustration cards for Toolbar, Auto Transmit button states, table row color legends, and live QSO status banner.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Dynamische Toolbar-Statusanzeige „Auto ON / CQ Only“: Ist die Option „Nur Stationen anrufen, die CQ rufen“ aktiv, zeigt der grüne Hauptschalter dies kompakt zweizeilig als „Auto ON / CQ Only“ an." : "Dynamic “Auto ON / CQ Only” Toolbar Badge: When CQ Only is active in settings, the green auto transmit button displays “Auto ON / CQ Only” on two compact lines without enlarging the button.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Neuer Filter „Most wanted Only“: Eigenständige Sektion in der rechten Filter-Seitenleiste mit Schalter und wählbarer Rang-Schwelle (Top 10 bis 100)." : "New “Most wanted Only” Filter: Dedicated section in the right filter sidebar with active toggle and rank threshold selector (Top 10 to 100).", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Erweiterte Dokumentation für Auto-QSO-Trigger: Umfassende Erklärungen aller Signal-Trigger, Einstellungsoptionen und der Priorisierungs-Pipeline im Hilfebereich." : "Expanded Auto QSO Triggers Documentation: Comprehensive breakdown of message triggers, operational settings, and candidate scoring order in the Help section.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Konfigurierbare UDP-Bridge Zieladresse: Volle Unterstützung für individuelle IP-Adressen (Unicast & Multicast) und Portweiterleitung inklusive dynamischer Modusanzeige (UC/MC)." : "Configurable UDP Bridge Destination: Full support for custom destination IP addresses (Unicast & Multicast) and port forwarding with dynamic UC/MC mode indicator.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Option „Nur Stationen anrufen, die CQ rufen“: Neue Einstellung unter Auto Mode Optionen, um ausschließlich aktive CQ-Rufer automatisch anzurufen." : "“Only call stations calling CQ” Option: New setting under Auto Mode Options to strictly call active CQ callers.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Struktureller FT8/FT4 Grid-Parser: Verhindert zuverlässig, dass QSO-Abschluss-Tokens wie RR73 fälschlicherweise als Maidenhead-Planquadrate interpretiert werden." : "Structural FT8/FT4 Grid Parser: Reliably distinguishes Maidenhead locators from QSO termination tokens such as RR73.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Großkreis-Pfad bei fehlendem Locator: Bei einem aktiven QSO ohne empfangenen Maidenhead-Locator wird der Großkreis (Great Circle) automatisch zum Zentrum des ermittelten Landes gezeichnet." : "Great Circle Path Fallback to Country: When no Maidenhead grid locator is received for an active QSO, the Great Circle path is automatically drawn and centered to the resolved country center.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Erweiterte Rufzeichen- & Präfix-Auflösung: Verbesserte Erkennung von Sonder- und Portabel-Rufzeichen mit Slashes (/P, /M, /MM, EA8/DL1ABC)." : "Enhanced Prefix & Callsign Resolution: Improved entity resolution for portable and slash callsigns (/P, /M, /MM, EA8/DL1ABC).", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
                
                // Version 4.0.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 4.0.0")
                            .font(.headline)
                            .bold()
                        Text("(Build 437)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Mehrsprachige Benutzeroberfläche (Deutsch & Englisch): Vollständige Lokalisierung aller Ansichten, Dialoge, Filter, Tabellenspalten und Menüs." : "Multi-Language Support (German & English): Complete native localization across all views, dialogs, filters, tables, and menus.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Dynamischer Sprachwechsel in den Einstellungen: Direkte Umschaltung zwischen System, Deutsch und English unter Einstellungen -> Sprache ohne Neustart der App." : "Dedicated Language Settings: Instant switching between System, German, and English in Settings -> Language without restarting the app.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Intelligente Einheiten- & Kontinent-Übersetzung: Vollständig synchronisierte Zeiteinheiten (Stunden/Tage/Monate/Jahre bzw. Hours/Days/Months/Years) und Kontinent-Bezeichnungen." : "Synchronized Units & Geographic Names: Localized time units (Hours/Days/Months/Years) and continent names.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Universal 2 Binary: Vollständige native Unterstützung für Apple Silicon (M1/M2/M3/M4) sowie Intel-basierte Macs (x86_64) unter macOS 14+." : "Universal 2 Binary: Native dual-architecture binary for Apple Silicon (M1/M2/M3/M4) and Intel Macs (x86_64) on macOS 14+.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()

                // Version 3.6.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.6.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Universal 2 Binary: Vollständige native Unterstützung für Apple Silicon (M1/M2/M3/M4) sowie Intel-basierte Macs (x86_64) unter macOS 14+." : "Universal 2 Binary Support: Native execution for Apple Silicon and Intel Macs (x86_64).", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Strukturierte Filter-Sidebar: Logische Neuordnung aller Filterbereiche von geografischen Kriterien (Kontinente, gesperrte/erlaubte Länder, Zonen, Rufzeichen) über Logbuch-Historie bis hin zu Signal- und Doubletten-Filtern." : "Structured Filter Sidebar: Logical reordering of filter categories from macro geography to QSO history and signal filters.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Klarere Filterbezeichnung: Der frühere „WSJT-X Spezialfilter“ heißt nun prägnant „WSJT-X CQ Filter“ (Nur CQ, RRR, RR73, 73)." : "WSJT-X CQ Filter Renaming: Renamed former special filter to concise WSJT-X CQ Filter.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Automatisierte Universal-Release-Pipeline: Das Release-Skript und der integrierte Installer bauen und paketieren automatisch universelle Mach-O-Binaries in der DMG." : "Automated Universal Release: Release pipeline automatically packages universal binaries into the DMG.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()

                // Version 3.5.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.5.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Konfigurierbarer Filter für bereits gearbeitete Stationen: Neuer Schalter in der Filter-Sidebar, der gearbeitete Stationen nach einer frei wählbaren Zeitspanne (0 bis 999 Stunden, Tage, Monate oder Jahre) wieder durchlässt und für AutoQSO freigibt." : "Configurable Worked Station Filter: New toggle in Filter Sidebar allowing worked stations to pass through and become eligible for AutoQSO after a customizable duration (0 to 999 hours, days, months, or years).", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Blitzschnelle O(1) Zeitstempel-Indexierung: AutoQSO indexiert die exakten UTC-Zeitstempel aller QSOs im SQLite-Speicher, sodass Zeitspannen-Prüfungen auch bei zehntausenden Logbucheinträgen in Nanosekunden erfolgen." : "Lightning-Fast O(1) Timestamp Indexing: AutoQSO indexes exact UTC timestamps of all QSOs in SQLite for nanosecond lookups even across tens of thousands of records.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Flexible Zifferneingabe & Einheiten-Picker: Direkte numerische Eingabe (0–999) im Textfeld kombiniert mit Stunden-, Tage-, Monate- und Jahre-Auswahl." : "Flexible Numeric Input & Unit Selector: Direct numeric entry (0–999) combined with Hours, Days, Months, and Years selection.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Vollständige Integration in Filter & Auto-Transmit: Einstellbare Wiederholungs-QSOs fließen nahtlos in die DX-Filterung, die automatische Sendeauswahl (Auto Transmit) und das Most-Wanted-Panel ein." : "Seamless Filter & Auto-Transmit Integration: Re-worked station rules seamlessly integrate into DX filtering, Auto Transmit, and Most Wanted calculations.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()

                // Version 3.4.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.4.1")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Intelligente 5-Minuten-Zeitfenster-Deduplizierung: Erkennt und verhindert doppelte QSOs durch Start- und Endzeit-Abweichungen (`TIME_ON` vs. `TIME_OFF`) zwischen WSJT-X, RUMlogNG, QRZ.com und LoTW zuverlässig in der SQLite-Datenbank." : "Intelligent 5-Minute Time Window Deduplication: Accurately detects and merges QSO records with start/end time variations (`TIME_ON` vs `TIME_OFF`) across WSJT-X, RUMlogNG, QRZ.com, and LoTW.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Automatische Logbuch-Bereinigung: Beim Programmstart werden bestehende doppelte Einträge automatisch fusioniert (fehlende Grid- und DXCC-Informationen ergänzt) und bereinigt." : "Automated Logbook Hygiene: Existing duplicates are automatically merged and enriched with missing grid locators on app startup.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "WSJT-X Doppel-Meldungs-Filter: Intelligentes Debouncing verhindert das parallele doppelte Eintragen von QSOs, wenn WSJT-X zeitgleich `loggedAdif`- und `qsoLogged`-UDP-Pakete sendet." : "WSJT-X Message Debouncing: Prevents double logging when WSJT-X sends simultaneous `loggedAdif` and `qsoLogged` UDP packets.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Präzise Popover-Verankerung auf der Grid-Karte: Das Grid-Inspector-Popover verankert sich jetzt als Karten-Annotation direkt an der exakten Zentrumskoordinate des angeklickten Planquadrats mit zielgenau ausgerichteter Sprechblase." : "Precise Grid Map Popover Anchoring: Grid Inspector attaches directly to the center coordinate of clicked squares.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Dauerhafte Verfügbarkeit der Grid-Karte: Die 2D-Kartenansicht, das Maidenhead-Gitter und der Inspector bleiben auch bei 0 neuen DX-Grids im aktuellen Zeitfenster uneingeschränkt sichtbar und interaktiv bedienbar." : "Permanent Grid Map Availability: 2D map, Maidenhead grid, and Inspector remain fully interactive even with 0 new DX spots.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Automatische Länderauflösung im Grid-Inspector: Rufzeichen gearbeiteter Grids werden automatisch über den Prefix-Matcher in lesbare Ländernamen (statt numerischer DXCC-IDs) aufgelöst." : "Automatic Country Resolution: Callsigns in worked grids are converted into readable country names via prefix matcher.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Aufgeräumte Toolbar: Das Textfeld für die Minutensperre wurde aus der Haupt-Toolbar entfernt und wird nun übersichtlich in den Einstellungen (WSJT-X) verwaltet." : "Cleaned-Up Toolbar: Minute cooldown field moved to Settings (WSJT-X).", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.4.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.4.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "RUMlogNG AppleScript-Integration: Direkte 1-Klick-Synchronisation des Logbuchs aus der laufenden macOS App RUMlogNG über die native AppleScript-Schnittstelle (`ReadAdif`) – sowohl inkrementell als auch vollständig ab 1900." : "RUMlogNG AppleScript Integration: 1-click sync directly from running macOS RUMlogNG app via AppleScript (`ReadAdif`).", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Umschaltbare Logbuch-Quellen: Flexibler Segmented-Picker in den Einstellungen zum Umschalten zwischen RUMlogNG, ARRL LoTW und QRZ.com inklusive automatischem Post-QSO-Sync für die aktive Quelle." : "Switchable Logbook Sources: Toggle between RUMlogNG, ARRL LoTW, and QRZ.com with auto post-QSO sync.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Aktives QSO auf Ausbreitungskarte zentriert: Automatische Zentrierung und optimale Skalierung des Großkreis-Pfads (Great Circle) auf 2D-Karte und 3D-Globus bei jedem aktiven QSO, inklusive 1-Klick Re-Zentrierung über den Status-Banner." : "Active QSO Centering: Great Circle path auto-centered on 2D map and 3D globe during active QSOs.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Dual-Installer Release-DMG: Bereitstellung von nativer GUI-Installer-App (`AutoQSO Installer.app`) und Terminal-Installationsskript (`Install AutoQSO.command`) im Release-Image." : "Dual-Installer DMG: Includes native macOS GUI Installer app and terminal command script.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Quickstart Direktsprung-Routing: Direkte Sprungbuttons aus den 4 Quickstart-Schritten zu den jeweiligen Einstellungs-Tabs (Rufzeichen/Telnet, QTH-Locator, UDP-Server, Logbuch-Sync)." : "Quickstart Direct Navigation: 1-click shortcut buttons from Quickstart to respective Settings tabs.", font: .subheadline, color: .secondary)
                        
                        Text(isDe ? "🐞 Fehlerbehebungen & Leistungsverbesserungen" : "🐞 Bugfixes & Performance")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet(isDe ? "Crash-Fix Auto-Scroll: Behebung eines Out-of-Bounds-Absturzes beim automatischen Tabellen-Scrollen durch Umstellung auf asynchrones Viewport-Scrolling (`clipView.scroll(to:)`)." : "Auto-Scroll Crash Fix: Resolved out-of-bounds crash via async viewport scrolling.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "macOS Automation-Permissions: `NSAppleEventsUsageDescription` und automatisches Ad-hoc-Codesigning in allen Build-Skripten integriert." : "macOS Automation Permissions: Integrated `NSAppleEventsUsageDescription` and auto code-signing.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.3.2
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.3.2")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Nativer macOS GUI-Installer: Grafische Installer-App (`AutoQSO Installer.app`) direkt im `.dmg` ersetzt das Terminal-Skript. Bietet komfortable Zielordner-Auswahl, Gatekeeper-Quarantäne-Entfernung (`xattr -cr`), Code-Signatur-Auffrischung und Sofortstart." : "Native macOS GUI Installer: Graphical installer app in DMG with destination picker, Gatekeeper quarantine removal (`xattr -cr`), and instant launch.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Interaktiver Grid-Inspector: Ein Klick auf ein beliebiges Grid-Feld auf der Karte öffnet ein Detail-Popover mit Status (gearbeitet/ungearbeitet), Peilung/Distanz, aktiven Stationen und QRZ.com-Aufruf." : "Interactive Grid Inspector: Click any grid square for worked status, bearing/distance, stations, and QRZ lookup.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Band-Schnellfilter auf Grid-Map: Horizontale Filter-Pill-Leiste (`ALL`, `160M`–`6M`) zum sofortigen Umschalten der angezeigten Grids und Map-Marker nach dem aktiven Band." : "Band Quick Filters: Pill selector (`ALL`, `160M`–`6M`) for instant band-specific grid filtering.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Peilung & Distanz (Beam Heading / Distance): Anzeige von Azimut und Großkreis-Entfernung bezogen auf das eigene Heimat-QTH (`🧭 285° · 4.210 km`) direkt in jeder Grid-Zeile." : "Beam Heading & Distance: Azimuth and great-circle distance relative to home QTH in each row.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Spot-Frische & Age-Decay: Brandneue Spots (< 3 Min.) werden mit `⚡ NEU`-Badge und leuchtender Umrandung hervorgehoben; ältere Spots (> 10 Min.) blenden dezent ab." : "Spot Freshness Decay: Fresh spots (< 3 min) glow with `⚡ NEW` badge; older spots fade gracefully.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Kompakt- / Detail-Umschalter: Umschaltbare Grid-Sidebar zwischen einer platzsparenden 1-Zeilen-Übersicht und einer ausführlichen Detailansicht mit Stationen und Zeiten." : "Compact / Detail Toggle: Switchable sidebar between 1-line summary and comprehensive station cards.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Pixel-dynamische Maidenhead-Zoomstufen: Das Maidenhead-Gitter berechnet die tatsächliche Pixelgröße der Zellen; Umschaltung auf feinere Stufen erfolgt erst bei ausreichender Pixelbreite (kein Zupflastern der Karte)." : "Adaptive Pixel Grid Zoom: Scales from 2-char to 8-char resolution based on actual on-screen pixel size.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Getrennte Reset-Buttons: Unabhängige Werkseinstellungs-Buttons für Listen-Ansicht und Karten-Ansicht in den Einstellungen." : "Independent Reset Buttons: Separate factory reset buttons for table and map customization.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Cluster Spots in Haupttabelle: Vollständige Anzeige und Farbkodierung von DX Cluster Spots in der Haupttabelle mit Spotter-Spalte und Spotter-Filterung." : "Cluster Spots in Main Table: Full color-coded display of DX cluster spots with spotter filtering.", font: .subheadline, color: .secondary)
                        
                        Text(isDe ? "🐞 Fehlerbehebungen & Leistungsverbesserungen" : "🐞 Bugfixes & Performance")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet(isDe ? "Behebung des UI-Hangs beim Spaltenverschieben: Korrektur der SwiftUI-Tabellenstruktur zur Beseitigung von Deadlocks beim Umordnen von Spalten." : "Fixed Column Reordering Hang: Resolved UI deadlocks during drag-and-drop column rearrangement.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Schnelles Tabellen-Rendering: O(1) Cache-Evaluierung für Zellenfarben beseitigt Ruckeln beim schnellen Scrollen." : "Fast Table Rendering: O(1) cached color evaluation eliminates scroll stutter.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Karten-Performance: Entkopplung der Map-Sidebars via EquatableView (keine Re-Layouts bei Pan/Zoom) und Beseitigung synchroner I/O im Canvas-Rendering." : "Map Performance: EquatableView sidebar decoupling eliminates re-layout cycles during pan/zoom.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.3.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.3.1")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "3D-Globus-Projektion & Maidenhead-Gitter: Maidenhead-Grid-Linien und gearbeitete 4-Stellen Planquadrate werden in der 3D-Globusansicht nativ als 3D-Polylines und 3D-Polygone auf die Erdkugel projiziert." : "3D Globe Projection: Maidenhead grid lines and worked squares projected onto interactive 3D sphere.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Aktiver QSO-Pfad auf Ausbreitungskarte: Zeichnet bei einem aktiven WSJT-X Anruf/QSO eine leuchtend gelbe Großkreis-Verbindungslinie zwischen eigenem QTH (minimalistisches 🏠 Symbol) und der Zielstation auf der 2D-Karte und dem 3D-Globus inklusive Live-Statusbanner (⚡ AKTIVES QSO)." : "Active QSO Great Circle Path: Displays glowing connection line from home QTH to target station.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Einstellungsbereich Eigenes QTH & Interaktiver QTH Picker: Neuer Einstellungsreiter 'Eigenes QTH (Maidenhead)' (max. 8-Stellen-Präzision) mit Echtzeit-Standortanalyse und nativer interaktiver Karte (InteractiveQTHPickerView) mit Google-Style Drop-Pin." : "Home QTH Settings & Picker: Up to 8-character locator resolution with interactive map and drop-pin.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Interaktiver Installer & macOS Gatekeeper Lösung: Doppelklickbares Skript (`Install AutoQSO.command`) direkt im `.dmg`, das den Zielordner abfragt, Quarantäne-Attribute entfernt und AutoQSO startet." : "Interactive Installer: Automates installation and quarantine clearance.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Kompaktmodus Toolbar-Schaltflächen: Alle 6 Icon-Buttons (Logbuch, Ausbreitungskarte, Grid-Map, Normalmodus, Einstellungen, Hilfe) sind jetzt direkt in der Toolbar des Kompaktmodus verfügbar." : "Compact Mode Toolbar: Access Logbook, Propagation Map, Grid Map, Normal View, Settings, and Help.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Kartenstil Dropdown-Menü: Neues kompaktes, kontrastreiches Dropdown-Menü (.ultraThinMaterial Pill) für alle Kartenansichten ohne störende Text-Labels." : "Map Style Menu: Compact translucent pill dropdown for MapKit styles.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.3.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.3.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Schattierung gearbeiteter Grids: Umschaltbare farbige Unterlegung (`checkmark.square`) aller im Logbuch vorhandenen 4-Stellen-Grids auf der Maidenhead Grid-Map mit anpassbarem Farbton (Standard: `#FF5926` Rot-Orange)." : "Worked Grid Shading: Highlights all worked 4-character grids on the map with customizable tint.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Interaktives Grid-Logbuchfenster: Einzelklick auf ein beliebiges gearbeitetes Grid-Feld auf der Karte öffnet ein Detailfenster (WorkedGridDetailView) mit allen im Logbuch gespeicherten QSOs für diesen Maidenhead-Locator inklusive Such- und Filterfunktion." : "Worked Grid History: Single-click on any worked square displays all logged QSOs for that locator.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Doppelklick QRZ.com-Aufruf: Doppelklick auf eine Station im Grid-Logbuchfenster öffnet direkt deren QRZ.com-Detailseite im Browser." : "Double-Click QRZ Lookup: Instantly opens callsign profile on QRZ.com with connection checks.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Vollständiger Logbuch-Sync (ab 1900): QRZ.com und LoTW Sync laden bei Bedarf das gesamte Logbuch ab 1900 herunter. Intelligentes SQLite-Upsert (ON CONFLICT DO UPDATE) reichert bestehende QSOs nachträglich mit fehlenden Grid-Locatoren an, ohne Duplikate zu erzeugen." : "Full Logbook Sync (since 1900): Downloads complete history and enriches missing locators via SQLite upsert.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Maidenhead Grid-Filter (4 & 6 Stellen): Neue Filterregeln zum gezielten Filtern nach bisher ungearbeiteten 4-Stellen (`JO31`) und 6-Stellen (`JO31AA`) Maidenhead-Lokaltoren." : "Maidenhead Grid Filters: Filter decodes for unworked 4-char (`JO31`) and 6-char (`JO31AA`) squares.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Neue Maidenhead Grid-Map: Separates interaktives Kartenfenster (`Grid-Map ↗`) zur Visualisierung aller ungearbeiteten 4-Stellen (grün) und 6-Stellen (blau) Grids." : "Maidenhead Grid Map: Interactive window displaying unworked 4-char (green) and 6-char (blue) squares.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                                
                Divider()
                                
                // Version 3.2.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.2.1")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isDe ? "✨ Neue Funktionen & Verbesserungen" : "✨ New Features & Improvements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Freeze-Snapshot-Modus: Pause-Button friert die Dekodierliste & Protokolle mit einem statischen Snapshot ein. Hintergrunddaten werden weiter empfangen; das freie Scrollen in historischen Daten ist ohne automatisches Zurückspringen möglich." : "Freeze Snapshot Mode: Pause button takes a static snapshot of decode tables and logs without pausing background reception.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Echtzeit-Suchfeld: Neue Suchfelder in der Hauptleiste und Log-Konsole filtern Einträge in Echtzeit nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text." : "Real-Time Search: Live search in main toolbar and log console by callsign, country, spotter, grid, or text.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Vollständige Tabellenanzeige & Farbkodierung: Alle empfangenen Decodes und DX-Spots erscheinen in der Haupttabelle. Filter-Regeln steuern die farbliche Hervorhebung (z.B. Grau für blockiert) und automatische Aktionen." : "Full Table Display & Color Coding: All decodes and DX spots shown; filter rules apply intelligent highlights without deleting data.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Universelles Spot-Parsing: Unterstützung für DX-Spots aller gängigen Cluster-Knotentypen (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider)." : "Universal Spot Parsing: Automatic parsing for VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, and DXSpider nodes.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.2.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.2.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isDe ? "⚡ Performance & UI/UX Optimierungen" : "⚡ Performance & UI/UX Enhancements")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Flüssige UI-Updates: Debouncing von Decodes und Cluster-Spots um 300ms verhindert UI-Ruckler während dichter FT8-Decode-Bursts." : "Smooth UI Updates: 300ms burst debouncing prevents UI lag during heavy FT8 cycles.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Schneller App-Start: Das Parsen der CTY.DAT-Länderdatenbank wurde in den Hintergrund verlagert und blockiert nicht mehr den Start der Anwendung." : "Fast Startup: Background parsing of CTY.DAT country database.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Optimierte Log-Anzeige: Umstellung der System- und WSJT-X-Konsolen auf LazyVStack spart signifikant Rendering-Zeit für Offscreen-Texte." : "Optimized Log Console: LazyVStack reduces memory and rendering overhead.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.1.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.1.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isDe ? "🗺️ Ausbreitungskarte & DX Cluster Integration" : "🗺️ Propagation Map & DX Cluster Integration")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Ausbreitungskarte (Propagation Map): Vollständige Live-Visualisierung von Spots und Decodes auf einer Weltkarte." : "Propagation Map: Full live visualization of spots and decodes on a world map.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Persistente Spot-Auswahl: Manuell selektierte Spots bleiben im Info-Banner permanent sichtbar." : "Persistent Selection: Manually selected stations stay pinned in the detail banner.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Zentriertes Konsolen-Layout: Segment-Umschalter für die Log-Tabellen exakt zentriert." : "Centered Console Layout: Clean segmented control in log console.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Sende-Schalter: Hauptschalter kompakt benannt als \"Auto ON\" / \"Auto OFF\"." : "Auto Transmit Toggle: Clean \"Auto ON\" / \"Auto OFF\" switch.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 3.0.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.0.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isDe ? "🌐 Losgelöste Logs, DX Cluster Manager & Layout-Flexibilität" : "🌐 Detachable Logs, DX Cluster Manager & Layout Options")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Losgelöste Log-Konsole: Das Diagnosefenster lässt sich abkoppeln und dockt beim Schließen wieder im Hauptfenster an." : "Detachable Log Console: Open logs in standalone window with auto-docking.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Integrierter Cluster-Manager: Hinzufügen, Editieren, Löschen und per Drag-and-Drop Sortieren von Clustern in den Einstellungen." : "DX Cluster Manager: Add, edit, delete, and reorder cluster nodes via drag and drop.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Telnet Server Splittung: DX Cluster und Telnet Server sind eigenständige Abschnitte." : "Telnet Server Architecture: Split DX cluster clients and Telnet server into modular sections.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "ADIF Datei Import: Bequemer Import von QSOs via `.adi`/`.adif`-Dateien direkt über die Einstellungen." : "ADIF File Import: Direct import of `.adi`/`.adif` logbooks with duplicate checks.", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Ansichtsoptionen: Freie Wahl der chronologischen Sortierung, Farbschemas (Hell/Dunkel/System) sowie anpassbare Farben und Schriftgrößen." : "Appearance Customizer: Dark/Light modes, custom fonts, and colors.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 2.0.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 2.0.0")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isDe ? "🔥 Most Wanted & Entfernungspriorisierung" : "🔥 Most Wanted & Distance Prioritization")
                            .font(.subheadline)
                            .bold()
                        bullet(isDe ? "Club Log Top 100 Most Wanted DXCC integriert (P5, KH3, KH7K, CE0X, FT/X, 3Y/B, etc.)" : "Club Log Top 100 Most Wanted DXCC integration (P5, KH3, KH7K, CE0X, FT/X, 3Y/B, etc.)", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Rote Hervorhebung (🔥 #Rang) in der Decodier-Tabelle für ungearbeitete Most Wanted Stationen" : "Red highlight (🔥 #Rank) in table for unworked rare entities", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Gesondertes Most-Wanted-Panel unterhalb der Tabelle" : "Dedicated Most Wanted panel below table", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Maidenhead Locator → Großkreis-Entfernung (km) via Haversine-Formel" : "Maidenhead Locator → Great Circle distance (km) calculation", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                
                Divider()
                
                // Version 1.0.0
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version 1.0.0")
                        .font(.headline)
                        .bold()
                    VStack(alignment: .leading, spacing: 4) {
                        bullet(isDe ? "Auto QSO Trigger für CQ, 73, RR73 und RRR Decodes" : "Auto QSO triggers for CQ, 73, RR73, and RRR decodes", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Inkrementeller LoTW & QRZ Sync" : "Incremental LoTW & QRZ logbook sync", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Duplicate Prevention via SQLite uniqueKey" : "Duplicate prevention via SQLite unique keys", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Freie Speicherort-Wahl & iCloud Drive Sync" : "Custom storage location & iCloud Drive sync", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Einstellungen mit linker Sidebar-Navigation" : "Settings window with sidebar navigation", font: .subheadline, color: .secondary)
                        bullet(isDe ? "Hilfe-Fenster mit Seitenleiste" : "Help & documentation window with sidebar", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
            }
            
        case .copyright:
            VStack(alignment: .leading, spacing: 12) {
                Text(isDe ? "Copyright & Urheberrecht" : "Copyright & License")
                    .font(.title)
                    .bold()
                VStack(alignment: .leading, spacing: 8) {
                    Text("AutoQSO — DX-Filter and Automated FT8/FT4 QSO Manager")
                        .font(.headline)
                    Text("Copyright (c) Georg Isenbürger - DJ6GI")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text(isDe ? "Alle Rechte vorbehalten." : "All rights reserved.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }
        }
    }

    private func sendSupportEmail() {
        let isDe = langManager.isGerman
        let recipient = "support@autoqso.app"
        let subject = isDe ? "AutoQSO Support Anfrage - v\(APP_VERSION)" : "AutoQSO Support Request - v\(APP_VERSION)"
        
        // System & Hardware Details ermitteln
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let hostName = Host.current().localizedName ?? Host.current().name ?? (isDe ? "Unbekannter Mac" : "Unknown Mac")
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemoryGB = String(format: "%.1f GB", Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024))
        
        #if arch(arm64)
        let architecture = "Apple Silicon (arm64)"
        #else
        let architecture = "Intel (x86_64)"
        #endif

        let bodyText = isDe ? """
        Hallo AutoQSO Support-Team,

        [Bitte beschreibe hier dein Anliegen oder Problem]


        --------------------------------------------------
        SYSTEM INFORMATIONEN (Automatisch generiert)
        --------------------------------------------------
        App Version:      AutoQSO v\(APP_VERSION) (Build \(APP_BUILD_NUMBER))
        macOS Version:    \(osVersion)
        Gerätename:       \(hostName)
        Architektur:      \(architecture)
        CPU Kerne:        \(processorCount)
        Arbeitsspeicher:  \(physicalMemoryGB)
        --------------------------------------------------
        """ : """
        Hello AutoQSO Support Team,

        [Please describe your inquiry or issue here]


        --------------------------------------------------
        SYSTEM DIAGNOSTICS (Automatically Generated)
        --------------------------------------------------
        App Version:      AutoQSO v\(APP_VERSION) (Build \(APP_BUILD_NUMBER))
        macOS Version:    \(osVersion)
        Device Name:      \(hostName)
        Architecture:     \(architecture)
        CPU Cores:        \(processorCount)
        RAM:              \(physicalMemoryGB)
        --------------------------------------------------
        """

        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = bodyText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let mailToURL = URL(string: "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)") else {
            return
        }

        NSWorkspace.shared.open(mailToURL)
    }

    private func bullet(_ text: String, font: Font = .body, color: Color = .primary) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(font)
                .foregroundColor(.secondary)
            Text(LocalizedStringKey(text))
                .font(font)
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
        }
    }

    private func numberedItem(_ number: String, _ text: String, font: Font = .body, color: Color = .primary) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(number)
                .font(font)
                .foregroundColor(.secondary)
            Text(LocalizedStringKey(text))
                .font(font)
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
        }
    }

    private func iconBullet(icon: String, text: String, font: Font = .body, color: Color = .primary) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(font)
                .foregroundColor(.accentColor)
                .frame(width: 20, alignment: .center)
            Text(LocalizedStringKey(text))
                .font(font)
                .foregroundColor(color)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Visuelle Hilfe-Grafiken / UI Illustrations

    private func toolbarIllustrationCard(isDe: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isDe ? "🖼️ Visuelle Toolbar-Übersicht:" : "🖼️ Visual Toolbar Overview:")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                // Linke Sidebar
                Image(systemName: "sidebar.left")
                    .padding(5)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
                
                // Auto Transmit Button
                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                    VStack(alignment: .leading, spacing: -1) {
                        Text("Auto ON").font(.system(size: 9, weight: .bold))
                        Text("CQ Only").font(.system(size: 7, weight: .semibold))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(5)
                
                // Sortierung & Pause
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                    Image(systemName: "pause.circle")
                }
                .padding(4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                
                // Suchfeld
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.caption2)
                    Text(isDe ? "Suchen..." : "Search...").font(.caption2).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                .frame(maxWidth: 120)
                
                Spacer()
                
                // Rechte Buttons
                HStack(spacing: 6) {
                    Image(systemName: "book")
                    Image(systemName: "map")
                    Image(systemName: "square.grid.3x3.topleft.filled")
                    Image(systemName: "gearshape")
                    Image(systemName: "questionmark.circle")
                    Image(systemName: "sidebar.right")
                }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        }
        .padding(10)
        .background(Color.blue.opacity(0.04))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.15), lineWidth: 1))
    }

    private func autoModeButtonsIllustrationCard(isDe: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isDe ? "🖼️ Auto-Sende-Schalter (Zustände im Vergleich):" : "🖼️ Auto Transmit Button States Comparison:")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                // 1. Normaler Auto-Modus
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text("Auto ON").fontWeight(.bold)
                    }
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    
                    Text(isDe ? "Alle CQs & 73s" : "All CQs & 73s")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                // 2. CQ-Only Modus (Zweizeilig)
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        VStack(alignment: .leading, spacing: -1) {
                            Text("Auto ON").font(.system(size: 10, weight: .bold))
                            Text("CQ Only").font(.system(size: 8, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    
                    Text(isDe ? "Nur echte CQs" : "Only Active CQs")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                // 3. Ausgeschaltet
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle")
                        Text("Auto OFF").fontWeight(.bold)
                    }
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(6)
                    
                    Text(isDe ? "Deaktiviert" : "Disabled")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.04))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.15), lineWidth: 1))
    }

    private func tableRowsIllustrationCard(isDe: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isDe ? "🖼️ Farbliche Kennzeichnung in der Dekodiertabelle:" : "🖼️ Decode Table Color Highlights & Badges:")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
            
            VStack(spacing: 4) {
                // 1. Most Wanted
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill").font(.system(size: 9))
                        Text("#1").font(.system(size: 9, weight: .bold))
                    }
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(Color.red).foregroundColor(.white).cornerRadius(3)
                    
                    Text("14:05:00").font(.system(size: 10, design: .monospaced))
                    Text("P5/DJ6GI").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.red)
                    Text(isDe ? "Nordkorea" : "North Korea").font(.system(size: 10)).foregroundColor(.secondary)
                    Spacer()
                    Text("CQ P5/DJ6GI PM49").font(.system(size: 10, design: .monospaced))
                    Text(isDe ? "Most Wanted (#1)" : "Most Wanted (#1)").font(.system(size: 9, weight: .semibold)).foregroundColor(.red)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.red.opacity(0.1)).cornerRadius(4)
                
                // 2. CQ Kandidat
                HStack(spacing: 6) {
                    Text("CQ").font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.green).foregroundColor(.white).cornerRadius(3)
                    
                    Text("14:05:15").font(.system(size: 10, design: .monospaced))
                    Text("OZ/DJ6GI").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.green)
                    Text(isDe ? "Dänemark" : "Denmark").font(.system(size: 10)).foregroundColor(.secondary)
                    Spacer()
                    Text("CQ DX OZ/DJ6GI JO45").font(.system(size: 10, design: .monospaced))
                    Text(isDe ? "AutoQSO Kandidat" : "AutoQSO Target").font(.system(size: 9, weight: .semibold)).foregroundColor(.green)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.1)).cornerRadius(4)
                
                // 3. Gearbeitet
                HStack(spacing: 6) {
                    Text("14:05:30").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
                    Text("DL1ABC").font(.system(size: 11, design: .monospaced)).foregroundColor(.red.opacity(0.6))
                    Text(isDe ? "Deutschland" : "Germany").font(.system(size: 10)).foregroundColor(.secondary)
                    Spacer()
                    Text("G4XYZ DL1ABC 73").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
                    Text(isDe ? "Bereits gearbeitet" : "Worked on band").font(.system(size: 9)).foregroundColor(.secondary)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.secondary.opacity(0.04)).cornerRadius(4)
                
                // 4. Blockiert
                HStack(spacing: 6) {
                    Text("14:05:45").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary.opacity(0.6))
                    Text("EA8XYZ").font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary.opacity(0.5))
                    Text(isDe ? "Kanarische Inseln" : "Canary Islands").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.6))
                    Spacer()
                    Text("CQ EA8XYZ IL18").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary.opacity(0.5))
                    Text(isDe ? "Durch Filter blockiert" : "Blocked by Filter").font(.system(size: 9)).foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.secondary.opacity(0.02)).cornerRadius(4)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
    }

    private func activeQSOPathIllustrationCard(isDe: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isDe ? "🖼️ Live QSO-Status-Banner & Großkreis-Pfad (2D-Karte & 3D-Globus):" : "🖼️ Live QSO Status Banner & Great Circle Path (2D Map & 3D Globe):")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
            
            // Live Status Banner Mockup
            HStack(spacing: 10) {
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("OZ/DJ6GI").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.yellow)
                Text(isDe ? "Dänemark" : "Denmark").font(.system(size: 10)).foregroundColor(.secondary)
                Divider().frame(height: 12)
                Text("JO45").font(.system(size: 10, weight: .semibold, design: .monospaced))
                Divider().frame(height: 12)
                Text("485 km").font(.system(size: 10, weight: .bold))
                Divider().frame(height: 12)
                Text("🧭 012°").font(.system(size: 10))
                Spacer()
                Text("TX BEREIT").font(.system(size: 9, weight: .bold)).padding(.horizontal, 5).padding(.vertical, 2).background(Color.green).foregroundColor(.white).cornerRadius(3)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.85))
            .foregroundColor(.white)
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow.opacity(0.5), lineWidth: 1))
        }
        .padding(10)
        .background(Color.yellow.opacity(0.04))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
    }
}
