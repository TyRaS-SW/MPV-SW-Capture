-- msc_overlay.lua - For MPV-SW-Capture - By TyRaS-SW
-- MPV-SW-Capture dynamic overlay
-- Based on an initial alpha design concept by supremeuefn.
-- Localization via OSDLang.dat + ASMENU_<lang>.dat + MENUMSG_<lang>.dat
-- menu.conf is read as-is; labels translated in memory.
-- Root sections loaded from scripts/sections.dat (fallback to defaults).

local mp = require "mp"
local msg = require "mp.msg"
local assdraw = require "mp.assdraw"

local C = {
    panel     = "221A14", edge = "44362B",
    active    = "33271D", card = "2C221A", cardedge = "4F4033",
    track     = "382C22", hi = "F8F5F2", text = "D4C5B7",
    dim       = "AB9682", faint = "86705D", accent = "524BFF",
    blue      = "FF9E4A", green = "7FD035",
    amber     = "41A4D9",
    btn_yellow = "41A4D9",  -- ASS BGR: warm amber (RGB D9A441)
    btn_hover  = "008CFF",  -- ASS BGR: dark orange (RGB FF8C00)
    btn_black  = "000000",  -- black text on buttons
}
local RW, RH = 1280, 720
local P = { x = 140, y = 64, w = 1000, h = 592 }
local SW, HH, RHROW, BOOST = 232, 64, 32, 400
local visible, section, cursor, scroll = false, 1, 1, 0
local tabs = {}
local bound, drag, timer = false, nil, nil
local root, device = nil, ""
local app_version = "vUnknown"
local hover_close, hover_quit, hover_clean, hover_reload = false, false, false, false
local hover_screenshot, hover_record, hover_lang = false, false, false
local audio = { volume = nil, boost = 100, muted = false, pending = false, version = 0 }
local hit = {}
local ov = mp.create_osd_overlay("ass-events")
local sx, sy = 1, 1
local hide_timer = nil
local audio_refreshed = false
local boost_debounce = nil      -- timer for debounced boost send
local volume_debounce = nil     -- timer for debounced volume send

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function reset_hit()
    hit = { panel = nil, side = {}, rows = {}, tabs = {}, cards = {},
            close = nil, quit = nil, clean = nil, reload = nil,
            screenshot = nil, record = nil, lang = nil }
end
reset_hit()

local function getroot()
    if root then return root end
    root = (mp.get_property("config-path") or "."):gsub("\\", "/")
    return root
end

local function osd(s)
    if (mp.get_property_number("osd-duration") or 1000) > 0 then
        mp.osd_message(s, 1.2)
    end
end

local function cmd(s)
    return function() mp.command(s) end
end

-- ------------------------------------------------------------
-- Localization (T)
-- ------------------------------------------------------------
local function keyof(s)
    local out = {}
    s = s or ""
    for i = 1, #s do
        local b = s:byte(i)
        if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or (b >= 48 and b <= 57) or b == 32 then
            out[#out + 1] = string.char(b)
        end
    end
    return table.concat(out):gsub("^%s+", ""):gsub("%s+$", ""):lower()
end

local AS, MM, MM_SORTED = {}, {}, {}
local T_cache = {}

local function current_lang_code()
    local f = io.open(getroot() .. "/scripts/lang/OSDLang.dat", "r")
    if not f then return "en" end
    local s = (f:read("*a") or "")
    s = s:gsub("^\239\187\191", "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    f:close()
    if s == "" then return "en" end
    return s
end

local function load_kv(path)
    local d = {}
    local f = io.open(path, "r")
    if not f then return d end
    for line in f:lines() do
        local clean = line:gsub("^\239\187\191", "")
        if not clean:match("^%s*#") and not clean:match("^%s*$") then
            local k, v = clean:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if k and v and k ~= "" then d[k] = v end
        end
    end
    f:close()
    return d
end

local function esc_pat(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

local function rebuild_dicts()
    local lang = current_lang_code()
    local base = getroot() .. "/scripts/lang/"

    AS = load_kv(base .. "ASMENU_" .. lang .. ".dat")
    local as_en = load_kv(base .. "ASMENU_en.dat")
    for k, v in pairs(as_en) do if AS[k] == nil then AS[k] = v end end

    MM = load_kv(base .. "MENUMSG_" .. lang .. ".dat")
    local mm_en = load_kv(base .. "MENUMSG_en.dat")
    for k, v in pairs(mm_en) do if MM[k] == nil then MM[k] = v end end

    MM_SORTED = {}
    for k, v in pairs(MM) do MM_SORTED[#MM_SORTED + 1] = { k, v } end
    table.sort(MM_SORTED, function(a, b) return #a[1] > #b[1] end)

    T_cache = {}
end

local function T(s)
    if not s or s == "" then return s end
    local cached = T_cache[s]
    if cached then return cached end

    local as = AS[s] or AS[keyof(s)]
    if as then T_cache[s] = as; return as end

    local r = s
    for _, p in ipairs(MM_SORTED) do
        if r:find(p[1], 1, true) then
            r = r:gsub(esc_pat(p[1]), p[2])
        end
    end
    T_cache[s] = r
    return r
end

-- Translate the content inside double quotes only (safe for commands)
local function T_command(s)
    if not s or s == "" then return s end
    return (s:gsub('"([^"]*)"', function(inner)
        if inner == "" then return '""' end
        return '"' .. T(inner) .. '"'
    end))
end

rebuild_dicts()

-- ------------------------------------------------------------
-- Available languages (read from scripts/lang/language_list.dat)
-- ------------------------------------------------------------
local AVAILABLE_LANGS = {}

local function load_languages()
    local defaults = { "en", "es" }
    local f = io.open(getroot() .. "/scripts/lang/language_list.dat", "r")
    if not f then
        msg.warn("MSC overlay: language_list.dat not found, using defaults")
        return defaults
    end
    local langs = {}
    for line in f:lines() do
        local clean = line:gsub("^\239\187\191", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" and not clean:match("^#") then
            langs[#langs + 1] = clean
        end
    end
    f:close()
    if #langs == 0 then
        msg.warn("MSC overlay: language_list.dat empty, using defaults")
        return defaults
    end
    msg.info("MSC overlay: loaded " .. #langs .. " languages from language_list.dat")
    return langs
end

AVAILABLE_LANGS = load_languages()

-- Returns the next language in the cycle after `current`.
-- If `current` is not in the list, returns the first one.
local function next_language(current)
    if #AVAILABLE_LANGS == 0 then return "en" end
    for i, l in ipairs(AVAILABLE_LANGS) do
        if l == current then
            local next_i = (i % #AVAILABLE_LANGS) + 1
            return AVAILABLE_LANGS[next_i]
        end
    end
    return AVAILABLE_LANGS[1]
end

-- ------------------------------------------------------------
-- Audio / external
-- ------------------------------------------------------------
local function device_refresh()
    local ok, d = pcall(dofile, getroot() .. "/scripts/usb3.lua")
    device = (ok and type(d) == "table" and tostring(d.video_device or "")) or ""
    if not ok then
        msg.warn("MSC overlay: cannot load scripts/usb3.lua: " .. tostring(d))
    end
end

local function refresh_app_version()
    app_version = "vUnknown"
    local f = io.open(getroot() .. "/mpv.conf", "rb")
    if not f then return end
    for _ = 1, 40 do
        local line = f:read("*l")
        if not line then break end
        local version = line:match("^%s*#%s*[vV]([%d]+[%d%.%-_A-Za-z]*)%s*$")
        if version then
            app_version = "v" .. version
            break
        end
    end
    f:close()
end

local function num(s)
    if not s or s:match("EXCEPTION") or s:match("ERROR") then return nil end
    local out
    for line in s:gmatch("[^\r\n]+") do
        local n = line:match("^%s*(%d+)%s*$")
        if n then out = tonumber(n) end
    end
    return out
end

local function ps(rel, args, cb)
    local a = { "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", getroot() .. "/" .. rel }
    for _, v in ipairs(args or {}) do a[#a + 1] = v end
    mp.command_native_async({
        name = "subprocess",
        args = a,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    }, function(ok, r)
        if cb then cb(ok, r) end
    end)
end

-- `attempt` is internal: when the first call comes back empty (ffplay not
-- running yet), retry every 500ms up to 8 times (4 seconds total).
local function audio_refresh(attempt)
    attempt = attempt or 1
    audio.version = audio.version + 1
    local current_version = audio.version
    audio.pending = true
    ps("data/ffplayvol.ps1", { "get", "ffplay" }, function(ok, r)
        if current_version ~= audio.version then return end
        local n = ok and r and num(r.stdout)
        if not n and attempt < 8 and visible then
            mp.add_timeout(0.5, function()
                if visible then audio_refresh(attempt + 1) end
            end)
            return
        end
        if n then audio.volume = n end
        ps("data/ffplayboost.ps1", { "get" }, function(ok2, r2)
            if current_version ~= audio.version then return end
            local b = ok2 and r2 and num(r2.stdout)
            if b then audio.boost = b end
            audio.pending = false
            if visible then render() end
        end)
    end)
end

-- Debounced senders: collapse rapid changes into a single PowerShell call.
-- Prevents parallel ffplay restart storms when the user drags fast.
local function schedule_volume_send(value)
    if volume_debounce then volume_debounce:kill(); volume_debounce = nil end
    volume_debounce = mp.add_timeout(0.4, function()
        volume_debounce = nil
        ps("data/ffplayvol.ps1", { "set", "ffplay", tostring(value) })
    end)
end

local function schedule_boost_send(value)
    if boost_debounce then boost_debounce:kill(); boost_debounce = nil end
    boost_debounce = mp.add_timeout(0.5, function()
        boost_debounce = nil
        ps("data/ffplayboost.ps1", { "set", tostring(value) })
    end)
end

local function volset(v)
    if type(v) ~= "number" then return end
    v = math.floor(math.max(0, math.min(100, v)) + 0.5)
    audio.volume = v
    if visible then render() end
    schedule_volume_send(v)
end

local function boostset(v)
    if type(v) ~= "number" then return end
    v = math.max(100, math.min(BOOST, v))
    if v == audio.boost then return end
    audio.boost = v
    if visible then render() end
    schedule_boost_send(v)
end

local function mute()
    ps("data/ffplayvol.ps1", { "togglemute", "ffplay" }, function(ok, r)
        if ok and r then
            audio.muted = not (r.stdout or ""):match("unmuted")
        end
        if visible then render() end
    end)
end

-- ------------------------------------------------------------
-- Clean All
-- ------------------------------------------------------------
local function cleanall()
    mp.commandv("script-message", "clear-bezel", "silent")
    mp.commandv("script-message", "clear-crop", "silent")
    mp.commandv("script-message", "clear-addon-shaders", "silent")
    mp.commandv("vf", "set", "")
    mp.commandv("change-list", "glsl-shaders", "clr", "")
    mp.set_property("deband", "no")
    mp.set_property("user-data/active_shader", "none")
    mp.set_property("user-data/active_shape", "none")
    mp.set_property("window-scale", 1.0)               -- Size 1.0x
    mp.set_property("video-rotate", 0)                 -- Restore Rotation
    mp.set_property("geometry", "50%:50%")             -- CENTER Position
    mp.set_property("border", "no")                    -- Remove ALL: border off
    mp.set_property("title-bar", "no")                 -- Remove ALL: title-bar off
    mp.set_property("ontop", "no")                     -- Always On Top: OFF
    mp.set_property("video-aspect-override", "16:9")   -- Stretch Window: 16:9
    osd(T("CLEAN ALL"))
end

-- ------------------------------------------------------------
-- menu.conf parsing
-- ------------------------------------------------------------
local function labelof(s)
    s = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local first = s:find("[%a%d]")
    return first and s:sub(first):gsub("^%s+", "") or s
end

local function checked(s)
    if not s then return nil end
    local p, v = s:match('get%(%s*"([^"]+)"%s*%)%s*==%s*(.-)%s*$')
    if not p then return nil end
    return p, (v:match('^"(.*)"$') or v)
end

local function canon(v)
    -- Guard against nil AND boolean false. The old version used
    -- `tostring(v or "")`, which turned boolean false into "" and
    -- broke every `==false` check (e.g. Fill Screen).
    if v == nil then return "" end
    if type(v) == "boolean" then
        return v and "yes" or "no"
    end
    v = tostring(v)
    if v == "true" or v == "yes" then return "yes" end
    if v == "false" or v == "no" then return "no" end
    local a, b = v:match("^(%d+%.?%d*):(%d+%.?%d*)$")
    if a then return string.format("%.6g", tonumber(a) / tonumber(b)) end
    local n = tonumber(v)
    return n and string.format("%.6g", n) or v
end

local function check_matches(entry)
    if not entry or not entry.check_property then return false end
    if entry.is_clear then return false end
    local actual = mp.get_property_native(entry.check_property)
    if actual == nil then actual = mp.get_property(entry.check_property) end
    return canon(actual) == canon(entry.check_expected)
end

local function item(body, indent)
    local f = {}
    for q in body:gmatch("[^\t]+") do
        f[#f + 1] = q:gsub("^%s+", ""):gsub("%s+$", "")
    end
    local raw = f[1] or ""
    local lbl = labelof(raw)
    local lbl_lower = lbl:lower()
    local is_clear = lbl_lower:find("clear", 1, true) ~= nil
                  or lbl_lower:find("clean", 1, true) ~= nil
                  or lbl_lower:find("remove all", 1, true) ~= nil
    local x = {
        raw = raw,
        label = T(lbl),
        label_en = lbl,
        is_clear = is_clear,
        key = keyof(raw),
        indent = indent,
        command = nil,
        disabled = false,
        children = {},
    }
    for i = 2, #f do
        if f[i]:sub(1, 8) == "checked=" then
            x.check = f[i]:sub(9)
        elseif f[i]:sub(1, 9) == "disabled=" then
            x.disabled = f[i]:sub(10) == "true"
        elseif not x.command then
            x.command = T_command(f[i])
        end
    end
    return x
end

-- ------------------------------------------------------------
-- Root sections (externalized to scripts/sections.dat)
-- ------------------------------------------------------------
local ROOTS = {}

local function load_roots()
    local defaults = {
        shaders = "grid", shapes = "grid", crops = "grid", bezels = "grid",
        window = "grid", capture = "grid", ["video options"] = "grid",
        audio = "grid", others = "grid",
    }
    local f = io.open(getroot() .. "/scripts/sections.dat", "r")
    if not f then
        msg.warn("MSC overlay: sections.dat not found, using defaults")
        return defaults
    end
    local roots, count = {}, 0
    for line in f:lines() do
        local clean = line:gsub("^\239\187\191", ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean ~= "" and not clean:match("^#") then
            local key, layout = clean:match("^(.-)%s*=%s*([%a%-]+)$")
            if not key then
                key = clean
                layout = "grid"
            end
            layout = layout:lower()
            if layout ~= "grid" and layout ~= "list" and layout ~= "toggle-grid" then
                layout = "grid"
            end
            roots[keyof(key)] = layout
            count = count + 1
        end
    end
    f:close()
    if count == 0 then
        msg.warn("MSC overlay: sections.dat empty, using defaults")
        return defaults
    end
    msg.info("MSC overlay: loaded " .. count .. " sections from sections.dat")
    return roots
end

ROOTS = load_roots()

local function loadconf()
    local tries = {}
    local opt = mp.get_opt and mp.get_opt("menu-conf")
    if opt and opt ~= "" then tries[#tries + 1] = opt end
    if mp.find_config_file then
        local p = mp.find_config_file("menu.conf")
        if p then tries[#tries + 1] = p end
    end
    tries[#tries + 1] = getroot() .. "/menu.conf"
    for _, p in ipairs(tries) do
        if not p:match("^%a:[/\\]") then p = getroot() .. "/" .. p end
        local f = io.open(p, "rb")
        if f then
            local s = f:read("*a")
            f:close()
            if s and #s > 0 then
                msg.info("MSC overlay: menu.conf loaded: " .. p)
                return s
            end
        end
    end
    msg.error("MSC overlay: menu.conf not found")
    return nil
end

local function parseconf()
    local s = loadconf()
    if not s then return {} end
    local out, cur = {}, nil
    for line in s:gmatch("[^\r\n]+") do
        if not line:match("^%s*$") then
            local body = line:gsub("^[ \t]+", "")
            local lead = line:sub(1, #line - #body)
            local ind = 0
            for i = 1, #lead do
                ind = ind + (lead:sub(i, i) == "\t" and 4 or 1)
            end
            local x = item(body, ind)
            if ind == 0 and not x.command and ROOTS[x.key] then
                cur = { name = x.raw, key = x.key, items = {} }
                out[#out + 1] = cur
            elseif cur then
                cur.items[#cur.items + 1] = x
            end
        end
    end
    return out
end

local function hierarchy(items)
    local rootnode = { indent = -1, children = {} }
    local st = { rootnode }
    for _, x in ipairs(items) do
        while #st > 1 and x.indent <= st[#st].indent do
            table.remove(st)
        end
        st[#st].children[#st[#st].children + 1] = x
        if not x.command then
            st[#st + 1] = x
        end
    end
    return rootnode.children
end

-- Commands that should close the overlay immediately after running
-- (no auto-reopen after 3s -- the user is capturing, not tweaking).
local function is_close_after_command(c)
    if not c then return false end
    local lower = c:lower()
    if lower == "screenshot" or lower:match("^screenshot%s") then
        return true
    end
    if lower:find("autocompress", 1, true) and lower:find("toggle%-record") then
        return true
    end
    if lower:find("toggle%-stats") then
        return true
    end
    return false
end

-- Commands that change the audio boost value. After running one,
-- hide the menu and auto-reopen it so the slider reflects the new value.
local function is_boost_command(c)
    if not c then return false end
    return c:find("ffplayboost", 1, true) ~= nil
end

local function card(x, state)
    if x.disabled or not x.command then return nil end
    local property, expected = checked(x.check)
    if property and not state.prop then state.prop = property end
    local display_value = nil
    if property then
        local normalized = canon(expected)
        if tostring(expected):find("&&", 1, true) then
            display_value = "OFF"
        elseif normalized == "yes" then
            display_value = "ON"
        elseif normalized == "no" then
            display_value = "OFF"
        else
            display_value = normalized
        end
    end
    return {
        label = x.label,
        label_en = x.label_en or x.label,
        is_clear = x.is_clear or false,
        sub = display_value,
        id = property and canon(expected) or nil,
        check_property = property,
        check_expected = expected,
        run = cmd(x.command),
        close_after = is_close_after_command(x.command),
        is_boost = is_boost_command(x.command),
    }
end

local function collect(xs, into, state)
    for _, x in ipairs(xs or {}) do
        if x.command then
            local c = card(x, state)
            if c then into[#into + 1] = c end
        end
        if #x.children > 0 then collect(x.children, into, state) end
    end
end

local function bezel_tabs(xs)
    local groups, all, cur, state = {}, {}, nil, { prop = nil }
    for _, x in ipairs(xs) do
        if x.disabled and not x.command then
            cur = { name = x.label, cards = {} }
            groups[#groups + 1] = cur
        elseif x.command then
            local p, v = checked(x.check)
            local clear = p and (canon(v) == "none" or v == "")
            local target = (clear or not cur) and all or cur.cards
            local c = card(x, state)
            if c then target[#target + 1] = c end
        end
    end
    local out = {}
    if #all > 0 then out[#out + 1] = { name = T("All"), cards = all } end
    for _, g in ipairs(groups) do
        if #g.cards > 0 then out[#out + 1] = g end
    end
    return out, state.prop
end

local function window_tabs(xs)
    local WG = {
        { "size", T("SIZE") },
        { "position", T("POSITION") },
        { "rotation", T("ROTATION") },
        { "other options", T("OTHER OPTIONS") },
        { "window extras", T("WINDOW EXTRAS") },
    }
    local g, order = {}, {}
    for _, z in ipairs(WG) do
        g[z[1]] = { name = z[2], cards = {} }
        order[#order + 1] = z[1]
    end
    local cur, state = nil, { prop = nil }
    local function walk(x)
        local k = x.key
        if g[k] then
            cur = g[k]
        elseif k == "always on top" or k == "stretch window" or k == "mini mode" then
            cur = g["window extras"]
            local c = card(x, state)
            if c then cur.cards[#cur.cards + 1] = c end
        elseif x.command and cur then
            local c = card(x, state)
            if c then cur.cards[#cur.cards + 1] = c end
        end
        for _, q in ipairs(x.children) do walk(q) end
    end
    for _, x in ipairs(xs) do walk(x) end
    local out = {}
    for _, k in ipairs(order) do
        if #g[k].cards > 0 then out[#out + 1] = g[k] end
    end
    return out, state.prop
end

local function generic_tabs(xs)
    local out, flat, state = {}, {}, { prop = nil }
    for _, x in ipairs(xs) do
        if not x.command and #x.children > 0 then
            local cs = {}
            collect(x.children, cs, state)
            if #cs > 0 then out[#out + 1] = { name = x.label, cards = cs } end
        elseif x.command then
            flat[#flat + 1] = x
        end
    end
    if #flat > 0 then
        local cs = {}
        collect(flat, cs, state)
        if #cs > 0 then table.insert(out, 1, { name = T("All"), cards = cs }) end
    end
    return out, state.prop
end

local function list_rows(xs, state)
    local out = {}
    state = state or { prop = nil }
    for _, x in ipairs(xs) do
        if x.command and not x.disabled then
            local c = card(x, state)
            if c then
                out[#out + 1] = {
                    label = c.label,
                    label_en = c.label_en,
                    is_clear = c.is_clear,
                    kind = "action",
                    run = c.run,
                    id = c.id,
                    check_property = c.check_property,
                    check_expected = c.check_expected,
                }
            end
        elseif x.label ~= "" then
            out[#out + 1] = { label = x.label, kind = "head" }
        end
        if #x.children > 0 then
            local sub = list_rows(x.children, state)
            for _, r in ipairs(sub) do out[#out + 1] = r end
        end
    end
    return out
end

-- ------------------------------------------------------------
-- Section model
-- ------------------------------------------------------------
local SECTIONS = {}

-- Forward declaration: build_quick_section captures this as an upvalue.
-- Without it, the reference inside the IIFE resolves to a nil global.
local toggle_language

local function quickcard(en_label, run, sub_en, close_after, icon)
    return {
        label = T(en_label),
        sub = T(sub_en or "Quick"),
        id = en_label,
        run = run,
        close_after = close_after or false,
        icon = icon,           -- optional: emoji shown instead of the LCD icon
    }
end

local function build_quick_section()
    local m = {
        name = "\u{26A1}\u{FE0F} " .. T("Quick"),   -- ⚡️ emoji presentation
        key_en = "quick",
        layout = "quick",
        flat = true,   -- render all tabs at once, grouped by visual header
        tabs = {
            {
                name = T("CAPTURE"),
                cards = {
                    quickcard("Take Screenshot", cmd("screenshot"), nil, true,
                              "\u{1F4F8}"),                    -- 📸 camera with flash
                    quickcard("Record Video", function()
                        mp.commandv("script-message-to", "autocompress", "toggle-record")
                    end, nil, true,
                              "\u{1F3A5}"),                    -- 🎥 movie camera
                    quickcard("Clean ALL", cleanall, nil, false,
                              "\u{1F9F9}"),                    -- 🧹 broom
                },
            },
            {
                name = T("HELP"),
                cards = {
                    quickcard("Check Latest MSC Version",
                              cmd("script-message check-version"), "Help", false,
                              "\u{1F504}"),                    -- 🔄 refresh
                    quickcard("Open MPV-SW-Capture Website",
                        cmd('run cmd /c start "" "https://tyras-sw.github.io/MPV-SW-Capture/"'),
                              "Help", false,
                              "\u{1F3E0}"),                    -- 🏠 home
                    quickcard("MPV-SW-Capture Discord",
                        cmd("run explorer https://discord.gg/PaVutUUK9U"),
                              "Help", false,
                              "\u{1F4AC}"),                    -- 💬 speech balloon
                    quickcard("Hide OSD Messages",
                              cmd("script-message toggle-osd"), "Help", false,
                              "\u{1F648}"),            -- 🙈 monkey covering itself
                    quickcard("Info Stream",
                              cmd("script-message toggle-stats"), "Help", true,
                              "\u{2139}\u{FE0F}"),             -- ℹ️ info
                },
            },
            {
                name = T("SETTINGS"),
                cards = {
                    (function()
                        local cur = current_lang_code()
                        local target = next_language(cur)
                        return quickcard("Switch Language", toggle_language,
                                         "-> " .. target:upper(), false,
                                         "\u{1F310}")           -- 🌐 globe
                    end)(),
                },
            },
        },
    }
    -- Flat list of all cards, used for cursor navigation
    m.flat_cards = {}
    for _, t in ipairs(m.tabs) do
        for _, q in ipairs(t.cards) do
            m.flat_cards[#m.flat_cards + 1] = q
        end
    end
    return m
end

local function rebuild_sections()
    local new = {}
    new[1] = build_quick_section()

    for _, d in ipairs(parseconf()) do
        d.items = hierarchy(d.items)
        local tabs2, prop
        if d.key == "bezels" then
            tabs2, prop = bezel_tabs(d.items)
        elseif d.key == "window" then
            tabs2, prop = window_tabs(d.items)
        else
            tabs2, prop = generic_tabs(d.items)
        end
        local m
        local root_layout = ROOTS[d.key] or "grid"
        local use_grid = (root_layout ~= "list")
        if #tabs2 > 0 and use_grid then
            m = { name = T(d.name), key_en = d.key, layout = "grid", tabs = tabs2 }
            local n = 0
            for _, g in ipairs(tabs2) do n = n + #g.cards end
            m.badge = function() return tostring(n) end
        else
            local st = { prop = nil }
            local r = list_rows(d.items, st)
            prop = prop or st.prop
            m = { name = T(d.name), key_en = d.key, rows = function() return r end }
            local n = 0
            for _, q in ipairs(r) do if q.kind ~= "head" then n = n + 1 end end
            m.badge = function() return tostring(n) end
        end
        if d.key == "audio" then
            local audio_tabs, audio_prop = generic_tabs(d.items)
            m = {
                name = T(d.name),
                key_en = d.key,
                layout = "grid",
                tabs = audio_tabs,
                badge = function()
                    local n = 0
                    for _, g in ipairs(audio_tabs) do n = n + #g.cards end
                    return tostring(n)
                end,
            }
            if audio_prop then
                local p = audio_prop
                m.active = function() return canon(mp.get_property(p)) end
            end
        end
        if prop and d.key ~= "audio" then
            local p = prop
            m.active = function() return canon(mp.get_property(p)) end
        end
        new[#new + 1] = m
    end

    SECTIONS = new
end

-- ------------------------------------------------------------
-- Language switcher (used by a Quick card)
-- Defined BEFORE rebuild_sections() because build_quick_section()
-- references toggle_language at construction time.
-- ------------------------------------------------------------
local function set_language_and_reload(new_lang)
    local path = getroot() .. "/scripts/lang/OSDLang.dat"
    local f = io.open(path, "w")
    if not f then
        msg.warn("MSC overlay: cannot write " .. path)
        return
    end
    f:write(new_lang)
    f:close()

    rebuild_dicts()
    AVAILABLE_LANGS = load_languages()
    ROOTS = load_roots()
    rebuild_sections()
    tabs = {}

    -- Notify other scripts to reload their language resources
    mp.command("script-message reload-osd-messages")

    if section > #SECTIONS then section = 1 end
    cursor = 1
    render()
end

function toggle_language()
    local cur = current_lang_code()
    local target = next_language(cur)
    set_language_and_reload(target)
end

rebuild_sections()

-- ------------------------------------------------------------
-- Auto-hide
-- ------------------------------------------------------------
local function is_auto_hide_section(s)
    local k = s and s.key_en or ""
    return k == "shaders" or k == "shapes" or k == "crops" or k == "bezels"
end

local function cancel_hide_timer()
    if hide_timer then
        hide_timer:kill()
        hide_timer = nil
    end
end

local function schedule_show(delay)
    cancel_hide_timer()
    hide_timer = mp.add_timeout(delay, function()
        hide_timer = nil
        if not visible then show() end
    end)
end

local function trigger_auto_hide(force)
    local s = SECTIONS[section]
    if force or is_auto_hide_section(s) then
        cancel_hide_timer()
        if visible then
            hide()
            schedule_show(3.0)
        end
    end
end

-- ------------------------------------------------------------
-- Drawing helpers
-- ------------------------------------------------------------
local function rect(a, x, y, w, h, colour, alpha)
    a:new_event()
    a:append(string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H%s&\\1a&H%02X&}", colour, alpha or 0))
    a:draw_start()
    a:rect_cw(x, y, x + w, y + h)
    a:draw_stop()
end

local function text(a, x, y, s, colour, size, bold, align)
    a:new_event()
    a:append(string.format(
        "{\\pos(%.1f,%.1f)\\an%d\\bord0\\shad0\\1c&H%s&\\fs%.1f\\b%d\\fnSegoe UI}",
        x, y, align or 4, colour, size, bold and 1 or 0))
    a:append(tostring(s):gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"))
end

local function cross(a, x, y, r, t, colour)
    local st = string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H%s&}", colour)
    a:new_event()
    a:append(st)
    a:draw_start()
    a:move_to(x - r, y - r + t)
    a:line_to(x - r + t, y - r)
    a:line_to(x + r, y + r - t)
    a:line_to(x + r - t, y + r)
    a:draw_stop()
    a:new_event()
    a:append(st)
    a:draw_start()
    a:move_to(x - r, y + r - t)
    a:line_to(x - r + t, y + r)
    a:line_to(x + r, y - r + t)
    a:line_to(x + r - t, y - r)
    a:draw_stop()
end

local function check_icon(a, x, y, size, colour)
    local t = math.max(1.4 * sx, size * 0.12)
    local x1 = x - size * 0.48
    local y1 = y + size * 0.02
    local x2 = x - size * 0.12
    local y2 = y + size * 0.34
    local x3 = x + size * 0.52
    local y3 = y - size * 0.42
    -- \pos(0,0) anchors the drawing to absolute coordinates. Without it,
    -- libass may offset the icon (this was why checkmarks looked low).
    local style = string.format("{\\pos(0,0)\\bord0\\shad0\\c&H%s&}", colour)
    a:new_event()
    a:append(style)
    a:draw_start()
    a:move_to(x1, y1)
    a:line_to(x1 + t, y1 - t)
    a:line_to(x2, y2 - t)
    a:line_to(x3, y3 + t)
    a:line_to(x3 + t, y3 + t * 2)
    a:line_to(x2, y2 + t)
    a:line_to(x1 - t, y1 + t)
    a:draw_stop()
end

local function lcd_icon(a, x, y, on)
    local c = on and C.accent or C.faint
    local w = 24 * sx
    local h = 16 * sy
    rect(a, x - w / 2, y - h / 2, w, h, c, 0x70)
    rect(a, x - w / 2 + 2 * sx, y - h / 2 + 2 * sy, w - 4 * sx, h - 4 * sy, C.track, 0x18)
    rect(a, x - 5 * sx, y + h / 2 + 2 * sy, 10 * sx, 2 * sy, c, 0x40)
end

-- Draw the card icon. If the card has a custom `icon` (emoji), draw it;
-- otherwise, fall back to the default LCD icon.
local function draw_card_icon(a, x, y, q, on, sel)
    if q and q.icon then
        local c = (on or sel) and C.hi or C.text
        text(a, x, y, q.icon, c, 28 * sx, false, 5)
    else
        lcd_icon(a, x, y, on)
    end
end

local function video_icon(a, x, y, colour)
    local size = 8 * sx
    local st = string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H%s&}", colour)
    a:new_event()
    a:append(st)
    a:draw_start()
    a:move_to(x - size, y - size)
    a:line_to(x - size, y + size)
    a:line_to(x + size, y)
    a:draw_stop()
end

local function trash_icon(a, x, y, colour)
    local st = string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H%s&}", colour)
    a:new_event()
    a:append(st)
    a:draw_start()
    local w = 12 * sx
    local h = 14 * sy
    a:move_to(x - w / 2, y + h / 2)
    a:line_to(x + w / 2, y + h / 2)
    a:line_to(x + w / 2 - 2 * sx, y - h / 2 + 2 * sy)
    a:line_to(x - w / 2 + 2 * sx, y - h / 2 + 2 * sy)
    a:draw_stop()
    a:new_event()
    a:append(st)
    a:draw_start()
    a:move_to(x - w / 2 - 2 * sx, y - h / 2)
    a:line_to(x + w / 2 + 2 * sx, y - h / 2)
    a:draw_stop()
    a:new_event()
    a:append(st)
    a:draw_start()
    a:move_to(x - 4 * sx, y - h / 2)
    a:line_to(x - 4 * sx, y - h / 2 - 3 * sy)
    a:line_to(x + 4 * sx, y - h / 2 - 3 * sy)
    a:line_to(x + 4 * sx, y - h / 2)
    a:draw_stop()
end

-- ------------------------------------------------------------
-- Text truncation
-- ------------------------------------------------------------
local function truncate_text(str, max_width, font_size)
    local approx_char_width = font_size * 0.35
    local max_chars = math.floor(max_width / approx_char_width)
    if max_chars < 1 then max_chars = 1 end
    if #str > max_chars then
        return str:sub(1, max_chars - 3) .. "..."
    end
    return str
end

-- ------------------------------------------------------------
-- Effective gain helper (used by both Quick and Audio sliders)
-- Returns a formatted string and a colour based on clipping risk.
-- ------------------------------------------------------------
local function compute_effective_gain()
    local boost_factor  = (audio.boost or 100) / 100.0
    local volume_factor = (audio.muted and 0) or ((audio.volume or 100) / 100.0)
    local effective     = boost_factor * volume_factor

    local str
    if audio.muted then
        str = T("MUTED")
    elseif effective > 0.001 then
        local db = 20 * math.log(effective, 10)
        str = string.format("%.2fx (%+.1f dB)", effective, db)
    else
        str = "0.00x"
    end

    local colour = C.dim
    if effective >= 3.0 then
        colour = C.amber   -- amber: high clipping risk
    elseif effective >= 2.0 then
        colour = C.green   -- green: noticeable gain
    end

    return str, colour
end

-- ------------------------------------------------------------
-- Render
-- ------------------------------------------------------------
local function gridcards()
    local s = SECTIONS[section]
    if not s or (s.layout ~= "grid" and s.layout ~= "quick") then return nil end
    if s.flat then return s.flat_cards end
    local ti = tabs[section] or 1
    if ti > #s.tabs then ti = 1 end
    return s.tabs[ti].cards
end

local function first()
    if gridcards() then return 1 end
    local r = SECTIONS[section].rows()
    for i, q in ipairs(r) do
        if q.kind ~= "head" then return i end
    end
    return 1
end

function render()
    if not visible then
        ov.data = ""
        ov:update()
        return
    end

    if section >= 1 and section <= #SECTIONS then
        local s0 = SECTIONS[section]
        if (s0.key_en == "quick" or s0.key_en == "audio") and not audio_refreshed then
            audio_refresh()
            audio_refreshed = true
        end
    end

    local ow = mp.get_property_number("osd-width") or RW
    local oh = mp.get_property_number("osd-height") or RH
    sx = math.min(ow / RW, oh / RH)
    sy = sx
    local ox = (ow - RW * sx) / 2
    local oy = (oh - RH * sy) / 2

    local X = function(v) return ox + v * sx end
    local Y = function(v) return oy + v * sy end

    local a = assdraw.ass_new()
    reset_hit()
    hit.panel = { X(P.x), Y(P.y), X(P.x + P.w), Y(P.y + P.h) }

    rect(a, X(P.x) - 1, Y(P.y) - 1, P.w * sx + 2, P.h * sy + 2, C.edge, 0x10)
    rect(a, X(P.x), Y(P.y), P.w * sx, P.h * sy, C.panel, 0x0A)

    local hy = Y(P.y)
    rect(a, X(P.x), hy + HH * sy, P.w * sx, 1, C.edge, 0x10)
    rect(a, X(P.x + 24), hy + 19 * sy, 4 * sx, 26 * sy, C.accent, 0)
    text(a, X(P.x + 38), hy + 32 * sy, "MPV-SW-CAPTURE", C.hi, 20 * sx, true)
    text(a, X(P.x + 185), hy + 32 * sy, app_version, C.text, 16 * sx, false)
    if device ~= "" then
        -- Emoji icon, matching the style of the header buttons
        local dev_icon = "\u{1F3AE}"   -- 🎮 videogame controller
        text(a, X(P.x + 254), hy + 28 * sy, dev_icon, C.text, 36 * sx, false, 5)
        -- Device name (truncated to fit)
        local dev_max_chars = 32
        local dev_text = device
        if #dev_text > dev_max_chars then
            dev_text = dev_text:sub(1, dev_max_chars - 3) .. "..."
        end
        text(a, X(P.x + 274), hy + 32 * sy, dev_text, C.dim, 16 * sx, false)
    end

    local w, h = mp.get_property_number("width"), mp.get_property_number("height")
    local st = w and h and string.format("%dx%d", w, h) or T("no signal")
    local fps = mp.get_property_number("estimated-vf-fps")
    if fps and fps > 0 then st = st .. string.format(" %d fps", math.floor(fps + 0.5)) end
    local right = P.x + P.w - 24
    local hcy = hy + 32 * sy   -- header vertical center

    -- ============================================================
    -- Right side: resolution info + close button
    -- ============================================================
    local ix, iy = X(right - 10), hcy
    hit.close = { ix - 18 * sx, iy - 18 * sy, ix + 18 * sx, iy + 18 * sy }
    if hover_close then
        rect(a, ix - 18 * sx, iy - 18 * sy, 36 * sx, 36 * sy, C.accent, 0x18)
    end
    cross(a, ix, iy, 8 * sx, 2.5 * sx, hover_close and C.hi or C.accent)

    rect(a, X(right - 40), hy + 21 * sy, 1, 22 * sy, C.edge, 0x10)
    text(a, X(right - 50), hcy, st, C.text, 16 * sx, false, 6)

    -- Green video icon (play triangle) - anchored in design space
    local approx_text_w = #st * 8
    local dot_x = X(right - 50 - approx_text_w - -15)
    video_icon(a, dot_x, hcy, w and C.green or C.amber)

    -- ============================================================
    -- Header action buttons: [SCREENSHOT] [RECORD] [LANG]
    -- Placed to the LEFT of the green icon.
    -- ============================================================
    local btn_h   = 30 * sy
    local btn_gap = 8 * sx
    local btn_y   = hcy - btn_h / 2

    -- Separator between buttons and the green icon
    local sep_x = dot_x - 14 * sx
    rect(a, sep_x, hy + 21 * sy, 1, 22 * sy, C.edge, 0x10)

    -- Rightmost: language badge (clickable)
    local btn_right_edge = sep_x - 8 * sx
    local lang_code = current_lang_code():upper()
    local lang_w    = math.max(44, #lang_code * 14 + 10) * sx
    local lang_x    = btn_right_edge - lang_w
    hit.lang        = { lang_x, btn_y, lang_x + lang_w, btn_y + btn_h }
    if hover_lang then
        rect(a, lang_x - 2 * sx, btn_y - 2 * sy, lang_w + 4 * sx, btn_h + 4 * sy, C.blue, 0x30)
    end
    rect(a, lang_x, btn_y, lang_w, btn_h, C.panel, 0x30)
    local lang_border = hover_lang and C.hi or C.blue
    rect(a, lang_x,               btn_y,               lang_w, 1,     lang_border, 0x30)
    rect(a, lang_x,               btn_y + btn_h - 1,   lang_w, 1,     lang_border, 0x30)
    rect(a, lang_x,               btn_y,               1,      btn_h, lang_border, 0x30)
    rect(a, lang_x + lang_w - 1,  btn_y,               1,      btn_h, lang_border, 0x30)
    text(a, lang_x + lang_w / 2, hcy, lang_code,
         hover_lang and C.hi or C.blue, 22 * sx, true, 5)

    -- Icon size (bigger than the label)
    local btn_icon_fs = 26 * sx   -- ← change this to resize the icon
    local btn_label_fs = 14 * sx  -- ← change this to resize the label

    -- Icon offset within the button (from the left edge)
    -- Tweak these if the icon looks off-center.
    local icon_offset_x = 11 * sx   -- ← move icon left/right
    local icon_offset_y = -2 * sy   -- ← move icon up (negative) / down (positive)

    -- Middle: RECORD button
    local rec_w    = 108 * sx
    local rec_x    = lang_x - btn_gap - rec_w
    hit.record     = { rec_x, btn_y, rec_x + rec_w, btn_y + btn_h }
    local rec_bg   = hover_record and C.btn_hover or C.btn_yellow
    rect(a, rec_x, btn_y, rec_w, btn_h, rec_bg, 0)
    -- Icon (left, larger)
    text(a, rec_x + icon_offset_x, hcy + icon_offset_y,
         "\u{1F3A5}", C.btn_black, btn_icon_fs, true, 5)
    -- Label (right of the icon, smaller)
    text(a, rec_x + 32 * sx + (rec_w - 48 * sx) / 2, hcy,
         T("RECORD_HEADER"), C.btn_black, btn_label_fs, true, 5)

    -- Leftmost: SCREENSHOT button
    local sht_w    = 138 * sx
    local sht_x    = rec_x - btn_gap - sht_w
    hit.screenshot = { sht_x, btn_y, sht_x + sht_w, btn_y + btn_h }
    local sht_bg   = hover_screenshot and C.btn_hover or C.btn_yellow
    rect(a, sht_x, btn_y, sht_w, btn_h, sht_bg, 0)
    -- Icon (left, larger)
    text(a, sht_x + icon_offset_x, hcy + icon_offset_y,
         "\u{1F4F8}", C.btn_black, btn_icon_fs, true, 5)
    -- Label (right of the icon, smaller)
    text(a, sht_x + 32 * sx + (sht_w - 48 * sx) / 2, hcy,
         T("SCREENSHOT_HEADER"), C.btn_black, btn_label_fs, true, 5)

    local bx, by = X(P.x), hy + HH * sy
    rect(a, bx + SW * sx, by, 1, (P.h - HH) * sy, C.edge, 0x10)
    for i, s in ipairs(SECTIONS) do
        local ry = by + (14 + (i - 1) * RHROW) * sy
        hit.side[i] = { bx, ry, bx + SW * sx, ry + RHROW * sy }
        if i == section then
            rect(a, bx, ry, SW * sx, RHROW * sy, C.active, 0x18)
            rect(a, bx, ry, 3 * sx, RHROW * sy, C.accent, 0)
        end
        text(a, bx + 24 * sx, ry + 16 * sy, s.name, C.hi, 16 * sx, i == section)
        local bd = s.badge and s.badge()
        if bd then
            text(a, bx + (SW - 20) * sx, ry + 16 * sy, bd,
                s.key_en == "audio" and C.accent or C.faint, 11 * sx, true, 6)
        end
    end

    local fy = Y(P.y + P.h) - 34 * sy
    local clean_y = fy - 42 * sy

    rect(a, bx + 20 * sx, clean_y - 12 * sy, (SW - 40) * sx, 1, C.edge, 0x10)
    hit.clean = { bx + 12 * sx, clean_y - 10 * sy, bx + (SW - 12) * sx, clean_y + 22 * sy }
    if hover_clean then
        rect(a, bx + 12 * sx, clean_y - 10 * sy, (SW - 24) * sx, 30 * sy, C.active, 0x10)
    end
    trash_icon(a, bx + 25 * sx, clean_y + 6 * sy, hover_clean and C.accent or C.hi)
    text(a, bx + 41 * sx, clean_y + 6 * sy, T("CLEAN ALL"),
        hover_clean and C.hi or C.faint, 17 * sx, hover_clean)

    rect(a, bx + 20 * sx, fy - 12 * sy, (SW - 40) * sx, 1, C.edge, 0x10)
    hit.quit = { bx + 12 * sx, fy - 12 * sy, bx + (SW - 12) * sx, fy + 22 * sy }
    if hover_quit then
        rect(a, bx + 12 * sx, fy - 10 * sy, (SW - 24) * sx, 30 * sy, C.active, 0x10)
    end
    cross(a, bx + 25 * sx, fy + 6 * sy, 7 * sx, 2.2 * sx, hover_quit and C.accent or C.hi)
    text(a, bx + 41 * sx, fy + 6 * sy, T("Close MPV-SW-Capture"),
        hover_quit and C.hi or C.faint, 17 * sx, hover_quit)

    local s = SECTIONS[section]
    local cx, cw, cy = bx + (SW + 24) * sx, P.w - SW - 48, by + 22 * sy
    local active = s.active and s.active() or nil
    local top = cy

    if s.layout == "quick" then
        local function meter(label, val, pct, colour, row)
            local yy = top + row * 34 * sy
            text(a, cx, yy + 17 * sy, label, C.text, 17 * sx, row == 0)
            local barx, bw = cx + 96 * sx, (cw - 162) * sx
            rect(a, barx, yy + 15 * sy, bw, 4 * sy, C.track, 0x10)
            rect(a, barx, yy + 15 * sy, bw * pct, 4 * sy, colour, 0)
            text(a, cx + cw * sx, yy + 17 * sy, val, colour, 19 * sx, true, 6)
            hit.rows[#hit.rows + 1] = {
                x1 = cx - 10 * sx, y1 = yy,
                x2 = cx + (cw + 20) * sx, y2 = yy + 34 * sy,
                index = -row - 1,
                kind = "meter",
                meter = row == 0 and "volume" or "boost",
                bar_x1 = barx,
                bar_x2 = barx + bw,
            }
            if row == 0 then
                local rx = cx + 72 * sx
                local ry = yy + 12 * sy
                local rsize = 28 * sx
                local hover_size = 12 * sx
                hit.reload = { rx - hover_size, ry - hover_size, rx + hover_size, ry + hover_size }
                if hover_reload then
                    rect(a, rx - hover_size, ry - hover_size, hover_size * 2, hover_size * 2, C.accent, 0x20)
                end
                a:new_event()
                a:append(string.format("{\\pos(%.1f,%.1f)\\an5\\bord0\\shad0\\1c&H%s&\\fs%.1f\\fnSegoe UI}",
                    rx, ry, hover_reload and C.accent or C.faint, rsize * 1.2))
                a:append("\u{21BB}")
            end
        end
        meter(T("Volume"),
            audio.muted and T("MUTED") or (audio.volume and audio.volume .. "%" or "--"),
            (audio.volume or 0) / 100, C.blue, 0)
        meter(T("Audio Boost"),
            audio.boost .. "%",
            (audio.boost - 100) / (BOOST - 100), C.accent, 1)

        -- Effective gain (right-aligned, below the two sliders)
        local eff_str, eff_colour = compute_effective_gain()
        local yy_eff = top + 2 * 34 * sy
        text(a, cx + cw * sx, yy_eff + 8 * sy, eff_str, eff_colour, 13 * sx, false, 6)

        top = top + 98 * sy
    end

    if s.key_en == "audio" then
        local function audio_meter(label, val, pct, colour, row)
            local yy = top + row * 34 * sy
            text(a, cx, yy + 17 * sy, label, C.text, 17 * sx, row == 0)
            local barx, bw = cx + 96 * sx, (cw - 162) * sx
            rect(a, barx, yy + 15 * sy, bw, 4 * sy, C.track, 0x10)
            rect(a, barx, yy + 15 * sy, bw * pct, 4 * sy, colour, 0)
            text(a, cx + cw * sx, yy + 17 * sy, val, colour, 19 * sx, true, 6)
            hit.rows[#hit.rows + 1] = {
                x1 = cx - 10 * sx, y1 = yy,
                x2 = cx + (cw + 20) * sx, y2 = yy + 34 * sy,
                index = -row - 1,
                kind = "meter",
                meter = row == 0 and "volume" or "boost",
                bar_x1 = barx,
                bar_x2 = barx + bw,
            }
            if row == 0 then
                local rx = cx + 72 * sx
                local ry = yy + 12 * sy
                local rsize = 28 * sx
                local hover_size = 12 * sx
                hit.reload = { rx - hover_size, ry - hover_size, rx + hover_size, ry + hover_size }
                if hover_reload then
                    rect(a, rx - hover_size, ry - hover_size, hover_size * 2, hover_size * 2, C.accent, 0x20)
                end
                a:new_event()
                a:append(string.format("{\\pos(%.1f,%.1f)\\an5\\bord0\\shad0\\1c&H%s&\\fs%.1f\\fnSegoe UI}",
                    rx, ry, hover_reload and C.accent or C.faint, rsize * 1.2))
                a:append("\u{21BB}")
            end
        end
        audio_meter(T("Volume"),
            audio.muted and T("MUTED") or (audio.volume and audio.volume .. "%" or "--"),
            (audio.volume or 0) / 100, C.blue, 0)
        audio_meter(T("Audio Boost"),
            audio.boost .. "%",
            (audio.boost - 100) / (BOOST - 100), C.accent, 1)

        -- Effective gain (right-aligned, below the two sliders)
        local eff_str, eff_colour = compute_effective_gain()
        local yy_eff = top + 2 * 34 * sy
        text(a, cx + cw * sx, yy_eff + 8 * sy, eff_str, eff_colour, 13 * sx, false, 6)

        top = top + 98 * sy
    end

    if s.flat then
        -- Flat layout: headers + all cards visible at once (no tabs bar)
        hit.tabs = {}
        hit.cards = {}
        local cols, gap = 3, 12 * sx
        local cardw = (cw * sx - gap * (cols - 1)) / cols
        local cardh = 55 * sy
        local gy = top
        local card_global = 0
        local bottom_limit = Y(P.y + P.h) - 30 * sy

        for _, t in ipairs(s.tabs) do
            -- Section header (visual only, not clickable)
            text(a, cx, gy + 12 * sy, t.name, C.accent, 12 * sx, true)
            gy = gy + 26 * sy

            local col = 0
            for _, q in ipairs(t.cards) do
                card_global = card_global + 1
                local px = cx + col * (cardw + gap)
                local py = gy
                if py + cardh <= bottom_limit then
                    -- Each card has its own ON/OFF state via check_matches.
                    local is_checked = check_matches(q)
                    -- Navigation index in the flat layout.
                    local sel = card_global == cursor
                    -- Border and text follow the cursor only. The checkmark
                    -- below shows the active state, so the accent border is
                    -- reserved for "where you are".
                    local on = sel

                    rect(a, px, py, cardw, cardh, on and C.active or C.card, on and 0x08 or 0x18)
                    if is_checked then
                        check_icon(a, px + cardw - 30 * sx, py + 42 * sy, 11 * sx, C.accent)
                    end
                    local ed = sel and C.accent or C.cardedge
                    rect(a, px, py, cardw, 1, ed, 0x10)
                    rect(a, px, py + cardh - 1, cardw, 1, ed, 0x10)
                    rect(a, px, py, 1, cardh, ed, 0x10)
                    rect(a, px + cardw - 1, py, 1, cardh, ed, 0x10)

                    local icon_x = px + 14 * sx
                    local icon_y = py + cardh / 2
                    draw_card_icon(a, icon_x, icon_y, q, on, sel)

                    local text_start_x = icon_x + 20 * sx
                    local text_end_x = px + cardw - 12 * sx
                    local max_text_width = text_end_x - text_start_x
                    local label_font_size = 16.5 * sx
                    local sub_font_size = 12.6 * sx
                    local truncated_label = truncate_text(q.label, max_text_width, label_font_size)
                    local truncated_sub = q.sub and truncate_text(q.sub, max_text_width, sub_font_size) or nil

                    text(a, text_start_x, py + 18 * sy, truncated_label,
                        sel and C.hi or C.text, label_font_size, sel, 4)
                    if truncated_sub then
                        text(a, text_start_x, py + 18 * sy + 20 * sy, truncated_sub,
                            C.faint, sub_font_size, false, 4)
                    end

                    hit.cards[card_global] = { px, py, px + cardw, py + cardh, index = card_global }
                end

                col = col + 1
                if col >= cols then
                    col = 0
                    gy = gy + cardh + gap
                end
            end
            if col > 0 then
                gy = gy + cardh + gap
            end
            gy = gy + 4 * sy
        end
    elseif s.layout == "grid" or s.layout == "quick" then
        local ti = tabs[section] or 1
        if ti > #s.tabs then ti = 1 end
        tabs[section] = ti
        local g = s.tabs[ti]
        local tx, ty = cx, top
        hit.tabs = {}
        local maxright = cx + cw * sx
        local lasty = ty

        for i, t in ipairs(s.tabs) do
            local tw = (#t.name * 5.0 + 50) * sx
            if tx + tw > maxright and tx > cx then
                tx = cx
                ty = ty + 38 * sy
            end
            local on = i == ti
            rect(a, tx, ty, tw, 30 * sy, on and C.accent or C.card, on and 0 or 0x18)
            if not on then
                rect(a, tx, ty, tw, 1, C.cardedge, 0x30)
                rect(a, tx, ty + 29 * sy, tw, 1, C.cardedge, 0x30)
            end
            text(a, tx + tw / 2, ty + 15 * sy, t.name, on and C.panel or C.text, 17 * sx, on, 5)
            hit.tabs[i] = { tx, ty, tx + tw, ty + 30 * sy }
            tx = tx + tw + 8 * sx
            lasty = ty
        end

        local gy = lasty + 46 * sy
        hit.cards = {}
        local cols, gap = 3, 12 * sx
        local cardw = (cw * sx - gap * (cols - 1)) / cols
        local cardh = 55 * sy

        for i, q in ipairs(g.cards) do
            local px = cx + ((i - 1) % cols) * (cardw + gap)
            local py = gy + math.floor((i - 1) / cols) * (cardh + gap)
            if py + cardh > Y(P.y + P.h) - 30 * sy then break end

            -- Each card has its own ON/OFF state via check_matches.
            local is_checked = check_matches(q)
            -- Navigation index in the current tab.
            local sel = i == cursor
            -- Border and text follow the cursor only. The checkmark below
            -- shows the active state, so the accent border is reserved for
            -- "where you are".
            local on = sel

            rect(a, px, py, cardw, cardh, on and C.active or C.card, on and 0x08 or 0x18)

            if is_checked then
                check_icon(a, px + cardw - 30 * sx, py + 42 * sy, 11 * sx, C.accent)
            end

            local ed = sel and C.accent or C.cardedge
            rect(a, px, py, cardw, 1, ed, 0x10)
            rect(a, px, py + cardh - 1, cardw, 1, ed, 0x10)
            rect(a, px, py, 1, cardh, ed, 0x10)
            rect(a, px + cardw - 1, py, 1, cardh, ed, 0x10)

            local icon_x = px + 14 * sx
            local icon_y = py + cardh / 2
            draw_card_icon(a, icon_x, icon_y, q, on, sel)

            local text_start_x = icon_x + 20 * sx
            local text_end_x = px + cardw - 12 * sx
            local max_text_width = text_end_x - text_start_x
            local label_font_size = 16.5 * sx
            local sub_font_size = 12.6 * sx
            local truncated_label = truncate_text(q.label, max_text_width, label_font_size)
            local truncated_sub = q.sub and truncate_text(q.sub, max_text_width, sub_font_size) or nil

            text(a, text_start_x, py + 18 * sy, truncated_label,
                sel and C.hi or C.text, label_font_size, sel, 4)
            if truncated_sub then
                text(a, text_start_x, py + 18 * sy + 20 * sy, truncated_sub,
                    C.faint, sub_font_size, false, 4)
            end

            hit.cards[i] = { px, py, px + cardw, py + cardh, index = i }
        end
    else
        local r = s.rows()
        local max = math.floor((P.h - HH - 44 - (s.footer and 34 or 0)) / 34)
        if cursor < scroll + 1 then scroll = cursor - 1 end
        if cursor > scroll + max then scroll = cursor - max end
        if scroll < 0 then scroll = 0 end

        local d = 0
        for i = scroll + 1, #r do
            if d >= max then break end
            local q = r[i]
            local yy = cy + d * 36 * sy
            if q.kind ~= "head" then
                hit.rows[#hit.rows + 1] = {
                    x1 = cx - 10 * sx, y1 = yy,
                    x2 = cx + (cw + 20) * sx, y2 = yy + 36 * sy,
                    index = i,
                    kind = q.kind,
                    meter = q.meter,
                }
            end
            if q.kind == "head" then
                text(a, cx, yy + 17 * sy, q.label, C.dim, 11 * sx, true)
            elseif q.kind == "meter" then
                local isv = q.meter == "volume"
                local v = isv and audio.volume or audio.boost
                local pc = isv and ((v or 0) / 100) or ((v - 100) / (BOOST - 100))
                local suf = isv and (v and v .. "%" or "--") or v .. "%"
                if isv and audio.muted then suf = T("MUTED") end
                text(a, cx, yy + 17 * sy, q.label, C.text, 13 * sx, i == cursor)
                local barx, bw = cx + 96 * sx, (cw - 162) * sx
                rect(a, barx, yy + 15 * sy, bw, 4 * sy, C.track, 0x10)
                rect(a, barx, yy + 15 * sy, bw * pc, 4 * sy, isv and C.blue or C.accent, 0)
                text(a, cx + cw * sx, yy + 17 * sy, suf, isv and C.hi or C.accent, 15 * sx, true, 6)
                local hr = hit.rows[#hit.rows]
                hr.bar_x1 = barx
                hr.bar_x2 = barx + bw
            else
                local sel = i == cursor
                if sel then
                    rect(a, cx - 10 * sx, yy, (cw + 20) * sx, 36 * sy, C.active, 0x20)
                    rect(a, cx - 10 * sx, yy, 3 * sx, 36 * sy, C.accent, 0)
                end
                local is_on = false
                if active and q.id and active == q.id then is_on = true end
                local offset = 0
                if is_on then
                    text(a, cx + 20 * sx, yy + 17 * sy, "\u{2713}", C.accent, 14 * sx, true, 4)
                    offset = 24
                end
                text(a, cx + offset * sx, yy + 17 * sy, q.label, sel and C.hi or C.text, 13 * sx, sel)
                local v = q.value and q.value() or nil
                if v then
                    text(a, cx + cw * sx, yy + 17 * sy, v,
                        v == "REC" and C.accent or C.faint, 12 * sx, true, 6)
                end
            end
            d = d + 1
        end
    end

    text(a, cx, Y(P.y + P.h) - 29 * sy,
        T("KEYBOARD: [ARROW KEYS] Move. [ENTER] Apply. [TAB] Change to next section. [ESC] Close menu."),
        C.hi, 14.7 * sx, false)
    text(a, cx, Y(P.y + P.h) - 13 * sy,
        T("MOUSE: Click any section to choose an option."),
        C.hi, 14.7 * sx, false)

    ov.res_x = ow
    ov.res_y = oh
    ov.data = a.text
    ov:update()
end

-- ------------------------------------------------------------
-- Input handling
-- ------------------------------------------------------------
local function inside(box, x, y)
    if not box then return false end
    local x1, y1, x2, y2 = box[1] or box.x1, box[2] or box.y1, box[3] or box.x2, box[4] or box.y2
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

local function pos()
    local m = mp.get_property_native("mouse-pos")
    return m and m.x, m and m.y
end

-- Slider drag: update only the visual state while dragging,
-- send the final value to PowerShell once on release.
-- Guards against NaN, division by zero, and stale hitboxes.
local function fromx(h, x)
    if not h or not h.bar_x1 or not h.bar_x2 then return end
    if h.bar_x2 == h.bar_x1 then return end
    local f = (x - h.bar_x1) / (h.bar_x2 - h.bar_x1)
    if f ~= f then return end   -- NaN check
    f = math.max(0, math.min(1, f))
    if h.meter == "volume" then
        -- Visual-only update; the real value is sent on release.
        audio.volume = math.floor(f * 100 + 0.5)
        render()
    else
        audio.boost = math.floor((100 + f * (BOOST - 100)) / 25 + 0.5) * 25
        render()
    end
end

local function stopdrag()
    if timer then
        timer:kill()
        timer = nil
    end
    if drag then
        local which = drag.meter
        drag = nil
        if which == "volume" then
            local v = audio.volume
            if type(v) == "number" then
                schedule_volume_send(v)
            end
        elseif which == "boost" then
            local b = audio.boost
            if type(b) == "number" then
                -- Send via the debouncer: if the user drags again within
                -- the debounce window, only the final value reaches PowerShell.
                schedule_boost_send(b)
            end
        end
    end
end

local function switch_section_and_refresh(new_section)
    if section == new_section then return end
    section = new_section
    cursor = first()
    scroll = 0
    audio_refreshed = false
    local s = SECTIONS[section]
    if s.key_en == "quick" or s.key_en == "audio" then
        audio_refresh()
        audio_refreshed = true
    end
    render()
end

local function run_card(q)
    if not q or not q.run then return end
    q.run()
    if q.close_after then
        hide()                                  -- pure close
    else
        render()
        trigger_auto_hide(q.is_boost)           -- force hide+reopen for boost
    end
end

local function handle_action()
    local cs = gridcards()
    if cs then
        run_card(cs[cursor])
        return
    end
    run_card(SECTIONS[section].rows()[cursor])
end

local function activate()
    handle_action()
end

local function move(d)
    local cs = gridcards()
    if cs then
        cursor = math.max(1, math.min(#cs, cursor + d * 3))
        render()
        return
    end
    local r = SECTIONS[section].rows()
    local i = cursor
    for _ = 1, #r do
        i = i + d
        if i < 1 then i = #r elseif i > #r then i = 1 end
        if r[i].kind ~= "head" then
            cursor = i
            render()
            return
        end
    end
end

local function sw(d)
    switch_section_and_refresh(section + d)
end

local function horiz(d)
    local cs = gridcards()
    if cs then
        local s = SECTIONS[section]
        if s.flat then
            -- Flat layout: no tab switching, just move within cards
            cursor = math.max(1, math.min(#cs, cursor + d))
            render()
            return
        end
        local i = cursor + d
        if i < 1 or i > #cs then
            local t = (tabs[section] or 1) + d
            if t < 1 then t = #s.tabs elseif t > #s.tabs then t = 1 end
            tabs[section] = t
            cursor = 1
        else
            cursor = i
        end
        render()
        return
    end

    local q = SECTIONS[section].rows()[cursor]
    if q and q.kind == "meter" then
        if q.meter == "volume" then
            volset((audio.volume or 100) + d * 5)
        else
            boostset(audio.boost + d * 25)
        end
    else
        switch_section_and_refresh(section + d)
    end
end

local function mouseup()
    stopdrag()
end

local function unbind()
    if not bound then return end
    for i = 1, 11 do mp.remove_key_binding("msc_key" .. i) end
    mp.remove_key_binding("msc_esc")
    mp.remove_key_binding("msc_rmb")
    mp.remove_key_binding("msc_lmb")
    mp.unobserve_property(mousemove)
    bound = false
end

function hide()
    if not visible then return end
    visible = false
    cancel_hide_timer()
    hover_close = false
    hover_quit = false
    hover_clean = false
    hover_reload = false
    hover_screenshot = false
    hover_record = false
    hover_lang = false
    stopdrag()
    unbind()
    reset_hit()
    ov.data = ""
    ov:update()
end

function mousemove()
    if not visible then return end
    local x, y = pos()
    if not x then return end

    if drag then
        fromx(drag, x)
        return
    end

    local new_close      = hit.close and inside(hit.close, x, y) or false
    local new_quit       = hit.quit and inside(hit.quit, x, y) or false
    local new_clean      = hit.clean and inside(hit.clean, x, y) or false
    local new_reload     = hit.reload and inside(hit.reload, x, y) or false
    local new_screenshot = hit.screenshot and inside(hit.screenshot, x, y) or false
    local new_record     = hit.record and inside(hit.record, x, y) or false
    local new_lang       = hit.lang and inside(hit.lang, x, y) or false

    if new_close ~= hover_close
       or new_quit ~= hover_quit
       or new_clean ~= hover_clean
       or new_reload ~= hover_reload
       or new_screenshot ~= hover_screenshot
       or new_record ~= hover_record
       or new_lang ~= hover_lang then
        hover_close      = new_close
        hover_quit       = new_quit
        hover_clean      = new_clean
        hover_reload     = new_reload
        hover_screenshot = new_screenshot
        hover_record     = new_record
        hover_lang       = new_lang
        render()
        return
    end

    if hover_close or hover_quit or hover_clean or hover_reload
       or hover_screenshot or hover_record or hover_lang then return end

    for _, h in ipairs(hit.rows) do
        if inside(h, x, y) and h.index > 0 and cursor ~= h.index then
            cursor = h.index
            render()
            return
        end
    end
end

local function mousedown()
    if not visible then return end
    local x, y = pos()
    if not x then return end
    if not inside(hit.panel, x, y) then hide(); return end
    if hit.close and inside(hit.close, x, y) then hide(); return end
    if hit.quit and inside(hit.quit, x, y) then mp.command("quit"); return end
    if hit.clean and inside(hit.clean, x, y) then cleanall(); return end
    if hit.reload and inside(hit.reload, x, y) then audio_refresh(); return end

    -- Header action buttons
    if hit.screenshot and inside(hit.screenshot, x, y) then
        mp.command("screenshot")
        hide()
        return
    end
    if hit.record and inside(hit.record, x, y) then
        mp.commandv("script-message-to", "autocompress", "toggle-record")
        hide()
        return
    end
    if hit.lang and inside(hit.lang, x, y) then
        toggle_language()
        return
    end

    for i, h in ipairs(hit.side) do
        if inside(h, x, y) then
            switch_section_and_refresh(i)
            return
        end
    end

    for i, h in ipairs(hit.tabs or {}) do
        if inside(h, x, y) then
            tabs[section] = i
            cursor = 1
            render()
            return
        end
    end

    for i, h in ipairs(hit.cards or {}) do
        if inside(h, x, y) then
            cursor = i
            local cs = gridcards()
            run_card(cs and cs[cursor])
            return
        end
    end

    if hit.clear and inside(hit.clear, x, y) then
        local sec = SECTIONS[section]
        if sec.clear and sec.clear.run then
            sec.clear.run()
            render()
            trigger_auto_hide()
        end
        return
    end

    for _, h in ipairs(hit.rows) do
        if inside(h, x, y) then
            if h.index > 0 then cursor = h.index end
            if h.kind == "meter" then
                -- Kill any stale timer before starting a new drag
                if timer then timer:kill(); timer = nil end
                drag = h
                fromx(h, x)
                timer = mp.add_periodic_timer(0.03, function()
                    if drag then
                        local px = pos()
                        if px then fromx(drag, px) end
                    end
                end)
            else
                run_card(SECTIONS[section].rows()[cursor])
            end
            return
        end
    end
    render()
end

local K = {
    { "UP", function() move(-1) end },
    { "DOWN", function() move(1) end },
    { "LEFT", function() horiz(-1) end },
    { "RIGHT", function() horiz(1) end },
    { "ENTER", activate },
    { "KP_ENTER", activate },
    { "TAB", function() sw(1) end },
    { "PGUP", function() sw(-1) end },
    { "PGDWN", function() sw(1) end },
    { "WHEEL_UP", function() move(-1) end },
    { "WHEEL_DOWN", function() move(1) end },
}

local function bind()
    if bound then return end
    for i, k in ipairs(K) do
        mp.add_forced_key_binding(k[1], "msc_key" .. i, k[2], { repeatable = true })
    end
    mp.add_forced_key_binding("ESC", "msc_esc", hide)
    mp.add_forced_key_binding("MBTN_RIGHT", "msc_rmb", hide)
    mp.add_forced_key_binding("MBTN_LEFT", "msc_lmb", function(e)
        if e.event == "down" then mousedown() elseif e.event == "up" then mouseup() end
    end, { complex = true })
    mp.observe_property("mouse-pos", "native", mousemove)
    bound = true
end

-- ------------------------------------------------------------
-- Show / Toggle
-- ------------------------------------------------------------
function show()
    if visible then return end
    visible = true
    cancel_hide_timer()
    if section > #SECTIONS then section = 1 end
    cursor = first()
    scroll = 0
    refresh_app_version()
    device_refresh()
    bind()
    audio_refresh()
    audio_refreshed = true
    render()
end

local function toggle()
    if visible then hide() else show() end
end

mp.add_key_binding(nil, "toggle-overlay", toggle)
mp.register_script_message("toggle-overlay", toggle)
mp.register_script_message("close-overlay", hide)

mp.register_script_message("reload-lang", function()
    rebuild_dicts()
    AVAILABLE_LANGS = load_languages()
    ROOTS = load_roots()
    rebuild_sections()
    tabs = {}
    if visible then
        if section > #SECTIONS then section = 1 end
        cursor = first()
        render()
    end
end)

mp.observe_property("osd-width", "number", function()
    if visible then render() end
end)

mp.register_event("shutdown", hide)

msg.info("MSC overlay loaded. Use script-message toggle-overlay.")

audio_refresh()