# set_mode.ps1 - For MPV-SW-Capture
#
# Switches the capture resolution / frame rate / pixel format.
#
# The capture format is fixed when mpv opens the DirectShow device, so it
# cannot be changed on a running instance - this writes the chosen mode to
# data\capture_mode.txt and relaunches mpv (video only; ffplay keeps
# playing, so audio is not interrupted).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\set_mode.ps1 -Mode 4k60
#   powershell -ExecutionPolicy Bypass -File .\set_mode.ps1 -List

param(
    [string]$Mode = "",
    [switch]$List
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path -Parent $scriptDir
$modeFile  = Join-Path $scriptDir "capture_mode.txt"
$batPath   = Join-Path $scriptDir "MPV-SW-Capture.bat"
$mpv       = Join-Path $rootDir "mpv.exe"

# Modes this card actually delivers, verified by enumeration:
#   raw (yuyv422/nv12) tops out at 4K30 and 1440p60
#   MJPEG reaches 4K60, 1440p144 and 1080p240, and arrives full-range
# Frame rates above the console's own output are padded with duplicate
# frames by the card, so the presets stop at what is genuinely useful.
$MODES = [ordered]@{
    "4k60"     = @{ w=3840; h=2160; fps=60;  codec="mjpeg";    label="4K 60 (MJPEG)" }
    "4k30"     = @{ w=3840; h=2160; fps=30;  codec="nv12";     label="4K 30 (raw)" }
    "1440p60"  = @{ w=2560; h=1440; fps=60;  codec="nv12";     label="1440p 60 (raw)" }
    "1440p120" = @{ w=2560; h=1440; fps=120; codec="mjpeg";    label="1440p 120 (MJPEG)" }
    "1080p60"  = @{ w=1920; h=1080; fps=60;  codec="yuyv422";  label="1080p 60 (raw)" }
    "1080p120" = @{ w=1920; h=1080; fps=120; codec="mjpeg";    label="1080p 120 (MJPEG)" }
    "720p60"   = @{ w=1280; h=720;  fps=60;  codec="yuyv422";  label="720p 60 (raw)" }
}

if ($List) {
    Write-Host "Available modes:"
    foreach ($k in $MODES.Keys) {
        "  {0,-10} {1}" -f $k, $MODES[$k].label
    }
    exit 0
}

if ($Mode -eq "" -or -not $MODES.Contains($Mode)) {
    Write-Host "ERROR: unknown mode '$Mode'. Use -List to see the options."
    exit 1
}

$m = $MODES[$Mode]

# Read the configured device out of the launcher.
$device = ""
if (Test-Path $batPath) {
    $bat = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)
    if ($bat -match '(?im)^\s*SET\s+"video_device=([^"]*)"') { $device = $Matches[1] }
}
if ($device -eq "") {
    Write-Host "ERROR: no video device configured. Run SETUP first."
    exit 3
}

# Raw formats are named with pixel_format; MJPEG with vcodec.
if ($m.codec -eq "mjpeg") {
    $fmtFlag = "--demuxer-lavf-o-append=vcodec=mjpeg"
} else {
    $fmtFlag = "--demuxer-lavf-o-append=pixel_format=" + $m.codec
}

# Buffer sized for ~16 raw frames; MJPEG needs far less.
$rtbuf = [int64]($m.w * $m.h * 2 * 16)
if ($m.codec -eq "mjpeg") { $rtbuf = [int64]($rtbuf / 4) }
if ($rtbuf -lt 67108864) { $rtbuf = 67108864 }

# IMPORTANT: -o-append, never -o-set. Each -o-set REPLACES the whole option
# map, so several -o-set flags silently discard all but the last.
$flags = @(
    $fmtFlag
    "--demuxer-lavf-o-append=video_size=" + $m.w + "x" + $m.h
    "--demuxer-lavf-o-append=framerate=" + $m.fps
    "--demuxer-lavf-o-append=rtbufsize=" + $rtbuf
    "--container-fps-override=" + $m.fps
) -join " "

Set-Content -Path $modeFile -Value $flags -Encoding ASCII -NoNewline

# Relaunch only the video instance. ffplay is left alone so audio keeps
# playing and the Audio Boost level is preserved.
$procs = @(Get-Process -Name mpv -ErrorAction SilentlyContinue)
foreach ($p in $procs) { try { $p.Kill() } catch { } }
if ($procs.Count -gt 0) { Start-Sleep -Milliseconds 600 }

# MJPEG decode benefits from more threads; raw needs almost none.
$threads = if ($m.codec -eq "mjpeg") { 4 } else { 1 }

$args = "--no-border ""av://dshow:video=$device"" --profile=low-latency " +
        "$flags --sws-scaler=point --vd-lavc-threads=$threads --untimed " +
        "--demuxer-thread=no --vo=gpu-next --hwdec=auto-safe " +
        "--target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 " +
        "--osc=no --script-opts=msc_check_version_auto=0"

Start-Process -FilePath $mpv -ArgumentList $args -WorkingDirectory $rootDir

Write-Host ("Switched to {0}" -f $m.label)
exit 0
