-- 747-400 hydraulic power without X-Plane: the pumps of the four systems
-- (engine pumps, the air driven demand pumps of systems 1 and 4, the AC
-- motor pumps of systems 2 and 3, the auxiliary pump of system 4), the HYDIM
-- logic that runs the demand pumps and drives the P5 lights and the EICAS
-- messages, system pressure, quantity, temperature, reservoir pressure, and
-- the brake source and accumulator. Logic and sources:
-- docs/overhaul/notes/ATA-29.md §2-§4 (HYDIM logic ATA29_32 p.141 for
-- systems 1 and 4, p.143 for 2 and 3, p.89 for the AUX pump; FCOM 13.10-13.30).
--
--   local H = B747_hyd_model               -- in XTLua, after dofile
--   local H = dofile(".../B747.19.hyd_model.lua")   -- in the tests
--   local s = H.new()
--   local inp = H.inputs()                 -- fill it every frame
--   local out = H.update(s, inp, dt)       -- the same table every frame

local M = setmetatable({}, {})
B747_hyd_model = M

M.NOMINAL_PSI = 3000            -- no flow (ATA22 p.6)
M.RATED_PSI = 2850              -- the pumps' rating point (ATA29_32 p.26)
M.PS_LOW_PSI = 1400             -- pump pressure switches (ATA29_32 p.61, p.141)
M.PS_RESET_PSI = 1600           -- EDP switch reset (p.61); the demand switch alike (estimate)
M.SYS_LOW_PSI = 1200            -- system pressure (p.98)
M.POWERED_PSI = 1000            -- a load has hydraulic power (estimate: no value in the sources;
                                -- the old code used 900 and 1000)
M.ALERT_DELAY_S = 2             -- HYDIM outputs (p.141, p.143)
M.RUN_ON_S, M.RUN_OFF_S = 0.3, 14         -- demand pump run on demand (p.141, p.143)
M.ACMP_DELAY_S = {[2] = 1.5, [3] = 3.0}   -- motor pump start after leaving OFF (p.70-72)
M.ADP_FLAPS_HOLD_S = 10         -- ADP keeps running in the air after the flaps are up (estimate:
                                -- p.141 has a 10 s timer whose kind cannot be read)
M.OVHT_C = 104                  -- case drain temperature (p.100)
M.QTY_LO, M.QTY_RF = 0.34, 0.75 -- p.116; RF on the ground only (FCOM p.1489)
M.RSVR_PSI, M.RSVR_LOW_PSI = 45, 6.3      -- reservoir pressurisation (p.38)
M.ENGINE_RUNNING_N2 = 50        -- HYD PRESS DEM (status) waits for its engine (p.137; the
                                -- running speed is an estimate: starter cutout is at 50 %)
M.BRAKE_PSI = {[4] = 1200, [1] = 1500, [2] = 1500}   -- brake source selection (ATA29_32 p.390;
                                -- system 2's switch value estimated)
M.ACC_PRECHARGE_PSI, M.ACC_GAS_IN3 = 750, 200        -- brake accumulator (ATA29_32 p.408)

-- HYD synoptic pump symbols (ATA29_32 p.105-106). ON (white) is the empty
-- symbol: both figures draw a pump that gives pressure without a word
-- (FCOM p.1486, ATA29_32 p.107). The engine pump uses ON, ON_AMBER and OFF.
M.SYN_ON, M.SYN_ON_AMBER, M.SYN_AUTO_AMBER, M.SYN_AUTO, M.SYN_OFF = 0, 1, 2, 3, 4
M.SYN_AUX_OFF, M.SYN_AUX_STANDBY, M.SYN_AUX_ON, M.SYN_AUX_AMBER = 0, 1, 2, 3

-- flow at the rated pressure, gpm (ATA29_32 p.26, p.68, p.84)
M.EDP_GPM, M.ADP_GPM, M.ACMP_GPM, M.AUX_GPM = 37.5, 32, 6, 5.7
-- estimates (the sources give no values): leakage of a system, the bleed duct
-- pressure the ADP turbine needs, how fast pressure builds and decays, the
-- accumulator charging, the temperature of a system with a pump running
M.LEAK_GPM = 0.5
M.ADP_DUCT_MIN_PSI, M.ADP_DUCT_FULL_PSI = 5, 15
M.PRESS_UP_S, M.PRESS_DOWN_S = 0.5, 4
M.ACC_CHARGE_S = 1
M.TEMP_LAG_S, M.TEMP_RISE_C = 600, 30     -- FCOM p.1485 shows 50 °C
M.RSVR_DECAY_S = 300

-- DC buses: HYDIM n, and the demand pump control (ATA29_32 p.63, p.71;
-- ATA22 p.22, p.24; HYDIM-3 and -4 and ACMP 3 control by symmetry, estimate)
M.HYDIM_BUS = {4, 3, 2, 1}
M.CONTROL_BUS = {1, 2, 3, 4}
M.ADP_DUCT = {[1] = 1, [4] = 2}           -- ADP 1 left duct, ADP 4 right (estimate, FCOM p.614)

-- the loads and the systems that power them (FCOM p.943-953, p.1490-1491,
-- p.1511-1516); a load has power while one of its systems has
M.LOADS = {
    l_outbd_aileron = {1, 2}, l_inbd_aileron = {1, 3}, r_inbd_aileron = {2, 4}, r_outbd_aileron = {3, 4},
    l_outbd_elevator = {1}, l_inbd_elevator = {1, 2}, r_inbd_elevator = {3, 4}, r_outbd_elevator = {4},
    upper_rudder = {1, 3}, lower_rudder = {2, 4},
    upper_yaw_damper = {3}, lower_yaw_damper = {2},
    elev_feel = {2, 3}, stab_trim = {2, 3},
    spoilers_2_3_10_11 = {2}, spoilers_1_4_9_12 = {3}, spoilers_5_6_7_8 = {4},
    autopilot_c = {1}, autopilot_r = {2}, autopilot_l = {3},
    inbd_te_flaps = {1}, outbd_te_flaps = {4},
    nose_body_gear = {1}, wing_gear = {4}, steering = {1},
}

function M.inputs()
    return {
        engine_pump = {true, true, true, true},   -- ENGINE pump switch ON
        demand_sel = {0, 0, 0, 0},                -- -1 AUX (system 4 only), 0 OFF, 1 AUTO, 2 ON
        fire_out = {false, false, false, false},  -- engine fire switch pulled
        fuel_cutoff = {true, true, true, true},   -- FUEL CONTROL CUTOFF
        n2 = {0, 0, 0, 0},                        -- %
        dc = {true, true, true, true},            -- DC bus 1-4 powered
        ac = {true, true, true, true},            -- AC bus 1-4 powered
        gh_ac = false, gh_dc = false,             -- ground handling bus, AC and DC
        duct_psi = {0, 0},                        -- left and right bleed duct
        on_ground = true,                         -- air/ground relay
        flaps_moving = false,                     -- trailing edge flaps in transit (FCU)
        flaps_down = false,                       -- trailing edge flaps not up (FCU)
        demand_gpm = {0, 0, 0, 0},                -- what the loads draw from each system
        qty_use = {0, 0, 0, 0},                   -- quantity the loads took this frame (ratio)
        brake_use_in3 = 0,                        -- fluid the brakes took from the accumulator
        oat = 15,                                 -- °C
    }
end

function M.new()
    local s = {t = 0, first = true, acc_psi = M.ACC_PRECHARGE_PSI, rsvr_psi = 0, sys = {}}
    local out = {sys = {}, aux_psi = 0, aux_running = false, brake_source = 0, brake_psi = 0,
        acc_psi = M.ACC_PRECHARGE_PSI, brake_source_alert = false, normal_brakes = false,
        syn_aux = M.SYN_AUX_OFF}
    for n = 1, 4 do
        s.sys[n] = {
            psi = 0, qty = 1.0, temp = 15,
            edp_low = true, dem_low = true,       -- pressure switches
            demand_t = 0, demand_run = false,     -- run on demand: time in the new state, output
            ready_t = 0,                          -- ACMP: time since the selector left OFF
            flaps_t = M.ADP_FLAPS_HOLD_S,         -- ADP: time since the flaps came up in the air
            edp_low_t = 0, sys_low_t = 0, dem_low_t = 0,
            dem_low_any_t = 0,                    -- demand pump output low, commanded or not
        }
        out.sys[n] = {
            psi = 0, edp_psi = 0, dem_psi = 0, qty = 1.0, temp = 15,
            sov_open = true, edp_on = false, dem_commanded = false, dem_running = false,
            powered = false, rf = false, lo = false, rsvr_low = true,
            light_eng_press = true, light_dem_press = true, light_sys_fault = true,
            press_sys = false, press_eng = false, press_dem = false, ovht = false, qty_low = false,
            control = false,
            status_eng = true, status_dem = false, status_ovht = false, status_rsvr = true,
            status_hydim = true,
            syn_edp = M.SYN_ON_AMBER, syn_dem = M.SYN_OFF,
        }
    end
    s.out = out
    return s
end

-- a flight that starts with the engines running: the systems pressurised,
-- the engine pump switches reset
function M.preset_running(s)
    for n = 1, 4 do
        local ss = s.sys[n]
        ss.psi, ss.edp_low, ss.edp_low_t, ss.sys_low_t = M.NOMINAL_PSI, false, 0, 0
    end
    s.acc_psi = M.NOMINAL_PSI
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

-- a pressure switch with its hysteresis
local function switch_low(low, psi)
    if psi < M.PS_LOW_PSI then return true end
    if psi >= M.PS_RESET_PSI then return false end
    return low
end

-- run on demand: on 0.3 s after the condition, off 14 s after it ends
local function run_on_demand(ss, cond, dt)
    if cond == ss.demand_run then
        ss.demand_t = 0
    else
        ss.demand_t = ss.demand_t + dt
        if ss.demand_t >= (cond and M.RUN_ON_S or M.RUN_OFF_S) then
            ss.demand_run, ss.demand_t = cond, 0
        end
    end
    return ss.demand_run
end

local function lag(x, target, tau, dt)
    return x + (target - x) * math.min(1, dt / tau)
end

function M.update(s, inp, dt)
    s.t = s.t + dt
    local out = s.out

    -- reservoirs: bleed air regulated to 45 psi (p.38); held a while
    -- without bleed (estimate)
    local duct = math.max(inp.duct_psi[1], inp.duct_psi[2])
    local rsvr = math.min(M.RSVR_PSI, duct)
    if rsvr >= s.rsvr_psi or s.first then s.rsvr_psi = rsvr
    else s.rsvr_psi = lag(s.rsvr_psi, rsvr, M.RSVR_DECAY_S, dt) end

    for n = 1, 4 do
        local ss, o = s.sys[n], out.sys[n]
        local sel = inp.demand_sel[n]
        local auto, on, aux = sel == 1, sel == 2, sel == -1 and n == 4
        local hydim = inp.dc[M.HYDIM_BUS[n]]
        local control = inp.dc[M.CONTROL_BUS[n]]

        -- engine pump: the fire switch closes the supply shutoff valve and
        -- depressurises the pump; the depressurising solenoid needs DC, so
        -- without it the pump pressurises (ATA29_32 p.40, p.44-46; the bus
        -- is not given: DC bus n, estimate)
        o.sov_open = not inp.fire_out[n]
        local depress = inp.dc[n] and (not inp.engine_pump[n] or inp.fire_out[n])
        local edp_gpm = 0
        if not depress and o.sov_open and ss.qty > 0 then
            edp_gpm = M.EDP_GPM * clamp(inp.n2[n] / 100, 0, 1)   -- flow with N2 (estimate, FCTM p.286)
        end
        o.edp_on = edp_gpm > 0

        -- demand pump (ATA29_32 p.141, p.143)
        local dem_gpm, commanded = 0, false
        if n == 1 or n == 4 then
            local flaps
            if inp.on_ground then
                ss.flaps_t = M.ADP_FLAPS_HOLD_S
                flaps = inp.flaps_moving
            else
                if inp.flaps_down then ss.flaps_t = 0 else ss.flaps_t = ss.flaps_t + dt end
                flaps = ss.flaps_t < M.ADP_FLAPS_HOLD_S
            end
            local demand = run_on_demand(ss, auto and ss.edp_low, dt)
            local auto_run = hydim and auto and (flaps or inp.fuel_cutoff[n] or demand)
            commanded = control and (on or auto_run)
            if commanded then
                local d = inp.duct_psi[M.ADP_DUCT[n]]
                dem_gpm = M.ADP_GPM * clamp((d - M.ADP_DUCT_MIN_PSI) / (M.ADP_DUCT_FULL_PSI - M.ADP_DUCT_MIN_PSI), 0, 1)
            end
            o.control = not hydim                 -- HYD CONTROL 1, 4 (estimate, notes §4.2)
        else
            if sel == 0 then ss.ready_t = 0 else ss.ready_t = ss.ready_t + dt end
            local ready = ss.ready_t >= M.ACMP_DELAY_S[n]
            local demand = run_on_demand(ss, auto and ready and ss.edp_low, dt)
            local auto_run = hydim and auto and ready and (inp.fuel_cutoff[n] or demand)
            commanded = control and ((on and ready) or auto_run)   -- the ELCU closes
            if commanded and inp.ac[n] then dem_gpm = M.ACMP_GPM end
            o.control = false
        end
        o.dem_commanded = commanded
        o.dem_running = dem_gpm > 0

        -- AUX pump of system 4: on the ground with the ground handling bus,
        -- while neither the engine pump nor the demand pump gives pressure
        -- (ATA29_32 p.86-89)
        local aux_gpm = 0
        if n == 4 then
            out.aux_running = aux and inp.on_ground and inp.gh_ac and inp.gh_dc and ss.edp_low and ss.dem_low
            if out.aux_running then aux_gpm = M.AUX_GPM end
        end

        -- system pressure: 3000 psi with no flow, lower as the loads take
        -- what the pumps give, falling when they cannot (estimate, notes §4.7)
        local capacity = edp_gpm + dem_gpm + aux_gpm
        local draw = M.LEAK_GPM + inp.demand_gpm[n]
        local target = 0
        if capacity >= draw then
            target = M.NOMINAL_PSI - (M.NOMINAL_PSI - M.RATED_PSI) * draw / capacity
        elseif capacity > 0 then
            target = M.RATED_PSI * capacity / draw
        end
        ss.psi = lag(ss.psi, target, (target > ss.psi) and M.PRESS_UP_S or M.PRESS_DOWN_S, dt)
        o.psi = ss.psi
        o.powered = ss.psi >= M.POWERED_PSI
        -- each pump's switch sees its own outlet only (check valves, p.78)
        o.edp_psi = (edp_gpm > 0) and ss.psi or 0
        o.dem_psi = (dem_gpm > 0) and ss.psi or 0
        if n == 4 then out.aux_psi = (aux_gpm > 0) and ss.psi or 0 end
        ss.edp_low = switch_low(ss.edp_low, o.edp_psi)
        ss.dem_low = switch_low(ss.dem_low, o.dem_psi)

        -- quantity and temperature
        ss.qty = ss.qty - inp.qty_use[n]
        o.qty = ss.qty
        o.lo = ss.qty <= M.QTY_LO
        o.rf = inp.on_ground and ss.qty <= M.QTY_RF
        local heat = (edp_gpm + dem_gpm + aux_gpm > 0) and M.TEMP_RISE_C or 0
        if s.first then ss.temp = inp.oat + heat
        else ss.temp = lag(ss.temp, inp.oat + heat, M.TEMP_LAG_S, dt) end
        o.temp = ss.temp
        o.rsvr_low = s.rsvr_psi < M.RSVR_LOW_PSI

        -- HYDIM outputs (notes §4.6; ATA29_32 p.141, p.143)
        if ss.edp_low then ss.edp_low_t = ss.edp_low_t + dt else ss.edp_low_t = 0 end
        if ss.psi < M.SYS_LOW_PSI then ss.sys_low_t = ss.sys_low_t + dt else ss.sys_low_t = 0 end
        if commanded and ss.dem_low then ss.dem_low_t = ss.dem_low_t + dt else ss.dem_low_t = 0 end
        local edp_low2 = ss.edp_low_t >= M.ALERT_DELAY_S
        local sys_low2 = ss.sys_low_t >= M.ALERT_DELAY_S
        local dem_low2 = ss.dem_low_t >= M.ALERT_DELAY_S
        o.light_eng_press = edp_low2
        o.light_dem_press = sel == 0 or aux or dem_low2
        o.ovht = ss.temp > M.OVHT_C
        o.light_sys_fault = sys_low2 or o.lo or o.ovht
        -- EICAS. The pump messages give way to HYD PRESS SYS (FCOM p.1582);
        -- the alert model hides HYD PRESS ENG on the ground with the FUEL
        -- CONTROL CUTOFF or the fire switch out (FCOM p.1586)
        o.press_sys = sys_low2
        o.press_eng = edp_low2 and not sys_low2
        o.press_dem = o.light_dem_press and not sys_low2
        o.qty_low = o.lo
        -- STATUS (ATA29_32 p.137): each pump's output below 1400 psi (the
        -- demand pump while it is commanded and its engine runs), above
        -- 104 °C, the reservoir below 6.3 psig, the HYDIM bus inactive
        o.status_eng = edp_low2
        o.status_dem = dem_low2 and inp.n2[n] >= M.ENGINE_RUNNING_N2
        o.status_ovht = o.ovht
        o.status_rsvr = o.rsvr_low
        o.status_hydim = not hydim

        -- HYD synoptic (ATA29_32 p.105-106): the pump symbols from the
        -- switches and the pressure switches, which wait as the lights do
        -- (estimate). With system 4 on AUX its demand pump shows OFF (FCOM
        -- p.1486).
        if ss.dem_low then ss.dem_low_any_t = ss.dem_low_any_t + dt else ss.dem_low_any_t = 0 end
        if not inp.engine_pump[n] then o.syn_edp = M.SYN_OFF
        elseif edp_low2 then o.syn_edp = M.SYN_ON_AMBER
        else o.syn_edp = M.SYN_ON end
        if sel <= 0 then o.syn_dem = M.SYN_OFF
        elseif on then
            if ss.dem_low_any_t >= M.ALERT_DELAY_S then o.syn_dem = M.SYN_ON_AMBER else o.syn_dem = M.SYN_ON end
        elseif not commanded then o.syn_dem = M.SYN_AUTO
        elseif dem_low2 then o.syn_dem = M.SYN_AUTO_AMBER
        else o.syn_dem = M.SYN_ON end
        -- the AUX pump: cyan while the engine pump gives pressure, white while
        -- it runs, amber while it cannot (estimate: the source gives white and
        -- amber the same condition)
        if n == 4 then
            if not aux then out.syn_aux = M.SYN_AUX_OFF
            elseif not edp_low2 then out.syn_aux = M.SYN_AUX_STANDBY
            elseif out.aux_running then out.syn_aux = M.SYN_AUX_ON
            else out.syn_aux = M.SYN_AUX_AMBER end
        end
    end

    -- brake source: system 4, then 1, then 2, then the accumulator, which
    -- system 4 charges (ATA29_32 p.388-392, p.408; FCOM p.1514-1516)
    local p4 = s.sys[4].psi
    if p4 > s.acc_psi then s.acc_psi = lag(s.acc_psi, p4, M.ACC_CHARGE_S, dt) end
    local source = 0
    if p4 >= M.BRAKE_PSI[4] then source = 4
    elseif s.sys[1].psi >= M.BRAKE_PSI[1] then source = 1
    elseif s.sys[2].psi >= M.BRAKE_PSI[2] then source = 2 end
    local gas = M.ACC_GAS_IN3
    local fluid = gas * (1 - M.ACC_PRECHARGE_PSI / math.max(s.acc_psi, M.ACC_PRECHARGE_PSI))
    if source == 0 and inp.brake_use_in3 > 0 then
        fluid = math.max(0, fluid - inp.brake_use_in3)
        s.acc_psi = M.ACC_PRECHARGE_PSI * gas / (gas - fluid)
    end
    out.brake_source = source
    out.normal_brakes = source == 4            -- autobrake needs the normal brakes (FCOM p.1515)
    out.brake_source_alert = source == 0       -- >BRAKE SOURCE (FCOM p.1521)
    out.acc_psi = s.acc_psi                    -- the gauge shows the precharge with no fluid (estimate)
    if source > 0 then out.brake_psi = s.sys[source].psi
    elseif fluid > 0 then out.brake_psi = s.acc_psi
    else out.brake_psi = 0 end

    s.first = false
    return out
end

-- whether a load of M.LOADS has hydraulic power
function M.load_powered(out, name)
    for _, n in ipairs(M.LOADS[name]) do
        if out.sys[n].powered then return true end
    end
    return false
end

return M
