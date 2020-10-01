--[[
*****************************************************************************************
* Program Script Name	:	B747.manipulators
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

NUM_BTN_SW_COVERS   = 20
NUM_BTN_SW          = 89
NUM_TOGGLE_SW       = 38
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
B747CMD_openAllDoors 				= deferred_command("laminar/B747/button_switch/open_all_doors", "Open All doors", B747_open_door_CMDhandler)
B747CMD_closeAllDoors 				= deferred_command("laminar/B747/button_switch/close_all_doors", "Open All doors", B747_close_door_CMDhandler)
B747DR_init_manip_CD                = deferred_dataref("laminar/B747/manip/init_CD", "number")
B747DR_button_switch_cover_position = deferred_dataref("laminar/B747/button_switch_cover/position", "array[" .. tostring(NUM_BTN_SW_COVERS) .. "]")
B747DR_button_switch_position       = deferred_dataref("laminar/B747/button_switch/position", "array[" .. tostring(NUM_BTN_SW) .. "]")
B747DR_toggle_switch_position       = deferred_dataref("laminar/B747/toggle_switch/position", "array[" .. tostring(NUM_TOGGLE_SW) .. "]")
B747DR_elec_ext_pwr_1_switch_mode   = deferred_dataref("laminar/B747/elec_ext_pwr_1/switch_mode", "number")
B747DR_elec_apu_pwr_1_switch_mode   = deferred_dataref("laminar/B747/apu_pwr_1/switch_mode", "number")
B747DR_gen_drive_disc_status        = deferred_dataref("laminar/B747/electrical/generator/drive_disc_status", "array[4]")
B747DR_accy_door_handle             = deferred_dataref("laminar/B747/misc/accy_door_handle", "number", B747_accy_door_handle_DRhandler)

----- COCKPIT SUN VISORS ----------------------------------------------------------------
B747DR_sun_visor_left_right_capt    = deferred_dataref("laminar/B747/misc/sun_visor/left_right/capt", "number", B747_sun_visor_left_right_capt_DRhandler)
B747DR_sun_visor_left_right_fo      = deferred_dataref("laminar/B747/misc/sun_visor/left_right/fo", "number", B747_sun_visor_left_right_fo_DRhandler)

----- OVERHEAD MAP LIGHTS ---------------------------------------------------------------
B747DR_ovhd_map_light_x_capt        = deferred_dataref("laminar/B747/misc/ovhd_map_light/x_axis/capt", "number", B747_ovhd_map_light_x_capt_DRhandler)
B747DR_ovhd_map_light_y_capt        = deferred_dataref("laminar/B747/misc/ovhd_map_light/y_axis/capt", "number", B747_ovhd_map_light_y_capt_DRhandler)

B747DR_ovhd_map_light_x_fo          = deferred_dataref("laminar/B747/misc/ovhd_map_light/x_axis/fo", "number", B747_ovhd_map_light_x_fo_DRhandler)
B747DR_ovhd_map_light_y_fo          = deferred_dataref("laminar/B747/misc/ovhd_map_light/y_axis/fo", "number", B747_ovhd_map_light_y_fo_DRhandler)

--*************************************************************************************--
--** 				                 CUSTOM COMMANDS                			     **--
--*************************************************************************************--

----- BUTTON SWITCH COVERS --------------------------------------------------------------
B747CMD_button_switch_cover = {}
for i = 0, NUM_BTN_SW_COVERS-1 do
    B747CMD_button_switch_cover[i] 		= deferred_command("laminar/B747/button_switch_cover" .. string.format("%02d", i), "Button Switch Cover" .. string.format("%02d", i),nil)--, B747_button_switch_cover_CMDhandler[i])
end



----- GLARESHIELD BUTTON SWITCHES -------------------------------------------------------

-- WARNING/CAUTION
B747DR_master_warning               = deferred_dataref("laminar/B747/warning/master_warning", "number")
B747DR_master_caution               = deferred_dataref("laminar/B747/warning/master_caution", "number")
B747CMD_warning_caution_captain 		= deferred_command("laminar/B747/button_switch/warn_caut_capt", "Warning/Caution Reset (Captain)", B747_warning_caution_captain_CMDhandler)
B747CMD_warning_caution_fo 			= deferred_command("laminar/B747/button_switch/warn_caut_fo", "Warning/Caution Reset (First Officer)", B747_warning_caution_fo_CMDhandler)

B747CMD_warning_caution_fo 			= deferred_command("laminar/B747/button_switch/altknob", "Warning/Caution Reset (First Officer)", B747_warning_caution_fo_CMDhandler)

----- MAIN PANEL BUTTON SWITCHES --------------------------------------------------------

-- ALTERNATE FLAP
B747CMD_altn_flap 				= deferred_command("laminar/B747/button_switch/altn_flap", "Alternate Flaps", B747_altn_flap_CMDhandler)

-- ALTERNATE GEAR
B747CMD_altn_nose_gear_extend 			= deferred_command("laminar/B747/button_switch/altn_nose_gear_extend", "Alternate Nose Gear Extend", B747_altn_nose_gear_extend_CMDhandler)
B747CMD_altn_wing_gear_extend 			= deferred_command("laminar/B747/button_switch/altn_wing_gear_extend", "Alternate Wing gear Extend", B747_altn_wing_gear_extend_CMDhandler)

-- GROUND PROXIMITY
B747CMD_gnd_prox_gs_inhibit 			= deferred_command("laminar/B747/button_switch/gnd_prox_gs_inhibit", "Ground Proximity Glideslope Inhibit", B747_gnd_prox_gs_inhibit_CMDhandler)
B747CMD_gnd_prox_flap_ovrd 			= deferred_command("laminar/B747/button_switch/gnd_prox_flap_ovrd", "Ground Proximity Flap Override", B747_gnd_prox_flap_ovrd_CMDhandler)
B747CMD_gnd_prox_gear_ovrd 			= deferred_command("laminar/B747/button_switch/gnd_prox_gear_ovrd", "Ground Proximity gear Override", B747_gnd_prox_gear_ovrd_CMDhandler)
B747CMD_gnd_prox_terr_ovrd 			= deferred_command("laminar/B747/button_switch/gnd_prox_terr_ovrd", "Ground Proximity Terrain Override", B747_gnd_prox_terr_ovrd_CMDhandler)



----- OVERHEAD PANEL BUTTON SWITCHES ----------------------------------------------------

-- ELECTRONIC ENGINE CONTROL
B747CMD_elec_eng_ctrl_1 			= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_1", "Electronic Engine Control 1", B747_elec_eng_ctrl_1_CMDhandler)
B747CMD_elec_eng_ctrl_2 			= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_2", "Electronic Engine Control 2", B747_elec_eng_ctrl_2_CMDhandler)
B747CMD_elec_eng_ctrl_3 			= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_3", "Electronic Engine Control 3", B747_elec_eng_ctrl_3_CMDhandler)
B747CMD_elec_eng_ctrl_4 			= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_4", "Electronic Engine Control 4", B747_elec_eng_ctrl_4_CMDhandler)

-- ELECTRIC
B747CMD_elec_util_L 				= deferred_command("laminar/B747/button_switch/elec_util_L", "Utility L", B747_elec_util_L_CMDhandler)
B747CMD_elec_util_R 				= deferred_command("laminar/B747/button_switch/elec_util_R",  "Utility R", B747_elec_util_R_CMDhandler)
B747CMD_elec_battery 				= deferred_command("laminar/B747/button_switch/elec_battery", "Battery", B747_elec_battery_CMDhandler)
B747CMD_elec_ext_pwr_1 				= deferred_command("laminar/B747/button_switch/elec_ext_pwr_1", "External Power 1", B747_elec_ext_pwr_1_CMDhandler)
B747CMD_elec_ext_pwr_2 				= deferred_command("laminar/B747/button_switch/elec_ext_pwr_2", "External Power 2", B747_elec_ext_pwr_2_CMDhandler)
B747CMD_elec_apu_gen_1 				= deferred_command("laminar/B747/button_switch/elec_apu_gen_1", "APU Generator 1", B747_elec_apu_gen_1_CMDhandler)
B747CMD_elec_apu_gen_2 				= deferred_command("laminar/B747/button_switch/elec_apu_gen_2", "APU Generator 2", B747_elec_apu_gen_2_CMDhandler)
B747CMD_elec_bus_tie_1 				= deferred_command("laminar/B747/button_switch/elec_bus_tie_1", "Bus Tie 1", B747_elec_bus_tie_1_CMDhandler)
B747CMD_elec_bus_tie_2 				= deferred_command("laminar/B747/button_switch/elec_bus_tie_2", "Bus Tie 2", B747_elec_bus_tie_2_CMDhandler)
B747CMD_elec_bus_tie_3 				= deferred_command("laminar/B747/button_switch/elec_bus_tie_3", "Bus Tie 3", B747_elec_bus_tie_3_CMDhandler)
B747CMD_elec_bus_tie_4 				= deferred_command("laminar/B747/button_switch/elec_bus_tie_4", "Bus Tie 4", B747_elec_bus_tie_4_CMDhandler)
B747CMD_elec_gen_ctrl_1 			= deferred_command("laminar/B747/button_switch/elec_gen_ctrl_1", "Generator Control 1", B747_elec_gen_ctrl_1_CMDhandler)
B747CMD_elec_gen_ctrl_2 			= deferred_command("laminar/B747/button_switch/elec_gen_ctrl_2", "Generator Control 2", B747_elec_gen_ctrl_2_CMDhandler)
B747CMD_elec_gen_ctrl_3 				= deferred_command("laminar/B747/button_switch/elec_gen_ctrl_3", "Generator Control 3", B747_elec_gen_ctrl_3_CMDhandler)
B747CMD_elec_gen_ctrl_4 				= deferred_command("laminar/B747/button_switch/elec_gen_ctrl_4", "Generator Control 4", B747_elec_gen_ctrl_4_CMDhandler)
B747CMD_elec_drive_disc_1 				= deferred_command("laminar/B747/button_switch/elec_drive_disc_1", "Drive Disc 1", B747_elec_drive_disc_1_CMDhandler)
B747CMD_elec_drive_disc_2 				= deferred_command("laminar/B747/button_switch/elec_drive_disc_2", "Drive Disc 2", B747_elec_drive_disc_2_CMDhandler)
B747CMD_elec_drive_disc_3 				= deferred_command("laminar/B747/button_switch/elec_drive_disc_3", "Drive Disc 3", B747_elec_drive_disc_3_CMDhandler)
B747CMD_elec_drive_disc_4 				= deferred_command("laminar/B747/button_switch/elec_drive_disc_4", "Drive Disc 4", B747_elec_drive_disc_4_CMDhandler)

-- HYDRAULIC
B747CMD_hyd_pump_1 						= deferred_command("laminar/B747/button_switch/hyd_pump_1", "Hydraulic Pump 1", B747_hyd_pump_1_CMDhandler)
B747CMD_hyd_pump_2 						= deferred_command("laminar/B747/button_switch/hyd_pump_2", "Hydraulic Pump 2", B747_hyd_pump_2_CMDhandler)
B747CMD_hyd_pump_3 						= deferred_command("laminar/B747/button_switch/hyd_pump_3", "Hydraulic Pump 3", B747_hyd_pump_3_CMDhandler)
B747CMD_hyd_pump_4 						= deferred_command("laminar/B747/button_switch/hyd_pump_4", "Hydraulic Pump 4", B747_hyd_pump_4_CMDhandler)

-- PRESSURIZATION
B747CMD_press_outflow_vlv_L 			= deferred_command("laminar/B747/button_switch/press_outflow_vlv_L", "Pressure Outflow Valve L", B747_press_outflow_vlv_L_CMDhandler)
B747CMD_press_outflow_vlv_R 			= deferred_command("laminar/B747/button_switch/press_outflow_vlv_R", "Pressure Outflow Valve R", B747_press_outflow_vlv_R_CMDhandler)

-- TEMPERATURE
B747CMD_temp_zone_rst 					= deferred_command("laminar/B747/button_switch/temp_zone_rst", "Temperature Zone Reset", B747_temp_zone_rst_CMDhandler)
B747CMD_temp_trim_air 					= deferred_command("laminar/B747/button_switch/temp_trim_air", "Temperture Trim Air", B747_temp_trim_air_CMDhandler)
B747CMD_temp_recirc_upr 				= deferred_command("laminar/B747/button_switch/temp_recirc_upr", "Temperature Recirculation Upper", B747_temp_recirc_upr_CMDhandler)
B747CMD_temp_recirc_lwr 				= deferred_command("laminar/B747/button_switch/temp_recirc_lwr", "Temperature Recirculation Lower", B747_temp_recirc_lwr_CMDhandler)
B747CMD_temp_aft_cargo_ht 				= deferred_command("laminar/B747/button_switch/temp_aft_cargo_ht", "Temperature Cargo Heat", B747_temp_aft_cargo_ht_CMDhandler)
B747CMD_temp_hi_flow 					= deferred_command("laminar/B747/button_switch/temp_hi_flow", "Temperature Hi Flow", B747_temp_hi_flow_CMDhandler)
B747CMD_temp_pack_rst 					= deferred_command("laminar/B747/button_switch/temp_pack_rst", "Temperature Pack Reset", B747_temp_pack_rst_CMDhandler)

-- MISC FUEL CONTROL
B747CMD_misc_fuel_xfr_1_4 				= deferred_command("laminar/B747/button_switch/misc_fuel_xfr_1_4", "Miscellaneous Fuel Tranfer 1 & 4", B747_misc_fuel_xfr_1_4_CMDhandler)

-- START
B747CMD_start_ign_cont 					= deferred_command("laminar/B747/button_switch/start_ign_cont", "Ignition Continous", B747_start_ign_cont_CMDhandler)
B747CMD_start_autostart 				= deferred_command("laminar/B747/button_switch/start_autostart", "Autostart", B747_start_autostart_CMDhandler)

-- FUEL JETTISON SYSTEM
B747CMD_fuel_jet_nozzle_vlv_L 			= deferred_command("laminar/B747/button_switch/fuel_jet_nozzle_vlv_L", "Fuel Jettison Nozzle Valve L", B747_fuel_jet_nozzle_vlv_L_CMDhandler)
B747CMD_fuel_jet_nozzle_vlv_R 			= deferred_command("laminar/B747/button_switch/fuel_jet_nozzle_vlv_R", "Fuel Jettison Nozzle Valve R", B747_fuel_jet_nozzle_vlv_R_CMDhandler)

-- FUEL SYSTEM
B747CMD_fuel_xfeed_vlv_1 				= deferred_command("laminar/B747/button_switch/fuel_xfeed_vlv_1", "Fuel Crossfeed Valve 1", B747_fuel_xfeed_vlv_1_CMDhandler)
B747CMD_fuel_xfeed_vlv_2 				= deferred_command("laminar/B747/button_switch/fuel_xfeed_vlv_2", "Fuel Crossfeed Valve 2", B747_fuel_xfeed_vlv_2_CMDhandler)
B747CMD_fuel_xfeed_vlv_3 				= deferred_command("laminar/B747/button_switch/fuel_xfeed_vlv_3", "Fuel Crossfeed Valve 3", B747_fuel_xfeed_vlv_3_CMDhandler)
B747CMD_fuel_xfeed_vlv_4 				= deferred_command("laminar/B747/button_switch/fuel_xfeed_vlv_4", "Fuel Crossfeed Valve 4", B747_fuel_xfeed_vlv_4_CMDhandler)
B747CMD_fuel_ctr_wing_tnk_pump_L 		= deferred_command("laminar/B747/button_switch/fuel_ctr_wing_tnk_pump_L", "Fuel Center Wing Tank Pump L", B747_fuel_ctr_wing_tnk_pump_L_CMDhandler)
B747CMD_fuel_ctr_wing_tnk_pump_R 		= deferred_command("laminar/B747/button_switch/fuel_ctr_wing_tnk_pump_R", "Fuel Center Wing Tank Pump R", B747_fuel_ctr_wing_tnk_pump_R_CMDhandler)
B747CMD_fuel_stab_tnk_pump_L 			= deferred_command("laminar/B747/button_switch/fuel_stab_tnk_pump_L", "Fuel Stabilizer Tank Pump L", B747_fuel_stab_tnk_pump_L_CMDhandler)
B747CMD_fuel_stab_tnk_pump_R 			= deferred_command("laminar/B747/button_switch/fuel_stab_tnk_pump_R", "Fuel Stabilizer Tank Pump R", B747_fuel_stab_tnk_pump_R_CMDhandler)
B747CMD_fuel_main_pump_fwd_1 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_fwd_1", "Fuel Main Pump Forward 1", B747_fuel_main_pump_fwd_1_CMDhandler)
B747CMD_fuel_main_pump_fwd_2 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_fwd_2", "Fuel Main Pump Forward 2", B747_fuel_main_pump_fwd_2_CMDhandler)
B747CMD_fuel_main_pump_fwd_3 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_fwd_3", "Fuel Main Pump Forward 3", B747_fuel_main_pump_fwd_3_CMDhandler)
B747CMD_fuel_main_pump_fwd_4 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_fwd_4", "Fuel Main Pump Forward 4", B747_fuel_main_pump_fwd_4_CMDhandler)
B747CMD_fuel_main_pump_aft_1 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_aft_1", "Fuel Main Pump Aft 1", B747_fuel_main_pump_aft_1_CMDhandler)
B747CMD_fuel_main_pump_aft_2 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_aft_2", "Fuel Main Pump Aft 2", B747_fuel_main_pump_aft_2_CMDhandler)
B747CMD_fuel_main_pump_aft_3 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_aft_3", "Fuel Main Pump Aft 3", B747_fuel_main_pump_aft_3_CMDhandler)
B747CMD_fuel_main_pump_aft_4 			= deferred_command("laminar/B747/button_switch/fuel_main_pump_aft_4", "Fuel Main Pump Aft 4", B747_fuel_main_pump_aft_4_CMDhandler)
B747CMD_fuel_overd_pump_fwd_2 			= deferred_command("laminar/B747/button_switch/fuel_overd_pump_fwd_2", "Fuel Override Pump Forward 2", B747_fuel_overd_pump_fwd_2_CMDhandler)
B747CMD_fuel_overd_pump_fwd_3 			= deferred_command("laminar/B747/button_switch/fuel_overd_pump_fwd_3", "Fuel Override Pump Forward 3", B747_fuel_overd_pump_fwd_3_CMDhandler)
B747CMD_fuel_overd_pump_aft_2 			= deferred_command("laminar/B747/button_switch/fuel_overd_pump_aft_2", "Fuel Override Pump Aft 2", B747_fuel_overd_pump_aft_2_CMDhandler)
B747CMD_fuel_overd_pump_aft_3 			= deferred_command("laminar/B747/button_switch/fuel_overd_pump_aft_3", "Fuel Override Pump Aft 3", B747_fuel_overd_pump_aft_3_CMDhandler)

-- ANTI-ICE
B747CMD_anti_ice_nacelle_1 				= deferred_command("laminar/B747/button_switch/anti_ice_nacelle_1", "Anti-Ice Nacelle 1", B747_anti_ice_nacelle_1_CMDhandler)
B747CMD_anti_ice_nacelle_2 				= deferred_command("laminar/B747/button_switch/anti_ice_nacelle_2", "Anti-Ice Nacelle 2", B747_anti_ice_nacelle_2_CMDhandler)
B747CMD_anti_ice_nacelle_3 				= deferred_command("laminar/B747/button_switch/anti_ice_nacelle_3", "Anti-Ice Nacelle 3", B747_anti_ice_nacelle_3_CMDhandler)
B747CMD_anti_ice_nacelle_4 				= deferred_command("laminar/B747/button_switch/anti_ice_nacelle_4", "Anti-Ice Nacelle 4", B747_anti_ice_nacelle_4_CMDhandler)
B747CMD_anti_ice_wing 					= deferred_command("laminar/B747/button_switch/anti_ice_wing", "Anti-Ice Wing", B747_anti_ice_wing_CMDhandler)
B747CMD_anti_ice_window_L 				= deferred_command("laminar/B747/button_switch/anti_ice_window_L", "Anti-Ice Winodw L", B747_anti_ice_window_L_CMDhandler)
B747CMD_anti_ice_window_R 				= deferred_command("laminar/B747/button_switch/anti_ice_window_R", "Anti-Ice Winodw L", B747_anti_ice_window_R_CMDhandler)

-- BLEED AIR
B747CMD_bleed_air_isln_vlv_L 			= deferred_command("laminar/B747/button_switch/bleed_air_isln_vlv_L", "Bleed Air Isolation Valve L", B747_bleed_air_isln_vlv_L_CMDhandler)
B747CMD_bleed_air_isln_vlv_R 			= deferred_command("laminar/B747/button_switch/bleed_air_isln_vlv_R", "Bleed Air Isolation Valve R", B747_bleed_air_isln_vlv_R_CMDhandler)
B747CMD_bleed_air_vlv_engine_1 			= deferred_command("laminar/B747/button_switch/bleed_air_vlv_engine_1", "Bleed Air Valve Engine 1", B747_bleed_air_vlv_engine_1_CMDhandler)
B747CMD_bleed_air_vlv_engine_2 			= deferred_command("laminar/B747/button_switch/bleed_air_vlv_engine_2", "Bleed Air Valve Engine 2", B747_bleed_air_vlv_engine_2_CMDhandler)
B747CMD_bleed_air_vlv_engine_3 			= deferred_command("laminar/B747/button_switch/bleed_air_vlv_engine_3", "Bleed Air Valve Engine 3", B747_bleed_air_vlv_engine_3_CMDhandler)
B747CMD_bleed_air_vlv_engine_4 			= deferred_command("laminar/B747/button_switch/bleed_air_vlv_engine_4", "Bleed Air Valve Engine 4", B747_bleed_air_vlv_engine_4_CMDhandler)
B747CMD_bleed_air_vlv_apu 				= deferred_command("laminar/B747/button_switch/bleed_air_vlv_apu", "Bleed Air Valve APU", B747_bleed_air_vlv_apu_CMDhandler)

-- YAW DAMPER
B747CMD_yaw_damper_upr 					= deferred_command("laminar/B747/button_switch/yaw_damper_upr", "Yaw Damper Upper", B747_yaw_damper_upr_CMDhandler)
B747CMD_yaw_damper_lwr 					= deferred_command("laminar/B747/button_switch/yaw_damper_lwr", "Yaw Damper Lower", B747_yaw_damper_lwr_CMDhandler)

-- CARGO FIRE
B747CMD_cargo_fire_arm_fwd 				= deferred_command("laminar/B747/button_switch/cargo_fire_arm_fwd", "Cargo Fire Arm Forward", B747_cargo_fire_arm_fwd_CMDhandler)
B747CMD_cargo_fire_arm_aft 				= deferred_command("laminar/B747/button_switch/cargo_fire_arm_aft", "Cargo Fire Arm Aft", B747_cargo_fire_arm_aft_CMDhandler)
B747CMD_cargo_fire_disch 				= deferred_command("laminar/B747/button_switch/cargo_fire_disch", "Cargo Fire Discharge", B747_cargo_fire_disch_CMDhandler)







----- OVERHEAD TOGGLE SWITCHES ----------------------------------------------------------

-- OBSERVER AUDIO SWITCH
B747CMD_obsrv_audio_switch_left 		= deferred_command("laminar/B747/toggle_switch/observer_audio_left", "Observer Audio Switch Left", B747_obsrv_audio_switch_left_CMDhandler)
B747CMD_obsrv_audio_switch_right 		= deferred_command("laminar/B747/toggle_switch/observer_audio_right", "Observer Audio Switch Right", B747_obsrv_audio_switch_right_CMDhandler)

-- SERVICE INTERPHONE SWITCH
B747CMD_srvc_interphone_switch 			= deferred_command("laminar/B747/toggle_switch/srvc_interphone", "Service Interphone Switch", B747_srvc_interphone_switch_CMDhandler)

-- ENGINE START SWITCH
B747CMD_engine_start_switch1 			= deferred_command("laminar/B747/toggle_switch/engine_start1", "Engine Start Switch 1", B747_engine_start_switch1_CMDhandler)
B747CMD_engine_start_switch2 			= deferred_command("laminar/B747/toggle_switch/engine_start2", "Engine Start Switch 2", B747_engine_start_switch2_CMDhandler)
B747CMD_engine_start_switch3 			= deferred_command("laminar/B747/toggle_switch/engine_start3", "Engine Start Switch 3", B747_engine_start_switch3_CMDhandler)
B747CMD_engine_start_switch4 			= deferred_command("laminar/B747/toggle_switch/engine_start4", "Engine Start Switch 4", B747_engine_start_switch4_CMDhandler)
		
B747CMD_engine_start_switch1_off 		= deferred_command("laminar/B747/toggle_switch/engine_start1_off", "Engine Start Switch 1 Off", B747_engine_start_switch1_off_CMDhandler)
B747CMD_engine_start_switch2_off 		= deferred_command("laminar/B747/toggle_switch/engine_start2_off", "Engine Start Switch 2 Off", B747_engine_start_switch2_off_CMDhandler)
B747CMD_engine_start_switch3_off 		= deferred_command("laminar/B747/toggle_switch/engine_start3_off", "Engine Start Switch 3 Off", B747_engine_start_switch3_off_CMDhandler)
B747CMD_engine_start_switch4_off 		= deferred_command("laminar/B747/toggle_switch/engine_start4_off", "Engine Start Switch 4 Off", B747_engine_start_switch4_off_CMDhandler)

-- WINDHSIELD WASHER SWITCH
B747CMD_windshield_washer_switch_L 		= deferred_command("laminar/B747/toggle_switch/windshield_washer_L", "Windshield Washer Switch Left", B747_windshield_washer_switch_L_CMDhandler)
B747CMD_windshield_washer_switch_R 		= deferred_command("laminar/B747/toggle_switch/windshield_washer_R", "Windshield Washer Switch Right", B747_windshield_washer_switch_R_CMDhandler)

-- OUTFLOW VALVE OPEN/CLOSE SWITCH
B747CMD_outflow_valve_switch_open 		= deferred_command("laminar/B747/toggle_switch/outflow_valve_open", "Outlfow Valve Switch Open", B747_outflow_valve_switch_open_CMDhandler)
B747CMD_outflow_valve_switch_close 		= deferred_command("laminar/B747/toggle_switch/outflow_valve_close", "Outlfow Valve Switch Close", B747_outflow_valve_switch_close_CMDhandler)

-- STORM LIGHT SWITCH
B747CMD_storm_light_switch 				= deferred_command("laminar/B747/toggle_switch/storm_light", "Storm Light Switch", B747_storm_light_switch_CMDhandler)

-- LANDING LIGHT SWITCH
B747CMD_landing_light_switch_OBL 		= deferred_command("laminar/B747/toggle_switch/landing_light_OBL", "Landing Light Switch Outboard Left", B747_landing_light_switch_OBL_CMDhandler)
B747CMD_landing_light_switch_OBR 		= deferred_command("laminar/B747/toggle_switch/landing_light_OBR", "Landing Light Switch Outboard Right", B747_landing_light_switch_OBR_CMDhandler)
B747CMD_landing_light_switch_IBL 		= deferred_command("laminar/B747/toggle_switch/landing_light_IBL", "Landing Light Switch Inboard Left", B747_landing_light_switch_IBL_CMDhandler)
B747CMD_landing_light_switch_IBR 		= deferred_command("laminar/B747/toggle_switch/landing_light_IBR", "Landing Light Switch Inboard Right", B747_landing_light_switch_IBR_CMDhandler)

-- RUNWAY TURNOFF LIGHTS
B747CMD_runway_turnoff_light_switch_L 	= deferred_command("laminar/B747/toggle_switch/rwy_tunoff_L", "Left Runway Turnoff Light Switch", B747_runway_turnoff_light_switch_L_CMDhandler)
B747CMD_runway_turnoff_light_switch_R 	= deferred_command("laminar/B747/toggle_switch/rwy_tunoff_R", "Right Runway Turnoff Light Switch", B747_runway_turnoff_light_switch_R_CMDhandler)

-- TAXI LIGHT SWITCH
B747CMD_taxi_light_switch 				= deferred_command("laminar/B747/toggle_switch/taxi_light", "Taxi Light Switch", B747_taxi_light_switch_CMDhandler)

-- BEACON LIGHT SWITCH
B747CMD_beacon_light_switch_up 			= deferred_command("laminar/B747/toggle_switch/beacon_light_up", "Beacon Light Switch Up", B747_beacon_light_switch_up_CMDhandler)
B747CMD_beacon_light_switch_down 		= deferred_command("laminar/B747/toggle_switch/beacon_light_down", "Beacon Light Switch Down", B747_beacon_light_switch_down_CMDhandler)

-- NAV LIGHT SWITCH
B747CMD_nav_light_switch 				= deferred_command("laminar/B747/toggle_switch/nav_light", "Nav Light Switch", B747_nav_light_switch_CMDhandler)

-- STROBE LIGHT SWITCH
B747CMD_strobe_light_switch 			= deferred_command("laminar/B747/toggle_switch/strobe_light", "Strobe Light Switch", B747_strobe_light_switch_CMDhandler)

-- WING LIGHT SWITCH
B747CMD_wing_light_switch 				= deferred_command("laminar/B747/toggle_switch/wing_light", "Wing Light Switch", B747_wing_light_switch_CMDhandler)

-- LOGO LIGHT SWITCH
B747CMD_logo_light_switch 				= deferred_command("laminar/B747/toggle_switch/logo_light", "Logo Light Switch", B747_logo_light_switch_CMDhandler)

-- IND LIGHT SIWTCH
B747CMD_ind_light_switch_up 			= deferred_command("laminar/B747/toggle_switch/ind_light_up", "Ind Light Switch Up", B747_ind_light_switch_up_CMDhandler)
B747CMD_ind_light_switch_down 			= deferred_command("laminar/B747/toggle_switch/ind_light_down", "Ind Light Switch Down", B747_ind_light_switch_down_CMDhandler)

-- CABIN LIGHTS
B747CMD_cabin_lights_switch 			= deferred_command("laminar/B747/toggle_switch/cabin_lights", "Cabin Lights Switch", B747_cabin_lights_switch_CMDhandler) -- NOTE: NO PHYSICAL SWITCH






----- GLARESHIELD PANEL TOGGLE SWITCHES -------------------------------------------------

-- VOR/ADF SWITCH
B747CMD_vor_adf_pilot_switch_L_up 		= deferred_command("laminar/B747/toggle_switch/vor_adf_pilot_L_up", "VOR/ADF Switch Pilot Left Up", B747_vor_adf_pilot_switch_L_up_CMDhandler)
B747CMD_vor_adf_pilot_switch_L_down 	= deferred_command("laminar/B747/toggle_switch/vor_adf_pilot_L_down", "VOR/ADF Switch Pilot Left Down", B747_vor_adf_pilot_switch_L_down_CMDhandler)

B747CMD_vor_adf_pilot_switch_R_up 		= deferred_command("laminar/B747/toggle_switch/vor_adf_pilot_R_up", "VOR/ADF Switch Pilot Right Up", B747_vor_adf_pilot_switch_R_up_CMDhandler)
B747CMD_vor_adf_pilot_switch_R_down 	= deferred_command("laminar/B747/toggle_switch/vor_adf_pilot_R_down", "VOR/ADF Switch Pilot Right Down", B747_vor_adf_pilot_switch_R_down_CMDhandler)


B747CMD_vor_adf_fo_switch_L_up 			= deferred_command("laminar/B747/toggle_switch/vor_adf_fo_L_up", "VOR/ADF Switch First Officer Left Up", B747_vor_adf_fo_switch_L_up_CMDhandler)
B747CMD_vor_adf_fo_switch_L_down 		= deferred_command("laminar/B747/toggle_switch/vor_adf_fo_L_down", "VOR/ADF Switch First Officer Left Down", B747_vor_adf_fo_switch_L_down_CMDhandler)


B747CMD_vor_adf_fo_switch_R_up 			= deferred_command("laminar/B747/toggle_switch/vor_adf_fo_R_up", "VOR/ADF Switch First Officer Right Up", B747_vor_adf_fo_switch_R_up_CMDhandler)
B747CMD_vor_adf_fo_switch_R_down 		= deferred_command("laminar/B747/toggle_switch/vor_adf_fo_R_down", "VOR/ADF Switch First Officer Right Down", B747_vor_adf_fo_switch_R_down_CMDhandler)





-- FLIGHT DIRECTOR SWITCH
B747CMD_flight_dir_switch_L 			= deferred_command("laminar/B747/toggle_switch/flight_dir_L", "Flight Director Switch Left", B747_flight_dir_switch_L_CMDhandler)
B747CMD_flight_dir_switch_R 			= deferred_command("laminar/B747/toggle_switch/flight_dir_R", "Flight Director Switch Right", B747_flight_dir_switch_R_CMDhandler)


-- AUTO-THROTTLE SWITCH
B747CMD_autothrottle_arm_switch 		= deferred_command("laminar/B747/toggle_switch/autothrottle", "Logo Light Switch", B747_autothrottle_arm_switch_CMDhandler)
B747CMD_autothrottle_arm            	= deferred_command("laminar/B747/authrottle_arm", "Autothrottle Arm", B747_autothrottle_arm_CMDhandler)
B747CMD_autothrottle_disarm         	= deferred_command("laminar/B747/authrottle_disarm", "Autothrottle Disarm", B747_autothrottle_disarm_CMDhandler)





----- MAIN PANEL TOGGLE SWITCHES --------------------------------------------------------

-- HEADING REFERENCE SWITCH
B747CMD_heading_ref_switch 				= deferred_command("laminar/B747/toggle_switch/heading_ref", "heading Reference Switch", B747_heading_ref_switch_CMDhandler)





----- OVERHEAD SUN VISOR ----------------------------------------------------------------
B747CMD_sun_visor_up_down_capt  		= deferred_command("laminar/B747/toggle_sun_visor/up_down/capt", "number", B747_sun_visor_up_down_capt_CMDhandler)
B747CMD_sun_visor_up_down_fo    		= deferred_command("laminar/B747/toggle_sun_visor/up_down/fo", "number", B747_sun_visor_up_down_fo_CMDhandler)




----- WINDOW SUN SHADES -----------------------------------------------------------------
B747CMD_window_shade_up_down_front_capt = deferred_command("laminar/B747/window_shade/up_down_front/front_capt", "number", B747_window_shade_up_down_front_capt_CMDhandler)
B747CMD_window_shade_up_down_rear_capt  = deferred_command("laminar/B747/window_shade/up_down_rear/capt", "number", B747_window_shade_up_down_rear_capt_CMDhandler)

B747CMD_window_shade_up_down_front_fo  	= deferred_command("laminar/B747/window_shade/up_down_front/front_fo", "number", B747_window_shade_up_down_front_fo_CMDhandler)
B747CMD_window_shade_up_down_rear_fo  	= deferred_command("laminar/B747/window_shade/up_down_rear/fo", "number", B747_window_shade_up_down_rear_fo_CMDhandler)




----- AI --------------------------------------------------------------------------------
B747CMD_ai_manip_quick_start			= deferred_command("laminar/B747/ai/manip_quick_start", "number", B747_ai_manip_quick_start_CMDhandler)



function flight_start()
    print("Lua Flight Start")

end

--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--




--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--




--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- ANIMATION UTILITY -----------------------------------------------------------------
