-- osd_messages.lua - By TyRaS-SW
-- Universal OSD messages for MPV scripts
-- Language code read from data/lang/OSDLang.dat
-- Messages loaded from data/lang/OSDMSG_<lang>.dat (fallback to en)

local mp = require "mp"

-- -------------------------------------------------------------------------
-- Resolve the project root from mpv's config-path (which the launcher
-- sets to the project folder via --config-dir). This is the same
-- approach used by msc_overlay.lua and audio_mode.lua. It avoids
-- depending on where this script physically lives, so moving the
-- script around doesn't break the path to data/lang/.
-- -------------------------------------------------------------------------
local function get_root_dir()
    local root = mp.get_property("config-path") or "."
    root = root:gsub("\\", "/")
    if not root:match("/$") then root = root .. "/" end
    return root
end

local root_dir  = get_root_dir()
local lang_dir  = root_dir .. "data/lang/"
local lang_file = lang_dir .. "OSDLang.dat"

-- -------------------------------------------------------------------------
-- Read language from OSDLang.dat (fallback "en")
-- -------------------------------------------------------------------------
local function read_lang_from_file()
    local f = io.open(lang_file, "r")
    if not f then return "en" end
    local content = f:read("*all")
    f:close()
    -- Strip UTF-8 BOM (EF BB BF) if present, then whitespace and newlines
    content = content:gsub("^\xef\xbb\xbf", ""):gsub("%s+", "")
    if content == "" then return "en" end
    return content
end

-- -------------------------------------------------------------------------
-- Load messages from OSDMSG_<lang>.dat
-- -------------------------------------------------------------------------
local function load_messages(lang)
    local msg_file = lang_dir .. "OSDMSG_" .. lang .. ".dat"
    local msgs = {}
    local f = io.open(msg_file, "r")
    if f then
        for line in f:lines() do
            local key, val = line:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if key and val then
                msgs[key] = val
            end
        end
        f:close()
    end
    return msgs
end

-- Initial load: read language and load messages (with fallback to "en")
local current_lang = read_lang_from_file()
local messages = load_messages(current_lang)
if not next(messages) then
    messages = load_messages("en")
    if not next(messages) then
        messages = {}
    end
end

-- -------------------------------------------------------------------------
-- Get message by key
-- -------------------------------------------------------------------------
function get(key)
    return messages[key] or key
end

-- -------------------------------------------------------------------------
-- Show OSD message respecting osd-duration
-- -------------------------------------------------------------------------
function show(key, duration)
    local text = get(key)
    local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
    if osd_duration_ms == 0 then return end
    if duration == nil then duration = osd_duration_ms / 1000 end
    mp.osd_message(text, duration)
end

-- -------------------------------------------------------------------------
-- Direct function to show raw text without a key
-- -------------------------------------------------------------------------
function safe_osd_message(text, duration)
    local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
    if osd_duration_ms == 0 then return end
    if duration == nil then duration = osd_duration_ms / 1000 end
    mp.osd_message(text, duration)
end

-- -------------------------------------------------------------------------
-- Allow other scripts to query the current language
-- -------------------------------------------------------------------------
function get_lang()
    return current_lang
end

-- -------------------------------------------------------------------------
-- Reload language and messages (called by the overlay on language change)
-- -------------------------------------------------------------------------
local function reload_messages()
    current_lang = read_lang_from_file()
    messages = load_messages(current_lang)
    if not next(messages) then
        messages = load_messages("en")
        if not next(messages) then
            messages = {}
        end
    end
end

-- Listen for the overlay notification
mp.register_script_message("reload-osd-messages", reload_messages)

-- -------------------------------------------------------------------------
-- Export
-- -------------------------------------------------------------------------
return {
    get = get,
    show = show,
    safe_osd_message = safe_osd_message,
    get_lang = get_lang,
    reload = reload_messages,
}