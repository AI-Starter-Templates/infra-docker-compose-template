# infra-docker-compose-template

Docker Compose for **Postgres + Redis + Traefik v3** with dev / prod profiles and opt-in overlays for observability, error tracking, queue dashboards, and image-update detection. Part of [BoringStack](https://boringstack.xyz).

Clone this repo as a sibling of `api-template` and `ui-template` (same parent directory) so the Compose build contexts resolve.

## Run locally

```bash
cp compose/.env.example compose/.env
chmod +x compose/dev.sh scripts/*.sh
./scripts/compose-up.sh                    # boot dev stack
```

First start runs migrations and seeds a demo user. Sign in at **http://localhost:3001** with `demo@example.com` / `password123`.

## Overlays

```bash
WITH_OBSERVABILITY=1 ./scripts/compose-up.sh    # + Prometheus / Grafana / Loki / Promtail
WITH_GLITCHTIP=1     ./scripts/compose-up.sh    # + self-hosted error tracking
WITH_BULLMQ=1        ./scripts/compose-up.sh    # + BullMQ dashboard
WITH_WUD=1           ./scripts/compose-up.sh    # + image-update detection (Discord webhook)
STACK=prod           ./scripts/compose-up.sh    # production: built images, HTTPS, ACME
```

Flags compose freely.

## Full docs

The [infra overview](https://boringstack.xyz/infra/overview/) covers the service inventory, the profile/overlay model, [resource limits](https://boringstack.xyz/infra/resource-limits/), and [secrets](https://boringstack.xyz/infra/secrets/). The runbooks for [firewall + TLS](https://boringstack.xyz/runbooks/firewall-and-tls/), [backups](https://boringstack.xyz/runbooks/backups/), [Cloudflare Email setup](https://boringstack.xyz/runbooks/cloudflare-email-setup/), and [image updates](https://boringstack.xyz/runbooks/image-updates/) live alongside.

The `docs/` folder in this repo is the canonical source for now; the docs site is being progressively promoted from those files.

## License

MIT.
