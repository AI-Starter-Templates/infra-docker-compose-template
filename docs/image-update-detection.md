# Image update detection (WUD)

[**WUD (What's Up Docker)**](https://getwud.github.io/wud/) watches every running container and notifies when a newer image tag becomes available — without auto-patching anything. You stay in the loop, you decide when to bump.

## Why notify-only

WUD supports auto-patching `docker-compose.yml`, but that's a footgun in a starter template:
- Surprise restarts in the middle of the night.
- A breaking patch release silently rolling into prod.
- Compose file edits muddying your git history.

This overlay deliberately mounts the docker socket read-only and **omits** the auto-patch trigger config. You get notifications, you do the bump.

## Setup

1. Optional but recommended — a Discord channel + incoming webhook:
   - Server settings → Integrations → Webhooks → New Webhook → copy URL.
2. Add to `compose/.env`:
   ```env
   WUD_DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
   # WUD_SCHEDULE="0 */6 * * *"  # every 6h (default)
   # If you watch private GHCR images:
   # WUD_GHCR_USERNAME=your-gh-username
   # WUD_GHCR_TOKEN=ghp_xxx       # PAT with read:packages
   ```
3. Boot the overlay:
   ```bash
   WITH_WUD=1 ./scripts/compose-up.sh
   ```

## Where to look

- **Dashboard** — http://localhost:3033 lists every container and the newest available tag. Even without Discord, this is the primary surface.
- **Discord** — when a newer tag is detected, WUD posts a card with the container, current tag, and the new tag.

## When you act on a notification

1. Read the upstream image's release notes / changelog.
2. Bump the tag in `compose/docker-compose.yml` (or in the overlay that owns the image).
3. `./scripts/compose-up.sh` re-pulls the new image and recreates the container.
4. Verify health: `docker compose ps` + your usual smoke checks.

## What WUD does NOT do

- It does not pull images preemptively — it only queries registries for tag metadata.
- It does not modify any file by default (in this configuration).
- It does not restart containers.

## Costs / footprint

- Memory limit: 256M (override via `WUD_LIMITS_MEMORY`).
- Docker socket access is **read-only** — WUD can list containers and inspect images but cannot start/stop/modify them.
- Hits registries on the schedule you configure; default every 6h. Don't crank this below every 30m unless you really need it.

## Disable

```bash
# stop just the WUD overlay:
WITH_WUD=1 ./scripts/compose-down.sh

# or omit WITH_WUD on the next up to drop it:
./scripts/compose-up.sh
```

Related: [security-hardening.md](security-hardening.md) for other operational concerns.
