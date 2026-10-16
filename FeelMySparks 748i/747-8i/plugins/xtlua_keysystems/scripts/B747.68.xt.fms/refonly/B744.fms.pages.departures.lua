fmsPages["DEPARTURES"]=createPage("DEPARTURES")
fmsPages["DEPARTURES"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "   **** DEPARTURES      ",
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

fmsPages["DEPARTURES"]["templateSmall"]={
"                    1/2 ",
" SIDS    RTE 1   RUNWAYS",
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


  
  
fmsFunctionsDefs["DEPARTURES"]={}
fmsFunctionsDefs["DEPARTURES"]["L1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["L2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["L3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["L4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["L5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["L6"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["R1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["R2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["R3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["R5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARTURES"]["R6"]={"setpage","NOPAGE"}