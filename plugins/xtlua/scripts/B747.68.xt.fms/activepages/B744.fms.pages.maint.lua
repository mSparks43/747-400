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
"                        ",
"                        ",
"                        ",
"                        ",
"<INDEX       SIM CONFIG>"
}


fmsFunctionsDefs["MAINT"]={}

fmsFunctionsDefs["MAINT"]["L1"]={"setpage","MAINTCROSSLOAD"}
fmsFunctionsDefs["MAINT"]["L2"]={"setpage","MAINTPERFFACTOR"}
fmsFunctionsDefs["MAINT"]["L3"]={"setpage","MAINTIRSMONITOR"}
fmsFunctionsDefs["MAINT"]["L6"]={"setpage","ACMS"}
fmsFunctionsDefs["MAINT"]["R1"]={"setpage","MAINTBITE"}
fmsFunctionsDefs["MAINT"]["R6"]={"setpage","MAINTSIMCONFIG"}


