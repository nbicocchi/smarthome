#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STACKS=("iot" "network" "media" "proxy")

usage() {
  echo "Usage: $0 {start|stop|restart|status}"
  exit 1
}

if [ $# -ne 1 ]; then
  usage
fi

ACTION="$1"

start_stacks() {
  echo "🚀 Starting all Docker stacks..."
  for stack in "${STACKS[@]}"; do
    if [ -f "$BASE_DIR/$stack/docker-compose.yml" ]; then
      echo "  Starting stack: $stack"
      docker compose -f "$BASE_DIR/$stack/docker-compose.yml" up -d
    fi
  done
}

stop_stacks() {
  echo "🛑 Stopping all Docker stacks..."
  for stack in "${STACKS[@]}"; do
    if [ -f "$BASE_DIR/$stack/docker-compose.yml" ]; then
      echo "  Stopping stack: $stack"
      docker compose -f "$BASE_DIR/$stack/docker-compose.yml" down
    fi
  done
}

status_stacks() {
  echo "📊 Checking status of all Docker stacks..."
  for stack in "${STACKS[@]}"; do
    if [ -f "$BASE_DIR/$stack/docker-compose.yml" ]; then
      echo "----------------------------------------"
      echo " Stack: $stack"
      echo "----------------------------------------"
      docker compose -f "$BASE_DIR/$stack/docker-compose.yml" ps
      echo ""
    fi
  done
}

case "$ACTION" in
  start|up)
    start_stacks
    ;;
  stop|down)
    stop_stacks
    ;;
  restart)
    stop_stacks
    start_stacks
    ;;
  status|ps)
    status_stacks
    ;;
  *)
    usage
    ;;
esac
