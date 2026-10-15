--[[
*****************************************************************************************
* Program Script Name	:	B744.fms.pages.pax-cargo
* Author Name			:	Marauder28
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2020-12-14	0.01a				Start of Dev
*
*****************************************************************************************
*
*****************************************************************************************
--]]

fmsPages["PAXCARGO"]=createPage("PAXCARGO")
fmsPages["PAXCARGO"].getPage=function(self,pgNo,fmsID)
	if pgNo == 1 then

		fmsFunctionsDefs["PAXCARGO"]["L1"]={"setdata","paxFirstClassA"}
		fmsFunctionsDefs["PAXCARGO"]["L2"]={"setdata","paxBusClassB"}
		fmsFunctionsDefs["PAXCARGO"]["L3"]={"setdata","paxEconClassC"}
		fmsFunctionsDefs["PAXCARGO"]["L4"]={"setdata","paxEconClassD"}
		fmsFunctionsDefs["PAXCARGO"]["L5"]={"setdata","paxEconClassE"}
		fmsFunctionsDefs["PAXCARGO"]["L6"]={"setpage","GNDHNDL"}
		fmsFunctionsDefs["PAXCARGO"]["R1"]={"setdata","cargoFwd"}
		fmsFunctionsDefs["PAXCARGO"]["R2"]={"setdata","cargoAft"}
		fmsFunctionsDefs["PAXCARGO"]["R3"]={"setdata","cargoBulk"}
		fmsFunctionsDefs["PAXCARGO"]["R5"]={"setdata","paxPayload"}

		local weight_factor = 0
		local paxA = 0
		local paxB = 0
		local paxC = 0
		local paxD = 0
		local paxE = 0
		local cargo_fwd = 0
		local cargo_aft = 0
		local cargo_bulk = 0
		local payload_weight = 0

		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		else
			weight_factor = 1
		end
		
		paxA = string.format("%-2d", tonumber(fmsModules["data"].paxFirstClassA))
		paxB = string.format("%-2d", tonumber(fmsModules["data"].paxBusClassB))
		paxC = string.format("%-2d", tonumber(fmsModules["data"].paxEconClassC))
		paxD = string.format("%-3d", tonumber(fmsModules["data"].paxEconClassD))
		paxE = string.format("%-3d", tonumber(fmsModules["data"].paxEconClassE))
		cargo_fwd = string.format("%6d", tonumber(fmsModules["data"].cargoFwd) * weight_factor)
		cargo_aft = string.format("%6d", tonumber(fmsModules["data"].cargoAft) * weight_factor)
		cargo_bulk = string.format("%5d", tonumber(fmsModules["data"].cargoBulk) * weight_factor)
		payload_weight = string.format("%5.1f", (simDR_payload_weight * weight_factor) / 1000)

		if simDR_onGround == 0 then
			fmsFunctionsDefs["PAXCARGO"]["L1"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L2"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L3"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L4"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L5"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R1"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R2"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R3"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R5"]=nil
		else
			fmsFunctionsDefs["PAXCARGO"]["L1"]={"setdata","paxFirstClassA"}
			fmsFunctionsDefs["PAXCARGO"]["L2"]={"setdata","paxBusClassB"}
			fmsFunctionsDefs["PAXCARGO"]["L3"]={"setdata","paxEconClassC"}
			fmsFunctionsDefs["PAXCARGO"]["L4"]={"setdata","paxEconClassD"}
			fmsFunctionsDefs["PAXCARGO"]["L5"]={"setdata","paxEconClassE"}
			fmsFunctionsDefs["PAXCARGO"]["R1"]={"setdata","cargoFwd"}
			fmsFunctionsDefs["PAXCARGO"]["R2"]={"setdata","cargoAft"}
			fmsFunctionsDefs["PAXCARGO"]["R3"]={"setdata","cargoBulk"}
			fmsFunctionsDefs["PAXCARGO"]["R5"]={"setdata","paxPayload"}
		end
		
	  return {
	  "   PAX / CARGO ("..simConfigData["data"].SIM.weight_display_units..")",
	  "                         ",
	  paxA.."                "..cargo_fwd,
	  "                         ",
	  paxB.."                "..cargo_aft,
	  "                         ",
	  paxC.."                 "..cargo_bulk,
	  "                         ",
	  paxD,
	  "           PAYLOAD="..payload_weight,
	  paxE,
	  "                         ",
	  "<GND HNDL                "
	  }
	  elseif pgNo == 2 then
		fmsFunctionsDefs["PAXCARGO"]["L1"]={"setdata","freightZoneA"}
		fmsFunctionsDefs["PAXCARGO"]["L2"]={"setdata","freightZoneB"}
		fmsFunctionsDefs["PAXCARGO"]["L3"]={"setdata","freightZoneC"}
		fmsFunctionsDefs["PAXCARGO"]["L4"]={"setdata","freightZoneD"}
		fmsFunctionsDefs["PAXCARGO"]["L5"]={"setdata","freightZoneE"}
		fmsFunctionsDefs["PAXCARGO"]["L6"]={"setpage","GNDHNDL"}
		fmsFunctionsDefs["PAXCARGO"]["R1"]={"setdata","cargoFwd"}
		fmsFunctionsDefs["PAXCARGO"]["R2"]={"setdata","cargoAft"}
		fmsFunctionsDefs["PAXCARGO"]["R3"]={"setdata","cargoBulk"}
		fmsFunctionsDefs["PAXCARGO"]["R5"]={"setdata","freightPayload"}

		local weight_factor = 0
		local freightZoneA = 0
		local freightZoneB = 0
		local freightZoneC = 0
		local freightZoneD = 0
		local freightZoneE = 0
		local cargo_fwd = 0
		local cargo_aft = 0
		local cargo_bulk = 0
		local payload_weight = 0

		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		else
			weight_factor = 1
		end
		
		freightZoneA = string.format("%-5d", tonumber(fmsModules["data"].freightZoneA) * weight_factor)
		freightZoneB = string.format("%-5d", tonumber(fmsModules["data"].freightZoneB) * weight_factor)
		freightZoneC = string.format("%-6d", tonumber(fmsModules["data"].freightZoneC) * weight_factor)
		freightZoneD = string.format("%-6d", tonumber(fmsModules["data"].freightZoneD) * weight_factor)
		freightZoneE = string.format("%-4d", tonumber(fmsModules["data"].freightZoneE) * weight_factor)
		cargo_fwd = string.format("%6d", tonumber(fmsModules["data"].cargoFwd) * weight_factor)
		cargo_aft = string.format("%6d", tonumber(fmsModules["data"].cargoAft) * weight_factor)
		cargo_bulk = string.format("%5d", tonumber(fmsModules["data"].cargoBulk) * weight_factor)
		payload_weight = string.format("%5.1f", (simDR_payload_weight * weight_factor) / 1000)

		if simDR_onGround == 0 then
			fmsFunctionsDefs["PAXCARGO"]["L1"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L2"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L3"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L4"]=nil
			fmsFunctionsDefs["PAXCARGO"]["L5"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R1"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R2"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R3"]=nil
			fmsFunctionsDefs["PAXCARGO"]["R5"]=nil
		else
			fmsFunctionsDefs["PAXCARGO"]["L1"]={"setdata","freightZoneA"}
			fmsFunctionsDefs["PAXCARGO"]["L2"]={"setdata","freightZoneB"}
			fmsFunctionsDefs["PAXCARGO"]["L3"]={"setdata","freightZoneC"}
			fmsFunctionsDefs["PAXCARGO"]["L4"]={"setdata","freightZoneD"}
			fmsFunctionsDefs["PAXCARGO"]["L5"]={"setdata","freightZoneE"}
			fmsFunctionsDefs["PAXCARGO"]["R1"]={"setdata","cargoFwd"}
			fmsFunctionsDefs["PAXCARGO"]["R2"]={"setdata","cargoAft"}
			fmsFunctionsDefs["PAXCARGO"]["R3"]={"setdata","cargoBulk"}
			fmsFunctionsDefs["PAXCARGO"]["R5"]={"setdata","freightPayload"}
		end
		
	  return {
	  "     FREIGHT ("..simConfigData["data"].SIM.weight_display_units..")",
	  "                         ",
	  freightZoneA.."             "..cargo_fwd,
	  "                         ",
	  freightZoneB.."             "..cargo_aft,
	  "                         ",
	  freightZoneC.."             "..cargo_bulk,
	  "                         ",
	  freightZoneD,
	  "           PAYLOAD="..payload_weight,
	  freightZoneE,
	  "                         ",
	  "<GND HNDL                "
	  }

	end
end

fmsPages["PAXCARGO"].getSmallPage=function(self,pgNo,fmsID)
	if pgNo == 1 then
		local weight_factor = 0
		local cargo_total = 0
		local pax_total = 0

		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		else
			weight_factor = 1
		end

		pax_total = string.format("%3d", fmsModules["data"].paxTotal)
		cargo_total = string.format("%4.1f", (tonumber(fmsModules["data"].cargoTotal) * weight_factor) / 1000)
		
	  return {
	  "                     1/2 ",
	  "FIRST (A)      FWD CARGO",
	  "     (23) (5P/16C)      ",
	  "BUS   (B)      AFT CARGO",
	  "     (80) (4P/14C)      ",
	  "ECON  (C)     BULK CARGO",
	  "     (77)               ",
	  "ECON  (D)    --TOTALS-- ",
	  "    (104)     "..pax_total.." / "..cargo_total,
	  "ECON  (E)                ",
	  "    (132)                ",
	  "                         ",
	  "                         "
	  }
	elseif pgNo == 2 then
		local weight_factor = 0
		local freight_total = 0
		local cargo_total = 0

		if simConfigData["data"].SIM.weight_display_units == "LBS" then
			weight_factor = simConfigData["data"].SIM.kgs_to_lbs
		else
			weight_factor = 1
		end

		freight_total = string.format("%5.1f", (tonumber(fmsModules["data"].freightTotal) * weight_factor) / 1000)
		cargo_total = string.format("%4.1f", (tonumber(fmsModules["data"].cargoTotal) * weight_factor) / 1000)
		
	  return {
	  "                     2/2",
	  "ZONE A         FWD CARGO",
	  "     (3P) (5P/16C)      ",
	  "ZONE B         AFT CARGO",
	  "     (8P) (4P/14C)      ",
	  "ZONE C        BULK CARGO",
	  "     (6P)               ",
	  "ZONE D        --TOTALS-- ",
	  "     (12P)  "..freight_total.." / "..cargo_total,
	  "ZONE E                   ",
	  "     (1P)               ",
	  "                         ",
	  "                         "
	  }

	end
end

fmsPages["PAXCARGO"].getNumPages=function(self)
  return 2
end
