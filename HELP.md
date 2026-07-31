# AutoQSO Help & Documentation

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 1. Introduction

AutoQSO is an automated FT8/FT4 helper designed for macOS. It interfaces with WSJT-X via UDP, tracks your worked stations across all bands using LoTW and QRZ.com data, highlights rare Most Wanted stations, and automates calling target stations based on distance and priority.

---

## 2. Most Wanted & Distance Prioritization

- **Top 100 Most Wanted DXCC List**: Integrated live Club Log Most Wanted DXCC entity dataset (e.g. #1 North Korea, #2 Johnston Island, #3 Kure Island, #24 Bouvet Island).
- **Red Highlighting (🔥)**: Decodes from Top 100 Most Wanted entities are highlighted in **bright red** with a rank badge (e.g., `🔥 #1`, `🔥 #24`).
- **Maidenhead Grid Distance Calculation**: Converts 4-character and 6-character Maidenhead locators (e.g., `JO31`, `FH12`) to calculate precise geodesic distance in kilometers (`km`).
- **Prioritization Order**: AutoQSO selects targets in strict priority:
  1. **Priority 1**: Top Most Wanted DXCC entities (Top 10..100).
  2. **Priority 2**: Furthest distance first (`km`).
  3. **Priority 3**: Strongest signal-to-noise ratio (`SNR dB`).

---

## 3. Trigger Logic

AutoQSO continuously analyzes incoming WSJT-X decodes:

- **CQ Messages**: `CQ DL1ABC JO31`, `CQ DX K1ABC`, `CQ POTA W1AW`
- **73 / RR73 / RRR Messages**: `DL1ABC G4XYZ 73`, `K1ABC N2DEF RR73`, `HB9AAA W1AW RRR`

When a valid message is received:
1. AutoQSO extracts the target callsign.
2. Checks if the callsign has already been worked on that band in your local log.
3. Checks if the callsign is currently in a retry cooldown (10-15 min).
4. Sorts all available candidates (Most Wanted > Distance > SNR).
5. AutoQSO issues a WSJT-X Reply packet (Type 12) to call the highest priority station.

---

## 4. Logbook Sync & Management

- **Dynamic Incremental Sync**: LoTW and QRZ downloads start 2 days prior to the latest QSO in your database (UTC calendar), preventing redundant data transfers while capturing spillovers.
- **Duplicate Protection**: Unique key constraints (`CALL_BAND_MODE_YYYYMMDD_TIME`) in SQLite ensure no duplicates are loaded.
- **Sync Date Reset**: Options to reset the sync query date to `1900-01-01` to re-fetch full history without deleting local data.
- **Logbook Re-initialization**: Option to wipe local SQLite database entries and perform a full re-sync from scratch.
- **Row-by-Row Deletion**: Individual entry deletion via 🗑️ buttons, multi-row selection, context menus, and keyboard shortcuts (`Delete`/`Backspace`).

---

## 5. Storage Location & iCloud Sync

- **Default Location**: `~/Documents/AutoQSO/autoqso_log.sqlite`
- **Custom Folder**: Select any local directory via macOS native `NSOpenPanel`.
- **iCloud Drive**: Seamlessly store and sync database files across multiple Macs using `iCloud Drive/AutoQSO`.
- **Automatic Migration**: Changing storage location automatically moves your existing SQLite database file to the new destination.

---

## 6. Legal & Safety Disclaimer

> **IMPORTANT LEGAL NOTICE**
> 
> Operating an amateur radio transmitter under automatic control is subject to national laws and regulations (e.g. BNetzA in Germany, FCC in the United States). 
> 
> The control operator remains responsible for all transmitted signals. Never leave an automated transmitter running unsupervised unless authorized by your license class and local regulations.
> 
> Software provided "AS IS", without warranty of any kind. 
> 
> **Copyright (c) Georg Isenbürger - DJ6GI**

---

## 7. Version & Build History

- **Version 1.0.0**:
  - Most Wanted & Distance Prioritization: Red highlighting (🔥) of Top 100 DXCC entities, Maidenhead grid distance calculation (km), and prioritized candidate selection (Most Wanted > Distance > SNR).
  - Auto QSO trigger support for `CQ`, `73`, `RR73`, and `RRR`.
  - Dynamic 2-day-prior incremental sync (UTC calendar) with LoTW and QRZ.com.
  - Reset sync start date to `1900-01-01` & full logbook re-initialization.
  - Row-by-row & bulk logbook deletion.
  - Custom storage folder selection & iCloud Drive sync.
  - Redesigned Settings dialog with non-collapsible left sidebar.
  - Native Help window with non-collapsible left sidebar.
  - Custom 3D Retina App Icon for macOS app bundle & DMG installer.
  - Automated release script generating versioned `.dmg` installers and GitHub releases.
