-- xbrz_loader.lua
-- Applies 5xBRZ.glsl configured for a given console, aware of nso_retro.lua's
-- crop state (user-data/crop-active, crop_fit and crop_rect).
local mp = require 'mp'
local msg = require 'mp.msg'

local systems = {
    NES   = { w = 256, h = 240, x = 0.157291, y = 0.025000, aw = 0.685416, ah = 0.950000 },
    SNES  = { w = 256, h = 224, x = 0.157291, y = 0.033333, aw = 0.685416, ah = 0.933333 },
    GB    = { w = 160, h = 144, x = 0.208333, y = 0.033333, aw = 0.583333, ah = 0.933333 },
    GBA   = { w = 240, h = 160, x = 0.125000, y = 0.055555, aw = 0.750000, ah = 0.888888 },
    N64   = { w = 320, h = 240, x = 0.126041, y = 0.033333, aw = 0.747916, ah = 0.933333 }
}

local current_sys = nil   -- system currently enabled (nil = 5xBRZ off)
local slot = 0            -- counter: every apply writes a brand new shader file
local run_id = tostring(os.time() % 1000000)  -- avoids clashes with files of older sessions
local recent_files = {}   -- generated files still on disk (oldest first)
local current_file = nil  -- shader file currently expected in glsl-shaders
local last_params = nil   -- "sys|x|y|w|h" of the shader last applied
local reapply_timer = nil

local function f6(n)
    return (string.format("%.6f", n):gsub(",", "."))
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

-- Shader classification inside glsl-shaders:
--   ours     = the generated 5xBRz file of this loader
--   managed  = files other scripts own and that must coexist with 5xBRZ:
--              nso_retro.lua (bezel shield "protect_" and CRT shapes) and
--              resolution_switcher.lua (GPU scaler "msc_scale_v2_...", used for
--              any upscaled resolution in GPU mode)
--   foreign  = anything else, i.e. another main shader (4K, VHS, ...)
-- 5xBRZ is a main shader like the others: it replaces foreign shaders when it
-- is selected, and it is removed when a foreign shader is selected.
-- The GPU scaler is NOT a main shader: it only sets the resolution of the frame
-- (like the old CPU "scale" filter did), so 5xBRZ must run after it, on the
-- already enlarged frame. resolution_switcher.lua always puts it first.
local function is_ours(path)
    return tostring(path):find("msc_5xBRz_", 1, true) ~= nil
end

local function is_scaler(path)
    return tostring(path):find("msc_scale_v%d+_") ~= nil
end

local function is_managed(path)
    local p = tostring(path):gsub("\\", "/")
    return p:find("protect_", 1, true) ~= nil or p:find("/shapes/", 1, true) ~= nil
        or is_scaler(p)
end

local function is_foreign(path)
    return not is_ours(path) and not is_managed(path)
end

-- Stop tracking 5xBRZ and take our file out of glsl-shaders.
local function stop_tracking(remove_from_list)
    local was_tracking = current_sys ~= nil or current_file ~= nil
    current_sys = nil
    current_file = nil
    last_params = nil
    if reapply_timer then
        reapply_timer:kill()
        reapply_timer = nil
    end
    if remove_from_list and was_tracking then
        local list = mp.get_property_native("glsl-shaders", {})
        if type(list) == "table" then
            local kept, changed = {}, false
            for _, sh in ipairs(list) do
                if is_ours(sh) then changed = true else table.insert(kept, sh) end
            end
            if changed then mp.set_property_native("glsl-shaders", kept) end
        end
    end
end

-- OSD translations (osd_messages.lua). If it can't be loaded, the English
-- fallback below is used.
local osd = { get = function(key) return key end }
do
    local info = debug.getinfo(1, "S")
    local dir = info and info.source and info.source:match("@?(.*[/\\])") or ""
    dir = dir:gsub("\\", "/")
    local ok_osd, loaded = pcall(dofile, dir .. "osd_messages.lua")
    if ok_osd and type(loaded) == "table" and type(loaded.get) == "function" then
        osd = loaded
    else
        msg.warn("[xbrz_loader] Using fallback messages (osd_messages.lua not loaded)")
    end
end

local OSD_FALLBACK = {
    xbrz_on            = "5xBRZ: %s (%s)",
    xbrz_mode_full     = "Full Screen",
    xbrz_mode_cropped  = "Cropped",
    xbrz_mode_fit      = "Crop: Fit 16:9",
    xbrz_err_notfound  = "Error: 5xBRz.glsl not found",
    xbrz_err_write     = "Error: could not write %s",
}

-- Helper to respect Streamer mode (hidden OSD)
local function show_osd(text, duration)
    local osd_duration = mp.get_property_number("osd-duration") or 1000
    if osd_duration > 0 then
        mp.osd_message(text, duration or 2)
    end
end

-- Translated text for a key (English fallback if missing). A literal "\n" in a
-- translation becomes a line break.
local function osd_text(key)
    local text = osd.get(key)
    if text == nil or text == key then text = OSD_FALLBACK[key] or key end
    return (text:gsub("\\n", "\n"))
end

local function osd_fmt(key, duration, ...)
    local text = osd_text(key)
    if select('#', ...) > 0 then
        local ok_fmt, res = pcall(string.format, text, ...)
        if ok_fmt then text = res end
    end
    show_osd(text, duration)
end

local function clean_str(v)
    if v == nil then return "" end
    v = tostring(v)
    local inner = v:match('^"(.*)"$')
    if inner then v = inner end
    return v
end

local function get_user_str(name)
    return clean_str(mp.get_property_native(name))
end

local function vf_has_label(label)
    local vf = mp.get_property_native("vf", {})
    if type(vf) ~= "table" then return false end
    for _, f in ipairs(vf) do
        if type(f) == "table" and f.label == label then return true end
    end
    return false
end

-- Returns x, y, w, h (fractions of the frame that reaches the shader) of the
-- game area, plus the mode key ("full", "cropped" or "fit") used for the OSD text.
local function compute_region(sys)
    local crop_id = get_user_str("user-data/crop-active")
    local fit     = get_user_str("user-data/crop_fit")
    local rect    = get_user_str("user-data/crop_rect")
    if fit == "" then fit = "none" end

    local has_croptag = vf_has_label("croptag")
    if crop_id ~= "" and not has_croptag then
        crop_id = ""
    elseif crop_id == "" and has_croptag then
        return 0.0, 0.0, 1.0, 1.0, "cropped"
    end

    if crop_id == "" then
        return sys.x, sys.y, sys.aw, sys.ah, "full"
    end

    if fit == "fill" then
        return sys.x, sys.y, sys.aw, sys.ah, "fit"
    end

    local cx, cy, cw, ch = rect:match("^([%d%.%-]+)|([%d%.%-]+)|([%d%.%-]+)|([%d%.%-]+)$")
    cx, cy, cw, ch = tonumber(cx), tonumber(cy), tonumber(cw), tonumber(ch)
    if not (cx and cy and cw and ch) or cw <= 0 or ch <= 0 then
        return 0.0, 0.0, 1.0, 1.0, "cropped"
    end

    local eps = 0.002
    local contains = cx <= sys.x + eps
        and cy <= sys.y + eps
        and cx + cw >= sys.x + sys.aw - eps
        and cy + ch >= sys.y + sys.ah - eps

    if not contains then
        return 0.0, 0.0, 1.0, 1.0, "cropped"
    end

    local rx = clamp((sys.x - cx) / cw, 0.0, 1.0)
    local ry = clamp((sys.y - cy) / ch, 0.0, 1.0)
    local rw = clamp(sys.aw / cw, 0.01, 1.0 - rx)
    local rh = clamp(sys.ah / ch, 0.01, 1.0 - ry)

    local tol = 0.015
    if rx < tol and ry < tol and (1.0 - rx - rw) < tol and (1.0 - ry - rh) < tol then
        return 0.0, 0.0, 1.0, 1.0, "cropped"
    end

    return rx, ry, rw, rh, "cropped"
end

local function apply_xbrz(sys_name, silent)
    local sys = systems[sys_name]
    if not sys then return end
    current_sys = sys_name

    -- 2. Decide coordinates
    local target_x, target_y, target_w, target_h, mode_key = compute_region(sys)
    last_params = string.format("%s|%.6f|%.6f|%.6f|%.6f", sys_name, target_x, target_y, target_w, target_h)

    -- 3. Generate the shader
    slot = slot + 1
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
    temp_dir = temp_dir:gsub("\\", "/")
    local temp_file = temp_dir .. "/msc_5xBRz_" .. sys_name .. "_" .. run_id .. "_" .. slot .. ".glsl"

    local orig_path = mp.command_native({"expand-path", "~~/shaders/pixel/5xBRz.glsl"})
    local f = io.open(orig_path, "r")
    if not f then
        osd_fmt("xbrz_err_notfound", 3)
        return
    end
    local content = f:read("*a")
    f:close()

    local values = {
        GAME_W   = tostring(sys.w),
        GAME_H   = tostring(sys.h),
        ACTIVE_X = f6(target_x),
        ACTIVE_Y = f6(target_y),
        ACTIVE_W = f6(target_w),
        ACTIVE_H = f6(target_h),
    }

    local new_lines = {}
    local current_param = nil
    for line in content:gmatch("[^\r\n]+") do
        if current_param then
            if not line:match("^%s*//") and not line:match("^%s*$") then
                table.insert(new_lines, values[current_param])
                current_param = nil
            else
                table.insert(new_lines, line)
            end
        else
            table.insert(new_lines, line)
            local param = line:match("^//!PARAM%s+(%S+)")
            if param and values[param] then
                current_param = param
            end
        end
    end
    content = table.concat(new_lines, "\n")

    local out = io.open(temp_file, "w")
    if not out then
        osd_fmt("xbrz_err_write", 3, temp_file)
        return
    end
    out:write(content)
    out:close()

    -- 4. Apply
    local current_shaders = mp.get_property_native("glsl-shaders", {})
    local new_shaders = {}
    for _, s in ipairs(current_shaders) do
        -- Keep only what other scripts manage (nso_retro shield and CRT shapes,
        -- resolution_switcher GPU scaler); our old file and any other main
        -- shader are dropped, so 5xBRZ never stacks on them.
        if not is_ours(s) and is_managed(s) then
            table.insert(new_shaders, s)
        end
    end
    table.insert(new_shaders, temp_file)
    current_file = temp_file
    mp.set_property_native("glsl-shaders", new_shaders)

    -- Keep only the last few generated files on disk.
    table.insert(recent_files, temp_file)
    while #recent_files > 6 do
        os.remove(table.remove(recent_files, 1))
    end

    mp.set_property("deband", "no")
    mp.set_property("user-data/active_shader", "XBRZ_" .. sys_name)
    if not silent then
        osd_fmt("xbrz_on", 2, sys_name, osd_text("xbrz_mode_" .. mode_key))
    end
end

mp.register_script_message("apply-xbrz", function(sys)
    apply_xbrz(sys, false)
end)

-- -------------------------------------------------------------------------
-- Re-apply automatically when the crop changes (or when 5xBRZ is disabled)
-- -------------------------------------------------------------------------
local function schedule_reapply(delay)
    if not current_sys then return end
    if reapply_timer then reapply_timer:kill() end
    reapply_timer = mp.add_timeout(type(delay) == "number" and delay or 0.15, function()
        reapply_timer = nil
        if not current_sys then return end
        local active = get_user_str("user-data/active_shader")
        if active ~= "" and not active:match("^XBRZ_") then
            stop_tracking(true)   -- another shader took over meanwhile
            return
        end
        apply_xbrz(current_sys, true)
    end)
end

-- Crop state changes (published by nso_retro.lua).
mp.observe_property("user-data/crop-active", "native", function() schedule_reapply() end)
mp.observe_property("user-data/crop_fit", "native", function() schedule_reapply() end)
mp.observe_property("user-data/crop_rect", "native", function() schedule_reapply() end)

mp.observe_property("vf", "native", function() schedule_reapply(0.4) end)

mp.observe_property("user-data/capture_resolution", "native", function() schedule_reapply(0.8) end)
mp.observe_property("video-out-params/w", "native", function() schedule_reapply(0.4) end)
mp.observe_property("video-out-params/h", "native", function() schedule_reapply(0.4) end)

-- Watchdog on glsl-shaders.
--   * A foreign (main) shader showed up: the user picked another shader, so
--     5xBRZ is switched off and removed. It must never stack with it.
--   * Our file vanished without a foreign shader (a script rewrote the list):
--     put it back.
mp.observe_property("glsl-shaders", "native", function(_, value)
    if not current_sys or not current_file then return end
    local found = false
    local foreign = false
    if type(value) == "table" then
        for _, s in ipairs(value) do
            if tostring(s) == current_file then found = true end
            if is_foreign(s) then foreign = true end
        end
    end
    if foreign then
        stop_tracking(true)
        return
    end
    if not found then
        schedule_reapply(0.3)
    end
end)

-- Reconciliation: once a second, recompute what the shader should be using
mp.add_periodic_timer(1.0, function()
    if not current_sys or reapply_timer then return end
    local sys = systems[current_sys]
    if not sys then return end
    local x, y, w, h = compute_region(sys)
    local now = string.format("%s|%.6f|%.6f|%.6f|%.6f", current_sys, x, y, w, h)
    if now ~= last_params then
        apply_xbrz(current_sys, true)
    end
end)

-- If another menu entry disables/replaces 5xBRZ, stop tracking it and make
-- sure its file is not left in glsl-shaders.
mp.observe_property("user-data/active_shader", "native", function(_, value)
    value = clean_str(value)
    if value ~= "" and not value:match("^XBRZ_") then
        stop_tracking(true)
    end
end)
