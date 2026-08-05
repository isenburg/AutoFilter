import SwiftUI

enum HelpSection: String, CaseIterable, Identifiable {
    case overview = "Übersicht"
    case wsjtx = "WSJT-X Setup"
    case triggers = "Auto QSO Triggers"
    case cluster = "DX Cluster"
    case telnet = "Telnet Server"
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
        case .cluster: return "list.bullet.rectangle.portrait"
        case .telnet: return "terminal"
        case .logbook: return "book.closed"
        case .storage: return "folder.fill"
        case .disclaimer: return "exclamationmark.triangle"
        case .changelog: return "clock"
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
                    Label("WSJTX Auto Transmit: Automatisierte Sende-Engine", systemImage: "bolt.fill")
                    Label("Prüfung gegen SQLite-Logbuch (bereits auf Band gearbeitet)", systemImage: "checkmark.seal.fill")
                    Label("Detektieren von CQ, 73, RR73 und RRR Decodes", systemImage: "bolt.horizontal.fill")
                    Label("Top 100 Most Wanted DXCC – Rote Hervorhebung (🔥) & Priorität", systemImage: "flame.fill")
                    Label("Maidenhead Locator → km Entfernungsberechnung", systemImage: "location.fill")
                    Label("Gesondertes Most-Wanted-Panel (höhenverstellbar via VSplitView) unter der Tabelle", systemImage: "rectangle.split.2x1")
                    Label("DX Cluster Slots (C1, C2, C3) per Dropdown-Picker und Live-Status", systemImage: "list.bullet.rectangle.portrait")
                    Label("Laufender Telnet-Server zur Spotting-Weiterleitung an externe Programme", systemImage: "terminal")
                    Label("Umschaltbare Log-Diagnose (System, WSJT-X-Rohdaten, Cluster-Spots)", systemImage: "doc.text")
                    Label("Abkoppelbare Log-Konsole als eigenständiges, positionierbares Fenster", systemImage: "macwindow.badge.plus")
                    Label("Chronologische Sortierung wählbar (Neueste oben oder unten)", systemImage: "arrow.up.arrow.down.square")
                    Label("Unterstützung von Hell-, Dunkel- und System-Farbschemata", systemImage: "circle.lefthalf.filled")
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
                Text("1. Ermittlung des Rufzeichens der sendenden Station.\n2. Abgleich mit dem Logbuch (falls auf dem aktuellen Band bereits gearbeitet -> grau hinterlegt und übersprungen).\n3. Prüfung auf aktiven Cooldown/Sperre.\n4. Senden des Reply-Kommandos an WSJT-X zum automatischen Anruf (WSJTX Auto Transmit).")
            }
            
        case .cluster:
            VStack(alignment: .leading, spacing: 12) {
                Text("DX Cluster Verbindung & Verwaltung")
                    .font(.title)
                    .bold()
                Text("AutoQSO ermöglicht den Anschluss an bis zu drei parallele DX-Cluster-Verbindungen (C1, C2, C3).")
                    .font(.body)
                
                Text("Zuweisung und Status:")
                    .font(.headline)
                Text("• In der linken Sidebar oder den Einstellungen wählen Sie die gewünschten Cluster aus einem Dropdown-Menü.\n• Status-Indikatoren zeigen an, ob die Verbindung aktiv ist (Grau = Aus, Orange = Verbindungsaufbau, Grün = Verbunden, Rot = Verbindungsfehler).")
                
                Text("Listen-Manager (Einstellungen -> DX Cluster):")
                    .font(.headline)
                Text("• Hinzufügen & Bearbeiten: Sie können eigene Cluster mit Name, Host und Port registrieren.\n• Drag-and-Drop: Die Reihenfolge der Cluster kann direkt in der Tabelle per Maus verschoben und angepasst werden.\n• Zurücksetzen (Restore Defaults): Stellt die ursprüngliche Liste der vordefinierten Standard-Cluster wieder her.")
            }
            
        case .telnet:
            VStack(alignment: .leading, spacing: 12) {
                Text("Telnet Server & Spotting-Ausgabe")
                    .font(.title)
                    .bold()
                Text("AutoQSO läuft als lokaler Telnet-Cluster-Server, an den Sie externe Log-Software (z.B. MacLoggerDX) koppeln können.")
                    .font(.body)
                
                Text("Konfiguration:")
                    .font(.headline)
                Text("• Port & Login: Der Server horcht standardmäßig auf Port 8000. Das Login-Rufzeichen (z.B. GUEST) kann in den Einstellungen angepasst werden.\n• Client-Tracking: Der Live-Status im linken Sidepanel zeigt die Anzahl der aktuell verbundenen externen Programme an.")
                
                Text("WSJT-X Spotter Telnet-Ausgabe:")
                    .font(.headline)
                Text("• Ist dieser Schalter aktiviert, werden alle gefilterten WSJT-X Dekodierungen als rohe DX-Spots im Telnet-Format ausgegeben, sodass sie sofort in Ihrem Log-Programm auf der Karte erscheinen. Standardmäßig ist diese Option deaktiviert (keine Ausgabe).")
            }
            
        case .logbook:
            VStack(alignment: .leading, spacing: 12) {
                Text("Logbuch Management & Synchronisation")
                    .font(.title2)
                    .bold()
                
                Text("Inkrementeller Sync:")
                    .font(.headline)
                Text("• Startet automatisch ab dem QSO-Datum (minus 2 Tage Cooldown) Ihres neuesten Eintrags.\n• Synchronisiert Einträge direkt mit LoTW (Logbook of The World) und QRZ.com XML.")
                
                Text("ADIF-Datei importieren:")
                    .font(.headline)
                Text("• Über den Button 'ADIF Datei hochladen' können Sie bestehende Logbücher im `.adi` / `.adif` Format in Ihre lokale SQLite-Datenbank einspielen. Duplikate werden anhand des eindeutigen Schlüssels (Call, Band, Mode, Zeit) automatisch aussortiert.")
                
                Text("Logbuch leeren / Löschen:")
                    .font(.headline)
                Text("• Löschen (🗑️): QSOs können einzeln oder über Mehrfachauswahl gelöscht werden.\n• Logbuch löschen: Der Button in den Einstellungen entfernt alle lokalen QSOs aus der Datenbank nach Bestätigung eines Sicherheitsdialogs.")
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
            VStack(alignment: .leading, spacing: 16) {
                Text("Changelog")
                    .font(.title)
                    .bold()
                
                // Version 3.0.0
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version 3.0.0")
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
                        Text("🌐 Detektierbare Logs, DX Cluster Manager & Layout-Flexibilität")
                            .font(.subheadline)
                            .bold()
                        Text("• Losgelöste Log-Konsole: Das Diagnosefenster lässt sich abkoppeln und dockt beim Schließen wieder im Hauptfenster an.")
                        Text("• Integrierter Cluster-Manager: Hinzufügen, Editieren, Löschen und per Drag-and-Drop Sortieren von Clustern in den Einstellungen.")
                        Text("• Telnet Server Splittung: DX Cluster und Telnet Server sind eigenständige Abschnitte in Sidebar und Einstellungen.")
                        Text("• ADIF Datei Import: Bequemer Import von QSOs via `.adi`/`.adif`-Dateien direkt über die Einstellungen.")
                        Text("• Ansichtsoptionen: Freie Wahl der chronologischen Sortierung (Neueste oben/unten) und Farbschemas (Hell/Dunkel/System).")
                        Text("• Höhenerhalt: Speichert die Höhen des Log- und Most Wanted-Panels permanent ab, um ein flüssiges Wiederöffnen zu sichern.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.08))
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
                        Text("• 200ms Sendeverzögerung vermindert Paketverluste bei hoher CPU-Last in WSJT-X")
                        Text("• Smarte Wiederholung (max. 3-mal, 3s Takt) falls WSJT-X den TX-Trigger verwirft")
                        Text("• Detaillierte Live-Konsole zur Nachverfolgung übersprungener Stationen")
                        Text("• Sicherheits-Filter verhindert das Anrufen des eigenen Rufzeichens")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
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
                        Text("• Option \"Ausschließlich Most Wanted Stationen anrufen\" in den Einstellungen")
                        Text("• Senden des Shift Modifiers (0x01) erzwingt jetzt zuverlässig \"Enable TX = ON\" in WSJT-X")
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
                        Text("• WSJT-X Clear-Nachricht (Typ 3) als Signal für den Start eines neuen Decode-Fensters")
                        Text("• Verwerfen von empfangenen EnableTx & Reply-Paketen auf dem UDP-Port")
                        Text("• Replay-Decodes (isNew=false) verwerfen die Liste nicht mehr fälschlicherweise")
                        Text("• SQLite Logbuch Import-Deduplizierung & Key-Normalisierung")
                        Text("• Banner-Selektion synchronisiert per einfachem Klick auf die Decodier-Tabelle")
                        Text("• Layout-Harmonisierung der Toolbar (AUTO MODE, SYNCHRONISATION, LOGBUCH, FENSTER)")
                        Text("• Integriertes Release-Skript für automatische macOS .dmg Erstellung & GitHub Upload")
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
                        Text("• Präzise Callsign-Validierung für ambige Präfixe (KG4, KH1/3/4/5/9, KP1/5, ST, 3C, VP6)")
                        Text("• No duplicates im Most-Wanted-Panel — pro Rufzeichen nur ein Eintrag (bestes SNR)")
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
                        Text("• Club Log Top 100 Most Wanted DXCC integriert (P5, KH3, KH7K, CE0X, FT/X, 3Y/B, Bouvet, etc.)")
                        Text("• Rote Hervorhebung (🔥 #Rang) in der Decodier-Tabelle für ungearbeitete Most Wanted Stationen")
                        Text("• Gesondertes Most-Wanted-Panel unterhalb der Tabelle – nur Stationen die auf diesem Band noch nicht gearbeitet wurden")
                        Text("• Panel-Höhe mit der Maus stufenlos verstellbar (50–500 pt), Größe wird dauerhaft gespeichert")
                        Text("• Maidenhead Locator → Großkreis-Entfernung (km) via Haversine-Formel")
                        Text("• Entfernungsspalte in der Haupttabelle")
                        Text("• Entfernung & Grid-Square im Stations-Banner (Evaluierungsleiste)")
                        Text("• Most Wanted Rang-Badge im Stations-Banner bei seltenen Entitäten")
                        
                        Text("🎯 Prioritätsreihenfolge (Auto QSO Engine)")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text("• Priorität 1: Most Wanted Entitäten zuerst (Rang #1 = höchste Priorität)")
                        Text("• Priorität 2: Weiteste Entfernung (km) zuerst")
                        Text("• Priorität 3: Stärkstes Signal (SNR dB) als Fallback")
                        
                        Text("⚙️ Einstellungen (Most Wanted & Priorität)")
                            .font(.subheadline)
                            .bold()
                            .padding(.top, 4)
                        Text("• Eigener Maidenhead Grid Locator (z.B. JO31 oder JO31AA)")
                        Text("• Schalter: Most Wanted rot hervorheben")
                        Text("• Schalter: Priorität nach Most Wanted & Entfernung")
                        Text("• Schwelle: Top 10 / 20 / 50 / 100 Most Wanted")
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
                        Text("• Auto QSO Trigger für CQ, 73, RR73 und RRR Decodes")
                        Text("• Inkrementeller LoTW & QRZ Sync (2 Tage vor letztem QSO, UTC)")
                        Text("• Duplicate Prevention via SQLite uniqueKey")
                        Text("• Reset Sync-Startdatum auf 1900 & Logbuch-Neuinitialisierung")
                        Text("• Zeilenweises & Mehrfach-Löschen (🗑️, Kontextmenü, Tastatur)")
                        Text("• Freie Speicherort-Wahl & iCloud Drive Sync")
                        Text("• Einstellungen mit linker Sidebar-Navigation")
                        Text("• Hilfe-Fenster mit Seitenleiste")
                        Text("• 3D Retina App Icon für macOS App-Bundle & DMG")
                        Text("• Release-Skript: Versioniertes .dmg, Git-Tagging & GitHub Releases")
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
