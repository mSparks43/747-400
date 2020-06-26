--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
fmsFunctions={}
dofile("acars/acars.lua")
fmsPages["INDEX"]=createPage("INDEX")
fmsPages["INDEX"]["template"]={

"          MENU          ",
"                        ",
"<FMC             SELECT>",
"                        ",
"<ACARS           SELECT>",
"                        ",
"<SAT                    ",
"                        ",
"                        ",
"                        ",
"<ACMS                   ", 
"                        ",
"<CMC                    "
}
fmsPages["INDEX"]["templateSmall"]={
"                        ",
"                 EFIS CP",
"                        ",
"                EICAS CP",
"                        ",
"                 CTL PNL",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
}

fmsFunctionsDefs["INDEX"]={}
fmsFunctionsDefs["INDEX"]["L1"]={"setpage","FMC"}
fmsFunctionsDefs["INDEX"]["L2"]={"setpage","ACARS"}
fmsPages["RTE1"]=createPage("RTE1")
fmsPages["RTE1"].getPage=function(self,pgNo,fmsID)
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
  "<RTE 2             PERF>",
  }
  return page 
end
fmsFunctionsDefs["RTE1"]["L1"]={"custom2fmc","L1"}
fmsFunctionsDefs["RTE1"]["L2"]={"custom2fmc","L2"}
fmsFunctionsDefs["RTE1"]["L3"]={"custom2fmc","L3"}
fmsFunctionsDefs["RTE1"]["L4"]={"custom2fmc","L4"}
fmsFunctionsDefs["RTE1"]["L5"]={"custom2fmc","L5"}
fmsFunctionsDefs["RTE1"]["L6"]={"setpage","RTE2"}
fmsFunctionsDefs["RTE1"]["R1"]={"custom2fmc","R1"}
fmsFunctionsDefs["RTE1"]["R2"]={"custom2fmc","R2"}
fmsFunctionsDefs["RTE1"]["R3"]={"custom2fmc","R3"}
fmsFunctionsDefs["RTE1"]["R4"]={"custom2fmc","R4"}
fmsFunctionsDefs["RTE1"]["R5"]={"custom2fmc","R5"}
fmsFunctionsDefs["RTE1"]["R6"]={"setpage","PERFINIT"}

fmsFunctionsDefs["RTE1"]["next"]={"custom2fmc","next"}
fmsFunctionsDefs["RTE1"]["prev"]={"custom2fmc","prev"}
dofile("B744.fms.pages.posinit.lua")
dofile("B744.fms.pages.perfinit.lua")
dofile("B744.fms.pages.thrustlim.lua")
dofile("B744.fms.pages.takeoff.lua")
dofile("B744.fms.pages.approach.lua")
dofile("B744.fms.pages.maint.lua")
dofile("B744.fms.pages.maintbite.lua")
dofile("B744.fms.pages.maintcrossload.lua")
dofile("B744.fms.pages.maintirsmonitor.lua")
dofile("B744.fms.pages.maintperffactor.lua")
dofile("B744.fms.pages.actrte1.lua")

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
dofile("B744.fms.pages.atcindex.lua")
dofile("B744.fms.pages.atclogonstatus.lua")
dofile("B744.fms.pages.atcrejectdueto.lua")
dofile("B744.fms.pages.atcreport.lua")
dofile("B744.fms.pages.atcreport2.lua")
dofile("B744.fms.pages.atcuplink.lua")
dofile("B744.fms.pages.atcverifyresponse.lua")
dofile("B744.fms.pages.deparrindex.lua")
dofile("B744.fms.pages.departures.lua")
dofile("B744.fms.pages.fixinfo.lua")
dofile("B744.fms.pages.fmccomm.lua")
dofile("B744.fms.pages.identpage.lua")
dofile("B744.fms.pages.irsprogress.lua")
dofile("B744.fms.pages.navradpage.lua")
dofile("B744.fms.pages.progress.lua")
dofile("B744.fms.pages.refnavdata1.lua")
dofile("B744.fms.pages.satcom.lua")
dofile("B744.fms.pages.waypointwinds.lua")

]]

fmsPages["INITREF"]=createPage("INITREF")
fmsPages["INITREF"]["template"]={

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
"<TAKEOFF                ", 
"                        ",
"<APPROACH         MAINT>"
}


fmsFunctionsDefs["INITREF"]={}
fmsFunctionsDefs["INITREF"]["L1"]={"setpage","IDENT"}
fmsFunctionsDefs["INITREF"]["L2"]={"setpage","POSINIT"}
fmsFunctionsDefs["INITREF"]["L3"]={"setpage","PERFINIT"}
fmsFunctionsDefs["INITREF"]["L4"]={"setpage","THRUSTLIM"}
fmsFunctionsDefs["INITREF"]["L5"]={"setpage","TAKEOFF"}
fmsFunctionsDefs["INITREF"]["L6"]={"setpage","APPROACH"}
fmsFunctionsDefs["INITREF"]["R6"]={"setpage","MAINT"}
fmsFunctionsDefs["INITREF"]["R1"]={"setpage","DATABASE"}



simDR_variation=find_dataref("sim/flightmodel/position/magnetic_variation")
fmsPages["NAVRAD"]=createPage("NAVRAD")
fmsPages["NAVRAD"].getPage=function(self,pgNo,fmsID)
  local ils1="                        "
  local ils2="                        "
  if string.len(ilsData)>1 then
    local ilsNav=json.decode(ilsData)
    ils1= ilsNav[7]
    ils2= string.format("%6.2f/%03d%s             ", ilsNav[3]*0.01,(ilsNav[4]+simDR_variation), "˚")
  end
  local page={
    "        NAV RADIO       ",
    "                        ",
    string.format("%6.2f %4s  %4s %6.2f", simDR_radio_nav_freq_hz[2]*0.01, simDR_radio_nav03_ID, simDR_radio_nav04_ID, simDR_radio_nav_freq_hz[3]*0.01),
    string.format("                        ", ""),
    string.format(" %03d     %3s  %3s    %03d", simDR_radio_nav_obs_deg[2], "---", "---", simDR_radio_nav_obs_deg[3]),
    "                        ",
    string.format("%06.1f         %06.1f   ", simDR_radio_adf1_freq_hz, simDR_radio_adf2_freq_hz),
    "                        ",
    ils1,
    ils2,
    "                        ", 
    "                        ",
    "                        "
    }
  return page
end
--fmsPages["NAVRAD"]["template"]=
fmsPages["NAVRAD"]["templateSmall"]={
"                        ",
" VOR L             VOR R",
"                        ",
" CRS      RADIAL     CRS",
"                        ",
" ADF L             ADF R",
"      ANT            ANT",
" ILS                    ",
"                        ",
"           M            ",
"                        ",
"                        ",
"                        ",
}
fmsFunctionsDefs["NAVRAD"]["L1"]={"setDref","VORL"}
fmsFunctionsDefs["NAVRAD"]["L2"]={"setDref","CRSL"}
fmsFunctionsDefs["NAVRAD"]["L3"]={"setDref","ADFL"}
fmsFunctionsDefs["NAVRAD"]["R1"]={"setDref","VORR"}
fmsFunctionsDefs["NAVRAD"]["R2"]={"setDref","CRSR"}
fmsFunctionsDefs["NAVRAD"]["R3"]={"setDref","ADFR"}
--fmsFunctionsDefs["NAVRAD"]["L6"]={"setpage","ACARS"}

function fmsFunctions.setpage(fmsO,value)
  fmsO["pgNo"]=1
  
  --sim/FMS/navrad
  --sim/FMS2/navrad
  if value=="FMC" then
    fmsO["inCustomFMC"]=false
    fmsO["currentPage"]="FMC"
    simCMD_FMS_key[fmsO.id]["fpln"]:once()
    simCMD_FMS_key[fmsO.id]["L6"]:once()
     
  elseif value=="VHFCONTROL" then
    fmsO["inCustomFMC"]=false
    fmsO["currentPage"]="VHFCONTROL"
    simCMD_FMS_key[fmsO.id]["navrad"]:once()
    
  elseif value=="IDENT" then
    fmsO["inCustomFMC"]=false
    fmsO["currentPage"]="IDENT"
    simCMD_FMS_key[fmsO.id]["index"]:once()
    simCMD_FMS_key[fmsO.id]["L1"]:once()
    
  elseif value=="DATABASE" then
    fmsO["inCustomFMC"]=false
    fmsO["currentPage"]="DATABASE"
    simCMD_FMS_key[fmsO.id]["index"]:once()
    simCMD_FMS_key[fmsO.id]["R2"]:once()
  elseif value=="RTE2" then
    fmsO["inCustomFMC"]=false
    fmsO["currentPage"]="RTE2"
    simCMD_FMS_key[fmsO.id]["dir_intc"]:once()
    simCMD_FMS_key[fmsO.id]["R2"]:once()
  else
    fmsO["inCustomFMC"]=true
    fmsO["currentPage"]=value 
 
  end
  print("setpage " .. value)
end
function fmsFunctions.custom2fmc(fmsO,value)
  simCMD_FMS_key[fmsO["id"]]["del"]:once()
  simCMD_FMS_key[fmsO["id"]]["clear"]:once()
  if value~="next" and value~="prev" and string.len(fmsO["scratchpad"])>0 then
    for c in string.gmatch(fmsO["scratchpad"],".") do
      simCMD_FMS_key[fmsO["id"]][c]:once()
    end
  end
  simCMD_FMS_key[fmsO["id"]][value]:once()
  fmsO["scratchpad"]=""
end
function fmsFunctions.setdata(fmsO,value) 
  if value=="depdst" then
    dep=string.sub(fmsO["scratchpad"],1,4)
    dst=string.sub(fmsO["scratchpad"],-4)
    --fmsModules["data"]["fltdep"]=dep
    --fmsModules["data"]["fltdst"]=dst
    setFMSData("fltdep",dep)
    setFMSData("fltdst",dst)
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
  else
    setFMSData(value,fmsO["scratchpad"])
  end
  fmsO["scratchpad"]=""
end

function fmsFunctions.setDref(fmsO,value)
   local val=tonumber(fmsO["scratchpad"])
  print(val)
  if value=="VORL" then simDR_radio_nav_freq_hz[2]=val*100 end
  if value=="VORR" then simDR_radio_nav_freq_hz[3]=val*100 end
  if value=="CRSL" then simDR_radio_nav_obs_deg[2]=val end
  if value=="CRSR" then simDR_radio_nav_obs_deg[3]=val end
  if value=="ADFL" then simDR_radio_adf1_freq_hz=val end
  if value=="ADFR" then simDR_radio_adf2_freq_hz=val end
  fmsO["scratchpad"]=""
end
function fmsFunctions.showmessage(fmsO,value)
  acarsSystem.currentMessage=value
  fmsO["inCustomFMC"]=true
  fmsO["currentPage"]="VIEWACARSMSG" 
end