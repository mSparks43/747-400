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
    if tAlt>vnavSPD_conditions["above"]+500 then
        tAlt=math.min(vnavSPD_conditions["above"]+500,tAlt)
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
    if tAlt>vnavSPD_conditions["above"]+500 then
        tAlt=math.min(vnavSPD_conditions["above"]+500,tAlt)
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
    local tAlt=(tonumber(string.sub(getFMSData("crzalt"),3))*100)-1000
    if tAlt>vnavSPD_conditions["above"]+500 then
        tAlt=math.min(vnavSPD_conditions["above"]+500,tAlt)
    end
    return tAlt
end
function clb_crz_next()
    return 320000
end
function des_src_next()
    --return tonumber(getFMSData("desspdtransalt"))
    local tAlt=tonumber(getFMSData("desspdtransalt"))
    if tAlt<vnavSPD_conditions["below"]-500 then
        tAlt=math.max(vnavSPD_conditions["below"]-500,tAlt)
    end
    return tAlt
end
function des_aptres_next()
    return tonumber(getFMSData("desrestalt"))
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

function clb_src_setSpd()
    if B747DR_airspeed_V2<900 then
        simDR_autopilot_airspeed_is_mach = 0  
        B747DR_ap_ias_dial_value = math.min(399.0, B747DR_airspeed_V2 + 10)
        B747DR_switchingIASMode=1
        B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
        run_after_time(B747_updateIAS, 0.25)
    end
    vnavSPD_state["setBaro"]=false
end
function clb_aptres_setSpd()
    local spdval=tonumber(getFMSData("clbrestspd"))
    simDR_autopilot_airspeed_is_mach = 0
    print("convert to clb clbrestspd ".. spdval)
    B747DR_ap_ias_dial_value = math.min(399.0, spdval)
    B747DR_switchingIASMode=1
    B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    run_after_time(B747_updateIAS, 0.25)

end
function clb_spcres_setSpd()
    local spdval=tonumber(getFMSData("clbspd"))
    B747DR_switchingIASMode=1
    local crzspdval=tonumber(getFMSData("crzspd"))/10
    if simDR_airspeed_mach > (crzspdval/100) then
      print("convert to cruise speed in clb ".. crzspdval)
      simDR_autopilot_airspeed_is_mach = 1
      B747DR_ap_ias_dial_value = crzspdval
      B747DR_lastap_dial_airspeed=crzspdval*0.01
    else
      simDR_autopilot_airspeed_is_mach = 0
      if(B747DR_ap_ias_dial_value<spdval) then
        spdval=math.min(B747DR_ap_ias_dial_value+5,spdval)
      end
      print("convert to clb speed ".. spdval)
      B747DR_ap_ias_dial_value = math.min(399.0, spdval)
      B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    end
    run_after_time(B747_updateIAS, 0.25)

end
function clb_nores_setSpd()
    local spdval=tonumber(getFMSData("transpd"))
    B747DR_switchingIASMode=1
    local crzspdval=tonumber(getFMSData("crzspd"))/10
    if simDR_airspeed_mach > (crzspdval/100) then
      print("convert to cruise speed in clb".. crzspdval)
      simDR_autopilot_airspeed_is_mach = 1
      B747DR_ap_ias_dial_value = crzspdval
      B747DR_lastap_dial_airspeed=crzspdval*0.01
    else
      simDR_autopilot_airspeed_is_mach = 0
      if(B747DR_ap_ias_dial_value<spdval) then
        spdval=math.min(B747DR_ap_ias_dial_value+10,spdval)
      end
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
    print("convert to cruise speed in clb_crz_setSpd ".. spdval)
    simDR_autopilot_airspeed_is_mach = 1
    B747DR_ap_ias_dial_value = spdval
    B747DR_lastap_dial_airspeed=spdval*0.01
    run_after_time(B747_updateIAS, 0.25)
end
function des_src_setSpd()
    local crzspdval=tonumber(getFMSData("desspdmach"))/10
    local spdval=tonumber(getFMSData("desspd"))
    if simDR_airspeed_mach > (crzspdval/100) then
      print("convert to mach descend speed in des".. crzspdval)
      simDR_autopilot_airspeed_is_mach = 1
      B747DR_ap_ias_dial_value = crzspdval
      B747DR_lastap_dial_airspeed=crzspdval*0.01
    else
        
      if simDR_autopilot_airspeed_is_mach==1 then
        spdval=simDR_ind_airspeed_kts_pilot
      elseif(B747DR_ap_ias_dial_value>spdval) then
        spdval=math.max(B747DR_ap_ias_dial_value-5,spdval)
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
    simDR_autopilot_airspeed_is_mach = 0
    print("convert to destranspd speed ".. spdval)
    B747DR_ap_ias_dial_value = math.min(399.0, spdval)
    B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    run_after_time(B747_updateIAS, 0.25)
    if simDR_autopilot_autothrottle_enabled == 0 then							-- AUTOTHROTTLE IS "OFF"
        simCMD_autopilot_autothrottle_on:once()	
    end
end
function des_spcres_setSpd()
    local spdval=tonumber(getFMSData("desrestspd"))
    simDR_autopilot_airspeed_is_mach = 0
    print("convert to descend speed ".. spdval)
    B747DR_ap_ias_dial_value = math.min(399.0, spdval)
    B747DR_lastap_dial_airspeed=B747DR_ap_ias_dial_value
    run_after_time(B747_updateIAS, 0.25)
    if simDR_autopilot_autothrottle_enabled == 0 then							-- AUTOTHROTTLE IS "OFF"
        simCMD_autopilot_autothrottle_on:once()	
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
function B747_update_vnav_speed()
    if simDR_onGround~=vnavSPD_conditions["onground"] then vnavSPD_state["gotVNAVSpeed"]=false end
    if vnavSPD_conditions["above"]>0 and vnavSPD_conditions["above"]<simDR_pressureAlt1 then 
      print("above "..vnavSPD_conditions["above"].. " " ..vnavSPD_conditions["name"])
      vnavSPD_state["gotVNAVSpeed"]=false 
    end
    if vnavSPD_conditions["descent"]==(B747DR_ap_inVNAVdescent>0) then 
       print("descent "..B747DR_ap_inVNAVdescent.. " " ..vnavSPD_conditions["name"])
       vnavSPD_state["gotVNAVSpeed"]=false 
    end
    if vnavSPD_conditions["below"]>0 and vnavSPD_conditions["below"]>simDR_pressureAlt1 then 
       print("below "..vnavSPD_conditions["below"].. " " ..vnavSPD_conditions["name"])
       vnavSPD_state["gotVNAVSpeed"]=false 
    end
    if vnavSPD_conditions["crzAlt"]~=B747BR_cruiseAlt then 
       print("new crzAlt")
       vnavSPD_state["gotVNAVSpeed"]=false 
    end
    if vnavSPD_conditions["crzSpd"]~=getFMSData("crzspd") then 
       print("new crzSpd")
       vnavSPD_state["gotVNAVSpeed"]=false 
    end
    if vnavSPD_conditions["leg"]~=B747DR_fmscurrentIndex then
       print("new crzSpd leg")
       vnavSPD_state["gotVNAVSpeed"]=false 
    end
end
function B747_vnav_setClimbspeed()
    local lastAlt=simDR_pressureAlt1+(simDR_radarAlt1-400)
    local cState="src"
    local nextAlt=spd_states["clb"]["src"]["nextfunc"]()
    while simDR_pressureAlt1>nextAlt and spd_states["clb"][cState]["nextstate"]~=nil do
        lastAlt=nextAlt
        cState=spd_states["clb"][cState]["nextstate"]
        nextAlt=spd_states["clb"][cState]["nextfunc"]()
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
        cState=spd_states["des"][cState]["nextstate"]
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
