-- NSO Retro MPV by TyRaS-SW
-- OLD bezel-resolution pipeline + ORIGIN simplified shapes/OSD behavior.
--
-- Fixed: transition from crop to bezel no longer deforms the image.
-- Now all crops are cleared before applying a bezel, and coordinates are
-- calculated based on the original video size, not the canvas.

local mp = require "mp"

-- -------------------------------------------------------------------------
-- Cargar osd_messages con dofile (usa la ruta del script actual)
-- -------------------------------------------------------------------------
local osd
local function get_script_path()
    local info = debug.getinfo(1, "S")
    return info and info.source:match("@?(.*/)") or ""
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
    -- Fallback: mensajes en inglés
    osd = {
        get = function(key)
            local defaults = {
                no_bezel = "Select a bezel first.",
                fill_on  = "Fit Full 16:9 to Bezel: ON",
                fill_off = "Fit Full 16:9 to Bezel: OFF",
                reset    = "Bezel Fit: Reset",
            }
            return defaults[key] or key
        end,
        show = function(key, duration)
            local text = osd.get(key)
            local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
            if osd_duration_ms == 0 then return end
            if duration == nil then duration = osd_duration_ms / 1000 end
            mp.osd_message(text, duration)
        end,
        safe_osd_message = function(text, duration)
            local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
            if osd_duration_ms == 0 then return end
            if duration == nil then duration = osd_duration_ms / 1000 end
            mp.osd_message(text, duration)
        end
    }
    print("nso_retro: Using fallback messages (osd_messages.lua not loaded).")
    print("Error: " .. tostring(err))
    print("Looked for: " .. osd_path)
else
    print("nso_retro: osd_messages.lua loaded successfully from: " .. osd_path)
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

local current_bezel_image = nil
local current_bezel_id = nil
local current_bezel_x = nil
local current_bezel_y = nil
local current_bezel_w = nil
local current_bezel_h = nil

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

local function get_shield_path()
return temp_dir .. "/protect_" .. (active_bezel or "default") .. ".glsl"
end

local function update_shape_property()
mp.set_property_native("user-data/active_shape", active_shape)
end

local function shader_list_contains(list, wanted)
if not wanted or wanted == "" then return true end
for _, s in ipairs(split_shader_list_native(list or {})) do
if tostring(s) == tostring(wanted) then return true end
end
return false
end

local function sync_glsl_stack()
if syncing_glsl then return end
syncing_glsl = true

local shaders = mp.get_property_native("glsl-shaders", {}) or {}
local list = split_shader_list_native(shaders)
local clean = {}

for _, s in ipairs(list) do
local str = tostring(s)
if not str:find("protect_") and not path_is_shape(str) then
table.insert(clean, str)
end
end

local final = {}
if active_bezel then table.insert(final, get_shield_path()) end

local shape_path = current_shape_path()
if shape_path then table.insert(final, shape_path) end

for _, s in ipairs(clean) do table.insert(final, s) end

mp.set_property_native("glsl-shaders", final)
update_shape_property()
syncing_glsl = false
end

-- -------------------------------------------------------------------------
-- ORIGIN silent shape controls
-- -------------------------------------------------------------------------
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

local function remove_all_crops(vf_list)
local clean = {}

for _, f in ipairs(vf_list or {}) do
local is_crop = false
if type(f) == "table" then
if f.name == "crop" then
is_crop = true
elseif f.name == "lavfi" and f.params and f.params.graph
and f.params.graph:match("^crop=") then
is_crop = true
end
end
if not is_crop then table.insert(clean, f) end
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
-- Get video size (not canvas)
-- -------------------------------------------------------------------------
local function get_video_size()
    local vw = mp.get_property_number("video-params/w") or 1920
    local vh = mp.get_property_number("video-params/h") or 1080
    if vw <= 0 then vw = 1920 end
    if vh <= 0 then vh = 1080 end
    return math.max(1, vw), math.max(1, vh)
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

    -- Keep video strictly inside bezel opening
    if (x2 - x1) > 1 then
        x2 = x2 - 1
    end

    return x1, y1, x2 - x1, y2 - y1, vw, vh
end

-- -------------------------------------------------------------------------
-- Shield shader
-- -------------------------------------------------------------------------
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
    local vw, vh = get_video_size()

    local x  = px / vw
    local y  = py / vh
    local w  = (pw - 1) / vw
    local h  = ph / vh

    local coords = {
        string.format("%.6f", x):gsub(",", "."),
        string.format("%.6f", x + w):gsub(",", "."),
        string.format("%.6f", y):gsub(",", "."),
        string.format("%.6f", y + h):gsub(",", ".")
    }

    local code = GLSL_TEMPLATE:format(
        coords[1], coords[2], coords[3], coords[4],
        coords[1], coords[2], coords[3], coords[4]
    )

    local f = io.open(shield_path, "w")
    if f then f:write(code); f:close() end
end

local function remove_protect_shader()
local shaders = mp.get_property_native("glsl-shaders", {}) or {}
local clean = {}
for _, s in ipairs(shaders) do
if not tostring(s):find("protect_") then table.insert(clean, s) end
end
mp.set_property_native("glsl-shaders", clean)
end

-- -------------------------------------------------------------------------
-- Bezel and crop clear helpers
-- -------------------------------------------------------------------------
local function clear_bezel_only()
local vf_list = remove_bezeltag(mp.get_property_native("vf", {}) or {})
mp.set_property_native("vf", vf_list)

active_bezel = nil
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
end

local function clear_crop_only()
local vf_list = remove_all_crops(mp.get_property_native("vf", {}) or {})
mp.set_property_native("vf", vf_list)

active_crop = ""
mp.set_property("user-data/crop-active", "")
end

-- -------------------------------------------------------------------------
-- Apply bezel (clears all crops and previous bezels first)
-- -------------------------------------------------------------------------
local function apply_bezel(image_file, bezel_id, px, py, pw, ph)
px, py, pw, ph = tonumber(px), tonumber(py), tonumber(pw), tonumber(ph)
if not px or not py or not pw or not ph then return end

-- Remember the exact bezel selected by the user.
current_bezel_image = image_file
current_bezel_id = bezel_id
current_bezel_x = px
current_bezel_y = py
current_bezel_w = pw
current_bezel_h = ph

local previous_bezel = active_bezel

-- ============================================================
--  FIX: Remove ALL crops and bezels before applying new bezel
-- ============================================================
local vf_list = mp.get_property_native("vf", {}) or {}
vf_list = remove_bezeltag(remove_all_crops(vf_list))

-- Now compute inner window coordinates based on clean video
local inner_x, inner_y, inner_w, inner_h, vw, vh = scale_from_base_1080(px, py, pw, ph)

-- Geometry-based right-edge inset:
local right_base = px + pw
local right_margin = 1920 - right_base
if right_margin >= 280 and right_margin <= 320 and inner_w > 1 then
    inner_w = inner_w - 1
end

local serial = bezel_apply_serial + 1
bezel_apply_serial = serial

active_bezel = bezel_id
active_crop = ""  -- Reset crop state
mp.set_property("user-data/active_bezel", bezel_id)
mp.set_property("user-data/crop-active", "")

local path = mp.command_native({ "expand-path", "~~/bezels/" .. image_file })
if not path then return end

path = path:gsub("\\", "/"):gsub(":", "\\:")

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

mp.set_property_native("vf", vf_list)

if bezel_sync_timer then
bezel_sync_timer:kill()
bezel_sync_timer = nil
end

bezel_sync_timer = mp.add_timeout(0.05, function()
if serial ~= bezel_apply_serial then return end

generate_shader(inner_x, inner_y, inner_w, inner_h)
sync_glsl_stack()

if previous_bezel and previous_bezel ~= bezel_id then
os.remove(temp_dir .. "/protect_" .. previous_bezel .. ".glsl")
end
end)
end

-- -------------------------------------------------------------------------
-- Crop controls
-- -------------------------------------------------------------------------
local function toggle_crop(id)
if active_bezel then clear_bezel_only() end

local vf_list = remove_all_crops(mp.get_property_native("vf", {}) or {})
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
mp.add_key_binding(nil, id, function() toggle_crop(id) end)
end

-- -------------------------------------------------------------------------
-- Bezel controls
-- -------------------------------------------------------------------------
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

-- -------------------------------------------------------------------------
-- Restore shield and active-shape order after shader changes
-- -------------------------------------------------------------------------
mp.observe_property("glsl-shaders", "native", function(_, value)
if syncing_glsl then return end

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

print("NSO Retro MPV (OLD resolution + ORIGIN silent OSD/shapes)")

mp.set_property("user-data/active_bezel", "none")
mp.set_property("user-data/crop-active", "")
mp.set_property("user-data/active_shape", "none")
mp.set_property("user-data/bezel_fit", "none")
sync_glsl_stack()