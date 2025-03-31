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

--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--
-- Holds all SimConfig options
B747DR_simconfig_data						= deferred_dataref("laminar/B747/simconfig", "string")
B747DR_newsimconfig_data					= deferred_dataref("laminar/B747/newsimconfig", "number")
B747DR_is_freighter          				= deferred_dataref("laminar/B747/freighter", "number")
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
B747DR_hideGE						= deferred_dataref("laminar/B747/engines/hideGE", "number") 
B747DR_hideRR						= deferred_dataref("laminar/B747/engines/hideRR", "number")
B747DR_hidePW						= deferred_dataref("laminar/B747/engines/hidePW", "number") 
--silvereagle to end
-- Misc.
B747DR_fmc_spill_lights						= deferred_dataref("laminar/B747/fmc/spill_lights", "number")
B747DR_fmc_cockpit_seats_hide				= deferred_dataref("laminar/B747/fmc/cockpit_seats_hide", "number")
--silvereagle end

B747DR_SNDoptions			        	= deferred_dataref("laminar/B747/fmod/options", "array[7]")
--B747DR_SNDoptions_volume				= deferred_dataref("laminar/B747/fmod/options/volume", "array[8]")
B747DR_SNDoptions_gpws					= deferred_dataref("laminar/B747/fmod/options/gpws", "array[16]")
B747DR_modernAlarms						= deferred_dataref("laminar/B747/fmod/options/modernAlarms", "number")

B747DR_acarsProvider						= deferred_dataref("laminar/B747/acars/systemProvider", "number")
--*************************************************************************************--
--** 				        MAIN PROGRAM LOGIC                                       **--
--*************************************************************************************--
simConfigData = {}
dofile("version.lua")
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
					 spill_lights = "NORM", --HI = 1, NORM = 0 --silvereagle
					 cockpit_seats_hide = "SHOW", --SHOW = 0 (default), HIDE = 1, (Useful to hide cockpit seats when using 3 monitors and the seats are in the way of viewing the instrument panel.) --silvereagle
			},
			PLANE = {
						model = "747-400",  --747-400, 747-400ER, 747-400F
						aircraft_type = "PASSENGER", --Passenger, Freighter
						engines = "PW4056",  --PW4056, PW4060, PW4062, CF6-80C2-B1F, CF6-80C2-B5F, CF6-80C2-B1F1, RB211-524G, RB211-524H, RB211-524H8T
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
								op_program = fmcVersion,
								drag_ff = "+0.0/-0.0",
					  },
			},
			SOUND = { --default 0 on
				alarmsOption = 0,
				seatBeltOption = 0,
				paOption = 0,
				musicOption = 0,  --EPR, N1  Should be N1 for GE engines
				PM_toggle = 0,  --CRT, LCD  (used in Passenger & Combi Aircraft)
				V1Option = 0,  --CRT, LCD  (used in Freighter Aircraft)
				GPWSminimums = 0,
				GPWSapproachingMinimums = 0,
				GPWS2500 = 0,
				GPWS1000 =0,
				GPWS500 = 0,
				GPWS400 = 0,
				GPWS300 = 0,
				GPWS200 = 0,
				GPWS100 = 0,
				GPWS50 = 0,
				GPWS40 = 0,
				GPWS30 = 0,
				GPWS20 = 0,
				GPWS10 = 0,
				GPWS5 = 0
			}
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
	if string.match(simConfigData["data"].PLANE.engines, "PW") or string.match(simConfigData["data"].PLANE.engines, "RB") then --  simConfigData["data"].PLANE.thrust_ref == "EPR" then
		B747DR_thrust_ref = 0
	elseif string.match(simConfigData["data"].PLANE.engines, "CF6") then --simConfigData["data"].PLANE.thrust_ref == "N1" then
		B747DR_thrust_ref = 1
	else --Asssume EPR if all else fails
		B747DR_thrust_ref = 0
	end
end

-- crazytimtimtim
function checkEngineType()
	if string.match(simConfigData["data"].PLANE.engines, "PW") then
		B747DR_engineType = 0
		B747DR_hideGE=0
		B747DR_hideRR=1
		B747DR_hidePW=1
	elseif string.match(simConfigData["data"].PLANE.engines, "CF") then
		B747DR_engineType = 1
		B747DR_hideGE=0
		B747DR_hideRR=1
		B747DR_hidePW=1
	elseif string.match(simConfigData["data"].PLANE.engines, "RB") then
		B747DR_engineType = 2
		B747DR_hideGE=1
		B747DR_hideRR=0
		B747DR_hidePW=1
	else --Assume PW if all else fails
		B747DR_engineType = 0
		B747DR_hideGE=0
		B747DR_hideRR=1
		B747DR_hidePW=1
	end
end
-- crazytimtimtim end
function setSoundOption(key,value) 

	if key == "alarmsOption" then
		B747DR_SNDoptions[0] = value
	end

	if key == "seatBeltOption" then 
		B747DR_SNDoptions[1] = value
		return 
	end
	if key == "paOption" then 
		B747DR_SNDoptions[2] = value
		return 
	end
	if key == "musicOption" then 
		B747DR_SNDoptions[3] = value
		return 
	end
	if key == "PM_toggle" then 
		B747DR_SNDoptions[4] = value
		return 
	end
	if key == "V1Option" then B747DR_SNDoptions[5] = value return end

	if key == "GPWSminimums" then B747DR_SNDoptions_gpws[1] = value return end
	if key == "GPWSapproachingMinimums" then B747DR_SNDoptions_gpws[2] = value return end
	if key == "GPWS2500" then B747DR_SNDoptions_gpws[3] = value return end
	if key == "GPWS1000" then B747DR_SNDoptions_gpws[4] = value return end
	if key == "GPWS500" then B747DR_SNDoptions_gpws[5] = value return end
	if key == "GPWS400" then B747DR_SNDoptions_gpws[6] = value return end
	if key == "GPWS300" then B747DR_SNDoptions_gpws[7] = value return end
	if key == "GPWS200" then B747DR_SNDoptions_gpws[8] = value return end
	if key == "GPWS100" then B747DR_SNDoptions_gpws[9] = value return end
	if key == "GPWS50" then B747DR_SNDoptions_gpws[10] = value return end
	if key == "GPWS40" then B747DR_SNDoptions_gpws[11] = value return end
	if key == "GPWS30" then B747DR_SNDoptions_gpws[12] = value return end
	if key == "GPWS20" then B747DR_SNDoptions_gpws[13] = value return end
	if key == "GPWS10" then B747DR_SNDoptions_gpws[14] = value return end
	if key == "GPWS5" then B747DR_SNDoptions_gpws[15] = value return end

end
function set_loaded_configs()
	B747DR_modernAlarms = 1
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
	
	--silvereagle to end
	if simConfigData["data"].SIM.spill_lights == "NORM" or simConfigData["data"].SIM.spill_lights == null then
		B747DR_fmc_spill_lights = 0
	else
		B747DR_fmc_spill_lights = 1
	end

	if simConfigData["data"].SIM.cockpit_seats_hide == "SHOW" or simConfigData["data"].SIM.cockpit_seats_hide == null then
		B747DR_fmc_cockpit_seats_hide = 0
	else
		B747DR_fmc_cockpit_seats_hide = 1
	end
	--silvereagle end

	if simConfigData["data"].SIM.acarsProvider == "AUTOATC" or simConfigData["data"].SIM.acarsProvider == null then
		B747DR_acarsProvider=0
	else
		B747DR_acarsProvider=1
	end

	for key, value in pairs(simConfigData["data"].SOUND) do
		setSoundOption(key,value)
	end
	if simConfigData["data"].PLANE.aircraft_type ~= "PASSENGER" then
		B747DR_is_freighter= 1
	else
		B747DR_is_freighter= 0
	end
	print("B747DR_is_freighter="..B747DR_is_freighter)
	B747DR_newsimconfig_data=0
end

function aircraft_simConfig()
	local file_location = simDR_livery_path.."B747-400_simconfig.dat"
	print("File = "..file_location)
	local file = io.open(file_location, "r")

	if file ~= nil then
		io.input(file)
		local tmpDataS = io.read()
		io.close(file)
		--print("read "..tmpDataS)
		local tmpData=json.decode(tmpDataS)
		if (tmpData["SOUND"]==nil) then
			tmpData["SOUND"]=simconfig_values()["SOUND"]
		end
		tmpData.FMC.INIT.op_program = fmcVersion
		--print("encoding "..tmpDataS)
		B747DR_simconfig_data = json.encode(tmpData)
		--print("done encoding "..B747DR_simconfig_data)
		B747DR_newsimconfig_data=1
		run_after_time(set_loaded_configs, 3)  --Apply loaded configs.  Wait a few seconds to ensure they load correctly.
	else
		B747DR_simconfig_data = json.encode(simconfig_values())
		run_after_time(set_loaded_configs, 3)  --Apply loaded configs.  Wait a few seconds to ensure they load correctly.
	end

end

simConfigData["data"]=simconfig_values()

if simDR_acf_tailnum ~= nil then
	simConfigData["data"].PLANE.fin_nbr = simDR_acf_tailnum
end

local flightInit=false
function flight_start()
    flightInit=false
end
function do_flight_start()
	local refreshLivery=simDR_livery_path
	B747DR_simconfig_data=json.encode(simConfigData["data"]["values"]) --make the simConfig data available to other modules
	B747DR_newsimconfig_data=1
	run_after_time(aircraft_simConfig, 1)  --Load specific simConfig data for current livery
end
function livery_load()
	--print("simcongfig livery_load")
	local refreshLivery=simDR_livery_path
	B747DR_newsimconfig_data=1
	run_after_time(aircraft_simConfig, 2)  --Load specific simConfig data for current livery
end

local setSimConfig=false
function hasSimConfig()
	if B747DR_newsimconfig_data==1 then
		if string.len(B747DR_simconfig_data) > 1 then
			
			simConfigData["data"] = json.decode(B747DR_simconfig_data)
			setSimConfig=true
		else
			return false
		end
	end
	return setSimConfig
end
function after_physics()
	--Keep the structure fresh
	--print("in simconfig "..B747DR_simconfig_data)
	if flightInit==false then
        do_flight_start()
    end
    flightInit=true
	if hasSimConfig()==false then return end


	--See if Baro's should be sync'd
	baro_sync()
	
	--PFD/ND Styles
	check_pfd_nd_style()
	
	--Thrust Ref Setting
	check_thrust_ref()

	--Engine Type
	checkEngineType()
end
