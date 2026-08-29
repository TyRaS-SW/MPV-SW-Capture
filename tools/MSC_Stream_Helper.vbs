' ============================================================
' MPV-SW-Capture Stream Helper Launcher by TyRaS-SW
' ============================================================
CreateObject("WScript.Shell").Run "powershell.exe -WindowStyle Hidden -File """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & "\..\data\script\Stream_MSCGUI.ps1""", 0, False