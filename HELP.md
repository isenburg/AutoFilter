# AutoQSO Help & Documentation

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 1. Introduction

AutoQSO is an automated FT8/FT4 helper designed for macOS. It interfaces with WSJT-X via UDP, tracks your worked stations across all bands using LoTW and QRZ.com data, and automates calling new stations.

---

## 2. Trigger Logic

AutoQSO continuously analyzes incoming WSJT-X decodes:

- **CQ Messages**: `CQ DL1ABC JO31`, `CQ DX K1ABC`, `CQ POTA W1AW`
- **73 / RR73 / RRR Messages**: `DL1ABC G4XYZ 73`, `K1ABC N2DEF RR73`, `HB9AAA W1AW RRR`

When a valid message is received:
1. AutoQSO extracts the target callsign.
2. Checks if the callsign has already been worked on that band in your local log.
3. Checks if the callsign is currently in a retry cooldown (10-15 min).
4. If unworked and not on cooldown, AutoQSO issues a WSJT-X Reply packet (Type 12) to begin calling the station immediately.

---

## 3. Logbook Sync & Management

- **Dynamic Incremental Sync**: LoTW and QRZ downloads start 1 day before the latest QSO in your database, preventing redundant data transfers.
- **Duplicate Protection**: Unique key constraints (`CALL_BAND_MODE_YYYYMMDD_TIME`) in SQLite ensure no duplicates are loaded.
- **Sync Date Reset**: Options to reset the sync query date to `1900-01-01` to re-fetch full history without deleting local data.
- **Logbook Re-initialization**: Option to wipe local SQLite database entries and perform a full re-sync from scratch.
- **Row-by-Row Deletion**: Individual entry deletion via 🗑️ buttons, multi-row selection, context menus, and keyboard shortcuts (`Delete`/`Backspace`).

---

## 4. Storage Location & iCloud Sync

- **Default Location**: `~/Documents/AutoQSO/autoqso_log.sqlite`
- **Custom Folder**: Select any local directory via macOS native `NSOpenPanel`.
- **iCloud Drive**: Seamlessly store and sync database files across multiple Macs using `iCloud Drive/AutoQSO`.
- **Automatic Migration**: Changing storage location automatically moves your existing SQLite database file to the new destination.

---

## 5. Legal & Safety Disclaimer

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

## 6. Version & Build History

- **Version 1.0.0**:
  - Auto QSO trigger support for `CQ`, `73`, `RR73`, and `RRR`.
  - Dynamic 1-day-prior incremental sync with LoTW and QRZ.com.
  - Reset sync start date to `1900-01-01` & full logbook re-initialization.
  - Row-by-row & bulk logbook deletion.
  - Custom storage folder selection & iCloud Drive sync.
  - Redesigned Settings dialog with non-collapsible left sidebar.
  - Native Help window with non-collapsible left sidebar.
  - Custom 3D Retina App Icon for macOS app bundle & DMG installer.
  - Automated release script generating versioned `.dmg` installers and GitHub releases.
