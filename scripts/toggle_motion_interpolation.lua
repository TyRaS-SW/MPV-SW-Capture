-- toggle_motion_interpolation.lua - For MPV-SW-Capture - By TyRaS-SW
local function is_on()
    return mp.get_property_bool("user-data/motion_interpolation", false)
end

local function set_on()
    mp.set_property("interpolation", "yes")
    mp.set_property("tscale", "oversample")
    mp.set_property_bool("user-data/motion_interpolation", true)
    mp.osd_message("Motion Interpolation: ON")
end

local function set_off()
    mp.set_property("interpolation", "no")
    mp.set_property("tscale", "linear")
    mp.set_property_bool("user-data/motion_interpolation", false)
    mp.osd_message("Motion Interpolation: OFF")
end

local function toggle_motion_interpolation()
    if is_on() then
        set_off()
    else
        set_on()
    end
end

mp.register_script_message("toggle-motion-interpolation", toggle_motion_interpolation)