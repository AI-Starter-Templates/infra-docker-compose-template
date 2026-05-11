# infrastructure-template

Docker Compose for **Postgres + Redis** plus **Traefik v3** (same layering style as a long-running single-VPS setup): dev routes to **api-template / ui-template on the host**, prod profile builds **API + UI images** and terminates TLS with **ACME**. Optional Prometheus / Grafana and runbooks live under [docs/](docs/).

Clone this repo as a sibling named `infra` next to `api-template` so the API quickstart path works:

```bash
(cd ../infra/compose && ./dev.sh)
```

If you use another folder name, adjust that path.

## Layout

| Path                 | Purpose                                                                   |
| -------------------- | ------------------------------------------------------------------------- |
| [compose/](compose/) | Base compose, Traefik dev/prod overlays, `dev.sh`, optional observability |
| [scripts/](scripts/) | Wrappers that honor `STACK` and `WITH_OBSERVABILITY`                      |
| [docs/](docs/)       | Traefik, runbooks, optional stacks                                        |

## Quickstart (dev: Traefik + DB + host apps)

```bash
cp compose/.env.example compose/.env   # defaults STACK=dev
chmod +x compose/dev.sh scripts/*.sh
# For STACK=prod only: copy compose/api.prod.env.example to compose/api.prod.env and fill it in.
./scripts/compose-up.sh
```

Traefik listens on **80** and **443**. With defaults, add to `/etc/hosts` (or use `.localhost` where your OS resolves it automatically):

- `api.localhost` → API on the host at port **3000**
- `app.localhost` → UI on the host at port **3001**
- `traefik.localhost` → Traefik dashboard

Stop (keep data):

```bash
./scripts/compose-down.sh
```

Stop and **delete** volumes:

```bash
./scripts/compose-down-clean.sh
```

If you started with observability:

```bash
WITH_OBSERVABILITY=1 ./scripts/compose-down.sh
```

## Prod profile (containers + ACME)

```bash
# compose/.env: STACK=prod, PUBLIC_API_HOST, PUBLIC_UI_HOST, ACME_EMAIL
# compose/api.prod.env: full API env (see api.prod.env.example)
STACK=prod ./scripts/compose-up.sh
```

Details: [docs/traefik.md](docs/traefik.md).

## Docs

- [Traefik dev vs prod](docs/traefik.md)
- [Security hardening checklist](docs/security-hardening.md)
- [Single-host firewall and TLS](docs/runbooks/single-host-firewall-and-tls.md)
- [Postgres backups and off-site sync](docs/backup-offsite.md) (encrypt, rclone, restore drills)
- [Optional observability (Prometheus / Grafana)](docs/observability-optional.md)
- [Optional GlitchTip (self-hosted errors)](docs/glitchtip-optional.md)

## License

MIT.
