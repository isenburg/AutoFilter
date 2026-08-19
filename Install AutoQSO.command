#!/bin/bash
set -euo pipefail

# ============================================================
# AutoQSO macOS Interactive Installer & Gatekeeper Fix
# Copyright (c) Georg Isenbürger - DJ6GI
# ============================================================

# Terminal colors
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="AutoQSO.app"
SOURCE_APP=""

# Locate AutoQSO.app relative to script
if [ -d "$SCRIPT_DIR/$APP_NAME" ]; then
    SOURCE_APP="$SCRIPT_DIR/$APP_NAME"
elif [ -d "$SCRIPT_DIR/../$APP_NAME" ]; then
    SOURCE_APP="$SCRIPT_DIR/../$APP_NAME"
else
    # Check mounted DMGs
    FOUND=$(find /Volumes -maxdepth 2 -name "$APP_NAME" 2>/dev/null | head -n 1 || echo "")
    if [ -n "$FOUND" ] && [ -d "$FOUND" ]; then
        SOURCE_APP="$FOUND"
    fi
fi

echo -e "${CYAN}${BOLD}"
echo "============================================================"
echo "   AutoQSO macOS Interactive Installer & Gatekeeper Fix"
echo "   Copyright (c) Georg Isenbürger - DJ6GI"
echo "============================================================"
echo -e "${NC}"

if [ -z "$SOURCE_APP" ] || [ ! -d "$SOURCE_APP" ]; then
    echo -e "${RED}✗ Fehler: $APP_NAME wurde im aktuellen Verzeichnis oder DMG nicht gefunden!${NC}"
    echo "Bitte stelle sicher, dass sich 'Install AutoQSO.command' im selben Ordner wie '$APP_NAME' befindet."
    echo ""
    read -p "Drücke Eingabe zum Beenden..."
    exit 1
fi

echo -e "Quell-App gefunden: ${GREEN}$SOURCE_APP${NC}\n"

# Prompt user for destination directory
echo -e "${BOLD}Wohin möchtest du AutoQSO installieren?${NC}"
echo -e "  [1] ${CYAN}/Applications${NC} (Systemweiter Programme-Ordner - Empfohlen)"
echo -e "  [2] ${CYAN}~/Applications${NC} (Benutzerdefinierte Programme im Home-Ordner)"
echo -e "  [3] Ordner interaktiv über Finder-Dialog auswählen..."
echo ""
read -p "Deine Wahl [1-3] (Standard: 1): " CHOICE
CHOICE="${CHOICE:-1}"

TARGET_DIR=""

case "$CHOICE" in
    1)
        TARGET_DIR="/Applications"
        ;;
    2)
        TARGET_DIR="$HOME/Applications"
        mkdir -p "$TARGET_DIR"
        ;;
    3)
        echo -e "${CYAN}Öffne Ordnerauswahl im Finder...${NC}"
        SELECTED_FOLDER=$(osascript -e '
            try
                tell application "Finder"
                    set folderPath to POSIX path of (choose folder with prompt "Wähle den Zielordner für AutoQSO:")
                    return folderPath
                end tell
            on error
                return ""
            end try
        ' 2>/dev/null || echo "")
        
        if [ -z "$SELECTED_FOLDER" ]; then
            echo -e "${YELLOW}Auswahl abgebrochen. Verwende /Applications...${NC}"
            TARGET_DIR="/Applications"
        else
            TARGET_DIR="${SELECTED_FOLDER%/}"
        fi
        ;;
    *)
        echo -e "${YELLOW}Ungültige Eingabe. Verwende /Applications...${NC}"
        TARGET_DIR="/Applications"
        ;;
esac

DEST_APP="$TARGET_DIR/$APP_NAME"

echo -e "\nZielordner: ${GREEN}$TARGET_DIR${NC}"

# Check if app already exists at target location
if [ -d "$DEST_APP" ]; then
    echo -e "${YELLOW}Hinweis: Eine bestehende Version von AutoQSO wurde in '$TARGET_DIR' gefunden.${NC}"
    read -p "Möchtest du diese überschreiben? [J/n]: " OVERWRITE
    OVERWRITE="${OVERWRITE:-J}"
    if [[ "$OVERWRITE" =~ ^[JjYy] ]]; then
        echo -e "Entferne alte Version..."
        rm -rf "$DEST_APP"
    else
        echo -e "${RED}Installation abgebrochen.${NC}"
        read -p "Drücke Eingabe zum Beenden..."
        exit 0
    fi
fi

# Step 1: Copy app
echo -e "\n${CYAN}1/3 Kopiere AutoQSO nach '$TARGET_DIR'...${NC}"
cp -R "$SOURCE_APP" "$TARGET_DIR/"
echo -e "${GREEN}✓ Kopieren erfolgreich.${NC}"

# Step 2: Remove quarantine attribute
echo -e "${CYAN}2/3 Entferne macOS Gatekeeper Quarantäne-Attribut (xattr -cr)...${NC}"
xattr -cr "$DEST_APP" 2>/dev/null || true
echo -e "${GREEN}✓ Gatekeeper Quarantäne entfernt.${NC}"

# Step 3: Re-apply ad-hoc code signature
echo -e "${CYAN}3/3 Aktualisiere ad-hoc Code-Signatur (codesign)...${NC}"
codesign --force --deep --sign - "$DEST_APP" 2>/dev/null || true
echo -e "${GREEN}✓ Code-Signatur erfolgreich aufgefrischt.${NC}"

echo -e "\n${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ Installation erfolgreich abgeschlossen!${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}\n"

read -p "Möchtest du AutoQSO jetzt sofort starten? [J/n]: " LAUNCH
LAUNCH="${LAUNCH:-J}"

if [[ "$LAUNCH" =~ ^[JjYy] ]]; then
    echo -e "${CYAN}Starte AutoQSO aus '$TARGET_DIR'...${NC}"
    open "$DEST_APP"
fi

echo -e "\nAuf Wiedersehen!"
sleep 1
