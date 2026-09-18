-- tools_launcher.lua - For MPV-SW-Capture - By TyRaS-SW
-- Launch tools from the menu (Bezel, Video and more)
-- with OSD messages and language support.

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

-- -------------------------------------------------------------------------
-- Load osd_messages safely
-- -------------------------------------------------------------------------
local osd

-- Returns the directory that contains this script, normalized to forward
-- slashes and with a trailing separator. Accepts either separator style
-- so the fallback below works regardless of how mpv reports the source.
local function get_script_path()
    local info = debug.getinfo(1, "S")
    if not info or not info.source then return "" end
    local dir = info.source:match("@?(.*[/\\])")
    if not dir then return "" end
    return dir:gsub("\\", "/")
end

local script_dir = get_script_path()
local osd_path = script_dir .. "osd_messages.lua"

local ok, err = pcall(function()
    local loaded = dofile(osd_path)
    if loaded
       and type(loaded.get) == "function"
       and type(loaded.show) == "function"
       and type(loaded.safe_osd_message) == "function" then
        osd = loaded
    else
        error("osd_messages.lua missing required functions (get/show/safe_osd_message)")
    end
end)

if not ok then
    -- Fallback: minimal OSD helpers. get() returns the key as-is; the
    -- caller is responsible for detecting untranslated keys and using a
    -- generic English message instead.
    local function show_text(text, duration)
        local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
        if osd_duration_ms == 0 then return end
        if duration == nil then duration = osd_duration_ms / 1000 end
        mp.osd_message(text, duration)
    end

    osd = {
        get = function(key) return key end,
        show = function(key, duration) show_text(key, duration) end,
        safe_osd_message = show_text,
    }
    msg.warn("tools_launcher: using fallback OSD (osd_messages.lua not loaded): " .. tostring(err))
else
    msg.info("tools_launcher: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- Get MPV root directory (where mpv.conf and data/ live)
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

    -- script_dir ends with "scripts/". Strip it to get the root that
    -- contains mpv.conf, data/, and scripts/.
    if script_dir and script_dir ~= "" then
        local root = script_dir:match("^(.*)/scripts/$")
        if root and root ~= "" then
            return root
        end
    end

    return "."
end

-- -------------------------------------------------------------------------
-- Run a tool (PowerShell script)
-- -------------------------------------------------------------------------
local function run_tool(tool_key, script_relative_path)
    local root = get_mpv_root()
    if not root or root == "" then
        osd.show("toolslauncher_error_dir", 3)
        return
    end

    local full_path = root .. "/" .. script_relative_path:gsub("\\", "/")

    -- Check if the script exists.
    local file = io.open(full_path, "r")
    if not file then
        osd.show("toolslauncher_error_notfound", 3)
        msg.error("Script not found: " .. full_path)
        return
    end
    file:close()

    -- Execute PowerShell with the script (hidden window).
    utils.subprocess_detached({
        args = {
            "powershell.exe",
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", full_path
        }
    })

    -- Build the OSD message. When osd_messages.lua is loaded, the opening
    -- template is translated and contains a %s placeholder for the tool
    -- name. In fallback mode, osd.get() returns the key unchanged, so we
    -- detect that and emit a plain English message instead of printing a
    -- raw dictionary key to the user.
    local name_key = "toolslauncher_" .. tool_key .. "_name"
    local display_name = osd.get(name_key)
    if display_name == name_key then
        display_name = tool_key
    end

    local opener = osd.get("toolslauncher_opening")
    local msg_text
    if opener == "toolslauncher_opening" then
        msg_text = "Opening " .. display_name
    else
        msg_text = string.format(opener, display_name)
    end
    osd.safe_osd_message(msg_text, 2)

    msg.info("Launched: " .. full_path)
end

-- -------------------------------------------------------------------------
-- Register script-messages for each tool
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