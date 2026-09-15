-- Run with mpv.exe --no-config --load-scripts=no --idle=yes --vo=null --ao=null --script=tests/edge_hover.lua
local real_mp = require "mp"
local function test()
    local file = assert(io.open("scripts/msc_overlay.lua", "r"))
    local source = file:read("*a")
    file:close()
    assert(loadstring(source))
    local first = assert(source:find("local edge_mouse_initialized", 1, true))
    local last = assert(source:find("-- Input handling", first, true))
    local checks = [[
local mouse, visible, edge_visible, edge_drag, edge_hit, edge_hide_timer
local edge_enabled = true
local shows, drags = 0, 0
local mp = {}
function mp.get_property_native() return mouse end
function mp.add_timeout(delay, callback)
    assert(delay == 1)
    return { callback = callback }
end
local function edge_hide() edge_visible = false; edge_hide_timer = nil end
local function edge_show()
    shows = shows + 1
    edge_visible = true
    edge_hide_timer = nil
    edge_hit = { panel = { 0, 100, 104, 360 } }
end
local function inside(b, x, y)
    return x >= b[1] and x <= b[3] and y >= b[2] and y <= b[4]
end
local function edge_set_from_y() drags = drags + 1 end
]] .. source:sub(first, last - 1) .. [[
mouse = { x = 0, y = 0, hover = true }
edge_mousemove()
assert(shows == 0, "initial snapshot must not reveal")
edge_mousemove()
assert(shows == 0, "unchanged snapshot must not reveal")
mouse = { x = 0, y = 20, hover = false }
edge_mousemove()
assert(shows == 0, "outside-window coordinates must not reveal")
mouse = { x = 5, y = 200, hover = true }
edge_mousemove()
assert(shows == 1, "real edge movement reveals")
mouse.x = 70
edge_mousemove()
assert(edge_visible and not edge_hide_timer, "panel stays open")
mouse.x = 200
edge_mousemove()
assert(edge_hide_timer, "leaving panel schedules hide")
mouse.x = 70
edge_mousemove()
assert(not edge_hide_timer, "returning cancels hide")
edge_drag = true
mouse.x = 300
edge_mousemove()
assert(drags == 1 and not edge_hide_timer, "drag continues outside panel")
edge_drag = false
mouse.hover = false
edge_mousemove()
assert(edge_hide_timer, "leaving window schedules hide")
edge_hide_timer.callback()
assert(not edge_visible)
visible = true
local before = shows
mouse = { x = 2, y = 200, hover = true }
edge_mousemove()
assert(shows == before, "main menu suppresses sidebar")
visible = false
edge_enabled = false
mouse.x = 4
edge_mousemove()
assert(shows == before, "disabled sidebar ignores edge movement")
edge_enabled = true
mouse.x = 6
edge_mousemove()
assert(shows == before + 1, "re-enabled sidebar reveals normally")
]]
    assert(loadstring(checks))()
    local function block(first_marker, last_marker)
        local start = assert(source:find(first_marker, 1, true))
        local finish = assert(source:find(last_marker, start, true))
        return source:sub(start, finish - 1)
    end
    local settings_checks = [[
local saved, property, hidden, rendered, fail_write
local visible = true
local function getroot() return "test-root" end
local function edge_hide() hidden = true end
local function render() rendered = true end
local function osd() end
local msg = { error = function() end }
local mp = { set_property_bool = function(_, value) property = value end }
local settings = {
    read = function(name) assert(name == "hover_volume.txt"); return saved end,
    write = function(name, value)
        assert(name == "hover_volume.txt")
        if fail_write then return false, "read-only" end
        saved = value; return true
    end,
}
]] .. block("local function load_edge_enabled()", "local function osd(s)")
    .. block("local function toggle_edge_enabled()", "local function edge_show()") .. [[
assert(edge_enabled and property, "new installations default to enabled")
toggle_edge_enabled()
assert(not edge_enabled and not property and hidden and rendered, "disable applies immediately")
assert(saved == "no\n" and not load_edge_enabled(), "disabled setting survives reload")
toggle_edge_enabled()
assert(edge_enabled and property and load_edge_enabled(), "enable survives reload")
fail_write = true
toggle_edge_enabled()
assert(edge_enabled and property, "failed save must not change active setting")
]]
    assert(loadstring(settings_checks))()
end
real_mp.add_timeout(0, function()
    local ok, err = pcall(test)
    if ok then print("PASS: edge hover startup and interaction") else print("FAIL: " .. tostring(err)) end
    real_mp.commandv("quit", ok and "0" or "1")
end)
