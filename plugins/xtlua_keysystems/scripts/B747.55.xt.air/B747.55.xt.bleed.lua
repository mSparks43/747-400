-- The bleed air model (B747.55.bleed_model.lua) in the aircraft: reads the
-- P5 bleed panel, the START, AUTOSTART, FUEL CONTROL, fire and NAI switches,
-- N2, the APU, the buses, the packs, wing anti-ice and the demand pumps;
-- runs the model every frame and writes the valve positions, the engine and
-- duct pressures under their old names (notes/ATA-36.md §6), the P5 lights,
-- the EICAS messages, and X-Plane's bleed air mode. B747.55.xt.air.lua loads
-- it after its bindings and uses them (binding a number dataref again under
-- the same name would write 0 to it).
dofile("B747.55.bleed_model.lua")
local B = B747_bleed_model

B747DR_bleed_elec_ac            = find_dataref("laminar/B747/electrical/bus/ac")
B747DR_bleed_elec_dc            = find_dataref("laminar/B747/electrical/bus/dc")
B747DR_bleed_apu_sel_pos        = find_dataref("laminar/B747/electrical/apu/sel_dial_pos")
B747DR_bleed_wing_ai_valve_pos  = find_dataref("laminar/B747/antiice/wing/valve_pos")
B747DR_bleed_adp_1_psi          = find_dataref("laminar/B747/hydraulics/dem_pressure_1")
B747DR_bleed_adp_4_psi          = find_dataref("laminar/B747/hydraulics/dem_pressure_4")
B747DR_bleed_light_sys_fault    = find_dataref("laminar/B747/air/light/sys_fault")
B747DR_bleed_light_isln_valve   = find_dataref("laminar/B747/air/light/isln_valve")
B747DR_bleed_light_apu_valve    = find_dataref("laminar/B747/air/light/apu_valve")
simDR_bleed_fail_apu_press      = find_dataref("sim/operation/failures/rel_APU_press")
B747DR_bleed_CAS_status         = find_dataref("laminar/B747/CAS/status_status")

local BLEED_SWITCH = 77         -- button_switch/position[77-80]: ENGINE BLEED 1-4
local NAI_SWITCH = 68           -- button_switch/position[68-71]: NAI 1-4
local START_SWITCH = 16         -- toggle_switch/position[16-19]: START 1-4
local AUTOSTART_SWITCH = 45
local VALVE_SPEED = 20          -- PRSOV and start valve animation, as before

-- EICAS message slots (laminar/B747/CAS/advisory_status, B747.87.xt.warning.lua)
local ADV_OVHT = 22             -- BLD 1-4 OVHT/PRV: 22-25
local ADV_ISLN_APU = 34         -- >BLEED ISLN APU
local ADV_ISLN = 35             -- BLEED ISLN L, R: 35-36
local ADV_OFF = 39              -- >BLEED 1-4 OFF: 39-42
-- STATUS slots (laminar/B747/CAS/status_status, B747.87.xt.warning.lua)
local STATUS_ASCTU = 20         -- BLEED ASCTU A, B: 20-21
local STATUS_ISLN = 22          -- BLEED ISLN L, R: 22-23
local STATUS_ISLN_APU = 24      -- BLEED ISLN APU

local bleed_state = B.new()
local bleed_inputs = B.inputs()

local function flag(v)
    if v then return 1 end
    return 0
end

local function engine(n)
    if n == 1 then return B747bleedAir.engine1
    elseif n == 2 then return B747bleedAir.engine2
    elseif n == 3 then return B747bleedAir.engine3 end
    return B747bleedAir.engine4
end

local function fire_out(n)
    if n == 1 then return B747DR_engine01_fire_ext_switch_pos_arm > 0.5
    elseif n == 2 then return B747DR_engine02_fire_ext_switch_pos_arm > 0.5
    elseif n == 3 then return B747DR_engine03_fire_ext_switch_pos_arm > 0.5 end
    return B747DR_engine04_fire_ext_switch_pos_arm > 0.5
end

local function read_inputs(inp)
    for n = 1, 4 do
        inp.bleed_on[n] = B747DR_button_switch_position[BLEED_SWITCH + n - 1] > 0.95
        inp.nai_on[n] = B747DR_button_switch_position[NAI_SWITCH + n - 1] > 0.95
        inp.start_pulled[n] = B747DR_toggle_switch_position[START_SWITCH + n - 1] > 0.95
        inp.fuel_run[n] = B747DR_fuel_control_toggle_switch_pos[n - 1] > 0.95
        inp.fire_out[n] = fire_out(n)
        inp.n2[n] = B747DR_display_N2[n - 1]
        inp.dc[n] = B747DR_bleed_elec_dc[n - 1] > 0.5
        inp.ac[n] = B747DR_bleed_elec_ac[n - 1] > 0.5
    end
    inp.autostart = B747DR_button_switch_position[AUTOSTART_SWITCH] > 0.95
    inp.isln_on[1] = B747DR_button_switch_position[75] > 0.95
    inp.isln_on[2] = B747DR_button_switch_position[76] > 0.95
    inp.apu_bleed_on = B747DR_button_switch_position[81] > 0.95
    inp.apu_selector = B747DR_bleed_apu_sel_pos
    inp.apu_n1 = simDR_apu_N1_pct
    inp.apu_air_failed = simDR_bleed_fail_apu_press == 6     -- X-Plane failure: inoperative
    for p = 1, 3 do inp.packs[p] = B747DR_pack_ctrl_sel_pos[p - 1] > 0.5 end
    inp.wai[1] = B747DR_bleed_wing_ai_valve_pos[0] > 0.5
    inp.wai[2] = B747DR_bleed_wing_ai_valve_pos[1] > 0.5
    inp.adp[1] = B747DR_bleed_adp_1_psi > 0
    inp.adp[2] = B747DR_bleed_adp_4_psi > 0
    inp.altitude = simDR_indicated_altitude_pilot
end

local function write_outputs(out)
    for n = 1, 4 do
        local o, e = out.eng[n], engine(n)
        e.psi = o.psi
        e.bleed_air_valve.target_pos = o.prsov_open and 1 or 0
        e.bleed_air_valve.pos = B747_set_anim_value(e.bleed_air_valve.pos, e.bleed_air_valve.target_pos, 0.0, 1.0, VALVE_SPEED)
        e.bleed_air_start_valve.target_pos = o.start_valve_open and 1 or 0
        e.bleed_air_start_valve.pos = B747_set_anim_value(e.bleed_air_start_valve.pos, e.bleed_air_start_valve.target_pos, 0.0, 1.0, VALVE_SPEED)
        B747DR_bleed_light_sys_fault[n - 1] = flag(o.sys_fault)
        B747DR_CAS_advisory_status[ADV_OVHT + n - 1] = flag(o.ovht_alert)
        B747DR_CAS_advisory_status[ADV_OFF + n - 1] = flag(o.off_alert)
    end
    B747bleedAir.isolation_valve_L.pos = out.isln_pos[1]
    B747bleedAir.isolation_valve_R.pos = out.isln_pos[2]
    B747bleedAir.apu.bleed_air_valve.pos = out.apu_pos
    B747_duct_pressure_L = out.duct[1]
    B747_duct_pressure_C = out.duct[2]
    B747_duct_pressure_R = out.duct[3]
    B747DR_bleed_light_isln_valve[0] = flag(out.isln_light[1])
    B747DR_bleed_light_isln_valve[1] = flag(out.isln_light[2])
    B747DR_bleed_light_apu_valve = flag(out.apu_light)
    B747DR_CAS_advisory_status[ADV_ISLN] = flag(out.isln_alert[1])
    B747DR_CAS_advisory_status[ADV_ISLN + 1] = flag(out.isln_alert[2])
    B747DR_CAS_advisory_status[ADV_ISLN_APU] = flag(out.apu_alert)
    -- the STATUS messages of the same disagreements (ATA30_32_35_36 p.24)
    -- and of the ASCTU channels
    B747DR_bleed_CAS_status[STATUS_ISLN] = flag(out.isln_alert[1])
    B747DR_bleed_CAS_status[STATUS_ISLN + 1] = flag(out.isln_alert[2])
    B747DR_bleed_CAS_status[STATUS_ISLN_APU] = flag(out.apu_alert)
    B747DR_bleed_CAS_status[STATUS_ASCTU] = flag(out.asctu_alert[1])
    B747DR_bleed_CAS_status[STATUS_ASCTU + 1] = flag(out.asctu_alert[2])

    -- X-Plane's own bleed air feeds its pressurisation and its air starters.
    -- X-Plane ties its isolation valves to the mode (4 APU closes both, so
    -- the APU air cannot reach the starters; 5 auto opens both; 0 off closes
    -- both), so only the mode is set: auto while the ducts have air, off
    -- when they are empty. The valves the crew sees are the model's.
    -- Read first: XTLua passes on only a value that differs from the one it
    -- holds (TESTING.md §1.2).
    local mode = 0
    if out.duct[1] + out.duct[2] + out.duct[3] > 0.5 then mode = 5 end
    if simDR_bleed_air_mode ~= mode then simDR_bleed_air_mode = mode end
end

-- a new flight
function B747_bleed_flight_start()
    bleed_state = B.new()
end

-- every frame
function B747_bleed()
    read_inputs(bleed_inputs)
    write_outputs(B.update(bleed_state, bleed_inputs, SIM_PERIOD))
end
