fmsPages["DESCENTFORECAST"]=createPage("DESCENTFORECAST")
fmsPages["DESCENTFORECAST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "   DESCENT FORECAST     ",
 "                        ",
 "FL***              -----",
 "                        ",
 "FL***         ***°/***KT",
 "                        ",
 "FL***         ***°/***KT",
 "                        ",
 "****         ***°/***KT",
 "                        ",
 "                        ", 
 "                        ",
 "<SEND               DES>"
    }
end

fmsPages["DESCENTFORECAST"]["templateSmall"]={
"                        ",
" TRANS LVL    TAI/ON ALT",
"                        ",
" ALT                    ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"-----         ---°/---KT", 
" REQUEST----------------",
"                        "
}


  
  
fmsFunctionsDefs["DESCENTFORECAST"]={}
fmsFunctionsDefs["DESCENTFORECAST"]["L1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["L2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["L3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["L5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["L6"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DESCENTFORECAST"]["R6"]={"setpage","NOPAGE"}

