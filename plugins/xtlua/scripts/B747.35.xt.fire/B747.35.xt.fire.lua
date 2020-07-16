--[[
*****************************************************************************************
* Program Script Name	:	B747.35.fire
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
local fire_extiguisher_switch_lock = {}
for i = 1, 4 do
    fire_extiguisher_switch_lock[i] = 0
end

local fire_extinguisher_switch_pos_arm_target  = {}
for i = 1, 4 do
    fire_extinguisher_switch_pos_arm_target[i] = 0
end

local fire_extinguisher_switch_pos_disch_target = {}
for i = 1, 4 do
    fire_extinguisher_switch_pos_disch_target[i] = 0
end





--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running       = find_dataref("sim/operation/prefs/startup_running")

simDR_engine_fire           = find_dataref("sim/cockpit2/annunciators/engine_fires")
simDR_engine_fire_ext_on    = find_dataref("sim/cockpit2/engine/actuators/fire_extinguisher_on")
simDR_cockpit_smoke         = find_dataref("sim/operation/failures/rel_smoke_cpit")
simDR_press_diff_psi        = find_dataref("sim/cockpit2/pressurization/indicators/pressure_diffential_psi")



--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_CAS_warning_status                   = find_dataref("laminar/B747/CAS/warning_status")



--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_fire_ovht_button_pos                 = deferred_dataref("laminar/B747/fire/fire_ovht/button_pos", "number")

B747DR_engine01_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine01/ext_switch/pos_arm", "number")
B747DR_engine02_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine02/ext_switch/pos_arm", "number")
B747DR_engine03_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine03/ext_switch/pos_arm", "number")
B747DR_engine04_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine04/ext_switch/pos_arm", "number")

B747DR_engine01_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine01/ext_switch/pos_disch", "number")
B747DR_engine02_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine02/ext_switch/pos_disch", "number")
B747DR_engine03_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine03/ext_switch/pos_disch", "number")
B747DR_engine04_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine04/ext_switch/pos_disch", "number")

B747DR_fire_ext_bottle_0102A_psi            = deferred_dataref("laminar/B747/fire/engine01_02A/ext_bottle/psi", "number")
B747DR_fire_ext_bottle_0102B_psi            = deferred_dataref("laminar/B747/fire/engine01_02B/ext_bottle/psi", "number")
B747DR_fire_ext_bottle_0304A_psi            = deferred_dataref("laminar/B747/fire/engine03_04A/ext_bottle/psi", "number")
B747DR_fire_ext_bottle_0304B_psi            = deferred_dataref("laminar/B747/fire/engine03_04B/ext_bottle/psi", "number")

B747DR_init_fire_CD                         = deferred_dataref("laminar/B747/fire/init_CD", "number")



--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--

----- FIRE/OVERHEAT TEST ----------------------------------------------------------------
function B747_fire_ovht_test_button_CMDhandler(phase, duration)
    if phase == 0 then
	      B747DR_fire_ovht_button_pos = 1
    elseif phase == 2 then
        B747DR_fire_ovht_button_pos = 0
    end
end




----- FIRE EXTINGUISHER SWITCHES --------------------------------------------------------
function B747_eng01_fire_ext_switch_arm_CMDhandler(phase, duration)
    if phase == 0 then
        if fire_extiguisher_switch_lock[1] == 0 then                    -- TODO:  CHANGE TO ALLOW SWITCH TO BE RETURNED TO "OFF" WHEN FIRE IS OUT ?
            if fire_extinguisher_switch_pos_disch_target[1] == 0 then
                fire_extinguisher_switch_pos_arm_target[1] = 1.0 - fire_extinguisher_switch_pos_arm_target[1]
            end
        end
    end
end

function B747_eng02_fire_ext_switch_arm_CMDhandler(phase, duration)
    if phase == 0 then
        if fire_extiguisher_switch_lock[2] == 0 then
            if fire_extinguisher_switch_pos_disch_target[2] == 0 then
                fire_extinguisher_switch_pos_arm_target[2] = 1.0 - fire_extinguisher_switch_pos_arm_target[2]
            end
        end
    end
end

function B747_eng03_fire_ext_switch_arm_CMDhandler(phase, duration)
    if phase == 0 then
        if fire_extiguisher_switch_lock[3] == 0 then
            if fire_extinguisher_switch_pos_disch_target[3] == 0 then
                fire_extinguisher_switch_pos_arm_target[3] = 1.0 - fire_extinguisher_switch_pos_arm_target[3]
            end
        end
    end
end

function B747_eng04_fire_ext_switch_arm_CMDhandler(phase, duration)
    if phase == 0 then
        if fire_extiguisher_switch_lock[4] == 0 then
            if fire_extinguisher_switch_pos_disch_target[4] == 0 then
                fire_extinguisher_switch_pos_arm_target[4] = 1.0 - fire_extinguisher_switch_pos_arm_target[4]
            end
        end
    end
end



function B747_eng01_fire_ext_switch_A_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine01_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[1] = math.max(fire_extinguisher_switch_pos_disch_target[1]-1, -1)
        end
    end
end

function B747_eng01_fire_ext_switch_B_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine01_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[1] = math.min(fire_extinguisher_switch_pos_disch_target[1]+1, 1)
        end
    end
end

function B747_eng02_fire_ext_switch_A_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine02_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[2] = math.min(fire_extinguisher_switch_pos_disch_target[2]+1, 1)
        end
    end
end

function B747_eng02_fire_ext_switch_B_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine02_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[2] = math.max(fire_extinguisher_switch_pos_disch_target[2]-1, -1)
        end
    end
end

function B747_eng03_fire_ext_switch_A_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine03_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[3] = math.max(fire_extinguisher_switch_pos_disch_target[3]-1, -1)
        end
    end
end

function B747_eng03_fire_ext_switch_B_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine03_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[3] = math.min(fire_extinguisher_switch_pos_disch_target[3]+1, 1)
        end
    end
end

function B747_eng04_fire_ext_switch_A_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine04_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[4] = math.min(fire_extinguisher_switch_pos_disch_target[4]+1, 1)
        end
    end
end

function B747_eng04_fire_ext_switch_B_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_engine04_fire_ext_switch_pos_arm == 1 then
            fire_extinguisher_switch_pos_disch_target[4] = math.max(fire_extinguisher_switch_pos_disch_target[4]-1, -1)
        end
    end
end



function B747_ai_fire_quick_start_CMDhandler(phase, duration) 
	if phase == 0 then
		B747_set_fire_all_modes()
		B747_set_fire_CD()
		B747_set_fire_ER()		
	end			
end	




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

----- FIRE/OVERHEAT TEST ----------------------------------------------------------------
B747CMD_fire_ovht_test_button       = deferred_command("laminar/B747/fire/button/fire_ovht_test", "Fire/Overheat Test", B747_fire_ovht_test_button_CMDhandler)



----- FIRE EXTINGUISHER SWITCHES --------------------------------------------------------
B747CMD_eng01_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine01/ext_switch_arm", "Fire Extinguisher Switch 01 Arm", B747_eng01_fire_ext_switch_arm_CMDhandler)
B747CMD_eng02_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine02/ext_switch_arm", "Fire Extinguisher Switch 02 Arm", B747_eng02_fire_ext_switch_arm_CMDhandler)
B747CMD_eng03_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine03/ext_switch_arm", "Fire Extinguisher Switch 03 Arm", B747_eng03_fire_ext_switch_arm_CMDhandler)
B747CMD_eng04_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine04/ext_switch_arm", "Fire Extinguisher Switch 04 Arm", B747_eng04_fire_ext_switch_arm_CMDhandler)


B747CMD_eng01_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine01/ext_switch_A", "Fire Extinguisher Switch A", B747_eng01_fire_ext_switch_A_CMDhandler)
B747CMD_eng01_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine01/ext_switch_B", "Fire Extinguisher Switch B", B747_eng01_fire_ext_switch_B_CMDhandler)
B747CMD_eng02_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine02/ext_switch_A", "Fire Extinguisher Switch A", B747_eng02_fire_ext_switch_A_CMDhandler)
B747CMD_eng02_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine02/ext_switch_B", "Fire Extinguisher Switch B", B747_eng02_fire_ext_switch_B_CMDhandler)
B747CMD_eng03_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine03/ext_switch_A", "Fire Extinguisher Switch A", B747_eng03_fire_ext_switch_A_CMDhandler)
B747CMD_eng03_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine03/ext_switch_B", "Fire Extinguisher Switch B", B747_eng03_fire_ext_switch_B_CMDhandler)
B747CMD_eng04_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine04/ext_switch_A", "Fire Extinguisher Switch A", B747_eng04_fire_ext_switch_A_CMDhandler)
B747CMD_eng04_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine04/ext_switch_B", "Fire Extinguisher Switch B", B747_eng04_fire_ext_switch_B_CMDhandler)


-- AI
B747CMD_ai_fire_quick_start			= deferred_command("laminar/B747/ai/fire_quick_start", "number", B747_ai_fire_quick_start_CMDhandler)




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end



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





----- FIRE EXTINGUISHER LOCKS -----------------------------------------------------------
function B747_fire_extingiuisher_locks()

    fire_extiguisher_switch_lock[1] = 0 --B747_ternary((simDR_engine_fire[0] == 6), 0, 1) -- TODO: ADD FUEL CUTOFF SWITCH TO LOGIC
    fire_extiguisher_switch_lock[2] = 0 --B747_ternary((simDR_engine_fire[1] == 6), 0, 1)
    fire_extiguisher_switch_lock[3] = 0 --B747_ternary((simDR_engine_fire[2] == 6), 0, 1)
    fire_extiguisher_switch_lock[4] = 0 --B747_ternary((simDR_engine_fire[3] == 6), 0, 1)

end


B747DR_engine_fire			    = deferred_dataref("laminar/B747/annunciators/engine_fires", "array[4)")



----- FIRE EXTINGUISHER SWITCH ANIMATION ------------------------------------------------
function B747_fire_ext_switch_animation()
    for i = 0, 3 do
      if  B747DR_fire_ovht_button_pos==1 then 
	  B747DR_engine_fire[i]=1
      else
	B747DR_engine_fire[i]=simDR_engine_fire[i]
      end
    end
    B747DR_engine01_fire_ext_switch_pos_arm = B747_set_animation_position(B747DR_engine01_fire_ext_switch_pos_arm, fire_extinguisher_switch_pos_arm_target[1], 0.0, 1.0, 10)
    B747DR_engine02_fire_ext_switch_pos_arm = B747_set_animation_position(B747DR_engine02_fire_ext_switch_pos_arm, fire_extinguisher_switch_pos_arm_target[2], 0.0, 1.0, 10)
    B747DR_engine03_fire_ext_switch_pos_arm = B747_set_animation_position(B747DR_engine03_fire_ext_switch_pos_arm, fire_extinguisher_switch_pos_arm_target[3], 0.0, 1.0, 10)
    B747DR_engine04_fire_ext_switch_pos_arm = B747_set_animation_position(B747DR_engine04_fire_ext_switch_pos_arm, fire_extinguisher_switch_pos_arm_target[4], 0.0, 1.0, 10)

    B747DR_engine01_fire_ext_switch_pos_disch = B747_set_animation_position(B747DR_engine01_fire_ext_switch_pos_disch, fire_extinguisher_switch_pos_disch_target[1],-1.0, 1.0, 10)
    B747DR_engine02_fire_ext_switch_pos_disch = B747_set_animation_position(B747DR_engine02_fire_ext_switch_pos_disch, fire_extinguisher_switch_pos_disch_target[2],-1.0, 1.0, 10)
    B747DR_engine03_fire_ext_switch_pos_disch = B747_set_animation_position(B747DR_engine03_fire_ext_switch_pos_disch, fire_extinguisher_switch_pos_disch_target[3],-1.0, 1.0, 10)
    B747DR_engine04_fire_ext_switch_pos_disch = B747_set_animation_position(B747DR_engine04_fire_ext_switch_pos_disch, fire_extinguisher_switch_pos_disch_target[4],-1.0, 1.0, 10)

end





----- FIRE EXTINGUISH LOGIC -------------------------------------------------------------
function B747_fire_extinguishers()

    ----- SET SIM FIRE EXTINGUISHER

    -- ENGINE #1
    if B747DR_engine01_fire_ext_switch_pos_disch < -0.95
        or B747DR_engine01_fire_ext_switch_pos_disch > 0.95
    then
        simDR_engine_fire_ext_on[0] = 1
    else
        simDR_engine_fire_ext_on[0] = 0
    end


    -- ENGINE #2
    if B747DR_engine02_fire_ext_switch_pos_disch < -0.95
        or B747DR_engine02_fire_ext_switch_pos_disch > 0.95
    then
        simDR_engine_fire_ext_on[1] = 1
    else
        simDR_engine_fire_ext_on[1] = 0
    end


    -- ENGINE #3
    if B747DR_engine03_fire_ext_switch_pos_disch < -0.95
        or B747DR_engine03_fire_ext_switch_pos_disch > 0.95
    then
        simDR_engine_fire_ext_on[2] = 1
    else
        simDR_engine_fire_ext_on[2] = 0
    end


    -- ENGINE #4
    if B747DR_engine04_fire_ext_switch_pos_disch < -0.95
        or B747DR_engine04_fire_ext_switch_pos_disch > 0.95
    then
        simDR_engine_fire_ext_on[3] = 1
    else
        simDR_engine_fire_ext_on[3] = 0
    end




    ----- SET BOTTLE PRESSURE ON DISCHARGE

    -- ENGINE #1 / BOTTLE A DISCHARGE
    if simDR_engine_fire_ext_on[0] == 1
        and B747DR_engine01_fire_ext_switch_pos_disch < -0.95
        and B747DR_fire_ext_bottle_0102A_psi > 0
    then
        B747DR_fire_ext_bottle_0102A_psi = math.max(0, B747DR_fire_ext_bottle_0102A_psi - (40.0 * SIM_PERIOD))
    end

    -- ENGINE #1 / BOTTLE B DISCHARGE
    if simDR_engine_fire_ext_on[0] == 1
        and B747DR_engine01_fire_ext_switch_pos_disch > 0.95
        and B747DR_fire_ext_bottle_0102B_psi > 0
    then
        B747DR_fire_ext_bottle_0102B_psi = math.max(0, B747DR_fire_ext_bottle_0102B_psi - (40.0 * SIM_PERIOD))
    end

    -- ENGINE #2 / BOTTLE A DISCHARGE
    if simDR_engine_fire_ext_on[1] == 1
        and B747DR_engine02_fire_ext_switch_pos_disch > 0.95
        and B747DR_fire_ext_bottle_0102A_psi > 0
    then
        B747DR_fire_ext_bottle_0102A_psi = math.max(0, B747DR_fire_ext_bottle_0102A_psi - (40.0 * SIM_PERIOD))
    end

    -- ENGINE #2 / BOTTLE B DISCHARGE
    if simDR_engine_fire_ext_on[1] == 1
        and B747DR_engine02_fire_ext_switch_pos_disch < -0.95
        and B747DR_fire_ext_bottle_0102B_psi > 0
    then
        B747DR_fire_ext_bottle_0102B_psi = math.max(0, B747DR_fire_ext_bottle_0102B_psi - (40.0 * SIM_PERIOD))
    end




    -- ENGINE #3 / BOTTLE A DISCHARGE
    if simDR_engine_fire_ext_on[2] == 1
        and B747DR_engine03_fire_ext_switch_pos_disch < -0.95
        and B747DR_fire_ext_bottle_0304A_psi > 0
    then
        B747DR_fire_ext_bottle_0304A_psi = math.max(0, B747DR_fire_ext_bottle_0304A_psi - (40.0 * SIM_PERIOD))
    end

    -- ENGINE #3 / BOTTLE B DISCHARGE
    if simDR_engine_fire_ext_on[2] == 1
        and B747DR_engine03_fire_ext_switch_pos_disch > 0.95
        and B747DR_fire_ext_bottle_0304B_psi > 0
    then
        B747DR_fire_ext_bottle_0304B_psi = math.max(0, B747DR_fire_ext_bottle_0304B_psi - (40.0 * SIM_PERIOD))
    end

    -- ENGINE #4 / BOTTLE A DISCHARGE
    if simDR_engine_fire_ext_on[3] == 1
        and B747DR_engine04_fire_ext_switch_pos_disch > 0.95
        and B747DR_fire_ext_bottle_0304A_psi > 0
    then
        B747DR_fire_ext_bottle_0304A_psi = math.max(0, B747DR_fire_ext_bottle_0304A_psi - (40.0 * SIM_PERIOD))
    end

    -- ENGINE #4 / BOTTLE B DISCHARGE
    if simDR_engine_fire_ext_on[3] == 1
        and B747DR_engine04_fire_ext_switch_pos_disch < -0.95
        and B747DR_fire_ext_bottle_0304B_psi > 0
    then
        B747DR_fire_ext_bottle_0304B_psi = math.max(0, B747DR_fire_ext_bottle_0304B_psi - (40.0 * SIM_PERIOD))
    end


end





----- EICAS MESSAGES --------------------------------------------------------------------
function B747_fire_EICAS_msg()

    -- FIRE ENG 1
    B747DR_CAS_warning_status[11] = 0
    if simDR_engine_fire[0] > 0 then B747DR_CAS_warning_status[11] = 1 end

    -- FIRE ENG 2
    B747DR_CAS_warning_status[12] = 0
    if simDR_engine_fire[1] > 0 then B747DR_CAS_warning_status[12] = 1 end

    -- FIRE ENG 3
    B747DR_CAS_warning_status[13] = 0
    if simDR_engine_fire[2] > 0 then B747DR_CAS_warning_status[13] = 1 end

    -- FIRE ENG 4
    B747DR_CAS_warning_status[14] = 0
    if simDR_engine_fire[3] > 0 then B747DR_CAS_warning_status[14] = 1 end

end








----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_fire_monitor_AI()

    if B747DR_init_fire_CD == 1 then
        B747_set_fire_all_modes()
        B747_set_fire_CD()
        B747DR_init_fire_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_fire_all_modes()

	B747DR_init_fire_CD = 0
	
    B747DR_fire_ext_bottle_0102A_psi = 600.0
    B747DR_fire_ext_bottle_0102B_psi = 600.0
    B747DR_fire_ext_bottle_0304A_psi = 600.0
    B747DR_fire_ext_bottle_0304B_psi = 600.0

    fire_extinguisher_switch_pos_arm_target[1] = 0
    fire_extinguisher_switch_pos_arm_target[2] = 0
    fire_extinguisher_switch_pos_arm_target[3] = 0
    fire_extinguisher_switch_pos_arm_target[4] = 0

    fire_extinguisher_switch_pos_disch_target[1] = 0
    fire_extinguisher_switch_pos_disch_target[2] = 0
    fire_extinguisher_switch_pos_disch_target[3] = 0
    fire_extinguisher_switch_pos_disch_target[4] = 0

    B747DR_smoke_evac_handle = 0

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_fire_CD()



end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_fire_ER()
	

	
end






----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_fire()

    -- ALL MODES ------------------------------------------------------------------------

        B747_set_fire_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_fire_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_fire_ER()

    end

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start() 

    B747_flight_start_fire()

end

--function flight_crash() end

--function before_physics() end
debug_fire     = deferred_dataref("laminar/B747/debug/fire", "number")
function after_physics()
    if debug_fire>0 then return end
    B747_fire_extingiuisher_locks()
    B747_fire_ext_switch_animation()
    B747_fire_extinguishers()

    B747_fire_EICAS_msg()

    B747_fire_monitor_AI()

end

--function after_replay() end



