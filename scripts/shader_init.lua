local current_lang = "en"
-- shader_init.lua by TyRaS-SW - Initialization of shader and OSD control

local mp = require "mp"

-- -------------------------------------------------------------------------
-- Cargar osd_messages de forma segura
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
    if loaded and type(loaded.get) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get function")
    end
end)

if not ok then
    -- Fallback: función get básica
    osd = {
        get = function(key) return key end
    }
    print("shader_init: Using fallback OSD (osd_messages.lua not loaded). Error: " .. tostring(err))
else
    print("shader_init: osd_messages.lua loaded from " .. osd_path)
end

-- -------------------------------------------------------------------------
-- Inicializar shader activo
-- -------------------------------------------------------------------------
mp.set_property("user-data/active_shader", "SH_4K_1")

-- Variable para rastrear si la ventana de Info Stream está visible
local stats_visible = false

-- -------------------------------------------------------------------------
-- FUNCIÓN: toggle OSD (mostrar/ocultar mensajes)
-- -------------------------------------------------------------------------
local function toggle_osd()
    local dur = mp.get_property_number("osd-duration")
    if dur == 0 then
        -- Activar modo normal (mostrar OSD)
        mp.set_property_number("osd-duration", 1000)
        local msg_text = osd.get("shaderinit_osd_on")
        mp.osd_message(msg_text, 2.0)
    else
        -- Activar modo oculto (ocultar OSD)
        mp.set_property_number("osd-duration", 0)

        -- Si Info Stream está visible, cerrarlo automáticamente
        if stats_visible then
            mp.commandv("script-binding", "stats/display-page-1-toggle")
            stats_visible = false
        end

        local msg_text = osd.get("shaderinit_osd_off")
        mp.osd_message(msg_text, 2.0)
    end
end

mp.register_script_message("toggle-osd", toggle_osd)

-- -------------------------------------------------------------------------
-- FUNCIÓN: Info Stream (bloqueado en modo oculto)
-- -------------------------------------------------------------------------
local function toggle_stats()
    local dur = mp.get_property_number("osd-duration")

    -- Si está en modo oculto, no permitir abrir Info Stream
    if dur == 0 then
        -- Si por algún motivo está visible (caso raro), lo cerramos
        if stats_visible then
            mp.commandv("script-binding", "stats/display-page-1-toggle")
            stats_visible = false
        end
        return
    end

    -- Modo normal: alternar Info Stream
    mp.commandv("script-binding", "stats/display-page-1-toggle")
    stats_visible = not stats_visible
end

mp.register_script_message("toggle-stats", toggle_stats)