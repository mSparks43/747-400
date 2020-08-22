fmsPages["ACTCRZ"]=createPage("ACTCRZ")
fmsPages["ACTCRZ"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
    "     ACT ECON CRZ       ",
    "                        ",
    "FL***              FL***",
    "                        ",
    ".***       ****z /****NM",
    "                        ",
    "**.*        ****z /***.*",
    "                        ",
    "ICAO      FL***    FL***",
    "------------------------",
    "                ENG OUT>", 
    "                        ",
    "<RTA PROGRESS       LRC>"
    }
end

fmsPages["ACTCRZ"].getSmallPage=function(self,pgNo,fmsID)
    return{
    "                    2/3 ",
    " CRZ ALT         STEP TO",
    "                        ",
    " ECON SPD             AT",
    "                        ",
    " N1        KATL ETA/FUEL",
    "                        ",
    " STEP SITE OPT       MAX",
    "                        ",
    "                        ",
    "                        ", 
    "                        ",
    "                        "
    }
end


fmsFunctionsDefs["ACTCRZ"]={}
fmsFunctionsDefs["ACTCRZ"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["L4"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["L6"]={"setpage","RTAPROGRESS"}
fmsFunctionsDefs["ACTCRZ"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTCRZ"]["R5"]={"setpage","ENGOUT"}
fmsFunctionsDefs["ACTCRZ"]["R6"]={"setpage","LRC"}
