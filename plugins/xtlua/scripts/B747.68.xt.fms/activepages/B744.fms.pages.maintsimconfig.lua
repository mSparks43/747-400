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
  ""..display_weight_units,  --.."             "..simConfigData["data"].irs_align_time,
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
  "WEIGHT UNITS            ", --IRS ALIGN",
  ""..display_weight_units,   --.."             mins",
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
--fmsFunctionsDefs["MAINTSIMCONFIG"]["R1"]={"setdata","irsAlignTime"}
fmsFunctionsDefs["MAINTSIMCONFIG"]["L6"]={"setpage","MAINT"}