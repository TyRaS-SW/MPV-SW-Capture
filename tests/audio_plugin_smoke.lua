-- Requires configured capture hardware. Does not record audio or video.
-- mpv.exe --no-config --load-scripts=no --idle=yes --vo=null --ao=null --script=scripts/msc_audio.dll --script=tests/audio_plugin_smoke.lua
local mp = require "mp"
local device = assert(dofile("scripts/usb3.lua").audio_device)
local function prop(name) return mp.get_property_native("user-data/audio-plugin-" .. name) or "" end
local function fail(message) mp.msg.error(message); mp.commandv("quit", "1") end
mp.set_property_bool("mute", true)
mp.add_timeout(1, function() mp.commandv("script-message", "msc-audio-start", device) end)
mp.add_timeout(4, function()
    mp.msg.info(prop("status") .. " " .. prop("details") .. " " .. prop("stats"))
    if prop("status") ~= "running" then fail("plugin did not start"); return end
    if not prop("stats"):find("gain=0.0000", 1, true) then fail("mute not applied"); return end
    mp.set_property_number("volume", 0)
    mp.set_property_bool("mute", false)
end)
mp.add_timeout(6, function()
    if not prop("stats"):find("gain=0.0000", 1, true) then fail("zero volume not applied"); return end
    mp.commandv("script-message", "msc-audio-stop")
end)
mp.add_timeout(7, function()
    if prop("status") ~= "stopped" then fail("plugin did not stop"); return end
    mp.set_property_number("volume", 25)
    mp.set_property_number("volume-gain-max", 12.1)
    mp.set_property_number("volume-gain", 20 * math.log(2) / math.log(10))
    mp.commandv("script-message", "msc-audio-start", "MSC deliberately missing test device")
end)
mp.add_timeout(9, function()
    if not prop("status"):find("error:", 1, true) then fail("missing device did not report an error"); return end
    if not prop("stats"):find("gain=0.5000", 1, true) then fail("volume/boost not applied"); return end
    mp.set_property_number("volume", 0)
    mp.commandv("script-message", "msc-audio-start", device)
end)
mp.add_timeout(12, function()
    local stats = prop("stats")
    local captured = tonumber(stats:match("captured=(%d+)")) or 0
    local rendered = tonumber(stats:match("rendered=(%d+)")) or 0
    if prop("status") ~= "running" or captured == 0 or rendered == 0 then fail("plugin restart did not stream"); return end
    mp.msg.info("PASS: live plugin capture/render, mute, volume/boost, missing device error, stop and restart: " .. stats)
    mp.commandv("quit", "0")
end)
