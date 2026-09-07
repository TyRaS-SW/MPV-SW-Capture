-- msc_overlay.lua - For MPV-SW-Capture - Modern ESC overlay UI
--
-- Replaces the built-in select/context-menu with a drawn ASS overlay:
-- a left sidebar of sections and a content pane, rendered over the live
-- capture feed.
--
-- Design constraints this file works within (libass, not a browser):
--   * flat fills, 1px rules and solid bars only - no blur, gradients,
--     rounded corners or drop shadows
--   * icons are drawn as vector paths, not glyphs or images
--
-- Audio: played by a separate ffplay process, so volume and boost are
-- driven through data/ffplayvol.ps1 and data/ffplayboost.ps1 rather than
-- mpv properties. Those calls spawn PowerShell (~220ms) and boost restarts
-- ffplay, so every call here is asynchronous and the UI paints from a
-- cache. See MPV-SW-Capture.bat for why audio is not routed through mpv.

local mp = require "mp"
local msg = require "mp.msg"
local assdraw = require "mp.assdraw"
local utils = require "mp.utils"

-- ============================================================
-- THEME (Direction A - dark glass, Switch-inspired)
-- ============================================================
local C = {
    scrim        = "0A0B10",  -- full-frame dim behind the panel
    panel        = "221A14",  -- panel body            (#141a22)
    panel_edge   = "44362B",  -- 1px borders           (#2b3644)
    row_active   = "33271D",  -- selected sidebar row  (#1d2733)
    card         = "2C221A",  -- inset cards           (#1a222c)
    card_edge    = "4F4033",  -- card border           (#33404f)
    track        = "382C22",  -- meter trough          (#222c38)

    text_hi      = "F8F5F2",  -- primary text          (#f2f5f8)
    text         = "D4C5B7",  -- body text             (#b7c5d4)
    text_dim     = "AB9682",  -- labels                (#8296ab)
    text_faint    = "86705D",  -- hints                 (#5d7086)

    accent       = "524BFF",  -- MSC red               (#ff4b52)
    accent_soft  = "8F8AFF",  -- lighter red           (#ff8a8f)
    accent_bg    = "1E1A2A",  -- red-tinted fill       (#2a1a1e)
    accent_edge  = "302B4A",  -- red-tinted border     (#4a2b30)
    blue         = "FF9E4A",  -- volume meter          (#4a9eff)
    green        = "7FD035",  -- live dot              (#35d07f)
    amber        = "41A4D9",  -- caution               (#d9a441)
}

-- Values above are already in ASS's &HBBGGRR& byte order; the comment on
-- each line is the #RRGGBB it corresponds to.

-- Layout is authored against a 1280x720 reference and scaled to the
-- window, so the overlay keeps its proportions at any size.
local REF_W, REF_H = 1280, 720

local PANEL = { x = 140, y = 64, w = 1000, h = 592 }
local SIDEBAR_W = 232
local HEADER_H = 64

-- ============================================================
-- STATE
-- ============================================================
local visible = false
local section = 1        -- index into SECTIONS
local cursor = 1         -- selected row within the content pane
local scroll = 0         -- first visible content row
local tab = {}           -- per-section active category tab: tab[section] = i

local overlay = mp.create_osd_overlay("ass-events")

-- Audio values are cached; refreshed asynchronously (see above).
local audio = {
    volume = nil,        -- nil = "not read yet"
    boost = 100,
    muted = false,
    pending = false,
}

local ROOT = nil

-- Hit regions recorded during render(), so a mouse click can be mapped back
-- to whatever was actually drawn. Screen coordinates, in OSD pixels.
--   sidebar[i] = {x1, y1, x2, y2}                for section i
--   rows[]     = {x1, y1, x2, y2, index, kind,   for a content row
--                 bar_x1, bar_x2}                (bar_* only on meters)
local hit = { sidebar = {}, rows = {}, panel = nil }

-- ============================================================
-- PATHS
-- ============================================================
local function get_root()
    if ROOT then return ROOT end
    local cfg = mp.get_property("config-path")
    if cfg and cfg ~= "" then
        ROOT = cfg:gsub("\\", "/")
        return ROOT
    end
    local wd = mp.get_property("working-directory")
    ROOT = (wd and wd ~= "" and wd:gsub("\\", "/")) or "."
    return ROOT
end

-- ============================================================
-- ASYNC AUDIO STATE
-- ============================================================
-- Audio is played by a separate ffplay process (see MPV-SW-Capture.bat for
-- why), so volume and boost live outside mpv and are driven through the
-- helper scripts. Each call spawns PowerShell (~220ms) and a boost change
-- restarts ffplay, so every call here is ASYNCHRONOUS: the overlay paints
-- from this cache and repaints when a value arrives. Never block render().
local BOOST_MAX = 400

-- Parse a number the helper scripts print on their own line.
--
-- They print an "EXCEPTION: ..." message when there is no ffplay session,
-- and that text contains digits (e.g. 'with "1" argument(s)'). A bare
-- "%d+" scrape returns 1 from it, which showed up as a 1% volume reading.
local function parse_number(s)
    if not s then return nil end
    if s:match("EXCEPTION") or s:match("ERROR") then return nil end
    local last = nil
    for line in s:gmatch("[^\r\n]+") do
        local n = line:match("^%s*(%d+)%s*$")
        if n then last = tonumber(n) end
    end
    return last
end

local function ps_async(script_rel, args, on_done)
    local root = get_root()
    local a = {
        "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", root .. "/" .. script_rel,
    }
    for _, v in ipairs(args) do a[#a + 1] = v end

    mp.command_native_async({
        name = "subprocess",
        args = a,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    }, function(ok, res)
        if on_done then on_done(ok, res) end
    end)
end

local function refresh_audio()
    if audio.pending then return end
    audio.pending = true

    ps_async("data/ffplayvol.ps1", { "get", "ffplay" }, function(ok, res)
        if ok and res and res.stdout then
            local n = parse_number(res.stdout)
            if n then audio.volume = n end
        end
        ps_async("data/ffplayboost.ps1", { "get" }, function(ok2, res2)
            if ok2 and res2 and res2.stdout then
                local b = parse_number(res2.stdout)
                if b then audio.boost = b end
            end
            audio.pending = false
            if visible then render() end
        end)
    end)
end
-- ============================================================
-- ACTIONS
-- ============================================================
local function osd(text)
    local dur = mp.get_property_number("osd-duration") or 1000
    if dur > 0 then mp.osd_message(text, 1.2) end
end

local function clamp_boost(v)
    if v < 100 then return 100 end
    if v > BOOST_MAX then return BOOST_MAX end
    return v
end

local function vol_set(v)
    if v < 0 then v = 0 elseif v > 100 then v = 100 end
    v = math.floor(v + 0.5)
    audio.volume = v                 -- optimistic: draw it immediately
    if visible then render() end
    ps_async("data/ffplayvol.ps1", { "set", "ffplay", tostring(v) }, function() end)
end

local function vol_step(dir, step)
    vol_set((audio.volume or 100) + (dir == "up" and step or -step))
end

local function vol_mute()
    ps_async("data/ffplayvol.ps1", { "togglemute", "ffplay" }, function(ok, res)
        if ok and res and res.stdout then
            audio.muted = res.stdout:match("unmuted") == nil
        end
        if visible then render() end
    end)
end

-- Boost restarts ffplay (~0.5s of silence) because ffplay cannot change its
-- filter graph at runtime. Show the target value straight away so the meter
-- never looks frozen while that happens.
local function boost_set(v)
    v = clamp_boost(v)
    if v == audio.boost then return end
    audio.boost = v
    if visible then render() end
    ps_async("data/ffplayboost.ps1", { "set", tostring(v) }, function(ok, res)
        if ok and res and res.stdout then
            local n = parse_number(res.stdout)
            if n then audio.boost = n end
        end
        if visible then render() end
    end)
end

local function boost_step(delta)
    boost_set((audio.boost or 100) + delta)
end

-- ============================================================
-- MENU MODEL
-- Mirrors menu.conf so the overlay is a full replacement, not a subset.
-- Each row: { label, kind, run, value, note }
--   kind "action"  - run() on ENTER
--   kind "meter"   - draws a bar; left/right adjust
--   kind "head"    - non-selectable subheading
-- ============================================================
local function cmd(s)
    return function() mp.command(s) end
end

local function shader(list, id, label)
    return function()
        mp.commandv("change-list", "glsl-shaders", "set", list)
        mp.set_property("user-data/active_shader", id)
        osd(label)
    end
end

local SECTIONS = {}

-- ---------- QUICK ----------
SECTIONS[1] = {
    name = "Quick",
    icon = "quick",
    rows = function()
        return {
            { label = "Volume", kind = "meter", meter = "volume" },
            { label = "Audio Boost", kind = "meter", meter = "boost" },
            { label = "CAPTURE", kind = "head" },
            { label = "Take Screenshot", kind = "action", run = cmd("screenshot") },
            {
                label = "Record Video (30s)", kind = "action",
                run = function()
                    mp.commandv("script-message-to", "autocompress", "toggle-record")
                end,
                value = function()
                    return mp.get_property_native("user-data/is_recording") and "REC" or nil
                end,
            },
            { label = "Fullscreen", kind = "action", run = cmd("cycle fullscreen") },
            -- Window/display toggles live in the Window section; repeating
            -- them here only lengthened the panel.
            { label = "Clean ALL", kind = "action", run = function()
                mp.commandv("script-message", "clear-bezel", "silent")
                mp.commandv("script-message", "clear-crop", "silent")
                mp.commandv("script-message", "clear-addon-shaders", "silent")
                mp.commandv("vf", "set", "")
                mp.commandv("change-list", "glsl-shaders", "clr", "")
                mp.set_property("deband", "no")
                mp.set_property("user-data/active_shader", "none")
                mp.set_property("user-data/active_shape", "none")
                osd("Cleaned ALL")
            end },
        }
    end,
}

-- ---------- AUDIO ----------
SECTIONS[2] = {
    name = "Audio",
    icon = "audio",
    badge = function()
        if audio.boost and audio.boost > 100 then
            return tostring(audio.boost) .. "%"
        end
        return nil
    end,
    -- The sliders ARE the control: left/right adjust them, so separate
    -- preset rows would just duplicate what the meter already does.
    rows = function()
        return {
            { label = "Volume", kind = "meter", meter = "volume" },
            { label = "Audio Boost", kind = "meter", meter = "boost" },
            { label = "Mute / Unmute", kind = "action", run = vol_mute,
              value = function() return audio.muted and "MUTED" or nil end },
        }
    end,
    footer = "Boost amplifies past the source level. Changing it restarts audio (~0.5s).",
}

-- ---------- SHADERS ----------
local SH = "~~/shaders/"
SECTIONS[3] = {
    name = "Shaders",
    icon = "shader",
    layout = "grid",
    badge = function() return "28" end,
    active = function() return mp.get_property("user-data/active_shader") end,
    -- Category tabs, each holding a grid of cards (see the design canvas).
    tabs = {
        {
            name = "4K",
            cards = {
                { label = "1080p to 4K Fast", sub = "FSR1 + NVSharpen", id = "SH_4K_1",
                  run = shader(SH.."KrigBilateral.glsl;"..SH.."AMD_FSR1_RT.glsl;"..SH.."NVSharpen_scl_RT.glsl", "SH_4K_1", "1080p->4K Fast") },
                { label = "4K Adaptive", sub = "Adaptive sharpen", id = "SH_4K_2",
                  run = shader(SH.."KrigBilateral.glsl;"..SH.."AMD_FSR1_RT.glsl;"..SH.."Adaptive_sharpen_lite_RT.glsl", "SH_4K_2", "1080p->4K Adaptive") },
                { label = "4K NVScaler", sub = "NVIDIA scaler", id = "SH_4K_3",
                  run = shader(SH.."KrigBilateral.glsl;"..SH.."NVScaler_RT.glsl;"..SH.."NVSharpen_scl_RT.glsl", "SH_4K_3", "1080p->4K NVScaler") },
                { label = "Only Sharpen", sub = "No upscale", id = "SH_SP_1",
                  run = shader(SH.."Adaptive_sharpen_RT.glsl", "SH_SP_1", "Only Sharpen") },
            },
        },
        {
            name = "TV / CRT",
            cards = {
                { label = "VHS", sub = "Tape artefacts", id = "SH_TV_1",
                  run = shader(SH.."retro/vhs.glsl", "SH_TV_1", "CRT VHS") },
                { label = "CRT Aperture", sub = "Aperture grille", id = "SH_TV_2",
                  run = shader(SH.."retro/crt-aperture-windowscale-fixed.glsl", "SH_TV_2", "CRT Aperture") },
                { label = "CRT Trinitron", sub = "Sony Trinitron", id = "SH_TV_3",
                  run = shader(SH.."retro/crt-gdv-mini-ultra-trinitron_notcurv.glsl", "SH_TV_3", "CRT Trinitron") },
                { label = "Royale Kurozumi", sub = "Heavy mask", id = "SH_TV_4",
                  run = shader(SH.."retro/crt-royale-kurozumi.glsl", "SH_TV_4", "CRT Royale Kurozumi") },
                { label = "Royale Intel", sub = "Lighter Royale", id = "SH_TV_5",
                  run = shader(SH.."retro/crt-royale-fb-intel.glsl", "SH_TV_5", "CRT Royale Intel") },
                { label = "CRT Gizmo", sub = "Soft scanlines", id = "SH_TV_6",
                  run = shader(SH.."retro/gizmo-crt-fixed.glsl", "SH_TV_6", "CRT Gizmo") },
                { label = "CRT Hyllian", sub = "Sharp scanlines", id = "SH_TV_7",
                  run = shader(SH.."retro/crt-hyllian-fix.glsl", "SH_TV_7", "CRT Hyllian") },
                { label = "Vertical Grille", sub = "Curved grille", id = "SH_TV_8",
                  run = shader(SH.."retro/crt-vertical-aperture-grille.glsl;"..SH.."crt-curvature-only.glsl", "SH_TV_8", "CRT Vertical Aperture Grille") },
                { label = "Vertical Slot Mask", sub = "Slot mask", id = "SH_TV_9",
                  run = shader(SH.."retro/crt-vertical-slotmask.glsl", "SH_TV_9", "CRT Vertical Slot Mask") },
            },
        },
        {
            name = "Handheld",
            cards = {
                { label = "Dot Matrix", sub = "Handheld LCD", id = "SH_VG_1",
                  run = shader(SH.."retro/dot-perfect.glsl", "SH_VG_1", "Handheld Dot Matrix") },
                { label = "GB LCD Color", sub = "Game Boy tint", id = "SH_VG_2",
                  run = shader(SH.."retro/gb_origin_lcd_colors.glsl;"..SH.."retro/dot-perfect.glsl", "SH_VG_2", "GB LCD Color Screen") },
                { label = "Gameboy Advance", sub = "GBA panel", id = "SH_VG_3",
                  run = shader(SH.."retro/gba.glsl", "SH_VG_3", "GBA") },
                { label = "Arcade (Lottes)", sub = "Arcade CRT", id = "SH_VG_4",
                  run = shader(SH.."retro/crt-lottes-fix.glsl", "SH_VG_4", "CRT Arcade (Lottes)") },
                { label = "GTU-v050", sub = "Composite blur", id = "SH_VG_5",
                  run = shader(SH.."retro/gtu-v050-fix.glsl", "SH_VG_5", "GTU-v050") },
                { label = "Geom Deluxe", sub = "Curved geometry", id = "SH_VG_6",
                  run = shader(SH.."retro/crt-geom-deluxe-fix.glsl", "SH_VG_6", "CRT Geom Deluxe") },
                { label = "Guest SM", sub = "Guest shader", id = "SH_VG_7",
                  run = shader(SH.."retro/crt-guest-sm-fix.glsl", "SH_VG_7", "CRT Guest SM") },
            },
        },
        {
            name = "Special",
            cards = {
                { label = "Broken LCD TV", sub = "Damaged panel", id = "SH_OT_1",
                  run = shader(SH.."lcd_brokenTV.glsl", "SH_OT_1", "Broken LCD TV") },
                { label = "LCD Dust", sub = "Dust overlay", id = "SH_OT_2",
                  run = shader(SH.."lcd_dust.glsl", "SH_OT_2", "LCD Dust") },
                { label = "Inverted Colors", sub = "Colour invert", id = "SH_OT_3",
                  run = shader(SH.."inverted_colors.glsl", "SH_OT_3", "Inverted Colors") },
            },
        },
    },
    clear = { label = "Clear", id = "none", run = function()
        mp.commandv("change-list", "glsl-shaders", "clr", "")
        mp.set_property("deband", "no")
        mp.set_property("user-data/active_shader", "none")
        osd("Shaders cleaned")
    end },
}
-- ---------- SHAPES ----------
local function shape(id, label)
    return function()
        mp.commandv("script-message", "toggle-addon-shader", id)
        osd(label)
    end
end

SECTIONS[4] = {
    name = "Shapes",
    icon = "shape",
    layout = "grid",
    badge = function() return "10" end,
    active = function() return mp.get_property("user-data/active_shape") end,
    tabs = {
        {
            name = "Curvature",
            cards = {
                { label = "CRT Curvature", sub = "Barrel warp", id = "FRM1", run = shape("FRM1", "CRT Curvature") },
                { label = "Curvature + Edge", sub = "Edge darkening", id = "FRM2", run = shape("FRM2", "CRT Curvature (Edge Darkening)") },
                { label = "Wide Barrel", sub = "Wider warp", id = "FRM3", run = shape("FRM3", "CRT Wide Barrel") },
                { label = "Wide Barrel + Edge", sub = "Edge darkening", id = "FRM4", run = shape("FRM4", "CRT Wide Barrel (Edge Darkening)") },
                { label = "Super Curvature", sub = "Strong warp", id = "FRM5", run = shape("FRM5", "CRT Super Curvature") },
                { label = "Rounded Corners", sub = "Corner mask", id = "FRM6", run = shape("FRM6", "Rounded Corners") },
            },
        },
        {
            name = "Perspective",
            cards = {
                { label = "Tilted Keystone", sub = "Leaning back", id = "FRM7", run = shape("FRM7", "CRT Tilted (Keystone)") },
                { label = "Keystone Inverted", sub = "Leaning forward", id = "FRM8", run = shape("FRM8", "CRT Tilted (Keystone Inverted)") },
                { label = "Pinball", sub = "Cabinet angle", id = "FRM9", run = shape("FRM9", "Pinball Perspective") },
                { label = "Inward Keystone", sub = "Low bottom zoom", id = "FRMO_1", run = shape("FRMO_1", "Inward Keystone") },
            },
        },
    },
    clear = { label = "Clear", id = "none", run = function()
        mp.commandv("script-message", "clear-addon-shaders", "silent")
        osd("Shape cleared")
    end },
}

-- ---------- CROPS ----------
local function crop(binding, label)
    return function()
        mp.commandv("script-binding", binding)
        osd(label)
    end
end

SECTIONS[5] = {
    name = "Crops",
    icon = "crop",
    layout = "grid",
    badge = function() return "12" end,
    active = function() return mp.get_property("user-data/crop-active") end,
    tabs = {
        {
            name = "N64 / GC",
            cards = {
                { label = "N64 / GC", sub = "4:3", id = "crop1", run = crop("crop1", "NSO N64/GC (4:3)") },
                { label = "N64 Mario 64", sub = "Native size", id = "cropsp1", run = crop("cropsp1", "NSO N64 (Mario 64 Size)") },
                { label = "N64 DK64", sub = "Widescreen", id = "cropsp2", run = crop("cropsp2", "NSO N64 (DK64 Widescreen)") },
            },
        },
        {
            name = "NES / SNES",
            cards = {
                { label = "NES", sub = "4:3 / CRT", id = "crop2", run = crop("crop2", "NSO NES (4:3/CRT)") },
                { label = "NES Pixel Perfect", sub = "1:1 pixels", id = "crop3", run = crop("crop3", "NSO NES (Pixel Perfect)") },
                { label = "SNES / Genesis", sub = "4:3 / CRT", id = "crop4", run = crop("crop4", "NSO SNES/GEN (4:3/CRT)") },
                { label = "SNES Pixel Perfect", sub = "1:1 pixels", id = "crop5", run = crop("crop5", "NSO SNES (Pixel Perfect)") },
                { label = "Genesis Pixel", sub = "1:1 pixels", id = "crop10", run = crop("crop10", "NSO Genesis (Pixel Perfect)") },
            },
        },
        {
            name = "Game Boy",
            cards = {
                { label = "GameBoy Color", sub = "Default size", id = "crop6", run = crop("crop6", "NSO GameBoy Color") },
                { label = "GameBoy Small", sub = "Compact", id = "crop7", run = crop("crop7", "NSO GameBoy (Small)") },
                { label = "GameBoy Advance", sub = "Default size", id = "crop8", run = crop("crop8", "NSO GameBoy Advance") },
                { label = "GBA Small", sub = "Compact", id = "crop9", run = crop("crop9", "NSO GameBoy Advance (Small)") },
            },
        },
    },
    clear = { label = "Clear", id = "", run = function()
        mp.commandv("script-message", "clear-crop", "silent")
        osd("Crop cleared")
    end },
}

-- ---------- BEZELS ----------
-- File names, ids and the four crop coordinates must match menu.conf
-- exactly: the id drives the active-state highlight and the coordinates
-- place the video inside the bezel art.
local function bezel(file, id, a, b, c, d, label)
    return function()
        mp.commandv("script-message", "toggle-bezel", file, id,
            tostring(a), tostring(b), tostring(c), tostring(d))
        osd(label)
    end
end

SECTIONS[6] = {
    name = "Bezels",
    icon = "bezel",
    layout = "grid",
    badge = function() return "5" end,
    active = function() return mp.get_property("user-data/active_bezel") end,
    tabs = {
        {
            name = "All",
            cards = {
                { label = "NES", sub = "80s TV", id = "NES1",
                  run = bezel("nes_b_1.png", "NES1", 302, 28, 1316, 1026, "NES BG 1 (80s TV)") },
                { label = "CRT 4:3", sub = "90s TV", id = "4.3CRT1",
                  run = bezel("crt43_b_1.png", "4.3CRT1", 298, 36, 1322, 1008, "CRT 4:3 BG 1 (90s TV)") },
                { label = "Game Boy", sub = "Handheld shell", id = "GB1",
                  run = bezel("gb_b_1.png", "GB1", 398, 36, 1124, 1008, "GB BG 1") },
                { label = "Game Boy Advance", sub = "Handheld shell", id = "GBA1",
                  run = bezel("gba_b_1.png", "GBA1", 240, 60, 1440, 960, "GBA BG 1") },
                { label = "Full 4:3", sub = "Plain frame", id = "F4.3_1",
                  run = bezel("f43_b_1.png", "F4.3_1", 240, 0, 1440, 1080, "Full 4:3") },
            },
        },
    },
    clear = { label = "Clear", id = "", run = function()
        mp.commandv("script-message", "clear-bezel", "silent")
        osd("Bezel cleared")
    end },
}
-- ---------- WINDOW ----------
SECTIONS[7] = {
    name = "Window",
    icon = "window",
    rows = function()
        return {
            { label = "SIZE", kind = "head" },
            { label = "Scale 50%", kind = "action", run = cmd("set window-scale 0.5") },
            { label = "Scale 75%", kind = "action", run = cmd("set window-scale 0.75") },
            { label = "Scale 100%", kind = "action", run = cmd("set window-scale 1.0") },
            { label = "Scale 125%", kind = "action", run = cmd("set window-scale 1.25") },
            { label = "Fullscreen", kind = "action", run = cmd("cycle fullscreen") },
            { label = "ROTATION", kind = "head" },
            { label = "Rotate 0", kind = "action", run = cmd("set video-rotate 0") },
            { label = "Rotate 90", kind = "action", run = cmd("set video-rotate 90") },
            { label = "Rotate 180", kind = "action", run = cmd("set video-rotate 180") },
            { label = "Rotate 270", kind = "action", run = cmd("set video-rotate 270") },
            { label = "OPTIONS", kind = "head" },
            { label = "Window Border", kind = "action", run = cmd("cycle border"),
              value = function()
                  return mp.get_property_native("border") and "ON" or "OFF"
              end },
            { label = "Always On Top", kind = "action", run = cmd("cycle ontop"),
              value = function()
                  return mp.get_property_native("ontop") and "ON" or "OFF"
              end },
            { label = "Stretch 2.35:1", kind = "action",
              run = cmd('cycle-values video-aspect-override "2.35:1" "16:9"') },
            { label = "Mini Mode", kind = "action",
              run = cmd('set window-scale 0.3 ; set geometry 0%:100%') },
            { label = "Mirror Mode", kind = "action",
              run = function() mp.commandv("script-message", "toggle-mirror") end },
        }
    end,
}

-- ---------- VIDEO ----------
-- Capture resolution / frame rate. The format is fixed when mpv opens the
-- DirectShow device, so switching relaunches the video instance; ffplay is
-- left running, so audio and the Audio Boost level are not interrupted.
local function set_mode(id, label)
    return function()
        osd("Switching to " .. label .. "...")
        ps_async("data/set_mode.ps1", { "-Mode", id }, function() end)
    end
end

SECTIONS[8] = {
    name = "Video",
    icon = "video",
    rows = function()
        return {
            -- The chosen mode is saved to data\capture_mode.txt and reused
            -- on the next launch. Switching relaunches the video instance
            -- only, so audio and the Audio Boost level are not interrupted.
            { label = "CAPTURE MODE", kind = "head" },
            { label = "4K 60", kind = "action", run = set_mode("4k60", "4K 60"),
              value = function() return "MJPEG" end },
            { label = "4K 30", kind = "action", run = set_mode("4k30", "4K 30"),
              value = function() return "raw" end },
            { label = "1440p 60", kind = "action", run = set_mode("1440p60", "1440p 60"),
              value = function() return "raw" end },
            { label = "1440p 120", kind = "action", run = set_mode("1440p120", "1440p 120"),
              value = function() return "MJPEG" end },
            { label = "1080p 60", kind = "action", run = set_mode("1080p60", "1080p 60"),
              value = function() return "raw" end },
            { label = "1080p 120", kind = "action", run = set_mode("1080p120", "1080p 120"),
              value = function() return "MJPEG" end },
            { label = "720p 60", kind = "action", run = set_mode("720p60", "720p 60"),
              value = function() return "raw" end },
            { label = "PICTURE", kind = "head" },
            { label = "Toggle Deband", kind = "action", run = cmd("cycle deband"),
              value = function()
                  return mp.get_property_native("deband") and "ON" or "OFF"
              end },
            { label = "Toggle Deinterlace", kind = "action",
              run = cmd("cycle-values deinterlace yes no"),
              value = function()
                  return mp.get_property("deinterlace") == "yes" and "ON" or "OFF"
              end },
            { label = "Motion Interpolation", kind = "action",
              run = function()
                  mp.commandv("script-message-to", "toggle_motion_interpolation",
                      "toggle-motion-interpolation")
              end,
              value = function()
                  return mp.get_property_native("user-data/motion_interpolation")
                      and "ON" or "OFF"
              end },
            { label = "Auto ICC Profile", kind = "action",
              run = cmd("cycle icc-profile-auto"),
              value = function()
                  return mp.get_property_native("icc-profile-auto") and "ON" or "OFF"
              end },
            { label = "Fill Screen (Fullscreen)", kind = "action",
              run = cmd("cycle-values keepaspect yes no"),
              value = function()
                  return mp.get_property("keepaspect") == "no" and "FILL" or "FIT"
              end },
        }
    end,
}

-- ---------- TOOLS ----------
SECTIONS[9] = {
    name = "Tools",
    icon = "tools",
    rows = function()
        return {
            { label = "Bezel Manager", kind = "action",
              run = function() mp.commandv("script-message", "launch-bezel") end },
            { label = "Video Manager", kind = "action",
              run = function() mp.commandv("script-message", "launch-video") end },
            { label = "Stream Helper", kind = "action",
              run = function() mp.commandv("script-message", "launch-stream") end },
            { label = "INSTALLERS", kind = "head" },
            { label = "Run INSTALLER", kind = "action",
              run = function() mp.commandv("script-message", "launch-installer") end },
            { label = "Run SETUP", kind = "action",
              run = function() mp.commandv("script-message", "launch-setup") end },
            { label = "HELP", kind = "head" },
            { label = "Check Latest Version", kind = "action",
              run = function() mp.commandv("script-message", "check-version") end },
            { label = "Hide OSD Messages", kind = "action",
              run = function() mp.commandv("script-message", "toggle-osd") end,
              value = function()
                  return (mp.get_property_number("osd-duration") or 1000) == 0
                      and "HIDDEN" or "SHOWN"
              end },
            { label = "Info Stream", kind = "action",
              run = function() mp.commandv("script-message", "toggle-stats") end },
            { label = "EXIT", kind = "head" },
            { label = "Close MPV-SW-Capture", kind = "action", run = cmd("quit") },
        }
    end,
}

-- ============================================================
-- DRAWING HELPERS
-- ============================================================
local sx, sy = 1, 1   -- scale factors, recomputed per render

local function S(v) return v * sx end

local function rect(ass, x, y, w, h, colour, alpha)
    ass:new_event()
    ass:append(string.format("{\\pos(0,0)\\bord0\\shad0\\1c&H%s&\\1a&H%02X&}",
        colour, alpha or 0))
    ass:draw_start()
    ass:rect_cw(x, y, x + w, y + h)
    ass:draw_stop()
end

local function text(ass, x, y, s, colour, size, bold, align)
    ass:new_event()
    ass:append(string.format(
        "{\\pos(%.1f,%.1f)\\an%d\\bord0\\shad0\\1c&H%s&\\fs%.1f\\b%d\\fnSegoe UI}",
        x, y, align or 4, colour, size, bold and 1 or 0))
    ass:append(s:gsub("\\", "\\\\"):gsub("{", "\\{"):gsub("}", "\\}"))
end

-- ============================================================
-- RENDER
-- ============================================================
function render()
    if not visible then
        overlay.data = ""
        overlay:update()
        return
    end

    local ow = mp.get_property_number("osd-width") or REF_W
    local oh = mp.get_property_number("osd-height") or REF_H
    if ow <= 0 or oh <= 0 then ow, oh = REF_W, REF_H end

    -- Uniform scale keeps the panel's proportions; centre the result.
    sx = math.min(ow / REF_W, oh / REF_H)
    sy = sx
    local ox = (ow - REF_W * sx) / 2
    local oy = (oh - REF_H * sy) / 2

    local function X(v) return ox + v * sx end
    local function Y(v) return oy + v * sy end

    local ass = assdraw.ass_new()

    -- Reset hit regions for this frame (see `hit` above).
    hit.sidebar = {}
    hit.rows = {}
    hit.panel = { X(PANEL.x), Y(PANEL.y),
                  X(PANEL.x + PANEL.w), Y(PANEL.y + PANEL.h) }

    -- Scrim over the whole frame. Dark enough that the panel reads as the
    -- foreground; the feed stays faintly visible behind it.
    rect(ass, 0, 0, ow, oh, C.scrim, 0x28)

    -- Panel body + border
    rect(ass, X(PANEL.x) - 1, Y(PANEL.y) - 1,
         PANEL.w * sx + 2, PANEL.h * sy + 2, C.panel_edge, 0x10)
    rect(ass, X(PANEL.x), Y(PANEL.y), PANEL.w * sx, PANEL.h * sy, C.panel, 0x0A)

    -- ---------- HEADER ----------
    local hy = Y(PANEL.y)
    rect(ass, X(PANEL.x), hy + HEADER_H * sy, PANEL.w * sx, 1, C.panel_edge, 0x10)
    rect(ass, X(PANEL.x + 24), hy + 19 * sy, 4 * sx, 26 * sy, C.accent, 0)
    text(ass, X(PANEL.x + 38), hy + 32 * sy, "MPV-SW-CAPTURE", C.text_hi, 17 * sx, true)

    -- Live status (right side of header)
    local res = ""
    local w = mp.get_property_number("width")
    local h = mp.get_property_number("height")
    local fps = mp.get_property_number("estimated-vf-fps")
    if w and h then
        res = string.format("%dx%d", w, h)
        if fps and fps > 0 then res = res .. string.format("  %d fps", math.floor(fps + 0.5)) end
    else
        res = "no signal"
    end
    -- Right-aligned run: [dot] resolution/fps | ESC close
    -- Laid out right-to-left so the pieces never collide.
    local right = PANEL.x + PANEL.w - 24
    text(ass, X(right), hy + 32 * sy, "ESC close", C.text_faint, 13 * sx, false, 6)
    rect(ass, X(right - 96), hy + 21 * sy, 1, 22 * sy, C.panel_edge, 0x10)
    text(ass, X(right - 112), hy + 32 * sy, res, C.text, 13 * sx, false, 6)
    local dot_x = right - 112 - (#res * 6.6) - 14
    rect(ass, X(dot_x), hy + 28 * sy, 8 * sx, 8 * sy,
         (w and C.green or C.amber), 0)

    -- ---------- SIDEBAR ----------
    local sxb = X(PANEL.x)
    local syb = hy + HEADER_H * sy
    rect(ass, sxb + SIDEBAR_W * sx, syb, 1, (PANEL.h - HEADER_H) * sy, C.panel_edge, 0x10)

    local row_h = 40
    for i, sec in ipairs(SECTIONS) do
        local ry = syb + (14 + (i - 1) * row_h) * sy
        local is_sel = (i == section)
        hit.sidebar[i] = { sxb, ry, sxb + SIDEBAR_W * sx, ry + row_h * sy }
        if is_sel then
            rect(ass, sxb, ry, SIDEBAR_W * sx, row_h * sy, C.row_active, 0x18)
            rect(ass, sxb, ry, 3 * sx, row_h * sy, C.accent, 0)
        end
        text(ass, sxb + 24 * sx, ry + (row_h / 2) * sy, sec.name,
             is_sel and C.text_hi or C.text, 14 * sx, is_sel)

        local badge = sec.badge and sec.badge() or nil
        if badge then
            local bcol = (i == 2 and audio.boost and audio.boost > 100)
                and C.accent or C.text_faint
            text(ass, sxb + (SIDEBAR_W - 20) * sx, ry + (row_h / 2) * sy,
                 badge, bcol, 11 * sx, true, 6)
        end
    end

    -- Device footer
    local fy = Y(PANEL.y + PANEL.h) - 34 * sy
    rect(ass, sxb + 20 * sx, fy - 12 * sy, (SIDEBAR_W - 40) * sx, 1, C.panel_edge, 0x10)
    rect(ass, sxb + 20 * sx, fy + 3 * sy, 7 * sx, 7 * sy, C.green, 0)
    text(ass, sxb + 34 * sx, fy + 6 * sy, "UGREEN 25173", C.text_faint, 12 * sx, false)

    -- ---------- CONTENT ----------
    local cx = sxb + (SIDEBAR_W + 24) * sx
    local cw = (PANEL.w - SIDEBAR_W - 48)
    local cy = syb + 22 * sy

    local sec = SECTIONS[section]
    local active_id = sec.active and sec.active() or nil

    -- ---------- CARD GRID (Shaders etc.) ----------
    -- Category tabs across the top, then a grid of cards, matching the
    -- design canvas. Cards carry a preview block, a title and a subtitle.
    if sec.layout == "grid" then
        local ti = tab[section] or 1
        if ti > #sec.tabs then ti = 1 end
        local group = sec.tabs[ti]

        -- Tab strip
        local tx = cx
        local ty = cy
        hit.tabs = {}
        for i, t in ipairs(sec.tabs) do
            local tw = (#t.name * 7.4 + 30) * sx
            local on = (i == ti)
            rect(ass, tx, ty, tw, 30 * sy, on and C.accent or C.card,
                 on and 0 or 0x18)
            if not on then
                rect(ass, tx, ty, tw, 1, C.card_edge, 0x30)
                rect(ass, tx, ty + 29 * sy, tw, 1, C.card_edge, 0x30)
            end
            text(ass, tx + tw / 2, ty + 15 * sy, t.name,
                 on and C.panel or C.text, 13 * sx, on, 5)
            hit.tabs[i] = { tx, ty, tx + tw, ty + 30 * sy }
            tx = tx + tw + 8 * sx
        end

        -- "Clear" sits at the right end of the tab strip
        if sec.clear then
            local cwid = 74 * sx
            local cxx = cx + cw * sx - cwid
            rect(ass, cxx, ty, cwid, 30 * sy, C.card, 0x18)
            rect(ass, cxx, ty, cwid, 1, C.card_edge, 0x30)
            rect(ass, cxx, ty + 29 * sy, cwid, 1, C.card_edge, 0x30)
            text(ass, cxx + cwid / 2, ty + 15 * sy, sec.clear.label,
                 C.text_dim, 13 * sx, false, 5)
            hit.clear = { cxx, ty, cxx + cwid, ty + 30 * sy }
        else
            hit.clear = nil
        end

        -- Card grid: 3 columns, wrapping.
        local cols = 3
        local gap = 12 * sx
        local card_w = (cw * sx - gap * (cols - 1)) / cols
        local card_h = 104 * sy
        local gy = ty + 46 * sy

        hit.cards = {}
        for i, card in ipairs(group.cards) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local px = cx + col * (card_w + gap)
            local py = gy + row * (card_h + gap)

            if py + card_h > Y(PANEL.y + PANEL.h) - 30 * sy then break end

            local on = (active_id ~= nil and card.id == active_id)
            local sel = (i == cursor)

            -- Card body + border (accent border when active or selected)
            rect(ass, px, py, card_w, card_h,
                 (on or sel) and C.row_active or C.card, on and 0x08 or 0x18)
            local edge = on and C.accent or (sel and C.text_faint or C.card_edge)
            rect(ass, px, py, card_w, 1, edge, 0x10)
            rect(ass, px, py + card_h - 1, card_w, 1, edge, 0x10)
            rect(ass, px, py, 1, card_h, edge, 0x10)
            rect(ass, px + card_w - 1, py, 1, card_h, edge, 0x10)

            -- Preview block: a flat swatch standing in for the effect.
            -- libass cannot render a live shader thumbnail.
            local pv_h = 44 * sy
            rect(ass, px + 1, py + 1, card_w - 2, pv_h, C.track, 0x18)
            local inner = 22 * sy
            local ix = px + card_w / 2 - inner / 2
            local iy = py + 1 + pv_h / 2 - inner / 2
            local icol = on and C.accent or C.text_faint
            rect(ass, ix, iy, inner, 2 * sy, icol, 0x20)
            rect(ass, ix, iy + inner - 2 * sy, inner, 2 * sy, icol, 0x20)
            rect(ass, ix, iy, 2 * sx, inner, icol, 0x20)
            rect(ass, ix + inner - 2 * sx, iy, 2 * sx, inner, icol, 0x20)

            if on then
                rect(ass, px + 8 * sx, py + pv_h + 12 * sy, 6 * sx, 6 * sy, C.accent, 0)
            end
            text(ass, px + (on and 20 or 10) * sx, py + pv_h + 15 * sy,
                 card.label, (on or sel) and C.text_hi or C.text, 12.5 * sx, on or sel)
            if card.sub then
                text(ass, px + 10 * sx, py + pv_h + 33 * sy, card.sub,
                     C.text_faint, 10.5 * sx, false)
            end

            hit.cards[i] = { px, py, px + card_w, py + card_h, index = i }
        end

        -- Footer hint
        text(ass, cx, Y(PANEL.y + PANEL.h) - 18 * sy,
             "Arrow keys move  ENTER apply  TAB next section", C.text_faint, 11 * sx, false)

        overlay.res_x = ow
        overlay.res_y = oh
        overlay.data = ass.text
        overlay:update()
        return
    end

    hit.tabs, hit.cards, hit.clear = nil, nil, nil
    local rows = sec.rows()

    -- Rows visible at once (leaves room for the footer note)
    local avail = (PANEL.h - HEADER_H - 44 - (sec.footer and 34 or 0))
    local line_h = 34
    local max_rows = math.floor(avail / line_h)

    -- Keep the cursor in view
    if cursor < scroll + 1 then scroll = cursor - 1 end
    if cursor > scroll + max_rows then scroll = cursor - max_rows end
    if scroll < 0 then scroll = 0 end

    local drawn = 0
    for i = scroll + 1, #rows do
        if drawn >= max_rows then break end
        local r = rows[i]
        local ry = cy + drawn * line_h * sy

        -- Record this row's clickable bounds (headings are not clickable).
        if r.kind ~= "head" then
            hit.rows[#hit.rows + 1] = {
                x1 = cx - 10 * sx, y1 = ry,
                x2 = cx + (cw + 20) * sx, y2 = ry + line_h * sy,
                index = i, kind = r.kind, meter = r.meter,
            }
        end

        if r.kind == "head" then
            text(ass, cx, ry + 17 * sy, r.label, C.text_dim, 11 * sx, true)

        elseif r.kind == "meter" then
            local is_vol = (r.meter == "volume")
            local val, pct, colour, suffix

            if is_vol then
                val = audio.volume
                pct = (val or 0) / 100
                colour = C.blue
                suffix = val and (tostring(val) .. "%") or "--"
                if audio.muted then suffix = "MUTED" end
            else
                val = audio.boost or 100
                pct = (val - 100) / (BOOST_MAX - 100)
                colour = C.accent
                suffix = tostring(val) .. "%"
            end
            if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end

            local sel = (i == cursor)
            if sel then
                rect(ass, cx - 10 * sx, ry, (cw + 20) * sx, line_h * sy, C.row_active, 0x20)
            end

            text(ass, cx, ry + 17 * sy, r.label,
                 sel and C.text_hi or C.text, 13 * sx, sel)

            local bar_x = cx + 96 * sx
            local bar_w = (cw - 96 - 66) * sx

            -- Remember the track so a click/drag on it maps to a value.
            local hr = hit.rows[#hit.rows]
            if hr then hr.bar_x1 = bar_x; hr.bar_x2 = bar_x + bar_w end

            -- Slider: thin trough, filled portion, and a handle that rides
            -- the value. Scale ticks sit UNDER the trough rather than on it,
            -- so nothing looks like a stuck marker at rest.
            local tr_y = ry + 15 * sy
            local tr_h = 4 * sy
            rect(ass, bar_x, tr_y, bar_w, tr_h, C.track, 0x10)
            if pct > 0 then
                rect(ass, bar_x, tr_y, bar_w * pct, tr_h, colour, 0)
            end

            if not is_vol then
                for _, mark in ipairs({ 200, 300 }) do
                    local mx = bar_x + bar_w * ((mark - 100) / (BOOST_MAX - 100))
                    rect(ass, mx, tr_y + tr_h + 3 * sy, 1 * sx, 3 * sy, C.text_faint, 0x60)
                end
            end

            -- Handle, clamped so it stays fully inside the track at 0% / 100%.
            local hw = 4 * sx
            local hx = bar_x + (bar_w - hw) * pct
            rect(ass, hx, tr_y - 5 * sy, hw, tr_h + 10 * sy,
                 sel and C.text_hi or colour, 0)

            text(ass, cx + cw * sx, ry + 17 * sy, suffix,
                 is_vol and C.text_hi or C.accent, 15 * sx, true, 6)

            -- Show the adjust affordance only on the focused slider, so the
            -- panel stays quiet until a row is actually selected.
            if sel then
                text(ass, bar_x - 12 * sx, ry + 17 * sy, "<", C.text_faint, 13 * sx, true, 6)
                text(ass, bar_x + bar_w + 12 * sx, ry + 17 * sy, ">", C.text_faint, 13 * sx, true, 4)
            end

        else -- action
            local sel = (i == cursor)
            if sel then
                rect(ass, cx - 10 * sx, ry, (cw + 20) * sx, line_h * sy, C.row_active, 0x20)
                rect(ass, cx - 10 * sx, ry, 3 * sx, line_h * sy, C.accent, 0)
            end

            local is_on = (active_id ~= nil and r.id ~= nil and active_id == r.id)
            if is_on then
                rect(ass, cx, ry + 14 * sy, 6 * sx, 6 * sy, C.accent, 0)
            end

            text(ass, cx + (is_on and 16 or 0) * sx, ry + 17 * sy, r.label,
                 sel and C.text_hi or (is_on and C.accent_soft or C.text),
                 13 * sx, sel or is_on)

            local v = r.value and r.value() or nil
            if v then
                text(ass, cx + cw * sx, ry + 17 * sy, v,
                     v == "REC" and C.accent or C.text_faint, 12 * sx, true, 6)
            end
        end

        drawn = drawn + 1
    end

    -- Scroll indicator
    if #rows > max_rows then
        local frac = max_rows / #rows
        local tr_h = avail * sy
        local th = tr_h * frac
        local tp = (scroll / (#rows - max_rows)) * (tr_h - th)
        local bx = cx + (cw + 14) * sx
        rect(ass, bx, cy, 2 * sx, tr_h, C.panel_edge, 0x50)
        rect(ass, bx, cy + tp, 2 * sx, th, C.text_dim, 0x30)
    end

    -- Footer note
    if sec.footer then
        local fyy = Y(PANEL.y + PANEL.h) - 26 * sy
        text(ass, cx, fyy, sec.footer, C.text_faint, 11 * sx, false)
    end

    -- Draw in real OSD pixels. Without this the overlay keeps its default
    -- 1280x720 coordinate space and libass rescales everything a second
    -- time, which pushed the panel off-centre and clipped its right edge.
    overlay.res_x = ow
    overlay.res_y = oh
    overlay.data = ass.text
    overlay:update()
end

-- ============================================================
-- NAVIGATION
-- ============================================================
-- Cards in the active tab of a grid section, or nil for list sections.
local function grid_cards()
    local sec = SECTIONS[section]
    if sec.layout ~= "grid" then return nil end
    local ti = tab[section] or 1
    if ti > #sec.tabs then ti = 1 end
    return sec.tabs[ti].cards
end

local function selectable(rows, i)
    return rows[i] and rows[i].kind ~= "head"
end

local function move_cursor(delta)
    -- Grid sections move by whole rows (3 columns) for up/down.
    local cards = grid_cards()
    if cards then
        local step = (math.abs(delta) == 1) and (delta * 3) or delta
        local i = cursor + step
        if i < 1 then i = 1 elseif i > #cards then i = #cards end
        cursor = i
        render()
        return
    end

    local rows = SECTIONS[section].rows()
    local i = cursor
    for _ = 1, #rows do
        i = i + delta
        if i < 1 then i = #rows elseif i > #rows then i = 1 end
        if selectable(rows, i) then
            cursor = i
            render()
            return
        end
    end
end

local function first_selectable()
    if grid_cards() then return 1 end
    local rows = SECTIONS[section].rows()
    for i = 1, #rows do
        if selectable(rows, i) then return i end
    end
    return 1
end

local function switch_section(delta)
    section = section + delta
    if section < 1 then section = #SECTIONS elseif section > #SECTIONS then section = 1 end
    cursor = first_selectable()
    scroll = 0
    render()
end

-- Left/right adjust meters; otherwise they move between sections.
local function horizontal(dir)
    -- In a grid, left/right walks the cards; at a row edge it changes tab.
    local cards = grid_cards()
    if cards then
        local i = cursor + dir
        if i < 1 or i > #cards then
            local sec = SECTIONS[section]
            local ti = (tab[section] or 1) + dir
            if ti < 1 then ti = #sec.tabs elseif ti > #sec.tabs then ti = 1 end
            tab[section] = ti
            cursor = 1
        else
            cursor = i
        end
        render()
        return
    end

    local rows = SECTIONS[section].rows()
    local r = rows[cursor]
    if r and r.kind == "meter" then
        if r.meter == "volume" then
            vol_step(dir > 0 and "up" or "down", 5)
        else
            boost_step(dir * 25)
        end
        return
    end
    switch_section(dir)
end

local function activate()
    local cards = grid_cards()
    if cards then
        local c = cards[cursor]
        if c and c.run then c.run(); render() end
        return
    end

    local rows = SECTIONS[section].rows()
    local r = rows[cursor]
    if r and r.kind == "action" and r.run then
        r.run()
        render()
    end
end

-- ============================================================
-- MOUSE
-- Regions are captured during render() (see `hit`), so hit-testing always
-- matches what is actually on screen at the current window size.
-- ============================================================
local function inside(box, x, y)
    if not box then return false end
    local x1, y1, x2, y2 = box[1], box[2], box[3], box[4]
    if box.x1 then x1, y1, x2, y2 = box.x1, box.y1, box.x2, box.y2 end
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
end

-- Set a meter from an absolute x position on its track.
local function meter_from_x(hr, x)
    local frac = (x - hr.bar_x1) / (hr.bar_x2 - hr.bar_x1)
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end

    if hr.meter == "volume" then
        vol_set(math.floor(frac * 100 + 0.5))
    else
        -- Each boost change restarts ffplay, so a free drag would fire a
        -- restart per pixel. Snap to 25% and let the meter follow the
        -- cursor; the value is committed on release (see stop_drag).
        local v = clamp_boost(math.floor((100 + frac * (BOOST_MAX - 100)) / 25 + 0.5) * 25)
        if v ~= audio.boost then
            audio.boost = v          -- draw now, apply on release
            if visible then render() end
        end
    end
end

local dragging = nil   -- hit-row being dragged, or nil
local drag_timer = nil -- polls the cursor while a slider is held

local function mouse_pos()
    local m = mp.get_property_native("mouse-pos")
    if not m then return nil end
    return m.x, m.y
end

-- While a slider is held, poll the pointer on a timer. Observing
-- "mouse-pos" alone does not deliver updates reliably during a held
-- button, which made dragging behave like a single click.
local function start_drag(hr)
    dragging = hr
    if not drag_timer then
        drag_timer = mp.add_periodic_timer(0.03, function()
            if not (visible and dragging) then return end
            local x = mouse_pos()
            if x then meter_from_x(dragging, x) end
        end)
    end
    drag_timer:resume()
end

local function stop_drag()
    -- Commit a boost drag once, on release, rather than restarting ffplay
    -- repeatedly while the pointer moves.
    if dragging and dragging.meter == "boost" then
        local target = audio.boost
        audio.boost = nil            -- force boost_set to see a change
        boost_set(target)
    end
    dragging = nil
    if drag_timer then drag_timer:kill() end
end

local function on_mouse_move()
    if not visible then return end
    local x, y = mouse_pos()
    if not x then return end

    if dragging then
        meter_from_x(dragging, x)
        return
    end

    -- Hover highlights the row under the cursor.
    for _, hr in ipairs(hit.rows) do
        if inside(hr, x, y) then
            if cursor ~= hr.index then
                cursor = hr.index
                render()
            end
            return
        end
    end
end

local function on_mouse_down()
    if not visible then return end
    local x, y = mouse_pos()
    if not x then return end

    -- Clicking outside the panel closes it.
    if not inside(hit.panel, x, y) then
        hide()
        return
    end

    for i, box in ipairs(hit.sidebar) do
        if inside(box, x, y) then
            if section ~= i then
                section = i
                cursor = first_selectable()
                scroll = 0
                render()
            end
            return
        end
    end

    -- Grid sections: category tabs, the Clear button, and cards.
    if hit.tabs then
        for i, box in ipairs(hit.tabs) do
            if inside(box, x, y) then
                tab[section] = i
                cursor = 1
                render()
                return
            end
        end
    end
    if hit.clear and inside(hit.clear, x, y) then
        local sec = SECTIONS[section]
        if sec.clear and sec.clear.run then sec.clear.run() end
        render()
        return
    end
    if hit.cards then
        for i, box in ipairs(hit.cards) do
            if inside(box, x, y) then
                cursor = i
                activate()
                return
            end
        end
    end

    for _, hr in ipairs(hit.rows) do
        if inside(hr, x, y) then
            cursor = hr.index
            if hr.kind == "meter" and hr.bar_x1 then
                -- Click anywhere on the track jumps there; holding drags.
                -- Anywhere on the row starts a drag, so grabbing the handle
                -- does not require pixel-accurate aim.
                start_drag(hr)
                meter_from_x(hr, x)
            else
                activate()
            end
            return
        end
    end

    render()
end

local function on_mouse_up()
    stop_drag()
end

-- ============================================================
-- KEY BINDINGS (only while the overlay is open)
-- ============================================================
local KEYS = {
    { "UP",     function() move_cursor(-1) end },
    { "DOWN",   function() move_cursor(1) end },
    { "LEFT",   function() horizontal(-1) end },
    { "RIGHT",  function() horizontal(1) end },
    { "ENTER",  activate },
    { "KP_ENTER", activate },
    { "TAB",    function() switch_section(1) end },
    { "PGUP",   function() switch_section(-1) end },
    { "PGDWN",  function() switch_section(1) end },
    { "WHEEL_UP",   function() move_cursor(-1) end },
    { "WHEEL_DOWN", function() move_cursor(1) end },
}

local bound = false

local function bind_keys()
    if bound then return end
    for i, k in ipairs(KEYS) do
        mp.add_forced_key_binding(k[1], "msc_overlay_" .. i, k[2], { repeatable = true })
    end
    mp.add_forced_key_binding("ESC", "msc_overlay_esc", function() hide() end)
    mp.add_forced_key_binding("MBTN_RIGHT", "msc_overlay_rmb", function() hide() end)

    -- Mouse: click to select/activate, hold to drag a slider.
    mp.add_forced_key_binding("MBTN_LEFT", "msc_overlay_lmb", function(t)
        if t.event == "down" then
            on_mouse_down()
        elseif t.event == "up" then
            on_mouse_up()
        end
    end, { complex = true })

    mp.observe_property("mouse-pos", "native", on_mouse_move)
    bound = true
end

local function unbind_keys()
    if not bound then return end
    for i = 1, #KEYS do
        mp.remove_key_binding("msc_overlay_" .. i)
    end
    mp.remove_key_binding("msc_overlay_esc")
    mp.remove_key_binding("msc_overlay_rmb")
    mp.remove_key_binding("msc_overlay_lmb")
    mp.unobserve_property(on_mouse_move)
    stop_drag()
    bound = false
end

-- ============================================================
-- SHOW / HIDE
-- ============================================================
local saved_cursor_autohide = nil

function show()
    if visible then return end
    visible = true
    cursor = first_selectable()
    -- The app hides the pointer after 100ms; keep it up while the menu is
    -- open so it can actually be clicked.
    saved_cursor_autohide = mp.get_property("cursor-autohide")
    mp.set_property("cursor-autohide", "no")
    bind_keys()
    refresh_audio()
    render()
end

function hide()
    if not visible then return end
    visible = false
    unbind_keys()
    if saved_cursor_autohide then
        mp.set_property("cursor-autohide", saved_cursor_autohide)
        saved_cursor_autohide = nil
    end
    overlay.data = ""
    overlay:update()
end

local function toggle()
    if visible then hide() else show() end
end

mp.add_key_binding(nil, "toggle-overlay", toggle)
mp.register_script_message("toggle-overlay", toggle)
mp.register_script_message("close-overlay", hide)

-- Repaint when the window is resized while open.
mp.observe_property("osd-width", "number", function()
    if visible then render() end
end)

-- Keep the recording badge live.
mp.observe_property("user-data/is_recording", "native", function()
    if visible then render() end
end)

mp.register_event("shutdown", function() unbind_keys() end)

msg.info("MSC overlay loaded. Use script-message toggle-overlay.")
