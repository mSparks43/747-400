fmsPages["APPROACH"]=createPage("APPROACH")
fmsPages["APPROACH"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"      APPROACH REF      ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"*****  ****       "..fmsModules["data"]["flapspeed"] ,
"                        ",
"                        ", 
"------------------------",
"<INDEX       THRUST LIM>"
    }
end

fmsPages["APPROACH"].getSmallPage=function(self,pgNo,fmsID)
    return{

"                        ",
" GROSS WT   FLAPS   VREF",
""..fmsModules["data"]["grosswt"] .."        25°  "..fmsModules["data"]["vref1"] .."KT",
"                        ",
"             30°  "..fmsModules["data"]["vref2"] .."KT",
"                        ",
"                        ",
" *******      FLAP/SPEED",
"     FT    M            ",
"                        ",
"                        ", 
"------------------------",
"                        "
    }
	end
	
fmsFunctionsDefs["APPROACH"]={}
fmsFunctionsDefs["APPROACH"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["APPROACH"]["R6"]={"setpage","THRUSTLIM"}
fmsFunctionsDefs["APPROACH"]["L1"]={"setdata","grosswt"}
fmsFunctionsDefs["APPROACH"]["R1"]={"setdata","vref1"}
fmsFunctionsDefs["APPROACH"]["R2"]={"setdata","vref2"}
fmsFunctionsDefs["APPROACH"]["R4"]={"setdata","flapspeed"}