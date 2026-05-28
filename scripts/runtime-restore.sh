#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STACKS=("iot" "network" "media" "proxy")
BACKUP_DIR="$BASE_DIR/backups"
LATEST="$BACKUP_DIR/latest.tar.gz"

# --- Funzioni Docker ---
stop_docker() {
  echo "🛑 Stopping Docker services..."
  for stack in "${STACKS[@]}"; do
    if [ -f "$BASE_DIR/$stack/docker-compose.yml" ]; then
      echo "  Stopping stack: $stack"
      docker compose -f "$BASE_DIR/$stack/docker-compose.yml" down || true
    fi
  done
}

start_docker() {
  echo "🚀 Starting Docker services..."
  for stack in "${STACKS[@]}"; do
    if [ -f "$BASE_DIR/$stack/docker-compose.yml" ]; then
      echo "  Starting stack: $stack"
      docker compose -f "$BASE_DIR/$stack/docker-compose.yml" up -d
    fi
  done
}

# --- Funzione per il ripristino da Backup ---
restore_from_backup() {
  echo "📦 Backup found! Starting restoration content..."

  # Backup di sicurezza delle runtime attuali
  local backup_suffix="$(date +%Y%m%d_%H%M%S)"
  for stack in "${STACKS[@]}"; do
    local runtime_dir="$BASE_DIR/$stack/runtime"
    if [ -d "$runtime_dir" ]; then
      local backup_old="$BASE_DIR/$stack/runtime_old_$backup_suffix"
      echo "  💾 Moving current $stack runtime to $backup_old"
      mv "$runtime_dir" "$backup_old"
    fi
  done

  # Estrazione
  echo "📂 Extracting files from $LATEST..."
  tar -xzf "$LATEST" -C "$BASE_DIR"

  echo "✅ Restore from backup complete!"
}

# --- Funzione per il Bootstrap da Base Config ---
bootstrap_from_config() {
  echo "⚠️  No backup found at $LATEST."
  echo "📥 Initializing minimal systems from base_configs..."

  for stack in "${STACKS[@]}"; do
    local stack_dir="$BASE_DIR/$stack"
    local runtime_dir="$stack_dir/runtime"
    local config_dir="$stack_dir/base_config"

    if [ -d "$stack_dir" ]; then
      echo "🔧 Initializing stack: $stack"
      
      if [ -d "$runtime_dir" ]; then
        echo "  ✨ Runtime folder already exists for $stack, skipping creation."
      else
        mkdir -p "$runtime_dir"
      fi

      if [ -d "$config_dir" ]; then
        echo "  🚚 Copying files from base_config for $stack..."
        cp -rn "$config_dir/"* "$runtime_dir/"
      fi
    fi
  done
  echo "✅ Minimal systems ready!"
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