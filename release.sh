#!/bin/bash
set -euo pipefail

# ============================================================
# AutoQSO Release Script
# Baut Release-Version, erstellt .app + .dmg,
# speichert lokal und lädt als GitHub Release hoch.
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

APP_NAME="AutoQSO"
GITHUB_REPO="isenburg/AutoQSO"

# ── Farben ────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}▶ $*${NC}"; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠ $*${NC}"; }
err()     { echo -e "${RED}✗ $*${NC}"; exit 1; }

# ── GitHub Upload via REST API ────────────────────────────────
api_create_release() {
    local TOKEN="$1" TAG="$2" TITLE="$3" NOTES="$4"
    local NOTES_JSON
    NOTES_JSON=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<< "$NOTES")

    curl -s -X POST \
        -H "Authorization: token $TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$GITHUB_REPO/releases" \
        -d "{\"tag_name\":\"$TAG\",\"name\":\"$TITLE\",\"body\":$NOTES_JSON,\"draft\":false,\"prerelease\":false}"
}

api_upload_asset() {
    local TOKEN="$1" UPLOAD_URL="$2" DMG_PATH="$3" DMG_NAME="$4"
    curl -s -X POST \
        -H "Authorization: token $TOKEN" \
        -H "Content-Type: application/x-apple-diskimage" \
        "${UPLOAD_URL}?name=${DMG_NAME}" \
        --data-binary @"$DMG_PATH" > /dev/null
}

github_release() {
    local TOKEN="$1" TAG="$2" TITLE="$3" NOTES="$4" DMG_PATH="$5" DMG_NAME="$6"

    info "Erstelle GitHub Release via API..."
    RESP=$(api_create_release "$TOKEN" "$TAG" "$TITLE" "$NOTES")

    UPLOAD_URL=$(echo "$RESP" | python3 -c "
import json,sys
d=json.load(sys.stdin)
url=d.get('upload_url','')
print(url.split('{')[0])
" 2>/dev/null || echo "")

    if [ -z "$UPLOAD_URL" ]; then
        warn "Upload-URL nicht gefunden. Antwort: $RESP"
        return 1
    fi

    info "Lade DMG hoch..."
    api_upload_asset "$TOKEN" "$UPLOAD_URL" "$DMG_PATH" "$DMG_NAME"
    success "GitHub Release '$TAG' erstellt & DMG hochgeladen!"
    echo -e "  🌐 https://github.com/$GITHUB_REPO/releases/tag/$TAG"
}

# ══════════════════════════════════════════════════════════════

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
cat > "$PROJECT_DIR/Sources/AutoQSO/BuildNumber.swift" <<EOF
public let APP_VERSION = "$VERSION"
public let APP_BUILD_NUMBER = $BUILD
EOF

# ── 3. Changelog aus Git-Commits oder Parameter ────────────────
MANUAL_CHANGES="${1:-}"

if [ -n "$MANUAL_CHANGES" ]; then
    info "Verwende manuell übergebene Release-Notes..."
    CHANGELOG="$MANUAL_CHANGES"
else
    info "Erzeuge Changelog aus Git-Commits..."
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [ -n "$LAST_TAG" ]; then
        CHANGELOG=$(git log "${LAST_TAG}..HEAD" --pretty=format:"- %s" --no-merges 2>/dev/null)
    else
        CHANGELOG=$(git log --pretty=format:"- %s" --no-merges -20 2>/dev/null)
    fi
    [ -n "$CHANGELOG" ] || CHANGELOG="- Release v$VERSION (Build $BUILD)"
fi

# ── 4. Release kompilieren ───────────────────────────────────
info "Kompiliere Release-Version..."
swift build -c release 2>&1 || err "Kompilierung fehlgeschlagen!"
success "Build abgeschlossen"

# ── 5. .app Bundle ───────────────────────────────────────────
info "Erstelle .app Bundle..."
BUNDLE="$PROJECT_DIR/$APP_NAME.app"
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$PROJECT_DIR/.build/release/$APP_NAME" "$BUNDLE/Contents/MacOS/"
chmod +x "$BUNDLE/Contents/MacOS/$APP_NAME"
[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] && \
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$BUNDLE/Contents/Resources/"

cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>com.dj6gi.autoqso</string>
    <key>CFBundleName</key>                    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>                 <string>$BUILD</string>
    <key>CFBundleShortVersionString</key>      <string>$VERSION</string>
    <key>CFBundlePackageType</key>             <string>APPL</string>
    <key>NSHighResolutionCapable</key>         <true/>
    <key>LSMinimumSystemVersion</key>          <string>14.0</string>
    <key>NSAppleEventsUsageDescription</key>   <string>AutoQSO benötigt Zugriff auf RUMlogNG, um Logbuch-Einträge abzugleichen.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict></plist>
PLIST

info "Signiere AutoQSO.app Bundle ad-hoc..."
codesign --force --deep --sign - "$BUNDLE"
success "AutoQSO.app Bundle erstellt & ad-hoc signiert"

info "Erstelle AutoQSO Installer.app Bundle..."
INSTALLER_NAME="AutoQSO Installer"
INSTALLER_BUNDLE="$PROJECT_DIR/$INSTALLER_NAME.app"
rm -rf "$INSTALLER_BUNDLE"
mkdir -p "$INSTALLER_BUNDLE/Contents/MacOS" "$INSTALLER_BUNDLE/Contents/Resources"
cp "$PROJECT_DIR/.build/release/AutoQSOInstaller" "$INSTALLER_BUNDLE/Contents/MacOS/$INSTALLER_NAME"
chmod +x "$INSTALLER_BUNDLE/Contents/MacOS/$INSTALLER_NAME"
[ -f "$PROJECT_DIR/Resources/AppIcon.icns" ] && \
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$INSTALLER_BUNDLE/Contents/Resources/"

cat > "$INSTALLER_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key>              <string>$INSTALLER_NAME</string>
    <key>CFBundleIconFile</key>                <string>AppIcon</string>
    <key>CFBundleIdentifier</key>              <string>com.dj6gi.autoqso.installer</string>
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

info "Signiere AutoQSO Installer.app Bundle ad-hoc..."
codesign --force --deep --sign - "$INSTALLER_BUNDLE"
success "AutoQSO Installer.app Bundle erstellt & ad-hoc signiert"

# ── 6. .dmg erstellen ────────────────────────────────────────
info "Erstelle .dmg..."
DMG_NAME="${APP_NAME}-v${VERSION}-b${BUILD}.dmg"
DMG_PATH="$PROJECT_DIR/$DMG_NAME"
DMG_LATEST="$PROJECT_DIR/$APP_NAME.dmg"
rm -f "$DMG_PATH" "$DMG_LATEST"

STAGING=$(mktemp -d)
cp -R "$BUNDLE" "$STAGING/"
cp -R "$INSTALLER_BUNDLE" "$STAGING/"
if [ -f "$PROJECT_DIR/Install AutoQSO.command" ]; then
    cp "$PROJECT_DIR/Install AutoQSO.command" "$STAGING/"
    chmod +x "$STAGING/Install AutoQSO.command"
fi
ln -s /Applications "$STAGING/Applications"

# README für DMG erstellen (Deutsch & Englisch)
cat > "$STAGING/README.txt" << 'README_EOF'
================================================================================
  AutoQSO – macOS Anleitungs-Hinweis / Installation & Launch Guide
================================================================================

--------------------------------------------------------------------------------
DEUTSCH / GERMAN: Wie installiere & starte ich AutoQSO unter macOS?
--------------------------------------------------------------------------------

Da AutoQSO ad-hoc signiert ist (ohne kostenpflichtiges Apple-Entwickler-
Zertifikat), stuft macOS Gatekeeper die App beim ersten Ausführen evtl. als
"unbekannter Entwickler" oder "beschädigt" ein.

1. OPTION 1 (Nativer 1-Klick GUI Installer – Empfohlen):
   - Starte die App `AutoQSO Installer.app` direkt in dieser DMG.
   - Falls Gatekeeper warnt: Rechtsklick (oder Ctrl+Klick) auf `AutoQSO Installer.app` -> "Öffnen".
   - Der grafische Installer fragt deinen Wunsch-Zielordner (/Applications, ~/Applications
     oder Ordnerauswahl im Finder) ab, kopiert die App, entfernt das macOS
     Quarantäne-Attribut (xattr -cr) automatisch und startet AutoQSO auf Wunsch direkt.

2. OPTION 2 (Interaktives Terminal-Installationsskript):
   - Starte per Doppelklick das Skript `Install AutoQSO.command`.
   - Folge den Eingabeaufforderungen im Terminal.

3. OPTION 3 (Manuell: Drag-and-Drop + Terminal):
   - Ziehe `AutoQSO.app` in den Ordner `Applications` (Programme).
   - Öffne das Terminal (Programme > Dienstprogramme > Terminal) und führe aus:

       xattr -cr /Applications/AutoQSO.app
       codesign --force --deep --sign - /Applications/AutoQSO.app

4. OPTION 4 (Rechtsklick im Finder):
   - Rechtsklick (oder Ctrl+Klick) auf `AutoQSO.app` im Programme-Ordner -> "Öffnen".
   - Falls blockiert: Systemeinstellungen > Datenschutz & Sicherheit -> "Dennoch öffnen".


--------------------------------------------------------------------------------
ENGLISH: How to install & run AutoQSO on macOS?
--------------------------------------------------------------------------------

Since AutoQSO is distributed with ad-hoc code signing (without a paid Apple
Developer ID certificate), macOS Gatekeeper might block the app on first launch.

1. OPTION 1 (1-Click GUI Installer – Recommended):
   - Double-click `AutoQSO Installer.app` inside this DMG.
   - If Gatekeeper prompts a warning: Right-click (or Ctrl+Click) `AutoQSO Installer.app` -> "Open".
   - The graphical installer prompts for your target directory (/Applications, ~/Applications,
     or custom folder via Finder dialog), copies the app, strips Gatekeeper
     quarantine locks (xattr -cr), refreshes code signing, and launches AutoQSO cleanly!

2. OPTION 2 (Interactive Terminal Installer Script):
   - Double-click `Install AutoQSO.command` inside this DMG and follow the prompt.

3. OPTION 3 (Manual: Drag-and-Drop + Terminal):
   - Drag `AutoQSO.app` into the `Applications` folder shortcut.
   - Open Terminal (Applications > Utilities > Terminal) and run:

       xattr -cr /Applications/AutoQSO.app
       codesign --force --deep --sign - /Applications/AutoQSO.app

4. OPTION 4 (Finder Right-Click):
   - Right-click (or Ctrl+Click) `AutoQSO.app` in `/Applications` and select "Open".
   - If blocked: Open System Settings > Privacy & Security -> "Open Anyway".

================================================================================
README_EOF

hdiutil create -volname "$APP_NAME v$VERSION" -srcfolder "$STAGING" \
    -ov -format UDZO "$DMG_PATH" > /dev/null
rm -rf "$STAGING"
cp "$DMG_PATH" "$DMG_LATEST"
success "DMG: $DMG_NAME (inkl. README.txt)"

# ── 7. Git commit & Tag & Push ───────────────────────────────
info "Git Commit, Tag & Push..."
TAG="v${VERSION}-b${BUILD}"
TITLE="AutoQSO v${VERSION} (Build ${BUILD})"

git add \
    "$PROJECT_DIR/.version" \
    "$PROJECT_DIR/.build_number" \
    "$PROJECT_DIR/Sources/AutoQSO/BuildNumber.swift" \
    "$PROJECT_DIR/Sources/" \
    "$PROJECT_DIR/HELP.md" 2>/dev/null || true

git commit -m "Release v$VERSION Build $BUILD" 2>/dev/null || warn "Nichts zu committen"
git tag -a "$TAG" -m "$TITLE" 2>/dev/null || warn "Tag existiert bereits"

REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
if [ -n "$REMOTE_URL" ]; then
    git push origin main 2>/dev/null || warn "Push fehlgeschlagen"
    git push origin "$TAG" 2>/dev/null || warn "Tag-Push fehlgeschlagen"
    success "Code & Tag gepusht → GitHub"
else
    warn "Kein Git Remote – Push übersprungen"
fi

# ── 8. GitHub Release ─────────────────────────────────────────
RELEASE_NOTES="## $TITLE

### Änderungen seit letztem Release
$CHANGELOG

---
**Anforderungen:** macOS 14.0+
**Copyright:** © 2024–2026 Georg Isenbürger · DJ6GI"

# Token ermitteln: Umgebungsvariable → eingebettet in Remote-URL
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [ -z "$TOKEN" ]; then
    TOKEN=$(echo "$REMOTE_URL" | grep -oE 'ghp_[A-Za-z0-9]+' | head -1 || echo "")
fi

if command -v gh > /dev/null 2>&1 && gh auth status > /dev/null 2>&1; then
    info "GitHub Release via gh CLI..."
    gh release create "$TAG" "$DMG_PATH" \
        --repo "$GITHUB_REPO" \
        --title "$TITLE" \
        --notes "$RELEASE_NOTES" \
        --latest
    success "GitHub Release erstellt & DMG hochgeladen!"
    echo -e "  🌐 https://github.com/$GITHUB_REPO/releases/tag/$TAG"
elif [ -n "$TOKEN" ]; then
    github_release "$TOKEN" "$TAG" "$TITLE" "$RELEASE_NOTES" "$DMG_PATH" "$DMG_NAME"
else
    warn "Kein GitHub Token verfügbar – Release übersprungen."
    warn "→ Installiere 'gh' und führe 'gh auth login' aus"
    warn "→ oder setze: export GITHUB_TOKEN=ghp_..."
fi

# ── Zusammenfassung ───────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  Release v$VERSION (Build $BUILD) fertig!        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📦 DMG:   $DMG_PATH"
echo -e "  🔖 Tag:   $TAG"
echo -e "  🌐 Repo:  https://github.com/$GITHUB_REPO/releases"
echo ""
