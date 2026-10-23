-- The electrical model (B747.03.elec_model.lua) in the aircraft: reads the
-- P5 panel, the engines and the APU, runs the model every frame, and writes
-- the bus, breaker, light and EICAS datarefs, the older names the panels and
-- the sounds use (docs/overhaul/notes/ATA-24.md §6), and X-Plane's own
-- electrics, kept as stand-ins for X-Plane's instruments and sounds.
-- B747.03.xt.electrical.lua loads it after binding its datarefs and uses its
-- bindings (binding a number dataref again under the same name would write 0
-- to it).
dofile("B747.03.elec_model.lua")
local E = B747_elec_model

simDR_elec_engine_N2            = find_dataref("sim/flightmodel/engine/ENGN_N2_")
B747DR_elec_engine_type         = find_dataref("laminar/B747/engines/type")
B747DR_elec_pseu_air            = find_dataref("laminar/B747/gear/air_ground/pri_air")

B747DR_elec_bus_ac              = find_dataref("laminar/B747/electrical/bus/ac")
B747DR_elec_bus_dc              = find_dataref("laminar/B747/electrical/bus/dc")
B747DR_elec_bus_utility         = find_dataref("laminar/B747/electrical/bus/utility")
B747DR_elec_bus_galley          = find_dataref("laminar/B747/electrical/bus/galley")
B747DR_elec_bus_sync            = find_dataref("laminar/B747/electrical/bus/sync")
B747DR_elec_bus_any_ac          = find_dataref("laminar/B747/electrical/bus/any_ac")
B747DR_elec_bus_xfr_capt        = find_dataref("laminar/B747/electrical/bus/xfr_capt")
B747DR_elec_bus_xfr_fo          = find_dataref("laminar/B747/electrical/bus/xfr_fo")
B747DR_elec_bus_stby_main       = find_dataref("laminar/B747/electrical/bus/stby_main")
B747DR_elec_bus_stby_apu        = find_dataref("laminar/B747/electrical/bus/stby_apu")
B747DR_elec_bus_bat_main        = find_dataref("laminar/B747/electrical/bus/bat_main")
B747DR_elec_bus_bat_apu         = find_dataref("laminar/B747/electrical/bus/bat_apu")
B747DR_elec_bus_hot_bat_main    = find_dataref("laminar/B747/electrical/bus/hot_bat_main")
B747DR_elec_bus_hot_bat_apu     = find_dataref("laminar/B747/electrical/bus/hot_bat_apu")
B747DR_elec_bus_dc_tie          = find_dataref("laminar/B747/electrical/bus/dc_tie")
B747DR_elec_bus_gnd_svc         = find_dataref("laminar/B747/electrical/bus/gnd_svc")
B747DR_elec_bus_gnd_svc_util    = find_dataref("laminar/B747/electrical/bus/gnd_svc_util")
B747DR_elec_bus_gnd_hdlg        = find_dataref("laminar/B747/electrical/bus/gnd_hdlg")
B747DR_elec_bus_gnd_hdlg_dc     = find_dataref("laminar/B747/electrical/bus/gnd_hdlg_dc")
B747DR_elec_breaker_gcb         = find_dataref("laminar/B747/electrical/breaker/gcb")
B747DR_elec_breaker_btb         = find_dataref("laminar/B747/electrical/breaker/btb")
B747DR_elec_breaker_dcir        = find_dataref("laminar/B747/electrical/breaker/dcir")
B747DR_elec_breaker_xpc         = find_dataref("laminar/B747/electrical/breaker/xpc")
B747DR_elec_breaker_apb         = find_dataref("laminar/B747/electrical/breaker/apb")
B747DR_elec_breaker_ssb         = find_dataref("laminar/B747/electrical/breaker/ssb")
B747DR_elec_idg_connected       = find_dataref("laminar/B747/electrical/idg_connected")
B747DR_elec_air_mode            = find_dataref("laminar/B747/electrical/air_mode")
B747DR_elec_load_shed           = find_dataref("laminar/B747/electrical/load_shed")
B747DR_elec_battery_volts       = find_dataref("laminar/B747/electrical/battery/volts")
B747DR_elec_battery_amps        = find_dataref("laminar/B747/electrical/battery/amps")
B747DR_elec_light_ext_avail     = find_dataref("laminar/B747/electrical/light/ext_avail")
B747DR_elec_light_apu_avail     = find_dataref("laminar/B747/electrical/light/apu_avail")
B747DR_elec_light_isln          = find_dataref("laminar/B747/electrical/light/isln")
B747DR_elec_light_gen_off       = find_dataref("laminar/B747/electrical/light/gen_off")
B747DR_elec_light_drive         = find_dataref("laminar/B747/electrical/light/drive")
B747DR_elec_light_util_off      = find_dataref("laminar/B747/electrical/light/util_off")

local elec_state = E.new()
local elec_inputs = E.inputs()

local function flag(v)
    if v then return 1 end
    return 0
end

-- EICAS message slots (laminar/B747/CAS/*_status), B747.87.xt.warning.lua
local CAUTION_AC_BUS = 15          -- ELEC AC BUS 1-4: 15-18
local CAUTION_GEN_OFF = 71         -- ELEC GEN OFF 1-4 as cautions (405): 71-74, unused for 109
local ADV_BAT_DISCH_APU, ADV_BAT_DISCH_MAIN, ADV_BATTERY_OFF = 19, 20, 21
local ADV_DRIVE_DISC = 83          -- >DRIVE DISC 1-4: 83-86
local ADV_BUS_ISLN = 92            -- ELEC BUS ISLN 1-4: 92-95
local ADV_DRIVE = 96               -- ELEC DRIVE 1-4: 96-99
local ADV_GEN_OFF = 100            -- ELEC GEN OFF 1-4: 100-103 (advisory, 109)
local ADV_SSB_OPEN = 104
local ADV_UTIL_BUS = 105           -- ELEC UTIL BUS L/R: 105-106
local ADV_STBY_BUS_APU, ADV_STBY_BUS_MAIN = 276, 277

local function read_inputs(inp)
    inp.engine_type = B747DR_elec_engine_type
    inp.battery = B747DR_button_switch_position[13] > 0.5
    inp.stby_power = B747DR_elec_standby_power_sel_pos
    inp.utility[1] = B747DR_button_switch_position[11] > 0.5
    inp.utility[2] = B747DR_button_switch_position[12] > 0.5
    for n = 1, 4 do
        inp.bus_tie[n] = B747DR_button_switch_position[17 + n] > 0.5
        inp.gen_cont[n] = B747DR_button_switch_position[21 + n] > 0.5
        inp.drive_disc[n] = B747DR_gen_drive_disc_status[n - 1] == 1
        inp.n2[n] = simDR_elec_engine_N2[n - 1]
    end
    inp.ext_request[1] = B747DR_elec_ext_pwr_1_switch_mode == 1
    inp.ext_request[2] = B747DR_elec_ext_pwr_2_switch_mode == 1
    inp.apu_request[1] = B747DR_elec_apu_pwr_1_switch_mode == 1
    inp.apu_request[2] = B747DR_elec_apu_pwr_2_switch_mode == 1
    inp.ext_available[1] = B747DR_elec_ext_pwr1_available == 1
    inp.ext_available[2] = B747DR_elec_ext_pwr2_available == 1
    inp.apu_n1 = simDR_apu_N1_pct
    inp.apu_start = simDR_apu_start_switch_mode == 2 and simDR_apu_N1_pct < E.APU_READY_N1
    inp.on_ground = B747DR_elec_pseu_air == 0               -- PSEU air relays, ATA29_32 p.299
end

local function write_buses(out)
    for n = 1, 4 do
        B747DR_elec_bus_ac[n - 1] = flag(out.ac[n])
        B747DR_elec_bus_dc[n - 1] = flag(out.dc[n])
        B747DR_elec_bus_utility[n - 1] = flag(out.util[n])
        B747DR_elec_bus_galley[n - 1] = flag(out.galley[n])
        B747DR_elec_breaker_gcb[n - 1] = flag(out.gcb[n])
        B747DR_elec_breaker_btb[n - 1] = flag(out.btb[n])
        B747DR_elec_breaker_dcir[n - 1] = flag(out.dcir[n])
        B747DR_elec_idg_connected[n - 1] = flag(out.idg_connected[n])
        B747DR_elec_light_isln[n - 1] = flag(out.lights.isln[n])
        B747DR_elec_light_gen_off[n - 1] = flag(out.lights.gen_off[n])
        B747DR_elec_light_drive[n - 1] = flag(out.lights.drive[n])
    end
    for k = 1, 2 do
        B747DR_elec_bus_sync[k - 1] = flag(out.sync[k])
        B747DR_elec_breaker_xpc[k - 1] = flag(out.xpc[k])
        B747DR_elec_breaker_apb[k - 1] = flag(out.apb[k])
        B747DR_elec_light_ext_avail[k - 1] = flag(out.lights.ext_avail[k])
        B747DR_elec_light_apu_avail[k - 1] = flag(out.lights.apu_avail[k])
        B747DR_elec_light_util_off[k - 1] = flag(out.lights.util_off[k])
    end
    B747DR_elec_bus_any_ac = flag(out.xp.ac_power)
    B747DR_elec_bus_xfr_capt = flag(out.xfr.capt)
    B747DR_elec_bus_xfr_fo = flag(out.xfr.fo)
    B747DR_elec_bus_stby_main = flag(out.stby.main)
    B747DR_elec_bus_stby_apu = flag(out.stby.apu)
    B747DR_elec_bus_bat_main = flag(out.bat_bus.main)
    B747DR_elec_bus_bat_apu = flag(out.bat_bus.apu)
    B747DR_elec_bus_hot_bat_main = flag(out.hot_bat_bus.main)
    B747DR_elec_bus_hot_bat_apu = flag(out.hot_bat_bus.apu)
    B747DR_elec_bus_dc_tie = flag(out.dc_tie)
    B747DR_elec_bus_gnd_svc = flag(out.gsb)
    B747DR_elec_bus_gnd_svc_util = flag(out.gs_util)
    B747DR_elec_bus_gnd_hdlg = flag(out.ghb)
    B747DR_elec_bus_gnd_hdlg_dc = flag(out.gh_dc)
    B747DR_elec_breaker_ssb = flag(out.ssb)
    B747DR_elec_air_mode = flag(out.air_mode)
    B747DR_elec_load_shed = flag(out.load_shed)
    B747DR_elec_battery_volts[0] = out.battery.main.volts
    B747DR_elec_battery_volts[1] = out.battery.apu.volts
    B747DR_elec_battery_amps[0] = out.battery.main.amps
    B747DR_elec_battery_amps[1] = out.battery.apu.amps
end

-- The names the ELEC synoptic, the P5 panel, the displays and the sounds
-- already use, with their meaning kept (notes ATA-24 §3.2, §6).
local function write_legacy(out)
    B747DR_elec_bus1hot = flag(out.btb[1] and out.ac[1])   -- bus tie flow bar
    B747DR_elec_bus2hot = flag(out.btb[2] and out.ac[2])
    B747DR_elec_bus3hot = flag(out.btb[3] and out.ac[3])
    B747DR_elec_bus4hot = flag(out.btb[4] and out.ac[4])
    B747DR_elec_topleftbus = flag(out.sync[1])
    B747DR_elec_toprightbus = flag(out.sync[2])
    B747DR_elec_ssb = B747_set_animation_position(B747DR_elec_ssb, flag(out.ssb), 0.0, 1.0, 10)
    B747DR_simDR_esys0 = flag(not out.ac[1])                 -- 1 = AC bus amber
    B747DR_simDR_esys1 = flag(not out.ac[2])
    B747DR_simDR_esys2 = flag(not out.ac[3])
    B747DR_simDR_esys3 = flag(not out.ac[4])
    B747DR_elec_utilityleft1 = flag(out.util[1])
    B747DR_elec_utilityleft2 = flag(out.util[2])
    B747DR_elec_utilityright1 = flag(out.util[3])
    B747DR_elec_utilityright2 = flag(out.util[4])
    B747DR_elec_ext_pwr1_on = flag(out.xpc[1])
    B747DR_elec_ext_pwr2_on = flag(out.xpc[2])
    B747DR_elec_apu_pwr1_on = flag(out.apb[1])
    B747DR_elec_apu_pwr2_on = flag(out.apb[2])
    B747DR_elec_apu_volts = out.battery.apu.volts
    -- displays: 0 powered, 6 not (B747.60.xt.fltInst02.lua). Captain's PFD and
    -- ND on the APU standby bus, F/O's displays on the F/O transfer bus
    -- (FCOM p.800, p.804).
    B747DR_simDR_captain_display = out.stby.apu and 0 or 6
    B747DR_simDR_fo_display = out.xfr.fo and 0 or 6
    -- CDUs (6 powered): [8] the left CDU on the main standby bus (FCOM p.804),
    -- [7] the right CDU on the F/O transfer bus (FCOM p.800), [6] the centre
    -- CDU, whose bus no source gives: the F/O transfer bus as before (estimate).
    -- Which slot is which CDU: notes ATA-34-61-CDU.md.
    B747DR_elec_display_power[6] = out.xfr.fo and 6 or 0
    B747DR_elec_display_power[7] = out.xfr.fo and 6 or 0
    B747DR_elec_display_power[8] = out.stby.main and 6 or 0
end

local function write_cas(out)
    local cas = out.cas
    for n = 1, 4 do
        B747DR_CAS_caution_status[CAUTION_AC_BUS + n - 1] = flag(cas.ac_bus[n])
        B747DR_CAS_caution_status[CAUTION_GEN_OFF + n - 1] = 0
        B747DR_CAS_advisory_status[ADV_GEN_OFF + n - 1] = flag(cas.gen_off[n])
        B747DR_CAS_advisory_status[ADV_BUS_ISLN + n - 1] = flag(cas.bus_isln[n])
        B747DR_CAS_advisory_status[ADV_DRIVE + n - 1] = flag(cas.drive[n])
        B747DR_CAS_advisory_status[ADV_DRIVE_DISC + n - 1] = flag(cas.drive_disc[n])
    end
    B747DR_CAS_advisory_status[ADV_SSB_OPEN] = flag(cas.ssb_open)
    B747DR_CAS_advisory_status[ADV_UTIL_BUS] = flag(cas.util_bus[1])
    B747DR_CAS_advisory_status[ADV_UTIL_BUS + 1] = flag(cas.util_bus[2])
    B747DR_CAS_advisory_status[ADV_STBY_BUS_APU] = flag(cas.stby_bus_apu)
    B747DR_CAS_advisory_status[ADV_STBY_BUS_MAIN] = flag(cas.stby_bus_main)
    B747DR_CAS_advisory_status[ADV_BAT_DISCH_APU] = flag(cas.bat_disch_apu)
    B747DR_CAS_advisory_status[ADV_BAT_DISCH_MAIN] = flag(cas.bat_disch_main)
    B747DR_CAS_advisory_status[ADV_BATTERY_OFF] = flag(cas.battery_off)
end

-- X-Plane's electrics as stand-ins (notes §6): the battery follows the
-- BATTERY switch (the sounds test battery_on), the GPU any XPC, the APU
-- generator any APB, generator n GCB n; the cross tie stays closed so that
-- X-Plane's buses have power whenever any source does. Each is read first:
-- XTLua passes on only a value that differs from the one it holds, so a
-- value X-Plane changed itself would otherwise stay (TESTING.md §1.2).
local function write_xplane(out)
    if simDR_cross_tie ~= 1 then simDR_cross_tie = 1 end
    local v = flag(out.xp.battery_on)
    if simDR_battery_on[0] ~= v then simDR_battery_on[0] = v end
    v = flag(out.xp.gpu_on)
    if simDR_gpu_on ~= v then simDR_gpu_on = v end
    v = flag(out.xp.apu_gen_on)
    if simDR_apu_gen_on ~= v then simDR_apu_gen_on = v end
    for n = 1, 4 do
        v = flag(out.xp.generator_on[n])
        if simDR_generator_on[n - 1] ~= v then simDR_generator_on[n - 1] = v end
    end
end

-- Switch requests and DRIVE DISC flags the model dropped go back to the
-- datarefs the switch handlers (B747.01.xt.manipulators.lua) toggle.
local function write_switch_feedback(out, inp)
    if out.clear_ext[1] then B747DR_elec_ext_pwr_1_switch_mode = 0 end
    if out.clear_ext[2] then B747DR_elec_ext_pwr_2_switch_mode = 0 end
    if out.clear_apu[1] then B747DR_elec_apu_pwr_1_switch_mode = 0 end
    if out.clear_apu[2] then B747DR_elec_apu_pwr_2_switch_mode = 0 end
    for n = 1, 4 do
        if out.drive_disc_flag[n] ~= inp.drive_disc[n] then
            B747DR_gen_drive_disc_status[n - 1] = flag(out.drive_disc_flag[n])
        end
    end
end

function B747_elec_buses()
    read_inputs(elec_inputs)
    local out = E.update(elec_state, elec_inputs, SIM_PERIOD)
    write_buses(out)
    write_legacy(out)
    write_cas(out)
    write_xplane(out)
    write_switch_feedback(out, elec_inputs)
end
