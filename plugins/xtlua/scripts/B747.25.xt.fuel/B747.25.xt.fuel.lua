--[[
*****************************************************************************************
* Program Script Name : B747.25.fuel
* Author Name     : Jim Gregory
*
*   Revisions:
*   -- DATE --  --- REV NO ---    --- DESCRIPTION ---
*   2016-04-26  0.01a       Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED          *
*****************************************************************************************
--]]


--*************************************************************************************--
--**                        XLUA GLOBALS                           **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]


--*************************************************************************************--
--**                         CONSTANTS                             **--
--*************************************************************************************--

NUM_FUEL_TOGGLE_SW = 4

--replace create_command
function deferred_command(name,desc,realFunc)
  return replace_command(name,realFunc)
end
--replace deferred_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end


--*************************************************************************************--
--**                      GLOBAL VARIABLES                         **--
--*************************************************************************************--
simDR_time_now						= find_dataref("sim/time/total_running_time_sec")
B747 = {}
B747.fuel = {}
local lastFuelLevels={}
local lastTotalFuel=0
simDR_fuel_tank_weight_total_kg     = find_dataref("sim/flightmodel/weight/m_fuel_total")

------ FUEL TANK LEVELS --------------------------------------------------------------
local lastFuelUpdate=0
local startedRefil=0
-- CREATE FUEL TANK TABLES
local tankName = {"center_tank", "main1_tank", "main2_tank", "main3_tank", "main4_tank", "stab_tank", "res2_tank", "res3_tank"}
for _, tank_name in ipairs(tankName) do
    B747.fuel[tank_name] = {}
end

B747.fuel.engine1 = {}
B747.fuel.engine2 = {}
B747.fuel.engine3 = {}
B747.fuel.engine4 = {}

----- FUEL TANK PROPERTIES --------------------------------------------------------------

-- FUEL TANK CAPACITY (KILOGRAMS)
B747.fuel.center_tank.capacity      = 52167.0   -- XP Tank DR Index: 0
B747.fuel.main1_tank.capacity       = 13622.0   -- XP Tank DR Index: 1
B747.fuel.main2_tank.capacity       = 38132.0   -- XP Tank DR Index: 2
B747.fuel.main3_tank.capacity       = 38132.0   -- XP Tank DR Index: 3
B747.fuel.main4_tank.capacity       = 13622.0   -- XP Tank DR Index: 4
B747.fuel.res2_tank.capacity          =  4018.0   -- XP Tank DR Index: 5
B747.fuel.res3_tank.capacity      =  4018.0   -- XP Tank DR Index: 6
B747.fuel.stab_tank.capacity      = 10030.0   -- XP Tank DR Index: 7

-- FUEL TANK MIN LIMIT (KILOGRAMS)
B747.fuel.center_tank.min         =   0.0   -- XP Tank DR Index: 0
B747.fuel.main1_tank.min          =   0.0   -- XP Tank DR Index: 1
B747.fuel.main2_tank.min          =   0.0   -- XP Tank DR Index: 2
B747.fuel.main3_tank.min          =   0.0   -- XP Tank DR Index: 3
B747.fuel.main4_tank.min          =   0.0   -- XP Tank DR Index: 4
B747.fuel.res2_tank.min         =   0.0   -- XP Tank DR Index: 5
B747.fuel.res3_tank.min         =   0.0   -- XP Tank DR Index: 6
B747.fuel.stab_tank.min         =   0.0   -- XP Tank DR Index

-- PUMPS
B747.fuel.center_tank.ovrd_jett_pump_L  = {}
B747.fuel.center_tank.ovrd_jett_pump_R  = {}
B747.fuel.center_tank.scvg_pump_L1    = {}
B747.fuel.center_tank.scvg_pump_L2    = {}
B747.fuel.center_tank.scvg_pump_R1    = {}
B747.fuel.center_tank.scvg_pump_R2    = {}

B747.fuel.main1_tank.main_pump_fwd    = {}
B747.fuel.main1_tank.main_pump_aft    = {}

B747.fuel.main2_tank.main_pump_fwd    = {}
B747.fuel.main2_tank.main_pump_aft    = {}
B747.fuel.main2_tank.ovrd_jett_pump_fwd = {}
B747.fuel.main2_tank.ovrd_jett_pump_aft = {}
B747.fuel.main2_tank.apu_dc_pump    = {}

B747.fuel.main3_tank.main_pump_fwd    = {}
B747.fuel.main3_tank.main_pump_aft    = {}
B747.fuel.main3_tank.ovrd_jett_pump_fwd = {}
B747.fuel.main3_tank.ovrd_jett_pump_aft = {}

B747.fuel.main4_tank.main_pump_fwd    = {}
B747.fuel.main4_tank.main_pump_aft    = {}

B747.fuel.stab_tank.xfr_jett_pump_L   = {}
B747.fuel.stab_tank.xfr_jett_pump_R   = {}

    B747.fuel.center_tank.ovrd_jett_pump_L.on   = deferred_dataref("laminar/B747/fuel/center_tank/ovrd_jett_pump_L_on", "number")
    B747.fuel.center_tank.ovrd_jett_pump_R.on   = deferred_dataref("laminar/B747/fuel/center_tank/ovrd_jett_pump_R_on", "number")
    B747.fuel.center_tank.scvg_pump_L1.on     = deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_L1_on", "number")
    B747.fuel.center_tank.scvg_pump_L2.on     = deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_L2_on", "number")
    B747.fuel.center_tank.scvg_pump_R1.on     = deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_R1_on", "number")
    B747.fuel.center_tank.scvg_pump_R2.on     = deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_R2_on", "number")

    B747.fuel.main1_tank.main_pump_fwd.on     = deferred_dataref("laminar/B747/fuel/main1_tank/main_pump_fwd_on", "number")
    B747.fuel.main1_tank.main_pump_aft.on     = deferred_dataref("laminar/B747/fuel/main1_tank/main_pump_aft_on", "number")

    B747.fuel.main2_tank.main_pump_fwd.on     = deferred_dataref("laminar/B747/fuel/main2_tank/main_pump_fwd_on", "number")
    B747.fuel.main2_tank.main_pump_aft.on     = deferred_dataref("laminar/B747/fuel/main2_tank/main_pump_aft_on", "number")
    B747.fuel.main2_tank.ovrd_jett_pump_fwd.on      = deferred_dataref("laminar/B747/fuel/main2_tank/ovrd_jett_pump_fwd_on", "number")
    B747.fuel.main2_tank.ovrd_jett_pump_aft.on      = deferred_dataref("laminar/B747/fuel/main2_tank/ovrd_jett_pump_aft_on", "number")
    B747.fuel.main2_tank.apu_dc_pump.on         = deferred_dataref("laminar/B747/fuel/main2_tank/apu_dc_pump_on", "number")

    B747.fuel.main3_tank.main_pump_fwd.on     = deferred_dataref("laminar/B747/fuel/main3_tank/main_pump_fwd_on", "number")
    B747.fuel.main3_tank.main_pump_aft.on     = deferred_dataref("laminar/B747/fuel/main3_tank/main_pump_aft_on", "number")
    B747.fuel.main3_tank.ovrd_jett_pump_fwd.on      = deferred_dataref("laminar/B747/fuel/main3_tank/ovrd_jett_pump_fwd_on", "number")
    B747.fuel.main3_tank.ovrd_jett_pump_aft.on      = deferred_dataref("laminar/B747/fuel/main3_tank/ovrd_jett_pump_aft_on", "number")

    B747.fuel.main4_tank.main_pump_fwd.on     = deferred_dataref("laminar/B747/fuel/main4_tank/main_pump_fwd_on", "number")
    B747.fuel.main4_tank.main_pump_aft.on     = deferred_dataref("laminar/B747/fuel/main4_tank/main_pump_aft_on", "number")

    B747.fuel.stab_tank.xfr_jett_pump_L.on        = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_pump_L_on", "number")
    B747.fuel.stab_tank.xfr_jett_pump_R.on        = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_pump_R_on", "number")
    B747DR_engine_used_fuel               = deferred_dataref("laminar/B747/fuel/totaliser","array[5]")
-- VALVES
B747.fuel.center_tank.refuel_vlv_L    = {}
B747.fuel.center_tank.refuel_vlv_R    = {}
B747.fuel.center_tank.jett_vlv_L    = {}
B747.fuel.center_tank.jett_vlv_R    = {}
B747.fuel.center_tank.stab_xfr_vlv_L  = {}
B747.fuel.center_tank.stab_xfr_vlv_R  = {}
B747.fuel.center_tank.flow_eq_vlv   = {}

B747.fuel.main1_tank.refuel_vlv     = {}
B747.fuel.main1_tank.main_xfr_vlv   = {}

B747.fuel.main2_tank.refuel_vlv_L   = {}
B747.fuel.main2_tank.refuel_vlv_R   = {}
B747.fuel.main2_tank.jett_vlv     = {}
B747.fuel.main2_tank.apu_vlv      = {}

B747.fuel.main3_tank.refuel_vlv_L   = {}
B747.fuel.main3_tank.refuel_vlv_R   = {}
B747.fuel.main3_tank.jett_vlv     = {}

B747.fuel.main4_tank.refuel_vlv     = {}
B747.fuel.main4_tank.main_xfr_vlv   = {}

B747.fuel.stab_tank.refuel_vlv      = {}
B747.fuel.stab_tank.isolation_vlv_L   = {}
B747.fuel.stab_tank.xfr_jett_vlv_L    = {}
B747.fuel.stab_tank.isolation_vlv_R   = {}
B747.fuel.stab_tank.xfr_jett_vlv_R    = {}

B747.fuel.res2_tank.refuel_vlv      = {}
B747.fuel.res2_tank.xfr_vlv_A     = {}
B747.fuel.res2_tank.xfr_vlv_B     = {}

B747.fuel.res3_tank.refuel_vlv      = {}
B747.fuel.res3_tank.xfr_vlv_A     = {}
B747.fuel.res3_tank.xfr_vlv_B     = {}

B747.fuel.engine1.xfeed_vlv         = {}
B747.fuel.engine2.xfeed_vlv         = {}
B747.fuel.engine3.xfeed_vlv         = {}
B747.fuel.engine4.xfeed_vlv         = {}

B747.fuel.spar_vlv1           = {}
B747.fuel.spar_vlv2           = {}
B747.fuel.spar_vlv3           = {}
B747.fuel.spar_vlv4           = {}

B747.fuel.jett_nozzle_vlv_L       = {}
B747.fuel.jett_nozzle_vlv_R       = {}

    -- VALVE TARGET POS
    B747.fuel.center_tank.refuel_vlv_L.target_pos = 0
    B747.fuel.center_tank.refuel_vlv_R.target_pos = 0
    B747.fuel.center_tank.jett_vlv_L.target_pos   = 0
    B747.fuel.center_tank.jett_vlv_R.target_pos   = 0
    B747.fuel.center_tank.stab_xfr_vlv_L.target_pos = 0
    B747.fuel.center_tank.stab_xfr_vlv_R.target_pos = 0
    B747.fuel.center_tank.flow_eq_vlv.target_pos    = 0

    B747.fuel.main1_tank.refuel_vlv.target_pos    = 0
    B747.fuel.engine1.xfeed_vlv.target_pos        = 0
    B747.fuel.main1_tank.main_xfr_vlv.target_pos    = 0

    B747.fuel.main2_tank.refuel_vlv_L.target_pos  = 0
    B747.fuel.main2_tank.refuel_vlv_R.target_pos  = 0
    B747.fuel.engine2.xfeed_vlv.target_pos        = 0
    B747.fuel.main2_tank.jett_vlv.target_pos    = 0
    B747.fuel.main2_tank.apu_vlv.target_pos     = 0

    B747.fuel.main3_tank.refuel_vlv_L.target_pos  = 0
    B747.fuel.main3_tank.refuel_vlv_R.target_pos  = 0
    B747.fuel.engine3.xfeed_vlv.target_pos        = 0
    B747.fuel.main3_tank.jett_vlv.target_pos      = 0

    B747.fuel.main4_tank.refuel_vlv.target_pos    = 0
    B747.fuel.engine4.xfeed_vlv.target_pos        = 0
    B747.fuel.main4_tank.main_xfr_vlv.target_pos  = 0

    B747.fuel.stab_tank.refuel_vlv.target_pos   = 0
    B747.fuel.stab_tank.isolation_vlv_L.target_pos  = 0
    B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos = 0
    B747.fuel.stab_tank.isolation_vlv_R.target_pos  = 0
    B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos = 0

    B747.fuel.res2_tank.refuel_vlv.target_pos   = 0
    B747.fuel.res2_tank.xfr_vlv_A.target_pos        = 0
    B747.fuel.res2_tank.xfr_vlv_B.target_pos    = 0

    B747.fuel.res3_tank.refuel_vlv.target_pos   = 0
    B747.fuel.res3_tank.xfr_vlv_A.target_pos    = 0
    B747.fuel.res3_tank.xfr_vlv_B.target_pos    = 0

    B747.fuel.spar_vlv1.target_pos          = 0
    B747.fuel.spar_vlv2.target_pos          = 0
    B747.fuel.spar_vlv3.target_pos          = 0
    B747.fuel.spar_vlv4.target_pos          = 0

    B747.fuel.jett_nozzle_vlv_L.target_pos      = 0
    B747.fuel.jett_nozzle_vlv_R.target_pos      = 0


    -- VALVE POS
    B747.fuel.center_tank.refuel_vlv_L.pos      = deferred_dataref("laminar/B747/fuel/center_tank/refuel_vlv_L_pos", "number")
    B747.fuel.center_tank.refuel_vlv_R.pos      = deferred_dataref("laminar/B747/fuel/center_tank/refuel_vlv_R_pos", "number")
    B747.fuel.center_tank.jett_vlv_L.pos      = deferred_dataref("laminar/B747/fuel/center_tank/jett_vlv_L_pos", "number")
    B747.fuel.center_tank.jett_vlv_R.pos      = deferred_dataref("laminar/B747/fuel/center_tank/jett_vlv_R_pos", "number")
    B747.fuel.center_tank.stab_xfr_vlv_L.pos    = deferred_dataref("laminar/B747/fuel/center_tank/stab_xfr_vlv_L_pos", "number")
    B747.fuel.center_tank.stab_xfr_vlv_R.pos    = deferred_dataref("laminar/B747/fuel/center_tank/stab_xfr_vlv_R_pos", "number")
    B747.fuel.center_tank.flow_eq_vlv.pos     = deferred_dataref("laminar/B747/fuel/center_tank/flow_eq_vlv_pos", "number")

    B747.fuel.main1_tank.refuel_vlv.pos       = deferred_dataref("laminar/B747/fuel/main1_tank/refuel_vlv_pos", "number")
    B747.fuel.main1_tank.main_xfr_vlv.pos     = deferred_dataref("laminar/B747/fuel/main1_tank/main_xfr_vlv_pos", "number")

    B747.fuel.main2_tank.refuel_vlv_L.pos     = deferred_dataref("laminar/B747/fuel/main2_tank/refuel_vlv_L_pos", "number")
    B747.fuel.main2_tank.refuel_vlv_R.pos     = deferred_dataref("laminar/B747/fuel/main2_tank/refuel_vlv_R_pos", "number")
    B747.fuel.main2_tank.jett_vlv.pos       = deferred_dataref("laminar/B747/fuel/main2_tank/jett_vlv_pos", "number")
    B747.fuel.main2_tank.apu_vlv.pos        = deferred_dataref("laminar/B747/fuel/main2_tank/apu_vlv_pos", "number")

    B747.fuel.main3_tank.refuel_vlv_L.pos     = deferred_dataref("laminar/B747/fuel/main3_tank/refuel_vlv_L_pos", "number")
    B747.fuel.main3_tank.refuel_vlv_R.pos     = deferred_dataref("laminar/B747/fuel/main3_tank/refuel_vlv_R_pos", "number")
    B747.fuel.main3_tank.jett_vlv.pos       = deferred_dataref("laminar/B747/fuel/main3_tank/jett_vlv_pos", "number")

    B747.fuel.main4_tank.refuel_vlv.pos         = deferred_dataref("laminar/B747/fuel/main4_tank/refuel_vlv_pos", "number")
    B747.fuel.main4_tank.main_xfr_vlv.pos     = deferred_dataref("laminar/B747/fuel/main4_tank/main_xfr_vlv_pos", "number")

    B747.fuel.stab_tank.refuel_vlv.pos        = deferred_dataref("laminar/B747/fuel/stab_tank/refuel_vlv_pos", "number")
    B747.fuel.stab_tank.isolation_vlv_L.pos     = deferred_dataref("laminar/B747/fuel/stab_tank/isolation_vlv_L_pos", "number")
    B747.fuel.stab_tank.xfr_jett_vlv_L.pos      = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_vlv_L_pos", "number")
    B747.fuel.stab_tank.isolation_vlv_R.pos     = deferred_dataref("laminar/B747/fuel/stab_tank/isolation_vlv_R_pos", "number")
    B747.fuel.stab_tank.xfr_jett_vlv_R.pos      = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_vlv_R_pos", "number")

    B747.fuel.res2_tank.refuel_vlv.pos        = deferred_dataref("laminar/B747/fuel/res2_tank/refuel_vlv_pos", "number")
    B747.fuel.res2_tank.xfr_vlv_A.pos       = deferred_dataref("laminar/B747/fuel/res2_tank/xfr_vlv_A_pos", "number")
    B747.fuel.res2_tank.xfr_vlv_B.pos       = deferred_dataref("laminar/B747/fuel/res2_tank/xfr_vlv_B_pos", "number")

    B747.fuel.res3_tank.refuel_vlv.pos        = deferred_dataref("laminar/B747/fuel/res3_tank/refuel_vlv_pos", "number")
    B747.fuel.res3_tank.xfr_vlv_A.pos       = deferred_dataref("laminar/B747/fuel/res3_tank/xfr_vlv_A_pos", "number")
    B747.fuel.res3_tank.xfr_vlv_B.pos       = deferred_dataref("laminar/B747/fuel/res3_tank/xfr_vlv_B_pos", "number")

    B747.fuel.engine1.xfeed_vlv.pos           = deferred_dataref("laminar/B747/fuel/engine1/xfeed_vlv_pos", "number")
    B747.fuel.engine2.xfeed_vlv.pos           = deferred_dataref("laminar/B747/fuel/engine2/xfeed_vlv_pos", "number")
    B747.fuel.engine3.xfeed_vlv.pos           = deferred_dataref("laminar/B747/fuel/engine3/xfeed_vlv_pos", "number")
    B747.fuel.engine4.xfeed_vlv.pos           = deferred_dataref("laminar/B747/fuel/engine4/xfeed_vlv_pos", "number")

    B747.fuel.spar_vlv1.pos             = deferred_dataref("laminar/B747/fuel/spar_vlv1_pos", "number")
    B747.fuel.spar_vlv2.pos             = deferred_dataref("laminar/B747/fuel/spar_vlv2_pos", "number")
    B747.fuel.spar_vlv3.pos               = deferred_dataref("laminar/B747/fuel/spar_vlv3_pos", "number")
    B747.fuel.spar_vlv4.pos               = deferred_dataref("laminar/B747/fuel/spar_vlv4_pos", "number")

    B747.fuel.jett_nozzle_vlv_L.pos         = deferred_dataref("laminar/B747/fuel/jett_nozzle_vlv_L_pos", "number")
    B747.fuel.jett_nozzle_vlv_R.pos         = deferred_dataref("laminar/B747/fuel/jett_nozzle_vlv_R_pos", "number")



--*************************************************************************************--
--**                      LOCAL VARIABLES                          **--
--*************************************************************************************--

B747_fuel_control_toggle_sw_pos_target = deferred_dataref("laminar/B747/fuel/switch_target", "array[4]")--{}


local B747_stab_pump_low_press_shutoff_L = 0
local B747_stab_pump_low_press_shutoff_R = 0

local stabTank_to_centerTank_xfr_KgSec_L = 0
local stabTank_to_centerTank_xfr_KgSec_R = 0
local resTank2_to_mainTank2_xfr_KgSec_A = 0
local resTank2_to_mainTank2_xfr_KgSec_B = 0
local resTank3_to_mainTank3_xfr_KgSec_A = 0
local resTank3_to_mainTank3_xfr_KgSec_B = 0
local mainTank1_to_mainTank2_xfr_KgSec = 0
local mainTank4_to_mainTank3_xfr_KgSec = 0
local centerTank_to_mainTank2_xfr_KgSec_L1 = 0
local centerTank_to_mainTank2_xfr_KgSec_L2 = 0
local centerTank_to_mainTank3_xfr_KgSec_R1 = 0
local centerTank_to_mainTank3_xfr_KgSec_R2 = 0

local B747_stab_fuel_xfr_L = 0
local B747_stab_fuel_xfr_R = 0
local B747_main1_jett_fuel_xfr = 0
local B747_main4_jett_fuel_xfr = 0
local B747_res2A_fuel_xfr = 0
local B747_res2B_fuel_xfr = 0
local B747_res3A_fuel_xfr = 0
local B747_res3B_fuel_xfr = 0

local centerTank_jettison_KgSec_L = 0
local centerTank_jettison_KgSec_R = 0
local mainTank2_jettison_KgSec_A = 0
local mainTank2_jettison_KgSec_B = 0
local mainTank3_jettison_KgSec_A = 0
local mainTank3_jettison_KgSec_B = 0

local apuFuelBurn_KgSec = 0

local num_pressurized_oj_pumps = 0

local engine1fuelSrc = {}
local engine2fuelSrc = {}
local engine3fuelSrc = {}
local engine4fuelSrc = {}

local fuel_update_rate = 0.10                             -- FREQUENCY OF FUEL CALCULATION (TIMER)

local fuel_tankToEngine = 0



--*************************************************************************************--
--**                        X-PLANE DATAREFS                         **--
--*************************************************************************************--

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")

simDR_override_fuel_system          = find_dataref("sim/operation/override/override_fuel_system")

simDR_elec_bus_volts                = find_dataref("sim/cockpit2/electrical/bus_volts")
simDR_flap_deploy_ratio             = find_dataref("laminar/B747/cablecontrols/flap_ratio")
simDR_wing_flap1_deg                = find_dataref("sim/flightmodel2/wing/flap1_deg")
simDR_all_wheels_on_ground          = find_dataref("sim/flightmodel/failures/onground_any")
simDR_TAT                           = find_dataref("sim/cockpit2/temperature/outside_air_LE_temp_degc")

simDR_engine_fire                   = find_dataref("sim/cockpit2/annunciators/engine_fires")
simDR_eng_fuel_flow_kg_sec          = find_dataref("sim/cockpit2/engine/indicators/fuel_flow_kg_sec")
simDR_fuel_tank_weight_kg           = find_dataref("sim/flightmodel/weight/m_fuel")  -- kgs
-- 0 = center_tank
-- 1 = main1_tank
-- 2 = main2_tank
-- 3 = main3_tank
-- 4 = main4_tank
-- 5 = res2_tank
-- 6 = res3_tank
-- 7 = stab_tank

simDR_fueL_tank_weight_total_kg     = find_dataref("sim/flightmodel/weight/m_fuel_total")  -- kgs
simDR_engine_has_fuel               = find_dataref("sim/flightmodel2/engines/has_fuel_flow_before_mixture")

simDR_fuel_filter_block_01          = find_dataref("sim/operation/failures/rel_fuel_block0")
simDR_fuel_filter_block_02          = find_dataref("sim/operation/failures/rel_fuel_block1")
simDR_fuel_filter_block_03          = find_dataref("sim/operation/failures/rel_fuel_block2")
simDR_fuel_filter_block_04          = find_dataref("sim/operation/failures/rel_fuel_block3")

simDR_fuel_totalizer_kg       = find_dataref("sim/cockpit2/fuel/fuel_totalizer_init_kg")


--*************************************************************************************--
--**                      FIND CUSTOM DATAREFS                         **--
--*************************************************************************************--

B747DR_button_switch_position       = find_dataref("laminar/B747/button_switch/position")
--[[
  
BUTTON SWITCH INDEXES:

    misc_fuel_xfr_1_4           = 43
    fuel_jet_nozzle_vlv_L       = 46
    fuel_jet_nozzle_vlv_R       = 47
    fuel_xfeed_vlv_1            = 48
    fuel_xfeed_vlv_2            = 49
    fuel_xfeed_vlv_3            = 50
    fuel_xfeed_vlv_4            = 51
    fuel_ctr_wing_tnk_pump_L    = 52
    fuel_ctr_wing_tnk_pump_R    = 53
    fuel_stab_tnk_pump_L        = 54
    fuel_stab_tnk_pump_R        = 55
    fuel_main_pump_fwd_1        = 56
    fuel_main_pump_fwd_2        = 57
    fuel_main_pump_fwd_3        = 58
    fuel_main_pump_fwd_4        = 59
    fuel_main_pump_aft_1        = 60
    fuel_main_pump_aft_2        = 61
    fuel_main_pump_aft_3        = 62
    fuel_main_pump_aft_4        = 63
    fuel_overd_pump_fwd_2       = 64
    fuel_overd_pump_fwd_3       = 65
    fuel_overd_pump_aft_2       = 66
    fuel_overd_pump_aft_3       = 67

--]]

B747DR_elec_apu_sel_pos             = find_dataref("laminar/B747/electrical/apu/sel_dial_pos")
B747DR_engine_fuel_valve_pos        = find_dataref("laminar/B747/engines/fuel_valve_pos")

--B747DR_CAS_warning_status           = find_dataref("laminar/B747/CAS/warning_status")
B747DR_CAS_caution_status           = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status          = find_dataref("laminar/B747/CAS/advisory_status")



--*************************************************************************************--
--**                CREATE READ-ONLY CUSTOM DATAREFS                         **--
--*************************************************************************************--

B747DR_fuel_jettison_sel_dial_pos       = deferred_dataref("laminar/B747/fuel/fuel_jettison/sel_dial_pos", "number")
B747DR_fuel_control_toggle_switch_pos   = deferred_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos", "array[4]")

B747DR_stab_fuel_pump_press_low_L       = deferred_dataref("laminar/B747/fuel/stab_pump_L/pressure_low", "number")
B747DR_stab_fuel_pump_press_low_R       = deferred_dataref("laminar/B747/fuel/stab_pump_R/pressure_low", "number")

B747DR_stab_xfr_status                  = deferred_dataref("laminar/B747/fuel/stab_xfr_status", "number")
B747DR_res2_xfr_status                  = deferred_dataref("laminar/B747/fuel/res2_xfr_status", "number")
B747DR_res3_xfr_status                  = deferred_dataref("laminar/B747/fuel/res3_xfr_status", "number")
B747DR_ctr_scvg_L_status                = deferred_dataref("laminar/B747/fuel/ctr_scvg_L_status", "number")
B747DR_ctr_scvg_R_status                = deferred_dataref("laminar/B747/fuel/ctr_scvg_R_status", "number")

B747DR_fuel_temperature                 = deferred_dataref("laminar/B747/fuel/temperature", "number")

B747DR_jett_time                        = deferred_dataref("laminar/B747/fuel/jettison_time", "number")


B747DR_gen_fuel_XFmfld_status           = deferred_dataref("laminar/B747/fuel/gen_XFmfld_status", "number")

B747DR_gen_fuel_engine1_status          = deferred_dataref("laminar/B747/fuel/engine1_status", "number")
B747DR_gen_fuel_engine2_status          = deferred_dataref("laminar/B747/fuel/engine2_status", "number")
B747DR_gen_fuel_engine3_status          = deferred_dataref("laminar/B747/fuel/engine3_status", "number")
B747DR_gen_fuel_engine4_status          = deferred_dataref("laminar/B747/fuel/engine4_status", "number")

B747DR_gen_fuel_OJpump2_status          = deferred_dataref("laminar/B747/fuel/oj_pump2_status", "number")
B747DR_gen_fuel_OJpump3_status          = deferred_dataref("laminar/B747/fuel/oj_pump3_status", "number")

B747DR_gen_jett_valve_status            = deferred_dataref("laminar/B747/fuel/jett_vlv_status", "number")
B747DR_gen_jett_OJctrL_status           = deferred_dataref("laminar/B747/fuel/jett/OJctrL_status", "number")
B747DR_gen_jett_OJctrR_status           = deferred_dataref("laminar/B747/fuel/jett/OJctrR_status", "number")
B747DR_gen_jett_OJmain2_status          = deferred_dataref("laminar/B747/fuel/jett/OJmain2_status", "number")
B747DR_gen_jett_OJmain3_status          = deferred_dataref("laminar/B747/fuel/jett/OJmain3_status", "number")
B747DR_gen_jett_OJstab_status           = deferred_dataref("laminar/B747/fuel/jett/OJstab_status", "number")
B747DR_gen_jett_mfldL1_status           = deferred_dataref("laminar/B747/fuel/jett/mfldL1_status", "number")
B747DR_gen_jett_mfldL2_status           = deferred_dataref("laminar/B747/fuel/jett/mfldL2_status", "number")
B747DR_gen_jett_mfldL3_status           = deferred_dataref("laminar/B747/fuel/jett/mfldL3_status", "number")
B747DR_gen_jett_mfldR1_status           = deferred_dataref("laminar/B747/fuel/jett/mfldR1_status", "number")
B747DR_gen_jett_mfldR2_status           = deferred_dataref("laminar/B747/fuel/jett/mfldR2_status", "number")
B747DR_gen_jett_mfldR3_status           = deferred_dataref("laminar/B747/fuel/jett/mfldR3_status", "number")
B747DR_gen_jett_Xmfld_status            = deferred_dataref("laminar/B747/fuel/jett/mXmfld_status", "number")

B747DR_gen_xfeed_vlv1_status            = deferred_dataref("laminar/B747/fuel/gen/xfeed_vlv1_status", "number")
B747DR_gen_xfeed_vlv2_status            = deferred_dataref("laminar/B747/fuel/gen/xfeed_vlv2_status", "number")
B747DR_gen_xfeed_vlv3_status            = deferred_dataref("laminar/B747/fuel/gen/xfeed_vlv3_status", "number")
B747DR_gen_xfeed_vlv4_status            = deferred_dataref("laminar/B747/fuel/gen/xfeed_vlv4_status", "number")
B747DR_refuel             = deferred_dataref("laminar/B747/fuel/refuel", "number")
B747DR_fuel_preselect         = deferred_dataref("laminar/B747/fuel/preselect", "number")
B747DR_fuel_add             = deferred_dataref("laminar/B747/fuel/add_fuel", "number")
B747DR_init_fuel_CD                     = deferred_dataref("laminar/B747/fuel/init_CD", "number")


--*************************************************************************************--
--**               READ-WRITE CUSTOM DATAREF HANDLERS                      **--
--*************************************************************************************--

-- FUEL TO REMAIN
function B747DR_fuel_to_remain_rheo_DRhandler()
    print("DR handler")


end


--*************************************************************************************--
--**               CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

-- FUEL TO REMAIN
B747DR_fuel_to_remain_rheo      = deferred_dataref("laminar/B747/fuel/fuel_to_remain/rheostat", "number", B747DR_fuel_to_remain_rheo_DRhandler)

-- FUEL TANK WEIGHT DISPLAY QTY (8 TANKS)
B747DR_fuel_tank_display_qty      = deferred_dataref("laminar/B747/fuel/fuel_tank_display_qty", "array[8]")

-- FUEL TOTAL WEIGHT DISPLAY QTY
B747DR_fuel_total_display_qty     = deferred_dataref("laminar/B747/fuel/fuel_total_display_qty", "number")

-- FUEL FLOW PER SECOND
B747DR_fuel_flow_sec_display      = deferred_dataref("laminar/B747/fuel/fuel_flow_sec_display", "array[4]")

-- FUEL DISPLAY TOGGLE (EICAS)
B747DR_fuel_display_units_eicas     = deferred_dataref("laminar/B747/fuel/fuel_display_units_eicas", "number")

-- Temp location for fuel preselect for displaying in correct units
B747DR_fuel_preselect_temp        = deferred_dataref("laminar/B747/fuel/fuel_preselect_temp", "number")

-- Holds all SimConfig options
B747DR_simconfig_data         = deferred_dataref("laminar/B747/simconfig", "string")
B747DR_newsimconfig_data				= deferred_dataref("laminar/B747/newsimconfig", "number")

--*************************************************************************************--
--**                     X-PLANE COMMAND HANDLERS                        **--
--*************************************************************************************--



--*************************************************************************************--
--**                         X-PLANE COMMANDS                            **--
--*************************************************************************************--



--*************************************************************************************--
--**                      CUSTOM COMMAND HANDLERS                      **--
--*************************************************************************************--

-- AUTO IGNITION
function B747_fuel_jettison_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_fuel_jettison_sel_dial_pos = math.min(B747DR_fuel_jettison_sel_dial_pos+1, 2)
    end
end
function B747_fuel_jettison_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_fuel_jettison_sel_dial_pos = math.max(B747DR_fuel_jettison_sel_dial_pos-1, 0)
    end
end





-- TQ FUEL CONTROL SWITCHES
B747DR_dsp_synoptic_display                     = find_dataref("laminar/B747/dsp/synoptic_display")

function B747_fuel_control_switch1_CMDhandler(phase, duration)
    if phase == 0 then
        B747_fuel_control_toggle_sw_pos_target[0] = 1.0 - B747_fuel_control_toggle_sw_pos_target[0]
        B747DR_dsp_synoptic_display = 1
    end
end

function B747_fuel_control_switch2_CMDhandler(phase, duration)
    if phase == 0 then
        B747_fuel_control_toggle_sw_pos_target[1] = 1.0 - B747_fuel_control_toggle_sw_pos_target[1]
        B747DR_dsp_synoptic_display = 1
    end
end

function B747_fuel_control_switch3_CMDhandler(phase, duration)
    if phase == 0 then
        B747_fuel_control_toggle_sw_pos_target[2] = 1.0 - B747_fuel_control_toggle_sw_pos_target[2]
        B747DR_dsp_synoptic_display = 1
    end
end

function B747_fuel_control_switch4_CMDhandler(phase, duration)
    if phase == 0 then
        B747_fuel_control_toggle_sw_pos_target[3] = 1.0 - B747_fuel_control_toggle_sw_pos_target[3]
        B747DR_dsp_synoptic_display = 1
    end
end




function B747_ai_fuek_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
    B747_set_fuel_all_modes() 
    B747_set_fuel_CD()
    B747_set_fuel_ER()  
  end   
end 



--*************************************************************************************--
--**                      CREATE CUSTOM COMMANDS                         **--
--*************************************************************************************--

-- FUEL JETTISON SELECTOR
B747CMD_fuel_jettison_sel_up  = deferred_command("laminar/B747/fuel/fuel_jett/el_dial_up", "Fuel Jettison Selector Dial Up", B747_fuel_jettison_sel_up_CMDhandler)
B747CMD_fuel_jettison_sel_dn  = deferred_command("laminar/B747/fuel/fuel_jett/sel_dial_dn", "Fuel Jettison Selector Dial Down", B747_fuel_jettison_sel_dn_CMDhandler)



-- TQ FUEL CONTROL SWITCHES
B747CMD_fuel_control_switch1  = deferred_command("laminar/B747/fuel/fuel_control_1/toggle_switch", "Fuel Control Switch 1", B747_fuel_control_switch1_CMDhandler)
B747CMD_fuel_control_switch2  = deferred_command("laminar/B747/fuel/fuel_control_2/toggle_switch", "Fuel Control Switch 2", B747_fuel_control_switch2_CMDhandler)
B747CMD_fuel_control_switch3  = deferred_command("laminar/B747/fuel/fuel_control_3/toggle_switch", "Fuel Control Switch 3", B747_fuel_control_switch3_CMDhandler)
B747CMD_fuel_control_switch4  = deferred_command("laminar/B747/fuel/fuel_control_4/toggle_switch", "Fuel Control Switch 4", B747_fuel_control_switch4_CMDhandler)


-- AI
B747CMD_ai_fuel_quick_start   = deferred_command("laminar/B747/ai/fuel_quick_start", "number", B747_ai_fuek_quick_start_CMDhandler)



--*************************************************************************************--
--**                      OBJECT CONSTRUCTORS                      **--
--*************************************************************************************--



--*************************************************************************************--
--**                       CREATE SYSTEM OBJECTS                     **--
--*************************************************************************************--



--*************************************************************************************--
--**                          SYSTEM FUNCTIONS                       **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end





----- ANIMATION UNILITY -----------------------------------------------------------------
function B747_set_anim_value(current_value, target, min, max, speed)

    local fps_factor = math.min(1.0, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end





----- TOGGLE SWITCH POSITION ANIMATION --------------------------------------------------
function B747_fuel_toggle_switch_animation()

    for i = 0, NUM_FUEL_TOGGLE_SW-1 do

        B747DR_fuel_control_toggle_switch_pos[i] = B747_set_anim_value(B747DR_fuel_control_toggle_switch_pos[i], B747_fuel_control_toggle_sw_pos_target[i], 0.0, 1.0, 20.0)
    end

end






----- FUEL PUMP CONTROL -------------------------------------------------------------
--- AUTO SHUTOFF FLAG ---
function B747_stab_pump_shutoff_delay_L()
    B747_stab_pump_low_press_shutoff_L = 1                                          -- SET THE SHUTOFF FLAG
end
--- AUTO SHUTOFF FLAG ---
function B747_stab_pump_shutoff_delay_R()
    B747_stab_pump_low_press_shutoff_R = 1                                          -- SET THE SHUTOFF FLAG
end
function B747_fuel_pump_control()

    -- POWER REQUIRED - PUMPS ARE OFF WHEN THERE IS NO POWER
    local power = B747_ternary((simDR_elec_bus_volts[0] > 0.0), 1, 0)

    ---------------------------------------------------------------------------------
    -----                        C E N T E R   T A N K                          -----
    ---------------------------------------------------------------------------------

    -- OVERRIDE/JETTISON PUMP (LEFT) ------------------------------------------------
                                          -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[52] > 0.95 then                                -- PUMP SWITCH DEPRESSED
           
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.center_tank.ovrd_jett_pump_L.on = 0                           -- TURN PUMP OFF
      else
        B747.fuel.center_tank.ovrd_jett_pump_L.on = 1 * power                       -- TURN THE PUMP ON
            end
  else
    B747.fuel.center_tank.ovrd_jett_pump_L.on = 0 
        end

    --- STANDARD MODE ---
    else
        if B747DR_button_switch_position[52] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            B747.fuel.center_tank.ovrd_jett_pump_L.on = 1 * power                       -- TURN THE PUMP ON
  else
      B747.fuel.center_tank.ovrd_jett_pump_L.on = 0 
        end
    end


    -- OVERRIDE/JETTISON PUMP (RIGHT) -----------------------------------------------
    
    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[53] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET - TURN PUMP OFF
                B747.fuel.center_tank.ovrd_jett_pump_R.on = 0
      else
    B747.fuel.center_tank.ovrd_jett_pump_R.on = 1 * power                       -- TURN THE PUMP ON
            end
  else
      B747.fuel.center_tank.ovrd_jett_pump_R.on = 0                                       -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end

    --- STANDARD MODE ---
    else
        if B747DR_button_switch_position[53] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            B747.fuel.center_tank.ovrd_jett_pump_R.on = 1 * power                       -- TURN THE PUMP ON
   else
      B747.fuel.center_tank.ovrd_jett_pump_R.on = 0                                       -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end
    end


    -- SACAVENGE PUMP #1 (LEFT) -----------------------------------------------------
    
    if simDR_fuel_tank_weight_kg[2] < 27200.0                                           -- MAIN TANK #2 IS AT TRANSFER THERESHOLD
        and simDR_fuel_tank_weight_kg[0] < 1820.0                                       -- CENER TANK IS AT TRANSFER THRESHOLD
        and simDR_fuel_tank_weight_kg[0] > B747.fuel.center_tank.min                    -- CENTER TANK IS NOT EMPTY
        and (B747.fuel.main2_tank.main_pump_fwd.on == 1                                 -- HYDROMECHANICAL VENTURI POWER FOR PUMP OPERATION
            or B747.fuel.main2_tank.main_pump_aft.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_fwd.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_aft.on == 1)                              --          "
    then
        B747.fuel.center_tank.scvg_pump_L1.on = 1                                       -- TURN THE SCAVENGE PUMP ON
    else
      B747.fuel.center_tank.scvg_pump_L1.on = 0                                           -- DEFAULT TO PUMP OFF
    end



    -- SACAVENGE PUMP #2 (LEFT) -----------------------------------------------------
    
    if simDR_fuel_tank_weight_kg[2] < 27200.0                                           -- MAIN TANK #2 IS AT TRANSFER THERESHOLD
        and simDR_fuel_tank_weight_kg[0] < 1820.0                                       -- CENER TANK IS AT TRANSFER THRESHOLD
        and simDR_fuel_tank_weight_kg[0] > B747.fuel.center_tank.min                    -- CENTER TANK IS NOT EMPTY
        and (B747.fuel.main2_tank.main_pump_fwd.on == 1                                 -- HYDROMECHANICAL VENTURI POWER FOR PUMP OPERATION
            or B747.fuel.main2_tank.main_pump_aft.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_fwd.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_aft.on == 1)                              --          "
    then
        B747.fuel.center_tank.scvg_pump_L2.on = 1                                       -- TURN THE SCAVENGE PUMP ON
    else
  B747.fuel.center_tank.scvg_pump_L2.on = 0                                           -- DEFAULT TO PUMP OFF
    end


    -- SACAVENGE PUMP #1 (RIGHT) ----------------------------------------------------
   
    if simDR_fuel_tank_weight_kg[3] < 27200.0                                           -- MAIN TANK #3 IS AT TRANSFER THERESHOLD
        and simDR_fuel_tank_weight_kg[0] < 1820.0                                       -- CENER TANK IS AT TRANSFER THRESHOLD
        and simDR_fuel_tank_weight_kg[0] > B747.fuel.center_tank.min                    -- CENTER TANK IS NOT EMPTY
        and (B747.fuel.main2_tank.main_pump_fwd.on == 1                                 -- HYDROMECHANICAL VENTURI POWER FOR PUMP OPERATION
            or B747.fuel.main2_tank.main_pump_aft.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_fwd.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_aft.on == 1)                              --          "
    then
        B747.fuel.center_tank.scvg_pump_R1.on = 1                                       -- TURN THE SCAVENGE PUMP ON
    else
  B747.fuel.center_tank.scvg_pump_R1.on = 0                                           -- DEFAULT TO PUMP OFF
    end



    -- SACAVENGE PUMP #2 (RIGHT) ----------------------------------------------------
    
    if simDR_fuel_tank_weight_kg[3] < 27200.0                                           -- MAIN TANK #3 IS AT TRANSFER THERESHOLD
        and simDR_fuel_tank_weight_kg[0] < 1820.0                                       -- CENER TANK IS AT TRANSFER THRESHOLD
        and simDR_fuel_tank_weight_kg[0] > B747.fuel.center_tank.min                    -- CENTER TANK IS NOT EMPTY
        and (B747.fuel.main2_tank.main_pump_fwd.on == 1                                 -- HYDROMECHANICAL VENTURI POWER FOR PUMP OPERATION
            or B747.fuel.main2_tank.main_pump_aft.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_fwd.on == 1                               --          "
            or B747.fuel.main3_tank.main_pump_aft.on == 1)                              --          "
    then
        B747.fuel.center_tank.scvg_pump_R2.on = 1                                       -- TURN THE SCAVENGE PUMP ON
    else
  B747.fuel.center_tank.scvg_pump_R2.on = 0                                           -- DEFAULT TO PUMP OFF
    end




    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #1                         -----
    ---------------------------------------------------------------------------------

    -- MAIN PUMP FORWARD ------------------------------------------------------------
   
    if B747DR_button_switch_position[56] > 0.95 then                                    -- PUMP SWITCH DEPRESSED
        B747.fuel.main1_tank.main_pump_fwd.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main1_tank.main_pump_fwd.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end


    -- MAIN PUMP AFT ----------------------------------------------------------------
    
    if B747DR_button_switch_position[60] > 0.95 then                                    -- PUMP SWITCH DEPRESSED
        B747.fuel.main1_tank.main_pump_aft.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main1_tank.main_pump_aft.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #2                         -----
    ---------------------------------------------------------------------------------

    -- MAIN PUMP FORWARD ------------------------------------------------------------
    
    if B747DR_button_switch_position[57] > 0.95 then                                    -- PUMP SWITCH DEPRESSED
        B747.fuel.main2_tank.main_pump_fwd.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main2_tank.main_pump_fwd.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end


    -- MAIN PUMP AFT ----------------------------------------------------------------
    
    if B747DR_button_switch_position[61] > 0.95                                         -- PUMP SWITCH DEPRESSED
        or B747DR_elec_apu_sel_pos >= 1                                                 -- APU IS "ON"
    then
        B747.fuel.main2_tank.main_pump_aft.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main2_tank.main_pump_aft.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end


    -- OVERRIDE/JETTISON PUMP FORWARD -----------------------------------------------
    
    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[64] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.main2_tank.ovrd_jett_pump_fwd.on = 0                          -- TURN PUMP OFF
      else
    B747.fuel.main2_tank.ovrd_jett_pump_fwd.on = 1 * power                      -- TURN THE PUMP ON
            end
  else
    B747.fuel.main2_tank.ovrd_jett_pump_fwd.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end

    --- STANDARD MODE ---
    else
        if B747DR_button_switch_position[64] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if ((B747.fuel.center_tank.ovrd_jett_pump_L.on == 1                         -- CENTER TANK O/J PUMP LEFT IS ON          \
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 1                      -- CENTER TANK O/J PUMP RIGHT IS ON          | CENTER TANK PUMPS LOW PRESSURE
                and simDR_fuel_tank_weight_kg[0] < 900.0)                               -- STANDPIPE LIMIT                          /
                or
                (B747.fuel.center_tank.ovrd_jett_pump_L.on == 0                         -- CENTER TANK O/J PUMP LEFT IS OFF
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 0))                    -- CENTER TANK O/J PUMP RIGHT IS OFF
            then
                B747.fuel.main2_tank.ovrd_jett_pump_fwd.on = 1                          -- TURN THE PUMP ON
      else
          B747.fuel.main2_tank.ovrd_jett_pump_fwd.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
            end
  else
    B747.fuel.main2_tank.ovrd_jett_pump_fwd.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end
    end


    -- OVERRIDE/JETTISON PUMP AFT ---------------------------------------------------
    
    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[66] > 0.95 then                                -- PUMP SWITCH DEPRESSED
           
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.main2_tank.ovrd_jett_pump_aft.on = 0                          -- TURN PUMP OFF
      else
    B747.fuel.main2_tank.ovrd_jett_pump_aft.on = 1 * power                      -- TURN THE PUMP ON
            end
  else
      B747.fuel.main2_tank.ovrd_jett_pump_aft.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end

    --- STANDARD MODE ---
    else
        if B747DR_button_switch_position[66] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if ((B747.fuel.center_tank.ovrd_jett_pump_L.on == 1                         -- CENTER TANK O/J PUMP LEFT IS ON          \
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 1                      -- CENTER TANK O/J PUMP RIGHT IS ON          | CENTER TANK PUMPS LOW PRESSURE
                and simDR_fuel_tank_weight_kg[0] < 900.0)                               -- STANDPIPE LIMIT                          /
                or
                (B747.fuel.center_tank.ovrd_jett_pump_L.on == 0                         -- CENTER TANK O/J PUMP LEFT IS OFF
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 0))                    -- CENTER TANK O/J PUMP RIGHT IS OFF
            then
                B747.fuel.main2_tank.ovrd_jett_pump_aft.on = 1                          -- TURN THE PUMP ON
      else
         B747.fuel.main2_tank.ovrd_jett_pump_aft.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
            end
  else
    B747.fuel.main2_tank.ovrd_jett_pump_aft.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end
    end


    -- APU DC PUMP  -----------------------------------------------------------------   TODO:  ADD FEATURE - AUTO-SHUTOFF AFTER 15-20 MINUTES (OVERHEAT)
    
    if B747DR_elec_apu_sel_pos == 1                                                     -- APU IS "ON"
        and B747.fuel.main2_tank.main_pump_aft.on == 0                                  -- AC POWERED FUEL PUMP IS OFF
    then
        B747.fuel.main2_tank.apu_dc_pump.on = 1                                         -- TURN THE DC PUMP ON (APU BATTERY POWER ALWAYS AVAILABLE)
    else
  B747.fuel.main2_tank.apu_dc_pump.on = 0                                             -- DEFAULT TO PUMP OFF
    end



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #3                         -----
    ---------------------------------------------------------------------------------

    -- MAIN PUMP FORWARD ------------------------------------------------------------
   
    if B747DR_button_switch_position[58] > 0.95 then                                    -- PUMP SWITCH DEPRESSED
        B747.fuel.main3_tank.main_pump_fwd.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main3_tank.main_pump_fwd.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end


    -- MAIN PUMP AFT ----------------------------------------------------------------
    
    if B747DR_button_switch_position[62] > 0.95                                         -- PUMP SWITCH DEPRESSED
        or B747DR_elec_apu_sel_pos >= 1                                                 -- APU IS "ON"
    then
        B747.fuel.main3_tank.main_pump_aft.on = 1 * power                               -- TURN THE PUMP ON
    else
        B747.fuel.main3_tank.main_pump_aft.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end


    -- OVERRIDE/JETTISON PUMP FORWARD -----------------------------------------------
    
    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[65] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.main3_tank.ovrd_jett_pump_fwd.on = 0                          -- TURN PUMP OFF
      else
    B747.fuel.main3_tank.ovrd_jett_pump_fwd.on = 1 * power                      -- TURN THE PUMP ON
            end
  else
        B747.fuel.main3_tank.ovrd_jett_pump_fwd.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end

    --- STANDARD MODE ---
    else
        if B747DR_button_switch_position[65] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if ((B747.fuel.center_tank.ovrd_jett_pump_L.on == 1                         -- CENTER TANK O/J PUMP LEFT IS ON          \
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 1                      -- CENTER TANK O/J PUMP RIGHT IS ON          | CENTER TANK PUMPS LOW PRESSURE
                and simDR_fuel_tank_weight_kg[0] < 900.0)                               -- STANDPIPE LIMIT                          /
                or
                (B747.fuel.center_tank.ovrd_jett_pump_L.on == 0                         -- CENTER TANK O/J PUMP LEFT IS OFF
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 0))                    -- CENTER TANK O/J PUMP RIGHT IS OFF
            then
                B747.fuel.main3_tank.ovrd_jett_pump_fwd.on = 1                          -- TURN THE PUMP ON
      else
    B747.fuel.main3_tank.ovrd_jett_pump_fwd.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
            end
  else
    B747.fuel.main3_tank.ovrd_jett_pump_fwd.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end
    end


    -- OVERRIDE/JETTISON PUMP AFT ---------------------------------------------------
    
    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[67] > 0.95 then                                -- PUMP SWITCH DEPRESSED
           
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.main3_tank.ovrd_jett_pump_aft.on = 0                          -- TURN PUMP OFF
      else
    B747.fuel.main3_tank.ovrd_jett_pump_aft.on = 1 * power                      -- TURN THE PUMP ON
            end
  else
      B747.fuel.main3_tank.ovrd_jett_pump_aft.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end

    --- STANDARD MODE ---
    else
        if B747DR_button_switch_position[67] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if ((B747.fuel.center_tank.ovrd_jett_pump_L.on == 1                         -- CENTER TANK O/J PUMP LEFT IS ON          \
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 1                      -- CENTER TANK O/J PUMP RIGHT IS ON          | CENTER TANK PUMPS LOW PRESSURE
                and simDR_fuel_tank_weight_kg[0] < 900.0)                               -- STANDPIPE LIMIT                          /
                or
                (B747.fuel.center_tank.ovrd_jett_pump_L.on == 0                         -- CENTER TANK O/J PUMP LEFT IS OFF
                and B747.fuel.center_tank.ovrd_jett_pump_R.on == 0))                    -- CENTER TANK O/J PUMP RIGHT IS OFF
            then
                B747.fuel.main3_tank.ovrd_jett_pump_aft.on = 1                          -- TURN THE PUMP ON
      else
        B747.fuel.main3_tank.ovrd_jett_pump_aft.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
            end
  else
    B747.fuel.main3_tank.ovrd_jett_pump_aft.on = 0                                      -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
        end
    end



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #4                         -----
    ---------------------------------------------------------------------------------

    -- MAIN PUMP FORWARD ------------------------------------------------------------
    
    if B747DR_button_switch_position[59] > 0.95 then                                    -- PUMP SWITCH DEPRESSED
        B747.fuel.main4_tank.main_pump_fwd.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main4_tank.main_pump_fwd.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end


    -- MAIN PUMP AFT ----------------------------------------------------------------
    
    if B747DR_button_switch_position[63] > 0.95 then                                    -- PUMP SWITCH DEPRESSED
        B747.fuel.main4_tank.main_pump_aft.on = 1 * power                               -- TURN THE PUMP ON
    else
  B747.fuel.main4_tank.main_pump_aft.on = 0                                           -- DEFAULT TO PUMP OFF - PUMP SWITCH NOT DEPRESSED
    end



    ---------------------------------------------------------------------------------
    -----                     S T A B I L I Z E R   T A N K                     -----
    ---------------------------------------------------------------------------------

    -- TRANSFER/JETTISON PUMP (LEFT) ------------------------------------------------

    

    --- AUTO SHUTOFF RESET ---
    if simDR_fuel_tank_weight_kg[7] > 0.0 then                                          -- STABILZER TANK HAS FUEL
        B747_stab_pump_low_press_shutoff_L = 0                                          -- RESET THE SHUTOFF FLAG
    end

    --- LOW PRESSURE WARNING ---
    if B747.fuel.stab_tank.xfr_jett_pump_L.on == 1.0                                    -- PUMP IS RUNNING
        and simDR_fuel_tank_weight_kg[7] <= 0.0                                         -- NO FUEL AVAILABLE
    then
        B747DR_stab_fuel_pump_press_low_L = 1                                           -- SET THE LOW PRESSURE FLAG
    else
        B747DR_stab_fuel_pump_press_low_L = 0                                           -- RESET THE LOW PRESSURE FLAG
    end

    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[54] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if B747_stab_pump_low_press_shutoff_L == 0 then                             -- LOW PRESSURE AUTO SHUTOFF IS DISABLED
                B747.fuel.stab_tank.xfr_jett_pump_L.on = 1 * power                      -- TURN THE PUMP ON
            end
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.stab_tank.xfr_jett_pump_L.on = 0                              -- TURN THE PUMP OFF
            end
        else
            B747.fuel.stab_tank.xfr_jett_pump_L.on = 0                                  -- TURN THE PUMP OFF
        end

    --- TRANSFER MODE ---
    else
        if B747DR_button_switch_position[54] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if B747_stab_pump_low_press_shutoff_L == 0 then                             -- LOW PRESSURE AUTO SHUTOFF IS DISABLED
                if simDR_all_wheels_on_ground == 0                                      -- AIRCRAFT IS IN FLIGHT
                    and simDR_flap_deploy_ratio < 0.50                                  -- FLAPS ARE RETRACTED OUT OF RANGE OF FLAPS 10 & 20
                    and simDR_fuel_tank_weight_kg[0] <= 36470.0                         -- CENTER TANK FUEL QTY BELOW LIMIT
                then
                    B747.fuel.stab_tank.xfr_jett_pump_L.on = 1.0 * power                -- TURN THE PUMP ON
                    B747_stab_fuel_xfr_L = 1                                            -- SET THE TRANSFER STATUS FLAG - KEEP THE PUMP RUNNING !!
                else
                    B747.fuel.stab_tank.xfr_jett_pump_L.on = 0                          -- TURN THE PUMP OFF
                    B747_stab_fuel_xfr_L = 0                                            -- RESET THE TRANSFER STATUS FLAG
                end
            end
        else
            B747.fuel.stab_tank.xfr_jett_pump_L.on = 0                                  -- TURN THE PUMP OFF
            B747_stab_fuel_xfr_L = 0                                                    -- RESET THE TRANSFER STATUS FLAG
        end
    end

    --- AUTO SHUTOFF ---
    if B747DR_stab_fuel_pump_press_low_L == 1 then
        if is_timer_scheduled(B747_stab_pump_shutoff_delay_L) == false then
            run_after_time(B747_stab_pump_shutoff_delay_L, 20.0)
        end
    else
        if is_timer_scheduled(B747_stab_pump_shutoff_delay_L) == true then
            stop_timer(B747_stab_pump_shutoff_delay_L)
        end
    end



    -- TRANSFER/JETTISON PUMP (RIGHT) ------------------------------------------------

    

    --- AUTO SHUTOFF RESET ---
    if simDR_fuel_tank_weight_kg[7] > 0.0 then                                          -- STABILZER TANK HAS FUEL
        B747_stab_pump_low_press_shutoff_R = 0                                          -- RESET THE SHUTOFF FLAG
    end

    --- LOW PRESSURE WARNING ---
    if B747.fuel.stab_tank.xfr_jett_pump_R.on == 1.0                                    -- PUMP IS RUNNING
        and simDR_fuel_tank_weight_kg[7] <= 0.0                                         -- NO FUEL AVAILABLE
    then
        B747DR_stab_fuel_pump_press_low_R = 1                                           -- SET THE LOW PRESSURE FLAG
    else
        B747DR_stab_fuel_pump_press_low_R = 0                                           -- RESET THE LOW PRESSURE FLAG
    end

    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if B747DR_button_switch_position[54] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if B747_stab_pump_low_press_shutoff_R == 0 then                             -- LOW PRESSURE AUTO SHUTOFF IS DISABLED
                B747.fuel.stab_tank.xfr_jett_pump_R.on = 1 * power                      -- TURN THE PUMP ON
            end
            if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then       -- JETTISON GOAL HAS BEEN MET
                B747.fuel.stab_tank.xfr_jett_pump_R.on = 0                              -- TURN THE PUMP OFF
            end
        else
            B747.fuel.stab_tank.xfr_jett_pump_R.on = 0                                  -- TURN THE PUMP OFF
        end

    --- TRANSFER MODE ---
    else
        if B747DR_button_switch_position[55] > 0.95 then                                -- PUMP SWITCH DEPRESSED
            if B747_stab_pump_low_press_shutoff_R == 0 then                             -- LOW PRESSURE AUTO SHUTOFF IS DISABLED
                if simDR_all_wheels_on_ground == 0                                      -- AIRCRAFT IS IN FLIGHT
                    and simDR_flap_deploy_ratio < 0.50                                  -- FLAPS ARE RETRACTED OUT OF RANGE OF FLAPS 10 & 20
                    and simDR_fuel_tank_weight_kg[0] <= 36470.0                         -- CENTER TANK FUEL QTY BELOW LIMIT
                then
                    B747.fuel.stab_tank.xfr_jett_pump_R.on = 1.0 * power                -- TURN THE PUMP ON
                    B747_stab_fuel_xfr_R = 1                                            -- SET THE TRANSFER STATUS FLAG - KEEP THE PUMP RUNNING !!
                else
                    B747.fuel.stab_tank.xfr_jett_pump_R.on = 0                          -- TURN THE PUMP OFF
                    B747_stab_fuel_xfr_R = 0                                            -- RESET THE TRANSFER STATUS FLAG
                end
            end
        else
            B747.fuel.stab_tank.xfr_jett_pump_R.on = 0                                  -- TURN THE PUMP OFF
            B747_stab_fuel_xfr_R = 0                                                    -- RESET THE TRANSFER STATUS FLAG
        end
    end

    --- AUTO SHUTOFF ---
    if B747DR_stab_fuel_pump_press_low_R == 1 then
        if is_timer_scheduled(B747_stab_pump_shutoff_delay_R) == false then
            run_after_time(B747_stab_pump_shutoff_delay_R, 20.0)
        end
    else
        if is_timer_scheduled(B747_stab_pump_shutoff_delay_R) == true then
            stop_timer(B747_stab_pump_shutoff_delay_R)
        end
    end

end









----- FUEL VALVE CONTROL ------------------------------------------------------------
function B747_fuel_valve_control()

    -- POWER REQUIRED - VALVES ARE NORMALLY CLOSED WHEN THERE IS NO POWER
    local power = B747_ternary((simDR_elec_bus_volts[0] > 0.0), 1, 0)

    ---------------------------------------------------------------------------------
    -----                        C E N T E R   T A N K                          -----
    ---------------------------------------------------------------------------------
    B747.fuel.center_tank.refuel_vlv_L.target_pos = 0                                   -- NOT MODELED
    B747.fuel.center_tank.refuel_vlv_R.target_pos = 0                                   -- NOT MODELED

    -- JETTISON VALVE (LEFT) --------------------------------------------------------
    
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg > (B747DR_fuel_to_remain_rheo * 1000) then   -- JETTISON GOAL HAS NOT BEEN MET
            B747.fuel.center_tank.jett_vlv_L.target_pos = 1 * power                     -- OPEN THE VALVE
  else
      B747.fuel.center_tank.jett_vlv_L.target_pos = 0                                     -- DEFAULT TO VALVE CLOSED
        end
    else
  B747.fuel.center_tank.jett_vlv_L.target_pos = 0                                     -- DEFAULT TO VALVE CLOSED
    end


    -- JETTISON VALVE (RIGHT) -------------------------------------------------------
   
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg > (B747DR_fuel_to_remain_rheo * 1000) then   -- JETTISON GOAL HAS NOT BEEN MET
            B747.fuel.center_tank.jett_vlv_R.target_pos = 1 * power                     -- OPEN THE VALVE
  else
     B747.fuel.center_tank.jett_vlv_R.target_pos = 0                                     -- DEFAULT TO VALVE CLOSED
        end
    else
       B747.fuel.center_tank.jett_vlv_R.target_pos = 0                                     -- DEFAULT TO VALVE CLOSED
    end


    -- STABILIZER TRANSFER VALVE (LEFT) ---------------------------------------------
   
    if B747_stab_fuel_xfr_L == 1 then                                                   -- LEFT STABILIZER FUEL TRANSFER COMMANDED
        B747.fuel.center_tank.stab_xfr_vlv_L.target_pos = 1 * power                     -- OPEN THE VALVE
    else
  B747.fuel.center_tank.stab_xfr_vlv_L.target_pos = 0                                 -- DEFAULT TO VALVE CLOSED
    end


    -- STABILIZER TRANSFER VALVE (LEFT) ---------------------------------------------
    
    if B747_stab_fuel_xfr_R == 1 then                                                   -- RIGHT STABILIZER FUEL TRANSFER COMMANDED
        B747.fuel.center_tank.stab_xfr_vlv_R.target_pos = 1 * power                     -- OPEN THE VALVE
    else
  B747.fuel.center_tank.stab_xfr_vlv_R.target_pos = 0                                 -- DEFAULT TO VALVE CLOSED
    end


    -- FUEL FLOW EQUALIZATION VALVE -------------------------------------------------
    B747.fuel.center_tank.flow_eq_vlv.target_pos  = 0.5                               -- PROPORTIONAL BASED ON LEFT/RIGHT FUEL FLOW (NOT MODELED)



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #1                         -----
    ---------------------------------------------------------------------------------
    B747.fuel.main1_tank.refuel_vlv.target_pos = 0                                      -- (NOT MODELED)

    -- CROSSFEED VALVE --------------------------------------------------------------
    
    if B747DR_button_switch_position[48] > 0.95 then                                 -- VALVE SWITCH DEPRESSED
        B747.fuel.engine1.xfeed_vlv.target_pos = 1 * power                           -- OPEN THE VALVE
  else
    B747.fuel.engine1.xfeed_vlv.target_pos = 0                                       -- DEFAULT TO VALVE CLOSED
    end


    -- MAIN 1 TO MAIN 2 TRANSFER VALVE ----------------------------------------------
    

    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg > (B747DR_fuel_to_remain_rheo * 1000) then            -- JETTISON GOAL HAS NOT BEEN MET
            if (simDR_fuel_tank_weight_kg[2] <= 9072.00                                 -- ONLY OPEN THE VALVE WHEN TANK #2 IS BELOW THIS THRESHOLD
                or B747_main1_jett_fuel_xfr == 1)                                       -- OR ONCE THE VALVE IS OPENED FOR JETTISON, KEEP IT OPEN!
                and simDR_fuel_tank_weight_kg[1] > 0.0                                  -- DON'T OPEN VALVE IF NO FUEL TO TRANSFER
            then
                B747.fuel.main1_tank.main_xfr_vlv.target_pos = 1 * power                -- OPEN THE VALVE
                B747_main1_jett_fuel_xfr = 1                                            -- SET THE JETTISON TRANSFER FLAG
      else
        B747.fuel.main1_tank.main_xfr_vlv.target_pos = 0                                    -- DEFAULT TO VALVE CLOSED
            end
      else
        B747.fuel.main1_tank.main_xfr_vlv.target_pos = 0                                    -- DEFAULT TO VALVE CLOSED
        end

    --- MANUAL TRANSFER MODE ---
    else
       B747_main1_jett_fuel_xfr = 0                                                    -- RESET THE JETTISON TRANSFER FLAG
        if B747DR_button_switch_position[43] > 0.95                                     -- MAIN 1&4 TRANSFER SWITCH IS DEPRESSED
            and simDR_fuel_tank_weight_kg[1] > 0.0                                      -- DON'T OPEN VALVE IF NO FUEL TO TRANSFER
        then
            B747.fuel.main1_tank.main_xfr_vlv.target_pos = 1 * power                    -- OPEN THE VALVE
  else
     
     B747.fuel.main1_tank.main_xfr_vlv.target_pos = 0
        end
    end


    -- SPAR VALVE -------------------------------------------------------------------
   
    if B747DR_fuel_control_toggle_switch_pos[0] > 0.95                                  -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        and simDR_engine_fire[0] < 6                                                    -- THERE IS NO ENGINE FIRE
    then
        B747.fuel.spar_vlv1.target_pos = 1 * power                                      -- OPEN THE VALVE
    else
       B747.fuel.spar_vlv1.target_pos = 0                                                  -- DEFAULT TO VALVE CLOSED
    end



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #2                         -----
    ---------------------------------------------------------------------------------
    B747.fuel.main2_tank.refuel_vlv_L.target_pos  = 0                                 -- (NOT MODELED)
    B747.fuel.main2_tank.refuel_vlv_R.target_pos  = 0                                 -- (NOT MODELED)


    -- CROSSFEED VALVE --------------------------------------------------------------
    B747.fuel.engine2.xfeed_vlv.target_pos = 0                                          -- DEFAULT TO VALVE CLOSED
    if B747DR_button_switch_position[49] > 0.95 then                                    -- VALVE SWITCH DEPRESSED
        B747.fuel.engine2.xfeed_vlv.target_pos = 1 * power                              -- OPEN THE VALVE
        if simDR_all_wheels_on_ground == 1                                              -- AIRCRAFT IS ON THE GROUND
            and (simDR_flap_deploy_ratio >= 0.500 and simDR_flap_deploy_ratio <= 0.667) -- FLAPS ARE IN THE TAKEOFF POSITION (FLAPS 10 TO FLAPS 20)
        then
            B747.fuel.engine2.xfeed_vlv.target_pos = 0
        end
    end


    -- JETTISON VALVE ---------------------------------------------------------------
    
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg > (B747DR_fuel_to_remain_rheo * 1000) then            -- JETTISON GOAL HAS NOT BEEN MET
            B747.fuel.main2_tank.jett_vlv.target_pos = 1 * power                        -- OPEN THE VALVE
  else
    B747.fuel.main2_tank.jett_vlv.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
        end
    else
  B747.fuel.main2_tank.jett_vlv.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
    end


    -- APU VALVE --------------------------------------------------------------------
    
    if B747DR_elec_apu_sel_pos >= 1 then
        B747.fuel.main2_tank.apu_vlv.target_pos = 1 * power
    else
      B747.fuel.main2_tank.apu_vlv.target_pos = 0
    end


    -- SPAR VALVE -------------------------------------------------------------------
   
    if B747DR_fuel_control_toggle_switch_pos[1] > 0.95                                  -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        and simDR_engine_fire[1] < 6                                                    -- THERE IS NO ENGINE FIRE
    then
        B747.fuel.spar_vlv2.target_pos = 1 * power                                      -- OPEN THE VALVE
    else
       B747.fuel.spar_vlv2.target_pos = 0                                                  -- DEFAULT TO VALVE CLOSED
    end



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #3                         -----
    ---------------------------------------------------------------------------------
    B747.fuel.main3_tank.refuel_vlv_L.target_pos = 0                                    -- (NOT MODELED)
    B747.fuel.main3_tank.refuel_vlv_R.target_pos = 0                                    -- (NOT MODELED)


    -- CROSSFEED VALVE --------------------------------------------------------------
    
    if B747DR_button_switch_position[50] > 0.95 then                                    -- VALVE SWITCH DEPRESSED
        
        if simDR_all_wheels_on_ground == 1                                              -- AIRCRAFT IS ON THE GROUND
            and (simDR_flap_deploy_ratio >= 0.500 and simDR_flap_deploy_ratio <= 0.667) -- FLAPS ARE IN THE TAKEOFF POSITION (FLAPS 10 TO FLAPS 20)
        then
            B747.fuel.engine3.xfeed_vlv.target_pos = 0
  else
      B747.fuel.engine3.xfeed_vlv.target_pos = 1 * power                              -- OPEN THE VALVE
        end
    else
  B747.fuel.engine3.xfeed_vlv.target_pos = 0
    end


    -- JETTISON VALVE ---------------------------------------------------------------
    
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg > (B747DR_fuel_to_remain_rheo * 1000) then            -- JETTISON GOAL HAS NOT BEEN MET
            B747.fuel.main3_tank.jett_vlv.target_pos = 1 * power                        -- OPEN THE VALVE
    else
      B747.fuel.main3_tank.jett_vlv.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
        end
  else
    B747.fuel.main3_tank.jett_vlv.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
    end


    -- SPAR VALVE -------------------------------------------------------------------
    
    if B747DR_fuel_control_toggle_switch_pos[2] > 0.95                                  -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        and simDR_engine_fire[2] < 6                                                    -- THERE IS NO ENGINE FIRE
    then
        B747.fuel.spar_vlv3.target_pos = 1 * power                                      -- OPEN THE VALVE
    else
      B747.fuel.spar_vlv3.target_pos = 0                                                  -- DEFAULT TO VALVE CLOSED
    end



    ---------------------------------------------------------------------------------
    -----                        M A I N   T A N K   #4                         -----
    ---------------------------------------------------------------------------------
    B747.fuel.main4_tank.refuel_vlv.target_pos = 0                                      -- (NOT MODELED)


    -- CROSSFEED VALVE --------------------------------------------------------------
    
    if B747DR_button_switch_position[51] > 0.95 then                                    -- VALVE SWITCH DEPRESSED
        B747.fuel.engine4.xfeed_vlv.target_pos = 1 * power                              -- OPEN THE VALVE
  else
    B747.fuel.engine4.xfeed_vlv.target_pos = 0                                          -- DEFAULT TO VALVE CLOSED
    end


    -- MAIN 4 TO MAIN 3 TRANSFER VALVE ----------------------------------------------
   

    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg > (B747DR_fuel_to_remain_rheo * 1000) then            -- JETTISON GOAL HAS NOT BEEN MET
            if (simDR_fuel_tank_weight_kg[3] <= 9072.00                                 -- ONLY OPEN THE VALVE WHEN TANK #2 IS BELOW THIS THRESHOLD
                or B747_main4_jett_fuel_xfr == 1)                                       -- OR ONCE THE VALVE IS OPENED FOR JETTISON, KEEP IT OPEN!
                and simDR_fuel_tank_weight_kg[4] > 0.0                                  -- DON'T OPEN VALVE IF NO FUEL TO TRANSFER
            then
                B747.fuel.main4_tank.main_xfr_vlv.target_pos = 1 * power                -- OPEN THE VALVE
                B747_main4_jett_fuel_xfr = 1                                            -- SET THE JETTISON TRANSFER FLAG
      else
         B747.fuel.main4_tank.main_xfr_vlv.target_pos = 0                                    -- DEFAULT TO VALVE CLOSED
            end
  else 
     B747.fuel.main4_tank.main_xfr_vlv.target_pos = 0                                    -- DEFAULT TO VALVE CLOSED
        end

    --- MANUAL TRANSFER MODE ---
    else
        B747_main4_jett_fuel_xfr = 0                                                    -- RESET THE JETTISON TRANSFER FLAG
        if B747DR_button_switch_position[43] > 0.95                                     -- MAIN 1&4 TRANSFER SWITCH IS DEPRESSED
            and simDR_fuel_tank_weight_kg[4] > 0.0                                      -- DON'T OPEN VALVE IF NO FUEL TO TRANSFER
        then
            B747.fuel.main4_tank.main_xfr_vlv.target_pos = 1 * power                    -- OPEN THE VALVE
  else
     B747.fuel.main4_tank.main_xfr_vlv.target_pos = 0                                    -- DEFAULT TO VALVE CLOSED
     
        end
    end


    -- SPAR VALVE -------------------------------------------------------------------
    
    if B747DR_fuel_control_toggle_switch_pos[3] > 0.95                                  -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        and simDR_engine_fire[3] < 6                                                    -- THERE IS NO ENGINE FIRE
    then
        B747.fuel.spar_vlv4.target_pos = 1 * power                                      -- OPEN THE VALVE
    else
      B747.fuel.spar_vlv4.target_pos = 0                                                  -- DEFAULT TO VALVE CLOSED
    end



    ---------------------------------------------------------------------------------
    -----                     S T A B I L I Z E R   T A N K                     -----
    ---------------------------------------------------------------------------------
    B747.fuel.stab_tank.refuel_vlv.target_pos   = 0                                 -- (NOT MODELED)
    B747.fuel.stab_tank.isolation_vlv_L.target_pos  = 0                                 -- (NOT MODELED)
    B747.fuel.stab_tank.isolation_vlv_R.target_pos  = 0                                 -- (NOT MODELED)

    -- TRANSFER/JETTISON VALVE (LEFT) -----------------------------------------------
    

    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then           -- JETTISON GOAL HAS NOT BEEN MET
            B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos = 1 * power                   -- OPEN THE VALVE
  else
      B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos = 0                                   -- DEFAULT TO VALVE CLOSED
        end

    --- TRANSFER MODE ---
    else
        if B747_stab_fuel_xfr_L == 1 then                                               -- LEFT STABILIZER FUEL TRANSFER/JETTISON COMMANDED
            B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos = 1 * power                   -- OPEN THE VALVE
      else
        B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos = 0                                   -- DEFAULT TO VALVE CLOSED
        end
    end


    -- TRANSFER/JETTISON VALVE (RIGHT) ----------------------------------------------
    

    --- JETTISON MODE ---
    if ((B747DR_button_switch_position[46] > 0.95 or B747DR_button_switch_position[47] > 0.95) and B747DR_fuel_jettison_sel_dial_pos > 0) then
        if simDR_fueL_tank_weight_total_kg <= (B747DR_fuel_to_remain_rheo * 1000) then           -- JETTISON GOAL HAS NOT BEEN MET
            B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos = 1 * power                   -- OPEN THE VALVE
    else
      B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos = 0                                   -- DEFAULT TO VALVE CLOSED
        end

    --- TRANSFER MODE ---
    else
        if B747_stab_fuel_xfr_R == 1 then                                               -- RIGHT STABILIZER FUEL TRANSFER/JETTISON COMMANDED
            B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos = 1 * power                   -- OPEN THE VALVE
      else
        B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos = 0                                   -- DEFAULT TO VALVE CLOSED
        end
    end



    ---------------------------------------------------------------------------------
    -----                     R E S E R V E   T A N K   #2                      -----
    ---------------------------------------------------------------------------------
    B747.fuel.res2_tank.refuel_vlv.target_pos = 0                                       -- (NOT MODELED)


    -- TRANSFER VALVE A -------------------------------------------------------------
    
    if (simDR_fuel_tank_weight_kg[2] < 18200.0                                          -- #2 WEIGHT IS BELOW 18200.0
        or B747_res2A_fuel_xfr == 1)                                                    -- OR ONCE THE VALVE IS OPENED FOR TRANSFER, KEEP IT OPEN!
        and
        simDR_fuel_tank_weight_kg[5] > 0.0                                              -- TANK #3 IS NOT EMPTY
    then
        B747.fuel.res2_tank.xfr_vlv_A.target_pos = 1 * power                            -- OPEN THE VALVE
        B747_res2A_fuel_xfr = 1                                                         -- SET THE TRANSFER FLAG
    else
  B747.fuel.res2_tank.xfr_vlv_A.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
    end


    -- TRANSFER VALVE B -------------------------------------------------------------
    
    if (simDR_fuel_tank_weight_kg[2] < 18200.0                                          -- TANK #2 WEIGHT IS BELOW 18200.0
        or B747_res2B_fuel_xfr == 1)                                                    -- OR ONCE THE VALVE IS OPENED FOR TRANSFER, KEEP IT OPEN!
        and
        simDR_fuel_tank_weight_kg[5] > 0.0                                              -- TANK #3 IS NOT EMPTY
    then
        B747.fuel.res2_tank.xfr_vlv_B.target_pos = 1 * power                            -- OPEN THE VALVE
        B747_res2B_fuel_xfr = 1                                                         -- SET THE TRANSFER FLAG
    else
      B747.fuel.res2_tank.xfr_vlv_B.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
    end




    ---------------------------------------------------------------------------------
    -----                     R E S E R V E   T A N K   #3                      -----
    ---------------------------------------------------------------------------------
    B747.fuel.res3_tank.refuel_vlv.target_pos = 0                                       -- (NOT MODELED)


    -- TRANSFER VALVE A -------------------------------------------------------------
    
    if (simDR_fuel_tank_weight_kg[3] < 18200.0                                          -- TANK #3 WEIGHT IS BELOW 18200.0
        or B747_res3A_fuel_xfr == 1)                                                    -- OR ONCE THE VALVE IS OPENED FOR TRANSFER, KEEP IT OPEN!
        and
        simDR_fuel_tank_weight_kg[6] > 0.0                                              -- TANK #4 IS NOT EMPTY
    then
        B747.fuel.res3_tank.xfr_vlv_A.target_pos = 1 * power                            -- OPEN THE VALVE
        B747_res3A_fuel_xfr = 1                                                         -- SET THE TRANSFER FLAG
    else
      B747.fuel.res3_tank.xfr_vlv_A.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
    end


    -- TRANSFER VALVE B -------------------------------------------------------------
    
    if (simDR_fuel_tank_weight_kg[3] < 18200.0                                          -- TANK #3 WEIGHT IS BELOW 18200.0
        or B747_res3B_fuel_xfr == 1)                                                    -- OR ONCE THE VALVE IS OPENED FOR TRANSFER, KEEP IT OPEN!
        and
        simDR_fuel_tank_weight_kg[6] > 0.0                                              -- TANK #4 IS NOT EMPTY
    then
        B747.fuel.res3_tank.xfr_vlv_B.target_pos = 1 * power                            -- OPEN THE VALVE
        B747_res3B_fuel_xfr = 1                                                         -- SET THE TRANSFER FLAG
    else
      B747.fuel.res3_tank.xfr_vlv_B.target_pos = 0                                        -- DEFAULT TO VALVE CLOSED
    end



    ---------------------------------------------------------------------------------
    -----                   J E T T I S O N   M A N I F O L D                   -----
    ---------------------------------------------------------------------------------

    -- JETTISON VALVE (LEFT) --------------------------------------------------------
    
    if B747DR_button_switch_position[46] > 0.95
        and B747DR_fuel_jettison_sel_dial_pos > 0
    then
        B747.fuel.jett_nozzle_vlv_L.target_pos = 1 * power
    else
      B747.fuel.jett_nozzle_vlv_L.target_pos = 0
    end


    -- JETTISON VALVE (RIGHT) -------------------------------------------------------
    
    if B747DR_button_switch_position[47] > 0.95
        and B747DR_fuel_jettison_sel_dial_pos > 0
    then
        B747.fuel.jett_nozzle_vlv_R.target_pos = 1 * power
    else
      B747.fuel.jett_nozzle_vlv_R.target_pos = 0
    end


    -- JETTISON VALVE STATUS --------------------------------------------------------
    
    if B747.fuel.jett_nozzle_vlv_L.pos > 0.05
        or B747.fuel.jett_nozzle_vlv_R.pos > 0.05
    then
        B747DR_gen_jett_valve_status = 1
    else
      B747DR_gen_jett_valve_status = 0
    end

end








----- FUEL VALVE ANIMATION --------------------------------------------------------------
function B747_fuel_valve_animation()

    local valve_anm_speed = 10.0

    B747.fuel.center_tank.refuel_vlv_L.pos      = B747_set_anim_value(B747.fuel.center_tank.refuel_vlv_L.pos, B747.fuel.center_tank.refuel_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.center_tank.refuel_vlv_R.pos      = B747_set_anim_value(B747.fuel.center_tank.refuel_vlv_R.pos, B747.fuel.center_tank.refuel_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.center_tank.jett_vlv_L.pos    = B747_set_anim_value(B747.fuel.center_tank.jett_vlv_L.pos, B747.fuel.center_tank.jett_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.center_tank.jett_vlv_R.pos    = B747_set_anim_value(B747.fuel.center_tank.jett_vlv_R.pos, B747.fuel.center_tank.jett_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.center_tank.stab_xfr_vlv_L.pos  = B747_set_anim_value(B747.fuel.center_tank.stab_xfr_vlv_L.pos, B747.fuel.center_tank.stab_xfr_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.center_tank.stab_xfr_vlv_R.pos  = B747_set_anim_value(B747.fuel.center_tank.stab_xfr_vlv_R.pos, B747.fuel.center_tank.stab_xfr_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.center_tank.flow_eq_vlv.pos   = B747_set_anim_value(B747.fuel.center_tank.flow_eq_vlv.pos, B747.fuel.center_tank.flow_eq_vlv.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.main1_tank.refuel_vlv.pos       = B747_set_anim_value(B747.fuel.main1_tank.refuel_vlv.pos, B747.fuel.main1_tank.refuel_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.engine1.xfeed_vlv.pos           = B747_set_anim_value(B747.fuel.engine1.xfeed_vlv.pos, B747.fuel.engine1.xfeed_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main1_tank.main_xfr_vlv.pos   = B747_set_anim_value(B747.fuel.main1_tank.main_xfr_vlv.pos, B747.fuel.main1_tank.main_xfr_vlv.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.main2_tank.refuel_vlv_L.pos   = B747_set_anim_value(B747.fuel.main2_tank.refuel_vlv_L.pos, B747.fuel.main2_tank.refuel_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main2_tank.refuel_vlv_R.pos   = B747_set_anim_value(B747.fuel.main2_tank.refuel_vlv_R.pos, B747.fuel.main2_tank.refuel_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.engine2.xfeed_vlv.pos           = B747_set_anim_value(B747.fuel.engine2.xfeed_vlv.pos, B747.fuel.engine2.xfeed_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main2_tank.jett_vlv.pos     = B747_set_anim_value(B747.fuel.main2_tank.jett_vlv.pos, B747.fuel.main2_tank.jett_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main2_tank.apu_vlv.pos      = B747_set_anim_value(B747.fuel.main2_tank.apu_vlv.pos, B747.fuel.main2_tank.apu_vlv.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.main3_tank.refuel_vlv_L.pos   = B747_set_anim_value(B747.fuel.main3_tank.refuel_vlv_L.pos, B747.fuel.main3_tank.refuel_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main3_tank.refuel_vlv_R.pos   = B747_set_anim_value(B747.fuel.main3_tank.refuel_vlv_R.pos, B747.fuel.main3_tank.refuel_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.engine3.xfeed_vlv.pos           = B747_set_anim_value(B747.fuel.engine3.xfeed_vlv.pos, B747.fuel.engine3.xfeed_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main3_tank.jett_vlv.pos     = B747_set_anim_value(B747.fuel.main3_tank.jett_vlv.pos, B747.fuel.main3_tank.jett_vlv.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.main4_tank.refuel_vlv.pos       = B747_set_anim_value(B747.fuel.main4_tank.refuel_vlv.pos, B747.fuel.main4_tank.refuel_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.engine4.xfeed_vlv.pos           = B747_set_anim_value(B747.fuel.engine4.xfeed_vlv.pos, B747.fuel.engine4.xfeed_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.main4_tank.main_xfr_vlv.pos   = B747_set_anim_value(B747.fuel.main4_tank.main_xfr_vlv.pos, B747.fuel.main4_tank.main_xfr_vlv.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.stab_tank.refuel_vlv.pos        = B747_set_anim_value(B747.fuel.stab_tank.refuel_vlv.pos, B747.fuel.stab_tank.refuel_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.stab_tank.isolation_vlv_L.pos     = B747_set_anim_value(B747.fuel.stab_tank.isolation_vlv_L.pos, B747.fuel.stab_tank.isolation_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.stab_tank.xfr_jett_vlv_L.pos      = B747_set_anim_value(B747.fuel.stab_tank.xfr_jett_vlv_L.pos, B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.stab_tank.isolation_vlv_R.pos     = B747_set_anim_value(B747.fuel.stab_tank.isolation_vlv_R.pos, B747.fuel.stab_tank.isolation_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.stab_tank.xfr_jett_vlv_R.pos      = B747_set_anim_value(B747.fuel.stab_tank.xfr_jett_vlv_R.pos, B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.res2_tank.refuel_vlv.pos        = B747_set_anim_value(B747.fuel.res2_tank.refuel_vlv.pos, B747.fuel.res2_tank.refuel_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.res2_tank.xfr_vlv_A.pos     = B747_set_anim_value(B747.fuel.res2_tank.xfr_vlv_A.pos, B747.fuel.res2_tank.xfr_vlv_A.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.res2_tank.xfr_vlv_B.pos     = B747_set_anim_value(B747.fuel.res2_tank.xfr_vlv_B.pos, B747.fuel.res2_tank.xfr_vlv_B.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.res3_tank.refuel_vlv.pos        = B747_set_anim_value(B747.fuel.res3_tank.refuel_vlv.pos, B747.fuel.res3_tank.refuel_vlv.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.res3_tank.xfr_vlv_A.pos     = B747_set_anim_value(B747.fuel.res3_tank.xfr_vlv_A.pos, B747.fuel.res3_tank.xfr_vlv_A.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.res3_tank.xfr_vlv_B.pos     = B747_set_anim_value(B747.fuel.res3_tank.xfr_vlv_B.pos, B747.fuel.res3_tank.xfr_vlv_B.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.spar_vlv1.pos             = B747_set_anim_value(B747.fuel.spar_vlv1.pos, B747.fuel.spar_vlv1.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.spar_vlv2.pos             = B747_set_anim_value(B747.fuel.spar_vlv2.pos, B747.fuel.spar_vlv2.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.spar_vlv3.pos             = B747_set_anim_value(B747.fuel.spar_vlv3.pos, B747.fuel.spar_vlv3.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.spar_vlv4.pos             = B747_set_anim_value(B747.fuel.spar_vlv4.pos, B747.fuel.spar_vlv4.target_pos, 0.0, 1.0, valve_anm_speed)

    B747.fuel.jett_nozzle_vlv_L.pos         = B747_set_anim_value(B747.fuel.jett_nozzle_vlv_L.pos, B747.fuel.jett_nozzle_vlv_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747.fuel.jett_nozzle_vlv_R.pos         = B747_set_anim_value(B747.fuel.jett_nozzle_vlv_R.pos, B747.fuel.jett_nozzle_vlv_R.target_pos, 0.0, 1.0, valve_anm_speed)

end



function set_engine_OJ_sources(source_table)

         -- CENTER TANK
        if B747.fuel.center_tank.ovrd_jett_pump_L.on > 0 or B747.fuel.center_tank.ovrd_jett_pump_R.on > 0 then
            if simDR_fuel_tank_weight_kg[0] > 900.0 then table.insert(source_table, 0) end
        end

        -- MAIN 2 TANK
        if B747.fuel.main2_tank.ovrd_jett_pump_fwd.on > 0 or B747.fuel.main2_tank.ovrd_jett_pump_aft.on > 0 then
            if simDR_fuel_tank_weight_kg[2] > 3200.0 then table.insert(source_table, 2) end

        end

        -- MAIN 3 TANK
        if B747.fuel.main3_tank.ovrd_jett_pump_fwd.on > 0 or B747.fuel.main3_tank.ovrd_jett_pump_aft.on> 0 then
            if simDR_fuel_tank_weight_kg[3] > 3200.0 then table.insert(source_table, 3) end
        end

    end
----- ENGINE FUEL SOURCE ------------------------------------------------------------
function B747_engine_fuel_source()

    --[[

    NOTE:  ALTHOUGH IT IS FEASIBLE THAT ANY MAIN PUMP COULD SUPPLY ANY ENGINE, IT WOUYLD BE RARE AND THEREFORE IT IS NOT MODELED.

    --]]

    local totalFuelFLow_KgH = (simDR_eng_fuel_flow_kg_sec[0] + simDR_eng_fuel_flow_kg_sec[1] + simDR_eng_fuel_flow_kg_sec[2] + simDR_eng_fuel_flow_kg_sec[3]) * 3600.0
    num_pressurized_oj_pumps = 0
    if B747.fuel.center_tank.ovrd_jett_pump_L.on == 1 and simDR_fuel_tank_weight_kg[0] > 900.0 then num_pressurized_oj_pumps = num_pressurized_oj_pumps + 1 end
    if B747.fuel.center_tank.ovrd_jett_pump_R.on == 1 and simDR_fuel_tank_weight_kg[0] > 900.0 then num_pressurized_oj_pumps = num_pressurized_oj_pumps + 1 end
    if B747.fuel.main2_tank.ovrd_jett_pump_fwd.on == 1 and simDR_fuel_tank_weight_kg[2] > 3200.0 then num_pressurized_oj_pumps = num_pressurized_oj_pumps + 1 end
    if B747.fuel.main2_tank.ovrd_jett_pump_aft.on == 1 and simDR_fuel_tank_weight_kg[2] > 3200.0 then num_pressurized_oj_pumps = num_pressurized_oj_pumps + 1 end
    if B747.fuel.main3_tank.ovrd_jett_pump_fwd.on == 1 and simDR_fuel_tank_weight_kg[3] > 3200.0 then num_pressurized_oj_pumps = num_pressurized_oj_pumps + 1 end
    if B747.fuel.main3_tank.ovrd_jett_pump_aft.on == 1 and simDR_fuel_tank_weight_kg[3] > 3200.0 then num_pressurized_oj_pumps = num_pressurized_oj_pumps + 1 end

    


    ---------------------------------------------------------------------------------
    -----                           E N G I N E   # 1                           -----
    ---------------------------------------------------------------------------------
    engine1fuelSrc = {}
    local engine1GenStatus = 0

    --- ENGINE 1 CROSSFEED VALVE IS CLOSED
    if B747.fuel.engine1.xfeed_vlv.pos < 0.01 then

        -- EITHER MAIN 1 PUMP IS ON
        if B747.fuel.main1_tank.main_pump_fwd.on > 0 or B747.fuel.main1_tank.main_pump_aft.on > 0 then

            -- FUEL SOURCE IS MAIN TANK 1
            if simDR_fuel_tank_weight_kg[1] > 0.0 then
                table.insert(engine1fuelSrc, 1)
                engine1GenStatus = 1
            end
        end


    --- ENGINE 1 CROSSFEED VALVE IS OPEN
    else

        -- BOTH MAIN 1 PUMPS ARE OFF
        if B747.fuel.main1_tank.main_pump_fwd.on < 0.01 and B747.fuel.main1_tank.main_pump_aft.on < 0.01 then

            set_engine_OJ_sources(engine1fuelSrc)                                                       -- FUEL SOURCE IS OJ PUMP(S) TANK
            if num_pressurized_oj_pumps > 0 then engine1GenStatus = 2 end                               -- GENERIC INSTRUMENT DISPLAY STATUS

        -- BOTH MAIN 1 PUMPS ARE ON
        elseif B747.fuel.main1_tank.main_pump_fwd.on > 0 and B747.fuel.main1_tank.main_pump_aft.on > 0 then

            if num_pressurized_oj_pumps >= 2 then                                                       -- OJ OVERRIDE OF MAIN 1 PUMPS
                set_engine_OJ_sources(engine1fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine1GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[1] > 0.0 then
                    table.insert(engine1fuelSrc, 1)                                                     -- FUEL SOURCE IS MAIN TANK 1
                    engine1GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        -- ONLY ONE MAIN 1 PUMP IS ON
        else
            if num_pressurized_oj_pumps >= 1 then                                                       -- OJ OVERRIDE OF MAIN 1 PUMP
                set_engine_OJ_sources(engine1fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine1GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[1] > 0.0 then
                    table.insert(engine1fuelSrc, 1)                                                     -- FUEL SOURCE IS MAIN TANK 1
                    engine1GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        end
    end
    B747DR_gen_fuel_engine1_status = engine1GenStatus


    ---------------------------------------------------------------------------------
    -----                           E N G I N E   # 2                           -----
    ---------------------------------------------------------------------------------
    engine2fuelSrc = {}
    local engine2GenStatus = 0

    --- ENGINE 2 CROSSFEED VALVE IS CLOSED
    if B747.fuel.engine2.xfeed_vlv.pos < 0.01 then

         -- EITHER MAIN 2 PUMP IS ON
        if B747.fuel.main2_tank.main_pump_fwd.on > 0 or B747.fuel.main2_tank.main_pump_aft.on > 0 then

            -- FUEL SOURCE IS MAIN TANK 2
            if simDR_fuel_tank_weight_kg[2] > 0.0 then
                table.insert(engine2fuelSrc, 2)
                engine2GenStatus = 1
            end
        end


    --- ENGINE 2 CROSSFEED VALVE IS OPEN
    else

        -- BOTH MAIN 2 PUMPS ARE OFF
        if B747.fuel.main2_tank.main_pump_fwd.on < 0.01 and B747.fuel.main2_tank.main_pump_aft.on < 0.01 then

                set_engine_OJ_sources(engine2fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                if num_pressurized_oj_pumps > 0 then engine2GenStatus = 2 end                               -- GENERIC INSTRUMENT DISPLAY STATUS

        -- BOTH MAIN 2 PUMPS ARE ON
        elseif B747.fuel.main2_tank.main_pump_fwd.on > 0 and B747.fuel.main2_tank.main_pump_aft.on > 0 then

            if num_pressurized_oj_pumps >= 2 then                                                       -- OJ OVERRIDE OF MAIN 2 PUMPS
                set_engine_OJ_sources(engine2fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine2GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[2] > 0.0 then
                    table.insert(engine2fuelSrc, 2)                                                     -- FUEL SOURCE IS MAIN TANK 2
                    engine2GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        -- ONLY ONE MAIN 2 PUMP IS ON
        else
             if num_pressurized_oj_pumps >= 1 then                                                      -- OJ OVERRIDE OF MAIN 2 PUMP
                set_engine_OJ_sources(engine2fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine2GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[2] > 0.0 then
                    table.insert(engine2fuelSrc, 2)                                                     -- FUEL SOURCE IS MAIN TANK 2
                    engine2GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                 end
            end

        end
    end
    B747DR_gen_fuel_engine2_status = engine2GenStatus


    ---------------------------------------------------------------------------------
    -----                           E N G I N E   # 3                           -----
    ---------------------------------------------------------------------------------
    engine3fuelSrc = {}
    local engine3GenStatus = 0

    --- ENGINE 3 CROSSFEED VALVE IS CLOSED
    if B747.fuel.engine3.xfeed_vlv.pos < 0.01 then

         -- EITHER MAIN 3 PUMP IS ON
        if B747.fuel.main3_tank.main_pump_fwd.on > 0 or B747.fuel.main3_tank.main_pump_aft.on > 0 then

            -- FUEL SOURCE IS MAIN TANK 3
            if simDR_fuel_tank_weight_kg[3] > 0.0 then
                table.insert(engine3fuelSrc, 3)
                engine3GenStatus = 1
            end
        end


    --- ENGINE 3 CROSSFEED VALVE IS OPEN
    else

        -- BOTH MAIN 3 PUMPS ARE OFF
        if B747.fuel.main3_tank.main_pump_fwd.on < 0.01 and B747.fuel.main3_tank.main_pump_aft.on < 0.01 then

                set_engine_OJ_sources(engine3fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                if num_pressurized_oj_pumps > 0 then engine3GenStatus = 2 end                           -- GENERIC INSTRUMENT DISPLAY STATUS

        -- BOTH MAIN 3 PUMPS ARE ON
        elseif B747.fuel.main3_tank.main_pump_fwd.on > 0 and B747.fuel.main3_tank.main_pump_aft.on > 0 then

            if num_pressurized_oj_pumps >= 2 then                                                       -- OJ OVERRIDE OF MAIN 3 PUMPS
                set_engine_OJ_sources(engine3fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine3GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[3] > 0.0 then
                    table.insert(engine3fuelSrc, 3)                                                     -- FUEL SOURCE IS MAIN TANK 3
                    engine3GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        -- ONLY ONE MAIN 3 PUMP IS ON
        else
             if num_pressurized_oj_pumps >= 1 then                                                      -- OJ OVERRIDE OF MAIN 3 PUMP
                set_engine_OJ_sources(engine3fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine3GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[3] > 0.0 then
                    table.insert(engine3fuelSrc, 3)                                                     -- FUEL SOURCE IS MAIN TANK 3
                    engine3GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        end
    end
    B747DR_gen_fuel_engine3_status = engine3GenStatus


    ---------------------------------------------------------------------------------
    -----                           E N G I N E   # 4                           -----
    ---------------------------------------------------------------------------------
    engine4fuelSrc = {}
    local engine4GenStatus = 0

    --- ENGINE 4 CROSSFEED VALVE IS CLOSED
    if B747.fuel.engine4.xfeed_vlv.pos < 0.01 then

         -- EITHER MAIN 4 PUMP IS ON
        if B747.fuel.main4_tank.main_pump_fwd.on > 0 or B747.fuel.main4_tank.main_pump_aft.on > 0 then

            -- FUEL SOURCE IS MAIN TANK 4
            if simDR_fuel_tank_weight_kg[4] > 0.0 then
                table.insert(engine4fuelSrc, 4)
                engine4GenStatus = 1
            end
        end


    --- ENGINE 4 CROSSFEED VALVE IS OPEN
    else

        -- BOTH MAIN 4 PUMPS ARE OFF
        if B747.fuel.main4_tank.main_pump_fwd.on < 0.01 and B747.fuel.main4_tank.main_pump_aft.on < 0.01 then

                set_engine_OJ_sources(engine4fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                if num_pressurized_oj_pumps > 0 then engine4GenStatus = 2 end                           -- GENERIC INSTRUMENT DISPLAY STATUS

        -- BOTH MAIN 4 PUMPS ARE ON
        elseif B747.fuel.main4_tank.main_pump_fwd.on > 0 and B747.fuel.main4_tank.main_pump_aft.on > 0 then

            if num_pressurized_oj_pumps >= 2 then                                                       -- OJ OVERRIDE OF MAIN 4 PUMPS
                set_engine_OJ_sources(engine4fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine4GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[4] > 0.0 then
                    table.insert(engine4fuelSrc, 4)                                                     -- FUEL SOURCE IS MAIN TANK 4
                    engine4GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        -- ONLY ONE MAIN 4 PUMP IS ON
        else
             if num_pressurized_oj_pumps >= 1 then                                                      -- OJ OVERRIDE OF MAIN 4 PUMP
                set_engine_OJ_sources(engine4fuelSrc)                                                   -- FUEL SOURCE IS OJ PUMP(S) TANK
                engine4GenStatus = 2                                                                    -- GENERIC INSTRUMENT DISPLAY STATUS
            else
                if simDR_fuel_tank_weight_kg[4] > 0.0 then
                    table.insert(engine4fuelSrc, 4)                                                     -- FUEL SOURCE IS MAIN TANK 4
                    engine4GenStatus = 1                                                                -- GENERIC INSTRUMENT DISPLAY STATUS
                end
            end

        end
    end
    B747DR_gen_fuel_engine4_status = engine4GenStatus

end





local engineHasFuelProcessing = 0
function startFuelProcessing()

    engineHasFuelProcessing = 1
    
end
----- ENGINE(S) HAVE FUEL SUPPLY ----------------------------------------------------
function B747_engine_has_fuel()

    if engineHasFuelProcessing == 1 then
        simDR_engine_has_fuel[0] = B747_ternary((#engine1fuelSrc > 0 and B747.fuel.spar_vlv1.pos > 0 and B747DR_engine_fuel_valve_pos[0] > 0), 1, 0)
        simDR_engine_has_fuel[1] = B747_ternary((#engine2fuelSrc > 0 and B747.fuel.spar_vlv2.pos > 0 and B747DR_engine_fuel_valve_pos[1] > 0), 1, 0)
        simDR_engine_has_fuel[2] = B747_ternary((#engine3fuelSrc > 0 and B747.fuel.spar_vlv3.pos > 0 and B747DR_engine_fuel_valve_pos[2] > 0), 1, 0)
        simDR_engine_has_fuel[3] = B747_ternary((#engine4fuelSrc > 0 and B747.fuel.spar_vlv4.pos > 0 and B747DR_engine_fuel_valve_pos[3] > 0), 1, 0)
    end
    --if engineHasFuelProcessing == 0 then
     local update=B747DR_engine_fuel_valve_pos[0]
     update=B747DR_engine_fuel_valve_pos[1]
     update=B747DR_engine_fuel_valve_pos[2]
     update=B747DR_engine_fuel_valve_pos[3]
     update=simDR_engine_has_fuel[0] 
     update=simDR_engine_has_fuel[1] 
     update=simDR_engine_has_fuel[2] 
     update=simDR_engine_has_fuel[3] 
    --end
      
end







----- FUEL FLOW RATES ---------------------------------------------------------------
function B747_fuel_flow_rate()

    local gravity_flow_rate = 1.1       -- THIS VALUE IS AN EDUCATED GUESS AT THIS POINT, SEEMS TO WORK WELL BASED ON PUBLISHED LOGIC

    ----- TRANSFER ------------------------------------------------------------------

    -- FROM STABILIZER TANK TO CENTER TANK (RATE =  APPROX 1.5 HOURS FOR TOTAL TRANSFER WITH BOTH PUMPS ON)
    -- RATE = 10030 Kg TOTAL IN 90 MIN = 111.444444 Kg/MIN = 1.8574074074 Kg/SEC TOTAL = 0.9287037037 Kg/SEC/PUMP
    stabTank_to_centerTank_xfr_KgSec_L = B747_ternary((simDR_fuel_tank_weight_kg[7] > 0.0), ((B747.fuel.stab_tank.xfr_jett_pump_L.on * B747.fuel.stab_tank.xfr_jett_vlv_L.pos * B747.fuel.center_tank.stab_xfr_vlv_L.pos) * 0.9287037037), 0.0)
    stabTank_to_centerTank_xfr_KgSec_R = B747_ternary((simDR_fuel_tank_weight_kg[7] > 0.0), ((B747.fuel.stab_tank.xfr_jett_pump_R.on * B747.fuel.stab_tank.xfr_jett_vlv_R.pos * B747.fuel.center_tank.stab_xfr_vlv_R.pos) * 0.9287037037), 0.0)


    -- RESERVE TANK 2 TO MAIN TANK 2 (RATE = GRAVITY)
    resTank2_to_mainTank2_xfr_KgSec_A = B747_ternary((simDR_fuel_tank_weight_kg[5] > 0.0), (B747.fuel.res2_tank.xfr_vlv_A.pos * gravity_flow_rate), 0.0)
    resTank2_to_mainTank2_xfr_KgSec_B = B747_ternary((simDR_fuel_tank_weight_kg[5] > 0.0), (B747.fuel.res2_tank.xfr_vlv_B.pos * gravity_flow_rate), 0.0)


    -- RESERVE TANK 3 TO MAIN TANK 3 (RATE = GRAVITY)
    resTank3_to_mainTank3_xfr_KgSec_A = B747_ternary((simDR_fuel_tank_weight_kg[6] > 0.0), (B747.fuel.res3_tank.xfr_vlv_A.pos * gravity_flow_rate), 0.0)
    resTank3_to_mainTank3_xfr_KgSec_B = B747_ternary((simDR_fuel_tank_weight_kg[6] > 0.0), (B747.fuel.res3_tank.xfr_vlv_B.pos * gravity_flow_rate), 0.0)


    -- FROM MAIN TANK 1 TO MAIN TANK 2 (RATE = GRAVITY) - RESTRICT XFR TO 3200.0 KG REMAINING IN OUTBOARD TANK #1
    mainTank1_to_mainTank2_xfr_KgSec = B747_ternary((simDR_fuel_tank_weight_kg[1] > 3200.0), (B747.fuel.main1_tank.main_xfr_vlv.pos * gravity_flow_rate), 0.0)


    -- FROM MAIN TANK 4 TO MAIN TANK 3 (RATE = GRAVITY) - RESTRICT XFR TO 3200.0 KG REMAINING IN OUTBOARD TANK #4
    mainTank4_to_mainTank3_xfr_KgSec = B747_ternary((simDR_fuel_tank_weight_kg[4] > 3200.0), (B747.fuel.main4_tank.main_xfr_vlv.pos * gravity_flow_rate), 0.0)


    -- FROM CENTER TANK TO MAIN TANK 2 (SCAVENGE: RATE = 545 Kg/HR)
    centerTank_to_mainTank2_xfr_KgSec_L1 = B747_ternary((simDR_fuel_tank_weight_kg[0] > 0.0), (B747.fuel.center_tank.scvg_pump_L1.on * 0.15138888888889), 0.0)
    centerTank_to_mainTank2_xfr_KgSec_L2 = B747_ternary((simDR_fuel_tank_weight_kg[0] > 0.0), (B747.fuel.center_tank.scvg_pump_L2.on * 0.15138888888889), 0.0)


    -- FROM CENTER TANK TO MAIN TANK 3 (SCAVENGE: RATE = 545 Kg/HR)
    centerTank_to_mainTank3_xfr_KgSec_R1 = B747_ternary((simDR_fuel_tank_weight_kg[0] > 0.0), (B747.fuel.center_tank.scvg_pump_R1.on * 0.15138888888889), 0.0)
    centerTank_to_mainTank3_xfr_KgSec_R2 = B747_ternary((simDR_fuel_tank_weight_kg[0] > 0.0), (B747.fuel.center_tank.scvg_pump_R2.on * 0.15138888888889), 0.0)




    ----- FUEL DUMP -----------------------------------------------------------------

    -- TOTAL JETTISON PUMPS = 6
    -- RATE = 2000 Kg/MIN TOTAL = 333/Kg/MIN/PUMP = 5.55 Kg/SEC/PUMP
    -- JETTISON RESTRICTED TO 3200 Kg REMAINING IN EACH TANK
    local kgDefuelrate=5.55
    if simDR_all_wheels_on_ground == 1 then
      kgDefuelrate = 20
    end
    centerTank_jettison_KgSec_L    = B747_ternary((simDR_fuel_tank_weight_kg[0] > 3200.0), ((B747.fuel.center_tank.jett_vlv_L.pos * B747.fuel.center_tank.ovrd_jett_pump_L.on) * kgDefuelrate), 0.0)
    centerTank_jettison_KgSec_R    = B747_ternary((simDR_fuel_tank_weight_kg[0] > 3200.0), ((B747.fuel.center_tank.jett_vlv_R.pos * B747.fuel.center_tank.ovrd_jett_pump_R.on) * kgDefuelrate), 0.0)
    mainTank2_jettison_KgSec_A     = B747_ternary((simDR_fuel_tank_weight_kg[2] > 3200.0), (((B747.fuel.main2_tank.jett_vlv.pos) * ((B747.fuel.main2_tank.ovrd_jett_pump_fwd.on))) * kgDefuelrate), 0.0)
    mainTank2_jettison_KgSec_B     = B747_ternary((simDR_fuel_tank_weight_kg[2] > 3200.0), (((B747.fuel.main2_tank.jett_vlv.pos) * ((B747.fuel.main2_tank.ovrd_jett_pump_aft.on))) * kgDefuelrate), 0.0)
    mainTank3_jettison_KgSec_A     = B747_ternary((simDR_fuel_tank_weight_kg[3] > 3200.0), (((B747.fuel.main3_tank.jett_vlv.pos) * ((B747.fuel.main3_tank.ovrd_jett_pump_fwd.on))) * kgDefuelrate), 0.0)
    mainTank3_jettison_KgSec_B     = B747_ternary((simDR_fuel_tank_weight_kg[3] > 3200.0), (((B747.fuel.main3_tank.jett_vlv.pos) * ((B747.fuel.main3_tank.ovrd_jett_pump_aft.on))) * kgDefuelrate), 0.0)




    ----- APU FUEL BURN -------------------------------------------------------------

    -- APU  (RATE = 500 KG/HR)
    
    if B747.fuel.main2_tank.main_pump_aft.on > 0.95
        or B747.fuel.main2_tank.apu_dc_pump.on > 0.95
    then
        apuFuelBurn_KgSec = B747.fuel.main2_tank.apu_vlv.pos * 0.13888888888889
    else
        apuFuelBurn_KgSec = 0
    end




    ----- ENGINE FUEL BURN ----------------------------------------------------------

    -- USE:  simDR_eng_fuel_flow_kg_sec  (SEE ENGINE FUEL BURN BELOW)

end





function B747_fuel_tank_levels()
    if lastFuelUpdate==0 then
        lastFuelUpdate=simDR_time_now
    end
    fuel_calc_rate=simDR_time_now-lastFuelUpdate
    --print("B747_fuel_tank_levels "..(fuel_calc_rate))
    lastFuelUpdate=simDR_time_now
    if lastTotalFuel==0 then 
        lastTotalFuel=simDR_fuel_tank_weight_total_kg 
        for i=0,7,1 do
            lastFuelLevels[i]=simDR_fuel_tank_weight_kg[i]
        end
    end
    if startedRefil==0 then
        startedRefil=simDR_time_now
    end
    local cFuel=simDR_fuel_tank_weight_total_kg
    if (simDR_time_now-startedRefil)<2 and simDR_all_wheels_on_ground == 1 and engineHasFuelProcessing==0 and cFuel>100000 then
        --print("empty fuel")
        B747DR_refuel=cFuel-100000
        simDR_fuel_tank_weight_kg[0]=0
        simDR_fuel_tank_weight_kg[1]=11976
        simDR_fuel_tank_weight_kg[2]=33793
        simDR_fuel_tank_weight_kg[3]=33793
        simDR_fuel_tank_weight_kg[4]=11976
        simDR_fuel_tank_weight_kg[5]=3517
        simDR_fuel_tank_weight_kg[6]=3517
        simDR_fuel_tank_weight_kg[7]=0
        
        return
    end

    
    if simDR_all_wheels_on_ground == 0 and IN_REPLAY==0 and lastTotalFuel<simDR_fuel_tank_weight_total_kg and engineHasFuelProcessing==1 then
        print("reverted fuel levels")
        for i=0,7,1 do
            simDR_fuel_tank_weight_kg[i]=lastFuelLevels[i]
        end
    
       
    end
    if  (simDR_time_now-startedRefil)>10 then
        engineHasFuelProcessing=1
    end
    ----- FUEL TRANSFER ---------------------------------------------------------

    -- FROM STABILIZER TANK TO CENTER TANK
    if simDR_fuel_tank_weight_kg[7] > 0 and simDR_fuel_tank_weight_kg[0] < B747.fuel.center_tank.capacity then
        simDR_fuel_tank_weight_kg[7] = math.max(B747.fuel.stab_tank.min, simDR_fuel_tank_weight_kg[7] - (stabTank_to_centerTank_xfr_KgSec_L * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[0] = math.min(B747.fuel.center_tank.capacity, simDR_fuel_tank_weight_kg[0] + (stabTank_to_centerTank_xfr_KgSec_L * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[7] = math.max(B747.fuel.stab_tank.min, simDR_fuel_tank_weight_kg[7] - (stabTank_to_centerTank_xfr_KgSec_R * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[0] = math.min(B747.fuel.center_tank.capacity, simDR_fuel_tank_weight_kg[0] + (stabTank_to_centerTank_xfr_KgSec_R * fuel_calc_rate))
    end


    -- FROM RESERVE TANK 2 TO MAIN TANK 2
    if simDR_fuel_tank_weight_kg[5] > 0 and simDR_fuel_tank_weight_kg[2] < B747.fuel.main2_tank.capacity then
        simDR_fuel_tank_weight_kg[5] = math.max(B747.fuel.res2_tank.min, simDR_fuel_tank_weight_kg[5] - (resTank2_to_mainTank2_xfr_KgSec_A * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[2] = math.min(B747.fuel.main2_tank.capacity,( simDR_fuel_tank_weight_kg[2] + (resTank2_to_mainTank2_xfr_KgSec_A * fuel_calc_rate)))

        simDR_fuel_tank_weight_kg[5] = math.max(B747.fuel.res2_tank.min, simDR_fuel_tank_weight_kg[5] - (resTank2_to_mainTank2_xfr_KgSec_B * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[2] = math.min(B747.fuel.main2_tank.capacity, (simDR_fuel_tank_weight_kg[2] + (resTank2_to_mainTank2_xfr_KgSec_B * fuel_calc_rate)))
    end


    -- FROM RESERVE TANK 3 TO MAIN TANK 3
    if simDR_fuel_tank_weight_kg[6] > 0 and simDR_fuel_tank_weight_kg[3] < B747.fuel.main3_tank.capacity then
        simDR_fuel_tank_weight_kg[6] = math.max(B747.fuel.res3_tank.min, simDR_fuel_tank_weight_kg[6] - (resTank3_to_mainTank3_xfr_KgSec_A * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[3] = math.min(B747.fuel.main3_tank.capacity, simDR_fuel_tank_weight_kg[3] + (resTank3_to_mainTank3_xfr_KgSec_A * fuel_calc_rate))

        simDR_fuel_tank_weight_kg[6] = math.max(B747.fuel.res3_tank.min, simDR_fuel_tank_weight_kg[6] - (resTank3_to_mainTank3_xfr_KgSec_B * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[3] = math.min(B747.fuel.main3_tank.capacity, simDR_fuel_tank_weight_kg[3] + (resTank3_to_mainTank3_xfr_KgSec_B * fuel_calc_rate))
    end


    -- FROM MAIN TANK 1 TO MAIN TANK 2
    if simDR_fuel_tank_weight_kg[1] > 0 and simDR_fuel_tank_weight_kg[2] < B747.fuel.main2_tank.capacity then
        simDR_fuel_tank_weight_kg[1] = math.max(B747.fuel.main1_tank.min, simDR_fuel_tank_weight_kg[1] - (mainTank1_to_mainTank2_xfr_KgSec * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[2] = math.min(B747.fuel.main2_tank.capacity, simDR_fuel_tank_weight_kg[2] + (mainTank1_to_mainTank2_xfr_KgSec * fuel_calc_rate))
    end


    -- FROM MAIN TANK 4 TO MAIN TANK 3
    if simDR_fuel_tank_weight_kg[4] > 0 and simDR_fuel_tank_weight_kg[3] < B747.fuel.main3_tank.capacity then
        simDR_fuel_tank_weight_kg[4] = math.max(B747.fuel.main4_tank.min, simDR_fuel_tank_weight_kg[4] - (mainTank4_to_mainTank3_xfr_KgSec * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[3] = math.min(B747.fuel.main3_tank.capacity, simDR_fuel_tank_weight_kg[3] + (mainTank4_to_mainTank3_xfr_KgSec * fuel_calc_rate))
    end


    -- FROM CENTER TANK TO MAIN TANK 2 (SCAVENGE)
    if simDR_fuel_tank_weight_kg[0] > 0 and simDR_fuel_tank_weight_kg[2] < B747.fuel.main2_tank.capacity then
        simDR_fuel_tank_weight_kg[0] = math.max(B747.fuel.center_tank.min, simDR_fuel_tank_weight_kg[0] - (centerTank_to_mainTank2_xfr_KgSec_L1 * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[2] = math.min(B747.fuel.main2_tank.capacity, simDR_fuel_tank_weight_kg[2] + (centerTank_to_mainTank2_xfr_KgSec_L1 * fuel_calc_rate))

        simDR_fuel_tank_weight_kg[0] = math.max(B747.fuel.center_tank.min, simDR_fuel_tank_weight_kg[0] - (centerTank_to_mainTank2_xfr_KgSec_L2 * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[2] = math.min(B747.fuel.main2_tank.capacity, simDR_fuel_tank_weight_kg[2] + (centerTank_to_mainTank2_xfr_KgSec_L2 * fuel_calc_rate))
    end


    -- FROM CENTER TANK TO MAIN TANK 3 (SCAVENGE)
    if simDR_fuel_tank_weight_kg[0] > 0 and simDR_fuel_tank_weight_kg[3] < B747.fuel.main3_tank.capacity then
        simDR_fuel_tank_weight_kg[0] = math.max(B747.fuel.center_tank.min, simDR_fuel_tank_weight_kg[0] - (centerTank_to_mainTank3_xfr_KgSec_R1 * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[3] = math.min(B747.fuel.main3_tank.capacity, simDR_fuel_tank_weight_kg[3] + (centerTank_to_mainTank3_xfr_KgSec_R1 * fuel_calc_rate))

        simDR_fuel_tank_weight_kg[0] = math.max(B747.fuel.center_tank.min, simDR_fuel_tank_weight_kg[0] - (centerTank_to_mainTank3_xfr_KgSec_R2 * fuel_calc_rate))
        simDR_fuel_tank_weight_kg[3] = math.min(B747.fuel.main3_tank.capacity, simDR_fuel_tank_weight_kg[3] + (centerTank_to_mainTank3_xfr_KgSec_R2 * fuel_calc_rate))
    end



    ----- FUEL DUMP -------------------------------------------------------------

    local fuel_jett_valve_flow_factor = (B747.fuel.jett_nozzle_vlv_L.pos * 0.5) + (B747.fuel.jett_nozzle_vlv_R.pos * 0.5)

    -- FROM CENTER TANK
    simDR_fuel_tank_weight_kg[0] = math.max(B747.fuel.center_tank.min, simDR_fuel_tank_weight_kg[0] - ((centerTank_jettison_KgSec_L * fuel_jett_valve_flow_factor) * fuel_calc_rate))
    simDR_fuel_tank_weight_kg[0] = math.max(B747.fuel.center_tank.min, simDR_fuel_tank_weight_kg[0] - ((centerTank_jettison_KgSec_R * fuel_jett_valve_flow_factor) * fuel_calc_rate))

    -- FROM MAIN TANK #2
    simDR_fuel_tank_weight_kg[2] = math.max(B747.fuel.main2_tank.min, simDR_fuel_tank_weight_kg[2] - ((mainTank2_jettison_KgSec_A * fuel_jett_valve_flow_factor) * fuel_calc_rate))
    simDR_fuel_tank_weight_kg[2] = math.max(B747.fuel.main2_tank.min, simDR_fuel_tank_weight_kg[2] - ((mainTank2_jettison_KgSec_B * fuel_jett_valve_flow_factor) * fuel_calc_rate))

    -- FROM MAIN TANK #3
    simDR_fuel_tank_weight_kg[3] = math.max(B747.fuel.main3_tank.min, simDR_fuel_tank_weight_kg[3] - ((mainTank3_jettison_KgSec_A * fuel_jett_valve_flow_factor) * fuel_calc_rate))
    simDR_fuel_tank_weight_kg[3] = math.max(B747.fuel.main3_tank.min, simDR_fuel_tank_weight_kg[3] - ((mainTank3_jettison_KgSec_B * fuel_jett_valve_flow_factor) * fuel_calc_rate))
  -- 0 = center_tank
-- 1 = main1_tank
-- 2 = main2_tank
-- 3 = main3_tank
-- 4 = main4_tank
-- 5 = res2_tank
-- 6 = res3_tank
-- 7 = stab_tank
    simDR_fuel_tank_weight_kg[0] = math.min(B747.fuel.center_tank.capacity, simDR_fuel_tank_weight_kg[0])
    simDR_fuel_tank_weight_kg[1] = math.min(B747.fuel.main1_tank.capacity, simDR_fuel_tank_weight_kg[1])
    simDR_fuel_tank_weight_kg[2] = math.min(B747.fuel.main2_tank.capacity, simDR_fuel_tank_weight_kg[2])
    simDR_fuel_tank_weight_kg[3] = math.min(B747.fuel.main3_tank.capacity, simDR_fuel_tank_weight_kg[3])
    simDR_fuel_tank_weight_kg[4] = math.min(B747.fuel.main4_tank.capacity, simDR_fuel_tank_weight_kg[4])
    simDR_fuel_tank_weight_kg[5] = math.min(B747.fuel.res2_tank.capacity, simDR_fuel_tank_weight_kg[5])
    simDR_fuel_tank_weight_kg[6] = math.min(B747.fuel.res3_tank.capacity, simDR_fuel_tank_weight_kg[6])
    simDR_fuel_tank_weight_kg[7] = math.min(B747.fuel.stab_tank.capacity, simDR_fuel_tank_weight_kg[7])



    ----- ENGINE FUEL BURN ------------------------------------------------------

    -- APU
    simDR_fuel_tank_weight_kg[2] = math.max(B747.fuel.main2_tank.min, simDR_fuel_tank_weight_kg[2] - (apuFuelBurn_KgSec * fuel_calc_rate/2))
    simDR_fuel_tank_weight_kg[3] = math.max(B747.fuel.main3_tank.min, simDR_fuel_tank_weight_kg[3] - (apuFuelBurn_KgSec * fuel_calc_rate/2))
    
    -- ENGINE #1
    local eng1fuelShareRatio = 0
    local engine1_used=0
    if #engine1fuelSrc > 0 then eng1fuelShareRatio = 1.0 / #engine1fuelSrc end
    local engine1_source_fuel_flow_KgSec = simDR_eng_fuel_flow_kg_sec[0] * eng1fuelShareRatio
    
    for _, tankID in ipairs(engine1fuelSrc) do
        engine1_used=engine1_used+(engine1_source_fuel_flow_KgSec * fuel_calc_rate)
        simDR_fuel_tank_weight_kg[tankID] = simDR_fuel_tank_weight_kg[tankID] - (engine1_source_fuel_flow_KgSec * fuel_calc_rate)
    end
 
    B747DR_engine_used_fuel[0]=B747DR_engine_used_fuel[0]+engine1_used
    -- ENGINE #2
    local eng2fuelShareRatio = 0
    local engine2_used=0
    if #engine2fuelSrc > 0 then eng2fuelShareRatio = 1.0 / #engine2fuelSrc end
    local engine2_source_fuel_flow_KgSec = simDR_eng_fuel_flow_kg_sec[1] * eng2fuelShareRatio

    for _, tankID in ipairs(engine2fuelSrc) do
        engine2_used=engine2_used+(engine2_source_fuel_flow_KgSec * fuel_calc_rate)
        simDR_fuel_tank_weight_kg[tankID] = simDR_fuel_tank_weight_kg[tankID] - (engine2_source_fuel_flow_KgSec * fuel_calc_rate)
    end
    B747DR_engine_used_fuel[1]=B747DR_engine_used_fuel[1]+engine2_used

    -- ENGINE #3
    local eng3fuelShareRatio = 0
    local engine3_used=0
    if #engine3fuelSrc > 0 then eng3fuelShareRatio = 1.0 / #engine3fuelSrc end
    local engine3_source_fuel_flow_KgSec = simDR_eng_fuel_flow_kg_sec[2] * eng3fuelShareRatio

    for _, tankID in ipairs(engine3fuelSrc) do
        engine3_used=engine3_used+(engine3_source_fuel_flow_KgSec * fuel_calc_rate)
        simDR_fuel_tank_weight_kg[tankID] = simDR_fuel_tank_weight_kg[tankID] - (engine3_source_fuel_flow_KgSec * fuel_calc_rate)
    end
    B747DR_engine_used_fuel[2]=B747DR_engine_used_fuel[2]+engine3_used

    -- ENGINE #4
    local eng4fuelShareRatio = 0
    local engine4_used=0
    if #engine4fuelSrc > 0 then eng4fuelShareRatio = 1.0 / #engine4fuelSrc end
    local engine4_source_fuel_flow_KgSec = simDR_eng_fuel_flow_kg_sec[3] * eng4fuelShareRatio

    for _, tankID in ipairs(engine4fuelSrc) do
        engine4_used=engine4_used+(engine4_source_fuel_flow_KgSec * fuel_calc_rate)
        simDR_fuel_tank_weight_kg[tankID] = simDR_fuel_tank_weight_kg[tankID] - (engine4_source_fuel_flow_KgSec * fuel_calc_rate)
    end
    B747DR_engine_used_fuel[3]=B747DR_engine_used_fuel[3]+engine4_used
    B747DR_engine_used_fuel[4]=B747DR_engine_used_fuel[4]+engine1_used+engine2_used+engine3_used+engine4_used+(apuFuelBurn_KgSec * fuel_calc_rate)
    lastTotalFuel=simDR_fuel_tank_weight_total_kg 
    --print("processing="..engineHasFuelProcessing)
    for i=0,7,1 do
        --print(i .. " " ..lastFuelLevels[i] .. " ".. simDR_fuel_tank_weight_kg[i])
        lastFuelLevels[i]=simDR_fuel_tank_weight_kg[i]
    end
end








----- FUEL TEMPERATURE ------------------------------------------------------------------
local B747_fuel_temp_init_flag = 0

function B747_init_fuel_temp()
    B747DR_fuel_temperature = simDR_TAT
    B747_fuel_temp_init_flag = 1
end

function B747_fuel_temp()

    if B747_fuel_temp_init_flag == 0 then
        if is_timer_scheduled(B747_init_fuel_temp) == false then
            run_after_time(B747_init_fuel_temp, 1.0)
        end
    else
        B747DR_fuel_temperature = B747_set_anim_value(B747DR_fuel_temperature, simDR_TAT, -47.0, 99.0, 0.0001)
    end

end







----- SYNOPTIC - FUEL TRANSFER ----------------------------------------------------------
function B747_fuel_xfr_synoptic()

    -- STAB TO CENTER TRANSFER
    
    if (B747.fuel.stab_tank.xfr_jett_pump_L.on == 1 or B747.fuel.stab_tank.xfr_jett_pump_R.on == 1)
        and
        (B747.fuel.center_tank.stab_xfr_vlv_L.pos > 0.05 or B747.fuel.center_tank.stab_xfr_vlv_R.pos > 0.05)
    then
        B747DR_stab_xfr_status = 1
        if simDR_fuel_tank_weight_kg[7] > 0.0 then
            B747DR_stab_xfr_status = 2
        end
    else
        B747DR_stab_xfr_status = 0
    end


    -- RES2 TO MAIN2 TRANSFER
    
    if B747.fuel.res2_tank.xfr_vlv_A.pos > 0.05 or B747.fuel.res2_tank.xfr_vlv_B.pos > 0.05 then
         B747DR_res2_xfr_status = 1
         if simDR_fuel_tank_weight_kg[5] > 0.0 then
            B747DR_res2_xfr_status = 2
         end
    else
        B747DR_res2_xfr_status = 0
    end


    -- RES3 TO MAIN3 TRANSFER
    
    if B747.fuel.res3_tank.xfr_vlv_A.pos > 0.05 or B747.fuel.res3_tank.xfr_vlv_B.pos > 0.05 then
         B747DR_res3_xfr_status = 1
         if simDR_fuel_tank_weight_kg[6] > 0.0 then
            B747DR_res3_xfr_status = 2
         end
    else
        B747DR_res3_xfr_status = 0
    end


    -- CENTER TO MAIN 2
    
    if B747.fuel.center_tank.scvg_pump_L1.on == 1 or B747.fuel.center_tank.scvg_pump_L2.on == 1 then
        B747DR_ctr_scvg_L_status = 1
        if simDR_fuel_tank_weight_kg[0] > 0.0 then
            B747DR_ctr_scvg_L_status = 2
        end
    else
        B747DR_ctr_scvg_L_status = 0
    end

    -- CENTER TO MAIN 3
    
    if B747.fuel.center_tank.scvg_pump_R1.on == 1 or B747.fuel.center_tank.scvg_pump_R2.on == 1 then
        B747DR_ctr_scvg_R_status = 1
        if simDR_fuel_tank_weight_kg[0] > 0.0 then
            B747DR_ctr_scvg_R_status = 2
        end
    else
        B747DR_ctr_scvg_R_status = 0    
    end

end





----- SYNOPTIC - FUEL JETTISON ----------------------------------------------------------
function B747_fuel_jett_synoptic()

    -- CENTER OJ
    
    if B747.fuel.center_tank.ovrd_jett_pump_L.on == 1
        and B747DR_gen_jett_valve_status == 1
    then
        B747DR_gen_jett_OJctrL_status = 1
    else
        B747DR_gen_jett_OJctrL_status = 0
    end

    
    if B747.fuel.center_tank.ovrd_jett_pump_R.on == 1
        and B747DR_gen_jett_valve_status == 1
    then
        B747DR_gen_jett_OJctrR_status = 1
    else
        B747DR_gen_jett_OJctrR_status = 0
    end

    -- MAIN2 OJ
    
    if (B747.fuel.main2_tank.ovrd_jett_pump_fwd.on == 1 or B747.fuel.main2_tank.ovrd_jett_pump_aft.on == 1)
        and B747DR_gen_jett_valve_status == 1
    then
        B747DR_gen_jett_OJmain2_status = 1
    else
        B747DR_gen_jett_OJmain2_status = 0
    end

     -- MAIN3 OJ
    
    if (B747.fuel.main3_tank.ovrd_jett_pump_fwd.on == 1 or B747.fuel.main3_tank.ovrd_jett_pump_aft.on == 1)
        and B747DR_gen_jett_valve_status == 1
    then
        B747DR_gen_jett_OJmain3_status = 1
    else
        B747DR_gen_jett_OJmain3_status = 0
    end

    -- STABILIZER
    
    if (B747.fuel.stab_tank.xfr_jett_pump_L.on == 1 or B747.fuel.stab_tank.xfr_jett_pump_R.on == 1)
        and B747DR_gen_jett_valve_status == 1
    then
        B747DR_gen_jett_OJstab_status = 1
    else
        B747DR_gen_jett_OJstab_status = 0
    end




    -- MANIFOLD 1 LEFT
    
    if B747DR_gen_jett_OJctrL_status == 1
        or B747DR_gen_jett_OJmain2_status == 1
    then
        B747DR_gen_jett_mfldL1_status = 1
    else
        B747DR_gen_jett_mfldL1_status = 0
    end

    -- MANIFOLD 2LEFT
    
    if B747DR_gen_jett_OJctrL_status == 1
        or B747DR_gen_jett_OJctrR_status == 1
        or B747DR_gen_jett_OJmain2_status == 1
        or B747DR_gen_jett_OJmain3_status == 1
        or B747DR_gen_jett_OJstab_status == 1
    then
        B747DR_gen_jett_mfldL2_status = 1
    else
        B747DR_gen_jett_mfldL2_status = 0
    end

    -- MANIFOLD 3 LEFT
    
    if B747DR_gen_jett_mfldL2_status == 1 or B747DR_gen_jett_Xmfld_status == 1
    then
        B747DR_gen_jett_mfldL3_status = 1
    else
        B747DR_gen_jett_mfldL3_status = 0
    end

    -- MANIFOLD 1 RIGHT
    
    if B747DR_gen_jett_OJctrR_status == 1
        or B747DR_gen_jett_OJmain3_status == 1
    then
        B747DR_gen_jett_mfldR1_status = 1
    else
        B747DR_gen_jett_mfldR1_status = 0
    end

     -- MANIFOLD 2 RIGHT
    
    if B747DR_gen_jett_OJctrL_status == 1
        or B747DR_gen_jett_OJctrR_status == 1
        or B747DR_gen_jett_OJmain2_status == 1
        or B747DR_gen_jett_OJmain3_status == 1
        or B747DR_gen_jett_OJstab_status == 1
    then
        B747DR_gen_jett_mfldR2_status = 1
    else
        B747DR_gen_jett_mfldR2_status = 0
    end

    -- MANIFOLD 3 RIGHT
    
    if B747DR_gen_jett_mfldR2_status == 1 or B747DR_gen_jett_Xmfld_status == 1
    then
        B747DR_gen_jett_mfldR3_status = 1
    else
        B747DR_gen_jett_mfldR3_status = 0
    end

    -- CROSS MANIFOLD
    
    if B747DR_gen_jett_mfldL2_status == 1
        or B747DR_gen_jett_mfldR2_status == 1
        or B747DR_gen_jett_OJstab_status == 1
    then
        B747DR_gen_jett_Xmfld_status = 1
    else
        B747DR_gen_jett_Xmfld_status = 0
    end

end







----- SYNOPTIC - FUEL STANDARD -----------------------------------------------------------
function B747_fuel_std_synoptic()

    -- CROSSFEED MANIFOLD
    B747DR_gen_fuel_XFmfld_status = B747_ternary(
        B747.fuel.main2_tank.ovrd_jett_pump_fwd.on == 1 or
        B747.fuel.main2_tank.ovrd_jett_pump_aft.on == 1 or
        B747.fuel.center_tank.ovrd_jett_pump_L.on == 1 or
        B747.fuel.center_tank.ovrd_jett_pump_R.on == 1 or
        B747.fuel.main3_tank.ovrd_jett_pump_fwd.on == 1 or
        B747.fuel.main3_tank.ovrd_jett_pump_aft.on == 1
        , 1, 0)


    -- OJ PUMP(S) 2
    
    if B747.fuel.main2_tank.ovrd_jett_pump_fwd.on == 1 or B747.fuel.main2_tank.ovrd_jett_pump_aft.on == 1 then
        B747DR_gen_fuel_OJpump2_status = 1
    else
      B747DR_gen_fuel_OJpump2_status = 0
    end

    -- OJ PUMP(S) 3
    
    if B747.fuel.main3_tank.ovrd_jett_pump_fwd.on == 1 or B747.fuel.main3_tank.ovrd_jett_pump_aft.on == 1 then
        B747DR_gen_fuel_OJpump3_status = 1
    else
      B747DR_gen_fuel_OJpump3_status = 0
    end



    ----- XFEED VALVES ------------------------------------------------------------------

    -- VALVE 1 COMMANDED OPEN
    if B747.fuel.engine1.xfeed_vlv.target_pos == 1.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine1.xfeed_vlv.pos < 0.99 then
            B747DR_gen_xfeed_vlv1_status = 0                                -- TRANSITION TO OPEN
        else
            B747DR_gen_xfeed_vlv1_status = 1                                -- OPEN
        end

    -- VALVE 1 COMMANDED CLOSED
    elseif B747.fuel.engine1.xfeed_vlv.target_pos == 0.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine1.xfeed_vlv.pos > 0.01 then
            B747DR_gen_xfeed_vlv1_status = 2                                -- TRANSITION TO CLOSED
        else
            B747DR_gen_xfeed_vlv1_status = 3                                -- CLOSED
        end
    end


    -- VALVE 2 COMMANDED OPEN
    if B747.fuel.engine2.xfeed_vlv.target_pos == 1.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine2.xfeed_vlv.pos < 0.99 then
            B747DR_gen_xfeed_vlv2_status = 0                                -- TRANSITION TO OPEN
        else
            B747DR_gen_xfeed_vlv2_status = 1                                -- OPEN
        end

    -- VALVE 2 COMMANDED CLOSED
    elseif B747.fuel.engine2.xfeed_vlv.target_pos == 0.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine2.xfeed_vlv.pos > 0.01 then
            B747DR_gen_xfeed_vlv2_status = 2                                -- TRANSITION TO CLOSED
        else
            B747DR_gen_xfeed_vlv2_status = 3                                -- CLOSED
        end
    end


    -- VALVE 3 COMMANDED OPEN
    if B747.fuel.engine3.xfeed_vlv.target_pos == 1.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine3.xfeed_vlv.pos < 0.99 then
            B747DR_gen_xfeed_vlv3_status = 0                                -- TRANSITION TO OPEN
        else
            B747DR_gen_xfeed_vlv3_status = 1                                -- OPEN
        end

    -- VALVE 3 COMMANDED CLOSED
    elseif B747.fuel.engine3.xfeed_vlv.target_pos == 0.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine3.xfeed_vlv.pos > 0.01 then
            B747DR_gen_xfeed_vlv3_status = 2                                -- TRANSITION TO CLOSED
        else
            B747DR_gen_xfeed_vlv3_status = 3                                -- CLOSED
        end
    end


    -- VALVE 4 COMMANDED OPEN
    if B747.fuel.engine4.xfeed_vlv.target_pos == 1.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine4.xfeed_vlv.pos < 0.99 then
            B747DR_gen_xfeed_vlv4_status = 0                                -- TRANSITION TO OPEN
        else
            B747DR_gen_xfeed_vlv4_status = 1                                -- OPEN
        end

    -- VALVE 4 COMMANDED CLOSED
    elseif B747.fuel.engine4.xfeed_vlv.target_pos == 0.0 then
        -- POSITION DISAGREE
        if B747.fuel.engine4.xfeed_vlv.pos > 0.01 then
            B747DR_gen_xfeed_vlv4_status = 2                                -- TRANSITION TO CLOSED
        else
            B747DR_gen_xfeed_vlv4_status = 3                                -- CLOSED
        end
    end


end

-- :: ****************************************************************************************
-- :: B744 Tank Manager for Sparky 744 and Default 747-400
-- :: by Garen Evans (@giwiganz) garen.evans@gmail.com
-- :: https://discord.com/channels/713625220568842260/713625220568842263/844535310745731112
-- :: 
-- :: Automaticallly toggles override and crossfeed tanks.
-- :: Exclusively for B744 ICAO
-- ::
-- :: Version 1.0 - February 12, 2021 (initial release)
-- :: Version 1.0.1 - February 23, 2024 (mSparks converted and incorporated to XTLua)
-- ::
-- :: 
-- :: ****************************************************************************************
B747CMD_fuel_overd_pump_fwd_2       = find_command("laminar/B747/button_switch/fuel_overd_pump_fwd_2")
B747CMD_fuel_overd_pump_fwd_3       = find_command("laminar/B747/button_switch/fuel_overd_pump_fwd_3")
B747CMD_fuel_overd_pump_aft_2       = find_command("laminar/B747/button_switch/fuel_overd_pump_aft_2")
B747CMD_fuel_overd_pump_aft_3       = find_command("laminar/B747/button_switch/fuel_overd_pump_aft_3")
B747CMD_fuel_xfeed_vlv_1            = find_command("laminar/B747/button_switch/fuel_xfeed_vlv_1")
B747CMD_fuel_xfeed_vlv_4            = find_command("laminar/B747/button_switch/fuel_xfeed_vlv_4")

function ToggleCrossFeedsOverrides()
    B747CMD_fuel_overd_pump_fwd_2:once()
    B747CMD_fuel_overd_pump_fwd_3:once()
    B747CMD_fuel_overd_pump_aft_2:once()
    B747CMD_fuel_overd_pump_aft_3:once()
    B747CMD_fuel_xfeed_vlv_1:once()
    B747CMD_fuel_xfeed_vlv_4:once()
end

function tank_helper()
    fob = simDR_fuel_tank_weight_kg[0] + simDR_fuel_tank_weight_kg[1] + simDR_fuel_tank_weight_kg[2] + simDR_fuel_tank_weight_kg[3] + simDR_fuel_tank_weight_kg[4] + simDR_fuel_tank_weight_kg[5] + simDR_fuel_tank_weight_kg[6] + simDR_fuel_tank_weight_kg[7]
    fob = math.floor(fob * 2.2046)

    -- if have fuel and all crossfeeds are off, then turn em om
    if(fob > 120000) then
        if(B747DR_gen_xfeed_vlv1_status==3 and B747DR_gen_xfeed_vlv2_status==3 and B747DR_gen_xfeed_vlv3_status==3 and B747DR_gen_xfeed_vlv4_status==3) then
            if(B747.fuel.main2_tank.ovrd_jett_pump_fwd.on==0 
            and B747.fuel.main2_tank.ovrd_jett_pump_aft.on==0 
            and B747.fuel.main3_tank.ovrd_jett_pump_fwd.on==0 
            and B747.fuel.main3_tank.ovrd_jett_pump_aft.on==0) then
                ToggleCrossFeedsOverrides()
            end
        end
    else
        if(B747DR_gen_xfeed_vlv1_status~=3 and B747DR_gen_xfeed_vlv2_status~=3 and B747DR_gen_xfeed_vlv3_status~=3 and B747DR_gen_xfeed_vlv4_status~=3) then
            if(B747.fuel.main2_tank.ovrd_jett_pump_fwd.on~=0 
            and B747.fuel.main2_tank.ovrd_jett_pump_aft.on~=0 
            and B747.fuel.main3_tank.ovrd_jett_pump_fwd.on~=0 
            and B747.fuel.main3_tank.ovrd_jett_pump_aft.on~=0) then
                ToggleCrossFeedsOverrides()
            end
        end
    end

end


----- FUEL JETTISON TIME -----------------------------------------------------------------
function B747_fuel_jettison_time()

    local ttlFuelToJettison = simDR_fueL_tank_weight_total_kg - math.max(12800.0, B747DR_fuel_to_remain_rheo * 1000.0)
    local fuel_jett_valve_flow_factor = (B747.fuel.jett_nozzle_vlv_L.pos * 0.5) + (B747.fuel.jett_nozzle_vlv_R.pos * 0.5)
    local ttlFuelJettisonFlowKgMin = (
        (centerTank_jettison_KgSec_L
        + centerTank_jettison_KgSec_R
        + mainTank2_jettison_KgSec_A
        + mainTank2_jettison_KgSec_B
        + mainTank3_jettison_KgSec_A
        + mainTank3_jettison_KgSec_B) * fuel_jett_valve_flow_factor) * 60.0


    if ttlFuelJettisonFlowKgMin > 0 then
        B747DR_jett_time = ttlFuelToJettison / ttlFuelJettisonFlowKgMin
    else
        B747DR_jett_time = 0
    end

end


function eicas_caution_center_left()
    if B747DR_button_switch_position[52] > 0.95 then
        B747DR_CAS_caution_status[69] = 1
    end
end

function eicas_caution_center_right()
    if B747DR_button_switch_position[53] > 0.95 then
        B747DR_CAS_caution_status[70] = 1
    end
end

----- FUEL SYSTEM EICAS MESSAGES --------------------------------------------------------
function B747_fuel_EICAS_msg()

    -- FUEL TANK-TO-ENGINE
    if B747.fuel.engine1.xfeed_vlv.pos < 0.05
        and B747DR_button_switch_position[64] < 0.05
        and B747DR_button_switch_position[65] < 0.05
        and B747DR_button_switch_position[66] < 0.05
        and B747DR_button_switch_position[67] < 0.05
        and B747.fuel.engine4.xfeed_vlv.pos < 0.05
    then
        fuel_tankToEngine = 1
    else
        fuel_tankToEngine = 0
    end

    -- FUEL JETT SYS
    
    if (simDR_fueL_tank_weight_total_kg < (B747DR_fuel_to_remain_rheo * 1000.0))
        and (B747.fuel.jett_nozzle_vlv_L.pos > 0.95 or B747.fuel.jett_nozzle_vlv_R.pos > 0.95)
    then
        B747DR_CAS_caution_status[31] = 1
    else
      B747DR_CAS_caution_status[31] = 0
    end

    -- FUEL QTY LOW
    
    if simDR_fuel_tank_weight_kg[1] < 900.0
        or simDR_fuel_tank_weight_kg[2] < 900.0
        or simDR_fuel_tank_weight_kg[3] < 900.0
        or simDR_fuel_tank_weight_kg[4] < 900.0
    then
        B747DR_CAS_caution_status[36] = 1
    else
        B747DR_CAS_caution_status[36] = 0
    end

    -- APU FUEL
    
    if (B747.fuel.main2_tank.apu_vlv.pos > 0.95 and B747DR_elec_apu_sel_pos < 0.95)
        or
        (B747.fuel.main2_tank.apu_vlv.pos < 0.05 and B747DR_elec_apu_sel_pos > 0.95)
    then
        B747DR_CAS_advisory_status[15] = 1
    else
        B747DR_CAS_advisory_status[15] = 0
    end

    -- ENG 1 FUEL FILT
    
    if simDR_fuel_filter_block_01== 6 then 
      B747DR_CAS_advisory_status[114] = 1 
    else
      B747DR_CAS_advisory_status[114] = 0
    end

    -- ENG 2 FUEL FILT
    
    if simDR_fuel_filter_block_02== 6 then 
      B747DR_CAS_advisory_status[115] = 1 
    else
      B747DR_CAS_advisory_status[115] = 0
    end

    -- ENG 3 FUEL FILT
    
    if simDR_fuel_filter_block_03== 6 then 
      B747DR_CAS_advisory_status[116] = 1 
    else
      B747DR_CAS_advisory_status[116] = 0
    end

    -- ENG 4 FUEL FILT
    
    if simDR_fuel_filter_block_04== 6 then 
      B747DR_CAS_advisory_status[117] = 1 
    else
      B747DR_CAS_advisory_status[117] = 0
    end

    -- FUEL IMBALANCE
    if fuel_tankToEngine == 1 then

        if math.abs(simDR_fuel_tank_weight_kg[2] - simDR_fuel_tank_weight_kg[3]) > 2720.0
            or math.abs(simDR_fuel_tank_weight_kg[1] - simDR_fuel_tank_weight_kg[4]) > 2720.0
        then
            B747DR_CAS_advisory_status[148] = 1
        end

        if B747DR_CAS_advisory_status[148] == 1
            and
            math.abs(((simDR_fuel_tank_weight_kg[2] + simDR_fuel_tank_weight_kg[3]) - (simDR_fuel_tank_weight_kg[3] + simDR_fuel_tank_weight_kg[4]))) < 450.0
        then
            B747DR_CAS_advisory_status[148] = 0
        end
    end

    -- FUEL IMBAL 1-4
    
    if math.abs(simDR_fuel_tank_weight_kg[1] - simDR_fuel_tank_weight_kg[4]) > 1360.0 then
        B747DR_CAS_advisory_status[149] = 1
    else
        B747DR_CAS_advisory_status[149] = 0
    end

    if B747DR_CAS_advisory_status[149] == 1
        and
        math.abs(simDR_fuel_tank_weight_kg[1] - simDR_fuel_tank_weight_kg[4]) < 450.0
    then
        B747DR_CAS_advisory_status[149] = 1
    end

    -- FUEL IMBAL 2-3
    
    if math.abs(simDR_fuel_tank_weight_kg[2] - simDR_fuel_tank_weight_kg[3]) > 1360.0 then
        B747DR_CAS_advisory_status[150] = 1
    else
        B747DR_CAS_advisory_status[150] = 0
    end

    if B747DR_CAS_advisory_status[150] == 1
        and
        math.abs(simDR_fuel_tank_weight_kg[2] - simDR_fuel_tank_weight_kg[3]) < 450.0
    then
        B747DR_CAS_advisory_status[150] = 1
    end

    -- FUEL OVRD CTR L
    
    if (simDR_fuel_tank_weight_kg[0] > 7700.0 and simDR_all_wheels_on_ground == 1 and B747DR_button_switch_position[52] < 0.05)
        or
        (simDR_fuel_tank_weight_kg[0] > 1800.0 and simDR_all_wheels_on_ground == 0 and B747DR_button_switch_position[52] < 0.05)
    then
        B747DR_CAS_advisory_status[153] = 1
    else
        B747DR_CAS_advisory_status[153] = 0
    end

    -- FUEL OVRD CTR R
    
    if (simDR_fuel_tank_weight_kg[0] > 7700.0 and simDR_all_wheels_on_ground == 1 and B747DR_button_switch_position[53] < 0.05)
        or
        (simDR_fuel_tank_weight_kg[0] > 1800.0 and simDR_all_wheels_on_ground == 0 and B747DR_button_switch_position[53] < 0.05)
    then
        B747DR_CAS_advisory_status[154] = 1
    else
        B747DR_CAS_advisory_status[154] = 0
    end

    -- FUEL OVRD 2 AFT
    
    if fuel_tankToEngine == 0 and B747DR_button_switch_position[66] < 0.05 then 
      B747DR_CAS_advisory_status[155] = 1
    else
      B747DR_CAS_advisory_status[155] = 0
    end

    -- FUEL OVRD 3 AFT
    
    if fuel_tankToEngine == 0 and B747DR_button_switch_position[67] < 0.05 then 
      B747DR_CAS_advisory_status[156] = 1
    else
      B747DR_CAS_advisory_status[156] = 0
    end

    -- FUEL OVRD 2 FWD
    
    if fuel_tankToEngine == 0 and B747DR_button_switch_position[64] < 0.05 then 
      B747DR_CAS_advisory_status[157] = 1
    else
      B747DR_CAS_advisory_status[157] = 0
    end

    -- FUEL OVRD 3 FWD
    
    if fuel_tankToEngine == 0 and B747DR_button_switch_position[65] < 0.05 then 
      B747DR_CAS_advisory_status[158] = 1 
    else
      B747DR_CAS_advisory_status[158] = 0
    end

    -- FUEL LOW CTR L
    if B747DR_CAS_caution_status[37] == 0 and B747DR_CAS_caution_status[69] == 0 then
        if B747DR_button_switch_position[52] > 0.95
            and simDR_fuel_tank_weight_kg[0] <= 1300.0
        then
            B747DR_CAS_advisory_status[302] = 1 
            if is_timer_scheduled(eicas_caution_center_left)==false then
                run_after_time(eicas_caution_center_left,60)
            end
        else
            B747DR_CAS_advisory_status[302] = 0
        end
    elseif B747DR_button_switch_position[52] < 0.95 or simDR_fuel_tank_weight_kg[0] >= 1300.0 then
        B747DR_CAS_advisory_status[302] = 0
        B747DR_CAS_caution_status[69] = 0
    else
        B747DR_CAS_advisory_status[302] = 0

    end    
    -- FUEL LOW CTR R
    if B747DR_CAS_caution_status[37] == 0 and B747DR_CAS_caution_status[70] == 0 then
        if B747DR_button_switch_position[53] > 0.95
            and simDR_fuel_tank_weight_kg[0] <= 1300.0
        then
            B747DR_CAS_advisory_status[303] = 1
            if is_timer_scheduled(eicas_caution_center_right)==false then
                run_after_time(eicas_caution_center_right,60)
            end
            
        else
            B747DR_CAS_advisory_status[303] = 0
        end
    elseif B747DR_button_switch_position[53] < 0.95 or simDR_fuel_tank_weight_kg[0] >= 1300.0 then
        B747DR_CAS_advisory_status[303] = 0
        B747DR_CAS_caution_status[70] = 0
    else
        B747DR_CAS_advisory_status[303] = 0
    end  
    -- FUEL PMP STAB L
    
    if B747DR_CAS_caution_status[37] == 0 then
        if (B747DR_button_switch_position[54] > 0.95 and simDR_all_wheels_on_ground == 1)
            or (B747DR_button_switch_position[54] < 0.05 and simDR_fuel_tank_weight_kg[7] > 500.0 and simDR_all_wheels_on_ground == 0)
        then
            B747DR_CAS_advisory_status[159] = 1
        else
            B747DR_CAS_advisory_status[159] = 0
        end
    else
      B747DR_CAS_advisory_status[159] = 0
    end

    -- FUEL PMP STAB R
    
    if B747DR_CAS_caution_status[37] == 0 then
        if (B747DR_button_switch_position[55] > 0.95 and simDR_all_wheels_on_ground == 1)
            or (B747DR_button_switch_position[55] < 0.05 and simDR_fuel_tank_weight_kg[7] > 500.0 and simDR_all_wheels_on_ground == 0)
        then
            B747DR_CAS_advisory_status[160] = 1
  else
        B747DR_CAS_advisory_status[160] = 0
        end
    else
      B747DR_CAS_advisory_status[160] = 0
    end

    -- FUEL PUMP 1 AFT
   
    if B747DR_CAS_caution_status[32] == 0 then
        if B747.fuel.main1_tank.main_pump_aft.on > 0 and simDR_fuel_tank_weight_kg[1] <= 10.0 then 
    B747DR_CAS_advisory_status[161] = 1 
  else
     B747DR_CAS_advisory_status[161] = 0
  end
    else
       B747DR_CAS_advisory_status[161] = 0
    end

    -- FUEL PUMP 2 AFT
    
    if B747DR_CAS_caution_status[33] == 0 then
        if B747.fuel.main1_tank.main_pump_aft.on > 0 and simDR_fuel_tank_weight_kg[2] <= 10.0 then 
    B747DR_CAS_advisory_status[162] = 1 
  else
    B747DR_CAS_advisory_status[162] = 0
  end
    else
      B747DR_CAS_advisory_status[162] = 0
    end

    -- FUEL PUMP 3 AFT
    
    if B747DR_CAS_caution_status[34] == 0 then
        if B747.fuel.main1_tank.main_pump_aft.on > 0 and simDR_fuel_tank_weight_kg[3] <= 10.0 then 
    B747DR_CAS_advisory_status[163] = 1
  else
    B747DR_CAS_advisory_status[163] = 0
  end
    else
      B747DR_CAS_advisory_status[163] = 0
    end

    -- FUEL PUMP 4 AFT
    
    if B747DR_CAS_caution_status[35] == 0 then
        if B747.fuel.main1_tank.main_pump_aft.on > 0 and simDR_fuel_tank_weight_kg[4] <= 10.0 then 
    B747DR_CAS_advisory_status[164] = 1 
  else
    B747DR_CAS_advisory_status[164] = 0
  end
    else
      B747DR_CAS_advisory_status[164] = 0
    end

    -- FUEL PUMP 1 FWD
    
    if B747DR_CAS_caution_status[32] == 0 then
        if B747.fuel.main1_tank.main_pump_fwd.on > 0 and simDR_fuel_tank_weight_kg[1] <= 10.0 then 
    B747DR_CAS_advisory_status[165] = 1 
  else
    B747DR_CAS_advisory_status[165] = 0
  end
    else
      B747DR_CAS_advisory_status[165] = 0
    end

    -- FUEL PUMP 2 FWD
    
    if B747DR_CAS_caution_status[33] == 0 then
        if B747.fuel.main1_tank.main_pump_fwd.on > 0 and simDR_fuel_tank_weight_kg[2] <= 10.0 then 
    B747DR_CAS_advisory_status[166] = 1
  else
    B747DR_CAS_advisory_status[166] = 0
  end
    else
      B747DR_CAS_advisory_status[166] = 0
    end

    -- FUEL PUMP 3 FWD
    
    if B747DR_CAS_caution_status[34] == 0 then
        if B747.fuel.main1_tank.main_pump_fwd.on > 0 and simDR_fuel_tank_weight_kg[3] <= 10.0 then 
    B747DR_CAS_advisory_status[167] = 1 
  else
    B747DR_CAS_advisory_status[167] = 0
  end
    else
      B747DR_CAS_advisory_status[167] = 0
    end

    -- FUEL PUMP 4 FWD
    
    if B747DR_CAS_caution_status[35] == 0 then
        if B747.fuel.main1_tank.main_pump_fwd.on > 0 and simDR_fuel_tank_weight_kg[4] <= 10.0 then 
    B747DR_CAS_advisory_status[168] = 1
  else
    B747DR_CAS_advisory_status[168] = 0
  end
    else
      B747DR_CAS_advisory_status[168] = 0
    end
    
    -- >FUEL TANK/ENG
    if fuel_tankToEngine==1 or B747DR_fuel_jettison_sel_dial_pos > 0 then
        B747DR_CAS_advisory_status[171] = 0
    else
        
        if ((simDR_fuel_tank_weight_kg[2] <= simDR_fuel_tank_weight_kg[1]) or (simDR_fuel_tank_weight_kg[3] <= simDR_fuel_tank_weight_kg[4]))
            and (B747.fuel.engine1.xfeed_vlv.pos > 0.95 or B747.fuel.engine4.xfeed_vlv.pos > 0.95)
        then
            B747DR_CAS_advisory_status[171] = 1
  else
      B747DR_CAS_advisory_status[171] = 0
        end
    end

    -- >FUEL TEMP LOW
    
    if B747DR_fuel_temperature < -37.0 then 
      B747DR_CAS_advisory_status[172] = 1 
    else
      B747DR_CAS_advisory_status[172] = 0
    end

    -- >FUEL XFER 1+4
    
    if B747DR_button_switch_position[43] > 0.95 then
        if simDR_all_wheels_on_ground == 1
            or
            (simDR_all_wheels_on_ground == 0
            and
            ((simDR_fuel_tank_weight_kg[2] + simDR_fuel_tank_weight_kg[3]) > (simDR_fuel_tank_weight_kg[1] + simDR_fuel_tank_weight_kg[4])))
        then
            B747DR_CAS_advisory_status[179] = 1
  else
    B747DR_CAS_advisory_status[179] = 0
        end
    else
      B747DR_CAS_advisory_status[179] = 0
    end

    -- >JETT NOZ ON
   
    if B747.fuel.jett_nozzle_vlv_L.pos > 0.0 and B747.fuel.jett_nozzle_vlv_R.pos > 0.0 then
        B747DR_CAS_advisory_status[235] = 1
    else
       B747DR_CAS_advisory_status[235] = 0
    end

    -- >JETT NOZ ON L
    
    if B747DR_CAS_advisory_status[235] == 0 then
        if B747.fuel.jett_nozzle_vlv_L.pos > 0.0 then 
    B747DR_CAS_advisory_status[236] = 1 
  else
    B747DR_CAS_advisory_status[236] = 0
  end
    else
      B747DR_CAS_advisory_status[236] = 0
    end

    -- >JETT NOZ ON R
    
    if B747DR_CAS_advisory_status[235] == 0 then
        if B747.fuel.jett_nozzle_vlv_R.pos > 0.0 then 
    B747DR_CAS_advisory_status[237] = 1
  else
    B747DR_CAS_advisory_status[237] = 0
  end
    else
      B747DR_CAS_advisory_status[237] = 0
    end

    -- >SCAV PUMP ON
    
    if simDR_all_wheels_on_ground == 1 then
        if B747.fuel.center_tank.scvg_pump_L1.on > 0.0
            or B747.fuel.center_tank.scvg_pump_L2.on > 0.0
            or B747.fuel.center_tank.scvg_pump_R1.on > 0.0
            or B747.fuel.center_tank.scvg_pump_R2.on > 0.0
        then
            B747DR_CAS_advisory_status[263] = 1
  else
    B747DR_CAS_advisory_status[263] = 0
        end
    else
      B747DR_CAS_advisory_status[263] = 0
    end

    -- >X FEED CONFIG
    
    if ((B747.fuel.engine1.xfeed_vlv.pos < 0.05 or B747.fuel.engine4.xfeed_vlv.pos < 0.05)
        and
        ((simDR_fuel_tank_weight_kg[3] - simDR_fuel_tank_weight_kg[4]) > 100.0
        or
        simDR_fuel_tank_weight_kg[2] - simDR_fuel_tank_weight_kg[1] > 100.0))

        or

        ((B747.fuel.engine2.xfeed_vlv.pos < 0.05 or B747.fuel.engine3.xfeed_vlv.pos < 0.05)
        and
        (simDR_wing_flap1_deg[0] < 9.9 or simDR_wing_flap1_deg[0] > 21.0))
    then
        B747DR_CAS_advisory_status[299] = 1
    else
      B747DR_CAS_advisory_status[299] = 0
    end

end

--Marauder28
function B747_fuel_balance_check()
  --Initial check to ensure that this balance function only runs once
  if simDR_fuel_totalizer_kg ~= simDR_fueL_tank_weight_total_kg then
    return
  end
  
  --Determine amount for each tank based on existing fuel and load order.
  --Load order is:
  --1) Even distribution in Main1, Main2, Main3, Main4 (Wing)
  --3) Reserve 5 & Reserve 6 (Wing)
  --4) Center 0
  --5) Horizontal Stabilizer 7

  local overage = 0
  
  --Use and rebalance any existing fuel into their proper tanks before starting the refueling process
  --Start by placing all fuel into the first 2 main tanks and then take overages and place it in tanks in the order above
  simDR_fuel_tank_weight_kg[1] = simDR_fueL_tank_weight_total_kg / 4
  simDR_fuel_tank_weight_kg[4] = simDR_fueL_tank_weight_total_kg / 4
  simDR_fuel_tank_weight_kg[2] = simDR_fueL_tank_weight_total_kg / 4
  simDR_fuel_tank_weight_kg[3] = simDR_fueL_tank_weight_total_kg / 4

  --print("Initial Split Main1 = "..simDR_fuel_tank_weight_kg[1])
  --print("Initial Split Main4 = "..simDR_fuel_tank_weight_kg[4])
  --print("Initial Split Main2 = "..simDR_fuel_tank_weight_kg[2])
  --print("Initial Split Main3 = "..simDR_fuel_tank_weight_kg[3])
  
  simDR_fuel_tank_weight_kg[5] = 0
  simDR_fuel_tank_weight_kg[6] = 0
  simDR_fuel_tank_weight_kg[7] = 0
  simDR_fuel_tank_weight_kg[0] = 0
  
  --Move overages from Main1 to Main2
  if simDR_fuel_tank_weight_kg[1] > B747.fuel.main1_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[1] - B747.fuel.main1_tank.capacity
    simDR_fuel_tank_weight_kg[1] = B747.fuel.main1_tank.capacity
    simDR_fuel_tank_weight_kg[2] = simDR_fuel_tank_weight_kg[2] + overage
    --print("Main1 OVERAGE --> Main2 = "..overage)
    overage = 0
    --print("Bal Main1 = "..simDR_fuel_tank_weight_kg[1])
  end
  
  --Move overages from Main4 to Main3
  if simDR_fuel_tank_weight_kg[4] > B747.fuel.main4_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[4] - B747.fuel.main4_tank.capacity
    simDR_fuel_tank_weight_kg[4] = B747.fuel.main4_tank.capacity
    simDR_fuel_tank_weight_kg[3] = simDR_fuel_tank_weight_kg[3] + overage
    --print("Main4 OVERAGE --> Main3 = "..overage)
    overage = 0
    --print("Bal Main4 = "..simDR_fuel_tank_weight_kg[4])
  end

  --Move overages from Main2 to Reserve5
  if simDR_fuel_tank_weight_kg[2] > B747.fuel.main2_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[2] - B747.fuel.main2_tank.capacity
    simDR_fuel_tank_weight_kg[2] = B747.fuel.main2_tank.capacity
    simDR_fuel_tank_weight_kg[5] = overage
    --print("Main2 OVERAGE --> Rsv5 = "..overage)
    overage = 0
    --print("Bal Main2 = "..simDR_fuel_tank_weight_kg[2])
  end

  --Move overages from Main3 to Reserve6
  if simDR_fuel_tank_weight_kg[3] > B747.fuel.main3_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[3] - B747.fuel.main3_tank.capacity
    simDR_fuel_tank_weight_kg[3] = B747.fuel.main3_tank.capacity
    simDR_fuel_tank_weight_kg[6] = overage
    --print("Main3 OVERAGE --> Rsv6 = "..overage)
    overage = 0
    --print("Bal Main3 = "..simDR_fuel_tank_weight_kg[3])
  end

  --Move overages from Reserve5 to Center0 (Reserve5 is also known as res2 in previous code)
  if simDR_fuel_tank_weight_kg[5] > B747.fuel.res2_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[5] - B747.fuel.res2_tank.capacity
    simDR_fuel_tank_weight_kg[5] = B747.fuel.res2_tank.capacity
    simDR_fuel_tank_weight_kg[0] = overage
    --print("Rsv5 OVERAGE --> Center0 = "..overage)
    overage = 0
    --print("Bal RSV5 = "..simDR_fuel_tank_weight_kg[5])
  end

  --Move overages from Reserve6 to Center0 (Reserve6 is also known as res3 in previous code)
  if simDR_fuel_tank_weight_kg[6] > B747.fuel.res3_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[6] - B747.fuel.res3_tank.capacity
    simDR_fuel_tank_weight_kg[6] = B747.fuel.res3_tank.capacity
    simDR_fuel_tank_weight_kg[0] = simDR_fuel_tank_weight_kg[0] + overage
    --print("Rsv6 OVERAGE --> Center0 = "..overage)
    overage = 0
    --print("Bal RSV6 = "..simDR_fuel_tank_weight_kg[6])
  end

  --Move overages from Center0 to Stab7
  if simDR_fuel_tank_weight_kg[0] > B747.fuel.center_tank.capacity then
    overage = simDR_fuel_tank_weight_kg[0] - B747.fuel.center_tank.capacity
    simDR_fuel_tank_weight_kg[0] = B747.fuel.center_tank.capacity
    simDR_fuel_tank_weight_kg[7] = overage
    --print("Center0 OVERAGE --> Stab7 = "..overage)
    overage = 0
    --print("Bal CENTER0 = "..simDR_fuel_tank_weight_kg[0])
  end

  --print("Main1 = "..simDR_fuel_tank_weight_kg[1])
  --print("Main4 = "..simDR_fuel_tank_weight_kg[4])
  --print("Main2 = "..simDR_fuel_tank_weight_kg[2])
  --print("Main3 = "..simDR_fuel_tank_weight_kg[3])
  --print("Rsv5 = "..simDR_fuel_tank_weight_kg[5])
  --print("Rsv6 = "..simDR_fuel_tank_weight_kg[6])
  --print("Center0 = "..simDR_fuel_tank_weight_kg[0])
  --print("Stab7 = "..simDR_fuel_tank_weight_kg[7])

end
--Marauder28

function B747_refueling()
  if B747DR_refuel<=0.0 then
  --Marauder28
  --Set the totalizer to the current fuel amount after refueling
  simDR_fuel_totalizer_kg = simDR_fueL_tank_weight_total_kg
  --Marauder28

  return
  end
  

  local fuelIn=math.min(100*fuel_update_rate,B747DR_refuel)
  --print("sending fuel "..fuelIn)
  
  --Marauder28
  B747_fuel_balance_check()  --Ensure existing fuel is ordered in the tanks correctly before refueling

  --Now start adding fuel
  --Load order is:
  --1) Even distribution in Main1, Main2, Main3, Main4 (Wing)  e.g. BLOCK FUEL / 4
  --3) Reserve 5 & Reserve 6 (Wing)
  --4) Center 0
  --5) Horizontal Stabilizer 7
  
  --Finish filling Main1 - Main4 First
  if simDR_fuel_tank_weight_kg[1] < B747.fuel.main1_tank.capacity then
    B747DR_refuel = B747DR_refuel - fuelIn
    simDR_fuel_tank_weight_kg[1] = simDR_fuel_tank_weight_kg[1] + fuelIn
  end
  if simDR_fuel_tank_weight_kg[4] < B747.fuel.main4_tank.capacity then
    B747DR_refuel = B747DR_refuel - fuelIn
    simDR_fuel_tank_weight_kg[4] = simDR_fuel_tank_weight_kg[4] + fuelIn
  end
  if simDR_fuel_tank_weight_kg[2] < B747.fuel.main2_tank.capacity then
    B747DR_refuel = B747DR_refuel - fuelIn
    simDR_fuel_tank_weight_kg[2] = simDR_fuel_tank_weight_kg[2] + fuelIn
  end
  if simDR_fuel_tank_weight_kg[3] < B747.fuel.main3_tank.capacity then
    B747DR_refuel = B747DR_refuel - fuelIn
    simDR_fuel_tank_weight_kg[3] = simDR_fuel_tank_weight_kg[3] + fuelIn
  end
  
  --Now deal with overflows in Main1 - Main4 using Reserve5 & Reserve6 (known as Res2 & Res3 in other code)
  if simDR_fuel_tank_weight_kg[1] == B747.fuel.main1_tank.capacity and 
    simDR_fuel_tank_weight_kg[4] == B747.fuel.main4_tank.capacity then
    if simDR_fuel_tank_weight_kg[2] < B747.fuel.main2_tank.capacity then
      B747DR_refuel = B747DR_refuel - fuelIn
      simDR_fuel_tank_weight_kg[2] = simDR_fuel_tank_weight_kg[2] + fuelIn
    elseif simDR_fuel_tank_weight_kg[5] < B747.fuel.res2_tank.capacity then
      B747DR_refuel = B747DR_refuel - fuelIn
      simDR_fuel_tank_weight_kg[5] = simDR_fuel_tank_weight_kg[5] + fuelIn
    end
    if simDR_fuel_tank_weight_kg[3] < B747.fuel.main3_tank.capacity then
      B747DR_refuel = B747DR_refuel - fuelIn
      simDR_fuel_tank_weight_kg[3] = simDR_fuel_tank_weight_kg[3] + fuelIn
    elseif simDR_fuel_tank_weight_kg[6] < B747.fuel.res3_tank.capacity then
      B747DR_refuel = B747DR_refuel - fuelIn
      simDR_fuel_tank_weight_kg[6] = simDR_fuel_tank_weight_kg[6] + fuelIn
    end   
  end
  
  --Reserve5 & Reserve6 are full so move on to Center 0
  if simDR_fuel_tank_weight_kg[5] == B747.fuel.res2_tank.capacity and 
    simDR_fuel_tank_weight_kg[6] == B747.fuel.res3_tank.capacity then
    if simDR_fuel_tank_weight_kg[0] < B747.fuel.center_tank.capacity then
      B747DR_refuel = B747DR_refuel - fuelIn
      simDR_fuel_tank_weight_kg[0] = simDR_fuel_tank_weight_kg[0] + fuelIn
    elseif simDR_fuel_tank_weight_kg[7] < B747.fuel.stab_tank.capacity then
      B747DR_refuel = B747DR_refuel - fuelIn
      simDR_fuel_tank_weight_kg[7] = simDR_fuel_tank_weight_kg[7] + fuelIn
    end
  end
  
  -- Don't overfill
  if simDR_fuel_tank_weight_kg[7] == B747.fuel.stab_tank.capacity then
    B747DR_refuel = 0
  end

end



----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_fuel_monitor_AI()

    if B747DR_init_fuel_CD == 1 then
        B747_set_fuel_all_modes()
        B747_set_fuel_CD()
        B747DR_init_fuel_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_fuel_all_modes()

  B747DR_init_fuel_CD = 0
    B747DR_fuel_to_remain_rheo = 9.6
    B747DR_fuel_jettison_sel_dial_pos = 0

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_fuel_CD()

    --run_after_time(startFuelProcessing, 10.0)                                        -- DELAYED FUEL PROCESSING

    -- TURN OFF THE FUEL CONTROL VALVES
    --[[if B747DR_fuel_control_toggle_switch_pos[0] > 0.5 then B747CMD_fuel_control_switch1:once() end
    if B747DR_fuel_control_toggle_switch_pos[1] > 0.5 then B747CMD_fuel_control_switch2:once() end
    if B747DR_fuel_control_toggle_switch_pos[2] > 0.5 then B747CMD_fuel_control_switch3:once() end
    if B747DR_fuel_control_toggle_switch_pos[3] > 0.5 then B747CMD_fuel_control_switch4:once() end]]--
    for i = 0, NUM_FUEL_TOGGLE_SW-1 do
        B747_fuel_control_toggle_sw_pos_target[i] = 0
    end
end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_fuel_ER()
  
    -- MANUALLY SET FUEL PROCESSING TO ALLOW FOR UI "ENGINES RUNNING" OPTION
    engineHasFuelProcessing = 0                                                     -- DO NOT ALLOW FUEL PROCESSING
    for i = 0, 3 do
  --print("engine has fuel "..i)
        simDR_engine_has_fuel[i] = 1                                                -- FORCE "HAS FUEL" TO "ON"
    end
    --run_after_time(startFuelProcessing, 10.0)                                        -- DELAYED FUEL PROCESSING

    B747_fuel_control_toggle_sw_pos_target[0] = 1.0
    B747DR_fuel_control_toggle_switch_pos[0] = 1.0

    B747_fuel_control_toggle_sw_pos_target[1] = 1.0
    B747DR_fuel_control_toggle_switch_pos[1] = 1.0

    B747_fuel_control_toggle_sw_pos_target[2] = 1.0
    B747DR_fuel_control_toggle_switch_pos[2] = 1.0

    B747_fuel_control_toggle_sw_pos_target[3] = 1.0
    B747DR_fuel_control_toggle_switch_pos[3] = 1.0
  
end

dofile("json/json.lua")

--Simulator Config Options
simConfigData = {}
if string.len(B747DR_simconfig_data) > 1 then
  simConfigData["data"] = json.decode(B747DR_simconfig_data)
else
  simConfigData["data"] = json.decode("[]")
end

-- FUEL DISPLAY UNITS CALCULATION
--[[
* Determine the current selected display units (from the Maintenance page of the FMC)
* and use a multiplication factor to convert KGS to LBS if needed.  This will be stored
* in a dataref that is used on the 3D display panel for the upper and lower EICAS to
* display the fuel quantities in the correct units.
--]]
function B747_calculate_fuel_display_units ()
	local fuel_calculation_factor = 1 -- Initially set to 1 (i.e. KGS) unless LBS is selected
	local x = 0
	
	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		fuel_calculation_factor = simConfigData["data"].SIM.kgs_to_lbs
	end
	
	B747DR_fuel_total_display_qty = simDR_fueL_tank_weight_total_kg * fuel_calculation_factor
	
	B747DR_fuel_preselect = B747DR_fuel_preselect_temp * fuel_calculation_factor

	for x = 0, 7 do
		B747DR_fuel_tank_display_qty[x] = simDR_fuel_tank_weight_kg[x] * fuel_calculation_factor
	end
	
	-- Determine fuel flow rate for display on EICAS based on fuel calculation factor
	for x = 0, 3 do
		B747DR_fuel_flow_sec_display[x] = simDR_eng_fuel_flow_kg_sec[x] * fuel_calculation_factor
	end

	-- Set correct fuel units displayed on EICAS
	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		B747DR_fuel_display_units_eicas = 1
	else
		B747DR_fuel_display_units_eicas = 0
	end

end





----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_fuel()
    print("B747_flight_start_fuel")
    engineHasFuelProcessing = 0
    startedRefil=0

    lastTotalFuel=simDR_fuel_tank_weight_total_kg
    for i=0,7,1 do
        lastFuelLevels[i]=simDR_fuel_tank_weight_kg[i]
    end
    -- ALL MODES ------------------------------------------------------------------------
    run_at_interval(B747_fuel_tank_levels, fuel_update_rate)
  
    B747_set_fuel_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_fuel_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

    B747_set_fuel_ER()

    end
  
end





--*************************************************************************************--
--**                          EVENT CALLBACKS                        **--
--*************************************************************************************--

function aircraft_load()

    simDR_override_fuel_system = 1
    --run_after_time(startFuelProcessing, 20.0)
end

function aircraft_unload()
   
    simDR_override_fuel_system = 0

end

function flight_start() 

    B747_flight_start_fuel()

end

--function flight_crash() end
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end
--[[function B747_engine_has_fuel()
    if engineHasFuelProcessing == 1 then
        simDR_engine_has_fuel[0] = B747_ternary((B747DR_gen_fuel_engine1_status > 0 and B747.fuel.spar_vlv1.pos > 0 and B747DR_engine_fuel_valve_pos[0] > 0), 1, 0)
        simDR_engine_has_fuel[1] = B747_ternary((B747DR_gen_fuel_engine2_status > 0 and B747.fuel.spar_vlv2.pos > 0 and B747DR_engine_fuel_valve_pos[1] > 0), 1, 0)
        simDR_engine_has_fuel[2] = B747_ternary((B747DR_gen_fuel_engine3_status > 0 and B747.fuel.spar_vlv3.pos > 0 and B747DR_engine_fuel_valve_pos[2] > 0), 1, 0)
        simDR_engine_has_fuel[3] = B747_ternary((B747DR_gen_fuel_engine4_status > 0 and B747.fuel.spar_vlv4.pos > 0 and B747DR_engine_fuel_valve_pos[3] > 0), 1, 0)
    end

end]]
debug_fuel     = deferred_dataref("laminar/B747/debug/fuel", "number")
function before_physics()
    if debug_fuel>0 then return end

    B747_engine_fuel_source()
    B747_engine_has_fuel()
end
local setSimConfig=false
function hasSimConfig()
	if B747DR_newsimconfig_data==1 then
		if string.len(B747DR_simconfig_data) > 1 then
			simConfigData["data"] = json.decode(B747DR_simconfig_data)
			setSimConfig=true
		else
			return false
		end
	end
	return setSimConfig
end
function after_physics()
    collectgarbage("collect")
    if hasSimConfig()==false then return end
    local onGround=simDR_all_wheels_on_ground
    if debug_fuel>11 then return end
    B747_fuel_pump_control()
    if debug_fuel>10 then return end
    B747_fuel_valve_control()
    if debug_fuel>9 then return end
    B747_fuel_valve_animation()
    if debug_fuel>8 then return end
    B747_fuel_flow_rate()
    if debug_fuel>7 then return end
    B747_fuel_temp()
    if debug_fuel>6 then return end
    B747_fuel_jettison_time()
    if debug_fuel>5 then return end
    B747_fuel_std_synoptic()
    if debug_fuel>4 then return end
    B747_fuel_xfr_synoptic()
    if debug_fuel>3 then return end
    B747_fuel_jett_synoptic()
    if debug_fuel>2 then return end
    B747_fuel_toggle_switch_animation()
    if debug_fuel>1 then return end
    B747_fuel_EICAS_msg()
    --auto tank to engine
    if simConfigData["data"].SIM.auto_fuel_mgmt =="YES" then tank_helper() end

    if debug_fuel>0 then return end
    B747_fuel_monitor_AI()
    if engineHasFuelProcessing==1 then
        B747_refueling()
    end
    
    
   --print(simDR_eng_fuel_flow_kg_sec[0] .. " " .. simDR_eng_fuel_flow_kg_sec[1] .. " " .. simDR_eng_fuel_flow_kg_sec[2] .. " " .. simDR_eng_fuel_flow_kg_sec[3])
--   print("after" .. simDR_fuel_tank_weight_kg[0] .. " " .. simDR_fuel_tank_weight_kg[1].. " " .. simDR_fuel_tank_weight_kg[2].. " " .. 
--       simDR_fuel_tank_weight_kg[3].. " " .. simDR_fuel_tank_weight_kg[4].. " " .. simDR_fuel_tank_weight_kg[5].. " " .. 
--       simDR_fuel_tank_weight_kg[6].. " " .. simDR_fuel_tank_weight_kg[7])

 

  --Display Fuel Units
  B747_calculate_fuel_display_units()
end

--function after_replay() end



