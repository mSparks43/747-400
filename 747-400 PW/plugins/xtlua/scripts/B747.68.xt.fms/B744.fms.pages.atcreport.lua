fmsPages["ATCREPORT"]=createPage("ATCREPORT")
fmsPages["ATCREPORT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"       ATC INDEX        ",
"                        ",	               
"<RTE REPORT   FREE TEXT>",
"                        ",
"<CONFIRM ALTITUDE       ",
"                        ",
"<REPORT PASSING GGW     ",
"                        ",
"<WHEN CAN YOU ACCEPT F..",
"                        ",
"<REPORT REACHING FL350  ",
"------------------------",
"<INDEX                  "
    }
end

fmsPages["ATCREPORT"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                    1/1 ",
" ATC                    ",	               
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
" ARMED                  ",
"                        ",
"                        ",
"                        "
    }
end


  
fmsFunctionsDefs["ATCREPORT"]={}
fmsFunctionsDefs["ATCREPORT"]["L6"]={"setpage","ATCINDEX"}
--[[
fmsFunctionsDefs["ATCREPORT"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R6"]={"setpage",""}
]]

