-- Run from the repository root with LuaJIT: luajit tests/bleed/bleed_module_test.lua
-- The air conditioning module as XTLua runs it (tests/lib/xtlua.lua), with
-- the bleed air model through its glue (B747.55.xt.bleed.lua): the P5 bleed
-- panel, START, N2, the APU and the buses in; the valve positions, engine
-- and duct pressures, lights, EICAS slots and X-Plane's bleed air mode out.
-- The model's behaviour itself is tested in bleed_model_test.lua; this
-- checks the wiring and the names the panel, the engines, anti-ice and the
-- hydraulics read (docs/overhaul/notes/ATA-36.md §6).
local T = dofile("tests/lib/check.lua")("bleed_module")
local xtlua = dofile("tests/lib/xtlua.lua")

local rt = xtlua.new()
rt:load("plugins/xtlua_keysystems/scripts/B747.55.xt.air/B747.55.xt.air.lua")
rt:set("sim/operation/prefs/startup_running", 0)
rt:callout("flight_start")

local function frames(seconds)
    for _ = 1, math.floor(seconds * 30 + 0.5) do rt:frame(1 / 30) end
end
local function get(name, i) return rt:get(name, i) end
local AIR = "laminar/B747/air/"
local SW = "laminar/B747/button_switch/position"
local PACK = "laminar/B747/air/pack_ctrl/sel_dial_pos"
local ADVISORY = "laminar/B747/CAS/advisory_status"

-- power, bleed switches ON, AUTOSTART, APU running with its bleed
frames(0.5)
for i = 0, 3 do
    rt:set("laminar/B747/electrical/bus/ac", i, 1)
    rt:set("laminar/B747/electrical/bus/dc", i, 1)
end
for i = 75, 81 do rt:set(SW, i, 1) end
rt:set(SW, 45, 1)
for i = 0, 2 do rt:set(PACK, i, 1) end
rt:set("laminar/B747/electrical/apu/sel_dial_pos", 1)
rt:set("sim/cockpit2/electrical/APU_N1_percent", 100)
frames(6)
T.equal(get(AIR .. "apu/bleed_valve_pos"), 1, "APU: bleed valve open")
T.equal(get(AIR .. "isolation_valve_L_pos"), 1, "APU: ISLN L open")
T.check(get(AIR .. "duct_pressure_L") > 25 and get(AIR .. "duct_pressure_R") > 25, "APU, three packs: L and R ducts")
T.check(get(AIR .. "duct_pressure_C") > 25, "APU, three packs: centre duct")
T.equal(get("sim/cockpit2/pressurization/actuators/bleed_air_mode"), 5, "APU: X-Plane bleed air auto (its valves open)")
T.equal(get(AIR .. "light/apu_valve"), 0, "APU: no VALVE light")

-- START 4 with three packs on: not enough air; packs 2 and 3 OFF: it starts
-- (FCOM p.123, p.895)
rt:set("laminar/B747/toggle_switch/position", 19, 1)
rt:set("laminar/B747/fuel/fuel_control/toggle_sw_pos", 3, 1)
frames(3)
T.equal(get(AIR .. "engine4/bleed_start_valve_pos"), 0, "START 4, three packs: start valve stays closed")
rt:set(PACK, 1, 0)
rt:set(PACK, 2, 0)
frames(3)
T.equal(get(AIR .. "engine4/bleed_start_valve_pos"), 1, "START 4, one pack: start valve open (the engines read it)")
-- the engine comes up and START drops out; 15 s later the PRV opens
rt:set("laminar/B747/engines/display_N2", 3, 55)
rt:set("laminar/B747/toggle_switch/position", 19, 0)
frames(1)
T.equal(get(AIR .. "engine4/bleed_start_valve_pos"), 0, "starter cutout: start valve closed")
rt:set("laminar/B747/engines/display_N2", 3, 65)
frames(16)
T.check(get(AIR .. "engine4/bleed_air_psi") > 50, "engine 4 running: bleed air (anti-ice reads it)")
T.equal(get(AIR .. "engine4/bleed_valve_pos"), 1, "engine 4 running: bleed valve open (synoptic, OFF light)")
T.equal(get("sim/cockpit2/pressurization/actuators/bleed_air_mode"), 5, "engine air: X-Plane bleed air auto")

-- ENGINE BLEED 4 off with the engine running: >BLEED 4 OFF
rt:set(SW, 80, 0)
frames(1)
T.equal(get(AIR .. "engine4/bleed_valve_pos"), 0, "bleed 4 off: valve closed")
T.equal(get(ADVISORY, 42), 1, "bleed 4 off: >BLEED 4 OFF")
rt:set(SW, 80, 1)
frames(2)
T.equal(get(ADVISORY, 42), 0, "bleed 4 on: no >BLEED 4 OFF")

-- ISLN L off: VALVE light while it moves, then closed
rt:set(SW, 75, 0)
frames(1)
T.equal(get(AIR .. "light/isln_valve", 0), 1, "ISLN L moving: VALVE light")
frames(2)
T.equal(get(AIR .. "isolation_valve_L_pos"), 0, "ISLN L closed")
T.equal(get(AIR .. "light/isln_valve", 0), 0, "ISLN L closed: VALVE light out")
T.equal(get(ADVISORY, 35), 0, "ISLN L closed as commanded: no BLEED ISLN L")

-- the STATUS messages (laminar/B747/CAS/status_status): ISLN R switched OFF
-- without AC bus 3 stays open: BLEED ISLN R advisory and status after 10 s
-- (ATA30_32_35_36 p.24); DC bus 1 lost for 20 s: BLEED ASCTU A (p.16)
local STATUS = "laminar/B747/CAS/status_status"
rt:set("laminar/B747/electrical/bus/ac", 2, 0)
rt:set(SW, 76, 0)
frames(11)
T.equal(get(ADVISORY, 36), 1, "ISLN R stuck: BLEED ISLN R")
T.equal(get(STATUS, 23), 1, "ISLN R stuck: STATUS BLEED ISLN R")
T.equal(get(STATUS, 22), 0, "ISLN R stuck: no STATUS BLEED ISLN L")
rt:set(SW, 76, 1)
rt:set("laminar/B747/electrical/bus/ac", 2, 1)
rt:set("laminar/B747/electrical/bus/dc", 0, 0)
frames(21)
T.equal(get(STATUS, 23), 0, "ISLN R as commanded again: STATUS gone")
T.equal(get(STATUS, 20), 1, "DC bus 1 lost 20 s: STATUS BLEED ASCTU A")
T.equal(get(STATUS, 21), 0, "DC bus 1 lost: no BLEED ASCTU B")

T.done()
