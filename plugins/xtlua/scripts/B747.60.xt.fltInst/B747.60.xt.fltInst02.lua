--[[
*****************************************************************************************
* Program Script Name	:	B747.60.fltInst
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

--[[
B747_RESET  = -1
B747_HOLD   = 0
B747_RUN    = 1
B747_START  = 1
B747_STOP   = 0
B747_ET     = 0
B747_CHRONO = 1
--]]






--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local B747_flt_mode = 0                                                               -- ON THE GROUND
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
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")

simDR_all_wheels_on_ground          = find_dataref("sim/flightmodel/failures/onground_any")

--simDR_HSI_source_sel                = find_dataref("sim/cockpit2/radios/actuators/HSI_source_select_pilot")
simDR_autopilot_source              = find_dataref("sim/cockpit2/autopilot/autopilot_source")

simDR_time_is_GMT                   = find_dataref("sim/cockpit2/clock_timer/timer_is_GMT")
simDR_time_zulu_minutes             = find_dataref("sim/cockpit2/clock_timer/zulu_time_minutes")
simDR_time_zulu_hours               = find_dataref("sim/cockpit2/clock_timer/zulu_time_hours")
simDR_time_current_day              = find_dataref("sim/cockpit2/clock_timer/current_day")
simDR_time_current_month            = find_dataref("sim/cockpit2/clock_timer/current_month")

simDR_rmi_captain_left_use_adf      = find_dataref("sim/cockpit2/radios/actuators/RMI_left_use_adf_pilot")
simDR_rmi_captain_right_use_adf     = find_dataref("sim/cockpit2/radios/actuators/RMI_right_use_adf_pilot")

simDR_adf1_relative_bearing_deg     = find_dataref("sim/cockpit2/radios/indicators/adf1_relative_bearing_deg")
simDR_adf2_relative_bearing_deg     = find_dataref("sim/cockpit2/radios/indicators/adf2_relative_bearing_deg")
--simDR_nav1_relative_bearing_deg     = find_dataref("sim/cockpit2/radios/indicators/nav1_relative_bearing_deg")
--simDR_nav2_relative_bearing_deg     = find_dataref("sim/cockpit2/radios/indicators/nav2_relative_bearing_deg")

simDR_nav_relative_bearing_deg      = find_dataref("sim/cockpit2/radios/indicators/nav_relative_bearing_deg")

simDR_nav3_ID                       = find_dataref("sim/cockpit2/radios/indicators/nav3_nav_id")
simDR_nav4_ID                       = find_dataref("sim/cockpit2/radios/indicators/nav4_nav_id")
simDR_adf1_ID                       = find_dataref("sim/cockpit2/radios/indicators/adf1_nav_id")
simDR_adf2_ID                       = find_dataref("sim/cockpit2/radios/indicators/adf2_nav_id")

simDR_altimeter_baro_inHg           = find_dataref("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")
simDR_altimeter_baro_inHg_fo        = find_dataref("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_copilot")
simDR_altitude_ft_pilot             = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")

simDR_radio_alt_DH_capt             = find_dataref("sim/cockpit2/gauges/actuators/radio_altimeter_bug_ft_pilot")
simDR_radio_alt_DH_fo               = find_dataref("sim/cockpit2/gauges/actuators/radio_altimeter_bug_ft_copilot")
simDR_radio_alt_height_capt         = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
--simDR_radio_alt_height_fo           = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_copilot")
--simDR_radio_alt_DH_alert_capt       = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_dh_lit_pilot")
--simDR_radio_alt_DH_alert_fo         = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_dh_lit_copilot")

simDR_EFIS_map_mode                 = find_dataref("sim/cockpit2/EFIS/map_mode")
simDR_EFIS_map_range                = find_dataref("sim/cockpit2/EFIS/map_range")
simDR_EFIS_map_is_center            = find_dataref("sim/cockpit2/EFIS/map_mode_is_HSI")

simDR_EFIS_1_sel_pilot              = find_dataref("sim/cockpit2/EFIS/EFIS_1_selection_pilot")
simDR_EFIS_2_sel_pilot              = find_dataref("sim/cockpit2/EFIS/EFIS_1_selection_copilot")
simDR_EFIS_1_sel_fo                 = find_dataref("sim/cockpit2/EFIS/EFIS_2_selection_pilot")
simDR_EFIS_2_sel_fo                 = find_dataref("sim/cockpit2/EFIS/EFIS_2_selection_copilot")

simDR_vvi_fpm_pilot                 = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")

simDR_EFIS_wxr_on                   = find_dataref("sim/cockpit2/EFIS/EFIS_weather_on")
simDR_EFIS_tcas_on                  = find_dataref("sim/cockpit2/EFIS/EFIS_tcas_on")
B747DR_nd_capt_tfc	            = find_dataref("laminar/B747/nd/capt/tfc")
B747DR_nd_fo_tfc	            = find_dataref("laminar/B747/nd/fo/tfc")
B747DR_nd_capt_tcas_off             = find_dataref("laminar/B747/nd/capt/tcas_off")
B747DR_nd_fo_tcas_off         	    = find_dataref("laminar/B747/nd/fo/tcas_off")
B747DR_pfd_mode_capt		    = find_dataref("laminar/B747/pfd/capt/irs")
B747DR_pfd_mode_fo		    = find_dataref("laminar/B747/pfd/fo/irs")

B747DR_xpdr_sel_pos                 = find_dataref("laminar/B747/flt_mgmt/txpdr/mode_sel_pos")
--simDR_acf_weight_payload_kg         = find_dataref("sim/flightmodel/weight/m_fixed")
simDR_acf_weight_total_kg           = find_dataref("sim/flightmodel/weight/m_total")
simDR_wing_flap1_deg                = find_dataref("sim/flightmodel2/wing/flap1_deg")

simDR_OAT_degC                      = find_dataref("sim/cockpit2/temperature/outside_air_temp_degc")
simDR_wind_heading_deg              = find_dataref("sim/cockpit2/gauges/indicators/wind_heading_deg_mag")
simDR_wind_speed_kts                = find_dataref("sim/cockpit2/gauges/indicators/wind_speed_kts")
simDR_position_mag_psi              = find_dataref("sim/flightmodel/position/mag_psi")

simDR_gear_deploy_ratio             = find_dataref("sim/flightmodel2/gear/deploy_ratio")
simDR_airspeed                      = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
simDR_airspeed_mach                 = find_dataref("sim/flightmodel/misc/machno")
simDR_AOA_fail                      = find_dataref("sim/operation/failures/rel_AOA")
simDR_battery_chg_watt_hr           = find_dataref("sim/cockpit/electrical/battery_charge_watt_hr")
simDR_stalled_elements              = find_dataref("sim/flightmodel2/wing/elements/element_is_stalled")
simDR_stall_warning                  = find_dataref("sim/flightmodel/failures/stallwarning")
simDR_has_stall_warning                  = find_dataref("sim/aircraft/view/acf_has_stallwarn")
simDR_hsi_hdef_dots_pilot           = find_dataref("sim/cockpit2/radios/indicators/hsi_hdef_dots_pilot")
simDR_hsi_vdef_dots_pilot           = find_dataref("sim/cockpit2/radios/indicators/hsi_vdef_dots_pilot")

simDR_hsi_hdef_dots_copilot         = find_dataref("sim/cockpit2/radios/indicators/hsi_hdef_dots_copilot")
simDR_hsi_vdef_dots_copilot         = find_dataref("sim/cockpit2/radios/indicators/hsi_vdef_dots_copilot")

simDR_elec_bus_volts				= find_dataref("sim/cockpit2/electrical/bus_volts")		
simDR_time_now						= find_dataref("sim/time/total_running_time_sec")

simDR_autopilot_TOGA_pitch_deg      	= find_dataref("sim/cockpit2/autopilot/TOGA_pitch_deg")


--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_button_switch_position   = find_dataref("laminar/B747/button_switch/position")

B747DR_CAS_msg_page             = find_dataref("laminar/B747/CAS/msg_page")
B747DR_CAS_num_msg_pages        = find_dataref("laminar/B747/CAS/num_msg_pages")
B747DR_CAS_caut_adv_display     = find_dataref("laminar/B747/CAS/caut_adv_display")
B747DR_CAS_recall_ind           = find_dataref("laminar/B747/CAS/recall_ind")

B747DR_CAS_warning_status       = find_dataref("laminar/B747/CAS/warning_status")
B747DR_CAS_caution_status       = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status      = find_dataref("laminar/B747/CAS/advisory_status")

B747DR_elec_standby_power_sel_pos   = find_dataref("laminar/B747/electrical/standby_power/sel_dial_pos")

B747DR_autothrottle_fail            	= find_dataref("laminar/B747/engines/autothrottle_fail")

B747DR_toga_mode                                = find_dataref("sim/cockpit2/autopilot/TOGA_status")
--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_flt_inst_fd_src_capt_dial_pos            = deferred_dataref("laminar/B747/flt_inst/flt_dir_src/capt/sel_dial_pos", "number")
B747DR_flt_inst_nav_src_capt_dial_pos           = deferred_dataref("laminar/B747/flt_inst/nav_src/capt/sel_dial_pos", "number")
B747DR_flt_inst_eiu_src_capt_dial_pos           = deferred_dataref("laminar/B747/flt_inst/eiu_src/capt/sel_dial_pos", "number")
B747DR_flt_inst_irs_src_capt_dial_pos           = deferred_dataref("laminar/B747/flt_inst/irs_src/capt/sel_dial_pos", "number")
B747DR_flt_inst_air_data_src_capt_dial_pos      = deferred_dataref("laminar/B747/flt_inst/air_data_src/capt/sel_dial_pos", "number")

B747DR_flt_inst_fd_src_fo_dial_pos              = deferred_dataref("laminar/B747/flt_inst/flt_dir_src/fo/sel_dial_pos", "number")
B747DR_flt_inst_nav_src_fo_dial_pos             = deferred_dataref("laminar/B747/flt_inst/nav_src/fo/sel_dial_pos", "number")
B747DR_flt_inst_eiu_src_fo_dial_pos             = deferred_dataref("laminar/B747/flt_inst/eiu_src/fo/sel_dial_pos", "number")
B747DR_flt_inst_irs_src_fo_dial_pos             = deferred_dataref("laminar/B747/flt_inst/irs_src/fo/sel_dial_pos", "number")
B747DR_flt_inst_air_data_src_fo_dial_pos        = deferred_dataref("laminar/B747/flt_inst/air_data_src/fo/sel_dial_pos", "number")

B747DR_flt_inst_eiu_src_ctr_pnl_dial_pos        = deferred_dataref("laminar/B747/flt_inst/eiu_src/ctr_pnl/sel_dial_pos", "number")
B747DR_flt_inst_fmc_master_src_ctr_pnl_sel_pos  = deferred_dataref("laminar/B747/flt_inst/fmc_master_src/ctr_pnl/sel_dial_pos", "number")

B747DR_flt_inst_inbd_disp_capt_sel_dial_pos     = deferred_dataref("laminar/B747/flt_inst/capt_inbd_display/sel_dial_pos", "number")
B747DR_flt_inst_lwr_disp_capt_sel_dial_pos      = deferred_dataref("laminar/B747/flt_inst/capt_lwr_display/sel_dial_pos", "number")

B747DR_flt_inst_inbd_disp_fo_sel_dial_pos       = deferred_dataref("laminar/B747/flt_inst/fo_inbd_display/sel_dial_pos", "number")
B747DR_flt_inst_lwr_disp_fo_sel_dial_pos        = deferred_dataref("laminar/B747/flt_inst/fo_lwr_display/sel_dial_pos", "number")

B747DR_flt_inst_capt_pfd_pos      		= deferred_dataref("laminar/B747/flt_inst/display/capt/pfd_pos", "number")
B747DR_flt_inst_fo_pfd_pos      		= deferred_dataref("laminar/B747/flt_inst/display/fo/pfd_pos", "number")
B747DR_flt_inst_capt_nd_pos      		= deferred_dataref("laminar/B747/flt_inst/display/capt/nd_pos", "number")
B747DR_flt_inst_fo_nd_pos      			= deferred_dataref("laminar/B747/flt_inst/display/fo/nd_pos", "number")
B747DR_flt_inst_eicas_pos      			= deferred_dataref("laminar/B747/flt_inst/display/eicas_pos", "number")
B747DR_flt_inst_pri_eicas_pos      		= deferred_dataref("laminar/B747/flt_inst/display/pri_eicas_pos", "number")

B747DR_efis_min_ref_alt_capt_sel_dial_pos       = deferred_dataref("laminar/B747/efis/min_ref_alt/capt/sel_dial_pos", "number")
B747DR_efis_ref_alt_capt_set_dial_pos           = deferred_dataref("laminar/B747/efis/ref_alt/capt/set_dial_pos", "number")
B747DR_efis_dh_reset_capt_switch_pos            = deferred_dataref("laminar/B747/efis/dh_reset/capt/switch_pos", "number")
B747DR_efis_baro_ref_capt_sel_dial_pos          = deferred_dataref("laminar/B747/efis/baro_ref/capt/sel_dial_pos", "number")
B747DR_efis_baro_std_capt_switch_pos            = deferred_dataref("laminar/B747/efis/baro_std/capt/switch_pos", "number")
B747DR_efis_baro_std_capt_show_preselect              = deferred_dataref("laminar/B747/efis/baro_std/capt/show_preselect", "number")
B747DR_efis_baro_capt_set_dial_pos              = deferred_dataref("laminar/B747/efis/baro/capt/set_dial_pos", "number")
B747DR_efis_baro_capt_preselect                 = deferred_dataref("laminar/B747/efis/baro/capt/preselect", "number")
B747DR_efis_baro_alt_ref_capt                   = deferred_dataref("laminar/B747/efis/baro_ref/capt", "number")

B747DR_efis_min_ref_alt_fo_sel_dial_pos         = deferred_dataref("laminar/B747/efis/min_ref_alt/fo/sel_dial_pos", "number")
B747DR_efis_ref_alt_fo_set_dial_pos             = deferred_dataref("laminar/B747/efis/ref_alt/fo/set_dial_pos", "number")
B747DR_efis_dh_reset_fo_switch_pos              = deferred_dataref("laminar/B747/efis/dh_reset/fo/switch_pos", "number")
B747DR_efis_baro_ref_fo_sel_dial_pos            = deferred_dataref("laminar/B747/efis/baro_ref/fo/sel_dial_pos", "number")
B747DR_efis_baro_std_fo_switch_pos              = deferred_dataref("laminar/B747/efis/baro_std/fo/switch_pos", "number")
B747DR_efis_baro_fo_set_dial_pos                = deferred_dataref("laminar/B747/efis/baro/fo/set_dial_pos", "number")
B747DR_efis_baro_std_fo_show_preselect              = deferred_dataref("laminar/B747/efis/baro_std/fo/show_preselect", "number")
B747DR_efis_baro_fo_preselect                   = deferred_dataref("laminar/B747/efis/baro/fo/preselect", "number")
B747DR_efis_baro_alt_ref_fo                     = deferred_dataref("laminar/B747/efis/baro_ref/fo", "number")

B747DR_efis_fpv_capt_switch_pos                 = deferred_dataref("laminar/B747/efis/fpv/capt/switch_pos", "number")
B747DR_efis_meters_capt_switch_pos              = deferred_dataref("laminar/B747/efis/meters/capt/switch_pos", "number")
B747DR_efis_meters_capt_selected                = deferred_dataref("laminar/B747/efis/meters/capt/selected", "number")

B747DR_efis_fpv_fo_switch_pos                   = deferred_dataref("laminar/B747/efis/fpv/fo/switch_pos", "number")
B747DR_efis_meters_fo_switch_pos                = deferred_dataref("laminar/B747/efis/meters/fo/switch_pos", "number")
B747DR_efis_meters_fo_selected                  = deferred_dataref("laminar/B747/efis/meters/fo/selected", "number")

B747DR_nd_mode_capt_sel_dial_pos                = deferred_dataref("laminar/B747/nd/mode/capt/sel_dial_pos", "number")
B747DR_nd_range_capt_sel_dial_pos               = deferred_dataref("laminar/B747/nd/range/capt/sel_dial_pos", "number")

B747DR_nd_center_capt_switch_pos                = deferred_dataref("laminar/B747/nd/center/capt/switch_pos", "number")
B747DR_nd_traffic_capt_switch_pos               = deferred_dataref("laminar/B747/nd/traffic/capt/switch_pos", "number")

B747_nd_map_center_capt                         = deferred_dataref("laminar/B747/nd/map_center/capt", "number")

B747DR_nd_mode_fo_sel_dial_pos                  = deferred_dataref("laminar/B747/nd/mode/fo/sel_dial_pos", "number")
B747DR_nd_range_fo_sel_dial_pos                 = deferred_dataref("laminar/B747/nd/range/fo/sel_dial_pos", "number")

B747DR_nd_center_fo_switch_pos                  = deferred_dataref("laminar/B747/nd/center/fo/switch_pos", "number")
B747DR_nd_traffic_fo_switch_pos                 = deferred_dataref("laminar/B747/nd/traffic/fo/switch_pos", "number")

B747_nd_map_center_fo                           = deferred_dataref("laminar/B747/nd/map_center/fo", "number")

B747DR_nd_wxr_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/wxr/capt/switch_pos", "number")
B747DR_nd_sta_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/sta/capt/switch_pos", "number")
B747DR_nd_wpt_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/wpt/capt/switch_pos", "number")
B747DR_nd_arpt_capt_switch_pos                  = deferred_dataref("laminar/B747/nd/arpt/capt/switch_pos", "number")
B747DR_nd_data_capt_switch_pos                  = deferred_dataref("laminar/B747/nd/data/capt/switch_pos", "number")
B747DR_nd_pos_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/pos/capt/switch_pos", "number")
B747DR_nd_terr_capt_switch_pos                  = deferred_dataref("laminar/B747/nd/terr/capt/switch_pos", "number")
B747DR_nd_capt_traffic_Selected                 = deferred_dataref("laminar/B747/nd/traffic/capt/selected", "number")
B747DR_nd_fo_traffic_Selected                   = deferred_dataref("laminar/B747/nd/traffic/fo/selected", "number")
B747DR_nd_capt_vor_ndb                          = deferred_dataref("laminar/B747/nd/data/capt/vor_ndb", "number")
B747DR_nd_fo_vor_ndb                          	= deferred_dataref("laminar/B747/nd/data/fo/vor_ndb", "number")
B747DR_nd_capt_wpt                          = deferred_dataref("laminar/B747/nd/data/capt/wpt", "number")
B747DR_nd_fo_wpt                         	= deferred_dataref("laminar/B747/nd/data/fo/wpt", "number")
B747DR_nd_capt_apt	                        = deferred_dataref("laminar/B747/nd/data/capt/apt", "number")
B747DR_nd_fo_apt	                        = deferred_dataref("laminar/B747/nd/data/fo/apt", "number")

B747_nd_vorL_ID_flag_capt                       = deferred_dataref("laminar/B747/nd/vorL_id_flag/capt", "number")
B747_nd_vorR_ID_flag_capt                       = deferred_dataref("laminar/B747/nd/vorR_id_flag/capt", "number")

B747_nd_adfL_ID_flag_capt                       = deferred_dataref("laminar/B747/nd/adfL_id_flag/capt", "number")
B747_nd_adfR_ID_flag_capt                       = deferred_dataref("laminar/B747/nd/adfR_id_flag/capt", "number")

B747_exp_nd_track_line_on                       = deferred_dataref("laminar/B747/nd/track_line_on", "number")

B747DR_nd_wxr_fo_switch_pos                     = deferred_dataref("laminar/B747/nd/wxr/fo/switch_pos", "number")
B747DR_nd_sta_fo_switch_pos                     = deferred_dataref("laminar/B747/nd/sta/fo/switch_pos", "number")
B747DR_nd_wpt_fo_switch_pos                     = deferred_dataref("laminar/B747/nd/wpt/fo/switch_pos", "number")
B747DR_nd_arpt_fo_switch_pos                    = deferred_dataref("laminar/B747/nd/arpt/fo/switch_pos", "number")
B747DR_nd_data_fo_switch_pos                    = deferred_dataref("laminar/B747/nd/data/fo/switch_pos", "number")
B747DR_nd_pos_fo_switch_pos                     = deferred_dataref("laminar/B747/nd/pos/fo/switch_pos", "number")
B747DR_nd_terr_fo_switch_pos                    = deferred_dataref("laminar/B747/nd/terr/fo/switch_pos", "number")

B747_nd_vorL_ID_flag_fo                         = deferred_dataref("laminar/B747/nd/vorL_id_flag/fo", "number")
B747_nd_vorR_ID_flag_fo                         = deferred_dataref("laminar/B747/nd/vorR_id_flag/fo", "number")

B747_nd_adfL_ID_flag_fo                         = deferred_dataref("laminar/B747/nd/adfL_id_flag/fo", "number")
B747_nd_adfR_ID_flag_fo                         = deferred_dataref("laminar/B747/nd/adfR_id_flag/fo", "number")

B747DR_dsp_eng_switch_pos                       = deferred_dataref("laminar/B747/dsp/eng/switch_pos", "number")
B747DR_dsp_stat_switch_pos                      = deferred_dataref("laminar/B747/dsp/stat/switch_pos", "number")
B747DR_dsp_elec_switch_pos                      = deferred_dataref("laminar/B747/dsp/elec/switch_pos", "number")
B747DR_dsp_fuel_switch_pos                      = deferred_dataref("laminar/B747/dsp/fuel/switch_pos", "number")
B747DR_dsp_ecs_switch_pos                       = deferred_dataref("laminar/B747/dsp/ecs/switch_pos", "number")
B747DR_dsp_hyd_switch_pos                       = deferred_dataref("laminar/B747/dsp/hyd/switch_pos", "number")
B747DR_dsp_drs_switch_pos                       = deferred_dataref("laminar/B747/dsp/drs/switch_pos", "number")
B747DR_dsp_gear_switch_pos                      = deferred_dataref("laminar/B747/dsp/gear/switch_pos", "number")

B747DR_dsp_canc_switch_pos                      = deferred_dataref("laminar/B747/dsp/canc/switch_pos", "number")
B747DR_dsp_rcl_switch_pos                       = deferred_dataref("laminar/B747/dsp/rcl/switch_pos", "number")

B747DR_dsp_synoptic_display                     = deferred_dataref("laminar/B747/dsp/synoptic_display", "number")

B747DR_STAT_msg_page                            = deferred_dataref("laminar/B747/STAT/msg_page", "number")
B747DR_STAT_num_msg_pages                       = deferred_dataref("laminar/B747/STAT/num_msg_pages", "number")
B747DR_simDR_captain_display              = find_dataref("laminar/B747/electrical/capt_display_power")
B747DR_simDR_fo_display             = find_dataref("laminar/B747/electrical/fo_display_power")
B747DR_elec_display_power   = find_dataref("laminar/B747/electrical/display_has_power")
--[[
B747DR_clock_captain_chrono_switch_pos          = deferred_dataref("laminar/B747/clock/captain/chrono_switch_pos", "number")
B747DR_clock_captain_et_sel_switch_pos          = deferred_dataref("laminar/B747/clock/captain/et_sel_switch_pos", "number")
B747DR_clock_captain_date_switch_pos            = deferred_dataref("laminar/B747/clock/captain/date_switch_pos", "number")
B747DR_clock_captain_set_switch_pos             = deferred_dataref("laminar/B747/clock/captain/set_switch_pos", "number")

B747DR_clock_fo_chrono_switch_pos               = deferred_dataref("laminar/B747/clock/fo/chrono_switch_pos", "number")
B747DR_clock_fo_et_sel_switch_pos               = deferred_dataref("laminar/B747/clock/fo/et_sel_switch_pos", "number")
B747DR_clock_fo_date_switch_pos                 = deferred_dataref("laminar/B747/clock/fo/date_switch_pos", "number")
B747DR_clock_fo_set_switch_pos                  = deferred_dataref("laminar/B747/clock/fo/set_switch_pos", "number")

B747DR_glrshld_captain_chrono_switch_pos        = deferred_dataref("laminar/B747/glareshiled/captain/chrono_switch_pos", "number")
B747DR_glrshld_fo_chrono_switch_pos             = deferred_dataref("laminar/B747/glareshiled/fo/chrono_switch_pos", "number")

B747DR_clock_captain_gmt_display_mode           = deferred_dataref("laminar/B747/clock/captain/gmt_display_mode", "number")
B747DR_clock_captain_gmt_date_mode              = deferred_dataref("laminar/B747/clock/captain/gmt_date_mode", "number")
B747DR_clock_captain_et_chr_display_mode        = deferred_dataref("laminar/B747/clock/captain/et_chr_display_mode", "number")
B747DR_clock_captain_chrono_mode                = deferred_dataref("laminar/B747/clock/captain/chrono_mode", "number")
B747DR_clock_captain_chrono_seconds             = deferred_dataref("laminar/B747/clock/captain/chrono_seconds", "number")
B747DR_clock_captain_chrono_minutes             = deferred_dataref("laminar/B747/clock/captain/chrono_minutes", "number")
B747DR_clock_captain_et_mode                    = deferred_dataref("laminar/B747/clock/captain/et_mode", "number")
B747DR_clock_captain_et_seconds                 = deferred_dataref("laminar/B747/clock/captain/et_seconds", "number")
B747DR_clock_captain_et_minutes                 = deferred_dataref("laminar/B747/clock/captain/et_minutes", "number")
B747DR_clock_captain_et_hours                   = deferred_dataref("laminar/B747/clock/captain/et_hours", "number")
B747DR_clock_captain_date_month                 = deferred_dataref("laminar/B747/clock/captain/date_month", "number")
B747DR_clock_captain_date_day                   = deferred_dataref("laminar/B747/clock/captain/date_day", "number")
B747DR_clock_captain_date_year12                = deferred_dataref("laminar/B747/clock/captain/date_year12", "number")
B747DR_clock_captain_date_year34                = deferred_dataref("laminar/B747/clock/captain/date_year34", "number")
B747DR_clock_captain_gmt_minutes                = deferred_dataref("laminar/B747/clock/captain/gmt_minutes", "number")
B747DR_clock_captain_gmt_hours                  = deferred_dataref("laminar/B747/clock/captain/gmt_hours", "number")

B747DR_clock_fo_gmt_display_mode                = deferred_dataref("laminar/B747/clock/fo/gmt_display_mode", "number")
B747DR_clock_fo_gmt_date_mode                   = deferred_dataref("laminar/B747/clock/fo/gmt_date_mode", "number")
B747DR_clock_fo_et_chr_display_mode             = deferred_dataref("laminar/B747/clock/fo/et_chr_display_mode", "number")
B747DR_clock_fo_chrono_mode                     = deferred_dataref("laminar/B747/clock/fo/chrono_mode", "number")
B747DR_clock_fo_chrono_seconds                  = deferred_dataref("laminar/B747/clock/fo/chrono_seconds", "number")
B747DR_clock_fo_chrono_minutes                  = deferred_dataref("laminar/B747/clock/fo/chrono_minutes", "number")
B747DR_clock_fo_et_mode                         = deferred_dataref("laminar/B747/clock/fo/et_mode", "number")
B747DR_clock_fo_et_seconds                      = deferred_dataref("laminar/B747/clock/fo/et_seconds", "number")
B747DR_clock_fo_et_minutes                      = deferred_dataref("laminar/B747/clock/fo/et_minutes", "number")
B747DR_clock_fo_et_hours                        = deferred_dataref("laminar/B747/clock/fo/et_hours", "number")
B747DR_clock_fo_date_month                      = deferred_dataref("laminar/B747/clock/fo/date_month", "number")
B747DR_clock_fo_date_day                        = deferred_dataref("laminar/B747/clock/fo/date_day", "number")
B747DR_clock_fo_date_year12                     = deferred_dataref("laminar/B747/clock/fo/date_year12", "number")
B747DR_clock_fo_date_year34                     = deferred_dataref("laminar/B747/clock/fo/date_year34", "number")
B747DR_clock_fo_gmt_minutes                     = deferred_dataref("laminar/B747/clock/fo/gmt_minutes", "number")
B747DR_clock_fo_gmt_hours                       = deferred_dataref("laminar/B747/clock/fo/gmt_hours", "number")
--]]

B747DR_RMI_left_bearing                         = deferred_dataref("laminar/B747/rmi_left/captain/bearing", "number")
B747DR_RMI_right_bearing                        = deferred_dataref("laminar/B747/rmi_right/captain/bearing", "number")

B747DR_alt_hectopascal                          = deferred_dataref("laminar/B747/altimeter/baro_hectopascal", "number")
B747DR_altimter_ft_adjusted                     = deferred_dataref("laminar/B747/altimeter/ft_adjusted", "number")

B747DR_dec_ht_display_status                    = deferred_dataref("laminar/B747/dec_height/display_status", "number")
B747DR_radio_alt_display_status                 = deferred_dataref("laminar/B747/radio_alt/display_status", "number")

B747DR_radio_altitude                           = deferred_dataref("laminar/B747/efis/radio_altitude", "number")

B747DR_vertical_speed_fpm                       = deferred_dataref("laminar/B747/vsi/fpm", "number")

B747DR_airspeed_V1                              = deferred_dataref("laminar/B747/airspeed/V1", "number")
B747DR_airspeed_Vr                              = deferred_dataref("laminar/B747/airspeed/Vr", "number")
B747DR_airspeed_V2                              = deferred_dataref("laminar/B747/airspeed/V2", "number")
B747DR_airspeed_Va                              = deferred_dataref("laminar/B747/airspeed/Va", "number")
B747DR_airspeed_Vf0                             = deferred_dataref("laminar/B747/airspeed/Vf0", "number")
B747DR_airspeed_Vf1                             = deferred_dataref("laminar/B747/airspeed/Vf1", "number")
B747DR_airspeed_Vf5                             = deferred_dataref("laminar/B747/airspeed/Vf5", "number")
B747DR_airspeed_Vf10                            = deferred_dataref("laminar/B747/airspeed/Vf10", "number")
B747DR_airspeed_Vf20                            = deferred_dataref("laminar/B747/airspeed/Vf20", "number")
B747DR_airspeed_Vf25                            = deferred_dataref("laminar/B747/airspeed/Vf25", "number")
B747DR_airspeed_Vf30                            = deferred_dataref("laminar/B747/airspeed/Vf30", "number")
B747DR_airspeed_Vfe0                            = deferred_dataref("laminar/B747/airspeed/Vfe0", "number")
B747DR_airspeed_Vfe1                            = deferred_dataref("laminar/B747/airspeed/Vfe1", "number")
B747DR_airspeed_Vfe5                            = deferred_dataref("laminar/B747/airspeed/Vfe2", "number")
B747DR_airspeed_Vfe10                           = deferred_dataref("laminar/B747/airspeed/Vfe10", "number")
B747DR_airspeed_Vfe20                           = deferred_dataref("laminar/B747/airspeed/Vfe20", "number")
B747DR_airspeed_Vfe25                           = deferred_dataref("laminar/B747/airspeed/Vfe25", "number")
B747DR_airspeed_Vfe30                           = deferred_dataref("laminar/B747/airspeed/Vfe30", "number")
B747DR_airspeed_Vlo                             = deferred_dataref("laminar/B747/airspeed/Vlo", "number")
B747DR_airspeed_Mlo                             = deferred_dataref("laminar/B747/airspeed/Mlo", "number")
B747DR_airspeed_Mms                             = deferred_dataref("laminar/B747/airspeed/Mms", "number")
B747DR_airspeed_Vle                             = deferred_dataref("laminar/B747/airspeed/Vle", "number")
B747DR_airspeed_Mle                             = deferred_dataref("laminar/B747/airspeed/Mle", "number")
B747DR_airspeed_Vmo                             = deferred_dataref("laminar/B747/airspeed/Vmo", "number")
B747DR_airspeed_Mmo                             = deferred_dataref("laminar/B747/airspeed/Mmo", "number")
B747DR_airspeed_Vmc                             = deferred_dataref("laminar/B747/airspeed/Vmc", "number")
B747DR_airspeed_Vne                             = deferred_dataref("laminar/B747/airspeed/Vne", "number")
B747DR_airspeed_Mne                             = deferred_dataref("laminar/B747/airspeed/Mne", "number")
B747DR_airspeed_Vref30                          = deferred_dataref("laminar/B747/airspeed/Vref30", "number")
B747DR_airspeed_Vref                          = deferred_dataref("laminar/B747/airspeed/Vref", "number")
B747DR_airspeed_VrefFlap                          = deferred_dataref("laminar/B747/airspeed/VrefFlap", "number")
B747DR_airspeed_showVf25                            = deferred_dataref("laminar/B747/airspeed/showVf25", "number")
B747DR_airspeed_showVf30                            = deferred_dataref("laminar/B747/airspeed/showVf30", "number")
B747DR_airspeed_Vmax                            = deferred_dataref("laminar/B747/airspeed/Vmax", "number")
B747DR_airspeed_Vmaxm                           = deferred_dataref("laminar/B747/airspeed/Vmaxm", "number")
B747DR_airspeed_Vs                              = deferred_dataref("laminar/B747/airspeed/Vs", "number")
simDR_flap_ratio_control                        = find_dataref("sim/cockpit2/controls/flap_ratio")                      -- FLAP HANDLE
B747DR_airspeed_window_min                      = deferred_dataref("laminar/B747/airspeed_window/min", "number")

B747DR_init_inst_CD                             = deferred_dataref("laminar/B747/inst/init_CD", "number")

B747DR_loc_ptr_vis_capt                         = deferred_dataref("laminar/B747/localizer_ptr/visibility_flag_capt", "number")
B747DR_loc_scale_vis_capt                       = deferred_dataref("laminar/B747/localizer_scale/visibility_flag_capt", "number")
B747DR_glideslope_ptr_vis_capt                  = deferred_dataref("laminar/B747/glideslope_ptr/visibility_flag_capt", "number")
B747DR_loc_ptr_vis_fo                           = deferred_dataref("laminar/B747/localizer_ptr/visibility_flag_fo", "number")
B747DR_loc_scale_vis_fo                         = deferred_dataref("laminar/B747/localizer_scale/visibility_flag_fo", "number")
B747DR_glideslope_ptr_vis_fo                    = deferred_dataref("laminar/B747/glideslope_ptr/visibility_flag_fo", "number")

-- crazytimtimtim ( + Matt726)
B747DR_v1_alert                                 = deferred_dataref("laminar/B747/alerts/v1", "number")
B747DR_appDH_alert                              = deferred_dataref("laminar/B747/alerts/appDH", "number")
B747DR_DH_alert                                 = deferred_dataref("laminar/B747/alerts/DH", "number")


--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

simCMD_clock_is_gmt             = find_command("sim/instruments/timer_is_GMT")

simCMD_EFIS_wxr                 = find_command("sim/instruments/EFIS_wxr")
simCMD_EFIS_tcas                = find_command("sim/instruments/EFIS_tcas")

-- simCMD_EFIS_apt                 = find_command("sim/instruments/EFIS_apt")
-- simCMD_EFIS_vor                 = find_command("sim/instruments/EFIS_vor")
-- simCMD_EFIS_ndb                 = find_command("sim/instruments/EFIS_ndb")
simCMD_EFIS_fix                 = find_command("sim/instruments/EFIS_fix")

simDR_EFIS_apt			= find_dataref("sim/cockpit2/EFIS/EFIS_airport_on")
simDR_EFIS_fix 			= find_dataref("sim/cockpit2/EFIS/EFIS_fix_on")
simDR_EFIS_vor 			= find_dataref("sim/cockpit2/EFIS/EFIS_vor_on")
simDR_EFIS_ndb 			= find_dataref("sim/cockpit2/EFIS/EFIS_ndb_on")


--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_autothrottle_disarm                 = find_command("laminar/B747/authrottle_disarm")



--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- FLIGHT DIRECTOR SOURCE SELECTOR (CAPTAIN)
function B747_flt_inst_fd_src_capt_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_fd_src_capt_dial_pos = math.min(B747DR_flt_inst_fd_src_capt_dial_pos+1, 2)
    end
end
function B747_flt_inst_fd_src_capt_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_fd_src_capt_dial_pos = math.max(B747DR_flt_inst_fd_src_capt_dial_pos-1, 0)
    end
end

-- NAV SOURCE SELECTOR (CAPTAIN)
function B747_inst_src_capt_nav_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_nav_src_capt_dial_pos = math.min(B747DR_flt_inst_nav_src_capt_dial_pos+1, 3)
    end
end
function B747_inst_src_capt_nav_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_nav_src_capt_dial_pos = math.max(B747DR_flt_inst_nav_src_capt_dial_pos-1, 0)
    end
end

-- EIU SOURCE SELECTOR (CAPTAIN)
function B747_inst_src_capt_eiu_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_eiu_src_capt_dial_pos = math.min(B747DR_flt_inst_eiu_src_capt_dial_pos+1, 3)
    end
end
function B747_inst_src_capt_eiu_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_eiu_src_capt_dial_pos = math.max(B747DR_flt_inst_eiu_src_capt_dial_pos-1, 0)
    end
end

-- IRS SOURCE SELECTOR (CAPTAIN)
function B747_inst_src_capt_irs_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_irs_src_capt_dial_pos = math.min(B747DR_flt_inst_irs_src_capt_dial_pos+1, 2)
    end
end
function B747_inst_src_capt_irs_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_irs_src_capt_dial_pos = math.max(B747DR_flt_inst_irs_src_capt_dial_pos-1, 0)
    end
end

-- AIR DATA SOURCE SELECTOR (CAPTAIN)
function B747_inst_src_capt_air_data_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_air_data_src_capt_dial_pos = math.min(B747DR_flt_inst_air_data_src_capt_dial_pos+1, 1)
    end
end
function B747_inst_src_capt_air_data_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_air_data_src_capt_dial_pos = math.max(B747DR_flt_inst_air_data_src_capt_dial_pos-1, 0)
    end
end





-- FLIGHT DIRECTOR SOURCE SELECTOR (FIRST OFFICER)
function B747_flt_inst_fd_src_fo_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_fd_src_fo_dial_pos = math.min(B747DR_flt_inst_fd_src_fo_dial_pos+1, 2)
    end
end
function B747_flt_inst_fd_src_fo_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_fd_src_fo_dial_pos = math.max(B747DR_flt_inst_fd_src_fo_dial_pos-1, 0)
    end
end

-- NAV SOURCE SELECTOR (FIRST OFFICER)
function B747_inst_src_fo_nav_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_nav_src_fo_dial_pos = math.min(B747DR_flt_inst_nav_src_fo_dial_pos+1, 3)
    end
end
function B747_inst_src_fo_nav_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_nav_src_fo_dial_pos = math.max(B747DR_flt_inst_nav_src_fo_dial_pos-1, 0)
    end
end

-- EIU SOURCE SELECTOR (FIRST OFFICER)
function B747_inst_src_fo_eiu_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_eiu_src_fo_dial_pos = math.min(B747DR_flt_inst_eiu_src_fo_dial_pos+1, 3)
    end
end
function B747_inst_src_fo_eiu_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_eiu_src_fo_dial_pos = math.max(B747DR_flt_inst_eiu_src_fo_dial_pos-1, 0)
    end
end

-- IRS SOURCE SELECTOR (FIRST OFFICER)
function B747_inst_src_fo_irs_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_irs_src_fo_dial_pos = math.min(B747DR_flt_inst_irs_src_fo_dial_pos+1, 2)
    end
end
function B747_inst_src_fo_irs_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_irs_src_fo_dial_pos = math.max(B747DR_flt_inst_irs_src_fo_dial_pos-1, 0)
    end
end

-- AIR DATA SOURCE SELECTOR (FIRST OFFICER)
function B747_inst_src_fo_air_data_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_air_data_src_fo_dial_pos = math.min(B747DR_flt_inst_air_data_src_fo_dial_pos+1, 1)
    end
end
function B747_inst_src_fo_air_data_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_air_data_src_fo_dial_pos = math.max(B747DR_flt_inst_air_data_src_fo_dial_pos-1, 0)
    end
end





-- EIU SOURCE SELECTOR (CENTER PANEL)
function B747_flt_inst_eiu_src_ctr_pnl_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_eiu_src_ctr_pnl_dial_pos = math.min(B747DR_flt_inst_eiu_src_ctr_pnl_dial_pos+1, 3)
    end
end
function B747_flt_inst_eiu_src_ctr_pnl_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_eiu_src_ctr_pnl_dial_pos = math.max(B747DR_flt_inst_eiu_src_ctr_pnl_dial_pos-1, 0)
    end
end

--  FMC MASTER SELECTOR (CENTER PANEL)
function B747_flt_inst_fmc_master_src_ctr_pnl_sel_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_fmc_master_src_ctr_pnl_sel_pos = 1.0 - B747DR_flt_inst_fmc_master_src_ctr_pnl_sel_pos
        simDR_autopilot_source = B747DR_flt_inst_fmc_master_src_ctr_pnl_sel_pos                               -- TODO:  VERIFY WITH HOW TO SWITCH NAV1/NAV2 (HSI SOURCE SEL)
        B747CMD_autothrottle_disarm:once()
    end
end






-- DISPLAY SELECTOR (CAPTAIN)
function B747_flt_inst_inbd_disp_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_inbd_disp_capt_sel_dial_pos = math.min(B747DR_flt_inst_inbd_disp_capt_sel_dial_pos+1, 2)
    end
end
function B747_flt_inst_inbd_disp_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_inbd_disp_capt_sel_dial_pos = math.max(B747DR_flt_inst_inbd_disp_capt_sel_dial_pos-1, 0)
    end
end

function B747_flt_inst_lwr_disp_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_lwr_disp_capt_sel_dial_pos = math.min(B747DR_flt_inst_lwr_disp_capt_sel_dial_pos+1, 2)
    end
end
function B747_flt_inst_lwr_disp_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_lwr_disp_capt_sel_dial_pos = math.max(B747DR_flt_inst_lwr_disp_capt_sel_dial_pos-1, 0)
    end
end





-- DISPLAY SELECTOR (FIRST OFFICER)
function B747_flt_inst_inbd_disp_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_inbd_disp_fo_sel_dial_pos = math.min(B747DR_flt_inst_inbd_disp_fo_sel_dial_pos+1, 2)
    end
end
function B747_flt_inst_inbd_disp_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_inbd_disp_fo_sel_dial_pos = math.max(B747DR_flt_inst_inbd_disp_fo_sel_dial_pos-1, 0)
    end
end

function B747_flt_inst_lwr_disp_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_lwr_disp_fo_sel_dial_pos = math.min(B747DR_flt_inst_lwr_disp_fo_sel_dial_pos+1, 2)
    end
end
function B747_flt_inst_lwr_disp_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_flt_inst_lwr_disp_fo_sel_dial_pos = math.max(B747DR_flt_inst_lwr_disp_fo_sel_dial_pos-1, 0)
    end
end





-- EFIS CONTROLS (CAPTAIN)
function B747_efis_min_ref_alt_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_min_ref_alt_capt_sel_dial_pos = math.min(B747DR_efis_min_ref_alt_capt_sel_dial_pos + 1, 1)
    end
end

function B747_efis_min_ref_alt_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_min_ref_alt_capt_sel_dial_pos = math.max(B747DR_efis_min_ref_alt_capt_sel_dial_pos - 1, 0)
    end
end


function B747_efis_ref_alt_capt_set_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_ref_alt_capt_set_dial_pos = B747DR_efis_ref_alt_capt_set_dial_pos + 0.1
        if B747DR_efis_min_ref_alt_capt_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_capt = simDR_radio_alt_DH_capt + 1.0
        elseif B747DR_efis_min_ref_alt_capt_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_capt = B747DR_efis_baro_alt_ref_capt + 1.0
        end
    elseif phase == 1 and duration > 1.0 then
        B747DR_efis_ref_alt_capt_set_dial_pos = B747DR_efis_ref_alt_capt_set_dial_pos + 0.1
        if B747DR_efis_min_ref_alt_capt_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_capt = simDR_radio_alt_DH_capt + 10.0
        elseif B747DR_efis_min_ref_alt_capt_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_capt = B747DR_efis_baro_alt_ref_capt + 10.0
        end
    end
end

function B747_efis_ref_alt_capt_set_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_ref_alt_capt_set_dial_pos = B747DR_efis_ref_alt_capt_set_dial_pos - 0.1
        if B747DR_efis_min_ref_alt_capt_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_capt = math.max(simDR_radio_alt_DH_capt - 1.0,-1)
        elseif B747DR_efis_min_ref_alt_capt_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_capt = B747DR_efis_baro_alt_ref_capt - 1.0
        end
    elseif phase == 1 and duration > 1.0 then
        B747DR_efis_ref_alt_capt_set_dial_pos = B747DR_efis_ref_alt_capt_set_dial_pos - 0.1
        if B747DR_efis_min_ref_alt_capt_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_capt = math.max(simDR_radio_alt_DH_capt - 10.0,-1)
        elseif B747DR_efis_min_ref_alt_capt_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_capt = B747DR_efis_baro_alt_ref_capt - 10.0
        end
    end
end


function B747_efis_dh_capt_reset_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_dh_reset_capt_switch_pos = 1
        simDR_radio_alt_DH_capt=350
        B747DR_efis_baro_alt_ref_capt=1000
        simDR_radio_alt_DH_fo=350
        B747DR_efis_baro_alt_ref_fo=1000
    elseif phase == 2 then
        B747DR_efis_dh_reset_capt_switch_pos = 0
    end
end

function B747_efis_baro_ref_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_ref_capt_sel_dial_pos = math.min(B747DR_efis_baro_ref_capt_sel_dial_pos + 1, 1)
    end
end

function B747_efis_baro_ref_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_ref_capt_sel_dial_pos = math.max(B747DR_efis_baro_ref_capt_sel_dial_pos - 1, 0)
    end
end

function B747_efis_baro_set_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_capt_set_dial_pos = B747DR_efis_baro_capt_set_dial_pos + 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_capt_switch_pos == 0 then
            simDR_altimeter_baro_inHg = math.min(34.00, simDR_altimeter_baro_inHg + 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 0
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_capt_switch_pos == 1 then
            B747DR_efis_baro_capt_preselect = math.min(34.00, B747DR_efis_baro_capt_preselect + 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 1
        end
    elseif phase == 1 and duration > 0.5 then 
        B747DR_efis_baro_capt_set_dial_pos = B747DR_efis_baro_capt_set_dial_pos + 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_capt_switch_pos == 0 then
            simDR_altimeter_baro_inHg = math.min(34.00, simDR_altimeter_baro_inHg + 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 0
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_capt_switch_pos == 1 then
            B747DR_efis_baro_capt_preselect = math.min(34.00, B747DR_efis_baro_capt_preselect + 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 1
        end
    end
end

function B747_efis_baro_set_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_capt_set_dial_pos = B747DR_efis_baro_capt_set_dial_pos - 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_capt_switch_pos == 0 then
            simDR_altimeter_baro_inHg = math.max(26.00, simDR_altimeter_baro_inHg - 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 0
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_capt_switch_pos == 1 then
            B747DR_efis_baro_capt_preselect = math.max(26.00, B747DR_efis_baro_capt_preselect - 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 1
        end
    elseif phase == 1 and duration > 0.5 then  
        B747DR_efis_baro_capt_set_dial_pos = B747DR_efis_baro_capt_set_dial_pos - 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_capt_switch_pos == 0 then
            simDR_altimeter_baro_inHg = math.max(26.00, simDR_altimeter_baro_inHg - 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 0
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_capt_switch_pos == 1 then
            B747DR_efis_baro_capt_preselect = math.max(26.00, B747DR_efis_baro_capt_preselect - 0.01)
            B747DR_efis_baro_std_capt_show_preselect = 1
        end
    end
end


function B747_efis_baro_std_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_std_capt_switch_pos = 1.0 -  B747DR_efis_baro_std_capt_switch_pos
        if B747DR_efis_baro_std_capt_switch_pos == 0 then
            simDR_altimeter_baro_inHg = B747DR_efis_baro_capt_preselect
            B747DR_efis_baro_std_capt_show_preselect = 0
        elseif B747DR_efis_baro_std_capt_switch_pos == 1 then
            simDR_altimeter_baro_inHg = 29.92
            B747DR_efis_baro_capt_preselect = 29.92
            B747DR_efis_baro_std_capt_show_preselect = 0
        end
    end
end



function B747_efis_fpv_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_fpv_capt_switch_pos = 1
    elseif phase == 2 then
        B747DR_efis_fpv_capt_switch_pos = 0
    end
end


function B747_efis_meters_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_meters_capt_switch_pos = 1
        B747DR_efis_meters_capt_selected = 1.0 - B747DR_efis_meters_capt_selected
    elseif phase == 2 then
        B747DR_efis_meters_capt_switch_pos = 0
    end
end






-- EFIS CONTROLS (FIRST OFFICER)
function B747_efis_min_ref_alt_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_min_ref_alt_fo_sel_dial_pos = math.min(B747DR_efis_min_ref_alt_fo_sel_dial_pos+1, 1)
    end
end

function B747_efis_min_ref_alt_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_min_ref_alt_fo_sel_dial_pos = math.max(B747DR_efis_min_ref_alt_fo_sel_dial_pos-1, 0)
    end
end


function B747_efis_ref_alt_fo_set_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_ref_alt_fo_set_dial_pos = B747DR_efis_ref_alt_fo_set_dial_pos + 0.1
        if B747DR_efis_min_ref_alt_fo_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_fo = simDR_radio_alt_DH_fo + 1.0
        elseif B747DR_efis_min_ref_alt_fo_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_fo = B747DR_efis_baro_alt_ref_fo + 1.0
        end
    elseif phase == 1 and duration > 1.0 then
        B747DR_efis_ref_alt_fo_set_dial_pos = B747DR_efis_ref_alt_fo_set_dial_pos + 0.1
        if B747DR_efis_min_ref_alt_fo_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_fo = simDR_radio_alt_DH_fo + 10.0
        elseif B747DR_efis_min_ref_alt_fo_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_fo = B747DR_efis_baro_alt_ref_fo + 10.0
        end
    end
end

function B747_efis_ref_alt_fo_set_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_ref_alt_fo_set_dial_pos = B747DR_efis_ref_alt_fo_set_dial_pos - 0.1
        if B747DR_efis_min_ref_alt_fo_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_fo = math.max(simDR_radio_alt_DH_fo - 1.0,-1)
        elseif B747DR_efis_min_ref_alt_fo_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_fo = B747DR_efis_baro_alt_ref_fo - 1.0
        end
    elseif phase == 1 and duration > 1.0 then
        B747DR_efis_ref_alt_fo_set_dial_pos = B747DR_efis_ref_alt_fo_set_dial_pos - 0.1
        if B747DR_efis_min_ref_alt_fo_sel_dial_pos == 0 then                                          -- RADIO ALT
            simDR_radio_alt_DH_fo = math.max(simDR_radio_alt_DH_fo - 10.0,-1)
        elseif B747DR_efis_min_ref_alt_fo_sel_dial_pos == 1 then                                      -- BARO ALT
            B747DR_efis_baro_alt_ref_fo = B747DR_efis_baro_alt_ref_fo - 10.0
        end
    end
end


function B747_efis_dh_fo_reset_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_dh_reset_fo_switch_pos = 1
        B747DR_efis_dh_reset_capt_switch_pos = 1
        simDR_radio_alt_DH_capt=350
        B747DR_efis_baro_alt_ref_capt=1000
        simDR_radio_alt_DH_fo=350
        B747DR_efis_baro_alt_ref_fo=1000
    elseif phase == 2 then
        B747DR_efis_dh_reset_fo_switch_pos = 0
    end
end

function B747_efis_baro_ref_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_ref_fo_sel_dial_pos = math.min(B747DR_efis_baro_ref_fo_sel_dial_pos + 1, 1)
    end
end

function B747_efis_baro_ref_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_ref_fo_sel_dial_pos = math.max(B747DR_efis_baro_ref_fo_sel_dial_pos - 1, 0)
    end
end

function B747_efis_baro_set_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_fo_set_dial_pos = B747DR_efis_baro_fo_set_dial_pos + 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_fo_switch_pos == 0 then
            simDR_altimeter_baro_inHg_fo = math.min(34.00, simDR_altimeter_baro_inHg_fo + 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 0 
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_fo_switch_pos == 1 then
            B747DR_efis_baro_fo_preselect = math.min(34.00, B747DR_efis_baro_fo_preselect + 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 1
        end
    elseif phase == 1 and duration > 0.5 then
        B747DR_efis_baro_fo_set_dial_pos = B747DR_efis_baro_fo_set_dial_pos + 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_fo_switch_pos == 0 then
            simDR_altimeter_baro_inHg_fo = math.min(34.00, simDR_altimeter_baro_inHg_fo + 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 0 
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_fo_switch_pos == 1 then
            B747DR_efis_baro_fo_preselect = math.min(34.00, B747DR_efis_baro_fo_preselect + 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 1
        end
    end
end

function B747_efis_baro_set_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_fo_set_dial_pos = B747DR_efis_baro_fo_set_dial_pos - 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_fo_switch_pos == 0 then
            simDR_altimeter_baro_inHg_fo = math.max(26.00, simDR_altimeter_baro_inHg_fo - 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 0
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_fo_switch_pos == 1 then
            B747DR_efis_baro_fo_preselect = math.max(26.00, B747DR_efis_baro_fo_preselect - 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 1
        end
    elseif phase == 1 and duration > 0.5 then
        B747DR_efis_baro_fo_set_dial_pos = B747DR_efis_baro_fo_set_dial_pos - 0.01
        -- NORMAL BARO ADJUST
        if B747DR_efis_baro_std_fo_switch_pos == 0 then
            simDR_altimeter_baro_inHg_fo = math.max(26.00, simDR_altimeter_baro_inHg_fo - 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 0
        -- PRESELECT BARO ADJUST
        elseif B747DR_efis_baro_std_fo_switch_pos == 1 then
            B747DR_efis_baro_fo_preselect = math.max(26.00, B747DR_efis_baro_fo_preselect - 0.01)
            B747DR_efis_baro_std_fo_show_preselect = 1
        end
    end
end


function B747_efis_baro_std_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_baro_std_fo_switch_pos = 1.0 -  B747DR_efis_baro_std_fo_switch_pos
        if B747DR_efis_baro_std_fo_switch_pos == 0 then
            simDR_altimeter_baro_inHg_fo = B747DR_efis_baro_fo_preselect
            B747DR_efis_baro_std_fo_show_preselect = 0
        elseif B747DR_efis_baro_std_fo_switch_pos == 1 then
            simDR_altimeter_baro_inHg_fo = 29.92
            B747DR_efis_baro_fo_preselect = 29.92
            B747DR_efis_baro_std_fo_show_preselect = 0
        end
    end
end



function B747_efis_fpv_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_fpv_fo_switch_pos = 1
    elseif phase == 2 then
        B747DR_efis_fpv_fo_switch_pos = 0
    end
end


function B747_efis_meters_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_efis_meters_fo_switch_pos = 1
        B747DR_efis_meters_fo_selected = 1.0 - B747DR_efis_meters_fo_selected
    elseif phase == 2 then
        B747DR_efis_meters_fo_switch_pos = 0
    end
end





-- ND CONTROLS
local B747_center_status_old = 0
function B747_nd_mode_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747_center_status_old = B747_nd_map_center_capt
        B747DR_nd_mode_capt_sel_dial_pos = math.min(B747DR_nd_mode_capt_sel_dial_pos+1, 3)
        
        if B747DR_nd_mode_capt_sel_dial_pos == 3 then
            simDR_EFIS_map_mode = 4
            B747_nd_map_center_capt = B747_center_status_old
            --B747_nd_map_center_capt = 1
        else
            B747_nd_map_center_capt = B747_center_status_old
            simDR_EFIS_map_mode = 1 --math.min(B747DR_nd_mode_capt_sel_dial_pos,1)
        end
        -- TODO:  ADD ELEMENTS STATUS BASED ON MODE
    end
end

function B747_nd_mode_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747_center_status_old = B747_nd_map_center_capt
        B747DR_nd_mode_capt_sel_dial_pos = math.max(B747DR_nd_mode_capt_sel_dial_pos-1, 0)
        
        if B747DR_nd_mode_capt_sel_dial_pos == 3 then
            simDR_EFIS_map_mode = 4
            --B747_nd_map_center_capt = 1
            B747_nd_map_center_capt = B747_center_status_old
        else
            
            simDR_EFIS_map_mode = 1 --math.max(B747DR_nd_mode_capt_sel_dial_pos,1)
        end
    end
end


function B747_nd_range_capt_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_range_capt_sel_dial_pos = math.min(B747DR_nd_range_capt_sel_dial_pos+1, 6)
        simDR_EFIS_map_range = B747DR_nd_range_capt_sel_dial_pos
        B747DR_nd_range_fo_sel_dial_pos = B747DR_nd_range_capt_sel_dial_pos
    end
end

function B747_nd_range_capt_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_range_capt_sel_dial_pos = math.max(B747DR_nd_range_capt_sel_dial_pos-1, 0)
        simDR_EFIS_map_range = B747DR_nd_range_capt_sel_dial_pos
        B747DR_nd_range_fo_sel_dial_pos = B747DR_nd_range_capt_sel_dial_pos
    end
end


function B747_nd_center_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_center_capt_switch_pos = 1
        if B747DR_nd_mode_capt_sel_dial_pos < 3 then
            B747_nd_map_center_capt = 1.0 - B747_nd_map_center_capt
            --B747_nd_map_center_fo = B747_nd_map_center_capt
        end
    elseif phase == 2 then
        B747DR_nd_center_capt_switch_pos = 0
    end
end


function B747_nd_traffic_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_traffic_capt_switch_pos = 1
        --simCMD_EFIS_tcas:once()
        B747DR_nd_capt_traffic_Selected=1-B747DR_nd_capt_traffic_Selected
	
    elseif phase == 2 then
        B747DR_nd_traffic_capt_switch_pos = 0
    end
end




function B747_nd_wxr_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_wxr_capt_switch_pos = 1
        simCMD_EFIS_wxr:once()
    elseif phase == 2 then
        B747DR_nd_wxr_capt_switch_pos = 0
    end
end

function B747_nd_sta_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_sta_capt_switch_pos = 1
        --simCMD_EFIS_vor:once()
        --simCMD_EFIS_ndb:once()
        B747DR_nd_capt_vor_ndb = 1.0 - B747DR_nd_capt_vor_ndb
    elseif phase == 2 then
        B747DR_nd_sta_capt_switch_pos = 0
    end
end

function B747_nd_wpt_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_wpt_capt_switch_pos = 1
        B747DR_nd_capt_wpt = 1.0 - B747DR_nd_capt_wpt
    elseif phase == 2 then
        B747DR_nd_wpt_capt_switch_pos = 0
    end
end

function B747_nd_arpt_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_arpt_capt_switch_pos = 1
        --simCMD_EFIS_apt:once()
	B747DR_nd_capt_apt = 1.0 - B747DR_nd_capt_apt
    elseif phase == 2 then
        B747DR_nd_arpt_capt_switch_pos = 0
    end
end

function B747_nd_data_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_data_capt_switch_pos = 1
    elseif phase == 2 then
        B747DR_nd_data_capt_switch_pos = 0
    end
end

function B747_nd_pos_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_pos_capt_switch_pos = 1
    elseif phase == 2 then
        B747DR_nd_pos_capt_switch_pos = 0
    end
end

function B747_nd_terr_capt_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_terr_capt_switch_pos = 1
    elseif phase == 2 then
        B747DR_nd_terr_capt_switch_pos = 0
    end
end







function B747_nd_mode_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        --B747_center_status_old = B747_nd_map_center_capt
	B747_center_status_old = B747_nd_map_center_fo
        B747DR_nd_mode_fo_sel_dial_pos = math.min(B747DR_nd_mode_fo_sel_dial_pos+1, 3)
        --B747DR_nd_mode_capt_sel_dial_pos = B747DR_nd_mode_fo_sel_dial_pos
        
        if B747DR_nd_mode_fo_sel_dial_pos == 3 then
            simDR_EFIS_map_mode = 4
            --B747_nd_map_center_fo = 1
            --B747_nd_map_center_capt = B747_nd_map_center_fo
        else
            B747_nd_map_center_fo = B747_center_status_old
            simDR_EFIS_map_mode =1 -- math.max(B747DR_nd_mode_fo_sel_dial_pos,1)
            --B747_nd_map_center_capt = B747_nd_map_center_fo
        end
        -- TODO:  ADD ELEMENTS STATUS BASED ON MODE
    end
end

function B747_nd_mode_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
	B747_center_status_old = B747_nd_map_center_fo
        B747DR_nd_mode_fo_sel_dial_pos = math.max(B747DR_nd_mode_fo_sel_dial_pos-1, 0)
       -- B747DR_nd_mode_capt_sel_dial_pos = B747DR_nd_mode_fo_sel_dial_pos
        
        if B747DR_nd_mode_fo_sel_dial_pos == 3 then
            simDR_EFIS_map_mode = 4
            --B747_nd_map_center_fo = 1
           -- B747_nd_map_center_capt = B747_nd_map_center_fo
        else
            B747_nd_map_center_fo = B747_center_status_old
            simDR_EFIS_map_mode =1 -- math.max(B747DR_nd_mode_fo_sel_dial_pos,1)
           -- B747_nd_map_center_capt = B747_nd_map_center_capt
        end
    end
end


function B747_nd_range_fo_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_range_fo_sel_dial_pos = math.min(B747DR_nd_range_fo_sel_dial_pos+1, 6)
        simDR_EFIS_map_range = B747DR_nd_range_fo_sel_dial_pos
        B747DR_nd_range_capt_sel_dial_pos = B747DR_nd_range_fo_sel_dial_pos
    end
end

function B747_nd_range_fo_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_range_fo_sel_dial_pos = math.max(B747DR_nd_range_fo_sel_dial_pos-1, 0)
        simDR_EFIS_map_range = B747DR_nd_range_fo_sel_dial_pos
        B747DR_nd_range_capt_sel_dial_pos = B747DR_nd_range_fo_sel_dial_pos
    end
end



function B747_nd_center_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_center_fo_switch_pos = 1
        if B747DR_nd_mode_fo_sel_dial_pos < 3 then
            B747_nd_map_center_fo = 1.0 - B747_nd_map_center_fo
            --B747_nd_map_center_capt = B747_nd_map_center_fo
        end
    elseif phase == 2 then
        B747DR_nd_center_fo_switch_pos = 0
    end
end

function B747_nd_traffic_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_traffic_fo_switch_pos = 1
        --simCMD_EFIS_tcas:once()
	
        B747DR_nd_fo_traffic_Selected=1-B747DR_nd_fo_traffic_Selected
	
    elseif phase == 2 then
        B747DR_nd_traffic_fo_switch_pos = 0
    end
end



function B747_nd_wxr_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_wxr_fo_switch_pos = 1
        simCMD_EFIS_wxr:once()
    elseif phase == 2 then
        B747DR_nd_wxr_fo_switch_pos = 0
    end
end

function B747_nd_sta_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_sta_fo_switch_pos = 1
        --simCMD_EFIS_vor:once()
        --simCMD_EFIS_ndb:once()
        B747DR_nd_fo_vor_ndb = 1.0 - B747DR_nd_fo_vor_ndb
	
    elseif phase == 2 then
        B747DR_nd_sta_fo_switch_pos = 0
    end
end

function B747_nd_wpt_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_wpt_fo_switch_pos = 1
        B747DR_nd_fo_wpt = 1.0 - B747DR_nd_fo_wpt
    elseif phase == 2 then
        B747DR_nd_wpt_fo_switch_pos = 0
    end
end

function B747_nd_arpt_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_arpt_fo_switch_pos = 1
        --simCMD_EFIS_apt:once()
	B747DR_nd_fo_apt = 1.0 - B747DR_nd_fo_apt
    elseif phase == 2 then
        B747DR_nd_arpt_fo_switch_pos = 0
    end
end

function B747_nd_data_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_data_fo_switch_pos = 1
    elseif phase == 2 then
        B747DR_nd_data_fo_switch_pos = 0
    end
end

function B747_nd_pos_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_pos_fo_switch_pos = 1
    elseif phase == 2 then
        B747DR_nd_pos_fo_switch_pos = 0
    end
end

function B747_nd_terr_fo_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_nd_terr_fo_switch_pos = 1
    elseif phase == 2 then
        B747DR_nd_terr_fo_switch_pos = 0
    end
end




-- DISPLAY SELECT PANEL
function B747_dsp_eng_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_eng_switch_pos = 1
        if B747DR_dsp_synoptic_display == 1 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 1 end
    elseif phase == 2 then
        B747DR_dsp_eng_switch_pos = 0
    end
end

function B747_dsp_stat_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_stat_switch_pos = 1
        if B747DR_dsp_synoptic_display == 2 then
            if B747DR_STAT_msg_page == B747DR_STAT_num_msg_pages then
                B747DR_dsp_synoptic_display = 0
            else
                B747DR_STAT_msg_page = B747DR_STAT_msg_page + 1
            end
        else
            B747DR_dsp_synoptic_display = 2
            B747DR_STAT_msg_page = 1
        end
    elseif phase == 2 then
        B747DR_dsp_stat_switch_pos = 0
    end
end

function B747_dsp_elec_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_elec_switch_pos = 1
        if B747DR_dsp_synoptic_display == 3 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 3 end
    elseif phase == 2 then
        B747DR_dsp_elec_switch_pos = 0
    end
end

function B747_dsp_fuel_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_fuel_switch_pos = 1
        if B747DR_dsp_synoptic_display == 4 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 4 end
    elseif phase == 2 then
        B747DR_dsp_fuel_switch_pos = 0
    end
end

function B747_dsp_ecs_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_ecs_switch_pos = 1
        if B747DR_dsp_synoptic_display == 5 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 5 end
    elseif phase == 2 then
        B747DR_dsp_ecs_switch_pos = 0
    end
end

function B747_dsp_hyd_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_hyd_switch_pos = 1
        if B747DR_dsp_synoptic_display == 6 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 6 end
    elseif phase == 2 then
        B747DR_dsp_hyd_switch_pos = 0
    end
end

function B747_dsp_drs_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_drs_switch_pos = 1
        if B747DR_dsp_synoptic_display == 7 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 7 end
    elseif phase == 2 then
        B747DR_dsp_drs_switch_pos = 0
    end
end

function B747_dsp_gear_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_gear_switch_pos = 1
        if B747DR_dsp_synoptic_display == 8 then B747DR_dsp_synoptic_display = 0 else B747DR_dsp_synoptic_display = 8 end
    elseif phase == 2 then
        B747DR_dsp_gear_switch_pos = 0
    end
end

function B747_dsp_canc_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_canc_switch_pos = 1
        if B747DR_CAS_msg_page == B747DR_CAS_num_msg_pages then
            B747DR_CAS_msg_page = 1
            B747DR_CAS_caut_adv_display = 0
        else
            B747DR_CAS_msg_page = math.min(B747DR_CAS_num_msg_pages, B747DR_CAS_msg_page + 1)
        end
    elseif phase == 2 then
        B747DR_dsp_canc_switch_pos = 0
    end
end



function B747_CAS_canx_recall_display()
    B747DR_CAS_recall_ind = 0
end

function B747_dsp_rcl_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_dsp_rcl_switch_pos = 1
        B747DR_CAS_msg_page = 1
        B747DR_CAS_caut_adv_display = 1
        B747DR_CAS_recall_ind = 1
    elseif phase == 2 then
        B747DR_dsp_rcl_switch_pos = 0
        if is_timer_scheduled(B747_CAS_canx_recall_display) == false then
            run_after_time(B747_CAS_canx_recall_display, 1.0)
        else
            stop_timer(B747_CAS_canx_recall_display)
            run_after_time(B747_CAS_canx_recall_display, 1.0)
        end
    end
end


--[[

-- CLOCK (CAPTAIN) 
function B747_clock_captain_chrono_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_captain_chrono_switch_pos = 1
        if B747DR_clock_captain_chrono_mode == B747_START then
            B747DR_clock_captain_chrono_mode = B747_STOP
        elseif B747DR_clock_captain_chrono_mode == B747_STOP then
            B747DR_clock_captain_chrono_mode = B747_RESET
        elseif B747DR_clock_captain_chrono_mode == B747_RESET then
            B747DR_clock_captain_chrono_mode = B747_START
        end
    elseif phase == 2 then
        B747DR_clock_captain_chrono_switch_pos = 0
    end
end

function B747_glareshield_captain_chrono_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_glrshld_captain_chrono_switch_pos = 1
        if B747DR_clock_captain_chrono_mode == B747_START then
            B747DR_clock_captain_chrono_mode = B747_STOP
        elseif B747DR_clock_captain_chrono_mode == B747_STOP then
            B747DR_clock_captain_chrono_mode = B747_RESET
        elseif B747DR_clock_captain_chrono_mode == B747_RESET then
            B747DR_clock_captain_chrono_mode = B747_START
        end
    elseif phase == 2 then
        B747DR_glrshld_captain_chrono_switch_pos = 0
    end
end

function B747_clock_captain_et_sel_switch_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_captain_et_sel_switch_pos = math.min(B747DR_clock_captain_et_sel_switch_pos+1, 1)
        if B747DR_clock_captain_et_sel_switch_pos == 0 then
            B747DR_clock_captain_et_mode = B747_HOLD
        elseif B747DR_clock_captain_et_sel_switch_pos == 1 then
            B747DR_clock_captain_et_mode = B747_RUN
        end
    end
end

function B747_clock_captain_et_sel_switch_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_captain_et_sel_switch_pos = math.max(B747DR_clock_captain_et_sel_switch_pos-1, -1)
        if B747DR_clock_captain_et_sel_switch_pos == 0 then
            B747DR_clock_captain_et_mode = B747_HOLD
        elseif B747DR_clock_captain_et_sel_switch_pos == -1 then
            B747DR_clock_captain_et_mode = B747_RESET
        end
    elseif phase == 2 then
        if B747DR_clock_captain_et_sel_switch_pos == -1 then
            B747DR_clock_captain_et_sel_switch_pos = 0
            B747DR_clock_captain_et_mode = B747_HOLD
        end
    end

end

function B747_clock_captain_date_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_captain_date_switch_pos = 1
        B747DR_clock_captain_gmt_display_mode = 1.0 - B747DR_clock_captain_gmt_display_mode
    elseif phase == 2 then
        B747DR_clock_captain_date_switch_pos = 0
    end
end

function B747_clock_captain_set_switch_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_captain_set_switch_pos = math.min(B747DR_clock_captain_set_switch_pos+1, 3)
    end
end

function B747_clock_captain_set_switch_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_captain_set_switch_pos = math.max(B747DR_clock_captain_set_switch_pos-1, 0)
    end
end





-- CLOCK (FIRST OFFICER) 
function B747_clock_fo_chrono_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_fo_chrono_switch_pos = 1
        if B747DR_clock_fo_chrono_mode == B747_START then
            B747DR_clock_fo_chrono_mode = B747_STOP
        elseif B747DR_clock_fo_chrono_mode == B747_STOP then
            B747DR_clock_fo_chrono_mode = B747_RESET
        elseif B747DR_clock_fo_chrono_mode == B747_RESET then
            B747DR_clock_fo_chrono_mode = B747_START
        end
    elseif phase == 2 then
        B747DR_clock_fo_chrono_switch_pos = 0
    end
end

function B747_glareshield_fo_chrono_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_glrshld_fo_chrono_switch_pos = 1
        if B747DR_clock_fo_chrono_mode == B747_START then
            B747DR_clock_fo_chrono_mode = B747_STOP
        elseif B747DR_clock_fo_chrono_mode == B747_STOP then
            B747DR_clock_fo_chrono_mode = B747_RESET
        elseif B747DR_clock_fo_chrono_mode == B747_RESET then
            B747DR_clock_fo_chrono_mode = B747_START
        end
    elseif phase == 2 then
        B747DR_glrshld_fo_chrono_switch_pos = 0
    end
end

function B747_clock_fo_et_sel_switch_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_fo_et_sel_switch_pos = math.min(B747DR_clock_fo_et_sel_switch_pos+1, 1)
        if B747DR_clock_fo_et_sel_switch_pos == 0 then
            B747DR_clock_fo_et_mode = B747_HOLD
        elseif B747DR_clock_fo_et_sel_switch_pos == 1 then
            B747DR_clock_fo_et_mode = B747_RUN
        end
    end
end

function B747_clock_fo_et_sel_switch_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_fo_et_sel_switch_pos = math.max(B747DR_clock_fo_et_sel_switch_pos-1, -1)
        if B747DR_clock_fo_et_sel_switch_pos == 0 then
            B747DR_clock_fo_et_mode = B747_HOLD
        elseif B747DR_clock_fo_et_sel_switch_pos == -1 then
            B747DR_clock_fo_et_mode = B747_RESET
        end
    elseif phase == 2 then
        if B747DR_clock_fo_et_sel_switch_pos == -1 then
            B747DR_clock_fo_et_sel_switch_pos = 0
            B747DR_clock_fo_et_mode = B747_HOLD
        end
    end

end

function B747_clock_fo_date_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_fo_date_switch_pos = 1
        B747DR_clock_fo_gmt_display_mode = 1.0 - B747DR_clock_fo_gmt_display_mode
    elseif phase == 2 then
        B747DR_clock_fo_date_switch_pos = 0
    end
end

function B747_clock_fo_set_switch_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_fo_set_switch_pos = math.min(B747DR_clock_fo_set_switch_pos+1, 3)
    end
end

function B747_clock_fo_set_switch_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_clock_fo_set_switch_pos = math.max(B747DR_clock_fo_set_switch_pos-1, 0)
    end
end
--]]




function B747_ai_fltinst_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
    	 B747_set_inst_all_modes()
    	 B747_set_inst_CD()
    	 B747_set_inst_ER()  
    end
end




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- INSTRUMENT SOURCE SELECTORS (CAPTAIN)
B747CMD_flt_inst_fd_src_capt_dial_up        = deferred_command("laminar/B747/flt_inst/flt_dir_src/capt/sel_dial_up", "Flight Inst Flight Director Source Captain Up", B747_flt_inst_fd_src_capt_dial_up_CMDhandler)
B747CMD_flt_inst_fd_src_capt_dial_dn        = deferred_command("laminar/B747/flt_inst/flt_dir_src/capt/sel_dial_dn", "Flight Inst Flight Director Source Captain Down", B747_flt_inst_fd_src_capt_dial_dn_CMDhandler)

B747CMD_flt_inst_nav_src_capt_dial_up       = deferred_command("laminar/B747/flt_inst/nav_src/capt/sel_dial_up", "Flight Inst NAV Source Captain Up", B747_inst_src_capt_nav_up_CMDhandler)
B747CMD_flt_inst_nav_src_capt_dial_dn       = deferred_command("laminar/B747/flt_inst/nav_src/capt/sel_dial_dn", "Flight Inst NAV Source Captain Down", B747_inst_src_capt_nav_dn_CMDhandler)

B747CMD_flt_inst_eiu_src_capt_dial_up       = deferred_command("laminar/B747/flt_inst/eiu_src/capt/sel_dial_up", "Flight Inst EIU Source Captain Up", B747_inst_src_capt_eiu_up_CMDhandler)
B747CMD_flt_inst_eiu_src_capt_dial_dn       = deferred_command("laminar/B747/flt_inst/eiu_src/capt/sel_dial_dn", "Flight Inst EIU Source Captain Down", B747_inst_src_capt_eiu_dn_CMDhandler)

B747CMD_flt_inst_irs_src_capt_dial_up       = deferred_command("laminar/B747/flt_inst/irs_src/capt/sel_dial_up", "Flight Inst IRS Source Captain Up", B747_inst_src_capt_irs_up_CMDhandler)
B747CMD_flt_inst_irs_src_capt_dial_dn       = deferred_command("laminar/B747/flt_inst/irs_src/capt/sel_dial_dn", "Flight Inst IRS Source Captain Down", B747_inst_src_capt_irs_dn_CMDhandler)

B747CMD_flt_inst_air_data_src_capt_dial_up  = deferred_command("laminar/B747/flt_inst/air_data_src/capt/sel_dial_up", "Flight Inst Air Data Source Captain Up", B747_inst_src_capt_air_data_up_CMDhandler)
B747CMD_flt_inst_air_data_src_capt_dial_dn  = deferred_command("laminar/B747/flt_inst/air_data_src/capt/sel_dial_dn", "Flight Inst Air Data Source Captain Down", B747_inst_src_capt_air_data_dn_CMDhandler)




-- INSTRUMENT SOURCE SELECTORS (FIRST OFFICER)
B747CMD_flt_inst_fd_src_fo_dial_up          = deferred_command("laminar/B747/flt_inst/flt_dir_src/fo/sel_dial_up", "Flight Inst Flight Director Source First Officer Up", B747_flt_inst_fd_src_fo_dial_up_CMDhandler)
B747CMD_flt_inst_fd_src_fo_dial_dn          = deferred_command("laminar/B747/flt_inst/flt_dir_src/fo/sel_dial_dn", "Flight Inst Flight Director Source First Officer Down", B747_flt_inst_fd_src_fo_dial_dn_CMDhandler)

B747CMD_flt_inst_nav_src_fo_dial_up         = deferred_command("laminar/B747/flt_inst/nav_src/fo/sel_dial_up", "Flight Inst NAV Source First Officer Up", B747_inst_src_fo_nav_up_CMDhandler)
B747CMD_flt_inst_nav_src_fo_dial_dn         = deferred_command("laminar/B747/flt_inst/nav_src/fo/sel_dial_dn", "Flight Inst NAV Source First Officer Down", B747_inst_src_fo_nav_dn_CMDhandler)

B747CMD_flt_inst_eiu_src_fo_dial_up         = deferred_command("laminar/B747/flt_inst/eiu_src/fo/sel_dial_up", "Flight Inst EIU Source First Officer Up", B747_inst_src_fo_eiu_up_CMDhandler)
B747CMD_flt_inst_eiu_src_fo_dial_dn         = deferred_command("laminar/B747/flt_inst/eiu_src/fo/sel_dial_dn", "Flight Inst EIU Source First Officer Down", B747_inst_src_fo_eiu_dn_CMDhandler)

B747CMD_flt_inst_irs_src_fo_dial_up         = deferred_command("laminar/B747/flt_inst/irs_src/fo/sel_dial_up", "Flight Inst IRS Source First Officer Up", B747_inst_src_fo_irs_up_CMDhandler)
B747CMD_flt_inst_irs_src_fo_dial_dn         = deferred_command("laminar/B747/flt_inst/irs_src/fo/sel_dial_dn", "Flight Inst IRS Source First Officer Down", B747_inst_src_fo_irs_dn_CMDhandler)

B747CMD_flt_inst_air_data_src_fo_dial_up    = deferred_command("laminar/B747/flt_inst/air_data_src/fo/sel_dial_up", "Flight Inst Air Data Source First Officer Up", B747_inst_src_fo_air_data_up_CMDhandler)
B747CMD_flt_inst_air_data_src_fo_dial_dn    = deferred_command("laminar/B747/flt_inst/air_data_src/fo/sel_dial_dn", "Flight Inst Air Data Source First Officer Down", B747_inst_src_fo_air_data_dn_CMDhandler)





-- INSTRUMENT SOURCE SELECTORS (CENTER PANEL)
B747CMD_flt_inst_eiu_src_ctr_pnl_dial_up    = deferred_command("laminar/B747/flt_inst/eiu_src/ctr_pnl/sel_dial_up", "Flight Inst Center Panel EIU Up", B747_flt_inst_eiu_src_ctr_pnl_dial_up_CMDhandler)
B747CMD_flt_inst_eiu_src_ctr_pnl_dial_dn    = deferred_command("laminar/B747/flt_inst/eiu_src/ctr_pnl/sel_dial_dn", "Flight Inst Center Panel EIU Down", B747_flt_inst_eiu_src_ctr_pnl_dial_dn_CMDhandler)

B747CMD_flt_inst_fmc_master_src_ctr_pnl_sel = deferred_command("laminar/B747/flt_inst/fmc_master_src/ctr_pnl/sel_dial", "Flight Instr Center Panel FMC Master Selector", B747_flt_inst_fmc_master_src_ctr_pnl_sel_CMDhandler)






-- DISPLAY SELECTORS (CAPTAIN)
B747CMD_flt_inst_inbd_disp_capt_sel_dial_up = deferred_command("laminar/B747/flt_inst/capt_inbd_display/sel_dial_up", "Flight Inst Captain Inboard Display Selector Up", B747_flt_inst_inbd_disp_capt_sel_dial_up_CMDhandler)
B747CMD_flt_inst_inbd_disp_capt_sel_dial_dn = deferred_command("laminar/B747/flt_inst/capt_inbd_display/sel_dial_dn", "Flight Inst Captain Inboard Display Selector Down", B747_flt_inst_inbd_disp_capt_sel_dial_dn_CMDhandler)

B747CMD_flt_inst_lwr_disp_capt_sel_dial_up  = deferred_command("laminar/B747/flt_inst/capt_lwr_display/sel_dial_up", "Flight Inst Captain Lower Display Selector Up", B747_flt_inst_lwr_disp_capt_sel_dial_up_CMDhandler)
B747CMD_flt_inst_lwr_disp_capt_sel_dial_dn  = deferred_command("laminar/B747/flt_inst/capt_lwr_display/sel_dial_dn", "Flight Inst Captain Lower Display Selector Down", B747_flt_inst_lwr_disp_capt_sel_dial_dn_CMDhandler)



-- DISPLAY SELECTORS (FIRST OFFICER)
B747CMD_flt_inst_inbd_disp_fo_sel_dial_up   = deferred_command("laminar/B747/flt_inst/fo_inbd_display/sel_dial_up", "Flight Inst First Officer Inboard Display Selector Up", B747_flt_inst_inbd_disp_fo_sel_dial_up_CMDhandler)
B747CMD_flt_inst_inbd_disp_fo_sel_dial_dn   = deferred_command("laminar/B747/flt_inst/fo_inbd_display/sel_dial_dn", "Flight Inst First Officer Inboard Display Selector Down", B747_flt_inst_inbd_disp_fo_sel_dial_dn_CMDhandler)

B747CMD_flt_inst_lwr_disp_fo_sel_dial_up    = deferred_command("laminar/B747/flt_inst/fo_lwr_display/sel_dial_up", "Flight Inst First Officer Lower Display Selector Up", B747_flt_inst_lwr_disp_fo_sel_dial_up_CMDhandler)
B747CMD_flt_inst_lwr_disp_fo_sel_dial_dn    = deferred_command("laminar/B747/flt_inst/fo_lwr_display/sel_dial_dn", "Flight Inst First Officer Lower Display Selector Down", B747_flt_inst_lwr_disp_fo_sel_dial_dn_CMDhandler)




-- EFIS CONTROLS (CAPTAIN)
B747CMD_efis_min_ref_alt_capt_sel_dial_up   = deferred_command("laminar/B747/efis/min_ref_alt/capt/sel_dial_up", "EFIS Altitude Minimums Ref Selector Up", B747_efis_min_ref_alt_capt_sel_dial_up_CMDhandler)
B747CMD_efis_min_ref_alt_capt_sel_dial_dn   = deferred_command("laminar/B747/efis/min_ref_alt/capt/sel_dial_dn", "EFIS Altitude Minimums Ref Selector Down", B747_efis_min_ref_alt_capt_sel_dial_dn_CMDhandler)

B747CMD_efis_ref_alt_capt_set_dial_up       = deferred_command("laminar/B747/efis/ref_alt/capt/set_dial_up", "EFIS Altitude Ref Set Dial Up", B747_efis_ref_alt_capt_set_dial_up_CMDhandler)
B747CMD_efis_ref_alt_capt_set_dial_dn       = deferred_command("laminar/B747/efis/ref_alt/capt/set_dial_dn", "EFIS Altitude Ref Set Dial Down", B747_efis_ref_alt_capt_set_dial_dn_CMDhandler)

B747DR_efis_min_alt_ctrl_fo_rheo            = deferred_dataref("laminar/B747/efis/min_alt_ctrl/fo/rheostat", "number", B747_efis_min_alt_ctrl_fo_rheo)

B747CMD_efis_dh_capt_reset_switch           = deferred_command("laminar/B747/efis/dh/capt/reset_switch", "EFIS Decision Height Reset Switch", B747_efis_dh_capt_reset_switch_CMDhandler)

B747CMD_efis_baro_ref_capt_sel_dial_up      = deferred_command("laminar/B747/efis/baro_ref/capt/sel_dial_up", "EFIS BARO Ref Selector Up", B747_efis_baro_ref_capt_sel_dial_up_CMDhandler)
B747CMD_efis_baro_ref_capt_sel_dial_dn      = deferred_command("laminar/B747/efis/baro_ref/capt/sel_dial_dn", "EFIS BARO Ref Selector Down", B747_efis_baro_ref_capt_sel_dial_dn_CMDhandler)
B747CMD_efis_baro_set_capt_sel_dial_up      = deferred_command("laminar/B747/efis/baro_set/capt/sel_dial_up", "EFIS BARO Set Selector Up", B747_efis_baro_set_capt_sel_dial_up_CMDhandler)
B747CMD_efis_baro_set_capt_sel_dial_dn      = deferred_command("laminar/B747/efis/baro_set/capt/sel_dial_dn", "EFIS BARO Set Selector Down", B747_efis_baro_set_capt_sel_dial_dn_CMDhandler)
B747CMD_efis_baro_std_capt_switch           = deferred_command("laminar/B747/efis/baro_std/capt/switch", "EFIS BARO STD Switch", B747_efis_baro_std_capt_switch_CMDhandler)

B747CMD_efis_fpv_capt_switch                = deferred_command("laminar/B747/efis/fpv/capt/switch", "EFIS FPV Switch", B747_efis_fpv_capt_switch_CMDhandler)
B747CMD_efis_meters_capt_switch             = deferred_command("laminar/B747/efis/meters/capt/switch", "EFIS Meters Switch", B747_efis_meters_capt_switch_CMDhandler)




-- EFIS CONTROLS (FIRST OFFICER)
B747CMD_efis_min_ref_alt_fo_sel_dial_up     = deferred_command("laminar/B747/efis/min_ref_alt/fo/sel_dial_up", "EFIS Altitude Minimums Ref Selector Up", B747_efis_min_ref_alt_fo_sel_dial_up_CMDhandler)
B747CMD_efis_min_ref_alt_fo_sel_dial_dn     = deferred_command("laminar/B747/efis/min_ref_alt/fo/sel_dial_dn", "EFIS Altitude Minimums Ref Selector Down", B747_efis_min_ref_alt_fo_sel_dial_dn_CMDhandler)

B747CMD_efis_ref_alt_fo_set_dial_up         = deferred_command("laminar/B747/efis/ref_alt/fo/set_dial_up", "EFIS Altitude Ref Set Dial Up", B747_efis_ref_alt_fo_set_dial_up_CMDhandler)
B747CMD_efis_ref_alt_fo_set_dial_dn         = deferred_command("laminar/B747/efis/ref_alt/fo/set_dial_dn", "EFIS Altitude Ref Set Dial Down", B747_efis_ref_alt_fo_set_dial_dn_CMDhandler)

B747CMD_efis_dh_fo_reset_switch             = deferred_command("laminar/B747/efis/dh/fo/reset_switch", "EFIS Decision Height Reset Switch", B747_efis_dh_fo_reset_switch_CMDhandler)

B747CMD_efis_baro_ref_fo_sel_dial_up        = deferred_command("laminar/B747/efis/baro_ref/fo/sel_dial_up", "EFIS BARO Ref Selector Up", B747_efis_baro_ref_fo_sel_dial_up_CMDhandler)
B747CMD_efis_baro_ref_fo_sel_dial_dn        = deferred_command("laminar/B747/efis/baro_ref/fo/sel_dial_dn", "EFIS BARO Ref Selector Down", B747_efis_baro_ref_fo_sel_dial_dn_CMDhandler)
B747CMD_efis_baro_set_fo_sel_dial_up        = deferred_command("laminar/B747/efis/baro_set/fo/sel_dial_up", "EFIS BARO Set Selector Up", B747_efis_baro_set_fo_sel_dial_up_CMDhandler)
B747CMD_efis_baro_set_fo_sel_dial_dn        = deferred_command("laminar/B747/efis/baro_set/fo/sel_dial_dn", "EFIS BARO Set Selector Down", B747_efis_baro_set_fo_sel_dial_dn_CMDhandler)
B747CMD_efis_baro_std_fo_switch             = deferred_command("laminar/B747/efis/baro_std/fo/switch", "EFIS BARO STD Switch", B747_efis_baro_std_fo_switch_CMDhandler)

B747CMD_efis_fpv_fo_switch                  = deferred_command("laminar/B747/efis/fpv/fo/switch", "EFIS FPV Switch", B747_efis_fpv_fo_switch_CMDhandler)
B747CMD_efis_meters_fo_switch               = deferred_command("laminar/B747/efis/meters/fo/switch", "EFIS Meters Switch", B747_efis_meters_fo_switch_CMDhandler)




-- ND CONTROLS (CAPTAIN)
B747CMD_nd_mode_capt_sel_dial_up            = deferred_command("laminar/B747/nd/mode/capt/sel_dial_up", "ND Mode Selector Up", B747_nd_mode_capt_sel_dial_up_CMDhandler)
B747CMD_nd_mode_capt_sel_dial_dn            = deferred_command("laminar/B747/nd/mode/capt/sel_dial_dn", "ND Mode Selector Down", B747_nd_mode_capt_sel_dial_dn_CMDhandler)

B747CMD_nd_range_capt_sel_dial_up           = deferred_command("laminar/B747/nd/range/capt/sel_dial_up", "ND Range Selector Up", B747_nd_range_capt_sel_dial_up_CMDhandler)
B747CMD_nd_range_capt_sel_dial_dn           = deferred_command("laminar/B747/nd/range/capt/sel_dial_dn", "ND Range Selector Down", B747_nd_range_capt_sel_dial_dn_CMDhandler)

B747CMD_nd_center_capt_switch               = deferred_command("laminar/B747/nd/center/capt/switch", "ND Center Switch", B747_nd_center_capt_switch_CMDhandler)
B747CMD_nd_traffic_capt_switch              = deferred_command("laminar/B747/nd/traffic/capt/switch", "ND Traffic Switch", B747_nd_traffic_capt_switch_CMDhandler)

B747CMD_nd_wxr_capt_switch                  = deferred_command("laminar/B747/nd/wxr/capt/switch", "ND WXR Switch", B747_nd_wxr_capt_switch_CMDhandler)
B747CMD_nd_sta_capt_switch                  = deferred_command("laminar/B747/nd/sta/capt/switch", "ND STA Switch", B747_nd_sta_capt_switch_CMDhandler)
B747CMD_nd_wpt_capt_switch                  = deferred_command("laminar/B747/nd/wpt/capt/switch", "ND WPT Switch", B747_nd_wpt_capt_switch_CMDhandler)
B747CMD_nd_arpt_capt_switch                 = deferred_command("laminar/B747/nd/arpt/capt/switch", "ND ARPT Switch", B747_nd_arpt_capt_switch_CMDhandler)
B747CMD_nd_data_capt_switch                 = deferred_command("laminar/B747/nd/data/capt/switch", "ND DATA Switch", B747_nd_data_capt_switch_CMDhandler)
B747CMD_nd_pos_capt_switch                  = deferred_command("laminar/B747/nd/pos/capt/switch", "ND POS Switch", B747_nd_pos_capt_switch_CMDhandler)
B747CMD_nd_terr_capt_switch                 = deferred_command("laminar/B747/nd/terr/capt/switch", "ND TERR Switch", B747_nd_terr_capt_switch_CMDhandler)



-- ND CONTROLS (FIRST OFFICER)
B747CMD_nd_mode_fo_sel_dial_up              = deferred_command("laminar/B747/nd/mode/fo/sel_dial_up", "ND Mode Selector Up", B747_nd_mode_fo_sel_dial_up_CMDhandler)
B747CMD_nd_mode_fo_sel_dial_dn              = deferred_command("laminar/B747/nd/mode/fo/sel_dial_dn", "ND Mode Selector Down", B747_nd_mode_fo_sel_dial_dn_CMDhandler)

B747CMD_nd_range_fo_sel_dial_up             = deferred_command("laminar/B747/nd/range/fo/sel_dial_up", "ND Range Selector Up", B747_nd_range_fo_sel_dial_up_CMDhandler)
B747CMD_nd_range_fo_sel_dial_dn             = deferred_command("laminar/B747/nd/range/fo/sel_dial_dn", "ND Range Selector Down", B747_nd_range_fo_sel_dial_dn_CMDhandler)

B747CMD_nd_center_fo_switch                 = deferred_command("laminar/B747/nd/center/fo/switch", "ND Center Switch", B747_nd_center_fo_switch_CMDhandler)
B747CMD_nd_traffic_fo_switch                = deferred_command("laminar/B747/nd/traffic/fo/switch", "ND Traffic Switch", B747_nd_traffic_fo_switch_CMDhandler)

B747CMD_nd_wxr_fo_switch                    = deferred_command("laminar/B747/nd/wxr/fo/switch", "ND WXR Switch", B747_nd_wxr_fo_switch_CMDhandler)
B747CMD_nd_sta_fo_switch                    = deferred_command("laminar/B747/nd/sta/fo/switch", "ND STA Switch", B747_nd_sta_fo_switch_CMDhandler)
B747CMD_nd_wpt_fo_switch                    = deferred_command("laminar/B747/nd/wpt/fo/switch", "ND WPT Switch", B747_nd_wpt_fo_switch_CMDhandler)
B747CMD_nd_arpt_fo_switch                   = deferred_command("laminar/B747/nd/arpt/fo/switch", "ND ARPT Switch", B747_nd_arpt_fo_switch_CMDhandler)
B747CMD_nd_data_fo_switch                   = deferred_command("laminar/B747/nd/data/fo/switch", "ND DATA Switch", B747_nd_data_fo_switch_CMDhandler)
B747CMD_nd_pos_fo_switch                    = deferred_command("laminar/B747/nd/pos/fo/switch", "ND POS Switch", B747_nd_pos_fo_switch_CMDhandler)
B747CMD_nd_terr_fo_switch                   = deferred_command("laminar/B747/nd/terr/fo/switch", "ND TERR Switch", B747_nd_terr_fo_switch_CMDhandler)




-- DISPLAY SELECT PANEL
B747CMD_dsp_eng_switch                      = deferred_command("laminar/B747/dsp/eng_switch", "Display Select Panel ENG Switch", B747_dsp_eng_switch_CMDhandler)
B747CMD_dsp_stat_switch                     = deferred_command("laminar/B747/dsp/stat_switch", "Display Select Panel STAT Switch", B747_dsp_stat_switch_CMDhandler)
B747CMD_dsp_elec_switch                     = deferred_command("laminar/B747/dsp/elec_switch", "Display Select Panel ELEC Switch", B747_dsp_elec_switch_CMDhandler)
B747CMD_dsp_fuel_switch                     = deferred_command("laminar/B747/dsp/fuel_switch", "Display Select Panel FUEL Switch", B747_dsp_fuel_switch_CMDhandler)
B747CMD_dsp_ecs_switch                      = deferred_command("laminar/B747/dsp/ecs_switch", "Display Select Panel ECS Switch", B747_dsp_ecs_switch_CMDhandler)
B747CMD_dsp_hyd_switch                      = deferred_command("laminar/B747/dsp/hyd_switch", "Display Select Panel HYD Switch", B747_dsp_hyd_switch_CMDhandler)
B747CMD_dsp_drs_switch                      = deferred_command("laminar/B747/dsp/drs_switch", "Display Select Panel DRS Switch", B747_dsp_drs_switch_CMDhandler)
B747CMD_dsp_gear_switch                     = deferred_command("laminar/B747/dsp/gear_switch", "Display Select Panel GEAR Switch", B747_dsp_gear_switch_CMDhandler)

B747CMD_dsp_canc_switch                     = deferred_command("laminar/B747/dsp/canc_switch", "Display Select Panel CANC Switch", B747_dsp_canc_switch_CMDhandler)
B747CMD_dsp_rcl_switch                      = deferred_command("laminar/B747/dsp/rcl_switch", "Display Select Panel Recall Switch", B747_dsp_rcl_switch_CMDhandler)


--[[
-- CLOCK
B747CMD_clock_captain_chrono_switch         = deferred_command("laminar/B747/clock/captain/chrono_switch", "Captain Clock Chronograph Switch", B747_clock_captain_chrono_switch_CMDhandler)
B747CMD_glrshld_captain_chrono_switch       = deferred_command("laminar/B747/glareshield/captain/chrono_switch", "Captain Glareshield Chronograph Switch", B747_glareshield_captain_chrono_switch_CMDhandler)
B747CMD_clock_captain_et_sel_switch_up      = deferred_command("laminar/B747/clock/captain/et_switch_up", "Captain Clock Elapsed Time Switch_Up", B747_clock_captain_et_sel_switch_up_CMDhandler)
B747CMD_clock_captain_et_sel_switch_dn      = deferred_command("laminar/B747/clock/captain/et_switch_dn", "Captain Clock Elapsed Time Switch_Down", B747_clock_captain_et_sel_switch_dn_CMDhandler)
B747CMD_clock_captain_date_switch           = deferred_command("laminar/B747/clock/captain/date_switch", "Captain Clock Date Switch", B747_clock_captain_date_switch_CMDhandler)
B747CMD_clock_captain_set_switch_up         = deferred_command("laminar/B747/clock/captain/set_switch_up", "Captain Clock Set Switch Up", B747_clock_captain_set_switch_up_CMDhandler)
B747CMD_clock_captain_set_switch_dn         = deferred_command("laminar/B747/clock/captain/set_switch_dn", "Captain Clock Set Switch Down", B747_clock_captain_set_switch_dn_CMDhandler)


B747CMD_clock_fo_chrono_switch              = deferred_command("laminar/B747/clock/fo/chrono_switch", "First Officer Clock Chronograph Switch", B747_clock_fo_chrono_switch_CMDhandler)
B747CMD_glrshld_fo_chrono_switch            = deferred_command("laminar/B747/glareshield/fo/chrono_switch", "First Officer Glareshield Chronograph Switch", B747_glareshield_fo_chrono_switch_CMDhandler)
B747CMD_clock_fo_et_sel_switch_up           = deferred_command("laminar/B747/clock/fo/et_switch_up", "First Officer Clock Elapsed Time Switch_Up", B747_clock_fo_et_sel_switch_up_CMDhandler)
B747CMD_clock_fo_et_sel_switch_dn           = deferred_command("laminar/B747/clock/fo/et_switch_dn", "First Officer Clock Elapsed Time Switch_Down", B747_clock_fo_et_sel_switch_dn_CMDhandler)
B747CMD_clock_fo_date_switch                = deferred_command("laminar/B747/clock/fo/date_switch", "First Officer Clock Date Switch", B747_clock_fo_date_switch_CMDhandler)
B747CMD_clock_fo_set_switch_up              = deferred_command("laminar/B747/clock/fo/set_switch_up", "First Officer Clock Set Switch Up", B747_clock_fo_set_switch_up_CMDhandler)
B747CMD_clock_fo_set_switch_dn              = deferred_command("laminar/B747/clock/fo/set_switch_dn", "First Officer Clock Set Switch Down", B747_clock_fo_set_switch_dn_CMDhandler)
--]]


-- AI
B747CMD_ai_fltinst_quick_start			= deferred_command("laminar/B747/ai/fltinst_quick_start", "number", B747_ai_fltinst_quick_start_CMDhandler)



--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- RESCALE FLOAT AND CLAMP TO OUTER LIMITS -------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    if in2 - in1 == 0 then return out1 + (out2 - out1) * (x - in1) end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end






----- ROUNDING --------------------------------------------------------------------------
function roundToIncrement(number, increment)

    local y = number / increment
    local q = math.floor(y + 0.5)
    local z = q * increment

    return z

end



function roundUpToIncrement(number, increment)

    local y = number / increment
    local q = math.ceil(y)
    local z = q * increment

    return z

end



function roundDownToIncrement(number, increment)

    local y = number / increment
    local q = math.floor(y)
    local z = q * increment

    return z

end



function roundUp(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end





----- RECIPROCAL ANGLE ------------------------------------------------------------------
function recipAngle(angle)
    return (angle + 180) % 360
end








----- CLOCK (CAPTAIN) -------------------------------------------------------------------

--[[
function B747_captain_clock_et_timer()

    B747DR_clock_captain_et_seconds = B747DR_clock_captain_et_seconds + 0.01

    if B747DR_clock_captain_et_seconds > 59.99 then
        B747DR_clock_captain_et_seconds = 0.0
        B747DR_clock_captain_et_minutes = B747DR_clock_captain_et_minutes + 1

        if B747DR_clock_captain_et_minutes > 59 then
            B747DR_clock_captain_et_minutes = 0.0
            B747DR_clock_captain_et_hours = B747DR_clock_captain_et_hours + 1

            if B747DR_clock_captain_et_hours > 23.0 then
                B747DR_clock_captain_et_hours = 0
            end
        end
    end

end





function B747_captain_clock_chrono_timer()
	
		
    B747DR_clock_captain_chrono_seconds = B747DR_clock_captain_chrono_seconds + 0.01

    if B747DR_clock_captain_chrono_seconds > 59.99 then
        B747DR_clock_captain_chrono_seconds = 0.0
        B747DR_clock_captain_chrono_minutes = B747DR_clock_captain_chrono_minutes + 1

        if B747DR_clock_captain_chrono_minutes > 59.0 then
            B747DR_clock_captain_chrono_minutes = 0.0
        end
    end

end




function B747_captain_clock_date_mode()

    B747DR_clock_captain_gmt_date_mode = 1.0 - B747DR_clock_captain_gmt_date_mode

end




function B747_captain_clock()

    -- GMT TIME
    if simDR_time_is_GMT == 0 then simCMD_clock_is_gmt:once() end               -- TODO:  RESET ON EXIT?  DO WE EVEN NEED THIS?
    B747DR_clock_captain_gmt_minutes    = simDR_time_zulu_minutes
    B747DR_clock_captain_gmt_hours      = simDR_time_zulu_hours


    -- DATE
    local currentDate                   = os.date("*t")
    B747DR_clock_captain_date_day       = simDR_time_current_day
    B747DR_clock_captain_date_month     = simDR_time_current_month
    B747DR_clock_captain_date_year12    = string.sub(currentDate.year, -4, -3)
    B747DR_clock_captain_date_year34    = string.sub(currentDate.year, -2, -1)


    -- TIME/DATE SWITCH             TODO:  ELECTRICAL POWER REQ
    if B747DR_clock_captain_gmt_display_mode == 1.0 then
        if is_timer_scheduled(B747_captain_clock_date_mode) == false then
            run_at_interval(B747_captain_clock_date_mode, 2.0)
        end
    else
        if is_timer_scheduled(B747_captain_clock_date_mode) == true then
            stop_timer(B747_captain_clock_date_mode)
            B747DR_clock_captain_gmt_date_mode = 0.0
        end
    end


    -- ELAPSED TIMER                TODO:  ELECTRICAL POWER REQ
    if B747DR_clock_captain_et_mode == B747_RUN then
        if is_timer_scheduled(B747_captain_clock_et_timer) == false then
            run_at_interval(B747_captain_clock_et_timer, 0.01)
        end
    elseif B747DR_clock_captain_et_mode == B747_HOLD then
        if is_timer_scheduled(B747_captain_clock_et_timer) == true then
            stop_timer(B747_captain_clock_et_timer)
        end
    elseif B747DR_clock_captain_et_mode == B747_RESET then
        B747DR_clock_captain_et_seconds = 0
        B747DR_clock_captain_et_minutes = 0
        B747DR_clock_captain_et_hours = 0
    end


    -- CHRONOGRAPH TIMER            TODO:  ELECTRICAL POWER REQ
    if B747DR_clock_captain_chrono_mode == B747_START then
        if is_timer_scheduled(B747_captain_clock_chrono_timer) == false then
            run_at_interval(B747_captain_clock_chrono_timer, 0.01)
        end
        B747DR_clock_captain_et_chr_display_mode = B747_CHRONO
    elseif B747DR_clock_captain_chrono_mode == B747_STOP then
        if is_timer_scheduled(B747_captain_clock_chrono_timer) == true then
            stop_timer(B747_captain_clock_chrono_timer)
        end
    elseif B747DR_clock_captain_chrono_mode == B747_RESET then
        B747DR_clock_captain_chrono_seconds = 0
        B747DR_clock_captain_chrono_minutes = 0
        B747DR_clock_captain_et_chr_display_mode = B747_ET
    end


end--]]






----- CLOCK (FIRST OFFICER) -------------------------------------------------------------

--[[
function B747_fo_clock_et_timer()

    B747DR_clock_fo_et_seconds = B747DR_clock_fo_et_seconds + 0.01

    if B747DR_clock_fo_et_seconds > 59.99 then
        B747DR_clock_fo_et_seconds = 0.0
        B747DR_clock_fo_et_minutes = B747DR_clock_fo_et_minutes + 1

        if B747DR_clock_fo_et_minutes > 59 then
            B747DR_clock_fo_et_minutes = 0.0
            B747DR_clock_fo_et_hours = B747DR_clock_fo_et_hours + 1

            if B747DR_clock_fo_et_hours > 23.0 then
                B747DR_clock_fo_et_hours = 0
            end
        end
    end

end




function B747_fo_clock_chrono_timer()

    B747DR_clock_fo_chrono_seconds = B747DR_clock_fo_chrono_seconds + 0.01

    if B747DR_clock_fo_chrono_seconds > 59.99 then
        B747DR_clock_fo_chrono_seconds = 0.0
        B747DR_clock_fo_chrono_minutes = B747DR_clock_fo_chrono_minutes + 1

        if B747DR_clock_fo_chrono_minutes > 59.0 then
            B747DR_clock_fo_chrono_minutes = 0.0
        end
    end

end




function B747_fo_clock_date_mode()

    B747DR_clock_fo_gmt_date_mode = 1.0 - B747DR_clock_fo_gmt_date_mode

end




function B747_fo_clock()

    -- GMT TIME
    B747DR_clock_fo_gmt_minutes    = simDR_time_zulu_minutes
    B747DR_clock_fo_gmt_hours      = simDR_time_zulu_hours


    -- DATE
    local currentDate              = os.date("*t")
    B747DR_clock_fo_date_day       = simDR_time_current_day
    B747DR_clock_fo_date_month     = simDR_time_current_month
    B747DR_clock_fo_date_year12    = string.sub(currentDate.year, -4, -3)
    B747DR_clock_fo_date_year34    = string.sub(currentDate.year, -2, -1)


    -- TIME/DATE SWITCH
    if B747DR_clock_fo_gmt_display_mode == 1.0 then
        if is_timer_scheduled(B747_fo_clock_date_mode) == false then
            run_at_interval(B747_fo_clock_date_mode, 2.0)
        end
    else
        if is_timer_scheduled(B747_fo_clock_date_mode) == true then
            stop_timer(B747_fo_clock_date_mode)
            B747DR_clock_fo_gmt_date_mode = 0.0
        end
    end


    -- ELAPSED TIMER                TODO:  ELECTRICAL POWER REQ
    if B747DR_clock_fo_et_mode == B747_RUN then
        if is_timer_scheduled(B747_fo_clock_et_timer) == false then
            run_at_interval(B747_fo_clock_et_timer, 0.01)
        end
    elseif B747DR_clock_fo_et_mode == B747_HOLD then
        if is_timer_scheduled(B747_fo_clock_et_timer) == true then
            stop_timer(B747_fo_clock_et_timer)
        end
    elseif B747DR_clock_fo_et_mode == B747_RESET then
        B747DR_clock_fo_et_seconds = 0
        B747DR_clock_fo_et_minutes = 0
        B747DR_clock_fo_et_hours = 0
    end


    -- CHRONOGRAPH TIMER            TODO:  ELECTRICAL POWER REQ
    if B747DR_clock_fo_chrono_mode == B747_START then
        if is_timer_scheduled(B747_fo_clock_chrono_timer) == false then
            run_at_interval(B747_fo_clock_chrono_timer, 0.01)
        end
        B747DR_clock_fo_et_chr_display_mode = B747_CHRONO
    elseif B747DR_clock_fo_chrono_mode == B747_STOP then
        if is_timer_scheduled(B747_fo_clock_chrono_timer) == true then
            stop_timer(B747_fo_clock_chrono_timer)
        end
    elseif B747DR_clock_fo_chrono_mode == B747_RESET then
        B747DR_clock_fo_chrono_seconds = 0
        B747DR_clock_fo_chrono_minutes = 0
        B747DR_clock_fo_et_chr_display_mode = B747_ET
    end


end--]]





----- RMI -------------------------------------------------------------------------------
function B747_rmi()

    -- LEFT
    if simDR_rmi_captain_left_use_adf == 0 then
        B747DR_RMI_left_bearing = simDR_nav_relative_bearing_deg[2]
    elseif simDR_rmi_captain_left_use_adf == 1 then
        B747DR_RMI_left_bearing = simDR_adf1_relative_bearing_deg
    end


    --RIGHT
    if simDR_rmi_captain_right_use_adf == 0 then
        B747DR_RMI_right_bearing = simDR_nav_relative_bearing_deg[3]
    elseif simDR_rmi_captain_right_use_adf == 1 then
        B747DR_RMI_right_bearing = simDR_adf2_relative_bearing_deg
    end

end





----- DECISION HEIGHT -------------------------------------------------------------------
function B747_on_ground()
    if simDR_all_wheels_on_ground > 0 then                                              -- VERIFY WHEELS STILL ON GROUND
        B747_flt_mode = 0                                                               -- MODE = GROUND
    end
end

local B747_DH_flash_counter = 0
function B747_DH_flash()
    if B747DR_dec_ht_display_status == 1 then
        B747DR_dec_ht_display_status = 2
    elseif B747DR_dec_ht_display_status == 2 then
        B747DR_dec_ht_display_status = 1
    end

    B747_DH_flash_counter = B747_DH_flash_counter + 1

    if B747_DH_flash_counter == 10 then
        B747_DH_flash_counter = 0
        stop_timer(B747_DH_flash)
    end
end

local B747_DH_alert_mode = 0
function B747_decision_height_capt()


    -- SET FLIGHT MODE
    if simDR_all_wheels_on_ground > 0                                                   -- WHEELS NOT ON GROUND
        and simDR_radio_alt_height_capt > 75.0                                          -- 75' ABOVE GROUND
        and B747_flt_mode == 0                                                          -- GROUND
    then
        B747_flt_mode = 1                                                               -- MODE = IN FLIGHT
        if is_timer_scheduled(B747_on_ground) == true then
            stop_timer(B747_on_ground)
        end

    elseif simDR_all_wheels_on_ground > 0                                               -- WHEELS ON GROUND
        and B747_flt_mode == 1                                                          -- IN FLIGHT
    then
        B747_flt_mode = 2                                                               -- MODE = TOUCHDOWN
        if is_timer_scheduled(B747_on_ground) == false then
            run_after_time(B747_on_ground, 10.0)
        end
    end


    -- TRIGGER THE DH ALERT
    if B747_flt_mode == 1                                                               -- IN FLIGHT
        and simDR_radio_alt_height_capt < simDR_radio_alt_DH_capt                       -- AIRCRAFT BELOW DH
        and B747_DH_alert_mode == 0                                                     -- DH ALERT HAS NOT STARTED
    then
        B747DR_dec_ht_display_status = 1                                                -- TURN ON DH ALERT
        B747DR_radio_alt_display_status = 1                                             -- TURN ON RADIO ALT ALERT
        if is_timer_scheduled(B747_DH_flash) == false then
            run_at_interval(B747_DH_flash, 0.5)                                         -- FLASH THE DH ALERT
        end
        B747_DH_alert_mode = 1                                                          -- DH ALERT HAS STARTED
    end


    -- RESET THE DH ALERT
    if B747_DH_alert_mode == 1 then
        if B747DR_efis_dh_reset_capt_switch_pos == 1
            or B747_flt_mode == 2
            or simDR_radio_alt_height_capt > (simDR_radio_alt_DH_capt + 75.0)
        then
            B747DR_dec_ht_display_status = 0
            B747DR_radio_alt_display_status = 0
            B747_DH_alert_mode = 0
        end
    end

    -- "Approaching Minimums" and "Minimums" Callouts (crazytimtimtim + Matt726)
    if B747DR_toga_mode == 0
    and simDR_all_wheels_on_ground == 0
    then

        if  B747DR_efis_min_ref_alt_capt_sel_dial_pos == 0                  -- RADIO mode
        and simDR_radio_alt_DH_capt ~= 0
        then

            if simDR_radio_alt_height_capt <= simDR_radio_alt_DH_capt + 80 and simDR_radio_alt_height_capt > simDR_radio_alt_DH_capt then
                B747DR_appDH_alert = 1
            elseif simDR_radio_alt_height_capt <= simDR_radio_alt_DH_capt then
                B747DR_DH_alert = 1
                B747DR_appDH_alert = 0
            else
                B747DR_DH_alert = 0
                B747DR_appDH_alert = 0
            end

        elseif B747DR_efis_min_ref_alt_capt_sel_dial_pos == 1                   -- BARO mode
        and B747DR_efis_baro_alt_ref_capt ~= 0
        then

            if simDR_altitude_ft_pilot <= B747DR_efis_baro_alt_ref_capt + 80 and simDR_altitude_ft_pilot > B747DR_efis_baro_alt_ref_capt then
                B747DR_appDH_alert = 1
            elseif simDR_altitude_ft_pilot <= B747DR_efis_baro_alt_ref_capt then
                B747DR_DH_alert = 1
                B747DR_appDH_alert = 0
            else
                B747DR_DH_alert = 0
                B747DR_appDH_alert = 0
            end
        else
            B747DR_DH_alert = 0
            B747DR_appDH_alert = 0
        end
    else
        B747DR_DH_alert = 0
        B747DR_appDH_alert = 0
    end
end

--[[if B747DR_toga_mode == 0
and simDR_all_wheels_on_ground == 0
then
    if  (B747DR_efis_min_ref_alt_capt_sel_dial_pos == 0                  -- RADIO mode
    and simDR_radio_alt_height_capt <= simDR_radio_alt_DH_capt + 80
    and simDR_radio_alt_height_capt ~= 0)

    or (B747DR_efis_min_ref_alt_capt_sel_dial_pos == 1                   -- BARO mode
    and simDR_altitude_ft_pilot <= B747DR_efis_baro_alt_ref_capt + 80)
    then
        B747DR_appDH_alert = 1
    else
        B747DR_appDH_alert = 0
    end
end
]]
----- RADIO ALTITUDE --------------------------------------------------------------------
function B747_radio_altitude()

    if simDR_radio_alt_height_capt < 100.0 then                                             -- TWO FOOT INCREMENTS
        B747DR_radio_altitude = roundToIncrement(simDR_radio_alt_height_capt, 2)

    elseif simDR_radio_alt_height_capt < 500.0 then                                         -- TEN FOOT INCREMENTS
        B747DR_radio_altitude = roundToIncrement(simDR_radio_alt_height_capt, 10)

    else                                                                                    -- TWENTY FOOT INCREMENTS
        B747DR_radio_altitude = roundToIncrement(simDR_radio_alt_height_capt, 20)

    end

end








----- ALTIMETER -------------------------------------------------------------------------
function B747_altimteter()

    B747DR_alt_hectopascal = string.format("%04d", roundToIncrement((simDR_altimeter_baro_inHg * 33.8639), 1))
    B747DR_altimter_ft_adjusted = simDR_altitude_ft_pilot * 0.01

end






----- LOCALIZER & GLIDESLOPE FLAGS PM VISIBILITY FLAGS ----------------------------------
function B747_loc_gs_vis_flags()

    -- CAPTAIN LOCALIZER SCALE
    
    if simDR_hsi_hdef_dots_pilot < -0.50 or simDR_hsi_hdef_dots_pilot > 0.50 then
        B747DR_loc_scale_vis_capt = 1
    elseif simDR_hsi_hdef_dots_pilot >= -0.50 and simDR_hsi_hdef_dots_pilot <= 0.50 then
        B747DR_loc_scale_vis_capt = 2
    else
        B747DR_loc_scale_vis_capt = 0
    end


    -- CAPTAIN LOCALIZER POINTER
    
    if simDR_hsi_hdef_dots_pilot < -2.3 or simDR_hsi_hdef_dots_pilot > 2.3
    then
        B747DR_loc_ptr_vis_capt = 1
    elseif (simDR_hsi_hdef_dots_pilot >= -2.3 and simDR_hsi_hdef_dots_pilot < -0.5)
        or (simDR_hsi_hdef_dots_pilot <= 2.3 and simDR_hsi_hdef_dots_pilot > 0.5)
    then
        B747DR_loc_ptr_vis_capt = 2
    elseif simDR_hsi_hdef_dots_pilot >= -0.5 and simDR_hsi_hdef_dots_pilot <= 0.5
    then
        B747DR_loc_ptr_vis_capt = 3
    else
        B747DR_loc_ptr_vis_capt = 0
    end


    -- CAPTAIN GLIDESLOPE POINTER
    
    if simDR_hsi_vdef_dots_pilot < -2.3 or simDR_hsi_vdef_dots_pilot > 2.3 then
        B747DR_glideslope_ptr_vis_capt = 1
    elseif simDR_hsi_vdef_dots_pilot >= -2.3 and simDR_hsi_vdef_dots_pilot <= 2.3 then
        B747DR_glideslope_ptr_vis_capt = 2
    else
        B747DR_glideslope_ptr_vis_capt = 0
    end


    -- FIRST OFFICER LOCALIZER SCALE
    
    if simDR_hsi_hdef_dots_copilot < -0.50 or simDR_hsi_hdef_dots_copilot > 0.50 then
        B747DR_loc_scale_vis_fo = 1
    elseif simDR_hsi_hdef_dots_copilot >= -0.50 and simDR_hsi_hdef_dots_copilot <= 0.50 then
        B747DR_loc_scale_vis_fo = 2
    else
        B747DR_loc_scale_vis_fo = 0
    end


    -- FIRST OFFICER LOCALIZER POINTER
    
    if simDR_hsi_hdef_dots_copilot < -2.3 or simDR_hsi_hdef_dots_copilot > 2.3
    then
        B747DR_loc_ptr_vis_fo = 1
    elseif (simDR_hsi_hdef_dots_copilot >= -2.3 and simDR_hsi_hdef_dots_copilot < -0.5)
        or (simDR_hsi_hdef_dots_copilot <= 2.3 and simDR_hsi_hdef_dots_copilot > 0.5)
    then
        B747DR_loc_ptr_vis_fo = 2
    elseif simDR_hsi_hdef_dots_copilot >= -0.5 and simDR_hsi_hdef_dots_copilot <= 0.5
    then
        B747DR_loc_ptr_vis_fo = 3
    else
        B747DR_loc_ptr_vis_fo = 0
    end


    -- FIRST OFFICER GLIDESLOPE POIUNTER
    
    if simDR_hsi_vdef_dots_copilot < -2.3 or simDR_hsi_vdef_dots_copilot > 2.3 then
        B747DR_glideslope_ptr_vis_fo = 1
    elseif simDR_hsi_vdef_dots_copilot >= -2.3 and simDR_hsi_vdef_dots_copilot <= 2.3 then
        B747DR_glideslope_ptr_vis_fo = 2
    else
        B747DR_glideslope_ptr_vis_fo = 0
    end

end




----- ND NAV RAD FREQ ID ----------------------------------------------------------------
function B747_ND_nav_rad_ID()

    -- VOR RADIOS
    B747_nd_vorL_ID_flag_capt = 1
    if string.byte(simDR_nav3_ID) == nil then
        B747_nd_vorL_ID_flag_capt = 0
    end

    B747_nd_vorR_ID_flag_capt = 1
    if string.byte(simDR_nav4_ID) == nil then
        B747_nd_vorR_ID_flag_capt = 0
    end
    

    -- ADF RADIOS
    B747_nd_adfL_ID_flag_capt = 1
    if string.byte(simDR_adf1_ID) == nil then
        B747_nd_adfL_ID_flag_capt = 0
    end

    B747_nd_adfR_ID_flag_capt = 1
    if string.byte(simDR_adf2_ID) == nil then
        B747_nd_adfR_ID_flag_capt = 0
    end    

end





----- BARO INIT -------------------------------------------------------------------------
function B747_baro_init()

    -- CAPT BARO
    --[[if simDR_altimeter_baro_inHg > 29.91
        and simDR_altimeter_baro_inHg < 29.93
    then
        if B747DR_efis_baro_std_capt_switch_pos == 0 then B747CMD_efis_baro_std_capt_switch:once() end
    end]]
    B747DR_efis_baro_std_capt_switch_pos = 0
    B747DR_efis_baro_capt_preselect = 29.92
    simDR_altimeter_baro_inHg =29.92
    B747DR_efis_baro_std_capt_show_preselect = 0
    -- F/O BARO
    --[[if simDR_altimeter_baro_inHg_fo > 29.91
        and simDR_altimeter_baro_inHg_fo < 29.93
    then
        if B747DR_efis_baro_std_fo_switch_pos == 0 then B747CMD_efis_baro_std_fo_switch:once() end
    end]]
    B747DR_efis_baro_std_fo_switch_pos = 0
    B747DR_efis_baro_fo_preselect = 29.92
    simDR_altimeter_baro_inHg_fo = 29.92
    B747DR_efis_baro_std_fo_show_preselect = 0
end






----- VERTICAL SPEED INDICATOR ----------------------------------------------------------
function B747_vsi()

    B747DR_vertical_speed_fpm = roundToIncrement(simDR_vvi_fpm_pilot, 50)
end







----- ND MODES --------------------------------------------------------------------------
local seenRASet=0
function B747_nd_EFIS_map_modes()

    local mapCenter=simDR_EFIS_map_is_center--force read state
    --[[if simDR_EFIS_map_mode <= 2 then
        simDR_EFIS_map_is_center = 0
    else
        simDR_EFIS_map_is_center = 1
    end]]
    local capttfc=0
    local fotfc=0
    local capttcas_off=0
    local fotcas_off=0
    if seenRASet==0 and B747DR_xpdr_sel_pos==4 then
      seenRASet=1
    end
    if seenRASet==0 and B747DR_pfd_mode_capt==1 then --TA/RA never selected, ND IRS aligned, TCAS OFF ND Messages
      capttcas_off=1
    elseif B747DR_xpdr_sel_pos<=2 and B747DR_pfd_mode_capt==1 and B747DR_nd_capt_traffic_Selected==1 then
      capttcas_off=1
    elseif B747DR_xpdr_sel_pos>2 and B747DR_pfd_mode_capt==1 and B747DR_nd_capt_traffic_Selected==1 then
      capttfc=1
    end
    
    if seenRASet==0 and B747DR_pfd_mode_fo==1 then --TA/RA never selected, ND IRS aligned, TCAS OFF ND Messages
      fotcas_off=1
    elseif B747DR_xpdr_sel_pos<=2 and B747DR_pfd_mode_fo==1 and B747DR_nd_fo_traffic_Selected==1 then
      fotcas_off=1
    elseif B747DR_xpdr_sel_pos>2 and B747DR_pfd_mode_fo==1 and B747DR_nd_fo_traffic_Selected==1 then
      fotfc=1
    end
    
    if capttfc==1 or fotfc==1 then
      simDR_EFIS_tcas_on=1
    else
      simDR_EFIS_tcas_on=0
    end
    
    B747DR_nd_capt_tfc=capttfc
    B747DR_nd_fo_tfc=fotfc
    B747DR_nd_capt_tcas_off=capttcas_off
    B747DR_nd_fo_tcas_off=fotcas_off
end





----- ND TRACK LINE ---------------------------------------------------------------------
function B747_nd_track_line()

    

    if (B747DR_nd_mode_capt_sel_dial_pos <= 1 and B747DR_nd_center_capt_switch_pos == 0 and (simDR_EFIS_wxr_on > 0.5 or simDR_EFIS_tcas_on > 0.5))
        or
        (B747DR_nd_mode_capt_sel_dial_pos == 2 and B747DR_nd_center_capt_switch_pos == 0)
    then
        B747_exp_nd_track_line_on = 1
    else
      B747_exp_nd_track_line_on = 0
    end

end







----- V-SPEEDS --------------------------------------------------------------------------

-- V1 / Vr / V2 - TEMPERATURE/ALTITUDE REGIONS
local regions = {}
local tempAltRegion = 0

function B747_getTempAltRegions()

    local regTop = {0, 0, 0, 0, 0}
    for region = 1, 5 do
        local lowTempIndex = 1
        for index = 1, #VtempAltRegionData[region] do
            if VtempAltRegionData[region][index].temp <= simDR_OAT_degC then
                lowTempIndex = index
            end
        end
        regTop[region] = B747_rescale(VtempAltRegionData[region][lowTempIndex].temp, VtempAltRegionData[region][lowTempIndex].alt , VtempAltRegionData[region][math.min(#VtempAltRegionData[region], lowTempIndex+1)].temp, VtempAltRegionData[region][math.min(#VtempAltRegionData[region], lowTempIndex+1)].alt, simDR_OAT_degC)
    end
    local regBottom = {-2000, regTop[1], regTop[2], regTop[3], regTop[4]}


    regions = {

        {-- REGION A

            -- DEFINE THE REGION
            l=-60, b=regBottom[1], t=regTop[1], r=46.29,

            -- SET THE CURRENT TEMPERATURE/ALTITUDE REGION
            f = function()
                tempAltRegion = 1
            end,

        },

        {-- REGION B

            -- DEFINE THE REGION
            l=-60.0, b=regBottom[2], t=regTop[2], r=50.16,

            -- SET THE CURRENT TEMPERATURE/ALTITUDE REGION
            f = function()
                tempAltRegion = 2
            end,

        },

        {-- REGION C

            -- DEFINE THE REGION
            l=-60.0, b=regBottom[3], t=regTop[3], r=55.53,

            -- SET THE CURRENT TEMPERATURE/ALTITUDE REGION
            f = function()
                tempAltRegion = 3
            end,

        },

        {-- REGION D

            -- DEFINE THE REGION
            l=-60.0, b=regBottom[4], t=regTop[4], r=60.31,

            -- SET THE CURRENT TEMPERATURE/ALTITUDE REGION
            f = function()
                tempAltRegion = 4
            end,

        },

        {-- REGION E

            -- DEFINE THE REGION
            l=-60.0, b=regBottom[5], t=regTop[5], r=64.80,

            -- SET THE CURRENT TEMPERATURE/ALTITUDE REGION
            f = function()
                tempAltRegion = 5
            end,

        }

    }

end

function B747_setTempAltRegion()

    B747_getTempAltRegions()

    local num_regions = #regions

    for i=1, num_regions do

        local r = regions[i]

        if (simDR_OAT_degC > r.l) and (simDR_OAT_degC < r.r) then

            if (simDR_altitude_ft_pilot > r.b) and (simDR_altitude_ft_pilot < r.t) then

                r.f()

                return true

            end -- ALTITUDE TEST
        end -- TEMPERATURE TEST
    end -- LOOP ALL REGIONS

    return false

end




-- V1 WIND ADJUSTMENT
local B747_V1windAdj = 0
function B747_V1_wind_adjustment()

    local weight_max = math.min(420000, roundUpToIncrement(simDR_acf_weight_total_kg, 20000))
    local weight_min = math.max(200000, weight_max-20000)
    local HW = simDR_wind_speed_kts * math.cos(math.rad(recipAngle(simDR_wind_heading_deg))-math.rad(simDR_position_mag_psi))
    local HWmax = 0
    local HWmin = 0

    if HW < 0 then
        HWmin = math.max(-15, roundDownToIncrement(HW, 5))
        HWmax = math.min(0, HWmin + 5)
     elseif HW > 0 then
        HWmax = math.min(40, roundUpToIncrement(HW, 10))
        HWmin = math.max(0, HWmax - 10)
    end

    B747_V1windAdj = B747_rescale(HWmin, V1windAdj[HWmin][weight_min], HWmax, V1windAdj[HWmax][weight_max], simDR_wind_speed_kts)

end




B747DR_airspeed_flapsRef                              = find_dataref("laminar/B747/airspeed/flapsRef")
-- V1 / Vr / V2
function B747_setV1VrV2()

    local weight_max = math.min(420000, roundUpToIncrement(simDR_acf_weight_total_kg, 20000))
    local weight_min = math.max(200000, weight_max-20000)
    local flaps = roundToIncrement(B747DR_airspeed_flapsRef, 10)
    if B747DR_radio_altitude>1000 then
        B747DR_airspeed_flapsRef=0
    end

    if flaps >= 10.0 and flaps <= 20.0 then

        -- V1
        B747DR_airspeed_V1 = B747_rescale(weight_min, B747_V1[flaps][tempAltRegion][weight_min], weight_max, B747_V1[flaps][tempAltRegion][weight_max], simDR_acf_weight_total_kg)
        B747DR_airspeed_V1 = B747DR_airspeed_V1 + B747_V1windAdj

        -- Vr
        B747DR_airspeed_Vr = B747_rescale(weight_min, B747_Vr[flaps][tempAltRegion][weight_min], weight_max, B747_Vr[flaps][tempAltRegion][weight_max], simDR_acf_weight_total_kg)

        -- V2
        B747DR_airspeed_V2 = B747_rescale(weight_min, B747_V2[flaps][tempAltRegion][weight_min], weight_max, B747_V2[flaps][tempAltRegion][weight_max], simDR_acf_weight_total_kg)

    else
	if simDR_all_wheels_on_ground==1 then
	  B747DR_airspeed_V1 = 999.0
	else
	  B747DR_airspeed_V1 = 998.0 --only show no vspd on the ground
	end
        B747DR_airspeed_Vr = 999.0
        B747DR_airspeed_V2 = 999.0

    end

    -- crazytimtimtim V1 callout
    if simDR_airspeed >= B747DR_airspeed_V1 and
    simDR_all_wheels_on_ground == 1 and
    B747DR_airspeed_V1 > 0 and
    B747DR_toga_mode ~= 0 then
        B747DR_v1_alert = 1
    else
        B747DR_v1_alert = 0
    end

end





-- Vref30
function B747_setVref30()

    local weight_max = math.min(400000, roundToIncrement(simDR_acf_weight_total_kg, 20000))
    local weight_min = math.max(200000, weight_max-20000)

    local speed = {}
    if simDR_altitude_ft_pilot <= -2000 then speed = Vref30data.speedMinus2k
        elseif simDR_altitude_ft_pilot <= 0 then speed = Vref30data.speed0k
        elseif simDR_altitude_ft_pilot <= 2000 then speed = Vref30data.speed2k
        elseif simDR_altitude_ft_pilot <= 6000 then speed = Vref30data.speed6k
        else speed = Vref30data.speed10k
    end
    B747DR_airspeed_Vref30 = B747_rescale(weight_min, speed[weight_min], weight_max, speed[weight_max], simDR_acf_weight_total_kg)

end



function setVmc(weight,flaps)

    local weight_factor =  B747_rescale(179000.0, 0, 396000.0, 61.0, weight) 
    local flap_Vmc      = 0
    if flaps<1 then
      flap_Vmc      =B747_rescale(0.0, (179), 1.0, 166, flaps) + weight_factor --13/1
    elseif flaps<10 then
      flap_Vmc      =B747_rescale(1.0, 166, 10.0, 137, flaps) + weight_factor --3/1
    else
      flap_Vmc      =B747_rescale(10.0, 137, 30.0, 118, flaps) + weight_factor --0.95/1
    end
    B747DR_airspeed_Vmc = flap_Vmc 
    --print(" " ..weight/1000 .. "t, " .. flaps .. "=" .. math.floor(B747DR_airspeed_Vmc))
end

-- MISC V-SPEEDS
function B747_Vspeeds()

    -- Vf (FLAP DESIGN SPEED)
    B747DR_airspeed_Vf0 = B747DR_airspeed_Vref30+80                     --
    if simDR_acf_weight_total_kg > 309000.0 then B747DR_airspeed_Vf0 = B747DR_airspeed_Vref30+100 end
    B747DR_airspeed_Vf1 = B747DR_airspeed_Vref30+60
    B747DR_airspeed_Vf5 = B747DR_airspeed_Vref30+40
    B747DR_airspeed_Vf10 = B747DR_airspeed_Vref30+20
    B747DR_airspeed_Vf20 = B747DR_airspeed_Vref30+10
    B747DR_airspeed_Vf25 = B747DR_airspeed_Vref30+5
    B747DR_airspeed_Vf30 = B747DR_airspeed_Vref30
    
    
    if simDR_flap_ratio_control <1.0 and simDR_flap_ratio_control>0.66 and (B747DR_airspeed_VrefFlap~=1) then
        B747DR_airspeed_showVf25=1
    else
        B747DR_airspeed_showVf25=0
    end

    if simDR_flap_ratio_control >=0.83 and B747DR_airspeed_VrefFlap==0 then
        B747DR_airspeed_showVf30=1
    else
        B747DR_airspeed_showVf30=0
    end

    if simDR_radio_alt_height_capt< 5.0 then
        B747DR_airspeed_VrefFlap=0
    end

    -- Vfe (MAXIMUM FLAP EXTENDED SPEED - [PLACARD])
    B747DR_airspeed_Vfe1 = 280.0
    B747DR_airspeed_Vfe5 = 260.0
    B747DR_airspeed_Vfe10 = 240.0
    B747DR_airspeed_Vfe20 = 230.0
    B747DR_airspeed_Vfe25 = 205.0
    B747DR_airspeed_Vfe30 = 180.0


    -- Va (DESIGN MANEUVERING SPEED)
    B747DR_airspeed_Va = B747_rescale(0.0, 329.31, 10000.0, 334.78, simDR_altitude_ft_pilot)
    if simDR_altitude_ft_pilot > 10000.0 then B747DR_airspeed_Va = B747_rescale(10000.0, 334.78, 20000.0, 343.52, simDR_altitude_ft_pilot) end
    if simDR_altitude_ft_pilot > 200000.0 then B747DR_airspeed_Va = B747_rescale(20000.0, 343.52, 30000.0, 360.0, simDR_altitude_ft_pilot) end


    -- Vlo / Mlo (MAXIMUM LANDING GEAR OPERATING SPEED)
    -- 270/.820
    B747DR_airspeed_Vlo = 270.0
    B747DR_airspeed_Mlo = 0.820


    -- Vle  /Mle (MAXIMUM LANDING GEAR EXTENDED SPEED)
    -- 320/.820
    B747DR_airspeed_Vle = 320.0
    B747DR_airspeed_Mle = 0.820


    -- Vmc (MINIMIMUM OPERATING (CONTROL) MANEUVERING SPEED) (AMBER RANGE)
    setVmc(simDR_acf_weight_total_kg,simDR_wing_flap1_deg[0])
    
    
    if simDR_airspeed < B747DR_airspeed_Vmc then 
        B747DR_airspeed_window_min = 1 
    else 
        B747DR_airspeed_window_min = 0
    end


    -- Vmo / Mmo (MAXIMUM OPERATING LIMIT SPEED)
   
    if simDR_altitude_ft_pilot > 28620.0 then 
        B747DR_airspeed_Vmo = B747_rescale(28620.0, 365.0, 45000.0, 252.35, simDR_altitude_ft_pilot) 
    else
        B747DR_airspeed_Vmo = 365.0
    end

    if simDR_altitude_ft_pilot <= 28620.0 then B747DR_airspeed_Mmo = 0.880 end
    if simDR_altitude_ft_pilot > 28620.0 then B747DR_airspeed_Mmo = 0.920 end
    B747DR_airspeed_Mms = B747_rescale(20620.0,0.740,28620,0.920,simDR_altitude_ft_pilot)


    -- Vne / Mne (NEVER EXCEED SPEED)
    B747DR_airspeed_Vne = 365.0
    B747DR_airspeed_Mne = 0.920


    -- Vmax (MAXIMUM SPEED -  HIGH SPEED RED CHECKER BOX ON ASI
    local flapSpeed = B747DR_airspeed_Vmo
    if simDR_wing_flap1_deg[0] > 0.0 and simDR_wing_flap1_deg[0] <= 1.0 then
        flapSpeed = B747_rescale(0.0, B747DR_airspeed_Vmo, 1.0, B747DR_airspeed_Vfe1, simDR_wing_flap1_deg[0])
    elseif simDR_wing_flap1_deg[0] > 1.0 and simDR_wing_flap1_deg[0] <= 5.0 then
        flapSpeed = B747_rescale(1.0, B747DR_airspeed_Vfe1, 5.0, B747DR_airspeed_Vfe5, simDR_wing_flap1_deg[0])
    elseif simDR_wing_flap1_deg[0] > 5.0 and simDR_wing_flap1_deg[0] <= 10.0 then
        flapSpeed = B747_rescale(5.0, B747DR_airspeed_Vfe5, 10.0, B747DR_airspeed_Vfe10, simDR_wing_flap1_deg[0])
    elseif simDR_wing_flap1_deg[0] > 10.0 and simDR_wing_flap1_deg[0] <= 20.0 then
        flapSpeed = B747_rescale(10.0, B747DR_airspeed_Vfe10, 20.0, B747DR_airspeed_Vfe20, simDR_wing_flap1_deg[0])
    elseif simDR_wing_flap1_deg[0] > 20.0 and simDR_wing_flap1_deg[0] <= 25.0 then
        flapSpeed = B747_rescale(20.0, B747DR_airspeed_Vfe20, 25.0, B747DR_airspeed_Vfe25, simDR_wing_flap1_deg[0])
    elseif simDR_wing_flap1_deg[0] > 25.0 and simDR_wing_flap1_deg[0] <= 30.0 then
        flapSpeed = B747_rescale(25.0, B747DR_airspeed_Vfe25, 30.0, B747DR_airspeed_Vfe30, simDR_wing_flap1_deg[0])
    end

    local gearSpeed = B747DR_airspeed_Vmo
    gearSpeed = B747_rescale(0.0, B747DR_airspeed_Vmo, 1.0, B747DR_airspeed_Vle, simDR_gear_deploy_ratio[0])

    B747DR_airspeed_Vmax = math.min(B747DR_airspeed_Vmo, flapSpeed, gearSpeed)

    -- Vmaxm (MAXIMUM MANEUVERING SPEED)  (AMBER RANGE)
    B747DR_airspeed_Vmaxm = B747DR_airspeed_Vmax - 10.0

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

-- LOW SPEED RED CHECKER BOX ON ASI
function B747_Vs()

    -- Vs (STALL SPEED OR MINIMUM STEADY FLIGHT SPEED FOR WHICH THE AIRCRAFT IS STILL CONTROLLABLE)
    local weight_max = math.min(400000, roundToIncrement(simDR_acf_weight_total_kg, 20000))
    local weight_min = math.max(200000, weight_max-20000)

    local alt_min = -2000
    local alt_max = 0.0
    if simDR_altitude_ft_pilot >= 0.0 then
        alt_min = 0.0
        alt_max = 2000.0
    elseif simDR_altitude_ft_pilot >= 2000.0 then
        alt_min = 2000.0
        alt_max = 6000.0
    elseif simDR_altitude_ft_pilot >= 6000.0 then
        alt_min = 6000.0
        alt_max = 10000.0
    elseif simDR_altitude_ft_pilot >= 10000.0 then
        alt_min = 10000.0
        alt_max = 10000.0
    end

    local flap_min = 0
    local flap_max = 0
    if simDR_wing_flap1_deg[0] >= 0.01 and simDR_wing_flap1_deg[0] < 1.0 then
        flap_min = 0
        flap_max = 1
    elseif simDR_wing_flap1_deg[0] >= 0.99 and simDR_wing_flap1_deg[0] < 1.01 then
        flap_min = 1
        flap_max = 1
    elseif simDR_wing_flap1_deg[0] >= 1.01 and simDR_wing_flap1_deg[0] < 4.99 then
        flap_min = 1
        flap_max = 5
    elseif simDR_wing_flap1_deg[0] >= 4.99 and simDR_wing_flap1_deg[0] < 5.01 then
        flap_min = 5
        flap_max = 5
    elseif simDR_wing_flap1_deg[0] >= 5.01 and simDR_wing_flap1_deg[0] < 9.99 then
        flap_min = 5
        flap_max = 10
    elseif simDR_wing_flap1_deg[0] >= 9.99 and simDR_wing_flap1_deg[0] < 10.01 then
        flap_min = 10
        flap_max = 10
    elseif simDR_wing_flap1_deg[0] >= 10.01 and simDR_wing_flap1_deg[0] < 19.99 then
        flap_min = 10
        flap_max = 20
    elseif simDR_wing_flap1_deg[0] >= 19.99 and simDR_wing_flap1_deg[0] < 20.01 then
        flap_min = 20
        flap_max = 20
    elseif simDR_wing_flap1_deg[0] >= 20.01 and simDR_wing_flap1_deg[0] < 24.99 then
        flap_min = 20
        flap_max = 25
    elseif simDR_wing_flap1_deg[0] >= 24.99 and simDR_wing_flap1_deg[0] < 25.01 then
        flap_min = 25
        flap_max = 25
    elseif simDR_wing_flap1_deg[0] >= 25.01 and simDR_wing_flap1_deg[0] < 29.99 then
        flap_min = 25
        flap_max = 30
    elseif simDR_wing_flap1_deg[0] >= 29.99 then
        flap_min = 30
        flap_max = 30
    end

    local weight_min_index          = weight_min*0.001
    local weight_max_index          = weight_max*0.001
    local Vs_min_flap_min_alt_speed = B747_rescale(weight_min, VsData[flap_min][alt_min][weight_min_index], weight_max, VsData[flap_min][alt_min][weight_max_index], simDR_acf_weight_total_kg)
    local Vs_min_flap_max_alt_speed = B747_rescale(weight_min, VsData[flap_min][alt_max][weight_min_index], weight_max, VsData[flap_min][alt_max][weight_max_index], simDR_acf_weight_total_kg)
    local Vs_min_flap_alt_speed     = B747_rescale(alt_min, Vs_min_flap_min_alt_speed, alt_max, Vs_min_flap_max_alt_speed, simDR_altitude_ft_pilot)
    local Vs_max_flap_min_alt_speed = B747_rescale(weight_min, VsData[flap_max][alt_min][weight_min_index], weight_max, VsData[flap_max][alt_min][weight_max_index], simDR_acf_weight_total_kg)
    local Vs_max_flap_max_alt_speed = B747_rescale(weight_min, VsData[flap_max][alt_max][weight_min_index], weight_max, VsData[flap_max][alt_max][weight_max_index], simDR_acf_weight_total_kg)
    local Vs_max_flap_alt_speed     = B747_rescale(alt_min, Vs_max_flap_min_alt_speed, alt_max, Vs_max_flap_max_alt_speed, simDR_altitude_ft_pilot)
    local target_airspeed_Vs              = B747_rescale(flap_min, Vs_min_flap_alt_speed, flap_max, Vs_max_flap_alt_speed, simDR_wing_flap1_deg[0])
    if simDR_airspeed > target_airspeed_Vs then
        local numStalled=0
        for i=0,320 do
            if simDR_stalled_elements[i]>0 then
                numStalled=numStalled+1
            end
        end
        local vSAOA=0
        if numStalled > 0 then
            vSAOA=(target_airspeed_Vs-simDR_airspeed)*(0-numStalled)/10
            vSAOA=math.min(vSAOA,simDR_airspeed+15-target_airspeed_Vs)
            if simDR_all_wheels_on_ground==0 then
                simDR_autopilot_TOGA_pitch_deg=15-(17*numStalled/10)
                --print("simDR_autopilot_TOGA_pitch_deg1="..simDR_autopilot_TOGA_pitch_deg)
            end

        elseif simDR_all_wheels_on_ground==1 then
            simDR_autopilot_TOGA_pitch_deg=8
        else
            local tSpeed=target_airspeed_Vs+20
            if B747DR_airspeed_V2<900 then
                tSpeed=B747DR_airspeed_V2+10
            end
            simDR_autopilot_TOGA_pitch_deg=B747_rescale(target_airspeed_Vs,2,tSpeed,15,simDR_airspeed) 
            --print("simDR_autopilot_TOGA_pitch_deg2="..simDR_autopilot_TOGA_pitch_deg) 
        end
        B747DR_airspeed_Vs=B747_animate_value(B747DR_airspeed_Vs,target_airspeed_Vs+vSAOA,0,450,1)
        --print(vSAOA)
    else
        B747DR_airspeed_Vs=B747_animate_value(B747DR_airspeed_Vs,target_airspeed_Vs,0,450,1)
        simDR_autopilot_TOGA_pitch_deg=8
        --print("simDR_autopilot_TOGA_pitch_deg3="..simDR_autopilot_TOGA_pitch_deg)
    end
    --simDR_stall_warning=0 -- always set
    if simDR_airspeed<B747DR_airspeed_Vs and simDR_all_wheels_on_ground==0 then
        simDR_stall_warning=1
    else
        simDR_stall_warning=0
    end
end





-- INIT V1 / Vr / V2
function B747_initV1VrV2()

    B747_setTempAltRegion()
    B747_V1_wind_adjustment()
    B747_setV1VrV2()

end






----- FLIGHT INSTRUMENTS EICAS MESSAGES -------------------------------------------------
function B747_baro_disagree()
    --if math.abs(B747DR_efis_baro_capt_set_dial_pos - B747DR_efis_baro_fo_set_dial_pos) > 0.01 then
    if math.abs(simDR_altimeter_baro_inHg - simDR_altimeter_baro_inHg_fo) > 0.01 then  
        B747DR_CAS_advisory_status[18] = 1
    end
end

local last_batt_chg_watt_hr = 0
local last_chg_watt_hr = 0
function B747_fltInst_EICAS_msg()

    -- OVERSPEED
    
    if simDR_airspeed > B747DR_airspeed_Vmax
        or simDR_airspeed_mach > B747DR_airspeed_Mmo
    then
        B747DR_CAS_warning_status[22] = 1
    else
        B747DR_CAS_warning_status[22] = 0
    end

    -- >AIRSPEED LOW
    
    if (simDR_airspeed < B747DR_airspeed_Vmc or simDR_airspeed < B747DR_airspeed_Vs)
        and simDR_radio_alt_height_capt > 100.0
    then
        B747DR_CAS_caution_status[0] = 1
    else
        B747DR_CAS_caution_status[0] = 0
    end

    -- >AOA RIGHT
    
    if simDR_AOA_fail == 6 then 
        B747DR_CAS_advisory_status[12] = 1 
    else
        B747DR_CAS_advisory_status[12] = 0
    end

    -- >BARO DISAGREE
    --if math.abs(B747DR_efis_baro_capt_set_dial_pos - B747DR_efis_baro_fo_set_dial_pos) > 0.01 then
    if math.abs(simDR_altimeter_baro_inHg - simDR_altimeter_baro_inHg_fo) > 0.01 then  
        if is_timer_scheduled(B747_baro_disagree) == false then
            run_after_time(B747_baro_disagree, 60.0)
        end
    else
        B747DR_CAS_advisory_status[18] = 0
         if is_timer_scheduled(B747_baro_disagree) == true then
            stop_timer(B747_baro_disagree)
        end
    end

    -- >BAT DISCH MAIN
    
    if simDR_battery_chg_watt_hr[0] < last_batt_chg_watt_hr  then
        if simDR_battery_chg_watt_hr[0]+2 < last_chg_watt_hr  then
            B747DR_CAS_advisory_status[20] = 1
        end
    elseif B747DR_elec_standby_power_sel_pos<2 then  
        B747DR_CAS_advisory_status[20] = 0
        last_chg_watt_hr=simDR_battery_chg_watt_hr[0]
    end    


    -- >BATTERY OFF
    
    if B747DR_button_switch_position[13] < 0.05 then 
        B747DR_CAS_advisory_status[21] = 1 
    else
        B747DR_CAS_advisory_status[21] = 0
    end

    last_batt_chg_watt_hr = simDR_battery_chg_watt_hr[0]
    

end


function fltInstsetCRTs()
  
  
    local crtState=B747DR_flt_inst_inbd_disp_capt_sel_dial_pos
    + 3*B747DR_flt_inst_lwr_disp_capt_sel_dial_pos
    + 9*B747DR_flt_inst_inbd_disp_fo_sel_dial_pos
    + 27*B747DR_flt_inst_lwr_disp_fo_sel_dial_pos
    --print(crtState)
    
    local capt_power=6-B747DR_simDR_captain_display
    local fo_power=6-B747DR_simDR_fo_display
    
    -- Captain PFD 0
    -- First Officer PFD 1
    -- First Officer ND 2
    -- Captain ND 3
    -- Upper EIACAS 4
    -- Lower EICAS 5
    -- FMS L -- in electrical
    -- FMS R-- in electrical
    -- FMS C-- in electrical
    if crtState==40 then -- all normal
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0
     B747DR_flt_inst_capt_nd_pos      	= 0
     B747DR_flt_inst_fo_nd_pos      	= 0
     B747DR_flt_inst_eicas_pos      	= 0
     B747DR_flt_inst_pri_eicas_pos      = 0
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=fo_power
    elseif crtState==39 then --capt inbd to eicas
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0
     B747DR_flt_inst_capt_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_fo_nd_pos      	= 0
     B747DR_flt_inst_eicas_pos      	= 2 --EICAS to ND
     B747DR_flt_inst_pri_eicas_pos      = 0
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=fo_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=capt_power
    elseif crtState==41 then --capt inbd to PFD
     B747DR_flt_inst_capt_pfd_pos      	= 1 --PFD to ND
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_fo_nd_pos      	= 0
     B747DR_flt_inst_eicas_pos      	= 3 --EICAS to PFD
     B747DR_flt_inst_pri_eicas_pos      = 0
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=fo_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=capt_power
    elseif crtState==37 then --capt lwr to eicas pri
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= 0 
     B747DR_flt_inst_fo_nd_pos      	= 0
     B747DR_flt_inst_eicas_pos      	= 5 --EICAS to Upper
     B747DR_flt_inst_pri_eicas_pos      = 1 --PRI EIACS to lower
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=fo_power
     B747DR_elec_display_power[5]=capt_power
    elseif crtState==43 then --capt lwr to ND
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_fo_nd_pos      	= 0
     B747DR_flt_inst_eicas_pos      	= 5 --EICAS to Upper
     B747DR_flt_inst_pri_eicas_pos      = 2 --PRI EIACS to ND
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=fo_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=capt_power
    elseif crtState==49 then --fo inbd to eicas
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0
     B747DR_flt_inst_capt_nd_pos      	= 0 
     B747DR_flt_inst_fo_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_eicas_pos      	= 1 --EICAS to FO ND
     B747DR_flt_inst_pri_eicas_pos      = 0
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=fo_power
    elseif crtState==31 then --fo inbd to PFD
     B747DR_flt_inst_capt_pfd_pos      	= 0 --PFD to ND
     B747DR_flt_inst_fo_pfd_pos      	= 1 
     B747DR_flt_inst_capt_nd_pos      	= 0 --ND to Lower EICAS
     B747DR_flt_inst_fo_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_eicas_pos      	= 4 --EICAS to PFD
     B747DR_flt_inst_pri_eicas_pos      = 0
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=fo_power
    elseif crtState==67 then --fo lwr to eicas pri
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= 0 
     B747DR_flt_inst_fo_nd_pos      	= 0
     B747DR_flt_inst_eicas_pos      	= 5 --EICAS to Upper
     B747DR_flt_inst_pri_eicas_pos      = 1 --PRI EIACS to lower
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=fo_power
     B747DR_elec_display_power[5]=capt_power
    elseif crtState==13 then --fo lwr to ND
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= 0 
     B747DR_flt_inst_fo_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_eicas_pos      	= 5 --EICAS to Upper
     B747DR_flt_inst_pri_eicas_pos      = 3 --PRI EIACS to ND
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=capt_power
    elseif crtState==12 then --capt inbd to eicas - fo lwr to ND
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= -1 -- No capt ND
     B747DR_flt_inst_fo_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_eicas_pos      	= 2 --EICAS to capt ND
     B747DR_flt_inst_pri_eicas_pos      = 3 --PRI EIACS to ND
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=capt_power
     B747DR_elec_display_power[4]=fo_power
     B747DR_elec_display_power[5]=capt_power
     elseif crtState==52 then --fo inbd to eicas - capt lwr to ND
     B747DR_flt_inst_capt_pfd_pos      	= 0
     B747DR_flt_inst_fo_pfd_pos      	= 0 
     B747DR_flt_inst_capt_nd_pos      	= 1 --ND to Lower EICAS
     B747DR_flt_inst_fo_nd_pos      	= -1 -- No FO ND
     B747DR_flt_inst_eicas_pos      	= 1 --EICAS to fo ND
     B747DR_flt_inst_pri_eicas_pos      = 2 --PRI EIACS to capt ND
     B747DR_elec_display_power[0]=capt_power
     B747DR_elec_display_power[1]=fo_power
     B747DR_elec_display_power[2]=fo_power
     B747DR_elec_display_power[3]=fo_power
     B747DR_elec_display_power[4]=capt_power
     B747DR_elec_display_power[5]=fo_power
    end
end







----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_inst_monitor_AI()

    if B747DR_init_inst_CD == 1 then
        B747_set_inst_all_modes()
        B747_set_inst_CD()
        B747DR_init_inst_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_inst_all_modes()

	B747DR_init_inst_CD = 0
	
    B747DR_STAT_msg_page = 1
    B747DR_STAT_num_msg_pages = 1

--[[
    B747DR_clock_captain_chrono_mode = B747_RESET
    B747DR_clock_fo_chrono_mode = B747_RESET
--]]
    
    
    B747DR_dsp_synoptic_display = 1
    B747_baro_init()

    B747DR_flt_inst_inbd_disp_capt_sel_dial_pos = 1
    B747DR_flt_inst_lwr_disp_capt_sel_dial_pos = 1
    B747DR_flt_inst_eiu_src_capt_dial_pos = 1

    B747DR_flt_inst_inbd_disp_fo_sel_dial_pos = 1
    B747DR_flt_inst_lwr_disp_fo_sel_dial_pos = 1

    B747DR_flt_inst_eiu_src_ctr_pnl_dial_pos = 1

    B747DR_flt_inst_fd_src_fo_dial_pos = 2
    B747DR_flt_inst_nav_src_fo_dial_pos = 3

    B747DR_flt_inst_eiu_src_fo_dial_pos = 2
    B747DR_flt_inst_irs_src_fo_dial_pos = 2
    B747DR_flt_inst_air_data_src_fo_dial_pos = 1

    --if simDR_EFIS_map_mode == 3 then simDR_EFIS_map_mode = 0 end
    simDR_EFIS_map_mode = 1 
    B747DR_nd_mode_capt_sel_dial_pos = simDR_EFIS_map_mode

    B747DR_nd_range_capt_sel_dial_pos = simDR_EFIS_map_range
    B747DR_nd_range_fo_sel_dial_pos = B747DR_nd_range_capt_sel_dial_pos

    simDR_EFIS_1_sel_pilot = 1
    simDR_EFIS_2_sel_pilot = 1
    simDR_EFIS_1_sel_fo = 1
    simDR_EFIS_2_sel_fo = 1

    B747DR_nd_capt_vor_ndb = 0
    B747DR_nd_fo_vor_ndb = 0
    B747DR_nd_capt_wpt = 0
    B747DR_nd_fo_wpt = 0
    B747DR_nd_capt_apt = 0
    B747DR_nd_fo_apt = 0
    simDR_EFIS_apt = 0
    simDR_EFIS_fix = 0
    simDR_EFIS_vor = 0
    simDR_EFIS_ndb = 0

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_inst_CD()
  simDR_EFIS_tcas_on=0
  B747DR_nd_capt_tfc=0


end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_inst_ER()
    simDR_EFIS_tcas_on=0
    B747DR_nd_capt_tfc=0

	
end






----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_fltInst()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_inst_all_modes()



    -- DEFERRED INIT





    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then    
    
    	B747_set_inst_CD()





    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then
	    
		B747_set_inst_ER()


	end

end











--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end


--function aircraft_unload() end


function flight_start()
    simDR_has_stall_warning=0
    simDR_autopilot_TOGA_pitch_deg      = 8.0
    B747_flight_start_fltInst()

end


--function flight_crash() end


--function before_physics() end

debug_fltinst     = deferred_dataref("laminar/B747/debug/fltinst", "number")
function after_physics()
  if debug_fltinst>0 then return end

    --B747_captain_clock()
    --B747_fo_clock()
    
    B747_fltInst_capt_get_clock_year()
    B747_fltInst_capt_elapsed_timer()
    B747_fltInst_capt_chrono_timer()
    
    B747_fltInst_fo_get_clock_year()
    B747_fltInst_fo_elapsed_timer()
    B747_fltInst_fo_chrono_timer()
    
    B747_rmi()
    B747_altimteter()
    B747_decision_height_capt()
    B747_radio_altitude()
    B747_ND_nav_rad_ID()
    B747_vsi()

    B747_loc_gs_vis_flags()

    --simDR_EFIS_map_is_center = 0                                                        -- FORCE TO (PERSISTENT) EXPANDED MODE
    B747_nd_EFIS_map_modes()
    B747_nd_track_line()

    B747_setVref30()
    B747_Vspeeds()
    B747_Vs()

    B747_setTempAltRegion()
    B747_V1_wind_adjustment()
    B747_setV1VrV2()

    B747_fltInst_EICAS_msg()

    B747_inst_monitor_AI()
    fltInstsetCRTs()
end


--function after_replay() end


