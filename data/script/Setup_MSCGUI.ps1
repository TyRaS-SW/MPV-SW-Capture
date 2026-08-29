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
        $root = Split-Path -Parent (Split-Path -Parent $scriptDir)
        return $root
    }
    return $scriptDir
}
$script:RootDir = Get-RootDir
$script:SD = $script:RootDir

# ============================================================
#  LANGUAGE PERSISTENCE
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

$FontTitle        = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$FontSub          = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Regular)
$FontBold         = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Bold)
$FontBtn          = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontSmall        = New-Object System.Drawing.Font("Segoe UI",  8, [System.Drawing.FontStyle]::Regular)
$FontNote         = New-Object System.Drawing.Font("Segoe UI",  9, [System.Drawing.FontStyle]::Regular)
$FontSectionTitle = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontLangBtn      = New-Object System.Drawing.Font("Segoe UI",  11, [System.Drawing.FontStyle]::Bold)
$FontSmallBold    = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)

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
    S1NoFfplay  = "ffplay not found. Check your PATH."

    S2Title     = "SELECT DATE FORMAT FOR FILE NAMES IN SCREENSHOTS AND RECORDS"
    S2Opt1      = "Japan / Korea  (yyyy-MM-dd)"
    S2Opt2      = "Latin America / Europe  (dd-MM-yyyy)"
    S2Opt3      = "USA / Canada  (MM-dd-yyyy)"

    S3Title     = "CHOOSE IF YOU WANT TO AUTO START SPECIAL SHADERS ON MPV-SW-CAPTURE"
    S3Yes       = "Yes  - Start MPV with Special Shaders activated  (1080p-4K Fast)"
    S3No        = "No   - Start MPV without Shaders  (Capture Card default)"
    S3Note      = "Note: This Special Shader improves your image quality without affecting your resources, and is highly recommended. But, if you notice that the Shader is producing lag or simply you don't want it, select No."

    S4Title     = "CHANGE DEFAULT RECORD VIDEO TIME"
    S4Note      = "Note: You need around 7-10 GB of disk space to record 30 seconds. If you increase to 1 minute, you need twice the disk space. This is temporary space required to successfully create the video, or it will fail. The temporary files auto-delete after creating the compressed video."
    S4Opt1      = " 30 seconds  -  7-10 GB disk space  (Default)"
    S4Opt2      = " 60 seconds  -  14-20 GB disk space"
    S4Opt3      = " 90 seconds  -  21-30 GB disk space"
    S4Opt4      = "120 seconds  -  28-40 GB disk space"

    S5Title     = "OTHER OPTIONS FOR MPV-SW-Capture"
    S5Shorcut   = "CREATE DESKTOP AND LOCAL SHORTCUTS"
    S5IccTitle  = "AUTOSTART WITH YOUR ICC PROFILE"
    S5OsdTitle  = "AUTOSTART HIDE OSD MESSAGES (Streamer Mode)"
    S5BorderTitle = "AUTOSTART WINDOW BORDER+TITLE BAR"
    S5AutoCheckTitle = "AUTO-CHECK FOR UPDATES ON STARTUP"
    S5No        = "No"
    S5Yes       = "Yes"
    S5BorderOnly = "Only border"
    S5BorderBoth = "Border+T.Bar"

    StatusReady = "Ready. Scan devices then click Apply Setup."
    ApplyBtn    = "Apply Setup"
    ErrSelect   = "Select video and audio devices first!"
    DoneMsg     = "Setup applied successfully!`n`nFiles updated:`n  - MPV-SW-Capture.bat`n  - scripts\usb3.lua`n  - mpv.conf`n  - scripts\autocompress.lua`n  - scripts\shader_init.lua`n  - menu.conf`n  - scripts\record.lua`n`nIf shortcut creation was enabled, shortcuts for MPV-SW-Capture were also created on the Desktop and in the root folder."
    DoneTitle   = "MPV-SW-Capture Setup"
    DoneStatus  = "Setup complete! All files updated."
    ErrStatus   = "Error: {0}"

    FfplayFound    = "ffplay.exe: Found!"
    FfplayNotFound = "ffplay.exe: NOT Found!"
    MenuFound      = "menu.conf: Found!"
    MenuNotFound   = "menu.conf: NOT Found!"
    MenuToSpanish  = "MENU translated to Spanish!"
    MenuToEnglish  = "MENU translated to English!"
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
    S1NoFfplay  = "ffplay no encontrado. Revisa tu PATH."

    S2Title     = "SELECCIONA EL FORMATO DE FECHA PARA CAPTURAS Y GRABACIONES"
    S2Opt1      = "Japon / Corea  (yyyy-MM-dd)"
    S2Opt2      = "Latinoamerica / Europa  (dd-MM-yyyy)"
    S2Opt3      = "EE.UU. / Canada  (MM-dd-yyyy)"

    S3Title     = "ELIGE SI QUIERES INICIAR AUTOMATICAMENTE LOS SHADERS EN MPV-SW-CAPTURE"
    S3Yes       = "Si   - Iniciar MPV con Shaders Especiales activados (1080p-4K Fast)"
    S3No        = "No   - Iniciar MPV sin Shaders Especiales (por defecto de la tarjeta de captura)"
    S3Note      = "Nota: Este Shader especial mejora la calidad de imagen sin afectar casi los recursos, y es altamente recomendado. Pero si notas que produce lag o simplemente no lo quieres, selecciona No."

    S4Title     = "CAMBIAR EL TIEMPO DE GRABACION DE VIDEO"
    S4Note      = "Nota: Necesitas alrededor de 7-10 GB de espacio en disco para grabar 30 segundos. Si aumentas a 1 minuto, necesitas el doble. Este espacio temporal es requerido para crear el video correctamente, o fallara. Los archivos temporales se auto-eliminan tras comprimir el video."
    S4Opt1      = " 30 segundos  -  7-10 GB de espacio en disco  (Por defecto)"
    S4Opt2      = " 60 segundos  -  14-20 GB de espacio en disco"
    S4Opt3      = " 90 segundos  -  21-30 GB de espacio en disco"
    S4Opt4      = "120 segundos  -  28-40 GB de espacio en disco"

    S5Title     = "OTRAS OPCIONES PARA MPV-SW-Capture"
    S5Shorcut   = "CREAR ACCESOS DIRECTOS EN EL ESCRITORIO Y LOCAL"
    S5IccTitle  = "INICIO AUTOMATICO CON TU PERFIL ICC"
    S5OsdTitle  = "OCULTAR MENSAJES OSD AL INICIO (Modo Streamer)"
    S5BorderTitle = "BORDE VENTANA+BARRA DE TITULO AL INICIO"
    S5AutoCheckTitle = "VERIFICAR ACTUALIZACIONES AL INICIO"
    S5No        = "No"
    S5Yes       = "Si"
    S5BorderOnly = "Solo borde"
    S5BorderBoth = "Borde+Barra T."

    StatusReady = "Listo. Busca dispositivos y luego haz clic en Aplicar."
    ApplyBtn    = "Aplicar"
    ErrSelect   = "Selecciona los dispositivos de video y audio primero!"
    DoneMsg     = "Configuracion aplicada correctamente!`n`nArchivos actualizados:`n  - MPV-SW-Capture.bat`n  - scripts\usb3.lua`n  - mpv.conf`n  - scripts\autocompress.lua`n  - scripts\shader_init.lua`n  - menu.conf`n  - scripts\record.lua`n`nSi la opcion de acceso directo estaba activada, tambien se crearon accesos directos de MPV-SW-Capture en el Escritorio y en la carpeta raiz."
    DoneTitle   = "Configuracion MPV-SW-Capture"
    DoneStatus  = "Configuracion completa! Todos los archivos actualizados."
    ErrStatus   = "Error: {0}"

    FfplayFound    = "ffplay.exe: Encontrado!"
    FfplayNotFound = "ffplay.exe: NO Encontrado!"
    MenuFound      = "menu.conf: Encontrado!"
    MenuNotFound   = "menu.conf: NO Encontrado!"
    MenuToSpanish  = "MENU traducido al Espanol!"
    MenuToEnglish  = "MENU traducido al Ingles!"
}

$script:CurrentLang = "EN"
$script:LastVideoCount = $null
$script:LastAudioCount = $null
$script:LastScanState  = "none"
$script:LastStatusState = "ready"
$script:LastErrorText   = ""

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

function Get-AppDir {
    return $script:RootDir
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
#  FUNCIÓN PARA ACTUALIZAR current_lang EN SCRIPTS LUA
# ============================================================
function Set-ScriptLanguage([string]$path, [string]$lang, [System.Text.Encoding]$enc) {
    # Si el archivo no existe, lo creamos con la línea current_lang
    if (-not (Test-Path $path)) {
        $langValue = if ($lang -eq "ES") { "es" } else { "en" }
        $content = "local current_lang = `"$langValue`"`r`n`r`n"
        [System.IO.File]::WriteAllText($path, $content, $enc)
        return
    }
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $langValue = if ($lang -eq "ES") { "es" } else { "en" }
    $pattern = 'local\s+current_lang\s*=\s*"(?:en|es)"'
    $replace = 'local current_lang = "' + $langValue + '"'
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, $replace, 1)
    } else {
        # Si no existe, insertar al principio
        $content = 'local current_lang = "' + $langValue + '"' + "`r`n" + $content
    }
    [System.IO.File]::WriteAllText($path, $content, $enc)
}

# ============================================================
#  FORM & CARDS
# ============================================================
$formW   = 1140
$formH   = 550
$headerH = 68

$leftX   = 20
$cardW   = 550
$colGap  = 16
$rightX  = $leftX + $cardW + $colGap

$row1Y   = 10
$row2Y   = 170
$row3Y   = 380

$cTopH    = 150
$cMidH    = 200
$cBottomH = 92

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

$FontHeaderNote = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$lHeaderNote = New-Lbl (T "HeaderNote") 710 38 470 18 $FontHeaderNote $script:ACCENT3

$script:EXE_OK  = [System.Drawing.Color]::FromArgb(50, 160, 80)
$script:EXE_ERR = [System.Drawing.Color]::FromArgb(180, 50, 50)

function Get-FfplayStatus {
    if (Test-Path (Join-Path $script:RootDir "ffplay.exe")) { return (T "FfplayFound"), $script:EXE_OK }
    else { return (T "FfplayNotFound"), $script:EXE_ERR }
}
function Get-MenuStatus {
    if (Test-Path (Join-Path $script:RootDir "menu.conf")) { return (T "MenuFound"), $script:EXE_OK }
    else { return (T "MenuNotFound"), $script:EXE_ERR }
}

$lExeFFplay   = New-Lbl "" 520 18 220 16 $FontSmall $script:EXE_OK
$lExeMenuConf = New-Lbl "" 520 36 220 16 $FontSmall $script:EXE_OK

$pHeader.Controls.AddRange(@($lAppTitle,$lAppSub,$lLangLbl,$btnEN,$btnES,$lHeaderNote,$lExeFFplay,$lExeMenuConf))
$form.Controls.Add($pHeader)

$pMain = New-Pnl 0 $headerH $formW ($formH-$headerH) $script:BG
$form.Controls.Add($pMain)

$card1 = New-CardXY $pMain $leftX  $row1Y $cardW $cTopH    "S1Title" $null    $false
$card2 = New-CardXY $pMain $leftX  $row3Y $cardW $cBottomH "S2Title" $null $false
$card3 = New-CardXY $pMain $rightX $row1Y $cardW $cTopH    "S3Title" $null    $false
$card4 = New-CardXY $pMain $rightX $row2Y $cardW $cMidH    "S4Title" $null    $false
$card5 = New-CardXY $pMain $leftX  $row2Y $cardW $cMidH    "S5Title" $null    $false
$card6 = New-CardXY $pMain $rightX $row3Y $cardW $cBottomH "ActionsTitle" $null $false

$card1.Tag="S1"
$card2.Tag="S2"
$card3.Tag="S3"
$card4.Tag="S4"
$card5.Tag="S5"
$card6.Tag="ACT"

# --- Card 1: Devices ---
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

# --- Card 2: Date Format ---
$rbEU  = New-RB (T "S2Opt2") 14 30 500
$rbISO = New-RB (T "S2Opt1") 14 50 500
$rbUS  = New-RB (T "S2Opt3") 14 70 500
$rbEU.Checked = $true
$card2.Controls.AddRange(@($rbEU,$rbISO,$rbUS))

# --- Card 3: Shaders ---
$lS3Note = New-Object System.Windows.Forms.Label
$lS3Note.Text        = T "S3Note"
$lS3Note.Location    = [System.Drawing.Point]::new(14,34)
$lS3Note.Size        = [System.Drawing.Size]::new(530,0)
$lS3Note.Font        = $FontNote
$lS3Note.ForeColor   = $script:NOTE_C
$lS3Note.BackColor   = [System.Drawing.Color]::Transparent
$lS3Note.AutoSize    = $true
$lS3Note.MaximumSize = [System.Drawing.Size]::new(530,0)
$card3.Controls.Add($lS3Note)

$rbShOn  = New-RB (T "S3Yes") 14 100 520
$rbShOff = New-RB (T "S3No")  14 124 520
$rbShOn.Checked = $true
$card3.Controls.AddRange(@($rbShOn,$rbShOff))

# --- Card 4: Record Time ---
$lS4Note = New-Object System.Windows.Forms.Label
$lS4Note.Text        = T "S4Note"
$lS4Note.Location    = [System.Drawing.Point]::new(14,34)
$lS4Note.Size        = [System.Drawing.Size]::new(530,0)
$lS4Note.Font        = $FontNote
$lS4Note.ForeColor   = $script:NOTE_C
$lS4Note.BackColor   = [System.Drawing.Color]::Transparent
$lS4Note.AutoSize    = $true
$lS4Note.MaximumSize = [System.Drawing.Size]::new(530,0)
$card4.Controls.Add($lS4Note)

$rbR30  = New-RB (T "S4Opt1") 14 100 520
$rbR60  = New-RB (T "S4Opt2") 14 124 520
$rbR90  = New-RB (T "S4Opt3") 14 148 520
$rbR120 = New-RB (T "S4Opt4") 14 172 520
$rbR30.Checked = $true
$card4.Controls.AddRange(@($rbR30,$rbR60,$rbR90,$rbR120))

# --- Card 5: Other Options ---
$pnlSc = New-Pnl 14 28 520 26 $script:CARD
$lScLabel = New-Lbl (T "S5Shorcut") 0 5 320 16 $FontSmallBold $script:ACCENT3
$rbScNo   = New-RB (T "S5No")  320 3 50
$rbScYes  = New-RB (T "S5Yes") 420 3 50
$rbScYes.Checked = $true
$pnlSc.Controls.AddRange(@($lScLabel, $rbScNo, $rbScYes))

$pnlIcc = New-Pnl 14 52 520 26 $script:CARD
$lIccLabel = New-Lbl (T "S5IccTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbIccNo   = New-RB (T "S5No")  320 3 50
$rbIccYes  = New-RB (T "S5Yes") 420 3 50
$rbIccNo.Checked = $true
$pnlIcc.Controls.AddRange(@($lIccLabel, $rbIccNo, $rbIccYes))

$pnlOsd = New-Pnl 14 76 520 26 $script:CARD
$lOsdLabel = New-Lbl (T "S5OsdTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbOsdNo   = New-RB (T "S5No")  320 3 50
$rbOsdYes  = New-RB (T "S5Yes") 420 3 50
$rbOsdNo.Checked = $true
$pnlOsd.Controls.AddRange(@($lOsdLabel, $rbOsdNo, $rbOsdYes))

$pnlBorder = New-Pnl 14 100 520 26 $script:CARD
$lBorderLabel = New-Lbl (T "S5BorderTitle") 0 5 260 16 $FontSmallBold $script:ACCENT3
$rbBorderNo   = New-RB (T "S5No")        265 3 50
$rbBorderOnly = New-RB (T "S5BorderOnly") 320 3 100
$rbBorderBoth = New-RB (T "S5BorderBoth") 420 3 110
$rbBorderNo.Checked = $true
$pnlBorder.Controls.AddRange(@($lBorderLabel, $rbBorderNo, $rbBorderOnly, $rbBorderBoth))

$pnlAutoCheck = New-Pnl 14 124 520 26 $script:CARD
$lAutoCheckLabel = New-Lbl (T "S5AutoCheckTitle") 0 5 300 16 $FontSmallBold $script:ACCENT3
$rbAutoCheckNo   = New-RB (T "S5No")  320 3 50
$rbAutoCheckYes  = New-RB (T "S5Yes") 420 3 50
$rbAutoCheckNo.Checked = $true
$pnlAutoCheck.Controls.AddRange(@($lAutoCheckLabel, $rbAutoCheckNo, $rbAutoCheckYes))

$card5.Controls.AddRange(@($pnlSc, $pnlIcc, $pnlOsd, $pnlBorder, $pnlAutoCheck))

# --- Card 6: Actions ---
$btnMenuToggle = New-Object System.Windows.Forms.Button
$btnMenuToggle.Text     = "MENU: English <-> Espanol"
$btnMenuToggle.Location = [System.Drawing.Point]::new(14,36)
$btnMenuToggle.Size     = [System.Drawing.Size]::new(220,40)
Style-Btn $btnMenuToggle $script:ACCENT3 $script:BG
$btnMenuToggle.Font = $FontBtn

$lStatus = New-Lbl (T "StatusReady") 244 28 150 50 $FontSub $script:MUTED

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = (T "ApplyBtn")
$btnApply.Location = [System.Drawing.Point]::new(402,36)
$btnApply.Size     = [System.Drawing.Size]::new(120,40)
Style-Btn $btnApply $script:ACCENT2 $script:BG
$card6.Controls.AddRange(@($btnMenuToggle,$lStatus,$btnApply))

# ============================================================
#  LANGUAGE SWITCH
# ============================================================
function Apply-Lang([string]$lang) {
    $script:CurrentLang = $lang
    Style-LangBtn $btnEN ($lang -eq "EN")
    Style-LangBtn $btnES ($lang -eq "ES")

    $form.Text = T 'Title'
    $lAppSub.Text     = T "HeaderSub"
    $lLangLbl.Text    = T "LangLabel"
    $lHeaderNote.Text = T "HeaderNote"

    $card1.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S1Title" }
    $card2.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S2Title" }
    $card3.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S3Title" }
    $card4.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S4Title" }
    $card5.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "S5Title" }
    $card6.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] -and $_.Font.Bold -and $_.Font.Size -eq $FontSectionTitle.Size } | ForEach-Object { $_.Text = T "ActionsTitle" }

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
        "no_ffplay" {
            $lScanStatus.ForeColor = $script:ERROR_C
            $lScanStatus.Text = T "S1NoFfplay"
        }
        default { $lScanStatus.Text = "" }
    }

    $rbISO.Text   = T "S2Opt1"
    $rbEU.Text    = T "S2Opt2"
    $rbUS.Text    = T "S2Opt3"

    $lS3Note.Text = T "S3Note"
    $rbShOn.Text  = T "S3Yes"
    $rbShOff.Text = T "S3No"

    $lS4Note.Text = T "S4Note"
    $rbR30.Text   = T "S4Opt1"
    $rbR60.Text   = T "S4Opt2"
    $rbR90.Text   = T "S4Opt3"
    $rbR120.Text  = T "S4Opt4"

    $lScLabel.Text      = T "S5Shorcut"
    $lIccLabel.Text     = T "S5IccTitle"
    $lOsdLabel.Text     = T "S5OsdTitle"
    $lBorderLabel.Text  = T "S5BorderTitle"
    $lAutoCheckLabel.Text = T "S5AutoCheckTitle"
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

    switch ($script:LastStatusState) {
        "ready"          { $lStatus.ForeColor = $script:MUTED;   $lStatus.Text = T "StatusReady" }
        "menu_not_found" { $lStatus.ForeColor = $script:ERROR_C; $lStatus.Text = T "MenuNotFound" }
        "menu_to_es"     { $lStatus.ForeColor = $script:SUCCESS; $lStatus.Text = T "MenuToSpanish" }
        "menu_to_en"     { $lStatus.ForeColor = $script:SUCCESS; $lStatus.Text = T "MenuToEnglish" }
        "done"           { $lStatus.ForeColor = $script:SUCCESS; $lStatus.Text = T "DoneStatus" }
        "err_select"     { $lStatus.ForeColor = $script:ERROR_C; $lStatus.Text = T "ErrSelect" }
        "custom_error"   { $lStatus.ForeColor = $script:ERROR_C; $lStatus.Text = [string]::Format((T "ErrStatus"), $script:LastErrorText) }
        default          { $lStatus.ForeColor = $script:MUTED;   $lStatus.Text = T "StatusReady" }
    }

    $btnApply.Text = T "ApplyBtn"

    $ffText, $ffColor = Get-FfplayStatus
    $lExeFFplay.Text = $ffText
    $lExeFFplay.ForeColor = $ffColor

    $menuText, $menuColor = Get-MenuStatus
    $lExeMenuConf.Text = $menuText
    $lExeMenuConf.ForeColor = $menuColor

    $form.Refresh()
}

# ============================================================
#  EVENTOS
# ============================================================
$btnEN.Add_Click({
    Apply-Lang "EN"
    Save-GUILanguage "EN"
})
$btnES.Add_Click({
    Apply-Lang "ES"
    Save-GUILanguage "ES"
})

$btnScan.Add_Click({
    $script:LastScanState = "scanning"
    $lScanStatus.ForeColor = $script:MUTED
    $lScanStatus.Text = (T "S1Scanning")
    $form.Refresh()

    $tmpFile = [System.IO.Path]::GetTempFileName()

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

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        $content = ($stdout + "`r`n" + $stderr)
        [System.IO.File]::WriteAllText($tmpFile, $content, [System.Text.Encoding]::UTF8)

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
        $script:LastScanState = "no_ffplay"
        $script:LastVideoCount = $null; $script:LastAudioCount = $null
        $lScanStatus.ForeColor = $script:ERROR_C
        $lScanStatus.Text = ((T "S1NoFfplay") + " " + $_.Exception.Message)
    }
    finally {
        if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }
    }
})

# ============================================================
#  BOTÓN MENU (con las nuevas traducciones y tools_launcher)
# ============================================================
$btnMenuToggle.Add_Click({
    $menuPath = Join-Path $script:RootDir "menu.conf"
    if (-not (Test-Path $menuPath)) {
        $script:LastStatusState = "menu_not_found"
        $lStatus.ForeColor = $script:ERROR_C
        $lStatus.Text = T "MenuNotFound"
        return
    }

    $utf8 = New-Object System.Text.UTF8Encoding $false
    $menu = [System.IO.File]::ReadAllText($menuPath, [System.Text.Encoding]::UTF8)

    # Mapas de traducción (incluyendo las nuevas claves de TOOLS)
    $mapEN = @{
        'CERRAR MPV-SW-Capture'='CLOSE MPV-SW-Capture'; 'Videojuegos'='VideoGame'; 'Rellenar Ventana'='Fill Screen'; 'Solo Nitidez'='Only Sharpen'; 'Limpiar Shaders'='Clean Shaders'; 'AYUDA'='HELP'; 'RECORTES'='CROPS'; 'Borrar Recorte'='Clear Crop'; 'Recorte Eliminado'='Crop Cleared'
        'MARCOS'='BEZELS'; 'Borrar Marcos'='Clear Bezels'; 'Marcos Eliminados'='Bezels Cleared'
        'VENTANA'='WINDOW'; 'TAMANO'='SIZE'; 'Pantalla Completa'='Fullscreen'; 'POSICION'='POSITION'
        'Arriba Izquierda'='Top Left'; 'Arriba Derecha'='Top Right'; 'Arriba Centro'='Top Center'
        'Centro Izquierda'='Center Left'; 'Centro Derecha'='Center Right'; 'Abajo Centro'='Bottom Center'
        'Abajo Izquierda'='Bottom Left'; 'Abajo Derecha'='Bottom Right'; 'Siempre Visible'='Always On Top'
        'Estirar Ventana'='Stretch Window'; 'Modo Mini'='Mini Mode'; '"Modo Mini"'='"Mini Mode"'
        'CAPTURA'='CAPTURE'; 'Capturar Imagen'='Take Screenshot'; 'Grabar Video'='Record Video'
        'AUDIO'='AUDIO'; 'Silenciar/Activar sonido'='Mute/Unmute'
        'OPCIONES DE VIDEO'='VIDEO OPTIONS'; 'VIDEO'='VIDEO'; 'Cambiar a Perfil ICC Automatico'='Change to Auto ICC Profile'; 'Alternar Deband'='Toggle Deband'
        'Deband:'='Deband:'; 'Alternar Desentrelazado'='Toggle Deinterlace'; 'Desentrelazado:'='Deinterlace:'
        'Bordes'='Borders'
        'OTROS'='OTHERS'; 'Limpiar TODO'='Clean ALL'; '"Limpiando TODO"'='"Cleaning ALL"'
        'Informacion de Stream'='Info Stream'; 'CENTRO'='CENTER'; 'Especial'='Special'
        'FORMAS'='SHAPES'; 'Interpolacion de Movimiento'='Motion Interpolation'; 'Limpiar Forma'='Clean Shape'; 'Forma Limpiada'='Shape Cleared'
        'Curvatura'='Curvature'; 'Orillas Oscuras'='Edge Darkening'
        'Barril Ancho'='Wide Barrel'; 'Esquinas Redondeadas'='Rounded Corners'
        'Inclinado'='Tilted'; 'Invertido'='Inverted'
        'Perspectiva Pinball'='Pinball Perspective';
        'Keystone Hacia Adentro (Zoom Inferior Bajo)'='Inward Keystone (Low Bottom Zoom)'
        'ROTACION'='ROTATION'; 'Girar a la Derecha'='Rotate Clockwise'; 'Girar a la Izquierda'='Rotate Counter-Clockwise'; 'Restablecer Rotacion'='Reset Rotation'; 'OTRAS OPCIONES'='OTHER OPTIONS'; 'Borde de Ventana'='Window Border'; 'Barra de Titulo'='Title Bar'; 'Quitar TODO'='Remove ALL'; 'Girado +90°'='Rotated +90°'; 'Girado -90°'='Rotated -90°'; 'Rotacion Reiniciada'='Rotation Reset'; 'Borde: ${border}'='Border: ${border}'; 'Barra de Titulo: ${border}'='Title Bar: ${border}'; 'Ambos Quitados'='Removed Both'; 'Ocultar Mensajes OSD'='Hide OSD Messages'; 'Espejo OFF'='Mirror OFF'; 'Espejo ON'='Mirror ON'; 'Modo Espejo'='Mirror Mode'; 'Revisa la Ultima Version de MSC'='Check Latest MSC Version'; 'Abre la Web de MPV-SW-Capture'='Open MPV-SW-Capture Website'; 'Discord de MPV-SW-Capture'='MPV-SW-Capture Discord'; 'Abriendo sitio web...'='Opening website...'; 'Abriendo Discord...'='Opening Discord...'; 'https://tyras-sw.github.io/MPV-SW-Capture/?lang=es'='https://tyras-sw.github.io/MPV-SW-Capture/'
        # Traducciones para TOOLS
        'HERRAMIENTAS'='TOOLS'
        'Abrir Administrador Marcos'='Open Bezel Manager'
        'Abrir Administrador de Video'='Open Video Manager'
        'Abrir Asistente de Stream'='Open Stream Helper'
    }

    $mapES = @{
        'CLOSE MPV-SW-Capture'='CERRAR MPV-SW-Capture'; 'VideoGame'='Videojuegos'; 'Fill Screen'='Rellenar Ventana'; 'Only Sharpen'='Solo Nitidez'; 'Clean Shaders'='Limpiar Shaders'; 'HELP'='AYUDA'; 'CROPS'='RECORTES'; 'Clear Crop'='Borrar Recorte'; 'Crop Cleared'='Recorte Eliminado'
        'BEZELS'='MARCOS'; 'Clear Bezels'='Borrar Marcos'; 'Bezels Cleared'='Marcos Eliminados'
        'WINDOW'='VENTANA'; 'SIZE'='TAMANO'; 'Fullscreen'='Pantalla Completa'; 'POSITION'='POSICION'
        'Top Left'='Arriba Izquierda'; 'Top Right'='Arriba Derecha'; 'Top Center'='Arriba Centro'
        'Center Left'='Centro Izquierda'; 'Center Right'='Centro Derecha'; 'Bottom Center'='Abajo Centro'
        'Bottom Left'='Abajo Izquierda'; 'Bottom Right'='Abajo Derecha'; 'Always On Top'='Siempre Visible'
        'Stretch Window'='Estirar Ventana'; 'Mini Mode'='Modo Mini'; '"Mini Mode"'='"Modo Mini"'
        'CAPTURE'='CAPTURA'; 'Take Screenshot'='Capturar Imagen'; 'Record Video'='Grabar Video'
        'AUDIO'='AUDIO'; 'Mute/Unmute'='Silenciar/Activar sonido'
        'VIDEO OPTIONS'='OPCIONES DE VIDEO'; 'VIDEO'='VIDEO'; 'Change to Auto ICC Profile'='Cambiar a Perfil ICC Automatico'; 'Toggle Deband'='Alternar Deband'
        'Deband:'='Deband:'; 'Toggle Deinterlace'='Alternar Desentrelazado'; 'Deinterlace:'='Desentrelazado:'
        'Borders'='Bordes'
        'OTHERS'='OTROS'; 'Clean ALL'='Limpiar TODO'; '"Cleaning ALL"'='"Limpiando TODO"'
        'Info Stream'='Informacion de Stream'; 'CENTER'='CENTRO'; 'Special'='Especial'
        'SHAPES'='FORMAS'; 'Motion Interpolation'='Interpolacion de Movimiento'; 'Clean Shape'='Limpiar Forma'; 'Shape Cleared'='Forma Limpiada'
        'Curvature'='Curvatura'; 'Edge Darkening'='Orillas Oscuras'
        'Wide Barrel'='Barril Ancho'; 'Rounded Corners'='Esquinas Redondeadas'
        'Tilted'='Inclinado'; 'Inverted'='Invertido'
        'Pinball Perspective'='Perspectiva Pinball';
        'Inward Keystone (Low Bottom Zoom)'='Keystone Hacia Adentro (Zoom Inferior Bajo)'
        'ROTATION'='ROTACION'; 'Rotate Clockwise'='Girar a la Derecha'; 'Rotate Counter-Clockwise'='Girar a la Izquierda'; 'Reset Rotation'='Restablecer Rotacion'; 'OTHER OPTIONS'='OTRAS OPCIONES'; 'Window Border'='Borde de Ventana'; 'Title Bar'='Barra de Titulo'; 'Remove ALL'='Quitar TODO'; 'Rotated +90°'='Girado +90°'; 'Rotated -90°'='Girado -90°'; 'Rotation Reset'='Rotacion Reiniciada'; 'Border: ${border}'='Borde: ${border}'; 'Title Bar: ${border}'='Barra de Titulo: ${border}'; 'Removed Both'='Ambos Quitados'; 'Hide OSD Messages'='Ocultar Mensajes OSD'; 'Mirror OFF'='Espejo OFF'; 'Mirror ON'='Espejo ON'; 'Mirror Mode'='Modo Espejo'; 'Check Latest MSC Version'='Revisa la Ultima Version de MSC'; 'Open MPV-SW-Capture Website'='Abre la Web de MPV-SW-Capture'; 'MPV-SW-Capture Discord'='Discord de MPV-SW-Capture'; 'Opening website...'='Abriendo sitio web...'; 'Opening Discord...'='Abriendo Discord...'; 'https://tyras-sw.github.io/MPV-SW-Capture/'='https://tyras-sw.github.io/MPV-SW-Capture/?lang=es'
        # Traducciones para TOOLS
        'TOOLS'='HERRAMIENTAS'
        'Open Bezel Manager'='Abrir Administrador Marcos'
        'Open Video Manager'='Abrir Administrador de Video'
        'Open Stream Helper'='Abrir Asistente de Stream'
    }

    # Detectar si el menú está en inglés o español (usando palabras clave)
    $englishHits = 0
    $spanishHits = 0

    foreach ($probe in @('VideoGame','Only Sharpen','Clean Shaders','VIDEO OPTIONS','Change to Auto ICC Profile','Toggle Deband','Toggle Deinterlace','Other Video Options','Auto ICC')) {
        if ($menu.Contains($probe)) { $englishHits++ }
    }
    foreach ($probe in @('Videojuegos','Solo Nitidez','Limpiar Shaders','OPCIONES DE VIDEO','Cambiar a Perfil ICC Automatico','Alternar Deband','Alternar Desentrelazado','Otras Opciones de Video','ICC Automatico')) {
        if ($menu.Contains($probe)) { $spanishHits++ }
    }

    $isEnglish = $englishHits -ge $spanishHits

    # Traducir el menú
    if ($isEnglish) {
        foreach ($k in $mapES.Keys) { $menu = $menu.Replace($k, $mapES[$k]) }
        [System.IO.File]::WriteAllText($menuPath, $menu, $utf8)
        $script:LastStatusState = "menu_to_es"
        $lStatus.ForeColor = $script:SUCCESS
        $lStatus.Text = T "MenuToSpanish"
    } else {
        foreach ($k in $mapEN.Keys) { $menu = $menu.Replace($k, $mapEN[$k]) }
        [System.IO.File]::WriteAllText($menuPath, $menu, $utf8)
        $script:LastStatusState = "menu_to_en"
        $lStatus.ForeColor = $script:SUCCESS
        $lStatus.Text = T "MenuToEnglish"
    }

    # Actualizar current_lang en los scripts que lo usan
    $langToSet = if ($isEnglish) { "ES" } else { "EN" }

    $scriptsToUpdate = @(
        "scripts\check_version.lua",
        "scripts\mirror_toggle.lua",
        "scripts\autocompress.lua",
        "scripts\shader_init.lua",
        "scripts\tools_launcher.lua"   # <--- NUEVO
    )

    foreach ($relPath in $scriptsToUpdate) {
        $fullPath = Join-Path $script:RootDir $relPath
        Set-ScriptLanguage $fullPath $langToSet $utf8
    }
})

# ============================================================
#  BOTÓN APPLY (sin cambios)
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
    $shMode= if ($rbShOn.Checked) { "enable" } else { "disable" }
    $shInit= if ($shMode -eq "enable") { "SH_4K_1" } else { "none" }
    $recSec= if ($rbR30.Checked) { 30 } elseif ($rbR60.Checked) { 60 } elseif ($rbR90.Checked) { 90 } else { 120 }
    $recLua = $recSec.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)

    $root = $script:RootDir
    $utf8bom = New-Object System.Text.UTF8Encoding $true
    $utf8    = New-Object System.Text.UTF8Encoding $false

    function Update-File([string]$path, [hashtable]$map, [System.Text.Encoding]$enc) {
        if (-not (Test-Path $path)) { return }
        $c = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
        foreach ($k in $map.Keys) { $c = $c -replace $k, $map[$k] }
        [System.IO.File]::WriteAllText($path, $c, $enc)
    }

    try {
        Update-File (Join-Path $root "data\MPV-SW-Capture.bat") @{
            '(SET "video_device=)[^"]*"' = ('${1}' + $vDev + '"')
            '(SET "audio_device=)[^"]*"' = ('${1}' + $aDev + '"')
        } $utf8bom

        Update-File (Join-Path $root "scripts\usb3.lua") @{
            '(data\.video_device\s*=\s*")[^"]*"' = ('${1}' + $vDev + '"')
            '(data\.audio_device\s*=\s*")[^"]*"' = ('${1}' + $aDev + '"')
        } $utf8

        $cf = Join-Path $root "mpv.conf"
        if (Test-Path $cf) {
            $c = [System.IO.File]::ReadAllText($cf, [System.Text.Encoding]::UTF8)
            $c = $c -replace 'screenshot-template=.*', ('screenshot-template="' + $tpl + '"')
            if ($shMode -eq "enable") {
                $c = $c -replace '(?m)^#?(deband=)', '$1'
                $c = $c -replace '(?m)^#?(glsl-shader=)', '$1'
            } else {
                $c = $c -replace '(?m)^#?(deband=)', '#$1'
                $c = $c -replace '(?m)^#?(glsl-shader=)', '#$1'
            }
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

        # --- Actualizar MPV-SW-Capture.bat para borde y barra de título ---
        $batPath = Join-Path $root "data\MPV-SW-Capture.bat"
        if (Test-Path $batPath) {
            $batContent = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)
            
            if ($rbBorderNo.Checked) {
                $borderArg = "--no-border"
                $titleArg = ""
            } elseif ($rbBorderOnly.Checked) {
                $borderArg = "--border"
                $titleArg = "--title-bar=no"
            } else { # $rbBorderBoth.Checked
                $borderArg = "--border"
                $titleArg = ""
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

        # --- Auto-check for updates ---
        $autoCheckVal = if ($rbAutoCheckYes.Checked) { "1" } else { "0" }
        $batPath = Join-Path $root "data\MPV-SW-Capture.bat"
        if (Test-Path $batPath) {
            $batContent = [System.IO.File]::ReadAllText($batPath, [System.Text.Encoding]::UTF8)
            if ($batContent -match '(--script-opts=msc_check_version_auto=\d)') {
                $batContent = $batContent -replace '--script-opts=msc_check_version_auto=\d', ('--script-opts=msc_check_version_auto=' + $autoCheckVal)
            } else {
                $batContent = $batContent -replace '(start "" /b "%prog1_path%.*?)(\s*$|(?= --))', ('$1 --script-opts=msc_check_version_auto=' + $autoCheckVal)
            }
            [System.IO.File]::WriteAllText($batPath, $batContent, [System.Text.Encoding]::UTF8)
        }

        $luaDateFmt = if ($psFmt -eq "yyyy-MM-dd") { "%Y-%m-%d_%H%M%S" } elseif ($psFmt -eq "MM-dd-yyyy") { "%m-%d-%Y_%H%M%S" } else { "%d-%m-%Y_%H%M%S" }
        Update-File (Join-Path $root "scripts\autocompress.lua") @{
            'os\.date\("%[^"]+"\)' = ('os.date("' + $luaDateFmt + '")')
        } $utf8

        # --- Update shader_init.lua ---
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

        # --- Shortcuts ---
        if ($rbScYes.Checked) {
            $targetExe = Join-Path $root "mpv.exe"
            $icoPath   = Join-Path $root "data\icon\msc-shortcut.ico"
            $desktopFolder = [Environment]::GetFolderPath("Desktop")

            function New-Shortcut {
                param([string]$lnkPath, [string]$targetExe, [string]$workingDir, [string]$iconPath)
                try {
                    [ShortcutCreator]::CreateShortcut($lnkPath, $targetExe, $workingDir, $iconPath, 0)
                    return $true
                } catch { return $false }
            }

            $destDesktop = Join-Path $desktopFolder "MPV-SW-Capture.lnk"
            $ok = New-Shortcut $destDesktop $targetExe $root $icoPath
            if (-not $ok) {
                $urlContent = @"
[InternetShortcut]
URL=file:///$($root.Replace('\','/'))/mpv.exe
IconIndex=0
IconFile=$($root)\data\icon\msc-shortcut.ico
"@
                $destDesktopUrl = Join-Path $desktopFolder "MPV-SW-Capture.url"
                [System.IO.File]::WriteAllText($destDesktopUrl, $urlContent, [System.Text.Encoding]::UTF8)
            }

            $destRoot = Join-Path $root "MPV-SW-Capture.lnk"
            $ok = New-Shortcut $destRoot $targetExe $root $icoPath
            if (-not $ok) {
                $urlContent = @"
[InternetShortcut]
URL=file:///$($root.Replace('\','/'))/mpv.exe
IconIndex=0
IconFile=$($root)\data\icon\msc-shortcut.ico
"@
                $destRootUrl = Join-Path $root "MPV-SW-Capture.url"
                [System.IO.File]::WriteAllText($destRootUrl, $urlContent, [System.Text.Encoding]::UTF8)
            }
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
$savedLang = Load-GUILanguage
Apply-Lang $savedLang

[System.Windows.Forms.Application]::Run($form)