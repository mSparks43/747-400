-- Run from the repository root with LuaJIT: luajit tests/elec/elec_model_test.lua
-- The electrical model (plugins/xtlua/scripts/B747.03.xt.electrical/B747.03.elec_model.lua)
-- against the crew-visible behaviour of FCOM 6.10-6.30 (airplane 109) and the
-- Lufthansa ATA 24 manual (LH24). Page numbers are PDF pages, as in
-- docs/overhaul/notes/ATA-24.md.
local T = dofile("tests/lib/check.lua")("elec_model")
local E = dofile("plugins/xtlua/scripts/B747.03.xt.electrical/B747.03.elec_model.lua")

-- One frame, then do what the glue does with the switch requests the model
-- dropped (it writes the switch_mode datarefs back to 0).
local function step(s, inp, dt)
    local out = E.update(s, inp, dt)
    for k = 1, 2 do
        if out.clear_ext[k] then inp.ext_request[k] = false end
        if out.clear_apu[k] then inp.apu_request[k] = false end
    end
    return out
end

local function run(s, inp, seconds, dt)
    dt = dt or 1 / 30
    local out
    local frames = math.max(1, math.floor(seconds / dt + 0.5))
    for _ = 1, frames do out = step(s, inp, dt) end
    return out
end

local function all(t, n, v)
    for i = 1, n do if t[i] ~= v then return false end end
    return true
end

-- the airplane on the ground, BATTERY ON, STANDBY POWER AUTO, utility on
local function powered_up()
    local s, inp = E.new(), E.inputs()
    inp.battery = true
    inp.utility = {true, true}
    return s, inp
end

local function apu_running(inp)
    inp.apu_n1 = 100
end

local function engines(inp, n2)
    for n = 1, 4 do inp.n2[n] = n2 end
end

-- Cold and dark: the hot battery buses are always on (FCOM p.820); BATTERY
-- OFF leaves the battery buses and the standby buses without power (FCOM
-- p.819-820, p.804: the inverters need the BATTERY switch ON).
do
    local s, inp = E.new(), E.inputs()
    local out = run(s, inp, 1)
    T.check(all(out.ac, 4, false), "cold: AC buses off")
    T.check(all(out.dc, 4, false), "cold: DC buses off")
    T.check(out.hot_bat_bus.main and out.hot_bat_bus.apu, "cold: hot battery buses on (FCOM p.820)")
    T.check(not out.bat_bus.main and not out.bat_bus.apu, "cold: battery buses off with BATTERY OFF (FCOM p.819-820)")
    T.check(not out.stby.main and not out.stby.apu, "cold: standby buses off with BATTERY OFF (FCOM p.804)")
    T.check(out.cas.battery_off, "cold: >BATTERY OFF (FCOM p.821)")
    T.check(out.lights.battery_off, "cold: BATTERY OFF light (FCOM p.781)")
end

-- Battery only: battery buses from the hot battery buses, both standby buses
-- from the inverters (FCOM p.804, p.819-820). The AC buses are dead: ELEC AC
-- BUS 1-4, while ELEC GEN OFF stays inhibited. BAT DISCH MAIN and APU come
-- within 3 minutes (FCOM p.181 SP.6.3) and not at once.
do
    local s, inp = powered_up()
    local out = run(s, inp, 1)
    T.check(out.bat_bus.main and out.bat_bus.apu, "battery: battery buses on")
    T.check(out.stby.main and out.stby.apu, "battery: standby buses on the inverters (FCOM p.804)")
    T.check(all(out.cas.ac_bus, 4, true), "battery: ELEC AC BUS 1-4 (FCOM p.821)")
    T.check(all(out.cas.gen_off, 4, false), "battery: ELEC GEN OFF inhibited with ELEC AC BUS")
    T.check(not out.cas.stby_bus_main and not out.cas.stby_bus_apu, "battery: no >STBY BUS message")
    T.check(not out.cas.bat_disch_main, "battery: BAT DISCH not at once")
    out = run(s, inp, 175)
    T.check(out.cas.bat_disch_main and out.cas.bat_disch_apu, "battery: BAT DISCH MAIN and APU within 3 min (FCOM p.181)")
    T.check(out.battery.main.amps > 2, "battery: main battery discharging")
    T.check(all(out.lights.drive, 4, true), "battery: DRIVE lights on with the engines stopped (FCOM p.104)")
end

-- STANDBY POWER OFF: both standby buses lose power even with AC power
-- (FCOM p.780); >STBY BUS MAIN and APU (FCOM p.823).
do
    local s, inp = powered_up()
    apu_running(inp)
    run(s, inp, 1)
    inp.apu_request[1] = true
    run(s, inp, 1)
    inp.stby_power = 0
    local out = run(s, inp, 1)
    T.check(out.ac[3], "stby off: AC 3 has power")
    T.check(not out.stby.main and not out.stby.apu, "stby off: standby buses off (FCOM p.780)")
    T.check(out.cas.stby_bus_main and out.cas.stby_bus_apu, "stby off: >STBY BUS MAIN and APU (FCOM p.823)")
end

-- STANDBY POWER BAT: the inverters feed the standby buses, the chargers stop
-- and the batteries discharge (FCOM p.780-781, p.806; SP.6.3 p.181).
do
    local s, inp = powered_up()
    apu_running(inp)
    run(s, inp, 1)
    inp.apu_request[1] = true
    run(s, inp, 1)
    local out = run(s, inp, 1)
    T.check(out.battery.main.amps <= 0, "stby auto: main battery not discharging with AC power")
    inp.stby_power = 2
    out = run(s, inp, 1)
    T.check(out.stby.main and out.stby.apu, "stby bat: standby buses on the inverters")
    out = run(s, inp, 180)
    T.check(out.cas.bat_disch_main and out.cas.bat_disch_apu, "stby bat: BAT DISCH MAIN and APU (FCOM p.181)")
    inp.stby_power = 1
    out = run(s, inp, 1)
    T.check(not out.cas.bat_disch_main and not out.cas.bat_disch_apu, "stby auto again: BAT DISCH gone (FCOM p.181)")
end

-- APU generators (FCOM p.796): the first source closes the SSB and powers
-- everything; the second on the other side opens it, each side on its own;
-- when one goes, the SSB closes and the other powers everything.
do
    local s, inp = powered_up()
    apu_running(inp)
    local out = run(s, inp, 1)
    T.check(out.lights.apu_avail[1] and out.lights.apu_avail[2], "APU: AVAIL lights (FCOM p.783)")
    inp.apu_request[1] = true
    out = run(s, inp, 1)
    T.check(out.apb[1] and out.ssb, "APU GEN 1: APB 1 and SSB closed (FCOM p.796)")
    T.check(all(out.ac, 4, true), "APU GEN 1: AC 1-4 on")
    T.check(out.lights.apu_on[1] and not out.lights.apu_avail[1], "APU GEN 1: ON light, AVAIL out (FCOM p.783)")
    T.check(out.xfr.capt and out.xfr.fo and out.stby.main and out.stby.apu, "APU GEN 1: transfer and standby buses on")
    T.check(all(out.dc, 4, true) and out.bat_bus.main and out.bat_bus.apu, "APU GEN 1: DC and battery buses on")
    T.check(all(out.util, 4, true) and all(out.galley, 4, true), "APU GEN 1: utility and galley buses on (109)")
    T.check(out.battery.main.amps <= 0 and out.battery.apu.amps <= 0, "APU GEN 1: chargers on")
    inp.apu_request[2] = true
    out = run(s, inp, 1)
    T.check(out.apb[1] and out.apb[2] and not out.ssb, "APU GEN 2: SSB opens, each side on its own (FCOM p.796)")
    T.check(all(out.ac, 4, true), "APU GEN 2: AC 1-4 on")
    inp.apu_request[1] = false
    out = run(s, inp, 1)
    T.check(not out.apb[1] and out.apb[2] and out.ssb, "APU GEN 1 off: SSB closes, APU 2 powers all (FCOM p.796)")
    T.check(all(out.ac, 4, true), "APU GEN 1 off: AC 1-4 on")
end

-- Engine start on the two APU generators (FCOM p.797): each IDG takes its
-- side; when both sides have IDGs the SSB closes. The APU generators drop
-- out with their AVAIL lights back on.
do
    local s, inp = powered_up()
    apu_running(inp)
    run(s, inp, 1)
    inp.apu_request = {true, true}
    run(s, inp, 1)
    inp.n2[4] = 30
    local out = run(s, inp, 1)
    T.check(not out.gcb[4] and out.apb[2], "start 4: below the on-line speed the IDG stays off (LH24 p.66)")
    inp.n2[4] = 60
    out = run(s, inp, 1)
    T.check(out.gcb[4] and not out.apb[2] and out.apb[1], "start 4: IDG 4 takes the right side, APU 2 drops (FCOM p.797)")
    T.check(not out.ssb, "start 4: SSB stays open (APU left, IDG right)")
    T.check(not inp.apu_request[2], "start 4: APU GEN 2 request cleared (ON light out)")
    T.check(out.lights.apu_avail[2] and not out.lights.apu_on[2], "start 4: APU GEN 2 AVAIL again")
    inp.n2[3] = 60
    out = run(s, inp, 1)
    T.check(out.gcb[3] and not out.ssb, "start 3: IDG 3 on")
    inp.n2[2] = 60
    out = run(s, inp, 1)
    T.check(out.gcb[2] and not out.apb[1] and out.ssb, "start 2: APU 1 drops, IDGs on both sides, SSB closes (FCOM p.797)")
    inp.n2[1] = 60
    out = run(s, inp, 1)
    T.check(all(out.gcb, 4, true) and out.ssb and all(out.ac, 4, true), "start 1: four IDGs, SSB closed")
    T.check(all(out.lights.gen_off, 4, false) and all(out.lights.drive, 4, false), "after start: GEN OFF and DRIVE lights out")
    T.check(all(out.cas.gen_off, 4, false) and all(out.cas.ac_bus, 4, false), "after start: no ELEC message")
end

-- One APU generator powering everything, then an engine: the IDG takes over
-- everything and the SSB stays closed (FCOM p.797).
do
    local s, inp = powered_up()
    apu_running(inp)
    run(s, inp, 1)
    inp.apu_request[1] = true
    run(s, inp, 1)
    inp.n2[4] = 60
    local out = run(s, inp, 1)
    T.check(out.gcb[4] and not out.apb[1] and out.ssb, "single APU: IDG 4 takes everything, SSB stays closed (FCOM p.797)")
    T.check(all(out.ac, 4, true), "single APU: AC 1-4 on")
end

-- With the IDGs on line, selecting EXT/APU takes the IDGs off (FCOM p.797).
-- When the same kind is available for the other side, the SSB opens and only
-- that side changes; otherwise the new source takes everything (LH24 p.123).
do
    local s, inp = powered_up()
    engines(inp, 69)
    inp.ext_available = {true, true}
    local out = run(s, inp, 1)
    T.check(all(out.gcb, 4, true) and out.ssb, "IDGs: four GCBs and the SSB closed")
    T.check(out.lights.ext_avail[1] and out.lights.ext_avail[2], "IDGs: EXT AVAIL lights (FCOM p.784)")
    inp.ext_request[1] = true
    out = run(s, inp, 1)
    T.check(out.xpc[1] and not out.gcb[1] and not out.gcb[2], "EXT 1 (EXT 2 available): IDG 1 and 2 off (LH24 p.123)")
    T.check(out.gcb[3] and out.gcb[4] and not out.ssb, "EXT 1 (EXT 2 available): SSB opens, IDG 3 and 4 stay")
    T.check(all(out.ac, 4, true), "EXT 1: AC 1-4 on")
    T.check(out.cas.gen_off[1] and out.cas.gen_off[2] and not out.cas.gen_off[3], "EXT 1: ELEC GEN OFF 1 and 2 (FCOM p.822)")
    inp.ext_request[2] = true
    out = run(s, inp, 1)
    T.check(out.xpc[2] and all(out.gcb, 4, false) and not out.ssb, "EXT 2: the other IDGs off, SSB open (FCOM p.797)")
    inp.ext_request[1] = false
    out = run(s, inp, 1)
    T.check(not out.xpc[1] and out.gcb[1] and out.gcb[2] and not out.ssb, "EXT 1 off: IDG 1 and 2 back, SSB open (IDG left, EXT right)")
    inp.ext_request[2] = false
    out = run(s, inp, 1)
    T.check(all(out.gcb, 4, true) and out.ssb and all(out.ac, 4, true), "EXT 2 off: four IDGs, SSB closed")

    -- only EXT 1 available: it takes everything (LH24 p.123, first row)
    inp.ext_available = {true, false}
    inp.ext_request[1] = true
    out = run(s, inp, 1)
    T.check(out.xpc[1] and all(out.gcb, 4, false) and out.ssb, "EXT 1 alone: all GCBs open, SSB closed (LH24 p.123)")
    T.check(all(out.ac, 4, true), "EXT 1 alone: AC 1-4 on")
end

-- BUS TIE OFF (FCOM p.785, p.798, p.802, p.819): the BTB and DCIR open, ISLN
-- light and ELEC BUS ISLN; the AC bus stays on its own IDG. With GEN CONT OFF
-- as well the bus is dead: ELEC AC BUS, and ISLN/GEN OFF are inhibited.
do
    local s, inp = powered_up()
    engines(inp, 69)
    run(s, inp, 1)
    inp.bus_tie[2] = false
    local out = run(s, inp, 1)
    T.check(not out.btb[2] and not out.dcir[2], "BUS TIE 2 OFF: BTB 2 and DCIR 2 open (FCOM p.785, p.819)")
    T.check(out.lights.isln[2] and out.cas.bus_isln[2], "BUS TIE 2 OFF: ISLN light, ELEC BUS ISLN 2 (FCOM p.821)")
    T.check(out.ac[2] and out.gcb[2], "BUS TIE 2 OFF: AC 2 on its own IDG")
    inp.gen_cont[2] = false
    out = run(s, inp, 1)
    T.check(not out.ac[2] and out.cas.ac_bus[2], "BUS TIE 2 and GEN CONT 2 OFF: AC 2 dead, ELEC AC BUS 2")
    T.check(not out.cas.bus_isln[2] and not out.cas.gen_off[2], "AC 2 dead: ISLN and GEN OFF 2 inhibited (FCOM p.802)")
    T.check(out.dc[2] == false, "AC 2 dead, DCIR 2 open: DC 2 dead")
end

-- GEN CONT OFF (FCOM p.786, p.798, p.822): the GCB opens, the AC bus is fed
-- from the sync bus, GEN CONT OFF light and ELEC GEN OFF. Back ON, the IDG
-- comes back on line.
do
    local s, inp = powered_up()
    engines(inp, 69)
    run(s, inp, 1)
    inp.gen_cont[3] = false
    local out = run(s, inp, 1)
    T.check(not out.gcb[3] and out.ac[3], "GEN CONT 3 OFF: GCB 3 open, AC 3 from the sync bus (FCOM p.798)")
    T.check(out.lights.gen_off[3] and out.cas.gen_off[3], "GEN CONT 3 OFF: OFF light, ELEC GEN OFF 3 (FCOM p.786, p.822)")
    inp.gen_cont[3] = true
    out = run(s, inp, 1)
    T.check(out.gcb[3] and not out.cas.gen_off[3], "GEN CONT 3 ON: IDG 3 back on line")
end

-- Transfer buses (LH24 p.228): the captain's goes to AC 1 180 ms after AC 3
-- is lost and back 1.2 s after it returns. The main standby bus then runs on
-- its inverter (FCOM p.804). The same at 20 and 45 frames a second.
for _, fps in ipairs({20, 30, 45}) do
    local dt = 1 / fps
    local s, inp = powered_up()
    engines(inp, 69)
    run(s, inp, 1, dt)
    inp.gen_cont[3], inp.bus_tie[3] = false, false
    local out = run(s, inp, 0.1, dt)
    T.check(not out.ac[3] and not out.xfr.capt, fps .. " fps: CAPT XFR dead for the first 180 ms")
    out = run(s, inp, 0.15, dt)
    T.check(out.xfr.capt, fps .. " fps: CAPT XFR on AC 1 after 180 ms (LH24 p.228)")
    T.check(out.xfr.fo, fps .. " fps: F/O XFR stays on AC 2")
    T.check(out.stby.main, fps .. " fps: main standby bus on its inverter (FCOM p.804)")
    inp.gen_cont[3], inp.bus_tie[3] = true, true
    out = run(s, inp, 1.0, dt)
    T.check(out.ac[3] and s.xfr.capt.alt, fps .. " fps: CAPT XFR still on AC 1 1.0 s after AC 3 returns")
    out = run(s, inp, 0.3, dt)
    T.check(not s.xfr.capt.alt and out.xfr.capt, fps .. " fps: CAPT XFR back on AC 3 after 1.2 s")
end

-- DRIVE DISC (FCOM p.785-786, p.821): at idle it disconnects the IDG, opens
-- the GCB, lights DRIVE and shows >DRIVE DISC; the bus stays on through the
-- BTB. Pushed with the engine stopped it does nothing here (estimate).
do
    local s, inp = powered_up()
    engines(inp, 69)
    run(s, inp, 1)
    inp.drive_disc[1] = true
    local out = run(s, inp, 1)
    T.check(not out.idg_connected[1] and not out.gcb[1], "DRIVE DISC 1: IDG 1 disconnected, GCB 1 open")
    T.check(out.cas.drive_disc[1] and out.lights.drive[1], "DRIVE DISC 1: >DRIVE DISC 1 and DRIVE light (FCOM p.821)")
    T.check(not out.cas.drive[1], "DRIVE DISC 1: no ELEC DRIVE 1 once disconnected (FCOM p.821)")
    T.check(out.ac[1], "DRIVE DISC 1: AC 1 from the sync bus")
    inp.drive_disc[1] = false   -- the maintenance reset, on the ground
    out = run(s, inp, 1)
    T.check(out.idg_connected[1] and out.gcb[1], "reset: IDG 1 reconnected on the ground")

    s, inp = powered_up()
    run(s, inp, 1)
    inp.drive_disc[2] = true
    out = run(s, inp, 1)
    T.check(out.idg_connected[2], "DRIVE DISC 2 with the engine stopped: still connected (estimate)")
    T.check(not out.drive_disc_flag[2], "DRIVE DISC 2 with the engine stopped: the switch flag is reset")
end

-- Air mode (LH24 p.66, p.146-148, p.218; FCOM p.895): the APU generators are
-- for the ground only, and EXT/APU cannot be connected in the air.
do
    local s, inp = powered_up()
    engines(inp, 69)
    apu_running(inp)
    inp.on_ground = false
    local out = run(s, inp, 1)
    T.check(out.air_mode, "air: air mode")
    T.check(not out.lights.apu_avail[1] and not out.lights.apu_avail[2], "air: APU GEN AVAIL out (FCOM p.783)")
    inp.apu_request[1] = true
    out = run(s, inp, 1)
    T.check(not out.apb[1] and not inp.apu_request[1], "air: APU GEN request refused")
    T.check(all(out.gcb, 4, true), "air: IDGs stay on line")
    T.check(not out.ghb, "air: ground handling bus off (FCOM p.799)")
    -- on the ground, three engines at high N2 also make air mode (LH24 p.66)
    s, inp = powered_up()
    engines(inp, 80)
    out = run(s, inp, 1)
    T.check(out.air_mode, "ground, three or more IDGs at 6100 rpm: air mode (LH24 p.66)")
end

-- Load shedding in flight (LH24 p.236-238): with two generators, galley 1,
-- 4 and 2 go one a second, utility buses and galley 3 stay; ELEC UTIL BUS is
-- not shown meanwhile (FCOM p.795, p.822). With four generators again they
-- come back in reverse order.
do
    local s, inp = powered_up()
    engines(inp, 69)
    inp.on_ground = false
    local out = run(s, inp, 1)
    T.check(all(out.galley, 4, true) and all(out.util, 4, true), "4 gens: all utility and galley buses on")
    inp.gen_cont[1], inp.gen_cont[2] = false, false
    out = run(s, inp, 1.05)
    T.check(not out.galley[1] and out.galley[4], "2 gens: galley 1 shed first, after 1 s")
    out = run(s, inp, 1.05)
    T.check(not out.galley[4] and out.galley[2], "2 gens: then galley 4")
    out = run(s, inp, 1.05)
    T.check(not out.galley[2] and out.galley[3], "2 gens: then galley 2; galley 3 stays")
    out = run(s, inp, 5)
    T.check(out.galley[3] and all(out.util, 4, true), "2 gens: utility buses and galley 3 stay (LH24 p.238)")
    T.check(out.load_shed and not out.cas.util_bus[1], "2 gens: load shed, no ELEC UTIL BUS (FCOM p.795)")
    inp.gen_cont[1], inp.gen_cont[2] = true, true
    out = run(s, inp, 1.05)
    T.check(out.galley[2] and not out.galley[4], "4 gens: galley 2 back first")
    out = run(s, inp, 3)
    T.check(all(out.galley, 4, true) and not out.load_shed, "4 gens: all galleys back")
    -- UTILITY switch OFF: its buses off, OFF light, ELEC UTIL BUS (FCOM p.781, p.822)
    inp.utility[2] = false
    out = run(s, inp, 1)
    T.check(not out.util[3] and not out.galley[4], "R UTILITY OFF: utility 3 and galley 4 off")
    T.check(out.lights.util_off[2] and out.cas.util_bus[2], "R UTILITY OFF: OFF light, ELEC UTIL BUS R")
end

-- APU start on the batteries (LH24 p.158-159, p.200; FCOM p.804, p.896): the
-- APU inverter stops for 65 s, so the APU standby bus (captain's PFD and ND)
-- loses power; BAT DISCH APU is not shown while the APU starts.
do
    local s, inp = powered_up()
    run(s, inp, 1)
    inp.apu_start = true
    local out = run(s, inp, 1)
    T.check(not out.stby.apu and out.stby.main, "APU start: APU standby bus off, main standby on")
    out = run(s, inp, 60)
    T.check(not out.cas.bat_disch_apu, "APU start: no BAT DISCH APU while starting (LH24 p.200)")
    T.check(out.battery.apu.amps > 100, "APU start: the starter runs on the APU battery (FCOM p.896)")
    out = run(s, inp, 5)
    T.check(out.stby.apu, "APU start: APU standby bus back after 65 s")
    inp.apu_start = false
    apu_running(inp)
    inp.apu_request[1] = true
    out = run(s, inp, 1)
    T.check(all(out.ac, 4, true) and out.battery.apu.amps <= 0, "APU running: AC power, APU battery charging")
end

-- X-Plane stand-ins follow the breakers (notes §6)
do
    local s, inp = powered_up()
    apu_running(inp)
    run(s, inp, 1)
    inp.apu_request[1] = true
    local out = run(s, inp, 1)
    T.check(out.xp.battery_on and out.xp.apu_gen_on and not out.xp.gpu_on, "X-Plane: battery and APU generator on")
    T.check(out.xp.ac_power and not out.xp.generator_on[1], "X-Plane: AC power, engine generators off")
end

T.done()
