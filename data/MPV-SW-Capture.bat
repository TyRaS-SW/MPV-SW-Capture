@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

SET "prog1_path=%ROOT_DIR%\mpv.exe"
SET "prog2_path=%ROOT_DIR%\ffplay.exe"
SET "prog1_name=mpv.exe"
SET "prog2_name=ffplay.exe"
SET "video_device="
SET "audio_device="
SET "ffplay_volume=100"
SET "mutex_name=Global\SW_CAPTURE_MPV_SINGLE_INSTANCE"
SET "ffplayvol_path=%ROOT_DIR%\data\ffplayvol.exe"

start "" /b "%prog1_path%" --no-border av://dshow:video="%video_device%" --profile=low-latency --demuxer-lavf-o-set=rtbufsize=64M --sws-scaler=point --demuxer-lavf-o-set=video_size=1920x1080 --container-fps-override=60 --vd-lavc-threads=1 --untimed --demuxer-thread=no --vo=gpu-next --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no --script-opts=msc_check_version_auto=0

set SDL_AUDIODRIVER=wasapi
set SDL_AUDIO_SAMPLES=128

if exist "%ffplayvol_path%" (
start "" /b "%ffplayvol_path%" watch-tag ffplay 5000 >nul 2>&1
ping 127.0.0.1 -n 2 >nul

start "" /b "%prog2_path%" -f dshow -audio_buffer_size 4 -i audio="%audio_device%" -volume %ffplay_volume% -fflags nobuffer+fastseek -flags low_delay -strict experimental -nodisp -hide_banner -loglevel quiet

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
)
