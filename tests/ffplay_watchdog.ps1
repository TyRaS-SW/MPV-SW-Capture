# Run: powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/ffplay_watchdog.ps1
# All process enumeration, sleeping and termination are mocked.
$ErrorActionPreference = 'Stop'
$watchdog = Join-Path (Split-Path -Parent $PSScriptRoot) 'data\ffplay_watchdog.ps1'
$dataDir = Split-Path -Parent $watchdog
$appDir = Split-Path -Parent $dataDir

function Get-Process {
    param($Name, $ErrorAction)
    if ($Name -eq 'mpv') {
        $testState.mpvQueries++
        [pscustomobject]@{ Id = 90; Path = 'C:\Other App\mpv.exe' }
        if ($testState.mpvQueries -le 2 -or ($testState.restarted -and $testState.mpvQueries -ge 4)) {
            [pscustomobject]@{ Id = 10; Path = (Join-Path $appDir 'mpv.exe') }
        }
    } else {
        [pscustomobject]@{ Id = 20; Path = (Join-Path $appDir 'ffplay.exe') }
        [pscustomobject]@{ Id = 91; Path = 'C:\Other App\ffplay.exe' }
    }
}
function Get-CimInstance {
    param($ClassName, $Filter)
    [pscustomobject]@{ ProcessId = 30; CommandLine = ('powershell -File "' + $dataDir + '\ffplayboost.ps1" set 200') }
    [pscustomobject]@{ ProcessId = 31; CommandLine = ('powershell -File "' + ($dataDir -replace '\\', '/') + '/ffplayvol.ps1" watch-tag') }
    [pscustomobject]@{ ProcessId = 92; CommandLine = 'powershell -File "C:\Other App\data\ffplayboost.ps1" set 200' }
    [pscustomobject]@{ ProcessId = 93; CommandLine = ('powershell -File "' + $dataDir + '\ffplayboost.ps1.extra"') }
}
function Start-Sleep {
    param($Milliseconds)
    $testState.sleeps++
    if ($testState.sleeps -gt 5) { throw 'Watchdog incorrectly waited for an unrelated player' }
}
function Stop-Process {
    param($Id, [switch]$Force, $ErrorAction)
    $testState.stopped.Add([int]$Id)
}

foreach ($case in @('normal shutdown with unrelated MPV', 'orphan cleanup', 'capture restarted during grace period')) {
    $testState = @{}
    $testState.mpvQueries = 0
    $testState.sleeps = 0
    $testState.stopped = New-Object 'System.Collections.Generic.List[int]'
    $testState.restarted = $case -eq 'capture restarted during grace period'
    & $watchdog -CleanupOnly:($case -eq 'orphan cleanup')
    $actual = $testState.stopped -join ','
    $expected = if ($testState.restarted) { '' } else { '30,31,20' }
    if ($actual -ne $expected) { throw "${case}: expected stops [$expected], got [$actual]" }
    Write-Output "PASS: $case"
}
