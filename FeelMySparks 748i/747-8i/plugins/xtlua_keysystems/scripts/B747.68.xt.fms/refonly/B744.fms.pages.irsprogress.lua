fmsPages["IRSPROGRESS"]=createPage("IRSPROGRESS")
fmsPages["IRSPROGRESS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"      IRS PROGRESS      ",
"                        ",		               
"                        ",
"                        ",
"*****     ***NM    **:**",
"                        ",
"*****     ***NM    **:**",
"                        ",
"*****     ***NM    **:**",
"                        ",
"***°*** ****°***   ***KT",
"                        ",  
"* *.*NM     ***°M  ***°M" 
    }
end

fmsPages["IRSPROGRESS"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                        ",
" LAST     ALT           ",		               
"CYN      FL***          ",
" TO       DTG           ",
"                        ",
" NEXT                   ",
"                        ",
" DEST                   ",
"                        ",
" IRS R                GS",
"                        ",
" XTK ERROR   DTK      TK", 
"                        " 
    }
end


  
fmsFunctionsDefs["IRSPROGRESS"]={}
--[[
fmsFunctionsDefs["IRSPROGRESS"]["L1"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["L2"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["L3"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R4"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["L5"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["L6"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R1"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R2"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R3"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R4"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R5"]={"setpage",""}
fmsFunctionsDefs["IRSPROGRESS"]["R6"]={"setpage",""}
]]

