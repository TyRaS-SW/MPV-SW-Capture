-- NSO Retro MPV by TyRaS-SW
local mp = require 'mp'

local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
temp_dir = temp_dir:gsub("\\\\", "/")

-- ===== CROPS =====
local crops = {
crop1 = { filter = "crop=ih*4/3:ih", title = "NSO N64/GC (4:3)" },
crop2 = { filter = "crop=1436:1008", title = "NSO N64 (Mario 64 Size)" },
crop3 = { filter = "crop=1316:1026", title = "NSO NES (4:3/CRT)" },
crop4 = { filter = "crop=1024:912", title = "NSO NES (Pixel Perfect)" },
crop5 = { filter = "crop=1316:1008", title = "NSO SNES/GEN (4:3/CRT)" },
crop6 = { filter = "crop=1152:1008", title = "NSO SNES (Pixel Perfect)" },
crop7 = { filter = "crop=1120:1008", title = "NSO GameBoy Color" },
crop8 = { filter = "crop=800:720", title = "NSO GameBoy (Small)" },
crop9 = { filter = "crop=1440:960", title = "NSO GameBoy Advance" },
crop10 = { filter = "crop=960:640", title = "NSO GameBoy Advance (Small)" },
crop11 = { filter = "crop=1280:896", title = "NSO Genesis (Pixel Perfect)" }
}

local active_crop = ""
local active_bezel = nil

local function toggle_crop(id)
local bezel_status = mp.get_property("user-data/active_bezel", "none")
if bezel_status ~= "none" then
mp.set_property("user-data/active_bezel", "none")
mp.set_property("vf", "")
local shaders = mp.get_property_native("glsl-shaders", {})
for i = #shaders, 1, -1 do
if tostring(shaders[i]):find("protect") then
table.remove(shaders, i)
end
end
mp.set_property_native("glsl-shaders", shaders)
mp.commandv("video-redraw")
active_bezel = nil
end

local title = crops[id].title
if active_crop == id then
mp.set_property("vf", "")
active_crop = ""
mp.set_property("user-data/crop-active", "")
mp.osd_message(title .. " OFF", 2)
else
mp.set_property("vf", crops[id].filter)
active_crop = id
mp.set_property("user-data/crop-active", id)
mp.osd_message(title .. " ON", 2)
end
mp.commandv("script-message menu-refresh")
end

for id, _ in pairs(crops) do
mp.add_key_binding(nil, id, function() toggle_crop(id) end)
end

-- ===== HYBRID BEZELS (SINGLE FILE + VISIBLE PNG) =====
local guard = false
local cache_coords = {}

local function get_shield_path()
return temp_dir .. "/protect_" .. (active_bezel or "default") .. ".glsl"
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

local function ensure_shield_first()
if guard or not active_bezel then return end
guard = true
local shaders = mp.get_property_native("glsl-shaders", {})
for i = #shaders, 1, -1 do
if tostring(shaders[i]):find("protect") then
table.remove(shaders, i)
end
end
table.insert(shaders, 1, get_shield_path())
mp.set_property_native("glsl-shaders", shaders)
mp.commandv("video-redraw")
guard = false
end

mp.observe_property("glsl-shaders", "native", function(_, shaders)
if active_bezel then ensure_shield_first() end
end)

local function generate_shader(px, py, pw, ph)
local shield_path = get_shield_path()
local x, y, w, h = px/1920, py/1080, pw/1920, ph/1080
cache_coords = {
string.format("%.3f", x):gsub(",", "."),
string.format("%.3f", x + w):gsub(",", "."),
string.format("%.3f", y):gsub(",", "."),
string.format("%.3f", y + h):gsub(",", ".")
}
local glsl_code = GLSL_TEMPLATE:format(
cache_coords[1], cache_coords[2], cache_coords[3], cache_coords[4],
cache_coords[1], cache_coords[2], cache_coords[3], cache_coords[4])
local f = io.open(shield_path, "w")
if f then f:write(glsl_code); f:close() end
end

local function clear_bezel()
active_crop = ""
mp.set_property("user-data/crop-active", "")
mp.set_property("vf", "")
active_bezel = nil
local vf_list = mp.get_property_native("vf", {})
for i = #vf_list, 1, -1 do
if vf_list[i].label == "bezeltag" then table.remove(vf_list, i); break end
end
mp.set_property_native("vf", vf_list)
local shaders = mp.get_property_native("glsl-shaders", {})
for i = #shaders, 1, -1 do
if tostring(shaders[i]):find("protect") then table.remove(shaders, i) end
end
mp.set_property_native("glsl-shaders", shaders)
mp.set_property("user-data/active_bezel", "none")
mp.commandv("video-redraw")
mp.commandv("script-message menu-refresh")
end

local function enable_bezel_synced(image_file, bezel_id, px, py, pw, ph)
active_bezel = bezel_id
generate_shader(tonumber(px), tonumber(py), tonumber(pw), tonumber(ph))
ensure_shield_first()
mp.add_timeout(0.033, function()
local path = mp.command_native({"expand-path", "~~/bezels/" .. image_file})
path = path:gsub("\\\\", "/"):gsub(":", "\\:")
-- PNG VISIBLE + ANTI-SHADOWS
local graph_str = string.format(
"movie='%s'[bg];[in]crop=%s:%s:%s:%s[vid];[bg][vid]overlay=%s:%s",
path, pw, ph, px, py, px, py)
local vf_list = mp.get_property_native("vf", {})
for i = #vf_list, 1, -1 do
if vf_list[i].label == "bezeltag" then table.remove(vf_list, i); break end
end
table.insert(vf_list, {name="lavfi", label="bezeltag", params={graph=graph_str}})
mp.set_property_native("vf", vf_list)
mp.set_property("user-data/active_bezel", bezel_id)
mp.osd_message("BEZELS: " .. bezel_id, 2)
end)
end

mp.register_script_message("toggle-bezel", function(image_file, bezel_id, px, py, pw, ph)
local w = mp.get_property_number("width", 0)
local h = mp.get_property_number("height", 0)
if w ~= 1920 or h ~= 1080 then
mp.osd_message("Error: Video 1920x1080 required", 4)
return
end
if active_bezel == bezel_id then
clear_bezel()
else
clear_bezel()
mp.add_timeout(0.033, function()
enable_bezel_synced(image_file, bezel_id, px, py, pw, ph)
end)
end
mp.commandv("script-message menu-refresh")
end)

print("NSO Retro MPV")

mp.register_script_message("clear-bezel", function()
clear_bezel()
mp.osd_message("Bezels Cleared", 2)
end)

-- Initialize user-data property on script load
mp.set_property("user-data/active_bezel", "none")
mp.set_property("user-data/active_shader", "SH1")
mp.set_property("user-data/crop-active", "")