-- Run from the project root:
-- mpv.exe --no-config --load-scripts=no --idle=yes --vo=null --ao=null --script=tests/launcher_process_scope.lua
local real_mp = require "mp"
local file = assert(io.open("scripts/sw-capture.lua", "r"))
local source = file:read("*a")
file:close()

local function check(name, processes, expected_launch, options)
    options = options or {}
    local launched, queries, quits, cleaned = false, 0, 0, false
    local mock_mp = {
        msg = { info = function() end, warn = function() end, error = function() end },
        get_opt = function() return options.skip end,
        get_property = function() return tostring(options.playlist or 0) end,
        commandv = function(command) assert(command == "quit"); quits = quits + 1 end,
        add_timeout = function(_, callback) callback() end,
    }
    function mock_mp.command_native(command)
        if command.args[1] == "cmd.exe" then
            launched = true -- Never launch real capture or watchdog processes.
            return {}
        end
        local ps = command.args[#command.args]
        if ps == "-CleanupOnly" then
            assert(command.args[#command.args - 1] == "C:\\Capture Test's\\data\\ffplay_watchdog.ps1")
            cleaned = true
            if not options.cleanup_fails then
                processes = processes:gsub("[^\n]*Name='ffplay'[^\n]*\n", "")
            end
            return { status = options.cleanup_fails and 1 or 0 }
        end
        if ps:find("Get-Process", 1, true) then
            queries = queries + 1
            -- Execute the production PowerShell filter against fixture process
            -- objects, including an installation path with spaces/apostrophes.
            command.args[#command.args] = [[
function Get-Process {
    param($Name, $ErrorAction)
    @(
]] .. processes .. [[
    ) | Where-Object { $_.Name -eq $Name }
}
]] .. ps
            local result = real_mp.command_native(command)
            assert(result and result.status == 0, result and result.stderr or "subprocess failed")
            return result
        end
        assert(ps:find("System.Threading.Mutex", 1, true))
        return { status = 0, stdout = options.busy and "LOCK_FAIL" or "LOCK_OK" }
    end
    local run = assert(loadstring(source, "@C:/Capture Test's/scripts/sw-capture.lua"))
    setfenv(run, setmetatable({ mp = mock_mp, io = {
        open = function(path)
            assert(path == "C:\\Capture Test's\\data\\MPV-SW-Capture.bat")
            return { close = function() end }
        end,
    } }, { __index = _G }))
    run()
    assert(launched == expected_launch, name .. ": unexpected launch decision")
    assert(queries == ((options.skip or options.playlist) and 0 or (cleaned and 3 or 2)), name .. ": query count")
    assert(cleaned == (options.cleanup or false), name .. ": cleanup decision")
    real_mp.msg.info("PASS: " .. name)
end

real_mp.add_timeout(0, function()
    local ok, err = pcall(function()
        local own = "[pscustomobject]@{ Name='mpv'; Path='C:\\Capture Test''s\\mpv.exe' }\n"
        local unrelated = "[pscustomobject]@{ Name='mpv'; Path='C:\\Program Files\\Fred TV\\deps\\mpv.exe' }\n"
            .. "[pscustomobject]@{ Name='ffplay'; Path='C:\\Other App\\ffplay.exe' }\n"
            .. "[pscustomobject]@{ Name='mpv'; Path=$null }\n"
        check("unrelated players do not block startup", own .. unrelated, true)
        check("existing capture MPV blocks duplicate startup", own .. own .. unrelated, false)
        local orphan = "[pscustomobject]@{ Name='ffplay'; Path='c:\\capture test''s\\FFPLAY.EXE' }\n"
        check("orphaned capture FFplay is cleaned before startup", own .. orphan, true, { cleanup = true })
        check("failed orphan cleanup blocks startup", own .. orphan, false, { cleanup = true, cleanup_fails = true })
        check("active capture audio is never cleaned", own .. own .. orphan, false)
        check("busy mutex still blocks startup", own, false, { busy = true })
        check("capture playback skips launcher", "", false, { playlist = 1 })
        check("setup skip flag skips launcher", "", false, { skip = "1" })
    end)
    if not ok then real_mp.msg.error(tostring(err)) end
    real_mp.commandv("quit", ok and "0" or "1")
end)
