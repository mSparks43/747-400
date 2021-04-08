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
function setDescentVSpeed()
	local fmsO=getFMS()
  if simDR_autopilot_altitude_ft+600 > simDR_pressureAlt1 then return end --dont set fpm near hold alt  
  local distanceNM=getDistance(simDR_latitude,simDR_longitude,fmsO[B747DR_fmstargetIndex][5],fmsO[B747DR_fmstargetIndex][6]) --B747BR_nextDistanceInFeet/6076.12
  local nextDistanceInFeet=distanceNM*6076.12
  local time=distanceNM*30.8666/(simDR_groundspeed) --time in minutes, gs in m/s....
  local early=100
  if simDR_autopilot_altitude_ft>5000 then early=250 end
  local vdiff=B747DR_ap_vnav_target_alt-simDR_pressureAlt1-early --to be negative
  local vspeed=vdiff/time
  --print("speed=".. simDR_groundspeed .. " distance=".. distanceNM .. " vspeed=" .. vspeed .. " vdiff=" .. vdiff .. " time=" .. time)
		  --speed=89.32039642334 distance=2.9459299767094vspeed=-6559410.6729958
  B747DR_ap_vb = math.atan2(vdiff,nextDistanceInFeet)*-57.2958
  if vspeed<-3500 then vspeed=-3500 end
  
  if simDR_radarAlt1<=2000 then
    simDR_autopilot_vs_fpm = -250 -- slow descent, reduces AoA which if it goes to high spoils the landing
    B747DR_ap_inVNAVdescent=0
    B747DR_ap_vnav_state=0
    print("End Descent")
    return
  end
  simDR_autopilot_vs_fpm = vspeed
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
  
  function vnavDescent()

  end

  
  function vnavCruise()
    
    
  end