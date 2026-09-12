Set objShell = CreateObject("WScript.Shell")
objShell.Run "..\mpv.exe --script=""..\data\script\mscl_stream.lua"" --script-opts=skip=1", 0, False