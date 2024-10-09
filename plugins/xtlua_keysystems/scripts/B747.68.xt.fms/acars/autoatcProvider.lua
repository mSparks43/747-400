--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
acarsOnlineDataref=find_dataref("autoatc/acars/online")
acarsReceiveDataref=find_dataref("autoatc/acars/in")
sendDataref=find_dataref("autoatc/acars/out")
hasMobile=find_dataref("autoatc/hasMobile")
cduDataref=find_dataref("autoatc/cdu")

execLightDataref=find_dataref("sim/cockpit2/radios/indicators/fms_exec_light_copilot")
wasOnline=false
local lastSend=0
function getDefaultCycle()
  local file = io.open("Resources/default data/earth_nav.dat")
  if file==nil then
    return "2107" 
  end
  file:read("*l")
  local buildData=file:read("*l")
  io.close(file)
  return string.sub(buildData,27,30)
end
function getCycle()
  local file = io.open("Custom Data/earth_nav.dat", "r")
  if file==nil then
    return getDefaultCycle().." \n" 
  end
  file:read("*l")
  local buildData=file:read("*l")
  io.close(file)
  return string.sub(buildData,27,30).." \n"
end
autoATCState={}
autoATCState["initialised"]=false
autoATCState["online"]=false
acarsSystem.currentMessage={}
acarsSystem.getCurrentMessage=function(fmsID)
  return acarsSystem.currentMessage[fmsID]
end

acarsSystem.clear=function()
  print("LUA acarsSystem clearing ACARS messages:")
  --acarsSystem.provider.messageID=1
  acarsSystem.sentMessage=0
  acarsSystem.messages={}
  acarsSystem.messageSendQueue={}
  
end

--set the current message being viewed
acarsSystem.setCurrentMessage=function(fmsID,messageID)
  acarsSystem.currentMessage[fmsID]=messageID
end
function doACARSData(key,value)
  print("Key=("..key..") Value=("..value..")")
  if key=="CUR CTR" then
    setFMSData("curCTR",value)
  elseif key=="NEXT CTR" then
    setFMSData("nextCTR",value)
  elseif key=="SQUAWK" then
    simDR_xpdr_code=tonumber(value)
    print("Set transponder to "..value)
  end

end

function processACARSData(data)
  print("Processing ACARS data:"..data)
  local v=split(data,"@")
  for n=1,table.getn(v),1 do
    print(n.." = "..v[n])
    print(n%2)
    if (n%2)==0 then doACARSData(str_trim(v[n-1]),str_trim(v[n])) end
  end
end
acarsSystem.provider={
  messageID=1,
  logoff=function()
    if acarsSystem.provider.online()==true and fmsModules["data"]["atc"]~="****" then
      
      local tMSG={}
      tMSG["to"]=fmsModules["data"]["atc"]--getFMSData("acarsAddress")
      tMSG["type"]="cpdlc"
      tMSG["msg"]="LOGOFF"
      tMSG["RR"]="N"
      acarsSystem.provider.sendATC(json.encode(tMSG))
      autoATCState["online"]=false
    end
  end,
sendATC=function(value)
  print("LUA send ACARS message:"..value)
  local newMessage=json.decode(value)--check json value or fail
  newMessage["to"]=fmsModules["data"]["atc"]
  newMessage["from"]=getFMSData("fltno")
  newMessage["time"]=string.format("%02d:%02d",hh,mm)
  newMessage["messageID"]=acarsSystem.provider.messageID
  acarsSystem.provider.messageID=acarsSystem.provider.messageID+1
  --sendDataref=json.encode(newMessage)
  acarsSystem.messageSendQueue[table.getn(acarsSystem.messageSendQueue.values)+1]=json.encode(newMessage)
  --sleep(3)
end,
sendCompany=function(value)
  print("LUA send ACARS message:"..value)
  local newMessage=json.decode(value)--check json value or fail
  newMessage["to"]="company"
  newMessage["time"]=string.format("%02d:%02d",hh,mm)
  newMessage["messageID"]=acarsSystem.provider.messageID
  acarsSystem.provider.messageID=acarsSystem.provider.messageID+1
  --sendDataref=json.encode(newMessage)
  acarsSystem.messageSendQueue[table.getn(acarsSystem.messageSendQueue.values)+1]=json.encode(newMessage)
end,
send=function()
  local now=simDRTime
  local diff=simDRTime-lastSend
  if diff<15 then return end
  local queueSize=table.getn(acarsSystem.messageSendQueue.values)
  
  if queueSize>acarsSystem.sentMessage then
    local sending=acarsSystem.messageSendQueue[acarsSystem.sentMessage+1]
    local newMessage=json.decode(sending)
    newMessage["status"]="         SENT"
    acarsSystem.messageSendQueue[acarsSystem.sentMessage+1]=json.encode(newMessage)
    print("LUA send ACARS sending :"..sending)
    if acarsSystem.remote.isHoppie() then
      if not(acarsSystem.remote.send(sending)) then
        sendDataref=sending
      end
    else
      sendDataref=sending
    end
    lastSend=simDRTime
    acarsSystem.sentMessage=acarsSystem.sentMessage+1
  end
end,
gotResponse=function(mid)
  local onSent=table.getn(acarsSystem.messageSendQueue.values)
  print("parseResponse looking for msg "..mid)
  while (onSent>0) do
    print("parseResponse for msg "..acarsSystem.messageSendQueue[onSent])
    local thisMessage=json.decode(acarsSystem.messageSendQueue[onSent])
    if (""..thisMessage["messageID"])==(""..mid) then
      thisMessage["status"]="RESPONSE RCVD"
      print("parseResponse using")
      acarsSystem.messageSendQueue[onSent]=json.encode(thisMessage)
      onSent=0
    end
    onSent=onSent-1
  end
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
      io.write("I\n1100 Version\nCYCLE "..getCycle())
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
    if newMessage["type"]=="telex" then
      newMessage["read"]=false
      newMessage["rr"]="N"
      newMessage["time"]=string.format("%02d:%02d",hh,mm)
      newMessage["messageID"]=acarsSystem.provider.messageID
      acarsSystem.provider.messageID=acarsSystem.provider.messageID+1
      print("msg time "..newMessage["time"])
      acarsSystem.messages[table.getn(acarsSystem.messages.values)+1]=newMessage
    end
    if newMessage["type"]=="cpdlc" then
      
      newMessage["read"]=false
      newLogon=""
      if newMessage["msg"]=="LOGON ACCEPTED" then
        newMessage["read"]=true
        autoATCState["online"]=true
        newMessage["title"]="LOGON ACCEPTED"
        newMessage["msg"]=newMessage["from"]
      elseif string.find(newMessage["msg"], "@") then 
        processACARSData(newMessage["msg"])
      --[[elseif string.starts(newMessage["msg"],"NEXT CTR ") then 
        newMessage["read"]=true
        print("setting nextCTR "..fmsModules["data"]["nextCTR"])
        if string.len(newMessage["msg"])==13 then
          setFMSData("curCTR",getFMSData("nextCTR"))
          setFMSData("nextCTR",string.sub(newMessage["msg"],10,13))
          print("nextCTR ("..fmsModules["data"]["nextCTR"]..")")
        end]]--
      elseif newMessage["msg"]=="SERVICE TERMINATED" then
        newMessage["read"]=true
        autoATCState["online"]=false
        if fmsModules["data"]["nextCTR"]~="****" and fmsModules["data"]["atc"]==newMessage["from"] and fmsModules["data"]["atc"]==fmsModules["data"]["curCTR"] and fmsModules["data"]["atc"]~=fmsModules["data"]["nextCTR"] then
          setFMSData("atc","****")
          newLogon=fmsModules["data"]["nextCTR"]
        elseif fmsModules["data"]["curCTR"]~="****" and fmsModules["data"]["atc"]==newMessage["from"] and fmsModules["data"]["atc"]~=fmsModules["data"]["curCTR"] then
          setFMSData("atc","****")
          newLogon=fmsModules["data"]["curCTR"]
        end
        newMessage["title"]="SERVICE TERMINATED"
        newMessage["msg"]=newMessage["from"]
      end

      newMessage["time"]=string.format("%02d:%02d",hh,mm)
      if newMessage["title"]==nil then
        newMessage["title"]=string.sub(newMessage["msg"],1,19) --newMessage["from"].." "..string.sub(newMessage["msg"],1,15)
      end
      if newMessage["RT"]~=nil then
        acarsSystem.provider.gotResponse(newMessage["RT"])
      end
      if newMessage["rt"]~=nil then
        acarsSystem.provider.gotResponse(newMessage["rt"])
      end
      if newMessage["messageID"]~=nil then
        newMessage["srcID"]=newMessage["messageID"]
      end
      newMessage["REPLIED"]=false
      newMessage["messageID"]=acarsSystem.provider.messageID
      acarsSystem.provider.messageID=acarsSystem.provider.messageID+1
      acarsSystem.messages[table.getn(acarsSystem.messages.values)+1]=newMessage
      if string.len(newLogon)==4 then
        fmsFunctions["acarsLogonATC"](fmsL,newLogon)--send any notifications to fmsL, shouldn't be any if we are here
      end
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
  if hasMobile~=1 then wasOnline=false cduDataref="{}" return end
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




