-- osd_messages.lua
-- Universal OSD messages for MPV scripts
-- Language code read from lang/OSDLang.dat
-- Messages loaded from lang/OSDMSG_<lang>.dat (fallback to en)

local mp = require "mp"

-- -------------------------------------------------------------------------
-- Obtener directorio del script actual
-- -------------------------------------------------------------------------
local function get_script_dir()
    local info = debug.getinfo(1, "S")
    local path = info and info.source:match("^@?(.*)$") or ""
    local dir = path:match("^(.*)[/\\][^/\\]+$") or ""
    if dir ~= "" then
        if not dir:match("[/\\]$") then
            dir = dir .. "/"
        end
    end
    return dir
end

local script_dir = get_script_dir()
local lang_dir = script_dir .. "lang/"
local lang_file = lang_dir .. "OSDLang.dat"

-- -------------------------------------------------------------------------
-- Leer idioma desde OSDLang.dat (fallback "en")
-- -------------------------------------------------------------------------
local function read_lang_from_file()
    local f = io.open(lang_file, "r")
    if not f then return "en" end
    local content = f:read("*all")
    f:close()
    -- Eliminar BOM (EF BB BF) si existe, luego espacios y saltos de línea
    content = content:gsub("^\xef\xbb\xbf", ""):gsub("%s+", "")
    if content == "" then return "en" end
    return content
end

-- -------------------------------------------------------------------------
-- Cargar mensajes desde el archivo OSDMSG_<lang>.dat
-- -------------------------------------------------------------------------
local function load_messages(lang)
    local msg_file = lang_dir .. "OSDMSG_" .. lang .. ".dat"
    local msgs = {}
    local f = io.open(msg_file, "r")
    if f then
        for line in f:lines() do
            local key, val = line:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if key and val then
                msgs[key] = val
            end
        end
        f:close()
    end
    return msgs
end

-- Carga inicial: leer idioma y cargar mensajes (con fallback a "en")
local current_lang = read_lang_from_file()
local messages = load_messages(current_lang)
if not next(messages) then
    messages = load_messages("en")
    if not next(messages) then
        messages = {}
    end
end

-- -------------------------------------------------------------------------
-- Obtener mensaje por clave
-- -------------------------------------------------------------------------
function get(key)
    return messages[key] or key
end

-- -------------------------------------------------------------------------
-- Mostrar mensaje OSD con respeto a osd-duration
-- -------------------------------------------------------------------------
function show(key, duration)
    local text = get(key)
    local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
    if osd_duration_ms == 0 then return end
    if duration == nil then duration = osd_duration_ms / 1000 end
    mp.osd_message(text, duration)
end

-- -------------------------------------------------------------------------
-- Función directa para mostrar texto sin clave
-- -------------------------------------------------------------------------
function safe_osd_message(text, duration)
    local osd_duration_ms = mp.get_property_number("osd-duration") or 1000
    if osd_duration_ms == 0 then return end
    if duration == nil then duration = osd_duration_ms / 1000 end
    mp.osd_message(text, duration)
end

-- -------------------------------------------------------------------------
-- Función para que otros scripts puedan obtener el idioma actual
-- -------------------------------------------------------------------------
function get_lang()
    return current_lang
end

-- -------------------------------------------------------------------------
-- Recargar idioma y mensajes (llamado desde el overlay al cambiar idioma)
-- -------------------------------------------------------------------------
local function reload_messages()
    current_lang = read_lang_from_file()
    messages = load_messages(current_lang)
    if not next(messages) then
        messages = load_messages("en")
        if not next(messages) then
            messages = {}
        end
    end
end

-- Escuchar el aviso del overlay
mp.register_script_message("reload-osd-messages", reload_messages)

-- -------------------------------------------------------------------------
-- Exportar
-- -------------------------------------------------------------------------
return {
    get = get,
    show = show,
    safe_osd_message = safe_osd_message,
    get_lang = get_lang,
    reload = reload_messages,
}