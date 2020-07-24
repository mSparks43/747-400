--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
B747DR_CAS_advisory_status       = find_dataref("laminar/B747/CAS/advisory_status")

B747DR_iru_status         	= find_dataref("laminar/B747/flt_mgmt/iru/status")
B747DR_iru_mode_sel_pos         = find_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos")

B747DR_pfd_mode_capt		                = find_dataref("laminar/B747/pfd/capt/irs")
B747DR_pfd_mode_fo		                = find_dataref("laminar/B747/pfd/fo/irs")
B747DR_irs_src_fo		                = find_dataref("laminar/B747/flt_inst/irs_src/fo/sel_dial_pos")
B747DR_irs_src_capt		                = find_dataref("laminar/B747/flt_inst/irs_src/capt/sel_dial_pos")
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
function toDMS(value,isLat)
  degrees=value
  if value<0 then
    degrees=degrees*-1
   end
  minutes=(value-math.floor(value))*60
  seconds=minutes-math.floor(minutes)
  local p="N"
  if isLat==true and value<0 then 
    p="W"
  elseif isLat==true then  
    p="E"
  elseif value<0 then
    p="S"
  end
  retVal=string.format(p .. "%03d`%02d.%1d",degrees,minutes,seconds*10)
  return retVal
end
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end
--replace deferred_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
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


navAidsJSON   = find_dataref("xtlua/navaids")

B747DR_fms1_display_mode            = find_dataref("laminar/B747/fms1/display_mode")

B747DR_init_fmsL_CD                 = find_dataref("laminar/B747/fmsL/init_CD")
ilsData=deferred_dataref("laminar/B747/radio/ilsData", "string")
acars=deferred_dataref("laminar/B747/comm/acars","number")  
toderate=deferred_dataref("laminar/B747/engine/derate/TO","number") 
clbderate=deferred_dataref("laminar/B747/engine/derate/CLB","number")

--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--

-- CRT BRIGHTNESS DIAL ------------------------------------------------------------------
B747DR_fms1_display_brightness      = deferred_dataref("laminar/B747/fms1/display_brightness", "number", B747_fms1_display_brightness_DRhandler)

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
  atc="****",
  grwt="***.*",
  crzalt="*****",
  fuel="***.*",
  zfw="***.*",
  reserves="***.*",
  costindex="****",
  crzcg="**.*",
  thrustsel="26",
  thrustn1="**.*",
  toflap="**",
  v1="***",
  vr="***",
  v2="***",
  runway="*****",
  coroute="*****",
  grosswt="***.*",
  vref1="***",
  vref2="***",
  irsLat="****`**.*",
  irsLon="****`**.*",
  flapspeed="**/***",
  airportpos="*****",
  airportgate="*****",
setData=function(self,id,value)
  --always retain the same length
  if value=="" then value="***********" end
  len=string.len(self[id])
  if len < string.len(value) then 
    value=string.sub(value,1,len)
  end
  --newVal=string.sub(value,1,len)
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

dofile("irs/irs_system.lua")
dofile("B744.fms.pages.lua")

dofile("B744.createfms.lua")

fmsC = {}
setmetatable(fmsC, {__index = fms})
fmsC.id="fmsC"
setDREFs(fmsC,"cdu1","fms1","sim/FMS/","fms3")
fmsC.inCustomFMC=true
fmsC.currentPage="INDEX"


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
  if simDR_startup_running == 0 then
    irsSystem["irsL"]["aligned"]=false
    irsSystem["irsC"]["aligned"]=false
    irsSystem["irsR"]["aligned"]=false
    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

      irsSystem.align("irsL",true)
  
      irsSystem.align("irsC",true)
  
      irsSystem.align("irsR",true)

    end
 
end
debug_fms     = deferred_dataref("laminar/B747/debug/fms", "number")
function after_physics()
  if debug_fms>0 then return end
    fmsL:B747_fms_display()
    fmsC:B747_fms_display()
    fmsR:B747_fms_display()
    
    irsSystem.update()
    
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
