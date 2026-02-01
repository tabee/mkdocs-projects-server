#!/usr/bin/env bash

cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║  ✅ MkDocs Multi-Project Setup - VOLLSTÄNDIG IMPLEMENTIERT    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

📦 PROJEKT-STRUKTUR
═══════════════════════════════════════════════════════════════

mkdocs-projects-server/
├── 📘 README.md               ← Vollständige Dokumentation
├── 🚀 QUICKSTART.md           ← Schnelleinstieg
├── ✅ IMPLEMENTATION.md       ← Was wurde gemacht
│
├── 🐳 docker-compose.yml      ← Services: builder + nginx
├── 🔧 .env.example            ← Konfiguration-Template (alle Werte erforderlich!)
├── 🔒 .gitignore              ← Git-Ignores
├── ⚙️  setup.sh               ← Interaktives Setup Script
│
├── 📁 builder/
│   ├── Dockerfile             ← Python 3.12 + MkDocs + venv
│   ├── requirements.txt        ← Abhängigkeiten
│   └── build-all.sh           ← Multi-Project Build Script
│
└── 📁 nginx/
    ├── Dockerfile             ← Alpine Nginx (hardened)
    ├── nginx.conf             ← Hauptkonfiguration
    └── conf.d/
        └── default.conf       ← Vhost-Konfiguration


🎯 FEATURES IMPLEMENTIERT
═══════════════════════════════════════════════════════════════

✅ Multi-Project Support
   → Beliebig viele Projekte in ${PROJECTS_DIR}/

✅ Lokale Datenspeicherung
   → Quellen: ${PROJECTS_DIR}/ (auf Host)
   → Output: ${SITE_DIR}/ (auf Host)
   → Keine "wer hat was erstellt"-Permission-Hölle

✅ Flexible Python venv (im Container)
   → Nicht Host-abhängig
   → Reproduzierbar (Dockerfile + requirements.txt)
   → Einfach aktualisierbar

✅ UID/GID Mapping
   → Builder schreibt mit Host-UID/GID
   → Keine Root-Permission-Probleme

✅ Hardened Setup
   → read-only Filesystems
   → Non-root User überall
   → no-new-privileges
   → CAP_DROP ALL
   → tmpfs für temporäre Dateien

✅ Production-Ready
   → Nginx mit Security Headers
   → Proper Logging
   → Saubere Trennung: Repo-Code vs. Host-Daten

✅ Keine Default-Werte
   → Deployment rein über explizit gesetzte Umgebungsvariablen


🚀 QUICKSTART
═══════════════════════════════════════════════════════════════

Option A - Interaktiv (EMPFOHLEN):

    bash setup.sh

    → Fragt alle erforderlichen Werte ab
    → Erstellt .env
    → Erstellt Ordner
    → Baut Docker Images
    → Startet Services


Option B - Manuell:

    # 1. .env erstellen (ALLE Werte erforderlich!)
    cat > .env << EOF
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    PROJECTS_DIR=/srv/appdata/mkdocs/projects
    SITE_DIR=/srv/appdata/mkdocs/site
    NGINX_PORT=8080
    CONTAINER_BUILDER=mkdocs-builder
    CONTAINER_NGINX=docs-nginx
    EOF

    # 2. Ordner erstellen
    mkdir -p /srv/appdata/mkdocs/projects /srv/appdata/mkdocs/site

    # 3. Stack bauen
    docker compose up -d --build

    # 4. Test
    docker compose run --rm builder


📊 DATEN-LAYOUT
═══════════════════════════════════════════════════════════════

Auf dem Host:

    ${PROJECTS_DIR}/                  ← MkDocs-Quellen
    ├── projekt-alpha/
    │   ├── mkdocs.yml
    │   └── docs/
    │       └── index.md
    └── projekt-beta/
        └── ...

    ${SITE_DIR}/                      ← Build-Output
    ├── projekt-alpha/
    │   ├── index.html
    │   └── ...
    └── projekt-beta/
        └── ...

Im Browser:

    http://127.0.0.1:${NGINX_PORT}/projekt-alpha/
    http://127.0.0.1:${NGINX_PORT}/projekt-beta/


⚙️  TÄGLICHE BEFEHLE
═══════════════════════════════════════════════════════════════

docker compose up -d              Stack starten
docker compose down               Stack stoppen
docker compose run --rm builder   Alle Projekte neu bauen
docker compose logs -f builder    Builder-Logs live
docker compose logs -f nginx      Nginx-Logs live
docker compose ps                 Status


🔧 .env VARIABLEN (ALLE ERFORDERLICH!)
═══════════════════════════════════════════════════════════════

USER_ID=                                        # Linux-UID (id -u)
GROUP_ID=                                       # Linux-GID (id -g)
PROJECTS_DIR=                                   # Absoluter Pfad!
SITE_DIR=                                       # Absoluter Pfad!
NGINX_PORT=                                     # Port
CONTAINER_BUILDER=                              # Container-Name
CONTAINER_NGINX=                                # Container-Name


📚 DOKUMENTATION
═══════════════════════════════════════════════════════════════

README.md
  → Ausführliche Dokumentation
  → Schritt-für-Schritt Setup
  → Troubleshooting
  → Häufige Fehler & Lösungen
  → Optionale Features

QUICKSTART.md
  → Schnelleinstieg
  → Checklisten
  → Häufige Fehler

IMPLEMENTATION.md
  → Was wurde implementiert
  → Feature-Übersicht
  → Workflow-Beispiele


🔒 SICHERHEIT
═══════════════════════════════════════════════════════════════

✅ Datenquellen unter deiner Kontrolle
   → Alles auf dem Host in ${PROJECTS_DIR}/ und ${SITE_DIR}/

✅ Container hardened
   → read-only FS
   → non-root User
   → Strict UID/GID Mapping
   → No-new-privileges
   → CAP_DROP ALL

✅ Backup ist trivial
   → tar czf backup.tar.gz ${PROJECTS_DIR} ${SITE_DIR}


❓ HÄUFIGE FRAGEN
═══════════════════════════════════════════════════════════════

F: Wie viele Projekte kann ich haben?
A: Unbegrenzt. Builder findet alle automatisch.

F: Wie starte ich einen Rebuild?
A: docker compose run --rm builder

F: Kann ich die Theme ändern?
A: Ja. builder/requirements.txt ändern → docker compose up -d --build

F: Werden meine Daten im Container gespeichert?
A: Nein. Alles liegt auf dem Host.

F: Was kostet das?
A: Nichts. Open-Source Stack (MkDocs, Nginx, Alpine).


✨ STATUS
═══════════════════════════════════════════════════════════════

Status: ✅ READY FOR PRODUCTION

Alle Anforderungen erfüllt:
  ✅ Multi-Project-Support
  ✅ Lokale Datenspeicherung
  ✅ Flexible venv
  ✅ UID/GID Mapping
  ✅ Hardened Setup
  ✅ Ausführliche Dokumentation
  ✅ Interaktives Setup Script
  ✅ Troubleshooting Guides
  ✅ Keine Default-Werte


🎬 LOS GEHT'S!
═══════════════════════════════════════════════════════════════

1. Lese README.md oder QUICKSTART.md
2. Führe "bash setup.sh" aus
3. Erstelle ein Test-Projekt
4. Öffne http://127.0.0.1:${NGINX_PORT}/ im Browser

Questions? Check README.md → Troubleshooting section.

═══════════════════════════════════════════════════════════════
EOF
