# homelab

Self-hosted services for my personal homelab on TrueNAS.

## Services

- **Traefik** - Reverse proxy with Let's Encrypt
- **Blocky** - DNS ad-blocker
- **Homepage** - Dashboard

## Add Custom app to TrueNAS

Name: <service>

custom config
```yml
include:
  - /mnt/main/homelab/services/<service>/compose.yml
```