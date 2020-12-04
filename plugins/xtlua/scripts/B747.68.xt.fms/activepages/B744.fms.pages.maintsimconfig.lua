fmsPages["MAINTSIMCONFIG"]=createPage("MAINTSIMCONFIG")
fmsPages["MAINTSIMCONFIG"].getPage=function(self,pgNo,fmsID)
	local display_weight_units

	if simConfigData["data"].weight_display_units == "KGS" then
		display_weight_units = simConfigData["data"].weight_display_units.."/"
	else
		display_weight_units = "   /"..simConfigData["data"].weight_display_units
	end
	
  return {
  "   SIM CONFIGURATION    ",
  "                        ",
  ""..display_weight_units,
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "<MAINT                  "
  }
end

fmsPages["MAINTSIMCONFIG"].getSmallPage=function(self,pgNo,fmsID)
	local display_weight_units = "KGS"
	
	if simConfigData["data"].weight_display_units == "KGS" then
		display_weight_units = "    LBS"
	else
		display_weight_units = "KGS"
	end

  return {
  "                        ",
  "WEIGHT UNITS            ",
  ""..display_weight_units,
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
end
fmsFunctionsDefs["MAINTSIMCONFIG"]["L1"]={"setdata","weightUnits"}
fmsFunctionsDefs["MAINTSIMCONFIG"]["L6"]={"setpage","MAINT"}