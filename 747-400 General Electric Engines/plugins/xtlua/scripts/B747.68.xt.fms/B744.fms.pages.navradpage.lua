fmsPages["NAVRADPAGE"]=createPage("NAVRADPAGE")
fmsPages["NAVRADPAGE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
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

fmsPages["NAVRADPAGE"]["templateSmall"]={
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


  
  
fmsFunctionsDefs["NAVRADPAGE"]={}
--[[
fmsFunctionsDefs["NAVRADPAGE"]["L1"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["L2"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["L3"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["R4"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["L5"]={"setpage",""}
]]
fmsFunctionsDefs["NAVRADPAGE"]["L6"]={"setpage","INDEX"}
--[[
fmsFunctionsDefs["NAVRADPAGE"]["R1"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["R2"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["R3"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["R4"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["R5"]={"setpage",""}
fmsFunctionsDefs["NAVRADPAGE"]["R6"]={"setpage",""}
]]
