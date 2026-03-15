# Run once after the CouchDB container starts to finalize single-node cluster setup.
# All other settings (CORS, auth, size limits) are handled by local.d/local.ini.
#
# Usage: .\init-couchdb.ps1
# Optionally override the host: .\init-couchdb.ps1 -Host "http://192.168.1.100:5984"

param(
    [string]$CouchDbHost = "https://obsidian.punsvik.net"
)

# Load credentials from .env file in the same directory
$envFile = Join-Path $PSScriptRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}

$username = [System.Environment]::GetEnvironmentVariable("COUCHDB_USER")
$password = [System.Environment]::GetEnvironmentVariable("COUCHDB_PASSWORD")

if (-not $username -or -not $password) {
    Write-Error "COUCHDB_USER and COUCHDB_PASSWORD must be set in .env"
    exit 1
}

$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))
$headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Basic $cred"
}

$body = @{
    action       = "enable_single_node"
    username     = $username
    password     = $password
    bind_address = "0.0.0.0"
    port         = 5984
    singlenode   = $true
} | ConvertTo-Json

Write-Host "Initializing CouchDB at $CouchDbHost ..."
$response = Invoke-RestMethod -Method POST -Uri "$CouchDbHost/_cluster_setup" -Headers $headers -Body $body
Write-Host "Done: $($response | ConvertTo-Json)"
