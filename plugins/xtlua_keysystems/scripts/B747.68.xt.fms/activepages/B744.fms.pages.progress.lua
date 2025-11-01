fmsPages["PROGRESS"]=createPage("PROGRESS")
--[[
fmsPages["PROGRESS"].getPage=function(self,pgNo,fmsID)
  local l1=cleanFMSLine(B747DR_srcfms[fmsID][1])
  local page=string.sub(l1,22,22)
  local l10="                        "
  local l11="                        " 
  local l13="                        "
  if page=="1" then
        l13="                POS REF>"
	fmsFunctionsDefs["PROGRESS"]["R6"]={"setpage_no","POSINIT_2"}
	if B747BR_tod>0 and B747BR_totalDistance>B747BR_tod then
	  local dist=B747BR_totalDistance-B747BR_tod
	  l10=" TOP OF DES             "
	  l11="T/D      ".. string.format("%5d",dist) ..""
	end
  else
     
      fmsFunctionsDefs["PROGRESS"]["R6"]=nil
  end
  
  local page={
  l1,
  cleanFMSLine(B747DR_srcfms[fmsID][2]),
  cleanFMSLine(B747DR_srcfms[fmsID][3]),
  cleanFMSLine(B747DR_srcfms[fmsID][4]),
  cleanFMSLine(B747DR_srcfms[fmsID][5]),
  cleanFMSLine(B747DR_srcfms[fmsID][6]),
  cleanFMSLine(B747DR_srcfms[fmsID][7]),
  cleanFMSLine(B747DR_srcfms[fmsID][8]),
  cleanFMSLine(B747DR_srcfms[fmsID][9]),
  l10,
  l11,
  cleanFMSLine(B747DR_srcfms[fmsID][12]),
  l13,
  }
  return page 
  
end
]]--
local lastPageNum={}
local lastPage={}
function refreshPages()
  lastPageNum={}
end
fmsPages["PROGRESS"].getPage=function(self,pgNo,fmsID)
  --print(avocatd:test())
  if simDR_onGround == 1 then
    B747DR_last_waypoint_fuel=simDR_fueL_tank_weight_total_kg
  end
  if lastPageNum[fmsID]~=nil and lastPageNum[fmsID]==pgNo then
    if is_timer_scheduled(refreshPages)==false then
      run_after_time(refreshPages,1.0)
    end
    return lastPage[fmsID]
  end
  local mult=1.0
    if simConfigData["data"].SIM.weight_display_units == "LBS" then
      mult=simConfigData["data"].SIM.kgs_to_lbs
    end
  if pgNo==1 then 
    fmsFunctionsDefs["PROGRESS"]["L6"]={"setpage","POSREPORT"}
    fmsFunctionsDefs["PROGRESS"]["R6"]={"setpage","POSINIT_2"}
    local ffkgs = (simDR_eng_fuel_flow_kg_sec[0] + simDR_eng_fuel_flow_kg_sec[1] + simDR_eng_fuel_flow_kg_sec[2] + simDR_eng_fuel_flow_kg_sec[3])
    if simDR_onGround == 1 then
      B747DR_last_waypoint_fuel=simDR_fueL_tank_weight_total_kg
      ffkgs=3.1
    end
    local toFuel="---.-"
    local nextFuel="---.-"
    local dtgTO=" ---"
    local dtgNext=" ---"
    local meters_per_second_to_kts = 1.94384449
    local default_speed = 275 * meters_per_second_to_kts
    local actual_speed = simDR_groundspeed * meters_per_second_to_kts
    local distToNext=tonumber(string.sub(B747DR_ND_waypoint_distance,1,5))
    --print("B747DR_ND_waypoint_distance "..string.sub(B747DR_ND_waypoint_distance,1,5))
    local time_to_waypoint=0
    if B747DR_ND_current_waypoint~="-----" and distToNext~=nil then
      dtgTO=string.format("%4d",distToNext)
      
      time_to_waypoint = (distToNext / math.max(default_speed, actual_speed)) * 3600
      f_used_toNext=time_to_waypoint*ffkgs
      toFuel=string.format("%5.1f",((simDR_fueL_tank_weight_total_kg-f_used_toNext)*mult/1000))
      --print("time_to_waypoint "..time_to_waypoint)
    end
    --local distToNext2=tonumber(string.sub(B747DR_ND_waypoint_distance,1,5))
    if B747DR_next_waypoint~="-----" and B747DR_next_waypoint_dist>0 and B747DR_ND_current_waypoint~="-----" and distToNext~=nil then
      --print("B747DR_next_waypoint_dist "..B747DR_next_waypoint_dist)
      time_to_waypoint = time_to_waypoint+((B747DR_next_waypoint_dist / math.max(default_speed, actual_speed)) * 3600)
      dtgNext=string.format("%4d",distToNext+B747DR_next_waypoint_dist)
      f_used_toNext=time_to_waypoint*ffkgs
      nextFuel=string.format("%5.1f",((simDR_fueL_tank_weight_total_kg-f_used_toNext)*mult/1000))
      --print("time_next_waypoint "..time_to_waypoint)
    end
    local todText="----z/----NM"
    if B747BR_tod>0 and B747BR_totalDistance>B747BR_tod then
      local dist=B747BR_totalDistance-B747BR_tod
      if B747BR_toc>=0 and dist > B747BR_toc and B747DR_ap_flightPhase<2 then
        dist=B747BR_toc
      end
      local hours = 0
      local mins = 0
      local secs = 0
      local time_to_TOD =0
      time_to_TOD,hours,mins,secs = get_ETA_for_Distance(dist,0)
      todText=string.format("%12s",string.format("%02d%02dz/%dNM", hours, mins,dist))
    end
    local destText=" --- ----   --.-"
    if B747BR_totalDistance>0 then
      local dist=B747BR_totalDistance
      local hours = 0
      local mins = 0
      local secs = 0
      local time_to_DEST =0
      time_to_DEST,hours,mins,secs = get_ETA_for_Distance(dist,0)
      local f_used_toDest=time_to_DEST*ffkgs
      destText=string.format("%16s",string.format("%4d %02d%02d  %5.1f",dist, hours, mins,((simDR_fueL_tank_weight_total_kg-f_used_toDest)*mult/1000)))
    end
    local selSpd=string.format("%3dkt ",simDR_autopilot_airspeed_kts)
    if simDR_autopilot_airspeed_is_mach==1 then
      selSpd=string.format("%-5.3f ",simDR_autopilot_airspeed_kts_mach)
    end
    lastPage[fmsID]= {
    "        PROGRESS        ",
    "                        ",
    "                        ",
    "                        ",
    string.format("%-5s",B747DR_ND_current_waypoint).."   "..dtgTO.." ".. string.sub(B747DR_ND_waypoint_eta,1,4).."  "..toFuel ,
    "                        ",
    string.format("%-5s", B747DR_next_waypoint).."   "..dtgNext.." ".. string.sub(B747DR_next_waypoint_eta,1,4).."  "..nextFuel,
    "                        ",
    B747DR_destination.."    "..destText,
    "                        ",
    selSpd.."      "..todText, 
    "------------------------",
    "<POS REPORT     POS REF>"
    }
    lastPageNum[fmsID]=1
    return lastPage[fmsID]

  elseif pgNo==2 then
    fmsFunctionsDefs["PROGRESS"]["L6"]=nil
    fmsFunctionsDefs["PROGRESS"]["R6"]=nil
    
    local fuel1=string.format("%4.1f",(B747DR_engine_used_fuel[0]*mult/1000))
    local fuel2=string.format("%4.1f",(B747DR_engine_used_fuel[1]*mult/1000))
    local fuel3=string.format("%4.1f",(B747DR_engine_used_fuel[2]*mult/1000))
    local fuel4=string.format("%4.1f",(B747DR_engine_used_fuel[3]*mult/1000))
    local fuel_remaining=string.format("%5.1f",(simDR_fueL_tank_weight_total_kg*mult/1000))
    local windSide="L"
    local latWind="  0"
    local longWind="  0"
    if B747DR_ND_Wind_Bearing<-90 then 
      windSide="R"
      local angle=math.rad(180-(B747DR_ND_Wind_Bearing*-1))
      latWind=string.format("%3d",math.sin(angle)*simDR_wind_speed)
      longWind=string.format("%3d",math.cos(angle)*simDR_wind_speed)
    elseif B747DR_ND_Wind_Bearing<0 then 
      windSide="R"
      local angle=math.rad(B747DR_ND_Wind_Bearing*-1)
      latWind=string.format("%3d",math.sin(angle)*simDR_wind_speed)
      longWind=string.format("%3d",math.cos(angle)*simDR_wind_speed)
    elseif B747DR_ND_Wind_Bearing>90 then
      windSide="L"
      local angle=math.rad(180-B747DR_ND_Wind_Bearing)
      latWind=string.format("%3d",math.sin(angle)*simDR_wind_speed)
      longWind=string.format("%3d",math.cos(angle)*simDR_wind_speed)
    else --0 to 90
      windSide="L"
      local angle=math.rad(B747DR_ND_Wind_Bearing)
      latWind=string.format("%3d",math.sin(angle)*simDR_wind_speed)
      longWind=string.format("%3d",math.cos(angle)*simDR_wind_speed)
    end
    xtk_error=string.format("%2.1f",B747DR_ap_lnav_xtk_error)
    lastPage[fmsID]= {
    "        PROGRESS        ",
    "                        ",
    longWind.."KT "..string.format("%10s",B747DR_ND_Wind_Line.."KT").."  "..windSide..latWind .."KT",
    "                        ",
    "L "..xtk_error.."              +**FT",
    "                        ",
    string.format("%03.0f",B747DR_TAS_pilot).."                ".. string.format("%3d",simDR_air_temp) .."`C",
    "                        ",
    " ".. fuel1 .."  ".. fuel2 .."   ".. fuel3 .."  ".. fuel4 .."",
    "                        ",
	"<USE                USE>",
    "                        ", 
    fuel_remaining.."               "..fuel_remaining
    }
    lastPageNum[fmsID]=2
    return lastPage[fmsID]
  elseif pgNo==3 then
    fmsFunctionsDefs["PROGRESS"]["L6"]=nil
    fmsFunctionsDefs["PROGRESS"]["R6"]=nil
    lastPage[fmsID]= {
    "  ACT RTA PROGRESS      ",
    "                        ",
    "-----           ----.-z ",
    "                        ",
    ".***      FL***/****.*z ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
	  ".890                    ",
    "------------------------", 
    "                        "
    }
    lastPageNum[fmsID]=3
    return lastPage[fmsID]
  end
end

fmsPages["PROGRESS"].getSmallPage=function(self,pgNo,fmsID)
  local mult=1.0
    if simConfigData["data"].SIM.weight_display_units == "LBS" then
      mult=simConfigData["data"].SIM.kgs_to_lbs
    end 
  if pgNo==1 then 
    local fuel_ata=string.format("%5.1f",(B747DR_last_waypoint_fuel*mult/1000))
    local toText="T/D"
    local dist=B747BR_totalDistance-B747BR_tod
      if B747BR_toc>=0 and dist > B747BR_toc and B747DR_ap_flightPhase<2 then
        toText="T/C"
      end
    return {
"                    1/3 ",
" LAST   ALT   ATA   FUEL",
string.format("%-5s", B747DR_last_waypoint).."        "..string.sub(B747DR_waypoint_ata,1,4).."z "..fuel_ata ,
" TO      DTG  ETA       ",
"                 Z      ",
" NEXT                   ",
"                 Z      ",
" DEST                   ",
"                 Z      ",
" SEL SPD          TO "..toText,
"                        ", 
"                        ",
"                        "
}
elseif pgNo==2 then
  
  local fuel_used=string.format("%5.1f",(B747DR_engine_used_fuel[4]*mult/1000))
  local tWind=" H/WIND"
  if B747DR_ND_Wind_Bearing>-90 and B747DR_ND_Wind_Bearing<90 then tWind=" T/WIND" end
  return {
    "                    2/3 ",
    tWind.."   WIND    X/WIND",
    "                        ",
    " XTK ERROR     VTK ERROR",
    "      NM                ",
    " TAS    FUEL USED    SAT",
    "   KT   TOT ".. fuel_used .."      C",
    "   1     2      3     4 ",
    "                        ",
    "                        ",   
    "        FUEL QTY        ",
    " TOTALIZER    CALCULATED", 
    "                        "
    } 
	elseif pgNo==3 then return {
    "                    3/3 ",
    " FIX                 RTA",
    "                        ",
    " RTA SPD         ALT/ETA",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    " MAX SPD                ",
    "                        ",
	  "                        ",
    "                        ", 
    "                        "
    }
end
end
fmsPages["PROGRESS"].getNumPages=function(self)

  return 3
end

fmsFunctionsDefs["PROGRESS"]={}
fmsFunctionsDefs["PROGRESS"]["next"]={"custom2fmc","next"}
fmsFunctionsDefs["PROGRESS"]["prev"]={"custom2fmc","prev"}
fmsFunctionsDefs["PROGRESS"]["exec"]={"custom2fmc","exec"}
--[[
fmsFunctionsDefs["PROGRESS"]["L1"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["L2"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["L3"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["L4"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["L5"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["L6"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["R1"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["R2"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["R3"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["R4"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["R5"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["R6"]={"setpage",""}
]]