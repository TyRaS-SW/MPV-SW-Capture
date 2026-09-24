# StreamMenu_MSC.ps1 - By TyRaS-SW
# External streamer menu for MPV-SW-Capture
# Communicates with a running MPV-SW-Capture instance via named pipe IPC.
# Requires mpv to be launched with --input-ipc-server=\\.\pipe\mpv-sw-capture-socket

Add-Type -AssemblyName PresentationFramework

# ============================================================
# Native interop
# ============================================================
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class StreamMenuNative {
    [DllImport("shell32.dll", SetLastError = true)]
    public static extern void SetCurrentProcessExplicitAppUserModelID(
        [MarshalAs(UnmanagedType.LPWStr)] string AppID);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr LoadImage(IntPtr hinst, string lpszName, uint uType,
                                          int cxDesired, int cyDesired, uint fuLoad);

    public const uint IMAGE_ICON      = 1;
    public const uint LR_LOADFROMFILE = 0x00000010;
    public const uint LR_DEFAULTSIZE  = 0x00000040;
    public const uint WM_SETICON      = 0x0080;
    public const int  ICON_SMALL      = 0;
    public const int  ICON_BIG        = 1;

    // Win32 imports for bringing mpv to the foreground.
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr ProcessId);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    public const int SW_RESTORE = 9;
    public const int SW_SHOW    = 5;

    // Finds the main window of the given process name and brings it to
    // the foreground. If the window is minimized it is restored first.
    // Uses AttachThreadInput, the standard workaround for the Windows
    // foreground lock that otherwise makes SetForegroundWindow silently
    // fail when called from a background process.
    public static bool BringProcessToForeground(string processName) {
        try {
            System.Diagnostics.Process[] procs =
                System.Diagnostics.Process.GetProcessesByName(processName);
            foreach (var p in procs) {
                IntPtr h = p.MainWindowHandle;
                if (h == IntPtr.Zero) continue;
                if (IsIconic(h)) ShowWindow(h, SW_RESTORE);

                IntPtr fg = GetForegroundWindow();
                if (fg == h) return true;

                uint fgThread     = GetWindowThreadProcessId(fg, IntPtr.Zero);
                uint targetThread = GetWindowThreadProcessId(h, IntPtr.Zero);
                uint curThread    = GetCurrentThreadId();

                if (fgThread     != curThread) AttachThreadInput(curThread, fgThread,     true);
                if (targetThread != curThread) AttachThreadInput(curThread, targetThread, true);

                BringWindowToTop(h);
                ShowWindow(h, SW_SHOW);
                bool ok = SetForegroundWindow(h);

                if (targetThread != curThread) AttachThreadInput(curThread, targetThread, false);
                if (fgThread     != curThread) AttachThreadInput(curThread, fgThread,     false);

                return ok;
            }
        } catch { }
        return false;
    }
}
"@

# Native ShellLink COM interop. Supports arguments so the shortcut can
# point at wscript.exe with the VBS path, avoiding the powershell.exe
# console window that appears when a console-subsystem exe is used as
# the shortcut target.
#
# Compiled lazily on first use. Skipping this at startup saves
# ~200-400 ms because Add-Type launches csc.exe as a subprocess for
# each call. The shortcut button is pressed rarely, so paying the cost
# on demand is strictly better than paying it on every launch.
$script:ShortcutCreatorLoaded = $false
function Initialize-ShortcutCreator {
    if ($script:ShortcutCreatorLoaded) { return }
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;

    public static class ShortcutCreator {
        [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
        private class ShellLink { }

        [ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("000214F9-0000-0000-C000-000000000046")]
        private interface IShellLink {
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
        private interface IPersistFile {
            void GetClassID(out Guid pClassID);
            void IsDirty();
            void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, int dwMode);
            void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, bool fRemember);
            void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
            void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
        }

        public static bool Create(string lnkPath, string targetPath, string arguments,
                                  string workingDir, string iconPath, int iconIndex, string description) {
            try {
                Type shellLinkType = Type.GetTypeFromCLSID(new Guid("00021401-0000-0000-C000-000000000046"));
                object shellLink = Activator.CreateInstance(shellLinkType);
                IShellLink link = (IShellLink)shellLink;
                IPersistFile persist = (IPersistFile)shellLink;

                link.SetPath(targetPath);
                if (!string.IsNullOrEmpty(arguments)) link.SetArguments(arguments);
                if (!string.IsNullOrEmpty(workingDir)) link.SetWorkingDirectory(workingDir);
                if (!string.IsNullOrEmpty(iconPath)) link.SetIconLocation(iconPath, iconIndex);
                if (!string.IsNullOrEmpty(description)) link.SetDescription(description);

                persist.Save(lnkPath, true);
                Marshal.ReleaseComObject(shellLink);
                return true;
            } catch {
                return false;
            }
        }
    }
"@
    $script:ShortcutCreatorLoaded = $true
}

try {
    [StreamMenuNative]::SetCurrentProcessExplicitAppUserModelID("TyRaS-SW.MPVSWCapture.StreamMenu")
} catch { }

# ============================================================
# Single instance guard
# ============================================================
$script:SingleInstanceMutex = $null
try {
    $createdNew = $false
    $script:SingleInstanceMutex = New-Object System.Threading.Mutex(
        $true, "MPVSWCapture_StreamMenu_SingleInstance", [ref]$createdNew)
    if (-not $createdNew) { exit 0 }
} catch { }

# ============================================================
# Paths
# ============================================================
$script:RootDir      = (Get-Item (Join-Path $PSScriptRoot "..\..")).FullName
$script:MenuConfPath = Join-Path $script:RootDir "menu.conf"
$script:LangDir      = Join-Path $script:RootDir "data/lang"
$script:OSDLangFile  = Join-Path $script:LangDir "OSDLang.dat"
$script:LangListFile = Join-Path $script:LangDir "language_list.dat"
$script:IconPath     = Join-Path $script:RootDir "data\icon\stmenumsc.ico"
$script:ToolsDir     = Join-Path $script:RootDir "tools"
$script:VbsPath      = Join-Path $script:ToolsDir "MSC_StreamMenu.vbs"

# ============================================================
# Language system
# ============================================================
function Get-CurrentLanguage {
    if (-not (Test-Path $script:OSDLangFile)) { return "en" }
    try {
        $content = [System.IO.File]::ReadAllText($script:OSDLangFile, [System.Text.Encoding]::UTF8)
        $content = $content.Trim().TrimStart([char]0xFEFF)
        if ($content -eq "") { return "en" }
        return $content
    } catch { return "en" }
}

function Set-CurrentLanguage {
    param([string]$Lang)
    try {
        [System.IO.File]::WriteAllText($script:OSDLangFile, $Lang, (New-Object System.Text.UTF8Encoding($false)))
        return $true
    } catch { return $false }
}

function Get-AvailableLanguages {
    $defaults = @("en")
    if (-not (Test-Path $script:LangListFile)) { return $defaults }
    $langs = @()
    try {
        foreach ($line in [System.IO.File]::ReadAllLines($script:LangListFile, [System.Text.Encoding]::UTF8)) {
            $clean = $line.Trim().TrimStart([char]0xFEFF)
            if ($clean -ne "" -and -not $clean.StartsWith("#")) { $langs += $clean }
        }
    } catch { }
    if ($langs.Count -eq 0) { return $defaults }
    return $langs
}

$script:LangDict = @{}
$script:CurrentLang = "en"

function Load-LangDict {
    param([string]$Lang)
    $script:LangDict = @{}
    foreach ($l in @($Lang, "en")) {
        $file = Join-Path $script:LangDir "STMENU_$l.dat"
        if (-not (Test-Path $file)) { continue }
        try {
            $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
            foreach ($line in ($content -split "`r?`n")) {
                $line = $line.Trim()
                if ($line -eq "" -or $line.StartsWith("#")) { continue }
                $eq = $line.IndexOf("=")
                if ($eq -lt 1) { continue }
                $k = $line.Substring(0, $eq).Trim()
                $v = $line.Substring($eq + 1).Trim()
                if (-not $script:LangDict.ContainsKey($k)) { $script:LangDict[$k] = $v }
            }
        } catch { }
    }
}

function T {
    param([string]$Key)
    if ($script:LangDict.ContainsKey($Key)) { return $script:LangDict[$Key] }
    return $Key
}

function Get-OSDMessage {
    param([string]$Key)
    $lang = Get-CurrentLanguage
    $msgFile = Join-Path $script:LangDir "OSDMSG_$lang.dat"
    if (-not (Test-Path $msgFile)) { $msgFile = Join-Path $script:LangDir "OSDMSG_en.dat" }
    if (-not (Test-Path $msgFile)) { return $Key }
    try {
        $content = [System.IO.File]::ReadAllText($msgFile, [System.Text.Encoding]::UTF8)
        foreach ($line in ($content -split "`r?`n")) {
            $line = $line.Trim()
            if ($line -eq "" -or $line.StartsWith("#")) { continue }
            $eq = $line.IndexOf("=")
            if ($eq -lt 1) { continue }
            $k = $line.Substring(0, $eq).Trim()
            $v = $line.Substring($eq + 1).Trim()
            if ($k -eq $Key) { return $v }
        }
    } catch { }
    return $Key
}

# ============================================================
# menu.conf parser
# ============================================================
function Get-MenuItems {
    param([string]$MenuFile, [string]$RootKeyword)
    $items = [System.Collections.ArrayList]::new()
    if (-not (Test-Path $MenuFile)) { return $items }
    $lines = [System.IO.File]::ReadAllLines($MenuFile, [System.Text.Encoding]::UTF8)
    $inSection = $false
    foreach ($rawLine in $lines) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) { continue }
        $rest = $rawLine; $lead = ""
        while ($rest.Length -gt 0 -and ($rest[0] -eq ' ' -or $rest[0] -eq "`t")) {
            $lead += $rest[0]; $rest = $rest.Substring(1)
        }
        if ($lead.Length -eq 0) {
            $inSection = $false
            if ($rest -match "([A-Z][A-Z\s]+)\s*$") {
                if ($matches[1].Trim() -eq $RootKeyword) { $inSection = $true }
            }
            continue
        }
        if (-not $inSection) { continue }
        $parts = $rest -split "`t"
        if ($parts.Count -lt 2) { continue }
        $label = $parts[0].Trim()
        $command = $parts[1].Trim()
        $disabled = $false
        for ($j = 2; $j -lt $parts.Count; $j++) {
            if ($parts[$j].Trim() -eq "disabled=true") { $disabled = $true }
        }
        if ($disabled) { continue }
        if ([string]::IsNullOrEmpty($command)) { continue }
        [void]$items.Add([PSCustomObject]@{ Label = $label; Command = $command })
    }
    return ,$items
}

# ============================================================
# mpv command string parsers
# ============================================================
function Split-MpvCommands {
    param([string]$CommandText)
    $commands = [System.Collections.ArrayList]::new()
    if ([string]::IsNullOrEmpty($CommandText)) { return ,$commands }
    $current = ""; $inQuotes = $false
    for ($i = 0; $i -lt $CommandText.Length; $i++) {
        $c = $CommandText[$i]
        if ($c -eq '"') { $inQuotes = -not $inQuotes; $current += $c }
        elseif ($c -eq ';' -and -not $inQuotes) {
            if ($current.Trim() -ne "") { [void]$commands.Add($current.Trim()) }
            $current = ""
        } else { $current += $c }
    }
    if ($current.Trim() -ne "") { [void]$commands.Add($current.Trim()) }
    return ,$commands
}

function Split-MpvArgs {
    param([string]$CommandText)
    $out = [System.Collections.ArrayList]::new()
    if ([string]::IsNullOrEmpty($CommandText)) { return ,$out }
    $current = ""; $inQuotes = $false; $hadToken = $false
    foreach ($c in $CommandText.ToCharArray()) {
        if ($c -eq '"') { $inQuotes = -not $inQuotes; $hadToken = $true }
        elseif (($c -eq ' ' -or $c -eq "`t") -and -not $inQuotes) {
            if ($hadToken) { [void]$out.Add($current); $current = ""; $hadToken = $false }
        } else { $current += $c; $hadToken = $true }
    }
    if ($hadToken) { [void]$out.Add($current) }
    return ,$out
}

# ============================================================
# JSON helpers
# ============================================================
function ConvertTo-JsonString {
    param([string]$S)
    if ($null -eq $S) { return "" }
    $S = $S.Replace('\', '\\').Replace('"', '\"')
    $S = $S.Replace("`r", '\r').Replace("`n", '\n').Replace("`t", '\t')
    return $S
}

function Build-MpvPayload {
    param([string[]]$Command, [int]$RequestId)
    $parts = [System.Collections.ArrayList]::new()
    foreach ($arg in $Command) {
        [void]$parts.Add('"' + (ConvertTo-JsonString $arg) + '"')
    }
    $cmdJson = "[" + ($parts -join ",") + "]"
    return '{"command":' + $cmdJson + ',"request_id":' + $RequestId + '}'
}

# ============================================================
# IPC (named pipe to mpv)
# ============================================================
$script:PipeName    = "mpv-sw-capture-socket"
$script:Pipe        = $null
$script:Reader      = $null
$script:Writer      = $null
$script:PendingRead = $null
$script:RequestId   = 0
$script:Props       = @{}
$script:PendingGets = @{}
$script:Connected   = $false

function Send-Raw {
    param([string[]]$Command)
    if (-not $script:Pipe -or -not $script:Writer) { return }
    try {
        $script:RequestId++
        $payload = Build-MpvPayload -Command $Command -RequestId $script:RequestId
        $script:Writer.WriteLine($payload)
    } catch { $script:Connected = $false }
}

function Send-MpvCommandString {
    param([string]$CommandString)
    if (-not (Connect-Mpv)) { return 0 }
    $commands = Split-MpvCommands -CommandText $CommandString
    $sentCount = 0
    foreach ($cmd in $commands) {
        $parts = Split-MpvArgs -CommandText $cmd
        if (@($parts).Count -gt 0) { Send-Raw $parts; $sentCount++ }
    }
    return $sentCount
}

function Send-GetProperty {
    param([string]$PropName)
    if (-not $script:Pipe -or -not $script:Writer) { return }
    try {
        $script:RequestId++
        $myId = $script:RequestId
        $script:PendingGets[$myId] = $PropName
        $payload = Build-MpvPayload -Command @("get_property", $PropName) -RequestId $myId
        $script:Writer.WriteLine($payload)
    } catch { $script:Connected = $false }
}

function Close-MpvConnection {
    $script:Connected = $false
    if ($script:Pipe) { try { $script:Pipe.Dispose() } catch { } }
    $script:Pipe        = $null
    $script:Reader      = $null
    $script:Writer      = $null
    $script:PendingRead = $null
    $script:PendingGets = @{}
}

function Connect-Mpv {
    if ($script:Pipe -and $script:Pipe.IsConnected) { return $true }
    if ($script:Pipe) { Close-MpvConnection }
    try {
        $p = New-Object System.IO.Pipes.NamedPipeClientStream(
            ".", $script:PipeName,
            [System.IO.Pipes.PipeDirection]::InOut,
            [System.IO.Pipes.PipeOptions]::Asynchronous)
        # 100 ms is enough for the pipe to accept if it exists. A longer
        # timeout blocks the UI thread on every failed attempt, making the
        # app feel frozen while disconnected. 100 ms keeps the UI responsive
        # and is still short enough that the next poll tick (500 ms later)
        # will succeed within ~1 second after mpv starts listening.
        $p.Connect(100)
        $script:Pipe   = $p
        $script:Reader = New-Object System.IO.StreamReader($p)
        $script:Writer = New-Object System.IO.StreamWriter($p)
        $script:Writer.AutoFlush = $true
        $script:Connected = $true

        # volume is polled in the UI timer, not observed. Same reason as
        # audio-boost: when observe_property is used on some setups the
        # initial value never arrives, so the slider stays at its XAML
        # default until the user interacts with it.

        try { $script:PendingRead = $script:Reader.ReadLineAsync() }
        catch { $script:PendingRead = $null }
        return $true
    } catch {
        Close-MpvConnection
        return $false
    }
}

function Send-Mpv {
    param([string[]]$Command)
    if (-not (Connect-Mpv)) { return }
    Send-Raw $Command
    # If the connect just succeeded from a button click (rather than the
    # poll timer), update the visual state right away so the user sees
    # "Connected" without waiting for the next poll tick.
    if ($script:Connected -and $script:StatusText.Text -ne (T "Connected")) {
        Set-Status (T "Connected") $green
    }
}

# ============================================================
# Palette
# ============================================================
$bgPanel  = "#141A22"
$bgCard   = "#1A222C"
$bgBorder = "#2B3644"
$textHi   = "#F2F5F8"
$textNorm = "#B7C5D4"
$textDim  = "#8296AB"
$amber    = "#D9A441"
$blue     = "#4A9EFF"
$green    = "#35D07F"
$red      = "#FF4B52"

$ICON_LOCK   = 0xE72E
$ICON_UNLOCK = 0xE785
$ICON_HIDE   = 0xED1A
$ICON_VIEW   = 0xE7B3
$ICON_CAMERA = 0xE722
$ICON_RECORD = 0xE7C8
$ICON_TRASH  = 0xE74D
$ICON_OPEN   = 0xE8E5
$ICON_CLOSE  = 0xE711
$ICON_LINK   = 0xE71B
$ICON_FOLDER = 0xE8B7
$ICON_VIDEO  = 0xE714
$ICON_PHOTO  = 0xE91B

# ============================================================
# XAML
# ============================================================
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MPV-SW-Capture - Stream Menu"
        Width="580" SizeToContent="Height" MaxHeight="1400" MinHeight="600"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanMinimize"
        Background="$bgPanel"
        Foreground="$textNorm"
        FontFamily="Segoe UI Emoji, Segoe UI"
        UseLayoutRounding="True"
        TextOptions.TextFormattingMode="Display">
    <Window.Resources>
        <Style x:Key="BaseButton" TargetType="Button">
            <Setter Property="Background" Value="$bgCard"/>
            <Setter Property="Foreground" Value="$textHi"/>
            <Setter Property="BorderBrush" Value="$bgBorder"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="8,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="$blue"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="$amber"/>
                                <Setter Property="Foreground" Value="#000000"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="Button" BasedOn="{StaticResource BaseButton}"/>

        <Style x:Key="CloseMpvButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="BorderBrush" Value="$red"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>
        <Style x:Key="OpenMpvButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="BorderBrush" Value="$green"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <Style x:Key="DangerToggle" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="6,12"/>
            <Setter Property="BorderBrush" Value="$red"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <Style x:Key="ApplyButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="$blue"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="6,6"/>
        </Style>
        <Style x:Key="LangButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="$bgPanel"/>
            <Setter Property="Foreground" Value="$blue"/>
            <Setter Property="BorderBrush" Value="$blue"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="MinWidth" Value="52"/>
        </Style>
        <Style x:Key="LockNormal" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="BorderBrush" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="FontSize" Value="17"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,14"/>
        </Style>
        <Style x:Key="LockActive" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="$amber"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="BorderBrush" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="FontSize" Value="19"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#E8B855"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#C89430"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="OSDNormal" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="BorderBrush" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="FontSize" Value="17"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,14"/>
        </Style>
        <Style x:Key="OSDActive" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="$blue"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="BorderBrush" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="FontSize" Value="19"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="8,14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#6ABAFF"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#3A8EEF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="ToggleNormal" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Padding" Value="6,12"/>
        </Style>
        <Style x:Key="ToggleActive" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="Background" Value="$amber"/>
            <Setter Property="Foreground" Value="#000000"/>
            <Setter Property="BorderBrush" Value="#FFC857"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="6,12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#E8B855"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#C89430"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="PosButton" TargetType="Button" BasedOn="{StaticResource BaseButton}">
            <Setter Property="FontFamily" Value="Segoe UI Symbol"/>
            <Setter Property="FontSize" Value="20"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="MinWidth" Value="42"/>
            <Setter Property="MinHeight" Value="34"/>
        </Style>

        <Style TargetType="Slider">
            <Setter Property="Height" Value="26"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Slider">
                        <Grid>
                            <Border Height="4" CornerRadius="2" Background="$bgCard" VerticalAlignment="Center"/>
                            <Track x:Name="PART_Track">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="Slider.DecreaseLarge" Opacity="0" Focusable="False"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Width="16" Height="16" Focusable="False">
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Ellipse Fill="$amber"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="Slider.IncreaseLarge" Opacity="0" Focusable="False"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <DataTemplate x:Key="MenuConfItemTemplate">
            <TextBlock Text="{Binding Label}"/>
        </DataTemplate>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="$bgCard"/>
            <Setter Property="Foreground" Value="$textHi"/>
            <Setter Property="BorderBrush" Value="$bgBorder"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Height" Value="30"/>
            <Setter Property="MaxDropDownHeight" Value="280"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <Border x:Name="Bd"
                                    Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="1"
                                    CornerRadius="4">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="22"/>
                                    </Grid.ColumnDefinitions>
                                    <ContentPresenter Grid.Column="0"
                                                      Margin="10,0,0,0"
                                                      VerticalAlignment="Center"
                                                      HorizontalAlignment="Left"
                                                      Content="{TemplateBinding SelectionBoxItem}"
                                                      ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                                      ContentStringFormat="{TemplateBinding SelectionBoxItemStringFormat}"
                                                      IsHitTestVisible="False"/>
                                    <Path Grid.Column="1"
                                          HorizontalAlignment="Center"
                                          VerticalAlignment="Center"
                                          Data="M 0 0 L 4 4 L 8 0 Z"
                                          Fill="$textHi"/>
                                </Grid>
                            </Border>
                            <ToggleButton x:Name="ToggleButton"
                                          Focusable="False"
                                          Background="Transparent"
                                          ClickMode="Press"
                                          IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Background="Transparent"/>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <Popup x:Name="PART_Popup"
                                   AllowsTransparency="True"
                                   Placement="Bottom"
                                   Focusable="False"
                                   IsOpen="{TemplateBinding IsDropDownOpen}">
                                <Border Background="$bgCard"
                                        BorderBrush="$bgBorder"
                                        BorderThickness="1"
                                        CornerRadius="4"
                                        MinWidth="{TemplateBinding ActualWidth}"
                                        MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <ScrollViewer>
                                        <StackPanel IsItemsHost="True"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="BorderBrush" Value="$blue"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="$bgCard"/>
            <Setter Property="Foreground" Value="$textHi"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Bd"
                                Background="{TemplateBinding Background}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="$bgBorder"/>
                                <Setter Property="Foreground" Value="$textHi"/>
                            </Trigger>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="$blue"/>
                                <Setter Property="Foreground" Value="#000000"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,18">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" Width="4" Background="$amber" Margin="0,0,12,0"/>
            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                <TextBlock x:Name="HeaderTitle" Text="STREAM MENU"
                           FontSize="18" FontWeight="Bold" Foreground="$textHi"/>
                <TextBlock x:Name="HeaderSubtitle" Text="External control for MPV-SW-Capture"
                           FontSize="11" Foreground="$textDim"/>
            </StackPanel>
            <!-- Focus mpv button, positioned left of the language button. -->
            <Button x:Name="BtnFocusMpv" Grid.Column="2"
                    Style="{StaticResource LangButton}"
                    VerticalAlignment="Center" Margin="12,0,6,0"/>
            <Button x:Name="BtnLanguage" Grid.Column="3" Content="EN"
                    Style="{StaticResource LangButton}"
                    VerticalAlignment="Center" Margin="0,0,0,0"/>
        </Grid>

        <StackPanel Grid.Row="1" Margin="0,0,0,14">
            <Grid Margin="0,0,0,6">
                <TextBlock x:Name="VolumeLabel" Text="VOLUME" FontSize="11" FontWeight="Bold" Foreground="$textHi"/>
                <TextBlock x:Name="VolumeValue" Text="100%" FontSize="14" FontWeight="Bold" Foreground="$amber" HorizontalAlignment="Right"/>
            </Grid>
            <Slider x:Name="VolumeSlider" Minimum="0" Maximum="100" Value="100" TickFrequency="5" IsSnapToTickEnabled="True"/>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,20">
            <Grid Margin="0,0,0,6">
                <TextBlock x:Name="BoostLabel" Text="AUDIO BOOST" FontSize="11" FontWeight="Bold" Foreground="$textHi"/>
                <TextBlock x:Name="BoostValue" Text="100%" FontSize="14" FontWeight="Bold" Foreground="$amber" HorizontalAlignment="Right"/>
            </Grid>
            <Slider x:Name="BoostSlider" Minimum="100" Maximum="400" Value="100" TickFrequency="25" IsSnapToTickEnabled="True"/>
        </StackPanel>

        <Border x:Name="RecStatusBorder" Grid.Row="3" Margin="0,0,0,18"
                Background="#2A1416" BorderBrush="$red" BorderThickness="1"
                CornerRadius="4" Padding="12,10" Visibility="Collapsed">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock x:Name="RecLabelText" Grid.Row="0"
                           Text="REC" Foreground="$red" FontSize="13" FontWeight="Bold" TextWrapping="Wrap"/>
                <Grid x:Name="RecProgressGrid" Grid.Row="1" Margin="0,8,0,0" Height="6">
                    <Border Background="#3A1A1E" CornerRadius="3"/>
                    <Border x:Name="RecProgressFill" Background="$red" CornerRadius="3"
                            HorizontalAlignment="Left" Width="0"/>
                </Grid>
                <TextBlock x:Name="RecHintText" Grid.Row="2"
                           Margin="0,8,0,0" FontSize="11" Foreground="$amber"
                           TextWrapping="Wrap"/>
            </Grid>
        </Border>

        <Border Grid.Row="4" Height="1" Background="$bgBorder" Margin="0,0,0,14"/>

        <UniformGrid Grid.Row="5" Columns="2" Margin="0,0,0,14">
            <Button x:Name="BtnLockMenu" Margin="0,0,6,0" Style="{StaticResource LockNormal}"/>
            <Button x:Name="BtnHideOSD" Margin="6,0,0,0" Style="{StaticResource OSDNormal}"/>
        </UniformGrid>

        <UniformGrid Grid.Row="6" Columns="2" Margin="0,0,0,14">
            <Button x:Name="BtnOpenMpv"  Margin="0,0,6,0" Style="{StaticResource OpenMpvButton}"/>
            <Button x:Name="BtnCloseMpv" Margin="6,0,0,0" Style="{StaticResource CloseMpvButton}"/>
        </UniformGrid>

        <UniformGrid Grid.Row="7" Columns="2" Margin="0,0,0,6">
            <Button x:Name="BtnScreenshot" Margin="0,0,6,0"/>
            <Button x:Name="BtnRecord"     Margin="6,0,0,0"/>
        </UniformGrid>

        <UniformGrid Grid.Row="8" Columns="2" Margin="0,0,0,6">
            <Button x:Name="BtnInfo"    Margin="0,0,6,0"/>
            <Button x:Name="BtnShowASS" Margin="6,0,0,0" FontWeight="Bold"/>
        </UniformGrid>

        <UniformGrid Grid.Row="9" Columns="4" Margin="0,0,0,14">
            <Button x:Name="BtnAutoICC"    Margin="0,0,4,0" Style="{StaticResource ToggleNormal}"/>
            <Button x:Name="BtnFullscreen" Margin="4,0,4,0" Style="{StaticResource ToggleNormal}"/>
            <Button x:Name="BtnOnTop"      Margin="4,0,4,0" Style="{StaticResource ToggleNormal}"/>
            <Button x:Name="BtnClean"      Margin="4,0,0,0" Style="{StaticResource DangerToggle}"/>
        </UniformGrid>

        <Grid Grid.Row="10" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Grid Grid.Column="0" Margin="0,0,14,0">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" x:Name="WindowPositionLabel" Text="WINDOW POSITION"
                           FontSize="11" FontWeight="Bold" Foreground="$textHi" Margin="0,0,0,4"/>
                <UniformGrid Grid.Row="1" Columns="3" Rows="3">
                    <Button x:Name="BtnPosNW" Content="&#x2196;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosN"  Content="&#x2191;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosNE" Content="&#x2197;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosW"  Content="&#x2190;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosC"  Content="&#x25A0;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosE"  Content="&#x2192;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosSW" Content="&#x2199;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosS"  Content="&#x2193;" Margin="1" Style="{StaticResource PosButton}"/>
                    <Button x:Name="BtnPosSE" Content="&#x2198;" Margin="1" Style="{StaticResource PosButton}"/>
                </UniformGrid>
                <!-- Fill Screen and Fit Full are stacked with manual spacing
                     so Fill Screen sits at the same vertical level as the
                     CROPS combo, and Fit Full sits at the BEZELS combo
                     level. Height="30" matches the ComboBox height so the
                     buttons look like siblings of the combos on the right. -->
                <StackPanel Grid.Row="2" VerticalAlignment="Top">
                    <Button x:Name="BtnFillScreen" Margin="1,5,1,0"
                            Height="30" Padding="6,0"
                            Style="{StaticResource ToggleNormal}"/>
                    <Button x:Name="BtnFitFull" Margin="1,27,1,0"
                            Height="30" Padding="6,0"
                            Style="{StaticResource ToggleNormal}"/>
                </StackPanel>
            </Grid>
            <Grid Grid.Column="1" VerticalAlignment="Top">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Grid.Row="0" x:Name="ShaderLabel" Text="SHADER"
                           FontSize="11" FontWeight="Bold" Foreground="$textHi" Margin="0,0,0,4"/>
                <Grid Grid.Row="1" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <ComboBox x:Name="ComboShaders" Grid.Column="0" Margin="0,0,6,0"
                              ItemTemplate="{StaticResource MenuConfItemTemplate}"
                              VerticalAlignment="Top"/>
                    <Button x:Name="BtnApplyShaders" Grid.Column="1" MinWidth="64"
                            VerticalAlignment="Top" Style="{StaticResource ApplyButton}"/>
                </Grid>
                <TextBlock Grid.Row="2" x:Name="ShapesLabel" Text="SHAPES"
                           FontSize="11" FontWeight="Bold" Foreground="$textHi" Margin="0,0,0,4"/>
                <Grid Grid.Row="3" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <ComboBox x:Name="ComboShapes" Grid.Column="0" Margin="0,0,6,0"
                              ItemTemplate="{StaticResource MenuConfItemTemplate}"
                              VerticalAlignment="Top"/>
                    <Button x:Name="BtnApplyShapes" Grid.Column="1" MinWidth="64"
                            VerticalAlignment="Top" Style="{StaticResource ApplyButton}"/>
                </Grid>
                <TextBlock Grid.Row="4" x:Name="CropsLabel" Text="CROPS"
                           FontSize="11" FontWeight="Bold" Foreground="$textHi" Margin="0,0,0,4"/>
                <Grid Grid.Row="5" Margin="0,0,0,8">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <ComboBox x:Name="ComboCrops" Grid.Column="0" Margin="0,0,6,0"
                              ItemTemplate="{StaticResource MenuConfItemTemplate}"
                              VerticalAlignment="Top"/>
                    <Button x:Name="BtnApplyCrops" Grid.Column="1" MinWidth="64"
                            VerticalAlignment="Top" Style="{StaticResource ApplyButton}"/>
                </Grid>
                <TextBlock Grid.Row="6" x:Name="BezelsLabel" Text="BEZELS"
                           FontSize="11" FontWeight="Bold" Foreground="$textHi" Margin="0,0,0,4"/>
                <Grid Grid.Row="7">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <ComboBox x:Name="ComboBezels" Grid.Column="0" Margin="0,0,6,0"
                              ItemTemplate="{StaticResource MenuConfItemTemplate}"
                              VerticalAlignment="Top"/>
                    <Button x:Name="BtnApplyBezels" Grid.Column="1" MinWidth="64"
                            VerticalAlignment="Top" Style="{StaticResource ApplyButton}"/>
                </Grid>
            </Grid>
        </Grid>

        <UniformGrid Grid.Row="11" Columns="2" Margin="0,0,0,6">
            <Button x:Name="BtnOpenRecordings"  Margin="0,0,6,0"/>
            <Button x:Name="BtnOpenScreenshots" Margin="6,0,0,0"/>
        </UniformGrid>

        <UniformGrid Grid.Row="12" Columns="2" Margin="0,0,0,14">
            <Button x:Name="BtnCreateShortcut" Margin="0,0,6,0"/>
            <Button x:Name="BtnOpenTools"      Margin="6,0,0,0"/>
        </UniformGrid>

        <Grid Grid.Row="13" Margin="0,4,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal" HorizontalAlignment="Left">
                <Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="$red"
                         VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock x:Name="StatusText" Text="Connecting..." FontSize="11"
                           Foreground="$textDim" VerticalAlignment="Center"/>
            </StackPanel>
            <TextBlock x:Name="LogText" Grid.Column="1" Text="" FontSize="11" Foreground="$amber"
                       HorizontalAlignment="Right" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
        </Grid>
    </Grid>
</Window>
"@

try {
    $sr = New-Object System.IO.StringReader($xaml)
    $xmlReader = [System.Xml.XmlReader]::Create($sr)
    $window = [Windows.Markup.XamlReader]::Load($xmlReader)
} catch {
    [System.Windows.MessageBox]::Show("Failed to load UI: $_", "Error")
    exit 1
}

# ============================================================
# Window icon (title bar + taskbar)
# ============================================================
if (Test-Path $script:IconPath) {
    try {
        $iconUri = New-Object System.Uri($script:IconPath)
        $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create($iconUri)
    } catch { }
}

function Apply-TaskbarIcon {
    if (-not (Test-Path $script:IconPath)) { return }
    try {
        $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
        $hwnd = $helper.Handle
        if ($hwnd -eq [IntPtr]::Zero) { return }
        $flags = [StreamMenuNative]::LR_LOADFROMFILE -bor [StreamMenuNative]::LR_DEFAULTSIZE
        $hBig = [StreamMenuNative]::LoadImage(
            [IntPtr]::Zero, $script:IconPath,
            [StreamMenuNative]::IMAGE_ICON, 0, 0, $flags)
        $hSmall = [StreamMenuNative]::LoadImage(
            [IntPtr]::Zero, $script:IconPath,
            [StreamMenuNative]::IMAGE_ICON, 16, 16,
            [StreamMenuNative]::LR_LOADFROMFILE)
        if ($hBig -ne [IntPtr]::Zero) {
            [void][StreamMenuNative]::SendMessage($hwnd, [StreamMenuNative]::WM_SETICON,
                [IntPtr][StreamMenuNative]::ICON_BIG, $hBig)
        }
        if ($hSmall -ne [IntPtr]::Zero) {
            [void][StreamMenuNative]::SendMessage($hwnd, [StreamMenuNative]::WM_SETICON,
                [IntPtr][StreamMenuNative]::ICON_SMALL, $hSmall)
        }
    } catch { }
}

# ============================================================
# Element references
# ============================================================
$script:HeaderTitle         = $window.FindName("HeaderTitle")
$script:HeaderSubtitle      = $window.FindName("HeaderSubtitle")
$script:BtnLanguage         = $window.FindName("BtnLanguage")
$script:VolumeLabel         = $window.FindName("VolumeLabel")
$script:BoostLabel          = $window.FindName("BoostLabel")
$script:WindowPositionLabel = $window.FindName("WindowPositionLabel")
$script:ShaderLabel         = $window.FindName("ShaderLabel")
$script:ShapesLabel         = $window.FindName("ShapesLabel")
$script:CropsLabel          = $window.FindName("CropsLabel")
$script:BezelsLabel         = $window.FindName("BezelsLabel")
$script:VolumeSlider        = $window.FindName("VolumeSlider")
$script:VolumeValue         = $window.FindName("VolumeValue")
$script:BoostSlider         = $window.FindName("BoostSlider")
$script:BoostValue          = $window.FindName("BoostValue")
$script:StatusDot           = $window.FindName("StatusDot")
$script:StatusText          = $window.FindName("StatusText")
$script:LogText             = $window.FindName("LogText")
$script:RecStatusBorder     = $window.FindName("RecStatusBorder")
$script:RecLabelText        = $window.FindName("RecLabelText")
$script:RecProgressGrid     = $window.FindName("RecProgressGrid")
$script:RecProgressFill     = $window.FindName("RecProgressFill")
$script:RecHintText         = $window.FindName("RecHintText")
$script:LockButton          = $window.FindName("BtnLockMenu")
$script:OSDButton           = $window.FindName("BtnHideOSD")
$script:BtnScreenshot       = $window.FindName("BtnScreenshot")
$script:BtnRecord           = $window.FindName("BtnRecord")
$script:BtnInfo             = $window.FindName("BtnInfo")
$script:BtnClean            = $window.FindName("BtnClean")
$script:BtnShowASS          = $window.FindName("BtnShowASS")
$script:BtnOpenMpv          = $window.FindName("BtnOpenMpv")
$script:BtnCloseMpv         = $window.FindName("BtnCloseMpv")
$script:BtnOpenRecordings   = $window.FindName("BtnOpenRecordings")
$script:BtnOpenScreenshots  = $window.FindName("BtnOpenScreenshots")
$script:BtnCreateShortcut   = $window.FindName("BtnCreateShortcut")
$script:BtnOpenTools        = $window.FindName("BtnOpenTools")
$script:BtnApplyShaders     = $window.FindName("BtnApplyShaders")
$script:BtnApplyShapes      = $window.FindName("BtnApplyShapes")
$script:BtnApplyCrops       = $window.FindName("BtnApplyCrops")
$script:BtnApplyBezels      = $window.FindName("BtnApplyBezels")
$script:TglAutoICC          = $window.FindName("BtnAutoICC")
$script:TglFullscreen       = $window.FindName("BtnFullscreen")
$script:TglOnTop            = $window.FindName("BtnOnTop")
$script:TglFitFull          = $window.FindName("BtnFitFull")
$script:TglFillScreen       = $window.FindName("BtnFillScreen")
$script:ComboShaders        = $window.FindName("ComboShaders")
$script:ComboShapes         = $window.FindName("ComboShapes")
$script:ComboCrops          = $window.FindName("ComboCrops")
$script:ComboBezels         = $window.FindName("ComboBezels")
$script:BtnFocusMpv         = $window.FindName("BtnFocusMpv")

$script:StyleLockNormal = $window.FindResource("LockNormal")
$script:StyleLockActive = $window.FindResource("LockActive")
$script:StyleOSDNormal  = $window.FindResource("OSDNormal")
$script:StyleOSDActive  = $window.FindResource("OSDActive")
$script:StyleTglNormal  = $window.FindResource("ToggleNormal")
$script:StyleTglActive  = $window.FindResource("ToggleActive")

# ============================================================
# State
# ============================================================
$script:LastSliderTouch     = [DateTime]::MinValue
$script:IsUpdatingFromPoll  = $false
$script:LastRecState        = $null
$script:LastProcState       = $null
$script:DoneUntil           = [DateTime]::MinValue
$script:DoneLabelText       = "Finished!"
$script:RecLabelTemplate    = "REC"
$script:LastLockState       = $null
$script:LastOSDState        = $null
$script:LastAutoICC         = $null
$script:LastFullscr         = $null
$script:LastOnTop           = $null
$script:LastFitFull         = $null
$script:LastFillScreen      = $null
$script:LogClearAt          = $null
$script:PollTickCounter     = 0
$script:LastLockBool        = $false
$script:LastOSDHidden       = $false

$script:LastLockClick = [DateTime]::MinValue
$script:LastOSDClick  = [DateTime]::MinValue
$script:LastIccClick  = [DateTime]::MinValue
$script:LastFsClick   = [DateTime]::MinValue
$script:LastOtClick   = [DateTime]::MinValue
$script:LastFitClick  = [DateTime]::MinValue
$script:LastFs2Click  = [DateTime]::MinValue
$script:ClickGuardMs  = 1500

# ============================================================
# Helpers
# ============================================================
$script:BrushCache = @{}
function Get-Brush {
    param([string]$Color)
    if (-not $script:BrushCache.ContainsKey($Color)) {
        $b = New-Object System.Windows.Media.SolidColorBrush (
            [System.Windows.Media.ColorConverter]::ConvertFromString($Color))
        $b.Freeze()
        $script:BrushCache[$Color] = $b
    }
    return $script:BrushCache[$Color]
}

function Set-Status {
    param([string]$Text, [string]$Color)
    if ($script:StatusText.Text -ne $Text) { $script:StatusText.Text = $Text }
    $b = Get-Brush $Color
    if (-not [object]::ReferenceEquals($script:StatusDot.Fill, $b)) { $script:StatusDot.Fill = $b }
}

function Set-Log {
    param([string]$Text)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $script:LogText.Text = "[$ts] $Text"
    $script:LogClearAt = (Get-Date).AddSeconds(8)
}

function FormatTime {
    param([double]$Seconds)
    if ($null -eq $Seconds) { return "00:00" }
    $s = [Math]::Max(0, [int]$Seconds)
    return "{0:00}:{1:00}" -f ([int]($s / 60)), ($s % 60)
}

function New-IconText {
    param([int]$IconCode, [string]$Label)
    $sp = New-Object System.Windows.Controls.StackPanel
    $sp.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $sp.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $icon = New-Object System.Windows.Controls.TextBlock
    $icon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets, Segoe UI Symbol")
    $icon.Text = [string][char]$IconCode
    $icon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $icon.Margin = New-Object System.Windows.Thickness(0,0,8,0)
    $icon.FontSize = 15
    [void]$sp.Children.Add($icon)
    $txt = New-Object System.Windows.Controls.TextBlock
    $txt.Text = $Label
    $txt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $txt.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe UI")
    [void]$sp.Children.Add($txt)
    return $sp
}

function Set-ToggleButtonState {
    param([System.Windows.Controls.Button]$Button, [bool]$On, [string]$LabelOn, [string]$LabelOff)
    $target = if ($On) { $LabelOn } else { $LabelOff }
    if (($Button.Content -as [string]) -ne $target) { $Button.Content = $target }
    $style = if ($On) { $script:StyleTglActive } else { $script:StyleTglNormal }
    if ($Button.Style -ne $style) { $Button.Style = $style }
}

function Set-LockButtonState {
    param([bool]$Locked)
    $script:LastLockBool = $Locked
    if ($Locked) {
        $script:LockButton.Content = New-IconText -IconCode $ICON_UNLOCK -Label (T "UnlockMenu")
        $script:LockButton.Style = $script:StyleLockActive
    } else {
        $script:LockButton.Content = New-IconText -IconCode $ICON_LOCK -Label (T "LockMenu")
        $script:LockButton.Style = $script:StyleLockNormal
    }
}

function Set-OSDButtonState {
    param([bool]$Hidden)
    $script:LastOSDHidden = $Hidden
    if ($Hidden) {
        $script:OSDButton.Content = New-IconText -IconCode $ICON_VIEW -Label (T "ShowOSD")
        $script:OSDButton.Style = $script:StyleOSDActive
    } else {
        $script:OSDButton.Content = New-IconText -IconCode $ICON_HIDE -Label (T "HideOSD")
        $script:OSDButton.Style = $script:StyleOSDNormal
    }
}

function Refresh-AllTexts {
    $script:HeaderTitle.Text = T "StreamMenuTitle"
    $script:HeaderSubtitle.Text = T "StreamMenuSubtitle"
    $script:BtnLanguage.Content = $script:CurrentLang.ToUpper()

    $script:VolumeLabel.Text = T "Volume"
    $script:BoostLabel.Text = T "AudioBoost"

    Set-LockButtonState -Locked $script:LastLockBool
    Set-OSDButtonState -Hidden $script:LastOSDHidden

    $script:BtnScreenshot.Content = New-IconText -IconCode $ICON_CAMERA -Label (T "Screenshot")
    $script:BtnRecord.Content     = New-IconText -IconCode $ICON_RECORD -Label (T "Record")
    $script:BtnClean.Content      = New-IconText -IconCode $ICON_TRASH  -Label (T "CleanALL")
    $script:BtnOpenMpv.Content    = New-IconText -IconCode $ICON_OPEN   -Label (T "OpenMPV")
    $script:BtnCloseMpv.Content   = New-IconText -IconCode $ICON_CLOSE  -Label (T "CloseMPV")
    $script:BtnCreateShortcut.Content = New-IconText -IconCode $ICON_LINK   -Label (T "CreateShortcut")
    $script:BtnOpenTools.Content      = New-IconText -IconCode $ICON_FOLDER -Label (T "OpenTools")
    $script:BtnOpenRecordings.Content  = New-IconText -IconCode $ICON_VIDEO -Label (T "OpenRecordings")
    $script:BtnOpenScreenshots.Content = New-IconText -IconCode $ICON_PHOTO -Label (T "OpenScreenshots")

    $script:BtnInfo.Content    = T "InfoStream"
    $script:BtnShowASS.Content = T "ShowMenu"
    $script:BtnFocusMpv.Content = T "FocusMPV"

    Set-ToggleButtonState -Button $script:TglAutoICC    -On ($script:Props["icc-profile-auto"] -eq $true) `
        -LabelOn (T "AutoICCOn")    -LabelOff (T "AutoICC")
    Set-ToggleButtonState -Button $script:TglFullscreen -On ($script:Props["fullscreen"] -eq $true) `
        -LabelOn (T "FullscreenOn") -LabelOff (T "Fullscreen")
    Set-ToggleButtonState -Button $script:TglOnTop      -On ($script:Props["ontop"] -eq $true) `
        -LabelOn (T "OnTopOn")      -LabelOff (T "OnTop")
    Set-ToggleButtonState -Button $script:TglFitFull    -On ($script:Props["user-data/bezel_fit"] -eq "fill") `
        -LabelOn (T "FitFullOn")    -LabelOff (T "FitFull")
    Set-ToggleButtonState -Button $script:TglFillScreen -On ($script:Props["keepaspect"] -eq $false) `
        -LabelOn (T "FillScreenOn") -LabelOff (T "FillScreen")

    $script:WindowPositionLabel.Text = T "WindowPosition"
    $script:ShaderLabel.Text = T "Shader"
    $script:ShapesLabel.Text = T "Shapes"
    $script:CropsLabel.Text  = T "Crops"
    $script:BezelsLabel.Text = T "Bezels"
    $script:BtnApplyShaders.Content = T "Apply"
    $script:BtnApplyShapes.Content  = T "Apply"
    $script:BtnApplyCrops.Content   = T "Apply"
    $script:BtnApplyBezels.Content  = T "Apply"
}

function Populate-Combos {
    $script:ComboShaders.ItemsSource = Get-MenuItems -MenuFile $script:MenuConfPath -RootKeyword "SHADERS"
    $script:ComboShaders.SelectedIndex = -1
    $script:ComboShapes.ItemsSource  = Get-MenuItems -MenuFile $script:MenuConfPath -RootKeyword "SHAPES"
    $script:ComboShapes.SelectedIndex = -1
    $script:ComboCrops.ItemsSource   = Get-MenuItems -MenuFile $script:MenuConfPath -RootKeyword "CROPS"
    $script:ComboCrops.SelectedIndex = -1
    $script:ComboBezels.ItemsSource  = Get-MenuItems -MenuFile $script:MenuConfPath -RootKeyword "BEZELS"
    $script:ComboBezels.SelectedIndex = -1
}

# ============================================================
# Slider handlers
# ============================================================
$script:VolumeTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:VolumeTimer.Interval = [TimeSpan]::FromMilliseconds(60)
$script:VolumeTimer.Add_Tick({
    $script:VolumeTimer.Stop()
    $v = [int]$script:VolumeSlider.Value
    Send-Mpv @("set_property", "volume", $v) | Out-Null
    if ($script:VolumeValue.Text -ne "$v%") { $script:VolumeValue.Text = "$v%" }
})

$script:VolumeSlider.Add_ValueChanged({
    if ($script:IsUpdatingFromPoll) { return }
    $script:LastSliderTouch = [DateTime]::Now
    $script:VolumeValue.Text = "$([int]$script:VolumeSlider.Value)%"
    $script:VolumeTimer.Stop()
    $script:VolumeTimer.Start()
})

$script:BoostTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:BoostTimer.Interval = [TimeSpan]::FromMilliseconds(80)
$script:BoostTimer.Add_Tick({
    $script:BoostTimer.Stop()
    $b = [int]$script:BoostSlider.Value
    Send-Mpv @("script-message-to", "audio_mode", "audio-boost-set", "$b") | Out-Null
    if ($script:BoostValue.Text -ne "$b%") { $script:BoostValue.Text = "$b%" }
})

$script:BoostSlider.Add_ValueChanged({
    if ($script:IsUpdatingFromPoll) { return }
    $script:LastSliderTouch = [DateTime]::Now
    $script:BoostValue.Text = "$([int]$script:BoostSlider.Value)%"
    $script:BoostTimer.Stop()
    $script:BoostTimer.Start()
})

# ============================================================
# Button handlers
# ============================================================
$window.FindName("BtnScreenshot").Add_Click({
    Send-Mpv @("screenshot") | Out-Null
    Set-Status (T "Screenshot") $green
    Set-Log (T "ScreenshotSaved")
})

$window.FindName("BtnRecord").Add_Click({
    if ($script:Props["user-data/is_processing"] -eq $true) {
        Set-Log (Get-OSDMessage "autocompress_wait_processing")
        return
    }
    Send-Mpv @("script-message-to", "autocompress", "force-toggle-record") | Out-Null
    Set-Status (T "RecordToggled") $green
})

$window.FindName("BtnClean").Add_Click({
    Send-Mpv @("script-message", "clear-bezel", "silent") | Out-Null
    Send-Mpv @("script-message", "clear-crop", "silent") | Out-Null
    Send-Mpv @("script-message", "clear-addon-shaders", "silent") | Out-Null
    Send-Mpv @("vf", "set", "") | Out-Null
    Send-Mpv @("change-list", "glsl-shaders", "clr", "") | Out-Null
    Send-Mpv @("set_property", "deband", "no") | Out-Null
    Send-Mpv @("set_property", "user-data/active_shader", "none") | Out-Null
    Send-Mpv @("set_property", "user-data/active_shape", "none") | Out-Null
    Send-Mpv @("set_property", "video-rotate", 0) | Out-Null
    Send-Mpv @("set_property", "border", "no") | Out-Null
    Send-Mpv @("set_property", "title-bar", "no") | Out-Null
    Send-Mpv @("set_property", "ontop", "no") | Out-Null
    Send-Mpv @("set_property", "video-aspect-override", "16:9") | Out-Null
    Set-Status (T "CleanALL") $green
    Set-Log (T "CleanALLApplied")
})

$window.FindName("BtnLockMenu").Add_Click({
    Send-Mpv @("script-message", "toggle-menu-lock") | Out-Null
    $now = -not $script:LastLockBool
    Set-LockButtonState -Locked $now
    $script:LastLockState = $now
    $script:Props["user-data/menu_locked"] = $now
    $script:LastLockClick = [DateTime]::Now
})

$window.FindName("BtnHideOSD").Add_Click({
    Send-Mpv @("script-message", "toggle-osd") | Out-Null
    $now = -not $script:LastOSDHidden
    Set-OSDButtonState -Hidden $now
    $script:LastOSDState = $now
    $script:Props["osd-duration"] = if ($now) { 0.0 } else { 1000.0 }
    $script:LastOSDClick = [DateTime]::Now
})

$window.FindName("BtnAutoICC").Add_Click({
    Send-Mpv @("cycle", "icc-profile-auto") | Out-Null
    $current = ($script:Props["icc-profile-auto"] -eq $true)
    $now = -not $current
    Set-ToggleButtonState -Button $script:TglAutoICC -On $now `
        -LabelOn (T "AutoICCOn") -LabelOff (T "AutoICC")
    $script:LastAutoICC = $now
    $script:Props["icc-profile-auto"] = $now
    $script:LastIccClick = [DateTime]::Now
})

$window.FindName("BtnFullscreen").Add_Click({
    Send-Mpv @("cycle", "fullscreen") | Out-Null
    $current = ($script:Props["fullscreen"] -eq $true)
    $now = -not $current
    Set-ToggleButtonState -Button $script:TglFullscreen -On $now `
        -LabelOn (T "FullscreenOn") -LabelOff (T "Fullscreen")
    $script:LastFullscr = $now
    $script:Props["fullscreen"] = $now
    $script:LastFsClick = [DateTime]::Now
})

$window.FindName("BtnOnTop").Add_Click({
    Send-Mpv @("cycle", "ontop") | Out-Null
    $current = ($script:Props["ontop"] -eq $true)
    $now = -not $current
    Set-ToggleButtonState -Button $script:TglOnTop -On $now `
        -LabelOn (T "OnTopOn") -LabelOff (T "OnTop")
    $script:LastOnTop = $now
    $script:Props["ontop"] = $now
    $script:LastOtClick = [DateTime]::Now
})

# Fill screen toggle. Mirrors the menu.conf entry:
#   ▢ Fill Screen (Fullscreen)  cycle-values keepaspect yes no
# The button is "on" when keepaspect is off (fill screen active).
$window.FindName("BtnFillScreen").Add_Click({
    Send-Mpv @("cycle-values", "keepaspect", "yes", "no") | Out-Null
    $on = -not ($script:LastFillScreen -eq $true)
    $script:LastFillScreen = $on
    $script:Props["keepaspect"] = (-not $on)   # keepaspect yes when button off
    Set-ToggleButtonState -Button $script:TglFillScreen -On $on `
        -LabelOn (T "FillScreenOn") -LabelOff (T "FillScreen")
    $script:LastFs2Click = [DateTime]::Now
})

$window.FindName("BtnFitFull").Add_Click({
    Send-Mpv @("script-message", "bezel-fill-toggle") | Out-Null
    $now = ($script:LastFitFull -ne "fill")
    Set-ToggleButtonState -Button $script:TglFitFull -On $now `
        -LabelOn (T "FitFullOn") -LabelOff (T "FitFull")
    $script:LastFitFull = if ($now) { "fill" } else { "fit" }
    $script:Props["user-data/bezel_fit"] = $script:LastFitFull
    $script:LastFitClick = [DateTime]::Now
})

# Focus mpv handler. Moved to the header area but the logic is unchanged.
$window.FindName("BtnFocusMpv").Add_Click({
    # Ask mpv to restore itself first. mpv manages its own window state,
    # so letting it handle un-minimize avoids fighting it with ShowWindow.
    Send-Mpv @("set_property", "window-minimized", "no") | Out-Null

    # Then bring the window to the foreground via Win32. This handles the
    # case where mpv is behind other windows but not minimized, and it
    # works around the Windows foreground lock using AttachThreadInput.
    $ok = [StreamMenuNative]::BringProcessToForeground("mpv")
    if ($ok) {
        Set-Status (T "MPVFocused") $green
        Set-Log    (T "MPVFocused")
    } else {
        Set-Log (T "MPVFocusFailed")
    }
})

$window.FindName("BtnShowASS").Add_Click({
    Send-Mpv @("script-message", "toggle-overlay") | Out-Null
    Set-Status (T "ASSMenuToggled") $green
})

$window.FindName("BtnInfo").Add_Click({
    Send-Mpv @("script-message", "toggle-stats") | Out-Null
    Set-Status (T "InfoToggled") $green
})

$window.FindName("BtnPosNW").Add_Click({ Send-Mpv @("set", "geometry", "0%:0%")     | Out-Null; Set-Log (T "PosTopLeft") })
$window.FindName("BtnPosN").Add_Click({  Send-Mpv @("set", "geometry", "50%:0%")    | Out-Null; Set-Log (T "PosTopCenter") })
$window.FindName("BtnPosNE").Add_Click({ Send-Mpv @("set", "geometry", "100%:0%")   | Out-Null; Set-Log (T "PosTopRight") })
$window.FindName("BtnPosW").Add_Click({  Send-Mpv @("set", "geometry", "0%:50%")    | Out-Null; Set-Log (T "PosCenterLeft") })
$window.FindName("BtnPosC").Add_Click({  Send-Mpv @("set", "geometry", "50%:50%")   | Out-Null; Set-Log (T "PosCenter") })
$window.FindName("BtnPosE").Add_Click({  Send-Mpv @("set", "geometry", "100%:50%")  | Out-Null; Set-Log (T "PosCenterRight") })
$window.FindName("BtnPosSW").Add_Click({ Send-Mpv @("set", "geometry", "0%:100%")   | Out-Null; Set-Log (T "PosBottomLeft") })
$window.FindName("BtnPosS").Add_Click({  Send-Mpv @("set", "geometry", "50%:100%")  | Out-Null; Set-Log (T "PosBottomCenter") })
$window.FindName("BtnPosSE").Add_Click({ Send-Mpv @("set", "geometry", "100%:100%") | Out-Null; Set-Log (T "PosBottomRight") })

$window.FindName("BtnOpenRecordings").Add_Click({
    $path = Join-Path $script:RootDir "_record"
    if (Test-Path $path) {
        Start-Process -FilePath "explorer.exe" -ArgumentList "`"$path`""
        Set-Log (T "OpenedRecordings")
    } else { Set-Log (T "RecordingsNotFound") }
})

$window.FindName("BtnOpenScreenshots").Add_Click({
    $path = Join-Path $script:RootDir "_screenshots"
    if (Test-Path $path) {
        Start-Process -FilePath "explorer.exe" -ArgumentList "`"$path`""
        Set-Log (T "OpenedScreenshots")
    } else { Set-Log (T "ScreenshotsNotFound") }
})

# Writes the launcher VBS to tools\MSC_StreamMenu.vbs (always, so it
# stays in sync with the current layout), then creates a shortcut that
# points at wscript.exe with the VBS as argument. wscript.exe is a
# Windows-subsystem app so no console window appears, unlike pointing
# the shortcut directly at powershell.exe. The VBS resolves its own
# absolute path so there are no working-directory dependencies.
$window.FindName("BtnCreateShortcut").Add_Click({
    try {
        Initialize-ShortcutCreator

        if (-not (Test-Path $script:ToolsDir)) {
            [void](New-Item -ItemType Directory -Path $script:ToolsDir -Force)
        }

        # Emit the VBS with absolute-path resolution. The '0' argument
        # to WshShell.Run and -WindowStyle Hidden on powershell.exe
        # ensure no window is shown at any point.
        $vbsContent = @'
' MSC_StreamMenu.vbs - Launch MPV-SW-Capture Stream Menu
' Launched by wscript.exe (via shortcut) so no console window appears.
Option Explicit

Dim fso, objShell, toolsDir, rootDir, ps1Path, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

' This file lives in <root>\tools\. Two levels up is the root.
toolsDir = fso.GetParentFolderName(WScript.ScriptFullName)
rootDir  = fso.GetParentFolderName(toolsDir)
ps1Path  = rootDir & "\data\script\StreamMenu_MSC.ps1"

If Not fso.FileExists(ps1Path) Then
    MsgBox "StreamMenu_MSC.ps1 not found at:" & vbCrLf & ps1Path, 16, "MPV-SW-Capture"
    WScript.Quit 1
End If

cmd = "powershell.exe -STA -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & ps1Path & """"
objShell.Run cmd, 0, False
'@
        [System.IO.File]::WriteAllText($script:VbsPath, $vbsContent, [System.Text.Encoding]::ASCII)

        $desktop = [Environment]::GetFolderPath("Desktop")
        $lnkPath = Join-Path $desktop "MPV-SW-Capture Stream Menu.lnk"

        $wscriptExe = Join-Path $env:SystemRoot "System32\wscript.exe"
        $vbsFull = (Get-Item $script:VbsPath).FullName
        $arguments = '"' + $vbsFull + '"'

        $iconForShortcut = $null
        if (Test-Path $script:IconPath) {
            $iconForShortcut = (Get-Item $script:IconPath).FullName
        }

        $ok = [ShortcutCreator]::Create(
            $lnkPath,
            $wscriptExe,
            $arguments,
            $script:RootDir,
            $iconForShortcut,
            0,
            "MPV-SW-Capture Stream Menu")

        if ($ok) {
            Set-Status (T "ShortcutCreated") $green
            Set-Log (T "ShortcutCreated")
        } else {
            Set-Log (T "ShortcutFailed")
        }
    } catch {
        Set-Log ((T "ShortcutFailed") + ": " + $_.Exception.Message)
    }
})

$window.FindName("BtnOpenTools").Add_Click({
    if (Test-Path $script:ToolsDir) {
        Start-Process -FilePath "explorer.exe" -ArgumentList "`"$script:ToolsDir`""
        Set-Log (T "OpenedTools")
    } else {
        Set-Log (T "ToolsNotFound")
    }
})

$window.FindName("BtnOpenMpv").Add_Click({
    $bat = Join-Path $script:RootDir "MPV-SW-Capture.bat"
    $mpv = Join-Path $script:RootDir "mpv.exe"
    if (Test-Path $bat) {
        Start-Process -FilePath $bat -WorkingDirectory $script:RootDir
        Set-Log (T "LaunchedMPV")
    } elseif (Test-Path $mpv) {
        Start-Process -FilePath $mpv -WorkingDirectory $script:RootDir
        Set-Log (T "LaunchedMPVExe")
    } else { Set-Log (T "MPVNotFound") }
})

# Block Close MPV while a recording or its processing is in progress.
# If mpv is already gone, there is nothing to close and nothing to
# protect: skip the guard and just update the status.
$window.FindName("BtnCloseMpv").Add_Click({
    if (-not $script:Connected) {
        Set-Log (T "MPVClosed")
        Set-Status (T "MPVClosed") $red
        return
    }
    $isRec  = $script:Props["user-data/is_recording"]
    $isProc = $script:Props["user-data/is_processing"]
    if ($isRec -eq $true -or $isProc -eq $true) {
        Set-Log (T "CannotCloseWhileRecording")
        return
    }
    Send-Mpv @("quit") | Out-Null
    Set-Log (T "MPVClosed")
    Set-Status (T "MPVClosed") $red
})

$window.FindName("BtnApplyShaders").Add_Click({
    $item = $script:ComboShaders.SelectedItem
    if ($null -eq $item) { Set-Log (T "NoShaderSelected"); return }
    $n = Send-MpvCommandString $item.Command
    Set-Log "$(T 'AppliedShader') ($n): $($item.Label)"
})

$window.FindName("BtnApplyShapes").Add_Click({
    $item = $script:ComboShapes.SelectedItem
    if ($null -eq $item) { Set-Log (T "NoShapeSelected"); return }
    $n = Send-MpvCommandString $item.Command
    Set-Log "$(T 'AppliedShape') ($n): $($item.Label)"
})

$window.FindName("BtnApplyCrops").Add_Click({
    $item = $script:ComboCrops.SelectedItem
    if ($null -eq $item) { Set-Log (T "NoCropSelected"); return }
    $n = Send-MpvCommandString $item.Command
    Set-Log "$(T 'AppliedCrop') ($n): $($item.Label)"
})

$window.FindName("BtnApplyBezels").Add_Click({
    $item = $script:ComboBezels.SelectedItem
    if ($null -eq $item) { Set-Log (T "NoBezelSelected"); return }
    $n = Send-MpvCommandString $item.Command
    Set-Log "$(T 'AppliedBezel') ($n): $($item.Label)"
})

$window.FindName("BtnLanguage").Add_Click({
    $avail = Get-AvailableLanguages
    if ($avail.Count -eq 0) { return }
    $cur = Get-CurrentLanguage
    $idx = [array]::IndexOf($avail, $cur)
    if ($idx -lt 0) { $idx = -1 }
    $next = $avail[($idx + 1) % $avail.Count]
    if (-not (Set-CurrentLanguage -Lang $next)) {
        Set-Log "Could not write OSDLang.dat"
        return
    }
    $script:CurrentLang = $next
    Load-LangDict $next
    Refresh-AllTexts
    Send-Mpv @("script-message", "reload-lang") | Out-Null
    Send-Mpv @("script-message", "reload-osd-messages") | Out-Null
    Set-Status (T "LanguageChanged") $green
    Set-Log "$(T 'LanguageChanged'): $($next.ToUpper())"
})

$window.Add_KeyDown({
    param($s, $e)
    if ($e.Key -eq [System.Windows.Input.Key]::Escape) { $window.Close() }
})

# ============================================================
# Pipe reader timer (batch drain, regex parser)
# ============================================================
$script:PipeTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:PipeTimer.Interval = [TimeSpan]::FromMilliseconds(30)
$script:PipeTimer.Add_Tick({
    for ($i = 0; $i -lt 200; $i++) {
        if (-not $script:PendingRead) { return }
        if (-not $script:PendingRead.IsCompleted) { return }
        try {
            $line = $script:PendingRead.Result
            if ($null -eq $line) {
                Close-MpvConnection
                return
            }

            $reqId = $null; $evt = $null; $name = $null; $err = $null
            $m = [regex]::Match($line, '"request_id"\s*:\s*(\d+)')
            if ($m.Success) { $reqId = [int]$m.Groups[1].Value }
            $m = [regex]::Match($line, '"event"\s*:\s*"([^"]+)"')
            if ($m.Success) { $evt = $m.Groups[1].Value }
            $m = [regex]::Match($line, '"error"\s*:\s*"([^"]+)"')
            if ($m.Success) { $err = $m.Groups[1].Value }

            if ($evt -eq "property-change") {
                $m = [regex]::Match($line, '"name"\s*:\s*"([^"]+)"')
                if ($m.Success) { $name = $m.Groups[1].Value }
                if ($name) {
                    $dm = [regex]::Match($line, '"data"\s*:\s*(".*?"|true|false|null|-?[\d\.eE\+\-]+)')
                    if ($dm.Success) {
                        $raw = $dm.Groups[1].Value
                        if ($raw -eq 'true') { $v = $true }
                        elseif ($raw -eq 'false') { $v = $false }
                        elseif ($raw -eq 'null') { $v = $null }
                        elseif ($raw.StartsWith('"')) { $v = $raw.Substring(1, $raw.Length - 2) }
                        else { $v = [double]$raw }
                        $script:Props[$name] = $v
                    }
                }
            }
            elseif ($null -ne $reqId -and $script:PendingGets.ContainsKey($reqId)) {
                $prop = $script:PendingGets[$reqId]
                $script:PendingGets.Remove($reqId)
                if ($err -eq "success") {
                    $dm = [regex]::Match($line, '"data"\s*:\s*(".*?"|true|false|null|-?[\d\.eE\+\-]+)')
                    if ($dm.Success) {
                        $raw = $dm.Groups[1].Value
                        if ($raw -eq 'true') { $v = $true }
                        elseif ($raw -eq 'false') { $v = $false }
                        elseif ($raw -eq 'null') { $v = $null }
                        elseif ($raw.StartsWith('"')) { $v = $raw.Substring(1, $raw.Length - 2) }
                        else { $v = [double]$raw }
                        $script:Props[$prop] = $v
                    }
                }
            }

            $script:PendingRead = $script:Reader.ReadLineAsync()
        } catch {
            Close-MpvConnection
            return
        }
    }
})

# ============================================================
# UI poll timer
# ============================================================
$script:PollTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:PollTimer.Interval = [TimeSpan]::FromMilliseconds(500)
$script:PollTimer.Add_Tick({
    if ($script:LogClearAt -and (Get-Date) -gt $script:LogClearAt) {
        $script:LogText.Text = ""
        $script:LogClearAt = $null
    }

    if (-not $script:Connected) { Connect-Mpv | Out-Null }
    if (-not $script:Connected) {
        Set-Status (T "Disconnected") $red

        # mpv is gone, so any recording state we have is stale. Clear it
        # so the REC panel disappears and the Stream Menu can be closed
        # normally. Otherwise the stale "is_recording = true" would keep
        # blocking Add_Closing forever.
        if ($script:Props["user-data/is_recording"] -eq $true -or
            $script:Props["user-data/is_processing"] -eq $true) {
            $script:Props["user-data/is_recording"] = $false
            $script:Props["user-data/is_processing"] = $false
            $script:LastRecState  = $null
            $script:LastProcState = $null
        }
        if ($script:RecStatusBorder.Visibility -ne "Collapsed") {
            $script:RecStatusBorder.Visibility = "Collapsed"
        }
        return
    }

    $script:PollTickCounter++
    $slowPoll = ($script:PollTickCounter % 4) -eq 0

    # volume is polled rather than observed. On some setups the initial
    # observe_property value never arrives, leaving the slider stuck at
    # its XAML default until the user interacts with it.
    Send-GetProperty "volume"
    Send-GetProperty "user-data/audio-boost"
    Send-GetProperty "user-data/is_recording"
    Send-GetProperty "user-data/is_processing"
    Send-GetProperty "user-data/menu_locked"
    Send-GetProperty "osd-duration"

    if ($script:Props["user-data/is_recording"] -eq $true) {
        Send-GetProperty "user-data/record_elapsed_seconds"
        Send-GetProperty "user-data/record_target_seconds"
    }

    if ($slowPoll) {
        Send-GetProperty "icc-profile-auto"
        Send-GetProperty "fullscreen"
        Send-GetProperty "ontop"
        Send-GetProperty "user-data/bezel_fit"
        # keepaspect is polled slowly, only useful for the Fill Screen
        # toggle's visual state.
        Send-GetProperty "keepaspect"
    }

    if (((Get-Date) - $script:LastSliderTouch).TotalMilliseconds -ge 900) {
        $script:IsUpdatingFromPoll = $true
        try {
            $vol = $script:Props["volume"]
            if ($null -ne $vol) {
                $vInt = [int]$vol
                if ([Math]::Abs($vInt - [int]$script:VolumeSlider.Value) -ge 1) {
                    $script:VolumeSlider.Value = $vInt
                }
                if ($script:VolumeValue.Text -ne "$vInt%") { $script:VolumeValue.Text = "$vInt%" }
            }
            $boost = $script:Props["user-data/audio-boost"]
            if ($null -ne $boost) {
                $bInt = [int]$boost
                if ([Math]::Abs($bInt - [int]$script:BoostSlider.Value) -ge 1) {
                    $script:BoostSlider.Value = $bInt
                }
                if ($script:BoostValue.Text -ne "$bInt%") { $script:BoostValue.Text = "$bInt%" }
            }
        } finally { $script:IsUpdatingFromPoll = $false }
    }

    $locked = $script:Props["user-data/menu_locked"]
    if ($null -ne $locked -and $locked -ne $script:LastLockState) {
        if (((Get-Date) - $script:LastLockClick).TotalMilliseconds -gt $script:ClickGuardMs) {
            Set-LockButtonState -Locked ($locked -eq $true)
            $script:LastLockState = $locked
        }
    }

    $osdDur = $script:Props["osd-duration"]
    if ($null -ne $osdDur) {
        $osdHidden = ([double]$osdDur -eq 0)
        if ($osdHidden -ne $script:LastOSDState) {
            if (((Get-Date) - $script:LastOSDClick).TotalMilliseconds -gt $script:ClickGuardMs) {
                Set-OSDButtonState -Hidden $osdHidden
                $script:LastOSDState = $osdHidden
            }
        }
    }

    $icc = $script:Props["icc-profile-auto"]
    if ($null -ne $icc -and $icc -ne $script:LastAutoICC) {
        if (((Get-Date) - $script:LastIccClick).TotalMilliseconds -gt $script:ClickGuardMs) {
            Set-ToggleButtonState -Button $script:TglAutoICC -On ($icc -eq $true) `
                -LabelOn (T "AutoICCOn") -LabelOff (T "AutoICC")
            $script:LastAutoICC = $icc
        }
    }
    $fs = $script:Props["fullscreen"]
    if ($null -ne $fs -and $fs -ne $script:LastFullscr) {
        if (((Get-Date) - $script:LastFsClick).TotalMilliseconds -gt $script:ClickGuardMs) {
            Set-ToggleButtonState -Button $script:TglFullscreen -On ($fs -eq $true) `
                -LabelOn (T "FullscreenOn") -LabelOff (T "Fullscreen")
            $script:LastFullscr = $fs
        }
    }
    $ot = $script:Props["ontop"]
    if ($null -ne $ot -and $ot -ne $script:LastOnTop) {
        if (((Get-Date) - $script:LastOtClick).TotalMilliseconds -gt $script:ClickGuardMs) {
            Set-ToggleButtonState -Button $script:TglOnTop -On ($ot -eq $true) `
                -LabelOn (T "OnTopOn") -LabelOff (T "OnTop")
            $script:LastOnTop = $ot
        }
    }
    $fit = $script:Props["user-data/bezel_fit"]
    if ($null -ne $fit -and $fit -ne $script:LastFitFull) {
        if (((Get-Date) - $script:LastFitClick).TotalMilliseconds -gt $script:ClickGuardMs) {
            Set-ToggleButtonState -Button $script:TglFitFull -On ($fit -eq "fill") `
                -LabelOn (T "FitFullOn") -LabelOff (T "FitFull")
            $script:LastFitFull = $fit
        }
    }
    # Fill screen poll update. Button is "on" when keepaspect is off.
    $keep = $script:Props["keepaspect"]
    if ($null -ne $keep) {
        $on = ($keep -eq $false)
        if ($on -ne $script:LastFillScreen) {
            if (((Get-Date) - $script:LastFs2Click).TotalMilliseconds -gt $script:ClickGuardMs) {
                $script:LastFillScreen = $on
                Set-ToggleButtonState -Button $script:TglFillScreen -On $on `
                    -LabelOn (T "FillScreenOn") -LabelOff (T "FillScreen")
            }
        }
    }

    $isRec  = $script:Props["user-data/is_recording"]
    $isProc = $script:Props["user-data/is_processing"]

    if ($null -ne $isRec) {
        if ($null -eq $script:LastRecState) {
            $script:LastRecState = $isRec
        } elseif ($isRec -ne $script:LastRecState) {
            if ($isRec -eq $true) {
                $script:RecLabelTemplate = Get-OSDMessage "autocompress_recording_label"
                Set-Log (Get-OSDMessage "autocompress_recording_label")
            } else {
                Set-Log (Get-OSDMessage "autocompress_finishing_label")
            }
            $script:LastRecState = $isRec
        }
    }
    if ($null -ne $isProc) {
        if ($null -eq $script:LastProcState) {
            $script:LastProcState = $isProc
        } elseif ($isProc -ne $script:LastProcState) {
            if ($isProc -eq $false) {
                $script:DoneLabelText = Get-OSDMessage "autocompress_done_label"
                $script:DoneUntil = (Get-Date).AddSeconds(5)
                Set-Log (Get-OSDMessage "autocompress_done_label")
            }
            $script:LastProcState = $isProc
        }
    }

    if ($isRec -eq $true) {
        $elapsed = 0.0; $target = 0.0
        if ($null -ne $script:Props["user-data/record_elapsed_seconds"]) {
            $elapsed = [double]$script:Props["user-data/record_elapsed_seconds"]
        }
        if ($null -ne $script:Props["user-data/record_target_seconds"]) {
            $target = [double]$script:Props["user-data/record_target_seconds"]
        }
        $label = $script:RecLabelTemplate; if (-not $label) { $label = "REC" }
        $newText = "$label  $(FormatTime $elapsed) / $(FormatTime $target)"
        if ($script:RecLabelText.Text -ne $newText) { $script:RecLabelText.Text = $newText }
        $hint = T "RecordingHintClose"
        if ($script:RecHintText.Text -ne $hint) { $script:RecHintText.Text = $hint }
        $pct = 0.0
        if ($target -gt 0) { $pct = $elapsed / $target }
        if ($pct -lt 0) { $pct = 0 }
        if ($pct -gt 1) { $pct = 1 }
        $gridW = $script:RecProgressGrid.ActualWidth
        if ($gridW -gt 0) {
            $newW = [int]($gridW * $pct)
            if ([int]$script:RecProgressFill.Width -ne $newW) { $script:RecProgressFill.Width = $newW }
        }
        if ($script:RecProgressGrid.Visibility -ne "Visible") { $script:RecProgressGrid.Visibility = "Visible" }
        if ($script:RecStatusBorder.Visibility -ne "Visible")   { $script:RecStatusBorder.Visibility = "Visible" }
    }
    elseif ($isProc -eq $true) {
        $newText = Get-OSDMessage "autocompress_finishing_label"
        if ($script:RecLabelText.Text -ne $newText) { $script:RecLabelText.Text = $newText }
        $hint = T "ProcessingHintClose"
        if ($script:RecHintText.Text -ne $hint) { $script:RecHintText.Text = $hint }
        if ($script:RecProgressGrid.Visibility -ne "Collapsed") { $script:RecProgressGrid.Visibility = "Collapsed" }
        if ($script:RecStatusBorder.Visibility -ne "Visible")   { $script:RecStatusBorder.Visibility = "Visible" }
    }
    elseif ((Get-Date) -lt $script:DoneUntil) {
        if ($script:RecLabelText.Text -ne $script:DoneLabelText) {
            $script:RecLabelText.Text = $script:DoneLabelText
        }
        if ($script:RecHintText.Text -ne "") { $script:RecHintText.Text = "" }
        if ($script:RecProgressGrid.Visibility -ne "Collapsed") { $script:RecProgressGrid.Visibility = "Collapsed" }
        if ($script:RecStatusBorder.Visibility -ne "Visible")   { $script:RecStatusBorder.Visibility = "Visible" }
    }
    else {
        if ($script:RecStatusBorder.Visibility -ne "Collapsed") {
            $script:RecStatusBorder.Visibility = "Collapsed"
        }
    }

    Set-Status (T "Connected") $green
})

# ============================================================
# Show window
# ============================================================
$window.Add_Loaded({
    Apply-TaskbarIcon

    $script:CurrentLang = Get-CurrentLanguage
    Load-LangDict $script:CurrentLang
    Refresh-AllTexts

    Connect-Mpv | Out-Null
    Populate-Combos
    $script:PipeTimer.Start()
    $script:PollTimer.Start()
})

$window.Add_Closed({
    $script:Connected = $false
    $script:PipeTimer.Stop()
    $script:PollTimer.Stop()
    $script:VolumeTimer.Stop()
    $script:BoostTimer.Stop()
    if ($script:Pipe) { try { $script:Pipe.Dispose() } catch { } }
})

# ============================================================
# Block window close while a recording or its processing is
# still in progress. Otherwise the .mkv and .wav temp files
# would be orphaned and remain on disk forever.
# This intercepts both the Escape key and the title bar X button.
#
# If mpv is not connected, there is nothing to protect: any recording
# state we still hold is stale, and the user should be able to close
# the Stream Menu freely.
# ============================================================
$window.Add_Closing({
    param($s, $e)
    if (-not $script:Connected) { return }

    $isRec  = $script:Props["user-data/is_recording"]
    $isProc = $script:Props["user-data/is_processing"]
    if ($isRec -eq $true -or $isProc -eq $true) {
        $e.Cancel = $true
        Set-Log (T "CannotCloseWhileRecording")
    }
})

# ============================================================
# Window hook: pause timers during drag
# ============================================================
$window.Add_SourceInitialized({
    $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
    $source = [System.Windows.Interop.HwndSource]::FromHwnd($hwnd)
    $source.AddHook([System.Windows.Interop.HwndSourceHook]{
        param($h, $msg, $wParam, $lParam, [ref]$handled)
        if ($msg -eq 0x0231) {
            if ($script:PipeTimer) { $script:PipeTimer.Stop() }
            if ($script:PollTimer) { $script:PollTimer.Stop() }
        } elseif ($msg -eq 0x0232) {
            if ($script:Connected) {
                if ($script:PipeTimer) { $script:PipeTimer.Start() }
                if ($script:PollTimer) { $script:PollTimer.Start() }
            }
        }
        return [IntPtr]::Zero
    })
})

$window.ShowDialog() | Out-Null