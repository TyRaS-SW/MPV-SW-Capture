@echo off
setlocal EnableDelayedExpansion

set "VIDEO=%~1"
set "AUDIO=%~2"
set "RECORD_DIR=%~3"

timeout /t 4 /nobreak >nul

:: CORRECT DATE
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('dd-MM-yyyy')"' ) do set "CURRENT_DATE=%%i"

set "BASENAME=MPV_%CURRENT_DATE%_"
set "COUNT=1"

:LOOP
set "PADDED=0000!COUNT!"
set "PADDED=!PADDED:~-4!"
set "OUTPUT=%RECORD_DIR%\%BASENAME%!PADDED!.mp4"
if exist "!OUTPUT!" (set /a COUNT+=1 & goto LOOP)

:: SHORTEST: Final = min(video,audio) → 29s if audio is 29s
ffmpeg -i "%VIDEO%" -i "%AUDIO%" -map 0:v -map 1:a -c:v libx264 -preset veryfast -crf 23 -c:a aac -b:a 192k -shortest -y "!OUTPUT!" >nul 2>&1

:: Double cleanup
if %ERRORLEVEL% EQU 0 (
timeout /t 1 /nobreak >nul
del /f /q "%VIDEO%" 2>nul
del /f /q "%AUDIO%" 2>nul
timeout /t 1 /nobreak >nul
del /f /q "%VIDEO%" 2>nul
del /f /q "%AUDIO%" 2>nul
)

endlocal
exit
