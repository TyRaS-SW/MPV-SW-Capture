# ffplayvol.ps1 - By TyRaS-SW
# Controls the volume of ffplay's audio session through WASAPI.
# Requires FfplayVolWrapper.dll in the same directory.
#
# Usage (the order of <value> and <target> does not matter):
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 list
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 watch-tag [ffplay] [5000]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 get [ffplay]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 set <0-100> [ffplay]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 up <step> [ffplay]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 down <step> [ffplay]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 mute [ffplay]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 unmute [ffplay]
#   powershell -ExecutionPolicy Bypass -File .\ffplayvol.ps1 togglemute [ffplay]

param(
    [string]$Command = "",
    [string]$Target = "ffplay",
    [string]$Step = "5"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dllPath = Join-Path $scriptDir "FfplayVolWrapper.dll"

if (-not (Test-Path $dllPath)) {
    Write-Host "ERROR: FfplayVolWrapper.dll was not found at: $dllPath"
    Write-Host "Compile the DLL first by running compile-wrapper.bat"
    exit 10
}

Add-Type -Path $dllPath

# Flexible argument parsing:
# Numeric arguments are used as a volume value, step size, or timeout.
# Text arguments are used as the target audio-session name.
$target = "ffplay"
$numericVal = 5
$hasNumeric = $false

foreach ($a in @($Target, $Step)) {
    if ($a -and $a -ne "") {
        $n = 0

        if ([int]::TryParse($a, [ref]$n)) {
            $numericVal = $n
            $hasNumeric = $true
        }
        else {
            $target = $a
        }
    }
}

function Print-Help {
    Write-Host "Usage:"
    Write-Host "  ffplayvol.ps1 list"
    Write-Host "  ffplayvol.ps1 watch-tag [ffplay] [5000]"
    Write-Host "  ffplayvol.ps1 get [ffplay]"
    Write-Host "  ffplayvol.ps1 set <0-100> [ffplay]"
    Write-Host "  ffplayvol.ps1 up <step> [ffplay]"
    Write-Host "  ffplayvol.ps1 down <step> [ffplay]"
    Write-Host "  ffplayvol.ps1 mute [ffplay]"
    Write-Host "  ffplayvol.ps1 unmute [ffplay]"
    Write-Host "  ffplayvol.ps1 togglemute [ffplay]"
}

if ($Command -eq "") {
    Print-Help
    exit 1
}

$cmd = $Command.ToLowerInvariant()

try {
    switch ($cmd) {
        "list" {
            $sessions = [FfplayVol.FfplayVolWrapper]::ListSessions()

            Write-Host "Active audio sessions found: $($sessions.Count)"

            foreach ($s in $sessions) {
                Write-Host $s
            }

            exit 0
        }

        "watch-tag" {
            $timeout = 4000

            if ($hasNumeric) {
                $timeout = $numericVal
            }

            Write-Host "Waiting for an ffplay audio session for ${timeout}ms (tag: $target)..."

            $ok = [FfplayVol.FfplayVolWrapper]::WatchTag($target, $timeout)

            if ($ok) {
                Write-Host "watch-tagged:$target"
                exit 0
            }
            else {
                Write-Host "ERROR: No new ffplay session was detected within ${timeout}ms"
                exit 2
            }
        }

        "get" {
            $vol = [FfplayVol.FfplayVolWrapper]::GetVolume($target)
            Write-Output $vol
            exit 0
        }

        "set" {
            if (-not $hasNumeric) {
                Write-Host "ERROR: set requires a value from 0 to 100"
                exit 1
            }

            [FfplayVol.FfplayVolWrapper]::SetVolume($target, $numericVal)

            Write-Output $numericVal
            exit 0
        }

        "up" {
            $stepVal = 10

            if ($hasNumeric) {
                $stepVal = $numericVal
            }

            [FfplayVol.FfplayVolWrapper]::VolumeUp($target, $stepVal)

            $newVol = [FfplayVol.FfplayVolWrapper]::GetVolume($target)

            Write-Output $newVol
            exit 0
        }

        "down" {
            $stepVal = 10

            if ($hasNumeric) {
                $stepVal = $numericVal
            }

            [FfplayVol.FfplayVolWrapper]::VolumeDown($target, $stepVal)

            $newVol = [FfplayVol.FfplayVolWrapper]::GetVolume($target)

            Write-Output $newVol
            exit 0
        }

        "mute" {
            [FfplayVol.FfplayVolWrapper]::Mute($target)

            Write-Output "muted"
            exit 0
        }

        "unmute" {
            [FfplayVol.FfplayVolWrapper]::Unmute($target)

            Write-Output "unmuted"
            exit 0
        }

        "togglemute" {
            $isMuted = [FfplayVol.FfplayVolWrapper]::ToggleMute($target)

            if ($isMuted) {
                Write-Output "muted"
            }
            else {
                Write-Output "unmuted"
            }

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