

fmsPages["CMC"]=createPage("CMC")
fmsPages["CMC"].getPage=function(self,pgNo,fmsID)

  if pgNo==1 then 
      fmsFunctionsDefs["CMC"]["L1"]={"setpage","PLFAULTS"}
      fmsFunctionsDefs["CMC"]["L2"]={"setpage","CONFTEST"}
      fmsFunctionsDefs["CMC"]["L3"]={"setpage","EMANP"}
      fmsFunctionsDefs["CMC"]["L4"]={"setpage","GRDTEST"}
    return {
            
"     CMC-L MENU      1/2",
"                        ",
"<PRESENT LEG FAULTS     ",
"                        ",
"<CONFIDENCE TESTS       ",
"                        ",
"<EICAS MAINT PAGES      ",
"                        ",
"<GROUND TESTS           ",
"                        ",
"                        ", 
"------------------------",
"                   HELP>"
    }
  elseif pgNo==2 then
      --fmsFunctionsDefs["CMC"]["L1"]={"setpage","FAULTS"}
      --fmsFunctionsDefs["CMC"]["L2"]={"setpage","FHISTORY"}
      --fmsFunctionsDefs["CMC"]["L3"]={"setpage","OFUCNTION"}
    return {
            
"     CMC-L MENU      2/2",
"                        ",
"<EXISTING FAULTS        ",
"                        ",
"<FAULT HISTORY          ",
"                        ",
"<OTHER FUNCTIONS        ",
"                        ",
"------------------------",
"                        ",
"                  NOTES>", 
"                        ",
"                   HELP>"
    }
end
end
fmsPages["CMC"].getNumPages=function(self)
  return 2
end


fmsPages["PLFAULTS"]=createPage("PLFAULTS")
fmsPages["PLFAULTS"].getPage=function(self,pgNo,fmsID)
  if pgNo==1 then

    return {
              
      "    THROTTLE TESTS   1/2",
      " ../B747/engine/throttle",
      string.format("%02.2f", B747DR_throttle[0]).."  "..string.format("%02.2f", B747DR_throttle[1]).."  "..string.format("%02.2f", B747DR_throttle[2]).."  "..string.format("%02.2f", B747DR_throttle[3]).."  ",
      "    ../throttle_reversor",
      string.format("%02.2f", B747DR_throttle_reversor[0]).."  "..string.format("%02.2f", B747DR_throttle_reversor[1]).."  "..string.format("%02.2f", B747DR_throttle_reversor[2]).."  "..string.format("%02.2f", B747DR_throttle_reversor[3]).."  ",
      "   ../throttle_ratio_all",
      string.format("%02.2f", simDR_throttle_ratio_all).."                        ",
      "actuators/throttle_ratio",
      string.format("%02.2f", simDR_throttle_ratio[0]).."  "..string.format("%02.2f", simDR_throttle_ratio[1]).."  "..string.format("%02.2f", simDR_throttle_ratio[2]).."  "..string.format("%02.2f", simDR_throttle_ratio[3]).."  ",
      "          ../engines/TRA",
      string.format("%02.2f", B747DR_throttle_resolver_angle[0]).."  "..string.format("%02.2f", B747DR_throttle_resolver_angle[1]).."  "..string.format("%02.2f", B747DR_throttle_resolver_angle[2]).."  "..string.format("%02.2f", B747DR_throttle_resolver_angle[3]).."  ", 
      "------------------------",
      "<RETURN                 "
    }
  elseif pgNo==2 then 
    return {
              
      "    THROTTLE TESTS   2/3",
      "     ../engine/ENGN_thro",
      string.format("%02.2f", simDR_engn_thro[0]).."  "..string.format("%02.2f", simDR_engn_thro[1]).."  "..string.format("%02.2f", simDR_engn_thro[2]).."  "..string.format("%02.2f", simDR_engn_thro[3]).."  ",
      " ../engine/ENGN_thro_use",
      string.format("%02.2f", simDR_engn_thro_use[0]).."  "..string.format("%02.2f", simDR_engn_thro_use[1]).."  "..string.format("%02.2f", simDR_engn_thro_use[2]).."  "..string.format("%02.2f", simDR_engn_thro_use[3]).."  ",
      "/engine/acf_throtmax_FWD",
      string.format("%02.2f", simDR_throttle_max).."                        ",
      "                        ",
      "                        ",
      "                        ",
      "                        ",
      "------------------------",
      "<RETURN                 "
    } 
  elseif pgNo==3 then  
    local numStalled=0
    for i=0,320 do
      if simDR_stalled_elements[i]>0 then
        numStalled=numStalled+1
      end
    end
      return {
              
  "      STALL TESTS    3/3",
  "                        ",
  "STALLED ELEMENTS        ",
  "                        ",
  "    "..numStalled,
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ", 
  "------------------------",
  "<RETURN                 "
      }
  end
end
fmsPages["PLFAULTS"].getNumPages=function(self)
  return 3
end

fmsFunctionsDefs["PLFAULTS"]["L6"]={"setpage","CMC"}
fmsPages["CONFTEST"]=createPage("CONFTEST")
fmsPages["CONFTEST"].getPage=function(self,pgNo,fmsID) 
    return {
            
"  CONFIDENCE TESTS   1/1",
"                        ",
"<STALL LEFT             ",
"                        ",
"<STALL RIGHT            ",
"                        ",
"<T/O CONFIG WARNING     ",
"                        ",
"<GPWC                   ",
"                        ",
"                        ", 
"------------------------",
"<RETURN            HELP>"
    }
  
end

fmsFunctionsDefs["CONFTEST"]["L6"]={"setpage","CMC"}
fmsPages["EMANP"]=createPage("EMANP")
fmsPages["EMANP"].getPage=function(self,pgNo,fmsID)
  
  if pgNo==1 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTCMC"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTAPU"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTENGFUEL"}
      fmsFunctionsDefs["EMANP"]["L6"]={"setpage","CMC"}
    return {
      
" EICAS MAINT PAGES   1/3",
"                        ",
"<21 ECS                 ",
"                        ",
"<24 ELECTRICAL          ",
"                        ",
"<27 FLT CONT            ",
"                        ",
"<28 FUEL                ",
"                        ",
"<29 HYDRAULIC           ",
"------------------------",
"<RETURN            HELP>"
    }
  elseif pgNo==2 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTCMC"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTAPU"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTENGFUEL"}
      fmsFunctionsDefs["EMANP"]["L6"]={"setpage","CMC"}
    return {
      
" EICAS MAINT PAGES   2/3",
"                        ",
"<31 CONFIGURATIONS      ",
"                        ",
"<31 GEAR                ",
"                        ",
"<49 APU                 ",
"                        ",
"<73 EPCS                ",
"                        ",
"<74 PERFORMANCE         ",
"------------------------",
"<RETURN            HELP>"
    }
  elseif pgNo==3 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTCMC"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTAPU"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTENGFUEL"}
      fmsFunctionsDefs["EMANP"]["L6"]={"setpage","CMC"}
    return {
      
" EICAS MAINT PAGES   3/3",
"                        ",
"<73 ENG EXCD            ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"------------------------",
"<RETURN            HELP>"
    }  
  end
end

fmsPages["EMANP"].getNumPages=function(self)
  return 3
end

fmsPages["GRDTEST"]=createPage("GRDTEST")
fmsPages["GRDTEST"].getPage=function(self,pgNo,fmsID)

  if pgNo==1 then 
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTAC"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTCABPSI"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTECS"}
      --fmsFunctionsDefs["GRDTEST"]["L4"]={"setpage","GTAPFD"}
      --fmsFunctionsDefs["GRDTEST"]["L5"]={"setpage","GTYAW"}
      fmsFunctionsDefs["GRDTEST"]["L6"]={"setpage","CMC"}
    return {
            
"    GROUND TESTS     1/6",
"                        ",
"<21 AIR CONDITIONING    ",
"                        ",
"<21 CABIN PRESURE       ",
"                        ",
"<21 EQUIPMENT COOLING   ",
"                        ",
"<22 AUTOPILOT FLT DIR   ",
"                        ",
"<22 YAW DAMPER          ", 
"------------------------",
"<RETURN            HELP>"
    }
    
  elseif pgNo==2 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTCOMM"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTELEC"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTFIRE"}
      --fmsFunctionsDefs["GRDTEST"]["L4"]={"setpage","GTAIL"}
      --fmsFunctionsDefs["GRDTEST"]["L5"]={"setpage","GTRUDR"}
      fmsFunctionsDefs["GRDTEST"]["L6"]={"setpage","CMC"}
    return {
      
"    GROUND TESTS     2/6",
"                        ",
"<23 COMMUNICATIONS      ",
"                        ",
"<24 ELECTRICAL POWER    ",
"                        ",
"<26 FIRE PROTECTION     ",
"                        ",
"<27 AILERON LOCKOUT     ",
"                        ",
"<27 RUDDER RATIO        ", 
"------------------------",
"<RETURN            HELP>"
    }
    
  elseif pgNo==3 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTFLAP"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTSTALL"}
     --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTFUEL"}
      --fmsFunctionsDefs["GRDTEST"]["L4"]={"setpage","GTHYD"}
      --fmsFunctionsDefs["GRDTEST"]["L5"]={"setpage","GTICE"}
      fmsFunctionsDefs["GRDTEST"]["L6"]={"setpage","CMC"}
    return {
      
"    GROUND TESTS     3/6",
"                        ",
"<27 FLAP CONTROL        ",
"                        ",
"<27 STALL WARNING       ",
"                        ",
"<28 FUEL                ",
"                        ",
"<29 HYDRAULIC POWER     ",
"                        ",
"<30 ICE AND RAIN        ", 
"------------------------",
"<RETURN            HELP>"
    }
    
  elseif pgNo==4 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTWARN"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTREC"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTBRAKE"}
      --fmsFunctionsDefs["GRDTEST"]["L4"]={"setpage","GTPSEU"}
      --fmsFunctionsDefs["GRDTEST"]["L5"]={"setpage","GTBRKTEMP"}
      fmsFunctionsDefs["GRDTEST"]["L6"]={"setpage","CMC"}
    return {
      
"    GROUND TESTS     4/6",
"                        ",
"<31 INDICATING/WARNING  ",
"                        ",
"<31 RECORDING           ",
"                        ",
"<32 BRAKE CONTROL       ",
"                        ",
"<32 PSEU SYSTEM         ",
"                        ",
"<32 BRAKE TEMPERATURE   ", 
"------------------------",
"<RETURN            HELP>"
    }
    
elseif pgNo==5 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTAIRDAT"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTIR"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTNAVRAD"}
      --fmsFunctionsDefs["GRDTEST"]["L4"]={"setpage","GTFM"}
      --fmsFunctionsDefs["GRDTEST"]["L5"]={"setpage","GTPNEU"}
      fmsFunctionsDefs["GRDTEST"]["L6"]={"setpage","CMC"}
    return {
      
"    GROUND TESTS     5/6",
"                        ",
"<34 AIR DATA            ",
"                        ",
"<34 INERTIAL REFERENCE  ",
"                        ",
"<34 NAVIGATION RADIOS   ",
"                        ",
"<34 FLIGHT MANAGEMENT   ",
"                        ",
"<36 PNEUMATICS          ", 
"------------------------",
"<RETURN            HELP>"
    }
    
elseif pgNo==6 then
      --fmsFunctionsDefs["GRDTEST"]["L1"]={"setpage","GTCMC"}
      --fmsFunctionsDefs["GRDTEST"]["L2"]={"setpage","GTAPU"}
      --fmsFunctionsDefs["GRDTEST"]["L3"]={"setpage","GTENGFUEL"}
      fmsFunctionsDefs["GRDTEST"]["L6"]={"setpage","CMC"}
    return {
      
"    GROUND TESTS     6/6",
"                        ",
"<45 CENTRAL MAINTENANCE ",
"                        ",
"<49 APU                 ",
"                        ",
"<73 ENGINE FUEL CONTROL ",
"                        ",
"                        ",
"                        ",
"                        ",
"------------------------",
"<RETURN            HELP>"
    }
  
  end
end

fmsPages["GRDTEST"].getNumPages=function(self)
  return 6
end
