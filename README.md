# AutoFilter

**DX-Filter and Automated FT8/FT4 QSO Manager & WSJT-X Assistant**

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 📖 Overview

**AutoFilter** is a high-performance macOS application designed for amateur radio operators. 

- **Primary Function (DX-Filter)**: Analyzes, classifies, and filters incoming DX spots and decodes in real-time according to custom criteria, callsign lists, countries, and bands.
- **WSJT-X Integration (Auto QSO)**: Automated transmit engine for FT8 and FT4 contacts, cross-referencing incoming decodes against a local SQLite logbook synchronized with RUMlogNG, ARRL LoTW, and QRZ.com, prioritizing rare Most-Wanted DXCC stations.

### 🔄 Inline-Filter Architecture
AutoFilter operates as an inline filter positioned between incoming signal streams (up to **3 simultaneous DX Clusters** plus **WSJT-X UDP Decodes**) and your logging software (such as **RUMlogNG**):
- **No Cluster Commands Required**: Eliminates the need to configure server-side filter commands on individual cluster servers.
- **Independent of Cluster Software**: Consistent local filtering regardless of cluster type (DXSpider, AR-Cluster, CC-Cluster, RBN).
- **Telnet Forwarding**: Filtered spots are forwarded via the built-in Telnet server directly to RUMlogNG.

---

## ⚡ Key Features

- **DX-Filter (Core Feature)**: Intelligent real-time spot evaluation, customizable color coding, continent/region filtering, and spot forwarding via built-in Telnet cluster server.
- **Automated FT8/FT4 QSO Engine**: Responds automatically to `CQ`, `73`, `RR73`, and `RRR` decodes or direct inbound callers (with automatic cooldown bypass), customizable DX filters, and dupe prevention.
- **3D Globe & 2D Propagation Maps**: Native 3D Globe projection rendering Maidenhead grid lines, worked 4-character squares, spot pins, and active QSO great-circle paths.
- **Active QSO Path Visualization & Centering**: Displays an accurate 3D spherical great-circle arc (Slerp) connecting Home QTH (🏠) and the target station (⚡), automatically centered and framed on the map with a 1-click re-centering status banner.
- **Interactive QTH Picker**: Dedicated Maidenhead settings topic (up to 8-character precision) with interactive map picking and Google-style drop pins.
- **Searchable Settings & Documentation**: Integrated real-time search across all settings categories and documentation topics with deep bilingual keyword indexing (German & English) and dynamic sidebar filtering.
- **RUMlogNG, LoTW & QRZ.com Logbook Sync**: Local SQLite storage supporting 1-click sync from RUMlogNG (via native AppleScript `ReadAdif`), LoTW, and QRZ.com from 1900-01-01 onwards with selectable provider mode and automatic post-QSO syncing.
- **Compact & Detachable Modes**: Toolbar toggle for compact view with full icon access, and detachable log diagnostic consoles.

---

## 💻 System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or newer (including macOS 15 Sequoia).
- **Processor / Architecture**: Universal Binary (Native support for **Apple Silicon** M1/M2/M3/M4 & **Intel Macs** `x86_64`).

---

## 📥 Installation & macOS Gatekeeper Fix

Since AutoFilter is distributed with self-signed (ad-hoc) code signing without a paid Apple Developer ID certificate, macOS Gatekeeper may block direct launches. The DMG release includes two installer options:

### Option 1: Native 1-Click GUI Installer (Recommended)
1. Mount the downloaded **`AutoFilter-vX.X.X.dmg`** file.
2. Double-click (or **Right-Click -> Open**) **`AutoFilter Installer.app`** inside the DMG.
3. Select your desired target directory (`/Applications`, `~/Applications`, or custom folder). The installer automatically copies the app, removes quarantine attributes (`xattr -cr`), and refreshes code signatures.

### Option 2: Interactive Terminal Installer Script
1. Inside the DMG, double-click **`Install AutoFilter.command`**.
2. Follow the prompt to select the destination folder.

### Option 3: Manual Installation (Terminal)
If you drag `AutoFilter.app` into `/Applications` manually, run:
```bash
xattr -cr /Applications/AutoFilter.app
codesign --force --deep --sign - /Applications/AutoFilter.app
```

---

## 🚀 Getting Started

AutoFilter supports two primary operation modes:

### Mode A: Minimum Setup – Inline DX Cluster Filter (3 Steps)
For operating AutoFilter strictly as an intelligent inline filter between upstream internet clusters and your logging software (e.g., RUMlogNG, MacLoggerDX, Log4OM, N1MM):
1. **Internet Connection**: Active internet connection to receive live DX spots.
2. **Select DX Cluster**: Select and connect to your preferred cluster (C1, C2, or C3) via the sidebar dropdown or **Settings -> DX Cluster**.
3. **Configure Telnet Server (IP & Port)**: Enable the Telnet server under **Settings -> Telnet Server** (default: `127.0.0.1:8000`), and configure your logging software's DX cluster connection to connect to `127.0.0.1` on port `8000`. Filtered spots will flow directly into your logger in real time!

---

### Mode B: Full Setup – Auto QSO & WSJT-X (All-Inclusive in 4 Steps)
For full-featured operation with automated calling (Auto QSO), live decode filtering, and duplicate checking:
1. **Callsign & Home QTH**: Set your login callsign under **Settings -> Telnet Server** and your Maidenhead grid locator under **Settings -> Home QTH**.
2. **WSJT-X UDP Setup**: In WSJT-X under **Settings -> Reporting**, enable `Prompt me to log QSO` [x], `Accept UDP requests` [x], `UDP Server Address: 224.0.0.1` (or `127.0.0.1`), and `Port: 2237`.
3. **Logbook Sync**: Open **Settings -> Logbook Sync** and sync your QSOs via RUMlogNG, LoTW, QRZ.com, or ADIF file import.
4. **DX Cluster & Auto Transmit**: Select your upstream cluster, configure your filter rules in the right sidebar, and toggle **Auto Transmit** in the top toolbar.

---

## ⚠️ Disclaimer & Safety Warning

> [!CAUTION]
> **OPERATOR RESPONSIBILITY & REGULATORY COMPLIANCE**
> 
> 1. **Station Control**: Operating an amateur radio station automatically must comply with all national telecommunications laws and amateur radio regulations in your country (e.g., BNetzA, FCC, Ofcom). The licensed operator is solely responsible for all transmissions originating from their station.
> 2. **Duty of Supervision**: Always maintain control over your station while AutoFilter is active. Never leave an automated station unattended unless operating strictly under authorized automatic control guidelines.
> 3. **No Warranty**: This software is provided **"AS IS"**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
> 4. **Limitation of Liability**: In no event shall the author (**Georg Isenbürger - DJ6GI**) be liable for any claim, damages, regulatory fines, or other liability arising from, out of, or in connection with the software or the use or other dealings in the software.

---

## 📝 Changelog

### Version 5.1.0
- **Smart Inbound Caller Preemption**: Automatically switches to an incoming caller addressed to us if the currently called target has not answered after configurable transmit attempts (1–4 attempts, default: 2).
- **Most Wanted Fast-Track Jump**: Instant preemption (after 1 attempt) when an incoming caller is an unworked Most Wanted DXCC entity.
- **Active QSO Protection**: Locks preemption once the called target answers to ensure ongoing two-way QSOs are never broken.
- **Soft Cooldown Handling**: Places unanswered targets into a brief 2-minute soft cooldown to prevent calling loops while keeping them reachable later.

### Version 5.0.0
- **Mac App Store & StoreKit 2 Integration**: Native StoreKit 2 in-app purchase architecture for lifetime license activation and purchase restoration.
- **60-Minute Session Trial Mode**: Free trial mode offering full feature access for 60 minutes per session; automated pass-through and purchase prompt upon trial expiry with instant reset on app restart.
- **Trial Status Indicator**: Real-time session countdown badge in the main toolbar providing one-click access to the upgrade sheet.

---

## 📜 Copyright

**Copyright (c) Georg Isenbürger - DJ6GI**  
All Rights Reserved.

