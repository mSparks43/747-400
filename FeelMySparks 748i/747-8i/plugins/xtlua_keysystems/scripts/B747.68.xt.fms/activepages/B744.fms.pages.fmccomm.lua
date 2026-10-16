fmsPages["FMCCOMM"]=createPage("FMCCOMM")
fmsPages["FMCCOMM"].getPage=function(self,pgNo,fmsID)
  local data= "OFFLINE"
  if acarsSystem.provider.online() then data="  READY" end
  if pgNo==1 then 
    fmsFunctionsDefs["FMCCOMM"]["R1"]={"setpage","POSREPORT"}
    return {
"        FMC COMM        ",
"                        ",		               
"<RTE 1       POS REPORT>",
"                        ",
"<DES FORECAST           ",
"                        ",
"<RTE DATA               ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                 "..data
    }
  elseif pgNo==2 then 
    fmsFunctionsDefs["FMCCOMM"]["R1"]=nil
    return {
"        FMC COMM        ",
"                        ",	               
"<SEND         ----------",
"                        ",
"<SEND                   ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                 "..data
    }
end
end

fmsPages["FMCCOMM"].getSmallPage=function(self,pgNo,fmsID)
  if pgNo==1 then 
    return {
"                    1/2 ",
"                        ",		               
"                        ",
" UPLINK                 ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"               DATA LINK",
"                        " 
}
elseif pgNo==2 then 
  
  return {
"                    2/2 ",
" RTE REQUEST    CO ROUTE",		               
"                        ",
" WIND REQUEST           ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"               DATA LINK",
"                        "
    } 
end
end
fmsPages["FMCCOMM"].getNumPages=function(self)
  return 2 
end
  
fmsFunctionsDefs["FMCCOMM"]={}
fmsFunctionsDefs["FMCCOMM"]["L1"]={"setpage","RTE1"}
--[[
fmsFunctionsDefs["FMCCOMM"]["L1"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["L2"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["L3"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R4"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["L5"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["L6"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R1"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R2"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R3"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R4"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R5"]={"setpage",""}
fmsFunctionsDefs["FMCCOMM"]["R6"]={"setpage",""}
]]

