@echo off
setlocal EnableExtensions

set "SCRIPT_PATH=%~dp0data\script\Install_MSCGUI.ps1"

if not exist "%SCRIPT_PATH%" (
    echo.
    echo ERROR: Install_MSCGUI.ps1 was not found.
    echo "%SCRIPT_PATH%"
    echo.
    pause
    exit /b 1
)

cls
echo ===================================================================================
echo                  MPV-SW-Capture Installer - INITIAL INSTALLATION
echo ===================================================================================
echo This CMD Installer is required only for the initial installation of MPV-SW-Capture.
echo The installer will start automatically after you continue.
echo -----------------------------------------------------------------------------------
echo What happens next:
echo -----------------------------------------------------------------------------------
echo Run the Installer to download and install the required components, including mpv.exe.
echo Once mpv.exe is installed, you will no longer need to use this CMD installer.
echo Use the dedicated MPV-SW-Capture .vbs instead, like MPV-SW-Capture_INSTALLER.
echo.
echo After the installation is complete, to continue with the application configuration,
echo close the Installer, and this will open automatically MPV-SW-Capture_SETUP.
echo NOTE: If fails, you can open it manually.
echo.
echo Press any key to continue...
pause >nul

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

set "PS_EXIT=%ERRORLEVEL%"
if not "%PS_EXIT%"=="0" (
    echo.
    echo ===================================================================================
    echo                           INSTALLATION DID NOT COMPLETE
    echo ===================================================================================
    echo.
    echo The installer returned exit code %PS_EXIT%.
    echo Please review the messages above and try again.
    echo.
    pause
    exit /b %PS_EXIT%
)

set "SETUP_LINK=%~dp0MPV-SW-Capture_SETUP.vbs"

echo.
echo ===================================================================================
echo                           INITIAL INSTALLATION COMPLETED
echo ===================================================================================
echo.

if exist "%SETUP_LINK%" (
    echo The initial installation is complete.
    echo.
    echo Press any key to open MPV-SW-Capture_SETUP...
    pause >nul

    start "" "%SETUP_LINK%"
) else (
    echo MPV-SW-Capture_SETUP.lnk was not found.
    echo Please open MPV-SW-Capture_SETUP manually.
    echo.
    pause
)

endlocal
exit /b 0