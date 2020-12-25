--[[
*****************************************************************************************
* Program Script Name	:	B747.87.warning
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2016-04-26	0.01a				Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED
*****************************************************************************************
--]]


--#####################################################################################--
--#                   EICAS MESSAGE FUNCTIONALITY & DESCRIPTION                       #--
--#####################################################################################--
--[[

IN ANY SCRIPT THE MESSAGE STATUS DATAREFS "B747DR_CAS_warning_status[X]", 'B747DR_CAS_caution_status[X]",
"B747DR_CAS_advisory_status[X]", OR "B747DR_CAS_memo_status[X]" SHOULD BE SET = 1 (ONE) OR 0 (ZERO),
WHICH INDICATES THAT THE EICAS MESSAGE SHOULD BE ACTIVATED OR DE-ACTIVATED.

THEN, THE SYSTEM AUTOMATICALLY COMPARES THE STATUS DATAREFS WITH THE APPROPRIATE MESSAGE
DATABASE TABLE AND DETERMINES IF THE MESSAGE HAS CHANGED.

IF THE MESSAGE HAS BEEN CHANGED IT IS ADDED OR REMOVED FROM THE DISPLAY "QUEUE" APPROPRIATELY.

FINALLY, THE DISPLAY QUEUE IS ITERATED AND THE DISPLAY PAGES ARE BUILT TO SET UP THE VALUES
FOR THE GENERIC TEXT INSTRUMENTS.

--]]



--*************************************************************************************--
--** 					              XLUA GLOBALS              				     **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]

function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end
--replace deferred_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

local NUM_ALERT_MESSAGES = 109

local B747_CASmemoMsg ={}
local B747_CASadvisoryMsg={}
local B747_CAScautionMsg={}
local B747_CASwarningMsg={}
B747_CASwarningMsg   = {
    {DRindex = 0, name = ">AUTOPILOT DISC", status = 0},        --
    {DRindex = 1, name = "CABIN ALTITUDE", status = 0},         --
    {DRindex = 2, name = ">CONFIG FLAPS", status = 0},          --
    {DRindex = 3, name = ">CONFIG GEAR", status = 0},           --
    {DRindex = 4, name = ">CONFIG GEAR CTR", status = 0},
    {DRindex = 5, name = ">CONFIG PARK BRK", status = 0},       --
    {DRindex = 6, name = ">CONFIG SPOILERS", status = 0},       --
    {DRindex = 7, name = ">CONFIG STAB", status = 0},           --
    {DRindex = 8, name = "FIRE APU", status = 0},
    {DRindex = 9, name = "FIRE CARGO AFT", status = 0},
    {DRindex = 10, name = "FIRE CARGO FWD", status = 0},
    {DRindex = 11, name = "FIRE ENG 1", status = 0},            --
    {DRindex = 12, name = "FIRE ENG 2", status = 0},            --
    {DRindex = 13, name = "FIRE ENG 3", status = 0},            --
    {DRindex = 14, name = "FIRE ENG 4", status = 0},            --
    {DRindex = 15, name = "FIRE MAIN DECK", status = 0},
    {DRindex = 16, name = "FIRE MN DK FWD", status = 0},
    {DRindex = 17, name = "FIRE MN DK MID", status = 0},
    {DRindex = 18, name = "FIRE MN DK AFT", status = 0},
    {DRindex = 19, name = ">FIRE TEST FAIL", status = 0},
    {DRindex = 20, name = ">FIRE TEST PASS", status = 0},
    {DRindex = 21, name = "FIRE WHEEL WELL", status = 0},
    {DRindex = 22, name = ">OVERSPEED", status = 0},            --
    {DRindex = 23, name = ">PILOT RESPONSE", status = 0},
    {DRindex = 24, name = ">TEST IN PROG", status = 0},
    {DRindex = 25, name = ">VALVE TEST FAIL", status = 0},
    {DRindex = 26, name = ">VALVE TEST PASS", status = 0},
    {DRindex = 27, name = ">VLV TST IN PROG", status = 0},
}

B747_CAScautionMsg   = {
    {DRindex = 0, name = ">AIRSPEED LOW", status = 0},          --
    {DRindex = 1, name = "ALT DISAGREE", status = 0},
    {DRindex = 2, name = ">ALTITUDE ALERT", status = 0},
    {DRindex = 3, name = ">ATTITUDE", status = 0},
    {DRindex = 4, name = ">AUTOPILOT", status = 0},             --
    {DRindex = 5, name = ">AUTOTHROT DISC", status = 0},
    {DRindex = 6, name = "BLD DUCT LEAK C", status = 0},
    {DRindex = 7, name = "BLD DUCT LEAK L", status = 0},
    {DRindex = 8, name = "BLD DUCT LEAK R", status = 0},
    {DRindex = 9, name = ">BRAKE SOURCE", status = 0},          --
    {DRindex = 10, name = "CABIN ALT AUTO", status = 0},        --
    {DRindex = 11, name = "DOOR AFT CARGO", status = 0},
    {DRindex = 12, name = "DOOR FWD CARGO", status = 0},
    {DRindex = 13, name = "DOOR SIDE CARGO", status = 0},
    {DRindex = 14, name = "DOOR U/D FLT LK", status = 0},
    {DRindex = 15, name = "ELEC AC BUS 1", status = 0},
    {DRindex = 16, name = "ELEC AC BUS 2", status = 0},
    {DRindex = 17, name = "ELEC AC BUS 3", status = 0},
    {DRindex = 18, name = "ELEC AC BUS 4", status = 0},
    {DRindex = 19, name = "ENG 1 AUTOSTART", status = 0},
    {DRindex = 20, name = "ENG 2 AUTOSTART", status = 0},
    {DRindex = 21, name = "ENG 3 AUTOSTART", status = 0},
    {DRindex = 22, name = "ENG 4 AUTOSTART", status = 0},
    {DRindex = 23, name = ">ENG 1 SHUTDOWN", status = 0},       --
    {DRindex = 24, name = ">ENG 2 SHUTDOWN", status = 0},       --
    {DRindex = 25, name = ">ENG 3 SHUTDOWN", status = 0},       --
    {DRindex = 26, name = ">ENG 4 SHUTDOWN", status = 0},       --
    {DRindex = 27, name = "EQUIP COOLING", status = 0},
    {DRindex = 28, name = "FLAPS CONTROL", status = 0},         --
    {DRindex = 29, name = "FLAPS DRIVE", status = 0},
    {DRindex = 30, name = "FLAPS PRIMARY", status = 0},
    {DRindex = 31, name = "FUEL JETT SYS", status = 0},         --
    {DRindex = 32, name = "FUEL PRESS ENG 1", status = 0},
    {DRindex = 33, name = "FUEL PRESS ENG 2", status = 0},
    {DRindex = 34, name = "FUEL PRESS ENG 3", status = 0},
    {DRindex = 35, name = "FUEL PRESS ENG 4", status = 0},
    {DRindex = 36, name = "FUEL QTY LOW", status = 0},          --
    {DRindex = 37, name = "FUEL STAB XFR", status = 0},
    {DRindex = 38, name = "GEAR DISAGREE", status = 0},
    {DRindex = 39, name = "GEAR TILT", status = 0},
    {DRindex = 40, name = "HYD PRESS SYS 1", status = 0},       --
    {DRindex = 41, name = "HYD PRESS SYS 2", status = 0},       --
    {DRindex = 42, name = "HYD PRESS SYS 3", status = 0},       --
    {DRindex = 43, name = "HYD PRESS SYS 4", status = 0},       --
    {DRindex = 44, name = "IAS DISAGREE", status = 0},
    {DRindex = 45, name = ">ICING", status = 0},                --
    {DRindex = 46, name = ">ICING NAC", status = 0},
    {DRindex = 47, name = "ILS ANTENNA", status = 0},
    {DRindex = 48, name = "MLS ANTENNA", status = 0},
    {DRindex = 49, name = ">NO AUTOLAND", status = 0},
    {DRindex = 50, name = ">NO LAND 3", status = 0},
    {DRindex = 51, name = ">PILOT RESPONSE", status = 0},
    {DRindex = 52, name = "SMOKE DR 5 REST", status = 0},
    {DRindex = 53, name = ">SMOKE LAVATORY", status = 0},
    {DRindex = 54, name = ">SMOKE LAV/COMP", status = 0},
    {DRindex = 55, name = ">SMOKE ZN B REST", status = 0},
    {DRindex = 56, name = ">SMOKE ZN F REST", status = 0},
    {DRindex = 57, name = ">SNGL SOURCE ILS", status = 0},
    {DRindex = 58, name = ">SNGL SOURCE MLS", status = 0},
    {DRindex = 59, name = ">SPEEDBRAKES EXT", status = 0},      --
    {DRindex = 60, name = "STAB TRIM UNSCHD", status = 0},
    {DRindex = 61, name = "STARTER CUTOUT 1", status = 0},      --
    {DRindex = 62, name = "STARTER CUTOUT 2", status = 0},      --
    {DRindex = 63, name = "STARTER CUTOUT 3", status = 0},      --
    {DRindex = 64, name = "STARTER CUTOUT 4", status = 0},      --
    {DRindex = 65, name = "TIRE PRESSURE", status = 0},
    {DRindex = 66, name = "UNABLE RNP", status = 0},
}

B747_CASadvisoryMsg   = {
    {DRindex = 0, name = ">ADC CENTRE", status = 0},
    {DRindex = 1, name = ">ADC LEFT", status = 0},
    {DRindex = 2, name = ">ADC RIGHT", status = 0},
    {DRindex = 3, name = "AILERON LOCKOUT", status = 0},
    {DRindex = 4, name = ">ALT ALERT SYS", status = 0},
    {DRindex = 5, name = "AIR/GND SYSTEM", status = 0},
    {DRindex = 6, name = ">ALT CALLOUTS", status = 0},
    {DRindex = 7, name = ">ANTI-ICE", status = 0},              --
    {DRindex = 8, name = ">ANTI-ICE NAC", status = 0},
    {DRindex = 9, name = ">ANTI ICE WING", status = 0},
    {DRindex = 10, name = "ANTISKID", status = 0},
    {DRindex = 11, name = "ANTISKID OFF", status = 0},
    {DRindex = 12, name = ">AOA RIGHT", status = 0},            --
    {DRindex = 13, name = "APU", status = 0},                   --
    {DRindex = 14, name = "APU DOOR", status = 0},              --
    {DRindex = 15, name = "APU FUEL", status = 0},              --
    {DRindex = 16, name = ">APU GEN 1", status = 0},
    {DRindex = 17, name = "AUTOBRAKES", status = 0},
    {DRindex = 18, name = ">BARO DISAGREE", status = 0},        --
    {DRindex = 19, name = ">BAT DISCH APU", status = 0},
    {DRindex = 20, name = ">BAT DISCH MAIN", status = 0},
    {DRindex = 21, name = ">BATTERY OFF", status = 0},
    {DRindex = 22, name = "BLD 1 OVHT/PRV", status = 0},
    {DRindex = 23, name = "BLD 2 OVHT/PRV", status = 0},
    {DRindex = 24, name = "BLD 3 OVHT/PRV", status = 0},
    {DRindex = 25, name = "BLD 4 OVHT/PRV", status = 0},
    {DRindex = 26, name = "BLEED 1", status = 0},
    {DRindex = 27, name = "BLEED 2", status = 0},
    {DRindex = 28, name = "BLEED 3", status = 0},
    {DRindex = 29, name = "BLEED 4", status = 0},
    {DRindex = 30, name = "BLEED HP ENG 1", status = 0},
    {DRindex = 31, name = "BLEED HP ENG 2", status = 0},
    {DRindex = 32, name = "BLEED HP ENG 3", status = 0},
    {DRindex = 33, name = "BLEED HP ENG 4", status = 0},
    {DRindex = 34, name = ">BLEED ISLN APU", status = 0},
    {DRindex = 35, name = "BLEED ISLN L", status = 0},
    {DRindex = 36, name = "BLEED ISLN R", status = 0},
    {DRindex = 37, name = "BLEED LOSS L", status = 0},
    {DRindex = 38, name = "BLEED LOSS R", status = 0},
    {DRindex = 39, name = ">BLEED 1 OFF", status = 0},          --
    {DRindex = 40, name = ">BLEED 2 OFF", status = 0},          --
    {DRindex = 41, name = ">BLEED 3 OFF", status = 0},          --
    {DRindex = 42, name = ">BLEED 4 OFF", status = 0},          --
    {DRindex = 43, name = ">BODY GEAR STRG", status = 0},
    {DRindex = 44, name = ">BOTTLE LOW APU", status = 0},
    {DRindex = 45, name = "BRAKE LIMITER", status = 0},
    {DRindex = 46, name = "BRAKE TEMP", status = 0},
    {DRindex = 47, name = ">BTL LOW APU A", status = 0},
    {DRindex = 48, name = ">BTL LOW APU B", status = 0},
    {DRindex = 49, name = ">CARGO DET AIR", status = 0},
    {DRindex = 50, name = ">CDU MENU", status = 0},
    {DRindex = 51, name = ">CGO BTL DISCH", status = 0},
    {DRindex = 52, name = ">CONFIG WARN SY", status = 0},
    {DRindex = 53, name = ">CREW OXY LOW", status = 0},
    {DRindex = 54, name = "CREW RST OXY ON", status = 0},
    {DRindex = 55, name = ">DATALINK AVAIL", status = 0},
    {DRindex = 56, name = ">DATALINK LOST", status = 0},
    {DRindex = 57, name = ">DATALINK SYS", status = 0},
    {DRindex = 58, name = ">DET FIRE APU", status = 0},
    {DRindex = 59, name = ">DET FIRE/OHT 1", status = 0},
    {DRindex = 60, name = ">DET FIRE/OHT 2", status = 0},
    {DRindex = 61, name = ">DET FIRE/OHT 3", status = 0},
    {DRindex = 62, name = ">DET FIRE/OHT 4", status = 0},
    {DRindex = 63, name = "DOOR BULK CARGO", status = 0},
    {DRindex = 64, name = "DOOR ELEC CTR", status = 0},
    {DRindex = 65, name = "DOOR ELEC MAIN", status = 0},
    {DRindex = 66, name = "DOOR ENTRY L1", status = 0},         --
    {DRindex = 67, name = "DOOR ENTRY L2", status = 0},
    {DRindex = 68, name = "DOOR ENTRY L3", status = 0},
    {DRindex = 69, name = "DOOR ENTRY L4", status = 0},
    {DRindex = 70, name = "DOOR ENTRY L5", status = 0},
    {DRindex = 71, name = "DOOR ENTRY R1", status = 0},
    {DRindex = 72, name = "DOOR ENTRY R2", status = 0},
    {DRindex = 73, name = "DOOR ENTRY R3", status = 0},
    {DRindex = 74, name = "DOOR ENTRY R4", status = 0},
    {DRindex = 75, name = "DOOR ENTRY R5", status = 0},
    {DRindex = 76, name = "DOOR L UPPER DK", status = 0},       --
    {DRindex = 77, name = "DOOR R UPPER DK", status = 0},
    {DRindex = 78, name = "DOOR U/D FLT LK", status = 0},
    {DRindex = 79, name = "DOORS ELEC", status = 0},
    {DRindex = 80, name = "DOORS ENTRY L", status = 0},
    {DRindex = 81, name = "DOORS ENTRY R", status = 0},
    {DRindex = 82, name = "DOORS UPR DECK", status = 0},
    {DRindex = 83, name = ">DRIVE DISC 1", status = 0},         --
    {DRindex = 84, name = ">DRIVE DISC 2", status = 0},         --
    {DRindex = 85, name = ">DRIVE DISC 3", status = 0},         --
    {DRindex = 86, name = ">DRIVE DISC 4", status = 0},         --
    {DRindex = 87, name = ">E/E CLNG CARD", status = 0},
    {DRindex = 88, name = ">EFIS CONTROL L", status = 0},
    {DRindex = 89, name = ">EFIS CONTROL R", status = 0},
    {DRindex = 90, name = ">EFIS/EICAS C/P", status = 0},
    {DRindex = 91, name = ">EIU LEFT", status = 0},
    {DRindex = 92, name = "ELEC BUS ISLN 1", status = 0},
    {DRindex = 93, name = "ELEC BUS ISLN 2", status = 0},
    {DRindex = 94, name = "ELEC BUS ISLN 3", status = 0},
    {DRindex = 95, name = "ELEC BUS ISLN 4", status = 0},
    {DRindex = 96, name = "ELEC DRIVE 1", status = 0},
    {DRindex = 97, name = "ELEC DRIVE 2", status = 0},
    {DRindex = 98, name = "ELEC DRIVE 3", status = 0},
    {DRindex = 99, name = "ELEC DRIVE 4", status = 0},
    {DRindex = 100, name = "ELEC GEN OFF 1", status = 0},
    {DRindex = 101, name = "ELEC GEN OFF 2", status = 0},
    {DRindex = 102, name = "ELEC GEN OFF 3", status = 0},
    {DRindex = 103, name = "ELEC GEN OFF 4", status = 0},
    {DRindex = 104, name = ">ELEC SSB OPEN", status = 0},
    {DRindex = 105, name = "ELEC UTIL BUS L", status = 0},      --
    {DRindex = 106, name = "ELEC UTIL BUS R", status = 0},      --
    {DRindex = 107, name = ">ELT ON", status = 0},
    {DRindex = 108, name = ">EMER LIGHTS", status = 0},
    {DRindex = 109, name = "ENG IGNITION", status = 0},
    {DRindex = 110, name = ">ENG 1 CONTROL", status = 0},
    {DRindex = 111, name = ">ENG 2 CONTROL", status = 0},
    {DRindex = 112, name = ">ENG 3 CONTROL", status = 0},
    {DRindex = 113, name = ">ENG 4 CONTROL", status = 0},
    {DRindex = 114, name = "ENG 1 FUEL FILT", status = 0},      --
    {DRindex = 115, name = "ENG 2 FUEL FILT", status = 0},      --
    {DRindex = 116, name = "ENG 3 FUEL FILT", status = 0},      --
    {DRindex = 117, name = "ENG 4 FUEL FILT", status = 0},      --
    {DRindex = 118, name = "ENG 1 OIL TEMP", status = 0},       --
    {DRindex = 119, name = "ENG 2 OIL TEMP", status = 0},       --
    {DRindex = 120, name = "ENG 3 OIL TEMP", status = 0},       --
    {DRindex = 121, name = "ENG 4 OIL TEMP", status = 0},       --
    {DRindex = 122, name = "ENG 1 REV LIMTD", status = 0},
    {DRindex = 123, name = "ENG 2 REV LIMTD", status = 0},
    {DRindex = 124, name = "ENG 3 REV LIMTD", status = 0},
    {DRindex = 125, name = "ENG 4 REV LIMTD", status = 0},
    {DRindex = 126, name = "ENG 1 REVERSER", status = 0},       --
    {DRindex = 127, name = "ENG 2 REVERSER", status = 0},       --
    {DRindex = 128, name = "ENG 3 REVERSER", status = 0},       --
    {DRindex = 129, name = "ENG 4 REVERSER", status = 0},       --
    {DRindex = 130, name = ">ENG 1 REVERSER", status = 0},
    {DRindex = 131, name = ">ENG 2 REVERSER", status = 0},
    {DRindex = 132, name = ">ENG 3 REVERSER", status = 0},
    {DRindex = 133, name = ">ENG 4 REVERSER", status = 0},
    {DRindex = 134, name = ">ENG 1 RPM LIM", status = 0},       --
    {DRindex = 135, name = ">ENG 2 RPM LIM", status = 0},       --
    {DRindex = 136, name = ">ENG 3 RPM LIM", status = 0},       --
    {DRindex = 137, name = ">ENG 4 RPM LIM", status = 0},       --
    {DRindex = 138, name = "ENG 1 START VLV", status = 0},
    {DRindex = 139, name = "ENG 2 START VLV", status = 0},
    {DRindex = 140, name = "ENG 3 START VLV", status = 0},
    {DRindex = 141, name = "ENG 4 START VLV", status = 0},
    {DRindex = 142, name = ">FLAP RELIEF", status = 0},
    {DRindex = 143, name = ">FLT CONT VLVS", status = 0},
    {DRindex = 144, name = "FMC LEFT", status = 0},
    {DRindex = 145, name = ">FMC MESSAGE", status = 0},
    {DRindex = 146, name = "FMC RIGHT", status = 0},
    {DRindex = 147, name = ">FMC STATUS", status = 0},
    {DRindex = 148, name = "FUEL IMBALANCE", status = 0},       --
    {DRindex = 149, name = "FUEL IMBAL 1-4", status = 0},       --
    {DRindex = 150, name = "FUEL IMBAL 2-3", status = 0},       --
    {DRindex = 151, name = ">FUEL JETT A", status = 0},
    {DRindex = 152, name = ">FUEL JETT B", status = 0},
    {DRindex = 153, name = "FUEL OVRD CTR L", status = 0},      --
    {DRindex = 154, name = "FUEL OVRD CTR R", status = 0},      --
    {DRindex = 155, name = "FUEL OVRD 2 AFT", status = 0},      --
    {DRindex = 156, name = "FUEL OVRD 3 AFT", status = 0},      --
    {DRindex = 157, name = "FUEL OVRD 2 FWD", status = 0},      --
    {DRindex = 158, name = "FUEL OVRD 3 FWD", status = 0},      --
    {DRindex = 159, name = "FUEL PMP STAB L", status = 0},      --
    {DRindex = 160, name = "FUEL PMP STAB R", status = 0},      --
    {DRindex = 161, name = "FUEL PUMP 1 AFT", status = 0},      --
    {DRindex = 162, name = "FUEL PUMP 2 AFT", status = 0},      --
    {DRindex = 163, name = "FUEL PUMP 3 AFT", status = 0},      --
    {DRindex = 164, name = "FUEL PUMP 4 AFT", status = 0},      --
    {DRindex = 165, name = "FUEL PUMP 1 FWD", status = 0},      --
    {DRindex = 166, name = "FUEL PUMP 2 FWD", status = 0},      --
    {DRindex = 167, name = "FUEL PUMP 3 FWD", status = 0},      --
    {DRindex = 168, name = "FUEL PUMP 4 FWD", status = 0},      --
    {DRindex = 169, name = "FUEL RES XFR 2", status = 0},
    {DRindex = 170, name = "FUEL RES XFR 3", status = 0},
    {DRindex = 171, name = ">FUEL TANK/ENG", status = 0},       --
    {DRindex = 172, name = ">FUEL TEMP LOW", status = 0},       --
    {DRindex = 173, name = "FUEL TEMP SYS", status = 0},
    {DRindex = 174, name = ">FUEL WING ISOL", status = 0},
    {DRindex = 175, name = "FUEL X FEED 1", status = 0},
    {DRindex = 176, name = "FUEL X FEED 2", status = 0},
    {DRindex = 177, name = "FUEL X FEED 3", status = 0},
    {DRindex = 178, name = "FUEL X FEED 4", status = 0},
    {DRindex = 179, name = ">FUEL XFER 1+4", status = 0},       --
    {DRindex = 180, name = "GEAR DOOR", status = 0},
    {DRindex = 181, name = "GND PROX SYS", status = 0},
    {DRindex = 182, name = ">GPS", status = 0},
    {DRindex = 183, name = ">GPS LEFT", status = 0},
    {DRindex = 184, name = ">GPS RIGHT", status = 0},
    {DRindex = 185, name = ">HEADING", status = 0},
    {DRindex = 186, name = "HEAT L AOA", status = 0},           --
    {DRindex = 187, name = "HEAT L TAT", status = 0},
    {DRindex = 188, name = "HEAT P/S CAPT", status = 0},        --
    {DRindex = 189, name = "HEAT P/S F/O", status = 0},         --
    {DRindex = 190, name = "HEAT P/S L AUX", status = 0},
    {DRindex = 191, name = "HEAT P/S R AUX", status = 0},
    {DRindex = 192, name = "HEAT R AOA", status = 0},           --
    {DRindex = 193, name = "HEAT R TAT", status = 0},
    {DRindex = 194, name = "HEAT WINDOW L", status = 0},
    {DRindex = 195, name = "HEAT WINDOW R", status = 0},
    {DRindex = 196, name = ">HUMID DOOR 5", status = 0},
    {DRindex = 197, name = ">HUMID FLT DK", status = 0},
    {DRindex = 198, name = ">HUMID MAIN CAB", status = 0},
    {DRindex = 199, name = ">HUMID ZONE F", status = 0},
    {DRindex = 200, name = "HYD CONTROL 1", status = 0},
    {DRindex = 201, name = "HYD CONTROL 4", status = 0},
    {DRindex = 202, name = "HYD OVHT SYS 1", status = 0},
    {DRindex = 203, name = "HYD OVHT SYS 2", status = 0},
    {DRindex = 204, name = "HYD OVHT SYS 3", status = 0},
    {DRindex = 205, name = "HYD OVHT SYS 4", status = 0},
    {DRindex = 206, name = "HYD PRESS DEM 1", status = 0},
    {DRindex = 207, name = "HYD PRESS DEM 2", status = 0},
    {DRindex = 208, name = "HYD PRESS DEM 3", status = 0},
    {DRindex = 209, name = "HYD PRESS DEM 4", status = 0},
    {DRindex = 210, name = "HYD PRESS ENG 1", status = 0},
    {DRindex = 211, name = "HYD PRESS ENG 2", status = 0},
    {DRindex = 212, name = "HYD PRESS ENG 3", status = 0},
    {DRindex = 213, name = "HYD PRESS ENG 4", status = 0},
    {DRindex = 214, name = ">HYD QTY HALF 1", status = 0},
    {DRindex = 215, name = ">HYD QTY HALF 2", status = 0},
    {DRindex = 216, name = ">HYD QTY HALF 3", status = 0},
    {DRindex = 217, name = ">HYD QTY HALF 4", status = 0},
    {DRindex = 218, name = ">HYD QTY LOW 1", status = 0},       --
    {DRindex = 219, name = ">HYD QTY LOW 2", status = 0},       --
    {DRindex = 220, name = ">HYD QTY LOW 3", status = 0},       --
    {DRindex = 221, name = ">HYD QTY LOW 4", status = 0},       --
    {DRindex = 222, name = ">ICE DETECTORS", status = 0},
    {DRindex = 223, name = ">IDLE DISAGREE", status = 0},
    {DRindex = 224, name = ">IFF MODE 4", status = 0},
    {DRindex = 225, name = ">IRS AC CENTRE", status = 0},
    {DRindex = 226, name = ">IRS AC LEFT", status = 0},
    {DRindex = 227, name = ">IRS AC RIGHT", status = 0},
    {DRindex = 228, name = "IRS CENTRE", status = 0},
    {DRindex = 229, name = ">IRS DC CENTRE", status = 0},
    {DRindex = 230, name = ">IRS DC LEFT", status = 0},
    {DRindex = 231, name = ">IRS DC RIGHT", status = 0},
    {DRindex = 232, name = "IRS LEFT", status = 0},
    {DRindex = 233, name = "IRS MOTION", status = 0},
    {DRindex = 234, name = "IRS RIGHT", status = 0},
    {DRindex = 235, name = ">JETT NOZ ON", status = 0},         --
    {DRindex = 236, name = ">JETT NOZ ON L", status = 0},       --
    {DRindex = 237, name = ">JETT NOZ ON R", status = 0},       --
    {DRindex = 238, name = ">JETT NOZZLE L", status = 0},
    {DRindex = 239, name = ">JETT NOZZLE R", status = 0},
    {DRindex = 240, name = "LANDING ALT", status = 0},
    {DRindex = 241, name = ">LE FLAPS DIS", status = 0},
    {DRindex = 242, name = "NAI VALVE 1", status = 0},
    {DRindex = 243, name = "NAI VALVE 2", status = 0},
    {DRindex = 244, name = "NAI VALVE 3", status = 0},
    {DRindex = 245, name = "NAI VALVE 4", status = 0},
    {DRindex = 246, name = ">NO AUTOLAND", status = 0},
    {DRindex = 247, name = ">NO ICING", status = 0},
    {DRindex = 248, name = ">NO LAND 3", status = 0},
    {DRindex = 249, name = "OUTFLOW VLV L", status = 0},
    {DRindex = 250, name = "OUTFLOW VLV R", status = 0},
    {DRindex = 251, name = "PACK CONTROL", status = 0},
    {DRindex = 252, name = "PACK 1", status = 0},
    {DRindex = 253, name = "PACK 2", status = 0},
    {DRindex = 254, name = "PACK 3", status = 0},
    {DRindex = 255, name = ">PASS OXY LOW", status = 0},
    {DRindex = 256, name = "PASS OXYGEN ON", status = 0},
    {DRindex = 257, name = ">PILOT RESPONSE", status = 0},
    {DRindex = 258, name = "PRESS RELIEF", status = 0},
    {DRindex = 259, name = ">PVD SYS CAPT", status = 0},
    {DRindex = 260, name = ">PVD SYS F/O", status = 0},
    {DRindex = 261, name = "RUD RATIO DUAL", status = 0},
    {DRindex = 262, name = "RUD RATIO SNGL", status = 0},
    {DRindex = 263, name = ">SCAV PUMP ON", status = 0},
    {DRindex = 264, name = ">SMOKE LAVATORY", status = 0},
    {DRindex = 265, name = ">SMOKE LAV/COMP", status = 0},
    {DRindex = 266, name = ">SNGL SOURCE RA", status = 0},
    {DRindex = 267, name = ">SOURCE SEL ADC", status = 0},
    {DRindex = 268, name = ">SOURCE SEL EIU", status = 0},
    {DRindex = 269, name = ">SOURCE SEL F/D", status = 0},
    {DRindex = 270, name = ">SOURCE SEL IRS", status = 0},
    {DRindex = 271, name = ">SOURCE SEL NAV", status = 0},
    {DRindex = 272, name = "SPEEDBRAKE AUTO", status = 0},
    {DRindex = 273, name = ">STAB GREENBAND", status = 0},
    {DRindex = 274, name = ">STAB TRIM 2", status = 0},
    {DRindex = 275, name = ">STAB TRIM 3", status = 0},
    {DRindex = 276, name = ">STBY BUS APU", status = 0},
    {DRindex = 277, name = ">STBY BUS MAIN", status = 0},
    {DRindex = 278, name = ">STBY POWER OFF", status = 0},
    {DRindex = 279, name = ">TCAS OFF", status = 0},
    {DRindex = 280, name = ">TCAS RA CAPT", status = 0},
    {DRindex = 281, name = ">TCAS RA F/O", status = 0},
    {DRindex = 282, name = ">TCAS SYSTEM", status = 0},
    {DRindex = 283, name = ">TEMP CARGO A/C", status = 0},
    {DRindex = 284, name = "TEMP CARGO HEAT", status = 0},
    {DRindex = 285, name = "TEMP DEV CGO HI", status = 0},
    {DRindex = 286, name = "TEMP DEV CGO LO", status = 0},
    {DRindex = 287, name = "TEMP ZONE", status = 0},
    {DRindex = 288, name = "TERR POS", status = 0},
    {DRindex = 289, name = ">TERR OVRD", status = 0},
    {DRindex = 290, name = ">TIRE PRESSURE", status = 0},
    {DRindex = 291, name = ">TRACK", status = 0},
    {DRindex = 292, name = ">TRANSPONDER L", status = 0},
    {DRindex = 293, name = ">TRANSPONDER R", status = 0},
    {DRindex = 294, name = ">TRIM AIR OFF", status = 0},
    {DRindex = 295, name = "UNABLE RNP", status = 0},
    {DRindex = 296, name = "WAI VALVE LEFT", status = 0},
    {DRindex = 297, name = "WAI VALVE RIGHT", status = 0},
    {DRindex = 298, name = ">WINDSHEAR SYS", status = 0},
    {DRindex = 299, name = ">X FEED CONFIG", status = 0},       --
    {DRindex = 300, name = ">YAW DAMPER LWR", status = 0},      --
    {DRindex = 301, name = ">YAW DAMPER UPR", status = 0},      --
}

B747_CASmemoMsg   = {
    {DRindex = 0, name = "ACARS MESSAGE", status = 0},
    {DRindex = 1, name = "APU RUNNING", status = 0},            --
    {DRindex = 2, name = "AUTOBRAKES 1", status = 0},           --
    {DRindex = 3, name = "AUTOBRAKES 2", status = 0},           --
    {DRindex = 4, name = "AUTOBRAKES 3", status = 0},           --
    {DRindex = 5, name = "AUTOBRAKES 4", status = 0},           --
    {DRindex = 6, name = "AUTOBRAKES MAX", status = 0},
    {DRindex = 7, name = "AUTOBRAKES RTO", status = 0},         --
    {DRindex = 8, name = "CON IGNITION ON", status = 0},        --
    {DRindex = 9, name = "DOORS AUTO", status = 0},
    {DRindex = 10, name = "DOORS AUTO/MAN", status = 0},
    {DRindex = 11, name = "DOORS MANUAL", status = 0},
    {DRindex = 12, name = "HF DATA OFF", status = 0},
    {DRindex = 13, name = "HIGH ALT LDG", status = 0},
    {DRindex = 14, name = "IRS ALIGN MODE L", status = 0},
    {DRindex = 15, name = "IRS ALIGN MODE C", status = 0},
    {DRindex = 16, name = "IRS ALIGN MODE R", status = 0},
    {DRindex = 17, name = "NO SMOKING ON", status = 0},         --
    {DRindex = 18, name = "PACK 1 OFF", status = 0},            --
    {DRindex = 19, name = "PACK 2 OFF", status = 0},            --
    {DRindex = 20, name = "PACK 3 OFF", status = 0},            --
    {DRindex = 21, name = "PACKS 1 + 2 OFF", status = 0},       --
    {DRindex = 22, name = "PACKS 1 + 3 OFF", status = 0},       --
    {DRindex = 23, name = "PACKS 2 + 3 OFF", status = 0},       --
    {DRindex = 24, name = "PACKS HIGH FLOW", status = 0},
    {DRindex = 25, name = "PACKS OFF", status = 0},             --
    {DRindex = 26, name = "PARK BRAKE SET", status = 0},        --
    {DRindex = 27, name = "PASS SIGNS ON", status = 0},
    {DRindex = 28, name = "PRINTER MESSAGE", status = 0},
    {DRindex = 29, name = "PVD BOTH ON", status = 0},
    {DRindex = 30, name = "PVD CAPT ON", status = 0},
    {DRindex = 31, name = "PVD F/O ON", status = 0},
    {DRindex = 32, name = "SATCOM MESSAGE", status = 0},
    {DRindex = 33, name = "SEATBELTS ON", status = 0},
    {DRindex = 34, name = "STBY IGNITION ON", status = 0},
    {DRindex = 35, name = "STROBE LIGHT OFF", status = 0},
    {DRindex = 36, name = "THERAP OXYGEN ON", status = 0},
    {DRindex = 37, name = "VHF DATA OFF", status = 0},
    {DRindex = 38, name = "VMO GEAR DOWN", status = 0},
    {DRindex = 39, name = "VMO SPARE ENGINE", status = 0},
    {DRindex = 40, name = "ACARS NO COMM", status = 0},
    {DRindex = 41, name = "ACARS CALL", status = 0},
    {DRindex = 41, name = "ACARS VOICE", status = 0},
    {DRindex = 42, name = "PRINTER MESSAGE", status = 0},
    {DRindex = 43, name = "ACARS ALERT", status = 0},
    {DRindex = 44, name = "ACARS VOICE BUSY", status = 0},
    {DRindex = 45, name = "SPEEDBRAKE ARMED", status = 0},
}





--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local B747_CASwarning   = {}
local B747_CAScaution   = {}
local B747_CASadvisory  = {}
local B747_CASmemo      = {}



--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--
simDR_bus_volts               = find_dataref("sim/cockpit2/electrical/bus_volts")

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")
simDR_all_wheels_on_ground          = find_dataref("sim/flightmodel/failures/onground_all")
simDR_ind_airspeed_kts_pilot        = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")




--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_airspeed_Vmc                 = find_dataref("laminar/B747/airspeed/Vmc")




--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--
simDR_esys1              = find_dataref("sim/operation/failures/rel_esys2")
B747DR_CAS_warning_status       = deferred_dataref("laminar/B747/CAS/warning_status", string.format("array[%s]", #B747_CASwarningMsg))
B747DR_CAS_caution_status       = deferred_dataref("laminar/B747/CAS/caution_status", string.format("array[%s]", #B747_CAScautionMsg))
B747DR_CAS_advisory_status      = deferred_dataref("laminar/B747/CAS/advisory_status", string.format("array[%s]", #B747_CASadvisoryMsg))
B747DR_CAS_memo_status          = deferred_dataref("laminar/B747/CAS/memo_status", string.format("array[%s]", #B747_CASmemoMsg))


B747DR_CAS_gen_warning_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_warning_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_warning_msg_%03d", i), "string")
end

B747DR_CAS_gen_caution_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_caution_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_caution_msg_%03d", i), "string")
end

B747DR_CAS_gen_advisory_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_advisory_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_advisory_msg_%03d", i), "string")
end

B747DR_CAS_gen_memo_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_memo_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_memo_msg_%03d", i), "string")
end


B747DR_CAS_recall_ind           = deferred_dataref("laminar/B747/CAS/recall_ind", "number")
B747DR_CAS_sec_eng_exceed_cue   = deferred_dataref("laminar/B747/CAS/sec_eng_exceed_cue", "number")
B747DR_CAS_status_cue           = deferred_dataref("laminar/B747/CAS/status_cue", "number")
B747DR_CAS_msg_page             = deferred_dataref("laminar/B747/CAS/msg_page", "number")
B747DR_CAS_num_msg_pages        = deferred_dataref("laminar/B747/CAS/num_msg_pages", "number")
B747DR_CAS_caut_adv_display     = deferred_dataref("laminar/B747/CAS/caut_adv_display", "number")


B747DR_master_warning           = find_dataref("laminar/B747/warning/master_warning")
B747DR_master_caution           = find_dataref("laminar/B747/warning/master_caution")
B747DR_fire_ovht_button_pos     = deferred_dataref("laminar/B747/fire/fire_ovht/button_pos", "number")
B747DR_init_warning_CD          = deferred_dataref("laminar/B747/warning/init_CD", "number")



--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

function B747_ai_warning_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
		B747_set_warning_all_modes()
		B747_set_warning_CD()
		B747_set_warning_ER()	
	end 	
end	




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- AI
B747CMD_ai_warning_quick_start			= deferred_command("laminar/B747/ai/warning_quick_start", "number", B747_ai_warning_quick_start_CMDhandler)



--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- RESCALE FLOAT AND CLAMP TO OUTER LIMITS -------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end




----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end


----- CREW ALERT MESSAGE TABLE REMOVE ---------------------------------------------------
function B747_removeWarning(message)

    for i = #B747_CASwarning, 1, -1 do
        if B747_CASwarning[i] == message then
            table.remove(B747_CASwarning, i)
            break
        end
    end

end

function B747_removeCaution(message)

    for i = #B747_CAScaution, 1, -1 do
        if B747_CAScaution[i] == message then
            table.remove(B747_CAScaution, i)
            break
        end
    end

end

function B747_removeAdvisory(message)

    for i = #B747_CASadvisory, 1, -1 do
        if B747_CASadvisory[i] == message then
            table.remove(B747_CASadvisory, i)
            break
        end
    end

end

function B747_removeMemo(message)
    for i = #B747_CASmemo, 1, -1 do
        if B747_CASmemo[i] == message then
            table.remove(B747_CASmemo, i)
            break
        end
    end

end



function cleanAllWhenOff()
  for i = 1, #B747_CASwarningMsg do
    B747_removeWarning(B747_CASwarningMsg[i].name)   
    B747_CASwarningMsg[i].status=0
  end
  for i = 1, #B747_CAScautionMsg do
    B747_removeCaution(B747_CAScautionMsg[i].name)
    B747_CAScautionMsg[i].status=0
  end
  for i = 1, #B747_CASadvisoryMsg do
    B747_removeAdvisory(B747_CASadvisoryMsg[i].name) 
    B747_CASadvisoryMsg[i].status=0
  end
  for i = 1, #B747_CASmemoMsg do
     B747_removeMemo(B747_CASmemoMsg[i].name)
     B747_CASmemoMsg[i].status = 0
  end
end


----- BUILD THE ALERT QUEUE -------------------------------------------------------------
function B747_CAS_queue() 

    ----- WARNINGS
    for i = 1, #B747_CASwarningMsg do                                                                   -- ITERATE THE WARNINGS DATA TABLE

        if B747_CASwarningMsg[i].status ~= B747DR_CAS_warning_status[B747_CASwarningMsg[i].DRindex] then -- THE WARNING STATUS HAS CHANGED

            if B747DR_CAS_warning_status[B747_CASwarningMsg[i].DRindex] == 1 then                       -- WARNING IS ACTIVE
                table.insert(B747_CASwarning, B747_CASwarningMsg[i].name)                               -- ADD TO THE WARNING QUEUE
                B747DR_master_warning = 1                                                               -- SET THE MASTER WARNING
            elseif B747DR_CAS_warning_status[B747_CASwarningMsg[i].DRindex] == 0 then                   -- WARNING IS INACTIVE
                B747_removeWarning(B747_CASwarningMsg[i].name)                                          -- REMOVE FROM THE WARNING QUEUE
            end
            B747_CASwarningMsg[i].status = B747DR_CAS_warning_status[B747_CASwarningMsg[i].DRindex]     -- RESET WARNING STATUS

        end

    end
    if #B747_CASwarning == 0 and B747DR_fire_ovht_button_pos==0 then 
      B747DR_master_warning = 0 
    elseif B747DR_fire_ovht_button_pos==1 then 
      B747DR_master_warning = 1 
    end 

    ----- CAUTIONS
    for i = 1, #B747_CAScautionMsg do                                                      -- ITERATE THE CAUTIONS DATA TABLE

        if B747_CAScautionMsg[i].status ~= B747DR_CAS_caution_status[B747_CAScautionMsg[i].DRindex] then -- THE CAUTION STATUS HAS CHANGED

            if B747DR_CAS_caution_status[B747_CAScautionMsg[i].DRindex] == 1 then                 -- CAUTION IS ACTIVE
                table.insert(B747_CAScaution, B747_CAScautionMsg[i].name)                  -- ADD TO THE CAUTION QUEUE
                B747DR_master_caution = 1                                                   -- SET THE MASTER CAUTION
            elseif B747DR_CAS_caution_status[B747_CAScautionMsg[i].DRindex] == 0 then             -- CAUTION IS INACTIVE
                B747_removeCaution(B747_CAScautionMsg[i].name)                             -- REMOVE FROM THE CAUTION QUEUE
            end
            B747_CAScautionMsg[i].status = B747DR_CAS_caution_status[B747_CAScautionMsg[i].DRindex]  -- RESET CAUTION STATUS
        end

    end
    if #B747_CAScaution == 0 then B747DR_master_caution = 0 end  

    ----- ADVISORIES
    for i = 1, #B747_CASadvisoryMsg do                                                      -- ITERATE THE CAUTIONS DATA TABLE

        if B747_CASadvisoryMsg[i].status ~= B747DR_CAS_advisory_status[B747_CASadvisoryMsg[i].DRindex] then -- THE CAUTION STATUS HAS CHANGED

            if B747DR_CAS_advisory_status[B747_CASadvisoryMsg[i].DRindex] == 1 then                 -- CAUTION IS ACTIVE
                table.insert(B747_CASadvisory, B747_CASadvisoryMsg[i].name)                  -- ADD TO THE CAUTION QUEUE
            elseif B747DR_CAS_advisory_status[B747_CASadvisoryMsg[i].DRindex] == 0 then             -- CAUTION IS INACTIVE
                B747_removeAdvisory(B747_CASadvisoryMsg[i].name)                             -- REMOVE FROM THE CAUTION QUEUE
            end
            B747_CASadvisoryMsg[i].status = B747DR_CAS_advisory_status[B747_CASadvisoryMsg[i].DRindex]  -- RESET CAUTION STATUS

        end

    end

    ----- MEMOS
    
    for i = 1, #B747_CASmemoMsg do                                                          -- ITERATE THE CAUTIONS DATA TABLE
	
        if B747_CASmemoMsg[i].status ~= B747DR_CAS_memo_status[B747_CASmemoMsg[i].DRindex] then    -- THE CAUTION STATUS HAS CHANGED

            if B747DR_CAS_memo_status[B747_CASmemoMsg[i].DRindex] == 1 then                        -- CAUTION IS ACTIVE
                table.insert(B747_CASmemo, B747_CASmemoMsg[i].name)                         -- ADD TO THE CAUTION QUEUE
            elseif B747DR_CAS_memo_status[B747_CASmemoMsg[i].DRindex] == 0 then                    -- CAUTION IS INACTIVE
                B747_removeMemo(B747_CASmemoMsg[i].name)                                -- REMOVE FROM THE CAUTION QUEUE
            end
            B747_CASmemoMsg[i].status = B747DR_CAS_memo_status[B747_CASmemoMsg[i].DRindex]         -- RESET CAUTION STATUS

        end

    end

end



local powered = false



----- BUILD THE CAS DISPLAY PAGES -------------------------------------------------------
function B747_CAS_display()
    
    B747DR_CAS_num_msg_pages = #B747_CASwarning
    if #B747_CASwarning < 11 then
        B747DR_CAS_num_msg_pages = math.ceil(math.max(10, (#B747_CASwarning + #B747_CAScaution + #B747_CASadvisory + #B747_CASmemo)) / 11)
    end
    local numAlertPages = 10 --math.ceil((#B747_CASwarning + #B747_CAScaution + #B747_CASadvisory + #B747_CASmemo) / 11)  -- TODO:  CHANGE TO FIXED NUMBER OF PAGES (GENERIC MESSAGES)
    local genIndex = 0
    local lastGenIndex = 0

    -- RESET ALL MESSAGES
    --[[for x = 0, NUM_ALERT_MESSAGES do
        B747DR_CAS_gen_warning_msg[x] = " "
        B747DR_CAS_gen_caution_msg[x] = " "
        B747DR_CAS_gen_advisory_msg[x] = " "
        B747DR_CAS_gen_memo_msg[x] = " "
    end]]
    local set_B747DR_CAS_gen_warning_msg={}
    local set_B747DR_CAS_gen_caution_msg={}
    local set_B747DR_CAS_gen_advisory_msg={}
    local set_B747DR_CAS_gen_memo_msg={}
    for x = 0, NUM_ALERT_MESSAGES do
        set_B747DR_CAS_gen_warning_msg[x] = 0
        set_B747DR_CAS_gen_caution_msg[x] = 0
        set_B747DR_CAS_gen_advisory_msg[x] = 0
        set_B747DR_CAS_gen_memo_msg[x] = 0
    end
    ----- WARNINGS ----------------------------------------------------------------------

    for i = #B747_CASwarning, 1, -1 do                                                      -- REVERSE ITERATE THE TABLE (GET MOST RECENT FIRST)

        B747DR_CAS_gen_warning_msg[genIndex] = B747_CASwarning[i]                               -- ASSIGN ALERT TO WARNING GENERIC
        set_B747DR_CAS_gen_warning_msg[genIndex] = 1						-- MARK IT USED
	lastGenIndex = genIndex
        if #B747_CASwarning < 11 then                                                       -- NUM WARNINGS FILLS OR EXCEEDS ONE PAGE
            for page = 2, numAlertPages  do                                                 -- ITERATE ALL OTHER ALERT PAGES
                B747DR_CAS_gen_warning_msg[((page*11)-11) + genIndex] = B747DR_CAS_gen_warning_msg[genIndex]    -- DUPLICATE THE WARNING FOR ALL PAGES
		set_B747DR_CAS_gen_warning_msg[genIndex] = 1						-- MARK IT USED
            end
        end
        genIndex = genIndex + 1                                                             -- INCREMENT THE GENERIC INDEX
	--::continue::
    end


    if #B747_CASwarning < 11 then                                                           -- FIRST PAGE NOT FULL OF WARNINGS - OK TO PROCEED

        if B747DR_CAS_caut_adv_display == 1 then

            ----- CAUTIONS --------------------------------------------------------------
            for i = #B747_CAScaution, 1, -1 do                                                      -- REVERSE ITERATE THE TABLE (MOST RECENT MESSAGE FIRST)

                B747DR_CAS_gen_caution_msg[genIndex] = B747_CAScaution[i]                           -- ASSIGN ALERT TO CAUTION GENERIC
		set_B747DR_CAS_gen_caution_msg[genIndex] =1						-- MARK IT USED
                lastGenIndex = genIndex
                genIndex = genIndex + 1                                                             -- INCREMENT THE GENERIC INDEX
                if math.fmod(genIndex, 11) == 0 then                                                -- END OF PAGE
                    genIndex = genIndex + #B747_CASwarning                                          -- INCREMENT THE INDEX BY THE NUM OF WARNINGS DISPLAYED (FOR NEXT PAGE)
                end


            end


            ----- ADVISORIES ------------------------------------------------------------
            for i = #B747_CASadvisory, 1, -1 do                                                     -- REVERSE ITERATE THE TABLE (MOST RECENT MESSAGE FIRST)

                B747DR_CAS_gen_advisory_msg[genIndex] = B747_CASadvisory[i]                             -- ASSIGN ALERT TO ADVISORY GENERIC
                set_B747DR_CAS_gen_advisory_msg[genIndex] = 1						-- MARK IT USED
		lastGenIndex = genIndex
                genIndex = genIndex + 1                                                             -- INCREMENT THE GENERIC INDEX
                if math.fmod(genIndex, 11) == 0 then                                                -- END OF PAGE
                    genIndex = genIndex + #B747_CASwarning                                          -- INCREMENT THE INDEX BY THE NUM OF WARNINGS DISPLAYED (FOR NEXT PAGE)
                end

            end

        end


        ----- MEMOS ---------------------------------------------------------------------
        local memoPageCheck = 1                                                                 -- FIST MEMO PAGE CHECK FLAG
        local increment = -1                                                                    -- INITIAL DISPLAY DIRECTION IS BOTTOM UP
        --local lastIndex = genIndex                                                              -- SAVE THE LAST GENERIC INDEX
        local page = math.ceil((genIndex+1) / 11)                                               -- GET CURRENT PAGE #
        local memoStartPage = page                                                              -- ASSIGN START PAGE FOR MEMO MESSAGES

        genIndex = ((memoStartPage * 10) + (memoStartPage - 1))                                 -- START DISPLAY AT BOTTOM OF CURRENT PAGE

        for i = #B747_CASmemo, 1, -1 do                                                         -- REVERSE ITERATE THE TABLE (MOST RECENT MESSAGE FIRST)

            -- FIRST PAGE IS FILLED
            if memoPageCheck == 1                                                               -- OK TO PERFORM CHECK
                and page == memoStartPage                                                       -- STILL ON START PAGE
                and genIndex == lastGenIndex                                                    -- WE ARE AT THE LAST ADVISORY MESSAGE POSITION - START PAGE IS FILLED

            -- START NEXT PAGE
            then
                page = page + 1                                                                 -- INCREMENT PAGE # TO STOP PAGE CHECK
                genIndex = page * 11                                                            -- SET THE GENERIC INDEX TO BEGINNING OF NEXT PAGE
                increment = 1                                                                   -- CHANGE DISPLAY DIRECTION TO TOP DOWM
                memoPageCheck = 0                                                               -- SET THE FLAG TO STOP PAGE CHECK
            end

            B747DR_CAS_gen_memo_msg[genIndex] = B747_CASmemo[i]                                     -- ASSIGN MEMO TO GENERIC
            set_B747DR_CAS_gen_memo_msg[genIndex] = 1
	    genIndex = genIndex + increment                                                     -- ADJUST THE GENERIC INDEX
            if math.fmod(genIndex, 10) == 0 then                                                -- END OF PAGE
                genIndex = genIndex + #B747_CASwarning                                          -- INCREMENT THE INDEX BY THE NUM OF WARNINGS DISPLAYED (FOR NEXT PAGE)
            end

        end
    end
    for x = 0, NUM_ALERT_MESSAGES do

      if set_B747DR_CAS_gen_warning_msg[x]==0 then B747DR_CAS_gen_warning_msg[x] = " " end
      if set_B747DR_CAS_gen_caution_msg[x]==0 then B747DR_CAS_gen_caution_msg[x] = " " end
      if set_B747DR_CAS_gen_advisory_msg[x]==0 then B747DR_CAS_gen_advisory_msg[x] = " " end
      if set_B747DR_CAS_gen_memo_msg[x]==0 then B747DR_CAS_gen_memo_msg[x] = " " end
    end
end








----- EICAS MESSAGES --------------------------------------------------------------------
function B747_warnings_EICAS_msg()



end







----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_warning_monitor_AI()

    if B747DR_init_warning_CD == 1 then
        B747_set_warning_all_modes()
        B747_set_warning_CD()
        B747DR_init_warning_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_warning_all_modes()

    B747DR_init_warning_CD = 0
    B747DR_CAS_msg_page = 1
    B747DR_CAS_caut_adv_display = 1

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_warning_CD()



end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_warning_ER()
	
    B747DR_sfty_no_smoke_sel_dial_pos = 1
    B747DR_sfty_seat_belts_sel_dial_pos = 1
	
end






----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_warning()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_warning_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_warning_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_warning_ER()

    end

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end
simDRTime=find_dataref("sim/time/total_running_time_sec")
local lastUpdate=0;
function flight_start() 
    lastUpdate=simDRTime
    B747_flight_start_warning()

end

--function flight_crash() end

--function before_physics() end
debug_warning     = deferred_dataref("laminar/B747/debug/warning", "number")
function after_physics()
  if debug_warning>0 then return end
    local diff=simDRTime-lastUpdate
    if simDR_bus_volts[0]<5 or simDR_esys1==6 then
      powered = false
      cleanAllWhenOff()
      lastUpdate=simDRTime
    elseif diff>2 and powered == true then
      B747_CAS_queue()
      B747_CAS_display()

      B747_warnings_EICAS_msg()

      B747_warning_monitor_AI()
      lastUpdate=simDRTime
    elseif diff>4 then
      powered = true
      lastUpdate=simDRTime
    end
end

--function after_replay() end



