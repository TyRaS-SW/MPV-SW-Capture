local current_lang = "en"
-- check_version.lua - For MPV-SW-Capture - By TyRaS-SW
-- Check for latest MSC version. Reads script-opts from command line or mpv.conf.

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

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
    if loaded and type(loaded.get) == "function" and type(loaded.show) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get/show functions")
    end
end)

if not ok then
    -- Fallback: funciones básicas
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
    print("check_version: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("check_version: osd_messages.lua loaded from " .. osd_path)
end

-- 🔧 DURATION OF FINAL MESSAGE (in seconds)
local FINAL_MSG_DURATION = 4.0

-- Read script-opts for auto-check
local function get_script_opt(key)
    local script_opts = mp.get_property("options/script-opts") or ""
    for part in script_opts:gmatch("[^,]+") do
        local k, v = part:match("^(.-)=(.*)$")
        if k == key then
            return v
        end
    end
    return nil
end

local auto_check = tonumber(get_script_opt("msc_check_version_auto")) or 0

-- Online mpv.conf URL
local VERSION_URL = "https://raw.githubusercontent.com/TyRaS-SW/MPV-SW-Capture/main/mpv.conf"

-- Get script directory (for local mpv.conf)
local function get_script_dir()
    local info = debug.getinfo(1, "S")
    if info and info.source then
        local path = info.source:match("^@(.*)$")
        if path then
            path = path:gsub("\\", "/")
            local dir = path:match("^(.*)/[^/]+$")
            if dir then
                return dir
            end
        end
    end
    return nil
end

-- Extract version from mpv.conf content
local function get_version_from_conf(content)
    for line in content:gmatch("[^\r\n]+") do
        local version = line:match("^%s*#%s*v([%d.]+)%s*$")
        if version then
            return version
        end
    end
    return nil
end

-- Parse version string into a comparable number
local function parse_version(v)
    if not v then return 0 end
    local major, minor, patch = string.match(v, "v?(%d+)%.(%d+)%.?(%d*)")
    return (tonumber(major) or 0) * 10000 + (tonumber(minor) or 0) * 100 + (tonumber(patch) or 0)
end

-- Download content without showing a command window
local function download_content_silent(url)
    local args = {}
    if mp.get_property_native("platform") == "windows" then
        args = {"powershell", "-NoProfile", "-Command", "(Invoke-WebRequest -Uri '"..url.."' -UseBasicParsing).Content"}
    else
        args = {"curl", "-s", url}
    end
    local res = utils.subprocess({ args = args, cancellable = false })
    if res.status == 0 and res.stdout and res.stdout ~= "" then
        return res.stdout
    end
    return nil
end

-- Main version check function
local function show_version_status()
    local success, err = pcall(function()
        -- Initial message
        osd.show("checkversion_checking")

        -- Get local mpv.conf path
        local script_dir = get_script_dir()
        if not script_dir then
            osd.show("checkversion_error_dir", FINAL_MSG_DURATION)
            return
        end

        local conf_path = script_dir .. "/../mpv.conf"
        local file = io.open(conf_path, "r")
        if not file then
            osd.show("checkversion_error_conf", FINAL_MSG_DURATION)
            return
        end
        local local_content = file:read("*all")
        file:close()

        local local_version_str = get_version_from_conf(local_content)
        if not local_version_str then
            osd.show("checkversion_error_local", FINAL_MSG_DURATION)
            return
        end

        -- Fetch online version
        osd.show("checkversion_checking_online")

        local online_content = download_content_silent(VERSION_URL)
        if not online_content or online_content == "" then
            osd.show("checkversion_error_online", FINAL_MSG_DURATION)
            return
        end

        local online_version_str = get_version_from_conf(online_content)
        if not online_version_str then
            osd.show("checkversion_error_online_version", FINAL_MSG_DURATION)
            return
        end

        -- Compare versions
        local local_ver = parse_version(local_version_str)
        local online_ver = parse_version(online_version_str)

        local msg_text
        if online_ver > local_ver then
            msg_text = string.format(osd.get("checkversion_new_version"), online_version_str, local_version_str)
        elseif online_ver == local_ver then
            msg_text = string.format(osd.get("checkversion_latest"), local_version_str)
        else
            msg_text = string.format(osd.get("checkversion_newer_local"), local_version_str, online_version_str)
        end
        -- Use FINAL_MSG_DURATION
        osd.safe_osd_message(msg_text, FINAL_MSG_DURATION)
    end)

    if not success then
        local err_msg = tostring(err)
        osd.safe_osd_message("ERROR: " .. err_msg, FINAL_MSG_DURATION)
        msg.error("Version check error: " .. err_msg)
    end
end

-- Register script-message for menu integration
mp.register_script_message("check-version", function()
    show_version_status()
end)

-- Auto-check on startup if enabled
if auto_check == 1 then
    mp.add_timeout(1.5, function()
        show_version_status()
    end)
end