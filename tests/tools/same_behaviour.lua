-- Check that a refactor did not change what a module does (docs/overhaul/TESTING.md §3).
--
--   luajit tests/tools/same_behaviour.lua <scenario.lua> [git revision, default HEAD]
--
-- Runs the scenario's module twice without X-Plane (tests/lib/xtlua.lua): once
-- from the working tree and once with every file of the module's folder taken
-- from the git revision. Both runs get the same inputs every frame and the
-- same math.random seed. After every frame it compares every dataref either
-- run wrote, the commands run and the printed lines, at each frame period of
-- the scenario, and stops at the first difference.
--
-- A scenario file returns { module = "<main file>", seconds = n,
-- dt = {periods...}, setup = function(rt) end, inputs = function(rt, t) end }.
local xtlua = dofile("tests/lib/xtlua.lua")

local scenario_path, rev = arg[1], arg[2] or "HEAD"
assert(scenario_path, "usage: luajit tests/tools/same_behaviour.lua <scenario.lua> [revision]")
local scenario = dofile(scenario_path)

local function git(command)
    local pipe = assert(io.popen("git " .. command .. " 2>&1", "r"))
    local out = pipe:read("*a")
    local ok = pipe:close()
    return out, ok
end

-- every file of the module's folder at the revision
local dir = scenario.module:match("^(.*)/[^/]+$")
local old_files = {}
local listing = git("ls-tree --name-only " .. rev .. " " .. dir .. "/")
for path in listing:gmatch("[^\r\n]+") do
    local name = path:match("^.*/([^/]+)$")
    if name and name:match("%.lua$") then old_files[name] = git("show " .. rev .. ":" .. path) end
end
assert(next(old_files), "no Lua files in " .. dir .. " at " .. rev)

local function run(files, dt)
    math.randomseed(12345)
    local rt = xtlua.new()
    if scenario.setup then scenario.setup(rt) end
    rt:load(scenario.module, {files = files})
    rt:callout("flight_start")
    local frames = {}
    local t = 0
    while t < scenario.seconds do
        scenario.inputs(rt, t)
        rt:frame(dt)
        t = t + dt
        frames[#frames + 1] = {t = t, values = rt:snapshot(), commands = #rt.command_log, log = #rt.log}
    end
    return rt, frames
end

local function same_value(a, b)
    if type(a) == "table" and type(b) == "table" then
        for k, v in pairs(a) do if not same_value(v, b[k]) then return false end end
        for k in pairs(b) do if a[k] == nil then return false end end
        return true
    end
    if type(a) == "number" and type(b) == "number" then
        return a == b or (a ~= a and b ~= b)  -- NaN equals NaN here
    end
    return a == b
end

local function show(v)
    if type(v) ~= "table" then return tostring(v) end
    local parts = {}
    for i = 0, 15 do if v[i] ~= nil then parts[#parts + 1] = tostring(v[i]) end end
    return "{" .. table.concat(parts, ", ") .. (v[16] ~= nil and ", ..." or "") .. "}"
end

local failed = false
for _, dt in ipairs(scenario.dt) do
    local new_rt, new_frames = run({}, dt)
    local old_rt, old_frames = run(old_files, dt)
    local first
    for i = 1, math.min(#new_frames, #old_frames) do
        local a, b = new_frames[i], old_frames[i]
        local diffs = {}
        for name, v in pairs(a.values) do
            if not same_value(v, b.values[name]) then diffs[#diffs + 1] = name end
        end
        for name in pairs(b.values) do
            if a.values[name] == nil then diffs[#diffs + 1] = name end
        end
        if #diffs > 0 or a.commands ~= b.commands or a.log ~= b.log then
            first = {i = i, t = a.t, diffs = diffs, a = a, b = b}
            break
        end
    end
    if not first then
        for i = 1, #new_rt.command_log do
            local x, y = new_rt.command_log[i], old_rt.command_log[i]
            if not y or x.name ~= y.name or x.phase ~= y.phase then first = {i = i, what = "command " .. i} break end
        end
        for i = 1, #new_rt.log do
            if new_rt.log[i] ~= old_rt.log[i] then first = {i = i, what = "printed line " .. i} break end
        end
    end
    local written = 0
    for _ in pairs(new_frames[#new_frames].values) do written = written + 1 end
    if first then
        failed = true
        print(string.format("dt %.4f: DIFFERENT at frame %d (t %.3f s)", dt, first.i, first.t or 0))
        if first.what then print("  " .. first.what) end
        if first.a and first.a.commands ~= first.b.commands then
            print(string.format("  commands run so far: now %d, %s %d", first.a.commands, rev, first.b.commands))
        end
        if first.a and first.a.log ~= first.b.log then
            print(string.format("  printed lines so far: now %d, %s %d", first.a.log, rev, first.b.log))
        end
        table.sort(first.diffs or {})
        for k, name in ipairs(first.diffs or {}) do
            if k > 20 then print("  ...") break end
            print(string.format("  %s: now %s, %s %s", name, show(first.a.values[name]), rev, show(first.b.values[name])))
        end
    else
        print(string.format("dt %.4f: same over %d frames (%d datarefs written, %d commands, %d printed lines)",
            dt, #new_frames, written, #new_rt.command_log, #new_rt.log))
    end
end
if failed then os.exit(1) end
