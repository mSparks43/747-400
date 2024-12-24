--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
--Marauder28
--V Speeds
B747DR_airspeed_V1			= deferred_dataref("laminar/B747/airspeed/V1", "number")
B747DR_airspeed_Vr			= deferred_dataref("laminar/B747/airspeed/Vr", "number")
B747DR_airspeed_V2			= deferred_dataref("laminar/B747/airspeed/V2", "number")
B747DR_airspeed_flapsRef	= deferred_dataref("laminar/B747/airspeed/flapsRef", "number")

--Refuel DR
B747DR_refuel							= deferred_dataref("laminar/B747/fuel/refuel", "number")
--Marauder28

--silvereagle added to end
-- Misc.
B747DR_fmc_spill_lights		= deferred_dataref("laminar/B747/fmc/spill_lights", "number")
B747DR_fmc_cockpit_seats_hide	= deferred_dataref("laminar/B747/fmc/cockpit_seats_hide", "number")
--silvereagle end

acarsOnlineDataref=find_dataref("autoatc/acars/online")
B747DR_acarsProvider						= deferred_dataref("laminar/B747/acars/systemProvider", "number")
B747DR_acars=find_dataref("laminar/B747/comm/acars")
fmsFunctions={}
dofile("acars/acars.lua")

fmsPages["INDEX"]=createPage("INDEX")
fmsPages["INDEX"].getPage=function(self,pgNo,fmsID)
  local acarsS="             "
  local gs1="                        "

  if simDR_onGround ==1 then
    gs1="                 SELECT>"

  end
  if acars==1 and B747DR_rtp_C_off==0 then 
	acarsS="<ACARS  <REQ>" 
	fmsFunctionsDefs["INDEX"]["L2"]={"setpage","ACARS"}
  else
	fmsFunctionsDefs["INDEX"]["L2"]=nil
	end
return {

"          MENU          ",
"                        ",
"<FMC    <ACT>    SELECT>",
"                        ",
acarsS.."    SELECT>",
"                        ",
"<SAT                    ",
"                        ",
gs1,
"                        ",
"<ACMS                   ", 
"                        ",
"<CMC             SELECT>"
}
end
fmsPages["INDEX"].getSmallPage=function(self,pgNo,fmsID)

  local gs2="                        "
  if simDR_onGround ==1 then

    gs2="         GROUND HANDLING"
  end
  return {
      "                        ",
      "                 EFIS CP",
      "                        ",
      "                EICAS CP",
      "                        ",
      "                 CTL PNL",
      "                        ",
      gs2,
      "                        ",
      "                        ",
      "                        ",
      "         AIRCRAFT CONFIG",
      "                        ",
      }
end
fmsFunctionsDefs["INDEX"]={}
fmsFunctionsDefs["INDEX"]["L1"]={"setpage","IDENT"}

fmsFunctionsDefs["INDEX"]["L5"]={"setpage","ACMS"}
fmsFunctionsDefs["INDEX"]["L6"]={"setpage","CMC"}
fmsFunctionsDefs["INDEX"]["R1"]={"setpage","EFISCTL152"}
fmsFunctionsDefs["INDEX"]["R2"]={"setpage","EICASMODES"}
fmsFunctionsDefs["INDEX"]["R4"]={"setpage","GNDHNDL"}
fmsFunctionsDefs["INDEX"]["R6"]={"setpage","MAINTSIMCONFIG"}
--fmsFunctionsDefs["INDEX"]["R6"]={"setpage", "MAINTSIMCONFIG"}

fmsPages["RTE1"]=createPage("RTE1")
fmsPages["RTE1"].getPage=function(self,pgNo,fmsID)
  local l1=cleanFMSLine(B747DR_srcfms[fmsID][1])
  local pageNo=tonumber(string.sub(l1,21,22))

  local lastLine="<RTE 2             PERF>"
  if simDR_onGround ==1 then
    fmsFunctionsDefs["RTE1"]["L6"]=nil
    lastLine="                   PERF>"
  else
    --fmsFunctionsDefs["RTE1"]["L6"]={"setpage","RTE2"}
    fmsFunctionsDefs["RTE1"]["L6"]={"setpage","LEGS"}
  end

  if pageNo~=1 then
	fmsFunctionsDefs["RTE1"]["L1"]={"custom2fmc","L1"}
	fmsFunctionsDefs["RTE1"]["L2"]={"custom2fmc","L2"}
	fmsFunctionsDefs["RTE1"]["R1"]={"custom2fmc","R1"}
	fmsFunctionsDefs["RTE1"]["R2"]={"custom2fmc","R2"}
	fmsFunctionsDefs["RTE1"]["R3"]={"custom2fmc","R3"}
	return {
		"      ACT RTE 1     " .. string.sub(cleanFMSLine(B747DR_srcfms[fmsID][1]),-4,-1) ,
		cleanFMSLine(B747DR_srcfms[fmsID][2]),
		cleanFMSLine(B747DR_srcfms[fmsID][3]),
		cleanFMSLine(B747DR_srcfms[fmsID][4]),
		cleanFMSLine(B747DR_srcfms[fmsID][5]),
		cleanFMSLine(B747DR_srcfms[fmsID][6]),
		cleanFMSLine(B747DR_srcfms[fmsID][7]),
		cleanFMSLine(B747DR_srcfms[fmsID][8]),
		cleanFMSLine(B747DR_srcfms[fmsID][9]),
		cleanFMSLine(B747DR_srcfms[fmsID][10]),
		cleanFMSLine(B747DR_srcfms[fmsID][11]),
		cleanFMSLine(B747DR_srcfms[fmsID][12]),
		lastLine,
		}
  end
  fmsFunctionsDefs["RTE1"]["L1"]={"setdata","fltdep"}
  fmsFunctionsDefs["RTE1"]["L2"]={"setdata","runway"}
  fmsFunctionsDefs["RTE1"]["R1"]={"setdata","fltdst"}
  fmsFunctionsDefs["RTE1"]["R2"]={"custom2fmc","R3"}
  fmsFunctionsDefs["RTE1"]["L4"]={"custom2fmc","L4"}
  fmsFunctionsDefs["RTE1"]["R3"]={"setpage","FMC"}
  local line5="                "..string.sub(cleanFMSLine(B747DR_srcfms[fmsID][5]),1,8)
  if acarsSystem.provider.online() then line5=" <SEND          "..string.sub(cleanFMSLine(B747DR_srcfms[fmsID][5]),1,8) end
  local page={
  "      ACT RTE 1     " .. string.sub(cleanFMSLine(B747DR_srcfms[fmsID][1]),-4,-1) ,
  "                        ",
  cleanFMSLine(B747DR_srcfms[fmsID][3]),
  "                        ",
  fmsModules["data"]["runway"] .."            ".. string.sub(cleanFMSLine(B747DR_srcfms[fmsID][7]),-7,-1), 
  "                        ",
  line5,
  cleanFMSLine(B747DR_srcfms[fmsID][8]),
  cleanFMSLine(B747DR_srcfms[fmsID][9]),
  cleanFMSLine(B747DR_srcfms[fmsID][10]),
  cleanFMSLine(B747DR_srcfms[fmsID][11]),
  cleanFMSLine(B747DR_srcfms[fmsID][12]),
  lastLine,
  }
  return page 
end
fmsPages["RTE1"].getSmallPage=function(self,pgNo,fmsID)
	local l1=cleanFMSLine(B747DR_srcfms[fmsID][1])
  local pageNo=tonumber(string.sub(l1,21,22))
  if pageNo~=1 then
	return {
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		}
  end
	local line4 = "               CO ROUTE "
	if acarsSystem.provider.online() then line4=" REQUEST       CO ROUTE " end
	local page={
		"                        ",
		cleanFMSLine(B747DR_srcfms[fmsID][2]),
		"                        ",
		" RUNWAY          FLT NO ",
		"                        ",
		line4,
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		}
	return page 
end
--fmsFunctionsDefs["RTE1"]["L1"]={"custom2fmc","L1"}
fmsFunctionsDefs["RTE1"]["L1"]={"setdata","fltdep"}
--fmsFunctionsDefs["RTE1"]["L1"]={"setdata","origin"}
fmsFunctionsDefs["RTE1"]["L2"]={"setdata","runway"}

fmsFunctionsDefs["RTE1"]["L3"]={"custom2fmc","L3"}
fmsFunctionsDefs["RTE1"]["L4"]={"custom2fmc","L4"}
fmsFunctionsDefs["RTE1"]["L5"]={"custom2fmc","L5"}

--fmsFunctionsDefs["RTE1"]["R1"]={"custom2fmc","R1"}
fmsFunctionsDefs["RTE1"]["R1"]={"setdata","fltdst"}
fmsFunctionsDefs["RTE1"]["R2"]={"custom2fmc","R3"}
fmsFunctionsDefs["RTE1"]["R3"]={"custom2fmc","L2"}
fmsFunctionsDefs["RTE1"]["R4"]={"custom2fmc","R4"}
fmsFunctionsDefs["RTE1"]["R5"]={"custom2fmc","R5"}
fmsFunctionsDefs["RTE1"]["R6"]={"setpage","PERFINIT"}

fmsFunctionsDefs["RTE1"]["next"]={"custom2fmc","next"}
fmsFunctionsDefs["RTE1"]["prev"]={"custom2fmc","prev"}
fmsFunctionsDefs["RTE1"]["exec"]={"custom2fmc","exec"}
dofile("activepages/B744.fms.pages.posinit.lua")
dofile("activepages/B744.fms.pages.perfinit.lua")
dofile("activepages/B744.fms.pages.thrustlim.lua")
dofile("activepages/B744.fms.pages.takeoff.lua")
dofile("activepages/B744.fms.pages.approach.lua")
dofile("activepages/B744.fms.pages.legs.lua")
dofile("activepages/B744.fms.pages.maint.lua")
dofile("activepages/B744.fms.pages.maintbite.lua")
dofile("activepages/B744.fms.pages.maintcrossload.lua")
dofile("activepages/B744.fms.pages.maintirsmonitor.lua")
dofile("activepages/B744.fms.pages.maintperffactor.lua")
dofile("activepages/B744.fms.pages.progress.lua")
dofile("activepages/B744.fms.pages.actrte1.lua")
dofile("activepages/B744.fms.pages.fmccomm.lua")
dofile("activepages/B744.fms.pages.vnav.lua")
dofile("activepages/B744.fms.pages.vnav.lrc.lua")
dofile("activepages/B744.fms.pages.groundhandling.lua")
dofile("activepages/B744.fms.pages.maintsimconfig.lua")
dofile("activepages/B744.fms.pages.identpage.lua")
dofile("activepages/atc/B744.fms.pages.atcindex.lua")
dofile("activepages/atc/B744.fms.pages.atclogonstatus.lua")
dofile("activepages/atc/B744.fms.pages.emergency.lua")
dofile("activepages/atc/B744.fms.pages.atcreport.lua")
dofile("activepages/atc/B744.fms.pages.posreport.lua")
dofile("activepages/atc/B744.fms.pages.request.lua")
dofile("activepages/atc/B744.fms.pages.whencanwe.lua")
dofile("activepages/B744.fms.pages.cmc.lua")
dofile("activepages/B744.fms.pages.acms.lua")
dofile("activepages/B744.fms.pages.pax-cargo.lua")
dofile("activepages/B744.fms.pages.efisctl.lua")
dofile("activepages/B744.fms.pages.eicasctl.lua")
dofile("activepages/B744.fms.pages.doors.lua")
dofile("activepages/B744.fms.pages.soundconfig.lua")

--[[
dofile("B744.fms.pages.actclb.lua")
dofile("B744.fms.pages.actcrz.lua")
dofile("B744.fms.pages.actdes.lua")
dofile("B744.fms.pages.actirslegs.lua")
dofile("B744.fms.pages.actrte1data.lua")
dofile("B744.fms.pages.actrte1hold.lua")
dofile("B744.fms.pages.actrte1legs.lua")
dofile("B744.fms.pages.altnnavradio.lua")
dofile("B744.fms.pages.approach.lua")
dofile("B744.fms.pages.arrivals.lua")


dofile("B744.fms.pages.atcrejectdueto.lua")

dofile("B744.fms.pages.atcreport2.lua")
dofile("B744.fms.pages.atcuplink.lua")
dofile("B744.fms.pages.atcverifyresponse.lua")
dofile("B744.fms.pages.deparrindex.lua")
dofile("B744.fms.pages.departures.lua")
dofile("B744.fms.pages.fixinfo.lua")

dofile("B744.fms.pages.identpage.lua")
dofile("B744.fms.pages.irsprogress.lua")
dofile("B744.fms.pages.navradpage.lua")
dofile("B744.fms.pages.progress.lua")
dofile("B744.fms.pages.refnavdata1.lua")
dofile("B744.fms.pages.satcom.lua")
dofile("B744.fms.pages.waypointwinds.lua")

]]


fmsPages["INITREF"]=createPage("INITREF")
fmsPages["INITREF"].getPage=function(self,pgNo,fmsID)
  local lineA="                        "
  local LineB="<APPROACH               "
  if simDR_onGround ==1 then
    fmsFunctionsDefs["INITREF"]["L5"]={"setpage","TAKEOFF"}
    fmsFunctionsDefs["INITREF"]["R6"]={"setpage","MAINT"}
    lineA="<TAKEOFF                "
    LineB="<APPROACH         MAINT>"
  else
    fmsFunctionsDefs["INITREF"]["L5"]=nil
    fmsFunctionsDefs["INITREF"]["R6"]=nil
  end
  return {

  "     INIT/REF INDEX 1/1 ",
  "                        ",
  "<IDENT         NAV DATA>",
  "                        ",
  "<POS                    ",
  "                        ",
  "<PERF                   ",
  "                        ",
  "<THRUST LIM             ",
  "                        ",
  lineA, 
  "                        ",
  LineB
  }
end

fmsFunctionsDefs["INITREF"]={}
fmsFunctionsDefs["INITREF"]["L1"]={"setpage","IDENT"}
fmsFunctionsDefs["INITREF"]["L2"]={"setpage","POSINIT"}
fmsFunctionsDefs["INITREF"]["L3"]={"setpage","PERFINIT"}
fmsFunctionsDefs["INITREF"]["L4"]={"setpage","THRUSTLIM"}

fmsFunctionsDefs["INITREF"]["L6"]={"setpage","APPROACH"}

fmsFunctionsDefs["INITREF"]["R1"]={"setpage","DATABASE"}
local navAids
simDR_variation=find_dataref("sim/flightmodel/position/magnetic_variation")
B747DR_ils_dots           	= deferred_dataref("laminar/B747/autopilot/ils_dots", "number")
function findILS(value)
  
  local modes=B747DR_radioModes
  if navAidsJSON==nil or string.len(navAidsJSON)<5 then return false end
  if value=="DELETE" then 
    B747DR_radioModes=replace_char(1,modes," ")
	ilsData=""
	B747DR_ils_dots=0
    return true
  end
  B747DR_radioModes=replace_char(1,modes,"M")
  navAids=json.decode(navAidsJSON)
  local direction=nil
  local valueSO=split(value,"/")
  --print(value)
  if table.getn(valueSO) > 1 then
    value=valueSO[1]
     --print(value)
    direction=tonumber(valueSO[2])
    --print(value.." and " .. direction)
  else
    --print(value)
  end
  --print(" in " .. navAidsJSON)
  local val=tonumber(value)
  if val~=nil then val=val*100 end
  local found=false
  local bestDist=360
  for n=table.getn(navAids),1,-1 do
      if navAids[n][2] == 8 then
	  --print("navaid "..n.."->".. navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
	  
	 if (value==navAids[n][8] or (val~=nil and val==navAids[n][3])) and (direction==nil or getHeadingDifferenceM(direction,navAids[n][4])<bestDist) then
	    found=true
		ilsData=json.encode(navAids[n])
		local course=(navAids[n][4]+simDR_variation)
	    print("68 - Tuning ILSs ".. ilsData)
	    if direction ~=nil then
		  bestDist=getHeadingDifferenceM(direction,navAids[n][4])
		  --course=direction
		end
		if course<0 then
			course=course+360
		elseif course>360 then
			course=course-360
  		end
	    simDR_nav1Freq=navAids[n][3]
	    simDR_nav2Freq=navAids[n][3] 	
	    simDR_radio_nav_obs_deg[0]=course
		simDR_radio_nav_obs_deg[1]=course
	    print("68 - Tuned ILS "..course)
	    print("68 - useThis "..bestDist)
	  end
      end
   end

   return found
end



fmsPages["NAVRAD"]=createPage("NAVRAD")

ils_line1 = ""
ils_line2 = ""
park = "PARK"
original_distance = -1

fmsPages["NAVRAD"].getPage=function(self,pgNo,fmsID)
  local ils1="                        "
  local ils2="                        "
  local modes=B747DR_radioModes
  local dist_to_TOD = B747BR_totalDistance - B747BR_tod
  if string.len(ilsData)>1 then
    local ilsNav=json.decode(ilsData)
    ils2= ilsNav[7]
	ils_line2 = "   "..ils2
    if original_distance == -1 then
		original_distance = B747BR_totalDistance  --capture original flightplan distance
	end
  --print("Dist to TOD = "..dist_to_tod)	
	local course = ilsNav[4]+simDR_variation
	if course<0 then
		course=course+360
	end

		if (dist_to_TOD >= 50 and dist_to_TOD < 200) then
			--ils2= string.format("%6.2f/%03d%s %4s          .", ilsNav[3]*0.01,(ilsNav[4]+simDR_variation), "˚", park)
			ils1 = "            "..park
			ils_line1 = string.format("<%6.2f/%03d%s           ", ilsNav[3]*0.01,((simDR_radio_nav_obs_deg[0])), "˚")
		elseif (dist_to_TOD < 50) then
			ils1= string.format("%6.2f/%03d%s          ", ilsNav[3]*0.01,((simDR_radio_nav_obs_deg[0])), "`"..modes:sub(1, 1))
			ils_line1 = ""
		end
  else
    ils1 = park
	ils_line1 = ""
	ils_line2 = ""
  end
  local modes=B747DR_radioModes
  local vorL_radial="---"
  local vorR_radial="---"
  local vorL_obs="---"
  local vorR_obs="---"
  if simDR_radio_nav_horizontal[2]==1 then vorL_radial=string.format("%03d",simDR_radio_nav_radial[2]) end
  if simDR_radio_nav_horizontal[3]==1 then vorR_radial=string.format("%03d",simDR_radio_nav_radial[3]) end
  if modes:sub(2, 2)=="M" then vorL_obs=string.format("%03d",simDR_radio_nav_obs_deg[2]) end
  if modes:sub(3, 3)=="M" then vorR_obs=string.format("%03d",simDR_radio_nav_obs_deg[3]) end
  local page={
    "        NAV RADIO       ",
    "                        ",
    string.format("%6.2f %4s  %4s %6.2f", simDR_radio_nav_freq_hz[2]*0.01, simDR_radio_nav03_ID, simDR_radio_nav04_ID, simDR_radio_nav_freq_hz[3]*0.01),
    string.format("                        ", ""),
    string.format("%3s      %3s  %3s    %3s", vorL_obs, vorL_radial,vorR_radial, vorR_obs),
    "                        ",
    string.format("%06.1f           %06.1f ", simDR_radio_adf1_freq_hz, simDR_radio_adf2_freq_hz),
    "                        ",
    ils1,
--    ils2,
    "                        ",	
    "                        ", 
--    "--------         -------",
    "                        ", 
    fmsModules["data"]["preselectLeft"].."            "..fmsModules["data"]["preselectRight"],
    }
  return page
end
fmsPages["NAVRAD"].getSmallPage=function(self,pgNo,fmsID)
  local modes=B747DR_radioModes
  return{
  "                        ",
  " VOR L             VOR R",
  "      ".. modes:sub(2, 2) .."          ".. modes:sub(3, 3) .."      ",
  " CRS      RADIAL     CRS",
  "                        ",
  " ADF L             ADF R",
  "      M                M",
--  " ILS ".. modes:sub(1, 1) .."                  ",
  " ILS - MLS              ",  
--  "                        ",
  ils_line1,
  ils_line2,
--  ,
--  "                        ",
  "                        ",
  "        PRESELECT       ",
  "                        ",
  }
end
fmsFunctionsDefs["NAVRAD"]["L1"]={"setDref","VORL"}
fmsFunctionsDefs["NAVRAD"]["L2"]={"setDref","CRSL"}
fmsFunctionsDefs["NAVRAD"]["L3"]={"setDref","ADFL"}
fmsFunctionsDefs["NAVRAD"]["R1"]={"setDref","VORR"}
fmsFunctionsDefs["NAVRAD"]["R2"]={"setDref","CRSR"}
fmsFunctionsDefs["NAVRAD"]["R3"]={"setDref","ADFR"}
fmsFunctionsDefs["NAVRAD"]["L4"]={"setDref","ILS"}
fmsFunctionsDefs["NAVRAD"]["L6"]={"setdata","preselectLeft"}
fmsFunctionsDefs["NAVRAD"]["R6"]={"setdata","preselectRight"}
--fmsFunctionsDefs["NAVRAD"]["L6"]={"setpage","ACARS"}
function fmsFunctions.setpage_no(fmsO,valueA)
  print("setpage_no="..valueA)
    local valueO=split(valueA,"_")
    print(valueO[1].." "..valueO[2])
   --fmsO["pgNo"]=tonumber(valueO[2])
   fmsO["targetpgNo"]=tonumber(valueO[2])
   value=valueO[1]

     
  if value=="FMC" then
    fmsO["targetCustomFMC"]=false
    fmsO["targetPage"]="FMC"
    simCMD_FMS_key[fmsO.id]["fpln"]:once()
    simCMD_FMS_key[fmsO.id]["L6"]:once()
	simCMD_FMS_key[fmsO.id]["L2"]:once()
  elseif value=="PROGRESS" then
	fmsModules[fmsO.id].targetCustomFMC=false
    simCMD_FMS_key[fmsO.id]["prog"]:once()
    fmsModules[fmsO.id].targetPage="PROGRESS"
	fmsModules[fmsO.id].targetpgNo=1
  elseif value=="VHFCONTROL" then
    fmsO["targetCustomFMC"]=false
    fmsO["targetPage"]="VHFCONTROL"
    simCMD_FMS_key[fmsO.id]["navrad"]:once()
    
  elseif value=="IDENT" then
    fmsO["targetCustomFMC"]=true
    fmsO["targetPage"]="IDENT"
    simCMD_FMS_key[fmsO.id]["index"]:once()
    simCMD_FMS_key[fmsO.id]["L1"]:once()
    
  elseif value=="DATABASE" then
    fmsO["targetCustomFMC"]=false
    fmsO["targetPage"]="DATABASE"
    simCMD_FMS_key[fmsO.id]["index"]:once()
    simCMD_FMS_key[fmsO.id]["R2"]:once()
  elseif value=="RTE1" then
    simCMD_FMS_key[fmsO.id]["fpln"]:once()
    fmsO["targetCustomFMC"]=true
    fmsO["targetPage"]="RTE1"
  elseif value=="RTE2" then
    fmsO["targetCustomFMC"]=false
    fmsO["targetPage"]="RTE2"
    simCMD_FMS_key[fmsO.id]["dir_intc"]:once()
  elseif value=="LEGS" then
	fmsModules[fmsO.id].targetCustomFMC=true
	fmsModules[fmsO.id].targetPage="LEGS"
	simCMD_FMS_key[fmsO.id]["legs"]:once()
	fmsModules[fmsO.id].targetpgNo=1  
  else
    fmsO["targetCustomFMC"]=true
    fmsO["targetPage"]=value 
 
  end
  print("setpage " .. value)
  run_after_time(switchCustomMode, 0.5)
end
function fmsFunctions.setpage(fmsO,value)
  value=value.."_1"
  fmsFunctions["setpage_no"](fmsO,value)
  --sim/FMS/navrad
  --sim/FMS2/navrad
  
end
function fmsFunctions.custom2fmc(fmsO,value)
  print("custom2fmc" .. value)
  simCMD_FMS_key[fmsO["id"]]["del"]:once()
  simCMD_FMS_key[fmsO["id"]]["clear"]:once()
  if value~="next" and value~="prev" and string.len(fmsO["scratchpad"])>0 then
    for c in string.gmatch(fmsO["scratchpad"],".") do
      local v=c
	if v=="/" then v="slash" end
	simCMD_FMS_key[fmsO["id"]][v]:once()
    end
  elseif value=="next" then
    fmsO["targetpgNo"]=fmsO["pgNo"]+1
    run_after_time(switchCustomMode, 0.5)
  elseif value=="prev" then 
    fmsO["targetpgNo"]=fmsO["pgNo"]-1
    run_after_time(switchCustomMode, 0.5)
  end
  simCMD_FMS_key[fmsO["id"]][value]:once()
  fmsO["scratchpad"]=""
end
function fmsFunctions.key2fmc(fmsO,value)
  print("key2fmc" .. value)
  if string.len(fmsO["scratchpad"])>0 then
    simCMD_FMS_key[fmsO["id"]]["del"]:once()
    simCMD_FMS_key[fmsO["id"]]["clear"]:once()
    if value~="next" and value~="prev" then
      for c in string.gmatch(fmsO["scratchpad"],".") do
	local v=c
	if v=="/" then v="slash" end
	simCMD_FMS_key[fmsO["id"]][v]:once()
      end
    end
  end
  simCMD_FMS_key[fmsO["id"]][value]:once()
  fmsO["scratchpad"]=""
  fmsO["notify"]=""
end
local updateFrom="fmsL"
local lastCrz=0

function updateCRZ()
  local setVal=string.sub(B747DR_srcfms[updateFrom][3],20,24)
  print("from line".. updateFrom.." "..B747DR_srcfms[updateFrom][3])
  print("to:"..setVal)
  local alt=validAlt(setVal)
  if alt~=nil then 
	B747BR_cruiseAlt=alt 
	lastCrz=B747BR_cruiseAlt
  end
  fmsModules:setData("crzalt",setVal)
end

function monitorCRZALT()
	local thisCRZ=B747BR_cruiseAlt
	if not(thisCRZ==lastCrz) then
		print("update because "..thisCRZ.."!="..lastCrz)
		local fmsO=fmsL
		simCMD_FMS_key[fmsO.id]["fpln"]:once()--make sure we arent on the vnav page
		simCMD_FMS_key[fmsO.id]["clb"]:once()--go to the vnav page
		simCMD_FMS_key[fmsO.id]["next"]:once() --go to the vnav page 2
		local newcrzalt=""..B747BR_cruiseAlt
		for c in string.gmatch(newcrzalt,".") do
			local v=c
		  	if v=="/" then v="slash" end
			simCMD_FMS_key[fmsO["id"]][v]:once()
		end
		simCMD_FMS_key[fmsO["id"]]["R1"]:once()
		updateFrom=fmsO.id
		local toGet=B747DR_srcfms[updateFrom][3] --make sure we update it
		if is_timer_scheduled(updateCRZ) == true then
			stop_timer(updateCRZ)                                -- KILL THE TIMER
		end
		run_after_time(updateCRZ,2.0)
		lastCrz=B747BR_cruiseAlt
	end
	
end

function fmsFunctions.getdata(fmsO,value) 
  local data=""
  if value=="gpspos" then
    data=irsSystem.getLat("gpsL") .." " .. irsSystem.getLon("gpsL")
  elseif value=="lastpos" then
    data=irsSystem.calcLatA() .." "..irsSystem.calcLonA()
  else
    data=getFMSData(value)
  end
  fmsO["scratchpad"]=data
end
function validateSpeed(value)
  local val=tonumber(value)
  if val==nil then return false end
  if val<130 or val>300 then return false end

  return true
end
function validAlt(value)
  local val=tonumber(value)
  if string.len(value)>2 and string.sub(value,1,2)=="FL" then val=tonumber(string.sub(value,3)) end
  
  if val==nil then return nil end
  if val<1000 then val=val*100 end
  local maxA = 58.16363636 - 0.06154545  * (simDR_GRWT/1000) -- model derived fcom p. 1576, ISA+10 and below
  if val<2000 or val>(maxA*1000) then return nil end

  return ""..val
end
function validFL(value)
  local val=tonumber(value)
  if string.len(value)>2 and string.sub(value,1,2)=="FL" then val=tonumber(string.sub(value,3)) end
  
  if val==nil then return nil end
  if val<1000 then val=val*100 end
  local maxA = 58.16363636 - 0.06154545  * (simDR_GRWT/1000) -- model derived fcom p. 1576, ISA+10 and below
  if val<10000 or val>(maxA*1000) then return nil end

  return "FL".. (val/100)
end
function validateMachSpeed(value)
  local val=tonumber(value)
  
  
  if val==nil then return nil end
  if val<1 then val=val*1000 end
  if val<100 then val=val*10 end
  if val<400 or val>870 then return nil end

  return ""..val
end

-- VALIDATE ENTRY OF WEIGHT UNITS
function validate_weight_units(value)
	--local val=tostring(value)
	--print(value)
	if value == "KGS" or value == "LBS" then
		return true
	else
		return false
	end
end

-- VALIDATE ENTRY OF SETHDG
function validate_sethdg(value)
	--print(value)
	if tonumber(value) >= 0 and tonumber(value) <= 360 then
		return true
	else
		return false
	end
end

function preselect_fuel()
	-- DETERMINE FUEL WEIGHT DISPLAY UNITS
	local fuel_calculation_factor = 1
	
	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		fuel_calculation_factor = simConfigData["data"].SIM.kgs_to_lbs
	end
	
	B747DR_refuel=B747DR_fuel_add * 1000 / fuel_calculation_factor  --(always add fuel in KGS behind the scenes)
	B747DR_fuel_preselect=simDR_fueL_tank_weight_total_kg + B747DR_refuel
	
	-- Used in calculation for displaying Preselect Fuel Qty in correct weight units (actual display done in B747.25.xt.fuel)
	B747DR_fuel_preselect_temp = B747DR_fuel_preselect
	B747DR_fuel_add=0
	simDR_m_jettison=simDR_acf_m_jettison
	
	--Marauder28
	--Set the totalizer to the current fuel amount before refueling
	simDR_fuel_totalizer_kg = simDR_fueL_tank_weight_total_kg
	--Marauder28
end

--Marauder28
function calc_pax_cargo()
	local pax_total				= 0
	local pax_weightA			= 0
	local pax_weightB			= 0
	local pax_weightC			= 0
	local pax_weightD			= 0
	local pax_weightE			= 0
	local pax_weight_Tot		= 0
	local cargo_weight_fwd		= 0
	local cargo_weight_aft		= 0
	local cargo_weight_bulk		= 0
	local cargo_weight_tot		= 0
	local freight_weightA		= 0
	local freight_weightB		= 0
	local freight_weightC		= 0
	local freight_weightD		= 0
	local freight_weightE		= 0
	local freight_weight_tot	= 0

	pax_total		= 	tonumber(fmsModules["data"].paxFirstClassA) + tonumber(fmsModules["data"].paxBusClassB)
						+ tonumber(fmsModules["data"].paxEconClassC) + tonumber(fmsModules["data"].paxEconClassD)
						+ tonumber(fmsModules["data"].paxEconClassE)
	pax_weightA		=	tonumber(fmsModules["data"].paxFirstClassA) * simConfigData["data"].SIM.std_pax_weight
	pax_weightB		= 	tonumber(fmsModules["data"].paxBusClassB) * simConfigData["data"].SIM.std_pax_weight
	pax_weightC		=	tonumber(fmsModules["data"].paxEconClassC) * simConfigData["data"].SIM.std_pax_weight
	pax_weightD		=	tonumber(fmsModules["data"].paxEconClassD) * simConfigData["data"].SIM.std_pax_weight
	pax_weightE		=	tonumber(fmsModules["data"].paxEconClassE) * simConfigData["data"].SIM.std_pax_weight
	pax_weight_Tot	=	pax_weightA + pax_weightB + pax_weightC + pax_weightD + pax_weightE

	cargo_weight_fwd	= tonumber(fmsModules["data"].cargoFwd)
	cargo_weight_aft	= tonumber(fmsModules["data"].cargoAft)
	cargo_weight_bulk	= tonumber(fmsModules["data"].cargoBulk)
	cargo_weight_tot	= cargo_weight_fwd + cargo_weight_aft + cargo_weight_bulk
	
	freight_weightA		= tonumber(fmsModules["data"].freightZoneA)
	freight_weightB		= tonumber(fmsModules["data"].freightZoneB)
	freight_weightC		= tonumber(fmsModules["data"].freightZoneC)
	freight_weightD		= tonumber(fmsModules["data"].freightZoneD)
	freight_weightE		= tonumber(fmsModules["data"].freightZoneE)
	freight_weight_tot	= freight_weightA + freight_weightB + freight_weightC + freight_weightD + freight_weightE
	
	--Assign values to FMC
	fmsModules["data"].paxTotal 		= pax_total
	fmsModules["data"].paxWeightA		= pax_weightA
	fmsModules["data"].paxWeightB		= pax_weightB
	fmsModules["data"].paxWeightC		= pax_weightC
	fmsModules["data"].paxWeightD		= pax_weightD
	fmsModules["data"].paxWeightE		= pax_weightE
	fmsModules["data"].paxWeightTotal	= pax_weight_Tot
	fmsModules["data"].cargoTotal		= cargo_weight_tot
	fmsModules["data"].freightTotal		= freight_weight_tot
	
	--Assign values to WB
	wb.passenger_zoneA_weight		= pax_weightA	
	wb.passenger_zoneB_weight		= pax_weightB
	wb.passenger_zoneC_weight		= pax_weightC
	wb.passenger_zoneD_weight		= pax_weightD
	wb.passenger_zoneE_weight		= pax_weightE
	wb.fwd_lower_cargo_weight		= cargo_weight_fwd
	wb.aft_lower_cargo_weight		= cargo_weight_aft
	wb.bulk_lower_cargo_weight		= cargo_weight_bulk
	wb.freight_zoneA_weight			= freight_weightA
	wb.freight_zoneB_weight			= freight_weightB
	wb.freight_zoneC_weight			= freight_weightC
	wb.freight_zoneD_weight			= freight_weightD
	wb.freight_zoneE_weight			= freight_weightE
	
	--Update Sim Payload weight with PAX & Cargo entries
	simDR_payload_weight = pax_weight_Tot + cargo_weight_tot + freight_weight_tot
	
	--print("PAX A Wgt = "..pax_weightA)
	--print("PAX A = "..tonumber(fmsModules["data"].paxFirstClassA))
	--print("PAX B Wgt = "..pax_weightB)
	--print("PAX B = "..tonumber(fmsModules["data"].paxBusClassB))
	--print("PAX C Wgt = "..pax_weightC)
	--print("PAX C = "..tonumber(fmsModules["data"].paxEconClassC))
	--print("PAX D Wgt = "..pax_weightD)
	--print("PAX D = "..tonumber(fmsModules["data"].paxEconClassD))
	--print("PAX E Wgt = "..pax_weightE)
	--print("PAX E = "..tonumber(fmsModules["data"].paxEconClassE))
	--print("PAX Tot = "..pax_weight_Tot)
	--print("Cargo Fwd = "..cargo_weight_fwd)
	--print("Cargo Aft = "..cargo_weight_aft)
	--print("Cargo Bulk = "..cargo_weight_bulk)
	--print("Cargo Tot = "..cargo_weight_tot)
	--print("FREIGHT A = "..freight_weightA)
	--print("FREIGHT B = "..freight_weightB)
	--print("FREIGHT C = "..freight_weightC)
	--print("FREIGHT D = "..freight_weightD)
	--print("FREIGHT E = "..freight_weightE)
	--print("Freight Tot = "..freight_weight_tot)
end
--Marauder28

--Marauder28
timer_start = 0
--Marauder28

function fmsFunctions.setdata(fmsO,value)
  local del=false  
  if fmsO["scratchpad"]=="DELETE" then fmsO["scratchpad"]="" del=true end
  if value=="WXR" then
		fmsModules["cmds"]["sim/instruments/EFIS_wxr"]:once()  
  elseif value=="POS" then
  elseif value=="TERR" then
	if fmsO.id=="fmsR" then 
		B747DR_nd_fo_terr = 1-B747DR_nd_fo_terr
	else
		B747DR_nd_capt_terr=1-B747DR_nd_capt_terr
	end
  elseif value=="TFC" then
	if fmsO.id=="fmsR" then 
		B747DR_nd_fo_traffic_Selected=1-B747DR_nd_fo_traffic_Selected
	else
		B747DR_nd_capt_traffic_Selected=1-B747DR_nd_capt_traffic_Selected
	end
	
  elseif value=="VORDISP" then
	if fmsO.id=="fmsR" then 
		simDR_EFIS_1_sel_fo =2
		simDR_EFIS_2_sel_fo =2
	else
		simDR_EFIS_1_sel_pilot=2
		simDR_EFIS_2_sel_pilot=2
	end
  elseif value=="WPT" then
	
	if fmsO.id=="fmsR" then 
		B747DR_nd_fo_wpt=1-B747DR_nd_fo_wpt 
	else
		B747DR_nd_capt_wpt=1-B747DR_nd_capt_wpt
	end
  elseif value=="STA" then
	if fmsO.id=="fmsR" then 
		B747DR_nd_fo_vor_ndb = 1-B747DR_nd_fo_vor_ndb 
	else
		B747DR_nd_capt_vor_ndb=1-B747DR_nd_capt_vor_ndb
	end
  elseif value=="ARPT" then
	if fmsO.id=="fmsR" then 
		B747DR_nd_fo_apt=1-B747DR_nd_fo_apt
	else
		B747DR_nd_capt_apt=1-B747DR_nd_capt_apt
	end
  elseif value=="DATA" then
  elseif value=="ADFDISP" then
	if fmsO.id=="fmsR" then 
		simDR_EFIS_1_sel_fo =0
		simDR_EFIS_2_sel_fo =0
	else
		simDR_EFIS_1_sel_pilot=0
		simDR_EFIS_2_sel_pilot=0
	end
  elseif value=="DH" then
	if tonumber(fmsO["scratchpad"]) ==nil then 
		fmsO["notify"]="INVALID ENTRY"
		return
	end
	local alt=tonumber(fmsO["scratchpad"])
	if fmsO.id=="fmsR" then 
		simDR_radio_alt_DH_fo=alt
	else
		simDR_radio_alt_DH_capt=alt
	end
  elseif value=="MDA" then
		if tonumber(fmsO["scratchpad"]) ==nil then 
			fmsO["notify"]="INVALID ENTRY"
			return
		end
		local alt=tonumber(fmsO["scratchpad"])
		if fmsO.id=="fmsR" then 
			B747DR_efis_baro_alt_ref_fo=alt
		else
			B747DR_efis_baro_alt_ref_capt=alt
		end
  elseif value=="EFISMAP" then
	if fmsO.id=="fmsR" then 
		simDR_nd_mode_dial_fo= 2
	else
		simDR_nd_mode_dial_capt= 2
	end
  elseif value=="EFISPLN" then
		if fmsO.id=="fmsR" then 
			simDR_nd_mode_dial_fo= 3
		else
			simDR_nd_mode_dial_capt= 3
		end	
  elseif value=="EFISAPP" then
		if fmsO.id=="fmsR" then 
			simDR_nd_mode_dial_fo= 0
		else
			simDR_nd_mode_dial_capt= 0
		end	
  elseif value=="EFISVOR" then
		if fmsO.id=="fmsR" then 
			simDR_nd_mode_dial_fo= 1
		else
			simDR_nd_mode_dial_capt= 1
		end	
  elseif value=="EFISCTR" then
		if fmsO.id=="fmsR" then 
			simDR_nd_center_dial_fo= 1-simDR_nd_center_dial_fo
		else
			simDR_nd_center_dial_capt= 1-simDR_nd_center_dial_capt
		end	
	elseif value=="BARO" then
		if fmsO["scratchpad"]=="S" or fmsO["scratchpad"]=="STD" then
			simDR_altimeter_baro_inHg_fo=29.92
			simDR_altimeter_baro_inHg=29.92
			B747DR_efis_baro_std_capt_switch_pos=1
			B747DR_efis_baro_std_fo_switch_pos=1
			return
		end
		if tonumber(fmsO["scratchpad"]) ==nil then 
			fmsO["notify"]="INVALID ENTRY"
			return
		end
		local baro=tonumber(fmsO["scratchpad"])
		if fmsO.id=="fmsR" then 
			if B747DR_efis_baro_ref_fo_sel_dial_pos==1 then 
				baro=baro/33.863892
			end
			
		else
			if B747DR_efis_baro_ref_capt_sel_dial_pos==1 then 
				baro=baro/33.863892
			end
			
		end	
		simDR_altimeter_baro_inHg_fo=baro
		simDR_altimeter_baro_inHg=baro
		B747DR_efis_baro_std_capt_switch_pos=0
		B747DR_efis_baro_std_fo_switch_pos=0
  elseif value=="RANGEINC" then
	simDR_range_dial_fo=math.min(simDR_range_dial_fo+1, 6)
	simDR_range_dial_capt=simDR_range_dial_fo
	simDR_EFIS_map_range=simDR_range_dial_fo
  elseif value=="RANGEDEC" then	
	simDR_range_dial_fo=math.max(simDR_range_dial_fo-1, 0)
	simDR_range_dial_capt=simDR_range_dial_fo
	simDR_EFIS_map_range=simDR_range_dial_fo
  elseif value=="depdst" and string.len(fmsO["scratchpad"])>3  then
    dep=string.sub(fmsO["scratchpad"],1,4)
    dst=string.sub(fmsO["scratchpad"],-4)
    --fmsModules["data"]["fltdep"]=dep
    --fmsModules["data"]["fltdst"]=dst
    setFMSData("fltdep",dep)
    setFMSData("fltdst",dst)
  elseif value=="clbspd" then
    if validateSpeed(fmsO["scratchpad"]) ==false then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("clbspd",fmsO["scratchpad"])
    end
  elseif value=="clbtrans" then
    spd=string.sub(fmsO["scratchpad"],1,3)
    alt=string.sub(fmsO["scratchpad"],5)
    if validateSpeed(spd) ==false then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("transpd",spd)
      if validAlt(alt) ~=nil then 
	setFMSData("spdtransalt",validAlt(alt))
      end
    end
  elseif value=="transalt" then
    if validAlt(fmsO["scratchpad"]) ~=nil then 
	setFMSData("transalt",validAlt(fmsO["scratchpad"]))
    else
      fmsO["notify"]="INVALID ENTRY"
    end
  elseif value=="clbrest" then
    spd=string.sub(fmsO["scratchpad"],1,3)
    alt=string.sub(fmsO["scratchpad"],5)
    if validateSpeed(spd) ==false then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("clbrestspd",spd)
      if validAlt(alt) ~=nil then 
	setFMSData("clbrestalt",validAlt(alt))
      end
    end
  elseif value=="crzspd" then
    if validateMachSpeed(fmsO["scratchpad"]) ==nil then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("crzspd",validateMachSpeed(fmsO["scratchpad"]))
    end
  elseif value=="stepalt" then
    if validFL(fmsO["scratchpad"]) ~=nil then 
		setFMSData("stepalt",validFL(fmsO["scratchpad"]))
    else
      fmsO["notify"]="INVALID ENTRY"
    end
  elseif value=="desspds" then
    div = string.find(fmsO["scratchpad"], "%/")
    spd=getFMSData("desspd")
   -- print(spd)
    if div==nil then 
      div=string.len(fmsO["scratchpad"])+1 
    else
      spd=string.sub(fmsO["scratchpad"],div+1)
    end
   -- print(spd)
    machspd=string.sub(fmsO["scratchpad"],1,div-1)
    if validateMachSpeed(machspd) ==nil or validateSpeed(spd) ==false then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("desspd",spd)
      setFMSData("desspdmach",validateMachSpeed(machspd))
    end
  elseif value=="destrans" then
    spd=string.sub(fmsO["scratchpad"],1,3)
    alt=string.sub(fmsO["scratchpad"],5)
    if validateSpeed(spd) ==false then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("destranspd",spd)
      if validAlt(alt) ~=nil then 
	setFMSData("desspdtransalt",validAlt(alt))
      end
    end 
   elseif value=="desrest" then
    spd=string.sub(fmsO["scratchpad"],1,3)
    alt=string.sub(fmsO["scratchpad"],5)
    if validateSpeed(spd) ==false then 
      fmsO["notify"]="INVALID ENTRY"
    else
      setFMSData("desrestspd",spd)
      if validAlt(alt) ~=nil then 
	setFMSData("desrestalt",validAlt(alt))
      end
    end
  elseif value=="airportpos" then --and string.len(fmsO["scratchpad"])>3 then
    
	if string.len(navAidsJSON) > 1 and string.len(fmsO["scratchpad"])>3 then
		local navAids=json.decode(navAidsJSON)
		print(table.getn(navAids).." navaids")
		--print(navAidsJSON)
		for n=table.getn(navAids),1,-1 do
		  if navAids[n][2] == 1 and navAids[n][8]==fmsO["scratchpad"] then
			print("navaid "..n.."->".. navAids[n][1].." ".. navAids[n][2].." ".. navAids[n][3].." ".. navAids[n][4].." ".. navAids[n][5].." ".. navAids[n][6].." ".. navAids[n][7].." ".. navAids[n][8])
			local lat=toDMS(navAids[n][5],true)
			local lon=toDMS(navAids[n][6],false)
		
			setFMSData("irsLat",lat)
			setFMSData("irsLon",lon)
			--irsSystem["irsLat"]=lat
			--irsSystem["irsLon"]=lon
		  end
		end
		setFMSData("airportpos",fmsO["scratchpad"])
		setFMSData("airportgate","----")
	elseif del == true then
		setFMSData("airportpos",defaultFMSData().airportpos)
		setFMSData("airportpos",defaultFMSData().airportgate)
		setFMSData("irsLat",defaultFMSData().irsLat)
		setFMSData("irsLon",defaultFMSData().irsLon)		
	end

  elseif value=="flttime" then 
    hhV=string.sub(fmsO["scratchpad"],1,2)
    mmV=string.sub(fmsO["scratchpad"],-2)
    setFMSData("flttimehh",hhV)
    setFMSData("flttimemm",mmV)
  elseif value=="rpttime" then 
    hhV=string.sub(fmsO["scratchpad"],1,2)
    mmV=string.sub(fmsO["scratchpad"],-2)
    setFMSData("rpttimehh",hhV)
    setFMSData("rpttimemm",mmV)
  elseif value=="fltdate" then 
    setFMSData("fltdate",os.date("%Y%m%d"))
  elseif value=="crzalt" then
	if IN_REPLAY==1 then
		fmsModules:setData("crzalt","FL350") -- if in replay just default to FL350 since we cant set the default FMS
	else
		if string.len(fmsO["scratchpad"])>0 then
			local alt=validAlt(fmsO["scratchpad"])
			if alt~=nil then 
				simCMD_FMS_key[fmsO.id]["fpln"]:once()--make sure we arent on the vnav page
				simCMD_FMS_key[fmsO.id]["clb"]:once()--go to the vnav page
				simCMD_FMS_key[fmsO.id]["next"]:once() --go to the vnav page 2

				fmsFunctions["custom2fmc"](fmsO,"R1")
				updateFrom=fmsO.id
				local toGet=B747DR_srcfms[updateFrom][3] --make sure we update it
				run_after_time(updateCRZ,0.5)
			else
				fmsO["notify"]="INVALID CRZ ALT"
			end
		else
			fmsModules:setData("crzalt","")
			B747BR_cruiseAlt=0
		end	
	end
	--[[if string.len(fmsO["scratchpad"])>0 then
		local alt=validAlt(fmsO["scratchpad"])
		if alt~=nil then 
			B747BR_cruiseAlt=alt 
			lastCrz=alt
			fmsModules:setData("crzalt",fmsO["scratchpad"])
		else
			fmsO["notify"]="INVALID CRZ ALT"
		end
	else
		fmsModules:setData("crzalt","")
		B747BR_cruiseAlt=0
	end]]--
  elseif value=="irspos" then
	if string.len(fmsO["scratchpad"])>10 then
		print("set irs pos")
		lat=string.sub(fmsO["scratchpad"],1,9)
		lon=string.sub(fmsO["scratchpad"],-9)
		--fmsModules["data"]["fltdep"]=dep
		--fmsModules["data"]["fltdst"]=dst
		print(getFMSData("irsLat").." "..lat)
		print(getFMSData("irsLon").." "..lon)
		setFMSData("irsLat",lat)
		setFMSData("irsLon",lon)
		irsSystem["irsLat"]=lat
		irsSystem["irsLon"]=lon
		irsSystem["setPos"]=true
		fmsModules["data"]["initIRSLat"]=lat
		fmsModules["data"]["initIRSLon"]=lon
		B747DR_fmc_notifications[12]=0
	else
		fmsO["notify"]="INVALID ENTRY"
	end
--     if fmsModules["fmsL"].notify=="ENTER IRS POSITION" then fmsModules["fmsL"].notify="" end
--     if fmsModules["fmsC"].notify=="ENTER IRS POSITION" then fmsModules["fmsC"].notify="" end
--     if fmsModules["fmsR"].notify=="ENTER IRS POSITION" then fmsModules["fmsR"].notify="" end
   elseif value=="passengers" then
     local numPassengers=tonumber(fmsO["scratchpad"])
     if numPassengers==nil then numPassengers=2 end
     if numPassengers<2 then numPassengers=2 end
     if numPassengers>416 then numPassengers=416 end
     B747DR_payload_weight=numPassengers*120
   elseif value=="services" then
     if simDR_acf_m_jettison==0 then
		if B747DR_elec_ext_pwr1_available==0 then
        	fmsModules["cmds"]["laminar/B747/electrical/connect_power"]:once() 
		end
		fmsModules["cmds"]["sim/ground_ops/service_plane"]:once() 
     end
     fmsModules["lastcmd"]=fmsModules["cmdstrings"]["sim/ground_ops/service_plane"]
     run_after_time(preselect_fuel,30)
   elseif value=="fuelpreselect" then
	if string.len(fmsO["scratchpad"])>0 then
     local fuel=tonumber(fmsO["scratchpad"])
     if fuel~=nil then
       B747DR_fuel_add=fuel
       
     end
	else
		fmsO["notify"]="INVALID ENTRY"
	end
   elseif value=="origin" then
	if string.len(fmsO["scratchpad"])>0 then
     fmsFunctions["custom2fmc"](fmsO,"L1")
     fmsModules:setData("crzalt","*****") -- clear cruise alt /crzalt when entering a new source airport (this is broken and currently disabled)
	else
		fmsO["notify"]="INVALID ENTRY"
	end
   elseif value=="airportgate" then
	if string.len(fmsO["scratchpad"])>0 then
		local lat=toDMS(simDR_latitude,true)
		local lon=toDMS(simDR_longitude,false)
		irsSystem["irsLat"]=lat
		irsSystem["irsLon"]=lon
		setFMSData("irsLat",lat)
		setFMSData("irsLon",lon)
		setFMSData(value,fmsO["scratchpad"])
	else
		fmsO["notify"]="INVALID ENTRY"
	end
  elseif value == "codata" then
	if string.len(fmsO["scratchpad"])>0 then
		setFMSData(value, fmsO["scratchpad"])
	else
		fmsO["notify"]="INVALID ENTRY"
	end
  elseif value == "sethdg" then
	if validate_sethdg(fmsO["scratchpad"]) == false then
		fmsO["notify"]="INVALID ENTRY"
	else
		if fmsModules["data"] ~= "---`" then
			if (fmsO["scratchpad"] == "0" or fmsO["scratchpad"] == "00" or fmsO["scratchpad"] == "000") then
				fmsO["scratchpad"] = "360`"
			end
			setFMSData(value, fmsO["scratchpad"].."`")
			timer_start = simDRTime
		end
	end
  elseif value == "fltdep" then
	print("set fltdep "..fmsO["scratchpad"])
	if string.len(fmsO["scratchpad"])>0 or del==true then
		fmsFlightPlan = "[]" --clear the flight plan
		if del==true then
			setFMSData("fltdep","****")
			setFMSData("fltdst","****")
		else	
			dep=string.sub(fmsO["scratchpad"],1,4)
			setFMSData("fltdep",dep)
			setFMSData("fltdst","****")
			simCMD_FMS_key[fmsO.id]["fpln"]:once()
			fmsFunctions["custom2fmc"](fmsO,"L1")
		end
		fmsModules:setData("crzalt","*****") -- clear cruise alt /crzalt when entering a new source airport
	else
		   fmsO["notify"]="INVALID ENTRY"
	end
  elseif value == "fltdst" then
	print("set fltdst")
	if string.len(fmsO["scratchpad"])>0 or del==true then
		if del==true then
			setFMSData("fltdep","****")
			setFMSData("fltdst","****")
			fmsFlightPlan = "[]" --clear the flight plan
		else	
			dep=string.sub(fmsO["scratchpad"],1,4)
			setFMSData("fltdst",dep)
			simCMD_FMS_key[fmsO.id]["fpln"]:once()
			fmsFunctions["custom2fmc"](fmsO,"R1")
		end
	else
		fmsO["notify"]="INVALID ENTRY"
 	end
  elseif value == "vref1" then
	fmsO["scratchpad"]=string.format("25/%3d", B747DR_airspeed_Vf25)
	return
  elseif value == "vref2" then
	fmsO["scratchpad"]=string.format("30/%3d", B747DR_airspeed_Vf30)
	return
  elseif value == "flapspeed" then
	if fmsO["scratchpad"]=="" then 
		B747DR_airspeed_VrefFlap=0
		setFMSData(value,"") 
		return 
	end
	local vref=tonumber(string.sub(fmsO["scratchpad"],4))
	if vref==nil or vref<110 or vref>180 then 
		fmsO["notify"]="INVALID ENTRY" 
		return 
	end
	B747DR_airspeed_Vref=vref
	print(string.sub(fmsO["scratchpad"],1,2))
	if string.sub(fmsO["scratchpad"],1,2) == "25" then
		B747DR_airspeed_VrefFlap=1
  	else
		B747DR_airspeed_VrefFlap=2
	end	
	setFMSData(value,fmsO["scratchpad"])
  elseif value == "grwt" then
	local grwt
	if string.len(fmsO["scratchpad"]) ~= 0 and string.len(fmsO["scratchpad"]) ~= 3 and string.len(fmsO["scratchpad"]) ~= 5 then
		fmsO["notify"]="INVALID ENTRY"
		fmsO["scratchpad"] = ""
		return
  	elseif string.len(fmsO["scratchpad"]) > 0 and string.len(fmsO["scratchpad"]) <= 5 and tonumber(fmsO["scratchpad"])~=nil then
		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			grwt = tonumber(fmsO["scratchpad"]) / simConfigData["data"].SIM.kgs_to_lbs  --store LBS in KGS
		else
			grwt = tonumber(fmsO["scratchpad"])
		end
	elseif fmsO["scratchpad"] == "" then
		grwt = simDR_GRWT / 1000
	else
		fmsO["notify"]="INVALID ENTRY"
		fmsO["scratchpad"] = ""
		return
	end
	grwt = string.format("%5.1f", grwt)
	if tonumber(grwt) > 999 then
		fmsO["notify"]="INVALID ENTRY"
		fmsO["scratchpad"] = ""
		return
	end
	zfw = string.format("%5.1f", tonumber(grwt) - (simDR_fuel / 1000))
	if tonumber(zfw) <50 then
		fmsO["notify"]="INVALID ENTRY"
		fmsO["scratchpad"] = ""
		return
	end
	setFMSData(value, grwt)
	setFMSData("zfw", zfw)
	calc_CGMAC()  --Recalc CG %MAC and TRIM units
	if (B747DR_airspeed_V1 < 999 or B747DR_airspeed_Vr < 999 or B747DR_airspeed_V2 < 999) and simDR_onground == 1 then
		B747DR_airspeed_flapsRef = 0
		--B747DR_airspeed_V1 = 999
		--B747DR_airspeed_Vr = 999
		--B747DR_airspeed_V2 = 999
		fmsO["notify"] = "TAKEOFF SPEEDS DELETED"
	end

  elseif value == "zfw" and not del then
	local zfw
	if string.len(fmsO["scratchpad"]) > 0 and string.len(fmsO["scratchpad"]) <= 5 and string.match(fmsO["scratchpad"], "%d") then
		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			zfw = fmsO["scratchpad"] / simConfigData["data"].SIM.kgs_to_lbs  --store LBS in KGS
		else
			zfw = fmsO["scratchpad"]
		end
	elseif fmsO["scratchpad"] == "" then
		zfw = (simDR_GRWT-simDR_fuel) / 1000
	else
		fmsO["notify"]="INVALID ENTRY"
		fmsO["scratchpad"] = ""
		return
	end
	zfw = string.format("%5.1f", zfw)
	grwt = string.format("%5.1f", tonumber(zfw) + (simDR_fuel / 1000))
	setFMSData(value, zfw)
	setFMSData("grwt", grwt)
	calc_CGMAC()  --Recalc CG %MAC and TRIM units
	if (B747DR_airspeed_V1 < 999 or B747DR_airspeed_Vr < 999 or B747DR_airspeed_V2 < 999) and simDR_onground == 1 then
		B747DR_airspeed_flapsRef = 0
		--B747DR_airspeed_V1 = 999
		--B747DR_airspeed_Vr = 999
		--B747DR_airspeed_V2 = 999
		fmsO["notify"] = "TAKEOFF SPEEDS DELETED"
	end
  elseif value == "reserves" then
	local rsv = 0
	if not string.match(fmsO["scratchpad"], "%d") or string.len(fmsO["scratchpad"]) > 5 then
		fmsO["notify"] = "INVALID ENTRY"
		fmsO["scratchpad"] = ""
		return
	else
		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			rsv = string.format("%5.1f", fmsO["scratchpad"] / simConfigData["data"].SIM.kgs_to_lbs)  --store LBS in KGS
		else
			rsv = string.format("%5.1f", fmsO["scratchpad"])
		end
		setFMSData(value, rsv)
	end
  elseif value == "crzcg" then
	if string.len(fmsO["scratchpad"]) > 0 and not string.find(fmsO["scratchpad"], " ") then
		setFMSData(value, fmsO["scratchpad"])
	end
	if string.len(fmsModules["data"].crzcg) > 0 then
		crzcg_lineLg = string.format("%4.1f%%", tonumber(fmsModules["data"].crzcg))
	end
  elseif value == "stepsize" then
	if fmsO["scratchpad"] == "ICAO" then
		setFMSData(value, fmsO["scratchpad"])
	elseif tonumber(fmsO["scratchpad"]) == nil then
		fmsO["notify"] = "INVALID ENTRY"
	elseif tonumber(fmsO["scratchpad"]) < 0 or tonumber(fmsO["scratchpad"]) > 9000 or math.fmod(tonumber(fmsO["scratchpad"]), 1000) > 0 then  --ensure increments of 1000
		fmsO["notify"] = "INVALID ENTRY"
	else
		setFMSData(value, fmsO["scratchpad"])
	end
  elseif value == "cg_mac" then
	if string.match(fmsO["scratchpad"], "%a") or string.match(fmsO["scratchpad"], "%s") or fmsModules["data"].cg_mac == "--" then
		fmsO["notify"] = "INVALID ENTRY"
		return
	elseif string.len(fmsO["scratchpad"]) > 0 then 
		calc_stab_trim(fmsModules["data"].grwt, fmsO["scratchpad"])
		setFMSData(value, fmsO["scratchpad"])
	else
		calc_stab_trim(fmsModules["data"].grwt, fmsModules["data"].cg_mac)
	end
	
	cg_lineLg = string.format("%2.0f%%", tonumber(fmsModules["data"].cg_mac))
--Marauder28
--PAX / CARGO page
  elseif value == "paxFirstClassA" then
	if string.match(fmsO["scratchpad"], "%d") and math.abs(tonumber(fmsO["scratchpad"])) <= 23 then
		setFMSData(value, math.abs(string.format("%2d", fmsO["scratchpad"])))
		calc_pax_cargo()
	elseif fmsO["scratchpad"] == "F" then  --Add FULL PAX
		setFMSData("paxFirstClassA", "23")
		setFMSData("paxBusClassB", "80")
		setFMSData("paxEconClassC", "77")
		setFMSData("paxEconClassD", "104")
		setFMSData("paxEconClassE", "132")
		setFMSData("freightZoneA", "")
		setFMSData("freightZoneB", "")
		setFMSData("freightZoneC", "")
		setFMSData("freightZoneD", "")
		setFMSData("freightZoneE", "")
		calc_pax_cargo()
	elseif fmsO["scratchpad"] == "C" then  --Clear PAX / CARGO entries
		setFMSData("paxFirstClassA", "")
		setFMSData("paxBusClassB", "")
		setFMSData("paxEconClassC", "")
		setFMSData("paxEconClassD", "")
		setFMSData("paxEconClassE", "")
		setFMSData("cargoFwd", "")
		setFMSData("cargoAft", "")
		setFMSData("cargoBulk", "")
		setFMSData("freightZoneA", "")
		setFMSData("freightZoneB", "")
		setFMSData("freightZoneC", "")
		setFMSData("freightZoneD", "")
		setFMSData("freightZoneE", "")
		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData(value, "23")
		calc_pax_cargo()
	elseif string.match(fmsO["scratchpad"], "%d") and tonumber(fmsO["scratchpad"]) > 23 then  --Add set number of PAX by round-robin through all zones
		setFMSData("paxFirstClassA", "")
		setFMSData("paxBusClassB", "")
		setFMSData("paxEconClassC", "")
		setFMSData("paxEconClassD", "")
		setFMSData("paxEconClassE", "")

		local x = tonumber(fmsO["scratchpad"])
		local paxA = 0
		local paxB = 0
		local paxC = 0
		local paxD = 0
		local paxE = 0
		
		if x > 416 then
			x = 416
		end
		repeat
			if x > 0 and paxA < 23 then
				paxA = paxA + 1
				x = x - 1
			end
			if x > 0 and paxB < 80 then
				paxB = paxB + 1
				x = x - 1
			end
			if x > 0 and paxC < 77 then
				paxC = paxC + 1
				x = x - 1
			end
			if x > 0 and paxD < 104 then
				paxD = paxD + 1
				x = x - 1
			end
			if x > 0 and paxE < 132 then
				paxE = paxE + 1
				x = x - 1
			end
		until (x == 0)
		
		fmsModules["data"].paxFirstClassA = string.format("%2d", paxA)
		fmsModules["data"].paxBusClassB = string.format("%2d", paxB)
		fmsModules["data"].paxEconClassC = string.format("%2d", paxC)
		fmsModules["data"].paxEconClassD = string.format("%3d", paxD)
		fmsModules["data"].paxEconClassE = string.format("%3d", paxE)
		
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "paxBusClassB" then
	if string.match(fmsO["scratchpad"], "%d") then
		local pax = math.abs(tonumber(fmsO["scratchpad"]))
		if pax > 80 then
			pax = 80
		end
		setFMSData(value, string.format("%2d", pax))
		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData(value, "80")
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "paxEconClassC" then
	if string.match(fmsO["scratchpad"], "%d") then
		local pax = math.abs(tonumber(fmsO["scratchpad"]))
		if pax > 77 then
			pax = 77
		end
		setFMSData(value, string.format("%2d", pax))
		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData(value, "77")
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "paxEconClassD" then
	if string.match(fmsO["scratchpad"], "%d") then
		local pax = math.abs(tonumber(fmsO["scratchpad"]))
		if pax > 104 then
			pax = 104
		end
		setFMSData(value, string.format("%3d", pax))
		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData(value, "104")
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "paxEconClassE" then
	if string.match(fmsO["scratchpad"], "%d") then
		local pax = math.abs(tonumber(fmsO["scratchpad"]))
		if pax > 132 then
			pax = 132
		end
		setFMSData(value, string.format("%3d", pax))
		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData(value, "132")
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "paxPayload" then
	if string.match(fmsO["scratchpad"], "%d") then
		local weight_factor = 1

		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		else
			weight_factor = 1
		end

		local pax_weight = math.abs(tonumber(fmsO["scratchpad"])) * 1000
		local pax = 0
		local paxA = 0
		local paxB = 0
		local paxC = 0
		local paxD = 0
		local paxE = 0
	
		pax = math.ceil(pax_weight / (simConfigData["data"].SIM.std_pax_weight * weight_factor))
		if pax > 416 then
			pax = 416
		end

		setFMSData("paxFirstClassA", "")
		setFMSData("paxBusClassB", "")
		setFMSData("paxEconClassC", "")
		setFMSData("paxEconClassD", "")
		setFMSData("paxEconClassE", "")
		setFMSData("freightZoneA", "")
		setFMSData("freightZoneB", "")
		setFMSData("freightZoneC", "")
		setFMSData("freightZoneD", "")
		setFMSData("freightZoneE", "")

		repeat
			if pax > 0 and paxA < 23 then
				paxA = paxA + 1
				pax = pax - 1
			end
			if pax > 0 and paxB < 80 then
				paxB = paxB + 1
				pax = pax - 1
			end
			if pax > 0 and paxC < 77 then
				paxC = paxC + 1
				pax = pax - 1
			end
			if pax > 0 and paxD < 104 then
				paxD = paxD + 1
				pax = pax - 1
			end
			if pax > 0 and paxE < 132 then
				paxE = paxE + 1
				pax = pax - 1
			end
		until (pax == 0)
		
		fmsModules["data"].paxFirstClassA = string.format("%2d", paxA)
		fmsModules["data"].paxBusClassB = string.format("%2d", paxB)
		fmsModules["data"].paxEconClassC = string.format("%2d", paxC)
		fmsModules["data"].paxEconClassD = string.format("%3d", paxD)
		fmsModules["data"].paxEconClassE = string.format("%3d", paxE)

		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData("paxFirstClassA", "0")
		setFMSData("paxBusClassB", "0")
		setFMSData("paxEconClassC", "0")
		setFMSData("paxEconClassD", "0")
		setFMSData("paxEconClassE", "0")
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "cargoFwd" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and (string.match(fmsO["scratchpad"], "P") or string.match(fmsO["scratchpad"], "C")) then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0

		if chars == "P" then
			weight_per_unit = 5035 * weight_factor
			if digits > 5 then
				digits = 5
			end
		elseif chars == "C" then
			weight_per_unit = 1588 * weight_factor
			if digits > 16 then
				digits = 16
			end
		end
		
		fmsO["scratchpad"] = string.format("%6d", digits * weight_per_unit)
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local cwt = 0

		cwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS
		
		if cwt > 26490 then
			cwt = 26490
		end
		
		setFMSData(value, string.format("%6d", cwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "cargoAft" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and (string.match(fmsO["scratchpad"], "P") or string.match(fmsO["scratchpad"], "C")) then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0
		
		if chars == "P" then
			weight_per_unit = 5035 * weight_factor
			if digits > 4 then
				digits = 4
			end
		elseif chars == "C" then
			weight_per_unit = 1588 * weight_factor
			if digits > 14 then
				digits = 14
			end
		end
		
		fmsO["scratchpad"] = string.format("%6d", digits * weight_per_unit)
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local cwt = 0

		cwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS

		if cwt > 22938 then
			cwt = 22938
		end

		setFMSData(value, string.format("%6d", cwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "cargoBulk" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local cwt = 0

		cwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS

		if cwt > 6749 then
			cwt = 6749
		end

		setFMSData(value, string.format("%5d", cwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
--FREIGHT Page
  elseif value == "freightZoneA" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") and math.abs(tonumber(fmsO["scratchpad"])) <= (11160 * weight_factor) then
		setFMSData(value, math.abs(string.format("%5d", fmsO["scratchpad"])) / weight_factor)
		calc_pax_cargo()
	elseif fmsO["scratchpad"] == "F" then  --Add FULL FREIGHT
		setFMSData("freightZoneA", "11289")
		setFMSData("freightZoneB", "30104")
		setFMSData("freightZoneC", "22578")
		setFMSData("freightZoneD", "45156")
		setFMSData("freightZoneE", "3763")
		setFMSData("paxFirstClassA", "")
		setFMSData("paxBusClassB", "")
		setFMSData("paxEconClassC", "")
		setFMSData("paxEconClassD", "")
		setFMSData("paxEconClassE", "")
		calc_pax_cargo()
	elseif fmsO["scratchpad"] == "C" then  --Clear FREIGHT entries
		setFMSData("freightZoneA", "")
		setFMSData("freightZoneB", "")
		setFMSData("freightZoneC", "")
		setFMSData("freightZoneD", "")
		setFMSData("freightZoneE", "")
		setFMSData("cargoFwd", "")
		setFMSData("cargoAft", "")
		setFMSData("cargoBulk", "")
		setFMSData("paxFirstClassA", "")
		setFMSData("paxBusClassB", "")
		setFMSData("paxEconClassC", "")
		setFMSData("paxEconClassD", "")
		setFMSData("paxEconClassE", "")
		calc_pax_cargo()
	elseif string.len(fmsO["scratchpad"]) < 1 then
		setFMSData(value, "11160")
		calc_pax_cargo()
	elseif string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") and tonumber(fmsO["scratchpad"]) > (11289 * weight_factor) then  --Add FREIGHT by round-robin through all zones
		setFMSData("freightZoneA", "")
		setFMSData("freightZoneB", "")
		setFMSData("freightZoneC", "")
		setFMSData("freightZoneD", "")
		setFMSData("freightZoneE", "")

		local x = tonumber(string.format("%6d", fmsO["scratchpad"] / weight_factor)) --convert to base units of KGS
		local zoneA = 0
		local zoneB = 0
		local zoneC = 0
		local zoneD = 0
		local zoneE = 0
		
		if x > 112890 then  --112,900 KGS is the MAX Revenue Payload.  112,890 KGS is the defined average pallet weight (3763) * 30 pallets
			x = 112890
		end
		repeat
			if x > 0 and zoneA < 11289 then
				zoneA = zoneA + 1
				x = x - 1
			end
			if x > 0 and zoneB < 30104 then
				zoneB = zoneB + 1
				x = x - 1
			end
			if x > 0 and zoneC < 22578 then
				zoneC = zoneC + 1
				x = x - 1
			end
			if x > 0 and zoneD < 45156 then
				zoneD = zoneD + 1
				x = x - 1
			end
			if x > 0 and zoneE < 3763 then
				zoneE = zoneE + 1
				x = x - 1
			end
			--print("X = "..x.." ZoneA = "..zoneA.." ZoneB = "..zoneB.." ZoneC = "..zoneC.." ZoneD = "..zoneD.." ZoneE = "..zoneE)
		until (x == 0)
		
		fmsModules["data"].freightZoneA = string.format("%5d", zoneA)
		fmsModules["data"].freightZoneB = string.format("%5d", zoneB)
		fmsModules["data"].freightZoneC = string.format("%5d", zoneC)
		fmsModules["data"].freightZoneD = string.format("%5d", zoneD)
		fmsModules["data"].freightZoneE = string.format("%4d", zoneE)
		
		fmsO["scratchpad"] = ""
		
		calc_pax_cargo()
	elseif string.match(fmsO["scratchpad"], "%d") and string.match(fmsO["scratchpad"], "P") then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0

		if chars == "P" then
			weight_per_unit = 3763 * weight_factor
			if digits > 3 then
				digits = 3
			end
		end
		
		fmsO["scratchpad"] = string.format("%5d", digits * weight_per_unit)
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local fwt = 0

		fwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS
		
		if fwt > 11289 then
			fwt = 11289
		end
		
		setFMSData(value, string.format("%5d", fwt))
		calc_pax_cargo()
	end
  elseif value == "freightZoneB" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and string.match(fmsO["scratchpad"], "P") then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0

		if chars == "P" then
			weight_per_unit = 3763 * weight_factor
			if digits > 8 then
				digits = 8
			end
		end
		
		fmsO["scratchpad"] = string.format("%5d", digits * weight_per_unit)
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local fwt = 0

		fwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS
		
		if fwt > 30104 then
			fwt = 30104
		end
		
		setFMSData(value, string.format("%5d", fwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "freightZoneC" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and string.match(fmsO["scratchpad"], "P") then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0

		if chars == "P" then
			weight_per_unit = 3763 * weight_factor
			if digits > 6 then
				digits = 6
			end
		end
		
		fmsO["scratchpad"] = string.format("%5d", digits * weight_per_unit)
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local fwt = 0

		fwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS
		
		if fwt > 22578 then
			fwt = 22578
		end
		
		setFMSData(value, string.format("%5d", fwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "freightZoneD" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and string.match(fmsO["scratchpad"], "P") then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0

		if chars == "P" then
			weight_per_unit = 3763 * weight_factor
			if digits > 12 then
				digits = 12
			end
		end
		
		fmsO["scratchpad"] = string.format("%6d", digits * weight_per_unit)
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local fwt = 0

		fwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS
		
		if fwt > 45156 then
			fwt = 45156
		end
		
		setFMSData(value, string.format("%6d", fwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
  elseif value == "freightZoneE" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and string.match(fmsO["scratchpad"], "P") then
		local digits = math.abs(tonumber(string.match(fmsO["scratchpad"], "%d+")))
		local chars = string.match(fmsO["scratchpad"], "%u")
		local weight_per_unit = 0

		if chars == "P" then
			weight_per_unit = 3763 * weight_factor
			if digits > 1 then
				digits = 1
			end
		end
		
		fmsO["scratchpad"] = string.format("%4d", digits * weight_per_unit)
	end
	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") then
		local fwt = 0

		fwt = math.abs(tonumber(fmsO["scratchpad"])) / weight_factor  --store LBS in KGS
		
		if fwt > 3763 then
			fwt = 3763
		end
		
		setFMSData(value, string.format("%4d", fwt))
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
   elseif value == "freightPayload" then
	if string.match(fmsO["scratchpad"], "%d") then --and not string.match(fmsO["scratchpad"], "%u") then
		local weight_factor = 1

		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		else
			weight_factor = 1
		end

		setFMSData("paxFirstClassA", "")
		setFMSData("paxBusClassB", "")
		setFMSData("paxEconClassC", "")
		setFMSData("paxEconClassD", "")
		setFMSData("paxEconClassE", "")
		setFMSData("freightZoneA", "")
		setFMSData("freightZoneB", "")
		setFMSData("freightZoneC", "")
		setFMSData("freightZoneD", "")
		setFMSData("freightZoneE", "")

		local x = math.abs(tonumber(fmsO["scratchpad"]) / weight_factor) * 1000  --convert to base units of KGS
		local zoneA = 0
		local zoneB = 0
		local zoneC = 0
		local zoneD = 0
		local zoneE = 0
		
		if x > 112890 then  --112,900 KGS is the MAX Revenue Payload.  112,890 KGS is the defined average pallet weight (3763) * 30 pallets
			x = 112890
		end
		
		repeat
			if x > 0 and zoneA < 11289 then
				zoneA = zoneA + 1
				x = x - 1
			end
			if x > 0 and zoneB < 30104 then
				zoneB = zoneB + 1
				x = x - 1
			end
			if x > 0 and zoneC < 22578 then
				zoneC = zoneC + 1
				x = x - 1
			end
			if x > 0 and zoneD < 45156 then
				zoneD = zoneD + 1
				x = x - 1
			end
			if x > 0 and zoneE < 3763 then
				zoneE = zoneE + 1
				x = x - 1
			end
			--print("X = "..x.." ZoneA = "..zoneA.." ZoneB = "..zoneB.." ZoneC = "..zoneC.." ZoneD = "..zoneD.." ZoneE = "..zoneE)
		until (x <= 0)
		
		fmsModules["data"].freightZoneA = string.format("%5d", zoneA)
		fmsModules["data"].freightZoneB = string.format("%5d", zoneB)
		fmsModules["data"].freightZoneC = string.format("%5d", zoneC)
		fmsModules["data"].freightZoneD = string.format("%5d", zoneD)
		fmsModules["data"].freightZoneE = string.format("%4d", zoneE)
		
		fmsO["scratchpad"] = ""
		
		calc_pax_cargo()
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
--Marauder28
--SimConfig Page
   elseif value=="weightUnits" then
	if string.len(fmsO["scratchpad"])>0 and validate_weight_units(fmsO["scratchpad"]) == false then 
      fmsO["notify"]="INVALID ENTRY"
	elseif is_timer_scheduled(preselect_fuel) == true then
	  fmsO["notify"]="NA - WAITING FOR FUEL TRUCK"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.weight_display_units = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.weight_display_units == "KGS" then
			fmsO["scratchpad"] = "LBS"
		else
			fmsO["scratchpad"] = "KGS"
		end
		simConfigData["data"].SIM.weight_display_units = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
  elseif value == "irsAlignTime" then
	if not string.match(fmsO["scratchpad"], "%d") or string.len(fmsO["scratchpad"]) > 2 then
		fmsO["notify"] = "INVALID ENTRY"
	else
		--setFMSData(value, tonumber(fmsO["scratchpad"]) * 60)
		simConfigData["data"].SIM.irs_align_time = tonumber(fmsO["scratchpad"]) * 60
		pushSimConfig(simConfigData["data"]["values"])
		--print("FMC IRS = "..fmsO["scratchpad"] * 60)
	end
   elseif value=="autoFuelMgmt" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "YES" or fmsO["scratchpad"] == "NO") then 
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.auto_fuel_mgmt = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.auto_fuel_mgmt == "NO" then
			fmsO["scratchpad"] = "YES"
		else
			fmsO["scratchpad"] = "NO"
		end
		simConfigData["data"].SIM.auto_fuel_mgmt = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="baroIndicator" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "IN" or fmsO["scratchpad"] == "HPA") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.baro_indicator = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.baro_indicator == "IN" then
			fmsO["scratchpad"] = "HPA"
		else
			fmsO["scratchpad"] = "IN"
		end
		simConfigData["data"].SIM.baro_indicator = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="baroSync" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "YES" or fmsO["scratchpad"] == "NO") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.baro_sync = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.baro_sync == "NO" then
			fmsO["scratchpad"] = "YES"
		else
			fmsO["scratchpad"] = "NO"
		end
		simConfigData["data"].SIM.baro_sync = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
  elseif value == "stdPaxWeight" then
	local weight_factor = 1

	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].SIM.kgs_to_lbs
	else
		weight_factor = 1
	end

	if string.match(fmsO["scratchpad"], "%d") and not string.match(fmsO["scratchpad"], "%u") and tonumber(fmsO["scratchpad"]) < 500.0 then
		local pax_weight = 0

		pax_weight = string.format("%5.1f", math.abs(tonumber(fmsO["scratchpad"]) / weight_factor))  --store weight in KGS

		simConfigData["data"].SIM.std_pax_weight = pax_weight
		pushSimConfig(simConfigData["data"]["values"])		
	else
		fmsO["notify"] = "INVALID ENTRY"
	end
   elseif value=="captInbd" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "EICAS" or fmsO["scratchpad"] == "NORM" or fmsO["scratchpad"] == "PFD") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.capt_inbd = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.capt_inbd == "EICAS" then
			fmsO["scratchpad"] = "NORM"
		elseif simConfigData["data"].SIM.capt_inbd == "NORM" then
			fmsO["scratchpad"] = "PFD"
		else
			fmsO["scratchpad"] = "EICAS"
		end
		simConfigData["data"].SIM.capt_inbd = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="captLwr" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "EICAS PRI" or fmsO["scratchpad"] == "NORM" or fmsO["scratchpad"] == "ND") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.capt_inbd = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.capt_lwr == "EICAS PRI" then
			fmsO["scratchpad"] = "NORM"
		elseif simConfigData["data"].SIM.capt_lwr == "NORM" then
			fmsO["scratchpad"] = "ND"
		else
			fmsO["scratchpad"] = "EICAS PRI"
		end
		simConfigData["data"].SIM.capt_lwr = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="foInbd" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "PFD" or fmsO["scratchpad"] == "NORM" or fmsO["scratchpad"] == "EICAS") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.fo_inbd = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.fo_inbd == "PFD" then
			fmsO["scratchpad"] = "NORM"
		elseif simConfigData["data"].SIM.fo_inbd == "NORM" then
			fmsO["scratchpad"] = "EICAS"
		else
			fmsO["scratchpad"] = "PFD"
		end
		simConfigData["data"].SIM.fo_inbd = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="foLwr" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "ND" or fmsO["scratchpad"] == "NORM" or fmsO["scratchpad"] == "EICAS PRI") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].SIM.fo_inbd = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].SIM.fo_lwr == "ND" then
			fmsO["scratchpad"] = "NORM"
		elseif simConfigData["data"].SIM.fo_lwr == "NORM" then
			fmsO["scratchpad"] = "EICAS PRI"
		else
			fmsO["scratchpad"] = "ND"
		end
		simConfigData["data"].SIM.fo_lwr = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
	
--silvereagle added to end
    elseif value=="spillLights" then
		if B747DR_fmc_spill_lights == 0 then
			fmsO["scratchpad"] = "HI"
			B747DR_fmc_spill_lights = 1
		else	
			fmsO["scratchpad"] = "NORM"
			B747DR_fmc_spill_lights = 0
		end
		simConfigData["data"].SIM.spill_lights = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])

    elseif value=="cockpitSeatsHide" then
		if B747DR_fmc_cockpit_seats_hide == 0 then
			fmsO["scratchpad"] = "HIDE"
			B747DR_fmc_cockpit_seats_hide = 1
		else	
			fmsO["scratchpad"] = "SHOW"
			B747DR_fmc_cockpit_seats_hide = 0
		end
		simConfigData["data"].SIM.cockpit_seats_hide = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
--silvereagle end
	elseif value=="setacarsprovider" then
		if B747DR_acarsProvider == 0 then
			fmsO["scratchpad"] = "HOPPIE"
			B747DR_acarsProvider = 1
		else	
			fmsO["scratchpad"] = "AUTOATC"
			B747DR_acarsProvider = 0
		end
		simConfigData["data"].SIM.acarsProvider = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])	
	elseif value=="simConfigSave" then
			local file_location = simDR_livery_path.."B747-400_simconfig.dat"
			--print("File = "..file_location)
			local file = io.open(file_location, "w")

			if file ~= nil then
				io.output(file)
				io.write(B747DR_simconfig_data)
				io.close(file)
			end
--Plane Config Page
	elseif value=="model" then
		simConfigData["data"].PLANE.model = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
   elseif value=="aircraftType" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "PASSENGER" or fmsO["scratchpad"] == "FREIGHTER") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].PLANE.aircraft_type = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].PLANE.aircraft_type == "PASSENGER" then
			fmsO["scratchpad"] = "FREIGHTER"
		else
			fmsO["scratchpad"] = "PASSENGER"
		end
		simConfigData["data"].PLANE.aircraft_type = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="engines" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "CF6-80C2-B1F" or fmsO["scratchpad"] == "CF6-80C2-B5F" or fmsO["scratchpad"] == "CF6-80C2-B1F1"
		or fmsO["scratchpad"] == "PW4056" or fmsO["scratchpad"] == "PW4060" or fmsO["scratchpad"] == "PW4062"
		or fmsO["scratchpad"] == "RB211-524G" or fmsO["scratchpad"] == "RB211-524H") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].PLANE.engines = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].PLANE.engines == "CF6-80C2-B1F" then
			fmsO["scratchpad"] = "CF6-80C2-B5F"
			simConfigData["data"].PLANE.thrust_ref = "N1"
		elseif simConfigData["data"].PLANE.engines == "CF6-80C2-B5F" then
			fmsO["scratchpad"] = "CF6-80C2-B1F1"
			simConfigData["data"].PLANE.thrust_ref = "N1"
		elseif simConfigData["data"].PLANE.engines == "CF6-80C2-B1F1" then
			fmsO["scratchpad"] = "PW4056"
			simConfigData["data"].PLANE.thrust_ref = "EPR"
		elseif simConfigData["data"].PLANE.engines == "PW4056" then
			fmsO["scratchpad"] = "PW4060"
			simConfigData["data"].PLANE.thrust_ref = "EPR"
		elseif simConfigData["data"].PLANE.engines == "PW4060" then
			fmsO["scratchpad"] = "PW4062"
			simConfigData["data"].PLANE.thrust_ref = "EPR"
		elseif simConfigData["data"].PLANE.engines == "PW4062" then
			fmsO["scratchpad"] = "RB211-524G"
			simConfigData["data"].PLANE.thrust_ref = "EPR"
		elseif simConfigData["data"].PLANE.engines == "RB211-524G" then
			fmsO["scratchpad"] = "RB211-524H"
			simConfigData["data"].PLANE.thrust_ref = "EPR"
		elseif simConfigData["data"].PLANE.engines == "RB211-524H" then
			fmsO["scratchpad"] = "RB211-524H8T"
			simConfigData["data"].PLANE.thrust_ref = "EPR"
		else
			fmsO["scratchpad"] = "CF6-80C2-B1F"
			simConfigData["data"].PLANE.thrust_ref = "N1"
		end
		simConfigData["data"].PLANE.engines = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   --Removed to allow engine code above to forcibly set the thrust_ref mode (i.e. don't let users select and mess things up)
--[[   elseif value=="thrustRef" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "EPR" or fmsO["scratchpad"] == "N1") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].PLANE.thrust_ref = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].PLANE.thrust_ref == "EPR" then
			fmsO["scratchpad"] = "N1"
		else
			fmsO["scratchpad"] = "EPR"
		end
		simConfigData["data"].PLANE.thrust_ref = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end]]
   elseif value=="airline" then
		simConfigData["data"].PLANE.airline = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
   elseif value=="civilRegistration" then
		simConfigData["data"].PLANE.civil_registration = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
   elseif value=="finNbr" then
		simConfigData["data"].PLANE.fin_nbr = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
   elseif value=="pfdStyle" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "CRT" or fmsO["scratchpad"] == "LCD") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].PLANE.pfd_style = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].PLANE.pfd_style == "CRT" then
			fmsO["scratchpad"] = "LCD"
		else
			fmsO["scratchpad"] = "CRT"
		end
		simConfigData["data"].PLANE.pfd_style = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
   elseif value=="ndStyle" then
	if string.len(fmsO["scratchpad"])>0 and not (fmsO["scratchpad"] == "LCD" or fmsO["scratchpad"] == "CRT") then
      fmsO["notify"]="INVALID ENTRY"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].PLANE.nd_style = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
    else
		if simConfigData["data"].PLANE.nd_style == "CRT" then
			fmsO["scratchpad"] = "LCD"
		else
			fmsO["scratchpad"] = "CRT"
		end
		simConfigData["data"].PLANE.nd_style = fmsO.scratchpad
		pushSimConfig(simConfigData["data"]["values"])
	end
--Marauder28
   elseif value=="atc" then
		--setFMSData(value,fmsO["scratchpad"])
		
		fmsFunctions["acarsLogonATC"](fmsO,fmsO["scratchpad"])
	elseif value=="fltdepatc" then
		--setFMSData("atc",fmsModules.data["fltdep"])
		
		fmsFunctions["acarsLogonATC"](fmsO,fmsModules.data["fltdep"])
	elseif value=="fltdstatc" then
		--setFMSData("atc",fmsModules.data["fltdst"])
		
		fmsFunctions["acarsLogonATC"](fmsO,fmsModules.data["fltdst"])	
	elseif value=="acarsEMERSOB" and string.len(fmsO["scratchpad"]) > 0 then
		tVal=tonumber(fmsO["scratchpad"])
		if tVal==nil or tVal<1 or tVal>450 then
			fmsO["notify"]="INVALID ENTRY"
		else
			setFMSData("acarsEMERSOB",fmsO["scratchpad"])
		end
	elseif value=="metarreq" then
		if acarsSystem.provider.loggedOn()~="ACCEPTED" then fmsO["notify"]="RE-LOGON TO ATC COMM" return end
		fmsFunctions["acarsATCRequest"](fmsO,"REQUEST METAR") --request metar	
		fmsFunctions["setpage_no"](fmsO,"VIEWUPACARS_1") --then go to the message page
	elseif value=="sendarmedacarsnr" then
		if not(fmsFunctions.acarsDataReady(fmsO)) then return end	
		if fmsModules["data"]["atc"]=="****" then fmsO["notify"]="NO LOGON" return end	
		local ln=getFMSData("acarsMessage")
		fmsFunctions["acarsSendATCMessage"](fmsO,ln,"N") --send message
		setFMSData("acarsMessage","")
		fmsFunctions["setpage_no"](fmsO,"VIEWDOWNACARS_1") --then go to the sent message page	
	elseif value=="sendarmedacarsrr" then
		if not(fmsFunctions.acarsDataReady(fmsO)) then return end	
		if fmsModules["data"]["atc"]=="****" then fmsO["notify"]="NO LOGON" return end
		local ln=getFMSData("acarsMessage")
		fmsFunctions["acarsSendATCMessage"](fmsO,ln,"Y") --send message
		setFMSData("acarsMessage","")
		fmsFunctions["setpage_no"](fmsO,"VIEWDOWNACARS_1") --then go to the sent message page
	elseif value=="tafreq" then	
		if acarsSystem.provider.loggedOn()~="ACCEPTED" then fmsO["notify"]="RE-LOGON TO ATC COMM" return end
		fmsFunctions["acarsATCRequest"](fmsO,"REQUEST TAF")	--request metar
		fmsFunctions["setpage_no"](fmsO,"VIEWUPACARS_1") --then go to the message page
   elseif fmsO["scratchpad"]=="" and del==false then
      cVal=getFMSData(value)
    
      fmsO["scratchpad"]=cVal
    return 
  else
    setFMSData(value,fmsO["scratchpad"])
  end
  fmsO["scratchpad"]=""
end

function fmsFunctions.setDref(fmsO,value)
   local val=tonumber(fmsO["scratchpad"])
  if value=="VNAVS1" and B747DR_ap_vnav_system ~=1.0 then B747DR_ap_vnav_system=1 return elseif value=="VNAVS1" then B747DR_ap_vnav_system=0 return end 
  if value=="VNAVS2" and B747DR_ap_vnav_system ~=2.0 then B747DR_ap_vnav_system=2 return elseif value=="VNAVS2" then B747DR_ap_vnav_system=0 return end 
  if value=="VNAVSPAUSE" then 
	if B747DR_ap_vnav_pause>0 then 
		B747DR_ap_vnav_pause=0
	else
		B747DR_ap_vnav_pause=1 
	end 
	return 
	end 
  if value=="CHOCKS" then
	B747DR__gear_chocked = 1 - B747DR__gear_chocked
	--Stop refueling operation if CHOCKS are removed
	if B747DR__gear_chocked == 0 then
		B747DR_refuel=0.0
	end
	return
  end
  if value=="PAUSEVAL" then
	local numVal=tonumber(fmsO["scratchpad"])
	fmsO["scratchpad"]="" 
	if numVal==nil then fmsO["notify"]="INVALID ENTRY" return end
	if numVal>999 then numVal=999 end
	if numVal<=1 then numVal=1 end
	B747DR_ap_vnav_pause=numVal
	return 
  end


 	
  if value=="TO" then toderate=0 clbderate=0 return  end
  if value=="TO1" then toderate=1 clbderate=1 return  end
  if value=="TO2" then toderate=2 clbderate=2 return  end
  if value=="CLB" then clbderate=0 return  end
  if value=="CLB1" then clbderate=1 return  end
  if value=="CLB2" then clbderate=2  return end
  if value=="ILS" then 
    if findILS(fmsO["scratchpad"])==false then fmsO["notify"]="INVALID ENTRY" end
    fmsO["scratchpad"]="" 
    return 
  end
  local modes=B747DR_radioModes
  if value=="VORL" and val==nil then B747DR_radioModes=replace_char(2,modes,"A") fmsO["scratchpad"]="" return end
  if value=="VORR" and val==nil then B747DR_radioModes=replace_char(3,modes,"A") fmsO["scratchpad"]="" return end
   if val==nil or (value=="CRSL" and modes:sub(2, 2)=="A") or (value=="CRSR" and modes:sub(3, 3)=="A") then
     fmsO["notify"]="INVALID ENTRY"
     return 
   end
 --print(val)
  if value=="VORL" then B747DR_radioModes=replace_char(2,modes,"M") simDR_radio_nav_freq_hz[2]=val*100  end
  if value=="VORR" then B747DR_radioModes=replace_char(3,modes,"M") simDR_radio_nav_freq_hz[3]=val*100  end
  if value=="CRSL" then simDR_radio_nav_obs_deg[2]=val end
  if value=="CRSR" then simDR_radio_nav_obs_deg[3]=val end
  if value=="ADFL" then simDR_radio_adf1_freq_hz=val end
  if value=="ADFR" then simDR_radio_adf2_freq_hz=val end
  if value=="V1" then
	if val<100 or val>200 then
		fmsO["notify"]="INVALID ENTRY"
     	return 
	end
	B747DR_airspeed_V1=val 
  end
  if value=="VR" then
	if val<100 or val>200 then
		fmsO["notify"]="INVALID ENTRY"
     	return 
	end
	
	B747DR_airspeed_Vr=val 
  end
  if value=="V2" then
	if val<100 or val>200 then
		fmsO["notify"]="INVALID ENTRY"
     	return 
	end
	B747DR_airspeed_V2=val 
  end
  if value=="flapsRef" then 
	if val~=10 and val~=20 then
		fmsO["notify"]="INVALID ENTRY"
     	return 
	end
	B747DR_airspeed_flapsRef=val 
  end

  fmsO["scratchpad"]=""
end
function fmsFunctions.setscratchpad(fmsO,value)
	fmsO["scratchpad"]=value
end
function fmsFunctions.respondmessage(fmsO,value)
	acarsSystem.setCurrentMessage(fmsO.id,value)
	fmsO["inCustomFMC"]=true
	fmsO["targetPage"]="RESPONDACARSMSG"
	run_after_time(switchCustomMode, 0.5)
  end

function fmsFunctions.sendACARSmessage(fmsO,value)
	print("send "..value)
	acarsSystem.setCurrentMessage(fmsO.id,value)
	print("setCurrentMessage "..value)
	fmsFunctions["acarsRespondATC"](fmsO,value)
	print("acarsRespondATC "..value)
	fmsO["inCustomFMC"]=true
  	fmsO["targetPage"]="VIEWACARSLOG"
  	run_after_time(switchCustomMode, 0.5)
end
function fmsFunctions.showmessage(fmsO,value)
  acarsSystem.setCurrentMessage(fmsO.id,value)
  fmsO["inCustomFMC"]=true
  fmsO["targetPage"]="VIEWACARSMSG"
  run_after_time(switchCustomMode, 0.5)
end

function fmsFunctions.doCMD(fmsO,value)
  print("do fmc command "..value)
  if fmsModules["cmds"][value] ~= nil then
	fmsModules["cmds"][value]:once()
	fmsModules["lastcmd"]=fmsModules["cmdstrings"][value]
  end
end
function fmsFunctions.setacars(fmsO,value)
	setFMSData("acarsMessage",value)
	fmsO["inCustomFMC"]=true
  	fmsO["targetPage"]="ATCVERIFYWCEREQUEST"
  	run_after_time(switchCustomMode, 0.5)
end
function fmsFunctions.clearreq(fmsO,value)
	setFMSData("acarsREQALT","")
	setFMSData("acarsREQSPEED","")
	setFMSData("acarsREQOFFSET","")
	setFMSData("acarsREQHDG","")
	setFMSData("acarsREQTRK","")
	setFMSData("acarsREQAT","")
	setFMSData("acarsREQTO","")
	setFMSData("acarsREQDUE","")
	setFMSData("acarsMessage","")
end
function fmsFunctions.setmayday(fmsO,value)
	setFMSData("acarsEMERMSG",value)
	fmsO["inCustomFMC"]=true
  	fmsO["targetPage"]="ATCVERIFYEMERGENCY"
  	run_after_time(switchCustomMode, 0.5)
end
function fmsFunctions.clearemergency(fmsO,value)
	setFMSData("acarsEMEROFFSET","")
	setFMSData("acarsEMERMSG","")
	setFMSData("acarsEMERDESC","")
	setFMSData("acarsMessage","")
end
function fmsFunctions.clearwce(fmsO,value)
	setFMSData("acarsWCWCRZCLB","")
	setFMSData("acarsWCWCLB","")
	setFMSData("acarsWCWDES","")
	setFMSData("acarsWCWSPEED","")
	setFMSData("acarsMessage","")
end	
function fmsFunctions.clearacars(fmsO,value)
	print("do fmc clearacars")
	acarsSystem.clear()
end

function fmsFunctions.setSoundOption(fmsO,value) -- sound options (crazytimtimtim + Matt726)
	-- TODO, this would make more sense to use an array lookup of options, but copied pasted for now
	if value == "alarmsOption" then
		if B747DR_SNDoptions[0] ~= 2 then
			B747DR_SNDoptions[0] = B747DR_SNDoptions[0] + 1
		elseif B747DR_SNDoptions[0] == 2 then
			B747DR_SNDoptions[0] = 0
		end
		simConfigData["data"].SOUND.alarmsOption = B747DR_SNDoptions[0]
		pushSimConfig(simConfigData["data"]["values"])
	end

	if value == "seatBeltOption" then 
		B747DR_SNDoptions[1] = 1 - B747DR_SNDoptions[1] 
		simConfigData["data"].SOUND.seatBeltOption = B747DR_SNDoptions[1]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "paOption" then 
		B747DR_SNDoptions[2] = 1 - B747DR_SNDoptions[2] 
		simConfigData["data"].SOUND.paOption = B747DR_SNDoptions[2]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "musicOption" then 
		B747DR_SNDoptions[3] = 1 - B747DR_SNDoptions[3] 
		simConfigData["data"].SOUND.musicOption = B747DR_SNDoptions[3]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "PM_toggle" then 
		B747DR_SNDoptions[4] = 1 - B747DR_SNDoptions[4] 
		simConfigData["data"].SOUND.PM_toggle = B747DR_SNDoptions[4]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "V1Option" then 
		B747DR_SNDoptions[5] = 1 - B747DR_SNDoptions[5] 
		simConfigData["data"].SOUND.V1Option = B747DR_SNDoptions[5]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end

	if value == "GPWSminimums" then 
		B747DR_SNDoptions_gpws[1] = 1 - B747DR_SNDoptions_gpws[1] 
		simConfigData["data"].SOUND.GPWSminimums = B747DR_SNDoptions_gpws[1]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWSapproachingMinimums" then 
		B747DR_SNDoptions_gpws[2] = 1 - B747DR_SNDoptions_gpws[2] 
		simConfigData["data"].SOUND.GPWSapproachingMinimums = B747DR_SNDoptions_gpws[2]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS2500" then 
		B747DR_SNDoptions_gpws[3] = 1 - B747DR_SNDoptions_gpws[3] 
		simConfigData["data"].SOUND.GPWS2500 = B747DR_SNDoptions_gpws[3]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS1000" then 
		B747DR_SNDoptions_gpws[4] = 1 - B747DR_SNDoptions_gpws[4] 
		simConfigData["data"].SOUND.GPWS1000 = B747DR_SNDoptions_gpws[4]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS500" then 
		B747DR_SNDoptions_gpws[5] = 1 - B747DR_SNDoptions_gpws[5] 
		simConfigData["data"].SOUND.GPWS500 = B747DR_SNDoptions_gpws[5]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS400" then 
		B747DR_SNDoptions_gpws[6] = 1 - B747DR_SNDoptions_gpws[6] 
		simConfigData["data"].SOUND.GPWS400 = B747DR_SNDoptions_gpws[6]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS300" then 
		B747DR_SNDoptions_gpws[7] = 1 - B747DR_SNDoptions_gpws[7] 
		simConfigData["data"].SOUND.GPWS300 = B747DR_SNDoptions_gpws[7]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS200" then
		 B747DR_SNDoptions_gpws[8] = 1 - B747DR_SNDoptions_gpws[8] 
		 simConfigData["data"].SOUND.GPWS200 = B747DR_SNDoptions_gpws[8]
		pushSimConfig(simConfigData["data"]["values"])
		 return 
	end
	if value == "GPWS100" then 
		B747DR_SNDoptions_gpws[9] = 1 - B747DR_SNDoptions_gpws[9] 
		simConfigData["data"].SOUND.GPWS100 = B747DR_SNDoptions_gpws[9]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS50" then 
		B747DR_SNDoptions_gpws[10] = 1 - B747DR_SNDoptions_gpws[10] 
		simConfigData["data"].SOUND.GPWS50 = B747DR_SNDoptions_gpws[10]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS40" then 
		B747DR_SNDoptions_gpws[11] = 1 - B747DR_SNDoptions_gpws[11] 
		simConfigData["data"].SOUND.GPWS40 = B747DR_SNDoptions_gpws[11]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS30" then 
		B747DR_SNDoptions_gpws[12] = 1 - B747DR_SNDoptions_gpws[12] 
		simConfigData["data"].SOUND.GPWS30 = B747DR_SNDoptions_gpws[12]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS20" then 
		B747DR_SNDoptions_gpws[13] = 1 - B747DR_SNDoptions_gpws[13] 
		simConfigData["data"].SOUND.GPWS20 = B747DR_SNDoptions_gpws[13]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS10" then 
		B747DR_SNDoptions_gpws[14] = 1 - B747DR_SNDoptions_gpws[14]
		simConfigData["data"].SOUND.GPWS10 = B747DR_SNDoptions_gpws[14]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end
	if value == "GPWS5" then 
		B747DR_SNDoptions_gpws[15] = 1 - B747DR_SNDoptions_gpws[15] 
		simConfigData["data"].SOUND.GPWS5 = B747DR_SNDoptions_gpws[15]
		pushSimConfig(simConfigData["data"]["values"])
		return 
	end

end
