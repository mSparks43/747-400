--5.33.47
fmsPages["WHENCANWE"]=createPage("WHENCANWE")
fmsPages["WHENCANWE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    local wcwCRZCLB=getFMSData("acarsWCWCRZCLB")
    local wcwCLB=getFMSData("acarsWCWCLB")
    local wcwDES=getFMSData("acarsWCWDES")
    local wcwSPD=getFMSData("acarsWCWSPEED")
    return{

"   WHEN CAN WE EXPECT   ",
"                        ",	               
wcwCRZCLB.."                   ",
"                        ",
wcwCLB.."                   ",
"                        ",
wcwDES.."                   ",
"                        ",
".".. wcwSPD .."                     ",
"                        ",
"<ERASE WHEN CAN WE      ",
"------------------------",
"<INDEX           VERIFY>"
    }
end

fmsPages["WHENCANWE"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                        ",      
" CRZ CLB TO             ",
"                        ",	               
" CLIMB TO               ",
"             HIGHER ALT>",
" DESCENT TO             ",
"              LOWER ALT>",
" SPEED                  ",
"            BACK ON RTE>",
"                        ",
"                        ",
"                        ",
"                        "
    }
end


  
fmsFunctionsDefs["WHENCANWE"]={}
fmsFunctionsDefs["WHENCANWE"]["L6"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["WHENCANWE"]["L1"]={"setdata","acarsWCWCRZCLB"}
fmsFunctionsDefs["WHENCANWE"]["L2"]={"setdata","acarsWCWCLB"}
fmsFunctionsDefs["WHENCANWE"]["L3"]={"setdata","acarsWCWDES"}
fmsFunctionsDefs["WHENCANWE"]["L4"]={"setdata","acarsWCWSPEED"}
fmsFunctionsDefs["WHENCANWE"]["L5"]={"clearwce",""}
fmsFunctionsDefs["WHENCANWE"]["R2"]={"setacars","WHEN CAN WE EXPECT HIGHER ALT"}
fmsFunctionsDefs["WHENCANWE"]["R3"]={"setacars","WHEN CAN WE EXPECT LOWER ALT"}
fmsFunctionsDefs["WHENCANWE"]["R4"]={"setacars","WHEN CAN WE EXPECT BACK ON RTE"}
fmsFunctionsDefs["WHENCANWE"]["R6"]={"setpage","ATCVERIFYWCEREQUEST"}

fmsPages["ATCVERIFYWCEREQUEST"]=createPage("ATCVERIFYWCEREQUEST")
local reqData={}
fmsPages["ATCVERIFYWCEREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    reqData={}
    local i=1

    local msg="WHEN CAN WE EXPECT"
    local msgTail=""
  
 --[[   acarsWCWCLB=string.rep("-", 5),
  acarsWCWDES=string.rep("-", 5),
  acarsWCWSPEED=string.rep("-", 2),]]--

    local wcecrzclb=getFMSData("acarsWCWCRZCLB")
    if wcecrzclb~="-----" then
        reqData[i]={" CRUISE ALTITUDE           ",wcecrzclb.."                     "}
        i=i+1       
        msg=str_trim(msg.." CRUISE ALTITUDE "..wcecrzclb)
    end
    local wceclb=getFMSData("acarsWCWCLB")
    if wceclb~="-----" then
        reqData[i]={" CLIMB TO           ",wceclb.."                     "}
        i=i+1       
        msg=str_trim(msg.." CLIMB TO "..wceclb)
    end
    local wcedes=getFMSData("acarsWCWDES")
    if wcedes~="-----" then
        reqData[i]={" DESCEND TO           ",wcedes.."                     "}
        i=i+1       
        msg=str_trim(msg.." DESCEND TO "..wcedes)
    end
    local reqSPD=getFMSData("acarsWCWSPEED")
    if reqSPD~="--" then
        reqData[i]={" SPEED       ","."..reqSPD.."                     "}
        i=i+1
        msg=str_trim(msg.." SPEED M."..reqSPD)
    end
    if i==1 then
        msg=getFMSData("acarsMessage")
        local msgLines=convertToFMSLines(msg)
        for z=1,table.getn(msgLines) do
            reqData[i]={"/FREE TEXT              ",msgLines[z]}
            i=i+1
        end
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
        fmsFunctionsDefs["ATCVERIFYWCEREQUEST"]["L5"]=nil
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
            "<WHEN CAN WE            "
            }
      else
        fmsFunctionsDefs["ATCVERIFYWCEREQUEST"]["R5"]={"setdata","sendarmedacarsrr"}
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
      "<WHEN CAN WE            "
          }
    end
end

fmsPages["ATCVERIFYWCEREQUEST"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
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
fmsPages["ATCVERIFYWCEREQUEST"].getNumPages=function(self)
    numPages=math.ceil(table.getn(reqData)/4)
    if numPages<1 then numPages=1 end
  return numPages 
end

  
fmsFunctionsDefs["ATCVERIFYWCEREQUEST"]={}
fmsFunctionsDefs["ATCVERIFYWCEREQUEST"]["L6"]={"setpage","WHENCANWE"}