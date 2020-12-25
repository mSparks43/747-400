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
--Marauder28

fmsFunctions={}
dofile("acars/acars.lua")

fmsPages["INDEX"]=createPage("INDEX")
fmsPages["INDEX"].getPage=function(self,pgNo,fmsID)
  local acarsS="      "
  local gs1="                        "

  if simDR_onGround ==1 then
    gs1="                 SELECT>"

  end
  if acars==1 and B747DR_rtp_C_off==0 then acarsS="<ACARS" end
return {

"          MENU          ",
"                        ",
"<FMC             SELECT>",
"                        ",
acarsS.."           SELECT>",
"                        ",
"<SAT                    ",
"                        ",
gs1,
"                        ",
"<ACMS                   ", 
"                        ",
"<CMC                    "
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
      "                        ",
      "                        ",
      }
end
fmsFunctionsDefs["INDEX"]={}
fmsFunctionsDefs["INDEX"]["L1"]={"setpage","FMC"}
fmsFunctionsDefs["INDEX"]["L2"]={"setpage","ACARS"}
fmsFunctionsDefs["INDEX"]["L5"]={"setpage","ACMS"}
fmsFunctionsDefs["INDEX"]["L6"]={"setpage","CMC"}
fmsFunctionsDefs["INDEX"]["R4"]={"setpage","GNDHNDL"}
fmsPages["RTE1"]=createPage("RTE1")
fmsPages["RTE1"].getPage=function(self,pgNo,fmsID)
  local lastLine="<RTE 2             PERF>"
  if simDR_onGround ==1 then
    fmsFunctionsDefs["RTE1"]["L6"]=nil
    lastLine="                   PERF>"
  else
    --fmsFunctionsDefs["RTE1"]["L6"]={"setpage","RTE2"}
    fmsFunctionsDefs["RTE1"]["L6"]={"setpage","LEGS"}
  end
  local page={
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
  return page 
end
fmsFunctionsDefs["RTE1"]["L1"]={"custom2fmc","L1"}
--fmsFunctionsDefs["RTE1"]["L1"]={"setdata","origin"}
fmsFunctionsDefs["RTE1"]["L2"]={"custom2fmc","L2"}
fmsFunctionsDefs["RTE1"]["L3"]={"custom2fmc","L3"}
fmsFunctionsDefs["RTE1"]["L4"]={"custom2fmc","L4"}
fmsFunctionsDefs["RTE1"]["L5"]={"custom2fmc","L5"}

fmsFunctionsDefs["RTE1"]["R1"]={"custom2fmc","R1"}
fmsFunctionsDefs["RTE1"]["R2"]={"custom2fmc","R2"}
fmsFunctionsDefs["RTE1"]["R3"]={"custom2fmc","R3"}
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
dofile("activepages/B744.fms.pages.groundhandling.lua")
dofile("activepages/B744.fms.pages.maintsimconfig.lua")
dofile("activepages/B744.fms.pages.identpage.lua")
dofile("activepages/atc/B744.fms.pages.atcindex.lua")
dofile("activepages/atc/B744.fms.pages.atclogonstatus.lua")
dofile("activepages/atc/B744.fms.pages.atcreport.lua")
dofile("activepages/atc/B744.fms.pages.posreport.lua")
dofile("activepages/atc/B744.fms.pages.request.lua")
dofile("activepages/atc/B744.fms.pages.whencanwe.lua")
dofile("activepages/B744.fms.pages.cmc.lua")
dofile("activepages/B744.fms.pages.acms.lua")
dofile("activepages/B744.fms.pages.pax-cargo.lua")
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

function findILS(value)
  
  local modes=B747DR_radioModes
  if navAidsJSON==nil or string.len(navAidsJSON)<5 then return false end
  if value=="DELETE" then 
    B747DR_radioModes=replace_char(1,modes," ")
    ilsData=""
    return true
  end
  B747DR_radioModes=replace_char(1,modes,"M")
  navAids=json.decode(navAidsJSON)
  local direction=nil
  local valueSO=split(value,"/")
  print(value)
  if table.getn(valueSO) > 1 then
    value=valueSO[1]
     print(value)
    direction=tonumber(valueSO[2])
    print(value.." and " .. direction)
  else
    print(value)
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
	    print("68 - Tuning ILS".. ilsData)
	    if direction ~=nil then
	      bestDist=getHeadingDifferenceM(direction,navAids[n][4])
	    end
	    simDR_nav1Freq=navAids[n][3]
	    simDR_nav2Freq=navAids[n][3]
	    local course=(navAids[n][4]+simDR_variation)
	    simDR_radio_nav_obs_deg[0]=course
	    simDR_radio_nav_obs_deg[1]=course
	    print("68 - Tuned ILS "..course)
	    print("68 - useThis"..bestDist)
	  end
      end
   end
   return found
end


simDR_variation=find_dataref("sim/flightmodel/position/magnetic_variation")
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
    if (dist_to_TOD >= 50 and dist_to_TOD < 200) then
		--ils2= string.format("%6.2f/%03d%s %4s          .", ilsNav[3]*0.01,(ilsNav[4]+simDR_variation), "˚", park)
		ils1 = "            "..park
		ils_line1 = string.format("<%6.2f/%03d%s           ", ilsNav[3]*0.01,(round((ilsNav[4]+round(simDR_variation)))), "˚")
	elseif (dist_to_TOD < 50) then
		ils1= string.format("%6.2f/%03d%s          ", ilsNav[3]*0.01,(round((ilsNav[4]+round(simDR_variation)))), "`"..modes:sub(1, 1))
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
   
  else
    fmsO["targetCustomFMC"]=true
    fmsO["targetPage"]=value 
 
  end
  print("setpage " .. value)
  run_after_time(switchCustomMode, 0.25)
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
    run_after_time(switchCustomMode, 0.25)
  elseif value=="prev" then 
    fmsO["targetpgNo"]=fmsO["pgNo"]-1
    run_after_time(switchCustomMode, 0.25)
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
function updateCRZ()
  local setVal=string.sub(B747DR_srcfms[updateFrom][3],20,24)
  print("from line".. updateFrom.." "..B747DR_srcfms[updateFrom][3])
  print("to:"..setVal)
  local alt=validAlt(setVal)
  if alt~=nil then B747BR_cruiseAlt=alt end
  fmsModules:setData("crzalt",setVal)
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
  if val<2000 or val>40000 then return nil end

  return ""..val
end
function validFL(value)
  local val=tonumber(value)
  if string.len(value)>2 and string.sub(value,1,2)=="FL" then val=tonumber(string.sub(value,3)) end
  
  if val==nil then return nil end
  if val<1000 then val=val*100 end
  if val<10000 or val>40000 then return nil end

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
	print(value)
	if value == "KGS" or value == "LBS" then
		return true
	else
		return false
	end
end

-- VALIDATE ENTRY OF SETHDG
function validate_sethdg(value)
	print(value)
	if tonumber(value) >= 0 and tonumber(value) <= 360 then
		return true
	else
		return false
	end
end

function preselect_fuel()
	-- DETERMINE FUEL WEIGHT DISPLAY UNITS
	local fuel_calculation_factor = 1
	
	if simConfigData["data"].weight_display_units == "LBS" then
		fuel_calculation_factor = simConfigData["data"].kgs_to_lbs
	end
	
	B747DR_refuel=B747DR_fuel_add * 1000 / fuel_calculation_factor  --(always add fuel in KGS behind the scenes)
	B747DR_fuel_preselect=simDR_fueL_tank_weight_total_kg + B747DR_refuel
	
	-- Used in calculation for displaying Preselect Fuel Qty in correct weight units (actual display done in B747.25.xt.fuel)
	B747DR_fuel_preselect_temp = B747DR_fuel_preselect
	B747DR_fuel_add=0
	simDR_m_jettison=simDR_acf_m_jettison
end

--Marauder28
function calc_pax_cargo()
	local pax_total			= 0
	local pax_weightA		= 0
	local pax_weightB		= 0
	local pax_weightC		= 0
	local pax_weightD		= 0
	local pax_weightE		= 0
	local pax_weight_Tot	= 0
	local cargo_weight_fwd	= 0
	local cargo_weight_aft	= 0
	local cargo_weight_bulk	= 0
	local cargo_weight_tot	= 0

	pax_total		= 	tonumber(fmsModules["data"].paxFirstClassA) + tonumber(fmsModules["data"].paxBusClassB)
						+ tonumber(fmsModules["data"].paxEconClassC) + tonumber(fmsModules["data"].paxEconClassD)
						+ tonumber(fmsModules["data"].paxEconClassE)
	pax_weightA		=	tonumber(fmsModules["data"].paxFirstClassA) * simConfigData["data"].stdPaxWeight
	pax_weightB		= 	tonumber(fmsModules["data"].paxBusClassB) * simConfigData["data"].stdPaxWeight
	pax_weightC		=	tonumber(fmsModules["data"].paxEconClassC) * simConfigData["data"].stdPaxWeight
	pax_weightD		=	tonumber(fmsModules["data"].paxEconClassD) * simConfigData["data"].stdPaxWeight
	pax_weightE		=	tonumber(fmsModules["data"].paxEconClassE) * simConfigData["data"].stdPaxWeight
	pax_weight_Tot	=	pax_weightA + pax_weightB + pax_weightC + pax_weightD + pax_weightE

	cargo_weight_fwd	= tonumber(fmsModules["data"].cargoFwd)
	cargo_weight_aft	= tonumber(fmsModules["data"].cargoAft)
	cargo_weight_bulk	= tonumber(fmsModules["data"].cargoBulk)
	cargo_weight_tot	= cargo_weight_fwd + cargo_weight_aft + cargo_weight_bulk
	
	--Assign values to FMC
	fmsModules["data"].paxTotal 		= pax_total
	fmsModules["data"].paxWeightA		= pax_weightA
	fmsModules["data"].paxWeightB		= pax_weightB
	fmsModules["data"].paxWeightC		= pax_weightC
	fmsModules["data"].paxWeightD		= pax_weightD
	fmsModules["data"].paxWeightE		= pax_weightE
	fmsModules["data"].paxWeightTotal	= pax_weight_Tot
	fmsModules["data"].cargoTotal		= cargo_weight_tot
	
	--Assign values to WB
	wb.passenger_zoneA_weight		= pax_weightA	
	wb.passenger_zoneB_weight		= pax_weightB
	wb.passenger_zoneC_weight		= pax_weightC
	wb.passenger_zoneD_weight		= pax_weightD
	wb.passenger_zoneE_weight		= pax_weightE
	wb.fwd_cargo_weight				= cargo_weight_fwd
	wb.aft_cargo_weight				= cargo_weight_aft
	wb.bulk_cargo_weight			= cargo_weight_bulk
	
	--Update Sim Payload weight with PAX & Cargo entries
	simDR_payload_weight = pax_weight_Tot + cargo_weight_tot
	
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
end
--Marauder28

--Marauder28
timer_start = 0
--Marauder28

function fmsFunctions.setdata(fmsO,value)
  local del=false  
  if fmsO["scratchpad"]=="DELETE" then fmsO["scratchpad"]="" del=true end

  if value=="depdst" and string.len(fmsO["scratchpad"])>3  then
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
    print(spd)
    if div==nil then 
      div=string.len(fmsO["scratchpad"])+1 
    else
      spd=string.sub(fmsO["scratchpad"],div+1)
    end
    print(spd)
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

    simCMD_FMS_key[fmsO.id]["fpln"]:once()--make sure we arent on the vnav page
    simCMD_FMS_key[fmsO.id]["clb"]:once()--go to the vnav page
    simCMD_FMS_key[fmsO.id]["next"]:once() --go to the vnav page 2

    fmsFunctions["custom2fmc"](fmsO,"R1")
    updateFrom=fmsO.id
    local toGet=B747DR_srcfms[updateFrom][3] --make sure we update it
    run_after_time(updateCRZ,0.5)
  elseif value=="irspos" and string.len(fmsO["scratchpad"])>10 then
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
        fmsModules["cmds"]["laminar/B747/electrical/connect_power"]:once() 
	fmsModules["cmds"]["sim/ground_ops/service_plane"]:once() 
     end
     fmsModules["lastcmd"]=fmsModules["cmdstrings"]["sim/ground_ops/service_plane"]
     run_after_time(preselect_fuel,30)
   elseif value=="fuelpreselect" and string.len(fmsO["scratchpad"])>0 then
     local fuel=tonumber(fmsO["scratchpad"])
     if fuel~=nil then
       B747DR_fuel_add=fuel
       
     end
   elseif value=="origin" and string.len(fmsO["scratchpad"])>0 then
     fmsFunctions["custom2fmc"](fmsO,"L1")
     fmsModules:setData("crzalt","*****") -- clear cruise alt /crzalt when entering a new source airport (this is broken and currently disabled)
   elseif value=="airportgate" and string.len(fmsO["scratchpad"])>0 then
    local lat=toDMS(simDR_latitude,true)
    local lon=toDMS(simDR_longitude,false)
    irsSystem["irsLat"]=lat
    irsSystem["irsLon"]=lon
    setFMSData("irsLat",lat)
    setFMSData("irsLon",lon)
    setFMSData(value,fmsO["scratchpad"])

--VALIDATE ENTERED WEIGHT UNITS
   elseif value=="weightUnits" then
	if string.len(fmsO["scratchpad"])>0 and validate_weight_units(fmsO["scratchpad"]) == false then 
      fmsO["notify"]="INVALID ENTRY"
	elseif is_timer_scheduled(preselect_fuel) == true then
	  fmsO["notify"]="NA - WAITING FOR FUEL TRUCK"
	elseif string.len(fmsO["scratchpad"]) > 0 then
		simConfigData["data"].weight_display_units = fmsO.scratchpad
		B747DR_simconfig_data=json.encode(simConfigData["data"]["values"])
    else
		if simConfigData["data"].weight_display_units == "KGS" then
			fmsO["scratchpad"] = "LBS"
		else
			fmsO["scratchpad"] = "KGS"
		end
		simConfigData["data"].weight_display_units = fmsO.scratchpad
		B747DR_simconfig_data=json.encode(simConfigData["data"]["values"])
	end

  elseif value == "codata" and string.len(fmsO["scratchpad"]) > 0 then
		setFMSData(value, fmsO["scratchpad"])
  
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

  elseif value == "grwt" then
	if string.len(fmsO["scratchpad"]) > 5 then
		fmsO["notify"]="INVALID ENTRY"
		return
	end
	local grwt
	if string.len(fmsO["scratchpad"]) > 0 then
		if simConfigData["data"].weight_display_units == "LBS" then
			grwt = fmsO["scratchpad"] / simConfigData["data"].kgs_to_lbs  --store LBS in KGS
		else
			grwt = fmsO["scratchpad"]
		end
	else
		grwt = (simDR_GRWT / 1000)
	end
	setFMSData(value, grwt)
	setFMSData("zfw", tonumber(grwt) - (simDR_fuel/1000))
	calc_CGMAC()  --Recalc CG %MAC and TRIM units
	if (B747DR_airspeed_V1 < 999 or B747DR_airspeed_Vr < 999 or B747DR_airspeed_V2 < 999) and simDR_onground == 1 then
		B747DR_airspeed_flapsRef = 0
		--B747DR_airspeed_V1 = 999
		--B747DR_airspeed_Vr = 999
		--B747DR_airspeed_V2 = 999
		fmsO["notify"] = "TAKEOFF SPEEDS DELETED"
	end

  elseif value == "zfw" then
	if string.len(fmsO["scratchpad"]) > 5 then
		fmsO["notify"]="INVALID ENTRY"
		return
	end
	local zfw
	if string.len(fmsO["scratchpad"]) > 0 then
		if simConfigData["data"].weight_display_units == "LBS" then
			zfw = fmsO["scratchpad"] / simConfigData["data"].kgs_to_lbs  --store LBS in KGS
		else
			zfw = fmsO["scratchpad"]
		end
	else
		zfw = (simDR_GRWT-simDR_fuel) / 1000
	end
	setFMSData(value, zfw)
	setFMSData("grwt", tonumber(zfw) + simDR_fuel / 1000)
	calc_CGMAC()  --Recalc CG %MAC and TRIM units
	if (B747DR_airspeed_V1 < 999 or B747DR_airspeed_Vr < 999 or B747DR_airspeed_V2 < 999) and simDR_onground == 1 then
		B747DR_airspeed_flapsRef = 0
		--B747DR_airspeed_V1 = 999
		--B747DR_airspeed_Vr = 999
		--B747DR_airspeed_V2 = 999
		fmsO["notify"] = "TAKEOFF SPEEDS DELETED"
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
  elseif value == "cargoFwd" then
	local weight_factor = 1

	if simConfigData["data"].weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].kgs_to_lbs
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
		else
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

	if simConfigData["data"].weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].kgs_to_lbs
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
		else
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

	if simConfigData["data"].weight_display_units == "LBS" then
		weight_factor = simConfigData["data"].kgs_to_lbs
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
--Marauder28

  --[[elseif value == "irsAlignTime" and string.len(fmsO["scratchpad"]) > 0 then
	if not string.match(fmsO["scratchpad"], "%d") then
		fmsO["notify"] = "INVALID ENTRY"
	else
		setFMSData(value, tonumber(fmsO["scratchpad"]) * 60)
		simConfigData["data"].irs_align_time = tonumber(fmsO["scratchpad"]) * 60
		print("FMC IRS = "..fmsO["scratchpad"] * 60)
	end]]

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
  if value=="VNAVSPAUSE" then B747DR_ap_vnav_pause=1-B747DR_ap_vnav_pause return end 
  if value=="CHOCKS" then B747DR__gear_chocked=1-B747DR__gear_chocked return  end
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
  print(val)
  if value=="VORL" then B747DR_radioModes=replace_char(2,modes,"M") simDR_radio_nav_freq_hz[2]=val*100  end
  if value=="VORR" then B747DR_radioModes=replace_char(3,modes,"M") simDR_radio_nav_freq_hz[3]=val*100  end
  if value=="CRSL" then simDR_radio_nav_obs_deg[2]=val end
  if value=="CRSR" then simDR_radio_nav_obs_deg[3]=val end
  if value=="ADFL" then simDR_radio_adf1_freq_hz=val end
  if value=="ADFR" then simDR_radio_adf2_freq_hz=val end
  if value=="flapsRef" then B747DR_airspeed_flapsRef=val end
  
  fmsO["scratchpad"]=""
end
function fmsFunctions.showmessage(fmsO,value)
  acarsSystem.currentMessage=value
  fmsO["inCustomFMC"]=true
  fmsO["targetPage"]="VIEWACARSMSG" 
  run_after_time(switchCustomMode, 0.25)
end

function fmsFunctions.doCMD(fmsO,value)
  print("do fmc command "..value)
  if fmsModules["cmds"][value] ~= nil then fmsModules["cmds"][value]:once() fmsModules["lastcmd"]=fmsModules["cmdstrings"][value] end
end
