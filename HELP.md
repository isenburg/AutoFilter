# AutoQSO Hilfe & Dokumentation

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 1. Einleitung & Installation

AutoQSO ist eine macOS-Anwendung für Funkamateure. Die **Hauptfunktion ist der DX-Filter**, der eingehende DX-Spots und Dekodierungen nach flexiblen Kriterien analysiert, farblich klassifiziert und verarbeitet. **Für WSJT-X bietet AutoQSO zusätzlich die automatisierte Auto QSO Sende-Engine**, welche gezielte Anrufe auf FT8- und FT4-Frequenzen vollständig automatisch steuert, gegen das lokale SQLite-Logbuch abgleicht und seltene Most-Wanted-Stationen bevorzugt.

### Interaktiver Installer & macOS Gatekeeper Lösung
Da AutoQSO ad-hoc signiert ist (ohne kostenpflichtiges Apple-Entwickler-Zertifikat), stuft macOS Gatekeeper die App beim ersten Download evtl. als „unbekannter Entwickler“ oder „beschädigt“ ein.

**Installation per Doppelklick (Empfohlen):**
1. Öffnen Sie die heruntergeladene **`AutoQSO-vX.X.X.dmg`** Datei.
2. Starten Sie per Doppelklick das Skript **`Install AutoQSO.command`**.
3. Wählen Sie interaktiv Ihren Zielordner (`/Applications`, `~/Applications` oder manueller Ordner-Dialog). Das Skript kopiert AutoQSO, entfernt das Quarantäne-Attribut (`xattr -cr`) automatisch und startet die App ohne Fehlermeldung.

---

## 2. WSJTX Auto Transmit & Tabellen-Steuerung

Der Hauptschalter in der oberen Menüleiste wurde in **WSJTX Auto Transmit** umbenannt. Er steuert die automatische Steuerung der Sende-Engine:
- **Aktivieren/Deaktivieren**: Ein Klick auf den prominenten Button schaltet die Automatik ein ("WSJTX AUTO TRANSMIT AKTIV", grün) oder aus ("WSJTX AUTO TRANSMIT AUS", grau).
- **Freeze / Pause (Snapshot-Modus)**: Der Pause-Button friert die Dekodiertabelle und Protokolle mit einem statischen Snapshot ein. Auto-Scroll wird deaktiviert und Hintergrunddaten werden weiter empfangen. Sie können völlig frei durch historische Daten scrollen, ohne dass neu ankommende Dekodierungen die Ansicht zurückspringen lassen. Ein erneuter Klick hebt die Pause auf.
- **Echtzeit-Suchfeld**: Über das integrierte Suchfeld in der Toolbar (sowie in den Logs) filtern Sie die Tabelle oder Protokolle in Echtzeit nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text – sowohl im Live- als auch im Freeze-Modus.
- **Min. Sperre / Cooldown**: Das Feld für die Cooldown-Dauer (Standard: 10 Minuten) blockiert Rufzeichen nach einem automatischen Anruf temporär vor weiteren Sendeversuchen.

---

## 3. Most Wanted & Entfernungspriorisierung

- **Top 100 Most Wanted DXCC**: Integrierte Club Log Most Wanted Liste (z.B. P5, KH3, KH7K, Bouvet, etc.).
- **Rote Hervorhebung (🔥)**: Ungearbeitete Most Wanted Stationen werden in der Decodier-Tabelle knallrot mit Rang-Badge markiert (z.B. `🔥 #1`).
- **Gesondertes Most-Wanted-Panel**: Unterhalb der Haupttabelle zeigt ein eigenes Panel ausschließlich die gerade empfangenen Most Wanted Stationen an, die auf dem aktuellen Band noch **nicht gearbeitet** wurden.
- **Größenanpassung**: Die Höhe des Panels lässt sich über die native macOS Trennlinie (`VSplitView`) stufenlos verändern. Die eingestellte Größe wird automatisch in den Benutzerdaten gespeichert.
- **Entfernung**: Automatische Berechnung der Großkreis-Entfernung in Kilometern via Haversine-Formel basierend auf dem Grid-Locator der Station und Ihrem eigenen Standort-Locator.

---

## 4. DX Cluster Manager & Spot-Verarbeitung

Die Steuerung der DX-Cluster-Verbindung wurde komplett modernisiert:
- **Sende-Slots**: In der Sidebar oder in den Einstellungen können Sie bis zu drei parallele DX-Cluster-Verbindungen (C1, C2, C3) per Dropdown-Picker auswählen.
- **Verbindungsstatus**: Farbige Kreise zeigen den Live-Status an (Grau = Deaktiviert, Orange = Verbindungsaufbau, Grün = Verbunden, Rot = Fehler).
- **Universelles Spot-Parsing**: Alle eintreffenden Spots gängiger Knoten-Formate (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider) werden automatisch erfasst.
- **Vollständige Listenanzeige & Farbkodierung**: Alle empfangenen Spots und Dekodierungen werden ohne Vorab-Löschung in der Haupttabelle dargestellt. Filter-Regeln löschen keine Einträge mehr, sondern steuern die farbliche Hervorhebung (z.B. Grau für blockiert) und automatische Aktionen.
- **Länder- & Spotter-Filterung**: Autovervollständigung beim Tippen sowie Teilstring- & Regionenerkennung (Eingaben wie `Russia` oder `Russland` stimmen automatisch mit `European Russia` und `Asiatic Russia` überein).
- **Listen-Verwaltung (Einstellungen -> DX Cluster)**:
  - **Hinzufügen**: Neuen Cluster mit Name, Host und Port registrieren.
  - **Löschen**: Über das Mülleimer-Icon 🗑️ Einträge entfernen.
  - **Bearbeiten**: Über das Stift-Icon 📝 Werte anpassen.
  - **Drag-and-Drop Sortierung**: Einträge in der Liste können per Maus direkt verschoben und neu geordnet werden.
  - **A-Z Sortierung**: Schnelles alphabetisches Sortieren der Clusterliste.
  - **Zurücksetzen (Restore Defaults)**: Setzt die Liste komplett auf die vordefinierten Standard-Cluster (RBN, VE7CC, K3LR, etc.) zurück.

---

## 5. Telnet Server

AutoQSO enthält einen eigenen Telnet-Cluster-Server, an den sich externe Log- oder Mapping-Programme (z.B. MacLoggerDX) connecten können:
- **Port & Callsign**: Standardmäßig horcht der Server auf Port `8000`. Das Login-Rufzeichen (Standard `GUEST`) ist frei wählbar.
- **Live-Status**: Zeigt an, ob der Server aktiv ist und wie viele externe Clients aktuell verbunden sind.
- **WSJT-X Decodes Telnet-Ausgabe**: Ein Schalter ermöglicht es, alle lokalen WSJT-X Dekodierungen nach Durchlaufen Ihrer Filter als DX-Spots über Telnet auszugeben. Standardmäßig ist diese Option deaktiviert (keine Telnet-Ausgabe).

---

## 6. Logbuch-Sync & ADIF-Import

Sämtliche Logbuch-Optionen wurden im Einstellungsreiter **Logbuch-Sync** konsolidiert:
- **LoTW & QRZ.com**: Eingabe der Zugangsdaten und manueller Live-Abgleich. Der Sync erfolgt inkrementell (standardmäßig ab 2 Tage vor dem letzten QSO).
- **ADIF-Datei hochladen**: Sie können Ihre QSOs aus Drittprogrammen über eine ADIF-Datei (`.adi` oder `.adif`) importieren. AutoQSO liest die Datei ein, filtert Duplikate heraus und fügt neue QSOs in die lokale SQLite-Datenbank ein.
- **Logbuch-Sync-Intervall**: Ermöglicht einen kontinuierlichen Abgleich Ihrer QSOs.
- **Logbuch löschen**: Löscht alle lokalen QSOs aus der SQLite-Datenbank nach einer Sicherheitsabfrage.

---

## 7. Logs & Rohdaten (Log-Konsole)

Zur Diagnose und Rohdaten-Überwachung verfügt die App über drei umschaltbare Konsolen:
- **System-Logs**: Interne Status- und Fehlermeldungen (z.B. Socket-Bindungsfehler oder Verbindungsabbrüche).
- **WSJT-X Rohdaten**: Zeigt empfangene UDP-Pakete an. Kann über Checkboxen nach *Decodes* (Dekodierungen), *Eingang* (Steuerdaten von WSJT-X) und *Ausgang* (gesendete Befehle) gefiltert werden.
- **Cluster-Spots**: Listet alle rohen DX-Spots auf, die von den verbundenen Upstream-Clustern empfangen wurden.
- **Log-Suchfeld**: Eigenes Echtzeit-Suchfeld in der Log-Konsole zum Filtern der Protokollmeldungen.
- **Log-Löschen (🗑️)**: Ein Klick auf das Mülleimer-Symbol leert die aktiven Log-Einträge.
- **Konsole abkoppeln (Eigenes Fenster)**: Über das Abkopplungs-Icon oben rechts in der Konsole lässt sich die Log-Ansicht in ein eigenes, frei positionierbares macOS-Fenster auslagern. Beim Schließen des Fensters dockt die Konsole automatisch wieder im Hauptfenster an. Die Konsolenhöhe im Hauptfenster wird beim Ziehen der Trennlinie automatisch gespeichert.

---

## 8. Ansichtsoptionen

Im Einstellungsreiter **Ansicht** können visuelle Vorlieben konfiguriert werden:
- **Sortierung**: Legen Sie fest, ob neue Einträge in der Decodier-Tabelle und den Listen oben (Newest on Top) oder unten (Newest on Bottom) angefügt werden sollen. Dies lässt sich auch direkt in der Hauptansicht über den Pfeil-Button umschalten.
- **Farbschema**: Wählen Sie zwischen **System** (folgt den macOS-Systemeinstellungen), **Hell** (Light Mode) und **Dunkel** (Sleek Dark Mode).
- **Schriftgrößen**: Schieberegler für die Schriftgröße der Decodier-Tabelle (8-20 pt) und der Log-Konsole (8-20 pt).
- **Farbanpassungen**:
  - **Tabelle**: Eigene Farben für Standard-Text, Most Wanted (🔥), interessante CQ-Rufe und gearbeitete Stationen.
  - **Log-Konsole**: Anpassbare Farben für Konsolen-Hintergrund, System-Logs, WSJT-X Dekodierungen, Eingang (Steuerdaten), Ausgang (Sendedaten) und Cluster-Spots.
- **Standardwerte**: Ein Button setzt alle Farben und Schriftgrößen auf den ursprünglichen Standardzustand zurück.

## 9. Ausbreitungskarte (Propagation Map)

Über den Button **Karte ↗** in der Menüleiste/Toolbar (im Bereich FENSTER) kann die **Ausbreitungskarte** in einem eigenständigen, separaten Fenster geöffnet werden:
- **Karte**: Zeigt eine interaktive Landkarte mit Annotations-Badges der aktiven Länder. Auf den Badges sind die Bänder und die Anzahl der Spots (z.B. `20M:5`) verzeichnet.
- **Aktiver QSO-Pfad & Live-Banner**: Bei einem aktiven WSJT-X QSO/Anruf wird sowohl auf der 2D-Flachkarte als auch auf dem 3D-Globus eine leuchtend gelbe Großkreis-Verbindungslinie (`MKGeodesicPolyline` / `MapPolyline`) zwischen Ihrem eigenen QTH (grünes 🏠 Symbol) und der Zielstation gezeichnet. Ein Live-Statusbanner oben mittig zeigt Rufton, Ziel-Locator und Entfernung in km an.
- **Kartenstile & 3D-Globus**: Auswahl zwischen Standard, Satellit, Hybrid und nativer 3D-Globusansicht (Kugeldarstellung). Der Kartenstil lässt sich für Ausbreitungskarte und Grid-Karte unabhängig wählen.
- **3D Maidenhead Grid & Schattierung**: Im 3D-Globus-Modus werden Maidenhead-Gitterlinien sowie gearbeitete 4-Stellen-Planquadrate als 3D-Geometrie direkt auf die Erdkugel projiziert. Ein Klick auf ein gearbeitetes Feld öffnet das Grid-Logbuchfenster.
- **Eigenes QTH & Interaktiver QTH Picker**: Im Einstellungsfenster unter *Eigenes QTH (Maidenhead)* lässt sich der eigene Locator präzise bis zu 8 Stellen (z.B. `JO31AA24`) angeben. Ein Klick auf *Interaktive Karte zum Wählen 🗺️* öffnet eine interaktive Zoom-Karte mit dynamischem Maidenhead-Gitter und Google-Style Drop-Pin zum bequemen Wählen des eigenen Standorts per Mausklick.
- **Datenbasis**: Die Karte aggregiert ausschließlich Spots und Decodes, die die aktiven Filterkriterien erfolgreich durchlaufen haben (d.h. nicht blockiert sind).
- **Steuerungsoverlay (oben links)**:
  - **Zeitfenster**: Stepper zur Einstellung des Auswertungszeitfensters (5 bis 120 Minuten).
  - **Gearbeitete mitzählen**: Ein Ein-/Ausschalter. Standardmäßig werden bereits gearbeitete Stationen herausgefiltert. Ist dieser Schalter aktiviert, werden auch Stationen, die bereits auf dem Band gearbeitet wurden, in der Karte dargestellt und gezählt.
  - **Statistik-Zähler**: Zeigt die Gesamtanzahl der empfangenen ("Empf.") und weitergeleiteten ("Durchg.") Decodes/Spots pro Stunde an.
- **Sidebar**: Listet alle aktiven Länder auf, sortierbar nach Kontinent (einklappbar), alphabetisch (A-Z) oder nach Anzahl der Spots.

---

## 10. Kompaktmodus (Compact Mode)

Um den Platzbedarf auf dem Bildschirm drastisch zu reduzieren, kann AutoQSO über den Button **Kompakt** in der Menüleiste (Bereich FENSTER) in einen reduzierten Anzeigemodus versetzt werden.
- **Reduzierte Oberfläche**: Blendet alle Log-Konsolen, Seitenleisten und die Statusleiste aus. Das Fenster lässt sich danach extrem klein zusammenschieben (bis zu `480x320` Pixel).
- **Steuerleiste (oben)**: Bietet schnellen Zugriff auf:
  - **Auto ON / Auto OFF**: Aktiviert oder deaktiviert den automatischen Sendebetrieb.
  - **Filter AN / Filter AUS**: Schaltet die globalen DX-Filterregeln ein oder aus.
  - **Karte ↗**: Öffnet das separate Fenster der Ausbreitungskarte.
  - **WSJT-X & TX Status**: Kompakte Status-Lämpchen zur Überwachung der Verbindung und Sendeaktivität.
  - **Normaler Modus Button**: Über das Pfeilsymbol ganz rechts wird die normale Vollansicht wiederhergestellt.
- **Haupttabelle**: Zeigt eine reduzierte Decodier-Tabelle (Zeit, DX Call, Land, SNR, Nachricht) der gefilterten Spots.
- **Most Wanted**: Ein horizontaler, platzsparender Ticker am unteren Rand listet aktive, ungearbeitete Most Wanted Stationen auf, die durch Anklicken sofort im Info-Banner fokussiert werden können.

---

## 11. Rechtlicher Hinweis

> **WICHTIGER RECHTLICHER HINWEIS**
>
> Das Betreiben eines Amateurfunksenders unter automatischer Steuerung unterliegt nationalen Gesetzen und Vorschriften (z.B. BNetzA in Deutschland, FCC in den USA).
>
> Der Steuernde (Control Operator) ist für alle gesendeten Signale verantwortlich. Lassen Sie einen automatisierten Sender niemals unbeaufsichtigt laufen, sofern dies nicht durch Ihre Lizenzklasse und lokale Vorschriften erlaubt ist.
>
> Software wird „AS IS" bereitgestellt, ohne jegliche Garantie.
