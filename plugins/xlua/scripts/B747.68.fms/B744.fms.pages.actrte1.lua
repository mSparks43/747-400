fmsPages["ACTRTE1"]=createPage("ACTRTE1")
fmsPages["ACTRTE1"].getPage=function(self,pgNo,fmsID)
  if pgNo==1 then return {
    "      ACT RTE 1         ",
    "                        ",
    ""..fmsModules["data"]["origin"] .."                "..fmsModules["data"]["destination"] ,
    "                        ",
    ""..fmsModules["data"]["runway"] .."             "..fmsModules["data"]["flightnumber"] ,
    "                        ",
    "<SEND              "..fmsModules["data"]["coroute"] ,
    "             -----------",
    "<LOAD                   ",
    "                        ",
    "<RTE COPY          SEND>", 
    "                        ",
    "<RTE 2        PERF INIT>"
    }
  elseif pgNo==2 then return {
    "      ACT RTE 1         ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ", 
    "------------------------",
    "<RTE 2        PERF INIT>"
    }
end
end

fmsPages["ACTRTE1"].getSmallPage=function(self,pgNo,fmsID)
  if pgNo==1 then return {
"                    1/3 ",
" ORIGIN             DEST",
"                        ",
" RUNWAY           FLT NO",
"                        ",
" REQUEST        CO ROUTE",
"                        ",
"ROUTE UPLINK -----------",
"                        ",
"               CO REPORT",
"                        ", 
"                        ",
"                        "
}
elseif pgNo==2 then return {
    "                    2/3 ",
    " VIA                  TO",
    "                        ",
    "                        ",
    "                        ",
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
end


fmsFunctionsDefs["ACTRTE1"]={}
fmsFunctionsDefs["ACTRTE1"]["L1"]={"setdata","origin"}
fmsFunctionsDefs["ACTRTE1"]["L2"]={"setdata","runway"}
fmsFunctionsDefs["ACTRTE1"]["L3"]={"setpage","SEND"}
fmsFunctionsDefs["ACTRTE1"]["L4"]={"setpage","LOAD"}
fmsFunctionsDefs["ACTRTE1"]["L5"]={"setpage","RTECOPY"}
fmsFunctionsDefs["ACTRTE1"]["L6"]={"setpage","ACTRTE2"}
fmsFunctionsDefs["ACTRTE1"]["R1"]={"setdata","destination"}
fmsFunctionsDefs["ACTRTE1"]["R2"]={"setdata","flightnumber"}
fmsFunctionsDefs["ACTRTE1"]["R3"]={"setdata","coroute"}
fmsFunctionsDefs["ACTRTE1"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1"]["R5"]={"setpage","SEND"}
fmsFunctionsDefs["ACTRTE1"]["R6"]={"setpage","PERFINIT"}
