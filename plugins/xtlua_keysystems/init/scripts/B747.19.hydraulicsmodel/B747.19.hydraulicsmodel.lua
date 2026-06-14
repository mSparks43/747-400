--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks
*****************************************************************************************
hydraulicsmodel.lua
27/04/2020
]]

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

B747DR_flight_director_pitch           = deferred_dataref("laminar/B747/autopilot/flight_director_pitch_deg", "number")
B747DR_flight_director_roll 		= deferred_dataref("laminar/B747/autopilot/flight_director_roll_deg", "number")
B747_controls_lower_rudder           = deferred_dataref("laminar/B747/cablecontrols/lower_rudder", "number")
B747_controls_upper_rudder           = deferred_dataref("laminar/B747/cablecontrols/upper_rudder", "number")

B747_controls_left_outer_elevator           = deferred_dataref("laminar/B747/cablecontrols/left_outer_elevator", "number")
B747_controls_right_outer_elevator            = deferred_dataref("laminar/B747/cablecontrols/right_outer_elevator", "number")
B747_controls_left_inner_elevator           = deferred_dataref("laminar/B747/cablecontrols/left_inner_elevator", "number")
B747_controls_right_inner_elevator          = deferred_dataref("laminar/B747/cablecontrols/right_inner_elevator", "number")

B747_controls_left_outer_aileron           = deferred_dataref("laminar/B747/cablecontrols/left_outer_aileron", "number")
B747_controls_right_outer_aileron            = deferred_dataref("laminar/B747/cablecontrols/right_outer_aileron", "number")
B747_controls_left_inner_aileron           = deferred_dataref("laminar/B747/cablecontrols/left_inner_aileron", "number")
B747_controls_right_inner_aileron          = deferred_dataref("laminar/B747/cablecontrols/right_inner_aileron", "number")

B747_duct_pressure_L           = deferred_dataref("laminar/B747/air/duct_pressure_L", "number")
B747_duct_pressure_R           = deferred_dataref("laminar/B747/air/duct_pressure_R", "number")

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

B747DR_hyd_sys_pressure_use_1  = deferred_dataref("laminar/B747/hydraulics/pressure_use_1", "number")
B747DR_hyd_sys_pressure_use_2  = deferred_dataref("laminar/B747/hydraulics/pressure_use_2", "number")
B747DR_hyd_sys_pressure_use_3  = deferred_dataref("laminar/B747/hydraulics/pressure_use_3", "number")
B747DR_hyd_sys_pressure_use_4  = deferred_dataref("laminar/B747/hydraulics/pressure_use_4", "number")

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



B747DR_hyd_dmd_pmp_sel_pos      = deferred_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos", "array[4]")
B747DR_rudder_ratio   = deferred_dataref("laminar/B747/flt_ctrls/rudder_ratio", "number")


B747DR_yaw_damper_lwr   = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_lwr", "number")
B747DR_yaw_damper_upr   = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_upr", "number")
B747DR_elevator_ratio   = deferred_dataref("laminar/B747/flt_ctrls/elevator_ratio", "number")
B747DR_rudder_lwr_pos   = deferred_dataref("laminar/B747/flt_ctrls/rudder_lwr_pos", "number")
B747DR_rudder_upr_pos   = deferred_dataref("laminar/B747/flt_ctrls/rudder_upr_pos", "number")
B747DR_l_elev_inner   = deferred_dataref("laminar/B747/flt_ctrls/l_elev_inner", "number")
B747DR_r_elev_inner   = deferred_dataref("laminar/B747/flt_ctrls/r_elev_inner", "number")
B747DR_l_elev_outer   = deferred_dataref("laminar/B747/flt_ctrls/l_elev_outer", "number")
B747DR_r_elev_outer   = deferred_dataref("laminar/B747/flt_ctrls/r_elev_outer", "number")

B747DR_sim_pitch_ratio   = deferred_dataref("laminar/B747/flt_ctrls/sim_pitch_ratio", "number")
B747DR_sim_roll_ratio   = deferred_dataref("laminar/B747/flt_ctrls/sim_roll_ratio", "number")
--B747DR_yaw_damp_ratio   = deferred_dataref("laminar/B747/flt_ctrls/sim_yaw_damp_ratio", "number")
B747DR_custom_pitch_ratio   = deferred_dataref("laminar/B747/flt_ctrls/custom_pitch_ratio", "number")
B747DR_custom_roll_ratio   = deferred_dataref("laminar/B747/flt_ctrls/custom_roll_ratio", "number")
B747DR_l_aileron_inner   = deferred_dataref("laminar/B747/flt_ctrls/l_aileron_inner", "number")
B747DR_r_aileron_inner   = deferred_dataref("laminar/B747/flt_ctrls/r_aileron_inner", "number")
B747DR_l_aileron_outer   = deferred_dataref("laminar/B747/flt_ctrls/l_aileron_outer", "number")
B747DR_r_aileron_outer   = deferred_dataref("laminar/B747/flt_ctrls/r_aileron_outer", "number")

B747DR_l_aileron_outer_lockout   = deferred_dataref("laminar/B747/flt_ctrls/left_outer_aileron_lockout", "number")
B747DR_r_aileron_outer_lockout   = deferred_dataref("laminar/B747/flt_ctrls/right_outer_aileron_lockout", "number")
B747DR_spoilers      = deferred_dataref("laminar/B747/flt_ctrls/spoilers", "array[13]") --0 unused

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

B747DR_flap_ratio = deferred_dataref("laminar/B747/cablecontrols/flap_ratio", "number")
B747DR_flap1 = deferred_dataref("laminar/B747/cablecontrols/flap1", "number")
B747DR_flap2 = deferred_dataref("laminar/B747/cablecontrols/flap2", "number")
B747DR_flap3 = deferred_dataref("laminar/B747/cablecontrols/flap3", "number")
B747DR_flap4 = deferred_dataref("laminar/B747/cablecontrols/flap4", "number")
B747DR_flap_deployed_ratio        = deferred_dataref("laminar/B747/gauges/indicators/flap_deployed_ratio", "number")
B747DR_flap_deployed_ratio1        = deferred_dataref("laminar/B747/gauges/indicators/flap_deployed_ratio1", "number")
B747DR_flap_deployed_ratio2        = deferred_dataref("laminar/B747/gauges/indicators/flap_deployed_ratio2", "number")
B747DR_flap_deployed_ratio3        = deferred_dataref("laminar/B747/gauges/indicators/flap_deployed_ratio3", "number")
B747DR_flap_deployed_ratio4        = deferred_dataref("laminar/B747/gauges/indicators/flap_deployed_ratio4", "number")
B747DR_yaw_damper_upr_on             = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_upr_on", "number")
B747DR_yaw_damper_lwr_on             = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_lwr_on", "number")
B747DR_outer_spoilers      = deferred_dataref("laminar/B747/flt_ctrls/outer_spoilers", "array[2]") --for stat display
B747DR_flaps      = deferred_dataref("laminar/B747/flt_ctrls/flaps", "array[5]") --0 unuse

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