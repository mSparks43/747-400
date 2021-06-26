
-- WRITTEN BY CRAZYTIMTIMTIM


-- passenger sound page


fmsPages["PASSENGERSOUNDCONFIG"]=createPage("PASSENGERSOUNDCONFIG")
fmsPages["PASSENGERSOUNDCONFIG"].getPage=function(self,pgNo,fmsID)
	if pgNo == 1 then

		local lineA = ""
		local lineB = ""
		local lineC = ""

		fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L1"]={"setSoundOption","seatBeltOption"}
		fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L2"]={"setSoundOption","paOption"}
		fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L3"]={"setSoundOption","musicOption"}

		return{
			"      SOUND CONFIG      ",
			"                        ",
			"<SEATBELT SOUND         ",
			"                        ",
			"<PA/FLIGHT ATTEND.      ",
			"                        ",
			"<BOARDING MUSIC         ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"------------------------",
			"<SIMCONFIG              "
		}

	end
end

fmsPages["PASSENGERSOUNDCONFIG"].getSmallPage=function(self,pgNo,fmsID)
	if pgNo == 1 then

		local lineA = "                  (STBLT)"
		local lineB = "                     (PA)"
		local lineC = "                  (MUSIC)"

		if B747DR_SNDoptions[1] == 0 then
			lineA = "                      (1/2)"
		else
			lineA = "                      (2/2)"
		end

		if B747DR_SNDoptions[2] == 0 then
			lineB = "                       (ON)"
		else
			lineB = "                      (OFF)"
		end

		if B747DR_SNDoptions[3] == 0 then
			lineC = "                       (ON)"
		else
			lineC = "                      (OFF)"
		end

		return{
			"                        ",
			"PASSENGERS      (CURRENTLY)",
			lineA,
			"                        ",
			lineB,
			"                        ",
			lineC,
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "
		}

	end
end

fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L6"]={"setpage","MAINTSIMCONFIG_4"}

fmsPages["PASSENGERSOUNDCONFIG"].getNumPages=function(self)
  return 1
end



-- GPWS SOUND PAGE



fmsPages["GPWSSOUNDCONFIG"]=createPage("GPWSSOUNDCONFIG")
fmsPages["GPWSSOUNDCONFIG"].getPage=function(self,pgNo,fmsID)

	local lineA = ""
	local lineB = ""
	local lineC = ""
	local lineD = ""
	local lineE = ""

	if pgNo == 1 then

		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L1"]={"setSoundOption","GPWS2500"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L2"]={"setSoundOption","GPWS1000"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L3"]={"setSoundOption","GPWS500"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L4"]={"setSoundOption","GPWS400"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L5"]={"setSoundOption","GPWS300"}

		lineA = "<2500                   "
		lineB = "<1000                   "
		lineC = "<500                    "
		lineD = "<400                    "
		lineE = "<300                    "

	elseif pgNo == 2 then

		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L1"]={"setSoundOption","GPWS200"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L2"]={"setSoundOption","GPWS100"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L3"]={"setSoundOption","GPWS50"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L4"]={"setSoundOption","GPWS40"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L5"]={"setSoundOption","GPWS30"}

		lineA = "<200                    "
		lineB = "<100                    "
		lineC = "<50                     "
		lineD = "<40                     "
		lineE = "<30                     "

	elseif pgNo == 3 then

		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L1"]={"setSoundOption","GPWS20"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L2"]={"setSoundOption","GPWS10"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L3"]={"setSoundOption","GPWS5"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L4"]={"setSoundOption","GPWSminimums"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L5"]={"setSoundOption","GPWSapproachingMinimums"}

		lineA = "<20                     "
		lineB = "<10                     "
		lineC = "<5                      "
		lineD = "<MINIMUMS               "
		lineE = "<APP. MINIMUMS          "

	end

	return {
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
		"<SIMCONFIG              "
	}

end

fmsPages["GPWSSOUNDCONFIG"].getSmallPage=function(self,pgNo,fmsID)

	local lineA = ""
	local lineB = ""
	local lineC = ""
	local lineD = ""
	local lineE = ""
	local line = {"notInUse", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"}

	if pgNo == 1 then

		for i = 1, 5 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "                       (ON)"
			else
				line[i] = "                      (OFF)"
			end
		end

		lineA = line[1]
		lineB = line[2]
		lineC = line[3]
		lineD = line[4]
		lineE = line[5]

	elseif pgNo == 2 then

		for i = 6, 10 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "                       (ON)"
			else
				line[i] = "                      (OFF)"
			end
		end

		lineA = line[6]
		lineB = line[7]
		lineC = line[8]
		lineD = line[9]
		lineE = line[10]

	elseif pgNo == 3 then

		for i = 11, 15 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "                       (ON)"
			else
				line[i] = "                      (OFF)"
			end
		end

		lineA = line[11]
		lineB = line[12]
		lineC = line[13]
		lineD = line[14]
		lineE = line[15]

	end

	return {

		"                      "..pgNo.."/3",
		"GPWS OPTIONS    (CURRENTLY)",
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

end

fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L6"]={"setpage","MAINTSIMCONFIG_4"}

fmsPages["GPWSSOUNDCONFIG"].getNumPages=function(self)
	return 3
end



-- PM CALLOUTS CONFIG



fmsPages["PMCALLOUTSCONFIG"]=createPage("PMCALLOUTSCONFIG")
fmsPages["PMCALLOUTSCONFIG"].getPage=function(self,pgNo,fmsID)

	local lineA = ""
	local lineB = ""
	local lineC = ""
	local lineD = ""
	local lineE = ""

	if pgNo == 1 then

		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L1"]={"setSoundOption","PM_all_off"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["R1"]={"setSoundOption","PM_all_on"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L2"]={"setSoundOption","PM_80kt"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L3"]={"setSoundOption","PM_V1"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L4"]={"setSoundOption","PM_rotate"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L5"]={"setSoundOption","PM_V2"}


		lineA = "<ON        ALL      OFF>"
		lineB = "<80 KNOTS               "
		lineC = "<V1                     "
		lineD = "<ROTATE                 "
		lineE = "<V2                     "

	elseif pgNo == 2 then

		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L1"]={"setSoundOption","PM_posRate"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L2"]={"setSoundOption","PM_10000ft"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L3"]={"setSoundOption","PM_transAlt"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L4"]={"setSoundOption","PM_1000ToGO"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L5"]={"setSoundOption","PM_spdbrk"}


		lineA = "<POSITIVE RATE          "
		lineB = "<TEN THOUSAND FT        "
		lineC = "<TRANSITION ALT         "
		lineD = "<1000 FT TO LVLOFF      "
		lineE = "<SPEEDBRAKE             "
		

	elseif pgNo == 3 then

		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L1"]={"setSoundOption","PM_rto"}
		fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L2"]={"setSoundOption","PM_reverse"}

		lineA = "<REJECTED TAKEOFF       "
		lineB = "<THRUST REVERSERS       "
		lineC = "                        "
		lineD = "                        "
		lineE = "                        "

	end

	return {
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
		"<SIMCONFIG              "
	}

end


fmsPages["PMCALLOUTSCONFIG"].getSmallPage=function(self,pgNo,fmsID)

	local lineA = ""
	local lineB = ""
	local lineC = ""
	local lineD = ""
	local lineE = ""
	local line = {"1notInUse", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"}

	if pgNo == 1 then

		for i = 1, 5 do
			if B747DR_SNDoptions_pm[i] == 0 then
				line[i] = "                       (ON)"
			else
				line[i] = "                      (OFF)"
			end
		end

		lineA = "                        "
		lineB = line[2]
		lineC = line[3]
		lineD = line[4]
		lineE = line[5]

	elseif pgNo == 2 then

		for i = 6, 10 do
			if B747DR_SNDoptions_pm[i] == 0 then
				line[i] = "                       (ON)"
			else
				line[i] = "                      (OFF)"
			end
		end

		lineA = line[6]
		lineB = line[7]
		lineC = line[8]
		lineD = line[9]
		lineE = line[10]

	elseif pgNo == 3 then

		for i = 11, 12 do
			if B747DR_SNDoptions_pm[i] == 0 then
				line[i] = "                       (ON)"
			else
				line[i] = "                      (OFF)"
			end
		end

		lineA = line[11]
		lineB = line[12]
		lineC = "                        "
		lineD = "                        "
		lineE = "                        "

	end

	return {

		"                      "..pgNo.."/3",
		"F/O CALLOUTS    (CURRENTLY)",
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

end

fmsFunctionsDefs["PMCALLOUTSCONFIG"]["L6"]={"setpage","MAINTSIMCONFIG_4"}

fmsPages["PMCALLOUTSCONFIG"].getNumPages=function(self)
  return 3
end



-- VOLUME PAGE



--[[
fmsPages["VOLUME"]=createPage("VOLUME")
fmsPages["VOLUME"].getPage=function(self,pgNo,fmsID)

	local lineA = "                        "
	local lineB = "                        "
	fmsFunctionsDefs["VOLUME"]["R6"]={"setSoundOption","resetAllSounds"}

	if pgNo == 1 then

		fmsFunctionsDefs["VOLUME"]["L1"]={"setSoundOption","alarmsSUB"}
		fmsFunctionsDefs["VOLUME"]["L2"]={"setSoundOption","alarmsMute"}
		fmsFunctionsDefs["VOLUME"]["L3"]={"setSoundOption","windSUB"}
		fmsFunctionsDefs["VOLUME"]["L4"]={"setSoundOption","windMute"}
		fmsFunctionsDefs["VOLUME"]["R1"]={"setSoundOption","alarmsADD"}
		fmsFunctionsDefs["VOLUME"]["R2"]={"setSoundOption","alarmsRST"}
		fmsFunctionsDefs["VOLUME"]["R3"]={"setSoundOption","windADD"}
		fmsFunctionsDefs["VOLUME"]["R4"]={"setSoundOption","windRST"}

		lineA = B747DR_SNDoptions_volume[0]
		lineB = B747DR_SNDoptions_volume[1]

	elseif pgNo == 2 then

		fmsFunctionsDefs["VOLUME"]["L1"]={"setSoundOption","gndRollSUB"}
		fmsFunctionsDefs["VOLUME"]["L2"]={"setSoundOption","gndRollMute"}
		fmsFunctionsDefs["VOLUME"]["L3"]={"setSoundOption","enginesSUB"}
		fmsFunctionsDefs["VOLUME"]["L4"]={"setSoundOption","enginesMute"}
		fmsFunctionsDefs["VOLUME"]["R1"]={"setSoundOption","gndRollADD"}
		fmsFunctionsDefs["VOLUME"]["R2"]={"setSoundOption","gndRollRST"}
		fmsFunctionsDefs["VOLUME"]["R3"]={"setSoundOption","enginesADD"}
		fmsFunctionsDefs["VOLUME"]["R4"]={"setSoundOption","enginesRST"}

		lineA = B747DR_SNDoptions_volume[2]
		lineB = B747DR_SNDoptions_volume[3]

	elseif pgNo == 3 then

		fmsFunctionsDefs["VOLUME"]["L1"]={"setSoundOption","buttonsSUB"}
		fmsFunctionsDefs["VOLUME"]["L2"]={"setSoundOption","buttonsMute"}
		fmsFunctionsDefs["VOLUME"]["L3"]={"setSoundOption","PA_SUB"}
		fmsFunctionsDefs["VOLUME"]["L4"]={"setSoundOption","PA_Mute"}
		fmsFunctionsDefs["VOLUME"]["R1"]={"setSoundOption","buttonsADD"}
		fmsFunctionsDefs["VOLUME"]["R2"]={"setSoundOption","buttonsRST"}
		fmsFunctionsDefs["VOLUME"]["R3"]={"setSoundOption","PA_ADD"}
		fmsFunctionsDefs["VOLUME"]["R4"]={"setSoundOption","PA_RST"}

		lineA = B747DR_SNDoptions_volume[4]
		lineB = B747DR_SNDoptions_volume[5]

	elseif pgNo == 4 then

		fmsFunctionsDefs["VOLUME"]["L1"]={"setSoundOption","musicSUB"}
		fmsFunctionsDefs["VOLUME"]["L2"]={"setSoundOption","musicMute"}
		fmsFunctionsDefs["VOLUME"]["L3"]=nil
		fmsFunctionsDefs["VOLUME"]["L4"]=nil
		fmsFunctionsDefs["VOLUME"]["R1"]={"setSoundOption","musicADD"}
		fmsFunctionsDefs["VOLUME"]["R2"]={"setSoundOption","musicRST"}
		fmsFunctionsDefs["VOLUME"]["R3"]=nil
		fmsFunctionsDefs["VOLUME"]["R4"]=nil

		lineA = B747DR_SNDoptions_volume[6]
		lineB = " "

	end

	return {
		"     Volume Controls    ",
		"                        ",
		"-          "..lineA.."          +",
		"                        ",
		"<MUTE             RESET>",
		"                        ",
		"-          "..lineB.."          +",
		"                        ",
		"<MUTE             RESET>",
		"                        ",
		"                        ",
		"------------------------",
		"<SIMCONFIG    RESET ALL>"
	}

end


fmsPages["VOLUME"].getSmallPage=function(self,pgNo,fmsID)

	local lineA = "                        "
	local lineB = "                        "

	if pgNo == 1 then

		lineA = "         ALARMS         "
		lineB = "          WIND          "

	elseif pgNo == 2 then

		lineA = "      GROUND CONTACT    "
		lineB = "         ENGINES        "

	elseif pgNo == 3 then

		lineA = "     COCKPIT BUTTONS    "
		lineB = "    PA ANNOUNCEMENTS    "

	elseif pgNo == 4 then

		lineA = "     BOARDING MUSIC     "
		lineB = "                        "

	end

	return {
		"                     "..pgNo.."/4",
		"                        ",
		"             /10        ",
		lineA,
		"                        ",
		"                        ",
		"             /10        ",
		lineB,
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        "
	}

end

fmsFunctionsDefs["VOLUME"]["L6"]={"setpage","MAINTSIMCONFIG_4"}

fmsPages["VOLUME"].getNumPages=function(self)
	return 4
end
]]
