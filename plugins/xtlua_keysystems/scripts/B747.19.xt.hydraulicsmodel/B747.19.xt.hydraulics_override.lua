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
-- 2 rudder upper 1,3
-- 3 l elev inner
-- 4 r elev inner
-- 5 l elev outer
-- 6 r elev outer
-- 7 l ail inner sim/flightmodel/controls/wing2l_ail1def[0]
-- 8 r ail inner sim/flightmodel/controls/wing4r_ail1def[0]
-- 9 l ail outer sim/flightmodel/controls/wing4l_ail2def[0]
-- 10 r ail outer sim/flightmodel/controls/wing2r_ail2def[0]
local B747_pressureDRs={}
local controlRatios={}
controlRatios[0]=0
B747_pressureDRs[0]=0
local computeRate=0.0333 -- handle low FPS
local lastCompute=0
local doCompute=0
-- the hydraulic model's pressures (B747.19.xt.hyd_power.lua); each move of
-- a surface takes some, and a surface stops when its systems have no more
function pressure_input()
    for n=1,4,1 do
        B747_pressureDRs[n]=B747_hyd_power_psi(n)
    end
    
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
    -- what is left goes back to the model as the flow taken; the quantity's
    -- effect on pressure is in the model (the standpipe, HYD-21)
    for n=1,4,1 do
        B747_hyd_power_left(n,B747_pressureDRs[n])
    end
    B747DR_hyd_sys_pressure_1=B747_pressureDRs[1]
    B747DR_hyd_sys_pressure_2=B747_pressureDRs[2]
    B747DR_hyd_sys_pressure_3=B747_pressureDRs[3]
    B747DR_hyd_sys_pressure_4=B747_pressureDRs[4]

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
    if hydraulics_consumer({0,0,0,1},controlDiff[18]/3)==0 then
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
    -- rudder upper 1,3
    if hydraulics_consumer({1,0,1,0},controlDiff[2]*3)==0 then
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


    --1,3 L inboard aileron
    if hydraulics_consumer({1,0,1,0},controlDiff[7]*3)==0 then
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
    --3,4 R outboard aileron
    if hydraulics_consumer({0,0,1,1},controlDiff[10]*3)==0 then
        controlRatios[10]=B747_animate_value(lastControlValue[10],0,-100,100,1)
    end

    spoiler_consumption(controlDiff)
    flap_consumption(controlDiff)
    for i=1,numSurfaces,1 do
        lastControlValue[i]=controlRatios[i]
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

        if simDR_ias_pilot<20 then
            simDR_override_steering=0
        else
            simDR_override_steering=1
            simDR_steering[0]=B747_rescale(-1,-7,1,7,simDR_total_heading_ratio)
            simDR_steering[1]=B747_interpolate_value(simDR_steering[1],0,-77,77,0.3)
            simDR_steering[2]=B747_interpolate_value(simDR_steering[2],0,-77,77,0.3)
        end
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
        ap_pitch_assist(doCompute)
        ap_roll_assist(doCompute)
    else
        B747DR_sim_pitch_ratio=ap_pitch_assist(doCompute)
        B747DR_sim_roll_ratio=ap_roll_assist(doCompute)
    end
    yaw_damper_system(doCompute)

end
