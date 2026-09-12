-- toggle_motion_interpolation.lua - For MPV-SW-Capture - By TyRaS-SW

local mp = require "mp"

-- -------------------------------------------------------------------------
-- Cargar osd_messages de forma segura
-- -------------------------------------------------------------------------
local osd
local function get_script_path()
    local info = debug.getinfo(1, "S")
    return info and info.source:match("@?(.*/)") or ""
end

local script_dir = get_script_path()
local osd_path = script_dir .. "osd_messages.lua"

local ok, err = pcall(function()
    local loaded = dofile(osd_path)
    if loaded and type(loaded.show) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with show function")
    end
end)

if not ok then
    -- Fallback: función show básica
    osd = {
        show = function(key, duration)
            local text = key
            local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
            if osd_duration_ms == 0 then return end
            if duration == nil then duration = osd_duration_ms / 1000 end
            mp.osd_message(text, duration)
        end
    }
    print("toggle_motion_interpolation: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("toggle_motion_interpolation: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- Funciones principales
-- -------------------------------------------------------------------------
local function is_on()
    return mp.get_property_bool("user-data/motion_interpolation", false)
end

local function set_on()
    mp.set_property("interpolation", "yes")
    mp.set_property("tscale", "oversample")
    mp.set_property_bool("user-data/motion_interpolation", true)
    osd.show("motioninterp_on", 1.5)
end

local function set_off()
    mp.set_property("interpolation", "no")
    mp.set_property("tscale", "linear")
    mp.set_property_bool("user-data/motion_interpolation", false)
    osd.show("motioninterp_off", 1.5)
end

local function toggle_motion_interpolation()
    if is_on() then
        set_off()
    else
        set_on()
    end
end

mp.register_script_message("toggle-motion-interpolation", toggle_motion_interpolation)