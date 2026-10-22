-- Run XTLua script modules without X-Plane (docs/overhaul/TESTING.md §3).
--
-- Each module is loaded the way XTLua loads it: a fresh Lua environment runs
-- the real plugins/<instance>/init.lua, then run_module_in_namespace() runs
-- the module's main file in a namespace, and dofile() inside the module reads
-- files from the module's folder. The C functions init.lua calls
-- (XTLuaFindDataRef, XTLuaGetNumber, ...) are supplied from an in-memory
-- dataref store shared by all modules of one runtime.
--
-- Differences from X-Plane, on purpose:
--   * reads and writes are immediate. In X-Plane, XTLua copies values between
--     the sim and the worker thread once a frame, and the first read of a
--     dataref in a module returns 0.
--   * nothing else moves the datarefs: the test sets the inputs.
--
--   local xtlua = dofile("tests/lib/xtlua.lua")
--   local rt = xtlua.new()
--   local hyd = rt:load("plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/B747.19.xt.hydraulicsmodel.lua")
--   rt:set("sim/time/total_running_time_sec", 10)
--   rt:callout("flight_start")
--   for i = 1, 300 do rt:frame(1 / 30) end
--   print(rt:get("laminar/B747/hydraulics/pressure_1"))
local source = dofile("tests/lib/source.lua")

local M = {}

-- X-Plane's folder, for Resources/plugins/DataRefs.txt (dataref types)
M.xplane_root = os.getenv("XPLANE_ROOT") or "../.."

-- Run every init script (plugins/*/init/scripts/<m>/<m>.lua) the way XLua
-- runs it, with C functions that only record the datarefs it creates, and
-- return name -> type ("number", "string", "array[n]"). Running them, rather
-- than reading the text, also catches types built at run time
-- ("array[" .. NUM_BTN_SW .. "]"). A script that fails is reported in
-- M.init_errors.
M.init_errors = {}
local function init_script_types()
    local types = {}
    local function noop() end
    for _, path in ipairs(source.lua_files()) do
        local instance, mod = path:match("^(plugins/[^/]+)/init/scripts/([^/]+)/[^/]+%.lua$")
        if instance and path == instance .. "/init/scripts/" .. mod .. "/" .. mod .. ".lua" then
            local dir = instance .. "/init/scripts/" .. mod
            local env = setmetatable({}, {__index = _G})
            env._G = env  -- the script state's globals: namespaces fall back to them
            env.XLuaCreateDataRef = function(name, t) types[name] = t return name end
            env.XLuaFindDataRef = function(name) return name end
            env.XLuaGetDataRefType = function(name) return types[name] or "unknown" end
            env.XLuaGetNumber = function() return 0 end
            env.XLuaGetString = function() return "" end
            env.XLuaGetArray = function() return 0 end
            env.XLuaCreateCommand = function(name) return {name = name} end
            env.XLuaFindCommand = function(name) return {name = name} end
            -- XlLuaReplaceCommand is spelled so in the XTLua binary and init/init.lua
            for _, f in ipairs({"XLuaSetNumber", "XLuaSetString", "XLuaSetArray", "XlLuaReplaceCommand",
                    "XLuaWrapCommand", "XLuaCommandStart", "XLuaCommandStop", "XLuaCommandOnce", "XLuaRunTimer"}) do
                env[f] = noop
            end
            env.XLuaCreateTimer = function(func) return {func = func} end
            env.XLuaIsTimerScheduled = function() return false end
            env.XLuaGetCode = function(fname) return loadfile(dir .. "/" .. fname) end
            env.print = noop
            local ok, err = pcall(function()
                local init = assert(loadfile(instance .. "/init/init.lua"))
                setfenv(init, env)
                init()
                env.run_module_in_namespace(assert(loadfile(path)))
            end)
            if not ok then M.init_errors[#M.init_errors + 1] = path .. ": " .. tostring(err) end
        end
    end
    return types
end

local types_cache
-- name -> {type = "number"|"string"|"array[n]", int = true for int datarefs}
local function dataref_types()
    if types_cache then return types_cache end
    local types = {}
    local file = io.open(M.xplane_root .. "/Resources/plugins/DataRefs.txt", "rb")
    M.datarefs_txt_found = file ~= nil
    if file then
        for line in file:lines() do
            local name, t = line:match("^(%S+)\t(%S+)")
            if name then
                local base, n = t:match("^(%a+)%[(%d+)%]$")
                if base == "byte" then
                    types[name] = {type = "string"}
                elseif base then
                    types[name] = {type = "array[" .. n .. "]", int = base == "int"}
                elseif t == "float" or t == "double" or t == "int" then
                    types[name] = {type = "number", int = t == "int"}
                end
            end
        end
        file:close()
    end
    for name, t in pairs(init_script_types()) do types[name] = {type = t} end
    types_cache = types
    return types
end

local function truncate(v)
    if type(v) ~= "number" then return v end
    return v >= 0 and math.floor(v) or math.ceil(v)
end

local Runtime = {}
Runtime.__index = Runtime

-- opts.types: extra name -> type ("number", "string", "array[n]") for
-- datarefs the scripts' init files and DataRefs.txt do not know.
function M.new(opts)
    opts = opts or {}
    local rt = setmetatable({
        types = {},
        values = {},      -- name -> number, string, or table indexed from 0
        written = {},     -- names a module wrote (set/array write), for snapshots
        modules = {},
        commands = {},    -- name -> {handler, before, after} from replace/wrap
        command_log = {}, -- {name, phase} for every start/stop/once from a module
        log = {},         -- print() output
        time = 0,
    }, Runtime)
    for name, t in pairs(dataref_types()) do rt.types[name] = t end
    for name, t in pairs(opts.types or {}) do rt.types[name] = {type = t} end
    return rt
end

function Runtime:type_of(name)
    local t = self.types[name]
    if t then return t.type end
    if name:sub(1, 6) == "xtlua/" then return "string" end
    return "unknown"
end

local function array_size(t)
    return tonumber(t:match("%[(%d+)%]$"))
end

-- the stored value, created with the dataref's zero on first use
function Runtime:raw(name)
    local v = self.values[name]
    if v ~= nil then return v end
    local t = self:type_of(name)
    if t == "number" then v = 0
    elseif t == "string" then v = ""
    elseif array_size(t) then
        v = {}
        for i = 0, array_size(t) - 1 do v[i] = 0 end
    else
        return nil
    end
    self.values[name] = v
    return v
end

-- Test side: read or write a dataref. Arrays take an index, or "name[i]".
local function split(name, index)
    if index == nil then
        local base, i = name:match("^(.-)%[(%d+)%]$")
        if base then return base, tonumber(i) end
    end
    return name, index
end

function Runtime:get(name, index)
    name, index = split(name, index)
    local v = self:raw(name)
    if type(v) == "table" then
        if index == nil then return v end
        return v[index] or 0
    end
    return v
end

function Runtime:set(name, a, b)
    local index, value
    if b ~= nil then index, value = a, b else value = a end
    name, index = split(name, index)
    local t = self.types[name]
    local int = t and t.int
    if int then value = truncate(value) end
    local v = self:raw(name)
    if type(v) == "table" then
        if type(value) == "table" then
            for i, x in pairs(value) do v[i] = int and truncate(x) or x end
        else
            v[index or 0] = value
        end
    elseif v ~= nil then
        self.values[name] = value
    else
        -- X-Plane would not have it either: pass its type in new{types = ...}
        -- if another plugin creates it
        error("set: unknown dataref " .. name, 2)
    end
end

-- The C functions XTLua's init.lua expects, bound to this runtime.
local function c_functions(rt, module)
    local c = {}
    c.XTLuaFindDataRef = function(name) return name end
    c.XTLuaGetDataRefType = function(name) return rt:type_of(name) end
    c.XTLuaGetNumber = function(name)
        local v = rt:raw(name)
        if type(v) == "number" then return v end
        return 0
    end
    c.XTLuaSetNumber = function(name, v)
        if rt:type_of(name) ~= "number" then return end
        -- a non-number (for example a dataref object, when a module binds
        -- the same global twice) is taken as the C API takes it
        v = tonumber(v) or 0
        local t = rt.types[name]
        if t and t.int then v = truncate(v) end
        rt.values[name] = v
        rt.written[name] = true
    end
    c.XTLuaGetString = function(name)
        local v = rt:raw(name)
        if type(v) == "string" then return v end
        return ""
    end
    c.XTLuaSetString = function(name, v)
        if rt:type_of(name) ~= "string" then return end
        -- a table (a module binding the same global twice) writes nothing
        if type(v) ~= "string" and type(v) ~= "number" then return end
        rt.values[name] = tostring(v)
        rt.written[name] = true
    end
    c.XTLuaGetArray = function(name, i)
        local v = rt:raw(name)
        if type(v) ~= "table" then return 0 end
        return v[i] or 0
    end
    c.XTLuaSetArray = function(name, i, value)
        local v = rt:raw(name)
        if type(v) ~= "table" then return end
        i, value = tonumber(i) or 0, tonumber(value) or 0
        local size = array_size(rt:type_of(name))
        if i < 0 or (size and i >= size) then return end
        local t = rt.types[name]
        if t and t.int then value = truncate(value) end
        v[i] = value
        rt.written[name] = true
    end
    c.XTLuaFindCommand = function(name) return {name = name} end
    local function log_command(cmd, phase)
        rt.command_log[#rt.command_log + 1] = {name = cmd.name, phase = phase, module = module.name, time = rt.time}
    end
    c.XTLuaCommandStart = function(cmd) log_command(cmd, "start") end
    c.XTLuaCommandStop = function(cmd) log_command(cmd, "stop") end
    c.XTLuaCommandOnce = function(cmd) log_command(cmd, "once") end
    c.XTLuaReplaceCommand = function(cmd, func) rt.commands[cmd.name] = {handler = func, module = module} end
    c.XTLuaWrapCommand = function(cmd, before, after)
        rt.commands[cmd.name] = {before = before, after = after, module = module}
    end
    c.XTLuaCreateTimer = function(func) return {func = func} end
    c.XTLuaRunTimer = function(timer, delay, rep)
        if delay < 0 then
            module.timers[timer] = nil
        else
            timer.due = rt.time + delay
            timer.rep = rep
            module.timers[timer] = true
        end
    end
    c.XTLuaIsTimerScheduled = function(timer) return module.timers[timer] ~= nil end
    c.XLuaGetCode = function(fname)
        local text = module.files[fname]
        if text then return assert(loadstring(text, "@" .. module.dir .. "/" .. fname)) end
        local chunk, err = loadfile(module.dir .. "/" .. fname)
        if not chunk then error("dofile " .. fname .. ": " .. tostring(err)) end
        return chunk
    end
    return c
end

-- Load a module from its main file. opts.files maps file names in the
-- module's folder to replacement source text (to run another version of a
-- file, for example from git). Returns the module; module.ns is its namespace.
function Runtime:load(main_path, opts)
    opts = opts or {}
    local dir, main_file = main_path:match("^(.*)/([^/]+)$")
    local instance = main_path:match("^(plugins/[^/]+)/")
    local module = {name = main_file, dir = dir, files = opts.files or {}, timers = {}}
    local env = setmetatable({}, {__index = _G})
    env._G = env  -- the module state's globals: the namespace falls back to them
    for k, f in pairs(c_functions(self, module)) do env[k] = f end
    env.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
        self.log[#self.log + 1] = module.name .. ": " .. table.concat(parts, " ")
    end
    local init = assert(loadfile(instance .. "/init.lua"))
    setfenv(init, env)
    init()
    module.env = env
    env.run_module_in_namespace(env.XLuaGetCode(main_file))
    module.ns = env.n
    self.modules[#self.modules + 1] = module
    return module
end

-- Call a callout (flight_start, before_physics, ...) in every module.
function Runtime:callout(name)
    for _, module in ipairs(self.modules) do
        module.env.n = module.ns
        module.env.do_callout(name)
    end
end

-- One frame: advance the sim clock, fire due timers, then before_physics and
-- after_physics in every module, in load order.
function Runtime:frame(dt)
    dt = dt or 1 / 30
    self.time = self.time + dt
    self:set("sim/time/total_running_time_sec", self.time)
    self:set("sim/operation/misc/frame_rate_period", dt)
    for _, module in ipairs(self.modules) do
        module.env.n = module.ns
        module.env.setup_callback_var("SIM_PERIOD", dt)
        module.env.setup_callback_var("IN_REPLAY", 0)
        local due = {}
        for timer in pairs(module.timers) do
            if timer.due <= self.time + 1e-9 then due[#due + 1] = timer end
        end
        for _, timer in ipairs(due) do
            if timer.rep and timer.rep > 0 then timer.due = timer.due + timer.rep
            else module.timers[timer] = nil end
            timer.func()
        end
    end
    self:callout("before_physics")
    self:callout("after_physics")
end

-- Run a command the way X-Plane calls a replaced command: phase 0 (begin),
-- then 1 (continue) for each frame of the duration, then 2 (end).
function Runtime:command(name, duration)
    local entry = self.commands[name]
    assert(entry, "no module handles command " .. name)
    local function call(phase, held)
        if entry.before then entry.before(phase, held) end
        if entry.handler then entry.handler(phase, held) end
        if entry.after then entry.after(phase, held) end
    end
    call(0, 0)
    local held = 0
    while duration and held < duration do
        self:frame(1 / 30)
        held = held + 1 / 30
        call(1, held)
    end
    call(2, held)
end

-- Every dataref a module has written, with its value (arrays copied).
function Runtime:snapshot()
    local out = {}
    for name in pairs(self.written) do
        local v = self.values[name]
        if type(v) == "table" then
            local copy = {}
            for i, x in pairs(v) do copy[i] = x end
            v = copy
        end
        out[name] = v
    end
    return out
end

return M
