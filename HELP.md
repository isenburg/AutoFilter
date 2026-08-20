# AutoQSO Hilfe & Dokumentation

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 1. Einleitung & Installation

AutoQSO ist eine macOS-Anwendung für Funkamateure. Die **Hauptfunktion ist der DX-Filter**, der eingehende DX-Spots und Dekodierungen nach flexiblen Kriterien analysiert, farblich klassifiziert und verarbeitet. **Für WSJT-X bietet AutoQSO zusätzlich die automatisierte Auto QSO Sende-Engine**, welche gezielte Anrufe auf FT8- und FT4-Frequenzen vollständig automatisch steuert, gegen das lokale SQLite-Logbuch abgleicht und seltene Most-Wanted-Stationen bevorzugt.

### Systemvoraussetzungen
- **Betriebssystem**: macOS 14.0 (Sonoma) oder neuer (einschließlich macOS 15 Sequoia).
- **Prozessor / Architektur**: Universal Binary (Nativ für **Apple Silicon** M1/M2/M3/M4 & **Intel Macs** `x86_64`).

### Interaktiver Installer & macOS Gatekeeper Lösung
Da AutoQSO ad-hoc signiert ist (ohne kostenpflichtiges Apple-Entwickler-Zertifikat), stuft macOS Gatekeeper die App beim ersten Download evtl. als „unbekannter Entwickler“ oder „beschädigt“ ein. Im DMG stehen zwei Wege zur Verfügung:

**Option 1: Nativer 1-Klick GUI Installer (Empfohlen)**
1. Öffne die heruntergeladene **`AutoQSO-vX.X.X.dmg`** Datei.
2. Starte per Doppelklick die App **`AutoQSO Installer.app`** (falls Gatekeeper warnt: *Rechtsklick -> Öffnen*).
3. Wähle deinen Zielordner (`/Applications`, `~/Applications` oder Finder-Dialog). Der Installer kopiert AutoQSO, entfernt das Quarantäne-Attribut (`xattr -cr`) automatisch und startet die App ohne Fehlermeldung.

**Option 2: Terminal-Installationsskript**
- Starte per Doppelklick das Skript **`Install AutoQSO.command`** und folge den Anweisungen im Terminal.

---

## 2. Quickstart – Mindesteinstellungen in 4 Schritten

Für den erfolgreichen Betrieb von AutoQSO sind lediglich vier grundlegende Einstellungen erforderlich:

1. **Eigenes Rufzeichen & Grid-Locator (Heimat-QTH)**
   - *Eigenes Rufzeichen*: Wird unter **Einstellungen (⚙️) -> Telnet Server** (*Rufzeichen für Login*) eingestellt (relevant für Cluster-Verbindungen und den lokalen Telnet-Server).
   - *Grid-Locator*: Wird unter **Einstellungen (⚙️) -> Eigenes QTH (Maidenhead)** eingegeben (z. B. `JO31AA24` oder per interaktivem Karten-Picker 🗺️).
   - *Details*: Siehe Abschnitt [6. Telnet Server](#6-telnet-server) und [10. Ausbreitungskarte](#10-ausbreitungskarte-propagation-map).

2. **WSJT-X UDP-Verbindung (Empfang & Auto Transmit)**
   - *Zweck*: Empfang von FT8/FT4 Dekodierungen und automatische Antwortkommandos.
   - *Einstellung in WSJT-X*: Unter **Settings -> Reporting** aktivieren:
     - `Prompt me to log QSO` [x]
     - `Accept UDP requests` [x]
     - `UDP Server Address: 224.0.0.1` (oder `127.0.0.1`), `UDP Server Port: 2237`
   - *Details*: Siehe Abschnitt [3. WSJTX Auto Transmit](#3-wsjtx-auto-transmit--tabellen-steuerung).

3. **Logbuch-Synchronisation (RUMlogNG / LoTW / QRZ.com / ADIF)**
   - *Zweck*: Echtzeit-Abgleich gegen bereits getätigte QSOs, Vermeidung von Doppel-QSOs, Markierung neuer Grids/Länder.
   - *Einstellung*: **Einstellungen (⚙️) -> Logbuch-Sync** öffnen, Quelle auswählen (**RUMlogNG**, **LoTW** oder **QRZ.com**) und Sync starten (oder ADIF-Datei importieren).
   - *Details*: Siehe Abschnitt [7. Logbuch-Sync & ADIF-Import](#7-logbuch-sync--adif-import).

4. **DX Cluster (Optional, empfohlen)**
   - *Zweck*: Paralleler Empfang von DX-Spots über bis zu 3 Verbindungen (C1, C2, C3).
   - *Einstellung*: Dropdown-Picker in der linken Seitenleiste oder unter **Einstellungen (⚙️) -> DX Cluster**.
   - *Details*: Siehe Abschnitt [5. DX Cluster Manager & Spot-Verarbeitung](#5-dx-cluster-manager--spot-verarbeitung).

---

## 3. WSJTX Auto Transmit & Tabellen-Steuerung

Der Hauptschalter in der oberen Menüleiste steuert die automatische Sende-Engine:
- **Aktivieren/Deaktivieren**: Ein Klick auf den prominenten Button schaltet die Automatik ein ("WSJTX AUTO TRANSMIT AKTIV", grün) oder aus ("WSJTX AUTO TRANSMIT AUS", grau).
- **Freeze / Pause (Snapshot-Modus)**: Der Pause-Button friert die Dekodiertabelle und Protokolle mit einem statischen Snapshot ein. Auto-Scroll wird deaktiviert und Hintergrunddaten werden weiter empfangen. Du kannst völlig frei durch historische Daten scrollen, ohne dass neu ankommende Dekodierungen die Ansicht zurückspringen lassen. Ein erneuter Klick hebt die Pause auf.
- **Echtzeit-Suchfeld**: Über das integrierte Suchfeld in der Toolbar (sowie in den Logs) filterst du die Tabelle oder Protokolle in Echtzeit nach Rufzeichen, Land, Spotter, Grid-Locator oder Nachrichten-Text – sowohl im Live- als auch im Freeze-Modus.
- **Min. Sperre / Cooldown**: In den **Einstellungen (⚙️) -> WSJT-X** kann die Cooldown-Dauer (Standard: 10 Minuten) konfiguriert werden, um Rufzeichen nach einem automatischen Anruf temporär vor weiteren Sendeversuchen zu blockieren.

---

## 4. DX-Filter & Filter-Sidebar

Die rechte Filter-Sidebar bietet eine Vielzahl feingranularer Kriterien zur Filterung eingehender Dekodierungen und Spots:
1. **Kontinent-Filter**: Schaltet einzelne Kontinente (AF, AN, AS, EU, NA, OC, SA) flexibel an oder aus.
2. **Gesperrte Länder (Blacklist)**: Blockiert Signale aus ausgewählten DXCC-Ländern.
3. **Erlaubte DX-Länder (Whitelist)**: Lässt ausschließlich Stationen aus den eingetragenen Ländern durch.
4. **Gesperrte CQ-Zonen**: Blockiert gezielt Stationen aus bestimmten CQ-Zonen (1–40).
5. **Gesperrte ITU-Zonen**: Blockiert gezielt Stationen aus bestimmten ITU-Zonen (1–90).
6. **Erlaubte DX-Rufzeichen**: Whitelist-Modus nach Rufzeichen-Präfixen (z. B. `DP0`, `K1`).
7. **Gearbeitete Stationen (Neu in v3.5.0)**:
   - *Funktion*: Ermöglicht es, bereits gearbeitete Stationen auf dem Band nach Ablauf einer frei konfigurierbaren Zeitspanne wieder durchzulassen und als interessante AutoQSO-Kandidaten freizugeben.
   - *Zeitspanne*: Beliebige Zifferneingabe von `0` bis `999`.
   - *Einheit*: Wählbar zwischen `Stunden`, `Tagen`, `Monaten` und `Jahren`.
   - *Beispiel*: Bei Einstellung von `1 Monat` werden Stationen, deren letztes QSO auf dem Band älter als 1 Monat ist, wieder grün hervorgehoben und für automatische Anrufe zugelassen. Stationen, die innerhalb des letzten Monats gearbeitet wurden, bleiben blockiert.
8. **Maidenhead Grid-Filter**: Filtert nach neuen, noch nicht gearbeiteten 4-Stellen- (`JO31`) oder 6-Stellen-Grids (`JO31aa`).
9. **WSJT-X CQ Filter**: Lässt nur Anrufe durch, die `CQ`, `RR73`, `RRR` oder `73` enthalten.
10. **Doubletten-Filter**: Verhindert doppelte Dekodierungen des gleichen Rufzeichens auf derselben Frequenz innerhalb eines konfigurierbaren Zeitfensters (1–15 Min.) und Frequenztoleranz (0.5–3.0 kHz).

---

## 5. DX Cluster Manager & Spot-Verarbeitung

Der DX-Cluster-Manager ermöglicht den gleichzeitigen Empfang von DX-Spots über bis zu drei unabhängige Telnet-Verbindungen:
- **3 parallele Verbindungen (C1, C2, C3)**: Beliebige Server aus der Liste zuweisen oder deaktivieren.
- **Verbindungsstatus**: Farbige Kreise zeigen den Live-Status an (Grau = Deaktiviert, Orange = Verbindungsaufbau, Grün = Verbunden, Rot = Fehler).
- **Universelles Spot-Parsing**: Alle eintreffenden Spots gängiger Knoten-Formate (VE7CC, K3LR, RBNet, AR-Cluster, CC-Cluster, DXSpider) werden automatisch erfasst.
- **Vollständige Listenanzeige & Farbkodierung**: Alle empfangenen Spots und Dekodierungen werden in der Haupttabelle dargestellt. Filter-Regeln steuern die farbliche Hervorhebung (Grün = CQ/Kandidat, Rot = Most Wanted, Blassrot/Grau = Gearbeitet/Blockiert).
- **Länder- & Spotter-Filterung**: Autovervollständigung beim Tippen sowie Teilstring- & Regionenerkennung (Eingaben wie `Russia` oder `Russland` stimmen automatisch mit `European Russia` und `Asiatic Russia` überein).
- **Listen-Verwaltung (Einstellungen -> DX Cluster)**: Hinzufügen, Bearbeiten, Löschen, Drag-and-Drop Sortieren und Zurücksetzen auf Standard-Cluster (RBN, VE7CC, K3LR, etc.).

---

## 6. Telnet Server

AutoQSO enthält einen eigenen Telnet-Cluster-Server, an den sich externe Log- oder Mapping-Programme (z.B. MacLoggerDX) connecten können:
- **Port & Callsign**: Standardmäßig horcht der Server auf Port `8000`. Das Login-Rufzeichen (Standard `GUEST`) ist frei wählbar.
- **Live-Status**: Zeigt an, ob der Server aktiv ist und wie viele externe Clients aktuell verbunden sind.
- **WSJT-X Decodes Telnet-Ausgabe**: Ein Schalter ermöglicht es, alle lokalen WSJT-X Dekodierungen nach Durchlaufen deiner Filter als DX-Spots über Telnet auszugeben. Standardmäßig ist diese Option deaktiviert.

---

## 7. Logbuch-Sync & ADIF-Import

Sämtliche Logbuch-Optionen wurden im Einstellungsreiter **Logbuch-Sync** konsolidiert:
- **RUMlogNG (macOS App)**: 1-Klick-Synchronisation über die native macOS AppleScript-Schnittstelle von RUMlogNG (`ReadAdif`).
- **LoTW & QRZ.com**: Eingabe der Zugangsdaten und Abgleich (Vollständig ab 1900 oder inkrementell).
- **ADIF-Datei importieren**: Du kannst deine QSOs aus Drittprogrammen über eine ADIF-Datei (`.adi` oder `.adif`) importieren. AutoQSO liest die Datei ein, filtert Duplikate heraus und fügt neue QSOs in die lokale SQLite-Datenbank ein.
- **Intelligente Deduplizierung**: Erkennt und fusioniert doppelte QSOs durch Start-/Endzeit-Abweichungen (`TIME_ON` vs. `TIME_OFF`) automatisch.
- **Logbuch löschen**: Löscht alle lokalen QSOs aus der SQLite-Datenbank nach einer Sicherheitsabfrage.

---

## 8. Most Wanted & Entfernungspriorisierung

- **Top 100 Most Wanted DXCC**: Integrierte Club Log Most Wanted Liste (z.B. P5, KH3, KH7K, Bouvet, etc.).
- **Rote Hervorhebung (🔥)**: Ungearbeitete Most Wanted Stationen werden in der Decodier-Tabelle knallrot mit Rang-Badge markiert (z.B. `🔥 #1`).
- **Gesondertes Most-Wanted-Panel**: Unterhalb der Haupttabelle zeigt ein eigenes Panel ausschließlich die gerade empfangenen Most Wanted Stationen an, die auf dem aktuellen Band noch nicht gearbeitet wurden.
- **Größenanpassung**: Die Höhe des Panels lässt sich über die native macOS Trennlinie (`VSplitView`) stufenlos verändern und wird gespeichert.
- **Entfernung**: Automatische Berechnung der Großkreis-Entfernung in Kilometern via Haversine-Formel basierend auf dem Grid-Locator der Station und deinem eigenen Standort-Locator.

---

## 9. Logs & Rohdaten (Log-Konsole)

Zur Diagnose und Rohdaten-Überwachung verfügt die App über drei umschaltbare Konsolen:
- **System-Logs**: Interne Status- und Fehlermeldungen (z.B. Socket-Bindungsfehler oder Verbindungsabbrüche).
- **WSJT-X Rohdaten**: Zeigt empfangene UDP-Pakete an. Kann über Checkboxen nach *Decodes* (Dekodierungen), *Eingang* (Steuerdaten von WSJT-X) und *Ausgang* (gesendete Befehle) gefiltert werden.
- **Cluster-Spots**: Listet alle rohen DX-Spots auf, die von den verbundenen Upstream-Clustern empfangen wurden.
- **Log-Suchfeld**: Eigenes Echtzeit-Suchfeld in der Log-Konsole zum Filtern der Protokollmeldungen.
- **Log-Löschen (🗑️)**: Ein Klick auf das Mülleimer-Symbol leert die aktiven Log-Einträge.
- **Konsole abkoppeln (Eigenes Fenster)**: Über das Abkopplungs-Icon oben rechts in der Konsole lässt sich die Log-Ansicht in ein eigenes, frei positionierbares macOS-Fenster auslagern.

---

## 10. Ausbreitungskarte (Propagation Map) & 3D-Globus

Über den Button **Karte ↗** in der Menüleiste/Toolbar kann die **Ausbreitungskarte** in einem eigenständigen Fenster geöffnet werden:
- **Karte**: Zeigt eine interaktive Landkarte mit Annotations-Badges der aktiven Länder. Auf den Badges sind die Bänder und die Anzahl der Spots (z.B. `20M:5`) verzeichnet.
- **Aktiver QSO-Pfad & Live-Banner**: Bei einem aktiven WSJT-X QSO wird sowohl auf der 2D-Flachkarte als auch auf dem 3D-Globus eine leuchtend gelbe Großkreis-Verbindungslinie zwischen deinem QTH (🏠) und der Zielstation gezeichnet. Ein Live-Statusbanner oben mittig zeigt Rufton, Ziel-Locator und Entfernung in km an.
- **Kartenstile & 3D-Globus**: Auswahl zwischen Standard, Satellit, Hybrid und nativer 3D-Globusansicht (Kugeldarstellung).
- **3D Maidenhead Grid & Schattierung**: Im 3D-Globus-Modus werden Maidenhead-Gitterlinien sowie gearbeitete 4-Stellen-Planquadrate direkt auf die Erdkugel projiziert.
- **Eigenes QTH & Interaktiver QTH Picker**: Im Einstellungsfenster unter *Eigenes QTH (Maidenhead)* lässt sich der Locator präzise bis zu 8 Stellen angeben oder per interaktivem Karten-Picker wählen.

---

## 11. Kompaktmodus (Compact Mode)

Über den Button **Kompakt** in der Toolbar lässt sich AutoQSO auf ein Minimum reduzieren (bis zu `480x320` Pixel):
- Blendet Log-Konsolen und Seitenleisten aus.
- Kompakte Steuerleiste oben mit schnellem Zugriff auf Auto ON/OFF, Filter AN/AUS, Karte ↗ und Status-Indikatoren.
- Platzsparender Most-Wanted-Ticker am unteren Fensterrand.

---

## 12. Rechtlicher Hinweis

> **WICHTIGER RECHTLICHER HINWEIS**
>
> Das Betreiben eines Amateurfunksenders unter automatischer Steuerung unterliegt nationalen Gesetzen und Vorschriften (z.B. BNetzA in Deutschland, FCC in den USA).
>
> Der Steuernde (Control Operator) ist für alle gesendeten Signale verantwortlich. Lasse einen automatisierten Sender niemals unbeaufsichtigt laufen, sofern dies nicht durch deine Lizenzklasse und lokale Vorschriften erlaubt ist.
>
> Software wird „AS IS" bereitgestellt, ohne jegliche Garantie.
