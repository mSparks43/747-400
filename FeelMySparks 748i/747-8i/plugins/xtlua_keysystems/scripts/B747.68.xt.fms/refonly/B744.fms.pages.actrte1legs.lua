fmsPages["ACTRTE1LEGS"]=createPage("ACTRTE1LEGS")
fmsPages["ACTRTE1LEGS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"  ACT RTE 1 LEGS        ",
"                        ",               
"*****                   ",
"                        ",
"*****                   ",
"                        ",
"*****                   ",
"                        ",
"*****                   ",
"                        ",
"*****           ***/****",
"------------------------",
"<RTE 2 LEGS    RTE DATA>"
    }
end

fmsPages["ACTRTE1LEGS"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"  ACT RTE 1 LEGS    1/3 ",
" ***°HDG  *NM           ",               
"              ***/ **** ",
" ***°  ****NM           ",
"              ***/ **** ",
" ***°  ****NM           ",
"              ***/ **** ",
" ***°  ****NM           ",
"              ***/ **** ",
" ***°  ****NM           ",
"                        ",
"                        ",
"                        "
    }
end

  
fmsFunctionsDefs["ACTRTE1LEGS"]={}
--[[
fmsFunctionsDefs["ACTRTE1LEGS"]["L1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["L2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["L3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["L5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["L6"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R1"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R2"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R3"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R5"]={"setpage",""}
fmsFunctionsDefs["ACTRTE1LEGS"]["R6"]={"setpage",""}
]]

