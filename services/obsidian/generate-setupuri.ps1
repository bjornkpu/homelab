# Generates the obsidian://setuplivesync?settings=... URI for the Self-hosted LiveSync plugin.
# Requires Deno: https://deno.com
#
# Usage: .\generate-setupuri.ps1
# Optional overrides:
#   .\generate-setupuri.ps1 -Hostname "https://obsidian.punsvik.net" -Database "obsidiannotes" -Passphrase "my-secret"

param(
    [string]$Hostname = "https://obsidian.punsvik.net",
    [string]$Database = "obsidian"
)

$envFile = Join-Path $PSScriptRoot ".env"
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
    }
}

$env:hostname = $Hostname
$env:database = $Database
$env:username = [System.Environment]::GetEnvironmentVariable("COUCHDB_USER")
$env:password = [System.Environment]::GetEnvironmentVariable("COUCHDB_PASSWORD")
$env:passphrase = if ($Passphrase) { $Passphrase } else { [System.Environment]::GetEnvironmentVariable("LIVESYNC_PASSPHRASE") }

if (-not $env:username -or -not $env:password) {
    Write-Error "COUCHDB_USER and COUCHDB_PASSWORD must be set in .env"
    exit 1
}

if (-not $env:passphrase) {
    Write-Error "LIVESYNC_PASSPHRASE must be set in .env (or pass -Passphrase)"
    exit 1
}

Write-Host "Generating setup URI for $Hostname / db: $Database ..."
deno run -A https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/flyio/generate_setupuri.ts
