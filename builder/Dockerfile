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
      inotify-tools \
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

# Build-Scripts fest im Image (nicht aus Mount!)
COPY --chown=mkdocs:mkdocs build-all.sh /home/mkdocs/build-all.sh
COPY --chown=mkdocs:mkdocs watch-and-build.sh /home/mkdocs/watch-and-build.sh
RUN chmod +x /home/mkdocs/build-all.sh /home/mkdocs/watch-and-build.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/home/mkdocs/watch-and-build.sh"]
