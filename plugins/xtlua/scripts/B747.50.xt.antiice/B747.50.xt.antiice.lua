--[[
*****************************************************************************************
* Program Script Name	:	B747.50.antiice
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
local B747DR_nacelle_ai_valve_target_pos = {}
for i = 0, 3 do
    B747DR_nacelle_ai_valve_target_pos[i] = 0
end

local B747DR_wing_ai_valve_target_pos = {}
for i = 0, 1 do
    B747DR_wing_ai_valve_target_pos[i] = 0
end


--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")
simDR_engine_nacelle_heat_on        = find_dataref("sim/cockpit2/ice/ice_inlet_heat_on_per_engine")
simDR_wing_heat_on                  = find_dataref("sim/cockpit2/ice/ice_surfce_heat_on")
simDR_wing_heat_on_L                = find_dataref("sim/cockpit2/ice/ice_surfce_heat_left_on")
simDR_wing_heat_on_R                = find_dataref("sim/cockpit2/ice/ice_surfce_heat_right_on")
simDR_window_heat_on                = find_dataref("sim/cockpit2/ice/ice_window_heat_on")
simDR_windshield_wiper_speed        = find_dataref("sim/cockpit2/switches/wiper_speed")
simDR_flap_deploy_ratio             = find_dataref("sim/flightmodel2/controls/flap_handle_deploy_ratio")
simDR_all_wheels_on_ground          = find_dataref("sim/flightmodel/failures/onground_any")
simDR_ice_detected                  = find_dataref("sim/cockpit2/annunciators/ice")
simDR_OAT_degc                      = find_dataref("sim/cockpit2/temperature/outside_air_temp_degc")
simDR_AOA_heat_fail_L               = find_dataref("sim/flightmodel/failures/aoa_ice")
simDR_AOA_heat_fail_R               = find_dataref("sim/flightmodel/failures/aoa_ice2")
simDR_pitot_heat_fail_capt          = find_dataref("sim/operation/failures/rel_ice_pitot_heat1")
simDR_pitot_heat_fail_fo            = find_dataref("sim/operation/failures/rel_ice_pitot_heat2")
simDR_static_heat_fail_capt         = find_dataref("sim/operation/failures/rel_ice_static_heat")
simDR_static_heat_fail_fo           = find_dataref("sim/operation/failures/rel_ice_static_heat2")





--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_button_switch_position       = find_dataref("laminar/B747/button_switch/position")

B747DR_engine1_bleed_air_psi        = find_dataref("laminar/B747/air/engine1/bleed_air_psi")
B747DR_engine2_bleed_air_psi        = find_dataref("laminar/B747/air/engine2/bleed_air_psi")
B747DR_engine3_bleed_air_psi        = find_dataref("laminar/B747/air/engine3/bleed_air_psi")
B747DR_engine4_bleed_air_psi        = find_dataref("laminar/B747/air/engine4/bleed_air_psi")

B747DR_engine1_bleed_air_start_valve_pos  = find_dataref("laminar/B747/air/engine1/bleed_start_valve_pos")
B747DR_engine2_bleed_air_start_valve_pos  = find_dataref("laminar/B747/air/engine2/bleed_start_valve_pos")
B747DR_engine3_bleed_air_start_valve_pos  = find_dataref("laminar/B747/air/engine3/bleed_start_valve_pos")
B747DR_engine4_bleed_air_start_valve_pos  = find_dataref("laminar/B747/air/engine4/bleed_start_valve_pos")

B747DR_duct_pressure_L              = find_dataref("laminar/B747/air/duct_pressure_L")
B747DR_duct_pressure_C              = find_dataref("laminar/B747/air/duct_pressure_C")
B747DR_duct_pressure_R              = find_dataref("laminar/B747/air/duct_pressure_R")

B747DR_CAS_warning_status           = find_dataref("laminar/B747/CAS/warning_status")
B747DR_CAS_caution_status           = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status          = find_dataref("laminar/B747/CAS/advisory_status")



--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_windshield_wiper_sel_L_pos   = deferred_dataref("laminar/B747/antiice/wndshlsd_wiper_L/sel_dial_pos", "number")
B747DR_windshield_wiper_sel_R_pos   = deferred_dataref("laminar/B747/antiice/wndshlsd_wiper_R/sel_dial_pos", "number")

B747DR_nacelle_ai_valve_pos         = deferred_dataref("laminar/B747/antiice/nacelle/valve_pos", "array[4)")
B747DR_wing_ai_valve_pos            = deferred_dataref("laminar/B747/antiice/wing/valve_pos", "array[2)")

B747DR_init_ice_CD                  = deferred_dataref("laminar/B747/ice/init_CD", "number")



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

simCMD_ice_inlet_heat_on_engine01       = find_command("sim/ice/inlet_heat0_on")
simCMD_ice_inlet_heat_off_engine01      = find_command("sim/ice/inlet_heat0_off")
simCMD_ice_inlet_heat_on_engine02       = find_command("sim/ice/inlet_heat1_on")
simCMD_ice_inlet_heat_off_engine02      = find_command("sim/ice/inlet_heat1_off")
simCMD_ice_inlet_heat_on_engine03       = find_command("sim/ice/inlet_heat2_on")
simCMD_ice_inlet_heat_off_engine03      = find_command("sim/ice/inlet_heat2_off")
simCMD_ice_inlet_heat_on_engine04       = find_command("sim/ice/inlet_heat3_on")
simCMD_ice_inlet_heat_off_engine04      = find_command("sim/ice/inlet_heat3_off")

simCMD_ice_wing_heat_on                 = find_command("sim/ice/wing_heat_on")
simCMD_ice_wing_heat_off                = find_command("sim/ice/wing_heat_off")

simCMD_ice_window_heat_on               = find_command("sim/ice/window_heat_on")
simCMD_ice_window_heat_off              = find_command("sim/ice/window_heat_off")

simCMD_ice_detect_on                    = find_command("sim/ice/detect_on")





--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- WINDSHIELD WIPERS
function B747_set_sim_wiper_speed()
    local wwSpeed = math.max(B747DR_windshield_wiper_sel_L_pos, B747DR_windshield_wiper_sel_R_pos)
    simDR_windshield_wiper_speed = wwSpeed
end

function B747_windshield_wiper_sel_L_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_windshield_wiper_sel_L_pos = math.min(B747DR_windshield_wiper_sel_L_pos+1, 2)
        B747_set_sim_wiper_speed()
    end
end
function B747_windshield_wiper_sel_L_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_windshield_wiper_sel_L_pos = math.max(B747DR_windshield_wiper_sel_L_pos-1, 0)
        B747_set_sim_wiper_speed()
    end
end

function B747_windshield_wiper_sel_R_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_windshield_wiper_sel_R_pos = math.min(B747DR_windshield_wiper_sel_R_pos+1, 2)
        B747_set_sim_wiper_speed()
    end
end
function B747_windshield_wiper_sel_R_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_windshield_wiper_sel_R_pos = math.max(B747DR_windshield_wiper_sel_R_pos-1, 0)
        B747_set_sim_wiper_speed()
    end
end




function B747_ai_antiice_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
	 	B747_set_ice_all_modes()
	 	B747_set_ice_CD()
	 	B747_set_ice_ER()  
	end    	
end	





--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- WINDSHIELD WIPERS
B747CMD_windshield_wiper_sel_L_up 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_L/sel_dial_up", "Windshield Wiper Selector Dial Left Up", B747_windshield_wiper_sel_L_up_CMDhandler)
B747CMD_windshield_wiper_sel_L_dn 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_L/sel_dial_dn", "Windshield Wiper Selector Dial Left Down", B747_windshield_wiper_sel_L_dn_CMDhandler)

B747CMD_windshield_wiper_sel_R_up 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_R/sel_dial_up", "Windshield Wiper Selector Dial Right Up", B747_windshield_wiper_sel_R_up_CMDhandler)
B747CMD_windshield_wiper_sel_R_dn 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_R/sel_dial_dn", "Windshield Wiper Selector Dial Right Down", B747_windshield_wiper_sel_R_dn_CMDhandler)


-- AI
B747CMD_ai_antiice_quick_start			= deferred_command("laminar/B747/ai/antiice_quick_start", "number", B747_ai_antiice_quick_start_CMDhandler)



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
function B747_set_anim_value(current_value, target, min, max, speed)

    local fps_factor = math.min(1.0, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end




----- NACELLE ANTI-ICE VALVES------------------------------------------------------------
function B747_nacelle_antiice()

    ----- OPEN/CLOSE THE VALVES ---------------------------------------------------------

    -- ENGINE #1
    B747DR_nacelle_ai_valve_target_pos[0] = 0.0
    if B747DR_button_switch_position[68] >= 0.95
        and B747DR_engine1_bleed_air_psi > 12.0
        and B747DR_engine1_bleed_air_start_valve_pos < 0.01
    then
        B747DR_nacelle_ai_valve_target_pos[0] = 1.0
    end

    -- ENGINE #2
    B747DR_nacelle_ai_valve_target_pos[1] = 0.0
    if B747DR_button_switch_position[69] >= 0.95
        and B747DR_engine2_bleed_air_psi > 12.0
        and B747DR_engine2_bleed_air_start_valve_pos < 0.01
    then
        B747DR_nacelle_ai_valve_target_pos[1] = 1.0
    end

     -- ENGINE #3
    B747DR_nacelle_ai_valve_target_pos[2] = 0.0
    if B747DR_button_switch_position[70] >= 0.95
        and B747DR_engine3_bleed_air_psi > 12.0
        and B747DR_engine3_bleed_air_start_valve_pos < 0.01
    then
        B747DR_nacelle_ai_valve_target_pos[2] = 1.0
    end

     -- ENGINE #4
    B747DR_nacelle_ai_valve_target_pos[3] = 0.0
    if B747DR_button_switch_position[71] >= 0.95
        and B747DR_engine4_bleed_air_psi > 12.0
        and B747DR_engine4_bleed_air_start_valve_pos < 0.01
    then
        B747DR_nacelle_ai_valve_target_pos[3] = 1.0
    end


    ----- SET THE VALVE ANIMATION POSITION -----------------------------------------------
    for i = 0, 3 do
        B747DR_nacelle_ai_valve_pos[i] = B747_set_anim_value(B747DR_nacelle_ai_valve_pos[i], B747DR_nacelle_ai_valve_target_pos[i], 0.0, 1.0, 20.0)
    end


    ----- SET THE X-PLANE ANTI-ICE STATUS -----------------------------------------------

    -- ENGINE #1
    if B747DR_nacelle_ai_valve_pos[0] > 0.5 then
        if simDR_engine_nacelle_heat_on[0] == 0 then simCMD_ice_inlet_heat_on_engine01:once() end
    elseif B747DR_nacelle_ai_valve_pos[0] < 0.5 then
        if simDR_engine_nacelle_heat_on[0] == 1 then simCMD_ice_inlet_heat_off_engine01:once() end
    end

    -- ENGINE #2
    if B747DR_nacelle_ai_valve_pos[1] > 0.5 then
        if simDR_engine_nacelle_heat_on[1] == 0 then simCMD_ice_inlet_heat_on_engine02:once() end
    elseif B747DR_nacelle_ai_valve_pos[1] < 0.5 then
        if simDR_engine_nacelle_heat_on[1] == 1 then simCMD_ice_inlet_heat_off_engine02:once() end
    end

    -- ENGINE #3
    if B747DR_nacelle_ai_valve_pos[2] > 0.5 then
        if simDR_engine_nacelle_heat_on[2] == 0 then simCMD_ice_inlet_heat_on_engine03:once() end
    elseif B747DR_nacelle_ai_valve_pos[2] < 0.5 then
        if simDR_engine_nacelle_heat_on[2] == 1 then simCMD_ice_inlet_heat_off_engine03:once() end
    end

    -- ENGINE #4
    if B747DR_nacelle_ai_valve_pos[3] > 0.5 then
        if simDR_engine_nacelle_heat_on[3] == 0 then simCMD_ice_inlet_heat_on_engine04:once() end
    elseif B747DR_nacelle_ai_valve_pos[3] < 0.5 then
        if simDR_engine_nacelle_heat_on[3] == 1 then simCMD_ice_inlet_heat_off_engine04:once() end
    end

end





----- WING ------------------------------------------------------------------------------
function B747_wing_antiice()

    ----- OPEN/CLOSE THE VALVES ---------------------------------------------------------

    -- LEFT WING
    B747DR_wing_ai_valve_target_pos[0] = 0.0
    if B747DR_button_switch_position[72] >= 0.95
        and simDR_all_wheels_on_ground == 0
        and B747DR_duct_pressure_L > 12.0
        and simDR_flap_deploy_ratio < 0.01
    then
        B747DR_wing_ai_valve_target_pos[0] = 1.0
    end


    -- RIGHT WING
    B747DR_wing_ai_valve_target_pos[1] = 0.0
    if B747DR_button_switch_position[72] >= 0.95
        and simDR_all_wheels_on_ground == 0
        and B747DR_duct_pressure_R > 12.0
        and simDR_flap_deploy_ratio < 0.01
    then
        B747DR_wing_ai_valve_target_pos[1] = 1.0
    end


    ----- SET THE VALVE ANIMATION POSITION -----------------------------------------------
    for i = 0, 1 do
        B747DR_wing_ai_valve_pos[i] = B747_set_anim_value(B747DR_wing_ai_valve_pos[i], B747DR_wing_ai_valve_target_pos[i], 0.0, 1.0, 20.0)
    end


    ----- SET THE X-PLANE ANTI-ICE STATUS -----------------------------------------------

    -- LEFT WING
    if B747DR_wing_ai_valve_pos[0] > 0.5 then
        if simDR_wing_heat_on_L == 0 then simCMD_ice_wing_heat_on:once() end
    elseif B747DR_wing_ai_valve_pos[0] < 0.5 then
        if simDR_wing_heat_on_L == 1 then simCMD_ice_wing_heat_off:once() end
    end


    -- RIGHT WING
    if B747DR_wing_ai_valve_pos[1] > 0.5 then
        if simDR_wing_heat_on_R == 0 then simCMD_ice_wing_heat_on:once() end
    elseif B747DR_wing_ai_valve_pos[1] < 0.5 then
        if simDR_wing_heat_on_R == 1 then simCMD_ice_wing_heat_off:once() end
    end

end




----- WINDOW ----------------------------------------------------------------------------
function B747_window_antiice()

    if B747DR_button_switch_position[73] >= 0.95 or
            B747DR_button_switch_position[74] >= 0.95
    then
        if simDR_window_heat_on == 0 then
            simCMD_ice_window_heat_on:once()
        end
    elseif B747DR_button_switch_position[73] <= 0.05 and
        B747DR_button_switch_position[74] <= 0.05
    then
        if simDR_window_heat_on == 1 then
			simCMD_ice_window_heat_off:once()
		end
    end

end






----- ANTI-ICE EICAS MESSAGED -----------------------------------------------------------
function B747_antiice_EICAS_msg()

    -- >ICING
    B747DR_CAS_caution_status[45] = 0
    if simDR_ice_detected == 1 then B747DR_CAS_caution_status[45] = 1 end

    -- >ANTI_ICE
    B747DR_CAS_advisory_status[7] = 0
    if ((simDR_engine_nacelle_heat_on[0] > 0
        or simDR_engine_nacelle_heat_on[1] > 0
        or simDR_engine_nacelle_heat_on[2] > 0
        or simDR_engine_nacelle_heat_on[3] > 0)
        or
        (simDR_wing_heat_on_L == 1 or simDR_wing_heat_on_R))
        and
        simDR_OAT_degc > 12.0
        and
        simDR_ice_detected == 0
    then
        B747DR_CAS_advisory_status[7] = 0
    end

    -- HEAT L AOA
    B747DR_CAS_advisory_status[186] = 0
    if simDR_AOA_heat_fail_L == 6 then B747DR_CAS_advisory_status[186] = 1 end

    -- HEAT R AOA
    B747DR_CAS_advisory_status[192] = 0
    if simDR_AOA_heat_fail_R == 6 then B747DR_CAS_advisory_status[192] = 1 end

    -- HEAT P/S CAPT
    B747DR_CAS_advisory_status[188] = 0
    if simDR_pitot_heat_fail_capt == 6 or simDR_static_heat_fail_capt == 6 then
        B747DR_CAS_advisory_status[188] = 1
    end

    -- HEAT P/S F/O
    B747DR_CAS_advisory_status[189] = 0
    if simDR_pitot_heat_fail_fo == 6 or simDR_static_heat_fail_fo == 6 then
        B747DR_CAS_advisory_status[189] = 1
    end



end








----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_ice_monitor_AI()

    if B747DR_init_ice_CD == 1 then
        B747_set_ice_all_modes()
        B747_set_ice_CD()
        B747DR_init_ice_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_ice_all_modes()

	B747DR_init_ice_CD = 0
    simCMD_ice_detect_on:once()

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_ice_CD()

    B747DR_windshield_wiper_sel_L_pos = 0
    B747DR_windshield_wiper_sel_R_pos = 0

end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_ice_ER()
	

	
end









----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_antiIce()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_ice_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_ice_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_ice_ER()

    end

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start()

    B747_flight_start_antiIce()

end

--function flight_crash() end

--function before_physics() end
debug_antiice     = deferred_dataref("laminar/B747/debug/antiice", "number")
function after_physics()
if debug_antiice>0 then return end
    B747_nacelle_antiice()
    B747_wing_antiice()
    B747_window_antiice()

    B747_antiice_EICAS_msg()

    B747_ice_monitor_AI()

end

--function after_replay() end



