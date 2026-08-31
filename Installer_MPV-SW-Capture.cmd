@echo off
setlocal EnableExtensions

set "SCRIPT_PATH=%~dp0data\script\Install_MSCGUI.ps1"

if not exist "%SCRIPT_PATH%" (
    echo ERROR: Script not found:
    echo "%SCRIPT_PATH%"
    pause
    endlocal
    exit /b 1
)

start "" powershell.exe -NoProfile -WindowStyle Minimized -File "%SCRIPT_PATH%"

endlocal
exit /b 0
