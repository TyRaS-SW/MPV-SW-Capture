# Experimental in-process audio

This prototype tests independent capture/playback inside `mpv.exe`. It is a C++
MPV plugin using Windows WASAPI directly, not FFplay compiled into a DLL. MPV
continues to render video without waiting for the plugin's audio clock.

## Design and implementation plan

1. Load a DLL through MPV's supported C plugin interface.
2. Open the configured capture device by its exact Windows friendly name or
   endpoint ID. Do not fall back to a microphone if the configured device is absent.
3. Run event-driven shared-mode capture and rendering on one dedicated audio
   thread. Request the driver's minimum shared period, with a default-period
   fallback. Render through the default multimedia output device.
4. Convert endpoint PCM/float data through a bounded stereo queue and linear
   resampler. Apply a small clock-drift correction and discard stale queued
   audio after a stall rather than accumulating delay indefinitely.
5. Observe MPV volume, mute and volume-gain for the existing controls. Ramp gain
   changes over approximately 5 ms and clip boosted samples at full scale.
6. Expose diagnostics, handle errors visibly, and release both audio clients on
   stop/shutdown. Keep the existing FFplay and MPV Native modes available.
7. Compare live audio latency, video frame pacing and process capture with the
   existing modes before considering this a replacement.

## Build

Windows x64; MSYS2 UCRT64 GCC is required. From the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File native-audio/build.ps1
```

Override `-Compiler` if GCC is elsewhere. Close this app before rebuilding a
loaded DLL. The script builds `scripts/msc_audio.dll` and runs the portable audio
core tests. C++/GCC runtime libraries are statically linked; the DLL uses Windows
system DLLs at runtime. Generated binaries are ignored by Git.

The vendored `vendor/mpv/client.h` is from MPV v0.40.0, under its included ISC
license: https://github.com/mpv-player/mpv/blob/v0.40.0/include/mpv/client.h
The plugin resolves its API from the host MPV executable and does not link a
second copy of libmpv. MPV must support C plugins.

## Try it / switch back

Use **Audio > In-process Audio Plugin (Experimental)**, quit, then reopen the
app. The launcher opens video only; the DLL captures and renders audio inside
that same MPV process. No FFplay process is started. **Audio Plugin Diagnostics**
shows status, device rates, engine periods, queue occupancy, underruns and gain.
**Restart Audio Plugin** retries after a device/output change or an error.

To roll back, select **FFplay Low Latency** or **MPV Native**, then restart.
Selections apply on the next launch; controls keep operating the current backend
until then. If the UI cannot open, set `data/menu/audio_mode.txt` to `ffplay` while
the app is closed. A missing DLL prevents selecting the plugin mode.

## Validation and limits

`tests/audio_plugin_smoke.lua` tests real capture/render, mute, zero volume,
boost, missing-device errors, stop/restart and shutdown without recording audio
or video. It starts muted.
Its header has the command. `tests/audio_mode_plugin.lua` tests routing and mode
selection without hardware. Existing volume/menu tests also apply.

Local trial on 2026-09-13: USB capture at 48 kHz stereo, default output at
384 kHz stereo, 10 ms input/output engine periods, 20 ms target queue.
The 30-second `tests/audio_plugin_video.lua` run completed at a reported 60 fps
with zero audio underruns or queue drops, and zero MPV frame-drop/delay counters.
Windows reported the render session's PID as the same PID as MPV. The existing
DirectShow video launch did emit buffer-overflow warnings during initialization;
MPV's frame counters are not a measurement of that startup loss. No comparative
end-to-end latency or Discord/OBS test has been performed yet.

The engine accepts float32 and PCM16/24/32 mix formats. Mono is duplicated;
multichannel capture uses its first two channels, and multichannel output uses
front left/right only. Linear resampling is a prototype tradeoff. Shared output
keeps Windows application-audio capture available. Endpoint changes require a
plugin restart; it does not silently switch input devices.

Queue diagnostics are software occupancy, **not measured end-to-end latency**.
Independent audio/video clocks do not guarantee lip sync. No fixed -3-second
offset is applied in this mode. Discord and OBS capture must be verified in those
applications; successful WASAPI rendering alone does not prove compatibility.
