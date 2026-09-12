# ffplay_watchdog.ps1
# Independent watchdog: kills ffplay.exe (and lingering helpers)
# when mpv.exe disappears (clean exit OR crash).
# Launched hidden from the main .bat, but survives independently.

$ErrorActionPreference = "SilentlyContinue"

# 1) Wait for mpv to appear (up to 20 seconds)
$waited = 0
while (-not (Get-Process -Name "mpv" -ErrorAction SilentlyContinue)) {
    Start-Sleep -Milliseconds 250
    $waited += 250
    if ($waited -ge 20000) { exit }   # mpv never started
}

# 2) Wait for mpv to disappear
while (Get-Process -Name "mpv" -ErrorAction SilentlyContinue) {
    Start-Sleep -Milliseconds 500
}

# 3) Small grace period (let a clean shutdown close ffplay by itself)
Start-Sleep -Milliseconds 1000

# 4) Kill ffplay if still running
$ffplay = Get-Process -Name "ffplay" -ErrorAction SilentlyContinue
if ($ffplay) {
    Stop-Process -Name "ffplay" -Force -ErrorAction SilentlyContinue
}

# 5) Also kill any lingering ffplayvol / ffplayboost PowerShell monitors
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -match "ffplayvol\.ps1|ffplayboost\.ps1" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }