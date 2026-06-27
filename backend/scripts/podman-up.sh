#!/usr/bin/env bash
# Start Nexus backend with Podman Compose
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$BACKEND_DIR"

PROFILE_ARGS=()
if [[ "${1:-}" == "--with-db" ]]; then
  PROFILE_ARGS=(--profile with-db)
  shift
elif [[ "${1:-}" == "--full" ]]; then
  PROFILE_ARGS=(--profile with-db --profile with-cache)
  shift
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

if command -v podman >/dev/null 2>&1 && podman compose version >/dev/null 2>&1; then
  podman compose -f podman-compose.yml "${PROFILE_ARGS[@]}" up -d --build "$@"
elif command -v podman-compose >/dev/null 2>&1; then
  # Legacy podman-compose (no profiles — starts API only unless you extend the file)
  podman-compose -f podman-compose.yml up -d --build "$@"
else
  echo "Install Podman: brew install podman" >&2
  exit 1
fi

echo ""
echo "API: http://127.0.0.1:${NEXUS_API_PORT:-8848}/api/health"
echo "Test: curl http://127.0.0.1:${NEXUS_API_PORT:-8848}/api/health"
