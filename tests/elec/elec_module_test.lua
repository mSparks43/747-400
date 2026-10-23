-- Run from the repository root with LuaJIT: luajit tests/elec/elec_module_test.lua
-- The electrical module as XTLua runs it (tests/lib/xtlua.lua): the panel and
-- engine datarefs in, the bus, breaker, light, EICAS and X-Plane datarefs
-- out, through the glue (B747.03.xt.elec_buses.lua). The model's behaviour
-- itself is tested in elec_model_test.lua; this checks the wiring and the
-- names other parts of the aircraft read (docs/overhaul/notes/ATA-24.md §6).
local T = dofile("tests/lib/check.lua")("elec_module")
local xtlua = dofile("tests/lib/xtlua.lua")

local rt = xtlua.new()
rt:load("plugins/xtlua/scripts/B747.03.xt.electrical/B747.03.xt.electrical.lua")
rt:set("sim/flightmodel/failures/onground_any", 1)
rt:set("sim/operation/prefs/startup_running", 0)
rt:callout("flight_start")

local function frames(seconds)
    for _ = 1, math.floor(seconds * 30 + 0.5) do rt:frame(1 / 30) end
end
local function get(name, i) return rt:get(name, i) end
local SW = "laminar/B747/button_switch/position"
local CAUTION = "laminar/B747/CAS/caution_status"
local ADVISORY = "laminar/B747/CAS/advisory_status"

-- the first frame runs the module's cold-and-dark flight start (STANDBY
-- POWER OFF); then the panel as the before-start flows leave it: BATTERY ON,
-- STANDBY POWER AUTO, UTILITY, BUS TIE AUTO, GEN CONT ON
frames(0.1)
T.equal(get("laminar/B747/electrical/standby_power/sel_dial_pos"), 0, "cold and dark: STANDBY POWER OFF")
for _, i in ipairs({11, 12, 13, 18, 19, 20, 21, 22, 23, 24, 25}) do rt:set(SW, i, 1) end
rt:set("laminar/B747/electrical/standby_power/sel_dial_pos", 1)
frames(1)
T.equal(get("laminar/B747/electrical/bus/stby_main"), 1, "battery: main standby bus")
T.equal(get("laminar/B747/electrical/bus/stby_apu"), 1, "battery: APU standby bus")
T.equal(get("laminar/B747/electrical/bus/ac", 0), 0, "battery: AC 1 dead")
for i = 15, 18 do T.equal(get(CAUTION, i), 1, "battery: ELEC AC BUS caution " .. i) end
T.equal(get("laminar/B747/electrical/capt_display_power"), 0, "battery: captain's displays powered (APU standby)")
T.equal(get("laminar/B747/electrical/fo_display_power"), 6, "battery: F/O's displays off (F/O XFR dead)")
T.equal(get("laminar/B747/electrical/display_has_power", 8), 6, "battery: left CDU on main standby")
T.equal(get("sim/cockpit2/electrical/battery_on", 0), 1, "battery: X-Plane battery follows the switch")
T.equal(get("laminar/B747/electrical/light/drive", 0), 1, "battery: DRIVE light")
-- the STAT page's battery values (custom acf): the model's volts and the
-- current without its sign (FCOM p.793)
local amps = get("laminar/B747/electrical/battery/amps", 0)
T.check(amps > 0, "battery: the main battery discharges (+)")
T.equal(get("laminar/B747/electrical/battery/stat_amps", 0), amps, "battery: STAT A-DC is the discharge current")
T.check(get("laminar/B747/electrical/battery/volts", 0) > 20, "battery: STAT V-DC from the model")

-- APU running; APU GEN 1 pushed (the manipulator sets switch_mode 1)
rt:set("sim/cockpit2/electrical/APU_N1_percent", 100)
rt:set("sim/cockpit2/electrical/APU_running", 1)
rt:set("laminar/B747/electrical/apu/sel_dial_pos", 1)
frames(1)
T.equal(get("laminar/B747/electrical/apu_pwr1_avail"), 1, "APU: available to the switch handler")
T.equal(get("laminar/B747/electrical/light/apu_avail", 0), 1, "APU: AVAIL light")
rt:set("laminar/B747/apu_pwr_1/switch_mode", 1)
frames(1)
T.equal(get("laminar/B747/electrical/breaker/apb", 0), 1, "APU GEN 1: APB 1 closed")
T.equal(get("laminar/B747/electrical/breaker/ssb"), 1, "APU GEN 1: SSB closed")
for i = 0, 3 do T.equal(get("laminar/B747/electrical/bus/ac", i), 1, "APU GEN 1: AC bus " .. (i + 1)) end
T.equal(get("laminar/B747/electrical/apu_pwr1_on"), 1, "APU GEN 1: apu_pwr1_on (sounds, panel)")
T.equal(get("laminar/B747/electrical/bus1hot"), 1, "APU GEN 1: bus1hot (synoptic)")
T.equal(get("laminar/B747/electrical/topleftbus"), 1, "APU GEN 1: topleftbus")
T.equal(get("laminar/B747/rel_esys"), 0, "APU GEN 1: AC bus 1 not amber")
T.equal(get("sim/cockpit2/electrical/APU_generator_on"), 1, "APU GEN 1: X-Plane APU generator on")
T.equal(get("sim/cockpit2/electrical/cross_tie"), 1, "APU GEN 1: X-Plane cross tie closed")
for i = 15, 18 do T.equal(get(CAUTION, i), 0, "APU GEN 1: no ELEC AC BUS caution " .. i) end
for i = 100, 103 do T.equal(get(ADVISORY, i), 1, "APU GEN 1: ELEC GEN OFF advisory " .. i) end
T.equal(get("laminar/B747/electrical/fo_display_power"), 0, "APU GEN 1: F/O's displays powered")

-- four engines at idle: the IDGs take over, APU GEN 1 drops and its switch
-- request is cleared, X-Plane's generators follow the GCBs
for i = 0, 3 do rt:set("sim/flightmodel/engine/ENGN_N2_", i, 69) end
frames(1)
for i = 0, 3 do
    T.equal(get("laminar/B747/electrical/breaker/gcb", i), 1, "engines: GCB " .. (i + 1))
    T.equal(get("sim/cockpit2/electrical/generator_on", i), 1, "engines: X-Plane generator " .. (i + 1))
end
T.equal(get("laminar/B747/electrical/breaker/apb", 0), 0, "engines: APB 1 open")
T.equal(get("laminar/B747/apu_pwr_1/switch_mode"), 0, "engines: APU GEN 1 request cleared")
T.equal(get("laminar/B747/electrical/apu_pwr1_on"), 0, "engines: APU GEN 1 ON light out")
for i = 100, 103 do T.equal(get(ADVISORY, i), 0, "engines: no ELEC GEN OFF " .. i) end
for i = 71, 74 do T.equal(get(CAUTION, i), 0, "engines: ELEC GEN OFF never a caution (109) " .. i) end
T.equal(get("laminar/B747/electrical/light/drive", 0), 0, "engines: DRIVE light out")
amps = get("laminar/B747/electrical/battery/amps", 0)
T.check(amps < 0, "engines: the main battery charges (-)")
T.equal(get("laminar/B747/electrical/battery/stat_amps", 0), -amps, "engines: STAT A-DC without the sign")

-- BUS TIE 2 OFF: ISLN light and ELEC BUS ISLN 2
rt:set(SW, 19, 0)
frames(1)
T.equal(get("laminar/B747/electrical/light/isln", 1), 1, "BUS TIE 2 OFF: ISLN light")
T.equal(get(ADVISORY, 93), 1, "BUS TIE 2 OFF: ELEC BUS ISLN 2")
T.equal(get("laminar/B747/electrical/bus2hot"), 0, "BUS TIE 2 OFF: no bus tie flow bar")
rt:set(SW, 19, 1)

-- DRIVE DISC 1 pushed at idle (the manipulator sets the flag)
rt:set("laminar/B747/electrical/generator/drive_disc_status", 0, 1)
frames(1)
T.equal(get("laminar/B747/electrical/idg_connected", 0), 0, "DRIVE DISC 1: IDG 1 disconnected")
T.equal(get(ADVISORY, 83), 1, "DRIVE DISC 1: >DRIVE DISC 1")
T.equal(get("laminar/B747/CAS/status_status", 25), 1, "DRIVE DISC 1: STATUS DRIVE DISC 1 (LH24 p.64)")
T.equal(get("laminar/B747/CAS/status_status", 26), 0, "DRIVE DISC 1: no STATUS DRIVE DISC 2")
T.equal(get("sim/cockpit2/electrical/generator_on", 0), 0, "DRIVE DISC 1: X-Plane generator 1 off")

-- STANDBY POWER OFF: >STBY BUS MAIN and APU, captain's displays off
rt:set("laminar/B747/electrical/standby_power/sel_dial_pos", 0)
frames(1)
T.equal(get(ADVISORY, 276), 1, "STBY OFF: >STBY BUS APU")
T.equal(get(ADVISORY, 277), 1, "STBY OFF: >STBY BUS MAIN")
T.equal(get("laminar/B747/electrical/capt_display_power"), 6, "STBY OFF: captain's displays off")

T.done()
