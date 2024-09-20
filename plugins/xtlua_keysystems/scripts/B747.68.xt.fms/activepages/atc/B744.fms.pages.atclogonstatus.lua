fmsPages["ATCLOGONSTATUS"]=createPage("ATCLOGONSTATUS")
fmsPages["ATCLOGONSTATUS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local logon="   N/A  "
    local data= "OFFLINE"
    if netstatusDataref>0 or string.len(acarsReceiveDataref)>1 then
        data=" ACTIVE"
    elseif acarsSystem.provider.online() then 
	    logon=acarsSystem.provider.loggedOn()
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
"<SELECT OFF         "..fmsModules["data"]["curCTR"],
"                        ",
"                    "..fmsModules["data"]["nextCTR"],
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
" ADS (ACT)     ADS EMERG",
"                        ",
"----------------DATALINK",
"                        "
    }
end


fmsFunctionsDefs["ATCLOGONSTATUS"]={}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L6"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L1"]={"setdata","atc"}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L2"]={"setdata","fltno"}
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

