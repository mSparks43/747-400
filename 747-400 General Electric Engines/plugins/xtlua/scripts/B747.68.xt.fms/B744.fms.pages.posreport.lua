fmsPages["POSREPORT"]=createPage("POSREPORT")
fmsPages["POSREPORT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"           POS REPORT   ",
"                        ",	               
"*********          ****z",
"                        ",
"FL***                .**",
"                        ",
"*****              ****z",
"                        ",
"*********          ****z",
"                        ",
"-**°   ***°/***KT  ***.*",
"                        ",
"<SEND              SEND>" 
    }
end

fmsPages["POSREPORT"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                        ",
" LAST                ATA",	               
"                        ",
" ALT                 SPD",
"                        ",
" TO                  ETA",
"                        ",
" NEXT            EST ETA",
"                        ",
" TEMP     WIND      FUEL",
"    C                   ",
" COMPANY ----------- ATC",
"                        " 
    }
end


  
fmsFunctionsDefs["POSREPORT"]={}
--[[
fmsFunctionsDefs["POSREPORT"]["L1"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L2"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L3"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L5"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L6"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R1"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R2"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R3"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R5"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R6"]={"setpage",""}
]]

