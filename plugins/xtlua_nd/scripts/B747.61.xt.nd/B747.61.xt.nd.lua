--Read out and set displays for ND icons
-- (C) Mark 'mSparks' Parker 2020 CCBYNC4 release
-- Small changes by Matt726
simDR_version=find_dataref("sim/version/xplane_internal_version")
simDR_tcas_lat                = find_dataref("sim/cockpit2/tcas/targets/position/lat")
simDR_tcas_lon                = find_dataref("sim/cockpit2/tcas/targets/position/lon")
simDR_radarAlt1 = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
simDR_tcas_vs                = find_dataref("sim/cockpit2/tcas/targets/position/vertical_speed")
simDR_radio_nav03_ID                = find_dataref("sim/cockpit2/radios/indicators/nav3_nav_id")
simDR_radio_nav04_ID                = find_dataref("sim/cockpit2/radios/indicators/nav4_nav_id")
B747DR_text_capt_show 				= find_dataref("laminar/B747/nd/capt/text/show")
B747DR_text_capt_heading			= find_dataref("laminar/B747/nd/capt/text/heading")
B747DR_text_capt_distance			= find_dataref("laminar/B747/nd/capt/text/distance")
--B747DR_text_capt_icon				= find_dataref("laminar/B747/nd/capt/text/icon","array[60]")
B747DR_nd_mode_capt_sel_dial_pos                = find_dataref("laminar/B747/nd/mode/capt/sel_dial_pos", "number")
B747DR_nd_mode_fo_sel_dial_pos                  = find_dataref("laminar/B747/nd/mode/fo/sel_dial_pos", "number")
B747DR_text_fo_show 				= find_dataref("laminar/B747/nd/fo/text/show")
B747DR_text_fo_heading			= find_dataref("laminar/B747/nd/fo/text/heading")
B747DR_text_fo_distance			= find_dataref("laminar/B747/nd/fo/text/distance")
--B747DR_text_fo_icon				= find_dataref("laminar/B747/nd/fo/text/icon","array[60]")
B747DR_fmscurrentIndex      = find_dataref("laminar/B747/autopilot/ap_monitor/fmscurrentIndex")
B747BR_totalDistance 			= find_dataref("laminar/B747/autopilot/dist/remaining_distance")
B747BR_eod_index 			= find_dataref("laminar/B747/autopilot/dist/eod_index")
B747BR_nextDistanceInFeet 		= find_dataref("laminar/B747/autopilot/dist/next_distance_feet")
B747BR_cruiseAlt 			= find_dataref("laminar/B747/autopilot/dist/cruise_alt")
B747BR_tod				= find_dataref("laminar/B747/autopilot/dist/top_of_descent")
B747BR_todLat				= find_dataref("laminar/B747/autopilot/dist/top_of_descent_lat")
B747BR_todLong				= find_dataref("laminar/B747/autopilot/dist/top_of_descent_long")
B747BR_tocLat				= find_dataref("laminar/B747/autopilot/dist/top_of_climb_lat")
B747BR_tocLong				= find_dataref("laminar/B747/autopilot/dist/top_of_climb_long")
B747BR_toc				= find_dataref("laminar/B747/autopilot/dist/distance_to_toc")
B747DR_ap_FMA_active_pitch_mode     	= find_dataref("laminar/B747/autopilot/FMA/active_pitch_mode")
simDR_autopilot_vs_fpm = find_dataref("sim/cockpit2/autopilot/vvi_dial_fpm")
simDR_autopilot_alt_hold_status = find_dataref("laminar/B747/autopilot/altitude_hold_status")
iconTextDataCapt={}
iconTextDataCapt.icons=find_dataref("laminar/B747/nd/capt/text/icon")
for n=0,59,1 do
  iconTextDataCapt[n]={}
  iconTextDataCapt[n].whitetext=find_dataref("laminar/B747/nd/capt/text/whitetext"..n)
  iconTextDataCapt[n].bluetext=find_dataref("laminar/B747/nd/capt/text/bluetext"..n)
  iconTextDataCapt[n].redtext=find_dataref("laminar/B747/nd/capt/text/redtext"..n)
  iconTextDataCapt[n].greentext=find_dataref("laminar/B747/nd/capt/text/greentext"..n)
end

iconTextDataFO={}
iconTextDataFO.icons=find_dataref("laminar/B747/nd/fo/text/icon")
for n=0,59,1 do
  iconTextDataFO[n]={}
  iconTextDataFO[n].whitetext=find_dataref("laminar/B747/nd/fo/text/whitetext"..n)
  iconTextDataFO[n].bluetext=find_dataref("laminar/B747/nd/fo/text/bluetext"..n)
  iconTextDataFO[n].redtext=find_dataref("laminar/B747/nd/fo/text/redtext"..n)
  iconTextDataFO[n].greentext=find_dataref("laminar/B747/nd/fo/text/greentext"..n)
end

navAidsJSON   = find_dataref("xtlua/navaids")
fmsJSON = find_dataref("xtlua/fms")
simDRTime=find_dataref("sim/time/total_running_time_sec")
simDR_latitude				= find_dataref("sim/flightmodel/position/latitude")
simDR_longitude				= find_dataref("sim/flightmodel/position/longitude")
simDR_true_heading			= find_dataref("sim/flightmodel/position/psi")
simDR_mag_heading			= find_dataref("sim/cockpit/gyros/psi_ind_ahars_pilot_degm")
simDR_ground_track			= find_dataref("sim/cockpit2/gauges/indicators/ground_track_mag_pilot")
simDR_heading_track			= find_dataref("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot")
B747DR_nd_terr_weather_capt                  		= find_dataref("laminar/B747/nd/terr_weather/capt")
B747DR_nd_terr_weather_fo                  		= find_dataref("laminar/B747/nd/terr_weather/fo")
B747DR_nd_capt_terr                          = find_dataref("laminar/B747/nd/data/capt/terr")
B747DR_nd_fo_terr                          	= find_dataref("laminar/B747/nd/data/fo/terr")
simDR_EFIS_wxr_on                   = find_dataref("sim/cockpit2/EFIS/EFIS_weather_on")
simDR_EFIS_wxr_on_copilot           = find_dataref("sim/cockpit2/EFIS/EFIS_weather_on_copilot")
B747DR_nd_capt_up                  		= find_dataref("laminar/B747/nd/up/capt")
B747DR_nd_fo_up                  		= find_dataref("laminar/B747/nd/up/fo")

simDR_map_range				= find_dataref("sim/cockpit2/EFIS/map_range")
simDR_map_mode				= find_dataref("sim/cockpit2/EFIS/map_mode")
simDR_map_range_copilot				= find_dataref("sim/cockpit2/EFIS/map_range_copilot")
simDR_map_mode_copilot				= find_dataref("sim/cockpit2/EFIS/map_mode_copilot")
backport_map_mode_copilot = 0
backport_map_range_copilot = 0
simDR_range_dial_capt			= find_dataref("laminar/B747/nd/range/capt/sel_dial_pos")
simDR_range_dial_fo			= find_dataref("laminar/B747/nd/range/fo/sel_dial_pos")
B747_nd_map_center_capt                 = find_dataref("laminar/B747/nd/map_center/capt")
B747_nd_map_center_fo                   = find_dataref("laminar/B747/nd/map_center/fo")
B747DR_nd_capt_vor_ndb                  = find_dataref("laminar/B747/nd/data/capt/vor_ndb")
B747DR_nd_fo_vor_ndb                    = find_dataref("laminar/B747/nd/data/fo/vor_ndb")
B747DR_nd_capt_wpt                  = find_dataref("laminar/B747/nd/data/capt/wpt")
B747DR_nd_fo_wpt                    = find_dataref("laminar/B747/nd/data/fo/wpt")
B747DR_nd_capt_apt	                = find_dataref("laminar/B747/nd/data/capt/apt")
B747DR_nd_fo_apt	                = find_dataref("laminar/B747/nd/data/fo/apt")
B747DR_pfd_mode_capt		 = find_dataref("laminar/B747/pfd/capt/irs")
B747DR_pfd_mode_fo		 = find_dataref("laminar/B747/pfd/fo/irs")
B747DR_nd_capt_tfc	                        = find_dataref("laminar/B747/nd/capt/tfc")
B747DR_nd_fo_tfc	                        = find_dataref("laminar/B747/nd/fo/tfc")

simDR_groundspeed			                      = find_dataref("sim/flightmodel2/position/groundspeed")
simDR_vvi_fpm_pilot        	                = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
simDR_autopilot_altitude_ft    		          = find_dataref("laminar/B747/autopilot/altitude_dial_ft") -- alternate might better MCP which is B747DR_autopilot_altitude_ft
simDR_pressureAlt1	                        = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
--B747DR_nd_alt_distance                  		= find_dataref("laminar/B747/nd/toc/distance")
B747DR_nd_alt_distance_fo                  		= find_dataref("laminar/B747/nd/toc/distance/fo")
B747DR_nd_alt_distance_capt                  		= find_dataref("laminar/B747/nd/toc/distance/capt")
B747DR_nd_alt_fo_active			                = find_dataref("laminar/B747/nd/toc/fo_active")
B747DR_nd_alt_capt_active			              = find_dataref("laminar/B747/nd/toc/capt_active")

local captIRS=0
local foIRS=0
local ranges = {10, 20, 40, 80, 160, 320, 640}
local usedNaviadsTableFO={}
local usedNaviadsTableCapt={}
local currentNaviadsTable={}
local fmsTable={}
local lastCaptNavaid=0
local lastFONavaid=0
local lastUpdate=0
local lastUpdateIcon=0
local lastUpdateFixes=0
local nLength=0
local numFixes=0
local localFixes={}
local scansize=1000
dofile("json/json.lua")
dofile("numberlua.lua")
function livery_load()
  scansize=1000
end

function decodeNAVAIDS()
  if string.len(navAidsJSON) ~= nLength then
      currentNaviadsTable=json.decode(navAidsJSON)
      nLength=string.len(navAidsJSON)
  end
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
  --print(lat1.." "..lon1.." "..lat2.." "..lon2)
  --print("Distance = "..retVal) 
  return retVal
end
function makeIcon(iconTextData,navtype,text,latitude,longitude,distance)
  if text~=nil and string.lower(text)~="latlong" and iconTextData==iconTextDataCapt and usedNaviadsTableCapt[text]~=nil then return end
  if text~=nil and string.lower(text)~="latlong" and iconTextData==iconTextDataFO and usedNaviadsTableFO[text]~=nil then return end
  if text~=nil and string.lower(text)=="latlong" then text=" " end
  if text~=nil and string.lower(text)=="latlon" then text=" " end
  local abs_heading=getHeading(simDR_latitude,simDR_longitude,latitude,longitude)
  local heading_diff=0
  if iconTextData==iconTextDataCapt then
    if simDR_map_mode==2 then
      mag_diff=getHeadingDifference(simDR_true_heading,simDR_mag_heading)
      heading_diff=getHeadingDifference(simDR_ground_track-mag_diff,abs_heading)
    else
      heading_diff=getHeadingDifference(simDR_true_heading,abs_heading)
    end
  else
    if backport_map_mode_copilot==2 then
      mag_diff=getHeadingDifference(simDR_true_heading,simDR_mag_heading)
      heading_diff=getHeadingDifference(simDR_ground_track-mag_diff,abs_heading)
    else
      heading_diff=getHeadingDifference(simDR_true_heading,abs_heading)
    end
  end
  
  local lastNavaid=0
  local vor_ndb=0
  local wpt=0
  local apt=0
  local displayDistance=0
  local range=0
  if iconTextData==iconTextDataCapt then
    if captIRS==0 then return end
    range=ranges[simDR_range_dial_capt + 1]
    displayDistance=distance*(640/ranges[simDR_range_dial_capt + 1])
    if (heading_diff < -135 or heading_diff > 135) and displayDistance> 160 and B747_nd_map_center_capt<1 then return end
    if displayDistance> 250 and B747_nd_map_center_capt>0 then return end
    if (heading_diff < -45 or heading_diff > 45) and displayDistance> 480 and B747_nd_map_center_capt<1 then return end
    if (heading_diff < -55 or heading_diff > 55) and displayDistance> 400 and B747_nd_map_center_capt<1 then return end
    lastNavaid=lastCaptNavaid
    apt=B747DR_nd_capt_apt
    vor_ndb=B747DR_nd_capt_vor_ndb
    wpt=B747DR_nd_capt_wpt
  else
    if foIRS==0 then return end
    range=ranges[simDR_range_dial_fo + 1]
    displayDistance=distance*(640/ranges[simDR_range_dial_fo + 1])
    if (heading_diff < -135 or heading_diff > 135) and displayDistance> 160 and B747_nd_map_center_fo<1 then return end 
     if displayDistance> 250 and B747_nd_map_center_fo>0 then return end
     if (heading_diff < -45 or heading_diff > 45) and displayDistance> 480 and B747_nd_map_center_fo<1 then return end
     if (heading_diff < -55 or heading_diff > 55) and displayDistance> 400 and B747_nd_map_center_fo<1 then return end
    lastNavaid=lastFONavaid
    apt=B747DR_nd_fo_apt
    vor_ndb=B747DR_nd_fo_vor_ndb
    wpt=B747DR_nd_fo_wpt
  end
  
  if lastNavaid > 59 then return end
  
  if navtype==1 and apt>0 then --airport
    iconTextData.icons[lastNavaid]=2
    iconTextData[lastNavaid].bluetext=text
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==3003 then --current FMS waypoint
    iconTextData.icons[lastNavaid]=4
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].redtext=text
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==3005 then --non current FMS waypoint
    iconTextData.icons[lastNavaid]=5
    iconTextData[lastNavaid].whitetext=text
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==3006 then --white tcas no vspeed
    iconTextData.icons[lastNavaid]=22
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" " 
  elseif (navtype==3007) then --FIX
    if range>40 or wpt==0 then return end
    iconTextData.icons[lastNavaid]=13
    iconTextData[lastNavaid].bluetext=text
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" " 
  elseif (navtype==3008) then --TOD
    iconTextData.icons[lastNavaid]=8
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].whitetext=" " 
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=text 
  elseif bit_and(navtype,4)>0 and vor_ndb>0 then
    iconTextData.icons[lastNavaid]=11
    if text==simDR_radio_nav03_ID or text==simDR_radio_nav04_ID then
      iconTextData.icons[lastNavaid]=10
      iconTextData[lastNavaid].bluetext=" "
      iconTextData[lastNavaid].greentext=text
    else
      iconTextData.icons[lastNavaid]=11
      iconTextData[lastNavaid].bluetext=text
      iconTextData[lastNavaid].greentext=" "
    end
    
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].redtext=" "
    
  elseif navtype==2 and vor_ndb>0 then
    iconTextData.icons[lastNavaid]=0
    iconTextData[lastNavaid].bluetext=text
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" " 
  else
    return
  end
  iconTextData[lastNavaid].latitude=latitude
  iconTextData[lastNavaid].longitude=longitude
  if iconTextData==iconTextDataCapt then
    B747DR_text_capt_show[lastNavaid]=1
    B747DR_text_capt_heading[lastNavaid]=heading_diff
    B747DR_text_capt_distance[lastNavaid]=displayDistance
    lastCaptNavaid=lastCaptNavaid+1
    if text~=nil then usedNaviadsTableCapt[text]=true end
  else
     B747DR_text_fo_show[lastNavaid]=1
     B747DR_text_fo_heading[lastNavaid]=heading_diff
     B747DR_text_fo_distance[lastNavaid]=displayDistance
     lastFONavaid=lastFONavaid+1
     if text~=nil then usedNaviadsTableFO[text]=true end
  end
  
end

function updateIcon(iconData,n,isCaptain)
   local distance = getDistance(simDR_latitude,simDR_longitude,iconData[n].latitude,iconData[n].longitude)
  local abs_heading=getHeading(simDR_latitude,simDR_longitude,iconData[n].latitude,iconData[n].longitude)
  local heading_diff=0
  if (simDR_map_mode==2 and isCaptain==1) or (backport_map_mode_copilot==2 and isCaptain==0) then
    mag_diff=getHeadingDifference(simDR_true_heading,simDR_mag_heading)
    heading_diff=getHeadingDifference(simDR_ground_track-mag_diff,abs_heading)
  else
    heading_diff=getHeadingDifference(simDR_true_heading,abs_heading)
  end
  if isCaptain==1 then
    displayDistance=distance*(640/ranges[simDR_range_dial_capt + 1])
    B747DR_text_capt_heading[n]=heading_diff
    B747DR_text_capt_distance[n]=displayDistance
  else
     displayDistance=distance*(640/ranges[simDR_range_dial_fo + 1])
     B747DR_text_fo_heading[n]=heading_diff
     B747DR_text_fo_distance[n]=displayDistance

  end
end
function updateIcons()
  for n=0,lastCaptNavaid,1 do
    if B747DR_text_capt_show[n]==0 then break end
    updateIcon(iconTextDataCapt,n,1)
  end
  for n=0,lastFONavaid,1 do
    if B747DR_text_fo_show[n]==0 then break end
    updateIcon(iconTextDataFO,n,0)
  end
end

function newIcons()
  lastCaptNavaid=0
  lastFONavaid=0
  captIRS=B747DR_pfd_mode_capt
  foIRS=B747DR_pfd_mode_fo
  if simDR_map_mode==4 then
    for n=0,59,1 do
    B747DR_text_capt_show[n]=0
    B747DR_text_fo_show[n]=0
    end
    return
  end
  usedNaviadsTableCapt={}
  usedNaviadsTableFO={}
  --flightplan
  local start=B747DR_fmscurrentIndex-1
  if start<1 then start=1 end

  for n=start,table.getn(fmsTable),1 do
    local distance = getDistance(simDR_latitude,simDR_longitude,fmsTable[n][5],fmsTable[n][6])
    --Captain flightplan
    if distance < ranges[simDR_range_dial_capt + 1] and simDR_map_mode==2 then 

      if fmsTable[n][10]==true then
	      makeIcon(iconTextDataCapt,3003,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      else
	      makeIcon(iconTextDataCapt,3005,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      end
    end
    --FO flightplan
    if distance < ranges[simDR_range_dial_fo + 1] and backport_map_mode_copilot==2 then 

      if fmsTable[n][10]==true then
	      makeIcon(iconTextDataFO,3003,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      else
	      makeIcon(iconTextDataFO,3005,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      end
    end
  end
  --TODs
  if B747BR_cruiseAlt>0 and B747BR_totalDistance-B747BR_tod>-3 then
    local toddist=getDistance(simDR_latitude,simDR_longitude,B747BR_todLat,B747BR_todLong)
    if B747DR_nd_mode_capt_sel_dial_pos==2 then
      if toddist < ranges[simDR_range_dial_capt + 1] and simDR_radarAlt1>5000 then 
        makeIcon(iconTextDataCapt,3008,"T/D",B747BR_todLat,B747BR_todLong,toddist)
      end
    end
    if B747DR_nd_mode_fo_sel_dial_pos==2 then
      if toddist < ranges[simDR_range_dial_fo + 1] and simDR_radarAlt1>5000 then 
        makeIcon(iconTextDataFO,3008,"T/D",B747BR_todLat,B747BR_todLong,toddist)
      end
    end
  end
  --TOCs
  if B747BR_cruiseAlt>0 and B747BR_toc>0 then
    local tocdist=getDistance(simDR_latitude,simDR_longitude,B747BR_tocLat,B747BR_tocLong)
    if B747DR_nd_mode_capt_sel_dial_pos==2 then
      if tocdist < ranges[simDR_range_dial_capt + 1] and simDR_radarAlt1>-5000 then 
        makeIcon(iconTextDataCapt,3008,"T/C",B747BR_tocLat,B747BR_tocLong,tocdist)
      end
    end
    if B747DR_nd_mode_fo_sel_dial_pos==2 then
      if tocdist < ranges[simDR_range_dial_fo + 1] and simDR_radarAlt1>-5000 then 
        makeIcon(iconTextDataFO,3008,"T/C",B747BR_tocLat,B747BR_tocLong,tocdist)
      end
    end
  end
  --TCAS
  for n=1,64,1 do
    local distance = getDistance(simDR_latitude,simDR_longitude,simDR_tcas_lat[n],simDR_tcas_lon[n])
    if B747DR_nd_capt_tfc>0 and distance < ranges[simDR_range_dial_capt + 1] then 
      makeIcon(iconTextDataCapt,3006,nil,simDR_tcas_lat[n],simDR_tcas_lon[n],distance)
    end
    if B747DR_nd_fo_tfc>0 and distance < ranges[simDR_range_dial_fo + 1] then 
      makeIcon(iconTextDataFO,3006,nil,simDR_tcas_lat[n],simDR_tcas_lon[n],distance)
    end
  end  

  --NAVAIDS
  for n=table.getn(currentNaviadsTable),1,-1 do
    local distance = getDistance(simDR_latitude,simDR_longitude,currentNaviadsTable[n][5],currentNaviadsTable[n][6])
    if distance < ranges[simDR_range_dial_capt + 1] then 
      makeIcon(iconTextDataCapt,currentNaviadsTable[n][2],currentNaviadsTable[n][8],currentNaviadsTable[n][5],currentNaviadsTable[n][6],distance)
    end
    if distance < ranges[simDR_range_dial_fo + 1] then 
      makeIcon(iconTextDataFO,currentNaviadsTable[n][2],currentNaviadsTable[n][8],currentNaviadsTable[n][5],currentNaviadsTable[n][6],distance)
    end
  end
  --FIXES
  for n=1,numFixes do
    local distance = getDistance(simDR_latitude,simDR_longitude,localFixes[n]["lat"],localFixes[n]["long"])
    if distance < ranges[simDR_range_dial_capt + 1] then 
      makeIcon(iconTextDataCapt,3007,localFixes[n]["name"],localFixes[n]["lat"],localFixes[n]["long"],distance)
    end
    if distance < ranges[simDR_range_dial_fo + 1] then 
      makeIcon(iconTextDataFO,3007,localFixes[n]["name"],localFixes[n]["lat"],localFixes[n]["long"],distance)
    end
  end

  for n=lastCaptNavaid,59,1 do
    B747DR_text_capt_show[n]=0
  end
  for n=lastFONavaid,59,1 do
    B747DR_text_fo_show[n]=0
  end
  --print(lastCaptNavaid.." ".. lastFONavaid)
end


debug_nd     = find_dataref("laminar/B747/debug/nd")

local fix_data_file=nil
local nLines=0
local numTempFixes=0
local tmplocalFixes={}


function read_fixes()
  if fix_data_file==nil then
    fix_data_file = io.open( "Resources/default data/earth_fix.dat", "r" )
    fix_data_file:read( "*line")
    fix_data_file:read( "*line")
    fix_data_file:read( "*line") 
  end

  local line=""
  local lat=0
  local long=0
  local name=""
  local distance=0
  --scansize kept low after first pass to ensure time constraints met/no warn:xtlua time overflow during flight
  for n=0 ,scansize do
    line=fix_data_file:read( "*line" )
    if line~=nil then 
      lat=tonumber(string.sub(line,1,13))
      long=tonumber(string.sub(line,16,29))
      if lat~=nil and long~=nil then 
        distance=getDistance(simDR_latitude,simDR_longitude,lat,long)
        name=string.sub(line,31,36)
        i, j = string.find(name, "%d+")
        if distance<40 and string.sub(name,1,1)~=" " and i==nil then
          numTempFixes=numTempFixes+1
          tmplocalFixes[numTempFixes]={}
          tmplocalFixes[numTempFixes]["name"]=name
          tmplocalFixes[numTempFixes]["lat"]=lat
          tmplocalFixes[numTempFixes]["long"]=long
          
          --print(name)
        end
      end
      nLines=nLines+1
    else
      break
    end
  end
  if line==nil then 
    fix_data_file:close()
    fix_data_file=nil
    localFixes={}
    scansize=25
    numFixes=numTempFixes
    for n=1 ,numTempFixes do
      localFixes[n]={}
      localFixes[n]["name"]=tmplocalFixes[n]["name"]
      localFixes[n]["lat"]=tmplocalFixes[n]["lat"]
      localFixes[n]["long"]=tmplocalFixes[n]["long"]
    end
    tmplocalFixes={}
    numTempFixes=0
    nLines=0
    lastUpdateFixes=simDRTime
  end
end
function compute_and_show_alt_range_arc()
  local meters_per_second_to_kts = 1.94384449
  local actual_speed = simDR_groundspeed * meters_per_second_to_kts
  if B747DR_ap_FMA_active_pitch_mode==2 then --Glideslope
    B747DR_nd_alt_distance_capt=-99
    B747DR_nd_alt_distance_fo=-99
    B747DR_nd_alt_fo_active=0
    B747DR_nd_alt_capt_active=0 
    return
  end
  if simDR_autopilot_alt_hold_status<2 and ((simDR_autopilot_altitude_ft>simDR_pressureAlt1 and simDR_vvi_fpm_pilot>500) or (simDR_autopilot_altitude_ft<simDR_pressureAlt1 and simDR_vvi_fpm_pilot<-500) or B747DR_ap_FMA_active_pitch_mode==7) then
    altDiff=simDR_autopilot_altitude_ft-simDR_pressureAlt1
    local fpmVal=simDR_vvi_fpm_pilot
    if B747DR_ap_FMA_active_pitch_mode==6 or B747DR_ap_FMA_active_pitch_mode==7 then
      fpmVal=simDR_autopilot_vs_fpm
    end
    minsToAlt=altDiff/fpmVal
    distanceToAlt=(actual_speed*minsToAlt)/60
    --print("distanceToAlt="..distanceToAlt.." minsToAlt="..minsToAlt.." altDiff="..altDiff.." actual_speed="..actual_speed)
    if distanceToAlt < ranges[simDR_range_dial_capt + 1] then
      B747DR_nd_alt_distance_capt=distanceToAlt*(640/ranges[simDR_range_dial_capt + 1])
    else
      B747DR_nd_alt_distance_capt=-99
    end
    if distanceToAlt < ranges[simDR_range_dial_fo + 1] then
      B747DR_nd_alt_distance_fo=distanceToAlt*(640/ranges[simDR_range_dial_fo + 1])
    else
      B747DR_nd_alt_distance_fo=-99
    end
  else
    B747DR_nd_alt_distance_capt=-99
    B747DR_nd_alt_distance_fo=-99
  end
  

  if captIRS==0 or B747DR_nd_alt_distance_capt<-90 or B747DR_nd_mode_capt_sel_dial_pos~=2 then 
    B747DR_nd_alt_capt_active=0 
  else
    B747DR_nd_alt_capt_active=1
  end
  if foIRS==0 or B747DR_nd_alt_distance_fo<-90 or B747DR_nd_mode_fo_sel_dial_pos~=2 then 
    B747DR_nd_alt_fo_active=0
  else
    B747DR_nd_alt_fo_active=1
   end
end
last_range_dial = 0
function aircraft_unload()
  print("ND aircraft unload")
  if fix_data_file~=nil then
    print("ND close fix_data_file")
    fix_data_file:close()
    fix_data_file=nil
  end
end
function after_physics()
  collectgarbage("collect")

  if debug_nd>0 then return end
  local diff=simDRTime-lastUpdate
  if simDR_version>=120012 then
    backport_map_mode_copilot=simDR_map_mode_copilot
  --print("simDR_ground_track="..simDR_ground_track)
    if simDR_map_mode_copilot ==2 then
      B747DR_nd_fo_up = simDR_ground_track
    else
      B747DR_nd_fo_up = simDR_heading_track
    end
    if B747DR_nd_capt_terr>0 or simDR_EFIS_wxr_on>0 then
      B747DR_nd_terr_weather_capt=1
    else
      B747DR_nd_terr_weather_capt=0
    end
    if B747DR_nd_fo_terr>0 or simDR_EFIS_wxr_on_copilot>0 then
      B747DR_nd_terr_weather_fo=1
    else
      B747DR_nd_terr_weather_fo=0
    end
    if simDR_map_mode ==2 then
      B747DR_nd_capt_up = simDR_ground_track
    else
      B747DR_nd_capt_up = simDR_heading_track
    end
  else
    if simDR_map_mode ==2 then
      B747DR_nd_capt_up = simDR_ground_track
      B747DR_nd_fo_up = simDR_ground_track
    else
      B747DR_nd_capt_up = simDR_heading_track
      B747DR_nd_fo_up = simDR_heading_track
    end
    backport_map_range_copilot=simDR_map_range
    backport_map_mode_copilot=simDR_map_mode
  end  
  
  --force new icons if range dial changes (stop bleed into other displays)
  if simDR_range_dial_capt~=last_range_dial then
    last_range_dial=simDR_range_dial_capt
    newIcons()
  end

  updateIcons()
  compute_and_show_alt_range_arc()
  if debug_nd<-2 then return end
  local diff2=simDRTime-lastUpdateIcon
  if diff>0.5 then 
    newIcons()
    lastUpdateIcon=simDRTime
  end
  if debug_nd<-1 then return end
  diff2=simDRTime-lastUpdateFixes
  if diff2>10 then 
    read_fixes()
  end
  if diff<2 then return end
  lastUpdate=simDRTime
  if debug_nd<0 then return end
  decodeNAVAIDS()
  decodeFlightPlan()
  newIcons()
  
  --print("navaids size="..table.getn(currentNaviadsTable))
  --print("fms size="..table.getn(fmsTable))
  
end 
