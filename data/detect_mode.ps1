# detect_mode.ps1 - For MPV-SW-Capture
#
# Picks the best capture mode the card can actually deliver and writes the
# matching mpv flags to data\capture_mode.txt for the launcher to read.
#
# Why this exists:
#   * Raw (uncompressed) tops out at 4K30 / 1440p60 on this class of card,
#     while MJPEG reaches 4K60 - so MJPEG is preferred at high resolutions.
#   * MJPEG also arrives full-range (yuvj*, "pc") instead of limited-range
#     ("tv"), which measurably widens the luma range.
#   * The console can change output resolution between sessions, so the mode
#     is detected at launch rather than hardcoded.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\detect_mode.ps1 [-Device "<name>"]
#   powershell -ExecutionPolicy Bypass -File .\detect_mode.ps1 -Show

param(
    [string]$Device = "",
    [switch]$Show
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path -Parent $scriptDir
$ffmpeg    = Join-Path $rootDir "ffmpeg.exe"
$outFile   = Join-Path $scriptDir "capture_mode.txt"
$batPath   = Join-Path $scriptDir "MPV-SW-Capture.bat"

# Read the configured device out of the launcher when not given one.
function Get-Device {
    if ($Device -ne "") { return $Device }

    if (Test-Path $batPath) {
        $bat = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)

        if ($bat -match '(?im)^\s*SET\s+"video_device=([^"]*)"') {
            $d = $Matches[1]
            if ($d -ne "") { return $d }
        }
    }

    return ""
}

$dev = Get-Device

if ($dev -eq "") {
    Write-Host "ERROR: no video device configured. Run SETUP first."
    exit 3
}

if (-not (Test-Path $ffmpeg)) {
    Write-Host "ERROR: ffmpeg.exe not found at: $ffmpeg"
    exit 10
}

# ------------------------------------------------------------
# Enumerate what the card advertises
# ------------------------------------------------------------
# ffmpeg writes this listing to stderr and exits non-zero by design, so
# redirect and ignore the exit code rather than letting it throw.
$listing = ""
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    $listing = (& $ffmpeg -hide_banner -f dshow -list_options true -i ("video=" + $dev) 2>&1 | Out-String)
} catch {
    $listing = "$_"
} finally {
    $ErrorActionPreference = $prevEAP
}

if ($listing -match "Could not|not found|I/O error") {
    # The device is almost certainly open in another process; a running
    # capture holds it exclusively.
    Write-Host "ERROR: could not query the device (is the app already running?)"
    exit 4
}

# Lines look like:
#   vcodec=mjpeg  min s=3840x2160 fps=25 max s=3840x2160 fps=60.0002
#   pixel_format=nv12  min s=1920x1080 fps=5 max s=1920x1080 fps=120
$modes = @()

foreach ($line in ($listing -split "`n")) {
    if ($line -match '(vcodec|pixel_format)=(\S+).*?max s=(\d+)x(\d+) fps=([\d.]+)') {
        $modes += [pscustomobject]@{
            Kind   = $Matches[1]
            Codec  = $Matches[2]
            Width  = [int]$Matches[3]
            Height = [int]$Matches[4]
            Fps    = [double]$Matches[5]
        }
    }
}

if ($modes.Count -eq 0) {
    Write-Host "ERROR: the device reported no usable modes"
    exit 5
}

# ------------------------------------------------------------
# Rank the modes
# ------------------------------------------------------------
# Resolution first, then framerate; MJPEG breaks ties because it reaches
# framerates raw cannot and carries full colour range. Anything under 50fps
# is treated as a fallback so a 4K30 raw mode never beats 4K60 MJPEG.
function Score([object]$m) {
    $pixels = $m.Width * $m.Height
    $fps    = [math]::Round($m.Fps)

    # Frame rates above the source are padded with duplicates by the card,
    # so cap the value of very high rates rather than chasing 240fps.
    if ($fps -gt 60) { $fps = 60 }

    $score = $pixels * $fps
    if ($m.Codec -eq "mjpeg") { $score = $score * 1.10 }
    return $score
}

$best = $modes | Sort-Object -Property @{ Expression = { Score $_ } } -Descending | Select-Object -First 1

if ($Show) {
    Write-Host "Device: $dev"
    Write-Host ""
    Write-Host "Available modes (best first):"
    $modes |
        Sort-Object -Property @{ Expression = { Score $_ } } -Descending |
        Select-Object -First 12 |
        ForEach-Object {
            "  {0,-14} {1,4}x{2,-5} {3,6:N0} fps" -f $_.Codec, $_.Width, $_.Height, $_.Fps
        }
    Write-Host ""
}

# ------------------------------------------------------------
# Emit mpv flags
# ------------------------------------------------------------
# IMPORTANT: use -o-append, never -o-set. Each -o-set REPLACES the whole
# option map, so several of them silently discard all but the last. That is
# why the previous launcher's rtbufsize was never actually applied.
$fps = [math]::Round($best.Fps)
if ($fps -gt 60) { $fps = 60 }

# Raw frames are width*height*2 bytes; give the buffer room for ~16 of them
# so a hitch cannot back the device up. MJPEG needs far less.
$frameBytes = $best.Width * $best.Height * 2
$rtbuf = [int64]($frameBytes * 16)
if ($best.Codec -eq "mjpeg") { $rtbuf = [int64]($rtbuf / 4) }
if ($rtbuf -lt 67108864) { $rtbuf = 67108864 }

$flags = @()
if ($best.Kind -eq "vcodec") {
    $flags += "--demuxer-lavf-o-append=vcodec=" + $best.Codec
} else {
    $flags += "--demuxer-lavf-o-append=pixel_format=" + $best.Codec
}
$flags += "--demuxer-lavf-o-append=video_size=" + $best.Width + "x" + $best.Height
$flags += "--demuxer-lavf-o-append=framerate=" + $fps
$flags += "--demuxer-lavf-o-append=rtbufsize=" + $rtbuf
$flags += "--container-fps-override=" + $fps

$line = $flags -join " "

Set-Content -Path $outFile -Value $line -Encoding ASCII -NoNewline

Write-Host ("Selected: {0} {1}x{2} @ {3}fps" -f $best.Codec, $best.Width, $best.Height, $fps)

if ($Show) {
    Write-Host ""
    Write-Host "Flags written to $outFile"
    Write-Host $line
}

exit 0
