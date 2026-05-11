# Optional observability (Prometheus + Grafana + Alertmanager)

The base stack already runs **Traefik** on ports **80** and **443**. The observability overlay is a **separate Compose profile** so it stays optional.

## What you get

- **Prometheus** on [http://localhost:9090](http://localhost:9090)
- **Grafana** on [http://localhost:3010](http://localhost:3010) (mapped away from **3000** so it does not clash with the Traefik file-provider path to the UI on **3001** in dev, or with other tools)
- **Alertmanager** on [http://localhost:9093](http://localhost:9093)

## Start

From repo root (works with `STACK=dev` or `STACK=prod`):

```bash
WITH_OBSERVABILITY=1 ./scripts/compose-up.sh
```

Compose passes **`--profile observability`** in addition to `dev` or `prod`.

Set `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` in `compose/.env` before exposing Grafana beyond localhost.

## Stop

Use the same `STACK` and `WITH_OBSERVABILITY` you used to start:

```bash
WITH_OBSERVABILITY=1 ./scripts/compose-down.sh
```

`compose-down-clean.sh` removes **all** volumes (Postgres, Redis, Grafana, Prometheus, Let’s Encrypt if present).

## Going further

- **Loki / Promtail** for logs: see Grafana’s [Loki docker examples](https://grafana.com/docs/loki/latest/installation/docker/).
- **Kubernetes:** use your Kustomize stack for cluster-wide scraping instead of this Compose overlay.
