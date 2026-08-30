# Install_MSCGUI.ps1 - By TyRaS-SW
# GUI Installer/Updater for MPV-SW-Capture
# EN/ES GUI - PowerShell 5+ (Windows 10/11)

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

$script:AppUserModelID = "TyRaS.MPVSWCapture.Installer"
try {
    [TaskbarAppId]::SetCurrentProcessExplicitAppUserModelID($script:AppUserModelID) | Out-Null
} catch {}

# ============================================================
#  ROBUST PATH DETECTION (simplified)
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
    # Fallback: use the script's directory as root (for compatibility)
    return $scriptDir
}

$script:RootDir = Get-RootDir
$script:ScriptDir = Get-ScriptDir  # Should be data/script

# ============================================================
#  LANGUAGE PERSISTENCE (shared with other tools)
# ============================================================
$script:LangFilePath = Join-Path $script:RootDir "data\script\GUILang.dat"

function Load-GUILanguage {
    if (Test-Path $script:LangFilePath) {
        try {
            $content = Get-Content $script:LangFilePath -Encoding UTF8 -Raw
            $content = $content.Trim().ToUpper()
            if ($content -eq "EN" -or $content -eq "ES") {
                return $content
            }
        } catch {}
    }
    Save-GUILanguage "EN"
    return "EN"
}

function Save-GUILanguage([string]$lang) {
    $dir = Split-Path -Parent $script:LangFilePath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $content = if ($lang -eq "EN") { "en" } else { "es" }
    [System.IO.File]::WriteAllText($script:LangFilePath, $content, [System.Text.Encoding]::UTF8)
}

# ============================================================
#  FORM ICON (prioritizes data\icon\installmsc.ico)
# ============================================================
function Get-AppIcon {
    try {
        $customIconPath = Join-Path $script:RootDir "data\icon\installmsc.ico"
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
#  COLOR PALETTE  (amber/orange - distinct from Setup blue)
# ============================================================
$script:BG      = [System.Drawing.Color]::FromArgb(18,  17,  14)
$script:SURFACE = [System.Drawing.Color]::FromArgb(28,  26,  20)
$script:CARD    = [System.Drawing.Color]::FromArgb(38,  35,  26)
$script:ACCENT  = [System.Drawing.Color]::FromArgb(251, 191,  36)
$script:ACCENT2 = [System.Drawing.Color]::FromArgb(74,  222, 128)
$script:ACCENT3 = [System.Drawing.Color]::FromArgb(251, 146,  60)
$script:TEXT    = [System.Drawing.Color]::FromArgb(230, 225, 210)
$script:MUTED   = [System.Drawing.Color]::FromArgb(140, 130, 110)
$script:SUCCESS = [System.Drawing.Color]::FromArgb(72,  199, 116)
$script:ERROR_C = [System.Drawing.Color]::FromArgb(255, 100, 100)
$script:NOTE_C  = [System.Drawing.Color]::FromArgb(220, 200, 130)
$script:EXE_OK  = [System.Drawing.Color]::FromArgb(50,  160,  80)
$script:EXE_ERR = [System.Drawing.Color]::FromArgb(180,  50,  50)

# ============================================================
#  FONTS
# ============================================================
$FontTitle        = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontSub          = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Regular)
$FontBold         = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Bold)
$FontBtn          = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontSmall        = New-Object System.Drawing.Font("Segoe UI",  8, [System.Drawing.FontStyle]::Regular)
$FontBtnSmall     = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Bold)
$FontNote         = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Regular)
$FontSectionTitle = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Bold)
$FontLangBtn      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$FontMono         = New-Object System.Drawing.Font("Consolas",  8, [System.Drawing.FontStyle]::Regular)

# ============================================================
#  STRINGS EN / ES
# ============================================================
$script:Lang = @{}
$script:Lang["EN"] = @{
    Title         = "MPV-SW-Capture - Installer / Updater"
    HeaderSub     = "Installer / Updater  -  Download and update all required software."
    HeaderNote    = "All files are installed in the same folder as this script."
    LangLabel     = "GUI Language:"
    ActionsTitle  = "ACTIONS"
    S1Title       = "INSTALL OR UPDATE ffmpeg + ffplay"
    S1Desc        = "Downloads the latest git build from GyanD/codexffmpeg (GitHub)."
    S1Installed   = "Installed:"
    S1Available   = "Available:"
    S1Result      = "Result:"
    S1None        = "not installed"
    S1Checking    = "Checking..."
    S1BtnCheck    = "Check"
    S1BtnInstall  = "Install / Update"
    S1ModeStable  = "Stable"
    S1ModeDaily   = "Daily"
    S2Title       = "INSTALL OR UPDATE mpv"
    S2Desc        = "Downloads the latest build from zhongfly/mpv-winbuild (GitHub)."
    S2Installed   = "Installed:"
    S2Available   = "Available:"
    S2Result      = "Result:"
    S2None        = "not installed"
    S2Checking    = "Checking..."
    S2BtnCheck    = "Check"
    S2BtnInstall  = "Install / Update"
    S2VariantLbl  = "Variant:"
    S2V1          = "x86_64  (64-bit, all CPUs)"
    S2V2          = "x86_64-v3  (64-bit, Intel Haswell 2013+/AMD Excavator+)"
    S2V3          = "aarch64  (ARM64)"
    S3Title       = "INSTALL OR UPDATE MPV-SW-Capture"
    S3Desc        = "Downloads the latest release from MPV-SW-Capture (GitHub)."
    S3Installed   = "Installed:"
    S3Available   = "Available:"
    S3Result      = "Result:"
    S3None        = "not installed"
    S3Checking    = "Checking..."
    S3BtnCheck    = "Check"
    S3BtnInstall  = "Install / Update"
    S4Title       = "INSTALLED VERSIONS"
    S4Label       = "Installed versions and update status:"
    ActCheckAll   = "Check All"
    ActUpdateAll  = "Install / Update ALL"
    ActForce      = "Force Reinstall ALL"
    ForceConfirmTitle = "Confirm full reinstall"
    ForceConfirmText  = "Are you sure you want to force reinstall all components?`r`n`r`nThis will redownload and reinstall ffmpeg, ffplay, mpv and MPV-SW-Capture."
    StatusLbl         = "STATUS"
    StatusReady       = "Ready."
    StatusChecking    = "Checking versions..."
    StatusDownloading = "Downloading..."
    StatusDone        = "Done!"
    StatusUpToDate    = "All up to date."
    LogReady          = "Installer ready. Select an action."
    LogCheckingFF     = "[ffmpeg]  Checking latest version..."
    LogCheckingMpv    = "[mpv]     Checking latest version..."
    LogCheckingMySW   = "[MPV-SW]  Checking latest version..."
    LogFFUpToDate     = "[ffmpeg]  Already up to date ({0})."
    LogMpvUpToDate    = "[mpv]     Already up to date ({0})."
    LogMySWUpToDate   = "[MPV-SW]  Already up to date ({0})."
    LogFFDownload     = "[ffmpeg]  Downloading {0}..."
    LogMpvDownload    = "[mpv]     Downloading {0}..."
    LogMySWDownload   = "[MPV-SW]  Downloading {0}..."
    LogFFExtracting   = "[ffmpeg]  Extracting ffmpeg.exe and ffplay.exe..."
    LogMpvExtracting  = "[mpv]     Extracting mpv.exe..."
    LogMySWExtracting = "[MPV-SW]  Extracting files..."
    LogFFDone         = "[ffmpeg]  Installed. Version: {0}"
    LogMpvDone        = "[mpv]     Installed. Version: {0} [{1}]"
    LogMySWDone       = "[MPV-SW]  Installed. Version: {0}"
    LogFFError        = "[ffmpeg]  Error: {0}"
    LogMpvError       = "[mpv]     Error: {0}"
    LogMySWError      = "[MPV-SW]  Error: {0}"
    LogAllDone        = "All operations completed."
    LogFFNotFound     = "[ffmpeg]  No essentials asset found in release."
    LogMpvNotFound    = "[mpv]     No compatible .7z asset found for variant '{0}'."
    LogMySWNotFound   = "[MPV-SW]  No .zip asset found in release."
    Log7zError        = "[7zr]     Could not download 7zr.exe: {0}"
    LogApiError       = "GitHub API error for {0}: {1}"
    ResLatest         = "You have the latest version installed!"
    ResUpdate         = "You should update to the latest version."
    ResNewer          = "You have a newer version not available yet. You should not update."
    ResMissing        = "You do not have any version installed. You must install!"
    ResUnknown        = "Version not checked yet."
    SumUnknown        = "Update unknown"
    LogRateLimit      = "GitHub API rate limit reached. Add scripts/.github-token.txt or set GITHUB_TOKEN."
    StatusRateLimit   = "API limit reached. Wait ~1 hour or use Manual Install."
    StatusRateLimitInline = "API limit reached. Wait ~1 hour or use MANUAL Install."
    SumLatest         = "OK Latest version installed"
    SumOutdated       = "! Update available"
    SumNewer          = "> Local version is newer than offered"
    SumMissing        = "X Not installed"
    IconLatest        = "+"
    IconUpdate        = "!"
    IconNewer         = "?"
    IconMissing       = "x"
}
$script:Lang["ES"] = @{
    Title         = "MPV-SW-Capture - Instalador / Actualizador"
    HeaderSub     = "Instalador / Actualizador  -  Descarga y actualiza todos los softwares necesarios."
    HeaderNote    = "Todos los archivos se instalan en la misma carpeta que este script."
    LangLabel     = "Idioma del GUI:"
    ActionsTitle  = "ACCIONES"
    S1Title       = "INSTALAR O ACTUALIZAR ffmpeg + ffplay"
    S1Desc        = "Descarga el ultimo build git de GyanD/codexffmpeg (GitHub)."
    S1Installed   = "Instalada:"
    S1Available   = "Disponible:"
    S1Result      = "Resultado:"
    S1None        = "no instalado"
    S1Checking    = "Verificando..."
    S1BtnCheck    = "Verificar"
    S1BtnInstall  = "Instalar / Actualizar"
    S1ModeStable  = "Estable"
    S1ModeDaily   = "Diario"
    S1BtnManual   = "MANUAL"
    S2Title       = "INSTALAR O ACTUALIZAR mpv"
    S2Desc        = "Descarga el ultimo build de zhongfly/mpv-winbuild (GitHub)."
    S2Installed   = "Instalada:"
    S2Available   = "Disponible:"
    S2Result      = "Resultado:"
    S2None        = "no instalado"
    S2Checking    = "Verificando..."
    S2BtnCheck    = "Verificar"
    S2BtnInstall  = "Instalar / Actualizar"
    S2BtnManual   = "MANUAL"
    S2VariantLbl  = "Variante:"
    S2V1          = "x86_64  (64-bit, todos CPUs)"
    S2V2          = "x86_64-v3  (64-bit, Intel Haswell 2013+/AMD Excavator+)"
    S2V3          = "aarch64  (ARM64)"
    S3Title       = "INSTALAR O ACTUALIZAR MPV-SW-Capture"
    S3Desc        = "Descarga la ultima release de MPV-SW-Capture (GitHub)."
    S3Installed   = "Instalada:"
    S3Available   = "Disponible:"
    S3Result      = "Resultado:"
    S3None        = "no instalado"
    S3Checking    = "Verificando..."
    S3BtnCheck    = "Verificar"
    S3BtnInstall  = "Instalar / Actualizar"
    S3BtnManual   = "MANUAL"
    S4Title       = "VERSIONES INSTALADAS"
    S4Label       = "Versiones instaladas y estado de actualizacion:"
    ActCheckAll   = "Verificar Todo"
    ActUpdateAll  = "Instalar / Actualizar TODO"
    ActForce      = "Reinstalar TODO (forzar)"
    ForceConfirmTitle = "Confirmar reinstalacion total"
    ForceConfirmText  = "Estas seguro de forzar la reinstalacion de todos los componentes?`r`n`r`nEsto volvera a descargar y reinstalar ffmpeg, ffplay, mpv y MPV-SW-Capture."
    StatusLbl         = "ESTADO"
    StatusReady       = "Listo."
    StatusChecking    = "Verificando versiones..."
    StatusDownloading = "Descargando..."
    StatusDone        = "Listo!"
    StatusUpToDate    = "Todo actualizado."
    LogReady          = "Installer listo. Selecciona una accion."
    LogCheckingFF     = "[ffmpeg]  Verificando ultima version..."
    LogCheckingMpv    = "[mpv]     Verificando ultima version..."
    LogCheckingMySW   = "[MPV-SW]  Verificando ultima version..."
    LogFFUpToDate     = "[ffmpeg]  Ya esta actualizado ({0})."
    LogMpvUpToDate    = "[mpv]     Ya esta actualizado ({0})."
    LogMySWUpToDate   = "[MPV-SW]  Ya esta actualizado ({0})."
    LogFFDownload     = "[ffmpeg]  Descargando {0}..."
    LogMpvDownload    = "[mpv]     Descargando {0}..."
    LogMySWDownload   = "[MPV-SW]  Descargando {0}..."
    LogFFExtracting   = "[ffmpeg]  Extrayendo ffmpeg.exe y ffplay.exe..."
    LogMpvExtracting  = "[mpv]     Extrayendo mpv.exe..."
    LogMySWExtracting = "[MPV-SW]  Extrayendo archivos..."
    LogFFDone         = "[ffmpeg]  Instalado. Version: {0}"
    LogMpvDone        = "[mpv]     Instalado. Version: {0} [{1}]"
    LogMySWDone       = "[MPV-SW]  Instalado. Version: {0}"
    LogFFError        = "[ffmpeg]  Error: {0}"
    LogMpvError       = "[mpv]     Error: {0}"
    LogMySWError      = "[MPV-SW]  Error: {0}"
    LogAllDone        = "Todas las operaciones completadas."
    LogFFNotFound     = "[ffmpeg]  No se encontro asset essentials en la release."
    LogMpvNotFound    = "[mpv]     No se encontro asset .7z para la variante '{0}'."
    LogMySWNotFound   = "[MPV-SW]  No se encontro asset .zip en la release."
    Log7zError        = "[7zr]     No se pudo descargar 7zr.exe: {0}"
    LogApiError       = "Error de API de GitHub para {0}: {1}"
    ResLatest         = "Tienes la ultima version instalada!"
    ResUpdate         = "Deberias actualizar a la ultima version."
    ResNewer          = "Tienes una version mas nueva aun no disponible. No deberias actualizar."
    ResMissing        = "No tienes ninguna version instalada. Debes instalar!"
    ResUnknown        = "Version aun no verificada."
    SumUnknown        = "Actualizacion desconocida"
    LogRateLimit      = "Se alcanzo el limite de GitHub API. Agrega scripts/.github-token.txt o define GITHUB_TOKEN."
    StatusRateLimit   = "Limite API alcanzado. Espera ~1 hora o usa Manual Install."
    StatusRateLimitInline = "Limite API alcanzado. Espera ~1 hora o usa Instalacion MANUAL."
    SumLatest         = "OK Ultima version instalada"
    SumOutdated       = "! Hay actualizacion disponible"
    SumNewer          = "> La version local es mas nueva que la ofrecida"
    SumMissing        = "X No instalado"
    IconLatest        = "+"
    IconUpdate        = "!"
    IconNewer         = "?"
    IconMissing       = "x"
}

$script:CurrentLang = "EN"
function T { param([string]$key) return $script:Lang[$script:CurrentLang][$key] }

# ============================================================
#  PATHS & APIS (now using $script:RootDir)
# ============================================================
$script:SD = $script:RootDir  # All files are installed in the root folder
$script:TempDir     = Join-Path $script:RootDir "_temp_installer"
$script:VersionFile = Join-Path $script:RootDir "scripts\.installed-versions.json"
$script:GitHubTokenFile = Join-Path $script:RootDir "scripts\.github-token.txt"

$FFmpegApiUrl       = "https://api.github.com/repos/GyanD/codexffmpeg/releases?per_page=10"
$FFmpegStableApiUrl = "https://api.github.com/repos/GyanD/codexffmpeg/releases/latest"
$MpvApiUrl    = "https://api.github.com/repos/zhongfly/mpv-winbuild/releases/latest"
$MyRepoApiUrl = "https://api.github.com/repos/TyRaS-SW/MPV-SW-Capture/releases/latest"
$FFmpegLatestPage = "https://github.com/GyanD/codexffmpeg/releases/latest"
$FFmpegReleasesPage = "https://github.com/GyanD/codexffmpeg/releases"
$MpvLatestPage    = "https://github.com/zhongfly/mpv-winbuild/releases/latest"
$MyLatestPage     = "https://github.com/TyRaS-SW/MPV-SW-Capture/releases/latest"

$script:CacheFFVersion = $null
$script:CacheFFUrl = $null
$script:CacheFFMode = $null
$script:CacheMpvRelease = $null
$script:CacheMyRelease = $null
$script:CheckedFFAvailable = $null
$script:CheckedMpvAvailable = $null
$script:CheckedMyAvailable = $null
$script:GitHubRateLimited = $false

function Get-GitHubToken {
    if ($env:GITHUB_TOKEN) { return $env:GITHUB_TOKEN.Trim() }
    if (Test-Path $script:GitHubTokenFile) {
        try { return (Get-Content $script:GitHubTokenFile -Raw -Encoding UTF8).Trim() } catch {}
    }
    return $null
}
function Get-GitHubHeaders {
    $h = @{ 'User-Agent'='MPV-SW-Installer/1.0'; 'Accept'='application/vnd.github+json' }
    $tok = Get-GitHubToken
    if ($tok) { $h['Authorization'] = 'Bearer ' + $tok }
    return $h
}

function Get-FFmpegMode {
    if ($script:rbFFStable -and $script:rbFFStable.Checked) { return 'stable' }
    return 'daily'
}

# ============================================================
#  UI HELPERS  (same as Setup)
# ============================================================
function New-Lbl([string]$text,[int]$x,[int]$y,[int]$w,[int]$h,
                 [System.Drawing.Font]$font,[System.Drawing.Color]$color) {
    if (-not $font)     { $font  = $FontSub }
    if ($color.IsEmpty) { $color = $script:TEXT }
    $l = New-Object System.Windows.Forms.Label
    $l.Text=$text; $l.Location=[System.Drawing.Point]::new($x,$y)
    $l.Size=[System.Drawing.Size]::new($w,$h); $l.Font=$font
    $l.ForeColor=$color; $l.BackColor=[System.Drawing.Color]::Transparent
    $l.AutoSize=$false; return $l
}
function New-Pnl([int]$x,[int]$y,[int]$w,[int]$h,[System.Drawing.Color]$color) {
    if ($color.IsEmpty) { $color = $script:CARD }
    $p = New-Object System.Windows.Forms.Panel
    $p.Location=[System.Drawing.Point]::new($x,$y); $p.Size=[System.Drawing.Size]::new($w,$h)
    $p.BackColor=$color; return $p
}
function New-RB([string]$text,[int]$x,[int]$y,[int]$w) {
    $r = New-Object System.Windows.Forms.RadioButton
    $r.Text=$text; $r.Location=[System.Drawing.Point]::new($x,$y)
    $r.Size=[System.Drawing.Size]::new($w,22); $r.Font=$FontSub
    $r.ForeColor=$script:TEXT; $r.BackColor=[System.Drawing.Color]::Transparent; return $r
}
function Style-Btn([System.Windows.Forms.Button]$btn,
                   [System.Drawing.Color]$bg,[System.Drawing.Color]$fg) {
    if ($bg.IsEmpty) { $bg=$script:ACCENT }
    if ($fg.IsEmpty) { $fg=$script:BG }
    $btn.BackColor=$bg; $btn.ForeColor=$fg; $btn.Font=$FontBtn
    $btn.FlatStyle='Flat'; $btn.FlatAppearance.BorderSize=0
    $btn.Cursor=[System.Windows.Forms.Cursors]::Hand
}

function Set-ManualButtonVisibleText([System.Windows.Forms.Button]$btn,[string]$txt) {
    $btn.Text = $txt
    $btn.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 8, [System.Drawing.FontStyle]::Bold)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.BackColor = [System.Drawing.Color]::FromArgb(45, 38, 26)
    $btn.UseVisualStyleBackColor = $false
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btn.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btn.Padding = [System.Windows.Forms.Padding]::new(0)
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = $script:ACCENT3
    $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 46, 30)
    $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(60, 50, 32)
    $btn.AutoEllipsis = $false
    $btn.AutoSize = $false
    $btn.Refresh()
}

function Style-ManualBtn([System.Windows.Forms.Button]$btn) {
    $btn.Font = $FontBtnSmall
    $btn.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btn.Image = $null
    $btn.UseMnemonic = $false
    $btn.UseVisualStyleBackColor = $false
    $btn.BackColor = [System.Drawing.Color]::FromArgb(36,32,24)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = 'Popup'
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = $script:ACCENT3
    $btn.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(48,42,30)
    $btn.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(54,46,32)
}

function Style-LangBtn([System.Windows.Forms.Button]$btn,[bool]$active) {
    $btn.Font=New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $btn.FlatStyle='Flat'
    $btn.FlatAppearance.BorderSize=1
    $btn.Cursor=[System.Windows.Forms.Cursors]::Hand
    $btn.AutoSize=$false
    $btn.TextAlign=[System.Drawing.ContentAlignment]::MiddleCenter
    $btn.UseMnemonic=$false
    if ($active) {
        $btn.BackColor=$script:ACCENT; $btn.ForeColor=$script:BG
        $btn.FlatAppearance.BorderColor=$script:ACCENT
    } else {
        $btn.BackColor=$script:SURFACE; $btn.ForeColor=$script:MUTED
        $btn.FlatAppearance.BorderColor=$script:MUTED
    }
}

function New-CardXY([System.Windows.Forms.Control]$parent,
    [int]$x,[int]$y,[int]$w,[int]$h,[string]$titleKey) {
    $card=New-Pnl $x $y $w $h $script:CARD
    $bar=New-Pnl 0 0 $w 3 $script:ACCENT; $card.Controls.Add($bar)
    $lT=New-Lbl (T $titleKey) 14 8 ($w-20) 22 $FontSectionTitle $script:ACCENT
    $card.Controls.Add($lT); $parent.Controls.Add($card); return $card
}

# ============================================================
#  VERSION FILE HELPERS
# ============================================================
function Get-InstalledVersions {
    $scriptsDir = Join-Path $script:SD "scripts"
    if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir | Out-Null }
    if (Test-Path $script:VersionFile) {
        try { return Get-Content $script:VersionFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch {}
    }
    return [PSCustomObject]@{ ffmpeg=""; mpv=""; mpvVariant=""; mpvsw="" }
}
function Save-InstalledVersions {
    param([string]$ffmpeg="",[string]$mpv="",[string]$mpvVariant="",[string]$mpvsw="")
    $e = Get-InstalledVersions
    if ($ffmpeg)     { $e | Add-Member -Force -NotePropertyName ffmpeg     -NotePropertyValue $ffmpeg }
    if ($mpv)        { $e | Add-Member -Force -NotePropertyName mpv        -NotePropertyValue $mpv }
    if ($mpvVariant) { $e | Add-Member -Force -NotePropertyName mpvVariant -NotePropertyValue $mpvVariant }
    if ($mpvsw)      { $e | Add-Member -Force -NotePropertyName mpvsw      -NotePropertyValue $mpvsw }
    $sd = Join-Path $script:SD "scripts"
    if (-not (Test-Path $sd)) { New-Item -ItemType Directory -Path $sd | Out-Null }
    $e | ConvertTo-Json | Set-Content $script:VersionFile -Encoding UTF8
}

function Get-MpvSwOfflineVersion {
    $conf = Join-Path $script:SD 'mpv.conf'
    if (-not (Test-Path $conf)) { return $null }
    try {
        $lines = Get-Content $conf -Encoding UTF8 -TotalCount 8
        foreach ($line in $lines) {
            if ($line -match '^\s*#\s*(v\d+\.\d+\.\d+)\s*$') {
                return $Matches[1]
            }
        }
    } catch {}
    return $null
}

function Get-FFmpegOfflineVersion {
    $ff = Join-Path $script:SD 'ffmpeg.exe'
    $fp = Join-Path $script:SD 'ffplay.exe'
    if (-not ((Test-Path $ff) -and (Test-Path $fp))) { return $null }
    try {
        $ver = (& $ff -version 2>$null | Select-Object -First 1)
        if ($ver -match 'ffmpeg version\s+([^\s]+)') {
            return $Matches[1]
        }
    } catch {}
    return '__present__'
}

function Sync-FFmpegVersionFromOffline {
    $offline = Get-FFmpegOfflineVersion
    if (-not $offline) { return $false }
    $json = Get-InstalledVersions
    if ($offline -eq '__present__') {
        if ($json.ffmpeg -and $json.ffmpeg -ne '') { return $false }
        return $false
    }
    $offlineCanon = Get-FFmpegDisplayVersion $offline
    if (-not $offlineCanon) { $offlineCanon = $offline }
    if ($json.ffmpeg -eq $offlineCanon) { return $false }
    Save-InstalledVersions -ffmpeg $offlineCanon -mpv $json.mpv -mpvVariant $json.mpvVariant -mpvsw $json.mpvsw
    return $true
}

function Get-MpvOfflineVersion {
    $mpv = Join-Path $script:SD 'mpv.exe'
    if (-not (Test-Path $mpv)) { return $null }
    try {
        $ver = (& $mpv '--version' 2>$null | Select-Object -First 1)
        if ($ver -match 'mpv\s+([\S]+)') {
            return $Matches[1]
        }
    } catch {}
    return '__present__'
}

function Sync-MpvExeVersionFromOffline {
    $offline = Get-MpvOfflineVersion
    if (-not $offline) { return $false }
    $json = Get-InstalledVersions
    if ($offline -eq '__present__') {
        if ($json.mpv -and $json.mpv -ne '') { return $false }
        return $false
    }
    if ($json.mpv -eq $offline) { return $false }
    # Only sync if JSON is empty (avoid overwriting a good canonical tag)
    if ($json.mpv -and $json.mpv -ne '') { return $false }
    Save-InstalledVersions -ffmpeg $json.ffmpeg -mpv $offline -mpvVariant $json.mpvVariant -mpvsw $json.mpvsw
    return $true
}

function Sync-OfflineInstalledVersions {
    $changed = $false
    if (Sync-FFmpegVersionFromOffline) { $changed = $true }
    if (Sync-MpvExeVersionFromOffline) { $changed = $true }
    if (Sync-MpvSwVersionFromOffline) { $changed = $true }
    return $changed
}

function Sync-MpvSwVersionFromOffline {
    $offline = Get-MpvSwOfflineVersion
    if (-not $offline) { return $false }
    $json = Get-InstalledVersions
    if ($json.mpvsw -eq $offline) { return $false }
    Save-InstalledVersions -ffmpeg $json.ffmpeg -mpv $json.mpv -mpvVariant $json.mpvVariant -mpvsw $offline
    return $true
}

function Get-MpvHashFragment([string]$v) {
    if (-not $v) { return $null }
    $h = $null
    if ($v -match '-g([0-9a-fA-F]{7,})') { $h = $Matches[1].ToLower() }
    elseif ($v -match '-(g?[0-9a-fA-F]{7,})[a-fA-F0-9]*$') { $h = $Matches[1].ToLower() }
    if ($h) { return ($h -replace '^g','') }
    return $null
}

function Rewrite-MpvJsonToOnlineTag([string]$onlineTag) {
    if (-not $onlineTag) { return $false }
    $json = Get-InstalledVersions
    $current = $json.mpv
    if (-not $current) { return $false }
    if ($current -eq $onlineTag) { return $false }

    $localHash = Get-MpvHashFragment $current
    $remoteHash = Get-MpvHashFragment $onlineTag
    if (-not $localHash -or -not $remoteHash) {
        Log-Warn ('[mpv] Hash missing. local=' + $current + ' | online=' + $onlineTag)
        return $false
    }
    if (-not ($localHash.StartsWith($remoteHash) -or $remoteHash.StartsWith($localHash))) {
        Log-Warn ('[mpv] Hash mismatch. local=' + $localHash + ' | online=' + $remoteHash)
        return $false
    }

    $obj = [PSCustomObject]@{
        ffmpeg = $json.ffmpeg
        mpv = $onlineTag
        mpvVariant = $(if ($json.mpvVariant) { $json.mpvVariant } else { 'x86_64' })
        mpvsw = $json.mpvsw
    }
    $sd = Join-Path $script:SD 'scripts'
    if (-not (Test-Path $sd)) { New-Item -ItemType Directory -Path $sd | Out-Null }
    $obj | ConvertTo-Json -Depth 4 | Set-Content $script:VersionFile -Encoding UTF8 -Force
    Log-OK ('[mpv] JSON canonized to online tag: ' + $onlineTag)
    return $true
}

function Rewrite-FFmpegJsonToOnlineTag([string]$onlineTag) {
    if (-not $onlineTag) { return $false }
    $json = Get-InstalledVersions
    $current = $json.ffmpeg
    if (-not $current) { return $false }
    if ($current -eq $onlineTag) { return $false }

    $localDisplay  = Get-FFmpegDisplayVersion $current
    $remoteDisplay = Get-FFmpegDisplayVersion $onlineTag

    if (-not $localDisplay -or -not $remoteDisplay) {
        Log-Warn ('[ffmpeg] Display version missing. local=' + $current + ' | online=' + $onlineTag)
        return $false
    }
    if ($localDisplay -ne $remoteDisplay) {
        Log-Warn ('[ffmpeg] Version mismatch. local=' + $localDisplay + ' | online=' + $remoteDisplay)
        return $false
    }

    $obj = [PSCustomObject]@{
        ffmpeg     = $onlineTag
        mpv        = $json.mpv
        mpvVariant = $(if ($json.mpvVariant) { $json.mpvVariant } else { '' })
        mpvsw      = $json.mpvsw
    }
    $sd = Join-Path $script:SD 'scripts'
    if (-not (Test-Path $sd)) { New-Item -ItemType Directory -Path $sd | Out-Null }
    $obj | ConvertTo-Json -Depth 4 | Set-Content $script:VersionFile -Encoding UTF8 -Force
    Log-OK ('[ffmpeg] JSON canonized to online tag: ' + $onlineTag)
    return $true
}

# ============================================================
#  DOWNLOAD / EXTRACT / LOG
# ============================================================
function Ensure-TempDir {
    if (-not (Test-Path $script:TempDir)) { New-Item -ItemType Directory -Path $script:TempDir | Out-Null }
}
function Remove-TempDir {
    if (Test-Path $script:TempDir) { Remove-Item -Recurse -Force $script:TempDir -ErrorAction SilentlyContinue }
}
function Append-Log([string]$msg,[System.Drawing.Color]$color) {
    if ($null -eq $script:LogBox) { return }
    if ($null -eq $msg) { $msg = '' }
    try {
        $safeColor = if ($null -ne $color -and -not $color.IsEmpty) { $color } else { $script:TEXT }
    } catch {
        $safeColor = $script:TEXT
    }
    if ($null -eq $safeColor) { $safeColor = [System.Drawing.Color]::White }
    try {
        $script:LogBox.SelectionStart = $script:LogBox.TextLength
        $script:LogBox.SelectionLength = 0
        $script:LogBox.SelectionColor = $safeColor
        $script:LogBox.AppendText($msg + "`n")
        $script:LogBox.SelectionColor = $script:LogBox.ForeColor
        $script:LogBox.ScrollToCaret()
    } catch {
        try { $script:LogBox.AppendText($msg + "`n") } catch {}
    }
    [System.Windows.Forms.Application]::DoEvents()
}
function Log-Info([string]$m)  { Append-Log $m $script:TEXT }
function Log-OK([string]$m)    { Append-Log $m $script:SUCCESS }
function Log-Warn([string]$m)  { Append-Log $m $script:NOTE_C }
function Log-Error([string]$m) { Append-Log $m $script:ERROR_C }
function Set-Status([string]$msg,[System.Drawing.Color]$color) {
    if ($script:GitHubRateLimited -and $msg -ne (T 'StatusRateLimitInline')) {
        $script:lStatus.Text = (T 'StatusRateLimitInline')
        $script:lStatus.ForeColor = $script:NOTE_C
    } else {
        $script:lStatus.Text = $msg
        $script:lStatus.ForeColor = $color
    }
    [System.Windows.Forms.Application]::DoEvents()
}
function Set-BlockedStatus {
    $script:GitHubRateLimited = $true
    $script:lStatus.Text = (T 'StatusRateLimitInline')
    $script:lStatus.ForeColor = $script:NOTE_C
    [System.Windows.Forms.Application]::DoEvents()
}

function Set-ApiStatus([string]$msg,[System.Drawing.Color]$color) {
    if ($script:lApiStatus -ne $null) {
        $script:lApiStatus.Text = $msg
        $script:lApiStatus.ForeColor = $color
        $script:lApiStatus.Refresh()
    }
    if ($msg) {
        $script:LastApiStatusText = $msg
        $script:lStatus.Text = $msg
        $script:lStatus.ForeColor = $color
        $script:lStatus.Refresh()
    } else {
        $script:LastApiStatusText = ''
    }
    [System.Windows.Forms.Application]::DoEvents()
}
function Open-Url([string]$url) {
    try {
        Start-Process $url | Out-Null
        return $true
    } catch {}
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $url
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        return $true
    } catch {}
    try { [System.Windows.Forms.Clipboard]::SetText($url) } catch {}
    [System.Windows.Forms.MessageBox]::Show('Could not open the browser automatically.`n`nThe URL was copied to the clipboard:`n' + $url, 'MPV-SW-Capture', 'OK', 'Warning') | Out-Null
    return $false
}

function Get-DirectFinalUrl([string]$url) {
    try {
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.Method = 'HEAD'
        $req.AllowAutoRedirect = $false
        $req.UserAgent = 'MPV-SW-Installer/1.0'
        $resp = $req.GetResponse()
        try {
            if (($resp.StatusCode.value__ -ge 300) -and ($resp.StatusCode.value__ -lt 400)) {
                return $resp.Headers['Location']
            }
        } finally {
            $resp.Close()
        }
    } catch {
        try {
            return $_.Exception.Response.Headers['Location']
        } catch {}
    }
    return $null
}

function Get-GitHubRelease([string]$url) {
    try {
        $script:GitHubRateLimited = $false
        return Invoke-RestMethod -Uri $url -Headers (Get-GitHubHeaders) -UseBasicParsing
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match 'rate limit' -or $msg -match '403') { $script:GitHubRateLimited = $true }
        return $null
    }
}

function Invoke-GitHubJson([string]$url) {
    try {
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.Method = 'GET'
        $req.UserAgent = 'MPV-SW-Installer/1.0'
        $req.Accept = 'application/vnd.github+json'
        $req.Timeout = 15000
        $req.ReadWriteTimeout = 15000
        foreach ($k in (Get-GitHubHeaders).Keys) {
            if ($k -eq 'Authorization') { $req.Headers[$k] = (Get-GitHubHeaders)[$k] }
        }
        $resp = $req.GetResponse()
        try {
            $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $json = $sr.ReadToEnd()
            $sr.Close()
            $script:GitHubRateLimited = $false
            return ($json | ConvertFrom-Json)
        } finally {
            $resp.Close()
        }
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match 'rate limit' -or $msg -match '403') { $script:GitHubRateLimited = $true }
        return $null
    }
}

function Get-FFmpegLatest {
    $mode = Get-FFmpegMode
    if ($script:CacheFFVersion -and $script:CacheFFUrl -and $script:CacheFFMode -eq $mode) {
        $a = [PSCustomObject]@{ name = [System.IO.Path]::GetFileName($script:CacheFFUrl); browser_download_url = $script:CacheFFUrl }
        return $script:CacheFFVersion, $a
    }
    if ($mode -eq 'stable') {
        $rel = Invoke-GitHubJson $FFmpegStableApiUrl
        if (-not $rel -or -not $rel.assets) { return $null, $null }
        $asset = $rel.assets | Where-Object { $_.name -match '^ffmpeg-.*essentials_build\.7z$' -and $_.name -notmatch 'git' } | Select-Object -First 1
        if ($asset) {
            $script:CacheFFVersion = $rel.tag_name
            $script:CacheFFUrl     = $asset.browser_download_url
            $script:CacheFFMode    = $mode
            return $rel.tag_name, $asset
        }
        return $null, $null
    } else {
        $releases = Invoke-GitHubJson $FFmpegApiUrl
        if (-not $releases) { return $null, $null }
        foreach ($rel in $releases) {
            if (-not $rel.assets) { continue }
            $asset = $rel.assets | Where-Object { $_.name -match '^ffmpeg-.*git-.*essentials_build\.7z$' } | Select-Object -First 1
            if ($asset) {
                $script:CacheFFVersion = $rel.tag_name
                $script:CacheFFUrl     = $asset.browser_download_url
                $script:CacheFFMode    = $mode
                return $rel.tag_name, $asset
            }
        }
        return $null, $null
    }
}

function Get-MpvLatestRelease {
    if ($script:CacheMpvRelease) { return $script:CacheMpvRelease }
    $r = Invoke-GitHubJson $MpvApiUrl
    if ($r) { $script:CacheMpvRelease = $r }
    return $r
}

function Get-MpvAssetForVariant($release,[string]$variant) {
    if (-not $release -or -not $release.assets) { return $null }
    switch ($variant) {
        'x86_64'    { return ($release.assets | Where-Object { $_.name -match '^mpv-x86_64-\d{8}-git-[A-Za-z0-9]+\.7z$' } | Select-Object -First 1) }
        'x86_64-v3' { return ($release.assets | Where-Object { $_.name -match '^mpv-x86_64-v3-\d{8}-git-[A-Za-z0-9]+\.7z$' } | Select-Object -First 1) }
        'aarch64'   { return ($release.assets | Where-Object { $_.name -match '^mpv-aarch64-\d{8}-git-[A-Za-z0-9]+\.7z$' } | Select-Object -First 1) }
        default     { return ($release.assets | Where-Object { $_.name -match '^mpv-x86_64-\d{8}-git-[A-Za-z0-9]+\.7z$' } | Select-Object -First 1) }
    }
}

function Get-MpvVersionForVariant([string]$variant) {
    $r = Get-MpvLatestRelease
    if (-not $r) { return $null, $null }
    $asset = Get-MpvAssetForVariant $r $variant
    if (-not $asset) { return $r.tag_name, $null }

    $variantVer = $r.tag_name
    if ($asset.name -match '^(mpv-[^-]+(?:-[^-]+)?)-(\d{8})-git-([A-Za-z0-9]+)\.7z$') {
        $variantVer = ($Matches[2] + '-git-' + $Matches[3])
    }
    return $variantVer, $asset
}

function Update-MpvAvailableForSelection {
    $variant = Get-SelectedMpvVariant
    $ver, $asset = Get-MpvVersionForVariant $variant
    if ($ver) {
        $script:CheckedMpvAvailable = $ver
        if ($script:lMpv_Avail) {
            $script:lMpv_Avail.Text = (T 'S2Available') + '  ' + $ver
            $script:lMpv_Avail.ForeColor = $script:SUCCESS
        }
    } else {
        $script:CheckedMpvAvailable = $null
        if ($script:lMpv_Avail) {
            $script:lMpv_Avail.Text = (T 'S2Available') + '  ?'
            $script:lMpv_Avail.ForeColor = $script:ERROR_C
        }
    }
    if ($script:lMpv_Result) {
        $iv = (Get-InstalledVersions).mpv
        $script:lMpv_Result.Text = $(if ($script:CheckedMpvAvailable) { (Get-ResultIcon $iv $script:CheckedMpvAvailable) } else { '-' }) + ' ' + (T 'S2Result') + '  ' + $(if ($script:CheckedMpvAvailable) { (Get-ResultMessage $iv $script:CheckedMpvAvailable) } else { (T 'ResUnknown') })
    }
    Refresh-SummaryCard
}

function Get-MyLatestRelease {
    if ($script:CacheMyRelease) { return $script:CacheMyRelease }
    $r = Invoke-GitHubJson $MyRepoApiUrl
    if ($r) { $script:CacheMyRelease = $r }
    return $r
}

function Clear-RemoteCache {
    $script:CacheFFVersion = $null
    $script:CacheFFUrl = $null
    $script:CacheFFMode = $null
    $script:CacheMpvRelease = $null
    $script:CacheMyRelease = $null
}

function Get-SelectedMpvVariant {
    if ($script:rbV2 -and $script:rbV2.Checked) { return 'x86_64-v3' }
    if ($script:rbV3 -and $script:rbV3.Checked) { return 'aarch64' }
    return 'x86_64'
}

# ============================================================
#  EXTRACTION FUNCTIONS (using tar.exe)
# ============================================================
function Expand-Archive7z {
    param([string]$archive, [string]$dest)
    try {
        if (-not (Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
        # Usar tar.exe (nativo de Windows 10/11) para extraer .7z
        $tarExe = if (Test-Path "$env:SystemRoot\System32\tar.exe") { "$env:SystemRoot\System32\tar.exe" } else { "tar.exe" }
        $p = Start-Process -FilePath $tarExe -ArgumentList @("-xf", "`"$archive`"", "-C", "`"$dest`"") -Wait -PassThru -WindowStyle Minimized
        if ($p.ExitCode -eq 0) {
            return $true
        } else {
            Log-Error ("[tar] Extraction failed with code " + $p.ExitCode)
            return $false
        }
    } catch {
        Log-Error ("[tar] Extraction error: " + $_.Exception.Message)
        return $false
    }
}

function Expand-ArchiveZip {
    param([string]$archive, [string]$dest)
    try {
        if (-not (Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
        Expand-Archive -Path $archive -DestinationPath $dest -Force -ErrorAction Stop
        return $true
    } catch {
        Log-Error ("[zip] Extraction error: " + $_.Exception.Message)
        return $false
    }
}

function Download-File([string]$url,[string]$out,[string]$logKey) {
    Log-Info ([string]::Format((T $logKey),[System.IO.Path]::GetFileName($out)))
    try {
        $ProgressPreference='SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
        $ProgressPreference='Continue'; return $true
    } catch { Log-Error $_.Exception.Message; return $false }
}

# ============================================================
#  INSTALLATION FUNCTIONS (using tar.exe)
# ============================================================
function Do-InstallFFmpeg([bool]$force) {
    Log-Info (T 'LogCheckingFF')
    $installed=(Get-InstalledVersions).ffmpeg
    $remoteVer,$asset=Get-FFmpegLatest
    if (-not $asset -or -not $remoteVer) {
        if ($script:GitHubRateLimited) { Log-Warn (T 'LogRateLimit') }
        Log-Error (T 'LogFFNotFound')
        return $false
    }
    $state = Get-VersionState $installed $remoteVer
    if (-not $force -and $installed -and ($state -eq 'latest' -or $state -eq 'newer')) {
        Log-OK ([string]::Format((T 'LogFFUpToDate'),$installed))
        $script:CheckedFFAvailable=$remoteVer
        Refresh-VersionLabels
        return $true
    }
    Ensure-TempDir
    $archPath=Join-Path $script:TempDir $asset.name
    $extPath=Join-Path $script:TempDir 'ffmpeg_extracted'
    if (Test-Path $extPath) { Remove-Item -Recurse -Force $extPath -ErrorAction SilentlyContinue }
    if (-not (Download-File $asset.browser_download_url $archPath 'LogFFDownload')) { return $false }
    Log-Info (T 'LogFFExtracting')
    if (Expand-Archive7z $archPath $extPath) {
        $fe=Get-ChildItem -Path $extPath -Recurse -Filter 'ffmpeg.exe' | Select-Object -First 1
        $fp=Get-ChildItem -Path $extPath -Recurse -Filter 'ffplay.exe' | Select-Object -First 1
        if ($fe -and $fp) {
            Copy-Item $fe.FullName -Destination (Join-Path $script:SD 'ffmpeg.exe') -Force
            Copy-Item $fp.FullName -Destination (Join-Path $script:SD 'ffplay.exe') -Force
            Save-InstalledVersions -ffmpeg $remoteVer
            $script:CheckedFFAvailable=$remoteVer
            Log-OK ([string]::Format((T 'LogFFDone'),$remoteVer))
            Refresh-VersionLabels
            return $true
        }
        Log-Error (T 'LogFFNotFound')
        return $false
    }
    Log-Error ([string]::Format((T 'LogFFError'),'Extraction failed'))
    return $false
}

function Do-InstallMPV([string]$variant,[bool]$force) {
    Log-Info (T 'LogCheckingMpv')
    $installed=(Get-InstalledVersions).mpv
    $r=Get-MpvLatestRelease
    if (-not $r) {
        if ($script:GitHubRateLimited) { Log-Warn (T 'LogRateLimit') }
        Log-Error ([string]::Format((T 'LogApiError'),'mpv','latest release unavailable'))
        return $false
    }
    $remoteVer, $asset = Get-MpvVersionForVariant $variant
    if (-not $asset) {
        Log-Error ([string]::Format((T 'LogMpvNotFound'),$variant))
        return $false
    }
    $state = Get-VersionState $installed $remoteVer
    if (-not $force -and $installed -and ($state -eq 'latest' -or $state -eq 'newer')) {
        Log-OK ([string]::Format((T 'LogMpvUpToDate'),$installed))
        $script:CheckedMpvAvailable=$remoteVer
        Refresh-VersionLabels
        return $true
    }
    Ensure-TempDir
    $archPath=Join-Path $script:TempDir $asset.name
    $extPath=Join-Path $script:TempDir 'mpv_extracted'
    if (Test-Path $extPath) { Remove-Item -Recurse -Force $extPath -ErrorAction SilentlyContinue }
    if (-not (Download-File $asset.browser_download_url $archPath 'LogMpvDownload')) { return $false }
    Log-Info (T 'LogMpvExtracting')
    if (Expand-Archive7z $archPath $extPath) {
        $exe=Get-ChildItem -Path $extPath -Recurse -File | Where-Object { $_.Name -ieq 'mpv.exe' } | Select-Object -First 1
        if (-not $exe) {
            $candidateDir = Get-ChildItem -Path $extPath -Recurse -Directory | Where-Object { $_.Name -match '^mpv($|[\-_])' } | Select-Object -First 1
            if ($candidateDir) {
                $directExe = Join-Path $candidateDir.FullName 'mpv.exe'
                if (Test-Path $directExe) { $exe = Get-Item $directExe }
            }
        }
        if (-not $exe) {
            Log-Error ([string]::Format((T 'LogMpvError'),'mpv.exe not found'))
            return $false
        }
        Copy-Item $exe.FullName -Destination (Join-Path $script:SD 'mpv.exe') -Force
        Save-InstalledVersions -mpv $remoteVer -mpvVariant $variant
        $script:CheckedMpvAvailable=$remoteVer
        Log-OK ([string]::Format((T 'LogMpvDone'),$remoteVer,$variant))
        Refresh-VersionLabels
        return $true
    }
    Log-Error ([string]::Format((T 'LogMpvError'),'Extraction failed'))
    return $false
}

function Do-InstallMySW([bool]$force) {
    Log-Info (T 'LogCheckingMySW')
    [void](Sync-MpvSwVersionFromOffline)
    $installed=(Get-InstalledVersions).mpvsw
    $r=Get-MyLatestRelease
    if (-not $r) {
        if ($script:GitHubRateLimited) { Log-Warn (T 'LogRateLimit') }
        Log-Error ([string]::Format((T 'LogApiError'),'MPV-SW-Capture','latest release unavailable'))
        return $false
    }
    $remoteVer=$r.tag_name
    $state = Get-VersionState $installed $remoteVer
    if (-not $force -and $installed -and ($state -eq 'latest' -or $state -eq 'newer')) {
        Log-OK ([string]::Format((T 'LogMySWUpToDate'),$installed))
        $script:CheckedMyAvailable=$remoteVer
        Refresh-VersionLabels
        return $true
    }
    $asset = $r.assets | Where-Object { $_.name -match '\.zip$' } | Select-Object -First 1
    if (-not $asset) {
        Log-Error (T 'LogMySWNotFound')
        return $false
    }
    Ensure-TempDir
    $zipPath=Join-Path $script:TempDir $asset.name
    $extPath=Join-Path $script:TempDir 'mpvsw_extracted'
    if (Test-Path $extPath) { Remove-Item -Recurse -Force $extPath -ErrorAction SilentlyContinue }
    if (-not (Download-File $asset.browser_download_url $zipPath 'LogMySWDownload')) { return $false }
    Log-Info (T 'LogMySWExtracting')
    if (Expand-ArchiveZip $zipPath $extPath) {
        $files = Get-ChildItem -Path $extPath -Recurse -File
        if (-not $files -or $files.Count -eq 0) {
            Log-Error ([string]::Format((T 'LogMySWError'),'ZIP extracted no files'))
            return $false
        }
        try {
            foreach ($f in $files) {
                $rel = $f.FullName.Substring($extPath.Length).TrimStart('\','/')
                if ([string]::IsNullOrWhiteSpace($rel)) { continue }
                $dest = Join-Path $script:SD $rel
                $destDir = Split-Path -Parent $dest
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                Copy-Item -Path $f.FullName -Destination $dest -Force -ErrorAction Stop
            }
        } catch {
            Log-Error ([string]::Format((T 'LogMySWError'),$_.Exception.Message))
            return $false
        }
        Save-InstalledVersions -mpvsw $remoteVer
        $script:CheckedMyAvailable=$remoteVer
        Log-OK ([string]::Format((T 'LogMySWDone'),$remoteVer))
        Refresh-VersionLabels
        return $true
    }
    Log-Error ([string]::Format((T 'LogMySWError'),'Extraction failed'))
    return $false
}

# ============================================================
#  VERSION STATUS HELPERS
# ============================================================
function Normalize-VersionForCompare([string]$v) {
    if (-not $v) { return -1 }
    if ($v -match '^v?(\d+)\.(\d+)\.(\d+)$') {
        return [int]$Matches[1] * 1000000 + [int]$Matches[2] * 1000 + [int]$Matches[3]
    }
    if ($v -match '^(\d{4})-(\d{2})-(\d{2})') {
        return [int](($Matches[1] + $Matches[2] + $Matches[3]) -join '')
    }
    if ($v -match '^(\d{8})') {
        return [int]$Matches[1]
    }
    return -1
}

function Get-VersionState([string]$installed,[string]$available) {
    if (-not $installed) { return 'missing' }
    $i = Normalize-VersionForCompare $installed
    $a = Normalize-VersionForCompare $available
    if ($i -lt 0 -or $a -lt 0) {
        if ($installed -eq $available) { return 'latest' }
        return 'outdated'
    }
    if ($i -eq $a) { return 'latest' }
    if ($i -lt $a) { return 'outdated' }
    return 'newer'
}

function Get-ResultMessage([string]$installed,[string]$available) {
    switch (Get-VersionState $installed $available) {
        'latest'   { return T 'ResLatest' }
        'outdated' { return T 'ResUpdate' }
        'newer'    { return T 'ResNewer' }
        default    { return T 'ResMissing' }
    }
}

function Get-ResultColor([string]$installed,[string]$available) {
    switch (Get-VersionState $installed $available) {
        'latest'   { return $script:SUCCESS }
        'outdated' { return $script:NOTE_C }
        'newer'    { return $script:ACCENT3 }
        default    { return $script:ERROR_C }
    }
}

function Get-ResultIcon([string]$installed,[string]$available) {
    switch (Get-VersionState $installed $available) {
        'latest'   { return T 'IconLatest' }
        'outdated' { return T 'IconUpdate' }
        'newer'    { return T 'IconNewer' }
        default    { return T 'IconMissing' }
    }
}

function Get-FFmpegDisplayVersion([string]$v) {
    if (-not $v) { return $v }
    if ($v -match '^([0-9]+(\.[0-9]+){1,3})') {
        return $Matches[1]
    }
    return $v
}

function Refresh-SummaryCard {
    $v = Get-InstalledVersions
    if ($null -eq $script:lS4Body) { return }
    $script:lS4Body.Clear()
    $myOff = Get-MpvSwOfflineVersion

    $items = @(
        @{
            Name  = "ffmpeg"
            Ver   = if ($v.ffmpeg) { $v.ffmpeg } else { "---" }
            Show  = if ($v.ffmpeg) { Get-FFmpegDisplayVersion $v.ffmpeg } else { "---" }
            Avail = $script:CheckedFFAvailable
        },
        @{
            Name  = "mpv"
            Ver   = if ($v.mpv) { $v.mpv } else { "---" }
            Show  = if ($v.mpv) { "$($v.mpv) [$($v.mpvVariant)]" } else { "---" }
            Avail = $script:CheckedMpvAvailable
        },
        @{
            Name  = "MPV-SW"
            Ver   = if ($myOff) { $myOff } elseif ($v.mpvsw) { $v.mpvsw } else { "---" }
            Show  = if ($myOff) { $myOff } elseif ($v.mpvsw) { $v.mpvsw } else { "---" }
            Avail = $script:CheckedMyAvailable
        }
    )

    foreach ($it in $items) {
        if (-not $it.Avail) {
            $icon = "-"
            $lineColor = $script:MUTED
            $msg = T "SumUnknown"
        }
        else {
            $state = Get-VersionState $it.Ver $it.Avail
            switch ($state) {
                "latest"   { $icon = T "IconLatest";  $lineColor = $script:SUCCESS; $msg = T "SumLatest" }
                "outdated" { $icon = T "IconUpdate";  $lineColor = $script:NOTEC;   $msg = T "SumOutdated" }
                "newer"    { $icon = T "IconNewer";   $lineColor = $script:ACCENT3; $msg = T "SumNewer" }
                default     { $icon = T "IconMissing"; $lineColor = $script:ERRORC;  $msg = T "SumMissing" }
            }
        }

        try {
            $safeLineColor = if ($null -ne $lineColor -and -not $lineColor.IsEmpty) { $lineColor } else { $script:MUTED }
        } catch {
            $safeLineColor = $script:MUTED
        }
        if ($null -eq $safeLineColor) { $safeLineColor = [System.Drawing.Color]::White }
        try {
            $safeMuted = if ($null -ne $script:MUTED -and -not $script:MUTED.IsEmpty) { $script:MUTED } else { [System.Drawing.Color]::Silver }
        } catch {
            $safeMuted = [System.Drawing.Color]::Silver
        }

        try {
            $script:lS4Body.SelectionColor = $safeLineColor
            $script:lS4Body.AppendText(("{0} {1,-10} {2}`n" -f $icon, $it.Name, $it.Show))
            $script:lS4Body.SelectionColor = $safeMuted
            $script:lS4Body.AppendText(("   {0}`n" -f $msg))
        } catch {
            try {
                $script:lS4Body.AppendText(("{0} {1,-10} {2}`n   {3}`n" -f $icon, $it.Name, $it.Show, $msg))
            } catch {}
        }
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Refresh-VersionLabels {
    [void](Sync-OfflineInstalledVersions)
    $v=Get-InstalledVersions; $none=T "S1None"
    $myOff = Get-MpvSwOfflineVersion

    $ffRaw      = if ($v.ffmpeg) { Get-FFmpegDisplayVersion $v.ffmpeg } else { $none }
    $ffInstTxt  = if ($ffRaw.Length -gt 36) { $ffRaw.Substring(0,34) + '..' } else { $ffRaw }
    $mpvRaw     = if ($v.mpv) { $v.mpv } else { $none }
    $mpvInstTxt = if ($mpvRaw.Length -gt 36) { $mpvRaw.Substring(0,34) + '..' } else { $mpvRaw }
    $myRaw      = if ($myOff) { $myOff } elseif ($v.mpvsw) { $v.mpvsw } else { $none }
    $myInstTxt  = if ($myRaw.Length -gt 36) { $myRaw.Substring(0,34) + '..' } else { $myRaw }

    $script:lFF_Inst.Text   = (T "S1Installed") + "  " + $ffInstTxt
    $script:lMpv_Inst.Text  = (T "S2Installed") + "  " + $mpvInstTxt
    $script:lMySW_Inst.Text = (T "S3Installed") + "  " + $myInstTxt

    $script:lFF_Avail.Text   = (T "S1Available") + "  " + $(if ($script:CheckedFFAvailable) { $script:CheckedFFAvailable } else { '?' })
    $script:lMpv_Avail.Text  = (T "S2Available") + "  " + $(if ($script:CheckedMpvAvailable) { $script:CheckedMpvAvailable } else { '?' })
    $script:lMySW_Avail.Text = (T "S3Available") + "  " + $(if ($script:CheckedMyAvailable) { $script:CheckedMyAvailable } else { '?' })

    $script:lFF_Result.Text   = $(if ($script:CheckedFFAvailable) { (Get-ResultIcon $v.ffmpeg $script:CheckedFFAvailable) } else { '-' }) + ' ' + (T "S1Result") + '  ' + $(if ($script:CheckedFFAvailable) { (Get-ResultMessage $v.ffmpeg $script:CheckedFFAvailable) } else { (T 'ResUnknown') })
    $script:lMpv_Result.Text  = $(if ($script:CheckedMpvAvailable) { (Get-ResultIcon $v.mpv $script:CheckedMpvAvailable) } else { '-' }) + ' ' + (T "S2Result") + '  ' + $(if ($script:CheckedMpvAvailable) { (Get-ResultMessage $v.mpv $script:CheckedMpvAvailable) } else { (T 'ResUnknown') })
    $script:lMySW_Result.Text = $(if ($script:CheckedMyAvailable) { (Get-ResultIcon $v.mpvsw $script:CheckedMyAvailable) } else { '-' }) + ' ' + (T "S3Result") + '  ' + $(if ($script:CheckedMyAvailable) { (Get-ResultMessage $v.mpvsw $script:CheckedMyAvailable) } else { (T 'ResUnknown') })

    $script:lFF_Result.ForeColor   = $script:TEXT
    $script:lMpv_Result.ForeColor  = $script:TEXT
    $script:lMySW_Result.ForeColor = $script:TEXT

    $ffState = Get-VersionState $v.ffmpeg $script:CheckedFFAvailable
    if ($script:btnFF_I) { $script:btnFF_I.Enabled = (-not ($ffState -eq 'latest' -or $ffState -eq 'newer')) }

    $mpvState = Get-VersionState $v.mpv $script:CheckedMpvAvailable
    if ($script:btnMpv_I) { $script:btnMpv_I.Enabled = (-not ($mpvState -eq 'latest' -or $mpvState -eq 'newer')) }

    $myState = Get-VersionState $v.mpvsw $script:CheckedMyAvailable
    if ($script:btnMySW_I) { $script:btnMySW_I.Enabled = (-not ($myState -eq 'latest' -or $myState -eq 'newer')) }

    Refresh-SummaryCard
}

function Refresh-InstalledNow {
    [void](Sync-OfflineInstalledVersions)
    Refresh-VersionLabels
    if ($form) { $form.Refresh() }
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-WithLock([scriptblock]$action) {
    foreach ($b in @($script:btnCheckAll,$script:btnUpdateAll,$script:btnForce,
                     $script:btnFF_I,$script:btnMpv_I,$script:btnMySW_I)) { $b.Enabled=$false }
    try { & $action } finally {
        Remove-TempDir
        foreach ($b in @($script:btnCheckAll,$script:btnUpdateAll,$script:btnForce,
                         $script:btnFF_I,$script:btnMpv_I,$script:btnMySW_I)) { $b.Enabled=$true }
    }
}

# ============================================================
#  FORM  (same dimensions as Setup: 1140 x 550)
# ============================================================
$formW=1140; $formH=550; $headerH=68
$leftX=20; $cardW=550; $colGap=16; $rightX=$leftX+$cardW+$colGap
$row1Y=10; $row2Y=190; $row3Y=385
$cTopH=170; $cMidH=185; $cBotH=85

# ============================================================
#  FORM CREATION (using the correct Get-AppIcon)
# ============================================================
$form=New-Object System.Windows.Forms.Form
try { $appIcon = Get-AppIcon; if($appIcon){ $form.Icon = $appIcon } } catch {}
$form.ShowInTaskbar = $true
$form.Text = T 'Title'
$form.ClientSize=[System.Drawing.Size]::new($formW,$formH)
$form.MinimumSize=$form.Size
$form.BackColor=$script:BG; $form.ForeColor=$script:TEXT
$form.FormBorderStyle='FixedSingle'; $form.MaximizeBox=$false
$form.StartPosition='CenterScreen'; $form.Font=$FontSub

# --- Header ---
$pHeader=New-Pnl 0 0 $formW $headerH $script:SURFACE
$lAppTitle  =New-Lbl "MPV-SW-Capture" 20 2 420 36 $FontTitle $script:ACCENT
$lAppSub    =New-Lbl (T "HeaderSub")  22 36 520 18 $FontSub $script:MUTED
$lHeaderNote=New-Lbl (T "HeaderNote") 560 38 560 18 $FontSmall $script:ACCENT3
$lLangLbl   =New-Lbl (T "LangLabel")  930 10 90 18 $FontSmall $script:MUTED
$btnEN=New-Object System.Windows.Forms.Button
$btnEN.Text="EN"; $btnEN.Location=[System.Drawing.Point]::new(1038,6)
$btnEN.Size=[System.Drawing.Size]::new(44,26); Style-LangBtn $btnEN $true
$btnES=New-Object System.Windows.Forms.Button
$btnES.Text="ES"; $btnES.Location=[System.Drawing.Point]::new(1086,6)
$btnES.Size=[System.Drawing.Size]::new(44,26); Style-LangBtn $btnES $false
$pHeader.Controls.AddRange(@($lAppTitle,$lAppSub,$lLangLbl,$btnEN,$btnES,$lHeaderNote))
$form.Controls.Add($pHeader)

$pMain=New-Pnl 0 $headerH $formW ($formH-$headerH) $script:BG
$form.Controls.Add($pMain)

# ============================================================
#  CARD 1  ffmpeg + ffplay  (top-left)
# ============================================================
$card1=New-CardXY $pMain $leftX $row1Y $cardW $cTopH "S1Title"; $card1.Tag="S1"
$lFF_Desc=New-Lbl (T "S1Desc") 14 30 ($cardW-148) 16 $FontSmall $script:MUTED
$card1.Controls.Add($lFF_Desc)
$lFF_Inst=New-Lbl "" 14 52 ($cardW-204) 18 $FontBold $script:NOTE_C; $card1.Controls.Add($lFF_Inst)
$script:lFF_Inst=$lFF_Inst
$lFF_Avail=New-Lbl "" 14 72 340 18 $FontSmall $script:MUTED; $card1.Controls.Add($lFF_Avail)
$script:lFF_Avail=$lFF_Avail
$lFF_Result=New-Lbl "" 14 150 515 26 $FontBold $script:TEXT; $card1.Controls.Add($lFF_Result)
$script:lFF_Result=$lFF_Result

$btnFF_C=New-Object System.Windows.Forms.Button
$btnFF_C.Text=T "S1BtnCheck"; $btnFF_C.Location=[System.Drawing.Point]::new(438,30)
$btnFF_C.Size=[System.Drawing.Size]::new(94,28)
Style-Btn $btnFF_C $script:SURFACE $script:ACCENT
$btnFF_C.FlatAppearance.BorderSize=1; $btnFF_C.FlatAppearance.BorderColor=$script:ACCENT
$card1.Controls.Add($btnFF_C)

$btnFF_I=New-Object System.Windows.Forms.Button
$btnFF_I.Text=T "S1BtnInstall"; $btnFF_I.Location=[System.Drawing.Point]::new(360,60)
$btnFF_I.Size=[System.Drawing.Size]::new(172,32); Style-Btn $btnFF_I $script:ACCENT $script:BG
$card1.Controls.Add($btnFF_I); $script:btnFF_I=$btnFF_I

$btnFF_M=New-Object System.Windows.Forms.Button
$btnFF_M.Text=T "S1BtnManual"; $btnFF_M.Location=[System.Drawing.Point]::new(438,95)
$btnFF_M.Size=[System.Drawing.Size]::new(94,28)
Style-ManualBtn $btnFF_M
Set-ManualButtonVisibleText $btnFF_M "MANUAL"
$card1.Controls.Add($btnFF_M); $script:btnFF_M=$btnFF_M

$lFFMode=New-Lbl "Version:" 14 126 70 16 $FontBold $script:MUTED
$card1.Controls.Add($lFFMode); $script:lFFMode=$lFFMode
$rbFFStable=New-RB "Stable" 90 126 110
$rbFFDaily=New-RB "Daily" 200 126 110
$rbFFStable.ForeColor=$script:TEXT; $rbFFDaily.ForeColor=$script:TEXT
$rbFFStable.Font=$FontBold; $rbFFDaily.Font=$FontBold
$rbFFStable.Checked=$true
$card1.Controls.AddRange(@($rbFFStable,$rbFFDaily))
$script:rbFFStable=$rbFFStable; $script:rbFFDaily=$rbFFDaily

# ============================================================
#  CARD 2  mpv  (top-right)
# ============================================================
$card2=New-CardXY $pMain $rightX $row1Y $cardW $cTopH "S2Title"; $card2.Tag="S2"
$lMpv_Desc=New-Lbl (T "S2Desc") 14 30 ($cardW-148) 16 $FontSmall $script:MUTED
$card2.Controls.Add($lMpv_Desc)
$lMpv_Inst=New-Lbl "" 14 52 ($cardW-204) 18 $FontBold $script:NOTE_C; $card2.Controls.Add($lMpv_Inst)
$script:lMpv_Inst=$lMpv_Inst
$lMpv_Avail=New-Lbl "" 14 72 340 18 $FontSmall $script:MUTED; $card2.Controls.Add($lMpv_Avail)
$script:lMpv_Avail=$lMpv_Avail
$lMpv_Result=New-Lbl "" 14 150 515 26 $FontBold $script:TEXT; $card2.Controls.Add($lMpv_Result)
$script:lMpv_Result=$lMpv_Result

$btnMpv_C=New-Object System.Windows.Forms.Button
$btnMpv_C.Text=T "S2BtnCheck"; $btnMpv_C.Location=[System.Drawing.Point]::new(438,30)
$btnMpv_C.Size=[System.Drawing.Size]::new(94,28)
Style-Btn $btnMpv_C $script:SURFACE $script:ACCENT
$btnMpv_C.FlatAppearance.BorderSize=1; $btnMpv_C.FlatAppearance.BorderColor=$script:ACCENT
$card2.Controls.Add($btnMpv_C)

$btnMpv_I=New-Object System.Windows.Forms.Button
$btnMpv_I.Text=T "S2BtnInstall"; $btnMpv_I.Location=[System.Drawing.Point]::new(360,60)
$btnMpv_I.Size=[System.Drawing.Size]::new(172,32); Style-Btn $btnMpv_I $script:ACCENT $script:BG
$card2.Controls.Add($btnMpv_I); $script:btnMpv_I=$btnMpv_I

$btnMpv_M=New-Object System.Windows.Forms.Button
$btnMpv_M.Text=T "S2BtnManual"; $btnMpv_M.Location=[System.Drawing.Point]::new(438,95)
$btnMpv_M.Size=[System.Drawing.Size]::new(94,28)
Style-ManualBtn $btnMpv_M
Set-ManualButtonVisibleText $btnMpv_M "MANUAL"
$card2.Controls.Add($btnMpv_M); $script:btnMpv_M=$btnMpv_M

$lVarLbl=New-Lbl (T "S2VariantLbl") 14 90 80 16 $FontBold $script:MUTED
$card2.Controls.Add($lVarLbl)
$rbV1=New-RB (T "S2V1") 14 105 190
$rbV2=New-RB (T "S2V2") 190 124 360
$rbV3=New-RB (T "S2V3") 14 124 150
$rbV1.Checked=$true
$_sv=(Get-InstalledVersions).mpvVariant
if ($_sv -eq "x86_64-v3") { $rbV1.Checked=$false; $rbV2.Checked=$true }
elseif ($_sv -eq "aarch64") { $rbV1.Checked=$false; $rbV3.Checked=$true }
$card2.Controls.AddRange(@($rbV1,$rbV2,$rbV3))
$script:rbV1=$rbV1; $script:rbV2=$rbV2; $script:rbV3=$rbV3

# ============================================================
#  CARD 3  MPV-SW-Capture  (mid-left) + Log box
# ============================================================
$card3=New-CardXY $pMain $leftX $row2Y $cardW $cMidH "S3Title"; $card3.Tag="S3"
$lMySW_Desc=New-Lbl (T "S3Desc") 14 30 ($cardW-148) 16 $FontSmall $script:MUTED
$card3.Controls.Add($lMySW_Desc)
$lMySW_Inst=New-Lbl "" 14 52 ($cardW-204) 18 $FontBold $script:NOTE_C; $card3.Controls.Add($lMySW_Inst)
$script:lMySW_Inst=$lMySW_Inst
$lMySW_Avail=New-Lbl "" 14 72 340 18 $FontSmall $script:MUTED; $card3.Controls.Add($lMySW_Avail)
$script:lMySW_Avail=$lMySW_Avail
$lMySW_Result=New-Lbl "" 14 168 515 26 $FontBold $script:TEXT; $card3.Controls.Add($lMySW_Result)
$script:lMySW_Result=$lMySW_Result

$btnMySW_C=New-Object System.Windows.Forms.Button
$btnMySW_C.Text=T "S3BtnCheck"; $btnMySW_C.Location=[System.Drawing.Point]::new(438,30)
$btnMySW_C.Size=[System.Drawing.Size]::new(94,28)
Style-Btn $btnMySW_C $script:SURFACE $script:ACCENT
$btnMySW_C.FlatAppearance.BorderSize=1; $btnMySW_C.FlatAppearance.BorderColor=$script:ACCENT
$card3.Controls.Add($btnMySW_C)

$btnMySW_I=New-Object System.Windows.Forms.Button
$btnMySW_I.Text=T "S3BtnInstall"; $btnMySW_I.Location=[System.Drawing.Point]::new(360,60)
$btnMySW_I.Size=[System.Drawing.Size]::new(172,32); Style-Btn $btnMySW_I $script:ACCENT $script:BG
$card3.Controls.Add($btnMySW_I); $script:btnMySW_I=$btnMySW_I

$btnMySW_M=New-Object System.Windows.Forms.Button
$btnMySW_M.Text=T "S3BtnManual"; $btnMySW_M.Location=[System.Drawing.Point]::new(438,95)
$btnMySW_M.Size=[System.Drawing.Size]::new(94,28)
Style-ManualBtn $btnMySW_M
Set-ManualButtonVisibleText $btnMySW_M "MANUAL"
$card3.Controls.Add($btnMySW_M); $script:btnMySW_M=$btnMySW_M

$lLogLbl=New-Lbl "LOG" 14 110 40 14 $FontBold $script:MUTED; $card3.Controls.Add($lLogLbl)
$logBox=New-Object System.Windows.Forms.RichTextBox
$logBox.Location=[System.Drawing.Point]::new(14,128)
$logBox.Size=[System.Drawing.Size]::new($cardW-28,40)
$logBox.BackColor=[System.Drawing.Color]::FromArgb(22,20,15)
$logBox.ForeColor=$script:TEXT; $logBox.Font=$FontMono
$logBox.BorderStyle='None'; $logBox.ReadOnly=$true; $logBox.ScrollBars='Vertical'
$card3.Controls.Add($logBox); $script:LogBox=$logBox

# ============================================================
#  CARD 4  Installed versions  (mid-right)
# ============================================================
$card4=New-CardXY $pMain $rightX $row2Y $cardW $cMidH "S4Title"; $card4.Tag="S4"
$lS4Lbl=New-Lbl (T "S4Label") 14 30 ($cardW-28) 16 $FontSmall $script:MUTED
$card4.Controls.Add($lS4Lbl)
$lS4Body=New-Object System.Windows.Forms.RichTextBox
$lS4Body.Location=[System.Drawing.Point]::new(14,52)
$lS4Body.Size=[System.Drawing.Size]::new($cardW-28,100)
$lS4Body.Font=$FontMono; $lS4Body.ForeColor=$script:ACCENT
$lS4Body.BackColor=[System.Drawing.Color]::FromArgb(38,35,26); $lS4Body.BorderStyle='None'; $lS4Body.ReadOnly=$true; $lS4Body.ScrollBars='None'; $lS4Body.AutoSize=$false
$card4.Controls.Add($lS4Body); $script:lS4Body=$lS4Body

# ============================================================
#  CARD 5  Actions  (bottom-left)
# ============================================================
$card5=New-CardXY $pMain $leftX $row3Y $cardW $cBotH "ActionsTitle"; $card5.Tag="ACT"

$btnCheckAll=New-Object System.Windows.Forms.Button
$btnCheckAll.Text=T "ActCheckAll"; $btnCheckAll.Location=[System.Drawing.Point]::new(14,34)
$btnCheckAll.Size=[System.Drawing.Size]::new(148,32)
Style-Btn $btnCheckAll $script:SURFACE $script:ACCENT
$btnCheckAll.FlatAppearance.BorderSize=1; $btnCheckAll.FlatAppearance.BorderColor=$script:ACCENT
$card5.Controls.Add($btnCheckAll); $script:btnCheckAll=$btnCheckAll

$btnUpdateAll=New-Object System.Windows.Forms.Button
$btnUpdateAll.Text=T "ActUpdateAll"; $btnUpdateAll.Location=[System.Drawing.Point]::new(172,34)
$btnUpdateAll.Size=[System.Drawing.Size]::new(190,32); Style-Btn $btnUpdateAll $script:ACCENT2 $script:BG
$card5.Controls.Add($btnUpdateAll); $script:btnUpdateAll=$btnUpdateAll

$btnForce=New-Object System.Windows.Forms.Button
$btnForce.Text=T "ActForce"; $btnForce.Location=[System.Drawing.Point]::new(372,34)
$btnForce.Size=[System.Drawing.Size]::new(162,32)
Style-Btn $btnForce $script:SURFACE $script:ERROR_C
$btnForce.FlatAppearance.BorderSize=1; $btnForce.FlatAppearance.BorderColor=$script:ERROR_C
$card5.Controls.Add($btnForce); $script:btnForce=$btnForce

# ============================================================
#  CARD 6  Status  (bottom-right)
# ============================================================
$card6=New-CardXY $pMain $rightX $row3Y $cardW $cBotH "ActionsTitle"; $card6.Tag="ACT6"
$lStatusLbl=New-Lbl (T "StatusLbl") 14 28 60 14 $FontSmall $script:MUTED; $card6.Controls.Add($lStatusLbl); $script:lStatusLbl=$lStatusLbl
$lStatus=New-Object System.Windows.Forms.Label
$lStatus.Location=[System.Drawing.Point]::new(14,45)
$lStatus.Size=[System.Drawing.Size]::new($cardW-28,36)
$lStatus.Font=$FontSub; $lStatus.ForeColor=$script:MUTED
$lStatus.BackColor=[System.Drawing.Color]::Transparent
$lStatus.Text=T "StatusReady"; $lStatus.AutoSize=$false
$card6.Controls.Add($lStatus); $script:lStatus=$lStatus

# ============================================================
#  BUTTON EVENTS
# ============================================================
$btnFF_C.Add_Click({
        if ($script:GitHubRateLimited) {
            $script:lStatus.Text = (T 'StatusRateLimitInline')
            $script:lStatus.ForeColor = $script:NOTE_C
            Log-Warn (T 'LogRateLimit')
            [System.Windows.Forms.Application]::DoEvents()
            return
        }

    $script:lFF_Avail.Text=T "S1Checking"; [System.Windows.Forms.Application]::DoEvents()
    $ver,$a=Get-FFmpegLatest
    if ($a -and $ver) {
        $script:CheckedFFAvailable=$ver
        $script:lFF_Avail.Text=(T "S1Available")+"  "+$ver; $script:lFF_Avail.ForeColor=$script:SUCCESS
        $didCanon = Rewrite-FFmpegJsonToOnlineTag $ver
        $iv=(Get-InstalledVersions).ffmpeg
        $ivDisplay = Get-FFmpegDisplayVersion $iv
        $verDisplay = Get-FFmpegDisplayVersion $ver
        if ($didCanon -or ($ivDisplay -and $verDisplay -and $ivDisplay -eq $verDisplay)) {
            $script:lFF_Result.Text=(T "IconLatest")+" "+(T "S1Result")+"  "+(T "ResLatest")
            $script:lFF_Result.ForeColor=$script:TEXT
            Refresh-VersionLabels
            Refresh-SummaryCard
        } else {
            $script:lFF_Result.Text=(Get-ResultIcon $iv $ver)+" "+(T "S1Result")+"  "+(Get-ResultMessage $iv $ver)
            $script:lFF_Result.ForeColor=$script:TEXT
            Refresh-SummaryCard
        }
    }
    else { $script:lFF_Avail.Text=(T "S1Available")+"  ?"; $script:lFF_Avail.ForeColor=$script:ERROR_C; if ($script:GitHubRateLimited) { Log-Warn (T 'LogRateLimit'); Set-BlockedStatus; Set-BlockedStatus; Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } elseif (($script:lFF_Avail.Text -match '\?$') -and ($script:lMpv_Avail.Text -match '\?$') -and ($script:lMySW_Avail.Text -match '\?$')) { Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } else { Set-ApiStatus '' $script:MUTED } }
})
$btnMpv_C.Add_Click({
        $script:lMpv_Avail.Text=T "S2Checking"; [System.Windows.Forms.Application]::DoEvents()
    $r=Get-MpvLatestRelease
    if ($r) {
        $script:CheckedMpvAvailable=$r.tag_name
        $didCanon = Rewrite-MpvJsonToOnlineTag $r.tag_name
        $script:lMpv_Avail.Text=(T "S2Available")+"  "+$r.tag_name
        $script:lMpv_Avail.ForeColor=$script:SUCCESS
        $iv=(Get-InstalledVersions).mpv
        if ($didCanon) {
            $script:lMpv_Result.Text=(T "IconLatest")+" "+(T "S2Result")+"  "+(T "ResLatest")
            $script:lMpv_Result.ForeColor=$script:TEXT
            Refresh-VersionLabels
            Refresh-SummaryCard
        } elseif ((Get-MpvHashFragment $iv) -and (Get-MpvHashFragment $r.tag_name) -and (((Get-MpvHashFragment $iv).StartsWith((Get-MpvHashFragment $r.tag_name))) -or ((Get-MpvHashFragment $r.tag_name).StartsWith((Get-MpvHashFragment $iv))))) {
            $script:lMpv_Result.Text=(T "IconLatest")+" "+(T "S2Result")+"  "+(T "ResLatest")
            $script:lMpv_Result.ForeColor=$script:TEXT
            Refresh-VersionLabels
            Refresh-SummaryCard
        } else {
            $script:lMpv_Result.Text=(Get-ResultIcon $iv $r.tag_name)+" "+(T "S2Result")+"  "+(Get-ResultMessage $iv $r.tag_name)
            $script:lMpv_Result.ForeColor=$script:TEXT
            Refresh-SummaryCard
        }
    }
    else { $script:lMpv_Avail.Text=(T "S2Available")+"  ?"; $script:lMpv_Avail.ForeColor=$script:ERROR_C; if ($script:GitHubRateLimited) { Log-Warn (T 'LogRateLimit'); Set-BlockedStatus; Set-BlockedStatus; Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } elseif (($script:lFF_Avail.Text -match '\?$') -and ($script:lMpv_Avail.Text -match '\?$') -and ($script:lMySW_Avail.Text -match '\?$')) { Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } else { Set-ApiStatus '' $script:MUTED } }
})
$btnMySW_C.Add_Click({
        $script:lMySW_Avail.Text=T "S3Checking"; [System.Windows.Forms.Application]::DoEvents()
    $r=Get-MyLatestRelease
    if ($r) { $script:CheckedMyAvailable=$r.tag_name; $script:lMySW_Avail.Text=(T "S3Available")+"  "+$r.tag_name; $script:lMySW_Avail.ForeColor=$script:SUCCESS; $iv=(Get-InstalledVersions).mpvsw; $script:lMySW_Result.Text=(Get-ResultIcon $iv $r.tag_name)+" "+(T "S3Result")+"  "+(Get-ResultMessage $iv $r.tag_name); $script:lMySW_Result.ForeColor=$script:TEXT; Refresh-SummaryCard }
    else { $script:lMySW_Avail.Text=(T "S3Available")+"  ?"; $script:lMySW_Avail.ForeColor=$script:ERROR_C; if ($script:GitHubRateLimited) { Log-Warn (T 'LogRateLimit'); Set-BlockedStatus; Set-BlockedStatus; Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } elseif (($script:lFF_Avail.Text -match '\?$') -and ($script:lMpv_Avail.Text -match '\?$') -and ($script:lMySW_Avail.Text -match '\?$')) { Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } else { Set-ApiStatus '' $script:MUTED } }
})

$btnFF_M.Add_Click({ $u = $(if ((Get-FFmpegMode) -eq 'stable') { $FFmpegLatestPage } else { $FFmpegReleasesPage }); Log-Info ('[manual] Opening: ' + $u); if (-not (Open-Url $u)) { Log-Warn '[manual] Browser could not be opened automatically.' } })
$btnMpv_M.Add_Click({ Log-Info ('[manual] Opening: ' + $MpvLatestPage); if (-not (Open-Url $MpvLatestPage)) { Log-Warn '[manual] Browser could not be opened automatically.' } })
$btnMySW_M.Add_Click({ Log-Info ('[manual] Opening: ' + $MyLatestPage); if (-not (Open-Url $MyLatestPage)) { Log-Warn '[manual] Browser could not be opened automatically.' } })

$btnFF_I.Add_Click({
    Run-WithLock {
        Set-Status (T "StatusDownloading") $script:NOTE_C
        Do-InstallFFmpeg $false
        Refresh-InstalledNow
        if ($script:GitHubRateLimited) { Set-ApiStatus (T 'StatusRateLimitInline') $script:NOTE_C }
        Set-Status (T "StatusDone") $script:SUCCESS
    }
})
$btnMpv_I.Add_Click({
    $v=Get-SelectedMpvVariant
    Run-WithLock {
        Set-Status (T "StatusDownloading") $script:NOTE_C
        Do-InstallMPV $v $false
        if ($script:GitHubRateLimited) { Set-ApiStatus (T 'StatusRateLimitInline') $script:NOTE_C }
        Set-Status (T "StatusDone") $script:SUCCESS
    }
})
$btnMySW_I.Add_Click({
    Run-WithLock {
        Set-Status (T "StatusDownloading") $script:NOTE_C
        Do-InstallMySW $false
        if ($script:GitHubRateLimited) { Set-ApiStatus (T 'StatusRateLimitInline') $script:NOTE_C }
        Set-Status (T "StatusDone") $script:SUCCESS
    }
})

$btnCheckAll.Add_Click({
    Clear-RemoteCache
    Set-Status (T "StatusChecking") $script:NOTE_C; [System.Windows.Forms.Application]::DoEvents()
    $ver,$a=Get-FFmpegLatest
    if ($a -and $ver) { $script:CheckedFFAvailable=$ver; $script:lFF_Avail.Text=(T "S1Available")+"  "+$ver; $script:lFF_Avail.ForeColor=$script:SUCCESS; $iv=(Get-InstalledVersions).ffmpeg; $script:lFF_Result.Text=(Get-ResultIcon $iv $ver)+" "+(T "S1Result")+"  "+(Get-ResultMessage $iv $ver) }
    else { $script:lFF_Avail.Text=(T "S1Available")+"  ?"; $script:lFF_Avail.ForeColor=$script:ERROR_C }
    $r2=Get-MpvLatestRelease
    if ($r2) {
        $variant = Get-SelectedMpvVariant
        $variantVer, $variantAsset = Get-MpvVersionForVariant $variant
        $script:CheckedMpvAvailable=$(if ($variantVer) { $variantVer } else { $r2.tag_name })
        $didCanon = Rewrite-MpvJsonToOnlineTag $script:CheckedMpvAvailable
        $script:lMpv_Avail.Text=(T "S2Available")+"  "+$script:CheckedMpvAvailable
        $script:lMpv_Avail.ForeColor=$script:SUCCESS
        $iv=(Get-InstalledVersions).mpv
        if ($didCanon) {
            $script:lMpv_Result.Text=(T "IconLatest")+" "+(T "S2Result")+"  "+(T "ResLatest")
            Refresh-VersionLabels
            Refresh-SummaryCard
        } elseif ((Get-MpvHashFragment $iv) -and (Get-MpvHashFragment $script:CheckedMpvAvailable) -and (((Get-MpvHashFragment $iv).StartsWith((Get-MpvHashFragment $script:CheckedMpvAvailable))) -or ((Get-MpvHashFragment $script:CheckedMpvAvailable).StartsWith((Get-MpvHashFragment $iv))))) {
            $script:lMpv_Result.Text=(T "IconLatest")+" "+(T "S2Result")+"  "+(T "ResLatest")
            Refresh-VersionLabels
            Refresh-SummaryCard
        } else {
            $script:lMpv_Result.Text=(Get-ResultIcon $iv $script:CheckedMpvAvailable)+" "+(T "S2Result")+"  "+(Get-ResultMessage $iv $script:CheckedMpvAvailable)
        }
    }
    else { $script:lMpv_Avail.Text=(T "S2Available")+"  ?"; $script:lMpv_Avail.ForeColor=$script:ERROR_C }
    $r3=Get-MyLatestRelease
    if ($r3) { $script:CheckedMyAvailable=$r3.tag_name; $script:lMySW_Avail.Text=(T "S3Available")+"  "+$r3.tag_name; $script:lMySW_Avail.ForeColor=$script:SUCCESS; $iv=(Get-InstalledVersions).mpvsw; $script:lMySW_Result.Text=(Get-ResultIcon $iv $r3.tag_name)+" "+(T "S3Result")+"  "+(Get-ResultMessage $iv $r3.tag_name) }
    else { $script:lMySW_Avail.Text=(T "S3Available")+"  ?"; $script:lMySW_Avail.ForeColor=$script:ERROR_C }
    Refresh-SummaryCard
    if ($script:GitHubRateLimited -or (($script:lFF_Avail.Text -match '\?$') -and ($script:lMpv_Avail.Text -match '\?$') -and ($script:lMySW_Avail.Text -match '\?$'))) { Log-Warn (T 'LogRateLimit'); Set-ApiStatus (T 'StatusRateLimit') $script:NOTE_C } else { Set-ApiStatus '' $script:MUTED }
    Set-Status (T "StatusReady") $script:MUTED
})

$btnUpdateAll.Add_Click({
    $v=Get-SelectedMpvVariant
    Run-WithLock {
        Set-Status (T "StatusDownloading") $script:NOTE_C
        Do-InstallFFmpeg $false
        Do-InstallMPV $v $false
        Do-InstallMySW $false
        Refresh-InstalledNow
        if ($script:GitHubRateLimited) { Set-ApiStatus (T 'StatusRateLimitInline') $script:NOTE_C }
        Log-OK (T "LogAllDone")
        Set-Status (T "StatusDone") $script:SUCCESS
    }
})

$btnForce.Add_Click({
    $resp = [System.Windows.Forms.MessageBox]::Show((T 'ForceConfirmText'), (T 'ForceConfirmTitle'), [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    if (Test-Path $script:VersionFile) { Remove-Item $script:VersionFile -Force }
    $v=Get-SelectedMpvVariant
    Refresh-VersionLabels
    Log-Warn (T 'LogForced')
    Run-WithLock {
        Set-Status (T "StatusDownloading") $script:NOTE_C
        Do-InstallFFmpeg $true
        Do-InstallMPV $v $true
        Do-InstallMySW $true
        Refresh-InstalledNow
        if ($script:GitHubRateLimited) { Set-ApiStatus (T 'StatusRateLimitInline') $script:NOTE_C }
        Log-OK (T "LogAllDone")
        Set-Status (T "StatusDone") $script:SUCCESS
    }
})

# ============================================================
#  LANGUAGE TOGGLE
# ============================================================
function Apply-Lang([string]$lang) {
    $script:CurrentLang=$lang
    Style-LangBtn $btnEN ($lang -eq "EN")
    Style-LangBtn $btnES ($lang -eq "ES")

    $form.Text = T 'Title'
    $lAppSub.Text=T "HeaderSub"; $lLangLbl.Text=T "LangLabel"; $lHeaderNote.Text=T "HeaderNote"

    foreach ($card in @($card1,$card2,$card3,$card4,$card5,$card6)) {
        $tL=$card.Controls | Where-Object {
            ($_ -is [System.Windows.Forms.Label]) -and $_.Font.Bold -and ($_.Font.Size -eq $FontSectionTitle.Size)
        } | Select-Object -First 1
        if ($tL) {
            switch ($card.Tag) {
                "S1"   { $tL.Text=T "S1Title" }
                "S2"   { $tL.Text=T "S2Title" }
                "S3"   { $tL.Text=T "S3Title" }
                "S4"   { $tL.Text=T "S4Title" }
                "ACT"  { $tL.Text=T "ActionsTitle" }
                "ACT6" { $tL.Text=T "ActionsTitle" }
            }
        }
    }

    $lFF_Desc.Text=T "S1Desc"; $lMpv_Desc.Text=T "S2Desc"; $lMySW_Desc.Text=T "S3Desc"
    $lVarLbl.Text=T "S2VariantLbl"
    $rbV1.Text=T "S2V1"; $rbV2.Text=T "S2V2"; $rbV3.Text=T "S2V3"
    $lS4Lbl.Text=T "S4Label"
    $btnFF_C.Text=T "S1BtnCheck"; $btnFF_I.Text=T "S1BtnInstall"
    $btnMpv_C.Text=T "S2BtnCheck"; $btnMpv_I.Text=T "S2BtnInstall"
    $btnMySW_C.Text=T "S3BtnCheck"; $btnMySW_I.Text=T "S3BtnInstall"
    $btnCheckAll.Text=T "ActCheckAll"; $btnUpdateAll.Text=T "ActUpdateAll"; $btnForce.Text=T "ActForce"
    $script:rbFFStable.Text = T "S1ModeStable"
    $script:rbFFDaily.Text  = T "S1ModeDaily"
    if ($script:lStatusLbl) { $script:lStatusLbl.Text = T "StatusLbl" }
    $knownStatusKeys = @('StatusReady','StatusChecking','StatusDownloading','StatusDone','StatusUpToDate')
    $otherLang = if ($lang -eq 'EN') { 'ES' } else { 'EN' }
    $matched = $false
    foreach ($key in $knownStatusKeys) {
        $valOther = $script:Lang[$otherLang][$key]
        if ($script:lStatus.Text -eq $valOther -or $script:lStatus.Text -eq $script:Lang[$lang][$key]) {
            $script:lStatus.Text = T $key
            $matched = $true
            break
        }
    }
    if (-not $matched -and (-not $script:GitHubRateLimited)) {
        $script:lStatus.Text = T 'StatusReady'
        $script:lStatus.ForeColor = $script:MUTED
    }
    if (-not $script:LogBox.TextLength) {
        Log-Info (T 'LogReady')
    }
    Refresh-VersionLabels; $form.Refresh()
}

# ============================================================
#  BUTTON EVENTS (modificados para guardar idioma)
# ============================================================
$btnEN.Add_Click({
    Apply-Lang "EN"
    Save-GUILanguage "EN"
})
$btnES.Add_Click({
    Apply-Lang "ES"
    Save-GUILanguage "ES"
})

$rbV1.Add_CheckedChanged({ if ($rbV1.Checked) { Update-MpvAvailableForSelection } })
$rbV2.Add_CheckedChanged({ if ($rbV2.Checked) { Update-MpvAvailableForSelection } })
$rbV3.Add_CheckedChanged({ if ($rbV3.Checked) { Update-MpvAvailableForSelection } })

# ============================================================
#  INIT
# ============================================================
[void](Sync-OfflineInstalledVersions)

# Cargar idioma guardado
$savedLang = Load-GUILanguage
Apply-Lang $savedLang

Set-ApiStatus '' $script:MUTED

[System.Windows.Forms.Application]::Run($form)