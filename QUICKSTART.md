# Schnellcheck: Alle Dateien vorhanden? ✅

```
✅ README.md                     - Komplette Dokumentation & Gebrauchsanleitung
✅ IMPLEMENTATION.md             - Was wurde implementiert, Status
✅ docker-compose.yml            - Orchestrierung (builder + nginx services)
✅ .env.example                  - Template für .env (alle Variablen erforderlich!)
✅ .gitignore                    - Git-Ignores (.env, __pycache__, etc.)
✅ setup.sh                      - Interaktives Setup-Script

Builder-Container:
✅ builder/Dockerfile            - Python 3.12 + MkDocs + venv, non-root, hardened
✅ builder/requirements.txt       - mkdocs==1.6.1, mkdocs-material==9.5.30
✅ builder/build-all.sh          - Baut alle Projekte

Nginx-Container:
✅ nginx/Dockerfile              - Alpine Nginx, non-root, read-only, hardened
✅ nginx/nginx.conf              - Master-Config mit Security Headers
✅ nginx/conf.d/default.conf     - Vhost für Projekt-Subdirectories
```

## WICHTIG: Keine Default-Werte

**Alle Umgebungsvariablen müssen explizit gesetzt werden.** Es gibt keine Default-Werte.

## Wie geht's weiter?

### Option A: Interaktives Setup (empfohlen)

```bash
bash setup.sh
```

Das Script fragt alle erforderlichen Werte interaktiv ab:
1. PROJECTS_DIR (absoluter Pfad)
2. SITE_DIR (absoluter Pfad)
3. NGINX_PORT
4. Container-Namen
5. Docker-Images bauen
6. Services starten

### Option B: Manuelles Setup

```bash
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

# 4. Testen
docker compose run --rm builder
```

## Was funktioniert dann?

```bash
# Neues Projekt
mkdir -p /srv/appdata/mkdocs/projects/mein-projekt/docs

cat > /srv/appdata/mkdocs/projects/mein-projekt/mkdocs.yml << 'EOF'
site_name: Mein Projekt
docs_dir: docs
theme:
  name: material
EOF

cat > /srv/appdata/mkdocs/projects/mein-projekt/docs/index.md << 'EOF'
# Hallo MkDocs

Das ist mein erstes Projekt.
EOF

# Bauen
docker compose run --rm builder

# Browser (Port aus .env)
# http://127.0.0.1:8080/mein-projekt/
```

## Erforderliche Variablen in .env

| Variable | Beschreibung | Beispiel |
|----------|--------------|----------|
| `USER_ID` | Linux-UID | `id -u` |
| `GROUP_ID` | Linux-GID | `id -g` |
| `PROJECTS_DIR` | MkDocs-Projekte (absolut) | `/srv/appdata/mkdocs/projects` |
| `SITE_DIR` | Build-Output (absolut) | `/srv/appdata/mkdocs/site` |
| `NGINX_PORT` | Port für Nginx | `8080` |
| `CONTAINER_BUILDER` | Container-Name Builder | `mkdocs-builder` |
| `CONTAINER_NGINX` | Container-Name Nginx | `docs-nginx` |

## Häufige Fehler & Fixes

### "Permission denied" beim Builder

```bash
# Überprüfe deine UID/GID
id -u && id -g

# Update .env und Restart
docker compose down && docker compose up -d --build
docker compose run --rm builder
```

### mkdocs.yml existiert, wird aber skipped

```bash
# Logs checken
docker compose logs builder
```

### Nginx zeigt 404

```bash
# HTML vorhanden?
ls ${SITE_DIR}/dein-projekt/index.html

# Nginx-Logs
docker compose logs nginx
```

## Datensicherheit

✅ **Alle Daten liegen auf dem Host:**
- `${PROJECTS_DIR}/` = Quellen
- `${SITE_DIR}/` = Output (Builder schreibt mit UID/GID)

✅ **Container sind hardened:**
- read-only FS (außer wo nötig)
- non-root User
- Strict UID/GID Mapping
- No-new-privileges

✅ **Backup ist trivial:**

```bash
tar czf docs-backup-$(date +%Y%m%d).tar.gz ${PROJECTS_DIR} ${SITE_DIR}
```

---

## Checkliste vor dem Start

- [ ] `.env` vollständig konfiguriert (alle Variablen gesetzt)
- [ ] Ordner erstellt: `mkdir -p ${PROJECTS_DIR} ${SITE_DIR}`
- [ ] `docker` und `docker compose` installiert
- [ ] `docker compose up -d --build` erfolgreich
- [ ] Browser öffnet http://127.0.0.1:${NGINX_PORT}/ ohne Fehler

---

**Status: READY FOR PRODUCTION** ✅

Alle Anforderungen erfüllt. Keine Default-Werte. Deployment rein über Umgebungsvariablen.
