-- Run from the project root with the bundled MPV:
-- mpv.exe --no-config --load-scripts=no --idle=yes --vo=null --ao=null --script=tests/native_menu.lua
local mp = require "mp"
mp.set_property("user-data/audio-mode", "mpv")
mp.set_property("user-data/audio-boost", "100")
dofile("scripts/msc_overlay.lua")

mp.add_timeout(0.1, function()
    local ok, err = pcall(function()
        -- Exercise the complete overlay, including synchronous native refresh
        -- and rendering, on both first opening and reopening the menu.
        show()
        hide()
        show()
        hide()
    end)
    if ok then mp.msg.info("PASS: native menu opens and reopens")
    else mp.msg.error(tostring(err)) end
    mp.commandv("quit", ok and "0" or "1")
end)
