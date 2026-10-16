fmsPages["ACTRTE1WINDS"]=createPage("ACTRTE1WINDS")
fmsPages["ACTRTE1WINDS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"    NOLLA WINDS         ",
"                        ",               
"-----                   ",
"                        ",
"                        ",
"                        ",
"****    **°C  ***°/ **KT",
"                        ",
"FL***  -**°C  ***°/ **KT",
"                        ",
"                 ----/--",
"------------------------",
"               RTE DATA>" 
    }
end

fmsPages["ACTRTE1WINDS"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                   5/11 ",
"ALT    OAT       DIR/SPD",	               
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                 ALT/OAT",
"                        ",
"                        ",
"                        " 
}
end

  
fmsFunctionsDefs["ACTRTE1WINDS"]={}
--[[
fmsFunctionsDefs["ACTRTE1WINDS"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["L6"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1WINDS"]["R6"]={"setpage",""}
]]

