@echo off
setlocal EnableExtensions

:: MPV-SW-Capture launcher
::
:: Two processes: mpv renders the capture video, ffplay plays the capture
:: audio. This split is deliberate - see the notes below before changing it.
::
:: WHY NOT ONE PROCESS (mpv --audio-file):
::   It works on paper and every metric looks good (0ms cache, 0 dropped
::   frames, avsync ~4e-06, 2.7% CPU), and it would fix Discord app-window
::   audio capture. But in practice a second dshow input adds perceptible
::   input and audio delay that the counters do not show. Tried and reverted
::   twice. If you try again, test by feel, not by metrics.
::
:: WHY NOT MJPEG / 4K:
::   The card offers MJPEG 4K60 (raw tops out at 4K30) with full colour
::   range, and it benchmarks the same as raw for throughput. It also felt
::   laggier in use. data\detect_mode.ps1 can pick the best mode and write
::   data\capture_mode.txt - the hook is left in place below but is NOT wired
::   into the mpv line. To try it, add %capture_flags% to the start line.
::
:: KNOWN GOOD (what ships): raw 1920x1080 @60, unthreaded demuxer, ffplay
:: for audio. Measured 5 dropped frames, all during device startup.

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "prog1_path=%ROOT_DIR%\mpv.exe"
set "prog2_path=%ROOT_DIR%\ffplay.exe"
set "prog1_name=mpv.exe"
set "prog2_name=ffplay.exe"
SET "video_device=UGREEN 25173"
SET "audio_device=HDMI (UGREEN 25173)"
set "ffplay_volume=100"
set "mutex_name=Global\SW_CAPTURE_MPV_SINGLE_INSTANCE"

set "ffplayvol_ps1=%ROOT_DIR%\data\ffplayvol.ps1"
set "ffplayvol_dll=%ROOT_DIR%\data\FfplayVolWrapper.dll"
set "ffplayboost_ps1=%ROOT_DIR%\data\ffplayboost.ps1"

if not exist "%prog1_path%" (
    echo ERROR: mpv.exe not found at "%prog1_path%"
    exit /b 1
)

if not exist "%ffplayvol_ps1%" (
    echo ERROR: no existe "%ffplayvol_ps1%"
    exit /b 1
)

if not exist "%ffplayvol_dll%" (
    echo ERROR: no existe "%ffplayvol_dll%"
    exit /b 1
)

:: NOTE: these use --demuxer-lavf-o-APPEND, not -o-set. Each -o-set REPLACES
:: the whole option map, so the previous two -o-set flags silently discarded
:: rtbufsize and only video_size survived.
start "" /b "%prog1_path%" --no-border av://dshow:video="%video_device%" --profile=low-latency --demuxer-lavf-o-append=rtbufsize=67108864 --demuxer-lavf-o-append=video_size=1920x1080 --container-fps-override=60 --sws-scaler=point --vd-lavc-threads=1 --untimed --demuxer-thread=no --vo=gpu-next --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no --script-opts=msc_check_version_auto=0

set "SDL_AUDIODRIVER=wasapi"
set "SDL_AUDIO_SAMPLES=128"

start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ffplayvol_ps1%" watch-tag ffplay 5000 >nul 2>&1
ping 127.0.0.1 -n 2 >nul

start "" /b "%prog2_path%" -f dshow -audio_buffer_size 4 -i audio="%audio_device%" -volume %ffplay_volume% -fflags nobuffer+fastseek -flags low_delay -strict experimental -nodisp -hide_banner -loglevel quiet

:: Re-apply the saved Audio Boost level, if any (restarts ffplay with the
:: volume filter). Does nothing when boost is at 100%.
if exist "%ffplayboost_ps1%" (
    start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ffplayboost_ps1%" apply >nul 2>&1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$m = [System.Threading.Mutex]::OpenExisting('%mutex_name%'); $m.ReleaseMutex(); $m.Dispose()" >nul 2>&1

:loop
tasklist /fi "imagename eq %prog1_name%" 2>nul | find /i "%prog1_name%" >nul
if %errorlevel% neq 0 goto mpv_closed

tasklist /fi "imagename eq %prog2_name%" 2>nul | find /i "%prog2_name%" >nul
if %errorlevel% neq 0 goto ffplay_closed

timeout /t 1 /nobreak >nul
goto loop

:mpv_closed
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$m = [System.Threading.Mutex]::OpenExisting('%mutex_name%'); $m.ReleaseMutex(); $m.Dispose()" >nul 2>&1
taskkill /f /im %prog2_name% >nul 2>&1
exit /b

:ffplay_closed
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$m = [System.Threading.Mutex]::OpenExisting('%mutex_name%'); $m.ReleaseMutex(); $m.Dispose()" >nul 2>&1
taskkill /f /im %prog1_name% >nul 2>&1
exit /b
