# homelab

Self-hosted services on TrueNAS SCALE. Traefik fronts everything with Let's Encrypt TLS; services are either TrueNAS Apps store installs or Custom Compose apps included from this repo.

## Layout

| Path | Purpose |
|---|---|
| `services/<name>/compose.yml` | Custom Compose services |
| `services/traefik/config/dynamic/<name>.yml` | Per-service Traefik routes (hot-reload) |
| `services/homepage/services.yaml` | Dashboard tiles |
| `services/blocky/config.yml` | LAN DNS (wildcard `*.punsvik.net`, `*.furuknappen.no`) |

## What's deployed

```bash
ssh nas 'midclt call app.query "[]"'
```

## Add a service

Register a Custom Compose app in the TrueNAS UI **once** with this config:

```yaml
include:
  - /mnt/main/homelab/services/<service>/compose.yml
```

Iterate locally; pick up changes with:

```bash
ssh nas 'midclt -t 300 call -j app.redeploy "\"<service>\""'
```
