#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$BASE_DIR/backup"
RUNTIME_DIR="$BASE_DIR/runtime"
MAX_BACKUPS="${MAX_BACKUPS:-5}"

# Se viene passato un numero come argomento, usalo come limite massimo
if [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
  MAX_BACKUPS="$1"
fi

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="$BACKUP_DIR/runtime_$TIMESTAMP.zip"

mkdir -p "$BACKUP_DIR"

echo "📦 Avvio backup di runtime..."

if [ ! -d "$RUNTIME_DIR" ]; then
  echo "⚠️ Nessuna cartella runtime trovata per il backup!"
  exit 0
fi

echo "🗜️ Compressione in corso: runtime -> $(basename "$BACKUP_FILE")"
# Usiamo python3 per creare lo zip poiché l'utility 'zip' non è installata sull'host
python3 -c "import shutil; shutil.make_archive('${BACKUP_FILE%.zip}', 'zip', '${BASE_DIR}', 'runtime')"

echo "✅ Backup creato con successo!"

# Aggiorna il link simbolico latest.zip
ln -sfn "$BACKUP_FILE" "$BACKUP_DIR/latest.zip"
echo "🔗 latest.zip aggiornato"

# Rotazione dei backup: conserva solo gli ultimi N
shopt -s nullglob
BACKUPS=("$BACKUP_DIR"/runtime_*.zip)
shopt -u nullglob

NUM_BACKUPS=${#BACKUPS[@]}
if [ "$NUM_BACKUPS" -gt "$MAX_BACKUPS" ]; then
  LIMIT=$((NUM_BACKUPS - MAX_BACKUPS))
  echo "🧹 Pulizia: rimozione dei $LIMIT backup più vecchi..."
  for ((i=0; i<LIMIT; i++)); do
    echo "  Eliminazione: $(basename "${BACKUPS[i]}")"
    rm -f "${BACKUPS[i]}"
  done
else
  echo "✅ Numero di backup ($NUM_BACKUPS) entro il limite ($MAX_BACKUPS)."
fi