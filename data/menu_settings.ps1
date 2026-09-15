# Shared by the launcher and settings writers. Keep legacy files as backups;
# an existing setting in data/menu always wins.
$ErrorActionPreference = 'Stop'
$menuDirectory = Join-Path $PSScriptRoot 'menu'
[System.IO.Directory]::CreateDirectory($menuDirectory) | Out-Null
foreach ($name in @('audio_mode.txt', 'boost.txt', 'hover_volume.txt')) {
    $legacy = Join-Path $PSScriptRoot $name
    $destination = Join-Path $menuDirectory $name
    if ((Test-Path -LiteralPath $legacy -PathType Leaf) -and
        -not (Test-Path -LiteralPath $destination)) {
        try { [System.IO.File]::Copy($legacy, $destination, $false) }
        catch {
            # Another startup reader may have migrated it concurrently.
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw }
        }
    }
}
