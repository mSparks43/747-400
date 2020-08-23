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
B747DR_windshield_wiper_sel_L_pos   = deferred_dataref("laminar/B747/antiice/wndshlsd_wiper_L/sel_dial_pos", "number")
B747DR_windshield_wiper_sel_R_pos   = deferred_dataref("laminar/B747/antiice/wndshlsd_wiper_R/sel_dial_pos", "number")

B747DR_nacelle_ai_valve_pos         = deferred_dataref("laminar/B747/antiice/nacelle/valve_pos", "array[4)")
B747DR_wing_ai_valve_pos            = deferred_dataref("laminar/B747/antiice/wing/valve_pos", "array[2)")

B747DR_init_ice_CD                  = deferred_dataref("laminar/B747/ice/init_CD", "number")



-- WINDSHIELD WIPERS
B747CMD_windshield_wiper_sel_L_up 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_L/sel_dial_up", "Windshield Wiper Selector Dial Left Up", B747_windshield_wiper_sel_L_up_CMDhandler)
B747CMD_windshield_wiper_sel_L_dn 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_L/sel_dial_dn", "Windshield Wiper Selector Dial Left Down", B747_windshield_wiper_sel_L_dn_CMDhandler)

B747CMD_windshield_wiper_sel_R_up 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_R/sel_dial_up", "Windshield Wiper Selector Dial Right Up", B747_windshield_wiper_sel_R_up_CMDhandler)
B747CMD_windshield_wiper_sel_R_dn 	= deferred_command("laminar/B747/antiice/wndshlsd_wiper_R/sel_dial_dn", "Windshield Wiper Selector Dial Right Down", B747_windshield_wiper_sel_R_dn_CMDhandler)


-- AI
B747CMD_ai_antiice_quick_start			= deferred_command("laminar/B747/ai/antiice_quick_start", "number", B747_ai_antiice_quick_start_CMDhandler)





