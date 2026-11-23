-- msc_colorfix.lua - For MPV-SW-Capture - By TyRaS-SW
-- Dynamic BT.601 to BT.709 color correction
-- Uses mpv's native format filter to avoid runtime bracket parsing issues.

local mp = require 'mp'

local filter_label = "@msc_colorfix"
local filter_str = "@msc_colorfix:format=colormatrix=bt.709"
local updating = false

local function check_colorfix()
    if updating then return end
    
    local vp = mp.get_property_native("video-params")
    if not vp then return end
    
    local matrix = vp["colormatrix"]
    local h = vp["h"]
    local gamma = vp["gamma"]
    
    if not matrix or not h then return end
    
    -- Apply only when source is mislabeled BT.601, HD or higher, and not HDR
    local should_apply = (matrix == "bt.601" and h >= 720 and gamma ~= "pq")
    
    local vf = mp.get_property("vf") or ""
    local has_filter = vf:find(filter_label, 1, true) ~= nil
    local has_any_colorfix = vf:find("colormatrix=bt.709", 1, true) ~= nil

    if should_apply and not has_any_colorfix then
        updating = true
        mp.commandv("vf", "add", filter_str)
        updating = false
    elseif not should_apply and has_filter then
        updating = true
        mp.commandv("vf", "remove", filter_label)
        updating = false
    end
end

mp.register_event("file-loaded", function()
    mp.add_timeout(0.2, check_colorfix)
end)

mp.add_periodic_timer(2, check_colorfix)

mp.observe_property("vf", "string", function()
    mp.add_timeout(0.1, check_colorfix)
end)