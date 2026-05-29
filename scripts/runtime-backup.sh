#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$BASE_DIR/backup"
RUNTIME_DIR="$BASE_DIR/runtime"

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