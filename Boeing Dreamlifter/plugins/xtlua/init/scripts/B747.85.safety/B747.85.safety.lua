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

B747DR_sfty_no_smoke_sel_dial_pos   = deferred_dataref("laminar/B747/safety/no_smoking/sel_dial_pos", "number")
B747DR_sfty_seat_belts_sel_dial_pos = deferred_dataref("laminar/B747/safety/seat_belts/sel_dial_pos", "number")

B747DR_init_safety_CD               = deferred_dataref("laminar/B747/safety/init_CD", "number")



--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--

B747DR_checklist_marker_capt        = deferred_dataref("laminar/B747/safety/checklist_marker_capt", "number", B747_checklist_marker_capt_DRhandler)
B747DR_checklist_marker_fo          = deferred_dataref("laminar/B747/safety/checklist_marker_fo", "number", B747_checklist_marker_fo_DRhandler)



-- NO SMOKING DIAL
B747CMD_sfty_no_smoke_sel_dial_up   = deferred_command("laminar/B747/safety/no_smoking/sel_dial_up", "No Smoking Selector Dial Up", B747_sfty_no_smoke_sel_dial_up_CMDhandler)
B747CMD_sfty_no_smoke_sel_dial_dn   = deferred_command("laminar/B747/safety/no_smoking/sel_dial_dn", "No Smoking Selector Dial Down", B747_sfty_no_smoke_sel_dial_dn_CMDhandler)


-- SEAT BELTS DIAL
B747CMD_sfty_seat_belts_sel_dial_up = deferred_command("laminar/B747/safety/seat_belts/sel_dial_up", "Seat Belts Selector Dial Up", B747_sfty_seat_belts_sel_dial_up_CMDhandler)
B747CMD_sfty_seat_belts_sel_dial_dn = deferred_command("laminar/B747/safety/seat_belts/sel_dial_dn", "Seat Belts Selector Dial_Down", B747_sfty_seat_belts_sel_dial_dn_CMDhandler)



-- AI
B747CMD_ai_safety_quick_start			= deferred_command("laminar/B747/ai/safety_quick_start", "number", B747_ai_safety_quick_start_CMDhandler)





