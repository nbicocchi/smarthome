#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$BASE_DIR/backup"
RUNTIME_DIR="$BASE_DIR/runtime"
LATEST="$BACKUP_DIR/latest.zip"

echo "🏁 Avvio ripristino di runtime..."

# 1. Ferma i servizi Docker
echo "🛑 Arresto dei servizi Docker..."
"$SCRIPT_DIR/runtime-control.sh" stop || true

# 2. Sposta la cartella runtime esistente per sicurezza
if [ -d "$RUNTIME_DIR" ]; then
  BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"
  BACKUP_OLD="${RUNTIME_DIR}_old_$BACKUP_SUFFIX"
  echo "💾 Spostamento runtime corrente in $BACKUP_OLD..."
  mv "$RUNTIME_DIR" "$BACKUP_OLD"
fi

# 3. Ripristina da zip o esegui bootstrap da base_config
if [ -f "$LATEST" ]; then
  echo "📂 Estrazione file da $LATEST..."
  unzip -q "$LATEST" -d "$BASE_DIR"
  echo "✅ Ripristino da backup completato!"
else
  echo "⚠️ Nessun backup trovato in $LATEST. Inizializzazione da base_config..."
  for stack_dir in "$BASE_DIR/stacks"/*; do
    if [ -d "$stack_dir" ]; then
      config_dir="$stack_dir/base_config"
      if [ -d "$config_dir" ]; then
        mkdir -p "$RUNTIME_DIR"
        echo "  🚚 Copia dei file da base_config per $(basename "$stack_dir")..."
        cp -rn "$config_dir/"* "$RUNTIME_DIR/"
      fi
    fi
  done
  echo "✅ Inizializzazione minima completata!"
fi

echo "✨ Ripristino completato con successo!"