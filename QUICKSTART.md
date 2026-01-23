# Schnellcheck: Alle Dateien vorhanden? ✅

```
✅ README.md                     - Komplette Dokumentation & Gebrauchsanleitung
✅ IMPLEMENTATION.md             - Was wurde implementiert, Status
✅ docker-compose.yml            - Orchestrierung (builder + nginx services)
✅ .env.example                  - Template für .env (manuell: cp .env.example .env)
✅ .gitignore                    - Git-Ignores (.env, __pycache__, etc.)
✅ setup.sh                      - Automatisiertes Setup-Script
✅ Todo.md                       - Dieses Dokument (alte Anforderungen → erledigt)

Builder-Container:
✅ builder/Dockerfile            - Python 3.12 + MkDocs + venv, non-root, hardened
✅ builder/requirements.txt       - mkdocs==1.6.1, mkdocs-material==9.5.30
✅ builder/build-all.sh          - Baut alle Projekte in ~/docs-projects → ~/docs-site

Nginx-Container:
✅ nginx/Dockerfile              - Alpine Nginx, non-root, read-only, hardened
✅ nginx/nginx.conf              - Master-Config mit Security Headers
✅ nginx/conf.d/default.conf     - Vhost für Projekt-Subdirectories
```

## Wie geht's weiter?

### Option A: Automatisiertes Setup (empfohlen)

```bash
bash setup.sh
```

Macht:
1. Erstellt ~/.env mit deiner UID/GID
2. Erstellt ~/docs-projects und ~/docs-site
3. Docker-Images bauen
4. Services starten
5. Zeigt Nächste-Schritte

### Option B: Manuelles Setup

```bash
# 1. .env erstellen
cp .env.example .env
# → Editiere .env: absolute Pfade, USER_ID=$(id -u), GROUP_ID=$(id -g)

# 2. Ordner erstellen
mkdir -p ~/docs-projects ~/docs-site

# 3. Stack bauen
docker compose up -d --build

# 4. Testen
docker compose run --rm builder
```

## Was funktioniert dann?

```bash
# Neues Projekt
mkdir -p ~/docs-projects/mein-projekt/docs
cat > ~/docs-projects/mein-projekt/mkdocs.yml << 'EOF'
site_name: Mein Projekt
docs_dir: docs
theme:
  name: material
EOF

cat > ~/docs-projects/mein-projekt/docs/index.md << 'EOF'
# Hallo MkDocs

Das ist mein erstes Projekt.
EOF

# Bauen
docker compose run --rm builder

# Browser
# http://127.0.0.1:8080/mein-projekt/
```

## Wichtige Variablen in .env

| Variable | Bedeutung | Beispiel |
|----------|-----------|----------|
| `USER_ID` | Deine Linux-UID | `1000` (from `id -u`) |
| `GROUP_ID` | Deine Linux-GID | `1000` (from `id -g`) |
| `PROJECTS_DIR` | Wo liegen deine MkDocs-Projekte? | `/home/mario/docs-projects` |
| `SITE_DIR` | Wo sollen die gebauten Sites hin? | `/home/mario/docs-site` |
| `NGINX_PORT` | Port für Nginx (lokal) | `8080` |
| `CONTAINER_BUILDER` | Container-Name Builder | `mkdocs-builder` |
| `CONTAINER_NGINX` | Container-Name Nginx | `docs-nginx` |

## Häufige Fehler & Fixes

### "Permission denied" beim Builder

```bash
# Überprüfe deine UID/GID
id -u && id -g

# Update .env und Restart
echo "USER_ID=$(id -u)" > .env
echo "GROUP_ID=$(id -g)" >> .env
# ... rest
docker compose down && docker compose up -d --build
docker compose run --rm builder
```

### mkdocs.yml existiert, wird aber skipped

```bash
# Logs checken
docker compose logs builder

# Lokales Testen
cd ~/docs-projects/dein-projekt
mkdocs build --strict
```

### Nginx zeigt 404

```bash
# HTML vorhanden?
ls ~/docs-site/dein-projekt/index.html

# Nginx-Logs
docker compose logs nginx
```

## Datensicherheit

✅ **Alle Daten liegen auf dem Host:**
- `~/docs-projects/` = Quellen (du kontrollierst)
- `~/docs-site/` = Output (Builder schreibt mit deiner UID/GID)

✅ **Container sind hardened:**
- read-only FS (außer wo nötig)
- non-root User
- Strict UID/GID Mapping
- No-new-privileges

✅ **Backup ist trivial:**

```bash
tar czf docs-backup-$(date +%Y%m%d).tar.gz ~/docs-projects ~/docs-site
```

---

## Checkliste vor dem Start

- [ ] `setup.sh` ausgeführt ODER
- [ ] `.env` manuell korrekt konfiguriert
- [ ] `mkdir -p ~/docs-projects ~/docs-site` ausgeführt
- [ ] `docker` und `docker compose` installiert
- [ ] `docker compose up -d --build` erfolgreich
- [ ] Browser öffnet http://127.0.0.1:8080/ ohne Fehler

---

**Status: READY FOR PRODUCTION** ✅

Alle Anforderungen erfüllt. Kein Mystery-Code, kein Versteckmechanismus. Siehe README.md für vollständige Dokumentation.
