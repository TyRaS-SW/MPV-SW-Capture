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

-- Creates the directory that contains `file_path` using cmd.exe's built-in
-- mkdir, which creates intermediate directories in one call. Lua has no
-- filesystem API beyond io.open (which does not create folders), so this
-- has to go through a subprocess. cmd.exe is far cheaper than PowerShell:
-- a few milliseconds and a couple of MB versus ~200 ms and ~30 MB, and it
-- removes the dependency on data/menu_settings.ps1.
local function ensure_parent_dir(file_path)
    local dir = file_path:match("^(.*)[/\\][^/\\]+$")
    if not dir or dir == "" then return end

    -- gsub returns two values (string and substitution count). Assigning to
    -- a local first keeps only the string when building the args array.
    local dir_win = dir:gsub("/", "\\")

    mp.command_native({
        name = "subprocess",
        playback_only = false,
        args = { "cmd.exe", "/c", "mkdir", dir_win }
    })
end

function M.write(name, value)
    local path = M.path(name)
    local f, err = io.open(path, "w")
    if not f then
        -- The menu directory is normally present. If it is missing (fresh
        -- install, partial upgrade, restored backup, read-only installation
        -- that gained write permission), create it and retry.
        ensure_parent_dir(path)
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