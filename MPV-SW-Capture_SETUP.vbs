Set objShell = CreateObject("WScript.Shell")
objShell.Run "mpv.exe --script="".\data\script\mscl_setup.lua"" --script-opts=skip=1", 0, False