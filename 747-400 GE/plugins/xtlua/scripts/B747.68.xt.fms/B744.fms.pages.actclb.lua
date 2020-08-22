fmsPages["ACTCLB"]=createPage("ACTCLB")
fmsPages["ACTCLB"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
    "     ACT ECON CLB       ",
    "                        ",
    "FL***           ***/****",
    "                        ",
    "***/.***     350LO 2LONG",
    "                        ",
    "250/10000          *****",
    "                        ",
    "---/-----       ***/.***",
    "------------------------",
    "                ENG OUT>", 
    "                        ",
    "                CLB DIR>"
    }
end

fmsPages["ACTCLB"].getSmallPage=function(self,pgNo,fmsID)
    return{
    "                    1/3 ",
    " CRZ ALT        AT *****",
    "                        ",
    " ECON SPD   ERR AT *****",
    "                        ",
    " SPD TRANS     TRANS ALT",
    "                        ",
    " SPD REST      MAX ANGLE",
    "                        ",
    "                        ",
    "                        ", 
    "                        ",
    "                        "
    }
end


fmsFunctionsDefs["ACTCLB"]={}
fmsFunctionsDefs["ACTCLB"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["L4"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["L6"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTCLB"]["R5"]={"setpage","ENGOUT"}
fmsFunctionsDefs["ACTCLB"]["R6"]={"setpage","CLBDIR"}
