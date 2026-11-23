-- save_resolution.lua - For MPV-SW-Capture - By TyRaS-SW
-- Persists the selected input resolution across sessions.
-- Behavior: The save button ALWAYS overwrites the saved resolution.

local mp = require 'mp'
local msg = require 'mp.msg'

-- -------------------------------------------------------------------------
-- Load osd_messages in secure mode (SAME PATTERN AS check_version.lua)
-- -------------------------------------------------------------------------
local osd
local function get_script_path()
    local info = debug.getinfo(1, "S")
    return info and info.source:match("@?(.*[/\\])") or ""
end

local script_dir = get_script_path()
local osd_path = script_dir .. "osd_messages.lua"

local ok, err = pcall(function()
    local loaded = dofile(osd_path)
    if loaded and type(loaded.get) == "function" and type(loaded.show) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get/show functions")
    end
end)

if not ok then
    osd = {
        get = function(key) return key end,
        show = function(key, duration)
            local text = key
            local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
            if osd_duration_ms == 0 then return end
            if duration == nil then duration = osd_duration_ms / 1000 end
            mp.osd_message(text, duration)
        end,
        safe_osd_message = function(text, duration)
            local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
            if osd_duration_ms == 0 then return end
            if duration == nil then duration = osd_duration_ms / 1000 end
            mp.osd_message(text, duration)
        end
    }
    msg.warn("save_resolution: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    msg.info("save_resolution: osd_messages.lua loaded from " .. osd_path)
end

-- Fallback strings (used only if osd.get returns the key itself)
local FALLBACK = {
    save_res_ok      = "Resolution saved: %s",
    save_res_cleared = "Saved resolution cleared",
    save_res_error   = "Error saving resolution",
    save_res_label_auto = "Auto/Native",
}

-- Helper: get translated template, else fallback
local function tpl(key)
    local v = osd.get(key)
    if v == nil or v == key then
        v = FALLBACK[key] or key
    end
    return v
end

-- Helper: show a message using the same system as check_version.lua
local function show_msg(key, ...)
    local template = tpl(key)
    local text = template
    if select('#', ...) > 0 then
        local ok2, result = pcall(string.format, template, ...)
        if ok2 then text = result end
    end
    -- Use safe_osd_message so osd-duration logic is centralized
    if osd.safe_osd_message then
        osd.safe_osd_message(text, 2)
    else
        osd.show(text, 2)
    end
end

-- -------------------------------------------------------------------------
-- Labels & File I/O
-- -------------------------------------------------------------------------
local RES_LABELS = {
    ["854x480"]   = "480p",       ["1280x720"]  = "720p",
    ["1920x1080"] = "FHD (1080p)",["2048x1152"] = "QWXGA (1152p)",
    ["2560x1440"] = "QHD (1440p)",["2880x1620"] = "3K (1620p)",
    ["3200x1800"] = "QHD+ (1800p)",["3840x2160"] = "4K (2160p)",
}

local function label_of(res)
    if res == "auto" then return tpl("save_res_label_auto") end
    return RES_LABELS[res] or res
end

local function getroot() return (mp.get_property("config-path") or "."):gsub("\\", "/") end
local SAVE_FILE = getroot() .. "/data/menu/saved_resolution.txt"

local function read_saved()
    local f = io.open(SAVE_FILE, "r")
    if not f then return nil end
    local s = (f:read("*a") or ""):gsub("^%s+", ""):gsub("%s+$", "")
    f:close()
    s = s:gsub('"', ''):gsub("'", '')
    if s == "" then return nil end
    return s
end

local function write_saved(value)
    local f = io.open(SAVE_FILE, "w")
    if not f then
        local dir = SAVE_FILE:match("^(.*)[/\\][^/\\]+$")
        if dir then
            local win_dir = dir:gsub("/", "\\")
            os.execute('if not exist "' .. win_dir .. '" mkdir "' .. win_dir .. '"')
            f = io.open(SAVE_FILE, "w")
        end
    end
    if not f then return false end
    f:write(value .. "\n")
    f:close()
    return true
end

local function delete_saved()
    os.remove(SAVE_FILE)
end

local function current_res()
    return tostring(mp.get_property("user-data/capture_resolution") or "auto"):gsub("%s+", "")
end

local function update_state()
    local saved = read_saved()
    local active = (saved ~= nil and saved == current_res()) and "yes" or "no"
    mp.set_property("user-data/saved_resolution_active", active)
    mp.set_property("user-data/saved_resolution_exists", saved and "yes" or "no")
end

local RES_CMD_MAP = {
    ["854x480"]   = "set-res-480",   ["1280x720"]  = "set-res-720",
    ["1920x1080"] = "set-res-1080",  ["2048x1152"] = "set-res-2048",
    ["2560x1440"] = "set-res-1440",  ["2880x1620"] = "set-res-1620",
    ["3200x1800"] = "set-res-1800",  ["3840x2160"] = "set-res-4k",
    ["auto"]      = "set-res-auto",
}

-- Applied silently: no OSD message when restoring at startup.
local function apply_saved(value)
    if not value then return end
    local c = RES_CMD_MAP[value]
    if c then
        mp.commandv("script-message", c, "silent")
    else
        msg.warn("[save_resolution] Unknown value: " .. value)
    end
end

-- -------------------------------------------------------------------------
-- Actions
-- -------------------------------------------------------------------------
mp.register_script_message("save-resolution", function()
    local cur = current_res()
    if write_saved(cur) then
        show_msg("save_res_ok", label_of(cur))
        msg.info("[save_resolution] Saved: " .. cur)
    else
        show_msg("save_res_error")
    end
    update_state()
end)

mp.register_script_message("clear-saved-resolution", function()
    local saved = read_saved()
    if saved then
        delete_saved()
        show_msg("save_res_cleared")
    end
    update_state()
end)

-- NEW: real toggle (matches your menu item "toggle-save-resolution")
mp.register_script_message("toggle-save-resolution", function()
    if read_saved() then
        delete_saved()
        show_msg("save_res_cleared")
    else
        local cur = current_res()
        if write_saved(cur) then
            show_msg("save_res_ok", label_of(cur))
        else
            show_msg("save_res_error")
        end
    end
    update_state()
end)

mp.observe_property("user-data/capture_resolution", "string", function()
    mp.add_timeout(0.05, update_state)
end)

-- -------------------------------------------------------------------------
-- Apply on startup
-- -------------------------------------------------------------------------
-- The saved resolution is applied on "start-file": every script is already
-- loaded by then, and the video filter chain has not been built yet, so the
-- scale filter goes in with the first frames instead of reconfiguring a
-- chain that is already running. "playback-restart" is only a safety net.
local startup_applied = false
local startup_verified = false

local function has_scale_filter()
    for _, f in ipairs(mp.get_property_native("vf", {}) or {}) do
        if f.label == "msc_scale" then return true end
    end
    return false
end

local function apply_startup_resolution()
    if startup_applied then return end
    local saved = read_saved()
    if not saved then
        update_state()
        return
    end

    startup_applied = true

    apply_saved(saved)
    update_state()
    msg.info("[save_resolution] Applied saved resolution silently: " .. saved)
end

mp.register_event("start-file", apply_startup_resolution)

mp.register_event("playback-restart", function()
    -- Safety net, runs once: if the resolution did not stick (script loaded
    -- late, filter rejected...), apply it again, still silently.
    if not startup_verified then
        startup_verified = true
        local saved = read_saved()
        if saved and (current_res() ~= saved
                      or (saved ~= "auto" and not has_scale_filter())) then
            apply_saved(saved)
            msg.info("[save_resolution] Re-applied saved resolution: " .. saved)
        end
    end
    update_state()
end)

update_state()
