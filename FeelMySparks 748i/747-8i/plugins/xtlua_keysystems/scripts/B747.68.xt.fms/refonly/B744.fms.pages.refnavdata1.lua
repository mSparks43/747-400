fmsPages["REFNAVDATA1"]=createPage("REFNAVDATA1")
fmsPages["REFNAVDATA1"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "  REF NAV DATA          ",
 "                        ",
 "***               ***.**",
 "                        ",
 "***°**.*       ****°**.*",
 "                        ",
 "***               ******",
 "                        ",
 "                        ",
 "                        ",
 "----                ----", 
 "-------------VOR/DME NAV",
 "<INDEX          INHIBIT>"
    }
end

fmsPages["REFNAVDATA1"]["templateSmall"]={
"                        ",
" IDENT              FREQ",
"                        ",
" LATITUDE      LONGITUDE",
"                        ",
" MAG VAR       ELEVATION",
"                        ",
"     NAVAID INHIBIT     ",
"----                ----",
"    VOR ONLY INHIBIT    ",
"                        ", 
"                        ",
"                        "
}


  
  
fmsFunctionsDefs["REFNAVDATA1"]={}
--[[
fmsFunctionsDefs["REFNAVDATA1"]["L1"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["L2"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["L3"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["R4"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["L5"]={"setpage",""}
]]
fmsFunctionsDefs["REFNAVDATA1"]["L6"]={"setpage","INDEX"}
--[[
fmsFunctionsDefs["REFNAVDATA1"]["R1"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["R2"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["R3"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["R4"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["R5"]={"setpage",""}
fmsFunctionsDefs["REFNAVDATA1"]["R6"]={"setpage",""}
]]
