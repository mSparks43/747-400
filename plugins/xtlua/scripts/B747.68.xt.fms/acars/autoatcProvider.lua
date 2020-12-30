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
acarsSystem.provider={
send=function(value)
  print("send ACARS message:"..value)
  local newMessage=json.decode(value)--check json value or fail
  sendDataref=value
  --run_after_time(doSendAfterTime, 2.0)
end,

receive=function() 
  updateAutoATCCDU()
  if string.len(acarsReceiveDataref)>1 then
    print("ACARS receive message:".. acarsReceiveDataref)
    local newMessage=json.decode(acarsReceiveDataref)
    newMessage["read"]=false
    newMessage["time"]=string.format("%02d:%02d",hh,mm)
    if newMessage["fp"] ~= nil then
      print("flight plan=" .. newMessage["fp"])
      file = io.open("Output/FMS plans/".. getFMSData("fltno") ..".fms", "w")
      io.output(file)
      io.write(newMessage["fp"])
      io.close(file)
      newMessage["fp"]= nil
    end
    acarsReceiveDataref=" "
    acarsSystem.messages[table.getn(acarsSystem.messages.values)+1]=newMessage
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
