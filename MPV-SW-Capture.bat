@echo off
cd "%~dp0"

SET "prog1_name=mpv.exe"
SET "prog2_name=ffplay.exe"
SET "video_device=USB3 Video"
SET "audio_device=Interfaz de sonido digital (USB3 Digital Audio)"

if not defined INVISIBLE_MODE (
set INVISIBLE_MODE=1
cscript //nologo "%~dp0MPV-SW-Capture.vbs"
exit
)

REM MPV: 1080p60
start "" "%prog1_name%" av://dshow:video="%video_device%" --profile=low-latency --demuxer-lavf-o-set=rtbufsize=512M --sws-scaler=point --demuxer-lavf-o-set=video_size=1920x1080 --container-fps-override=60 --vd-lavc-threads=1 --untimed --no-border --demuxer-thread=no --vo=gpu-next --hwdec=no --target-colorspace-hint=no --cursor-autohide=100 --window-scale=1.0 --osc=no

REM Configure SDL engine for ultra-low latency on audio output
set SDL_AUDIODRIVER=wasapi
set SDL_AUDIO_SAMPLES=128

REM ffplay: Perfect audio sync (30ms buffer and zero-wait decoding)
start "" /b "%prog2_name%" -f dshow -audio_buffer_size 4 -i audio="%audio_device%" -fflags nobuffer+fastseek -flags low_delay -strict experimental -nodisp -hide_banner -loglevel quiet

REM Improved surveillance loop
:loop
tasklist /fi "imagename eq %prog1_name%" 2>nul | find /i "%prog1_name%" >nul
if %errorlevel% equ 0 goto check_ffplay

tasklist /fi "imagename eq %prog2_name%" 2>nul | find /i "%prog2_name%" >nul
if %errorlevel% equ 0 taskkill /f /im %prog2_name% >nul 2>&1
exit

:check_ffplay
tasklist /fi "imagename eq %prog2_name%" 2>nul | find /i "%prog2_name%" >nul
if %errorlevel% equ 0 timeout /t 1 /nobreak >nul & goto loop
taskkill /f /im %prog1_name% >nul 2>&1
exit
