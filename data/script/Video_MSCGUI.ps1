# Video_MSCGUI.ps1 - By TyRaS-SW
# GUI Tool for Advanced Video Configurations
# EN/ES GUI - PowerShell 5+ (Windows 10/11)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ============================================================
#  APPMODELID (Taskbar Icon Grouping)
# ============================================================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class TaskbarAppId {
    [DllImport("shell32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);
}
"@

$script:AppUserModelID = "TyRaS.MPVSWCapture.VideoManager"
try {
    [TaskbarAppId]::SetCurrentProcessExplicitAppUserModelID($script:AppUserModelID) | Out-Null
} catch {}

# ============================================================
#  PATH DETECTION
# ============================================================
function Get-ScriptDir {
    try { if ($PSCommandPath) { return (Split-Path -Parent $PSCommandPath) } } catch {}
    try { if ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) { return (Split-Path -Parent $MyInvocation.MyCommand.Path) } } catch {}
    return (Get-Location).Path
}

function Get-RootDir {
    $scriptDir = Get-ScriptDir
    if ((Split-Path $scriptDir -Leaf) -eq 'script' -and (Split-Path (Split-Path $scriptDir -Parent) -Leaf) -eq 'data') {
        $root = Split-Path -Parent (Split-Path -Parent $scriptDir)
        return $root
    }
    return $scriptDir
}

# --- Determine paths ---
$script:RootDir = Get-RootDir
$script:ScriptDir = Get-ScriptDir
$script:ToolsDir = Join-Path $script:RootDir "tools"
$script:BatPath = Join-Path $script:RootDir "data\MPV-SW-Capture.bat"
$script:JsonPath = Join-Path $script:ToolsDir "user-video_options.json"

# ============================================================
#  LANGUAGE PERSISTENCE
# ============================================================
$script:LangFilePath = Join-Path $script:RootDir "data\script\GUILang.dat"

function Load-GUILanguage {
    if (Test-Path $script:LangFilePath) {
        try {
            $content = Get-Content $script:LangFilePath -Encoding UTF8 -Raw
            $content = $content.Trim().ToUpper()
            if ($content -eq "EN" -or $content -eq "ES") { return $content }
        } catch {}
    }
    Save-GUILanguage "EN"
    return "EN"
}

function Save-GUILanguage([string]$lang) {
    $dir = Split-Path -Parent $script:LangFilePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $content = if ($lang -eq "EN") { "en" } else { "es" }
    [System.IO.File]::WriteAllText($script:LangFilePath, $content, [System.Text.Encoding]::UTF8)
}

$script:CurrentLang = 'EN'
$script:LogEntries = New-Object System.Collections.Generic.List[object]

# Default mpv launch line. 
# No pixel_format or vcodec set by default (FFmpeg negotiates automatically).
$script:DefaultLine = 'start "" /b "%prog1_path%" --no-border --config-dir="%ROOT_DIR%" %capture_source% --profile=low-latency --demuxer-lavf-o="video_size=1920x1080%fps_opt%,rtbufsize=24M" --vd-lavc-threads=1 %timing_args% --demuxer-thread=no --vo=gpu-next --gpu-api=d3d11 --swapchain-depth=1 --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no --script-opts=msc_check_version_auto=0 %native_audio_args% --input-ipc-server=\\.\pipe\mpv-sw-capture-socket'

# ============================================================
#  FORM ICON
# ============================================================
function Get-AppIcon {
    try {
        $customIconPath = Join-Path $script:RootDir "data\icon\videomsc.ico"
        if (Test-Path -LiteralPath $customIconPath) { return New-Object System.Drawing.Icon($customIconPath) }
    } catch {}
    try {
        $exePath = [System.Windows.Forms.Application]::ExecutablePath
        if ($exePath -and (Test-Path -LiteralPath $exePath)) { return [System.Drawing.Icon]::ExtractAssociatedIcon($exePath) }
    } catch {}
    return $null
}

# ============================================================
#  LANGUAGES
# ============================================================
$script:Lang = @{
EN = @{
Title='MPV-SW-Capture - Video Options Manager'; Header='Edit video options in MPV-SW-Capture.bat.'; LangLabel='GUI Language';
Files='Paths'; FilesNote='The GUI program stays in /tools. The file edited by this program is /data/MPV-SW-Capture.bat. Custom JSON files are saved in /tools.';
Root='Root folder'; Tools='Tools folder'; Bat='BAT file'; Json='Custom JSON';
Settings='MPV launch settings'; Actions='Actions';
Rtbuf='Video Buffer Size'; VideoSize='Video Resolution'; Fps='FPS'; Threads='Video Decode Threads'; WindowScale='Window Scale'; DemuxerThread='Demuxer Thread'; Vo='Video Output'; Hwdec='Hardware Decode'; GpuApi='GPU API'; SwapchainDepth='Swapchain Depth'; InputFormat='Input Video Format';
Reload='Reload from BAT'; Save='Save to BAT'; RestoreDefaults='Restore DEFAULT Options'; SaveCustom='Save Custom Options'; ImportCustom='Import Custom Options';
MsgBatMissing='MPV-SW-Capture.bat was not found in /data.'; MsgLineMissing='The mpv start line was not found in the BAT file.'; MsgSaved='BAT file updated successfully.'; MsgReload='Values reloaded from BAT.'; MsgDefaultsApplied='Default options restored and written to BAT.'; MsgJsonSaved='Custom options JSON saved.'; MsgJsonImported='Custom options imported and written to BAT.'; MsgJsonMissing='JSON file was not found.'; MsgJsonInvalid='The JSON file is invalid or incomplete.'; MsgImportConfirm='Do you want to import the JSON file and replace the BAT options?'; MsgDefaultsConfirm='Do you want to restore the default video options?'; MsgConfirmTitle='Confirm';
LogTitle='Log';
RtbufHelp='Set the video buffer size used by mpv before playback. Lower values reduce lag, higher values improve stability. Default: 24M.';
VideoSizeHelp='Force the default resolution. "1080p" is most stable. Use "720p" if you get lag at 1080p.';
FpsHelp='Force default FPS. "Auto" uses Capture Card FPS. "60" is default.';
ThreadsHelp='Best for low latency is "1". "0" uses automatic values and can increase buffering.';
WindowScaleHelp='Adjust the initial mpv window size. Higher values make the window larger.';
HwdecHelp='"no" is default. "auto-safe" reduces CPU usage. "auto", "yes" are aggressive.';
VoHelp='"gpu-next" is modern and best. "gpu" is for older PCs.';
DemuxerHelp='"no" is recommended to reduce latency.';
GpuApiHelp='"d3d11" is native Windows (best for HDR). "vulkan" is alternative. "opengl" is legacy.';
SwapchainDepthHelp='"1" = lowest latency (recommended). "2" or "3" = more stable on slower GPUs (adds latency).';
InputFormatHelp='"auto": default. "mjpeg": compressed format. "yuyv422": RAW quality. Some formats may not be compatible.';
Auto='Auto'; Yes='Yes'; No='No'; DefaultWord='Default'; JsonFilter='JSON files (*.json)|*.json';
};
ES = @{
Title='MPV-SW-Capture - Administrador de Opciones de Video'; Header='Edita las opciones de video en MPV-SW-Capture.bat.'; LangLabel='Idioma del GUI';
Files='Rutas'; FilesNote='El programa GUI queda en /tools. El archivo que edita este programa es /data/MPV-SW-Capture.bat. Los JSON personalizados se guardan en /tools.';
Root='Carpeta raiz'; Tools='Carpeta tools'; Bat='Archivo BAT'; Json='JSON personalizado';
Settings='Opciones de inicio de MPV'; Actions='Acciones';
Rtbuf='Tamano del buffer de video'; VideoSize='Resolucion de video'; Fps='FPS'; Threads='Hilos de decodificacion de video'; WindowScale='Escala de ventana'; DemuxerThread='Hilo del demuxer'; Vo='Salida de video'; Hwdec='Decodificacion por hardware'; GpuApi='API de GPU'; SwapchainDepth='Profundidad de Swapchain'; InputFormat='Formato de video de entrada';
Reload='Recargar desde BAT'; Save='Guardar en BAT'; RestoreDefaults='Restaurar Opciones por DEFECTO'; SaveCustom='Guardar Opciones Personalizadas'; ImportCustom='Importar Opciones Personalizadas';
MsgBatMissing='No se encontro MPV-SW-Capture.bat en /data.'; MsgLineMissing='No se encontro la linea de inicio de mpv dentro del BAT.'; MsgSaved='BAT actualizado correctamente.'; MsgReload='Valores recargados desde el BAT.'; MsgDefaultsApplied='Las opciones por defecto fueron restauradas y escritas en el BAT.'; MsgJsonSaved='El JSON de opciones personalizadas fue guardado.'; MsgJsonImported='Las opciones personalizadas fueron importadas y escritas en el BAT.'; MsgJsonMissing='No se encontro el archivo JSON.'; MsgJsonInvalid='El archivo JSON es invalido o esta incompleto.'; MsgImportConfirm='Deseas importar el archivo JSON y reemplazar las opciones del BAT?'; MsgDefaultsConfirm='Deseas restaurar las opciones de video por defecto?'; MsgConfirmTitle='Confirmar';
LogTitle='Log';
RtbufHelp='Define el tamano del buffer de video. Valores bajos reducen lag, altos mejoran estabilidad. Defecto: 24M.';
VideoSizeHelp='Fuerza la resolucion. "1080p" es la mas estable. Usa "720p" si tienes lag en 1080p.';
FpsHelp='Fuerza FPS. "Auto" usa el de la capturadora. "60" por defecto.';
ThreadsHelp='Mejor latencia es "1". "0" usa valores automaticos y puede aumentar buffering.';
WindowScaleHelp='Ajusta el tamano inicial de la ventana. Valores mas altos la agrandan.';
HwdecHelp='"no" por defecto. "auto-safe" reduce CPU. "auto", "yes" son agresivos.';
VoHelp='"gpu-next" es moderno y mejor. "gpu" es para PCs antiguos.';
DemuxerHelp='"no" es recomendado para reducir latencia.';
GpuApiHelp='"d3d11" es nativo Windows (mejor HDR). "vulkan" es alternativa. "opengl" es legacy.';
SwapchainDepthHelp='"1" = latencia minima (recomendado). "2" o "3" = mas estable en GPUs lentas.';
InputFormatHelp='"auto": defecto. "mjpeg": formato comprimido. "yuyv422": calidad RAW. Algunos formatos podrian no ser compatibles.';
Auto='Auto'; Yes='Si'; No='No'; DefaultWord='Defecto'; JsonFilter='Archivos JSON (*.json)|*.json';
}
}

function T([string]$Key) { if($Key -eq '__RAW__'){ return '' }; $script:Lang[$script:CurrentLang][$Key] }
function Add-LogEntry([string]$type,[string]$extra='') { $script:LogEntries.Add([pscustomobject]@{ time=(Get-Date -Format 'HH:mm:ss'); type=$type; extra=$extra }) | Out-Null; Refresh-Log }
function Refresh-Log { if(-not $tbLog){ return }; $tbLog.Clear(); foreach($e in $script:LogEntries){ if($e.type -eq '__RAW__'){ $msg = $e.extra } else { $msg = (T $e.type) + $e.extra }; $tbLog.AppendText('[' + $e.time + '] ' + $msg + [Environment]::NewLine) } }
function Set-Status([string]$txt){ Add-LogEntry '__RAW__' $txt }
function Set-StatusKey([string]$key){ Add-LogEntry $key }
function Set-StatusKeyEx([string]$key,[string]$extra){ Add-LogEntry $key $extra }

$script:BG=[Drawing.Color]::FromArgb(58,58,62)
$script:SURFACE=[Drawing.Color]::FromArgb(68,68,72)
$script:CARD=[Drawing.Color]::FromArgb(78,78,84)
$script:ACCENT=[Drawing.Color]::FromArgb(99,179,237)
$script:ACCENT2=[Drawing.Color]::FromArgb(72,219,155)
$script:ACCENT3=[Drawing.Color]::FromArgb(241,166,48)
$script:TEXT=[Drawing.Color]::FromArgb(238,238,240)
$script:MUTED=[Drawing.Color]::FromArgb(198,198,204)
$FontTitle=New-Object Drawing.Font('Segoe UI',16,[Drawing.FontStyle]::Bold)
$FontSub=New-Object Drawing.Font('Segoe UI',9)
$FontSubBold=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
$FontBold=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
$FontBtn=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$FontSmall=New-Object Drawing.Font('Segoe UI',8)
$FontLangBtn=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)

# Default logical values. These are the "safe" defaults applied by
# Restore Defaults and highlighted in the lists.
$script:DefaultOptionMap = @{
    rtbuf           = '24M'
    videoSize       = '1920x1080'
    fps             = '60'
    threads         = '1'
    windowScale     = '1.0'
    demuxerThread   = 'no'
    vo              = 'gpu-next'
    hwdec           = 'no'
    gpuApi          = 'd3d11'
    swapchainDepth  = '1'
    inputFormat     = 'auto'
}

function Style-Btn($btn,$bg,$fg){ $btn.UseVisualStyleBackColor=$false; $btn.BackColor=$bg; $btn.ForeColor=$fg; $btn.Font=$FontBtn; $btn.FlatStyle='Flat'; $btn.FlatAppearance.BorderSize=0; $btn.Cursor='Hand'; $btn.TextAlign='MiddleCenter' }
function Style-LangBtn($btn,[bool]$active){ $btn.UseVisualStyleBackColor=$false; $btn.Font=$FontLangBtn; $btn.FlatStyle='Flat'; $btn.FlatAppearance.BorderSize=1; $btn.Cursor='Hand'; if($active){$btn.BackColor=$script:ACCENT;$btn.ForeColor=$script:BG;$btn.FlatAppearance.BorderColor=$script:ACCENT}else{$btn.BackColor=$script:SURFACE;$btn.ForeColor=$script:MUTED;$btn.FlatAppearance.BorderColor=$script:MUTED} }
function New-Lbl([string]$text,[int]$x,[int]$y,[int]$w,[int]$h,$font,$color){ $l=New-Object Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h); $l.Font=$font; $l.ForeColor=$color; $l.BackColor=[Drawing.Color]::Transparent; $l }
function Normalize-UiValue([string]$Value){ if([string]::IsNullOrWhiteSpace($Value)){ return $Value }; return (($Value -replace ' \(Default\)$','' -replace ' \(Defecto\)$','').Trim()) }

function Get-LogicalListItemValue($lb,[string]$itemText){
    $raw = Normalize-UiValue $itemText
    $key = [string]$lb.Tag
    switch ($key) {
        'fps' {
            if($raw -eq (T 'Auto')){ return '__AUTO__' }
            return $raw
        }
        'hwdec' {
            if($raw -eq 'no'){ return 'no' }
            if($raw -eq 'yes'){ return 'yes' }
            return $raw.ToLowerInvariant()
        }
        'demuxerThread' {
            if($raw -eq 'no'){ return 'no' }
            if($raw -eq 'yes'){ return 'yes' }
            return $raw.ToLowerInvariant()
        }
        'inputFormat' {
            return $raw.ToLowerInvariant()
        }
        default { return $raw }
    }
}

function Get-DefaultValueForList($lb){
    if($null -eq $lb.Tag){ return $null }
    $key = [string]$lb.Tag
    if($script:DefaultOptionMap.ContainsKey($key)){ return $script:DefaultOptionMap[$key] }
    return $null
}

function Draw-ListItem($sender, $e){
    if($e.Index -lt 0){ return }
    $itemText = [string]$sender.Items[$e.Index]
    $itemValue = Get-LogicalListItemValue $sender $itemText
    $defaultValue = Get-DefaultValueForList $sender
    $isDefault = ($null -ne $defaultValue -and $itemValue -eq $defaultValue)
    $isSelected = (($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected)
    $bgColor = if($isSelected){ $script:ACCENT } else { $sender.BackColor }
    $fgColor = if($isSelected){ $script:BG } elseif($isDefault){ $script:ACCENT3 } else { $script:TEXT }
    $useFont = if($isDefault){ $FontSubBold } else { $sender.Font }
    $bgBrush = New-Object System.Drawing.SolidBrush($bgColor)
    $fgBrush = New-Object System.Drawing.SolidBrush($fgColor)
    $e.Graphics.FillRectangle($bgBrush, $e.Bounds)
    $textRect = New-Object System.Drawing.RectangleF(($e.Bounds.X + 4),($e.Bounds.Y + 1),($e.Bounds.Width - 6),($e.Bounds.Height - 1))
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Near
    $e.Graphics.DrawString($itemText, $useFont, $fgBrush, $textRect, $stringFormat)
    $e.DrawFocusRectangle()
    $bgBrush.Dispose()
    $fgBrush.Dispose()
    $stringFormat.Dispose()
}

function Style-List($lb){ $lb.BackColor=$script:CARD; $lb.ForeColor=$script:TEXT; $lb.BorderStyle='FixedSingle'; $lb.SelectionMode='One'; $lb.MultiColumn=$false; $lb.IntegralHeight=$false; $lb.Font=$FontSub; $lb.HorizontalScrollbar=$false; $lb.DrawMode=[System.Windows.Forms.DrawMode]::OwnerDrawFixed; $lb.Add_DrawItem({ param($sender,$e) Draw-ListItem $sender $e }) }
function New-List([int]$x,[int]$y,[int]$w,[int]$h){ $lb=New-Object Windows.Forms.ListBox; $lb.Location=New-Object Drawing.Point($x,$y); $lb.Size=New-Object Drawing.Size($w,$h); Style-List $lb; return $lb }
function Set-ListItems($lb,[string[]]$items){ $lb.BeginUpdate(); $lb.Items.Clear(); foreach($i in $items){ [void]$lb.Items.Add($i) }; $lb.EndUpdate(); $lb.Invalidate() }
function Get-OptionValue([string]$Line,[string]$Name){ $m = [regex]::Match($Line,'(?i)--' + [regex]::Escape($Name) + '=([^\s]+)'); if($m.Success){ return $m.Groups[1].Value }; return $null }
function Set-Or-ReplaceOption([string]$Line,[string]$Name,[string]$Value){ $pattern='(?i)\s--' + [regex]::Escape($Name) + '=[^\s]+'; if([regex]::IsMatch($Line,$pattern)){ return ([regex]::Replace($Line,$pattern,' --' + $Name + '=' + $Value,1)) }; return ($Line + ' --' + $Name + '=' + $Value) }
function Remove-Option([string]$Line,[string]$Name){ return ([regex]::Replace($Line,'(?i)\s--' + [regex]::Escape($Name) + '=[^\s]+','')) }
function Normalize-Spaces([string]$Line){ return (($Line -replace '\s{2,}',' ').TrimEnd()) }
function Load-BatLines { if(-not (Test-Path -LiteralPath $script:BatPath)){ throw (T 'MsgBatMissing') }; return [IO.File]::ReadAllLines($script:BatPath,[Text.UTF8Encoding]::new($false)) }

# --- Demuxer option helpers (combined --demuxer-lavf-o string) ---
function Get-DemuxerOptValue([string]$Line, [string]$OptName) {
    $m = [regex]::Match($Line, '(?i)--demuxer-lavf-o=(?:"([^"]*)"|([^\s]+))')
    if ($m.Success) {
        $optsStr = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
        $optsStr = $optsStr -replace '(?i)%fps_opt%',''
        $m2 = [regex]::Match($optsStr, '(?i)(?:^|,)\s*' + [regex]::Escape($OptName) + '\s*=\s*([^,]+)')
        if ($m2.Success) { return $m2.Groups[1].Value.Trim() }
    }
    return $null
}

function Set-DemuxerOptValue([string]$Line, [string]$OptName, [string]$Value) {
    $m = [regex]::Match($Line, '(?i)--demuxer-lavf-o=(?:"([^"]*)"|([^\s]+))')
    $optsStr = ""
    if ($m.Success) {
        $optsStr = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
    }
    # %fps_opt% is a BAT variable (framerate). Strip it while editing, then put it back.
    $hadFpsToken = ($optsStr -match '(?i)%fps_opt%')
    $optsStr = $optsStr -replace '(?i)%fps_opt%',''

    $parts = $optsStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $found = $false
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($parts[$i] -match "(?i)^$([regex]::Escape($OptName))=(.*)$") {
            $parts[$i] = "$OptName=$Value"
            $found = $true
        }
    }
    if (-not $found) {
        $parts += "$OptName=$Value"
    }

    $newOptsStr = $parts -join ','
    if ($hadFpsToken) { $newOptsStr = [regex]::Replace($newOptsStr, '(?i)(^|,)(video_size=[^,]*)', '$1$2%fps_opt%', 1) }
    $newOpt = "--demuxer-lavf-o=`"$newOptsStr`""

    if ($m.Success) {
        return $Line.Substring(0, $m.Index) + $newOpt + $Line.Substring($m.Index + $m.Length)
    } else {
        return $Line + " " + $newOpt
    }
}

function Remove-DemuxerOptValue([string]$Line, [string]$OptName) {
    $m = [regex]::Match($Line, '(?i)--demuxer-lavf-o=(?:"([^"]*)"|([^\s]+))')
    if (-not $m.Success) { return $Line }

    $optsStr = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
    $hadFpsToken = ($optsStr -match '(?i)%fps_opt%')
    $optsStr = $optsStr -replace '(?i)%fps_opt%',''
    $parts = $optsStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" -and $_ -notmatch "(?i)^$([regex]::Escape($OptName))=" }

    $newOptsStr = $parts -join ','
    if ($hadFpsToken) { $newOptsStr = [regex]::Replace($newOptsStr, '(?i)(^|,)(video_size=[^,]*)', '$1$2%fps_opt%', 1) }
    $newOpt = "--demuxer-lavf-o=`"$newOptsStr`""

    return $Line.Substring(0, $m.Index) + $newOpt + $Line.Substring($m.Index + $m.Length)
}
# --------------------------------------------------------

# --- capture_fps helpers (BAT variable + %fps_opt% token) ---
# FPS is no longer written to the mpv line. It is stored in: set "capture_fps=XX"
# Empty value = Auto (the BAT then omits framerate= and the driver decides).
function Test-FpsValue([string]$Value){ return ($Value -match '^[0-9]+(\.[0-9]+)?$') }

function Get-BatFpsValue([string[]]$Lines,[string]$Fallback='__AUTO__'){
    foreach($l in $Lines){
        $m = [regex]::Match($l,'(?i)^\s*set\s+"capture_fps=([^"]*)"')
        if($m.Success){
            $val = $m.Groups[1].Value.Trim()
            if([string]::IsNullOrWhiteSpace($val)){ return '__AUTO__' }
            return $val
        }
    }
    return $Fallback
}

function Ensure-FpsToken([string]$Line){
    if($Line -match '(?i)%fps_opt%'){ return $Line }
    return [regex]::Replace($Line,'(?i)(--demuxer-lavf-o="[^"]*?video_size=[^,"]*)','$1%fps_opt%',1)
}

function Set-BatFpsLines([string[]]$Lines,[string]$Fps){
    $val = ''
    if($Fps -ne '__AUTO__' -and (Test-FpsValue $Fps)){ $val = $Fps }
    $capLine = 'set "capture_fps=' + $val + '"'

    $list = New-Object System.Collections.Generic.List[string]
    foreach($l in $Lines){ [void]$list.Add([string]$l) }

    $capIdx = -1
    for($i=0; $i -lt $list.Count; $i++){ if($list[$i] -match '(?i)^\s*set\s+"capture_fps="?'){ $capIdx = $i; break } }

    if($capIdx -ge 0){
        $list[$capIdx] = $capLine
    } else {
        $block = @(
            ':: --- Capture framerate (dshow) ---',
            ':: Frame rate requested from the capture card (30, 60, 120...).',
            ':: Leave empty for AUTO: framerate is not passed and the driver decides.',
            $capLine
        )
        $insAt = -1
        for($i=0; $i -lt $list.Count; $i++){ if($list[$i] -match '(?i)^\s*set\s+"audio_device='){ $insAt = $i + 1; break } }
        if($insAt -lt 0){ $insAt = Get-MpvLineIndex ($list.ToArray()) }
        if($insAt -lt 0){ $insAt = $list.Count }
        $list.InsertRange($insAt, [string[]]$block)
        $capIdx = $insAt + $block.Count - 1
    }

    $hasLogic = $false
    foreach($l in $list){ if($l -match '(?i)^\s*if\s+defined\s+capture_fps\b'){ $hasLogic = $true; break } }
    if(-not $hasLogic){
        $logic = @(
            'set "fps_opt="',
            'if defined capture_fps set "fps_opt=,framerate=%capture_fps%"'
        )
        $list.InsertRange($capIdx + 1, [string[]]$logic)
    }
    return ,([string[]]$list.ToArray())
}
# --------------------------------------------------------

function Get-MpvLineIndex([string[]]$Lines){
    for($i=0; $i -lt $Lines.Count; $i++){
        if($Lines[$i] -like '*start "" /b "%prog1_path%"*' -and $Lines[$i] -like '*--profile=low-latency*'){ return $i }
    }
    return -1
}

function Parse-LineToValues([string]$line){
    $rtbuf = Get-DemuxerOptValue $line 'rtbufsize'; if([string]::IsNullOrWhiteSpace($rtbuf)){ $rtbuf = '24M' }
    $videoSize = Get-DemuxerOptValue $line 'video_size'; if([string]::IsNullOrWhiteSpace($videoSize)){ $videoSize = '1920x1080' }
    
    # Check both vcodec and pixel_format to determine the actual inputFormat
    $vcodec = Get-DemuxerOptValue $line 'vcodec'
    $pixfmt = Get-DemuxerOptValue $line 'pixel_format'
    $inputFormat = if (-not [string]::IsNullOrWhiteSpace($vcodec)) { $vcodec } elseif (-not [string]::IsNullOrWhiteSpace($pixfmt)) { $pixfmt } else { 'auto' }

    # Legacy fallbacks only: the real value now lives in set "capture_fps=" (see Get-BatFpsValue).
    $fps = Get-DemuxerOptValue $line 'framerate'
    if([string]::IsNullOrWhiteSpace($fps)){ $fps = Get-OptionValue $line 'container-fps-override' }
    if([string]::IsNullOrWhiteSpace($fps)){ $fps = '__AUTO__' }
    $threads = Get-OptionValue $line 'vd-lavc-threads'; if([string]::IsNullOrWhiteSpace($threads)){ $threads = '1' }
    $windowScale = Get-OptionValue $line 'window-scale'; if([string]::IsNullOrWhiteSpace($windowScale)){ $windowScale = '1.0' }
    $demuxerThread = Get-OptionValue $line 'demuxer-thread'; if([string]::IsNullOrWhiteSpace($demuxerThread)){ $demuxerThread = 'no' }
    $vo = Get-OptionValue $line 'vo'; if([string]::IsNullOrWhiteSpace($vo)){ $vo = 'gpu-next' }
    $hwdec = Get-OptionValue $line 'hwdec'; if([string]::IsNullOrWhiteSpace($hwdec)){ $hwdec = 'no' }
    $gpuApi = Get-OptionValue $line 'gpu-api'; if([string]::IsNullOrWhiteSpace($gpuApi)){ $gpuApi = 'd3d11' }
    $swapchainDepth = Get-OptionValue $line 'swapchain-depth'; if([string]::IsNullOrWhiteSpace($swapchainDepth)){ $swapchainDepth = '1' }
    
    return @{ rtbuf=$rtbuf; videoSize=$videoSize; inputFormat=$inputFormat; fps=$fps; threads=$threads; windowScale=$windowScale; demuxerThread=$demuxerThread; vo=$vo; hwdec=$hwdec; gpuApi=$gpuApi; swapchainDepth=$swapchainDepth }
}

function Set-ListValue($lb,[string]$value){
    $targetValue = $value
    if([string]::IsNullOrWhiteSpace($targetValue)){ $targetValue = '' }
    for($i=0; $i -lt $lb.Items.Count; $i++){
        $candidate = Get-LogicalListItemValue $lb ([string]$lb.Items[$i])
        if($candidate -eq $targetValue){ $lb.SelectedIndex = $i; return }
    }
    if($lb.Items.Count -gt 0){ $lb.SelectedIndex = 0 }
}

function Apply-ValuesToForm($v){
    Set-ListValue $lbRtbuf $v.rtbuf
    Set-ListValue $lbVideoSize $v.videoSize
    Set-ListValue $lbInputFormat $v.inputFormat
    Set-ListValue $lbFps $v.fps
    Set-ListValue $lbThreads $v.threads
    Set-ListValue $lbWindowScale $v.windowScale
    Set-ListValue $lbDemuxer $v.demuxerThread
    Set-ListValue $lbVo $v.vo
    Set-ListValue $lbHwdec $v.hwdec
    Set-ListValue $lbGpuApi $v.gpuApi
    Set-ListValue $lbSwapchainDepth $v.swapchainDepth
}

function Load-ValuesToForm { $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; $vals = Parse-LineToValues $lines[$idx]; $vals.fps = Get-BatFpsValue $lines $vals.fps; Apply-ValuesToForm $vals }

function Get-FormValues {
    return @{
        rtbuf          = (Get-LogicalListItemValue $lbRtbuf ([string]$lbRtbuf.SelectedItem));
        videoSize      = (Get-LogicalListItemValue $lbVideoSize ([string]$lbVideoSize.SelectedItem));
        inputFormat    = (Get-LogicalListItemValue $lbInputFormat ([string]$lbInputFormat.SelectedItem));
        fps            = (Get-LogicalListItemValue $lbFps ([string]$lbFps.SelectedItem));
        threads        = (Get-LogicalListItemValue $lbThreads ([string]$lbThreads.SelectedItem));
        windowScale    = (Get-LogicalListItemValue $lbWindowScale ([string]$lbWindowScale.SelectedItem));
        demuxerThread  = (Get-LogicalListItemValue $lbDemuxer ([string]$lbDemuxer.SelectedItem));
        vo             = (Get-LogicalListItemValue $lbVo ([string]$lbVo.SelectedItem));
        hwdec          = (Get-LogicalListItemValue $lbHwdec ([string]$lbHwdec.SelectedItem));
        gpuApi         = (Get-LogicalListItemValue $lbGpuApi ([string]$lbGpuApi.SelectedItem));
        swapchainDepth = (Get-LogicalListItemValue $lbSwapchainDepth ([string]$lbSwapchainDepth.SelectedItem))
    }
}

function Apply-ValuesToLine([string]$line,$v){
    $line = Set-DemuxerOptValue $line 'rtbufsize' $v.rtbuf
    $line = Set-DemuxerOptValue $line 'video_size' $v.videoSize
    
    # Auto: remove both. Codecs: use vcodec. Raw formats: use pixel_format.
    if($v.inputFormat -eq 'auto'){
        $line = Remove-DemuxerOptValue $line 'pixel_format'
        $line = Remove-DemuxerOptValue $line 'vcodec'
    } elseif ($v.inputFormat -in @('mjpeg', 'h264')) {
        $line = Remove-DemuxerOptValue $line 'pixel_format'
        $line = Set-DemuxerOptValue $line 'vcodec' $v.inputFormat
    } else {
        $line = Remove-DemuxerOptValue $line 'vcodec'
        $line = Set-DemuxerOptValue $line 'pixel_format' $v.inputFormat
    }

    # FPS is stored in set "capture_fps=" (see Set-BatFpsLines). Remove legacy fps options from the mpv line.
    $line = Remove-Option $line 'container-fps-override'
    $line = Remove-DemuxerOptValue $line 'framerate'
    $line = Ensure-FpsToken $line
    $line = Set-Or-ReplaceOption $line 'vd-lavc-threads' $v.threads
    $line = Set-Or-ReplaceOption $line 'window-scale' $v.windowScale
    $line = Set-Or-ReplaceOption $line 'demuxer-thread' $v.demuxerThread
    $line = Set-Or-ReplaceOption $line 'vo' $v.vo
    $line = Set-Or-ReplaceOption $line 'hwdec' $v.hwdec
    $line = Set-Or-ReplaceOption $line 'gpu-api' $v.gpuApi
    $line = Set-Or-ReplaceOption $line 'swapchain-depth' $v.swapchainDepth
    return (Normalize-Spaces $line)
}

function Save-Bat { $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; $fv = Get-FormValues; $lines[$idx] = Apply-ValuesToLine $lines[$idx] $fv; $lines = [string[]](Set-BatFpsLines $lines $fv.fps); [IO.File]::WriteAllLines($script:BatPath,$lines,[Text.UTF8Encoding]::new($false)); Set-StatusKey 'MsgSaved' }
function Apply-DefaultOptions { $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; $lines[$idx] = $script:DefaultLine; $dfps = $script:DefaultOptionMap['fps']; $lines = [string[]](Set-BatFpsLines $lines $dfps); [IO.File]::WriteAllLines($script:BatPath,$lines,[Text.UTF8Encoding]::new($false)); $dv = Parse-LineToValues $script:DefaultLine; $dv.fps = $dfps; Apply-ValuesToForm $dv; Set-StatusKey 'MsgDefaultsApplied' }
function Save-CustomJson { $v = Get-FormValues | ConvertTo-Json -Depth 4; [IO.File]::WriteAllText($script:JsonPath,$v,[Text.UTF8Encoding]::new($false)); Set-StatusKeyEx 'MsgJsonSaved' ("`r`n" + $script:JsonPath) }

function Import-CustomJson {
    $ofd = New-Object Windows.Forms.OpenFileDialog
    $ofd.Filter = T 'JsonFilter'
    if($ofd.ShowDialog() -ne 'OK'){ return }
    if(-not (Test-Path -LiteralPath $ofd.FileName)){ throw (T 'MsgJsonMissing') }
    $raw = Get-Content -LiteralPath $ofd.FileName -Raw -Encoding UTF8
    $obj = $raw | ConvertFrom-Json
    if($null -eq $obj.rtbuf -or $null -eq $obj.videoSize -or $null -eq $obj.fps -or $null -eq $obj.threads -or $null -eq $obj.windowScale -or $null -eq $obj.demuxerThread -or $null -eq $obj.vo -or $null -eq $obj.hwdec -or $null -eq $obj.gpuApi -or $null -eq $obj.swapchainDepth){ throw (T 'MsgJsonInvalid') }
    
    # inputFormat is optional for backward compatibility.
    $inputFormatVal = if($null -ne $obj.inputFormat -and -not [string]::IsNullOrWhiteSpace([string]$obj.inputFormat)) { [string]$obj.inputFormat } else { 'auto' }
    
    $vals = @{
        rtbuf=[string]$obj.rtbuf;
        videoSize=[string]$obj.videoSize;
        inputFormat=$inputFormatVal;
        fps=[string]$obj.fps;
        threads=[string]$obj.threads;
        windowScale=[string]$obj.windowScale;
        demuxerThread=[string]$obj.demuxerThread;
        vo=[string]$obj.vo;
        hwdec=[string]$obj.hwdec;
        gpuApi=[string]$obj.gpuApi;
        swapchainDepth=[string]$obj.swapchainDepth
    }
    Apply-ValuesToForm $vals
    $lines = Load-BatLines
    $idx = Get-MpvLineIndex $lines
    if($idx -lt 0){ throw (T 'MsgLineMissing') }
    $lines[$idx] = Apply-ValuesToLine $lines[$idx] $vals
    $lines = [string[]](Set-BatFpsLines $lines $vals.fps)
    [IO.File]::WriteAllLines($script:BatPath,$lines,[Text.UTF8Encoding]::new($false))
    Set-StatusKey 'MsgJsonImported'
}

$form=New-Object Windows.Forms.Form
$form.Text = T 'Title'
try {
    $appIcon = Get-AppIcon
    if ($appIcon) { $form.Icon = $appIcon; $form.Refresh() }
} catch {}
$form.ClientSize=New-Object Drawing.Size(1120,952)
$form.StartPosition='CenterScreen'
$form.ShowInTaskbar = $true
$form.FormBorderStyle='FixedSingle'
$form.MaximizeBox=$false
$form.BackColor=$script:BG
$form.ForeColor=$script:TEXT
$form.Font=$FontSub

$pHeader=New-Object Windows.Forms.Panel
$pHeader.Location=New-Object Drawing.Point(0,0)
$pHeader.Size=New-Object Drawing.Size(1120,70)
$pHeader.BackColor=$script:SURFACE
$form.Controls.Add($pHeader)
$lTitle=New-Lbl 'MPV-SW-Capture' 20 4 420 30 $FontTitle $script:ACCENT
$lSub=New-Lbl (T 'Header') 22 36 560 20 $FontSub $script:MUTED
$lLang=New-Lbl (T 'LangLabel') 900 10 88 18 $FontSmall $script:MUTED
$btnEN=New-Object Windows.Forms.Button; $btnEN.Text='EN'; $btnEN.Location=New-Object Drawing.Point(992,6); $btnEN.Size=New-Object Drawing.Size(50,26); Style-LangBtn $btnEN $true
$btnES=New-Object Windows.Forms.Button; $btnES.Text='ES'; $btnES.Location=New-Object Drawing.Point(1048,6); $btnES.Size=New-Object Drawing.Size(50,26); Style-LangBtn $btnES $false
$pHeader.Controls.AddRange(@($lTitle,$lSub,$lLang,$btnEN,$btnES))

$gbFiles=New-Object Windows.Forms.GroupBox
$gbFiles.Location=New-Object Drawing.Point(14,80); $gbFiles.Size=New-Object Drawing.Size(1092,94); $gbFiles.ForeColor=$script:TEXT; $gbFiles.BackColor=$script:BG
$form.Controls.Add($gbFiles)
$lFilesNote=New-Lbl '' 14 14 1050 16 $FontSmall $script:MUTED
$lRoot=New-Lbl '' 14 30 1050 16 $FontSmall $script:TEXT
$lTools=New-Lbl '' 14 44 1050 16 $FontSmall $script:TEXT
$lBat=New-Lbl '' 14 58 1050 16 $FontSmall $script:TEXT
$lJson=New-Lbl '' 14 72 1050 16 $FontSmall $script:TEXT
$gbFiles.Controls.AddRange(@($lFilesNote,$lRoot,$lTools,$lBat,$lJson))

$gbSettings=New-Object Windows.Forms.GroupBox
$gbSettings.Location=New-Object Drawing.Point(14,178); $gbSettings.Size=New-Object Drawing.Size(1092,550); $gbSettings.ForeColor=$script:TEXT; $gbSettings.BackColor=$script:BG
$form.Controls.Add($gbSettings)
function Add-SectionLabel([string]$text,[int]$x,[int]$y,[int]$w){ $lbl=New-Lbl $text $x $y $w 18 $FontBold $script:TEXT; $gbSettings.Controls.Add($lbl); return $lbl }
$leftX=18; $rightX=556

# --- ROW 1 ---
$lblRtbuf = Add-SectionLabel '' $leftX 14 180
$hlpRtbuf = New-Lbl '' 18 30 180 52 $FontSmall $script:ACCENT3
$lbRtbuf = New-List 200 20 320 105
$lbRtbuf.Tag = 'rtbuf'
$lbRtbuf.ItemHeight = 15
Set-ListItems $lbRtbuf @('16M','24M','32M','48M','64M','128M','256M')
$gbSettings.Controls.AddRange(@($hlpRtbuf,$lbRtbuf))

$lblVideo = Add-SectionLabel '' $rightX 14 180
$hlpVideo = New-Lbl '' 556 30 180 52 $FontSmall $script:ACCENT3
$lbVideoSize = New-List 742 20 314 88
$lbVideoSize.Tag = 'videoSize'
$lbVideoSize.ItemHeight = 16
Set-ListItems $lbVideoSize @('1280x720','1920x1080','2048x1152','2560x1440','3840x2160')
$gbSettings.Controls.AddRange(@($hlpVideo,$lbVideoSize))

# --- ROW 2 ---
$lblFps = Add-SectionLabel '' $leftX 130 180
$hlpFps = New-Lbl '' 18 146 170 52 $FontSmall $script:ACCENT3
$lbFps = New-List 200 130 320 62
$lbFps.Tag = 'fps'
$lbFps.ItemHeight = 15
Set-ListItems $lbFps @((T 'Auto'),'60','30','120')
$gbSettings.Controls.AddRange(@($hlpFps,$lbFps))

$lblThreads = Add-SectionLabel '' $rightX 130 186
$hlpThreads = New-Lbl '' 556 146 180 52 $FontSmall $script:ACCENT3
$lbThreads = New-List 742 130 314 62
$lbThreads.Tag = 'threads'
$lbThreads.ItemHeight = 18
Set-ListItems $lbThreads @('1','0')
$gbSettings.Controls.AddRange(@($hlpThreads,$lbThreads))

# --- ROW 3 ---
$lblScale = Add-SectionLabel '' $leftX 202 180
$hlpScale = New-Lbl '' 18 218 170 52 $FontSmall $script:ACCENT3
$lbWindowScale = New-List 200 202 320 78
$lbWindowScale.Tag = 'windowScale'
$lbWindowScale.ItemHeight = 15
Set-ListItems $lbWindowScale @('0.5','0.75','1.0','1.25','2.0')
$gbSettings.Controls.AddRange(@($hlpScale,$lbWindowScale))

$lblHwdec = Add-SectionLabel '' $rightX 202 180
$hlpHwdec = New-Lbl '' 556 218 180 52 $FontSmall $script:ACCENT3
$lbHwdec = New-List 742 202 314 78
$lbHwdec.Tag = 'hwdec'
$lbHwdec.ItemHeight = 18
Set-ListItems $lbHwdec @('no','auto-safe','auto','yes')
$gbSettings.Controls.AddRange(@($hlpHwdec,$lbHwdec))

# --- ROW 4 ---
$lblVo = Add-SectionLabel '' $leftX 290 180
$hlpVo = New-Lbl '' 18 306 170 52 $FontSmall $script:ACCENT3
$lbVo = New-List 200 290 320 48
$lbVo.Tag = 'vo'
$lbVo.ItemHeight = 18
Set-ListItems $lbVo @('gpu-next','gpu')
$gbSettings.Controls.AddRange(@($hlpVo,$lbVo))

$lblDemuxer = Add-SectionLabel '' $rightX 290 180
$hlpDemuxer = New-Lbl '' 556 306 180 52 $FontSmall $script:ACCENT3
$lbDemuxer = New-List 742 290 314 48
$lbDemuxer.Tag = 'demuxerThread'
$lbDemuxer.ItemHeight = 18
Set-ListItems $lbDemuxer @('no','yes')
$gbSettings.Controls.AddRange(@($hlpDemuxer,$lbDemuxer))

# --- ROW 5 ---
$lblGpuApi = Add-SectionLabel '' $leftX 356 180
$hlpGpuApi = New-Lbl '' 18 372 170 52 $FontSmall $script:ACCENT3
$lbGpuApi = New-List 200 348 320 78
$lbGpuApi.Tag = 'gpuApi'
$lbGpuApi.ItemHeight = 18
Set-ListItems $lbGpuApi @('d3d11','vulkan','opengl','auto')
$gbSettings.Controls.AddRange(@($hlpGpuApi,$lbGpuApi))

$lblSwapDepth = Add-SectionLabel '' $rightX 356 186
$hlpSwapDepth = New-Lbl '' 556 372 180 52 $FontSmall $script:ACCENT3
$lbSwapchainDepth = New-List 742 348 314 62
$lbSwapchainDepth.Tag = 'swapchainDepth'
$lbSwapchainDepth.ItemHeight = 18
Set-ListItems $lbSwapchainDepth @('1','2','3')
$gbSettings.Controls.AddRange(@($hlpSwapDepth,$lbSwapchainDepth))

# --- ROW 6: Input Pixel Format (pixel_format / vcodec) ---
$lblInputFormat = Add-SectionLabel '' $leftX 444 180
$hlpInputFormat = New-Lbl '' 18 460 170 60 $FontSmall $script:ACCENT3
$lbInputFormat = New-List 200 436 320 100
$lbInputFormat.Tag = 'inputFormat'
$lbInputFormat.ItemHeight = 16
Set-ListItems $lbInputFormat @('auto','mjpeg','yuyv422','nv12','i420','h264')
$gbSettings.Controls.AddRange(@($hlpInputFormat,$lbInputFormat))

$gbActions=New-Object Windows.Forms.GroupBox
$gbActions.Location=New-Object Drawing.Point(14,738)
$gbActions.Size=New-Object Drawing.Size(1092,190)
$gbActions.ForeColor=$script:TEXT
$gbActions.BackColor=$script:BG
$form.Controls.Add($gbActions)

$btnReload=New-Object Windows.Forms.Button
$btnReload.Location=New-Object Drawing.Point(210,15)
$btnReload.Size=New-Object Drawing.Size(210,34)
Style-Btn $btnReload $script:ACCENT $script:BG

$btnRestoreDefaults=New-Object Windows.Forms.Button
$btnRestoreDefaults.Location=New-Object Drawing.Point(436,15)
$btnRestoreDefaults.Size=New-Object Drawing.Size(240,34)
Style-Btn $btnRestoreDefaults $script:ACCENT3 $script:BG
$btnRestoreDefaults.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)

$btnImportCustom=New-Object Windows.Forms.Button
$btnImportCustom.Location=New-Object Drawing.Point(690,15)
$btnImportCustom.Size=New-Object Drawing.Size(250,34)
Style-Btn $btnImportCustom $script:ACCENT $script:BG
$btnImportCustom.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)

$btnSave=New-Object Windows.Forms.Button
$btnSave.Location=New-Object Drawing.Point(325,58)
$btnSave.Size=New-Object Drawing.Size(210,34)
Style-Btn $btnSave $script:ACCENT2 $script:BG

$btnSaveCustom=New-Object Windows.Forms.Button
$btnSaveCustom.Location=New-Object Drawing.Point(555,58)
$btnSaveCustom.Size=New-Object Drawing.Size(244,34)
Style-Btn $btnSaveCustom $script:ACCENT2 $script:BG
$btnSaveCustom.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)

$lblLog = New-Lbl '' 18 100 120 18 $FontBold $script:TEXT

$tbLog=New-Object Windows.Forms.TextBox
$tbLog.Location=New-Object Drawing.Point(18,120)
$tbLog.Size=New-Object Drawing.Size(1052,55)
$tbLog.Multiline=$true
$tbLog.ReadOnly=$true
$tbLog.ScrollBars='Vertical'
$tbLog.BackColor=$script:CARD
$tbLog.ForeColor=$script:TEXT

$gbActions.Controls.AddRange(@(
    $btnReload,
    $btnRestoreDefaults,
    $btnImportCustom,
    $btnSave,
    $btnSaveCustom,
    $lblLog,
    $tbLog
))

function Sync-Paths { $lFilesNote.Text = T 'FilesNote'; $lRoot.Text = (T 'Root') + ': ' + $script:RootDir; $lTools.Text = (T 'Tools') + ': ' + $script:ToolsDir; $lBat.Text = (T 'Bat') + ': ' + $script:BatPath; $lJson.Text = (T 'Json') + ': ' + $script:JsonPath }

function Apply-Lang([string]$lang){
    $saved = $null
    try { $saved = Get-FormValues } catch {}
    $script:CurrentLang=$lang
    Style-LangBtn $btnEN ($lang -eq 'EN'); Style-LangBtn $btnES ($lang -eq 'ES')
    $form.Text=T 'Title'; $lSub.Text=T 'Header'; $lLang.Text=T 'LangLabel'; $gbFiles.Text=T 'Files'; $gbSettings.Text=T 'Settings'; $gbActions.Text=T 'Actions'
    $lblRtbuf.Text=T 'Rtbuf'; $lblVideo.Text=T 'VideoSize'; $lblFps.Text=T 'Fps'; $lblThreads.Text=T 'Threads'; $lblScale.Text=T 'WindowScale'; $lblDemuxer.Text=T 'DemuxerThread'; $lblVo.Text=T 'Vo'; $lblHwdec.Text=T 'Hwdec'; $lblGpuApi.Text=T 'GpuApi'; $lblSwapDepth.Text=T 'SwapchainDepth'; $lblInputFormat.Text=T 'InputFormat'; $lblLog.Text=T 'LogTitle'
    $hlpRtbuf.Text=T 'RtbufHelp'; $hlpVideo.Text=T 'VideoSizeHelp'; $hlpFps.Text=T 'FpsHelp'; $hlpThreads.Text=T 'ThreadsHelp'; $hlpScale.Text=T 'WindowScaleHelp'; $hlpDemuxer.Text=T 'DemuxerHelp'; $hlpVo.Text=T 'VoHelp'; $hlpHwdec.Text=T 'HwdecHelp'; $hlpGpuApi.Text=T 'GpuApiHelp'; $hlpSwapDepth.Text=T 'SwapchainDepthHelp'; $hlpInputFormat.Text=T 'InputFormatHelp'
    $btnReload.Text=T 'Reload'; $btnSave.Text=T 'Save'; $btnRestoreDefaults.Text=T 'RestoreDefaults'; $btnSaveCustom.Text=T 'SaveCustom'; $btnImportCustom.Text=T 'ImportCustom'
    Set-ListItems $lbRtbuf @('16M','24M','32M','48M','64M','128M','256M')
    Set-ListItems $lbVideoSize @('1280x720','1920x1080','2048x1152','2560x1440','3840x2160')
    Set-ListItems $lbFps @((T 'Auto'),'60','30','120')
    Set-ListItems $lbThreads @('1','0')
    Set-ListItems $lbWindowScale @('0.5','0.75','1.0','1.25','2.0')
    Set-ListItems $lbHwdec @('no','auto-safe','auto','yes')
    Set-ListItems $lbVo @('gpu-next','gpu')
    Set-ListItems $lbDemuxer @('no','yes')
    Set-ListItems $lbGpuApi @('d3d11','vulkan','opengl','auto')
    Set-ListItems $lbSwapchainDepth @('1','2','3')
    Set-ListItems $lbInputFormat @('auto','mjpeg','yuyv422','nv12','i420','h264')
    Sync-Paths
    Refresh-Log
    if($saved){ Apply-ValuesToForm $saved }
}

# ============================================================
#  EVENTS
# ============================================================
$btnEN.Add_Click({
    Apply-Lang 'EN'
    Save-GUILanguage 'EN'
})

$btnES.Add_Click({
    Apply-Lang 'ES'
    Save-GUILanguage 'ES'
})

$btnReload.Add_Click({ try { Load-ValuesToForm; Set-StatusKey 'MsgReload' } catch { Set-Status $_.Exception.Message } })
$btnSave.Add_Click({ try { Save-Bat } catch { Set-Status $_.Exception.Message } })
$btnRestoreDefaults.Add_Click({ try { $ans=[Windows.Forms.MessageBox]::Show((T 'MsgDefaultsConfirm'),(T 'MsgConfirmTitle'),[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question); if($ans -ne [Windows.Forms.DialogResult]::Yes){ return }; Apply-DefaultOptions } catch { Set-Status $_.Exception.Message } })
$btnSaveCustom.Add_Click({ try { Save-CustomJson } catch { Set-Status $_.Exception.Message } })
$btnImportCustom.Add_Click({ try { $ans=[Windows.Forms.MessageBox]::Show((T 'MsgImportConfirm'),(T 'MsgConfirmTitle'),[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question); if($ans -ne [Windows.Forms.DialogResult]::Yes){ return }; Import-CustomJson } catch { Set-Status $_.Exception.Message } })

# ============================================================
#  INIT
# ============================================================
$savedLang = Load-GUILanguage
Apply-Lang $savedLang

try { Load-ValuesToForm; Set-StatusKey 'MsgReload' } catch { Set-Status $_.Exception.Message }
[void]$form.ShowDialog()