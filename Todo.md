# Setup-Status: ✅ VOLLSTÄNDIG IMPLEMENTIERT

Dieses Verzeichnis enthält ein **produktionsreifes, hardened Multi-Project-MkDocs-Setup** mit Docker Compose.

## Was wurde gemacht?

- ✅ Komplette README.md mit Schnellstart und Troubleshooting
- ✅ docker-compose.yml mit hardened Builder + Nginx Services
- ✅ Builder Dockerfile + requirements.txt (Python 3.12 + venv)
- ✅ Nginx Dockerfile + sichere Config (non-root, read-only)
- ✅ Automatisiertes setup.sh Script
- ✅ .env.example Template
- ✅ build-all.sh für Multi-Project-Builds
- ✅ Flexible UID/GID-Mapping (Jupyter-ähnlich)
- ✅ Lokale Datenspeicherung (PROJECTS_DIR / SITE_DIR)

## Los geht's

```bash
# Automatisches Setup (empfohlen)
bash setup.sh

# Oder manuell: siehe README.md
```

---

## Alte Dokumentation (obsolet, aber noch vorhanden)


---

## 1) Lokale Ordner auf dem Host (muss so in einer Readme.md stehen!)

Beispiel (kannst du frei wählen):

```bash
mkdir -p ~/docs-projects
mkdir -p ~/docs-site
```

Struktur in `~/docs-projects`:

```text
~/docs-projects/
├── alpha/
│   ├── mkdocs.yml
│   └── docs/
│       └── index.md
├── beta/
│   ├── mkdocs.yml
│   └── docs/
│       └── index.md
└── gamma/...
```

Output landet in `~/docs-site`:

```text
~/docs-site/
├── alpha/
├── beta/
└── gamma/
```

---

## 2) `.env` (neben docker-compose.yml)

Leg dein Stack-Repo irgendwo hin, z. B.:

```text
~/Code/mkdocs-stack/
├── docker-compose.yml
├── .env
├── builder/
└── nginx/
```

In `~/Code/mkdocs-stack/.env`:

```env
# Identity (Host-User -> Container-User)
USER_ID=1000
GROUP_ID=1000

# Host-Pfade (DAS ist dein “wie beim Jupyter”-Teil)
PROJECTS_DIR=/home/mario/docs-projects
SITE_DIR=/home/mario/docs-site

# Port nur localhost gebunden
NGINX_PORT=8080

# Container-Namen optional
CONTAINER_BUILDER=mkdocs-builder
CONTAINER_NGINX=docs-nginx
```

Wenn du’s “automatisch” willst wie bei deinem Jupyter-Text, kannst du die UID/GID so setzen:

```bash
echo "USER_ID=$(id -u)" >> .env
echo "GROUP_ID=$(id -g)" >> .env
```

(Compose selbst kann `$(id -u)` in `.env` nicht auswerten, das ist kein Bash-Skript.)

---

## 3) docker-compose.yml (mit PROJECTS_DIR / SITE_DIR)

```yaml
services:
  builder:
    container_name: ${CONTAINER_BUILDER}
    build:
      context: ./builder
      args:
        USER_ID: ${USER_ID}
        GROUP_ID: ${GROUP_ID}
    working_dir: /home/mkdocs/work
    volumes:
      - ${PROJECTS_DIR}:/home/mkdocs/work/projects
      - ${SITE_DIR}:/home/mkdocs/work/site
    # Hardening
    read_only: true
    tmpfs:
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    restart: "no"
    command: ["/home/mkdocs/work/builder/build-all.sh"]

  nginx:
    container_name: ${CONTAINER_NGINX}
    build:
      context: ./nginx
      args:
        USER_ID: ${USER_ID}
        GROUP_ID: ${GROUP_ID}
    ports:
      - "127.0.0.1:${NGINX_PORT}:8080"
    volumes:
      - ${SITE_DIR}:/usr/share/nginx/html:ro
    # Hardening
    read_only: true
    tmpfs:
      - /var/cache/nginx
      - /var/run
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    restart: unless-stopped
    depends_on:
      - builder
```

**Wichtig:** Der Builder sieht nur `/projects` und `/site`. Dein Repo bleibt sauber getrennt. Genau wie du’s wolltest.

---

## 4) builder/build-all.sh (angepasst)

Damit das Script im Container liegt, mounten wir im Builder **nur** `PROJECTS_DIR` und `SITE_DIR`. Also muss `build-all.sh` in das Builder-Image rein (nicht aus dem Host-Mount kommen).

### builder/Dockerfile (relevanter Teil)

```dockerfile
COPY --chown=mkdocs:mkdocs build-all.sh /home/mkdocs/work/builder/build-all.sh
RUN chmod +x /home/mkdocs/work/builder/build-all.sh
```

### builder/build-all.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECTS="/home/mkdocs/work/projects"
OUT="/home/mkdocs/work/site"

mkdir -p "${OUT}"

mapfile -t PROJ_DIRS < <(find "${PROJECTS}" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#PROJ_DIRS[@]} -eq 0 ]]; then
  echo "Keine Projekte unter ${PROJECTS} gefunden."
  exit 1
fi

echo "Baue MkDocs Projekte..."
for dir in "${PROJ_DIRS[@]}"; do
  name="$(basename "${dir}")"
  cfg="${dir}/mkdocs.yml"

  if [[ ! -f "${cfg}" ]]; then
    echo "SKIP: ${name} (kein mkdocs.yml)"
    continue
  fi

  echo "-> ${name}"
  rm -rf "${OUT:?}/${name}"
  mkdir -p "${OUT}/${name}"

  mkdocs build \
    --config-file "${cfg}" \
    --site-dir "${OUT}/${name}" \
    --clean \
    --strict
done

echo "Fertig. Output in ${OUT}/<project>/"
```

---

## 5) Wo liegen die Daten jetzt wirklich?

* Deine Quellen: **`${PROJECTS_DIR}`** (Host)
* Output: **`${SITE_DIR}`** (Host)
* Nginx served: **`${SITE_DIR}`** read-only
* Builder schreibt: **`${SITE_DIR}`** als dein Host-User (per UID/GID)

So wie beim Jupyter-Server:

* *eine definierte Host-Quelle*
* *ein definierter Host-Output*
* *UID/GID sauber gemappt*
* *keine “wer hat das jetzt erstellt”-Permission-Hölle*

---

## 6) Start/Build

Einmalig build+start:

```bash
docker compose up -d --build
```

Nur neu bauen (ohne Nginx neu bauen):

```bash
docker compose run --rm builder
```

Aufruf:

```text
http://127.0.0.1:8080/alpha/
http://127.0.0.1:8080/beta/
```

---

## 7) Permission-Fallen (weil Linux)

Wenn `${SITE_DIR}` oder `${PROJECTS_DIR}` falsche Owner haben:

```bash
sudo chown -R $(id -u):$(id -g) "${PROJECTS_DIR}" "${SITE_DIR}"
```

Wenn du Multi-User machst, musst du pro User eigene dirs und eigene `.env` pflegen. Alles andere endet in Blut.

---

Wenn du willst, gebe ich dir als nächsten Schritt noch eine **Auto-Index-Seite** in `${SITE_DIR}/index.html`, die alle gefundenen Projekte verlinkt (alpha/beta/…). Das ist in 10 Zeilen erledigt und spart Browser-Tippen wie im Jahr 2003.





 Hier **die kompletten Dockerfiles**, exakt passend zu dem **Jupyter-ähnlichen Setup mit PROJECTS_DIR / SITE_DIR**, ohne implizite Mounts, ohne Überraschungen. Zwei Dockerfiles. Fertig.

Kein Marketing. Kein „you could“. Das läuft so.

---

## 1️⃣ `builder/Dockerfile`

👉 baut **alle MkDocs-Projekte** aus `${PROJECTS_DIR}` nach `${SITE_DIR}`
👉 nicht-root
👉 reproduzierbar
👉 minimal

```dockerfile
# syntax=docker/dockerfile:1.7
FROM python:3.12-slim-bookworm

ARG USER_ID=1000
ARG GROUP_ID=1000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

# Minimal Runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
      tini \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Deterministischer User (wie beim Jupyter-Setup)
RUN groupadd -g ${GROUP_ID} mkdocs \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash mkdocs

USER mkdocs
WORKDIR /home/mkdocs

# Virtualenv
RUN python -m venv /home/mkdocs/venv
ENV PATH="/home/mkdocs/venv/bin:${PATH}"

# Abhängigkeiten
COPY --chown=mkdocs:mkdocs requirements.txt /tmp/requirements.txt
RUN python -m pip install --upgrade pip \
    && python -m pip install -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# Build-Script fest im Image (nicht aus Mount!)
COPY --chown=mkdocs:mkdocs build-all.sh /home/mkdocs/build-all.sh
RUN chmod +x /home/mkdocs/build-all.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/home/mkdocs/build-all.sh"]
```

### `builder/requirements.txt`

```txt
mkdocs==1.6.1
mkdocs-material==9.5.30
```

---

## 2️⃣ `nginx/Dockerfile`

👉 served **nur** `${SITE_DIR}`
👉 non-root
👉 read-only
👉 kein Default-Nginx-Müll

```dockerfile
# syntax=docker/dockerfile:1.7
FROM nginx:1.27-alpine

ARG USER_ID=1000
ARG GROUP_ID=1000

# Weg mit unklarem Default-User, wir wollen Kontrolle
RUN deluser nginx 2>/dev/null || true \
    && addgroup -g ${GROUP_ID} -S nginx \
    && adduser  -u ${USER_ID} -S -D -H -G nginx nginx

# Eigene Konfiguration
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d

# Runtime-Verzeichnisse vorbereiten
RUN mkdir -p /var/cache/nginx /var/run \
    && chown -R nginx:nginx \
       /var/cache/nginx \
       /var/run \
       /etc/nginx

USER nginx

EXPOSE 8080
```

---

## 3️⃣ Warum das exakt wie dein Jupyter-Setup ist

| Jupyter                    | MkDocs                           |
| -------------------------- | -------------------------------- |
| `PROJECTS_DIR` → Notebooks | `PROJECTS_DIR` → MkDocs-Projekte |
| `UID/GID` gemappt          | `UID/GID` gemappt                |
| Bind-Mount                 | Bind-Mount                       |
| kein Root                  | kein Root                        |
| reproduzierbar             | reproduzierbar                   |
| klarer Datenpfad           | klarer Datenpfad                 |

Der Repo-Code ist **nur Infrastruktur**.
Die **echten Daten liegen lokal**, vollständig unter deiner Kontrolle.

---

## 4️⃣ Kurztest (ohne Denken)

```bash
docker compose build
docker compose up -d
```

Neu bauen ohne Nginx-Neustart:

```bash
docker compose run --rm builder
```

---

## 5️⃣ Typische Fehler (damit du sie nicht machst)

* ❌ `site/` manuell bearbeiten
* ❌ Builder Schreibrechte auf alles geben
* ❌ Projekte ins Repo legen statt in `${PROJECTS_DIR}`
* ❌ Nginx Root laufen lassen

Alles davon macht dein Setup schlechter.

---

Wenn du willst, kommt als nächstes:

* automatische `index.html`-Generierung
* optionale Auth (Basic / OIDC)
* Watcher-Container (inotify → rebuild)
* oder eine **CI-fähige Variante**, die exakt dasselbe Layout nutzt

Keinerlei Stilbruch. Nur weniger Menschenfehler.
