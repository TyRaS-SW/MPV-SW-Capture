@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: MPV-SW-Capture launcher
:: Audio Boost managed by ffplayboost.ps1
:: Watchdog delegated to data\ffplay_watchdog.ps1 (independent process).

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "prog1_path=%ROOT_DIR%\mpv.exe"
set "prog2_path=%ROOT_DIR%\ffplay.exe"
set "prog1_name=mpv.exe"
set "prog2_name=ffplay.exe"

:: --- LEAVE EMPTY TO USE THE DEFAULT DEVICE ---
SET "video_device="
SET "audio_device="

set "ffplay_volume=100"
set "mutex_name=Global\SW_CAPTURE_MPV_SINGLE_INSTANCE"

set "ffplayvol_ps1=%ROOT_DIR%\data\ffplayvol.ps1"
set "ffplayvol_dll=%ROOT_DIR%\data\FfplayVolWrapper.dll"
set "ffplayboost_ps1=%ROOT_DIR%\data\ffplayboost.ps1"
set "watchdog_ps1=%ROOT_DIR%\data\ffplay_watchdog.ps1"

if not exist "%prog1_path%" (
 echo ERROR: mpv.exe not found at "%prog1_path%"
 exit /b 1
)
if not exist "%ffplayvol_ps1%" (
 echo ERROR: ffplayvol.ps1 not found
 exit /b 1
)
if not exist "%ffplayvol_dll%" (
 echo ERROR: FfplayVolWrapper.dll not found
 exit /b 1
)
if not exist "%ffplayboost_ps1%" (
 echo ERROR: ffplayboost.ps1 not found
 exit /b 1
)
if not exist "%watchdog_ps1%" (
 echo ERROR: ffplay_watchdog.ps1 not found
 exit /b 1
)

:: --- START MPV-SW-Capture ---
start "" /b "%prog1_path%" --no-border av://dshow:video="%video_device%" --profile=low-latency --demuxer-lavf-o-set=rtbufsize=64M --sws-scaler=point --demuxer-lavf-o-set=video_size=1920x1080 --container-fps-override=60 --vd-lavc-threads=1 --untimed --demuxer-thread=no --vo=gpu-next --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no --script-opts=msc_check_version_auto=0

set "SDL_AUDIODRIVER=wasapi"
set "SDL_AUDIO_SAMPLES=128"

:: Start volume monitor
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ffplayvol_ps1%" watch-tag ffplay 5000 >nul 2>&1

:: Small pause so monitor is ready before ffplay
ping 127.0.0.1 -n 2 >nul

:: --- START FFPLAY via ffplayboost.ps1 start ---
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ffplayboost_ps1%" start >nul 2>&1

:: --- START EXTERNAL WATCHDOG ---
:: Independent process. Kills ffplay when mpv exits, even on crash.
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%watchdog_ps1%" >nul 2>&1

:: Release the single-instance mutex (best-effort)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { $m = [System.Threading.Mutex]::OpenExisting('%mutex_name%'); $m.ReleaseMutex(); $m.Dispose() } catch {}" >nul 2>&1

:: The .bat's job is done. Exit immediately; the watchdog handles cleanup.
exit /b