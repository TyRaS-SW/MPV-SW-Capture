' ============================================================
' MPV-SW-Capture Setup Launcher by TyRaS-SW
' ============================================================
CreateObject("WScript.Shell").Run "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\data\script\Setup_MSCGUI.ps1""", 0, False