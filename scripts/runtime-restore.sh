#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STACKS=("iot" "management" "media" "monitoring" "proxy")
BACKUP_DIR="$BASE_DIR/backup"
RUNTIME_DIR="$BASE_DIR/runtime"
LATEST="$BACKUP_DIR/latest.tar.gz"

# --- Funzioni Docker ---
get_compose_file() {
  local stack="$1"
  local stack_dir="$BASE_DIR/stacks/$stack"
  if [ -f "$stack_dir/docker-compose.yml" ]; then
    echo "$stack_dir/docker-compose.yml"
  elif [ -f "$stack_dir/docker-compose.yaml" ]; then
    echo "$stack_dir/docker-compose.yaml"
  fi
}

stop_docker() {
  echo "🛑 Stopping Docker services..."
  for stack in "${STACKS[@]}"; do
    local compose_file
    compose_file=$(get_compose_file "$stack")
    if [ -n "$compose_file" ]; then
      echo "  Stopping stack: $stack"
      docker compose -f "$compose_file" down || true
    fi
  done
}

start_docker() {
  echo "🚀 Starting Docker services..."
  for stack in "${STACKS[@]}"; do
    local compose_file
    compose_file=$(get_compose_file "$stack")
    if [ -n "$compose_file" ]; then
      echo "  Starting stack: $stack"
      docker compose -f "$compose_file" up -d
    fi
  done
}

# --- Funzione per il ripristino da Backup ---
restore_from_backup() {
  echo "📦 Backup found! Starting restoration content..."

  # Backup di sicurezza delle runtime attuali
  local backup_suffix="$(date +%Y%m%d_%H%M%S)"
  if [ -d "$RUNTIME_DIR" ]; then
    local backup_old="${RUNTIME_DIR}_old_$backup_suffix"
    echo "  💾 Moving current runtime to $backup_old"
    mv "$RUNTIME_DIR" "$backup_old"
  fi

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
    local stack_dir="$BASE_DIR/stacks/$stack"
    local config_dir="$stack_dir/base_config"

    if [ -d "$stack_dir" ]; then
      echo "🔧 Initializing stack: $stack"

      if [ -d "$config_dir" ]; then
        mkdir -p "$RUNTIME_DIR"
        echo "  🚚 Copying files from base_config for $stack..."
        cp -rn "$config_dir/"* "$RUNTIME_DIR/"
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