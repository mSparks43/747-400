
--THIS SCRIPT WAS MADE BY CRAZYTIMTIMTIM, with some help from mSparks43 and Marauder28

registerFMCCommand("sim/flight_controls/door_open_1","OPEN DOOR 1")
registerFMCCommand("sim/flight_controls/door_close_1","CLOSE DOOR 1")
registerFMCCommand("sim/flight_controls/door_open_2","OPEN DOOR 2")
registerFMCCommand("sim/flight_controls/door_close_2","CLOSE DOOR 2")

simDR_doors = find_dataref("sim/cockpit2/switches/door_open")

fmsPages["DOORS"]=createPage("DOORS")
fmsPages["DOORS"].getPage=function(self,pgNo,fmsID)
  if pgNo == 1 then

    local lineA = "<OPEN                    "
    local lineB = "<OPEN                    "
    local LineC = "<OPEN                    "

    if simDR_doors[1] == 1 then
      lineA = "<CLOSE                   "
      fmsFunctionsDefs["DOORS"]["L1"]={"doCMD","sim/flight_controls/door_close_2"}
    else
      lineA = "<OPEN                    "
      fmsFunctionsDefs["DOORS"]["L1"]={"doCMD","sim/flight_controls/door_open_2"}
    end

    if simDR_doors[0] == 1 then
      lineB = "<CLOSE                   "
      fmsFunctionsDefs["DOORS"]["L2"]={"doCMD","sim/flight_controls/door_close_1"}
      else
      lineB = "<OPEN                    "
      fmsFunctionsDefs["DOORS"]["L2"]={"doCMD","sim/flight_controls/door_open_1"}
    end
    
     if simDR_doors[0] == 1 then
      lineC = "<CLOSE                   "
      fmsFunctionsDefs["DOORS"]["L2"]={"doCMD","sim/flight_controls/door_close_3"}
      else
      lineC = "<OPEN                    "
      fmsFunctionsDefs["DOORS"]["L2"]={"doCMD","sim/flight_controls/door_open_3"}
    end

    return {
      "     DOOR CONTROL       ",
      "                        ",
      lineA,
      "                        ",
      lineB,
      "                        ",
      LineC,
      "                        ",
      "                        ",
      "INOP                    ",
      "                        ",
      "INOP                    ",
      "------------------------",
      "<INDEX       GND HANDLE>"
    }

  elseif pgNo == 2 then
    
    fmsFunctionsDefs["DOORS"]["L1"]=nil
    fmsFunctionsDefs["DOORS"]["L2"]=nil
    
    return {
      "     Door Control       ",
      "                        ",
      "INOP                    ",
      "                        ",
      "INOP                    ",
      "                        ",
      "INOP                    ",
      "                        ",
      "INOP                    ",
      "                        ",
      "INOP                    ",
      "------------------------",
      "<INDEX       GND HANDLE>"
    }

  elseif pgNo == 3 then

    fmsFunctionsDefs["DOORS"]["L1"]=nil
    fmsFunctionsDefs["DOORS"]["L2"]=nil
    
    return {
      "     Door Control       ",
      "                        ",
      "INOP                    ",
      "                        ",
      "INOP                    ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "------------------------",
      "<INDEX       GND HANDLE>"
    }
    
  end
end

fmsPages["DOORS"].getSmallPage=function(self,pgNo,fmsID)

  if pgNo == 1 then

    local lineC = "                        "
    local lineD = "                        "

    if simDR_doors[1] == 1 then
      lineC = "                 (OPENED)"
    else
      lineC = "                 (CLOSED)"
    end

    if simDR_doors[0] == 1 then
      lineD = "                 (OPENED)"
    else
      lineD = "                 (CLOSED)"
    end

    return{
      "                     1/3",
      "FWD L                   ",
      lineC,
      "Upper L                 ",
      lineD,
      "FWD R                   ",
      "                        ",
      "UPPER R                 ",
      "                        ",
      "FWD WING L              ",
      "                        ",
      "                        ",
      "                        "
    }

  elseif pgNo == 2 then

    return{
      "                     2/3",
      "FWD WING R              ",
      "                        ",
      "WING L                  ",
      "                        ",
      "WING R                  ",
      "                        ",
      "AFT WING L              ",
      "                        ",
      "AFT WING R              ",
      "                        ",
      "                        ",
      "                        "
    }

  elseif pgNo == 3 then
    return{

      "                     3/3",
      "AFT L                   ",
      "                        ",
      "AFT R                   ",
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
end

fmsFunctionsDefs["DOORS"]["L6"]={"setpage","INDEX"}
fmsFunctionsDefs["DOORS"]["R6"]={"setpage","GNDHNDL"}

fmsPages["DOORS"].getNumPages=function(self)
  return 3
end
