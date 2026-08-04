# AutoQSO Help & Documentation

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 1. Introduction

AutoQSO ist eine macOS-Anwendung zur Automatisierung von FT8- und FT4-Kontakten in Verbindung mit WSJT-X. Die App überwacht eingehende Decodes per UDP, prüft gegen ein lokales SQLite-Logbuch (LoTW & QRZ.com), hebt seltene Most-Wanted-Stationen hervor und ruft automatisch nach Priorität.

---

## 2. Most Wanted & Entfernungspriorisierung (Neu in v2.0.0)

- **Top 100 Most Wanted DXCC**: Integrierte Club Log Most Wanted Liste (P5, KH3, KH7K, CE0X, FT/X, 3Y/B, Bouvet, etc.)
- **Rote Hervorhebung (🔥)**: Ungearbeitete Most Wanted Stationen werden in der Decodier-Tabelle knallrot mit Rang-Badge markiert (🔥 #1, 🔥 #24).
- **Gesondertes Most-Wanted-Panel**: Unterhalb der Haupttabelle erscheint ein eigenes Panel, das ausschließlich Most Wanted Stationen zeigt, die auf dem aktuellen Band noch **nicht gearbeitet** wurden.
- **Höhenverstellbares Panel**: Die Höhe des Most-Wanted-Feldes kann mit der Maus durch Ziehen der Überschriften-Leiste stufenlos zwischen 50–500 pt eingestellt werden. Die Größe wird dauerhaft gespeichert.
- **Maidenhead Locator → km**: Umrechnung von 4/6-stelligen Maidenhead-Locatoren in geografische Koordinaten und Berechnung der Großkreis-Entfernung in Kilometern via Haversine-Formel.
- **Entfernung im Stations-Banner**: Neben dem Rufzeichen und dem QRZ.com-Button zeigt der Stations-Banner die berechnete Entfernung (km) und das Grid-Square der aktuellen Station an.

---

## 3. Prioritätsreihenfolge (Auto QSO Engine)

Bei der automatischen Anrufauswahl in `evaluateAutoQSO()` gilt folgende strikte Priorität:

1. **Priorität 1**: Most Wanted Entitäten (Top 1–100) zuerst — Rang #1 = höchste Priorität
2. **Priorität 2**: Weiteste Entfernung (km) zuerst
3. **Priorität 3**: Stärkstes Signal (SNR dB) als Fallback

---

## 4. Auto QSO Trigger Logik

AutoQSO analysiert alle WSJT-X Decodes in Echtzeit:

- **CQ Nachrichten**: `CQ DL1ABC JO31`, `CQ DX K1ABC`, `CQ POTA W1AW`
- **73 / RR73 / RRR Nachrichten**: `DL1ABC G4XYZ 73`, `K1ABC N2DEF RR73`, `HB9AAA W1AW RRR`

Wenn ein gültiges Decode erkannt wird:
1. Callsign extrahieren & DXCC-Entität bestimmen
2. Prüfen ob bereits auf diesem Band gearbeitet (SQLite-Logbuch)
3. Prüfen ob im Retry-Cooldown (10–15 Min.)
4. Kandidaten sortieren (Most Wanted → Entfernung → SNR)
5. WSJT-X Reply-Paket (Type 12) an höchstpriore Station senden

---

## 5. Einstellungen: Most Wanted & Priorität

In den **Einstellungen → 🔥 Most Wanted & Priorität**:

| Einstellung | Beschreibung |
|---|---|
| **Eigener Grid Locator** | Maidenhead-Locator Ihres Standorts (z.B. `JO31` oder `JO31AA`) |
| **Most Wanted rot hervorheben** | Rote Hervorhebung in der Tabelle ein-/ausschalten |
| **Priorität: Most Wanted & Entfernung** | Auto-QSO-Priorisierung nach Seltenheit & Entfernung |
| **Schwelle Most Wanted** | Top 10 / 20 / 50 / 100 einstellen |

---

## 6. Logbuch-Sync & Verwaltung

- **Inkrementeller Sync**: LoTW & QRZ starten 2 Tage vor dem neuesten QSO in der Datenbank (UTC-Kalender).
- **Duplicate Prevention**: Eindeutigkeitsprüfung via `CALL_BAND_MODE_YYYYMMDD_TIME` in SQLite.
- **Reset Sync-Datum**: Auf `1900-01-01` zurücksetzen für vollständige Neu-Synchronisierung.
- **Logbuch-Neuinitialisierung**: Lokale SQLite-Einträge löschen & komplett neu laden.
- **Löschen**: Einzellöschung (🗑️), Mehrfachauswahl, Kontextmenü, Tastatur (`Delete`/`Backspace`).

---

## 7. Speicherort & iCloud Sync

- **Standard**: `~/Documents/AutoQSO/autoqso_log.sqlite`
- **Eigener Ordner**: Auswahl via macOS `NSOpenPanel`
- **iCloud Drive**: `iCloud Drive/AutoQSO` für geräteübergreifende Synchronisierung
- **Automatische Migration**: Beim Wechsel des Speicherorts wird die bestehende Datenbank automatisch verschoben.

---

## 8. Rechtlicher Hinweis

> **WICHTIGER RECHTLICHER HINWEIS**
>
> Das Betreiben eines Amateurfunksenders unter automatischer Steuerung unterliegt nationalen Gesetzen und Vorschriften (z.B. BNetzA in Deutschland, FCC in den USA).
>
> Der Steuernde (Control Operator) ist für alle gesendeten Signale verantwortlich. Lassen Sie einen automatisierten Sender niemals unbeaufsichtigt laufen, sofern dies nicht durch Ihre Lizenzklasse und lokale Vorschriften erlaubt ist.
>
> Software wird „AS IS" bereitgestellt, ohne jegliche Garantie.
>
> **Copyright (c) Georg Isenbürger - DJ6GI**

---

## 9. Changelog

### Version 2.0.4 (AKTUELL)

#### ⚡ Stabilitäts- & Timing-Verbesserungen beim Senden
- **200ms Sendeverzögerung**: AutoQSO wartet nun 200 ms mit dem Senden des Trigger-Kommandos, bis WSJT-X den CPU-intensiven Decodierzyklus abgeschlossen hat. Verhindert Zuverlässigkeitsprobleme und Paketverluste.
- **Smarte Sende-Wiederholung (Retries)**: Ist die Sende-Bereitschaft (TX BEREIT) nach 3 Sekunden nicht aktiv, versucht AutoQSO das Kommando erneut (max. 3-mal). Wird sofort abgebrochen, sobald WSJT-X Sende-Bereitschaft signalisiert.
- **Engine-Logbuch**: Live-Anzeige detaillierter Auswertungsergebnisse in der Log-Konsole (warum CQ-Rufe übersprungen wurden).
- **Eigene Rufzeichen-Sperre**: Filtert das eigene Rufzeichen aus den Kandidaten, um Selbstanrufe zu verhindern.

---

### Version 2.0.3

#### 🎯 Strikter DXCC-Filter & TX-Triggering
- **Strikter DXCC-Filter**: Neue Option „Ausschließlich Most Wanted Stationen anrufen“ in den Einstellungen.
- **Erweitertes TX-Triggering**: Sendet Shift Modifier (`0x01`) beim Antworten, was in WSJT-X „Enable TX = ON“ erzwingt.

---

### Version 2.0.2

#### 🛠️ UDP-Protokoll, TX-Steuerung & GUI-Verfeinerungen
- **Clear-Signal (Typ 3)**: WSJT-X Clear-Nachricht leert die Decodier-Liste exakt zu Beginn jedes neuen 15s-Fensters
- **Empfangene EnableTx/Reply Pakete**: Werden auf dem UDP-Port abgefangen und verworfen (verhindert Loopback-Konflikte)
- **Replay-Decodes**: `isNew=false` löscht die Decodier-Liste nicht mehr fälschlicherweise
- **SQLite Import-Deduplizierung**: Dreistufiger Schutz gegen doppelte QSOs beim LoTW/QRZ Sync
- **Banner-Selektion**: Einfacher Klick auf eine Zeile schaltet den Banner um; automatisches Reset beim nächsten Decode
- **Toolbar-Layout**: Perfekt ausgerichtete Sektionen (AUTO MODE, SYNCHRONISATION, LOGBUCH, FENSTER)
- **Automatisierter Release-Prozess**: Ein-Klick `release.sh` baut Release-Binary, `.app`, `.dmg` & lädt zu GitHub Release hoch

---

### Version 2.0.1

#### 🐛 Bugfixes & Präzise Callsign-Validierung
- Präzise Ambiguität-Auflösung für problematische Most-Wanted-Präfixe
- **KG4**: Nur echte Guantanamo Bay Rufzeichen (≤ 5 Zeichen, z.B. `KG4AS`, `KG4WW`) — `KG4ABC` (US-General) wird **nicht** mehr als Most Wanted erkannt
- **KH1/3/4/5/9**: Nur kurze Suffixe (≤ 5 Zeichen) oder Expeditions-Format mit `/` (z.B. `KH1/K6VVA`)
- **KP1/KP5**: Navassa Island / Desecheo Island — nur kurze oder `/P`-Expeditionsrufzeichen
- **ST**: Sudan — nur wenn das dritte Zeichen eine Ziffer ist (`ST0...`, `ST2...`)
- **3C**: Äquatorialguinea — wird nicht mit `3C0` (Annobon Island, eigener Rang) verwechselt
- **VP6/VP6D**: Pitcairn wird nicht mit `VP6/D` (Ducie Island, eigener Rang) verwechselt
- **FO/M, FO/C, FO/A**: Marquesas/Clipperton/Austral — nur bei explizitem Schrägstrich-Subfix
- Most-Wanted-Panel zeigt keine Doubletten mehr — pro Rufzeichen nur ein Eintrag (bestes SNR)

---

### Version 2.0.0

#### 🔥 Most Wanted & Entfernungsfeatures
- Club Log Top 100 Most Wanted DXCC integriert
- Rote Hervorhebung (🔥 #Rang) für ungearbeitete Most Wanted Stationen in der Tabelle
- Gesondertes Most-Wanted-Panel unterhalb der Tabelle (nur ungearbeitete Stationen auf aktuellem Band)
- Panel-Höhe stufenlos verstellbar (50–500 pt), dauerhaft gespeichert
- Maidenhead Locator → Großkreis-Entfernung (km) via Haversine-Formel
- Entfernungsspalte in der Haupttabelle
- Entfernung & Grid-Square im Stations-Banner (Evaluierungsleiste)
- Most Wanted Rang-Badge im Stations-Banner

#### 🎯 Auto QSO Priorisierung
- Neue Prioritätsreihenfolge: Most Wanted (#1–#100) → Weiteste Entfernung → SNR
- Nur ungearbeitete Stationen auf dem aktuellen Band werden berücksichtigt

#### ⚙️ Einstellungen
- Neue Kategorie „Most Wanted & Priorität" in den Einstellungen
- Grid-Locator Eingabe, Schalter für Hervorhebung/Priorität, Rang-Schwelle

---

### Version 1.0.0

- Auto QSO Trigger für CQ, 73, RR73 und RRR Decodes
- Inkrementeller LoTW & QRZ Sync (2 Tage vor letztem QSO, UTC)
- Duplicate Prevention via SQLite uniqueKey
- Reset Sync-Startdatum auf 1900 & Logbuch-Neuinitialisierung
- Zeilenweises & Mehrfach-Löschen (🗑️, Kontextmenü, Tastatur)
- Freie Speicherort-Wahl & iCloud Drive Sync
- Einstellungen mit linker Sidebar-Navigation
- Hilfe-Fenster mit Seitenleiste
- 3D Retina App Icon für macOS App-Bundle & DMG
- Release-Skript: Versioniertes .dmg, Git-Tagging & GitHub Releases
