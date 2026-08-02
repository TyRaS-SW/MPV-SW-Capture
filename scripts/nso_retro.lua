-- NSO Retro MPV by TyRaS-SW
-- Fused version: crops + bezels + shield + shapes
-- Dynamic bezel scaling based on output canvas size
-- Shape addons persist across preset/shader changes without warping bezels

local mp = require "mp"

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
-- Shape addons
-- -------------------------------------------------------------------------
local current_lang = "en"

local addons = {
FRM1 = { en = "CRT Curvature", es = "CRT Curvatura", path = "shaders/shapes/crt-curvature-only.glsl" },
FRM2 = { en = "CRT Curvature (Edge Darkening)", es = "CRT Curvatura (Orillas Oscuras)", path = "shaders/shapes/crt-curvature-onlyE.glsl" },
FRM3 = { en = "CRT Wide Barrel", es = "CRT Barril Ancho", path = "shaders/shapes/crt-widebarrel.glsl" },
FRM4 = { en = "CRT Wide Barrel (Edge Darkening)", es = "CRT Barril Ancho (Orillas Oscuras)", path = "shaders/shapes/crt-widebarrelE.glsl" },
FRM5 = { en = "CRT Super Curvature", es = "CRT Super Curvatura", path = "shaders/shapes/crt-supercurvature.glsl" },
FRM6 = { en = "Rounded Corners", es = "Esquinas Redondeadas", path = "shaders/shapes/rounded-corners.glsl" },
FRM7 = { en = "CRT Tilted  (Keystone)", es = "CRT Inclinado (Keystone)", path = "shaders/shapes/tilted-crt.glsl" },
FRM8 = { en = "CRT Tilted  (Keystone Inverted)", es = "CRT Inclinado (Keystone Invertido)", path = "shaders/shapes/tilted-crt_inv.glsl" },
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
return a.es or a.en or "none"
end
return a.en or a.es or "none"
end

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
elseif f.name == "lavfi" and f.params and f.params.graph and f.params.graph:match("^crop=") then
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
-- Scale NSO base coordinates (1920x1080) to current output canvas size.
-- -------------------------------------------------------------------------
local function scale_from_base_1080(px, py, pw, ph)
local vop = mp.get_property_native("video-out-params") or {}
local vw = tonumber(vop.w) or tonumber(vop.dw) or mp.get_property_number("width", 1920)
local vh = tonumber(vop.h) or tonumber(vop.dh) or mp.get_property_number("height", 1080)

local sx = vw / 1920
local sy = vh / 1080

local x1 = math.floor(px * sx)
local y1 = math.floor(py * sy)
local x2 = math.ceil((px + pw) * sx)
local y2 = math.ceil((py + ph) * sy)

if x1 < 0 then x1 = 0 end
if y1 < 0 then y1 = 0 end
if x2 > vw then x2 = vw end
if y2 > vh then y2 = vh end

local sw = x2 - x1
local sh = y2 - y1

if sw < 1 then sw = 1 end
if sh < 1 then sh = 1 end

return x1, y1, sw, sh, vw, vh
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

local vop = mp.get_property_native("video-out-params") or {}
local vw = tonumber(vop.w) or tonumber(vop.dw) or mp.get_property_number("width", 1920)
local vh = tonumber(vop.h) or tonumber(vop.dh) or mp.get_property_number("height", 1080)

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

local previous_bezel = active_bezel
local spx, spy, spw, sph, vw, vh = scale_from_base_1080(px, py, pw, ph)

local inner_x = spx
local inner_y = spy
local inner_w = spw
local inner_h = sph

if inner_x < 0 then inner_x = 0 end
if inner_y < 0 then inner_y = 0 end
if inner_w < 1 then inner_w = 1 end
if inner_h < 1 then inner_h = 1 end

if inner_x + inner_w < vw then
inner_w = inner_w + 1
end

if inner_x + inner_w > vw then
inner_w = vw - inner_x
end

if inner_y + inner_h > vh then
inner_h = vh - inner_y
end

if inner_w < 1 then inner_w = 1 end
if inner_h < 1 then inner_h = 1 end

local my_serial = bezel_apply_serial + 1
bezel_apply_serial = my_serial

active_bezel = bezel_id
mp.set_property("user-data/active_bezel", bezel_id)

local path = mp.command_native({ "expand-path", "~~/bezels/" .. image_file })
path = path:gsub("\\", "/"):gsub(":", "\\:")

local graph_str = string.format(
"movie='%s'[bz];" ..
"[bz][in]scale2ref=iw:ih[bzfull][base];" ..
"[base]crop=%d:%d:%d:%d:exact=1,setsar=1[vidwin];" ..
"[bzfull][vidwin]overlay=%d:%d",
path, inner_w, inner_h, inner_x, inner_y, inner_x, inner_y
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

generate_shader(inner_x, inner_y, inner_w, inner_h)
sync_glsl_stack()

if previous_bezel and previous_bezel ~= bezel_id then
local old_shield = temp_dir .. "/protect_" .. previous_bezel .. ".glsl"
os.remove(old_shield)
end
end)

mp.osd_message(tr("BEZEL: ", "MARCO: ") .. bezel_id, 2)
end

-- -------------------------------------------------------------------------
-- Toggle crop.
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
-- Toggle bezel.
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

mp.register_script_message("clear-bezel", function(silent)
clear_bezel_only()
if not (silent and silent ~= "") then
mp.osd_message(tr("Bezels Cleared", "Marcos Eliminados"), 2)
end
end)

mp.register_script_message("clear-crop", function(silent)
clear_crop_only()
if not (silent and silent ~= "") then
mp.osd_message(tr("Crop Cleared", "Recorte Eliminado"), 2)
end
end)

mp.register_script_message("reapply-bezel-shield", function()
sync_glsl_stack()
if active_bezel then
mp.osd_message("Bezel shield reapplied", 1)
end
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

print("NSO Retro MPV")

mp.set_property("user-data/active_bezel", "none")
mp.set_property("user-data/active_shader", "SH_4K_1")
mp.set_property("user-data/crop-active", "")
mp.set_property("user-data/active_shape", "none")
sync_glsl_stack()
