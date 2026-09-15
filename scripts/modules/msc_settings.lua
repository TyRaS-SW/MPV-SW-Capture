-- Portable menu state, with migration from the legacy data/ location.
local mp = require "mp"
local M = {}
local function root()
    return (mp.get_property("config-path") or "."):gsub("\\", "/")
end
local function read_path(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local value = f:read("*a")
    f:close()
    return value
end
function M.path(name)
    return root() .. "/data/menu/" .. name
end
function M.write(name, value)
    local path = M.path(name)
    local f, err = io.open(path, "w")
    if not f then
        -- Normally the shipped menu directory exists. Repair partial upgrades
        -- using a structured subprocess argument, without shell-built paths.
        mp.command_native({ name = "subprocess", playback_only = false,
            capture_stdout = true, capture_stderr = true,
            args = { "powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", root() .. "/data/menu_settings.ps1" } })
        f, err = io.open(path, "w")
    end
    if not f then return false, err end
    local written, write_err = f:write(value)
    local closed, close_err = f:close()
    return written ~= nil and closed ~= nil, write_err or close_err
end
function M.read(name)
    local value = read_path(M.path(name))
    if value ~= nil then return value end
    value = read_path(root() .. "/data/" .. name)
    if value ~= nil then
        -- Still honour the old preference if a read-only installation prevents
        -- migration. A failed write must not silently select a different mode.
        local ok, err = M.write(name, value)
        if not ok then mp.msg.warn("Cannot migrate " .. name .. ": " .. tostring(err)) end
    end
    return value
end
return M
