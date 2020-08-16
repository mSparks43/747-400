fmsPages["MAINT"]=createPage("MAINT")
fmsPages["MAINT"]["template"]={

"  MAINTENANCE INDEX 1/1 ",
"                        ",
"<CROSSLOAD         BITE>",
"                        ",
"<PERF FACTOR            ",
"                        ",
"<IRS MONITOR            ",
"                        ",
"<VNAV CONFIG            ",
"                        ",
"                        ", 
"                        ",
"<INDEX                  "
}


fmsFunctionsDefs["MAINT"]={}

fmsFunctionsDefs["MAINT"]["L1"]={"setpage","MAINTCROSSLOAD"}
fmsFunctionsDefs["MAINT"]["L2"]={"setpage","MAINTPERFFACTOR"}
fmsFunctionsDefs["MAINT"]["L3"]={"setpage","MAINTIRSMONITOR"}
fmsFunctionsDefs["MAINT"]["L4"]={"setpage","VNAVCONFIG"}
fmsFunctionsDefs["MAINT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["MAINT"]["R1"]={"setpage","MAINTBITE"}

fmsPages["VNAVCONFIG"]=createPage("VNAVCONFIG")
fmsPages["VNAVCONFIG"].getPage=function(self,pgNo,fmsID)
  local lineA="<ENABLE XPLANE VNAV     "
  local LineB="<ENABLE CUSTOM VNAV     "
  	
  if B747DR_ap_vnav_system == 1.0 then
      lineA="<DISABLE XPLANE VNAV    "
  elseif B747DR_ap_vnav_system == 2.0 then
      LineB="<DISABLE CUSTOM VNAV    "
  end
  return {

  "       VNAV CONFIG      ",
  "                        ",
  lineA,
  "                        ",
  LineB,
  "                        ",
  "                        ",
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