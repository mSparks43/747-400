simDR_GRWT=find_dataref("sim/flightmodel/weight/m_total")
simDR_fuel=find_dataref("sim/flightmodel/weight/m_fuel_total")
simDR_payload=find_dataref("sim/flightmodel/weight/fixed")
simDR_fuel_tanks=find_dataref("sim/flightmodel/weight/m_fuel") --res on 5 and 6
fmsPages["PERFINIT"]=createPage("PERFINIT")
fmsPages["PERFINIT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local grwt=string.format("%05.1f",simDR_GRWT/1000)
    local grfuel=string.format("%05.1f",simDR_fuel/1000)
    local zfw=string.format("%05.1f",(simDR_GRWT-simDR_fuel)/1000)
    local reserves=string.format("%05.1f",(simDR_fuel_tanks[5]+simDR_fuel_tanks[6])/1000)
    return{

 "       PERF INIT        ",
 "                        ",
 "".. grwt .."              "..fmsModules["data"]["crzalt"],
 "                        ",
 ""..grfuel ,
 "                        ",
 ""..zfw ,
 "                        ",
 ""..reserves .."              "..fmsModules["data"]["crzcg"],
 "                        ",
 ""..fmsModules["data"]["costindex"] .."              ICAO", 
 "                        ",
 "<INDEX       THRUST LIM>"
    }
end

fmsPages["PERFINIT"]["templateSmall"]={
"                        ",
" GR WT           CRZ ALT",
"                        ",
" FUEL                   ",
"     CALC               ",
" ZFW                    ",
"                        ",
" RESERVES         CRZ CG",
"                        ",
" COST INDEX    STEP SIZE",
"                        ", 
"                        ",
"                        "
}


  
  
fmsFunctionsDefs["PERFINIT"]={}


fmsFunctionsDefs["PERFINIT"]["L1"]={"setdata","grwt"}
fmsFunctionsDefs["PERFINIT"]["L2"]={"setdata","fuel"}
fmsFunctionsDefs["PERFINIT"]["L3"]={"setdata","zfw"}
fmsFunctionsDefs["PERFINIT"]["L4"]={"setdata","reserves"}
fmsFunctionsDefs["PERFINIT"]["L5"]={"setdata","costindex"}
fmsFunctionsDefs["PERFINIT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["PERFINIT"]["R1"]={"setdata","crzalt"}
fmsFunctionsDefs["PERFINIT"]["R4"]={"setdata","crzcg"}
fmsFunctionsDefs["PERFINIT"]["R6"]={"setpage","THRUSTLIM"}
