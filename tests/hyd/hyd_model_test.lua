-- Run from the repository root with LuaJIT: luajit tests/hyd/hyd_model_test.lua
-- The hydraulic model (plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/B747.19.hyd_model.lua)
-- against FCOM 13.10-13.30 and the HYDIM logic of ATA29_32 (p.141, p.143,
-- p.89): the panel lights and EICAS through the normal procedures (FCOM
-- p.104, p.119, p.126), the demand pump timers, engine pump loss, the fire
-- switch, power, the brake source and accumulator, quantity.
local T = dofile("tests/lib/check.lua")("hyd_model")
local H = dofile("plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/B747.19.hyd_model.lua")

local DT = 1 / 30
local function run(s, inp, seconds, dt)
    dt = dt or DT
    local out
    for _ = 1, math.max(1, math.floor(seconds / dt + 0.5)) do out = H.update(s, inp, dt) end
    return out
end
-- parked with everything off and no power
local function parked()
    local s, inp = H.new(), H.inputs()
    for n = 1, 4 do inp.dc[n], inp.ac[n] = false, false end
    return s, inp
end
-- power on: buses, the ground handling bus and APU bleed in both ducts
local function power(inp)
    for n = 1, 4 do inp.dc[n], inp.ac[n] = true, true end
    inp.gh_ac, inp.gh_dc = true, true
    inp.duct_psi[1], inp.duct_psi[2] = 30, 30
end
-- all four engines at idle, demand pumps AUTO (after Before Taxi)
local function engines_running(inp)
    power(inp)
    for n = 1, 4 do
        inp.n2[n], inp.fuel_cutoff[n], inp.demand_sel[n] = 65, false, 1
    end
end

-- preflight (FCOM p.104): engines off, DEMAND OFF, ENGINE ON: SYS FAULT,
-- DEMAND PRESS and ENGINE PRESS lit; EICAS shows HYD PRESS SYS, and the
-- pump messages give way to it (FCOM p.1582)
do
    local s, inp = parked()
    power(inp)
    inp.duct_psi[1], inp.duct_psi[2] = 0, 0
    local out = run(s, inp, 3)
    for n = 1, 4 do
        local o = out.sys[n]
        T.equal(o.psi, 0, "preflight: system " .. n .. " at 0 psi")
        T.check(o.light_sys_fault and o.light_dem_press and o.light_eng_press, "preflight: three lights on, system " .. n)
        T.check(o.press_sys, "preflight: HYD PRESS SYS " .. n)
        T.check(not o.press_eng and not o.press_dem, "preflight: no pump messages under HYD PRESS SYS " .. n)
    end
    T.check(out.brake_source_alert, "preflight: >BRAKE SOURCE")
    T.equal(out.acc_psi, 750, "preflight: the accumulator gauge shows its precharge (estimate)")
end

-- before start (FCOM p.119): system 4 AUX first: the AUX pump pressurises
-- it, SYS FAULT 4 goes out, DEMAND PRESS 4 stays on; then 1-3 AUTO with the
-- FUEL CONTROL CUTOFF run their demand pumps; ACMP 2 starts 1.5 s, ACMP 3
-- 3 s after leaving OFF (ATA29_32 p.70-72)
do
    local s, inp = parked()
    power(inp)
    run(s, inp, 1)
    inp.demand_sel[4] = -1
    local out = run(s, inp, 3)
    T.check(out.aux_running, "AUX: the AUX pump runs")
    T.check(out.sys[4].psi > 2900, "AUX: system 4 at about 3000 psi")
    T.check(out.aux_psi > 2900, "AUX: aux_pressure for the synoptic")
    T.check(not out.sys[4].light_sys_fault, "AUX: SYS FAULT 4 out")
    T.check(out.sys[4].light_dem_press, "AUX: DEMAND PRESS 4 stays on")
    T.check(out.sys[4].press_dem, "AUX: HYD PRESS DEM 4 while in AUX (FCOM p.1495)")
    T.check(not out.sys[4].dem_running, "AUX: the ADP does not run in AUX (FCOM p.1483)")
    T.equal(out.brake_source, 4, "AUX: brakes on system 4")
    for n = 1, 3 do inp.demand_sel[n] = 1 end
    out = run(s, inp, 1.0)
    T.check(out.sys[1].dem_running, "AUTO with CUTOFF: ADP 1 runs")
    T.check(not out.sys[2].dem_running, "AUTO: ACMP 2 not yet at 1.0 s")
    out = run(s, inp, 1.0)
    T.check(out.sys[2].dem_running and not out.sys[3].dem_running, "AUTO: ACMP 2 at 2.0 s, ACMP 3 not yet")
    out = run(s, inp, 1.5)
    T.check(out.sys[3].dem_running, "AUTO: ACMP 3 at 3.5 s")
    out = run(s, inp, 2)
    for n = 1, 3 do
        T.check(not out.sys[n].light_sys_fault and not out.sys[n].light_dem_press,
            "AUTO: SYS FAULT and DEMAND PRESS out, system " .. n)
        T.check(out.sys[n].light_eng_press, "AUTO: ENGINE PRESS stays on with the engine off, system " .. n)
    end
    T.check(out.sys[1].press_eng, "AUTO: HYD PRESS ENG 1 raised (the alert model hides it before start)")
end

-- after the engine starts the EDP pressurises; with AUTO the demand pump
-- stops 14 s after its pump's pressure is back (ATA29_32 p.141, p.143). The
-- same at 20, 30 and 45 fps.
for _, fps in ipairs({20, 30, 45}) do
    local dt = 1 / fps
    local s, inp = parked()
    power(inp)
    for n = 1, 4 do inp.demand_sel[n] = 1 end
    run(s, inp, 5, dt)
    inp.n2[2], inp.fuel_cutoff[2] = 65, false
    local out = run(s, inp, 1, dt)
    T.check(not out.sys[2].light_eng_press, fps .. " fps start: ENGINE PRESS 2 out")
    T.check(out.sys[2].dem_running, fps .. " fps start: ACMP 2 still runs at 1 s")
    out = run(s, inp, 12.5, dt)
    T.check(out.sys[2].dem_running, fps .. " fps start: ACMP 2 still runs at 13.5 s")
    out = run(s, inp, 1, dt)
    T.check(not out.sys[2].dem_running, fps .. " fps start: ACMP 2 stopped at 14.5 s")
    T.check(out.sys[2].psi > 2900, fps .. " fps start: system 2 on its engine pump")
end

-- an engine pump lost in flight: with AUTO the ADP takes over in 0.3 s;
-- ENGINE PRESS and HYD PRESS ENG after 2 s, no HYD PRESS SYS
do
    local s, inp = parked()
    engines_running(inp)
    inp.on_ground = false
    run(s, inp, 20)
    inp.engine_pump[1] = false
    local out = run(s, inp, 0.5)
    T.check(out.sys[1].dem_running, "EDP 1 off: ADP 1 runs")
    T.check(not out.sys[1].light_eng_press, "EDP 1 off: ENGINE PRESS not before 2 s")
    out = run(s, inp, 2)
    T.check(out.sys[1].light_eng_press and out.sys[1].press_eng, "EDP 1 off: ENGINE PRESS and HYD PRESS ENG 1")
    T.check(not out.sys[1].press_sys and out.sys[1].psi > 2800, "EDP 1 off: the system keeps its pressure")
    -- no bleed for the ADP: the system goes; DEMAND PRESS for the pump that
    -- does not run; the pump messages give way to HYD PRESS SYS
    inp.duct_psi[1] = 0
    out = run(s, inp, 1)
    T.check(not out.sys[1].light_dem_press, "no bleed: DEMAND PRESS not before 2 s")
    out = run(s, inp, 1.5)
    T.check(out.sys[1].light_dem_press and out.sys[1].press_dem, "no bleed: DEMAND PRESS and HYD PRESS DEM 1")
    out = run(s, inp, 20)
    T.check(out.sys[1].press_sys and not out.sys[1].press_dem and not out.sys[1].press_eng,
        "no bleed: HYD PRESS SYS 1 alone")
    T.check(not H.load_powered(out, "l_outbd_elevator"), "system 1 lost: left outboard elevator unpowered")
    T.check(H.load_powered(out, "l_inbd_elevator"), "system 1 lost: left inboard elevator on system 2")
    T.check(H.load_powered(out, "upper_rudder"), "system 1 lost: upper rudder on system 3")
end

-- the engine fire switch closes the supply valve and depressurises the
-- engine pump; the demand pump runs (FCOM p.905, p.1490)
do
    local s, inp = parked()
    engines_running(inp)
    inp.on_ground = false
    run(s, inp, 20)
    inp.fire_out[3] = true
    local out = run(s, inp, 3)
    T.check(not out.sys[3].sov_open, "fire 3: supply valve closed")
    T.check(not out.sys[3].edp_on, "fire 3: EDP 3 gives no pressure")
    T.check(out.sys[3].dem_running and out.sys[3].psi > 2800, "fire 3: ACMP 3 holds the system")
end

-- the motor pumps need their AC bus; commanded with no motor running:
-- DEMAND PRESS and HYD PRESS DEM (FCOM p.1484, p.1495)
do
    local s, inp = parked()
    engines_running(inp)
    run(s, inp, 20)
    inp.ac[2] = false
    inp.demand_sel[2] = 2
    local out = run(s, inp, 5)
    T.check(out.sys[2].dem_commanded and not out.sys[2].dem_running, "ACMP 2 ON, no AC bus 2: commanded, not running")
    T.check(out.sys[2].light_dem_press and out.sys[2].press_dem, "ACMP 2 no AC: DEMAND PRESS and HYD PRESS DEM 2")
    T.check(out.sys[2].psi > 2800, "ACMP 2 no AC: the engine pump keeps system 2")
    inp.demand_sel[2] = 0
    out = run(s, inp, 0.5)
    T.check(out.sys[2].light_dem_press and out.sys[2].press_dem, "DEMAND 2 OFF: DEMAND PRESS and HYD PRESS DEM 2")
end

-- ADP 1 and 4 in the air: running while the flaps are out and 10 s after
-- they are up (estimate on the timer); on the ground while they move
-- (ATA29_32 p.61-64; FCOM p.1483)
do
    local s, inp = parked()
    engines_running(inp)
    inp.on_ground, inp.flaps_down = false, true
    local out = run(s, inp, 20)
    T.check(out.sys[1].dem_running and out.sys[4].dem_running, "flaps out in the air: ADP 1 and 4 run")
    T.check(not out.sys[2].dem_running, "flaps out in the air: ACMP 2 does not")
    inp.flaps_down = false
    out = run(s, inp, 9)
    T.check(out.sys[1].dem_running, "flaps up: ADP 1 still at 9 s")
    out = run(s, inp, 2)
    T.check(not out.sys[1].dem_running, "flaps up: ADP 1 stopped at 11 s")
    inp.on_ground = true
    inp.flaps_moving = true
    out = run(s, inp, 1)
    T.check(out.sys[4].dem_running, "on the ground, flaps moving: ADP 4 runs")
    inp.flaps_moving = false
    out = run(s, inp, 1)
    T.check(not out.sys[4].dem_running, "on the ground, flaps stopped: ADP 4 stops")
end

-- brake source: 4, then 1 below 1200 psi on 4, then 2 below 1500 on 1, then
-- the accumulator, charged by system 4 (ATA29_32 p.388-392, p.408)
do
    local s, inp = parked()
    engines_running(inp)
    local out = run(s, inp, 20)
    T.equal(out.brake_source, 4, "brakes: normal on system 4")
    T.check(out.normal_brakes, "brakes: normal brakes for the autobrake")
    T.check(out.acc_psi > 2900, "brakes: system 4 charges the accumulator")
    for _, n in ipairs({4}) do inp.engine_pump[n], inp.demand_sel[n] = false, 0 end
    inp.gh_ac = false
    out = run(s, inp, 30)
    T.equal(out.brake_source, 1, "brakes: system 1 when 4 is low")
    T.check(out.acc_psi > 2900, "brakes: the accumulator holds")
    inp.engine_pump[1], inp.demand_sel[1] = false, 0
    out = run(s, inp, 30)
    T.equal(out.brake_source, 2, "brakes: system 2 when 1 is low too")
    inp.engine_pump[2], inp.demand_sel[2] = false, 0
    out = run(s, inp, 30)
    T.equal(out.brake_source, 0, "brakes: the accumulator when 4, 1 and 2 are low")
    T.check(out.brake_source_alert, "brakes: >BRAKE SOURCE")
    T.check(out.brake_psi > 2900, "brakes: accumulator pressure at the brakes")
    for _ = 1, 20 do inp.brake_use_in3 = 10; H.update(s, inp, DT) end
    inp.brake_use_in3 = 0
    out = run(s, inp, 0.1)
    T.equal(out.acc_psi, 750, "brakes: an empty accumulator shows its precharge")
    T.equal(out.brake_psi, 0, "brakes: and gives no pressure")
end

-- quantity: RF on the ground only, LO lights SYS FAULT and >HYD QTY LOW;
-- at 0.00 the engine pump loses its supply, the demand pump does not
-- (FCOM p.1485, p.1489; ATA29_32 p.104, p.116)
do
    local s, inp = parked()
    engines_running(inp)
    run(s, inp, 20)
    inp.qty_use[3] = 0.3
    local out = run(s, inp, DT)
    inp.qty_use[3] = 0
    T.check(out.sys[3].rf and not out.sys[3].lo, "qty 0.70: RF on the ground")
    inp.on_ground = false
    out = run(s, inp, 0.1)
    T.check(not out.sys[3].rf, "qty 0.70: no RF in the air")
    inp.qty_use[3] = 0.4
    out = run(s, inp, DT)
    inp.qty_use[3] = 0
    out = run(s, inp, 0.1)
    T.check(out.sys[3].lo and out.sys[3].qty_low and out.sys[3].light_sys_fault, "qty 0.30: LO, >HYD QTY LOW, SYS FAULT")
    inp.qty_use[3] = 0.3
    out = run(s, inp, DT)
    inp.qty_use[3] = 0
    out = run(s, inp, 1)
    T.check(not out.sys[3].edp_on, "qty 0.00: the engine pump has no supply")
    T.check(out.sys[3].dem_running and out.sys[3].psi > 2800, "qty 0.00: the demand pump keeps the system")
end

-- DC lost: the engine pump cannot be depressurised (estimate, ATA29_32
-- p.44); HYDIM 1 down: HYD CONTROL 1 (estimate)
do
    local s, inp = parked()
    engines_running(inp)
    run(s, inp, 5)
    inp.engine_pump[1] = false
    inp.dc[1] = false
    local out = run(s, inp, 3)
    T.check(out.sys[1].edp_on, "no DC 1: EDP 1 pressurises with its switch OFF")
    T.check(out.sys[4].control, "no DC 1: HYD CONTROL 4 (HYDIM-4 on DC bus 1, estimate)")
    T.check(not out.sys[1].control, "no DC 1: no HYD CONTROL 1 (HYDIM-1 on DC bus 4)")
    T.check(out.sys[4].status_hydim and not out.sys[1].status_hydim, "no DC 1: STATUS HYDIM 4 only")
end

-- STATUS messages (ATA29_32 p.137): HYD PRESS ENG with the engine pump
-- below 1400 psi, HYD PRESS DEM only while the demand pump runs low with
-- its engine running, HYD RSVR PRESS without bleed, HYD OVHT SYS above 104 °C
do
    local s, inp = parked()
    power(inp)
    local out = run(s, inp, 3)
    T.check(out.sys[2].status_eng, "STATUS: HYD PRESS ENG 2 with the engine stopped")
    T.check(not out.sys[2].status_dem, "STATUS: no HYD PRESS DEM 2 with the engine stopped")
    T.check(not out.sys[2].status_rsvr and not out.sys[2].status_hydim, "STATUS: reservoir and HYDIM fine")
    engines_running(inp)
    out = run(s, inp, 20)
    for n = 1, 4 do
        T.check(not out.sys[n].status_eng and not out.sys[n].status_dem, "STATUS: none with engine " .. n .. " running")
    end
    inp.demand_sel[3] = 2                       -- DEMAND 3 ON, with no AC bus 3: no pressure
    inp.ac[3] = false
    out = run(s, inp, 5)
    T.check(out.sys[3].status_dem, "STATUS: HYD PRESS DEM 3 with its pump commanded and low")
    inp.duct_psi[1], inp.duct_psi[2] = 0, 0
    out = run(s, inp, 900)
    T.check(out.sys[1].status_rsvr, "STATUS: HYD RSVR PRESS 1 without bleed")
    inp.oat = 90                                 -- 90 + 30 °C with the pumps running
    out = run(s, inp, 3600)
    T.check(out.sys[1].status_ovht, "STATUS: HYD OVHT SYS 1 above 104 °C")
end

-- HYD synoptic pump symbols (ATA29_32 p.105-106, FCOM p.1486-1488): a pump
-- giving pressure is the empty symbol; DEM AUTO cyan while not commanded,
-- OFF amber with the selector OFF (and system 4 on AUX), ON or AUTO amber
-- when commanded and low; EDP OFF with its switch OFF, ON amber when low;
-- AUX OFF white, cyan on standby, white running, amber when it cannot run
do
    local s, inp = parked()
    power(inp)
    local out = run(s, inp, 3)
    for n = 1, 4 do
        T.equal(out.sys[n].syn_edp, H.SYN_ON_AMBER, "synoptic: EDP " .. n .. " ON amber with the engine stopped")
        T.equal(out.sys[n].syn_dem, H.SYN_OFF, "synoptic: DEM " .. n .. " OFF with the selector OFF")
    end
    T.equal(out.syn_aux, H.SYN_AUX_OFF, "synoptic: AUX OFF while not selected")
    inp.demand_sel[4] = -1                      -- AUX: the AUX pump runs on the ground
    out = run(s, inp, 3)
    T.equal(out.syn_aux, H.SYN_AUX_ON, "synoptic: AUX running (white, empty)")
    T.equal(out.sys[4].syn_dem, H.SYN_OFF, "synoptic: DEM 4 OFF with the selector on AUX (FCOM p.1486)")
    inp.gh_ac = false                           -- no ground handling bus: the AUX pump stops
    out = run(s, inp, 3)
    T.equal(out.syn_aux, H.SYN_AUX_AMBER, "synoptic: AUX amber when it cannot run (estimate)")
    inp.gh_ac = true

    engines_running(inp)
    inp.demand_sel[4] = -1
    out = run(s, inp, 20)
    for n = 1, 4 do
        T.equal(out.sys[n].syn_edp, H.SYN_ON, "synoptic: EDP " .. n .. " empty with its engine running")
    end
    for n = 1, 3 do
        T.equal(out.sys[n].syn_dem, H.SYN_AUTO, "synoptic: DEM " .. n .. " AUTO (cyan) while not needed")
    end
    T.equal(out.syn_aux, H.SYN_AUX_STANDBY, "synoptic: AUX cyan while EDP 4 gives pressure")
    inp.demand_sel[4] = 1

    inp.engine_pump[2] = false                  -- ENGINE pump 2 OFF: DEM 2 runs on demand
    out = run(s, inp, 5)
    T.equal(out.sys[2].syn_edp, H.SYN_OFF, "synoptic: EDP 2 OFF with its switch OFF")
    T.equal(out.sys[2].syn_dem, H.SYN_ON, "synoptic: DEM 2 running in AUTO shows the empty symbol")
    inp.ac[2] = false                           -- and no AC bus 2: commanded, no pressure
    out = run(s, inp, 5)
    T.equal(out.sys[2].syn_dem, H.SYN_AUTO_AMBER, "synoptic: DEM 2 AUTO amber, commanded and low")
    inp.demand_sel[2] = 2
    out = run(s, inp, 1)
    T.equal(out.sys[2].syn_dem, H.SYN_ON_AMBER, "synoptic: DEM 2 ON amber with the selector ON and low")
    inp.ac[2], inp.engine_pump[2], inp.demand_sel[2] = true, true, 1

    inp.fire_out[3] = true                      -- fire switch 3: SOV closed, EDP 3 depressurised
    out = run(s, inp, 5)
    T.check(not out.sys[3].sov_open, "synoptic: SOV 3 closed by the fire switch")
    T.equal(out.sys[3].syn_edp, H.SYN_ON_AMBER, "synoptic: EDP 3 ON amber (switch ON, no pressure)")
    T.check(out.sys[3].sov_open == false and out.sys[2].sov_open, "synoptic: only SOV 3 closed")
end

T.done()
