fmsPages["POSINIT"]=createPage("POSINIT")
fmsPages["POSINIT"].getPage=function(self,pgNo,fmsID)
  if pgNo==1 then return {
    "       POS INIT    1/3  ",
    "	             LAST POS",
    "      ***`**.* ****`**.*",
    "REF AIRPORT             ",
    "-----                   ",
    "GATE                    ",
    "-----                   ",
    "UTC (GPS)        GPS POS",
    "****z ***`**.* ****`**.*",
    "SET HDG      SET IRS POS",
    "---`. ***`**.* ****`**.*", 
    "------------------------",
    "<INDEX            ROUTE>"
    } 
  end
  if pgNo==2 then return {
    "       POS REF     2/3  ",
    " FMS POS (GPS L)      GS",
    "***`**.* ****`**.* ***KT",
    "IRS (3)                 ",
    "***`**.* ****`**.*      ",
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
  if pgNo==3 then return {
    "       POS REF     3/3  ",
    " IRS L                GS",
    "***`**.* ****`**.* ***KT",
    " IRS C                  ",
    "***`**.* ****`**.* ***KT",
    " IRS R                  ",
    "***`**.* ****`**.* ***KT",
    " GPS L                  ",
    "***`**.* ****`**.* ***KT",
    "GPS R                   ",
    "***`**.* ****`**.* ***KT", 
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
fmsFunctionsDefs["POSINIT"]["R6"]={"setpage","ACTRTE1"}
