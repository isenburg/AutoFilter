# AutoQSO

**DX-Filter and Automated FT8/FT4 QSO Manager & WSJT-X Assistant**

*Copyright (c) Georg Isenbürger - DJ6GI*

---

## 📖 Overview

**AutoQSO** is a high-performance macOS application designed for amateur radio operators. 

- **Primary Function (DX-Filter)**: Analyzes, classifies, and filters incoming DX spots and decodes in real-time according to custom criteria, callsign lists, countries, and bands.
- **WSJT-X Integration (Auto QSO)**: Automated transmit engine for FT8 and FT4 contacts, cross-referencing incoming decodes against a local SQLite logbook synchronized with RUMlogNG, ARRL LoTW, and QRZ.com, prioritizing rare Most-Wanted DXCC stations.

---

## ⚡ Key Features

- **DX-Filter (Core Feature)**: Intelligent real-time spot evaluation, customizable color coding, continent/region filtering, and spot forwarding via built-in Telnet cluster server.
- **Automated FT8/FT4 QSO Engine**: Responds automatically to `CQ`, `73`, `RR73`, and `RRR` decodes with dupe prevention and automatic cooldown management.
- **3D Globe & 2D Propagation Maps**: Native 3D Globe projection rendering Maidenhead grid lines, worked 4-character squares, spot pins, and active QSO great-circle paths.
- **Active QSO Path Visualization & Centering**: Displays an accurate 3D spherical great-circle arc (Slerp) connecting Home QTH (🏠) and the target station (⚡), automatically centered and framed on the map with a 1-click re-centering status banner.
- **Interactive QTH Picker**: Dedicated Maidenhead settings topic (up to 8-character precision) with interactive map picking and Google-style drop pins.
- **RUMlogNG, LoTW & QRZ.com Logbook Sync**: Local SQLite storage supporting 1-click sync from RUMlogNG (via native AppleScript `ReadAdif`), LoTW, and QRZ.com from 1900-01-01 onwards with selectable provider mode and automatic post-QSO syncing.
- **Compact & Detachable Modes**: Toolbar toggle for compact view with full icon access, and detachable log diagnostic consoles.

---

## 📥 Installation & macOS Gatekeeper Fix

Since AutoQSO is distributed with self-signed (ad-hoc) code signing without a paid Apple Developer ID certificate, macOS Gatekeeper may block direct launches. The DMG release includes two installer options:

### Option 1: Native 1-Click GUI Installer (Recommended)
1. Mount the downloaded **`AutoQSO-vX.X.X.dmg`** file.
2. Double-click (or **Right-Click -> Open**) **`AutoQSO Installer.app`** inside the DMG.
3. Select your desired target directory (`/Applications`, `~/Applications`, or custom folder). The installer automatically copies the app, removes quarantine attributes (`xattr -cr`), and refreshes code signatures.

### Option 2: Interactive Terminal Installer Script
1. Inside the DMG, double-click **`Install AutoQSO.command`**.
2. Follow the prompt to select the destination folder.

### Option 3: Manual Installation (Terminal)
If you drag `AutoQSO.app` into `/Applications` manually, run:
```bash
xattr -cr /Applications/AutoQSO.app
codesign --force --deep --sign - /Applications/AutoQSO.app
```

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
2. Go to **Settings -> Logbuch-Sync** to choose your active logbook source (**RUMlogNG**, **LoTW**, or **QRZ.com**).
3. Go to **Settings -> Telnet Server** to set your login callsign.
4. Go to **Settings -> Eigenes QTH** to set your Maidenhead locator (or click 🗺️ for interactive map picker).
5. Toggle **WSJTX Auto Transmit** in the toolbar to enable automated calling.

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

### Version 3.4.0 (Build 410)
- **RUMlogNG AppleScript Integration**: 1-click logbook synchronization from running RUMlogNG app via native AppleScript (`ReadAdif`) with full (since 1900) and incremental sync modes.
- **Selectable Logbook Providers**: Switch between *RUMlogNG*, *ARRL LoTW*, and *QRZ.com* in settings with automatic dynamic post-QSO syncing.
- **Active QSO Great-Circle Centering**: Automatically centers and zooms the map on active QSO great-circle paths with 1-click re-centering from the top status pill.
- **Dual-Installer Release DMG**: Includes both native macOS GUI Installer (`AutoQSO Installer.app`) and terminal script (`Install AutoQSO.command`).
- **Quickstart Deep-Linking**: Direct navigation buttons from Quickstart to specific settings tabs.
- **Auto-Scroll Crash Fix**: Thread-safe asynchronous viewport scrolling for high-throughput decoding.

### Version 3.3.2 (Build 402)
- **Native macOS GUI Installer**: Native GUI installer app bundled inside DMG with custom target directory picker.
- **Interactive Grid Inspector**: Clickable grid cells with detailed popovers showing bearing, distance, worked status, and QRZ lookups.
- **Band Quick-Filter Pills**: Horizontal filter pills (`ALL`, `160M`–`6M`) on the grid map.
- **Bearing & Distance Display**: Shows azimuth and great-circle distance relative to Home QTH in grid lists.
- **Spot Freshness Decay**: Visual indicators for fresh spots (<3 min) and subtle fading for older spots.
- **Interactive 1-Click Installer**: Bundled `Install AutoQSO.command` inside DMG releases with target folder selection (`/Applications`, `~/Applications`, Finder dialog) and automatic Gatekeeper quarantine removal (`xattr -cr`).
- **3D Globe Projection & Maidenhead Grid**: Rendered Maidenhead grid lines and worked 4-character squares natively as 3D polylines and polygons on 3D Globe map.
- **Active QSO Path Visualization**: Added accurate 3D spherical great-circle arc (Slerp) between Home QTH (🏠) and target station (⚡) with top status banner.
- **Interactive QTH Picker**: Modal map picker with 8-character locator resolution and Google-style drop pin.
- **Compact Mode Toolbar**: Integrated complete set of 6 icon buttons into the compact view header with clean bordered styling.
- **Map Style Menu Controls**: Compact, high-contrast dropdown menus (`.ultraThinMaterial` pill) across all 2D and 3D map views.

### Version 3.2.1 (Build 198)
- **Bugfixes & Toolbar Help**: Fixed numeric text fields, window-level scroll hierarchy, and added toolbar clear buttons.

### Version 3.2.0 (Build 190)
- **UI Performance Boost**: Coalesced and debounced decode UI calculations by 300ms, and moved `cty.dat` parser to background queue.

### Version 3.1.0 (Build 174)
- **Propagation Map**: Interactive Live Map detailing country activity and active bands.

### Version 3.0.0 (Build 166)
- **Detachable Console**: Diagnostic logs console now detachable into floating window.
- **DX Cluster Manager**: Upstream cluster management with native drag-and-drop reordering.

### Version 1.0.0 (Build 61)
- **Initial Release**: SQLite logbook engine, LoTW/QRZ historical sync, and FT8/FT4 auto-calling.

---

## 📜 Copyright

**Copyright (c) Georg Isenbürger - DJ6GI**  
All Rights Reserved.
