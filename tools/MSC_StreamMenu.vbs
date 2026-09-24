Set fso = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")
rootDir = fso.GetParentFolderName(fso.GetParentFolderName(WScript.ScriptFullName))
ps1Path = rootDir & "\data\script\StreamMenu_MSC.ps1"
objShell.Run "powershell.exe -STA -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & ps1Path & """", 0, False