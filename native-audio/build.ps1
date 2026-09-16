param([string]$Compiler = 'C:\msys64\ucrt64\bin\g++.exe')
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Compiler)) { throw "Install MSYS2 UCRT64 GCC or pass -Compiler with its g++.exe path." }
$appRoot = Split-Path -Parent $PSScriptRoot
$previousPath = $env:PATH
try {
    $env:PATH = (Split-Path -Parent $Compiler) + ';' + $env:PATH
    & $Compiler -std=c++17 -O2 -Wall -Wextra -shared -static -static-libgcc -static-libstdc++ `
        (Join-Path $PSScriptRoot 'msc_audio.cpp') -o (Join-Path $appRoot 'scripts\msc_audio.dll') -lole32 -luuid -lavrt -lksuser
    if ($LASTEXITCODE -ne 0) { throw 'Audio plugin compilation failed. Close MPV before rebuilding its loaded DLL.' }
    & $Compiler -std=c++17 -O2 -Wall -Wextra -static (Join-Path $PSScriptRoot 'audio_core_test.cpp') -o (Join-Path $PSScriptRoot 'audio_core_test.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Audio core test compilation failed' }
    & (Join-Path $PSScriptRoot 'audio_core_test.exe')
    if ($LASTEXITCODE -ne 0) { throw 'Audio core tests failed' }
    Write-Output 'Built scripts/msc_audio.dll (Windows x64, system DLL dependencies only).'
} finally { $env:PATH = $previousPath }
