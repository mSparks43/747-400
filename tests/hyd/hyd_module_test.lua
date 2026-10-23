-- Run from the repository root with LuaJIT: luajit tests/hyd/hyd_module_test.lua
-- The hydraulic modules as XTLua runs them (tests/lib/xtlua.lua): the model
-- through its glue (B747.19.xt.hyd_power.lua) in the hydraulics module, with
-- B747.20 (selectors, EICAS memo). The panel, engines, buses and bleed ducts
-- in; the pressures, synoptic values, lights and EICAS slots out. The model's
-- behaviour itself is tested in hyd_model_test.lua; this checks the wiring
-- and the names the panels, the autopilot and the flight controls read
-- (docs/overhaul/notes/ATA-29.md §6.2).
local T = dofile("tests/lib/check.lua")("hyd_module")
local xtlua = dofile("tests/lib/xtlua.lua")

math.randomseed(1)
local rt = xtlua.new()
rt:load("plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/B747.19.xt.hydraulicsmodel.lua")
rt:load("plugins/xtlua_keysystems/scripts/B747.20.xt.hydraulics/B747.20.xt.hydraulics.lua")
rt:set("sim/operation/prefs/startup_running", 0)
rt:callout("flight_start")

local function frames(seconds)
    for _ = 1, math.floor(seconds * 30 + 0.5) do rt:frame(1 / 30) end
end
local function get(name, i) return rt:get(name, i) end
local HYD = "laminar/B747/hydraulics/"
local SEL = HYD .. "dmd_pump/sel_dial_pos"
local CAUTION = "laminar/B747/CAS/caution_status"
local ADVISORY = "laminar/B747/CAS/advisory_status"
local STATUS = "laminar/B747/CAS/status_status"
local SW = "laminar/B747/button_switch/position"

-- cold and dark, ENGINE pumps ON; then power and APU bleed
frames(0.5)
for i = 30, 33 do rt:set(SW, i, 1) end
for i = 0, 3 do
    rt:set("laminar/B747/electrical/bus/dc", i, 1)
    rt:set("laminar/B747/electrical/bus/ac", i, 1)
end
rt:set("laminar/B747/electrical/bus/gnd_hdlg", 1)
rt:set("laminar/B747/electrical/bus/gnd_hdlg_dc", 1)
rt:set("laminar/B747/air/duct_pressure_L", 30)
rt:set("laminar/B747/air/duct_pressure_R", 30)
frames(3)
for n = 1, 4 do
    T.equal(get(HYD .. "pressure_" .. n), 0, "preflight: system " .. n .. " at 0 psi")
    T.equal(get(HYD .. "light/sys_fault", n - 1), 1, "preflight: SYS FAULT " .. n)
    T.equal(get(HYD .. "light/dem_press", n - 1), 1, "preflight: DEMAND PRESS " .. n .. " (selector OFF)")
    T.equal(get(HYD .. "light/eng_press", n - 1), 1, "preflight: ENGINE PRESS " .. n)
    T.equal(get(CAUTION, 39 + n), 1, "preflight: HYD PRESS SYS " .. n)
end
T.equal(get(CAUTION, 9), 1, "preflight: >BRAKE SOURCE")
T.equal(get(HYD .. "light/brake_source"), 1, "preflight: BRAKE SOURCE light")
T.equal(get(HYD .. "res_1"), 1, "preflight: quantity 1.00 (no random value, HYD-16)")
-- the custom acf's HYD synoptic (codes: B747.19.hyd_model.lua M.SYN_*)
local SYN = HYD .. "synoptic/"
for n = 1, 4 do
    T.equal(get(SYN .. "edp", n - 1), 1, "preflight: synoptic EDP " .. n .. " ON amber (engine stopped)")
    T.equal(get(SYN .. "dem", n - 1), 4, "preflight: synoptic DEM " .. n .. " OFF")
    T.equal(get(SYN .. "sov", n - 1), 1, "preflight: synoptic SOV " .. n .. " open")
    T.equal(get(SYN .. "rsvr_press", n - 1), 0, "preflight: no RSVR PRESS " .. n .. " with APU bleed")
end
T.equal(get(SYN .. "aux"), 0, "preflight: synoptic AUX OFF")
T.equal(get(SYN .. "text_off"), "OFF", "synoptic: the word OFF for gen_text")
T.equal(get(SYN .. "text_auto"), "AUTO", "synoptic: the word AUTO for gen_text")

-- system 4 AUX first (FCOM p.119)
rt:set(SEL, 3, -1)
frames(3)
T.check(get(HYD .. "aux_pressure") > 2900, "AUX: aux_pressure")
T.check(get(HYD .. "pressure_4") > 2900, "AUX: system 4 pressure")
T.equal(get(HYD .. "dem_mode_4"), -1, "AUX: synoptic selector")
T.equal(get(SYN .. "aux"), 2, "AUX: synoptic AUX running")
T.equal(get(SYN .. "dem", 3), 4, "AUX: synoptic DEM 4 OFF")
T.equal(get(HYD .. "light/sys_fault", 3), 0, "AUX: SYS FAULT 4 out")
T.equal(get(HYD .. "light/dem_press", 3), 1, "AUX: DEMAND PRESS 4 on")
T.equal(get(ADVISORY, 209), 1, "AUX: HYD PRESS DEM 4")
T.equal(get(CAUTION, 43), 0, "AUX: no HYD PRESS SYS 4")
T.equal(get(CAUTION, 9), 0, "AUX: no >BRAKE SOURCE")
T.check(get(HYD .. "indicators/hydraulic_pressure_1_2_4") > 2500, "AUX: system 4 charges the accumulator")

-- 1-3 AUTO with the FUEL CONTROL CUTOFF
for i = 0, 2 do rt:set(SEL, i, 1) end
frames(5)
for n = 1, 3 do
    T.check(get(HYD .. "dem_pressure_" .. n) > 2900, "AUTO: demand pump " .. n .. " pressure")
    T.equal(get(HYD .. "light/sys_fault", n - 1), 0, "AUTO: SYS FAULT " .. n .. " out")
    T.equal(get(HYD .. "light/dem_press", n - 1), 0, "AUTO: DEMAND PRESS " .. n .. " out")
end
T.equal(get(ADVISORY, 210), 1, "AUTO: HYD PRESS ENG 1 raised (hidden before start by the alert model)")
T.equal(get(HYD .. "valve_1"), 1, "AUTO: synoptic supply valve open, engine pump on")

-- the engines start: engine pumps take over, demand pumps 2 and 3 stop 14 s
-- later; AUX pump 4 stops when EDP 4 pressurises
for i = 0, 3 do
    rt:set("sim/flightmodel/engine/ENGN_N2_", i, 65)
    rt:set("laminar/B747/fuel/fuel_control/toggle_sw_pos", i, 1)
end
rt:set(SEL, 3, 1)
frames(16)
for n = 1, 4 do
    T.check(get(HYD .. "edp_pressure_" .. n) > 2900, "engines: EDP " .. n .. " pressure")
    T.equal(get(HYD .. "light/eng_press", n - 1), 0, "engines: ENGINE PRESS " .. n .. " out")
    T.equal(get(ADVISORY, 209 + n), 0, "engines: no HYD PRESS ENG " .. n)
end
T.equal(get(HYD .. "dem_pressure_2"), 0, "engines: ACMP 2 stopped")
T.equal(get(HYD .. "aux_pressure"), 0, "engines: AUX pump stopped")
T.check(get(HYD .. "pressure_dsp_1") >= 2800, "engines: synoptic pressure")
for n = 1, 4 do
    T.equal(get(SYN .. "edp", n - 1), 0, "engines: synoptic EDP " .. n .. " empty")
    T.equal(get(SYN .. "dem", n - 1), 3, "engines: synoptic DEM " .. n .. " AUTO (cyan)")
end

-- ENGINE pump 1 OFF: ADP 1 keeps system 1, ENGINE PRESS and HYD PRESS ENG
rt:set(SW, 30, 0)
frames(3)
T.equal(get(HYD .. "light/eng_press", 0), 1, "EDP 1 off: ENGINE PRESS 1")
T.equal(get(ADVISORY, 210), 1, "EDP 1 off: HYD PRESS ENG 1")
T.check(get(HYD .. "dem_pressure_1") > 2900 and get(HYD .. "pressure_1") > 2800, "EDP 1 off: ADP 1 holds system 1")
T.equal(get(HYD .. "valve_1"), 0, "EDP 1 off: synoptic shows the engine pump off")
T.equal(get(SYN .. "edp", 0), 4, "EDP 1 off: synoptic EDP 1 OFF")
T.equal(get(SYN .. "sov", 0), 1, "EDP 1 off: synoptic SOV 1 still open")
T.equal(get(SYN .. "dem", 0), 0, "EDP 1 off: synoptic DEM 1 running (empty)")
rt:set(SW, 30, 1)
frames(16)

-- an X-Plane leak failure drains one system in 15-30 s; >HYD QTY LOW and
-- SYS FAULT at LO; clearing the failure fills it again
rt:set("sim/operation/failures/rel_hydleak", 6)
frames(40)
local low1, low2 = get(HYD .. "res_1") <= 0.34, get(HYD .. "res_2") <= 0.34
T.check(low1 ~= low2, "leak: one of systems 1 and 2 drained")
local n = low1 and 1 or 2
T.equal(get(ADVISORY, 217 + n), 1, "leak: >HYD QTY LOW " .. n)
T.equal(get(HYD .. "light/sys_fault", n - 1), 1, "leak: SYS FAULT " .. n)
T.equal(get("laminar/B747/EICAS2/stat/LO", n), 1, "leak: LO on STATUS")
rt:set("sim/operation/failures/rel_hydleak", 0)
frames(1)
T.equal(get(HYD .. "res_" .. n), 1, "leak cleared: quantity back to 1.00")
T.equal(get(ADVISORY, 217 + n), 0, "leak cleared: no >HYD QTY LOW")

-- STATUS slots (laminar/B747/CAS/status_status, ATA29_32 p.137): engines
-- running, ENGINE pump 2 OFF: HYD PRESS ENG 2 (slot 1) and nothing else
rt:set(SW, 31, 0)
frames(4)
T.equal(get(STATUS, 1), 1, "STATUS: HYD PRESS ENG 2 with its pump OFF")
T.equal(get(STATUS, 0), 0, "STATUS: no HYD PRESS ENG 1")
for slot = 4, 19 do
    T.equal(get(STATUS, slot), 0, "STATUS: slot " .. slot .. " clear")
end
rt:set(SW, 31, 1)
frames(4)
T.equal(get(STATUS, 1), 0, "STATUS: HYD PRESS ENG 2 gone with its pump ON")

-- fire switch 3: the synoptic's SOV 3 closes; EDP 3 shows ON amber
rt:set("laminar/B747/fire/engine03/ext_switch/pos_arm", 1)
frames(4)
T.equal(get(SYN .. "sov", 2), 0, "fire 3: synoptic SOV 3 closed")
T.equal(get(SYN .. "edp", 2), 1, "fire 3: synoptic EDP 3 ON amber")
rt:set("laminar/B747/fire/engine03/ext_switch/pos_arm", 0)
-- no bleed: the reservoirs lose pressure (5 min, estimate): RSVR PRESS
rt:set("laminar/B747/air/duct_pressure_L", 0)
rt:set("laminar/B747/air/duct_pressure_R", 0)
frames(900)
T.equal(get(SYN .. "rsvr_press", 0), 1, "no bleed: synoptic RSVR PRESS 1")

T.done()
