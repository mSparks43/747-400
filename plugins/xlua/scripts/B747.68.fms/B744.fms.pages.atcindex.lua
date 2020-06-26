fmsPages["ATCINDEX"]=createPage("ATCINDEX")
fmsPages["ATCINDEX"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"       ATC INDEX        ",
"                        ",	               
"<EMERGENCY   POS REPORT>",
"                        ",
"<REQUEST    WHEN CAN WE>",
"                        ",
"<REPORT                 ",
"                        ",
"<LOG          CLEARANCE>",
"                        ",
"<LOGON/STATUS     VOICE>",
"------------------------",
"<PRINT LOG              "
    }
end


  
fmsFunctionsDefs["ATCINDEX"]={}
--[[
fmsFunctionsDefs["ATCINDEX"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCINDEX"]["R6"]={"setpage",""}
]]

