simDR_GRWT=find_dataref("sim/flightmodel/weight/m_total")
simDR_fuel=find_dataref("sim/flightmodel/weight/m_fuel_total")
--simDR_payload=find_dataref("sim/flightmodel/weight/m_fixed")
--simDR_fuel_tanks=find_dataref("sim/flightmodel/weight/m_fuel") --res on 5 and 6
--simDR_cg=find_dataref("sim/flightmodel/misc/cgz_ref_to_default")

--Marauder28
grwt_lineLg = ""
grwt_lineSm = ""
crzcg_lineLg = ""
crzcg_lineSm = ""
--Marauder28

fmsPages["PERFINIT"]=createPage("PERFINIT")
fmsPages["PERFINIT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
	--Marauder28
	local grwt = fmsModules["data"].grwt
	local grwt_diff = 0  --used to track differences in manually entered GW and sim-provided GW
	local zfw = fmsModules["data"].zfw
	local calc_gw = string.format("%5.1f", (simDR_GRWT / 1000))
	local calc_zfw = string.format("%5.1f", ((simDR_GRWT - simDR_fuel) / 1000))
	local rsv = fmsModules["data"].reserves
	
	if not string.match(grwt, "***.*") then
		calc_zfw = string.format("%5.1f", (tonumber(grwt) - simDR_fuel) / 1000)
		grwt_diff = string.format("%5.1f", tonumber(grwt) - simDR_GRWT)
	end
	
	if not string.match(zfw, "***.*") then
		zfw = string.format("%5.1f", zfw)
		grwt = string.format("%5.1f", tonumber(zfw) + (simDR_fuel / 1000))
	end

	if not string.match(rsv, "***.*") then
		rsv = string.format("%5.1f", rsv)
	end
	
	if string.len(crzcg_lineLg) < 1 then
		crzcg_lineSm = string.format("%5.1f%%", tonumber(fmsModules["data"].crzcg))
	else
		crzcg_lineLg = string.format("%5.1f%%", tonumber(fmsModules["data"].crzcg))
		crzcg_lineSm = ""
	end
	--Marauder28
	
    --local grwtV=simDR_GRWT/1000
    local grfuelV=simDR_fuel/1000
    --local zfwV=(simDR_GRWT-simDR_fuel)/1000
    --local reservesV=(simDR_fuel_tanks[5]+simDR_fuel_tanks[6])/1000
    local jet_weightV=simDR_m_jettison/1000

	if simConfigData["data"].weight_display_units == "LBS" then
	  --Marauder28
	  if not string.match(grwt, "***.*") then grwt = string.format("%5.1f", tonumber(grwt) * simConfigData["data"].kgs_to_lbs) end
	  if not string.match(zfw, "***.*") then zfw = string.format("%5.1f", tonumber(zfw) * simConfigData["data"].kgs_to_lbs) end
      if not string.match(rsv, "***.*") then rsv = string.format("%5.1f", tonumber(rsv) * simConfigData["data"].kgs_to_lbs) end
	  calc_gw = string.format("%5.1f", tonumber(calc_gw) * simConfigData["data"].kgs_to_lbs)
	  calc_zfw = string.format("%5.1f", tonumber(calc_zfw) * simConfigData["data"].kgs_to_lbs)	  
	  --Marauder28

      --grwtV=grwtV * simConfigData["data"].kgs_to_lbs
      grfuelV=grfuelV * simConfigData["data"].kgs_to_lbs
      --zfwV=zfwV * simConfigData["data"].kgs_to_lbs
      jet_weightV=jet_weightV * simConfigData["data"].kgs_to_lbs
    end
	
    --local grwt=string.format("%05.1f",grwtV)
    local grfuel=string.format("%5.1f",grfuelV)
    --local zfw=string.format("%05.1f",zfwV)
    --local reserves=string.format("%5.1f",tonumber(reservesV))
    local jet_weight="     "
    if jet_weightV>0 then jet_weight=string.format("%5.1f",jet_weightV) end

	--Marauder28
	if string.match(grwt, "***.*") then
		grwt_lineLg = "     "
		grwt_lineSm = "<"..calc_gw
	else
		fmsModules["data"].grwt = string.format("%5.1f", simDR_GRWT + grwt_diff)
		grwt_lineLg = string.format("%5.1f", tonumber(grwt))
		grwt_lineSm = "      "   --..calc_gw
	end
	--Marauder28
	
    return{

 "       PERF INIT        ",
 "                        ",
 "".. grwt_lineLg .."              "..fmsModules["data"]["crzalt"],
 "                        ",
 ""..grfuel .. "              "..jet_weight ,
 "                        ",
 ""..zfw,
 "                        ",
-- ""..reserves .."              "..crzcg_lineLg,
 ""..rsv .."              "..crzcg_lineLg,
 "                        ",
 ""..fmsModules["data"]["costindex"] .."                "..fmsModules["data"].stepsize, 
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
      " GR WT ADV       CRZ ALT",
	  grwt_lineSm,
--      "                        ",
      lineA,
      "      CALC              ",
      " ZFW                    ",
      "                        ",
      " RESERVES         CRZ CG",
--      "                        ",
      "                   "..crzcg_lineSm,
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
fmsFunctionsDefs["PERFINIT"]["R4"]={"setdata","crzcg"}
fmsFunctionsDefs["PERFINIT"]["R5"]={"setdata","stepsize"}
fmsFunctionsDefs["PERFINIT"]["R6"]={"setpage","THRUSTLIM"}
