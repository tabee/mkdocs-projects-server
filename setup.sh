#!/usr/bin/env bash
set -euo pipefail

# MkDocs Projects Server - Setup Script
# =====================================
# Dieses Script erstellt eine .env Datei mit allen erforderlichen Variablen.
# Es gibt KEINE Default-Werte - alle Werte werden interaktiv abgefragt.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 MkDocs Multi-Project Setup"
echo "=============================="
echo
echo "WICHTIG: Alle Variablen müssen gesetzt werden."
echo "         Es gibt keine Default-Werte."
echo

# 1. Check if .env exists
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    echo "⚠️  .env existiert bereits."
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
echo "👤 Erkannt: UID=${USER_ID}, GID=${GROUP_ID}"
echo

# 3. Ask for PROJECTS_DIR
echo "📂 PROJECTS_DIR: Wo sollen die MkDocs-Projekte liegen?"
echo "   Empfohlen: /srv/appdata/mkdocs/projects"
read -p "   Pfad (absolut): " PROJECTS_DIR

if [[ -z "$PROJECTS_DIR" ]]; then
    echo "❌ PROJECTS_DIR darf nicht leer sein."
    exit 1
fi

if [[ ! "$PROJECTS_DIR" = /* ]]; then
    echo "❌ PROJECTS_DIR muss ein absoluter Pfad sein."
    exit 1
fi

# 4. Ask for SITE_DIR
echo
echo "📂 SITE_DIR: Wo soll der Build-Output gespeichert werden?"
echo "   Empfohlen: /srv/appdata/mkdocs/site"
read -p "   Pfad (absolut): " SITE_DIR

if [[ -z "$SITE_DIR" ]]; then
    echo "❌ SITE_DIR darf nicht leer sein."
    exit 1
fi

if [[ ! "$SITE_DIR" = /* ]]; then
    echo "❌ SITE_DIR muss ein absoluter Pfad sein."
    exit 1
fi

# 5. Ask for NGINX_PORT
echo
echo "🌐 NGINX_PORT: Auf welchem Port soll Nginx lauschen?"
read -p "   Port (z.B. 8080): " NGINX_PORT

if [[ -z "$NGINX_PORT" ]]; then
    echo "❌ NGINX_PORT darf nicht leer sein."
    exit 1
fi

if ! [[ "$NGINX_PORT" =~ ^[0-9]+$ ]]; then
    echo "❌ NGINX_PORT muss eine Zahl sein."
    exit 1
fi

# 6. Ask for container names
echo
echo "📦 Container-Namen:"
read -p "   CONTAINER_BUILDER (z.B. mkdocs-builder): " CONTAINER_BUILDER
read -p "   CONTAINER_NGINX (z.B. docs-nginx): " CONTAINER_NGINX

if [[ -z "$CONTAINER_BUILDER" ]] || [[ -z "$CONTAINER_NGINX" ]]; then
    echo "❌ Container-Namen dürfen nicht leer sein."
    exit 1
fi

# 7. Create directories
echo
echo "📁 Erstelle Ordner..."
mkdir -p "$PROJECTS_DIR" "$SITE_DIR"
chmod 755 "$PROJECTS_DIR" "$SITE_DIR"
echo "   ✓ $PROJECTS_DIR"
echo "   ✓ $SITE_DIR"

# 8. Create .env
echo
echo "🔧 Erstelle .env..."
cat > "$SCRIPT_DIR/.env" << EOF
# MkDocs Projects Server Configuration
# Generiert von setup.sh am $(date +%Y-%m-%d)

USER_ID=${USER_ID}
GROUP_ID=${GROUP_ID}

PROJECTS_DIR=${PROJECTS_DIR}
SITE_DIR=${SITE_DIR}

NGINX_PORT=${NGINX_PORT}

CONTAINER_BUILDER=${CONTAINER_BUILDER}
CONTAINER_NGINX=${CONTAINER_NGINX}
EOF

echo "   ✓ $SCRIPT_DIR/.env"
echo
echo "📋 Konfiguration:"
cat "$SCRIPT_DIR/.env"

# 9. Build Docker Images
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

# 10. Start services
echo
echo "▶️  Starte Services..."
$COMPOSE_CMD up -d

echo
echo "✅ Setup abgeschlossen!"
echo
echo "📋 Nächste Schritte:"
echo "   1. Erstelle ein Test-Projekt:"
echo "      mkdir -p ${PROJECTS_DIR}/test-projekt/docs"
echo
echo "   2. Erstelle ${PROJECTS_DIR}/test-projekt/mkdocs.yml:"
echo "      ---"
echo "      site_name: Test"
echo "      docs_dir: docs"
echo "      theme:"
echo "        name: material"
echo "      ---"
echo
echo "   3. Erstelle ${PROJECTS_DIR}/test-projekt/docs/index.md:"
echo "      # Hallo MkDocs"
echo
echo "   4. Baue neu:"
echo "      $COMPOSE_CMD run --rm builder"
echo
echo "   5. Öffne Browser:"
echo "      http://127.0.0.1:${NGINX_PORT}/test-projekt/"
echo
echo "📚 Weitere Infos: cat README.md"
