local current_lang = "en"
-- mirror_toggle.lua - For MPV-SW-Capture - By TyRaS-SW
-- Toggle mirror effect with OSD, language support, and menu tick
local mp = require "mp"

-- -------------------------------------------------------------------------
-- Cargar osd_messages de forma segura (con dofile y ruta del script)
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
    -- Fallback: funciones básicas sin traducción
    osd = {
        get = function(key) return key end,
        show = function(key, duration)
            local text = key
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
    print("mirror_toggle: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("mirror_toggle: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- Funciones de filtro
-- -------------------------------------------------------------------------
local function get_vf_list()
    return mp.get_property_native("vf", {})
end

local function set_vf_list(list)
    mp.set_property_native("vf", list)
end

local function has_hflip(list)
    for _, f in ipairs(list) do
        if type(f) == "table" and f.name == "hflip" then
            return true
        end
    end
    return false
end

-- -------------------------------------------------------------------------
-- Actualizar user-data para el menú
-- -------------------------------------------------------------------------
local function update_mirror_user_data()
    local vf_list = get_vf_list()
    local active = has_hflip(vf_list)
    mp.set_property("user-data/mirror_active", tostring(active))
    return active
end

-- -------------------------------------------------------------------------
-- Toggle mirror usando osd.show() para mensajes
-- -------------------------------------------------------------------------
local function toggle_mirror()
    print("mirror_toggle: toggle_mirror called")
    local vf_list = get_vf_list()
    local hflip_present = has_hflip(vf_list)

    if hflip_present then
        -- Eliminar hflip
        local new_list = {}
        for _, f in ipairs(vf_list) do
            if not (type(f) == "table" and f.name == "hflip") then
                table.insert(new_list, f)
            end
        end
        set_vf_list(new_list)
        osd.show("mirrortoggle_off", 1.5)
        print("mirror_toggle: Mirror OFF")
    else
        -- Insertar hflip al principio
        local new_list = { { name = "hflip" } }
        for _, f in ipairs(vf_list) do
            table.insert(new_list, f)
        end
        set_vf_list(new_list)
        osd.show("mirrortoggle_on", 1.5)
        print("mirror_toggle: Mirror ON")
    end

    update_mirror_user_data()
end

-- -------------------------------------------------------------------------
-- Observar cambios en vf para mantener user-data sincronizado
-- -------------------------------------------------------------------------
mp.observe_property("vf", "native", function()
    update_mirror_user_data()
end)

-- -------------------------------------------------------------------------
-- Inicializar
-- -------------------------------------------------------------------------
update_mirror_user_data()

-- Registrar script-message para integración con menú
mp.register_script_message("toggle-mirror", toggle_mirror)

-- Atajo de teclado opcional (tecla M)
mp.add_key_binding("m", "toggle-mirror", toggle_mirror)

print("mirror_toggle: Script loaded successfully")