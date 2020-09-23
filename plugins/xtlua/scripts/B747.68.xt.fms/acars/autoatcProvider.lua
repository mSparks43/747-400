--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
acarsOnlineDataref=find_dataref("autoatc/acars/online")
acarsReceiveDataref=find_dataref("autoatc/acars/in")
sendDataref=find_dataref("autoatc/acars/out")
sendCommand=find_command("AutoATC/ACARS")
function doSendAfterTime()
  sendCommand:once()--need to give sendDataref time to write
end
acarsSystem.provider={
send=function(value)
  print("send ACARS message:"..value)
  local newMessage=json.decode(value)--check json value or fail
  sendDataref=value
  run_after_time(doSendAfterTime, 2.0)
end,

receive=function() 
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
  if acarsOnlineDataref==0 then return false end
  return true
end
} 
