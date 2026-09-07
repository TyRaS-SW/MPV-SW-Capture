' ============================================================
' MPV-SW-Capture Launcher
' ============================================================
' Detects what the console is sending, starts the capture video in that
' mode, then starts the capture audio - all with no console window.
'
' Order matters:
'   1. detect_signal.ps1 probes the card (it needs the device exclusively)
'      and then starts mpv in the detected mode via set_mode.ps1.
'   2. ffplay opens the audio pin afterwards.
'
' Why not the other obvious routes:
'   * data\MPV-SW-Capture.bat  - starts ffplay FIRST, and its own precheck
'     then sees ffplay running and refuses to start the video instance.
'   * bare mpv.exe             - scripts\sw-capture.lua bootstraps that .bat
'     and inherits the same ordering problem: audio, no picture.
'
' Run(..., 0, False): 0 hides the window, False = do not wait.
' ============================================================
Option Explicit

Dim shell, fso, root, videoDev, audioDev, mpvArgs, ffArgs, detectPs

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
root = fso.GetParentFolderName(WScript.ScriptFullName)

' Keep these in sync with data\MPV-SW-Capture.bat
videoDev = "UGREEN 25173"
audioDev = "HDMI (UGREEN 25173)"

shell.CurrentDirectory = root

' --- video ---------------------------------------------------
' Starts in the LAST MODE YOU PICKED, saved in data\capture_mode.txt by
' the menu (ESC > Video > Capture Mode). Change it there; it sticks.
'
' Auto-detection was tried and removed on purpose: probing the card needs
' the capture device exclusively, which added ~4s to every launch, and the
' card silently upscales a smaller source anyway - so a wrong mode costs
' sharpness, not a broken picture. Manual is faster and predictable.
'
' NOTE: --demuxer-lavf-o-APPEND, not -o-set. Each -o-set replaces the whole
' option map, so multiple -o-set flags discard all but the last.
Dim modeFile, modeFlags
modeFile = root & "\data\capture_mode.txt"
modeFlags = ""

If fso.FileExists(modeFile) Then
  On Error Resume Next
  modeFlags = Trim(fso.OpenTextFile(modeFile, 1).ReadAll())
  On Error GoTo 0
End If

If modeFlags = "" Then
  ' First run, or the saved mode was lost: 1080p60 raw.
  modeFlags = "--demuxer-lavf-o-append=pixel_format=yuyv422" & _
              " --demuxer-lavf-o-append=video_size=1920x1080" & _
              " --demuxer-lavf-o-append=framerate=60" & _
              " --demuxer-lavf-o-append=rtbufsize=67108864" & _
              " --container-fps-override=60"
End If

mpvArgs = """" & root & "\mpv.exe""" & _
  " --no-border ""av://dshow:video=" & videoDev & """" & _
  " --profile=low-latency " & modeFlags & _
  " --sws-scaler=point --vd-lavc-threads=4 --untimed --demuxer-thread=no" & _
  " --vo=gpu-next --hwdec=auto-safe --target-colorspace-hint=no" & _
  " --cursor-autohide=100 --window-scale=1.0 --osc=no" & _
  " --script-opts=msc_check_version_auto=0"

shell.Run mpvArgs, 0, False

' Give the capture device a moment before the audio side opens it.
WScript.Sleep 1500

' --- audio ---------------------------------------------------
shell.Environment("PROCESS")("SDL_AUDIODRIVER") = "wasapi"
shell.Environment("PROCESS")("SDL_AUDIO_SAMPLES") = "128"

ffArgs = """" & root & "\ffplay.exe""" & _
  " -f dshow -audio_buffer_size 4 -i ""audio=" & audioDev & """" & _
  " -volume 100 -fflags nobuffer+fastseek -flags low_delay" & _
  " -strict experimental -nodisp -hide_banner -loglevel quiet"

shell.Run ffArgs, 0, False

' Re-apply the saved Audio Boost level, if any (no-op at 100%).
If fso.FileExists(root & "\data\ffplayboost.ps1") Then
  WScript.Sleep 2500
  shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & _
            root & "\data\ffplayboost.ps1"" apply", 0, False
End If
