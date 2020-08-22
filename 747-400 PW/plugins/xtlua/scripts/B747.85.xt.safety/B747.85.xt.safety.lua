--[[
*****************************************************************************************
* Program Script Name	:	B747.85.safety
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



--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
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
simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")
simDR_door_open_ratio               = find_dataref("sim/flightmodel2/misc/door_open_ratio")
simDR_cockpit2_no_smoking_switch    = find_dataref("sim/cockpit2/switches/no_smoking")
simDR_cockpit2_seat_belt_switch     = find_dataref("sim/cockpit2/switches/fasten_seat_belts")


--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--


B747DR_CAS_advisory_status          = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_CAS_memo_status              = find_dataref("laminar/B747/CAS/memo_status")



--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_sfty_no_smoke_sel_dial_pos   = deferred_dataref("laminar/B747/safety/no_smoking/sel_dial_pos", "number")
B747DR_sfty_seat_belts_sel_dial_pos = deferred_dataref("laminar/B747/safety/seat_belts/sel_dial_pos", "number")

B747DR_init_safety_CD               = deferred_dataref("laminar/B747/safety/init_CD", "number")



--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--

function B747_checklist_marker_capt_DRhandler() end
function B747_checklist_marker_fo_DRhandler() end



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

B747DR_checklist_marker_capt        = deferred_dataref("laminar/B747/safety/checklist_marker_capt", "number", B747_checklist_marker_capt_DRhandler)
B747DR_checklist_marker_fo          = deferred_dataref("laminar/B747/safety/checklist_marker_fo", "number", B747_checklist_marker_fo_DRhandler)




--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- NO SMOKING DIAL
function B747_sfty_no_smoke_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_sfty_no_smoke_sel_dial_pos = math.min(B747DR_sfty_no_smoke_sel_dial_pos+1, 2)
    end
end
function B747_sfty_no_smoke_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_sfty_no_smoke_sel_dial_pos = math.max(B747DR_sfty_no_smoke_sel_dial_pos-1, 0)
    end
end




-- SEAT BELTS DIAL
function B747_sfty_seat_belts_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_sfty_seat_belts_sel_dial_pos = math.min(B747DR_sfty_seat_belts_sel_dial_pos+1, 2)
    end
end
function B747_sfty_seat_belts_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_sfty_seat_belts_sel_dial_pos = math.max(B747DR_sfty_seat_belts_sel_dial_pos-1, 0)
    end
end





function B747_ai_safety_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
      	B747_set_safety_all_modes()
      	B747_set_safety_CD()
      	B747_set_safety_ER() 
    end
end






--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--

-- NO SMOKING DIAL
B747CMD_sfty_no_smoke_sel_dial_up   = deferred_command("laminar/B747/safety/no_smoking/sel_dial_up", "No Smoking Selector Dial Up", B747_sfty_no_smoke_sel_dial_up_CMDhandler)
B747CMD_sfty_no_smoke_sel_dial_dn   = deferred_command("laminar/B747/safety/no_smoking/sel_dial_dn", "No Smoking Selector Dial Down", B747_sfty_no_smoke_sel_dial_dn_CMDhandler)


-- SEAT BELTS DIAL
B747CMD_sfty_seat_belts_sel_dial_up = deferred_command("laminar/B747/safety/seat_belts/sel_dial_up", "Seat Belts Selector Dial Up", B747_sfty_seat_belts_sel_dial_up_CMDhandler)
B747CMD_sfty_seat_belts_sel_dial_dn = deferred_command("laminar/B747/safety/seat_belts/sel_dial_dn", "Seat Belts Selector Dial_Down", B747_sfty_seat_belts_sel_dial_dn_CMDhandler)



-- AI
B747CMD_ai_safety_quick_start			= deferred_command("laminar/B747/ai/safety_quick_start", "number", B747_ai_safety_quick_start_CMDhandler)



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--










----- SAFETY EICAS MESSAGES -------------------------------------------------------------
function B747_safety_EICAS_msg()

    -- DOOR ENTRY L1
    B747DR_CAS_advisory_status[66] = 0
    if simDR_door_open_ratio[1] > 0.01 then B747DR_CAS_advisory_status[66] = 1 end

    -- DOOR L UPPER DK
    B747DR_CAS_advisory_status[76] = 0
    if simDR_door_open_ratio[0] > 0.01 then B747DR_CAS_advisory_status[76] = 1 end

    -- NO SMOKING ON
    B747DR_CAS_memo_status[17] = 0
    if simDR_cockpit2_no_smoking_switch == 1
        and simDR_cockpit2_seat_belt_switch == 0
    then
        B747DR_CAS_memo_status[17] = 1
    end

    -- PASS SIGNS ON
    B747DR_CAS_memo_status[27] = 0
    if simDR_cockpit2_no_smoking_switch == 1 and simDR_cockpit2_seat_belt_switch == 1 then
        B747DR_CAS_memo_status[27] = 1
    end

    -- SEATBELTS ON
    B747DR_CAS_memo_status[33] = 0
    if simDR_cockpit2_seat_belt_switch == 1
        and simDR_cockpit2_no_smoking_switch == 0
    then
        B747DR_CAS_memo_status[33] = 1
    end


end






----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_safety_monitor_AI()

    if B747DR_init_safety_CD == 1 then
        B747_set_safety_all_modes()
        B747_set_safety_CD()
        B747DR_init_safety_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_safety_all_modes()

	B747DR_init_safety_CD = 0

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_safety_CD()

    B747DR_sfty_no_smoke_sel_dial_pos = 0
    B747DR_sfty_seat_belts_sel_dial_pos = 0

end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_safety_ER()
	
    B747DR_sfty_no_smoke_sel_dial_pos = 1
    B747DR_sfty_seat_belts_sel_dial_pos = 1
	
end







----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_safety()

    -- ALL MODES ------------------------------------------------------------------------



    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_safety_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_safety_ER()

    end

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start() 

    B747_flight_start_safety()

end

--function flight_crash() end

--function before_physics() end
debug_safety     = deferred_dataref("laminar/B747/debug/safety", "number")
function after_physics()
    if debug_safety>0 then return end
    B747_safety_EICAS_msg()

    B747_safety_monitor_AI()

end

--function after_replay() end



