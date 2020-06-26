fmsPages["ACTDES"]=createPage("ACTDES")
fmsPages["ACTDES"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
    "     ACT ECON DES       ",
    "                        ",
    "  **** *****    ***/****",
    "                        ",
    ".***/***                ",
    "                        ",
    "***/*****               ",
    "                        ",
    "---/-----               ",
    "------------------------",
    "               FORECAST>", 
    "                        ",
    "OFFPATH DES     DES DIR>"
    }
end

fmsPages["ACTDES"].getSmallPage=function(self,pgNo,fmsID)
    return{
    "                    3/3 ",
    " E/D AT         AT *****",
    "                        ",
    " ECON SPD               ",
    "                        ",
    " SPD TRANS              ",
    "                        ",
    " SPD REST               ",
    "                        ",
    "                        ",
    "                        ", 
    "                        ",
    "                        "
    }
end


fmsFunctionsDefs["ACTDES"]={}
fmsFunctionsDefs["ACTDES"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["L4"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["L6"]={"setpage","OFFPATHDES"}
fmsFunctionsDefs["ACTDES"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTDES"]["R5"]={"setpage","DESCENTFORECAST"}
fmsFunctionsDefs["ACTDES"]["R6"]={"setpage","DESDIR"}
