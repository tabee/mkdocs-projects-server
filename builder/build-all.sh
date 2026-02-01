#!/usr/bin/env bash
set -euo pipefail

PROJECTS="/home/mkdocs/work/projects"
OUT="/home/mkdocs/work/site"

mkdir -p "${OUT}"

mapfile -t PROJ_DIRS < <(find "${PROJECTS}" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#PROJ_DIRS[@]} -eq 0 ]]; then
  echo "⚠️  Keine Projekte unter ${PROJECTS} gefunden."
  echo "   Erstelle \${PROJECTS_DIR}/<projekt>/ mit mkdocs.yml"
  exit 0
fi

echo "🔨 Baue MkDocs Projekte..."
for dir in "${PROJ_DIRS[@]}"; do
  name="$(basename "${dir}")"
  cfg="${dir}/mkdocs.yml"

  if [[ ! -f "${cfg}" ]]; then
    echo "   ⊘ ${name} (kein mkdocs.yml)"
    continue
  fi

  echo "   → ${name}"
  rm -rf "${OUT:?}/${name}"
  mkdir -p "${OUT}/${name}"

  mkdocs build \
    --config-file "${cfg}" \
    --site-dir "${OUT}/${name}" \
    --clean \
    --strict
done

echo "✅ Fertig. Output: ${OUT}/"
ls -la "${OUT}/" | tail -n +2 | awk '{print "   " $NF " (" $5 " bytes)"}'
