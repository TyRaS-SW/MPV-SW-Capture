# ffplay_watchdog.ps1
# Independent watchdog: stops this installation's FFplay and helpers
# when its MPV disappears (clean exit OR crash).
# Launched hidden from the main .bat, but survives independently.

param([switch]$CleanupOnly)

$ErrorActionPreference = "SilentlyContinue"

$captureRoot = Split-Path -Parent $PSScriptRoot
$captureMpv = Join-Path $captureRoot "mpv.exe"
$captureFfplay = Join-Path $captureRoot "ffplay.exe"
$helperPattern = '(?i)(?:^|[\s"])' + [regex]::Escape($PSScriptRoot) + '\\ffplay(?:vol|boost)\.ps1(?:"|\s|$)'

function Get-CaptureMpv {
    Get-Process -Name "mpv" -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq $captureMpv }
}

if (-not $CleanupOnly) {
    # 1) Wait for mpv to appear (up to 20 seconds)
    $waited = 0
    while (-not (Get-CaptureMpv)) {
        Start-Sleep -Milliseconds 250
        $waited += 250
        if ($waited -ge 20000) { exit }   # mpv never started
    }

    # 2) Wait for mpv to disappear
    while (Get-CaptureMpv) {
        Start-Sleep -Milliseconds 500
    }

    # 3) Small grace period (let a clean shutdown close ffplay by itself)
    Start-Sleep -Milliseconds 1000
}

# A replacement capture may have started during the grace period. The launcher
# uses CleanupOnly only after ruling out another capture MPV instance.
if (-not $CleanupOnly -and (Get-CaptureMpv)) { exit }

# Stop this installation's helpers first, so a pending boost cannot relaunch
# FFplay after cleanup. Forward slashes are used by the Lua callers.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { ($_.CommandLine -replace '/', '\') -match $helperPattern } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Get-Process -Name "ffplay" -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $captureFfplay } |
    ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
