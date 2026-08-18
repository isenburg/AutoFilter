#!/bin/bash
set -e

# --- Konfiguration ---
APP_NAME="AutoQSO"
VERSION="${1:-1.0.0}"
RELEASE_DIR="./releases/v${VERSION}"
DMG_NAME="${APP_NAME}_${VERSION}.dmg"
STAGING_DIR="/tmp/${APP_NAME}_staging"

echo "==> Starte lokalen Release-Prozess für ${APP_NAME} (v${VERSION})..."

# 1. Verzeichnisse vorbereiten
rm -rf "$STAGING_DIR" "$RELEASE_DIR"
mkdir -p "$STAGING_DIR" "$RELEASE_DIR"


# 2. Release-Build via xcodebuild erstellen (explizit für macOS)
echo "==> Erstelle Release-Build..."
xcodebuild -scheme "$APP_NAME" \
           -configuration Release \
           -destination 'generic/platform=macOS' \
           -derivedDataPath ./build \
           clean build > /dev/null

# 3. App und Symlink zum Programme-Ordner im Staging ablegen
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# 4. DMG erzeugen (nativ via hdiutil)
echo "==> Erzeuge ${DMG_NAME}..."
hdiutil create -volname "${APP_NAME} v${VERSION}" \
               -srcfolder "$STAGING_DIR" \
               -ov -format UDZO \
               "${RELEASE_DIR}/${DMG_NAME}"

# Aufräumen
rm -rf "$STAGING_DIR"

# 5. Lokalen Git-Tag setzen (wird NICHT gepusht)
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    TAG_NAME="v${VERSION}"
    if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
        echo "Hinweis: Lokaler Git-Tag $TAG_NAME existiert bereits."
    else
        git tag -a "$TAG_NAME" -m "Lokaler Release $TAG_NAME"
        echo "==> Lokaler Git-Tag '$TAG_NAME' wurde erstellt."
    fi
fi

echo "=========================================="
echo "Release erfolgreich lokal erstellt!"
echo "DMG-Pfad: ${RELEASE_DIR}/${DMG_NAME}"
echo "=========================================="