--[[
*****************************************************************************************
* Program Script Name	:	B747.70.autopilot.monitor
* Author Name			:	Mark Parker (mSparks)
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2021-03-23	0.01a				Start of Dev
*
*
*
*
--]]

--get the glideslope to an FMS entry
function getSlope(fmsIndex)
    local distanceNM=getDistance(simDR_latitude,simDR_longitude,fmsO[fmsIndex][5],fmsO[fmsIndex][6])
    local nextDistanceInFeet=distanceNM*6076.12
    local time=distanceNM*30.8666/(simDR_groundspeed) --time in minutes, gs in m/s....
    local vdiff=B747DR_ap_vnav_target_alt-simDR_pressureAlt1-early --to be negative
    local vspeed=vdiff/time
    local slope=math.atan2(vdiff,nextDistanceInFeet)*-57.2958
    print("i "..fmsIndex.." slope" ..slope)
    return slope
end
function VNAV_NEXT_ALT(numAPengaged,fms)
    local began=false
    local targetAlt=simDR_autopilot_altitude_ft
    local targetIndex=0
    local currentIndex=0
    local dist_to_TOD=(B747BR_totalDistance-B747BR_tod)
    local lowerAlt=tonumber(getFMSData("desrestalt"))
    --print("FMS ="..fmsJSON)
    for i=1,table.getn(fms),1 do
      --print("i="..i.." began="..tostring(began))
        if fms[i][10]==true then
            began=true
            currentIndex=i
            local nextDistance=getDistance(simDR_latitude,simDR_longitude,fms[i][5],fms[i][6])
            B747DR_fmstargetDistance=nextDistance
            if nextDistance>dist_to_TOD and dist_to_TOD>0 and B747DR_ap_inVNAVdescent==0 and B747BR_cruiseAlt>0 then
            targetAlt=B747BR_cruiseAlt
            targetIndex=i
            break
            end
            if dist_to_TOD<0 and fms[i][9]>0 and fms[i][9]<lowerAlt and fms[i][2] ~= 1 and numAPengaged>0 then targetAlt=fms[i][9] targetIndex=i break end
        elseif began==true then
            local nextDistance=getDistance(simDR_latitude,simDR_longitude,fms[i][5],fms[i][6])
            local thisDistance=getDistance(fms[i-1][5],fms[i-1][6],fms[i][5],fms[i][6])
            B747DR_fmstargetDistance=B747DR_fmstargetDistance+thisDistance
            if nextDistance>dist_to_TOD and dist_to_TOD>0 and B747DR_ap_inVNAVdescent==0 and B747BR_cruiseAlt>0 then
            targetAlt=B747BR_cruiseAlt
            targetIndex=i
            break
            end
            if B747BR_totalDistance>0 and dist_to_TOD>0 and B747DR_ap_inVNAVdescent==0 and (nextDistance)>dist_to_TOD then
            break
            end
            if dist_to_TOD<0 and fms[i][9]>0 and fms[i][9]<lowerAlt and fms[i][2] ~= 1 then targetAlt=fms[i][9] targetIndex=i break end
        end
    end
    if targetIndex==0 and dist_to_TOD<0 then
        local endI = table.getn(fms)
        B747DR_fmstargetIndex=endI
        B747DR_ap_vnav_target_alt=fms[endI][9]
    else
        B747DR_fmstargetIndex=targetIndex
        B747DR_ap_vnav_target_alt=targetAlt
    end
    return targetAlt
end

function VNAV_CLB_ALT(numAPengaged,fms)
    local targetAlt=VNAV_NEXT_ALT(numAPengaged,fms)
    --print("VNAV_CLB_ALT 1".. simDR_autopilot_altitude_ft .. " "  .. targetAlt .. " ")
    local lastHold=simDRTime-B747DR_mcp_hold_pressed
    if targetAlt>B747DR_autopilot_altitude_ft and simDR_pressureAlt1<B747DR_autopilot_altitude_ft+100 and lastHold>30 then
        targetAlt=B747DR_autopilot_altitude_ft
    end
    local mcpDiff=simDR_pressureAlt1-B747DR_autopilot_altitude_ft
    if B747DR_mcp_hold~=1 and simDR_autopilot_alt_hold_status==2 and targetAlt==B747DR_autopilot_altitude_ft
     and (mcpDiff<B747DR_alt_capture_window and mcpDiff>-B747DR_alt_capture_window)
     and lastHold>30 and B747BR_cruiseAlt>B747DR_autopilot_altitude_ft-B747DR_alt_capture_window
     and targetAlt~=B747BR_cruiseAlt then
        B747DR_mcp_hold=1
        simDR_autopilot_vs_status=0
        simDR_autopilot_flch_status=0
        print("set B747DR_mcp_hold in VNAV_CLB_ALT")
    end
    if B747DR_mcp_hold==0 then simDR_autopilot_altitude_ft=targetAlt end

    --print("VNAV_CLB_ALT 2".. simDR_autopilot_altitude_ft .. " "  .. targetAlt .. " ")
end

function VNAV_CLB(numAPengaged,fmsO)
    VNAV_CLB_ALT(numAPengaged,fmsO)
    if simDR_autopilot_alt_hold_status == 2 and B747DR_ap_vnav_state == 1 and B747DR_mcp_hold==1 then
        B747DR_ap_lastCommand = simDRTime
        B747DR_ap_vnav_state=2
    end
    if B747DR_mcp_hold==1 then return end


    local start=B747DR_fmscurrentIndex
    local waypointAlt=fmsO[start][9]
    if waypointAlt==0 or simDR_radarAlt1<3000 then waypointAlt=B747DR_autopilot_altitude_ft end
    local waypointDiff=waypointAlt-simDR_pressureAlt1
    local mcpDiff=simDR_pressureAlt1-B747DR_autopilot_altitude_ft

    --print("VNAV_CLB "..waypointDiff .. " " .. mcpDiff.. " " .. waypointAlt .. " " .. start.. " " .. fmsO[start][9].. " " .. simDR_pressureAlt1)
    if simDR_autopilot_alt_hold_status==2 and (waypointDiff>1000 and (mcpDiff>1000 or mcpDiff<-1000)) then
        setVNAVState("vnavcalcwithTargetAlt",0)
		if getVNAVState("manualVNAVspd")==0 then
		    setVNAVState("gotVNAVSpeed",false)
		    B747_vnav_speed()
		end
        B747DR_ap_vnav_state = 3 --resume
        --computeVNAVAlt(fmsO)
        B747DR_ap_lastCommand = simDRTime
        print("UPDATE VNAV_CLB "..waypointDiff .. " " .. mcpDiff.. " " .. waypointAlt .. " " .. start.. " " .. fmsO[start][9].. " " .. simDR_pressureAlt1)
    end
    if B747DR_engine_TOGA_mode == 1 and simDR_radarAlt1>1500 then
        B747DR_engine_TOGA_mode = 0
    end
    if (simDR_pressureAlt1 < B747BR_cruiseAlt-B747DR_alt_capture_window or simDR_pressureAlt1 > B747BR_cruiseAlt+B747DR_alt_capture_window) and simDR_radarAlt1>400 then
        if simDR_autopilot_flch_status == 0 and
        (simDR_autopilot_alt_hold_status == 0 or numAPengaged==0 or B747DR_ap_vnav_state == 1 or B747DR_ap_vnav_state == 3
           -- or (waypointDiff>1000 and (mcpDiff>1000 or mcpDiff<-1000))
        ) then
            --if (simDR_allThrottle>=0.94) then
                simCMD_autopilot_flch_mode:once()
                simDR_autopilot_flch_status=2
                simDR_autopilot_vs_status=0
                simDR_autopilot_alt_hold_status=0
                --simDR_autopilot_alt_hold_status=0
                B747DR_engine_TOGA_mode = 0
                B747DR_autopilot_TOGA_status=0
                B747DR_ap_autoland=-1
                B747DR_ap_lastCommand = simDRTime
                print("flch > 1000 feet climb ")
                --B747DR_ap_vnav_state=2

            --end
        end
        if simDR_autopilot_flch_status > 0 or simDR_autopilot_alt_hold_status > 0  and B747DR_engine_TOGA_mode == 0 then
            --print("VNAV_CLB simDR_autopilot_flch_status > 0")
            B747DR_ap_vnav_state=2
            if simDR_pressureAlt1 < B747BR_cruiseAlt-B747DR_alt_capture_window then B747DR_ap_thrust_mode=2 end
        end
    elseif (simDR_pressureAlt1 >= B747BR_cruiseAlt-B747DR_alt_capture_window and simDR_pressureAlt1 <= B747BR_cruiseAlt+B747DR_alt_capture_window) and simDR_radarAlt1>400 then
        if (simDR_autopilot_alt_hold_status == 0) then
            --simCMD_autopilot_alt_hold_mode:once()
            simDR_autopilot_alt_hold_status=2
            simDR_autopilot_vs_status=0
            simDR_autopilot_flch_status=0
            simDR_autopilot_hold_altitude_ft=B747BR_cruiseAlt
            print("alt hold +/-300 feet cruise")
            B747DR_ap_lastCommand = simDRTime
        end
        if simDR_autopilot_flch_status > 0 or simDR_autopilot_alt_hold_status > 0 then
            --print("at cruise")
            B747DR_ap_vnav_state=2
        end
    end


end
function VNAV_CRZ(numAPengaged,dist)
    --print("VNAV_CRZ alt hold")
    if simDR_autopilot_alt_hold_status == 0 or simDR_autopilot_vs_status~=0 or simDR_autopilot_flch_status~=0 then
        --simCMD_autopilot_alt_hold_mode:once()
        simDR_autopilot_alt_hold_status=2
        simDR_autopilot_vs_status=0
        simDR_autopilot_flch_status=0
        simDR_autopilot_hold_altitude_ft=B747BR_cruiseAlt
        B747DR_ap_lastCommand = simDRTime
        print("alt hold < 50nm from TOD")
    end
    if B747DR_mcp_hold==1 and simDR_autopilot_alt_hold_status > 0 and simDR_autopilot_hold_altitude_ft==B747BR_cruiseAlt then
        B747DR_mcp_hold=0
        print("clear MCP hold in VNAV_CRZ")
    end
    if simDR_autopilot_alt_hold_status > 0 then
       -- print("VNAV_CRZ alt hold")
        B747DR_ap_vnav_state=2
    end
    if simDR_autopilot_hold_altitude_ft>B747BR_cruiseAlt and simDR_autopilot_alt_hold_status > 0 and dist>0 then
        B747BR_cruiseAlt=simDR_autopilot_hold_altitude_ft
    end
end
function VNAV_DES_ALT(numAPengaged,fms)
    local targetAlt=VNAV_NEXT_ALT(numAPengaged,fms)
    local lastHold=simDRTime-B747DR_mcp_hold_pressed

    if targetAlt<B747DR_autopilot_altitude_ft and simDR_pressureAlt1>B747DR_autopilot_altitude_ft-100 and lastHold>30 then
        targetAlt=B747DR_autopilot_altitude_ft
    end
    local mcpDiff=simDR_pressureAlt1-B747DR_autopilot_altitude_ft
    if simDR_autopilot_alt_hold_status==2 and targetAlt==B747DR_autopilot_altitude_ft   and (mcpDiff<B747DR_alt_capture_window and mcpDiff>-B747DR_alt_capture_window) and lastHold>30 and B747BR_cruiseAlt>B747DR_autopilot_altitude_ft-B747DR_alt_capture_window then
        B747DR_mcp_hold=1
        print("set B747DR_mcp_hold in VNAV_DES_ALT")
    end
    if B747DR_mcp_hold==0 then simDR_autopilot_altitude_ft=targetAlt end
end


function VNAV_DES(numAPengaged,fms)
    VNAV_DES_ALT(numAPengaged,fms) --sets altitude target
    local diff2 = simDR_autopilot_altitude_ft - simDR_pressureAlt1
    local diff3 = B747DR_autopilot_altitude_ft- simDR_pressureAlt1
    local lastHold=simDRTime-B747DR_mcp_hold_pressed
    local descentstatus=0
    local diff = simDRTime - B747DR_ap_lastCommand

	if diff < 0.2 then
		return
	end


    if B747DR_switchingIASMode==1 then return end
    local upperAlt=math.max(tonumber(getFMSData("desspdtransalt")),tonumber(getFMSData("desrestalt")))
    --print("upperAlt "..upperAlt)
    --if B747DR_ap_ias_mach_window_open == 1 then

        if simDR_pressureAlt1>upperAlt and simDR_ind_airspeed_kts_pilot>=B747DR_airspeed_Vmc+15 then
            --descentstatus = simDR_autopilot_flch_status
            simDR_autopilot_vs_status=0
            simDR_autopilot_flch_status=2
            simDR_autopilot_alt_hold_status=0
            B747DR_ap_thrust_mode=2
            descentstatus = 2
        else
            --descentstatus = simDR_autopilot_vs_status
            simDR_autopilot_vs_status=2
            simDR_autopilot_flch_status=0
            simDR_autopilot_alt_hold_status=0
            B747DR_ap_thrust_mode=0
            descentstatus = 2
       end
   -- else
   --    descentstatus = simDR_autopilot_vs_status
    --end
   -- print("VNAV_DES B747DR_ap_inVNAVdescent=" .. " "..B747DR_ap_inVNAVdescent.. " "..diff2.. " "..diff3.. " "..B747DR_ap_vnav_state.. " " .. B747DR_mcp_hold)


    if B747DR_mcp_hold>0 then return end --in an MCP hold, just stay there
    if descentstatus == 0 and B747DR_ap_inVNAVdescent ~=0 then
        print("simDR_autopilot_vs_status  == 0 clear descent "..B747BR_fpe)
        B747DR_ap_inVNAVdescent = 0
        B747DR_ap_lastCommand=simDRTime
        return
    end
    --Past TOD and MCP ALT at current alt - activate VNAV ALT

    local isManualSpeed=false
    --Not started descent, not in VNAV ALT, past TOD, begin descending
    if B747DR_ap_inVNAVdescent ==0 and diff2<=0 and (diff3<=-100 or diff3>=0)
            and B747BR_totalDistance>0 and (B747BR_totalDistance-B747BR_tod<0.0 or beganDescent()==true)
            and simDR_radarAlt1>1000
            and B747BR_fpe>-400
                 then
        if diff3<0 then --mcp dial is below current altitude
            --entering descent from alt hold with window open, close it for a few seconds to establish descent
            if B747DR_ap_ias_mach_window_open == 1 and simDR_autopilot_alt_hold_status==2 then
                B747DR_ap_ias_mach_window_open = 0
                --simDR_allThrottle=0
                B747DR_switchingIASMode=1
                isManualSpeed=true
                run_after_time(B747_updateIASWindow, 10.0)
            end
            B747DR_ap_inVNAVdescent =1
            B747DR_ap_flightPhase=3
            setDescent(true)
            print("Begin descent 3")
            getDescentTarget()
            simDR_autopilot_vs_status=2
            simDR_autopilot_flch_status=0
            simDR_autopilot_alt_hold_status=0
            simCMD_autopilot_vert_speed_mode:once()
            B747DR_ap_lastCommand=simDRTime+2
            return
        else
            B747DR_mcp_hold=2
            print("set B747DR_mcp_hold")
            return
        end
    end
    --

    if (B747DR_ap_inVNAVdescent ==1 or (beganDescent()==true and simDR_autopilot_alt_hold_status==2)) and diff2<=-500 and (diff3<=-500 or diff3>=500) and (descentstatus == 0 or simDR_autopilot_alt_hold_status==2) and simDR_radarAlt1>1000 then
        if B747DR_autopilot_gs_status < 1 then
            --if B747DR_ap_ias_mach_window_open == 0 or simDR_pressureAlt1<=upperAlt or simDR_ind_airspeed_kts_pilot<B747DR_airspeed_Vmc+15 then

            if simDR_pressureAlt1>upperAlt and B747DR_ap_ias_mach_window_open == 1 and simDR_autopilot_flch_status == 0 then
                simCMD_autopilot_flch_mode:once()
                simDR_autopilot_flch_status=2
                simDR_autopilot_vs_status=0
                simDR_autopilot_alt_hold_status=0
                B747DR_ap_thrust_mode = 2

                B747DR_ap_lastCommand=simDRTime
            elseif simDR_autopilot_vs_status==0 then
                B747DR_ap_lastCommand=simDRTime
                simCMD_autopilot_vert_speed_mode:once()
            end
            --simCMD_pause:once()
            simDR_autopilot_alt_hold_status=0
            --simDR_autopilot_vs_status=2
           -- else
           --     simCMD_autopilot_flch_mode:once()
            --    simDR_autopilot_alt_hold_status=0
            --end
            B747DR_ap_inVNAVdescent =2
            B747DR_ap_flightPhase=3
            setDescent(true)
            print("Resume descent")
            return
        end
    end
    local spdval=tonumber(getFMSData("desspd"))
    local forceOn=false
    if B747DR_ap_ias_dial_value<=spdval and simDR_autopilot_airspeed_is_mach==0 and B747DR_ap_ias_mach_window_open == 0 then forceOn=true end
    if B747BR_totalDistance-B747BR_tod<=0 and simDR_autopilot_airspeed_is_mach==0 and B747DR_ap_ias_mach_window_open == 0 and isManualSpeed==false then forceOn=true end
    if B747DR_ap_inVNAVdescent >0 and B747DR_autothrottle_active == 1 and simDR_allThrottle<0.02 and forceOn==false then							-- AUTOTHROTTLE IS "ON"
       -- simCMD_autopilot_autothrottle_off:once()									-- DEACTIVATE THE AUTOTHROTTLE
        B747DR_autothrottle_active=0
        B747DR_ap_lastCommand=simDRTime
        print("fix idle throttle")
        return
    elseif B747DR_autothrottle_active == 0 and (simDR_ind_airspeed_kts_pilot<B747DR_airspeed_Vmc+15 or forceOn==true) and isATEnabled() then
        --simCMD_autopilot_autothrottle_on:once()
        B747DR_autothrottle_active=1
        B747DR_ap_lastCommand=simDRTime
        if B747DR_engine_TOGA_mode ==1 then B747DR_engine_TOGA_mode = 0 end	-- CANX ENGINE TOGA IF ACTIVE
        print("fix idle throttle to climb/maintain")
        return
    end

    if simDR_autopilot_vs_status == 2 and B747DR_fmstargetIndex>=2 then
        setDescentVSpeed()
    end
    if simDR_autopilot_hold_altitude_ft>B747BR_cruiseAlt and simDR_autopilot_alt_hold_status > 0 and (B747BR_totalDistance-B747BR_tod)>0 then
        B747BR_cruiseAlt=simDR_autopilot_hold_altitude_ft
    end
    B747DR_ap_vnav_state=2
end
local last_THR_REF=0

function B747_monitor_THR_REF_AT()
    local timediff=simDRTime-B747DR_ap_lastCommand

    if timediff<0.1 then return end
    if not(isATEnabled()) then return end
    if ((B747DR_ap_thrust_mode == 0 and simDR_autopilot_flch_status>0) or (simDR_radarAlt1>2000 and( simDR_pressureAlt1< simDR_autopilot_altitude_ft+B747DR_alt_capture_window and simDR_pressureAlt1> simDR_autopilot_altitude_ft-B747DR_alt_capture_window))) and B747DR_autothrottle_active == 0 then
        print("B747_monitor_THR_REF_AT B747DR_ap_thrust_mode " .. B747DR_ap_thrust_mode)
        B747DR_ap_thrust_mode = 0
        B747DR_autothrottle_active=1
        B747DR_ap_lastCommand = simDRTime
        return
    end
    if B747DR_ap_FMA_autothrottle_mode~=5 then return end

    local n1_pct=math.max(B747DR_display_N1[0],B747DR_display_N1[1],B747DR_display_N1[2],B747DR_display_N1[3])
    local lastChange=simDRTime-last_THR_REF

    --print("THR REF B747_monitor_THR_REF_AT".." simDR_autopilot_autothrottle_on "..simDR_autopilot_autothrottle_on.." simDR_override_throttles "..simDR_override_throttles.." simDR_autopilot_altitude_ft "..simDR_autopilot_altitude_ft.." simDR_pressureAlt1 "..simDR_pressureAlt1)
   if (B747DR_autothrottle_active == 0 or simDR_override_throttles==1)
    and (simDR_pressureAlt1< simDR_autopilot_altitude_ft+B747DR_alt_capture_window and simDR_pressureAlt1> simDR_autopilot_altitude_ft-B747DR_alt_capture_window) then
        B747DR_ap_flightPhase=2
		print("B747DR_ap_thrust_mode " .. B747DR_ap_thrust_mode)
		B747DR_ap_thrust_mode = 0
		print("B747DR_ap_thrust_mode " .. B747DR_ap_thrust_mode)
        B747DR_ap_lastCommand = simDRTime
        return
    end

    --[[if lastChange>1 or lastChange<-1 then return end --wait for engines to stabilise
    if lastChange==0 and needNew==true then return end --wait for engines to stabilise, wait for update N1]]
    local ref_throttle=100
    local altDiff = simDR_autopilot_altitude_ft - simDR_pressureAlt1

    if B747DR_ap_thrust_mode==2 and altDiff<0 then
        ref_throttle=math.floor(20+B747_rescale(-10000,0,0,30,altDiff))
        B747DR_ap_flightPhase=3
        --print("THR REF descend at ref_throttle "..ref_throttle.." altDiff "..altDiff)
    elseif simDR_radarAlt1<1000 and B747DR_ap_thrust_mode<3 then --set acceleration height here
        if toderate==1 then ref_throttle=96
        elseif toderate==2 then ref_throttle=86
        end
        B747DR_ap_flightPhase=0
    else
        if B747DR_ap_thrust_mode==0 and timediff>0.5 then
            --print("B747DR_ap_thrust_mode =1 @ "..timediff)
            B747DR_ap_thrust_mode=1

        end
        if altDiff>1000 then
            B747DR_ap_flightPhase=1
        end
        if clbderate==1 then ref_throttle=96
        elseif clbderate==2 then ref_throttle=86
        end
    end


    local wait=0
    local thrustDiff=ref_throttle-n1_pct
    if (thrustDiff<0) then
        thrustDiff=thrustDiff*-1
    end
    if thrustDiff<2 then wait=0.2
    elseif thrustDiff<10 then wait=0.1
    elseif thrustDiff<20 then wait=0.05 end
    --print("THR REF="..ref_throttle.. " simDR_allThrottle="..n1_pct.. " wait="..wait.. " B747DR_ap_thrust_mode="..B747DR_ap_thrust_mode)
    if lastChange<wait then return end --wait for engines to stabilise
    --[[if B747DR_autothrottle_active == 1 and timediff>0.5 then
        B747DR_ap_thrust_mode=0
        return
    end]]
    last_THR_REF=simDRTime

    --Marauder28
    --Defer throttle control to EEC module
    --[[if (string.match(simConfigData["data"].PLANE.engines, "CF6") or string.match(simConfigData["data"].PLANE.engines, "PW") or string.match(simConfigData["data"].PLANE.engines, "RB")) and
        (string.match(B747DR_ref_thr_limit_mode, "TO") or string.match(B747DR_ref_thr_limit_mode, "CLB")  or string.match(B747DR_ref_thr_limit_mode, "GA")) then
        return
    end
    --Marauder28

    if (n1_pct < (ref_throttle-0.2)) and simDR_allThrottle<0.99 then
	    simCMD_ThrottleUp:once()
    elseif (n1_pct > (ref_throttle+0.8)) and simDR_allThrottle>0.0 and B747DR_ap_flightPhase>2 then
        smCMD_ThrottleDown:once()
    end
    if (n1_pct > (ref_throttle+0.8)) and simDR_allThrottle>0.0 and B747DR_ap_flightPhase>2 and simDR_autopilot_airspeed_kts< simDR_ind_airspeed_kts_pilot then
        simCMD_ThrottleDown:once()
    end]]

end
function checkMCPAlt(dist)
    local eta=dist/simDR_groundspeed

    if eta>0.0334 then
        B747DR_fmc_notifications[33]=0
        --print("checkMCPAlt "..eta.. " "..dist)
        return
    end

    local diff3 = B747DR_autopilot_altitude_ft- simDR_pressureAlt1
    --print("checkMCPAlt "..eta.. " "..dist.. " "..diff3)
    if diff3>-1000 and B747DR_autopilot_altitude_ft>B747BR_cruiseAlt-1000 then
        B747DR_fmc_notifications[33]=1
    else
        B747DR_fmc_notifications[33]=0
    end
end
local lastVNAVSwitch=0
function VNAV_modeSwitch(fmsO)
    --if B747BR_cruiseAlt < 10 then return end --no cruise alt set, not needed because cant set to 1 without this
    if B747DR_ap_vnav_state == 0 then
        B747_monitor_THR_REF_AT()
        return
    end --not requested
    local dist=B747BR_totalDistance-B747BR_tod

    if B747DR_ap_inVNAVdescent >0 and B747DR_autothrottle_active == 0 and isATEnabled() and simDR_allThrottle>0 and simDR_radarAlt1>1000 and B747DR_ap_FMA_autothrottle_mode==5 then
        simCMD_ThrottleDown:once()
    else
        B747_monitor_THR_REF_AT()
    end
    if simDR_autopilot_alt_hold_status==2 and B747DR_ap_flightPhase<3 then
        B747DR_ap_flightPhase=2
    end
    local diff=simDRTime-B747DR_ap_lastCommand
    local diff2=simDRTime-lastVNAVSwitch
    if diff<0.5 or diff2<0.1 then return end --mode switch at 0.1 second intervals

    local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode


    --print("checkMCPAlt "..eta.. " "..dist.. " "..diff3)

    if (dist>10 and simDR_pressureAlt1<(B747BR_cruiseAlt-math.max(B747DR_alt_capture_window,500))) or (dist>0 and simDR_radarAlt1<5000 and B747DR_ap_inVNAVdescent==0) then
        VNAV_CLB(numAPengaged,fmsO) --climb to cruise
        B747DR_ap_inDescent = 0
    elseif dist>0 and B747DR_ap_inVNAVdescent==0 and simDR_radarAlt1<3000 then
        lastVNAVSwitch=simDRTime
    elseif dist>0 and B747DR_ap_inVNAVdescent==0 then
        B747DR_ap_inDescent = 0
        VNAV_CRZ(numAPengaged,dist) --go to alt hold if not in descent
        checkMCPAlt(dist)
    else
        B747DR_ap_inDescent = 1
        VNAV_DES(numAPengaged,fmsO)
        checkMCPAlt(dist)
    end
    lastVNAVSwitch=simDRTime

end
function LNAV_modeSwitch()
    --[[print("Nav status "..simDR_autopilot_nav_status)
    print("Heading status "..simDR_autopilot_heading_status)
    print("Roll status "..simDR_autopilot_roll_status)
    print("sync_degrees "..simDR_autopilot_roll_sync_degrees)
    print("ap_state "..simDR_autopilot_state)]]
end
function aileronTrim()
    --[[return
    local numAPengaged = B747DR_ap_cmd_L_mode + B747DR_ap_cmd_C_mode + B747DR_ap_cmd_R_mode
    if numAPengaged==0 then return end
    --Flight envelope protection
    if math.abs(B747DR_capt_ap_roll)>15 and math.abs(simDR_capt_roll)>15 then
        simDR_ap_aileron_trim=B747_animate_value(simDR_ap_aileron_trim,B747DR_capt_ap_roll/5,-6,6,1)
    else
        simDR_ap_aileron_trim=B747_animate_value(simDR_ap_aileron_trim,0,-6,6,5)
    end]]--
    --print("trim " .. B747DR_capt_ap_roll .. " " .. simDR_ap_aileron_trim)

end
function toBits(num)
    -- returns a table of bits, least significant first.
    local t={} -- will contain the bits
    while num>0 do
        rest=math.fmod(num,2)
        t[#t+1]=rest
        num=(num-rest)/2
    end
    return t
end
--custom autothrottle for THR REF

function B747_monitorAT()

    local diff=simDRTime-B747DR_ap_lastCommand
    if diff<0.5 then return end --mode switch at 0.5 second intervals
    if simDR_autopilot_autothrottle_enabled~=0 then

        simDR_autopilot_autothrottle_enabled=0
    end
    --make sure autothrottle is in the correct mode for the FMA
    --[[local ap_state=toBits(simDR_autopilot_state)
    local fmsArm=0
    local fmsactive=0
    if table.getn(ap_state) >=13 then fmsArm=ap_state[13] end
    if table.getn(ap_state) >=14 then fmsactive=ap_state[14] end ]]
    --[[print("A/T " .. simDR_autopilot_autothrottle_enabled.. " ap_state "..simDR_autopilot_state
    .. " FMS ARM "..fmsArm
    .. " FMS ACTIVE "..fmsactive
    .. " course "..simDR_autopilot_course
    .. " type "..simDR_autopilot_destination_type
    .. " index "..simDR_autopilot_destination_index)]]
    --disconnects if 2 more more (more than one) engine inop
    local numRun=0;
    if B747DR_display_N1[0]>15.0 then numRun=numRun+1 end
    if B747DR_display_N1[1]>15.0 then numRun=numRun+1 end
    if B747DR_display_N1[2]>15.0 then numRun=numRun+1 end
    if B747DR_display_N1[3]>15.0 then numRun=numRun+1 end

    if numRun<3 or B747DR_autothrottle_fail>0 then
        if B747DR_autothrottle_active==1 then
            print("2+ engines inop or fail AT")
            --simCMD_autopilot_autothrottle_off:once()
            B747DR_autothrottle_active=0
            B747DR_ap_lastCommand=simDRTime
            B747DR_autothrottle_fail=1
        end
        if B747DR_ap_FMA_autothrottle_mode>0 then
            print("B747DR_ap_FMA_autothrottle_mode fail AT")
            B747DR_autothrottle_fail=1
        end
        B747DR_engine_TOGA_mode = 0 
    end

   --AT OFF
    if not(isATEnabled()) then --or simDR_radarAlt1<25
        if B747DR_autothrottle_active==1 then
            print("AT off")
            --simCMD_autopilot_autothrottle_off:once()
            B747DR_autothrottle_active=0
            B747DR_ap_lastCommand=simDRTime
        end

        return
    end

    --ALT/VS/GS
    --if simDR_autopilot_alt_hold_status == 2 then

    --if  B747DR_ap_FMA_active_pitch_mode==5 or B747DR_ap_FMA_active_pitch_mode==9 then
    if  simDR_autopilot_alt_hold_status==2 or B747DR_ap_FMA_active_pitch_mode==2 then
        if B747DR_ap_thrust_mode~=0 then
            B747DR_ap_lastCommand=simDRTime
        end
        B747DR_ap_thrust_mode=0
        B747DR_engine_TOGA_mode = 0	-- CANX ENGINE TOGA IF ACTIVE
        B747DR_autopilot_TOGA_status=0
        if B747DR_ap_flightPhase<3 then
            B747DR_ap_flightPhase=2
        end

        if B747DR_autothrottle_active==0 then
            print("simDR_autopilot_alt_hold_status")
            B747DR_autothrottle_active=1
            B747DR_ap_lastCommand=simDRTime
        end

        return
    end
    if (B747DR_ap_FMA_active_pitch_mode == 9
    or B747DR_ap_FMA_active_pitch_mode == 7) and B747DR_ap_vnav_state > 0
    or B747DR_ap_FMA_active_pitch_mode == 2 then
        if B747DR_autothrottle_active==0 then
            print("B747DR_ap_FMA_active_pitch_mode")
            B747DR_autothrottle_active=1
            if B747DR_engine_TOGA_mode ==1 then B747DR_engine_TOGA_mode = 0 end	-- CANX ENGINE TOGA IF ACTIVE
            B747DR_ap_lastCommand=simDRTime
        end
        B747DR_ap_thrust_mode=0

        return
    end

    if B747DR_autothrottle_active==1 and B747DR_ap_FMA_active_pitch_mode==2 and B747DR_ap_FMA_autothrottle_mode ~= 3 then -- SPD
        B747DR_ap_lastCommand=simDRTime
        B747DR_ap_FMA_autothrottle_mode=3
        return
    end
end

function getWCAforHeading(theading)
    local tas = simDR_TAS_mps * 1.94384 -- true airspeed in knots
    local heading=math.fmod(theading,360)
    if heading<0 then heading=heading+360 end
    local wca=0
    if B747DR_ND_Wind_Bearing<-90 then
        --rhs
        local angle=math.rad(180-(B747DR_ND_Wind_Bearing*-1))
        wca=(simDR_wind_speed_kts/tas)*math.sin(angle)
        --local latWind=math.sin(angle)*simDR_wind_speed
      elseif B747DR_ND_Wind_Bearing<0 then
        --rhs
        local angle=math.rad(B747DR_ND_Wind_Bearing*-1)
        wca=(simDR_wind_speed_kts/tas)*math.sin(angle)
        --local latWind=math.sin(angle)*simDR_wind_speed
      elseif B747DR_ND_Wind_Bearing>90 then
        --lhs
        local angle=math.rad(180-B747DR_ND_Wind_Bearing)
        wca=-(simDR_wind_speed_kts/tas)*math.sin(angle)
       --local latWind=-math.sin(angle)*simDR_wind_speed
      else --0 to 90
        --lhs
        local angle=math.rad(B747DR_ND_Wind_Bearing)
        wca=-(simDR_wind_speed_kts/tas)*math.sin(angle)
        --local latWind=-math.sin(angle)*simDR_wind_speed
      end
      wca=math.deg(wca)

      local hV=heading +wca
      hV=math.fmod(hV,360)
      if hV<0 then hV=hV+360 end
      return hV
end
local onApproach=false
function B747_updateApproachHeading(fmsO)

   --[[print("simDR_hsi_ldef_dots_nav1 " .. simDR_hsi_ldef_dots_nav1 ..
    " simDR_hsi_ldef_dots_nav2 " .. simDR_hsi_ldef_dots_nav2  ..
    " simDR_hsi_nav1_horizontal_signal " ..simDR_hsi_nav1_horizontal_signal ..
    " simDR_hsi_nav1_horizontal_signal " ..simDR_hsi_nav2_horizontal_signal ..
    " simDR_hsi_nav1_vertical_signal " ..simDR_hsi_nav1_vertical_signal ..
    " simDR_hsi_nav2_vertical_signal " ..simDR_hsi_nav2_vertical_signal ..
    " simDR_nav1_gs_flag " .. simDR_nav1_gs_flag ..
    " simDR_nav2_gs_flag " ..  simDR_nav2_gs_flag ..
    " simDR_hsi_vdef_dots_pilot " .. simDR_hsi_vdef_dots_pilot)]]--

    local diff = simDRTime - B747DR_ap_lastCommand
    if simDR_autopilot_nav_status==1 and simDR_hsi_nav1_horizontal_signal==1 and simDR_hsi_nav2_horizontal_signal==1  and diff>0.5 then
        simDR_autopilot_nav_status=2
        B747DR_ap_lastCommand = simDRTime
    end

    if simDR_autopilot_nav_status==2 and simDR_nav1_gs_flag ==0 and simDR_nav2_gs_flag ==0 and simDR_autopilot_gs_status==1 and math.abs(simDR_hsi_vdef_dots_pilot)<0.3 and simDR_hsi_nav1_vertical_signal==1 and simDR_hsi_nav2_vertical_signal ==1 and diff>0.5 then
        simDR_autopilot_gs_status=2
        B747DR_ap_lastCommand = simDRTime
    end

    if simDR_autopilot_nav_status==2 then
        if simDR_hsi_nav1_horizontal_signal==1 and simDR_hsi_nav2_horizontal_signal==1 then
            if simDR_autopilot_heading_status == 0 and diff>0.5 then
                simCMD_autopilot_heading_select:once()
                B747DR_ap_ATT = 0.0
                B747DR_ap_lastCommand = simDRTime
            end
            --print("simDR_radio_nav_obs_deg[0] " ..simDR_radio_nav_obs_deg[0])
            local bearing=(simDR_radio_nav1_bearing_deg +simDR_radio_nav2_bearing_deg)/2
            --local diffap = math.min(math.abs(getHeadingDifference(simDR_radio_nav_obs_deg[0], bearing)),30)*2
            local diffap = getHeadingDifference(simDR_radio_nav_obs_deg[0], bearing)*2
            if diffap<-60 then
                diffap=-60
            elseif diffap>60 then
                diffap=60
            end
            local modHeading=(simDR_hsi_ldef_dots_nav1+simDR_hsi_ldef_dots_nav2)*4+diffap
            local hV=getWCAforHeading(simDR_radio_nav_obs_deg[0]+modHeading)
            --print("hV " ..hV.." modHeading " ..modHeading .." diffap "..diffap)
            simDR_autopilot_heading_deg =	 hV
            if onApproach==false and math.abs(diffap) < 5 then
                --print("onApproach")
                onApproach=true
            end
            if onApproach==true and math.abs(simDR_hsi_ldef_dots_nav1+simDR_hsi_ldef_dots_nav2) > 4 then
                onApproach=false
                --print("LOC glitching")
                simDR_autopilot_nav_status=1
            end
        else
           -- print("LOC signal glitching")
            simDR_autopilot_nav_status=1
        end
        return
    end

    local start=B747DR_fmscurrentIndex
    if fmsO[start]==nil then
        --print("empty data "..start)
        return
    end

    if B747DR_ap_approach_mode~=0 and simDR_autopilot_nav_status==0 and B747DR_ap_lnav_state>0 and diff>0.5 then
        if simDR_autopilot_heading_status == 0 then
            simCMD_autopilot_heading_select:once()
            B747DR_ap_ATT = 0.0
            B747DR_ap_lastCommand = simDRTime
        end
        local ap2Heading=getHeading(simDR_latitude,simDR_longitude,fmsO[start][5],fmsO[start][6])
        local hV=getWCAforHeading(ap2Heading+simDR_variation)
        --print("B747_updateApproachHeading hV="..hV.." wca="..wca.." wca_deg="..wca.." simDR_wind_speed_kts="..simDR_wind_speed_kts.." ap2Heading="..ap2Heading )
        simDR_autopilot_heading_deg =	 hV
    end
end

function B747_monitorAP(fmsO)
    --refresh
    local autothrottlemode=B747DR_autothrottle_active
    local flch_status=simDR_autopilot_flch_status
    local vs_status=simDR_autopilot_vs_status
    B747_monitorAT()
    VNAV_modeSwitch(fmsO)
    LNAV_modeSwitch()
    aileronTrim()

    B747_updateApproachHeading(fmsO)
end
