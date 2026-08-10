-- NSO Retro MPV by TyRaS-SW
-- Fused version: crops + bezels + shield + shapes
-- Dynamic bezel scaling based on current video resolution
-- OSD messages are handled exclusively by menu.conf.
-- active_shader is initialized by shader_init.lua (created by setup).

local mp = require "mp"

local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
temp_dir = temp_dir:gsub("\\", "/")

-- -------------------------------------------------------------------------
-- Crop presets
-- -------------------------------------------------------------------------
local crops = {
    crop1  = { filter = "crop=ih*4/3:ih", title = "NSO N64/GC (4:3)" },
    crop2  = { filter = "crop=1316:1026", title = "NSO NES (4:3/CRT)" },
    crop3  = { filter = "crop=1024:912", title = "NSO NES (Pixel Perfect)" },
    crop4  = { filter = "crop=1316:1008", title = "NSO SNES/GEN (4:3/CRT)" },
    crop5  = { filter = "crop=1152:1008", title = "NSO SNES (Pixel Perfect)" },
    crop6  = { filter = "crop=1120:1008", title = "NSO GameBoy Color" },
    crop7  = { filter = "crop=800:720", title = "NSO GameBoy (Small)" },
    crop8  = { filter = "crop=1440:960", title = "NSO GameBoy Advance" },
    crop9 = { filter = "crop=960:640", title = "NSO GameBoy Advance (Small)" },
    crop10 = { filter = "crop=1280:896", title = "NSO Genesis (Pixel Perfect)" },
    cropsp1  = { filter = "crop=1436:1008", title = "NSO N64 (Mario 64 Size)" },
    cropsp2  = { filter = "crop=1611:983", title = "NSO N64 (DK64 Widescreen Size)" }
}

-- -------------------------------------------------------------------------
-- Shape addons (paths only)
-- -------------------------------------------------------------------------
local shape_paths = {
    FRM1   = "shaders/shapes/crt-curvature-only.glsl",
    FRM2   = "shaders/shapes/crt-curvature-onlyE.glsl",
    FRM3   = "shaders/shapes/crt-widebarrel.glsl",
    FRM4   = "shaders/shapes/crt-widebarrelE.glsl",
    FRM5   = "shaders/shapes/crt-supercurvature.glsl",
    FRM6   = "shaders/shapes/rounded-corners.glsl",
    FRM7   = "shaders/shapes/tilted-crt.glsl",
    FRM8   = "shaders/shapes/tilted-crt_inv.glsl",
    FRM9   = "shaders/shapes/pinball-perspective.glsl",
    FRMO_1 = "shaders/shapes/inward-keystone-bottom.glsl",
}

local active_crop = ""
local active_bezel = nil
local active_shape = "none"
local syncing_glsl = false
local bezel_apply_serial = 0
local bezel_sync_timer = nil
local glsl_resync_timer = nil

-- -------------------------------------------------------------------------
-- Helpers
-- -------------------------------------------------------------------------
local function split_shader_list_native(v)
    if type(v) == "table" then
        local out = {}
        for _, s in ipairs(v) do
            if s and s ~= "" then
                table.insert(out, tostring(s))
            end
        end
        return out
    end

    if not v or v == "" then
        return {}
    end

    local t = {}
    for part in string.gmatch(tostring(v), "([^;]+)") do
        table.insert(t, part)
    end
    return t
end

local function current_shape_path()
    if active_shape ~= "none" and shape_paths[active_shape] then
        return shape_paths[active_shape]
    end
    return nil
end

local function get_shield_path()
    return temp_dir .. "/protect_" .. (active_bezel or "default") .. ".glsl"
end

local function update_shape_property()
    mp.set_property_native("user-data/active_shape", active_shape)
end

local function shader_list_contains(list, wanted)
    if not wanted or wanted == "" then
        return true
    end

    for _, s in ipairs(split_shader_list_native(list or {})) do
        if tostring(s) == wanted then
            return true
        end
    end

    return false
end

local function sync_glsl_stack()
    if syncing_glsl then
        return
    end

    syncing_glsl = true

    local shaders = mp.get_property_native("glsl-shaders", {}) or {}
    local list = split_shader_list_native(shaders)

    local clean = {}
    for _, s in ipairs(list) do
        local str = tostring(s)
        if not str:find("protect_") and not shape_paths[s] then
            table.insert(clean, str)
        end
    end

    local final = {}

    if active_bezel then
        table.insert(final, get_shield_path())
    end

    local shape_path = current_shape_path()
    if shape_path then
        table.insert(final, shape_path)
    end

    for _, s in ipairs(clean) do
        table.insert(final, s)
    end

    mp.set_property_native("glsl-shaders", final)
    update_shape_property()

    syncing_glsl = false
end

-- -------------------------------------------------------------------------
-- Shape controls (no OSD)
-- -------------------------------------------------------------------------
local function toggle_shape(id)
    if not shape_paths[id] and id ~= "none" then
        return
    end

    if active_shape == id then
        active_shape = "none"
    else
        active_shape = id
    end

    sync_glsl_stack()
end

local function clear_shapes()
    active_shape = "none"
    sync_glsl_stack()
end

mp.register_script_message("toggle-addon-shader", toggle_shape)
mp.register_script_message("clear-addon-shaders", clear_shapes)

-- -------------------------------------------------------------------------
-- Convert a crop string into a native vf table.
-- -------------------------------------------------------------------------
local function parse_crop_filter(filter_str)
    local args = filter_str:match("^crop=(.+)$")
    if not args then
        return nil
    end

    local parts = {}
    for p in args:gmatch("[^:]+") do
        table.insert(parts, p)
    end

    local has_expression = false
    for _, p in ipairs(parts) do
        if p:match("[%*%+%-%/a-zA-Z]") then
            has_expression = true
            break
        end
    end

    if has_expression then
        return {
            name = "lavfi",
            params = { graph = "crop=" .. args }
        }
    end

    local w = tonumber(parts[1])
    local h = tonumber(parts[2])
    local x = tonumber(parts[3])
    local y = tonumber(parts[4])

    if w and h then
        local expr = string.format(
            "crop=iw*%d/1920:ih*%d/1080%s%s",
            w,
            h,
            x and string.format(":iw*%d/1920", x) or "",
            y and string.format(":ih*%d/1080", y) or ""
        )

        return {
            name = "lavfi",
            params = { graph = expr }
        }
    end

    return {
        name = "lavfi",
        params = { graph = "crop=" .. args }
    }
end

local function remove_all_crops(vf_list)
    local clean = {}

    for _, f in ipairs(vf_list or {}) do
        local is_crop = false

        if type(f) == "table" then
            if f.name == "crop" then
                is_crop = true
            elseif f.name == "lavfi"
                and f.params
                and f.params.graph
                and f.params.graph:match("^crop=") then
                is_crop = true
            end
        end

        if not is_crop then
            table.insert(clean, f)
        end
    end

    return clean
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

-- -------------------------------------------------------------------------
-- Scale NSO base coordinates (1920x1080) to current video resolution.
-- -------------------------------------------------------------------------
local function scale_from_base_1080(px, py, pw, ph)
    local vw = mp.get_property_number("width", 1920)
    local vh = mp.get_property_number("height", 1080)

    local sx = vw / 1920
    local sy = vh / 1080

    return
        math.floor(px * sx + 0.5),
        math.floor(py * sy + 0.5),
        math.floor(pw * sx + 0.5),
        math.floor(ph * sy + 0.5),
        vw,
        vh
end

local GLSL_TEMPLATE = [[
//!HOOK MAINPRESUB
//!BIND HOOKED
//!SAVE CLEAN_FRAME
//!COMPONENTS 4
vec4 hook() { return HOOKED_texOff(0.0); }

//!HOOK MAINPRESUB
//!BIND HOOKED
//!COMPONENTS 4
vec4 hook() {
vec2 uv = HOOKED_pos;
if (uv.x < %s || uv.x > %s || uv.y < %s || uv.y > %s) {
return vec4(0.0, 0.0, 0.0, 1.0);
}
return HOOKED_texOff(0.0);
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND CLEAN_FRAME
//!COMPONENTS 4
vec4 hook() {
vec2 uv = HOOKED_pos;
if (uv.x < %s || uv.x > %s || uv.y < %s || uv.y > %s) {
return CLEAN_FRAME_tex(uv);
}
return HOOKED_texOff(0.0);
}
]]

local function generate_shader(px, py, pw, ph)
    local shield_path = get_shield_path()

    local vw = mp.get_property_number("width", 1920)
    local vh = mp.get_property_number("height", 1080)

    local x = px / vw
    local y = py / vh
    local w = pw / vw
    local h = ph / vh

    local coords = {
        string.format("%.6f", x):gsub(",", "."),
        string.format("%.6f", x + w):gsub(",", "."),
        string.format("%.6f", y):gsub(",", "."),
        string.format("%.6f", y + h):gsub(",", ".")
    }

    local glsl_code = GLSL_TEMPLATE:format(
        coords[1], coords[2], coords[3], coords[4],
        coords[1], coords[2], coords[3], coords[4]
    )

    local f = io.open(shield_path, "w")
    if f then
        f:write(glsl_code)
        f:close()
    end
end

local function remove_protect_shader()
    local shaders = mp.get_property_native("glsl-shaders", {}) or {}
    local clean = {}

    for _, s in ipairs(shaders) do
        if not tostring(s):find("protect_") then
            table.insert(clean, s)
        end
    end

    mp.set_property_native("glsl-shaders", clean)
end

-- -------------------------------------------------------------------------
-- Bezel / crop clear helpers
-- -------------------------------------------------------------------------
local function clear_bezel_only()
    local vf_list = mp.get_property_native("vf", {}) or {}
    vf_list = remove_bezeltag(vf_list)
    mp.set_property_native("vf", vf_list)

    active_bezel = nil
    mp.set_property("user-data/active_bezel", "none")

    if bezel_sync_timer then
        bezel_sync_timer:kill()
        bezel_sync_timer = nil
    end

    remove_protect_shader()
end

local function clear_crop_only()
    local vf_list = mp.get_property_native("vf", {}) or {}
    vf_list = remove_all_crops(vf_list)
    mp.set_property_native("vf", vf_list)

    active_crop = ""
    mp.set_property("user-data/crop-active", "")
end

-- -------------------------------------------------------------------------
-- Apply or replace bezel overlay.
-- -------------------------------------------------------------------------
local function apply_bezel(image_file, bezel_id, px, py, pw, ph)
    px, py, pw, ph = tonumber(px), tonumber(py), tonumber(pw), tonumber(ph)

    local spx, spy, spw, sph = scale_from_base_1080(px, py, pw, ph)
    local my_serial = bezel_apply_serial + 1
    bezel_apply_serial = my_serial

    active_bezel = bezel_id
    mp.set_property("user-data/active_bezel", bezel_id)

    local path = mp.command_native({ "expand-path", "~~/bezels/" .. image_file })
    path = path:gsub("\\", "/"):gsub(":", "\\:")

    local graph_str = string.format(
        "movie='%s'[bg];[in]crop=%s:%s:%s:%s[vid];[bg][vid]overlay=%s:%s",
        path, spw, sph, spx, spy, spx, spy
    )

    local vf_list = mp.get_property_native("vf", {}) or {}
    vf_list = remove_bezeltag(vf_list)

    table.insert(vf_list, {
        name = "lavfi",
        label = "bezeltag",
        params = { graph = graph_str }
    })

    mp.set_property_native("vf", vf_list)

    if bezel_sync_timer then
        bezel_sync_timer:kill()
        bezel_sync_timer = nil
    end

    bezel_sync_timer = mp.add_timeout(0.05, function()
        if my_serial ~= bezel_apply_serial then
            return
        end

        generate_shader(spx, spy, spw, sph)
        sync_glsl_stack()
    end)
end

-- -------------------------------------------------------------------------
-- Toggle crop.
-- -------------------------------------------------------------------------
local function toggle_crop(id)
    if active_bezel then
        clear_bezel_only()
    end

    local vf_list = mp.get_property_native("vf", {}) or {}
    vf_list = remove_all_crops(vf_list)

    if active_crop == id then
        mp.set_property_native("vf", vf_list)
        active_crop = ""
        mp.set_property("user-data/crop-active", "")
        return
    end

    local crop_table = parse_crop_filter(crops[id].filter)
    if crop_table then
        table.insert(vf_list, 1, crop_table)
        mp.set_property_native("vf", vf_list)
    else
        mp.commandv("vf", "add", crops[id].filter)
    end

    active_crop = id
    mp.set_property("user-data/crop-active", id)
end

for id, _ in pairs(crops) do
    mp.add_key_binding(nil, id, function()
        toggle_crop(id)
    end)
end

-- -------------------------------------------------------------------------
-- Toggle bezel.
-- -------------------------------------------------------------------------
mp.register_script_message("toggle-bezel", function(image_file, bezel_id, px, py, pw, ph)
    if active_bezel == bezel_id then
        clear_bezel_only()
        return
    end

    if active_crop ~= "" then
        clear_crop_only()
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

-- -------------------------------------------------------------------------
-- Watch shader list changes and restore shield + active shape order.
-- -------------------------------------------------------------------------
mp.observe_property("glsl-shaders", "native", function(_, value)
    if syncing_glsl then
        return
    end

    local need_resync = false
    local shader_list = split_shader_list_native(value or {})

    if active_bezel and not shader_list_contains(shader_list, get_shield_path()) then
        need_resync = true
    end

    local shape_path = current_shape_path()
    if shape_path and not shader_list_contains(shader_list, shape_path) then
        need_resync = true
    end

    if need_resync then
        if glsl_resync_timer then
            glsl_resync_timer:kill()
            glsl_resync_timer = nil
        end

        glsl_resync_timer = mp.add_timeout(0.05, function()
            glsl_resync_timer = nil
            sync_glsl_stack()
        end)
    end
end)

print("NSO Retro MPV (OSD-free, no shader init)")

-- -------------------------------------------------------------------------
-- Initialize shared state properties
-- Note: active_shader is now initialized by shader_init.lua (created by setup)
-- -------------------------------------------------------------------------
mp.set_property("user-data/active_bezel", "none")
mp.set_property("user-data/crop-active", "")
mp.set_property("user-data/active_shape", "none")
sync_glsl_stack()