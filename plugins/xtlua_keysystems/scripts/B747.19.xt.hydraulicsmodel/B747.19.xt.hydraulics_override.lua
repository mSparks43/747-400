-- mSparks 2022/01/07

--sim/operation/override/override_wheel_steer
--
--sim/operation/override/override_control_surfaces
--sim/multiplayer/controls/yoke_pitch_ratio	float[20]	y	[-1..1]	The deflection of the axis controlling pitch.
--sim/multiplayer/controls/yoke_roll_ratio	float[20]	y	[-1..1]	The deflection of the axis controlling roll.
--sim/multiplayer/controls/yoke_heading_ratio	float[20]	y	[-1..1]	The deflection of the axis controlling yaw.
--sim/operation/override/override_joystick_roll
--sim/operation/override/override_joystick_pitch
--sim/operation/override/override_joystick_heading
--sim/flightmodel2/wing/aileron2_deg[]
--sim/flightmodel2/wing/aileron1_deg[]
--sim/flightmodel2/wing/flap1_deg[]
--sim/flightmodel2/wing/flap2_deg[]
--sim/flightmodel2/controls/slat2_deploy_ratio
--sim/flightmodel2/controls/slat1_deploy_ratio
dofile("pid.lua")

lastBraking=0
lastPitch=0
lastRoll=0
lastYaw=0
lastFlaps=0
numSurfaces=26
lastControlValue={}
for i=0,numSurfaces,1 do
    lastControlValue[i]=0
end

-- 1 rudder lower 2,4
-- 2 rudder upper 1,2
-- 3 l elev inner
-- 4 r elev inner
-- 5 l elev outer
-- 6 r elev outer
-- 7 l ail inner sim/flightmodel/controls/wing2l_ail1def[0]
-- 8 r ail inner sim/flightmodel/controls/wing4r_ail1def[0]
-- 9 l ail outer sim/flightmodel/controls/wing4l_ail2def[0]
-- 10 r ail outer sim/flightmodel/controls/wing2r_ail2def[0]
brakeConsumption=0
local B747_pressureDRs={}
local controlRatios={}
controlRatios[0]=0
B747_pressureDRs[0]=0
local computeRate=0.0333 -- handle low FPS
local lastCompute=0
local doCompute=0
function pressure_input()
    B747_pressureDRs[1]=B747DR_hyd_sys_pressure_1
    B747_pressureDRs[2]=B747DR_hyd_sys_pressure_2
    B747_pressureDRs[3]=B747DR_hyd_sys_pressure_3
    B747_pressureDRs[4]=B747DR_hyd_sys_pressure_4
    
    controlRatios[1]=B747_controls_lower_rudder--simDR_rudder[10]
    controlRatios[2]=B747_controls_upper_rudder--simDR_rudder[10]

    controlRatios[3]=B747_controls_left_inner_elevator-- -simDR_elevator[0]
    controlRatios[4]=B747_controls_right_inner_elevator-- -simDR_elevator[0]
    controlRatios[5]=B747_controls_left_outer_elevator-- -simDR_elevator[0]
    controlRatios[6]=B747_controls_right_outer_elevator-- -simDR_elevator[0]

    controlRatios[7]=B747_controls_left_inner_aileron--simDR_left_aileron_inner
    controlRatios[8]=B747_controls_right_inner_aileron--simDR_right_aileron_inner
    controlRatios[9]=B747_controls_left_outer_aileron--simDR_left_aileron_outer
    controlRatios[10]=B747_controls_right_outer_aileron--simDR_right_aileron_outer

    --left wing
    controlRatios[11]=B747DR_spoiler1
    controlRatios[12]=B747DR_spoiler2
    controlRatios[13]=B747DR_spoiler3
    controlRatios[14]=B747DR_spoiler4
    controlRatios[15]=B747DR_spoiler5--simDR_spoiler5
    controlRatios[16]=B747DR_speedbrake3--simDR_spoiler67[0]

    --right wing
    controlRatios[17]=B747DR_speedbrake3--simDR_spoiler67[1]
    controlRatios[18]=B747DR_spoiler8--simDR_spoiler8
    controlRatios[19]=B747DR_spoiler9--simDR_spoiler910
    controlRatios[20]=B747DR_spoiler10--simDR_spoiler910
    controlRatios[21]=B747DR_spoiler11--simDR_spoiler1112
    controlRatios[22]=B747DR_spoiler12--simDR_spoiler1112

    --flaps left outer to right outer
    controlRatios[23]=B747DR_flap1--simDR_flap1
    controlRatios[24]=B747DR_flap2--simDR_flap2
    controlRatios[25]=B747DR_flap3--simDR_flap3
    controlRatios[26]=B747DR_flap4--simDR_flap4
    
end

function pressure_output()
    if B747DR_hyd_sys_restotal_1>0.1 then
        B747DR_hyd_sys_pressure_1=B747_pressureDRs[1]
    else
        B747DR_hyd_sys_pressure_1=0
    end
    if B747DR_hyd_sys_restotal_2>0.1 then
        B747DR_hyd_sys_pressure_2=B747_pressureDRs[2]
    else
        B747DR_hyd_sys_pressure_2=0
    end
    if B747DR_hyd_sys_restotal_3>0.1 then
        B747DR_hyd_sys_pressure_3=B747_pressureDRs[3]
    else
        B747DR_hyd_sys_pressure_3=0
    end
    if B747DR_hyd_sys_restotal_4>0.1 then
        B747DR_hyd_sys_pressure_4=B747_pressureDRs[4]
    else
        B747DR_hyd_sys_pressure_4=0
    end

    B747DR_rudder_lwr_pos=B747_animate_value(B747DR_rudder_lwr_pos,controlRatios[1],-100,100,20)
    B747DR_rudder_upr_pos=B747_animate_value(B747DR_rudder_upr_pos,controlRatios[2],-100,100,20)
    --B747_interpolate_value
    --[[B747DR_l_elev_inner   = B747_animate_value(B747DR_l_elev_inner,controlRatios[3],-100,100,20)
    B747DR_r_elev_inner   = B747_animate_value(B747DR_r_elev_inner,controlRatios[4],-100,100,20)
    B747DR_l_elev_outer   = B747_animate_value(B747DR_l_elev_outer,controlRatios[5],-100,100,20)
    B747DR_r_elev_outer   = B747_animate_value(B747DR_r_elev_outer,controlRatios[6],-100,100,20)]]--
    B747DR_l_elev_inner   = B747_interpolate_value(B747DR_l_elev_inner,controlRatios[3],-22,17,0.75)
    B747DR_r_elev_inner   = B747_interpolate_value(B747DR_r_elev_inner,controlRatios[4],-22,17,0.75)
    B747DR_l_elev_outer   = B747_interpolate_value(B747DR_l_elev_outer,controlRatios[5],-22,17,0.75)
    B747DR_r_elev_outer   = B747_interpolate_value(B747DR_r_elev_outer,controlRatios[6],-22,17,0.75)

    --[[B747DR_l_aileron_inner   = B747_animate_value(B747DR_l_aileron_inner,controlRatios[7],-100,100,10)
    B747DR_r_aileron_inner   = B747_animate_value(B747DR_r_aileron_inner,controlRatios[8],-100,100,10)
    B747DR_l_aileron_outer   = B747_animate_value(B747DR_l_aileron_outer,controlRatios[9],-100,100,10)
    B747DR_r_aileron_outer   = B747_animate_value(B747DR_r_aileron_outer,controlRatios[10],-100,100,10)]]
    B747DR_l_aileron_inner   = B747_interpolate_value(B747DR_l_aileron_inner,controlRatios[7],-20,20,0.75)
    B747DR_r_aileron_inner   = B747_interpolate_value(B747DR_r_aileron_inner,controlRatios[8],-20,20,0.75)
    B747DR_l_aileron_outer   = B747_interpolate_value(B747DR_l_aileron_outer,controlRatios[9],-25,15,0.75)
    B747DR_r_aileron_outer   = B747_interpolate_value(B747DR_r_aileron_outer,controlRatios[10],-25,15,0.75)


    --spoilers
    for i=1,12,1 do
        B747DR_spoilers[i]=B747_animate_value(B747DR_spoilers[i],controlRatios[i+10],-100,100,10)
    end
    simDR_spoiler12=(B747DR_spoilers[1]+B747DR_spoilers[2])/2
    simDR_spoiler34=(B747DR_spoilers[3]+B747DR_spoilers[4])/2
    simDR_spoiler5=(B747DR_spoilers[5])

    simDR_spoiler8=(B747DR_spoilers[8])
    simDR_spoiler910=(B747DR_spoilers[9]+B747DR_spoilers[10])/2
    simDR_spoiler1112=(B747DR_spoilers[11]+B747DR_spoilers[12])/2
    --spoiler stat
    outleft_spoilers=0
    for i=1,5,1 do
        outleft_spoilers=outleft_spoilers+B747DR_spoilers[i]
    end
    outright_spoilers=0
    for i=8,12,1 do
        outright_spoilers=outright_spoilers+B747DR_spoilers[i]
    end
    B747DR_outer_spoilers[0]=B747_animate_value(B747DR_outer_spoilers[0],outleft_spoilers/5,-100,100,10)
    B747DR_outer_spoilers[1]=B747_animate_value(B747DR_outer_spoilers[1],outright_spoilers/5,-100,100,10)

    --flaps
    --[[B747DR_flaps[1]=B747_animate_value(B747DR_flaps[1],controlRatios[23],-100,100,0.08)
    B747DR_flaps[2]=B747_animate_value(B747DR_flaps[2],controlRatios[24],-100,100,0.08)
    B747DR_flaps[3]=B747_animate_value(B747DR_flaps[3],controlRatios[25],-100,100,0.08)
    B747DR_flaps[4]=B747_animate_value(B747DR_flaps[4],controlRatios[26],-100,100,0.08)]]

    B747DR_flaps[1]=B747_interpolate_value(B747DR_flaps[1],controlRatios[23],0,30,45)
    B747DR_flaps[2]=B747_interpolate_value(B747DR_flaps[2],controlRatios[24],0,30,45)
    B747DR_flaps[3]=B747_interpolate_value(B747DR_flaps[3],controlRatios[25],0,30,45)
    B747DR_flaps[4]=B747_interpolate_value(B747DR_flaps[4],controlRatios[26],0,30,45)
    simDR_flap1=B747DR_flaps[1]
    simDR_flap2=B747DR_flaps[2]
    simDR_flap3=B747DR_flaps[3]
    simDR_flap4=B747DR_flaps[4]
end


function hydraulics_consumer(src,consumption)
    local take_index=0
    if consumption==0  then
        consumption=0.001
    end
    --print("consume "..src[1].." "..src[2].." "..src[3].." "..src[4].." "..consumption)
    for i=1,4,1 do
        if src[i]==1 and B747_pressureDRs[i]>consumption and B747_pressureDRs[i]>B747_pressureDRs[take_index] and B747_pressureDRs[i]>900 then
            take_index=i
        end

    end
    if take_index>0 then
        B747_pressureDRs[take_index]=B747_pressureDRs[take_index]-consumption
        return consumption
    else
        return 0
    end
end

function brake_accumulator()
    if simDR_parking_brake_ratio>lastBraking then
        brakeDiff=(simDR_parking_brake_ratio-lastBraking)*400
    else
        brakeDiff=0
    end
    if brakeDiff<simDR_hyd_press_1_2 then
        simDR_hyd_press_1_2=simDR_hyd_press_1_2-brakeDiff
    else
        simDR_hyd_press_1_2=0
    end
    brakeConsumption=brakeConsumption+brakeDiff
    lastBraking=simDR_parking_brake_ratio

    brakeConsumption=brakeConsumption-hydraulics_consumer({1,1,0,1},brakeConsumption)  
end
function flap_consumption(controlDiff)
    if hydraulics_consumer({0,0,0,1},controlDiff[23]*10)==0 then
        controlRatios[23]=lastControlValue[23]
    end
    if hydraulics_consumer({1,0,0,0},controlDiff[24]*10)==0 then
        controlRatios[24]=lastControlValue[24]
    end
    if hydraulics_consumer({1,0,0,0},controlDiff[25]*10)==0 then
        controlRatios[25]=lastControlValue[25]
    end
    if hydraulics_consumer({0,0,0,1},controlDiff[26]*10)==0 then
        controlRatios[26]=lastControlValue[26]
    end
end
function spoiler_consumption(controlDiff)
    --system 2, spoilers 2,3,10,11
    if hydraulics_consumer({0,1,0,0},controlDiff[12]/3)==0 then
        controlRatios[12]=B747_animate_value(lastControlValue[12],0,-100,100,1)
    end
    if hydraulics_consumer({0,1,0,0},controlDiff[13]/3)==0 then
        controlRatios[13]=B747_animate_value(lastControlValue[13],0,-100,100,1)
    end
    if hydraulics_consumer({0,1,0,0},controlDiff[20]/3)==0 then
        controlRatios[20]=B747_animate_value(lastControlValue[20],0,-100,100,1)
    end
    if hydraulics_consumer({0,1,0,0},controlDiff[21]/3)==0 then
        controlRatios[21]=B747_animate_value(lastControlValue[21],0,-100,100,1)
    end
    --system 3, spoilers 1,4,9,12
    if hydraulics_consumer({0,0,1,0},controlDiff[11]/3)==0 then
        controlRatios[11]=B747_animate_value(lastControlValue[11],0,-100,100,1)
    end
    if hydraulics_consumer({0,0,1,0},controlDiff[14]/3)==0 then
        controlRatios[14]=B747_animate_value(lastControlValue[14],0,-100,100,1)
    end
    if hydraulics_consumer({0,0,1,0},controlDiff[19]/3)==0 then
        controlRatios[19]=B747_animate_value(lastControlValue[19],0,-100,100,1)
    end
    if hydraulics_consumer({0,0,1,0},controlDiff[22]/3)==0 then
        controlRatios[22]=B747_animate_value(lastControlValue[22],0,-100,100,1)
    end

    --system 4, spoilers 5,6,7,8
    if hydraulics_consumer({0,0,0,1},controlDiff[15]/3)==0 then
        controlRatios[15]=B747_animate_value(lastControlValue[15],0,-100,100,1)
    end
    if hydraulics_consumer({0,0,0,1},controlDiff[16]/3)==0 then
        controlRatios[16]=B747_animate_value(lastControlValue[16],0,-100,100,1)
    end
    if hydraulics_consumer({0,0,0,1},controlDiff[17]/3)==0 then
        controlRatios[17]=B747_animate_value(lastControlValue[17],0,-100,100,1)
    end
    if hydraulics_consumer({0,0,0,1},controlDiff[1]/3)==0 then
        controlRatios[18]=B747_animate_value(lastControlValue[18],0,-100,100,1)
    end
end

function flight_controls_consumption()
    controlDiff={}
    for i=1,numSurfaces,1 do
        --print(i.." getting")
        --print(controlRatios[i])
        --print(lastControlValue[i])
        if controlRatios[i]>lastControlValue[i] then
            controlDiff[i]=(controlRatios[i]-lastControlValue[i])
        else
            controlDiff[i]=(lastControlValue[i]-controlRatios[i])
        end
        
    end

    -- steering 
    hydraulics_consumer({1,0,0,0},controlDiff[1]*5)
    --rudder lower 
    if hydraulics_consumer({0,1,0,1},controlDiff[1]*3)==0 then
        controlRatios[1]=B747_animate_value(lastControlValue[1],0,-100,100,10)
    end

    --[[if hydraulics_consumer({0,1,0,1},controlDiff[1]*3)==0 then
        controlRatios[1]=B747_animate_value(lastControlValue[1],0,-100,100,1)
    end]]
    -- rudder upper 
    if hydraulics_consumer({1,1,0,0},controlDiff[2]*3)==0 then
        controlRatios[2]=B747_animate_value(lastControlValue[2],0,-100,100,10)
    end
    
    --1,2 L inboard elev
    if hydraulics_consumer({1,1,0,0},controlDiff[3]*3)==0 then
        controlRatios[3]=B747_animate_value(lastControlValue[3],0,-100,100,20)
    end
    --3,4 R inboard elev
    if hydraulics_consumer({0,0,1,1},controlDiff[4]*3)==0 then
        controlRatios[4]=B747_animate_value(lastControlValue[4],0,-100,100,20)
    end
    --1 L outboard elev
    if hydraulics_consumer({1,0,0,0},controlDiff[5]*3)==0 then
        controlRatios[5]=B747_animate_value(lastControlValue[5],0,-100,100,20)
    end
    --4 R outboard elev
    if hydraulics_consumer({0,0,0,1},controlDiff[6]*3)==0 then
        controlRatios[6]=B747_animate_value(lastControlValue[6],0,-100,100,20)
    end


    --1,2 L inboard aileron
    if hydraulics_consumer({1,1,0,0},controlDiff[7]*3)==0 then
        controlRatios[7]=B747_animate_value(lastControlValue[7],0,-100,100,1)
    end
    --2,4 R inboard aileron
    if hydraulics_consumer({0,1,0,1},controlDiff[8]*3)==0 then
        controlRatios[8]=B747_animate_value(lastControlValue[8],0,-100,100,1)
    end
    --1,2 L outboard aileron
    if hydraulics_consumer({1,1,0,0},controlDiff[9]*3)==0 then
        controlRatios[9]=B747_animate_value(lastControlValue[9],0,-100,100,1)
    end
    --2,3,4 R outboard aileron
    if hydraulics_consumer({0,1,1,1},controlDiff[10]*3)==0 then
        controlRatios[10]=B747_animate_value(lastControlValue[10],0,-100,100,1)
    end

    spoiler_consumption(controlDiff)
    flap_consumption(controlDiff)
    for i=1,numSurfaces,1 do
        lastControlValue[i]=controlRatios[i]
    end
end

function normal_slats()
    if simDR_flap_ratio > 0.166 then
        simDR_innerslats_ratio  	= B747_interpolate_value(simDR_innerslats_ratio,1,0,1,8.5)
    elseif simDR_flap2+simDR_flap3 <2 then
        simDR_innerslats_ratio  	= B747_interpolate_value(simDR_innerslats_ratio,0,0,1,8.5)
    end
    if simDR_flap_ratio > 0.332 then
        simDR_outerslats_ratio  	= B747_interpolate_value(simDR_outerslats_ratio,1,0,1,8.5)
    elseif  simDR_flap2+simDR_flap3 <8 then
        simDR_outerslats_ratio  	= B747_interpolate_value(simDR_outerslats_ratio,0,0,1,8.5)
    end
end
local slatsRetract=false
function B747_slats()
    
    if simDR_flap_ratio==0 and simDR_innerslats_ratio==0 and simDR_outerslats_ratio==0 then
         return;
    elseif (B747DR_speedbrake_lever >0.5 and (simDR_prop_mode[0] == 3 or simDR_prop_mode[1] == 3 or simDR_prop_mode[2] == 3 or simDR_prop_mode[3] == 3)) 
        or (slatsRetract==true and B747DR_speedbrake_lever >0.5) then	
      simDR_innerslats_ratio = B747_interpolate_value(simDR_innerslats_ratio, 0.0, 0.0, 1.0, 8.5)
      slatsRetract=true
    else 
      slatsRetract=false
      normal_slats()
    end
   
 end
 local lastTrimmed=0
 local lastUp=0
 local lastDown=0
local pitchRecord={}
local currentPitchRecord=1
local lastPitchRecordUpdate=0
for i=1,10,1 do
    pitchRecord[i]=0
end


local director_pitchRecord={}
local director_currentPitchRecord=1
local director_lastPitchRecordUpdate=0
for i=1,10,1 do
    director_pitchRecord[i]=0
end
local director_rollRecord={}
local director_currentrollRecord=1
local director_lastrollRecordUpdate=0
for i=1,10,1 do
    director_rollRecord[i]=0
end

local director_yawRecord={}
local director_currentyawRecord=1
local director_lastyawRecordUpdate=0
for i=1,30,1 do
    director_yawRecord[i]=0
end
local last_simDR_ind_airspeed_kts_pilot=0
local last_simDR_AHARS_pitch_heading_deg_pilot=0
local last_altitude=0
local directorSampleRate=0.02
local directorRollSampleRate=0.1
local directoryawSampleRate=0.03
local lastAPTargetRoll=0
local capturedLocTime=0
local hasLoc=false
function ap_director_roll()
   if simDR_autopilot_nav_status ==2 and hasLoc==false then
        capturedLocTime=simDRTime
        hasLoc=true
        print("autoland capturedLocTime")
    elseif simDR_autopilot_nav_status ~=2 then
        hasLoc=false
    end
    if math.abs(B747DR_ap_ATT)>=5 then
        return B747DR_ap_ATT
    elseif (simDR_autopilot_nav_status ~=2 and B747DR_autopilot_nav_status==2) or 5>(simDRTime-capturedLocTime) then
        print("autoland estimating roll capturedLocTime "..capturedLocTime.. " simDRTime "..simDRTime .. " simDR_autopilot_nav_status "..simDR_autopilot_nav_status)
        return lastAPTargetRoll
    else
        lastAPTargetRoll=B747DR_ap_target_roll
        return B747DR_ap_target_roll
   end
end
function ap_director_yaw()
    if math.abs(simDR_AHARS_roll_heading_deg_pilot)>5 then 
        return -simDR_sideslip
    else
        return simDR_AHARS_heading_deg_pilot
    end
end
local lastPitchMode=0
local lastPitchModeChange=0
local lastRetVal=0
function ap_director_pitch_retVal(pitchMode,retVal)
    if pitchMode~=lastPitchMode then
        lastPitchModeChange=simDRTime
        lastPitchMode=pitchMode
        
    end
    local diff=simDRTime-lastPitchModeChange
    if diff<0.7 then
        if debug_flight_directors==1 then
            print("last ap_director_pitch_retVal "..lastRetVal .." retVal "..retVal .." pitchMode "..pitchMode)
        end
        last_simDR_AHARS_pitch_heading_deg_pilot=lastRetVal
        return lastRetVal
    end
    if debug_flight_directors==1 then
        print("ap_director_pitch_retVal "..retVal.." retVal "..retVal .." pitchMode "..pitchMode)
    end
    lastRetVal=retVal
    return retVal

end
local thisTargetGlideslipeFPM=-800
local last_simDR_hsi_vdef_dots_pilot=0
local lastSimDRTime=0
local last_speed_delta=0


function getGlideSlopeFPM()
    local diff=simDRTime-lastSimDRTime
    --[[if diff<1 then
        return thisTargetGlideslipeFPM
    end]]
    local speed_fpm=simDR_groundspeed*196.85
    thisTargetGlideslipeFPM=-math.tan(math.rad(simDR_glideslope1))*speed_fpm
    local nextVdef=simDR_hsi_vdef_dots_pilot 
   -- local correction=(8*nextVdef*nextVdef*nextVdef)
    if math.abs(nextVdef)>2.0 then
        nextVdef=nextVdef*3
    end
    local correction=(75*nextVdef)
    local resultTargetGlideslipeFPM=thisTargetGlideslipeFPM-correction --was 75 last testing
    --print("fin thisTargetGlideslipeFPM "..thisTargetGlideslipeFPM.." correction "..correction.." resultTargetGlideslipeFPM "..resultTargetGlideslipeFPM)
    if debug_flight_directors==1 then
        print("fin simDR_glideslope1 "..simDR_glideslope1.."thisTargetGlideslipeFPM "..thisTargetGlideslipeFPM.." correction "..correction.." resultTargetGlideslipeFPM "..resultTargetGlideslipeFPM)
    end
    return resultTargetGlideslipeFPM
  
end


local previous_pitchTime=0
local last_simDR_vvi_fpm_pilot=0
local last_vvi_update=0
local prev_vvi_update=0.5
local fpmBias=0
local lastFlapsFPM=0
function get_FPM_bias()
    local fpmBiasMax=6000
    if B747DR_flap_ratio~=lastFlapsFPM and B747DR_flap_lever_detent==0 and simDR_radarAlt1>3000 then
        local Flaps_change=B747DR_flap_ratio-lastFlapsFPM
        print("Flaps_change "..Flaps_change)
        fpmBias=fpmBias+fpmBiasMax*Flaps_change
        lastFlapsFPM=B747DR_flap_ratio
    end
    fpmBias=B747_interpolate_value(fpmBias,0.0,-fpmBiasMax,fpmBiasMax,10)
   -- print("fpmBias "..fpmBias)
    return fpmBias
end
function ap_director_pitch(pitchMode)
    time=simDRTime-previous_pitchTime
    previous_pitchTime=simDRTime
    --print("ap_director_pitch" ..time.. " "..directorSampleRate)
    if time>5 or time==0 then
        return last_simDR_AHARS_pitch_heading_deg_pilot
    end
   -- print("ap_director_pitc go")
    local alt_delta=simDR_pressureAlt1-last_altitude
    last_altitude=simDR_pressureAlt1
    local holdAlt=simDR_autopilot_altitude_ft 
    local refreshHoldAlt=simDR_autopilot_hold_altitude_ft
    local refreshfd=simDR_flight_director_pitch
    if simDR_autopilot_alt_hold_status==2 and (pitchMode~=5 and pitchMode~=6 and pitchMode~=9) then
        simDR_autopilot_alt_hold_status=0
    end
    if simDR_autopilot_alt_hold_status==2 then
        holdAlt=simDR_autopilot_hold_altitude_ft
    end
    if debug_flight_directors==1 then
        print("ap_director_pitch for "..pitchMode.." holdAlt "..holdAlt)
    end
    if B747DR_ap_autoland == 1 then 
        if debug_flight_directors==1 then
            print("pitching for autoland "..B744DR_autolandPitch .. " simDR_AHARS_pitch_heading_deg_pilot "..simDR_AHARS_pitch_heading_deg_pilot.. "simDR_touchGround "..simDR_touchGround)
        end
        directorSampleRate=0.02
        return ap_director_pitch_retVal(pitchMode,B744DR_autolandPitch)
    end
    --B747DR_ap_flightPhase == 3 and simDR_autopilot_vs_fpm == -500
    if ((pitchMode==4 and B747DR_ap_flightPhase ~= 3) or pitchMode==8) 
    and (simDR_pressureAlt1> holdAlt+B747DR_alt_capture_window or simDR_pressureAlt1< holdAlt-B747DR_alt_capture_window) then
        --local pitchError=math.abs(simDR_AHARS_pitch_heading_deg_pilot-last_simDR_AHARS_pitch_heading_deg_pilot)
        local pitchError=simDR_AHARS_pitch_heading_deg_pilot-last_simDR_AHARS_pitch_heading_deg_pilot

        local speed_delta=simDR_ind_airspeed_kts_pilot-last_simDR_ind_airspeed_kts_pilot
        --FLCH
        if debug_flight_directors==1 then
            print("ap_director_pitch for FLCH "..B747DR_ap_flightPhase)
        end
        last_simDR_ind_airspeed_kts_pilot=simDR_ind_airspeed_kts_pilot
        if (math.abs(simDR_autopilot_airspeed_kts-simDR_ind_airspeed_kts_pilot)>5) and math.abs(simDR_vvi_fpm_pilot)>100 then
            directorSampleRate=0.3
        else
            directorSampleRate=0.5
        end

        local rog=0.01+math.abs(0.5*speed_delta)
        if rog>0.3 then rog=0.3 end
        if simDR_pressureAlt1>29000 or simDR_ind_airspeed_kts_pilot<simDR_autopilot_airspeed_kts then
            rog=rog/3
        end
        local min_speedDelta=0
        local max_speedDelta=0
        local minSafeSpeed = B747DR_airspeed_Vmc + 10
        local speedDiff=math.abs(simDR_ind_airspeed_kts_pilot-simDR_autopilot_airspeed_kts)
        local canDescend = true
        local canAscend = true
       -- if simDR_pressureAlt1> holdAlt and simDR_vvi_fpm_pilot > -200 and simDR_ind_airspeed_kts_pilot<B747DR_airspeed_Vmax-10 then canAscend = false end
        --if simDR_pressureAlt1< holdAlt and simDR_vvi_fpm_pilot < 200 and simDR_ind_airspeed_kts_pilot>minSafeSpeed then canDescend = false end

        if simDR_vvi_fpm_pilot > 200 and (simDR_ind_airspeed_kts_pilot<simDR_autopilot_airspeed_kts-5) then canAscend = false end
        if simDR_vvi_fpm_pilot < -200 and (simDR_ind_airspeed_kts_pilot>simDR_autopilot_airspeed_kts+5) then canDescend = false end
        if B747DR_ap_inVNAVdescent>0 and simDR_vvi_fpm_pilot < -500 and simDR_autopilot_airspeed_kts< simDR_ind_airspeed_kts_pilot+5 then canDescend = false end
        if  speedDiff > 1 then
            if (simDR_autopilot_airspeed_kts< simDR_ind_airspeed_kts_pilot-1) then
                max_speedDelta=0.001+speedDiff/250
            else
                max_speedDelta=0.001+speedDiff/25
            end
            min_speedDelta=max_speedDelta/3
        end

        if ((simDR_autopilot_airspeed_kts> simDR_ind_airspeed_kts_pilot+1) and speed_delta<max_speedDelta 
            or (simDR_autopilot_airspeed_kts< simDR_ind_airspeed_kts_pilot-1) and speed_delta<-max_speedDelta) and pitchError<0.5 and canDescend
        then
            if debug_flight_directors==1 then
                print("-simDR_AHARS_pitch_heading_deg_pilot "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_autopilot_airspeed_kts "..simDR_autopilot_airspeed_kts.." simDR_ind_airspeed_kts_pilot "..simDR_ind_airspeed_kts_pilot.." speed_delta "..speed_delta.." min_speedDelta "..min_speedDelta.." max_speedDelta "..max_speedDelta.." rog "..rog)
            end
            last_simDR_AHARS_pitch_heading_deg_pilot= (last_simDR_AHARS_pitch_heading_deg_pilot-rog)
        elseif ((simDR_autopilot_airspeed_kts< simDR_ind_airspeed_kts_pilot-1) and speed_delta>-min_speedDelta 
            or (simDR_autopilot_airspeed_kts> simDR_ind_airspeed_kts_pilot+1) and speed_delta>min_speedDelta ) and pitchError>-0.5 and canAscend
        then
            if debug_flight_directors==1 then
                print("+simDR_AHARS_pitch_heading_deg_pilot "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_autopilot_airspeed_kts "..simDR_autopilot_airspeed_kts.." simDR_ind_airspeed_kts_pilot "..simDR_ind_airspeed_kts_pilot.." speed_delta "..speed_delta.." min_speedDelta "..min_speedDelta.." max_speedDelta "..max_speedDelta.." rog "..rog)
            end
            last_simDR_AHARS_pitch_heading_deg_pilot= (last_simDR_AHARS_pitch_heading_deg_pilot+rog)
        end

        last_altitude=simDR_pressureAlt1
        if last_simDR_AHARS_pitch_heading_deg_pilot<-3.5 then
            last_simDR_AHARS_pitch_heading_deg_pilot=-3.5
        elseif last_simDR_AHARS_pitch_heading_deg_pilot>15 then 
            last_simDR_AHARS_pitch_heading_deg_pilot=15
        end
        retval=last_simDR_AHARS_pitch_heading_deg_pilot
        last_simDR_AHARS_pitch_heading_deg_pilot=retval
        
        return ap_director_pitch_retVal(pitchMode,retval)
    elseif pitchMode~=2 and 
    (pitchMode==5 or pitchMode==9 or 
    (simDR_autopilot_alt_hold_status==2) or 
    (simDR_pressureAlt1< holdAlt+B747DR_alt_capture_window and simDR_pressureAlt1> holdAlt-B747DR_alt_capture_window)) then
        --ALT
        if debug_flight_directors==1 then
            print("ap_director_pitch for ALT")

        end 
        if simDR_autopilot_alt_hold_status~=2 then
            simDR_autopilot_hold_altitude_ft=simDR_autopilot_altitude_ft
            simDR_autopilot_alt_hold_status=2
            simDR_autopilot_vs_status=0
            simDR_autopilot_flch_status=0
            --cancel TOGA pitch
            B747DR_autopilot_TOGA_status=0 
            holdAlt=simDR_autopilot_hold_altitude_ft
        end
        local fpmBias=get_FPM_bias()
        local altDiff=math.abs(simDR_pressureAlt1-holdAlt+fpmBias*40)
        local targetFPM=(holdAlt-simDR_pressureAlt1)*2 --target alt in 30 secs
        --local pitchError=math.abs(simDR_AHARS_pitch_heading_deg_pilot-last_simDR_AHARS_pitch_heading_deg_pilot)
        local pitchError=simDR_AHARS_pitch_heading_deg_pilot-last_simDR_AHARS_pitch_heading_deg_pilot

        directorSampleRate=0.1
        local currentFPM=simDR_vvi_fpm_pilot+fpmBias
        local rog=0.001+0.00003*math.abs(currentFPM-targetFPM)
        --if simDR_pressureAlt1>29000 or (altDiff<B747DR_alt_capture_window) then
        if simDR_pressureAlt1>10000 or math.abs(currentFPM)<100 then
            rog=0.0001+0.00001*math.abs(currentFPM-targetFPM)
        end
        if currentFPM>targetFPM  and (pitchError<0.5 or (math.abs(fpmBias)>50 and pitchError<1.0)) then
            last_simDR_AHARS_pitch_heading_deg_pilot=last_simDR_AHARS_pitch_heading_deg_pilot-rog
            if debug_flight_directors==1 then
                print("-last_altitude "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_vvi_fpm_pilot "..currentFPM.." rog "..rog.." targetFPM "..targetFPM)
            end
        elseif currentFPM<targetFPM and pitchError>-0.5 or (math.abs(fpmBias)>50 and pitchError>-1.0) then
            if debug_flight_directors==1 then 
                print("+last_altitude "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_vvi_fpm_pilot "..currentFPM.." rog "..rog.." targetFPM "..targetFPM)
            end
            last_simDR_AHARS_pitch_heading_deg_pilot=last_simDR_AHARS_pitch_heading_deg_pilot+rog
        else
            if debug_flight_directors==1 then
                print("=last_altitude "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_vvi_fpm_pilot "..currentFPM.." rog "..rog.." targetFPM "..targetFPM.. " pitchError "..pitchError)
            end
        end
        if last_simDR_AHARS_pitch_heading_deg_pilot<-3.5 then
            last_simDR_AHARS_pitch_heading_deg_pilot=-3.5
        elseif last_simDR_AHARS_pitch_heading_deg_pilot>15 then 
            last_simDR_AHARS_pitch_heading_deg_pilot=15
        end
        retval=last_simDR_AHARS_pitch_heading_deg_pilot
        last_simDR_AHARS_pitch_heading_deg_pilot=retval
        return ap_director_pitch_retVal(pitchMode,retval)
    
    elseif pitchMode==4 or pitchMode==7 or pitchMode==6 or pitchMode==2 then --pitchMode==2 GLIDESLOPE
        local pitchError=simDR_AHARS_pitch_heading_deg_pilot-last_simDR_AHARS_pitch_heading_deg_pilot
        
        if debug_flight_directors==1 then
            print("ap_director_pitch for VS pitchError="..pitchError)
        end

        local targetFPM=simDR_autopilot_vs_fpm
        local currentFPM=simDR_vvi_fpm_pilot+get_FPM_bias()
        local minUpdateRate=2.0
        local vviDiff=simDRTime-last_vvi_update
        if vviDiff>2 and prev_vvi_update < 1 then
            prev_vvi_update=2.0 --give two seconds before reducing sample rate
            if debug_flight_directors==1 then
                print("prev_vvi_update=2.0") --recover overshoots
            end
        end
        if pitchMode==2 then --set FPM based on glideslope
            targetFPM=getGlideSlopeFPM()
        --    print("getGlideSlopeFPM="..targetFPM.." dots="..simDR_hsi_vdef_dots_pilot)
             --minUpdateRate=B747_rescale(0,0.5,2.5,0.1,math.abs(simDR_hsi_vdef_dots_pilot)) -- be faster on glideslope
        --else
        --    print("standard FPM="..targetFPM.." dots="..simDR_hsi_vdef_dots_pilot)
        end
        if debug_flight_directors==1 then
            print("autopilot FPM="..currentFPM.." target="..targetFPM)
        end
        local vviError=math.abs(currentFPM-targetFPM)
        --[[if ((pitchError<0.3 and vviError<50) or simDR_autopilot_alt_hold_status==2) and pitchMode~=2 then
            directorSampleRate=0.5
        elseif pitchError<0.3 then
            directorSampleRate=minUpdateRate
        end]]--
        --if pitchError<1.3 then
        directorSampleRate=math.min(B747_rescale(0,1,500,0.2,math.abs(vviError)),minUpdateRate,prev_vvi_update)
        prev_vvi_update=directorSampleRate
        --end
       
        --local rog=0.001+0.00004*vviError/(time*30)
        local rog=0.001+0.000003*math.abs(currentFPM-targetFPM)
        local div=B747_rescale(100,30,300,0.3,simDR_ind_airspeed_kts_pilot)
        if debug_flight_directors==1 then
            print("directorSampleRate "..directorSampleRate.." div "..div)
        end
        --[[if simDR_pressureAlt1>29000 then
            rog=rog/3
        elseif vviError>400 then
                rog=rog*15
        elseif simDR_pressureAlt1<12000 then
                rog=rog*3
        end]]
        rog=rog*div
        local speed_delta=(currentFPM-last_simDR_vvi_fpm_pilot)/(time*30)
        last_simDR_vvi_fpm_pilot=currentFPM
        local min_speedDelta=0
        local max_speedDelta=0
        if  vviError > 10 then
            max_speedDelta=vviError/5
            min_speedDelta=vviError/50
        end

        --if pitchError<0.5 then
            if (currentFPM>targetFPM and speed_delta>-min_speedDelta and pitchError<0.5) --primary
            or (currentFPM<targetFPM and speed_delta<-max_speedDelta and pitchError<0.5) then
                last_simDR_AHARS_pitch_heading_deg_pilot=last_simDR_AHARS_pitch_heading_deg_pilot-rog
                last_vvi_update=simDRTime
                if debug_flight_directors==1 then
                    print("-last_simDR_AHARS_pitch_heading_deg_pilot "..last_simDR_AHARS_pitch_heading_deg_pilot)
                    print("-simDR_vvi_fpm_pilot "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_vvi_fpm_pilot "..currentFPM.." rog "..rog.." speed_delta "..speed_delta.." min_speedDelta "..min_speedDelta.." max_speedDelta "..max_speedDelta)
                end
            elseif (simDR_vvi_fpm_pilot<targetFPM and speed_delta<min_speedDelta and pitchError>-0.5) --primary
            or (currentFPM>targetFPM and speed_delta>max_speedDelta and pitchError>-0.5)  then
                if debug_flight_directors==1 then 
                    print("+last_simDR_AHARS_pitch_heading_deg_pilot "..last_simDR_AHARS_pitch_heading_deg_pilot)
                    print("+simDR_vvi_fpm_pilot "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_vvi_fpm_pilot "..currentFPM.." rog "..rog.." speed_delta "..speed_delta.." min_speedDelta "..min_speedDelta.." max_speedDelta "..max_speedDelta)
                end
                last_vvi_update=simDRTime
                last_simDR_AHARS_pitch_heading_deg_pilot=last_simDR_AHARS_pitch_heading_deg_pilot+rog
            elseif debug_flight_directors==1 then 
                print("=simDR_vvi_fpm_pilot "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_vvi_fpm_pilot "..currentFPM.." rog "..rog.." speed_delta "..speed_delta.." min_speedDelta "..min_speedDelta.." max_speedDelta "..max_speedDelta)
            end
       -- end
        if last_simDR_AHARS_pitch_heading_deg_pilot<-3.5 then
            last_simDR_AHARS_pitch_heading_deg_pilot=-3.5
        elseif last_simDR_AHARS_pitch_heading_deg_pilot>10 then 
            last_simDR_AHARS_pitch_heading_deg_pilot=10
        end
        retval=last_simDR_AHARS_pitch_heading_deg_pilot
        last_simDR_AHARS_pitch_heading_deg_pilot=ap_director_pitch_retVal(pitchMode,retval)--retval
        --
        --if pitchMode==2 then
        --    ap_director_pitch_retVal(pitchMode,retval)--log it
        --    return retval
        --else
            return last_simDR_AHARS_pitch_heading_deg_pilot--ap_director_pitch_retVal(pitchMode,retval)
        --end
    elseif pitchMode==1 then
       -- print("simDR_autopilot_TOGA_pitch_deg ="..simDR_autopilot_TOGA_pitch_deg)
        if debug_flight_directors==1 then
            print("ap_director_pitch for TOGA")
        end
        directorSampleRate=0.1
        retval=B747_interpolate_value(last_simDR_AHARS_pitch_heading_deg_pilot,simDR_autopilot_TOGA_pitch_deg,2,12,5)
        last_simDR_AHARS_pitch_heading_deg_pilot=retval
        ap_director_pitch_retVal(pitchMode,retval) --make sure pitch retval is fresh
        return retval--ap_director_pitch_retVal(pitchMode,retval)
    --elseif pitchMode==2 then
     --   directorSampleRate=0.5
    else
        --print("ap_director_pitch for off")
        last_simDR_AHARS_pitch_heading_deg_pilot=0
        return 0
    end
    local retval=simDR_flight_director_pitch
    if debug_flight_directors==1 then
        print("+simDR_flight_director_pitch "..simDR_AHARS_pitch_heading_deg_pilot.." simDR_flight_director_pitch "..simDR_flight_director_pitch.." B747DR_ap_FMA_active_pitch_mode "..B747DR_ap_FMA_active_pitch_mode.." holdAlt "..holdAlt)
    end
    if retval<simDR_AHARS_pitch_heading_deg_pilot-5 then
        retval=simDR_AHARS_pitch_heading_deg_pilot-5
    elseif retval>simDR_AHARS_pitch_heading_deg_pilot+5 then 
        retval=simDR_AHARS_pitch_heading_deg_pilot+5
    end

    if pitchMode==5 or pitchMode==9 then
        directorSampleRate=1.0
        if retval<-1.5 then
            retval=-1.5
        elseif retval>10 then 
            retval=10
        end
    else
        --if B747DR_ap_FMA_active_pitch_mode==2 then
            directorSampleRate=1.0
        --else
        --    directorSampleRate=0.5
       -- end
        if retval<-10 then
            retval=-10
        elseif retval>10 then 
            retval=10
        end
    end
    last_altitude=simDR_pressureAlt1
    last_simDR_AHARS_pitch_heading_deg_pilot=retval
    return ap_director_pitch_retVal(pitchMode,retval)
end
local current_roll_intregal=0
function ap_director_roll_integral()
    --return B747DR_ap_target_roll
    local displayUpdate=false
    --[[if math.abs(simDR_AHARS_roll_heading_deg_pilot)>5 then
        directorRollSampleRate=0.1
    else
        directorRollSampleRate=1
    end]]
    directorRollSampleRate=B747_rescale(0,1,10,0.3,math.abs(simDR_AHARS_roll_heading_deg_pilot))
    
    if (simDRTime-director_lastrollRecordUpdate)>directorRollSampleRate then
        displayUpdate=true
        director_lastrollRecordUpdate=simDRTime
        director_rollRecord[director_currentrollRecord]=ap_director_roll()
        director_currentrollRecord=director_currentrollRecord+1
        --print("currentPitchRecord "..director_currentPitchRecord)
        if director_currentrollRecord>10 then
            director_currentrollRecord=1
        end
        current_roll_intregal=0
        for i=1,10,1 do
            current_roll_intregal=current_roll_intregal+director_rollRecord[i]
           --if displayUpdate then print("i "..i.." = " ..pitchRecord[i].. " " ..retval) end
        end
    end
    local retval=current_roll_intregal/10
    B747DR_flight_director_roll=retval
   -- if displayUpdate then print("retval "..retval.." "..simDRTime) end
    return retval
end

function dampSlip()
    --[[local retval=0
    for i=1,30,1 do
        local tVal=director_yawRecord[i]
        retval=retval+tVal
       --if displayUpdate then print("i "..i.." = " ..pitchRecord[i].. " " ..retval) end
    end
    retval=retval/30]]
    return ap_director_yaw()--retval
end
function dampYaw()
    --local displayUpdate=false
    
    
    local retval=director_yawRecord[1]
    local left=0
    if retval>270 then left=1 end
    for i=2,30,1 do
        local tVal=director_yawRecord[i]
        if left==1 and tVal<90 then tVal=tVal+360 end
        if left==0 and tVal>270 then tVal=tVal-360 end
        retval=retval+tVal
       --if displayUpdate then print("i "..i.." = " ..pitchRecord[i].. " " ..retval) end
    end
    retval=retval/30
    if retval<0 then retval=retval+360 end

    retval=getHeadingDifference(retval,simDR_AHARS_heading_deg_pilot)
    --if displayUpdate then print("ap_director_yaw_integral "..retval.." simDR_AHARS_heading_deg_pilot "..simDR_AHARS_heading_deg_pilot) end
    return retval
end
function clearYawIntegral()
    local val=0
    if math.abs(simDR_AHARS_roll_heading_deg_pilot)<5 then 
        val=simDR_AHARS_heading_deg_pilot
    end
    for i=1,30,1 do
        director_yawRecord[i]=val
    end
end
local lastDamperSystem=0 --0 == slip, 1==yaw
local current_yaw_intregal=0
function ap_director_yaw_integral()
    if (simDRTime-director_lastyawRecordUpdate)>directoryawSampleRate then
         director_lastyawRecordUpdate=simDRTime
         director_yawRecord[director_currentyawRecord]=ap_director_yaw()
         director_currentyawRecord=director_currentyawRecord+1

         if director_currentyawRecord>30 then
             director_currentyawRecord=1
         end
        if math.abs(simDR_AHARS_roll_heading_deg_pilot)>5 then 
            if lastDamperSystem~=0 then clearYawIntegral() end
            lastDamperSystem=0
            current_yaw_intregal= dampSlip()
        else
            if lastDamperSystem~=1 then clearYawIntegral() end
            lastDamperSystem=1
            current_yaw_intregal= dampYaw()
        end
     end
    
    return current_yaw_intregal
end
local current_pitch_intregal=0
function ap_director_pitch_integral()
    local displayUpdate=false
    if (simDRTime-director_lastPitchRecordUpdate)>directorSampleRate then
        displayUpdate=true
        director_lastPitchRecordUpdate=simDRTime
        director_pitchRecord[director_currentPitchRecord]=ap_director_pitch(B747DR_ap_FMA_active_pitch_mode)
        director_currentPitchRecord=director_currentPitchRecord+1
        --print("currentPitchRecord "..director_currentPitchRecord)
        if director_currentPitchRecord>10 then
            director_currentPitchRecord=1
        end
        current_pitch_intregal=0
        for i=1,10,1 do
            current_pitch_intregal=current_pitch_intregal+director_pitchRecord[i]
        -- if displayUpdate then print("i "..i.." = " ..pitchRecord[i].. " " ..current_pitch_intregal) end
        end
    end
    
    local retval=current_pitch_intregal/10
    B747DR_flight_director_pitch=retval
    --if displayUpdate then print("retval "..retval.." "..simDRTime) end
    return retval
end

local trimrate=25
function doTrim()

    if simDRTime-lastTrimmed<0.2 or simDR_radarAlt1<500 then return end
    lastTrimmed=simDRTime
    local ratioWindow=0.05
    if B747DR_ap_FMA_active_pitch_mode==2 or simDR_autopilot_alt_hold_status==2 then
        ratioWindow=0.01 --quick trim on glideslope and alt hold
    elseif B747DR_ap_FMA_active_pitch_mode==4 or B747DR_ap_FMA_active_pitch_mode==8 or (B747DR_ap_FMA_active_pitch_mode==6 and B747DR_ap_inVNAVdescent>0) then
        ratioWindow=0.2 --limit trim activity when pitching for speed
    end

    
    if simDR_ind_airspeed_kts_pilot>230 then
        trimrate=60
    elseif simDR_ind_airspeed_kts_pilot<220 then
        trimrate=30
    end
    if B747DR_sim_pitch_ratio>ratioWindow then
        simDR_elevator_trim=B747_interpolate_value(simDR_elevator_trim,1.0,-1,1,trimrate)
        lastTrimmed=simDRTime+1 
        --print("up trim "..ratioWindow)
    elseif B747DR_sim_pitch_ratio<-ratioWindow then
        simDR_elevator_trim=B747_interpolate_value(simDR_elevator_trim,-1.0,-1,1,trimrate) 
        lastTrimmed=simDRTime+1 
        --print("down trim "..ratioWindow)
    end

end
local previous_simDR_AHARS_pitch_heading_deg_pilot=0

local pitchPid = newPid()
pitchPid.minout=-1
pitchPid.maxout=1
pitchPid.target=0
pitchPid.input = 0
pitchPid:compute()

function ap_pitch_assist()
    local flight_director_pitch=ap_director_pitch_integral()
    local target=0
    local retval=B747_interpolate_value(B747DR_sim_pitch_ratio,0,-1,1,20)
    local refreshsimDR_electric_trim=simDR_electric_trim
    local refresh_trim=simDR_elevator_trim
    B747DR_pidPitchP=B747_rescale(3000,B747DR_pidPitchPL,40000,B747DR_pidPitchPH,B747DR_autopilot_altitude_ft_pfd)
    B747DR_pidPitchI=B747DR_pidPitchP --scale this with P
    pitchPid.kp=B747DR_pidPitchP
    pitchPid.ki=B747DR_pidPitchI
    pitchPid.kd=B747DR_pidPitchD
    
    if simDR_autopilot_servos_on>0 and (B747DR_ap_FMA_active_pitch_mode>0 or B747DR_ap_autoland == 1) then
        simDR_electric_trim=0
        pitchPid.input = simDR_AHARS_pitch_heading_deg_pilot
        pitchPid.target= flight_director_pitch
        if doCompute==1 then
            pitchPid:compute()
        end
        retval=pitchPid.output

       -- print("elevatorRequest "..elevatorRequest .." pitchChange "..pitchChange .." targetElevator "..targetElevator .." elevatorRate "..elevatorRate)
        doTrim()
       -- print("flight_director_pitch "..flight_director_pitch .." simDR_AHARS_pitch_heading_deg_pilot "..simDR_AHARS_pitch_heading_deg_pilot .." retval "..retval)
    else
        pitchPid:compute(true)
        simDR_electric_trim=1
    end
    if retval==nil then return 0 end
    return retval
end

local previous_simDR_AHARS_roll_heading_deg_pilot=0

local rollPid = newPid()
rollPid.minout=-1
rollPid.maxout=1
rollPid.target=0
rollPid.input = 0
rollPid:compute()

function ap_roll_assist()
    local retval=B747_interpolate_value(B747DR_sim_roll_ratio,0,-1,1,20)
    local flight_director_roll=ap_director_roll_integral()
    rollPid.kp=B747DR_pidRollP
    rollPid.ki=B747DR_pidRollI
    B747DR_pidRollD=B747_rescale(3000,B747DR_pidRollDL,30000,B747DR_pidRollDH,B747DR_autopilot_altitude_ft_pfd)
    rollPid.kd=B747DR_pidRollD
    if simDR_autopilot_servos_on>0 and (B747DR_ap_FMA_active_roll_mode>0) then
        rollPid.input = simDR_AHARS_roll_heading_deg_pilot
        rollPid.target= flight_director_roll
        if doCompute==1 then
            rollPid:compute()
        end
        local speed=B747_rescale(0.5,2,4,0.4,math.abs(flight_director_roll-simDR_AHARS_roll_heading_deg_pilot))
        if rollPid.output==nil then return 0 end
        retval=B747_interpolate_value(B747DR_sim_roll_ratio,rollPid.output,-1,1,speed) 
        --print("flight_director_roll "..flight_director_roll.." speed "..speed .." simDR_AHARS_roll_heading_deg_pilot "..simDR_AHARS_roll_heading_deg_pilot .." retval "..retval)
    else
        rollPid:compute(true)
    end
    return retval
end
local yawPid = newPid()
yawPid.minout=-1
yawPid.maxout=1
yawPid.target=0
yawPid.input = 0
yawPid:compute()

function get_damper_value(currentValue)
    local target=yawPid.output
    
    local speed=0.4
    
    --[[if math.abs(simDR_AHARS_roll_heading_deg_pilot)<5 and math.abs(yawPid.input)<0.35 then
        speed=2
        target=0
    end]]
    local mult=1
    if math.abs(simDR_AHARS_roll_heading_deg_pilot)<5 then
        mult=B747_rescale(0,0,0.35,1,yawPid.input)
    end
    target=target*mult
    return target --B747_interpolate_value(currentValue,target,-1,1,speed)
end

function yaw_damper_system()
    if math.abs(simDR_AHARS_roll_heading_deg_pilot)<5 then
        B747DR_pidyawP = B747_rescale(3000, B747DR_pidyawProllL,30000, B747DR_pidyawProllH,B747DR_autopilot_altitude_ft_pfd)
        B747DR_pidyawI = 0.000003
        B747DR_pidyawD = B747_rescale(3000,B747DR_pidyawDrollL,30000,B747DR_pidyawDrollH,B747DR_autopilot_altitude_ft_pfd)
    else
        B747DR_pidyawP = B747_rescale(3000, B747DR_pidyawPslipL,30000, B747DR_pidyawPslipH,B747DR_autopilot_altitude_ft_pfd)
        B747DR_pidyawI = 0.000003
        B747DR_pidyawD = B747_rescale(3000,B747DR_pidyawDslipL,30000,B747DR_pidyawDslipH,B747DR_autopilot_altitude_ft_pfd)
    end

    yawPid.kp=B747DR_pidyawP
    yawPid.ki=B747DR_pidyawI
    yawPid.kd=B747DR_pidyawD
    yawPid.input = ap_director_yaw_integral()
    if doCompute==1 then
        yawPid:compute()
    end
    --print(B747DR_yaw_damper_lwr.." "..get_damper_value())
    if B747DR_yaw_damper_upr_on ==1 then
        
         B747DR_yaw_damper_upr=B747_interpolate_value(B747DR_yaw_damper_upr,get_damper_value(B747DR_yaw_damper_upr),-1,1,0.3)
    else

        B747DR_yaw_damper_upr=B747_interpolate_value(B747DR_yaw_damper_upr,0,-1,1,0.3)
    end

    if B747DR_yaw_damper_lwr_on ==1 then
        B747DR_yaw_damper_lwr=B747_interpolate_value(B747DR_yaw_damper_lwr,get_damper_value(B747DR_yaw_damper_lwr),-1,1,0.3)
    else
        B747DR_yaw_damper_lwr=B747_interpolate_value(B747DR_yaw_damper_lwr,0,-1,1,0.3)
    end
end


function flight_controls_override()
    --[[override=1
    for i=1,4,1 do
        if B747_pressureDRs[i]>800 then
            --override=0
        end
    end]] --this ver always overrides
    if (simDRTime-lastCompute)>computeRate then
        doCompute=1
        lastCompute=simDRTime
    else
        doCompute=0
    end  
    simDR_override_control_surfaces=1--override
    if B747_pressureDRs[1]>1000 then
        simDR_override_steering=0
    else
        simDR_override_steering=1
    end
    --Rudder ratio changer
    B747DR_rudder_ratio=1.0-B747_rescale(150,0,450,0.84375,simDR_ias_pilot)
    B747DR_elevator_ratio=1.0--(1.0-B747_rescale(150,0,350,0.84375,simDR_ias_pilot))*-1
    B747DR_l_aileron_outer_lockout   = 1.0-B747_rescale(232,0,238,1.0,simDR_ias_pilot)
    B747DR_r_aileron_outer_lockout   = (1.0-B747_rescale(232,0,238,1.0,simDR_ias_pilot))*-1
    B747_slats()
    if((simDRTime - B747DR_switching_servos_on)<2) then
        ap_pitch_assist()
        ap_roll_assist()
    else
        B747DR_sim_pitch_ratio=ap_pitch_assist()
        B747DR_sim_roll_ratio=ap_roll_assist()
    end
    yaw_damper_system()

end
