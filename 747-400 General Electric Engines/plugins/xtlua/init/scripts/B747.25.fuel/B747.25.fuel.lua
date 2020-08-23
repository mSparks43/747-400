--[[
*****************************************************************************************
* Program Script Name	:	B747.25.fuel
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2016-04-26	0.01a				Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED	        *
*****************************************************************************************
--]]


--*************************************************************************************--
--** 					              XLUA GLOBALS              				     **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]


--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

NUM_FUEL_TOGGLE_SW = 4

function null_command(phase, duration)
end
--replace create_command
function deferred_command(name,desc,nilFunc)
	c = XLuaCreateCommand(name,desc)
	--print("Deferred command: "..name)
	--XLuaReplaceCommand(c,null_command)
	return nil --make_command_obj(c)
end
--replace create_dataref
function deferred_dataref(name,type,notifier)
	--print("Deffereed dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end

--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--

B747 = {}
B747.fuel = {}

-- CREATE FUEL TANK TABLES
local tankName = {"center_tank", "main1_tank", "main2_tank", "main3_tank", "main4_tank", "stab_tank", "res2_tank", "res3_tank"}
for _, tank_name in ipairs(tankName) do
    B747.fuel[tank_name] = {}
end

B747.fuel.engine1 = {}
B747.fuel.engine2 = {}
B747.fuel.engine3 = {}
B747.fuel.engine4 = {}

-- PUMPS
B747.fuel.center_tank.ovrd_jett_pump_L 	= {}
B747.fuel.center_tank.ovrd_jett_pump_R 	= {}
B747.fuel.center_tank.scvg_pump_L1		= {}
B747.fuel.center_tank.scvg_pump_L2		= {}
B747.fuel.center_tank.scvg_pump_R1		= {}
B747.fuel.center_tank.scvg_pump_R2		= {}

B747.fuel.main1_tank.main_pump_fwd		= {}
B747.fuel.main1_tank.main_pump_aft		= {}

B747.fuel.main2_tank.main_pump_fwd		= {}
B747.fuel.main2_tank.main_pump_aft		= {}
B747.fuel.main2_tank.ovrd_jett_pump_fwd	= {}
B747.fuel.main2_tank.ovrd_jett_pump_aft	= {}
B747.fuel.main2_tank.apu_dc_pump		= {}

B747.fuel.main3_tank.main_pump_fwd		= {}
B747.fuel.main3_tank.main_pump_aft		= {}
B747.fuel.main3_tank.ovrd_jett_pump_fwd	= {}
B747.fuel.main3_tank.ovrd_jett_pump_aft	= {}

B747.fuel.main4_tank.main_pump_fwd		= {}
B747.fuel.main4_tank.main_pump_aft		= {}

B747.fuel.stab_tank.xfr_jett_pump_L		= {}
B747.fuel.stab_tank.xfr_jett_pump_R		= {}

    B747.fuel.center_tank.ovrd_jett_pump_L.on		= deferred_dataref("laminar/B747/fuel/center_tank/ovrd_jett_pump_L_on", "number")
    B747.fuel.center_tank.ovrd_jett_pump_R.on		= deferred_dataref("laminar/B747/fuel/center_tank/ovrd_jett_pump_R_on", "number")
    B747.fuel.center_tank.scvg_pump_L1.on			= deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_L1_on", "number")
    B747.fuel.center_tank.scvg_pump_L2.on			= deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_L2_on", "number")
    B747.fuel.center_tank.scvg_pump_R1.on			= deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_R1_on", "number")
    B747.fuel.center_tank.scvg_pump_R2.on			= deferred_dataref("laminar/B747/fuel/center_tank/scvg_pump_R2_on", "number")

    B747.fuel.main1_tank.main_pump_fwd.on			= deferred_dataref("laminar/B747/fuel/main1_tank/main_pump_fwd_on", "number")
    B747.fuel.main1_tank.main_pump_aft.on			= deferred_dataref("laminar/B747/fuel/main1_tank/main_pump_aft_on", "number")

    B747.fuel.main2_tank.main_pump_fwd.on			= deferred_dataref("laminar/B747/fuel/main2_tank/main_pump_fwd_on", "number")
    B747.fuel.main2_tank.main_pump_aft.on			= deferred_dataref("laminar/B747/fuel/main2_tank/main_pump_aft_on", "number")
    B747.fuel.main2_tank.ovrd_jett_pump_fwd.on	    = deferred_dataref("laminar/B747/fuel/main2_tank/ovrd_jett_pump_fwd_on", "number")
    B747.fuel.main2_tank.ovrd_jett_pump_aft.on	    = deferred_dataref("laminar/B747/fuel/main2_tank/ovrd_jett_pump_aft_on", "number")
    B747.fuel.main2_tank.apu_dc_pump.on			    = deferred_dataref("laminar/B747/fuel/main2_tank/apu_dc_pump_on", "number")

    B747.fuel.main3_tank.main_pump_fwd.on			= deferred_dataref("laminar/B747/fuel/main3_tank/main_pump_fwd_on", "number")
    B747.fuel.main3_tank.main_pump_aft.on			= deferred_dataref("laminar/B747/fuel/main3_tank/main_pump_aft_on", "number")
    B747.fuel.main3_tank.ovrd_jett_pump_fwd.on	    = deferred_dataref("laminar/B747/fuel/main3_tank/ovrd_jett_pump_fwd_on", "number")
    B747.fuel.main3_tank.ovrd_jett_pump_aft.on	    = deferred_dataref("laminar/B747/fuel/main3_tank/ovrd_jett_pump_aft_on", "number")

    B747.fuel.main4_tank.main_pump_fwd.on			= deferred_dataref("laminar/B747/fuel/main4_tank/main_pump_fwd_on", "number")
    B747.fuel.main4_tank.main_pump_aft.on			= deferred_dataref("laminar/B747/fuel/main4_tank/main_pump_aft_on", "number")

    B747.fuel.stab_tank.xfr_jett_pump_L.on		    = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_pump_L_on", "number")
    B747.fuel.stab_tank.xfr_jett_pump_R.on		    = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_pump_R_on", "number")

-- VALVES
B747.fuel.center_tank.refuel_vlv_L		= {}
B747.fuel.center_tank.refuel_vlv_R		= {}
B747.fuel.center_tank.jett_vlv_L		= {}
B747.fuel.center_tank.jett_vlv_R		= {}
B747.fuel.center_tank.stab_xfr_vlv_L	= {}
B747.fuel.center_tank.stab_xfr_vlv_R	= {}
B747.fuel.center_tank.flow_eq_vlv		= {}

B747.fuel.main1_tank.refuel_vlv			= {}
B747.fuel.main1_tank.main_xfr_vlv		= {}

B747.fuel.main2_tank.refuel_vlv_L		= {}
B747.fuel.main2_tank.refuel_vlv_R		= {}
B747.fuel.main2_tank.jett_vlv			= {}
B747.fuel.main2_tank.apu_vlv			= {}

B747.fuel.main3_tank.refuel_vlv_L		= {}
B747.fuel.main3_tank.refuel_vlv_R		= {}
B747.fuel.main3_tank.jett_vlv			= {}

B747.fuel.main4_tank.refuel_vlv			= {}
B747.fuel.main4_tank.main_xfr_vlv		= {}

B747.fuel.stab_tank.refuel_vlv			= {}
B747.fuel.stab_tank.isolation_vlv_L		= {}
B747.fuel.stab_tank.xfr_jett_vlv_L		= {}
B747.fuel.stab_tank.isolation_vlv_R		= {}
B747.fuel.stab_tank.xfr_jett_vlv_R		= {}

B747.fuel.res2_tank.refuel_vlv			= {}
B747.fuel.res2_tank.xfr_vlv_A			= {}
B747.fuel.res2_tank.xfr_vlv_B			= {}

B747.fuel.res3_tank.refuel_vlv			= {}
B747.fuel.res3_tank.xfr_vlv_A			= {}
B747.fuel.res3_tank.xfr_vlv_B			= {}

B747.fuel.engine1.xfeed_vlv			    = {}
B747.fuel.engine2.xfeed_vlv			    = {}
B747.fuel.engine3.xfeed_vlv			    = {}
B747.fuel.engine4.xfeed_vlv			    = {}

B747.fuel.spar_vlv1						= {}
B747.fuel.spar_vlv2						= {}
B747.fuel.spar_vlv3						= {}
B747.fuel.spar_vlv4						= {}

B747.fuel.jett_nozzle_vlv_L				= {}
B747.fuel.jett_nozzle_vlv_R				= {}

    -- VALVE TARGET POS
    B747.fuel.center_tank.refuel_vlv_L.target_pos	= 0
    B747.fuel.center_tank.refuel_vlv_R.target_pos	= 0
    B747.fuel.center_tank.jett_vlv_L.target_pos		= 0
    B747.fuel.center_tank.jett_vlv_R.target_pos		= 0
    B747.fuel.center_tank.stab_xfr_vlv_L.target_pos = 0
    B747.fuel.center_tank.stab_xfr_vlv_R.target_pos	= 0
    B747.fuel.center_tank.flow_eq_vlv.target_pos    = 0

    B747.fuel.main1_tank.refuel_vlv.target_pos		= 0
    B747.fuel.engine1.xfeed_vlv.target_pos		    = 0
    B747.fuel.main1_tank.main_xfr_vlv.target_pos    = 0

    B747.fuel.main2_tank.refuel_vlv_L.target_pos	= 0
    B747.fuel.main2_tank.refuel_vlv_R.target_pos	= 0
    B747.fuel.engine2.xfeed_vlv.target_pos		    = 0
    B747.fuel.main2_tank.jett_vlv.target_pos		= 0
    B747.fuel.main2_tank.apu_vlv.target_pos			= 0

    B747.fuel.main3_tank.refuel_vlv_L.target_pos	= 0
    B747.fuel.main3_tank.refuel_vlv_R.target_pos	= 0
    B747.fuel.engine3.xfeed_vlv.target_pos		    = 0
    B747.fuel.main3_tank.jett_vlv.target_pos	    = 0

    B747.fuel.main4_tank.refuel_vlv.target_pos		= 0
    B747.fuel.engine4.xfeed_vlv.target_pos		    = 0
    B747.fuel.main4_tank.main_xfr_vlv.target_pos	= 0

    B747.fuel.stab_tank.refuel_vlv.target_pos		= 0
    B747.fuel.stab_tank.isolation_vlv_L.target_pos	= 0
    B747.fuel.stab_tank.xfr_jett_vlv_L.target_pos	= 0
    B747.fuel.stab_tank.isolation_vlv_R.target_pos	= 0
    B747.fuel.stab_tank.xfr_jett_vlv_R.target_pos	= 0

    B747.fuel.res2_tank.refuel_vlv.target_pos		= 0
    B747.fuel.res2_tank.xfr_vlv_A.target_pos        = 0
    B747.fuel.res2_tank.xfr_vlv_B.target_pos		= 0

    B747.fuel.res3_tank.refuel_vlv.target_pos		= 0
    B747.fuel.res3_tank.xfr_vlv_A.target_pos		= 0
    B747.fuel.res3_tank.xfr_vlv_B.target_pos		= 0

    B747.fuel.spar_vlv1.target_pos					= 0
    B747.fuel.spar_vlv2.target_pos					= 0
    B747.fuel.spar_vlv3.target_pos					= 0
    B747.fuel.spar_vlv4.target_pos					= 0

    B747.fuel.jett_nozzle_vlv_L.target_pos			= 0
    B747.fuel.jett_nozzle_vlv_R.target_pos			= 0

    B747.fuel.center_tank.refuel_vlv_L.pos	    = deferred_dataref("laminar/B747/fuel/center_tank/refuel_vlv_L_pos", "number")
    B747.fuel.center_tank.refuel_vlv_R.pos	    = deferred_dataref("laminar/B747/fuel/center_tank/refuel_vlv_R_pos", "number")
    B747.fuel.center_tank.jett_vlv_L.pos	    = deferred_dataref("laminar/B747/fuel/center_tank/jett_vlv_L_pos", "number")
    B747.fuel.center_tank.jett_vlv_R.pos	    = deferred_dataref("laminar/B747/fuel/center_tank/jett_vlv_R_pos", "number")
    B747.fuel.center_tank.stab_xfr_vlv_L.pos    = deferred_dataref("laminar/B747/fuel/center_tank/stab_xfr_vlv_L_pos", "number")
    B747.fuel.center_tank.stab_xfr_vlv_R.pos    = deferred_dataref("laminar/B747/fuel/center_tank/stab_xfr_vlv_R_pos", "number")
    B747.fuel.center_tank.flow_eq_vlv.pos	    = deferred_dataref("laminar/B747/fuel/center_tank/flow_eq_vlv_pos", "number")

    B747.fuel.main1_tank.refuel_vlv.pos		    = deferred_dataref("laminar/B747/fuel/main1_tank/refuel_vlv_pos", "number")
    B747.fuel.main1_tank.main_xfr_vlv.pos	    = deferred_dataref("laminar/B747/fuel/main1_tank/main_xfr_vlv_pos", "number")

    B747.fuel.main2_tank.refuel_vlv_L.pos	    = deferred_dataref("laminar/B747/fuel/main2_tank/refuel_vlv_L_pos", "number")
    B747.fuel.main2_tank.refuel_vlv_R.pos	    = deferred_dataref("laminar/B747/fuel/main2_tank/refuel_vlv_R_pos", "number")
    B747.fuel.main2_tank.jett_vlv.pos		    = deferred_dataref("laminar/B747/fuel/main2_tank/jett_vlv_pos", "number")
    B747.fuel.main2_tank.apu_vlv.pos		    = deferred_dataref("laminar/B747/fuel/main2_tank/apu_vlv_pos", "number")

    B747.fuel.main3_tank.refuel_vlv_L.pos	    = deferred_dataref("laminar/B747/fuel/main3_tank/refuel_vlv_L_pos", "number")
    B747.fuel.main3_tank.refuel_vlv_R.pos	    = deferred_dataref("laminar/B747/fuel/main3_tank/refuel_vlv_R_pos", "number")
    B747.fuel.main3_tank.jett_vlv.pos		    = deferred_dataref("laminar/B747/fuel/main3_tank/jett_vlv_pos", "number")

    B747.fuel.main4_tank.refuel_vlv.pos	        = deferred_dataref("laminar/B747/fuel/main4_tank/refuel_vlv_pos", "number")
    B747.fuel.main4_tank.main_xfr_vlv.pos	    = deferred_dataref("laminar/B747/fuel/main4_tank/main_xfr_vlv_pos", "number")

    B747.fuel.stab_tank.refuel_vlv.pos		    = deferred_dataref("laminar/B747/fuel/stab_tank/refuel_vlv_pos", "number")
    B747.fuel.stab_tank.isolation_vlv_L.pos	    = deferred_dataref("laminar/B747/fuel/stab_tank/isolation_vlv_L_pos", "number")
    B747.fuel.stab_tank.xfr_jett_vlv_L.pos	    = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_vlv_L_pos", "number")
    B747.fuel.stab_tank.isolation_vlv_R.pos	    = deferred_dataref("laminar/B747/fuel/stab_tank/isolation_vlv_R_pos", "number")
    B747.fuel.stab_tank.xfr_jett_vlv_R.pos	    = deferred_dataref("laminar/B747/fuel/stab_tank/xfr_jett_vlv_R_pos", "number")

    B747.fuel.res2_tank.refuel_vlv.pos		    = deferred_dataref("laminar/B747/fuel/res2_tank/refuel_vlv_pos", "number")
    B747.fuel.res2_tank.xfr_vlv_A.pos		    = deferred_dataref("laminar/B747/fuel/res2_tank/xfr_vlv_A_pos", "number")
    B747.fuel.res2_tank.xfr_vlv_B.pos		    = deferred_dataref("laminar/B747/fuel/res2_tank/xfr_vlv_B_pos", "number")

    B747.fuel.res3_tank.refuel_vlv.pos		    = deferred_dataref("laminar/B747/fuel/res3_tank/refuel_vlv_pos", "number")
    B747.fuel.res3_tank.xfr_vlv_A.pos		    = deferred_dataref("laminar/B747/fuel/res3_tank/xfr_vlv_A_pos", "number")
    B747.fuel.res3_tank.xfr_vlv_B.pos		    = deferred_dataref("laminar/B747/fuel/res3_tank/xfr_vlv_B_pos", "number")

    B747.fuel.engine1.xfeed_vlv.pos		        = deferred_dataref("laminar/B747/fuel/engine1/xfeed_vlv_pos", "number")
    B747.fuel.engine2.xfeed_vlv.pos		        = deferred_dataref("laminar/B747/fuel/engine2/xfeed_vlv_pos", "number")
    B747.fuel.engine3.xfeed_vlv.pos		        = deferred_dataref("laminar/B747/fuel/engine3/xfeed_vlv_pos", "number")
    B747.fuel.engine4.xfeed_vlv.pos		        = deferred_dataref("laminar/B747/fuel/engine4/xfeed_vlv_pos", "number")

    B747.fuel.spar_vlv1.pos					    = deferred_dataref("laminar/B747/fuel/spar_vlv1_pos", "number")
    B747.fuel.spar_vlv2.pos					    = deferred_dataref("laminar/B747/fuel/spar_vlv2_pos", "number")
    B747.fuel.spar_vlv3.pos				        = deferred_dataref("laminar/B747/fuel/spar_vlv3_pos", "number")
    B747.fuel.spar_vlv4.pos				        = deferred_dataref("laminar/B747/fuel/spar_vlv4_pos", "number")

    B747.fuel.jett_nozzle_vlv_L.pos			    = deferred_dataref("laminar/B747/fuel/jett_nozzle_vlv_L_pos", "number")
    B747.fuel.jett_nozzle_vlv_R.pos			    = deferred_dataref("laminar/B747/fuel/jett_nozzle_vlv_R_pos", "number")



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
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


B747DR_init_fuel_CD                     = deferred_dataref("laminar/B747/fuel/init_CD", "number")


-- FUEL TO REMAIN
B747DR_fuel_to_remain_rheo      = deferred_dataref("laminar/B747/fuel/fuel_to_remain/rheostat", "number")



--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- FUEL JETTISON SELECTOR
B747CMD_fuel_jettison_sel_up 	= deferred_command("laminar/B747/fuel/fuel_jett/el_dial_up", "Fuel Jettison Selector Dial Up", B747_fuel_jettison_sel_up_CMDhandler)
B747CMD_fuel_jettison_sel_dn 	= deferred_command("laminar/B747/fuel/fuel_jett/sel_dial_dn", "Fuel Jettison Selector Dial Down", B747_fuel_jettison_sel_dn_CMDhandler)



-- TQ FUEL CONTROL SWITCHES
B747CMD_fuel_control_switch1 	= deferred_command("laminar/B747/fuel/fuel_control_1/toggle_switch", "Fuel Control Switch 1", B747_fuel_control_switch1_CMDhandler)
B747CMD_fuel_control_switch2 	= deferred_command("laminar/B747/fuel/fuel_control_2/toggle_switch", "Fuel Control Switch 2", B747_fuel_control_switch2_CMDhandler)
B747CMD_fuel_control_switch3 	= deferred_command("laminar/B747/fuel/fuel_control_3/toggle_switch", "Fuel Control Switch 3", B747_fuel_control_switch3_CMDhandler)
B747CMD_fuel_control_switch4 	= deferred_command("laminar/B747/fuel/fuel_control_4/toggle_switch", "Fuel Control Switch 4", B747_fuel_control_switch4_CMDhandler)
B747DR_engine_fuel_valve_pos        = find_dataref("laminar/B747/engines/fuel_valve_pos")

-- AI
B747CMD_ai_fuel_quick_start		= deferred_command("laminar/B747/ai/fuel_quick_start", "number", B747_ai_fuek_quick_start_CMDhandler)
simDR_override_fuel_system          = find_dataref("sim/operation/override/override_fuel_system")
simDR_engine_has_fuel               = find_dataref("sim/flightmodel2/engines/has_fuel_flow_before_mixture")
function aircraft_load()

    simDR_override_fuel_system = 1

end

function aircraft_unload()
    
    simDR_override_fuel_system = 0

end

engineHasFuelProcessing = 0
function startFuelProcessing()
    engineHasFuelProcessing = 1
end


function flight_start() 
    engineHasFuelProcessing = 0
    run_after_time(startFuelProcessing, 10.0)                                        -- DELAYED FUEL PROCESSING

end