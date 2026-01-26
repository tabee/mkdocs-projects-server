#!/usr/bin/env bash
set -euo pipefail

PROJECTS="${PROJECTS_DIR:-/home/mkdocs/work/projects}"
BUILD_SCRIPT="/home/mkdocs/build-all.sh"

echo "👁️  Starte File-Watcher für MkDocs Projekte..."
echo "   Überwache: ${PROJECTS}"
echo ""

# Initial build
bash "${BUILD_SCRIPT}"

echo ""
echo "👁️  Warte auf Änderungen... (Strg+C zum Beenden)"

# Watch for changes and rebuild
inotifywait -m -r -e modify,create,delete,move \
  --exclude '(__pycache__|\.pyc$|\.git|site/)' \
  "${PROJECTS}" | while read -r directory event filename; do
    
    # Debounce: kurze Pause um multiple Events zu gruppieren
    sleep 0.5
    
    # Entferne verbleibende Events aus dem Buffer
    while read -t 0.1 -r; do :; done
    
    echo ""
    echo "📝 Änderung erkannt: ${directory}${filename}"
    echo "🔄 Rebuilding..."
    
    if bash "${BUILD_SCRIPT}"; then
      echo "✅ Rebuild erfolgreich"
    else
      echo "❌ Rebuild fehlgeschlagen"
    fi
    
    echo "👁️  Warte auf weitere Änderungen..."
done
