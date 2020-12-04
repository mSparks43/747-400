--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
local seenApproach=false
local active_land=false
local zerodThrottle=false
local pinThrottle=0;
local pinrudder=0;
local throttleAdjust=0.18
local rod=0
local lastAlt=0
local initElevator=0
local lastRod=0
local touchedGround=false
local inrollout=false
local pinRoll=0
local windCorrectAngle=0 
local maxPitch=0
local maxThrottle=1
local flareAt=30
local zeroRatePitch=6
local totalLift=0
local liftMeasurements=0;
local neutralPitch=0
local pitchMeasurements=0;


function start_flare()
  local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
    --print("autoland ".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_active_roll_mode.. " "..B747DR_ap_FMA_active_pitch_mode.. " "..numAPengaged)
    --B747DR_ap_FMA_active_roll_mode = 4 --ROLLOUT
    B747DR_ap_FMA_armed_pitch_mode = 0
    B747DR_ap_FMA_active_pitch_mode = 3 --SHOW FLARE
    pinThrottle=simDR_allThrottle
    simCMD_autopilot_autothrottle_off:once() 
    windCorrectAngle=simDR_reqHeading-simDR_AHARS_heading_deg_pilot
    --simCMD_autopilot_fdir_servos_down_one:once()
    B747DR_ap_autoland=1
    active_land=false
    zerodThrottle=false
    touchedGround=false
    inrollout=false
    lastRod=0
    initElevator=0
    maxPitch=0
    simDR_overRideStab=1
    maxThrottle=simDR_allThrottle
    lastAlt=0
    pinThrottle=0;
    zeroRatePitch=(neutralPitch/pitchMeasurements)+0.5
end
local targetPitch
function doPitch()

  local doRollout=((4.5+simDR_AHARS_pitch_heading_deg_pilot))
  
  if simDR_radarAlt1 >flareAt then 
    targetPitch=zeroRatePitch

  end
  
  if simDR_radarAlt1 < doRollout then targetPitch=4 maxPitch=4 inrollout=true B747DR_ap_FMA_active_roll_mode=4 B747DR_ap_FMA_active_pitch_mode=0 end
  
  if simDR_radarAlt1 < 5.3 then targetPitch=1 maxPitch=1 inrollout=true B747DR_ap_FMA_active_roll_mode=4 B747DR_ap_FMA_active_pitch_mode=0 end
  

  if simDR_radarAlt1 < flareAt and simDR_radarAlt1 > doRollout then

    local progressPitch=((55-(simDR_radarAlt1)))/(zeroRatePitch-0.5)
    if progressPitch>zeroRatePitch+0.5 then 
      targetPitch=zeroRatePitch+0.5
    elseif progressPitch<simDR_AHARS_pitch_heading_deg_pilot and simDR_AHARS_pitch_heading_deg_pilot>zeroRatePitch-2 and simDR_AHARS_pitch_heading_deg_pilot<zeroRatePitch then --dont nose down in final 50 feet
      targetPitch=simDR_AHARS_pitch_heading_deg_pilot
    elseif progressPitch<zeroRatePitch-2 then 
      targetPitch=zeroRatePitch-2 
     else
      targetPitch=progressPitch
    end

  end
  
 -- if inrollout==true then targetPitch=1 end
  if inrollout==true then 
    local tP=(simDR_radarAlt1-4.0)
    if simDR_radarAlt1 < 7 then 
      targetPitch=tP
    elseif tP> simDR_AHARS_pitch_heading_deg_pilot then
     targetPitch=tP
    else
     targetPitch=simDR_AHARS_pitch_heading_deg_pilot
    end
  end
  if simDR_onGround==1 then targetPitch=-0.1 end
  
  if simDR_AHARS_pitch_heading_deg_pilot>targetPitch+0.1 then
    initElevator=-0.1*(simDR_AHARS_pitch_heading_deg_pilot-targetPitch)
  elseif B744_fpm<-300 and simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
    initElevator=0.5*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
  elseif simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
    initElevator=0.3*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
  end
end



function doYaw()
  pinRoll= 0.0
  --if touchedGround==true then  pinRoll= 0 end
  if touchedGround==false then 
    local roll=simDR_AHARS_roll_deg_pilot
    local tRoll=0
    if roll>pinRoll then
      tRoll=-0.2*(roll)
  elseif roll<pinRoll then
      tRoll=0.2*(roll)
  end
  if tRoll>0.5 then tRoll=0.5 end
  if tRoll<-0.5 then tRoll=-0.5 end
  
  simDR_roll=B747_set_ap_animation_position(simDR_roll,tRoll,-1,1,5)
  
 
   
  end 
  if inrollout==true then
   local diff=simDR_reqHeading-simDR_AHARS_heading_deg_pilot
  if diff>0 then
      pinrudder=-0.3*(diff)
  elseif diff<0 then
      pinrudder=0.3*(diff)
  end
  if pinrudder>1 then pinrudder=1 end
  if pinrudder<-1 then pinrudder=-1 end
  --if zerodThrottle then pinrudder=0 end
  
    simDR_rudder=B747_set_ap_animation_position(simDR_rudder,pinrudder,-1,1,3)
  end

    
    --pTrint("yaw " .. diff .." ".. simDR_rudder .. " " .. simDR_roll .. " " .. simDR_AHARS_roll_deg_pilot)
end
function controlYaw()
  local diff=simDR_reqHeading-simDR_AHARS_heading_deg_pilot
  if simDR_radarAlt1 <13 or touchedGround==true then --align runway
    doYaw()
  end
end
local targetAirspeed
B747DR_airspeed_Vf25                            = find_dataref("laminar/B747/airspeed/Vf25")
B747DR_airspeed_Vf30                            = find_dataref("laminar/B747/airspeed/Vf30")
function doThrottle()
  local refSpeed
  if simDR_flap_ratio_control<=0.668 then --flaps 25
	    refSpeed=B747DR_airspeed_Vf25
	  elseif simDR_flap_ratio_control<=1.0 then --flaps 30
	    refSpeed=B747DR_airspeed_Vf30
	  end
  targetAirspeed= refSpeed 
  lastAlt=simDR_radarAlt1
  if touchedGround==true then pinThrottle=0 return end
  if simDR_touchGround>0 then touchedGround=true pinThrottle=0 return end
  
  if simDR_radarAlt1 < 7 then
    targetAirspeed=refSpeed + 1
  elseif simDR_radarAlt1 < flareAt then

    targetAirspeed=refSpeed  -- -((50-simDR_radarAlt1)/20)

  end
  
  local diff=targetAirspeed-simDR_ind_airspeed_kts_pilot
  
  if diff>0 then
      pinThrottle=diff/10
  elseif diff<0 then
      pinThrottle=0
  end
  if pinThrottle>1 then pinThrottle=1 end
  if pinThrottle<0 then pinThrottle=0 end
  
end
function during_Flare()
  local altdiff=lastAlt-simDR_radarAlt1
  if altdiff~=0 and lastRod==0 and lastAlt~=0 then lastRod=altdiff
  elseif altdiff~=0 then lastRod=(altdiff+lastRod)/2 end
  if lastRod<0 then lastRod=0 end
  doThrottle()
  doPitch()
  controlYaw()
  simDR_allThrottle=B747_set_ap_animation_position(simDR_allThrottle,pinThrottle,0,1,10)
  simDR_elevator=initElevator --B747_set_ap_animation_position(simDR_elevator,initElevator,-1,1,1)
  --simDR_rudder=B747_set_ap_animation_position(simDR_rudder,pinrudder,-1,1,2)
--   if inrollout==false then
-- 
--     print("autoland flare alt=".. simDR_radarAlt1 .. " rollout=false initElevator=" ..initElevator.. " targetspeed=".. targetAirspeed  .." fpm=".. B744_fpm .."/".. lastRod.." : ".." actualPitch=".. simDR_AHARS_pitch_heading_deg_pilot .." targetPitch=" ..targetPitch .." onGround="..simDR_onGround)
--   else
--     print("autoland flare alt=".. simDR_radarAlt1 .. " rollout=true initElevator=" .. initElevator.." targetspeed=".. targetAirspeed  .." fpm=".. B744_fpm  .."/".. lastRod.." : ".." actualPitch=".. simDR_AHARS_pitch_heading_deg_pilot .." targetPitch=" ..targetPitch .." onGround="..simDR_onGround)
-- 
--   end
end
function end_Flare()
--print("autoland stop".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_autothrottle_mode .." "..B747DR_ap_FMA_active_pitch_mode)
        --pinThrottle=simDR_allThrottle
--         print("autoland stop".. simDR_radarAlt1 .. " ".. pinThrottle .." "..B747DR_ap_FMA_active_pitch_mode)
        --simCMD_autopilot_fdir_servos_down_one:once()
        B747DR_ap_FMA_active_pitch_mode = 0 --no pitch
       -- simDR_elevator=initElevator-0.05--B747_set_ap_animation_position(simDR_elevator,initElevator-0.05,0,1,5)
        simDR_pitch  =0.0
        active_land=true
        zerodThrottle=false
	
end
function touchdown_elevator()
      if simDR_AHARS_pitch_heading_deg_pilot>2 then targetPitch=1
      elseif simDR_AHARS_pitch_heading_deg_pilot>1 then targetPitch=0
      else targetPitch=-2 end
      if simDR_AHARS_pitch_heading_deg_pilot>targetPitch+0.1 then
	initElevator=-0.2*(simDR_AHARS_pitch_heading_deg_pilot-targetPitch)
      elseif simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
	initElevator=0.2*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
      end
      simDR_elevator=B747_set_ap_animation_position(simDR_elevator,initElevator,-1,1,1)
end
simDR_Lift=find_dataref("sim/flightmodel/forces/lift_path_axis")
function preLand_measure()
     totalLift=totalLift+(simDR_Lift/10000)
      liftMeasurements=liftMeasurements+1;
      
      neutralPitch=neutralPitch+simDR_AHARS_pitch_heading_deg_pilot
      pitchMeasurements=pitchMeasurements+1;
      targetPitch=(neutralPitch/pitchMeasurements)
--       print("Lift="..(totalLift/liftMeasurements).. " Pitch="..targetPitch)
end
function preFlare_elevator()
      if simDR_AHARS_pitch_heading_deg_pilot>targetPitch+0.1 then
	initElevator=-0.2*(simDR_AHARS_pitch_heading_deg_pilot-targetPitch)
      elseif simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
	initElevator=0.2*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
      end
      simDR_elevator=B747_set_ap_animation_position(simDR_elevator,initElevator,-1,1,1)
end
function do_touchdown()
     touchdown_elevator()
     if simDR_onGround==1 then
	simDR_rudder=B747_set_ap_animation_position(simDR_rudder,0,-1,1,3)
     else
	doYaw()
     end
      --print("autoland touchdown".. simDR_radarAlt1 .. " ".. initElevator .." ".. simDR_AHARS_pitch_heading_deg_pilot)
      --[[if simDR_radarAlt1 >5 then
         simDR_allThrottle=B747_set_ap_animation_position(simDR_allThrottle,0,0,1,5)
         --print("autoland calming ".. simDR_radarAlt1 .. " ".. simDR_allThrottle .." "..B747DR_ap_FMA_active_pitch_mode)
	 
      else]]
	if simDR_allThrottle>0 and not zerodThrottle then 
         simDR_allThrottle=B747_set_ap_animation_position(simDR_allThrottle,0,0,1,10)
         --print("autoland zeroing ".. simDR_radarAlt1 .. " ".. simDR_allThrottle .." "..B747DR_ap_FMA_active_pitch_mode)
      elseif active_land and not zerodThrottle  then 
         zerodThrottle=true--allow thrust reversors
	 --simDR_pitch2=-1
--          print("autoland zero ".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_autothrottle_mode .." "..B747DR_ap_FMA_active_pitch_mode)
      end
      if simDR_onGround==1 and simDR_rudder==0 then 
	B747DR_ap_autoland=0 
	seenApproach=false
	simDR_overRideStab=0
	B747DR_ap_FMA_active_roll_mode=0
      end --we done!
end

function runAutoland()
  local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
  local diff=simDR_reqHeading-simDR_AHARS_heading_deg_pilot
   if simDR_autopilot_approach_status>0 then seenApproach=true end
  
   if seenApproach==false then return false end
   if numAPengaged<1 then 
   --if (simDR_autopilot_approach_status==0 and active_autoland==false) or numAPengaged<1 then
      B747DR_ap_autoland=0 
      simDR_overRideStab=0
      return false
    end
    if B747DR_ap_autoland<0 then
      simDR_overRideStab=0
      return false --Go Around active
    elseif B747DR_ap_autoland==1 then
      if active_land  then
        do_touchdown()
	return true
      end
     
      if simDR_radarAlt1 < 5 and not active_land then -- watch the bounce! 
        end_Flare()
	return true
      end
      during_Flare()
     return true 
    
  end
  if simDR_touchGround>0 then return false end
   -- print("prep autoland ".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_active_roll_mode.. " "..B747DR_ap_FMA_active_pitch_mode.. " "..numAPengaged)
  pinThrottle=simDR_allThrottle
  if simDR_radarAlt1>0 and simDR_radarAlt1 < flareAt and numAPengaged>2 then --and B747DR_ap_FMA_active_roll_mode==3 and B747DR_ap_FMA_active_pitch_mode == 2 and (always autoland >2 aps)
    lastAlt=simDR_radarAlt1 --begin alt tracking
    start_flare()
    return true
   end
   --no nose dives in the last 100 feet
    if simDR_radarAlt1 < 100 and numAPengaged>2 then 
      preFlare_elevator()
      B747DR_ap_FMA_armed_pitch_mode=3
-- 	print("autoland preflare ".. simDR_radarAlt1.. " " .. simDR_AHARS_pitch_heading_deg_pilot .." " ..targetPitch)
      return true
    elseif simDR_radarAlt1 < 500 and numAPengaged>2 then
      preLand_measure()
    else
       zeroRatePitch=6
      totalLift=0
      liftMeasurements=0;
      neutralPitch=0
      pitchMeasurements=0;
      touchedGround=false
      pinRoll=0
    end
   
   return false
end
