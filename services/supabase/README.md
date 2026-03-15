# Supabase — Shared Backend Infrastructure

Self-hosted Supabase instance shared across all apps. One Postgres database, one auth pool, multiple schemas (one per app).

- **Studio**: https://supabase.furuknappen.no (LAN only)
- **API**: https://api.furuknappen.no (public, used by app frontends)

## Architecture

```
supabase-kong  ──── supabase-auth    (GoTrue — JWT auth, user management)
(API gateway)  ──── supabase-rest    (PostgREST — auto REST API per schema)
               ──── supabase-storage (File storage, local filesystem)
               ──── supabase-meta    (DB admin API, used by Studio)

supabase-db    ──── supabase-storage
(PostgreSQL)   ──── supabase-auth
               ──── supabase-rest
               ──── supabase-meta

supabase-imgproxy    (image transforms for Storage)
supabase-studio      (dashboard — direct Traefik route, bypasses Kong)
```

All apps share one `auth.users` table. Data isolation is per-schema via Row Level Security.

## First-Time Setup

### 1. Create appdata directories (on TrueNAS)

```bash
ssh nas "mkdir -p /mnt/main/appdata/supabase/db"
ssh nas "mkdir -p /mnt/main/appdata/supabase/storage"
```

### 2. Generate secrets

```bash
# JWT secret
openssl rand -hex 32

# Postgres password
openssl rand -hex 16

# PG Meta crypto key (must be 32+ chars)
openssl rand -hex 32
```

For `ANON_KEY` and `SERVICE_ROLE_KEY`: go to https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys and follow the JWT generation steps using your `JWT_SECRET`.

### 3. Create the .env file

```bash
cp .env.example .env
# Edit .env with your generated values
```

### 4. Deploy via TrueNAS

Register as a custom app in TrueNAS pointing to this `compose.yml`, then start it:

```bash
ssh nas "midclt call 'app.start' '\"supabase\"'"
```

### 5. Verify

```bash
# Check all containers are healthy
ssh nas "docker ps --filter name=supabase"

# API health checks
curl https://api.furuknappen.no/auth/v1/health
curl https://api.furuknappen.no/storage/v1/status
curl https://api.furuknappen.no/rest/v1/ -H "apikey: <YOUR_ANON_KEY>"

# Open Studio in browser (LAN only)
# https://supabase.furuknappen.no
```

---

## Adding a New App Backend

Run these steps whenever you spin up a new app that needs a database backend.

### Step 1 — Create the schema

In Studio (Table Editor → SQL Editor) or via psql:

```sql
CREATE SCHEMA IF NOT EXISTS myapp;

GRANT USAGE ON SCHEMA myapp TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA myapp
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon, authenticated, service_role;
```

### Step 2 — Register schema with PostgREST

Edit `.env`:

```dotenv
PGRST_DB_SCHEMAS=public,myapp
```

Then restart via TrueNAS:

```bash
ssh nas "midclt call 'app.restart' '\"supabase\"'"
```

### Step 3 — Create tables with RLS

```sql
CREATE TABLE myapp.items (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name       text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE myapp.items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_own_rows" ON myapp.items
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Step 4 — Connect from the app

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://api.furuknappen.no',
  'YOUR_ANON_KEY',
  { db: { schema: 'myapp' } }
)

// Example: fetch rows
const { data, error } = await supabase.from('items').select('*')
```

The `db.schema` option automatically sends the correct `Accept-Profile: myapp` header. RLS ensures users only see their own rows.

---

## Operational Commands

```bash
# Check container status
ssh nas "docker ps --filter name=supabase"

# View logs for a specific container
ssh nas "docker logs supabase-rest --tail 50"
ssh nas "docker logs supabase-auth --tail 50"
ssh nas "docker logs supabase-kong --tail 50"
ssh nas "docker logs supabase-db --tail 50"

# Restart the entire stack
ssh nas "midclt call 'app.restart' '\"supabase\"'"

# Stop / start
ssh nas "midclt call 'app.stop' '\"supabase\"'"
ssh nas "midclt call 'app.start' '\"supabase\"'"

# Connect to Postgres directly
ssh nas "docker exec -it supabase-db psql -U supabase_admin -d postgres"
```

## File Layout

```
services/supabase/
├── compose.yml          Docker Compose stack (8 containers)
├── kong.yml             Kong API gateway declarative config
├── .env.example         Template — copy to .env and fill in secrets
├── .env                 Secrets (gitignored)
├── db-init/             Init SQL — runs once on first DB boot
│   ├── roles.sql        Sets passwords for Supabase DB roles
│   ├── jwt.sql          Sets JWT config on the DB
│   └── webhooks.sql     Creates supabase_functions schema
└── README.md            This file
```

Data lives at `/mnt/main/appdata/supabase/` (not in this repo):
- `db/` — PostgreSQL data files
- `storage/` — uploaded files (browsable via TrueNAS file manager)
