-- tools_launcher.lua - For MPV-SW-Capture - By TyRaS-SW
-- Launch tools from the menu (Bezel, Video, FFPlay Stream Helper, Stream
-- Menu and more) with OSD messages and language support.

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
-- Announce the tool via OSD. Shared between run_tool and run_stream_menu
-- so both paths emit identical text and fallback behavior.
-- -------------------------------------------------------------------------
local function announce_tool(tool_key)
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

    announce_tool(tool_key)

    msg.info("Launched: " .. full_path)
end

-- -------------------------------------------------------------------------
-- Run the Stream Menu. Two possible entry points:
--
--   1. tools/MSC_StreamMenu.vbs -> launched via wscript.exe. This is the
--      preferred path: wscript.exe is a Windows-subsystem binary, so no
--      console window ever appears, and the VBS itself uses
--      WshShell.Run(cmd, 0, False) to hide the PowerShell it spawns.
--      Zero flash. The VBS is generated by the Stream Menu itself the
--      first time the user clicks "Create Shortcut", and also shipped
--      with the package.
--
--   2. data/script/StreamMenu_MSC.ps1 -> launched via powershell.exe -STA
--      -WindowStyle Hidden. Fallback if the VBS is missing. -STA is
--      required because StreamMenu_MSC.ps1 uses WPF, which needs a
--      single-threaded apartment.
--
-- The file existence check is done on whichever path we are about to
-- use, not on both, so a missing PS1 with a present VBS still works and
-- vice versa.
-- -------------------------------------------------------------------------
local function run_stream_menu()
    local root = get_mpv_root()
    if not root or root == "" then
        osd.show("toolslauncher_error_dir", 3)
        return
    end

    local vbs_path = root .. "/tools/MSC_StreamMenu.vbs"
    local ps1_path = root .. "/data/script/StreamMenu_MSC.ps1"

    -- Preferred: VBS via wscript.exe.
    local vbs_file = io.open(vbs_path, "r")
    if vbs_file then
        vbs_file:close()
        utils.subprocess_detached({
            args = { "wscript.exe", vbs_path }
        })
        announce_tool("streammenu")
        msg.info("Launched Stream Menu via VBS: " .. vbs_path)
        return
    end

    -- Fallback: PowerShell -STA on the PS1.
    local ps1_file = io.open(ps1_path, "r")
    if not ps1_file then
        osd.show("toolslauncher_error_notfound", 3)
        msg.error("Stream Menu not found. Tried: " .. vbs_path .. " and " .. ps1_path)
        return
    end
    ps1_file:close()

    utils.subprocess_detached({
        args = {
            "powershell.exe",
            "-STA",
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", ps1_path
        }
    })
    announce_tool("streammenu")
    msg.info("Launched Stream Menu via PowerShell: " .. ps1_path)
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

mp.register_script_message("launch-ffplay-stream", function()
    run_tool("ffplaystream", "data/script/FFPlayStream_MSCGUI.ps1")
end)

mp.register_script_message("launch-stream-menu", function()
    run_stream_menu()
end)

mp.register_script_message("launch-installer", function()
    run_tool("install", "data/script/Install_MSCGUI.ps1")
end)

mp.register_script_message("launch-setup", function()
    run_tool("setup", "data/script/Setup_MSCGUI.ps1")
end)

msg.info("Tools Launcher loaded. Use script-messages to open tools.")