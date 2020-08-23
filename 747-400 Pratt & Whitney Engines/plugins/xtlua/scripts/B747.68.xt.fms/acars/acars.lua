--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]

fmsPages["ACARS"]=createPage("ACARS")
fmsPages["ACARS"]["template"]={
"    ACARS-MAIN MENU     ",
"                        ",
"<PREFLIGHT         MSGS>",
"                        ",
"<INFLIGHT     VHF CNTRL>",
"                        ",
"<POSTFLIGHT     WXR REQ>",
"                        ",
"                        ",
"                        ",
"<MAINT EVENT      TIMES>",
"                        ",
"                        "
}
fmsFunctionsDefs["ACARS"]["L1"]={"setpage","PREFLIGHT"}
fmsFunctionsDefs["ACARS"]["R1"]={"setpage","ACARSMSGS"}
fmsFunctionsDefs["ACARS"]["R2"]={"setpage","VHFCONTROL"}
fmsPages["PREFLIGHT"]=createPage("PREFLIGHT")
fmsPages["PREFLIGHT"]["template"]={

"  ACARS-PREFLIGHT MENU  ",
"                        ",
"                        ",
"                        ",
"<INITIALIZE        MSGS>",
"                        ",
"              VHF CNTRL>",
"                        ",
"<UTC UPDATE     WXR REQ>",
string.format(" %02d:%02d:%02d               ",hh,mm,ss),
"            EVENT TIMES>", 
"                        ",
"                        ",
"<RETURN                 "
}

fmsFunctionsDefs["PREFLIGHT"]["L6"]={"setpage","ACARS"}
fmsFunctionsDefs["PREFLIGHT"]["L2"]={"setpage","INITIALIZE"}
fmsFunctionsDefs["PREFLIGHT"]["R2"]={"setpage","ACARSMSGS"}
fmsFunctionsDefs["PREFLIGHT"]["R3"]={"setpage","VHFCONTROL"}
fmsPages["INITIALIZE"]=createPage("INITIALIZE")
fmsPages["INITIALIZE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  fmsPages["INITIALIZE"]["template"]={

  "  ACARS-INITIALIZATION  ",
  "                        ",
  "<"..fmsModules["data"]["fltno"] .."        "..fmsModules.data["fltdate"],
  "                        ",
  "<".. fmsModules.data["fltdep"] .."/"..fmsModules.data["fltdst"] .."        "..fmsModules.data["flttimehh"] ..":"..fmsModules.data["flttimemm"] ..">",
  "                        ",
  fmsModules.data["rpttimehh"] ..":"..fmsModules.data["rpttimemm"] .."            ------>",
  "                        ",
  "<------          ------>",
  "F/O ID       CHK CAPT ID",
  "<------          ------>",
  "                        ",
  "<RETURN                 "
  }
  return fmsPages["INITIALIZE"]["template"]
end
fmsPages["INITIALIZE"]["templateSmall"]={
"                        ",
"FLT NO          UTC DATE",
"                        ",
"DEP/DES         FLT TIME",
"                        ",
"RPT TIME         S/01 ID",
"                        ",
"CAPT ID          S/02 ID",
"                        ",
"                        ",
"                        ",
"                        ", 
"                        ",
"                        "
}
fmsFunctionsDefs["INITIALIZE"]["L6"]={"initAcars",""}
fmsFunctionsDefs["INITIALIZE"]["L1"]={"setdata","fltno"}
fmsFunctionsDefs["INITIALIZE"]["L2"]={"setdata","depdst"}
fmsFunctionsDefs["INITIALIZE"]["L3"]={"setdata","rpttime"}
fmsFunctionsDefs["INITIALIZE"]["R1"]={"setdata","fltdate"}
fmsFunctionsDefs["INITIALIZE"]["R2"]={"setdata","flttime"}
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
  run_after_time(switchCustomMode, 0.15)
  
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
    
    
    acarsSystem.provider.send(json.encode(tMSG))
    fmsO["targetCustomFMC"]=true
    run_after_time(switchCustomMode, 0.15)
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
      "    ACARS-MISC MSGS     ",
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

fmsPages["VIEWMISCACARS"].getPage=function(self,pgNo,fmsID)
  local page=acarsSystem.getMiscMessages(pgNo)
  return page.template 
end
fmsPages["VIEWMISCACARS"].getSmallPage=function(self,pgNo,fmsID) 
  local page=acarsSystem.getMiscMessages(pgNo)
  return page.templateSmall 
end
fmsPages["VIEWMISCACARS"].getNumPages=function(self)
  noPages=math.ceil(table.getn(acarsSystem.messages.values)/4)
  if noPages<1 then noPages=1 end
  return noPages 
end
fmsFunctionsDefs["VIEWMISCACARS"]["L5"]={"setdata","acarsAddress"}
fmsFunctionsDefs["VIEWMISCACARS"]["L6"]={"setpage","ACARSMSGS"}
fmsFunctionsDefs["VIEWMISCACARS"]["R5"]={"acarsSystemSend","msg"}
----
fmsPages["VIEWUPACARS"]=createPage("VIEWUPACARS")



acarsSystem.getUpMessages=function(pgNo)
    

     
    retVal={}
    retVal.template={
      "    ACARS-UPLINK MSG    ",
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

fmsPages["VIEWUPACARS"].getPage=function(self,pgNo,fmsID)
  local page=acarsSystem.getUpMessages(pgNo)
  return page.template 
end
fmsPages["VIEWUPACARS"].getSmallPage=function(self,pgNo,fmsID) 
  local page=acarsSystem.getUpMessages(pgNo)
  return page.templateSmall 
end
fmsPages["VIEWUPACARS"].getNumPages=function(self)
  noPages=math.ceil(table.getn(acarsSystem.messages.values)/4)
  if noPages<1 then noPages=1 end
  return noPages 
end

fmsFunctionsDefs["VIEWUPACARS"]["L6"]={"setpage","ACARSMSGS"}



----

fmsPages["VIEWACARSMSG"]=createPage("VIEWACARSMSG")
fmsPages["VIEWACARSMSG"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  acarsSystem.messages[acarsSystem.currentMessage]["read"]=true
  local msg=acarsSystem.messages[acarsSystem.currentMessage]
  local start=(pgNo-1)*168
  fmsPages["VIEWACARSMSG"]["template"]={

  "     ACARS-MESSAGE      ",
  "                        ",
  msg["title"],
  "                        ",
  string.sub(msg["msg"],start+1,start+24),
  string.sub(msg["msg"],start+25,start+48),
  string.sub(msg["msg"],start+49,start+72),
  string.sub(msg["msg"],start+73,start+96),
  string.sub(msg["msg"],start+97,start+120),
  string.sub(msg["msg"],start+121,start+144),
  string.sub(msg["msg"],start+145,start+168),
  "                        ",
  "<RETURN                 "
  }
  return fmsPages["VIEWACARSMSG"]["template"]
end
fmsPages["VIEWACARSMSG"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  local msg=acarsSystem.messages[acarsSystem.currentMessage]
  numPages=math.ceil(string.len(msg["msg"])/168)
  if numPages<1 then numPages=1 end
  fmsPages["VIEWACARSMSG"]["templateSmall"]={

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
  return fmsPages["VIEWACARSMSG"]["templateSmall"]
end
fmsPages["VIEWACARSMSG"].getNumPages=function(self)
  local msg=acarsSystem.messages[acarsSystem.currentMessage]
  noPages=math.ceil(string.len(msg["msg"])/168)
  if noPages<1 then noPages=1 end
  return noPages 
end
fmsFunctionsDefs["VIEWACARSMSG"]["L6"]={"setpage","ACARSMSGS"}