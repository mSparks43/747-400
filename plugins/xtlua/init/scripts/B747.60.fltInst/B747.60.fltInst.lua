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

B747DR_flt_inst_capt_pfd_pos      		= deferred_dataref("laminar/B747/flt_inst/display/capt/pfd_pos", "number")
B747DR_flt_inst_fo_pfd_pos      		= deferred_dataref("laminar/B747/flt_inst/display/fo/pfd_pos", "number")
B747DR_flt_inst_capt_nd_pos      		= deferred_dataref("laminar/B747/flt_inst/display/capt/nd_pos", "number")
B747DR_flt_inst_fo_nd_pos      			= deferred_dataref("laminar/B747/flt_inst/display/fo/nd_pos", "number")
B747DR_flt_inst_eicas_pos      			= deferred_dataref("laminar/B747/flt_inst/display/eicas_pos", "number")
B747DR_flt_inst_pri_eicas_pos      		= deferred_dataref("laminar/B747/flt_inst/display/pri_eicas_pos", "number")

B747DR_flt_inst_inbd_disp_fo_sel_dial_pos       = deferred_dataref("laminar/B747/flt_inst/fo_inbd_display/sel_dial_pos", "number")
B747DR_flt_inst_lwr_disp_fo_sel_dial_pos        = deferred_dataref("laminar/B747/flt_inst/fo_lwr_display/sel_dial_pos", "number")

B747DR_efis_min_ref_alt_capt_sel_dial_pos       = deferred_dataref("laminar/B747/efis/min_ref_alt/capt/sel_dial_pos", "number")
B747DR_efis_ref_alt_capt_set_dial_pos           = deferred_dataref("laminar/B747/efis/ref_alt/capt/set_dial_pos", "number")
B747DR_efis_dh_reset_capt_switch_pos            = deferred_dataref("laminar/B747/efis/dh_reset/capt/switch_pos", "number")
B747DR_efis_baro_ref_capt_sel_dial_pos          = deferred_dataref("laminar/B747/efis/baro_ref/capt/sel_dial_pos", "number")
B747DR_efis_baro_std_capt_switch_pos            = deferred_dataref("laminar/B747/efis/baro_std/capt/switch_pos", "number")
B747DR_efis_baro_capt_set_dial_pos              = deferred_dataref("laminar/B747/efis/baro/capt/set_dial_pos", "number")
B747DR_efis_baro_capt_preselect                 = deferred_dataref("laminar/B747/efis/baro/capt/preselect", "number")
B747DR_efis_baro_alt_ref_capt                   = deferred_dataref("laminar/B747/efis/baro_ref/capt", "number")

B747DR_efis_min_ref_alt_fo_sel_dial_pos         = deferred_dataref("laminar/B747/efis/min_ref_alt/fo/sel_dial_pos", "number")
B747DR_efis_ref_alt_fo_set_dial_pos             = deferred_dataref("laminar/B747/efis/ref_alt/fo/set_dial_pos", "number")
B747DR_efis_dh_reset_fo_switch_pos              = deferred_dataref("laminar/B747/efis/dh_reset/fo/switch_pos", "number")
B747DR_efis_baro_ref_fo_sel_dial_pos            = deferred_dataref("laminar/B747/efis/baro_ref/fo/sel_dial_pos", "number")
B747DR_efis_baro_std_fo_switch_pos              = deferred_dataref("laminar/B747/efis/baro_std/fo/switch_pos", "number")
B747DR_efis_baro_fo_set_dial_pos                = deferred_dataref("laminar/B747/efis/baro/fo/set_dial_pos", "number")
B747DR_efis_baro_fo_preselect                   = deferred_dataref("laminar/B747/efis/baro/fo/preselect", "number")
B747DR_efis_baro_alt_ref_fo                     = deferred_dataref("laminar/B747/efis/baro_ref/fo", "number")

B747DR_efis_fpv_capt_switch_pos                 = deferred_dataref("laminar/B747/efis/fpv/capt/switch_pos", "number")
B747DR_efis_meters_capt_switch_pos              = deferred_dataref("laminar/B747/efis/meters/capt/switch_pos", "number")
B747DR_efis_meters_capt_selected                = deferred_dataref("laminar/B747/efis/meters/capt/selected", "number")

B747DR_efis_fpv_fo_switch_pos                   = deferred_dataref("laminar/B747/efis/fpv/fo/switch_pos", "number")
B747DR_efis_meters_fo_switch_pos                = deferred_dataref("laminar/B747/efis/meters/fo/switch_pos", "number")
B747DR_efis_meters_fo_selected                  = deferred_dataref("laminar/B747/efis/meters/fo/selected", "number")

B747DR_pfd_mode_capt		                = deferred_dataref("laminar/B747/pfd/capt/irs", "number")
B747DR_pfd_mode_fo		                = deferred_dataref("laminar/B747/pfd/fo/irs", "number")

B747DR_nd_mode_capt_sel_dial_pos                = deferred_dataref("laminar/B747/nd/mode/capt/sel_dial_pos", "number")
B747DR_nd_range_capt_sel_dial_pos               = deferred_dataref("laminar/B747/nd/range/capt/sel_dial_pos", "number")

B747DR_nd_center_capt_switch_pos                = deferred_dataref("laminar/B747/nd/center/capt/switch_pos", "number")
B747DR_nd_traffic_capt_switch_pos               = deferred_dataref("laminar/B747/nd/traffic/capt/switch_pos", "number")

B747_nd_map_center_capt                         = deferred_dataref("laminar/B747/nd/map_center/capt", "number")
B747_nd_map_center_fo                           = deferred_dataref("laminar/B747/nd/map_center/fo", "number")
B747DR_nd_mode_fo_sel_dial_pos                  = deferred_dataref("laminar/B747/nd/mode/fo/sel_dial_pos", "number")
B747DR_nd_range_fo_sel_dial_pos                 = deferred_dataref("laminar/B747/nd/range/fo/sel_dial_pos", "number")

B747DR_nd_center_fo_switch_pos                  = deferred_dataref("laminar/B747/nd/center/fo/switch_pos", "number")
B747DR_nd_traffic_fo_switch_pos                 = deferred_dataref("laminar/B747/nd/traffic/fo/switch_pos", "number")



B747DR_nd_wxr_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/wxr/capt/switch_pos", "number")
B747DR_nd_sta_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/sta/capt/switch_pos", "number")
B747DR_nd_wpt_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/wpt/capt/switch_pos", "number")
B747DR_nd_arpt_capt_switch_pos                  = deferred_dataref("laminar/B747/nd/arpt/capt/switch_pos", "number")
B747DR_nd_data_capt_switch_pos                  = deferred_dataref("laminar/B747/nd/data/capt/switch_pos", "number")
B747DR_nd_pos_capt_switch_pos                   = deferred_dataref("laminar/B747/nd/pos/capt/switch_pos", "number")
B747DR_nd_terr_capt_switch_pos                  = deferred_dataref("laminar/B747/nd/terr/capt/switch_pos", "number")

B747DR_nd_capt_vor_ndb                          = deferred_dataref("laminar/B747/nd/data/capt/vor_ndb", "number")
B747DR_nd_fo_vor_ndb                          	= deferred_dataref("laminar/B747/nd/data/fo/vor_ndb", "number")
B747DR_nd_capt_wpt                          = deferred_dataref("laminar/B747/nd/data/capt/wpt", "number")
B747DR_nd_fo_wpt                         	= deferred_dataref("laminar/B747/nd/data/fo/wpt", "number")
B747DR_nd_capt_apt	                        = deferred_dataref("laminar/B747/nd/data/capt/apt", "number")
B747DR_nd_fo_apt	                        = deferred_dataref("laminar/B747/nd/data/fo/apt", "number")
B747DR_nd_capt_tfc	                        = deferred_dataref("laminar/B747/nd/capt/tfc", "number")
B747DR_nd_fo_tfc	                        = deferred_dataref("laminar/B747/nd/fo/tfc", "number")

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
B747DR_nd_capt_traffic_Selected                 = deferred_dataref("laminar/B747/nd/traffic/capt/selected", "number")
B747DR_nd_fo_traffic_Selected                   = deferred_dataref("laminar/B747/nd/traffic/fo/selected", "number")
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


B747DR_RMI_left_bearing                         = deferred_dataref("laminar/B747/rmi_left/captain/bearing", "number")
B747DR_RMI_right_bearing                        = deferred_dataref("laminar/B747/rmi_right/captain/bearing", "number")

B747DR_alt_hectopascal                          = deferred_dataref("laminar/B747/altimeter/baro_hectopascal", "number")
B747DR_altimter_ft_adjusted                     = deferred_dataref("laminar/B747/altimeter/ft_adjusted", "number")

B747DR_dec_ht_display_status                    = deferred_dataref("laminar/B747/dec_height/display_status", "number")
B747DR_radio_alt_display_status                 = deferred_dataref("laminar/B747/radio_alt/display_status", "number")

B747DR_radio_altitude                           = deferred_dataref("laminar/B747/efis/radio_altitude", "number")

B747DR_vertical_speed_fpm                       = deferred_dataref("laminar/B747/vsi/fpm", "number")

B747DR_airspeed_debugspeed                             = deferred_dataref("laminar/B747/airspeed/debugspeed", "number")
B747DR_airspeed_flapsRef                              = deferred_dataref("laminar/B747/airspeed/flapsRef", "number")
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
B747DR_airspeed_Vle                             = deferred_dataref("laminar/B747/airspeed/Vle", "number")
B747DR_airspeed_Mle                             = deferred_dataref("laminar/B747/airspeed/Mle", "number")
B747DR_airspeed_Vmo                             = deferred_dataref("laminar/B747/airspeed/Vmo", "number")
B747DR_airspeed_Mmo                             = deferred_dataref("laminar/B747/airspeed/Mmo", "number")
B747DR_airspeed_Vmc                             = deferred_dataref("laminar/B747/airspeed/Vmc", "number")
B747DR_airspeed_Vne                             = deferred_dataref("laminar/B747/airspeed/Vne", "number")
B747DR_airspeed_Mne                             = deferred_dataref("laminar/B747/airspeed/Mne", "number")
B747DR_airspeed_Vref30                          = deferred_dataref("laminar/B747/airspeed/Vref30", "number")
B747DR_airspeed_Vmax                            = deferred_dataref("laminar/B747/airspeed/Vmax", "number")
B747DR_airspeed_Vmaxm                           = deferred_dataref("laminar/B747/airspeed/Vmaxm", "number")
B747DR_airspeed_Vs                              = deferred_dataref("laminar/B747/airspeed/Vs", "number")

B747DR_airspeed_window_min                      = deferred_dataref("laminar/B747/airspeed_window/min", "number")

B747DR_init_inst_CD                             = deferred_dataref("laminar/B747/inst/init_CD", "number")

B747DR_loc_ptr_vis_capt                         = deferred_dataref("laminar/B747/localizer_ptr/visibility_flag_capt", "number")
B747DR_loc_scale_vis_capt                       = deferred_dataref("laminar/B747/localizer_scale/visibility_flag_capt", "number")
B747DR_glideslope_ptr_vis_capt                  = deferred_dataref("laminar/B747/glideslope_ptr/visibility_flag_capt", "number")
B747DR_loc_ptr_vis_fo                           = deferred_dataref("laminar/B747/localizer_ptr/visibility_flag_fo", "number")
B747DR_loc_scale_vis_fo                         = deferred_dataref("laminar/B747/localizer_scale/visibility_flag_fo", "number")
B747DR_glideslope_ptr_vis_fo                    = deferred_dataref("laminar/B747/glideslope_ptr/visibility_flag_fo", "number")


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
B747CMD_ai_fltinst_quick_start			= deferred_command("laminar/B747/ai/fltinst_quick_start", "number", B747_ai_fltinst_quick_start_CMDhandler)


B747DR_fltInst_capt_clock_CHR_switch_pos	= deferred_dataref("laminar/B747/fltInst/capt/clock_chr_sw_pos", "number")
B747DR_fltInst_capt_clock_DATE_switch_pos	= deferred_dataref("laminar/B747/fltInst/capt/clock_date_sw_pos", "number")
B747DR_fltInst_capt_clock_ET_sel_pos		= deferred_dataref("laminar/B747/fltInst/capt/clock_et_sel_pos", "number")				-- 0=HLD, 1=RUN, 2=RESET 
B747DR_fltInst_capt_clock_SET_sel_pos		= deferred_dataref("laminar/B747/fltInst/capt/clock_set_sel_pos", "number")		
B747DR_fltInst_capt_clock_UTC_display		= deferred_dataref("laminar/B747/fltInst/capt/clock_utc_display", "number")				-- 0=TIME, 1=DATE
B747DR_fltInst_capt_clock_DATE_display_mode	= deferred_dataref("laminar/B747/fltInst/capt/clock_date_display_mode", "number")			-- 0=DAY/MONTH, 1=YEAR	
B747DR_fltInst_capt_clock_ET_CHR_display	= deferred_dataref("laminar/B747/fltInst/capt/clock_et_chr_display", "number")			-- 0=ET, 1=CHR	
B747DR_fltInst_capt_clock_ET_minutes		= deferred_dataref("laminar/B747/fltInst/capt/clock_et_minutes", "number")
B747DR_fltInst_capt_clock_ET_hours			= deferred_dataref("laminar/B747/fltInst/capt/clock_et_hours", "number")
B747DR_fltInst_capt_clock_CHR_seconds		= deferred_dataref("laminar/B747/fltInst/capt/clock_chr_seconds", "number")
B747DR_fltInst_capt_clock_CHR_minutes		= deferred_dataref("laminar/B747/fltInst/capt/clock_chr_minutes", "number")
B747DR_fltInst_capt_clock_year				= deferred_dataref("laminar/B747/fltInst/capt/clock_year", "number")


B747CMD_fltInst_capt_clock_chrono_switch	= deferred_command("laminar/B747/fltInst/capt/clock_chrono_switch", "Captain Clock Chronograph Switch", B747_capt_clock_chrono_switch_CMDhandler)
B747CMD_fltInst_capt_clock_date_switch		= deferred_command("laminar/B747/fltInst/capt/clock_date_switch", "Captain Clock Date Switch", B747_capt_clock_date_switch_CMDhandler)
B747CMD_fltInst_capt_clock_ET_sel_up		= deferred_command("laminar/B747/fltInst/capt/clock_et_sel_up", "Captain Clock ET Selector Up", B747_capt_clock_ET_sel_up_CMDhandler)
B747CMD_fltInst_capt_clock_ET_sel_dn		= deferred_command("laminar/B747/fltInst/capt/clock_et_sel_down", "Captain Clock ET Selector Down", B747_capt_clock_ET_sel_dn_CMDhandler)
B747CMD_fltInst_capt_clock_SET_sel_up		= deferred_command("laminar/B747/fltInst/capt/clock_set_sel_up", "Captain Clock SET Selector Up", B747_capt_clock_SET_sel_up_CMDhandler)
B747CMD_fltInst_capt_clock_SET_sel_dn		= deferred_command("laminar/B747/fltInst/capt/clock_set_sel_down", "Captain Clock SET Selector Down", B747_capt_clock_SET_sel_dn_CMDhandler)


B747DR_fltInst_fo_clock_CHR_switch_pos		= deferred_dataref("laminar/B747/fltInst/fo/clock_chr_sw_pos", "number")
B747DR_fltInst_fo_clock_DATE_switch_pos		= deferred_dataref("laminar/B747/fltInst/fo/clock_date_sw_pos", "number")
B747DR_fltInst_fo_clock_ET_sel_pos			= deferred_dataref("laminar/B747/fltInst/fo/clock_et_sel_pos", "number")				-- 0=HLD, 1=RUN, 2=RESET 
B747DR_fltInst_fo_clock_SET_sel_pos			= deferred_dataref("laminar/B747/fltInst/fo/clock_set_sel_pos", "number")		
B747DR_fltInst_fo_clock_UTC_display			= deferred_dataref("laminar/B747/fltInst/fo/clock_utc_display", "number")				-- 0=TIME, 1=DATE
B747DR_fltInst_fo_clock_DATE_display_mode	= deferred_dataref("laminar/B747/fltInst/fo/clock_date_display_mode", "number")		-- 0=DAY/MONTH, 1=YEAR	
B747DR_fltInst_fo_clock_ET_CHR_display		= deferred_dataref("laminar/B747/fltInst/fo/clock_et_chr_display", "number")			-- 0=ET, 1=CHR	
B747DR_fltInst_fo_clock_ET_minutes			= deferred_dataref("laminar/B747/fltInst/fo/clock_et_minutes", "number")
B747DR_fltInst_fo_clock_ET_hours			= deferred_dataref("laminar/B747/fltInst/fo/clock_et_hours", "number")
B747DR_fltInst_fo_clock_CHR_seconds			= deferred_dataref("laminar/B747/fltInst/fo/clock_chr_seconds", "number")
B747DR_fltInst_fo_clock_CHR_minutes			= deferred_dataref("laminar/B747/fltInst/fo/clock_chr_minutes", "number")
B747DR_fltInst_fo_clock_year				= deferred_dataref("laminar/B747/fltInst/fo/clock_year", "number")


B747CMD_fltInst_fo_clock_chrono_switch	= deferred_command("laminar/B747/fltInst/fo/clock_chrono_switch", "First Officer Clock Chronograph Switch", B747_fo_clock_chrono_switch_CMDhandler)
B747CMD_fltInst_fo_clock_date_switch	= deferred_command("laminar/B747/fltInst/fo/clock_date_switch", "First Officer Clock Date Switch", B747_fo_clock_date_switch_CMDhandler)
B747CMD_fltInst_fo_clock_ET_sel_up		= deferred_command("laminar/B747/fltInst/fo/clock_et_sel_up", "First Officer Clock ET Selector Up", B747_fo_clock_ET_sel_up_CMDhandler)
B747CMD_fltInst_fo_clock_ET_sel_dn		= deferred_command("laminar/B747/fltInst/fo/clock_et_sel_down", "First Officer Clock ET Selector Down", B747_fo_clock_ET_sel_dn_CMDhandler)
B747CMD_fltInst_fo_clock_SET_sel_up		= deferred_command("laminar/B747/fltInst/fo/clock_set_sel_up", "First Officer Clock SET Selector Up", B747_fo_clock_SET_sel_up_CMDhandler)
B747CMD_fltInst_fo_clock_SET_sel_dn		= deferred_command("laminar/B747/fltInst/fo/clock_set_sel_down", "First Officer Clock SET Selector Down", B747_fo_clock_SET_sel_dn_CMDhandler)

