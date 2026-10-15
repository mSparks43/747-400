fmsPages["ARRIVALS"]=createPage("ARRIVALS")
fmsPages["ARRIVALS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "    **** ARRIVALS       ",
 "                        ",
 "                        ",
 "                        ",
 "                        ",
 "                        ",
 "                        ",
 "                        ",
 "                        ",
 "                        ",
 "                        ", 
 "------------------------",
 "<INDEX            ROUTE>"
    }
end

fmsPages["ARRIVALS"]["templateSmall"]={
"                    1/X ",
" STARS  RTE 1 APPROACHES",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ", 
"                        ",
"                        "
}


  
  
fmsFunctionsDefs["ARRIVALS"]={}
fmsFunctionsDefs["ARRIVALS"]["L1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["L2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["L3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["L4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["L5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["L6"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["R1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["R2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["R3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["R5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["ARRIVALS"]["R6"]={"setpage","NOPAGE"}