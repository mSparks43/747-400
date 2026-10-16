fmsPages["ALTNNAVRADIO"]=createPage("ALTNNAVRADIO")
fmsPages["ALTNNAVRADIO"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"     ALTN NAV RADIO     ",
"                        ",		               
"116.80                  ",
"                        ",
"---                     ",
"                        ",
"1304.5                  ",
"                        ",
"110.70/037°             ",
"                        ",
"                        ",
"                        ",
"110.90/128°       ------" 
    }
end

fmsPages["ALTNNAVRADIO"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                        ",
" VOR                    ",	               
"                        ",
" CRS                    ",
"                        ",
" ADF                    ",
"                        ",
" ILS                    ",
"                        ",
"                        ",
"                        ",
"       PRESELECT        ",
"                        " 
    }
end


  
fmsFunctionsDefs["ALTNNAVRADIO"]={}
--[[
fmsFunctionsDefs["ALTNNAVRADIO"]["L1"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["L2"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["L3"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R4"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["L5"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["L6"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R1"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R2"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R3"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R4"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R5"]={"setpage",""}
fmsFunctionsDefs["ALTNNAVRADIO"]["R6"]={"setpage",""}
]]

