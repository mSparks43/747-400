-- Run from the repository root with LuaJIT: luajit tests/static/modules_run_test.lua
-- Every XTLua module of the aircraft (plugins/*/scripts/<m>/<m>.lua) loads the
-- way XTLua loads it, runs flight_start and 60 frames at 30 fps without a Lua
-- error (tests/lib/xtlua.lua: no X-Plane, every input dataref at 0). An error
-- here would stop the module in X-Plane too: it catches a broken dofile, a
-- missing function or a nil index before the aircraft is loaded.
local T = dofile("tests/lib/check.lua")("modules_run")
local xtlua = dofile("tests/lib/xtlua.lua")
local source = dofile("tests/lib/source.lua")

local modules = {}
for _, path in ipairs(source.lua_files()) do
    local instance, mod = path:match("^(plugins/[^/]+)/scripts/([^/]+)/[^/]+%.lua$")
    if instance and path == instance .. "/scripts/" .. mod .. "/" .. mod .. ".lua" then
        modules[#modules + 1] = path
    end
end
T.check(#modules >= 26, "found " .. #modules .. " modules, expected at least 26")
xtlua.new()  -- reads the dataref types
T.check(xtlua.datarefs_txt_found, "X-Plane's Resources/plugins/DataRefs.txt not found (set XPLANE_ROOT)")
T.equal(#xtlua.init_errors, 0, "init scripts that fail to run: " .. table.concat(xtlua.init_errors, "; "))

for _, path in ipairs(modules) do
    math.randomseed(1)
    local rt = xtlua.new()
    local stage = "load"
    local ok, err = pcall(function()
        rt:load(path)
        stage = "flight_start"
        rt:callout("flight_start")
        stage = "frames"
        for _ = 1, 60 do rt:frame(1 / 30) end
    end)
    T.check(ok, path .. " (" .. stage .. "): " .. tostring(err))
end
T.done()
