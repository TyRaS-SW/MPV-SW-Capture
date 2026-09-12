local current_lang = "en"
-- tools_launcher.lua - For MPV-SW-Capture - By TyRaS-SW
-- Launch tools from the menu (Bezel, Video and more)
-- with OSD messages and language support.

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
    if loaded and type(loaded.get) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get function")
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
    print("tools_launcher: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("tools_launcher: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- GET MPV ROOT DIRECTORY (where mpv.conf and data/ are)
-- -------------------------------------------------------------------------
local function get_mpv_root()
    local config_path = mp.get_property("config-path")
    if config_path and config_path ~= "" then
        return config_path:gsub("\\", "/")
    end

    local wd = mp.get_property("working-directory")
    if wd and wd ~= "" then
        return wd:gsub("\\", "/")
    end

    local info = debug.getinfo(1, "S")
    if info and info.source then
        local script_path = info.source:match("^@(.*)$")
        if script_path then
            local root = script_path:match("^(.*)[/\\]scripts[/\\][^/\\]+$")
            if root then
                return root:gsub("\\", "/")
            end
        end
    end

    return "."
end

-- -------------------------------------------------------------------------
-- RUN A TOOL (PowerShell script)
-- -------------------------------------------------------------------------
local function run_tool(tool_key, script_relative_path)
    local root = get_mpv_root()
    if not root or root == "" then
        osd.show("toolslauncher_error_dir", 3)
        return
    end

    local full_path = root .. "/" .. script_relative_path:gsub("\\", "/")

    -- Check if the script exists
    local file = io.open(full_path, "r")
    if not file then
        osd.show("toolslauncher_error_notfound", 3)
        msg.error("Script not found: " .. full_path)
        return
    end
    file:close()

    -- Execute PowerShell with the script (hidden window)
    utils.subprocess_detached({
        args = {
            "powershell.exe",
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", full_path
        },
        playback_only = false
    })

    -- Show friendly OSD message with tool name
    local name_key = "toolslauncher_" .. tool_key .. "_name"
    local display_name = osd.get(name_key)
    if display_name == name_key then
        -- fallback: use tool_key as name
        display_name = tool_key
    end
    local msg_text = string.format(osd.get("toolslauncher_opening"), display_name)
    osd.safe_osd_message(msg_text, 2)

    msg.info("Launched: " .. full_path)
end

-- -------------------------------------------------------------------------
-- REGISTER SCRIPT-MESSAGES FOR EACH TOOL
-- -------------------------------------------------------------------------
mp.register_script_message("launch-bezel", function()
    run_tool("bezel", "data/script/Bezel_MSCGUI.ps1")
end)

mp.register_script_message("launch-video", function()
    run_tool("video", "data/script/Video_MSCGUI.ps1")
end)

mp.register_script_message("launch-stream", function()
    run_tool("stream", "data/script/Stream_MSCGUI.ps1")
end)

mp.register_script_message("launch-installer", function()
    run_tool("install", "data/script/Install_MSCGUI.ps1")
end)

mp.register_script_message("launch-setup", function()
    run_tool("setup", "data/script/Setup_MSCGUI.ps1")
end)

msg.info("Tools Launcher loaded. Use script-messages to open tools.")