fmsPages["PERFINIT"]=createPage("PERFINIT")
fmsPages["PERFINIT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "       PERF INIT        ",
 "                        ",
 ""..fmsModules["data"]["grwt"] .."              "..fmsModules["data"]["crzalt"],
 "                        ",
 ""..fmsModules["data"]["fuel"] ,
 "                        ",
 ""..fmsModules["data"]["zfw"] ,
 "                        ",
 ""..fmsModules["data"]["reserves"] .."              "..fmsModules["data"]["crzcg"],
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
fmsFunctionsDefs["PERFINIT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["PERFINIT"]["R6"]={"setpage","THRUSTLIM"}
fmsFunctionsDefs["PERFINIT"]["L1"]={"setdata","grwt"}
fmsFunctionsDefs["PERFINIT"]["L2"]={"getdata","fuel"}
fmsFunctionsDefs["PERFINIT"]["L3"]={"setdata","zfw"}
fmsFunctionsDefs["PERFINIT"]["L4"]={"setdata","reserves"}
fmsFunctionsDefs["PERFINIT"]["L5"]={"setdata","costindex"}
fmsFunctionsDefs["PERFINIT"]["R1"]={"setdata","crzalt"}
fmsFunctionsDefs["PERFINIT"]["R4"]={"setdata","crzcg"}

