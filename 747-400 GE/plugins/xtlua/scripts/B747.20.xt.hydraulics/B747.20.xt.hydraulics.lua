--[[
*****************************************************************************************
* Program Script Name	:	B747.20.hydraulics
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



--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--
--replace create_command
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end
--replace create_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")

simDR_elec_hyd_pump_on          = find_dataref("sim/cockpit2/switches/electric_hydraulic_pump_on")
simDR_engine01_hyd_pump_fail    = find_dataref("sim/operation/failures/rel_hydpmp")
simDR_engine02_hyd_pump_fail    = find_dataref("sim/operation/failures/rel_hydpmp2")
simDR_engine03_hyd_pump_fail    = find_dataref("sim/operation/failures/rel_hydpmp3")
simDR_engine04_hyd_pump_fail    = find_dataref("sim/operation/failures/rel_hydpmp4")
simDR_hyd_press_1               = find_dataref("sim/cockpit2/hydraulics/indicators/hydraulic_pressure_1")
simDR_hyd_press_2               = find_dataref("sim/cockpit2/hydraulics/indicators/hydraulic_pressure_2")
simDR_hyd_fluid_level           = find_dataref("sim/cockpit2/hydraulics/indicators/hydraulic_fluid_ratio_1")
simDR_hyd_fluid_level2          = find_dataref("sim/cockpit2/hydraulics/indicators/hydraulic_fluid_ratio_2")
simDR_parking_brake_ratio       = find_dataref("sim/cockpit2/controls/parking_brake_ratio")




--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_button_switch_position   = find_dataref("laminar/B747/button_switch/position")
B747DR_CAS_caution_status       = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status      = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_CAS_memo_status          = find_dataref("laminar/B747/CAS/memo_status")

B747DR_hyd_sys_restotal_1      = find_dataref("laminar/B747/hydraulics/restotal_1")
B747DR_hyd_sys_restotal_2      = find_dataref("laminar/B747/hydraulics/restotal_2")
B747DR_hyd_sys_restotal_3      = find_dataref("laminar/B747/hydraulics/restotal_3")
B747DR_hyd_sys_restotal_4      = find_dataref("laminar/B747/hydraulics/restotal_4")
B747DR_hyd_sys_res_1      = find_dataref("laminar/B747/hydraulics/res_1")
B747DR_hyd_sys_res_2      = find_dataref("laminar/B747/hydraulics/res_2")
B747DR_hyd_sys_res_3      = find_dataref("laminar/B747/hydraulics/res_3")
B747DR_hyd_sys_res_4      = find_dataref("laminar/B747/hydraulics/res_4")

B747DR_hyd_sys_pressure_1      = find_dataref("laminar/B747/hydraulics/pressure_1")
B747DR_hyd_sys_pressure_2      = find_dataref("laminar/B747/hydraulics/pressure_2")
B747DR_hyd_sys_pressure_3      = find_dataref("laminar/B747/hydraulics/pressure_3")
B747DR_hyd_sys_pressure_4      = find_dataref("laminar/B747/hydraulics/pressure_4")
B747DR_hyd_dmd_pmp_sel_pos      = find_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos")

--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--





B747DR_init_hyd_CD              = deferred_dataref("laminar/B747/hyd/init_CD", "number")



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




--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- DEMAND PUMP SELECTORS (ELEC)
function B747_hyd_dmd_pmp_sel_01_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[0] = math.min(B747DR_hyd_dmd_pmp_sel_pos[0]+1, 2)
    end
end
function B747_hyd_dmd_pmp_sel_01_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[0] = math.max(B747DR_hyd_dmd_pmp_sel_pos[0]-1, 0)
    end
end

function B747_hyd_dmd_pmp_sel_02_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[1] = math.min(B747DR_hyd_dmd_pmp_sel_pos[1]+1, 2)
    end
end
function B747_hyd_dmd_pmp_sel_02_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[1] = math.max(B747DR_hyd_dmd_pmp_sel_pos[1]-1, 0)
    end
end

function B747_hyd_dmd_pmp_sel_03_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[2] = math.min(B747DR_hyd_dmd_pmp_sel_pos[2]+1, 2)
    end
end
function B747_hyd_dmd_pmp_sel_03_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[2] = math.max(B747DR_hyd_dmd_pmp_sel_pos[2]-1, 0)
    end
end

function B747_hyd_dmd_pmp_sel_04_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[3] = math.min(B747DR_hyd_dmd_pmp_sel_pos[3]+1, 2)
    end
end
function B747_hyd_dmd_pmp_sel_04_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_hyd_dmd_pmp_sel_pos[3] = math.max(B747DR_hyd_dmd_pmp_sel_pos[3]-1, -1)
    end
end




function B747_ai_hyd_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
		B747_set_hyd_all_modes()
		--B747_set_hyd_CD()
		--B747_set_hyd_ER()   
	end    	
end	


--*************************************************************************************--
--** 				                 CUSTOM COMMANDS                			     **--
--*************************************************************************************--

-- DEMAND PUMP SELECTORS
B747CMD_hyd_dmd_pmp_sel_01_up 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_01_up", "Hydraulic Demand Pump Selector 01 Up", B747_hyd_dmd_pmp_sel_01_up_CMDhandler)
B747CMD_hyd_dmd_pmp_sel_01_dn 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_01_dn", "Hydraulic Demand Pump Selector 01 Down", B747_hyd_dmd_pmp_sel_01_dn_CMDhandler)

B747CMD_hyd_dmd_pmp_sel_02_up 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_02_up", "Hydraulic Demand Pump Selector 02 Up", B747_hyd_dmd_pmp_sel_02_up_CMDhandler)
B747CMD_hyd_dmd_pmp_sel_02_dn 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_02_dn", "Hydraulic Demand Pump Selector 02 Down", B747_hyd_dmd_pmp_sel_02_dn_CMDhandler)

B747CMD_hyd_dmd_pmp_sel_03_up 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_03_up", "Hydraulic Demand Pump Selector 03 Up", B747_hyd_dmd_pmp_sel_03_up_CMDhandler)
B747CMD_hyd_dmd_pmp_sel_03_dn 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_03_dn", "Hydraulic Demand Pump Selector 03 Down", B747_hyd_dmd_pmp_sel_03_dn_CMDhandler)

B747CMD_hyd_dmd_pmp_sel_04_up 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_04_up", "Hydraulic Demand Pump Selector 04 Up", B747_hyd_dmd_pmp_sel_04_up_CMDhandler)
B747CMD_hyd_dmd_pmp_sel_04_dn 	= deferred_command("laminar/B747/hydraulics/sel_dial/dmd_pump_04_dn", "Hydraulic Demand Pump Selector 04 Down", B747_hyd_dmd_pmp_sel_04_dn_CMDhandler)

-- AI
B747CMD_ai_hyd_quick_start		= deferred_command("laminar/B747/ai/hyd_quick_start", "number", B747_ai_hyd_quick_start_CMDhandler)




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

-- ENGINE DRIVEN PUMPS
function B747_engine_hyd_pumps()

    --[[ UTILIZE FAILURES TO TURN PUMPS ON AND OFF ]]--

    -- ENGINE #1
    if B747DR_button_switch_position[30] > 0.95 then
        simDR_engine01_hyd_pump_fail = 0
    elseif B747DR_button_switch_position[30] < 0.05 then
        simDR_engine01_hyd_pump_fail = 6
    end


    -- ENGINE #2
    if B747DR_button_switch_position[31] > 0.95 then
        simDR_engine02_hyd_pump_fail = 0
    elseif B747DR_button_switch_position[31] < 0.05 then
        simDR_engine02_hyd_pump_fail = 6
    end


    -- ENGINE #3
    if B747DR_button_switch_position[32] > 0.95 then
        simDR_engine03_hyd_pump_fail = 0
    elseif B747DR_button_switch_position[32] < 0.05 then
        simDR_engine03_hyd_pump_fail = 6
    end


    -- ENGINE #4
    if B747DR_button_switch_position[33] > 0.95 then
        simDR_engine04_hyd_pump_fail = 0
    elseif B747DR_button_switch_position[33] < 0.05 then
        simDR_engine04_hyd_pump_fail = 6
    end

end




-- ELECTRIC DEMAND PUMPS
function B747_elec_hyd_pumps()

    -- AUTO
    if (((B747DR_hyd_dmd_pmp_sel_pos[0] > 0.95 and B747DR_hyd_dmd_pmp_sel_pos[0] < 1.05) and simDR_engine01_hyd_pump_fail == 6)
        or
        ((B747DR_hyd_dmd_pmp_sel_pos[1] > 0.95 and B747DR_hyd_dmd_pmp_sel_pos[1] < 1.05) and simDR_engine02_hyd_pump_fail == 6)
        or
        ((B747DR_hyd_dmd_pmp_sel_pos[2] > 0.95 and B747DR_hyd_dmd_pmp_sel_pos[2] < 1.05) and simDR_engine03_hyd_pump_fail == 6)
        or
        ((B747DR_hyd_dmd_pmp_sel_pos[3] > 0.95 and B747DR_hyd_dmd_pmp_sel_pos[3] < 1.05) and simDR_engine04_hyd_pump_fail == 6))
    then
        simDR_elec_hyd_pump_on = 1


    -- ON
    elseif (B747DR_hyd_dmd_pmp_sel_pos[0] > 1.95
        and B747DR_hyd_dmd_pmp_sel_pos[1] > 1.95
        and B747DR_hyd_dmd_pmp_sel_pos[2] > 1.95
        and B747DR_hyd_dmd_pmp_sel_pos[3] > 1.95)
    then
        simDR_elec_hyd_pump_on = 1



    -- DEMAND PUMP 4 AUX
    elseif (((B747DR_hyd_dmd_pmp_sel_pos[0] < 0.05 and B747DR_hyd_dmd_pmp_sel_pos[0] > -0.05)
        or (B747DR_hyd_dmd_pmp_sel_pos[1] < 0.05 and B747DR_hyd_dmd_pmp_sel_pos[1] > -0.05)
        or (B747DR_hyd_dmd_pmp_sel_pos[2] < 0.05 and B747DR_hyd_dmd_pmp_sel_pos[2] > -0.05))
        and B747DR_hyd_dmd_pmp_sel_pos[3] < -0.5)
    then
        simDR_elec_hyd_pump_on = 1



    else
        simDR_elec_hyd_pump_on = 0

    end

end





----- EICAS MESSAGES --------------------------------------------------------------------
function B747_hyd_EICAS_msg()

    -- >BRAKE SOURCE
    
    --[[if simDR_engine01_hyd_pump_fail == 6
        and simDR_engine02_hyd_pump_fail == 6
        and simDR_engine04_hyd_pump_fail == 6]]
    if B747DR_hyd_sys_pressure_1 < 1000 and B747DR_hyd_sys_pressure_2 < 1000 and B747DR_hyd_sys_pressure_4 < 1000
    then
        B747DR_CAS_caution_status[9] = 1
    else
      B747DR_CAS_caution_status[9] = 0
    end

    -- HYD PRESS SYS 1-4
    B747DR_CAS_caution_status[40] = 0
    B747DR_CAS_caution_status[41] = 0
    B747DR_CAS_caution_status[42] = 0
    B747DR_CAS_caution_status[43] = 0
    if B747DR_hyd_sys_pressure_1 < 1000.0 then
        B747DR_CAS_caution_status[40] = 1
    end
    if B747DR_hyd_sys_pressure_2 < 1000.0 then
        B747DR_CAS_caution_status[41] = 1
    end
    if B747DR_hyd_sys_pressure_3 < 1000.0 then
        B747DR_CAS_caution_status[42] = 1
    end
    if B747DR_hyd_sys_pressure_4 < 1000.0 then
        B747DR_CAS_caution_status[43] = 1
    end
    
    

    -- >HYD QTY LOW 1 / >HYD QTY LOW 2
    B747DR_CAS_advisory_status[218] = 0
    B747DR_CAS_advisory_status[219] = 0
    if simDR_hyd_fluid_level < 0.10 then
        B747DR_CAS_advisory_status[218] = 1
        B747DR_CAS_advisory_status[219] = 1
    end

    -- >HYD QTY LOW 3 / >HYD QTY LOW 4
    B747DR_CAS_advisory_status[220] = 0
    B747DR_CAS_advisory_status[221] = 0
    if simDR_hyd_fluid_level2 < 0.10 then
        B747DR_CAS_advisory_status[220] = 1
        B747DR_CAS_advisory_status[221] = 1
    end

    -- PARK BRAKE SET
    
    if simDR_parking_brake_ratio > 0.9 then 
      B747DR_CAS_memo_status[26] = 1 
    else
      B747DR_CAS_memo_status[26] = 0
    end

end







----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_hyd_monitor_AI()

    if B747DR_init_hyd_CD == 1 then
        B747_set_hyd_all_modes()
        --B747_set_hyd_CD()
        B747DR_init_hyd_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_hyd_all_modes()

	B747DR_init_hyd_CD = 0	
B747DR_hyd_sys_restotal_1=math.random()*0.4+0.55
B747DR_hyd_sys_restotal_2=math.random()*0.4+0.55
B747DR_hyd_sys_restotal_3=math.random()*0.4+0.55
B747DR_hyd_sys_restotal_4=math.random()*0.4+0.55
B747DR_hyd_sys_res_1=B747DR_hyd_sys_restotal_1
B747DR_hyd_sys_res_2=B747DR_hyd_sys_restotal_2
B747DR_hyd_sys_res_3=B747DR_hyd_sys_restotal_3
B747DR_hyd_sys_res_4=B747DR_hyd_sys_restotal_4
end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_hyd_CD()
print("start hydraulic engines cd")
    B747DR_hyd_dmd_pmp_sel_pos[0] = 0
    B747DR_hyd_dmd_pmp_sel_pos[1] = 0
    B747DR_hyd_dmd_pmp_sel_pos[2] = 0
    B747DR_hyd_dmd_pmp_sel_pos[3] = 0

end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_hyd_ER()
	print("start hydraulic engines running")
    B747DR_hyd_dmd_pmp_sel_pos[0] = 1
    B747DR_hyd_dmd_pmp_sel_pos[1] = 1
    B747DR_hyd_dmd_pmp_sel_pos[2] = 1
    B747DR_hyd_dmd_pmp_sel_pos[3] = 1	
	
end







----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_hydraulic()

    -- ALL MODES ------------------------------------------------------------------------

        B747_set_hyd_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_hyd_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_hyd_ER()

    end

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start()

    B747_flight_start_hydraulic()

end

--function flight_crash() end

--function before_physics() end
debug_hydro     = deferred_dataref("laminar/B747/debug/hydro", "number")
function after_physics()
    if debug_hydro>0 then return end
    B747_engine_hyd_pumps()
    B747_elec_hyd_pumps()

    B747_hyd_EICAS_msg()

    B747_hyd_monitor_AI()

end

--function after_replay() end



