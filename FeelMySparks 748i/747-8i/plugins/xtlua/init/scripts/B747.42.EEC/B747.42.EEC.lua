--[[
*****************************************************************************************
* Program Script Name	:	B747.42.EEC
* Author Name			:	Marauder28
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2020-11-19	0.01a				Start of Dev
*	2021-05-27	0.1					Initial Release
*
*
*
*****************************************************************************************
*
*****************************************************************************************
--]]

--*************************************************************************************--
--** 					         EARLY FUNCTION DEFITIONS                            **--
--*************************************************************************************--
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


--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--
--THRUST CALC
B747DR_TO_throttle				= deferred_dataref("laminar/B747/engines/thrustref_throttle", "number")
B747DR_display_N1				= deferred_dataref("laminar/B747/engines/display_N1", "array[4]")
B747DR_display_N1_ref			= deferred_dataref("laminar/B747/engines/display_N1_ref", "array[4]")
B747DR_display_N1_max			= deferred_dataref("laminar/B747/engines/display_N1_max", "array[4]")
B747DR_display_N2				= deferred_dataref("laminar/B747/engines/display_N2", "array[4]")
B747DR_display_N3				= deferred_dataref("laminar/B747/engines/display_N3", "array[4]")
B747DR_display_EPR				= deferred_dataref("laminar/B747/engines/display_EPR", "array[4]")
B747DR_display_EPR_ref			= deferred_dataref("laminar/B747/engines/display_EPR_ref", "array[4]")
B747DR_display_EPR_max			= deferred_dataref("laminar/B747/engines/display_EPR_max", "array[4]")
B747DR_display_GE_EGT			= deferred_dataref("laminar/B747/engines/display_GE_EGT", "array[4]")
B747DR_display_EGT				= deferred_dataref("laminar/B747/engines/display_EGT", "array[4]")
B747DR_ref_line_magenta 		= deferred_dataref("laminar/B747/engines/display_ref_line_magenta", "number")
B747DR_throttle_resolver_angle 	= deferred_dataref("laminar/B747/engines/TRA", "array[4]")
B747DR_log_level = deferred_dataref("laminar/B747/engines/logging", "number")  --true / false

B747DR_pidthrottleP = deferred_dataref("laminar/B747/flt_ctrls/pid/throttle/p", "number")
--B747DR_pidthrottleHP = deferred_dataref("laminar/B747/flt_ctrls/pid/throttle/highp", "number")
--B747DR_pidthrottleLP = deferred_dataref("laminar/B747/flt_ctrls/pid/throttle/lowp", "number")
B747DR_pidthrottleI = deferred_dataref("laminar/B747/flt_ctrls/pid/throttle/i", "number")
B747DR_pidthrottleD = deferred_dataref("laminar/B747/flt_ctrls/pid/throttle/d", "number")

B747DR_pideccI = deferred_dataref("laminar/B747/flt_ctrls/pid/ecc/N1/i", "number")
B747DR_pideccD = deferred_dataref("laminar/B747/flt_ctrls/pid/ecc/N1/d", "number")
B747DR_pideccP = deferred_dataref("laminar/B747/flt_ctrls/pid/ecc/N1/p", "number")

B747DR_pidepr_eccI = deferred_dataref("laminar/B747/flt_ctrls/pid/ecc/epr/i", "number")
B747DR_pidepr_eccD = deferred_dataref("laminar/B747/flt_ctrls/pid/ecc/epr/d", "number")
B747DR_pidepr_eccP = deferred_dataref("laminar/B747/flt_ctrls/pid/ecc/epr/p", "number")
