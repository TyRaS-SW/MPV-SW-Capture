# ffplayboost.ps1 - By TyRaS-SW
# Audio Boost for MPV-SW-Capture.
#
# The regular volume control (ffplayvol.ps1) drives the Windows WASAPI session
# volume, which is a 0.0-1.0 scalar: it can only ATTENUATE. Once the session is
# at 100% there is no headroom left, so quiet capture sources cannot be raised
# any further.
#
# This script amplifies inside ffplay instead, using the ffmpeg "volume" audio
# filter (-af volume=<gain>). ffplay cannot change its filter graph at runtime,
# so applying a new boost relaunches ffplay with the same low-latency flags the
# launcher uses. The chosen level is persisted in data\boost.txt so it is
# reapplied on the next start.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\ffplayboost.ps1 get
#   powershell -ExecutionPolicy Bypass -File .\ffplayboost.ps1 set <100-400>
#   powershell -ExecutionPolicy Bypass -File .\ffplayboost.ps1 up [step]
#   powershell -ExecutionPolicy Bypass -File .\ffplayboost.ps1 down [step]
#   powershell -ExecutionPolicy Bypass -File .\ffplayboost.ps1 reset
#   powershell -ExecutionPolicy Bypass -File .\ffplayboost.ps1 apply

param(
    [string]$Command = "",
    [string]$Value = ""
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path -Parent $scriptDir
$statePath = Join-Path $scriptDir "boost.txt"
$ffplayExe = Join-Path $rootDir "ffplay.exe"
$batPath   = Join-Path $scriptDir "MPV-SW-Capture.bat"

# Boost is a percentage: 100 = no boost (unity gain), 200 = double amplitude.
$MIN_BOOST     = 100
$MAX_BOOST     = 400
$DEFAULT_STEP  = 25

function Get-Boost {
    if (Test-Path $statePath) {
        $raw = (Get-Content $statePath -Raw).Trim()
        $n = 0

        if ([int]::TryParse($raw, [ref]$n)) {
            if ($n -lt $MIN_BOOST) { return $MIN_BOOST }
            if ($n -gt $MAX_BOOST) { return $MAX_BOOST }
            return $n
        }
    }

    return $MIN_BOOST
}

function Save-Boost([int]$level) {
    Set-Content -Path $statePath -Value $level -Encoding ASCII -NoNewline
}

function Clamp-Boost([int]$level) {
    if ($level -lt $MIN_BOOST) { return $MIN_BOOST }
    if ($level -gt $MAX_BOOST) { return $MAX_BOOST }
    return $level
}

# Read the capture audio device straight out of the launcher, so the boost
# always follows whatever Setup configured. Falls back to usb3.lua.
function Get-AudioDevice {
    if (Test-Path $batPath) {
        $bat = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)

        if ($bat -match '(?im)^\s*SET\s+"audio_device=([^"]*)"') {
            $dev = $Matches[1]
            if ($dev -ne "") { return $dev }
        }
    }

    $luaPath = Join-Path $rootDir "scripts\usb3.lua"

    if (Test-Path $luaPath) {
        $lua = [System.IO.File]::ReadAllText($luaPath, [System.Text.Encoding]::UTF8)

        if ($lua -match 'data\.audio_device\s*=\s*"([^"]*)"') {
            $dev = $Matches[1]
            if ($dev -ne "") { return $dev }
        }
    }

    return ""
}

function Stop-Ffplay {
    # Not an error if nothing is running: at launch time ffplay may not exist
    # yet. Using Get-Process avoids taskkill writing to stderr, which
    # $ErrorActionPreference = "Stop" would escalate into a fatal exception.
    $procs = @(Get-Process -Name ffplay -ErrorAction SilentlyContinue)

    if ($procs.Count -eq 0) { return }

    foreach ($proc in $procs) {
        try { $proc.Kill() } catch { }
    }

    Start-Sleep -Milliseconds 250
}

# Relaunch ffplay with the boost filter applied. The flag set mirrors
# MPV-SW-Capture.bat so latency behaviour stays identical.
function Start-Ffplay([int]$level) {
    $device = Get-AudioDevice

    if ($device -eq "") {
        Write-Host "ERROR: No audio device configured. Run SETUP first."
        exit 3
    }

    if (-not (Test-Path $ffplayExe)) {
        Write-Host "ERROR: ffplay.exe was not found at: $ffplayExe"
        exit 10
    }

    # ffmpeg's volume filter takes a linear amplitude multiplier, not a percent.
    $gain = ($level / 100.0).ToString("0.###", [System.Globalization.CultureInfo]::InvariantCulture)

    $env:SDL_AUDIODRIVER  = "wasapi"
    $env:SDL_AUDIO_SAMPLES = "128"

    # The device name contains spaces (and often parentheses), so the -i value
    # must stay a single quoted argument - exactly as MPV-SW-Capture.bat does it.
    # Passing an array here would split the name into separate arguments.
    $ffArgs = (
        '-f dshow ' +
        '-audio_buffer_size 4 ' +
        '-i audio="' + $device + '" ' +
        '-af volume=' + $gain + ' ' +
        '-volume 100 ' +
        '-fflags nobuffer+fastseek ' +
        '-flags low_delay ' +
        '-strict experimental ' +
        '-nodisp -hide_banner -loglevel quiet'
    )

    Start-Process -FilePath $ffplayExe -ArgumentList $ffArgs -WindowStyle Hidden
}

function Apply-Boost([int]$level) {
    Stop-Ffplay
    Start-Ffplay $level
    Save-Boost $level
}

function Print-Help {
    Write-Host "Usage:"
    Write-Host "  ffplayboost.ps1 get"
    Write-Host "  ffplayboost.ps1 set <$MIN_BOOST-$MAX_BOOST>"
    Write-Host "  ffplayboost.ps1 up [step]"
    Write-Host "  ffplayboost.ps1 down [step]"
    Write-Host "  ffplayboost.ps1 reset"
    Write-Host "  ffplayboost.ps1 apply"
}

if ($Command -eq "") {
    Print-Help
    exit 1
}

$cmd = $Command.ToLowerInvariant()

try {
    switch ($cmd) {
        "get" {
            Write-Output (Get-Boost)
            exit 0
        }

        "set" {
            $n = 0

            if (-not [int]::TryParse($Value, [ref]$n)) {
                Write-Host "ERROR: set requires a value from $MIN_BOOST to $MAX_BOOST"
                exit 1
            }

            $level = Clamp-Boost $n
            Apply-Boost $level

            Write-Output $level
            exit 0
        }

        "up" {
            $step = $DEFAULT_STEP
            $n = 0

            if ([int]::TryParse($Value, [ref]$n)) { $step = $n }

            $level = Clamp-Boost ((Get-Boost) + $step)
            Apply-Boost $level

            Write-Output $level
            exit 0
        }

        "down" {
            $step = $DEFAULT_STEP
            $n = 0

            if ([int]::TryParse($Value, [ref]$n)) { $step = $n }

            $level = Clamp-Boost ((Get-Boost) - $step)
            Apply-Boost $level

            Write-Output $level
            exit 0
        }

        "reset" {
            Apply-Boost $MIN_BOOST

            Write-Output $MIN_BOOST
            exit 0
        }

        # Used at launch: start ffplay with the stored boost, without killing a
        # session first (the launcher has not started one yet).
        "apply" {
            $level = Get-Boost

            if ($level -le $MIN_BOOST) {
                Write-Output $MIN_BOOST
                exit 0
            }

            Stop-Ffplay
            Start-Ffplay $level

            Write-Output $level
            exit 0
        }

        default {
            Print-Help
            exit 1
        }
    }
}
catch {
    Write-Host "EXCEPTION: $($_.Exception.Message)"
    exit 9
}
