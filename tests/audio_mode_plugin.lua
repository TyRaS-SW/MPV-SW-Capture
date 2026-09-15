-- Headless routing test: no devices or real settings are touched.
-- mpv.exe --no-config --load-scripts=no --idle=yes --vo=null --ao=null --script=tests/audio_mode_plugin.lua
local real_mp = require "mp"
local file = assert(io.open("scripts/audio_mode.lua", "r"))
local source = file:read("*a"); file:close()
local module_file = assert(io.open("scripts/modules/msc_settings.lua", "r"))
local module_source = module_file:read("*a"); module_file:close()
local function scenario(initial, selected, saved)
    local files = { ["./data/audio_mode.txt"] = initial, ["./data/boost.txt"] = "100", ["./scripts/msc_audio.dll"] = "present" }
    if saved == false then files["./data/audio_mode.txt"] = nil end
    local props, messages, events, calls = {}, {}, {}, {}
    local mock = {
        msg = { error = error, info = function() end },
        get_property = function(key) return props[key] end,
        get_property_number = function(key) return tonumber(props[key]) end,
        set_property = function(key, value) props[key] = value end,
        set_property_number = function(key, value) props[key] = value end,
        osd_message = function() end,
        register_script_message = function(key, cb) messages[key] = cb end,
        register_event = function(key, cb) events[key] = cb end,
        add_timeout = function(_, cb) cb() end,
        command_native_async = function(command) calls[#calls + 1] = command.args end,
        commandv = function(...) calls[#calls + 1] = {...} end,
    }
    local fake_io = { open = function(path, mode)
        if mode ~= "w" and not files[path] then return nil end
        return { read = function() return files[path] end, write = function(_, value) files[path] = value; return true end, close = function() return true end }
    end }
    local run = assert(loadstring(source))
    local env = setmetatable({ io = fake_io, require = function() return mock end,
        loadfile = function() return function() return {audio_device = "Test Capture"} end end }, {__index = _G})
    env.dofile = function(path)
        assert(path == "./scripts/modules/msc_settings.lua")
        local load = assert(loadstring(module_source)); setfenv(load, env); return load()
    end
    setfenv(run, env)
    run()
    assert(props["user-data/audio-active-mode"] == initial)
    messages["set-audio-mode"](selected)
    assert(props["user-data/audio-mode"] == selected)
    assert(files["./data/menu/audio_mode.txt"] == selected .. "\n", "selection must use the new settings folder")
    assert(props["user-data/audio-active-mode"] == initial, "selection must not change the running backend")
    messages["audio-volume-set"]("25")
    if initial == "ffplay" then
        assert(calls[#calls][6] == "./data/ffplayvol.ps1", "FFplay must remain active until restart")
    else
        assert(props.volume == 25, "in-process volume must update MPV properties")
        messages["audio-boost-set"]("200")
        assert(math.abs(props["volume-gain"] - 6.0205999) < .00001)
    end
    local before = #calls
    events["file-loaded"]()
    if initial == "plugin" then
        assert(#calls == before + 1 and calls[#calls][2] == "msc-audio-start" and calls[#calls][3] == "Test Capture")
    else assert(#calls == before, "other modes must never start plugin audio") end
end
real_mp.add_timeout(0, function()
    local ok, err = pcall(function()
        scenario("ffplay", "plugin")
        scenario("plugin", "ffplay")
        scenario("mpv", "plugin")
        scenario("plugin", "ffplay", false)
    end)
    if ok then real_mp.msg.info("PASS: plugin routing, boost, startup and mode changes deferred until restart")
    else real_mp.msg.error(tostring(err)) end
    real_mp.commandv("quit", ok and "0" or "1")
end)
