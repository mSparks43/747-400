--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]


function fmsFunctions.initAcars(fmsO,value)
  local currentInit=getFMSData("acarsInitString")
  local initData={}
  initData["reg"]=getFMSData("fltno")
  if initData["reg"]=="*******" then fmsO["notify"]="FLT NO NOT SET" return end
  initData["dep"]=getFMSData("fltdep")
  if initData["dep"]=="****" then fmsO["notify"]="DEPARTURE NOT SET" return end
  initData["dst"]=getFMSData("fltdst")
  if initData["dst"]=="****" then fmsO["notify"]="DESTINATION NOT SET" return end
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
  run_after_time(switchCustomMode, 0.5)
  
end
function fmsFunctions.acarsLogonATC(fmsO,value)
  acarsSystem.provider.logoff()
  local atcLogon={}
	atcLogon["type"]="logon"
  local newInitSend=json.encode(atcLogon)
  fmsFunctions.acarsSystemSendATC(fmsO,newInitSend)
end
function fmsFunctions.acarsATCRequest(fmsO,value)
  local atcReq={}
	atcReq["type"]="request"
  atcReq["request"]=value
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

fmsFunctionsDefs["ACARSMSGS"]["L6"]={"setpage","ACARS"}

fmsPages["VIEWMISCACARS"]=createPage("VIEWMISCACARS")

acarsSystem={}
acarsSystem.messages={}
--print("have this many "..table.getn(acarsSystem.messages.values).." acars messages")
dofile("acars/autoatcProvider.lua")

function fmsFunctions.acarsSystemSend(fmsO,value)
  if acarsSystem.provider.online() then
    local msgToSend=value
    local tMSG={}
    if string.len(msgToSend) <5 then 
      tMSG["adr"]=getFMSData("acarsAddress")
       if tMSG["adr"]=="*******" then fmsO["notify"]="EMPTY ADDRESS" return end
      msgToSend=fmsO["scratchpad"] 
      tMSG["type"]="msg"
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
      tMSG["adr"]=getFMSData("acarsAddress")
       if tMSG["adr"]=="*******" then fmsO["notify"]="EMPTY ADDRESS" return end
      msgToSend=fmsO["scratchpad"] 
      tMSG["type"]="msg"
      tMSG["msg"]=msgToSend
      
      fmsO["scratchpad"]=""
    else
      tMSG=json.decode(value)
    end
    if string.len(msgToSend) <5 then fmsO["notify"]="EMPTY MESSAGE" return end
    
    
    acarsSystem.provider.sendATC(json.encode(tMSG))
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
      --if not acarsSystem.messages[i]["read"] then
	--retVal.template[line]=retVal.template[line].." (new)"
      --end
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
      numPages=math.ceil(table.getn(acarsSystem.messages.values)/5)
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
    
    if pgNo>1 then startNo=table.getn(acarsSystem.messages.values)-((pgNo-1)*5) end
    endNo=startNo-3
    if endNo <1 then endNo=1 end
    for i = startNo,endNo , -1 do
      local ln="<"..acarsSystem.messages[i]["title"]
      local padding=21-string.len(ln)
      if padding<0 then padding=0 end
      if not acarsSystem.messages[i]["read"] then
	      retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").." NEW"
	--retVal.template[line]=string.sub(ln,1,21) .." NEW"
      else
	      retVal.template[line]=string.sub(ln,1,21) .. string.format("%"..padding.."s","").." OLD"
	--retVal.template[line]=string.sub(ln,1,21) .." OLD"
      end
      retVal.templateSmall[line+1]="            "..acarsSystem.messages[i]["time"]
      fmsFunctionsDefs["VIEWUPACARS"]["L"..(startNo-i+1)]={"showmessage",i}
      line = line+2
      
    end  
    return retVal
end

dofile("acars/acars.pages.lua")
----

