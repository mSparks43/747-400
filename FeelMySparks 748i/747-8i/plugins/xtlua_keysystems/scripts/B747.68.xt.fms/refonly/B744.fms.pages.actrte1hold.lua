fmsPages["ACTRTE1HOLD"]=createPage("ACTRTE1HOLD")
fmsPages["ACTRTE1HOLD"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "    ACT RTE 1 HOLD      ",
 "                        ",
 "*****        ***/FL*** ",
 "                        ",
 "**/***°          ****.*z",
 "                        ",
 "***°/L TURN             ",
 "                        ",
 "*.*                 ****",
 "                        ",
 "--.-               ***  ", 
 "------------------------",
 "<ERASE        EXIT HOLD>"
    }
end

fmsPages["ACTRTE1HOLD"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                    1/1 ",
" FIX         SPD/TGT ALT",
"                        ",
" QUAD/RADIAL     FIX ETA",
"                        ",
" ENBD CRS/DIR   EFC TIME",
"                   ----z",
" LEG TIME     HOLD AVAIL",
"   MIN                  ",
" LEG DIST     DEST SPEED",
"    NM                KT", 
"                        ",
"                        "
}
end

--[[

	
"  ACT RTE 1 LEGS    1/1 ",
" 130°TRK  3NM           ",	               
"SEAL 01       250/ 5000A",
" 101°     6NM           ",
"BOB 01        250/ 6289 ",
" 130°    12NM           ",
"SCOTT         250/ 7398 ",
" 149°    18NM           ",
"DONN          250/ 8721 ",
"         20NM           ",
"JERRY         250/ 9763 ",
"--------HOLD AT---------",
"*****              PPOS>" 
]]
  
fmsFunctionsDefs["ACTRTE1HOLD"]={}
--[[
fmsFunctionsDefs["ACTRTE1HOLD"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["L6"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1HOLD"]["R6"]={"setpage",""}
]]

