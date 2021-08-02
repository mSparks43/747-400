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

simDR_livery_path			= find_dataref("sim/aircraft/view/acf_livery_path")
simDR_acf_tailnum			= find_dataref("sim/aircraft/view/acf_tailnum")

--Baro Sync
simDR_baro_capt				= find_dataref("sim/cockpit/misc/barometer_setting")
simDR_baro_fo				= find_dataref("sim/cockpit/misc/barometer_setting2")

B747DR_SNDoptions			        	= find_dataref("laminar/B747/fmod/options")

--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--
-- Holds all SimConfig options
B747DR_simconfig_data						= deferred_dataref("laminar/B747/simconfig", "string")

B747DR_efis_baro_ref_capt_sel_dial_pos		= find_dataref("laminar/B747/efis/baro_ref/capt/sel_dial_pos", "number")
B747DR_efis_baro_ref_fo_sel_dial_pos		= deferred_dataref("laminar/B747/efis/baro_ref/fo/sel_dial_pos", "number")
B747DR_flt_inst_inbd_disp_capt_sel_dial_pos	= deferred_dataref("laminar/B747/flt_inst/capt_inbd_display/sel_dial_pos", "number")
B747DR_flt_inst_lwr_disp_capt_sel_dial_pos	= deferred_dataref("laminar/B747/flt_inst/capt_lwr_display/sel_dial_pos", "number")
B747DR_flt_inst_inbd_disp_fo_sel_dial_pos	= deferred_dataref("laminar/B747/flt_inst/fo_inbd_display/sel_dial_pos", "number")
B747DR_flt_inst_lwr_disp_fo_sel_dial_pos	= deferred_dataref("laminar/B747/flt_inst/fo_lwr_display/sel_dial_pos", "number")
B747DR_pfd_style							= deferred_dataref("laminar/B747/pfd/style", "number")
B747DR_nd_style								= deferred_dataref("laminar/B747/nd/style", "number")
B747DR_thrust_ref							= deferred_dataref("laminar/B747/engines/thrust_ref", "number")

--Baro Sync
B747DR_efis_baro_ref_capt_sel_dial_pos		= deferred_dataref("laminar/B747/efis/baro_ref/capt/sel_dial_pos", "number")
B747DR_efis_baro_ref_fo_sel_dial_pos		= deferred_dataref("laminar/B747/efis/baro_ref/fo/sel_dial_pos", "number")
B747DR_efis_baro_ref_capt_switch_pos		= deferred_dataref("laminar/B747/efis/baro_std/capt/switch_pos", "number")
B747DR_efis_baro_ref_fo_switch_pos			= deferred_dataref("laminar/B747/efis/baro_std/fo/switch_pos", "number")

-- Engine Type (crazytimitmtim)
B747DR_engineType                               = deferred_dataref("laminar/B747/engines/type", "number")
--*************************************************************************************--
--** 				        MAIN PROGRAM LOGIC                                       **--
--*************************************************************************************--
simConfigData = {}

function simconfig_values()
	return {
			SIM = {
					 kgs_to_lbs = 2.2046226218488,
					 lbs_to_kgs = 0.45359237,
					 weight_display_units = "KGS",  --KGS, LBS
					 irs_align_time = 600,  --Seconds
					 std_pax_weight = 120.0,  --KGS
					 baro_indicator = "IN",  --IN = 0, HPA = 1
					 baro_sync = "NO",  --Sync to CAPT
					 auto_fuel_mgmt = "NO",
					 capt_inbd = "NORM",  --EICAS = 0, NORM = 1, PFD = 2
					 capt_lwr = "NORM",  --EICAS PRI = 0, NORM = 1, ND = 2
					 fo_inbd = "NORM",  --PFD = 0, NORM = 1, EICAS = 2
					 fo_lwr = "NORM",  --ND = 0, NORM = 1, EICAS PRI = 2
			},
			PLANE = {
						model = "747-400",  --747-400, 747-400ER, 747-400F
						aircraft_type = "PASSENGER", --Passenger, Freighter
						engines = "CF6-80C2-B5F",  --PW4056, PW4060, PW4062, CF6-80C2-B1F, CF6-80C2-B5F, CF6-80C2-B1F1, RB211-524G, RB211-524H, RB211-524H8T
						thrust_ref = "EPR",  --EPR, N1  Should be N1 for GE engines
						pfd_style = "CRT",  --CRT, LCD  (used in Passenger & Combi Aircraft)
						nd_style = "CRT",  --CRT, LCD  (used in Freighter Aircraft)
						airline = "",
						civil_registration = "",
						fin_nbr = "",
			},
			FMC = {
					  INIT = {				
								nav_data = "",
								active = "",
								op_program = "",
								drag_ff = "+0.0/-0.0",
					  },
			},
	}
end

function baro_sync()
	if simConfigData["data"].SIM.baro_sync == "YES" then
		simDR_baro_fo = simDR_baro_capt
		B747DR_efis_baro_ref_fo_sel_dial_pos = B747DR_efis_baro_ref_capt_sel_dial_pos
		B747DR_efis_baro_ref_fo_switch_pos = B747DR_efis_baro_ref_capt_switch_pos
	end
end

function check_pfd_nd_style()
	if simConfigData["data"].PLANE.pfd_style == "CRT" then
		B747DR_pfd_style = 0
	elseif simConfigData["data"].PLANE.pfd_style == "LCD" then
		B747DR_pfd_style = 1
	end
	
	if simConfigData["data"].PLANE.nd_style == "CRT" then
		B747DR_nd_style = 0
	elseif simConfigData["data"].PLANE.nd_style == "LCD" then
		B747DR_nd_style = 1
	end
end

function check_thrust_ref()
	if simConfigData["data"].PLANE.thrust_ref == "EPR" then
		B747DR_thrust_ref = 0
	elseif simConfigData["data"].PLANE.thrust_ref == "N1" then
		B747DR_thrust_ref = 1
	end
end

-- crazytimtimtim
function checkEngineType()
	if string.match(simConfigData["data"].PLANE.engines, "PW") then
		B747DR_engineType = 0
	elseif string.match(simConfigData["data"].PLANE.engines, "CF") then
		B747DR_engineType = 1
	elseif string.match(simConfigData["data"].PLANE.engines, "RB") then
		B747DR_engineType = 2
	end
end

function checkAircraftType()
	if simConfigData["data"].PLANE.aircraft_type == "FREIGHTER" then
		B747DR_SNDoptions[2] = 1
		B747DR_SNDoptions[3] = 1
	end
end

-- crazytimtimtim end

function set_loaded_configs()

	--Baro
	if simConfigData["data"].SIM.baro_indicator == "IN" then
		B747DR_efis_baro_ref_capt_sel_dial_pos = 0
	elseif simConfigData["data"].SIM.baro_indicator == "HPA" then
		B747DR_efis_baro_ref_capt_sel_dial_pos = 1
	end

	if simConfigData["data"].SIM.baro_sync == "YES" then
		B747DR_efis_baro_ref_fo_sel_dial_pos = B747DR_efis_baro_ref_capt_sel_dial_pos
	end
	
	--Capt Displays
	if simConfigData["data"].SIM.capt_inbd == "EICAS" then
		B747DR_flt_inst_inbd_disp_capt_sel_dial_pos = 0
	elseif simConfigData["data"].SIM.capt_inbd == "NORM" then
		B747DR_flt_inst_inbd_disp_capt_sel_dial_pos = 1
	elseif simConfigData["data"].SIM.capt_inbd == "PFD" then
		B747DR_flt_inst_inbd_disp_capt_sel_dial_pos = 2
	end

	if simConfigData["data"].SIM.capt_lwr == "EICAS PRI" then
		B747DR_flt_inst_lwr_disp_capt_sel_dial_pos = 0
	elseif simConfigData["data"].SIM.capt_lwr == "NORM" then
		B747DR_flt_inst_lwr_disp_capt_sel_dial_pos = 1
	elseif simConfigData["data"].SIM.capt_lwr == "ND" then
		B747DR_flt_inst_lwr_disp_capt_sel_dial_pos = 2
	end

	--FO Displays
	if simConfigData["data"].SIM.fo_inbd == "PFD" then
		B747DR_flt_inst_inbd_disp_fo_sel_dial_pos = 0
	elseif simConfigData["data"].SIM.capt_inbd == "NORM" then
		B747DR_flt_inst_inbd_disp_fo_sel_dial_pos = 1
	elseif simConfigData["data"].SIM.capt_inbd == "EICAS" then
		B747DR_flt_inst_inbd_disp_fo_sel_dial_pos = 2
	end

	if simConfigData["data"].SIM.fo_lwr == "ND" then
		B747DR_flt_inst_lwr_disp_fo_sel_dial_pos = 0
	elseif simConfigData["data"].SIM.fo_lwr == "NORM" then
		B747DR_flt_inst_lwr_disp_fo_sel_dial_pos = 1
	elseif simConfigData["data"].SIM.fo_lwr == "EICAS PRI" then
		B747DR_flt_inst_lwr_disp_fo_sel_dial_pos = 2
	end

end

function aircraft_simConfig()
	local file_location = simDR_livery_path.."B747-400_simconfig.dat"
	--print("File = "..file_location)
	local file = io.open(file_location, "r")

	if file ~= nil then
		io.input(file)
		B747DR_simconfig_data = io.read()
		io.close(file)	
		
		run_after_time(set_loaded_configs, 3)  --Apply loaded configs.  Wait a few seconds to ensure they load correctly.
	end
end

simConfigData["data"]=simconfig_values()

if simDR_acf_tailnum ~= nil then
	simConfigData["data"].PLANE.fin_nbr = simDR_acf_tailnum
end

function flight_start()
	local refreshLivery=simDR_livery_path
	B747DR_simconfig_data=json.encode(simConfigData["data"]["values"]) --make the simConfig data available to other modules
	run_after_time(aircraft_simConfig, 1)  --Load specific simConfig data for current livery
end
function livery_load()
	local refreshLivery=simDR_livery_path
	run_after_time(aircraft_simConfig, 1)  --Load specific simConfig data for current livery
end
function after_physics()
	--Keep the structure fresh
	simConfigData["data"] = json.decode(B747DR_simconfig_data)

	--See if Baro's should be sync'd
	baro_sync()
	
	--PFD/ND Styles
	check_pfd_nd_style()
	
	--Thrust Ref Setting
	check_thrust_ref()

	--Engine Type
	checkEngineType()

	--Aircraft Type
	checkAircraftType()
end
