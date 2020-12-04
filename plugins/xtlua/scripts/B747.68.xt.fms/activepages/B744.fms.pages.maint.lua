fmsPages["MAINT"]=createPage("MAINT")
fmsPages["MAINT"]["template"]={

"   MAINTENANCE INDEX 1/1",
"                        ",
"<CROS LOAD         BITE>",
"                        ",
"<PERF FACTOR            ",
"                        ",
"<IRS MONITOR            ",
"                        ",
"<VNAV CONFIG            ",
"                        ",
"                        ",
"                        ",
"<INDEX       SIM CONFIG>"
}


fmsFunctionsDefs["MAINT"]={}

fmsFunctionsDefs["MAINT"]["L1"]={"setpage","MAINTCROSSLOAD"}
fmsFunctionsDefs["MAINT"]["L2"]={"setpage","MAINTPERFFACTOR"}
fmsFunctionsDefs["MAINT"]["L3"]={"setpage","MAINTIRSMONITOR"}
fmsFunctionsDefs["MAINT"]["L4"]={"setpage","VNAVCONFIG"}
fmsFunctionsDefs["MAINT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["MAINT"]["R1"]={"setpage","MAINTBITE"}
fmsFunctionsDefs["MAINT"]["R6"]={"setpage","MAINTSIMCONFIG"}

fmsPages["VNAVCONFIG"]=createPage("VNAVCONFIG")
fmsPages["VNAVCONFIG"].getPage=function(self,pgNo,fmsID)
  local lineA="<ENABLE XPLANE VNAV     "
  local LineB="<ENABLE CUSTOM VNAV     "
  local LineC="<ENABLE PAUSE AT T/D    "	
  if B747DR_ap_vnav_system == 1.0 then
      lineA="<DISABLE XPLANE VNAV    "
  elseif B747DR_ap_vnav_system == 2.0 then
      LineB="<DISABLE CUSTOM VNAV    "
  end
  if B747DR_ap_vnav_pause ==1.0 then 
      LineC="<DISABLE PAUSE AT T/D   "
  end
  return {

  "       VNAV CONFIG      ",
  "                        ",
  lineA,
  "                        ",
  LineB,
  "                        ",
  LineC,
  "                        ",
  "                        ",
  "                        ",
  "                        ", 
  "                        ",
  "                        "
  }
end
fmsFunctionsDefs["VNAVCONFIG"]["L1"]={"setDref","VNAVS1"}
fmsFunctionsDefs["VNAVCONFIG"]["L2"]={"setDref","VNAVS2"}
fmsFunctionsDefs["VNAVCONFIG"]["L3"]={"setDref","VNAVSPAUSE"}
