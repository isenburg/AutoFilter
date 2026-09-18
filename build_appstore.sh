#!/bin/bash
set -euo pipefail

# ============================================================
# AutoFilter Mac App Store Packaging Script
# Baut Universal Binary, signiert mit Apple Distribution Zertifikat
# und schnürt ein Mac App Store uploadfähiges .pkg Installationspaket.
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="AutoFilter"
BUNDLE_ID="com.gecando.autofilter"
TEAM_ID="K8ST37DFJ6"
APP_CERT="Apple Distribution: GLOMATEC GmbH ($TEAM_ID)"
INSTALLER_CERT="3rd Party Mac Developer Installer: GLOMATEC GmbH ($TEAM_ID)"
PROFILE_SRC="$PROJECT_DIR/AutoFilter.provisionprofile"

# ── Farben ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()    { echo -e "${CYAN}▶ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
err()     { echo -e "${RED}✗ $*${NC}"; exit 1; }

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🍏 AutoFilter Mac App Store Builder (.pkg)${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════════${NC}"
echo ""

# ── 1. Version & Build ───────────────────────────────────────
[ -f "$PROJECT_DIR/.version" ] || err ".version Datei nicht gefunden!"
VERSION=$(cat "$PROJECT_DIR/.version" | tr -d ' \n\r')

[ -f "$PROJECT_DIR/.build_number" ] || echo "0" > "$PROJECT_DIR/.build_number"
BUILD=$(cat "$PROJECT_DIR/.build_number" | tr -d ' \n\r')

success "Version: $VERSION  |  Build: $BUILD"

# ── 2. Provisioning Profile prüfen ───────────────────────────
[ -f "$PROFILE_SRC" ] || err "Provisioning Profile nicht gefunden: $PROFILE_SRC"
success "Provisioning Profile gefunden: $(basename "$PROFILE_SRC")"

# ── 3. Kompilieren (Universal Binary) ─────────────────────────
info "Kompiliere Universal Binary (Apple Silicon + Intel)..."
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

# ── 4. .app Bundle aufbauen ──────────────────────────────────
info "Erstelle sauberes App Store Bundle: $APP_NAME.app..."
BUNDLE="$PROJECT_DIR/$APP_NAME.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

BIN_PATH=$(find_release_bin "$APP_NAME")
cp "$BIN_PATH" "$BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME"

[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] || err "Resources/AppIcon.icns fehlt!"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/"

# Info.plist generieren
cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>                    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>             <string>$APP_NAME</string>
    <key>CFBundleVersion</key>                 <string>$BUILD</string>
    <key>CFBundleShortVersionString</key>      <string>$VERSION</string>
    <key>CFBundlePackageType</key>             <string>APPL</string>
    <key>NSHighResolutionCapable</key>         <true/>
    <key>LSMinimumSystemVersion</key>          <string>14.0</string>
    <key>LSApplicationCategoryType</key>       <string>public.app-category.utilities</string>
    <key>ITSAppUsesNonExemptEncryption</key>   <false/>
    <key>NSAppleEventsUsageDescription</key>   <string>AutoFilter benötigt Zugriff auf RUMlogNG, um Logbuch-Einträge abzugleichen.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict></plist>
PLIST

# Provisioning Profile einbetten
cp "$PROFILE_SRC" "$BUNDLE/Contents/embedded.provisionprofile"
success "App-Bundle strukturiert & Provisioning Profile eingebettet"

# ── 5. Code-Signierung für Mac App Store ─────────────────────
info "Signiere $APP_NAME.app mit '$APP_CERT' & Sandbox-Entitlements..."
codesign --force \
    --options runtime \
    --entitlements "$PROJECT_DIR/AutoFilter.entitlements" \
    --sign "$APP_CERT" \
    "$BUNDLE"

info "Validiere Signatur..."
codesign --verify --deep --strict --verbose=2 "$BUNDLE" 2>&1
success "Signatur erfolgreich validiert!"

# ── 6. .pkg Paket schnüren (productbuild) ────────────────────
PKG_NAME="AutoFilter-v${VERSION}-b${BUILD}.pkg"
PKG_PATH="$PROJECT_DIR/$PKG_NAME"
PKG_LATEST="$PROJECT_DIR/AutoFilter.pkg"
rm -f "$PKG_PATH" "$PKG_LATEST"

info "Erstelle signiertes Installer-Paket via productbuild..."
productbuild \
    --component "$BUNDLE" /Applications \
    --sign "$INSTALLER_CERT" \
    "$PKG_PATH"

cp "$PKG_PATH" "$PKG_LATEST"
success "Paket erstellt: $PKG_NAME"

# ── 7. Paket-Signatur prüfen ──────────────────────────────────
info "Überprüfe Signatur von $PKG_NAME..."
pkgutil --check-signature "$PKG_PATH"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  Mac App Store Paket erfolgreich erstellt!              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📦 Paket-Datei: ${BOLD}$PKG_PATH${NC}"
echo -e "  📁 Link:        ${BOLD}$PKG_LATEST${NC}"
echo ""
echo -e "  🚀 Nächster Schritt: Ziehe ${BOLD}$PKG_NAME${NC} einfach in die Apple-App ${BOLD}Transporter${NC}"
echo -e "     oder lade es per Terminal via 'xcrun altool' hoch."
echo ""
