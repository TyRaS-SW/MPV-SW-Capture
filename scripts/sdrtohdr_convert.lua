-- sdrtohdr_convert.lua - For MPV-SW-Capture - By TyRaS-SW
-- SDR to HDR (Inverse Tone Mapping) + Full RGB (0-255) + ICC management.
--
-- Script messages (same as before, menu.conf needs no changes):
--   toggle-sdr-to-hdr
--   toggle-full-rgb
--   clean-all-colors   (used by menu.conf "Clean ALL")
-- user-data exposed (same as before):
--   user-data/sdr_to_hdr = "yes"/"no"
--   user-data/full_rgb   = "yes"/"no"
--
-- Rules:
--   * HDR ON  -> Auto ICC is forced OFF (and restored when HDR turns OFF).
--   * HDR ON  -> Full RGB only uses the input filter (colorlevels=full);
--                video-output-levels stays "auto" (the HDR chain handles output range).
--   * HDR OFF -> Full RGB uses filter + video-output-levels=full.
--   * Full RGB state follows the REAL filter (e.g. "Clean ALL" does "vf set ''").

local mp = require 'mp'
local msg = require 'mp.msg'

-- ---- user-tunable HDR values ----
local HDR_PEAK         = "1000"   -- set to your display's real peak nits (e.g. "600")
local HDR_TONE_MAPPING = "hable"  -- try "bt.2390" and compare
-- Saturation in mpv is a float in the range -100..100 (0 = neutral, NOT a multiplier).
-- 1.05 is essentially neutral (+1.05%); kept for visual parity with the old look.
-- If you want a real HDR saturation boost, try "5" (still a valid float).
local HDR_SATURATION   = "1.05"
local HDR_CONTRAST     = "2"      -- 0 = neutral

local root = (mp.get_property("config-path") or "."):gsub("\\", "/")
local hdr_path = root .. "/data/menu/sdr_to_hdr.txt"
local rgb_path = root .. "/data/menu/full_rgb.txt"

local VF_LABEL  = "@msc_fullrgb"
local VF_FILTER = VF_LABEL .. ":format=colorlevels=full"

local is_hdr       = false
local is_full_rgb  = false
local icc_saved    = false   -- true while we hold a saved ICC value
local saved_icc    = false
local rgb_confirmed = false  -- true once vf_add() has really succeeded at least once
local ready        = false   -- true after initial state was loaded

-- ---- osd_messages ----
local osd
local function get_script_path()
    local info = debug.getinfo(1, "S")
    if not info or not info.source then return "" end
    local dir = info.source:match("@?(.*[/\\])")
    if not dir then return "" end
    return dir:gsub("\\", "/")
end

local osd_path = get_script_path() .. "osd_messages.lua"

local ok, err = pcall(function()
    local loaded = dofile(osd_path)
    if loaded and type(loaded.get) == "function" and type(loaded.show) == "function" then
        osd = loaded
    else
        error("osd_messages.lua does not return a table with get/show functions")
    end
end)

if not ok then
    local defaults = {
        sdrtohdr_on      = "SDR to HDR: ON (Refined)",
        sdrtohdr_off     = "SDR to HDR: OFF (SDR Native)",
        fullrgb_on       = "Full RGB: ON (0-255)",
        fullrgb_off      = "Full RGB: OFF (Auto)",
        icc_disabled_hdr = "ICC disabled in HDR mode",
    }
    local function show_text(text, duration)
        local ms = mp.get_property_number("osd-duration") or 1000
        if ms == 0 then return end
        mp.osd_message(text, duration or ms / 1000)
    end
    osd = {
        get = function(key) return defaults[key] or key end,
        show = function(key, duration) show_text(osd.get(key), duration) end,
    }
    msg.warn("[sdrtohdr_convert] Using fallback messages: " .. tostring(err))
end

-- ---- persistence ----
local function save_flag(path, state)
    local f = io.open(path, "w")
    if f then
        f:write(state and "yes\n" or "no\n")
        f:close()
    end
end

local function read_flag(path)
    local f = io.open(path, "r")
    if not f then return false end
    local content = f:read("*a"):match("^%s*(.-)%s*$")
    f:close()
    return content == "yes"
end

-- ---- vf helpers (Full RGB filter) ----
local function vf_has_label()
    local vf = mp.get_property("vf") or ""
    return vf:find("msc_fullrgb", 1, true) ~= nil
end

local function vf_add()
    if vf_has_label() then return end
    mp.commandv("vf", "add", VF_FILTER)
end

local function vf_remove()
    if not vf_has_label() then return end
    local removed_ok = pcall(function()
        mp.commandv("vf", "remove", VF_LABEL)
    end)
    if not removed_ok then
        pcall(function() mp.commandv("vf", "remove", "format") end)
    end
end

-- ---- output levels: depends on BOTH states ----
local function apply_levels()
    if is_full_rgb and not is_hdr then
        mp.set_property("video-output-levels", "full")
    else
        mp.set_property("video-output-levels", "auto")
    end
end

local function publish_rgb_state()
    mp.set_property("user-data/full_rgb", is_full_rgb and "yes" or "no")
end

-- ---- HDR properties ----
local hdr_props = {
    {"target-colorspace-hint", "yes"},
    {"inverse-tone-mapping", "yes"},
    {"target-trc", "pq"},
    {"target-prim", "bt.2020"},
    {"tone-mapping", HDR_TONE_MAPPING},
    {"target-peak", HDR_PEAK},
    {"saturation", HDR_SATURATION},
    {"contrast", HDR_CONTRAST},
}

local sdr_props = {
    {"target-colorspace-hint", "no"},
    {"inverse-tone-mapping", "no"},
    {"target-trc", "auto"},
    {"target-prim", "auto"},
    {"tone-mapping", "auto"},
    {"target-peak", "auto"},
    {"saturation", "0"},
    {"contrast", "0"},
}

-- ---- apply HDR state ----
local function apply_hdr(state, silent)
    is_hdr = state  -- set first: the ICC observer reads it
    if state then
        -- Publish state FIRST so the overlay doesn't read a stale value
        -- and overwrite icc_profile.txt with the wrong preference.
        mp.set_property("user-data/sdr_to_hdr", "yes")
        if not icc_saved then
            saved_icc = mp.get_property_bool("icc-profile-auto", false)
            icc_saved = true
        end
        mp.set_property("icc-profile-auto", "no")
        for _, p in ipairs(hdr_props) do mp.set_property(p[1], p[2]) end
    else
        for _, p in ipairs(sdr_props) do mp.set_property(p[1], p[2]) end
        if icc_saved then
            mp.set_property_bool("icc-profile-auto", saved_icc)
            icc_saved = false
        end
        mp.set_property("user-data/sdr_to_hdr", "no")
    end
    apply_levels()  -- Full RGB output levels depend on HDR state
    save_flag(hdr_path, is_hdr)
    if not silent then osd.show(state and "sdrtohdr_on" or "sdrtohdr_off", 2) end
end

-- ---- apply Full RGB state ----
local function apply_full_rgb(state, silent)
    is_full_rgb = state
    if state then vf_add() else vf_remove() end
    apply_levels()
    publish_rgb_state()
    save_flag(rgb_path, is_full_rgb)
    if not silent then osd.show(state and "fullrgb_on" or "fullrgb_off", 2) end
end

-- ---- toggles ----
mp.register_script_message("toggle-sdr-to-hdr", function()
    apply_hdr(not is_hdr, false)
end)

mp.register_script_message("toggle-full-rgb", function()
    -- decide from the REAL filter state, not from the variable
    apply_full_rgb(not vf_has_label(), false)
end)

-- ---- Clean ALL: reset color but respect HDR look ----
-- Replaces the old inline "set contrast 0 ; set brightness 0 ; set gamma 0 ;
-- set saturation 0 ; set hue 0" block from menu.conf.
mp.register_script_message("clean-all-colors", function()
    mp.set_property("brightness", "0")
    mp.set_property("gamma", "0")
    mp.set_property("hue", "0")
    if is_hdr then
        -- HDR is active: restore the HDR-specific color values
        mp.set_property("saturation", HDR_SATURATION)
        mp.set_property("contrast", HDR_CONTRAST)
    else
        -- Normal neutral reset
        mp.set_property("saturation", "0")
        mp.set_property("contrast", "0")
    end
end)

-- ---- keep ICC off while HDR is active ----
mp.observe_property("icc-profile-auto", "bool", function(_, v)
    if is_hdr and v then
        mp.set_property("icc-profile-auto", "no")
        osd.show("icc_disabled_hdr", 2)
    end
end)

-- ---- keep Full RGB state in sync with the real filter ----
-- (e.g. "Clean ALL" runs `vf set ""` and removes the filter behind our back)
mp.observe_property("vf", "native", function()
    if not ready then return end
    local has = vf_has_label()
    if has then rgb_confirmed = true end
    if has ~= is_full_rgb then
        is_full_rgb = has
        apply_levels()
        publish_rgb_state()
        -- Only persist once we know vf_add() has actually worked at least once,
        -- otherwise a failed start-up add would overwrite "yes" with "no".
        if rgb_confirmed then save_flag(rgb_path, is_full_rgb) end
    end
end)

-- ---- startup ----
local initial_state_applied = false

local function load_initial_state()
    if initial_state_applied then return end
    initial_state_applied = true

    -- HDR first, then Full RGB (levels depend on HDR state)
    if read_flag(hdr_path) then
        apply_hdr(true, true)
    else
        mp.set_property("user-data/sdr_to_hdr", "no")
    end

    if read_flag(rgb_path) then
        apply_full_rgb(true, true)
    else
        mp.set_property("user-data/full_rgb", "no")
    end

    ready = true
end

mp.observe_property("vo-configured", "bool", function(_, val)
    if val then load_initial_state() end
end)
mp.add_timeout(1.0, load_initial_state)