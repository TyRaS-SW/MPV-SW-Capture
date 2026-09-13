-- Add --script=tests/audio_plugin_video.lua to a normal capture launch with
-- plugin mode selected. Runs for 30 seconds, tests menu/control integration,
-- reports frame counters, then quits. No media is recorded.
local mp = require "mp"
local function prop(name) return mp.get_property_native("user-data/audio-plugin-" .. name) or "" end
local failure
mp.set_property_bool("mute", true)
mp.add_timeout(5, function()
    if prop("status") ~= "running" then failure = "plugin not running: " .. prop("status") end
    local details = prop("details")
    local pid = tonumber(details:match("^pid=(%d+)"))
    local session = tonumber(details:match("session_pid=(%d+)"))
    if not pid or pid ~= session then failure = "Windows audio session PID does not match MPV" end
    mp.msg.info(details)
    mp.commandv("script-message", "toggle-overlay")
end)
mp.add_timeout(6, function() mp.commandv("script-message", "close-overlay") end)
mp.add_timeout(8, function() mp.commandv("script-message-to", "audio_mode", "audio-volume-set", "50") end)
mp.add_timeout(9, function()
    if mp.get_property_number("volume") ~= 50 then failure = "volume routing failed" end
    mp.commandv("script-message-to", "audio_mode", "audio-volume-set", "100")
end)
mp.add_timeout(30, function()
    local stats = prop("stats")
    if prop("status") ~= "running" or (tonumber(stats:match("captured=(%d+)")) or 0) < 48000 then failure = "stream stopped" end
    if failure then mp.msg.error(failure) else
        mp.msg.info("PASS: 30s video/audio integration, session attribution, menu and volume. " .. stats
            .. " video_fps=" .. tostring(mp.get_property_number("estimated-vf-fps"))
            .. " dropped=" .. tostring(mp.get_property_number("frame-drop-count"))
            .. " delayed=" .. tostring(mp.get_property_number("vo-delayed-frame-count")))
    end
    mp.commandv("quit", failure and "1" or "0")
end)
