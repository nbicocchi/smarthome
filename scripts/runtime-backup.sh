#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RUNTIME="$BASE_DIR/runtime"
BACKUP_DIR="$BASE_DIR/backups"

TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="$BACKUP_DIR/runtime_$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "📦 Starting runtime backup..."

# Eseguiamo il backup dalla cartella base per percorsi relativi puliti
cd "$BASE_DIR"

tar -czf "$BACKUP_FILE" \
  --exclude="runtime/homeassistant/home-assistant_v2.db" \
  --exclude="runtime/homeassistant/home-assistant_v2.db-shm" \
  --exclude="runtime/homeassistant/home-assistant_v2.db-wal" \
  --exclude="runtime/homeassistant/.cache" \
  --exclude="runtime/homeassistant/tts" \
  --exclude="runtime/homeassistant/deps" \
  --exclude="runtime/mosquitto/log" \
  --exclude="runtime/zigbee2mqtt/log" \
  --exclude="runtime/portainer/bin" \
  "runtime"

echo "✅ Backup created: $BACKUP_FILE"

# salva ultimo backup come riferimento
ln -sfn "$BACKUP_FILE" "$BACKUP_DIR/latest.tar.gz"

echo "🔗 latest.tar.gz updated"