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
function null_command(phase, duration)
end
--replace create_command
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
B747DR_hyd_dmd_pmp_sel_pos      = find_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos")
B747DR_init_hyd_CD              = deferred_dataref("laminar/B747/hyd/init_CD", "number")
-- DEMAND PUMP SELECTORS (ELEC)


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




