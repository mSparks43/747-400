fmsPages["ATCREJECTDUETO"]=createPage("ATCREJECTDUETO")
fmsPages["ATCREJECTDUETO"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"      REJECT DUE TO     ",
"                        ",		               
"<                       ",
"                        ",
"<                       ",
"                        ",
"<                       ",
"                        ",
"                        ",
"<                       ",
"                        ",
"------------------------",
"<UPLINK          VERIFY>" 
    }
end

fmsPages["ATCREJECTDUETO"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                    1/1 ",
" DUE TO           DUE TO",		               
"<PERFORMANCE    WEATHER>",
" FREE TEXT              ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                RESPONSE",
"                        ",
"                        ",
"                        "
}
end

  
fmsFunctionsDefs["ATCREJECTDUETO"]={}
--[[
fmsFunctionsDefs["ATCREJECTDUETO"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCREJECTDUETO"]["R6"]={"setpage",""}
]]

