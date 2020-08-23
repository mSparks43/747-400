fmsPages["ATCVERIFYRESPONSE"]=createPage("ATCVERIFYRESPONSE")
fmsPages["ATCVERIFYRESPONSE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"   VERIFY RESPONSE      "
"                        "		               
"WILCO                   "
"                        "
"                        "
"                        "
"                        "
"                        "
"                        "
"                        "
"                   SEND>"
"------------------------"
"                        "  
    }
end

fmsPages["ATCVERIFYRESPONSE"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                    1/1 "
"                        "		               
"                        "
"                        "
"                        "
"                        "
"                        "
"                        "
"                        "
"                RESPONSE"
"                        "
"                        "
"                        " 
}
end

  
fmsFunctionsDefs["ATCVERIFYRESPONSE"]={}
--[[
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCVERIFYRESPONSE"]["R6"]={"setpage",""}
]]

