#!/usr/bin/env bash
set -euo pipefail

# MkDocs Projects Server - Quick Setup Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 MkDocs Multi-Project Setup"
echo "=============================="
echo

# 1. Check if .env exists
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    echo "✅ .env existiert bereits."
    read -p "Willst du sie überschreiben? (j/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Jj]$ ]]; then
        echo "OK, nutze existierende .env"
        exit 0
    fi
fi

# 2. Get user ID and Group ID
USER_ID=$(id -u)
GROUP_ID=$(id -g)
echo "👤 Dein User: $(id -un) (UID: $USER_ID, GID: $GROUP_ID)"

# 3. Ask for base directory
read -p "📂 Wo sollen die Ordner liegen? (default: $HOME) " BASE_DIR
BASE_DIR="${BASE_DIR:-$HOME}"

if [[ ! -d "$BASE_DIR" ]]; then
    echo "❌ $BASE_DIR existiert nicht."
    exit 1
fi

PROJECTS_DIR="$BASE_DIR/docs-projects"
SITE_DIR="$BASE_DIR/docs-site"

# 4. Create directories
echo
echo "📁 Erstelle Ordner..."
mkdir -p "$PROJECTS_DIR" "$SITE_DIR"
chmod 755 "$PROJECTS_DIR" "$SITE_DIR"
echo "   ✓ $PROJECTS_DIR"
echo "   ✓ $SITE_DIR"

# 5. Create .env
echo
echo "🔧 Erstelle .env..."
cat > "$SCRIPT_DIR/.env" << EOF
# MkDocs Projects Server Configuration
# Automatisch generiert von setup.sh

USER_ID=$USER_ID
GROUP_ID=$GROUP_ID

PROJECTS_DIR=$PROJECTS_DIR
SITE_DIR=$SITE_DIR

NGINX_PORT=8080

CONTAINER_BUILDER=mkdocs-builder
CONTAINER_NGINX=docs-nginx
EOF

echo "   ✓ $SCRIPT_DIR/.env"
cat "$SCRIPT_DIR/.env"

# 6. Build Docker Images
echo
echo "🐳 Docker Images werden gebuildet..."
cd "$SCRIPT_DIR"

if ! command -v docker &> /dev/null; then
    echo "❌ Docker ist nicht installiert."
    exit 1
fi

if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ docker-compose ist nicht verfügbar."
    exit 1
fi

echo "   Nutze: $COMPOSE_CMD"
$COMPOSE_CMD build

# 7. Start services
echo
echo "▶️  Starte Services..."
$COMPOSE_CMD up -d

echo
echo "✅ Setup abgeschlossen!"
echo
echo "📋 Nächste Schritte:"
echo "   1. Erstelle ein Test-Projekt:"
echo "      mkdir -p $PROJECTS_DIR/test-projekt/docs"
echo
echo "   2. Erstelle $PROJECTS_DIR/test-projekt/mkdocs.yml:"
echo "      ---"
echo "      site_name: Test"
echo "      docs_dir: docs"
echo "      theme:"
echo "        name: material"
echo "      ---"
echo
echo "   3. Erstelle $PROJECTS_DIR/test-projekt/docs/index.md:"
echo "      # Hallo MkDocs"
echo
echo "   4. Baue neu:"
echo "      $COMPOSE_CMD run --rm builder"
echo
echo "   5. Öffne Browser:"
echo "      http://127.0.0.1:8080/test-projekt/"
echo
echo "📚 Weitere Infos: cat README.md"
