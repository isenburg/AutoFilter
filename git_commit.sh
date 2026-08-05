#!/bin/bash

# Abbrechen, falls ein Befehl fehlschlägt
set -e

# Prüfen, ob das aktuelle Verzeichnis ein Git-Repository ist
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Fehler: Das aktuelle Verzeichnis ist kein Git-Repository!"
    exit 1
fi

# Optional: Nachrichten-Übergabe via Parameter (z. B. ./commit.sh "Feature X eingebaut")
# Falls kein Parameter übergeben wurde, wird ein Standard-Zeitstempel genutzt.
COMMIT_MSG="${1:-Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')}"

echo "1. Füge alle geänderten und neuen Dateien hinzu..."
git add -A

# Prüfen, ob es überhaupt Änderungen zum Committen gibt
if git diff-index --quiet HEAD --; then
    echo "Keine Änderungen vorhanden. Es wurde kein Commit erstellt."
    exit 0
fi

echo "2. Erstelle lokalen Commit..."
git commit -m "$COMMIT_MSG"

echo "Erfolgreich committed!"
git log -1 --stat