fmsPages["MAINTIRSMONITOR"]=createPage("MAINTIRSMONITOR")
fmsPages["MAINTIRSMONITOR"].getPage=function(self,pgNo,fmsID)
  return {

  "      IRS MONITOR   1/1 ",
  "                        ",
  "                        ",
  " IRS L                  ",
  irsSystem.getStatus("irsL"),
  " IRS C                  ",
  irsSystem.getStatus("irsC"),
  " IRS R                  ",
  irsSystem.getStatus("irsR"),
  "                        ",
  "                        ", 
  "                        ",
  "<INDEX                  "
      }
end

fmsFunctionsDefs["MAINTIRSMONITOR"]={}
fmsFunctionsDefs["MAINTIRSMONITOR"]["L6"]={"setpage","INITREF"}
