fmsPages["OPTIONS"]=createPage("OPTIONS")
fmsPages["ACMS"].getPage=function(self,pgNo,fmsID)

  return {
            
"    SIM OPTIONS INDEX   ",
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

fmsPages["CONFIG-ENGINES"]=createPage("CONFIG-ENGINES")
fmsPages["CONFIG-ENGINES"].getPage=function(self,pgNo,fmsID)

  return {
            
"     ENGINE OPTIONS     ",
"ENGINE MODEL            ",
"GE/PW/RR                ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ", 
"------------------------",
"<INDEX                  "
    }
end

fmsFunctionsDefs["CONFIG-SOUNDS"]["L6"]={"setpage","OPTIONS"}

fmsPages["CONFIG-SOUNDS"]=createPage("CONFIG-SOUNDS")
fmsPages["CONFIG-SOUNDS"].getPage=function(self,pgNo,fmsID)
  
  return {
            
"     SOUND OPTIONS      ",
"                        ",
"<GENERAL SOUND INFO     ",
"                        ",
"<COCKPIT                ",
"                        ",
"<CABIN                  ",
"                        ",
"<GPWS                   ",
"                        ",
"<SWITCHES               ", 
"------------------------",
"<INDEX                  "
    }
end

fmsFunctionsDefs["CONFIG-SOUNDS"]["L1"]={"setpage","SOUND-INFO"}
fmsFunctionsDefs["CONFIG-SOUNDS"]["L2"]={"setpage","SOUND-COCKPIT"}
fmsFunctionsDefs["CONFIG-SOUNDS"]["L3"]={"setpage","SOUND-CABIN"}
fmsFunctionsDefs["CONFIG-SOUNDS"]["L4"]={"setpage","SOUND-GPWS"}
fmsFunctionsDefs["CONFIG-SOUNDS"]["L5"]={"setpage","SOUND-SWITCHES"}
fmsFunctionsDefs["CONFIG-SOUNDS"]["L6"]={"setpage","OPTIONS"}

fmsPages["SOUND-INFO"]=createPage("SOUND-INFO")
fmsPages["SOUND-INFO"].getPage=function(self,pgNo,fmsID)

  return {
            
"       SOUND INFO       ",
"                        ",
"    FMOD SOUNDPACK      ",
"BY                      ",
"  MISTER FAHRENHEIT     ",
"VERSION                 ",
"0.1                     ",
"                        ",
"                        ",
"                        ",
"                        ", 
"------------------------",
"<RETURN                 "
    }
end

fmsFunctionsDefs["CONFIG-SOUNDS"]["L6"]={"setpage","CONFIG-SOUNDS"}
