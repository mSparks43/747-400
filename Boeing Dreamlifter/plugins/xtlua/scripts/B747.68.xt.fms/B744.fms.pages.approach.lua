simDR_acf_weight_total_kg           = find_dataref("sim/flightmodel/weight/m_total")
B747DR_airspeed_Vf25                            = find_dataref("laminar/B747/airspeed/Vf25")
B747DR_airspeed_Vf30                            = find_dataref("laminar/B747/airspeed/Vf30")

fmsPages["APPROACH"]=createPage("APPROACH")
fmsPages["APPROACH"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"      APPROACH REF      ",
"                        ",
string.format(" %6d            %3d", simDR_acf_weight_total_kg,B747DR_airspeed_Vf25),
"                        ",
string.format("                   %3d", B747DR_airspeed_Vf30),
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
"       KG    25`      KT",
"                        ",
"             30`      KT",
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