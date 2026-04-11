Set WshShell = CreateObject("WScript.Shell")
strPath = WScript.ScriptFullName
pos = InStrRev(strPath, "\")
batPath = Left(strPath, pos) & "MPV-SW-Capture.bat"
WshShell.Run batPath, 0, False