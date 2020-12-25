fmsPages["POSINIT"]=createPage("POSINIT")

fmsPages["POSINIT"].getPage=function(self,pgNo,fmsID)
  if pgNo==1 then

	--Marauder28
	--Load last aircraft position (for this livery)
	aircraft_las_pos("LOAD")

    fmsFunctionsDefs["POSINIT"]["R1"]={"getdata","lastpos"}
    
    fmsFunctionsDefs["POSINIT"]["R4"]={"getdata","gpspos"}
    if irsSystem["setPos"]==false or irsSystem["irsL"]["aligned"]==false or irsSystem["irsC"]["aligned"]==false or irsSystem["irsR"]["aligned"]==false then 
      fmsFunctionsDefs["POSINIT"]["R5"]={"setdata","irspos"}
      fmsFunctionsDefs["POSINIT"]["L2"]={"setdata","airportpos"}
      fmsFunctionsDefs["POSINIT"]["L3"]={"setdata","airportgate"}
    else
      fmsFunctionsDefs["POSINIT"]["L2"]=nil
      fmsFunctionsDefs["POSINIT"]["L3"]=nil
      fmsFunctionsDefs["POSINIT"]["R5"]=nil
    end
	if fmsModules["data"].sethdg == "---`" then
		fmsFunctionsDefs["POSINIT"]["L5"]={"setdata","sethdg"}
	else
		fmsFunctionsDefs["POSINIT"]["L5"]=nil
	end
    fmsFunctionsDefs["POSINIT"]["R6"]={"setpage","RTE1"}
    return {
    "      POS INIT        1/3 ",
    "                         ",
    "      "..fmsModules["data"].lastpos,
    "                         ",
    fmsModules["data"]["airportpos"].."  "..fmsModules["data"].irsLat.." "..fmsModules["data"].irsLon,
    "                         ",
    fmsModules["data"]["airportgate"].."                   ",
    "                         ",
    string.format("%02d%02dz ",hh,mm).. irsSystem.getLat("gpsL") .." " .. irsSystem.getLon("gpsL"),
    "                         ",
    fmsModules["data"].sethdg.."  ".. irsSystem.getInitLatPos().." ".. irsSystem.getInitLonPos(), 
    "                         ",
    "<INDEX             ROUTE>"
    } 
  elseif pgNo==2 then 
    fmsFunctionsDefs["POSINIT"]["L2"]=nil
    fmsFunctionsDefs["POSINIT"]["L3"]=nil
    fmsFunctionsDefs["POSINIT"]["R1"]=nil
    fmsFunctionsDefs["POSINIT"]["R4"]=nil
    fmsFunctionsDefs["POSINIT"]["R5"]=nil
    fmsFunctionsDefs["POSINIT"]["R6"]=nil
    local rnav_type="NAV STA"
    local rnav_id="**** ****"
    local rnav_accuracy="2.00/**.** "
    if simDR_radio_nav_horizontal[2]==1 and simDR_radio_nav_horizontal[3]==1 and simDR_radio_nav_hasDME[2]==1 and simDR_radio_nav_hasDME[3]==1 then 
      rnav_type="DME-DME"
      rnav_id=string.format("%4s %4s",simDR_radio_nav03_ID,simDR_radio_nav04_ID)
      rnav_accuracy="2.00/0.05"
    elseif (simDR_radio_nav_horizontal[2]==1 and simDR_radio_nav_hasDME[2]==1) then
      rnav_type="VOR-DME"
      rnav_id=string.format("%4s %4s",simDR_radio_nav03_ID,simDR_radio_nav03_ID)
      rnav_accuracy="2.00/0.15  "
    elseif (simDR_radio_nav_horizontal[3]==1 and simDR_radio_nav_hasDME[3]==1)  then
      rnav_type="VOR-DME"
      rnav_accuracy="2.00/0.15"
      rnav_id=string.format("%4s %4s",simDR_radio_nav04_ID,simDR_radio_nav04_ID)
    end
    if simDR_radio_nav_horizontal[3]==1 then vorR_radial=string.format("%03d",simDR_radio_nav_radial[3]) end
    return {
    "       POS REF     2/3  ",
    "                        ",
    irsSystem.getLine("gpsL"),
    "                        ",
    irsSystem.calcLatA().." ".. irsSystem.calcLonA() .."      ",
    "                 "..rnav_type,
    rnav_accuracy.."NM    "..rnav_id,
    "                        ",
    "                        ",
    "                        ",
    "<PURGE          INHIBIT>", 
    "                        ",
    "<INDEX         BRG/DIST>"
    } 
  elseif pgNo==3 then
    fmsFunctionsDefs["POSINIT"]["L2"]=nil
    fmsFunctionsDefs["POSINIT"]["L3"]=nil
     fmsFunctionsDefs["POSINIT"]["R1"]=nil
    fmsFunctionsDefs["POSINIT"]["R4"]=nil
    fmsFunctionsDefs["POSINIT"]["R5"]=nil
    fmsFunctionsDefs["POSINIT"]["R6"]=nil
    return {
    "       POS REF     3/3  ",
    "                        ",
    irsSystem.getLine("irsL"),
    "                        ",
    irsSystem.getLine("irsC"),
    "                        ",
    irsSystem.getLine("irsR"),
    "                        ",
    irsSystem.getLine("gpsL"),
    "                        ",
    irsSystem.getLine("gpsR"), 
    "                        ",
    "<INDEX         BRG/DIST>"
    } 
  end
end
fmsPages["POSINIT"].getSmallPage=function(self,pgNo,fmsID)
  if pgNo==1 then
    local setIRS="                        "
    if B747DR_iru_status[0]==4 or B747DR_iru_status[1]==4 or B747DR_iru_status[2]==4 or irsSystem["setPos"]==false then
      setIRS="SET HDG       SET IRS POS"
    end
    return {
    "                         ",
    "                 LAST POS",
    "                         ",
    "REF AIRPORT              ",
    "                         ",
    "GATE                     ",
    "                         ",
    "UTC (GPS)         GPS POS",
    "                         ",
    setIRS,
    "                         ", 
    "-------------------------",
    "                         "
    } 
  elseif pgNo==2 then 
    return {
    "                        ",
    " FMS POS (GPS L)      GS",
    "                        ",
    "IRS (3)                 ",
    "                        ",
    "RNP/ACTUAL              ",
    "                        ",
    "                        ",
    "                        ",
    "-----------------GPS NAV",
    "                        ", 
    "                        ",
    "                        "
    }
  elseif pgNo==3 then 
    return {
    "                        ",
    " IRS L                GS",
    "                        ",
    " IRS C                  ",
    "                        ",
    " IRS R                  ",
    "                        ",
    " GPS L                  ",
    "                        ",
    " GPS R                  ",
    "                        ", 
    "------------------------",
    "                        "
    }
  end
end
fmsPages["POSINIT"].getNumPages=function(self)
  return 3 
end
fmsFunctionsDefs["POSINIT"]={}
fmsFunctionsDefs["POSINIT"]["L6"]={"setpage","INITREF"}

