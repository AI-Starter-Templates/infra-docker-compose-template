#!/usr/bin/env bash
# Example backup wrapper: copy to backup-wrapper.sh, chmod +x, customize paths and keys.
# Do not commit real keys or rclone remotes to git.

set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/path/to/infra-docker-compose-template/compose}"
cd "$COMPOSE_DIR"

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

: "${POSTGRES_USER:?}"
: "${POSTGRES_DB:?}"
: "${RCLONE_REMOTE_NAME:?}"
: "${RCLONE_REMOTE_PATH:?}"

TS="$(date +%Y%m%d%H%M%S)"
WORKDIR="${TMPDIR:-/tmp}"
DUMP="$WORKDIR/db_backup_${TS}.sql.gz"

log() { echo "[$(date)] $*"; }

log "Starting pg_dump"
docker compose exec -T postgres \
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" | gzip > "$DUMP"

# Optional: encrypt before upload (uncomment and set AGE_PUBLIC_KEY or use gpg)
# age -r "$AGE_PUBLIC_KEY" -o "${DUMP}.age" "$DUMP" && rm -f "$DUMP" && DUMP="${DUMP}.age"

log "Uploading with rclone"
rclone copy "$DUMP" "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" --checksum --progress

log "Removing local artifact"
rm -f "$DUMP"

log "Done"
