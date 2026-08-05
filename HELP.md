# AutoQSO Hilfe & Dokumentation

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 1. Einleitung

AutoQSO ist eine macOS-Anwendung zur Automatisierung von FT8- und FT4-Kontakten in Verbindung mit WSJT-X. Die App überwacht eingehende Decodes per UDP, gleicht diese mit einem lokalen SQLite-Logbuch ab, hebt seltene Most-Wanted-Stationen hervor, leitet Spots weiter und wickelt automatische Anrufe nach frei konfigurierbaren Kriterien ab.

---

## 2. WSJTX Auto Transmit (Zuvor Auto Mode)

Der Hauptschalter in der oberen Menüleiste wurde in **WSJTX Auto Transmit** umbenannt. Er steuert die automatische Steuerung der Sende-Engine:
- **Aktivieren/Deaktivieren**: Ein Klick auf den prominenten Button schaltet die Automatik ein ("WSJTX AUTO TRANSMIT AKTIV", grün) oder aus ("WSJTX AUTO TRANSMIT AUS", grau).
- **Min. Sperre / Cooldown**: Daneben befindet sich das Feld für die Cooldown-Dauer (Standard: 10 Minuten). Wenn ein automatischer Anruf getätigt wird, wird das Rufzeichen für diesen Zeitraum für weitere automatische Sendeversuche blockiert. Dies verhindert Endlosschleifen bei nicht antwortenden Stationen.

---

## 3. Most Wanted & Entfernungspriorisierung

- **Top 100 Most Wanted DXCC**: Integrierte Club Log Most Wanted Liste (z.B. P5, KH3, KH7K, Bouvet, etc.).
- **Rote Hervorhebung (🔥)**: Ungearbeitete Most Wanted Stationen werden in der Decodier-Tabelle knallrot mit Rang-Badge markiert (z.B. `🔥 #1`).
- **Gesondertes Most-Wanted-Panel**: Unterhalb der Haupttabelle zeigt ein eigenes Panel ausschließlich die gerade empfangenen Most Wanted Stationen an, die auf dem aktuellen Band noch **nicht gearbeitet** wurden.
- **Größenanpassung**: Die Höhe des Panels lässt sich über die native macOS Trennlinie (`VSplitView`) stufenlos verändern. Die eingestellte Größe wird automatisch in den Benutzerdaten gespeichert.
- **Entfernung**: Automatische Berechnung der Großkreis-Entfernung in Kilometern via Haversine-Formel basierend auf dem Grid-Locator der Station und Ihrem eigenen Standort-Locator.

---

## 4. DX Cluster Manager

Die Steuerung der DX-Cluster-Verbindung wurde komplett modernisiert. Anstatt Host und Port manuell einzutippen, wählen Sie diese komfortabel aus einer zentralen Liste:
- **Sende-Slots**: In der Sidebar oder in den Einstellungen können Sie bis zu drei parallele DX-Cluster-Verbindungen (C1, C2, C3) per Dropdown-Picker auswählen.
- **Verbindungsstatus**: Farbige Kreise zeigen den Live-Status an (Grau = Deaktiviert, Orange = Verbindungsaufbau, Grün = Verbunden, Rot = Fehler).
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
- **Konsole abkoppeln (Eigenes Fenster)**: Über das Abkopplungs-Icon oben rechts in der Konsole lässt sich die Log-Ansicht in ein eigenes, frei positionierbares macOS-Fenster auslagern. Beim Schließen des Fensters dockt die Konsole automatisch wieder im Hauptfenster an. Die Konsolenhöhe im Hauptfenster wird beim Ziehen der Trennlinie automatisch gespeichert.

---

## 8. Ansichtsoptionen

Im Einstellungsreiter **Ansicht** können visuelle Vorlieben konfiguriert werden:
- **Sortierung**: Legen Sie fest, ob neue Einträge in der Decodier-Tabelle und den Listen oben (Newest on Top) oder unten (Newest on Bottom) angefügt werden sollen. Dies lässt sich auch direkt in der Hauptansicht über den Pfeil-Button umschalten.
- **Farbschema**: Wählen Sie zwischen **System** (folgt den macOS-Systemeinstellungen), **Hell** (Light Mode) und **Dunkel** (Sleek Dark Mode).

---

## 9. Rechtlicher Hinweis

> **WICHTIGER RECHTLICHER HINWEIS**
>
> Das Betreiben eines Amateurfunksenders unter automatischer Steuerung unterliegt nationalen Gesetzen und Vorschriften (z.B. BNetzA in Deutschland, FCC in den USA).
>
> Der Steuernde (Control Operator) ist für alle gesendeten Signale verantwortlich. Lassen Sie einen automatisierten Sender niemals unbeaufsichtigt laufen, sofern dies nicht durch Ihre Lizenzklasse und lokale Vorschriften erlaubt ist.
>
> Software wird „AS IS" bereitgestellt, ohne jegliche Garantie.
