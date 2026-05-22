#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RUNTIME="$BASE_DIR/runtime"
BACKUP_DIR="$BASE_DIR/backups"
BASE_CONFIG="$BASE_DIR/base_config"
LATEST="$BACKUP_DIR/latest.tar.gz"

# --- Funzioni Docker ---
stop_docker() {
  echo "🛑 Stopping Docker services..."
  docker compose -f "$BASE_DIR/docker-compose.yml" down || true
}

start_docker() {
  echo "🚀 Starting Docker services..."
  docker compose -f "$BASE_DIR/docker-compose.yml" up -d
}

# --- Funzione per il ripristino da Backup ---
restore_from_backup() {
  echo "📦 Backup found! Starting restoration content..."

  # Backup di sicurezza della runtime attuale
  if [ -d "$RUNTIME" ]; then
    BACKUP_OLD="$BASE_DIR/runtime_old_$(date +%Y%m%d_%H%M%S)"
    echo "💾 Moving current runtime to $BACKUP_OLD"
    mv "$RUNTIME" "$BACKUP_OLD"
  fi

  # Estrazione
  mkdir -p "$RUNTIME"
  echo "📂 Extracting files from $LATEST..."
  tar -xzf "$LATEST" -C "$BASE_DIR"

  echo "✅ Restore from backup complete!"
}

# --- Funzione per il Bootstrap da Base Config ---
bootstrap_from_config() {
  echo "⚠️  No backup found at $LATEST."
  echo "📥 Initializing minimal system from base_config..."

  if [ -d "$RUNTIME" ]; then
    echo "✨ Runtime folder already exists, skipping creation."
  else
    mkdir -p "$RUNTIME/"
  fi

  if [ -d "$BASE_CONFIG/" ]; then
    echo "🚚 Copying files from base_config..."
    cp -rn "$BASE_CONFIG/"* "$RUNTIME/"
    echo "✅ Minimal system ready!"
  else
    echo "❌ Error: base_config directory not found at $BASE_CONFIG"
    exit 1
  fi
}

# --- Main Logic ---
echo "🏁 Initializing runtime restoration/setup..."

stop_docker

if [ -f "$LATEST" ]; then
  restore_from_backup
else
  bootstrap_from_config
fi

start_docker

echo ""
echo "✨ System is back online!"