--[[
*****************************************************************************************
* Program Script Name	:	B747.45.fltCtrls
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





--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
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
local B747_rudder_trim_sel_dial_position_target = 0
local B747_aileron_trim_sel_dial_position_target = 0
B747_speedbrake_stop = deferred_dataref("laminar/B747/flt_ctrls/speedbrake_stop", "number") --0
local B747_speedbrake_lever_pos_target = 0
local B747_wheels_on_ground = 1
local B747_last_sim_sb_handle_pos = 0
B747_sb_manip_changed = deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever_changed", "number")
simDR_radarAlt1           	= find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
B747DR_fmc_notifications            = find_dataref("laminar/B747/fms/notification")


--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_button_switch_position   = find_dataref("laminar/B747/button_switch/position")

B747DR_fuel_control_toggle_switch_pos   = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")

B747DR_CAS_warning_status       = find_dataref("laminar/B747/CAS/warning_status")
B747DR_CAS_caution_status       = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status      = find_dataref("laminar/B747/CAS/advisory_status")

B747DR_airspeed_V1              = find_dataref("laminar/B747/airspeed/V1")
B747DR_parking_brake_ratio = find_dataref("laminar/B747/flt_ctrls/parking_brake_ratio")
B747DR_autobrakes_sel_dial_pos  = deferred_dataref("laminar/B747/gear/autobrakes/sel_dial_pos", "number")
B747DR_CAS_memo_status          = find_dataref("laminar/B747/CAS/memo_status")

-- crazytimtimtim
B747DR_IRS_dial_pos             = find_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos")
B747DR_ELEC_BATT                = find_dataref("sim/cockpit/electrical/battery_array_on")
B747DR_engines_throttle_ind     = find_dataref("sim/cockpit2/engine/actuators/throttle_ratio")
-- crazytimtimtim end
--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_yaw_damper_upr = find_command("laminar/B747/button_switch/yaw_damper_upr")
B747CMD_yaw_damper_lwr = find_command("laminar/B747/button_switch/yaw_damper_lwr")




--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")

simDR_innerslats_ratio  	= find_dataref("sim/flightmodel2/controls/slat1_deploy_ratio")
simDR_outerslats_ratio  	= find_dataref("sim/flightmodel2/controls/slat2_deploy_ratio")
simDR_autoslats_ratio  		= find_dataref("sim/aircraft/parts/acf_slatEQ")
simDR_prop_mode                 = find_dataref("sim/cockpit2/engine/actuators/prop_mode")
simDR_all_wheels_on_ground      = find_dataref("sim/flightmodel/failures/onground_all")

simDR_speedbrake_ratio_control  = find_dataref("sim/cockpit2/controls/speedbrake_ratio")
simDR_flap_handle_deploy_ratio  = find_dataref("sim/cockpit2/controls/flap_handle_deploy_ratio")
simDR_flap_ratio_control        = find_dataref("sim/cockpit2/controls/flap_ratio")                      -- FLAP HANDLE
simDR_flap_deploy_ratio         = find_dataref("sim/flightmodel2/controls/flap1_deploy_ratio")
simDR_yaw_damper_on             = find_dataref("sim/cockpit2/switches/yaw_damper_on")
simDR_gear_vert_defl            = find_dataref("sim/flightmodel2/gear/tire_vertical_deflection_mtr")
simDR_gear_deploy_ratio         = find_dataref("sim/flightmodel2/gear/deploy_ratio")
simDR_wing_flap1_deg            = find_dataref("sim/flightmodel2/wing/flap1_deg")
B747DR_airspeed_flapsRef        = find_dataref("laminar/B747/airspeed/flapsRef")
simDR_ind_airspeed_kts_pilot    = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
simDR_engine_N1_pct             = find_dataref("sim/cockpit2/engine/indicators/N1_percent")
simDR_radio_alt_height_capt     = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")


simDR_parking_brake_ratio       = find_dataref("sim/cockpit2/controls/parking_brake_ratio")
simDR_elevator_trim             = find_dataref("sim/flightmodel2/controls/elevator_trim")
simDR_acf_weight_total_kg       = find_dataref("sim/flightmodel/weight/m_total")
simDR_flap_control_fail         = find_dataref("sim/operation/failures/rel_flap_act")

simDR_engine_throttle_jet_all   = find_dataref("sim/cockpit2/engine/actuators/throttle_jet_rev_ratio_all")

simDR_hyd_press_1_2             = find_dataref("laminar/B747/hydraulics/indicators/hydraulic_pressure_1_2_4")

simDR_cg_adjust					= find_dataref("sim/flightmodel/misc/cgz_ref_to_default")
--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--


B747DR_alt_flaps_sel_dial_pos   = deferred_dataref("laminar/B747/flt_ctrls/alt_flaps/sel_dial_pos", "number")
B747DR_rudder_trim_sel_dial_pos = deferred_dataref("laminar/B747/flt_ctrls/rudder_trim/sel_dial_pos", "number")
B747DR_rudder_trim_switch_pos   = deferred_dataref("laminar/B747/flt_ctrls/aileron_trim/switch_pos", "number")
B747DR_speedbrake_lever_pos     = deferred_dataref("laminar/B747/flt_ctrls/speedbrake/lever_pos", "number")
B747DR_flap_trans_status        = deferred_dataref("laminar/B747/flt_ctrls/flap/transition_status", "number")
B747DR_EICAS1_flap_display_status = deferred_dataref("laminar/B747/flt_ctrls/flaps/EICAS1_display_status", "number")
B747DR_elevator_trim_mid_ind    = deferred_dataref("laminar/B747/flt_ctrls/elevator_trim/mid/indicator", "number")
B747DR__gear_chocked           = deferred_dataref("laminar/B747/gear/chocked", "number")
B747DR_init_fltctrls_CD         = deferred_dataref("laminar/B747/fltctrls/init_CD", "number")
--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

----- SPEEDBRAKE HANDLE -----------------------------------------------------------------
B747DR_speedbrake_lever     	= deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever", "number")--uses change handler B747_speedbrake_lever_DRhandler in xlua
B747DR_speedbrake_lever_detent  = deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever_detent", "number")



----- FLAP HANDLE -----------------------------------------------------------------------
B747DR_flap_lever_detent		= deferred_dataref("laminar/B747/flt_ctrls/flap_lever_detent", "number")

--STAB TRIM setting
B747DR_elevator_trim				    = deferred_dataref("laminar/B747/fmc/elevator_trim", "number")


--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--

----- SPEEDBRAKE LEVER ------------------------------------------------------------------
function B747_speedbrake_manip_timeout()
	B747_sb_manip_changed = 0 
end

function B747_speedbrake_lever_DRhandler()
    -- Done in init/scripts
--[[	
    -- DOWN DETENT
	if B747DR_speedbrake_lever < 0.01 then
		B747DR_speedbrake_lever = 0.0
        simDR_speedbrake_ratio_control = 0.0
        B747DR_CAS_memo_status[45] = 0
		
     -- ARMED DETENT
    elseif B747DR_speedbrake_lever < 0.15 and
        B747DR_speedbrake_lever > 0.10
    then
        B747DR_speedbrake_lever = 0.125 
        simDR_speedbrake_ratio_control = -0.5
        B747DR_CAS_memo_status[45] = 1
    
    -- ALL OTHER POSITIONS    
    else
	    B747DR_speedbrake_lever = math.min(1.0 - (B747_speedbrake_stop * 0.47), B747DR_speedbrake_lever)
        simDR_speedbrake_ratio_control = B747_rescale(0.15, 0.0, 1.0 - (B747_speedbrake_stop * 0.47), 1.0, B747DR_speedbrake_lever)
        B747DR_CAS_memo_status[45] = 0     
    end	   
    
    B747_sb_manip_changed = 1 
    if is_timer_scheduled(B747_speedbrake_manip_timeout) then
		stop_timer(B747_speedbrake_manip_timeout)    
	end	
	run_after_time(B747_speedbrake_manip_timeout, 2.0)
]]
end




function B747_speedbrake_lever_detent_DRhandler() end



function B747_flap_lever_detent_DRhandler() end	









--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- ALTERNATE FLAPS
function B747_alt_flaps_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_alt_flaps_sel_dial_pos = math.min(B747DR_alt_flaps_sel_dial_pos+1, 1)
    end
end
function B747_alt_flaps_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_alt_flaps_sel_dial_pos = math.max(B747DR_alt_flaps_sel_dial_pos-1,-1)
    end
end




-- STABLIZER TRIM
function B747_stablizer_trim_up_capt_CMDhandler(phase, duration)
    simCMD_stablizer_trim_up:once()
    --[[if phase == 0 then
        simCMD_stablizer_trim_up:once()
    end
    if phase == 1 then
        simCMD_stablizer_trim_up:start()
    end
    if phase == 2 then
        simCMD_stablizer_trim_up:stop()
    end]]--
end

function B747_stablizer_trim_dn_capt_CMDhandler(phase, duration)
    simCMD_stablizer_trim_dn:once()
    --[[if phase == 0 then
        simCMD_stablizer_trim_dn:once()
    end
    if phase == 1 then
        simCMD_stablizer_trim_dn:start()
    end
    if phase == 2 then
        simCMD_stablizer_trim_dn:stop()
    end]]--
end



function B747_stablizer_trim_up_fo_CMDhandler(phase, duration)
    simCMD_stablizer_trim_up:once()
   --[[ if phase == 0 then
        simCMD_stablizer_trim_up:once()
    end
    if phase == 1 then
        simCMD_stablizer_trim_up:start()
    end
    if phase == 2 then
        simCMD_stablizer_trim_up:stop()
    end]]--
end

function B747_stablizer_trim_dn_fo_CMDhandler(phase, duration)
    simCMD_stablizer_trim_dn:once()
  --[[  if phase == 0 then
        simCMD_stablizer_trim_dn:once()
    end
    if phase == 1 then
        simCMD_stablizer_trim_dn:start()
    end
    if phase == 2 then
        simCMD_stablizer_trim_dn:stop()
    end]]--
end




function B747_ai_fltctrls_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
	  	B747_set_fltctrls_all_modes() 
	  	B747_set_fltctrls_CD()
	  	B747_set_fltctrls_ER()
	end	
end	





--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--


-- RUDDER TRIM
function sim_rudder_trim_left_beforeCMDhandler(phase, duration) end

function sim_rudder_trim_left_afterCMDhandler(phase, duration)
    if phase == 0 then
        B747_rudder_trim_sel_dial_position_target = -1
    elseif phase == 2 then
        B747_rudder_trim_sel_dial_position_target = 0
    end
end



function sim_rudder_trim_right_beforeCMDhandler(phase, duration) end

function sim_rudder_trim_right_afterCMDhandler(phase, duration)
    if phase == 0 then
        B747_rudder_trim_sel_dial_position_target = 1
    elseif phase == 2 then
        B747_rudder_trim_sel_dial_position_target = 0
    end
end





-- AILERON TRIM
function sim_aileron_trim_left_beforeCMDhandler(phase, duration) end

function sim_aileron_trim_left_afterCMDhandler(phase, duration)
    if phase == 0 then
        B747_aileron_trim_sel_dial_position_target = -1
    elseif phase == 2 then
        B747_aileron_trim_sel_dial_position_target = 0
    end
end



function sim_aileron_trim_right_beforeCMDhandler(phase, duration) end

function sim_aileron_trim_right_afterCMDhandler(phase, duration)
    if phase == 0 then
        B747_aileron_trim_sel_dial_position_target = 1
    elseif phase == 2 then
        B747_aileron_trim_sel_dial_position_target = 0
    end
end




function sim_yaw_damper_on_beforeCMDhandler(phase, duration) end
function sim_yaw_damper_on_afterCMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_button_switch_position[82] <= 0.05 then
            B747CMD_yaw_damper_upr:once()
            B747CMD_yaw_damper_lwr:once()
        end
    end
end

function sim_yaw_damper_off_beforeCMDhandler(phase, duration) end
function sim_yaw_damper_off_afterCMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_button_switch_position[82] >= 0.95 then
            B747CMD_yaw_damper_upr:once()
            B747CMD_yaw_damper_lwr:once()
        end
    end
end






-- SPEEDBRAKE LEVER
function sim_speedbrake_lever_extend_one_CMDhandler(phase, duration)
    if phase == 0 then

	    -- MOVE FROM DOWN TO ARM
		if B747DR_speedbrake_lever < 0.10 then
	   		B747DR_speedbrake_lever = 0.125
	    
	    -- MOVE FROM ARM TO FLIGHT DETENT
	    elseif B747DR_speedbrake_lever > 0.10 and B747DR_speedbrake_lever < 0.15 then
		    B747DR_speedbrake_lever = 0.53
	    
	    -- MOVE FROM FLIGHT DETENT TO UP
	    elseif B747DR_speedbrake_lever > 0.525 and B747DR_speedbrake_lever < 1.0 then
	    	B747DR_speedbrake_lever = 1.0
	    end
	    
	    B747_speedbrake_lever_DRhandler()

    end
end

function sim_speedbrake_lever_retract_one_CMDhandler(phase, duration)
    if phase == 0 then
	    
	    -- MOVE FROM UP TO FLIGHT DETENT
		if B747DR_speedbrake_lever > 0.53 then
	   		B747DR_speedbrake_lever = 0.53
	    
	    -- MOVE FROM FLIGHT DETENT TO ARM 
	    elseif B747DR_speedbrake_lever > 0.15 and B747DR_speedbrake_lever <= 0.53 then
		    B747DR_speedbrake_lever = 0.125
	    
	    -- MOVE FROM ARM DETENT TO DOWN
	    elseif B747DR_speedbrake_lever > 0.10 and B747DR_speedbrake_lever < 0.15 then
	    	B747DR_speedbrake_lever = 0.0
	    end
	    
	    B747_speedbrake_lever_DRhandler()
	    
    end
end




function sim_speedbrake_lever_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_speedbrake_lever = 1.0
        B747_speedbrake_lever_DRhandler()
    end
end

function sim_speedbrake_lever_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_speedbrake_lever = 0.0
        B747_speedbrake_lever_DRhandler()
    end
end




function sim_toggle_speedbrakes_CMDhandler(phase, duration)
	if phase == 0 then
		if B747DR_speedbrake_lever < 0.01 then 
			B747DR_speedbrake_lever = 1.0
		else		
	    	B747DR_speedbrake_lever = 0.0
	    end	
	    B747_speedbrake_lever_DRhandler()
	end    
end








--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

-- RUDDER TRIM
simCMD_rudder_trim_left         = wrap_command("sim/flight_controls/rudder_trim_left", sim_rudder_trim_left_beforeCMDhandler, sim_rudder_trim_left_afterCMDhandler)
simCMD_rudder_trim_right        = wrap_command("sim/flight_controls/rudder_trim_right", sim_rudder_trim_right_beforeCMDhandler, sim_rudder_trim_right_afterCMDhandler)



-- AILERON TRIM
simCMD_aileron_trim_left        = wrap_command("sim/flight_controls/aileron_trim_left", sim_aileron_trim_left_beforeCMDhandler, sim_aileron_trim_left_afterCMDhandler)
simCMD_aileron_trim_right       = wrap_command("sim/flight_controls/aileron_trim_right", sim_aileron_trim_right_beforeCMDhandler, sim_aileron_trim_right_afterCMDhandler)


-- STABILIZER TRIM
simCMD_stablizer_trim_up        = find_command("sim/flight_controls/pitch_trim_up")
simCMD_stablizer_trim_dn        = find_command("sim/flight_controls/pitch_trim_down")



-- YAW DAMPER
simCMD_yaw_damper_on            = wrap_command("sim/systems/yaw_damper_on", sim_yaw_damper_on_beforeCMDhandler, sim_yaw_damper_on_afterCMDhandler)
simCMD_yaw_damper_off           = wrap_command("sim/systems/yaw_damper_off", sim_yaw_damper_off_beforeCMDhandler, sim_yaw_damper_off_afterCMDhandler)




-- SPEEDBRAKES
simCMD_speedbrakes_extend_one   = replace_command("sim/flight_controls/speed_brakes_down_one", sim_speedbrake_lever_extend_one_CMDhandler)
simCMD_speedbrakes_retract_one  = replace_command("sim/flight_controls/speed_brakes_up_one", sim_speedbrake_lever_retract_one_CMDhandler)
simCMD_speedbrakes_extend_full  = replace_command("sim/flight_controls/speed_brakes_down_all", sim_speedbrake_lever_up_CMDhandler)
simCMD_speedbrakes_retract_full = replace_command("sim/flight_controls/speed_brakes_up_all", sim_speedbrake_lever_dn_CMDhandler)
simCMD_speedbrakes_toggle       = replace_command("sim/flight_controls/speed_brakes_toggle", sim_toggle_speedbrakes_CMDhandler)










--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- ALTERNATE FLAPS
B747CMD_alt_flaps_sel_dial_up           = deferred_command("laminar/B747/flt_ctrls/flaps/alt_flaps/sel_dial_up", "Alternate Flaps Selector Dial Up", B747_alt_flaps_sel_dial_up_CMDhandler)
B747CMD_alt_flaps_sel_dial_dn           = deferred_command("laminar/B747/flt_ctrls/flaps/alt_flaps/sel_dial_dn", "Alternate Flaps Selector Dial Down", B747_alt_flaps_sel_dial_dn_CMDhandler)


-- STABLIZER TRIM
B747CMD_stablizer_trim_up_capt          = deferred_command("laminar/B747/flt_ctrls/stab_trim_up_capt", "Stablizer Trim Up Captain", B747_stablizer_trim_up_capt_CMDhandler)
B747CMD_stablizer_trim_dn_capt          = deferred_command("laminar/B747/flt_ctrls/stab_trim_dn_capt", "Stablizer Trim Down Captain", B747_stablizer_trim_dn_capt_CMDhandler)

B747CMD_stablizer_trim_up_fo            = deferred_command("laminar/B747/flt_ctrls/stab_trim_up_fo", "Stablizer Trim Up First Officer", B747_stablizer_trim_up_fo_CMDhandler)
B747CMD_stablizer_trim_dn_fo            = deferred_command("laminar/B747/flt_ctrls/stab_trim_dn_fo", "Stablizer Trim Down First Officer", B747_stablizer_trim_dn_fo_CMDhandler)


-- AI
B747CMD_ai_fltctrls_quick_start			= deferred_command("laminar/B747/ai/fltctrls_quick_start", "number", B747_ai_fltctrls_quick_start_CMDhandler)



function B747CMD_parking_brake_on_CMDhandler(phase, duration)
	if phase == 0 then
	  B747DR_parking_brake_ratio=1.0
	end    
end
function B747CMD_parking_brake_off_CMDhandler(phase, duration)
	if phase == 0 then
	  B747DR_parking_brake_ratio=0.0
	end    
end
function B747CMD_parking_brake_toggle_CMDhandler(phase, duration)
	if phase == 0 then
	  B747DR_parking_brake_ratio=1.0-B747DR_parking_brake_ratio
	end    
end
B747CMD_parking_brake_on            = deferred_command("laminar/B747/flt_ctrls/parking_brake_on", "Parking brake on", B747CMD_parking_brake_on_CMDhandler)
B747CMD_parking_brake_off            = deferred_command("laminar/B747/flt_ctrls/parking_brake_off", "Parking brake off", B747CMD_parking_brake_off_CMDhandler)
B747CMD_parking_brake_toggle            = deferred_command("laminar/B747/flt_ctrls/parking_brake_toggle", "Parking brake toggle", B747CMD_parking_brake_toggle_CMDhandler)


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

    local fps_factor = math.min(0.1, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end





----- RESCALE FLOAT AND CLAMP TO OUTER LIMITS -------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end





----- RUDDER TRIM DIAL POSITION ANIMATION --------------------------------------------
function B747_rudder_trim_dial_animation()

    B747DR_rudder_trim_sel_dial_pos = B747_set_animation_position(B747DR_rudder_trim_sel_dial_pos, B747_rudder_trim_sel_dial_position_target, -1.0, 1.0, 10.0)

end




----- AILERON TRIM SWITCH POSITION ANIMATION --------------------------------------------
function B747_aileron_trim_switch_animation()

    B747DR_rudder_trim_switch_pos = B747_set_animation_position(B747DR_rudder_trim_switch_pos, B747_aileron_trim_sel_dial_position_target, -1.0, 1.0, 10.0)

end




--[[
----- SPEEDBRAKE LEVER POSITION ANIMATION -----------------------------------------------
function B747_speedbrake_lever_animation()

    B747DR_speedbrake_lever_pos = B747_set_animation_position(B747DR_speedbrake_lever_pos, B747_speedbrake_lever_pos_target, 0.0, 1.0, 10.0)

end--]]





----- SPEEDBRAKE LEVER STOP -------------------------------------------------------------
function B747_speedbrake_lever_stop()

    if simDR_all_wheels_on_ground < 1 and simDR_radarAlt1>15 then
        B747_speedbrake_stop = 1
        B747DR__gear_chocked=0
    else
		B747_speedbrake_stop = 0	        
    end

end






----- SPEEDBRAKES -----------------------------------------------------------------------
function B747_speedbrake_sync()

	if B747_last_sim_sb_handle_pos ~= simDR_speedbrake_ratio_control then					-- SIM DR HAS CHANGED
		if B747_sb_manip_changed == 0 then													-- THE CHANGE IN SIM DR VALUE WAS INITIATED BY THE SIM, NOT A COMMAND OR MANIP 
			if simDR_speedbrake_ratio_control == -0.5 then
				B747DR_speedbrake_lever = 0.125	
			elseif simDR_speedbrake_ratio_control > -0.5 and simDR_speedbrake_ratio_control <= 0.0 then	
				B747DR_speedbrake_lever = 0.0
			else
				if B747_speedbrake_stop == 0 then											-- ON GROUND
					B747DR_speedbrake_lever = B747_rescale(0.0, 0.15, 1.0, 1.0, simDR_speedbrake_ratio_control)
				elseif B747_speedbrake_stop == 1 then										-- IN FLIGHT
					B747DR_speedbrake_lever = B747_rescale(0.0, 0.15, 1.0, 0.53, simDR_speedbrake_ratio_control)	
				end		
			end	
	
			B747_last_sim_sb_handle_pos = simDR_speedbrake_ratio_control
			
		end		
		
	end			
	
end	





----- YAW DAMPER ------------------------------------------------------------------------
function B747_yaw_damper()

    if (B747DR_button_switch_position[82] > 0.95 or
        B747DR_button_switch_position[83] > 0.95)
        and
        simDR_yaw_damper_on == 0
        and
        (B747DR_IRS_dial_pos[0] == 2 or                 -- make sure at leaset 1 IRU is in NAV position  (crazytimtimtim)
        B747DR_IRS_dial_pos[1] == 2 or
        B747DR_IRS_dial_pos[2] == 2) and
        B747DR_ELEC_BATT[0] == 1
    then
        simCMD_yaw_damper_on:once()
    elseif
        B747DR_button_switch_position[82] < 0.05 and
        B747DR_button_switch_position[83] < 0.05 and
        simDR_yaw_damper_on == 1
    then
        simCMD_yaw_damper_off:once()
    end

    if  ((B747DR_IRS_dial_pos[0] ~= 2 and
        B747DR_IRS_dial_pos[1] ~= 2 and
        B747DR_IRS_dial_pos[2] ~= 2) or
        B747DR_ELEC_BATT[0] == 0) and
        simDR_yaw_damper_on == 1
    then
        simCMD_yaw_damper_off:once()                -- disable Yaw Damper if all IRS is not on (crazytimtimtim)
    end

end


function B747_flap_move_to_slot()
    
    
    if simDR_flap_ratio_control<=0.0835 then --flaps 0
	    simDR_flap_ratio_control=0
    elseif simDR_flap_ratio_control<=0.25 then --flaps 5 
	    simDR_flap_ratio_control= 0.167
    elseif simDR_flap_ratio_control<=0.4165 then --flaps 10
	    simDR_flap_ratio_control= 0.333
    elseif simDR_flap_ratio_control<=0.5835 then --flaps 20
	    simDR_flap_ratio_control= 0.5
    elseif simDR_flap_ratio_control<=0.7505 then --flaps 25
	    simDR_flap_ratio_control= 0.667
    elseif simDR_flap_ratio_control<=0.9165 then --flaps 30
	    simDR_flap_ratio_control= 0.833
    else
	    simDR_flap_ratio_control = 1.0
    end

end

function FlapinSlot()
  if simDR_flap_ratio_control<0.001 then --flaps 0

	   return true
    elseif simDR_flap_ratio_control>0.166 and simDR_flap_ratio_control<0.168 then --flaps 1 

      simDR_flap_ratio_control= 0.167
	    return true
    elseif simDR_flap_ratio_control>0.332 and simDR_flap_ratio_control<0.334 then --flaps 5
      simDR_flap_ratio_control= 0.333

	    return true
    elseif simDR_flap_ratio_control>0.499 and simDR_flap_ratio_control<0.501 then --flaps 10
      simDR_flap_ratio_control= 0.5

	    return true
    elseif simDR_flap_ratio_control>0.666 and simDR_flap_ratio_control<0.668 then --flaps 20
     simDR_flap_ratio_control= 0.667

	    return true
    elseif simDR_flap_ratio_control>0.832 and simDR_flap_ratio_control<0.834 then --flaps 25
      simDR_flap_ratio_control= 0.833

	   return true
    elseif simDR_flap_ratio_control>0.999 then --flaps 30
      simDR_flap_ratio_control = 1.0

	   return true
    end
    --print("flap not in slot")
    return false
end
local last_flap_handle=-1
----- FLAP INDICATOR STATUS -------------------------------------------------------------
function B747_flap_transition_status()
    if last_flap_handle~=simDR_flap_ratio_control then
      if is_timer_scheduled(B747_flap_move_to_slot) == false then
	      stop_timer(B747_flap_move_to_slot)    
      end
      run_after_time(B747_flap_move_to_slot, 2.0)
    end
    
    last_flap_handle=simDR_flap_ratio_control
    if FlapinSlot()==false then 
      B747DR_flap_lever_detent = 0.006 
    else
      --print("flap in slot")
       B747DR_flap_lever_detent = 0.0
    end
    if math.abs(simDR_flap_handle_deploy_ratio - simDR_flap_ratio_control) > 0.01 then
        B747DR_flap_trans_status = 1
	
    else
	
        B747DR_flap_trans_status = 0
    end
    
end
local slatsRetract=false

function B747_landing_slats()
   if simDR_flap_ratio_control==0 and simDR_innerslats_ratio==0 and simDR_outerslats_ratio==0 then
        simDR_autoslats_ratio=0
   elseif (B747DR_speedbrake_lever >0.5 and (simDR_prop_mode[0] == 3 or simDR_prop_mode[1] == 3 or simDR_prop_mode[2] == 3 or simDR_prop_mode[3] == 3)) 
       or (slatsRetract==true and B747DR_speedbrake_lever >0.5) then	
     simDR_innerslats_ratio = B747_set_animation_position(simDR_innerslats_ratio, 0.0, 0.0, 1.0, 0.5)
     simDR_autoslats_ratio=0
     slatsRetract=true
   elseif B747DR_speedbrake_lever <0.5 then 
     slatsRetract=false
     if simDR_flap_ratio_control>0 and simDR_autoslats_ratio==0 then
	simDR_innerslats_ratio = B747_set_animation_position(simDR_innerslats_ratio, 1.0, 0.0, 1.0, 0.5)
	if simDR_innerslats_ratio==1 then simDR_autoslats_ratio=1 end
     else 
       simDR_autoslats_ratio=1
     end

    else 
        simDR_autoslats_ratio=1 
   end
  
end


----- PRIMARY EICAS FLAP DISPLAY STATUS -------------------------------------------------
function B747_flap_display_shutoff()
    B747DR_EICAS1_flap_display_status = 0
end

function B747_primary_EICAS_flap_display()

    if simDR_flap_deploy_ratio == 0 then
        if B747DR_EICAS1_flap_display_status == 1 then
            if is_timer_scheduled(B747_flap_display_shutoff) == false then
                run_after_time(B747_flap_display_shutoff, 10.0)
            end
        end
    else
         if is_timer_scheduled(B747_flap_display_shutoff) == true then
            stop_timer(B747_flap_display_shutoff)
        end
        B747DR_EICAS1_flap_display_status = 1
    end

end




----- ELEVATOR TRIM ---------------------------------------------------------------------
function B747_elevator_trim()
	--B747DR_elevator_trim_mid_ind = B747_rescale(200000, 0.0, 400000, 1.0, simDR_acf_weight_total_kg)
	
	--Marauder28
	--Use the calculated Stab Trim (adjusted) in the FMC to determine the Green Band range
	B747DR_elevator_trim_mid_ind = B747_rescale(0.0, 0.0, 4.5, 1.0, B747DR_elevator_trim - 3.75)
	--print("Stab Trim = "..B747DR_elevator_trim)
	--print("Trim Mid Ind = "..B747DR_elevator_trim_mid_ind)
	--Marauder28
end






----- EICAS MESSAGES --------------------------------------------------------------------
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
function B747_speedbrake_warn()
    --if math.abs(B747DR_efis_baro_capt_set_dial_pos - B747DR_efis_baro_fo_set_dial_pos) > 0.01 then
  --print("do warning speedbrake"..simDR_engine_N1_pct[1].." "..simDR_engine_N1_pct[2]) 
  local numClimb=0;
    if simDR_engine_N1_pct[0]>90.0 then numClimb=numClimb+1 end
    if simDR_engine_N1_pct[1]>90.0 then numClimb=numClimb+1 end
    if simDR_engine_N1_pct[2]>90.0 then numClimb=numClimb+1 end
    if simDR_engine_N1_pct[3]>90.0 then numClimb=numClimb+1 end
  if B747DR_speedbrake_lever >0.125 
  and simDR_all_wheels_on_ground == 0 
        and numClimb>=2 then  
        B747DR_CAS_warning_status[6] = 1
    end
    
end
local last_simDR_Brake=simDR_parking_brake_ratio
local last_B747DR_Brake=B747DR_parking_brake_ratio

function B747_fltCtrols_EICAS_msg()
    
    -- FUEL CONTROL SWITCH STATUS
    local num_fuel_ctrl_sw_on = 0
    for i = 0, 3 do
        if B747DR_fuel_control_toggle_switch_pos[i] > 0.95 then
            num_fuel_ctrl_sw_on = num_fuel_ctrl_sw_on + 1
        end
    end

    -- THRUST LEVER CLOSED
    local any_thrust_lever_closed = 0
    if simDR_engine_throttle_jet_all < 0.05 
        and simDR_engine_throttle_jet_all > -0.01
    then
        any_thrust_lever_closed = 1
    end

    -- THRUST LEVERS OPEN
    local num_thrust_levers_open = 0
    if simDR_engine_throttle_jet_all >= 0.05 then
        num_thrust_levers_open = num_thrust_levers_open + 1
    end

    -- >CONFIG FLAPS
    local thRef=96
    local unmatchedConfig=false
    if B747DR_airspeed_flapsRef>0 then
        if simDR_wing_flap1_deg[0]>B747DR_airspeed_flapsRef+0.05 or simDR_wing_flap1_deg[0]<B747DR_airspeed_flapsRef-0.05 then
            unmatchedConfig=true
        end
        thRef=86
    end

    if (simDR_wing_flap1_deg[0] < 9.95 or simDR_wing_flap1_deg[0] > 20.05 or unmatchedConfig==true)
        and simDR_all_wheels_on_ground == 1
        and simDR_ind_airspeed_kts_pilot < B747DR_airspeed_V1
        and num_fuel_ctrl_sw_on >= 3
        and simDR_engine_N1_pct[1] > thRef and simDR_engine_N1_pct[2] > thRef
    then
        B747DR_CAS_warning_status[2] = 1
    else
	B747DR_CAS_warning_status[2] = 0
    end

    -- >CONFIG GEAR
    
    if ((simDR_gear_deploy_ratio[0] < 0.99
        or simDR_gear_deploy_ratio[1] < 0.99
        or simDR_gear_deploy_ratio[2] < 0.99
        or simDR_gear_deploy_ratio[3] < 0.99
        or simDR_gear_deploy_ratio[4] < 0.99)

        and

        ((simDR_radio_alt_height_capt < 800.0 and any_thrust_lever_closed == 1)
        or
        simDR_wing_flap1_deg[0] > 24.95))

    then
        B747DR_CAS_warning_status[3] = 1
    else
	B747DR_CAS_warning_status[3] = 0
    end

    -- >CONFIG PARK BRK
    if B747DR__gear_chocked==1 then
      simDR_parking_brake_ratio = 1.0
      last_B747DR_Brake = 1.0
    elseif simDR_hyd_press_1_2 < 1000 and simDR_parking_brake_ratio > 0 then
      simDR_parking_brake_ratio = B747_animate_value(simDR_parking_brake_ratio,0,0,1,1)
    else
      if B747DR_parking_brake_ratio~=last_B747DR_Brake then --manually changed
	    simDR_parking_brake_ratio = B747DR_parking_brake_ratio
      --elseif simDR_parking_brake_ratio~=last_simDR_Brake then --sim changed
	--  B747DR_parking_brake_ratio = simDR_parking_brake_ratio
      end
      last_simDR_Brake=simDR_parking_brake_ratio
      last_B747DR_Brake=B747DR_parking_brake_ratio
    end
    if simDR_parking_brake_ratio==0 and B747DR_parking_brake_ratio>0 then
        B747DR_parking_brake_ratio=B747_animate_value(B747DR_parking_brake_ratio,0,0,1,3)
        last_simDR_Brake=simDR_parking_brake_ratio
        last_B747DR_Brake=B747DR_parking_brake_ratio
    end
    local numClimb=0;
    if simDR_engine_N1_pct[0]>90.0 then numClimb=numClimb+1 end
    if simDR_engine_N1_pct[1]>90.0 then numClimb=numClimb+1 end
    if simDR_engine_N1_pct[2]>90.0 then numClimb=numClimb+1 end
    if simDR_engine_N1_pct[3]>90.0 then numClimb=numClimb+1 end
    
    if simDR_parking_brake_ratio > 0.99
        and simDR_ind_airspeed_kts_pilot < B747DR_airspeed_V1
        and num_fuel_ctrl_sw_on >= 3
        and simDR_engine_N1_pct[1] > 90.0
        and simDR_engine_N1_pct[2] > 90.0
	    and simDR_all_wheels_on_ground == 1
    then
        B747DR_CAS_warning_status[5] = 1
    else
	    B747DR_CAS_warning_status[5] = 0
    end

    -- >CONFIG SPOILERS

    local numLeverClimb = 0;
    if B747DR_engines_throttle_ind[0] > 0.9 then numLeverClimb = numLeverClimb + 1 end
    if B747DR_engines_throttle_ind[1] > 0.9 then numLeverClimb = numLeverClimb + 1 end
    if B747DR_engines_throttle_ind[2] > 0.9 then numLeverClimb = numLeverClimb + 1 end
    if B747DR_engines_throttle_ind[3] > 0.9 then numLeverClimb = numLeverClimb + 1 end

    if B747DR_speedbrake_lever >0.01 --< 0.99
        and simDR_all_wheels_on_ground == 1
        and simDR_ind_airspeed_kts_pilot < B747DR_airspeed_V1
        and num_fuel_ctrl_sw_on >= 3
        and simDR_engine_N1_pct[1] > 90.0
        and simDR_engine_N1_pct[2] > 90.0
    then
        B747DR_CAS_warning_status[6] = 1
    elseif B747DR_speedbrake_lever >0.125 
        and simDR_all_wheels_on_ground == 0  
        and num_fuel_ctrl_sw_on >= 3
        and numLeverClimb>=2
	and is_timer_scheduled(B747_speedbrake_warn) == false then
	--print("warning speedbrake")  
        run_after_time(B747_speedbrake_warn, 1.0)
    elseif is_timer_scheduled(B747_speedbrake_warn) == false or numClimb<=1 then 
        B747DR_CAS_warning_status[6] = 0
    end

    -- >CONFIG STAB
    --local midIndTop = B747_rescale(0.0, 1.5, 1.0, 6.0, B747DR_elevator_trim_mid_ind)
    --local midIndBtm = midIndTop + 4.5
	
	--Marauder28
	--Make the top & bottom of the band a range of 4.5 units from the Stab Trim calculation
	local midIndTop = B747DR_elevator_trim - 2.25
	local midIndBtm = B747DR_elevator_trim + 2.25
	if midIndTop < 0 then
		midIndTop = 0
		midIndBtm = 4.5
	end
	--Marauder28
	
    --local curTrim   = B747_rescale(-1.0, 15, 1.0, 0.0, simDR_elevator_trim)
	local curTrim   = B747_rescale(-1.0, 0.0, 1.0, 15.0, simDR_elevator_trim)  --Swapped top and bottom of range for better comparisons
	--print("midIndTop = "..midIndTop)
	--print("midIndBtm = "..midIndBtm)
	--print("curTrim = "..curTrim)
    if (curTrim < midIndTop or curTrim > midIndBtm)              -- TODO:  VERIFY RANGE VALUES
        and simDR_all_wheels_on_ground == 1
        and simDR_ind_airspeed_kts_pilot < B747DR_airspeed_V1
        and num_fuel_ctrl_sw_on >= 3
        and simDR_engine_N1_pct[1] > 90.0
        and simDR_engine_N1_pct[2] > 90.0
    then
        B747DR_CAS_warning_status[7] = 1
    else
       B747DR_CAS_warning_status[7] = 0
    end

    -- FLAPS CONTROL
    
    if simDR_flap_control_fail == 6
        or B747DR_button_switch_position[0] > 0.95
    then
        B747DR_CAS_caution_status[28] = 1
    else
       B747DR_CAS_caution_status[28] = 0
    end

    -- >SPEEDBRAKES EXT
    
    if simDR_speedbrake_ratio_control > 0.15
        and 
        ((simDR_radio_alt_height_capt > 15.0 and simDR_radio_alt_height_capt < 800.0)
        or
        (simDR_wing_flap1_deg[0] > 24.0 and simDR_wing_flap1_deg[0] < 31.0)
        and
        num_thrust_levers_open >= 1)
    then
        B747DR_CAS_caution_status[59] = 1
    else
      B747DR_CAS_caution_status[59] = 0
    end

    -- >YAW DAMPER LWR
    
    if B747DR_button_switch_position[82] < 0.05 then 
      B747DR_CAS_advisory_status[300] = 1
    else
      B747DR_CAS_advisory_status[300] = 0
    end

    -- >YAW DAMPER UPR
    
    if B747DR_button_switch_position[83] < 0.05 then 
      B747DR_CAS_advisory_status[301] = 1 
    else
      B747DR_CAS_advisory_status[301] = 0
    end

end

-- crazytimmtimtim
function B747_autobrake_resetOnGround() -- reset autobrakes if armed while on ground
     B747DR_autobrakes_sel_dial_pos = 2 -- disarm
end








----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_fltctrls_monitor_AI()

    if B747DR_init_fltctrls_CD == 1 then
        B747_set_fltctrls_all_modes()
        B747_set_fltctrls_CD()
        B747DR_init_fltctrls_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_fltctrls_all_modes()
	
	B747DR_init_fltctrls_CD = 0
	run_after_time(B747_flight_start_deferred, 2.0)
	

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_fltctrls_CD()

    --B747DR_speedbrake_lever = 1.0
    --B747_speedbrake_lever_DRhandler()


    simDR_elevator_trim = 0

end




----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_fltctrls_ER()
  if simDR_all_wheels_on_ground == 1 then
	B747DR_parking_brake_ratio=1
  end
	
end







----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_fltCtrls()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_fltctrls_all_modes()
	

    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_fltctrls_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then
	    
		B747_set_fltctrls_ER()

    end

end





----- DEFERRED INIT ---------------------------------------------------------------------
function B747_flight_start_deferred()

    --B747_init_gear_check_flag()                                                             -- REQUIRED BECAUSE "sim/flightmodel/failures/onground_all" IS NOT VALID AT LOAD
    --B747_elevator_trim()  --moved to after_physics loop
    B747_last_sim_sb_handle_pos = simDR_speedbrake_ratio_control
    
end





--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start()

    B747_flight_start_fltCtrls()

end

--function flight_crash() end

--function before_physics() end
debug_fltctrls     = deferred_dataref("laminar/B747/debug/fltctrls", "number")
function after_physics()
if debug_fltctrls>0 then return end
    B747_rudder_trim_dial_animation()
    B747_aileron_trim_switch_animation()

    B747_speedbrake_lever_stop()
    B747_speedbrake_sync()
    --B747_speedbrake_lever_animation()
    --B747_speedbrake()

    B747_yaw_damper()

    B747_flap_transition_status()
    B747_primary_EICAS_flap_display()

    B747_fltCtrols_EICAS_msg()

    B747_fltctrls_monitor_AI()
    B747_landing_slats()
	
    --print(collectgarbage("count")*1024)
	
    --Marauder28
    B747_elevator_trim()  --constantly update the safe stab trim position based on CG   
	
    -- crazytimtimtim
    if B747DR_autobrakes_sel_dial_pos > 2 -- Autobrakes armed
       and simDR_all_wheels_on_ground == 1
       and simDR_engine_throttle_jet_all >= 0 -- reversers aren't deployed, indicating a landing
       and simDR_speedbrake_ratio_control < 0.3 -- spoilers aren't deployed, indicating a landing
       and simDR_ind_airspeed_kts_pilot <= 30 
       and is_timer_scheduled(B747_autobrake_resetOnGround) == false
       then
       run_after_time(B747_autobrake_resetOnGround, 1.0)
    end
	
end

--function after_replay() end



