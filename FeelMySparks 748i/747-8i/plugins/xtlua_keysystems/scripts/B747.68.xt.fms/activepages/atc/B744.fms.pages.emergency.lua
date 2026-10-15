fmsPages["ATCEMERGENCYREPORT"]=createPage("ATCEMERGENCYREPORT")
fmsPages["ATCEMERGENCYREPORT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    line1="<MAYDAY                >"
    if str_trim(getFMSData("acarsEMERMSG"))=="PAN PAN PAN" then
        line1="<                   PAN>"
    end
    return{

"   EMERGENCY REPORT     ",
"                        ",
line1,
"                        ",
"<                       ",
"                        ",
"                        ",
"                        ",
"<                       ",
"                        ",
"<ERASE EMERGENCY        ",
"------------------------",
"<INDEX           VERIFY>"
    }
end

fmsPages["ATCEMERGENCYREPORT"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local pMessage=str_trim(getFMSData("acarsEMERMSG"))
    line1="                    PAN "
    if pMessage=="PAN PAN PAN" then
        line1=" MAYDAY                 "
    end
    if getFMSData("acarsEMERSOB")~="---" then
        pMessage=pMessage.." SOB "..getFMSData("acarsEMERSOB")
    end
    if fmsModules.data["fltdst"]~="****" then
        pMessage=pMessage.." DIVERTING TO "..fmsModules.data["fltdst"]
    end
    if getFMSData("acarsEMEROFFSET")~="---" then
        pMessage=pMessage.." OFFSET "..getFMSData("acarsEMEROFFSET")
    end
    if getFMSData("acarsEMERDESC")~="-----" then
        pMessage=pMessage.." DESCENDING TO "..getFMSData("acarsEMERDESC")
    end
    pMessage=pMessage.." POSITION REPORT"
    if B747DR_last_waypoint~="-----" then
     pMessage=pMessage.." OVHD "..str_trim(string.format("%5s", B747DR_last_waypoint)).." AT "..string.sub(B747DR_waypoint_ata,1,4) .."Z"
    end
    if B747DR_ND_current_waypoint~="-----" then
     pMessage=pMessage.." TO "..str_trim(string.format("%5s",B747DR_ND_current_waypoint)).." ETA "..string.sub(B747DR_ND_waypoint_eta,1,4) .."Z"
    end
    pMessage=pMessage.." PPOS "..irsSystem.getLine("gpsL").. " FL".. string.format("%03d",round(B747DR_altimter_ft_adjusted))
    pMessage=pMessage.." SPEED ."..string.format("%02d",round(simDR_mach_pilot*100))
    setFMSData("acarsMessage",pMessage)
    return{

"                        ",
"                        ",
line1,
" DIVERT TO           SOB",
" "..fmsModules.data["fltdst"].."                "..getFMSData("acarsEMERSOB"),
"  OFFSET  FUEL REMAINING",
getFMSData("acarsEMEROFFSET").."                     ", --fuel remaining if SOB
" DESCEND TO             ",
" ".. getFMSData("acarsEMERDESC").."                  ",
"                        ",
"                        ",
"                        ",
"                        "
    }
end


  
fmsFunctionsDefs["ATCEMERGENCYREPORT"]={}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["L1"]={"setmayday","MAYDAY MAYDAY MAYDAY"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["L2"]={"setdata","fltdst"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["L3"]={"setdata","acarsEMEROFFSET"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["L4"]={"setdata","acarsEMERDESC"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["L5"]={"clearemergency",""}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["L6"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["R1"]={"setmayday","PAN PAN PAN"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["R2"]={"setdata","acarsEMERSOB"}
fmsFunctionsDefs["ATCEMERGENCYREPORT"]["R6"]={"setpage","ATCVERIFYEMERGENCY"}

fmsPages["ATCVERIFYEMERGENCY"]=createPage("ATCVERIFYEMERGENCY")
fmsPages["ATCVERIFYEMERGENCY"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo<2 then
        fmsFunctionsDefs["ATCVERIFYEMERGENCY"]["R5"]=nil
        return{

    "   VERIFY EMERGENCY     ",
    "                        ",
    getFMSData("acarsEMERMSG").."   ",
    "                        ",
    getFMSData("acarsEMERDESC").."                   ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "------------------------",
    "<EMERGENCY              "
        }
    else
        fmsFunctionsDefs["ATCVERIFYEMERGENCY"]["R5"]={"setdata","sendarmedacarsnr"}
        return{
            "   VERIFY EMERGENCY     ",
            "                        ",
            "<                       ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                   SEND>",
            "------------------------",
            "<EMERGENCY              "
                }
    end
end

fmsPages["ATCVERIFYEMERGENCY"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo<2 then
    return{

"                    "..pgNo.."/2 ",
"                        ",
"                        ",
" DESCENDING TO          ",
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
    else
    return{
        "                        ",
        "/FREE TEXT              ",
        "                        ",
        "                        ",
        "                        ",
        "                        ",
        "                        ",
        "                        ",
        "                        ",
        "                  REPORT",
        "                        ",
        "                        ",
        "                        ",
            }
end
end

fmsPages["ATCVERIFYEMERGENCY"].getNumPages=function(self)
    return 2
end

fmsFunctionsDefs["ATCVERIFYEMERGENCY"]={}
fmsFunctionsDefs["ATCVERIFYEMERGENCY"]["L6"]={"setpage","ATCEMERGENCYREPORT"}