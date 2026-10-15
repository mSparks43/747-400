--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
local clock = os.clock
function sleep(n)
  local t0 = clock()
  while clock() - t0 <= n do end
end
netRequestDataref=find_dataref("autoatc/networking/url")
netdataDataref=find_dataref("autoatc/networking/data")
netstatusDataref=find_dataref("autoatc/networking/urlstatus")

function fmsFunctions.initAcars(fmsO,value)
  local currentInit=getFMSData("acarsInitString")
  local initData={}
  initData["reg"]=getFMSData("fltno")
  if initData["reg"]=="*******" then fmsO["notify"]="FLT NO NOT SET" return end
  initData["dep"]=getFMSData("fltdep")
  if initData["dep"]=="****" then fmsO["notify"]="DEPARTURE NOT SET" return end
  initData["dst"]=getFMSData("fltdst")
  if initData["dst"]=="****" then fmsO["notify"]="DESTINATION NOT SET" return end
  initData["crzalt"]=getFMSData("crzalt")
  initData["pln"]=fmsJSON
  local newInit=json.encode(initData)
  if currentInit~= newInit then
    fmsModules["data"]["acarsInitString"]=newInit
    initData["type"]="initData"
    initData["af"]="B744"
    local newInitSend=json.encode(initData)
    print(newInitSend)
    fmsFunctions.acarsSystemSend(fmsO,newInitSend)
  end
  fmsO["pgNo"]=1
  fmsO["targetCustomFMC"]=true
  fmsO["targetPage"]="PREFLIGHT"
  fmsFunctions["acarsLogonATC"](fmsO,fmsModules.data["fltdep"])--auto login
  run_after_time(switchCustomMode, 0.5)
end
function fmsFunctions.acarsDataReady(fmsO)
  if getFMSData("fltno")=="--------" then fmsO["notify"]="FLT NO NOT SET" return false end
  if getFMSData("fltdep")=="****" then fmsO["notify"]="DEPARTURE NOT SET" return false end
  if getFMSData("fltdst")=="****" then fmsO["notify"]="DESTINATION NOT SET" return false end
  return true
end
function fmsFunctions.acarsLogonATC(fmsO,value)
  if not(fmsFunctions.acarsDataReady(fmsO)) then return end
  if getFMSData("atc")==value then return end
  acarsSystem.provider.logoff()
  local atcLogon={}
  setFMSData("atc",value)
  if fmsModules["data"]["atc"]=="****" then return end
	atcLogon["type"]="cpdlc"
  atcLogon["msg"]="REQUEST LOGON"
  atcLogon["RR"]="Y"
  local newInitSend=json.encode(atcLogon)
  fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
end


function fmsFunctions.acarsSendATCMessage(fmsO,message,requresResponse)
  if not(fmsFunctions.acarsDataReady(fmsO)) then return end
  local atcLogon={}
  if fmsModules["data"]["atc"]=="****" then return end
	atcLogon["type"]="cpdlc"
  atcLogon["msg"]=message
  atcLogon["RR"]=requresResponse
  local newInitSend=json.encode(atcLogon)
  fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
end


function fmsFunctions.acarsRespondATC(fmsO,value) --value=message being replied to, if, message starts WILCO = accepted, UNABLE = rejected, other=RESPONDED
  if not(fmsFunctions.acarsDataReady(fmsO)) then return end
  local atcLogon={}
  print("inacarsRespondATC "..value)
  if fmsModules["data"]["atc"]=="****" then fmsO["notify"]="NO LOGON" return end
  if string.len(fmsO["scratchpad"])>0 then
    local msg=acarsSystem.messages[value]
    
    local replyingTo=json.encode(msg)
    print("inacarsRespondATC msg"..replyingTo)
    atcLogon["type"]="cpdlc"
    atcLogon["msg"]=fmsO["scratchpad"]
    atcLogon["RR"]="N"
    atcLogon["status"]="SENDING"
    atcLogon["RT"]=msg["srcID"]
    local newInitSend=json.encode(atcLogon)
    print("newInitSend "..newInitSend)
    fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
    acarsSystem.messages[value]["REPLIED"]=true
    fmsO["scratchpad"] = ""
  else
    fmsO["notify"]="NO MESSAGE"
  end
end

function fmsFunctions.acarsATCRequest(fmsO,value)
  local atcReq={}
	atcReq["type"]="inforeq"
  atcReq["msg"]=value
  local newInitSend=json.encode(atcReq)
  fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
end
fmsPages["ACARSMSGS"]=createPage("ACARSMSGS")
fmsPages["ACARSMSGS"]["template"]={

"    ACARS-MSGS MENU     ",
"                        ",
"<FLT DSPTCH        MISC>",
"                        ",
"<UPLINK           DNLNK>",
"                        ",
"<PRINT UNDELIVERED MSGS ",
"                        ",
"                        ",
"                        ",
"                        ", 
"                        ",
"<RETURN                 "
}
fmsPages["ACARSMSGS"]["templateSmall"]={
"                        ",
"--------SEND MSG--------",
"                        ",
"-------STORED MSG-------",
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
fmsFunctionsDefs["ACARSMSGS"]["L2"]={"setpage","VIEWUPACARS"}
fmsFunctionsDefs["ACARSMSGS"]["L6"]={"setpage","ACARS"} --go to last page or acars
fmsFunctionsDefs["ACARSMSGS"]["R1"]={"setpage","VIEWMISCACARS"}
fmsFunctionsDefs["ACARSMSGS"]["R2"]={"setpage","VIEWDOWNACARS"}

fmsFunctionsDefs["ACARSMSGS"]["L6"]={"setpage","ACARS"}

fmsPages["VIEWMISCACARS"]=createPage("VIEWMISCACARS")

acarsSystem={}
acarsSystem.messages={}
acarsSystem.messageSendQueue={}
acarsSystem.sentMessage=0
--print("have this many "..table.getn(acarsSystem.messages.values).." acars messages")
dofile("acars/autoatcProvider.lua")
dofile("acars/autoatcHoppieProvider.lua")
function fmsFunctions.acarsSystemSend(fmsO,value)
  if acarsSystem.provider.online() then
    local msgToSend=value
    local tMSG={}
    if string.len(msgToSend) <5 then 
      tMSG["adr"]=getFMSData("acarsAddress")
       if tMSG["adr"]=="*******" then fmsO["notify"]="EMPTY ADDRESS" return end
      msgToSend=fmsO["scratchpad"]
      tMSG["type"]="cpdlc"
      tMSG["msg"]=msgToSend
      fmsO["scratchpad"]=""
    else
      tMSG=json.decode(value)
    end
    if string.len(msgToSend) <5 then fmsO["notify"]="EMPTY MESSAGE" return end
    
    
    acarsSystem.provider.sendCompany(json.encode(tMSG))
    fmsO["targetCustomFMC"]=true
    run_after_time(switchCustomMode, 0.5)
    --fmsO["currentPage"]="ACARS" 
    --local tMSG=json.encode({type="msg",msg="Test Message",time="12:00 UTC"})
    --print(tMSG)
    --local rMSG=json.decode(tMSG)
    --print(rMSG["msg"])
  else
    fmsO["notify"]="ACARS NO COMM"
  end
  --print("setpage" .. value)
end
function fmsFunctions.acarsSystemSendATC(fmsO,value)

  if acarsSystem.provider.online() then
    local msgToSend=value
    local tMSG={}
    if string.len(msgToSend) <5 then 
      tMSG["to"]=getFMSData("acarsAddress")
      if tMSG["to"]=="*******" then fmsO["notify"]="EMPTY ADDRESS" return end
      msgToSend=fmsO["scratchpad"] 
      tMSG["type"]="cpdlc"
      tMSG["msg"]=msgToSend
      fmsO["scratchpad"]=""
    else
      tMSG=json.decode(value)
    end
    if string.len(msgToSend) <5 then fmsO["notify"]="EMPTY MESSAGE" return end
    print("sendATC "..value)
    acarsSystem.provider.sendATC(json.encode(tMSG))
    --fmsO["targetCustomFMC"]=true
    --run_after_time(switchCustomMode, 0.5)
    --fmsO["currentPage"]="ACARS" 
    --local tMSG=json.encode({type="msg",msg="Test Message",time="12:00 UTC"})
    --print(tMSG)
    --local rMSG=json.decode(tMSG)
    --print(rMSG["msg"])
  else
    fmsO["notify"]="ACARS NO COMM"
  end
  --print("setpage" .. value)
end


acarsSystem.getMiscMessages=function(pgNo)
    

     
    retVal={}
    retVal.template={
      "   ACARS-MISC MSGS      ",
      "                        ",
      "                        ", -- --"<Test Message           ",
      "                        ",
      "                        ", -- --"<2nd Test Message       ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      " ADDRESS                ",
      "<"..fmsModules["data"]["acarsAddress"] .."           SEND>",
      "                        ",
      "<RETURN                 "
      } 
      numPages=math.ceil(table.getn(acarsSystem.messages.values)/4)
      if numPages<1 then numPages=1 end
    retVal.templateSmall={
      "                     "..pgNo.."/"..numPages.." ",
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
    line = 3
    startNo=table.getn(acarsSystem.messages.values)
    
    if pgNo>1 then startNo=table.getn(acarsSystem.messages.values)-((pgNo-1)*4) end
    endNo=startNo-3
    if endNo <1 then endNo=1 end
    for i = startNo,endNo , -1 do
      retVal.template[line]="<"..acarsSystem.messages[i]["title"]
      retVal.templateSmall[line+1]="            "..acarsSystem.messages[i]["time"]
      fmsFunctionsDefs["VIEWMISCACARS"]["L"..(startNo-i+1)]={"showmessage",i}
      line = line+2
      
    end  
    return retVal
end

fmsPages["VIEWUPACARS"]=createPage("VIEWUPACARS")



acarsSystem.getUpMessages=function(pgNo)
    retVal={}
    retVal.template={
      "  ACARS-UPLINK MSG      ",
      "                        ",
      "                        ", -- --"<Test Message           ",
      "                        ",
      "                        ", -- --"<2nd Test Message       ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "<RETURN                 "
      } 
      numPages=math.ceil(table.getn(acarsSystem.messages.values)/4)
      if numPages<1 then numPages=1 end
    retVal.templateSmall={
      "                    "..pgNo.."/"..numPages.."  ",
      " MSG TITLE          STAT",
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
    line = 3
    startNo=table.getn(acarsSystem.messages.values)
    
    if pgNo>1 then startNo=table.getn(acarsSystem.messages.values)-((pgNo-1)*4) end
    endNo=startNo-3
    --print("startNo "..startNo.." endNo "..endNo)
    if endNo <1 then endNo=1 end
    for i = startNo,endNo , -1 do
      local ln="<"..acarsSystem.messages[i]["title"]
      --local msg=acarsSystem.messages[i]
      --local encodedMSG=json.encode(msg)
      --print("rendering "..encodedMSG)
      local padding=21-string.len(ln)
      if padding<0 then padding=0 end
     --[[ if acarsSystem.messages[i]["rr"]~=nil and acarsSystem.messages[i]["rr"]=="N" then
        local padding=10-string.len(ln)
        if padding<0 then padding=0 end
        if not acarsSystem.messages[i]["REPLIED"] then
          retVal.template[line]=string.sub(ln,1,10) .. string.format("%"..padding.."s","").." REPLY REQUIRED"
        else
          retVal.template[line]=string.sub(ln,1,10) .. string.format("%"..padding.."s","").."     REPLY SENT"
        end
      else]]--

        if acarsSystem.messages[i]["rr"]~="N" and not acarsSystem.messages[i]["REPLIED"] then
          retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").."  RR"
        elseif not acarsSystem.messages[i]["read"] then
          retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").." NEW"
        else
          retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").." OLD"
        end
      --end
      retVal.templateSmall[line+1]="            "..acarsSystem.messages[i]["time"]
      fmsFunctionsDefs["VIEWUPACARS"]["L"..(startNo-i+1)]={"showmessage",i}
      line = line+2
      
    end  
    return retVal
end

fmsPages["VIEWDOWNACARS"]=createPage("VIEWDOWNACARS")

acarsSystem.getDownMessages=function(pgNo)
  retVal={}
  retVal.template={
    "  ACARS-DOWNLINK MSG    ",
    "                        ",
    "                        ", -- --"<Test Message           ",
    "                        ",
    "                        ", -- --"<2nd Test Message       ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "<RETURN                 "
    } 
    numPages=math.ceil(table.getn(acarsSystem.messageSendQueue.values)/4)
    if numPages<1 then numPages=1 end
  retVal.templateSmall={
    "                    "..pgNo.."/"..numPages.."  ",
    " MSG TITLE          STAT",
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
  line = 3
  startNo=table.getn(acarsSystem.messageSendQueue.values)
  
  if pgNo>1 then startNo=table.getn(acarsSystem.messageSendQueue.values)-((pgNo-1)*4) end
  endNo=startNo-3
  --print("startNo "..startNo.." endNo "..endNo)
  if endNo <1 then endNo=1 end
  local sMessage={}
  for i = startNo,endNo , -1 do
    --print(i.."="..acarsSystem.messageSendQueue[i])
    sMessage=json.decode(acarsSystem.messageSendQueue[i])
    local ln=""
    local status="        "
    if sMessage["status"]~=nil then status=sMessage["status"] end
    retVal.templateSmall[line]=" "..sMessage["time"].."z     "..status --RESPONSE RCVD"
    if sMessage["type"]=="cpdlc" then
      ln=sMessage["msg"].." ("..sMessage["to"] ..")"
    elseif sMessage["type"]=="initData" then
      ln="REQUEST "..sMessage["dep"].."-"..sMessage["dst"]
    elseif sMessage["type"]=="inforeq" then
      ln=sMessage["msg"].." ("..sMessage["to"] ..")"
    end
    local padding=24-string.len(ln)
    if padding<0 then padding=0 end
    retVal.template[line+1]=string.sub(ln,1,24) .. string.format("%"..padding.."s","")
    line = line+2
    
  end  
  return retVal
end

fmsPages["VIEWACARSLOG"]=createPage("VIEWACARSLOG")
acarsSystem.getLogMessages=function(pgNo)
  local onRecieved=table.getn(acarsSystem.messages.values)
  local onSent=table.getn(acarsSystem.messageSendQueue.values)
  
  local retVal={}
  local sMessage={}
  --print("getLogMessages")
  local currentPage=1
  while currentPage <= pgNo do
    retVal={}
    local rmID=1
    while (onRecieved>0 or onSent>0) and rmID<6 do
      local rID=0
      local sID=0
      --print("onRecieved "..onRecieved.." onSent "..onSent)
      
      if onRecieved>0 then
        rID=acarsSystem.messages[onRecieved]["messageID"]
      end
      if onSent>0 then
        sMessage=json.decode(acarsSystem.messageSendQueue[onSent])
        sID=sMessage["messageID"]
      end
      if sID==nil then print("got bad sID!!") end
      --print("rID "..rID.." sID "..sID.." "..acarsSystem.messageSendQueue[onSent])
      if rID>sID then
        retVal[rmID]=acarsSystem.messages[onRecieved]
        retVal[rmID]["ud"]="U"
        fmsFunctionsDefs["VIEWACARSLOG"]["R"..(rmID)]={"showmessage",onRecieved}
        --print("use received message".." rmID "..rmID.. " rID "..onRecieved)
        rmID=rmID+1
        onRecieved=onRecieved-1
      else
        if sMessage["msg"]~=nil then
          retVal[rmID]=sMessage
          retVal[rmID]["ud"]="D"
          rmID=rmID+1
          onSent=onSent-1
          --print("use sent message")
        else
          onSent=onSent-1
          --print("skip sent message")
        end
      end
    end
    currentPage=currentPage+1
  end
  return retVal
end

acarsSystem.getMessageLog=function(pgNo)
  
  retVal={}
  retVal.template={
    "        ATC LOG         ",
    "                        ",
    "                        ", -- --"<Test Message           ",
    "                        ",
    "                        ", -- --"<2nd Test Message       ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "------------------------",
    "<INDEX        ERASE LOG>"
    
    } 
    --numPages=math.ceil(table.getn(acarsSystem.messages.values)/5)+math.ceil(table.getn(acarsSystem.messageSendQueue.values)/5)
    numPages=math.ceil((table.getn(acarsSystem.messages.values)+table.getn(acarsSystem.messageSendQueue.values))/5)
    if numPages<1 then numPages=1 end
  retVal.templateSmall={
    "                    "..pgNo.."/"..numPages.."  ",
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

    local messageLog=acarsSystem.getLogMessages(pgNo)
    line = 2
    for i=1,table.getn(messageLog) do
      --print("M "..i.." "..messageLog[i]["ud"])
      local ln=""
      if messageLog[i]["ud"]=="U" then
        if messageLog[i]["rr"]~="N" then
          if not messageLog[i]["REPLIED"] then
            retVal.templateSmall[line]=" "..messageLog[i]["time"].."z    REPLY REQUIRED"
          else
            retVal.templateSmall[line]=" "..messageLog[i]["time"].."z        REPLY SENT"
          end
        else
          if not messageLog[i]["read"] then
            retVal.templateSmall[line]=" "..messageLog[i]["time"].."z               NEW"
          else
            retVal.templateSmall[line]=" "..messageLog[i]["time"].."z               OLD"
          end
        end
        ln="  "..messageLog[i]["title"]
        
      else
        --messageLog[i]["status"]
        local status="             "
        if messageLog[i]["status"]~=nil then status=messageLog[i]["status"] end
        retVal.templateSmall[line]=" "..messageLog[i]["time"].."z     "..status --RESPONSE RCVD"
        --print("T "..messageLog[i]["msg"])
        ln="  "..messageLog[i]["msg"]
      end
      retVal.templateSmall[line+1]=messageLog[i]["ud"].."                       "
      ln=string.sub(ln,1,21)
      local padding=21-string.len(ln)
      if padding<=0 then 
        padding=0 
        ln=ln..".."
      else
        ln=ln.."  "
      end
      retVal.template[line+1]=ln .. string.format("%"..padding.."s","").." >"
      line = line+2
    end
    return retVal
end

dofile("acars/acars.pages.lua")
----

