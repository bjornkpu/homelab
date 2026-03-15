# Solidtime

Open-source time tracker. https://docs.solidtime.io/self-hosting/guides/docker

## First-run setup

```bash
# 1. Generate app keys and paste output into laravel.env
docker compose run --rm solidtime php artisan self-host:generate-keys

# 2. Start containers (runs migrations automatically)
docker compose up -d

# 3. Create your user
docker compose exec solidtime php artisan admin:user:create "Firstname Lastname" "email@example.com" --verify-email
# Then restart so SUPER_ADMINS takes effect if set in laravel.env
docker compose down && docker compose up -d
```

## Optional: Activate Desktop client access

```bash
docker compose exec solidtime php artisan passport:client --name=desktop --redirect_uri=solidtime://oauth/callback --public -n
```

Note the client ID — enter it in the solidtime Desktop app under Instance Settings.

## Optional: Activate Browser Extension access

```bash
docker compose exec solidtime php artisan passport:client --name=browser-extension --redirect_uri=https://3369f72567118d8c03fb34880e9d6378d3b0c569.extensions.allizom.org/,https://hpanifeankiobmgbemnhjmhpjeebdhdd.chromiumapp.org/ --public -n
```

Note the client ID — enter it in the extension settings.

- [Chrome Web Store](https://chrome.google.com/webstore)
- [Firefox Add-ons](https://addons.mozilla.org)

## Optional: Activate API token access (for integrations)

```bash
docker compose exec solidtime php artisan passport:client --personal --name="API"
```

Only needs to be run once. Users can then create API tokens in their user settings.

## Update

```bash
# Optionally bump SOLIDTIME_IMAGE_TAG in .env first
docker compose pull
docker compose up -d
```
