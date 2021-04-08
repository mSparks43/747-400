fmsPages["ACARSWEATHER"]=createPage("ACARSWEATHER")
fmsPages["ACARSWEATHER"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local dep="     "
    local dst="     "
    if fmsModules["data"]["atc"]==fmsModules.data["fltdep"] then dep="<"..fmsModules.data["fltdep"] end
    if fmsModules["data"]["atc"]==fmsModules.data["fltdst"] then dst=fmsModules.data["fltdst"]..">" end

    return {
        " ACARS WEATHER REQUEST  ",
        "                         ",
        dep.."               "..dst,
        "                         ",
        "                    ".. fmsModules["data"]["atc"] ..">",
        "                         ",
        "                         ",
        "                         ",
        "                         ",
        "                         ",
        "<MESSAGES          METAR>",
        "                         ",
        "<ACARS               TAF>",
        "                         "
        }
end

fmsPages["ACARSWEATHER"].getSmallPage=function(self,pgNo,fmsID)
    local dep="     "
    local dst="     "
    if fmsModules["data"]["atc"]~=fmsModules.data["fltdep"] then dep="<"..fmsModules.data["fltdep"] end
    if fmsModules["data"]["atc"]~=fmsModules.data["fltdst"] then dst=fmsModules.data["fltdst"]..">" end

    return {
        "                        ",
        "ORIGIN        DESTINATION",
        dep.."               "..dst,
        "                  AIRPORT",
        "                        ",
        "                        ",
        "                        ",
        "                        ",
        "                        ",
        "RECEIVED          REQUEST",
        "                        ",
        "RETURN TO         REQUEST",
        "                        ",
        "                        "
        } 
end  
fmsFunctionsDefs["ACARSWEATHER"]["L1"]={"setdata","fltdepatc"}
fmsFunctionsDefs["ACARSWEATHER"]["R1"]={"setdata","fltdstatc"}
fmsFunctionsDefs["ACARSWEATHER"]["L5"]={"setpage","VIEWUPACARS"}
fmsFunctionsDefs["ACARSWEATHER"]["L6"]={"setpage","ACARS"}
fmsFunctionsDefs["ACARSWEATHER"]["R2"]={"setdata","atc"}
fmsFunctionsDefs["ACARSWEATHER"]["R5"]={"setdata","metarreq"}
fmsFunctionsDefs["ACARSWEATHER"]["R6"]={"setdata","tafreq"}