fmsPages["POSREPORT"]=createPage("POSREPORT")
fmsPages["POSREPORT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
   local grfuelV=simDR_fuel/1000
   if simConfigData["data"].SIM.weight_display_units == "LBS" then
     grfuelV=grfuelV * simConfigData["data"].SIM.kgs_to_lbs
   end
   local grfuel=string.format("%05.1f",grfuelV)
   local air_temp=string.format("%02d",simDR_air_temp)
   air_temp=string.format("%s%"..(3-(string.len(air_temp))).."s",air_temp,"")
   local pMessage="POSITION REPORT"
   if B747DR_last_waypoint~="-----" then
    pMessage=pMessage.." OVHD "..str_trim(string.format("%5s", B747DR_last_waypoint)).." AT "..string.sub(B747DR_waypoint_ata,1,4) .."Z"
   end
   if B747DR_ND_current_waypoint~="-----" then
    pMessage=pMessage.." TO "..str_trim(string.format("%5s",B747DR_ND_current_waypoint)).." ETA "..string.sub(B747DR_ND_waypoint_eta,1,4) .."Z"
   end
   pMessage=pMessage.." PPOS "..irsSystem.getLine("gpsL").. " FL".. string.format("%03d",round(B747DR_altimter_ft_adjusted))
   pMessage=pMessage.." SPEED ."..string.format("%02d",round(simDR_mach_pilot*100))
   --print(pMessage)
   setFMSData("acarsMessage",pMessage)
   return{
        "       POS REPORT        ",
        "                         ",	               
        string.format("%5s", B747DR_last_waypoint).."               "..string.sub(B747DR_waypoint_ata,1,4) .."Z",
        "                         ",
        "FL".. string.format("%03d",round(B747DR_altimter_ft_adjusted)) .."                 .".. string.format("%02d",round(simDR_mach_pilot*100)),
        "                         ",
        string.format("%5s",B747DR_ND_current_waypoint).."               ".. string.sub(B747DR_ND_waypoint_eta,1,4) .."Z" ,
        "                         ",
        string.format("%5s", B747DR_next_waypoint).."               ".. string.sub(B747DR_next_waypoint_eta,1,4) .."Z" ,
        "                         ",
        air_temp .."     ".. string.format("%s%"..(8-(string.len(B747DR_ND_Wind_Line))).."s",string.sub(B747DR_ND_Wind_Line.."KT",1,10),"") .."  "..grfuel,
        "                         ",
        "                    SEND>"
        --"<SEND               SEND>"
    }
end


fmsPages["POSREPORT"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                         ",
" LAST                 ATA",	               
"                         ",
" ALT                  SPD",
"                         ",
" TO                   ETA",
"                         ",
" NEXT             EST ETA",
"                         ",
" TEMP     WIND       FUEL",
"   `C                   ",
--" COMPANY ------------ ATC",
"         ------------ ATC",
"                         " 
    }
end


  
fmsFunctionsDefs["POSREPORT"]={}
fmsFunctionsDefs["POSREPORT"]["R6"]={"setpage","ATCREPORT"}
--[[
fmsFunctionsDefs["POSREPORT"]["L1"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L2"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L3"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L5"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["L6"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R1"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R2"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R3"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R5"]={"setpage",""}
fmsFunctionsDefs["POSREPORT"]["R6"]={"setpage",""}
]]

