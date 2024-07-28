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


function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end

function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local B747_button_switch_cover_position_target = {}
for i = 0, NUM_BTN_SW_COVERS-1 do
    B747_button_switch_cover_position_target[i] = 0

end

local B747_button_switch_position_target = {}
for i = 0, NUM_BTN_SW-1 do
    B747_button_switch_position_target[i] = 0
end

local B747_toggle_switch_position_target = {}
local B747DR_sun_visor_left_right_capt_target = 0.0
local B747DR_sun_visor_left_right_fo_target = 0.0
for i = 0, NUM_TOGGLE_SW-1 do
    B747_toggle_switch_position_target[i] = 0
end

local B747_close_button_cover = {}
local B747_button_switch_cover_CMDhandler = {}






--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--
simDR_engine_throttle_rev       = find_dataref("sim/cockpit2/engine/actuators/throttle_jet_rev_ratio")
simDR_engn_thro			= find_dataref("sim/flightmodel/engine/ENGN_thro")
simDR_prop_mode                 = find_dataref("sim/cockpit2/engine/actuators/prop_mode")
B747DR_throttle						= deferred_dataref("laminar/B747/engine/throttle", "array[4]")
B747DR_throttle_reversor			= deferred_dataref("laminar/B747/engine/throttle_reversor", "array[4]")
simDR_startup_running               	= find_dataref("sim/operation/prefs/startup_running")
simDR_all_wheels_on_ground          	= find_dataref("sim/flightmodel/failures/onground_any")
simDR_autopilot_servos_on           	= find_dataref("laminar/B747/autopilot/servos_on")
simDR_AHARS_roll_deg_pilot          	= find_dataref("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot")
simDR_autopilot_TOGA_vert_status    	= find_dataref("sim/cockpit2/autopilot/TOGA_status")
simDR_autopilot_TOGA_lat_status     	= find_dataref("sim/cockpit2/autopilot/TOGA_lateral_status")
B747DR_autopilot_TOGA_status     	= deferred_dataref("laminar/B747/autopilot/TOGA_status","number")
B747DR_autothrottle_active	= find_dataref("laminar/B747/engines/autothrottle_active")

B747DR_autothrottle_fail            	= find_dataref("laminar/B747/engines/autothrottle_fail")
--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--
B747DR_acfType               		= find_dataref("laminar/B747/acfType")
simDR_livery  				=find_dataref("sim/aircraft/view/acf_livery_path")
simDR_acf_m_jettison  				=find_dataref("sim/aircraft/weight/acf_m_jettison")
--B747DR_autothrottle_armed           = find_dataref("laminar/B747/autothrottle/armed")

B747DR_autopilot_cmd_L_mode         = find_dataref("laminar/B747/autopilot/cmd_L_mode/status")
B747DR_autopilot_cmd_C_mode         = find_dataref("laminar/B747/autopilot/cmd_C_mode/status")
B747DR_autopilot_cmd_R_mode         = find_dataref("laminar/B747/autopilot/cmd_R_mode/status")

B747DR_master_warning               = find_dataref("laminar/B747/warning/master_warning")
B747DR_master_caution               = find_dataref("laminar/B747/warning/master_caution")
B747DR_master_caution_audio     = find_dataref("laminar/B747/warning/master_caution_audio")
--B747DR_ap_armed_roll_mode           = find_dataref("laminar/B747/autopilot/armed_roll_mode")
--B747DR_ap_armed_pitch_mode          = find_dataref("laminar/B747/autopilot/armed_pitch_mode")

B747DR_ap_ias_mach_window_open      = find_dataref("laminar/B747/autopilot/ias_mach/window_open")
B747DR_ap_autothrottle_armed        	= deferred_dataref("laminar/B747/autothrottle/armed", "number")


--*************************************************************************************--
--** 				            READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_init_manip_CD                = deferred_dataref("laminar/B747/manip/init_CD", "number")
simDR_percent_lights_on             = find_dataref("sim/graphics/scenery/percent_lights_on")
B747DR_button_switch_cover_position = deferred_dataref("laminar/B747/button_switch_cover/position", "array[" .. tostring(NUM_BTN_SW_COVERS) .. "]")
B747DR_button_switch_position       = deferred_dataref("laminar/B747/button_switch/position", "array[" .. tostring(NUM_BTN_SW) .. "]")
B747DR_toggle_switch_position       = deferred_dataref("laminar/B747/toggle_switch/position", "array[" .. tostring(NUM_TOGGLE_SW) .. "]")
B747DR_elec_ext_pwr1_available      = find_dataref("laminar/B747/electrical/ext_pwr1_avail")
B747DR_elec_ext_pwr2_available      = find_dataref("laminar/B747/electrical/ext_pwr2_avail")
B747DR_elec_apu_pwr1_available      = find_dataref("laminar/B747/electrical/apu_pwr1_avail")
B747DR_elec_apu_pwr2_available      = find_dataref("laminar/B747/electrical/apu_pwr2_avail")
B747DR_elec_ext_pwr_1_switch_mode   = deferred_dataref("laminar/B747/elec_ext_pwr_1/switch_mode", "number")
B747DR_elec_apu_pwr_1_switch_mode   = deferred_dataref("laminar/B747/apu_pwr_1/switch_mode", "number")
B747DR_elec_ext_pwr_2_switch_mode   = deferred_dataref("laminar/B747/elec_ext_pwr_2/switch_mode", "number")
B747DR_elec_apu_pwr_2_switch_mode   = deferred_dataref("laminar/B747/apu_pwr_2/switch_mode", "number")
B747DR_gen_drive_disc_status        = deferred_dataref("laminar/B747/electrical/generator/drive_disc_status", "array[4]")

B747DR_ap_FMA_autothrottle_mode     = deferred_dataref("laminar/B747/autopilot/FMA/autothrottle_mode", "number")
B747DR_ap_ATT     	                = deferred_dataref("laminar/B747/autopilot/att_rate", "number")

simDR_radio_alt_DH_capt             = find_dataref("sim/cockpit2/gauges/actuators/radio_altimeter_bug_ft_pilot")
simDR_radio_alt_DH_fo               = find_dataref("sim/cockpit2/gauges/actuators/radio_altimeter_bug_ft_copilot")
B747DR_efis_baro_alt_ref_capt       = deferred_dataref("laminar/B747/efis/baro_ref/capt", "number")
B747DR_efis_baro_alt_ref_fo                     = deferred_dataref("laminar/B747/efis/baro_ref/fo", "number")
--*************************************************************************************--
--** 				        READ-WRITE CUSTOM DATAREF HANDLERS     		    	     **--
--*************************************************************************************--

----- COCKPIT ACCESSORY DOOR HANDLE -----------------------------------------------------
function B747_accy_door_handle_DRhandler() end


----- COCKPIT SUN VISORS ----------------------------------------------------------------
function B747_sun_visor_left_right_capt_DRhandler() end
function B747_sun_visor_left_right_fo_DRhandler() end

function B747_ovhd_map_light_x_capt_DRhandler() end
function B747_ovhd_map_light_y_capt_DRhandler() end

function B747_ovhd_map_light_x_fo_DRhandler() end
function B747_ovhd_map_light_y_fo_DRhandler() end



--*************************************************************************************--
--** 				            READ-WRITE CUSTOM DATAREFS                           **--
--*************************************************************************************--

----- COCKPIT ACCESSORY DOOR HANDLE -----------------------------------------------------
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
--** 				              FIND CUSTOM COMMANDS                   	    	 **--
--*************************************************************************************--

B747CMD_ap_reset 					= find_command("laminar/B747/autopilot/mode_reset")
--B747CMD_ap_att_mode					= find_command("laminar/B747/autopilot/att_mode")



--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--

-- BATTERY
function sim_battery1_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[13] < 0.01  then
            B747CMD_elec_battery:once()
        end
    end
end

function sim_battery1_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[13] > 0.99 then
            B747CMD_elec_battery:once()
        end
    end
end

function sim_battery_toggle_CMDhandler(phase, duration)
    if phase == 0 then
        B747CMD_elec_battery:once()
    end
end




-- EXTERNAL POWER
function sim_ext_pwr_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_elec_ext_pwr_1_switch_mode == 0 then
            B747DR_elec_ext_pwr_1_switch_mode = 1
        end
    end
end
function sim_ext_pwr_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_elec_ext_pwr_1_switch_mode == 1 then
            B747DR_elec_ext_pwr_1_switch_mode = 0
        end
    end
end
function sim_ext_pwr_toggle_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_ext_pwr_1_switch_mode = 1 - B747DR_elec_ext_pwr_1_switch_mode
    end
end




-- GENERATORS
function sim_generator_1_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[22] < 0.01 then
            simCMD_generator_1_on:once()
        end
    end
end
function sim_generator_2_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[23] < 0.01 then
            simCMD_generator_2_on:once()
        end
    end
end
function sim_generator_3_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[24] < 0.01 then
            simCMD_generator_3_on:once()
        end
    end
end
function sim_generator_4_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[25] < 0.01 then
            simCMD_generator_4_on:once()
        end
    end
end
function sim_generator_1_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[22] > 0.99 then
            simCMD_generator_1_off:once()
        end
    end
end
function sim_generator_2_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[23] > 0.99 then
            simCMD_generator_2_off:once()
        end
    end
end
function sim_generator_3_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[24] > 0.99 then
            simCMD_generator_3_off:once()
        end
    end
end
function sim_generator_4_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[25] > 0.99 then
            simCMD_generator_4_off:once()
        end
    end
end
function sim_generators_toggle_CMDhandler(phase, duration)
    if phase == 0 then
        simCMD_generators_toggle:once()
    end
end





-- CROSS TIE
function sim_cross_tie_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[18] < 0.01 then
            B747CMD_elec_bus_tie_1:once()
        end
        if B747_button_switch_position_target[19] < 0.01 then
            B747CMD_elec_bus_tie_2:once()
        end
        if B747_button_switch_position_target[20] < 0.01 then
            B747CMD_elec_bus_tie_3:once()
        end
        if B747_button_switch_position_target[21] < 0.01 then
            B747CMD_elec_bus_tie_4:once()
        end
    end
end

function sim_cross_tie_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[18] > 0.99 then
            B747CMD_elec_bus_tie_1:once()
        end
        if B747_button_switch_position_target[19] > 0.99 then
            B747CMD_elec_bus_tie_2:once()
        end
        if B747_button_switch_position_target[20] > 0.99 then
            B747CMD_elec_bus_tie_3:once()
        end
        if B747_button_switch_position_target[21] > 0.99 then
            B747CMD_elec_bus_tie_4:once()
        end
    end
end

function sim_cross_tie_toggle_CMDhandler(phase, duration)
    if phase == 0 then
        B747CMD_elec_bus_tie_1:once()
        B747CMD_elec_bus_tie_2:once()
        B747CMD_elec_bus_tie_3:once()
        B747CMD_elec_bus_tie_4:once()
    end
end






function B747_hyd_eng_pumps_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[30] < 0.01 then
            B747CMD_hyd_pump_1:once()
        end
        if B747_button_switch_position_target[31] < 0.01 then
            B747CMD_hyd_pump_2:once()
        end
        if B747_button_switch_position_target[32] < 0.01 then
            B747CMD_hyd_pump_3:once()
        end
        if B747_button_switch_position_target[33] < 0.01 then
            B747CMD_hyd_pump_4:once()
        end
    end
end

function B747_hyd_eng_pumps_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_button_switch_position_target[30] > 0.99 then
            B747CMD_hyd_pump_1:once()
        end
        if B747_button_switch_position_target[31] > 0.99 then
            B747CMD_hyd_pump_2:once()
        end
        if B747_button_switch_position_target[32] > 0.99 then
            B747CMD_hyd_pump_3:once()
        end
        if B747_button_switch_position_target[33] > 0.99 then
            B747CMD_hyd_pump_4:once()
        end
    end
end

function B747_hyd_eng_pumps_toggle_CMDhandler(phase, duration)
    if phase == 0 then
        B747CMD_hyd_pump_1:once()
        B747CMD_hyd_pump_2:once()
        B747CMD_hyd_pump_3:once()
        B747CMD_hyd_pump_4:once()
    end
end



function B747_ap_TOGA_mode_beforeCMDhandler(phase, duration) end
function B747_ap_TOGA_mode_afterCMDhandler(phase, duration)
	if phase == 0 then
		B747DR_ap_ias_mach_window_open = 1	
        B747DR_autothrottle_active = 1	
	end		
end



--*************************************************************************************--
--** 				                 FIND X-PLANE COMMANDS                   	     **--
--*************************************************************************************--

simCMD_autopilot_vert_speed_mode    = find_command("sim/autopilot/vertical_speed")
simCMD_autopilot_heading_mode       = find_command("sim/autopilot/heading_hold")



--*************************************************************************************--
--** 				               REPLACE X-PLANE COMMANDS                   	     **--
--*************************************************************************************--

simCMD_battery1_on                  = replace_command("sim/electrical/battery_1_on", sim_battery1_on_CMDhandler)
simCMD_battery1_off                 = replace_command("sim/electrical/battery_1_off", sim_battery1_off_CMDhandler)
simCMD_battery_toggle               = replace_command("sim/electrical/batteries_toggle", sim_battery_toggle_CMDhandler)

simCMD_ext_pwr_on                   = replace_command("sim/electrical/GPU_on", sim_ext_pwr_on_CMDhandler)
simCMD_ext_pwr_off                  = replace_command("sim/electrical/GPU_off", sim_ext_pwr_off_CMDhandler)
simCMD_ext_pwr_toggle               = replace_command("sim/electrical/GPU_toggle", sim_ext_pwr_toggle_CMDhandler)

simCMD_generator_1_on               = replace_command("sim/electrical/generator_1_on", sim_generator_1_on_CMDhandler)
simCMD_generator_2_on               = replace_command("sim/electrical/generator_2_on", sim_generator_2_on_CMDhandler)
simCMD_generator_3_on               = replace_command("sim/electrical/generator_3_on", sim_generator_3_on_CMDhandler)
simCMD_generator_4_on               = replace_command("sim/electrical/generator_4_on", sim_generator_4_on_CMDhandler)
simCMD_generator_1_off              = replace_command("sim/electrical/generator_1_off", sim_generator_1_off_CMDhandler)
simCMD_generator_2_off              = replace_command("sim/electrical/generator_2_off", sim_generator_2_off_CMDhandler)
simCMD_generator_3_off              = replace_command("sim/electrical/generator_3_off", sim_generator_3_off_CMDhandler)
simCMD_generator_4_off              = replace_command("sim/electrical/generator_4_off", sim_generator_4_off_CMDhandler)
simCMD_generators_toggle            = replace_command("sim/electrical/generators_toggle", sim_generators_toggle_CMDhandler)

simCMD_cross_tie_on                 = replace_command("sim/electrical/cross_tie_on", sim_cross_tie_on_CMDhandler)
simCMD_cross_tie_off                = replace_command("sim/electrical/cross_tie_off", sim_cross_tie_off_CMDhandler)
simCMD_cross_tie_toggle             = replace_command("sim/electrical/cross_tie_toggle", sim_cross_tie_toggle_CMDhandler)

simCMD_hyd_eng_pumps_on             = replace_command("sim/flight_controls/hydraulic_on", B747_hyd_eng_pumps_on_CMDhandler)
simCMD_hyd_eng_pumps_off            = replace_command("sim/flight_controls/hydraulic_off", B747_hyd_eng_pumps_off_CMDhandler)
simCMD_hyd_eng_pumps_toggle         = replace_command("sim/flight_controls/hydraulic_tog", B747_hyd_eng_pumps_toggle_CMDhandler)

--simCMD_autopilot_autothrottle_off   = find_command("sim/autopilot/autothrottle_off")


--simCMD_autopilot_pitch_sync         = find_command("sim/autopilot/pitch_sync")
--simCMD_autopilot_wing_leveler       = find_command("sim/autopilot/wing_leveler")
--simCMD_autopilot_alt_hold_mode      = find_command("sim/autopilot/altitude_hold")



--*************************************************************************************--
--** 				               WRAP X-PLANE COMMANDS                   	     	 **--
--*************************************************************************************--

simCMD_autopilot_TOGA_mode          = wrap_command("sim/autopilot/take_off_go_around", B747_ap_TOGA_mode_afterCMDhandler, B747_ap_TOGA_mode_afterCMDhandler)



--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--




--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

----- BUTTON SWITCH COVER FUNCTIONS -----------------------------------------------------
for i = 0, NUM_BTN_SW_COVERS-1 do

    -- CREATE THE CLOSE COVER FUNCTIONS
    B747_close_button_cover[i] = function()
        if i==9 and B747DR_button_switch_position[13] == 0 then
            B747_button_switch_cover_position_target[i] = 0.4
        else
            B747_button_switch_cover_position_target[i] = 0.0
        end
    end


    -- CREATE THE COVER HANDLER FUNCTIONS
    B747_button_switch_cover_CMDhandler[i] = function(phase, duration)
	--print("cover com hander "..i)
    closeTarget=0.0
    if i==9 and B747DR_button_switch_position[13] == 0 then closeTarget=0.4 end
        if phase == 0 then
            if B747_button_switch_cover_position_target[i] <0.6 then
                B747_button_switch_cover_position_target[i] = 1.0
                if is_timer_scheduled(B747_close_button_cover[i]) then
                    stop_timer(B747_close_button_cover[i])
                end
                run_after_time(B747_close_button_cover[i], 5.0)
            elseif B747_button_switch_cover_position_target[i] == 1.0 then
                B747_button_switch_cover_position_target[i] = closeTarget
                if is_timer_scheduled(B747_close_button_cover[i]) then
                    stop_timer(B747_close_button_cover[i])
                end
            end
        end
    end

end
for i = 0, NUM_BTN_SW_COVERS-1 do
    run_after_time(B747_close_button_cover[i], 1.0)
    
end



----- BUTTON SWITCH FUNCTIONS -----------------------------------------------------------
function B747_altn_flap_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[0] = 1.0 - B747_button_switch_position_target[0] end
end

function B747_altn_nose_gear_extend_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[1] = 1.0 - B747_button_switch_position_target[1] end
end

function B747_altn_wing_gear_extend_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[2] = 1.0 - B747_button_switch_position_target[2] end
end

function B747_gnd_prox_gs_inhibit_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[3] = 1.0 - B747_button_switch_position_target[3] end
end

function B747_gnd_prox_flap_ovrd_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[4] = 1.0 - B747_button_switch_position_target[4] end
end

function B747_gnd_prox_gear_ovrd_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[5] = 1.0 - B747_button_switch_position_target[5] end
end

function B747_gnd_prox_terr_ovrd_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[6] = 1.0 - B747_button_switch_position_target[6] end
end

function B747_elec_eng_ctrl_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[7] = 1.0 - B747_button_switch_position_target[7] end
end

function B747_elec_eng_ctrl_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[8] = 1.0 - B747_button_switch_position_target[8] end
end

function B747_elec_eng_ctrl_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[9] = 1.0 - B747_button_switch_position_target[9] end
end

function B747_elec_eng_ctrl_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[10] = 1.0 - B747_button_switch_position_target[10] end
end

function B747_elec_util_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[11] = 1.0 - B747_button_switch_position_target[11] end
end

function B747_elec_util_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[12] = 1.0 - B747_button_switch_position_target[12] end
end

function B747_elec_battery_CMDhandler(phase, duration)
    if phase == 0 then 
        B747_button_switch_position_target[13] = 1.0 - B747_button_switch_position_target[13] 
        simDR_radio_alt_DH_capt=-1
        simDR_radio_alt_DH_fo=-1
        B747DR_efis_baro_alt_ref_capt=-101
        B747DR_efis_baro_alt_ref_fo=-101
        if is_timer_scheduled(B747_close_button_cover[9]) then
            stop_timer(B747_close_button_cover[9])
        end
        run_after_time(B747_close_button_cover[9], 5.0)
    end
end

function B747_elec_ext_pwr_1_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[14] = 1
	if B747DR_elec_ext_pwr1_available==1 then 
	  B747DR_elec_ext_pwr_1_switch_mode = 1.0 - B747DR_elec_ext_pwr_1_switch_mode
	  
	  B747DR_elec_apu_pwr_1_switch_mode = 0
	end
    elseif phase == 1 then
        B747_button_switch_position_target[14] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[14] = 0
    end
end


function B747_elec_ext_pwr_2_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[15] = 1
	if B747DR_elec_ext_pwr2_available==1 then 
	  B747DR_elec_ext_pwr_2_switch_mode = 1.0 - B747DR_elec_ext_pwr_2_switch_mode
	  B747DR_elec_apu_pwr_2_switch_mode = 0
	end
    elseif phase == 1 then
        B747_button_switch_position_target[15] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[15] = 0
    end
end

function B747_elec_apu_gen_1_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[16] = 1
	if B747DR_elec_apu_pwr1_available==1 then 
	  B747DR_elec_apu_pwr_1_switch_mode = 1.0 - B747DR_elec_apu_pwr_1_switch_mode
	  B747DR_elec_ext_pwr_1_switch_mode = 0
	end
    elseif phase == 1 then
        B747_button_switch_position_target[16] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[16] = 0
    end
end

function B747_elec_apu_gen_2_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[17] = 1
	if B747DR_elec_apu_pwr2_available==1 then 
	  B747DR_elec_apu_pwr_2_switch_mode = 1.0 - B747DR_elec_apu_pwr_2_switch_mode
	  B747DR_elec_ext_pwr_2_switch_mode = 0
	end
    elseif phase == 1 then
        B747_button_switch_position_target[17] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[17] = 0
    end
end

function B747_elec_bus_tie_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[18] = 1.0 - B747_button_switch_position_target[18] end
end

function B747_elec_bus_tie_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[19] = 1.0 - B747_button_switch_position_target[19] end
end

function B747_elec_bus_tie_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[20] = 1.0 - B747_button_switch_position_target[20] end
end

function B747_elec_bus_tie_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[21] = 1.0 - B747_button_switch_position_target[21] end
end

function B747_elec_gen_ctrl_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[22] = 1.0 - B747_button_switch_position_target[22] end
end

function B747_elec_gen_ctrl_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[23] = 1.0 - B747_button_switch_position_target[23] end
end

function B747_elec_gen_ctrl_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[24] = 1.0 - B747_button_switch_position_target[24] end
end

function B747_elec_gen_ctrl_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[25] = 1.0 - B747_button_switch_position_target[25] end
end

function B747_elec_drive_disc_1_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[26] = 1
        B747DR_gen_drive_disc_status[0] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[26] = 0
    end
end

function B747_elec_drive_disc_2_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[27] = 1
        B747DR_gen_drive_disc_status[1] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[27] = 0
    end
end

function B747_elec_drive_disc_3_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[28] = 1
        B747DR_gen_drive_disc_status[2] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[28] = 0
    end
end

function B747_elec_drive_disc_4_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[29] = 1
        B747DR_gen_drive_disc_status[3] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[29] = 0
    end
end

function B747_hyd_pump_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[30] = 1.0 - B747_button_switch_position_target[30] end
end

function B747_hyd_pump_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[31] = 1.0 - B747_button_switch_position_target[31] end
end

function B747_hyd_pump_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[32] = 1.0 - B747_button_switch_position_target[32] end
end

function B747_hyd_pump_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[33] = 1.0 - B747_button_switch_position_target[33] end
end

function B747_press_outflow_vlv_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[34] = 1.0 - B747_button_switch_position_target[34] end
end

function B747_press_outflow_vlv_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[35] = 1.0 - B747_button_switch_position_target[35] end
end

function B747_temp_zone_rst_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[36] = 1
    elseif phase == 1 then
        B747_button_switch_position_target[36] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[36] = 0
    end
end

function B747_temp_trim_air_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[37] = 1.0 - B747_button_switch_position_target[37] end
end

function B747_temp_recirc_upr_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[38] = 1.0 - B747_button_switch_position_target[38] end
end

function B747_temp_recirc_lwr_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[39] = 1.0 - B747_button_switch_position_target[39] end
end

function B747_temp_aft_cargo_ht_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[40] = 1.0 - B747_button_switch_position_target[40] end
end

function B747_temp_hi_flow_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[41] = 1.0 - B747_button_switch_position_target[41] end
end

function B747_temp_pack_rst_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[42] = 1
    elseif phase == 1 then
        B747_button_switch_position_target[42] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[42] = 0
    end
end

function B747_misc_fuel_xfr_1_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[43] = 1.0 - B747_button_switch_position_target[43] end
end

function B747_start_ign_cont_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[44] = 1.0 - B747_button_switch_position_target[44] end
end

function B747_start_autostart_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[45] = 1.0 - B747_button_switch_position_target[45] end
end

function B747_fuel_jet_nozzle_vlv_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[46] = 1.0 - B747_button_switch_position_target[46] end
end

function B747_fuel_jet_nozzle_vlv_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[47] = 1.0 - B747_button_switch_position_target[47] end
end

function B747_fuel_xfeed_vlv_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[48] = 1.0 - B747_button_switch_position_target[48] end
end

function B747_fuel_xfeed_vlv_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[49] = 1.0 - B747_button_switch_position_target[49] end
end

function B747_fuel_xfeed_vlv_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[50] = 1.0 - B747_button_switch_position_target[50] end
end

function B747_fuel_xfeed_vlv_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[51] = 1.0 - B747_button_switch_position_target[51] end
end

function B747_fuel_ctr_wing_tnk_pump_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[52] = 1.0 - B747_button_switch_position_target[52] end
end

function B747_fuel_ctr_wing_tnk_pump_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[53] = 1.0 - B747_button_switch_position_target[53] end
end

function B747_fuel_stab_tnk_pump_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[54] = 1.0 - B747_button_switch_position_target[54] end
end

function B747_fuel_stab_tnk_pump_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[55] = 1.0 - B747_button_switch_position_target[55] end
end

function B747_fuel_main_pump_fwd_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[56] = 1.0 - B747_button_switch_position_target[56] end
end

function B747_fuel_main_pump_fwd_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[57] = 1.0 - B747_button_switch_position_target[57] end
end

function B747_fuel_main_pump_fwd_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[58] = 1.0 - B747_button_switch_position_target[58] end
end

function B747_fuel_main_pump_fwd_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[59] = 1.0 - B747_button_switch_position_target[59] end
end

function B747_fuel_main_pump_aft_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[60] = 1.0 - B747_button_switch_position_target[60] end
end

function B747_fuel_main_pump_aft_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[61] = 1.0 - B747_button_switch_position_target[61] end
end

function B747_fuel_main_pump_aft_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[62] = 1.0 - B747_button_switch_position_target[62] end
end

function B747_fuel_main_pump_aft_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[63] = 1.0 - B747_button_switch_position_target[63] end
end

function B747_fuel_overd_pump_fwd_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[64] = 1.0 - B747_button_switch_position_target[64] end
end

function B747_fuel_overd_pump_fwd_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[65] = 1.0 - B747_button_switch_position_target[65] end
end

function B747_fuel_overd_pump_aft_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[66] = 1.0 - B747_button_switch_position_target[66] end
end

function B747_fuel_overd_pump_aft_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[67] = 1.0 - B747_button_switch_position_target[67] end
end

function B747_anti_ice_nacelle_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[68] = 1.0 - B747_button_switch_position_target[68] end
end

function B747_anti_ice_nacelle_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[69] = 1.0 - B747_button_switch_position_target[69] end
end

function B747_anti_ice_nacelle_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[70] = 1.0 - B747_button_switch_position_target[70] end
end

function B747_anti_ice_nacelle_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[71] = 1.0 - B747_button_switch_position_target[71] end
end

function B747_anti_ice_wing_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[72] = 1.0 - B747_button_switch_position_target[72] end
end

function B747_anti_ice_window_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[73] = 1.0 - B747_button_switch_position_target[73] end
end

function B747_anti_ice_window_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[74] = 1.0 - B747_button_switch_position_target[74] end
end

function B747_bleed_air_isln_vlv_L_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[75] = 1.0 - B747_button_switch_position_target[75] end
end

function B747_bleed_air_isln_vlv_R_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[76] = 1.0 - B747_button_switch_position_target[76] end
end

function B747_bleed_air_vlv_engine_1_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[77] = 1.0 - B747_button_switch_position_target[77] end
end

function B747_bleed_air_vlv_engine_2_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[78] = 1.0 - B747_button_switch_position_target[78] end
end

function B747_bleed_air_vlv_engine_3_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[79] = 1.0 - B747_button_switch_position_target[79] end
end

function B747_bleed_air_vlv_engine_4_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[80] = 1.0 - B747_button_switch_position_target[80] end
end

function B747_bleed_air_vlv_apu_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[81] = 1.0 - B747_button_switch_position_target[81] end
end

function B747_yaw_damper_upr_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[82] = 1.0 - B747_button_switch_position_target[82] end
end

function B747_yaw_damper_lwr_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[83] = 1.0 - B747_button_switch_position_target[83] end
end

function B747_cargo_fire_arm_fwd_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[84] = 1.0 - B747_button_switch_position_target[84] end
end

function B747_cargo_fire_arm_aft_CMDhandler(phase, duration)
    if phase == 0 then B747_button_switch_position_target[85] = 1.0 - B747_button_switch_position_target[85] end
end

function B747_cargo_fire_disch_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[86] = 1
    elseif phase == 1 then
        B747_button_switch_position_target[86] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[86] = 0
    end
end

function B747_warning_caution_captain_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[87] = 1
        B747DR_master_warning = 0
        B747DR_master_caution = 0
        B747DR_master_caution_audio     = 0
    elseif phase == 1 then
        B747_button_switch_position_target[87] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[87] = 0
    end
end

function B747_warning_caution_fo_CMDhandler(phase, duration)
    if phase == 0 then
        B747_button_switch_position_target[88] = 1
        B747DR_master_warning = 0
        B747DR_master_caution = 0
        B747DR_master_caution_audio     = 0
    elseif phase == 1 then
        B747_button_switch_position_target[88] = 1
    elseif phase == 2 then
        B747_button_switch_position_target[88] = 0
    end
end




----- TOGGLE SWITCHES -------------------------------------------------------------------
function B747_storm_light_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[0] = 1.0 -  B747_toggle_switch_position_target[0]
    end
end

function B747_landing_light_switch_OBL_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[1] = 1.0 -  B747_toggle_switch_position_target[1] end
end

function B747_landing_light_switch_OBR_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[2] = 1.0 -  B747_toggle_switch_position_target[2] end
end

function B747_landing_light_switch_IBL_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[3] = 1.0 -  B747_toggle_switch_position_target[3] end
end

function B747_landing_light_switch_IBR_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[4] = 1.0 -  B747_toggle_switch_position_target[4] end
end

function B747_runway_turnoff_light_switch_L_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[5] = 1.0 -  B747_toggle_switch_position_target[5] end
end

function B747_runway_turnoff_light_switch_R_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[6] = 1.0 -  B747_toggle_switch_position_target[6] end
end

function B747_taxi_light_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[7] = 1.0 -  B747_toggle_switch_position_target[7] end
end


function B747_beacon_light_switch_up_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[8] == -1 then
            B747_toggle_switch_position_target[8] = 0
        elseif B747_toggle_switch_position_target[8] == 0 then
            B747_toggle_switch_position_target[8] = 1
        end
    end
end

function B747_beacon_light_switch_down_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[8] == 1 then
            B747_toggle_switch_position_target[8] = 0
        elseif B747_toggle_switch_position_target[8] == 0 then
            B747_toggle_switch_position_target[8] = -1
        end
    end
end

function B747_nav_light_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[9] = 1.0 -  B747_toggle_switch_position_target[9] end
end

function B747_strobe_light_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[10] = 1.0 -  B747_toggle_switch_position_target[10] end
end

function B747_wing_light_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[11] = 1.0 -  B747_toggle_switch_position_target[11] end
end

function B747_logo_light_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[12] = 1.0 -  B747_toggle_switch_position_target[12] end
end

function B747_ind_light_switch_up_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[13] == -1 then
            B747_toggle_switch_position_target[13] = 0
        elseif B747_toggle_switch_position_target[13] == 0 then
            B747_toggle_switch_position_target[13] = 1
        end
    elseif phase == 2 then
        if B747_toggle_switch_position_target[13] == 1 then
            B747_toggle_switch_position_target[13] = 0
        end
    end
end

function B747_ind_light_switch_down_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[13] == 1 then
            B747_toggle_switch_position_target[13] = 0
        elseif B747_toggle_switch_position_target[13] == 0 then
            B747_toggle_switch_position_target[13] = -1
        end
    end
end

function B747_obsrv_audio_switch_right_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[14] == -1 then
            B747_toggle_switch_position_target[14] = 0
        elseif B747_toggle_switch_position_target[14] == 0 then
            B747_toggle_switch_position_target[14] = 1
        end
    end
end

function B747_obsrv_audio_switch_left_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[14] == 1 then
            B747_toggle_switch_position_target[14] = 0
        elseif B747_toggle_switch_position_target[14] == 0 then
            B747_toggle_switch_position_target[14] = -1
        end
    end
end

function B747_srvc_interphone_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[15] = 1.0 -  B747_toggle_switch_position_target[15] end
end

function B747_engine_start_switch1_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[16] == 0 then
            B747_toggle_switch_position_target[16] = 1
        elseif B747_toggle_switch_position_target[16] == 1 then
            B747_toggle_switch_position_target[16] = 0
        end
    end
end

function B747_engine_start_switch1_off_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[16] = 0
    end
end

function B747_engine_start_switch2_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[17] == 0 then
            B747_toggle_switch_position_target[17] = 1
        elseif B747_toggle_switch_position_target[17] == 1 then
            B747_toggle_switch_position_target[17] = 0
        end
    end
end

function B747_engine_start_switch2_off_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[17] = 0
    end
end

function B747_engine_start_switch3_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[18] == 0 then
            B747_toggle_switch_position_target[18] = 1
        elseif B747_toggle_switch_position_target[18] == 1 then
            B747_toggle_switch_position_target[18] = 0
        end
    end
end

function B747_engine_start_switch3_off_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[18] = 0
    end
end

function B747_engine_start_switch4_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[19] == 0 then
            B747_toggle_switch_position_target[19] = 1
        elseif B747_toggle_switch_position_target[19] == 1 then
            B747_toggle_switch_position_target[19] = 0
        end
    end
end

function B747_engine_start_switch4_off_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[19] = 0
    end
end



function B747_windshield_washer_switch_L_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[20] = 0
    elseif phase == 2 then B747_toggle_switch_position_target[20] = 1 end
end

function B747_windshield_washer_switch_R_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[21] = 0
    elseif phase == 2 then B747_toggle_switch_position_target[21] = 1 end
end

function B747_outflow_valve_switch_open_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[22] = 1
    elseif phase == 2 then
        B747_toggle_switch_position_target[22] = 0
    end
end

function B747_outflow_valve_switch_close_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[22] == 0 then
            B747_toggle_switch_position_target[22] = -1
        end
    elseif phase == 2 then
        if B747_toggle_switch_position_target[22] == -1 then
            B747_toggle_switch_position_target[22] = 0
        end
    end
end

function B747_flight_dir_switch_L_CMDhandler(phase, duration)
    if phase == 0 then
	    
	    ----- SWITCH IS SET TO "ON" POSITION
		if simDR_all_wheels_on_ground == 1 then															-- ON THE GROUND
			if simDR_autopilot_servos_on == 0 then														-- NO AUTOPIOT ENGAGED
				if B747_toggle_switch_position_target[23] == 0.0 										-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
					and B747_toggle_switch_position_target[24] == 0.0 									-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
				then
					if B747DR_autopilot_TOGA_status == 0												-- TOGA LATERAL MODE IS OFF 
					then										
						B747DR_autopilot_TOGA_status=1												-- ACTIVATE "TOGA" MODE
					end		
				end
			end				
		elseif simDR_all_wheels_on_ground == 0 then														-- IN FLIGHT
			if simDR_autopilot_servos_on == 0 then														-- NO AUTOPIOT ENGAGED
				if B747_toggle_switch_position_target[23] == 0.0 										-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
					and B747_toggle_switch_position_target[24] == 0.0 									-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
				then
					simCMD_autopilot_vert_speed_mode:once()												-- ACTIVATE "VS" MODE
					simDR_autopilot_alt_hold_status=0
                    if math.abs(simDR_AHARS_roll_deg_pilot) < 5.0 then									-- BANK ANGLE LESS THAN 5 DEGREES
						simCMD_autopilot_heading_mode:once()											-- ACTIVATE "HEADING HOLD" MODE
					else
					--	B747CMD_ap_att_mode:once()														-- ACTIVATE "ATT" MODE		
                        B747DR_ap_ATT = simDR_AHARS_roll_deg_pilot
					end		
				end
			end							
		end
		
		
		-- SET THE TOGGLE SWITCH ANIMATION POSITION		
		B747_toggle_switch_position_target[23] = 1.0 - B747_toggle_switch_position_target[23]
		if B747_toggle_switch_position_target[23] == 0.0 										-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
					and B747_toggle_switch_position_target[24] == 0.0 									-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
				then
                    B747DR_ap_lastCommand=simDRTime										
                    B747DR_autopilot_TOGA_status=0   
        end
		
		----- SWITCH IS SET TO "OFF" POSITION
		--[[if B747_toggle_switch_position_target[23] == 0.0 												-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
			and B747_toggle_switch_position_target[24] == 0.0 											-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
		then
            if B747DR_autopilot_cmd_L_mode == 0 														-- LEFT CMD AP MODE IS "OFF"
            	and B747DR_autopilot_cmd_C_mode == 0 													-- CENTER CMD AP MODE IS "OFF"
				and B747DR_autopilot_cmd_R_mode == 0 													-- RIGHT CMD AP MODE IS "OFF"
			then
            	B747CMD_ap_reset:once()
            end			
		end]]
				
	end
end

function B747_flight_dir_switch_R_CMDhandler(phase, duration)
    if phase == 0 then
	    
	    ----- SWITCH IS SET TO "ON" POSITION
		if simDR_all_wheels_on_ground == 1 then															-- ON THE GROUND
			if simDR_autopilot_servos_on == 0 then														-- NO AUTOPIOT ENGAGED
				if B747_toggle_switch_position_target[23] == 0.0 										-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
					and B747_toggle_switch_position_target[24] == 0.0 									-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
				then
					if B747DR_autopilot_TOGA_status == 0										-- TOGA LATERAL MODE IS OFF 
					then	
                        B747DR_ap_lastCommand=simDRTime										
						B747DR_autopilot_TOGA_status=1												-- ACTIVATE "TOGA" MODE
					end		
				end
			end				
		elseif simDR_all_wheels_on_ground == 0 then														-- IN FLIGHT
			if simDR_autopilot_servos_on == 0 then														-- NO AUTOPIOT ENGAGED
				if B747_toggle_switch_position_target[23] == 0.0 										-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
					and B747_toggle_switch_position_target[24] == 0.0 									-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
				then
					simCMD_autopilot_vert_speed_mode:once()												-- ACTIVATE "VS" MODE
					simDR_autopilot_alt_hold_status=0
                    if math.abs(simDR_AHARS_roll_deg_pilot) < 5.0 then									-- BANK ANGLE LESS THAN 5 DEGREES
						simCMD_autopilot_heading_mode:once()											-- ACTIVATE "HEADING HOLD" MODE
					else
						--B747CMD_ap_att_mode:once()														-- ACTIVATE "ATT" MODE		
                        B747DR_ap_ATT = simDR_AHARS_roll_deg_pilot
					end		
				end
            
			end							
		end
		
		
		-- SET THE TOGGLE SWITCH ANIMATION POSITION
		B747_toggle_switch_position_target[24] = 1.0 - B747_toggle_switch_position_target[24]
		if B747_toggle_switch_position_target[23] == 0.0 										-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
					and B747_toggle_switch_position_target[24] == 0.0 									-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
				then
                    B747DR_ap_lastCommand=simDRTime										
                    B747DR_autopilot_TOGA_status=0   
        end
		
		----- SWITCH IS SET TO "OFF" POSITION
		--[[if B747_toggle_switch_position_target[23] == 0.0 												-- LEFT FLIGHT DIRECTOR SWITCH IS OFF
			and B747_toggle_switch_position_target[24] == 0.0 											-- RIGHT FLIGHT DIRECTOR SWITCH IS OFF
		then
            if B747DR_autopilot_cmd_L_mode == 0 														-- LEFT CMD AP MODE IS "OFF"
            	and B747DR_autopilot_cmd_C_mode == 0 													-- CENTER CMD AP MODE IS "OFF"
				and B747DR_autopilot_cmd_R_mode == 0 													-- RIGHT CMD AP MODE IS "OFF"
			then
            	B747CMD_ap_reset:once()
            end			
		end]]
				
	end
end

function B747_vor_adf_pilot_switch_L_up_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[25] == -1 then
            B747_toggle_switch_position_target[25] = 0
        elseif B747_toggle_switch_position_target[25] == 0 then
            B747_toggle_switch_position_target[25] = 1
        end
    end
end

function B747_vor_adf_pilot_switch_L_down_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[25] == 1 then
            B747_toggle_switch_position_target[25] = 0
        elseif B747_toggle_switch_position_target[25] == 0 then
            B747_toggle_switch_position_target[25] = -1
        end
    end
end

function B747_vor_adf_pilot_switch_R_up_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[26] == -1 then
            B747_toggle_switch_position_target[26] = 0
        elseif B747_toggle_switch_position_target[26] == 0 then
            B747_toggle_switch_position_target[26] = 1
        end
    end
end

function B747_vor_adf_pilot_switch_R_down_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[26] == 1 then
            B747_toggle_switch_position_target[26] = 0
        elseif B747_toggle_switch_position_target[26] == 0 then
            B747_toggle_switch_position_target[26] = -1
        end
    end
end

function B747_vor_adf_fo_switch_L_up_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[27] == -1 then
            B747_toggle_switch_position_target[27] = 0
        elseif B747_toggle_switch_position_target[27] == 0 then
            B747_toggle_switch_position_target[27] = 1
        end
    end
end

function B747_vor_adf_fo_switch_L_down_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[27] == 1 then
            B747_toggle_switch_position_target[27] = 0
        elseif B747_toggle_switch_position_target[27] == 0 then
            B747_toggle_switch_position_target[27] = -1
        end
    end
end

function B747_vor_adf_fo_switch_R_up_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[28] == -1 then
            B747_toggle_switch_position_target[28] = 0
        elseif B747_toggle_switch_position_target[28] == 0 then
            B747_toggle_switch_position_target[28] = 1
        end
    end
end

function B747_vor_adf_fo_switch_R_down_CMDhandler(phase, duration)
    if phase == 0 then
        if B747_toggle_switch_position_target[28] == 1 then
            B747_toggle_switch_position_target[28] = 0
        elseif B747_toggle_switch_position_target[28] == 0 then
            B747_toggle_switch_position_target[28] = -1
        end
    end
end

function B747_autothrottle_arm_switch_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[29] = 1.0 - B747_toggle_switch_position_target[29]
        B747DR_ap_autothrottle_armed = B747_toggle_switch_position_target[29]
        
        if B747_toggle_switch_position_target[29] == 0 then
            if B747DR_ap_FMA_autothrottle_mode>0 then
                print("B747_autothrottle_arm_switch_CMDhandler fail AT")
                B747DR_autothrottle_fail=1
            end
	     	if B747DR_autothrottle_active == 1 then
	     		--simCMD_autopilot_autothrottle_off:once() 
                 B747DR_autothrottle_active=0
	     	end
        else
            B747DR_autothrottle_fail=0
	    end    
    end
end

function B747_autothrottle_arm_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[29] = 1.0
        B747DR_ap_autothrottle_armed = B747_toggle_switch_position_target[29]
        B747DR_autothrottle_fail=0
    end
end
function B747_autothrottle_disarm_before_CMDhandler(phase, duration)
end
function B747_autothrottle_disarm_CMDhandler(phase, duration)
    if phase == 0 then
        B747_toggle_switch_position_target[29] = 0.0
        B747DR_ap_autothrottle_armed = B747_toggle_switch_position_target[29]
         if B747DR_autothrottle_active == 1 then
             --simCMD_autopilot_autothrottle_off:once() 
             B747DR_autothrottle_active=0
             B747DR_autothrottle_fail=1
         end
    end
end

function B747_heading_ref_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[30] = 1.0 - B747_toggle_switch_position_target[30] end
end





function B747_sun_visor_up_down_capt_CMDhandler(phase, duration)
    if phase == 0 then 
        B747_toggle_switch_position_target[31] = 1.0 - B747_toggle_switch_position_target[31] 
        if B747_toggle_switch_position_target[31]<0.1 then
            B747DR_sun_visor_left_right_capt_target=0.68
        else  
            B747DR_sun_visor_left_right_capt_target=0.0
        end    

    end
end
function B747_sun_visor_up_down_fo_CMDhandler(phase, duration)
    if phase == 0 then 
        B747_toggle_switch_position_target[32] = 1.0 - B747_toggle_switch_position_target[32]
        if B747_toggle_switch_position_target[32]<0.1 then
            B747DR_sun_visor_left_right_fo_target = 0.68
        else
            B747DR_sun_visor_left_right_fo_target = 0
        end
    end
end





function B747_window_shade_up_down_front_capt_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[33] = 1.0 - B747_toggle_switch_position_target[33] end
end

function B747_window_shade_up_down_rear_capt_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[34] = 1.0 - B747_toggle_switch_position_target[34] end
end


function B747_window_shade_up_down_front_fo_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[35] = 1.0 - B747_toggle_switch_position_target[35] end
end

function B747_window_shade_up_down_rear_fo_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[36] = 1.0 - B747_toggle_switch_position_target[36] end
end



function B747_cabin_lights_switch_CMDhandler(phase, duration)
    if phase == 0 then B747_toggle_switch_position_target[37] = 1.0 - B747_toggle_switch_position_target[37] end
end




function B747_ai_manip_quick_start_CMDhandler(phase, duration)
	if phase == 0 then 
		B747_set_manip_CD()
		B747_set_manip_ER()
		B747_set_manip_all_modes()
	end		
end	



--*************************************************************************************--
--** 				                 CUSTOM COMMANDS                			     **--
--*************************************************************************************--

----- BUTTON SWITCH COVERS --------------------------------------------------------------
B747CMD_button_switch_cover = {}
for i = 0, NUM_BTN_SW_COVERS-1 do
    B747CMD_button_switch_cover[i] 		= deferred_command("laminar/B747/button_switch_cover" .. string.format("%02d", i), "Button Switch Cover" .. string.format("%02d", i), B747_button_switch_cover_CMDhandler[i])
end



----- GLARESHIELD BUTTON SWITCHES -------------------------------------------------------

-- WARNING/CAUTION
B747CMD_warning_caution_captain 		= deferred_command("laminar/B747/button_switch/warn_caut_capt", "Warning/Caution Reset (Captain)", B747_warning_caution_captain_CMDhandler)
B747CMD_warning_caution_fo 				= deferred_command("laminar/B747/button_switch/warn_caut_fo", "Warning/Caution Reset (First Officer)", B747_warning_caution_fo_CMDhandler)



----- MAIN PANEL BUTTON SWITCHES --------------------------------------------------------

-- ALTERNATE FLAP
B747CMD_altn_flap 						= deferred_command("laminar/B747/button_switch/altn_flap", "Alternate Flaps", B747_altn_flap_CMDhandler)

-- ALTERNATE GEAR
B747CMD_altn_nose_gear_extend 			= deferred_command("laminar/B747/button_switch/altn_nose_gear_extend", "Alternate Nose Gear Extend", B747_altn_nose_gear_extend_CMDhandler)
B747CMD_altn_wing_gear_extend 			= deferred_command("laminar/B747/button_switch/altn_wing_gear_extend", "Alternate Wing gear Extend", B747_altn_wing_gear_extend_CMDhandler)

-- GROUND PROXIMITY
B747CMD_gnd_prox_gs_inhibit 			= deferred_command("laminar/B747/button_switch/gnd_prox_gs_inhibit", "Ground Proximity Glideslope Inhibit", B747_gnd_prox_gs_inhibit_CMDhandler)
B747CMD_gnd_prox_flap_ovrd 				= deferred_command("laminar/B747/button_switch/gnd_prox_flap_ovrd", "Ground Proximity Flap Override", B747_gnd_prox_flap_ovrd_CMDhandler)
B747CMD_gnd_prox_gear_ovrd 				= deferred_command("laminar/B747/button_switch/gnd_prox_gear_ovrd", "Ground Proximity gear Override", B747_gnd_prox_gear_ovrd_CMDhandler)
B747CMD_gnd_prox_terr_ovrd 				= deferred_command("laminar/B747/button_switch/gnd_prox_terr_ovrd", "Ground Proximity Terrain Override", B747_gnd_prox_terr_ovrd_CMDhandler)



----- OVERHEAD PANEL BUTTON SWITCHES ----------------------------------------------------

-- ELECTRONIC ENGINE CONTROL
B747CMD_elec_eng_ctrl_1 				= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_1", "Electronic Engine Control 1", B747_elec_eng_ctrl_1_CMDhandler)
B747CMD_elec_eng_ctrl_2 				= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_2", "Electronic Engine Control 2", B747_elec_eng_ctrl_2_CMDhandler)
B747CMD_elec_eng_ctrl_3 				= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_3", "Electronic Engine Control 3", B747_elec_eng_ctrl_3_CMDhandler)
B747CMD_elec_eng_ctrl_4 				= deferred_command("laminar/B747/button_switch/elec_eng_ctrl_4", "Electronic Engine Control 4", B747_elec_eng_ctrl_4_CMDhandler)

-- ELECTRIC
B747CMD_elec_util_L 					= deferred_command("laminar/B747/button_switch/elec_util_L", "Utility L", B747_elec_util_L_CMDhandler)
B747CMD_elec_util_R 					= deferred_command("laminar/B747/button_switch/elec_util_R",  "Utility R", B747_elec_util_R_CMDhandler)
B747CMD_elec_battery 					= deferred_command("laminar/B747/button_switch/elec_battery", "Battery", B747_elec_battery_CMDhandler)
B747CMD_elec_ext_pwr_1 					= deferred_command("laminar/B747/button_switch/elec_ext_pwr_1", "External Power 1", B747_elec_ext_pwr_1_CMDhandler)
B747CMD_elec_ext_pwr_2 					= deferred_command("laminar/B747/button_switch/elec_ext_pwr_2", "External Power 2", B747_elec_ext_pwr_2_CMDhandler)
B747CMD_elec_apu_gen_1 					= deferred_command("laminar/B747/button_switch/elec_apu_gen_1", "APU Generator 1", B747_elec_apu_gen_1_CMDhandler)
B747CMD_elec_apu_gen_2 					= deferred_command("laminar/B747/button_switch/elec_apu_gen_2", "APU Generator 2", B747_elec_apu_gen_2_CMDhandler)
B747CMD_elec_bus_tie_1 					= deferred_command("laminar/B747/button_switch/elec_bus_tie_1", "Bus Tie 1", B747_elec_bus_tie_1_CMDhandler)
B747CMD_elec_bus_tie_2 					= deferred_command("laminar/B747/button_switch/elec_bus_tie_2", "Bus Tie 2", B747_elec_bus_tie_2_CMDhandler)
B747CMD_elec_bus_tie_3 					= deferred_command("laminar/B747/button_switch/elec_bus_tie_3", "Bus Tie 3", B747_elec_bus_tie_3_CMDhandler)
B747CMD_elec_bus_tie_4 					= deferred_command("laminar/B747/button_switch/elec_bus_tie_4", "Bus Tie 4", B747_elec_bus_tie_4_CMDhandler)
B747CMD_elec_gen_ctrl_1 				= deferred_command("laminar/B747/button_switch/elec_gen_ctrl_1", "Generator Control 1", B747_elec_gen_ctrl_1_CMDhandler)
B747CMD_elec_gen_ctrl_2 				= deferred_command("laminar/B747/button_switch/elec_gen_ctrl_2", "Generator Control 2", B747_elec_gen_ctrl_2_CMDhandler)
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

-- DOORS
simCMDDOpen={}
simCMDDOpen[0]=find_command("sim/flight_controls/door_open_1")
simCMDDOpen[1]=find_command("sim/flight_controls/door_open_2")
simCMDDOpen[2]=find_command("sim/flight_controls/door_open_3")
simCMDDOpen[3]=find_command("sim/flight_controls/door_open_4")
simCMDDOpen[4]=find_command("sim/flight_controls/door_open_5")
simCMDDOpen[5]=find_command("sim/flight_controls/door_open_6")
simCMDDOpen[6]=find_command("sim/flight_controls/door_open_7")
simCMDDOpen[7]=find_command("sim/flight_controls/door_open_8")
simCMDDOpen[8]=find_command("sim/flight_controls/door_open_9")
simCMDDOpen[9]=find_command("sim/flight_controls/door_open_10")

simCMDDClose={}
simCMDDClose[0]=find_command("sim/flight_controls/door_close_1")
simCMDDClose[1]=find_command("sim/flight_controls/door_close_2")
simCMDDClose[2]=find_command("sim/flight_controls/door_close_3")
simCMDDClose[3]=find_command("sim/flight_controls/door_close_4")
simCMDDClose[4]=find_command("sim/flight_controls/door_close_5")
simCMDDClose[5]=find_command("sim/flight_controls/door_close_6")
simCMDDClose[6]=find_command("sim/flight_controls/door_close_7")
simCMDDClose[7]=find_command("sim/flight_controls/door_close_8")
simCMDDClose[8]=find_command("sim/flight_controls/door_close_9")
simCMDDClose[9]=find_command("sim/flight_controls/door_close_10")


-- function B747_open_door_CMDhandler(phase, duration) 
--   if phase==0 then
--     for i = 0, 9 do
--       simCMDDOpen[i]:once()
--     end
--   end
-- end
-- 
-- function B747_close_door_CMDhandler (phase, duration)
--   if phase==0 then
--     for i = 0, 9 do
--       simCMDDClose[i]:once()
--     end
--   end
-- end
-- B747CMD_openAllDoors 				= deferred_command("laminar/B747/button_switch/open_all_doors", "Open All doors", B747_open_door_CMDhandler)
-- B747CMD_closeAllDoors 				= deferred_command("laminar/B747/button_switch/close_all_doors", "Close All doors", B747_close_door_CMDhandler)

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
B747CMD_autothrottle_arm_switch 		= deferred_command("laminar/B747/toggle_switch/autothrottle", "Autothrottle toggle Switch", B747_autothrottle_arm_switch_CMDhandler)
B747CMD_autothrottle_arm            	= deferred_command("laminar/B747/authrottle_arm", "Autothrottle Arm", B747_autothrottle_arm_CMDhandler)
B747CMD_autothrottle_disarm         	= deferred_command("laminar/B747/authrottle_disarm", "Autothrottle Disarm", B747_autothrottle_disarm_CMDhandler)
    
simCMD_autothrottle_on                  = replace_command("sim/autopilot/autothrottle_arm", B747_autothrottle_arm_CMDhandler)
simCMD_autothrottle_off                 = wrap_command("sim/autopilot/autothrottle_off", B747_autothrottle_disarm_before_CMDhandler, B747_autothrottle_disarm_CMDhandler)
simCMD_autothrottle_arm_switch 		= replace_command("sim/autopilot/autothrottle_toggle", B747_autothrottle_arm_switch_CMDhandler)

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
function B747_set_animation_position(current_value, target, min, max, speed)

    local fps_factor = math.min(1.0, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end











----- BUTTON SWITCH COVER POSITION ANIMATION --------------------------------------------
function B747_button_switch_cover_animation()
    local refreshRoll=simDR_AHARS_roll_deg_pilot
    for i = 0, NUM_BTN_SW_COVERS-1 do
        B747DR_button_switch_cover_position[i] = B747_set_animation_position(B747DR_button_switch_cover_position[i], B747_button_switch_cover_position_target[i], 0.0, 1.0, 10.0)
    end

end





---- BUTTON SWITCH POSITION ANIMATION ---------------------------------------------------
function B747_button_switch_animation()

    for i = 0, NUM_BTN_SW-1 do
        -- STANDARD SPEED FOR SWITCH ANIMATION
        local speed = 10.0
        -- SET ANIMATION SPEED FASTER FOR MOMENTARY SWITCHES
        if index == 14                      -- EXTERNAL POWER 1
            or i == 15                      -- EXTERNAL POWER 2
            or i == 16                      -- APU GEN 1
            or i == 17                      -- APU GEN 2
            or i == 26                      -- DRIVE DISC 1
            or i == 27                      -- DRIVE DISC 2
            or i == 28                      -- DRIVE DISC 3
            or i == 29                      -- DRIVE DISC 4
            or i == 36                      -- ZONE RESET
            or i == 42                      -- PACK RESET
            or i == 86                      -- CARGO FIRE DISCHARGE
            or (i >=87 and i <= 88)         -- MASTER WARNING & CAUTION (CAPTAIN & FIRST OFFICER)
        then
            speed = 30.0
        end
        B747DR_button_switch_position[i] = B747_set_animation_position(B747DR_button_switch_position[i], B747_button_switch_position_target[i], 0.0, 1.0, speed)
    end

end





----- TOGGLE SWITCH POSITION ANIMATION --------------------------------------------------
function B747_toggle_switch_animation()
    if B747DR_sun_visor_left_right_fo_target >=0 then
        B747DR_sun_visor_left_right_fo = B747_set_animation_position(B747DR_sun_visor_left_right_fo, B747DR_sun_visor_left_right_fo_target, 0.0, 1.0, 1)
    end
    if B747DR_sun_visor_left_right_capt_target >=0 then
        B747DR_sun_visor_left_right_capt = B747_set_animation_position(B747DR_sun_visor_left_right_capt, B747DR_sun_visor_left_right_capt_target, 0.0, 1.0, 1)
    end
    if math.abs(B747DR_sun_visor_left_right_capt-B747DR_sun_visor_left_right_capt_target)<0.01 then
        B747DR_sun_visor_left_right_capt_target=-1
    end
    if math.abs(B747DR_sun_visor_left_right_fo-B747DR_sun_visor_left_right_fo_target)<0.01 then
        B747DR_sun_visor_left_right_fo_target=-1
    end
    for i = 0, NUM_TOGGLE_SW-1 do
        -- STANDARD FOR 2 POS SWITCHES
        local min, max = 0.0, 1.0

        -- SET THE SPEED OF THE ANIMATION
        local speed = 50.0
        if i >= 31 and i <= 32 then
            speed = 2.0             --  SUN VISORS
        elseif i >= 33 and i <= 36 then
            speed = 2.0             --  WINDOW SHADES
        end

        -- SET THE MIN VALUE FOR 3 POS SWITCHES
        if i == 8                       -- BEACON LIGHTS
            or i == 13                  -- IND LIGHTS
            or i == 14                  -- OBSERVER AUDIO
            or i == 22                  -- OUTFLOW VALVE OPEN/CLOSE
            or i == 25                  -- VOR/ADF CAPTAIN L
            or i == 26                  -- VOR/ADF CAPTAIN R
            or i == 27                  -- VOR/ADF FIRST OFFICER L
            or i == 28                  -- VOR/ADF FIRST OFFICER R
        then
            min = -1.0
        end

        B747DR_toggle_switch_position[i] = B747_set_animation_position(B747DR_toggle_switch_position[i], B747_toggle_switch_position_target[i], min, max, speed)
        
    end

end





----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_manip_monitor_AI()

    if B747DR_init_manip_CD == 1 then
        B747_set_manip_all_modes()
        B747_set_manip_CD()
        B747DR_init_manip_CD = 2
    end

end






----- DEFERRED INIT ---------------------------------------------------------------------
function B747_flight_start_DeferredInit()

    B747CMD_warning_caution_captain:once()

end










----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_manip_CD()

	-- BUTTON SWITCHES
	for i = 0, 86 do
		B747_button_switch_position_target[i] = 0
		B747DR_button_switch_position[i] = 0
	end

	B747DR_elec_ext_pwr_1_switch_mode = 0
	B747DR_elec_apu_pwr_1_switch_mode = 0


	-- TOGGLE SWITCHES
	for j = 0, 37 do
        if j < 13 then
            B747_toggle_switch_position_target[j] = 1
            B747DR_toggle_switch_position[j] = 1
        else
            B747_toggle_switch_position_target[j] = 0
		    B747DR_toggle_switch_position[j] = 0
        end
    end

    for k = 1, 12 do
        B747_toggle_switch_position_target[k] = 1
        B747DR_toggle_switch_position[k] = 1
        --not 7
    end
    if simDR_percent_lights_on > 0.1 then
        B747_toggle_switch_position_target[13] = -1
    end
    B747DR_toggle_switch_position[20] = 1
    B747_toggle_switch_position_target[20] = 1
    B747DR_toggle_switch_position[21] = 1
    B747_toggle_switch_position_target[21] = 1
    B747DR_toggle_switch_position[8] = 0
    B747_toggle_switch_position_target[8] = 0
end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_manip_ER()

	B747_set_manip_CD()

    -- ELECTRICAL SYSTEM
    B747_button_switch_position_target[11] = 1
	B747DR_button_switch_position[11] = 1
    B747_button_switch_position_target[12] = 1
	B747DR_button_switch_position[12] = 1
	B747_button_switch_position_target[13] = 1
	B747DR_button_switch_position[13] = 1
	B747_button_switch_position_target[18] = 1
	B747DR_button_switch_position[18] = 1
	B747_button_switch_position_target[19] = 1
	B747DR_button_switch_position[19] = 1
    B747_button_switch_position_target[20] = 1
	B747DR_button_switch_position[20] = 1	
	B747_button_switch_position_target[21] = 1
	B747DR_button_switch_position[21] = 1
	B747_button_switch_position_target[22] = 1
	B747DR_button_switch_position[22] = 1
	B747_button_switch_position_target[23] = 1
	B747DR_button_switch_position[23] = 1
	B747_button_switch_position_target[24] = 1
	B747DR_button_switch_position[24] = 1
	B747_button_switch_position_target[25] = 1
	B747DR_button_switch_position[25] = 1

    -- HYDRAULIC SYSTEM
    B747_button_switch_position_target[30] = 1
	B747DR_button_switch_position[30] = 1
    B747_button_switch_position_target[31] = 1
	B747DR_button_switch_position[31] = 1
	B747_button_switch_position_target[32] = 1
	B747DR_button_switch_position[32] = 1
	B747_button_switch_position_target[33] = 1
	B747DR_button_switch_position[33] = 1

    -- FUEL SYSTEM
    B747_button_switch_position_target[48] = 1
	B747DR_button_switch_position[48] = 1
	B747_button_switch_position_target[51] = 1
	B747DR_button_switch_position[51] = 1
	B747_button_switch_position_target[52] = 1
	B747DR_button_switch_position[52] = 1
	B747_button_switch_position_target[53] = 1
	B747DR_button_switch_position[53] = 1
    if simDR_all_wheels_on_ground==0 then
        B747_button_switch_position_target[54] = 1
        B747DR_button_switch_position[54] = 1
        B747_button_switch_position_target[55] = 1
        B747DR_button_switch_position[55] = 1
    end
	B747_button_switch_position_target[56] = 1
	B747DR_button_switch_position[56] = 1
	B747_button_switch_position_target[57] = 1
	B747DR_button_switch_position[57] = 1
	B747_button_switch_position_target[58] = 1
	B747DR_button_switch_position[58] = 1
	B747_button_switch_position_target[59] = 1
	B747DR_button_switch_position[59] = 1
	B747_button_switch_position_target[60] = 1
	B747DR_button_switch_position[60] = 1
	B747_button_switch_position_target[61] = 1
	B747DR_button_switch_position[61] = 1
	B747_button_switch_position_target[62] = 1
	B747DR_button_switch_position[62] = 1
	B747_button_switch_position_target[63] = 1
	B747DR_button_switch_position[63] = 1
	B747_button_switch_position_target[64] = 1
	B747DR_button_switch_position[64] = 1
	B747_button_switch_position_target[65] = 1
	B747DR_button_switch_position[65] = 1
	B747_button_switch_position_target[66] = 1
	B747DR_button_switch_position[66] = 1
	B747_button_switch_position_target[67] = 1
	B747DR_button_switch_position[67] = 1

    -- YAW DAMPER    
	B747_button_switch_position_target[82] = 1
	B747DR_button_switch_position[82] = 1
	B747_button_switch_position_target[83] = 1
	B747DR_button_switch_position[83] = 1

     -- TEMPERATURE   
 	B747_button_switch_position_target[37] = 1
	B747DR_button_switch_position[83] = 1 

    -- BLEED AIR
	B747_button_switch_position_target[75] = 1
	B747DR_button_switch_position[75] = 1
	B747_button_switch_position_target[76] = 1
	B747DR_button_switch_position[76] = 1
	B747_button_switch_position_target[77] = 1
	B747DR_button_switch_position[77] = 1
	B747_button_switch_position_target[78] = 1
	B747DR_button_switch_position[78] = 1
	B747_button_switch_position_target[79] = 1
	B747DR_button_switch_position[79] = 1
	B747_button_switch_position_target[80] = 1
	B747DR_button_switch_position[80] = 1   

    -- LIGHTS DIM
    if simDR_percent_lights_on > 0.1 then
        B747_toggle_switch_position_target[13] = -1
    end
end






----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_manip_all_modes()
	
	
	
	run_after_time(B747_flight_start_DeferredInit, 2.0)

    -- ELECTRONIC ENGINE CONTROL
	B747_button_switch_position_target[7] = 1
	B747DR_button_switch_position[7] = 1
	B747_button_switch_position_target[8] = 1
	B747DR_button_switch_position[8] = 1
	B747_button_switch_position_target[9] = 1
	B747DR_button_switch_position[9] = 1
	B747_button_switch_position_target[10] = 1
	B747DR_button_switch_position[10] = 1
	
    -- GENERATOR DRIVE DISC
	B747_button_switch_position_target[26] = 0
	B747DR_button_switch_position[26] = 1
	B747_button_switch_position_target[27] = 0
	B747DR_button_switch_position[27] = 1
	B747_button_switch_position_target[28] = 0
	B747DR_button_switch_position[28] = 1
	B747_button_switch_position_target[29] = 0
	B747DR_button_switch_position[29] = 1
	
	B747DR_gen_drive_disc_status[0] = 0
	B747DR_gen_drive_disc_status[1] = 0
	B747DR_gen_drive_disc_status[2] = 0
	B747DR_gen_drive_disc_status[3] = 0

    -- FUEL SYSTEM
	B747_button_switch_position_target[49] = 1
	B747DR_button_switch_position[49] = 1
	B747_button_switch_position_target[50] = 1
	B747DR_button_switch_position[50] = 1

end







----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_manip()

    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then
	print("Cold and Dark Start")
        B747_set_manip_CD()
        

    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then
	print("Start Engines Running")
        B747_set_manip_ER()

    end
    

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_manip_all_modes() 
       

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end
function setACFType()
  print("XTLua Typing "..simDR_livery)
  if string.match(simDR_livery, "Global Supertanker") then
      B747DR_acfType=1
      simDR_acf_m_jettison=80902
  else
      simDR_acf_m_jettison=0
  end
  B747_flight_start_manip()
end
local flightInit=false
function flight_start()
    flightInit=false
    do_flight_start()
end
function do_flight_start()
    print("XTLua Flight Start "..simDR_livery)
    local refreshOngroud=simDR_all_wheels_on_ground
    B747_flight_start_manip()
    run_after_time(setACFType,1)
end
function livery_load()
	local refreshLivery=simDR_livery_path

	run_after_time(setACFType, 1)  --Load specific simConfig data for current livery
end
function B747_animate_value(current_value, target, min, max, speed)

    --[[local fps_factor = math.min(0.1, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end]]--
    local fps_factor = math.min(0.1, speed * SIM_PERIOD)
	local nextValue=current_value + ((target - current_value) * fps_factor)
    if nextValue >= (max - 0.001) then
        return max
    elseif nextValue <= (min + 0.001) then
       return min
    else
        return nextValue
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
function B747_throttle_animation()
    local pinlever=false
    local refreshThro=0
    for i=0,3,1 do
        if simDR_engine_throttle_rev[i]<-0 or B747DR_throttle_reversor[i]<-0 and simDR_prop_mode[i]==3 then
            pinlever=true
        end
        refreshThro=simDR_engn_thro[i]
    end
    for i=0,3,1 do
        if pinlever then

            B747DR_throttle_reversor[i]=B747_interpolate_value(B747DR_throttle_reversor[i],simDR_engine_throttle_rev[i],-1,0,1)
            B747DR_throttle[i]=B747_interpolate_value(B747DR_throttle[i],0,0,1,1)
        else
            B747DR_throttle_reversor[i]=B747_interpolate_value(B747DR_throttle_reversor[i],0,-1,0,1)


            --B747DR_throttle[i]=simDR_engn_thro[i]--B747_interpolate_value(simDR_engn_thro[i],0,0,1,1)--simDR_engn_thro[i]
        end
    end

end
--function flight_crash() end

--function before_physics() end
debug_manipulators     = deferred_dataref("laminar/B747/debug/manipulators", "number")
function after_physics()
    if debug_manipulators>0 then return end
    if flightInit==false then
        do_flight_start()
    end
    flightInit=true

    B747_button_switch_cover_animation()
    B747_button_switch_animation()
    B747_toggle_switch_animation()
    B747_throttle_animation()
    B747_manip_monitor_AI()

end

--function after_replay() end
