fmsPages["DEPARRINDEX"]=createPage("DEPARRINDEX")
fmsPages["DEPARRINDEX"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "     DEP/ARR INDEX      ",
 "                        ",
 "<DEP  ****          ARR>",
 "                        ",
 "      ****          ARR>",
 "-----           --------",
 "<DEP  ****          ARR>",
 "                        ",
 "      ****          ARR>",
 "------------------------",
 "                        ", 
 " DEP  OTHER         ARR ",
 "<----              ---->"
    }
end

fmsPages["DEPARRINDEX"]["templateSmall"]={
"                        ",
"      RTE 1             ",
"                        ",
"                        ",
"                        ",
"     RTE 2              ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ", 
"                        ",
"                        "
}


  
  
fmsFunctionsDefs["DEPARRINDEX"]={}
fmsFunctionsDefs["DEPARRINDEX"]["L1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["L2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["L3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["L4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["L5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["L6"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["R1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["R2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["R3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["R5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["DEPARRINDEX"]["R6"]={"setpage","NOPAGE"}