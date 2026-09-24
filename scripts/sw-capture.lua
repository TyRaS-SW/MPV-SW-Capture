-- sw-capture.lua - For MPV-SW-Capture - By TyRaS-SW
-- Uses a global PowerShell named mutex to prevent relaunches.
-- No temporary lock files.

if mp.get_opt("skip") == "1" then
    mp.msg.info("[sw-capture] launcher instance detected, capture startup skipped")
    return
end

local function get_root_dir()
    local script_path = debug.getinfo(1, 'S').source:sub(2)
    script_path = script_path:gsub('/', '\\')
    return script_path:match('^(.+)\\[^\\]+\\[^\\]+$') or '.'
end

local function is_bare_launch()
    return (tonumber(mp.get_property('playlist-count')) or 0) == 0
end

local function ps_capture(ps)
    return mp.command_native({
        name = 'subprocess',
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = {'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', ps}
    })
end

-- Escapes a string for inclusion inside a single-quoted PowerShell string
-- literal. Doubling the apostrophes is the PS escape rule.
local function ps_escape(s)
    return (s:gsub("'", "''"))
end

-- Combined precheck. Runs everything the previous version did with three
-- sequential PowerShell launches in a single round-trip:
--   * count this installation's mpv.exe processes,
--   * count this installation's ffplay.exe processes,
--   * attempt to acquire the named mutex.
-- Output format: "mpv=N ffplay=N mutex=LOCK_OK|LOCK_FAIL".
-- Returns (mpv_count, ffplay_count, mutex_ok).
local function combined_precheck(root, mutex_name)
    local mpv_exe    = ps_escape(root .. '\\mpv.exe')
    local ffplay_exe = ps_escape(root .. '\\ffplay.exe')
    local mutex_esc  = ps_escape(mutex_name)

    local ps = table.concat({
        "$mpvExe = [System.IO.Path]::GetFullPath('" .. mpv_exe .. "')",
        "$ffplayExe = [System.IO.Path]::GetFullPath('" .. ffplay_exe .. "')",

        "$mpvCount = (Get-Process -Name 'mpv' -ErrorAction SilentlyContinue | " ..
            "Where-Object { $_.Path -eq $mpvExe } | Measure-Object).Count",
        "$ffplayCount = (Get-Process -Name 'ffplay' -ErrorAction SilentlyContinue | " ..
            "Where-Object { $_.Path -eq $ffplayExe } | Measure-Object).Count",

        "$created = $false",
        "$m = New-Object System.Threading.Mutex($true, '" .. mutex_esc .. "', [ref]$created)",
        "$mutexResult = if ($created) { 'LOCK_OK' } else { 'LOCK_FAIL' }",

        "Write-Output ('mpv=' + $mpvCount + ' ffplay=' + $ffplayCount + ' mutex=' + $mutexResult)"
    }, '; ')

    local res = ps_capture(ps)
    local out = (res and res.status == 0 and res.stdout) or ''
    local mpv_c    = tonumber(out:match('mpv=(%d+)'))    or 0
    local ffplay_c = tonumber(out:match('ffplay=(%d+)')) or 0
    local mutex_ok = out:match('mutex=LOCK_OK') ~= nil
    return mpv_c, ffplay_c, mutex_ok
end

-- Lightweight ffplay count, used only by the orphan-cleanup path to
-- confirm the watchdog actually stopped the audio process. Runs a single
-- Get-Process and skips the mutex check, which we already performed.
local function count_ffplay(root)
    local ffplay_exe = ps_escape(root .. '\\ffplay.exe')
    local ps = "$ffplayExe = [System.IO.Path]::GetFullPath('" .. ffplay_exe .. "'); " ..
               "(Get-Process -Name 'ffplay' -ErrorAction SilentlyContinue | " ..
               "Where-Object { $_.Path -eq $ffplayExe } | Measure-Object).Count"
    local res = ps_capture(ps)
    if not res or res.status ~= 0 or not res.stdout then return 0 end
    return tonumber((res.stdout:gsub('%s+', ''))) or 0
end

if not is_bare_launch() then
    mp.msg.info('[sw-capture] capture instance detected, script ignored')
    return
end

local root = get_root_dir()
local bat = root .. '\\data\\MPV-SW-Capture.bat'
local mutex_name = 'Global\\SW_CAPTURE_MPV_SINGLE_INSTANCE'

-- All the PowerShell work is deferred. mpv blocks on every script's
-- top-level code until it finishes its own init, and the previous version
-- ran three sequential PowerShell launches (~3 s) inside that window.
-- Deferring moves the work off the critical path: mpv finishes init,
-- shows the window, and the checks run in the background.
mp.add_timeout(0, function()
    -- Single combined PowerShell: process counts + mutex acquisition.
    -- This replaces three sequential round-trips (~3 s) with one (~1 s).
    local mpv_count, ffplay_count, mutex_ok = combined_precheck(root, mutex_name)
    mp.msg.info(string.format('[sw-capture] precheck → mpv=%d ffplay=%d mutex=%s',
        mpv_count, ffplay_count, mutex_ok and 'OK' or 'FAIL'))

    if mpv_count >= 2 then
        mp.msg.warn('[sw-capture] active session detected, blocking launch')
        mp.commandv('quit')
        return
    end

    if ffplay_count >= 1 then
        -- No capture MPV is running (the one counted above is this launcher).
        -- Recover audio left behind by a crash or an older watchdog.
        mp.msg.info('[sw-capture] cleaning up orphaned capture audio')
        mp.command_native({
            name = 'subprocess', playback_only = false,
            capture_stdout = true, capture_stderr = true,
            args = {'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                '-File', root .. '\\data\\ffplay_watchdog.ps1', '-CleanupOnly'}
        })
        if count_ffplay(root) >= 1 then
            mp.msg.error('[sw-capture] could not stop orphaned capture audio')
            mp.commandv('quit')
            return
        end
    end

    if not mutex_ok then
        mp.msg.warn('[sw-capture] mutex busy, blocking launch')
        mp.commandv('quit')
        return
    end

    local f = io.open(bat, 'r')
    if not f then
        ps_capture("$m = [System.Threading.Mutex]::OpenExisting('" .. ps_escape(mutex_name) .. "'); $m.ReleaseMutex(); $m.Dispose()")
        mp.msg.error('[sw-capture] .bat not found: ' .. bat)
        mp.commandv('quit')
        return
    end
    f:close()

    mp.msg.info('[sw-capture] mutex acquired, launching bat: ' .. bat)
    mp.command_native({
        name = 'subprocess',
        playback_only = false,
        detach = true,
        args = {'cmd.exe', '/d', '/c', bat}
    })

    mp.add_timeout(0.15, function()
        mp.commandv('quit')
    end)
end)