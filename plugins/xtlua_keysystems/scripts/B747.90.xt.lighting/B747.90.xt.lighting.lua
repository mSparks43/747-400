--[[
*****************************************************************************************
* Program Script Name	:	B747.90.lighting
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
NUM_SPILL_LIGHT_INDICES = 9
NUM_LANDING_LIGHTS      = 4
NUM_ANNUN_LIGHTS        = 270


--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--





--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--
local annun = {}
annun.a = {}
annun.b = {}



--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--
simDR_version=find_dataref("sim/version/xplane_internal_version")
simDR_shadow			    = find_dataref("sim/private/controls/shadow/total_fade_ratio")
simDR_headX=find_dataref("sim/graphics/view/pilots_head_x")
simDR_headY=find_dataref("sim/graphics/view/pilots_head_y")
simDR_headZ=find_dataref("sim/graphics/view/pilots_head_z")
simDR_headpsi=find_dataref("sim/graphics/view/pilots_head_psi")
simDR_headpitch=find_dataref("sim/graphics/view/pilots_head_the")
simDR_photoBias			    = find_dataref("sim/private/controls/photometric/ev100_bias")
simDR_capt_visor_lr			    = find_dataref("laminar/B747/misc/sun_visor/left_right/capt") --left/right
simDR_capt_visor_ud			    = find_dataref("laminar/B747/toggle_switch/position[31]") --up/down
simDR_fo_visor_lr			    = find_dataref("laminar/B747/misc/sun_visor/left_right/fo") --left/right
simDR_fo_visor_ud			    = find_dataref("laminar/B747/toggle_switch/position[32]") --up/down
simDR_contrast			    = find_dataref("sim/private/controls/tonemap/contrast")
simDR_light_storage			    = find_dataref("sim/private/controls/photometric/light_storage_scale")
simDR_tone_mode			    = find_dataref("sim/private/controls/tonemap/mode")
simDR_exposure_fusion			    = find_dataref("sim/private/controls/tonemap/exposure_fusion")
simDR_ev100			    = find_dataref("sim/private/controls/photometric/ev100")
simDR_sun_pitch			    = find_dataref("sim/graphics/scenery/sun_pitch_degrees")
simDR_view_pitch			    = find_dataref("sim/graphics/view/view_pitch")
simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")
simDR_percent_lights_on             = find_dataref("sim/graphics/scenery/percent_lights_on")
simDR_ai_flies_aircraft				= find_dataref("sim/operation/prefs/ai_flies_aircraft")

simDR_electrical_bus_volts          = find_dataref("sim/cockpit2/electrical/bus_volts")

simDR_aircraft_on_ground            = find_dataref("sim/flightmodel/failures/onground_any")
simDR_all_wheels_on_ground          = find_dataref("sim/flightmodel/failures/onground_any")


simDR_sim_brightness_ratio      = find_dataref("sim/cockpit2/electrical/HUD_brightness_ratio")
simDR_generic_brightness_switch     = find_dataref("sim/cockpit2/switches/generic_lights_switch")
simDR_generic_brightness_ratio      = find_dataref("sim/flightmodel2/lights/generic_lights_brightness_ratio")
simDR_panel_brightness_switch       = find_dataref("sim/cockpit2/switches/panel_brightness_ratio")
simDR_panel_brightness_ratio        = find_dataref("sim/cockpit2/electrical/panel_brightness_ratio_manual")
simDR_instrument_brightness_switch  = find_dataref("sim/cockpit2/switches/instrument_brightness_ratio")
--simDR_instrument_brightness_ratio   = find_dataref("sim/cockpit2/electrical/instrument_brightness_ratio_manual")

B747DR_instrument_brightness_ratio  = find_dataref("laminar/B747/switches/instrument_brightness_ratio")
simDR_landing_light_switch          = find_dataref("sim/cockpit2/switches/landing_lights_switch")
simDR_taxi_light_switch_on          = find_dataref("sim/cockpit2/switches/taxi_light_on")
simDR_beacon_lights_switch          = find_dataref("sim/cockpit/electrical/beacon_lights_on")
simDR_nav_lights_switch             = find_dataref("sim/cockpit2/switches/navigation_lights_on")
simDR_strobe_lights_switch          = find_dataref("sim/cockpit2/switches/strobe_lights_on")

simDR_gpu_on                        = find_dataref("sim/cockpit/electrical/gpu_on")

simDR_apu_running                   = find_dataref("sim/cockpit2/electrical/APU_running")
simDR_apu_N1_pct                    = find_dataref("sim/cockpit2/electrical/APU_N1_percent")
simDR_apu_gen_on                    = find_dataref("sim/cockpit2/electrical/APU_generator_on")

simDR_cross_tie                     = find_dataref("sim/cockpit2/electrical/cross_tie")
simDR_engine_running                = find_dataref("sim/flightmodel/engine/ENGN_running")
simDR_aircraft_groundspeed          = find_dataref("sim/flightmodel/position/groundspeed")
simDR_generator_on                  = find_dataref("sim/cockpit2/electrical/generator_on")

simDR_hyd_press_01                  = find_dataref("laminar/B747/hydraulics/pressure_1")
simDR_hyd_press_02                  = find_dataref("laminar/B747/hydraulics/pressure_2")
simDR_hyd_press_03                  = find_dataref("laminar/B747/hydraulics/pressure_3")
simDR_hyd_press_04                  = find_dataref("laminar/B747/hydraulics/pressure_4")
simDR_hyd_fluid_level_01            = find_dataref("laminar/B747/hydraulics/res_1")
simDR_hyd_fluid_level_02            = find_dataref("laminar/B747/hydraulics/res_2")
simDR_hyd_fluid_level_03            = find_dataref("laminar/B747/hydraulics/res_3")
simDR_hyd_fluid_level_04            = find_dataref("laminar/B747/hydraulics/res_4")

--simDR_annun_master_caution          = find_dataref("sim/cockpit2/annunciators/master_caution")
--simDR_annun_master_warning          = find_dataref("sim/cockpit2/annunciators/master_warning")
simDR_annun_generator_off           = find_dataref("sim/cockpit2/annunciators/generator_off")
simDR_yaw_damper_annun              = find_dataref("sim/cockpit2/annunciators/yaw_damper")
B747DR_yaw_damper_upr_on             = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_upr_on", "number")
B747DR_yaw_damper_lwr_on             = deferred_dataref("laminar/B747/flt_ctrls/yaw_damper_lwr_on", "number")
--simDR_bleed_air_off                 = find_dataref("sim/cockpit2/annunciators/bleed_air_off")
--simDR_bleed_air_mode                = find_dataref("sim/cockpit2/pressurization/actuators/bleed_air_mode")
simDR_annun_GPWS                    = find_dataref("sim/cockpit2/annunciators/GPWS")

simDR_generator_fail_01             = find_dataref("sim/operation/failures/rel_genera0")
simDR_generator_fail_02             = find_dataref("sim/operation/failures/rel_genera1")
simDR_generator_fail_03             = find_dataref("sim/operation/failures/rel_genera2")
simDR_generator_fail_04             = find_dataref("sim/operation/failures/rel_genera3")
simDR_hyd_pump_fail_eng_01          = find_dataref("sim/operation/failures/rel_hydpmp")
simDR_hyd_pump_fail_eng_02          = find_dataref("sim/operation/failures/rel_hydpmp2")
simDR_hyd_pump_fail_eng_03          = find_dataref("sim/operation/failures/rel_hydpmp3")
simDR_hyd_pump_fail_eng_04          = find_dataref("sim/operation/failures/rel_hydpmp4")
--simDR_nacelle_inlet_antiice_fail_01 = find_dataref("sim/operation/failures/rel_ice_inlet_heat")
--simDR_nacelle_inlet_antiice_fail_02 = find_dataref("sim/operation/failures/rel_ice_inlet_heat2")
--simDR_nacelle_inlet_antiice_fail_03 = find_dataref("sim/operation/failures/rel_ice_inlet_heat3")
--simDR_nacelle_inlet_antiice_fail_04 = find_dataref("sim/operation/failures/rel_ice_inlet_heat4")
--simDR_wing_anti_ice_fail_01         = find_dataref("sim/operation/failures/rel_ice_surf_heat")
--simDR_wing_anti_ice_fail_02         = find_dataref("sim/operation/failures/rel_ice_surf_heat2")
simDR_window_heat_fail              = find_dataref("sim/operation/failures/rel_ice_window_heat")
--simDR_bleed_air_fail_L              = find_dataref("sim/operation/failures/rel_bleed_air_lft")
--simDR_bleed_air_fail_R              = find_dataref("sim/operation/failures/rel_bleed_air_rgt")

--simDR_window_ice                    = find_dataref("sim/flightmodel/failures/window_ice")
simDR_OAT=find_dataref("sim/weather/temperature_ambient_c")

simDR_engine_bleed_air_fail         = find_dataref("sim/cockpit2/annunciators/bleed_air_fail")

simDR_gear_deploy_ratio             = find_dataref("sim/flightmodel2/gear/deploy_ratio")
simDR_aircraft_altitude             = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
simDR_cabin_altitude                = find_dataref("sim/cockpit2/pressurization/indicators/cabin_altitude_ft")

simDR_autopilot_servos_on           	= find_dataref("laminar/B747/autopilot/servos_on")
B747DR_autothrottle_active	= find_dataref("laminar/B747/engines/autothrottle_active")

simDR_autopilot_fms_vnav_status			= find_dataref("sim/cockpit2/autopilot/fms_vnav")
B747DR_ap_FMA_active_pitch_mode     	= find_dataref("laminar/B747/autopilot/FMA/active_pitch_mode")
simDR_autopilot_flch_status         	= find_dataref("laminar/B747/autopilot/speed_status")
simDR_autopilot_heading_hold_status     = find_dataref("sim/cockpit2/autopilot/heading_hold_status")
simDR_autopilot_vs_status           	= find_dataref("laminar/B747/autopilot/vvi_status")
simDR_autopilot_alt_hold_status         = find_dataref("laminar/B747/autopilot/altitude_hold_status")
B747DR_ap_approach_mode     	= find_dataref("laminar/B747/autopilot/approach_mode")
--simDR_autopilot_nav_status          = find_dataref("sim/cockpit2/autopilot/nav_status")
--simDR_autopilot_gs_status           = find_dataref("sim/cockpit2/autopilot/glideslope_status")
simDR_autopilot_nav_status = find_dataref("laminar/B747/autopilot/actual_nav_status")
simDR_autopilot_gs_status = find_dataref("laminar/B747/autopilot/actual_glideslope_status")

simDR_autopilot_app_status          = find_dataref("sim/cockpit2/autopilot/approach_status")
B747DR_autopilot_nav_status = find_dataref("laminar/B747/autopilot/nav_status")
B747DR_autopilot_gs_status = find_dataref("laminar/B747/autopilot/glideslope_status")
simDR_esys0              = find_dataref("sim/operation/failures/rel_esys")
simDR_esys1              = find_dataref("sim/operation/failures/rel_esys2")
simDR_esys2              = find_dataref("sim/operation/failures/rel_esys3")
simDR_esys3              = find_dataref("sim/operation/failures/rel_esys4")


simDR_cockpit2_no_smoking_switch    = find_dataref("sim/cockpit2/switches/no_smoking")
simDR_cockpit2_seat_belt_switch     = find_dataref("sim/cockpit2/switches/fasten_seat_belts")

simDR_fuel_tank_weight_kg           = find_dataref("sim/flightmodel/weight/m_fuel")

simDR_autoboard_in_progress         = find_dataref("sim/flightmodel2/misc/auto_board_in_progress")
simDR_autostart_in_progress         = find_dataref("sim/flightmodel2/misc/auto_start_in_progress")

simDR_flap_ratio_control        	= find_dataref("sim/cockpit2/controls/flap_ratio")





--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--
B747DR_ap_lnav_state                = find_dataref("laminar/B747/autopilot/lnav_state")
B747DR_ap_vnav_state                = find_dataref("laminar/B747/autopilot/vnav_state")
B747DR_button_switch_position       = find_dataref("laminar/B747/button_switch/position")
B747DR_toggle_switch_position       = find_dataref("laminar/B747/toggle_switch/position")
B747DR_engine_TOGA_mode             = find_dataref("laminar/B747/engines/TOGA_mode")
B747DR_elec_ext_pwr1_available      = find_dataref("laminar/B747/electrical/ext_pwr1_avail")
B747DR_elec_ext_pwr2_available      = find_dataref("laminar/B747/electrical/ext_pwr2_avail")
B747DR_elec_apu_pwr1_available      = find_dataref("laminar/B747/electrical/apu_pwr1_avail")
B747DR_elec_apu_pwr2_available      = find_dataref("laminar/B747/electrical/apu_pwr2_avail")
B747DR_elec_ext_pwr1_on      	    = find_dataref("laminar/B747/electrical/ext_pwr1_on")
B747DR_elec_ext_pwr2_on      	    = find_dataref("laminar/B747/electrical/ext_pwr2_on")
B747DR_elec_apu_pwr1_on      	    = find_dataref("laminar/B747/electrical/apu_pwr1_on")
B747DR_elec_apu_pwr2_on      	    = find_dataref("laminar/B747/electrical/apu_pwr2_on")
B747DR_elec_ext_pwr_1_switch_mode   = find_dataref("laminar/B747/elec_ext_pwr_1/switch_mode")
B747DR_elec_apu_pwr_1_switch_mode   = find_dataref("laminar/B747/apu_pwr_1/switch_mode")
B747DR_elec_ext_pwr_2_switch_mode   = find_dataref("laminar/B747/elec_ext_pwr_2/switch_mode")
B747DR_elec_apu_pwr_2_switch_mode   = find_dataref("laminar/B747/apu_pwr_2/switch_mode")
B747DR_gear_handle 					= find_dataref("laminar/B747/actuator/gear_handle")
--B747DR_gear_handle_position         = find_dataref("laminar/B747/gear_handle/position")
--B747DR_flap_lever                   = find_dataref("laminar/B747/flt_ctrls/flap_lever")
B747DR_hyd_dmd_pmp_sel_pos          = find_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos")

B747DR_rtp_L_offside_tuning_status  = find_dataref("laminar/B747/comm/rtp_L/offside_tuning_status")
B747DR_rtp_L_off_status             = find_dataref("laminar/B747/comm/rtp_L/off_status")
B747DR_rtp_L_vhf_L_status           = find_dataref("laminar/B747/comm/rtp_L/vhf_L_status")
B747DR_rtp_L_vhf_C_status           = find_dataref("laminar/B747/comm/rtp_L/vhf_C_status")
B747DR_rtp_L_vhf_R_status           = find_dataref("laminar/B747/comm/rtp_L/vhf_R_status")
B747DR_rtp_L_hf_L_status            = find_dataref("laminar/B747/comm/rtp_L/hf_L_status")
B747DR_rtp_L_am_status              = find_dataref("laminar/B747/comm/rtp_L/am_status")
B747DR_rtp_L_hf_R_status            = find_dataref("laminar/B747/comm/rtp_L/hf_R_status")
B747DR_rtp_R_offside_tuning_status  = find_dataref("laminar/B747/comm/rtp_R/offside_tuning_status")
B747DR_rtp_R_off_status             = find_dataref("laminar/B747/comm/rtp_R/off_status")
B747DR_rtp_R_vhf_L_status           = find_dataref("laminar/B747/comm/rtp_R/vhf_L_status")
B747DR_rtp_R_vhf_C_status           = find_dataref("laminar/B747/comm/rtp_R/vhf_C_status")
B747DR_rtp_R_vhf_R_status           = find_dataref("laminar/B747/comm/rtp_R/vhf_R_status")
B747DR_rtp_R_hf_L_status            = find_dataref("laminar/B747/comm/rtp_R/hf_L_status")
B747DR_rtp_R_am_status              = find_dataref("laminar/B747/comm/rtp_R/am_status")
B747DR_rtp_R_hf_R_status            = find_dataref("laminar/B747/comm/rtp_R/hf_R_status")
B747DR_rtp_C_offside_tuning_status  = find_dataref("laminar/B747/comm/rtp_C/offside_tuning_status")
B747DR_rtp_C_off_status             = find_dataref("laminar/B747/comm/rtp_C/off_status")
B747DR_rtp_C_vhf_L_status           = find_dataref("laminar/B747/comm/rtp_C/vhf_L_status")
B747DR_rtp_C_vhf_C_status           = find_dataref("laminar/B747/comm/rtp_C/vhf_C_status")
B747DR_rtp_C_vhf_R_status           = find_dataref("laminar/B747/comm/rtp_C/vhf_R_status")
B747DR_rtp_C_hf_L_status            = find_dataref("laminar/B747/comm/rtp_C/hf_L_status")
B747DR_rtp_C_am_status              = find_dataref("laminar/B747/comm/rtp_C/am_status")
B747DR_rtp_C_hf_R_status            = find_dataref("laminar/B747/comm/rtp_C/hf_R_status")

B747DR_ap_L_vhf_L_xmt_status        = find_dataref("laminar/B747/ap_L/vhf_L/xmt_status")
B747DR_ap_L_vhf_C_xmt_status        = find_dataref("laminar/B747/ap_L/vhf_C/xmt_status")
B747DR_ap_L_vhf_R_xmt_status        = find_dataref("laminar/B747/ap_L/vhf_R/xmt_status")
B747DR_ap_L_flt_xmt_status          = find_dataref("laminar/B747/ap_L/flt/xmt_status")
B747DR_ap_L_cab_xmt_status          = find_dataref("laminar/B747/ap_L/cab/xmt_status")
B747DR_ap_L_pa_xmt_status           = find_dataref("laminar/B747/ap_L/pa/xmt_status")
B747DR_ap_L_hf_L_xmt_status         = find_dataref("laminar/B747/ap_L/hf_L/xmt_status")
B747DR_ap_L_hf_R_xmt_status         = find_dataref("laminar/B747/ap_L/hf_R/xmt_status")
B747DR_ap_L_sat_L_xmt_status        = find_dataref("laminar/B747/ap_L/sat_L/xmt_status")
B747DR_ap_L_sat_R_xmt_status        = find_dataref("laminar/B747/ap_L/sat_R/xmt_status")

B747DR_ap_L_vhf_L_call_status       = find_dataref("laminar/B747/ap_L/vhf_L/call_status")
B747DR_ap_L_vhf_C_call_status       = find_dataref("laminar/B747/ap_L/vhf_C/call_status")
B747DR_ap_L_vhf_R_call_status       = find_dataref("laminar/B747/ap_L/vhf_R/call_status")
B747DR_ap_L_flt_call_status         = find_dataref("laminar/B747/ap_L/flt/call_status")
B747DR_ap_L_cab_call_status         = find_dataref("laminar/B747/ap_L/cab/call_status")
B747DR_ap_L_pa_call_status          = find_dataref("laminar/B747/ap_L/pa/call_status")
B747DR_ap_L_hf_L_call_status        = find_dataref("laminar/B747/ap_L/hf_L/call_status")
B747DR_ap_L_hf_R_call_status        = find_dataref("laminar/B747/ap_L/hf_R/call_status")
B747DR_ap_L_sat_L_call_status       = find_dataref("laminar/B747/ap_L/sat_L/call_status")
B747DR_ap_L_sat_R_call_status       = find_dataref("laminar/B747/ap_L/sat_R/call_status")

B747DR_ap_L_vhf_L_audio_status      = find_dataref("laminar/B747/ap_L/vhf_L/audio_status")
B747DR_ap_L_vhf_C_audio_status      = find_dataref("laminar/B747/ap_L/vhf_C/audio_status")
B747DR_ap_L_vhf_R_audio_status      = find_dataref("laminar/B747/ap_L/vhf_R/audio_status")
B747DR_ap_L_flt_audio_status        = find_dataref("laminar/B747/ap_L/flt/audio_status")
B747DR_ap_L_cab_audio_status        = find_dataref("laminar/B747/ap_L/cab/audio_status")
B747DR_ap_L_pa_audio_status         = find_dataref("laminar/B747/ap_L/pa/audio_status")
B747DR_ap_L_hf_L_audio_status       = find_dataref("laminar/B747/ap_L/hf_L/audio_status")
B747DR_ap_L_hf_R_audio_status       = find_dataref("laminar/B747/ap_L/hf_R/audio_status")
B747DR_ap_L_sat_L_audio_status      = find_dataref("laminar/B747/ap_L/sat_L/audio_status")
B747DR_ap_L_sat_R_udio_status       = find_dataref("laminar/B747/ap_L/sat_R/audio_status")
B747DR_ap_L_spkr_audio_status       = find_dataref("laminar/B747/ap_L/spkr/audio_status")
B747DR_ap_L_vor_adf_audio_status    = find_dataref("laminar/B747/ap_L/vor_adf/audio_status")
B747DR_ap_L_app_mkr_audio_status    = find_dataref("laminar/B747/ap_L/app_mkr/audio_status")

B747DR_ap_C_vhf_L_xmt_status        = find_dataref("laminar/B747/ap_C/vhf_L/xmt_status")
B747DR_ap_C_vhf_C_xmt_status        = find_dataref("laminar/B747/ap_C/vhf_C/xmt_status")
B747DR_ap_C_vhf_R_xmt_status        = find_dataref("laminar/B747/ap_C/vhf_R/xmt_status")
B747DR_ap_C_flt_xmt_status          = find_dataref("laminar/B747/ap_C/flt/xmt_status")
B747DR_ap_C_cab_xmt_status          = find_dataref("laminar/B747/ap_C/cab/xmt_status")
B747DR_ap_C_pa_xmt_status           = find_dataref("laminar/B747/ap_C/pa/xmt_status")
B747DR_ap_C_hf_L_xmt_status         = find_dataref("laminar/B747/ap_C/hf_L/xmt_status")
B747DR_ap_C_hf_R_xmt_status         = find_dataref("laminar/B747/ap_C/hf_R/xmt_status")
B747DR_ap_C_sat_L_xmt_status        = find_dataref("laminar/B747/ap_C/sat_L/xmt_status")
B747DR_ap_C_sat_R_xmt_status        = find_dataref("laminar/B747/ap_C/sat_R/xmt_status")

B747DR_ap_C_vhf_L_call_status       = find_dataref("laminar/B747/ap_C/vhf_L/call_status")
B747DR_ap_C_vhf_C_call_status       = find_dataref("laminar/B747/ap_C/vhf_C/call_status")
B747DR_ap_C_vhf_R_call_status       = find_dataref("laminar/B747/ap_C/vhf_R/call_status")
B747DR_ap_C_flt_call_status         = find_dataref("laminar/B747/ap_C/flt/call_status")
B747DR_ap_C_cab_call_status         = find_dataref("laminar/B747/ap_C/cab/call_status")
B747DR_ap_C_pa_call_status          = find_dataref("laminar/B747/ap_C/pa/call_status")
B747DR_ap_C_hf_L_call_status        = find_dataref("laminar/B747/ap_C/hf_L/call_status")
B747DR_ap_C_hf_R_call_status        = find_dataref("laminar/B747/ap_C/hf_R/call_status")
B747DR_ap_C_sat_L_call_status       = find_dataref("laminar/B747/ap_C/sat_L/call_status")
B747DR_ap_C_sat_R_call_status       = find_dataref("laminar/B747/ap_C/sat_R/call_status")

B747DR_ap_C_vhf_L_audio_status      = find_dataref("laminar/B747/ap_C/vhf_L/audio_status")
B747DR_ap_C_vhf_C_audio_status      = find_dataref("laminar/B747/ap_C/vhf_C/audio_status")
B747DR_ap_C_vhf_R_audio_status      = find_dataref("laminar/B747/ap_C/vhf_R/audio_status")
B747DR_ap_C_flt_audio_status        = find_dataref("laminar/B747/ap_C/flt/audio_status")
B747DR_ap_C_cab_audio_status        = find_dataref("laminar/B747/ap_C/cab/audio_status")
B747DR_ap_C_pa_audio_status         = find_dataref("laminar/B747/ap_C/pa/audio_status")
B747DR_ap_C_hf_L_audio_status       = find_dataref("laminar/B747/ap_C/hf_L/audio_status")
B747DR_ap_C_hf_R_audio_status       = find_dataref("laminar/B747/ap_C/hf_R/audio_status")
B747DR_ap_C_sat_L_audio_status      = find_dataref("laminar/B747/ap_C/sat_L/audio_status")
B747DR_ap_C_sat_R_udio_status       = find_dataref("laminar/B747/ap_C/sat_R/audio_status")
B747DR_ap_C_spkr_audio_status       = find_dataref("laminar/B747/ap_C/spkr/audio_status")
B747DR_ap_C_vor_adf_audio_status    = find_dataref("laminar/B747/ap_C/vor_adf/audio_status")
B747DR_ap_C_app_mkr_audio_status    = find_dataref("laminar/B747/ap_C/app_mkr/audio_status")

B747DR_ap_R_vhf_L_xmt_status        = find_dataref("laminar/B747/ap_R/vhf_L/xmt_status")
B747DR_ap_R_vhf_C_xmt_status        = find_dataref("laminar/B747/ap_R/vhf_C/xmt_status")
B747DR_ap_R_vhf_R_xmt_status        = find_dataref("laminar/B747/ap_R/vhf_R/xmt_status")
B747DR_ap_R_flt_xmt_status          = find_dataref("laminar/B747/ap_R/flt/xmt_status")
B747DR_ap_R_cab_xmt_status          = find_dataref("laminar/B747/ap_R/cab/xmt_status")
B747DR_ap_R_pa_xmt_status           = find_dataref("laminar/B747/ap_R/pa/xmt_status")
B747DR_ap_R_hf_L_xmt_status         = find_dataref("laminar/B747/ap_R/hf_L/xmt_status")
B747DR_ap_R_hf_R_xmt_status         = find_dataref("laminar/B747/ap_R/hf_R/xmt_status")
B747DR_ap_R_sat_L_xmt_status        = find_dataref("laminar/B747/ap_R/sat_L/xmt_status")
B747DR_ap_R_sat_R_xmt_status        = find_dataref("laminar/B747/ap_R/sat_R/xmt_status")

B747DR_ap_R_vhf_L_call_status       = find_dataref("laminar/B747/ap_R/vhf_L/call_status")
B747DR_ap_R_vhf_C_call_status       = find_dataref("laminar/B747/ap_R/vhf_C/call_status")
B747DR_ap_R_vhf_R_call_status       = find_dataref("laminar/B747/ap_R/vhf_R/call_status")
B747DR_ap_R_flt_call_status         = find_dataref("laminar/B747/ap_R/flt/call_status")
B747DR_ap_R_cab_call_status         = find_dataref("laminar/B747/ap_R/cab/call_status")
B747DR_ap_R_pa_call_status          = find_dataref("laminar/B747/ap_R/pa/call_status")
B747DR_ap_R_hf_L_call_status        = find_dataref("laminar/B747/ap_R/hf_L/call_status")
B747DR_ap_R_hf_R_call_status        = find_dataref("laminar/B747/ap_R/hf_R/call_status")
B747DR_ap_R_sat_L_call_status       = find_dataref("laminar/B747/ap_R/sat_L/call_status")
B747DR_ap_R_sat_R_call_status       = find_dataref("laminar/B747/ap_R/sat_R/call_status")

B747DR_ap_R_vhf_L_audio_status      = find_dataref("laminar/B747/ap_R/vhf_L/audio_status")
B747DR_ap_R_vhf_C_audio_status      = find_dataref("laminar/B747/ap_R/vhf_C/audio_status")
B747DR_ap_R_vhf_R_audio_status      = find_dataref("laminar/B747/ap_R/vhf_R/audio_status")
B747DR_ap_R_flt_audio_status        = find_dataref("laminar/B747/ap_R/flt/audio_status")
B747DR_ap_R_cab_audio_status        = find_dataref("laminar/B747/ap_R/cab/audio_status")
B747DR_ap_R_pa_audio_status         = find_dataref("laminar/B747/ap_R/pa/audio_status")
B747DR_ap_R_hf_L_audio_status       = find_dataref("laminar/B747/ap_R/hf_L/audio_status")
B747DR_ap_R_hf_R_audio_status       = find_dataref("laminar/B747/ap_R/hf_R/audio_status")
B747DR_ap_R_sat_L_audio_status      = find_dataref("laminar/B747/ap_R/sat_L/audio_status")
B747DR_ap_R_sat_R_udio_status       = find_dataref("laminar/B747/ap_R/sat_R/audio_status")
B747DR_ap_R_spkr_audio_status       = find_dataref("laminar/B747/ap_R/spkr/audio_status")
B747DR_ap_R_vor_adf_audio_status    = find_dataref("laminar/B747/ap_R/vor_adf/audio_status")
B747DR_ap_R_app_mkr_audio_status    = find_dataref("laminar/B747/ap_R/app_mkr/audio_status")


B747DR_call_pnl_ud_call_status     = find_dataref("laminar/B747/call_pnl/ud/call_status")
B747DR_call_pnl_crw_rst_L_call_status = find_dataref("laminar/B747/call_pnl/crw_rst_L/call_status")
B747DR_call_pnl_crw_rst_R_call_status = find_dataref("laminar/B747/call_pnl/crw_rst_R/call_status")
B747DR_call_pnl_cargo_call_status  = find_dataref("laminar/B747/call_pnl/cargo/call_status")
B747DR_call_pnl_grnd_call_status   = find_dataref("laminar/B747/call_pnl/grnd/call_status")


B747DR_sfty_no_smoke_sel_dial_pos   = find_dataref("laminar/B747/safety/no_smoking/sel_dial_pos")
B747DR_sfty_seat_belts_sel_dial_pos = find_dataref("laminar/B747/safety/seat_belts/sel_dial_pos")


B747DR_fire_ext_bottle_0102A_psi    = find_dataref("laminar/B747/fire/engine01_02A/ext_bottle/psi")
B747DR_fire_ext_bottle_0102B_psi    = find_dataref("laminar/B747/fire/engine01_02B/ext_bottle/psi")
B747DR_fire_ext_bottle_0304A_psi    = find_dataref("laminar/B747/fire/engine03_04A/ext_bottle/psi")
B747DR_fire_ext_bottle_0304B_psi    = find_dataref("laminar/B747/fire/engine03_04B/ext_bottle/psi")

B747DR_fuel_engine1_xfeed_vlv_pos   = find_dataref("laminar/B747/fuel/engine1/xfeed_vlv_pos")
B747DR_fuel_engine4_xfeed_vlv_pos   = find_dataref("laminar/B747/fuel/engine4/xfeed_vlv_pos")

B747_fuel_main1_tank_main_pump_fwd_on = find_dataref("laminar/B747/fuel/main1_tank/main_pump_fwd_on")
B747_fuel_main1_tank_main_pump_aft_on = find_dataref("laminar/B747/fuel/main1_tank/main_pump_aft_on")
B747_fuel_main2_tank_main_pump_fwd_on = find_dataref("laminar/B747/fuel/main2_tank/main_pump_fwd_on")
B747_fuel_main2_tank_main_pump_aft_on = find_dataref("laminar/B747/fuel/main2_tank/main_pump_aft_on")
B747_fuel_main3_tank_main_pump_fwd_on = find_dataref("laminar/B747/fuel/main3_tank/main_pump_fwd_on")
B747_fuel_main3_tank_main_pump_aft_on = find_dataref("laminar/B747/fuel/main3_tank/main_pump_aft_on")
B747_fuel_main4_tank_main_pump_fwd_on = find_dataref("laminar/B747/fuel/main4_tank/main_pump_fwd_on")
B747_fuel_main4_tank_main_pump_aft_on = find_dataref("laminar/B747/fuel/main4_tank/main_pump_aft_on")

B747_fuel_center_tank_ovrd_jett_pump_L_on = find_dataref("laminar/B747/fuel/center_tank/ovrd_jett_pump_L_on")
B747_fuel_center_tank_ovrd_jett_pump_R_on = find_dataref("laminar/B747/fuel/center_tank/ovrd_jett_pump_R_on")

B747_fuel_stab_tank_xfr_jett_pump_L_on = find_dataref("laminar/B747/fuel/stab_tank/xfr_jett_pump_L_on")
B747_fuel_stab_tank_xfr_jett_pump_R_on = find_dataref("laminar/B747/fuel/stab_tank/xfr_jett_pump_R_on")

B747_fuel_main2_tank_ovrd_jett_pump_fwd_on = find_dataref("laminar/B747/fuel/main2_tank/ovrd_jett_pump_fwd_on")
B747_fuel_main2_tank_ovrd_jett_pump_aft_on = find_dataref("laminar/B747/fuel/main2_tank/ovrd_jett_pump_aft_on")

B747_fuel_main3_tank_ovrd_jett_pump_fwd_on = find_dataref("laminar/B747/fuel/main3_tank/ovrd_jett_pump_fwd_on")
B747_fuel_main3_tank_ovrd_jett_pump_aft_on = find_dataref("laminar/B747/fuel/main3_tank/ovrd_jett_pump_aft_on")

B747DR_bleed_air_iso_vlv_L_pos      = find_dataref("laminar/B747/air/isolation_valve_L_pos")
B747DR_bleed_air_iso_vlv_R_pos      = find_dataref("laminar/B747/air/isolation_valve_R_pos")

B747DR_bleed_air_apu_vlv_pos        = find_dataref("laminar/B747/air/apu/bleed_valve_pos")

B747DR_bleed_air_engine1_vlv_pos    = find_dataref("laminar/B747/air/engine1/bleed_valve_pos")
B747DR_bleed_air_engine2_vlv_pos    = find_dataref("laminar/B747/air/engine2/bleed_valve_pos")
B747DR_bleed_air_engine3_vlv_pos    = find_dataref("laminar/B747/air/engine3/bleed_valve_pos")
B747DR_bleed_air_engine4_vlv_pos    = find_dataref("laminar/B747/air/engine4/bleed_valve_pos")

B747DR_bleed_air_engine1_start_valve_pos = find_dataref("laminar/B747/air/engine1/bleed_start_valve_pos")
B747DR_bleed_air_engine2_start_valve_pos = find_dataref("laminar/B747/air/engine2/bleed_start_valve_pos")
B747DR_bleed_air_engine3_start_valve_pos = find_dataref("laminar/B747/air/engine3/bleed_start_valve_pos")
B747DR_bleed_air_engine4_start_valve_pos = find_dataref("laminar/B747/air/engine4/bleed_start_valve_pos")

B747DR_nacelle_ai_valve_pos         = find_dataref("laminar/B747/antiice/nacelle/valve_pos")
B747DR_wing_ai_valve_pos            = find_dataref("laminar/B747/antiice/wing/valve_pos")

B747DR_autopilot_cmd_L_status       = find_dataref("laminar/B747/autopilot/cmd_L_mode/status")
B747DR_autopilot_cmd_C_status       = find_dataref("laminar/B747/autopilot/cmd_C_mode/status")
B747DR_autopilot_cmd_R_status       = find_dataref("laminar/B747/autopilot/cmd_R_mode/status")

B747DR_master_warning               = find_dataref("laminar/B747/warning/master_warning")
B747DR_master_caution               = find_dataref("laminar/B747/warning/master_caution")

B747DR_CAS_memo_status              = find_dataref("laminar/B747/CAS/memo_status")

B747DR_simDR_captain_display              = deferred_dataref("laminar/B747/electrical/capt_display_power", "number")
B747DR_simDR_fo_display             = deferred_dataref("laminar/B747/electrical/fo_display_power", "number")
B747DR_elec_display_power               = find_dataref("laminar/B747/electrical/display_has_power")


--wxr lighting
B747DR_wxr_left_GCS             = deferred_dataref("laminar/B747/wxr/left/GCS", "number")
B747DR_wxr_left_TFR             = deferred_dataref("laminar/B747/wxr/left/TFR", "number")
B747DR_wxr_left_WX             = deferred_dataref("laminar/B747/wxr/left/WX", "number")
B747DR_wxr_left_WX_T            = deferred_dataref("laminar/B747/wxr/left/WX_T", "number")
B747DR_wxr_left_MAP            = deferred_dataref("laminar/B747/wxr/left/MAP", "number")
B747DR_wxr_right_GCS             = deferred_dataref("laminar/B747/wxr/right/GCS", "number")
B747DR_wxr_right_TFR             = deferred_dataref("laminar/B747/wxr/right/TFR", "number")
B747DR_wxr_right_WX             = deferred_dataref("laminar/B747/wxr/right/WX", "number")
B747DR_wxr_right_WX_T            = deferred_dataref("laminar/B747/wxr/right/WX_T", "number")
B747DR_wxr_right_MAP            = deferred_dataref("laminar/B747/wxr/right/MAP", "number")

B747DR_wxr_test            = deferred_dataref("laminar/B747/wxr/test", "number")
B747DR_wxr_RR            = deferred_dataref("laminar/B747/wxr/RR", "number")
B747DR_wxr_LR            = deferred_dataref("laminar/B747/wxr/LR", "number")

simDR_wxrMode_cpt = find_dataref("sim/cockpit2/EFIS/EFIS_weather_mode")
simDR_wxrMode_fo = find_dataref("sim/cockpit2/EFIS/EFIS_weather_mode_copilot")
simDR_wxrgcs_cpt = find_dataref("sim/cockpit2/EFIS/EFIS_weather_gcs")
simDR_wxrgcs_fo = find_dataref("sim/cockpit2/EFIS/EFIS_weather_gcs_copilot")
--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

----- SPILL LIGHTS ----------------------------------------------------------------------
B747DR_spill_light_capt_panel_flood     = deferred_dataref("laminar/B747/light/spill/ratio/captain_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_center_panel_flood   = deferred_dataref("laminar/B747/light/spill/ratio/center_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_capt_map             = deferred_dataref("laminar/B747/light/spill/ratio/captain_map", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_capt_chart           = deferred_dataref("laminar/B747/light/spill/ratio/captain_chart", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_fo_panel_flood       = deferred_dataref("laminar/B747/light/spill/ratio/first_officer_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_fo_map               = deferred_dataref("laminar/B747/light/spill/ratio/first_officer_map", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_fo_chart             = deferred_dataref("laminar/B747/light/spill/ratio/first_officer_chart", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_observer_map         = deferred_dataref("laminar/B747/light/spill/ratio/observer_map", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_mcp_flood            = deferred_dataref("laminar/B747/light/spill/ratio/mcp_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_aisle_stand_flood    = deferred_dataref("laminar/B747/light/spill/ratio/aisle_stand", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_mag_compass_flood    = deferred_dataref("laminar/B747/light/spill/ratio/mag_compass", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")

B747DR_init_lighting_CD                 = deferred_dataref("laminar/B747/lighting/init_CD", "number")



----- LIT -------------------------------------------------------------------------------
--B747DR_LIT_capt_panel_flood             = deferred_dataref("laminar/B747/light/LIT/capt_panel_flood", "number")
--B747DR_LIT_fo_panel_flood               = deferred_dataref("laminar/B747/light/LIT/fo_panel_flood", "number")



----- ANNUNCIATORS ----------------------------------------------------------------------
B747DR_annun_brightness_ratio           = deferred_dataref("laminar/B747/annunciator/brightness_ratio", "array[" .. tostring(NUM_ANNUN_LIGHTS) .. "]")

B747DR_ap_FMA_autothrottle_mode     	= deferred_dataref("laminar/B747/autopilot/FMA/autothrottle_mode", "number")



--*************************************************************************************--
--** 				         READ-WRITE CUSTOM DATAREF HANDLERS     	    	     **--
--*************************************************************************************--

----- LIGHTING RHEOSTATS ----------------------------------------------------------------
function B747DR_flood_light_rheo_capt_panel_DRhandler() end
function B747DR_map_light_rheo_capt_DRhandler() end
function B747DR_chart_light_rheo_capt_DRhandler() end
function B747DR_flood_light_rheo_fo_panel_DRhandler() end
function B747DR_map_light_rheo_fo_DRhandler() end
function B747DR_chart_light_rheo_fo_DRhandler() end
function B747DR_map_light_rheo_observer_DRhandler() end
function B747DR_flood_light_rheo_mcp_DRhandler() end
function B747DR_flood_light_rheo_aisle_stand_DRhandler() end
function B747DR_flood_light_rheo_overhead_DRhandler() end




--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

----- LIGHTING RHEOSTATS ----------------------------------------------------------------
B747DR_flood_light_rheo_capt_panel      = deferred_dataref("laminar/B747/light/flood/rheostat/captain_panel", "number", B747DR_flood_light_rheo_capt_panel_DRhandler)
B747DR_map_light_rheo_capt              = deferred_dataref("laminar/B747/light/map/rheostat/captain", "number", B747DR_map_light_rheo_capt_DRhandler)
B747DR_chart_light_rheo_capt            = deferred_dataref("laminar/B747/light/chart/rheostat/captain", "number", B747DR_chart_light_rheo_capt_DRhandler)
B747DR_flood_light_rheo_fo_panel        = deferred_dataref("laminar/B747/light/flood/rheostat/first_officer_panel", "number", B747DR_flood_light_rheo_fo_panel_DRhandler)
B747DR_map_light_rheo_fo                = deferred_dataref("laminar/B747/light/map/rheostat/first_officer", "number", B747DR_map_light_rheo_fo_DRhandler)
B747DR_chart_light_rheo_fo              = deferred_dataref("laminar/B747/light/chart/rheostat/first_officer", "number", B747DR_chart_light_rheo_fo_DRhandler)
B747DR_map_light_rheo_observer          = deferred_dataref("laminar/B747/light/map/rheostat/observer", "number", B747DR_map_light_rheo_observer_DRhandler)
B747DR_flood_light_rheo_mcp             = deferred_dataref("laminar/B747/light/flood/rheostat/mcp_panel", "number", B747DR_flood_light_rheo_mcp_DRhandler)
B747DR_flood_light_rheo_aisle_stand     = deferred_dataref("laminar/B747/light/flood/rheostat/aisle_stand", "number", B747DR_flood_light_rheo_aisle_stand_DRhandler)
B747DR_flood_light_rheo_overhead        = deferred_dataref("laminar/B747/light/flood/rheostat/overhead", "number", B747DR_flood_light_rheo_overhead_DRhandler)

----- SPILL LIGHTS ----------------------------------------------------------------------
B747DR_fmc_spill_lights			= deferred_dataref("laminar/B747/fmc/spill_lights", "number") --silvereagle

function B747CMD_cockpitLightsOn_CMDhandler()
  --TODO Animate
  B747DR_flood_light_rheo_capt_panel=1
  B747DR_map_light_rheo_capt=1
  B747DR_chart_light_rheo_capt=1
  B747DR_flood_light_rheo_fo_panel=1
  B747DR_map_light_rheo_fo=1
  B747DR_chart_light_rheo_fo=1
  B747DR_map_light_rheo_observer=1
  B747DR_flood_light_rheo_mcp=1
  B747DR_flood_light_rheo_aisle_stand=1
  B747DR_flood_light_rheo_overhead=1
end

function B747CMD_cockpitLightsOff_CMDhandler()
  --TODO Animate
  B747DR_flood_light_rheo_capt_panel=0
  B747DR_map_light_rheo_capt=0
  B747DR_chart_light_rheo_capt=0
  B747DR_flood_light_rheo_fo_panel=0
  B747DR_map_light_rheo_fo=0
  B747DR_chart_light_rheo_fo=0
  B747DR_map_light_rheo_observer=0
  B747DR_flood_light_rheo_mcp=0
  B747DR_flood_light_rheo_aisle_stand=0
  B747DR_flood_light_rheo_overhead=0
end

B747CMD_cockpitLightsOn		= deferred_command("laminar/B747/light/cockpit_lightsOn", "cockpit lights On", B747CMD_cockpitLightsOn_CMDhandler)
B747CMD_cockpitLightsOff		= deferred_command("laminar/B747/light/cockpit_lightsOff", "cockpit lights Off", B747CMD_cockpitLightsOff_CMDhandler)

--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--






--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--





--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_taxi_light_switch               = find_command("laminar/B747/toggle_switch/taxi_light")
B747CMD_runway_turnoff_light_switch_L   = find_command("laminar/B747/toggle_switch/rwy_tunoff_L")
B747CMD_runway_turnoff_light_switch_R   = find_command("laminar/B747/toggle_switch/rwy_tunoff_R")



--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--


function B747_ai_lighting_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
		B747_set_lighting_all_modes()
		B747_set_lighting_CD()
		B747_set_lighting_ER()	
	end 	
end	



--*************************************************************************************--
--** 				               CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- AI
B747CMD_ai_lighting_quick_start			= deferred_command("laminar/B747/ai/lighting_quick_start", "number", B747_ai_lighting_quick_start_CMDhandler)



--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--




--*************************************************************************************--
--** 				              CREATE SYSTEM OBJECTS            	    			 **--
--*************************************************************************************--




--*************************************************************************************--
--** 				                 SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end





----- RESCALE FLOAT AND CLAMP TO OUTER LIMITS -------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end






----- INITIALIZE LIGHTING ---------------------------------------------------------------
function B747_init_lighting()

    -- TURN OFF THE FLIGHT DECK OVERHEAD FLOOD LIGHTS
    simDR_panel_brightness_switch[0] = 0.0

    -- SPILL LIGHTS
    --[[
    NOTE: FOR SPILL LIGHTS (AS PER BEN SUPNIK)...
    THE ORDER OF ARRAY DATA FOR THE OBJ FILE IS DIFFERENT THAN WHAT WE NEED TO USE TO SET THE DATAREF IN CODE.

    OBJ IS AS FOLLOWS:
    X	Y	Z	R	G	B	A	SIZE	Dx	Dy	Dz	SEMI	DATAREF

    SET DATAREF WITH CODE AS FOLLOWS:
    X	Y	Z	R	G	B	A	SIZE	SEMI	Dx	Dy	Dz
    --]]

    local capt_panel_flood_values = {1.0, 0.70, 0.24, 0.0, 0.55, 0.60, -0.05, -0.525, -0.425}
    local center_panel_flood_values = {1.0, 0.70, 0.24, 0.0, 0.65, 0.15, 0.0, -1.0, 0.0}
    local capt_map_values = {1.0, 0.70, 0.24, 0.0, 2.0, 0.98, 0.0, -1.0, 0.0}
    local capt_chart_values = {1.0, 0.70, 0.24, 0.0, 0.37, 0.88, -0.35, -0.65, 0.25}
    local fo_panel_flood_values = {1.0, 0.70, 0.24,  0.0, 0.55, 0.60, 0.05, -0.525, -0.425}
    local fo_map_values = {1.0, 0.70, 0.24, 0.0, 2.0, 0.98, 0.0, -1.0, 0.0}
    local fo_chart_values = {1.0, 0.70, 0.24, 0.0, 0.37, 0.88, 0.35, -0.65, 0.25}
    local observer_map_values = {1.0, 0.70, 0.24, 0.0, 2.5, 0.95, 0.15, -0.68, 0.17}
    local mcp_flood_values = {1.0, 0.70, 0.24, 0.0, 0.12, 0.08, 0.0, -0.50, 0.50}
    local aisle_stand_flood_values = {1.0, 0.70, 0.24, 0.0, 2.0, 0.85, 0.0, -0.8, -0.2}
    local mag_compass_flood_values = {1.0, 0.70, 0.24, 0.0, 0.1, 0.55, 0.0, 0.0 , -1.0}
    if simDR_version>=120012 then
        capt_panel_flood_values = {1.0, 0.70, 0.24, 10.0, 55.0, 0.60, -0.05, -0.525, -0.425}
        center_panel_flood_values = {1.0, 0.70, 0.24, 10.0, 65.0, 0.15, 0.0, -1.0, 0.0}
        capt_map_values = {1.0, 0.70, 0.24, 10.0, 200.0, 0.98, 0.0, -1.0, 0.0}
        capt_chart_values = {1.0, 0.70, 0.24, 10.0, 37.0, 0.88, -0.35, -0.65, 0.25}
        fo_panel_flood_values = {1.0, 0.70, 0.24,  10.0, 55.0, 0.60, 0.05, -0.525, -0.425}
        fo_map_values = {1.0, 0.70, 0.24, 10.0, 200.0, 0.98, 0.0, -1.0, 0.0}
        fo_chart_values = {1.0, 0.70, 0.24, 10.0, 37.0, 0.88, 0.35, -0.65, 0.25}
        observer_map_values = {1.0, 0.70, 0.24, 10.0, 250.0, 0.95, 0.15, -0.68, 0.17}
        mcp_flood_values = {1.0, 0.70, 0.24, 10.0, 12.0, 0.08, 0.0, -0.50, 0.50}
        aisle_stand_flood_values = {1.0, 0.70, 0.24, 10.0, 200.0, 0.85, 0.0, -0.8, -0.2}
        mag_compass_flood_values = {1.0, 0.70, 0.24, 10.0, 10.0, 0.55, 0.0, 0.0 , -1.0}
    end
    for i = 1, NUM_SPILL_LIGHT_INDICES do
        B747DR_spill_light_capt_panel_flood[i-1] = capt_panel_flood_values[i]
        B747DR_spill_light_center_panel_flood[i-1] = center_panel_flood_values[i]
        B747DR_spill_light_capt_map[i-1] = capt_map_values[i]
        B747DR_spill_light_capt_chart[i-1] = capt_chart_values[i]
        B747DR_spill_light_fo_panel_flood[i-1] = fo_panel_flood_values[i]
        B747DR_spill_light_fo_map[i-1] = fo_map_values[i]
        B747DR_spill_light_fo_chart[i-1] = fo_chart_values[i]
        B747DR_spill_light_observer_map[i-1] = observer_map_values[i]
        B747DR_spill_light_mcp_flood[i-1] = mcp_flood_values[i]
        B747DR_spill_light_aisle_stand_flood[i-1] = aisle_stand_flood_values[i]
        B747DR_spill_light_mag_compass_flood[i-1] = mag_compass_flood_values[i]
    end

end




----- INIT THE LIGHT RHEOSTATS ----------------------------------------------------------
function B747_init_light_rheostats()					

    local light_level = B747_rescale(0.1, 0.0, 0.2, 0.45, simDR_percent_lights_on)
    
    B747DR_flood_light_rheo_capt_panel      = light_level
    B747DR_map_light_rheo_capt              = 0
    B747DR_chart_light_rheo_capt            = 0
    B747DR_flood_light_rheo_fo_panel        = light_level
    B747DR_map_light_rheo_fo                = 0
    B747DR_chart_light_rheo_fo              = 0
    B747DR_map_light_rheo_observer          = 0
    B747DR_flood_light_rheo_mcp             = light_level
    B747DR_flood_light_rheo_aisle_stand     = light_level
    B747DR_flood_light_rheo_overhead        = 0
    simDR_panel_brightness_switch[1]        = light_level * 0.85                            -- FIRST OBSERVER PANEL
    simDR_panel_brightness_switch[2]        = light_level * 0.85                            -- AISLE STAND PANEL
    simDR_panel_brightness_switch[3]        = light_level * 0.90                            -- GLARESHIELD PANEL/MCP PANEL/COMPASS
    B747DR_instrument_brightness_ratio[6]   = light_level * 0.10                            -- CAPTAIN PANEL
    B747DR_instrument_brightness_ratio[7]   = light_level * 0.10                            -- OVERHEAD PANEL
    B747DR_instrument_brightness_ratio[8]   = light_level * 0.10                            -- F/O PANEL
    
    --simDR_panel_brightness_switch[1]        = light_level * 0.85                            -- FIRST OBSERVER PANEL
    --simDR_panel_brightness_switch[2]        = light_level * 0.85                            -- AISLE STAND PANEL
    --simDR_panel_brightness_switch[3]        = light_level * 0.90                            -- GLARESHIELD PANEL/MCP PANEL/COMPASS
    --B747DR_instrument_brightness_ratio[6]   = light_level * 0.90                            -- CAPTAIN PANEL
    --B747DR_instrument_brightness_ratio[7]   = light_level * 0.90                            -- OVERHEAD PANEL
    --B747DR_instrument_brightness_ratio[8]   = light_level * 0.90                            -- F/O PANEL

end




----- LANDING LIGHTS --------------------------------------------------------------------
function B747_landing_light_brightness()

    local gear_handle_factor = 0.5
    if B747DR_gear_handle < 0.05 then gear_handle_factor = 1.0 else gear_handle_factor = 0.5 end

    simDR_landing_light_switch[0] = (1 - B747DR_toggle_switch_position[1]) * gear_handle_factor
    simDR_landing_light_switch[1] = (1 - B747DR_toggle_switch_position[3]) * gear_handle_factor
    simDR_landing_light_switch[2] = (1 - B747DR_toggle_switch_position[4]) * gear_handle_factor
    simDR_landing_light_switch[3] = (1 - B747DR_toggle_switch_position[2]) * gear_handle_factor

end








----- TURNOFF LIGHTS --------------------------------------------------------------------
function B747_turnoff_lights()

    -- LEFT TURNOFF LIGHT
    if simDR_all_wheels_on_ground == 1 and B747DR_toggle_switch_position[5] < 0.05 then
        simDR_generic_brightness_switch[0] = 1
    else
        simDR_generic_brightness_switch[0] = 0
    end

    -- RIGHT TURNOFF LIGHT
    if simDR_all_wheels_on_ground == 1 and B747DR_toggle_switch_position[6] < 0.05 then
        simDR_generic_brightness_switch[1] = 1
    else
        simDR_generic_brightness_switch[1] = 0
    end

end





----- TAXI LIGHTS -----------------------------------------------------------------------
function B747_taxi_lights()

    if simDR_all_wheels_on_ground == 1 and B747DR_toggle_switch_position[7] < 0.05 then
        simDR_taxi_light_switch_on = 1
    else
        simDR_taxi_light_switch_on = 0
    end

end






----- BEACON LIGHTS ---------------------------------------------------------------------
function B747_beacon_lights()

   
    if B747DR_toggle_switch_position[8] > 0.95
        or B747DR_toggle_switch_position[8] < -0.95
    then
        simDR_beacon_lights_switch = 1
    else
        simDR_beacon_lights_switch = 0
    end	 

end




----- NAV LIGHTS ------------------------------------------------------------------------
function B747_nav_lights()

    simDR_nav_lights_switch = 1 - B747DR_toggle_switch_position[9]

end





----- STROBE LIGHTS ---------------------------------------------------------------------
function B747_strobe_lights()

   	simDR_strobe_lights_switch = B747DR_toggle_switch_position[10]

end





----- WING LIGHTS -----------------------------------------------------------------------
function B747_wing_lights()

    simDR_generic_brightness_switch[2] = 1 - B747DR_toggle_switch_position[11]

end





----- LOGO LIGHTS -----------------------------------------------------------------------
function B747_logo_lights()

    simDR_generic_brightness_switch[3] = 1 - B747DR_toggle_switch_position[12]

end



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

local brightnessRate={}
local brightnessPower={}
for i = 0, 32 do
	brightnessRate[i]=0.5+math.random()
	brightnessPower[i]=1
end
----- CABIN LIGHTS ----------------------------------------------------------------------
function B747_cabin_lights()
    --B747DR_elec_display_power
        -- Captain PFD 0
    -- First Officer PFD 1
    -- First Officer ND 2
    -- Captain ND 3
    -- Upper EIACAS 4
    -- Lower EICAS 5
       brightnessPower[3]=B747_animate_value(brightnessPower[3],B747DR_elec_display_power[2],0,1,0.5) --FO ND
       brightnessPower[5]=B747_animate_value(brightnessPower[5],B747DR_elec_display_power[1],0,1,0.5) --FO PFD
       brightnessPower[10]=B747_animate_value(brightnessPower[10],B747DR_elec_display_power[5],0,1,0.5) --LOWER EICAS
       brightnessPower[0]=B747_animate_value(brightnessPower[0],B747DR_elec_display_power[3],0,1,0.5) --C ND
       brightnessPower[2]=B747_animate_value(brightnessPower[2],B747DR_elec_display_power[0],0,1,0.5) --C PFD
       brightnessPower[9]=B747_animate_value(brightnessPower[9],B747DR_elec_display_power[4],0,1,0.5) --UPPER EICAS
     if B747DR_simDR_fo_display==6 then --FO Transfer bus
       brightnessPower[13]=0 --FMS R
     else
       brightnessPower[13]=B747_animate_value(brightnessPower[13],1,0,1,0.5)
     end
     
     if B747DR_simDR_captain_display==6 then --Capt Transfer bus
       brightnessPower[12]=0 --FMS C/L
     else
       brightnessPower[12]=B747_animate_value(brightnessPower[12],1,0,1,0.5)
     end
     

     for i = 0, 32 do
-- 	--print(i)
         simDR_instrument_brightness_switch[i] = B747_animate_value(simDR_instrument_brightness_switch[i],B747DR_instrument_brightness_ratio[i]* simDR_generic_brightness_ratio[63]*brightnessPower[i],0,1,brightnessRate[i])
     end
    local power = B747_ternary(
        (simDR_apu_gen_on == 1                                                          -- APU IS RUNNING
        or
        simDR_gpu_on == 1                                                               -- GPU IS ON
        or
        (simDR_generator_on[0] == 1 and simDR_engine_running[0] == 1)                   -- ENGINE #1 GENERATOR IS ON
        or
        (simDR_generator_on[1] == 1 and simDR_engine_running[1] == 1)                   -- ENGINE #2 GENERATOR IS ON
        or
        (simDR_generator_on[2] == 1 and simDR_engine_running[2] == 1)                   -- ENGINE #3 GENERATOR IS ON
        or
        (simDR_generator_on[3] == 1 and simDR_engine_running[3] == 1))                  -- ENGINE #4 GENERATOR IS ON
        and
        simDR_cross_tie == 1                                                            -- CROSS-TIE IS ON
        , 1, 0)



    local switch_value = 0

    if simDR_ai_flies_aircraft == 1
        or simDR_autoboard_in_progress == 1
        or simDR_autostart_in_progress == 1
    then
        if B747DR_toggle_switch_position[37] > 0.95
            and power == 1
        then
            switch_value = 0.25
        else
            switch_value = 0.0
        end
    else
        if simDR_percent_lights_on > 0.25
            and power == 1 and ((simDR_aircraft_altitude > 10000.0) or simDR_aircraft_groundspeed<15)
        then
            switch_value = 0.25
        elseif simDR_percent_lights_on > 0.25
        and power == 1 and ((simDR_aircraft_altitude < 10000.0) and simDR_aircraft_groundspeed>15)
            then 
            switch_value = 0.001      
        else
            switch_value = 0.0
        end
    end
    simDR_generic_brightness_switch[25] = switch_value
    

end

--silvereagle added/modified to end
----- SPILL LIGHTS ----------------------------------------------------------------------
function B747_spill_lights()
    local lightMod=0.5
    if simDR_version>=120012 then
        lightMod=simDR_sim_brightness_ratio
    end

	if B747DR_fmc_spill_lights == 1 then
		-- HERE FOR FMC "SIM CONFIG" PAGE "<SPILL LIGHTS HI" (BRIGHT DAY), STORM SWITCH HAS NO EFFECT

		-- USE THE GENERIC LIGHT INDEX [63] AS A "POWER" VALUE FOR THE SPILL LIGHTS
		
		-- TODO:  ADD BUS POWER LOGIC ?

		local storm_light_brt_level = 16.0 * lightMod 
		local storm_light_level = storm_light_brt_level * simDR_generic_brightness_ratio[63]

		-- SET THE SPILL LIGHT LEVELS
		B747DR_spill_light_capt_panel_flood[3]      = storm_light_level * 3
		B747DR_spill_light_center_panel_flood[3]    = storm_light_level * 3
		B747DR_spill_light_capt_map[3]              = B747DR_map_light_rheo_capt * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_capt_chart[3]            = B747DR_chart_light_rheo_capt * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_fo_panel_flood[3]        = storm_light_level * 3
		B747DR_spill_light_fo_map[3]                = B747DR_map_light_rheo_fo * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_fo_chart[3]              = B747DR_chart_light_rheo_fo * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_observer_map[3]          = B747DR_map_light_rheo_observer * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_mcp_flood[3]             = storm_light_level
		B747DR_spill_light_aisle_stand_flood[3]     = storm_light_level * 3

		--SET THE OVERHEAD FLOOD BRIGHTNESS LEVEL
		simDR_panel_brightness_switch[0]            = storm_light_level

		-- SET THE MAG COMPASS SPILL LIGHT LEVEL
		B747DR_spill_light_mag_compass_flood[3]     = simDR_panel_brightness_ratio[3] * lightMod *2
	
	elseif B747DR_fmc_spill_lights == 0 then
		-- HERE FOR "SIM CONFIG" PAGE "<SPILL LIGHTS NORM" (NOT BRIGHT DAY), STORM SWITCH HAS EFFECT

		-- USE THE GENERIC LIGHT INDEX [63] AS A "POWER" VALUE FOR THE SPILL LIGHTS

		-- TODO:  ADD BUS POWER LOGIC ?

		-- BRIGHTNESS LEVEL FOR STORM LIGHTS
		local storm_light_brt_level = 1.9 * lightMod 
        local lightLevel = simDR_generic_brightness_ratio[63] * lightMod *2
		local storm_light_level = storm_light_brt_level * simDR_generic_brightness_ratio[63]

		-- SET THE SPILL LIGHT LEVELS
		B747DR_spill_light_capt_panel_flood[3]      = B747_ternary((B747DR_toggle_switch_position[0] <= 0.05), storm_light_level, (B747DR_flood_light_rheo_capt_panel * lightLevel))
		B747DR_spill_light_center_panel_flood[3]    = B747_ternary((B747DR_toggle_switch_position[0] <= 0.05), storm_light_level, (B747DR_flood_light_rheo_capt_panel * lightLevel))
		B747DR_spill_light_capt_map[3]              = B747DR_map_light_rheo_capt * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_capt_chart[3]            = B747DR_chart_light_rheo_capt * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_fo_panel_flood[3]        = B747_ternary((B747DR_toggle_switch_position[0] <= 0.05), storm_light_level, (B747DR_flood_light_rheo_fo_panel * lightLevel))
		B747DR_spill_light_fo_map[3]                = B747DR_map_light_rheo_fo * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_fo_chart[3]              = B747DR_chart_light_rheo_fo * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_observer_map[3]          = B747DR_map_light_rheo_observer * simDR_generic_brightness_ratio[63]
		B747DR_spill_light_mcp_flood[3]             = B747_ternary((B747DR_toggle_switch_position[0] <= 0.05), storm_light_level, (B747DR_flood_light_rheo_mcp * lightLevel))
		B747DR_spill_light_aisle_stand_flood[3]     = B747_ternary((B747DR_toggle_switch_position[0] <= 0.05), storm_light_level, (B747DR_flood_light_rheo_aisle_stand * lightLevel))

		--SET THE OVERHEAD FLOOD BRIGHTNESS LEVEL
		simDR_panel_brightness_switch[0]            = B747_ternary((B747DR_toggle_switch_position[0] <= 0.05), storm_light_level, B747DR_flood_light_rheo_overhead)
        simDR_panel_brightness_switch[0]            = simDR_panel_brightness_switch[0]
        simDR_panel_brightness_switch[1]            = simDR_panel_brightness_switch[1]
        simDR_panel_brightness_switch[2]            = simDR_panel_brightness_switch[2]
        simDR_panel_brightness_switch[3]            = simDR_panel_brightness_switch[3]
		-- SET THE MAG COMPASS SPILL LIGHT LEVEL
		B747DR_spill_light_mag_compass_flood[3]     = simDR_panel_brightness_ratio[3] * lightLevel

	end
end
--silvereagle end

----- ANNUNCIATORS ----------------------------------------------------------------------
function B747_annunciators()

    -- BUTTON SWITCHES --------------------------------------------------------

    ------ GLARESHIELD -----

    -- MASTER CAUTION
    annun.b.master_caution = B747DR_master_caution

    -- MASTER WARNING
    annun.b.master_warning = B747DR_master_warning



    ----- MAIN PANEL -----

    -- GROUND PROXIMITY         simDR_annun_GPWS

    annun.b.gpws =  0 -- B747_ternary((B747DR_GPWS GS INHIBIT) and (simDR_annun_GPWS == 1), 1, 0)         --  TODO:: create GPWS dataref for monitoring of button press to inhibit

    -- GLIDESLOPE INHIBIT
    annun.b.gs_inhibit = 0          -- TODO:  NEED DR  (see above)



    ----- OVERHEAD PANEL -----

    -- ELECTRONIC ENGING CONTROL
    annun.b.el_eng_ctrl_01 = B747_ternary((B747DR_button_switch_position[7] < 0.5), 1, 0)
    annun.b.el_eng_ctrl_02 = B747_ternary((B747DR_button_switch_position[8] < 0.5), 1, 0)
    annun.b.el_eng_ctrl_03 = B747_ternary((B747DR_button_switch_position[9] < 0.5), 1, 0)
    annun.b.el_eng_ctrl_04 = B747_ternary((B747DR_button_switch_position[10] < 0.5), 1, 0)

    -- ELECTRIC UTILITY POWER
    annun.b.util_power_L = B747_ternary((B747DR_button_switch_position[11] < 0.5), 1, 0)
    annun.b.util_power_R = B747_ternary((B747DR_button_switch_position[12] < 0.5), 1, 0)

    -- BATTERY
    annun.b.battery_off = B747_ternary((B747DR_button_switch_position[13] < 0.5), 1, 0)

    -- EXTERNAL POWER
    annun.b.ext_pwr_avail_01 = B747_ternary(((B747DR_elec_ext_pwr1_available == 1) and B747DR_elec_ext_pwr_1_switch_mode == 0), 1, 0)
    annun.b.ext_pwr_avail_02 = B747_ternary(((B747DR_elec_ext_pwr2_available == 1) and (B747DR_elec_ext_pwr_2_switch_mode == 0)), 1, 0)
    B747DR_elec_ext_pwr1_on= B747_ternary((B747DR_elec_ext_pwr1_available == 1) and (B747DR_elec_ext_pwr_1_switch_mode == 1), 1, 0)
    B747DR_elec_ext_pwr2_on= B747_ternary((B747DR_elec_ext_pwr2_available == 1) and (B747DR_elec_ext_pwr_2_switch_mode == 1), 1, 0)

    -- APU GENERATOR
    annun.b.apu_gen_avail_01 = B747_ternary(((B747DR_elec_apu_pwr1_available ==1 and B747DR_elec_apu_pwr_1_switch_mode == 0)
        and (simDR_aircraft_on_ground == 1)
        and (simDR_apu_running == 1)
        and (simDR_apu_N1_pct > 95.0)),
        1, 0)
    annun.b.apu_gen_avail_02 = B747_ternary(((B747DR_elec_apu_pwr2_available ==1 and B747DR_elec_apu_pwr_2_switch_mode == 0)
        and (simDR_aircraft_on_ground == 1)
        and (simDR_apu_running == 1)
        and (simDR_apu_N1_pct > 95.0)),
        1, 0)
    B747DR_elec_apu_pwr1_on = B747_ternary(((simDR_apu_gen_on == 1) and B747DR_elec_apu_pwr_1_switch_mode == 1), 1, 0)
    B747DR_elec_apu_pwr2_on = B747_ternary(((simDR_apu_gen_on == 1) and B747DR_elec_apu_pwr_2_switch_mode == 1), 1, 0)

    -- BUS TIE
    annun.b.bus_tie_01 = B747_ternary(((simDR_cross_tie == 0) or B747DR_button_switch_position[18]==0), 1, 0)
    annun.b.bus_tie_02 = B747_ternary(((simDR_cross_tie == 0) or B747DR_button_switch_position[19]==0), 1, 0)
    annun.b.bus_tie_03 = B747_ternary(((simDR_cross_tie == 0) or B747DR_button_switch_position[20]==0), 1, 0)
    annun.b.bus_tie_04 = B747_ternary(((simDR_cross_tie == 0) or B747DR_button_switch_position[21]==0), 1, 0)

    -- GENERATOR CONTROL
    annun.b.gen_ctrl_off_01 = B747_ternary((simDR_annun_generator_off[0] == 1), 1, 0)
    annun.b.gen_ctrl_off_02 = B747_ternary((simDR_annun_generator_off[1] == 1), 1, 0)
    annun.b.gen_ctrl_off_03 = B747_ternary((simDR_annun_generator_off[2] == 1), 1, 0)
    annun.b.gen_ctrl_off_04 = B747_ternary((simDR_annun_generator_off[3] == 1), 1, 0)

    -- GENERATOR DRIVE DISC
    annun.b.gen_drive_disc_01 = B747_ternary(((simDR_generator_fail_01 == 6) or (simDR_annun_generator_off[0] == 1)), 1, 0)
    annun.b.gen_drive_disc_02 = B747_ternary(((simDR_generator_fail_02 == 6) or (simDR_annun_generator_off[1] == 1)), 1, 0)
    annun.b.gen_drive_disc_03 = B747_ternary(((simDR_generator_fail_03 == 6) or (simDR_annun_generator_off[2] == 1)), 1, 0)
    annun.b.gen_drive_disc_04 = B747_ternary(((simDR_generator_fail_04 == 6) or (simDR_annun_generator_off[3] == 1)), 1, 0)

    -- HYDRAULIC PUMP
    annun.b.hyd_pump_01 = B747_ternary((simDR_engine_running[0] == 0) or (simDR_hyd_pump_fail_eng_01 == 6), 1, 0)
    annun.b.hyd_pump_02 = B747_ternary((simDR_engine_running[1] == 0) or (simDR_hyd_pump_fail_eng_02 == 6), 1, 0)
    annun.b.hyd_pump_03 = B747_ternary((simDR_engine_running[2] == 0) or (simDR_hyd_pump_fail_eng_03 == 6), 1, 0)
    annun.b.hyd_pump_04 = B747_ternary((simDR_engine_running[3] == 0) or (simDR_hyd_pump_fail_eng_04 == 6), 1, 0)

    -- CARGO FIRE
    annun.b.cargo_fire_fwd = 0
    annun.b.cargo_fire_aft = 0
    annun.b.cargo_fire_disch = 0

    -- FUEL JETTISON NOZZLE VALVE
    annun.b.fuel_jett_valve_L = 0
    annun.b.fuel_jett_valve_R = 0

    -- FUEL SYSTEM
    annun.b.fuel_xfeed_01 = B747_ternary((B747DR_fuel_engine1_xfeed_vlv_pos ~= B747DR_button_switch_position[48]), 1, 0)
    annun.b.fuel_xfeed_02 = 0
    annun.b.fuel_xfeed_03 = 0
    annun.b.fuel_xfeed_04 = B747_ternary((B747DR_fuel_engine4_xfeed_vlv_pos ~= B747DR_button_switch_position[51]), 1, 0)

    
    if B747DR_button_switch_position[52] > 0.95
        and B747_fuel_center_tank_ovrd_jett_pump_L_on > 0 and simDR_fuel_tank_weight_kg[0] <= 900.0
    then
        annun.b.fuel_pump_center_L = 1
    else
        annun.b.fuel_pump_center_L = 0
    end

    
    if B747DR_button_switch_position[53] > 0.95
        and B747_fuel_center_tank_ovrd_jett_pump_R_on > 0 and simDR_fuel_tank_weight_kg[0] <= 900.0
    then
        annun.b.fuel_pump_center_R = 1
    else
        annun.b.fuel_pump_center_R = 0
    end

    
    if B747_fuel_stab_tank_xfr_jett_pump_L_on > 0 and simDR_fuel_tank_weight_kg[7] <= 10.0 then
        annun.b.fuel_pump_stab_L = 1
    else
        annun.b.fuel_pump_stab_L = 0
    end

    
    if B747_fuel_stab_tank_xfr_jett_pump_R_on > 0 and simDR_fuel_tank_weight_kg[7] <= 10.0 then
        annun.b.fuel_pump_stab_R = 1
    else
        annun.b.fuel_pump_stab_R = 0
    end

    
    if (B747_fuel_main1_tank_main_pump_fwd_on == 0 and simDR_engine_running[0] == 0)
        or (B747_fuel_main1_tank_main_pump_fwd_on > 0 and simDR_fuel_tank_weight_kg[1] <= 10.0)
    then
        annun.b.fuel_pump_main_fwd_01 = 1
    else
        annun.b.fuel_pump_main_fwd_01 = 0
    end

    
    if (B747_fuel_main2_tank_main_pump_fwd_on == 0 and simDR_engine_running[1] == 0)
        or (B747_fuel_main2_tank_main_pump_fwd_on > 0 and simDR_fuel_tank_weight_kg[2] <= 10.0)
    then
        annun.b.fuel_pump_main_fwd_02 = 1
    else
        annun.b.fuel_pump_main_fwd_02 = 0
    end

    
    if (B747_fuel_main3_tank_main_pump_fwd_on == 0 and simDR_engine_running[2] == 0)
        or (B747_fuel_main3_tank_main_pump_fwd_on > 0 and simDR_fuel_tank_weight_kg[3] <= 10.0)
    then
        annun.b.fuel_pump_main_fwd_03 = 1
    else
        annun.b.fuel_pump_main_fwd_03 = 0
    end

    
    if (B747_fuel_main4_tank_main_pump_fwd_on == 0 and simDR_engine_running[3] == 0)
        or (B747_fuel_main4_tank_main_pump_fwd_on > 0 and simDR_fuel_tank_weight_kg[4] <= 10.0)
    then
        annun.b.fuel_pump_main_fwd_04 = 1
    else
        annun.b.fuel_pump_main_fwd_04 = 0
    end

    
    if (B747_fuel_main1_tank_main_pump_aft_on == 0 and simDR_engine_running[0] == 0)
        or (B747_fuel_main1_tank_main_pump_aft_on > 0 and simDR_fuel_tank_weight_kg[1] <= 10.0)
    then
        annun.b.fuel_pump_main_aft_01 = 1
    else
        annun.b.fuel_pump_main_aft_01 = 0
    end

    
    if (B747_fuel_main2_tank_main_pump_aft_on == 0 and simDR_engine_running[1] == 0)
        or (B747_fuel_main2_tank_main_pump_aft_on > 0 and simDR_fuel_tank_weight_kg[2] <= 10.0)
    then
        annun.b.fuel_pump_main_aft_02 = 1
    else
        annun.b.fuel_pump_main_aft_02 = 0
    end

    
    if (B747_fuel_main3_tank_main_pump_aft_on == 0 and simDR_engine_running[2] == 0)
        or (B747_fuel_main3_tank_main_pump_aft_on > 0 and simDR_fuel_tank_weight_kg[3] <= 10.0)
    then
        annun.b.fuel_pump_main_aft_03 = 1
    else
        annun.b.fuel_pump_main_aft_03 = 0
    end

    
    if (B747_fuel_main4_tank_main_pump_aft_on == 0 and simDR_engine_running[3] == 0)
        or (B747_fuel_main4_tank_main_pump_aft_on > 0 and simDR_fuel_tank_weight_kg[4] <= 10.0)
    then
        annun.b.fuel_pump_main_aft_04 = 1
    else
        annun.b.fuel_pump_main_aft_04 = 0
    end

    
    if B747_fuel_main2_tank_ovrd_jett_pump_fwd_on > 0 and simDR_fuel_tank_weight_kg[2] <= 3200.0 then
        annun.b.fuel_pump_main_ovrd_fwd_02 = 1
    else
        annun.b.fuel_pump_main_ovrd_fwd_02 = 0
    end
    
    
    if B747_fuel_main3_tank_ovrd_jett_pump_fwd_on > 0 and simDR_fuel_tank_weight_kg[3] <= 3200.0 then
        annun.b.fuel_pump_main_ovrd_fwd_03 = 1
    else
        annun.b.fuel_pump_main_ovrd_fwd_03 = 0
    end

   
    if B747_fuel_main2_tank_ovrd_jett_pump_aft_on > 0 and simDR_fuel_tank_weight_kg[2] <= 3200.0 then
        annun.b.fuel_pump_main_ovrd_aft_02 = 1
    else
        annun.b.fuel_pump_main_ovrd_aft_02 = 0
    end

    
    if B747_fuel_main3_tank_ovrd_jett_pump_aft_on > 0 and simDR_fuel_tank_weight_kg[3] <= 3200.0 then
        annun.b.fuel_pump_main_ovrd_aft_03 = 1
    else
        annun.b.fuel_pump_main_ovrd_aft_03 = 0
    end

    -- ANTI-ICE
    
    if (B747DR_button_switch_position[68] > 0.95) and (B747DR_nacelle_ai_valve_pos[0] < 1.0)
        or (B747DR_button_switch_position[68]< 0.05) and (B747DR_nacelle_ai_valve_pos[0] > 0.0)
    then
        annun.b.anti_ice_nacelle_heat_01 = 1
    else
        annun.b.anti_ice_nacelle_heat_01 = 0
    end

    
    if (B747DR_button_switch_position[69] > 0.95) and (B747DR_nacelle_ai_valve_pos[1] < 1.0)
        or (B747DR_button_switch_position[69]< 0.05) and (B747DR_nacelle_ai_valve_pos[1] > 0.0)
    then
        annun.b.anti_ice_nacelle_heat_02 = 1
    else
        annun.b.anti_ice_nacelle_heat_02 = 0
    end

    
    if (B747DR_button_switch_position[70] > 0.95) and (B747DR_nacelle_ai_valve_pos[2] < 1.0)
        or (B747DR_button_switch_position[70]< 0.05) and (B747DR_nacelle_ai_valve_pos[2] > 0.0)
    then
        annun.b.anti_ice_nacelle_heat_03 = 1
    else
        annun.b.anti_ice_nacelle_heat_03 = 0
    end

    
    if (B747DR_button_switch_position[71] > 0.95) and (B747DR_nacelle_ai_valve_pos[3] < 1.0)
        or (B747DR_button_switch_position[71]< 0.05) and (B747DR_nacelle_ai_valve_pos[3] > 0.0)
    then
        annun.b.anti_ice_nacelle_heat_04 = 1
    else
        annun.b.anti_ice_nacelle_heat_04 = 0
    end

    
    if (B747DR_button_switch_position[72] > 0.95
        and
        (B747DR_wing_ai_valve_pos[0] < 1.0 or B747DR_wing_ai_valve_pos[1] < 1.0))
        or
        (B747DR_button_switch_position[72] < 0.05
        and
        (B747DR_wing_ai_valve_pos[0] > 0.0 or B747DR_wing_ai_valve_pos[1] > 0.0))
    then
        annun.b.anti_ice_wing_heat = 1
    else
        annun.b.anti_ice_wing_heat = 0
    end

    annun.b.anti_ice_window_heat_L = B747_ternary(((B747DR_button_switch_position[73] > 0.95) and (simDR_window_heat_fail == 6)), 1, 0)
    annun.b.anti_ice_window_heat_R = B747_ternary(((B747DR_button_switch_position[74] > 0.95) and (simDR_window_heat_fail == 6)), 1, 0)

    -- YAW DAMPER
    annun.b.yaw_damper_upper = B747_ternary((B747DR_yaw_damper_upr_on == 0), 1, 0)
    annun.b.yaw_damper_lower = B747_ternary((B747DR_yaw_damper_lwr_on == 0), 1, 0)

    -- TEMPERATURE
    annun.b.temp_zone_reset = B747_ternary((B747DR_button_switch_position[37] < 0.05), 1, 0)
    annun.b.temp_aft_cargo_heat = 0
    annun.b.temp_pack_reset = 0

    -- BLEED AIR
    annun.b.bleed_air_isolation_L = 0.0
    if (B747DR_button_switch_position[75] > 0.95 and B747DR_bleed_air_iso_vlv_L_pos < 1.0)
        or (B747DR_button_switch_position[75] < 0.01 and B747DR_bleed_air_iso_vlv_L_pos > 0.0)
    then
        annun.b.bleed_air_isolation_L = 1.0
    end

    annun.b.bleed_air_isolation_R = 0.0
    if (B747DR_button_switch_position[76] > 0.95 and B747DR_bleed_air_iso_vlv_R_pos < 1.0)
        or (B747DR_button_switch_position[76] < 0.01 and B747DR_bleed_air_iso_vlv_R_pos > 0.0)
    then
        annun.b.bleed_air_isolation_R = 1.0
    end

    annun.b.apu_bleed_air = 0.0
    if simDR_apu_running==1 and ((B747DR_button_switch_position[81] > 0.95 and B747DR_bleed_air_apu_vlv_pos < 1.0)
        or (B747DR_button_switch_position[81] < 0.01 and B747DR_bleed_air_apu_vlv_pos > 0.0))
    then
        annun.b.apu_bleed_air = 1.0
    end

    annun.b.engine_bleed_air_01 = B747_ternary((B747DR_bleed_air_engine1_vlv_pos == 0.0), 1, 0)
    annun.b.engine_bleed_air_02 = B747_ternary((B747DR_bleed_air_engine2_vlv_pos == 0.0), 1, 0)
    annun.b.engine_bleed_air_03 = B747_ternary((B747DR_bleed_air_engine3_vlv_pos == 0.0), 1, 0)
    annun.b.engine_bleed_air_04 = B747_ternary((B747DR_bleed_air_engine4_vlv_pos == 0.0), 1, 0)








    -- FIXED  ----------------------------------------------------------------------

    ----- MAIN PANEL -----

    -- BRAKE SOURCE LOW PRESS           simDR_hyd_press_01
    annun.a.brake_source = B747_ternary(((simDR_hyd_press_01 < 1000.0) and (simDR_hyd_press_02 < 1000.0)and (simDR_hyd_press_04 < 1000.0)), 1, 0)


    ----- OVERHEAD PANEL -----

    -- FLIGHT CONTROL HYDRAULIC POWER VALVES
    annun.a.flt_ctl_hyd_vlv_wing_01 = 0
    annun.a.flt_ctl_hyd_vlv_wing_02 = 0
    annun.a.flt_ctl_hyd_vlv_wing_03 = 0
    annun.a.flt_ctl_hyd_vlv_wing_04 = 0
    annun.a.flt_ctl_hyd_vlv_tail_01 = 0
    annun.a.flt_ctl_hyd_vlv_tail_02 = 0
    annun.a.flt_ctl_hyd_vlv_tail_03 = 0
    annun.a.flt_ctl_hyd_vlv_tail_04 = 0

    -- GEN FIELD
    annun.a.eng_gen_field_01 = 0
    annun.a.eng_gen_field_02 = 0
    annun.a.eng_gen_field_03 = 0
    annun.a.eng_gen_field_04 = 0
    annun.a.apu_gen_field_01 = 0
    annun.a.apu_gen_field_02 = 0
    annun.a.split_sys_breaker = 0

    -- SQUIB TEST
    annun.a.squib_test_eng_01 = 0
    annun.a.squib_test_eng_02 = 0
    annun.a.squib_test_eng_03 = 0
    annun.a.squib_test_eng_04 = 0
    annun.a.squib_test_apu = 0
    annun.a.squib_test_cargo_A = 0
    annun.a.squib_test_cargo_B = 0
    annun.a.squib_test_cargo_C = 0
    annun.a.squib_test_cargo_D = 0

    -- IRS
    annun.a.irs_on_bat = 0

    -- HYDRAULIC SYSTEM FAULT
    annun.a.hyd_sys_fault_01 = B747_ternary((simDR_hyd_press_01 < 1000.0) or (simDR_hyd_fluid_level_01 < 0.1), 1, 0)
    annun.a.hyd_sys_fault_02 = B747_ternary((simDR_hyd_press_02 < 1000.0) or (simDR_hyd_fluid_level_02 < 0.1), 1, 0)
    annun.a.hyd_sys_fault_03 = B747_ternary((simDR_hyd_press_03 < 1000.0) or (simDR_hyd_fluid_level_03 < 0.1), 1, 0)
    annun.a.hyd_sys_fault_04 = B747_ternary((simDR_hyd_press_04 < 1000.0) or (simDR_hyd_fluid_level_04 < 0.1), 1, 0)

    -- HYDRAULIC DEMAND PUMP PRESS LOW              -- TODO:  ADD CONDITIONS:  DEMAND PUMP PRESS LOW / DEMAND PUMP FAIL
    annun.a.demand_pump_press_01 = B747_ternary((B747DR_hyd_dmd_pmp_sel_pos[0] == 0), 1, 0)
    annun.a.demand_pump_press_02 = B747_ternary((B747DR_hyd_dmd_pmp_sel_pos[1] == 0), 1, 0)
    annun.a.demand_pump_press_03 = B747_ternary((B747DR_hyd_dmd_pmp_sel_pos[2] == 0), 1, 0)
    annun.a.demand_pump_press_04 = B747_ternary((B747DR_hyd_dmd_pmp_sel_pos[3] == 0), 1, 0)

    -- FIRE EXTINGUISHER BOTTLE DISCHARGE
    annun.a.fire_bottle_0102A_disch = B747_ternary((B747DR_fire_ext_bottle_0102A_psi < 225.0), 1, 0)
    annun.a.fire_bottle_0102B_disch = B747_ternary((B747DR_fire_ext_bottle_0102B_psi < 225.0), 1, 0)
    annun.a.fire_bottle_0304A_disch = B747_ternary((B747DR_fire_ext_bottle_0304A_psi < 225.0), 1, 0)
    annun.a.fire_bottle_0304B_disch = B747_ternary((B747DR_fire_ext_bottle_0304B_psi < 225.0), 1, 0)
    annun.a.fire_bottle_APU_disch = 0

    -- ENGINE BLEED AIR SYS FAULT
    annun.a.eng_bleed_air_sys_fault_01 = B747_ternary((simDR_engine_bleed_air_fail[0] == 1), 1, 0)
    annun.a.eng_bleed_air_sys_fault_02 = B747_ternary((simDR_engine_bleed_air_fail[1] == 1), 1, 0)
    annun.a.eng_bleed_air_sys_fault_03 = B747_ternary((simDR_engine_bleed_air_fail[2] == 1), 1, 0)
    annun.a.eng_bleed_air_sys_fault_04 = B747_ternary((simDR_engine_bleed_air_fail[3] == 1), 1, 0)

    -- START SWITCHES
    annun.a.start_vlv_open_01 = B747DR_bleed_air_engine1_start_valve_pos
    annun.a.start_vlv_open_02 = B747DR_bleed_air_engine2_start_valve_pos
    annun.a.start_vlv_open_03 = B747DR_bleed_air_engine3_start_valve_pos
    annun.a.start_vlv_open_04 = B747DR_bleed_air_engine4_start_valve_pos



    ----- PEDESTAL ----
    
    -- RADIO TUNING PANELS
    annun.a.rtp_L_offside_tuning = B747DR_rtp_L_offside_tuning_status
    annun.a.rtp_L_off = B747DR_rtp_L_off_status
    annun.a.rtp_L_vhf_L = B747DR_rtp_L_vhf_L_status
    annun.a.rtp_L_vhf_C = B747DR_rtp_L_vhf_C_status
    annun.a.rtp_L_vhf_R = B747DR_rtp_L_vhf_R_status
    annun.a.rtp_L_hf_L = B747DR_rtp_L_hf_L_status
    annun.a.rtp_L_am = B747DR_rtp_L_am_status
    annun.a.rtp_L_hf_R = B747DR_rtp_L_hf_R_status

    annun.a.rtp_R_offside_tuning = B747DR_rtp_R_offside_tuning_status
    annun.a.rtp_R_off = B747DR_rtp_R_off_status
    annun.a.rtp_R_vhf_L = B747DR_rtp_R_vhf_L_status
    annun.a.rtp_R_vhf_C = B747DR_rtp_R_vhf_C_status
    annun.a.rtp_R_vhf_R = B747DR_rtp_R_vhf_R_status
    annun.a.rtp_R_hf_L = B747DR_rtp_R_hf_L_status
    annun.a.rtp_R_am = B747DR_rtp_R_am_status
    annun.a.rtp_R_hf_R = B747DR_rtp_R_hf_R_status

    annun.a.rtp_C_offside_tuning = B747DR_rtp_C_offside_tuning_status
    annun.a.rtp_C_off = B747DR_rtp_C_off_status
    annun.a.rtp_C_vhf_L = B747DR_rtp_C_vhf_L_status
    annun.a.rtp_C_vhf_C = B747DR_rtp_C_vhf_C_status
    annun.a.rtp_C_vhf_R = B747DR_rtp_C_vhf_R_status
    annun.a.rtp_C_hf_L = B747DR_rtp_C_hf_L_status
    annun.a.rtp_C_am = B747DR_rtp_C_am_status
    annun.a.rtp_C_hf_R = B747DR_rtp_C_hf_R_status


    -- AUDIO PANEL L
    annun.a.ap_L_vhf_L_xmt = B747DR_ap_L_vhf_L_xmt_status
    annun.a.ap_L_vhf_C_xmt = B747DR_ap_L_vhf_C_xmt_status
    annun.a.ap_L_vhf_R_xmt = B747DR_ap_L_vhf_R_xmt_status
    annun.a.ap_L_flt_xmt = B747DR_ap_L_flt_xmt_status
    annun.a.ap_L_cab_xmt = B747DR_ap_L_cab_xmt_status
    annun.a.ap_L_pa_xmt = B747DR_ap_L_pa_xmt_status
    annun.a.ap_L_hf_L_xmt = B747DR_ap_L_hf_L_xmt_status
    annun.a.ap_L_hf_R_xmt = B747DR_ap_L_hf_R_xmt_status
    annun.a.ap_L_sat_L_xmt = B747DR_ap_L_sat_L_xmt_status
    annun.a.ap_L_sat_R_xmt = B747DR_ap_L_sat_R_xmt_status

    annun.a.ap_L_vhf_L_audio = B747DR_ap_L_vhf_L_audio_status
    annun.a.ap_L_vhf_C_audio = B747DR_ap_L_vhf_C_audio_status
    annun.a.ap_L_vhf_R_audio = B747DR_ap_L_vhf_R_audio_status
    annun.a.ap_L_flt_audio = B747DR_ap_L_flt_audio_status
    annun.a.ap_L_cab_audio = B747DR_ap_L_cab_audio_status
    annun.a.ap_L_pa_audio = B747DR_ap_L_pa_audio_status
    annun.a.ap_L_hf_L_audio = B747DR_ap_L_hf_L_audio_status
    annun.a.ap_L_hf_R_audio = B747DR_ap_L_hf_R_audio_status
    annun.a.ap_L_sat_L_audio = B747DR_ap_L_sat_L_audio_status
    annun.a.ap_L_sat_R_audio = B747DR_ap_L_sat_R_udio_status
    annun.a.ap_L_spkr_audio = B747DR_ap_L_spkr_audio_status
    annun.a.ap_L_vor_adf_audio = B747DR_ap_L_vor_adf_audio_status
    annun.a.ap_L_app_mkr_audio = B747DR_ap_L_app_mkr_audio_status

    annun.a.ap_L_vhf_L_call = B747DR_ap_L_vhf_L_call_status
    annun.a.ap_L_vhf_C_call = B747DR_ap_L_vhf_C_call_status
    annun.a.ap_L_vhf_R_call = B747DR_ap_L_vhf_R_call_status
    annun.a.ap_L_flt_call = B747DR_ap_L_flt_call_status
    annun.a.ap_L_cab_call = B747DR_ap_L_cab_call_status
    annun.a.ap_L_hf_L_call = B747DR_ap_L_hf_L_call_status
    annun.a.ap_L_hf_R_call = B747DR_ap_L_hf_R_call_status
    annun.a.ap_L_sat_L_call = B747DR_ap_L_sat_L_call_status
    annun.a.ap_L_sat_R_call = B747DR_ap_L_sat_R_call_status


    -- AUDIO PANEL C
    annun.a.ap_C_vhf_L_xmt = B747DR_ap_C_vhf_L_xmt_status
    annun.a.ap_C_vhf_C_xmt = B747DR_ap_C_vhf_C_xmt_status
    annun.a.ap_C_vhf_R_xmt = B747DR_ap_C_vhf_R_xmt_status
    annun.a.ap_C_flt_xmt = B747DR_ap_C_flt_xmt_status
    annun.a.ap_C_cab_xmt = B747DR_ap_C_cab_xmt_status
    annun.a.ap_C_pa_xmt = B747DR_ap_C_pa_xmt_status
    annun.a.ap_C_hf_L_xmt = B747DR_ap_C_hf_L_xmt_status
    annun.a.ap_C_hf_R_xmt = B747DR_ap_C_hf_R_xmt_status
    annun.a.ap_C_sat_L_xmt = B747DR_ap_C_sat_L_xmt_status
    annun.a.ap_C_sat_R_xmt = B747DR_ap_C_sat_R_xmt_status

    annun.a.ap_C_vhf_L_audio = B747DR_ap_C_vhf_L_audio_status
    annun.a.ap_C_vhf_C_audio = B747DR_ap_C_vhf_C_audio_status
    annun.a.ap_C_vhf_R_audio = B747DR_ap_C_vhf_R_audio_status
    annun.a.ap_C_flt_audio = B747DR_ap_C_flt_audio_status
    annun.a.ap_C_cab_audio = B747DR_ap_C_cab_audio_status
    annun.a.ap_C_pa_audio = B747DR_ap_C_pa_audio_status
    annun.a.ap_C_hf_L_audio = B747DR_ap_C_hf_L_audio_status
    annun.a.ap_C_hf_R_audio = B747DR_ap_C_hf_R_audio_status
    annun.a.ap_C_sat_L_audio = B747DR_ap_C_sat_L_audio_status
    annun.a.ap_C_sat_R_audio = B747DR_ap_C_sat_R_udio_status
    annun.a.ap_C_spkr_audio = B747DR_ap_C_spkr_audio_status
    annun.a.ap_C_vor_adf_audio = B747DR_ap_C_vor_adf_audio_status
    annun.a.ap_C_app_mkr_audio = B747DR_ap_C_app_mkr_audio_status

    annun.a.ap_C_vhf_L_call = B747DR_ap_C_vhf_L_call_status
    annun.a.ap_C_vhf_C_call = B747DR_ap_C_vhf_C_call_status
    annun.a.ap_C_vhf_R_call = B747DR_ap_C_vhf_R_call_status
    annun.a.ap_C_flt_call = B747DR_ap_C_flt_call_status
    annun.a.ap_C_cab_call = B747DR_ap_C_cab_call_status
    annun.a.ap_C_hf_L_call = B747DR_ap_C_hf_L_call_status
    annun.a.ap_C_hf_R_call = B747DR_ap_C_hf_R_call_status
    annun.a.ap_C_sat_L_call = B747DR_ap_C_sat_L_call_status
    annun.a.ap_C_sat_R_call = B747DR_ap_C_sat_R_call_status


    -- AUDIO PANEL R
    annun.a.ap_R_vhf_L_xmt = B747DR_ap_R_vhf_L_xmt_status
    annun.a.ap_R_vhf_C_xmt = B747DR_ap_R_vhf_C_xmt_status
    annun.a.ap_R_vhf_R_xmt = B747DR_ap_R_vhf_R_xmt_status
    annun.a.ap_R_flt_xmt = B747DR_ap_R_flt_xmt_status
    annun.a.ap_R_cab_xmt = B747DR_ap_R_cab_xmt_status
    annun.a.ap_R_pa_xmt = B747DR_ap_R_pa_xmt_status
    annun.a.ap_R_hf_L_xmt = B747DR_ap_R_hf_L_xmt_status
    annun.a.ap_R_hf_R_xmt = B747DR_ap_R_hf_R_xmt_status
    annun.a.ap_R_sat_L_xmt = B747DR_ap_R_sat_L_xmt_status
    annun.a.ap_R_sat_R_xmt = B747DR_ap_R_sat_R_xmt_status

    annun.a.ap_R_vhf_L_audio = B747DR_ap_R_vhf_L_audio_status
    annun.a.ap_R_vhf_C_audio = B747DR_ap_R_vhf_C_audio_status
    annun.a.ap_R_vhf_R_audio = B747DR_ap_R_vhf_R_audio_status
    annun.a.ap_R_flt_audio = B747DR_ap_R_flt_audio_status
    annun.a.ap_R_cab_audio = B747DR_ap_R_cab_audio_status
    annun.a.ap_R_pa_audio = B747DR_ap_R_pa_audio_status
    annun.a.ap_R_hf_L_audio = B747DR_ap_R_hf_L_audio_status
    annun.a.ap_R_hf_R_audio = B747DR_ap_R_hf_R_audio_status
    annun.a.ap_R_sat_L_audio = B747DR_ap_R_sat_L_audio_status
    annun.a.ap_R_sat_R_audio = B747DR_ap_R_sat_R_udio_status
    annun.a.ap_R_spkr_audio = B747DR_ap_R_spkr_audio_status
    annun.a.ap_R_vor_adf_audio = B747DR_ap_R_vor_adf_audio_status
    annun.a.ap_R_app_mkr_audio = B747DR_ap_R_app_mkr_audio_status

    annun.a.ap_R_vhf_L_call = B747DR_ap_R_vhf_L_call_status
    annun.a.ap_R_vhf_C_call = B747DR_ap_R_vhf_C_call_status
    annun.a.ap_R_vhf_R_call = B747DR_ap_R_vhf_R_call_status
    annun.a.ap_R_flt_call = B747DR_ap_R_flt_call_status
    annun.a.ap_R_cab_call = B747DR_ap_R_cab_call_status
    annun.a.ap_R_hf_L_call = B747DR_ap_R_hf_L_call_status
    annun.a.ap_R_hf_R_call = B747DR_ap_R_hf_R_call_status
    annun.a.ap_R_sat_L_call = B747DR_ap_R_sat_L_call_status
    annun.a.ap_R_sat_R_call = B747DR_ap_R_sat_R_call_status


    -- CALL PANEL
    annun.a.call_pnl_ud_call = B747DR_call_pnl_ud_call_status
    annun.a.call_pnl_crw_rst_L_call = B747DR_call_pnl_crw_rst_L_call_status
    annun.a.call_pnl_crw_rst_R_call = B747DR_call_pnl_crw_rst_R_call_status
    annun.a.call_pnl_cargo_call = B747DR_call_pnl_cargo_call_status
    annun.a.call_pnl_grnd_call = B747DR_call_pnl_grnd_call_status


    -- SAFETY
    annun.a.no_smoking = B747_ternary(
        (
            (B747DR_sfty_no_smoke_sel_dial_pos == 2)            -- "ON" POSITION
            or
        (
       
        (B747DR_sfty_no_smoke_sel_dial_pos == 1)            -- "AUTO" POSITION
        )

        and

        (
        (simDR_gear_deploy_ratio[0] > 0) or                 --|
        (simDR_gear_deploy_ratio[1] > 0) or                 --|
        (simDR_gear_deploy_ratio[2] > 0) or                 -- GEAR NOT UP
        (simDR_gear_deploy_ratio[3] > 0) or                 --|
        (simDR_gear_deploy_ratio[4] > 0) or                 --|
        (simDR_cabin_altitude > 10000.0)                    -- CABIN ALTITUDE IS GREATER THAN 10,000 FEET
        )                                                   -- TODO: PASSENGER OXY IS ON

        ), 1, 0)
    simDR_cockpit2_no_smoking_switch  = B747_ternary((annun.a.no_smoking == 1), 1, 0)       -- SET THE SIM ANNUNCIATOR



    annun.a.seat_belts = B747_ternary(
        (
            (B747DR_sfty_seat_belts_sel_dial_pos == 2)          -- "ON" POSITION
            or
        (
        
        (B747DR_sfty_seat_belts_sel_dial_pos == 1)          -- "AUTO" POSITION
        )

        and

        (
        (simDR_gear_deploy_ratio[0] > 0) or                 --|
        (simDR_gear_deploy_ratio[1] > 0) or                 --|
        (simDR_gear_deploy_ratio[2] > 0) or                 -- GEAR NOT UP
        (simDR_gear_deploy_ratio[3] > 0) or                 --|
        (simDR_gear_deploy_ratio[4] > 0) or                 --|
        (simDR_aircraft_altitude < 10300.0) or              -- AIRCRAFT ALTITUDE IS LESS THAN 10,300 FEET
        (simDR_cabin_altitude > 10000.0) or                 -- CABIN ALTITUDE IS GREATER THAN 10,000 FEET
        (simDR_flap_ratio_control > 0)                      -- FLAP LEVER IS NOT UP
        )

        ), 1, 0)
    simDR_cockpit2_seat_belt_switch = B747_ternary((annun.a.seat_belts == 1), 1, 0)         -- SET THE SIM ANNUNCIATOR






    -- MCP AUTOPILOT BUTTON SWITCHES ---------------------------------------------
	--annun.b.ap_thrust 	= B747_ternary(B747DR_engine_TOGA_mode >0 , 1, 0)
    annun.b.ap_thrust 	= B747_ternary(B747DR_ap_FMA_autothrottle_mode==5 and (simDR_autopilot_vs_status == 2 or simDR_autopilot_alt_hold_status == 2) , 1, 0)
    annun.b.ap_speed 	= B747_ternary(B747DR_ap_FMA_autothrottle_mode==3 and B747DR_ap_vnav_state < 1, 1, 0)
    annun.b.ap_lnav 	= B747_ternary(B747DR_ap_lnav_state>0, 1, 0)
    annun.b.ap_vnav 	= B747_ternary(simDR_autopilot_fms_vnav_status > 0 or B747DR_ap_vnav_state>0, 1, 0)
    annun.b.ap_fl_ch 	= B747_ternary(B747DR_ap_FMA_active_pitch_mode == 8 and simDR_autopilot_fms_vnav_status < 1 and B747DR_ap_vnav_state < 1, 1, 0)
    annun.b.ap_hdg_hold	= B747_ternary(simDR_autopilot_heading_hold_status == 2, 1, 0)
    annun.b.ap_vs 		= B747_ternary(simDR_autopilot_vs_status == 2 and simDR_autopilot_fms_vnav_status < 1 and B747DR_ap_vnav_state < 1 and simDR_autopilot_alt_hold_status==0, 1, 0)
    annun.b.ap_alt_hold = B747_ternary(simDR_autopilot_alt_hold_status == 2 and simDR_autopilot_fms_vnav_status < 1 and B747DR_ap_vnav_state < 1, 1, 0)
    annun.b.ap_app 		= B747_ternary((B747DR_autopilot_nav_status > 0 and B747DR_autopilot_gs_status > 0) or B747DR_ap_approach_mode>0, 1, 0)
    annun.b.ap_loc 		= B747_ternary((B747DR_autopilot_nav_status > 0 or B747DR_ap_approach_mode<0) and annun.b.ap_app == 0, 1, 0) --test this
    annun.b.ap_CMD_L 	= B747_ternary(B747DR_autopilot_cmd_L_status == 1 and simDR_autopilot_servos_on == 1, 1, 0)
    annun.b.ap_CMD_C 	= B747_ternary(B747DR_autopilot_cmd_C_status == 1 and simDR_autopilot_servos_on == 1, 1, 0)
    annun.b.ap_CMD_R 	= B747_ternary(B747DR_autopilot_cmd_R_status == 1 and simDR_autopilot_servos_on == 1, 1, 0)
    
    
end





----- ANNUNCIATORS (IND LTS) -----------------------------------------------------
function B747_ind_lights()

    --[[ USE THE GENERIC LIGHT INDEX [63] TO PROVIDE SMOOTH CHANGES OF THE IND LIGHTS BRIGHTNESS (ON/OFF) ]]--

    -- IND LTS SWITCH SETS ANNUNCIATOR BRIGHTNESS LEVEL
    local ind_lts_brt_level = 0.8                           -- BRIGHT
    local bright_dimmer =1.0
    if B747DR_toggle_switch_position[13] < -0.95 then
        ind_lts_brt_level = 0.4 
        bright_dimmer = 0.125                     -- DIM
    elseif B747DR_toggle_switch_position[13] > 0.95 then
        ind_lts_brt_level = 1.0                             -- TEST
    end

    local bus1Power = B747_rescale(0.0, 0.0, 28.0, 1.0, simDR_electrical_bus_volts[0] )
    local bus3Power = B747_rescale(0.0, 0.0, 28.0, 1.0, simDR_electrical_bus_volts[2])
    local busPower  = math.max(bus1Power, bus3Power)
    local brightness_level  = ind_lts_brt_level * simDR_generic_brightness_ratio[63] * busPower
    -- EXTERNAL POWER BRIGHTNESS
    local ext_pwr_avail_brightness_level  = ind_lts_brt_level

    -- APU BUTTON BRIGHTNESS
    local apu_avail_brightness_level  = ind_lts_brt_level
    local apu_on_brightness_level     = ind_lts_brt_level * (simDR_apu_gen_on * 0.8)
    
   


    -- BUTTON SWITCHES ----------------------------------------------------------


    ------ GLARESHIELD -----

    -- MASTER CAUTION
    B747DR_annun_brightness_ratio[0]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level*bright_dimmer, (annun.b.master_caution * brightness_level*bright_dimmer))

    -- MASTER WARNING
    B747DR_annun_brightness_ratio[1]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level*bright_dimmer, (annun.b.master_warning * brightness_level*bright_dimmer))



    ----- MAIN PANEL -----

    -- GROUND PROXIMITY
    B747DR_annun_brightness_ratio[2]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gpws * brightness_level))

    -- GLIDESLOPE INHIBIT
    B747DR_annun_brightness_ratio[3]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gs_inhibit * brightness_level))



    ----- OVERHEAD PANEL -----

    -- ELECTRONIC ENGING CONTROL
    B747DR_annun_brightness_ratio[4]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.el_eng_ctrl_01 * brightness_level))
    B747DR_annun_brightness_ratio[5]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.el_eng_ctrl_02 * brightness_level))
    B747DR_annun_brightness_ratio[6]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.el_eng_ctrl_03 * brightness_level))
    B747DR_annun_brightness_ratio[7]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.el_eng_ctrl_04 * brightness_level))

    -- ELECTRIC UTILITY POWER
    B747DR_annun_brightness_ratio[8]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.util_power_L * brightness_level))
    B747DR_annun_brightness_ratio[9]    = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.util_power_R * brightness_level))

    -- BATTERY
    B747DR_annun_brightness_ratio[10]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.battery_off * brightness_level))

    -- EXTERNAL POWER
    B747DR_annun_brightness_ratio[11]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ext_pwr_avail_01 * ext_pwr_avail_brightness_level))
    B747DR_annun_brightness_ratio[12]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (B747DR_elec_ext_pwr1_on * brightness_level))
    B747DR_annun_brightness_ratio[13]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ext_pwr_avail_02 * ext_pwr_avail_brightness_level))
    B747DR_annun_brightness_ratio[14]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (B747DR_elec_ext_pwr2_on * brightness_level))

    -- APU GENERATOR
    B747DR_annun_brightness_ratio[15]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.apu_gen_avail_01 * apu_avail_brightness_level))
    B747DR_annun_brightness_ratio[16]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (B747DR_elec_apu_pwr1_on * apu_on_brightness_level))
    B747DR_annun_brightness_ratio[17]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.apu_gen_avail_02 * apu_avail_brightness_level))
    B747DR_annun_brightness_ratio[18]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (B747DR_elec_apu_pwr2_on * brightness_level))

    -- BUS TIE
    B747DR_annun_brightness_ratio[19]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.bus_tie_01 * brightness_level))
    B747DR_annun_brightness_ratio[20]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.bus_tie_02 * brightness_level))
    B747DR_annun_brightness_ratio[21]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.bus_tie_03 * brightness_level))
    B747DR_annun_brightness_ratio[22]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.bus_tie_04 * brightness_level))

    -- GENERATOR CONTROL
    B747DR_annun_brightness_ratio[23]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_ctrl_off_01 * brightness_level))
    B747DR_annun_brightness_ratio[24]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_ctrl_off_02 * brightness_level))
    B747DR_annun_brightness_ratio[25]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_ctrl_off_03 * brightness_level))
    B747DR_annun_brightness_ratio[26]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_ctrl_off_04 * brightness_level))

    -- GENERATOR DRIVE DISC
    B747DR_annun_brightness_ratio[27]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_drive_disc_01 * brightness_level))
    B747DR_annun_brightness_ratio[28]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_drive_disc_02 * brightness_level))
    B747DR_annun_brightness_ratio[29]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_drive_disc_03 * brightness_level))
    B747DR_annun_brightness_ratio[30]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.gen_drive_disc_04 * brightness_level))

    -- HYDRAULIC PUMP
    B747DR_annun_brightness_ratio[31]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.hyd_pump_01 * brightness_level))
    B747DR_annun_brightness_ratio[32]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.hyd_pump_02 * brightness_level))
    B747DR_annun_brightness_ratio[33]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.hyd_pump_03 * brightness_level))
    B747DR_annun_brightness_ratio[34]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.hyd_pump_04 * brightness_level))

    -- CARGO FIRE
    B747DR_annun_brightness_ratio[35]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.cargo_fire_fwd * brightness_level))
    B747DR_annun_brightness_ratio[36]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.cargo_fire_aft * brightness_level))
    B747DR_annun_brightness_ratio[37]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.cargo_fire_disch * brightness_level))

    -- FUEL JETTISON VALVE
    B747DR_annun_brightness_ratio[38]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_jett_valve_L * brightness_level))
    B747DR_annun_brightness_ratio[39]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_jett_valve_R * brightness_level))

    -- FUEL SYSTEM
    B747DR_annun_brightness_ratio[40]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_xfeed_01 * brightness_level))
    B747DR_annun_brightness_ratio[41]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_xfeed_02 * brightness_level))
    B747DR_annun_brightness_ratio[42]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_xfeed_03 * brightness_level))
    B747DR_annun_brightness_ratio[43]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_xfeed_04 * brightness_level))
    B747DR_annun_brightness_ratio[44]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_center_L * brightness_level))
    B747DR_annun_brightness_ratio[45]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_center_R * brightness_level))
    B747DR_annun_brightness_ratio[46]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_stab_L * brightness_level))
    B747DR_annun_brightness_ratio[47]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_stab_R * brightness_level))
    B747DR_annun_brightness_ratio[48]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_fwd_01 * brightness_level))
    B747DR_annun_brightness_ratio[49]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_fwd_02 * brightness_level))
    B747DR_annun_brightness_ratio[50]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_fwd_03 * brightness_level))
    B747DR_annun_brightness_ratio[51]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_fwd_04 * brightness_level))
    B747DR_annun_brightness_ratio[52]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_aft_01 * brightness_level))
    B747DR_annun_brightness_ratio[53]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_aft_02 * brightness_level))
    B747DR_annun_brightness_ratio[54]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_aft_03 * brightness_level))
    B747DR_annun_brightness_ratio[55]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_aft_04 * brightness_level))
    B747DR_annun_brightness_ratio[56]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_ovrd_fwd_02 * brightness_level))
    B747DR_annun_brightness_ratio[57]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_ovrd_fwd_03 * brightness_level))
    B747DR_annun_brightness_ratio[58]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_ovrd_aft_02 * brightness_level))
    B747DR_annun_brightness_ratio[59]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.fuel_pump_main_ovrd_aft_03 * brightness_level))

    -- ANTI-ICE
    B747DR_annun_brightness_ratio[60]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_nacelle_heat_01 * brightness_level))
    B747DR_annun_brightness_ratio[61]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_nacelle_heat_02 * brightness_level))
    B747DR_annun_brightness_ratio[62]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_nacelle_heat_03 * brightness_level))
    B747DR_annun_brightness_ratio[63]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_nacelle_heat_04 * brightness_level))
    B747DR_annun_brightness_ratio[64]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_wing_heat * brightness_level))
    B747DR_annun_brightness_ratio[65]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_window_heat_L * brightness_level))
    B747DR_annun_brightness_ratio[66]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.anti_ice_window_heat_R * brightness_level))

    -- YAW DAMPER
    B747DR_annun_brightness_ratio[67]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.yaw_damper_upper * brightness_level))
    B747DR_annun_brightness_ratio[68]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.yaw_damper_lower * brightness_level))

    -- TEMPERATURE
    B747DR_annun_brightness_ratio[69]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.temp_zone_reset * brightness_level))
    B747DR_annun_brightness_ratio[70]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.temp_aft_cargo_heat * brightness_level))
    B747DR_annun_brightness_ratio[71]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.temp_pack_reset * brightness_level))

    -- BLEED AIR
    B747DR_annun_brightness_ratio[72]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.bleed_air_isolation_L * brightness_level))
    B747DR_annun_brightness_ratio[73]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.bleed_air_isolation_R * brightness_level))
    B747DR_annun_brightness_ratio[74]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.apu_bleed_air * brightness_level))
    B747DR_annun_brightness_ratio[75]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.engine_bleed_air_01 * brightness_level))
    B747DR_annun_brightness_ratio[76]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.engine_bleed_air_02 * brightness_level))
    B747DR_annun_brightness_ratio[77]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.engine_bleed_air_03 * brightness_level))
    B747DR_annun_brightness_ratio[78]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.engine_bleed_air_04 * brightness_level))





    -- FIXED  -------------------------------------------------------------------

    ----- MAIN PANEL -----

    -- BRAKE SOURCE LOW PRESS
    B747DR_annun_brightness_ratio[79]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.brake_source * brightness_level))


    ----- OVERHEAD PANEL -----

    -- FLIGHT CONTROL HYDRAULIC VALVES
    B747DR_annun_brightness_ratio[80]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_wing_01 * brightness_level))
    B747DR_annun_brightness_ratio[81]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_wing_02 * brightness_level))
    B747DR_annun_brightness_ratio[82]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_wing_03 * brightness_level))
    B747DR_annun_brightness_ratio[83]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_wing_04 * brightness_level))
    B747DR_annun_brightness_ratio[84]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_tail_01 * brightness_level))
    B747DR_annun_brightness_ratio[85]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_tail_02 * brightness_level))
    B747DR_annun_brightness_ratio[86]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_tail_03 * brightness_level))
    B747DR_annun_brightness_ratio[87]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.flt_ctl_hyd_vlv_tail_04 * brightness_level))

    -- GEN FIELD
    B747DR_annun_brightness_ratio[88]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_gen_field_01 * brightness_level))
    B747DR_annun_brightness_ratio[89]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_gen_field_02 * brightness_level))
    B747DR_annun_brightness_ratio[90]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_gen_field_03 * brightness_level))
    B747DR_annun_brightness_ratio[91]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_gen_field_04 * brightness_level))
    B747DR_annun_brightness_ratio[92]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.apu_gen_field_01 * brightness_level))
    B747DR_annun_brightness_ratio[93]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.apu_gen_field_02 * brightness_level))
    B747DR_annun_brightness_ratio[94]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.split_sys_breaker * brightness_level))

    -- SQUIB TEST
    B747DR_annun_brightness_ratio[95]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_eng_01 * brightness_level))
    B747DR_annun_brightness_ratio[96]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_eng_02 * brightness_level))
    B747DR_annun_brightness_ratio[97]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_eng_03 * brightness_level))
    B747DR_annun_brightness_ratio[98]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_eng_04 * brightness_level))
    B747DR_annun_brightness_ratio[99]   = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_apu * brightness_level))
    B747DR_annun_brightness_ratio[100]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_cargo_A * brightness_level))
    B747DR_annun_brightness_ratio[101]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_cargo_B * brightness_level))
    B747DR_annun_brightness_ratio[102]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_cargo_C * brightness_level))
    B747DR_annun_brightness_ratio[103]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.squib_test_cargo_D * brightness_level))

    -- IRS
    B747DR_annun_brightness_ratio[104]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.irs_on_bat * brightness_level))

    -- HYDRAULIC SYSTEM FAULT
    B747DR_annun_brightness_ratio[105]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.hyd_sys_fault_01 * brightness_level))
    B747DR_annun_brightness_ratio[106]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.hyd_sys_fault_02 * brightness_level))
    B747DR_annun_brightness_ratio[107]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.hyd_sys_fault_03 * brightness_level))
    B747DR_annun_brightness_ratio[108]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.hyd_sys_fault_04 * brightness_level))

    -- HYDRAULIC DEMAND PUMP PRESS LOW
    B747DR_annun_brightness_ratio[109]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.demand_pump_press_01 * brightness_level))
    B747DR_annun_brightness_ratio[110]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.demand_pump_press_02 * brightness_level))
    B747DR_annun_brightness_ratio[111]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.demand_pump_press_03 * brightness_level))
    B747DR_annun_brightness_ratio[112]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.demand_pump_press_04 * brightness_level))

    -- FIRE EXTINGUISHER BOTTLE DISCHARGE
    B747DR_annun_brightness_ratio[113]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.fire_bottle_0102A_disch * brightness_level))
    B747DR_annun_brightness_ratio[114]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.fire_bottle_0102B_disch * brightness_level))
    B747DR_annun_brightness_ratio[115]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.fire_bottle_0304A_disch * brightness_level))
    B747DR_annun_brightness_ratio[116]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.fire_bottle_0304B_disch * brightness_level))
    B747DR_annun_brightness_ratio[117]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.fire_bottle_APU_disch * brightness_level))

    -- ENGINE BLEED AIR SYS FAULT
    B747DR_annun_brightness_ratio[118]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_bleed_air_sys_fault_01 * brightness_level))
    B747DR_annun_brightness_ratio[119]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_bleed_air_sys_fault_02 * brightness_level))
    B747DR_annun_brightness_ratio[120]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_bleed_air_sys_fault_03 * brightness_level))
    B747DR_annun_brightness_ratio[121]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.eng_bleed_air_sys_fault_04 * brightness_level))

    -- START SWITCH (START VALVE OPEN)
    B747DR_annun_brightness_ratio[122]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.start_vlv_open_01 * brightness_level))
    B747DR_annun_brightness_ratio[123]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.start_vlv_open_02 * brightness_level))
    B747DR_annun_brightness_ratio[124]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.start_vlv_open_03 * brightness_level))
    B747DR_annun_brightness_ratio[125]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.start_vlv_open_04 * brightness_level))


    ----- PEDESTAL PANEL -----

    -- RADIO TUNING PANEL LEFT
    B747DR_annun_brightness_ratio[126]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_offside_tuning * brightness_level))
    B747DR_annun_brightness_ratio[127]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_off * brightness_level))
    B747DR_annun_brightness_ratio[128]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_vhf_L * brightness_level))
    B747DR_annun_brightness_ratio[129]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_vhf_C * brightness_level))
    B747DR_annun_brightness_ratio[130]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_vhf_R * brightness_level))
    B747DR_annun_brightness_ratio[131]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_hf_L * brightness_level))
    B747DR_annun_brightness_ratio[132]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_am * brightness_level))
    B747DR_annun_brightness_ratio[133]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_L_hf_R * brightness_level))

    -- RADIO TUNING PANEL RIGHT
    B747DR_annun_brightness_ratio[134]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_offside_tuning * brightness_level))
    B747DR_annun_brightness_ratio[135]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_off * brightness_level))
    B747DR_annun_brightness_ratio[136]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_vhf_L * brightness_level))
    B747DR_annun_brightness_ratio[137]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_vhf_C * brightness_level))
    B747DR_annun_brightness_ratio[138]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_vhf_R * brightness_level))
    B747DR_annun_brightness_ratio[139]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_hf_L * brightness_level))
    B747DR_annun_brightness_ratio[140]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_am * brightness_level))
    B747DR_annun_brightness_ratio[141]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_R_hf_R * brightness_level))

    -- RADIO TUNING PANEL CENTER
    B747DR_annun_brightness_ratio[142]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_offside_tuning * brightness_level))
    B747DR_annun_brightness_ratio[143]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_off * brightness_level))
    B747DR_annun_brightness_ratio[144]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_vhf_L * brightness_level))
    B747DR_annun_brightness_ratio[145]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_vhf_C * brightness_level))
    B747DR_annun_brightness_ratio[146]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_vhf_R * brightness_level))
    B747DR_annun_brightness_ratio[147]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_hf_L * brightness_level))
    B747DR_annun_brightness_ratio[148]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_am * brightness_level))
    B747DR_annun_brightness_ratio[149]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.rtp_C_hf_R * brightness_level))

    -- AUDIO PANEL LEFT
    B747DR_annun_brightness_ratio[150]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[151]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_C_xmt * brightness_level))
    B747DR_annun_brightness_ratio[152]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_R_xmt * brightness_level))
    B747DR_annun_brightness_ratio[153]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_flt_xmt * brightness_level))
    B747DR_annun_brightness_ratio[154]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_cab_xmt * brightness_level))
    B747DR_annun_brightness_ratio[155]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_pa_xmt * brightness_level))
    B747DR_annun_brightness_ratio[156]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_hf_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[157]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_hf_R_xmt * brightness_level))
    B747DR_annun_brightness_ratio[158]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_sat_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[159]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_sat_R_xmt * brightness_level))

    B747DR_annun_brightness_ratio[160]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[161]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_C_audio * brightness_level))
    B747DR_annun_brightness_ratio[162]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[163]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_flt_audio * brightness_level))
    B747DR_annun_brightness_ratio[164]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_cab_audio * brightness_level))
    B747DR_annun_brightness_ratio[165]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_pa_audio * brightness_level))
    B747DR_annun_brightness_ratio[166]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_hf_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[167]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_hf_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[168]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_sat_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[169]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_sat_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[170]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_spkr_audio * brightness_level))
    B747DR_annun_brightness_ratio[171]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vor_adf_audio * brightness_level))
    B747DR_annun_brightness_ratio[172]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_app_mkr_audio * brightness_level))

    B747DR_annun_brightness_ratio[173]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_L_call * brightness_level))
    B747DR_annun_brightness_ratio[174]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_C_call * brightness_level))
    B747DR_annun_brightness_ratio[175]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_vhf_R_call * brightness_level))
    B747DR_annun_brightness_ratio[176]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_flt_call * brightness_level))
    B747DR_annun_brightness_ratio[177]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_cab_call * brightness_level))
    B747DR_annun_brightness_ratio[178]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_hf_L_call * brightness_level))
    B747DR_annun_brightness_ratio[179]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_hf_R_call * brightness_level))
    B747DR_annun_brightness_ratio[180]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_sat_L_call * brightness_level))
    B747DR_annun_brightness_ratio[181]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_L_sat_R_call * brightness_level))

    -- AUDIO PANEL CENTER
    B747DR_annun_brightness_ratio[182]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[183]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_C_xmt * brightness_level))
    B747DR_annun_brightness_ratio[184]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_R_xmt * brightness_level))
    B747DR_annun_brightness_ratio[185]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_flt_xmt * brightness_level))
    B747DR_annun_brightness_ratio[186]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_cab_xmt * brightness_level))
    B747DR_annun_brightness_ratio[187]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_pa_xmt * brightness_level))
    B747DR_annun_brightness_ratio[188]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_hf_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[189]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_hf_R_xmt * brightness_level))
    B747DR_annun_brightness_ratio[190]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_sat_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[191]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_sat_R_xmt * brightness_level))

    B747DR_annun_brightness_ratio[192]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[193]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_C_audio * brightness_level))
    B747DR_annun_brightness_ratio[194]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[195]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_flt_audio * brightness_level))
    B747DR_annun_brightness_ratio[196]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_cab_audio * brightness_level))
    B747DR_annun_brightness_ratio[197]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_pa_audio * brightness_level))
    B747DR_annun_brightness_ratio[198]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_hf_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[199]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_hf_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[200]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_sat_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[201]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_sat_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[202]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_spkr_audio * brightness_level))
    B747DR_annun_brightness_ratio[203]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vor_adf_audio * brightness_level))
    B747DR_annun_brightness_ratio[204]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_app_mkr_audio * brightness_level))

    B747DR_annun_brightness_ratio[205]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_L_call * brightness_level))
    B747DR_annun_brightness_ratio[206]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_C_call * brightness_level))
    B747DR_annun_brightness_ratio[207]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_vhf_R_call * brightness_level))
    B747DR_annun_brightness_ratio[208]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_flt_call * brightness_level))
    B747DR_annun_brightness_ratio[209]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_cab_call * brightness_level))
    B747DR_annun_brightness_ratio[210]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_hf_L_call * brightness_level))
    B747DR_annun_brightness_ratio[211]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_hf_R_call * brightness_level))
    B747DR_annun_brightness_ratio[212]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_sat_L_call * brightness_level))
    B747DR_annun_brightness_ratio[213]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_C_sat_R_call * brightness_level))

    -- AUDIO PANEL RIGHT
    B747DR_annun_brightness_ratio[214]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[215]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_C_xmt * brightness_level))
    B747DR_annun_brightness_ratio[216]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_R_xmt * brightness_level))
    B747DR_annun_brightness_ratio[217]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_flt_xmt * brightness_level))
    B747DR_annun_brightness_ratio[218]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_cab_xmt * brightness_level))
    B747DR_annun_brightness_ratio[219]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_pa_xmt * brightness_level))
    B747DR_annun_brightness_ratio[220]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_hf_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[221]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_hf_R_xmt * brightness_level))
    B747DR_annun_brightness_ratio[222]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_sat_L_xmt * brightness_level))
    B747DR_annun_brightness_ratio[223]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_sat_R_xmt * brightness_level))

    B747DR_annun_brightness_ratio[224]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[225]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_C_audio * brightness_level))
    B747DR_annun_brightness_ratio[226]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[227]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_flt_audio * brightness_level))
    B747DR_annun_brightness_ratio[228]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_cab_audio * brightness_level))
    B747DR_annun_brightness_ratio[229]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_pa_audio * brightness_level))
    B747DR_annun_brightness_ratio[230]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_hf_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[231]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_hf_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[232]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_sat_L_audio * brightness_level))
    B747DR_annun_brightness_ratio[233]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_sat_R_audio * brightness_level))
    B747DR_annun_brightness_ratio[234]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_spkr_audio * brightness_level))
    B747DR_annun_brightness_ratio[235]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vor_adf_audio * brightness_level))
    B747DR_annun_brightness_ratio[236]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_app_mkr_audio * brightness_level))

    B747DR_annun_brightness_ratio[237]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_L_call * brightness_level))
    B747DR_annun_brightness_ratio[238]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_C_call * brightness_level))
    B747DR_annun_brightness_ratio[239]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_vhf_R_call * brightness_level))
    B747DR_annun_brightness_ratio[240]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_flt_call * brightness_level))
    B747DR_annun_brightness_ratio[241]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_cab_call * brightness_level))
    B747DR_annun_brightness_ratio[242]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_hf_L_call * brightness_level))
    B747DR_annun_brightness_ratio[243]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_hf_R_call * brightness_level))
    B747DR_annun_brightness_ratio[244]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_sat_L_call * brightness_level))
    B747DR_annun_brightness_ratio[245]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.ap_R_sat_R_call * brightness_level))

    B747DR_annun_brightness_ratio[246]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.call_pnl_ud_call * brightness_level))
    B747DR_annun_brightness_ratio[247]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.call_pnl_crw_rst_L_call * brightness_level))
    B747DR_annun_brightness_ratio[248]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.call_pnl_crw_rst_R_call * brightness_level))
    B747DR_annun_brightness_ratio[249]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.call_pnl_cargo_call * brightness_level))
    B747DR_annun_brightness_ratio[250]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.call_pnl_grnd_call * brightness_level))

    -- SAFETY                                                                           -- TODO:  CHANGE ATTR_light_level ON CABIN SIGNS IN BLENDER and ADD TRIGGER FOR XP SMOKE/SEAT BELT
    B747DR_annun_brightness_ratio[251]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.no_smoking * brightness_level))
    B747DR_annun_brightness_ratio[252]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.a.seat_belts * brightness_level))

    -- RADIO LCD
    B747DR_annun_brightness_ratio[253]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, brightness_level * (1.0 - B747DR_rtp_L_off_status))            -- LEFT RADIO PANEL GLASS (GLOW)
    B747DR_annun_brightness_ratio[254]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, brightness_level * (1.0 - B747DR_rtp_C_off_status))            -- CENTER RADIO PANEL GLASS (GLOW)
    B747DR_annun_brightness_ratio[255]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, brightness_level * (1.0 - B747DR_rtp_R_off_status))            -- RIGHT RADIO PANEL GLASS (GLOW)
    B747DR_annun_brightness_ratio[256]  = brightness_level                                              -- TRANSPONDER RADIO PANEL GLASS (GLOW)
    simDR_instrument_brightness_switch[15] = B747_ternary((brightness_level>0), 1.0, 0)                                           -- RADIO LCDs




    ----- MCP -----

    -- AUTOPILOT BUTTON SWITCHES
    B747DR_annun_brightness_ratio[257]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_thrust * brightness_level))
    B747DR_annun_brightness_ratio[258]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_speed * brightness_level))
    B747DR_annun_brightness_ratio[259]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_lnav * brightness_level))
    B747DR_annun_brightness_ratio[260]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_vnav * brightness_level))
    B747DR_annun_brightness_ratio[261]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_fl_ch * brightness_level))
    B747DR_annun_brightness_ratio[262]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_hdg_hold * brightness_level))
    B747DR_annun_brightness_ratio[263]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_vs * brightness_level))
    B747DR_annun_brightness_ratio[264]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_alt_hold * brightness_level))
    B747DR_annun_brightness_ratio[265]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_loc * brightness_level))
    B747DR_annun_brightness_ratio[266]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_app * brightness_level))
    B747DR_annun_brightness_ratio[267]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_CMD_L * brightness_level))
    B747DR_annun_brightness_ratio[268]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_CMD_C * brightness_level))
    B747DR_annun_brightness_ratio[269]  = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, (annun.b.ap_CMD_R * brightness_level))

    --wxr panel
        --not XP12.3
    if simDR_version<123004 then
        B747DR_wxr_left_GCS             = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_left_TFR             = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_left_WX             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or true), brightness_level, 0)
        B747DR_wxr_left_WX_T            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_left_MAP            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)

        B747DR_wxr_right_GCS             = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_right_TFR             = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_right_WX             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or true), brightness_level, 0)
        B747DR_wxr_right_WX_T            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_right_MAP            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)

        B747DR_wxr_test            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_RR            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
        B747DR_wxr_LR            = B747_ternary((B747DR_toggle_switch_position[13] == 1), brightness_level, 0)
    else 
        B747DR_wxr_left_GCS             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrgcs_cpt==1), brightness_level, 0)
        B747DR_wxr_left_TFR             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or (simDR_wxrMode_cpt==0 and simDR_wxrMode_fo==0)), brightness_level, 0)
        B747DR_wxr_left_WX             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_cpt==2), brightness_level, 0)
        B747DR_wxr_left_WX_T            = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_cpt==3), brightness_level, 0)
        B747DR_wxr_left_MAP            = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_cpt==4), brightness_level, 0)

        B747DR_wxr_right_GCS             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrgcs_fo==1), brightness_level, 0)
        B747DR_wxr_right_TFR             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or (simDR_wxrMode_cpt==0 and simDR_wxrMode_fo==0)), brightness_level, 0)
        B747DR_wxr_right_WX             = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_fo==2), brightness_level, 0)
        B747DR_wxr_right_WX_T            = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_fo==3), brightness_level, 0)
        B747DR_wxr_right_MAP            = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_fo==4), brightness_level, 0)

        B747DR_wxr_test            = B747_ternary((B747DR_toggle_switch_position[13] == 1 or simDR_wxrMode_cpt==1 or simDR_wxrMode_fo==1), brightness_level, 0)
        B747DR_wxr_RR            = B747_ternary((B747DR_toggle_switch_position[13] == 1 ), brightness_level, 0)
        B747DR_wxr_LR            = B747_ternary((B747DR_toggle_switch_position[13] == 1 or true), brightness_level, 0) 
    end
    --wxr lighting
    

   --[[simDR_wxrMode_cpt = find_dataref("sim/cockpit2/EFIS/EFIS_weather_mode")
    simDR_wxrMode_fo = find_dataref("sim/cockpit2/EFIS/EFIS_weather_mode_copilot")]]--

end







----- LIGHTING EICAS MESSAGES -----------------------------------------------------------
function B747_lighting_EICAS_msg()

    -- STROBE LIGHT OFF
    
    if simDR_strobe_lights_switch < 0.05 and simDR_aircraft_on_ground == 1 then
        B747DR_CAS_memo_status[35] = 0
    else
        B747DR_CAS_memo_status[35] = 0
    end

end









----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_lighting_monitor_AI()

    if B747DR_init_lighting_CD == 1 then
        B747_set_lighting_all_modes()
        B747_set_lighting_CD()
        B747DR_init_lighting_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_lighting_all_modes()

	B747DR_init_lighting_CD = 0
    B747_init_lighting()
    B747_init_light_rheostats()

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
--simDR_window_ice                    = find_dataref("sim/flightmodel/failures/window_ice")
simDR_OAT=find_dataref("sim/weather/temperature_ambient_c")
function B747_set_lighting_CD()
    --[[if simDR_OAT<-1 then
        simDR_window_ice                    = 1
    end]]--
end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_lighting_ER()
	

	
end







----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_lighting()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_lighting_all_modes()



    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_lighting_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_lighting_ER()

    end

end










----- EXIT PROCESSING -----------------------------------------------------------------------
function B747_aircraft_unload_lighting()

    -- RESET DEFAULT LIGHTING VALUES
    for i = 0, 63 do
        simDR_generic_brightness_switch[i] = 0.0
    end

    for i = 0, 3 do
        simDR_panel_brightness_switch[i] = 0.75
    end

    for i = 0, 15 do
        simDR_instrument_brightness_switch[i] = 0.0
	B747DR_instrument_brightness_ratio[i] = 0.75
    end

end





--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

function aircraft_unload()

    B747_aircraft_unload_lighting()

end


function flight_start()
    print("Lighting start")
    -- GENERIC LIGHT INDEX [63] (USED AS A "POWER SOURCE" VALUE FOR LIGHTS)
    simDR_generic_brightness_switch[63] = 1.0
    for i = 0, 15 do
        simDR_instrument_brightness_switch[i] = 0.0
	    B747DR_instrument_brightness_ratio[i] = 1.0
    end
    B747_flight_start_lighting()
    if simDR_version<115602 then
        simDR_shadow=-1
    end
end
function closest_intercept(x1,y1,z1,x2,y2,z2,psi,pitch)
    dx=x1 - x2;
    dy=y1 - y2;
    dz=z1 - z2;
    distance=math.sqrt(((dx*dx) + (dy*dy) + (dz*dz)));
    psiI=psi;



    pitchI=pitch;
    pdistance=math.cos(pitchI*math.pi/180.0)*distance;
    px=(-math.sin(psiI*math.pi/180.0))*pdistance;
    pz=math.cos(psiI*math.pi/180.0)*pdistance;
    py=(-math.sin(pitchI*math.pi/180.0))*distance;
    
    pdx=dx-px;
    pdy=dy-py;
    pdz=dz-pz;
    --print(distance.. " " .. pdx .. " " .. pdy .. " " .. pdz)
    loc=math.sqrt(((pdx*pdx) + (pdz*pdz) + (pdy*pdy)));
    return loc
end
function viewheadCoPilotVisor()
    local psi=simDR_headpsi
    local pitch=simDR_headpitch
    local visorX=B747_rescale(0.5,0.845,1,0.102,simDR_fo_visor_lr) 
    local visorY=5.2
    local visorZ=B747_rescale(0,-25.41,0.6,-26.4,simDR_fo_visor_lr)
    local thisHit=closest_intercept(simDR_headX,simDR_headY,simDR_headZ,visorX,visorY,visorZ,psi,pitch)
    
    local retVal=B747_rescale(0,1,0.4,0,thisHit)
    return retVal
end
function viewheadPilotVisor()
    local psi=simDR_headpsi
    local pitch=simDR_headpitch
    local visorX=B747_rescale(0.5,-0.845,1,-0.102,simDR_capt_visor_lr)
    local visorY=5.2
    local visorZ=B747_rescale(0,-25.41,0.6,-26.4,simDR_capt_visor_lr)
    local thisHit=closest_intercept(simDR_headX,simDR_headY,simDR_headZ,visorX,visorY,visorZ,psi,pitch)
    
    local retVal=B747_rescale(0,1,0.4,0,thisHit)
    return retVal
end
function getPilotVisorValue()
    local retVal=viewheadPilotVisor()
    --print("getPilotVisorValue "..(retVal))
 
    return retVal*(1-simDR_capt_visor_ud)
end
function getCoPilotVisorValue()
    local retVal=viewheadCoPilotVisor()
    --print("getCoPilotVisorValue "..retVal)
 
    return retVal*(1-simDR_fo_visor_ud)
end
local defaultBias=-0.3
function tone_mapping()

    simDR_photoBias=defaultBias-1.6*math.max(getPilotVisorValue(),getCoPilotVisorValue())
   
 --[[   if simDR_sun_pitch>0 then
        simDR_contrast	= B747_rescale(0,1.25,30,0.8,math.abs(simDR_view_pitch))
        simDR_ev100	    = B747_rescale(-10,8,15,14,math.abs(simDR_sun_pitch))
        simDR_tone_mode			    = 0
        simDR_exposure_fusion			    = 0
    else
        simDR_contrast	= B747_rescale(0,0.8,30,1.25,math.abs(simDR_view_pitch))
        simDR_light_storage		    = B747_rescale(0,10,30,1,math.abs(simDR_view_pitch))
        simDR_tone_mode			    = 1
    simDR_exposure_fusion			    = 1
    end]]--
    
end
--function flight_crash() end

--function before_physics() end
debug_lighting     = deferred_dataref("laminar/B747/debug/lighting", "number")
function after_physics()
    collectgarbage("collect")
  if debug_lighting>0 then return end
  
    B747_landing_light_brightness()
    B747_turnoff_lights()
    B747_taxi_lights()
    B747_beacon_lights()
    B747_nav_lights()
    B747_strobe_lights()
    B747_wing_lights()
    B747_logo_lights()
    B747_cabin_lights()

    B747_spill_lights()
    B747_annunciators()
    B747_ind_lights()

    B747_lighting_EICAS_msg()

    B747_lighting_monitor_AI()
    --tone_mapping()
end

--function after_replay() end



