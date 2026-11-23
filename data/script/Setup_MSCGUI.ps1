# Setup_MSCGUI.ps1 - By TyRaS-SW
# GUI Setup for MPV-SW-Capture
# EN/ES GUI - PowerShell 5+ (Windows 10/11)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# ============================================================
#  APPMODELID
# ============================================================
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class TaskbarAppId {
    [DllImport("shell32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);
}
"@

$script:AppUserModelID = "TyRaS.MPVSWCapture.Setup"
try {
    [TaskbarAppId]::SetCurrentProcessExplicitAppUserModelID($script:AppUserModelID) | Out-Null
} catch {}

# ============================================================
#  NATIVE SHORTCUT CREATOR (C#)
# ============================================================
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class ShortcutCreator
{
    [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
    private class ShellLink { }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("000214F9-0000-0000-C000-000000000046")]
    private interface IShellLink
    {
        void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cchMaxPath, out IntPtr pfd, int fFlags);
        void GetIDList(out IntPtr ppidl);
        void SetIDList(IntPtr pidl);
        void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cchMaxName);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cchMaxPath);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cchMaxPath);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        void GetHotkey(out short pwHotkey);
        void SetHotkey(short wHotkey);
        void GetShowCmd(out int piShowCmd);
        void SetShowCmd(int iShowCmd);
        void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cchIconPath, out int piIcon);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, int dwReserved);
        void Resolve(IntPtr hwnd, int fFlags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("0000010B-0000-0000-C000-000000000046")]
    private interface IPersistFile
    {
        void GetClassID(out Guid pClassID);
        void IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, int dwMode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, bool fRemember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
    }

    public static void CreateShortcut(string lnkPath, string targetPath, string workingDir, string iconPath, int iconIndex = 0)
    {
        Type shellLinkType = Type.GetTypeFromCLSID(new Guid("00021401-0000-0000-C000-000000000046"));
        object shellLink = Activator.CreateInstance(shellLinkType);
        IShellLink link = (IShellLink)shellLink;
        IPersistFile persist = (IPersistFile)shellLink;

        link.SetPath(targetPath);
        link.SetWorkingDirectory(workingDir);
        if (!string.IsNullOrEmpty(iconPath))
            link.SetIconLocation(iconPath, iconIndex);

        persist.Save(lnkPath, true);
        Marshal.ReleaseComObject(shellLink);
    }
}
"@ -ReferencedAssemblies "System.Runtime.InteropServices"

# ============================================================
#  ROOT DIRECTORY DETECTION
# ============================================================
function Get-RootDir {
    $scriptDir = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { (Get-Location).Path }
    if ((Split-Path $scriptDir -Leaf) -eq 'script' -and (Split-Path (Split-Path $scriptDir -Parent) -Leaf) -eq 'data') {
        return Split-Path -Parent (Split-Path -Parent $scriptDir)
    }
    return $scriptDir
}
$script:RootDir = Get-RootDir

# ============================================================
#  PATHS
# ============================================================
$script:LangFilePath    = Join-Path $script:RootDir "data\script\GUILang.dat"
$script:AudioModePath   = Join-Path $script:RootDir "data\menu\audio_mode.txt"
$script:HoverVolumePath = Join-Path $script:RootDir "data\menu\hover_volume.txt"

# ============================================================
#  LANGUAGE PERSISTENCE
# ============================================================
function Load-GUILanguage {
    if (Test-Path $script:LangFilePath) {
        try {
            $content = (Get-Content $script:LangFilePath -Encoding UTF8 -Raw).Trim().ToUpper()
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

# ============================================================
#  AUDIO MODE (data\menu\audio_mode.txt)
# ============================================================
function Get-AudioModeSetting {
    if (-not (Test-Path $script:AudioModePath)) { return "plugin" }
    try {
        $content = (Get-Content $script:AudioModePath -Encoding UTF8 -Raw).Trim().ToLower()
        if ($content -eq "ffplay") { return "ffplay" }
        return "plugin"
    } catch { return "plugin" }
}

function Set-AudioModeSetting([string]$mode) {
    $dir = Split-Path -Parent $script:AudioModePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $value = if ($mode -eq "ffplay") { "ffplay" } else { "plugin" }
    [System.IO.File]::WriteAllText($script:AudioModePath, $value, [System.Text.UTF8Encoding]::new($false))
}

# ============================================================
#  HOVER VOLUME (data\menu\hover_volume.txt)
# ============================================================
function Get-HoverVolumeSetting {
    if (-not (Test-Path $script:HoverVolumePath)) { return "no" }
    try {
        $content = (Get-Content $script:HoverVolumePath -Encoding UTF8 -Raw).Trim().ToLower()
        if ($content -eq "yes") { return "yes" }
        return "no"
    } catch { return "no" }
}

function Set-HoverVolumeSetting([string]$value) {
    $dir = Split-Path -Parent $script:HoverVolumePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $v = if ($value -eq "yes") { "yes" } else { "no" }
    [System.IO.File]::WriteAllText($script:HoverVolumePath, $v, [System.Text.UTF8Encoding]::new($false))
}

# ============================================================
#  MENU LANGUAGE (data\lang\OSDLang.dat + language_list.dat)
# ============================================================
function Get-MenuLanguage {
    $OSDLangFile = Join-Path $script:RootDir "data/lang/OSDLang.dat"
    if (Test-Path $OSDLangFile) {
        try {
            $content = [System.IO.File]::ReadAllText($OSDLangFile, [System.Text.Encoding]::UTF8).Trim().ToLower()
            if ($content -ne "") { return $content }
        } catch {}
    }
    return "en"
}

function Set-MenuLanguage([string]$lang) {
    $OSDLangFile = Join-Path $script:RootDir "data/lang/OSDLang.dat"
    $dir = Split-Path -Parent $OSDLangFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [System.IO.File]::WriteAllText($OSDLangFile, $lang, [System.Text.Encoding]::UTF8)
}

function Get-AvailableMenuLanguages {
    $listFile = Join-Path $script:RootDir "data/lang/language_list.dat"
    $fallback = @("en", "es")
    if (-not (Test-Path $listFile)) { return $fallback }
    try {
        $lines  = [System.IO.File]::ReadAllLines($listFile, [System.Text.Encoding]::UTF8)
        $parsed = @()
        foreach ($line in $lines) {
            $clean = $line.Trim().ToLower()
            if ($clean -ne "" -and -not $clean.StartsWith("#")) {
                if ($parsed -notcontains $clean) { $parsed += $clean }
            }
        }
        if ($parsed.Count -gt 0) { return $parsed }
    } catch {}
    return $fallback
}

function Select-MenuLanguageCombo([string]$lang) {
    if (-not $cbMenuLang) { return }
    $lang = ("" + $lang).ToLower()
    for ($i = 0; $i -lt $cbMenuLang.Items.Count; $i++) {
        if ($cbMenuLang.Items[$i].ToString().ToLower() -eq $lang) {
            $cbMenuLang.SelectedIndex = $i
            return
        }
    }
    if ($cbMenuLang.Items.Count -gt 0 -and $cbMenuLang.SelectedIndex -lt 0) {
        $cbMenuLang.SelectedIndex = 0
    }
}

# ============================================================
#  FORM ICON
# ============================================================
function Get-AppIcon {
    try {
        $iconPath = Join-Path $script:RootDir 'data\icon\setupmsc.ico'
        if (Test-Path -LiteralPath $iconPath) {
            return New-Object System.Drawing.Icon($iconPath)
        }
    } catch {}
    try {
        if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
            return [System.Drawing.Icon]::ExtractAssociatedIcon($PSCommandPath)
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
#  COLORS & FONTS
# ============================================================
$script:BG      = [System.Drawing.Color]::FromArgb(18,  18,  22)
$script:SURFACE = [System.Drawing.Color]::FromArgb(28,  28,  35)
$script:CARD    = [System.Drawing.Color]::FromArgb(38,  38,  48)
$script:ACCENT  = [System.Drawing.Color]::FromArgb(99,  179, 237)
$script:ACCENT2 = [System.Drawing.Color]::FromArgb(72,  219, 155)
$script:ACCENT3 = [System.Drawing.Color]::FromArgb(241, 166, 48)
$script:TEXT    = [System.Drawing.Color]::FromArgb(220, 220, 230)
$script:MUTED   = [System.Drawing.Color]::FromArgb(130, 130, 150)
$script:SUCCESS = [System.Drawing.Color]::FromArgb(72,  199, 116)
$script:ERROR_C = [System.Drawing.Color]::FromArgb(255, 100, 100)
$script:NOTE_C  = [System.Drawing.Color]::FromArgb(220, 200, 130)

$FontTitle        = New-Object System.Drawing.Font("Segoe UI", 18,   [System.Drawing.FontStyle]::Bold)
$FontSub          = New-Object System.Drawing.Font("Segoe UI",  9,   [System.Drawing.FontStyle]::Regular)
$FontBold         = New-Object System.Drawing.Font("Segoe UI",  9,   [System.Drawing.FontStyle]::Bold)
$FontBtn          = New-Object System.Drawing.Font("Segoe UI", 10,   [System.Drawing.FontStyle]::Bold)
$FontSmall        = New-Object System.Drawing.Font("Segoe UI",  8,   [System.Drawing.FontStyle]::Regular)
$FontNote         = New-Object System.Drawing.Font("Segoe UI",  9,   [System.Drawing.FontStyle]::Regular)
$FontSectionTitle = New-Object System.Drawing.Font("Segoe UI",  9,   [System.Drawing.FontStyle]::Bold)
$FontLangBtn      = New-Object System.Drawing.Font("Segoe UI", 11,   [System.Drawing.FontStyle]::Bold)
$FontSmallBold    = New-Object System.Drawing.Font("Segoe UI",  8,   [System.Drawing.FontStyle]::Bold)
$FontHeaderNote   = New-Object System.Drawing.Font("Segoe UI", 8.5,  [System.Drawing.FontStyle]::Regular)

# ============================================================
#  LANGUAGE STRINGS (EN / ES)
# ============================================================
$script:Lang = @{}
$script:Lang["EN"] = @{
    Title       = "MPV-SW-Capture - Setup"
    HeaderSub   = "Initial Setup  -  Configure your Capture Card and preferences."
    HeaderNote  = "You can use the MENU button below, without needing to use the rest of options."
    LangLabel   = "GUI Language:"
    ActionsTitle= "ACTIONS"

    S1Title     = "CHOOSE YOUR CAPTURE CARD DEVICE AUDIO AND VIDEO"
    S1VidLbl    = "Video device"
    S1AudLbl    = "Audio device"
    S1ScanBtn   = "Scan Devices"
    S1Scanning  = "Scanning..."
    S1Found     = "{0} video,  {1} audio device(s) found"
    S1NoDevices = "No devices found. Is ffplay in PATH?"

    S2Title     = "SELECT DATE FORMAT FOR FILE NAMES IN SCREENSHOTS AND RECORDS"
    S2Opt1      = "Japan / Korea  (yyyy-MM-dd)"
    S2Opt2      = "Latin America / Europe  (dd-MM-yyyy)"
    S2Opt3      = "USA / Canada  (MM-dd-yyyy)"

    S3Title     = "CHOOSE IF YOU WANT TO AUTO START SPECIAL SHADER ON MPV-SW-CAPTURE"
    S3No        = "NO - Start MPV without Special Shader (Capture Card default)"
    S3Sharpen   = "Sharpen - Start MPV with Sharpen shader"
    S3AA        = "Anti-Aliasing - Start MPV with AA shader"
    S3Note      = "Note: You can choose NOT to start with a Special Shader, or YES to use one of the 2 available recommended Special Shaders: Sharpen or Anti-Aliasing. These Shaders consume very few resources, so you are free to choose whether to use them or not."

    S4Title     = "CHANGE DEFAULT RECORD VIDEO TIME"
    S4Note      = "Note: You need around 7-10 GB of disk space to record 30 seconds. If you increase to 1 minute, you need twice the disk space. This is temporary space required to successfully create the video, or it will fail. The temporary files auto-delete after creating the compressed video."
    S4Opt1      = "30 seconds - 7-10 GB disk space (Default)"
    S4Opt2      = "60 seconds - 14-20 GB disk space"
    S4Opt3      = "90 seconds - 21-30 GB disk space"
    S4Opt4      = "120 seconds - 28-40 GB disk space"
    S4AudioTitle= "CHANGE WASAPI AUDIO OPTIONS"

    S5Title     = "OTHER OPTIONS FOR MPV-SW-Capture"
    S5Shorcut   = "CREATE DESKTOP AND LOCAL SHORTCUTS"
    S5IccTitle  = "AUTOSTART WITH YOUR ICC PROFILE"
    S5OsdTitle  = "AUTOSTART HIDE OSD MESSAGES (Streamer Mode)"
    S5BorderTitle = "AUTOSTART WINDOW BORDER+TITLE BAR"
    S5AutoCheckTitle = "AUTO-CHECK FOR UPDATES ON STARTUP"
    S5AudioModeTitle = "AUTOSTART WITH THE FOLLOWING AUDIO OUTPUT"
    S5HoverVolumeTitle = "AUTOSTART WITH HOVER VOLUME SIDEBAR"
    S5VideoFormatTitle = "INPUT VIDEO FORMAT"
    S5PeriodTitle = "WASAPI PERIOD MODE"
    S5BufferTitle = "AUDIO BUFFER SIZE (LATENCY VS STABILITY)"
    S5ZeroFillTitle = "UNDERRUN BEHAVIOR"
    S5BufOpt1 = "12 ms (Max Low Latency)"
    S5BufOpt2 = "20 ms"
    S5BufOpt3 = "25 ms (Recommended)"
    S5BufOpt4 = "30 ms"
    S5BufOpt5 = "50 ms"
    S5BufOpt6 = "100 ms (Max Stability)"
    S5ZeroPop = "Pop (Reset)"
    S5ZeroSilence = "Silence (Smooth)"
    S5No        = "No"
    S5Yes       = "Yes"
    S5BorderOnly = "Only border"
    S5BorderBoth = "Border+T.Bar"

    StatusReady = "Ready. Scan devices then click Apply Setup."
    StatusDefaultsLoaded = "Defaults loaded. Click Apply Setup to save."
    ApplyBtn    = "Apply Setup"
    BtnDefaultOpts = "Default Options"
    ErrSelect   = "Select video and audio devices first!"
    DoneMsg     = "Setup applied successfully!`n`nIf shortcut creation was enabled, shortcuts for MPV-SW-Capture were also created on the Desktop and in the root folder."
    DoneTitle   = "MPV-SW-Capture Setup"
    DoneStatus  = "Setup complete! All files updated."
    ErrStatus   = "Error: {0}"

    FfplayFound    = "ffplay.exe: Found!"
    FfplayNotFound = "ffplay.exe: NOT Found!"
    MenuFound      = "menu.conf: Found!"
    ApplyLangBtn   = "Apply Language"
    MenuToLanguage = "Menu language: {0}!"
}

$script:Lang["ES"] = @{
    Title       = "MPV-SW-Capture - Configuracion"
    HeaderSub   = "Configuracion Inicial  -  Configura tu Tarjeta de Captura y preferencias."
    HeaderNote  = "Puedes usar el boton MENU de abajo sin necesidad de usar el resto de opciones."
    LangLabel   = "Idioma del GUI:"
    ActionsTitle= "ACCIONES"

    S1Title     = "ELIGE TU DISPOSITIVO DE CAPTURA DE AUDIO Y VIDEO"
    S1VidLbl    = "Dispositivo de video"
    S1AudLbl    = "Dispositivo de audio"
    S1ScanBtn   = "Buscar Dispositivos"
    S1Scanning  = "Buscando..."
    S1Found     = "{0} video,  {1} dispositivo(s) de audio encontrado(s)"
    S1NoDevices = "No se encontraron dispositivos. Esta ffplay en el PATH?"

    S2Title     = "SELECCIONA EL FORMATO DE FECHA PARA CAPTURAS Y GRABACIONES"
    S2Opt1      = "Japon / Corea  (yyyy-MM-dd)"
    S2Opt2      = "Latinoamerica / Europa  (dd-MM-yyyy)"
    S2Opt3      = "EE.UU. / Canada  (MM-dd-yyyy)"

    S3Title     = "ELIGE SI QUIERES INICIAR AUTOMATICAMENTE EL SHADER ESPECIAL EN MPV-SW-CAPTURE"
    S3No        = "NO - Iniciar MPV sin Shader Especial (por defecto de la tarjeta de captura)"
    S3Sharpen   = "Sharpen (Nitidez) - Iniciar MPV con shader Sharpen"
    S3AA        = "Anti-Aliasing - Iniciar MPV con shader AA"
    S3Note      = "Nota: Puedes elegir NO iniciar con un Shader Especial, o SI utilizar uno de los 2 Shaders disponibles recomendados: Nitidez (Sharpen) o Anti-Aliasing. Estos Shaders consumen muy pocos recursos, por lo que puedes elegir libremente si usarlos o no."

    S4Title     = "CAMBIAR EL TIEMPO DE GRABACION DE VIDEO"
    S4Note      = "Nota: Necesitas alrededor de 7-10 GB de espacio en disco para grabar 30 segundos. Si aumentas a 1 minuto, necesitas el doble. Este espacio temporal es requerido para crear el video correctamente, o fallara. Los archivos temporales se auto-eliminan tras comprimir el video."
    S4Opt1      = "30 segundos - 7-10 GB de espacio (Por defecto)"
    S4Opt2      = "60 segundos - 14-20 GB de espacio"
    S4Opt3      = "90 segundos - 21-30 GB de espacio"
    S4Opt4      = "120 segundos - 28-40 GB de espacio"
    S4AudioTitle= "CAMBIAR OPCIONES DE AUDIO WASAPI"

    S5Title     = "OTRAS OPCIONES PARA MPV-SW-Capture"
    S5Shorcut   = "CREAR ACCESOS DIRECTOS EN EL ESCRITORIO Y LOCAL"
    S5IccTitle  = "INICIO AUTOMATICO CON TU PERFIL ICC"
    S5OsdTitle  = "OCULTAR MENSAJES OSD AL INICIO (Modo Streamer)"
    S5BorderTitle = "BORDE VENTANA+BARRA DE TITULO AL INICIO"
    S5AutoCheckTitle = "VERIFICAR ACTUALIZACIONES AL INICIO"
    S5AudioModeTitle = "INICIO AUTOMATICO CON ESTA SALIDA DE AUDIO"
    S5HoverVolumeTitle = "INICIO AUTOMATICO CON BARRA DE VOLUMEN FLOTANTE"
    S5VideoFormatTitle = "FORMATO DE VIDEO DE ENTRADA"
    S5PeriodTitle = "MODO DE PERIODO WASAPI"
    S5BufferTitle = "TAMANO BUFFER DE AUDIO (LATENCIA VS ESTABILIDAD)"
    S5ZeroFillTitle = "COMPORTAMIENTO UNDERRUN"
    S5BufOpt1 = "12 ms (Latencia Minima)"
    S5BufOpt2 = "20 ms"
    S5BufOpt3 = "25 ms (Recomendado)"
    S5BufOpt4 = "30 ms"
    S5BufOpt5 = "50 ms"
    S5BufOpt6 = "100 ms (Max. Estabilidad)"
    S5ZeroPop = "Pop (Reinicio)"
    S5ZeroSilence = "Silencio (Suave)"
    S5No        = "No"
    S5Yes       = "Si"
    S5BorderOnly = "Solo borde"
    S5BorderBoth = "Borde+Barra T."

    StatusReady = "Listo. Busca dispositivos y luego haz clic en Aplicar."
    StatusDefaultsLoaded = "Valores por defecto cargados. Haz clic en Aplicar."
    ApplyBtn    = "Aplicar"
    BtnDefaultOpts = "Predeterminados"
    ErrSelect   = "Selecciona los dispositivos de video y audio primero!"
    DoneMsg     = "Configuracion aplicada correctamente!`n`nSi la opcion de acceso directo estaba activada, tambien se crearon accesos directos de MPV-SW-Capture en el Escritorio y en la carpeta raiz."
    DoneTitle   = "Configuracion MPV-SW-Capture"
    DoneStatus  = "Configuracion completa! Todos los archivos actualizados."
    ErrStatus   = "Error: {0}"

    FfplayFound    = "ffplay.exe: Encontrado!"
    FfplayNotFound = "ffplay.exe: NO Encontrado!"
    MenuFound      = "menu.conf: Encontrado!"
    ApplyLangBtn   = "Aplicar Idioma"
    MenuToLanguage = "Idioma del menu: {0}!"
}

$script:CurrentLang = "EN"
$script:LastVideoCount = $null
$script:LastAudioCount = $null
$script:LastScanState  = "none"
$script:LastStatusState = "ready"
$script:LastErrorText   = ""
$script:LastScanError   = ""
$script:LastMenuLangSet = ""

function T { param([string]$key) return $script:Lang[$script:CurrentLang][$key] }

# ============================================================
#  UI HELPERS
# ============================================================
function New-Lbl([string]$text,[int]$x,[int]$y,[int]$w,[int]$h,
                 [System.Drawing.Font]$font,[System.Drawing.Color]$color) {
    if (-not $font)     { $font  = $FontSub }
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

function New-CB([int]$x,[int]$y,[int]$w) {
    $c = New-Object System.Windows.Forms.ComboBox
    $c.Location=[System.Drawing.Point]::new($x,$y)
    $c.Size=[System.Drawing.Size]::new($w,28)
    $c.DropDownStyle='DropDownList'
    $c.Font=$FontSub
    $c.BackColor=$script:CARD
    $c.ForeColor=$script:TEXT
    $c.FlatStyle='Flat'
    return $c
}

function New-RB([string]$text,[int]$x,[int]$y,[int]$w) {
    $r = New-Object System.Windows.Forms.RadioButton
    $r.Text=$text
    $r.Location=[System.Drawing.Point]::new($x,$y)
    $r.Size=[System.Drawing.Size]::new($w,22)
    $r.Font=$FontSub
    $r.ForeColor=$script:TEXT
    $r.BackColor=[System.Drawing.Color]::Transparent
    return $r
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
    if ($bg.IsEmpty) { $bg = $script:ACCENT }
    if ($fg.IsEmpty) { $fg = $script:BG }
    $btn.BackColor=$bg
    $btn.ForeColor=$fg
    $btn.Font=$FontBtn
    $btn.FlatStyle='Flat'
    $btn.FlatAppearance.BorderSize=0
    $btn.Cursor=[System.Windows.Forms.Cursors]::Hand
}

function Style-LangBtn([System.Windows.Forms.Button]$btn,[bool]$active) {
    $btn.Font=$FontLangBtn
    $btn.FlatStyle='Flat'
    $btn.FlatAppearance.BorderSize=1
    $btn.Cursor=[System.Windows.Forms.Cursors]::Hand
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

function New-CardXY(
    [System.Windows.Forms.Control]$parent,
    [int]$x,[int]$y,[int]$w,[int]$h,
    [string]$titleKey,[string]$noteKey,[bool]$paleYellow
) {
    $card = New-Pnl $x $y $w $h $script:CARD
    $bar  = New-Pnl 0 0 $w 3 $script:ACCENT
    $card.Controls.Add($bar)

    $lT = New-Lbl (T $titleKey) 14 8 ($w-20) 22 $FontSectionTitle $script:ACCENT
    $card.Controls.Add($lT)

    if ($noteKey) {
        $nc = if($paleYellow){$script:NOTE_C}else{$script:MUTED}
        $lN = New-Object System.Windows.Forms.Label
        $lN.Text = (T $noteKey)
        $lN.Location = [System.Drawing.Point]::new(14,34)
        $lN.Size = [System.Drawing.Size]::new(($w-28),0)
        $lN.Font = $FontNote
        $lN.ForeColor = $nc
        $lN.BackColor = [System.Drawing.Color]::Transparent
        $lN.AutoSize = $true
        $lN.MaximumSize = [System.Drawing.Size]::new(($w-28),0)
        $card.Controls.Add($lN)
    }

    $parent.Controls.Add($card)
    return $card
}

# ============================================================
#  FORM & CARDS
# ============================================================
$formW   = 1140
$formH   = 680
$headerH = 68

$leftX   = 20
$cardW   = 550
$colGap  = 16
$rightX  = $leftX + $cardW + $colGap

$row1Y   = 10
$row2Y   = 196
$row4Y   = 476

$cTopH      = 170
$cLeftMidH  = 270
$cRightMid1 = 130
$cRightMid2 = 140
$cBottomH   = 110

$form = New-Object System.Windows.Forms.Form
try { $appIcon = Get-AppIcon; if($appIcon){ $form.Icon = $appIcon } } catch {}
$form.ShowInTaskbar = $true
$form.Text = T 'Title'
$form.ClientSize = [System.Drawing.Size]::new($formW,$formH)
$form.MinimumSize = $form.Size
$form.BackColor = $script:BG
$form.ForeColor = $script:TEXT
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.StartPosition = 'CenterScreen'
$form.Font = $FontSub

$pHeader = New-Pnl 0 0 $formW $headerH $script:SURFACE
$lAppTitle   = New-Lbl "MPV-SW-Capture" 20 4 380 36 $FontTitle $script:ACCENT
$lAppSub     = New-Lbl (T "HeaderSub") 22 37 460 18 $FontSub $script:MUTED
$lLangLbl    = New-Lbl (T "LangLabel") 930 10 90 18 $FontSmall $script:MUTED

$btnEN       = New-Object System.Windows.Forms.Button
$btnEN.Text  = "EN"
$btnEN.Location = [System.Drawing.Point]::new(1038,6)
$btnEN.Size     = [System.Drawing.Size]::new(44,26)
Style-LangBtn $btnEN $true

$btnES       = New-Object System.Windows.Forms.Button
$btnES.Text  = "ES"
$btnES.Location = [System.Drawing.Point]::new(1086,6)
$btnES.Size     = [System.Drawing.Size]::new(44,26)
Style-LangBtn $btnES $false

$lHeaderNote = New-Lbl (T "HeaderNote") 710 38 470 18 $FontHeaderNote $script:ACCENT3

$script:EXE_OK  = [System.Drawing.Color]::FromArgb(50, 160, 80)
$script:EXE_ERR = [System.Drawing.Color]::FromArgb(180, 50, 50)

function Get-FfplayStatus {
    if (Test-Path (Join-Path $script:RootDir "ffplay.exe")) { return (T "FfplayFound"), $script:EXE_OK }
    else { return (T "FfplayNotFound"), $script:EXE_ERR }
}
function Get-MenuStatus {
    if (Test-Path (Join-Path $script:RootDir "menu.conf")) { return (T "MenuFound"), $script:EXE_OK }
    else { return ("menu.conf: NOT Found!"), $script:EXE_ERR }
}

$lExeFFplay   = New-Lbl "" 520 18 220 16 $FontSmall $script:EXE_OK
$lExeMenuConf = New-Lbl "" 520 36 220 16 $FontSmall $script:EXE_OK

$pHeader.Controls.AddRange(@($lAppTitle,$lAppSub,$lLangLbl,$btnEN,$btnES,$lHeaderNote,$lExeFFplay,$lExeMenuConf))
$form.Controls.Add($pHeader)

$pMain = New-Pnl 0 $headerH $formW ($formH-$headerH) $script:BG
$form.Controls.Add($pMain)

# --- Card Left 1: Devices ---
$card1 = New-CardXY $pMain $leftX $row1Y $cardW $cTopH "S1Title" $null $false
$lVidLbl  = New-Lbl (T "S1VidLbl") 14 38 220 18 $FontBold $script:TEXT
$cbVideo  = New-CB 14 58 320
$lAudLbl  = New-Lbl (T "S1AudLbl") 14 96 220 18 $FontBold $script:TEXT
$cbAudio  = New-CB 14 116 320

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = (T "S1ScanBtn")
$btnScan.Location = [System.Drawing.Point]::new(356,56)
$btnScan.Size     = [System.Drawing.Size]::new(170,32)
Style-Btn $btnScan $script:ACCENT $script:BG

$lScanStatus = New-Lbl "" 356 98 170 44 $FontSmall $script:MUTED
$card1.Controls.AddRange(@($lVidLbl,$cbVideo,$lAudLbl,$cbAudio,$btnScan,$lScanStatus))

# --- Card Right 1: Record Time (Radio Buttons) ---
$card3 = New-CardXY $pMain $rightX $row1Y $cardW $cTopH "S4Title" $null $false
$lS4Note = New-Object System.Windows.Forms.Label
$lS4Note.Text        = T "S4Note"
$lS4Note.Location    = [System.Drawing.Point]::new(14,34)
$lS4Note.Size        = [System.Drawing.Size]::new(530,0)
$lS4Note.Font        = $FontNote
$lS4Note.ForeColor   = $script:NOTE_C
$lS4Note.BackColor   = [System.Drawing.Color]::Transparent
$lS4Note.AutoSize    = $true
$lS4Note.MaximumSize = [System.Drawing.Size]::new(530,0)
$card3.Controls.Add($lS4Note)

$rbRec30  = New-RB (T "S4Opt1") 14 80 520
$rbRec60  = New-RB (T "S4Opt2") 14 100 520
$rbRec90  = New-RB (T "S4Opt3") 14 120 520
$rbRec120 = New-RB (T "S4Opt4") 14 140 520
$rbRec30.Checked = $true
$card3.Controls.AddRange(@($rbRec30,$rbRec60,$rbRec90,$rbRec120))

# --- Card Left 2: Other Options ---
$card5 = New-CardXY $pMain $leftX $row2Y $cardW $cLeftMidH "S5Title" $null $false

$pnlAudioMode = New-Pnl 14 30 520 26 $script:CARD
$lAudioModeLabel = New-Lbl (T "S5AudioModeTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbAudioModeWasapi = New-RB "WASAPI" 320 3 80
$rbAudioModeFfplay = New-RB "FFPLAY" 420 3 90
$rbAudioModeWasapi.Checked = $true
$pnlAudioMode.Controls.AddRange(@($lAudioModeLabel, $rbAudioModeWasapi, $rbAudioModeFfplay))

$pnlSc = New-Pnl 14 54 520 26 $script:CARD
$lScLabel = New-Lbl (T "S5Shorcut") 0 5 320 16 $FontSmallBold $script:ACCENT3
$rbScNo   = New-RB (T "S5No")  320 3 50
$rbScYes  = New-RB (T "S5Yes") 420 3 50
$rbScYes.Checked = $true
$pnlSc.Controls.AddRange(@($lScLabel, $rbScNo, $rbScYes))

$pnlIcc = New-Pnl 14 78 520 26 $script:CARD
$lIccLabel = New-Lbl (T "S5IccTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbIccNo   = New-RB (T "S5No")  320 3 50
$rbIccYes  = New-RB (T "S5Yes") 420 3 50
$rbIccNo.Checked = $true
$pnlIcc.Controls.AddRange(@($lIccLabel, $rbIccNo, $rbIccYes))

$pnlOsd = New-Pnl 14 102 520 26 $script:CARD
$lOsdLabel = New-Lbl (T "S5OsdTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbOsdNo   = New-RB (T "S5No")  320 3 50
$rbOsdYes  = New-RB (T "S5Yes") 420 3 50
$rbOsdNo.Checked = $true
$pnlOsd.Controls.AddRange(@($lOsdLabel, $rbOsdNo, $rbOsdYes))

$pnlBorder = New-Pnl 14 126 520 26 $script:CARD
$lBorderLabel = New-Lbl (T "S5BorderTitle") 0 5 260 16 $FontSmallBold $script:ACCENT3
$rbBorderNo   = New-RB (T "S5No")        265 3 50
$rbBorderOnly = New-RB (T "S5BorderOnly") 320 3 100
$rbBorderBoth = New-RB (T "S5BorderBoth") 420 3 110
$rbBorderNo.Checked = $true
$pnlBorder.Controls.AddRange(@($lBorderLabel, $rbBorderNo, $rbBorderOnly, $rbBorderBoth))

$pnlAutoCheck = New-Pnl 14 150 520 26 $script:CARD
$lAutoCheckLabel = New-Lbl (T "S5AutoCheckTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbAutoCheckNo   = New-RB (T "S5No")  320 3 50
$rbAutoCheckYes  = New-RB (T "S5Yes") 420 3 50
$rbAutoCheckNo.Checked = $true
$pnlAutoCheck.Controls.AddRange(@($lAutoCheckLabel, $rbAutoCheckNo, $rbAutoCheckYes))

$pnlHoverVolume = New-Pnl 14 174 520 26 $script:CARD
$lHoverVolumeLabel = New-Lbl (T "S5HoverVolumeTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbHoverVolumeNo   = New-RB (T "S5No")  320 3 50
$rbHoverVolumeYes  = New-RB (T "S5Yes") 420 3 50
$rbHoverVolumeNo.Checked = $true
$pnlHoverVolume.Controls.AddRange(@($lHoverVolumeLabel, $rbHoverVolumeNo, $rbHoverVolumeYes))

# --- Input Video Format Panel ---
$pnlVideoFormat = New-Pnl 14 198 520 26 $script:CARD
$lVideoFormatLabel = New-Lbl (T "S5VideoFormatTitle") 0 5 280 16 $FontSmallBold $script:ACCENT3
$cbVideoFormat = New-Object System.Windows.Forms.ComboBox
$cbVideoFormat.Location = [System.Drawing.Point]::new(285, 2)
$cbVideoFormat.Size = [System.Drawing.Size]::new(235, 24)
$cbVideoFormat.DropDownStyle = 'DropDownList'
$cbVideoFormat.Font = $FontSub
$cbVideoFormat.BackColor = $script:CARD
$cbVideoFormat.ForeColor = $script:TEXT
$cbVideoFormat.FlatStyle = 'Flat'
[void]$cbVideoFormat.Items.AddRange(@('auto', 'mjpeg', 'yuyv422', 'nv12', 'i420', 'h264'))
$cbVideoFormat.SelectedIndex = 0
$pnlVideoFormat.Controls.AddRange(@($lVideoFormatLabel, $cbVideoFormat))

$card5.Controls.AddRange(@($pnlAudioMode, $pnlSc, $pnlIcc, $pnlOsd, $pnlBorder, $pnlAutoCheck, $pnlHoverVolume, $pnlVideoFormat))

# --- Card Right 2: Shaders ---
$card4 = New-CardXY $pMain $rightX $row2Y $cardW $cRightMid1 "S3Title" $null $false
$lS3Note = New-Object System.Windows.Forms.Label
$lS3Note.Text        = T "S3Note"
$lS3Note.Location    = [System.Drawing.Point]::new(14,34)
$lS3Note.Size        = [System.Drawing.Size]::new(530,0)
$lS3Note.Font        = $FontNote
$lS3Note.ForeColor   = $script:NOTE_C
$lS3Note.BackColor   = [System.Drawing.Color]::Transparent
$lS3Note.AutoSize    = $true
$lS3Note.MaximumSize = [System.Drawing.Size]::new(530,0)
$card4.Controls.Add($lS3Note)

$rbShOff = New-RB (T "S3No") 14 85 520
$rbShOnS = New-RB (T "S3Sharpen") 14 107 250
$rbShOnA = New-RB (T "S3AA") 270 107 250
$rbShOff.Checked = $true
$card4.Controls.AddRange(@($rbShOff, $rbShOnS, $rbShOnA))

# --- Card Right 3: Audio Options ---
$card6 = New-CardXY $pMain $rightX ($row2Y + $cRightMid1 + 10) $cardW $cRightMid2 "S4AudioTitle" $null $false

$pnlPeriod = New-Pnl 14 30 520 50 $script:CARD
$lPeriodLabel = New-Lbl (T "S5PeriodTitle") 0 2 520 16 $FontSmallBold $script:ACCENT3
$rbPeriodMin  = New-RB "minimum"     4   24 100
$rbPeriodFund = New-RB "fundamental" 110 24 120
$rbPeriodDef  = New-RB "default"     240 24 90
$rbPeriodMax  = New-RB "maximum"     340 24 100
$rbPeriodMin.Checked = $true
$pnlPeriod.Controls.AddRange(@($lPeriodLabel, $rbPeriodMin, $rbPeriodFund, $rbPeriodDef, $rbPeriodMax))
$card6.Controls.Add($pnlPeriod)

$pnlBufferSize = New-Pnl 14 85 520 26 $script:CARD
$lBufferSizeLabel = New-Lbl (T "S5BufferTitle") 0 5 320 16 $FontSmallBold $script:ACCENT3
$cbBufferSize = New-Object System.Windows.Forms.ComboBox
$cbBufferSize.Location = [System.Drawing.Point]::new(325, 1)
$cbBufferSize.Size = [System.Drawing.Size]::new(195, 24)
$cbBufferSize.DropDownStyle = 'DropDownList'
$cbBufferSize.Font = $FontSub
$cbBufferSize.BackColor = $script:CARD
$cbBufferSize.ForeColor = $script:TEXT
$cbBufferSize.FlatStyle = 'Flat'
[void]$cbBufferSize.Items.AddRange(@( (T "S5BufOpt1"), (T "S5BufOpt2"), (T "S5BufOpt3"), (T "S5BufOpt4"), (T "S5BufOpt5"), (T "S5BufOpt6") ))
$cbBufferSize.SelectedIndex = 2
$pnlBufferSize.Controls.AddRange(@($lBufferSizeLabel, $cbBufferSize))
$card6.Controls.Add($pnlBufferSize)

$pnlZeroFill = New-Pnl 14 115 520 26 $script:CARD
$lZeroFillLabel = New-Lbl (T "S5ZeroFillTitle") 0 5 260 16 $FontSmallBold $script:ACCENT3
$rbZeroFillPop = New-RB (T "S5ZeroPop") 265 3 80
$rbZeroFillSilence = New-RB (T "S5ZeroSilence") 350 3 110
$rbZeroFillPop.Checked = $true
$pnlZeroFill.Controls.AddRange(@($lZeroFillLabel, $rbZeroFillPop, $rbZeroFillSilence))
$card6.Controls.Add($pnlZeroFill)

# --- Card Left 3: Date Format ---
$card2 = New-CardXY $pMain $leftX $row4Y $cardW $cBottomH "S2Title" $null $false
$rbEU  = New-RB (T "S2Opt2") 14 35 500
$rbISO = New-RB (T "S2Opt1") 14 55 500
$rbUS  = New-RB (T "S2Opt3") 14 75 500
$rbEU.Checked = $true
$card2.Controls.AddRange(@($rbEU,$rbISO,$rbUS))

# --- Card Right 4: Actions ---
$card7 = New-CardXY $pMain $rightX $row4Y $cardW $cBottomH "ActionsTitle" $null $false
$cbMenuLang = New-Object System.Windows.Forms.ComboBox
$cbMenuLang.Location      = [System.Drawing.Point]::new(14,35)
$cbMenuLang.Size          = [System.Drawing.Size]::new(88,28)
$cbMenuLang.DropDownStyle = 'DropDownList'
$cbMenuLang.Font          = $FontSub
$cbMenuLang.BackColor     = $script:CARD
$cbMenuLang.ForeColor     = $script:TEXT
$cbMenuLang.FlatStyle     = 'Flat'

$btnMenuToggle = New-Object System.Windows.Forms.Button
$btnMenuToggle.Text     = (T "ApplyLangBtn")
$btnMenuToggle.Location = [System.Drawing.Point]::new(108,30)
$btnMenuToggle.Size     = [System.Drawing.Size]::new(126,40)
Style-Btn $btnMenuToggle $script:ACCENT3 $script:BG
$btnMenuToggle.Font = $FontBtn

$btnDefaultOpts = New-Object System.Windows.Forms.Button
$btnDefaultOpts.Text     = (T "BtnDefaultOpts")
$btnDefaultOpts.Location = [System.Drawing.Point]::new(244,30)
$btnDefaultOpts.Size     = [System.Drawing.Size]::new(146,40)
Style-Btn $btnDefaultOpts $script:MUTED $script:BG
$btnDefaultOpts.Font = $FontBtn

$lStatus = New-Lbl (T "StatusReady") 14 76 522 20 $FontSub $script:MUTED
$lStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = (T "ApplyBtn")
$btnApply.Location = [System.Drawing.Point]::new(402,30)
$btnApply.Size     = [System.Drawing.Size]::new(134,40)
Style-Btn $btnApply $script:ACCENT2 $script:BG
$card7.Controls.AddRange(@($cbMenuLang,$btnMenuToggle,$btnDefaultOpts,$lStatus,$btnApply))

# ============================================================
#  LANGUAGE SWITCH (GUI only)
# ============================================================
function Apply-Lang([string]$lang) {
    $script:CurrentLang = $lang
    Style-LangBtn $btnEN ($lang -eq "EN")
    Style-LangBtn $btnES ($lang -eq "ES")

    $form.Text = T 'Title'
    $lAppSub.Text     = T "HeaderSub"
    $lLangLbl.Text    = T "LangLabel"
    $lHeaderNote.Text = T "HeaderNote"

    # Update card titles
    $card1.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S1Title" }
    $card2.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S2Title" }
    $card3.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S4Title" }
    $card4.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S3Title" }
    $card5.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S5Title" }
    $card6.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S4AudioTitle" }
    $card7.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "ActionsTitle" }

    $lVidLbl.Text = T "S1VidLbl"
    $lAudLbl.Text = T "S1AudLbl"
    $btnScan.Text = T "S1ScanBtn"

    switch ($script:LastScanState) {
        "scanning" {
            $lScanStatus.ForeColor = $script:MUTED
            $lScanStatus.Text = T "S1Scanning"
        }
        "found" {
            $lScanStatus.ForeColor = $script:SUCCESS
            $lScanStatus.Text = [string]::Format((T "S1Found"), $script:LastVideoCount, $script:LastAudioCount)
        }
        "no_devices" {
            $lScanStatus.ForeColor = $script:ERROR_C
            $lScanStatus.Text = T "S1NoDevices"
        }
        "scan_error" {
            $lScanStatus.ForeColor = $script:ERROR_C
            $lScanStatus.Text = [string]::Format((T "ErrStatus"), $script:LastScanError)
        }
        default { $lScanStatus.Text = "" }
    }

    $rbISO.Text   = T "S2Opt1"
    $rbEU.Text    = T "S2Opt2"
    $rbUS.Text    = T "S2Opt3"

    $lS3Note.Text = T "S3Note"
    $rbShOff.Text = T "S3No"
    $rbShOnS.Text = T "S3Sharpen"
    $rbShOnA.Text = T "S3AA"

    $lS4Note.Text = T "S4Note"
    $rbRec30.Text = T "S4Opt1"
    $rbRec60.Text = T "S4Opt2"
    $rbRec90.Text = T "S4Opt3"
    $rbRec120.Text = T "S4Opt4"

    $lScLabel.Text      = T "S5Shorcut"
    $lIccLabel.Text     = T "S5IccTitle"
    $lOsdLabel.Text     = T "S5OsdTitle"
    $lBorderLabel.Text  = T "S5BorderTitle"
    $lAutoCheckLabel.Text = T "S5AutoCheckTitle"
    $lAudioModeLabel.Text = T "S5AudioModeTitle"
    $lHoverVolumeLabel.Text = T "S5HoverVolumeTitle"
    $lVideoFormatLabel.Text = T "S5VideoFormatTitle"
    $lPeriodLabel.Text  = T "S5PeriodTitle"
    $lBufferSizeLabel.Text = T "S5BufferTitle"
    $lZeroFillLabel.Text = T "S5ZeroFillTitle"

    $rbScNo.Text        = T "S5No"
    $rbScYes.Text       = T "S5Yes"
    $rbIccNo.Text       = T "S5No"
    $rbIccYes.Text      = T "S5Yes"
    $rbOsdNo.Text       = T "S5No"
    $rbOsdYes.Text      = T "S5Yes"
    $rbBorderNo.Text    = T "S5No"
    $rbBorderOnly.Text  = T "S5BorderOnly"
    $rbBorderBoth.Text  = T "S5BorderBoth"
    $rbAutoCheckNo.Text = T "S5No"
    $rbAutoCheckYes.Text = T "S5Yes"
    $rbHoverVolumeNo.Text = T "S5No"
    $rbHoverVolumeYes.Text = T "S5Yes"

    # Refresh buffer size combo items (they are language-dependent)
    $currentBufIndex = $cbBufferSize.SelectedIndex
    $cbBufferSize.Items.Clear()
    [void]$cbBufferSize.Items.AddRange(@( (T "S5BufOpt1"), (T "S5BufOpt2"), (T "S5BufOpt3"), (T "S5BufOpt4"), (T "S5BufOpt5"), (T "S5BufOpt6") ))
    if ($currentBufIndex -ge 0 -and $currentBufIndex -lt $cbBufferSize.Items.Count) {
        $cbBufferSize.SelectedIndex = $currentBufIndex
    } else {
        $cbBufferSize.SelectedIndex = 2
    }

    $rbZeroFillPop.Text = T "S5ZeroPop"
    $rbZeroFillSilence.Text = T "S5ZeroSilence"

    switch ($script:LastStatusState) {
        "ready"           { $lStatus.ForeColor = $script:MUTED;   $lStatus.Text = T "StatusReady" }
        "menu_lang_set"   { $lStatus.ForeColor = $script:SUCCESS; $lStatus.Text = [string]::Format((T "MenuToLanguage"), $script:LastMenuLangSet) }
        "defaults_loaded" { $lStatus.ForeColor = $script:ACCENT3; $lStatus.Text = T "StatusDefaultsLoaded" }
        "done"            { $lStatus.ForeColor = $script:SUCCESS; $lStatus.Text = T "DoneStatus" }
        "err_select"      { $lStatus.ForeColor = $script:ERROR_C; $lStatus.Text = T "ErrSelect" }
        "custom_error"    { $lStatus.ForeColor = $script:ERROR_C; $lStatus.Text = [string]::Format((T "ErrStatus"), $script:LastErrorText) }
        default           { $lStatus.ForeColor = $script:MUTED;   $lStatus.Text = T "StatusReady" }
    }

    $btnApply.Text       = T "ApplyBtn"
    $btnMenuToggle.Text  = T "ApplyLangBtn"
    $btnDefaultOpts.Text = T "BtnDefaultOpts"

    $ffText, $ffColor = Get-FfplayStatus
    $lExeFFplay.Text = $ffText
    $lExeFFplay.ForeColor = $ffColor

    $menuText, $menuColor = Get-MenuStatus
    $lExeMenuConf.Text = $menuText
    $lExeMenuConf.ForeColor = $menuColor

    $form.Refresh()
}

# ============================================================
#  EVENTS
# ============================================================
$btnEN.Add_Click({
    Apply-Lang "EN"
    Save-GUILanguage "EN"
})
$btnES.Add_Click({
    Apply-Lang "ES"
    Save-GUILanguage "ES"
})

# ============================================================
#  SCAN DEVICES
# ============================================================
$btnScan.Add_Click({
    if ($script:LastScanState -eq "scanning") { return }
    $btnScan.Enabled  = $false
    $btnApply.Enabled = $false
    $script:LastScanState = "scanning"
    $lScanStatus.ForeColor = $script:MUTED
    $lScanStatus.Text = (T "S1Scanning")
    $form.Refresh()

    $proc = $null

    try {
        $ffplayLocal = Join-Path $script:RootDir "ffplay.exe"
        if (-not (Test-Path $ffplayLocal)) {
            throw "ffplay.exe not found in root directory ($script:RootDir)"
        }
        $ffplayCmd = $ffplayLocal

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $ffplayCmd
        $psi.Arguments = '-hide_banner -list_devices true -f dshow -i dummy'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardOutput = $true

        $enc = New-Object System.Text.UTF8Encoding($false)
        try {
            $psi.StandardOutputEncoding = $enc
            $psi.StandardErrorEncoding  = $enc
        } catch {}

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        [void]$proc.Start()

        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $scanClock  = [System.Diagnostics.Stopwatch]::StartNew()

        while (-not ($proc.HasExited -and $stdoutTask.IsCompleted -and $stderrTask.IsCompleted)) {
            if ($scanClock.Elapsed.TotalSeconds -ge 30) {
                throw "Device scan timed out after 30 seconds. Close other capture apps and retry."
            }
            [System.Windows.Forms.Application]::DoEvents()
            if ($form.IsDisposed) { return }
            Start-Sleep -Milliseconds 25
        }

        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $content = ($stdout + "`r`n" + $stderr)

        $vD = @()
        $aD = @()
        $inVideo = $false
        $inAudio = $false

        foreach ($line in $content -split "`r?`n") {
            if ($line -match 'DirectShow video devices') { $inVideo = $true; $inAudio = $false; continue }
            if ($line -match 'DirectShow audio devices') { $inVideo = $false; $inAudio = $true; continue }

            $m = [regex]::Match($line, '"([^"]+)"')
            if ($m.Success) {
                $name = $m.Groups[1].Value.Trim()
                if ($line -match 'Alternative name') { continue }
                if ($inVideo) { $vD += $name; continue }
                if ($inAudio) { $aD += $name; continue }
                if ($line -match '\(video\)') { $vD += $name; continue }
                if ($line -match '\(audio\)') { $aD += $name; continue }
            }
        }

        $vD = $vD | Select-Object -Unique
        $aD = $aD | Select-Object -Unique

        $cbVideo.Items.Clear()
        $cbAudio.Items.Clear()
        foreach ($d in $vD) { [void]$cbVideo.Items.Add($d) }
        foreach ($d in $aD) { [void]$cbAudio.Items.Add($d) }

        if ($cbVideo.Items.Count -gt 0) { $cbVideo.SelectedIndex = 0 }
        if ($cbAudio.Items.Count -gt 0) { $cbAudio.SelectedIndex = 0 }

        if ($vD.Count -eq 0 -and $aD.Count -eq 0) {
            $script:LastVideoCount = 0; $script:LastAudioCount = 0
            $script:LastScanState = "no_devices"
            $lScanStatus.ForeColor = $script:ERROR_C
            $lScanStatus.Text = (T "S1NoDevices")
        } else {
            $script:LastVideoCount = $vD.Count; $script:LastAudioCount = $aD.Count
            $script:LastScanState = "found"
            $lScanStatus.ForeColor = $script:SUCCESS
            $lScanStatus.Text = [string]::Format((T "S1Found"), $vD.Count, $aD.Count)
        }
    }
    catch {
        $script:LastScanState = "scan_error"
        $script:LastScanError = $_.Exception.Message
        $script:LastVideoCount = $null; $script:LastAudioCount = $null
        $lScanStatus.ForeColor = $script:ERROR_C
        $lScanStatus.Text = [string]::Format((T "ErrStatus"), $script:LastScanError)
    }
    finally {
        if ($null -ne $proc) {
            try { if (-not $proc.HasExited) { $proc.Kill() } } catch {}
            try { $proc.Dispose() } catch {}
        }
        if (-not $form.IsDisposed) {
            $btnScan.Enabled  = $true
            $btnApply.Enabled = $true
        }
    }
})

# ============================================================
#  MENU LANGUAGE BUTTON
# ============================================================
$btnMenuToggle.Add_Click({
    if ($cbMenuLang.SelectedIndex -lt 0) { return }
    $targetLang = ("" + $cbMenuLang.SelectedItem).Trim().ToLower()
    if ($targetLang -eq "") { return }

    try {
        Set-MenuLanguage $targetLang
        $script:LastStatusState = "menu_lang_set"
        $script:LastMenuLangSet = $targetLang.ToUpper()
        $lStatus.ForeColor = $script:SUCCESS
        $lStatus.Text = [string]::Format((T "MenuToLanguage"), $script:LastMenuLangSet)
    } catch {
        $script:LastStatusState = "custom_error"
        $script:LastErrorText = $_.Exception.Message
        $lStatus.ForeColor = $script:ERROR_C
        $lStatus.Text = [string]::Format((T "ErrStatus"), $_.Exception.Message)
    }

    $form.Refresh()
})

# ============================================================
#  DEFAULT OPTIONS BUTTON
# ============================================================
$btnDefaultOpts.Add_Click({
    # Restore all options to their optimal defaults
    $rbAudioModeWasapi.Checked = $true
    $rbScYes.Checked = $true
    $rbIccNo.Checked = $true
    $rbOsdNo.Checked = $true
    $rbBorderNo.Checked = $true
    $rbAutoCheckNo.Checked = $true
    $rbHoverVolumeNo.Checked = $true
    $cbVideoFormat.SelectedIndex = 0 # auto

    # Optimal WASAPI settings
    $rbPeriodMin.Checked = $true
    $cbBufferSize.SelectedIndex = 2   # 25 ms
    $rbZeroFillPop.Checked = $true    # Pop

    # Other options
    $rbRec30.Checked = $true
    $rbEU.Checked = $true
    $rbShOff.Checked = $true # Default is now NO

    $script:LastStatusState = "defaults_loaded"
    $lStatus.ForeColor = $script:ACCENT3
    $lStatus.Text = T "StatusDefaultsLoaded"
    $form.Refresh()
})

# ============================================================
#  APPLY BUTTON
# ============================================================
$btnApply.Add_Click({
    if ($cbVideo.SelectedIndex -lt 0 -or $cbAudio.SelectedIndex -lt 0) {
        $script:LastStatusState = "err_select"
        $lStatus.ForeColor = $script:ERROR_C
        $lStatus.Text = (T "ErrSelect")
        return
    }

    $vDev  = $cbVideo.SelectedItem
    $aDev  = $cbAudio.SelectedItem
    $psFmt = if ($rbISO.Checked) { "yyyy-MM-dd" } elseif ($rbUS.Checked) { "MM-dd-yyyy" } else { "dd-MM-yyyy" }
    $tpl   = if ($psFmt -eq "yyyy-MM-dd") { "MSC_%tY-%tm-%td_%tH%tM%tS" } elseif ($psFmt -eq "MM-dd-yyyy") { "MSC_%tm-%td-%tY_%tH%tM%tS" } else { "MSC_%td-%tm-%tY_%tH%tM%tS" }
    
    $shMode = "no"
    if ($rbShOnS.Checked) { $shMode = "sharpen" }
    elseif ($rbShOnA.Checked) { $shMode = "aa" }

    $shInit = "none"
    if ($shMode -eq "sharpen") { $shInit = "SH_SPN_1" }
    elseif ($shMode -eq "aa") { $shInit = "SH_AA_1" }

    # Get record seconds from radio buttons
    $recSec = if ($rbRec30.Checked) { 30 } elseif ($rbRec60.Checked) { 60 } elseif ($rbRec90.Checked) { 90 } else { 120 }
    $recLua = $recSec.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)

    $root    = $script:RootDir
    $batPath = Join-Path $root "data\MPV-SW-Capture.bat"
    # All text files are written as UTF-8 without BOM (matches Video_MSCGUI behavior).
    $utf8    = New-Object System.Text.UTF8Encoding $false

    # Update a text file by replacing every regex in the map.
    function Update-File([string]$path, [hashtable]$map, [System.Text.Encoding]$enc) {
        if (-not (Test-Path $path)) { return }
        $c = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        foreach ($k in $map.Keys) { $c = $c -replace $k, $map[$k] }
        [System.IO.File]::WriteAllText($path, $c, $enc)
    }

    # Create a .lnk shortcut; if COM fails, fall back to a .url shortcut.
    function Ensure-Shortcut([string]$destPath, [string]$targetExe, [string]$workingDir, [string]$iconPath) {
        try {
            [ShortcutCreator]::CreateShortcut($destPath, $targetExe, $workingDir, $iconPath, 0)
            return
        } catch {}
        $urlContent = @"
[InternetShortcut]
URL=file:///$($workingDir.Replace('\','/'))/mpv.exe
IconIndex=0
IconFile=$iconPath
"@
        $urlPath = [System.IO.Path]::ChangeExtension($destPath, '.url')
        [System.IO.File]::WriteAllText($urlPath, $urlContent, [System.Text.Encoding]::UTF8)
    }

    try {
        # --- Device names in .bat and usb3.lua ---
        Update-File $batPath @{
            '(SET "video_device=)[^"]*"' = ('${1}' + $vDev + '"')
            '(SET "audio_device=)[^"]*"' = ('${1}' + $aDev + '"')
        } $utf8

        Update-File (Join-Path $root "scripts\usb3.lua") @{
            '(data\.video_device\s*=\s*")[^"]*"' = ('${1}' + $vDev + '"')
            '(data\.audio_device\s*=\s*")[^"]*"' = ('${1}' + $aDev + '"')
        } $utf8

        # --- mpv.conf (screenshot template, shader, ICC, OSD) ---
        $cf = Join-Path $root "mpv.conf"
        if (Test-Path $cf) {
            $c = [System.IO.File]::ReadAllText($cf, [System.Text.Encoding]::UTF8)
            $c = $c -replace 'screenshot-template=.*', ('screenshot-template="' + $tpl + '"')

            # Shader logic
            if ($shMode -ne "no") {
                $shaderPath = if ($shMode -eq "sharpen") { "~~/shaders/sharpen/sharpen_lite_msc.glsl" } else { "~~/shaders/aa/aa_lite_msc.glsl" }
                
                # Remove existing shader and deband lines
                $c = $c -replace '(?m)^#?\s*deband=.*(?:\r?\n|$)', ''
                $c = $c -replace '(?m)^#?\s*glsl-shader=.*(?:\r?\n|$)', ''
                
                $shaderLines = "glsl-shader=`"$shaderPath`"`r`ndeband=no`r`n"
                
                if ($c -match '(?m)(# ===========================\r?\n# LAUNCH SHADER.*?\r?\n# ===========================\r?\n)') {
                    $c = $c -replace '(?m)(# ===========================\r?\n# LAUNCH SHADER.*?\r?\n# ===========================\r?\n)', "`$1$shaderLines"
                } else {
                    $c = $c.TrimEnd() + "`r`n# ===========================`r`n# LAUNCH SHADER (You will start with this when launch MPV)`r`n# ===========================`r`n$shaderLines"
                }
            } else {
                # NO: Comment out shader and enable deband
                $c = $c -replace '(?m)^\s*#?\s*deband=.*(?:\r?\n|$)', "# deband=yes`r`n"
                $c = $c -replace '(?m)^\s*#?\s*glsl-shader=.*(?:\r?\n|$)', "# glsl-shader=`"~~/shaders/sharpen/sharpen_lite_msc.glsl`"`r`n"
            }

            $c = $c -replace '(\r?\n){3,}', "`r`n`r`n"
            $c = $c.TrimEnd() + "`r`n"

            $iccVal = if ($rbIccYes.Checked) { "yes" } else { "no" }
            if ($c -match 'icc-profile-auto=') {
                $c = $c -replace 'icc-profile-auto=\S+', ('icc-profile-auto=' + $iccVal)
            } else {
                $c = $c.TrimEnd() + "`r`nicc-profile-auto=$iccVal`r`n"
            }
            $osdVal = if ($rbOsdYes.Checked) { "0" } else { "1000" }
            if ($c -match 'osd-duration=') {
                $c = $c -replace 'osd-duration=\d+', ('osd-duration=' + $osdVal)
            } else {
                $c = $c.TrimEnd() + "`r`nosd-duration=$osdVal`r`n"
            }
            [System.IO.File]::WriteAllText($cf, $c, $utf8)
        }

        # --- Border / title bar in .bat ---
        if (Test-Path $batPath) {
            $batContent = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)

            if ($rbBorderNo.Checked) {
                $borderArg = "--no-border"
                $titleArg  = ""
            } elseif ($rbBorderOnly.Checked) {
                $borderArg = "--border"
                $titleArg  = "--title-bar=no"
            } else {
                $borderArg = "--border"
                $titleArg  = ""
            }

            $batContent = $batContent -replace '--no-border ', ''
            $batContent = $batContent -replace '--no-border', ''
            $batContent = $batContent -replace '--border ', ''
            $batContent = $batContent -replace '--border', ''
            $batContent = $batContent -replace '--title-bar=\S+ ', ''
            $batContent = $batContent -replace '--title-bar=\S+', ''

            $pattern = '(start "" /b "%prog1_path%" )'
            $replacement = '${1}' + $borderArg + ' ' + $titleArg + ' '
            $batContent = $batContent -replace $pattern, $replacement
            $batContent = $batContent -replace '  +', ' '

            [System.IO.File]::WriteAllText($batPath, $batContent, $utf8)
        }

        # --- Auto-check for updates in .bat ---
        $autoCheckVal = if ($rbAutoCheckYes.Checked) { "1" } else { "0" }
        if (Test-Path $batPath) {
            $batContent = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)
            if ($batContent -match '(--script-opts=msc_check_version_auto=\d)') {
                $batContent = $batContent -replace '--script-opts=msc_check_version_auto=\d', ('--script-opts=msc_check_version_auto=' + $autoCheckVal)
            } else {
                $batContent = $batContent -replace '(start "" /b "%prog1_path%.*?)(\s*$|(?= --))', ('$1 --script-opts=msc_check_version_auto=' + $autoCheckVal)
            }
            [System.IO.File]::WriteAllText($batPath, $batContent, $utf8)
        }

        # --- Date format in autocompress.lua ---
        $luaDateFmt = if ($psFmt -eq "yyyy-MM-dd") { "%Y-%m-%d_%H%M%S" } elseif ($psFmt -eq "MM-dd-yyyy") { "%m-%d-%Y_%H%M%S" } else { "%d-%m-%Y_%H%M%S" }
        Update-File (Join-Path $root "scripts\autocompress.lua") @{
            'os\.date\("%[^"]+"\)' = ('os.date("' + $luaDateFmt + '")')
        } $utf8

        # --- shader_init.lua ---
        $shaderInitPath = Join-Path $root "scripts\shader_init.lua"
        if (Test-Path $shaderInitPath) {
            $content = [System.IO.File]::ReadAllText($shaderInitPath, [System.Text.Encoding]::UTF8)
            $content = $content -replace 'mp\.set_property\("user-data/active_shader",\s*"[^"]*"\)', ('mp.set_property("user-data/active_shader", "' + $shInit + '")')
            [System.IO.File]::WriteAllText($shaderInitPath, $content, $utf8)
        } else {
            $shaderInitContent = @"
-- shader_init.lua - Initialization of shader and OSD control
local current_lang = "en"

mp.set_property("user-data/active_shader", "$shInit")

local function toggle_osd()
    local dur = mp.get_property_number("osd-duration")
    if dur == 0 then
        mp.set_property_number("osd-duration", 1000)
        if current_lang == "es" then
            mp.osd_message("Mostrar OSD", 1, 0)
        else
            mp.osd_message("OSD Show Mode", 1, 0)
        end
    else
        mp.set_property_number("osd-duration", 0)
        if current_lang == "es" then
            mp.osd_message("Ocultar OSD", 1, 0)
        else
            mp.osd_message("OSD Hidden Mode", 1, 0)
        end
    end
end
mp.register_script_message("toggle-osd", toggle_osd)
"@
            [System.IO.File]::WriteAllText($shaderInitPath, $shaderInitContent, $utf8)
        }

        Update-File (Join-Path $root "menu.conf") @{
            'Limit=\d+ Sec' = ('Limit=' + $recSec + ' Sec')
        } $utf8

        Update-File (Join-Path $root "scripts\record.lua") @{
            '(data\.max_record_time\s*=\s*)\d+(?:\.\d+)?' = ('${1}' + $recLua)
        } $utf8

        # --- Audio mode / hover volume (PS 5.1 compatible) ---
        $audioModeValue = if ($rbAudioModeFfplay.Checked) { "ffplay" } else { "plugin" }
        Set-AudioModeSetting $audioModeValue

        $hoverValue = if ($rbHoverVolumeYes.Checked) { "yes" } else { "no" }
        Set-HoverVolumeSetting $hoverValue

        # --- WASAPI period / buffer / zero-fill in .bat ---
        $periodValue = if     ($rbPeriodMin.Checked)  { "minimum" } `
                  elseif ($rbPeriodFund.Checked) { "fundamental" } `
                  elseif ($rbPeriodDef.Checked)  { "default" } `
                  else                           { "maximum" }

        $bufferValue   = $cbBufferSize.SelectedItem.ToString() -replace ' ms.*', ''
        $zeroFillValue = if ($rbZeroFillSilence.Checked) { "1" } else { "0" }

        if (Test-Path $batPath) {
            $batContent = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)

            if ($batContent -match 'set "MSC_AUDIO_PERIOD=[^"]*"') {
                $batContent = $batContent -replace 'set "MSC_AUDIO_PERIOD=[^"]*"', ('set "MSC_AUDIO_PERIOD=' + $periodValue + '"')
            } else {
                $insert = ':: --- WASAPI capture period (plugin audio mode only) ---' + "`r`n" +
                          ':: Options: minimum | fundamental | default | maximum' + "`r`n" +
                          ":: If removed or empty, the DLL falls back to 'minimum'." + "`r`n" +
                          'set "MSC_AUDIO_PERIOD=' + $periodValue + '"'
                $batContent = $batContent -replace '(?i)(SET "audio_device=[^"]*")', ('$1' + "`r`n`r`n" + $insert)
            }

            if ($batContent -match 'set "MSC_AUDIO_BUFFER_MS=[^"]*"') {
                $batContent = $batContent -replace 'set "MSC_AUDIO_BUFFER_MS=[^"]*"', ('set "MSC_AUDIO_BUFFER_MS=' + $bufferValue + '"')
            } else {
                $insertBuf = ':: --- Audio buffer size in milliseconds ---' + "`r`n" +
                             'set "MSC_AUDIO_BUFFER_MS=' + $bufferValue + '"'
                $batContent = $batContent -replace '(?i)(set "MSC_AUDIO_PERIOD=[^"]*")', ('$1' + "`r`n" + $insertBuf)
            }

            if ($batContent -match 'set "MSC_AUDIO_ZERO_FILL=[^"]*"') {
                $batContent = $batContent -replace 'set "MSC_AUDIO_ZERO_FILL=[^"]*"', ('set "MSC_AUDIO_ZERO_FILL=' + $zeroFillValue + '"')
            } else {
                $insertZero = ':: --- Underrun behavior: 1=Silence, 0=Pop ---' + "`r`n" +
                              'set "MSC_AUDIO_ZERO_FILL=' + $zeroFillValue + '"'
                $batContent = $batContent -replace '(?i)(set "MSC_AUDIO_BUFFER_MS=[^"]*")', ('$1' + "`r`n" + $insertZero)
            }

            [System.IO.File]::WriteAllText($batPath, $batContent, $utf8)
        }

        # --- Input Video Format: line-based edit ---
        $selectedFormat = $cbVideoFormat.SelectedItem.ToString()
        if (Test-Path $batPath) {
            # Read as LINES so we only touch the mpv start line
            $batLines = [System.IO.File]::ReadAllLines($batPath, [System.Text.Encoding]::UTF8)

            # Locate the mpv start line
            $mpvLineIdx = -1
            for ($i = 0; $i -lt $batLines.Count; $i++) {
                if ($batLines[$i] -like '*start "" /b "%prog1_path%"*' -and
                    $batLines[$i] -like '*--profile=low-latency*') {
                    $mpvLineIdx = $i
                    break
                }
            }

            if ($mpvLineIdx -ge 0) {
                $line = $batLines[$mpvLineIdx]

                $optMatch = [regex]::Match($line, '(?i)--demuxer-lavf-o(?:ptions)?=(?:"([^"]*)"|([^\s]+))')

                if ($optMatch.Success) {
                    # Preserve existing non-format options
                    $optValue = if ($optMatch.Groups[1].Success) { $optMatch.Groups[1].Value } else { $optMatch.Groups[2].Value }

                    $parts = @()
                    if (-not [string]::IsNullOrWhiteSpace($optValue)) {
                        $parts = @($optValue -split ',' |
                            ForEach-Object { $_.Trim() } |
                            Where-Object { $_ -ne "" -and $_ -notmatch '(?i)^(vcodec|pixel_format)=' })
                    }

                    if ($selectedFormat -eq 'mjpeg' -or $selectedFormat -eq 'h264') {
                        $parts += "vcodec=$selectedFormat"
                    } elseif ($selectedFormat -ne 'auto') {
                        $parts += "pixel_format=$selectedFormat"
                    }

                    $newOptsStr = ($parts | Where-Object { $_ -ne "" }) -join ','

                    if ($newOptsStr -eq "") {
                        # 'auto' with no other options: remove the parameter entirely
                        $before = $line.Substring(0, $optMatch.Index)
                        $after  = $line.Substring($optMatch.Index + $optMatch.Length)
                        if ($before.EndsWith(' ') -and $after.StartsWith(' ')) {
                            $after = $after.Substring(1)
                        }
                        $line = $before + $after
                    } else {
                        # Replace in place
                        $newOpt = "--demuxer-lavf-o=`"$newOptsStr`""
                        $line = $line.Substring(0, $optMatch.Index) + $newOpt + $line.Substring($optMatch.Index + $optMatch.Length)
                    }
                } else {
                    # Parameter missing: insert right after the mpv anchor
                    if ($selectedFormat -ne 'auto') {
                        if ($selectedFormat -eq 'mjpeg' -or $selectedFormat -eq 'h264') {
                            $newOpt = "--demuxer-lavf-o=`"vcodec=$selectedFormat`""
                        } else {
                            $newOpt = "--demuxer-lavf-o=`"pixel_format=$selectedFormat`""
                        }

                        $anchorMatch = [regex]::Match($line, '(?i)start "" /b "%prog1_path%"')
                        if ($anchorMatch.Success) {
                            $insertPos = $anchorMatch.Index + $anchorMatch.Length
                            $line = $line.Substring(0, $insertPos) + " " + $newOpt + $line.Substring($insertPos)
                        }
                    }
                }

                $batLines[$mpvLineIdx] = $line
                [System.IO.File]::WriteAllLines($batPath, $batLines, [System.Text.UTF8Encoding]::new($false))
            }
        }

        # --- Shortcuts ---
        if ($rbScYes.Checked) {
            $targetExe     = Join-Path $root "mpv.exe"
            $icoPath       = Join-Path $root "data\icon\msc-shortcut.ico"
            $desktopFolder = [Environment]::GetFolderPath("Desktop")

            Ensure-Shortcut (Join-Path $desktopFolder "MPV-SW-Capture.lnk") $targetExe $root $icoPath
            Ensure-Shortcut (Join-Path $root "MPV-SW-Capture.lnk")          $targetExe $root $icoPath
        }

        $script:LastStatusState = "done"
        $lStatus.ForeColor = $script:SUCCESS
        $lStatus.Text = (T "DoneStatus")

        [System.Windows.Forms.MessageBox]::Show(
            (T "DoneMsg"), (T "DoneTitle"),
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        $script:LastStatusState = "custom_error"
        $script:LastErrorText   = $_.Exception.Message
        $lStatus.ForeColor = $script:ERROR_C
        $lStatus.Text = [string]::Format((T "ErrStatus"), $script:LastErrorText)
    }
})

# ============================================================
#  INIT
# ============================================================
# Populate the menu-language ComboBox from language_list.dat
$menuLangs = Get-AvailableMenuLanguages
$cbMenuLang.Items.Clear()
foreach ($l in $menuLangs) { [void]$cbMenuLang.Items.Add($l.ToUpper()) }
Select-MenuLanguageCombo (Get-MenuLanguage)

# Load current audio mode setting (default: WASAPI / "plugin")
if ((Get-AudioModeSetting) -eq "ffplay") {
    $rbAudioModeFfplay.Checked = $true
} else {
    $rbAudioModeWasapi.Checked = $true
}

# Load current hover volume setting (default: No)
if ((Get-HoverVolumeSetting) -eq "yes") {
    $rbHoverVolumeYes.Checked = $true
} else {
    $rbHoverVolumeNo.Checked = $true
}

# Load WASAPI period, buffer size, zero-fill and input format from .bat
$periodMode = "minimum"
$batPath = Join-Path $script:RootDir "data\MPV-SW-Capture.bat"
if (Test-Path $batPath) {
    try {
        $batContent = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)

        # Period mode
        if ($batContent -match 'set "MSC_AUDIO_PERIOD=([^"]*)"') {
            $candidate = $matches[1].Trim().ToLower()
            if ($candidate -in @("minimum","fundamental","default","maximum")) {
                $periodMode = $candidate
            }
        }

        # Buffer size (12, 20, 25, 30, 50, 100)
        if ($batContent -match 'set "MSC_AUDIO_BUFFER_MS=([^"]*)"') {
            $bufVal = $matches[1].Trim()
            switch ($bufVal) {
                "12"  { $cbBufferSize.SelectedIndex = 0 }
                "20"  { $cbBufferSize.SelectedIndex = 1 }
                "25"  { $cbBufferSize.SelectedIndex = 2 }
                "30"  { $cbBufferSize.SelectedIndex = 3 }
                "50"  { $cbBufferSize.SelectedIndex = 4 }
                "100" { $cbBufferSize.SelectedIndex = 5 }
                default { $cbBufferSize.SelectedIndex = 2 }
            }
        }

        # Zero fill (default Pop = 0)
        if ($batContent -match 'set "MSC_AUDIO_ZERO_FILL=([^"]*)"') {
            if ($matches[1].Trim() -eq "1") { $rbZeroFillSilence.Checked = $true }
            else { $rbZeroFillPop.Checked = $true }
        } else {
            $rbZeroFillPop.Checked = $true
        }

        # Input Video Format (vcodec or pixel_format)
        $formatVal = "auto"
        if ($batContent -match '(?i)--demuxer-lavf-o(?:ptions)?=(?:"([^"]*)"|([^\s]+))') {
            $optsStr = if ($matches[1]) { $matches[1] } else { $matches[2] }
            if ($optsStr -match '(?i)(?:^|,)\s*vcodec\s*=\s*([^,]+)') { $formatVal = $matches[1].Trim() }
            elseif ($optsStr -match '(?i)(?:^|,)\s*pixel_format\s*=\s*([^,]+)') { $formatVal = $matches[1].Trim() }
        }
        if ($cbVideoFormat.Items.Contains($formatVal)) { $cbVideoFormat.SelectedItem = $formatVal }
        else { $cbVideoFormat.SelectedIndex = 0 }

    } catch {}
}

switch ($periodMode) {
    "minimum"     { $rbPeriodMin.Checked  = $true }
    "fundamental" { $rbPeriodFund.Checked = $true }
    "maximum"     { $rbPeriodMax.Checked  = $true }
    default       { $rbPeriodMin.Checked  = $true }
}

# Load record time from menu.conf
$menuConfPath = Join-Path $script:RootDir "menu.conf"
if (Test-Path $menuConfPath) {
    try {
        $mc = [System.IO.File]::ReadAllText($menuConfPath, [System.Text.Encoding]::UTF8)
        if ($mc -match 'Limit=(\d+) Sec') {
            switch ($matches[1]) {
                "30"  { $rbRec30.Checked  = $true }
                "60"  { $rbRec60.Checked  = $true }
                "90"  { $rbRec90.Checked  = $true }
                "120" { $rbRec120.Checked = $true }
            }
        }
    } catch {}
}

$savedLang = Load-GUILanguage
Apply-Lang $savedLang

[System.Windows.Forms.Application]::Run($form)