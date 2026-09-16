# Isolated launcher/FFplay integration tests. No capture processes are started.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('MSC settings test ' + [Guid]::NewGuid().ToString('N'))
$data = Join-Path $fixture 'data'
[IO.Directory]::CreateDirectory($data) | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'data/menu_settings.ps1') -Destination $data
Copy-Item -LiteralPath (Join-Path $repo 'data/ffplayboost.ps1') -Destination $data
$launcher = [IO.File]::ReadAllText((Join-Path $repo 'data/MPV-SW-Capture.bat'))
$prefix = $launcher.Substring(0, $launcher.IndexOf('set "ffplayvol_ps1='))
[IO.File]::WriteAllText((Join-Path $data 'MPV-SW-Capture.bat'),
    $prefix + "`r`necho MODE=%audio_mode%`r`nexit /b 0`r`n", [Text.Encoding]::ASCII)
function Assert-Mode($expected) {
    $output = & cmd.exe /d /c (Join-Path $data 'MPV-SW-Capture.bat')
    if ($LASTEXITCODE -ne 0 -or $output -notcontains "MODE=$expected") {
        throw "Expected mode $expected, got $output"
    }
}
Assert-Mode 'plugin'
[IO.File]::WriteAllText((Join-Path $data 'audio_mode.txt'), 'ffplay')
[IO.File]::WriteAllText((Join-Path $data 'boost.txt'), '225')
[IO.File]::WriteAllText((Join-Path $data 'hover_volume.txt'), 'no')
Assert-Mode 'ffplay'
if ([IO.File]::ReadAllText((Join-Path $data 'menu/hover_volume.txt')) -ne 'no') { throw 'Hover setting lost' }
$boost = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $data 'ffplayboost.ps1') get
if ($LASTEXITCODE -ne 0 -or $boost -ne '225') { throw 'FFplay did not read migrated boost' }
[IO.File]::WriteAllText((Join-Path $data 'menu/audio_mode.txt'), 'mpv')
[IO.File]::WriteAllText((Join-Path $data 'menu/boost.txt'), '300')
Assert-Mode 'mpv'
$boost = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $data 'ffplayboost.ps1') get
if ($LASTEXITCODE -ne 0 -or $boost -ne '300') { throw 'Legacy boost overwrote new preference' }
[IO.File]::WriteAllText((Join-Path $data 'menu/audio_mode.txt'), 'invalid')
Assert-Mode 'ffplay'
Write-Output 'PASS: launcher defaults, legacy migration, new-setting precedence and FFplay boost'
