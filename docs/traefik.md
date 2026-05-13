# Traefik (dev and prod)

This template follows the same **shape** as a long-running production setup: **Traefik v3** on `frontend` and `backend` Docker networks, **Docker provider** for labeled routers, and a **production overlay** with HTTP to HTTPS redirect, **ACME HTTP-01**, and security middlewares on the API and UI services.

If you lock down **port 80** on the origin, HTTP-01 renewal can fail; prefer **DNS-01** for ACME in that case (see [single-host-firewall-and-tls.md](runbooks/single-host-firewall-and-tls.md)). Broader checklist: [security-hardening.md](security-hardening.md).

## Files

| File                                                                                              | Role                                                                                                |
| ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [compose/docker-compose.yml](../compose/docker-compose.yml)                                       | Postgres, Redis, Traefik (profiles `dev` / `prod`), `api-dev` / `ui-dev` (dev), `api` / `ui` (prod) |
| [compose/docker-compose.development-labels.yml](../compose/docker-compose.development-labels.yml) | Dev: Traefik dashboard + routers to **api-dev** and **ui-dev** containers                           |
| [compose/docker-compose.production-labels.yml](../compose/docker-compose.production-labels.yml)   | Prod: ACME, redirect, TLS routers + middlewares for `api` and `ui`                                  |

## Dev stack (`STACK=dev`, default)

1. Lay out **siblings**: `api-template`, `ui-template`, and `infra-docker-compose-template` under the same parent directory (Compose build contexts use `../../api-template` and `../../ui-template` from `compose/`).

2. Copy [compose/.env.example](../compose/.env.example) to `compose/.env` (optional for defaults).

3. Start Postgres, Redis, Traefik, **api-dev**, and **ui-dev**:

   ```bash
   ./scripts/compose-up.sh
   ```

4. Map hosts to the loopback interface if your OS needs it (examples):
   - `api.localhost`, `app.localhost`, `traefik.localhost` → `127.0.0.1`

5. Run **database migrations** from your local **api-template** clone (the API container does not auto-migrate):

   ```bash
   (cd ../api-template && bun run db:migrate)
   ```

6. Open:
   - `http://api.localhost` → API (Traefik → **api-dev**)
   - `http://app.localhost` → UI (Traefik → **ui-dev**; browser calls same-origin `/api` and `/auth`; Vite proxies those to **api-dev** via `VITE_API_PROXY_TARGET` inside the UI container)
   - `http://traefik.localhost` → Traefik dashboard

Optional: copy [compose/api.dev.env.example](../compose/api.dev.env.example) to `compose/api.dev.env` for extra API environment variables. Defaults for JWT and CORS live in `docker-compose.yml`; override with `API_DEV_*` entries in `compose/.env` if needed.

## Prod-shaped stack (`STACK=prod`)

Builds **api** and **ui** from sibling clones of **api-template** and **ui-template** (same parent directory as this repo) using `Dockerfile.prod`, wires **Let’s Encrypt** on `web` (HTTP-01), and terminates TLS on `websecure`.

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

Optional Prometheus / Grafana uses Compose **profile** `observability`. Grafana is published on **host port 3010** so it does not collide with Traefik’s use of 80/443 or the published UI dev port **3001**.

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
