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

B747DR_init_fltctrls_CD         = deferred_dataref("laminar/B747/fltctrls/init_CD", "number")
B747DR_parking_brake_ratio      = deferred_dataref("laminar/B747/flt_ctrls/parking_brake_ratio", "number")


--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--
----- SPEEDBRAKE LEVER ------------------------------------------------------------------
--local B747_sb_manip_changed = 0
B747_sb_manip_changed = deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever_changed", "number")

--local B747_speedbrake_stop = 0
B747_speedbrake_stop = deferred_dataref("laminar/B747/flt_ctrls/speedbrake_stop", "number")
simDR_speedbrake_ratio_control  = find_dataref("sim/cockpit2/controls/speedbrake_ratio")

function B747_speedbrake_manip_timeout()
	B747_sb_manip_changed = 0 
end
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end
function B747_speedbrake_lever_DRhandler()
	
    -- DOWN DETENT
	if B747DR_speedbrake_lever < 0.01 then
		B747DR_speedbrake_lever = 0.0
		simDR_speedbrake_ratio_control = 0.0
		
     -- ARMED DETENT
    elseif B747DR_speedbrake_lever < 0.15 and
        B747DR_speedbrake_lever > 0.10
    then
        B747DR_speedbrake_lever = 0.125 
        simDR_speedbrake_ratio_control = -0.5
    
    -- ALL OTHER POSITIONS    
    else
	    B747DR_speedbrake_lever = math.min(1.0 - (B747_speedbrake_stop * 0.47), B747DR_speedbrake_lever)
	    simDR_speedbrake_ratio_control = B747_rescale(0.15, 0.0, 1.0 - (B747_speedbrake_stop * 0.47), 1.0, B747DR_speedbrake_lever) 	       
    end	   
    
    B747_sb_manip_changed = 1 
    if is_timer_scheduled(B747_speedbrake_manip_timeout) then
		stop_timer(B747_speedbrake_manip_timeout)    
	end	
	run_after_time(B747_speedbrake_manip_timeout, 2.0)

end

	

----- SPEEDBRAKE HANDLE -----------------------------------------------------------------
B747DR_speedbrake_lever     	= deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever", "number", B747_speedbrake_lever_DRhandler)
function B747_speedbrake_lever_detent_DRhandler() end
B747DR_speedbrake_lever_detent  = deferred_dataref("laminar/B747/flt_ctrls/speedbrake_lever_detent", "number", B747_speedbrake_lever_detent_DRhandler)

----- FLAP HANDLE -----------------------------------------------------------------------
function B747_flap_lever_detent_DRhandler() end
B747DR_flap_lever_detent		= deferred_dataref("laminar/B747/flt_ctrls/flap_lever_detent", "number", B747_flap_lever_detent_DRhandler)

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


B747CMD_parking_brake_on            = deferred_command("laminar/B747/flt_ctrls/parking_brake_on", "Parking brake on", B747CMD_parking_brake_on_CMDhandler)
B747CMD_parking_brake_off            = deferred_command("laminar/B747/flt_ctrls/parking_brake_off", "Parking brake off", B747CMD_parking_brake_off_CMDhandler)
B747CMD_parking_brake_toggle            = deferred_command("laminar/B747/flt_ctrls/parking_brake_toggle", "Parking brake toggle", B747CMD_parking_brake_toggle_CMDhandler)


