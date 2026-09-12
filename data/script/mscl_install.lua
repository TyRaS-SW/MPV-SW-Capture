-- mscl_install.lua - For MPV-SW-Capture - By TyRaS-SW
-- MPV-SW-Capture Installer shortcut host.

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

local function normalize_path(path)
    return (path or ""):gsub("\\", "/")
end

local function get_application_root()
    local info = debug.getinfo(1, "S")
    local source = info and info.source or nil
    local script_path = source and source:match("^@(.*)$") or nil

    if not script_path then
        return nil
    end

    -- This launcher is stored in <root>\data\script\.
    local root = script_path:match("^(.*)[/\\]data[/\\]script[/\\][^/\\]+$")
    if not root or root == "" then
        return nil
    end

    return normalize_path(root):gsub("/+$", "")
end

local function launch_installer()
    local root = get_application_root()

    if not root then
        msg.error("[mscl_install] Application root not found")
        mp.osd_message("Installer error: application folder not found", 5)
        return false
    end

    local ps1_path = root .. "/data/script/Install_MSCGUI.ps1"
    local file = io.open(ps1_path, "r")

    if not file then
        msg.error("[mscl_install] Installer script not found: " .. ps1_path)
        mp.osd_message("Installer error: Install_MSCGUI.ps1 not found", 5)
        return false
    end

    file:close()

    -- Detached process: the installer can remain open after MPV exits.
    utils.subprocess_detached({
        args = {
            "powershell.exe",
            "-ExecutionPolicy", "Bypass",
            "-NoProfile",
            "-WindowStyle", "Hidden",
            "-File", ps1_path
        },
        playback_only = false
    })

    msg.info("[mscl_install] Installer launch requested: " .. ps1_path)
    return true
end

mp.add_timeout(0.2, function()
    local launched = launch_installer()

    if launched then
        mp.add_timeout(0.8, function()
            mp.commandv("quit")
        end)
    else
        mp.add_timeout(0.5, function()
            mp.commandv("quit", 1)
        end)
    end
end)
