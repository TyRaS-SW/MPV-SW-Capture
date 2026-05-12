-- NSO Retro MPV by TyRaS-SW
-- Fused version: crops + bezels + shield + shapes
-- Dynamic bezel scaling based on current video resolution
-- Shape addons persist across preset/shader changes without warping bezels

local mp = require "mp"

local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
temp_dir = temp_dir:gsub("\\", "/")

-- -------------------------------------------------------------------------
-- Crop presets
-- -------------------------------------------------------------------------
local crops = {
    crop1  = { filter = "crop=ih*4/3:ih", title = "NSO N64/GC (4:3)" },
    crop2  = { filter = "crop=1436:1008", title = "NSO N64 (Mario 64 Size)" },
    crop3  = { filter = "crop=1316:1026", title = "NSO NES (4:3/CRT)" },
    crop4  = { filter = "crop=1024:912", title = "NSO NES (Pixel Perfect)" },
    crop5  = { filter = "crop=1316:1008", title = "NSO SNES/GEN (4:3/CRT)" },
    crop6  = { filter = "crop=1152:1008", title = "NSO SNES (Pixel Perfect)" },
    crop7  = { filter = "crop=1120:1008", title = "NSO GameBoy Color" },
    crop8  = { filter = "crop=800:720", title = "NSO GameBoy (Small)" },
    crop9  = { filter = "crop=1440:960", title = "NSO GameBoy Advance" },
    crop10 = { filter = "crop=960:640", title = "NSO GameBoy Advance (Small)" },
    crop11 = { filter = "crop=1280:896", title = "NSO Genesis (Pixel Perfect)" }
}

-- -------------------------------------------------------------------------
-- Shape addons
-- -------------------------------------------------------------------------
local current_lang = "en"

local addons = {
FRM1 = { en = "CRT Curvature", es = "Curvatura CRT", path = "shaders/shapes/crt-curvature-only.glsl" },
FRM2 = { en = "CRT Curvature (Edge Darkening)", es = "Curvatura CRT (Oscurecer Bordes)", path = "shaders/shapes/crt-curvature-onlyE.glsl" },
FRM3 = { en = "Wide CRT Barrel", es = "CRT Barril Ancho", path = "shaders/shapes/crt-widebarrel.glsl" },
FRM4 = { en = "Wide CRT Barrel (Edge Darkening)", es = "CRT Barril Ancho (Oscurecer Bordes)", path = "shaders/shapes/crt-widebarrelE.glsl" },
FRM5 = { en = "CRT Super Curvature", es = "Super Curvatura CRT", path = "shaders/shapes/crt-supercurvature.glsl" },
FRM6 = { en = "Rounded Corners", es = "Esquinas Redondeadas", path = "shaders/shapes/rounded-corners.glsl" },
FRM7 = { en = "Tilted CRT (Keystone)", es = "CRT Inclinado (Keystone)", path = "shaders/shapes/tilted-crt.glsl" },
FRM8 = { en = "Tilted CRT (Keystone Inverted)", es = "CRT Inclinado (Keystone Invertido)", path = "shaders/shapes/tilted-crt_inv.glsl" },
FRM9 = { en = "Pinball Perspective", es = "Perspectiva Pinball", path = "shaders/shapes/pinball-perspective.glsl" },
FRMO_1 = { en = "Inward Keystone (Low Bottom Zoom)", es = "Keystone hacia adentro (Zoom inferior bajo)", path = "shaders/shapes/inward-keystone-bottom.glsl" },
}

local function set_language(lang)
if lang == "es" then
    current_lang = "es"
else
    current_lang = "en"
end
mp.set_property("user-data/osd_lang", current_lang)
end

local function tr(en_text, es_text)
if current_lang == "es" then
    return es_text
end
return en_text
end

local function addon_label(id)
local a = addons[id]
if not a then
    return "none"
end
if current_lang == "es" then
    return a.es
end
return a.en
end

local active_crop = ""
local active_bezel = nil
local active_shape = "none"
local syncing_glsl = false

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

local function path_in_addons(path)
for _, info in pairs(addons) do
if info.path == path then
return true
end
end
return false
end

local function current_shape_path()
if active_shape ~= "none" and addons[active_shape] then
return addons[active_shape].path
end
return nil
end

local function get_shield_path()
return temp_dir .. "/protect_" .. (active_bezel or "default") .. ".glsl"
end

local function update_shape_property()
mp.set_property_native("user-data/active_shape", active_shape)
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
if not str:find("protect_") and not path_in_addons(str) then
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
-- Shape controls
-- -------------------------------------------------------------------------
local function set_language(lang)
if lang == "es" then
current_lang = "es"
else
current_lang = "en"
end
mp.set_property("user-data/osd_lang", current_lang)
end

local function tr(en_text, es_text)
if current_lang == "es" then
return es_text
end
return en_text
end

local function addon_label(id)
local a = addons[id]
if not a then
return "none"
end
if current_lang == "es" then
return a.es or a.en or "none"
end
return a.en or a.es or "none"
end

local function toggle_shape(id)
if not addons[id] and id ~= "none" then
mp.osd_message(tr("Unknown Shape: ", "Forma desconocida: ") .. tostring(id))
return
end

if active_shape == id then
active_shape = "none"
mp.osd_message(tr("Shape OFF", "Forma DESACTIVADA"))
else
active_shape = id
mp.osd_message(tr("Shape ON: ", "Forma ACTIVADA: ") .. addon_label(id))
end

sync_glsl_stack()
end

local function clear_shapes(silent)
active_shape = "none"
sync_glsl_stack()
if silent ~= "silent" then
mp.osd_message(tr("Shape Cleared", "Forma Limpiada"))
end
end

mp.register_script_message("set-addon-language", set_language)
mp.register_script_message("toggle-addon-shader", toggle_shape)
mp.register_script_message("clear-addon-shaders", clear_shapes)

-- -------------------------------------------------------------------------
-- Convert a crop string into a native vf table.
-- Use lavfi when the crop contains expressions such as ih*4/3.
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

-- -------------------------------------------------------------------------
-- Remove every crop filter from the current vf list.
-- -------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------
-- Remove the bezel overlay filter from vf by label.
-- -------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------
-- Write shield shader using normalized coordinates.
-- -------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------
-- Remove shield shader only.
-- -------------------------------------------------------------------------
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

    remove_protect_shader()
    sync_glsl_stack()
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

    active_bezel = bezel_id
    mp.set_property("user-data/active_bezel", bezel_id)

    generate_shader(spx, spy, spw, sph)
    sync_glsl_stack()

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
    mp.osd_message(tr("BEZEL: ", "MARCO: ") .. bezel_id, 2)
end

-- -------------------------------------------------------------------------
-- Toggle crop.
-- Crops and bezels are mutually exclusive by design.
-- -------------------------------------------------------------------------
local function toggle_crop(id)
    local title = crops[id].title

    if active_bezel then
        clear_bezel_only()
    end

    local vf_list = mp.get_property_native("vf", {}) or {}
    vf_list = remove_all_crops(vf_list)

    if active_crop == id then
        mp.set_property_native("vf", vf_list)
        active_crop = ""
        mp.set_property("user-data/crop-active", "")
        mp.osd_message(title .. tr(" OFF", " DESACTIVADO"), 2)
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
    mp.osd_message(title .. tr(" ON", " ACTIVADO"), 2)
end

for id, _ in pairs(crops) do
    mp.add_key_binding(nil, id, function()
        toggle_crop(id)
    end)
end

-- -------------------------------------------------------------------------
-- Shape controls
-- -------------------------------------------------------------------------
local function toggle_shape(id)
if not addons[id] and id ~= "none" then
mp.osd_message(tr("Unknown Shape: ", "Forma desconocida: ") .. tostring(id))
return
end

if active_shape == id then
active_shape = "none"
mp.osd_message(tr("Shape OFF", "Forma DESACTIVADA"))
else
active_shape = id
mp.osd_message(tr("Shape ON: ", "Forma ACTIVADA: ") .. addon_label(id))
end

sync_glsl_stack()
end

local function clear_shapes(silent)
active_shape = "none"
sync_glsl_stack()
if silent ~= "silent" then
mp.osd_message(tr("Shape Cleared", "Forma Limpiada"))
end
end

mp.register_script_message("set-addon-language", set_language)
mp.register_script_message("toggle-addon-shader", toggle_shape)
mp.register_script_message("clear-addon-shaders", clear_shapes)

-- -------------------------------------------------------------------------
-- Toggle bezel.
-- Bezels and crops are mutually exclusive by design.
-- -------------------------------------------------------------------------
mp.register_script_message("toggle-bezel", function(image_file, bezel_id, px, py, pw, ph)
    if active_bezel == bezel_id then
        clear_bezel_only()
        mp.osd_message(tr("Bezel Cleared", "Marco Eliminado"), 2)
        return
    end

    if active_crop ~= "" then
        clear_crop_only()
    end

    apply_bezel(image_file, bezel_id, px, py, pw, ph)
end)

-- -------------------------------------------------------------------------
-- Clear bezel only.
-- -------------------------------------------------------------------------
mp.register_script_message("clear-bezel", function(silent)
    clear_bezel_only()
    if not (silent and silent ~= "") then
        mp.osd_message(tr("Bezels Cleared", "Marcos Eliminados"), 2)
    end
end)

-- -------------------------------------------------------------------------
-- Clear crop only.
-- -------------------------------------------------------------------------
mp.register_script_message("clear-crop", function(silent)
    clear_crop_only()
    if not (silent and silent ~= "") then
        mp.osd_message(tr("Crop Cleared", "Recorte Eliminado"), 2)
    end
end)

-- -------------------------------------------------------------------------
-- Manual helper to rebuild shader order.
-- -------------------------------------------------------------------------
mp.register_script_message("reapply-bezel-shield", function()
    sync_glsl_stack()
    if active_bezel then
        mp.osd_message("Bezel shield reapplied", 1)
    end
end)

-- -------------------------------------------------------------------------
-- Watch shader list changes and restore shield + active shape order.
-- -------------------------------------------------------------------------
mp.observe_property("glsl-shaders", "native", function()
    if syncing_glsl then
        return
    end

    if active_bezel or active_shape ~= "none" then
        mp.add_timeout(0.01, function()
            sync_glsl_stack()
        end)
    end
end)

print("NSO Retro MPV")

-- -------------------------------------------------------------------------
-- Initialize shared state properties
-- -------------------------------------------------------------------------
mp.set_property("user-data/active_bezel", "none")
mp.set_property("user-data/active_shader", "SH_4K_1")
mp.set_property("user-data/crop-active", "")
mp.set_property("user-data/active_shape", "none")
sync_glsl_stack()