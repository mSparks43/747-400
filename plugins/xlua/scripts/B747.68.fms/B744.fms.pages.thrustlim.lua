fmsPages["THRUSTLIM"]=createPage("THRUSTLIM")
fmsPages["THRUSTLIM"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"       THRUST LIM       ",
"                        ",
""..fmsModules["data"]["thrustsel"] .."        **       "..fmsModules["data"]["thrustn1"],
"                        ",
"<TO                 CLB>",
"                        ",
"<TO 1             CLB 1>",
"                        ",
"<TO 2             CLB 2>",
"                        ",
"                        ", 
"------------------------",
"<INDEX          TAKEOFF>"
         }
end

fmsPages["THRUSTLIM"]["templateSmall"]={
"                        ",
" SEL      OAT D-TO 1 N1 ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"  5%                    ",
"                        ",
"  20%                   ",
"                        ", 
"                        ",
"                        "
}

--[[ Only if in the air!
fmsPages["THRUSTLIM"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"       THRUST LIM       ",
"                        ",
"             "..fmsModules["data"]["thrustn1"],
"                        ",
"<GA                 CLB>",
"                        ",
"<CON              CLB 1>",
"                        ",
"<CRZ              CLB 2>",
"                        ",
"                        ", 
"------------------------",
"<INDEX         APPROACH>"
         }
end

fmsPages["THRUSTLIM"]["templateSmall"]={
"                        ",
"               CLB 1 N1 ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"  5%                    ",
"                        ",
"  20%                   ",
"                        ", 
"                        ",
"                        "
}

]]

fmsFunctionsDefs["THRUSTLIM"]={}
fmsFunctionsDefs["THRUSTLIM"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["THRUSTLIM"]["R6"]={"setpage","TAKEOFF"}
fmsFunctionsDefs["THRUSTLIM"]["L1"]={"setdata","thrustsel"}
fmsFunctionsDefs["THRUSTLIM"]["R1"]={"setdata","thrustn1"}