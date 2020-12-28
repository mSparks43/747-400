fmsPages["CMC"]=createPage("CMC")
fmsPages["CMC"].getPage=function(self,pgNo,fmsID)

  if pgNo==1 then 
      fmsFunctionsDefs["CMC"]["L1"]={"setpage","PLFAULTS"}
      fmsFunctionsDefs["CMC"]["L2"]={"setpage","CONFTEST"}
      --fmsFunctionsDefs["CMC"]["L3"]={"setpage","EMANP"}
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
  local numStalled=0
  for i=0,320 do
    if simDR_stalled_elements[i]>0 then
      numStalled=numStalled+1
    end
  end
    return {
            
"      STALL TESTS    1/1",
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
simDR_stalled_elements= find_dataref("sim/flightmodel2/wing/elements/element_is_stalled")

fmsPages["PLFAULTS"]=createPage("PLFAULTS")
fmsPages["PLFAULTS"].getPage=function(self,pgNo,fmsID) 
  local numStalled=0
  for i=0,320 do
    if simDR_stalled_elements[i]>0 then
      numStalled=numStalled+1
    end
  end
    return {
            
"      STALL TESTS    1/1",
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
fmsFunctionsDefs["PLFAULTS"]["L6"]={"setpage","CMC"}

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
end
end

fmsPages["GRDTEST"].getNumPages=function(self)
  return 4
end

--page is WIP
