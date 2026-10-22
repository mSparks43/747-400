-- Yaw dampers (upper and lower rudder): the yaw and sideslip inputs and the damper law.
-- Moved unchanged out of B747.19.xt.hydraulics_override.lua (docs/overhaul/PLAN.md R-1).
-- B747.19.xt.hydraulicsmodel.lua loads it after pid.lua; flight_controls_override()
-- calls yaw_damper_system(doCompute) every frame.
local director_yawRecord={}
local director_currentyawRecord=1
local director_lastyawRecordUpdate=0
for i=1,30,1 do
    director_yawRecord[i]=0
end
local directoryawSampleRate=0.03
function ap_director_yaw()
    if math.abs(simDR_AHARS_roll_heading_deg_pilot)>5 then 
        return -simDR_sideslip
    else
        return simDR_AHARS_heading_deg_pilot
    end
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
    
    if mult==0 or target==nil then
        return 0
    end
    --print("mult "..mult)
    --print("target "..target)
    target=target*mult
    return target --B747_interpolate_value(currentValue,target,-1,1,speed)
end

function yaw_damper_system(doCompute)
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
