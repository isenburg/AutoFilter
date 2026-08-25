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
2. Go to **Settings -> Logbook Sync** (or **Einstellungen -> Logbuch-Sync**) to choose your active logbook source (**RUMlogNG**, **LoTW**, or **QRZ.com**).
3. Go to **Settings -> Telnet Server** (or **Einstellungen -> Telnet Server**) to set your login callsign.
4. Go to **Settings -> Home QTH** (or **Einstellungen -> Eigenes QTH**) to set your Maidenhead locator (or click 🗺️ for interactive map picker).
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

### Version 4.3.1
- **Continuous Rolling Decode Buffer (FIFO 250)**: The decode table is no longer wiped every 15s / 7.5s cycle on WSJT-X `Clear` packets. Incoming stations continuously roll into the table at the top, and older entries beyond 250 records smoothly drop off the bottom.
- **Manual Clear Available**: Manual clearing remains available via the toolbar trash button (🗑️) or table reset action.

### Version 4.3.0
- **Auto-Answer Inbound Callers**: Detects direct incoming calls to your own callsign (`<MYCALL> <THEIRCALL> <GRID/RPRT>`) and automatically triggers a reply if the station passes all active DX and worked-before filters.
- **Automatic Cooldown Bypass for Active Callers**: If a station in cooldown quarantine returns and actively calls your station, the quarantine is immediately cleared and the caller is answered with top priority.
- **Configurable Auto QSO Option**: Dedicated toggle in *Settings → Auto QSO Options* with full bilingual localization (German & English).

### Version 4.2.0 (Build 498)
- **Searchable Settings & Help**: Real-time instant search across Settings and Help windows with deep bilingual keyword indexing (German & English), dynamic sidebar filtering, and dynamic section auto-selection.
- **Foreground Called Station Annotation Layering**: Called station marker (`⚡ Call (Grid)`) and active QSO great-circle paths are guaranteed to always render in the foreground (`zPosition = 1000`, `zPriority = .max`) over background country activity badges and grid markers on both 2D propagation maps and 3D globe.
- **Optimized Map Layering & Rendering**: Removed Metal drawingGroup layer promotion overrides for smooth panning/zooming and reliable CoreAnimation layer hierarchy.

### Version 4.1.1 (Build 494)
- **Configuration & Settings in SQLite Database**: All application settings, filter rules, UDP/Telnet/Cluster configurations, color themes, and UI options are now persistently stored in the SQLite database (`autoqso_log.sqlite`) alongside QSO logs with real-time bidirectional synchronization.
- **Seamless iCloud & Multi-Device Synchronization**: Switching storage locations or syncing across multiple Macs via iCloud Drive automatically hydrates and synchronizes all configurations directly from the database.
- **Restored Inner Window Dividers on Compact Mode Exit**: Returning from Compact Mode cleanly preserves and restores the saved split divider heights (`logConsoleHeight`, `mostWantedPanelHeight`) and sidebar widths.
- **Elevated Installer Permissions**: Both `AutoQSO Installer.app` and `Install AutoQSO.command` automatically request administrator privileges when installing to or overwriting existing versions in protected directories (e.g. `/Applications/AFU`).

### Version 4.1.0 (Build 477)
- **VIP: Allowed Maidenhead Grids Filter**: New dedicated filter section supporting single grids (`DN71`), bounding-box ranges (`DN61-DN74`, `KN64-KN71`), and comma-separated lists (`DN61-DN74, EN10`) with instant First-Match VIP exception pass.
- **Sortable Filter Pipeline & First-Match Boolean Evaluation**: All 12 filter sections in the right sidebar are fully reorderable via smooth drag & drop (`☰`). Evaluation follows a sequential **First-Match rule from top to bottom**:
  - **VIP Whitelists (Instant Pass & Passthrough)**: Matching signals in *VIP: Allowed Maidenhead Grids*, *VIP: Allowed DX Callsigns*, or *VIP: Allowed DX Countries* receive an instant VIP pass (`PASS / return true`), bypassing subsequent blacklists. Non-matches cleanly fall through to lower filter sections.
  - **Blacklists (Instant Drop)**: Any match in blocked countries, disabled continents, blocked zones, worked before, or duplicate filters immediately drops the station (`DROP / return false`).
- **VIP-First Standard Default Order & Presets (Default vs. Custom)**: Default pipeline order places VIP exceptions on positions 1–3 directly above general country blocks for instant exception overrides. Presets toggle seamlessly between Default and Custom.
- **Debounced Cycle Evaluation & Diagnostic Throttling**: Auto-QSO candidate search is debounced by 350 ms to process whole decode bursts at cycle end once, with throttled summary diagnostics.
- **Removed Obsolete Conflict Warnings**: Cleaned up legacy conflict checks in favor of deterministic multi-tier First-Match VIP exception evaluation.
- **Strict CTY.DAT DXCC Entity Adherence**: Country filtering strictly distinguishes autonomous DXCC entities (e.g. Puerto Rico `KP4`, Alaska `KL7`, Hawaii `KH6`, Guam `KH2`, Virgin Islands `KP2`) from mainland United States (`K`), preventing accidental collateral blocks.
- **Automatic QSO Abort without Cooldown (HaltTx)**: If an active target station answers a third party, AutoQSO immediately sends a `HaltTx` command to WSJT-X, cancels transmission without cooldown quarantine, and prepares for the next trigger.

### Version 4.0.1 (Build 459)
- **Visual Help Illustrations & Window Expansion**: Enriched the Help & Info dialog with dedicated UI illustrations for toolbar controls, button states, color-coded decode row legends, and live QSO banners in an enlarged 860 × 620 px layout.
- **Dynamic "Auto ON / CQ Only" Button Label**: When "Only Call CQ" is active, the green toolbar auto-transmit button cleanly displays "Auto ON / CQ Only" on two compact lines without enlarging the button.
- **Dedicated "Most wanted Only" Filter Section**: Added a standalone filter section in the right sidebar below Allowed DX Calls with toggle switch and rank threshold picker (Top 10 to 100).
- **Expanded Auto QSO Triggers Help**: In-depth documentation detailing supported message triggers (CQ & tail-ending 73/RR73), all operational settings, and candidate scoring workflows.
- **Configurable UDP Bridge Destination IP & Port**: Full support for custom destination IP addresses (Unicast & Multicast) and port forwarding with dynamic UC/MC mode indicator.
- **"Only Call CQ" Option**: Configurable toggle in *Settings → Auto Mode Options* to strictly call stations transmitting active CQ calls, skipping tail-end transmissions (73 / RR73 / RRR).
- **Structural FT8/FT4 Grid Parser**: Smart phase-aware parsing distinguishes Maidenhead grid locators from QSO termination tokens (`RR73`, `RRR`, `73`, etc.) to prevent false grid extractions.
- **Great Circle Path Fallback to Country**: When no Maidenhead grid locator is received for an active QSO, the Great Circle path is automatically calculated, drawn, and centered to the corresponding country center on both 2D map and 3D globe.
- **Robust Callsign & Prefix Resolution**: Enhanced prefix resolution and country coordinate lookup for complex callsigns with prefixes and portable suffixes (`/P`, `/M`, `/MM`, `EA8/DL1ABC`).

### Version 4.0.0 (Build 437)
- **Multi-Language Architecture (German 🇩🇪 & English 🇬🇧)**: Complete native localization across all views, tables, sidebars, filters, dialogs, map elements, and system alerts.
- **Dynamic In-App Language Selector**: Instant switching between *System (Default)*, *Deutsch*, and *English* in *Settings → Language* without requiring an app restart.
- **Synchronized Units & Geographic Names**: Fully localized time units (Hours/Days/Months/Years / Stunden/Tage/Monate/Jahre) and continent names.
- **Universal 2 Binary**: Full native execution on both Apple Silicon (M1/M2/M3/M4) and Intel Macs (`x86_64`) on macOS 14+.

### Version 3.6.0 (Build 428)
- **Universal 2 Binary Support**: Compiles natively as a dual-architecture Universal Binary for both **Apple Silicon** (`arm64`) and **Intel Macs** (`x86_64`) running macOS 14+.
- **Logically Restructured Filter Sidebar**: Intuitive reordering from macro geography (continents, blocked/allowed countries, zones, callsign prefixes) to QSO history and technical signal filters.
- **WSJT-X CQ Filter Renaming**: Renamed the former "WSJT-X Spezialfilter" to "WSJT-X CQ Filter" (CQ, RR73, RRR, 73 only) for greater clarity.
- **Automated Universal Release DMG**: Release pipeline automatically builds, verifies, and packages universal binaries into the distributable DMG.

### Version 3.5.0 (Build 421)
- **Configurable "Worked Before" Time-Threshold Filter**: New toggle in the filter sidebar enabling previously worked stations to pass through and become eligible for automated calling after a user-defined duration (0–999 hours, days, months, or years).
- **High-Performance O(1) Timestamp Caching**: In-memory UTC timestamp indexing of all QSOs for sub-millisecond evaluation across tens of thousands of logbook records.
- **Flexible Numeric Input & Unit Selector**: Dedicated numeric text field with bounds checking (0–999) paired with hours/days/months/years time unit picker.
- **Unified Filter & Auto-Transmit Integration**: Fully integrated into DX filtering rules, automated transmit candidate selection, and the Most-Wanted dashboard panel.

### Version 3.4.1 (Build 411)
- **Smart 5-Minute Time-Window Deduplication**: Prevents duplicate QSO entries across WSJT-X, RUMlogNG, QRZ.com, and LoTW caused by slight timestamp differences (`TIME_ON` vs. `TIME_OFF`).
- **Automatic Logbook Cleanup**: Automatically detects, merges missing attributes (Grid, DXCC), and removes existing duplicate records from SQLite upon startup.
- **WSJT-X Duplicate Packet Debouncing**: Intelligent filter prevents redundant double-logging when WSJT-X sends simultaneous `loggedAdif` and `qsoLogged` UDP packets.
- **Direct Map Coordinate Popover Anchoring**: Grid inspector popover now anchors directly to the exact geographic center coordinate of the clicked grid square with a targeted pointer.
- **Persistent Grid Map Display**: Ensures 2D map, Maidenhead overlay, and inspector remain fully visible and interactive even when 0 active DX grids are present.
- **Human-Readable Country Resolution**: Resolved matching logbook callsigns to full country names instead of displaying raw numeric DXCC entity IDs.
- **Streamlined Toolbar**: Removed the inline cooldown textfield from the main toolbar in favor of centralized configuration in Settings -> WSJT-X.

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
