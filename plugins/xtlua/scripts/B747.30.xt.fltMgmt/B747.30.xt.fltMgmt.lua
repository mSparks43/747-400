--[[
*****************************************************************************************
* Program Script Name	:	B747.30.fltMgmt
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
simDR_startup_running   = find_dataref("sim/operation/prefs/startup_running")
simDR_xpdr_mode         = find_dataref("sim/cockpit2/radios/actuators/transponder_mode")    -- 0=OFF, 1=STANDBY, 2=ON, 3=ALT, 4=TEST, 5=GROUND
simDR_airspeed                      = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
--simDR_xpdr_code         = find_dataref("sim/cockpit2/radios/actuators/transponder_code")

--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_iru_mode_sel_pos         = deferred_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos", "array[4]")
B747DR_iru_status         	= deferred_dataref("laminar/B747/flt_mgmt/iru/status", "array[4]")
B747DR_xpdrMode_sel_pos         = deferred_dataref("laminar/B747/flt_mgmt/txpdr/mode_sel_pos", "number")
B747DR_xpdr_sel_pos             = deferred_dataref("laminar/B747/flt_mgmt/transponder/sel_dial_pos", "number")
B747DR_ident_button_pos         = deferred_dataref("laminar/B747/flt_mgmt/transponder/ident_btn_pos", "number")
B747DR_xpdr_code_12_dial_pos    = deferred_dataref("laminar/B747/flt_mgmt/transponder_code/digts_12_dial_pos", "number")
B747DR_xpdr_code_34_dial_pos    = deferred_dataref("laminar/B747/flt_mgmt/transponder_code/digts_34_dial_pos", "number")

B747DR_init_fltmgmt_CD          = deferred_dataref("laminar/B747/fltmgmt/init_CD", "number")
B747DR_CAS_advisory_status          = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_radio_altitude                           = deferred_dataref("laminar/B747/efis/radio_altitude", "number")

--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--

function B747_xpdr_ident_CMDhandler_before(phase, duration) end
function B747_xpdr_ident_CMDhandler_after(phase, duration)
    if phase == 0 then
        B747DR_ident_button_pos = 1
     elseif phase == 2 then
        B747DR_ident_button_pos = 0
    end
end




function B747_xpdr_digits_12_up_CMDhandler_before(phase, duration) end
function B747_xpdr_digits_12_up_CMDhandler_after(phase, duration)
    B747DR_xpdr_code_12_dial_pos = B747DR_xpdr_code_12_dial_pos + 1
end
function B747_xpdr_digits_12_dn_CMDhandler_before(phase, duration) end
function B747_xpdr_digits_12_dn_CMDhandler_after(phase, duration)
    B747DR_xpdr_code_12_dial_pos = B747DR_xpdr_code_12_dial_pos - 1
end
function B747_xpdr_digits_34_up_CMDhandler_before(phase, duration) end
function B747_xpdr_digits_34_up_CMDhandler_after(phase, duration)
    B747DR_xpdr_code_34_dial_pos = B747DR_xpdr_code_34_dial_pos + 1
end
function B747_xpdr_digits_34_dn_CMDhandler_before(phase, duration) end
function B747_xpdr_digits_34_dn_CMDhandler_after(phase, duration)
    B747DR_xpdr_code_34_dial_pos = B747DR_xpdr_code_34_dial_pos - 1
end





--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

simCMD_xpdr_ident           = wrap_command("sim/transponder/transponder_ident", B747_xpdr_ident_CMDhandler_before, B747_xpdr_ident_CMDhandler_after)
simCMD_xpdr_digits_12_up    = wrap_command("sim/transponder/transponder_12_up", B747_xpdr_digits_12_up_CMDhandler_before, B747_xpdr_digits_12_up_CMDhandler_after)
simCMD_xpdr_digits_12_dn    = wrap_command("sim/transponder/transponder_12_down", B747_xpdr_digits_12_dn_CMDhandler_before, B747_xpdr_digits_12_dn_CMDhandler_after)
simCMD_xpdr_digits_34_up    = wrap_command("sim/transponder/transponder_34_up", B747_xpdr_digits_34_up_CMDhandler_before, B747_xpdr_digits_34_up_CMDhandler_after)
simCMD_xpdr_digits_34_dn    = wrap_command("sim/transponder/transponder_34_down", B747_xpdr_digits_34_dn_CMDhandler_before, B747_xpdr_digits_34_dn_CMDhandler_after)





--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- IRU MODE SELECTORS
function B747_flt_mgmgt_iru_mode_sel_L_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_iru_mode_sel_pos[0] = math.min(B747DR_iru_mode_sel_pos[0]+1, 3)
	if B747DR_iru_mode_sel_pos[0]==1 then B747DR_iru_status[0]=1 end
    end
end
function B747_flt_mgmgt_iru_mode_sel_L_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_iru_mode_sel_pos[0] = math.max(B747DR_iru_mode_sel_pos[0]-1, 0)
	if B747DR_iru_mode_sel_pos[0]==1 then B747DR_iru_status[0]=1 end
	if B747DR_iru_mode_sel_pos[0]==0 then B747DR_iru_status[0]=0 end
    end
end

function B747_flt_mgmgt_iru_mode_sel_C_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_iru_mode_sel_pos[1] = math.min(B747DR_iru_mode_sel_pos[1]+1, 3)
	if B747DR_iru_mode_sel_pos[1]==1 then B747DR_iru_status[1]=1 end
    end
end
function B747_flt_mgmgt_iru_mode_sel_C_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_iru_mode_sel_pos[1] = math.max(B747DR_iru_mode_sel_pos[1]-1, 0)
	if B747DR_iru_mode_sel_pos[1]==1 then B747DR_iru_status[1]=1 end
	if B747DR_iru_mode_sel_pos[1]==0 then B747DR_iru_status[1]=0 end
    end
end

function B747_flt_mgmgt_iru_mode_sel_R_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_iru_mode_sel_pos[2] = math.min(B747DR_iru_mode_sel_pos[2]+1, 3)
	if B747DR_iru_mode_sel_pos[2]==1 then B747DR_iru_status[2]=1 end
    end
end
function B747_flt_mgmgt_iru_mode_sel_R_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_iru_mode_sel_pos[2] = math.max(B747DR_iru_mode_sel_pos[2]-1, 0)
	if B747DR_iru_mode_sel_pos[2]==1 then B747DR_iru_status[2]=1 end
	if B747DR_iru_mode_sel_pos[2]==0 then B747DR_iru_status[2]=0 end
    end
end






-- TRANSPONDER (0=OFF, 1=STANDBY, 2=ON, 3=ALT, 4=TEST, 5=GROUND)
function B747_flt_xpdr_mode_sel_dial_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_xpdrMode_sel_pos = math.min(B747DR_xpdrMode_sel_pos+1, 4)
	--if B747DR_xpdrMode_sel_pos<=2 then simDR_EFIS_tcas_on =0 B747DR_nd_capt_tfc = 0 end
        simDR_xpdr_mode = math.min(B747DR_xpdrMode_sel_pos+1,2)
    end
end
function B747_flt_xpdr_mode_sel_dial_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_xpdrMode_sel_pos = math.max(B747DR_xpdrMode_sel_pos-1, 0)
	--if B747DR_xpdrMode_sel_pos<=2 then simDR_EFIS_tcas_on =0 B747DR_nd_capt_tfc = 0 end
        simDR_xpdr_mode = math.min(B747DR_xpdrMode_sel_pos+1,2)
    end
end




function B747_flt_xpdr_sel_dial_CMDhandler(phase, duration)
    if phase == 0 then
        if B747DR_xpdr_sel_pos == 0 then
            B747DR_xpdr_sel_pos = 1
        elseif B747DR_xpdr_sel_pos == 1 then
            B747DR_xpdr_sel_pos = 0
        end
    end
end





function B747_ai_fltmgmt_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
	 	B747_set_fltmgmt_all_modes()
	 	B747_set_fltmgmt_CD()
	 	B747_set_fltmgmt_ER()  
	end    	
end	




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- IRU MODE SELECTORS
B747CMD_flt_mgmgt_iru_mode_sel_L_up = deferred_command("laminar/B747/flt_mgmt/iru/mode_sel_dial_L_up", "Flight Management IRU Mode Selector L Up", B747_flt_mgmgt_iru_mode_sel_L_up_CMDhandler)
B747CMD_flt_mgmgt_iru_mode_sel_L_dn = deferred_command("laminar/B747/flt_mgmt/iru/mode_sel_dial_L_dn", "Flight Management IRU Mode Selector L Down", B747_flt_mgmgt_iru_mode_sel_L_dn_CMDhandler)

B747CMD_flt_mgmgt_iru_mode_sel_C_up = deferred_command("laminar/B747/flt_mgmt/iru/mode_sel_dial_C_up", "Flight Management IRU Mode Selector C Up", B747_flt_mgmgt_iru_mode_sel_C_up_CMDhandler)
B747CMD_flt_mgmgt_iru_mode_sel_C_dn = deferred_command("laminar/B747/flt_mgmt/iru/mode_sel_dial_C_dn", "Flight Management IRU Mode Selector C Down", B747_flt_mgmgt_iru_mode_sel_C_dn_CMDhandler)

B747CMD_flt_mgmgt_iru_mode_sel_R_up = deferred_command("laminar/B747/flt_mgmt/iru/mode_sel_dial_R_up", "Flight Management IRU Mode Selector R Up", B747_flt_mgmgt_iru_mode_sel_R_up_CMDhandler)
B747CMD_flt_mgmgt_iru_mode_sel_R_dn = deferred_command("laminar/B747/flt_mgmt/iru/mode_sel_dial_R_dn", "Flight Management IRU Mode Selector R Down", B747_flt_mgmgt_iru_mode_sel_R_dn_CMDhandler)



--TRANSPONDER
B747CMD_flt_xpdr_mode_sel_dial_up   = deferred_command("laminar/B747/flt_mgmt/transponder/mode_sel_dial_up", "Flight Management Transponder Mode Selector Dial Up", B747_flt_xpdr_mode_sel_dial_up_CMDhandler)
B747CMD_flt_xpdr_mode_sel_dial_dn   = deferred_command("laminar/B747/flt_mgmt/transponder/mode_sel_dial_dn", "Flight Management Transponder Mode Selector Dial Down", B747_flt_xpdr_mode_sel_dial_dn_CMDhandler)


B747CMD_flt_xpdr_sel_dial           = deferred_command("laminar/B747/flt_mgmt/transponder/sel_dial", "Flight Management Transponder Selector Dial", B747_flt_xpdr_sel_dial_CMDhandler)



-- AI
B747CMD_ai_fltmgmt_quick_start		= deferred_command("laminar/B747/ai/fltmgmt_quick_start", "number", B747_ai_fltmgmt_quick_start_CMDhandler)




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--








----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_fltmgmt_monitor_AI()

    if B747DR_init_fltmgmt_CD == 1 then
        B747_set_fltmgmt_all_modes()
        B747_set_fltmgmt_CD()
        B747DR_init_fltmgmt_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_fltmgmt_all_modes()

	B747DR_init_fltmgmt_CD = 0
    B747DR_xpdrMode_sel_pos = 0
    simDR_xpdr_mode = 1

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_fltmgmt_CD()

    B747DR_iru_mode_sel_pos[0] = 0
    B747DR_iru_mode_sel_pos[1] = 0
    B747DR_iru_mode_sel_pos[2] = 0
    B747DR_iru_status[0] = 0
    B747DR_iru_status[1] = 0
    B747DR_iru_status[2] = 0

end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_fltmgmt_ER()
	
    B747DR_iru_mode_sel_pos[0] = 2
    B747DR_iru_mode_sel_pos[1] = 2
    B747DR_iru_mode_sel_pos[2] = 2
    B747DR_iru_status[0] = 2
    B747DR_iru_status[1] = 2
    B747DR_iru_status[2] = 2
end






----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_fltMgmt()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_fltmgmt_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_fltmgmt_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_fltmgmt_ER()

    end

end






--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start() 

    B747_flight_start_fltMgmt()

end

--function flight_crash() end

--function before_physics() end
function B747_fltmgmt_EICAS_msg()
  if (B747DR_radio_altitude>400 or simDR_airspeed<30) and B747DR_xpdrMode_sel_pos<=2 then
    B747DR_CAS_advisory_status[279] = 1
  else
    B747DR_CAS_advisory_status[279] = 0
  end
  if B747DR_radio_altitude>400 and B747DR_xpdrMode_sel_pos==3 then
    B747DR_CAS_advisory_status[280] = 1
    B747DR_CAS_advisory_status[281] = 1
  else
    B747DR_CAS_advisory_status[280] = 0
    B747DR_CAS_advisory_status[281] = 0
  end
end
debug_fltmgmt     = deferred_dataref("laminar/B747/debug/fltmgmt", "number")
function after_physics()
  if debug_fltmgmt>0 then return end
    --print("navaids="..navAids)
    --print("fms="..fms)
    B747_fltmgmt_EICAS_msg()
    B747_fltmgmt_monitor_AI()
    --B747_fltmgmt_setILS() 
end

--function after_replay() end



