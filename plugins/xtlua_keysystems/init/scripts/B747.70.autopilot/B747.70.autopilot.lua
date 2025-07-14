--[[
*****************************************************************************************
* Program Script Name	:	B747.70.autopilot
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
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED
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
NUM_AUTOPILOT_BUTTONS = 18
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

simDR_autopilot_servos_on = deferred_dataref("laminar/B747/autopilot/servos_on", "number")
--custom ALT HOLD


B747DR_ap_button_switch_position    	= deferred_dataref("laminar/B747/autopilot/button_switch/position", "array[" .. tostring(NUM_AUTOPILOT_BUTTONS) .. "]")
B747DR_ap_bank_limit_sel_dial_pos   	= deferred_dataref("laminar/B747/autopilot/bank_limit/sel_dial_pos", "number")
B747DR_ap_ias_mach_window_open      	= deferred_dataref("laminar/B747/autopilot/ias_mach/window_open", "number")
B747DR_ap_vs_window_open            	= deferred_dataref("laminar/B747/autopilot/vert_spd/window_open", "number")
B747DR_ap_vs_show_thousands         	= deferred_dataref("laminar/B747/autopilot/vert_speed/show_thousands", "number")
--B747DR_ap_hdg_hold_mode             	= deferred_dataref("laminar/B747/autopilot/heading_hold_mode", "number")
--B747DR_ap_hdg_sel_mode              	= deferred_dataref("laminar/B747/autopilot/heading_sel_mode", "number")
B747DR_autopilot_altitude_ft    	= deferred_dataref("laminar/B747/autopilot/heading/altitude_dial_ft", "number")
B747DR_autopilot_altitude_ft_pfd    	= deferred_dataref("laminar/B747/autopilot/heading/altitude_dial_ft_pfd", "number")
B747DR_ap_heading_deg               	= deferred_dataref("laminar/B747/autopilot/heading/degrees", "number")
B747DR_ap_target_heading_deg               	= deferred_dataref("laminar/B747/autopilot/heading/target", "number")
B747DR_ap_target_altitude               	= deferred_dataref("laminar/B747/autopilot/altitude/target", "number")
B747DR_ap_target_vertspeed               	= deferred_dataref("laminar/B747/autopilot/vertspeed/target", "number")
B747DR_ap_target_speed               	= deferred_dataref("laminar/B747/autopilot/speed/target", "number")
B747DR_ap_target_flaps               	= deferred_dataref("laminar/B747/autopilot/flaps/target", "number")
B747DR_ap_ias_dial_value            	= deferred_dataref("laminar/B747/autopilot/ias_dial_value", "number")
B747DR_ap_ias_bug_value            	= deferred_dataref("laminar/B747/autopilot/ias_bug_value", "number")
B747DR_ap_ias_bug_value_pfd            	= deferred_dataref("laminar/B747/autopilot/ias_bug_value_pfd", "number")
B747DR_ap_ias_mach_dial_value            	= deferred_dataref("laminar/B747/autopilot/ias_mach_dial_value", "number") --display only
B747DR_ils_dots           	= deferred_dataref("laminar/B747/autopilot/ils_dots", "number") --display only
B747DR_ap_vnav_system            	= deferred_dataref("laminar/B747/autopilot/vnav_system", "number")
B747DR_ap_vnav_target_alt            	= deferred_dataref("laminar/B747/autopilot/vnav_target_alt", "number")
B747DR_ap_vnav_state            	= deferred_dataref("laminar/B747/autopilot/vnav_state", "number")
B747DR_ap_lnav_state            	= deferred_dataref("laminar/B747/autopilot/lnav_state", "number")
B747DR_ap_inVNAVdescent 		= deferred_dataref("laminar/B747/autopilot/vnav_descent", "number")
B747DR_ap_inDescent 		= deferred_dataref("laminar/B747/autopilot/vnav/after_tod", "number")
B747DR_ap_flightPhase 		= deferred_dataref("laminar/B747/autopilot/flightPhase", "number")
B747BR_totalDistance 			= deferred_dataref("laminar/B747/autopilot/dist/remaining_distance", "number")
B747BR_distance_to_dest 			= deferred_dataref("laminar/B747/autopilot/dist/distance_to_dest", "number")
B747BR_eod_index 			= deferred_dataref("laminar/B747/autopilot/dist/eod_index", "number")
B747BR_nextDistanceInFeet 		= deferred_dataref("laminar/B747/autopilot/dist/next_distance_feet", "number")
B747BR_cruiseAlt 			= deferred_dataref("laminar/B747/autopilot/dist/cruise_alt", "number")
B747BR_fpe				= deferred_dataref("laminar/B747/autopilot/dist/flight_path_error", "number")
B747BR_showFMA				= deferred_dataref("laminar/B747/autopilot/FMA/showFMA", "number")
B747BR_tod				= deferred_dataref("laminar/B747/autopilot/dist/top_of_descent", "number")
B747BR_todLat				= deferred_dataref("laminar/B747/autopilot/dist/top_of_descent_lat", "number")
B747BR_todLong				= deferred_dataref("laminar/B747/autopilot/dist/top_of_descent_long", "number")
B747BR_tocLat				= deferred_dataref("laminar/B747/autopilot/dist/top_of_climb_lat", "number")
B747BR_tocLong				= deferred_dataref("laminar/B747/autopilot/dist/top_of_climb_long", "number")
B747BR_toc				= deferred_dataref("laminar/B747/autopilot/dist/distance_to_toc", "number")
B747DR_autopilot_vs_fpm         			= deferred_dataref("laminar/B747/cockpit2/autopilot/vvi_dial_fpm", "number")
B747DR_ap_vvi_fpm						= deferred_dataref("laminar/B747/autopilot/vvi_fpm", "number")
B747DR_ap_alt_show_thousands      		= deferred_dataref("laminar/B747/autopilot/altitude/show_thousands", "number")
B747DR_ap_alt_show_tenThousands			= deferred_dataref("laminar/B747/autopilot/altitude/show_tenThousands", "number")
B747DR_ap_cmd_L_mode         			= deferred_dataref("laminar/B747/autopilot/cmd_L_mode/status", "number")
B747DR_ap_cmd_C_mode         			= deferred_dataref("laminar/B747/autopilot/cmd_C_mode/status", "number")
B747DR_ap_cmd_R_mode         			= deferred_dataref("laminar/B747/autopilot/cmd_R_mode/status", "number")
B747DR_ap_autothrottle_armed        	= deferred_dataref("laminar/B747/autothrottle/armed", "number")
B747DR_ap_mach_decimal_visibiilty	    = deferred_dataref("laminar/B747/autopilot/mach_dec_vis", "number")
B747DR_ap_fpa	    = deferred_dataref("laminar/B747/autopilot/navadata/fpa", "number")
B747DR_ap_vb	    = deferred_dataref("laminar/B747/autopilot/navadata/vb", "number")
B747DR_ap_capt_roll	    = deferred_dataref("laminar/B747/autopilot/capt_roll_ref", "number")
B747DR_ap_fo_roll	    = deferred_dataref("laminar/B747/autopilot/fo_roll_ref", "number")



B747DR_ap_FMA_autothrottle_mode_box_status  = deferred_dataref("laminar/B747/autopilot/FMA/autothrottle/mode_box_status", "number")
B747DR_ap_roll_mode_box_status         	= deferred_dataref("laminar/B747/autopilot/FMA/roll/mode_box_status", "number")
B747DR_ap_pitch_mode_box_status        	= deferred_dataref("laminar/B747/autopilot/FMA/pitch/mode_box_status", "number")
B747DR_ap_approach_mode     	= deferred_dataref("laminar/B747/autopilot/approach_mode", "number")

B747DR_autopilot_nav_status = deferred_dataref("laminar/B747/autopilot/nav_status", "number")
B747DR_autopilot_gs_status = deferred_dataref("laminar/B747/autopilot/glideslope_status", "number")

B747DR_autopilot_acutal_nav_status = deferred_dataref("laminar/B747/autopilot/actual_nav_status", "number")
B747DR_autopilot_acutal_gs_status = deferred_dataref("laminar/B747/autopilot/actual_glideslope_status", "number")

B747DR_ap_FMA_autothrottle_mode     	= deferred_dataref("laminar/B747/autopilot/FMA/autothrottle_mode", "number")
B747DR_ap_ATT     	                = deferred_dataref("laminar/B747/autopilot/att_rate", "number")

B747DR_ap_active_land = deferred_dataref("laminar/B747/autopilot/active_land", "number")
--[[
    0 = NONE
    1 = HOLD
    2 = IDLE
    3 = SPD
    4 = THR
    5 = THR REF
--]]

B747DR_ap_FMA_armed_roll_mode       	= deferred_dataref("laminar/B747/autopilot/FMA/armed_roll_mode", "number")
--[[
    0 = NONE
    1 = TOGA
    2 = LNAV
    3 = LOC
    4 = ROLLOUT
    5 = ATT
    6 = HDG SEL
    7 = HDG HOLD
--]]

B747DR_ap_FMA_active_roll_mode      	= deferred_dataref("laminar/B747/autopilot/FMA/active_roll_mode", "number")
--[[
    0 = NONE
    1 = TOGA
    2 = LNAV
    3 = LOC
    4 = ROLLOUT
    5 = ATT
    6 = HDG SEL
    7 = HDG HOLD
--]]

B747DR_ap_FMA_armed_pitch_mode      	= deferred_dataref("laminar/B747/autopilot/FMA/armed_pitch_mode", "number")
--[[
    0 = NONE
    1 = TOGA
    2 = G/S
    3 = FLARE
    4 = VNAV
    7 = V/S
    8 = FLCH SPD
    9 = ALT
--]]

B747DR_ap_FMA_active_pitch_mode     	= deferred_dataref("laminar/B747/autopilot/FMA/active_pitch_mode", "number")
--[[
    0 = NONE
    1 = TOGA
    2 = G/S
    3 = FLARE
    4 = VNAV SPD
    5 = VNAV ALT
    6 = VNAV PATH
    7 = V/S
    8 = FLCH SPD
    9 = ALT
--]]




B747DR_ap_AFDS_mode_box_status_pilot      	= deferred_dataref("laminar/B747/autopilot/AFDS/mode_box_status_pilot", "number")
B747DR_ap_AFDS_mode_box_status_copilot      	= deferred_dataref("laminar/B747/autopilot/AFDS/mode_box_status_copilot", "number")
B747DR_ap_AFDS_mode_box2_status_pilot     	= deferred_dataref("laminar/B747/autopilot/AFDS/mode_box2_status_pilot", "number")
B747DR_ap_AFDS_mode_box2_status_copilot     	= deferred_dataref("laminar/B747/autopilot/AFDS/mode_box2_status_copilot", "number")
B747DR_ap_AFDS_status_annun_pilot            	= deferred_dataref("laminar/B747/autopilot/AFDS/status_annun_pilot", "number")
B747DR_ap_AFDS_status_annun_copilot            	= deferred_dataref("laminar/B747/autopilot/AFDS/status_annun_copilot", "number")
--[[
    0 = NONE
    1 = FD
    2 = CMD
    3 = LAND 2
    4 = LAND 3
    5 = NO AUTOLAND
--]]
B747DR_ap_autoland            	= deferred_dataref("laminar/B747/autopilot/autoland", "number")
B744DR_autolandPitch            = deferred_dataref("laminar/B747/autopilot/autolandPitch", "number")
B747DR_lastap_dial_airspeed 	= deferred_dataref("laminar/B747/autopilot/ap_monitor/last_airspeed", "number")
B747DR_max_dial_machspeed       = deferred_dataref("laminar/B747/autopilot/ap_monitor/max_dial_machspeed", "number")
B747DR_target_descentAlt        = deferred_dataref("laminar/B747/autopilot/ap_monitor/target_descentAlt", "number")
B747DR_alt_capture_window        = deferred_dataref("laminar/B747/autopilot/ap_monitor/alt_capture_window", "number")
B747DR_switching_servos_on      = deferred_dataref("laminar/B747/autopilot/ap_monitor/servos_on_time", "number")
B747DR_target_descentSpeed      = deferred_dataref("laminar/B747/autopilot/ap_monitor/target_descentSpeed", "number")
B747DR_descentSpeedGradient     = deferred_dataref("laminar/B747/autopilot/ap_monitor/descentSpeedGradient", "number")
B747DR_switchingIASMode         = deferred_dataref("laminar/B747/autopilot/ap_monitor/switchingIASMode", "number")
B747DR_fmstargetIndex           = deferred_dataref("laminar/B747/autopilot/ap_monitor/fmstargetIndex", "number")
B747DR_fmstargetDistance           = deferred_dataref("laminar/B747/autopilot/ap_monitor/fmstargetDistance", "number")
B747DR_fmscurrentIndex          = deferred_dataref("laminar/B747/autopilot/ap_monitor/fmscurrentIndex", "number")
B747DR_mcp_hold                 = deferred_dataref("laminar/B747/autopilot/ap_monitor/mcp_hold", "number")
B747DR_mcp_hold_pressed                 = deferred_dataref("laminar/B747/autopilot/ap_monitor/mcp_hold_pressed", "number")
B747CMD_ap_thrust_mode              	= deferred_command("laminar/B747/autopilot/button_switch/thrust_mode", "Autopilot THR Mode", B747_ap_thrust_mode_CMDhandler)
B747DR_ap_thrust_mode              			= deferred_dataref("laminar/B747/autopilot/thrust_mode", "number")
-- 0 off
-- 1 CLB
-- 2 Manual
B747DR_ap_lastCommand              			= deferred_dataref("laminar/B747/autopilot/lastCommand", "number")

B747CMD_ap_switch_speed_mode			= deferred_command("laminar/B747/autopilot/button_switch/speed_mode", "A/P Speed Mode Switch", B747_ap_switch_speed_mode_CMDhandler)
B747CMD_ap_press_airspeed		= deferred_command("laminar/B747/button_switch/press_airspeed", "Airspeed Dial Press", B747_ap_switch_vnavspeed_mode_CMDhandler)
B747CMD_ap_press_altitude		= deferred_command("laminar/B747/button_switch/press_altitude", "Altitude Dial Press", B747_ap_switch_vnavalt_mode_CMDhandler)
B747CMD_ap_ias_mach_sel_button      	= deferred_command("laminar/B747/autopilot/ias_mach/sel_button", "Autopilot IAS/Mach Selector Button", B747_ap_ias_mach_sel_button_CMDhandler)
B747CMD_ap_switch_flch_mode				= deferred_command("laminar/B747/autopilot/button_switch/flch_mode", "Autopilot Fl CH Mode Switch", B747_ap_switch_flch_mode_CMDhandler)
B747CMD_ap_switch_vs_mode				= deferred_command("laminar/B747/autopilot/button_switch/vs_mode", "A/P V/S Mode Switch", B747_ap_switch_vs_mode_CMDhandler)
B747CMD_ap_switch_alt_hold_mode			= deferred_command("laminar/B747/autopilot/button_switch/alt_hold_mode", "A/P Altitude Hold Mode Switch", B747_ap_alt_hold_mode_CMDhandler)
B747CMD_autopilot_VNAV_mode				= deferred_command("laminar/B747/autopilot/button_switch/VNAV","A/P VNAV Mode Switch",B747_ap_VNAV_mode_CMDhandler)
B747CMD_autopilot_LNAV_mode				= deferred_command("laminar/B747/autopilot/button_switch/LNAV", "A/P LNAV Mode Switch",B747_ap_LANV_mode_afterCMDhandler)

B747CMD_ap_switch_hdg_sel_mode			= deferred_command("laminar/B747/autopilot/button_switch/heading_select", "A/P Heading Select Mode Switch", B747_ap_switch_hdg_sel_mode_CMDhandler)
--B747CMD_ap_switch_hdg_hold_mode			= deferred_command("laminar/B747/autopilot/button_switch/hdg_hold_mode", "A/P Heading Hold Mode Switch", B747_ap_switch_hdg_hold_mode_CMDhandler)
B747CMD_ap_switch_loc_mode				= deferred_command("laminar/B747/autopilot/button_switch/loc_mode", "A/P Localizer Mode Switch", B747_ap_switch_loc_mode_CMDhandler)

B747CMD_ap_switch_cmd_L					= deferred_command("laminar/B747/autopilot/button_switch/cmd_L", "A/P CMD L Switch", B747_ap_switch_cmd_L_CMDhandler)
B747CMD_ap_switch_cmd_C					= deferred_command("laminar/B747/autopilot/button_switch/cmd_C", "A/P CMD C Switch", B747_ap_switch_cmd_C_CMDhandler)
B747CMD_ap_switch_cmd_R					= deferred_command("laminar/B747/autopilot/button_switch/cmd_R", "A/P CMD R Switch", B747_ap_switch_cmd_R_CMDhandler)
B747CMD_autopilot_appr_mode					= deferred_command("laminar/B747/autopilot/approach", "APP Switch", B747CMD_autopilot_appr_mode_CMDhandler)
B747CMD_ap_switch_disengage_bar			= deferred_command("laminar/B747/autopilot/slide_switch/disengage_bar", "A/P Disenage Bar", B747_ap_switch_disengage_bar_CMDhandler)
B747CMD_ap_switch_yoke_disengage_capt	= deferred_command("laminar/B747/autopilot/button_switch/yoke_disengage_capt", "A/P Capt Yoke Disengage Switch", B747_ap_switch_yoke_disengage_capt_CMDhandler)
B747CMD_ap_switch_yoke_disengage_fo		= deferred_command("laminar/B747/autopilot/button_switch/yoke_disengage_fo", "A/P F/O Yoke Disengage Switch", B747_ap_switch_yoke_disengage_fo_CMDhandler)
B747CMD_ap_switch_autothrottle_disco_L	= deferred_command("laminar/B747/autopilot/button_switch/autothrottle_disco_L", "A/P Autothrottle Disco Left", B747_ap_switch_autothrottle_disco_L_CMDhandler)
B747CMD_ap_switch_autothrottle_disco_R	= deferred_command("laminar/B747/autopilot/button_switch/autothrottle_disco_R", "A/P Autothrottle Disco Right", B747_ap_switch_autothrottle_disco_R_CMDhandler)

--B747CMD_ap_att_mode						= deferred_command("laminar/B747/autopilot/att_mode", "Set Autopilot ATT Mode", B747_ap_att_mode_CMDhandler)
B747CMD_ap_reset 						= deferred_command("laminar/B747/autopilot/mode_reset", "Autopilot Mode Reset", B747_ap_reset_CMDhandler)



-- AI
B747CMD_ai_ap_quick_start				= deferred_command("laminar/B747/ai/autopilot_quick_start", "Autopilot Quick Start", B747_ai_ap_quick_start_CMDhandler)



simDR_override_throttles = find_dataref("sim/operation/override/override_throttles")
simDR_override_control_surfaces       = find_dataref("sim/operation/override/override_control_surfaces")
simDR_override_steering               = find_dataref("sim/operation/override/override_wheel_steer")
simDR_override_gpu               = find_dataref("sim/operation/override/override_GPU_volts")
simDR_version=find_dataref("sim/version/xplane_internal_version")
function aircraft_unload()
	if simDR_version>=120012 then
    simDR_override_gpu = 0
	end
    simDR_override_throttles = 0
    simDR_override_control_surfaces = 0
    simDR_override_steering=0
end
