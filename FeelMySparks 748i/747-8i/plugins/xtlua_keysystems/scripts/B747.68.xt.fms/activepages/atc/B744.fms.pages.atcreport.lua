fmsPages["ATCREPORT"]=createPage("ATCREPORT")
fmsPages["ATCREPORT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local ln=getFMSData("acarsMessage")
    local padding=23-string.len(ln)
    if padding<0 then padding=0 end
    --print(ln)
    local armedMessage=" "
    if string.len(ln)> 0 then
        armedMessage="<"..string.sub(ln,1,23) .. string.format("%"..padding.."s","")
        fmsFunctionsDefs["ATCREPORT"]["L5"]={"setdata","sendarmedacarsnr"}
    else
        fmsFunctionsDefs["ATCREPORT"]["L5"]=nil
    end
    local passing=" "
    if B747DR_last_waypoint~="-----" then
        passing="<REPORT PASSING "..str_trim(string.format("%5s", B747DR_last_waypoint))

    end
    return{

"       ATC INDEX        ",
"                        ",	               
"<RTE REPORT   FREE TEXT>",
"                        ",
"<CONFIRM ALTITUDE       ",
"                        ",
passing,
"                        ",
"<WHEN CAN YOU ACCEPT F..",
"                        ",
armedMessage,
"------------------------",
"<INDEX                  "
    }
end

fmsPages["ATCREPORT"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                    1/1 ",
" ATC                    ",	               
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
" ARMED                  ",
"                        ",
"                        ",
"                        "
    }
end


  
fmsFunctionsDefs["ATCREPORT"]={}
fmsFunctionsDefs["ATCREPORT"]["L1"]={"setpage","POSREPORT"}
fmsFunctionsDefs["ATCREPORT"]["L6"]={"setpage","ATCINDEX"}

--[[
fmsFunctionsDefs["ATCREPORT"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT"]["R6"]={"setpage",""}
]]

