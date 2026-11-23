-- resolution_switcher.lua - For MPV-SW-Capture - By TyRaS-SW
-- Handles dynamic resolution scaling using MPV's video filters (vf) or a GPU shader.
-- Integrates with osd_messages.lua for localization and Streamer mode.
-- GPU mode works alongside nso_retro.lua (crops and bezels are proportional,
-- so the shader scales the already cropped frame by the same factor).

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

-- -------------------------------------------------------------------------
-- Load OSD translations
-- -------------------------------------------------------------------------
local osd

local function get_script_path()
    local info = debug.getinfo(1, "S")
    if not info or not info.source then return "" end
    local dir = info.source:match("@?(.*[/\\])")
    return dir and dir:gsub("\\", "/") or ""
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
    -- Fallback dictionary in case osd_messages.lua is missing
    local defaults = {
        res_480 = "Resolution: 480p",
        res_720 = "Resolution: 720p",
        res_1080 = "Resolution: FHD (1080p)",
        res_2048 = "Resolution: QWXGA (1152p)",
        res_1440 = "Resolution: QHD (1440p)",
        res_1620 = "Resolution: 3K (1620p)",
        res_1800 = "Resolution: QHD+ (1800p)",
        res_4k = "Resolution: 4K (2160p)",
        res_auto = "Resolution: Auto (Native)"
    }
    osd = {
        get = function(key) return defaults[key] or key end,
        show = function(key, duration)
            local ms = mp.get_property_number("osd-duration") or 1000
            if ms > 0 then
                mp.osd_message(defaults[key] or key, duration or 2)
            end
        end
    }
    msg.warn("[resolution_switcher] Using fallback messages. Error: " .. tostring(err))
end

-- English fallback for the messages that are not in the basic fallback above.
local OSD_FALLBACK = {
    res_scale_gpu        = "Scaling: GPU (shader)",
    res_scale_cpu        = "Scaling: CPU (lavfi)",
    res_err_mkdir        = "resolution_switcher: could not create %s (using CPU scaling)",
    res_err_shader_write = "resolution_switcher: could not write %s (using CPU scaling)",
    res_log_saved        = "Log saved to:\n%s",
    res_log_error        = "Could not write log:\n%s",
}

-- OSD text helpers: look the key up in the translation files (osd_messages.lua) and fall
-- back to the English text above if the key is missing. A literal "\n" in a translation
-- becomes a line break. Extra arguments fill the %s placeholders. Streamer mode is
-- respected (osd-duration = 0 hides every message).
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
    local ms = mp.get_property_number("osd-duration") or 1000
    if ms == 0 then return end
    mp.osd_message(text, duration or (ms / 1000))
end

-- -------------------------------------------------------------------------
-- Core Functions
-- -------------------------------------------------------------------------

-- Removes the existing scaling filter, if any.
local function clean_scale()
    local vf = mp.get_property_native("vf", {})
    local new_vf = {}
    local changed = false
    
    for _, f in ipairs(vf) do
        if f.label == "msc_scale" then
            changed = true
        else
            table.insert(new_vf, f)
        end
    end
    
    if changed then 
        mp.set_property_native("vf", new_vf) 
    end
end

-- -------------------------------------------------------------------------
-- GPU Scaling (optional)
-- -------------------------------------------------------------------------
-- GPU Mode: The input resolution is applied by a GPU shader. The CPU no longer 
--           scales each frame, and an enlarged frame is not built in RAM
--           (the native frame reaches the GPU as it comes in).
-- CPU Mode: Previous behavior: libavfilter's "scale" filter on the CPU, per frame.
-- The quality is that of the kernel used by libswscale (bicubic B=0 C=0.6).
-- Shaders are generated automatically in data/scale/. They are only used for 
-- enlarging (above the input resolution); 480p/720p/1080p always use CPU.
-- If something fails (e.g., cannot write the shader file), it falls back 
-- automatically to the CPU filter.
--
-- The menu button (script-message "toggle-scale-gpu") changes the mode and saves
-- the choice in scale_gpu.txt. SCALE_USE_GPU is only the initial value before 
-- a saved choice exists.

local SCALE_USE_GPU = true

local gpu_active = false   -- shader currently controls the input resolution
local gpu_target = nil     -- { w = ..., h = ... }
local gpu_path   = nil     -- shader file in use
local gpu_files  = {}      -- files already checked/written in this session
local last_res   = nil     -- last requested resolution: { w, h }

-- Configuration folder (same "~~/" used by nso_retro.lua). Resolved once.
local config_root_cache = nil
local function config_root()
    if config_root_cache then return config_root_cache end
    local p = mp.command_native({ "expand-path", "~~/" })
    if type(p) ~= "string" or p == "" then
        p = mp.get_property("config-path") or "."
    end
    p = p:gsub("\\", "/"):gsub("/+$", "")
    config_root_cache = p
    return p
end

-- Creates a folder if it doesn't exist (Lua lacks mkdir; uses the system's).
local dirs_ready = {}
local function ensure_dir(dir)
    if dirs_ready[dir] then return true end
    local info = utils.file_info(dir)
    if info and info.is_dir then
        dirs_ready[dir] = true
        return true
    end

    local args
    if mp.get_property("platform") == "windows" then
        args = { "cmd", "/d", "/c", "mkdir", (dir:gsub("/", "\\")) }
    else
        args = { "mkdir", "-p", dir }
    end
    mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args,
    })

    info = utils.file_info(dir)
    dirs_ready[dir] = (info ~= nil and info.is_dir == true)
    return dirs_ready[dir]
end

-- Saved choice (same settings module used by the menu).
local scale_gpu_enabled = SCALE_USE_GPU
local scale_settings = nil
do
    local okm, st = pcall(dofile, config_root() .. "/data/modules/msc_settings.lua")
    if okm and type(st) == "table" and type(st.read) == "function" then
        scale_settings = st
        local v = st.read("scale_gpu.txt")
        if v ~= nil then
            scale_gpu_enabled = (v:match("^%s*(.-)%s*$") == "yes")
        end
    end
end

-- Own backup file (data/menu/msc_scale_mode.txt): so the choice is remembered
-- even if the settings module doesn't have "write". If the module has a saved
-- value, that one takes precedence. The previous path (data/) is also read and migrated.
local mode_dir      = config_root() .. "/data/menu"
local mode_file     = mode_dir .. "/msc_scale_mode.txt"
local mode_file_old = config_root() .. "/data/msc_scale_mode.txt"
do
    local f = io.open(mode_file, "rb") or io.open(mode_file_old, "rb")
    if f then
        local v = f:read("*a") or ""
        f:close()
        local from_module = scale_settings and scale_settings.read("scale_gpu.txt") ~= nil
        if not from_module and v ~= "" then
            scale_gpu_enabled = (v:match("^%s*(.-)%s*$") == "yes")
        end
    end
end
mp.set_property("user-data/scale_gpu", scale_gpu_enabled and "yes" or "no")

local function save_scale_mode()
    local value = scale_gpu_enabled and "yes" or "no"
    if scale_settings and type(scale_settings.write) == "function" then
        pcall(scale_settings.write, "scale_gpu.txt", value)
    end
    if ensure_dir(mode_dir) then
        local f = io.open(mode_file, "wb")
        if f then
            f:write(value)
            f:close()
            os.remove(mode_file_old)  -- already migrated
        end
    end
end

-- "Fit Full 16:9 to Crop" compresses the entire frame inside the filter chain
-- to the capture size. A shader that scales afterwards would stretch that 
-- compressed frame, so this mode keeps using the CPU scaler.
local function gpu_scale_allowed()
    return scale_gpu_enabled and mp.get_property("user-data/crop_fit") ~= "fill"
end

-- Two passes (horizontal then vertical). The number of taps is a constant
-- (@NX@ / @NY@) so the compiler unrolls the loops. The kernel widens 
-- automatically when reducing the image, so 480p/720p do not alias.
local SHADER_TEMPLATE = [==[
// msc_scale - generated by resolution_switcher.lua. Do not edit.
// Scales a @NW@x@NH@ capture to @W@x@H@ with bicubic (B=0, C=0.6), the
// default value of libswscale. The output size is the frame size by @W@/@NW@ and
// @H@/@NH@, so a frame cropped before this point (crops) preserves its
// shape and receives the same scale factor as the full frame.

//!HOOK MAIN
//!BIND HOOKED
//!SAVE MSC_SCALE_H
//!DESC msc_scale horizontal
//!WIDTH HOOKED.w @W@ * @NW@ /
//!HEIGHT HOOKED.h

float msc_k(float x) {
    x = abs(x);
    if (x < 1.0) return (1.4 * x - 2.4) * x * x + 1.0;
    if (x < 2.0) return ((-0.6 * x + 3.0) * x - 4.8) * x + 2.4;
    return 0.0;
}

vec4 hook() {
    float s    = max(float(@NW@) / float(@W@), 1.0);
    float x    = HOOKED_pos.x * HOOKED_size.x;
    float lo   = floor(x - 2.0 * s + 0.5);
    float edge = 0.5 * HOOKED_pt.x;
    vec4  acc  = vec4(0.0);
    float wsum = 0.0;
    for (int i = 0; i < @NX@; i++) {
        float j = lo + float(i);
        float w = msc_k((j + 0.5 - x) / s);
        float u = clamp((j + 0.5) * HOOKED_pt.x, edge, 1.0 - edge);
        acc  += w * HOOKED_tex(vec2(u, HOOKED_pos.y));
        wsum += w;
    }
    return acc / wsum;
}

//!HOOK MAIN
//!BIND HOOKED
//!BIND MSC_SCALE_H
//!DESC msc_scale vertical
//!WIDTH HOOKED.w @W@ * @NW@ /
//!HEIGHT HOOKED.h @H@ * @NH@ /

float msc_k(float x) {
    x = abs(x);
    if (x < 1.0) return (1.4 * x - 2.4) * x * x + 1.0;
    if (x < 2.0) return ((-0.6 * x + 3.0) * x - 4.8) * x + 2.4;
    return 0.0;
}

vec4 hook() {
    float s    = max(float(@NH@) / float(@H@), 1.0);
    float y    = HOOKED_pos.y * MSC_SCALE_H_size.y;
    float lo   = floor(y - 2.0 * s + 0.5);
    float edge = 0.5 * MSC_SCALE_H_pt.y;
    vec4  acc  = vec4(0.0);
    float wsum = 0.0;
    for (int i = 0; i < @NY@; i++) {
        float j = lo + float(i);
        float w = msc_k((j + 0.5 - y) / s);
        float v = clamp((j + 0.5) * MSC_SCALE_H_pt.y, edge, 1.0 - edge);
        acc  += w * MSC_SCALE_H_tex(vec2(HOOKED_pos.x, v));
        wsum += w;
    }
    return acc / wsum;
}
]==]

-- Taps required for an open kernel window of length 4*s (s >= 1).
local function taps_for(src, dst)
    local s = math.max(src / dst, 1)
    return math.max(4, math.ceil(4 * s - 1e-6))
end

-- Returns the shader path for this size and writes the file if missing.
-- Shaders go in data/scale/. The name encodes all parameters,
-- so an existing file is always valid.
local function ensure_shader_file(w, h, nw, nh, nx, ny)
    local dir = config_root() .. "/data/scale"
    local path = string.format("%s/msc_scale_v2_%dx%d_from_%dx%d_%d_%d.glsl", dir, w, h, nw, nh, nx, ny)
    if gpu_files[path] then return path end

    local f = io.open(path, "rb")
    if f then
        f:close()
        gpu_files[path] = true
        return path
    end

    if not ensure_dir(dir) then
        msg.warn("[resolution_switcher] could not create folder: " .. dir)
        osd_fmt("res_err_mkdir", 5, dir)
        return nil
    end

    local text = SHADER_TEMPLATE:gsub("@(%u+)@", { W = w, H = h, NW = nw, NH = nh, NX = nx, NY = ny })
    local tmp = path .. ".tmp"
    local out, err = io.open(tmp, "wb")
    if not out then
        msg.warn("[resolution_switcher] could not write shader: " .. tostring(err))
        osd_fmt("res_err_shader_write", 5, path)
        return nil
    end
    out:write(text)
    out:close()
    os.remove(path)
    if not os.rename(tmp, path) then
        os.remove(tmp)
        msg.warn("[resolution_switcher] could not finish shader file")
        return nil
    end
    gpu_files[path] = true
    return path
end

local function is_msc_shader(p)
    return type(p) == "string" and p:find("msc_scale_v%d+_") ~= nil
end

-- Sets `path` in glsl-shaders and removes any previous msc_scale shader. If `path`
-- is already in the list, it preserves its position (nso_retro.lua decides the order
-- of the list, so the two scripts don't fight). `path` = nil only removes ours.
local function set_gpu_shader(path)
    local list = mp.get_property_native("glsl-shaders", {}) or {}
    local present = false
    if path then
        for _, p in ipairs(list) do
            if p == path then present = true; break end
        end
    end

    local new = {}
    if path and not present then new[1] = path end
    for _, p in ipairs(list) do
        if not is_msc_shader(p) or (present and p == path) then
            new[#new + 1] = p
        end
    end

    local same = (#list == #new)
    if same then
        for i = 1, #new do
            if list[i] ~= new[i] then same = false; break end
        end
    end
    if not same then
        mp.set_property_native("glsl-shaders", new)
    end
end

local function clean_gpu_scale()
    gpu_active, gpu_target, gpu_path = false, nil, nil
    set_gpu_shader(nil)
end

-- Returns true if the GPU shader took over the resolution.
local function apply_gpu_scale(w, h)
    local nw = mp.get_property_number("video-params/w") or 1920
    local nh = mp.get_property_number("video-params/h") or 1080
    local path = ensure_shader_file(w, h, nw, nh, taps_for(nw, w), taps_for(nh, h))
    if not path then return false end
    gpu_active, gpu_target, gpu_path = true, { w = w, h = h }, path
    set_gpu_shader(path)
    return true
end

-- Safety net: never fight another script forever. More than 6 corrections in
-- 2 seconds means something is rewriting glsl-shaders; it stops correcting.
local fix_times = {}
local function allow_fix()
    local now = mp.get_time()
    local kept = {}
    for _, t in ipairs(fix_times) do
        if now - t < 2 then kept[#kept + 1] = t end
    end
    fix_times = kept
    if #fix_times >= 6 then
        msg.warn("[resolution_switcher] glsl-shaders keeps changing; not re-adding msc_scale")
        return false
    end
    fix_times[#fix_times + 1] = now
    return true
end

-- Menu actions like Clean All erase glsl-shaders: we put ours back.
mp.observe_property("glsl-shaders", "native", function(_, list)
    if not gpu_active or not gpu_path then return end
    local found = false
    if type(list) == "table" then
        for _, p in ipairs(list) do
            if p == gpu_path then found = true; break end
        end
    end
    if not found and allow_fix() then set_gpu_shader(gpu_path) end
end)

-- A different input (e.g., 720p -> 1080p) changes whether to upscale and how many taps to use.
-- nil is ignored (signal lost / reconnecting) to avoid flipping the shader around
-- while the capture restarts.
local apply_res  -- defined below

local function on_native_size_changed(_, value)
    if value == nil or not last_res then return end
    apply_res(last_res.w, last_res.h)
end
mp.observe_property("video-params/w", "number", on_native_size_changed)
mp.observe_property("video-params/h", "number", on_native_size_changed)

-- -------------------------------------------------------------------------
-- Window size
-- In GPU mode, mpv sees a native-sized video (1080p) and the shader enlarges it
-- on draw, so mpv doesn't know the image is bigger. To make the window grow
-- like it does with CPU, the chosen size (win_rel) is measured against the chosen
-- resolution: 1.0 = window of the resolution's size (4K = 3840x2160), in both modes.
-- The window is only adjusted when the resolution or mode changes (or from the menu);
-- the rest of the time it's left alone.
-- -------------------------------------------------------------------------
local win_rel = 1.0          -- chosen size, relative to the chosen resolution
local fit_pending = false    -- there's a fit waiting for the video to stabilize
local fit_timer = nil
local ignore_until = 0       -- ignores window-scale changes not from the user
local fit_deferred = false   -- a fit was skipped because we were in fullscreen; redo it on exit

-- How much mpv measures the video relative to the chosen resolution (1 if no shader).
local function window_factor()
    if gpu_active and last_res then
        local nw = mp.get_property_number("video-params/w") or 1920
        if nw > 0 then return last_res.w / nw end
    end
    return 1
end

-- Largest window-scale at which the window still fits on the monitor. Without this,
-- 4K (3840x2160) on a smaller monitor makes a window bigger than the screen: after leaving
-- fullscreen it looks like it is still in fullscreen and the window can't be reached.
-- Returns nil if the display or video size is unknown (then nothing is limited).
local function max_window_scale()
    local dw = mp.get_property_number("display-width")
    local dh = mp.get_property_number("display-height")
    local bw = mp.get_property_number("video-out-params/dw") or mp.get_property_number("video-out-params/w")
    local bh = mp.get_property_number("video-out-params/dh") or mp.get_property_number("video-out-params/h")
    if not (dw and dh and bw and bh) or dw <= 0 or dh <= 0 or bw <= 0 or bh <= 0 then
        return nil
    end
    return math.min(dw / bw, dh / bh)
end

local function clamp_scale(s)
    local m = max_window_scale()
    if m and s > m then return m end
    return s
end

-- For the menu to mark the active option (text with 2 decimals: "1.00", "0.50"...).
local function publish_window_rel()
    mp.set_property("user-data/window_scale_rel", string.format("%.2f", win_rel))
end

local function fit_window()
    fit_pending = false
    -- Setting window-scale while in fullscreen changes the size mpv restores on exit,
    -- so it waits until fullscreen is left (see the "fullscreen" observer below).
    if mp.get_property_bool("fullscreen") then
        fit_deferred = true
        publish_window_rel()
        return
    end
    local target = clamp_scale(win_rel * window_factor())
    local cur = mp.get_property_number("window-scale") or target
    if math.abs(cur - target) > 0.005 then
        ignore_until = mp.get_time() + 1.5
        mp.set_property_number("window-scale", target)
    end
    publish_window_rel()
end

local function schedule_fit()
    fit_pending = true
    if fit_timer then fit_timer:kill() end
    fit_timer = mp.add_timeout(0.5, fit_window)
end

-- Each video reconfiguration restarts the wait (nso_retro may reapply filters).
mp.observe_property("video-out-params", "native", function()
    if fit_pending and fit_timer then
        fit_timer:kill()
        fit_timer:resume()
    end
end)

-- If the size changes by other means (a direct "set window-scale 1.0", another key,
-- dragging the window), it's reinterpreted. In GPU mode, a "round" value from
-- the menu options (0.5, 1.0, 2.0...) is taken as relative to the chosen resolution,
-- just like with CPU: "set window-scale 1.0" gives a 4K window and not a 1080p one.
-- Any other value (drag) is only remembered. It waits 0.3s for the value
-- to stabilize, to avoid fighting an ongoing drag, and is ignored in fullscreen
-- and during its own adjustments.
local MENU_SIZES = { 0.3, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0 }
local ws_log = {}
local settle_timer = nil

local function ws_note(text)
    ws_log[#ws_log + 1] = string.format("%.1f  %s", mp.get_time(), text)
    if #ws_log > 25 then table.remove(ws_log, 1) end
end

mp.observe_property("fullscreen", "bool", function(_, fs)
    ignore_until = mp.get_time() + 1.5
    if fs then return end
    if fit_deferred then
        -- A fit was skipped while in fullscreen: do it now.
        fit_deferred = false
        schedule_fit()
    else
        -- Safety net: mpv restores the previous windowed size. If that is bigger than
        -- the monitor, shrink it so the window is never lost behind the screen edges.
        mp.add_timeout(0.5, function()
            if mp.get_property_bool("fullscreen") then return end
            local v = mp.get_property_number("window-scale")
            local m = max_window_scale()
            if v and m and v > m + 0.005 then
                ignore_until = mp.get_time() + 1.5
                mp.set_property_number("window-scale", m)
                ws_note(string.format("ws=%.3f -> too big for the monitor after fullscreen, limited to %.3f", v, m))
            end
        end)
    end
end)

local function settle_window_scale()
    if fit_pending or mp.get_property_bool("fullscreen") then return end
    local v = mp.get_property_number("window-scale")
    if not v then return end
    local f = window_factor()
    if f > 1.001 then
        for _, m in ipairs(MENU_SIZES) do
            if math.abs(v - m) < 0.003 then
                win_rel = m
                ignore_until = mp.get_time() + 1.5
                local applied = clamp_scale(m * f)
                mp.set_property_number("window-scale", applied)
                publish_window_rel()
                ws_note(string.format("ws=%.3f -> relative %.2f, applying %.3f", v, m, applied))
                return
            end
        end
    end
    win_rel = v / f
    publish_window_rel()
    ws_note(string.format("ws=%.3f -> remembering relative %.2f", v, win_rel))
end

mp.observe_property("window-scale", "number", function(_, v)
    if not v then return end
    if fit_pending or mp.get_time() < ignore_until or mp.get_property_bool("fullscreen") then
        ws_note(string.format("ws=%.3f (ignored)", v))
        return
    end
    ws_note(string.format("ws=%.3f (external)", v))
    if settle_timer then settle_timer:kill() end
    settle_timer = mp.add_timeout(0.3, settle_window_scale)
end)

-- From the menu: script-message set-window-scale 1.0
mp.register_script_message("set-window-scale", function(arg)
    local x = tonumber(arg)
    if not x then return end
    win_rel = x
    ignore_until = mp.get_time() + 1.5
    mp.set_property_number("window-scale", clamp_scale(x * window_factor()))
    publish_window_rel()
end)

-- Chooses GPU shader or CPU filter for (w, h) and applies it.
function apply_res(w, h)
    -- The shader is only used to ENLARGE. Reductions (480p/720p) and
    -- native resolution still go through the CPU filter: the frame is already 
    -- smaller, there's no real GPU saving, and the change is noticeable as usual.
    local native_w = mp.get_property_number("video-params/w") or 1920
    if gpu_scale_allowed() and w > native_w and apply_gpu_scale(w, h) then
        -- The shader does the work: no CPU scaling filter in the chain.
        clean_scale()
        schedule_fit()
        return
    end

    clean_gpu_scale()

    -- CPU path. Avoids rebuilding if msc_scale is already first with the
    -- same graph (rebuilding tears down and remakes the entire filter chain).
    local graph = "scale=" .. w .. ":" .. h
    local vf = mp.get_property_native("vf", {}) or {}
    local first = vf[1]
    local already = first and first.label == "msc_scale"
                    and first.params and first.params.graph == graph

    if not already then
        -- Rebuilds the filter list, placing msc_scale at the very top
        local new_vf = { { name = "lavfi", label = "msc_scale", params = { graph = graph } } }
        for _, f in ipairs(vf) do
            if f.label ~= "msc_scale" then
                table.insert(new_vf, f)
            end
        end
        mp.set_property_native("vf", new_vf)
    end
    schedule_fit()
end

-- Applies the new scale and updates the user-data property.
-- silent = true skips the OSD message (used when restoring the saved
-- resolution at startup).
local function change_res(w, h, osd_key, silent)
    last_res = { w = w, h = h }
    -- Updates user-data so the menu shows the active option's checkmark
    mp.set_property("user-data/capture_resolution", w .. "x" .. h)
    if not silent then
        osd.show(osd_key, 2)
    end

    apply_res(w, h)

    -- Notifies nso_retro.lua to recalculate bezels and crops
    mp.commandv("script-message", "reapply-vf")
end

-- nso_retro.lua enabled/disabled "Fit Full 16:9 to Crop": that mode needs the
-- CPU scaler, so it's chosen again and nso_retro recalculates.
mp.observe_property("user-data/crop_fit", "string", function()
    if not last_res then return end
    apply_res(last_res.w, last_res.h)
    mp.commandv("script-message", "reapply-vf")
end)

-- -------------------------------------------------------------------------
-- Script Message Listeners
-- -------------------------------------------------------------------------
mp.register_script_message("set-res-480",   function(arg) change_res(854, 480, "res_480", arg == "silent") end)
mp.register_script_message("set-res-720",   function(arg) change_res(1280, 720, "res_720", arg == "silent") end)
mp.register_script_message("set-res-1080",  function(arg) change_res(1920, 1080, "res_1080", arg == "silent") end)
mp.register_script_message("set-res-2048",  function(arg) change_res(2048, 1152, "res_2048", arg == "silent") end)
mp.register_script_message("set-res-1440",  function(arg) change_res(2560, 1440, "res_1440", arg == "silent") end)
mp.register_script_message("set-res-1620",  function(arg) change_res(2880, 1620, "res_1620", arg == "silent") end)
mp.register_script_message("set-res-1800",  function(arg) change_res(3200, 1800, "res_1800", arg == "silent") end)
mp.register_script_message("set-res-4k",    function(arg) change_res(3840, 2160, "res_4k", arg == "silent") end)

mp.register_script_message("set-res-auto", function(arg) 
    last_res = nil
    mp.set_property("user-data/capture_resolution", "auto")
    clean_scale()
    clean_gpu_scale()
    schedule_fit()
    -- Only shows the OSD if it's not a silent Clean All call
    if arg ~= "silent" then
        osd.show("res_auto", 2)
    end
    -- Notifies nso_retro.lua to recalculate bezels and crops
    mp.commandv("script-message", "reapply-vf")
end)

-- Changes the scaling mode (CPU <-> GPU), remembers it, and applies it instantly.
-- Arguments: "gpu" / "yes", "cpu" / "no", or no argument to toggle.
-- Can be called from the menu (script-message toggle-scale-gpu [gpu|cpu])
-- or with a key in input.conf:  KEY script-binding resolution_switcher/toggle-scale-gpu
local function set_scale_mode(arg)
    if arg == "gpu" or arg == "yes" then
        scale_gpu_enabled = true
    elseif arg == "cpu" or arg == "no" then
        scale_gpu_enabled = false
    else
        scale_gpu_enabled = not scale_gpu_enabled
    end
    mp.set_property("user-data/scale_gpu", scale_gpu_enabled and "yes" or "no")
    save_scale_mode()

    if last_res then
        apply_res(last_res.w, last_res.h)
        mp.commandv("script-message", "reapply-vf")
    end

    if arg ~= "silent" then
        osd_fmt(scale_gpu_enabled and "res_scale_gpu" or "res_scale_cpu", 2)
    end
end

mp.register_script_message("toggle-scale-gpu", set_scale_mode)
mp.add_key_binding(nil, "toggle-scale-gpu", function() set_scale_mode() end)

-- MPV messages about shaders / errors, to know why a shader isn't running.
-- The last 150 are saved and go at the end of msc_debug_log.txt.
local mpv_log = {}
mp.enable_messages("v")
mp.register_event("log-message", function(e)
    local prefix = e.prefix or ""
    if prefix:find("resolution_switcher", 1, true) then return end
    local text = (e.text or ""):gsub("%s+$", "")
    local low = text:lower()
    if low:find("real-time buffer", 1, true) then return end
    local lvl = e.level or ""
    local important = lvl == "fatal" or lvl == "error" or lvl == "warn"
    if important or low:find("shader", 1, true) or low:find("glsl", 1, true)
       or low:find("msc_scale", 1, true) or low:find("hook", 1, true) then
        mpv_log[#mpv_log + 1] = string.format("[%s] %s: %s", lvl, prefix, text)
        if #mpv_log > 150 then table.remove(mpv_log, 1) end
    end
end)

-- Scaling diagnostics: writes everything needed to msc_debug_log.txt, in the
-- configuration root folder (the same as "~~/"). You only need to upload that file.
-- Manual trigger: script-message scale-debug   or   KEY script-binding resolution_switcher/scale-debug
local function write_debug_log(show_osd)
    local function n(p) return mp.get_property_number(p) or 0 end
    local function str(p)
        local v = mp.get_property(p)
        return v ~= nil and v or "(not available)"
    end
    local function json(v)
        return utils.format_json(v) or "(not available)"
    end

    local L = {}
    local function add(t) L[#L + 1] = t end

    add("== msc_debug_log " .. os.date("%Y-%m-%d %H:%M:%S") .. " ==")
    add("mpv: " .. str("mpv-version"))
    add("vo: " .. str("current-vo") .. "   gpu-api: " .. str("gpu-api") .. "   hwdec: " .. str("hwdec-current"))
    add("")
    add("-- resolution_switcher Status")
    add("GPU mode chosen: " .. tostring(scale_gpu_enabled) .. "   active shader: " .. tostring(gpu_active))
    add("requested resolution: " .. (last_res and (last_res.w .. "x" .. last_res.h) or "auto"))
    add("shader: " .. tostring(gpu_path))
    add("window-scale: " .. str("window-scale") .. "   chosen relative size: " .. string.format("%.2f", win_rel) .. "   factor: " .. string.format("%.3f", window_factor()))
    add("window-scale changes (time, value, what the script did):")
    for _, line in ipairs(ws_log) do add("  " .. line) end
    add("crop_fit: " .. str("user-data/crop_fit") .. "   scale_gpu: " .. str("user-data/scale_gpu"))
    add("")
    add("-- Sizes")
    add(string.format("decoded input: %dx%d", n("video-params/w"), n("video-params/h")))
    add(string.format("vf output (what mpv sees): %dx%d", n("video-out-params/w"), n("video-out-params/h")))
    add(string.format("window (osd): %dx%d   fullscreen: %s", n("osd-width"), n("osd-height"), str("fullscreen")))
    add(string.format("monitor: %sx%s   max window-scale that fits: %s", str("display-width"), str("display-height"), tostring(max_window_scale())))
    add("scale: " .. str("scale") .. "   dscale: " .. str("dscale") .. "   cscale: " .. str("cscale"))
    add("")
    add("-- glsl-shaders")
    add(json(mp.get_property_native("glsl-shaders", {})))
    add("")
    add("-- vf")
    add(json(mp.get_property_native("vf", {})))
    add("")
    add("-- vo-passes (desc, last / average in ms)")
    local passes = mp.get_property_native("vo-passes")
    local found = false
    if type(passes) == "table" then
        for _, kind in ipairs({ "fresh", "redraw" }) do
            if type(passes[kind]) == "table" then
                for _, p in ipairs(passes[kind]) do
                    local d = type(p.desc) == "string" and p.desc or "?"
                    if d:find("msc_scale", 1, true) then found = true end
                    add(string.format("[%s] %s: %.2f / %.2f", kind, d,
                        (p.last or 0) / 1e6, (p.avg or 0) / 1e6))
                end
            end
        end
    else
        add("(vo-passes not available)")
    end
    if gpu_active and not found then
        add("WARNING: no msc_scale passes in vo-passes (the shader is not running)")
    end

    add("")
    add("-- Shader File")
    if gpu_path then
        local sf = io.open(gpu_path, "rb")
        if sf then
            local content = sf:read("*a") or ""
            sf:close()
            add("readable from Lua: yes, " .. #content .. " bytes")
            add("----- shader start -----")
            add(content)
            add("----- shader end -----")
        else
            add("readable from Lua: NO (" .. gpu_path .. ")")
        end
    else
        add("(no active shader)")
    end

    add("")
    add("-- mpv messages (shaders / errors)")
    if #mpv_log == 0 then
        add("(none; if you just opened mpv, change resolution and save the log again)")
    end
    for _, line in ipairs(mpv_log) do add(line) end

    local text = table.concat(L, "\n") .. "\n"
    local path = config_root() .. "/msc_debug_log.txt"
    local f, err = io.open(path, "w")
    if f then
        f:write(text)
        f:close()
        msg.info("[resolution_switcher] log saved to " .. path)
        if show_osd then osd_fmt("res_log_saved", 5, path) end
    else
        msg.error("[resolution_switcher] could not write " .. path .. ": " .. tostring(err))
        osd_fmt("res_log_error", 6, path)
    end
end

local function scale_debug() write_debug_log(true) end

mp.register_script_message("scale-debug", scale_debug)
mp.add_key_binding(nil, "scale-debug", scale_debug)