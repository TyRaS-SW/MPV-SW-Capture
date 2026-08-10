-- shader_init.lua by TyRaS-SW - Initialization of shader and OSD control
local current_lang = "en"

-- Initialize active shader
mp.set_property("user-data/active_shader", "SH_4K_1")

-- Variable para rastrear si la ventana de Info Stream está visible
local stats_visible = false

-- ============================================================
-- FUNCIÓN: toggle OSD (mostrar/ocultar mensajes)
-- ============================================================
local function toggle_osd()
    local dur = mp.get_property_number("osd-duration")
    if dur == 0 then
        -- Activar modo normal (mostrar OSD)
        mp.set_property_number("osd-duration", 1000)
        if current_lang == "es" then
            mp.osd_message("✅Mostrar OSD y ✅Grabación Activada", 2.0, 0)
        else
            mp.osd_message("✅OSD Show Mode and ✅Record Enabled", 2.0, 0)
        end
    else
        -- Activar modo oculto (ocultar OSD)
        mp.set_property_number("osd-duration", 0)

        -- Si Info Stream está visible, cerrarlo automáticamente
        if stats_visible then
            mp.commandv("script-binding", "stats/display-page-1-toggle")
            stats_visible = false
        end

        if current_lang == "es" then
            mp.osd_message("🙈Ocultar OSD y 🔒Grabación Desactivada", 2.0, 0)
        else
            mp.osd_message("🙈OSD Hidden Mode and 🔒Record Disabled", 2.0, 0)
        end
    end
end

mp.register_script_message("toggle-osd", toggle_osd)

-- ============================================================
-- FUNCIÓN: Info Stream (bloqueado en modo oculto)
-- ============================================================
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