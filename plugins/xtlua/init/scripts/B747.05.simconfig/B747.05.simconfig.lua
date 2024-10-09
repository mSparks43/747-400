--[[
*****************************************************************************************
* Program Script Name	:	B747.05.simconfig
* Author Name			:	Marauder28
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2020-11-19	0.01a				Start of Dev
*
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

B747DR_newsimconfig_data				= deferred_dataref("laminar/B747/newsimconfig", "number")
B747DR_pfd_style						= deferred_dataref("laminar/B747/pfd/style", "number")
B747DR_nd_style							= deferred_dataref("laminar/B747/nd/style", "number")
B747DR_thrust_ref						= deferred_dataref("laminar/B747/engines/thrust_ref", "number")
B747DR_engineType						= deferred_dataref("laminar/B747/engines/type", "number") -- crazytimtimtim engine type DR
B747DR_hideGE						= deferred_dataref("laminar/B747/engines/hideGE", "number") 
B747DR_hideRR						= deferred_dataref("laminar/B747/engines/hideRR", "number") 
B747DR_hidePW						= deferred_dataref("laminar/B747/engines/hidePW", "number") 
B747DR_hideCabin						= deferred_dataref("laminar/B747/objects/hideCabin", "number")
B747DR_hideGear						= deferred_dataref("laminar/B747/objects/hideGear", "number") 
B747DR_hideHStab						= deferred_dataref("laminar/B747/objects/hideHStab", "number")   
B747DR_hideFuse						= deferred_dataref("laminar/B747/objects/hideFuse", "number")   
B747DR_modernAlarms						= deferred_dataref("laminar/B747/fmod/options/modernAlarms", "number")
B747DR_fmc_cockpit_seats_hide				= deferred_dataref("laminar/B747/fmc/cockpit_seats_hide", "number") --silvereagle

B747DR_acarsProvider						= deferred_dataref("laminar/B747/acars/systemProvider", "number")
