#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

ENV_FILE="${ENV_FILE:-$ROOT/.env}"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

STACK="${STACK:-dev}"
COMPOSE_FILES=(-f "$ROOT/docker-compose.yml")
PROFILE_ARGS=()

case "$STACK" in
  dev)
    COMPOSE_FILES+=(-f "$ROOT/docker-compose.development-labels.yml")
    PROFILE_ARGS+=(--profile dev)
    ;;
  prod)
    COMPOSE_FILES+=(-f "$ROOT/docker-compose.production-labels.yml")
    PROFILE_ARGS+=(--profile prod)
    ;;
  *)
    echo "[ERROR] STACK must be \"dev\" or \"prod\" (got: ${STACK})" >&2
    exit 1
    ;;
esac

if [[ "${WITH_OBSERVABILITY:-0}" == "1" && -f "$ROOT/docker-compose.observability.yml" ]]; then
  COMPOSE_FILES+=(-f "$ROOT/docker-compose.observability.yml")
  PROFILE_ARGS+=(--profile observability)
fi

if [[ "${WITH_GLITCHTIP:-0}" == "1" && -f "$ROOT/docker-compose.glitchtip.yml" ]]; then
  COMPOSE_FILES+=(-f "$ROOT/docker-compose.glitchtip.yml")
  PROFILE_ARGS+=(--profile "glitchtip-${STACK}")
  # In prod, layer the GlitchTip prod labels (HTTPS + Basic Auth + CORS).
  if [[ "$STACK" == "prod" && -f "$ROOT/docker-compose.glitchtip-prod-labels.yml" ]]; then
    COMPOSE_FILES+=(-f "$ROOT/docker-compose.glitchtip-prod-labels.yml")
  fi
fi

if [[ "${WITH_BULLMQ:-0}" == "1" && "$STACK" == "dev" && -f "$ROOT/docker-compose.bullmq.yml" ]]; then
  COMPOSE_FILES+=(-f "$ROOT/docker-compose.bullmq.yml")
  PROFILE_ARGS+=(--profile bullmq)
fi

if [[ "${WITH_WUD:-0}" == "1" && -f "$ROOT/docker-compose.wud.yml" ]]; then
  COMPOSE_FILES+=(-f "$ROOT/docker-compose.wud.yml")
  PROFILE_ARGS+=(--profile wud)
fi

if [[ $# -eq 0 ]]; then
  set -- up -d
fi

exec docker compose "${COMPOSE_FILES[@]}" "${PROFILE_ARGS[@]}" "$@"
