Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ============================================================
#  APPMODELID (to show icon in taskbar)
# ============================================================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class TaskbarAppId {
    [DllImport("shell32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);
}
"@

$script:AppUserModelID = "TyRaS.MPVSWCapture.BezelManager"
try {
    [TaskbarAppId]::SetCurrentProcessExplicitAppUserModelID($script:AppUserModelID) | Out-Null
} catch {}

# ============================================================
#  ROBUST PATH DETECTION (works from data/script)
# ============================================================
function Get-ScriptDir {
    try { if ($PSCommandPath) { return (Split-Path -Parent $PSCommandPath) } } catch {}
    try { if ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) { return (Split-Path -Parent $MyInvocation.MyCommand.Path) } } catch {}
    return (Get-Location).Path
}

function Get-RootDir {
    $scriptDir = Get-ScriptDir
    # Si el script está en data/script, subimos dos niveles para obtener la raíz
    if ((Split-Path $scriptDir -Leaf) -eq 'script' -and (Split-Path (Split-Path $scriptDir -Parent) -Leaf) -eq 'data') {
        $root = Split-Path -Parent (Split-Path -Parent $scriptDir)
        return $root
    }
    # Fallback: usar el directorio del script como raíz (para compatibilidad)
    return $scriptDir
}

# --- CORRECTED PATHS: JSON and log go directly into tools/ ---
$script:RootDir = Get-RootDir
$script:ScriptDir = Get-ScriptDir  # Should be data/script
$script:ToolsDir = Join-Path $script:RootDir "tools"
$script:ManagerDir = $script:ToolsDir   # No subfolder, JSON and log in tools/
$script:BezelsDir = Join-Path $script:RootDir "bezels"
$script:MenuConfPath = Join-Path $script:RootDir "menu.conf"
$script:JsonPath = Join-Path $script:ManagerDir "user-bezels.json"
$script:LogPath = Join-Path $script:ManagerDir "bezel_manager_debug.log"
$script:CurrentLang = 'EN'
$script:CurrentEditBid = $null

# ============================================================
#  ENSURE DIRECTORIES
# ============================================================
function Ensure-Dirs {
    foreach ($p in @($script:BezelsDir, $script:ToolsDir)) {
        if (-not (Test-Path -LiteralPath $p)) {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
        }
    }
}
Ensure-Dirs

# ============================================================
#  FORM ICON (prioritizes data\icon\bezelmsc.ico)
# ============================================================
function Get-AppIcon {
    try {
        $customIconPath = Join-Path $script:RootDir "data\icon\bezelmsc.ico"
        if (Test-Path -LiteralPath $customIconPath) {
            return New-Object System.Drawing.Icon($customIconPath)
        }
    } catch {}

    try {
        $exePath = [System.Windows.Forms.Application]::ExecutablePath
        if ($exePath -and (Test-Path -LiteralPath $exePath)) {
            return [System.Drawing.Icon]::ExtractAssociatedIcon($exePath)
        }
    } catch {}

    return $null
}

# ============================================================
#  GROUPS, LANGUAGES, AND CORE LOGIC (unchanged)
# ============================================================
$script:Groups = @(
    @{ Key='PERSONAL'; EN='Custom / Manual (Personal)'; ES='Personalizado / Manual (Personal)'; X=''; Y=''; W=''; H='' },
    @{ Key='NES'; EN='NES (Famicom)'; ES='NES (Famicom)'; X='302'; Y='28'; W='1316'; H='1026' },
    @{ Key='SNES'; EN='SNES / GEN (Megadrive)'; ES='SNES / GEN (Megadrive)'; X='298'; Y='36'; W='1322'; H='1008' },
    @{ Key='GB'; EN='GB / GBC'; ES='GB / GBC'; X='398'; Y='36'; W='1124'; H='1008' },
    @{ Key='GBA'; EN='GBA'; ES='GBA'; X='240'; Y='60'; W='1440'; H='960' },
    @{ Key='N64'; EN='N64 / GC'; ES='N64 / GC'; X='240'; Y='0'; W='1440'; H='1080' }
)

$script:Lang = @{
EN = @{
Title='MPV-SW-Capture - Bezel Manager'; Header='Create and manage your Bezels.'; LangLabel='GUI Language';
Files='Paths'; FilesNote='Program stays in tools. Data, log and backup go to tools\. Copied PNG bezels still go to the root bezels folder.';
Root='Root folder'; Tools='Tools folder'; Manager='Tools folder (data)'; Bezels='Root bezels folder'; Menu='menu.conf'; Json='user-bezels.json'; Backup='menu.conf.bak'; Log='bezel_manager_debug.log';
List='Saved Bezels'; ListHint='Manage multiple Bezels using Mouse/Keyboard and the buttons below.'; Editor='Bezel editor'; Name='Display name'; Png='PNG file'; Browse='Browse PNG...'; Copy='Copy PNG to root bezels folder'; Group='Group'; Preset='Preset coords'; X='X'; Y='Y'; W='Width'; H='Height';
Add='Add new'; Update='Update selected'; Delete='Delete selected'; DeleteSelected='Delete selected'; Clear='Clear form'; Apply='Apply to menu.conf'; RestoreBase='Delete Bezels in menu.conf'; RestoreBaseES='Delete Bezels in menu.conf'; Reload='Reload list'; Import='Import other user-bezels.json'; EnableSelected='Enable selected'; DisableSelected='Disable selected'; CheckPngs='Check PNGs'; PresetGroup='Group preset'; PresetCustom='Custom / Manual'; EnableBezel='Enable Bezel'; JsonFilter='JSON files (*.json)|*.json'; RestoreTitle='MPV-SW-Capture - Bezel Manager'; StatusReady='Ready.';
MsgName='Please enter a Bezel name.'; MsgPng='Please choose a valid PNG file.'; MsgNums='X, Y, Width and Height must be valid integers.'; MsgMenu='menu.conf not found in root folder.'; MsgSelect='Please select a Bezel from the list first.'; MsgSelectDelete='To delete a Bezel, select one from the list.'; MsgSelectEnable='You have to select a Bezel to enable it.'; MsgSelectDisable='You have to select a Bezel to disable it.'; MsgSelectDeleteMulti='You have to select at least one Bezel to delete it.'; MsgAdded='Bezel added.'; MsgUpdated='Bezel updated.'; MsgDeleted='Bezel deleted.'; MsgDeletedMulti='Selected Bezels deleted.'; MsgEnabledMulti='Selected Bezels enabled.'; MsgDisabledMulti='Selected Bezels disabled.'; MsgApplied='menu.conf updated successfully.'; MsgNoBezels='No Bezels saved. PERSONAL block removed if present.'; MsgCopied='PNG copied to:'; MsgLoad='Data reloaded.'; MsgConfirmDelete='Delete selected Bezel?'; MsgConfirmDeleteMulti='Are you sure you want to delete the selected Bezels?'; MsgConfirmTitle='Confirm'; MsgConfirmDeleteTitle='Confirm delete'; MsgRestoreBaseDone='All BID Bezels and PERSONAL menu entries were removed from menu.conf.'; MsgImportDisabled='Imported Bezels disabled by default.'; MsgImportInvalid='Invalid user-bezels.json: missing bezels array.'; MsgPngCheckOk='PNG check complete. All PNGs found.'; MsgPngMissing='WARNING: missing PNG file: '; MsgSectionBezelsMissing='BEZELS section was not found.'; MsgClearLineMissing='Clear Bezels / Borrar Marcos line was not found.'; OpenFilter='PNG files (*.png)|*.png'
};
ES = @{
Title='MPV-SW-Capture - Administrador de Marcos'; Header='Crea y administra tus Marcos.'; LangLabel='Idioma del GUI';
Files='Rutas'; FilesNote='El programa queda en tools. Los datos, log y backup van a tools\. Los PNG copiados van a la carpeta bezels de la raiz.';
Root='Carpeta raiz'; Tools='Carpeta tools'; Manager='Carpeta tools (datos)'; Bezels='Carpeta de los Marcos de la raiz'; Menu='menu.conf'; Json='user-bezels.json'; Backup='menu.conf.bak'; Log='bezel_manager_debug.log';
List='Marcos guardados'; ListHint='Administra multiples Marcos usando Mouse/Teclado y los botones de abajo.'; Editor='Editor de Marco'; Name='Nombre visible'; Png='Archivo PNG'; Browse='Buscar PNG...'; Copy='Copiar PNG a la carpeta bezels de la raiz'; Group='Grupo'; Preset='Coordenadas preset'; X='X'; Y='Y'; W='Ancho'; H='Alto';
Add='Agregar nuevo'; Update='Actualizar seleccionado'; Delete='Eliminar seleccionado'; DeleteSelected='Eliminar seleccionados'; Clear='Limpiar formulario'; Apply='Aplicar a menu.conf'; RestoreBase='Delete Bezels in menu.conf'; RestoreBaseES='Borrar Marcos en menu.conf'; Reload='Recargar lista'; Import='Importar otro user-bezels.json'; EnableSelected='Habilitar seleccionados'; DisableSelected='Deshabilitar seleccionados'; CheckPngs='Comprobar PNGs'; PresetGroup='Preset del grupo'; PresetCustom='Personalizado / Manual'; EnableBezel='Habilitar Marco'; JsonFilter='Archivos JSON (*.json)|*.json'; RestoreTitle='MPV-SW-Capture - Administrador de Marcos'; StatusReady='Listo.';
MsgName='Por favor escribe un nombre para el bezel.'; MsgPng='Por favor elige un archivo PNG valido.'; MsgNums='X, Y, Ancho y Alto deben ser enteros validos.'; MsgMenu='No se encontro menu.conf en la carpeta raiz.'; MsgSelect='Por favor selecciona un bezel de la lista primero.'; MsgSelectDelete='Para borrar un Marco, selecciona un Marco del listado.'; MsgSelectEnable='Tienes que seleccionar un Marco para poder activarlo.'; MsgSelectDisable='Tienes que seleccionar un Marco para poder desactivarlo.'; MsgSelectDeleteMulti='Tienes que seleccionar al menos un Marco para poder borrarlo.'; MsgAdded='Marco agregado.'; MsgUpdated='Marco actualizado.'; MsgDeleted='Marco eliminado.'; MsgDeletedMulti='Marcos seleccionados eliminados.'; MsgEnabledMulti='Marcos seleccionados activados.'; MsgDisabledMulti='Marcos seleccionados desactivados.'; MsgApplied='menu.conf actualizado correctamente.'; MsgNoBezels='No hay Marcos guardados. El bloque PERSONAL se elimina si existe.'; MsgCopied='PNG copiado a:'; MsgLoad='Datos recargados.'; MsgConfirmDelete='Deseas eliminar el Marco seleccionado?'; MsgConfirmDeleteMulti='Deseas eliminar los Marcos seleccionados?'; MsgConfirmTitle='Confirmar'; MsgConfirmDeleteTitle='Confirmar borrado'; MsgRestoreBaseDone='Se quitaron todos los Marcos BID y el menu PERSONAL del menu.conf.'; MsgImportDisabled='Los Marcos importados quedaron desactivados por defecto.'; MsgImportInvalid='user-bezels.json invalido: falta el arreglo Marcos.'; MsgPngCheckOk='Comprobacion de PNGs completa. Todos los PNGs fueron encontrados.'; MsgPngMissing='ADVERTENCIA: falta el archivo PNG: '; MsgSectionBezelsMissing='No se encontro la seccion BEZELS.'; MsgClearLineMissing='No se encontro la linea Clear Bezels / Borrar Marcos.'; OpenFilter='Archivos PNG (*.png)|*.png'
}
}

function T([string]$Key) { $script:Lang[$script:CurrentLang][$Key] }
function Write-Log([string]$Msg) { }

function New-DefaultData { @{ bezels = @() } }
function Load-Data {
    Ensure-Dirs
    if(-not (Test-Path -LiteralPath $script:JsonPath)) {
        $d = New-DefaultData
        [IO.File]::WriteAllText($script:JsonPath, ($d | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
        Write-Log ('Load-Data created new json')
        return $d
    }
    try {
        $raw = Get-Content -LiteralPath $script:JsonPath -Raw -Encoding UTF8
        if([string]::IsNullOrWhiteSpace($raw)){ return (New-DefaultData) }
        $d = $raw | ConvertFrom-Json
        if($null -eq $d.bezels){ $d.bezels = @() }
        foreach($b in @($d.bezels)) { if($b.PSObject.Properties['sourcePath']) { $b.PSObject.Properties.Remove('sourcePath') }; if(-not $b.PSObject.Properties['enabled']) { Add-Member -InputObject $b -NotePropertyName enabled -NotePropertyValue $true } }
        Write-Log ('Load-Data OK. Bezels ' + @($d.bezels).Count)
        return $d
    } catch {
        Write-Log ('Load-Data error: ' + $_.Exception.Message)
        return (New-DefaultData)
    }
}
function Save-Data($Data) {
    Ensure-Dirs
    foreach($b in @($Data.bezels)) { if($b.PSObject.Properties['sourcePath']) { $b.PSObject.Properties.Remove('sourcePath') }; if(-not $b.PSObject.Properties['enabled']) { Add-Member -InputObject $b -NotePropertyName enabled -NotePropertyValue $true } }
    [IO.File]::WriteAllText($script:JsonPath, ($Data | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
    Write-Log ('Save-Data OK. total ' + @($Data.bezels).Count)
}
function Get-HighestExistingBidNumber {
    $max = 0
    try {
        $d = Load-Data
        foreach($b in @($d.bezels)) {
            $bidText = [string]$b.bid
            if($bidText -match '^BID(\d+)$') {
                $n = [int]$matches[1]
                if($n -gt $max) { $max = $n }
            }
        }
    } catch {}
    return $max
}
function Get-NextBid {
    $n = (Get-HighestExistingBidNumber) + 1
    if($n -lt 1) { $n = 1 }
    $bid = 'BID' + $n
    Write-Log ('Get-NextBID ' + $bid)
    $bid
}
function Copy-PngToBezels([string]$SourcePath) {
    Ensure-Dirs
    $resolved = (Resolve-Path -LiteralPath $SourcePath).Path
    $srcDir = Split-Path -Parent $resolved
    if($srcDir.TrimEnd('\\') -ieq $script:BezelsDir.TrimEnd('\\')) {
        return @{ Copied=$false; FileName=[IO.Path]::GetFileName($resolved); FullPath=$resolved }
    }
    $destName = [IO.Path]::GetFileName($resolved)
    $destPath = Join-Path $script:BezelsDir $destName
    Copy-Item -LiteralPath $resolved -Destination $destPath -Force
    Write-Log ('PNG copied/replaced to ' + $destPath)
    @{ Copied=$true; FileName=$destName; FullPath=$destPath }
}
function Make-BezelLine($B) {
    '    ' + $B.name + "`tscript-message toggle-bezel `"" + $B.png + "`" `"" + $B.bid + "`" " + $B.x + ' ' + $B.y + ' ' + $B.w + ' ' + $B.h + " ; show-text `"" + $B.name + "`"`tchecked=get(`"user-data/active_bezel`")==`"" + $B.bid + "`""
}
function Remove-AllBidLines([string[]]$Lines) {
    $result = New-Object System.Collections.Generic.List[string]
    foreach($line in $Lines) {
        if($line -match 'toggle-bezel.+"BID\d+"') { continue }
        if($line -match '^\s*PERSONAL\s+disabled=true$') { continue }
        if($line -match '^# ---- PERSONAL ----$') { continue }
        if($line -match '^# ---- END PERSONAL ----$') { continue }
        [void]$result.Add($line)
    }
    return (Normalize-BezelSpacing $result.ToArray())
}

function Clear-CustomBezelsFromMenuConf {
    if(-not (Test-Path -LiteralPath $script:MenuConfPath)) { throw (T 'MsgMenu') }
    Ensure-Dirs
    $lines = [IO.File]::ReadAllLines($script:MenuConfPath, [Text.Encoding]::UTF8)
    $lines = Remove-AllBidLines $lines
    $lines = Normalize-BezelSpacing $lines
    $lines = Collapse-BlankLinesBeforeClearBezel $lines
    [IO.File]::WriteAllLines($script:MenuConfPath, $lines, [Text.Encoding]::UTF8)
    Write-Log ('Clear-CustomBezelsFromMenuConf OK')
}

function Remove-ExistingBidLines([string[]]$Lines, $Bezels) {
    $bidSet = @{}
    foreach($b in @($Bezels)) {
        if($b.bid) { $bidSet[[string]$b.bid] = $true }
    }
    $result = New-Object System.Collections.Generic.List[string]
    for($i=0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        $skip = $false
        foreach($bid in $bidSet.Keys) {
            if($line -match ('toggle-bezel.+"' + [regex]::Escape($bid) + '"')) {
                $skip = $true
                break
            }
        }
        if(-not $skip) { [void]$result.Add($line) }
    }
    return $result.ToArray()
}
function Get-ClearBezelLine([string[]]$Block) {
    foreach($line in $Block) {
        if($line -match 'clear-bezel silent') { return $line }
    }
    return '    🧹 Clear Bezels	script-message clear-bezel silent ; show-text "Bezels Cleared"	checked=get("user-data/active_bezel")=="none"'
}

function Normalize-BezelSpacing([string[]]$Lines) {
    $bezelHeader = -1
    $windowHeader = -1
    for($i=0; $i -lt $Lines.Count; $i++) {
        if($bezelHeader -lt 0 -and $Lines[$i] -match 'BEZELS|MARCOS') { $bezelHeader = $i; continue }
        if($bezelHeader -ge 0 -and $Lines[$i] -match '▶WINDOW◀') { $windowHeader = $i; break }
    }
    if($bezelHeader -lt 0 -or $windowHeader -lt 0) { return $Lines }

    $before = New-Object System.Collections.Generic.List[string]
    for($i=0; $i -lt $bezelHeader; $i++) { [void]$before.Add($Lines[$i]) }
    $block = @($Lines[$bezelHeader..($windowHeader-1)])
    $after = New-Object System.Collections.Generic.List[string]
    for($i=$windowHeader; $i -lt $Lines.Count; $i++) { [void]$after.Add($Lines[$i]) }

    $title = $block[0]
    $clearLine = Get-ClearBezelLine $block
    $groups = New-Object System.Collections.Generic.List[object]
    $current = $null

    for($i=1; $i -lt $block.Count; $i++) {
        $line = $block[$i]
        if($line -match '^\s*NSO:') {
            $current = [ordered]@{ header = $line; items = New-Object System.Collections.Generic.List[string] }
            $groups.Add($current)
            continue
        }
        if($line -match 'Clear Bezels|Borrar Marcos') { continue }
        if([string]::IsNullOrWhiteSpace($line)) { continue }
        if($null -ne $current) { [void]$current.items.Add($line) }
    }

    $out = New-Object System.Collections.Generic.List[string]
    foreach($line in $before) { [void]$out.Add($line) }
    [void]$out.Add($title)
    for($i=0; $i -lt $groups.Count; $i++) {
        $g = $groups[$i]
        [void]$out.Add($g.header)
        foreach($item in $g.items) { [void]$out.Add($item) }
        if($i -lt ($groups.Count - 1)) { [void]$out.Add('') }
    }

    while($out.Count -gt 0 -and [string]::IsNullOrWhiteSpace($out[$out.Count-1])) { $out.RemoveAt($out.Count-1) }

    $needsSpacer = $false
    if($groups.Count -gt 0) {
        $lastGroup = $groups[$groups.Count - 1]
        if($lastGroup.items.Count -gt 0) { $needsSpacer = $true }
    }
    if($needsSpacer) { [void]$out.Add('') }

    [void]$out.Add($clearLine)

    if($after.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($after[0])) { [void]$out.Add('') }
    foreach($line in $after) { [void]$out.Add($line) }
    return $out.ToArray()
}

function Collapse-BlankLinesBeforeClearBezel([string[]]$Lines) {
    $result = New-Object System.Collections.Generic.List[string]
    for($i=0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if($line -match 'clear-bezel silent') {
            while($result.Count -gt 0 -and [string]::IsNullOrWhiteSpace($result[$result.Count-1])) {
                $result.RemoveAt($result.Count-1)
            }
            if($result.Count -gt 0) { [void]$result.Add('') }
            [void]$result.Add($line)
            continue
        }
        [void]$result.Add($line)
    }
    return $result.ToArray()
}

function Remove-PersonalBlock([string[]]$Lines) {
    $result = New-Object System.Collections.Generic.List[string]
    foreach($line in $Lines) {
        if($line -match '^\s*PERSONAL\s+disabled=true$') { continue }
        if($line -match 'toggle-bezel.+"BID\d+"') { }
        [void]$result.Add($line)
    }
    return $result.ToArray()
}
function Find-SectionInsertIndex([string[]]$Lines, [string]$GroupKey) {
    $bezelHeader = -1
    for($i=0; $i -lt $Lines.Count; $i++) {
        if($Lines[$i] -match 'BEZELS|MARCOS') { $bezelHeader = $i; break }
    }
    if($bezelHeader -lt 0) { return -1 }

    $pattern = ''
    switch($GroupKey) {
        'NES'  { $pattern = 'NSO:.*NES.*Famicom' }
        'SNES' { $pattern = 'NSO:.*SNES.*GEN|NSO:.*Megadrive' }
        'GB'   { $pattern = 'NSO:.*GB.*GBC|NSO:.*GBC' }
        'GBA'  { $pattern = 'NSO:.*GBA' }
        'N64'  { $pattern = 'NSO:.*N64.*GC|NSO:.*GC.*N64' }
        default { return -1 }
    }

    $section = -1
    for($i=$bezelHeader+1; $i -lt $Lines.Count; $i++) {
        if($Lines[$i] -match $pattern) { $section = $i; break }
        if($i -gt $bezelHeader+1 -and $Lines[$i] -match '▶WINDOW◀') { break }
    }
    if($section -lt 0) { return -1 }

    $lastContent = $section
    for($i=$section+1; $i -lt $Lines.Count; $i++) {
        if($Lines[$i] -match 'Clear Bezels|Borrar Marcos') { return $i }
        if($i -gt $section+1 -and $Lines[$i] -match '^\s*NSO:') { return $i }
        if($i -gt $section+1 -and $Lines[$i] -match '▶WINDOW◀') { return $i }
        if(-not [string]::IsNullOrWhiteSpace($Lines[$i])) { $lastContent = $i }
    }
    return ($lastContent + 1)
}
function Apply-MenuConf($Bezels) {
    if(-not (Test-Path -LiteralPath $script:MenuConfPath)){ throw (T 'MsgMenu') }
    Ensure-Dirs
    $lines = [IO.File]::ReadAllLines($script:MenuConfPath, [Text.Encoding]::UTF8)
    Write-Log ('Apply start. Path ' + $script:MenuConfPath + ' Bezels ' + @($Bezels).Count)
    $hasBezelsHeader = $false
    foreach($line in $lines){ if($line -match 'BEZELS|MARCOS'){ $hasBezelsHeader = $true; break } }
    if(-not $hasBezelsHeader){ throw (T 'MsgSectionBezelsMissing') }
    $lines = Remove-PersonalBlock $lines
    $lines = Remove-ExistingBidLines $lines $Bezels
    $personal = New-Object System.Collections.ArrayList
    foreach($gk in @('N64','GBA','GB','SNES','NES')) {
        $groupBezels = @($Bezels | Where-Object { $_.group -eq $gk })
        if(@($groupBezels).Count -eq 0){ continue }
        $idx = Find-SectionInsertIndex $lines $gk
        if($idx -lt 0) {
            foreach($b in $groupBezels){ [void]$personal.Add($b) }
            continue
        }
        $insert = @()
        foreach($b in $groupBezels){ $insert += (Make-BezelLine $b) }
        $before = @(); $after = @()
        if($idx -gt 0){ $before = $lines[0..($idx-1)] }
        if($idx -lt $lines.Count){ $after = $lines[$idx..($lines.Count-1)] }
        while(@($before).Count -gt 0 -and [string]::IsNullOrWhiteSpace($before[-1])) {
            if(@($before).Count -eq 1) { $before = @(); break }
            $before = $before[0..(@($before).Count-2)]
        }
        while(@($after).Count -gt 0 -and [string]::IsNullOrWhiteSpace($after[0])) {
            if(@($after).Count -eq 1) { $after = @(); break }
            $after = $after[1..(@($after).Count-1)]
        }
        $insert += ''
        $lines = @($before + $insert + $after)
    }
    foreach($b in @($Bezels | Where-Object { $_.group -eq 'PERSONAL' -or [string]::IsNullOrWhiteSpace($_.group) })) { [void]$personal.Add($b) }
    if($personal.Count -gt 0) {
        $clearIdx = -1
        for($i=0; $i -lt $lines.Count; $i++) { if($lines[$i] -match 'clear-bezel silent'){ $clearIdx = $i; break } }
        if($clearIdx -lt 0){ throw (T 'MsgClearLineMissing') }
        $block = @()
        $block += "    PERSONAL	disabled=true"
        foreach($b in $personal){ $block += (Make-BezelLine $b) }
        $block += ''
        $before = @(); $after = @()
        if($clearIdx -gt 0){ $before = $lines[0..($clearIdx-1)] }
        if($clearIdx -lt $lines.Count){ $after = $lines[$clearIdx..($lines.Count-1)] }
        $lines = @($before + $block + $after)
    }
    $lines = Normalize-BezelSpacing $lines
    $lines = Collapse-BlankLinesBeforeClearBezel $lines
    [IO.File]::WriteAllLines($script:MenuConfPath, $lines, [Text.UTF8Encoding]::new($false))
    Write-Log ('Apply OK')
}

# ============================================================
#  COLORS, FONTS, AND UI HELPERS
# ============================================================
$script:BG=[Drawing.Color]::FromArgb(20,16,28)
$script:SURFACE=[Drawing.Color]::FromArgb(33,26,44)
$script:CARD=[Drawing.Color]::FromArgb(45,36,60)
$script:ACCENT=[Drawing.Color]::FromArgb(99,179,237)
$script:ACCENT2=[Drawing.Color]::FromArgb(72,219,155)
$script:ACCENT3=[Drawing.Color]::FromArgb(241,166,48)
$script:TEXT=[Drawing.Color]::FromArgb(232,226,245)
$script:MUTED=[Drawing.Color]::FromArgb(170,156,196)
$script:ERRORC=[Drawing.Color]::FromArgb(176,48,48)
$script:SUCCESS=[Drawing.Color]::FromArgb(72,199,116)
$FontTitle=New-Object Drawing.Font('Segoe UI',16,[Drawing.FontStyle]::Bold)
$FontSub=New-Object Drawing.Font('Segoe UI',9)
$FontBold=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
$FontBtn=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$FontSmall=New-Object Drawing.Font('Segoe UI',8)
$FontLangBtn=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)

function Style-Btn($btn,$bg,$fg){ $btn.BackColor=$bg; $btn.ForeColor=$fg; $btn.Font=$FontBtn; $btn.FlatStyle='Flat'; $btn.FlatAppearance.BorderSize=0; $btn.Cursor='Hand' }
function Style-LangBtn($btn,[bool]$active){ $btn.Font=$FontLangBtn; $btn.FlatStyle='Flat'; $btn.FlatAppearance.BorderSize=1; $btn.Cursor='Hand'; if($active){$btn.BackColor=$script:ACCENT;$btn.ForeColor=$script:BG;$btn.FlatAppearance.BorderColor=$script:ACCENT}else{$btn.BackColor=$script:SURFACE;$btn.ForeColor=$script:MUTED;$btn.FlatAppearance.BorderColor=$script:MUTED} }
function New-Lbl([string]$text,[int]$x,[int]$y,[int]$w,[int]$h,$font,$color){ $l=New-Object Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h); $l.Font=$font; $l.ForeColor=$color; $l.BackColor=[Drawing.Color]::Transparent; $l }
function New-TB([int]$x,[int]$y,[int]$w){ $t=New-Object Windows.Forms.TextBox; $t.Location=New-Object Drawing.Point($x,$y); $t.Size=New-Object Drawing.Size($w,24); $t.BackColor=$script:CARD; $t.ForeColor=$script:TEXT; $t }
function New-CB([int]$x,[int]$y,[int]$w){ $c=New-Object Windows.Forms.ComboBox; $c.Location=New-Object Drawing.Point($x,$y); $c.Size=New-Object Drawing.Size($w,26); $c.DropDownStyle='DropDownList'; $c.BackColor=$script:CARD; $c.ForeColor=$script:TEXT; $c.FlatStyle='Flat'; $c }

$script:OwnerForm = New-Object Windows.Forms.Form
$script:OwnerForm.ShowInTaskbar = $false
$script:OwnerForm.FormBorderStyle = 'FixedToolWindow'
$script:OwnerForm.StartPosition = 'Manual'
$script:OwnerForm.Size = New-Object Drawing.Size(1,1)
$script:OwnerForm.Location = New-Object Drawing.Point(-32000,-32000)
$script:OwnerForm.Opacity = 0
$script:OwnerForm.ShowIcon = $false

$form=New-Object Windows.Forms.Form
$form.Text=T 'Title'
try { $appIcon = Get-AppIcon; if($appIcon){ $form.Icon = $appIcon } } catch {}
$form.ClientSize=New-Object Drawing.Size(1200,700)
$form.StartPosition='CenterScreen'
$form.ShowInTaskbar = $true
$form.FormBorderStyle='FixedSingle'
$form.MaximizeBox=$false
$form.BackColor=$script:BG
$form.ForeColor=$script:TEXT
$form.Font=$FontSub
try { if($script:OwnerForm){ $form.Owner = $script:OwnerForm } } catch {}

$pHeader=New-Object Windows.Forms.Panel
$pHeader.Location=New-Object Drawing.Point(0,0)
$pHeader.Size=New-Object Drawing.Size(1200,70)
$pHeader.BackColor=$script:SURFACE
$form.Controls.Add($pHeader)
$lTitle=New-Lbl 'MPV-SW-Capture' 20 4 340 30 $FontTitle $script:ACCENT
$lSub=New-Lbl (T 'Header') 22 36 440 20 $FontSub $script:MUTED
$lLang=New-Lbl (T 'LangLabel') 980 10 88 18 $FontSmall $script:MUTED
$btnEN=New-Object Windows.Forms.Button; $btnEN.Text='EN'; $btnEN.Location=New-Object Drawing.Point(1072,6); $btnEN.Size=New-Object Drawing.Size(50,26); Style-LangBtn $btnEN $true
$btnES=New-Object Windows.Forms.Button; $btnES.Text='ES'; $btnES.Location=New-Object Drawing.Point(1128,6); $btnES.Size=New-Object Drawing.Size(50,26); Style-LangBtn $btnES $false
$pHeader.Controls.AddRange(@($lTitle,$lSub,$lLang,$btnEN,$btnES))

$gbFiles=New-Object Windows.Forms.GroupBox
$gbFiles.Location=New-Object Drawing.Point(14,80); $gbFiles.Size=New-Object Drawing.Size(1170,130); $gbFiles.ForeColor=$script:TEXT; $gbFiles.BackColor=$script:BG
$form.Controls.Add($gbFiles)
$lFilesNote=New-Lbl '' 14 18 1130 28 $FontSmall $script:MUTED
$lRoot=New-Lbl '' 14 50 560 16 $FontSmall $script:TEXT
$lTools=New-Lbl '' 14 68 560 16 $FontSmall $script:TEXT
$lBezels=New-Lbl '' 14 104 560 16 $FontSmall $script:TEXT
$lMenu=New-Lbl '' 590 50 560 16 $FontSmall $script:TEXT
$lJson=New-Lbl '' 590 68 560 16 $FontSmall $script:TEXT
$gbFiles.Controls.AddRange(@($lFilesNote,$lRoot,$lTools,$lBezels,$lMenu,$lJson))

$gbList=New-Object Windows.Forms.GroupBox
$gbList.Location=New-Object Drawing.Point(14,220)
$gbList.Size=New-Object Drawing.Size(500,434)
$gbList.ForeColor=$script:TEXT
$gbList.BackColor=$script:BG
$form.Controls.Add($gbList)

$lListHint=New-Lbl '' 14 330 470 16 $FontSmall $script:ACCENT3
$gbList.Controls.Add($lListHint)

$listBezels=New-Object Windows.Forms.ListBox
$listBezels.Location=New-Object Drawing.Point(14,54)
$listBezels.Size=New-Object Drawing.Size(470,276)
$listBezels.BackColor=$script:CARD
$listBezels.ForeColor=$script:TEXT
$listBezels.Font=New-Object Drawing.Font('Segoe UI Symbol',10.5,[Drawing.FontStyle]::Regular)
$listBezels.BorderStyle='FixedSingle'
$listBezels.IntegralHeight=$false
$listBezels.HorizontalScrollbar=$true
$listBezels.SelectionMode='MultiExtended'
$listBezels.DrawMode='OwnerDrawFixed'
$listBezels.ItemHeight=22
$gbList.Controls.Add($listBezels)

$listBezels.Add_DrawItem({
    param($sender,$e)
    if($e.Index -lt 0){ return }
    $selected = (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -ne 0)
    $item = [string]$sender.Items[$e.Index]
    $bg = if($selected){ [System.Drawing.SystemColors]::Highlight } else { $script:CARD }
    $isEnabled = $item.StartsWith('[enabled]')
    $fg = if($selected){ [System.Drawing.SystemColors]::HighlightText } elseif($isEnabled){ [System.Drawing.Color]::FromArgb(92, 220, 132) } elseif($item.StartsWith('[disabled]')){ [System.Drawing.Color]::FromArgb(255, 104, 104) } else { $script:TEXT }
    $drawFont = if($isEnabled -and -not $selected){ New-Object System.Drawing.Font($sender.Font, [System.Drawing.FontStyle]::Bold) } else { $sender.Font }
    $brush = New-Object System.Drawing.SolidBrush($bg)
    try {
        $e.Graphics.FillRectangle($brush, $e.Bounds)
        [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics, $item, $drawFont, $e.Bounds, $fg, [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::NoPrefix -bor [System.Windows.Forms.TextFormatFlags]::NoPadding)
        $e.DrawFocusRectangle()
    } finally {
        if($drawFont -ne $sender.Font){ $drawFont.Dispose() }
        $brush.Dispose()
    }
})

$btnReload=New-Object Windows.Forms.Button
$btnReload.Location=New-Object Drawing.Point(14,20)
$btnReload.Size=New-Object Drawing.Size(140,30)
Style-Btn $btnReload $script:ACCENT $script:BG

$btnImport=New-Object Windows.Forms.Button
$btnImport.Location=New-Object Drawing.Point(160,20)
$btnImport.Size=New-Object Drawing.Size(324,30)
Style-Btn $btnImport $script:ACCENT2 $script:BG

$btnEnableSel=New-Object Windows.Forms.Button
$btnEnableSel.Location=New-Object Drawing.Point(14,348)
$btnEnableSel.Size=New-Object Drawing.Size(154,28)
Style-Btn $btnEnableSel $script:ACCENT2 $script:BG

$btnDisableSel=New-Object Windows.Forms.Button
$btnDisableSel.Location=New-Object Drawing.Point(174,348)
$btnDisableSel.Size=New-Object Drawing.Size(154,28)
Style-Btn $btnDisableSel $script:ERRORC $script:BG

$btnCheckPng=New-Object Windows.Forms.Button
$btnCheckPng.Location=New-Object Drawing.Point(334,348)
$btnCheckPng.Size=New-Object Drawing.Size(150,28)
Style-Btn $btnCheckPng $script:ACCENT3 $script:BG

$btnDeleteSel=New-Object Windows.Forms.Button
$btnDeleteSel.Location=New-Object Drawing.Point(14,380)
$btnDeleteSel.Size=New-Object Drawing.Size(154,28)
Style-Btn $btnDeleteSel $script:ERRORC $script:TEXT

$gbList.Controls.AddRange(@($btnReload,$btnImport,$btnEnableSel,$btnDisableSel,$btnCheckPng,$btnDeleteSel))

$gbEdit=New-Object Windows.Forms.GroupBox
$gbEdit.Location=New-Object Drawing.Point(528,220); $gbEdit.Size=New-Object Drawing.Size(656,434); $gbEdit.ForeColor=$script:TEXT; $gbEdit.BackColor=$script:BG
$form.Controls.Add($gbEdit)
$lName=New-Lbl '' 14 30 110 18 $FontBold $script:TEXT
$tbName=New-TB 132 28 494
$lPng=New-Lbl '' 14 66 110 18 $FontBold $script:TEXT
$tbPng=New-TB 132 64 370
$btnBrowse=New-Object Windows.Forms.Button
$btnBrowse.Location=New-Object Drawing.Point(510,62); $btnBrowse.Size=New-Object Drawing.Size(116,28); Style-Btn $btnBrowse $script:ACCENT $script:BG
$chkCopy=New-Object Windows.Forms.CheckBox
$chkCopy.Location=New-Object Drawing.Point(132,94); $chkCopy.Size=New-Object Drawing.Size(290,22); $chkCopy.ForeColor=$script:TEXT; $chkCopy.BackColor=$script:BG; $chkCopy.Checked=$true
$chkEnabled=New-Object Windows.Forms.CheckBox
$chkEnabled.Location=New-Object Drawing.Point(430,94); $chkEnabled.Size=New-Object Drawing.Size(180,22); $chkEnabled.ForeColor=$script:TEXT; $chkEnabled.BackColor=$script:BG; $chkEnabled.Checked=$true
$lGroup=New-Lbl '' 14 130 110 18 $FontBold $script:TEXT
$cbGroup=New-CB 132 128 490
$lPreset=New-Lbl '' 14 168 110 18 $FontBold $script:TEXT
$cbPreset=New-CB 132 166 490
$lX=New-Lbl '' 14 212 18 18 $FontBold $script:TEXT
$tbX=New-TB 36 210 90
$lY=New-Lbl '' 144 212 18 18 $FontBold $script:TEXT
$tbY=New-TB 166 210 90
$lW=New-Lbl '' 280 212 50 18 $FontBold $script:TEXT
$tbW=New-TB 334 210 100
$lH=New-Lbl '' 452 212 40 18 $FontBold $script:TEXT
$tbH=New-TB 496 210 100
$btnAdd=New-Object Windows.Forms.Button
$btnAdd.Location=New-Object Drawing.Point(14,260); $btnAdd.Size=New-Object Drawing.Size(180,34); Style-Btn $btnAdd $script:ACCENT2 $script:BG
$btnUpdate=New-Object Windows.Forms.Button
$btnUpdate.Location=New-Object Drawing.Point(204,260); $btnUpdate.Size=New-Object Drawing.Size(204,34); Style-Btn $btnUpdate $script:ACCENT $script:BG
$btnDelete=New-Object Windows.Forms.Button
$btnDelete.Location=New-Object Drawing.Point(418,260); $btnDelete.Size=New-Object Drawing.Size(204,34); Style-Btn $btnDelete $script:ERRORC $script:BG
$btnClear=New-Object Windows.Forms.Button
$btnClear.Location=New-Object Drawing.Point(14,304); $btnClear.Size=New-Object Drawing.Size(180,34); Style-Btn $btnClear $script:ACCENT3 $script:BG
$btnRestoreBase=New-Object Windows.Forms.Button
$btnRestoreBase.Location=New-Object Drawing.Point(204,304); $btnRestoreBase.Size=New-Object Drawing.Size(204,34); Style-Btn $btnRestoreBase $script:ERRORC $script:BG
$btnApply=New-Object Windows.Forms.Button
$btnApply.Location=New-Object Drawing.Point(418,304); $btnApply.Size=New-Object Drawing.Size(204,34); Style-Btn $btnApply $script:ACCENT2 $script:BG
$lStatus=New-Lbl '' 14 354 610 66 $FontSub $script:MUTED
$lStatus.BorderStyle='FixedSingle'; $lStatus.BackColor=$script:CARD
$gbEdit.Controls.AddRange(@($lName,$tbName,$lPng,$tbPng,$btnBrowse,$chkCopy,$chkEnabled,$lGroup,$cbGroup,$lPreset,$cbPreset,$lX,$tbX,$lY,$tbY,$lW,$tbW,$lH,$tbH,$btnAdd,$btnUpdate,$btnDelete,$btnClear,$btnRestoreBase,$btnApply,$lStatus))
$ofd=New-Object Windows.Forms.OpenFileDialog

$script:LastStatusKey = 'StatusReady'
$script:LastStatusExtra = ''
function Set-Status([string]$txt,[Drawing.Color]$color){ $script:LastStatusKey = $null; $script:LastStatusExtra=''; $lStatus.Text=$txt; $lStatus.ForeColor=$color }
function Set-StatusKey([string]$key,[Drawing.Color]$color){ $script:LastStatusKey = $key; $script:LastStatusExtra=''; $lStatus.Text = (T $key); $lStatus.ForeColor=$color }
function Set-StatusKeyEx([string]$key,[string]$extra,[Drawing.Color]$color){ $script:LastStatusKey = $key; $script:LastStatusExtra = $extra; $lStatus.Text = (T $key) + $extra; $lStatus.ForeColor=$color }
function Refresh-StatusLanguage { if(-not [string]::IsNullOrWhiteSpace($script:LastStatusKey)){ $lStatus.Text = (T $script:LastStatusKey) + $script:LastStatusExtra } }
function Get-PngDisplayName([string]$png){ if([string]::IsNullOrWhiteSpace($png)){ return '' }; try { return [IO.Path]::GetFileName($png.Trim()) } catch { return $png } }
function Get-UiLogText([string]$msg){
    if([string]::IsNullOrWhiteSpace($msg)){ return $msg }
    $map = @{
        'Load-Data created new json' = @{ EN='Load-Data created new json'; ES='Load-Data creó un json nuevo' }
        'Load-Data OK.' = @{ EN='Load-Data OK.'; ES='Load-Data OK.' }
        'Load-Data error:' = @{ EN='Load-Data error:'; ES='Error en Load-Data:' }
        'Save-Data OK.' = @{ EN='Save-Data OK.'; ES='Save-Data OK.' }
        'Get-NextBID' = @{ EN='Get-NextBID'; ES='Siguiente BID' }
        'PNG copied/replaced to' = @{ EN='PNG copied/replaced to'; ES='PNG copiado/reemplazado en' }
        'Clear-CustomBezelsFromMenuConf OK' = @{ EN='Clear-CustomBezelsFromMenuConf OK'; ES='Clear-CustomBezelsFromMenuConf OK' }
        'Apply start.' = @{ EN='Apply start.'; ES='Inicio de Apply.' }
        'Apply OK' = @{ EN='Apply OK'; ES='Apply OK' }
        'Add error:' = @{ EN='Add error:'; ES='Error al agregar:' }
        'Update error:' = @{ EN='Update error:'; ES='Error al actualizar:' }
        'Delete error:' = @{ EN='Delete error:'; ES='Error al eliminar:' }
        'Apply error:' = @{ EN='Apply error:'; ES='Error al aplicar:' }
        'ERROR RestoreBase' = @{ EN='ERROR RestoreBase'; ES='ERROR RestoreBase' }
        'Agregado' = @{ EN='Added'; ES='Agregado' }
        'Actualizado' = @{ EN='Updated'; ES='Actualizado' }
        'Eliminado' = @{ EN='Deleted'; ES='Eliminado' }
        'STARTUP FINAL-PURPLE-BG-ORIGBUTTONS' = @{ EN='STARTUP FINAL-PURPLE-BG-ORIGBUTTONS'; ES='INICIO FINAL-PURPLE-BG-ORIGBUTTONS' }
        'No bezels selected.' = @{ EN='No bezels selected.'; ES='No hay bezels seleccionados.' }
        'WARNING: missing PNG file:' = @{ EN='WARNING: missing PNG file:'; ES='ADVERTENCIA: falta el archivo PNG:' }
        'Invalid user-bezels.json: missing bezels array.' = @{ EN='Invalid user-bezels.json: missing bezels array.'; ES='user-bezels.json inválido: falta el arreglo bezels.' }
        'BEZELS section was not found.' = @{ EN='BEZELS section was not found.'; ES='No se encontró la sección BEZELS.' }
        'Clear Bezels / Borrar Marcos line was not found.' = @{ EN='Clear Bezels / Borrar Marcos line was not found.'; ES='No se encontró la línea Clear Bezels / Borrar Marcos.' }
    }
    foreach($k in $map.Keys){
        if($msg.StartsWith($k)){
            $prefix = $map[$k][$script:CurrentLang]
            return ($prefix + $msg.Substring($k.Length))
        }
    }
    return $msg
}
function Sync-Paths {
    $lFilesNote.Text = T 'FilesNote'
    $lRoot.Text = (T 'Root') + ': ' + $script:RootDir
    $lTools.Text = (T 'Tools') + ': ' + $script:ToolsDir
    $lBezels.Text = (T 'Bezels') + ': ' + $script:BezelsDir
    $lMenu.Text = (T 'Menu') + ': ' + $script:MenuConfPath
    $lJson.Text = (T 'Json') + ': ' + $script:JsonPath
}
function Fill-Groups {
    $cbGroup.Items.Clear()
    foreach($g in $script:Groups){ [void]$cbGroup.Items.Add($(if($script:CurrentLang -eq 'ES'){$g.ES}else{$g.EN})) }
    if($cbGroup.Items.Count -gt 0){ $cbGroup.SelectedIndex = 0 }
}
function Fill-Presets {
    $cbPreset.Items.Clear()
    $idx = $cbGroup.SelectedIndex
    if($idx -lt 0){ $idx = 0 }
    $g = $script:Groups[$idx]
    if($g.Key -ne 'PERSONAL'){
        [void]$cbPreset.Items.Add((T 'PresetGroup'))
        [void]$cbPreset.Items.Add((T 'PresetCustom'))
    } else {
        [void]$cbPreset.Items.Add((T 'PresetCustom'))
    }
    $cbPreset.SelectedIndex = 0
}
function Apply-GroupPreset {
    $idx = $cbGroup.SelectedIndex
    if($idx -lt 0){ return }
    $g = $script:Groups[$idx]
    if($g.Key -ne 'PERSONAL' -and $cbPreset.SelectedIndex -eq 0){ $tbX.Text=$g.X; $tbY.Text=$g.Y; $tbW.Text=$g.W; $tbH.Text=$g.H }
}
function Get-GroupKey { if($cbGroup.SelectedIndex -ge 0){ $script:Groups[$cbGroup.SelectedIndex].Key } else { 'PERSONAL' } }
function Group-Index([string]$key){ for($i=0;$i -lt $script:Groups.Count;$i++){ if($script:Groups[$i].Key -eq $key){ return $i } } ; 0 }
function Test-PngExists([string]$png){ if([string]::IsNullOrWhiteSpace($png)){ return $false }; $name=[IO.Path]::GetFileName(($png.Trim())); if([string]::IsNullOrWhiteSpace($name)){ return $false }; $dirs=@($script:BezelsDir); try { $rootBezels = Join-Path $script:RootDir 'bezels'; if($rootBezels -and $rootBezels -ne $script:BezelsDir){ $dirs += $rootBezels } } catch {} foreach($dir in @($dirs | Select-Object -Unique)){ if(-not (Test-Path -LiteralPath $dir)){ continue }; $p1=Join-Path $dir $name; if(Test-Path -LiteralPath $p1){ return $true }; if($name -notmatch '\.(png|PNG)$'){ $p2=Join-Path $dir ($name + '.png'); if(Test-Path -LiteralPath $p2){ return $true } }; try { foreach($it in @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue)){ if($it.Name -ieq $name){ return $true }; if(($name -notmatch '\.(png|PNG)$') -and ($it.Name -ieq ($name + '.png'))){ return $true } } } catch {} } return $false }
$null = $true
function Safe-Symbol([bool]$ok){ if($ok){ return '✓' } else { return 'X' } }
function Make-ListText($b){ $nm=if($b.PSObject.Properties['name']){ [string]$b.name } else { '' }; if([string]::IsNullOrWhiteSpace($nm)){ $nm=(if($script:CurrentLang -eq 'ES'){'(sin nombre)'}else{'(no name)'}) }; $nm=$nm -replace [char]0xFE0F,''; $nm=$nm.Replace('⌗','#'); $bid=if($b.PSObject.Properties['bid']){ [string]$b.bid } else { '' }; if([string]::IsNullOrWhiteSpace($bid)){ $bid='?' }; $state=if($b.enabled -eq $false){'[disabled]'}else{'[enabled]'}; $png=if($b.PSObject.Properties['png']){ [string]$b.png } else { '' }; if([string]::IsNullOrWhiteSpace($png)){ $png=(if($script:CurrentLang -eq 'ES'){'(sin png)'}else{'(no png)'}) }; $state + ' [' + $bid + '] ' + $nm + ' ' + $png }
function Refresh-List {
    $data=Load-Data
    $listBezels.Items.Clear()

    foreach($b in @($data.bezels)){
        [void]$listBezels.Items.Add((Make-ListText $b))
    }

    $listBezels.ForeColor = $script:TEXT
    $listBezels.BackColor = $script:CARD
    $listBezels.Font = New-Object Drawing.Font('Segoe UI',10.5,[Drawing.FontStyle]::Regular)

    Set-StatusKey 'StatusReady' $script:MUTED
}
function Clear-Form { $script:CurrentEditBid=$null; $tbName.Text=''; $tbPng.Text=''; $tbX.Text=''; $tbY.Text=''; $tbW.Text=''; $tbH.Text=''; $cbGroup.SelectedIndex=0; $chkEnabled.Checked=$true; Fill-Presets; $listBezels.ClearSelected() }
function Apply-Lang([string]$lang){ $script:CurrentLang=$lang; Style-LangBtn $btnEN ($lang -eq 'EN'); Style-LangBtn $btnES ($lang -eq 'ES'); $form.Text=T 'Title'; $lSub.Text=T 'Header'; $lLang.Text=T 'LangLabel'; $gbFiles.Text=T 'Files'; $gbList.Text=T 'List'; $lListHint.Text=T 'ListHint'; $gbList.ForeColor=$script:TEXT; $gbList.BackColor=$script:BG; $gbEdit.Text=T 'Editor'; $lName.Text=T 'Name'; $lPng.Text=T 'Png'; $btnBrowse.Text=T 'Browse'; $chkCopy.Text=T 'Copy'; $chkEnabled.Text=T 'EnableBezel'; $lGroup.Text=T 'Group'; $lPreset.Text=T 'Preset'; $lX.Text=T 'X'; $lY.Text=T 'Y'; $lW.Text=T 'W'; $lH.Text=T 'H'; $btnAdd.Text=T 'Add'; $btnUpdate.Text=T 'Update'; $btnDelete.Text=T 'Delete'; $btnClear.Text=T 'Clear'; $btnRestoreBase.Text=if($lang -eq 'ES'){ T 'RestoreBaseES' } else { T 'RestoreBase' }; $btnDeleteSel.Text=T 'DeleteSelected'; $btnApply.Text=T 'Apply'; $btnReload.Text=T 'Reload'; $btnImport.Text=T 'Import'; $btnEnableSel.Text=T 'EnableSelected'; $btnDisableSel.Text=T 'DisableSelected'; $btnCheckPng.Text=T 'CheckPngs'; $btnDeleteSel.Text=T 'DeleteSelected'; $ofd.Filter=T 'OpenFilter'; Sync-Paths; Fill-Groups; Fill-Presets; Refresh-StatusLanguage }
function Read-FormBezel {
    $name = $tbName.Text.Trim(); if([string]::IsNullOrWhiteSpace($name)){ throw (T 'MsgName') }
    $pngPath = $tbPng.Text.Trim()
    $pngExists = $false
    $pngInBezels = $false
    $pngFromExternalPath = $false
    $x=0;$y=0;$w=0;$h=0
    if(-not [int]::TryParse($tbX.Text.Trim(),[ref]$x)){ throw (T 'MsgNums') }
    if(-not [int]::TryParse($tbY.Text.Trim(),[ref]$y)){ throw (T 'MsgNums') }
    if(-not [int]::TryParse($tbW.Text.Trim(),[ref]$w)){ throw (T 'MsgNums') }
    if(-not [int]::TryParse($tbH.Text.Trim(),[ref]$h)){ throw (T 'MsgNums') }
    $copyResult = $null; $pngFile=''
    if(-not [string]::IsNullOrWhiteSpace($pngPath) -and (Test-Path -LiteralPath $pngPath)){
        $pngFromExternalPath = $true
        if($chkCopy.Checked){
            $copyResult = Copy-PngToBezels $pngPath
            $pngFile = $copyResult.FileName
            $pngExists = $true
            $pngInBezels = $true
        } else {
            $pngFile = [IO.Path]::GetFileName((Resolve-Path -LiteralPath $pngPath).Path)
            $pngExists = $true
        }
    } else {
        $pngFile = Get-PngDisplayName $pngPath
        $pngInBezels = Test-PngExists $pngFile
        $pngExists = $pngInBezels
        $copyResult = $null
    }
    @{ name=$name; sourcePath=$pngPath; png=$pngFile; group=(Get-GroupKey); x=$x; y=$y; w=$w; h=$h; copyResult=$copyResult; pngExists=$pngExists; pngInBezels=$pngInBezels; pngFromExternalPath=$pngFromExternalPath }
}
function Build-StatusExtra($copyResult,$pngExists,$pngFile){ $msg=''; if($copyResult -and $copyResult.Copied){ $msg += "`r`n" + (T 'MsgCopied') + ' ' + $copyResult.FullPath }; if(-not $pngExists -and -not [string]::IsNullOrWhiteSpace($pngFile)){ $msg += "`r`n" + (T 'MsgPngMissing') + $pngFile }; return $msg }

$cbGroup.Add_SelectedIndexChanged({ Fill-Presets; Apply-GroupPreset })
$cbPreset.Add_SelectedIndexChanged({ Apply-GroupPreset })
$btnBrowse.Add_Click({ if($ofd.ShowDialog() -eq 'OK'){ $tbPng.Text = $ofd.FileName } })
$listBezels.Add_SelectedIndexChanged({ if($listBezels.SelectedIndex -lt 0){ return }; $data=Load-Data; $all=@($data.bezels); if($listBezels.SelectedIndex -ge $all.Count){ return }; $b=$all[$listBezels.SelectedIndex]; $script:CurrentEditBid=[string]$b.bid; $tbName.Text=[string]$b.name; $tbPng.Text=[string]$b.png; $tbX.Text=[string]$b.x; $tbY.Text=[string]$b.y; $tbW.Text=[string]$b.w; $tbH.Text=[string]$b.h; $cbGroup.SelectedIndex=(Group-Index $(if([string]::IsNullOrWhiteSpace($b.group)){'PERSONAL'}else{$b.group})); $chkEnabled.Checked=($b.enabled -ne $false); Fill-Presets })
$btnAdd.Add_Click({ try { $f=Read-FormBezel; $data=Load-Data; $bid=Get-NextBid; $entry=[pscustomobject]@{ bid=$bid; name=$f.name; png=$f.png; group=$f.group; x=$f.x; y=$f.y; w=$f.w; h=$f.h; enabled=$true }; $data=Load-Data; $data.bezels=@(@($data.bezels)+$entry); Save-Data $data; Refresh-List; Clear-Form; Set-StatusKeyEx 'MsgAdded' (Build-StatusExtra $f.copyResult $f.pngExists $f.png) $script:SUCCESS; Write-Log (Get-UiLogText ('Agregado ' + $bid + ' group=' + $f.group)) } catch { Set-Status $_.Exception.Message $script:ERRORC; Write-Log (Get-UiLogText ('Add error: ' + $_.Exception.Message)) } })
$btnUpdate.Add_Click({ try { if([string]::IsNullOrWhiteSpace($script:CurrentEditBid)){ throw (T 'MsgSelect') }; $f=Read-FormBezel; $data=Load-Data; $found=$false; foreach($b in @($data.bezels)){ if([string]$b.bid -eq $script:CurrentEditBid){ $b.name=$f.name; $b.png=$f.png; $b.group=$f.group; $b.x=$f.x; $b.y=$f.y; $b.w=$f.w; $b.h=$f.h; $b.enabled=$chkEnabled.Checked; if($b.PSObject.Properties['sourcePath']) { $b.PSObject.Properties.Remove('sourcePath') }; $found=$true; break } }; if(-not $found){ throw (T 'MsgSelect') }; Save-Data $data; Refresh-List; Set-StatusKeyEx 'MsgUpdated' (Build-StatusExtra $f.copyResult $f.pngExists $f.png) $script:SUCCESS; Write-Log (Get-UiLogText ('Actualizado ' + $script:CurrentEditBid + ' group=' + $f.group)) } catch { Set-Status $_.Exception.Message $script:ERRORC; Write-Log (Get-UiLogText ('Update error: ' + $_.Exception.Message)) } })
$btnDelete.Add_Click({ try { if($listBezels.SelectedIndex -lt 0 -or [string]::IsNullOrWhiteSpace($script:CurrentEditBid)){ throw (T 'MsgSelect') }; $ans=[Windows.Forms.MessageBox]::Show((T 'MsgConfirmDelete'),(T 'MsgConfirmTitle'),[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question); if($ans -ne [Windows.Forms.DialogResult]::Yes){ return }; $data=Load-Data; $new=@(); foreach($b in @($data.bezels)){ if([string]$b.bid -ne $script:CurrentEditBid){ $new += $b } }; $data.bezels=$new; Save-Data $data; Refresh-List; Clear-Form; Set-StatusKey 'MsgDeleted' $script:SUCCESS; Write-Log (Get-UiLogText ('Eliminado ' + $script:CurrentEditBid)) } catch { Set-Status $_.Exception.Message $script:ERRORC; Write-Log (Get-UiLogText ('Delete error: ' + $_.Exception.Message)) } })
$btnClear.Add_Click({ Clear-Form; Set-StatusKey 'StatusReady' $script:MUTED })
$btnReload.Add_Click({ Refresh-List; Sync-Paths; Set-StatusKey 'MsgLoad' $script:SUCCESS })
function Import-OtherUserBezels { $ofdImport=New-Object Windows.Forms.OpenFileDialog; $ofdImport.Filter=(T 'JsonFilter'); if($ofdImport.ShowDialog() -ne 'OK'){ return }; try { $raw=Get-Content -LiteralPath $ofdImport.FileName -Raw -Encoding UTF8; $obj=$raw | ConvertFrom-Json; if($null -eq $obj.bezels){ throw (T 'MsgImportInvalid') }; $data=Load-Data; $next=(Get-HighestExistingBidNumber)+1; foreach($b in @($obj.bezels)){ $entry=[pscustomobject]@{ bid=('BID'+$next); name=[string]$b.name; png=[string]$b.png; group=$(if([string]::IsNullOrWhiteSpace([string]$b.group)){'PERSONAL'}else{[string]$b.group}); x=[int]$b.x; y=[int]$b.y; w=[int]$b.w; h=[int]$b.h; enabled=$false }; $data.bezels=@(@($data.bezels)+$entry); $next++ }; Save-Data $data; Refresh-List; Set-StatusKey 'MsgImportDisabled' $script:SUCCESS } catch { Set-Status $_.Exception.Message $script:ERRORC } }
$btnImport.Add_Click({ Import-OtherUserBezels })
$btnEnableSel.Add_Click({ try { $sel=@($listBezels.SelectedIndices); if($sel.Count -eq 0){ Set-StatusKey 'MsgSelectEnable' $script:ERRORC; return }; $data=Load-Data; foreach($i in $sel){ $data.bezels[$i].enabled=$true }; Save-Data $data; Refresh-List; Set-StatusKey 'MsgEnabledMulti' $script:SUCCESS } catch { Set-Status $_.Exception.Message $script:ERRORC } })
$btnDisableSel.Add_Click({ try { $sel=@($listBezels.SelectedIndices); if($sel.Count -eq 0){ Set-StatusKey 'MsgSelectDisable' $script:ERRORC; return }; $data=Load-Data; foreach($i in $sel){ $data.bezels[$i].enabled=$false }; Save-Data $data; Refresh-List; Set-StatusKey 'MsgDisabledMulti' $script:SUCCESS } catch { Set-Status $_.Exception.Message $script:ERRORC } })
$btnDeleteSel.Add_Click({ try { $sel=@(); foreach($i in $listBezels.SelectedIndices){ $sel += [int]$i }; $sel = @($sel | Sort-Object -Descending | Select-Object -Unique); if($sel.Count -eq 0){ Set-StatusKey 'MsgSelectDelete' $script:ERRORC; return }; $res=[Windows.Forms.MessageBox]::Show((T 'MsgConfirmDeleteMulti'),(T 'MsgConfirmDeleteTitle'),[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Warning); if($res -ne [Windows.Forms.DialogResult]::Yes){ return }; $data=Load-Data; $keep = New-Object System.Collections.ArrayList; for($j=0; $j -lt @($data.bezels).Count; $j++){ if($sel -notcontains [int]$j){ [void]$keep.Add($data.bezels[$j]) } }; $data.bezels = @($keep); Save-Data $data; Refresh-List; Clear-Form; Set-StatusKey 'MsgDeletedMulti' $script:SUCCESS } catch { Set-Status $_.Exception.Message $script:ERRORC } })
$btnCheckPng.Add_Click({ try { $data=Load-Data; $missing=@(); foreach($b in @($data.bezels)){ if(-not (Test-PngExists ([string]$b.png))){ $missing += [string]$b.png } }; Refresh-List; if($missing.Count -eq 0){ Set-StatusKey 'MsgPngCheckOk' $script:SUCCESS } else { Set-Status ((T 'MsgPngMissing') + (($missing | Select-Object -Unique) -join ', ')) $script:ERRORC } } catch { Set-Status $_.Exception.Message $script:ERRORC } })
$btnRestoreBase.Add_Click({
    try {
        Clear-CustomBezelsFromMenuConf
        [System.Windows.Forms.MessageBox]::Show((T 'MsgRestoreBaseDone'),(T 'RestoreTitle'),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        Write-Log ('ERROR RestoreBase ' + $_.Exception.Message)
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,(T 'RestoreTitle'),[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$btnApply.Add_Click({
    try {
        $data = Load-Data
        $enabled = @($data.bezels | Where-Object { $_.enabled -ne $false })
        Apply-MenuConf @($enabled)
        $msg = if (@($enabled).Count -gt 0) { T 'MsgApplied' } else { T 'MsgNoBezels' }
        Set-Status $msg $script:SUCCESS
        [Windows.Forms.MessageBox]::Show($msg, $form.Text, [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        Set-Status $_.Exception.Message $script:ERRORC
        Write-Log ('Apply error: ' + $_.Exception.Message)
    }
})

$btnEN.Add_Click({ Apply-Lang 'EN' })
$btnES.Add_Click({ Apply-Lang 'ES' })

Ensure-Dirs
Load-Data | Out-Null
Apply-Lang 'EN'
Refresh-List
Clear-Form
Write-Log ('STARTUP FINAL-PURPLE-BG-ORIGBUTTONS toolsDir=' + $script:ToolsDir + ' managerDir=' + $script:ManagerDir + ' bezelsDir=' + $script:BezelsDir + ' rootDir=' + $script:RootDir + ' menuExists=' + (Test-Path -LiteralPath $script:MenuConfPath) + ' json=' + $script:JsonPath)
try { if($script:OwnerForm){ $null = $script:OwnerForm.Show() } } catch {}
[System.Windows.Forms.Application]::Run($form)