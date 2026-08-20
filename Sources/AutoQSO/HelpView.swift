import SwiftUI
import AppKit

enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Übersicht"
    case quickstart = "Quickstart"
    case toolbar = "Toolbar & Bedienung"
    case wsjtx = "WSJT-X Setup"
    case triggers = "Auto QSO Triggers"
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
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .quickstart: return "bolt.circle"
        case .toolbar: return "command"
        case .wsjtx: return "antenna.radiowaves.left.and.right"
        case .triggers: return "bolt.horizontal"
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
}

struct HelpView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var selectedSection: HelpSection = .overview
    
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
            VStack(alignment: .leading, spacing: 6) {
                List(HelpSection.allCases, selection: $selectedSection) { section in
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .foregroundColor(selectedSection == section ? .accentColor : .secondary)
                            .frame(width: 18)
                        Text(section.rawValue)
                            .font(.body)
                    }
                    .tag(section)
                }
                .listStyle(.sidebar)
                
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
            .frame(width: 210)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content View
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    detailView(for: selectedSection)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 720, height: 540)
    }

    @ViewBuilder
    private func detailView(for section: HelpSection) -> some View {
        switch section {
        case .overview:
            VStack(alignment: .leading, spacing: 12) {
                Text("System-Übersicht")
                    .font(.title2)
                    .bold()
                Text("AutoQSO ist eine macOS-Anwendung für Funkamateure. Die **Hauptfunktion ist der DX-Filter** zur intelligenten Auswertung, Klassifizierung und Filterung von Spots und Dekodierungen. **Für WSJT-X steht die automatisierte Auto QSO Sende-Engine** zur Verfügung.")
                    .font(.body)
                
                // Quickstart Callout
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Neu bei AutoQSO? Schnellstart in 4 Schritten:")
                            .font(.headline)
                        Text("Erfahre, welche Mindesteinstellungen (Rufzeichen, QTH, WSJT-X, Logbuch) du für den Betrieb benötigst.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Quickstart öffnen") {
                        selectedSection = .quickstart
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(12)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.3), lineWidth: 1))
                
                Text("Hauptfunktionen:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    bullet("DX-Filter (Hauptfunktion): Intelligente Auswertung, Klassifizierung & Weiterleitung von DX-Spots & Decodes")
                    bullet("Auto QSO für WSJT-X: Automatisierte Sende-Engine für FT8 & FT4")
                    bullet("Prüfung gegen SQLite-Logbuch (bereits auf Band gearbeitet)")
                    bullet("Detektieren von CQ, 73, RR73 und RRR Decodes")
                    bullet("Top 100 Most Wanted DXCC – Rote Hervorhebung (🔥) & Priorität")
                    bullet("Maidenhead Locator → km Entfernungsberechnung")
                    bullet("Gesondertes Most-Wanted-Panel (höhenverstellbar via VSplitView) unter der Tabelle")
                    bullet("DX Cluster Slots (C1, C2, C3) per Dropdown-Picker und Live-Status")
                    bullet("Laufender Telnet-Server zur Spotting-Weiterleitung an externe Programme")
                    bullet("Umschaltbare Log-Diagnose (System, WSJT-X-Rohdaten, Cluster-Spots)")
                    bullet("Abkoppelbare Log-Konsole als eigenständiges, positionierbares Fenster")
                    bullet("Chronologische Sortierung wählbar (Neueste oben oder unten)")
                    bullet("Unterstützung von Hell-, Dunkel- und System-Farbschemata")
                }
            }
            
        case .quickstart:
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quickstart – Mindesteinstellungen")
                            .font(.title2)
                            .bold()
                        Text("Vier grundlegende Schritte zum sofortigen Funkbetrieb mit AutoQSO.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { openSettings() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                            Text("Einstellungen öffnen ⚙️")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // 1. Eigenes Rufzeichen & QTH
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("1. Eigenes Rufzeichen & Grid-Locator (Heimat-QTH)", systemImage: "location.circle.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .telnet) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("Rufzeichen (Telnet)")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { openSettings(to: .qth) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("QTH-Locator")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Hilfe") {
                            selectedSection = .propagationMap
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("• **Eigenes Rufzeichen**: Trage dein Rufzeichen unter **Einstellungen (⚙️) -> Telnet Server** (*Rufzeichen für Login*) ein. Es wird für Cluster-Verbindungen und den integrierten Telnet-Server genutzt.")
                        .font(.subheadline)
                    Text("• **Grid-Locator (Heimat-QTH)**: Öffne **Einstellungen (⚙️) -> Eigenes QTH (Maidenhead)** und trage deinen 4- bis 8-stelligen Locator ein (z. B. `JO31AA24`), oder nutze die interaktive Karte mit Drop-Pin (🗺️). Dies ermöglicht die präzise Entfernungs- und Peilungsberechnung zu allen Stationen.")
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
                        Label("2. WSJT-X UDP-Verbindung (Empfang & Auto Transmit)", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .udp) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("UDP-Einstellungen")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("WSJT-X Anleitung") {
                            selectedSection = .wsjtx
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("• **Zweck**: Empfängt Live-Dekodierungen (FT8/FT4) und sendet automatische Antwortkommandos (Auto QSO).")
                        .font(.subheadline)
                    Text("• **Einstellung in WSJT-X**: Öffne in WSJT-X **Settings -> Reporting** und aktiviere:\n  1. `Prompt me to log QSO` [x]\n  2. `Accept UDP requests` [x]\n  3. `UDP Server Address: 224.0.0.1` (Multicast) oder `127.0.0.1` (Unicast)\n  4. `UDP Server Port: 2237`")
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
                        Label("3. Logbuch-Synchronisation (RUMlogNG / LoTW / QRZ.com / ADIF)", systemImage: "book.closed.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .sync) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("Sync-Einstellungen")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Hilfe") {
                            selectedSection = .logbook
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("• **Zweck**: Gleicht eingehende Stationen in Echtzeit mit bereits getätigten QSOs auf dem Band ab, verhindert Doppel-QSOs und markiert ungearbeitete Länder/Grids farbig.")
                        .font(.subheadline)
                    Text("• **Einstellung**: Öffne **Einstellungen (⚙️) -> Logbuch-Sync**, wähle deine Quelle (**RUMlogNG**, **LoTW** oder **QRZ.com**) und starte den Sync (oder lade ein bestehendes Logbuch über *ADIF-Datei importieren* hoch).")
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
                        Label("4. DX Cluster & Filter (Optional)", systemImage: "list.bullet.rectangle.portrait.fill")
                            .font(.headline)
                        Spacer()
                        Button(action: { openSettings(to: .cluster) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("Cluster-Einstellungen")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Hilfe") {
                            selectedSection = .cluster
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Text("• **Zweck**: Paralleler Empfang weltweiter DX-Spots über bis zu drei Cluster (C1, C2, C3) zur Live-Ausbreitungsanalyse.")
                        .font(.subheadline)
                    Text("• **Einstellung**: Wähle in der linken Seitenleiste oder unter **Einstellungen (⚙️) -> DX Cluster** deine gewünschten Cluster per Dropdown aus.")
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
                Text("Toolbar & Bedienung")
                    .font(.title2)
                    .bold()
                Text("Hier findest du eine Übersicht über alle Steuerungselemente und Interaktionen in AutoQSO.")
                    .font(.body)
                
                Text("Bedienelemente der Toolbar:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    iconBullet(icon: "sidebar.left", text: "**Verbindungs-Sidebar**: Blendet die linke Status- und Konfigurations-Seitenleiste ein oder aus.")
                    iconBullet(icon: "play.circle", text: "**Auto Transmit Toggle (Auto ON/OFF)**: Aktiviert oder deaktiviert die automatische Sende-Engine.")
                    iconBullet(icon: "pause.circle", text: "**Freeze / Pause Toggle**: Friert die Ansicht der Dekodiertabelle & Logs mit einem statischen Snapshot ein (Auto-Scroll aus). Hintergrunddaten werden weiter empfangen. Erneuter Klick schaltet zurück auf Live-Scrollen.")
                    iconBullet(icon: "magnifyingglass", text: "**Echtzeit-Suchfeld**: Ermöglicht das sofortige Durchsuchen der Tabelle oder Logs nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text – sowohl im Live- als auch im Freeze-Modus.")
                    iconBullet(icon: "book", text: "**Logbuch**: Öffnet das LoTW/QRZ-Logbuchfenster zur Ansicht der getätigten QSOs.")
                    iconBullet(icon: "arrow.up", text: "**Sortierung**: Schaltet die chronologische Sortierung der Tabelleneinträge und Logs um (Neueste oben oder unten).")
                    iconBullet(icon: "trash", text: "**Tabelle löschen**: Leert die Liste der empfangenen Dekodierungen und Spots.")
                    iconBullet(icon: "map", text: "**Ausbreitungskarte**: Öffnet die Live-Karte zur Visualisierung empfangener Spots.")
                    iconBullet(icon: "rectangle.compress.vertical", text: "**Kompaktmodus**: Reduziert das Layout auf eine minimale Steuerleiste und Spot-Tabelle.")
                    iconBullet(icon: "gearshape", text: "**Einstellungen**: Öffnet den Einstellungsdialog zur Konfiguration der Syncs, Cluster und Farben.")
                    iconBullet(icon: "questionmark.circle", text: "**Hilfe**: Öffnet dieses Hilfe- und Changelog-Fenster.")
                    iconBullet(icon: "sidebar.right", text: "**Filter-Sidebar**: Blendet das rechte Panel zur Konfiguration von Rufzeichen-, DX- und Spotter-Filtern ein oder aus.")
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                Text("Tastatur- & Maus-Bedienung (Spot-Tabelle):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Einfacher Klick**: Wählt eine Station in der Tabelle aus. Dies lädt ihre Details in den Detail-Banner, aktualisiert die QRZ/LoTW-Daten und hebt das Rufzeichen hervor.")
                    bullet("**Doppelklick**: Löst die manuelle Antwort (**Manual Reply**) aus. AutoQSO sendet ein UDP-Reply-Kommando an WSJT-X, wodurch WSJT-X sofort auf die entsprechende Frequenz springt und den Sendezyklus startet.")
                }
            }
            
        case .wsjtx:
            VStack(alignment: .leading, spacing: 12) {
                Text("WSJT-X Konfiguration")
                    .font(.title2)
                    .bold()
                Text("In WSJT-X unter Settings -> Reporting:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    numberedItem("1.", "Option 'Prompt me to log QSO' aktivieren.")
                    numberedItem("2.", "Option 'Accept UDP requests' aktivieren.")
                    numberedItem("3.", "UDP Server Address: `224.0.0.1` (Multicast) oder `127.0.0.1` (Unicast).")
                    numberedItem("4.", "UDP Server Port: `2237`.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }
            
        case .triggers:
            VStack(alignment: .leading, spacing: 12) {
                Text("Auto QSO Trigger Logik")
                    .font(.title2)
                    .bold()
                Text("AutoQSO analysiert alle empfangenen WSJT-X Decodes in Echtzeit:")
                    .font(.body)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**CQ Anrufe**: CQ, CQ DX, CQ POTA, CQ TEST, etc.")
                    bullet("**73 Nachrichten**: z.B. `DL1ABC G4XYZ 73`")
                    bullet("**RR73 / RRR Nachrichten**: z.B. `K1ABC W1AW RR73`")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                Text("Ablauf:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    numberedItem("1.", "Ermittlung des Rufzeichens der sendenden Station.")
                    numberedItem("2.", "Abgleich mit dem Logbuch (falls auf dem aktuellen Band bereits gearbeitet -> grau hinterlegt und übersprungen).")
                    numberedItem("3.", "Prüfung auf aktiven Cooldown/Sperre.")
                    numberedItem("4.", "Senden des Reply-Kommandos an WSJT-X zum automatischen Anruf (WSJTX Auto Transmit).")
                }
            }
            
        case .cluster:
            VStack(alignment: .leading, spacing: 12) {
                Text("DX Cluster & Spot-Verarbeitung")
                    .font(.title2)
                    .bold()
                Text("AutoQSO ermöglicht den parallelen Empfang von bis zu drei DX-Cluster-Verbindungen (C1, C2, C3) sowie den WSJT-X Dekodierungen.")
                    .font(.body)
                
                Text("Zuweisung & Status:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("In der linken Sidebar oder den Einstellungen wählst du die gewünschten Cluster aus einem Dropdown-Menü.")
                    bullet("**Status-Indikatoren** zeigen an, ob die Verbindung aktiv ist (Grau = Aus, Orange = Verbindungsaufbau, Grün = Verbunden, Rot = Verbindungsfehler).")
                    bullet("**Universelles Spot-Parsing**: Alle eintreffenden Spots gängiger Knoten-Formate (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider) werden automatisch erfasst.")
                }
                
                Text("Vollständige Listenanzeige & Farbkodierung:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Vollständige Anzeige**: Alle empfangenen Spots und Dekodierungen werden ohne Vorab-Löschung in der Haupttabelle dargestellt.")
                    bullet("**Grün**: CQ-Anrufe und potenzielle AutoQSO-Kandidaten.")
                    bullet("**Rot / Fett**: Ungearbeitete seltene Most Wanted Entitäten.")
                    bullet("**Blasses Rot**: Stationen, die auf dem aktuellen Band bereits im Logbuch stehen.")
                    bullet("**Grau / Muted**: Von den aktiven DX- oder Spotter-Filtern blockierte Stationen.")
                    bullet("**Standard**: Normale empfangene Dekodierungen und Spots.")
                }
                
                Text("Länder- & Spotter-Filterung:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Intelligente Autovervollständigung**: Beim Tippen in den Länderfeldern (Gesperrte Länder, Erlaubte DX-Länder, Erlaubte Spotter-Länder) werden passende Länder sofort vorgeschlagen.")
                    bullet("**Teilstring- & Regionenerkennung**: Eingaben wie `Russia` oder `Russland` stimmen automatisch sowohl mit `European Russia` als auch `Asiatic Russia` überein. Genauso lassen sich Teilbegriffe gezielt filtern.")
                }
                
                Text("Listen-Manager (Einstellungen -> DX Cluster):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Hinzufügen & Bearbeiten**: Du kannst eigene Cluster mit Name, Host und Port registrieren.")
                    bullet("**Drag-and-Drop**: Die Reihenfolge der Cluster kann direkt in der Tabelle per Maus verschoben und angepasst werden.")
                    bullet("**Zurücksetzen (Restore Defaults)**: Stellt die ursprüngliche Liste der vordefinierten Standard-Cluster wieder her.")
                }
            }
            
        case .telnet:
            VStack(alignment: .leading, spacing: 12) {
                Text("Telnet Server & Spotting-Ausgabe")
                    .font(.title2)
                    .bold()
                Text("AutoQSO läuft als lokaler Telnet-Cluster-Server, an den du externe Log-Software (z.B. MacLoggerDX) koppeln kannst.")
                    .font(.body)
                
                Text("Konfiguration:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Port & Login**: Der Server horcht standardmäßig auf Port 8000. Das Login-Rufzeichen (z.B. GUEST) kann in den Einstellungen angepasst werden.")
                    bullet("**Client-Tracking**: Der Live-Status im linken Sidepanel zeigt die Anzahl der aktuell verbundenen externen Programme an.")
                }
                
                Text("WSJT-X Spotter Telnet-Ausgabe:")
                    .font(.headline)
                bullet("Ist dieser Schalter aktiviert, werden alle gefilterten WSJT-X Dekodierungen als rohe DX-Spots im Telnet-Format ausgegeben, sodass sie sofort in deinem Log-Programm auf der Karte erscheinen. Standardmäßig ist diese Option deaktiviert (keine Ausgabe).")
            }
            
        case .propagationMap:
            VStack(alignment: .leading, spacing: 14) {
                Text("Ausbreitungskarte & Maidenhead Grid-Map")
                    .font(.title2)
                    .bold()
                Text("AutoQSO bietet zwei spezialisierte interaktive Kartenansichten, die über die Toolbar-Buttons **Karte ↗** und **Grid-Map ↗** als eigenständige Fenster geöffnet werden können.")
                    .font(.body)
                
                Text("1. Ausbreitungskarte (Propagation Map):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Länder-Cluster**: Stellt aktive DX-Entitäten visuell auf einer Weltkarte dar mit farblich codierten Band-Badges.")
                    bullet("**Zeitfenster-Steuerung**: Einstellbar von 5 bis 120 Minuten.")
                    bullet("**Gearbeitete mitzählen**: Umschalter zur Anzeige bereits gearbeiteter Länder auf der Karte.")
                    bullet("**Seitenleiste**: Übersichtliche Gruppierung nach Kontinent, A–Z oder Spot-Anzahl.")
                }
                
                Text("2. Neue Maidenhead Grid-Map:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Ungearbeitete Maidenhead Grids**: Visualisiert gezielt noch ungearbeitete 4-Stellen (`JO31`) und 6-Stellen (`JO31AA`) Maidenhead-Lokaltore auf der Weltkarte.")
                    bullet("**Interaktiver Grid-Inspector (Klick auf Grid)**: Ein Klick auf ein beliebiges Grid-Feld oder Marker-Badge auf der Karte öffnet ein Info-Popover mit Status (gearbeitet/ungearbeitet), Peilung & Distanz, Band-Aufteilung, Liste aller aktiven Stationen inklusive Direktaufruf von QRZ.com und Zentrier-Schaltfläche.")
                    bullet("**Band-Schnellfilter**: Schwebende Pill-Leiste (`ALL`, `160M`–`6M`), um die Karte und Seitenleiste mit einem Klick auf das gewünschte Band zu filtern.")
                    bullet("**Peilung & Distanz**: Anzeige von Azimut und Großkreis-Entfernung bezogen auf das eigene Heimat-QTH (`🧭 285° · 4.210 km`) direkt in jeder Zeile.")
                    bullet("**Spot-Frische & Age-Decay**: Brandneue Spots (< 3 Min.) werden durch ein leuchtendes `⚡ NEU`-Badge und Umrandung hervorgehoben; ältere Spots (> 10 Min.) blenden dezent ab.")
                    bullet("**Kompakt- / Detail-Umschalter**: Schaltfläche in der Sidebar-Kopfleiste zum Wechseln zwischen einer kompakten 1-Zeilen-Übersicht und einer ausführlichen Detailkarte mit allen Rufzeichen.")
                    bullet("**Farbkodierung**: 4-Stellen Grids werden grün hervorgehoben, 6-Stellen Grids blau.")
                    bullet("**Echtzeit-Suchleiste**: Schnellsuche nach Grid-Locatoren oder Rufzeichen in der rechten Seitenleiste.")
                    bullet("**Fokussierung**: Klick auf eine Zeile oder ein Marker-Badge zentriert die Karte direkt auf den ausgewählten Locator.")
                }
                
                Text("3. Dynamisches Maidenhead Grid-Overlay (GridTracker-Stil):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Lückenlose Kartenabdeckung**: Hardwarebeschleunigtes Canvas-Gitter im GridTracker-Stil über der gesamten Karte.")
                    bullet("**Standardmäßig aktiv**: In der Grid-Map beim Öffnen automatisch eingeschaltet (über das Grid-Icon `grid.circle` in der oberen rechten Ecke umschaltbar).")
                    bullet("**Pixel-dynamische Auflösung**: Automatischer, bildschirmgrößenabhängiger Wechsel von 2-Stellen (`JO`), 4-Stellen (`JO31`), 6-Stellen (`JO31AA`) bis hin zu 8-Stellen Resolution (`JO31AA11`). Verhindert Überlappungen und gewährleistet immer freie Sicht auf Straßen und Satellitenbilder.")
                    bullet("**Dezente Lesbarkeits-Badges**: Transparente Unterlegungen (`opacity: 0.55`) sorgen für optimale Lesbarkeit, ohne die Karte zu verdecken.")
                    bullet("**Gearbeitete Grid-Schattierung**: Über das Häkchen-Icon (`checkmark.square`) lassen sich bereits gearbeitete 4-Stellen Grids aus dem Logbuch auf der Karte farbig schattieren. Die Schattierungsfarbe ist in den Einstellungen und in der unteren Leiste anpassbar (Standard: Rot-Orange `#FF5926`).")
                    bullet("**Klick auf gearbeitetes Grid**: Ein Klick auf ein schattiertes/gearbeitetes Grid-Feld öffnet ein Detailfenster (**WorkedGridDetailView**) mit allen im Logbuch enthaltenen QSOs für diesen Maidenhead-Locator inklusive Such- und Filterfunktion.")
                    bullet("**Doppelklick für QRZ.com**: Ein Doppelklick auf eine Station im Grid-Logbuchfenster öffnet direkt deren QRZ.com-Seite im Browser. Vor dem Öffnen wird automatisch geprüft, ob eine aktive Internetverbindung besteht; ansonsten erscheint ein nativer Fehlerhinweis.")
                    bullet("**Schnellsteuerungs-Leiste am Kartenrand**: Live-Anpassung der Schriftgröße (`A-`/`A+`), der Textfarbe, der Gitterlinienfarbe, der Badge-Farbe sowie der Schattierungsfarbe für gearbeitete Grids.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Text("Filter-Garantie:")
                    .font(.headline)
                bullet("Beide Karten aggregieren ausschließlich Dekodierungen und DX-Spots, die alle deine aktiven DX-Filterregeln erfolgreich bestanden haben.")
            }
            
        case .compactMode:
            VStack(alignment: .leading, spacing: 12) {
                Text("Kompaktmodus (Compact Mode)")
                    .font(.title2)
                    .bold()
                Text("Der Kompaktmodus reduziert den Platzbedarf von AutoQSO auf ein absolutes Minimum.")
                    .font(.body)
                
                Text("Funktionsumfang im Kompaktmodus:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Kompakte Steuerleiste**: Bietet Zugriff auf Auto Transmit (Auto ON/OFF), den globalen Filter-Schalter, das Öffnen der Ausbreitungskarte und die Verbindungs-/TX-Statuslämpchen.")
                    bullet("**Reduzierte Tabelle**: Zeigt eine fokussierte Tabelle mit Zeit, DX Call, Land, SNR und Nachricht.")
                    bullet("**Ticker für Most Wanted**: Unten scrollt eine Zeile mit ungearbeiteten seltenen Stationen durch. Durch Doppelklick/Anklicken kannst du diese anrufen bzw. im Banner fokussieren.")
                    bullet("**Minimalmaße**: Das Hauptfenster lässt sich bis auf 480x320 Pixel herunterskalieren, um perfekt in einer Bildschirmecke Platz zu finden.")
                    bullet("**Zurückwechseln**: Über das Pfeilsymbol ganz rechts in der kompakten Leiste gelangst du wieder in die Normalansicht.")
                }
            }
            
        case .logbook:
            VStack(alignment: .leading, spacing: 12) {
                Text("Logbuch Management & Synchronisation")
                    .font(.title2)
                    .bold()
                
                Text("Logbuch-Quellen (Umschaltbar):")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**RUMlogNG (macOS App)**: Direkte 1-Klick-Synchronisation über die native AppleScript-Schnittstelle von RUMlogNG (`ReadAdif`). RUMlogNG muss lediglich geöffnet sein.")
                    bullet("**ARRL LoTW**: Automatischer Download deiner bestätigten und hochgeladenen QSOs vom ARRL Logbook of The World.")
                    bullet("**QRZ.com**: API-basierter Abgleich deiner QSOs über deinen QRZ.com API Key.")
                }
                
                Text("Vollständiger Sync & Inkrementeller Sync:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Vollständiger Sync (ab 1900)**: Lädt das gesamte Logbuch ab `1900-01-01` herunter bzw. aus RUMlogNG.")
                    bullet("**Intelligentes SQLite-Upsert**: Bei bestehenden Einträgen werden fehlende Attribute (wie z. B. Grid-Locatoren) automatisch ergänzt, ohne doppelte QSOs zu erzeugen (`ON CONFLICT DO UPDATE`).")
                    bullet("**Inkrementeller Sync**: Synchronisiert automatisch nur neuere QSOs ab dem Datum des letzten Logbucheintrags.")
                }
                
                Text("ADIF-Datei importieren:")
                    .font(.headline)
                bullet("Über den Button '**ADIF-Datei auswählen & importieren...**' kannst du bestehende Logbücher im `.adi` / `.adif` Format in deine lokale SQLite-Datenbank einspielen. Duplikate werden anhand des eindeutigen Schlüssels (Call, Band, Mode, Zeit) automatisch aussortiert.")
                
                Text("Logbuch leeren / Löschen:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Löschen (🗑️)**: QSOs können im Logbuch-Fenster einzeln oder über Mehrfachauswahl gelöscht werden.")
                    bullet("**Logbuch löschen**: Der Button in den Einstellungen entfernt alle lokalen QSOs aus der Datenbank nach Bestätigung eines Sicherheitsdialogs.")
                }
            }
            
        case .storage:
            VStack(alignment: .leading, spacing: 12) {
                Text("Speicherort & iCloud Synchronisation")
                    .font(.title2)
                    .bold()
                
                Text("Konfiguration im Einstellungen-Dialog (Seitenleiste -> Speicherort & iCloud):")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    bullet("**Standard-Ordner**: Speichert die Datenbank unter `~/Documents/AutoQSO`.")
                    bullet("**Benutzerdefinierter Ordner**: Freie Wahl eines lokalen Ordners via macOS Dialog.")
                    bullet("**iCloud Drive**: Speichert in `iCloud Drive/AutoQSO` zur automatischen Synchronisation zwischen mehreren Macs.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Text("Hinweis: Beim Wechsel des Speicherorts wird die bestehende SQLite-Datenbank automatisch an den neuen Zielort kopiert.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .appearance:
            VStack(alignment: .leading, spacing: 12) {
                Text("Ansicht & Farbanpassungen")
                    .font(.title2)
                    .bold()
                Text("Im Einstellungsmenü unter **Ansicht** kannst du das gesamte Erscheinungsbild von AutoQSO deinen individuellen Wünschen anpassen.")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Farbschema & Darstellung:")
                        .font(.headline)
                    bullet("Auswahl zwischen **System**, **Hell** und **Dunkel**.")
                    bullet("Umschaltung der Sortierrichtung: Neueste Einträge oben oder unten in Haupttabelle und Logfenster.")
                    
                    Text("2. Listen-Ansicht (Haupttabelle & Log-Konsole):")
                        .font(.headline)
                    bullet("**Schriftgrößen**: Stufenlose Regelung der Tabellen- und Protokoll-Schriftgrößen (8 pt bis 20 pt).")
                    bullet("**Farbanpassungen Haupttabelle**: Individuelle Farbwahl für Standard-Text, Most Wanted (🔥), CQ-Aufrufe und bereits gearbeitete Stationen.")
                    bullet("**Farbanpassungen Log-Konsole**: Einstellbare Farben für Konsolen-Hintergrund, System-Logs, WSJT-X Dekodierungen, eingehenden/ausgehenden Traffic und Cluster-Spots.")
                    bullet("**Unabhängiges Zurücksetzen**: Eigener Button 'Listen-Ansicht auf Standard zurücksetzen' zur Wiederherstellung der Tabellen- und Logfarben.")
                    
                    Text("3. Landkarten-Ansicht (Maidenhead Grid-Overlay):")
                        .font(.headline)
                    bullet("**Gitter-Schriftgröße**: Slider zur Skalierung der Locator-Beschriftungen (8 pt bis 22 pt).")
                    bullet("**Farb-Customizing**: Separate Farbwahl für Gitter-Beschriftungen, Gitterlinien, Badge-Hintergründe und gearbeitete Grids.")
                    bullet("**Lesbarkeits-Badges**: Ein- und Ausschalten der dunklen Hintergründe hinter Locator-Texten.")
                    bullet("**Unabhängiges Zurücksetzen**: Eigener Button 'Karten-Ansicht auf Standard zurücksetzen' für alle Karteneinstellungen.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }

        case .support:
            VStack(alignment: .leading, spacing: 14) {
                Text("Support & Hilfestellung")
                    .font(.title2)
                    .bold()
                
                Text("Hast du Fragen, Probleme oder Feedback zu AutoQSO? Über den unten stehenden Button kannst du direkt eine E-Mail an unseren Support senden.")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Automatisch übermittelte Systeminformationen:")
                        .font(.headline)
                    bullet("App Version & Build-Nummer (`AutoQSO v\(APP_VERSION) (Build \(APP_BUILD_NUMBER))`)")
                    bullet("macOS-Version & Build-Nummer")
                    bullet("Hardware-Informationen (Mac-Modell/Hostname, Prozessortyp, CPU-Kerne, Arbeitsspeicher)")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Button(action: sendSupportEmail) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Text("Support-E-Mail senden")
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
                Text("Rechtlicher Hinweis & Haftungsausschluss")
                    .font(.title2)
                    .bold()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nutzung auf eigene Verantwortung:")
                        .font(.headline)
                    Text("Die Nutzung von AutoQSO und insbesondere der automatisierten Sendefunktion (**Auto QSO für WSJT-X**) erfolgt ausschließlich auf eigene Gefahr und Verantwortung des jeweiligen lizenzierten Funkamateurs.")
                        .font(.body)
                    
                    Text("Einhaltung der Amateurfunkbestimmungen:")
                        .font(.headline)
                    Text("Der Betreiber ist verpflichtet, die geltenden Gesetze, Bestimmungen der Bundesnetzagentur (bzw. der zuständigen nationalen Fernmeldebehörde) sowie die IARU-Bandpläne einzuhalten. Eine ständige Beaufsichtigung der Sendestation durch den Funkamateur ist sicherzustellen.")
                        .font(.body)
                    
                    Text("Haftungsausschluss:")
                        .font(.headline)
                    Text("Der Entwickler übernimmt keinerlei Haftung für direkte oder indirekte Schäden, Frequenzstörungen, Fehlbedienungen, Bandplanverletzungen oder sonstige Nachteile, die aus der Nutzung der Software resultieren.")
                        .font(.body)
                }
                .padding()
                .background(Color.red.opacity(0.08))
                .cornerRadius(8)
            }
            
        case .changelog:
            VStack(alignment: .leading, spacing: 16) {
                Text("Versionshistorie (Changelog)")
                    .font(.title2)
                    .bold()
                
                // Version 3.6.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.6.0")
                            .font(.headline)
                            .bold()
                        Text("(Build \(APP_BUILD_NUMBER))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("AKTUELL")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Universal 2 Binary: Vollständige native Unterstützung für Apple Silicon (M1/M2/M3/M4) sowie Intel-basierte Macs (x86_64) unter macOS 14+.", font: .subheadline, color: .secondary)
                        bullet("Strukturierte Filter-Sidebar: Logische Neuordnung aller Filterbereiche von geografischen Kriterien (Kontinente, gesperrte/erlaubte Länder, Zonen, Rufzeichen) über Logbuch-Historie bis hin zu Signal- und Doubletten-Filtern.", font: .subheadline, color: .secondary)
                        bullet("Klarere Filterbezeichnung: Der frühere „WSJT-X Spezialfilter“ heißt nun prägnant „WSJT-X CQ Filter“ (Nur CQ, RRR, RR73, 73).", font: .subheadline, color: .secondary)
                        bullet("Automatisierte Universal-Release-Pipeline: Das Release-Skript und der integrierte Installer bauen und paketieren automatisch universelle Mach-O-Binaries in der DMG.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.08))
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
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Konfigurierbarer Filter für bereits gearbeitete Stationen: Neuer Schalter in der Filter-Sidebar, der gearbeitete Stationen nach einer frei wählbaren Zeitspanne (0 bis 999 Stunden, Tage, Monate oder Jahre) wieder durchlässt und für AutoQSO freigibt.", font: .subheadline, color: .secondary)
                        bullet("Blitzschnelle O(1) Zeitstempel-Indexierung: AutoQSO indexiert die exakten UTC-Zeitstempel aller QSOs im SQLite-Speicher, sodass Zeitspannen-Prüfungen auch bei zehntausenden Logbucheinträgen in Nanosekunden erfolgen.", font: .subheadline, color: .secondary)
                        bullet("Flexible Zifferneingabe & Einheiten-Picker: Direkte numerische Eingabe (0–999) im Textfeld kombiniert mit Stunden-, Tage-, Monate- und Jahre-Auswahl.", font: .subheadline, color: .secondary)
                        bullet("Vollständige Integration in Filter & Auto-Transmit: Einstellbare Wiederholungs-QSOs fließen nahtlos in die DX-Filterung, die automatische Sendeauswahl (Auto Transmit) und das Most-Wanted-Panel ein.", font: .subheadline, color: .secondary)
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
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Intelligente 5-Minuten-Zeitfenster-Deduplizierung: Erkennt und verhindert doppelte QSOs durch Start- und Endzeit-Abweichungen (`TIME_ON` vs. `TIME_OFF`) zwischen WSJT-X, RUMlogNG, QRZ.com und LoTW zuverlässig in der SQLite-Datenbank.", font: .subheadline, color: .secondary)
                        bullet("Automatische Logbuch-Bereinigung: Beim Programmstart werden bestehende doppelte Einträge automatisch fusioniert (fehlende Grid- und DXCC-Informationen ergänzt) und bereinigt.", font: .subheadline, color: .secondary)
                        bullet("WSJT-X Doppel-Meldungs-Filter: Intelligentes Debouncing verhindert das parallele doppelte Eintragen von QSOs, wenn WSJT-X zeitgleich `loggedAdif`- und `qsoLogged`-UDP-Pakete sendet.", font: .subheadline, color: .secondary)
                        bullet("Präzise Popover-Verankerung auf der Grid-Karte: Das Grid-Inspector-Popover verankert sich jetzt als Karten-Annotation direkt an der exakten Zentrumskoordinate des angeklickten Planquadrats mit zielgenau ausgerichteter Sprechblase.", font: .subheadline, color: .secondary)
                        bullet("Dauerhafte Verfügbarkeit der Grid-Karte: Die 2D-Kartenansicht, das Maidenhead-Gitter und der Inspector bleiben auch bei 0 neuen DX-Grids im aktuellen Zeitfenster uneingeschränkt sichtbar und interaktiv bedienbar.", font: .subheadline, color: .secondary)
                        bullet("Automatische Länderauflösung im Grid-Inspector: Rufzeichen gearbeiteter Grids werden automatisch über den Prefix-Matcher in lesbare Ländernamen (statt numerischer DXCC-IDs) aufgelöst.", font: .subheadline, color: .secondary)
                        bullet("Aufgeräumte Toolbar: Das Textfeld für die Minutensperre wurde aus der Haupt-Toolbar entfernt und wird nun übersichtlich in den Einstellungen (WSJT-X) verwaltet.", font: .subheadline, color: .secondary)
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
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("RUMlogNG AppleScript-Integration: Direkte 1-Klick-Synchronisation des Logbuchs aus der laufenden macOS App RUMlogNG über die native AppleScript-Schnittstelle (`ReadAdif`) – sowohl inkrementell als auch vollständig ab 1900.", font: .subheadline, color: .secondary)
                        bullet("Umschaltbare Logbuch-Quellen: Flexibler Segmented-Picker in den Einstellungen zum Umschalten zwischen RUMlogNG, ARRL LoTW und QRZ.com inklusive automatischem Post-QSO-Sync für die aktive Quelle.", font: .subheadline, color: .secondary)
                        bullet("Aktives QSO auf Ausbreitungskarte zentriert: Automatische Zentrierung und optimale Skalierung des Großkreis-Pfads (Great Circle) auf 2D-Karte und 3D-Globus bei jedem aktiven QSO, inklusive 1-Klick Re-Zentrierung über den Status-Banner.", font: .subheadline, color: .secondary)
                        bullet("Dual-Installer Release-DMG: Bereitstellung von nativer GUI-Installer-App (`AutoQSO Installer.app`) und Terminal-Installationsskript (`Install AutoQSO.command`) im Release-Image.", font: .subheadline, color: .secondary)
                        bullet("Quickstart Direktsprung-Routing: Direkte Sprungbuttons aus den 4 Quickstart-Schritten zu den jeweiligen Einstellungs-Tabs (Rufzeichen/Telnet, QTH-Locator, UDP-Server, Logbuch-Sync).", font: .subheadline, color: .secondary)
                        
                        Text("🐞 Fehlerbehebungen & Leistungsverbesserungen")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Crash-Fix Auto-Scroll: Behebung eines Out-of-Bounds-Absturzes beim automatischen Tabellen-Scrollen durch Umstellung auf asynchrones Viewport-Scrolling (`clipView.scroll(to:)`).", font: .subheadline, color: .secondary)
                        bullet("macOS Automation-Permissions: `NSAppleEventsUsageDescription` und automatisches Ad-hoc-Codesigning in allen Build-Skripten integriert.", font: .subheadline, color: .secondary)
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
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Nativer macOS GUI-Installer: Grafische Installer-App (`AutoQSO Installer.app`) direkt im `.dmg` ersetzt das Terminal-Skript. Bietet komfortable Zielordner-Auswahl, Gatekeeper-Quarantäne-Entfernung (`xattr -cr`), Code-Signatur-Auffrischung und Sofortstart.", font: .subheadline, color: .secondary)
                        bullet("Interaktiver Grid-Inspector: Ein Klick auf ein beliebiges Grid-Feld auf der Karte öffnet ein Detail-Popover mit Status (gearbeitet/ungearbeitet), Peilung/Distanz, aktiven Stationen und QRZ.com-Aufruf.", font: .subheadline, color: .secondary)
                        bullet("Band-Schnellfilter auf Grid-Map: Horizontale Filter-Pill-Leiste (`ALL`, `160M`–`6M`) zum sofortigen Umschalten der angezeigten Grids und Map-Marker nach dem aktiven Band.", font: .subheadline, color: .secondary)
                        bullet("Peilung & Distanz (Beam Heading / Distance): Anzeige von Azimut und Großkreis-Entfernung bezogen auf das eigene Heimat-QTH (`🧭 285° · 4.210 km`) direkt in jeder Grid-Zeile.", font: .subheadline, color: .secondary)
                        bullet("Spot-Frische & Age-Decay: Brandneue Spots (< 3 Min.) werden mit `⚡ NEU`-Badge und leuchtender Umrandung hervorgehoben; ältere Spots (> 10 Min.) blenden dezent ab.", font: .subheadline, color: .secondary)
                        bullet("Kompakt- / Detail-Umschalter: Umschaltbare Grid-Sidebar zwischen einer platzsparenden 1-Zeilen-Übersicht und einer ausführlichen Detailansicht mit Stationen und Zeiten.", font: .subheadline, color: .secondary)
                        bullet("Pixel-dynamische Maidenhead-Zoomstufen: Das Maidenhead-Gitter berechnet die tatsächliche Pixelgröße der Zellen; Umschaltung auf feinere Stufen erfolgt erst bei ausreichender Pixelbreite (kein Zupflastern der Karte).", font: .subheadline, color: .secondary)
                        bullet("Getrennte Reset-Buttons: Unabhängige Werkseinstellungs-Buttons für Listen-Ansicht und Karten-Ansicht in den Einstellungen.", font: .subheadline, color: .secondary)
                        bullet("Cluster Spots in Haupttabelle: Vollständige Anzeige und Farbkodierung von DX Cluster Spots in der Haupttabelle mit Spotter-Spalte und Spotter-Filterung.", font: .subheadline, color: .secondary)
                        
                        Text("🐞 Fehlerbehebungen & Leistungsverbesserungen")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Behebung des UI-Hangs beim Spaltenverschieben: Korrektur der SwiftUI-Tabellenstruktur zur Beseitigung von Deadlocks beim Umordnen von Spalten.", font: .subheadline, color: .secondary)
                        bullet("Schnelles Tabellen-Rendering: O(1) Cache-Evaluierung für Zellenfarben beseitigt Ruckeln beim schnellen Scrollen.", font: .subheadline, color: .secondary)
                        bullet("Karten-Performance: Entkopplung der Map-Sidebars via EquatableView (keine Re-Layouts bei Pan/Zoom) und Beseitigung synchroner I/O im Canvas-Rendering.", font: .subheadline, color: .secondary)
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
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("3D-Globus-Projektion & Maidenhead-Gitter: Maidenhead-Grid-Linien und gearbeitete 4-Stellen Planquadrate werden in der 3D-Globusansicht nativ als 3D-Polylines und 3D-Polygone auf die Erdkugel projiziert.", font: .subheadline, color: .secondary)
                        bullet("Aktiver QSO-Pfad auf Ausbreitungskarte: Zeichnet bei einem aktiven WSJT-X Anruf/QSO eine leuchtend gelbe Großkreis-Verbindungslinie zwischen eigenem QTH (minimalistisches 🏠 Symbol) und der Zielstation auf der 2D-Karte und dem 3D-Globus inklusive Live-Statusbanner (⚡ AKTIVES QSO).", font: .subheadline, color: .secondary)
                        bullet("Einstellungsbereich Eigenes QTH & Interaktiver QTH Picker: Neuer Einstellungsreiter 'Eigenes QTH (Maidenhead)' (max. 8-Stellen-Präzision) mit Echtzeit-Standortanalyse und nativer interaktiver Karte (InteractiveQTHPickerView) mit Google-Style Drop-Pin.", font: .subheadline, color: .secondary)
                        bullet("Interaktiver Installer & macOS Gatekeeper Lösung: Doppelklickbares Skript (`Install AutoQSO.command`) direkt im `.dmg`, das den Zielordner (`/Applications`, `~/Applications` oder Finder-Dialog) abfragt, Quarantäne-Attribute (`xattr -cr`) entfernt, Code-Signatur auffrischt und AutoQSO direkt startet.", font: .subheadline, color: .secondary)
                        bullet("Kompaktmodus Toolbar-Schaltflächen: Alle 6 Icon-Buttons (Logbuch, Ausbreitungskarte, Grid-Map, Normalmodus, Einstellungen, Hilfe) sind jetzt direkt in der Toolbar des Kompaktmodus verfügbar.", font: .subheadline, color: .secondary)
                        bullet("Kartenstil Dropdown-Menü: Neues kompaktes, kontrastreiches Dropdown-Menü (.ultraThinMaterial Pill) für alle Kartenansichten ohne störende Text-Labels.", font: .subheadline, color: .secondary)
                        bullet("3D Grid-Interaktivität & Spots: Gearbeitete Felder auf dem 3D-Globus sind anklickbar und öffnen das Logbuch-Detailfenster (`WorkedGridDetailView`). Spots werden als 3D-Marker auf dem Globus dargestellt.", font: .subheadline, color: .secondary)
                        bullet("Unabhängige Kartenstile: Kartenstil-Einstellungen (`propagationMapStyle` und `newGridMapStyle`) werden für Ausbreitungskarte und Grid-Karte getrennt gespeichert.", font: .subheadline, color: .secondary)
                        
                        Text("🐞 Fehlerbehebungen & Performance-Optimierungen")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Signifikante Performance-Optimierung: Teure Logbuch-Iterationen (`worked4CharGrids`) gecacht, Canvas-Rendering mit Viewport-Bounding-Box Pre-Filter beschleunigt und Overlay-Updates auf Dirty-Flagging umgestellt.", font: .subheadline, color: .secondary)
                        bullet("Globus Region-Debouncing: 0.2s Debounce bei sichtbaren Region-Änderungen verhindert unnötige SwiftUI-Update-Kaskaden während flüssiger Globus-Rotationen.", font: .subheadline, color: .secondary)
                        bullet("Cluster-Befehle ohne Unterbrechung: Beim Senden von Befehlen an den DX Cluster im ClusterSendDialog bleibt das Live-Scrollen aktiv.", font: .subheadline, color: .secondary)
                        bullet("Karten-Projektionsstreifen beseitigt: Wrap-Around-Filterung im Canvas-Renderer verhindert visuelle Querstufen über die Datumsgrenze.", font: .subheadline, color: .secondary)
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
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Schattierung gearbeiteter Grids: Umschaltbare farbige Unterlegung (`checkmark.square`) aller im Logbuch vorhandenen 4-Stellen-Grids auf der Maidenhead Grid-Map mit anpassbarem Farbton (Standard: `#FF5926` Rot-Orange).", font: .subheadline, color: .secondary)
                        bullet("Interaktives Grid-Logbuchfenster: Einzelklick auf ein beliebiges gearbeitetes Grid-Feld auf der Karte öffnet ein Detailfenster (WorkedGridDetailView) mit allen im Logbuch gespeicherten QSOs für diesen Maidenhead-Locator inklusive Such- und Filterfunktion.", font: .subheadline, color: .secondary)
                        bullet("Doppelklick QRZ.com-Aufruf: Doppelklick auf eine Station im Grid-Logbuchfenster öffnet direkt deren QRZ.com-Detailseite im Browser. Vorab wird automatisch geprüft, ob eine aktive Internetverbindung besteht (NWPathMonitor); ansonsten erscheint ein Fehlerhinweis.", font: .subheadline, color: .secondary)
                        bullet("Vollständiger Logbuch-Sync (ab 1900): QRZ.com und LoTW Sync laden bei Bedarf das gesamte Logbuch ab 1900 herunter. Intelligentes SQLite-Upsert (ON CONFLICT DO UPDATE) reichert bestehende QSOs nachträglich mit fehlenden Grid-Locatoren an, ohne Duplikate zu erzeugen.", font: .subheadline, color: .secondary)
                        bullet("Maidenhead Grid-Filter (4 & 6 Stellen): Neue Filterregeln zum gezielten Filtern nach bisher ungearbeiteten 4-Stellen (`JO31`) und 6-Stellen (`JO31AA`) Maidenhead-Lokaltoren.", font: .subheadline, color: .secondary)
                        bullet("Neue Maidenhead Grid-Map: Separates interaktives Kartenfenster (`Grid-Map ↗`) zur Visualisierung aller ungearbeiteten 4-Stellen (grün) und 6-Stellen (blau) Grids inklusive Echtzeit-Suchleiste und einklappbaren Kontinent-Gruppen.", font: .subheadline, color: .secondary)
                        bullet("Vollständiges GridTracker-Overlay: Hardwarebeschleunigtes Maidenhead-Gitter (2- bis 8-Stellen Resolution) im GridTracker-Stil mit Lesbarkeits-Badges über Ozeanen.", font: .subheadline, color: .secondary)
                        bullet("Schnellsteuerungs-Leiste am Kartenrand: Live-Anpassung der Gitter-Schriftgröße (`A-`/`A+`), Textfarbe, Gitterlinienfarbe, Badge-Farbe sowie der Schattierungsfarbe für gearbeitete Grids.", font: .subheadline, color: .secondary)
                        bullet("Logbuch-Tabelle mit Grid-Spalte: Die Logbuch-Ansicht wurde um eine eigene Spalte für Maidenhead Grid-Locatoren erweitert.", font: .subheadline, color: .secondary)
                        
                        Text("🐞 Fehlerbehebungen & Optimierungen")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Schutz vor Doppel-Anrufen: Automatische Cooldown-Sperre (blacklistedCalls) beim Empfang von 73/RR73-Signalen sowie beim QSO-Loggen verhindert ein versehentliches zweites Anrufen derselben Station.", font: .subheadline, color: .secondary)
                        bullet("Karten-Projektionsstreifen beseitigt: Wrap-Around-Filterung im Canvas-Renderer verhindert visuelle Querstufen über die Datumsgrenze und Projektionsränder.", font: .subheadline, color: .secondary)
                        bullet("Grid MarkerView Positionskorrektur: Stationen werden in die obere rechte Ecke der Grid-Zellen positioniert; redundante System-Textballons wurden entfernt.", font: .subheadline, color: .secondary)
                        bullet("Propagation Chart Default: Standardansicht auf 'Propagation by Continent' (isStacked = false) umgestellt.", font: .subheadline, color: .secondary)
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
                                        Text("✨ Neue Funktionen & Verbesserungen")
                                            .font(.subheadline)
                                            .bold()
                                        bullet("Freeze-Snapshot-Modus: Pause-Button friert die Dekodierliste & Protokolle mit einem statischen Snapshot ein. Hintergrunddaten werden weiter empfangen; das freie Scrollen in historischen Daten ist ohne automatisches Zurückspringen möglich.", font: .subheadline, color: .secondary)
                                        bullet("Echtzeit-Suchfeld: Neue Suchfelder in der Hauptleiste und Log-Konsole filtern Einträge in Echtzeit nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text.", font: .subheadline, color: .secondary)
                                        bullet("Vollständige Tabellenanzeige & Farbkodierung: Alle empfangenen Decodes und DX-Spots erscheinen in der Haupttabelle. Filter-Regeln löschen keine Einträge mehr, sondern steuern die farbliche Hervorhebung (z.B. Grau für blockiert) und automatische Aktionen.", font: .subheadline, color: .secondary)
                                        bullet("Universelles Spot-Parsing: Unterstützung für DX-Spots aller gängigen Cluster-Knotentypen (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider).", font: .subheadline, color: .secondary)
                                        bullet("Erweiterte Länderfilterung: Teilstring- und Regionen-Matching (z.B. `Russia` / `Russland` erkennt sowohl `European Russia` als auch `Asiatic Russia`) inklusive verbesserter Autovervollständigung.", font: .subheadline, color: .secondary)
                                        
                                        Text("🐞 Fehlerbehebungen (Bugfixes)")
                                            .font(.subheadline)
                                            .bold()
                                            .padding(.top, 4)
                                        bullet("Eingabefelder: Behebung eines SwiftUI-Bugs unter macOS, bei dem die Eingabe von Portnummern und Cooldowns während des Tippens zurückgesetzt wurde.", font: .subheadline, color: .secondary)
                                        bullet("Auto-Scroll: Korrektur der Sortier- und Scrollrichtung bei Umschaltung zwischen \"Neueste oben\" und \"Neueste unten\".", font: .subheadline, color: .secondary)
                                        bullet("Log-Löschen: Schaltfläche (Papierkorb) in der Toolbar des Hauptfensters sowie in der abgekoppelten Log-Konsole hinzugefügt.", font: .subheadline, color: .secondary)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                                
                                Divider()
                
     /*
                // Version 3.2.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.2.1")
                            .font(.headline)
                            .bold()
                        Text("(Build \(APP_BUILD_NUMBER))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("AKTUELL")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("✨ Neue Funktionen & Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Freeze-Snapshot-Modus: Pause-Button friert die Dekodierliste & Protokolle mit einem statischen Snapshot ein. Hintergrunddaten werden weiter empfangen; das freie Scrollen in historischen Daten ist ohne automatisches Zurückspringen möglich.", font: .subheadline, color: .secondary)
                        bullet("Echtzeit-Suchfeld: Neue Suchfelder in der Hauptleiste und Log-Konsole filtern Einträge in Echtzeit nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text.", font: .subheadline, color: .secondary)
                        bullet("Vollständige Tabellenanzeige & Farbkodierung: Alle empfangenen Decodes und DX-Spots erscheinen in der Haupttabelle. Filter-Regeln löschen keine Einträge mehr, sondern steuern die farbliche Hervorhebung (z.B. Grau für blockiert) und automatische Aktionen.", font: .subheadline, color: .secondary)
                        bullet("Universelles Spot-Parsing: Unterstützung für DX-Spots aller gängigen Cluster-Knotentypen (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider).", font: .subheadline, color: .secondary)
                        bullet("Erweiterte Länderfilterung: Teilstring- und Regionen-Matching (z.B. `Russia` / `Russland` erkennt sowohl `European Russia` als auch `Asiatic Russia`) inklusive verbesserter Autovervollständigung.", font: .subheadline, color: .secondary)
                        
                        Text("🐞 Fehlerbehebungen (Bugfixes)")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Eingabefelder: Behebung eines SwiftUI-Bugs unter macOS, bei dem die Eingabe von Portnummern und Cooldowns während des Tippens zurückgesetzt wurde.", font: .subheadline, color: .secondary)
                        bullet("Auto-Scroll: Korrektur der Sortier- und Scrollrichtung bei Umschaltung zwischen \"Neueste oben\" und \"Neueste unten\".", font: .subheadline, color: .secondary)
                        bullet("Log-Löschen: Schaltfläche (Papierkorb) in der Toolbar des Hauptfensters sowie in der abgekoppelten Log-Konsole hinzugefügt.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.08))
                .cornerRadius(8)
                
                Divider()
                
             */
                
                // Version 3.2.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.2.0")
                            .font(.headline)
                            .bold()
                        Text("(Build 190)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("⚡ Performance & UI/UX Optimierungen")
                            .font(.subheadline)
                            .bold()
                        bullet("Flüssige UI-Updates: Debouncing von Decodes und Cluster-Spots um 300ms verhindert UI-Ruckler während dichter FT8-Decode-Bursts.", font: .subheadline, color: .secondary)
                        bullet("Schneller App-Start: Das Parsen der CTY.DAT-Länderdatenbank wurde in den Hintergrund verlagert und blockiert nicht mehr den Start der Anwendung.", font: .subheadline, color: .secondary)
                        bullet("Reduzierte CPU-Last: Durch Vorab-Berechnung statischer Spot-Metadaten und Caching des Most-Wanted-Rankings wird die CPU-Auslastung bei Listendarstellung drastisch minimiert.", font: .subheadline, color: .secondary)
                        bullet("Optimierte Log-Anzeige: Umstellung der System- und WSJT-X-Konsolen auf LazyVStack spart signifikant Rendering-Zeit für Offscreen-Texte.", font: .subheadline, color: .secondary)
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
                        Text("(Build 174)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🗺️ Ausbreitungskarte, persistente Spot-Auswahl & zentriertes Layout")
                            .font(.subheadline)
                            .bold()
                        bullet("Ausbreitungskarte (Propagation Map): Vollständige Live-Visualisierung von spots und decodes auf einer Weltkarte. Die Karte lässt sich über das Menü FENSTER -> \"Karte ↗\" als eigenständiges macOS-Fenster öffnen.", font: .subheadline, color: .secondary)
                        bullet("Persistente Spot-Auswahl: Manuell selektierte Spots bleiben im Info-Banner permanent sichtbar und werden erst dann überschrieben, wenn die Auto-Transmit-Automatik eine neue Zielstation anruft.", font: .subheadline, color: .secondary)
                        bullet("Zentriertes Konsolen-Layout: Der Segment-Umschalter für die Log-Tabellen ist nun sowohl im Hauptfenster als auch im abgetrennten Konsolenfenster exakt zentriert.", font: .subheadline, color: .secondary)
                        bullet("Sende-Schalter Umbenennung: Der Hauptschalter für das automatische Senden wurde kompakter benannt und heißt nun \"Auto ON\" / \"Auto OFF\".", font: .subheadline, color: .secondary)
                        bullet("Dynamische Schriftgrößen: Die Schriftgrößen der Länderlisten und Kartentexte skalieren automatisch mit der Tabellen-Schriftgröße mit. Die Anzeige für den Telnet-Login wurde leicht verkleinert, um ein Abschneiden langer Texte zu vermeiden.", font: .subheadline, color: .secondary)
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
                        Text("(Build 166)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🌐 Detektierbare Logs, DX Cluster Manager & Layout-Flexibilität")
                            .font(.subheadline)
                            .bold()
                        bullet("Losgelöste Log-Konsole: Das Diagnosefenster lässt sich abkoppeln und dockt beim Schließen wieder im Hauptfenster an.", font: .subheadline, color: .secondary)
                        bullet("Integrierter Cluster-Manager: Hinzufügen, Editieren, Löschen und per Drag-and-Drop Sortieren von Clustern in den Einstellungen.", font: .subheadline, color: .secondary)
                        bullet("Telnet Server Splittung: DX Cluster und Telnet Server sind eigenständige Abschnitte in Sidebar und Einstellungen.", font: .subheadline, color: .secondary)
                        bullet("ADIF Datei Import: Bequemer Import von QSOs via `.adi`/`.adif`-Dateien direkt über die Einstellungen.", font: .subheadline, color: .secondary)
                        bullet("Ansichtsoptionen: Freie Wahl der chronologischen Sortierung (Neueste oben/unten), Farbschemas (Hell/Dunkel/System) sowie anpassbare Farben und Schriftgrößen in der Liste und in den Logs.", font: .subheadline, color: .secondary)
                        bullet("Höhenerhalt: Speichert die Höhen des Log- und Most Wanted-Panels permanent ab, um ein flüssiges Wiederöffnen zu sichern.", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 2.0.4
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 2.0.4")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("⚡ Stabilitäts- & Timing-Verbesserungen")
                            .font(.subheadline)
                            .bold()
                        bullet("200ms Sendeverzögerung vermindert Paketverluste bei hoher CPU-Last in WSJT-X", font: .subheadline, color: .secondary)
                        bullet("Smarte Wiederholung (max. 3-mal, 3s Takt) falls WSJT-X den TX-Trigger verwirft", font: .subheadline, color: .secondary)
                        bullet("Detaillierte Live-Konsole zur Nachverfolgung übersprungener Stationen", font: .subheadline, color: .secondary)
                        bullet("Sicherheits-Filter verhindert das Anrufen des eigenen Rufzeichens", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
                
                Divider()
                
                // Version 2.0.3
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 2.0.3")
                            .font(.headline)
                            .bold()
                        Text("(Build 120)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🎯 Strikter DXCC-Filter & TX-Triggering")
                            .font(.subheadline)
                            .bold()
                        bullet("Option \"Ausschließlich Most Wanted Stationen anrufen\" in den Einstellungen", font: .subheadline, color: .secondary)
                        bullet("Senden des Shift Modifiers (0x01) erzwingt jetzt zuverlässig \"Enable TX = ON\" in WSJT-X", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                
                Divider()
                
                // Version 2.0.2
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 2.0.2")
                            .font(.headline)
                            .bold()
                        Text("(Build 111)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🛠️ UDP-Protokoll & TX-Steuerung")
                            .font(.subheadline)
                            .bold()
                        bullet("WSJT-X Clear-Nachricht (Typ 3) als Signal für den Start eines neuen Decode-Fensters", font: .subheadline, color: .secondary)
                        bullet("Verwerfen von empfangenen EnableTx & Reply-Paketen auf dem UDP-Port", font: .subheadline, color: .secondary)
                        bullet("Replay-Decodes (isNew=false) verwerfen die Liste nicht mehr fälschlicherweise", font: .subheadline, color: .secondary)
                        bullet("SQLite Logbuch Import-Deduplizierung & Key-Normalisierung", font: .subheadline, color: .secondary)
                        bullet("Banner-Selektion synchronisiert per einfachem Klick auf die Decodier-Tabelle", font: .subheadline, color: .secondary)
                        bullet("Layout-Harmonisierung der Toolbar (AUTO MODE, SYNCHRONISATION, LOGBUCH, FENSTER)", font: .subheadline, color: .secondary)
                        bullet("Integriertes Release-Skript für automatische macOS .dmg Erstellung & GitHub Upload", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                
                Divider()
                
                // Version 2.0.1
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 2.0.1")
                            .font(.headline)
                            .bold()
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🐛 Bugfixes & Präzision")
                            .font(.subheadline)
                            .bold()
                        bullet("Präzise Callsign-Validierung für ambige Präfixe (KG4, KH1/3/4/5/9, KP1/5, ST, 3C, VP6)", font: .subheadline, color: .secondary)
                        bullet("No duplicates im Most-Wanted-Panel — pro Rufzeichen nur ein Eintrag (bestes SNR)", font: .subheadline, color: .secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(8)
                
                Divider()
                
                // Version 2.0.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 2.0.0")
                            .font(.headline)
                            .bold()
                        Text("(Build 90)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text("🔥 Most Wanted & Entfernungspriorisierung")
                            .font(.subheadline)
                            .bold()
                        bullet("Club Log Top 100 Most Wanted DXCC integriert (P5, KH3, KH7K, CE0X, FT/X, 3Y/B, Bouvet, etc.)", font: .subheadline, color: .secondary)
                        bullet("Rote Hervorhebung (🔥 #Rang) in der Decodier-Tabelle für ungearbeitete Most Wanted Stationen", font: .subheadline, color: .secondary)
                        bullet("Gesondertes Most-Wanted-Panel unterhalb der Tabelle – nur Stationen die auf diesem Band noch nicht gearbeitet wurden", font: .subheadline, color: .secondary)
                        bullet("Panel-Höhe mit der Maus stufenlos verstellbar (50–500 pt), Größe wird dauerhaft gespeichert", font: .subheadline, color: .secondary)
                        bullet("Maidenhead Locator → Großkreis-Entfernung (km) via Haversine-Formel", font: .subheadline, color: .secondary)
                        bullet("Entfernungsspalte in der Haupttabelle", font: .subheadline, color: .secondary)
                        bullet("Entfernung & Grid-Square im Stations-Banner (Evaluierungsleiste)", font: .subheadline, color: .secondary)
                        bullet("Most Wanted Rang-Badge im Stations-Banner bei seltenen Entitäten", font: .subheadline, color: .secondary)
                        
                        Text("🎯 Prioritätsreihenfolge (Auto QSO Engine)")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Priorität 1: Most Wanted Entitäten zuerst (Rang #1 = höchste Priorität)", font: .subheadline, color: .secondary)
                        bullet("Priorität 2: Weiteste Entfernung (km) zuerst", font: .subheadline, color: .secondary)
                        bullet("Priorität 3: Stärkstes Signal (SNR dB) als Fallback", font: .subheadline, color: .secondary)
                        
                        Text("⚙️ Einstellungen (Most Wanted & Priorität)")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        bullet("Eigener Maidenhead Grid Locator (z.B. JO31 oder JO31AA)", font: .subheadline, color: .secondary)
                        bullet("Schalter: Most Wanted rot hervorheben", font: .subheadline, color: .secondary)
                        bullet("Schalter: Priorität nach Most Wanted & Entfernung", font: .subheadline, color: .secondary)
                        bullet("Schwelle: Top 10 / 20 / 50 / 100 Most Wanted", font: .subheadline, color: .secondary)
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
                        bullet("Auto QSO Trigger für CQ, 73, RR73 und RRR Decodes", font: .subheadline, color: .secondary)
                        bullet("Inkrementeller LoTW & QRZ Sync (2 Tage vor letztem QSO, UTC)", font: .subheadline, color: .secondary)
                        bullet("Duplicate Prevention via SQLite uniqueKey", font: .subheadline, color: .secondary)
                        bullet("Reset Sync-Startdatum auf 1900 & Logbuch-Neuinitialisierung", font: .subheadline, color: .secondary)
                        bullet("Zeilenweises & Mehrfach-Löschen (🗑️, Kontextmenü, Tastatur)", font: .subheadline, color: .secondary)
                        bullet("Freie Speicherort-Wahl & iCloud Drive Sync", font: .subheadline, color: .secondary)
                        bullet("Einstellungen mit linker Sidebar-Navigation", font: .subheadline, color: .secondary)
                        bullet("Hilfe-Fenster mit Seitenleiste", font: .subheadline, color: .secondary)
                        bullet("3D Retina App Icon für macOS App-Bundle & DMG", font: .subheadline, color: .secondary)
                        bullet("Release-Skript: Versioniertes .dmg, Git-Tagging & GitHub Releases", font: .subheadline, color: .secondary)
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
                Text("Copyright & Urheberrecht")
                    .font(.title)
                    .bold()
                VStack(alignment: .leading, spacing: 8) {
                    Text("AutoQSO — DX-Filter and Automated FT8/FT4 QSO Manager")
                        .font(.headline)
                    Text("Copyright (c) Georg Isenbürger - DJ6GI")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("Alle Rechte vorbehalten.")
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
        let recipient = "support@autoqso.app" // Hier Ziel-E-Mail eintragen
        let subject = "AutoQSO Support Anfrage - v\(APP_VERSION)"
        
        // System & Hardware Details ermitteln
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let hostName = Host.current().localizedName ?? Host.current().name ?? "Unbekannter Mac"
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemoryGB = String(format: "%.1f GB", Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024))
        
        #if arch(arm64)
        let architecture = "Apple Silicon (arm64)"
        #else
        let architecture = "Intel (x86_64)"
        #endif

        let bodyText = """
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
}
