fmsPages["PROGRESS"]=createPage("PROGRESS")
fmsPages["PROGRESS"].getPage=function(self,pgNo,fmsID)
  local l13="                        "
  if pgNo==1 then
        l13="                POS REF>"
	fmsFunctionsDefs["PROGRESS"]["R6"]={"setpage_no","POSINIT_2"}
  else
    fmsFunctionsDefs["PROGRESS"]["R6"]=nil
  end
  
  local page={
  cleanFMSLine(B747DR_srcfms[fmsID][1]),
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
  l13,
  }
  return page 
  
end

--[[
if pgNo==1 then return {
    "          PROGRESS      ",
    " LAST   ALT   ATA   FUEL",
    "                        ",
    "                        ",
    "***      *** ****Z  **.*",
    "                        ",
    "***      *** ****Z  **.*",
    "                        ",
    "****     *** ****Z  **.*",
    "                        ",
    ".***         ****z/***NM", 
    "------------------------",
    "<POS REPORT     POS REF>"
    }
  elseif pgNo==2 then return {
    "          PROGRESS      ",
    "                        ",
    " **KT   ***°/**   L **KT",
    "                        ",
    "L *.*              +**FT",
    "                        ",
    "***                -**° ",
    "                        ",
    " **.*  **.*   **.*  **.*",
    "                        ",
	"<USE                USE>",
    "                        ", 
    " **.*               **.*"
    }
  elseif pgNo==3 then return {
    "  ACT RTA PROGRESS      ",
    "                        ",
    "DENOH           1740.0zB",
    "                        ",
    ".878      FL370/1734.5z ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
	".890                    ",
    "------------------------", 
    "                        "
    }
end


fmsPages["PROGRESS"].getSmallPage=function(self,pgNo,fmsID)
  if pgNo==1 then return {
"                    1/3 ",
" LAST   ALT   ATA   FUEL",
"***    FL*** ****Z  **.*",
" TO      DTG  ETA       ",
"                        ",
" NEXT                   ",
"                        ",
" DEST                   ",
"                        ",
" SEL SPD          TO T/D",
"                        ", 
"                        ",
"                        "
}
elseif pgNo==2 then return {
    "                    2/3 ",
    " H/WIND   WIND    X/WIND",
    "                        ",
    " XTK ERROR     VTK ERROR",
    "     NM                 ",
    " TAS    FUEL USED    SAT",
    "   KT   TOT ***.*      C",
    "   1     2      3     4 ",
    "                        ",
    "                        ",   
    "        FUEL QTY        ",
    " TOTALIZER    CALCULATED", 
    "                        "
    } 
	elseif pgNo==3 then return {
    "                    3/3 ",
    "                        ",
    " FIX                 RTA",
    "                        ",
    " RTA SPD         ALT/ETA",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    " MAX SPD                ",
	"                        ",
    "                        ", 
    "                        "
    }
end
end]]


fmsFunctionsDefs["PROGRESS"]={}
fmsFunctionsDefs["PROGRESS"]["next"]={"custom2fmc","next"}
fmsFunctionsDefs["PROGRESS"]["prev"]={"custom2fmc","prev"}
fmsFunctionsDefs["PROGRESS"]["exec"]={"custom2fmc","exec"}
--[[
fmsFunctionsDefs["PROGRESS"]["L1"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["L2"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["L3"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["L4"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["L5"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["L6"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["R1"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["R2"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["R3"]={"setdata",""}
fmsFunctionsDefs["PROGRESS"]["R4"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["R5"]={"setpage",""}
fmsFunctionsDefs["PROGRESS"]["R6"]={"setpage",""}
]]