fmsPages["MAINTSIMCONFIG"]=createPage("MAINTSIMCONFIG")
fmsPages["MAINTSIMCONFIG"].getPage=function(self,pgNo,fmsID)
	if pgNo == 1 then
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L1"]={"setdata","weightUnits"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L2"]={"setdata","irsAlignTime"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L3"]={"setdata","autoFuelMgmt"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L4"]={"setdata","baroIndicator"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L5"]={"setdata","baroSync"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R1"]={"setdata","stdPaxWeight"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R2"]={"setdata","captInbd"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R3"]={"setdata","captLwr"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R4"]={"setdata","foInbd"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R5"]={"setdata","foLwr"}
    fmsFunctionsDefs["MAINTSIMCONFIG"]["R6"]={"setdata","simConfigSave"}
		local weight_factor = 1
		local display_weight_units = string.format("%-3s", simConfigData["data"].SIM.weight_display_units)
		local irs_align_time = string.format("%-2d", simConfigData["data"].SIM.irs_align_time / 60)  --Mins
		local std_pax_weight = string.format("%5.1f", simConfigData["data"].SIM.std_pax_weight * weight_factor)
		local fuel_mgmt = string.format("%-3s", simConfigData["data"].SIM.auto_fuel_mgmt)
		local capt_inbd_display = string.format("%5s", simConfigData["data"].SIM.capt_inbd)
		local capt_lwr_display = string.format("%9s", simConfigData["data"].SIM.capt_lwr)
		local fo_inbd_display = string.format("%5s", simConfigData["data"].SIM.fo_inbd)
		local fo_lwr_display = string.format("%9s", simConfigData["data"].SIM.fo_lwr)
		local baro_indicator = string.format("%-3s", simConfigData["data"].SIM.baro_indicator)
		local baro_sync = string.format("%-3s", simConfigData["data"].SIM.baro_sync)
		
		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		end

		std_pax_weight = string.format("%5.1f", simConfigData["data"].SIM.std_pax_weight * weight_factor)
		
		return {
		"       SIM CONFIG       ",
		"                        ",
		" "..display_weight_units.."                "..std_pax_weight,
		"                        ",
		" "..irs_align_time.."                 "..capt_inbd_display,
		"                        ",
		" "..fuel_mgmt.."            "..capt_lwr_display,
		"                        ",
		" "..baro_indicator.."                "..fo_inbd_display,
		"                        ",
		" "..baro_sync.."            "..fo_lwr_display,
		"                        ",
		"<MAINT               SAVE>"
    }
  elseif pgNo == 2 then
    fmsFunctionsDefs["MAINTSIMCONFIG"]["L1"]={"setDref","VNAVSPAUSE"}
    fmsFunctionsDefs["MAINTSIMCONFIG"]["L2"]={"setDref","PAUSEVAL"}
    fmsFunctionsDefs["MAINTSIMCONFIG"]["L3"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L4"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L5"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R1"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R2"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R3"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R4"]=nil
    fmsFunctionsDefs["MAINTSIMCONFIG"]["R5"]=nil
    fmsFunctionsDefs["MAINTSIMCONFIG"]["R6"]=nil
    local LineA="<ENABLE PAUSE AT T/D    "	
    local LineB="<PAUSE AT ***NM TO DEST "	
    if B747DR_ap_vnav_pause ==1.0 then 
        LineA="<DISABLE PAUSE AT T/D   "
        if B747BR_tod>0 then 
          LineB="<PAUSE AT ".. string.format("%03d",B747BR_tod) .."NM TO DEST "
        end
  
    elseif B747DR_ap_vnav_pause >1.0 then 
        LineA="<DISABLE PAUSE          "
        LineB="<PAUSE AT ".. string.format("%03d",B747DR_ap_vnav_pause) .."NM TO DEST "    
    end
    return {
  
    "     CONFIG PAUSE       ",
    "                        ",
    LineA,
    "                        ",
    LineB,
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ", 
    "                        ",
    "<MAINT                  "
    }
	elseif pgNo == 3 then
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L1"]={"setdata","model"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L2"]={"setdata","aircraftType"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L3"]={"setdata","engines"}
	    fmsFunctionsDefs["MAINTSIMCONFIG"]["L4"]={"setdata","thrustRef"}
    	fmsFunctionsDefs["MAINTSIMCONFIG"]["L5"]=nil
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R1"]={"setdata","airline"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R2"]={"setdata","civilRegistration"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R3"]={"setdata","finNbr"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R4"]={"setdata","pfdStyle"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["R5"]={"setdata","ndStyle"}
    	fmsFunctionsDefs["MAINTSIMCONFIG"]["R6"]={"setdata","simConfigSave"}
		local model = string.format("%-10s", string.sub(simConfigData["data"].PLANE.model, 1, 10))
		local aircraft_type = string.format("%-10s", simConfigData["data"].PLANE.aircraft_type)
		local engines = string.format("%-15s", simConfigData["data"].PLANE.engines)
		local thrust_ref = string.format("%-3s", simConfigData["data"].PLANE.thrust_ref)
		local airline = string.format("%14s", string.sub(simConfigData["data"].PLANE.airline, 1, 14))
		local civil_reg = string.format("%10s", string.sub(simConfigData["data"].PLANE.civil_registration, 1, 10))
		local fin_nbr = string.format("%5s", string.sub(simConfigData["data"].PLANE.fin_nbr,1, 5))
		local pfd_style = string.format("%-3s", simConfigData["data"].PLANE.pfd_style)
		local nd_style = string.format("%-3s", simConfigData["data"].PLANE.nd_style)
		
		return {
		"      PLANE CONFIG      ",
		"                        ",
		" "..model..""..airline,
		"                        ",
		" "..aircraft_type.."    "..civil_reg,
		"                        ",
		" "..engines.."    "..fin_nbr,
		"                        ",
		" "..thrust_ref.."                  "..pfd_style,
		"                        ",
		"                      "..nd_style,
		"                        ",
		"<MAINT               SAVE>"		
		}

	elseif pgNo == 4 then
		-- Sound options (crazytimtimtim + Matt726)
	
		local lineA = "          GPWS           "
		local lineB = "        SEAT BELT        "
		local lineC = "           PA            "
		local lineD = "          MUSIC          "
		local lineE = "         ALARMS          "

		fmsFunctionsDefs["MAINTSIMCONFIG"]["L1"]={"setDref","B747DR_SNDoptions_gpws"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L2"]={"setDref","B747DR_SNDoptions_seatBelt"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L3"]={"setDref","B747DR_SNDoptions_pa"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L4"]={"setDref","B747DR_SNDoptions_music"}
		fmsFunctionsDefs["MAINTSIMCONFIG"]["L5"]={"setDref","B747DR_SNDoptions_modernAlarms"}

		if B747DR_SNDoptions_gpws == 0 then
			lineA = "<USE OLD ALARMS         "
		else
			lineA = "<USE NEW ALARMS         "
		end

		if B747DR_SNDoptions_seatBelt == 0 then
			lineB = "<SEATBELT SOUND 2       "
		else
			lineB = "<SEATBELT SOUND 1       "
		end

		if B747DR_SNDoptions_pa == 0 then
			lineC = "<DISABLE PA             "
		else
			lineC = "<ENABLE PA              "
		end

		if B747DR_SNDoptions_music == 0 then
			lineD = "<DISABLE BRD MUSIC       "
		else
			lineD = "<ENABLE BRD MUSIC        "
		end

		if B747DR_SNDoptions_modernAlarms == 0 then
			lineE = "<USE NEW WARNINGS        "
		else
			lineE = "<USE DEFAULT WARNINGS    "
		end

		return{

		"      SOUND CONFIG      ",
		"                        ",
		lineA,
		"                        ",
		lineB,
		"                        ",
		lineC,
		"                        ",
		lineD,
		"                        ",
		lineE,
		"------------------------",
		"<MAINT                  "
		}

		-- Sound Options end
	end
end

fmsPages["MAINTSIMCONFIG"].getSmallPage=function(self,pgNo,fmsID)
	if pgNo == 1 then
		local display_weight_units = "KGS"
		local fuel_mgmt = "NO"
		local baro_indicator = "IN"
		local baro_sync = "NO"
		
		if simConfigData["data"].SIM.weight_display_units == "KGS" then
			display_weight_units = "/LBS"
		else
			display_weight_units = "/KGS"
		end

		if simConfigData["data"].SIM.auto_fuel_mgmt == "NO" then
			fuel_mgmt = "/YES"
		else
			fuel_mgmt = "/NO "
		end

		if simConfigData["data"].SIM.baro_indicator == "IN" then
			baro_indicator = "/HPA"
		else
			baro_indicator = "/IN "
		end

		if simConfigData["data"].SIM.baro_sync == "NO" then
			baro_sync = "/YES"
		else
			baro_sync = "/NO "
		end

		return {
		"                     1/4",
		" WGT UNITS    STD PAX WGT",
		"<    "..display_weight_units,
		" IRS ALIGN      CAPT INBD",
		"    MINS                 >",
		" FUEL MGMT(X)   CAPT  LWR",
		"<    "..fuel_mgmt.."                >",
		" BARO INDICATOR   FO INBD",
		"<    "..baro_indicator.."                >",
		" BARO SYNC        FO  LWR",
		"<    "..baro_sync.."                >",
		"                        ",
		"                        "
    }
  elseif pgNo == 2 then
    return {
      "                     2/4",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        "
      }
	elseif pgNo == 3 then
		local thrust_ref = "EPR"
		
		if simConfigData["data"].PLANE.thrust_ref == "EPR" then
			thrust_ref = "/N1 "
		else
			thrust_ref = "/EPR"
		end
		
		return {
		"                     3/4",
		" MODEL            AIRLINE",
		"                        ",
		" TYPE           CIVIL REG",
		"<                        ",
		" ENGINES(X)       FIN NBR",
		"<                        ",
		" THRUST REF(X)  PFD STYLE",
		"<    "..thrust_ref       .."                >",
		"              (X)ND STYLE",
		"                         >",
		"                        ",
		"                        "
		}

	elseif pgNo == 4 then
		-- smallPage for SoundConfig

		local lineA = "                   (GPWS)"
		local lineB = "                  (STBLT)"
		local lineC = "                     (PA)"
		local lineD = "                  (MUSIC)"
		local lineE = "                 (ALARMS)"

		if B747DR_SNDoptions_gpws == 0 then
			lineA = "                      (NEW)"
		else
			lineA = "                  (CLASSIC)"
		end

		if B747DR_SNDoptions_seatBelt == 0 then
			lineB = "                        (1)"
		else
			lineB = "                        (2)"
		end

		if B747DR_SNDoptions_pa == 0 then
			lineC = "                       (ON)"
		else
			lineC = "                      (OFF)"
		end

		if B747DR_SNDoptions_music == 0 then
			lineD = "                       (ON)"
		else
			lineD = "                      (OFF)"
		end

		if B747DR_SNDoptions_modernAlarms == 0 then
			lineE = "                  (DEFAULT)"
		else
			lineE = "                      (NEW)"
		end

		return {
			"                        4/4",
			"OPTIONS           CURRENTLY",
			lineA,
			"                        ",
			lineB,
			"                        ",
			lineC,
			"                        ",
			lineD,
			"                        ",
			lineE,
			"                        ",
			"                        "
		}
		
		-- sound smallPage end
	end
end

fmsPages["MAINTSIMCONFIG"].getNumPages=function(self)
  return 4
end
fmsFunctionsDefs["MAINTSIMCONFIG"]["L6"]={"setpage","MAINT"}