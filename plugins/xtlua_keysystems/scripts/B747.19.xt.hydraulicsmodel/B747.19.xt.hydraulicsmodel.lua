--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks
*****************************************************************************************
xt.hydraulicsmodel.lua
27/04/2020
]]
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end

function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
function getHeadingDifference(desireddirection,current_heading)
	error = current_heading - desireddirection
	if (error >  180) then error =error- 360 end
	if (error < -180) then error =error+ 360 end
	return error
end
--simDR_autopilot_nav_status = find_dataref("sim/cockpit2/autopilot/nav_status")
simDR_autopilot_nav_status = find_dataref("laminar/B747/autopilot/actual_nav_status")
B747DR_ap_ATT     	                = deferred_dataref("laminar/B747/autopilot/att_rate", "number")
B747DR_autopilot_nav_status = find_dataref("laminar/B747/autopilot/nav_status")
simCMD_pause = find_command("sim/operation/pause_toggle")
debug_flight_directors     = deferred_dataref("laminar/B747/debug/flight_directors", "number")
simDR_autopilot_hold_altitude_ft = find_dataref("laminar/B747/autopilot/altitude_hold_ft")
simDR_autopilot_alt_hold_status         = find_dataref("laminar/B747/autopilot/altitude_hold_status")
B747DR_autopilot_TOGA_status     	= deferred_dataref("laminar/B747/autopilot/TOGA_status","number")
simDR_hsi_vdef_dots_pilot           = find_dataref("sim/cockpit2/radios/indicators/hsi_vdef_dots_pilot")
B747DR_ap_flightPhase 				= deferred_dataref("laminar/B747/autopilot/flightPhase", "number")
B747DR_autopilot_altitude_ft_pfd = deferred_dataref("laminar/B747/autopilot/heading/altitude_dial_ft_pfd", "number")
simDR_glideslope1 = find_dataref("sim/cockpit/radios/nav1_slope_degt")
simDR_groundspeed			= find_dataref("sim/flightmodel2/position/groundspeed")
simDR_radarAlt1 = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
B747DR_flap_ratio = deferred_dataref("laminar/B747/cablecontrols/flap_ratio", "number")
B747DR_flap_lever_detent		= deferred_dataref("laminar/B747/flt_ctrls/flap_lever_detent", "number")
B747DR_pidRollP = deferred_dataref("laminar/B747/flt_ctrls/pid/roll/p", "number")
B747DR_pidRollI = deferred_dataref("laminar/B747/flt_ctrls/pid/roll/i", "number")
B747DR_pidRollDL = deferred_dataref("laminar/B747/flt_ctrls/pid/roll/dl", "number")
B747DR_pidRollDH = deferred_dataref("laminar/B747/flt_ctrls/pid/roll/dh", "number")
B747DR_pidRollD = deferred_dataref("laminar/B747/flt_ctrls/pid/roll/d", "number")

B747DR_pidPitchPL = deferred_dataref("laminar/B747/flt_ctrls/pid/pitch/pl", "number")
B747DR_pidPitchPH = deferred_dataref("laminar/B747/flt_ctrls/pid/pitch/ph", "number")
B747DR_pidPitchP = deferred_dataref("laminar/B747/flt_ctrls/pid/pitch/p", "number")
B747DR_pidPitchI = deferred_dataref("laminar/B747/flt_ctrls/pid/pitch/i", "number")
B747DR_pidPitchD = deferred_dataref("laminar/B747/flt_ctrls/pid/pitch/d", "number")


B747DR_pidyawP = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/p", "number")
B747DR_pidyawI = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/i", "number")
B747DR_pidyawD = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/d", "number")

B747DR_pidyawDslipH = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/d/slip/h", "number")
B747DR_pidyawDslipL = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/d/slip/l", "number")
B747DR_pidyawPslipH = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/p/slip/h", "number")
B747DR_pidyawPslipL = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/p/slip/l", "number")

B747DR_pidyawDrollH = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/d/roll/h", "number")
B747DR_pidyawDrollL = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/d/roll/l", "number")
B747DR_pidyawProllH = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/p/roll/h", "number")
B747DR_pidyawProllL = deferred_dataref("laminar/B747/flt_ctrls/pid/yaw/p/roll/l", "number")
B747DR_alt_capture_window        = deferred_dataref("laminar/B747/autopilot/ap_monitor/alt_capture_window", "number")

simDR_AHARS_heading_deg_pilot = find_dataref("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot")
simDR_autopilot_TOGA_pitch_deg      	= find_dataref("sim/cockpit2/autopilot/TOGA_pitch_deg")
B747DR_controlOverrides   = find_dataref("xtlua/controlObject")
B747DR_speedbrake_lever     	= deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever", "number")
simDR_prop_mode                 = find_dataref("sim/cockpit2/engine/actuators/prop_mode")
B747DR_button_switch_position   = find_dataref("laminar/B747/button_switch/position")
simDR_ias_pilot				= find_dataref("laminar/B747/gauges/indicators/airspeed_kts_pilot")
B747DR_display_N1					= deferred_dataref("laminar/B747/engines/display_N1", "array[4]")
B747DR_display_N2					= deferred_dataref("laminar/B747/engines/display_N2", "array[4]")
B747_duct_pressure_L                = deferred_dataref("laminar/B747/air/duct_pressure_L", "number")
B747_duct_pressure_R                = deferred_dataref("laminar/B747/air/duct_pressure_R", "number")
--B747DR_engine1psi    = deferred_dataref("laminar/B747/air/engine1/bleed_air_psi", "number")
--B747DR_engine4psi    = deferred_dataref("laminar/B747/air/engine4/bleed_air_psi", "number")
simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")
simDRTime=find_dataref("sim/time/total_running_time_sec")
B747DR_hyd_temp = find_dataref("sim/physics/earth_temp_c")
B747DR_hyd_sys_pressure_1      = deferred_dataref("laminar/B747/hydraulics/pressure_1", "number")
B747DR_hyd_sys_pressure_2      = deferred_dataref("laminar/B747/hydraulics/pressure_2", "number")
B747DR_hyd_sys_pressure_3      = deferred_dataref("laminar/B747/hydraulics/pressure_3", "number")
B747DR_hyd_sys_pressure_4      = deferred_dataref("laminar/B747/hydraulics/pressure_4", "number")
B747DR_hyd_sys_pressure_dsp_1      = deferred_dataref("laminar/B747/hydraulics/pressure_dsp_1", "number")
B747DR_hyd_sys_pressure_dsp_2      = deferred_dataref("laminar/B747/hydraulics/pressure_dsp_2", "number")
B747DR_hyd_sys_pressure_dsp_3      = deferred_dataref("laminar/B747/hydraulics/pressure_dsp_3", "number")
B747DR_hyd_sys_pressure_dsp_4      = deferred_dataref("laminar/B747/hydraulics/pressure_dsp_4", "number")
B747DR_hyd_sys_pressure_13      = deferred_dataref("laminar/B747/hydraulics/pressure_13", "number")
B747DR_hyd_sys_pressure_23      = deferred_dataref("laminar/B747/hydraulics/pressure_23", "number")
B747DR_hyd_sys_pressure_24      = deferred_dataref("laminar/B747/hydraulics/pressure_24", "number")
B747DR_hyd_sys_pressure_234      = deferred_dataref("laminar/B747/hydraulics/pressure_234", "number")
B747DR_hyd_sys_pressure_use_1      = deferred_dataref("laminar/B747/hydraulics/pressure_use_1", "number")
B747DR_hyd_sys_pressure_use_2      = deferred_dataref("laminar/B747/hydraulics/pressure_use_2", "number")
B747DR_hyd_sys_pressure_use_3      = deferred_dataref("laminar/B747/hydraulics/pressure_use_3", "number")
B747DR_hyd_sys_pressure_use_4      = deferred_dataref("laminar/B747/hydraulics/pressure_use_4", "number")

B747DR_hyd_sys_temp_1      = deferred_dataref("laminar/B747/hydraulics/temp_1", "number")
B747DR_hyd_sys_temp_2      = deferred_dataref("laminar/B747/hydraulics/temp_2", "number")
B747DR_hyd_sys_temp_3      = deferred_dataref("laminar/B747/hydraulics/temp_3", "number")
B747DR_hyd_sys_temp_4      = deferred_dataref("laminar/B747/hydraulics/temp_4", "number")

B747DR_hyd_sys_res_1      = deferred_dataref("laminar/B747/hydraulics/res_1", "number")
B747DR_hyd_sys_res_2      = deferred_dataref("laminar/B747/hydraulics/res_2", "number")
B747DR_hyd_sys_res_3      = deferred_dataref("laminar/B747/hydraulics/res_3", "number")
B747DR_hyd_sys_res_4      = deferred_dataref("laminar/B747/hydraulics/res_4", "number")

B747DR_hyd_sys_restotal_1      = deferred_dataref("laminar/B747/hydraulics/restotal_1", "number")
B747DR_hyd_sys_restotal_2      = deferred_dataref("laminar/B747/hydraulics/restotal_2", "number")
B747DR_hyd_sys_restotal_3      = deferred_dataref("laminar/B747/hydraulics/restotal_3", "number")
B747DR_hyd_sys_restotal_4      = deferred_dataref("laminar/B747/hydraulics/restotal_4", "number")

B747DR_hyd_dem_pressure_1      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_1", "number")
B747DR_hyd_dem_pressure_2      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_2", "number")
B747DR_hyd_dem_pressure_3      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_3", "number")
B747DR_hyd_dem_pressure_4      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_4", "number")

B747DR_hyd_edp_pressure_1      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_1", "number")
B747DR_hyd_edp_pressure_2      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_2", "number")
B747DR_hyd_edp_pressure_3      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_3", "number")
B747DR_hyd_edp_pressure_4      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_4", "number")
B747DR_hyd_aux_pressure      = deferred_dataref("laminar/B747/hydraulics/aux_pressure", "number")

B747DR_hyd_dem_mode_1      = deferred_dataref("laminar/B747/hydraulics/dem_mode_1", "number")--off auto on
B747DR_hyd_dem_mode_2      = deferred_dataref("laminar/B747/hydraulics/dem_mode_2", "number")
B747DR_hyd_dem_mode_3      = deferred_dataref("laminar/B747/hydraulics/dem_mode_3", "number")
B747DR_hyd_dem_mode_4      = deferred_dataref("laminar/B747/hydraulics/dem_mode_4", "number")-- -1 aux off auto on
-- CRT Displays/EICAS Lower/HYD/valve_on
B747DR_hyd_valve_1      = deferred_dataref("laminar/B747/hydraulics/valve_1", "number")
B747DR_hyd_valve_2      = deferred_dataref("laminar/B747/hydraulics/valve_2", "number")
B747DR_hyd_valve_3      = deferred_dataref("laminar/B747/hydraulics/valve_3", "number")
B747DR_hyd_valve_4      = deferred_dataref("laminar/B747/hydraulics/valve_4", "number")
simDR_hyd_press_1_2               = deferred_dataref("laminar/B747/hydraulics/indicators/hydraulic_pressure_1_2_4", "number")
simDR_parking_brake_ratio       = find_dataref("sim/cockpit2/controls/parking_brake_ratio")
--************ FLIGHT SURFACES **********

B747DR_rudder_lwr_pos   = deferred_dataref("laminar/B747/flt_ctrls/rudder_lwr_pos", "number")
B747DR_rudder_upr_pos   = deferred_dataref("laminar/B747/flt_ctrls/rudder_upr_pos", "number")
B747DR_rudder_ratio   = deferred_dataref("laminar/B747/flt_ctrls/rudder_ratio", "number")
B747DR_elevator_ratio   = deferred_dataref("laminar/B747/flt_ctrls/elevator_ratio", "number")
B747_controls_lower_rudder           = deferred_dataref("laminar/B747/cablecontrols/lower_rudder", "number")
B747_controls_upper_rudder           = deferred_dataref("laminar/B747/cablecontrols/upper_rudder", "number")

B747_controls_left_outer_elevator           = deferred_dataref("laminar/B747/cablecontrols/left_outer_elevator", "number")
B747_controls_right_outer_elevator            = deferred_dataref("laminar/B747/cablecontrols/right_outer_elevator", "number")
B747_controls_left_inner_elevator           = deferred_dataref("laminar/B747/cablecontrols/left_inner_elevator", "number")
B747_controls_right_inner_elevator          = deferred_dataref("laminar/B747/cablecontrols/right_inner_elevator", "number")

simDR_rudder            = find_dataref("sim/flightmodel2/wing/rudder1_deg")
B747DR_yaw_damper_lwr   = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_lwr", "number")
B747DR_yaw_damper_upr   = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_upr", "number")
simDR_sideslip             = find_dataref("sim/cockpit2/gauges/indicators/sideslip_degrees")
simDR_elevator_trim             = find_dataref("sim/flightmodel2/controls/elevator_trim")
simDR_autopilot_airspeed_kts = find_dataref("sim/cockpit2/autopilot/airspeed_dial_kts")
simDR_ind_airspeed_kts_pilot = find_dataref("laminar/B747/gauges/indicators/airspeed_kts_pilot")
B747DR_airspeed_Vmax      = find_dataref("laminar/B747/airspeed/Vmax")
B747DR_airspeed_Vmc = find_dataref("laminar/B747/airspeed/Vmc")
simDR_autopilot_altitude_ft = find_dataref("laminar/B747/autopilot/altitude_dial_ft")
simDR_pressureAlt1 = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
simDR_touchGround = find_dataref("sim/flightmodel/failures/onground_any")
simDR_autopilot_vs_fpm = find_dataref("sim/cockpit2/autopilot/vvi_dial_fpm")
B747DR_l_elev_inner   = deferred_dataref("laminar/B747/flt_ctrls/l_elev_inner", "number")
B747DR_r_elev_inner   = deferred_dataref("laminar/B747/flt_ctrls/r_elev_inner", "number")
B747DR_l_elev_outer   = deferred_dataref("laminar/B747/flt_ctrls/l_elev_outer", "number")
B747DR_r_elev_outer   = deferred_dataref("laminar/B747/flt_ctrls/r_elev_outer", "number")

simDR_yoke_pitch_ratio           = find_dataref("sim/cockpit2/controls/yoke_pitch_ratio")
B747DR_sim_pitch_ratio   = find_dataref("laminar/B747/flt_ctrls/sim_pitch_ratio")
B747DR_sim_roll_ratio   = find_dataref("laminar/B747/flt_ctrls/sim_roll_ratio")
--B747DR_yaw_damp_ratio   = deferred_dataref("laminar/B747/flt_ctrls/sim_yaw_damp_ratio", "number")
B747DR_yaw_damper_upr_on             = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_upr_on", "number")
B747DR_yaw_damper_lwr_on             = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_lwr_on", "number")
B747DR_ap_target_roll = find_dataref("sim/cockpit2/autopilot/flight_director_roll_deg")
B747DR_fo_ap_roll = find_dataref("laminar/B747/autopilot/fo_roll_ref")
B747DR_custom_pitch_ratio   = find_dataref("laminar/B747/flt_ctrls/custom_pitch_ratio")
B747DR_custom_roll_ratio   = deferred_dataref("laminar/B747/flt_ctrls/custom_roll_ratio", "number")
B747DR_ap_autoland            	= deferred_dataref("laminar/B747/autopilot/autoland", "number")
B744DR_autolandPitch            = deferred_dataref("laminar/B747/autopilot/autolandPitch", "number")
B747DR_ap_inVNAVdescent = deferred_dataref("laminar/B747/autopilot/vnav_descent", "number")
simDR_electric_trim   = find_dataref("sim/cockpit2/autopilot/electric_trim_on")
simDR_pitch_mistrim   = find_dataref("sim/cockpit2/autopilot/pitch_mistrim")
simDR_AHARS_roll_heading_deg_pilot          	= find_dataref("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot")
simDR_AHARS_pitch_heading_deg_pilot           = find_dataref("sim/cockpit2/gauges/indicators/pitch_AHARS_deg_pilot")
simDR_flight_director_pitch = find_dataref("sim/cockpit2/autopilot/flight_director_pitch_deg")
B747DR_flight_director_pitch           = deferred_dataref("laminar/B747/autopilot/flight_director_pitch_deg", "number")
B747DR_flight_director_roll 		= deferred_dataref("laminar/B747/autopilot/flight_director_roll_deg", "number")
simDR_autopilot_servos_on           	= find_dataref("laminar/B747/autopilot/servos_on")
B747DR_ap_FMA_active_pitch_mode     	= find_dataref("laminar/B747/autopilot/FMA/active_pitch_mode")
B747DR_ap_FMA_active_roll_mode      	= find_dataref("laminar/B747/autopilot/FMA/active_roll_mode")
simDR_vvi_fpm_pilot                 = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
simDR_autopilot_alt_hold_status     	= find_dataref("laminar/B747/autopilot/altitude_hold_status")
--simCMD_autopilot_alt_hold_mode      = find_command("sim/autopilot/altitude_hold")
B747_controls_left_outer_aileron           = deferred_dataref("laminar/B747/cablecontrols/left_outer_aileron", "number")
B747_controls_right_outer_aileron            = deferred_dataref("laminar/B747/cablecontrols/right_outer_aileron", "number")
B747_controls_left_inner_aileron           = deferred_dataref("laminar/B747/cablecontrols/left_inner_aileron", "number")
B747_controls_right_inner_aileron          = deferred_dataref("laminar/B747/cablecontrols/right_inner_aileron", "number")


simDR_left_aileron_inner = find_dataref("sim/flightmodel/controls/wing2l_ail1def")
simDR_right_aileron_inner = find_dataref("sim/flightmodel/controls/wing2r_ail1def")
simDR_left_aileron_outer = find_dataref("sim/flightmodel/controls/wing4l_ail2def")
simDR_right_aileron_outer = find_dataref("sim/flightmodel/controls/wing4r_ail2def")
B747DR_l_aileron_inner   = deferred_dataref("laminar/B747/flt_ctrls/l_aileron_inner", "number")
B747DR_r_aileron_inner   = deferred_dataref("laminar/B747/flt_ctrls/r_aileron_inner", "number")
B747DR_l_aileron_outer   = deferred_dataref("laminar/B747/flt_ctrls/l_aileron_outer", "number")
B747DR_r_aileron_outer   = deferred_dataref("laminar/B747/flt_ctrls/r_aileron_outer", "number")

B747DR_l_aileron_outer_lockout   = deferred_dataref("laminar/B747/flt_ctrls/left_outer_aileron_lockout", "number")
B747DR_r_aileron_outer_lockout   = deferred_dataref("laminar/B747/flt_ctrls/right_outer_aileron_lockout", "number")

B747DR_spoilers      = deferred_dataref("laminar/B747/flt_ctrls/spoilers", "array[13]") --0 unused
B747DR_outer_spoilers      = deferred_dataref("laminar/B747/flt_ctrls/outer_spoilers", "array[2]") --for stat display
B747DR_flaps      = deferred_dataref("laminar/B747/flt_ctrls/flaps", "array[5]") --0 unuse

B747DR_spoiler1 = deferred_dataref("laminar/B747/cablecontrols/spoiler1", "number")
B747DR_spoiler2 = deferred_dataref("laminar/B747/cablecontrols/spoiler2", "number")
B747DR_spoiler3 = deferred_dataref("laminar/B747/cablecontrols/spoiler3", "number")
B747DR_spoiler4 = deferred_dataref("laminar/B747/cablecontrols/spoiler4", "number")
B747DR_spoiler5 = deferred_dataref("laminar/B747/cablecontrols/spoiler5", "number")

B747DR_spoiler6 = deferred_dataref("laminar/B747/cablecontrols/spoiler6", "number")
B747DR_spoiler7 = deferred_dataref("laminar/B747/cablecontrols/spoiler7", "number")

B747DR_spoiler8 = deferred_dataref("laminar/B747/cablecontrols/spoiler8", "number")
B747DR_spoiler9 = deferred_dataref("laminar/B747/cablecontrols/spoiler9", "number")
B747DR_spoiler10 = deferred_dataref("laminar/B747/cablecontrols/spoiler10", "number")
B747DR_spoiler11 = deferred_dataref("laminar/B747/cablecontrols/spoiler11", "number")
B747DR_spoiler12 = deferred_dataref("laminar/B747/cablecontrols/spoiler12", "number")

B747DR_speedbrake1 = deferred_dataref("laminar/B747/cablecontrols/speedbrake34", "number")
B747DR_speedbrake2 = deferred_dataref("laminar/B747/cablecontrols/speedbrake58", "number")
B747DR_speedbrake3 = deferred_dataref("laminar/B747/cablecontrols/speedbrake67", "number")
B747DR_speedbrake4 = deferred_dataref("laminar/B747/cablecontrols/speedbrake12", "number")

simDR_spoiler12  = find_dataref("sim/flightmodel/controls/wing3l_spo1def")
simDR_spoiler34  = find_dataref("sim/flightmodel/controls/wing3l_spo2def")
simDR_spoiler5  = find_dataref("sim/flightmodel/controls/wing1l_spo1def")
simDR_spoiler67  = find_dataref("sim/flightmodel2/wing/speedbrake1_deg") -- array [0] left, [1] right
simDR_spoiler8  = find_dataref("sim/flightmodel/controls/wing1r_spo1def")
simDR_spoiler910  = find_dataref("sim/flightmodel/controls/wing3r_spo2def")
simDR_spoiler1112  = find_dataref("sim/flightmodel/controls/wing3r_spo1def")

--simDR_flap1  = find_dataref("sim/flightmodel2/wing/flap1_deg")-- inner array [0] left, [1] right
--simDR_flap2  = find_dataref("sim/flightmodel2/wing/flap2_deg")-- outer array [0] left, [1] right

B747DR_flap1 = deferred_dataref("laminar/B747/cablecontrols/flap1", "number")
B747DR_flap2 = deferred_dataref("laminar/B747/cablecontrols/flap2", "number")
B747DR_flap3 = deferred_dataref("laminar/B747/cablecontrols/flap3", "number")
B747DR_flap4 = deferred_dataref("laminar/B747/cablecontrols/flap4", "number")
simDR_flap_ratio			= find_dataref("sim/cockpit2/controls/flap_ratio")
simDR_innerslats_ratio  	= find_dataref("sim/flightmodel2/controls/slat1_deploy_ratio")
simDR_outerslats_ratio  	= find_dataref("sim/flightmodel2/controls/slat2_deploy_ratio")

simDR_flap1  = find_dataref("sim/flightmodel/controls/wing3l_fla2def")
simDR_flap2  = find_dataref("sim/flightmodel/controls/wing1l_fla1def")
simDR_flap3  = find_dataref("sim/flightmodel/controls/wing1r_fla1def")
simDR_flap4  = find_dataref("sim/flightmodel/controls/wing3r_fla2def")

simDR_version=find_dataref("sim/version/xplane_internal_version")
simDR_failhyd1  = find_dataref("sim/operation/failures/rel_hydleak")
simDR_failhyd2  = find_dataref("sim/operation/failures/rel_hydleak2")
simDR_failhyd3  = find_dataref("sim/operation/failures/rel_hydleak3")



simDR_override_control_surfaces       = find_dataref("sim/operation/override/override_control_surfaces")
simDR_override_steering               = find_dataref("sim/operation/override/override_wheel_steer")
--simDR_hyd_press_2               = find_dataref("sim/cockpit2/hydraulics/indicators/hydraulic_pressure_2")
B747DR_hyd_dmd_pmp_sel_pos      = deferred_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos", "array[4]")

function B747_animate_value(current_value, target, min, max, speed)

    

    if target >= (max - 0.001) then
        return max
    elseif target <= (min + 0.001) then
       return min
    else
      local fps_factor = math.min(0.1, speed * SIM_PERIOD)
        return current_value + ((target - current_value) * fps_factor)
    end

end

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
  if newValue <= min then
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
----- RESCALE ---------------------------------------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

  if x < in1 then return out1 end
  if x > in2 then return out2 end
  return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end
B747DR_switching_servos_on = deferred_dataref("laminar/B747/autopilot/ap_monitor/servos_on_time", "number")
dofile("B747.19.xt.hydraulics_override.lua")
function B747_engine_hyd_valves()
-- ENGINE #1
    if B747DR_button_switch_position[30] > 0.95 then
        B747DR_hyd_valve_1 = 1
    elseif B747DR_button_switch_position[30] < 0.05 then
        B747DR_hyd_valve_1  = 0
    end


    -- ENGINE #2
    if B747DR_button_switch_position[31] > 0.95 then
        B747DR_hyd_valve_2  = 1
    elseif B747DR_button_switch_position[31] < 0.05 then
        B747DR_hyd_valve_2  = 0
    end


    -- ENGINE #3
    if B747DR_button_switch_position[32] > 0.95 then
        B747DR_hyd_valve_3  = 1
    elseif B747DR_button_switch_position[32] < 0.05 then
        B747DR_hyd_valve_3  = 0
    end


    -- ENGINE #4
    if B747DR_button_switch_position[33] > 0.95 then
        B747DR_hyd_valve_4  = 1
    elseif B747DR_button_switch_position[33] < 0.05 then
        B747DR_hyd_valve_4  = 0
    end
end
function B747_engine_dem_modes()
  
  B747DR_hyd_dem_mode_1=B747DR_hyd_dmd_pmp_sel_pos[0]
  B747DR_hyd_dem_mode_2=B747DR_hyd_dmd_pmp_sel_pos[1]
  B747DR_hyd_dem_mode_3=B747DR_hyd_dmd_pmp_sel_pos[2]
  B747DR_hyd_dem_mode_4=B747DR_hyd_dmd_pmp_sel_pos[3]
  
end
function B747_edp_pressures()
    if B747DR_hyd_valve_1==1 then
      B747DR_hyd_edp_pressure_1=40*B747DR_display_N1[0]
    else
      B747DR_hyd_edp_pressure_1=0;
    end
    
    if B747DR_hyd_valve_2==1 then
      B747DR_hyd_edp_pressure_2=40*B747DR_display_N1[1]
    else
      B747DR_hyd_edp_pressure_2=0;
    end
    
    if B747DR_hyd_valve_3==1 then
      B747DR_hyd_edp_pressure_3=40*B747DR_display_N1[2]
    else
      B747DR_hyd_edp_pressure_3=0;
    end
    
    if B747DR_hyd_valve_4==1 then
      B747DR_hyd_edp_pressure_4=40*B747DR_display_N1[3]
    else
      B747DR_hyd_edp_pressure_4=0;
    end
end

function B747_dem_pressures()
  if B747DR_hyd_dem_mode_1>0 then 
    if B747DR_hyd_dem_mode_1==2 then
      B747DR_hyd_dem_pressure_1=B747_duct_pressure_L*110
    elseif B747DR_hyd_edp_pressure_1<2500 then
      B747DR_hyd_dem_pressure_1=B747_duct_pressure_L*110
    else
      B747DR_hyd_dem_pressure_1=0
    end
  else
     B747DR_hyd_dem_pressure_1=0  
  end
  
  
  if B747DR_hyd_dem_mode_2>0 then
    if B747DR_hyd_dem_mode_2==2 then
      B747DR_hyd_dem_pressure_2=3000
    elseif B747DR_hyd_edp_pressure_2<2500 then
      B747DR_hyd_dem_pressure_2=3000
    else
      B747DR_hyd_dem_pressure_2=0
    end
   else
     B747DR_hyd_dem_pressure_2=0 
  end
 
  if B747DR_hyd_dem_mode_3>0 then
    if B747DR_hyd_dem_mode_3==2 then
      B747DR_hyd_dem_pressure_3=3000
    elseif B747DR_hyd_edp_pressure_3<2500 then
      B747DR_hyd_dem_pressure_3=3000
    else
      B747DR_hyd_dem_pressure_3=0
    end
   else
     B747DR_hyd_dem_pressure_3=0
  end
  
  if B747DR_hyd_dem_mode_4>0 then
    if B747DR_hyd_dem_mode_4==2 then
      B747DR_hyd_dem_pressure_4=B747_duct_pressure_R*110
    elseif B747DR_hyd_edp_pressure_4<2500 then
      B747DR_hyd_dem_pressure_4=B747_duct_pressure_R*110
    else
      B747DR_hyd_dem_pressure_4=0
    end
    elseif B747DR_hyd_dem_mode_4<0 then
     B747DR_hyd_aux_pressure=2950
     B747DR_hyd_dem_pressure_4=0
    else
     B747DR_hyd_dem_pressure_4=0
     B747DR_hyd_aux_pressure=0
  end
  
end
local lastpressureUpdate=0
function B747_show_system_pressures()
  local diff = simDRTime - lastpressureUpdate
	if diff < 0.5 then
		return
	end
  B747DR_hyd_sys_pressure_dsp_1=math.floor(B747DR_hyd_sys_pressure_1/10)*10
  B747DR_hyd_sys_pressure_dsp_2=math.floor(B747DR_hyd_sys_pressure_2/10)*10
  B747DR_hyd_sys_pressure_dsp_3=math.floor(B747DR_hyd_sys_pressure_3/10)*10
  B747DR_hyd_sys_pressure_dsp_4=math.floor(B747DR_hyd_sys_pressure_4/10)*10

  lastpressureUpdate=simDRTime
end
function B747_system_pressures()
  --B747_animate_value(B747DR_hyd_sys_pressure_1,math.max(B747DR_hyd_dem_pressure_1,B747DR_hyd_edp_pressure_1),0,3000,1)
  B747DR_hyd_sys_pressure_use_1=B747_animate_value(B747DR_hyd_sys_pressure_use_1,((B747DR_hyd_dem_pressure_1+B747DR_hyd_edp_pressure_1)/10),0,45,1)--math.max(B747DR_hyd_dem_pressure_1,B747DR_hyd_edp_pressure_1)
  B747DR_hyd_sys_pressure_use_2=B747_animate_value(B747DR_hyd_sys_pressure_use_2,((B747DR_hyd_dem_pressure_2+B747DR_hyd_edp_pressure_2)/10),0,45,1)--math.max(B747DR_hyd_dem_pressure_2,B747DR_hyd_edp_pressure_2)
  B747DR_hyd_sys_pressure_use_3=B747_animate_value(B747DR_hyd_sys_pressure_use_3,((B747DR_hyd_dem_pressure_3+B747DR_hyd_edp_pressure_3)/10),0,45,1)--math.max(B747DR_hyd_dem_pressure_3,B747DR_hyd_edp_pressure_3)
  B747DR_hyd_sys_pressure_use_4=B747_animate_value(B747DR_hyd_sys_pressure_use_4,((B747DR_hyd_dem_pressure_4+B747DR_hyd_edp_pressure_4+B747DR_hyd_aux_pressure)/10),0,45,1)--math.max(B747DR_hyd_dem_pressure_4,B747DR_hyd_edp_pressure_4,B747DR_hyd_aux_pressure)
  
  --sys_pressure_use now contains how much pressure we can put into the system
  local s1Max=math.min(math.max(B747DR_hyd_dem_pressure_1,B747DR_hyd_edp_pressure_1,B747DR_hyd_sys_pressure_1),3300)
  local s2Max=math.min(math.max(B747DR_hyd_dem_pressure_2,B747DR_hyd_edp_pressure_2,B747DR_hyd_sys_pressure_2),3300)
  local s3Max=math.min(math.max(B747DR_hyd_dem_pressure_3,B747DR_hyd_edp_pressure_3,B747DR_hyd_sys_pressure_3),3300)
  local s4Max=math.min(math.max(B747DR_hyd_dem_pressure_4,B747DR_hyd_edp_pressure_4,B747DR_hyd_aux_pressure,B747DR_hyd_sys_pressure_4),3300)
  B747DR_hyd_sys_pressure_1=B747_animate_value(B747DR_hyd_sys_pressure_1,B747DR_hyd_sys_pressure_1+B747DR_hyd_sys_pressure_use_1,0,s1Max-math.random()*50,10)
  B747DR_hyd_sys_pressure_2=B747_animate_value(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_2+B747DR_hyd_sys_pressure_use_2,0,s2Max-math.random()*50,10)
  B747DR_hyd_sys_pressure_3=B747_animate_value(B747DR_hyd_sys_pressure_3,B747DR_hyd_sys_pressure_3+B747DR_hyd_sys_pressure_use_3,0,s3Max-math.random()*50,10)
  B747DR_hyd_sys_pressure_4=B747_animate_value(B747DR_hyd_sys_pressure_4,B747DR_hyd_sys_pressure_4+B747DR_hyd_sys_pressure_use_4,0,s4Max-math.random()*50,10)
  B747DR_hyd_sys_pressure_13=math.max(B747DR_hyd_sys_pressure_1,B747DR_hyd_sys_pressure_3) --12 remapped to 13
  B747DR_hyd_sys_pressure_23=math.max(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_3)
  B747DR_hyd_sys_pressure_24=math.max(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_4) 
  B747DR_hyd_sys_pressure_234=math.max(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_3,B747DR_hyd_sys_pressure_4)
  
  B747DR_hyd_sys_res_1=B747DR_hyd_sys_restotal_1-(B747DR_hyd_sys_pressure_1/3000)*0.1
  B747DR_hyd_sys_res_2=B747DR_hyd_sys_restotal_2-(B747DR_hyd_sys_pressure_2/3000)*0.1
  B747DR_hyd_sys_res_3=B747DR_hyd_sys_restotal_3-(B747DR_hyd_sys_pressure_3/3000)*0.1
  B747DR_hyd_sys_res_4=B747DR_hyd_sys_restotal_4-(B747DR_hyd_sys_pressure_4/3000)*0.1
  simDR_hyd_press_1_2 = math.max(simDR_hyd_press_1_2,B747DR_hyd_sys_pressure_1,B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_4)

  B747DR_hyd_sys_temp_1=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_1)*20
  B747DR_hyd_sys_temp_2=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_2)*20
  B747DR_hyd_sys_temp_3=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_3)*20
  B747DR_hyd_sys_temp_4=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_4)*20
end
--*************************************************************************************--
--**                          EVENT CALLBACKS                        **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end
function B747_set_hyd_model_ER()
  B747DR_hyd_sys_pressure_use_1=3100
  B747DR_hyd_sys_pressure_use_2=3100
  B747DR_hyd_sys_pressure_use_3=3100
  B747DR_hyd_sys_pressure_use_4=3100
  B747DR_hyd_sys_pressure_1=3100
  B747DR_hyd_sys_pressure_2=3100
  B747DR_hyd_sys_pressure_3=3100
  B747DR_hyd_sys_pressure_4=3100
end  

local initialiseControls=true
function flight_start() 
  --initial pids
  --lockedout
  --p 0.1
  --i 0.003
  --d 0.04

  B747DR_pidRollP = 0.05
  B747DR_pidRollI = 0.0003
  B747DR_pidRollDL = 0.05 --low 0.1 high 0.4
  B747DR_pidRollDH = 0.1 --low 0.1 high 0.4

  B747DR_pidPitchPL = 0.07 --low 0.15 high 0.05
  B747DR_pidPitchPH = 0.04 --low 0.15 high 0.05
  B747DR_pidPitchI = 0.07 --0.07
  B747DR_pidPitchD = 0.0002


  B747DR_pidyawP = 1.0
  B747DR_pidyawI = 0.00003
  B747DR_pidyawD = 3.0

  B747DR_pidyawDslipH = 0.1
  B747DR_pidyawDslipL = 0.1
  B747DR_pidyawPslipH = 0.02
  B747DR_pidyawPslipL = 0.02

  B747DR_pidyawDrollH = 0.1
  B747DR_pidyawDrollL = 0.1
  B747DR_pidyawProllH = 0.1
  B747DR_pidyawProllL = 0.1
    --rudder
    B747DR_rudder_ratio=1.0
    B747DR_elevator_ratio   = 1.0
    if initialiseControls then
      --YAW DAMPER
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-3.5,"maxout":3.5,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/yaw_damper_lwr","dstDref":"laminar/B747/cablecontrols/lower_rudder","scaledref":"laminar/B747/flt_ctrls/rudder_ratio"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-3.5,"maxout":3.5,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/yaw_damper_upr","dstDref":"laminar/B747/cablecontrols/upper_rudder","scaledref":"laminar/B747/flt_ctrls/rudder_ratio"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-32,"maxout":32,"scale":1.0,"srcDref":"sim/cockpit2/controls/total_heading_ratio","dstDref":"laminar/B747/cablecontrols/lower_rudder","scaledref":"laminar/B747/flt_ctrls/rudder_ratio"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-32,"maxout":32,"scale":1.0,"srcDref":"sim/cockpit2/controls/total_heading_ratio","dstDref":"laminar/B747/cablecontrols/upper_rudder","scaledref":"laminar/B747/flt_ctrls/rudder_ratio"}';

      B747DR_controlOverrides = '{"minin":-32,"maxin":32,"minout":-32,"maxout":32,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/rudder_lwr_pos","dstDref":"sim/flightmodel/controls/vstab2_rud1def"}';
      B747DR_controlOverrides = '{"minin":-32,"maxin":32,"minout":-32,"maxout":32,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/rudder_upr_pos","dstDref":"sim/flightmodel/controls/vstab2_rud2def"}';
    
      --elevators

      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-1,"maxout":1,"scale":1.0,"srcDref":"sim/cockpit2/controls/yoke_pitch_ratio","dstDref":"laminar/B747/flt_ctrls/custom_pitch_ratio"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-1,"maxout":1,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/sim_pitch_ratio","dstDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","scaledref":"laminar/B747/flt_ctrls/elevator_ratio"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-17,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/left_outer_elevator"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":22,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/left_outer_elevator"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-17,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/right_outer_elevator"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":22,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/right_outer_elevator"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-17,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/left_inner_elevator"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":22,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/left_inner_elevator"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-17,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/right_inner_elevator"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":22,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_pitch_ratio","dstDref":"laminar/B747/cablecontrols/right_inner_elevator"}';

      B747DR_controlOverrides = '{"minin":-22,"maxin":17,"minout":-22,"maxout":17,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/l_elev_outer","dstDref":"sim/flightmodel/controls/hstab1_elv1def"}'; --left_outer_elevator
      B747DR_controlOverrides = '{"minin":-22,"maxin":17,"minout":-22,"maxout":17,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/r_elev_outer","dstDref":"sim/flightmodel/controls/hstab2_elv1def"}'; --right_outer_elevator
      B747DR_controlOverrides = '{"minin":-22,"maxin":17,"minout":-22,"maxout":17,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/l_elev_inner","dstDref":"sim/flightmodel/controls/hstab1_elv2def"}'; --left_inner_elevator
      B747DR_controlOverrides = '{"minin":-22,"maxin":17,"minout":-22,"maxout":17,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/r_elev_inner","dstDref":"sim/flightmodel/controls/hstab2_elv2def"}'; --right_inner_elevator
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-15,"maxout":15,"scale":-1.0,"srcDref":"sim/flightmodel2/controls/elevator_trim","dstDref":"sim/flightmodel2/controls/stabilizer_deflection_degrees"}'; --trim
      
      
      --ailerons
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-1,"maxout":1,"scale":1.0,"srcDref":"sim/cockpit2/controls/yoke_roll_ratio","dstDref":"laminar/B747/flt_ctrls/custom_roll_ratio"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-1,"maxout":1,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/sim_roll_ratio","dstDref":"laminar/B747/flt_ctrls/custom_roll_ratio"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-1,"maxout":1,"scale":1.0,"srcDref":"sim/cockpit2/controls/aileron_trim","dstDref":"laminar/B747/flt_ctrls/custom_roll_ratio"}';
      
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-20,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/left_inner_aileron"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":1,"minout":-20,"maxout":20,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/right_inner_aileron"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-25,"maxout":0,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/left_outer_aileron","scaledref":"laminar/B747/flt_ctrls/left_outer_aileron_lockout"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":15,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/left_outer_aileron","scaledref":"laminar/B747/flt_ctrls/left_outer_aileron_lockout"}';

      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-15,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/right_outer_aileron","scaledref":"laminar/B747/flt_ctrls/right_outer_aileron_lockout"}';  
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":25,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/right_outer_aileron","scaledref":"laminar/B747/flt_ctrls/right_outer_aileron_lockout"}'; 
      
      B747DR_controlOverrides = '{"minin":-20,"maxin":20,"minout":-20,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/l_aileron_inner","dstDref":"sim/flightmodel/controls/wing2l_ail1def"}';
      B747DR_controlOverrides = '{"minin":-20,"maxin":20,"minout":-20,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/r_aileron_inner","dstDref":"sim/flightmodel/controls/wing2r_ail1def"}';
      B747DR_controlOverrides = '{"minin":-25,"maxin":15,"minout":-25,"maxout":15,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/l_aileron_outer","dstDref":"sim/flightmodel/controls/wing4l_ail2def"}';
      B747DR_controlOverrides = '{"minin":-25,"maxin":15,"minout":-25,"maxout":15,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/r_aileron_outer","dstDref":"sim/flightmodel/controls/wing4r_ail2def"}';  
      
      --spoilers
      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-45,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler1"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-45,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler2"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-45,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler3"}';
      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-45,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler4"}';  
      B747DR_controlOverrides = '{"minin":-1,"maxin":0,"minout":-20,"maxout":0,"scale":-1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler5"}';
    
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler8"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler9"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler10"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler11"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":1,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/custom_roll_ratio","dstDref":"laminar/B747/cablecontrols/spoiler12"}';  
      
    
      --flaps
      B747DR_controlOverrides = '{"minin":0.167,"maxin":0.5,"minout":0,"maxout":10,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap1"}';
      B747DR_controlOverrides = '{"minin":0.167,"maxin":0.5,"minout":0,"maxout":10,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap2"}';
      B747DR_controlOverrides = '{"minin":0.167,"maxin":0.5,"minout":0,"maxout":10,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap3"}';
      B747DR_controlOverrides = '{"minin":0.167,"maxin":0.5,"minout":0,"maxout":10,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap4"}';  

      B747DR_controlOverrides = '{"minin":0.5,"maxin":0.667,"minout":0,"maxout":10,"max":20,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap1"}';
      B747DR_controlOverrides = '{"minin":0.5,"maxin":0.667,"minout":0,"maxout":10,"max":20,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap2"}';
      B747DR_controlOverrides = '{"minin":0.5,"maxin":0.667,"minout":0,"maxout":10,"max":20,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap3"}';
      B747DR_controlOverrides = '{"minin":0.5,"maxin":0.667,"minout":0,"maxout":10,"max":20,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap4"}';  

      B747DR_controlOverrides = '{"minin":0.667,"maxin":0.8333,"minout":0,"maxout":20,"scale":0.1,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap1"}';
      B747DR_controlOverrides = '{"minin":0.667,"maxin":0.8333,"minout":0,"maxout":20,"scale":0.1,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap2"}';
      B747DR_controlOverrides = '{"minin":0.667,"maxin":0.8333,"minout":0,"maxout":20,"scale":0.1,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap3"}';
      B747DR_controlOverrides = '{"minin":0.667,"maxin":0.8333,"minout":0,"maxout":20,"scale":0.1,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap4"}';
      
      B747DR_controlOverrides = '{"minin":0.833,"maxin":1,"minout":0,"maxout":20,"scale":0.4,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap1"}';
      B747DR_controlOverrides = '{"minin":0.833,"maxin":1,"minout":0,"maxout":20,"scale":0.4,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap2"}';
      B747DR_controlOverrides = '{"minin":0.833,"maxin":1,"minout":0,"maxout":20,"scale":0.4,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap3"}';
      B747DR_controlOverrides = '{"minin":0.833,"maxin":1,"minout":0,"maxout":20,"scale":0.4,"max":30,"srcDref":"laminar/B747/cablecontrols/flap_ratio","dstDref":"laminar/B747/cablecontrols/flap4"}';
        
      --flap display
      --flap 1 
      B747DR_controlOverrides = '{"minin":0,"maxin":0.167,"minout":0,"maxout":0.15,"scale":1.0,"srcDref":"sim/cockpit2/controls/flap_ratio","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio1"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":10,"minout":0,"maxout":0.35,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3l_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio1"}';
      B747DR_controlOverrides = '{"minin":10,"maxin":20,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3l_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio1"}';
      B747DR_controlOverrides = '{"minin":20,"maxin":22,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3l_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio1"}';
      B747DR_controlOverrides = '{"minin":22,"maxin":30,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3l_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio1"}';
      
      --flap 2 
      B747DR_controlOverrides = '{"minin":0,"maxin":0.167,"minout":0,"maxout":0.15,"scale":1.0,"srcDref":"sim/cockpit2/controls/flap_ratio","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio2"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":10,"minout":0,"maxout":0.35,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1l_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio2"}';
      B747DR_controlOverrides = '{"minin":10,"maxin":20,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1l_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio2"}';
      B747DR_controlOverrides = '{"minin":20,"maxin":22,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1l_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio2"}';
      B747DR_controlOverrides = '{"minin":22,"maxin":30,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1l_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio2"}';
      --flap 3 
      B747DR_controlOverrides = '{"minin":0,"maxin":0.167,"minout":0,"maxout":0.15,"scale":1.0,"srcDref":"sim/cockpit2/controls/flap_ratio","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio3"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":10,"minout":0,"maxout":0.35,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1r_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio3"}';
      B747DR_controlOverrides = '{"minin":10,"maxin":20,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1r_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio3"}';
      B747DR_controlOverrides = '{"minin":20,"maxin":22,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1r_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio3"}';
      B747DR_controlOverrides = '{"minin":22,"maxin":30,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing1r_fla1def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio3"}';

      --flap 4 
      B747DR_controlOverrides = '{"minin":0,"maxin":0.167,"minout":0,"maxout":0.15,"scale":1.0,"srcDref":"sim/cockpit2/controls/flap_ratio","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio4"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":10,"minout":0,"maxout":0.35,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3r_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio4"}';
      B747DR_controlOverrides = '{"minin":10,"maxin":20,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3r_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio4"}';
      B747DR_controlOverrides = '{"minin":20,"maxin":22,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3r_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio4"}';
      B747DR_controlOverrides = '{"minin":22,"maxin":30,"minout":0,"maxout":0.167,"scale":1.0,"max":1,"srcDref":"sim/flightmodel/controls/wing3r_fla2def","dstDref":"laminar/B747/gauges/indicators/flap_deployed_ratio4"}';

      --speedbrakes
      B747DR_controlOverrides = '{"minin":0.125,"maxin":0.53,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/speedbrake_lever","dstDref":"laminar/B747/cablecontrols/speedbrake34"}';
      B747DR_controlOverrides = '{"minin":0.125,"maxin":0.53,"minout":0,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/speedbrake_lever","dstDref":"laminar/B747/cablecontrols/speedbrake58"}';
      B747DR_controlOverrides = '{"minin":0.40,"maxin":0.41,"minout":0,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/speedbrake_lever","dstDref":"laminar/B747/cablecontrols/speedbrake67"}';
      B747DR_controlOverrides = '{"minin":0.65,"maxin":0.66,"minout":0,"maxout":50,"scale":0.5,"srcDref":"laminar/B747/flt_ctrls/speedbrake_lever","dstDref":"laminar/B747/cablecontrols/speedbrake67"}';
      B747DR_controlOverrides = '{"minin":0.6,"maxin":0.90,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/flt_ctrls/speedbrake_lever","dstDref":"laminar/B747/cablecontrols/speedbrake12"}';
      
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake12","dstDref":"laminar/B747/cablecontrols/spoiler1"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake12","dstDref":"laminar/B747/cablecontrols/spoiler2"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake34","dstDref":"laminar/B747/cablecontrols/spoiler3"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake34","dstDref":"laminar/B747/cablecontrols/spoiler4"}';  
      B747DR_controlOverrides = '{"minin":0,"maxin":20,"minout":0,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake58","dstDref":"laminar/B747/cablecontrols/spoiler5"}';
    
      B747DR_controlOverrides = '{"minin":0,"maxin":20,"minout":0,"maxout":20,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake58","dstDref":"laminar/B747/cablecontrols/spoiler8"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake34","dstDref":"laminar/B747/cablecontrols/spoiler9"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake34","dstDref":"laminar/B747/cablecontrols/spoiler10"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake12","dstDref":"laminar/B747/cablecontrols/spoiler11"}';
      B747DR_controlOverrides = '{"minin":0,"maxin":45,"minout":0,"maxout":45,"scale":1.0,"srcDref":"laminar/B747/cablecontrols/speedbrake12","dstDref":"laminar/B747/cablecontrols/spoiler12"}';  

      B747DR_controlOverrides = '{"minin":20,"maxin":45,"minout":0,"maxout":50,"scale":0.5,"srcDref":"laminar/B747/cablecontrols/speedbrake67","dstDref":"laminar/B747/cablecontrols/spoiler5"}';
      B747DR_controlOverrides = '{"minin":20,"maxin":45,"minout":0,"maxout":50,"scale":0.5,"srcDref":"laminar/B747/cablecontrols/speedbrake67","dstDref":"laminar/B747/cablecontrols/spoiler8"}';
      initialiseControls=false
    else 
      print("not reinitialising controls!!!")
    end
    B747DR_hyd_sys_restotal_1=math.random()*0.2+0.8
    B747DR_hyd_sys_restotal_2=math.random()*0.2+0.8
    B747DR_hyd_sys_restotal_3=math.random()*0.2+0.8
    B747DR_hyd_sys_restotal_4=math.random()*0.2+0.8
    B747DR_hyd_sys_res_1=B747DR_hyd_sys_restotal_1
    B747DR_hyd_sys_res_2=B747DR_hyd_sys_restotal_2
    B747DR_hyd_sys_res_3=B747DR_hyd_sys_restotal_3
    B747DR_hyd_sys_res_4=B747DR_hyd_sys_restotal_4

    B747DR_hyd_sys_temp_1=B747DR_hyd_temp
    B747DR_hyd_sys_temp_2=B747DR_hyd_temp
    B747DR_hyd_sys_temp_3=B747DR_hyd_temp
    B747DR_hyd_sys_temp_4=B747DR_hyd_temp
    if simDR_startup_running == 1 then

		B747_set_hyd_model_ER() -- pressurise the system if engines start running

    end
end

--function flight_crash() end

--function before_physics() end
debug_hydro     = deferred_dataref("laminar/B747/debug/hydro", "number")

local lastStat=0
local countFrame=0
local hyd_failures={0,0,0,0}
local hydfailed1=false
local hydfailed2=false
local hydfailed3=false
local hasHydFailure=false
function roundToIncrement(number, increment)

  local y = number / increment
  local q = math.floor(y + 0.5)
  local z = q * increment

  return z

end
function hydraulic_failures()
  if simDR_failhyd1 ==0 and simDR_failhyd2 == 0 and simDR_failhyd3 ==0 then
    if hasHydFailure then
      hyd_failures={0,0,0,0}
      hydfailed1=false
      hydfailed2=false
      hydfailed3=false
      B747DR_hyd_sys_restotal_1=math.random()*0.2+0.8
      B747DR_hyd_sys_restotal_2=math.random()*0.2+0.8
      B747DR_hyd_sys_restotal_3=math.random()*0.2+0.8
      B747DR_hyd_sys_restotal_4=math.random()*0.2+0.8
      hasHydFailure=false
    end
    return
  end
  hasHydFailure=true
  if simDR_failhyd1 == 6 and not(hydfailed1) then
    local failIndex=1+roundToIncrement(math.random(),1)

    hyd_failures[failIndex] = 15+math.random()*15
    hydfailed1=true
  end
  if simDR_failhyd2 == 6 and not(hydfailed2) then
    local failIndex=2+roundToIncrement(math.random(),1)

    hyd_failures[failIndex] = 15+math.random()*15
    hydfailed2=true
  end
  if simDR_failhyd3 == 6 and not(hydfailed3) then
    local failIndex=3+roundToIncrement(math.random(),1)
    hyd_failures[failIndex] = 15+math.random()*15
    hydfailed2=true
  end
  if hyd_failures[1] >0 then
    B747DR_hyd_sys_restotal_1=B747_interpolate_value(B747DR_hyd_sys_restotal_1,0,0,1,hyd_failures[1])
  end
  if hyd_failures[2] >0 then
    B747DR_hyd_sys_restotal_2=B747_interpolate_value(B747DR_hyd_sys_restotal_2,0,0,1,hyd_failures[2])
  end
  if hyd_failures[3] >0 then
    B747DR_hyd_sys_restotal_3=B747_interpolate_value(B747DR_hyd_sys_restotal_3,0,0,1,hyd_failures[3])
  end
  if hyd_failures[4] >0 then
    B747DR_hyd_sys_restotal_4=B747_interpolate_value(B747DR_hyd_sys_restotal_4,0,0,1,hyd_failures[4])
  end
  --print("hyd failure "..hyd_failures[1].." "..hyd_failures[2].." "..hyd_failures[3].." "..hyd_failures[4])

end
function after_physics()
  if debug_hydro>0 then return end
  

   B747_engine_hyd_valves()
   B747_engine_dem_modes()
   B747_edp_pressures()
   B747_dem_pressures()
   B747_system_pressures()
   B747_show_system_pressures()
   --consumers
   pressure_input()
   brake_accumulator()
   flight_controls_consumption()
   pressure_output()
   flight_controls_override()
   if simDR_version>=120012 then
    hydraulic_failures()
   end
   if debug_hydro<0 then
    local diff=simDRTime-lastStat
    countFrame=countFrame+1
    if diff>=1 then
      print("Hydro fps="..countFrame)
      lastStat=simDRTime
      countFrame=0
    end
  end
end

--function after_replay() end