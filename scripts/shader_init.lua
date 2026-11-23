-- shader_init.lua by TyRaS-SW - Initialization of shader and OSD control

local mp = require "mp"

-- -------------------------------------------------------------------------
-- Load osd_messages safely
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
    if loaded and type(loaded.get) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get function")
    end
end)

if not ok then
    -- Fallback: basic get function
    osd = {
        get = function(key) return key end
    }
    print("shader_init: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("shader_init: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- Initialize active shader
-- -------------------------------------------------------------------------
mp.set_property("user-data/active_shader", "none")

-- Variable to track if Info Stream window is visible
local stats_visible = false

-- -------------------------------------------------------------------------
-- FUNCTION: toggle OSD (show/hide messages)
-- -------------------------------------------------------------------------
local function toggle_osd()
    local dur = mp.get_property_number("osd-duration")
    if dur == 0 then
        -- Activate normal mode (show OSD)
        mp.set_property_number("osd-duration", 1000)
        local msg_text = osd.get("shaderinit_osd_on")
        mp.osd_message(msg_text, 2.0)
    else
        -- Activate hidden mode (hide OSD)
        mp.set_property_number("osd-duration", 0)

        -- If Info Stream is visible, close it automatically
        if stats_visible then
            mp.commandv("script-binding", "stats/display-page-1-toggle")
            stats_visible = false
        end

        local msg_text = osd.get("shaderinit_osd_off")
        mp.osd_message(msg_text, 2.0)
    end
end

mp.register_script_message("toggle-osd", toggle_osd)

-- -------------------------------------------------------------------------
-- FUNCTION: Info Stream (locked in hidden mode)
-- -------------------------------------------------------------------------
local function toggle_stats()
    local dur = mp.get_property_number("osd-duration")

    -- If in hidden mode, do not allow opening Info Stream
    if dur == 0 then
        -- If visible for some reason (rare case), close it
        if stats_visible then
            mp.commandv("script-binding", "stats/display-page-1-toggle")
            stats_visible = false
        end
        return
    end

    -- Normal Mode: Toggle Info Stream
    mp.commandv("script-binding", "stats/display-page-1-toggle")
    stats_visible = not stats_visible
end

mp.register_script_message("toggle-stats", toggle_stats)