# infra-docker-compose-template

Docker Compose for **Postgres + Redis + Traefik v3** with separate dev / prod profiles, optional observability, error tracking, and ops overlays. **Dev** runs API + UI in containers with bind mounts for hot reload; **prod** builds production images and terminates TLS with ACME.

Clone this repo as a sibling of `api-template` and `ui-template` (same parent directory) so Compose build contexts resolve.

## Quickstart

```bash
cp compose/.env.example compose/.env       # defaults STACK=dev
chmod +x compose/dev.sh scripts/*.sh
./scripts/compose-up.sh                    # boot dev stack
```

First start runs `bun install` / `pnpm install` inside the API/UI containers (source is bind-mounted from your sibling repos). A one-shot **`api-migrate`** service applies the schema and seeds a demo user before the API starts.

Sign in at **http://localhost:3001** with **`demo@example.com`** / **`password123`**.

## Tasks

| Task | Command | Data preserved? |
|---|---|---|
| Start dev stack | `./scripts/compose-up.sh` | n/a |
| Stop, keep data | `./scripts/compose-down.sh` | ✅ |
| Stop and wipe data | `./scripts/compose-down-clean.sh` | ❌ (prompts; `CONFIRM=yes` to skip) |
| Start prod | `STACK=prod ./scripts/compose-up.sh` | n/a |
| With observability | `WITH_OBSERVABILITY=1 ./scripts/compose-up.sh` | n/a |
| With error tracking | `WITH_GLITCHTIP=1 ./scripts/compose-up.sh` | n/a |
| With queue dashboard | `WITH_BULLMQ=1 ./scripts/compose-up.sh` | n/a |
| With image-update bot | `WITH_WUD=1 ./scripts/compose-up.sh` | n/a |

Flags compose: `WITH_OBSERVABILITY=1 WITH_GLITCHTIP=1 ./scripts/compose-up.sh` brings up both overlays alongside the base stack.

## Service endpoints (dev)

All `*.localhost` hosts resolve to `127.0.0.1` automatically in every major browser — no `/etc/hosts` edit needed.

| URL | Service | Notes |
|---|---|---|
| http://localhost:3001 or http://app.localhost | UI (Vite dev server) | Traefik route + direct host port |
| http://localhost:3000 or http://api.localhost | API (Bun + Elysia) | Traefik route + direct host port |
| http://traefik.localhost | Traefik dashboard | dev only |
| postgresql://app:app_dev_password@localhost:5432/app | Postgres | dev only; not published in prod |
| redis://localhost:6379 | Redis | dev only; not published in prod |
| http://glitchtip.localhost | GlitchTip web UI | when `WITH_GLITCHTIP=1` |
| http://bullmq.localhost or http://localhost:3030 | BullMQ dashboard | when `WITH_BULLMQ=1` |
| http://localhost:3010 | Grafana | when `WITH_OBSERVABILITY=1` |

## Layout

| Path | Purpose |
|---|---|
| [compose/](compose/) | Base compose, dev/prod overlays, optional overlays (observability, glitchtip, bullmq, wud), `dev.sh` |
| [scripts/](scripts/) | Wrappers (`compose-up`, `compose-down`, `compose-down-clean`, backup, ufw, glitchtip-bootstrap) |
| [docs/](docs/) | Traefik, resource limits, security, backup, observability, GlitchTip, runbooks |

## Prod profile (containers + ACME)

```bash
# compose/.env: STACK=prod, PUBLIC_API_HOST, PUBLIC_UI_HOST, ACME_EMAIL
# compose/api.prod.env: full API env (see api.prod.env.example)
STACK=prod ./scripts/compose-up.sh
```

Details: [docs/traefik.md](docs/traefik.md).

## Docs

- [Traefik dev vs prod](docs/traefik.md)
- [Resource limits and sizing](docs/resource-limits.md)
- [Security hardening checklist](docs/security-hardening.md)
- [Single-host firewall and TLS](docs/runbooks/single-host-firewall-and-tls.md)
- [Cloudflare Email Service setup](docs/runbooks/cloudflare-email.md) — the api-template's default email provider
- [Postgres backups and off-site sync](docs/backup-offsite.md)
- [Optional observability](docs/observability-optional.md) (Prometheus / Grafana / Loki / Promtail)
- [GlitchTip (self-hosted error tracking)](docs/glitchtip.md)
- [Image update detection (WUD)](docs/image-update-detection.md)
- [PromQL cheatsheet](docs/promql-cheatsheet.md) · [LogQL cheatsheet](docs/logql-cheatsheet.md)

## License

MIT.
