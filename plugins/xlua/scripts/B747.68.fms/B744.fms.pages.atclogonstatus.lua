fmsPages["ATCLOGONSTATUS"]=createPage("ATCLOGONSTATUS")
fmsPages["ATCLOGONSTATUS"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"    ATC LOGON/STATUS    ",
"                        ",	               
"****            ACCEPTED",
"                        ",
"*******                 ",
"                        ",
"<SELECT OFF         ****",
"                        ",
"                    ****",
"                        ",
"<SELECT OFF   SELECT ON>",
"                        ",
"<INDEX             READY"
    }
end

fmsPages["ATCLOGONSTATUS"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
  
"    ATC LOGON/STATUS    ",
" LOGON TO          LOGON",	               
"                        ",
" FLT NO                 ",
"                        ",
" ATC COMM        ACT CTR",
"                        ",
"                NEXT CTR",
"                        ",
" ADS (ACT)     ADS ENERG",
"                        ",
"----------------DATALINK",
"                        "
    }
end


fmsFunctionsDefs["ATCLOGONSTATUS"]={}
--[[
fmsFunctionsDefs["ATCLOGONSTATUS"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCLOGONSTATUS"]["R6"]={"setpage",""}
]]

