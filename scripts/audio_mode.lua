-- audio_mode.lua - Selects and controls the capture-audio architecture.
-- ffplay mode remains the default for the lowest latency. mpv mode attaches
-- the DirectShow audio source to mpv so application-audio capture (Discord,
-- OBS, etc.) can see MPV-SW-Capture as the producing process.

local mp = require "mp"

local MIN_BOOST, MAX_BOOST = 100, 400

local function root()
    return (mp.get_property("config-path") or "."):gsub("\\", "/")
end

local function mode_path()
    return root() .. "/data/audio_mode.txt"
end

local function boost_path()
    return root() .. "/data/boost.txt"
end

local function normalize_mode(value)
    value = tostring(value or ""):lower():gsub("%s+", "")
    return value == "mpv" and "mpv" or "ffplay"
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local value = f:read("*a")
    f:close()
    return value
end

local function write_file(path, value)
    local f, err = io.open(path, "w")
    if not f then
        mp.msg.error("[audio_mode] Cannot write " .. path .. ": " .. tostring(err))
        return false
    end
    f:write(value .. "\n")
    f:close()
    return true
end

local function get_mode()
    return normalize_mode(read_file(mode_path()))
end

local function publish_mode(mode)
    mp.set_property("user-data/audio-mode", mode)
end

local function clamp(value, min, max)
    value = tonumber(value) or min
    return math.max(min, math.min(max, value))
end

local function get_boost()
    return math.floor(clamp(read_file(boost_path()), MIN_BOOST, MAX_BOOST) + 0.5)
end

local function save_boost(value)
    return write_file(boost_path(), tostring(math.floor(value + 0.5)))
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
    return get_mode() == "mpv"
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
    if write_file(mode_path(), mode) then
        publish_mode(mode)
        mp.osd_message(mode == "mpv"
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

local mode = get_mode()
publish_mode(mode)
mp.set_property("user-data/audio-boost", tostring(get_boost()))
if mode == "mpv" then mp.add_timeout(0.2, function() apply_native_boost(get_boost()) end) end
mp.msg.info("[audio_mode] active mode: " .. mode)
