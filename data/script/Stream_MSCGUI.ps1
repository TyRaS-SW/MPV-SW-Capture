# Stream_MSCGUI.ps1 - By TyRaS-SW
# GUI Tool for OBS + win-capture-audio integration
# EN/ES GUI - PowerShell 5+ (Windows 10/11)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ============================================================
# APPMODELID
# ============================================================
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class TaskbarAppId {
    [DllImport("shell32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);
}
"@
$script:AppUserModelID = "TyRaS.MPVSWCapture.StreamHelper"
try { [TaskbarAppId]::SetCurrentProcessExplicitAppUserModelID($script:AppUserModelID) | Out-Null } catch {}

# ============================================================
# ROOT DIRECTORY DETECTION
# ============================================================
function Get-RootDir {
    $scriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { (Get-Location).Path }
    if ((Split-Path $scriptDir -Leaf) -eq 'script' -and (Split-Path (Split-Path $scriptDir -Parent) -Leaf) -eq 'data') {
        return Split-Path -Parent (Split-Path -Parent $scriptDir)
    }
    return $scriptDir
}
$script:RootDir = Get-RootDir
$script:ToolsDir = Join-Path $script:RootDir "tools"
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
    # Si no existe o es inválido, devolver "EN" y crear el archivo
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
if (-not (Test-Path $script:ToolsDir)) { New-Item -ItemType Directory -Path $script:ToolsDir | Out-Null }

# ============================================================
# COLOR PALETTE
# ============================================================
$script:BG      = [System.Drawing.Color]::FromArgb(40, 38, 30)
$script:SURFACE = [System.Drawing.Color]::FromArgb(55, 52, 42)
$script:CARD    = [System.Drawing.Color]::FromArgb(70, 66, 54)
$script:ACCENT  = [System.Drawing.Color]::FromArgb(255, 215, 0)
$script:ACCENT2 = [System.Drawing.Color]::FromArgb(249, 168, 37)
$script:ACCENT3 = [System.Drawing.Color]::FromArgb(251, 192, 45)
$script:ACCENT4 = [System.Drawing.Color]::FromArgb(66, 133, 244)
$script:TEXT    = [System.Drawing.Color]::FromArgb(245, 240, 225)
$script:MUTED   = [System.Drawing.Color]::FromArgb(180, 170, 150)
$script:SUCCESS = [System.Drawing.Color]::FromArgb(72, 199, 116)
$script:ERROR_C = [System.Drawing.Color]::FromArgb(255, 100, 100)
$script:NOTE_C  = [System.Drawing.Color]::FromArgb(240, 210, 120)

$FontTitle        = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontSub          = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$FontBold         = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontBtn          = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontSmall        = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)
$FontBtnSmall     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontNote         = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$FontSectionTitle = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontLangBtn      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$FontMono         = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)

# ============================================================
# STRINGS (no accents in Spanish)
# ============================================================
$script:Lang = @{}
$script:Lang["EN"] = @{
    Title           = "MPV-SW-Capture - Stream Manager"
    HeaderSub       = "OBS Streaming Setup  -  One-click integration for MPV-SW-Capture"
    HeaderNote      = "This tool downloads win-capture-audio and configures OBS automatically."
    LangLabel       = "GUI Language:"
    S1Title         = "[OBS] INSTALLATION"
    S1Desc          = "Detect existing OBS or download the latest installer."
    S1Status        = "Status:"
    S1StatusFound   = "Found"
    S1StatusNotFound = "Not found"
    S1DetectBtn     = "Detect Installed OBS"
    S1DownloadBtn   = "Download OBS Installer"
    S1DownloadPortableBtn = "Download Portable OBS"
    S1ArchLabel     = "Portable Architecture:"
    S1OpenBtn       = "Open OBS"
    S1BrowseBtn     = "Browse OBS Folder (Portable)"
    S1PathLabel     = "OBS Path:"
    S1ModeLabel     = "Mode:"
    S1ModeChoice    = "Choose OBS Mode:"
    S1ModeInstalled = "Installed"
    S1ModePortable  = "Portable"
    S2Title         = "[OBS] win-capture-audio PLUGIN"
    S2Desc          = "Downloads and installs the plugin for OBS (bozbez/win-capture-audio)."
    S2Status        = "Status:"
    S2DetectBtn     = "Check Plugin"
    S2InstallBtn    = "Install Plugin"
    S2UninstallBtn  = "Uninstall Plugin"
    S2ManualBtn     = "Manual Download"
    S2OSDTitle      = "[MPV-SW-Capture] AUTOSTART HIDE OSD MESSAGES (Streamer Mode)"
    S2OSDDesc       = "This mode hides all messages that appear in the window when using options."
    S2OSDStatus     = "Status:"
    S2OSDEnabled    = "Enabled"
    S2OSDDisabled   = "Disabled"
    S2OSDCheckBtn   = "Check Status"
    S2OSDActivateBtn= "Activate Option"
    S2OSDDeactivateBtn = "Deactivate Option"
    S2OSDLogCheck   = "[OSD] Checking status..."
    S2OSDLogEnabled = "[OSD] Streamer Mode is enabled (osd-duration=0)."
    S2OSDLogDisabled= "[OSD] Streamer Mode is disabled (osd-duration=1000)."
    S2OSDLogActivated = "[OSD] Streamer Mode activated."
    S2OSDLogDeactivated = "[OSD] Streamer Mode deactivated."
    S2OSDLogError   = "[OSD] Error: {0}"
    S3Title         = "[OBS] SCENE CONFIGURATION"
    S3Desc          = "OPTIONAL: Install scene collection or add sources to existing scene automatically."
    S3Note          = "NOTE: If you already configured it. It's recommended to make a backup before doing anything."
    S3Note2         = "If you prefer, you can manually add scenes in OBS."
    S3Status        = "Status:"
    S3SceneLbl      = "Target Scene Collection:"
    S3BtnNew        = "Install New Scene Collection"
    S3BtnAdd        = "Add Sources to Selected Collection"
    S3BtnBackup     = "BACKUP Current OBS Scene Configuration"
    S3BtnRestore    = "RESTORE OBS Configuration"
    ActionsTitle    = "ACTIONS"
    StatusReady     = "Ready."
    StatusDone      = "Done!"
    StatusChecking  = "Checking..."
    StatusDownload  = "Downloading..."
    LogReady        = "OBS Helper ready."
    LogDetecting    = "[OBS] Detecting installation..."
    LogFound        = "[OBS] Found at: {0}"
    LogFoundPortable = "[OBS] Found portable at: {0}"
    LogNotFound     = "[OBS] Not found in standard locations."
    LogDL           = "[OBS] Downloading installer..."
    LogDLOK         = "[OBS] Download complete: {0}"
    LogDLCancel     = "[OBS] Download cancelled."
    LogPluginChk    = "[Plugin] Checking win-capture-audio..."
    LogPluginFound  = "[Plugin] Already installed."
    LogPluginNotFound = "[Plugin] Not installed."
    LogPluginDL     = "[Plugin] Downloading latest release..."
    LogPluginExtract = "[Plugin] Extracting to OBS root..."
    LogPluginOK     = "[Plugin] Installed successfully."
    LogPluginErr    = "[Plugin] Error: {0}"
    LogPluginUninstalled = "[Plugin] Uninstalled successfully."
    LogPluginUninstallErr = "[Plugin] Uninstall error: {0}"
    LogSceneStart   = "[Scene] Configuring OBS scene..."
    LogSceneOpen    = "[Scene] OBS is running. Please close it to proceed."
    LogSceneBackup  = "[Scene] Backup created: {0}"
    LogSceneAdd     = "[Scene] Sources added to scene collection '{0}'."
    LogSceneErr     = "[Scene] Error: {0}"
    LogBackupStart  = "[Backup] Creating backup of OBS configuration..."
    LogBackupOK     = "[Backup] Backup created: {0}"
    LogBackupErr    = "[Backup] Error: {0}"
    LogRestoreStart = "[Restore] Restoring OBS configuration from: {0}"
    LogRestoreOK    = "[Restore] Restore completed successfully."
    LogRestoreErr   = "[Restore] Error: {0}"
    LogSceneNoCollections = "[Scene] No scene collections found."
    ConfirmCloseOBS = "OBS Studio is currently running.`n`nPlease close OBS before continuing, as the configuration files need to be updated."
    ConfirmTitle    = "MPV-SW-Capture Stream Manager"
    ConfirmUninstallPlugin = "Are you sure you want to uninstall the win-capture-audio plugin?`n`nThis will remove all plugin files from OBS."
    ConfirmRestore  = "Are you sure you want to restore OBS configuration from the selected backup?`n`nThis will overwrite all current scene collections and settings.`n`nIt's recommended to create a backup before restoring."
    MsgAdminRequired = "OBS is installed in a protected folder.{0}{0}To install the plugin, you need to run this program as Administrator.{0}{0}Please close and restart with Administrator rights."
MsgAdminTitle = "Administrator Rights Required"
}
$script:Lang["ES"] = @{
    Title           = "MPV-SW-Capture - Administrador de Stream"
    HeaderSub       = "Configuracion para OBS  -  Integracion automatica para MPV-SW-Capture"
    HeaderNote      = "Esta herramienta descarga win-capture-audio y configura OBS automaticamente."
    LangLabel       = "Idioma del GUI:"
    S1Title         = "[OBS] INSTALACION"
    S1Desc          = "Detectar OBS existente o descargar el ultimo instalador."
    S1Status        = "Estado:"
    S1StatusFound   = "Encontrado"
    S1StatusNotFound = "No encontrado"
    S1DetectBtn     = "Detectar OBS Instalado"
    S1DownloadBtn   = "Descargar Instalador OBS"
    S1DownloadPortableBtn = "Descargar OBS Portable"
    S1ArchLabel     = "Arquitectura Portable:"
    S1OpenBtn       = "Abrir OBS"
    S1BrowseBtn     = "Examinar Carpeta OBS (Portable)"
    S1PathLabel     = "Ruta OBS:"
    S1ModeLabel     = "Modo:"
    S1ModeChoice    = "Elegir modo OBS:"
    S1ModeInstalled = "Instalado"
    S1ModePortable  = "Portable"
    S2Title         = "[OBS] PLUGIN win-capture-audio"
    S2Desc          = "Descarga e instala el plugin para OBS (bozbez/win-capture-audio)."
    S2Status        = "Estado:"
    S2DetectBtn     = "Verificar Plugin"
    S2InstallBtn    = "Instalar Plugin"
    S2UninstallBtn  = "Desinstalar Plugin"
    S2ManualBtn     = "Descarga Manual"
    S2OSDTitle      = "[MPV-SW-Capture] OCULTAR MENSAJES OSD AL INICIO (Modo Streamer)"
    S2OSDDesc       = "Este modo oculta todos los mensajes que aparecen en la ventana al usar opciones."
    S2OSDStatus     = "Estado:"
    S2OSDEnabled    = "Activado"
    S2OSDDisabled   = "Desactivado"
    S2OSDCheckBtn   = "Verificar Estado"
    S2OSDActivateBtn= "Activar Opcion"
    S2OSDDeactivateBtn = "Desactivar Opcion"
    S2OSDLogCheck   = "[OSD] Verificando estado..."
    S2OSDLogEnabled = "[OSD] El modo Streamer esta activado (osd-duration=0)."
    S2OSDLogDisabled= "[OSD] El modo Streamer esta desactivado (osd-duration=1000)."
    S2OSDLogActivated = "[OSD] Modo Streamer activado."
    S2OSDLogDeactivated = "[OSD] Modo Streamer desactivado."
    S2OSDLogError   = "[OSD] Error: {0}"
    S3Title         = "[OBS] CONFIGURACION DE ESCENA"
    S3Desc          = "OPCIONAL: Instala automaticamente escenas o agregar fuentes a escena existente."
    S3Note          = "NOTA: Si ya lo configuraste, se recomienda hacer un backup antes de hacer cualquier cambio."
    S3Note2         = "Si prefieres, puedes agregar escenas manualmente en OBS."
    S3Status        = "Estado:"
    S3SceneLbl      = "Coleccion de Escenas destino:"
    S3BtnNew        = "Instalar Nueva Coleccion de Escenas"
    S3BtnAdd        = "Agregar Fuentes a Coleccion Seleccionada"
    S3BtnBackup     = "BACKUP de la Configuracion Actual de OBS"
    S3BtnRestore    = "RESTAURAR Configuracion de OBS"
    ActionsTitle    = "ACCIONES"
    StatusReady     = "Listo."
    StatusDone      = "Completado!"
    StatusChecking  = "Verificando..."
    StatusDownload  = "Descargando..."
    LogReady        = "OBS Helper listo."
    LogDetecting    = "[OBS] Detectando instalacion..."
    LogFound        = "[OBS] Encontrado en: {0}"
    LogFoundPortable = "[OBS] Encontrado portable en: {0}"
    LogNotFound     = "[OBS] No encontrado en ubicaciones estandar."
    LogDL           = "[OBS] Descargando instalador..."
    LogDLOK         = "[OBS] Descarga completada: {0}"
    LogDLCancel     = "[OBS] Descarga cancelada."
    LogPluginChk    = "[Plugin] Verificando win-capture-audio..."
    LogPluginFound  = "[Plugin] Ya instalado."
    LogPluginNotFound = "[Plugin] No instalado."
    LogPluginDL     = "[Plugin] Descargando ultima version..."
    LogPluginExtract = "[Plugin] Extrayendo en la raiz de OBS..."
    LogPluginOK     = "[Plugin] Instalado correctamente."
    LogPluginErr    = "[Plugin] Error: {0}"
    LogPluginUninstalled = "[Plugin] Desinstalado correctamente."
    LogPluginUninstallErr = "[Plugin] Error al desinstalar: {0}"
    LogSceneStart   = "[Escena] Configurando escena de OBS..."
    LogSceneOpen    = "[Escena] OBS esta ejecutandose. Por favor, cierralo para continuar."
    LogSceneBackup  = "[Escena] Copia de seguridad creada: {0}"
    LogSceneAdd     = "[Escena] Fuentes agregadas a la coleccion de escenas '{0}'."
    LogSceneErr     = "[Escena] Error: {0}"
    LogBackupStart  = "[Backup] Creando backup de la configuracion de OBS..."
    LogBackupOK     = "[Backup] Backup creado: {0}"
    LogBackupErr    = "[Backup] Error: {0}"
    LogRestoreStart = "[Restore] Restaurando configuracion de OBS desde: {0}"
    LogRestoreOK    = "[Restore] Restauracion completada correctamente."
    LogRestoreErr   = "[Restore] Error: {0}"
    LogSceneNoCollections = "[Escena] No se encontraron colecciones de escenas."
    ConfirmCloseOBS = "OBS Studio se esta ejecutando.`n`nPor favor, cierra OBS antes de continuar, ya que los archivos de configuracion deben actualizarse."
    ConfirmTitle    = "MPV-SW-Capture Stream Manager"
    ConfirmUninstallPlugin = "Esta seguro de desinstalar el plugin win-capture-audio?`n`nSe eliminaran todos los archivos del plugin de OBS."
    ConfirmRestore  = "Esta seguro de restaurar la configuracion de OBS desde el backup seleccionado?`n`nEsto sobrescribira todas las colecciones de escenas y configuraciones actuales.`n`nSe recomienda crear un backup antes de restaurar."
    MsgAdminRequired = "OBS esta instalado en una carpeta protegida.{0}{0}Para instalar el plugin, necesitas ejecutar este programa como Administrador.{0}{0}Por favor, cierra y reinicia con derechos de Administrador."
MsgAdminTitle = "Se requieren derechos de Administrador"
}

$script:CurrentLang = "EN"
function T { param([string]$key) return $script:Lang[$script:CurrentLang][$key] }

# ============================================================
# UI HELPERS
# ============================================================
function New-Lbl([string]$text,[int]$x,[int]$y,[int]$w,[int]$h,
                 [System.Drawing.Font]$font,[System.Drawing.Color]$color) {
    if (-not $font) { $font = $FontSub }
    if ($color.IsEmpty) { $color = $script:TEXT }
    $l = New-Object System.Windows.Forms.Label
    $l.Text=$text
    $l.Location=[System.Drawing.Point]::new($x,$y)
    $l.Size=[System.Drawing.Size]::new($w,$h)
    $l.Font=$font
    $l.ForeColor=$color
    $l.BackColor=[System.Drawing.Color]::Transparent
    $l.AutoSize=$false
    return $l
}
function New-Pnl([int]$x,[int]$y,[int]$w,[int]$h,[System.Drawing.Color]$color) {
    if ($color.IsEmpty) { $color = $script:CARD }
    $p = New-Object System.Windows.Forms.Panel
    $p.Location=[System.Drawing.Point]::new($x,$y)
    $p.Size=[System.Drawing.Size]::new($w,$h)
    $p.BackColor=$color
    return $p
}
function Style-Btn([System.Windows.Forms.Button]$btn,
                   [System.Drawing.Color]$bg,[System.Drawing.Color]$fg) {
    if ($bg.IsEmpty) { $bg=$script:ACCENT }
    if ($fg.IsEmpty) { $fg=$script:BG }
    $btn.BackColor=$bg
    $btn.ForeColor=$fg
    $btn.Font=$FontBtn
    $btn.FlatStyle='Flat'
    $btn.FlatAppearance.BorderSize=0
    $btn.Cursor=[System.Windows.Forms.Cursors]::Hand
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
        $btn.BackColor=$script:ACCENT
        $btn.ForeColor=$script:BG
        $btn.FlatAppearance.BorderColor=$script:ACCENT
    } else {
        $btn.BackColor=$script:SURFACE
        $btn.ForeColor=$script:MUTED
        $btn.FlatAppearance.BorderColor=$script:MUTED
    }
}
function New-CardXY([System.Windows.Forms.Control]$parent,
    [int]$x,[int]$y,[int]$w,[int]$h,[string]$titleKey) {
    $card=New-Pnl $x $y $w $h $script:CARD
    $bar=New-Pnl 0 0 $w 3 $script:ACCENT
    $card.Controls.Add($bar)
    $lT=New-Lbl (T $titleKey) 14 8 ($w-20) 22 $FontSectionTitle $script:ACCENT
    $card.Controls.Add($lT)
    $parent.Controls.Add($card)
    return $card
}
function Append-Log([string]$msg,[System.Drawing.Color]$color) {
    if ($null -eq $script:LogBox) { return }
    try {
        $safeColor = if ($null -ne $color -and -not $color.IsEmpty) { $color } else { $script:TEXT }
    } catch { $safeColor = $script:TEXT }
    try {
        $script:LogBox.SelectionStart = $script:LogBox.TextLength
        $script:LogBox.SelectionLength = 0
        $script:LogBox.SelectionColor = $safeColor
        $script:LogBox.AppendText($msg + "`n")
        $script:LogBox.SelectionColor = $script:LogBox.ForeColor
        $script:LogBox.ScrollToCaret()
    } catch {}
    [System.Windows.Forms.Application]::DoEvents()
}
function Log-Info([string]$m)  { Append-Log $m $script:TEXT }
function Log-OK([string]$m)    { Append-Log $m $script:SUCCESS }
function Log-Warn([string]$m)  { Append-Log $m $script:NOTE_C }
function Log-Error([string]$m) { Append-Log $m $script:ERROR_C }
function Set-Status([string]$msg,[System.Drawing.Color]$color) {
    $script:lStatus.Text = $msg
    $script:lStatus.ForeColor = $color
    [System.Windows.Forms.Application]::DoEvents()
}
function Open-Url([string]$url) { try { Start-Process $url } catch {} }

function Test-AdminRights {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ============================================================
# PERSISTENT CONFIG (dos modos separados)
# ============================================================
$script:ConfigFile = Join-Path $script:ToolsDir "user-stream.json"
$script:CurrentOBSMode = "Installed"  # "Installed" o "Portable"
$script:OBSRootInstalled = $null
$script:OBSRootPortable = $null
$script:OBSRoot = $null  # Ruta activa según modo

function Load-OBSConfig {
    if (Test-Path $script:ConfigFile) {
        try {
            $json = Get-Content $script:ConfigFile -Encoding UTF8 | ConvertFrom-Json
            $inst = $json.OBSRootInstalled
            $port = $json.OBSRootPortable
            $mode = $json.OBSMode

            if ($inst -and (Test-Path (Join-Path $inst "bin\64bit\obs64.exe"))) {
                $script:OBSRootInstalled = $inst
            } else {
                $script:OBSRootInstalled = $null
            }
            if ($port -and (Test-Path (Join-Path $port "bin\64bit\obs64.exe"))) {
                $script:OBSRootPortable = $port
            } else {
                $script:OBSRootPortable = $null
            }

            if ($mode -eq "Installed" -or $mode -eq "Portable") {
                $script:CurrentOBSMode = $mode
            } else {
                $script:CurrentOBSMode = "Installed"
            }

            if ($json.OBSRoot -and -not $inst -and -not $port) {
                $root = $json.OBSRoot
                if (Test-Path (Join-Path $root "bin\64bit\obs64.exe")) {
                    if ($json.OBSMode -eq "Portable") {
                        $script:OBSRootPortable = $root
                    } else {
                        $script:OBSRootInstalled = $root
                    }
                }
            }

            if ($script:CurrentOBSMode -eq "Installed") {
                $script:OBSRoot = $script:OBSRootInstalled
            } else {
                $script:OBSRoot = $script:OBSRootPortable
            }
            return $script:OBSRoot
        } catch {}
    }
    $root = Find-OBSRoot -Mode $script:CurrentOBSMode
    if ($script:CurrentOBSMode -eq "Installed") {
        $script:OBSRootInstalled = $root
    } else {
        $script:OBSRootPortable = $root
    }
    $script:OBSRoot = $root
    Save-OBSConfig $root
    return $root
}

function Save-OBSConfig([string]$root) {
    if ($root) {
        if ($script:CurrentOBSMode -eq "Installed") {
            $script:OBSRootInstalled = $root
        } else {
            $script:OBSRootPortable = $root
        }
        $script:OBSRoot = $root
    }
    $obj = @{
        OBSRootInstalled = $script:OBSRootInstalled
        OBSRootPortable  = $script:OBSRootPortable
        OBSMode          = $script:CurrentOBSMode
    }
    $obj | ConvertTo-Json | Set-Content $script:ConfigFile -Encoding UTF8
}

# ============================================================
# OBS DETECTION AND CONFIGURATION (con modo)
# ============================================================
function Get-OBSUserConfig {
    param([bool]$Silent = $false)
    if ($script:OBSRoot) {
        $portableCandidates = @(
            (Join-Path $script:OBSRoot "config\obs-studio"),
            (Join-Path $script:OBSRoot "config")
        )
        foreach ($candidate in $portableCandidates) {
            if (Test-Path $candidate) {
                if (-not $Silent) { Log-Info "[Config] Using config path: $candidate" }
                return $candidate
            }
        }
    }
    $config = "$env:APPDATA\obs-studio"
    if (Test-Path $config) { 
        if (-not $Silent) { Log-Info "[Config] Using APPDATA: $config" }
        return $config 
    }
    if (-not $Silent) { Log-Warn "[Config] No OBS config folder found." }
    return $null
}

function Find-OBSRoot {
    param([string]$Mode = $script:CurrentOBSMode)
    Log-Info (T "LogDetecting")
    $paths = @()
    if ($Mode -eq "Installed") {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\obs64.exe"
            $obsExe = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).'(Default)'
            if ($obsExe) { $paths += $obsExe }
        } catch {}
        try {
            $regPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OBS Studio"
            $installPath = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).DisplayIcon
            if ($installPath) {
                $installPath = Split-Path $installPath -Parent
                $paths += (Join-Path $installPath "bin\64bit\obs64.exe")
            }
        } catch {}
        $paths += @(
            "C:\Program Files\obs-studio\bin\64bit\obs64.exe",
            "C:\Program Files (x86)\obs-studio\bin\64bit\obs64.exe",
            "$env:LOCALAPPDATA\Programs\obs-studio\bin\64bit\obs64.exe"
        )
    } else {
        $savedRoot = if ($Mode -eq "Installed") { $script:OBSRootInstalled } else { $script:OBSRootPortable }
        if ($savedRoot -and (Test-Path (Join-Path $savedRoot "bin\64bit\obs64.exe"))) {
            $paths += (Join-Path $savedRoot "bin\64bit\obs64.exe")
        }
        $rootDir = $script:RootDir
        $paths += @(
            (Join-Path $rootDir "bin\64bit\obs64.exe"),
            (Join-Path $rootDir "..\bin\64bit\obs64.exe"),
            (Join-Path $env:USERPROFILE "obs-portable\bin\64bit\obs64.exe")
        )
    }

    foreach ($p in $paths) {
        if (Test-Path $p) {
            $root = Split-Path (Split-Path (Split-Path $p -Parent) -Parent) -Parent
            Log-OK ([string]::Format((T "LogFound"), $root))
            return $root
        }
    }
    Log-Warn (T "LogNotFound")
    return $null
}

function Is-OBSPortable {
    param([string]$obsRoot)
    if ($obsRoot -match "Program Files" -or $obsRoot -match "ProgramFiles") {
        return $false
    }
    if (Test-Path (Join-Path $obsRoot "config")) {
        return $true
    }
    return $true
}

function Get-AllSceneCollections {
    $configPath = Get-OBSUserConfig -Silent $true
    if (-not $configPath) { return @() }
    $scenesDir = Join-Path $configPath "basic\scenes"
    if (-not (Test-Path $scenesDir)) { return @() }
    $collections = @()
    Get-ChildItem -Path $scenesDir -Filter "*.json" | ForEach-Object {
        $name = $_.BaseName
        $collections += $name
    }
    return $collections
}

function Get-ActiveSceneCollection {
    $configPath = Get-OBSUserConfig -Silent $true
    if (-not $configPath) { return $null }
    $globalIni = Join-Path $configPath "global.ini"
    if (Test-Path $globalIni) {
        try {
            $content = Get-Content $globalIni -Encoding UTF8
            foreach ($line in $content) {
                if ($line -match '^SceneCollection\s*=\s*(.+)$') {
                    return $Matches[1].Trim()
                }
            }
        } catch {}
    }
    $collections = Get-AllSceneCollections
    if ($collections.Count -gt 0) { return $collections[0] }
    return $null
}

function Get-ScenesJsonPathForCollection {
    param([string]$collectionName)
    $configPath = Get-OBSUserConfig -Silent $true
    if (-not $configPath) { return $null }
    if (-not $collectionName) { return $null }
    $scenesPath = Join-Path $configPath "basic\scenes\$collectionName.json"
    if (Test-Path $scenesPath) { return $scenesPath }
    return $null
}

function Ensure-GlobalIni {
    param([string]$configPath, [string]$collectionName)
    $globalIni = Join-Path $configPath "global.ini"
    $needUpdate = $true
    
    if (Test-Path $globalIni) {
        $content = Get-Content $globalIni -Encoding UTF8
        foreach ($line in $content) {
            if ($line -match '^SceneCollection\s*=\s*(.+)$') {
                if ($Matches[1].Trim() -eq $collectionName) {
                    $needUpdate = $false
                }
                break
            }
        }
    }
    
    if ($needUpdate) {
        $iniContent = @"
[General]
SceneCollection=$collectionName
"@
        Set-Content -Path $globalIni -Value $iniContent -Encoding UTF8
        Log-OK "[Config] Created/updated global.ini with SceneCollection=$collectionName"
        return $true
    }
    Log-Info "[Config] global.ini already has SceneCollection=$collectionName"
    return $true
}

# ============================================================
# JSON TEMPLATE (with placeholder for collection name)
# ============================================================
$script:SceneTemplate = @'
{
    "name": "{collection_name}",
    "sources": [
        {
            "prev_ver": 537001985,
            "name": "MPV-SW-Window",
            "uuid": "bed744e1-4c60-4eb0-bb28-34df2a1f9c1c",
            "id": "window_capture",
            "versioned_id": "window_capture",
            "settings": {
                "window": "MPV-SW-Capture:mpv:mpv.exe",
                "method": 2
            },
            "mixers": 255,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "libobs.mute": [],
                "libobs.unmute": [],
                "libobs.push-to-mute": [],
                "libobs.push-to-talk": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "private_settings": {}
        },
        {
            "prev_ver": 537001985,
            "name": "MPV-SW-Audio",
            "uuid": "f61e952f-2148-41a4-b02c-f4b9b1347ddf",
            "id": "audio_capture",
            "versioned_id": "audio_capture",
            "settings": {
                "executable_list": [
                    {
                        "hidden": false,
                        "selected": false,
                        "value": "ffplay.exe",
                        "uuid": "23777547-c201-4606-9ad3-cf22b24f0a04"
                    }
                ],
                "active_session_list": ""
            },
            "mixers": 255,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "libobs.mute": [],
                "libobs.unmute": [],
                "libobs.push-to-mute": [],
                "libobs.push-to-talk": [],
                "hotkey_start": [],
                "hotkey_stop": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "private_settings": {}
        },
        {
            "prev_ver": 537001985,
            "name": "Escena",
            "uuid": "f928b26f-e8c8-418d-97f4-e7c5444ad7f3",
            "id": "scene",
            "versioned_id": "scene",
            "settings": {
                "id_counter": 3,
                "custom_size": false,
                "items": [
                    {
                        "name": "MPV-SW-Window",
                        "source_uuid": "bed744e1-4c60-4eb0-bb28-34df2a1f9c1c",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 2,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 300
                        },
                        "hide_transition": {
                            "duration": 300
                        },
                        "private_settings": {}
                    },
                    {
                        "name": "MPV-SW-Audio",
                        "source_uuid": "f61e952f-2148-41a4-b02c-f4b9b1347ddf",
                        "visible": true,
                        "locked": false,
                        "rot": 0.0,
                        "align": 5,
                        "bounds_type": 0,
                        "bounds_align": 0,
                        "bounds_crop": false,
                        "crop_left": 0,
                        "crop_top": 0,
                        "crop_right": 0,
                        "crop_bottom": 0,
                        "id": 3,
                        "group_item_backup": false,
                        "pos": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale": {
                            "x": 1.0,
                            "y": 1.0
                        },
                        "bounds": {
                            "x": 0.0,
                            "y": 0.0
                        },
                        "scale_filter": "disable",
                        "blend_method": "default",
                        "blend_type": "normal",
                        "show_transition": {
                            "duration": 300
                        },
                        "hide_transition": {
                            "duration": 300
                        },
                        "private_settings": {}
                    }
                ]
            },
            "mixers": 0,
            "sync": 0,
            "flags": 0,
            "volume": 1.0,
            "balance": 0.5,
            "enabled": true,
            "muted": false,
            "push-to-mute": false,
            "push-to-mute-delay": 0,
            "push-to-talk": false,
            "push-to-talk-delay": 0,
            "hotkeys": {
                "OBSBasic.SelectScene": [],
                "libobs.show_scene_item.2": [],
                "libobs.hide_scene_item.2": [],
                "libobs.show_scene_item.3": [],
                "libobs.hide_scene_item.3": []
            },
            "deinterlace_mode": 0,
            "deinterlace_field_order": 0,
            "monitoring_type": 0,
            "canvas_uuid": "6c69626f-6273-4c00-9d88-c5136d61696e",
            "private_settings": {}
        }
    ],
    "groups": [],
    "scene_order": [
        {
            "name": "Escena"
        }
    ],
    "current_scene": "Escena",
    "current_program_scene": "Escena",
    "canvases": [],
    "current_transition": "Desvanecimiento",
    "transition_duration": 300,
    "transitions": [],
    "quick_transitions": [],
    "saved_projectors": [],
    "preview_locked": false,
    "scaling_enabled": false,
    "scaling_level": -20,
    "scaling_off_x": 0.0,
    "scaling_off_y": 0.0,
    "modules": {
        "captions": {
            "source": "",
            "enabled": false,
            "lang_id": 2058,
            "provider": "mssapi"
        },
        "output-timer": {
            "streamTimerHours": 0,
            "streamTimerMinutes": 0,
            "streamTimerSeconds": 0,
            "recordTimerHours": 0,
            "recordTimerMinutes": 0,
            "recordTimerSeconds": 0,
            "autoStartStreamTimer": false,
            "autoStartRecordTimer": false,
            "pauseRecordTimer": false
        },
        "auto-scene-switcher": {
            "interval": 300,
            "non_matching_scene": "",
            "switch_if_not_matching": false,
            "active": false,
            "switches": []
        },
        "scripts-tool": []
    },
    "version": 1
}
'@

# ============================================================
# OSD STREAMER MODE FUNCTIONS
# ============================================================
function Get-OSDStatus {
    $confPath = Join-Path $script:RootDir "mpv.conf"
    if (-not (Test-Path $confPath)) {
        return @{ enabled = $false; value = 1000 }
    }
    try {
        $lines = Get-Content $confPath -Encoding UTF8
        foreach ($line in $lines) {
            if ($line -match '^\s*osd-duration\s*=\s*(\d+)') {
                $val = [int]$Matches[1]
                return @{ enabled = ($val -eq 0); value = $val }
            }
        }
    } catch {}
    return @{ enabled = $false; value = 1000 }
}

function Set-OSDStatus {
    param([int]$newValue)
    $confPath = Join-Path $script:RootDir "mpv.conf"
    $utf8 = New-Object System.Text.UTF8Encoding $false

    if (-not (Test-Path $confPath)) {
        $content = "osd-duration=$newValue"
        [System.IO.File]::WriteAllText($confPath, $content, $utf8)
        return
    }

    try {
        $content = [System.IO.File]::ReadAllText($confPath, [System.Text.Encoding]::UTF8)
        if ($content -match '(?m)^\s*osd-duration\s*=\s*\d+') {
            $content = $content -replace '(?m)^\s*osd-duration\s*=\s*\d+', "osd-duration=$newValue"
        } else {
            if ($content -and -not $content.EndsWith("`r`n") -and -not $content.EndsWith("`n")) {
                $content += "`r`n"
            }
            $content += "osd-duration=$newValue"
        }
        [System.IO.File]::WriteAllText($confPath, $content, $utf8)
    } catch {
        throw $_.Exception.Message
    }
}

function Update-OSDDisplay {
    $status = Get-OSDStatus
    if ($status.enabled) {
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDEnabled")
        $script:lOSDStatus.ForeColor = $script:SUCCESS
    } else {
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDDisabled")
        $script:lOSDStatus.ForeColor = $script:ERROR_C
    }
}

# ============================================================
# MODE 1: Install New Scene Collection
# ============================================================
function Install-NewSceneCollection {
    param([string]$collectionName)
    
    if (-not $script:OBSRoot) {
        Log-Error "[New] OBS not found. Please detect OBS first."
        return $false
    }
    
    $configPath = Get-OBSUserConfig
    if (-not $configPath) {
        Log-Error "[New] Could not find OBS config folder."
        return $false
    }
    
    if (-not $collectionName) { $collectionName = "MPVSWCapture" }
    
    $scenesDir = Join-Path $configPath "basic\scenes"
    if (-not (Test-Path $scenesDir)) {
        New-Item -ItemType Directory -Path $scenesDir -Force | Out-Null
        Log-Info "[New] Created scenes directory"
    }
    
    $jsonPath = Join-Path $scenesDir "$collectionName.json"
    if (Test-Path $jsonPath) {
        $counter = 1
        while (Test-Path $jsonPath) {
            $newName = "$collectionName-$counter"
            $jsonPath = Join-Path $scenesDir "$newName.json"
            $counter++
        }
        Log-Info "[New] File exists, using $newName"
        $collectionName = $newName
    }
    
    Log-Info "[New] Creating new collection: $collectionName"
    
    try {
        $templateContent = $script:SceneTemplate -replace '{collection_name}', $collectionName
        
        $utf8 = New-Object System.Text.UTF8Encoding $false
        $stream = New-Object System.IO.StreamWriter($jsonPath, $false, $utf8)
        $stream.Write($templateContent)
        $stream.Close()
        Log-OK "[JSON] Template saved: $jsonPath"
        
        $content = Get-Content $jsonPath -Encoding UTF8 -Raw
        if ($content) {
            Log-OK "[JSON] File size: $($content.Length) bytes"
        } else {
            Log-Error "[JSON] File appears empty after saving."
            return $false
        }
        
        Ensure-GlobalIni -configPath $configPath -collectionName $collectionName
        Log-OK "[Scene] Scene collection installed successfully."
        
        [System.Windows.Forms.MessageBox]::Show(
            "Scene collection '$collectionName' installed successfully!`n`nIMPORTANT: To see this new collection in OBS, you must close and reopen OBS.`n`nThe Stream Manager will show it in the list immediately.",
            "MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        return $true
    } catch {
        Log-Error ([string]::Format((T "LogSceneErr"), $_.Exception.Message))
        return $false
    }
}
# ============================================================
# MODE 2: Add Sources to a Specific Collection
# ============================================================
function Add-SourcesToCollection {
    param([string]$collectionName, [string]$sceneName)
    
    if (-not $script:OBSRoot) {
        Log-Error "[Add] OBS not found. Please detect OBS first."
        return $false
    }
    
    $jsonPath = Get-ScenesJsonPathForCollection -collectionName $collectionName
    if (-not $jsonPath -or -not (Test-Path $jsonPath)) {
        Log-Error "[Add] Scene collection '$collectionName' not found."
        return $false
    }
    
    Log-Info "[Add] Modifying: $jsonPath"
    
    $backup = $jsonPath + ".backup"
    Copy-Item $jsonPath $backup -Force
    Log-OK "[Add] Backup created: $backup"
    
    try {
        $jsonContent = Get-Content $jsonPath -Encoding UTF8 -Raw
        if ([string]::IsNullOrWhiteSpace($jsonContent)) {
            Log-Error "[Add] JSON file is empty."
            return $false
        }
        
        $json = $jsonContent | ConvertFrom-Json
        
        $isOldFormat = ($json.PSObject.Properties.Name -contains "name" -and $json.PSObject.Properties.Name -contains "sources")
        $hasScenes = ($json.PSObject.Properties.Name -contains "scenes")
        
        $template = $script:SceneTemplate | ConvertFrom-Json
        $templateSources = $template.sources
        
        $sourceNames = @("MPV-SW-Window", "MPV-SW-Audio")
        $sourcesToAdd = @()
        foreach ($src in $templateSources) {
            if ($sourceNames -contains $src.name) {
                $sourcesToAdd += $src
            }
        }
        
        if ($sourcesToAdd.Count -eq 0) {
            Log-Error "[Add] No sources found in template."
            return $false
        }
        
        if ($isOldFormat) {
            $currentSources = $json.sources
            $existingNames = @()
            foreach ($src in $currentSources) {
                $existingNames += $src.name
            }
            
            $sceneSource = $null
            foreach ($src in $currentSources) {
                if ($src.id -eq "scene") {
                    $sceneSource = $src
                    break
                }
            }
            
            if (-not $sceneSource) {
                Log-Error "[Add] No scene source found in this collection."
                return $false
            }
            
            if (-not $sceneSource.settings) {
                $sceneSource | Add-Member -MemberType NoteProperty -Name "settings" -Value @{} -Force
            }
            if (-not $sceneSource.settings.items) {
                $sceneSource.settings | Add-Member -MemberType NoteProperty -Name "items" -Value @() -Force
            }
            
            $nextId = $sceneSource.settings.items.Count
            if ($sceneSource.settings.id_counter) {
                $nextId = $sceneSource.settings.id_counter
            }
            
            $addedCount = 0
            foreach ($newSrc in $sourcesToAdd) {
                if ($existingNames -notcontains $newSrc.name) {
                    $newUuid = [guid]::NewGuid().ToString()
                    $newSrc.uuid = $newUuid
                    
                    $currentSources += $newSrc
                    $existingNames += $newSrc.name
                    
                    $newItem = [PSCustomObject]@{
                        name = $newSrc.name
                        source_uuid = $newUuid
                        visible = $true
                        locked = $false
                        rot = 0.0
                        align = 5
                        bounds_type = 0
                        bounds_align = 0
                        bounds_crop = $false
                        crop_left = 0
                        crop_top = 0
                        crop_right = 0
                        crop_bottom = 0
                        id = $nextId
                        group_item_backup = $false
                        pos = @{ x = 0.0; y = 0.0 }
                        scale = @{ x = 1.0; y = 1.0 }
                        bounds = @{ x = 0.0; y = 0.0 }
                        scale_filter = "disable"
                        blend_method = "default"
                        blend_type = "normal"
                        show_transition = @{ duration = 300 }
                        hide_transition = @{ duration = 300 }
                        private_settings = @{}
                    }
                    $sceneSource.settings.items += $newItem
                    $nextId++
                    
                    $addedCount++
                    Log-Info "[Add] Added source: $($newSrc.name) with UUID $newUuid"
                } else {
                    Log-Info "[Add] Source already exists: $($newSrc.name)"
                }
            }
            
            $sceneSource.settings.id_counter = $nextId
            $json.sources = $currentSources
            
            if (-not $json.current_scene) {
                $json.current_scene = $sceneSource.name
                $json.current_program_scene = $sceneSource.name
            }
            
        } elseif ($hasScenes) {
            if (-not $json.scenes -or $json.scenes.Count -eq 0) {
                Log-Error "[Add] No scenes found in JSON."
                return $false
            }
            
            $targetScene = $null
            if ($sceneName) {
                $targetScene = $json.scenes | Where-Object { $_.name -eq $sceneName } | Select-Object -First 1
            }
            if (-not $targetScene) {
                $targetScene = $json.scenes | Where-Object { $_.name -eq $json.current_scene } | Select-Object -First 1
            }
            if (-not $targetScene) {
                $targetScene = $json.scenes[0]
            }
            
            if (-not $targetScene.sources) {
                $targetScene | Add-Member -MemberType NoteProperty -Name "sources" -Value @() -Force
            }
            
            $existingNames = @()
            foreach ($src in $targetScene.sources) {
                $existingNames += $src.name
            }
            
            $addedCount = 0
            foreach ($newSrc in $sourcesToAdd) {
                if ($existingNames -notcontains $newSrc.name) {
                    $newUuid = [guid]::NewGuid().ToString()
                    $newSrc.uuid = $newUuid
                    
                    $targetScene.sources += $newSrc
                    $existingNames += $newSrc.name
                    $addedCount++
                    Log-Info "[Add] Added source: $($newSrc.name) with UUID $newUuid"
                } else {
                    Log-Info "[Add] Source already exists: $($newSrc.name)"
                }
            }
            
            $json.current_scene = $targetScene.name
            $json.current_program_scene = $targetScene.name
        } else {
            Log-Error "[Add] Unknown JSON format."
            return $false
        }
        
        if ($addedCount -eq 0) {
            Log-Info "[Add] No new sources to add."
        }
        
        $utf8 = New-Object System.Text.UTF8Encoding $false
        $stream = New-Object System.IO.StreamWriter($jsonPath, $false, $utf8)
        $jsonString = $json | ConvertTo-Json -Depth 10
        $stream.Write($jsonString)
        $stream.Close()
        Log-OK "[Add] JSON saved successfully."
        
        Log-OK ([string]::Format((T "LogSceneAdd"), $collectionName))
        return $true
    } catch {
        Log-Error "[Add] Error: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================
# BACKUP AND RESTORE OBS CONFIGURATION
# ============================================================
function Backup-OBSConfiguration {
    param([string]$obsRoot)
    $configPath = Get-OBSUserConfig
    if (-not $configPath) {
        Log-Error "[Backup] Could not find OBS config folder."
        return $false
    }
    
    $backupDir = Join-Path $script:ToolsDir "BKP_OBS"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Log-Info "[Backup] Created backup directory: $backupDir"
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupDir "obs_backup_$timestamp.zip"
    
    Log-Info (T "LogBackupStart")
    Log-Info "[Backup] Config path: $configPath"
    
    $filesToBackup = @()
    $globalIni = Join-Path $configPath "global.ini"
    $userIni = Join-Path $configPath "user.ini"
    if (Test-Path $globalIni) { 
        $filesToBackup += $globalIni
        Log-Info "[Backup] Adding: $globalIni"
    } else {
        Log-Warn "[Backup] global.ini not found, will not be backed up."
    }
    if (Test-Path $userIni) { 
        $filesToBackup += $userIni
        Log-Info "[Backup] Adding: $userIni"
    } else {
        Log-Warn "[Backup] user.ini not found, will not be backed up."
    }
    
    $scenesDir = Join-Path $configPath "basic\scenes"
    if (Test-Path $scenesDir) {
        $sceneFiles = Get-ChildItem -Path $scenesDir -Filter "*.json"
        if ($sceneFiles.Count -eq 0) {
            Log-Warn "[Backup] No .json files found in $scenesDir"
        } else {
            foreach ($file in $sceneFiles) {
                $filesToBackup += $file.FullName
                Log-Info "[Backup] Adding scene file: $($file.Name)"
            }
        }
    } else {
        Log-Warn "[Backup] Scenes directory not found: $scenesDir"
    }
    
    if ($filesToBackup.Count -eq 0) {
        Log-Error "[Backup] No files found to backup. Aborting."
        return $false
    }
    
    Log-Info "[Backup] Total files to backup: $($filesToBackup.Count)"
    
    try {
        $tempDir = Join-Path $env:TEMP "obs_backup_temp_$([guid]::NewGuid().ToString().Substring(0,8))"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        
        foreach ($file in $filesToBackup) {
            $relativePath = $file.Substring($configPath.Length + 1)
            $destFile = Join-Path $tempDir $relativePath
            $destDir = Split-Path -Parent $destFile
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $file -Destination $destFile -Force
        }
        
        Compress-Archive -Path "$tempDir\*" -DestinationPath $backupFile -CompressionLevel Optimal -Force
        
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
        
        if (Test-Path $backupFile) {
            $zipSize = (Get-Item $backupFile).Length
            Log-OK "[Backup] ZIP created: $backupFile (Size: $([math]::Round($zipSize/1KB, 2)) KB)"
            return $backupFile
        } else {
            Log-Error "[Backup] ZIP file not created."
            return $false
        }
    } catch {
        Log-Error ([string]::Format((T "LogBackupErr"), $_.Exception.Message))
        return $false
    }
}

function Restore-OBSConfiguration {
    param([string]$zipPath)
    $configPath = Get-OBSUserConfig
    if (-not $configPath) {
        Log-Error "[Restore] Could not find OBS config folder."
        return $false
    }
    
    if (-not (Test-Path $zipPath)) {
        Log-Error "[Restore] ZIP file not found: $zipPath"
        return $false
    }
    
    Log-Info ([string]::Format((T "LogRestoreStart"), $zipPath))
    Log-Info "[Restore] Config path: $configPath"
    Log-Info "[Restore] ZIP file size: $([math]::Round((Get-Item $zipPath).Length/1KB, 2)) KB"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $script:ToolsDir "BKP_OBS"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    $securityBackup = Join-Path $backupDir "pre_restore_backup_$timestamp.zip"
    
    $filesToBackup = @()
    $globalIni = Join-Path $configPath "global.ini"
    $userIni = Join-Path $configPath "user.ini"
    if (Test-Path $globalIni) { $filesToBackup += $globalIni }
    if (Test-Path $userIni) { $filesToBackup += $userIni }
    $scenesDir = Join-Path $configPath "basic\scenes"
    if (Test-Path $scenesDir) {
        Get-ChildItem -Path $scenesDir -Filter "*.json" | ForEach-Object {
            $filesToBackup += $_.FullName
        }
    }
    if ($filesToBackup.Count -gt 0) {
        try {
            $tempDir = Join-Path $env:TEMP "pre_restore_backup_temp_$([guid]::NewGuid().ToString().Substring(0,8))"
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            foreach ($file in $filesToBackup) {
                $relativePath = $file.Substring($configPath.Length + 1)
                $destFile = Join-Path $tempDir $relativePath
                $destDir = Split-Path -Parent $destFile
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
                Copy-Item -Path $file -Destination $destFile -Force
            }
            Compress-Archive -Path "$tempDir\*" -DestinationPath $securityBackup -CompressionLevel Optimal -Force
            if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
            Log-Info "[Restore] Security backup created: $securityBackup"
        } catch {
            Log-Warn "[Restore] Could not create security backup: $($_.Exception.Message)"
        }
    }
    
    $backupExistingDir = Join-Path $env:TEMP "obs_existing_backup_$([guid]::NewGuid().ToString().Substring(0,8))"
    New-Item -ItemType Directory -Path $backupExistingDir -Force | Out-Null
    
    $filesToMove = @()
    if (Test-Path $globalIni) { $filesToMove += $globalIni }
    if (Test-Path $userIni) { $filesToMove += $userIni }
    if (Test-Path $scenesDir) {
        Get-ChildItem -Path $scenesDir -Recurse -File | ForEach-Object {
            $filesToMove += $_.FullName
        }
    }
    foreach ($file in $filesToMove) {
        $rel = $file.Substring($configPath.Length + 1)
        $dest = Join-Path $backupExistingDir $rel
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Move-Item -Path $file -Destination $dest -Force -ErrorAction SilentlyContinue
        Log-Info "[Restore] Moved existing: $rel -> $dest"
    }
    
    try {
        Log-Info "[Restore] Extracting ZIP directly to $configPath..."
        Expand-Archive -Path $zipPath -DestinationPath $configPath -Force -ErrorAction Stop
        Log-OK "[Restore] ZIP extracted successfully."
    } catch {
        Log-Error "[Restore] Failed to extract ZIP: $($_.Exception.Message)"
        Log-Warn "[Restore] Attempting to restore from security backup: $securityBackup"
        if (Test-Path $securityBackup) {
            Expand-Archive -Path $securityBackup -DestinationPath $configPath -Force -ErrorAction SilentlyContinue
            Log-Info "[Restore] Restored from security backup."
        }
        return $false
    }
    
    $verifyGlobal = Join-Path $configPath "global.ini"
    $verifyUser = Join-Path $configPath "user.ini"
    $verifyScenes = Join-Path $configPath "basic\scenes"
    $allOk = $true
    if (Test-Path $verifyGlobal) { Log-OK "[Restore] Verified: global.ini exists" } else { Log-Error "[Restore] global.ini missing after restore!"; $allOk = $false }
    if (Test-Path $verifyUser) { Log-OK "[Restore] Verified: user.ini exists" } else { Log-Error "[Restore] user.ini missing after restore!"; $allOk = $false }
    if (Test-Path $verifyScenes) {
        $sceneCount = (Get-ChildItem -Path $verifyScenes -Filter "*.json").Count
        Log-OK "[Restore] Verified: $sceneCount scene file(s) in basic\scenes"
        if ($sceneCount -eq 0) { Log-Warn "[Restore] No scene files found in basic\scenes" }
    } else {
        Log-Error "[Restore] basic\scenes folder missing after restore!"
        $allOk = $false
    }
    
    if (Test-Path $backupExistingDir) { Remove-Item -Recurse -Force $backupExistingDir -ErrorAction SilentlyContinue }
    
    if ($allOk) {
        Log-OK (T "LogRestoreOK")
        return $true
    } else {
        Log-Warn "[Restore] Some files may not have been restored correctly. Check the logs."
        return $false
    }
}

# ============================================================
# PLUGIN FUNCTIONS (FIXED - uses DLL location to find root)
# ============================================================
function Get-GitHubRelease {
    param([string]$url)
    try {
        $headers = @{
            'User-Agent' = 'MPV-SW-Capture-StreamManager/1.0'
            'Accept' = 'application/vnd.github+json'
        }
        $token = $env:GITHUB_TOKEN
        if ($token) { $headers['Authorization'] = "Bearer $token" }
        return Invoke-RestMethod -Uri $url -Headers $headers -UseBasicParsing -TimeoutSec 15
    } catch {
        $errorMsg = $_.Exception.Message
        if ($errorMsg -match "429" -or $errorMsg -match "rate limit") {
            Log-Warn "GitHub API rate limit reached."
        } else {
            Log-Warn "GitHub API error: $errorMsg"
        }
        return $null
    }
}

function Download-File {
    param([string]$url, [string]$out, [string]$logMsg)
    Log-Info ($logMsg + " " + [System.IO.Path]::GetFileName($out))
    try {
        $ProgressPreference='SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
        $ProgressPreference='Continue'
        return $true
    } catch { Log-Error $_.Exception.Message; return $false }
}

function Install-WinCaptureAudio {
    param([string]$obsRoot)
    $dll = Join-Path $obsRoot "obs-plugins\64bit\win-capture-audio.dll"
    if (Test-Path $dll) {
        Log-OK (T "LogPluginFound")
        $script:lPluginStatus.ForeColor = $script:SUCCESS
        $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginFound")
        return $true
    }
    
    Log-Info (T "LogPluginDL")
    
    $repoOwner = "bozbez"
    $repoName = "win-capture-audio"
    $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases"
    $releasesPage = "https://github.com/$repoOwner/$repoName/releases"
    
    try {
        $headers = @{
            'User-Agent' = 'MPV-SW-Capture-StreamManager/1.0'
            'Accept' = 'application/vnd.github+json'
        }
        $token = $env:GITHUB_TOKEN
        if ($token) {
            $headers['Authorization'] = "Bearer $token"
            Log-Info "[Plugin] Using GITHUB_TOKEN from environment"
        }
        
        Log-Info "[Plugin] Fetching releases list from GitHub API..."
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -TimeoutSec 10
        
        if (-not $response -or $response.Count -eq 0) {
            Log-Error "[Plugin] No releases found."
            return $false
        }
        
        $latestRelease = $response[0]
        Log-Info "[Plugin] Latest release: $($latestRelease.name) (Pre-release: $($latestRelease.prerelease))"
        
        if (-not $latestRelease.assets) {
            Log-Error "[Plugin] No assets found in the latest release."
            return $false
        }
        
        $asset = $latestRelease.assets | Where-Object { $_.name -match '\.zip$' -and $_.name -match 'win-capture-audio' } | Select-Object -First 1
        if (-not $asset) {
            Log-Error "[Plugin] No .zip asset found in the latest release."
            Log-Info "[Plugin] Available assets: $($latestRelease.assets.name -join ', ')"
            return $false
        }
        
        $downloadUrl = $asset.browser_download_url
        Log-Info "[Plugin] Download URL: $downloadUrl"
        
        $tempDir = Join-Path $env:TEMP "win-capture-audio-install"
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $zipPath = Join-Path $tempDir $asset.name
        
        Log-Info "[Plugin] Downloading: $($asset.name) ($([math]::Round($asset.size/1MB, 2)) MB)"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -Headers $headers -TimeoutSec 30
        $ProgressPreference = 'Continue'
        
        if (-not (Test-Path $zipPath) -or (Get-Item $zipPath).Length -eq 0) {
            Log-Error "[Plugin] Downloaded file is empty or missing."
            return $false
        }
        Log-Info "[Plugin] Downloaded $((Get-Item $zipPath).Length) bytes"
        
        Log-Info (T "LogPluginExtract")
        $extractPath = Join-Path $tempDir "extracted"
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        
        try {
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force -ErrorAction Stop
        } catch {
            Log-Error "[Plugin] Failed to extract ZIP: $($_.Exception.Message)"
            return $false
        }
        
        # FIND THE DLL AND DETERMINE THE ROOT FOLDER
        Log-Info "[Plugin] Searching for win-capture-audio.dll in extracted files..."
        $foundDll = Get-ChildItem -Path $extractPath -Recurse -Filter "win-capture-audio.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if (-not $foundDll) {
            Log-Error "[Plugin] Could not find win-capture-audio.dll in the extracted ZIP."
            return $false
        }
        
        Log-Info "[Plugin] Found DLL at: $($foundDll.FullName)"
        
        $dllDir = $foundDll.Directory
        $rootExtract = $null
        
        $currentDir = $dllDir
        while ($currentDir -and $currentDir.FullName -ne $extractPath) {
            if (Test-Path (Join-Path $currentDir.FullName "obs-plugins")) {
                $rootExtract = $currentDir.FullName
                Log-Info "[Plugin] Found obs-plugins in parent folder: $rootExtract"
                break
            }
            $currentDir = $currentDir.Parent
        }
        
        if (-not $rootExtract) {
            $parent = $dllDir.Parent.Parent
            if ($parent -and $parent.Name -eq "obs-plugins") {
                $rootExtract = $parent.Parent.FullName
                Log-Info "[Plugin] Using parent of obs-plugins as root: $rootExtract"
            } else {
                $rootExtract = $extractPath
                Log-Info "[Plugin] Using extraction root: $rootExtract"
            }
        }
        
        $files = Get-ChildItem -Path $rootExtract -Recurse -File
        $copiedCount = 0
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($rootExtract.Length + 1)
            if ([string]::IsNullOrEmpty($relativePath)) { continue }
            $destFile = Join-Path $obsRoot $relativePath
            $destDir = Split-Path -Parent $destFile
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $file.FullName -Destination $destFile -Force -ErrorAction SilentlyContinue
            $copiedCount++
        }
        Log-Info "[Plugin] Copied $copiedCount files to OBS root"
        
        $finalDll = Join-Path $obsRoot "obs-plugins\64bit\win-capture-audio.dll"
        if (Test-Path $finalDll) {
            Log-OK (T "LogPluginOK")
            $script:lPluginStatus.ForeColor = $script:SUCCESS
            $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginOK")
            if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
            return $true
        } else {
            $foundDllInObs = Get-ChildItem -Path $obsRoot -Recurse -Filter "win-capture-audio.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($foundDllInObs) {
                Log-OK "[Plugin] Found DLL at alternative location: $($foundDllInObs.FullName)"
                Log-OK (T "LogPluginOK")
                $script:lPluginStatus.ForeColor = $script:SUCCESS
                $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginOK")
                if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
                return $true
            } else {
                Log-Error "[Plugin] Plugin DLL not found after extraction. Expected: $finalDll"
                return $false
            }
        }
        
    } catch {
        $errorMsg = $_.Exception.Message
        $statusCode = $null
        if ($_.Exception.Response) {
            try { 
                $statusCode = [int]$_.Exception.Response.StatusCode 
                Log-Info "[Plugin] HTTP Status Code: $statusCode"
            } catch {}
        }
        
        if ($errorMsg -match "429" -or $errorMsg -match "rate limit" -or $statusCode -eq 429) {
            Log-Error "[Plugin] GitHub API rate limit reached. Please wait a few minutes and try again."
        } elseif ($errorMsg -match "403" -or $statusCode -eq 403) {
            Log-Error "[Plugin] GitHub API access denied (403). A token may be required."
        } elseif ($errorMsg -match "404" -or $statusCode -eq 404) {
            Log-Error "[Plugin] Plugin not found on GitHub. Opening releases page for manual download..."
            try {
                Start-Process $releasesPage
                Log-Info "[Plugin] Opened: $releasesPage"
            } catch {
                Log-Warn "[Plugin] Could not open browser. Please visit: $releasesPage"
            }
            Log-Info "[Plugin] After manual installation, click 'Check Plugin' to verify."
        } elseif ($errorMsg -match "timeout") {
            Log-Error "[Plugin] Download timed out. Please check your internet connection."
        } else {
            Log-Error "[Plugin] Error: $errorMsg"
            if ($statusCode) { Log-Error "[Plugin] HTTP Status: $statusCode" }
        }
        
        $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginNotFound")
        $script:lPluginStatus.ForeColor = $script:ERROR_C
        return $false
    }
}

function Uninstall-WinCaptureAudio {
    param([string]$obsRoot)
    $dllPath = Join-Path $obsRoot "obs-plugins\64bit\win-capture-audio.dll"
    $pluginDir = Join-Path $obsRoot "obs-plugins\64bit"
    $dataDir = Join-Path $obsRoot "data\obs-plugins\win-capture-audio"
    
    $uninstalled = $false
    if (Test-Path $dllPath) {
        try {
            Remove-Item -Path $dllPath -Force -ErrorAction Stop
            Log-Info "[Uninstall] Removed DLL: $dllPath"
            $uninstalled = $true
        } catch {
            Log-Error "[Uninstall] Could not remove DLL: $($_.Exception.Message)"
        }
    }
    if (Test-Path $dataDir) {
        try {
            Remove-Item -Path $dataDir -Recurse -Force -ErrorAction Stop
            Log-Info "[Uninstall] Removed data folder: $dataDir"
            $uninstalled = $true
        } catch {
            Log-Error "[Uninstall] Could not remove data folder: $($_.Exception.Message)"
        }
    }
    $pluginFolder = Join-Path $pluginDir "win-capture-audio"
    if (Test-Path $pluginFolder) {
        try {
            Remove-Item -Path $pluginFolder -Recurse -Force -ErrorAction Stop
            Log-Info "[Uninstall] Removed plugin folder: $pluginFolder"
            $uninstalled = $true
        } catch {
            Log-Error "[Uninstall] Could not remove plugin folder: $($_.Exception.Message)"
        }
    }
    
    if ($uninstalled) {
        Log-OK (T "LogPluginUninstalled")
        $script:lPluginStatus.ForeColor = $script:ERROR_C
        $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginNotFound")
        return $true
    } else {
        Log-Warn "[Uninstall] No plugin files found to remove."
        return $false
    }
}

# ============================================================
# FORM CREATION (4 CARDS, adjusted heights)
# ============================================================
$formW = 1020
$formH = 820
$headerH = 68
$leftX = 20
$cardW = 480
$colGap = 16
$rightX = $leftX + $cardW + $colGap

$row1Y = 10
$row2Y = 300
$cTopH = 265
$cMidH = 400

$script:IconPath = Join-Path $script:RootDir "data\icon\streammsc.ico"
$form=New-Object System.Windows.Forms.Form
if (Test-Path $script:IconPath) {
    try {
        $form.Icon = New-Object System.Drawing.Icon($script:IconPath)
    } catch {}
}
$form.ShowInTaskbar = $true
$form.Text = T 'Title'
$form.ClientSize=[System.Drawing.Size]::new($formW,$formH)
$form.MinimumSize=$form.Size
$form.BackColor=$script:BG
$form.ForeColor=$script:TEXT
$form.FormBorderStyle='FixedSingle'
$form.MaximizeBox=$false
$form.StartPosition='CenterScreen'
$form.Font=$FontSub

# --- Header ---
$pHeader=New-Pnl 0 0 $formW $headerH $script:SURFACE
$lAppTitle  =New-Lbl "MPV-SW-Capture" 20 2 380 36 $FontTitle $script:ACCENT
$lAppSub    =New-Lbl (T "HeaderSub")  22 36 480 18 $FontSub $script:MUTED
$lHeaderNote=New-Lbl (T "HeaderNote") 600 38 380 18 $FontSmall $script:ACCENT3
$lLangLbl   =New-Lbl (T "LangLabel")  760 10 90 18 $FontSmall $script:MUTED
$btnEN=New-Object System.Windows.Forms.Button
$btnEN.Text="EN"; $btnEN.Location=[System.Drawing.Point]::new(860,6); $btnEN.Size=[System.Drawing.Size]::new(44,26); Style-LangBtn $btnEN $true
$btnES=New-Object System.Windows.Forms.Button
$btnES.Text="ES"; $btnES.Location=[System.Drawing.Point]::new(910,6); $btnES.Size=[System.Drawing.Size]::new(44,26); Style-LangBtn $btnES $false
$pHeader.Controls.AddRange(@($lAppTitle,$lAppSub,$lHeaderNote,$lLangLbl,$btnEN,$btnES))
$form.Controls.Add($pHeader)

$pMain=New-Pnl 0 $headerH $formW ($formH-$headerH) $script:BG
$form.Controls.Add($pMain)

# --- CARD 1: OBS INSTALLATION ---
$card1=New-CardXY $pMain $leftX $row1Y $cardW $cTopH "S1Title"
$script:lCard1Title = $card1.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | Select-Object -First 1

# Descripción
$lOBSDesc=New-Lbl (T "S1Desc") 14 28 ($cardW-28) 16 $FontSmall $script:MUTED
$card1.Controls.Add($lOBSDesc)

# ---- Choose OBS Mode (dentro de un Panel para agrupar) ----
$pnlMode = New-Pnl 14 44 360 18 $script:CARD
$lModeChoice=New-Lbl (T "S1ModeChoice") 0 2 160 18 $FontBold $script:MUTED
$pnlMode.Controls.Add($lModeChoice)

$rbModeInstalled=New-Object System.Windows.Forms.RadioButton
$rbModeInstalled.Text=(T "S1ModeInstalled")
$rbModeInstalled.Location=[System.Drawing.Point]::new(166, 1)
$rbModeInstalled.Size=[System.Drawing.Size]::new(90, 22)
$rbModeInstalled.Font=$FontSub
$rbModeInstalled.ForeColor=$script:TEXT
$rbModeInstalled.BackColor=[System.Drawing.Color]::Transparent
$rbModeInstalled.Checked = ($script:CurrentOBSMode -eq "Installed")
$pnlMode.Controls.Add($rbModeInstalled)

$rbModePortable=New-Object System.Windows.Forms.RadioButton
$rbModePortable.Text=(T "S1ModePortable")
$rbModePortable.Location=[System.Drawing.Point]::new(266, 1)
$rbModePortable.Size=[System.Drawing.Size]::new(90, 22)
$rbModePortable.Font=$FontSub
$rbModePortable.ForeColor=$script:TEXT
$rbModePortable.BackColor=[System.Drawing.Color]::Transparent
$rbModePortable.Checked = ($script:CurrentOBSMode -eq "Portable")
$pnlMode.Controls.Add($rbModePortable)

$card1.Controls.Add($pnlMode)

$script:rbModeInstalled = $rbModeInstalled
$script:rbModePortable = $rbModePortable
$script:lModeChoice = $lModeChoice

# Status
$lOBSStatus=New-Lbl "" 14 62 300 18 $FontBold $script:MUTED
$card1.Controls.Add($lOBSStatus); $script:lOBSStatus=$lOBSStatus

# OBS Path
$lOBSPathLabel=New-Lbl (T "S1PathLabel") 14 80 70 18 $FontBold $script:MUTED
$card1.Controls.Add($lOBSPathLabel)
$lOBSPath=New-Lbl "" 88 80 350 18 $FontSmall $script:TEXT
$card1.Controls.Add($lOBSPath); $script:lOBSPath=$lOBSPath

# Mode
$lOBSModeLabel=New-Lbl (T "S1ModeLabel") 14 98 50 18 $FontBold $script:MUTED
$card1.Controls.Add($lOBSModeLabel)
$lOBSMode=New-Lbl "" 68 98 100 18 $FontSmall $script:TEXT
$card1.Controls.Add($lOBSMode); $script:lOBSMode=$lOBSMode

# Botones: Detect, Browse, Open
$btnOBSDetect=New-Object System.Windows.Forms.Button
$btnOBSDetect.Text=T "S1DetectBtn"; $btnOBSDetect.Location=[System.Drawing.Point]::new(14, 118); $btnOBSDetect.Size=[System.Drawing.Size]::new(130,32); Style-Btn $btnOBSDetect $script:SURFACE $script:ACCENT; $btnOBSDetect.FlatAppearance.BorderSize=1; $btnOBSDetect.FlatAppearance.BorderColor=$script:ACCENT
$card1.Controls.Add($btnOBSDetect)

$btnOBSBrowse=New-Object System.Windows.Forms.Button
$btnOBSBrowse.Text=T "S1BrowseBtn"; $btnOBSBrowse.Location=[System.Drawing.Point]::new(152, 118); $btnOBSBrowse.Size=[System.Drawing.Size]::new(180,32); Style-Btn $btnOBSBrowse $script:SURFACE $script:ACCENT; $btnOBSBrowse.FlatAppearance.BorderSize=1; $btnOBSBrowse.FlatAppearance.BorderColor=$script:ACCENT
$card1.Controls.Add($btnOBSBrowse)

$btnOBSOpen=New-Object System.Windows.Forms.Button
$btnOBSOpen.Text=T "S1OpenBtn"; $btnOBSOpen.Location=[System.Drawing.Point]::new(340, 118); $btnOBSOpen.Size=[System.Drawing.Size]::new(110,32); Style-Btn $btnOBSOpen $script:SURFACE $script:ACCENT; $btnOBSOpen.FlatAppearance.BorderSize=1; $btnOBSOpen.FlatAppearance.BorderColor=$script:ACCENT; $btnOBSOpen.Enabled=$false
$card1.Controls.Add($btnOBSOpen)

# Download OBS Installer
$btnOBSDL=New-Object System.Windows.Forms.Button
$btnOBSDL.Text=T "S1DownloadBtn"; $btnOBSDL.Location=[System.Drawing.Point]::new(14, 158); $btnOBSDL.Size=[System.Drawing.Size]::new(416,32); Style-Btn $btnOBSDL $script:ACCENT3 $script:BG
$card1.Controls.Add($btnOBSDL)

# Download Portable OBS
$btnOBSDLPortable=New-Object System.Windows.Forms.Button
$btnOBSDLPortable.Text=T "S1DownloadPortableBtn"; $btnOBSDLPortable.Location=[System.Drawing.Point]::new(14, 196); $btnOBSDLPortable.Size=[System.Drawing.Size]::new(416,32); Style-Btn $btnOBSDLPortable $script:ACCENT4 $script:TEXT
$card1.Controls.Add($btnOBSDLPortable)

# Architecture radio buttons (x64, arm64) dentro de un Panel para agrupar
$pnlArch = New-Pnl 14 238 300 28 $script:CARD
$lArchLabel=New-Lbl (T "S1ArchLabel") 0 0 140 18 $FontBold $script:MUTED
$pnlArch.Controls.Add($lArchLabel)
$rbArchX64=New-Object System.Windows.Forms.RadioButton
$rbArchX64.Text="x64"
$rbArchX64.Location=[System.Drawing.Point]::new(146, -2)
$rbArchX64.Size=[System.Drawing.Size]::new(50, 22)
$rbArchX64.Font=$FontSub
$rbArchX64.ForeColor=$script:TEXT
$rbArchX64.BackColor=[System.Drawing.Color]::Transparent
$rbArchX64.Checked=$true
$pnlArch.Controls.Add($rbArchX64)

$rbArchArm64=New-Object System.Windows.Forms.RadioButton
$rbArchArm64.Text="arm64"
$rbArchArm64.Location=[System.Drawing.Point]::new(206, -2)
$rbArchArm64.Size=[System.Drawing.Size]::new(60, 22)
$rbArchArm64.Font=$FontSub
$rbArchArm64.ForeColor=$script:TEXT
$rbArchArm64.BackColor=[System.Drawing.Color]::Transparent
$pnlArch.Controls.Add($rbArchArm64)

$card1.Controls.Add($pnlArch)

# Guardar referencias para el cambio de idioma y eventos
$script:lOBSStatus = $lOBSStatus
$script:lOBSPathLabel = $lOBSPathLabel
$script:lOBSModeLabel = $lOBSModeLabel
$script:lArchLabel = $lArchLabel
$script:rbArchX64 = $rbArchX64
$script:rbArchArm64 = $rbArchArm64

# --- CARD 2: PLUGIN ---
$card2=New-CardXY $pMain $rightX $row1Y $cardW $cTopH "S2Title"
$script:lCard2Title = $card2.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | Select-Object -First 1

$lPluginDesc=New-Lbl (T "S2Desc") 14 28 ($cardW-28) 16 $FontSmall $script:MUTED
$card2.Controls.Add($lPluginDesc)
$lPluginStatus=New-Lbl "" 14 44 300 18 $FontBold $script:MUTED
$card2.Controls.Add($lPluginStatus); $script:lPluginStatus=$lPluginStatus

$btnPluginCheck=New-Object System.Windows.Forms.Button
$btnPluginCheck.Text=T "S2DetectBtn"; $btnPluginCheck.Location=[System.Drawing.Point]::new(14,65); $btnPluginCheck.Size=[System.Drawing.Size]::new(130,32); Style-Btn $btnPluginCheck $script:SURFACE $script:ACCENT; $btnPluginCheck.FlatAppearance.BorderSize=1; $btnPluginCheck.FlatAppearance.BorderColor=$script:ACCENT
$card2.Controls.Add($btnPluginCheck)

$btnPluginInstall=New-Object System.Windows.Forms.Button
$btnPluginInstall.Text=T "S2InstallBtn"; $btnPluginInstall.Location=[System.Drawing.Point]::new(152,65); $btnPluginInstall.Size=[System.Drawing.Size]::new(130,32); Style-Btn $btnPluginInstall $script:ACCENT $script:BG
$card2.Controls.Add($btnPluginInstall)

$btnPluginUninstall=New-Object System.Windows.Forms.Button
$btnPluginUninstall.Text=T "S2UninstallBtn"; $btnPluginUninstall.Location=[System.Drawing.Point]::new(290,65); $btnPluginUninstall.Size=[System.Drawing.Size]::new(140,32); Style-Btn $btnPluginUninstall $script:ERROR_C $script:TEXT
$card2.Controls.Add($btnPluginUninstall)

$btnPluginManual=New-Object System.Windows.Forms.Button
$btnPluginManual.Text=T "S2ManualBtn"; $btnPluginManual.Location=[System.Drawing.Point]::new(14,105); $btnPluginManual.Size=[System.Drawing.Size]::new(416,32); Style-Btn $btnPluginManual $script:ACCENT2 $script:BG
$card2.Controls.Add($btnPluginManual)

# --- OSD SECTION ---
$lOSDTitle=New-Lbl (T "S2OSDTitle") 14 158 ($cardW-28) 18 $FontBold $script:ACCENT
$card2.Controls.Add($lOSDTitle)
$lOSDDesc=New-Lbl (T "S2OSDDesc") 14 178 ($cardW-28) 16 $FontSmall $script:MUTED
$card2.Controls.Add($lOSDDesc)
$lOSDStatus=New-Lbl "" 14 198 300 18 $FontBold $script:MUTED
$card2.Controls.Add($lOSDStatus); $script:lOSDStatus=$lOSDStatus

$btnOSDCheck=New-Object System.Windows.Forms.Button
$btnOSDCheck.Text=T "S2OSDCheckBtn"; $btnOSDCheck.Location=[System.Drawing.Point]::new(14,222); $btnOSDCheck.Size=[System.Drawing.Size]::new(130,32); Style-Btn $btnOSDCheck $script:SURFACE $script:ACCENT; $btnOSDCheck.FlatAppearance.BorderSize=1; $btnOSDCheck.FlatAppearance.BorderColor=$script:ACCENT
$card2.Controls.Add($btnOSDCheck)

$btnOSDActivate=New-Object System.Windows.Forms.Button
$btnOSDActivate.Text=T "S2OSDActivateBtn"; $btnOSDActivate.Location=[System.Drawing.Point]::new(152,222); $btnOSDActivate.Size=[System.Drawing.Size]::new(130,32); Style-Btn $btnOSDActivate $script:ACCENT $script:BG
$card2.Controls.Add($btnOSDActivate)

$btnOSDDeactivate=New-Object System.Windows.Forms.Button
$btnOSDDeactivate.Text=T "S2OSDDeactivateBtn"; $btnOSDDeactivate.Location=[System.Drawing.Point]::new(290,222); $btnOSDDeactivate.Size=[System.Drawing.Size]::new(140,32); Style-Btn $btnOSDDeactivate $script:ERROR_C $script:TEXT
$card2.Controls.Add($btnOSDDeactivate)

$script:lOSDTitle = $lOSDTitle
$script:lOSDDesc = $lOSDDesc
$script:lOSDStatus = $lOSDStatus
$script:btnOSDCheck = $btnOSDCheck
$script:btnOSDActivate = $btnOSDActivate
$script:btnOSDDeactivate = $btnOSDDeactivate

# --- CARD 3: OBS SCENE CONFIGURATION ---
$card3 = New-Pnl $leftX $row2Y $cardW $cMidH $script:CARD
$pMain.Controls.Add($card3)
$bar = New-Pnl 0 0 $cardW 3 $script:ACCENT
$card3.Controls.Add($bar)
$lS3Title = New-Lbl (T "S3Title") 14 8 ($cardW-20) 22 $FontSectionTitle $script:ACCENT
$card3.Controls.Add($lS3Title)

$lSceneDesc=New-Lbl (T "S3Desc") 14 30 ($cardW-28) 16 $FontSub $script:TEXT
$card3.Controls.Add($lSceneDesc)

$lSceneNote=New-Lbl (T "S3Note") 14 50 ($cardW-28) 16 $FontBold $script:NOTE_C
$card3.Controls.Add($lSceneNote)

$lSceneNote2=New-Lbl (T "S3Note2") 14 68 ($cardW-28) 14 $FontBold $script:NOTE_C
$card3.Controls.Add($lSceneNote2)

$lSceneStatus=New-Lbl "" 14 92 300 18 $FontBold $script:MUTED
$card3.Controls.Add($lSceneStatus); $script:lSceneStatus=$lSceneStatus

$lSceneLbl=New-Lbl (T "S3SceneLbl") 14 116 160 18 $FontBold $script:MUTED
$card3.Controls.Add($lSceneLbl)
$cbScenes=New-Object System.Windows.Forms.ComboBox
$cbScenes.Location=[System.Drawing.Point]::new(180,114); $cbScenes.Size=[System.Drawing.Size]::new(270,28); $cbScenes.DropDownStyle='DropDownList'; $cbScenes.Font=$FontSub; $cbScenes.BackColor=$script:CARD; $cbScenes.ForeColor=$script:TEXT; $cbScenes.FlatStyle='Flat'
$card3.Controls.Add($cbScenes)

$btnSceneNew=New-Object System.Windows.Forms.Button
$btnSceneNew.Text=T "S3BtnNew"; $btnSceneNew.Location=[System.Drawing.Point]::new(14,150); $btnSceneNew.Size=[System.Drawing.Size]::new(436,32); Style-Btn $btnSceneNew $script:ACCENT $script:BG
$card3.Controls.Add($btnSceneNew)

$btnSceneAdd=New-Object System.Windows.Forms.Button
$btnSceneAdd.Text=T "S3BtnAdd"; $btnSceneAdd.Location=[System.Drawing.Point]::new(14,188); $btnSceneAdd.Size=[System.Drawing.Size]::new(436,32); Style-Btn $btnSceneAdd $script:ACCENT2 $script:BG
$card3.Controls.Add($btnSceneAdd)

$btnBackup=New-Object System.Windows.Forms.Button
$btnBackup.Text=T "S3BtnBackup"; $btnBackup.Location=[System.Drawing.Point]::new(14,250); $btnBackup.Size=[System.Drawing.Size]::new(436,32); Style-Btn $btnBackup $script:ACCENT4 $script:TEXT
$card3.Controls.Add($btnBackup)

$btnRestore=New-Object System.Windows.Forms.Button
$btnRestore.Text=T "S3BtnRestore"; $btnRestore.Location=[System.Drawing.Point]::new(14,288); $btnRestore.Size=[System.Drawing.Size]::new(436,32); Style-Btn $btnRestore $script:SUCCESS $script:BG
$card3.Controls.Add($btnRestore)

$script:lS3Title = $lS3Title
$script:lSceneDesc = $lSceneDesc
$script:lSceneNote = $lSceneNote
$script:lSceneNote2 = $lSceneNote2
$script:lArchLabel = $lArchLabel
$script:rbArchX64 = $rbArchX64
$script:rbArchArm64 = $rbArchArm64
$script:lOBSStatus = $lOBSStatus
$script:lOBSPathLabel = $lOBSPathLabel
$script:lOBSModeLabel = $lOBSModeLabel

# --- CARD 4: ACTIONS ---
$card4=New-CardXY $pMain $rightX $row2Y $cardW $cMidH "ActionsTitle"
$script:lCard4Title = $card4.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | Select-Object -First 1

$logBox=New-Object System.Windows.Forms.RichTextBox
$logBox.Location=[System.Drawing.Point]::new(14,34); $logBox.Size=[System.Drawing.Size]::new($cardW-28,320)
$logBox.BackColor=[System.Drawing.Color]::FromArgb(22,20,15); $logBox.ForeColor=$script:TEXT; $logBox.Font=$FontMono
$logBox.BorderStyle='None'; $logBox.ReadOnly=$true; $logBox.ScrollBars='Vertical'
$card4.Controls.Add($logBox); $script:LogBox=$logBox

$lStatus=New-Object System.Windows.Forms.Label
$lStatus.Location=[System.Drawing.Point]::new(14,362); $lStatus.Size=[System.Drawing.Size]::new($cardW-28,36)
$lStatus.Font=$FontSub; $lStatus.ForeColor=$script:MUTED
$lStatus.BackColor=[System.Drawing.Color]::Transparent
$lStatus.Text=T "StatusReady"; $lStatus.AutoSize=$false
$card4.Controls.Add($lStatus); $script:lStatus=$lStatus

# ============================================================
# EVENT HANDLERS
# ============================================================

$script:SelectedCollection = $null

function Update-OBSDisplay {
    param([bool]$Silent = $false)
    
    $root = $script:OBSRoot
    if ($root -and (Test-Path (Join-Path $root "bin\64bit\obs64.exe"))) {
        $statusText = T "S1StatusFound"
        $script:lOBSStatus.Text = (T "S1Status") + " " + $statusText
        $script:lOBSStatus.ForeColor = $script:SUCCESS
        $script:lOBSPath.Text = $root
        $script:lOBSPath.ForeColor = $script:TEXT
        $btnOBSOpen.Enabled = $true
        
        if ($script:CurrentOBSMode -eq "Portable") {
            $script:lOBSMode.Text = "Portable"
            $script:lOBSMode.ForeColor = $script:ACCENT3
        } else {
            $script:lOBSMode.Text = "Installed"
            $script:lOBSMode.ForeColor = $script:SUCCESS
        }
        
        $allCollections = Get-AllSceneCollections
        if ($allCollections.Count -gt 0) {
            $cbScenes.Items.Clear()
            foreach ($coll in $allCollections) {
                [void]$cbScenes.Items.Add($coll)
            }
            
            if ($script:SelectedCollection -and $allCollections -contains $script:SelectedCollection) {
                $cbScenes.SelectedItem = $script:SelectedCollection
            } else {
                $activeCollection = Get-ActiveSceneCollection
                if ($activeCollection -and $allCollections -contains $activeCollection) {
                    $cbScenes.SelectedItem = $activeCollection
                } else {
                    $cbScenes.SelectedIndex = 0
                }
            }
            if (-not $Silent) { Log-Info "[Scene] Loaded $($allCollections.Count) scene collection(s)." }
        } else {
            $cbScenes.Items.Clear()
            if (-not $Silent) { Log-Warn (T "LogSceneNoCollections") }
        }
        
        $dll = Join-Path $root "obs-plugins\64bit\win-capture-audio.dll"
        if (Test-Path $dll) {
            $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginFound")
            $script:lPluginStatus.ForeColor = $script:SUCCESS
        } else {
            $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginNotFound")
            $script:lPluginStatus.ForeColor = $script:ERROR_C
        }
        Save-OBSConfig $root
    } else {
        $statusText = T "S1StatusNotFound"
        $script:lOBSStatus.Text = (T "S1Status") + " " + $statusText
        $script:lOBSStatus.ForeColor = $script:ERROR_C
        $script:lOBSPath.Text = "Not found"
        $script:lOBSPath.ForeColor = $script:ERROR_C
        if ($script:CurrentOBSMode -eq "Portable") {
            $script:lOBSMode.Text = "Portable"
            $script:lOBSMode.ForeColor = $script:ACCENT3
        } else {
            $script:lOBSMode.Text = "Installed"
            $script:lOBSMode.ForeColor = $script:SUCCESS
        }
        $btnOBSOpen.Enabled = $false
        $cbScenes.Items.Clear()
        $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginNotFound")
        $script:lPluginStatus.ForeColor = $script:ERROR_C
    }
    Update-OSDDisplay
}
# Detect OBS usando el modo actual
$btnOBSDetect.Add_Click({
    Set-Status (T "StatusChecking") $script:NOTE_C
    $root = Find-OBSRoot -Mode $script:CurrentOBSMode
    if ($root) {
        $script:OBSRoot = $root
        if ($script:CurrentOBSMode -eq "Installed") {
            $script:OBSRootInstalled = $root
        } else {
            $script:OBSRootPortable = $root
        }
        Save-OBSConfig $root
    } else {
        if ($script:CurrentOBSMode -eq "Installed") {
            $script:OBSRootInstalled = $null
        } else {
            $script:OBSRootPortable = $null
        }
        $script:OBSRoot = $null
        Save-OBSConfig $null
    }
    Update-OBSDisplay
    Set-Status (T "StatusReady") $script:MUTED
})

# Browse OBS
$btnOBSBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select obs64.exe (to locate OBS root folder)"
    $dialog.Filter = "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    $dialog.FilterIndex = 1
    $dialog.Multiselect = $false
    $dialog.CheckFileExists = $true
    $dialog.CheckPathExists = $true
    $dialog.InitialDirectory = if ($script:OBSRoot -and (Test-Path $script:OBSRoot)) { $script:OBSRoot } else { $env:ProgramFiles }
    
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedExe = $dialog.FileName
        $root = Split-Path (Split-Path (Split-Path $selectedExe -Parent) -Parent) -Parent
        if (Test-Path (Join-Path $root "bin\64bit\obs64.exe")) {
            $script:OBSRoot = $root
            if ($script:CurrentOBSMode -eq "Installed") {
                $script:OBSRootInstalled = $root
            } else {
                $script:OBSRootPortable = $root
            }
            Log-OK ("[OBS] Manual selection: " + $root)
            Save-OBSConfig $root
            Update-OBSDisplay
            Set-Status (T "StatusReady") $script:MUTED
        } else {
            Log-Error "[OBS] Invalid folder. 'bin\64bit\obs64.exe' not found."
        }
    }
})

# Download OBS Installer
$btnOBSDL.Add_Click({
    Set-Status (T "StatusDownload") $script:NOTE_C
    Log-Info (T "LogDL")
    try {
        $rel = Get-GitHubRelease "https://api.github.com/repos/obsproject/obs-studio/releases/latest"
        if (-not $rel) { Log-Error "Could not fetch OBS latest release."; return }
        $asset = $rel.assets | Where-Object { $_.name -match 'OBS-Studio-.*\.exe$' } | Select-Object -First 1
        if (-not $asset) { Log-Error "No installer asset found."; return }
        $savePath = Join-Path $env:USERPROFILE "Downloads\$($asset.name)"
        if (Download-File $asset.browser_download_url $savePath (T "LogDL")) {
            Log-OK ([string]::Format((T "LogDLOK"), $savePath))
            $btnOBSOpen.Enabled = $true
            $btnOBSOpen.Tag = $savePath
        }
    } catch { Log-Error $_.Exception.Message }
    Set-Status (T "StatusReady") $script:MUTED
})

# Download Portable OBS
$btnOBSDLPortable.Add_Click({
    $arch = if ($rbArchX64.Checked) { "x64" } else { "arm64" }
    $archDisplay = if ($arch -eq "x64") { "x86_64" } else { "arm64" }
    Log-Info "[OBS] Architecture selected: $archDisplay"
    
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select folder where OBS Portable will be installed (ZIP extraction)"
    $folderDialog.ShowNewFolderButton = $true
    if ($script:OBSRoot -and (Test-Path $script:OBSRoot)) {
        $folderDialog.SelectedPath = $script:OBSRoot
    } else {
        $folderDialog.SelectedPath = $env:UserProfile
    }
    
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $destFolder = $folderDialog.SelectedPath
        Log-Info "[OBS] Installing Portable OBS ($arch) to: $destFolder"
        Set-Status (T "StatusDownload") $script:NOTE_C
        
        try {
            $rel = Get-GitHubRelease "https://api.github.com/repos/obsproject/obs-studio/releases/latest"
            if (-not $rel) { Log-Error "Could not fetch OBS latest release."; return }
            
            if ($arch -eq "x64") {
                $asset = $rel.assets | Where-Object { 
                    $_.name -match '\.zip$' -and 
                    $_.name -match 'obs-studio' -and 
                    $_.name -match 'windows' -and 
                    $_.name -match 'x64' -and 
                    $_.name -notmatch 'PDB' 
                } | Select-Object -First 1
                if (-not $asset) {
                    $asset = $rel.assets | Where-Object { 
                        $_.name -match '\.zip$' -and 
                        $_.name -match 'x64' -and 
                        $_.name -notmatch 'PDB' 
                    } | Select-Object -First 1
                }
            } else {
                $asset = $rel.assets | Where-Object { 
                    $_.name -match '\.zip$' -and 
                    $_.name -match 'arm64' -and 
                    $_.name -notmatch 'PDB' 
                } | Select-Object -First 1
                if (-not $asset) {
                    $asset = $rel.assets | Where-Object { 
                        $_.name -match '\.zip$' -and 
                        $_.name -match 'arm64' 
                    } | Select-Object -First 1
                }
            }
            
            if (-not $asset) {
                Log-Error "[OBS] No .zip asset found for architecture $arch. Please download manually from: https://github.com/obsproject/obs-studio/releases"
                Set-Status (T "LogDLCancel") $script:ERROR_C
                return
            }
            
            Log-Info "[OBS] Selected asset: $($asset.name)"
            
            $zipPath = Join-Path $env:TEMP "obs_portable.zip"
            Log-Info "[OBS] Downloading: $($asset.name) ($([math]::Round($asset.size/1MB, 2)) MB)"
            
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -TimeoutSec 60
            $ProgressPreference = 'Continue'
            
            if (-not (Test-Path $zipPath) -or (Get-Item $zipPath).Length -eq 0) {
                Log-Error "[OBS] Downloaded file is empty or missing."
                Set-Status (T "LogDLCancel") $script:ERROR_C
                return
            }
            Log-OK "[OBS] Downloaded $((Get-Item $zipPath).Length) bytes"
            
            Log-Info "[OBS] Extracting ZIP to $destFolder"
            Expand-Archive -Path $zipPath -DestinationPath $destFolder -Force -ErrorAction Stop
            
            $extractedDirs = Get-ChildItem -Path $destFolder -Directory | Where-Object { $_.Name -match 'obs-studio' }
            if ($extractedDirs.Count -gt 0) {
                $extractedDir = $extractedDirs[0]
                Log-Info "[OBS] Found extracted folder: $($extractedDir.Name)"
                Get-ChildItem -Path $extractedDir.FullName -Recurse | Move-Item -Destination $destFolder -Force -ErrorAction SilentlyContinue
                Remove-Item $extractedDir.FullName -Force -ErrorAction SilentlyContinue
            }
            
            $portableFile = Join-Path $destFolder "portable_mode"
            New-Item -ItemType File -Path $portableFile -Force | Out-Null
            Log-Info "[OBS] Created portable_mode file at: $portableFile"
            
            $configDir = Join-Path $destFolder "config"
            if (-not (Test-Path $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
                Log-Info "[OBS] Created config directory: $configDir"
            }
            
            $obsExe = Join-Path $destFolder "bin\64bit\obs64.exe"
            if (Test-Path $obsExe) {
                $root = $destFolder
                $script:OBSRoot = $root
                $script:OBSRootPortable = $root
                $script:CurrentOBSMode = "Portable"
                $rbModePortable.Checked = $true
                Save-OBSConfig $root
                Log-OK "[OBS] Portable OBS ($arch) installed successfully to: $destFolder"
                Update-OBSDisplay
                Set-Status (T "StatusDone") $script:SUCCESS
            } else {
                Log-Warn "[OBS] Portable OBS installed but obs64.exe not found at expected location: $obsExe"
                $foundExe = Get-ChildItem -Path $destFolder -Recurse -Filter "obs64.exe" | Select-Object -First 1
                if ($foundExe) {
                    $root = Split-Path (Split-Path $foundExe.FullName -Parent) -Parent
                    $script:OBSRoot = $root
                    $script:OBSRootPortable = $root
                    $script:CurrentOBSMode = "Portable"
                    $rbModePortable.Checked = $true
                    Save-OBSConfig $root
                    Log-OK "[OBS] Found obs64.exe at: $foundExe.FullName"
                    Update-OBSDisplay
                    Set-Status (T "StatusDone") $script:SUCCESS
                } else {
                    Log-Warn "[OBS] Could not locate obs64.exe. You may need to locate it manually."
                    Set-Status (T "LogDLCancel") $script:ERROR_C
                }
            }
            
            if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
        } catch {
            Log-Error "[OBS] Error during portable installation: $($_.Exception.Message)"
            Set-Status (T "LogDLCancel") $script:ERROR_C
        }
    } else {
        Log-Info "[OBS] Portable installation cancelled."
    }
})

# Open OBS
$btnOBSOpen.Add_Click({
    $path = $btnOBSOpen.Tag
    if ($path -and (Test-Path $path)) {
        try { Start-Process $path } catch { Log-Error "Cannot open installer." }
        return
    }
    if ($script:OBSRoot -and (Test-Path (Join-Path $script:OBSRoot "bin\64bit\obs64.exe"))) {
        $obsExe = Join-Path $script:OBSRoot "bin\64bit\obs64.exe"
        $isPortable = ($script:CurrentOBSMode -eq "Portable")
        $args = if ($isPortable) { "--portable" } else { "" }
        $workingDir = Join-Path $script:OBSRoot "bin\64bit"
        
        $shortcutPath = Join-Path $env:TEMP "obs_shortcut.lnk"
        if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force -ErrorAction SilentlyContinue }
        try {
            $ws = New-Object -ComObject WScript.Shell
            $sc = $ws.CreateShortcut($shortcutPath)
            $sc.TargetPath = $obsExe
            $sc.Arguments = $args
            $sc.WorkingDirectory = $workingDir
            $sc.Save()
            Start-Process $shortcutPath
            Log-Info "[OBS] Opened OBS via shortcut: $shortcutPath (WorkingDir: $workingDir)"
        } catch {
            Log-Error "[OBS] Failed to create shortcut: $($_.Exception.Message)"
            try {
                Start-Process -FilePath $obsExe -WorkingDirectory $workingDir -ArgumentList $args
                Log-Info "[OBS] Opened OBS directly (fallback) with WorkingDir: $workingDir"
            } catch {
                Log-Error "[OBS] Could not open OBS: $($_.Exception.Message)"
                [System.Windows.Forms.MessageBox]::Show(
                    "Could not open OBS automatically.`n`nPlease open OBS manually from: $obsExe",
                    "MPV-SW-Capture Stream Manager",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            }
        }
    } else {
        Log-Warn "[OBS] No OBS executable found. Please download and install OBS first."
        [System.Windows.Forms.MessageBox]::Show(
            "No OBS executable found.`n`nPlease click 'Download OBS Installer' to download it, or locate OBS using 'Browse OBS Folder'.",
            "MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

# Check Plugin
$btnPluginCheck.Add_Click({
    if (-not $script:OBSRoot) { Log-Warn "[Plugin] No OBS root detected."; return }
    $dll = Join-Path $script:OBSRoot "obs-plugins\64bit\win-capture-audio.dll"
    if (Test-Path $dll) {
        Log-OK (T "LogPluginFound")
        $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginFound")
        $script:lPluginStatus.ForeColor = $script:SUCCESS
    } else {
        Log-Warn (T "LogPluginNotFound")
        $script:lPluginStatus.Text = (T "S2Status") + " " + (T "LogPluginNotFound")
        $script:lPluginStatus.ForeColor = $script:ERROR_C
    }
})

# Install Plugin
$btnPluginInstall.Add_Click({
    if (-not $script:OBSRoot) {
        Log-Error "[Plugin] OBS not found. Please detect OBS first."
        return
    }

    # Verificar permisos solo si OBS está en Program Files
    if ($script:OBSRoot -match "Program Files" -or $script:OBSRoot -match "ProgramFiles") {
        if (-not (Test-AdminRights)) {
            $msg = [string]::Format((T "MsgAdminRequired"), [Environment]::NewLine)
            [System.Windows.Forms.MessageBox]::Show(
                $msg,
                (T "MsgAdminTitle"),
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            Log-Warn "[Plugin] Installation aborted: Administrator rights required."
            return
        }
    }

    Set-Status (T "StatusDownload") $script:NOTE_C
    if (Install-WinCaptureAudio $script:OBSRoot) {
        Set-Status (T "StatusDone") $script:SUCCESS
        Update-OBSDisplay
    } else {
        Set-Status (T "LogPluginErr") $script:ERROR_C
    }
})

# Uninstall Plugin
$btnPluginUninstall.Add_Click({
    if (-not $script:OBSRoot) {
        Log-Error "[Uninstall] OBS not found. Please detect OBS first."
        return
    }

    # Verificar permisos solo si OBS está en Program Files
    if ($script:OBSRoot -match "Program Files" -or $script:OBSRoot -match "ProgramFiles") {
        if (-not (Test-AdminRights)) {
            $msg = [string]::Format((T "MsgAdminRequired"), [Environment]::NewLine)
            [System.Windows.Forms.MessageBox]::Show(
                $msg,
                (T "MsgAdminTitle"),
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            Log-Warn "[Plugin] Uninstallation aborted: Administrator rights required."
            return
        }
    }

    $result = [System.Windows.Forms.MessageBox]::Show((T "ConfirmUninstallPlugin"), (T "ConfirmTitle"), [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($result -eq [System.Windows.Forms.DialogResult]::No) { return }
    
    Set-Status (T "StatusChecking") $script:NOTE_C
    if (Uninstall-WinCaptureAudio $script:OBSRoot) {
        Set-Status (T "StatusDone") $script:SUCCESS
        Update-OBSDisplay
    } else {
        Set-Status (T "LogPluginErr") $script:ERROR_C
    }
})

# Manual Download
$btnPluginManual.Add_Click({
    $url = "https://github.com/bozbez/win-capture-audio/releases"
    Log-Info "[Plugin] Opening manual download page: $url"
    try {
        Start-Process $url
    } catch {
        Log-Error "[Plugin] Could not open browser: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Could not open browser automatically.`n`nPlease visit: $url",
            "MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

# --- OSD Event Handlers ---
$btnOSDCheck.Add_Click({
    Log-Info (T "S2OSDLogCheck")
    $status = Get-OSDStatus
    if ($status.enabled) {
        Log-OK (T "S2OSDLogEnabled")
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDEnabled")
        $script:lOSDStatus.ForeColor = $script:SUCCESS
    } else {
        Log-OK (T "S2OSDLogDisabled")
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDDisabled")
        $script:lOSDStatus.ForeColor = $script:ERROR_C
    }
})

$btnOSDActivate.Add_Click({
    try {
        Set-OSDStatus 0
        Log-OK (T "S2OSDLogActivated")
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDEnabled")
        $script:lOSDStatus.ForeColor = $script:SUCCESS
    } catch {
        Log-Error ([string]::Format((T "S2OSDLogError"), $_.Exception.Message))
    }
})

$btnOSDDeactivate.Add_Click({
    try {
        Set-OSDStatus 1000
        Log-OK (T "S2OSDLogDeactivated")
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDDisabled")
        $script:lOSDStatus.ForeColor = $script:ERROR_C
    } catch {
        Log-Error ([string]::Format((T "S2OSDLogError"), $_.Exception.Message))
    }
})

# ---- Eventos para los RadioButtons de modo OBS ----
$rbModeInstalled.Add_CheckedChanged({
    if ($rbModeInstalled.Checked) {
        $script:CurrentOBSMode = "Installed"
        $root = $script:OBSRootInstalled
        if ($root -and (Test-Path (Join-Path $root "bin\64bit\obs64.exe"))) {
            $script:OBSRoot = $root
        } else {
            $root = Find-OBSRoot -Mode "Installed"
            $script:OBSRoot = $root
            $script:OBSRootInstalled = $root
            Save-OBSConfig $root
        }
        Update-OBSDisplay
        Set-Status (T "StatusReady") $script:MUTED
    }
})

$rbModePortable.Add_CheckedChanged({
    if ($rbModePortable.Checked) {
        $script:CurrentOBSMode = "Portable"
        $root = $script:OBSRootPortable
        if ($root -and (Test-Path (Join-Path $root "bin\64bit\obs64.exe"))) {
            $script:OBSRoot = $root
        } else {
            $root = Find-OBSRoot -Mode "Portable"
            $script:OBSRoot = $root
            $script:OBSRootPortable = $root
            Save-OBSConfig $root
        }
        Update-OBSDisplay
        Set-Status (T "StatusReady") $script:MUTED
    }
})

# Install New Scene Collection
$btnSceneNew.Add_Click({
    if (-not $script:OBSRoot) { 
        Log-Error "[New] OBS not found. Please detect OBS first."
        [System.Windows.Forms.MessageBox]::Show(
            "OBS not found. Please click 'Detect Installed OBS' or browse for the OBS folder.",
            "Error - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return 
    }
    if (Get-Process -Name "obs64" -ErrorAction SilentlyContinue) {
        $result = [System.Windows.Forms.MessageBox]::Show((T "ConfirmCloseOBS"), (T "ConfirmTitle"), [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
    }
    Set-Status (T "StatusChecking") $script:NOTE_C
    Log-Info "[New] Installing new scene collection..."
    $script:lSceneStatus.Text = "[New] Installing..."
    $script:lSceneStatus.ForeColor = $script:NOTE_C
    
    if (Install-NewSceneCollection) {
        Log-OK "[New] Done!"
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "StatusDone")
        $script:lSceneStatus.ForeColor = $script:SUCCESS
        Set-Status (T "StatusDone") $script:SUCCESS
        Update-OBSDisplay
    } else {
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "LogSceneErr")
        $script:lSceneStatus.ForeColor = $script:ERROR_C
        Set-Status (T "LogSceneErr") $script:ERROR_C
    }
})

# Add Sources to Selected Collection
$btnSceneAdd.Add_Click({
    if (-not $script:OBSRoot) { 
        Log-Error "[Add] OBS not found. Please detect OBS first."
        [System.Windows.Forms.MessageBox]::Show(
            "OBS not found. Please click 'Detect Installed OBS' or browse for the OBS folder.",
            "Error - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return 
    }
    if (Get-Process -Name "obs64" -ErrorAction SilentlyContinue) {
        $result = [System.Windows.Forms.MessageBox]::Show((T "ConfirmCloseOBS"), (T "ConfirmTitle"), [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
    }
    
    $selectedCollection = $cbScenes.SelectedItem
    if (-not $selectedCollection) {
        Log-Error "[Add] No scene collection selected."
        return
    }
    
    Set-Status (T "StatusChecking") $script:NOTE_C
    Log-Info "[Add] Adding sources to collection: $selectedCollection"
    $script:lSceneStatus.Text = "[Add] Adding sources..."
    $script:lSceneStatus.ForeColor = $script:NOTE_C
    
    if (Add-SourcesToCollection -collectionName $selectedCollection) {
        Log-OK "[Add] Done!"
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "StatusDone")
        $script:lSceneStatus.ForeColor = $script:SUCCESS
        Set-Status (T "StatusDone") $script:SUCCESS
        $script:SelectedCollection = $selectedCollection
        Update-OBSDisplay
        [System.Windows.Forms.MessageBox]::Show(
            "Sources added successfully to collection '$selectedCollection'!`n`n- MPV-SW-Window (Window Capture, DXGI)`n- MPV-SW-Audio (win-capture-audio, ffplay.exe)`n`nYour existing scene configuration was preserved.",
            "Success - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } else {
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "LogSceneErr")
        $script:lSceneStatus.ForeColor = $script:ERROR_C
        Set-Status (T "LogSceneErr") $script:ERROR_C
    }
})

# BACKUP
$btnBackup.Add_Click({
    if (-not $script:OBSRoot) {
        Log-Error "[Backup] OBS not found. Please detect OBS first."
        [System.Windows.Forms.MessageBox]::Show(
            "OBS not found. Please click 'Detect Installed OBS' or browse for the OBS folder.",
            "Error - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }
    if (Get-Process -Name "obs64" -ErrorAction SilentlyContinue) {
        $result = [System.Windows.Forms.MessageBox]::Show((T "ConfirmCloseOBS"), (T "ConfirmTitle"), [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
    }
    
    Set-Status (T "StatusChecking") $script:NOTE_C
    $script:lSceneStatus.Text = "[Backup] Creating backup..."
    $script:lSceneStatus.ForeColor = $script:NOTE_C
    
    $backupFile = Backup-OBSConfiguration -obsRoot $script:OBSRoot
    if ($backupFile) {
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "StatusDone")
        $script:lSceneStatus.ForeColor = $script:SUCCESS
        Set-Status (T "StatusDone") $script:SUCCESS
        [System.Windows.Forms.MessageBox]::Show(
            "Backup created successfully!`n`nFile: $backupFile`n`nYou can restore it using the 'RESTORE' button.",
            "Success - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } else {
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "LogBackupErr")
        $script:lSceneStatus.ForeColor = $script:ERROR_C
        Set-Status (T "LogBackupErr") $script:ERROR_C
    }
})

# RESTORE
$btnRestore.Add_Click({
    if (-not $script:OBSRoot) {
        Log-Error "[Restore] OBS not found. Please detect OBS first."
        [System.Windows.Forms.MessageBox]::Show(
            "OBS not found. Please click 'Detect Installed OBS' or browse for the OBS folder.",
            "Error - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }
    if (Get-Process -Name "obs64" -ErrorAction SilentlyContinue) {
        $result = [System.Windows.Forms.MessageBox]::Show((T "ConfirmCloseOBS"), (T "ConfirmTitle"), [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
    }
    
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select OBS Backup ZIP file"
    $dialog.Filter = "ZIP files (*.zip)|*.zip|All files (*.*)|*.*"
    $dialog.FilterIndex = 1
    $dialog.Multiselect = $false
    $dialog.CheckFileExists = $true
    $dialog.CheckPathExists = $true
    
    $backupDir = Join-Path $script:ToolsDir "BKP_OBS"
    if (Test-Path $backupDir) {
        $dialog.InitialDirectory = $backupDir
    } else {
        $dialog.InitialDirectory = $script:ToolsDir
    }
    
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $zipPath = $dialog.FileName
    
    $result = [System.Windows.Forms.MessageBox]::Show((T "ConfirmRestore"), (T "ConfirmTitle"), [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($result -eq [System.Windows.Forms.DialogResult]::No) { return }
    
    Set-Status (T "StatusChecking") $script:NOTE_C
    $script:lSceneStatus.Text = "[Restore] Restoring..."
    $script:lSceneStatus.ForeColor = $script:NOTE_C
    
    if (Restore-OBSConfiguration -zipPath $zipPath) {
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "StatusDone")
        $script:lSceneStatus.ForeColor = $script:SUCCESS
        Set-Status (T "StatusDone") $script:SUCCESS
        Update-OBSDisplay
        [System.Windows.Forms.MessageBox]::Show(
            "OBS configuration restored successfully!`n`nPlease restart OBS to see the changes.",
            "Success - MPV-SW-Capture Stream Manager",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } else {
        $script:lSceneStatus.Text = (T "S3Status") + " " + (T "LogRestoreErr")
        $script:lSceneStatus.ForeColor = $script:ERROR_C
        Set-Status (T "LogRestoreErr") $script:ERROR_C
    }
})

# ============================================================
# LANGUAGE SWITCH
# ============================================================
function Apply-Lang([string]$lang) {
    $script:CurrentLang = $lang
    Style-LangBtn $btnEN ($lang -eq "EN")
    Style-LangBtn $btnES ($lang -eq "ES")

    $form.Text = T 'Title'
    $lAppSub.Text = T "HeaderSub"
    $lHeaderNote.Text = T "HeaderNote"
    $lLangLbl.Text = T "LangLabel"
    $lOBSDesc.Text = T "S1Desc"
    $lPluginDesc.Text = T "S2Desc"
    
    $script:lCard1Title.Text = T "S1Title"
    $script:lCard2Title.Text = T "S2Title"
    $script:lS3Title.Text = T "S3Title"
    $script:lCard4Title.Text = T "ActionsTitle"
    
    $script:lSceneDesc.Text = T "S3Desc"
    $script:lSceneNote.Text = T "S3Note"
    $script:lSceneNote2.Text = T "S3Note2"
    
    $script:lOBSPathLabel.Text = T "S1PathLabel"
    $script:lOBSModeLabel.Text = T "S1ModeLabel"
    $script:lArchLabel.Text = T "S1ArchLabel"
    $script:lModeChoice.Text = T "S1ModeChoice"
    $script:rbModeInstalled.Text = T "S1ModeInstalled"
    $script:rbModePortable.Text = T "S1ModePortable"
    
    $btnOBSDetect.Text = T "S1DetectBtn"
    $btnOBSDL.Text = T "S1DownloadBtn"
    $btnOBSDLPortable.Text = T "S1DownloadPortableBtn"
    $btnOBSOpen.Text = T "S1OpenBtn"
    $btnOBSBrowse.Text = T "S1BrowseBtn"
    
    $btnPluginCheck.Text = T "S2DetectBtn"
    $btnPluginInstall.Text = T "S2InstallBtn"
    $btnPluginUninstall.Text = T "S2UninstallBtn"
    $btnPluginManual.Text = T "S2ManualBtn"
    
    $script:lOSDTitle.Text = T "S2OSDTitle"
    $script:lOSDDesc.Text = T "S2OSDDesc"
    $script:btnOSDCheck.Text = T "S2OSDCheckBtn"
    $script:btnOSDActivate.Text = T "S2OSDActivateBtn"
    $script:btnOSDDeactivate.Text = T "S2OSDDeactivateBtn"
    
    $status = Get-OSDStatus
    if ($status.enabled) {
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDEnabled")
        $script:lOSDStatus.ForeColor = $script:SUCCESS
    } else {
        $script:lOSDStatus.Text = (T "S2OSDStatus") + " " + (T "S2OSDDisabled")
        $script:lOSDStatus.ForeColor = $script:ERROR_C
    }
    
    $lSceneLbl.Text = T "S3SceneLbl"
    $btnSceneNew.Text = T "S3BtnNew"
    $btnSceneAdd.Text = T "S3BtnAdd"
    $btnBackup.Text = T "S3BtnBackup"
    $btnRestore.Text = T "S3BtnRestore"
    
    $lStatus.Text = T "StatusReady"
    
    Update-OBSDisplay -Silent $true
    
    $langName = if ($lang -eq 'EN') { 'English' } else { 'Spanish' }
    Log-Info "[Language] Language changed to $langName"
    
    $form.Refresh()
}

$btnEN.Add_Click({
    Apply-Lang "EN"
    Save-GUILanguage "EN"
})

$btnES.Add_Click({
    Apply-Lang "ES"
    Save-GUILanguage "ES"
})

# ============================================================
# INIT
# ============================================================
# Cargar idioma guardado
$savedLang = Load-GUILanguage
Apply-Lang $savedLang
Log-Info (T "LogReady")

$savedRoot = Load-OBSConfig
if ($savedRoot) {
    $script:OBSRoot = $savedRoot
    Log-Info ("[OBS] Loaded saved path: " + $savedRoot)
} else {
    $script:OBSRoot = Find-OBSRoot -Mode $script:CurrentOBSMode
}
if ($script:CurrentOBSMode -eq "Installed") {
    $rbModeInstalled.Checked = $true
} else {
    $rbModePortable.Checked = $true
}
Update-OBSDisplay
[System.Windows.Forms.Application]::Run($form)