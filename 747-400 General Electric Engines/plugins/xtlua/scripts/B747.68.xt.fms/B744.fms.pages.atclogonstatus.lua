fmsPages["ATCLOGONSTATUS"]=createPage("ATCLOGONSTATUS")
fmsPages["ATCLOGONSTATUS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local logon="   N/A  "	
    local data= "OFFLINE"
    if acarsSystem.provider.online() then 
      if fmsModules["data"]["atc"]~="****" then 
	logon="ACCEPTED"
      else
	logon="   READY"
      end
      
      data="  READY" 
    else
      fmsModules["data"]["atc"]="****"
    end
    return{

"    ATC LOGON/STATUS    ",
"                        ",	               
fmsModules["data"]["atc"].."            "..logon,
"                        ",
fmsModules["data"]["fltno"].."                 ",
"                        ",
"<SELECT OFF         ****",
"                        ",
"                    ****",
"                        ",
"<SELECT OFF   SELECT ON>",
"                        ",
"<INDEX           "..data
    }
end

fmsPages["ATCLOGONSTATUS"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
  
"                        ",
" LOGON TO          LOGON",	               
"                        ",
" FLT NO                 ",
"                        ",
" ATC COMM        ACT CTR",
"                        ",
"                NEXT CTR",
"                        ",
" ADS (ACT)     ADS ENERG",
"                        ",
"----------------DATALINK",
"                        "
    }
end


fmsFunctionsDefs["ATCLOGONSTATUS"]={}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L6"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L1"]={"setdata","atc"}
--[[
fmsFunctionsDefs["ATCLOGONSTATUS"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R6"]={"setpage",""}
]]

