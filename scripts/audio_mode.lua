-- audio_mode.lua - Selects and controls the capture-audio architecture.
-- WASAPI plugin mode is the default for new installations. mpv mode attaches
-- the DirectShow audio source to mpv so application-audio capture (Discord,
-- OBS, etc.) can see MPV-SW-Capture as the producing process.

local mp = require "mp"

local MIN_BOOST, MAX_BOOST = 100, 400

local function root()
    return (mp.get_property("config-path") or "."):gsub("\\", "/")
end

local settings = dofile(root() .. "/scripts/modules/msc_settings.lua")

local function normalize_mode(value)
    value = tostring(value or ""):lower():gsub("%s+", "")
    if value == "" then return "plugin" end
    return (value == "mpv" or value == "plugin") and value or "ffplay"
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
    -- Four times amplitude is ~12.04 dB. Permit that full requested range.
    mp.set_property_number("volume-gain-max", 12.1)
    mp.set_property_number("volume-gain", boost_to_db(boost))
    save_boost(boost)
    mp.set_property("user-data/audio-boost", tostring(boost))
    return boost
end

local function ps(rel, args)
    local command = { "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", root() .. "/" .. rel }
    for _, value in ipairs(args or {}) do command[#command + 1] = tostring(value) end
    mp.command_native_async({ name = "subprocess", args = command, playback_only = false }, function() end)
end

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

mp.register_script_message("set-audio-mode", function(value)
    local mode = normalize_mode(value)
    if mode == "plugin" then
        local dll = io.open(root() .. "/scripts/msc_audio.dll", "rb")
        if not dll then
            mp.osd_message("Audio plugin is not built. Run native-audio/build.ps1 first.", 5)
            return
        end
        dll:close()
    end
    if write_file("audio_mode.txt", mode) then
        publish_mode(mode)
        mp.osd_message(mode == "plugin"
            and "WASAPI Audio Plugin selected. Restart MPV-SW-Capture to apply."
            or mode == "mpv"
            and "MPV native capture audio selected. Restart MPV-SW-Capture to apply."
            or "FFplay low-latency audio selected. Restart MPV-SW-Capture to apply.", 4)
    end
end)

mp.register_script_message("audio-volume-set", function(value) set_volume(value) end)
mp.register_script_message("audio-volume-up", function(value) change_volume(tonumber(value) or 10) end)
mp.register_script_message("audio-volume-down", function(value) change_volume(-(tonumber(value) or 10)) end)
mp.register_script_message("audio-mute", toggle_mute)
mp.register_script_message("audio-boost-set", function(value) set_boost(value) end)
mp.register_script_message("audio-boost-up", function(value) change_boost(tonumber(value) or 25) end)
mp.register_script_message("audio-boost-down", function(value) change_boost(-(tonumber(value) or 25)) end)
mp.register_script_message("audio-boost-reset", function() set_boost(MIN_BOOST) end)

local function start_plugin()
    if active_mode ~= "plugin" then return end
    local loader = loadfile(root() .. "/scripts/usb3.lua")
    local ok, device = false, nil
    if loader then ok, device = pcall(loader) end
    if not ok or type(device) ~= "table" or not device.audio_device or device.audio_device == "" then
        mp.osd_message("Audio plugin: no capture device configured. Run Setup first.", 6)
        return
    end
    mp.commandv("script-message", "msc-audio-start", device.audio_device)
end
mp.register_event("file-loaded", start_plugin)
mp.register_script_message("audio-plugin-restart", start_plugin)
mp.register_script_message("audio-plugin-status", function()
    mp.osd_message("Audio plugin: " .. tostring(mp.get_property_native("user-data/audio-plugin-status") or "not loaded")
        .. "\n" .. tostring(mp.get_property_native("user-data/audio-plugin-details") or "")
        .. "\n" .. tostring(mp.get_property_native("user-data/audio-plugin-stats") or ""), 8)
end)

local mode = active_mode
publish_mode(mode)
mp.set_property("user-data/audio-active-mode", mode)
mp.set_property("user-data/audio-boost", tostring(get_boost()))
if mode ~= "ffplay" then
    mp.add_timeout(0.2, function()
        apply_native_boost(get_boost())
    end)
end
mp.msg.info("[audio_mode] active mode: " .. mode)
