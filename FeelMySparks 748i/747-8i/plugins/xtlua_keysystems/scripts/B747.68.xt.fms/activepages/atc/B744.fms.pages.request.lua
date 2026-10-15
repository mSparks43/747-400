fmsPages["ATCREQUEST"]=createPage("ATCREQUEST")
fmsPages["ATCREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local reqAlt=getFMSData("acarsREQALT")
    if string.len(fmsModules[fmsID]["scratchpad"])>0 then
        fmsFunctionsDefs["ATCREQUEST"]["L1"]={"setdata","acarsREQALT"}
    else
        fmsFunctionsDefs["ATCREQUEST"]["L1"]={"setpage","ATCSUBREQUEST_1"}
    end
    local reqSpd=getFMSData("acarsREQSPEED")
    if string.len(fmsModules[fmsID]["scratchpad"])>0 then
        fmsFunctionsDefs["ATCREQUEST"]["L2"]={"setdata","acarsREQSPEED"}
    else
        fmsFunctionsDefs["ATCREQUEST"]["L2"]={"setpage","ATCSUBREQUEST_2"}
    end
    local reqoffset=getFMSData("acarsREQOFFSET")
    if string.len(fmsModules[fmsID]["scratchpad"])>0 then
        fmsFunctionsDefs["ATCREQUEST"]["L3"]={"setdata","acarsREQOFFSET"}
    else
        fmsFunctionsDefs["ATCREQUEST"]["L3"]={"setpage","ATCSUBREQUEST_3"}
    end
    return{

    "       ATC REQUEST      ",
    "                        ",
    "<"..reqAlt .."                  ",
    "                        ",
    "<."..reqSpd.."                    ",
    "                        ",
    "<"..reqoffset.."                    ",
    "                        ",
    "<ROUTE REQUEST          ",
    "                        ",
    "<ERASE REQUEST          ",
    "------------------------",
    "<INDEX           VERIFY>"
        }
end

fmsPages["ATCREQUEST"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                        ",      
" ALTITUDE               ",
"                        ",	               
" SPEED                  ",
"                        ",
" OFFSET                 ",
"    NM                  ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        "
    }
end


  
fmsFunctionsDefs["ATCREQUEST"]={}
fmsFunctionsDefs["ATCREQUEST"]["L4"]={"setpage","ATCSUBREQUEST_4"}
fmsFunctionsDefs["ATCREQUEST"]["L6"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["ATCREQUEST"]["L5"]={"clearreq",""}
fmsFunctionsDefs["ATCREQUEST"]["R6"]={"setpage","ATCVERIFYREQUEST"}

fmsPages["ATCSUBREQUEST"]=createPage("ATCSUBREQUEST")
fmsPages["ATCSUBREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then
        local reqAlt=getFMSData("acarsREQALT")
        fmsFunctionsDefs["ATCSUBREQUEST"]["L1"]={"setdata","acarsREQALT"}
        fmsFunctionsDefs["ATCSUBREQUEST"]["L2"]=nil
        fmsFunctionsDefs["ATCSUBREQUEST"]["R1"]=nil
        fmsFunctionsDefs["ATCSUBREQUEST"]["R2"]=nil
    return{

"     ATC ALT REQUEST    ",
"                        ",
"<"..reqAlt .."                  ",
"                        ",
" -----                  ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"------------------------",
"<REQUEST         VERIFY>"
    }
    elseif pgNo==2 then
        local reqSpd=getFMSData("acarsREQSPEED")
        fmsFunctionsDefs["ATCSUBREQUEST"]["L1"]={"setdata","acarsREQSPEED"}
        fmsFunctionsDefs["ATCSUBREQUEST"]["L2"]=nil
        fmsFunctionsDefs["ATCSUBREQUEST"]["R1"]=nil
        fmsFunctionsDefs["ATCSUBREQUEST"]["R2"]=nil
        return{

            "   ATC SPEED REQUEST    ",
            "                        ",
            "."..reqSpd .."                  ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "------------------------",
            "<REQUEST         VERIFY>"
                }
    elseif pgNo==3 then
        local reqoffset=getFMSData("acarsREQOFFSET")
        local reqat=getFMSData("acarsREQAT")
        fmsFunctionsDefs["ATCSUBREQUEST"]["L1"]={"setdata","acarsREQOFFSET"}
        fmsFunctionsDefs["ATCSUBREQUEST"]["L2"]={"setdata","acarsREQAT"}
        fmsFunctionsDefs["ATCSUBREQUEST"]["R1"]=nil
        fmsFunctionsDefs["ATCSUBREQUEST"]["R2"]=nil
        return{

            "   ATC OFFSET REQUEST   ",
            "                        ",
            ""..reqoffset .."                   ",
            "                        ",
            ""..reqat .."                   ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "------------------------",
            "<REQUEST         VERIFY>"
                }
    elseif pgNo==4 then
        local reqto=getFMSData("acarsREQTO")
        local reqheading=getFMSData("acarsREQHDG")
        local reqtrack=getFMSData("acarsREQTRK")
        fmsFunctionsDefs["ATCSUBREQUEST"]["L1"]={"setdata","acarsREQTO"}
        fmsFunctionsDefs["ATCSUBREQUEST"]["L2"]=nil
        fmsFunctionsDefs["ATCSUBREQUEST"]["R1"]={"setdata","acarsREQHDG"}
        fmsFunctionsDefs["ATCSUBREQUEST"]["R2"]={"setdata","acarsREQTRK"}
        return{

            "   ATC ROUTE REQUEST    ",
            "                        ",
            ""..reqto .."                "..reqheading,
            "                        ",
            "                     "..reqtrack,
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "------------------------",
            "<REQUEST         VERIFY>"
                }
    end
end

fmsPages["ATCSUBREQUEST"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then
    return{
"                     1/4",
" ALTITUDE        REQUEST",
"                CRZ CLB>",
" STEP AT    MAINTAIN OWN",
"         SEPARATION/VMC>",
"                  DUE TO",
"            PERFORMANCE>",
"                  DUE TO",
"<AT PILOT DISC   WEATHER",
"                        ",
"                        ",
"                        ",
"                        "
    }
    elseif pgNo==2 then
        return{
            "                     2/4",
            " SPEED                  ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                  DUE TO",
            "            PERFORMANCE>",
            "                  DUE TO",
            "                WEATHER>",
            "                        ",
            "                        ",
            "                        "
            }
    elseif pgNo==3 then
        return{
            "                     3/4",
            " OFFSET                 ",
            "                        ",
            " OFFSET AT              ",
            "                        ",
            "                        ",
            "                        ",
            "                        ",
            "                  DUE TO",
            "                WEATHER>",
            "                        ",
            "                        ",
            "                        "
            }
    elseif pgNo==4 then
            return{
            "                     4/4",
            " DIRECT TO       HEADING",
            "                        ",
            "            GROUND TRACK",
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


  
fmsFunctionsDefs["ATCSUBREQUEST"]={}
fmsFunctionsDefs["ATCSUBREQUEST"]["L6"]={"setpage","ATCREQUEST"}
fmsFunctionsDefs["ATCSUBREQUEST"]["R6"]={"setpage","ATCVERIFYREQUEST"}

fmsPages["ATCSUBREQUEST"].getNumPages=function(self)
    return 4
end

fmsPages["ATCVERIFYREQUEST"]=createPage("ATCVERIFYREQUEST")
local reqData={}
fmsPages["ATCVERIFYREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    reqData={}
    local i=1
    local reqAt=getFMSData("acarsREQAT") 
    local msg="REQUEST"
    local msgTail=""
    if reqAt~="-----" then
        reqData[i]={" AT                     ",reqAt.."                   "}
        i=i+1
        msgTail=" AT "..reqAt
    end
    local reqOffset=getFMSData("acarsREQOFFSET")
    if reqOffset~="---" then
        reqData[i]={" REQUEST OFFSET         ",reqOffset.."NM                   "}
        i=i+1
        msg="REQUEST OFFSET "..reqOffset.."NM"
    end
    local reqAlt=getFMSData("acarsREQALT")
    if reqAlt~="-----" then
        reqData[i]={" REQUEST ALTITUDE       ",reqAlt.."                   "}
        i=i+1
        local tAlt=validAlt(reqAlt)
        if tAlt~=nil then
            tAlt=tonumber(tAlt)
            print(tAlt .." <> "..B747DR_altimter_ft_adjusted)
            if tAlt>B747DR_altimter_ft_adjusted*100 then
                msg=str_trim(msg.." CLB TO "..reqAlt)
            else
                msg=str_trim(msg.." DES TO "..reqAlt)
            end
        end
    end
    local reqSPD=getFMSData("acarsREQSPEED")
    if reqSPD~="--" then
        reqData[i]={" REQUEST SPEED       ","."..reqSPD.."                     "}
        i=i+1
        msg=str_trim(msg.." SPEED M."..reqSPD)
    end
    
    local reqHdg=getFMSData("acarsREQHDG")
    if reqHdg~="---" then
        reqData[i]={" REQUEST HEADING     ","."..reqHdg.."                     "}
        i=i+1
        msg=str_trim(msg.." HDG "..reqHdg)
    end
    local reqTrk=getFMSData("acarsREQTRK")
    if reqTrk~="---" then
        reqData[i]={" REQUEST TRACK       ","."..reqTrk.."                     "}
        i=i+1
        msg=str_trim(msg.." TRK "..reqTrk)
    end
    
    local reqTo=getFMSData("acarsREQTO")
    if reqTo~="-----" then
        reqData[i]={" DIRECT TO           ",reqTo.."                   "}
        i=i+1
        msg=str_trim(msg.." DIRECT TO "..reqTo)
    end
    local reqDue=getFMSData("acarsREQDUE")
    if reqDue~="----------------" then
        reqData[i]={" DUE TO              ",reqDue.."                   "}
        i=i+1
        msg=str_trim(msg.." DUE TO "..reqDue)
    end
    reqData[i]={"/FREE TEXT              ","<                       "}
    numPages=math.ceil(table.getn(reqData)/4)
    local start=(pgNo-1)*4
    lines={}
    for i=1,4 do
        local lID=start+i
        if lID<=table.getn(reqData) then
            lines[i] =reqData[lID][2]
        else
            lines[i] ="                        "
        end
        --print(lines[i])
    end
    --print("     VERIFY REQUEST     "..numPages)
    --print(msg)
    setFMSData("acarsMessage",msg)
    if numPages<1 then numPages=1 end
    if pgNo<numPages then
        fmsFunctionsDefs["ATCVERIFYREQUEST"]["L5"]=nil
        return{
            "     VERIFY REQUEST     ",
            "                        ",
            lines[1],
            "                        ",
            lines[2],
            "                        ",
            lines[3],
            "                        ",
            lines[4],
            "                        ",
            "                        ",
            "                        ",
            "<REQUEST                "
            }
      else
        fmsFunctionsDefs["ATCVERIFYREQUEST"]["R5"]={"setdata","sendarmedacarsrr"}
            return{
      
      "     VERIFY REQUEST     ",
      "                        ",	               
      lines[1],
      "                        ",
      lines[2],
      "                        ",
      lines[3],
      "                        ",
      lines[4],
      "                        ",
      "                   SEND>",
      "                        ",
      "<REQUEST                "
          }
    end
end

fmsPages["ATCVERIFYREQUEST"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    numPages=math.ceil(table.getn(reqData)/4)
    local sendLine="                        "
    if pgNo==numPages then
        sendLine="                 REQUEST"
    end
    local start=(pgNo-1)*4
    lines={}
    for i=1,4 do
        local lID=start+i
        if lID<=table.getn(reqData) then
            lines[i] =reqData[lID][1]
        else
            lines[i] ="                        "
        end
        print(lines[i])
    end
      return{
"                    ".. pgNo.."/"..numPages,
lines[1],
"                        ",
lines[2],
"                        ",
lines[3],
"                        ",
lines[4],
"                        ",
sendLine,
"                        ",
"------------------------",
"                        "
    }

end
fmsPages["ATCVERIFYREQUEST"].getNumPages=function(self)
    numPages=math.ceil(table.getn(reqData)/4)
    if numPages<1 then numPages=1 end
  return numPages 
end

  
fmsFunctionsDefs["ATCVERIFYREQUEST"]={}
fmsFunctionsDefs["ATCVERIFYREQUEST"]["L6"]={"setpage","ATCREQUEST"}