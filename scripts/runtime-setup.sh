#!/usr/bin/env bash
set -euo pipefail

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV_FILE="$ROOT_DIR/scripts/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ .env file not found at $ENV_FILE"
  exit 1
fi

# Load USER and GROUP variables from .env (fallback to PUID/PGID if present)
# shellcheck disable=SC1091
source "$ENV_FILE"

# Resolve user and group identifiers
if [[ -z "${USER:-}" && -n "${PUID:-}" ]]; then
  USER="$PUID"
fi
if [[ -z "${GROUP:-}" && -n "${PGID:-}" ]]; then
  GROUP="$PGID"
fi

if [[ -z "${USER:-}" || -z "${GROUP:-}" ]]; then
  echo "❌ USER and GROUP (or PUID/PGID) must be defined in .env"
  exit 1
fi

echo "🔧 Using USER=$USER GROUP=$GROUP"

STACKS_DIR="$ROOT_DIR/stacks"
if [[ ! -d "$STACKS_DIR" ]]; then
  echo "❌ Stacks directory not found at $STACKS_DIR"
  exit 1
fi

for stack_path in "$STACKS_DIR"/*/; do
  [ -d "$stack_path" ] || continue
  stack_name=$(basename "$stack_path")
  echo "🚀 Processing stack: $stack_name"

  if [[ "$stack_name" == "dockge" ]]; then
    echo "   ⚠️ Skipping dockge stack"
    continue
  fi

  # Copy .env into the stack root (so each stack can read its own config)
  cp "$ENV_FILE" "$stack_path/.env"

  compose_file="$stack_path/docker-compose.yml"
  if [[ -f "$compose_file" ]]; then
    # Extract host-side volume paths (left side of the colon) ignoring variable interpolation
    grep -E "^[[:space:]]*-[[:space:]]*[^:]+:[^:]+" "$compose_file" | while IFS= read -r line; do
      # Trim leading spaces and hyphen
      vol=$(echo "$line" | sed -E 's/^[[:space:]]*-?[[:space:]]*//')
      host_path=$(echo "$vol" | cut -d ':' -f1)
      # Skip empty or variable references
      if [[ -z "$host_path" || $host_path == \${*} ]]; then
        continue
      fi
      # Resolve relative paths (starting with ./ or ../)
      if [[ "$host_path" = ./* || "$host_path" = ../* ]]; then
        host_abs="$stack_path/$host_path"
      else
        host_abs="$host_path"
      fi

      # Skip file paths (simple heuristic: contains a dot)
      if [[ "$host_abs" == *.* ]]; then
        echo "   ⚠️ Skipping file volume $host_abs"
        continue
      fi

      # Create directory if needed
      if [[ ! -d "$host_abs" ]]; then
        echo "   📁 Creating volume directory $host_abs"
        mkdir -p "$host_abs"
      fi

      # Set ownership
      echo "   👤 Setting ownership of $host_abs to $USER:$GROUP"
      chown "$USER":"$GROUP" "$host_abs"
    done
  else
    echo "   ⚠️ No docker-compose.yml found in $stack_path"
  fi
done

echo "✅ runtime-setup completed."
