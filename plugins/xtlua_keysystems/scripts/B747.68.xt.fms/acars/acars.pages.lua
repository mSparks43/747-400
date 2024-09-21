function convertToFMSLines(msg)
  local retVal={}
  local line=1
  local start=1
  local endI=string.len(msg)
  while start<endI do
    local cLine=string.sub(msg,start,start+24)
    local index = string.find(cLine, " [^ ]*$")
    if index~=nil and index > 10 then
      cLine=string.sub(msg,start,start+index-1)
      retVal[line]=cLine
      line=line+1
      start=start+index
    else
      retVal[line]=cLine
      line=line+1
      start=start+24
    end
  end
  return retVal
end


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
fmsFunctionsDefs["ACARS"]["L2"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["ACARS"]["L3"]={"setpage","POSTFLIGHT"}
fmsFunctionsDefs["ACARS"]["R1"]={"setpage","ACARSMSGS"}
fmsFunctionsDefs["ACARS"]["R2"]={"setpage","VHFCONTROL"}
fmsFunctionsDefs["ACARS"]["R3"]={"setpage","ACARSWEATHER"}
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
fmsFunctionsDefs["PREFLIGHT"]["R4"]={"setpage","ACARSWEATHER"}
fmsPages["POSTFLIGHT"]=createPage("POSTFLIGHT")
fmsPages["POSTFLIGHT"].getPage=function(self,pgNo,fmsID)
  local l1text="<LOGOFF "..fmsModules["data"]["atc"].."            "
  
  if fmsModules["data"]["atc"]=="****" then
    l1text="<LOGON                  "
    fmsFunctionsDefs["POSTFLIGHT"]["l1"]={"setpage","ATCLOGONSTATUS"} 
  else
    fmsFunctionsDefs["POSTFLIGHT"]["L1"]={"setdata","atc"}
  end
  local page={

    "  ACARS-POSTFLIGHT MENU ",
    "                        ",
    l1text,
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
    "<RETURN                 "
    }
    return page
end

fmsFunctionsDefs["POSTFLIGHT"]["L6"]={"setpage","ACARS"}
fmsPages["INITIALIZE"]=createPage("INITIALIZE")
fmsPages["INITIALIZE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  if getFMSData("crzalt")=="*****" then fmsModules[fmsID]["notify"]="CRUISE ALT NOT SET" end
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


  fmsPages["VIEWACARSLOG"].getPage=function(self,pgNo,fmsID)
    local page=acarsSystem.getMessageLog(pgNo)
    return page.template
  end
  fmsPages["VIEWACARSLOG"].getSmallPage=function(self,pgNo,fmsID) 
    local page=acarsSystem.getMessageLog(pgNo)
    return page.templateSmall
  end
  fmsPages["VIEWACARSLOG"].getNumPages=function(self)
    numPages=math.ceil(table.getn(acarsSystem.messages.values)/5)+math.ceil(table.getn(acarsSystem.messageSendQueue.values)/5)
    if numPages<1 then numPages=1 end
    return numPages 
  end
  fmsFunctionsDefs["VIEWACARSLOG"]["L6"]={"setpage","ATCINDEX"}
  fmsFunctionsDefs["VIEWACARSLOG"]["R6"]={"clearacars",""}
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
  fmsPages["VIEWDOWNACARS"].getPage=function(self,pgNo,fmsID)
    local page=acarsSystem.getDownMessages(pgNo)
    return page.template 
  end
  fmsPages["VIEWDOWNACARS"].getSmallPage=function(self,pgNo,fmsID) 
    local page=acarsSystem.getDownMessages(pgNo)
    return page.templateSmall 
  end
  fmsPages["VIEWDOWNACARS"].getNumPages=function(self)
    noPages=math.ceil(table.getn(acarsSystem.messageSendQueue.values)/4)
    if noPages<1 then noPages=1 end
    return noPages 
  end
  fmsFunctionsDefs["VIEWDOWNACARS"]["L6"]={"setpage","ACARSMSGS"}
  
  fmsPages["VIEWACARSMSG"]=createPage("VIEWACARSMSG")
  fmsPages["VIEWACARSMSG"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local currentMessage=acarsSystem.getCurrentMessage(fmsID)
    acarsSystem.messages[currentMessage]["read"]=true
    local msg=acarsSystem.messages[currentMessage]
   -- local start=(pgNo-1)*168
    local lLine="<RETURN                 "
    --if string.find(msg["msg"], "@") then
    if acarsSystem.messages[currentMessage]["rr"]~="N" and not acarsSystem.messages[currentMessage]["REPLIED"] then  
      --print (msg["msg"].." requiresRespond")
      lLine="<RETURN           REPLY>"
      fmsFunctionsDefs["VIEWACARSMSG"]["R6"]={"respondmessage",currentMessage}
    else
      fmsFunctionsDefs["VIEWACARSMSG"]["R6"]=nil
    end
    local msgLines=convertToFMSLines(msg["msg"])
    local start=(pgNo-1)*7
    local pageLines={}
    for i=1,7 do
      if start+i<=table.getn(msgLines) then
        pageLines[i]=msgLines[start+i]
      else
        pageLines[i]="                        "
      end
    end
    fmsPages["VIEWACARSMSG"]["template"]={
  
    "     ACARS-MESSAGE      ",
    "            "..msg["time"],
    msg["title"],
    "                        ",
    pageLines[1],--string.sub(msg["msg"],start+1,start+24),
    pageLines[2],--string.sub(msg["msg"],start+25,start+48),
    pageLines[3],--string.sub(msg["msg"],start+49,start+72),
    pageLines[4],--string.sub(msg["msg"],start+73,start+96),
    pageLines[5],--string.sub(msg["msg"],start+97,start+120),
    pageLines[6],--string.sub(msg["msg"],start+121,start+144),
    pageLines[7],--string.sub(msg["msg"],start+145,start+168),
    "                        ",
    lLine
    }
    return fmsPages["VIEWACARSMSG"]["template"]
  end
  fmsPages["VIEWACARSMSG"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local msg=acarsSystem.messages[acarsSystem.getCurrentMessage(fmsID)]
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
  fmsPages["VIEWACARSMSG"].getNumPages=function(self,fmsID)
    local msg=acarsSystem.messages[acarsSystem.getCurrentMessage(fmsID)]
    noPages=math.ceil(string.len(msg["msg"])/168)
    if noPages<1 then noPages=1 end
    return noPages 
  end
  fmsFunctionsDefs["VIEWACARSMSG"]["L6"]={"setpage","VIEWUPACARS"}

  
fmsPages["RESPONDACARSMSG"]=createPage("RESPONDACARSMSG")
fmsPages["RESPONDACARSMSG"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  local currentMessage=acarsSystem.getCurrentMessage(fmsID)
  local msg=acarsSystem.messages[currentMessage]

  fmsPages["RESPONDACARSMSG"]["template"]={

  "       ACARS-REPLY      ",
  "                        ",
  msg["title"],
  "                        ",
  "<WILCO                  ",
  "                        ",
  "<UNABLE DUE *****       ",
  "                        ",
  "                        ",
  "                        ",
  "<------          ------>",
  "                    "..fmsModules["data"]["atc"],
  "<RETURN            SEND>"
  }
  fmsFunctionsDefs["RESPONDACARSMSG"]["R6"]={"sendACARSmessage",currentMessage}
  fmsFunctionsDefs["RESPONDACARSMSG"]["L2"]={"setscratchpad","WILCO"}
  fmsFunctionsDefs["RESPONDACARSMSG"]["L3"]={"setscratchpad","UNABLE DUE "}
  return fmsPages["RESPONDACARSMSG"]["template"]
end
fmsPages["RESPONDACARSMSG"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  local pgNo=1
  local numPages=1
  fmsPages["RESPONDACARSMSG"]["templateSmall"]={
  
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
    return fmsPages["RESPONDACARSMSG"]["templateSmall"]
end
  dofile("acars/acars.pages.weatherrequest.lua")
