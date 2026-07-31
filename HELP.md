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

## 3. Logbook Sync (LoTW & QRZ)

- **Logbook of The World (LoTW)**: Query parameters retrieve all confirmed and unconfirmed QSOs back to `1900-01-01`.
- **QRZ.com**: Downloads logbook records using `MODSINCE:1900-01-01` to capture all contacts before 2014.
- All downloads are merged into a local SQLite database for instant dupe checking.

---

## 4. Legal & Safety Disclaimer

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

## 5. Version & Build History

- **Version 1.0.0 (Build 61)**:
  - Added support for `73`, `RR73`, and `RRR` decode triggers.
  - Fixed pre-2014 log fetching for LoTW (`qso_qsos=1`, `qso_startdate=1900-01-01`) and QRZ.com (`MODSINCE:1900-01-01`).
  - Added DMG release packaging and GitHub upload automation.
