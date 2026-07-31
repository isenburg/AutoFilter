import SwiftUI

enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Übersicht"
    case wsjtx = "WSJT-X Setup"
    case triggers = "Auto QSO Triggers"
    case logbook = "Logbuch & Sync"
    case storage = "Speicherort & iCloud"
    case disclaimer = "Rechtlicher Hinweis"
    case changelog = "Changelog"
    case copyright = "Copyright & Lizenz"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .wsjtx: return "antenna.radiowaves.left.and.right"
        case .triggers: return "bolt.horizontal"
        case .logbook: return "book.closed"
        case .storage: return "folder.fill"
        case .disclaimer: return "exclamationmark.triangle"
        case .changelog: return "list.bullet.rectangle"
        case .copyright: return "c.circle"
        }
    }
}

struct HelpView: View {
    @State private var selectedSection: HelpSection = .overview
    
    var body: some View {
        HStack(spacing: 0) {
            // Non-collapsible Left Sidebar
            VStack(alignment: .leading, spacing: 6) {
                Text("Hilfe Themen")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                
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
        .frame(minWidth: 720, minHeight: 500)
    }
    
    @ViewBuilder
    private func detailView(for section: HelpSection) -> some View {
        switch section {
        case .overview:
            VStack(alignment: .leading, spacing: 12) {
                Text("System-Übersicht")
                    .font(.title)
                    .bold()
                Text("AutoQSO ist eine macOS-Anwendung zur Automatisierung von FT8- und FT4-Kontakten in Verbindung mit WSJT-X.")
                    .font(.body)
                Text("Hauptfunktionen:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Automatische Antworten auf CQ, 73, RR73 und RRR", systemImage: "bolt.fill")
                    Label("Echtzeit-Prüfung gegen SQLite-Logbuch (bereits auf Band gearbeitet)", systemImage: "checkmark.seal.fill")
                    Label("Inkrementeller Sync mit LoTW & QRZ.com (1 Tag vor letztem QSO)", systemImage: "arrow.triangle.2.circlepath")
                    Label("Zeilenweises & Mehrfach-Löschen von Logbucheinträgen", systemImage: "trash")
                    Label("Freie Speicherort-Wahl (Ordner oder iCloud Drive)", systemImage: "folder.fill")
                    Label("Automatische Sperre / Cooldown bei Timeout oder Abbruch", systemImage: "clock.arrow.circlepath")
                }
            }
            
        case .wsjtx:
            VStack(alignment: .leading, spacing: 12) {
                Text("WSJT-X Konfiguration")
                    .font(.title)
                    .bold()
                Text("In WSJT-X unter Settings -> Reporting:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Option 'Prompt me to log QSO' aktivieren.")
                    Text("2. Option 'Accept UDP requests' aktivieren.")
                    Text("3. UDP Server Address: 224.0.0.1 (Multicast) oder 127.0.0.1 (Unicast).")
                    Text("4. UDP Server Port: 2237.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
            }
            
        case .triggers:
            VStack(alignment: .leading, spacing: 12) {
                Text("Auto QSO Trigger Logik")
                    .font(.title)
                    .bold()
                Text("AutoQSO analysiert alle empfangenen WSJT-X Decodes in Echtzeit:")
                    .font(.body)
                VStack(alignment: .leading, spacing: 6) {
                    Text("• CQ Anrufe: CQ, CQ DX, CQ POTA, CQ TEST, etc.")
                    Text("• 73 Nachrichten: z.B. DL1ABC G4XYZ 73")
                    Text("• RR73 / RRR Nachrichten: z.B. K1ABC W1AW RR73")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                Text("Ablauf:")
                    .font(.headline)
                Text("1. Ermittlung des Rufzeichens der sendenden Station.\n2. Abgleich mit dem Logbuch (falls auf dem aktuellen Band bereits gearbeitet -> grau hinterlegt und übersprungen).\n3. Prüfung auf aktiven Cooldown/Sperre.\n4. Senden des Reply-Kommandos an WSJT-X zum automatischen Anruf.")
            }
            
        case .logbook:
            VStack(alignment: .leading, spacing: 12) {
                Text("Logbuch Management & Synchronisation")
                    .font(.title2)
                    .bold()
                
                Text("Inkrementeller Sync:")
                    .font(.headline)
                Text("• Startet automatisch 1 Tag vor dem Datum des neuesten QSOs in der SQLite-Datenbank.\n• Verhindert das doppelte Laden bestehender QSOs durch strikte Eindeutigkeitsprüfung (`uniqueKey`).")
                
                Text("Sync-Datum Reset & Neu-Initialisierung:")
                    .font(.headline)
                Text("• Sync-Datum auf 1900 zurücksetzen: Erzwingt einen Re-Sync ab 1900-01-01 ohne bestehende Daten zu löschen.\n• Logbuch leeren & Re-Sync: Leert die SQLite-Datenbank komplett und baut das Logbuch neu auf.")
                
                Text("Zeilenweises Löschen:")
                    .font(.headline)
                Text("• Jede Zeile verfügt über ein direktes Mülleimer-Icon 🗑️.\n• Mehrere Einträge können per Shift/Cmd markiert und über den Toolbar-Button oder per Rechtsklick gelöscht werden.")
            }
            
        case .storage:
            VStack(alignment: .leading, spacing: 12) {
                Text("Speicherort & iCloud Synchronisation")
                    .font(.title2)
                    .bold()
                
                Text("Konfiguration im Einstellungen-Dialog (Seitenleiste -> Speicherort & iCloud):")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Standard-Ordner: Speichert die Datenbank unter ~/Documents/AutoQSO.")
                    Text("• Benutzerdefinierter Ordner: Freie Wahl eines lokalen Ordners via macOS Dialog.")
                    Text("• iCloud Drive: Speichert in iCloud Drive/AutoQSO zur automatischen Synchronisation zwischen mehreren Macs.")
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(8)
                
                Text("Hinweis: Beim Wechsel des Speicherorts wird die bestehende SQLite-Datenbank automatisch an den neuen Zielort kopiert.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
        case .disclaimer:
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title)
                    Text("Rechtlicher Hinweis & Haftungsausschluss")
                        .font(.title)
                        .bold()
                        .foregroundColor(.orange)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Aufsichtspflicht & Amateurfunkrecht:")
                        .font(.headline)
                    Text("1. Stationskontrolle: Der lizenzierte Funkamateur ist für alle von seiner Station ausgesendeten Signale gemäß den nationalen Fernmeldegesetzen (z.B. TKG/AFuG in Deutschland, BNetzA, FCC) voll verantwortlich.")
                    Text("2. Beaufsichtigter Betrieb: Der automatische Sendebetrieb muss stets beaufsichtigt werden.")
                    Text("3. Gewährleistungsausschluss: Die Software wird 'OHNE JEDE GEWÄHRLEISTUNG' zur Verfügung gestellt.")
                    Text("4. Haftungsbeschränkung: Der Autor (Georg Isenbürger - DJ6GI) übernimmt keinerlei Haftung für Schäden, Ordnungswidrigkeiten oder Folgeschäden.")
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
        case .changelog:
            VStack(alignment: .leading, spacing: 12) {
                Text("Changelog")
                    .font(.title)
                    .bold()
                VStack(alignment: .leading, spacing: 10) {
                    Text("Version \(APP_VERSION) (Build \(APP_BUILD_NUMBER))")
                        .font(.headline)
                    Text("• Most Wanted & Entfernungspriorisierung: Rote Hervorhebung (🔥) von Top 100 Most Wanted DXCC Entitäten, Maidenhead Grid Entfernungsberechnung (km) und automatische Anrufpriorität (Most Wanted > Weiteste Entfernung > SNR).\n• Auto QSO Trigger: Erweiterung um 73, RR73 und RRR Decodes.\n• Inkrementeller Sync: Startet dynamisch 2 Tage vor dem neuesten QSO in der Datenbank (UTC-Kalender).\n• Duplicate Prevention: Strikte Eindeutigkeitsprüfung in SQLite (uniqueKey).\n• Reset-Funktionen: Sync-Startdatum auf 1900 zurücksetzen & Logbuch von Grund auf neu laden.\n• Zeilenweises Löschen: Einzellöschung per 🗑️, Mehrfachauswahl, Kontextmenü & Tastatur-Shortcut.\n• Speicherort & iCloud: Wahl von benutzerdefinierten Ordnern oder iCloud Drive Sync.\n• Einstellungen-Dialog: Überarbeitung mit linker Seitenleiste (Sidebar-Navigation).\n• Hilfe-System: Nicht-einklappbares Hilfe-Fenster mit Seitenleiste.\n• 3D App Icon: Neues Retina macOS 3D Icon im App-Bundle und DMG Installer.\n• Release Automation: Build-Skript mit .dmg Erstellung, Versionierung & GitHub Releases.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
        case .copyright:
            VStack(alignment: .leading, spacing: 12) {
                Text("Copyright & Urheberrecht")
                    .font(.title)
                    .bold()
                VStack(alignment: .leading, spacing: 8) {
                    Text("AutoQSO — Automated FT8/FT4 QSO Manager")
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
}
