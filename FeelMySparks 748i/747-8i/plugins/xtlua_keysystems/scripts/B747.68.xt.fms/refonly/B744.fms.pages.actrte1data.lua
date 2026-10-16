fmsPages["ACTRTE1DATA"]=createPage("ACTRTE1DATA")
fmsPages["ACTRTE1DATA"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"  ACT RTE 1 DATA        ",
"                        ",	               
"      LACRE           W>",
"                        ",
"      VAMPS            >",
"                        ",
"      PAE               ",
"                        ",
"      CF13R            >",
"                        ",
"      NOLLA           W>",
"                        ",
"<LEGS              SEND>" 
    }
end

fmsPages["ACTRTE1DATA"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                    1/3 ",
" ETA    WPT   FUEL  WIND",	               
"1037z          43.5    >",
"                        ",
"1039z          43.3    >",
"                        ",
"1043z          42.4     ",
"                        ",
"1045z          42.3    >",
"                        ",
"1048z          42.1   W>",
"-----------------REQUEST",
"                        " 
}
end

  
fmsFunctionsDefs["ACTRTE1DATA"]={}
--[[
fmsFunctionsDefs["ACTRTE1DATA"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["L6"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1DATA"]["R6"]={"setpage",""}
]]

