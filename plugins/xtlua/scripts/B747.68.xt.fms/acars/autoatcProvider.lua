--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
acarsOnlineDataref=find_dataref("autoatc/acars/online")
acarsReceiveDataref=find_dataref("autoatc/acars/in")
sendDataref=find_dataref("autoatc/acars/out")
cduDataref=find_dataref("autoatc/cdu")
execLightDataref=find_dataref("sim/cockpit2/radios/indicators/fms_exec_light_copilot")
wasOnline=false

autoATCState={}
autoATCState["initialised"]=false
autoATCState["online"]=false
acarsSystem.provider={
  logoff=function()
    autoATCState["online"]=false
  end,
sendATC=function(value)
  
  print("LUA send ACARS message:"..value)
  local newMessage=json.decode(value)--check json value or fail
  newMessage["acarsDest"]=fmsModules["data"]["atc"]
  sendDataref=json.encode(newMessage)
end,
sendCompany=function(value)
  
  print("LUA send ACARS message:"..value)
  local newMessage=json.decode(value)--check json value or fail
  newMessage["acarsDest"]="company"
  sendDataref=json.encode(newMessage)
end,
receive=function() 
  updateAutoATCCDU()
  if string.len(acarsReceiveDataref)>1 then
    print("LUA ACARS receive message:".. acarsReceiveDataref)
    local newMessage=json.decode(acarsReceiveDataref)
    if newMessage["fp"] ~= nil then
      print("flight plan=" .. newMessage["fp"])
      file = io.open("Output/FMS plans/".. getFMSData("fltno") ..".fms", "w")
      io.output(file)
      io.write("I\n1100 Version\nCYCLE 1802 \n")
      io.write(newMessage["fp"])
      io.close(file)
      newMessage["fp"]= nil
    end

    if newMessage["initialised"]==true then
      autoATCState["initialised"]=true
    elseif newMessage["initialised"]==false then
      autoATCState["initialised"]=false
    end
    if newMessage["online"]==true then
      autoATCState["online"]=true
    elseif newMessage["online"]==false then
      autoATCState["online"]=false
    end
    if newMessage["type"]=="misc" then
      newMessage["read"]=false
      newMessage["time"]=string.format("%02d:%02d",hh,mm)
      print("msg time "..newMessage["time"])
      acarsSystem.messages[table.getn(acarsSystem.messages.values)+1]=newMessage
    end
    acarsReceiveDataref=" "
    
    print("ACARS did receive message:"..acarsReceiveDataref)
  end  
end,

online=function()
  if acarsReceiveDataref==nil then return false end
  if wasOnline==true and acarsOnlineDataref==0 then
    wasOnline=false
    cduDataref="{}"
  end
  if acarsOnlineDataref==0 then return false end
  return true
end,

loggedOn=function()
  if autoATCState["initialised"]==false and autoATCState["online"]==false then
    return "   N/A "
  end
  if autoATCState["online"]==false then
    return "   N/A "
  end
  if fmsModules["data"]["atc"]~="****" then 
      return "ACCEPTED"
  else
    return "   READY"
  end
end
} 
local lastCDU={}

local lastSmallCDU={}
function readyCDU()
  
  wasOnline=true;
  return
end

function updateAutoATCCDU()
  
  if acarsSystem.provider.online()==false then return end
  if wasOnline==false then
    if is_timer_scheduled(readyCDU)==false then run_after_time(readyCDU,5) end
    cduDataref="{}"
    return
  end
  local thisID=fmsR.id
  for i=1,14,1 do
    lastCDU[i]=B747DR_fms[thisID][i]
    lastSmallCDU[i]=B747DR_fms_s[thisID][i]
  end
  local cdu={}
  cdu["small"]=lastSmallCDU
  cdu["large"]=lastCDU
  cdu["type"]="boeing"
  if(execLightDataref>0) then
    cdu["execLight"]="active"
  else
    cdu["execLight"]=""
  end
  cduDataref=json.encode(cdu)
end
