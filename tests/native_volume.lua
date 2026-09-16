-- Run from the project root:
-- mpv.exe --no-config --load-scripts=no --idle=yes --vo=null --ao=null --script=tests/native_volume.lua
local real_mp = require "mp"
local function test()
    local file = assert(io.open("scripts/msc_overlay.lua", "r"))
    local source = file:read("*a")
    file:close()
    assert(loadstring(source)) -- Also check syntax of the complete overlay.

    local function block(first, last)
        local start = assert(source:find(first, 1, true))
        local finish = assert(source:find(last, start + #first, true))
        return source:sub(start, finish - 1)
    end
    -- Exercise the production handlers with real MPV volume properties and
    -- controlled timers/subprocesses; no capture device or FFplay is required.
    local checks = [[
local audio = { version = 0 }
local visible, edge_visible = false, false
local volume_debounce, edge_drag
local BOOST = 400
local calls, timers = {}, {}
local function render() end
local function edge_render() end
local function ps(path, args) calls[#calls + 1] = { path, args } end
local mp = setmetatable({}, { __index = real_mp })
function mp.add_timeout(delay, callback)
    local timer = { callback = callback, killed = false }
    function timer:kill() self.killed = true end
    timers[#timers + 1] = timer
    return timer
end
]] .. block("local function using_native_audio()", "local function schedule_boost_send")
    .. block("local function volset(v)", "local function boostset(v)")
    .. block("edge_set_from_y = function", "local function edge_mousemove()")
    .. block("local function fromx(h, x)", "local function stopdrag()") .. [[
real_mp.set_property("user-data/audio-mode", "mpv")
real_mp.set_property_number("volume", 73)
real_mp.set_property("user-data/audio-volume", "99")
audio_refresh()
assert(audio.volume == 73, "refresh must read actual MPV volume: " .. tostring(audio.volume) .. " mode=" .. tostring(real_mp.get_property("user-data/audio-mode")))
local edge = { y1 = 0, y2 = 100, meter = "volume" }
edge_set_from_y(75, edge)
assert(real_mp.get_property_number("volume") == 25, "edge drag must apply immediately")
edge_set_from_y(100, edge)
assert(real_mp.get_property_number("volume") == 0, "edge minimum")
edge_set_from_y(-10, edge)
assert(real_mp.get_property_number("volume") == 100, "edge maximum/clamping")
local bar = { bar_x1 = 0, bar_x2 = 100, meter = "volume" }
fromx(bar, 42)
assert(real_mp.get_property_number("volume") == 42, "Audio page drag must apply immediately")
assert(#timers == 0 and #calls == 0, "native volume must not use PowerShell or debounce")
schedule_volume_send(42)
assert(#timers == 0, "native release must also be immediate")

real_mp.set_property("user-data/audio-mode", "ffplay")
edge_set_from_y(80, edge)
fromx(bar, 30)
assert(audio.volume == 30 and #calls == 0 and #timers == 0, "FFplay drag stays visual until release")
assert(real_mp.get_property_number("volume") == 42, "FFplay must not change MPV volume")
schedule_volume_send(30)
schedule_volume_send(55)
assert(timers[1].killed and not timers[2].killed, "FFplay sends must coalesce")
timers[2].callback()
assert(#calls == 1 and calls[1][1] == "data/ffplayvol.ps1", "FFplay backend retained")
assert(calls[1][2][1] == "set" and calls[1][2][2] == "ffplay" and calls[1][2][3] == "55", "FFplay final value")

schedule_volume_send(10)
real_mp.set_property("user-data/audio-mode", "mpv")
schedule_volume_send(65)
assert(timers[3].killed, "native update cancels pending volume timer")
assert(real_mp.get_property_number("volume") == 65, "native volume after mode change")
]]
    local run = assert(loadstring(checks))
    setfenv(run, setmetatable({ real_mp = real_mp }, { __index = _G }))
    run()
end

real_mp.add_timeout(0, function()
    local ok, err = pcall(test)
    if ok then real_mp.msg.info("PASS: native and FFplay volume regression checks")
    else real_mp.msg.error(tostring(err)) end
    real_mp.commandv("quit", ok and "0" or "1")
end)
