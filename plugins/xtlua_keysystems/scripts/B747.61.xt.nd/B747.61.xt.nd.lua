--Read out and set displays for ND icons
-- (C) Mark 'mSparks' Parker 2020 CCBYNC4 release


B747DR_text_capt_show 				= find_dataref("laminar/B747/nd/capt/text/show","array[60]")
B747DR_text_capt_heading			= find_dataref("laminar/B747/nd/capt/text/heading","array[60]")
B747DR_text_capt_distance			= find_dataref("laminar/B747/nd/capt/text/distance","array[60]")
--B747DR_text_capt_icon				= find_dataref("laminar/B747/nd/capt/text/icon","array[60]")

B747DR_text_fo_show 				= find_dataref("laminar/B747/nd/fo/text/show","array[60]")
B747DR_text_fo_heading			= find_dataref("laminar/B747/nd/fo/text/heading","array[60]")
B747DR_text_fo_distance			= find_dataref("laminar/B747/nd/fo/text/distance","array[60]")
--B747DR_text_fo_icon				= find_dataref("laminar/B747/nd/fo/text/icon","array[60]")

iconTextDataCapt={}
iconTextDataCapt.icons=find_dataref("laminar/B747/nd/capt/text/icon","array[60]")
for n=0,59,1 do
  iconTextDataCapt[n]={}
  iconTextDataCapt[n].whitetext=find_dataref("laminar/B747/nd/capt/text/whitetext"..n)
  iconTextDataCapt[n].bluetext=find_dataref("laminar/B747/nd/capt/text/bluetext"..n)
  iconTextDataCapt[n].redtext=find_dataref("laminar/B747/nd/capt/text/redtext"..n)
  iconTextDataCapt[n].greentext=find_dataref("laminar/B747/nd/capt/text/greentext"..n)
end

iconTextDataFO={}
iconTextDataFO.icons=find_dataref("laminar/B747/nd/fo/text/icon","array[60]")
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
simDR_map_range				= find_dataref("sim/cockpit2/EFIS/map_range")
simDR_map_mode				= find_dataref("sim/cockpit2/EFIS/map_mode")
simDR_range_dial_capt			= find_dataref("laminar/B747/nd/range/capt/sel_dial_pos")
simDR_range_dial_fo			= find_dataref("laminar/B747/nd/range/fo/sel_dial_pos")
B747_nd_map_center_capt                 = find_dataref("laminar/B747/nd/map_center/capt")
B747_nd_map_center_fo                   = find_dataref("laminar/B747/nd/map_center/fo")
B747DR_nd_capt_vor_ndb                  = find_dataref("laminar/B747/nd/data/capt/vor_ndb")
B747DR_nd_fo_vor_ndb                    = find_dataref("laminar/B747/nd/data/fo/vor_ndb")
B747DR_nd_capt_apt	                = find_dataref("laminar/B747/nd/data/capt/apt")
B747DR_nd_fo_apt	                = find_dataref("laminar/B747/nd/data/fo/apt")
B747DR_pfd_mode_capt		 = find_dataref("laminar/B747/pfd/capt/irs")
B747DR_pfd_mode_fo		 = find_dataref("laminar/B747/pfd/fo/irs")

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
local nLength=0

dofile("json/json.lua")


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
  if text~="LATLON" and iconTextData==iconTextDataCapt and usedNaviadsTableCapt[text]~=nil then return end
  if text~="LATLON" and iconTextData==iconTextDataFO and usedNaviadsTableFO[text]~=nil then return end
  local abs_heading=getHeading(simDR_latitude,simDR_longitude,latitude,longitude)
  local heading_diff=0
  if simDR_map_mode==2 then
    mag_diff=getHeadingDifference(simDR_true_heading,simDR_mag_heading)
    heading_diff=getHeadingDifference(simDR_ground_track-mag_diff,abs_heading)
  else
    heading_diff=getHeadingDifference(simDR_true_heading,abs_heading)
  end

  
  local lastNavaid=0
  local vor_ndb=0
  local apt=0
  local displayDistance=0
  if iconTextData==iconTextDataCapt then
    if captIRS==0 then return end
    
    displayDistance=distance*(640/ranges[simDR_range_dial_capt + 1])
    if (heading_diff < -135 or heading_diff > 135) and displayDistance> 160 and B747_nd_map_center_capt<1 then return end
    if displayDistance> 250 and B747_nd_map_center_capt>0 then return end
    if (heading_diff < -45 or heading_diff > 45) and displayDistance> 480 and B747_nd_map_center_capt<1 then return end
    if (heading_diff < -55 or heading_diff > 55) and displayDistance> 400 and B747_nd_map_center_capt<1 then return end
    lastNavaid=lastCaptNavaid
    apt=B747DR_nd_capt_apt
    vor_ndb=B747DR_nd_capt_vor_ndb
  else
    if foIRS==0 then return end
    displayDistance=distance*(640/ranges[simDR_range_dial_fo + 1])
    if (heading_diff < -135 or heading_diff > 135) and displayDistance> 160 and B747_nd_map_center_fo<1 then return end 
     if displayDistance> 250 and B747_nd_map_center_fo>0 then return end
     if (heading_diff < -45 or heading_diff > 45) and displayDistance> 480 and B747_nd_map_center_fo<1 then return end
     if (heading_diff < -55 or heading_diff > 55) and displayDistance> 400 and B747_nd_map_center_fo<1 then return end
    lastNavaid=lastFONavaid
    apt=B747DR_nd_fo_apt
    vor_ndb=B747DR_nd_fo_vor_ndb
  end
  
  if lastNavaid > 59 then return end
  
  if navtype==1 and apt>0 then --airport
    iconTextData.icons[lastNavaid]=2
    iconTextData[lastNavaid].whitetext=text
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==3 then --current FMS waypoint
    iconTextData.icons[lastNavaid]=4
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].redtext=text
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==5 then --non current FMS waypoint
    iconTextData.icons[lastNavaid]=5
    iconTextData[lastNavaid].whitetext=text
    iconTextData[lastNavaid].bluetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==4 and vor_ndb>0 then
    iconTextData.icons[lastNavaid]=9
    iconTextData[lastNavaid].bluetext=text
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" "
  elseif navtype==2 and vor_ndb>0 then
    iconTextData.icons[lastNavaid]=0
    iconTextData[lastNavaid].bluetext=text
    iconTextData[lastNavaid].whitetext=" "
    iconTextData[lastNavaid].redtext=" "
    iconTextData[lastNavaid].greentext=" "
  elseif (navtype==64 or navtype==128 or navtype==256) and vor_ndb>0  then
    iconTextData.icons[lastNavaid]=3
    iconTextData[lastNavaid].bluetext=" "
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
    usedNaviadsTableCapt[text]=true;
  else
     B747DR_text_fo_show[lastNavaid]=1
     B747DR_text_fo_heading[lastNavaid]=heading_diff
     B747DR_text_fo_distance[lastNavaid]=displayDistance
     lastFONavaid=lastFONavaid+1
     usedNaviadsTableFO[text]=true;
  end
  
end

function updateIcon(iconData,n,isCaptain)
   local distance = getDistance(simDR_latitude,simDR_longitude,iconData[n].latitude,iconData[n].longitude)
  local abs_heading=getHeading(simDR_latitude,simDR_longitude,iconData[n].latitude,iconData[n].longitude)
  local heading_diff=0
  if simDR_map_mode==2 then
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
  for n=1,table.getn(fmsTable),1 do
    local distance = getDistance(simDR_latitude,simDR_longitude,fmsTable[n][5],fmsTable[n][6])
    if distance < ranges[simDR_range_dial_capt + 1] then 

      if fmsTable[n][10]==true then
	makeIcon(iconTextDataCapt,3,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      else
	makeIcon(iconTextDataCapt,5,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      end
    end
    if distance < ranges[simDR_range_dial_fo + 1] then 

      if fmsTable[n][10]==true then
	makeIcon(iconTextDataFO,3,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      else
	makeIcon(iconTextDataFO,5,fmsTable[n][8],fmsTable[n][5],fmsTable[n][6],distance)
      end
    end
  end
  for n=table.getn(currentNaviadsTable),1,-1 do
    local distance = getDistance(simDR_latitude,simDR_longitude,currentNaviadsTable[n][5],currentNaviadsTable[n][6])
    if distance < ranges[simDR_range_dial_capt + 1] then 
      makeIcon(iconTextDataCapt,currentNaviadsTable[n][2],currentNaviadsTable[n][8],currentNaviadsTable[n][5],currentNaviadsTable[n][6],distance)
    end
    if distance < ranges[simDR_range_dial_fo + 1] then 
      makeIcon(iconTextDataFO,currentNaviadsTable[n][2],currentNaviadsTable[n][8],currentNaviadsTable[n][5],currentNaviadsTable[n][6],distance)
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

function after_physics()
  if debug_nd>0 then return end
  local diff=simDRTime-lastUpdate
  updateIcons()
  local diff2=simDRTime-lastUpdateIcon
  if diff>2 then 
    newIcons()
    lastUpdateIcon=simDRTime
  end
  if diff<10 then return end
  lastUpdate=simDRTime
  decodeNAVAIDS()
  decodeFlightPlan()
  newIcons()
  print("navaids size="..table.getn(currentNaviadsTable))
  print("fms size="..table.getn(fmsTable))
  
end 
