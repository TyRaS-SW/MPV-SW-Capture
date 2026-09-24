-- audio_mode.lua - Selects and controls the capture-audio architecture.
-- WASAPI plugin mode is the default: low latency and capturable by other
-- apps (Discord, OBS, etc.). FFplay is the fallback for systems where the
-- WASAPI plugin cannot be used.
--
-- Original design and implementation by z-er.
-- Fixes, refactoring and ongoing maintenance by TyRaS-SW.

local mp = require "mp"

local MIN_BOOST, MAX_BOOST = 100, 400

local function root()
    return (mp.get_property("config-path") or "."):gsub("\\", "/")
end

local settings = dofile(root() .. "/data/modules/msc_settings.lua")

-- ------------------------------------------------------------
-- OSD helper (mirrors check_version.lua's loading pattern)
-- ------------------------------------------------------------
-- All user-facing messages go through osd.safe_osd_message so they respect
-- the "Hide OSD Messages" toggle (osd-duration == 0). If osd_messages.lua
-- cannot be loaded, a minimal fallback with the same guard is used.
local osd

-- Returns the directory that contains this script, with a trailing
-- separator and forward slashes. Accepts either separator style so the
-- loader works regardless of how mpv reports the source path.
local function get_script_path()
    local info = debug.getinfo(1, "S")
    if not info or not info.source then return "" end
    local dir = info.source:match("@?(.*[/\\])")
    if not dir then return "" end
    return dir:gsub("\\", "/")
end

local script_dir = get_script_path()
local osd_path = script_dir .. "osd_messages.lua"

local ok, err = pcall(function()
    local loaded = dofile(osd_path)
    if loaded
       and type(loaded.get) == "function"
       and type(loaded.show) == "function"
       and type(loaded.safe_osd_message) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not expose get/show/safe_osd_message")
    end
end)

if ok then
    mp.msg.info("[audio_mode] osd_messages.lua loaded from " .. osd_path)
else
    -- Fallback: a single guarded emitter. `show` and `safe_osd_message`
    -- are the same function; the difference is only the caller's intent.
    local function show_text(text, duration)
        local ms = mp.get_property_number("osd-duration") or 1000
        if ms == 0 then return end
        if duration == nil then duration = ms / 1000 end
        mp.osd_message(text, duration)
    end

    osd = {
        get = function(key) return key end,
        show = show_text,
        safe_osd_message = show_text,
    }
    mp.msg.warn("[audio_mode] Using fallback OSD (osd_messages.lua not loaded): " .. tostring(err))
end

-- ------------------------------------------------------------
-- Minimal localization (mirrors msc_overlay's MENUMSG loader)
-- ------------------------------------------------------------
local MM, MM_SORTED = {}, {}

local function current_lang_code()
    local f = io.open(root() .. "/data/lang/OSDLang.dat", "r")
    if not f then return "en" end
    local s = (f:read("*a") or ""):gsub("^\239\187\191", ""):gsub("^%s+", ""):gsub("%s+$", "")
    f:close()
    return s == "" and "en" or s
end

local function load_kv(path)
    local d = {}
    local f = io.open(path, "r")
    if not f then return d end
    for line in f:lines() do
        local clean = line:gsub("^\239\187\191", "")
        if not clean:match("^%s*#") and not clean:match("^%s*$") then
            local k, v = clean:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if k and v and k ~= "" then d[k] = v end
        end
    end
    f:close()
    return d
end

local function esc_pat(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function reload_messages()
    local lang = current_lang_code()
    local base = root() .. "/data/lang/"
    MM = load_kv(base .. "MENUMSG_" .. lang .. ".dat")
    local en = load_kv(base .. "MENUMSG_en.dat")
    for k, v in pairs(en) do if MM[k] == nil then MM[k] = v end end
    MM_SORTED = {}
    for k, v in pairs(MM) do MM_SORTED[#MM_SORTED + 1] = { k, v } end
    table.sort(MM_SORTED, function(a, b) return #a[1] > #b[1] end)
end

local function T(s)
    if not s or s == "" then return s end
    local r = s
    for _, p in ipairs(MM_SORTED) do
        if r:find(p[1], 1, true) then
            r = r:gsub(esc_pat(p[1]), p[2])
        end
    end
    return r
end

reload_messages()

-- msc_overlay fires this when the user switches language.
mp.register_script_message("reload-osd-messages", reload_messages)

-- ------------------------------------------------------------
-- Mode handling
-- ------------------------------------------------------------
-- Only two modes are supported: "plugin" (WASAPI, default) and "ffplay".
-- Any other stored value (including the legacy "mpv") is upgraded to
-- "plugin" so old configs keep working after the removal of the mpv mode.
local function normalize_mode(value)
    value = tostring(value or ""):lower():gsub("%s+", "")
    if value == "ffplay" then return "ffplay" end
    return "plugin"
end

local function write_file(name, value)
    local ok, err = settings.write(name, value .. "\n")
    if not ok then mp.msg.error("[audio_mode] Cannot write " .. name .. ": " .. tostring(err)) end
    return ok
end

local function get_mode()
    return normalize_mode(settings.read("audio_mode.txt"))
end

-- Selecting a mode changes the next launch. Keep controls attached to the
-- backend that this process actually started until it is restarted.
local active_mode = get_mode()

local function publish_mode(mode)
    mp.set_property("user-data/audio-mode", mode)
end

local function clamp(value, min, max)
    value = tonumber(value) or min
    return math.max(min, math.min(max, value))
end

local function get_boost()
    return math.floor(clamp(settings.read("boost.txt"), MIN_BOOST, MAX_BOOST) + 0.5)
end

local function save_boost(value)
    return write_file("boost.txt", tostring(math.floor(value + 0.5)))
end

local function boost_to_db(boost)
    return 20 * math.log(boost / 100) / math.log(10)
end

local function apply_native_boost(boost)
    boost = math.floor(clamp(boost, MIN_BOOST, MAX_BOOST) / 25 + 0.5) * 25
    -- Derive the plugin's gain ceiling from MAX_BOOST so the two stay in
    -- sync if the maximum ever changes. The +0.1 dB margin lets the plugin
    -- accept the highest allowed value without clamping it internally.
    mp.set_property_number("volume-gain-max", boost_to_db(MAX_BOOST) + 0.1)
    mp.set_property_number("volume-gain", boost_to_db(boost))
    -- Only hit the disk when the value actually changed. This avoids a
    -- write on startup (where the value read from disk is re-applied) and
    -- on drag bursts that converge on the same step.
    if get_boost() ~= boost then save_boost(boost) end
    mp.set_property("user-data/audio-boost", tostring(boost))
    return boost
end

local function ps(rel, args)
    local command = { "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", root() .. "/" .. rel }
    for _, value in ipairs(args or {}) do command[#command + 1] = tostring(value) end
    mp.command_native_async({ name = "subprocess", args = command, playback_only = false }, function() end)
end

-- True for the in-process backend (WASAPI plugin). False for ffplay.
local function native()
    return active_mode ~= "ffplay"
end

local function set_volume(value)
    value = math.floor(clamp(value, 0, 100) + 0.5)
    if native() then
        mp.set_property_number("volume", value)
        mp.set_property("user-data/audio-volume", tostring(value))
    else
        ps("data/ffplayvol.ps1", { "set", "ffplay", value })
    end
end

local function change_volume(delta)
    if native() then
        set_volume((mp.get_property_number("volume") or 100) + delta)
    else
        ps("data/ffplayvol.ps1", { delta >= 0 and "up" or "down", "ffplay", math.abs(delta) })
    end
end

local function toggle_mute()
    if native() then
        mp.command("cycle mute")
    else
        ps("data/ffplayvol.ps1", { "togglemute", "ffplay" })
    end
end

local function set_boost(value)
    value = math.floor(clamp(value, MIN_BOOST, MAX_BOOST) / 25 + 0.5) * 25
    if native() then
        apply_native_boost(value)
    else
        ps("data/ffplayboost.ps1", { "set", value })
    end
end

local function change_boost(delta)
    set_boost(get_boost() + delta)
end

-- Mode selection from the menu. Persists the choice for the next launch and
-- tells the user a restart is needed. Refuses to switch to "plugin" if the
-- native DLL is missing.
mp.register_script_message("set-audio-mode", function(value)
    local mode = normalize_mode(value)
    if mode == "plugin" then
        local dll = io.open(root() .. "/scripts/msc_audio.dll", "rb")
        if not dll then
            osd.safe_osd_message(T("Audio plugin is not built. Run native-audio/build.ps1 first."), 5)
            return
        end
        dll:close()
    end
    if write_file("audio_mode.txt", mode) then
        publish_mode(mode)
        local msg = (mode == "ffplay")
            and T("FFplay low-latency audio selected. Restart MPV-SW-Capture to apply.")
            or  T("WASAPI Audio Plugin selected. Restart MPV-SW-Capture to apply.")
        osd.safe_osd_message(msg, 4)
    end
end)

-- Volume / mute / boost endpoints. These are called from msc_overlay.lua
-- (and from the edge slider rail), and dispatch to whichever backend is
-- currently active.
mp.register_script_message("audio-volume-set", function(value) set_volume(value) end)
mp.register_script_message("audio-volume-up", function(value) change_volume(tonumber(value) or 10) end)
mp.register_script_message("audio-volume-down", function(value) change_volume(-(tonumber(value) or 10)) end)
mp.register_script_message("audio-mute", toggle_mute)
mp.register_script_message("audio-boost-set", function(value) set_boost(value) end)
mp.register_script_message("audio-boost-up", function(value) change_boost(tonumber(value) or 25) end)
mp.register_script_message("audio-boost-down", function(value) change_boost(-(tonumber(value) or 25)) end)
mp.register_script_message("audio-boost-reset", function() set_boost(MIN_BOOST) end)

-- Starts the WASAPI plugin on the configured capture device. Triggered on
-- file-loaded (so it starts with the first stream) and from the "Restart
-- WASAPI Audio Plugin" menu action. Silent no-op if the active mode is
-- ffplay.
local function start_plugin()
    if active_mode ~= "plugin" then return end
    local loader = loadfile(root() .. "/scripts/usb3.lua")
    local ok, device = false, nil
    if loader then ok, device = pcall(loader) end
    if not ok or type(device) ~= "table" or not device.audio_device or device.audio_device == "" then
        osd.safe_osd_message(T("Audio plugin: no capture device configured. Run Setup first."), 6)
        return
    end
    mp.commandv("script-message", "msc-audio-start", device.audio_device)
end
mp.register_event("file-loaded", start_plugin)
mp.register_script_message("audio-plugin-restart", start_plugin)
mp.register_script_message("audio-plugin-status", function()
    -- "not loaded" is a short technical fallback; left untranslated on purpose
    -- to avoid substring collisions with other MENUMSG entries.
    osd.safe_osd_message(T("Audio plugin:") .. " "
        .. tostring(mp.get_property_native("user-data/audio-plugin-status") or "not loaded")
        .. "\n" .. tostring(mp.get_property_native("user-data/audio-plugin-details") or "")
        .. "\n" .. tostring(mp.get_property_native("user-data/audio-plugin-stats") or ""), 8)
end)

-- ------------------------------------------------------------
-- Startup
-- ------------------------------------------------------------
-- Publish the mode and boost the plugin will use. If the WASAPI plugin is
-- active, schedule the initial boost application on a short delay so the
-- DLL has time to register its properties before we set volume-gain.
publish_mode(active_mode)
mp.set_property("user-data/audio-active-mode", active_mode)
mp.set_property("user-data/audio-boost", tostring(get_boost()))
if active_mode ~= "ffplay" then
    mp.add_timeout(0.2, function()
        apply_native_boost(get_boost())
    end)
end
mp.msg.info("[audio_mode] active mode: " .. active_mode)