--[[
*****************************************************************************************
* Program Script Name	:	B747.05.xt.simconfig
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

dofile("json/json.lua")

--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--
-- Holds all SimConfig options
B747DR_simconfig_data					= deferred_dataref("laminar/B747/simconfig", "string")

--*************************************************************************************--
--** 				        MAIN PROGRAM LOGIC                                       **--
--*************************************************************************************--
simConfig = {}

function simconfig_values()
	return {
			kgs_to_lbs = 2.2046226218488,
			weight_display_units = "KGS",
			model = "747-400",
			engines = "CF6-80C2-B1F",
			nav_data = "",
			active = "",
			op_program = "",  --populated in the IDENT page of FMC via data found in version.lua
			drag_ff = "+1.1/-3.5",
			irs_align_time = 600,
			stdPaxWeight = 120,  --In KGS
	}
end

--simConfig=simconfig_values()
simConfig["data"]=simconfig_values()

function flight_start()
	B747DR_simconfig_data=json.encode(simConfig["data"]["values"]) --make the simConfig data available to other modules
end
