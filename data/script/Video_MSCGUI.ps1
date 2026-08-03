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

$script:AppUserModelID = "TyRaS.MPVSWCapture.VideoManager"
try {
    [TaskbarAppId]::SetCurrentProcessExplicitAppUserModelID($script:AppUserModelID) | Out-Null
} catch {}

# ============================================================
#  PATH DETECTION (simplified, works from data/script)
# ============================================================
function Get-ScriptDir {
    try { if ($PSCommandPath) { return (Split-Path -Parent $PSCommandPath) } } catch {}
    try { if ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) { return (Split-Path -Parent $MyInvocation.MyCommand.Path) } } catch {}
    return (Get-Location).Path
}

function Get-RootDir {
    $scriptDir = Get-ScriptDir
    # If the script is inside data/script, go up two levels to get the root
    if ((Split-Path $scriptDir -Leaf) -eq 'script' -and (Split-Path (Split-Path $scriptDir -Parent) -Leaf) -eq 'data') {
        $root = Split-Path -Parent (Split-Path -Parent $scriptDir)
        return $root
    }
    # Fallback: use the script's directory as root
    return $scriptDir
}

# --- Determine paths ---
$script:RootDir = Get-RootDir
$script:ScriptDir = Get-ScriptDir  # Should be data/script
$script:ToolsDir = Join-Path $script:RootDir "tools"   # Real tools folder
$script:BatPath = Join-Path $script:RootDir "data\MPV-SW-Capture.bat"
$script:JsonPath = Join-Path $script:ToolsDir "user-video_options.json"

$script:CurrentLang = 'EN'
$script:LogEntries = New-Object System.Collections.Generic.List[object]
$script:DefaultLine = 'start "" /b "%prog1_path%" av://dshow:video="%video_device%" --profile=low-latency --demuxer-lavf-o-set=rtbufsize=64M --sws-scaler=point --demuxer-lavf-o-set=video_size=1920x1080 --container-fps-override=60 --vd-lavc-threads=1 --untimed --no-border --demuxer-thread=no --vo=gpu-next --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no'

# ============================================================
#  FORM ICON (prioritizes data\icon\videomsc.ico)
# ============================================================
function Get-AppIcon {
    try {
        $customIconPath = Join-Path $script:RootDir "data\icon\videomsc.ico"
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
#  LANGUAGES AND CORE LOGIC (unchanged from original)
# ============================================================
$script:Lang = @{
EN = @{
Title='MPV-SW-Capture - Video Options Manager'; Header='Edit video options in MPV-SW-Capture.bat.'; LangLabel='GUI Language';
Files='Paths'; FilesNote='The GUI program stays in /tools. The file edited by this program is /data/MPV-SW-Capture.bat. Custom JSON files are saved in /tools.';
Root='Root folder'; Tools='Tools folder'; Bat='BAT file'; Json='Custom JSON';
Settings='MPV launch settings'; Actions='Actions';
Rtbuf='Video Buffer Size'; VideoSize='Video Resolution'; Fps='FPS'; Threads='Video Decode Threads'; WindowScale='Window Scale'; DemuxerThread='Demuxer Thread'; Vo='Video Output'; Hwdec='Hardware Decode';
Reload='Reload from BAT'; Save='Save to BAT'; RestoreDefaults='Restore DEFAULT Options'; SaveCustom='Save Custom Options'; ImportCustom='Import Custom Options';
MsgBatMissing='MPV-SW-Capture.bat was not found in /data.'; MsgLineMissing='The mpv start line was not found in the BAT file.'; MsgSaved='BAT file updated successfully.'; MsgReload='Values reloaded from BAT.'; MsgDefaultsApplied='Default options restored and written to BAT.'; MsgJsonSaved='Custom options JSON saved.'; MsgJsonImported='Custom options imported and written to BAT.'; MsgJsonMissing='JSON file was not found.'; MsgJsonInvalid='The JSON file is invalid or incomplete.'; MsgImportConfirm='Do you want to import the JSON file and replace the BAT options?'; MsgDefaultsConfirm='Do you want to restore the default video options?'; MsgConfirmTitle='Confirm';
LogTitle='Log'; RtbufHelp='Set the video buffer size used by mpv before playback. Lower values reduce lag, while higher values improve stability."64M" is the default option.'; VideoSizeHelp='Force the default resolution. "1080p" is the most stable option; higher values increase usage and can cause lag. Use "720p" if you still get lag at 1080p.'; FpsHelp='Force the default FPS. "Auto" uses the Capture Card FPS. "60" is the default option.'; ThreadsHelp='Select video decode threads. "1" is the best option for low latency; "0" uses the automatic value and can increase buffering.'; DemuxerHelp='Enable or disable the demuxer thread used while reading the stream. "no" is the recommended option to reduce latency.'; VoHelp='Select the video output renderer. "gpu-next" is the modern and best option; "gpu" is an option for older PCs.'; HwdecHelp='"no" is the default and disables it; "auto-safe" reduces the CPU usage with hardware acceleration."auto","yes", are more aggressive options.'; WindowScaleHelp='Adjust the initial mpv window size. Higher values make the window larger and can slightly increase rendering load.'; Auto='Auto'; Yes='Yes'; No='No'; DefaultWord='Default'; JsonFilter='JSON files (*.json)|*.json';
};
ES = @{
Title='MPV-SW-Capture - Video Options Manager'; Header='Edita las opciones de video en MPV-SW-Capture.bat.'; LangLabel='Idioma del GUI';
Files='Rutas'; FilesNote='El programa GUI queda en /tools. El archivo que edita este programa es /data/MPV-SW-Capture.bat. Los JSON personalizados se guardan en /tools.';
Root='Carpeta raiz'; Tools='Carpeta tools'; Bat='Archivo BAT'; Json='JSON personalizado';
Settings='Opciones de inicio de MPV'; Actions='Acciones';
Rtbuf='Tamano del buffer de video'; VideoSize='Resolucion de video'; Fps='FPS'; Threads='Hilos de decodificacion de video'; WindowScale='Escala de ventana'; DemuxerThread='Hilo del demuxer'; Vo='Salida de video'; Hwdec='Decodificacion por hardware';
Reload='Recargar desde BAT'; Save='Guardar en BAT'; RestoreDefaults='Restaurar Opciones por DEFECTO'; SaveCustom='Guardar Opciones Personalizadas'; ImportCustom='Importar Opciones Personalizadas';
MsgBatMissing='No se encontro MPV-SW-Capture.bat en /data.'; MsgLineMissing='No se encontro la linea de inicio de mpv dentro del BAT.'; MsgSaved='BAT actualizado correctamente.'; MsgReload='Valores recargados desde el BAT.'; MsgDefaultsApplied='Las opciones por defecto fueron restauradas y escritas en el BAT.'; MsgJsonSaved='El JSON de opciones personalizadas fue guardado.'; MsgJsonImported='Las opciones personalizadas fueron importadas y escritas en el BAT.'; MsgJsonMissing='No se encontro el archivo JSON.'; MsgJsonInvalid='El archivo JSON es invalido o esta incompleto.'; MsgImportConfirm='Deseas importar el archivo JSON y reemplazar las opciones del BAT?'; MsgDefaultsConfirm='Deseas restaurar las opciones de video por defecto?'; MsgConfirmTitle='Confirmar';
LogTitle='Log'; RtbufHelp='Define el tamano del buffer de video que usa mpv antes de reproducir. Valores bajos reducen el lag; valores altos mejoran la estabilidad. "64M" por defecto.'; VideoSizeHelp='Fuerza la resolucion por defecto. "1080p" es la opcion mas estable; valores mas altos aumentan consumo y puede producir lag. Usa "720p" si tienes lag en 1080p.'; FpsHelp='Fuerza el FPS por defecto. "Auto" usa el FPS de la capturadora. "60" por defecto.'; ThreadsHelp='Elige la cantidad hilos. "1" es la mejor opcion para baja latencia; "0" usa el valor automatico y puede aumentar el buffering.'; DemuxerHelp='Activa o desactiva el hilo del demuxer usado al leer la senal. "no" es la opcion recomendada para reducir la latencia.'; VoHelp='Elige el renderizador de salida de video. "gpu-next" es la opcion moderna y mejor; "gpu" es para PCs mas antiguos.'; HwdecHelp='"no" es la opcion por defecto y lo desactiva; "auto-safe" reduce el uso de CPU con aceleracion por hardware. "auto","yes", son opciones mas agresivas.'; WindowScaleHelp='Ajusta el tamano inicial de la ventana. Valores mas altos agrandan la ventana y pueden aumentar un poco la carga de renderizado.'; Auto='Auto'; Yes='Si'; No='No'; DefaultWord='Defecto'; JsonFilter='Archivos JSON (*.json)|*.json';
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

$script:DefaultOptionMap = @{
    rtbuf         = '64M'
    videoSize     = '1920x1080'
    fps           = '60'
    threads       = '1'
    windowScale   = '1.0'
    demuxerThread = 'no'
    vo            = 'gpu-next'
    hwdec         = 'no'
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
function Get-MpvLineIndex([string[]]$Lines){ for($i=0; $i -lt $Lines.Count; $i++){ if($Lines[$i] -match 'start "" /b "%prog1_path%"' -and $Lines[$i] -match 'av://dshow:video='){ return $i } }; return -1 }
function Parse-LineToValues([string]$line){
    $rtbuf = Get-OptionValue $line 'demuxer-lavf-o-set=rtbufsize'; if([string]::IsNullOrWhiteSpace($rtbuf)){ $rtbuf = '64M' }
    $videoSize = Get-OptionValue $line 'demuxer-lavf-o-set=video_size'; if([string]::IsNullOrWhiteSpace($videoSize)){ $videoSize = '1920x1080' }
    $fps = Get-OptionValue $line 'container-fps-override'; if([string]::IsNullOrWhiteSpace($fps)){ $fps = '__AUTO__' }
    $threads = Get-OptionValue $line 'vd-lavc-threads'; if([string]::IsNullOrWhiteSpace($threads)){ $threads = '1' }
    $windowScale = Get-OptionValue $line 'window-scale'; if([string]::IsNullOrWhiteSpace($windowScale)){ $windowScale = '1.0' }
    $demuxerThread = Get-OptionValue $line 'demuxer-thread'; if([string]::IsNullOrWhiteSpace($demuxerThread)){ $demuxerThread = 'no' }
    $vo = Get-OptionValue $line 'vo'; if([string]::IsNullOrWhiteSpace($vo)){ $vo = 'gpu-next' }
    $hwdec = Get-OptionValue $line 'hwdec'; if([string]::IsNullOrWhiteSpace($hwdec)){ $hwdec = 'no' }
    return @{ rtbuf=$rtbuf; videoSize=$videoSize; fps=$fps; threads=$threads; windowScale=$windowScale; demuxerThread=$demuxerThread; vo=$vo; hwdec=$hwdec }
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
function Apply-ValuesToForm($v){ Set-ListValue $lbRtbuf $v.rtbuf; Set-ListValue $lbVideoSize $v.videoSize; Set-ListValue $lbFps $v.fps; Set-ListValue $lbThreads $v.threads; Set-ListValue $lbWindowScale $v.windowScale; Set-ListValue $lbDemuxer $v.demuxerThread; Set-ListValue $lbVo $v.vo; Set-ListValue $lbHwdec $v.hwdec }
function Load-ValuesToForm { $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; Apply-ValuesToForm (Parse-LineToValues $lines[$idx]) }
function Get-FormValues {
    return @{ rtbuf=(Get-LogicalListItemValue $lbRtbuf ([string]$lbRtbuf.SelectedItem)); videoSize=(Get-LogicalListItemValue $lbVideoSize ([string]$lbVideoSize.SelectedItem)); fps=(Get-LogicalListItemValue $lbFps ([string]$lbFps.SelectedItem)); threads=(Get-LogicalListItemValue $lbThreads ([string]$lbThreads.SelectedItem)); windowScale=(Get-LogicalListItemValue $lbWindowScale ([string]$lbWindowScale.SelectedItem)); demuxerThread=(Get-LogicalListItemValue $lbDemuxer ([string]$lbDemuxer.SelectedItem)); vo=(Get-LogicalListItemValue $lbVo ([string]$lbVo.SelectedItem)); hwdec=(Get-LogicalListItemValue $lbHwdec ([string]$lbHwdec.SelectedItem)) }
}
function Apply-ValuesToLine([string]$line,$v){
    $line = Set-Or-ReplaceOption $line 'demuxer-lavf-o-set=rtbufsize' $v.rtbuf
    $line = Set-Or-ReplaceOption $line 'demuxer-lavf-o-set=video_size' $v.videoSize
    if($v.fps -eq '__AUTO__'){ $line = Remove-Option $line 'container-fps-override' } else { $line = Set-Or-ReplaceOption $line 'container-fps-override' $v.fps }
    $line = Set-Or-ReplaceOption $line 'vd-lavc-threads' $v.threads
    $line = Set-Or-ReplaceOption $line 'window-scale' $v.windowScale
    $line = Set-Or-ReplaceOption $line 'demuxer-thread' $v.demuxerThread
    $line = Set-Or-ReplaceOption $line 'vo' $v.vo
    $line = Set-Or-ReplaceOption $line 'hwdec' $v.hwdec
    return (Normalize-Spaces $line)
}
function Save-Bat { $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; $lines[$idx] = Apply-ValuesToLine $lines[$idx] (Get-FormValues); [IO.File]::WriteAllLines($script:BatPath,$lines,[Text.UTF8Encoding]::new($false)); Set-StatusKey 'MsgSaved' }
function Apply-DefaultOptions { $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; $lines[$idx] = $script:DefaultLine; [IO.File]::WriteAllLines($script:BatPath,$lines,[Text.UTF8Encoding]::new($false)); Apply-ValuesToForm (Parse-LineToValues $script:DefaultLine); Set-StatusKey 'MsgDefaultsApplied' }
function Save-CustomJson { $v = Get-FormValues | ConvertTo-Json -Depth 4; [IO.File]::WriteAllText($script:JsonPath,$v,[Text.UTF8Encoding]::new($false)); Set-StatusKeyEx 'MsgJsonSaved' ("`r`n" + $script:JsonPath) }
function Import-CustomJson { $ofd = New-Object Windows.Forms.OpenFileDialog; $ofd.Filter = T 'JsonFilter'; if($ofd.ShowDialog() -ne 'OK'){ return }; if(-not (Test-Path -LiteralPath $ofd.FileName)){ throw (T 'MsgJsonMissing') }; $raw = Get-Content -LiteralPath $ofd.FileName -Raw -Encoding UTF8; $obj = $raw | ConvertFrom-Json; if($null -eq $obj.rtbuf -or $null -eq $obj.videoSize -or $null -eq $obj.fps -or $null -eq $obj.threads -or $null -eq $obj.windowScale -or $null -eq $obj.demuxerThread -or $null -eq $obj.vo -or $null -eq $obj.hwdec){ throw (T 'MsgJsonInvalid') }; $vals = @{ rtbuf=[string]$obj.rtbuf; videoSize=[string]$obj.videoSize; fps=[string]$obj.fps; threads=[string]$obj.threads; windowScale=[string]$obj.windowScale; demuxerThread=[string]$obj.demuxerThread; vo=[string]$obj.vo; hwdec=[string]$obj.hwdec }; Apply-ValuesToForm $vals; $lines = Load-BatLines; $idx = Get-MpvLineIndex $lines; if($idx -lt 0){ throw (T 'MsgLineMissing') }; $lines[$idx] = Apply-ValuesToLine $lines[$idx] $vals; [IO.File]::WriteAllLines($script:BatPath,$lines,[Text.UTF8Encoding]::new($false)); Set-StatusKey 'MsgJsonImported' }

$form=New-Object Windows.Forms.Form
$form.Text = T 'Title'
try {
    $appIcon = Get-AppIcon
    if ($appIcon) {
        $form.Icon = $appIcon
        $form.Refresh()
    }
} catch {
    # Silently ignore icon errors
}
$form.ClientSize=New-Object Drawing.Size(1120,790)
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
$gbSettings.Location=New-Object Drawing.Point(14,178); $gbSettings.Size=New-Object Drawing.Size(1092,378); $gbSettings.ForeColor=$script:TEXT; $gbSettings.BackColor=$script:BG
$form.Controls.Add($gbSettings)
function Add-SectionLabel([string]$text,[int]$x,[int]$y,[int]$w){ $lbl=New-Lbl $text $x $y $w 18 $FontBold $script:TEXT; $gbSettings.Controls.Add($lbl); return $lbl }
$leftX=18; $rightX=556

$lblRtbuf = Add-SectionLabel '' $leftX 24 180
$hlpRtbuf = New-Lbl '' 18 40 180 72 $FontSmall $script:ACCENT3
$lbRtbuf = New-List 200 24 320 88
$lbRtbuf.Tag = 'rtbuf'
$lbRtbuf.ItemHeight = 15
Set-ListItems $lbRtbuf @('32M','64M','128M','256M','512M','768M','1024M')
$gbSettings.Controls.AddRange(@($hlpRtbuf,$lbRtbuf))

$lblVideo = Add-SectionLabel '' $rightX 24 180
$hlpVideo = New-Lbl '' 556 40 180 72 $FontSmall $script:ACCENT3
$lbVideoSize = New-List 742 24 314 88
$lbVideoSize.Tag = 'videoSize'
$lbVideoSize.ItemHeight = 16
Set-ListItems $lbVideoSize @('1280x720','1920x1080','2048x1152','2560x1440','3840x2160')
$gbSettings.Controls.AddRange(@($hlpVideo,$lbVideoSize))

$lblFps = Add-SectionLabel '' $leftX 126 180
$hlpFps = New-Lbl '' 18 142 170 42 $FontSmall $script:ACCENT3
$lbFps = New-List 200 128 320 62
$lbFps.Tag = 'fps'
$lbFps.ItemHeight = 15
Set-ListItems $lbFps @((T 'Auto'),'60','30','24')
$gbSettings.Controls.AddRange(@($hlpFps,$lbFps))

$lblThreads = Add-SectionLabel '' $rightX 126 186
$hlpThreads = New-Lbl '' 556 142 180 52 $FontSmall $script:ACCENT3
$lbThreads = New-List 742 128 314 62
$lbThreads.Tag = 'threads'
$lbThreads.ItemHeight = 18
Set-ListItems $lbThreads @('1','0')
$gbSettings.Controls.AddRange(@($hlpThreads,$lbThreads))

$lblScale = Add-SectionLabel '' $leftX 206 180
$hlpScale = New-Lbl '' 18 222 170 72 $FontSmall $script:ACCENT3
$lbWindowScale = New-List 200 210 320 78
$lbWindowScale.Tag = 'windowScale'
$lbWindowScale.ItemHeight = 15
Set-ListItems $lbWindowScale @('0.5','0.75','1.0','1.25','2.0')
$gbSettings.Controls.AddRange(@($hlpScale,$lbWindowScale))

$lblHwdec = Add-SectionLabel '' $rightX 206 180
$hlpHwdec = New-Lbl '' 556 222 180 72 $FontSmall $script:ACCENT3
$lbHwdec = New-List 742 210 314 78
$lbHwdec.Tag = 'hwdec'
$lbHwdec.ItemHeight = 18
Set-ListItems $lbHwdec @('no','auto-safe','auto','yes')
$gbSettings.Controls.AddRange(@($hlpHwdec,$lbHwdec))

$lblVo = Add-SectionLabel '' $leftX 300 180
$hlpVo = New-Lbl '' 18 316 170 52 $FontSmall $script:ACCENT3
$lbVo = New-List 200 304 320 48
$lbVo.Tag = 'vo'
$lbVo.ItemHeight = 18
Set-ListItems $lbVo @('gpu-next','gpu')
$gbSettings.Controls.AddRange(@($hlpVo,$lbVo))

$lblDemuxer = Add-SectionLabel '' $rightX 300 180
$hlpDemuxer = New-Lbl '' 556 316 180 52 $FontSmall $script:ACCENT3
$lbDemuxer = New-List 742 304 314 48
$lbDemuxer.Tag = 'demuxerThread'
$lbDemuxer.ItemHeight = 18
Set-ListItems $lbDemuxer @('no','yes')
$gbSettings.Controls.AddRange(@($hlpDemuxer,$lbDemuxer))

$gbActions=New-Object Windows.Forms.GroupBox
$gbActions.Location=New-Object Drawing.Point(14,566)
$gbActions.Size=New-Object Drawing.Size(1092,196)
$gbActions.ForeColor=$script:TEXT
$gbActions.BackColor=$script:BG
$form.Controls.Add($gbActions)

$btnReload=New-Object Windows.Forms.Button
$btnReload.Location=New-Object Drawing.Point(210,28)
$btnReload.Size=New-Object Drawing.Size(210,34)
Style-Btn $btnReload $script:ACCENT $script:BG

$btnRestoreDefaults=New-Object Windows.Forms.Button
$btnRestoreDefaults.Location=New-Object Drawing.Point(436,28)
$btnRestoreDefaults.Size=New-Object Drawing.Size(240,34)
Style-Btn $btnRestoreDefaults $script:ACCENT3 $script:BG
$btnRestoreDefaults.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)

$btnImportCustom=New-Object Windows.Forms.Button
$btnImportCustom.Location=New-Object Drawing.Point(690,28)
$btnImportCustom.Size=New-Object Drawing.Size(250,34)
Style-Btn $btnImportCustom $script:ACCENT $script:BG
$btnImportCustom.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)

$btnSave=New-Object Windows.Forms.Button
$btnSave.Location=New-Object Drawing.Point(325,72)
$btnSave.Size=New-Object Drawing.Size(210,34)
Style-Btn $btnSave $script:ACCENT2 $script:BG

$btnSaveCustom=New-Object Windows.Forms.Button
$btnSaveCustom.Location=New-Object Drawing.Point(555,72)
$btnSaveCustom.Size=New-Object Drawing.Size(244,34)
Style-Btn $btnSaveCustom $script:ACCENT2 $script:BG
$btnSaveCustom.Font = New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)

$lblLog = New-Lbl '' 18 118 120 18 $FontBold $script:TEXT

$tbLog=New-Object Windows.Forms.TextBox
$tbLog.Location=New-Object Drawing.Point(18,140)
$tbLog.Size=New-Object Drawing.Size(1052,44)
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
    $lblRtbuf.Text=T 'Rtbuf'; $lblVideo.Text=T 'VideoSize'; $lblFps.Text=T 'Fps'; $lblThreads.Text=T 'Threads'; $lblScale.Text=T 'WindowScale'; $lblDemuxer.Text=T 'DemuxerThread'; $lblVo.Text=T 'Vo'; $lblHwdec.Text=T 'Hwdec'; $lblLog.Text=T 'LogTitle'
    $hlpRtbuf.Text=T 'RtbufHelp'; $hlpVideo.Text=T 'VideoSizeHelp'; $hlpFps.Text=T 'FpsHelp'; $hlpThreads.Text=T 'ThreadsHelp'; $hlpScale.Text=T 'WindowScaleHelp'; $hlpDemuxer.Text=T 'DemuxerHelp'; $hlpVo.Text=T 'VoHelp'; $hlpHwdec.Text=T 'HwdecHelp'
    $btnReload.Text=T 'Reload'; $btnSave.Text=T 'Save'; $btnRestoreDefaults.Text=T 'RestoreDefaults'; $btnSaveCustom.Text=T 'SaveCustom'; $btnImportCustom.Text=T 'ImportCustom'
    Set-ListItems $lbRtbuf @('32M','64M','128M','256M','512M','768M','1024M')
    Set-ListItems $lbVideoSize @('1280x720','1920x1080','2048x1152','2560x1440','3840x2160')
    Set-ListItems $lbFps @((T 'Auto'),'60','30','24')
    Set-ListItems $lbThreads @('1','0')
    Set-ListItems $lbWindowScale @('0.5','0.75','1.0','1.25','2.0')
    Set-ListItems $lbHwdec @('no','auto-safe','auto','yes')
    Set-ListItems $lbVo @('gpu-next','gpu')
    Set-ListItems $lbDemuxer @('no','yes')
    Sync-Paths
    Refresh-Log
    if($saved){ Apply-ValuesToForm $saved }
}

$btnEN.Add_Click({ Apply-Lang 'EN' })
$btnES.Add_Click({ Apply-Lang 'ES' })
$btnReload.Add_Click({ try { Load-ValuesToForm; Set-StatusKey 'MsgReload' } catch { Set-Status $_.Exception.Message } })
$btnSave.Add_Click({ try { Save-Bat } catch { Set-Status $_.Exception.Message } })
$btnRestoreDefaults.Add_Click({ try { $ans=[Windows.Forms.MessageBox]::Show((T 'MsgDefaultsConfirm'),(T 'MsgConfirmTitle'),[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question); if($ans -ne [Windows.Forms.DialogResult]::Yes){ return }; Apply-DefaultOptions } catch { Set-Status $_.Exception.Message } })
$btnSaveCustom.Add_Click({ try { Save-CustomJson } catch { Set-Status $_.Exception.Message } })
$btnImportCustom.Add_Click({ try { $ans=[Windows.Forms.MessageBox]::Show((T 'MsgImportConfirm'),(T 'MsgConfirmTitle'),[Windows.Forms.MessageBoxButtons]::YesNo,[Windows.Forms.MessageBoxIcon]::Question); if($ans -ne [Windows.Forms.DialogResult]::Yes){ return }; Import-CustomJson } catch { Set-Status $_.Exception.Message } })

Apply-Lang 'EN'
try { Load-ValuesToForm; Set-StatusKey 'MsgReload' } catch { Set-Status $_.Exception.Message }
[void]$form.ShowDialog()