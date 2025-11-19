
registerFMCCommand("laminar/B747/electrical/connect_power","GRND POWER")
registerFMCCommand("sim/ground_ops/service_plane","GROUND SERVICES")
registerFMCCommand("sim/ground_ops/pushback_stop","STOP PUSHBACK")
registerFMCCommand("sim/ground_ops/pushback_left","PUSHBACK LEFT")
registerFMCCommand("sim/ground_ops/pushback_straight","PUSHBACK STRAIGHT")
registerFMCCommand("sim/ground_ops/pushback_right","PUSHBACK RIGHT")

fmsPages["GNDHNDL"]=createPage("GNDHNDL")
fmsPages["GNDHNDL"].getPage=function(self,pgNo,fmsID)
  local lineA="<REMOVE CHOCKS          "
  local LineB="<REQUEST GROUND SERVICES"
  local LineC="<REQUEST PUSH BACK      "

  if B747DR__gear_chocked == 0.0 then
      lineA="<REQUEST CHOCKS         "
  end

  return {

  "     GROUND HANDLING    ",
  "                        ",
  "<GROUND SERVICES",
  "                        ",
  lineA,
  "                        ",
  "<PUSH BACK     PAX/CARGO>",
  "                        ",
  "<DOOR CONTROL           ",
  "                        ",
  "  "..fmsModules["lastcmd"], 
  "                        ",
  "<INDEX                  "
  }
end

fmsPages["GNDHNDL"].getSmallPage=function(self,pgNo,fmsID)
  return {
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "      LAST ACTION       ",
  "                        ",
  "                        ",
  "                        "
  }
end
fmsFunctionsDefs["GNDHNDL"]["L1"]={"setpage","GNDSRV"}
fmsFunctionsDefs["GNDHNDL"]["L2"]={"setDref","CHOCKS"}
fmsFunctionsDefs["GNDHNDL"]["L3"]={"setpage","PUSHBACK"} 
fmsFunctionsDefs["GNDHNDL"]["L6"]={"setpage","INDEX"}
fmsFunctionsDefs["GNDHNDL"]["R3"]={"setpage","PAXCARGO"}
fmsFunctionsDefs["GNDHNDL"]["L4"]={"setpage","DOORS"}

fmsPages["GNDSRV"]=createPage("GNDSRV")
fmsPages["GNDSRV"].getPage=function(self,pgNo,fmsID)
  local lineA=string.format("%03d",B747DR_fuel_add)
  local lineB="<GROUND POWER           "
  if simDR_version>=120012 and (simDR_gpuvolts>=24) then
    lineB="                        "
  elseif B747DR_elec_ext_pwr1_available==1 then
        lineB="<DISCONNECT GROUND POWER"
  end
  local lineC = "                        "
  if simDR_acf_m_jettison>0 then
	local jet_weight=simDR_m_jettison
	if simConfigData["data"].SIM.weight_display_units == "LBS" then
	   jet_weight=simDR_m_jettison * simConfigData["data"].SIM.kgs_to_lbs
	end
	lineC = "               ".. string.format("%05d",jet_weight) .."         "
  end	  


  return {

  "     GROUND SERVICES    ",
  "                        ",
  "<REQUEST GROUND SERVICES",
  "                        ",
  lineB,
  "                        ",
  " "..lineA,
  "                        ",

  lineC,
  "                        ",
  "  "..fmsModules["lastcmd"], 
  "                        ",
  "<GND HNDL               "
  }
end

fmsPages["GNDSRV"].getSmallPage=function(self,pgNo,fmsID)
	local lineA = "x1000KGS"
	local lineB = "                        "
	local lineC = "                        "
	if simDR_acf_m_jettison>0 then
	  lineB = "     FIRE RETARDANT LOAD"
	  fmsFunctionsDefs["GNDSRV"]["L4"]=nil
	  if simConfigData["data"].SIM.weight_display_units == "LBS" then
	    lineC = "                     LBS"
	  else
	    lineC = "                     KGS"
	  end
--	else
--	    lineB = "Passengers              "
--	    lineC = "      x120kgs           "
--	    fmsFunctionsDefs["GNDSRV"]["L4"]={"setdata","passengers"}
	end
	if simConfigData["data"].SIM.weight_display_units == "LBS" then
		lineA = "x1000LBS"
--		lineC = "      x265LBS           "
		
	end
	
  return {
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "ADD FUEL                ",
  "      "..lineA,
  lineB,
  lineC,
  "      LAST ACTION       ",
  "                        ",
  "                        ",
  "                        "
  }
end
fmsFunctionsDefs["GNDSRV"]["L1"]={"setdata","services"}
fmsFunctionsDefs["GNDSRV"]["L2"]={"doCMD","laminar/B747/electrical/connect_power"}
fmsFunctionsDefs["GNDSRV"]["L3"]={"setdata","fuelpreselect"}
fmsFunctionsDefs["GNDSRV"]["L6"]={"setpage","GNDHNDL"}

fmsPages["PUSHBACK"]=createPage("PUSHBACK")
fmsPages["PUSHBACK"].getPage=function(self,pgNo,fmsID)
  

  local LineA="<PUSHBACK LEFT          "
  local LineB="<STRAIGHT PUSHBACK      "
  local LineC="<PUSHBACK RIGHT         "
  local LineD="<REMOVE CHOCKS          "	
  if B747DR__gear_chocked == 0.0 then
      LineD="<REQUEST CHOCKS         "
  end
  if simDR_groundspeed>0.01 then 
    LineA="<STOP PUSHBACK          "
    LineB="                        "
    LineC="                        "
    fmsFunctionsDefs["PUSHBACK"]["L1"]={"doCMD","sim/ground_ops/pushback_stop"}
    fmsFunctionsDefs["PUSHBACK"]["L2"]=nil 
    fmsFunctionsDefs["PUSHBACK"]["L3"]=nil
  else
    fmsFunctionsDefs["PUSHBACK"]["L1"]={"doCMD","sim/ground_ops/pushback_left"}
    fmsFunctionsDefs["PUSHBACK"]["L2"]={"doCMD","sim/ground_ops/pushback_straight"} 
    fmsFunctionsDefs["PUSHBACK"]["L3"]={"doCMD","sim/ground_ops/pushback_right"}
  end

  return {

  "    PUSHBACK HANDLING   ",
  "                        ",
  LineA,
  "                        ",
  LineB,
  "                        ",
  LineC,
  "                        ",
  LineD,
  "                        ",
  "  "..fmsModules["lastcmd"], 
  "                        ",
  "<GND HNDL               "
  }
end
fmsPages["PUSHBACK"].getSmallPage=function(self,pgNo,fmsID)
  return {
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "      LAST ACTION       ",
  "                        ",
  "                        ",
  "                        "
  }
end
fmsFunctionsDefs["PUSHBACK"]["L4"]={"setDref","CHOCKS"}
fmsFunctionsDefs["PUSHBACK"]["L6"]={"setpage","GNDHNDL"}