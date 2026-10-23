-- Run from the repository root with LuaJIT: luajit tests/warning/alerts_module_test.lua
-- The crew alerting module as XTLua runs it (tests/lib/xtlua.lua), with the
-- manipulators (master reset) and the flight instruments (CANC, RCL): the
-- status slots the systems set in, the EICAS lines, pages and master lights
-- the panel and the sounds read out (B747.87.xt.alerts.lua). The model's
-- behaviour itself is tested in alert_model_test.lua; this checks the wiring.
local T = dofile("tests/lib/check.lua")("alerts_module")
local xtlua = dofile("tests/lib/xtlua.lua")

local rt = xtlua.new()
rt:load("plugins/xtlua/scripts/B747.87.xt.warning/B747.87.xt.warning.lua")
rt:load("plugins/xtlua/scripts/B747.01.xt.manipulators/B747.01.xt.manipulators.lua")
rt:load("plugins/xtlua_keysystems/scripts/B747.60.xt.fltInst/B747.60.xt.fltInst.lua")
rt:set("sim/operation/prefs/startup_running", 0)
rt:callout("flight_start")

local function frames(seconds)
    for _ = 1, math.floor(seconds * 30 + 0.5) do rt:frame(1 / 30) end
end
local function get(name, i) return rt:get(name, i) end
local function line(level, slot) return get(string.format("laminar/B747/CAS/gen_%s_msg_%03d", level, slot)) end
local WARNING = "laminar/B747/CAS/warning_status"
local CAUTION = "laminar/B747/CAS/caution_status"
local ADVISORY = "laminar/B747/CAS/advisory_status"
local MEMO = "laminar/B747/CAS/memo_status"
local STATUS = "laminar/B747/CAS/status_status"
local FUEL_CONTROL = "laminar/B747/fuel/fuel_control/toggle_sw_pos"
-- the slot of page 1 showing a text at a level, or nil (fltInst02 adds
-- messages of its own to these inputs, e.g. >AIRSPEED LOW)
local function slot_of(level, text)
    for slot = 0, 10 do
        if line(level, slot) == text then return slot end
    end
end

-- on the ground, every FUEL CONTROL CUTOFF, the EIUs powered from the main
-- standby bus: they start after 4 s
rt:set("laminar/B747/electrical/bus/stby_main", 1)
frames(5)
rt:set(CAUTION, 40, 1)              -- HYD PRESS SYS 1
rt:set(ADVISORY, 100, 1)            -- ELEC GEN OFF 1
rt:set(WARNING, 28, 1)              -- ENG 1 FAIL
rt:set(MEMO, 26, 1)                 -- PARK BRAKE SET
frames(0.5)
T.equal(line("caution", 0), "HYD PRESS SYS 1", "before start: the caution on line 1")
T.equal(line("advisory", 1), " ", "before start: ELEC GEN OFF 1 hidden (FCOM p.1586)")
T.equal(line("caution", 1), " ", "before start: ENG 1 FAIL hidden")
T.equal(line("memo", 10), "PARK BRAKE SET", "before start: the memo on the bottom line")
T.equal(get("laminar/B747/warning/master_caution"), 0, "before start: no master CAUTION")
T.equal(get("laminar/B747/warning/master_warning"), 0, "before start: ENG FAIL lights no master WARNING")
T.equal(get("laminar/B747/CAS/msg_page"), 1, "before start: page 1")
T.equal(get("laminar/B747/CAS/num_msg_pages"), 1, "before start: one page")

-- in the air, engines running: ENG 1 FAIL is a caution (FCOM p.899)
for i = 0, 3 do rt:set(FUEL_CONTROL, i, 1) end
rt:set("laminar/B747/gear/air_ground/pri_air", 1)
rt:set("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot", 5000)
rt:set("laminar/B747/gauges/indicators/airspeed_kts_pilot", 250)
rt:set(CAUTION, 41, 1)              -- HYD PRESS SYS 2
frames(0.5)
local hyd2, eng1, gen1 = slot_of("caution", "HYD PRESS SYS 2"), slot_of("caution", "ENG 1 FAIL"),
    slot_of("advisory", "ELEC GEN OFF 1")
T.check(hyd2 and eng1 and hyd2 < eng1, "in flight: the new caution above the older ones")
T.check(eng1 ~= nil and slot_of("warning", "ENG 1 FAIL") == nil, "in flight: ENG 1 FAIL shown as a caution")
T.check(gen1 and eng1 and gen1 > eng1, "in flight: the advisory after the cautions")
T.equal(get("laminar/B747/warning/master_caution"), 1, "in flight: master CAUTION")
T.equal(get("laminar/B747/warning/master_caution_audio"), 1, "in flight: the caution pulse")
T.equal(get("laminar/B747/warning/master_warning"), 0, "in flight: no master WARNING for ENG FAIL")
frames(1.2)
T.equal(get("laminar/B747/warning/master_caution_audio"), 0, "the caution pulse lasts 1 s")

-- master reset from the glareshield switch (manipulators)
rt:command("laminar/B747/button_switch/warn_caut_capt", 0.1)
frames(1)
T.equal(get("laminar/B747/warning/master_caution"), 0, "master reset: master CAUTION out and stays out")
T.equal(get("laminar/B747/warning/master_reset_count"), 1, "master reset: counted")

-- BLEED ISLN L, an advisory with the beeper: the pulse without master CAUTION
-- (FCOM p.619)
rt:set(ADVISORY, 35, 1)
frames(0.3)
T.check(slot_of("advisory", "BLEED ISLN L") ~= nil, "BLEED ISLN L: shown")
T.equal(get("laminar/B747/warning/master_caution_audio"), 1, "BLEED ISLN L: the beeper pulse")
T.equal(get("laminar/B747/warning/master_caution"), 0, "BLEED ISLN L: no master CAUTION")
rt:set(ADVISORY, 35, 0)
frames(1.2)

-- a STATUS message: the STATUS page line, the page count the STAT switch
-- pages with, and the cue, gone once the STATUS page is shown (FCOM p.1528,
-- p.1549)
rt:set(STATUS, 16, 1)               -- HYDIM 1
frames(0.3)
T.equal(get("laminar/B747/CAS/gen_status_msg_000"), "HYDIM 1", "STATUS: the message on line 1")
T.equal(get("laminar/B747/STAT/num_msg_pages"), 1, "STATUS: one page for the STAT switch")
T.equal(get("laminar/B747/CAS/status_cue"), 1, "STATUS cue: a new message")
T.equal(get("laminar/B747/CAS/status_cue_text"), "STATUS", "STATUS cue: its text")
rt:command("laminar/B747/dsp/stat_switch", 0.1)
frames(0.3)
T.equal(get("laminar/B747/dsp/synoptic_display"), 2, "STAT: the STATUS page shown")
T.equal(get("laminar/B747/CAS/status_cue"), 0, "STATUS cue: gone with the STATUS page shown")
rt:set(STATUS, 16, 0)
frames(0.3)
T.equal(get("laminar/B747/CAS/gen_status_msg_000"), " ", "STATUS: the line blank when the message goes")
rt:command("laminar/B747/dsp/stat_switch", 0.1)
frames(0.3)

-- a warning: master WARNING and the siren request
rt:set(WARNING, 1, 1)               -- CABIN ALTITUDE
frames(0.5)
T.equal(line("warning", 0), "CABIN ALTITUDE", "warning: on the top line")
T.check((slot_of("caution", "HYD PRESS SYS 2") or 0) > hyd2, "warning: the cautions move down")
T.equal(get("laminar/B747/warning/master_warning"), 1, "warning: master WARNING")
T.equal(get("laminar/B747/warning/warning_siren"), 1, "warning: siren asked for")

-- two pages: the warning repeats on page 2 (slots 11-21); CANC and RCL from
-- the display select panel (fltInst02)
for i = 61, 64 do rt:set(CAUTION, i, 1) end     -- STARTER CUTOUT 1-4
for i = 32, 35 do rt:set(CAUTION, i, 1) end     -- FUEL PRESS ENG 1-4
frames(0.5)
T.equal(get("laminar/B747/CAS/num_msg_pages"), 2, "pages: two")
T.equal(line("warning", 11), "CABIN ALTITUDE", "pages: the warning heads page 2")
rt:command("laminar/B747/dsp/canc_switch", 0.1)
frames(0.3)
T.equal(get("laminar/B747/CAS/canc_count"), 1, "CANC: counted")
T.equal(get("laminar/B747/CAS/msg_page"), 2, "CANC: page 2")
rt:command("laminar/B747/dsp/canc_switch", 0.1)
frames(0.3)
T.equal(get("laminar/B747/CAS/msg_page"), 1, "CANC on the last page: page 1")
T.equal(line("caution", 1), " ", "CANC on the last page: the cautions go")
T.equal(line("warning", 0), "CABIN ALTITUDE", "CANC on the last page: the warning stays")
T.equal(get("laminar/B747/CAS/caut_adv_display"), 0, "CANC on the last page: caut_adv_display 0")
rt:command("laminar/B747/dsp/rcl_switch", 0.1)
frames(0.3)
T.equal(get("laminar/B747/CAS/recall_ind"), 1, "RCL: RECALL shown")
T.equal(get("laminar/B747/CAS/num_msg_pages"), 2, "RCL: the cautions are back")
T.equal(get("laminar/B747/CAS/caut_adv_display"), 1, "RCL: caut_adv_display 1")
frames(1.5)
T.equal(get("laminar/B747/CAS/recall_ind"), 0, "RCL: RECALL gone 1 s after release")

-- the EIUs lose power: blank lines, lights out
rt:set("laminar/B747/electrical/bus/stby_main", 0)
frames(0.5)
T.equal(line("warning", 0), " ", "no power: lines blank")
T.equal(get("laminar/B747/warning/master_warning"), 0, "no power: master WARNING out")
T.equal(get("laminar/B747/warning/warning_siren"), 0, "no power: no siren")

-- a CANC pushed without power does nothing when the power comes back
rt:command("laminar/B747/dsp/canc_switch", 0.1)
rt:set("laminar/B747/electrical/bus/stby_main", 1)
frames(5)
T.equal(get("laminar/B747/CAS/caut_adv_display"), 1, "power back: the CANC pushed without power did nothing")
T.equal(line("warning", 0), "CABIN ALTITUDE", "power back: the messages are back")
T.equal(get("laminar/B747/warning/master_warning"), 1, "power back: master WARNING for the warning still there")

-- an engine start (START 2 pulled) holds new cautions back until the engine
-- reaches idle (FCOM p.1587)
for i = 0, 63 do rt:set(CAUTION, i, 0) end
rt:set(WARNING, 1, 0)
rt:command("laminar/B747/toggle_switch/engine_start2")
frames(0.5)
rt:set(CAUTION, 42, 1)              -- HYD PRESS SYS 3
frames(1)
T.equal(slot_of("caution", "HYD PRESS SYS 3"), nil, "engine start: a new caution waits")
rt:command("laminar/B747/toggle_switch/engine_start2_off")      -- starter cutout
rt:set("sim/flightmodel/engine/ENGN_N2_", 1, 65)
frames(0.5)
T.check(slot_of("caution", "HYD PRESS SYS 3") ~= nil, "engine start over at idle: the caution shows")

T.done()
