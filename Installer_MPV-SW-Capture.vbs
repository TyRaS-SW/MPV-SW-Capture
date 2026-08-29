' ============================================================
' MPV-SW-Capture Installer Launcher by TyRaS-SW
' Launches the Installer PowerShell script (Install_MSCGUI.ps1)
' ============================================================

Option Explicit

Dim objShell, objFSO, strScriptDir, strScriptPath
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strScriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

strScriptPath = objFSO.BuildPath(strScriptDir, "data\script\Install_MSCGUI.ps1")

If Not objFSO.FileExists(strScriptPath) Then
    MsgBox "File not found: " & strScriptPath & vbCrLf & _
           "Install_MSCGUI.ps1 must be in folder 'data\script'.", _
           vbCritical, "Installer - Error"
    WScript.Quit 1
End If

objShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & strScriptPath & """", 0, False

WScript.Quit 0