#!/bin/sh
set -e

APP_NAME="$1"

[ -n "${APP_NAME}" ] || { echo "ERROR: app name required"; exit 1; }

# Validate app name against whitelist
echo "${ALLOWED_APPS}" | tr ',' '\n' | grep -qx "${APP_NAME}" || {
  echo "ERROR: app '${APP_NAME}' not in ALLOWED_APPS"
  exit 1
}

# Call TrueNAS API to update the app (pulls latest image + restarts)
# NOTE: Endpoint/payload needs verification on live system.
#       Confirmed working via CLI: midclt call -job app.update "\"appname\""
PAYLOAD=$(printf '["%s", {}]' "${APP_NAME}")
curl -sf --max-time 30 -X POST \
  "http://localhost/api/v2.0/app/update" \
  -H "Authorization: Bearer ${TRUENAS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}"
