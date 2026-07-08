# e4Coin — instalador CLI para Windows (PowerShell 5.1+ / 7).
#
#   irm https://raw.githubusercontent.com/ab4cus/e4Coin-core/develop/install.ps1 | iex
#
# Prácticas aplicadas:
#   - sin privilegios de administrador: instala en %LOCALAPPDATA%\e4Coin\bin
#   - verifica SHA256 contra el asset SHA256SUMS del release (si existe)
#   - versión fijable:  $env:E4COIN_VERSION = "v22.1.3-e4coin.1"  (defecto: latest)
#   - PATH de usuario actualizado (no el de máquina)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = "ab4cus/e4Coin-core"
$InstallDir = if ($env:E4COIN_DIR) { $env:E4COIN_DIR } else { Join-Path $env:LOCALAPPDATA "e4Coin" }
$BinDir = Join-Path $InstallDir "bin"
$Version = if ($env:E4COIN_VERSION) { $env:E4COIN_VERSION } else { "latest" }

function Say([string]$msg) { Write-Host "e4coin-install: $msg" }

# --- resolver versión ---
if ($Version -eq "latest") {
    Say "consultando la última versión…"
    $release = Invoke-RestMethod -UseBasicParsing -Uri "https://api.github.com/repos/$Repo/releases/latest"
    $Version = $release.tag_name
}
Say "versión: $Version"

$Asset = "e4coin-$Version-win64.zip"
$Url = "https://github.com/$Repo/releases/download/$Version/$Asset"
$Tmp = Join-Path ([IO.Path]::GetTempPath()) "e4coin-install-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $Tmp | Out-Null

try {
    # --- descarga ---
    Say "descargando $Asset…"
    $ZipPath = Join-Path $Tmp $Asset
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $ZipPath

    # --- verificación SHA256 ---
    $SumsUrl = "https://github.com/$Repo/releases/download/$Version/SHA256SUMS"
    $SumsPath = Join-Path $Tmp "SHA256SUMS"
    $expected = $null
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $SumsUrl -OutFile $SumsPath
        $line = Select-String -Path $SumsPath -Pattern ([regex]::Escape($Asset)) | Select-Object -First 1
        if ($line) { $expected = ($line.Line -split "\s+")[0] }
    } catch { Say "aviso: el release no publica SHA256SUMS; se omite la verificación" }
    if ($expected) {
        $actual = (Get-FileHash -Algorithm SHA256 -Path $ZipPath).Hash.ToLowerInvariant()
        if ($actual -ne $expected.ToLowerInvariant()) {
            throw "checksum SHA256 INCORRECTO para $Asset (esperado $expected, obtenido $actual)"
        }
        Say "checksum SHA256 verificado ✓"
    }

    # --- instalación ---
    Say "instalando en $BinDir…"
    Expand-Archive -Path $ZipPath -DestinationPath $Tmp -Force
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
    $payload = Join-Path $Tmp "e4coin-win64"
    if (-not (Test-Path $payload)) { $payload = $Tmp }  # por si el zip no lleva carpeta
    Get-ChildItem -Path $payload -Filter "*.exe" | ForEach-Object {
        Copy-Item $_.FullName -Destination $BinDir -Force
    }

    # --- PATH de usuario ---
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$BinDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$BinDir;$userPath", "User")
        Say "PATH de usuario actualizado (abre una nueva terminal para usarlo)"
    }

    Say "listo ✓"
    Say "arrancar un nodo:   e4coind -daemon     (config: %APPDATA%\e4CoinCore\e4coin.conf)"
    Say "desinstalar:        Remove-Item -Recurse -Force `"$InstallDir`""
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
