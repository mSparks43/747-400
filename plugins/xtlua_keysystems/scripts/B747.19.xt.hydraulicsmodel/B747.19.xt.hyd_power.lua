-- The hydraulic model (B747.19.hyd_model.lua) in the aircraft: reads the
-- P5 HYD panel, the engines, the fire and FUEL CONTROL switches, the buses,
-- the bleed ducts, air/ground and the flaps; runs the model every frame and
-- writes the system pressures the flight controls and the autopilot use,
-- the synoptic, STATUS and brake accumulator values (notes/ATA-29.md §6.2),
-- the P5 lights and the EICAS messages. B747.19.xt.hydraulicsmodel.lua loads
-- it after its bindings and uses them (binding a number dataref again under
-- the same name would write 0 to it).
-- The flight controls still take pressure for each move from the model's
-- pressure (B747.19.xt.hydraulics_override.lua: pressure_input,
-- pressure_output, which writes the system pressures); what they took is the
-- model's demand in the next frame.
dofile("B747.19.hyd_model.lua")
local H = B747_hyd_model

simDR_hyd_engine_N2             = find_dataref("sim/flightmodel/engine/ENGN_N2_")
B747DR_hyd_fuel_control         = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")
B747DR_hyd_fire_handle_1        = find_dataref("laminar/B747/fire/engine01/ext_switch/pos_arm")
B747DR_hyd_fire_handle_2        = find_dataref("laminar/B747/fire/engine02/ext_switch/pos_arm")
B747DR_hyd_fire_handle_3        = find_dataref("laminar/B747/fire/engine03/ext_switch/pos_arm")
B747DR_hyd_fire_handle_4        = find_dataref("laminar/B747/fire/engine04/ext_switch/pos_arm")
B747DR_hyd_elec_ac              = find_dataref("laminar/B747/electrical/bus/ac")
B747DR_hyd_elec_dc              = find_dataref("laminar/B747/electrical/bus/dc")
B747DR_hyd_elec_gnd_hdlg        = find_dataref("laminar/B747/electrical/bus/gnd_hdlg")
B747DR_hyd_elec_gnd_hdlg_dc     = find_dataref("laminar/B747/electrical/bus/gnd_hdlg_dc")
B747DR_hyd_pseu_alt_air         = find_dataref("laminar/B747/gear/air_ground/alt_air")
B747DR_hyd_light_eng_press      = find_dataref("laminar/B747/hydraulics/light/eng_press")
B747DR_hyd_light_dem_press      = find_dataref("laminar/B747/hydraulics/light/dem_press")
B747DR_hyd_light_sys_fault      = find_dataref("laminar/B747/hydraulics/light/sys_fault")
B747DR_hyd_light_brake_source   = find_dataref("laminar/B747/hydraulics/light/brake_source")
B747DR_hyd_CAS_caution          = find_dataref("laminar/B747/CAS/caution_status")
B747DR_hyd_CAS_advisory         = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_hyd_CAS_status           = find_dataref("laminar/B747/CAS/status_status")
B747DR_hyd_stat_RF              = find_dataref("laminar/B747/EICAS2/stat/RF")
B747DR_hyd_stat_LO              = find_dataref("laminar/B747/EICAS2/stat/LO")
B747DR_hyd_syn_edp              = find_dataref("laminar/B747/hydraulics/synoptic/edp")
B747DR_hyd_syn_dem              = find_dataref("laminar/B747/hydraulics/synoptic/dem")
B747DR_hyd_syn_aux              = find_dataref("laminar/B747/hydraulics/synoptic/aux")
B747DR_hyd_syn_sov              = find_dataref("laminar/B747/hydraulics/synoptic/sov")
B747DR_hyd_syn_rsvr_press       = find_dataref("laminar/B747/hydraulics/synoptic/rsvr_press")
B747DR_hyd_syn_text_off         = find_dataref("laminar/B747/hydraulics/synoptic/text_off")
B747DR_hyd_syn_text_auto        = find_dataref("laminar/B747/hydraulics/synoptic/text_auto")

-- estimates: flow for the pressure the flight controls take (their old
-- pressure budget, B747.19.xt.hydraulics_override.lua), and the brake
-- accumulator fluid one full parking brake application takes
local GPM_PER_PSI_S = 0.03
local BRAKE_APPLY_IN3 = 20
local FLAP_MOVING_DEG, FLAP_DOWN_DEG = 0.2, 0.5   -- flap position against its command (estimate)

-- EICAS message slots (laminar/B747/CAS/*_status, B747.87.xt.warning.lua)
local CAUTION_BRAKE_SOURCE = 9
local CAUTION_PRESS_SYS = 40        -- HYD PRESS SYS 1-4: 40-43
local ADV_CONTROL = {[1] = 200, [4] = 201}   -- HYD CONTROL 1, 4
local ADV_OVHT = 202                -- HYD OVHT SYS 1-4: 202-205
local ADV_PRESS_DEM = 206           -- HYD PRESS DEM 1-4: 206-209
local ADV_PRESS_ENG = 210           -- HYD PRESS ENG 1-4: 210-213
local ADV_QTY_LOW = 218             -- >HYD QTY LOW 1-4: 218-221
-- STATUS slots (laminar/B747/CAS/status_status, B747.87.xt.warning.lua)
local STATUS_PRESS_ENG = 0          -- HYD PRESS ENG 1-4: 0-3
local STATUS_PRESS_DEM = 4          -- HYD PRESS DEM 1-4: 4-7
local STATUS_OVHT = 8               -- HYD OVHT SYS 1-4: 8-11
local STATUS_RSVR = 12              -- HYD RSVR PRESS 1-4: 12-15
local STATUS_HYDIM = 16             -- HYDIM 1-4: 16-19
local ENGINE_PUMP_SWITCH = 30       -- button_switch/position[30-33]: ENGINE pump 1-4

local hyd_state = H.new()
local hyd_inputs = H.inputs()
local took_psi = {0, 0, 0, 0}       -- what the flight controls took last frame
local last_parking_brake = nil
-- X-Plane's hydraulic leak failures: the system each one drains, and how
-- many seconds it takes (as before; the system is picked once, HYD-08)
local leak_s = {0, 0, 0, 0}
local leak_picked = {}

local function flag(v)
    if v then return 1 end
    return 0
end

local fails = {false, false, false}
local function leak_failures()
    fails[1], fails[2], fails[3] = simDR_failhyd1 == 6, simDR_failhyd2 == 6, simDR_failhyd3 == 6
    if not (fails[1] or fails[2] or fails[3]) then
        if next(leak_picked) then
            for n = 1, 4 do leak_s[n], hyd_state.sys[n].qty = 0, 1.0 end
            leak_picked = {}
        end
        return
    end
    for i = 1, 3 do
        if fails[i] and not leak_picked[i] then
            local n = i + math.floor(math.random() + 0.5)   -- leak i drains system i or i + 1
            leak_s[n] = 15 + math.random() * 15
            leak_picked[i] = true
        end
    end
end

local function read_inputs(inp, dt)
    for n = 1, 4 do
        inp.engine_pump[n] = B747DR_button_switch_position[ENGINE_PUMP_SWITCH + n - 1] > 0.95
        inp.demand_sel[n] = B747DR_hyd_dmd_pmp_sel_pos[n - 1]
        inp.fuel_cutoff[n] = B747DR_hyd_fuel_control[n - 1] < 0.5
        inp.n2[n] = simDR_hyd_engine_N2[n - 1]
        inp.dc[n] = B747DR_hyd_elec_dc[n - 1] > 0.5
        inp.ac[n] = B747DR_hyd_elec_ac[n - 1] > 0.5
        inp.demand_gpm[n] = took_psi[n] / math.max(dt, 0.001) * GPM_PER_PSI_S
        if leak_s[n] > 0 then inp.qty_use[n] = dt / leak_s[n] else inp.qty_use[n] = 0 end
    end
    inp.fire_out[1] = B747DR_hyd_fire_handle_1 > 0.5
    inp.fire_out[2] = B747DR_hyd_fire_handle_2 > 0.5
    inp.fire_out[3] = B747DR_hyd_fire_handle_3 > 0.5
    inp.fire_out[4] = B747DR_hyd_fire_handle_4 > 0.5
    inp.gh_ac = B747DR_hyd_elec_gnd_hdlg > 0.5
    inp.gh_dc = B747DR_hyd_elec_gnd_hdlg_dc > 0.5
    inp.duct_psi[1] = B747_duct_pressure_L
    inp.duct_psi[2] = B747_duct_pressure_R
    inp.on_ground = B747DR_hyd_pseu_alt_air == 0   -- the alternate air/ground relay (ATA29_32 p.63)
    -- the trailing edge flaps against their command (the FCU signals)
    local p1, p2, p3, p4 = B747DR_flaps[1], B747DR_flaps[2], B747DR_flaps[3], B747DR_flaps[4]
    inp.flaps_moving = math.abs(p1 - B747DR_flap1) > FLAP_MOVING_DEG or math.abs(p2 - B747DR_flap2) > FLAP_MOVING_DEG
        or math.abs(p3 - B747DR_flap3) > FLAP_MOVING_DEG or math.abs(p4 - B747DR_flap4) > FLAP_MOVING_DEG
    inp.flaps_down = math.max(p1, p2, p3, p4) > FLAP_DOWN_DEG
    inp.oat = B747DR_hyd_temp
    -- fluid the parking brake takes as it is set
    local pb = simDR_parking_brake_ratio
    if last_parking_brake == nil then last_parking_brake = pb end
    inp.brake_use_in3 = math.max(0, pb - last_parking_brake) * BRAKE_APPLY_IN3
    last_parking_brake = pb
end

local function write_outputs(out)
    local sys = out.sys
    B747DR_hyd_edp_pressure_1, B747DR_hyd_dem_pressure_1 = sys[1].edp_psi, sys[1].dem_psi
    B747DR_hyd_edp_pressure_2, B747DR_hyd_dem_pressure_2 = sys[2].edp_psi, sys[2].dem_psi
    B747DR_hyd_edp_pressure_3, B747DR_hyd_dem_pressure_3 = sys[3].edp_psi, sys[3].dem_psi
    B747DR_hyd_edp_pressure_4, B747DR_hyd_dem_pressure_4 = sys[4].edp_psi, sys[4].dem_psi
    B747DR_hyd_aux_pressure = out.aux_psi
    -- synoptic: the demand selector; one value for the supply valve open and
    -- the engine pump on (notes/ATA-29.md §6.2)
    B747DR_hyd_dem_mode_1 = hyd_inputs.demand_sel[1]
    B747DR_hyd_dem_mode_2 = hyd_inputs.demand_sel[2]
    B747DR_hyd_dem_mode_3 = hyd_inputs.demand_sel[3]
    B747DR_hyd_dem_mode_4 = hyd_inputs.demand_sel[4]
    B747DR_hyd_valve_1 = flag(sys[1].sov_open and hyd_inputs.engine_pump[1])
    B747DR_hyd_valve_2 = flag(sys[2].sov_open and hyd_inputs.engine_pump[2])
    B747DR_hyd_valve_3 = flag(sys[3].sov_open and hyd_inputs.engine_pump[3])
    B747DR_hyd_valve_4 = flag(sys[4].sov_open and hyd_inputs.engine_pump[4])
    -- the synoptic's pictures of what systems lost (as before)
    B747DR_hyd_sys_pressure_13 = math.max(sys[1].psi, sys[3].psi)
    B747DR_hyd_sys_pressure_23 = math.max(sys[2].psi, sys[3].psi)
    B747DR_hyd_sys_pressure_24 = math.max(sys[2].psi, sys[4].psi)
    B747DR_hyd_sys_pressure_234 = math.max(sys[2].psi, sys[3].psi, sys[4].psi)
    B747DR_hyd_sys_res_1, B747DR_hyd_sys_restotal_1, B747DR_hyd_sys_temp_1 = sys[1].qty, sys[1].qty, sys[1].temp
    B747DR_hyd_sys_res_2, B747DR_hyd_sys_restotal_2, B747DR_hyd_sys_temp_2 = sys[2].qty, sys[2].qty, sys[2].temp
    B747DR_hyd_sys_res_3, B747DR_hyd_sys_restotal_3, B747DR_hyd_sys_temp_3 = sys[3].qty, sys[3].qty, sys[3].temp
    B747DR_hyd_sys_res_4, B747DR_hyd_sys_restotal_4, B747DR_hyd_sys_temp_4 = sys[4].qty, sys[4].qty, sys[4].temp
    simDR_hyd_press_1_2 = out.acc_psi            -- BRAKE ACCUMULATOR PRESSURE gauge

    for n = 1, 4 do
        local o = sys[n]
        B747DR_hyd_light_eng_press[n - 1] = flag(o.light_eng_press)
        B747DR_hyd_light_dem_press[n - 1] = flag(o.light_dem_press)
        B747DR_hyd_light_sys_fault[n - 1] = flag(o.light_sys_fault)
        B747DR_hyd_stat_RF[n] = flag(o.rf and not o.lo)          -- LO replaces RF (FCOM p.1485)
        B747DR_hyd_stat_LO[n] = flag(o.lo)
        B747DR_hyd_CAS_caution[CAUTION_PRESS_SYS + n - 1] = flag(o.press_sys)
        B747DR_hyd_CAS_advisory[ADV_OVHT + n - 1] = flag(o.ovht)
        B747DR_hyd_CAS_advisory[ADV_PRESS_DEM + n - 1] = flag(o.press_dem)
        B747DR_hyd_CAS_advisory[ADV_PRESS_ENG + n - 1] = flag(o.press_eng)
        B747DR_hyd_CAS_advisory[ADV_QTY_LOW + n - 1] = flag(o.qty_low)
        if ADV_CONTROL[n] then B747DR_hyd_CAS_advisory[ADV_CONTROL[n]] = flag(o.control) end
        B747DR_hyd_CAS_status[STATUS_PRESS_ENG + n - 1] = flag(o.status_eng)
        B747DR_hyd_CAS_status[STATUS_PRESS_DEM + n - 1] = flag(o.status_dem)
        B747DR_hyd_CAS_status[STATUS_OVHT + n - 1] = flag(o.status_ovht)
        B747DR_hyd_CAS_status[STATUS_RSVR + n - 1] = flag(o.status_rsvr)
        B747DR_hyd_CAS_status[STATUS_HYDIM + n - 1] = flag(o.status_hydim)
        -- the custom acf's HYD synoptic (ACF_DIFF.md §5)
        B747DR_hyd_syn_edp[n - 1] = o.syn_edp
        B747DR_hyd_syn_dem[n - 1] = o.syn_dem
        B747DR_hyd_syn_sov[n - 1] = flag(o.sov_open)
        B747DR_hyd_syn_rsvr_press[n - 1] = flag(o.rsvr_low)
    end
    B747DR_hyd_syn_aux = out.syn_aux
    if B747DR_hyd_syn_text_off ~= "OFF" then B747DR_hyd_syn_text_off = "OFF" end
    if B747DR_hyd_syn_text_auto ~= "AUTO" then B747DR_hyd_syn_text_auto = "AUTO" end
    B747DR_hyd_light_brake_source = flag(out.brake_source_alert)
    B747DR_hyd_CAS_caution[CAUTION_BRAKE_SOURCE] = flag(out.brake_source_alert)
end

-- a new flight; with the engines running the systems start pressurised
function B747_hyd_power_flight_start()
    hyd_state = H.new()
    took_psi = {0, 0, 0, 0}
    last_parking_brake = nil
    leak_s, leak_picked = {0, 0, 0, 0}, {}
    if simDR_startup_running == 1 then H.preset_running(hyd_state) end
end

-- the pressure the flight controls can take from system n this frame
function B747_hyd_power_psi(n)
    return hyd_state.out.sys[n].psi
end

-- what is left of it after they moved
function B747_hyd_power_left(n, psi)
    took_psi[n] = math.max(0, hyd_state.out.sys[n].psi - psi)
end

-- every frame, before the flight controls take their pressure
function B747_hyd_power()
    leak_failures()
    read_inputs(hyd_inputs, SIM_PERIOD)
    write_outputs(H.update(hyd_state, hyd_inputs, SIM_PERIOD))
end
