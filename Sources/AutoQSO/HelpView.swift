import SwiftUI

enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Übersicht"
    case wsjtx = "WSJT-X Setup"
    case triggers = "Auto QSO Triggers"
    case logbook = "LoTW & QRZ Sync"
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
        .frame(minWidth: 700, minHeight: 480)
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
                    Label("Sync mit Logbook of The World (LoTW) & QRZ.com ab 1900-01-01", systemImage: "arrow.triangle.2.circlepath")
                    Label("Automatische Sperre / Cooldown (10-15 Min) bei Timeout oder Abbruch", systemImage: "clock.arrow.circlepath")
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
                Text("LoTW & QRZ.com Synchronisation")
                    .font(.title)
                    .bold()
                Text("Logbook of The World (LoTW):")
                    .font(.headline)
                Text("Fordert alle bestätigten und unbestätigten QSOs ab dem Startdatum 1900-01-01 an, um auch historische Logs vor 2014 vollständig einzulesen.")
                Text("QRZ.com API:")
                    .font(.headline)
                Text("Nutzt die Option MODSINCE:1900-01-01 zum Abruf des gesamten QRZ-Logbuchs.")
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version \(APP_VERSION) (Build \(APP_BUILD_NUMBER))")
                        .font(.headline)
                    Text("• Auto QSO Trigger um 73, RR73 und RRR erweitert.\n• Pre-2014 Historien-Download für LoTW (qso_qsos=1, qso_startdate=1900-01-01) und QRZ (MODSINCE:1900-01-01) korrigiert.\n• Neues Release-Skript mit automatischer Versionierung, .dmg Erstellung und GitHub Upload.\n• Nicht-einklappbares Hilfe-Fenster mit Seitenleiste integriert.")
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
