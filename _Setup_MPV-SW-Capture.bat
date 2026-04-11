@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM -- File paths
set "tmp=%temp%\dshow_%random%.txt"
set "bat_file=%~dp0MPV-SW-Capture.bat"
set "lua_file=%~dp0scripts\usb3.lua"
set "conf_file=%~dp0mpv.conf"
set "compress_bat=%~dp0scripts\compress_fuse.bat"
set "nso_lua=%~dp0scripts\nso_retro.lua"

ffplay -list_devices true -f dshow -i dummy 2>"%tmp%" 1>nul

REM -- Collect VIDEO devices
set "v_count=0"
for /f "tokens=*" %%L in ('findstr "(video)" "%tmp%"') do (
set "_L=%%L"
for /f tokens^=2^ delims^=^" %%V in ("!_L!") do (
set /a v_count+=1
set "video_!v_count!=%%V"
)
)

REM -- Collect AUDIO devices
set "a_count=0"
for /f "tokens=*" %%L in ('findstr "(audio)" "%tmp%"') do (
set "_L=%%L"
for /f tokens^=2^ delims^=^" %%A in ("!_L!") do (
set /a a_count+=1
set "audio_!a_count!=%%A"
)
)

del /f /q "%tmp%" >nul 2>&1

REM -- Display device lists
echo.
echo ========== VIDEO DEVICES ==========
for /l %%i in (1,1,!v_count!) do echo [%%i] !video_%%i!

echo.
echo ========== AUDIO DEVICES ==========
for /l %%i in (1,1,!a_count!) do echo [%%i] !audio_%%i!

REM -- VIDEO selection with validation
echo.
:ask_video
set "v_sel="
set /p "v_sel=Select VIDEO number : "
set "_check=!video_%v_sel%!"
if "!_check!"=="" (
    echo     [X] Invalid option. Enter a number between 1 and !v_count!.
    goto :ask_video
)

REM -- AUDIO selection with validation
echo.
:ask_audio
set "a_sel="
set /p "a_sel=Select AUDIO number : "
set "_check=!audio_%a_sel%!"
if "!_check!"=="" (
    echo     [X] Invalid option. Enter a number between 1 and !a_count!.
    goto :ask_audio
)

set "v_result=!video_%v_sel%!"
set "a_result=!audio_%a_sel%!"

REM -- Show result on screen
echo.
echo ============================================
echo video_device = !v_result!
echo audio_device = !a_result!
echo ============================================

REM -------------------------------------------------------
REM -- Update monitor.bat directly via PowerShell (UTF-8)
REM -------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass   -Command   "$VideoName = [string]::Copy('%v_result%');"   "$AudioName = [string]::Copy('%a_result%');"   "$BatPath   = '%bat_file%';"   "[Console]::InputEncoding  = [Text.UTF8Encoding]::new($false);"   "[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false);"   "$c = [IO.File]::ReadAllText($BatPath, [Text.Encoding]::UTF8);"   "$c = $c -replace '(SET .video_device=).*',('$1' + $VideoName + '\"');"   "$c = $c -replace '(SET .audio_device=).*',('$1' + $AudioName + '\"');"   "[IO.File]::WriteAllText($BatPath, $c, (New-Object Text.UTF8Encoding $true));"

REM -------------------------------------------------------
REM -- Update usb3.lua directly via PowerShell (UTF-8)
REM -------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass   -Command   "$VideoName = [string]::Copy('%v_result%');"   "$AudioName = [string]::Copy('%a_result%');"   "$LuaPath   = '%lua_file%';"   "[Console]::InputEncoding  = [Text.UTF8Encoding]::new($false);"   "[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false);"   "$c = [IO.File]::ReadAllText($LuaPath, [Text.Encoding]::UTF8);"   "$c = $c -replace '(data\.video_device = ).*',('$1\"' + $VideoName + '\"');"   "$c = $c -replace '(data\.audio_device = ).*',('$1\"' + $AudioName + '\"');"   "[IO.File]::WriteAllText($LuaPath, $c, (New-Object Text.UTF8Encoding $true));"

REM -- Done devices
echo.
echo Files updated:
echo %bat_file%
echo %lua_file%

REM -- Get today's date in all 3 formats for display
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd')"') do set "DATE_ISO=%%i"
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('dd-MM-yyyy')"') do set "DATE_EU=%%i"
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('MM-dd-yyyy')"') do set "DATE_US=%%i"

REM -- DATE FORMAT selection with validation
echo.
echo ============================================================
echo  SELECT DATE FORMAT FOR FILE NAMES
echo ============================================================
echo  [a]  Japan / China / Korea  :  !DATE_ISO!   (yyyy-MM-dd)
echo  [b]  Latin America / Europe :  !DATE_EU!   (dd-MM-yyyy)
echo  [c]  USA / Canada           :  !DATE_US!   (MM-dd-yyyy)
echo ============================================================
echo.
:ask_format
set "date_sel="
set "ps_format="
set /p "date_sel=Select format [a/b/c] : "
if /i "!date_sel!"=="a" set "ps_format=yyyy-MM-dd"
if /i "!date_sel!"=="b" set "ps_format=dd-MM-yyyy"
if /i "!date_sel!"=="c" set "ps_format=MM-dd-yyyy"
if "!ps_format!"=="" (
    echo     [X] Invalid option. Enter a, b or c.
    goto :ask_format
)

REM -------------------------------------------------------
REM -- Update mpv.conf + compress_fuse.bat via temp PS1
REM -------------------------------------------------------
set "ps_tmp=%temp%\mpv_upd_%random%.ps1"
echo $fmt = '!ps_format!'                                                                                                                                    > "!ps_tmp!"
echo $tpl = if ($fmt -eq 'yyyy-MM-dd') { 'MPV_%%tY-%%tm-%%td_%%n' } elseif ($fmt -eq 'MM-dd-yyyy') { 'MPV_%%tm-%%td-%%tY_%%n' } else { 'MPV_%%td-%%tm-%%tY_%%n' } >> "!ps_tmp!"
echo $f = '%conf_file%'                                                                                                                                      >> "!ps_tmp!"
echo $c = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)                                                                                                 >> "!ps_tmp!"
echo $c = $c -replace 'screenshot-template=.*', ('screenshot-template=' + [char]34 + $tpl + [char]34)                                                      >> "!ps_tmp!"
echo [IO.File]::WriteAllText($f, $c, (New-Object Text.UTF8Encoding $true))                                                                                  >> "!ps_tmp!"
echo $f = '%compress_bat%'                                                                                                                                   >> "!ps_tmp!"
echo $c = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)                                                                                                 >> "!ps_tmp!"
echo $c = $c -replace 'ToString\(''[\w-]+''\)', ('ToString(''' + $fmt + ''')')                                                                              >> "!ps_tmp!"
echo [IO.File]::WriteAllText($f, $c, (New-Object Text.UTF8Encoding $true))                                                                                  >> "!ps_tmp!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!ps_tmp!"
del /f /q "!ps_tmp!" 2>nul

REM -- SHADER selection with validation
echo.
echo ============================================================
echo  LAUNCH SHADERS ON MPV START
echo ============================================================
echo  [1]  Yes - Start MPV with shaders enabled (1080p-4K Fast)
echo  [2]  No  - Start MPV without shaders (Capture Card default)
echo ============================================================
echo.
:ask_shader
set "shader_sel="
set "shader_mode="
set /p "shader_sel=Select option [1/2] : "
if "!shader_sel!"=="1" set "shader_mode=enable"
if "!shader_sel!"=="2" set "shader_mode=disable"
if "!shader_mode!"=="" (
    echo     [X] Invalid option. Enter 1 or 2.
    goto :ask_shader
)

REM -------------------------------------------------------
REM -- Update mpv.conf shaders via temp PS1 file
REM    (?m) enables multiline so ^ matches start of each line
REM    First strip any existing # then re-add if disabling
REM -------------------------------------------------------
set "ps_tmp=%temp%\mpv_upd_%random%.ps1"
echo $mode = '!shader_mode!'                                                           > "!ps_tmp!"
echo $f = '%conf_file%'                                                               >> "!ps_tmp!"
echo $c = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)                          >> "!ps_tmp!"
echo if ($mode -eq 'enable') {                                                        >> "!ps_tmp!"
echo     $c = $c -replace '(?m)^#?(deband=)', '$1'                                   >> "!ps_tmp!"
echo     $c = $c -replace '(?m)^#?(glsl-shader=)', '$1'                              >> "!ps_tmp!"
echo } else {                                                                         >> "!ps_tmp!"
echo     $c = $c -replace '(?m)^#?(deband=)', '#$1'                                  >> "!ps_tmp!"
echo     $c = $c -replace '(?m)^#?(glsl-shader=)', '#$1'                             >> "!ps_tmp!"
echo }                                                                                >> "!ps_tmp!"
echo [IO.File]::WriteAllText($f, $c, (New-Object Text.UTF8Encoding $true))           >> "!ps_tmp!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!ps_tmp!"
del /f /q "!ps_tmp!" 2>nul

REM -------------------------------------------------------
REM -- Update nso_retro.lua: set active_shader init value
REM    SH1 if shaders enabled (matches default preset),
REM    none if shaders disabled
REM -------------------------------------------------------
if "!shader_mode!"=="enable" (
    set "shader_init=SH1"
) else (
    set "shader_init=none"
)

set "ps_tmp=%temp%\mpv_upd_%random%.ps1"
echo $val = '!shader_init!'                                                                                              > "!ps_tmp!"
echo $f = '%nso_lua%'                                                                                                   >> "!ps_tmp!"
echo $c = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)                                                            >> "!ps_tmp!"
echo $c = $c -replace 'mp\.set_property\("user-data/active_shader",\s*".*?"\)', ('mp.set_property("user-data/active_shader", "' + $val + '")') >> "!ps_tmp!"
echo [IO.File]::WriteAllText($f, $c, (New-Object Text.UTF8Encoding $true))                                             >> "!ps_tmp!"
powershell -NoProfile -ExecutionPolicy Bypass -File "!ps_tmp!"
del /f /q "!ps_tmp!" 2>nul

REM -- Done
echo.
echo ============================================================
echo Date format : !ps_format!
echo Shaders : !shader_mode!d (active_shader = !shader_init!)
echo ============================================================
echo Files updated:
echo - %bat_file%
echo - %lua_file%
echo - %conf_file%
echo - %compress_bat%
echo - %nso_lua%
echo ============================================================

REM -------------------------------------------------------
REM -- OPTIONAL: Create desktop shortcut to MPV-SW-Capture.vbs
REM -------------------------------------------------------
echo.
echo ============================================================
echo CREATE DESKTOP SHORTCUT FOR MPV-SW-Capture.vbs
echo ============================================================
echo [1] No  - Do not create shortcut
echo [2] Yes - Create shortcut on Desktop
echo ============================================================
echo.
:ask_shortcut
set "shortcut_sel="
set /p "shortcut_sel=Select option [1/2] : "
if "%shortcut_sel%"=="1" goto :no_shortcut
if "%shortcut_sel%"=="2" goto :make_shortcut
echo [X] Invalid option. Enter 1 or 2.
goto :ask_shortcut

:make_shortcut
REM Target VBS next to this setup script
set "VBS_TARGET=%~dp0MPV-SW-Capture.vbs"

REM Temp VBS that uses SpecialFolders("Desktop")
set "VBSFILE=%TEMP%\mk_mpv_shortcut_%RANDOM%.vbs"
> "%VBSFILE%" (
    echo Dim oWS, strDesktop, oLink
    echo Set oWS = CreateObject("WScript.Shell"^)
    echo strDesktop = oWS.SpecialFolders("Desktop"^)
    echo Set oLink = oWS.CreateShortcut(strDesktop ^& "\MPV-SW-Capture.lnk"^)
    echo oLink.TargetPath = "%VBS_TARGET%"
    echo oLink.WorkingDirectory = "%~dp0"
    echo oLink.Save
)
cscript //nologo "%VBSFILE%"
if errorlevel 1 (
    echo [X] Failed to create shortcut on Desktop.
) else (
    echo Shortcut created on Desktop.
)
del "%VBSFILE%" >nul 2>&1

:no_shortcut
echo.
echo Setup finished. Press any key to exit...
pause
endlocal