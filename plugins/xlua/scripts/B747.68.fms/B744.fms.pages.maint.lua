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
"                        ",
"                        ",
"                        ", 
"                        ",
"<INDEX                  "
    }


fmsFunctionsDefs["MAINT"]={}
fmsFunctionsDefs["MAINT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["MAINT"]["L1"]={"setpage","MAINTCROSSLOAD"}
fmsFunctionsDefs["MAINT"]["L2"]={"setpage","MAINTPERFFACTOR"}
fmsFunctionsDefs["MAINT"]["L3"]={"setpage","MAINTIRSMONITOR"}
fmsFunctionsDefs["MAINT"]["R1"]={"setpage","MAINTBITE"}
