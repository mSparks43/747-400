
-- NOTE:  THESE TABLES ARE ONE (1) BASED FOR INDEXING

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
    {DRindex = 14, name = "IRS ALIGN MODE C", status = 0},
    {DRindex = 15, name = "IRS ALIGN MODE L", status = 0},
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
}






dofile("B747.87.warning02.lua")