--[[
*****************************************************************************************
* Program Script Name	:	B747.70.autopilot.vnav
* Author Name			:	Mark Parker (mSparks)
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2021-01-27	0.01a				Start of Dev
*
*
*
*
--]]
dofile("B747.70.xt.autopilot.vnavspd.lua")

function deceleratedDesent(targetvspeed)
  if simDR_autopilot_airspeed_is_mach == 1 then return targetvspeed end --can't do this in mach mode, slow tf down already

  local meet = B747_rescale(0,0,400,500,B747BR_fpe)
  local upperAlt=math.max(tonumber(getFMSData("desspdtransalt")),tonumber(getFMSData("desrestalt")))
  if simDR_pressureAlt1>upperAlt+1000 then 
    return targetvspeed -meet
  end --nowhere near a restriction yet
  local lowerAlt=math.min(tonumber(getFMSData("desspdtransalt")),tonumber(getFMSData("desrestalt")))
  local upperAltspdval=tonumber(getFMSData("destranspd"))
  local lowerAltspdval=tonumber(getFMSData("desrestspd"))

  if simDR_ind_airspeed_kts_pilot<=(lowerAltspdval+5) then return targetvspeed end --already low enough
  --less than upperAlt+1000
   -- greater than lowerAltspdval
  if simDR_ind_airspeed_kts_pilot>(upperAltspdval+5) then 
    --print("upperAltspdval deceleratedDesent upperAlt"..upperAlt.." lowerAlt=".. lowerAlt .." upperAltspdval=".. upperAltspdval .." simDR_pressureAlt1="..simDR_pressureAlt1.." simDR_ind_airspeed_kts_pilot="..simDR_ind_airspeed_kts_pilot)
    return -500 
  end --approximate 500fpm

  if simDR_pressureAlt1>lowerAlt+1000 then return targetvspeed end --not at next restriction yet

  if simDR_ind_airspeed_kts_pilot>(lowerAltspdval+5) then 
    --print("lowerAltspdval deceleratedDesent upperAlt"..upperAlt.." lowerAlt=".. lowerAlt .." upperAltspdval=".. upperAltspdval .." simDR_pressureAlt1="..simDR_pressureAlt1.." simDR_ind_airspeed_kts_pilot="..simDR_ind_airspeed_kts_pilot)
    return -500 
  end --approximate 500fpm

  return targetvspeed-meet
  --print("oob deceleratedDesent upperAlt"..upperAlt.." lowerAlt=".. lowerAlt .." upperAltspdval=".. upperAltspdval .." simDR_pressureAlt1="..simDR_pressureAlt1.." simDR_ind_airspeed_kts_pilot="..simDR_ind_airspeed_kts_pilot)


end
function setDescentVSpeed()
	local fmsO=getFMS()
  if B747BR_totalDistance>=15 and fmsO[B747DR_fmstargetIndex]~= nil then
    --set in setDistances when < 15
    local glideAlt= B747DR_fmstargetDistance*290 +fmsO[B747DR_fmstargetIndex][9]
    if string.len(B747BR_vnavProfile)>2 then
      local vnavData=json.decode(B747BR_vnavProfile)
      local endI = table.getn(vnavData)
      for i = 1, endI, 1 do
        if vnavData[i][4] then
          if i==1 then break end
          --local altDiff=vnavData[i-1][3]-vnavData[i][3]

          local legDist = getDistance(simDR_latitude, simDR_longitude, vnavData[i][1], vnavData[i][2])
          glideAlt= legDist*vnavData[i][5] +vnavData[i][3]
          print("setDescentVSpeed "..glideAlt)
        end
      end
    end
    B747BR_fpe	= simDR_pressureAlt1-glideAlt
  end
  if simDR_autopilot_altitude_ft+600 > simDR_pressureAlt1 then return end --dont set fpm near hold alt  
  local distanceNM=B747DR_fmstargetDistance--getDistance(simDR_latitude,simDR_longitude,fmsO[B747DR_fmstargetIndex][5],fmsO[B747DR_fmstargetIndex][6]) --B747BR_nextDistanceInFeet/6076.12
  
  
  local headingDiff=getHeadingDifference(getHeading(simDR_latitude,simDR_longitude,fmsO[B747DR_fmstargetIndex][5],fmsO[B747DR_fmstargetIndex][6]), simDR_AHARS_heading_deg_pilot)
  --print("headingDiff="..headingDiff)
  if distanceNM<1 then
    distanceNM=1
  end
  --[[if distanceNM>20 or math.abs(
    getHeadingDifference(
      getHeading(simDR_latitude,simDR_longitude,fmsO[B747DR_fmstargetIndex][5],fmsO[B747DR_fmstargetIndex][6]), simDR_AHARS_heading_deg_pilot))>20 
      then distanceNM=B747BR_totalDistance end]]--
  local nextDistanceInFeet=distanceNM*6076.12
  local time=distanceNM*30.8666/(simDR_groundspeed) --time in minutes, gs in m/s....
  local early=100
  if simDR_autopilot_altitude_ft>5000 then
    early=250 
  else
    early=B747BR_fpe
  end
  local vdiff=B747DR_ap_vnav_target_alt-simDR_pressureAlt1-early --to be negative
  local vspeed=vdiff/time
  print("speed=".. simDR_groundspeed .. " distance=".. distanceNM .. " vspeed=" .. vspeed .. " vdiff=" .. vdiff .. " time=" .. time.. " B747DR_ap_vnav_target_alt=" .. B747DR_ap_vnav_target_alt)
		  --speed=89.32039642334 distance=2.9459299767094vspeed=-6559410.6729958
  B747DR_ap_vb = math.atan2(vdiff,nextDistanceInFeet)*-57.2958
  if vspeed<-2500 then vspeed=-2500 end
  if vspeed>100 then vspeed=100 end
  if simDR_radarAlt1<=10 then
    simDR_autopilot_vs_fpm = -250 -- slow descent, reduces AoA which if it goes to high spoils the landing
    B747DR_ap_inVNAVdescent=0
    B747DR_ap_vnav_state=0
    B747DR_ap_thrust_mode=0
    setDescent(false)
    print("End Descent")
    return
  end
  if B747DR_ap_vnav_state > 0 then
    simDR_autopilot_vs_fpm = deceleratedDesent(vspeed)
  end
  B747DR_ap_fpa=math.atan2(vspeed,simDR_groundspeed*196.85)*-57.2958
  
  --[[if B747DR_descentSpeedGradient>0 and simDR_pressureAlt1>B747DR_target_descentAlt then
    simDR_autopilot_airspeed_kts=B747DR_target_descentSpeed+(simDR_pressureAlt1-B747DR_target_descentAlt)*B747DR_descentSpeedGradient
    if simDR_autopilot_airspeed_is_mach == 1 then
      B747DR_ap_ias_dial_value=simDR_autopilot_airspeed_kts_mach*100
    end
    --print("set descentSpeed to " .. simDR_autopilot_airspeed_kts)
  end]]

  
end
  
  function getDescentTarget()
    B747DR_target_descentSpeed=tonumber(getFMSData("destranspd"))
    B747DR_target_descentAlt=tonumber(getFMSData("desspdtransalt"))
    if B747DR_target_descentAlt>simDR_pressureAlt1 
      or simDR_autopilot_airspeed_kts<B747DR_target_descentSpeed 
      then 
      B747DR_descentSpeedGradient=0 
      return 
    end
    B747DR_descentSpeedGradient=(simDR_autopilot_airspeed_kts-B747DR_target_descentSpeed)/(simDR_pressureAlt1-B747DR_target_descentAlt)
    print("set descentSpeedGradient to " .. B747DR_descentSpeedGradient)
  end
  