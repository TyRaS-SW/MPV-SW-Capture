@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: MPV-SW-Capture launcher
:: Audio Boost managed by ffplayboost.ps1
:: Watchdog delegated to data\ffplay_watchdog.ps1 (independent process).
:: Watchdog only runs in ffplay mode; plugin mode has nothing to clean up.

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "prog1_path=%ROOT_DIR%\mpv.exe"
set "prog2_path=%ROOT_DIR%\ffplay.exe"
set "prog1_name=mpv.exe"
set "prog2_name=ffplay.exe"

:: --- EMPTY IS NOT A CONFIGURED DEVICE ---
SET "video_device="
SET "audio_device="

:: --- WASAPI capture period (plugin audio mode only) ---
:: Controls the periodicity of the IAudioClient3 shared-mode capture stream.
::
:: Options:
:: minimum -> shortest legal period (~1 ms). Lowest latency, but
:: most sensitive to DPC/CPU spikes -> risk of crackles.
:: fundamental -> base period (minimum multiple of the engine tick).
:: default -> device default period (~10 ms). Most stable under
:: DPC/CPU load. Recommended when crackles are reported.
:: maximum -> longest legal period (highest stability, highest latency).
::
:: NOTE: If this variable is removed or left empty, the DLL falls back to
:: 'minimum' (the engine's historical default). Any unknown value also
:: falls back to 'minimum'.
set "MSC_AUDIO_PERIOD=minimum"

set "ffplay_volume=100"

set "audio_mode_file=%ROOT_DIR%\data\menu\audio_mode.txt"
set "audio_mode=plugin"

:: Audio architecture: WASAPI plugin is the default for new installs.
if exist "%audio_mode_file%" set /p "audio_mode=" < "%audio_mode_file%"
if /I "%audio_mode%"=="plugin" goto :audio_mode_valid
set "audio_mode=ffplay"
:audio_mode_valid

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
if /I "%audio_mode%"=="plugin" goto :plugin_audio
set "capture_source=av://dshow:video="%video_device%"" 
set "native_audio_args="
set "timing_args=--untimed"
goto :start_mpv

:plugin_audio
if not exist "%ROOT_DIR%\scripts\msc_audio.dll" (
 echo ERROR: Audio plugin missing. Run native-audio\build.ps1 or select another audio mode.
 exit /b 1
)
set "capture_source=av://dshow:video="%video_device%"" 
set "native_audio_args=--aid=no --audio-file-auto=no"
set "timing_args=--untimed"
goto :start_mpv

:start_mpv
start "" /b "%prog1_path%" --no-border --config-dir="%ROOT_DIR%" %capture_source% --profile=low-latency --demuxer-lavf-o-set=rtbufsize=64M --sws-scaler=point --demuxer-lavf-o-set=video_size=1920x1080 --container-fps-override=60 --vd-lavc-threads=1 %timing_args% --demuxer-thread=no --vo=gpu-next --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no --script-opts=msc_check_version_auto=0 %native_audio_args% --input-ipc-server=\\.\pipe\mpv-sw-capture-socket

set "SDL_AUDIODRIVER=wasapi"
set "SDL_AUDIO_SAMPLES=128"

if /I not "%audio_mode%"=="ffplay" goto :skip_ffplay_start
:: Start volume monitor
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ffplayvol_ps1%" watch-tag ffplay 5000 >nul 2>&1

:: Small pause so monitor is ready before ffplay
ping 127.0.0.1 -n 2 >nul

:: --- START FFPLAY via ffplayboost.ps1 start ---
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ffplayboost_ps1%" start >nul 2>&1

:: --- START EXTERNAL WATCHDOG ---
:: Independent process. Kills ffplay when mpv exits, even on crash.
:: Only needed in ffplay mode: plugin mode has nothing to clean up.
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%watchdog_ps1%" >nul 2>&1

:skip_ffplay_start

:: The .bat's job is done. Exit immediately; the watchdog handles cleanup in ffplay mode.
exit /b