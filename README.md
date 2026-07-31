# AutoQSO

**Automated FT8/FT4 QSO Manager & WSJT-X Assistant**

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 📖 Overview

**AutoQSO** is a macOS application designed to automate FT8 and FT4 contacts in conjunction with **WSJT-X**. It monitors incoming UDP decode messages from WSJT-X, filters out callsigns already worked on the current band (using local SQLite logbook data synchronized with ARRL LoTW and QRZ.com), and automatically initiates calls to new stations.

---

## ⚡ Key Features

- **Automated QSO Triggers**: Automatically responds to incoming decodes containing **`CQ`**, **`73`**, **`RR73`**, and **`RRR`**.
- **Dupe & Band Filtering**: Checks each station against your logbook before replying. Previously worked stations on that band are dimmed, and unworked stations trigger an auto-reply.
- **LoTW & QRZ.com Synchronization**: Downloads full historical logbook records (from `1900-01-01` onwards, including all records prior to 2014) and caches them in a fast local SQLite database.
- **Blacklist & Cooldown Management**: Automatically blacklists stations for 10-15 minutes if a QSO attempt times out (120 seconds) or is manually halted, preventing repetitive loops.
- **WSJT-X Integration**: Listens for WSJT-X UDP multicast messages (default `224.0.0.1:2237` or unicast `127.0.0.1:2237`) and sends `Reply` (Type 12) packets.

---

## 🚀 Getting Started

### 1. WSJT-X Setup
In **WSJT-X**, navigate to **Settings -> Reporting**:
- Enable **Prompt me to log QSO**.
- Check **Accept UDP requests**.
- Set **UDP Server Address**: `224.0.0.1` (or `127.0.0.1`).
- Set **UDP Server Port**: `2237`.

### 2. AutoQSO Configuration
1. Launch **AutoQSO**.
2. Enter your **LoTW Username & Password** and click **LoTW Sync** to populate your local logbook.
3. Enter your **QRZ.com API Key** and click **QRZ Sync** for QRZ logbook synchronization.
4. Toggle **AUTO MODE** to enable automated calling.

---

## ⚠️ Disclaimer & Safety Warning

> [!CAUTION]
> **OPERATOR RESPONSIBILITY & REGULATORY COMPLIANCE**
> 
> 1. **Station Control**: Operating an amateur radio station automatically must comply with all national telecommunications laws and amateur radio regulations in your country (e.g., BNetzA, FCC, Ofcom). The licensed operator is solely responsible for all transmissions originating from their station.
> 2. **Duty of Supervision**: Always maintain control over your station while AutoQSO is active. Never leave an automated station unattended unless operating strictly under authorized automatic control guidelines.
> 3. **No Warranty**: This software is provided **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
> 4. **Limitation of Liability**: In no event shall the author (**Georg Isenbürger - DJ6GI**) be liable for any claim, damages, regulatory fines, or other liability arising from, out of, or in connection with the software or the use or other dealings in the software.

---

## 📝 Changelog

### Version 1.0.0 (Build 61)
- **Expanded Auto QSO Triggers**: AutoQSO now triggers on `73`, `RR73`, and `RRR` messages as well as `CQ` decodes.
- **LoTW Historical Download Fix**: Fixed ARRL LoTW report parameters (`qso_qsos=1`) and start date queries (`qso_startdate=1900-01-01`) to ensure all QSOs prior to 2014 are fetched.
- **QRZ.com Historical Sync Fix**: Fixed QRZ API fetch options (`MODSINCE:1900-01-01`) to retrieve full log history back to 1900.
- **URL Encoding Enhancements**: Improved sanitization for credentials and API keys containing special characters.
- **Release Automation & Packaging**: Added automated `release` and `run.sh` scripts supporting semantic versioning (`.version`), `.dmg` bundle generation, and GitHub release uploads.
- **SQLite Logbook Engine**: Built-in SQLite local storage for fast dupe checking across all bands.

---

## 📜 Copyright

**Copyright (c) Georg Isenbürger - DJ6GI**  
All Rights Reserved.
