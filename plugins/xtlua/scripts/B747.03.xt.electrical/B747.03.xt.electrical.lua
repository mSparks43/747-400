--[[
*****************************************************************************************
* Program Script Name	:	B747.03.electrical
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2016-05-03	0.01a				Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED	    *
*****************************************************************************************
--]]

--[[

ELECTRICAL SYSTEM LOGIC DESCRIPTION:

In planemaker we set up 5 busses.  The battery is assigned to bus 5 making it essentially
the "Battery Bus".  The fifth bus will have power when the battery switch is on.
The 747 has 4 "bus-tie" switches, which can isolate each of the 4 main busses.  This cannot
be done in X-Plane so we require ALL (747) bus-tie switches to be closed in order to close the
X-Plane cross-tie (handled in the code below).  So, in X-Plane we assign the battery and
generators to bus 5.  Therefore, all of these 4 busses will have zero voltage until the
cross-tie is closed.

Since this logic means that all 4 busses either have power or they don't, the assignment of
components to busses in Planemaker is made for amp load distribution, not for power
source.  There should be no assignments made to the fifth bus.

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

function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
local B747_apu_start = 0
local B747_apu_inlet_door_target_pos = 0



--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")

simDR_engine_running            = find_dataref("sim/flightmodel/engine/ENGN_running")

simDR_aircraft_on_ground        = find_dataref("sim/flightmodel/failures/onground_any")
simDR_aircraft_groundspeed      = find_dataref("sim/flightmodel/position/groundspeed")

simDR_battery_on                = find_dataref("sim/cockpit2/electrical/battery_on")
simDR_gpu_on                    = find_dataref("sim/cockpit/electrical/gpu_on")
simDR_cross_tie                 = find_dataref("sim/cockpit2/electrical/cross_tie")

simDR_apu_gen_on                = find_dataref("sim/cockpit2/electrical/APU_generator_on")
--simDR_apu_gen_amps              = find_dataref("sim/cockpit2/electrical/APU_generator_amps")
simDR_apu_start_switch_mode     = find_dataref("sim/cockpit2/electrical/APU_starter_switch")
simDR_apu_N1_pct                = find_dataref("sim/cockpit2/electrical/APU_N1_percent")
simDR_apu_running               = find_dataref("sim/cockpit2/electrical/APU_running")
B747DR_elec_apu_oil      	= deferred_dataref("laminar/B747/electrical/oil", "number")


simDR_generator_on              = find_dataref("sim/cockpit2/electrical/generator_on")
simDR_generator_off              = find_dataref("sim/cockpit2/annunciators/generator_off")
simDR_esys0              = find_dataref("sim/operation/failures/rel_esys")
simDR_esys1              = find_dataref("sim/operation/failures/rel_esys2")
simDR_esys2              = find_dataref("sim/operation/failures/rel_esys3")
simDR_esys3              = find_dataref("sim/operation/failures/rel_esys4")




--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--
B747DR_elec_display_power   = find_dataref("laminar/B747/electrical/display_has_power")
-- Captain PFD
-- First Officer PFD
-- First Officer ND
-- Captain ND
-- Upper EIACAS
-- Lower EICAS
-- FMS L
-- FMS R
-- FMS C
B747DR_button_switch_position       = find_dataref("laminar/B747/button_switch/position")
B747DR_elec_ext_pwr_1_switch_mode   = find_dataref("laminar/B747/elec_ext_pwr_1/switch_mode")
B747DR_elec_ext_pwr_2_switch_mode   = find_dataref("laminar/B747/elec_ext_pwr_2/switch_mode")
B747DR_elec_apu_pwr_1_switch_mode   = find_dataref("laminar/B747/apu_pwr_1/switch_mode")
B747DR_elec_apu_pwr_2_switch_mode   = find_dataref("laminar/B747/apu_pwr_2/switch_mode")

B747DR_gen_drive_disc_status        = find_dataref("laminar/B747/electrical/generator/drive_disc_status")

B747DR_CAS_advisory_status          = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_CAS_memo_status              = find_dataref("laminar/B747/CAS/memo_status")
B747DR_simDR_esys0              = find_dataref("laminar/B747/rel_esys")
B747DR_simDR_esys1              = find_dataref("laminar/B747/rel_esys2")
B747DR_simDR_esys2              = find_dataref("laminar/B747/rel_esys3")
B747DR_simDR_esys3              = find_dataref("laminar/B747/rel_esys4")
B747DR_simDR_captain_display              = find_dataref("laminar/B747/electrical/capt_display_power")
B747DR_simDR_fo_display             = find_dataref("laminar/B747/electrical/fo_display_power")

--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_elec_standby_power_sel_pos   = deferred_dataref("laminar/B747/electrical/standby_power/sel_dial_pos", "number")
B747DR_elec_apu_sel_pos             = deferred_dataref("laminar/B747/electrical/apu/sel_dial_pos", "number")
B747DR_elec_stby_ignit_sel_pos      = deferred_dataref("laminar/B747/electrical/stby_ignit/sel_dial_pos", "number")
B747DR_elec_auto_ignit_sel_pos      = deferred_dataref("laminar/B747/electrical/auto_ignit/sel_dial_pos", "number")

B747DR_elec_apu_inlet_door_pos      = deferred_dataref("laminar/B747/electrical/apu_inlet_door", "number")
B747DR_elec_apu_volts      = deferred_dataref("laminar/B747/electrical/apu_volts", "number")
B747DR_elec_ext_pwr1_available      = deferred_dataref("laminar/B747/electrical/ext_pwr1_avail", "number")
B747DR_elec_ext_pwr2_available      = deferred_dataref("laminar/B747/electrical/ext_pwr2_avail", "number")
B747DR_elec_apu_pwr1_available      = deferred_dataref("laminar/B747/electrical/apu_pwr1_avail", "number")
B747DR_elec_apu_pwr2_available      = deferred_dataref("laminar/B747/electrical/apu_pwr2_avail", "number")
B747DR_init_elec_CD                 = deferred_dataref("laminar/B747/elec/init_CD", "number")
B747DR_elec_ext_pwr1_on      	= deferred_dataref("laminar/B747/electrical/ext_pwr1_on", "number")
B747DR_elec_ext_pwr2_on      	= deferred_dataref("laminar/B747/electrical/ext_pwr2_on", "number")
B747DR_elec_apu_pwr1_on      	= deferred_dataref("laminar/B747/electrical/apu_pwr1_on", "number")
B747DR_elec_apu_pwr2_on      	= deferred_dataref("laminar/B747/electrical/apu_pwr2_on", "number")
B747DR_elec_ssb      		= deferred_dataref("laminar/B747/electrical/ssb", "number")
B747DR_elec_topleftbus      	= deferred_dataref("laminar/B747/electrical/topleftbus", "number")
B747DR_elec_toprightbus      	= deferred_dataref("laminar/B747/electrical/toprightbus", "number")
B747DR_elec_bus1hot      	= deferred_dataref("laminar/B747/electrical/bus1hot", "number")
B747DR_elec_bus2hot      	= deferred_dataref("laminar/B747/electrical/bus2hot", "number")
B747DR_elec_bus3hot      	= deferred_dataref("laminar/B747/electrical/bus3hot", "number")
B747DR_elec_bus4hot      	= deferred_dataref("laminar/B747/electrical/bus4hot", "number")
B747DR_elec_utilityleft1      	= deferred_dataref("laminar/B747/electrical/utilityleft1", "number")
B747DR_elec_utilityright1      	= deferred_dataref("laminar/B747/electrical/utilityright1", "number")
B747DR_elec_utilityleft2      	= deferred_dataref("laminar/B747/electrical/utilityleft2", "number")
B747DR_elec_utilityright2      	= deferred_dataref("laminar/B747/electrical/utilityright2", "number")


--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	         	     **--
--*************************************************************************************--





--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--





--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--

-- APU
function sim_apu_start_CMDhandler(phase, duration)
    if phase == 0 then

        if simDR_apu_running == 0 then
            if B747DR_elec_apu_sel_pos == 0 then
                B747CMD_elec_apu_sel_up:once()
                B747CMD_elec_apu_sel_up:once()
            elseif B747DR_elec_apu_sel_pos == 1 then
                B747CMD_elec_apu_sel_up:once()
            end
        end
    end
end

function sim_apu_on_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_elec_apu_sel_pos == 0 then
            B747CMD_elec_apu_sel_up:once()
        end
    end
end

function sim_apu_off_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_elec_apu_sel_pos == 1 then
            B747CMD_elec_apu_sel_dn:once()
        end
    end
end





--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

simCMD_apu_start                = replace_command("sim/electrical/APU_start", sim_apu_start_CMDhandler)
simCMD_apu_on                   = replace_command("sim/electrical/APU_on", sim_apu_on_CMDhandler)
simCMD_apu_off                  = replace_command("sim/electrical/APU_off", sim_apu_off_CMDhandler)

--simCMD_apu_gen_on               = find_command("sim/electrical/APU_generator_on")
--simCMD_apu_gen_off              = find_command("sim/electrical/APU_generator_off")






--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- STANDBY POWER
function B747_elec_standby_power_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_standby_power_sel_pos = math.min(B747DR_elec_standby_power_sel_pos+1, 2)
    end
end
function B747_elec_standby_power_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_standby_power_sel_pos = math.max(B747DR_elec_standby_power_sel_pos-1, 0)
    end
end




-- APU SELECTOR
function B747_elec_apu_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_apu_sel_pos = math.min(B747DR_elec_apu_sel_pos+1, 2)
        if B747DR_elec_apu_sel_pos == 2 then B747_apu_start = 1 end
    end

    if phase == 2 then
        if B747DR_elec_apu_sel_pos == 2 then
            B747DR_elec_apu_sel_pos = 1
        end
    end
end
function B747_elec_apu_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_apu_sel_pos = math.max(B747DR_elec_apu_sel_pos-1, 0)
    end
end




-- STANDBY IGNITION
function B747_stby_ign_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_stby_ignit_sel_pos = math.min(B747DR_elec_stby_ignit_sel_pos+1, 2)
    end
end
function B747_stby_ign_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_stby_ignit_sel_pos = math.max(B747DR_elec_stby_ignit_sel_pos-1, 0)
    end
end




-- AUTO IGNITION
function B747_auto_ign_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_auto_ignit_sel_pos = math.min(B747DR_elec_auto_ignit_sel_pos+1, 2)
    end
end
function B747_auto_ign_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_elec_auto_ignit_sel_pos = math.max(B747DR_elec_auto_ignit_sel_pos-1, 0)
    end
end





function B747_ai_elec_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
	  	B747_set_elec_all_modes()
	  	B747_set_elec_CD() 
	  	B747_set_elec_ER()
	end 	
end	



--*************************************************************************************--
--** 				                 CUSTOM COMMANDS                			     **--
--*************************************************************************************--
function B747_connect_power_CMDhandler()
  B747DR_elec_ext_pwr1_available = 1
  B747DR_elec_ext_pwr2_available = 1
end
B747CMD_connect_power          = deferred_command("laminar/B747/electrical/connect_power", "Connect external power", B747_connect_power_CMDhandler)
-- STANDBY POWER
B747CMD_elec_standby_power_sel_up = deferred_command("laminar/B747/electrical/standby_power/sel_dial_up", "Electrical Standby Power Selector Up", B747_elec_standby_power_sel_up_CMDhandler)
B747CMD_elec_standby_power_sel_dn = deferred_command("laminar/B747/electrical/standby_power/sel_dial_dn", "Electrical Standby Power Selector Down", B747_elec_standby_power_sel_dn_CMDhandler)



-- APU SELECTOR
B747CMD_elec_apu_sel_up = deferred_command("laminar/B747/electrical/apu/sel_dial_up", "Electrical APU Selector Dial Up", B747_elec_apu_sel_up_CMDhandler)
B747CMD_elec_apu_sel_dn = deferred_command("laminar/B747/electrical/apu/sel_dial_dn", "Electrical APU Selector Dial Down", B747_elec_apu_sel_dn_CMDhandler)



-- STANDBY IGNITION
B747CMD_stby_ign_sel_up = deferred_command("laminar/B747/electrical/stby_ignit/sel_dial_up", "Electrical Standby Ignition Selector Dial Up", B747_stby_ign_sel_up_CMDhandler)
B747CMD_stby_ign_sel_dn = deferred_command("laminar/B747/electrical/stby_ignit/sel_dial_dn", "Electrical Standby Ignition Selector Dial Down", B747_stby_ign_sel_dn_CMDhandler)



-- AUTO IGNITION
B747CMD_auto_ign_sel_up = deferred_command("laminar/B747/electrical/auto_ignit/sel_dial_up", "Electrical Auto Ignition Selector Dial Up", B747_auto_ign_sel_up_CMDhandler)
B747CMD_auto_ign_sel_dn = deferred_command("laminar/B747/electrical/auto_ignit/sel_dial_dn", "Electrical Auto Ignition Selector Dial Down", B747_auto_ign_sel_dn_CMDhandler)


-- AI
B747CMD_ai_elec_quick_start			= deferred_command("laminar/B747/ai/elec_quick_start", "number", B747_ai_elec_quick_start_CMDhandler)



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





----- BATTERY ---------------------------------------------------------------------------
function B747_battery()

    if B747DR_button_switch_position[13] < 0.05
        and simDR_battery_on[0] == 1
    then
        simDR_battery_on[0] = 0
        B747DR_elec_apu_volts = 0
    end

    if B747DR_button_switch_position[13] > 0.95
        and simDR_battery_on[0] == 0
    then
        simDR_battery_on[0] = 1
        
    end
    if simDR_battery_on[0] == 1 then
         B747DR_elec_apu_volts = 28
    end
end





----- EXTERNAL POWER --------------------------------------------------------------------
function B747_external_power()

    -- EXT POWER 1 AVAILABLE
--     if simDR_aircraft_on_ground == 1
--         and simDR_aircraft_groundspeed < 0.05
--         and simDR_engine_running[0] == 0
--         and simDR_engine_running[1] == 0
--         and simDR_engine_running[2] == 0
--         and simDR_engine_running[3] == 0
--     then
--         B747DR_elec_ext_pwr1_available = 1
-- 	B747DR_elec_ext_pwr2_available = 1
--     else
--         B747DR_elec_ext_pwr1_available = 0
-- 	B747DR_elec_ext_pwr2_available = 0
--     end
    if simDR_aircraft_on_ground == 0
        or simDR_aircraft_groundspeed > 1.00
        or simDR_engine_running[0] == 1
        or simDR_engine_running[1] == 1
        or simDR_engine_running[2] == 1
        or simDR_engine_running[3] == 1
    then
        --print("disabled ground power at ".. simDR_aircraft_groundspeed .. " "..simDR_aircraft_on_ground)
        B747DR_elec_ext_pwr1_available = 0
	    B747DR_elec_ext_pwr2_available =0
    end
    -- EXTERNAL POWER ON/OFF
    if (B747DR_elec_ext_pwr1_available == 1
        and B747DR_elec_ext_pwr_1_switch_mode == 1) or (B747DR_elec_ext_pwr2_available == 1
        and B747DR_elec_ext_pwr_2_switch_mode == 1)
    then
        simDR_gpu_on = 1
    else
        simDR_gpu_on = 0
    end

end





----- BUS TIE ---------------------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end
function B747_bus_tie()
    simDR_cross_tie = 1 -- got power src make it available always then kill off buses
--     if B747DR_button_switch_position[18] > 0.95
--         or B747DR_button_switch_position[19] > 0.95
--         or B747DR_button_switch_position[20] > 0.95
--         or B747DR_button_switch_position[21] > 0.95
--         or simDR_cross_tie == 0
--     then
--         
--     elseif (B747DR_button_switch_position[18] < 0.05
--         and B747DR_button_switch_position[19] < 0.05
--         and B747DR_button_switch_position[20] < 0.05
--         and B747DR_button_switch_position[21] < 0.05)
--         and simDR_cross_tie == 1
--     then
--         simDR_cross_tie = 0
--     end
    
--     if B747DR_button_switch_position[18] < 0.05 and simDR_generator_off[0] ==1 then
--       simDR_esys0=6
--     else
--       simDR_esys0=0
--     end
--     if B747DR_button_switch_position[19] < 0.05 and simDR_generator_off[1] ==1 then
--       simDR_esys1=6
--     else
--       simDR_esys1=0
--     end
--     
--     if B747DR_button_switch_position[20] < 0.05 and simDR_generator_off[2] ==1 then
--       simDR_esys2=6
--     else
--       simDR_esys2=0
--     end
--     
--     if B747DR_button_switch_position[21] < 0.05 and simDR_generator_off[3] ==1 then
--       simDR_esys3=6
--     else
--       simDR_esys3=0
--     end
    
    B747DR_simDR_esys0=B747_ternary((B747DR_elec_bus1hot ==1 or simDR_generator_off[0] ==0),0,1)
    B747DR_simDR_esys1=B747_ternary((B747DR_elec_bus2hot ==1 or simDR_generator_off[1] ==0),0,1)
    B747DR_simDR_esys2=B747_ternary((B747DR_elec_bus3hot ==1 or simDR_generator_off[2] ==0),0,1)
    B747DR_simDR_esys3=B747_ternary((B747DR_elec_bus4hot ==1 or simDR_generator_off[3] ==0),0,1)
    
    --Captain Transfer Bus simDR_esys2
    B747DR_simDR_fo_display=B747_ternary((B747DR_simDR_esys1 < 0.05 or (B747DR_simDR_esys0 < 0.05 and B747DR_elec_standby_power_sel_pos>0)),0,6)
    --FO Transfer Bus simDR_esys1
    B747DR_simDR_captain_display=B747_ternary((B747DR_simDR_esys2 < 0.05 or (B747DR_simDR_esys0 < 0.05 and B747DR_elec_standby_power_sel_pos>0)  or (simDR_battery_on[0] == 1 and B747DR_elec_standby_power_sel_pos>0)),0,6)
    if failCapt==6 and failFO==6 then --turn off individual displays later
       simDR_esys1=6
       simDR_esys2=6
    else
       simDR_esys1=0
       simDR_esys2=0
    end
--     B747DR_elec_ext_pwr1_on     
--     B747DR_elec_ext_pwr2_on      
--     B747DR_elec_apu_pwr1_on      	
--     B747DR_elec_apu_pwr2_on 
    B747DR_elec_topleftbus = B747_ternary((B747DR_elec_ext_pwr1_on==1 or B747DR_elec_apu_pwr1_on==1 
      or (B747DR_elec_bus1hot ==1 and simDR_generator_off[0] ==0) or (B747DR_elec_bus2hot==1 and simDR_generator_off[1] ==0) 
      or B747DR_elec_ssb==1),1,0)
    B747DR_elec_toprightbus = B747_ternary((B747DR_elec_ext_pwr2_on==1 or B747DR_elec_apu_pwr2_on==1 
      or (B747DR_elec_bus3hot ==1 and simDR_generator_off[2] ==0) or (B747DR_elec_bus4hot==1 and simDR_generator_off[3] ==0) 
      or B747DR_elec_ssb==1),1,0)
    local do_tie= B747_ternary(((B747DR_elec_topleftbus ==1 or B747DR_elec_toprightbus==1) and 
	(B747DR_elec_ext_pwr1_on==1 or B747DR_elec_apu_pwr1_on==1 
      or (B747DR_elec_bus1hot ==1 and simDR_generator_off[0] ==0) 
      or (B747DR_elec_bus2hot ==1 and simDR_generator_off[1] ==0) 
      or B747DR_elec_ext_pwr2_on==1 or B747DR_elec_apu_pwr2_on==1
      or (B747DR_elec_bus3hot ==1 and simDR_generator_off[2] ==0) 
      or (B747DR_elec_bus4hot ==1 and simDR_generator_off[3] ==0))),1,0)
    local forceTie=B747_ternary((B747DR_elec_ext_pwr1_on == 1.0 and B747DR_elec_ext_pwr2_on==0 and B747DR_elec_apu_pwr2_on==0)
            or (B747DR_elec_ext_pwr2_on == 1.0 and B747DR_elec_ext_pwr1_on==0 and B747DR_elec_apu_pwr1_on==0)
            or (B747DR_elec_apu_pwr1_on == 1.0 and B747DR_elec_ext_pwr2_on==0 and B747DR_elec_apu_pwr2_on==0)
            or (B747DR_elec_apu_pwr2_on == 1.0 and B747DR_elec_ext_pwr1_on==0 and B747DR_elec_apu_pwr1_on==0),1,0)  
    local ssb = B747_ternary((B747DR_elec_ext_pwr1_on == 1.0 
            or B747DR_elec_ext_pwr2_on == 1.0
            or B747DR_elec_apu_pwr1_on == 1.0
            or B747DR_elec_apu_pwr2_on == 1.0
            
            ),forceTie,do_tie)
    B747DR_elec_ssb =B747_set_animation_position(B747DR_elec_ssb, ssb, 0.0, 1.0, 10)
    B747DR_elec_utilityleft1  = B747_ternary((B747DR_button_switch_position[11] > 0.95 and (B747DR_elec_bus1hot ==1 or simDR_generator_off[0] ==0)),1.0,0.0) 
    B747DR_elec_utilityleft2  = B747_ternary((B747DR_button_switch_position[11] > 0.95 and (B747DR_elec_bus2hot ==1 or simDR_generator_off[1] ==0)),1.0,0.0) 
    B747DR_elec_utilityright1 = B747_ternary((B747DR_button_switch_position[12] > 0.95 and (B747DR_elec_bus3hot ==1 or simDR_generator_off[2] ==0)),1.0,0.0) 
    B747DR_elec_utilityright2 = B747_ternary((B747DR_button_switch_position[12] > 0.95 and (B747DR_elec_bus4hot ==1 or simDR_generator_off[3] ==0)),1.0,0.0) 
    
    B747DR_elec_bus1hot = B747_ternary((B747DR_button_switch_position[18] > 0.95 and (simDR_generator_off[0] ==0 or B747DR_elec_topleftbus ==1)),1,0)
    B747DR_elec_bus2hot = B747_ternary((B747DR_button_switch_position[19] > 0.95 and (simDR_generator_off[1] ==0 or B747DR_elec_topleftbus ==1)),1,0)
    B747DR_elec_bus3hot = B747_ternary((B747DR_button_switch_position[20] > 0.95 and (simDR_generator_off[2] ==0 or B747DR_elec_toprightbus ==1)),1,0)
    B747DR_elec_bus4hot = B747_ternary((B747DR_button_switch_position[21] > 0.95 and (simDR_generator_off[3] ==0 or B747DR_elec_toprightbus ==1)),1,0)
-- Captain PFD
-- First Officer PFD
-- First Officer ND
-- Captain ND
-- Upper EIACAS
-- Lower EICAS
-- FMS C    
-- FMS R
-- FMS L
    B747DR_elec_display_power[6]=6-B747DR_simDR_fo_display
    B747DR_elec_display_power[7]=6-B747DR_simDR_fo_display
    B747DR_elec_display_power[8]=6-B747DR_simDR_captain_display
    
    --[[B747DR_elec_toprightbus      	
B747DR_elec_bus1hot      	
B747DR_elec_bus2hot      	
B747DR_elec_bus3hot      	
B747DR_elec_bus4hot      	
B747DR_elec_utilityleft      	
B747DR_elec_utilityright ]]     	
    
end





----- APU -------------------------------------------------------------------------------
function B747_apu_shutdown()

    simDR_apu_start_switch_mode = 0
    B747DR_elec_apu_pwr_1_switch_mode = 0
    B747DR_elec_apu_pwr_2_switch_mode = 0
    B747_apu_inlet_door_target_pos = 0.0

end

function B747_apu()

    -- STARTER
    if B747DR_elec_apu_sel_pos == 0 then
        if simDR_apu_running == 1 then
            if simDR_battery_on[0] == 0 then                    -- APU SHUTDOWN IMMEDIATELY IF BATTERY OFF
            B747_apu_shutdown()
            else                                                -- APU COOL DOWN BEFORE SHUT DOWN
                if is_timer_scheduled(B747_apu_shutdown) == false then
                    run_after_time(B747_apu_shutdown, 60.0)
                end
            end
        end


    elseif B747_apu_start == 1 then                   -- TODO:  NEED BATTERY SWITCH ON OR HARDWIRED ?
        if simDR_apu_running == 0 then
            B747_apu_inlet_door_target_pos = 1.0
            if B747DR_elec_apu_inlet_door_pos > 0.95 then
                simDR_apu_start_switch_mode = 2                 -- START
            end

        elseif simDR_apu_running == 1 then
            B747_apu_start = 0
            simDR_apu_start_switch_mode = 1                     -- RUNNING
        end

    end


    -- INLET DOOR
    B747DR_elec_apu_inlet_door_pos = B747_set_animation_position(B747DR_elec_apu_inlet_door_pos, B747_apu_inlet_door_target_pos, 0.0, 1.0, 0.7)


    -- APU GENERATOR
    if B747DR_elec_apu_sel_pos == 1 and simDR_apu_N1_pct > 95.0 then
      B747DR_elec_apu_pwr1_available      = 1
      B747DR_elec_apu_pwr2_available      = 1
    else
      B747DR_elec_apu_pwr1_available      = 0
      B747DR_elec_apu_pwr2_available      = 0
    end
    if simDR_aircraft_on_ground == 1 then
      if (B747DR_elec_apu_pwr_1_switch_mode == 1 or B747DR_elec_apu_pwr_2_switch_mode == 1)
             and simDR_apu_N1_pct > 95.0
             and simDR_apu_gen_on == 0
         then
             simDR_apu_gen_on = 1
	 elseif B747DR_elec_apu_pwr_1_switch_mode == 0 and B747DR_elec_apu_pwr_2_switch_mode==0 then
	    simDR_apu_gen_on = 0
	 end
    elseif simDR_apu_gen_on == 1 and B747DR_elec_apu_pwr_1_switch_mode == 0 and B747DR_elec_apu_pwr_2_switch_mode==0 then
        simDR_apu_gen_on = 0    
    end
--     if simDR_aircraft_on_ground == 1 then
--         if (B747DR_elec_apu_pwr_1_switch_mode == 1 or B747DR_elec_apu_pwr_2_switch_mode == 1)
--             and simDR_apu_N1_pct > 95.0
--             and simDR_apu_gen_on == 0
--         then
--             simDR_apu_gen_on = 1
-- 	    B747DR_elec_apu_pwr1_available      = 1
-- 	    B747DR_elec_apu_pwr2_available      = 1
--         elseif B747DR_elec_apu_pwr_1_switch_mode == 0 and B747DR_elec_apu_pwr_2_switch_mode==0 then
--             simDR_apu_gen_on = 0
--         end
--     else
--         if simDR_apu_gen_on == 1 and B747DR_elec_apu_pwr_1_switch_mode == 0 and B747DR_elec_apu_pwr_2_switch_mode==0 then
--             simDR_apu_gen_on = 0
-- 	    B747DR_elec_apu_pwr1_available      = 0
-- 	    B747DR_elec_apu_pwr2_available      = 0
--         end
--     end

end






----- GENERATORS ------------------------------------------------------------------------
function B747_generator()

    -- ENGINE #1
    if B747DR_gen_drive_disc_status[0] == 1 then
        simDR_generator_on[0] = 0
    else
        if simDR_generator_on[0] == 0
            and B747DR_button_switch_position[22] >= 0.95
        then
            simDR_generator_on[0] = 1
        elseif simDR_generator_on[0] == 1
            and B747DR_button_switch_position[22] <= 0.05
        then
            simDR_generator_on[0] = 0
        end
    end


    -- ENGINE #2
    if B747DR_gen_drive_disc_status[1] == 1 then
        simDR_generator_on[1] = 0
    else
        if simDR_generator_on[1] == 0
                and B747DR_button_switch_position[23] >= 0.95
        then
            simDR_generator_on[1] = 1
        elseif simDR_generator_on[1] == 1
                and B747DR_button_switch_position[23] <= 0.05
        then
            simDR_generator_on[1] = 0
        end
    end


    -- ENGINE #3
    if B747DR_gen_drive_disc_status[2] == 1 then
        simDR_generator_on[2] = 0
    else
        if simDR_generator_on[2] == 0
                and B747DR_button_switch_position[24] >= 0.95
        then
            simDR_generator_on[2] = 1
        elseif simDR_generator_on[2] == 1
                and B747DR_button_switch_position[24] <= 0.05
        then
            simDR_generator_on[2] = 0
        end
    end


    -- ENGINE #4
    if B747DR_gen_drive_disc_status[3] == 1 then
        simDR_generator_on[3] = 0
    else
        if simDR_generator_on[3] == 0
                and B747DR_button_switch_position[25] >= 0.95
        then
            simDR_generator_on[3] = 1
        elseif simDR_generator_on[3] == 1
                and B747DR_button_switch_position[25] <= 0.05
        then
            simDR_generator_on[3] = 0
        end
    end

end



function batteryDrain()
    B747DR_CAS_advisory_status[19] = 1
    B747DR_CAS_advisory_status[20] = 1
end

----- ELECTRICAL EICAS MESSAGES ---------------------------------------------------------
function B747_electrical_EICAS_msg()

    -- APU
    if B747DR_elec_standby_power_sel_pos==2 and is_timer_scheduled(batteryDrain) == false then
        run_after_time(batteryDrain,10)
    elseif B747DR_elec_standby_power_sel_pos<2 then
        B747DR_CAS_advisory_status[19] = 0
       --Main set in fltInst02.lua
    end
    if (B747DR_elec_apu_sel_pos > 0.95 and simDR_apu_N1_pct < 0.1)
        or
        (B747DR_elec_apu_sel_pos < 0.05 and simDR_apu_N1_pct > 95.0)
    then
        B747DR_CAS_advisory_status[13] = 1
    else
        B747DR_CAS_advisory_status[13] = 0
    end

    -- APU DOOR
    
    if (B747DR_elec_apu_inlet_door_pos > 0.95 and simDR_apu_running == 0)
        or
        (B747DR_elec_apu_inlet_door_pos < 0.05 and simDR_apu_running == 1)
    then
        B747DR_CAS_advisory_status[14] = 1
    else
        B747DR_CAS_advisory_status[14] = 0
    end

    -- >DRIVE DISC 1
    
    if B747DR_gen_drive_disc_status[0] == 1 then 
        B747DR_CAS_advisory_status[83] = 1 
    else
        B747DR_CAS_advisory_status[83] = 0
    end

    -- >DRIVE DISC 2
    
    if B747DR_gen_drive_disc_status[1] == 1 then 
        B747DR_CAS_advisory_status[84] = 1 
    else
        B747DR_CAS_advisory_status[84] = 0
    end

    -- >DRIVE DISC 3
    
    if B747DR_gen_drive_disc_status[2] == 1 then 
        B747DR_CAS_advisory_status[85] = 1 
    else
        B747DR_CAS_advisory_status[85] = 0
    end

    -- >DRIVE DISC 4
    
    if B747DR_gen_drive_disc_status[3] == 1 then 
        B747DR_CAS_advisory_status[86] = 1 
    else
        B747DR_CAS_advisory_status[86] = 0
    end

    -- ELEC UTIL BUS L
    
    if B747DR_button_switch_position[11] < 0.05 then 
        B747DR_CAS_advisory_status[105] = 1 
    else
        B747DR_CAS_advisory_status[105] = 0
    end

    -- ELEC UTIL BUS R
    
    if B747DR_button_switch_position[12] < 0.05 then 
        B747DR_CAS_advisory_status[106] = 1 
    else
        B747DR_CAS_advisory_status[106] = 0
    end

    -- APU RUNNING
    
    if simDR_apu_N1_pct > 95.0 then
        B747DR_CAS_memo_status[1] = 1
    else
        B747DR_CAS_memo_status[1] = 0
    end

    -- STBY IGNITION ON
    
    if B747DR_elec_stby_ignit_sel_pos == 0
        or B747DR_elec_stby_ignit_sel_pos == 2
    then
        B747DR_CAS_memo_status[34] = 1
    else
        B747DR_CAS_memo_status[34] = 0
    end

end






----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_elec_monitor_AI()

    if B747DR_init_elec_CD == 1 then
        B747_set_elec_all_modes()
        B747_set_elec_CD()
        B747DR_init_elec_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_elec_all_modes()
	
	B747DR_init_elec_CD = 0
    B747DR_elec_stby_ignit_sel_pos = 1
    B747DR_elec_auto_ignit_sel_pos = 1

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_elec_CD()

    B747DR_elec_standby_power_sel_pos = 0
    B747DR_elec_apu_sel_pos = 0
    simDR_apu_start_switch_mode = 0

end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_elec_ER()
  B747DR_elec_standby_power_sel_pos = 1
	
	
end	






----- FLIGHT START ---------------------------------------------------------------------
function B747_flight_start_electric()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_elec_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_elec_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_elec_ER()

    end

end








--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start() 

    B747_flight_start_electric()

end

--function flight_crash() end

--function before_physics() end
debug_electrical     = deferred_dataref("laminar/B747/debug/electrical", "number")
function after_physics()
    if debug_electrical>0 then return end
    B747_battery()
    B747_external_power()
    B747_apu()
    B747_bus_tie()
    B747_generator()
    B747_electrical_EICAS_msg()
    B747_elec_monitor_AI()

end

--function after_replay() end



