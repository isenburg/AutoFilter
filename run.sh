#!/bin/bash

# Navigate to project directory
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR" || exit 1

APP_NAME="AutoFilter"

echo "Beende $APP_NAME falls es läuft..."
killall "$APP_NAME" 2>/dev/null
sleep 1

VERSION_FILE=".version"
if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0.0" > "$VERSION_FILE"
fi
VERSION_NUM=$(cat "$VERSION_FILE" | tr -d ' \n\r')

BUILD_FILE=".build_number"
if [ ! -f "$BUILD_FILE" ]; then
    echo "0" > "$BUILD_FILE"
fi

BUILD_NUM=$(cat "$BUILD_FILE")
BUILD_NUM=$((BUILD_NUM + 1))
echo "$BUILD_NUM" > "$BUILD_FILE"
echo "Neue Version: $VERSION_NUM (Build-Nummer: $BUILD_NUM)"

# Speichere die Version & Build-Nummer im Swift Code
cat > Sources/AutoFilter/BuildNumber.swift <<EOF
public let APP_VERSION = "$VERSION_NUM"
public let APP_BUILD_NUMBER = $BUILD_NUM
EOF

echo "Kompiliere Debug-Version..."
swift build -c debug

if [ $? -eq 0 ]; then
    echo "Erstelle App-Bundle im Projektverzeichnis..."
    BUNDLE_DIR="${PROJECT_DIR}/${APP_NAME}.app"
    CONTENTS_DIR="${BUNDLE_DIR}/Contents"
    MACOS_DIR="${CONTENTS_DIR}/MacOS"
    RESOURCES_DIR="${CONTENTS_DIR}/Resources"
    
    rm -rf "$BUNDLE_DIR"
    mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
    
    cp ".build/debug/$APP_NAME" "$MACOS_DIR/"
    if [ -f "Resources/AppIcon.icns" ]; then
        cp "Resources/AppIcon.icns" "$RESOURCES_DIR/"
    fi
    
    cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.dj6gi.autofilter</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUM</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION_NUM</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>AutoFilter benötigt Zugriff auf RUMlogNG, um Logbuch-Einträge abzugleichen.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024–2026 Georg Isenbürger · DJ6GI</string>
</dict>
</plist>
EOF

    echo "Signiere App-Bundle ad-hoc..."
    codesign --force --deep --sign - "$BUNDLE_DIR"

    echo "Starte ${BUNDLE_DIR}..."
    open "$BUNDLE_DIR"
else
    echo "Fehler beim Kompilieren!"
    exit 1
fi
