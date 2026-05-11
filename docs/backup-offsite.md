# Postgres backups and off-site sync

Pattern for taking **logical dumps** from the running Postgres container and copying them to **object storage** (S3-compatible, Google Drive via rclone, etc.). Values below are placeholders; do not commit real credentials.

## One-off dump (Compose service name `postgres`)

From the `compose/` directory, with the stack running:

```bash
source .env   # or export POSTGRES_* yourself
DUMP="/tmp/db_backup_$(date +%Y%m%d%H%M%S).sql.gz"
docker compose exec -T postgres \
  pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "$DUMP"
ls -la "$DUMP"
```

Restore (destructive; test on a copy first):

```bash
gunzip -c "$DUMP" | docker compose exec -T postgres \
  psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
```

## Off-site copy (rclone example)

1. Install [rclone](https://rclone.org/) on the host (or run upload from a trusted CI runner that receives the artifact).
2. Configure a remote interactively: `rclone config`. Store config outside git (for example `~/.config/rclone/rclone.conf` with `chmod 600`).
3. Upload:

```bash
export RCLONE_REMOTE_NAME="myremote"      # name from rclone config
export RCLONE_REMOTE_PATH="backups/db"    # folder in the remote
rclone copy "$DUMP" "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" --progress
rm -f "$DUMP"   # optional: remove local file after verified upload
```

Use **application credentials** or **scoped keys** for the remote. Rotate keys if they ever leak.

## Cron (example)

Run daily at 02:30 as a dedicated user:

```cron
30 2 * * * cd /path/to/infra/compose && /path/to/backup-wrapper.sh >> /var/log/db-backup.log 2>&1
```

`backup-wrapper.sh` should: load env, run `pg_dump` as above, `rclone copy`, check exit codes, and alert on failure (email, Slack webhook, or metrics).

## What not to do

- Do not commit `rclone` remotes with **client secrets** or **refresh tokens** into a template repo.
- Do not expose Postgres **5432** to `0.0.0.0/0` unless you have a strong network ACL in front and a clear reason.
