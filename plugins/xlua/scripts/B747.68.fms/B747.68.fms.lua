--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]

--Workaround for stack overflow in init.lua namespace_read
function hasChild(parent,childKey)
  if(parent==nil) then
    return false
  end
  local keyFuncs=rawget(parent,'values')
  if keyFuncs==nil then return false end
  local keyFunc=rawget(keyFuncs,childKey)
  if keyFunc==nil then return false end
 
  return true
end
function cleanFMSLine(line)
    local retval=line:gsub("☐","*")
    retval=retval:gsub("°","`")
    return retval
end  
function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end
dofile("json/json.lua")
hh=find_dataref("sim/cockpit2/clock_timer/zulu_time_hours")
mm=find_dataref("sim/cockpit2/clock_timer/zulu_time_minutes")
ss=find_dataref("sim/cockpit2/clock_timer/zulu_time_seconds")
simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")

simDR_instrument_brightness_switch  = find_dataref("sim/cockpit2/switches/instrument_brightness_ratio")
simDR_instrument_brightness_ratio   = find_dataref("sim/cockpit2/electrical/instrument_brightness_ratio_manual")

simDR_radio_nav_freq_Mhz            = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_Mhz")
simDR_radio_nav_freq_khz            = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_khz")
simDR_radio_nav_freq_hz             = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_hz")
simDR_radio_nav_course_deg          = find_dataref("sim/cockpit2/radios/actuators/nav_course_deg_mag_pilot")
simDR_radio_nav_obs_deg             = find_dataref("sim/cockpit2/radios/actuators/nav_obs_deg_mag_pilot")
simDR_radio_nav01_ID                = find_dataref("sim/cockpit2/radios/indicators/nav1_nav_id")
simDR_radio_nav02_ID                = find_dataref("sim/cockpit2/radios/indicators/nav2_nav_id")
simDR_radio_nav03_ID                = find_dataref("sim/cockpit2/radios/indicators/nav3_nav_id")
simDR_radio_nav04_ID                = find_dataref("sim/cockpit2/radios/indicators/nav4_nav_id")

simDR_radio_adf1_freq_hz            = find_dataref("sim/cockpit2/radios/actuators/adf1_frequency_hz")
simDR_radio_adf2_freq_hz            = find_dataref("sim/cockpit2/radios/actuators/adf2_frequency_hz")

simDR_fueL_tank_weight_total_kg     = find_dataref("sim/flightmodel/weight/m_fuel_total")




B747DR_fms1_display_mode            = find_dataref("laminar/B747/fms1/display_mode")

B747DR_init_fmsL_CD                 = find_dataref("laminar/B747/fmsL/init_CD")
ilsData=deferred_dataref("laminar/B747/radio/ilsData", "string")
acars=create_dataref("laminar/B747/comm/acars","number")  

function createFMSDatarefs(fmsid)
create_dataref("laminar/B747/"..fmsid.."/Line01_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line02_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line03_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line04_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line05_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line06_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line07_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line08_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line09_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line10_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line11_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line12_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line13_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line14_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line01_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line02_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line03_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line04_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line05_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line06_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line07_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line08_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line09_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line10_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line11_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line12_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line13_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line14_S", "string")
end
createFMSDatarefs("fms1")
createFMSDatarefs("fms2")
createFMSDatarefs("fms3")
--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--

-- CRT BRIGHTNESS DIAL ------------------------------------------------------------------
B747DR_fms1_display_brightness      = create_dataref("laminar/B747/fms1/display_brightness", "number", B747_fms1_display_brightness_DRhandler)
fmsPages={}
--fmsPagesmall={}
fmsFunctionsDefs={}
fmsModules={} --set later
fmsModules["data"]={
  fltno="*******",
  fltdate="********",
  fltdep="****",
  fltdst="****",
  flttimehh="**",
  flttimemm="**",
  rpttimehh="**",
  rpttimemm="**",
  acarsAddress="*******",
  grwt="***.*",
  crzalt="*****",
  fuel="***.*",
  zfw="***.*",
  reserves="***.*",
  costindex="****",
  crzcg="**.*",
  thrustsel="**",
  thrustn1="**.*",
  toflap="**",
  v1="***",
  vr="***",
  v2="***",
  origin="****",
  runway="*****",
  destination="****",
  flightnumber="******",
  coroute="*****",
  grosswt="***.*",
  vref1="***",
  vref2="***",
  flapspeed="**/***",
setData=function(self,id,value)
  --always retain the same length
  len=string.len(self[id])
  newVal=string.sub(value,1,len)
  self[id]=string.format("%s%"..(len-string.len(value)).."s",value,"")
end
}
function setFMSData(id,value)
    --print("setting " .. id .. " to "..value.." curently "..fmsModules["data"][id])
   fmsModules["data"]:setData(id,value)
end  
function getFMSData(id)
  if hasChild(fmsModules["data"],id) then
    return fmsModules["data"][id]
  end
  return fmsModules["data"][id]
end 
function createPage(page)
  retVal={}
  retVal.name=page
  retVal.template={
  "    " .. page,
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
  "                        "
  }  
  retVal.templateSmall={
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
  "                        "
  }
  retVal.getPage=function(self,pgNo) return self.template end
  retVal.getSmallPage=function(self,pgNo) return self.templateSmall end
  retVal.getNumPages=function(self) return 1 end
  fmsFunctionsDefs[page]={}
  return retVal
end
dofile("B744.fms.pages.lua")

dofile("B744.createfms.lua")

fmsC = {}
setmetatable(fmsC, {__index = fms})
fmsC.id="fmsC"
setDREFs(fmsC,"cdu1","fms1","sim/FMS/","fms3")
fmsC.inCustomFMC=true
fmsC.currentPage="ACARS"

fmsL = {}
setmetatable(fmsL, {__index = fms})
fmsL.id="fmsL"
setDREFs(fmsL,"cdu1","fms3","sim/FMS/","fms1")
fmsL.inCustomFMC=true
fmsL.currentPage="INDEX"

fmsR = {}
setmetatable(fmsR, {__index = fms})
fmsR.id="fmsR"
setDREFs(fmsR,"cdu2","fms2","sim/FMS2/","fms2")
fmsR.inCustomFMC=true
fmsR.currentPage="INDEX"

fmsModules.fmsL=fmsL;
fmsModules.fmsC=fmsC;
fmsModules.fmsR=fmsR;
--dofile("json/json.lua")
--line=json.encode({ 1, 2, 3, { x = 10 } })
--print(line)
B747DR_CAS_memo_status          = find_dataref("laminar/B747/CAS/memo_status")
function flight_start()
  
end
function after_physics()
    fmsL:B747_fms_display()
    fmsC:B747_fms_display()
    fmsR:B747_fms_display()
    if acarsSystem.provider.online() then
      B747DR_CAS_memo_status[40]=0 --for CAS
      acars=1 --for radio
      acarsSystem.provider.receive()
      local hasNew=0
      for i = table.getn(acarsSystem.messages.values), 1, -1 do
	if not acarsSystem.messages[i]["read"] then 
	  hasNew=1
	end 
      end 
      B747DR_CAS_memo_status[0]=hasNew
    else
      B747DR_CAS_memo_status[40]=1 --for CAS
      acars=0 --for radio
    end
end
