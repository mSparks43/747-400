fmsPages["LEGS"]=createPage("LEGS")
fmsPages["LEGS"].getPage=function(self,pgNo,fmsID)
  
  local page={
    "     RTE LEGS           ",
    cleanFMSLine(B747DR_srcfms[fmsID][2]),
    cleanFMSLine(B747DR_srcfms[fmsID][3]),
    cleanFMSLine(B747DR_srcfms[fmsID][4]),
    cleanFMSLine(B747DR_srcfms[fmsID][5]),
    cleanFMSLine(B747DR_srcfms[fmsID][6]),
    cleanFMSLine(B747DR_srcfms[fmsID][7]),
    cleanFMSLine(B747DR_srcfms[fmsID][8]),
    cleanFMSLine(B747DR_srcfms[fmsID][9]),
    cleanFMSLine(B747DR_srcfms[fmsID][10]),
    cleanFMSLine(B747DR_srcfms[fmsID][11]),
    cleanFMSLine(B747DR_srcfms[fmsID][12]),
    cleanFMSLine(B747DR_srcfms[fmsID][13]),
  }
  return page 
  
end

fmsFunctionsDefs["LEGS"]["L1"]={"key2fmc","L1"}
fmsFunctionsDefs["LEGS"]["L2"]={"key2fmc","L2"}
fmsFunctionsDefs["LEGS"]["L3"]={"key2fmc","L3"}
fmsFunctionsDefs["LEGS"]["L4"]={"key2fmc","L4"}
fmsFunctionsDefs["LEGS"]["L5"]={"key2fmc","L5"}
fmsFunctionsDefs["LEGS"]["L6"]={"key2fmc","L6"}
fmsFunctionsDefs["LEGS"]["R1"]={"key2fmc","R1"}
fmsFunctionsDefs["LEGS"]["R2"]={"key2fmc","R2"}
fmsFunctionsDefs["LEGS"]["R3"]={"key2fmc","R3"}
fmsFunctionsDefs["LEGS"]["R4"]={"key2fmc","R4"}
fmsFunctionsDefs["LEGS"]["R5"]={"key2fmc","R5"}
fmsFunctionsDefs["LEGS"]["R6"]={"key2fmc","R6"}

fmsFunctionsDefs["LEGS"]["next"]={"key2fmc","next"}
fmsFunctionsDefs["LEGS"]["prev"]={"key2fmc","prev"}
fmsFunctionsDefs["LEGS"]["exec"]={"key2fmc","exec"}