--[[
*****************************************************************************************
* Program Script Name	:	B747.70.autopilot.vnavspd
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

local vnavSPD_conditions={}
vnavSPD_conditions["onground"]=0
vnavSPD_conditions["below"]=-1
vnavSPD_conditions["above"]=-1
vnavSPD_conditions["leg"]=0
vnavSPD_conditions["name"]="unknown"
local vnavSPD_state={}
vnavSPD_state["targetSpd"]=180
vnavSPD_state["targetAlt"]=5000
vnavSPD_state["targetVS"]=0 --descend, hold climb
vnavSPD_state["targetAltHold"]=false
vnavSPD_state["spdIsMach"]=false
vnavSPD_state["manualVNAVspd"]=0
vnavSPD_state["vnavcalcwithMCPAlt"]=0
vnavSPD_state["vnavcalcwithTargetAlt"]=0
vnavSPD_state["gotVNAVSpeed"]=false
vnavSPD_state["recalcAfter"]=0
vnavSPD_state["setBaro"]=false
--[[
    clb_src_next()
    First state during climb, get the altitude for next update as 200ft agl
]]
function clb_src_next()
    return simDR_pressureAlt1+(100-simDR_radarAlt1) --400ft agl at current pressure alt
end

--[[
    clb_aptres_next()
    Lower airspeed restriction , get the altitude for next update 100ft above SPD REST ALT, L4 on FMC VNAV page 1
    updates every 500 feet
]]
function clb_aptres_next()
    --return tonumber(getFMSData("clbrestalt"))+100
    local tAlt=tonumber(getFMSData("clbrestalt"))+100
    if tAlt>simDR_pressureAlt1+500 then
        tAlt=math.min(simDR_pressureAlt1+500,tAlt)
    end
    return tAlt
end
--[[
    clb_spcres_next()
    Lower airspace airspeed restriction , get the altitude for next update 100ft above SPD TRANSE ALT, L3 on FMC VNAV page 1
    updates every 500 feet
]]
function clb_spcres_next()
    --return tonumber(getFMSData("spdtransalt"))+100
    local tAlt=tonumber(getFMSData("spdtransalt"))+100
    if tAlt>simDR_pressureAlt1+500 then
        tAlt=math.min(simDR_pressureAlt1+500,tAlt)
    end
    return tAlt
end
--[[
    clb_spcres_next()
    Unrestrictied airspeed climb speed , get the altitude for next update 100ft above SPD TRANSE ALT, L3 on FMC VNAV page 1
    updates every 500 feet
]]
function clb_nores_next()
    --return (tonumber(string.sub(getFMSData("crzalt"),3))*100)-1000
    local tAlt=(B747BR_cruiseAlt)-500
    if tAlt>simDR_pressureAlt1+500 then
        tAlt=math.min(simDR_pressureAlt1+500,tAlt,B747BR_cruiseAlt-math.max(B747DR_alt_capture_window,500))
    end
    return tAlt
end
function clb_crz_next()
    return B747BR_cruiseAlt+1000
end
function des_src_next()
    --return tonumber(getFMSData("desspdtransalt"))
    local tAlt=tonumber(getFMSData("desspdtransalt"))
    if tAlt<simDR_pressureAlt1-500 then
        tAlt=math.max(simDR_pressureAlt1-500,tAlt)
    end
    return tAlt
end
function des_aptres_next()
    local tAlt=tonumber(getFMSData("desrestalt"))
    if tAlt<simDR_pressureAlt1-500 then
        tAlt=math.max(simDR_pressureAlt1-500,tAlt)
    end
    return tAlt
end
function des_spcres_next()
    return -100
end
local spd_states={}
spd_states["clb"]={}
spd_states["des"]={}
spd_states["clb"]["src"]={}
spd_states["clb"]["aptres"]={}
spd_states["clb"]["spcres"]={}
spd_states["clb"]["nores"]={}
spd_states["clb"]["crz"]={}
spd_states["des"]["src"]={}
spd_states["des"]["aptres"]={}
spd_states["des"]["spcres"]={}

spd_states["clb"]["src"]["nextfunc"]=clb_src_next
spd_states["clb"]["aptres"]["nextfunc"]=clb_aptres_next
spd_states["clb"]["spcres"]["nextfunc"]=clb_spcres_next
spd_states["clb"]["nores"]["nextfunc"]=clb_nores_next
spd_states["clb"]["crz"]["nextfunc"]=clb_crz_next
spd_states["des"]["src"]["nextfunc"]=des_src_next
spd_states["des"]["aptres"]["nextfunc"]=des_aptres_next
spd_states["des"]["spcres"]["nextfunc"]=des_spcres_next

spd_states["clb"]["src"]["nextstate"]="aptres"
spd_states["clb"]["aptres"]["nextstate"]="spcres"
spd_states["clb"]["spcres"]["nextstate"]="nores"
spd_states["clb"]["nores"]["nextstate"]="crz"
spd_states["clb"]["crz"]["nextstate"]=nil
spd_states["des"]["src"]["nextstate"]="aptres"
spd_states["des"]["aptres"]["nextstate"]="spcres"
spd_states["des"]["spcres"]["nextstate"]=nil
function modFlapSpeed(speed)
    local minSafeSpeed = B747DR_airspeed_Vmc + 10
	local maxSafeSpeed = B747DR_airspeed_Vmo
	if simDR_flap_ratio_control > 0 then
		if simDR_flap_ratio_control <= 0.168 then --flaps 1
			maxSafeSpeed = math.min(275,B747DR_airspeed_Vf0+2)
		elseif simDR_flap_ratio_control <= 0.34 then --flaps 5
			maxSafeSpeed = math.min(255,B747DR_airspeed_Vf1+2)
		elseif simDR_flap_ratio_control <= 0.5 then --flaps 10
			maxSafeSpeed = math.min(235,B747DR_airspeed_Vf5+2)
			minSafeSpeed = minSafeSpeed - 5
		elseif simDR_flap_ratio_control <= 0.668 then --flaps 20
			maxSafeSpeed = math.min(225,B747DR_airspeed_Vf10+2)
			minSafeSpeed = minSafeSpeed - 5
		elseif simDR_flap_ratio_control <= 0.84 then --flaps 25
			maxSafeSpeed = math.min(200,B747DR_airspeed_Vf20+2)
			minSafeSpeed = minSafeSpeed - 9
		elseif simDR_flap_ratio_control <= 1.0 then --flaps 30
			maxSafeSpeed = math.min(175,B747DR_airspeed_Vf25+2)
			minSafeSpeed = minSafeSpeed - 9
		end
	end
    if speed<minSafeSpeed then return minSafeSpeed
    elseif speed>maxSafeSpeed then return maxSafeSpeed
    else return speed end
end
function clb_src_setSpd()
    if B747DR_airspeed_V2<900 then
        simDR_autopilot_airspeed_is_mach = 0
        B747DR_ap_ias_dial_value = math.min(399.0, B747DR_airspeed_V2)
        B747DR_switchingIASMode=1
        B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
        run_after_time(B747_updateIAS, 0.25)
    end
    vnavSPD_state["setBaro"]=false
end
function clb_aptres_setSpd()
    local spdval=modFlapSpeed(math.min(B747DR_ap_ias_dial_value+5,tonumber(getFMSData("clbrestspd"))))
    spdval=math.max(spdval,simDR_ind_airspeed_kts_pilot-15)
    simDR_autopilot_airspeed_is_mach = 0
    print("convert to clb clbrestspd ".. spdval)
    B747DR_ap_ias_dial_value = math.min(399.0, spdval)
    B747DR_switchingIASMode=1
    B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    run_after_time(B747_updateIAS, 0.25)

end
function clb_spcres_setSpd()
    local spdval=modFlapSpeed(tonumber(getFMSData("clbspd")))
    B747DR_switchingIASMode=1
    local crzspdval=tonumber(getFMSData("crzspd"))/10
    if simDR_airspeed_mach > (crzspdval/100) then
      print("convert to cruise speed in clb ".. crzspdval)
      simDR_autopilot_airspeed_is_mach = 1
      B747DR_ap_ias_dial_value = crzspdval
      B747DR_lastap_dial_airspeed=crzspdval*0.01
    else

      if B747DR_ap_ias_dial_value+5<simDR_ind_airspeed_kts_pilot then
        spdval=math.min(simDR_ind_airspeed_kts_pilot,spdval)
      elseif(B747DR_ap_ias_dial_value<spdval) and simDR_autopilot_airspeed_is_mach == 0 then
        spdval=math.min(B747DR_ap_ias_dial_value+5,spdval)
      end
      spdval=math.max(spdval,simDR_ind_airspeed_kts_pilot-15)
      simDR_autopilot_airspeed_is_mach = 0
      print("convert to clb speed ".. spdval.. " at "..simDR_ind_airspeed_kts_pilot)
      B747DR_ap_ias_dial_value = math.min(399.0, spdval)
      B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    end
    run_after_time(B747_updateIAS, 0.25)

end
function clb_nores_setSpd()
    local spdval=modFlapSpeed(tonumber(getFMSData("transpd")))
    B747DR_switchingIASMode=1
    local crzspdval=tonumber(getFMSData("crzspd"))/10
    if simDR_airspeed_mach > (crzspdval/100) then
      print("convert to cruise speed in clb".. crzspdval)
      simDR_autopilot_airspeed_is_mach = 1
      B747DR_ap_ias_dial_value = crzspdval
      B747DR_lastap_dial_airspeed=crzspdval*0.01
    else
      if simDR_autopilot_airspeed_is_mach == 0 then
      if(B747DR_ap_ias_dial_value<spdval) then
        spdval=math.min(B747DR_ap_ias_dial_value+10,spdval)
      elseif(B747DR_ap_ias_dial_value>spdval) then
            spdval=math.max(B747DR_ap_ias_dial_value-10,spdval)
      end
     else
        simDR_autopilot_airspeed_is_mach = 0
     end
      spdval=math.max(spdval,simDR_ind_airspeed_kts_pilot-15)
      print("convert to transpd speed ".. spdval)
      B747DR_ap_ias_dial_value = math.min(399.0, spdval)
      B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    end
    run_after_time(B747_updateIAS, 0.25)

end
function clb_crz_setSpd()
    local spdval=tonumber(getFMSData("crzspd"))/10

    local ci = tonumber( getFMSData("costindex") )
    local ci_mach = 850
    if(ci == nil or ci == "****") then
        if(spdval == nil) then
          spdval = 85
        end
    else
        -- mach numbers in thousands...
        local lrcMach = 388.2356 + 0.6203 * gwtKG/1000 + 7.8061 * simDR_pressureAlt1/1000
        local mrcMach = lrcMach -  20
        local maxMach = 920 - 20
        local ci_mach = lrcMach --default

        if(ci <= 230) then --LRC or less  (CI 230 corresponds to LRC - ref Boeing)
          ci_mach = mrcMach + 20 * (ci / 230)
        else
          ci_mach = lrcMach + (maxMach - lrcMach) * ((ci-230)/(9999-230)) -- interpolate LRC to Mmo wrt. CI=230 to CI=9999, respectively.
        end

        -- Faster with headwind, slower with tailwind (cf., LRC which does not adjust for wind)
        -- Source: https://mediawiki.ivao.aero/index.php?title=Cost_Index and https://www.pprune.org/tech-log/248931-use-cost-index-winds.html
        local tas = simDR_TAS_mps * 1.94384 -- true airspeed in knots
        local gs = simDR_GS_mps * 1.94384 -- ground speed in knots
        local relWind = tas - gs  -- headwind positive, tailwind negative
        local adjWind = 0
        if(relWind > 0) then
          adjWind = 10 * relWind/50 -- plus M0.01 per 50 knots of headwind
        else
          adjWind = 20 * relWind/50 -- minus M0.02 per 50 knots of tailwind
        end
        ci_mach = ci_mach + adjWind

        if(ci_mach < mrcMach) then ci_mach = mrcMach end
        if(ci_mach > maxMach) then ci_mach = maxMach end

        ci_mach = math.floor(ci_mach)
        spdval = ci_mach/10
    end
    local transalt=tonumber(getFMSData("transalt"))
    local tspdval=modFlapSpeed(tonumber(getFMSData("transpd")))
    if simDR_pressureAlt1>=transalt or simDR_ind_airspeed_kts_pilot>=tspdval-1 then
        print("convert to cruise speed in clb_crz_setSpd ".. spdval)
        simDR_autopilot_airspeed_is_mach = 1
        B747DR_ap_ias_dial_value = spdval
        B747DR_lastap_dial_airspeed=spdval*0.01
        run_after_time(B747_updateIAS, 0.25)
    end
end

function des_src_setSpd()
    local crzspdval=tonumber(getFMSData("desspdmach"))/10
    local spdval=tonumber(getFMSData("desspd"))
    local nextspdval=tonumber(getFMSData("destranspd"))
    if simDR_airspeed_mach > (crzspdval/100) then
      print("convert to mach descend speed in des".. crzspdval)
      simDR_autopilot_airspeed_is_mach = 1
      B747DR_ap_ias_dial_value = crzspdval
      B747DR_lastap_dial_airspeed=crzspdval*0.01
    else

      if simDR_autopilot_airspeed_is_mach==1 then
        spdval=simDR_ind_airspeed_kts_pilot
      elseif(B747DR_ap_ias_dial_value>spdval) then
        spdval=math.max(B747DR_ap_ias_dial_value-15,spdval)
      else
        local lowerAlt=tonumber(getFMSData("desspdtransalt"))+1000
        local upperAlt=lowerAlt+1500
        spdval=B747_rescale(lowerAlt,nextspdval,upperAlt,spdval,simDR_pressureAlt1)
      end
      simDR_autopilot_airspeed_is_mach = 0
      print("des_src_setSpd:convert to descend speed ".. spdval)
      B747DR_ap_ias_dial_value = math.min(399.0, spdval)
      B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value

    end
    run_after_time(B747_updateIAS, 0.25)
end
function des_aptres_setSpd()
    local spdval=tonumber(getFMSData("destranspd"))
    local lowerAlt=tonumber(getFMSData("desrestalt"))


    local nextspdval=tonumber(getFMSData("desrestspd"))
    spdval=B747_rescale(lowerAlt+1000,nextspdval,lowerAlt+1500,spdval,simDR_pressureAlt1)
    simDR_autopilot_airspeed_is_mach = 0
    print("convert to destranspd speed ".. spdval)
    B747DR_ap_ias_dial_value = math.min(399.0, spdval)
    B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    run_after_time(B747_updateIAS, 0.25)
    if B747DR_autothrottle_active == 0 and simDR_ind_airspeed_kts_pilot < spdval+5 then							-- AUTOTHROTTLE IS "OFF"
       if isATEnabled() then
        B747DR_autothrottle_active=1
       end
        B747DR_ap_lastCommand = simDRTime
        if B747DR_engine_TOGA_mode ==1 then B747DR_engine_TOGA_mode = 0 end	-- CANX ENGINE TOGA IF ACTIVE
    end
end
function des_spcres_setSpd()
    local spdval=tonumber(getFMSData("desrestspd"))
    simDR_autopilot_airspeed_is_mach = 0
    print("convert to desrestspd speed ".. spdval)
    B747DR_ap_ias_dial_value = math.min(399.0, spdval)
    B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    run_after_time(B747_updateIAS, 0.25)
    if B747DR_autothrottle_active == 0 and simDR_ind_airspeed_kts_pilot < spdval+5 then							-- AUTOTHROTTLE IS "OFF"
        if isATEnabled() then
            B747DR_autothrottle_active=1
        end
        B747DR_ap_lastCommand = simDRTime
        if B747DR_engine_TOGA_mode ==1 then B747DR_engine_TOGA_mode = 0 end	-- CANX ENGINE TOGA IF ACTIVE
    end
end
spd_states["clb"]["src"]["spdfunc"]=clb_src_setSpd
spd_states["clb"]["aptres"]["spdfunc"]=clb_aptres_setSpd
spd_states["clb"]["spcres"]["spdfunc"]=clb_spcres_setSpd
spd_states["clb"]["nores"]["spdfunc"]=clb_nores_setSpd
spd_states["clb"]["crz"]["spdfunc"]=clb_crz_setSpd
spd_states["des"]["src"]["spdfunc"]=des_src_setSpd
spd_states["des"]["aptres"]["spdfunc"]=des_aptres_setSpd
spd_states["des"]["spcres"]["spdfunc"]=des_spcres_setSpd

function setVNAVState(name,value)
    vnavSPD_state[name]=value
end
function getVNAVState(name)
    return vnavSPD_state[name]
end
local lastVNAVSpeed=0
function B747_update_vnav_speed()
    if simDR_onGround~=vnavSPD_conditions["onground"] then vnavSPD_state["gotVNAVSpeed"]=false end
    if vnavSPD_conditions["above"]>0 and vnavSPD_conditions["above"]<simDR_pressureAlt1 then
      print("above "..vnavSPD_conditions["above"].. " " ..vnavSPD_conditions["name"])
      vnavSPD_state["gotVNAVSpeed"]=false
      lastVNAVSpeed=simDRTime
    end
    if vnavSPD_conditions["descent"]==(B747DR_ap_inVNAVdescent>0) then
       print("descent "..B747DR_ap_inVNAVdescent.. " " ..vnavSPD_conditions["name"])
       vnavSPD_state["gotVNAVSpeed"]=false
       lastVNAVSpeed=simDRTime
    end
    if vnavSPD_conditions["below"]>0 and vnavSPD_conditions["below"]>simDR_pressureAlt1 then
       print("below "..vnavSPD_conditions["below"].. " " ..vnavSPD_conditions["name"])
       vnavSPD_state["gotVNAVSpeed"]=false
       lastVNAVSpeed=simDRTime
    end
    if vnavSPD_conditions["crzAlt"]~=B747BR_cruiseAlt then
       print("new crzAlt")
       vnavSPD_state["gotVNAVSpeed"]=false
       lastVNAVSpeed=simDRTime
    end
    if vnavSPD_conditions["crzSpd"]~=getFMSData("crzspd") then
       print("new crzSpd")
       vnavSPD_state["gotVNAVSpeed"]=false
       lastVNAVSpeed=simDRTime
    end
    if vnavSPD_conditions["leg"]~=B747DR_fmscurrentIndex then
       print("new crzSpd leg")
       vnavSPD_state["gotVNAVSpeed"]=false
       lastVNAVSpeed=simDRTime
    end

    local diff=simDRTime-lastVNAVSpeed
    if diff>30 then
       vnavSPD_state["gotVNAVSpeed"]=false
       lastVNAVSpeed=simDRTime
    end
    --probably not needed?
    --[[if vnavSPD_conditions["mcpAlt"]~=B747DR_autopilot_altitude_ft then
        print("new mcpAlt")
        vnavSPD_conditions["mcpAlt"]=B747DR_autopilot_altitude_ft
        vnavSPD_state["gotVNAVSpeed"]=false
     end]]
end
function B747_vnav_setClimbspeed()
    local lastAlt=simDR_pressureAlt1+(simDR_radarAlt1-400)
    local cState="src"
    local nextAlt=spd_states["clb"]["src"]["nextfunc"]()
    while simDR_pressureAlt1>nextAlt and spd_states["clb"][cState]["nextstate"]~=nil do
        lastAlt=nextAlt
        if simDR_pressureAlt1>nextAlt then
            cState=spd_states["clb"][cState]["nextstate"]
        end
        nextAlt=spd_states["clb"][cState]["nextfunc"]()
        print("B747_vnav_setClimbspeed "..lastAlt .. " cState ".. cState.. " nextAlt ".. nextAlt)
    end
    local transalt=tonumber(getFMSData("transalt"))
    if vnavSPD_state["setBaro"]==false and nextAlt>transalt and simDR_pressureAlt1<=transalt then
        nextAlt=transalt
       -- print("prepped baro")
    end

    if vnavSPD_state["setBaro"]==false and simDR_pressureAlt1>=transalt then
        vnavSPD_state["setBaro"]=true
        B747DR_efis_baro_std_capt_switch_pos = 1
        --print("set baro")
        simDR_altimeter_baro_inHg = 29.92
        B747DR_efis_baro_std_fo_switch_pos = 1
        simDR_altimeter_baro_inHg_fo = 29.92

    end
    vnavSPD_conditions["name"]="clb_"..cState
    vnavSPD_conditions["onground"]=simDR_onGround
    vnavSPD_conditions["below"]=lastAlt
    vnavSPD_conditions["above"]=nextAlt
    vnavSPD_conditions["descent"]=true
    vnavSPD_conditions["crzAlt"]=B747BR_cruiseAlt
    vnavSPD_conditions["crzSpd"]=getFMSData("crzspd")
    vnavSPD_conditions["leg"]=B747DR_fmscurrentIndex
    vnavSPD_state["spdIsMach"]=simDR_autopilot_airspeed_is_mach
    vnavSPD_state["gotVNAVSpeed"]=true
    print("climb cState " .. cState .. " lastAlt "..lastAlt .. " nextAlt "..nextAlt)
    spd_states["clb"][cState]["spdfunc"]()
end

function B747_vnav_setDescendspeed()
    local lastAlt=simDR_pressureAlt1+1000
    local cState="src"
    local nextAlt=spd_states["des"]["src"]["nextfunc"]()
    while simDR_pressureAlt1<nextAlt and spd_states["des"][cState]["nextstate"]~=nil do
        lastAlt=nextAlt
        if simDR_pressureAlt1<nextAlt then
            cState=spd_states["des"][cState]["nextstate"]
        end
        nextAlt=spd_states["des"][cState]["nextfunc"]()
    end

    vnavSPD_conditions["name"]="des_"..cState
    vnavSPD_conditions["onground"]=simDR_onGround
    vnavSPD_conditions["below"]=nextAlt
    vnavSPD_conditions["above"]=lastAlt
    vnavSPD_conditions["descent"]=false
    vnavSPD_conditions["crzAlt"]=B747BR_cruiseAlt
    vnavSPD_conditions["crzSpd"]=getFMSData("crzspd")
    vnavSPD_conditions["leg"]=B747DR_fmscurrentIndex
    vnavSPD_state["spdIsMach"]=simDR_autopilot_airspeed_is_mach
    vnavSPD_state["gotVNAVSpeed"]=true
    print("des cState " .. cState .. " lastAlt "..lastAlt .. " nextAlt "..nextAlt)
    spd_states["des"][cState]["spdfunc"]()
end
function B747_vnav_speed()
    
    if B747DR_ap_vnav_state==0 then return end
    if getFMSData("crzalt")==nil then
        print("B747_vnav_speed nil "..B747BR_cruiseAlt)
        B747DR_ap_vnav_state=0 
    end
    local radarAltRefresh=simDR_radarAlt1
    local pressureAltRefresh=simDR_pressureAlt1
    if getVNAVState("manualVNAVspd")==1 then return end
    B747_update_vnav_speed()
    if vnavSPD_state["gotVNAVSpeed"]==true then return end
    if B747DR_ap_inVNAVdescent ==0 then
        B747_vnav_setClimbspeed()

    else
        B747_vnav_setDescendspeed()

    end

end
