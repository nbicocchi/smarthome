#!/usr/bin/env bash
set -euo pipefail

# =========================
# PATH SETUP
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$BASE_DIR/backup"
RUNTIME_DIR="$BASE_DIR/runtime"

MAX_BACKUPS="${MAX_BACKUPS:-5}"

# Override da CLI
if [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
  MAX_BACKUPS="$1"
fi

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="$BACKUP_DIR/runtime_$TIMESTAMP.zip"

# =========================
# START
# =========================

echo "📦 [$(date)] Avvio backup runtime..."

mkdir -p "$BACKUP_DIR"

if [[ ! -d "$RUNTIME_DIR" ]]; then
  echo "⚠️ Cartella runtime non trovata: $RUNTIME_DIR"
  exit 0
fi

# flush filesystem buffer (utile su storage lento / NAS)
sync

# =========================
# BACKUP CREATION
# =========================

echo "🗜️ Creazione archivio: $(basename "$BACKUP_FILE")"

python3 -c "
import shutil
shutil.make_archive('${BACKUP_FILE%.zip}', 'zip', '${BASE_DIR}', 'runtime')
"

echo "✅ Backup creato con successo"

# =========================
# LATEST LINK
# =========================

ln -sfn "$(basename "$BACKUP_FILE")" "$BACKUP_DIR/latest.zip"
echo "🔗 latest.zip aggiornato"

# =========================
# ROTATION
# =========================

shopt -s nullglob

# ordina dal più vecchio al più recente (IMPORTANTE)
mapfile -t BACKUPS < <(ls -1tr "$BACKUP_DIR"/runtime_*.zip 2>/dev/null || true)

shopt -u nullglob

NUM_BACKUPS=${#BACKUPS[@]}

if [[ "$NUM_BACKUPS" -eq 0 ]]; then
  echo "ℹ️ Nessun backup da gestire"
elif [[ "$NUM_BACKUPS" -gt "$MAX_BACKUPS" ]]; then
  LIMIT=$((NUM_BACKUPS - MAX_BACKUPS))

  echo "🧹 Rimozione $LIMIT backup più vecchi..."

  for ((i=0; i<LIMIT; i++)); do
    echo "  🗑️ Eliminazione: $(basename "${BACKUPS[i]}")"
    rm -f "${BACKUPS[i]}"
  done
else
  echo "✅ Rotazione OK ($NUM_BACKUPS/$MAX_BACKUPS)"
fi

# =========================
# END
# =========================

echo "🎉 Backup completato"
exit 0