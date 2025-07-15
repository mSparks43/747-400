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
--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

NUM_AUTOPILOT_BUTTONS = 18
function null_command(phase, duration)
end
function deferred_command(name, desc, realFunc)
	return wrap_command(name, realFunc, null_command)
end
function replace_char(pos, str, r)
	return str:sub(1, pos - 1) .. r .. str:sub(pos + 1)
end
--replace deferred_dataref
function deferred_dataref(name, nilType, callFunction)
	if callFunction ~= nil then
		print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
	end
	return find_dataref(name)
end

--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--
B747CMD_fdr_log_lnav           = find_command("laminar/B747/fdr/lnav")
B747CMD_fdr_log_vnav           = find_command("laminar/B747/fdr/vnav")
B747CMD_fdr_log_apon           = find_command("laminar/B747/fdr/apon")
B747CMD_fdr_log_apdisconnect           = find_command("laminar/B747/fdr/apdisconnect")
B747CMD_fdr_log_flch           = find_command("laminar/B747/fdr/flch")
B747CMD_fdr_log_vs           = find_command("laminar/B747/fdr/vs")
B747CMD_fdr_log_alt           = find_command("laminar/B747/fdr/alt")
B747CMD_fdr_log_toga           = find_command("laminar/B747/fdr/toga")
B747CMD_fdr_log_loc           = find_command("laminar/B747/fdr/loc")
B747CMD_fdr_log_app           = find_command("laminar/B747/fdr/app")
B747CMD_fdr_log_altmod           = find_command("laminar/B747/fdr/altmod")
B747CMD_fdr_log_spdmod           = find_command("laminar/B747/fdr/spdmod")
B747CMD_fdr_log_spd           = find_command("laminar/B747/fdr/spd")
B747CMD_fdr_log_headsel           = find_command("laminar/B747/fdr/headsel")
B747CMD_fdr_log_headhold          = find_command("laminar/B747/fdr/headhold")
--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local B747_ap_button_switch_position_target = {}
for i = 0, NUM_AUTOPILOT_BUTTONS - 1 do
	B747_ap_button_switch_position_target[i] = 0
end

local B747_ap_last_AFDS_status = 0
local B747_ap_last_FMA_autothrottle_mode = 0
local B747_ap_last_FMA_roll_mode = 0
local B747_ap_last_FMA_pitch_mode = 0
local fmsData = {}
function B747_rescale(in1, out1, in2, out2, x)
	if x < in1 then
		return out1
	end
	if x > in2 then
		return out2
	end
	return out1 + (out2 - out1) * (x - in1) / (in2 - in1)
end
function getFMSData(name)
	return fmsData[name]
end
function setFMSData(id, value)
	if string.len(B747DR_FMSdata) > 0 then
		fmsData = json.decode(B747DR_FMSdata)
	else
		fmsData = json.decode("[]")
	end
	fmsData[id] = value
	B747DR_FMSdata = json.encode(fmsData)
end

local beganDescentAny = false
function beganDescent()
	return beganDescentAny
end
function setDescent(val)
	beganDescentAny = val
end

--*************************************************************************************--
--** 				             FIND X-PLANE DATAREFS           			    	 **--
--*************************************************************************************--
B747DR_airspeed_Vf0 = find_dataref("laminar/B747/airspeed/Vf0", "number")
B747DR_airspeed_Vf1 = find_dataref("laminar/B747/airspeed/Vf1")
B747DR_airspeed_Vf5 = find_dataref("laminar/B747/airspeed/Vf5")
B747DR_airspeed_Vf10 = find_dataref("laminar/B747/airspeed/Vf10")
B747DR_airspeed_Vf20 = find_dataref("laminar/B747/airspeed/Vf20")
B747DR_airspeed_Vf25 = find_dataref("laminar/B747/airspeed/Vf25")
B747DR_airspeed_Vf30 = find_dataref("laminar/B747/airspeed/Vf30")
B747DR_CAS_warning_status = find_dataref("laminar/B747/CAS/warning_status")
simDR_autopilot_flight_dir_active = find_dataref("sim/cockpit2/annunciators/flight_director")
simDR_autopilot_flight_dir_mode = find_dataref("sim/cockpit2/autopilot/flight_director_mode")
B747DR_autothrottle_active = find_dataref("laminar/B747/engines/autothrottle_active")
--simDR_autopilot_autothrottle_on = find_dataref("sim/cockpit2/autopilot/autothrottle_on")
simCMD_ThrottleDown = find_command("sim/engines/throttle_down")
simCMD_ThrottleUp = find_command("sim/engines/throttle_up")
B747DR_ap_vnav_pause = find_dataref("laminar/B747/autopilot/vnav_pause")
simCMD_pause = find_command("sim/operation/pause_toggle")
simDRTime = find_dataref("sim/time/total_running_time_sec")
simDR_autopilot_autothrottle_enabled = find_dataref("sim/cockpit2/autopilot/autothrottle_enabled")
simDR_autopilot_autothrottle_arm = find_dataref("sim/cockpit2/autopilot/autothrottle_arm")
simDR_autopilot_bank_limit = find_dataref("sim/cockpit2/autopilot/bank_angle_mode")
simDR_autopilot_airspeed_is_mach = find_dataref("sim/cockpit2/autopilot/airspeed_is_mach")
simDR_autopilot_altitude_ft = find_dataref("laminar/B747/autopilot/altitude_dial_ft")
simDR_disabled_autopilot_altitude_ft = find_dataref("sim/cockpit2/autopilot/altitude_dial_ft")
simDR_autopilot_hold_altitude_ft = find_dataref("laminar/B747/autopilot/altitude_hold_ft")
simDR_autopilot_tod_index = find_dataref("sim/cockpit2/radios/indicators/fms_tod_before_index_pilot")
simDR_autopilot_tod_distance = find_dataref("sim/cockpit2/radios/indicators/fms_distance_to_tod_pilot")
B747DR_alt_capture_window        = deferred_dataref("laminar/B747/autopilot/ap_monitor/alt_capture_window", "number")
B747DR_switching_servos_on = deferred_dataref("laminar/B747/autopilot/ap_monitor/servos_on_time", "number")
B747DR_display_N1 = find_dataref("laminar/B747/engines/display_N1")
B747DR_display_N2 = find_dataref("laminar/B747/engines/display_N2")
B747DR_fmc_notifications = find_dataref("laminar/B747/fms/notification")
B747BR_distance_to_dest  = deferred_dataref("laminar/B747/autopilot/dist/distance_to_dest", "number")
B747BR_toc				= deferred_dataref("laminar/B747/autopilot/dist/distance_to_toc", "number")
B747DR_ils_dots = deferred_dataref("laminar/B747/autopilot/ils_dots", "number") --display only
B747BR_totalDistance = find_dataref("laminar/B747/autopilot/dist/remaining_distance")
B747BR_eod_index = deferred_dataref("laminar/B747/autopilot/dist/eod_index", "number")
B747BR_nextDistanceInFeet = find_dataref("laminar/B747/autopilot/dist/next_distance_feet")
B747BR_cruiseAlt = find_dataref("laminar/B747/autopilot/dist/cruise_alt")
B747BR_fpe				= find_dataref("laminar/B747/autopilot/dist/flight_path_error")
B747BR_tod = find_dataref("laminar/B747/autopilot/dist/top_of_descent")
B747BR_todLat = deferred_dataref("laminar/B747/autopilot/dist/top_of_descent_lat", "number")
B747BR_todLong = deferred_dataref("laminar/B747/autopilot/dist/top_of_descent_long", "number")
B747BR_tocLat				= deferred_dataref("laminar/B747/autopilot/dist/top_of_climb_lat", "number")
B747BR_tocLong				= deferred_dataref("laminar/B747/autopilot/dist/top_of_climb_long", "number")
B747DR_ND_Wind_Bearing = find_dataref("laminar/B747/nd/wind_bearing")
B747DR_throttle		= find_dataref("laminar/B747/engine/throttle")
simDR_wind_speed_kts = find_dataref("sim/cockpit2/gauges/indicators/wind_speed_kts")
simDR_autopilot_course = find_dataref("sim/cockpit/gps/course")
simDR_autopilot_destination_type = find_dataref("sim/cockpit/gps/destination_type")
simDR_autopilot_destination_index = find_dataref("sim/cockpit/gps/destination_index")
simDR_autopilot_airspeed_kts = find_dataref("sim/cockpit2/autopilot/airspeed_dial_kts")
simDR_autopilot_airspeed_kts_mach = find_dataref("sim/cockpit2/autopilot/airspeed_dial_kts_mach")
--simDR_autopilot_heading_deg         	= find_dataref("sim/cockpit2/autopilot/heading_dial_deg_mag_pilot")
simDR_autopilot_heading_deg = find_dataref("sim/cockpit/autopilot/heading_mag")
simDR_autopilot_vs_fpm = find_dataref("sim/cockpit2/autopilot/vvi_dial_fpm")
B747DR_autopilot_vs_fpm = find_dataref("laminar/B747/cockpit2/autopilot/vvi_dial_fpm")
simDR_hsi_vdef_dots_pilot           = find_dataref("sim/cockpit2/radios/indicators/hsi_vdef_dots_pilot")

simDR_hsi_ldef_dots_nav1           = find_dataref("sim/cockpit2/radios/indicators/nav1_hdef_dots_pilot")
simDR_hsi_ldef_dots_nav2           = find_dataref("sim/cockpit2/radios/indicators/nav2_hdef_dots_pilot")
simDR_hsi_nav1_horizontal_signal           = find_dataref("sim/cockpit2/radios/indicators/nav1_display_horizontal")
simDR_hsi_nav2_horizontal_signal           = find_dataref("sim/cockpit2/radios/indicators/nav2_display_horizontal")
simDR_hsi_nav1_vertical_signal           = find_dataref("sim/cockpit2/radios/indicators/nav1_display_vertical")
simDR_hsi_nav2_vertical_signal           = find_dataref("sim/cockpit2/radios/indicators/nav2_display_vertical")


simDR_autopilot_state = find_dataref("sim/cockpit/autopilot/autopilot_state")
simDR_autopilot_vs_status = find_dataref("laminar/B747/autopilot/vvi_status")
simDR_autopilot_flch_status = find_dataref("laminar/B747/autopilot/speed_status")
simDR_autopilot_TOGA_vert_status = find_dataref("sim/cockpit2/autopilot/TOGA_status")
B747DR_autopilot_TOGA_status     	= deferred_dataref("laminar/B747/autopilot/TOGA_status","number")
simDR_autopilot_TOGA_lat_status = find_dataref("sim/cockpit2/autopilot/TOGA_lateral_status")
simDR_autopilot_heading_status = find_dataref("sim/cockpit2/autopilot/heading_status")
simDR_autopilot_heading_hold_status = find_dataref("sim/cockpit2/autopilot/heading_hold_status")
simDR_autopilot_alt_hold_status = find_dataref("laminar/B747/autopilot/altitude_hold_status")
B747DR_ap_approach_mode = find_dataref("laminar/B747/autopilot/approach_mode")

--simDR_autopilot_nav_status = find_dataref("sim/cockpit2/autopilot/nav_status")
--simDR_autopilot_gs_status = find_dataref("sim/cockpit2/autopilot/glideslope_status")
simDR_autopilot_nav_status = find_dataref("laminar/B747/autopilot/actual_nav_status")
simDR_autopilot_gs_status = find_dataref("laminar/B747/autopilot/actual_glideslope_status")


B747DR_autopilot_nav_status = find_dataref("laminar/B747/autopilot/nav_status")
B747DR_autopilot_gs_status = find_dataref("laminar/B747/autopilot/glideslope_status")
simDR_nav1_gs_flag = find_dataref("sim/cockpit2/radios/indicators/nav1_flag_glideslope")
simDR_nav2_gs_flag = find_dataref("sim/cockpit2/radios/indicators/nav2_flag_glideslope")
simDR_autopilot_approach_status = find_dataref("sim/cockpit2/autopilot/approach_status")
simDR_autopilot_roll_sync_degrees = find_dataref("sim/cockpit2/autopilot/sync_hold_roll_deg")
simDR_autopilot_roll_status = find_dataref("sim/cockpit2/autopilot/roll_status")
simDR_autopilot_servos_on = find_dataref("laminar/B747/autopilot/servos_on")

simDR_autopilot_fms_vnav = find_dataref("sim/cockpit2/autopilot/fms_vnav")
simDR_autopilot_gpss = find_dataref("sim/cockpit2/autopilot/gpss_status")
simDR_autopilot_pitch = find_dataref("sim/cockpit2/autopilot/pitch_status")
B747DR_capt_ap_roll = find_dataref("laminar/B747/autopilot/capt_roll_ref")
B747DR_fo_ap_roll = find_dataref("laminar/B747/autopilot/fo_roll_ref")
B747DR_ap_target_roll = find_dataref("sim/cockpit2/autopilot/flight_director_roll_deg")
simDR_ap_aileron_trim = find_dataref("sim/cockpit2/controls/aileron_trim")
simDR_fo_roll = find_dataref("sim/cockpit2/gauges/indicators/roll_AHARS_deg_copilot")
simDR_capt_roll = find_dataref("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot")
simDR_airspeed_mach = find_dataref("sim/flightmodel/misc/machno")
simDR_vvi_fpm_pilot = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
simDR_ind_airspeed_kts_pilot = find_dataref("laminar/B747/gauges/indicators/airspeed_kts_pilot")
simDR_groundspeed = find_dataref("sim/flightmodel/position/groundspeed")
simDR_latitude = find_dataref("sim/flightmodel/position/latitude")
simDR_longitude = find_dataref("sim/flightmodel/position/longitude")
B747DR_airspeed_Vmc = find_dataref("laminar/B747/airspeed/Vmc")
B747DR_airspeed_Vmo = find_dataref("laminar/B747/airspeed/Vmo")
simDR_flap_ratio_control = find_dataref("sim/cockpit2/controls/flap_ratio") -- FLAP HANDLE
simDR_autopilot_nav_source = find_dataref("sim/cockpit2/radios/actuators/HSI_source_select_pilot")
simDR_AHARS_roll_deg_pilot = find_dataref("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot")
--simDR_AHARS_heading_deg_pilot       	= find_dataref("sim/cockpit2/gauges/indicators/ground_track_mag_pilot")--find_dataref("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot")
simDR_AHARS_heading_deg_pilot = find_dataref("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot")
simDR_nav1_radio_course_deg = find_dataref("sim/cockpit2/radios/actuators/nav1_course_deg_mag_pilot")
simDR_pressureAlt1 = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
simDR_radarAlt1 = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
simDR_radarAlt2 = find_dataref("sim/cockpit2/guages/indicators/radio_altimeter_height_ft_copilot")
simDR_allThrottle = 0 --find_dataref("sim/cockpit2/engine/actuators/throttle_ratio_all")
simDR_override_throttles = find_dataref("sim/operation/override/override_throttles")
simDR_descent = find_dataref("sim/cockpit2/autopilot/des_adjust")
simDR_pitch = find_dataref("sim/cockpit2/autopilot/sync_hold_pitch_deg")
simDR_touchGround = find_dataref("sim/flightmodel/failures/onground_any")
simDR_onGround = find_dataref("sim/flightmodel/failures/onground_any")
--simDR_pitch2           	= find_dataref("sim/cockpit2/autopilot/fpa")
B744_fpm = find_dataref("laminar/B747/vsi/fpm")
B747BR_showFMA				= deferred_dataref("laminar/B747/autopilot/FMA/showFMA", "number")
simDR_AHARS_pitch_heading_deg_pilot = find_dataref("sim/cockpit2/gauges/indicators/pitch_AHARS_deg_pilot")
--simDR_AHARS_pitch_heading_deg_pilot=find_dataref("sim/cockpit2/gauges/indicators/ground_track_mag_pilot")
simDR_elevator = find_dataref("sim/flightmodel2/controls/elevator_trim")
simDR_rudder = find_dataref("sim/flightmodel2/controls/rudder_trim")
--simDR_roll=find_dataref("sim/cockpit2/controls/total_roll_ratio")

--simDR_elevator =find_dataref("sim/joystick/artstab_pitch_ratio")--	float	y	[-1..1]	The artificial stability input modifications for pitch. Use override_artstab
simDR_roll = find_dataref("sim/joystick/artstab_roll_ratio")
 --	float	y	[-1..1]	The artificial stability input modifications for roll. Use override_artstab
--simDR_rudder=find_dataref("sim/joystick/artstab_heading_ratio")

simDR_reqHeading = find_dataref("sim/cockpit2/radios/actuators/hsi_obs_deg_mag_pilot")

--simDR_overRideStab = find_dataref("sim/operation/override/override_artstab")
simDR_nav1_radio_nav_type = find_dataref("sim/cockpit2/radios/indicators/nav1_type")
toderate = deferred_dataref("laminar/B747/engine/derate/TO", "number")
clbderate = deferred_dataref("laminar/B747/engine/derate/CLB", "number")
throttlederate = find_dataref("sim/aircraft/engine/acf_throtmax_FWD") -- can use this for engine type?
--[[
    0 = UNKNONW
    4 = VOR
    8 = ILS WITHOUT GLIDESLOPE
   16 = LOCALIZER (ONLY)
   32 = GLIDESLOPE
   40 = ILS WITH GLIDESLOPE
-]]
-- Datarefs for cost index calculations
gwtKG = find_dataref("sim/flightmodel/weight/m_total") -- kilograms
simDR_TAS_mps = find_dataref("sim/flightmodel/position/true_airspeed") -- true airspeed in meters per second
simDR_GS_mps = find_dataref("sim/flightmodel/position/groundspeed") -- ground airspeed in meters per secon

--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_toggle_switch_position = find_dataref("laminar/B747/toggle_switch/position")
B747DR_CAS_caution_status = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_speedbrake_lever = find_dataref("laminar/B747/flt_ctrls/speedbrake_lever")
B747DR_ap_autoland = deferred_dataref("laminar/B747/autopilot/autoland", "number")
B747DR_ap_autoland = 0
B744DR_autolandPitch = find_dataref("laminar/B747/autopilot/autolandPitch")
B747DR_lastap_dial_airspeed = deferred_dataref("laminar/B747/autopilot/ap_monitor/last_airspeed", "number")
B747DR_max_dial_machspeed = deferred_dataref("laminar/B747/autopilot/ap_monitor/max_dial_machspeed", "number")
B747DR_target_descentAlt = deferred_dataref("laminar/B747/autopilot/ap_monitor/target_descentAlt", "number")
B747DR_target_descentSpeed = deferred_dataref("laminar/B747/autopilot/ap_monitor/target_descentSpeed", "number")
B747DR_descentSpeedGradient = deferred_dataref("laminar/B747/autopilot/ap_monitor/descentSpeedGradient", "number")
B747DR_switchingIASMode = deferred_dataref("laminar/B747/autopilot/ap_monitor/switchingIASMode", "number")
B747DR_fmstargetIndex = deferred_dataref("laminar/B747/autopilot/ap_monitor/fmstargetIndex", "number")
B747DR_fmstargetDistance           = deferred_dataref("laminar/B747/autopilot/ap_monitor/fmstargetDistance", "number")
B747DR_fmscurrentIndex = deferred_dataref("laminar/B747/autopilot/ap_monitor/fmscurrentIndex", "number")
B747DR_mcp_hold = deferred_dataref("laminar/B747/autopilot/ap_monitor/mcp_hold", "number")
B747DR_mcp_hold_pressed = deferred_dataref("laminar/B747/autopilot/ap_monitor/mcp_hold_pressed", "number")
--*************************************************************************************--
--** 				             FIND X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

--simCMD_autopilot_autothrottle_on = find_command("sim/autopilot/autothrottle_on")
--simCMD_autopilot_autothrottle_off = find_command("sim/autopilot/autothrottle_off")
--simCMD_autopilot_toggle_knots_mach  	= find_command("sim/autopilot/knots_mach_toggle")
simCMD_autopilot_roll_center_sync_mode = find_command("sim/autopilot/override_center")
simCMD_autopilot_roll_right_sync_mode = find_command("sim/autopilot/override_right")
simCMD_autopilot_servos_on = find_command("sim/autopilot/servos_on")
simCMD_autopilot_servos_fdir_off = find_command("sim/autopilot/servos_fdir_off")
simCMD_autopilot_servos2_on = find_command("sim/autopilot/servos2_on")
simCMD_autopilot_servos2_fdir_off = find_command("sim/autopilot/servos_fdir2_off")
simCMD_autopilot_servos3_on = find_command("sim/autopilot/servos3_on")
simCMD_autopilot_servos3_fdir_off = find_command("sim/autopilot/servos_fdir3_off")
simCMD_autopilot_servos_off = find_command("sim/autopilot/servos_off_any")
simCMD_autopilot_fdir_off = find_command("sim/autopilot/servos_fdir_off")
simCMD_autopilot_fdir_servos_down_one = find_command("sim/autopilot/fdir_servos_down_one")
simCMD_autopilot_pitch_sync = find_command("sim/autopilot/pitch_sync")
simCMD_autopilot_set_nav1_as_nav_source = find_command("sim/autopilot/hsi_select_nav_1")
simCMD_autopilot_nav_mode = find_command("sim/autopilot/NAV")
simCMD_autopilot_wing_leveler = find_command("sim/autopilot/wing_leveler")
simCMD_autopilot_heading_select = find_command("sim/autopilot/heading")
simCMD_autopilot_vert_speed_mode = find_command("sim/autopilot/vertical_speed")
simCMD_autopilot_flch_mode = find_command("sim/autopilot/level_change")

--simCMD_autopilot_alt_hold_mode = find_command("sim/autopilot/altitude_hold")
simCMD_autopilot_glideslope_mode = find_command("sim/autopilot/glide_slope")


--*************************************************************************************--
--** 				              FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747DR_engine_TOGA_mode = find_dataref("laminar/B747/engines/TOGA_mode")

B747DR_autothrottle_fail = find_dataref("laminar/B747/engines/autothrottle_fail")

B747DR_hyd_sys_pressure_1      = deferred_dataref("laminar/B747/hydraulics/pressure_1", "number") -- AP C
B747DR_hyd_sys_pressure_2      = deferred_dataref("laminar/B747/hydraulics/pressure_2", "number") -- AP R
B747DR_hyd_sys_pressure_3      = deferred_dataref("laminar/B747/hydraulics/pressure_3", "number") -- AP L

B747DR_radioModes = deferred_dataref("laminar/B747/radio/tuningmodes", "string")
B747DR_FMSdata = deferred_dataref("laminar/B747/fms/data", "string")
--B747DR_efis_baro_capt_set_dial_pos              = deferred_dataref("laminar/B747/efis/baro/capt/set_dial_pos", "number")
B747DR_efis_baro_std_capt_switch_pos = deferred_dataref("laminar/B747/efis/baro_std/capt/switch_pos", "number")
B747DR_efis_baro_capt_preselect = deferred_dataref("laminar/B747/efis/baro/capt/preselect", "number")
B747DR_efis_baro_std_fo_switch_pos = deferred_dataref("laminar/B747/efis/baro_std/fo/switch_pos", "number")
simDR_altimeter_baro_inHg = find_dataref("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")
simDR_altimeter_baro_inHg_fo = find_dataref("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_copilot")
--B747DR_efis_baro_fo_set_dial_pos                = deferred_dataref("laminar/B747/efis/baro/fo/set_dial_pos", "number")
B747DR_efis_baro_fo_preselect = deferred_dataref("laminar/B747/efis/baro/fo/preselect", "number")
B747DR_ap_button_switch_position =
	deferred_dataref("laminar/B747/autopilot/button_switch/position", "array[" .. tostring(NUM_AUTOPILOT_BUTTONS) .. "]")
B747DR_ap_bank_limit_sel_dial_pos = deferred_dataref("laminar/B747/autopilot/bank_limit/sel_dial_pos", "number")
B747DR_ap_ias_mach_window_open = deferred_dataref("laminar/B747/autopilot/ias_mach/window_open", "number")
B747DR_ap_vs_window_open = deferred_dataref("laminar/B747/autopilot/vert_spd/window_open", "number")
B747DR_ap_vs_show_thousands = deferred_dataref("laminar/B747/autopilot/vert_speed/show_thousands", "number")
--B747DR_ap_hdg_hold_mode             	= deferred_dataref("laminar/B747/autopilot/heading_hold_mode", "number")
--B747DR_ap_hdg_sel_mode              	= deferred_dataref("laminar/B747/autopilot/heading_sel_mode", "number")
B747DR_autopilot_altitude_ft = find_dataref("laminar/B747/autopilot/heading/altitude_dial_ft")
B747DR_autopilot_altitude_ft_pfd = deferred_dataref("laminar/B747/autopilot/heading/altitude_dial_ft_pfd", "number")
B747DR_ap_heading_deg = deferred_dataref("laminar/B747/autopilot/heading/degrees", "number")
B747DR_ap_target_heading_deg = deferred_dataref("laminar/B747/autopilot/heading/target", "number")
B747DR_ap_target_speed               	= deferred_dataref("laminar/B747/autopilot/speed/target", "number")
B747DR_ap_target_altitude               	= deferred_dataref("laminar/B747/autopilot/altitude/target", "number")
B747DR_ap_target_vertspeed               	= deferred_dataref("laminar/B747/autopilot/vertspeed/target", "number")
B747DR_ap_target_flaps   = deferred_dataref("laminar/B747/autopilot/flaps/target", "number")
B747DR_ap_ias_dial_value = deferred_dataref("laminar/B747/autopilot/ias_dial_value", "number")
B747DR_ap_ias_bug_value = deferred_dataref("laminar/B747/autopilot/ias_bug_value", "number")
B747DR_ap_ias_bug_value_pfd = deferred_dataref("laminar/B747/autopilot/ias_bug_value_pfd", "number")
B747DR_ap_ias_mach_dial_value = deferred_dataref("laminar/B747/autopilot/ias_mach_dial_value", "number") -- display only
B747DR_airspeed_V2 = deferred_dataref("laminar/B747/airspeed/V2", "number")
B747DR_ap_vnav_system = deferred_dataref("laminar/B747/autopilot/vnav_system", "number")
B747DR_ap_vnav_target_alt = deferred_dataref("laminar/B747/autopilot/vnav_target_alt", "number")
B747DR_ap_vnav_state = deferred_dataref("laminar/B747/autopilot/vnav_state", "number")
B747DR_ap_lnav_state = deferred_dataref("laminar/B747/autopilot/lnav_state", "number")
B747DR_ap_inVNAVdescent = deferred_dataref("laminar/B747/autopilot/vnav_descent", "number")
B747DR_ap_inDescent 		= deferred_dataref("laminar/B747/autopilot/vnav/after_tod", "number")
B747DR_ap_flightPhase = deferred_dataref("laminar/B747/autopilot/flightPhase", "number")
B747DR_ap_active_land = deferred_dataref("laminar/B747/autopilot/active_land", "number")
-- 0 take off
-- 1 climb
-- 2 cruise
-- 3 descend
-- 4 landing
B747DR_airspeed_Mms = deferred_dataref("laminar/B747/airspeed/Mms", "number")
B747DR_ap_vvi_fpm = deferred_dataref("laminar/B747/autopilot/vvi_fpm", "number")
B747DR_ap_alt_show_thousands = deferred_dataref("laminar/B747/autopilot/altitude/show_thousands", "number")
B747DR_ap_alt_show_tenThousands = deferred_dataref("laminar/B747/autopilot/altitude/show_tenThousands", "number")
B747DR_ap_cmd_L_mode = deferred_dataref("laminar/B747/autopilot/cmd_L_mode/status", "number")
B747DR_ap_cmd_C_mode = deferred_dataref("laminar/B747/autopilot/cmd_C_mode/status", "number")
B747DR_ap_cmd_R_mode = deferred_dataref("laminar/B747/autopilot/cmd_R_mode/status", "number")
B747DR_ap_autothrottle_armed = deferred_dataref("laminar/B747/autothrottle/armed", "number")
B747DR_ap_mach_decimal_visibiilty = deferred_dataref("laminar/B747/autopilot/mach_dec_vis", "number")
B747DR_ap_fpa = deferred_dataref("laminar/B747/autopilot/navadata/fpa", "number")
B747DR_ap_vb = deferred_dataref("laminar/B747/autopilot/navadata/vb", "number")

B747DR_ap_FMA_autothrottle_mode_box_status =
	deferred_dataref("laminar/B747/autopilot/FMA/autothrottle/mode_box_status", "number")
B747DR_ap_roll_mode_box_status = deferred_dataref("laminar/B747/autopilot/FMA/roll/mode_box_status", "number")
B747DR_ap_pitch_mode_box_status = deferred_dataref("laminar/B747/autopilot/FMA/pitch/mode_box_status", "number")
B747DR_ap_ATT     	                = deferred_dataref("laminar/B747/autopilot/att_rate", "number")
B747DR_ap_FMA_autothrottle_mode = deferred_dataref("laminar/B747/autopilot/FMA/autothrottle_mode", "number")
--[[
    0 = NONE
    1 = HOLD
    2 = IDLE
    3 = SPD
    4 = THR
    5 = THR REF
--]]
B747DR_ap_FMA_armed_roll_mode = deferred_dataref("laminar/B747/autopilot/FMA/armed_roll_mode", "number")
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
B747DR_ap_FMA_active_roll_mode = deferred_dataref("laminar/B747/autopilot/FMA/active_roll_mode", "number")
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
B747DR_ap_FMA_armed_pitch_mode = deferred_dataref("laminar/B747/autopilot/FMA/armed_pitch_mode", "number")
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
B747DR_ap_FMA_active_pitch_mode = deferred_dataref("laminar/B747/autopilot/FMA/active_pitch_mode", "number")
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
B747DR_ap_AFDS_mode_box_status_pilot = deferred_dataref("laminar/B747/autopilot/AFDS/mode_box_status_pilot", "number")
B747DR_ap_AFDS_mode_box_status_copilot =
	deferred_dataref("laminar/B747/autopilot/AFDS/mode_box_status_copilot", "number")
B747DR_ap_AFDS_mode_box2_status_pilot = deferred_dataref("laminar/B747/autopilot/AFDS/mode_box2_status_pilot", "number")
B747DR_ap_AFDS_mode_box2_status_copilot =
	deferred_dataref("laminar/B747/autopilot/AFDS/mode_box2_status_copilot", "number")

B747DR_ap_AFDS_status_annun_pilot = deferred_dataref("laminar/B747/autopilot/AFDS/status_annun_pilot", "number")
B747DR_ap_AFDS_status_annun_copilot = deferred_dataref("laminar/B747/autopilot/AFDS/status_annun_copilot", "number")
--[[
    0 = NONE
    1 = FD
    2 = CMD
    3 = LAND 2
    4 = LAND 3
    5 = NO AUTOLAND
--]]
--Marauder28
B747DR_ref_thr_limit_mode = deferred_dataref("laminar/B747/engines/ref_thr_limit_mode", "string")
--[[
    ["NONE"]
    ["TO"]
    ["TO 1"]
    ["TO 2"]
    ["D-TO"]
    ["D-TO 1"]
    ["D-TO 2"]
    ["CLB"]
    ["CLB 1"]
    ["CLB 2"]
    ["CRZ"]
    ["CON"]
    ["GA"]
]]
-- Holds all SimConfig options
B747DR_simconfig_data = deferred_dataref("laminar/B747/simconfig", "string")
B747DR_newsimconfig_data = deferred_dataref("laminar/B747/newsimconfig", "number")
--Simulator Config Options
simConfigData = {}

--Marauder28
if string.len(B747DR_simconfig_data) > 1 then
	simConfigData["data"] = json.decode(B747DR_simconfig_data)
end
--Marauder28

--Marauder28

--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--

--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

--*************************************************************************************--
--** 				             CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--
function B747_animate_value(current_value, target, min, max, speed)
	local fps_factor = math.min(0.1, speed * SIM_PERIOD)

	if target >= (max - 0.001) and current_value >= (max - 0.01) then
		return max
	elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
		return min
	else
		return current_value + ((target - current_value) * fps_factor)
	end
end
function isATEnabled()
	if B747DR_toggle_switch_position[29] == 1 and B747DR_autothrottle_fail == 0 then return true end
	return false
end
dofile("B747.70.xt.autopilot.vnav.lua")
function autothrottle_reengage()
	if B747DR_autothrottle_active == 0 and isATEnabled() and simDR_onGround == 0 then
		--simCMD_autopilot_autothrottle_on:once()
		B747DR_autothrottle_active=1
	end
end

function B747_ap_thrust_mode_CMDhandler(phase, duration) -- INOP, NO CORRESPONDING FUNCTIONALITY IN X-PLANE
	if phase == 0 then
		B747_ap_button_switch_position_target[0] = 1
		--simCMD_autopilot_autothrottle_off:once()
		B747DR_autothrottle_active=0
		B747DR_ap_lastCommand = simDRTime
		if simDR_radarAlt1 > 400 then
			B747DR_ap_thrust_mode = 3
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[0] = 0
	end
end

function B747_ap_switch_speed_mode_CMDhandler(phase, duration)
	print("B747_ap_switch_speed_mode_CMDhandler "..phase.." "..duration)
	if phase == 0 then
		B747CMD_fdr_log_spd:once()
		B747_ap_button_switch_position_target[1] = 1 -- SET THE SPEED SWITCH ANIMATION TO "IN"
		B747DR_ap_lastCommand = simDRTime

		if isATEnabled() and simDR_onGround == 0 then -- AUTOTHROTTLE ""ARM" SWITCH IS "ON"

			B747DR_autothrottle_active=1

			if B747DR_engine_TOGA_mode > 0 then
				B747DR_engine_TOGA_mode = 0
			end -- CANX ENGINE TOGA IF ACTIVE
		end
		B747DR_ap_vnav_state = 0
		B747DR_ap_inVNAVdescent = 0
		if simDR_autopilot_flch_status~=0 then
		 simDR_autopilot_flch_status=0
		 if simDR_autopilot_vs_status==0 and  simDR_autopilot_alt_hold_status==0 then
			simDR_autopilot_vs_status=2
		 end
		end
		--B747DR_ap_flightPhase = 2
		if B747DR_autopilot_altitude_ft > simDR_pressureAlt1 then
			B747DR_ap_flightPhase = 1
		else
			B747DR_ap_flightPhase = 3
		end
		--print("B747DR_ap_thrust_mode " .. B747DR_ap_thrust_mode)
		B747DR_ap_thrust_mode = 0
		--print("B747DR_ap_thrust_mode " .. B747DR_ap_thrust_mode)
		if B747DR_switchingIASMode == 0 then
			if simDR_autopilot_airspeed_is_mach == 0 then
				simDR_autopilot_airspeed_kts = B747DR_ap_ias_dial_value
			elseif simDR_autopilot_airspeed_is_mach == 1 and B747DR_ap_ias_dial_value * 0.01 then
				simDR_autopilot_airspeed_kts_mach = B747DR_ap_ias_dial_value * 0.01 ---roundToIncrement(B747DR_ap_ias_dial_value, 1) * 0.01
			end
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[1] = 0 -- SET THE SPEED SWITCH ANIMATION TO "OUT"
	end
end
function B747_ap_switch_vnavspeed_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_spdmod:once()
		if B747_ap_button_switch_position_target[15] == 1 then
			B747_ap_button_switch_position_target[15] = 0
			return
		end
		B747_ap_button_switch_position_target[15] = 1 -- SET THE SPEED KNOB ANIMATION TO "IN"
		if B747DR_ap_vnav_state == 2 and B747DR_switchingIASMode==0 then
			setVNAVState("manualVNAVspd", 1 - getVNAVState("manualVNAVspd"))
			if getVNAVState("manualVNAVspd") == 0 then
				setVNAVState("gotVNAVSpeed", false)
				B747_vnav_speed()
			end
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[15] = 0 -- SET THE SPEED KNOB ANIMATION TO "OUT"
	end
end

function update_new_crzalt()
	print("doing set new cruise to "..B747BR_cruiseAlt)
	if simDR_autopilot_alt_hold_status==2 and B747DR_ap_vnav_state>1 then
		B747DR_mcp_hold = 0
		simDR_autopilot_alt_hold_status=0
		if B747DR_autopilot_altitude_ft > simDR_pressureAlt1 then
			B747DR_ap_flightPhase = 1
		else
			B747DR_ap_flightPhase = 3
		end
		B747DR_mcp_hold_pressed = simDRTime
		setVNAVState("vnavcalcwithTargetAlt", 0)
		if getVNAVState("manualVNAVspd") == 0 then
			setVNAVState("gotVNAVSpeed", false)
			B747_vnav_speed()
		end

		if B747DR_ap_vnav_state == 2 then
			B747DR_ap_vnav_state = 3 --resume
		end
		if B747BR_totalDistance - B747BR_tod <= 50 then
			B747DR_ap_inVNAVdescent = 1
			B747DR_ap_flightPhase = 3
			setDescent(true)
			print("Begin descent 1")
			getDescentTarget()
		end
	end
end

function B747_ap_switch_vnavalt_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_altmod:once()
		B747DR_ap_lastCommand = simDRTime
		print("vnav alt button")

		if B747_ap_button_switch_position_target[16] == 1 then
			B747_ap_button_switch_position_target[16] = 0
			return
		end

		B747_ap_button_switch_position_target[16] = 1 -- SET THE ALT KNOB ANIMATION TO "IN"

		if B747DR_autopilot_altitude_ft > B747BR_cruiseAlt then
			B747BR_cruiseAlt = B747DR_autopilot_altitude_ft
			print("set new cruise to "..B747BR_cruiseAlt)
			if is_timer_scheduled(update_new_crzalt) then
				stop_timer(update_new_crzalt)
			end
			run_after_time(update_new_crzalt, 2.0)
			B747DR_mcp_hold_pressed = simDRTime
			return
		end

		if simDR_autopilot_alt_hold_status==2 and B747DR_ap_vnav_state>1 then
			simDR_autopilot_altitude_ft=B747DR_autopilot_altitude_ft

			if B747DR_autopilot_altitude_ft > simDR_pressureAlt1 then

				B747DR_ap_flightPhase = 1
			else
				B747DR_ap_flightPhase = 3
			end
			B747DR_mcp_hold = 0
			simDR_autopilot_alt_hold_status=0
			B747DR_mcp_hold_pressed = simDRTime
			setVNAVState("vnavcalcwithTargetAlt", 0)
			if getVNAVState("manualVNAVspd") == 0 then
				setVNAVState("gotVNAVSpeed", false)
				B747_vnav_speed()
			end

			if B747DR_ap_vnav_state == 2 then
				B747DR_ap_vnav_state = 3 --resume
			end
			if B747BR_totalDistance - B747BR_tod <= 50 then
				B747DR_ap_inVNAVdescent = 1
				B747DR_ap_flightPhase = 3
				setDescent(true)
				print("Begin descent 2")
				getDescentTarget()
			end
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[16] = 0 -- SET THE ALT KNOB ANIMATION TO "OUT"
	end
end

function B747_ap_ias_mach_sel_button_CMDhandler(phase, duration) -- INOP, NO CORRESPONDING FUNCTIONALITY IN X-PLANE
	-- print("B747_ap_ias_mach_sel_button_CMDhandler")
	if phase == 0 then
		if simDR_autopilot_airspeed_is_mach == 0 then
			B747DR_ap_ias_dial_value = math.floor(simDR_ind_airspeed_kts_pilot)
		else
			B747DR_ap_ias_dial_value = math.floor(simDR_airspeed_mach * 100)
		end

	-- TODO: IN VNAV THIS ALTERNATELY OPENS AND CLOSES IAS/MACH WINDOW AND CONTROLS VNAV INTERACTION (FCOM Pg 643)
	-- TODO: CURRENTLY INOP - THE CURRENT XP FMS DOES NOT ALLOW THIS OPTION
	end
end

function B747_ap_switch_flch_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_flch:once()
		B747_ap_button_switch_position_target[4] = 1
		B747DR_ap_lastCommand = simDRTime
		simDR_autopilot_altitude_ft = B747DR_autopilot_altitude_ft
		simDR_autopilot_hold_altitude_ft=simDR_autopilot_altitude_ft
		B747DR_autopilot_TOGA_status=0
		if B747DR_ap_vnav_state == 0 or (simDR_autopilot_flch_status == 0 and B747DR_ap_vnav_state > 0) then
			simCMD_autopilot_flch_mode:once()
			simDR_autopilot_flch_status=2
            simDR_autopilot_vs_status=0
            simDR_autopilot_alt_hold_status=0
			--simDR_autopilot_flch_status=2

		end
		simDR_autopilot_alt_hold_status=0
		B747DR_ap_vnav_state = 0
		B747DR_ap_inVNAVdescent = 0
		if B747DR_autopilot_altitude_ft > simDR_pressureAlt1 then
			B747DR_ap_flightPhase = 1
		else
			B747DR_ap_flightPhase = 3
		end
		B747DR_ap_thrust_mode = 2
	elseif phase == 2 then
		B747_ap_button_switch_position_target[4] = 0
	end
end

function B747_ap_switch_vs_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_vs:once()
		local cAlt = simDR_radarAlt1
		B747_ap_button_switch_position_target[6] = 1
		--for animation

		if B747DR_autothrottle_active == 0 and isATEnabled() and simDR_onGround == 0 then -- AUTOTHROTTLE IS "OFF"
			--simCMD_autopilot_autothrottle_on:once() -- ACTIVATE THE AUTOTHROTTLE
			B747DR_autothrottle_active=1

		end
		B747DR_engine_TOGA_mode = 0
		B747DR_autopilot_TOGA_status=0
		simDR_autopilot_altitude_ft = B747DR_autopilot_altitude_ft
		simDR_autopilot_hold_altitude_ft=simDR_autopilot_altitude_ft
		simDR_autopilot_alt_hold_status=0
		B747DR_ap_thrust_mode = 0
		B747DR_ap_inVNAVdescent = 0
		if B747DR_autopilot_altitude_ft > simDR_pressureAlt1 then
			B747DR_ap_flightPhase = 1
		else
			B747DR_ap_flightPhase = 3
		end
		if B747DR_ap_vnav_state == 0 or (simDR_autopilot_vs_status == 0 and B747DR_ap_vnav_state > 0) then
			simCMD_autopilot_vert_speed_mode:once()
			simDR_autopilot_vs_status=2
			simDR_autopilot_vs_fpm = 0
			B747DR_ap_vvi_fpm = 0
			B747DR_autopilot_vs_fpm = 0
		end
		B747DR_ap_vnav_state = 0
	elseif phase == 2 then
	--for autpilot
	end
end

function B747_ap_alt_hold_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_alt:once()
		B747_ap_button_switch_position_target[7] = 1
		if B747DR_autothrottle_active == 0 and isATEnabled() then -- AUTOTHROTTLE IS "OFF"
			--simCMD_autopilot_autothrottle_on:once() -- ACTIVATE THE AUTOTHROTTLE
			B747DR_autothrottle_active=1
			B747DR_engine_TOGA_mode = 0
		end

		if simDR_autopilot_alt_hold_status == 2 and B747DR_ap_vnav_state > 0 then
			print("dont leave alt hold")
			simDR_autopilot_hold_altitude_ft=simDR_pressureAlt1
		else
			--simCMD_autopilot_alt_hold_mode:once()
			simDR_autopilot_alt_hold_status = 2
			simDR_autopilot_vs_status=0
            simDR_autopilot_flch_status=0
			simDR_autopilot_hold_altitude_ft=simDR_pressureAlt1
		end
		B747DR_ap_thrust_mode = 0
		B747DR_ap_vnav_state = 0
		B747DR_ap_inVNAVdescent = 0
		B747DR_ap_flightPhase = 2
		B747DR_autopilot_TOGA_status=0
	elseif phase == 2 then
		B747_ap_button_switch_position_target[7] = 0
	end
end


function B747_ap_switch_cmd_L_CMDhandler(phase, duration)
	print("B747_ap_switch_cmd_L_CMDhandler "..phase.." "..duration)
	if phase == 0 then
		--B747CMD_ap_reset:once()
		B747CMD_fdr_log_apon:once()
		B747DR_CAS_warning_status[0] = 0
		if B747DR_ap_button_switch_position[14] == 0 then -- DISENGAGE BAR IS "UP/OFF"
			if B747DR_ap_cmd_L_mode == 0 and simDR_radarAlt1>400 and (B747DR_ap_cmd_R_mode+B747DR_ap_cmd_C_mode)==0 then -- LEFT CMD AP MODE IS "OFF"
				if simDR_autopilot_servos_on == 0 then -- AUTOPILOT IS NOT ENGAGED
					--simCMD_autopilot_servos_on:once()

					B747DR_switching_servos_on = simDRTime -- TURN THE AP SERVOS "ON"
					simDR_autopilot_servos_on=1
				end
				B747DR_ap_cmd_L_mode = 1 -- SET AP CMD L MODE TO "ON"
			end
		end
	elseif phase == 1 then
		B747_ap_button_switch_position_target[10] = 1 -- SET THE BUTTON ANIMATION TO "DOWN"
	elseif phase == 2 then
		B747_ap_button_switch_position_target[10] = 0 -- SET THE BUTTON ANIMATION TO "UP"

	end
end

function B747_ap_switch_cmd_C_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_apon:once()
		B747_ap_button_switch_position_target[11] = 1 -- SET THE BUTTON ANIMATION TO "DOWN"
		B747DR_CAS_warning_status[0] = 0
	elseif phase == 2 then
		B747_ap_button_switch_position_target[11] = 0 -- SET THE BUTTON ANIMATION TO "UP"
		if B747DR_ap_button_switch_position[14] == 0 then -- DISENGAGE BAR IS "UP/OFF"
			if B747DR_ap_cmd_C_mode == 0 and simDR_radarAlt1>400 and (B747DR_ap_cmd_L_mode+B747DR_ap_cmd_R_mode)==0 then -- CENTER CMD AP MODE IS "OFF"
				if simDR_autopilot_servos_on == 0 then -- AUTOPILOT IS NOT ENGAGED
					--simCMD_autopilot_servos2_on:once()
					--simCMD_autopilot_servos_on:once()
					simDR_autopilot_servos_on=1
					B747DR_switching_servos_on = simDRTime
				end
				B747DR_ap_cmd_C_mode = 1 -- SET AP CMD C MODE TO "ON"
			end
		end
	end
end

function B747_ap_switch_cmd_R_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_apon:once()
		B747_ap_button_switch_position_target[12] = 1 -- SET THE BUTTON ANIMATION TO "DOWN"
		B747DR_CAS_warning_status[0] = 0
	elseif phase == 2 then
		B747_ap_button_switch_position_target[12] = 0 -- SET THE BUTTON ANIMATION TO "UP"
		if B747DR_ap_button_switch_position[14] == 0 then -- DISENGAGE BAR IS "UP/OFF"
			if B747DR_ap_cmd_R_mode == 0 and simDR_radarAlt1>400 and (B747DR_ap_cmd_L_mode+B747DR_ap_cmd_C_mode)==0 then -- RIGHT CMD AP MODE IS "OFF"
				if simDR_autopilot_servos_on == 0 then -- AUTOPILOT IS NOT ENGAGED
					--simCMD_autopilot_servos3_on:once()
					--simCMD_autopilot_servos_on:once()
					simDR_autopilot_servos_on=1
					B747DR_switching_servos_on = simDRTime
				end
				B747DR_ap_cmd_R_mode = 1 -- SET AP CMD R MODE TO "ON"
			end
		end
	end
end

function B747_ap_switch_disengage_bar_CMDhandler(phase, duration) --disengage bar
	if phase == 0 then
		B747CMD_fdr_log_apdisconnect:once()
		B747_ap_button_switch_position_target[14] = 1.0 - B747_ap_button_switch_position_target[14]
		B747DR_ap_lastCommand = simDRTime
		if B747_ap_button_switch_position_target[14] == 1.0 then -- DISENGAGE
			local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
			if numAPengaged > 0 then
				B747DR_CAS_warning_status[0] = 1
			end
			if B747DR_autothrottle_active == 1 then
				run_after_time(autothrottle_reengage,0.5)
			end
			B747CMD_ap_reset:once() -- TURN FLIGHT DIRECTOR AND SERVOS "OFF"
			B747_ap_all_cmd_modes_off()
			B747DR_ap_lastCommand=simDRTime
			simCMD_autopilot_servos_off:once()
			simCMD_autopilot_servos_fdir_off:once()
			simCMD_autopilot_servos2_fdir_off:once()
			simCMD_autopilot_servos3_fdir_off:once()
			simDR_autopilot_servos_on=0

		else
			B747DR_CAS_warning_status[0] = 0
		end
	end
end

function B747_ap_switch_yoke_disengage_capt_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_apdisconnect:once()
		B747DR_ap_lastCommand = simDRTime
		local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
		if B747DR_CAS_warning_status[0] == 0 and numAPengaged > 0 then
			B747DR_CAS_warning_status[0] = 1
		else
			B747DR_CAS_warning_status[0] = 0
		end
		if B747DR_autothrottle_active == 1 then
			run_after_time(autothrottle_reengage,0.5)
		end
		B747CMD_ap_reset:once()
		simCMD_autopilot_servos_off:once()
		simDR_autopilot_servos_on=0
		--simCMD_autopilot_fdir_servos_down_one:once()							-- TURN ONLY THE SERVOS OFF, LEAVE FLIGHT DIRECTOR ON
		B747_ap_all_cmd_modes_off()
		B747DR_ap_lastCommand=simDRTime
	end
end

function B747_ap_switch_yoke_disengage_fo_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_apdisconnect:once()
		B747DR_ap_lastCommand = simDRTime
		local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
		if B747DR_CAS_warning_status[0] == 0 and numAPengaged > 0 then
			B747DR_CAS_warning_status[0] = 1
		else
			B747DR_CAS_warning_status[0] = 0
		end
		if B747DR_autothrottle_active == 1 then
			run_after_time(autothrottle_reengage,0.5)
		end
		B747CMD_ap_reset:once()
		simCMD_autopilot_servos_off:once()
		simDR_autopilot_servos_on=0
		--simCMD_autopilot_fdir_servos_down_one:once()							-- TURN ONLY THE SERVOS OFF, LEAVE FLIGHT DIRECTOR ON
		B747_ap_all_cmd_modes_off()
		B747DR_ap_lastCommand=simDRTime
	end
end

function B747_ap_switch_autothrottle_disco_L_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_autothrottle_fail == 0 then
			B747DR_autothrottle_fail = 1
		else
			B747DR_autothrottle_fail = 0
		end
	end
end

function B747_ap_switch_autothrottle_disco_R_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_autothrottle_fail == 0 then
			B747DR_autothrottle_fail = 1
		else
			B747DR_autothrottle_fail = 0
		end
	end
end

function B747_ap_att_mode_CMDhandler(phase, duration)
	--[[if phase == 0 then
		if simDR_AHARS_roll_deg_pilot > 30.0 then
			simDR_autopilot_roll_sync_degrees = 30.0 -- LIMIT TO 30 DEGREES
			simCMD_autopilot_roll_right_sync_mode:once() -- ACTIVATE ROLL SYNC (RIGHT) MODE
		elseif simDR_AHARS_roll_deg_pilot < -30.0 then
			simDR_autopilot_roll_sync_degrees = -30.0 -- LIMIT TO 30 DEGREES
			simCMD_autopilot_roll_left_sync_mode:once() -- ACTIVATE ROLL SYNC (LEFT) MODE
		end
	end]]--
end

function B747_ap_reset_CMDhandler(phase, duration)
	print("B747_ap_reset_CMDhandler")
	if phase == 0 then
		--simCMD_autopilot_pitch_sync:once()

		B747DR_engine_TOGA_mode = 0
		B747_ap_all_cmd_modes_off() --B747_ap_reset_CMDhandler
		B747DR_ap_ias_mach_window_open = 0
	end
end

function B747_ai_ap_quick_start_CMDhandler(phase, duration)
	if phase == 0 then
		B747_set_ap_all_modes()
		B747_set_ap_CD()
		B747_set_ap_ER()
	end
end

function B747_ap_VNAV_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_vnav:once()
		B747_ap_button_switch_position_target[3] = 1
		local dist = B747BR_totalDistance - B747BR_tod
		if B747BR_cruiseAlt < 10 or (dist < 10 and simDR_onGround == 1) then
			B747DR_fmc_notifications[30] = 1
			return
		end
		if B747DR_ap_vnav_system == 1 then
			simCMD_autopilot_FMS_mode:once()
		elseif B747DR_ap_vnav_state > 0 then
			B747DR_ap_vnav_state = 0
			B747DR_ap_inVNAVdescent = 0
			B747DR_ap_thrust_mode = 0
			B747DR_mcp_hold=0
			if B747DR_autothrottle_active == 0 and isATEnabled() and simDR_onGround == 0 then
				--simCMD_autopilot_autothrottle_on:once()
				B747DR_autothrottle_active=1
			end
		elseif B747DR_ap_vnav_system == 2 then
			B747DR_ap_vnav_state = 1
			B747DR_ap_thrust_mode = 0
			B747DR_mcp_hold=0
			if beganDescent() == true and simDR_autopilot_alt_hold_status < 2 then
				print("had descent")
				--simCMD_autopilot_alt_hold_mode:once()
				simDR_autopilot_alt_hold_status = 2
				simDR_autopilot_vs_status=0
            	simDR_autopilot_flch_status=0
				simDR_autopilot_hold_altitude_ft=simDR_pressureAlt1
			elseif beganDescent() == true and simDR_autopilot_alt_hold_status == 2 then
				print("had descent, in alt hold")
			else
				print("no previous descent")
			end
			setVNAVState("gotVNAVSpeed", false)
			B747_vnav_speed()
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[3] = 0
	end
end
function B747_ap_LNAV_mode_afterCMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_lnav:once();
		B747_ap_button_switch_position_target[2] = 1
		B747DR_ap_ATT = 0.0
		--simCMD_autopilot_gpss_mode:once()
		if B747DR_ap_lnav_state > 0 then
			B747DR_ap_lnav_state = 0
			if simDR_autopilot_gpss > 0 then
				simCMD_autopilot_gpss_mode:once()
			end
			run_after_time(checkLNAV, 0.5)
		else
			print("arm LNAV")
			B747DR_ap_lnav_state = 1
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[2] = 0
	end
end
function B747_ap_switch_hdg_sel_mode_CMDhandler(phase, duration)
	if phase == 0 then
		B747CMD_fdr_log_headsel:once()
		if simDR_autopilot_gpss > 0 then
			simCMD_autopilot_gpss_mode:once()
		end
		simCMD_autopilot_heading_select:once()
		B747DR_ap_ATT = 0.0
		simDR_autopilot_heading_deg = B747DR_ap_heading_deg
		B747DR_ap_lnav_state = 0
		run_after_time(checkLNAV, 0.5)
	end
end
--*************************************************************************************--
--** 				             CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_ap_thrust_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/thrust_mode",
	"Autopilot THR Mode",
	B747_ap_thrust_mode_CMDhandler
)
B747DR_ap_thrust_mode = deferred_dataref("laminar/B747/autopilot/thrust_mode", "number")
B747DR_ap_lastCommand = deferred_dataref("laminar/B747/autopilot/lastCommand", "number")
B747CMD_ap_switch_speed_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/speed_mode",
	"A/P Speed Mode Switch",
	B747_ap_switch_speed_mode_CMDhandler
)
B747CMD_ap_press_airspeed =
	deferred_command(
	"laminar/B747/button_switch/press_airspeed",
	"Airspeed Dial Press",
	B747_ap_switch_vnavspeed_mode_CMDhandler
)
B747CMD_ap_press_altitude =
	deferred_command(
	"laminar/B747/button_switch/press_altitude",
	"Altitude Dial Press",
	B747_ap_switch_vnavalt_mode_CMDhandler
)
B747CMD_ap_ias_mach_sel_button =
	deferred_command(
	"laminar/B747/autopilot/ias_mach/sel_button",
	"Autopilot IAS/Mach Selector Button",
	B747_ap_ias_mach_sel_button_CMDhandler
)
B747CMD_ap_switch_flch_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/flch_mode",
	"Autopilot Fl CH Mode Switch",
	B747_ap_switch_flch_mode_CMDhandler
)
B747CMD_ap_switch_vs_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/vs_mode",
	"A/P V/S Mode Switch",
	B747_ap_switch_vs_mode_CMDhandler
)
B747CMD_ap_switch_alt_hold_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/alt_hold_mode",
	"A/P Altitude Hold Mode Switch",
	B747_ap_alt_hold_mode_CMDhandler
)
B747CMD_autopilot_VNAV_mode =
	deferred_command("laminar/B747/autopilot/button_switch/VNAV", "A/P VNAV Mode Switch", B747_ap_VNAV_mode_CMDhandler)
B747CMD_autopilot_LNAV_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/LNAV",
	"A/P LNAV Mode Switch",
	B747_ap_LNAV_mode_afterCMDhandler
)
B747CMD_ap_switch_hdg_sel_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/heading_select",
	"A/P Heading Select Mode Switch",
	B747_ap_switch_hdg_sel_mode_CMDhandler
)
--B747CMD_ap_switch_hdg_hold_mode			= deferred_command("laminar/B747/autopilot/button_switch/hdg_hold_mode", "A/P Heading Hold Mode Switch", B747_ap_switch_hdg_hold_mode_CMDhandler)

B747CMD_ap_switch_cmd_L =
	deferred_command("laminar/B747/autopilot/button_switch/cmd_L", "A/P CMD L Switch", B747_ap_switch_cmd_L_CMDhandler)
B747CMD_ap_switch_cmd_C =
	deferred_command("laminar/B747/autopilot/button_switch/cmd_C", "A/P CMD C Switch", B747_ap_switch_cmd_C_CMDhandler)
B747CMD_ap_switch_cmd_R =
	deferred_command("laminar/B747/autopilot/button_switch/cmd_R", "A/P CMD R Switch", B747_ap_switch_cmd_R_CMDhandler)

B747CMD_ap_switch_disengage_bar =
	deferred_command(
	"laminar/B747/autopilot/slide_switch/disengage_bar",
	"A/P Disenage Bar",
	B747_ap_switch_disengage_bar_CMDhandler
)
B747CMD_ap_switch_yoke_disengage_capt =
	deferred_command(
	"laminar/B747/autopilot/button_switch/yoke_disengage_capt",
	"A/P Capt Yoke Disengage Switch",
	B747_ap_switch_yoke_disengage_capt_CMDhandler
)
B747CMD_ap_switch_yoke_disengage_fo =
	deferred_command(
	"laminar/B747/autopilot/button_switch/yoke_disengage_fo",
	"A/P F/O Yoke Disengage Switch",
	B747_ap_switch_yoke_disengage_fo_CMDhandler
)
B747CMD_ap_switch_autothrottle_disco_L =
	deferred_command(
	"laminar/B747/autopilot/button_switch/autothrottle_disco_L",
	"A/P Autothrottle Disco Left",
	B747_ap_switch_autothrottle_disco_L_CMDhandler
)
B747CMD_ap_switch_autothrottle_disco_R =
	deferred_command(
	"laminar/B747/autopilot/button_switch/autothrottle_disco_R",
	"A/P Autothrottle Disco Right",
	B747_ap_switch_autothrottle_disco_R_CMDhandler
)

--B747CMD_ap_att_mode =
--	deferred_command("laminar/B747/autopilot/att_mode", "Set Autopilot ATT Mode", B747_ap_att_mode_CMDhandler)
B747CMD_ap_reset =
	deferred_command("laminar/B747/autopilot/mode_reset", "Autopilot Mode Reset", B747_ap_reset_CMDhandler)

--B747CMD_reverseThrust 						= find_command("sim/engines/thrust_reverse_toggle")

-- AI
B747CMD_ai_ap_quick_start =
	deferred_command("laminar/B747/ai/autopilot_quick_start", "Autopilot Quick Start", B747_ai_ap_quick_start_CMDhandler)

--*************************************************************************************--
--** 				          REPLACE X-PLANE COMMAND HANDLERS             	    	 **--
--*************************************************************************************--
--[[local lastap_dial_airspeed = simDR_autopilot_airspeed_kts
local max_dial_machspeed = 0.95
local target_descentAlt = 0.0
local target_descentSpeed = 0.0
local descentSpeedGradient = 0.0
local switchingIASMode=0]]
function B747_updateIASWindow()
	if simDR_autopilot_airspeed_is_mach == 0 then
		B747DR_ap_ias_dial_value = math.floor(simDR_ind_airspeed_kts_pilot)
	else
		B747DR_ap_ias_dial_value = math.floor(simDR_airspeed_mach * 100)
	end
	simDR_autopilot_airspeed_kts = B747DR_lastap_dial_airspeed
	B747DR_ap_ias_mach_window_open = 1
	B747DR_switchingIASMode = 0
end
function B747_updateIAS()
	--simDR_autopilot_airspeed_kts = lastap_dial_airspeed
	B747DR_switchingIASMode = 0
end
function confirm_B747_updateIASSpeed()
	simDR_autopilot_airspeed_kts_mach = B747DR_lastap_dial_airspeed
	print("confirm set kts_mach to " .. B747DR_lastap_dial_airspeed)
end
function B747_updateIASSpeed()
	simDR_autopilot_airspeed_kts_mach = B747DR_lastap_dial_airspeed
	print("set kts_mach to " .. B747DR_lastap_dial_airspeed)
	B747DR_switchingIASMode = 0
	run_after_time(confirm_B747_updateIASSpeed, 1)
end
function B747_updateIASMaxSpeed()
	B747DR_max_dial_machspeed = simDR_autopilot_airspeed_kts_mach
	print("set max kts_mach to " .. B747DR_max_dial_machspeed)
	B747DR_switchingIASMode = 0
end
function B747_ap_knots_mach_toggle_CMDhandler(phase, duration)
	if phase == 0 then
		B747_ap_button_switch_position_target[13] = 1
		if B747DR_ap_ias_mach_window_open == 1 then
			if simDR_airspeed_mach > 0.4 then
				B747DR_lastap_dial_airspeed = simDR_autopilot_airspeed_kts -- READ THE CURRENT AIRSPEED SETTING
				simDR_autopilot_airspeed_is_mach = 1 - simDR_autopilot_airspeed_is_mach -- SWAP THE MACH/KNOTS STATE
				B747DR_ap_ias_mach_window_open = 0 -- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				B747DR_switchingIASMode = 1
				run_after_time(B747_updateIASWindow, 0.25) --update target
			elseif simDR_airspeed_mach <= 0.4 and simDR_autopilot_airspeed_is_mach == 1 then
				B747DR_lastap_dial_airspeed = simDR_autopilot_airspeed_kts -- READ THE CURRENT AIRSPEED SETTING
				simDR_autopilot_airspeed_is_mach = 0 -- SWAP THE MACH/KNOTS STATE
				B747DR_ap_ias_mach_window_open = 0 -- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				B747DR_switchingIASMode = 1
				run_after_time(B747_updateIASWindow, 0.25) --update target
			end
		end
	elseif phase == 2 then
		B747_ap_button_switch_position_target[13] = 0
	end
end

function B747_ap_airspeed_up_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_ap_ias_mach_window_open == 1 then
			if simDR_autopilot_airspeed_is_mach == 0 then
				--simDR_autopilot_airspeed_kts = math.min(399.0, simDR_autopilot_airspeed_kts + 1)
				B747DR_ap_ias_dial_value = math.floor(math.min(399.0, B747DR_ap_ias_dial_value + 1))
			elseif simDR_autopilot_airspeed_is_mach == 1 then
				--simDR_autopilot_airspeed_kts_mach = math.min(0.950, simDR_autopilot_airspeed_kts_mach + 0.01)
				B747DR_ap_ias_dial_value = math.floor(math.min(95.0, B747DR_ap_ias_dial_value + 1))
			end
		end
	elseif phase == 1 then
		if duration > 0.5 then
			if B747DR_ap_ias_mach_window_open == 1 then
				if simDR_autopilot_airspeed_is_mach == 0 then
					--simDR_autopilot_airspeed_kts = math.min(399.0, simDR_autopilot_airspeed_kts + 1)
					B747DR_ap_ias_dial_value = math.floor(math.min(399.0, B747DR_ap_ias_dial_value + 1))
				elseif simDR_autopilot_airspeed_is_mach == 1 then
					B747DR_ap_ias_dial_value = math.floor(math.min(95.0, B747DR_ap_ias_dial_value + 1))
				--simDR_autopilot_airspeed_kts_mach = math.min(0.950, simDR_autopilot_airspeed_kts_mach + 0.01)
				end
			end
		end
	end
end

function B747_ap_airspeed_down_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_ap_ias_mach_window_open == 1 then
			if simDR_autopilot_airspeed_is_mach == 0 then
				--simDR_autopilot_airspeed_kts = math.max(100.0, simDR_autopilot_airspeed_kts - 1)
				B747DR_ap_ias_dial_value = math.floor(math.max(100.0, B747DR_ap_ias_dial_value - 1))
			elseif simDR_autopilot_airspeed_is_mach == 1 then
				--simDR_autopilot_airspeed_kts_mach = math.max(0.400, simDR_autopilot_airspeed_kts_mach - 0.01)
				B747DR_ap_ias_dial_value = math.floor(math.max(40.0, B747DR_ap_ias_dial_value - 1))
			end
		end
	elseif phase == 1 then
		if duration > 0.5 then
			if B747DR_ap_ias_mach_window_open == 1 then
				if simDR_autopilot_airspeed_is_mach == 0 then
					--simDR_autopilot_airspeed_kts = math.max(100.0, simDR_autopilot_airspeed_kts - 1)
					B747DR_ap_ias_dial_value = math.floor(math.max(100.0, B747DR_ap_ias_dial_value - 1))
				elseif simDR_autopilot_airspeed_is_mach == 1 then
					B747DR_ap_ias_dial_value = math.floor(math.max(40.0, B747DR_ap_ias_dial_value - 1))
				--simDR_autopilot_airspeed_kts_mach = math.max(0.400, simDR_autopilot_airspeed_kts_mach - 0.01)
				end
			end
		end
	end
end

function B747_ap_heading_up_CMDhandler(phase, duration)
	if phase == 0 then
		--if B747DR_ap_hdg_sel_mode == 1 then simDR_autopilot_heading_deg = B747DR_ap_heading_deg end
		--simDR_autopilot_heading_deg =	math.floor(math.fmod((simDR_autopilot_heading_deg + 1), 360.0)	)
		B747DR_ap_heading_deg = math.floor(math.fmod((B747DR_ap_heading_deg + 1), 360.0))
		if not (B747DR_ap_approach_mode ~= 0 and simDR_autopilot_nav_status ~= 2 and B747DR_ap_lnav_state > 0) then
			simDR_autopilot_heading_deg = B747DR_ap_heading_deg
		end
	elseif phase == 1 then
		if duration > 0.5 then
			--simDR_autopilot_heading_deg =	math.floor(math.fmod((simDR_autopilot_heading_deg + 1), 360.0)	)
			B747DR_ap_heading_deg = math.floor(math.fmod((B747DR_ap_heading_deg + 1), 360.0))
			if not (B747DR_ap_approach_mode ~= 0 and simDR_autopilot_nav_status ~= 2 and B747DR_ap_lnav_state > 0) then
				simDR_autopilot_heading_deg = B747DR_ap_heading_deg
			end
		--if B747DR_ap_hdg_sel_mode == 1 then simDR_autopilot_heading_deg = B747DR_ap_heading_deg end
		end
	end
end

function B747_ap_heading_down_CMDhandler(phase, duration)
	if phase == 0 then
		--if B747DR_ap_hdg_sel_mode == 1 then simDR_autopilot_heading_deg = B747DR_ap_heading_deg end
		--simDR_autopilot_heading_deg =	math.floor(math.fmod((simDR_autopilot_heading_deg - 1), 360.0)	)
		--if simDR_autopilot_heading_deg < 0.0 then simDR_autopilot_heading_deg = simDR_autopilot_heading_deg + 360.0 end
		B747DR_ap_heading_deg = math.floor(math.fmod((B747DR_ap_heading_deg - 1), 360.0))
		if B747DR_ap_heading_deg < 0.0 then
			B747DR_ap_heading_deg = B747DR_ap_heading_deg + 360.0
		end
		if not (B747DR_ap_approach_mode ~= 0 and simDR_autopilot_nav_status ~= 2 and B747DR_ap_lnav_state > 0) then
			simDR_autopilot_heading_deg = B747DR_ap_heading_deg
		end
	elseif phase == 1 then
		if duration > 0.5 then
			--simDR_autopilot_heading_deg =	math.floor(math.fmod((simDR_autopilot_heading_deg - 1), 360.0)	)
			--if simDR_autopilot_heading_deg < 0.0 then simDR_autopilot_heading_deg = simDR_autopilot_heading_deg + 360.0 end
			B747DR_ap_heading_deg = math.floor(math.fmod((B747DR_ap_heading_deg - 1), 360.0))
			if B747DR_ap_heading_deg < 0.0 then
				B747DR_ap_heading_deg = B747DR_ap_heading_deg + 360.0
			end
			if not (B747DR_ap_approach_mode ~= 0 and simDR_autopilot_nav_status ~= 2 and B747DR_ap_lnav_state > 0) then
				simDR_autopilot_heading_deg = B747DR_ap_heading_deg
			end
		--if B747DR_ap_hdg_sel_mode == 1 then simDR_autopilot_heading_deg = B747DR_ap_heading_deg end
		end
	end
end

function B747_ap_bank_limit_up_CMDhandler(phase, duration)
	if phase == 0 then
		B747DR_ap_bank_limit_sel_dial_pos = math.min(B747DR_ap_bank_limit_sel_dial_pos + 1, 5)
		if B747DR_ap_bank_limit_sel_dial_pos == 0 then
			simDR_autopilot_bank_limit = 4
		else
			simDR_autopilot_bank_limit = B747DR_ap_bank_limit_sel_dial_pos
		end
	end
end

function B747_ap_bank_limit_down_CMDhandler(phase, duration)
	if phase == 0 then
		B747DR_ap_bank_limit_sel_dial_pos = math.max(B747DR_ap_bank_limit_sel_dial_pos - 1, 0)
		if B747DR_ap_bank_limit_sel_dial_pos == 0 then
			simDR_autopilot_bank_limit = 4
		else
			simDR_autopilot_bank_limit = B747DR_ap_bank_limit_sel_dial_pos
		end
	end
end

function B747_ap_vertical_speed_up_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_ap_vs_window_open == 1 then
			simDR_autopilot_vs_fpm = math.min(6000.0, simDR_autopilot_vs_fpm + 100.0)
			B747DR_autopilot_vs_fpm = simDR_autopilot_vs_fpm
		end
		if B747DR_autopilot_vs_fpm > 0 then
			B747DR_ap_flightPhase = 1
		else
			B747DR_ap_flightPhase = 3
		end
	elseif phase == 1 then
		if duration > 0.5 then
			if B747DR_ap_vs_window_open == 1 then
				simDR_autopilot_vs_fpm = math.min(6000.0, simDR_autopilot_vs_fpm + 100.0)
				B747DR_autopilot_vs_fpm = simDR_autopilot_vs_fpm
			end
		end
	end
end
function B747_ap_vertical_speed_down_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_ap_vs_window_open == 1 then
			simDR_autopilot_vs_fpm = math.max(-8000.0, simDR_autopilot_vs_fpm - 100.0)
			B747DR_autopilot_vs_fpm = simDR_autopilot_vs_fpm

			if B747DR_autopilot_vs_fpm > 0 then
				B747DR_ap_flightPhase = 1
			else
				B747DR_ap_flightPhase = 3
			end
		end
	elseif phase == 1 then
		if duration > 0.5 then
			if B747DR_ap_vs_window_open == 1 then
				simDR_autopilot_vs_fpm = math.max(-8000.0, simDR_autopilot_vs_fpm - 100.0)
				B747DR_autopilot_vs_fpm = simDR_autopilot_vs_fpm
			end
		end
	end
end

function setSimAlt()
	--if B747DR_ap_vnav_state == 0 then
		simDR_autopilot_altitude_ft = B747DR_autopilot_altitude_ft
		print("set sim alt")
	--end
end

function B747_ap_altitude_up_CMDhandler(phase, duration)
	if phase == 0 then
		B747DR_autopilot_altitude_ft = math.min(50000.0, B747DR_autopilot_altitude_ft + 100)
		B747DR_ap_lastCommand = simDRTime + 1
		--if B747DR_ap_vnav_state == 0 then
			if is_timer_scheduled(setSimAlt) then
				stop_timer(setSimAlt)
			end
			run_after_time(setSimAlt, 3.0)
		--end
	elseif phase == 1 then
		if duration > 0.5 then
			B747DR_autopilot_altitude_ft = math.min(50000.0, B747DR_autopilot_altitude_ft + 100)
			B747DR_ap_lastCommand = simDRTime + 1
			--if B747DR_ap_vnav_state == 0 then
				if is_timer_scheduled(setSimAlt) then
					stop_timer(setSimAlt)
				end
				run_after_time(setSimAlt, 3.0)
			--end
		end
	end
end

function B747_ap_altitude_down_CMDhandler(phase, duration)
	if phase == 0 then
		B747DR_autopilot_altitude_ft = math.max(0.0, B747DR_autopilot_altitude_ft - 100)
		B747DR_ap_lastCommand = simDRTime + 1
		--if B747DR_ap_vnav_state == 0 then
			if is_timer_scheduled(setSimAlt) then
				stop_timer(setSimAlt)
			end
			run_after_time(setSimAlt, 3.0)
		--end
	elseif phase == 1 then
		if duration > 0.5 then
			B747DR_autopilot_altitude_ft = math.max(0.0, B747DR_autopilot_altitude_ft - 100)
			B747DR_ap_lastCommand = simDRTime + 1
			--if B747DR_ap_vnav_state == 0 then
				if is_timer_scheduled(setSimAlt) then
					stop_timer(setSimAlt)
				end
				run_after_time(setSimAlt, 3.0)
			--end
		end
	end
end
--[[function B747CMD_ap_heading_up_CMDhandler(phase, duration)
end
function B747CMD_ap_heading_down_CMDhandler(phase, duration)
end]]--

--*************************************************************************************--
--** 				            REPLACE X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--

simCMD_ap_knots_mach_toggle = replace_command("sim/autopilot/knots_mach_toggle", B747_ap_knots_mach_toggle_CMDhandler)

simCMD_ap_airspeed_up = replace_command("sim/autopilot/airspeed_up", B747_ap_airspeed_up_CMDhandler)
simCMD_ap_airspeed_down = replace_command("sim/autopilot/airspeed_down", B747_ap_airspeed_down_CMDhandler)
simCMD_ap_heading_up = replace_command("sim/autopilot/heading_up", B747_ap_heading_up_CMDhandler)
simCMD_ap_heading_down = replace_command("sim/autopilot/heading_down", B747_ap_heading_down_CMDhandler)
simCMD_ap_bank_limit_up = replace_command("sim/autopilot/bank_limit_up", B747_ap_bank_limit_up_CMDhandler)
simCMD_ap_bank_limit_down = replace_command("sim/autopilot/bank_limit_down", B747_ap_bank_limit_down_CMDhandler)
simCMD_ap_vertical_speed_up = replace_command("sim/autopilot/vertical_speed_up", B747_ap_vertical_speed_up_CMDhandler)
simCMD_ap_vertical_speed_down =
	replace_command("sim/autopilot/vertical_speed_down", B747_ap_vertical_speed_down_CMDhandler)
simCMD_ap_altitude_up = replace_command("sim/autopilot/altitude_up", B747_ap_altitude_up_CMDhandler)
simCMD_ap_altitude_down = replace_command("sim/autopilot/altitude_down", B747_ap_altitude_down_CMDhandler)
--B747CMD_ap_heading_up = replace_command("laminar/B747/autopilot/heading_up", B747CMD_ap_heading_up_CMDhandler)
--B747CMD_ap_heading_down = replace_command("laminar/B747/autopilot/heading_down", B747CMD_ap_heading_down_CMDhandler)

--*************************************************************************************--
--** 				          WRAP X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************-

----- ROUND TO INCREMENT ----------------------------------------------------------------
function roundToIncrement(numberToRound, increment)
	local y = numberToRound / increment
	local q = math.floor(y + 0.5)
	local z = q * increment

	return z
end

function B747_ap_heading_hold_mode_beforeCMDhandler(phase, duration)
	--[[print("heading hold "..simDR_AHARS_heading_deg_pilot)

  --B747DR_ap_heading_deg=roundToIncrement(simDR_AHARS_heading_deg_pilot, 1) unused?
  if simDR_autopilot_heading_hold_status ==0 then
    simDR_autopilot_heading_deg=roundToIncrement(simDR_AHARS_heading_deg_pilot, 1)
  end]]
end
function B747_ap_heading_hold_mode_afterCMDhandler(phase, duration)
	--print("heading hold2"..simDR_AHARS_heading_deg_pilot)
	B747DR_ap_lnav_state = 0
	if phase == 0 then
		B747CMD_fdr_log_headhold:once()
		B747DR_ap_ATT = 0.0
		B747_ap_button_switch_position_target[5] = 1
	elseif phase == 2 then
		B747_ap_button_switch_position_target[5] = 0
	end
end

dofile("json/json.lua")
simDR_variation = find_dataref("sim/flightmodel/position/magnetic_variation")
simDR_nav1Freq = find_dataref("sim/cockpit/radios/nav1_freq_hz")
simDR_nav2Freq = find_dataref("sim/cockpit/radios/nav2_freq_hz")
--simDR_nav1crs=find_dataref("sim/cockpit/radios/nav1_course_degm")
--simDR_nav2crs=find_dataref("sim/cockpit/radios/nav2_course_degm")
simDR_radio_nav_obs_deg = find_dataref("sim/cockpit2/radios/actuators/nav_obs_deg_mag_pilot")
simDR_radio_nav1_obs_deg = find_dataref("sim/cockpit/radios/nav1_obs_degt")
simDR_radio_nav2_obs_deg = find_dataref("sim/cockpit/radios/nav2_obs_degt")
simDR_radio_nav1_bearing_deg = find_dataref("sim/cockpit2/radios/indicators/nav1_bearing_deg_mag")
simDR_radio_nav2_bearing_deg = find_dataref("sim/cockpit2/radios/indicators/nav2_bearing_deg_mag")

navAidsJSON = find_dataref("xtlua/navaids")
fmsJSON = find_dataref("xtlua/fms")
nSize = 0
local navAids = {}
targetILS = find_dataref("laminar/B747/radio/ilsData")
local targetILSS = ""
local targetFMS = ""
local targetFMSnum = -1
targetFix = 0
bestDiff = 180
function getHeading(lat1, lon1, lat2, lon2)
	b10 = math.rad(lat1)
	b11 = math.rad(lon1)
	b12 = math.rad(lat2)
	b13 = math.rad(lon2)
	retVal =
		math.atan2(
		math.sin(b13 - b11) * math.cos(b12),
		math.cos(b10) * math.sin(b12) - math.sin(b10) * math.cos(b12) * math.cos(b13 - b11)
	)
	return math.deg(retVal)
end
function getHeadingDifference(desireddirection, current_heading)
	error = current_heading - desireddirection
	if (error > 180) then
		error = error - 360
	end
	if (error < -180) then
		error = error + 360
	end
	return error
end

function getDistance(lat1, lon1, lat2, lon2)
	if lat1 == lat2 and lon1 == lon2 then
		return 0
	end
	alat = math.rad(lat1)
	alon = math.rad(lon1)
	blat = math.rad(lat2)
	blon = math.rad(lon2)
	av = math.sin(alat) * math.sin(blat) + math.cos(alat) * math.cos(blat) * math.cos(blon - alon)
	if av > 1 then
		av = 1
	end
	retVal = math.acos(av) * 3440
	return retVal
end
local lastILSUpdate = 0
original_distance = -1
function round(x)
	return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end
function int(x)
	return x >= 0 and math.floor(x) or math.ceil(x)
end
function B747_fltmgmt_setILS(fmsO)
	local modes = B747DR_radioModes
	local targetDots=0
	--print("B747_fltmgmt_setILS")
	if modes:sub(1, 1) == " " then
		targetFMSnum = -1
		B747DR_radioModes = replace_char(1, modes, "A")
	elseif modes:sub(1, 1) == "M" then
		--local fms=json.decode(fmsSTR)

		setDistances(fmsO)
		--print("Dist B747DR_ils_dots = "..B747DR_ils_dots)
		--print("Dist targetILSS = "..targetILS)
		--print("Dist B747BR_distance_to_dest = "..B747BR_distance_to_dest)
		if B747DR_ils_dots==0 and ((B747BR_totalDistance>0 and B747BR_totalDistance< 50) or (B747BR_distance_to_dest>=0 and B747BR_distance_to_dest<50)) then
			if string.len(targetILS) > 2 then
				B747DR_ils_dots=1
				--print("do Dist B747DR_ils_dots = "..B747DR_ils_dots)
			end
		end
		return
	end
	local diff = simDRTime - lastILSUpdate
	if diff < 2 then
		return
	end
	--collectgarbage("collect")
	lastILSUpdate = simDRTime
	local n1 = simDR_nav1Freq
	local n2 = simDR_nav2Freq
	local d1 = simDR_radio_nav1_obs_deg
	local d2 = simDR_radio_nav2_obs_deg
	 --continually get latest
	local d1 = simDR_radio_nav_obs_deg[0]
	local d2 = simDR_radio_nav_obs_deg[1]
	 --continually get latest
	--print("fmsJSON=".. fmsSTR)


	setDistances(fmsO)

	local newTargetFix = 0
	local hitI = -1
	--print(navAidsJSON)
	if table.getn(fmsO) > 4 and (fmsO[targetFMSnum] == nil or targetFMS ~= fmsO[targetFMSnum][8]) then
		if string.len(navAidsJSON) ~= nSize then
			navAids = json.decode(navAidsJSON)
			nSize = string.len(navAidsJSON)
		end
		if fmsO[table.getn(fmsO)][2] == 1 then
			--we have an airport as our dst
			local apdistance = getDistance(simDR_latitude, simDR_longitude, fmsO[table.getn(fmsO)][5], fmsO[table.getn(fmsO)][6])
			if apdistance > 45 then
				return
			end

			--Marauder28
			if original_distance == -1 then
				original_distance = B747BR_totalDistance --capture original flightplan distance
			end
			local pct_remaining = 100 - (((original_distance - B747BR_totalDistance) / original_distance) * 100)
			local dist_to_TOD = B747BR_totalDistance - B747BR_tod
			--print("Orig Dist = "..original_distance)
			--print("Dist Remain = "..B747BR_totalDistance)
			--if dist_to_TOD > 0 then print("Dist TOD = "..dist_to_TOD) end
			--print("Pct Remain = "..pct_remaining)
			--if (apdistance>=200) or (pct_remaining > 50) then
			--if dist_to_TOD >= 200 then --or pct_remaining > 50 then
			--return    --more than 200nm away from TOD or less than half-way to DEST (used in NAV RAD auto-tune scenario #2)
			--end
			--Marauder28

			found = false
			local runwayHeading = -999
			for i = table.getn(fmsO) - 1, 2, -1 do --last is the airport, before that go-around [may] be dup
				--we have a fix coming in to the airport
				--if fms[i][2] == 512 then
				local ap1Heading = getHeading(fmsO[i][5], fmsO[i][6], fmsO[table.getn(fmsO)][5], fmsO[table.getn(fmsO)][6])
				local ap2Heading = getHeading(fmsO[i - 1][5], fmsO[i - 1][6], fmsO[table.getn(fmsO)][5], fmsO[table.getn(fmsO)][6])
				local diffap = getHeadingDifference(ap1Heading, ap2Heading)
				local distance = getDistance(fmsO[i][5], fmsO[i][6], fmsO[table.getn(fmsO)][5], fmsO[table.getn(fmsO)][6])
				print("finding ils FMS i=" .. i .. ":" .. ap1Heading .. ":" .. ap2Heading .. ":" .. diffap .. ":" .. distance.. ":" .. fmsO[i][8].. ":" .. fmsO[i - 1][8] )
				if diffap < 10 and diffap > -10 and distance < 11 then
					print("potential matched from" .. i)
					for n = table.getn(navAids), 1, -1 do
						--now find an ils

						if navAids[n][2] == 8 then
							local headingToILS = getHeading(fmsO[i][5], fmsO[i][6], navAids[n][5], navAids[n][6])
							local headingToNext = getHeading(fmsO[i][5], fmsO[i][6], fmsO[i + 1][5], fmsO[i + 1][6])
							local diff = getHeadingDifference(navAids[n][4], headingToILS)
							local diff2 = getHeadingDifference(headingToILS, headingToNext)
							if diff < 0 then
								diff = diff * -1
							end

							if diff2 < 5 and diff2 > -5 then
								local distance2 = getDistance(fmsO[table.getn(fmsO)][5], fmsO[table.getn(fmsO)][6], navAids[n][5], navAids[n][6])
								if diff < 1 and diff <= bestDiff and distance2 < 10 then
									--print("navaid "..n.."->"..fms[i][8].."="..diff.." ".. navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
									bestDiff = diff
									runwayHeading = headingToNext
									print("bestdiff = " .. bestDiff .. " on heading " .. headingToILS .. " course=" .. headingToNext)
									--if targetFix == newTargetFix then
									found = true
									newTargetFix = n
									print("newTargetFix = " .. newTargetFix)
									hitI = i
								end
							end
						end
					end
				end
			end
			targetFix = newTargetFix
			-- if found==false then
			bestDiff = 180

			--else
			if targetFix ~= 0 then
				--print("set targetILS")
				--navAids[targetFix][4]=runwayHeading
				targetILSS = json.encode(navAids[targetFix])
				targetFMS = fmsO[hitI][8]
				targetFMSnum = hitI
				targetILS = targetILSS
				print("Tune ILS" .. targetILSS)

				if string.len(targetILSS) > 0 then
					print("Tuning ILS" .. targetILSS)
					local ilsNav = json.decode(targetILSS)
					simDR_nav1Freq = ilsNav[3]
					simDR_nav2Freq = ilsNav[3]
					local course = (ilsNav[4] + int(simDR_variation))
					if course < 0 then
						course = course + 360
					end
					simDR_radio_nav_obs_deg[0] = course
					simDR_radio_nav_obs_deg[1] = course
					print("Tuned ILS " .. course)
					targetDots = 1 -- make PFD loc and GS dots visible
				end
			elseif B747DR_ap_FMA_active_roll_mode ~= 3 then
				--print("cleared targetILS")
				targetILS = " "
				targetILSS = " "
			end
		end
	elseif string.len(targetILSS) > 1 and string.len(targetILS) > 2 then
		--print("Tuned ILS "..course)
		--print("Tuning ILS".. targetILSS)
		local ilsNav = json.decode(targetILSS)
		simDR_nav1Freq = ilsNav[3]
		simDR_nav2Freq = ilsNav[3]
		local course = (ilsNav[4] + simDR_variation)
		if course < 0 then
			course = course + 360
		elseif course > 360 then
			course = course - 360
		end
		--course=round(course)
		simDR_radio_nav_obs_deg[0] = course
		simDR_radio_nav_obs_deg[1] = course
		targetDots = 1 -- make PFD loc and GS dots visible
	else
		if B747DR_ap_FMA_active_roll_mode == 3 then
			targetDots = 1 -- make PFD loc and GS dots visible
		elseif string.len(targetILS) < 2 and B747DR_ap_FMA_active_roll_mode ~= 3 then
			targetDots = 0
		end
	end
	local tDots=B747DR_ils_dots
	if (B747BR_totalDistance>0 and B747BR_totalDistance< 50) or (B747BR_distance_to_dest>=0 and B747BR_distance_to_dest<50) then
		B747DR_ils_dots=targetDots
	else
		B747DR_ils_dots=0
	end
	--print("target="..targetILS.."= "..targetILSS.."= "..targetFix.. " "..nSize.. " "..table.getn(navAids))
	--[[for i=table.getn(fms)-1,1,-1 do
    if fms[i][10]==true then
      print("fms"..i.."=".. fms[i][1].." "..fms[i][2].." "..fms[i][3].." "..fms[i][4].." "..fms[i][5].." "..fms[i][6].." "..fms[i][7].." "..fms[i][8].." "..fms[i][9].." active")
    else
      print("fms"..i.."=".. fms[i][1].." "..fms[i][2].." "..fms[i][3].." "..fms[i][4].." "..fms[i][5].." "..fms[i][6].." "..fms[i][7].." "..fms[i][8].." "..fms[i][9].." inactive")
    end
  end]]
end

--*************************************************************************************--
--** 				              WRAP X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--
simCMD_autopilot_gpss_mode = find_command("sim/autopilot/gpss")

simCMD_autopilot_FMS_mode = find_command("sim/autopilot/FMS")
simCMD_autopilot_heading_hold_mode =
	wrap_command(
	"sim/autopilot/heading_hold",
	B747_ap_heading_hold_mode_beforeCMDhandler,
	B747_ap_heading_hold_mode_afterCMDhandler
)
simCMD_autopilot_appr_mode = find_command("sim/autopilot/approach")

--*************************************************************************************--
--** 					           OBJECT CONSTRUCTORS         	    	    		 **--
--*************************************************************************************--

--*************************************************************************************--
--** 				                 CREATE OBJECTS        	         				 **--
--*************************************************************************************--

--*************************************************************************************--
--** 				                SYSTEM FUNCTIONS             	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
	if condition then
		return ifTrue
	else
		return ifFalse
	end
end

----- ANIMATION UNILITY -----------------------------------------------------------------
function B747_set_ap_animation_position(current_value, target, min, max, speed)
	if target >= (max - 0.001) and current_value >= (max - 0.01) then
		return max
	elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
		return min
	else
		return current_value + ((target - current_value) * (speed * SIM_PERIOD))
	end
end

---- BUTTON SWITCH POSITION ANIMATION ---------------------------------------------------
function B747_ap_button_switch_animation()
	for i = 0, NUM_AUTOPILOT_BUTTONS - 1 do
		B747DR_ap_button_switch_position[i] =
			B747_set_ap_animation_position(
			B747DR_ap_button_switch_position[i],
			B747_ap_button_switch_position_target[i],
			0.0,
			1.0,
			30.0
		)
	end
end

----- VERTICAL SPEED MODE ---------------------------------------------------------------
function B747_ap_vs_mode()
	----- WINDOW
	B747DR_ap_vs_window_open = B747_ternary(simDR_autopilot_vs_status >= 1 and B747DR_ap_vnav_state < 2 and simDR_autopilot_alt_hold_status<2, 1, 0)

	----- VVI FOR ANIMATION

	B747DR_ap_vvi_fpm = math.abs(simDR_autopilot_vs_fpm)

	----- THOUSANDS DIGIT HIDE/SHOW
	B747DR_ap_vs_show_thousands = B747_ternary(B747DR_ap_vs_window_open == 1 and B747DR_ap_vvi_fpm >= 1000, 1, 0)
end

----- IAS/MACH MODE ---------------------------------------------------------------------
function B747_ap_ias_mach_mode()
	if B747DR_ap_autoland < 0 and (simDR_radarAlt1 > 1500) then
		B747DR_ap_autoland = 0
		print("IAS end Go Around")
	end
	----- SET THE IAS/MACH WINDOW STATUS
	if B747DR_switchingIASMode == 0 and (B747DR_ap_vnav_state < 2 or getVNAVState("manualVNAVspd") == 1) then --inop until we know speed!
		B747DR_ap_ias_mach_window_open = 1
	else
		B747DR_ap_ias_mach_window_open = 0
	end
	local ap_dial_airspeed = simDR_autopilot_airspeed_kts -- READ THE CURRENT AIRSPEED SETTING
	local ap_simDR_autopilot_airspeed_is_mach = simDR_autopilot_airspeed_is_mach -- READ THE CURRENT mach SETTING

	----- AUTO-SWITCH AUTOPILOT IAS/MACH WINDOW AIRSPEED MODE
	if simDR_airspeed_mach < 0.40 and B747DR_switchingIASMode == 0 and B747DR_ap_vnav_state == 0 then
		if simDR_vvi_fpm_pilot < -250.0 then
			if ap_simDR_autopilot_airspeed_is_mach == 1 then
				--simDR_autopilot_airspeed_kts = ap_dial_airspeed								-- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				B747DR_lastap_dial_airspeed = simDR_autopilot_airspeed_kts
				simDR_autopilot_airspeed_is_mach = 0 -- CHANGE TO KNOTS
				B747DR_ap_ias_mach_window_open = 0 -- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				B747DR_switchingIASMode = 1
				print("AUTO-SWITCH AUTOPILOT IAS/MACH WINDOW AIRSPEED MODE")
				run_after_time(B747_updateIASWindow, 0.25) --update target
			end
		end
	end
    --D6-30151-481 4.10.4/5
	if simDR_airspeed_mach > 0.84 and B747DR_switchingIASMode == 0 and B747DR_ap_vnav_state == 0 then
		if simDR_vvi_fpm_pilot > 250.0 then
			if ap_simDR_autopilot_airspeed_is_mach == 0 then
				B747DR_lastap_dial_airspeed = simDR_autopilot_airspeed_kts
				--simDR_autopilot_airspeed_kts = ap_dial_airspeed								-- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				simDR_autopilot_airspeed_is_mach = 1 -- CHANGE TO KNOTS
				B747DR_ap_ias_mach_window_open = 0 -- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				B747DR_switchingIASMode = 1
				run_after_time(B747_updateIASWindow, 0.25) --update target
			end
		end
	end
	if simDR_autopilot_airspeed_kts > 310 and B747DR_switchingIASMode == 0 and B747DR_ap_vnav_state == 0 then
		if simDR_vvi_fpm_pilot < -250.0 then
			if ap_simDR_autopilot_airspeed_is_mach == 1 then
				B747DR_lastap_dial_airspeed = simDR_autopilot_airspeed_kts
				--simDR_autopilot_airspeed_kts = ap_dial_airspeed								-- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				simDR_autopilot_airspeed_is_mach = 0 -- CHANGE TO KNOTS
				B747DR_ap_ias_mach_window_open = 0 -- WRITE THE NEW VALUE TO FORCE CONVERSION TO CORRECT UNITS
				B747DR_switchingIASMode = 1
				run_after_time(B747_updateIASWindow, 0.25) --update target
			end
		end
	end
	----- SET THE IAS/MACH TUMBLER VALUE
	if B747DR_ap_ias_mach_window_open == 1 and simDR_autopilot_airspeed_is_mach == 1 then
		B747DR_ap_mach_decimal_visibiilty = 1
	else
		B747DR_ap_mach_decimal_visibiilty = 0
	end

	local minSafeSpeed = B747DR_airspeed_Vmc + 10
	local maxSafeSpeed = B747DR_airspeed_Vmo

	if simDR_flap_ratio_control > 0 then
		if simDR_flap_ratio_control <= 0.168 then --flaps 1
			maxSafeSpeed =275
		elseif simDR_flap_ratio_control <= 0.34 then --flaps 5
			maxSafeSpeed = 255
		elseif simDR_flap_ratio_control <= 0.5 then --flaps 10
			maxSafeSpeed = 235
			minSafeSpeed = minSafeSpeed - 5
		elseif simDR_flap_ratio_control <= 0.668 then --flaps 20
			maxSafeSpeed = 225
			minSafeSpeed = minSafeSpeed - 5
		elseif simDR_flap_ratio_control <= 0.84 then --flaps 25
			maxSafeSpeed = 200
			minSafeSpeed = minSafeSpeed - 9
		elseif simDR_flap_ratio_control <= 1.0 then --flaps 30
			maxSafeSpeed = 175
			minSafeSpeed = minSafeSpeed - 9
		end
	end
	local maxmach = B747DR_airspeed_Mms

	if B747DR_switchingIASMode == 0 then
		if simDR_autopilot_airspeed_is_mach == 0 then
			B747DR_ap_ias_bug_value = B747DR_ap_ias_dial_value
			if B747DR_ap_ias_dial_value < minSafeSpeed then
				simDR_autopilot_airspeed_kts = minSafeSpeed
			else
				simDR_autopilot_airspeed_kts = math.min(B747DR_ap_ias_dial_value, maxSafeSpeed)
			end
		elseif simDR_autopilot_airspeed_is_mach == 1 and B747DR_ap_ias_dial_value * 0.01 > 0.4 then
			B747DR_ap_ias_mach_dial_value = B747DR_ap_ias_dial_value * 0.01

			if simDR_autopilot_airspeed_kts >= maxSafeSpeed - 10 then
				if simDR_autopilot_airspeed_kts < maxSafeSpeed then
					B747DR_ap_ias_bug_value = maxSafeSpeed - 10 --simDR_autopilot_airspeed_kts
				end

				if
					simDR_autopilot_flch_status == 0 and B747DR_ap_inVNAVdescent == 0 and
						simDR_autopilot_airspeed_kts > maxSafeSpeed - 10
				 then
					simDR_autopilot_airspeed_kts = maxSafeSpeed - 10
					setFMSData("maxkts", simDR_autopilot_airspeed_kts)
				elseif simDR_autopilot_airspeed_kts > maxSafeSpeed - 20 then
					simDR_autopilot_airspeed_kts = maxSafeSpeed - 20 --flch/descent overspeed
					setFMSData("maxkts", simDR_autopilot_airspeed_kts)
				end
			else
				B747DR_ap_ias_bug_value = simDR_autopilot_airspeed_kts
				simDR_autopilot_airspeed_kts_mach = math.min(B747DR_ap_ias_dial_value * 0.01, maxmach - 0.01) ---roundToIncrement(B747DR_ap_ias_dial_value, 1) * 0.01
			end
		end
	end
	if simDR_ind_airspeed_kts_pilot < B747DR_ap_ias_bug_value then
		if B747DR_ap_ias_bug_value - simDR_ind_airspeed_kts_pilot > 60 then
			B747DR_ap_ias_bug_value_pfd = simDR_ind_airspeed_kts_pilot + 60
		else
			B747DR_ap_ias_bug_value_pfd = B747DR_ap_ias_bug_value
		end
	else
		if simDR_ind_airspeed_kts_pilot - B747DR_ap_ias_bug_value > 57.5 then
			B747DR_ap_ias_bug_value_pfd = simDR_ind_airspeed_kts_pilot - 57.5
		else
			B747DR_ap_ias_bug_value_pfd = B747DR_ap_ias_bug_value
		end
	end
end

local fms
function getFMS()
	return fms
end
function setDistances(fmsO)
	--print("set distances")
	if B747BR_cruiseAlt>0 and B747DR_ap_flightPhase<2 then
		local useFPM=2000
		if B744_fpm>2000 then useFPM=B744_fpm end
		local altDiff=B747BR_cruiseAlt-simDR_pressureAlt1
		local minsToAlt=altDiff/useFPM
		if simDR_groundspeed<150 then minsToAlt=minsToAlt+15 end
		local meters_per_second_to_kts = 1.94384449
		local default_speed = 250 * meters_per_second_to_kts
  		local actual_speed = simDR_groundspeed * meters_per_second_to_kts
		B747BR_toc=(math.max(default_speed, actual_speed)*minsToAlt)/60
	else
		B747BR_toc=-1
	end
	if (fmsO) == nil then
		B747BR_distance_to_dest=-1
		return
	end
	if table.getn(fmsO) == 0 then
		B747BR_distance_to_dest=-1
		return
	end

	local start = B747DR_fmscurrentIndex
	if start == 0 then
		start = 1
	end
	local iLat = simDR_latitude
	local iLong = simDR_longitude
	local endI = table.getn(fmsO)
	B747BR_distance_to_dest= getDistance(iLat, iLong, fmsO[endI][5], fmsO[endI][6])
	if table.getn(fmsO) <= 2 then
		return
	end
	if fmsO[start] == nil then
		print("empty data")
		return
	end
	local LastLeg = getDistance(simDR_latitude, simDR_longitude, fmsO[start][5], fmsO[start][6])

	local eLat = fmsO[start][5]
	local eLong = fmsO[start][6]
	local totalDistance = LastLeg
	local nextDistanceInFeet = totalDistance * 6076.12

	local eod = endI
	local setTOD = false
	local setTOC = false
	local todDist = B747BR_totalDistance - B747BR_tod
	for i = 1, endI - 1, 1 do
		if i >= start then
			iLat = fmsO[i][5]
			iLong = fmsO[i][6]
			eLat = fmsO[i + 1][5]
			eLong = fmsO[i + 1][6]
			LastLeg = getDistance(fmsO[i][5], fmsO[i][6], fmsO[i + 1][5], fmsO[i + 1][6])
			totalDistance = totalDistance + LastLeg
		end

		if totalDistance > todDist and setTOD == false and B747BR_totalDistance > 0 and todDist > 0 then
			setTOD = true
			--interpolate last leg
			local backingDist = totalDistance - todDist
			local legFrac = (LastLeg - backingDist) / LastLeg
			if legFrac >= 0 and legFrac <= 1 and totalDistance - LastLeg < todDist then
				B747BR_todLat = iLat + (eLat - iLat) * legFrac
				B747BR_todLong = iLong + (eLong - iLong) * legFrac
			end
		end
		if B747BR_toc>=0 and totalDistance > B747BR_toc and setTOC == false and B747BR_totalDistance > 0 then
			setTOC = true
			local backingDist = totalDistance - B747BR_toc
			local legFrac = (LastLeg - backingDist) / LastLeg
			if legFrac >= 0 and legFrac <= 1 and totalDistance - LastLeg < B747BR_toc then
				B747BR_tocLat = iLat + (eLat - iLat) * legFrac
				B747BR_tocLong = iLong + (eLong - iLong) * legFrac
			end
		end
		
		dtoAirport = getDistance(fmsO[i][5], fmsO[i][6], fmsO[endI][5], fmsO[endI][6])
		--print("i=".. i .." B747DR_fmscurrentIndex="..B747DR_fmscurrentIndex .." speed="..simDR_groundspeed .. " distance="..totalDistance.." dtoAirport="..dtoAirport.. " ".. fmsO[i][5].." ".. fmsO[i][6].." ".. fmsO[i+1][5].." ".. fmsO[i+1][6])
		if dtoAirport < 10 then
			eod = i
			--print("end fms"..i.."=at alt "..fms[i][3])
			break
		end
	end
	totalDistance = totalDistance + getDistance(fmsO[eod][5], fmsO[eod][6], fmsO[endI][5], fmsO[endI][6])
	--simDR_autopilot_altitude_ft
	B747BR_eod_index = eod
	B747BR_totalDistance = totalDistance
	if B747BR_totalDistance<15 then
		local glideAlt= B747BR_totalDistance*290 +fmsO[endI][3]
		B747BR_fpe	= simDR_pressureAlt1-glideAlt
	end
	B747BR_nextDistanceInFeet = nextDistanceInFeet
	local cruiseTOD = ((B747BR_cruiseAlt - fmsO[eod][3]) / 100) / 2.9
	local currentTOD = ((simDR_pressureAlt1 - fmsO[eod][3]) / 100) / 2.9
	
	B747BR_tod = cruiseTOD
end

----- ALTITUDE SELECTED -----------------------------------------------------------------

function B747_getCurrentWayPoint(fms)
	--[[ for i=1,table.getn(fms),1 do
    if fms[i][10]==true and i<=getVNAVState("recalcAfter") then
      --print("simDR_autopilot_altitude_ft=".. simDR_autopilot_altitude_ft)
      return
    end
  end]]
	for i = 1, table.getn(fms), 1 do
		--print("FMS j="..fmsJSON)

		if fms[i][10] == true then
			B747DR_fmscurrentIndex = i

			setVNAVState("recalcAfter", i)
			break
		end
	end
end

function B747_ap_altitude()
	local currentapAlt = simDR_autopilot_altitude_ft
	B747DR_ap_alt_show_thousands = B747_ternary(B747DR_autopilot_altitude_ft > 999.9, 1.0, 0.0)
	B747DR_ap_alt_show_tenThousands = B747_ternary(B747DR_autopilot_altitude_ft > 9999.99, 1.0, 0.0)
	local vvi_status = simDR_autopilot_vs_status
	local servoStatus = simDR_autopilot_servos_on
	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode

	B747DR_alt_capture_window = B747_rescale(0,200,3000,1000,math.abs(simDR_vvi_fpm_pilot))
	if simDR_pressureAlt1 < B747DR_autopilot_altitude_ft then
		if B747DR_autopilot_altitude_ft - simDR_pressureAlt1 > 400 then
			B747DR_autopilot_altitude_ft_pfd = simDR_pressureAlt1 + 400
		else
			B747DR_autopilot_altitude_ft_pfd = B747DR_autopilot_altitude_ft
		end
	else
		if simDR_pressureAlt1 - B747DR_autopilot_altitude_ft > 380 then
			B747DR_autopilot_altitude_ft_pfd = simDR_pressureAlt1 - 380
		else
			B747DR_autopilot_altitude_ft_pfd = B747DR_autopilot_altitude_ft
		end
	end

	--print("B747_ap_altitude")
	fms = json.decode(fmsJSON)
	-- 	if table.getn(fms)<2 or fms[table.getn(fms)][2] ~= 1 then
	-- 	  B747DR_ap_vnav_state=0
	-- 	  return
	-- 	end --no nav
	if (B747BR_totalDistance>0 and B747BR_tod >0) and (
		(B747DR_ap_vnav_pause > 1 and B747BR_totalDistance <= B747DR_ap_vnav_pause) or
			(B747DR_ap_vnav_pause == 1 and B747BR_totalDistance - B747BR_tod <= 1))
	 then
		B747DR_ap_vnav_pause = 0
		simCMD_pause:once()
	end
	if B747DR_ap_vnav_state > 0 then
		if table.getn(fms) < 2 or fms[table.getn(fms)][2] ~= 1 then
			print("Cancel VNAV " .. table.getn(fms))

			B747DR_fmc_notifications[54] = 1
			B747DR_ap_vnav_state = 0
			B747DR_ap_lnav_state = 0
			B747DR_ap_thrust_mode = 0
		end --no vnav

	--computeVNAVAlt(fms)
	end
end
--OLD button functions
--[[

]]
function B747_ap_appr_mode_beforeCMDhandler(phase, duration)
	if phase == 0 then
		--simCMD_autopilot_appr_mode:once()
		B747CMD_fdr_log_app:once()
		B747_ap_button_switch_position_target[9] = 1
		if B747DR_ils_dots ==0 then
			B747DR_fmc_notifications[40]=1
			return;
		else
			B747DR_fmc_notifications[40]=0
		end
		--simCMD_autopilot_roll_center_sync_mode:once()
		local diff = simDRTime - B747DR_ap_lastCommand
		--if diff>0.5 then
		if B747DR_ap_approach_mode <= 0 then
			B747DR_ap_approach_mode = 1
			if (B747DR_ap_cmd_L_mode ==1 or B747DR_ap_cmd_C_mode ==1 or B747DR_ap_cmd_R_mode==1) and simDR_radarAlt1>1500 then
				B747DR_ap_cmd_L_mode=1
				B747DR_ap_cmd_C_mode=1
				B747DR_ap_cmd_R_mode=1
			end
			print("arm APP approach")
		elseif B747DR_autopilot_gs_status ~= 2 and B747DR_autopilot_nav_status ~= 2 then
			B747DR_ap_approach_mode = 0
		end

		B747DR_ap_lastCommand = simDRTime
		B747DR_ap_heading_deg = roundToIncrement(simDR_radio_nav_obs_deg[0], 1) -- SET THE SELECTED HEADING VALUE TO THE LOC COURSE
	elseif phase == 2 then
		B747_ap_button_switch_position_target[9] = 0 -- SET THE LOC SWITCH ANIMATION TO "OUT"
	end
end

function B747_ap_switch_loc_mode_CMDhandler(phase, duration)
	if phase == 0 then
		--simCMD_autopilot_nav_mode:once()
		B747CMD_fdr_log_loc:once()
		B747_ap_button_switch_position_target[8] = 1
		if B747DR_ils_dots ==0 then
			B747DR_fmc_notifications[40]=1
			return;
		else
			B747DR_fmc_notifications[40]=0
		end
		local diff = simDRTime - B747DR_ap_lastCommand
		--if diff>0.5 then
		if B747DR_ap_approach_mode >= 0 then
			B747DR_ap_approach_mode = -1

			print("arm LOC approach")
		--else
		--	B747DR_ap_approach_mode=0
		end
		--end
		B747DR_ap_lastCommand = simDRTime
	elseif phase == 2 then
		B747_ap_button_switch_position_target[8] = 0 -- SET THE LOC SWITCH ANIMATION TO "OUT"
	end
end

B747CMD_autopilot_appr_mode =
	deferred_command("laminar/B747/autopilot/approach", "APP Switch", B747_ap_appr_mode_beforeCMDhandler)
B747CMD_ap_switch_loc_mode =
	deferred_command(
	"laminar/B747/autopilot/button_switch/loc_mode",
	"A/P Localizer Mode Switch",
	B747_ap_switch_loc_mode_CMDhandler
)
----- APPROACH MODE ---------------------------------------------------------------------

function B747_ap_appr_mode()
	local diff = simDRTime - B747DR_ap_lastCommand
	local appRefreshnav = simDR_autopilot_nav_status
	local appRefreshgs = simDR_autopilot_gs_status
	if B747DR_ap_approach_mode ~= 0 then --only if we'll need it
		local refreshheading = simDR_autopilot_heading_status
	end
	--reactivate LNAV if required

	if diff < 0.2 then
		return
	end

	if
		B747DR_ap_approach_mode ~= 0 and simDR_radarAlt1 < 1500 and B747DR_autopilot_nav_status == 2 and
		B747DR_autopilot_gs_status == 2 and
			(B747DR_ap_cmd_L_mode == 1 or B747DR_ap_cmd_C_mode == 1 or B747DR_ap_cmd_R_mode == 1)
	 then
		if B747DR_hyd_sys_pressure_3>1000 then
			B747DR_ap_cmd_L_mode = 1
		end
		if B747DR_hyd_sys_pressure_1>1000 then
			B747DR_ap_cmd_C_mode = 1
		end
		if B747DR_hyd_sys_pressure_2>1000 then
			B747DR_ap_cmd_R_mode = 1
		end
	end
	--print(B747DR_hyd_sys_pressure_1.." "..B747DR_hyd_sys_pressure_2.." "..B747DR_hyd_sys_pressure_3.." "..B747DR_ap_cmd_L_mode.." "..B747DR_ap_cmd_C_mode.." "..B747DR_ap_cmd_R_mode)
	if B747DR_hyd_sys_pressure_3<1000 then
		B747DR_ap_cmd_L_mode = 0
	end
	if B747DR_hyd_sys_pressure_1<1000 then
		B747DR_ap_cmd_C_mode = 0
	end
	if B747DR_hyd_sys_pressure_2<1000 then
		B747DR_ap_cmd_R_mode = 0
	end
	if B747DR_ap_approach_mode == 0 then
		--[[if simDR_autopilot_gs_status > 0 then
			simCMD_autopilot_glideslope_mode:once() -- CANX GLIDESLOPE MODE
			B747DR_ap_lastCommand = simDRTime
			return
		end
		if simDR_autopilot_nav_status > 0 then
			simCMD_autopilot_nav_mode:once() --DEACTIVATE LOC
			B747DR_ap_lastCommand = simDRTime
			return
		end]]--
		if simDR_autopilot_nav_status~=0 or simDR_autopilot_gs_status~=0 then
			B747DR_ap_lastCommand = simDRTime
		end
		simDR_autopilot_nav_status=0
		simDR_autopilot_gs_status=0

		return
	end -- no approach mode enabled
	local diffap = getHeadingDifference(simDR_radio_nav_obs_deg[0], simDR_AHARS_heading_deg_pilot)
	if diffap > -120 and diffap < 120 then --can really arm the mode
		if B747DR_ap_approach_mode == -1 then --WANT LOC
			if simDR_autopilot_nav_status == 0 or simDR_autopilot_gs_status > 0 then
				--simCMD_autopilot_nav_mode:once() --ACTIVATE LOC
				simDR_autopilot_nav_status=1
				simDR_autopilot_gs_status=0

				B747DR_ap_lastCommand = simDRTime

			end
		elseif B747DR_ap_approach_mode == 1 then --WANT APP
			if simDR_autopilot_gs_status == 0 and simDR_radarAlt1 < 3500 then
				print("simCMD_autopilot_appr_mode in B747DR_ap_approach_mode=1")
				--simCMD_autopilot_appr_mode:once() --ACTIVATE APP
				simDR_autopilot_nav_status=1
				simDR_autopilot_gs_status=1
				B747DR_ap_lastCommand = simDRTime
			end
		end
	elseif simDR_autopilot_nav_status > 0 then
		--[[if simDR_autopilot_gs_status > 0 then
			print("simCMD_autopilot_appr_mode in elseif")
			simCMD_autopilot_appr_mode:once() --DEACTIVATE APP
			B747DR_ap_lastCommand = simDRTime
		else
			simCMD_autopilot_nav_mode:once() --DEACTIVATE LOC
			B747DR_ap_lastCommand = simDRTime
		end]]--
		simDR_autopilot_nav_status=0
		simDR_autopilot_gs_status=0
		B747DR_ap_lastCommand = simDRTime
	elseif simDR_autopilot_gs_status > 0 then
		--simCMD_autopilot_glideslope_mode:once() -- CANX GLIDESLOPE MODE
		simDR_autopilot_nav_status=0
		simDR_autopilot_gs_status=0
		B747DR_ap_lastCommand = simDRTime
	end
	if simDR_onGround == 1 then
		print("simDR_onGround to B747DR_ap_approach_mode=0")
		B747DR_ap_approach_mode = 0
	end

	if B747DR_ap_lnav_state > 0 and simDR_autopilot_heading_status == 0 and simDR_autopilot_nav_status == 0 then
		simCMD_autopilot_heading_select:once()
		B747DR_ap_ATT = 0.0
		B747DR_ap_lastCommand = simDRTime
	end
end

function checkLNAV()
	if simDR_autopilot_gpss ~= 2 and B747DR_ap_approach_mode == 0 then
		B747DR_ap_lnav_state = 0
	end
end

----- FLIGHT MODE ANNUNCIATORS ----------------------------------------------------------

dofile("B747.autoland.lua")
dofile("B747.70.xt.autopilot.monitor.lua")
local apWasOn=0
function fma_rollModes()
	local diff = simDRTime - B747DR_ap_lastCommand

	if diff < 0.2 then
		return
	end
	-- ROLL MODES: ARMED
	-- ----------------------------------------------------------------------------------

	-- (NONE) --
	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
	if numAPengaged>0 then
		apWasOn=1
	end
	if numAPengaged>0 or B747DR_toggle_switch_position[23] > 0.5 or B747DR_toggle_switch_position[24] > 0.5 then
		B747BR_showFMA=1
	else
		B747BR_showFMA=0
	end
	if B747DR_toggle_switch_position[23] == 0.0 and B747DR_toggle_switch_position[24] == 0.0  and numAPengaged == 0 and apWasOn==1 then
		-- (LNAV) --
		B747DR_ap_FMA_armed_roll_mode = 0
	elseif simDR_autopilot_gpss == 1 or B747DR_ap_lnav_state == 1 then
		B747DR_ap_FMA_armed_roll_mode = 2
	elseif B747DR_autopilot_nav_status == 1 or (B747DR_ap_approach_mode ~= 0 and B747DR_autopilot_nav_status ~= 2) then
		-- (LOC) --
		B747DR_ap_FMA_armed_roll_mode = 3
	elseif simDR_radarAlt1 > 200 and (B747DR_ap_AFDS_status_annun_pilot == 3 or B747DR_ap_AFDS_status_annun_pilot == 4) then
		-- ROLLOUT and FLARE ARMED
		B747DR_ap_FMA_armed_roll_mode = 4
	else
		B747DR_ap_FMA_armed_roll_mode = 0
	end

	-- ROLL MODES: ACTIVE
	-- ----------------------------------------------------------------------------------

	-- (NONE) --
	--B747DR_ap_FMA_active_roll_mode = 0

	-- (TOGA) --
	local navcrz = simDR_nav1_radio_course_deg
	--print("navcrz "..navcrz)
	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
	if B747DR_toggle_switch_position[23] == 0.0 and B747DR_toggle_switch_position[24] == 0.0  and numAPengaged == 0 and apWasOn==1 then
		-- (TOGA) --
		B747DR_ap_FMA_active_roll_mode = 0
	elseif
	--simDR_autopilot_roll_status == 2 and simDR_autopilot_flight_dir_mode > 0 and
		math.abs(B747DR_ap_ATT) >= 5.0
 	then
		B747DR_ap_FMA_active_roll_mode = 5
	elseif B747DR_autopilot_TOGA_status~=0 then --simDR_autopilot_TOGA_lat_status == 2 then
		B747DR_ap_FMA_active_roll_mode = 1
	elseif simDR_onGround == 1 then
		-- (LOC) --
		B747DR_ap_FMA_active_roll_mode = 0
		B747DR_ap_thrust_mode = 0
	elseif B747DR_autopilot_nav_status == 2 then
		-- (LNAV) --
		B747DR_ap_FMA_active_roll_mode = 3
		--simDR_autopilot_heading_deg = roundToIncrement(simDR_radio_nav_obs_deg[0], 1) -- SET THE SELECTED HEADING VALUE TO THE LOC COURSE
		B747DR_ap_lnav_state = 0
	elseif simDR_autopilot_gpss == 2 or B747DR_ap_lnav_state == 2 then
		-- (ROLLOUT) --
		-- TODO: AUTOLAND LOGIC

		B747DR_ap_FMA_active_roll_mode = 2

		local diff = simDRTime - B747DR_ap_lastCommand
		--reactivate LNAV if required
		if diff > 0.5 and simDR_autopilot_gpss == 0 and B747DR_ap_approach_mode == 0 then
			print("simDR_autopilot_gpss == 2 or B747DR_ap_lnav_state==2")
			simCMD_autopilot_gpss_mode:once()
			B747DR_ap_lnav_state = 2
			run_after_time(checkLNAV, 0.5)
			B747DR_ap_lastCommand = simDRTime
		end
	elseif simDR_autopilot_heading_status == 2 and B747DR_ap_lnav_state == 0 then
		-- (HDG SEL) --
		simDR_autopilot_heading_deg = B747DR_ap_heading_deg
		B747DR_ap_FMA_active_roll_mode = 6
	elseif simDR_autopilot_heading_hold_status == 2 then
		-- (HDG HLD) --
		B747DR_ap_FMA_active_roll_mode = 7
		B747DR_ap_lnav_state = 0
	else
		B747DR_ap_FMA_active_roll_mode = 0
		if B747DR_ap_lnav_state == 2 then
			B747DR_ap_lnav_state = 0
		end
	end
end
local restoreAlt=0
function restoreAltFunc()
	simDR_autopilot_altitude_ft=restoreAlt
end
local lastGSProgress=0
function glideSlopeLOCProgress()
	--print("B747DR_ap_approach_mode "..B747DR_ap_approach_mode.." B747DR_engine_TOGA_mode "..B747DR_engine_TOGA_mode)
	if B747DR_ap_approach_mode == 0 or B747DR_engine_TOGA_mode == 1 then
		B747DR_autopilot_gs_status = 0
		B747DR_autopilot_nav_status = 0
		B747DR_ap_approach_mode = 0
	elseif B747DR_toggle_switch_position[23] == 1.0 or B747DR_toggle_switch_position[24] == 1.0 then
		if 	simDR_autopilot_gs_status>B747DR_autopilot_gs_status  then
			B747DR_autopilot_gs_status=simDR_autopilot_gs_status
		end
		if 	simDR_autopilot_nav_status>B747DR_autopilot_nav_status  then
			B747DR_autopilot_nav_status=simDR_autopilot_nav_status
		end
		local diff=simDRTime-lastGSProgress
		if simDR_autopilot_nav_status ==0 and B747DR_autopilot_nav_status>1 and diff>1 then
			lastGSProgress=simDRTime
			print("recover LOC mode")
			--simCMD_pause:once()
			if B747DR_autopilot_nav_status > 0 then
				--simCMD_autopilot_nav_mode:once() --DEACTIVATE LOC
				simDR_autopilot_nav_status=1

				B747DR_ap_lastCommand = simDRTime
				return
			end
		end
		if simDR_autopilot_gs_status ==0 and B747DR_autopilot_gs_status>1 and diff>1 then
			lastGSProgress=simDRTime
			print("recover GS mode")
			--simCMD_pause:once()
			if B747DR_autopilot_gs_status > 0 then
				--simCMD_autopilot_glideslope_mode:once() -- CANX GLIDESLOPE MODE
				simDR_autopilot_gs_status=1
				B747DR_ap_lastCommand = simDRTime
				return
			end
		end

	end
end
function fma_PitchModes()
	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode

	-- PITCH MODES: ARMED
	-- ----------------------------------------------------------------------------------

	-- (NONE) --

	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
	if B747DR_toggle_switch_position[23] == 0.0 and B747DR_toggle_switch_position[24] == 0.0  and numAPengaged == 0 and apWasOn==1 then
			-- (TOGA) --
		B747DR_ap_FMA_armed_pitch_mode = 0
	elseif B747DR_ap_vnav_state == 1 then
		-- (G/S) --
		B747DR_ap_FMA_armed_pitch_mode = 4
	elseif B747DR_autopilot_gs_status == 1 or (B747DR_ap_approach_mode > 0 and B747DR_autopilot_gs_status ~= 2) then
		-- (VNAV) --
		B747DR_ap_FMA_armed_pitch_mode = 2
	elseif B747DR_ap_vnav_state == 1 then
		B747DR_ap_FMA_armed_pitch_mode = 4
	elseif simDR_radarAlt1 > 200 and (B747DR_ap_AFDS_status_annun_pilot == 3 or B747DR_ap_AFDS_status_annun_pilot == 4) then
		-- ROLLOUT and FLARE ARMED (dont get here once in autoland)
		B747DR_ap_FMA_armed_pitch_mode = 3
	else
		-- (FLARE) --
		B747DR_ap_FMA_armed_pitch_mode = 0
	end

	-- PITCH MODES: ACTIVE
	-- ----------------------------------------------------------------------------------
	local altDiff=math.abs(simDR_pressureAlt1-simDR_autopilot_altitude_ft)
	-- (NONE) --
	--B747DR_ap_FMA_active_pitch_mode = 0
	if B747DR_toggle_switch_position[23] == 0.0 and B747DR_toggle_switch_position[24] == 0.0 and numAPengaged == 0 and apWasOn==1 then
		-- (TOGA) --
		if (simDRTime - B747DR_switching_servos_on) > 1 then
			B747_ap_all_cmd_modes_off()
			simCMD_autopilot_servos_fdir_off:once()
			simCMD_autopilot_servos2_fdir_off:once()
			simCMD_autopilot_servos3_fdir_off:once()
		end

		B747DR_ap_FMA_active_pitch_mode = 0
		B747DR_ap_vnav_state = 0
		B747DR_ap_lnav_state = 0
		B747DR_ap_inVNAVdescent = 0
		--B747DR_ap_thrust_mode=0
		B747DR_engine_TOGA_mode = 0
		--if B747DR_autopilot_gs_status ~= 2 and B747DR_autopilot_nav_status ~= 2 then
		B747DR_ap_approach_mode = 0
		apWasOn=0
		B747DR_autopilot_gs_status = 0
		B747DR_autopilot_nav_status = 0
		--end
	elseif B747DR_autopilot_TOGA_status == 1 then
		--if B747DR_engine_TOGA_mode == 1 then

		B747DR_ap_FMA_active_pitch_mode = 1
	elseif simDR_onGround == 1 then
		-- (G/S) --
		B747DR_ap_FMA_active_pitch_mode = 0
	elseif B747DR_autopilot_gs_status == 2 then
		-- (FLARE) --
		-- TODO: AUTOLAND LOGIC

		B747DR_ap_FMA_active_pitch_mode = 2 -- (GS) --
		B747DR_ap_vnav_state = 0
		B747DR_ap_inVNAVdescent = 0
		B747DR_ap_flightPhase = 4
		B747DR_ap_thrust_mode = 0
	elseif (simDR_autopilot_fms_vnav == 1 or B747DR_ap_vnav_state >= 2) and simDR_autopilot_flch_status == 2 then


		B747DR_ap_FMA_active_pitch_mode = 4 -- (VNAV SPD) --

	 --
	elseif (simDR_autopilot_fms_vnav == 1 or B747DR_ap_vnav_state >= 2) and (simDR_autopilot_alt_hold_status == 2 or altDiff<B747DR_alt_capture_window) then
		--[[if clbderate==0 then
			throttlederate=1.0
		elseif clbderate==1 then
			throttlederate=0.9
		elseif clbderate==2 then
			throttlederate=0.8
		end   ]]
		-- (VNAV PATH) --
		if B747DR_mcp_hold == 1 and (simDR_autopilot_altitude_ft / 100 ~= tonumber(string.sub(fmsData["crzalt"], 3))) then
			B747DR_ap_FMA_active_pitch_mode = 5 --VNAV ALT - MCP alt
		else
			B747DR_ap_FMA_active_pitch_mode = 6 --VNAV PTH - FMC alt
		end
	elseif (simDR_autopilot_fms_vnav == 1 or B747DR_ap_vnav_state >= 2) and simDR_autopilot_vs_status == 2 then
		-- (V/S) --
		if B747DR_ap_flightPhase == 3 and simDR_autopilot_vs_fpm == -500 then
			B747DR_ap_FMA_active_pitch_mode = 4 -- (VNAV SPD) --
		else
			B747DR_ap_FMA_active_pitch_mode = 6 -- (VNAV PATH) --
		end
	elseif (simDR_autopilot_vs_status == 2 and altDiff>B747DR_alt_capture_window) and simDR_autopilot_fms_vnav == 0 and B747DR_ap_vnav_state == 0 and simDR_autopilot_alt_hold_status ~= 2 then
		-- (FLCH SPD) --
		B747DR_ap_FMA_active_pitch_mode = 7 --VS


	elseif (simDR_autopilot_flch_status == 2 and altDiff>B747DR_alt_capture_window) and simDR_autopilot_fms_vnav == 0 and B747DR_ap_vnav_state == 0 and simDR_autopilot_alt_hold_status ~= 2 then
		-- (ALT) --
		B747DR_ap_FMA_active_pitch_mode = 8 --FLCH

	elseif (simDR_autopilot_alt_hold_status == 2 or altDiff<B747DR_alt_capture_window) and simDR_autopilot_fms_vnav == 0 and B747DR_ap_vnav_state == 0 then
		--throttlederate=1.0

		B747DR_ap_FMA_active_pitch_mode = 9 -- ALT
	else
		-- (NONE) --
		--throttlederate=1.0
		B747DR_ap_FMA_active_pitch_mode = 0
	end
end

function B747_ap_fma()
	B747DR_capt_ap_roll = B747_animate_value(B747DR_capt_ap_roll, B747DR_ap_target_roll - simDR_capt_roll, -25, 25, 10)
	B747DR_fo_ap_roll = B747_animate_value(B747DR_fo_ap_roll, B747DR_ap_target_roll - simDR_fo_roll, -25, 25, 10)
	--B747DR_capt_ap_roll=B747DR_ap_target_roll-simDR_capt_roll
	--B747DR_fo_ap_roll=B747DR_ap_target_roll-simDR_fo_roll
	glideSlopeLOCProgress()
	if B747DR_autothrottle_active==0 then
		B747DR_ap_FMA_autothrottle_mode = 0
	elseif B747DR_autothrottle_active==1 and B747DR_ap_FMA_active_pitch_mode==2 and B747DR_ap_FMA_autothrottle_mode ~= 3 then -- SPD
			B747DR_ap_lastCommand=simDRTime
			B747DR_ap_FMA_autothrottle_mode=3
	end
	if (B747DR_ap_AFDS_status_annun_pilot == 3 or B747DR_ap_AFDS_status_annun_pilot == 4) and runAutoland() then
		return
	end
	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
	-- AUTOTHROTTLE
	-------------------------------------------------------------------------------------
	if B747DR_ap_autoland == 1 and simDR_radarAlt1 < 25 then

		B747DR_ap_FMA_autothrottle_mode = 2 --IDLE
	elseif B747DR_toggle_switch_position[29] == 0 or B747DR_autothrottle_fail > 0 then
		B747DR_ap_FMA_autothrottle_mode = 0
	elseif
		(B747DR_engine_TOGA_mode > 0 and simDR_ind_airspeed_kts_pilot < 65) or B747DR_ap_autoland < 0 or
			(B747DR_ap_vnav_state == 0 and B747DR_ap_thrust_mode > 0)
	 then
		if B747DR_engine_TOGA_mode == 1 then
			B747DR_engine_TOGA_mode = 0
			B747DR_ap_FMA_autothrottle_mode = 0
		else
			B747DR_ap_FMA_autothrottle_mode = 5 --THR REF
		end
	elseif (B747DR_engine_TOGA_mode > 0 and simDR_radarAlt1 < 50) then
		B747DR_ap_FMA_autothrottle_mode = 1 --HOLD
		B747DR_engine_TOGA_mode = 1 --reached hold state
	elseif
		(simDR_autopilot_fms_vnav == 1 or B747DR_ap_vnav_state == 2) and
			(((simDR_autopilot_flch_status > 0 and (simDR_pressureAlt1> simDR_autopilot_altitude_ft+B747DR_alt_capture_window or simDR_pressureAlt1< simDR_autopilot_altitude_ft-B747DR_alt_capture_window)) or B747DR_engine_TOGA_mode == 1) and B747DR_ap_inVNAVdescent == 0)
	 then
		B747DR_ap_FMA_autothrottle_mode = 5 --THR REF
	elseif B747DR_autothrottle_active == 1 then
		if B747DR_ap_vnav_state > 0 and simDR_allThrottle < 0.1 and B747DR_ap_inVNAVdescent > 0 then
			B747DR_ap_FMA_autothrottle_mode = 2 --IDLE
		elseif simDR_onGround == 0 and B747DR_ap_FMA_active_pitch_mode==1 then --TOGA
			B747DR_ap_FMA_autothrottle_mode = 5 --THR REF
		elseif simDR_onGround == 0 then
			B747DR_ap_FMA_autothrottle_mode = 3 -- SPD
		end
	else
		if B747DR_ap_vnav_state > 0 and simDR_allThrottle < 0.1 and simDR_onGround == 0 then
			B747DR_ap_FMA_autothrottle_mode = 2 --IDLE
		elseif (B747DR_ap_vnav_state > 0 or isATEnabled()) and simDR_onGround == 0  and simDR_radarAlt1 < 50 then
			B747DR_ap_FMA_autothrottle_mode = 1 --HOLD
		else
			B747DR_ap_FMA_autothrottle_mode = 0
			--simDR_override_throttles = 0
		end
	end

	if simDR_radarAlt1 > 50 and B747DR_ap_lnav_state == 1 then
		B747DR_ap_lnav_state = 2
		print("simDR_radarAlt1>50 and B747DR_ap_lnav_state==1")
		if simDR_autopilot_gpss == 0 then
			simCMD_autopilot_gpss_mode:once()
		end
		simDR_autopilot_gpss = 2
		-- simCMD_autopilot_gpss_mode:once()
		run_after_time(checkLNAV, 0.5)
	end

	if B747DR_toggle_switch_position[23] == 0.0 and B747DR_toggle_switch_position[24] == 0.0  and numAPengaged == 0 then
		B747DR_ap_approach_mode = 0
	end
	fma_rollModes()
	fma_PitchModes()
end

function ap_reset()
	print("full reset AP in B747_ap_afds")
	B747CMD_ap_reset:once()
	B747DR_ap_lastCommand=simDRTime
end

local B747_ap_AFDS_status_annun = 0
function set_afds_status(value)
	if value ~= B747_ap_AFDS_status_annun then
		print("Set AFDS=" .. value .. " @ " .. simDR_radarAlt1 .. "feet")
	end
	B747_ap_AFDS_status_annun = value
	if value == 1 then
		if B747DR_toggle_switch_position[23] == 1.0 then
			B747DR_ap_AFDS_status_annun_pilot = value
		else
			B747DR_ap_AFDS_status_annun_pilot = 0
		end
		if B747DR_toggle_switch_position[24] == 1.0 then
			B747DR_ap_AFDS_status_annun_copilot = value
		else
			B747DR_ap_AFDS_status_annun_copilot = 0
		end
	else
		B747DR_ap_AFDS_status_annun_pilot = value
		B747DR_ap_AFDS_status_annun_copilot = value
	end
end
---- AFDS STATUS -------------------------------------------------------------------------
function B747_ap_afds()
	local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
	if simDR_autopilot_servos_on == 0 then
		if numAPengaged > 0 and (simDRTime - B747DR_switching_servos_on) > 1 then
			print("reset AP in B747_ap_afds")
			run_after_time(ap_reset, 2)
			B747DR_CAS_warning_status[0] = 1
			B747DR_ap_cmd_L_mode = 0
			B747DR_ap_cmd_C_mode = 0
			B747DR_ap_cmd_R_mode = 0
		elseif numAPengaged == 0 then
			B747DR_switching_servos_on = simDRTime

		end


		--simDR_autopilot_approach_status =0
		B747DR_ap_autoland = 0
		landAssist = false
	elseif simDR_autopilot_servos_on == 1 and (simDRTime - B747DR_switching_servos_on) > 1 then
		if numAPengaged == 0 then
			if B747DR_autothrottle_active == 1 then
				run_after_time(autothrottle_reengage,0.5)
			end
			B747CMD_ap_reset:once()
			simCMD_autopilot_servos_off:once()
			simDR_autopilot_servos_on=0
			B747_ap_all_cmd_modes_off()
			B747DR_CAS_warning_status[0] = 1
			B747DR_ap_lastCommand=simDRTime

		end
	end
	local diff = simDRTime - B747DR_ap_lastCommand
	if diff < 0.1 then
		return
	end

	local landAssist = false

	if ((B747DR_autopilot_nav_status ==2 and B747DR_autopilot_gs_status==2) or simDR_autopilot_approach_status > 1 or B747DR_ap_autoland == 1) and simDR_radarAlt1<1500 then
		landAssist = true
	end
	noAutoLand = false
	if
		numAPengaged > 0 and (B747DR_ap_approach_mode ~= 0) and simDR_radarAlt1 > 200 and simDR_radarAlt1 < 1000 and
		B747DR_autopilot_nav_status ~= 2 and
		B747DR_autopilot_gs_status ~= 2
	 then
		set_afds_status(5)
		noAutoLand = true
	elseif numAPengaged == 1 then -- TODO:  CHANGE TO "==" WHEN AUTOLAND LOGIC (BELOW) IS IMPLEMENTED
		-- TODO: IF LOC OR APP CAPTURED ? THEN...
		if landAssist == true and simDR_radarAlt1 < 1500 then
			set_afds_status(5) -- AFDS MODE = "NO AUTOLAND" (NOT MODELED)
		else
			set_afds_status(2) -- AFDS MODE = "CMD"
		end
	elseif numAPengaged == 2 and landAssist == true then
		set_afds_status(3) -- AFDS MODE = "LAND 2"
		B747_AFDS_land2_EICAS_status = 1
	elseif numAPengaged == 3 and landAssist == true then
		set_afds_status(4) -- AFDS MODE = "LAND 3"
		B747_AFDS_land3_EICAS_status = 1
	else
		if numAPengaged >= 1 then
			set_afds_status(2) -- AFDS MODE = "CMD"
		elseif B747DR_toggle_switch_position[23] > 0.95 or B747DR_toggle_switch_position[24] > 0.95 then
			set_afds_status(1) -- AFDS MODE = "FD"
		else
			set_afds_status(0)
		end
	end
	if noAutoLand then
		B747DR_CAS_advisory_status[246] = 1
	else
		B747DR_CAS_advisory_status[246] = 0
	end
end

----- FLIGHT MODE ANNUNCIATORS MODE CHANGE BOX ------------------------------------------
function B747_AFDS_status_mode_chg_timeout()
	B747DR_ap_AFDS_mode_box_status_pilot = 0
	B747DR_ap_AFDS_mode_box_status_copilot = 0
end

function B747_AFDS_status_mode_chg2_timeout()
	B747DR_ap_AFDS_mode_box2_status_pilot = 0
	B747DR_ap_AFDS_mode_box2_status_copilot = 0
end

function B747_at_mode_chg_timeout()
	B747DR_ap_FMA_autothrottle_mode_box_status = 0
end

function B747_roll_mode_chg_timeout()
	B747DR_ap_roll_mode_box_status = 0
end

function B747_pitch_mode_chg_timeout()
	B747DR_ap_pitch_mode_box_status = 0
end

function B747_ap_afds_fma_mode_change()
	-- AFDS STATUS
	if B747_ap_AFDS_status_annun ~= B747_ap_last_AFDS_status then
		if B747_ap_AFDS_status_annun == 0 then -- MODE IS "NONE"
			if is_timer_scheduled(B747_AFDS_status_mode_chg2_timeout) == true then -- TEST IF TIMER IS RUNNING
				stop_timer(B747_AFDS_status_mode_chg2_timeout) -- KILL THE TIMER
			end
			B747DR_ap_AFDS_mode_box_status_pilot = 0
			B747DR_ap_AFDS_mode_box_status_copilot = 0
			B747DR_ap_AFDS_mode_box2_status_pilot = 0
			B747DR_ap_AFDS_mode_box2_status_copilot = 0
		elseif B747_ap_AFDS_status_annun > 0 and B747_ap_AFDS_status_annun < 5 then -- MODE IS NOT "NONE" AND NOT "NO AUTOLAND"
			if B747DR_toggle_switch_position[23] == 1 then
				B747DR_ap_AFDS_mode_box_status_pilot = 1
			else
				B747DR_ap_AFDS_mode_box2_status_pilot = 0
			end -- SHOW THE MODE CHANGE BOX
			if B747DR_toggle_switch_position[24] == 1 then
				B747DR_ap_AFDS_mode_box_status_copilot = 1
			else
				B747DR_ap_AFDS_mode_box2_status_copilot = 0
			end -- SHOW THE MODE CHANGE BOX                                          -- SHOW THE MODE CHANGE BOX
			if is_timer_scheduled(B747_AFDS_status_mode_chg_timeout) == false then -- CHECK TIMEOUT STATUS
				run_after_time(B747_AFDS_status_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			else
				stop_timer(B747_AFDS_status_mode_chg_timeout) -- STOP PREVIOUS TIMER
				run_after_time(B747_AFDS_status_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			end
		elseif B747_ap_AFDS_status_annun == 5 then -- MODE IS "NO AUTOLAND"
			B747DR_ap_AFDS_mode_box_status_pilot = 0
			B747DR_ap_AFDS_mode_box_status_copilot = 0
			if B747DR_toggle_switch_position[23] == 1 then
				B747DR_ap_AFDS_mode_box2_status_pilot = 1
			end -- SHOW THE MODE CHANGE BOX
			if B747DR_toggle_switch_position[24] == 1 then
				B747DR_ap_AFDS_mode_box2_status_copilot = 1
			end -- SHOW THE MODE CHANGE BOX
			if is_timer_scheduled(B747_AFDS_status_mode_chg2_timeout) == false then -- CHECK TIMEOUT STATUS
				run_after_time(B747_AFDS_status_mode_chg2_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			else
				stop_timer(B747_AFDS_status_mode_chg2_timeout) -- STOP PREVIOUS TIMER
				run_after_time(B747_AFDS_status_mode_chg2_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			end
		end
	end
	B747_ap_last_AFDS_status = B747_ap_AFDS_status_annun -- RESET LAST MODE

	-- AUTOTHROTTLE MODE
	if B747DR_ap_FMA_autothrottle_mode ~= B747_ap_last_FMA_autothrottle_mode then -- THE MODE HAS CHANGED
		if B747DR_ap_FMA_autothrottle_mode == 0 then -- MODE IS "NONE"
			if is_timer_scheduled(B747_at_mode_chg_timeout) == true then -- TEST IF TIMER IS RUNNING
				stop_timer(B747_at_mode_chg_timeout) -- KILL THE TIMER
			end
			B747DR_ap_FMA_autothrottle_mode_box_status = 0
		elseif B747DR_ap_FMA_autothrottle_mode > 0 then -- MODE IS NOT "NONE"
			B747DR_ap_FMA_autothrottle_mode_box_status = 1 -- SHOW THE MODE CHANGE BOX
			if is_timer_scheduled(B747_at_mode_chg_timeout) == false then -- CHECK TIMEOUT STATUS
				run_after_time(B747_at_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			else
				stop_timer(B747_at_mode_chg_timeout) -- STOP PREVIOUS TIMER
				run_after_time(B747_at_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			end
		end
	end
	B747_ap_last_FMA_autothrottle_mode = B747DR_ap_FMA_autothrottle_mode -- RESET LAST MODE

	-- ROLL MODE
	if B747DR_ap_FMA_active_roll_mode ~= B747_ap_last_FMA_roll_mode then -- THE MODE HAS CHANGED
		if B747DR_ap_FMA_active_roll_mode == 0 then -- MODE IS "NONE"
			if is_timer_scheduled(B747_roll_mode_chg_timeout) == true then -- TEST IF TIMER IS RUNNING
				stop_timer(B747_roll_mode_chg_timeout) -- KILL THE TIMER
			end
			B747DR_ap_roll_mode_box_status = 0
		elseif B747DR_ap_FMA_active_roll_mode > 0 then -- MODE IS NOT "NONE"
			B747DR_ap_roll_mode_box_status = 1 -- SHOW THE MODE CHANGE BOX
			if is_timer_scheduled(B747_roll_mode_chg_timeout) == false then -- CHECK TIMEOUT STATUS
				run_after_time(B747_roll_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			else
				stop_timer(B747_roll_mode_chg_timeout) -- STOP PREVIOUS TIMER
				run_after_time(B747_roll_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			end
		end
	end
	B747_ap_last_FMA_roll_mode = B747DR_ap_FMA_active_roll_mode -- RESET LAST MODE

	-- PITCH MODE
	if B747DR_ap_FMA_active_pitch_mode ~= B747_ap_last_FMA_pitch_mode then -- THE MODE HAS CHANGED
		if B747DR_ap_FMA_active_pitch_mode == 0 then -- MODE IS "NONE"
			if is_timer_scheduled(B747_pitch_mode_chg_timeout) == true then -- TEST IF TIMER IS RUNNING
				stop_timer(B747_pitch_mode_chg_timeout) -- KILL THE TIMER
			end
			B747DR_ap_pitch_mode_box_status = 0
		elseif B747DR_ap_FMA_active_pitch_mode > 0 then -- MODE IS NOT "NONE"
			B747DR_ap_pitch_mode_box_status = 1 -- SHOW THE MODE CHANGE BOX
			if is_timer_scheduled(B747_pitch_mode_chg_timeout) == false then -- CHECK TIMEOUT STATUS
				run_after_time(B747_pitch_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			else
				stop_timer(B747_pitch_mode_chg_timeout) -- STOP PREVIOUS TIMER
				run_after_time(B747_pitch_mode_chg_timeout, 10.0) -- SET TO TIMEOUT IN 10 SECONDS
			end
		end
	end
	B747_ap_last_FMA_pitch_mode = B747DR_ap_FMA_active_pitch_mode -- RESET LAST MODE
end

----- TURN AUTOPILOT COMMAND MODES OFF --------------------------------------------------
function B747_ap_all_cmd_modes_off()
	print("B747_ap_all_cmd_modes_off")
	B747DR_ap_cmd_L_mode = 0
	B747DR_ap_cmd_C_mode = 0
	B747DR_ap_cmd_R_mode = 0
	--B747DR_ap_approach_mode = 0
	B747DR_switching_servos_on = simDRTime
end

local last_airspeed = 0
local last_target_heading = 0
function B747_interpolate_value(current_value, target, min, max, speed)--speed in sex min->max

    --[[if math.abs(current_value-target) <0.01 then
      return target
    end]]

    local change = ((max-min)/speed)*(SIM_PERIOD)
    newValue=current_value

    if newValue<=target then
      newValue=newValue+change
      --print(current_value.." ->newValue<= "..newValue)
      if newValue >= target then
        newValue = B747_animate_value(current_value,target,-100,100,100)
      end
    elseif newValue>target then
      newValue=newValue-change
      --print(current_value.." ->newValue>= "..newValue)
      if newValue <= target then
        newValue = B747_animate_value(current_value,target,-100,100,100)
      end
    end
    if newValue <= min+0.001 and newValue >= min-0.001 then
        newValue = min
    elseif newValue >= max-0.001 and newValue <= max+0.001 then
        newValue = max
    elseif newValue <= min then
      newValue = B747_animate_value(current_value,min,-100,100,100)
    elseif newValue >= max then
      newValue = B747_animate_value(current_value,max,-100,100,100)
    else
      --print(current_value.." ->newValue== "..newValue)
      --newValue = newValue
      if math.abs(current_value-target) < change then
        newValue = B747_animate_value(current_value,target,-100,100,100)
      --  print(current_value.." ->newValue== "..newValue)
      --else
      --  print(current_value.." ->newValue=== "..newValue)
      end


    end
    return newValue
  end
function B747_ap_target_flaps()
	if B747DR_ap_target_flaps == -1 then
		return
	end
	local diff = simDRTime - last_target_heading --set by next function
	if diff < 0.05 then
		return
	end
	local cFlaps=0
	local fTarget=0
	if B747DR_ap_target_flaps==0 then --flaps 1
		fTarget=0.0
	elseif B747DR_ap_target_flaps==1 then --flaps 1
		fTarget=0.167
	 elseif B747DR_ap_target_flaps== 5 then --flaps 5
		fTarget=0.333
	 elseif B747DR_ap_target_flaps==10 then --flaps 10
		fTarget=0.50
	 elseif B747DR_ap_target_flaps==20 then --flaps 20
		fTarget=0.667
	 elseif B747DR_ap_target_flaps==25 then --flaps 25
		fTarget=0.833
	 elseif B747DR_ap_target_flaps==30 then --flaps 30
		fTarget=1.0
	 else
		B747DR_ap_target_flaps=-1
		return
	 end
	 if fTarget<simDR_flap_ratio_control+0.01 and fTarget>simDR_flap_ratio_control-0.01 then
		B747DR_ap_target_flaps = -1
		print("set flaps")
		return
	 end
	 if simDR_flap_ratio_control>fTarget then
		simDR_flap_ratio_control=B747_interpolate_value(simDR_flap_ratio_control,0,0,1,8)
	 else
		simDR_flap_ratio_control=B747_interpolate_value(simDR_flap_ratio_control,1,0,1,8)
	 end
end
function B474_ap_target_vspeed()
	if B747DR_ap_target_vertspeed == -1 then
		return
	end
	if B747DR_ap_target_vertspeed == B747DR_autopilot_vs_fpm then
		B747DR_ap_target_vertspeed = -1
		return
	end
	if B747DR_ap_target_vertspeed<-8000 then
		B747DR_ap_target_vertspeed=-1
		return
	end
	if B747DR_ap_target_vertspeed>8000 then
		B747DR_ap_target_vertspeed=-1
		return
	end
	if B747DR_ap_vs_window_open==0 then
		B747CMD_ap_switch_vs_mode:once()
		return
	end
	--B747DR_ap_target_heading_deg = math.floor(B747DR_ap_target_speed)
	local vspd_diff = B747DR_autopilot_vs_fpm - B747DR_ap_target_vertspeed
	if vspd_diff<100 and vspd_diff>-100 then
		B747DR_ap_target_vertspeed = -1
		print("set vspeed")
		return
	 end
	print("target spd " .. B747DR_autopilot_vs_fpm .. " " .. B747DR_ap_target_vertspeed .. " " .. vspd_diff)
	if vspd_diff < 0 then
		simCMD_ap_vertical_speed_up:once()
	else
		simCMD_ap_vertical_speed_down:once()
	end


end

function B474_ap_target_altitude()
	if B747DR_ap_target_altitude == -1 then
		return
	end
	if B747DR_ap_target_altitude == B747DR_autopilot_altitude_ft then
		B747DR_ap_target_altitude = -1
		return
	end
	local diff = simDRTime - last_target_heading
	if diff < 0.05 then
		return
	end
	if B747DR_ap_target_altitude<100 then
		B747DR_ap_target_altitude=-1
		return
	end
	if B747DR_ap_target_speed>40000 then
		B747DR_ap_target_altitude=-1
		return
	end

	--B747DR_ap_target_heading_deg = math.floor(B747DR_ap_target_speed)
	local alt_diff = B747DR_autopilot_altitude_ft - B747DR_ap_target_altitude
	if alt_diff<100 and alt_diff>-100 then
		B747DR_autopilot_altitude_ft=B747DR_ap_target_altitude
		B747DR_ap_target_altitude = -1
		print("set altitude")
		return
	 end
	print("target alt " .. B747DR_autopilot_altitude_ft .. " " .. B747DR_ap_target_speed .. " " .. alt_diff)
	if alt_diff < 0 then
		B747DR_autopilot_altitude_ft = math.floor(B747DR_autopilot_altitude_ft + 100)
	else
		B747DR_autopilot_altitude_ft = math.floor(B747DR_autopilot_altitude_ft - 100)
	end
end

function B474_ap_target_speed()
	if B747DR_ap_target_speed == -1 then
		return
	end
	if B747DR_ap_ias_dial_value == B747DR_ap_target_speed then
		B747DR_ap_target_speed = -1
		return
	end
	local diff = simDRTime - last_target_heading
	if diff < 0.05 then
		return
	end
	if B747DR_ap_target_speed<100 then
		B747DR_ap_target_speed=-1
		return
	end
	if B747DR_ap_target_speed>350 then
		B747DR_ap_target_speed=-1
		return
	end
	--B747DR_ap_target_heading_deg = math.floor(B747DR_ap_target_speed)
	local speed_diff = B747DR_ap_ias_dial_value - B747DR_ap_target_speed
	print("target speed " .. B747DR_ap_ias_dial_value .. " " .. B747DR_ap_target_speed .. " " .. speed_diff)
	if speed_diff < 0 then
		B747DR_ap_ias_dial_value = math.floor(B747DR_ap_ias_dial_value + 1)
	else
		B747DR_ap_ias_dial_value = math.floor(B747DR_ap_ias_dial_value - 1)
	end
end
function B474_ap_target_heading()
	if B747DR_ap_target_heading_deg == -1 then
		return
	end
	if B747DR_ap_heading_deg == B747DR_ap_target_heading_deg then
		B747DR_ap_target_heading_deg = -1
		return
	end
	local diff = simDRTime - last_target_heading
	if diff < 0.05 then
		return
	end
	last_target_heading = simDRTime

	B747DR_ap_target_heading_deg = math.floor(B747DR_ap_target_heading_deg)
	local heading_diff = getHeadingDifference(B747DR_ap_target_heading_deg, B747DR_ap_heading_deg)
	print("target heading " .. B747DR_ap_target_heading_deg .. " " .. B747DR_ap_heading_deg .. " " .. heading_diff)
	if heading_diff < 0 then
		B747DR_ap_heading_deg = math.floor(math.fmod((B747DR_ap_heading_deg + 1), 360.0))
	else
		B747DR_ap_heading_deg = math.floor(math.fmod((B747DR_ap_heading_deg - 1), 360.0))
		if B747DR_ap_heading_deg < 0.0 then
			B747DR_ap_heading_deg = B747DR_ap_heading_deg + 360.0
		end
	end
end
----- EICAS MESSAGES --------------------------------------------------------------------
function B747_ap_EICAS_msg()
	-- >AUTOPILOT

	if simDR_autopilot_fail == 6 then
		B747DR_CAS_caution_status[4] = 1
	else
		B747DR_CAS_caution_status[4] = 0
	end

	--print("test drag required".. B747DR_speedbrake_lever .. " " .. simDR_all_wheels_on_ground .. " " .. simDR_autopilot_vs_fpm .. " " .. simDR_autopilot_vs_status .. " " )
	-- >AUTOTHROT DISC
	if B747DR_autothrottle_fail == 1 then
		B747DR_CAS_caution_status[5] = 1
	else
		B747DR_CAS_caution_status[5] = 0
	end

	if
		B747DR_speedbrake_lever < 0.3 and simDR_ind_airspeed_kts_pilot > (simDR_autopilot_airspeed_kts + 10) and
			simDR_ind_airspeed_kts_pilot > last_airspeed and
			simDR_autopilot_vs_status >= 1 and
			B747DR_ap_vnav_state > 0
	 then
		if
			simDR_allThrottle < 0.01 and simDR_radarAlt1 > 1000
		 then
			B747DR_fmc_notifications[9] = 1 --DRAG REQUIRED
		end
	elseif simDR_ind_airspeed_kts_pilot ~= last_airspeed then --dont turn it off if airspeed didn't update
		B747DR_fmc_notifications[9] = 0
	end
	last_airspeed = simDR_ind_airspeed_kts_pilot
end

----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_ap_monitor_AI()
	if B747DR_init_autopilot_CD == 1 then
		B747_set_ap_all_modes()
		B747_set_ap_CD()
		B747DR_init_autopilot_CD = 2
	end
end

----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_ap_all_modes()
	B747DR_init_autopilot_CD = 0

	simDR_autopilot_airspeed_is_mach = 0
	B747DR_ap_alt_show_thousands = 1

	simDR_autopilot_airspeed_kts_mach = 0.76 --200.0
	B747DR_ap_ias_dial_value = 100
	simDR_autopilot_heading_deg = 0.0
	simDR_autopilot_vs_fpm = 0.0
	simDR_autopilot_altitude_ft = 10000.0
	B747DR_autopilot_altitude_ft = 10000.0
end

----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_ap_CD()
end

----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_ap_ER()
end

----- FLGHT START -----------------------------------------------------------------------
function B747_flight_start_autopilot()
	-- ALL MODES ------------------------------------------------------------------------
	B747_set_ap_all_modes()
	simCMD_autopilot_set_nav1_as_nav_source:once()
	simDR_autopilot_bank_limit = 4
	B747DR_ap_approach_mode=0
	-- COLD & DARK ----------------------------------------------------------------------
	if simDR_startup_running == 0 then
		-- ENGINES RUNNING ------------------------------------------------------------------
		B747_set_ap_CD()
	elseif simDR_startup_running == 1 then
		B747_set_ap_ER()
	end
end

--*************************************************************************************--
--** 				                 EVENT CALLBACKS           	        			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start()
	B747_flight_start_autopilot()
	simDR_elevator = 0
	simDR_rudder = 0
	simDR_pitch = 0
	B747DR_ap_vnav_system = 2
	simDR_disabled_autopilot_altitude_ft=150000
end

--function flight_crash() end

--function before_physics() end
debug_autopilot = deferred_dataref("laminar/B747/debug/autopilot", "number")
local setSimConfig = false
function hasSimConfig()
	if B747DR_newsimconfig_data == 1 then
		if string.len(B747DR_simconfig_data) > 1 then
			simConfigData["data"] = json.decode(B747DR_simconfig_data)
			setSimConfig = true
		else
			return false
		end
	end
	return setSimConfig
end
function after_physics()
	if hasSimConfig() == false then
		return
	end
	collectgarbage("collect")
	if debug_autopilot > 0 then
		return
	end
	simDR_allThrottle=math.max(B747DR_throttle[0],B747DR_throttle[1],B747DR_throttle[2],B747DR_throttle[3])
	local cHeading = simDR_AHARS_heading_deg_pilot --constant refresh of data
	local tHeading = simDR_autopilot_heading_deg --constant refresh of data
	local headingStatus = simDR_autopilot_heading_hold_status --constant refresh of data
	local groundspeed = simDR_groundspeed
	 --constant refresh of dat
	local latitude = simDR_latitude
	 --constant refresh of dat
	local longitude = simDR_longitude
	 --constant refresh of dat
	local vsi = B744_fpm
	local isMachSpd = simDR_autopilot_airspeed_is_mach
	local machSpd = simDR_autopilot_airspeed_kts_mach
	local flch_status = simDR_autopilot_flch_status
	local vs_status =simDR_autopilot_vs_status
	local onGround = simDR_onGround
	local cruiseAlt = B747BR_cruiseAlt
	local tDist = B747BR_totalDistance
	local tod = B747BR_tod
	--print(B747DR_FMSdata)
	if string.len(B747DR_FMSdata) > 0 then
		fmsData = json.decode(B747DR_FMSdata)
	else
		fmsData = json.decode("[]")

	end

	local fmsSTR = fmsJSON
	local fms = json.decode(fmsSTR)
	B747_getCurrentWayPoint(fms)
	B747_monitorAP(fms)
	B747_ap_fma()
	B747_ap_button_switch_animation()
	B747_fltmgmt_setILS(fms)
	B747_ap_vs_mode()
	B747_ap_ias_mach_mode()
	B747_ap_altitude()
	B747_vnav_speed()
	B747_ap_appr_mode()
	B747_ap_afds()
	B747_ap_afds_fma_mode_change()
	B747_ap_EICAS_msg()
	B747_ap_target_flaps()
	B474_ap_target_vspeed()
	B474_ap_target_speed()
	B474_ap_target_altitude()
	B474_ap_target_heading()

	B747_ap_monitor_AI()
end

--function after_replay() end

--*************************************************************************************--
--** 				               SUB-MODULE PROCESSING       	        			 **--
--*************************************************************************************--

-- dofile("")
