-- check_version.lua - For MPV-SW-Capture - By TyRaS-SW
-- Check for latest MSC version. Reads script-opts from command line or mpv.conf.

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

-- Default language (can be changed to "es" for Spanish)
local current_lang = "en"

-- 🔧 DURATION OF FINAL MESSAGE (in seconds)
-- Adjust this value to control how long the final result message stays on screen.
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

-- Get script directory
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

-- Safe OSD message: respects osd-duration (hides if 0), otherwise shows message.
-- duration is in seconds (if not given, osd-duration converted to seconds)
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

-- Main version check function
local function show_version_status()
    local success, err = pcall(function()
        -- Initial message (no fixed duration, uses osd-duration converted)
        if current_lang == "es" then
            safe_osd_message("Buscando actualizaciones...")
        else
            safe_osd_message("Checking for updates...")
        end

        -- Get local mpv.conf path
        local script_dir = get_script_dir()
        if not script_dir then
            if current_lang == "es" then
                safe_osd_message("ERROR: No se pudo obtener el directorio del script")
            else
                safe_osd_message("ERROR: Could not get script directory")
            end
            return
        end

        local conf_path = script_dir .. "/../mpv.conf"
        local file = io.open(conf_path, "r")
        if not file then
            if current_lang == "es" then
                safe_osd_message("ERROR: No se encontró mpv.conf local")
            else
                safe_osd_message("ERROR: Local mpv.conf not found")
            end
            return
        end
        local local_content = file:read("*all")
        file:close()

        local local_version_str = get_version_from_conf(local_content)
        if not local_version_str then
            if current_lang == "es" then
                safe_osd_message("ERROR: No se encontró versión local")
            else
                safe_osd_message("ERROR: Local version not found")
            end
            return
        end

        -- Fetch online version (no fixed duration)
        if current_lang == "es" then
            safe_osd_message("Verificando versión online...")
        else
            safe_osd_message("Checking online version...")
        end

        local online_content = download_content_silent(VERSION_URL)
        if not online_content or online_content == "" then
            if current_lang == "es" then
                safe_osd_message("ERROR: No se pudo verificar la versión online")
            else
                safe_osd_message("ERROR: Could not check online version")
            end
            return
        end

        local online_version_str = get_version_from_conf(online_content)
        if not online_version_str then
            if current_lang == "es" then
                safe_osd_message("ERROR: No se encontró versión online")
            else
                safe_osd_message("ERROR: Online version not found")
            end
            return
        end

        -- Compare versions
        local local_ver = parse_version(local_version_str)
        local online_ver = parse_version(online_version_str)

        local msg_text = ""
        if online_ver > local_ver then
            if current_lang == "es" then
                msg_text = "🔄 Nueva v" .. online_version_str .. " (actual v" .. local_version_str .. ")\nUsa el instalador."
            else
                msg_text = "🔄 New v" .. online_version_str .. " (current v" .. local_version_str .. ")\nUse the installer."
            end
        elseif online_ver == local_ver then
            if current_lang == "es" then
                msg_text = "✅ Tienes la última versión: v" .. local_version_str
            else
                msg_text = "✅ You have the latest version: v" .. local_version_str
            end
        else
            if current_lang == "es" then
                msg_text = "⚠️ Tienes v" .. local_version_str .. " > online v" .. online_version_str .. "\nNo actualices."
            else
                msg_text = "⚠️ You have v" .. local_version_str .. " > online v" .. online_version_str .. "\nDo not update."
            end
        end
        -- 🔧 Use FINAL_MSG_DURATION to control MSG duration
        safe_osd_message(msg_text, FINAL_MSG_DURATION)
    end)

    if not success then
        local err_msg = tostring(err)
        safe_osd_message("ERROR: " .. err_msg, FINAL_MSG_DURATION)
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