---
name: add-service
description: Add a new service to Traefik and Homepage, using SSH to auto-discover container info from the NAS.
---

Use this skill when the user asks to add a new service to Traefik and Homepage.

## Step 1 — SSH discovery (read-only)

Run this command to list running containers on the NAS:

```bash
ssh nas 'sudo docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"'
```

- If the user provided a service name (e.g. `/add-service mealie`), filter the output to lines matching that name.
- Extract the **host port** from the PORTS column (the number before `->`, e.g. `30111` from `0.0.0.0:30111->9000/tcp`).
- Use the container NAME as the `container:` value for the Homepage entry.
- If the PORTS column is empty or the user indicates the service is on Kubernetes, use `192.168.1.20` as the target host instead of the default.

This is purely informational — never run write operations via SSH.

## Step 2 — Confirm details

Using the discovery output to pre-fill suggestions, confirm any missing details with the user:

- **service name** — used for the file name, router name, and service ID
- **port** — host-side port from discovery, or user-provided
- **subdomain** — default: service name
- **base domain** — default: `punsvik.net` (alternative: `furuknappen.no`)
- **target host** — default: `192.168.1.4`; use `192.168.1.20` for K8s
- **internal-only** — default: no
- **Homepage category** — use an existing section from `services/homepage/services.yaml` when possible
- **Homepage display name, icon, and description**
- **container name** — from discovery; include only if available

## Step 3 — Create files

### Traefik dynamic config

Create `services/traefik/config/dynamic/<service>.yml`:

```yaml
# Traefik Dynamic Configuration - <Display Name> (<TrueNAS App | K8s>)
# Proxies <subdomain>.<domain> to <host> on port <port>

http:
  routers:
    <service>:
      rule: "Host(`<subdomain>.<domain>`)"
      entryPoints:
        - websecure
      service: <service>-svc
      tls:
        certResolver: le
      middlewares:
        - security-headers@file
        # - internal-only@file   # uncomment when internal-only

  services:
    <service>-svc:
      loadBalancer:
        passHostHeader: true
        servers:
          - url: "http://<host>:<port>"
```

Always include `security-headers@file`. Add `internal-only@file` (uncommented) only when the service is internal-only.

### Homepage entry

Append under the chosen category in `services/homepage/services.yaml`:

```yaml
- <Display Name>:
    icon: <icon>
    href: https://<subdomain>.<domain>
    description: <description>
    siteMonitor: https://<subdomain>.<domain>
    server: truenas       # include only if container is provided
    container: <container> # include only if discovered
```

## Notes

- **Blocky DNS**: `*.punsvik.net` and `*.furuknappen.no` are wildcard-mapped to `192.168.1.4` — no DNS changes are ever needed for new services on these domains.
- **Traefik hot-reload**: Dynamic config reloads automatically; no Traefik restart needed.
- **File naming**: lowercase with hyphens (e.g. `actual-budget.yml`).
- **YAML style**: Match indentation and structure of existing files in the same directory.
- Do not modify any files other than the two listed above.
