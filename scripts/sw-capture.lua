-- sw-capture.lua - For MPV-SW-Capture - By TyRaS-SW
-- Uses a global PowerShell named mutex to prevent relaunches.
-- No temporary lock files.

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

local function count_processes(image_name)
    local ps = "$p = Get-Process -Name '" .. image_name:gsub('%.exe$', '') .. "' -ErrorAction SilentlyContinue; if ($p) { ($p | Measure-Object).Count } else { 0 }"
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

local mpv_count = count_processes('mpv.exe')
local ffplay_count = count_processes('ffplay.exe')
mp.msg.info(string.format('[sw-capture] precheck → mpv=%d ffplay=%d', mpv_count, ffplay_count))

if mpv_count >= 2 or ffplay_count >= 1 then
    mp.msg.warn('[sw-capture] active session detected, blocking launch')
    mp.commandv('quit')
    return
end

local acquire_ps = table.concat({
    "$created = $false",
    "$m = New-Object System.Threading.Mutex($true, '" .. mutex_name .. "', [ref]$created)",
    "if ($created) { 'LOCK_OK' } else { 'LOCK_FAIL' }"
}, '; ')

local acquire = ps_capture(acquire_ps)
local out = (acquire and acquire.stdout) or ''
if not out:match('LOCK_OK') then
    mp.msg.warn('[sw-capture] mutex busy, blocking launch')
    mp.commandv('quit')
    return
end

local f = io.open(bat, 'r')
if not f then
    ps_capture("$m = [System.Threading.Mutex]::OpenExisting('" .. mutex_name .. "'); $m.ReleaseMutex(); $m.Dispose()")
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