fmsPages["FIXINFO"]=createPage("FIXINFO")
fmsPages["FIXINFO"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"       FIX INFO         ",
"                        ",		               
"NOLLA    065/11         ",
"                        ",
"340/12    1537z  21     ",
"                        ",
"309/6     1538z  29     ",
"                        ",
"---/---                 ",
"                        ",
"049/10   1533z  1.1     ",
"                        ",
"<ERASE FIX         -----"  
    }
end

fmsPages["FIXINFO"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                    1/2 ",
" FIX   BRG/DIS  FR      ",		               
"                        ",
" BRG/DIS   ETA  DTG  ALT",
"                    4850",
"                        ",
"                    2600",
"                        ",
"                        ",
" ABEAM                  ",
"                    6000",
"            PRED ETA-ALT",
"                        "
}
end

  
fmsFunctionsDefs["FIXINFO"]={}
--[[
fmsFunctionsDefs["FIXINFO"]["L1"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["L2"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["L3"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R4"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["L5"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["L6"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R1"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R2"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R3"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R4"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R5"]={"setpage",""}
fmsFunctionsDefs["FIXINFO"]["R6"]={"setpage",""}
]]

