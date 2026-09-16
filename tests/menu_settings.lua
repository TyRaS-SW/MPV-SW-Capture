-- Headless migration test; all settings and I/O are in memory.
local mp = require "mp"
local f = assert(io.open("scripts/modules/msc_settings.lua", "r"))
local source = f:read("*a"); f:close()
local function test()
    local files, read_only, missing_dir, repairs = {}, false, false, 0
    local env = setmetatable({io = {open = function(path, mode)
        if mode == "r" then
            if files[path] == nil then return nil end
            return {read = function() return files[path] end, close = function() return true end}
        end
        if read_only or missing_dir then return nil, "unwritable" end
        return {write = function(_, value) files[path] = value; return true end, close = function() return true end}
    end}, require = function()
        return {get_property = function() return "C:/Capture Test's" end,
            msg = {warn = function() end}, command_native = function(command)
                assert(command.args[6] == "C:/Capture Test's/data/menu_settings.ps1")
                repairs = repairs + 1; missing_dir = false
            end}
    end}, {__index = _G})
    local load = assert(loadstring(source)); setfenv(load, env)
    local settings = load()
    local root = "C:/Capture Test's/data/"
    assert(settings.read("audio_mode.txt") == nil, "fresh installation has no stored selection")
    for name, value in pairs({["audio_mode.txt"]="ffplay", ["boost.txt"]="225", ["hover_volume.txt"]="no"}) do
        files[root .. name] = value
        assert(settings.read(name) == value)
        assert(files[root .. "menu/" .. name] == value, "legacy setting must be migrated")
        assert(files[root .. name] == value, "legacy backup must be retained")
    end
    files[root .. "menu/audio_mode.txt"] = "mpv"
    assert(settings.read("audio_mode.txt") == "mpv", "new preference wins over old backup")
    files[root .. "menu/audio_mode.txt"] = nil
    read_only = true
    assert(settings.read("audio_mode.txt") == "ffplay", "read-only legacy selection is still honoured")
    assert(not settings.write("boost.txt", "300"), "failed save is reported")
    read_only = false; missing_dir = true
    assert(settings.write("boost.txt", "300"), "missing directory repaired")
    assert(repairs > 0 and settings.read("boost.txt") == "300")
end
mp.add_timeout(0, function()
    local ok, err = pcall(test)
    if ok then print("PASS: migration, existing preferences, defaults, read-only and directory repair")
    else print("FAIL: " .. tostring(err)) end
    mp.commandv("quit", ok and "0" or "1")
end)
