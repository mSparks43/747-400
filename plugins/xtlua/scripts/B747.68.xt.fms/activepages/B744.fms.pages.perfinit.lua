simDR_GRWT=find_dataref("sim/flightmodel/weight/m_total")
simDR_fuel=find_dataref("sim/flightmodel/weight/m_fuel_total")
simDR_payload=find_dataref("sim/flightmodel/weight/fixed")
simDR_fuel_tanks=find_dataref("sim/flightmodel/weight/m_fuel") --res on 5 and 6
simDR_cg=find_dataref("sim/flightmodel/misc/cgz_ref_to_default")

fmsPages["PERFINIT"]=createPage("PERFINIT")
fmsPages["PERFINIT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local grwtV=simDR_GRWT/1000
    local grfuelV=simDR_fuel/1000
    local zfwV=(simDR_GRWT-simDR_fuel)/1000
    local reservesV=(simDR_fuel_tanks[5]+simDR_fuel_tanks[6])/1000
    local jet_weightV=simDR_m_jettison/1000
	if simConfigData["data"].weight_display_units == "LBS" then
      grwtV=grwtV * simConfigData["data"].kgs_to_lbs
      grfuelV=grfuelV * simConfigData["data"].kgs_to_lbs
      zfwV=zfwV * simConfigData["data"].kgs_to_lbs
      reservesV=reservesV * simConfigData["data"].kgs_to_lbs
      jet_weightV=jet_weightV * simConfigData["data"].kgs_to_lbs
    end
    local grwt=string.format("%05.1f",grwtV)
    local grfuel=string.format("%05.1f",grfuelV)
    local zfw=string.format("%05.1f",zfwV)
    local reserves=string.format("%05.1f",reservesV)
    local jet_weight="     "
    if jet_weightV>0 then jet_weight=string.format("%05.1f",jet_weightV) end
    return{

 "       PERF INIT        ",
 "                        ",
 "".. grwt .."              "..fmsModules["data"]["crzalt"],
 "                        ",
 ""..grfuel .. "              "..jet_weight ,
 "                        ",
 ""..zfw ,
 "                        ",
 ""..reserves .."              "..string.format("%03.1f",simDR_cg),
 "                        ",
 ""..fmsModules["data"]["costindex"] .."              ICAO", 
 "                        ",
 "<INDEX       THRUST LIM>"
    }
end
fmsPages["PERFINIT"].getSmallPage=function(self,pgNo,fmsID)
    local lineA=" FUEL                   "
    if simDR_m_jettison>0 then
    lineA=" FUEL         RETARDANT "
    end  
    return {
      "                        ",
      " GR WT           CRZ ALT",
      "                        ",
      lineA,
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
end

  
  
fmsFunctionsDefs["PERFINIT"]={}


fmsFunctionsDefs["PERFINIT"]["L1"]={"setdata","grwt"}
fmsFunctionsDefs["PERFINIT"]["L2"]={"setdata","fuel"}
fmsFunctionsDefs["PERFINIT"]["L3"]={"setdata","zfw"}
fmsFunctionsDefs["PERFINIT"]["L4"]={"setdata","reserves"}
fmsFunctionsDefs["PERFINIT"]["L5"]={"setdata","costindex"}
fmsFunctionsDefs["PERFINIT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["PERFINIT"]["R1"]={"setdata","crzalt"}
--fmsFunctionsDefs["PERFINIT"]["R4"]={"setdata","crzcg"}
fmsFunctionsDefs["PERFINIT"]["R6"]={"setpage","THRUSTLIM"}
