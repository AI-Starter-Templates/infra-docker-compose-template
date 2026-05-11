# Traefik (dev and prod)

This template follows the same **shape** as a long-running production setup: **Traefik v3** on `frontend` and `backend` Docker networks, **Docker provider** for labeled routers, optional **file provider** for dev-only routes to processes on the host, and a **production overlay** with HTTP to HTTPS redirect, **ACME HTTP-01**, and security middlewares on the API and UI services.

## Files

| File | Role |
| --- | --- |
| [compose/docker-compose.yml](../compose/docker-compose.yml) | Postgres, Redis, Traefik (profiles `dev` / `prod`), optional `api` + `ui` images for `prod` |
| [compose/docker-compose.development-labels.yml](../compose/docker-compose.development-labels.yml) | Dev: Traefik dashboard via Docker labels |
| [compose/docker-compose.production-labels.yml](../compose/docker-compose.production-labels.yml) | Prod: ACME, redirect, TLS routers + middlewares for `api` and `ui` |
| [compose/traefik/dynamic/dev.yml](../compose/traefik/dynamic/dev.yml) | Dev: HTTP routes to `host.docker.internal:3000` (API) and `:3001` (UI) |

## Dev stack (`STACK=dev`, default)

1. Copy [compose/.env.example](../compose/.env.example) to `compose/.env` (optional for defaults).
2. Start Postgres, Redis, and Traefik:

   ```bash
   ./scripts/compose-up.sh
   ```

3. Map hosts to the loopback interface if your OS needs it (examples):

   - `api.localhost`, `app.localhost`, `traefik.localhost` → `127.0.0.1`

4. Run **api-template** on port **3000** and **ui-template** on **3001** on the host (`bun dev`, `pnpm dev`). Traefik forwards:

   - `http://api.localhost` → API
   - `http://app.localhost` → UI
   - `http://traefik.localhost` → Traefik dashboard

**Linux:** `host.docker.internal` is wired via `extra_hosts: host-gateway` on the Traefik service. If your Docker version is older, add an explicit `extra_hosts` entry to the gateway IP.

## Prod-shaped stack (`STACK=prod`)

Builds **api** and **ui** from sibling [`api-template`](../api-template) / [`ui-template`](../ui-template) using `Dockerfile.prod`, wires **Let’s Encrypt** on `web` (HTTP-01), and terminates TLS on `websecure`.

1. Set in `compose/.env`:

   - `STACK=prod`
   - `PUBLIC_API_HOST`, `PUBLIC_UI_HOST` (real FQDNs)
   - `ACME_EMAIL` (contact for Let’s Encrypt)

2. Copy [compose/api.prod.env.example](../compose/api.prod.env.example) to `compose/api.prod.env` and fill every variable the API needs (JWT, CORS, OAuth, email, etc.). See api-template `.env.example`.

3. Start:

   ```bash
   STACK=prod ./scripts/compose-up.sh
   ```

4. Read [runbooks/single-host-firewall-and-tls.md](runbooks/single-host-firewall-and-tls.md) before locking the host behind Cloudflare-only origins, or HTTP-01 renewal will fail.

## Observability alongside Traefik

Optional Prometheus / Grafana uses Compose **profile** `observability`. Grafana is published on **host port 3010** so it does not collide with the UI dev server on 3001 or Traefik’s use of 80/443.

```bash
WITH_OBSERVABILITY=1 ./scripts/compose-up.sh
```

Stop with the same `WITH_OBSERVABILITY` and `STACK` values you used to start.

## Merge commands (reference)

Dev (what `compose/dev.sh` runs):

```text
docker compose -f docker-compose.yml -f docker-compose.development-labels.yml --profile dev up -d
```

Prod:

```text
docker compose -f docker-compose.yml -f docker-compose.production-labels.yml --profile prod up -d
```
