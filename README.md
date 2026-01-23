# MkDocs Multi-Project Docker Compose Setup

Ein hardened, produktionsreifes Multi-Project-Setup für MkDocs mit lokalem Host-Speicher, automatisiertem Build und Nginx-Serving.

## Schnellstart (TL;DR)

```bash
# 1. Ordner erstellen
mkdir -p ~/docs-projects ~/docs-site

# 2. Repo klonen / ins Verzeichnis gehen
cd ~/Code/mkdocs-projects-server

# 3. Environment-Variablen setzen (einmalig)
echo "USER_ID=$(id -u)" > .env
echo "GROUP_ID=$(id -g)" >> .env
echo "PROJECTS_DIR=$HOME/docs-projects" >> .env
echo "SITE_DIR=$HOME/docs-site" >> .env
echo "NGINX_PORT=8080" >> .env

# 4. Stack starten
docker compose up -d --build

# 5. Fertig
# http://127.0.0.1:8080/
```

---

## Architektur

### Datei-Layout auf dem Host

```
~/docs-projects/           ← Hier legst du deine MkDocs-Projekte hin
├── projekt-alpha/
│   ├── mkdocs.yml
│   └── docs/
│       ├── index.md
│       └── ...
├── projekt-beta/
│   ├── mkdocs.yml
│   └── docs/
│       └── index.md
└── projekt-gamma/
    └── ...

~/docs-site/               ← Build-Output (Container schreibt hier)
├── projekt-alpha/
│   ├── index.html
│   └── ...
├── projekt-beta/
│   └── ...
└── index.html             ← Auto-generierter Index (optional)
```

### Docker Services

```
builder          → baut alle Projekte aus ~/docs-projects → ~/docs-site
  └─ Python 3.12 + MkDocs in venv
  └─ läuft als nicht-root

nginx            → served ~/docs-site auf 127.0.0.1:8080
  └─ read-only Zugriff
  └─ läuft als nicht-root
```

---

## Schritt-für-Schritt Setup

### 1. Lokale Ordner erstellen

```bash
mkdir -p ~/docs-projects ~/docs-site
```

Gib beiden Ordnern die gleichen Rechte wie dein aktueller User:

```bash
chmod 755 ~/docs-projects ~/docs-site
```

### 2. `.env` konfigurieren

Editiere oder erstelle `~/Code/mkdocs-projects-server/.env`:

```bash
# Automatisch (am schnellsten)
echo "USER_ID=$(id -u)" > .env
echo "GROUP_ID=$(id -g)" >> .env
echo "PROJECTS_DIR=$HOME/docs-projects" >> .env
echo "SITE_DIR=$HOME/docs-site" >> .env
echo "NGINX_PORT=8080" >> .env
echo "CONTAINER_BUILDER=mkdocs-builder" >> .env
echo "CONTAINER_NGINX=docs-nginx" >> .env
```

Oder manuell (`~/Code/mkdocs-projects-server/.env`):

```env
USER_ID=1000
GROUP_ID=1000
PROJECTS_DIR=/home/username/docs-projects
SITE_DIR=/home/username/docs-site
NGINX_PORT=8080
CONTAINER_BUILDER=mkdocs-builder
CONTAINER_NGINX=docs-nginx
```

⚠️ **Wichtig:** Nutze **absolute Pfade** (nicht `~`). Dein aktueller User muss diese Ordner besitzen:

```bash
ls -la ~/docs-projects ~/docs-site
# drwxr-xr-x dein_user dein_user
```

### 3. Stack bauen und starten

```bash
cd ~/Code/mkdocs-projects-server
docker compose up -d --build
```

Das erste Mal dauert 1-2 Min (Python + Dependencies). Danach:

```bash
# Status checken
docker compose ps

# Logs lesen (Builder, Nginx)
docker compose logs -f builder
docker compose logs -f nginx
```

### 4. Dein erstes Projekt

Erstelle `~/docs-projects/mein-projekt/`:

```bash
mkdir -p ~/docs-projects/mein-projekt/docs
cat > ~/docs-projects/mein-projekt/mkdocs.yml << 'EOF'
site_name: Mein Projekt
docs_dir: docs
site_dir: site
theme:
  name: material
EOF

cat > ~/docs-projects/mein-projekt/docs/index.md << 'EOF'
# Willkommen

Das ist mein erstes MkDocs Projekt.
EOF
```

### 5. Neuen Build starten

```bash
# Builder neu ausführen (erzeugt ~/docs-site/mein-projekt/)
docker compose run --rm builder

# Check
ls ~/docs-site/mein-projekt/
# → index.html, ...

# Browser
# http://127.0.0.1:8080/mein-projekt/
```

---

## Tägliche Befehle

| Befehl                                | Effekt                         |
| ------------------------------------- | ------------------------------ |
| `docker compose up -d`                | Stack starten                  |
| `docker compose down`                 | Stack stoppen                  |
| `docker compose run --rm builder`     | Alle Projekte neu bauen        |
| `docker compose logs -f builder`      | Builder-Logs live              |
| `docker compose logs -f nginx`        | Nginx-Logs live                |
| `docker compose restart nginx`        | Nginx neu starten              |
| `docker compose ps`                   | Status                         |

---

## Häufige Probleme

### Permission Denied beim Builder

**Problem:** Builder kann in `~/docs-site` nicht schreiben.

**Lösung:**

```bash
# Check die UID/GID in .env
cat .env | grep USER_ID

# Falls falsch, aktualisier .env mit deinen realen Werten
echo "USER_ID=$(id -u)" > .env
echo "GROUP_ID=$(id -g)" >> .env
# ... (rest wiederholen)

# Container neu starten
docker compose down
docker compose up -d --build
docker compose run --rm builder
```

### `mkdocs.yml` existiert, Build schlägt fehl

**Problem:** Das Projekt wird übersprungen.

**Logs checken:**

```bash
docker compose logs builder | grep -i "skip\|error"
```

**Häufige Gründe:**

* `mkdocs.yml` liegt falsch (muss im Projektwurzel-Verzeichnis sein)
* YAML-Syntax-Fehler (nutze yamllint zum Checken)
* Fehlende Theme (z. B. `mkdocs-material`)

**Fix:**

```bash
# mkdocs.yml lokal validieren (falls mkdocs lokal installiert)
cd ~/docs-projects/dein-projekt
mkdocs build --strict
```

### Nginx zeigt 404

**Problem:** Browser erreicht Seite nicht.

**Checks:**

```bash
# Container laufen?
docker compose ps | grep nginx

# Port richtig?
curl http://127.0.0.1:8080/

# HTML existiert?
ls ~/docs-site/dein-projekt/index.html

# Nginx-Logs
docker compose logs nginx
```

---

## Datenschutz & Hardening

Dieses Setup ist hardened:

* **read-only Filesystems** auf Builder und Nginx
* **no-new-privileges** Cap-Drop
* **nicht-root** User überall
* **tmpfs** für Schreibzugriffe
* **Strict UID/GID Mapping** (keine Permission-Hölle auf dem Host)

Deine Quellen bleiben unter **deiner Kontrolle** auf dem Host. Die Container können nur:

* Builder: `/projects` lesen, `/site` schreiben
* Nginx: `/site` lesen (read-only)

---

## Optionale Features

### Auto-Generierte Index-Seite

Um einen Index mit Links zu allen Projekten zu generieren, nutze:

```bash
docker compose run --rm builder-index
```

(Noch nicht implementiert – kommt später.)

### Watch Mode (Auto-Build bei Änderungen)

Für Entwicklung: Container der mit inotify lädt und rebuildet (auf Anfrage).

### Backup

```bash
# Alle Projekte + Sites sichern
tar czf docs-backup-$(date +%Y%m%d).tar.gz ~/docs-projects ~/docs-site
```

---

## Debugging & Entwicklung

### In den Builder-Container gehen

```bash
docker compose run --rm --entrypoint /bin/bash builder

# Dann im Container:
ls /home/mkdocs/work/projects
ls /home/mkdocs/work/site
/home/mkdocs/venv/bin/mkdocs --version
```

### Nginx-Config anschauen

```bash
docker compose exec nginx cat /etc/nginx/nginx.conf
```

### Performance-Metriken

```bash
docker stats
```

---

## Struktur des Repos

```
~/Code/mkdocs-projects-server/
├── README.md                  ← Du bist hier
├── docker-compose.yml         ← Orchestrierung
├── .env                       ← Deine Konfiguration (lokale Variablen)
│
├── builder/
│   ├── Dockerfile             ← Python 3.12 + MkDocs + venv
│   ├── requirements.txt        ← pip-Abhängigkeiten
│   └── build-all.sh           ← Build-Script (läuft im Container)
│
├── nginx/
│   ├── Dockerfile             ← Alpine Nginx (hardened)
│   ├── nginx.conf             ← Hauptkonfiguration
│   └── conf.d/                ← Site-spezifische Configs
│       └── default.conf       ← Default Projekt-Index
│
└── .gitignore                 ← (optional)
```

---

## Lizenz & Support

Dieses Setup ist **lokal, selbstverwaltend und wartbar**. Keine Cloud-Abhängigkeiten.

Bei Fragen: **Logs checken** (`docker compose logs`) ist der erste Schritt.

---

## Versionsinfo

* **Docker:** 20.10+
* **Python:** 3.12
* **MkDocs:** 1.6.1
* **Theme:** mkdocs-material 9.5.30
* **Nginx:** 1.27 (Alpine)

Aktualisierungen der MkDocs-Version: Editiere `builder/requirements.txt` und führe `docker compose up -d --build` aus.
