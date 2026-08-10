-- mirror_toggle.lua - For MPV-SW-Capture - By TyRaS-SW
-- Toggle mirror effect with OSD, language support, and menu tick
local mp = require "mp"

-- Default language (change to "es" for Spanish)
local current_lang = "en"  -- "en" or "es"

-- Safe OSD message: respects osd-duration (hides if 0), otherwise uses given duration (in seconds)
local function safe_osd_message(text, duration)
    local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
    if osd_duration_ms == 0 then
        return  -- OSD hidden, do not show
    end
    -- If no specific duration provided, use osd-duration converted to seconds
    if duration == nil then
        duration = osd_duration_ms / 1000
    end
    mp.osd_message(text, duration)
end

-- Get current video filter list
local function get_vf_list()
    return mp.get_property_native("vf", {})
end

-- Set video filter list
local function set_vf_list(list)
    mp.set_property_native("vf", list)
end

-- Check if hflip is present in the filter list
local function has_hflip(list)
    for _, f in ipairs(list) do
        if type(f) == "table" and f.name == "hflip" then
            return true
        end
    end
    return false
end

-- Update user-data/mirror_active based on current vf state
local function update_mirror_user_data()
    local vf_list = get_vf_list()
    local active = has_hflip(vf_list)
    mp.set_property("user-data/mirror_active", tostring(active))
    return active
end

-- Toggle mirror
local function toggle_mirror()
    local vf_list = get_vf_list()
    local hflip_present = has_hflip(vf_list)

    if hflip_present then
        -- Remove hflip from list
        local new_list = {}
        for _, f in ipairs(vf_list) do
            if not (type(f) == "table" and f.name == "hflip") then
                table.insert(new_list, f)
            end
        end
        set_vf_list(new_list)
        -- Show OFF message
        if current_lang == "es" then
            safe_osd_message("Espejo OFF", 1.5)
        else
            safe_osd_message("Mirror OFF", 1.5)
        end
    else
        -- Insert hflip at the BEGINNING (before any other filter)
        local new_list = { { name = "hflip" } }
        for _, f in ipairs(vf_list) do
            table.insert(new_list, f)
        end
        set_vf_list(new_list)
        -- Show ON message
        if current_lang == "es" then
            safe_osd_message("Espejo ON", 1.5)
        else
            safe_osd_message("Mirror ON", 1.5)
        end
    end

    -- Update user-data for menu tick
    update_mirror_user_data()
end

-- Observe changes to vf property to keep user-data in sync
mp.observe_property("vf", "native", function()
    update_mirror_user_data()
end)

-- Initialize user-data at startup
update_mirror_user_data()

-- Register script-message for menu integration
mp.register_script_message("toggle-mirror", toggle_mirror)

-- Optional keyboard shortcut (M key)
mp.add_key_binding("m", "toggle-mirror", toggle_mirror)