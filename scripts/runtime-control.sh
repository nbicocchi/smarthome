#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STACKS=("iot" "management" "media" "monitoring" "proxy")

usage() {
  echo "Usage: $0 {start|stop|restart|status}"
  exit 1
}

if [ $# -ne 1 ]; then
  usage
fi

ACTION="$1"

get_compose_file() {
  local stack="$1"
  local stack_dir="$BASE_DIR/stacks/$stack"
  if [ -f "$stack_dir/docker-compose.yml" ]; then
    echo "$stack_dir/docker-compose.yml"
  elif [ -f "$stack_dir/docker-compose.yaml" ]; then
    echo "$stack_dir/docker-compose.yaml"
  fi
}

start_stacks() {
  echo "🚀 Starting all Docker stacks..."
  for stack in "${STACKS[@]}"; do
    local compose_file
    compose_file=$(get_compose_file "$stack")
    if [ -n "$compose_file" ]; then
      echo "  Starting stack: $stack"
      docker compose -f "$compose_file" up -d
    fi
  done
}

stop_stacks() {
  echo "🛑 Stopping all Docker stacks..."
  for stack in "${STACKS[@]}"; do
    local compose_file
    compose_file=$(get_compose_file "$stack")
    if [ -n "$compose_file" ]; then
      echo "  Stopping stack: $stack"
      docker compose -f "$compose_file" down
    fi
  done
}

status_stacks() {
  echo "📊 Checking status of all Docker stacks..."
  for stack in "${STACKS[@]}"; do
    local compose_file
    compose_file=$(get_compose_file "$stack")
    if [ -n "$compose_file" ]; then
      echo "----------------------------------------"
      echo " Stack: $stack"
      echo "----------------------------------------"
      docker compose -f "$compose_file" ps
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
