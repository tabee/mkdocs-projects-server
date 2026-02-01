# MkDocs Multi-Project Docker Compose Setup

Ein hardened, produktionsreifes Multi-Project-Setup für MkDocs mit lokalem Host-Speicher, automatisiertem Build und Nginx-Serving.

## Schnellstart (TL;DR)

**WICHTIG:** Alle Umgebungsvariablen müssen explizit gesetzt werden. Es gibt keine Default-Werte.

```bash
# 1. Ordner erstellen (Beispiel-Pfade)
mkdir -p /srv/appdata/mkdocs/projects /srv/appdata/mkdocs/site

# 2. Repo klonen / ins Verzeichnis gehen
cd /path/to/mkdocs-projects-server

# 3. Environment-Variablen setzen (alle erforderlich!)
cat > .env << EOF
USER_ID=$(id -u)
GROUP_ID=$(id -g)
PROJECTS_DIR=/srv/appdata/mkdocs/projects
SITE_DIR=/srv/appdata/mkdocs/site
NGINX_PORT=8080
CONTAINER_BUILDER=mkdocs-builder
CONTAINER_NGINX=docs-nginx
EOF

# 4. Stack starten
docker compose up -d --build

# 5. Fertig
# http://127.0.0.1:8080/
```

---

## Architektur

### Datei-Layout auf dem Host

```
${PROJECTS_DIR}/              ← MkDocs-Projekte
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

${SITE_DIR}/                  ← Build-Output (Container schreibt hier)
├── projekt-alpha/
│   ├── index.html
│   └── ...
├── projekt-beta/
│   └── ...
└── index.html               ← Auto-generierter Index (optional)
```

### Docker Services

```
builder          → baut alle Projekte aus ${PROJECTS_DIR} → ${SITE_DIR}
  └─ Python 3.12 + MkDocs in venv
  └─ läuft als nicht-root

nginx            → served ${SITE_DIR} auf 127.0.0.1:${NGINX_PORT}
  └─ read-only Zugriff
  └─ läuft als nicht-root
```

---

## Schritt-für-Schritt Setup

### 1. Lokale Ordner erstellen

```bash
# Empfohlene Pfade:
mkdir -p /srv/appdata/mkdocs/projects /srv/appdata/mkdocs/site
chmod 755 /srv/appdata/mkdocs/projects /srv/appdata/mkdocs/site
```

### 2. `.env` konfigurieren

Alle Variablen sind **erforderlich** - es gibt keine Default-Werte.

```bash
# .env erstellen (alle Werte müssen gesetzt werden)
cat > .env << EOF
USER_ID=$(id -u)
GROUP_ID=$(id -g)
PROJECTS_DIR=/srv/appdata/mkdocs/projects
SITE_DIR=/srv/appdata/mkdocs/site
NGINX_PORT=8080
CONTAINER_BUILDER=mkdocs-builder
CONTAINER_NGINX=docs-nginx
EOF
```

⚠️ **Wichtig**
- Nutze **absolute Pfade** (nicht `~`)
- Der User muss diese Ordner besitzen:

```bash
ls -la /srv/appdata/mkdocs/
# Ownership muss deiner UID/GID entsprechen
```

### 3. Stack bauen und starten

```bash
cd /path/to/mkdocs-projects-server
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

### 4. Erstes Projekt erstellen

```bash
mkdir -p /srv/appdata/mkdocs/projects/mein-projekt/docs

cat > /srv/appdata/mkdocs/projects/mein-projekt/mkdocs.yml << 'EOF'
site_name: Mein Projekt
docs_dir: docs
site_dir: site
theme:
  name: material
EOF

cat > /srv/appdata/mkdocs/projects/mein-projekt/docs/index.md << 'EOF'
# Willkommen

Das ist mein erstes MkDocs Projekt.
EOF
```

### 5. Neuen Build starten

```bash
# Builder neu ausführen
docker compose run --rm builder

# Check
ls /srv/appdata/mkdocs/site/mein-projekt/
# → index.html, ...

# Browser
# http://127.0.0.1:8080/mein-projekt/
```

---

## Erforderliche Variablen

| Variable | Beschreibung | Beispiel |
|----------|--------------|----------|
| `USER_ID` | Linux-UID des Host-Users | `1000` (ermitteln: `id -u`) |
| `GROUP_ID` | Linux-GID des Host-Users | `1000` (ermitteln: `id -g`) |
| `PROJECTS_DIR` | Absoluter Pfad für MkDocs-Projekte | `/srv/appdata/mkdocs/projects` |
| `SITE_DIR` | Absoluter Pfad für Build-Output | `/srv/appdata/mkdocs/site` |
| `NGINX_PORT` | Port für Nginx | `8080` |
| `CONTAINER_BUILDER` | Container-Name für Builder | `mkdocs-builder` |
| `CONTAINER_NGINX` | Container-Name für Nginx | `docs-nginx` |

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

**Problem:** Builder kann in `${SITE_DIR}` nicht schreiben.

**Lösung:**

```bash
# Check die UID/GID in .env
cat .env | grep USER_ID

# Falls falsch, aktualisier .env mit deinen realen Werten
# und starte den Stack neu:
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

### Nginx zeigt 404

**Problem:** Browser erreicht Seite nicht.

**Checks:**

```bash
# Container laufen?
docker compose ps | grep nginx

# Port richtig? (ersetze 8080 mit deinem NGINX_PORT)
curl http://127.0.0.1:8080/

# HTML existiert?
ls ${SITE_DIR}/dein-projekt/index.html

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

Daten bleiben unter **deiner Kontrolle** auf dem Host. Die Container können nur:

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
# Alle Projekte + Sites sichern (Pfade anpassen)
tar czf docs-backup-$(date +%Y%m%d).tar.gz ${PROJECTS_DIR} ${SITE_DIR}
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
mkdocs-projects-server/
├── README.md                  ← Du bist hier
├── docker-compose.yml         ← Orchestrierung
├── .env                       ← Deine Konfiguration (alle Variablen erforderlich)
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
└── .gitignore
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
