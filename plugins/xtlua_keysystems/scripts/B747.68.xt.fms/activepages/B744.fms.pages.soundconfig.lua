
-- WRITTEN BY CRAZYTIMTIMTIM


-- passenger sound page


fmsPages["PASSENGERSOUNDCONFIG"]=createPage("PASSENGERSOUNDCONFIG")
fmsPages["PASSENGERSOUNDCONFIG"].getPage=function(self,pgNo,fmsID)

	fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L1"]={"setSoundOption","seatBeltOption"}
	fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L2"]={"setSoundOption","paOption"}
	fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L3"]={"setSoundOption","musicOption"}

	local lineA = "                  (STBLT)"
	local lineB = "                     (PA)"
	local lineC = "                  (MUSIC)"

	if B747DR_SNDoptions[1] == 0 then
		lineA = "   /ON"
	else
		lineA = "OFF/  "
	end

	if B747DR_SNDoptions[2] == 0 then
		lineB = "   /ON"
	else
		lineB = "OFF/  "
	end

	if B747DR_SNDoptions[3] == 0 then
		lineC = "   /ON"
	else
		lineC = "OFF/  "
	end

		return{
		"    PASSENGER SOUNDS    ",
		"                        ",
		"<SEATBELT SOUND   "..lineA,
		"                        ",
		"<FLIGHT ATTEND.   "..lineB,
		"                        ",
		"<BOARDING MUSIC   "..lineC,
		"                        ",
		"                        ", --"<PASSENGERS             ",
		"                        ",
		"                        ",
		"------------------------",
		"<SOUND CONFIG           "
		}

end

fmsPages["PASSENGERSOUNDCONFIG"].getSmallPage=function(self,pgNo,fmsID)

	local lineA = "                  (STBLT)"
	local lineB = "                     (PA)"
	local lineC = "                  (MUSIC)"

	if B747DR_SNDoptions[1] == 0 then
		lineA = "                  OFF   "
	else
		lineA = "                      ON"
	end

	if B747DR_SNDoptions[2] == 0 then
		lineB = "                  OFF   "
	else
		lineB = "                      ON"
	end

	if B747DR_SNDoptions[3] == 0 then
		lineC = "                  OFF   "
	else
		lineC = "                      ON"
	end

	return{
		"                     1/1",
		"                        ",
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

fmsFunctionsDefs["PASSENGERSOUNDCONFIG"]["L6"]={"setpage","MAINTSIMCONFIG_5"}



-- GPWS SOUND PAGE



fmsPages["GPWSSOUNDCONFIG"]=createPage("GPWSSOUNDCONFIG")
fmsPages["GPWSSOUNDCONFIG"].getPage=function(self,pgNo,fmsID)

	local lineA = ""
	local lineB = ""
	local lineC = ""
	local lineD = ""
	local lineE = ""

	local lineA2 = ""
	local lineB2 = ""
	local lineC2 = ""
	local lineD2 = ""
	local lineE2 = ""
	local line = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"}

	if pgNo == 1 then

		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L1"]={"setSoundOption","GPWSminimums"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L2"]={"setSoundOption","GPWSapproachingMinimums"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L3"]={"setSoundOption","GPWS2500"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L4"]={"setSoundOption","GPWS1000"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L5"]={"setSoundOption","GPWS500"}

		lineA = "<MINIMUMS     "
		lineB = "<APP. MINIMUMS"
		lineC = "<2500         "
		lineD = "<1000         "
		lineE = "<500          "

		for i = 1, 5 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "ON/   "
			else
				line[i] = "  /OFF"
			end
		end

		lineA2 = line[1]
		lineB2 = line[2]
		lineC2 = line[3]
		lineD2 = line[4]
		lineE2 = line[5]

	elseif pgNo == 2 then

		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L1"]={"setSoundOption","GPWS400"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L2"]={"setSoundOption","GPWS300"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L3"]={"setSoundOption","GPWS200"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L4"]={"setSoundOption","GPWS100"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L5"]={"setSoundOption","GPWS50"}

		lineA = "<400          "
		lineB = "<300          "
		lineC = "<200          "
		lineD = "<100          "
		lineE = "<50           "

		for i = 6, 10 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "ON/   "
			else
				line[i] = "  /OFF"
			end
		end

		lineA2 = line[6]
		lineB2 = line[7]
		lineC2 = line[8]
		lineD2 = line[9]
		lineE2 = line[10]

	elseif pgNo == 3 then

		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L1"]={"setSoundOption","GPWS40"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L2"]={"setSoundOption","GPWS30"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L3"]={"setSoundOption","GPWS20"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L4"]={"setSoundOption","GPWS10"}
		fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L5"]={"setSoundOption","GPWS5"}

		lineA = "<40           "
		lineB = "<30           "
		lineC = "<20           "
		lineD = "<10           "
		lineE = "<5            "

		for i = 11, 15 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "ON/   "
			else
				line[i] = "  /OFF"
			end
		end

		lineA2 = line[11]
		lineB2 = line[12]
		lineC2 = line[13]
		lineD2 = line[14]
		lineE2 = line[15]

	end

	return {
		"      GPWS CONFIG       ",
		"                        ",
		lineA.."    "..lineA2,
		"                        ",
		lineB.."    "..lineB2,
		"                        ",
		lineC.."    "..lineC2,
		"                        ",
		lineD.."    "..lineD2,
		"                        ",
		lineE.."    "..lineE2,
		"------------------------",
		"<SOUND CONFIG           "
	}

end

fmsPages["GPWSSOUNDCONFIG"].getSmallPage=function(self,pgNo,fmsID)

	local lineA = ""
	local lineB = ""
	local lineC = ""
	local lineD = ""
	local lineE = ""
	local line = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15"}

	if pgNo == 1 then

		for i = 1, 5 do
			if B747DR_SNDoptions_gpws[i] == 0 then
				line[i] = "   OFF"
			else
				line[i] = "ON    "
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
				line[i] = "   OFF"
			else
				line[i] = "ON    "
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
				line[i] = "   OFF"
			else
				line[i] = "ON    "
			end
		end

		lineA = line[11]
		lineB = line[12]
		lineC = line[13]
		lineD = line[14]
		lineE = line[15]

	end

	return {

		"                     "..pgNo.."/3",
		"                        ",
		
		"                  "..lineA,
		"                        ",
		"                  "..lineB,
		"                        ",
		"                  "..lineC,
		"                        ",
		"                  "..lineD,
		"                        ",
		"                  "..lineE,
		"                        ",
		"                        "
	}

end

fmsFunctionsDefs["GPWSSOUNDCONFIG"]["L6"]={"setpage","MAINTSIMCONFIG_4"}

fmsPages["GPWSSOUNDCONFIG"].getNumPages=function(self)
	return 3
end


-- GENERAL SOUNDS



fmsPages["MISCSOUNDCONFIG"]=createPage("MISCSOUNDCONFIG")
fmsPages["MISCSOUNDCONFIG"].getPage=function(self,pgNo,fmsID)

	local lineA = "OLD/DEFLT/NEW"
	local lineB = "ON/OFF"
	local lineC = "ON/OFF"

	fmsFunctionsDefs["MISCSOUNDCONFIG"]["L1"]={"setSoundOption","PM_toggle"}
	fmsFunctionsDefs["MISCSOUNDCONFIG"]["L2"]={"setSoundOption", "alarmsOption"}
	fmsFunctionsDefs["MISCSOUNDCONFIG"]["L3"]={"setSoundOption", "V1Option"}
	fmsFunctionsDefs["MISCSOUNDCONFIG"]["L6"]={"setpage","MAINTSIMCONFIG_4"}

	if B747DR_SNDoptions[4] == 1 then
		lineA = "  /OFF"
	elseif B747DR_SNDoptions[4] == 0 then
		lineA = "ON/   "
	end

	if B747DR_SNDoptions[0] == 0 then
		lineB = "   /DEFLT/   "
	elseif B747DR_SNDoptions[0] == 1 then
		lineB = "   /     /NEW"
	elseif B747DR_SNDoptions[0] == 2 then
		lineB = "OLD/     /   "
	end

	if B747DR_SNDoptions[5] == 0 then
		lineC = "ON/   "
	elseif B747DR_SNDoptions[5] == 1 then
		lineC = "  /OFF"
	end

	return {
		"     GENERAL SOUNDS     ",
		"                        ",
		"<F/O CALLOUTS     "..lineA,
		"                        ",
		"<Warnings  "..lineB,
		"                        ",
		"<V1 Callout       "..lineC,
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"------------------------",
		"<SOUND CONFIG            "
	}

end

fmsPages["MISCSOUNDCONFIG"].getSmallPage=function(self,pgNo,fmsID)

	local lineA = "ON/OFF"
	local lineB = "OLD/DEFLT/NEW"
	local lineC = "ON/OFF"

	if B747DR_SNDoptions[4] == 1 then
		lineA = "ON    "
	elseif B747DR_SNDoptions[4] == 0 then
		lineA = "   OFF"
	end

	if B747DR_SNDoptions[0] == 0 then
		lineB = "OLD       NEW"
	elseif B747DR_SNDoptions[0] == 1 then
		lineB = "OLD DEFLT    "
	elseif B747DR_SNDoptions[0] == 2 then
		lineB = "    DEFLT NEW"
	end

	if B747DR_SNDoptions[5] == 0 then
		lineC = "  /OFF"
	elseif B747DR_SNDoptions[5] == 1 then
		lineC = "ON/   "
	end

	return {
		"                     1/1",
		"                        ",
		"                  "..lineA,
		"                        ",
		"           "..lineB,
		"                        ",
		"                  "..lineC,
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        ",
		"                        "
	}

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