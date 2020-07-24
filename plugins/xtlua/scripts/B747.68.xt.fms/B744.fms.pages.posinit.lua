fmsPages["POSINIT"]=createPage("POSINIT")

fmsPages["POSINIT"].getPage=function(self,pgNo,fmsID)
  if pgNo==1 then
    
    fmsFunctionsDefs["POSINIT"]["L2"]={"setdata","airportpos"}
    fmsFunctionsDefs["POSINIT"]["R1"]={"getdata","lastpos"}
    fmsFunctionsDefs["POSINIT"]["R4"]={"getdata","gpspos"}
    fmsFunctionsDefs["POSINIT"]["R5"]={"setdata","irspos"}
    fmsFunctionsDefs["POSINIT"]["R6"]={"setpage","RTE1"}
    return {
    "       POS INIT    1/3  ",
    "	             LAST POS",
    "      ".. irsSystem.calcLatA() .." "..irsSystem.calcLonA(),
    "REF AIRPORT             ",
    fmsModules["data"]["airportpos"].."                   ",
    "GATE                    ",
    fmsModules["data"]["airportgate"].."                   ",
    "UTC (GPS)        GPS POS",
    string.format("%02d%02dz ",hh,mm).. irsSystem.getLat("gpsL") .." " .. irsSystem.getLon("gpsL"),
    "SET HDG      SET IRS POS",
    "---` "..irsSystem.getLatPos().." "..irsSystem.getLonPos(), 
    "------------------------",
    "<INDEX            ROUTE>"
    } 
  end
  if pgNo==2 then 
    fmsFunctionsDefs["POSINIT"]["R1"]=nil
    fmsFunctionsDefs["POSINIT"]["R4"]=nil
    fmsFunctionsDefs["POSINIT"]["R5"]=nil
    fmsFunctionsDefs["POSINIT"]["R6"]=nil
    return {
    "       POS REF     2/3  ",
    " FMS POS (GPS L)      GS",
    irsSystem.getLine("gpsL"),
    "IRS (3)                 ",
    irsSystem.calcLatA().." ".. irsSystem.calcLonA() .."      ",
    "RNP/ACTUAL       DME/DME",
    "***.**/**.**NM **** ****",
    "                        ",
    "                        ",
    "-----------------GPS NAV",
    "<PURGE          INHIBIT>", 
    "                        ",
    "<INDEX         BRG/DIST>"
    } 
  end
  if pgNo==3 then 
     fmsFunctionsDefs["POSINIT"]["R1"]=nil
    fmsFunctionsDefs["POSINIT"]["R4"]=nil
    fmsFunctionsDefs["POSINIT"]["R5"]=nil
    fmsFunctionsDefs["POSINIT"]["R6"]=nil
    return {
    "       POS REF     3/3  ",
    " IRS L                GS",
    irsSystem.getLine("irsL"),
    " IRS C                  ",
    irsSystem.getLine("irsC"),
    " IRS R                  ",
    irsSystem.getLine("irsR"),
    " GPS L                  ",
    irsSystem.getLine("gpsL"),
    "GPS R                   ",
    irsSystem.getLine("gpsR"), 
    "------------------------",
    "<INDEX         BRG/DIST>"
    } 
  end
end

fmsPages["POSINIT"].getNumPages=function(self)
  return 3 
end
fmsFunctionsDefs["POSINIT"]={}
fmsFunctionsDefs["POSINIT"]["L6"]={"setpage","INITREF"}

