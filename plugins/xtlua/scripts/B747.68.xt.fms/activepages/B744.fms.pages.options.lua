fmsPages["OPTIONS"]=createPage("OPTIONS")
fmsPages["ACMS"].getPage=function(self,pgNo,fmsID)

  return {
            
"   SIMULATION OPTIONS   ",
"                        ",
"<ENGINES                ",
"                        ",
"<SOUND OPTIONS          ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ", 
"------------------------",
"<MENU                   "
    }
end
fmsFunctionsDefs["OPTIONS"]["L1"]={"setpage","CONFIG-ENGINES"}
fmsFunctionsDefs["OPTIONS"]["L2"]={"setpage","CONFIG-SOUNDS"}
fmsFunctionsDefs["OPTIONS"]["L6"]={"setpage","INDEX"}
