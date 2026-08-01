# Pingvin Share X

Self-hosted WeTransfer alternative at **https://share.punsvik.net**.

Upload files → get a link with an expiry date, optional password, and an
optional max-download count. Also supports **reverse shares**: you generate a
link, send it to someone else, and *they* upload to you.

Upstream: [smp46/pingvin-share-x](https://github.com/smp46/pingvin-share-x) — the
maintained fork of `stonith404/pingvin-share`, which was archived 2026-05-18 when
its author moved to Pocket ID full-time.

## Why this one is public

Unlike most services here it has **no `internal-only@file` middleware** — share
links have to open for people outside the LAN. Access control is at the app
layer instead: registration disabled, login required to upload, download links
anonymous.

`rate-limit@file` is deliberately **not** applied. Chunked uploads issue one
HTTP request per chunk, so a multi-GB upload would blow past the 100 req/min
average and fail partway through.

## First-run

1. Open https://share.punsvik.net — **the first account created becomes admin**.
   Do this promptly; until then anyone who finds the URL could claim it.
2. Admin → Configuration → **Share** → turn off *Allow registration*.
3. Configuration → **General** → set *App URL* to `https://share.punsvik.net`
   (used to build share links and email bodies).

## Pocket ID SSO

Configured in the admin UI (Configuration → OAuth), not via env vars.

1. In Pocket ID (https://auth.punsvik.net) → **OIDC Clients → Add**:
   - Type: confidential
   - Callback URL: `https://share.punsvik.net/api/oauth/callback/oidc`
   - Post-logout redirect URL: `https://share.punsvik.net`
2. In Pingvin admin → Configuration → OAuth:

   | Setting | Value |
   |---|---|
   | `oidc-enabled` | `true` |
   | `oidc-discoveryUri` | `https://auth.punsvik.net/.well-known/openid-configuration` |
   | `oidc-clientId` | from Pocket ID |
   | `oidc-clientSecret` | from Pocket ID |
   | `oidc-scope` | `openid email profile` |
   | `oidc-signOut` | `true` |
   | `oauth.allowRegistration` | `false` |

3. **Link your existing account before trying to sign in with it.** While logged
   in with your password, go to **Account → Authentication → Pocket ID → Connect**.

   Order matters. `oauth.allowRegistration: false` is correct for a public
   instance, but `OAuthService.signUp()` checks that flag *before* it looks for
   an existing user with a matching email, so the auto-link-on-first-login path
   is unreachable while it's false. Signing in via Pocket ID from the logged-out
   page fails with `no_user` even though your email matches exactly.

   Linking from the Account page goes through `OAuthController.callback()`
   instead, which sees your session, takes the `link` branch, and never consults
   `allowRegistration`. Once the `OAuthUser` row exists, `signIn()` matches on
   provider ID directly, so logged-out Pocket ID login works from then on with
   `allowRegistration` still false.

   (The alternative — flip `allowRegistration` true, sign in once to auto-link,
   flip it back — also works, but leaves a window where any Pocket ID user can
   create an account here.)

4. **Confirm Pocket ID login works from a logged-out session before** setting
   `disablePassword: true` — enabling it with a broken OIDC config locks you out
   of your own instance for real.

## Locked out?

Nothing here is unrecoverable as long as `disablePassword` is `false`. Inspect
users and login config directly:

```bash
ssh.exe nas 'sudo python3 -c "
import sqlite3
c=sqlite3.connect(\"file:/mnt/main/appdata/pingvin-share/data/pingvin-share.db?mode=ro\",uri=True)
print([r for r in c.execute(\"SELECT username,email,isAdmin FROM User\")])
print([r for r in c.execute(\"SELECT name,value FROM Config WHERE category=\\\"oauth\\\"\")])
"'
```

Login accepts **either** username or email (`AuthService`: `OR: [{email},{username}]`).
Note that signup **truncates the username** — an email of `first.lastname@…`
can yield a shorter username than you expect, so log in with the email if the
username isn't working.

## Storage

- Dataset: `main/appdata/pingvin-share/data`, owned `568:568` (apps preset ACL).
- Container runs as `PUID/PGID 568`.
- Max share size is set in the admin UI (Configuration → Share), not in compose.
  Uploads land on `main`, which has ~6.9 TB free — set a per-share cap you're
  comfortable with rather than relying on the disk to run out.

## Ops

```bash
ssh.exe nas 'midclt -t 300 call -j app.redeploy "\"pingvin-share\""'
ssh.exe nas 'sudo docker logs pingvin-share 2>&1 | tail -50'
```

Bump `PINGVIN_SHARE_IMAGE_TAG` in `.env` (or the default in `compose.yml`) to
upgrade, then redeploy.
