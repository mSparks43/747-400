--always record important in flight data to file 
-- mSparks June 2022
function null_command(phase, duration)
end
function deferred_command(name, desc, realFunc)
	return wrap_command(name, realFunc, null_command)
end
local lastUpdate=0
simDRTime=find_dataref("sim/time/total_running_time_sec")
B747DR_simconfig_data						= find_dataref("laminar/B747/simconfig", "string")
simDR_livery_path			= find_dataref("sim/aircraft/view/acf_livery_path")
simDR_aircraft_on_ground    = find_dataref("sim/flightmodel/failures/onground_any")
simDR_latitude				= find_dataref("sim/flightmodel/position/latitude")
simDR_longitude				= find_dataref("sim/flightmodel/position/longitude")
simDR_true_heading			= find_dataref("sim/flightmodel/position/psi")
simDR_AHARS_roll_heading_deg_pilot          	= find_dataref("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot")
simDR_AHARS_pitch_heading_deg_pilot           = find_dataref("sim/cockpit2/gauges/indicators/pitch_AHARS_deg_pilot")
simDR_mag_heading			= find_dataref("sim/cockpit/gyros/psi_ind_ahars_pilot_degm")
simDR_ground_track			= find_dataref("sim/cockpit2/gauges/indicators/ground_track_mag_pilot")
simDR_groundspeed			                      = find_dataref("sim/flightmodel2/position/groundspeed")
simDR_vvi_fpm_pilot        	                = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
simDR_autopilot_altitude_ft    		          = find_dataref("laminar/B747/autopilot/altitude_dial_ft")
simDR_pressureAlt1	                        = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
simDR_radarAlt1 = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
simDR_ind_airspeed_kts_pilot = find_dataref("laminar/B747/gauges/indicators/airspeed_kts_pilot")
simDR_GRWT=find_dataref("sim/flightmodel/weight/m_total")
simDR_fuel=find_dataref("sim/flightmodel/weight/m_fuel_total")
simDR_flap_deploy_ratio             = find_dataref("laminar/B747/cablecontrols/flap_ratio")

B747DR_ap_FMA_autothrottle_mode     	= find_dataref("laminar/B747/autopilot/FMA/autothrottle_mode")
B747DR_ap_FMA_armed_roll_mode       	= find_dataref("laminar/B747/autopilot/FMA/armed_roll_mode")
B747DR_ap_FMA_active_roll_mode      	= find_dataref("laminar/B747/autopilot/FMA/active_roll_mode")
B747DR_ap_FMA_armed_pitch_mode      	= find_dataref("laminar/B747/autopilot/FMA/armed_pitch_mode")
B747DR_ap_FMA_active_pitch_mode     	= find_dataref("laminar/B747/autopilot/FMA/active_pitch_mode")
B747DR_ap_AFDS_status_annun_pilot     = find_dataref("laminar/B747/autopilot/AFDS/status_annun_pilot")
B747DR_FMSdata=find_dataref("laminar/B747/fms/data")
--B747DR_FMSdata="{}"



B747DR_fmscurrentIndex      = find_dataref("laminar/B747/autopilot/ap_monitor/fmscurrentIndex")


simDR_autopilot_altitude_ft = find_dataref("laminar/B747/autopilot/altitude_dial_ft")



B747BR_totalDistance 			= find_dataref("laminar/B747/autopilot/dist/remaining_distance")
B747BR_eod_index 			= find_dataref("laminar/B747/autopilot/dist/eod_index", "number")
B747BR_nextDistanceInFeet 		= find_dataref("laminar/B747/autopilot/dist/next_distance_feet")
B747BR_cruiseAlt 			= find_dataref("laminar/B747/autopilot/dist/cruise_alt")
B747BR_tod				= find_dataref("laminar/B747/autopilot/dist/top_of_descent")
B747BR_todLat				= find_dataref("laminar/B747/autopilot/dist/top_of_descent_lat", "number")
B747BR_todLong				= find_dataref("laminar/B747/autopilot/dist/top_of_descent_long", "number")

fmsJson = find_dataref("xtlua/fms")

B747DR_fdr_log_json     = find_dataref("laminar/B747/fdr/json")
local fmsTable={}


dofile("json/json.lua")
local fdr_data_file=nil

function aircraft_fdrConfig()
  
  if fdr_data_file~=nil then
    print("FDR close FDR_data_file")
    fdr_data_file:close()
    fdr_data_file=nil
  end
  if simDR_livery_path~="" then
    print("FDR begin recording in "..simDR_livery_path)
    fdr_data_file = io.open( simDR_livery_path.."flight_data.jdat", "a" )
    io.output(fdr_data_file)
    io.write(B747DR_simconfig_data.."\n")
  else
    print("FDR not recording default livery")
  end
end
function data_refresh()
  local refreshLivery=simDR_livery_path
  local refreshdata=B747DR_simconfig_data
end
function livery_load()
	--print("simcongfig livery_load")
	local refreshLivery=simDR_livery_path
  run_after_time(data_refresh, 10)  --Load specific simConfig data for current livery
	run_after_time(aircraft_fdrConfig, 20)  --Load specific simConfig data for current livery
end



function decodeFlightPlan()
  if string.len(fmsJSON) >0 then
      fmsTable=json.decode(fmsJSON)
  end
  
end
function getHeading(lat1,lon1,lat2,lon2)
  b10=math.rad(lat1)
  b11=math.rad(lon1)
  b12=math.rad(lat2)
  b13=math.rad(lon2)
  retVal=math.atan2(math.sin(b13-b11)*math.cos(b12),math.cos(b10)*math.sin(b12)-math.sin(b10)*math.cos(b12)*math.cos(b13-b11))
  return math.deg(retVal)
end
function getHeadingDifference(desireddirection,current_heading)
	error = current_heading - desireddirection
	if (error >  180) then error =error- 360 end
	if (error < -180) then error =error+ 360 end
	return error
end

function getDistance(lat1,lon1,lat2,lon2)
  alat=math.rad(lat1)
  alon=math.rad(lon1)
  blat=math.rad(lat2)
  blon=math.rad(lon2)
  av=math.sin(alat)*math.sin(blat) + math.cos(alat)*math.cos(blat)*math.cos(blon-alon)
  if av > 1 then av=1 end
  retVal=math.acos(av) * 3440

  return retVal
end



debug_fdr     = find_dataref("laminar/B747/debug/fdr")
local NUM_ALERT_MESSAGES = 109
B747DR_CAS_gen_warning_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_warning_msg[i] = find_dataref(string.format("laminar/B747/CAS/gen_warning_msg_%03d", i))
end

B747DR_CAS_gen_caution_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_caution_msg[i] = find_dataref(string.format("laminar/B747/CAS/gen_caution_msg_%03d", i))
end

B747DR_CAS_gen_advisory_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_advisory_msg[i] = find_dataref(string.format("laminar/B747/CAS/gen_advisory_msg_%03d", i))
end

B747DR_CAS_gen_memo_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_memo_msg[i] = find_dataref(string.format("laminar/B747/CAS/gen_memo_msg_%03d", i))
end


function aircraft_unload()
  print("FDR aircraft unload")
  if fdr_data_file~=nil then
    print("FDR close FDR_data_file")
    fdr_data_file:close()
    fdr_data_file=nil
  end
end

local lastWarningUpdate=0
local lastcountMessages=0
function updateAPdata()
  if fdr_data_file==nil then return end
  local diff=simDRTime-lastWarningUpdate
  if diff<5 then return end
  lastWarningUpdate=simDRTime

  local countMessages=0
  local messages={}
  for i = 0, NUM_ALERT_MESSAGES do
      if B747DR_CAS_gen_warning_msg[i]~="" and B747DR_CAS_gen_warning_msg[i]~=" " then
        messages[countMessages+1]=B747DR_CAS_gen_warning_msg[i].." warning"
        countMessages=countMessages+1
      end
  end
  

  for i = 0, NUM_ALERT_MESSAGES do
      if B747DR_CAS_gen_caution_msg[i]~="" and B747DR_CAS_gen_caution_msg[i]~=" " then
        messages[countMessages+1]=B747DR_CAS_gen_caution_msg[i].." caution"
        countMessages=countMessages+1
      end
  end
  --print("countMessages "..countMessages)
  if lastcountMessages~=countMessages then
    lastcountMessages=countMessages
    local flightData={}
    flightData["time"]=os.date("%Y/%m/%d %X")
    flightData["CASDATA"]=messages
    local flightDataS=json.encode(flightData)
    --io.output(fdr_data_file)
    fdr_data_file:write(flightDataS.."\n") 
    fdr_data_file:flush()
  end
  --[[for i = 0, NUM_ALERT_MESSAGES do
      if B747DR_CAS_gen_advisory_msg[i]~=" " then
        messages[countMessages]=B747DR_CAS_gen_advisory_msg[i].." warning"
        countMessages=countMessages+1
      end
  end
  

  for i = 0, NUM_ALERT_MESSAGES do
      B747DR_CAS_gen_memo_msg[i]
  end]]--
end
local lastfmsSize=0
local lastfmsDataSize=0
local lastFMSUpdate=0
local lastPlanUpdate=0
local lastFMSIndex=-1
function updateFMSdata()
  if fdr_data_file==nil then return end
  local diff=simDRTime-lastFMSUpdate
  if diff<5 then return end
  lastFMSUpdate=simDRTime

  if(fmsJson~=nil and (string.len(fmsJson) ~=lastfmsSize or B747DR_fmscurrentIndex~=lastFMSIndex)) then
    --io.output(fdr_data_file)
    local diff=simDRTime-lastPlanUpdate
    if diff>10 then 
      fdr_data_file:write(fmsJson.."\n") 
      fdr_data_file:flush()
      print("Wrote FMS plan")
      lastPlanUpdate=simDRTime
    end
    lastfmsSize=string.len(fmsJson)
    lastFMSIndex=B747DR_fmscurrentIndex
  end
  
  if(B747DR_FMSdata~=nil and string.len(B747DR_FMSdata) ~=lastfmsDataSize) then
    --io.output(fdr_data_file)
    fdr_data_file:write(B747DR_FMSdata.."\n") 
    fdr_data_file:flush()
    lastfmsDataSize=string.len(B747DR_FMSdata)
    --print("Wrote FMS data")
  end
end
function updateFlightdata()
  if fdr_data_file==nil then return end
  if simDR_aircraft_on_ground>0 then return end
  local flightData={}
  flightData["time"]=os.date("%Y/%m/%d %X")
  flightData["flightData"]={}
  flightData["flightData"]["radarAlt"]=simDR_radarAlt1
  flightData["flightData"]["simDR_pressureAlt1"]=simDR_pressureAlt1
  flightData["flightData"]["simDR_groundspeed"]=simDR_groundspeed
  flightData["flightData"]["simDR_vvi_fpm_pilot"]=simDR_vvi_fpm_pilot
  flightData["flightData"]["simDR_true_heading"]=simDR_true_heading
  flightData["flightData"]["simDR_latitude"]=simDR_latitude
  flightData["flightData"]["simDR_longitude"]=simDR_longitude
  flightData["flightData"]["simDR_ind_airspeed_kts_pilot"]=simDR_ind_airspeed_kts_pilot
  flightData["flightData"]["roll"]=simDR_AHARS_roll_heading_deg_pilot
  flightData["flightData"]["pitch"]=simDR_AHARS_pitch_heading_deg_pilot 
  flightData["acData"]={}
  flightData["acData"]["simDR_GRWT"]=simDR_GRWT
  flightData["acData"]["simDR_fuel"]=simDR_fuel
  flightData["acData"]["flaps"]=simDR_flap_deploy_ratio
  flightData["fmaData"]={}
  flightData["fmaData"]["active"]={}
  flightData["fmaData"]["armed"]={}
  
  if B747DR_ap_FMA_autothrottle_mode == 0 then
    flightData["fmaData"]["AT"]="NONE"
  elseif B747DR_ap_FMA_autothrottle_mode == 1 then
    flightData["fmaData"]["AT"]="HOLD"
  elseif B747DR_ap_FMA_autothrottle_mode == 2 then
    flightData["fmaData"]["AT"]="IDLE"
  elseif B747DR_ap_FMA_autothrottle_mode == 3 then
    flightData["fmaData"]["AT"]="SPD"
  elseif B747DR_ap_FMA_autothrottle_mode == 4 then
    flightData["fmaData"]["AT"]="THR"
  elseif B747DR_ap_FMA_autothrottle_mode == 5 then
    flightData["fmaData"]["AT"]="THR REF"
  else
    flightData["fmaData"]["AT"]="ERROR"
  end

  if B747DR_ap_AFDS_status_annun_pilot == 0 then
    flightData["fmaData"]["status"]="NONE"
  elseif B747DR_ap_AFDS_status_annun_pilot == 1 then
    flightData["fmaData"]["status"]="FD"
  elseif B747DR_ap_AFDS_status_annun_pilot == 2 then
    flightData["fmaData"]["status"]="CMD"
  elseif B747DR_ap_AFDS_status_annun_pilot == 3 then
    flightData["fmaData"]["status"]="LAND 2"
  elseif B747DR_ap_AFDS_status_annun_pilot == 4 then
    flightData["fmaData"]["status"]="LAND 3"
  elseif B747DR_ap_AFDS_status_annun_pilot == 5 then
    flightData["fmaData"]["status"]="NO AUTOLAND"
  else
    flightData["fmaData"]["status"]="ERROR"
  end

  if B747DR_ap_FMA_armed_roll_mode == 0 then
    flightData["fmaData"]["armed"]["roll"]="NONE"
  elseif B747DR_ap_FMA_armed_roll_mode == 1 then
    flightData["fmaData"]["armed"]["roll"]="TOGA"
  elseif B747DR_ap_FMA_armed_roll_mode == 2 then
    flightData["fmaData"]["armed"]["roll"]="LNAV"
  elseif B747DR_ap_FMA_armed_roll_mode == 3 then
    flightData["fmaData"]["armed"]["roll"]="LOC"
  elseif B747DR_ap_FMA_armed_roll_mode == 4 then
    flightData["fmaData"]["armed"]["roll"]="ROLLOUT"
  elseif B747DR_ap_FMA_armed_roll_mode == 5 then
    flightData["fmaData"]["armed"]["roll"]="HDG SEL"
  elseif B747DR_ap_FMA_armed_roll_mode == 6 then
    flightData["fmaData"]["armed"]["roll"]="HDG HOLD"
  else
    flightData["fmaData"]["armed"]["roll"]="ERROR"
  end


  if B747DR_ap_FMA_active_roll_mode == 0 then
    flightData["fmaData"]["active"]["roll"]="NONE"
  elseif B747DR_ap_FMA_active_roll_mode == 1 then
    flightData["fmaData"]["active"]["roll"]="TOGA"
  elseif B747DR_ap_FMA_active_roll_mode == 2 then
    flightData["fmaData"]["active"]["roll"]="LNAV"
  elseif B747DR_ap_FMA_active_roll_mode == 3 then
    flightData["fmaData"]["active"]["roll"]="LOC"
  elseif B747DR_ap_FMA_active_roll_mode == 4 then
    flightData["fmaData"]["active"]["roll"]="ROLLOUT"
  elseif B747DR_ap_FMA_active_roll_mode == 5 then
    flightData["fmaData"]["active"]["roll"]="ATT"
  elseif B747DR_ap_FMA_active_roll_mode == 6 then
    flightData["fmaData"]["active"]["roll"]="HDG SEL"
  elseif B747DR_ap_FMA_active_roll_mode == 7 then
    flightData["fmaData"]["active"]["roll"]="HDG HOLD"
  else
    flightData["fmaData"]["active"]["roll"]="ERROR"
  end

  if B747DR_ap_FMA_armed_pitch_mode == 0 then
    flightData["fmaData"]["armed"]["pitch"]="NONE"
  elseif B747DR_ap_FMA_armed_pitch_mode == 1 then
    flightData["fmaData"]["armed"]["pitch"]="TOGA"
  elseif B747DR_ap_FMA_armed_pitch_mode == 2 then
    flightData["fmaData"]["armed"]["pitch"]="G/S"
  elseif B747DR_ap_FMA_armed_pitch_mode == 3 then
    flightData["fmaData"]["armed"]["pitch"]="FLARE"
  elseif B747DR_ap_FMA_armed_pitch_mode == 4 then
    flightData["fmaData"]["armed"]["pitch"]="VNAV"
  elseif B747DR_ap_FMA_armed_pitch_mode == 7 then
    flightData["fmaData"]["armed"]["pitch"]="V/S"
  elseif B747DR_ap_FMA_armed_pitch_mode == 8 then
    flightData["fmaData"]["armed"]["pitch"]="FLCH SPD"
  elseif B747DR_ap_FMA_armed_pitch_mode == 9 then
    flightData["fmaData"]["armed"]["pitch"]="ALT"
  else
    flightData["fmaData"]["armed"]["pitch"]="ERROR"
  end

  if B747DR_ap_FMA_active_pitch_mode == 0 then
    flightData["fmaData"]["active"]["pitch"]="NONE"
  elseif B747DR_ap_FMA_active_pitch_mode == 1 then
    flightData["fmaData"]["active"]["pitch"]="TOGA"
  elseif B747DR_ap_FMA_active_pitch_mode == 2 then
    flightData["fmaData"]["active"]["pitch"]="G/S"
  elseif B747DR_ap_FMA_active_pitch_mode == 3 then
    flightData["fmaData"]["active"]["pitch"]="FLARE"
  elseif B747DR_ap_FMA_active_pitch_mode == 4 then
    flightData["fmaData"]["active"]["pitch"]="VNAV SPD"
  elseif B747DR_ap_FMA_active_pitch_mode == 5 then
    flightData["fmaData"]["active"]["pitch"]="VNAV ALT"
  elseif B747DR_ap_FMA_active_pitch_mode == 6 then
    flightData["fmaData"]["active"]["pitch"]="VNAV PATH"
  elseif B747DR_ap_FMA_active_pitch_mode == 7 then
    flightData["fmaData"]["active"]["pitch"]="V/S"
  elseif B747DR_ap_FMA_active_pitch_mode == 8 then
    flightData["fmaData"]["active"]["pitch"]="FLCH SPD"
  elseif B747DR_ap_FMA_active_pitch_mode == 9 then
    flightData["fmaData"]["active"]["pitch"]="ALT"
  else
    flightData["fmaData"]["active"]["pitch"]="ERROR"
  end
  local diff=simDRTime-lastUpdate
  if diff>30 then 
    local flightDataS=json.encode(flightData)
    --io.output(fdr_data_file)
    fdr_data_file:write(flightDataS.."\n") 
    fdr_data_file:flush()
    lastUpdate=simDRTime
  end

end


--COMMAND LOGGING
function do_log_commmand(data)
  print(" log "..data)
  if fdr_data_file==nil then return end
  local flightData={}
  flightData["time"]=os.date("%Y/%m/%d %X")
  flightData["keyPress"]=data
  local flightDataS=json.encode(flightData)
  fdr_data_file:write(flightDataS.."\n") 
  fdr_data_file:flush()
end
function do_log_jdata(data)
  print(" log "..data)
  if fdr_data_file==nil then return end
  local flightData={}
  flightData["time"]=os.date("%Y/%m/%d %X")
  flightData["jsonlog"]=data
  local flightDataS=json.encode(flightData)
  fdr_data_file:write(flightDataS.."\n") 
  fdr_data_file:flush()
end
function B747CMD_fdr_log_lnav_CMDhandler(phase, duration)
  do_log_commmand("LNAV")
end
function B747CMD_fdr_log_vnav_CMDhandler(phase, duration)
  do_log_commmand("VNAV")
end
function B747CMD_fdr_log_apon_CMDhandler(phase, duration)
  do_log_commmand("AP ON")
end
function B747CMD_fdr_log_apdisconnect_CMDhandler(phase, duration)
  do_log_commmand("AP DISCONNECT")
end
function B747CMD_fdr_log_flch_CMDhandler(phase, duration)
  do_log_commmand("FLCH")
end
function B747CMD_fdr_log_vs_CMDhandler(phase, duration)
  do_log_commmand("VS")
end
function B747CMD_fdr_log_alt_CMDhandler(phase, duration)
  do_log_commmand("ALT HOLD")
end
function B747CMD_fdr_log_toga_CMDhandler(phase, duration)
  do_log_commmand("TOGA")
end
function B747CMD_fdr_log_loc_CMDhandler(phase, duration)
  do_log_commmand("LOC")
end
function B747CMD_fdr_log_app_CMDhandler(phase, duration)
  do_log_commmand("APP")
end
function B747CMD_fdr_log_altmod_CMDhandler(phase, duration)
  do_log_commmand("VNAV RESUME")
end
function B747CMD_fdr_log_spdmod_CMDhandler(phase, duration)
  do_log_commmand("SPD INTERVENTION")
end
function B747CMD_fdr_log_spd_CMDhandler(phase, duration)
  do_log_commmand("SPD")
end
function B747CMD_fdr_log_headsel_CMDhandler(phase, duration)
  do_log_commmand("HEADING SELECT")
end
function B747CMD_fdr_log_headhold_CMDhandler(phase, duration)
  do_log_commmand("HEADING HOLD")
end
B747CMD_fdr_log_lnav           = deferred_command("laminar/B747/fdr/lnav", "", B747CMD_fdr_log_lnav_CMDhandler) --autopilot
B747CMD_fdr_log_vnav           = deferred_command("laminar/B747/fdr/vnav", "", B747CMD_fdr_log_vnav_CMDhandler) --autopilot
B747CMD_fdr_log_apon           = deferred_command("laminar/B747/fdr/apon", "", B747CMD_fdr_log_apon_CMDhandler) --autopilot
B747CMD_fdr_log_apdisconnect           = deferred_command("laminar/B747/fdr/apdisconnect", "", B747CMD_fdr_log_apdisconnect_CMDhandler) --autopilot
B747CMD_fdr_log_flch           = deferred_command("laminar/B747/fdr/flch", "", B747CMD_fdr_log_flch_CMDhandler) --autopilot
B747CMD_fdr_log_vs           = deferred_command("laminar/B747/fdr/vs", "", B747CMD_fdr_log_vs_CMDhandler) --autopilot
B747CMD_fdr_log_alt           = deferred_command("laminar/B747/fdr/alt", "", B747CMD_fdr_log_alt_CMDhandler) --autopilot
B747CMD_fdr_log_toga           = deferred_command("laminar/B747/fdr/toga", "", B747CMD_fdr_log_toga_CMDhandler) --engines
B747CMD_fdr_log_loc           = deferred_command("laminar/B747/fdr/loc", "", B747CMD_fdr_log_loc_CMDhandler) --autopilot
B747CMD_fdr_log_app           = deferred_command("laminar/B747/fdr/app", "", B747CMD_fdr_log_app_CMDhandler) --autopilot
B747CMD_fdr_log_altmod           = deferred_command("laminar/B747/fdr/altmod", "", B747CMD_fdr_log_altmod_CMDhandler) --autopilot
B747CMD_fdr_log_spdmod           = deferred_command("laminar/B747/fdr/spdmod", "", B747CMD_fdr_log_spdmod_CMDhandler)
B747CMD_fdr_log_spd           = deferred_command("laminar/B747/fdr/spd", "", B747CMD_fdr_log_spd_CMDhandler)
B747CMD_fdr_log_headsel           = deferred_command("laminar/B747/fdr/headsel", "", B747CMD_fdr_log_headsel_CMDhandler)
B747CMD_fdr_log_headhold          = deferred_command("laminar/B747/fdr/headhold", "", B747CMD_fdr_log_headhold_CMDhandler)
function updateJSONData()
  if(string.len(B747DR_fdr_log_json) > 2) then
    local fdrData=B747DR_fdr_log_json
    do_log_jdata(fdrData)
    --print("log" .. fdrData)
    B747DR_fdr_log_json=" "
  end
end

function after_physics()
  collectgarbage("collect")
  if debug_fdr>0 then return end
  --if simDR_aircraft_on_ground>0 then return end

  updateJSONData()
  updateAPdata()
  updateFlightdata()
  updateFMSdata()
  
end 
