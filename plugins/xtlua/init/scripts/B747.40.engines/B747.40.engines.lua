--[[
*****************************************************************************************
* Program Script Name	:	B747.40.engines
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

--NUM_THRUST_LEVERS = 5


function null_command(phase, duration)
end
--replace create command
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
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_thrust_mnp_show				= deferred_dataref("laminar/B747/engine/thrust_mnp_show", "array[4]")
B747DR_thrust_mnp_show_all			= deferred_dataref("laminar/B747/engine/thrust_mnp_show_all", "number")

B747DR_reverse_mnp_show				= deferred_dataref("laminar/B747/engine/rev_mnp_show", "array[4)")
B747DR_reverse_mnp_show_all			= deferred_dataref("laminar/B747/engine/rev_mnp_show_all", "number")

B747DR_engine_fuel_valve_pos        = deferred_dataref("laminar/B747/engines/fuel_valve_pos", "array[4)")
B747DR_EICAS2_fuel_on_ind_status    = deferred_dataref("laminar/B747/engines/fuel_on_indicator_status", "array[4)")
B747DR_EICAS2_oil_press_status      = deferred_dataref("laminar/B747/engines/EICAS2_oil_press_status", "array[4)")
B747DR_EICAS2_engine_vibration      = deferred_dataref("laminar/B747/engines/vibration", "array[4)")
B747DR_EICAS2_engine_disturbance    = deferred_dataref("laminar/B747/engines/disturbance", "number")
B747DR_engine_vibration_position    = deferred_dataref("laminar/B747/engine/vibration_position", "array[4)")
B747DR_engine_oil_press_psi         = deferred_dataref("laminar/B747/engines/oil_press_psi", "array[4)")
B747DR_engine_oil_temp_degC         = deferred_dataref("laminar/B747/engines/oil_temp_degC", "array[4)")
B747DR_engine_oil_qty_liters        = deferred_dataref("laminar/B747/engines/oil_qty_liters", "array[4)")
B747DR_elec_apu_oil      			= deferred_dataref("laminar/B747/apu/oil", "number")
B747DR_engine_apu_n2      	        = deferred_dataref("laminar/B747/apu/n2", "number")
B747DR_EPR_max_limit                = deferred_dataref("laminar/B747/engines/EPR/max_limit", "array[4)")
B747DR_EGT_amber_inhibit            = deferred_dataref("laminar/B747/engines/EGT/amber_inhibit", "array[4)")
B747DR_EGT_amber_on                 = deferred_dataref("laminar/B747/engines/EGT/amber_on", "array[4)")
B747DR_EGT_white_on                 = deferred_dataref("laminar/B747/engines/EGT/white_on", "array[4)")

B747DR_init_engines_CD              = deferred_dataref("laminar/B747/engines/init_CD", "number")

B747DR_engine_TOGA_mode             = deferred_dataref("laminar/B747/engines/TOGA_mode", "number")

B747DR_ref_thr_limit_mode           = deferred_dataref("laminar/B747/engines/ref_thr_limit_mode", "string")


	


-- AI
B747CMD_ai_engines_quick_start		= deferred_command("laminar/B747/ai/engines_quick_start", "number", B747_ai_engines_quick_start_CMDhandler)



B747DR_button_switch_position               = find_dataref("laminar/B747/button_switch/position")
B747DR_toggle_switch_position               = find_dataref("laminar/B747/toggle_switch/position")

B747DR_fuel_control_toggle_switch_pos       = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")

B747DR_bleedAir_engine1_start_valve_pos     = find_dataref("laminar/B747/air/engine1/bleed_start_valve_pos")
B747DR_bleedAir_engine2_start_valve_pos     = find_dataref("laminar/B747/air/engine2/bleed_start_valve_pos")
B747DR_bleedAir_engine3_start_valve_pos     = find_dataref("laminar/B747/air/engine3/bleed_start_valve_pos")
B747DR_bleedAir_engine4_start_valve_pos     = find_dataref("laminar/B747/air/engine4/bleed_start_valve_pos")

B747DR_engine_fire				= deferred_dataref("laminar/B747/annunciators/engine_fires", "array[5)")

simDR_engine_N2_pct             = find_dataref("sim/cockpit2/engine/indicators/N2_percent")
simDR_engine_fuel_mix_ratio     = find_dataref("sim/cockpit2/engine/actuators/mixture_ratio")
simDR_engine_starter_status     = find_dataref("sim/cockpit2/engine/actuators/ignition_key")
simDR_flap_deploy_ratio         = find_dataref("sim/flightmodel2/controls/flap_handle_deploy_ratio")
simDR_engine_nacelle_heat_on    = find_dataref("sim/cockpit2/ice/ice_inlet_heat_on_per_engine")
simDR_engine_igniter_on         = find_dataref("sim/cockpit2/annunciators/igniter_on")
simCMD_igniter_on_1         = find_command("sim/igniters/igniter_contin_on_1")
simCMD_igniter_on_2         = find_command("sim/igniters/igniter_contin_on_2")
simCMD_igniter_on_3         = find_command("sim/igniters/igniter_contin_on_3")
simCMD_igniter_on_4         = find_command("sim/igniters/igniter_contin_on_4")

simCMD_igniter_off_1        = find_command("sim/igniters/igniter_contin_off_1")
simCMD_igniter_off_2        = find_command("sim/igniters/igniter_contin_off_2")
simCMD_igniter_off_3        = find_command("sim/igniters/igniter_contin_off_3")
simCMD_igniter_off_4        = find_command("sim/igniters/igniter_contin_off_4")

simCMD_starter_on_1         = find_command("sim/starters/engage_starter_1")
simCMD_starter_on_2         = find_command("sim/starters/engage_starter_2")
simCMD_starter_on_3         = find_command("sim/starters/engage_starter_3")
simCMD_starter_on_4         = find_command("sim/starters/engage_starter_4")

simCMD_starter_off_1        = find_command("sim/starters/shut_down_1")
simCMD_starter_off_2        = find_command("sim/starters/shut_down_2")
simCMD_starter_off_3        = find_command("sim/starters/shut_down_3")
simCMD_starter_off_4        = find_command("sim/starters/shut_down_4")
B747CMD_engine_start_switch1        = find_command("laminar/B747/toggle_switch/engine_start1")
B747CMD_engine_start_switch2        = find_command("laminar/B747/toggle_switch/engine_start2")
B747CMD_engine_start_switch3        = find_command("laminar/B747/toggle_switch/engine_start3")
B747CMD_engine_start_switch4        = find_command("laminar/B747/toggle_switch/engine_start4")

B747CMD_engine_start_switch1_off    = find_command("laminar/B747/toggle_switch/engine_start1_off")
B747CMD_engine_start_switch2_off    = find_command("laminar/B747/toggle_switch/engine_start2_off")
B747CMD_engine_start_switch3_off    = find_command("laminar/B747/toggle_switch/engine_start3_off")
B747CMD_engine_start_switch4_off    = find_command("laminar/B747/toggle_switch/engine_start4_off")





