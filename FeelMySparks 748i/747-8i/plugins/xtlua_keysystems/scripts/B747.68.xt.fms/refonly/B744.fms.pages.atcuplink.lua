fmsPages["ATCUPLINK"]=createPage("ATCUPLINK")
fmsPages["ATCUPLINK"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then return{

"  ****z ATC UPLINK      ",
"                        ",	               
"<REQUEST            OPEN",
"                        ",
"*****                   ",
"                        ",
"*****                   ",
"                        ",
"FL***                   ",
"                        ",
".**                     ",
"                        ",
"                    LOG>" 
    }

 elseif pgNo==2 then return {
"  ****z ATC UPLINK      ",
"                        ",		               
"****z                   ",
"                        ",
"FL***                   ",
"                        ",
"                        ",
"                        ",
"<STANDBY           LOAD>",
"                        ",
"<REJECT          ACCEPT>",
"                        ",
"<PRINT              LOG>" 
}
end
end

fmsPages["ATCUPLINK"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then return
	{
"                    1/2 ",
"                  STATUS",		               
"                        ",
" PROCEED DIRECT TO      ",
"                        ",
"/AT                     ",
"                        ",
" CLIMB TO AND MAINTAIN  ",
"                        ",
"/MAINTAIN               ",
"                        ",
"------- CONTINUED ------",
"                        " 
 }


 elseif pgNo==2 then return {
 
"                    2/2 ",
"/AT                     ",		               
"                        ",
" EXPECT CRUISE CLIMB TO ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"------------------------",
"                        "
}
end
end





fmsFunctionsDefs["ATCUPLINK"]={}
--[[
fmsFunctionsDefs["ATCUPLINK"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCUPLINK"]["R6"]={"setpage",""}
]]

