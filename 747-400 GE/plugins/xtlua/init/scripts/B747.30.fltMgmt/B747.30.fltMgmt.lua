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
function null_command(phase, duration)
end
--replace deferred_command
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


B747DR_iru_mode_sel_pos         = deferred_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos", "array[4]")
B747DR_iru_status         	= deferred_dataref("laminar/B747/flt_mgmt/iru/status", "array[4]")
B747DR_xpdrMode_sel_pos         = deferred_dataref("laminar/B747/flt_mgmt/txpdr/mode_sel_pos", "number")
B747DR_xpdr_sel_pos             = deferred_dataref("laminar/B747/flt_mgmt/transponder/sel_dial_pos", "number")
B747DR_ident_button_pos         = deferred_dataref("laminar/B747/flt_mgmt/transponder/ident_btn_pos", "number")
B747DR_xpdr_code_12_dial_pos    = deferred_dataref("laminar/B747/flt_mgmt/transponder_code/digts_12_dial_pos", "number")
B747DR_xpdr_code_34_dial_pos    = deferred_dataref("laminar/B747/flt_mgmt/transponder_code/digts_34_dial_pos", "number")

B747DR_init_fltmgmt_CD          = deferred_dataref("laminar/B747/fltmgmt/init_CD", "number")


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







