#!/bin/sh
set -e

APP_NAME="$1"

[ -n "${APP_NAME}" ] || { echo "ERROR: app name required"; exit 1; }

# Validate app name against whitelist
echo "${ALLOWED_APPS}" | tr ',' '\n' | grep -qx "${APP_NAME}" || {
  echo "ERROR: app '${APP_NAME}' not in ALLOWED_APPS"
  exit 1
}

# Call TrueNAS API to redeploy the app (pulls latest image + restarts)
# Equivalent to: midclt call app.redeploy "\"appname\""
PAYLOAD=$(printf '"%s"' "${APP_NAME}")
curl -sfk --max-time 30 -X POST \
  "https://192.168.1.4:444/api/v2.0/app/redeploy" \
  -H "Authorization: Bearer ${TRUENAS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}"
