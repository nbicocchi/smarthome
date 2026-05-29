#!/usr/bin/env bash
set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$BASE_DIR/backup"
RUNTIME_DIR="$BASE_DIR/runtime"

# Default number of backups to keep (can be overridden by MAX_BACKUPS env var)
MAX_BACKUPS="${MAX_BACKUPS:-5}"

usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -n, --max-backups N    Number of old backups to keep (default: 5, min: 1)"
  echo "  -h, --help             Show this help message"
  exit 1
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--max-backups)
      if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
        MAX_BACKUPS="$2"
        shift 2
      else
        echo "Error: -n/--max-backups requires a positive integer argument." >&2
        usage
      fi
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate MAX_BACKUPS
if [[ ! "$MAX_BACKUPS" =~ ^[0-9]+$ ]] || [[ "$MAX_BACKUPS" -lt 1 ]]; then
  echo "Error: MAX_BACKUPS must be a positive integer >= 1." >&2
  exit 1
fi

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="$BACKUP_DIR/runtime_$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Starting runtime backup..."

if [ ! -d "$RUNTIME_DIR" ]; then
  echo "⚠️ No runtime folder found to backup!"
  exit 0
fi

echo "🗜️ Archiving: runtime"

# Eseguiamo il backup dalla cartella base per percorsi relativi puliti
cd "$BASE_DIR"
tar -czf "$BACKUP_FILE" "runtime"

echo "✅ Backup created: $BACKUP_FILE"

# salva ultimo backup come riferimento
ln -sfn "$BACKUP_FILE" "$BACKUP_DIR/latest.tar.gz"

echo "🔗 latest.tar.gz updated"

# Rotation logic: keep only the most recent N backups
echo "🧹 Cleaning up old backups (keeping maximum $MAX_BACKUPS)..."

shopt -s nullglob
BACKUPS=("${BACKUP_DIR}"/runtime_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].tar.gz)
shopt -u nullglob

NUM_BACKUPS=${#BACKUPS[@]}

if [ "$NUM_BACKUPS" -gt "$MAX_BACKUPS" ]; then
  LIMIT=$((NUM_BACKUPS - MAX_BACKUPS))
  echo "🗑️ Found $NUM_BACKUPS backups. Deleting oldest $LIMIT backup(s)..."
  for ((i=0; i<LIMIT; i++)); do
    echo "  Deleting: $(basename "${BACKUPS[i]}")"
    rm -f "${BACKUPS[i]}"
  done
else
  echo "✅ Backup count ($NUM_BACKUPS) is within limit ($MAX_BACKUPS)."
fi