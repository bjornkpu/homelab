# Vikunja

Open-source task manager. https://vikunja.io/docs/full-docker-example/

Routed at https://tasks.punsvik.net, gated by Pocket ID forward-auth.

## Search backend

Uses **ParadeDB** instead of plain Postgres — a drop-in Postgres replacement
with an embedded BM25 search extension. Vikunja auto-detects it and enables
enhanced search; no extra configuration required.

## First-run

### 1. Register the OIDC client in Pocket ID

At https://auth.punsvik.net → **OIDC Clients** → **Add OIDC Client**:

- **Name:** Vikunja
- **Callback URL:** `https://tasks.punsvik.net/auth/openid/pocketid`
- **Public Client:** off (confidential)

Save, then copy the **Client ID** and **Client Secret** into
`services/vikunja/.env` (`OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`) and restart:

```bash
ssh nas 'midclt call -j app.restart "\"vikunja\""'
```

### 2. Create your Vikunja user

Visit https://tasks.punsvik.net and click **Sign in with Pocket ID**. The first
sign-in auto-creates a local Vikunja account linked to your Pocket ID identity.

Optionally disable local-password registration (everyone uses Pocket ID
afterwards) by adding `VIKUNJA_SERVICE_ENABLEREGISTRATION: "false"` to
`environment:` in `compose.yml` and restarting.

## Update

```bash
# Optionally bump VIKUNJA_IMAGE_TAG / PARADEDB_IMAGE_TAG in .env first
ssh nas 'midclt call -job app.update "\"vikunja\""'
```

## Storage layout

- `/mnt/main/appdata/vikunja/files` — uploaded files (owned by UID 1000)
- `/mnt/main/appdata/vikunja/db` — ParadeDB data
