#!/usr/bin/env bash
set -euo pipefail

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Verify that .env exists at project root
if [[ ! -f "$ROOT/.env" ]]; then
  echo "❌ .env file not found at $ROOT/.env"
  exit 1
fi

# Iterate over each stack directory and create/update symlink
for stack_dir in "$ROOT/stacks"/*; do
  if [[ -d "$stack_dir" ]]; then
    target_link="$stack_dir/.env"
    # Remove existing file if it's not a symlink
    if [[ -e "$target_link" && ! -L "$target_link" ]]; then
      rm -f "$target_link"
    fi
    ln -sf "$ROOT/.env" "$target_link"
    echo "✅ Linked $target_link -> $ROOT/.env"
  fi
done
