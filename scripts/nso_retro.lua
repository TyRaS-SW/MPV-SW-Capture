-- NSO Retro MPV by TyRaS-SW
-- GPU bezel (overlay-add) with the old CPU/lavfi bezel as fallback, plus the
-- ORIGIN simplified shapes/OSD behavior.
--
-- Fixed: transition from crop to bezel no longer deforms the image.
-- Now all crops are cleared before applying a bezel, and coordinates are
-- calculated based on the original video size, not the canvas.

local mp = require "mp"
local msg = require "mp.msg"
local utils = require "mp.utils"

-- -------------------------------------------------------------------------
-- Load osd_messages with dofile (use path script)
-- -------------------------------------------------------------------------
local osd

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
    if loaded and type(loaded.get) == "function" and type(loaded.show) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get/show functions")
    end
end)

if not ok then
    local defaults = {
        nsoretro_no_bezel = "Select a bezel first.",
        nsoretro_fill_on  = "Fit Full 16:9 to Bezel: ON",
        nsoretro_fill_off = "Fit Full 16:9 to Bezel: OFF",
        nsoretro_reset    = "Bezel Fit: Reset",
        nsoretro_no_crop       = "Select a crop first.",
        nsoretro_crop_fill_on  = "Fit Full 16:9 to Crop: ON",
        nsoretro_crop_fill_off = "Fit Full 16:9 to Crop: OFF",
    }

    local function show_text(text, duration)
        local ms = mp.get_property_number("osd-duration") or 1000
        if ms == 0 then return end
        if duration == nil then duration = ms / 1000 end
        mp.osd_message(text, duration)
    end

    osd = {
        get = function(key) return defaults[key] or key end,
        show = function(key, duration) show_text(osd.get(key), duration) end,
        safe_osd_message = show_text,
    }

    msg.warn("[nso_retro] Using fallback messages (osd_messages.lua not loaded): " .. tostring(err))
    msg.warn("[nso_retro] Looked for: " .. osd_path)
else
    msg.info("[nso_retro] osd_messages.lua loaded successfully from: " .. osd_path)
end

-- English fallback for the messages that are not in the basic fallback above.
local OSD_FALLBACK = {
    nsoretro_stretch_blocked = "Stretch Window disabled while bezel is active",
    nsoretro_gpu_unavailable = "NSO Retro: GPU bezel unavailable (%s). Using the CPU bezel.",
    nsoretro_hole_failed     = "NSO Retro: bezel hole failed (%s)",
    nsoretro_ps1_missing     = "NSO Retro: bezel_to_bgra.ps1 not found (put it in the mpv data folder). Using the CPU bezel.",
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

local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
temp_dir = temp_dir:gsub("\\", "/")

-- -------------------------------------------------------------------------
-- Crop presets
-- -------------------------------------------------------------------------
local crops = {
crop1 = { filter = "crop=ih*4/3:ih", title = "NSO N64/GC (4:3)" },
crop2 = { filter = "crop=1316:1026", title = "NSO NES (4:3/CRT)" },
crop3 = { filter = "crop=1024:912", title = "NSO NES (Pixel Perfect)" },
crop4 = { filter = "crop=1316:1008", title = "NSO SNES/GEN (4:3/CRT)" },
crop5 = { filter = "crop=1152:1008", title = "NSO SNES (Pixel Perfect)" },
crop6 = { filter = "crop=1120:1008", title = "NSO GameBoy Color" },
crop7 = { filter = "crop=800:720", title = "NSO GameBoy (Small)" },
crop8 = { filter = "crop=1440:960", title = "NSO GameBoy Advance" },
crop9 = { filter = "crop=960:640", title = "NSO GameBoy Advance (Small)" },
crop10 = { filter = "crop=1280:896", title = "NSO Genesis (Pixel Perfect)" },
cropsp1 = { filter = "crop=1436:1008", title = "NSO N64 (Mario 64 Size)" },
cropsp2 = { filter = "crop=1611:983", title = "NSO N64 (DK64 Widescreen Size)" }
}

-- -------------------------------------------------------------------------
-- ORIGIN simplified shape system
-- -------------------------------------------------------------------------
local shape_paths = {
FRM1 = "shaders/shapes/crt-curvature-only.glsl",
FRM2 = "shaders/shapes/crt-curvature-onlyE.glsl",
FRM3 = "shaders/shapes/crt-widebarrel.glsl",
FRM4 = "shaders/shapes/crt-widebarrelE.glsl",
FRM5 = "shaders/shapes/crt-supercurvature.glsl",
FRM6 = "shaders/shapes/rounded-corners.glsl",
FRM7 = "shaders/shapes/tilted-crt.glsl",
FRM8 = "shaders/shapes/tilted-crt_inv.glsl",
FRM9 = "shaders/shapes/pinball-perspective.glsl",
FRMO_1 = "shaders/shapes/inward-keystone-bottom.glsl"
}

local active_crop = ""
local active_bezel = nil
local active_shape = "none"
local syncing_glsl = false
local bezel_apply_serial = 0
local bezel_sync_timer = nil
local glsl_resync_timer = nil
local fill_bezel_enabled = false
local fill_crop_enabled  = false

local BEZEL_DEBUG      = false
local BEZEL_BUILD      = "build-H"
local BEZEL_FIT_MODE   = "stretch"
local BEZEL_USE_GPU    = true
local BEZEL_OSD_INSIDE = true
local BEZEL_PS1        = nil
local BEZEL_OVERLAY_ID = 47
local BEZEL_CACHE_MAX  = 6

local BEZEL_HDR_WHITE_NITS = 203

local hdr_active = false
local shield_geom = nil
local shield_written = nil

local bezel_mode = nil
local gpu_failed = false
local gpu_canvas_w, gpu_canvas_h = nil, nil
local gpu_src = nil
local gpu_bitmap = nil
local gpu_busy = false
local gpu_timer = nil
local gpu_saved = nil
local gpu_display = nil
local gpu_cache = {}
local gpu_menu_open = false
local gpu_settling = false
local gpu_settle_timer = nil
local gpu_cut_cleanup

local current_bezel_image = nil
local current_bezel_id = nil
local current_bezel_x = nil
local current_bezel_y = nil
local current_bezel_w = nil
local current_bezel_h = nil

-- -------------------------------------------------------------------------
-- Display lock (disable Stretch Window while bezel is active)
-- -------------------------------------------------------------------------
local display_locked = false
local display_lock_values = {}

local DISPLAY_PROPS = {
    aspect = "video-aspect-override",
    zoom = "video-zoom",
    scalex = "video-scale-x",
    scaley = "video-scale-y",
    panx = "video-pan-x",
    pany = "video-pan-y",
    omx = "osd-margin-x",
    omy = "osd-margin-y",
}

local function lock_display()
    if display_locked then return end
    display_lock_values = {
        aspect = mp.get_property_number("video-aspect-override") or -1,
        zoom = mp.get_property_number("video-zoom") or 0,
        scalex = mp.get_property_number("video-scale-x") or 1,
        scaley = mp.get_property_number("video-scale-y") or 1,
        panx = mp.get_property_number("video-pan-x") or 0,
        pany = mp.get_property_number("video-pan-y") or 0,
    }
    display_locked = true
end

local function unlock_display()
    display_locked = false
    display_lock_values = {}
end

local function watch_display_lock(prop, key)
    mp.observe_property(prop, "number", function(_, val)
        if not display_locked or val == nil then return end
        local saved = display_lock_values[key]
        if saved == nil then return end
        if math.abs(val - saved) > 0.001 then
            mp.set_property_number(prop, saved)
            osd_fmt("nsoretro_stretch_blocked", 2)
        end
    end)
end

watch_display_lock("video-aspect-override", "aspect")
watch_display_lock("video-zoom", "zoom")
watch_display_lock("video-scale-x", "scalex")
watch_display_lock("video-scale-y", "scaley")
watch_display_lock("video-pan-x", "panx")
watch_display_lock("video-pan-y", "pany")

-- -------------------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------------------
local function split_shader_list_native(v)
    if type(v) == "table" then
        local out = {}
        for _, s in ipairs(v) do
            if s and s ~= "" then table.insert(out, tostring(s)) end
        end
        return out
    end
    if not v or v == "" then return {} end
    local out = {}
    for part in string.gmatch(tostring(v), "([^;]+)") do
        table.insert(out, part)
    end
    return out
end

local function path_is_shape(path)
    for _, shape_path in pairs(shape_paths) do
        if tostring(path) == shape_path then return true end
    end
    return false
end

local function current_shape_path()
    if active_shape ~= "none" and shape_paths[active_shape] then
        return shape_paths[active_shape]
    end
    return nil
end

local function shield_variant()
    if bezel_mode == "gpu" then return "gpu" end
    return hdr_active and "hdr" or "sdr"
end

local function shield_path_for(id, variant)
    return temp_dir .. "/protect_" .. (id or "default") .. "_" .. variant .. ".glsl"
end

local function get_shield_path()
    return shield_path_for(active_bezel, shield_variant())
end

local function remove_shield_files(id)
    if not id then return end
    os.remove(shield_path_for(id, "gpu"))
    os.remove(shield_path_for(id, "sdr"))
    os.remove(shield_path_for(id, "hdr"))
end

local function f6(n)
    return (string.format("%.6f", n):gsub(",", "."))
end

local function build_blackout_code(box)
    local cond = string.format("uv.x < %s || uv.x > %s || uv.y < %s || uv.y > %s",
        f6(box.x0), f6(box.x1), f6(box.y0), f6(box.y1))
    return table.concat({
        "//!HOOK MAINPRESUB\n//!BIND HOOKED\n//!COMPONENTS 4\n",
        "vec4 hook() {\nvec2 uv = HOOKED_pos;\nif (", cond, ") {\nreturn vec4(0.0, 0.0, 0.0, 1.0);\n}\nreturn HOOKED_texOff(0.0);\n}\n",
    })
end

local HDR_HELPERS = [[
vec3 srgb_to_linear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
vec3 linear_to_pq(vec3 nits) {
    vec3 y = clamp(nits / 10000.0, 0.0, 1.0);
    vec3 p = pow(y, vec3(0.1593017578125));
    return pow((0.8359375 + 18.8515625 * p) / (1.0 + 18.6875 * p), vec3(78.84375));
}
vec3 bezel_sdr_to_hdr(vec3 c) {
    const mat3 BT709_TO_BT2020 = mat3(
        0.627404, 0.069097, 0.016391,
        0.329283, 0.919540, 0.088013,
        0.043313, 0.011362, 0.895595);
    vec3 lin = srgb_to_linear(clamp(c, 0.0, 1.0));
    return linear_to_pq(BT709_TO_BT2020 * lin * %s);
}
]]

local function build_shield_code(box, variant)
    if variant == "gpu" then return build_blackout_code(box) end
    local hdr = (variant == "hdr")

    local cond = string.format("uv.x < %s || uv.x > %s || uv.y < %s || uv.y > %s",
        f6(box.x0), f6(box.x1), f6(box.y0), f6(box.y1))

    local helpers, restore = "", "return CLEAN_FRAME_tex(uv);"
    if hdr then
        helpers = HDR_HELPERS:format(f6(BEZEL_HDR_WHITE_NITS))
        restore = "vec4 c = CLEAN_FRAME_tex(uv); return vec4(bezel_sdr_to_hdr(c.rgb), c.a);"
    end

    return table.concat({
        "//!HOOK MAINPRESUB\n//!BIND HOOKED\n//!SAVE CLEAN_FRAME\n//!COMPONENTS 4\n",
        "vec4 hook() { return HOOKED_texOff(0.0); }\n\n",
        "//!HOOK MAINPRESUB\n//!BIND HOOKED\n//!COMPONENTS 4\n",
        "vec4 hook() {\nvec2 uv = HOOKED_pos;\nif (", cond, ") {\nreturn vec4(0.0, 0.0, 0.0, 1.0);\n}\nreturn HOOKED_texOff(0.0);\n}\n\n",
        "//!HOOK OUTPUT\n//!BIND HOOKED\n//!BIND CLEAN_FRAME\n//!COMPONENTS 4\n",
        helpers,
        "vec4 hook() {\nvec2 uv = HOOKED_pos;\nif (", cond, ") {\n", restore, "\n}\nreturn HOOKED_texOff(0.0);\n}\n",
    })
end

local function ensure_shield_file()
    if not active_bezel or not shield_geom then return false end
    local path = get_shield_path()
    if shield_written == path then return true end

    local f = io.open(path, "w")
    if not f then
        msg.warn("[nso_retro] Could not write shield shader: " .. path)
        return false
    end
    f:write(build_shield_code(shield_geom, shield_variant()))
    f:close()
    shield_written = path
    return true
end

local function update_shape_property()
    mp.set_property_native("user-data/active_shape", active_shape)
end

local function lists_equal(a, b)
    if #a ~= #b then return false end
    for i = 1, #a do
        if tostring(a[i]) ~= tostring(b[i]) then return false end
    end
    return true
end

local function build_stack(list)
    local clean = {}
    local scaler = {}
    for _, s in ipairs(list) do
        local str = tostring(s)
        -- El shader de escalado por GPU (msc_scale_) se conserva y va siempre
        -- primero, pero no cuenta como "otro shader" para decidir el escudo.
        if str:find("msc_scale_") then
            table.insert(scaler, str)
        elseif not str:find("protect_") and not path_is_shape(str) then
            table.insert(clean, str)
        end
    end

    local shape_path = current_shape_path()
    local final = {}
    for _, s in ipairs(scaler) do table.insert(final, s) end

    local needs_shield = false
    if active_bezel and shield_geom then
        if bezel_mode == "gpu" then
            needs_shield = (not fill_bezel_enabled) and (shape_path ~= nil or #clean > 0)
        else
            needs_shield = hdr_active or shape_path ~= nil or #clean > 0
        end
    end
    if needs_shield and ensure_shield_file() then
        table.insert(final, get_shield_path())
    end
    if shape_path then table.insert(final, shape_path) end
    for _, s in ipairs(clean) do table.insert(final, s) end
    return final
end

local function sync_glsl_stack(force)
    if syncing_glsl then return end
    syncing_glsl = true

    local current = split_shader_list_native(mp.get_property_native("glsl-shaders", {}) or {})
    local final = build_stack(current)

    local has_shield = false
    for _, v in ipairs(final) do
        if tostring(v):find("protect_") then has_shield = true break end
    end
    if (force and has_shield) or not lists_equal(current, final) then
        mp.set_property_native("glsl-shaders", final)
    end
    update_shape_property()
    syncing_glsl = false
end

local function toggle_shape(id)
    if not shape_paths[id] and id ~= "none" then return end
    if active_shape == id then active_shape = "none" else active_shape = id end
    sync_glsl_stack()
end

local function clear_shapes()
    active_shape = "none"
    sync_glsl_stack()
end

mp.register_script_message("toggle-addon-shader", toggle_shape)
mp.register_script_message("clear-addon-shaders", clear_shapes)

-- -------------------------------------------------------------------------
-- Crop helpers
-- -------------------------------------------------------------------------
local function parse_crop_filter(filter_str)
    local args = filter_str:match("^crop=(.+)$")
    if not args then return nil end

    local parts = {}
    for p in args:gmatch("[^:]+") do table.insert(parts, p) end

    local has_expression = false
    for _, p in ipairs(parts) do
        if p:match("[%*%+%-%/a-zA-Z]") then
            has_expression = true
            break
        end
    end

    if has_expression then
        return { name = "lavfi", params = { graph = "crop=" .. args } }
    end

    local w, h = tonumber(parts[1]), tonumber(parts[2])
    local x, y = tonumber(parts[3]), tonumber(parts[4])

    if w and h then
        local expr = string.format(
            "crop=iw*%d/1920:ih*%d/1080%s%s",
            w,
            h,
            x and string.format(":iw*%d/1920", x) or "",
            y and string.format(":ih*%d/1080", y) or ""
        )
        return { name = "lavfi", params = { graph = expr } }
    end

    return { name = "lavfi", params = { graph = "crop=" .. args } }
end

local function eval_simple_expr(expr, base_w, base_h)
    local s = tostring(expr):gsub("ih", tostring(base_h)):gsub("iw", tostring(base_w))
    local fn = load("return " .. s)
    if not fn then return nil end
    local ok, result = pcall(fn)
    if ok and type(result) == "number" then
        return math.floor(result)
    end
    return nil
end

local function crop_rect_string(id)
    local c = crops[id]
    if not c then return "" end
    local args = c.filter:match("^crop=(.+)$")
    if not args then return "" end

    local parts = {}
    for p in args:gmatch("[^:]+") do table.insert(parts, p) end

    local function val(s, base_w, base_h)
        if not s then return nil end
        return tonumber(s) or eval_simple_expr(s, base_w, base_h)
    end

    local W = val(parts[1], 1920, 1080)
    local H = val(parts[2], 1920, 1080)
    if not W or not H or W < 1 or H < 1 then return "" end
    local X = val(parts[3], 1920, 1080) or math.floor((1920 - W) / 2)
    local Y = val(parts[4], 1920, 1080) or math.floor((1080 - H) / 2)

    local function f6(n)
        return (string.format("%.6f", n):gsub(",", "."))
    end
    return table.concat({ f6(X / 1920), f6(Y / 1080), f6(W / 1920), f6(H / 1080) }, "|")
end

local function get_video_size()
    local vf = mp.get_property_native("vf", {})
    for _, f in ipairs(vf) do
        if f.label == "msc_scale" and f.params and f.params.graph then
            local w, h = f.params.graph:match("scale=(%d+):(%d+)")
            if w and h then return tonumber(w), tonumber(h) end
        end
    end
    
    local vw = mp.get_property_number("width") or mp.get_property_number("video-params/w") or 1920
    local vh = mp.get_property_number("height") or mp.get_property_number("video-params/h") or 1080
    if vw <= 0 then vw = 1920 end
    if vh <= 0 then vh = 1080 end
    return math.max(1, vw), math.max(1, vh)
end

local function get_crop_filter(id, use_fit)
    local filter_str = crops[id].filter
    local args = filter_str:match("^crop=(.+)$")
    if not args then return nil end

    if not use_fit then
        return parse_crop_filter(filter_str)
    end

    local parts = {}
    for p in args:gmatch("[^:]+") do table.insert(parts, p) end
    local w_str, h_str = parts[1], parts[2]
    local x_str, y_str = parts[3], parts[4]
    if not w_str or not h_str then return nil end

    local vw, vh = get_video_size()

    local W, H
    local w_num = tonumber(w_str)
    local h_num = tonumber(h_str)
    if w_num then
        W = math.floor(w_num * vw / 1920)
    else
        W = eval_simple_expr(w_str, vw, vh)
    end
    if h_num then
        H = math.floor(h_num * vh / 1080)
    else
        H = eval_simple_expr(h_str, vw, vh)
    end
    if not W or not H or W < 1 or H < 1 then return nil end

    local X, Y
    if x_str and x_str ~= "" then
        local xn = tonumber(x_str)
        X = xn and math.floor(xn * vw / 1920) or eval_simple_expr(x_str, vw, vh)
    end
    if y_str and y_str ~= "" then
        local yn = tonumber(y_str)
        Y = yn and math.floor(yn * vh / 1080) or eval_simple_expr(y_str, vw, vh)
    end
    if not X then X = math.floor((vw - W) / 2) end
    if not Y then Y = math.floor((vh - H) / 2) end

    W = math.max(1, math.min(W, vw))
    H = math.max(1, math.min(H, vh))
    X = math.max(0, math.min(X, vw - W))
    Y = math.max(0, math.min(Y, vh - H))

    if W % 2 ~= 0 then W = math.min(vw, W + 1) end
    if H % 2 ~= 0 then H = math.min(vh, H + 1) end
    if X % 2 ~= 0 then X = math.max(0, X - 1) end
    if Y % 2 ~= 0 then Y = math.max(0, Y - 1) end

    if X + W > vw then X = vw - W end
    if Y + H > vh then Y = vh - H end
    if X < 0 then X = 0 end
    if Y < 0 then Y = 0 end

    local graph = string.format(
        "scale=%d:%d,setsar=1",
        W, H
    )
    return { name = "lavfi", params = { graph = graph } }
end

local function remove_all_crops(vf_list)
    local clean = {}

    for _, f in ipairs(vf_list or {}) do
        local is_crop = false
        if type(f) == "table" then
            if f.name == "crop" then
                is_crop = true
            elseif f.label == "croptag" then
                is_crop = true
            elseif f.name == "lavfi" and f.params and f.params.graph then
                local g = f.params.graph
                if g:match("^crop=") then
                    is_crop = true
                elseif g:match("^scale=") and g:find("pad=", 1, true) then
                    is_crop = true
                end
            end
        end
        if not is_crop then table.insert(clean, f) end
    end

    return clean
end

local function insert_crop_filter(vf_list, crop_table)
    local pos = 1
    for i, f in ipairs(vf_list) do
        if type(f) == "table" and f.label == "msc_scale" then
            pos = i + 1
            break
        end
    end
    table.insert(vf_list, pos, crop_table)
end

local function vf_signature(list)
    local parts = {}
    for _, f in ipairs(list or {}) do
        if type(f) == "table" then
            local graph = (f.params and f.params.graph) or ""
            parts[#parts + 1] = tostring(f.name) .. "|" .. tostring(f.label) .. "|" .. tostring(graph)
        end
    end
    return table.concat(parts, "\n")
end

local function set_vf_if_changed(new_list)
    local current = mp.get_property_native("vf", {}) or {}
    if vf_signature(current) == vf_signature(new_list) then return false end
    mp.set_property_native("vf", new_list)
    return true
end

local function remove_bezeltag(vf_list)
    local clean = {}
    for _, f in ipairs(vf_list or {}) do
        if not (type(f) == "table" and f.label == "bezeltag") then
            table.insert(clean, f)
        end
    end
    return clean
end

local function scale_from_base_1080(px, py, pw, ph)
    local vw, vh = get_video_size()
    local sx = vw / 1920
    local sy = vh / 1080

    local x1 = math.floor(px * sx)
    local y1 = math.floor(py * sy)
    local x2 = math.ceil((px + pw) * sx)
    local y2 = math.ceil((py + ph) * sy)

    x1 = math.max(0, math.min(x1, vw - 1))
    y1 = math.max(0, math.min(y1, vh - 1))
    x2 = math.max(x1 + 1, math.min(x2, vw))
    y2 = math.max(y1 + 1, math.min(y2, vh))

    local is_1080p = (vw == 1920 and vh == 1080)
    if not is_1080p then
        local ext = 2
        x1 = math.max(0, x1 - ext)
        y1 = math.max(0, y1 - ext)
        x2 = math.min(vw, x2 + ext)
        y2 = math.min(vh, y2 + ext)
    end

    local w = x2 - x1
    local h = y2 - y1
    if w % 2 ~= 0 then
        if x1 >= 1 then x1 = x1 - 1 else x2 = x2 + 1 end
        w = w + 1
    end
    if h % 2 ~= 0 then
        if y1 >= 1 then y1 = y1 - 1 else y2 = y2 + 1 end
        h = h + 1
    end

    return x1, y1, w, h, vw, vh
end

local function remove_protect_shader()
    local shaders = mp.get_property_native("glsl-shaders", {}) or {}
    local clean = {}
    for _, s in ipairs(shaders) do
        if not tostring(s):find("protect_") then table.insert(clean, s) end
    end
    mp.set_property_native("glsl-shaders", clean)
end

local apply_bezel

local function round(n) return math.floor(n + 0.5) end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function find_ps1()
    if BEZEL_PS1 and utils.file_info(BEZEL_PS1) then return BEZEL_PS1 end
    local candidates = {
        "~~/data/bezel_to_bgra.ps1",
        "~~/scripts/bezel_to_bgra.ps1",
        "~~/script-opts/bezel_to_bgra.ps1",
        "~~/bezel_to_bgra.ps1",
    }
    for _, c in ipairs(candidates) do
        local p = mp.command_native({ "expand-path", c })
        if p then
            p = p:gsub("\\", "/")
            if utils.file_info(p) then return p end
        end
    end
    local p = script_dir .. "bezel_to_bgra.ps1"
    if utils.file_info(p) then return p end
    return nil
end

local function bitmap_file_ok(path, size)
    local f = io.open(path, "rb")
    if not f then return false end
    local len = f:seek("end")
    f:close()
    return len == size
end

local function cache_touch(path)
    for i, p in ipairs(gpu_cache) do
        if p == path then table.remove(gpu_cache, i) break end
    end
    table.insert(gpu_cache, path)
    while #gpu_cache > BEZEL_CACHE_MAX do
        local old = table.remove(gpu_cache, 1)
        if not (gpu_bitmap and gpu_bitmap.path == old) then os.remove(old) end
    end
end

local function cleanup_old_bitmaps()
    local files = utils.readdir(temp_dir, "files")
    if not files then return end
    local now = os.time()
    for _, name in ipairs(files) do
        if name:find("^nso_bezel_") and (name:find("%.bgra$") or name:find("%.tmp$")) then
            local path = temp_dir .. "/" .. name
            local fi = utils.file_info(path)
            if fi and fi.mtime and now - fi.mtime > 3 * 86400 then os.remove(path) end
        end
    end
end
cleanup_old_bitmaps()

local function gpu_save_display()
    if gpu_saved then return end
    gpu_saved = {
        aspect = mp.get_property_number("video-aspect-override") or -1,
        zoom = mp.get_property_number("video-zoom") or 0,
        scalex = mp.get_property_number("video-scale-x") or 1,
        scaley = mp.get_property_number("video-scale-y") or 1,
        panx = mp.get_property_number("video-pan-x") or 0,
        pany = mp.get_property_number("video-pan-y") or 0,
        omx = mp.get_property_number("osd-margin-x") or 25,
        omy = mp.get_property_number("osd-margin-y") or 22,
    }
    gpu_display = {}
end

local function gpu_set_display(vals)
    for key, prop in pairs(DISPLAY_PROPS) do
        local v = vals[key]
        if v ~= nil then
            v = tonumber(string.format("%.6f", v))
            if not gpu_display or gpu_display[key] ~= v then
                mp.set_property_number(prop, v)
                if gpu_display then gpu_display[key] = v end
                -- Actualizar los valores de bloqueo para que el observer no revierta
                if display_locked then display_lock_values[key] = v end
            end
        end
    end
end

local function gpu_teardown()
    if gpu_timer then gpu_timer:kill() gpu_timer = nil end
    if gpu_settle_timer then gpu_settle_timer:kill() gpu_settle_timer = nil end
    gpu_settling = false
    mp.commandv("overlay-remove", BEZEL_OVERLAY_ID)
    gpu_cut_cleanup(nil)
    if gpu_saved then
        local saved = gpu_saved
        gpu_saved = nil
        gpu_display = nil
        gpu_set_display(saved)
    end
    gpu_bitmap = nil
    unlock_display()
end

local function gpu_fail(reason)
    msg.warn("[nso_retro] GPU bezel disabled (" .. tostring(reason) .. "); using the CPU bezel.")
    if not gpu_failed then
        osd_fmt("nsoretro_gpu_unavailable", 5, tostring(reason))
    end
    gpu_failed = true
    gpu_teardown()
    bezel_mode = nil
    if active_bezel and current_bezel_image then
        apply_bezel(current_bezel_image, current_bezel_id,
            current_bezel_x, current_bezel_y, current_bezel_w, current_bezel_h)
    end
end

local function gpu_target()
    if not shield_geom or not gpu_canvas_w or not gpu_src then return nil end
    local W = mp.get_property_number("osd-width") or 0
    local H = mp.get_property_number("osd-height") or 0
    if W < 2 or H < 2 then return nil end

    local s = math.min(W / gpu_canvas_w, H / gpu_canvas_h)
    local rw, rh = gpu_canvas_w * s, gpu_canvas_h * s
    local rx, ry = (W - rw) / 2, (H - rh) / 2
    local bw, bh = math.max(2, round(rw)), math.max(2, round(rh))

    local N = shield_geom
    local hx0 = clamp(math.floor(N.x0 * bw), 0, bw - 1)
    local hy0 = clamp(math.floor(N.y0 * bh), 0, bh - 1)
    local hx1 = clamp(math.ceil(N.x1 * bw), hx0 + 1, bw)
    local hy1 = clamp(math.ceil(N.y1 * bh), hy0 + 1, bh)

    local fi = utils.file_info(gpu_src)
    local stamp = fi and (tostring(fi.size) .. "_" .. tostring(math.floor(fi.mtime or 0))) or "0"
    local id = tostring(current_bezel_id):gsub("[^%w_%-]", "_")
    local path = temp_dir .. "/" .. string.format("nso_bezel_%s_%dx%d_%d_%d_%d_%d_%s.bgra",
        id, bw, bh, hx0, hy0, hx1, hy1, stamp)

    return {
        W = W, H = H, rx = rx, ry = ry, bw = bw, bh = bh,
        hx0 = hx0, hy0 = hy0, hx1 = hx1, hy1 = hy1, path = path,
    }
end

local gpu_cut_files = {}
local gpu_cut_warned = false

local function gpu_cut_fail(why)
    msg.warn("[nso_retro] bezel hole for the menu failed: " .. tostring(why))
    if not gpu_cut_warned then
        gpu_cut_warned = true
        osd_fmt("nsoretro_hole_failed", 5, tostring(why))
    end
    return nil
end

local function gpu_cut_bitmap(bm, t, ox, oy)
    local a, b, c, d
    local r = mp.get_property("user-data/menu_rect")
    if r then
        a, b, c, d = r:match("^(-?%d+),(-?%d+),(-?%d+),(-?%d+)$")
    end
    if a then
        a, b, c, d = tonumber(a), tonumber(b), tonumber(c), tonumber(d)
    else
        local sc = math.min(t.W / 1280, t.H / 720)
        local mx, my = (t.W - 1280 * sc) / 2, (t.H - 720 * sc) / 2
        a = math.floor(mx + 140 * sc) - 1
        b = math.floor(my + 64 * sc) - 1
        c = math.ceil(mx + 1140 * sc) + 1
        d = math.ceil(my + 656 * sc) + 1
    end

    local kx, ky = t.bw / bm.w, t.bh / bm.h
    local x0 = clamp(math.floor((a - ox) / kx), 0, bm.w)
    local x1 = clamp(math.ceil((c - ox) / kx), 0, bm.w)
    local y0 = clamp(math.floor((b - oy) / ky), 0, bm.h)
    local y1 = clamp(math.ceil((d - oy) / ky), 0, bm.h)
    if x1 <= x0 or y1 <= y0 then return bm.path end

    local base = bm.path:gsub("%.bgra$", "")
    local path = string.format("%s_m%d_%d_%d_%d.bgra", base, x0, y0, x1, y1)
    local size = bm.w * bm.h * 4
    if not bitmap_file_ok(path, size) then
        local f = io.open(bm.path, "rb")
        if not f then return gpu_cut_fail("cannot read bitmap") end
        local data = f:read("*a")
        f:close()
        if not data or #data ~= size then return gpu_cut_fail("bitmap size mismatch") end

        local stride = bm.w * 4
        local hole = string.rep("\0", (x1 - x0) * 4)
        local parts = { data:sub(1, y0 * stride) }
        for y = y0, y1 - 1 do
            local rs = y * stride
            parts[#parts + 1] = data:sub(rs + 1, rs + x0 * 4)
            parts[#parts + 1] = hole
            parts[#parts + 1] = data:sub(rs + x1 * 4 + 1, rs + stride)
        end
        parts[#parts + 1] = data:sub(y1 * stride + 1)

        local out = io.open(path, "wb")
        if not out then return gpu_cut_fail("cannot write " .. path) end
        out:write(table.concat(parts))
        out:close()
        if not bitmap_file_ok(path, size) then return gpu_cut_fail("written file has wrong size") end
    end
    local known = false
    for _, p in ipairs(gpu_cut_files) do if p == path then known = true end end
    if not known then table.insert(gpu_cut_files, path) end
    return path
end

gpu_cut_cleanup = function(keep)
    for i = #gpu_cut_files, 1, -1 do
        local p = gpu_cut_files[i]
        if p ~= keep then
            os.remove(p)
            table.remove(gpu_cut_files, i)
        end
    end
end

local function gpu_place(t)
    local bm = gpu_bitmap
    if not bm then return true end

    local ox, oy = round(t.rx), round(t.ry)
    if gpu_settling then
        mp.commandv("overlay-remove", BEZEL_OVERLAY_ID)
    else
        local path = bm.path
        if gpu_menu_open then
            path = gpu_cut_bitmap(bm, t, ox, oy)
        end
        if not path then
            mp.commandv("overlay-remove", BEZEL_OVERLAY_ID)
        else
            local ok
            if bm.w == t.bw and bm.h == t.bh then
                ok = mp.commandv("overlay-add", BEZEL_OVERLAY_ID, ox, oy, path, 0, "bgra",
                    bm.w, bm.h, bm.w * 4)
            else
                ok = mp.commandv("overlay-add", BEZEL_OVERLAY_ID, ox, oy, path, 0, "bgra",
                    bm.w, bm.h, bm.w * 4, t.bw, t.bh)
            end
            if not ok then return false end
        end
        if not gpu_menu_open then gpu_cut_cleanup(nil) end
    end

    local kx, ky = t.bw / bm.w, t.bh / bm.h
    local wx0, wy0 = ox + bm.hx0 * kx, oy + bm.hy0 * ky
    local wx1, wy1 = ox + bm.hx1 * kx, oy + bm.hy1 * ky

    gpu_save_display()
    local vals = {
        aspect = gpu_saved.aspect,
        zoom = gpu_saved.zoom, panx = gpu_saved.panx, pany = gpu_saved.pany,
        scalex = gpu_saved.scalex, scaley = gpu_saved.scaley,
    }
    if fill_bezel_enabled then
        local ow, oh = wx1 - wx0, wy1 - wy0
        local hole_A = ow / oh
        local vw = mp.get_property_number("video-params/w")
        local vh = mp.get_property_number("video-params/h")
        local A = (gpu_saved.aspect and gpu_saved.aspect > 0) and gpu_saved.aspect
            or ((vw and vh and vh > 0) and vw / vh) or (16 / 9)
        local tw, th
        if BEZEL_FIT_MODE == "stretch" then
            tw, th = ow, oh
        elseif BEZEL_FIT_MODE == "contain" then
            if A > hole_A then tw, th = ow, ow / A else tw, th = oh * A, oh end
        else
            if A > hole_A then tw, th = oh * A, oh else tw, th = ow, ow / A end
        end
        if mp.get_property_number("video-scale-x") ~= nil then
            local base_w = math.min(t.W, t.H * A)
            local base_h = base_w / A
            vals.aspect = gpu_saved.aspect
            vals.zoom = 0
            vals.scalex = tw / base_w
            vals.scaley = th / base_h
        else
            local TA = tw / th
            vals.aspect = TA
            local base_w = math.min(t.W, t.H * TA)
            vals.zoom = math.log(tw / base_w) / math.log(2)
        end
        vals.panx = ((wx0 + wx1) / 2 - t.W / 2) / tw
        vals.pany = ((wy0 + wy1) / 2 - t.H / 2) / th
    end
    if BEZEL_OSD_INSIDE then
        local k = 720 / t.H
        vals.omx = clamp(math.floor(gpu_saved.omx + math.max(wx0, t.W - wx1) * k + 0.5), 0, 300)
        vals.omy = clamp(math.floor(gpu_saved.omy + math.max(wy0, t.H - wy1) * k + 0.5), 0, 300)
    end
    gpu_set_display(vals)
    return true
end

local function gpu_convert(t, done)
    local ps1 = find_ps1()
    if not ps1 then done(false, "bezel_to_bgra.ps1 not found") return end

    mp.command_native_async({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = {
            "powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
            "-WindowStyle", "Hidden", "-File", ps1,
            "-Src", gpu_src, "-Dest", t.path,
            "-W", string.format("%d", t.bw), "-H", string.format("%d", t.bh),
            "-HoleX", string.format("%d", t.hx0), "-HoleY", string.format("%d", t.hy0),
            "-HoleW", string.format("%d", t.hx1 - t.hx0), "-HoleH", string.format("%d", t.hy1 - t.hy0),
        },
    }, function(success, res, err)
        if success and res and res.status == 0 and bitmap_file_ok(t.path, t.bw * t.bh * 4) then
            cache_touch(t.path)
            done(true)
        else
            local detail = res and res.stderr
            if not detail or detail == "" then detail = err or (res and res.error_string) or "no output" end
            msg.warn("[nso_retro] bezel_to_bgra.ps1 failed: " .. tostring(detail))
            done(false, "conversion failed")
        end
    end)
end

local function gpu_refresh()
    if bezel_mode ~= "gpu" or not active_bezel then return end
    local t = gpu_target()
    if not t then return end

    if not (gpu_bitmap and gpu_bitmap.path == t.path) and bitmap_file_ok(t.path, t.bw * t.bh * 4) then
        gpu_bitmap = { path = t.path, w = t.bw, h = t.bh,
            hx0 = t.hx0, hy0 = t.hy0, hx1 = t.hx1, hy1 = t.hy1 }
        cache_touch(t.path)
    end

    if gpu_bitmap then
        if not gpu_place(t) then gpu_fail("overlay-add failed") return end
        if gpu_bitmap.path == t.path then return end
    end

    if gpu_busy then return end
    gpu_busy = true
    gpu_convert(t, function(ok, why)
        gpu_busy = false
        if bezel_mode ~= "gpu" then return end
        if not ok then gpu_fail(why) return end
        gpu_refresh()
    end)
end

local function gpu_schedule(delay)
    if bezel_mode ~= "gpu" then return end
    if gpu_timer then gpu_timer:kill() end
    gpu_timer = mp.add_timeout(delay, function()
        gpu_timer = nil
        gpu_refresh()
    end)
end

local function gpu_settle_end()
    gpu_settle_timer = nil
    gpu_settling = false
    gpu_refresh()
end

local function gpu_begin_settle(delay)
    if bezel_mode ~= "gpu" then return end
    if not gpu_settling then
        gpu_settling = true
        mp.commandv("overlay-remove", BEZEL_OVERLAY_ID)
    end
    if gpu_settle_timer then gpu_settle_timer:kill() end
    gpu_settle_timer = mp.add_timeout(delay, gpu_settle_end)
end

local function gpu_on_osd_size()
    if bezel_mode ~= "gpu" then return end
    if gpu_settling then
        gpu_begin_settle(0.4)
        return
    end
    if gpu_bitmap then
        local t = gpu_target()
        if t then gpu_place(t) end
    end
    gpu_schedule(0.25)
end
mp.observe_property("osd-width", "number", gpu_on_osd_size)
mp.observe_property("osd-height", "number", gpu_on_osd_size)

mp.observe_property("user-data/capture_resolution", "string", function()
    gpu_begin_settle(0.8)
end)
mp.observe_property("video-params/h", "number", function()
    gpu_begin_settle(0.8)
end)

local function gpu_set_menu(open, how)
    if BEZEL_DEBUG then
        msg.info("[nso_retro] menu open=" .. tostring(open) .. " via " .. how .. " bezel_mode=" .. tostring(bezel_mode))
    end
    if open == gpu_menu_open then return end
    gpu_menu_open = open
    if bezel_mode ~= "gpu" then return end
    gpu_refresh()
end
mp.observe_property("user-data/menu_rect", "string", function()
    if gpu_menu_open and bezel_mode == "gpu" then gpu_refresh() end
end)
mp.observe_property("user-data/menu_visible", "string", function(_, v)
    if v == "yes" or v == "no" then gpu_set_menu(v == "yes", "user-data") end
end)
mp.register_script_message("msc-menu-visible", function(v)
    gpu_set_menu(v == "yes", "script-message")
end)

local function clear_bezel_only()
    set_vf_if_changed(remove_bezeltag(mp.get_property_native("vf", {}) or {}))

    gpu_teardown()
    bezel_mode = nil
    gpu_canvas_w, gpu_canvas_h = nil, nil
    gpu_src = nil

    local old_bezel = active_bezel
    active_bezel = nil
    shield_geom = nil
    shield_written = nil
    fill_bezel_enabled = false

    current_bezel_image = nil
    current_bezel_id = nil
    current_bezel_x = nil
    current_bezel_y = nil
    current_bezel_w = nil
    current_bezel_h = nil

    mp.set_property("user-data/bezel_fit", "none")
    mp.set_property("user-data/active_bezel", "none")

    if bezel_sync_timer then
        bezel_sync_timer:kill()
        bezel_sync_timer = nil
    end

    remove_protect_shader()
    remove_shield_files(old_bezel)
end

local function clear_crop_only()
    local vf_list = remove_all_crops(mp.get_property_native("vf", {}) or {})
    mp.set_property_native("vf", vf_list)

    active_crop = ""
    fill_crop_enabled = false
    mp.set_property("user-data/crop_rect", "")
    mp.set_property("user-data/crop_fit", "none")
    mp.set_property("user-data/crop-active", "")
end

apply_bezel = function(image_file, bezel_id, px, py, pw, ph)
    px, py, pw, ph = tonumber(px), tonumber(py), tonumber(pw), tonumber(ph)
    if not px or not py or not pw or not ph then return end

    local src = mp.command_native({ "expand-path", "~~/bezels/" .. image_file })
    if not src or not utils.file_info(src) then
        msg.warn("[nso_retro] Bezel image not found: " .. tostring(src))
        return
    end

    current_bezel_image = image_file
    current_bezel_id = bezel_id
    current_bezel_x = px
    current_bezel_y = py
    current_bezel_w = pw
    current_bezel_h = ph

    local previous_bezel = active_bezel

    local vf_list = mp.get_property_native("vf", {}) or {}
    vf_list = remove_bezeltag(remove_all_crops(vf_list))

    local inner_x, inner_y, inner_w, inner_h, vw, vh = scale_from_base_1080(px, py, pw, ph)

    if vw == 1920 and vh == 1080 then
        local right_base = px + pw
        local right_margin = 1920 - right_base
        if right_margin >= 280 and right_margin <= 320 and inner_w > 1 then
            inner_w = inner_w - 1
        end
    end

    shield_geom = {
        x0 = inner_x / vw,
        x1 = (inner_x + inner_w) / vw,
        y0 = inner_y / vh,
        y1 = (inner_y + inner_h) / vh,
    }
    shield_written = nil

    local serial = bezel_apply_serial + 1
    bezel_apply_serial = serial

    active_bezel = bezel_id
    active_crop = ""
    mp.set_property("user-data/active_bezel", bezel_id)
    mp.set_property("user-data/crop_rect", "")
    mp.set_property("user-data/crop-active", "")

    local use_gpu = BEZEL_USE_GPU and not gpu_failed
    if use_gpu and not find_ps1() then
        msg.warn("[nso_retro] bezel_to_bgra.ps1 not found; using the CPU bezel.")
        osd_fmt("nsoretro_ps1_missing", 5)
        use_gpu = false
    end

    if use_gpu then
        bezel_mode = "gpu"
        gpu_canvas_w, gpu_canvas_h = vw, vh
        gpu_src = src
        gpu_bitmap = nil
        if previous_bezel ~= bezel_id then
            mp.commandv("overlay-remove", BEZEL_OVERLAY_ID)
        end
        set_vf_if_changed(vf_list)
        lock_display()
    else
        if bezel_mode == "gpu" then gpu_teardown() end
        bezel_mode = "legacy"
        gpu_canvas_w, gpu_canvas_h = nil, nil
        gpu_src = nil

        local path = src:gsub("\\", "/"):gsub(":", "\\:")
        local graph_str

        if fill_bezel_enabled then
            graph_str = string.format(
                "movie='%s'[bz];" ..
                "[bz][in]scale2ref=iw:ih[bzfull][base];" ..
                "[base]scale=%d:%d:flags=bicubic,setsar=1[vidwin];" ..
                "[bzfull][vidwin]overlay=%d:%d",
                path,
                inner_w,
                inner_h,
                inner_x,
                inner_y
            )
        else
            graph_str = string.format(
                "movie='%s'[bz];" ..
                "[bz][in]scale2ref=iw:ih[bzfull][base];" ..
                "[base]crop=%d:%d:%d:%d:exact=1,setsar=1[vidwin];" ..
                "[bzfull][vidwin]overlay=%d:%d",
                path,
                inner_w,
                inner_h,
                inner_x,
                inner_y,
                inner_x,
                inner_y
            )
        end

        table.insert(vf_list, {
            name = "lavfi",
            label = "bezeltag",
            params = { graph = graph_str }
        })

        set_vf_if_changed(vf_list)
    end

    if bezel_sync_timer then
        bezel_sync_timer:kill()
        bezel_sync_timer = nil
    end

    bezel_sync_timer = mp.add_timeout(0.05, function()
        bezel_sync_timer = nil
        if serial ~= bezel_apply_serial then return end

        sync_glsl_stack(true)

        if previous_bezel and previous_bezel ~= bezel_id then
            remove_shield_files(previous_bezel)
        end

        if bezel_mode == "gpu" then gpu_refresh() end
    end)
end

local function toggle_crop(id)
    if active_bezel then clear_bezel_only() end

    local vf_list = remove_all_crops(mp.get_property_native("vf", {}) or {})
    if active_crop == id then
        mp.set_property_native("vf", vf_list)
        active_crop = ""
        fill_crop_enabled = false
        mp.set_property("user-data/crop_rect", "")
        mp.set_property("user-data/crop_fit", "none")
        mp.set_property("user-data/crop-active", "")
        return
    end

    local crop_table = get_crop_filter(id, fill_crop_enabled)
    if crop_table then
        crop_table.label = "croptag"
        insert_crop_filter(vf_list, crop_table)
        mp.set_property_native("vf", vf_list)
    else
        mp.commandv("vf", "add", crops[id].filter)
    end

    active_crop = id
    mp.set_property("user-data/crop_rect", crop_rect_string(id))
    mp.set_property("user-data/crop_fit", fill_crop_enabled and "fill" or "none")
    mp.set_property("user-data/crop-active", id)
end

for id, _ in pairs(crops) do
    mp.add_key_binding(nil, id, function() toggle_crop(id) end)
end

mp.register_script_message("toggle-bezel", function(image_file, bezel_id, px, py, pw, ph)
    if active_bezel == bezel_id then
        clear_bezel_only()
        return
    end
    apply_bezel(image_file, bezel_id, px, py, pw, ph)
end)

mp.register_script_message("clear-bezel", function()
    clear_bezel_only()
end)

mp.register_script_message("clear-crop", function()
    clear_crop_only()
end)

mp.register_script_message("reapply-bezel-shield", function()
    sync_glsl_stack()
end)

mp.register_script_message("bezel-fill-full-image", function()
    if not active_bezel or not current_bezel_image then
        osd.show("nsoretro_no_bezel", 3)
        return
    end

    fill_bezel_enabled = true
    mp.set_property("user-data/bezel_fit", "fill")

    apply_bezel(
        current_bezel_image,
        current_bezel_id,
        current_bezel_x,
        current_bezel_y,
        current_bezel_w,
        current_bezel_h
    )

    osd.show("nsoretro_fill_on", 2)
end)

mp.register_script_message("bezel-reset-video-fit", function()
    fill_bezel_enabled = false
    mp.set_property("user-data/bezel_fit", "none")

    if active_bezel and current_bezel_image then
        apply_bezel(
            current_bezel_image,
            current_bezel_id,
            current_bezel_x,
            current_bezel_y,
            current_bezel_w,
            current_bezel_h
        )
    end

    osd.show("nsoretro_reset", 2)
end)

mp.register_script_message("bezel-fill-toggle", function()
    if not active_bezel or not current_bezel_image then
        osd.show("nsoretro_no_bezel", 3)
        return
    end

    fill_bezel_enabled = not fill_bezel_enabled

    if fill_bezel_enabled then
        mp.set_property("user-data/bezel_fit", "fill")
        apply_bezel(
            current_bezel_image,
            current_bezel_id,
            current_bezel_x,
            current_bezel_y,
            current_bezel_w,
            current_bezel_h
        )
        osd.show("nsoretro_fill_on", 2)
    else
        mp.set_property("user-data/bezel_fit", "none")
        apply_bezel(
            current_bezel_image,
            current_bezel_id,
            current_bezel_x,
            current_bezel_y,
            current_bezel_w,
            current_bezel_h
        )
        osd.show("nsoretro_fill_off", 2)
    end
end)

mp.register_script_message("crop-fill-toggle", function()
    if not active_crop or active_crop == "" then
        osd.show("nsoretro_no_crop", 3)
        return
    end

    fill_crop_enabled = not fill_crop_enabled

    if fill_crop_enabled then
        mp.set_property("user-data/crop_fit", "fill")
    else
        mp.set_property("user-data/crop_fit", "none")
    end

    local id = active_crop
    local vf_list = remove_all_crops(mp.get_property_native("vf", {}) or {})
    local crop_table = get_crop_filter(id, fill_crop_enabled)
    if crop_table then
        crop_table.label = "croptag"
        insert_crop_filter(vf_list, crop_table)
        mp.set_property_native("vf", vf_list)
    end

    if fill_crop_enabled then
        osd.show("nsoretro_crop_fill_on", 2)
    else
        osd.show("nsoretro_crop_fill_off", 2)
    end
end)

mp.observe_property("glsl-shaders", "native", function(_, value)
    if syncing_glsl or bezel_sync_timer then return end

    local current = split_shader_list_native(value or {})
    if lists_equal(current, build_stack(current)) then return end

    if glsl_resync_timer then
        glsl_resync_timer:kill()
        glsl_resync_timer = nil
    end

    glsl_resync_timer = mp.add_timeout(0.05, function()
        glsl_resync_timer = nil
        sync_glsl_stack()
    end)
end)

mp.observe_property("user-data/sdr_to_hdr", "string", function(_, value)
    local now = (value == "yes")
    if now == hdr_active then return end
    hdr_active = now
    if bezel_mode == "legacy" and active_bezel and shield_geom then sync_glsl_stack() end
end)

mp.register_script_message("reapply-vf", function()
    if active_bezel and current_bezel_image then
        apply_bezel(current_bezel_image, current_bezel_id, current_bezel_x, current_bezel_y, current_bezel_w, current_bezel_h)
    elseif active_crop and active_crop ~= "" then
        local id = active_crop
        local vf_list = remove_all_crops(mp.get_property_native("vf", {}) or {})
        local crop_table = get_crop_filter(id, fill_crop_enabled)
        if crop_table then
            crop_table.label = "croptag"
            insert_crop_filter(vf_list, crop_table)
            set_vf_if_changed(vf_list)
        end
    end
end)

local vf_heal_timer = nil

local function vf_has_label(vf_list, label)
    for _, f in ipairs(vf_list or {}) do
        if type(f) == "table" and f.label == label then return true end
    end
    return false
end

mp.observe_property("vf", "native", function()
    if vf_heal_timer then vf_heal_timer:kill() end
    vf_heal_timer = mp.add_timeout(0.5, function()
        vf_heal_timer = nil
        local vf_list = mp.get_property_native("vf", {}) or {}

        if active_bezel and current_bezel_image then
            if bezel_mode == "gpu" then
                local vw, vh = get_video_size()
                if vw ~= gpu_canvas_w or vh ~= gpu_canvas_h then
                    apply_bezel(current_bezel_image, current_bezel_id, current_bezel_x, current_bezel_y, current_bezel_w, current_bezel_h)
                end
            elseif not vf_has_label(vf_list, "bezeltag") then
                apply_bezel(current_bezel_image, current_bezel_id, current_bezel_x, current_bezel_y, current_bezel_w, current_bezel_h)
            end
        elseif active_crop and active_crop ~= "" then
            if not vf_has_label(vf_list, "croptag") then
                local crop_table = get_crop_filter(active_crop, fill_crop_enabled)
                if crop_table then
                    crop_table.label = "croptag"
                    local clean = remove_all_crops(vf_list)
                    insert_crop_filter(clean, crop_table)
                    mp.set_property_native("vf", clean)
                end
            end
        end
    end)
end)

msg.info("[nso_retro] NSO Retro MPV (GPU bezel via overlay-add, CPU bezel as fallback) " .. BEZEL_BUILD)

mp.set_property("user-data/active_bezel", "none")
mp.set_property("user-data/crop-active", "")
mp.set_property("user-data/crop_rect", "")
mp.set_property("user-data/active_shape", "none")
mp.set_property("user-data/bezel_fit", "none")
mp.set_property("user-data/crop_fit", "none")
sync_glsl_stack()