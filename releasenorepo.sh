#!/bin/bash
set -euo pipefail

# ============================================================
# AutoFilter Local Release Script (No GitHub Upload)
# Baut Release-Version, erstellt .app + .dmg lokal,
# führt KEINEN Push und KEINEN GitHub-Upload durch.
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="AutoFilter"

# ── Farben ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}▶ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
err()     { echo -e "${RED}✗ $*${NC}"; exit 1; }

# ── 1. App beenden ────────────────────────────────────────────
info "Beende $APP_NAME falls es läuft..."
killall "$APP_NAME" 2>/dev/null && sleep 1 || true

# ── 2. Version & Build-Nummer ─────────────────────────────────
info "Lese Version & Build-Nummer..."
VERSION_FILE="$PROJECT_DIR/.version"
BUILD_FILE="$PROJECT_DIR/.build_number"
[ -f "$VERSION_FILE" ] || err ".version Datei nicht gefunden!"
VERSION=$(cat "$VERSION_FILE" | tr -d ' \n\r')
[ -f "$BUILD_FILE" ] || echo "0" > "$BUILD_FILE"
BUILD=$(( $(cat "$BUILD_FILE") + 1 ))
echo "$BUILD" > "$BUILD_FILE"
success "Version: $VERSION  |  Build: $BUILD"

# BuildNumber.swift aktualisieren
cat > "$PROJECT_DIR/Sources/AutoFilter/BuildNumber.swift" <<EOF
public let APP_VERSION = "$VERSION"
public let APP_BUILD_NUMBER = $BUILD
EOF

# README.md Build-Nummer für aktuelle Version synchronisieren
if [ -f "$PROJECT_DIR/README.md" ]; then
    sed -i '' -E "s/### Version $VERSION \(Build [0-9]+\)/### Version $VERSION (Build $BUILD)/g" "$PROJECT_DIR/README.md" 2>/dev/null || true
fi

# ── 3. Release kompilieren ───────────────────────────────────
info "Kompiliere Release-Version (Universal Binary: Apple Silicon + Intel)..."
swift build -c release --arch arm64 --arch x86_64 2>&1 || err "Kompilierung fehlgeschlagen!"
success "Universal-Build abgeschlossen"

find_release_bin() {
    local BIN_NAME="$1"
    if [ -f "$PROJECT_DIR/.build/apple/Products/Release/$BIN_NAME" ]; then
        echo "$PROJECT_DIR/.build/apple/Products/Release/$BIN_NAME"
    elif [ -f "$PROJECT_DIR/.build/release/$BIN_NAME" ]; then
        echo "$PROJECT_DIR/.build/release/$BIN_NAME"
    else
        err "Binary $BIN_NAME nicht gefunden!"
    fi
}

# ── 4. .app Bundle ───────────────────────────────────────────
info "Erstelle .app Bundle..."
BUNDLE="$PROJECT_DIR/$APP_NAME.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
AUTOFILTER_BIN=$(find_release_bin "$APP_NAME")
cp "$AUTOFILTER_BIN" "$BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME"
[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] && \
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/"

cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>com.gecando.autofilter</string>
    <key>CFBundleName</key>                    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>                 <string>$BUILD</string>
    <key>CFBundleShortVersionString</key>      <string>$VERSION</string>
    <key>CFBundlePackageType</key>             <string>APPL</string>
    <key>NSHighResolutionCapable</key>         <true/>
    <key>LSMinimumSystemVersion</key>          <string>14.0</string>
    <key>NSAppleEventsUsageDescription</key>   <string>AutoFilter benötigt Zugriff auf RUMlogNG, um Logbuch-Einträge abzugleichen.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict></plist>
PLIST

info "Signiere AutoFilter.app Bundle ad-hoc..."
codesign --force --deep --sign - "$BUNDLE"
success "AutoFilter.app Bundle erstellt & ad-hoc signiert"

info "Erstelle AutoFilter Installer.app Bundle..."
INSTALLER_NAME="AutoFilter Installer"
INSTALLER_BUNDLE="$PROJECT_DIR/$INSTALLER_NAME.app"
rm -rf "$INSTALLER_BUNDLE"
mkdir -p "$INSTALLER_BUNDLE/Contents/MacOS" "$INSTALLER_BUNDLE/Contents/Resources"
INSTALLER_BIN=$(find_release_bin "AutoFilterInstaller")
cp "$INSTALLER_BIN" "$INSTALLER_BUNDLE/Contents/MacOS/$INSTALLER_NAME"
chmod +x "$INSTALLER_BUNDLE/Contents/MacOS/$INSTALLER_NAME"
[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] && \
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$INSTALLER_BUNDLE/Contents/Resources/"

cat > "$INSTALLER_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$INSTALLER_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>com.gecando.autofilter.installer</string>
    <key>CFBundleName</key>                    <string>$INSTALLER_NAME</string>
    <key>CFBundleVersion</key>                 <string>$BUILD</string>
    <key>CFBundleShortVersionString</key>      <string>$VERSION</string>
    <key>CFBundlePackageType</key>             <string>APPL</string>
    <key>NSHighResolutionCapable</key>         <true/>
    <key>LSMinimumSystemVersion</key>          <string>14.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict></plist>
PLIST

info "Signiere AutoFilter Installer.app Bundle ad-hoc..."
codesign --force --deep --sign - "$INSTALLER_BUNDLE"
success "AutoFilter Installer.app Bundle erstellt & ad-hoc signiert"

# ── 5. .dmg erstellen ────────────────────────────────────────
info "Erstelle .dmg..."
DMG_NAME="${APP_NAME}-v${VERSION}-b${BUILD}.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"
DMG_LATEST="$PROJECT_DIR/$APP_NAME.dmg"
rm -f "$DMG_PATH" "$DMG_LATEST"

STAGING=$(mktemp -d)
cp -R "$BUNDLE" "$STAGING/"
cp -R "$INSTALLER_BUNDLE" "$STAGING/"
if [ -f "$PROJECT_DIR/Install AutoFilter.command" ]; then
    cp "$PROJECT_DIR/Install AutoFilter.command" "$STAGING/"
    chmod +x "$STAGING/Install AutoFilter.command"
fi
ln -s /Applications "$STAGING/Applications"

# README für DMG erstellen (Deutsch & Englisch)
cat > "$STAGING/README.txt" << 'README_EOF'
================================================================================
  AutoFilter – macOS Anleitungs-Hinweis / Installation & Launch Guide
================================================================================

--------------------------------------------------------------------------------
DEUTSCH / GERMAN: Systemvoraussetzungen
--------------------------------------------------------------------------------
- Betriebssystem: macOS 14.0 (Sonoma) oder neuer (z. B. macOS 15 Sequoia)
- Prozessor: Universal Binary (Apple Silicon M1/M2/M3/M4 & Intel Mac x86_64)

--------------------------------------------------------------------------------
ENGLISH: System Requirements
--------------------------------------------------------------------------------
- Operating System: macOS 14.0 (Sonoma) or later (e.g. macOS 15 Sequoia)
- Architecture: Universal Binary (Apple Silicon M1/M2/M3/M4 & Intel Mac x86_64)


--------------------------------------------------------------------------------
DEUTSCH / GERMAN: Wie installiere & starte ich AutoFilter unter macOS?
--------------------------------------------------------------------------------

Da AutoFilter ad-hoc signiert ist (ohne kostenpflichtiges Apple-Entwickler-
Zertifikat), stuft macOS Gatekeeper die App beim ersten Ausführen evtl. als
"unbekannter Entwickler" oder "beschädigt" ein.

1. OPTION 1 (Nativer 1-Klick GUI Installer – Empfohlen):
   - Starte die App `AutoFilter Installer.app` direkt in dieser DMG.
   - Falls Gatekeeper warnt: Rechtsklick (oder Ctrl+Klick) auf `AutoFilter Installer.app` -> "Öffnen".
   - Der grafische Installer fragt deinen Wunsch-Zielordner (/Applications, ~/Applications
     oder Ordnerauswahl im Finder) ab, kopiert die App, entfernt das macOS
     Quarantäne-Attribut (xattr -cr) automatisch und startet AutoFilter auf Wunsch direkt.

2. OPTION 2 (Interaktives Terminal-Installationsskript):
   - Starte per Doppelklick das Skript `Install AutoFilter.command`.
   - Folge den Eingabeaufforderungen im Terminal.

3. OPTION 3 (Manuell: Drag-and-Drop + Terminal):
   - Ziehe `AutoFilter.app` in den Ordner `Applications` (Programme).
   - Öffne das Terminal (Programme > Dienstprogramme > Terminal) und führe aus:

       xattr -cr /Applications/AutoFilter.app
       codesign --force --deep --sign - /Applications/AutoFilter.app

4. OPTION 4 (Rechtsklick im Finder):
   - Rechtsklick (oder Ctrl+Klick) auf `AutoFilter.app` im Programme-Ordner -> "Öffnen".
   - Falls blockiert: Systemeinstellungen > Datenschutz & Sicherheit -> "Dennoch öffnen".


--------------------------------------------------------------------------------
ENGLISH: How to install & run AutoFilter on macOS?
--------------------------------------------------------------------------------

Since AutoFilter is distributed with ad-hoc code signing (without a paid Apple
Developer ID certificate), macOS Gatekeeper might block the app on first launch.

1. OPTION 1 (1-Click GUI Installer – Recommended):
   - Double-click `AutoFilter Installer.app` inside this DMG.
   - If Gatekeeper prompts a warning: Right-click (or Ctrl+Click) `AutoFilter Installer.app` -> "Open".
   - The graphical installer prompts for your target directory (/Applications, ~/Applications,
     or custom folder via Finder dialog), copies the app, strips Gatekeeper
     quarantine locks (xattr -cr), refreshes code signing, and launches AutoFilter cleanly!

2. OPTION 2 (Interactive Terminal Installer Script):
   - Double-click `Install AutoFilter.command` inside this DMG and follow the prompt.

3. OPTION 3 (Manual: Drag-and-Drop + Terminal):
   - Drag `AutoFilter.app` into the `Applications` folder shortcut.
   - Open Terminal (Applications > Utilities > Terminal) and run:

       xattr -cr /Applications/AutoFilter.app
       codesign --force --deep --sign - /Applications/AutoFilter.app

4. OPTION 4 (Finder Right-Click):
   - Right-click (or Ctrl+Click) `AutoFilter.app` in `/Applications` and select "Open".
   - If blocked: Open System Settings > Privacy & Security -> "Open Anyway".

================================================================================
README_EOF

hdiutil create -volname "$APP_NAME v$VERSION" -srcfolder "$STAGING" \
    -ov -format UDZO "$DMG_PATH" > /dev/null
rm -rf "$STAGING"
cp "$DMG_PATH" "$DMG_LATEST"
success "DMG: $DMG_NAME (inkl. README.txt)"

# ── 6. Lokaler Git Commit & Tag (KEIN Remote Push, KEIN GitHub Upload) ────────
info "Lokaler Git Commit & Tag (kein Push)..."
TAG="v${VERSION}-b${BUILD}"
TITLE="AutoFilter v${VERSION} (Build ${BUILD})"

git add \
    "$PROJECT_DIR/.version" \
    "$PROJECT_DIR/.build_number" \
    "$PROJECT_DIR/Sources/AutoFilter/BuildNumber.swift" \
    "$PROJECT_DIR/README.md" \
    "$PROJECT_DIR/Sources/" \
    "$PROJECT_DIR/HELP.md" 2>/dev/null || true

git commit -m "Release v$VERSION Build $BUILD (local)" 2>/dev/null || warn "Nichts zu committen"
git tag -a "$TAG" -m "$TITLE (local release)" 2>/dev/null || warn "Tag existiert bereits"


# ── 7. Website-Release & API-Update ──────────────────────────
WEBSITE_DIR="$PROJECT_DIR/../Website"
PUBLISH_SCRIPT="$WEBSITE_DIR/publish_release.sh"

if [ -f "$PUBLISH_SCRIPT" ]; then
    info "Veröffentliche Release auf GECANDO Website..."
    "$PUBLISH_SCRIPT" \
        --app "AutoFilter" \
        --version "$VERSION" \
        --build "$BUILD" \
        --file "$DMG_PATH" \
        --min-os "macOS 14+" || warn "Website-Veröffentlichung übersprungen / mit Warnung beendet."
fi

# ── Zusammenfassung ───────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  Lokaler Release v$VERSION (Build $BUILD) fertig erstellt! ║${NC}"
echo -e "${GREEN}║      (Kein Upload zu GitHub / Kein Remote Push erfolgt)      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📦 DMG:         $DMG_PATH"
echo -e "  📦 Latest DMG:  $DMG_LATEST"
echo -e "  🔖 Lokaler Tag: $TAG"
echo ""