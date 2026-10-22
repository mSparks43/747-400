-- B747 flight-test recorder for FlyWithLua NG+ (X-Plane 12).
-- Part of the 747-400 overhaul flight-test kit (docs/overhaul/TESTING.md).
-- The master copy lives in the aircraft repository at tests/flight/fwl/;
-- copy it to X-Plane 12/Resources/plugins/FlyWithLua/Scripts/ to use it.
--
-- It records every frame while recording is on:
--   Output/B747_flighttest/session.csv  one row per frame. The first columns
--                                       match tests_old/data (t, alt, ias, vs,
--                                       pitch, thrust, tgt, flap, fma,
--                                       mcp_alt, window, weight, fd, q,
--                                       alpha, trim, elevator_ratio).
--   Output/B747_flighttest/events.csv   one row per change of the watched
--                                       states (FMA modes, A/P, air/ground,
--                                       flap handle).
--   Output/B747_flighttest/summary.txt  extremes over the recording, at stop.
-- Commands (also reachable through the X-Plane Web API):
--   FlyWithLua/B747_flighttest/start   start a new recording (overwrites)
--   FlyWithLua/B747_flighttest/stop    stop and write the summary
--   FlyWithLua/B747_flighttest/mark    add a "mark" row to events.csv
-- Does nothing unless the 747-400 is the user aircraft.

local VERSION = "3"

if not string.find(AIRCRAFT_PATH or "", "747-400", 1, true)
    or XPLMFindDataRef("laminar/B747/engines/type") == nil then
    logMsg("B747 flighttest: not the 747-400, recorder inactive")
    return
end

local OUT_DIR = SYSTEM_DIRECTORY .. "Output/B747_flighttest/"

-- column name, dataref, array index (nil for scalars), scale
local COLUMNS = {
    {"t"},
    {"alt", "sim/cockpit2/gauges/indicators/altitude_ft_pilot"},
    {"ias", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot"},
    {"vs", "sim/cockpit2/gauges/indicators/vvi_fpm_pilot"},
    {"pitch", "sim/flightmodel/position/theta"},
    {"thrust"},  -- mean of the four engines' POINT_thrust (N), as in tests_old/data
    {"tgt", "sim/cockpit2/autopilot/airspeed_dial_kts"},
    {"flap", "sim/cockpit2/controls/flap_ratio"},
    {"fma", "laminar/B747/autopilot/FMA/active_pitch_mode"},
    {"mcp_alt", "laminar/B747/autopilot/heading/altitude_dial_ft"},
    {"window", "laminar/B747/autopilot/ap_monitor/alt_capture_window"},
    {"weight", "sim/flightmodel/weight/m_total"},
    {"fd", "laminar/B747/autopilot/flight_director_pitch_deg"},
    {"q", "sim/flightmodel/position/Q"},
    {"alpha", "sim/flightmodel/position/alpha"},
    {"trim", "sim/flightmodel2/controls/elevator_trim"},
    -- pitch command to the elevators, -1..1 (the A/P's sim_pitch_ratio plus the
    -- yoke), as tests_old/data recorded it
    {"elevator_ratio", "laminar/B747/flt_ctrls/custom_pitch_ratio"},
    -- additions after the tests_old columns
    {"roll", "sim/flightmodel/position/phi"},
    {"hdg_mag", "sim/flightmodel/position/mag_psi"},
    {"gs_kt", "sim/flightmodel/position/groundspeed", nil, 1.943844},
    {"ra", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot"},
    {"gload", "sim/flightmodel/forces/g_nrml"},
    {"n1_1", "sim/flightmodel/engine/ENGN_N1_", 0}, {"n1_2", "sim/flightmodel/engine/ENGN_N1_", 1},
    {"n1_3", "sim/flightmodel/engine/ENGN_N1_", 2}, {"n1_4", "sim/flightmodel/engine/ENGN_N1_", 3},
    {"n2_1", "sim/flightmodel/engine/ENGN_N2_", 0}, {"n2_2", "sim/flightmodel/engine/ENGN_N2_", 1},
    {"n2_3", "sim/flightmodel/engine/ENGN_N2_", 2}, {"n2_4", "sim/flightmodel/engine/ENGN_N2_", 3},
    {"epr_1", "sim/flightmodel/engine/ENGN_EPR", 0}, {"epr_2", "sim/flightmodel/engine/ENGN_EPR", 1},
    {"epr_3", "sim/flightmodel/engine/ENGN_EPR", 2}, {"epr_4", "sim/flightmodel/engine/ENGN_EPR", 3},
    {"egt_1", "sim/flightmodel/engine/ENGN_EGT_c", 0}, {"egt_2", "sim/flightmodel/engine/ENGN_EGT_c", 1},
    {"egt_3", "sim/flightmodel/engine/ENGN_EGT_c", 2}, {"egt_4", "sim/flightmodel/engine/ENGN_EGT_c", 3},
    -- fuel flow as the aircraft's fuel system and EICAS read it (kg/s); ENGN_FF_
    -- goes negative while an engine starts
    {"ff_1", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", 0}, {"ff_2", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", 1},
    {"ff_3", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", 2}, {"ff_4", "sim/cockpit2/engine/indicators/fuel_flow_kg_sec", 3},
    {"thro_1", "sim/flightmodel/engine/ENGN_thro_use", 0}, {"thro_2", "sim/flightmodel/engine/ENGN_thro_use", 1},
    {"thro_3", "sim/flightmodel/engine/ENGN_thro_use", 2}, {"thro_4", "sim/flightmodel/engine/ENGN_thro_use", 3},
    {"fma_roll", "laminar/B747/autopilot/FMA/active_roll_mode"},
    {"fma_pitch_armed", "laminar/B747/autopilot/FMA/armed_pitch_mode"},
    {"fma_roll_armed", "laminar/B747/autopilot/FMA/armed_roll_mode"},
    {"fma_at", "laminar/B747/autopilot/FMA/autothrottle_mode"},
    {"servos_on", "laminar/B747/autopilot/servos_on"},
    {"on_ground", "sim/flightmodel/failures/onground_any"},
    {"frame_rate", "sim/operation/misc/frame_rate_period", nil, -1},  -- stored as frames per second
    {"sim_t", "sim/time/total_running_time_sec"},
    {"elev_deg", "laminar/B747/flt_ctrls/l_elev_inner"},  -- left inner elevator surface, deg
}
-- the four engines' thrust, for the "thrust" column
local THRUST = {{"sim/flightmodel/engine/POINT_thrust", 0}, {"sim/flightmodel/engine/POINT_thrust", 1},
    {"sim/flightmodel/engine/POINT_thrust", 2}, {"sim/flightmodel/engine/POINT_thrust", 3}}
-- states whose changes go to events.csv
local EVENTS = {"fma", "fma_roll", "fma_pitch_armed", "fma_roll_armed", "fma_at", "servos_on", "on_ground", "flap"}

-- Bind every column that exists in this X-Plane; a missing dataref leaves
-- its column empty and is logged once.
local bound = {}     -- column name -> global variable name
local scale = {}
local missing = {}
local function bind(var, name, index)
    if XPLMFindDataRef(name) == nil then return false end
    if index ~= nil then dataref(var, name, "readonly", index) else dataref(var, name, "readonly") end
    return true
end
for i, c in ipairs(COLUMNS) do
    if c[2] ~= nil then
        local var = "B747FT_c" .. i
        if bind(var, c[2], c[3]) then
            bound[c[1]] = var
            scale[c[1]] = c[4]
        else
            missing[#missing + 1] = c[2]
        end
    end
end
local thrust_vars = {}
for i, c in ipairs(THRUST) do
    local var = "B747FT_thrust" .. i
    if bind(var, c[1], c[2]) then thrust_vars[#thrust_vars + 1] = var end
end
if #missing > 0 then
    logMsg("B747 flighttest: datarefs not found, columns left empty: " .. table.concat(missing, ", "))
end

local function value(col)
    local var = bound[col]
    if var == nil then return nil end
    local v = _G[var]
    if v == nil then return nil end
    local s = scale[col]
    if s == -1 then return (v > 0) and (1 / v) or 0 end
    if s ~= nil then return v * s end
    return v
end
local function fmt(v)
    if v == nil then return "" end
    if v == math.floor(v) and math.abs(v) < 1e9 then return string.format("%d", v) end
    return string.format("%.4f", v)
end

local session, events = nil, nil
local buffer, buffered = {}, 0
local t0 = 0
local last = {}
local ext = {}
local function track(col, v)
    if v == nil then return end
    local e = ext[col]
    if e == nil then ext[col] = {min = v, max = v} return end
    if v < e.min then e.min = v end
    if v > e.max then e.max = v end
end

local function sim_time()
    local v = value("sim_t")
    return v or os.clock()
end

local function open(name)
    local f = io.open(OUT_DIR .. name, "w")
    if f == nil then
        -- the run script creates OUT_DIR; fall back to Output/ if it does not exist
        f = io.open(SYSTEM_DIRECTORY .. "Output/B747_flighttest_" .. name, "w")
    end
    return f
end

local function flush()
    if session ~= nil and buffered > 0 then
        session:write(table.concat(buffer))
        session:flush()
        buffer, buffered = {}, 0
    end
end

function B747FT_start()
    if session ~= nil then B747FT_stop() end
    session = open("session.csv")
    events = open("events.csv")
    if session == nil or events == nil then
        logMsg("B747 flighttest: cannot open the output files under " .. OUT_DIR)
        session, events = nil, nil
        return
    end
    local names = {}
    for _, c in ipairs(COLUMNS) do names[#names + 1] = c[1] end
    session:write(table.concat(names, ",") .. "\n")
    events:write("sim_t,t,state,from,to\n")
    t0 = sim_time()
    last, ext = {}, {}
    events:write(string.format("%s,0,start,,%s\n", fmt(t0), AIRCRAFT_FILENAME or ""))
    events:flush()
    logMsg("B747 flighttest: recording v" .. VERSION .. " to " .. OUT_DIR)
end

function B747FT_stop()
    if session == nil then return end
    flush()
    session:close()
    local t = sim_time() - t0
    events:write(string.format("%s,%s,stop,,\n", fmt(sim_time()), fmt(t)))
    events:close()
    session, events = nil, nil
    local f = open("summary.txt")
    if f ~= nil then
        f:write("B747 flighttest v" .. VERSION .. "  aircraft " .. (AIRCRAFT_FILENAME or "") .. "\n")
        f:write(string.format("duration_s %.2f\n", t))
        local cols = {}
        for col in pairs(ext) do cols[#cols + 1] = col end
        table.sort(cols)
        for _, col in ipairs(cols) do
            f:write(string.format("%s min %s max %s\n", col, fmt(ext[col].min), fmt(ext[col].max)))
        end
        f:close()
    end
    logMsg("B747 flighttest: stopped")
end

function B747FT_mark()
    if events == nil then return end
    events:write(string.format("%s,%s,mark,,\n", fmt(sim_time()), fmt(sim_time() - t0)))
    events:flush()
end

function B747FT_frame()
    if session == nil then return end
    local now = sim_time()
    local row = {}
    for i, c in ipairs(COLUMNS) do
        local v
        if c[1] == "t" then
            v = now - t0
        elseif c[1] == "thrust" then
            if #thrust_vars > 0 then
                local sum = 0
                for _, var in ipairs(thrust_vars) do sum = sum + (_G[var] or 0) end
                v = sum / #thrust_vars
            end
        else
            v = value(c[1])
        end
        row[i] = fmt(v)
        if c[1] ~= "t" and c[1] ~= "sim_t" then track(c[1], v) end
    end
    buffer[#buffer + 1] = table.concat(row, ",") .. "\n"
    buffered = buffered + 1
    for _, col in ipairs(EVENTS) do
        local v = value(col)
        if v ~= nil and last[col] ~= nil and v ~= last[col] then
            events:write(string.format("%s,%s,%s,%s,%s\n", fmt(now), fmt(now - t0), col, fmt(last[col]), fmt(v)))
        end
        last[col] = v
    end
    if buffered >= 60 then
        flush()
        events:flush()
    end
end

create_command("FlyWithLua/B747_flighttest/start", "B747 flight test: start recording", "B747FT_start()", "", "")
create_command("FlyWithLua/B747_flighttest/stop", "B747 flight test: stop recording", "B747FT_stop()", "", "")
create_command("FlyWithLua/B747_flighttest/mark", "B747 flight test: mark the event log", "B747FT_mark()", "", "")
do_every_frame("B747FT_frame()")
logMsg("B747 flighttest v" .. VERSION .. ": ready (" .. #COLUMNS .. " columns, " .. #missing .. " missing)")
