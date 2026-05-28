#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Define our stacks
STACKS=("iot" "network" "media" "proxy")
BACKUP_DIR="$BASE_DIR/backups"

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="$BACKUP_DIR/runtime_$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Starting runtime backup..."

# Eseguiamo il backup dalla cartella base per percorsi relativi puliti
cd "$BASE_DIR"

# Raccogli le cartelle runtime esistenti
RUNTIMES=()
for stack in "${STACKS[@]}"; do
  if [ -d "$stack/runtime" ]; then
    RUNTIMES+=("$stack/runtime")
  fi
done

if [ ${#RUNTIMES[@]} -eq 0 ]; then
  echo "⚠️ No runtime folders found to backup!"
  exit 0
fi

echo "🗜️ Archiving: ${RUNTIMES[*]}"

tar -czf "$BACKUP_FILE" "${RUNTIMES[@]}"

echo "✅ Backup created: $BACKUP_FILE"

# salva ultimo backup come riferimento
ln -sfn "$BACKUP_FILE" "$BACKUP_DIR/latest.tar.gz"

echo "🔗 latest.tar.gz updated"