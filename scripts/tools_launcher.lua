-- tools_launcher.lua - For MPV-SW-Capture - By TyRaS-SW
-- Launch tools from the menu (Bezel, Video and more)
-- with OSD messages and language support.

local mp = require "mp"
local utils = require "mp.utils"
local msg = require "mp.msg"

-- ============================================================
-- LANGUAGE SUPPORT
-- ============================================================
local current_lang = "en"  -- "en" or "es"

local tool_names = {
    bezel = { en = "Bezel Manager", es = "Administrador de Marcos" },
    video = { en = "Video Manager", es = "Administrador de Video" },
    stream = { en = "Stream Helper", es = "Asistente de Stream" },
}

-- ============================================================
-- SAFE OSD MESSAGE (respects osd-duration)
-- ============================================================
local function safe_osd_message(text, duration)
    local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
    if osd_duration_ms == 0 then
        return  -- OSD hidden, do not show
    end
    if duration == nil then
        duration = osd_duration_ms / 1000
    end
    mp.osd_message(text, duration)
end

-- ============================================================
-- GET MPV ROOT DIRECTORY (where mpv.conf and data/ are)
-- ============================================================
local function get_mpv_root()
    -- config-path usually points to the folder containing mpv.conf
    local config_path = mp.get_property("config-path")
    if config_path and config_path ~= "" then
        return config_path:gsub("\\", "/")
    end

    -- Fallback: use working directory
    local wd = mp.get_property("working-directory")
    if wd and wd ~= "" then
        return wd:gsub("\\", "/")
    end

    -- Last resort: use script directory (go up two levels from scripts/)
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

-- ============================================================
-- RUN A TOOL (PowerShell script)
-- ============================================================
local function run_tool(tool_key, script_relative_path)
    local root = get_mpv_root()
    if not root or root == "" then
        safe_osd_message("Error: Could not determine mpv directory", 3)
        return
    end

    local full_path = root .. "/" .. script_relative_path:gsub("\\", "/")

    -- Check if the script exists
    local file = io.open(full_path, "r")
    if not file then
        safe_osd_message("Error: Tool script not found", 3)
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

    -- Show friendly OSD message
    local name = tool_names[tool_key]
    if name then
        local display = name[current_lang] or name.en
        if current_lang == "es" then
            safe_osd_message("Abriendo " .. display, 2)
        else
            safe_osd_message("Opening " .. display, 2)
        end
    else
        safe_osd_message("Opening tool", 2)
    end

    msg.info("Launched: " .. full_path)
end

-- ============================================================
-- REGISTER SCRIPT-MESSAGES FOR EACH TOOL
-- ============================================================
mp.register_script_message("launch-bezel", function()
    run_tool("bezel", "data/script/Bezel_MSCGUI.ps1")
end)

mp.register_script_message("launch-video", function()
    run_tool("video", "data/script/Video_MSCGUI.ps1")
end)

mp.register_script_message("launch-stream", function()
    run_tool("stream", "data/script/Stream_MSCGUI.ps1")
end)

msg.info("Tools Launcher loaded. Use script-messages to open tools.")