--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
local seenApproach=false

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
local flareAt=50
local zeroRatePitch=6
local totalLift=0
local liftMeasurements=0;
local neutralPitch=0
local pitchMeasurements=0;


function start_flare()
  local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
    print("start_flare ".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_active_roll_mode.. " "..B747DR_ap_FMA_active_pitch_mode.. " "..numAPengaged)
    --B747DR_ap_FMA_active_roll_mode = 4 --ROLLOUT
    B747DR_ap_FMA_armed_pitch_mode = 0
    B747DR_ap_FMA_active_pitch_mode = 3 --SHOW FLARE
    pinThrottle=simDR_allThrottle
    --simCMD_autopilot_autothrottle_off:once()

    windCorrectAngle=simDR_reqHeading-simDR_AHARS_heading_deg_pilot
    --simCMD_autopilot_fdir_servos_down_one:once()

    B747DR_ap_active_land=0.0

    touchedGround=false
    inrollout=false
    lastRod=0
    initElevator=0
    maxPitch=0
    maxThrottle=simDR_allThrottle
    lastAlt=0
    pinThrottle=0;
    zeroRatePitch=(neutralPitch/pitchMeasurements)
end
local targetPitch
function B747_rescale(in1, out1, in2, out2, x)

  if x < in1 then return out1 end
  if x > in2 then return out2 end
  return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end
function doPitch()

  local doRollout=((4.5+simDR_AHARS_pitch_heading_deg_pilot))

  if simDR_radarAlt1 >flareAt then
    targetPitch=zeroRatePitch

  end
  if simDR_radarAlt1 < 5.3 then
    targetPitch=-1
    maxPitch=1
    inrollout=true
    B747DR_ap_FMA_active_roll_mode=4
    B747DR_ap_FMA_armed_roll_mode=0
    --B747DR_ap_FMA_active_pitch_mode=0
  elseif simDR_radarAlt1 < doRollout then
    targetPitch=0.1--zeroRatePitch-0.5
    maxPitch=4
    inrollout=true
    B747DR_ap_FMA_active_roll_mode=4
    B747DR_ap_FMA_armed_roll_mode=0
    --B747DR_ap_FMA_active_pitch_mode=0
    --B747DR_ap_FMA_armed_pitch_mode=0
  end




  if simDR_radarAlt1 < flareAt and simDR_radarAlt1 > doRollout then

    --[[local progressPitch=((55-(simDR_radarAlt1)))/(zeroRatePitch-0.5)
    if progressPitch>zeroRatePitch-0.5 then
      targetPitch=zeroRatePitch-0.5
    elseif progressPitch<simDR_AHARS_pitch_heading_deg_pilot and simDR_AHARS_pitch_heading_deg_pilot>zeroRatePitch-2 and simDR_AHARS_pitch_heading_deg_pilot<zeroRatePitch then --dont nose down in final 50 feet
      targetPitch=simDR_AHARS_pitch_heading_deg_pilot
    elseif progressPitch<zeroRatePitch-2 then
      targetPitch=zeroRatePitch-2
     else
      targetPitch=progressPitch
    end]]--
    flareRate=B747_rescale(130,2.5,180,1.0,simDR_ind_airspeed_kts_pilot)

    targetPitch=zeroRatePitch+flareRate --0.5
    print("flareRate "..flareRate.." targetPitch "..targetPitch.." flareAt "..flareAt.." simDR_AHARS_pitch_heading_deg_pilot "..simDR_AHARS_pitch_heading_deg_pilot)
  end
  --[[if inrollout==true then
    local tP=(simDR_radarAlt1-4.0)
    if simDR_radarAlt1 < 7 then
      targetPitch=tP
    elseif tP> simDR_AHARS_pitch_heading_deg_pilot then
     targetPitch=tP
    else
     targetPitch=simDR_AHARS_pitch_heading_deg_pilot
    end
  end]]
  --if simDR_onGround==1 then targetPitch=-3 end --never here
  B744DR_autolandPitch=targetPitch
  --[[if simDR_AHARS_pitch_heading_deg_pilot>targetPitch+0.1 then
    initElevator=-0.1*(simDR_AHARS_pitch_heading_deg_pilot-targetPitch)
  elseif B744_fpm<-300 and simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
    initElevator=0.5*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
  elseif simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
    initElevator=0.3*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
  end]]
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

  --simDR_roll=B747_set_ap_animation_position(simDR_roll,tRoll,-1,1,5)



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
  if pinThrottle<0 or simDR_radarAlt1<25 then pinThrottle=0 end
  if simDR_onGround==1 then
    B747DR_ap_FMA_autothrottle_mode = 0
  elseif simDR_radarAlt1<25 and isATEnabled() then
    B747DR_ap_FMA_autothrottle_mode = 2
  end

end
function during_Flare()
  local altdiff=lastAlt-simDR_radarAlt1
  if altdiff~=0 and lastRod==0 and lastAlt~=0 then lastRod=altdiff
  elseif altdiff~=0 then lastRod=(altdiff+lastRod)/2 end
  if lastRod<0 then lastRod=0 end
  print("during_Flare ".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_active_roll_mode.. " "..B747DR_ap_FMA_active_pitch_mode)
  --doThrottle()
  if simDR_onGround==1 then
    B747DR_ap_FMA_autothrottle_mode = 0
  elseif simDR_radarAlt1<40 then
    B747DR_ap_FMA_autothrottle_mode = 2
  end
  doPitch()
  controlYaw()


end
function end_Flare()
        B747DR_ap_FMA_active_pitch_mode = 0 --no pitch
       -- simDR_elevator=initElevator-0.05--B747_set_ap_animation_position(simDR_elevator,initElevator-0.05,0,1,5)
        simDR_pitch  =0.0
        B747DR_ap_active_land=1.0

        B747DR_ap_FMA_autothrottle_mode = 0
end
--[[function touchdown_elevator()
      if simDR_AHARS_pitch_heading_deg_pilot>2 then targetPitch=1
      elseif simDR_AHARS_pitch_heading_deg_pilot>1 then targetPitch=0
      else targetPitch=-2 end
      if simDR_AHARS_pitch_heading_deg_pilot>targetPitch+0.1 then
	initElevator=-0.2*(simDR_AHARS_pitch_heading_deg_pilot-targetPitch)
      elseif simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
	initElevator=0.2*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
      end
     --simDR_elevator=B747_set_ap_animation_position(simDR_elevator,initElevator,-1,1,1)
end]]
--simDR_Lift=find_dataref("sim/flightmodel/forces/lift_path_axis")
local lastVVI=0
local landingvviTime=0
function preLand_measure()
     --totalLift=totalLift+(simDR_Lift/10000)

     local currentFPM=simDR_vvi_fpm_pilot
     local diff=simDRTime-landingvviTime
     if diff>0.2 then
        landingvviTime=simDRTime
        local landingvviError=math.abs(currentFPM-lastVVI)
        lastVVI=currentFPM
        if B747DR_ap_autoland==0 and landingvviError<10 then  -- and simDR_hsi_vdef_dots_pilot <0.1 and simDR_hsi_vdef_dots_pilot>-0.1 then
          neutralPitch=neutralPitch+simDR_AHARS_pitch_heading_deg_pilot
          pitchMeasurements=pitchMeasurements+1;
          print("pitchMeasurements="..pitchMeasurements.. " Pitch="..B744DR_autolandPitch)
        end
        print("pitchMeasurements="..pitchMeasurements.. " Pitch="..B744DR_autolandPitch.. " landingvviError="..landingvviError)
        lastVVI=simDR_vvi_fpm_pilot
      end
      B744DR_autolandPitch=(neutralPitch/pitchMeasurements)


end
--[[function preFlare_elevator()
      if simDR_AHARS_pitch_heading_deg_pilot>targetPitch+0.1 then
	      initElevator=-0.2*(simDR_AHARS_pitch_heading_deg_pilot-targetPitch)
      elseif simDR_AHARS_pitch_heading_deg_pilot<targetPitch-0.1 then
	      initElevator=0.2*(targetPitch-simDR_AHARS_pitch_heading_deg_pilot)
      end
      --simDR_elevator=B747_set_ap_animation_position(simDR_elevator,initElevator,-1,1,1)
end]]
function do_touchdown()
     --touchdown_elevator()
     if simDR_onGround==1 then
	      simDR_rudder=B747_set_ap_animation_position(simDR_rudder,0,-1,1,3)
     else
	      doYaw()
     end


      if simDR_onGround==1 and simDR_ind_airspeed_kts_pilot<65 then
        B747DR_ap_autoland=0
        seenApproach=false
        B747CMD_ap_reset:once()
		    simCMD_autopilot_servos_off:once()
        simDR_autopilot_servos_on=0
		    B747_ap_all_cmd_modes_off()
        B747DR_ap_lastCommand=simDRTime
        B747DR_ap_FMA_active_roll_mode=0
        simDR_autopilot_approach_status=0
      end --we done!
end

function runAutoland()
  local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
  local diff=simDR_reqHeading-simDR_AHARS_heading_deg_pilot


  if ((B747DR_autopilot_nav_status ==2 and B747DR_autopilot_gs_status==2) or simDR_autopilot_approach_status>0) then seenApproach=true end
  if numAPengaged<1 then
    --if (simDR_autopilot_approach_status==0 and active_autoland==false) or numAPengaged<1 then
       B747DR_ap_autoland=0
       B747DR_ap_active_land=0.0
       return false
   end
   if seenApproach==false then return false end


  if B747DR_ap_autoland<0 then
      return false --Go Around active
  elseif B747DR_ap_autoland==1 then
      if B747DR_ap_active_land>0.5  then
        do_touchdown()
	      return true
      end

      if simDR_radarAlt1 < 5 and B747DR_ap_active_land<0.5 then -- watch the bounce!
        end_Flare()
	      return true
      end

      if simDR_radarAlt1 > flareAt and simDR_radarAlt1 < 800 and numAPengaged>=2 then
        preLand_measure()
      elseif B747DR_ap_FMA_active_pitch_mode ~= 3 and numAPengaged>=2 then
        lastAlt=simDR_radarAlt1 --begin alt tracking
        start_flare()
      else
        during_Flare()
      end
     return true
  end


  retval=false
  if (B747DR_ap_AFDS_status_annun_pilot==3 or B747DR_ap_AFDS_status_annun_pilot==4) then
    if simDR_radarAlt1>200 then
      B747DR_ap_FMA_armed_roll_mode = 4
      B747DR_ap_FMA_armed_pitch_mode = 3
    end
    retval=true
  end

  if simDR_touchGround>0 then return true end
   -- print("prep autoland ".. simDR_radarAlt1 .. " "..B747DR_ap_FMA_active_roll_mode.. " "..B747DR_ap_FMA_active_pitch_mode.. " "..numAPengaged)
  pinThrottle=simDR_allThrottle

   --no nose dives in the last 100 feet
    if simDR_radarAlt1 < 100 and numAPengaged>2 then
      --preFlare_elevator()
      B747DR_ap_autoland=1
-- 	print("autoland preflare ".. simDR_radarAlt1.. " " .. simDR_AHARS_pitch_heading_deg_pilot .." " ..targetPitch)
      return true
    elseif simDR_radarAlt1 < 800 and numAPengaged>2 then
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

   return retval
end
