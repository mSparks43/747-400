fmsPages["ATCREPORT2"]=createPage("ATCREPORT2")
fmsPages["ATCREPORT2"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"      VERIFY REPORT     ",
" WE CAN ACCEPT          ",	               
"FL390                   ",
"  AT                    ",
"****z                   ",
"                        ",
"<CANNOT ACCEPT          ",
" FREE TEXT              ",
"<                       ",
"                  REPORT",
"                   SEND>",
"------------------------",
"<REPORT                 " 
    }
end

fmsPages["ATCREPORT2"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"                        ",
" WE CAN ACCEPT          ",	               
"                        ",
"  AT                    ",
"                        ",
"                        ",
"                        ",
"                        ",
"<                       ",
"                  REPORT",
"                        ",
"------------------------",
"<REPORT                 " 
    }
end


  
fmsFunctionsDefs["ATCREPORT2"]={}
--[[
fmsFunctionsDefs["ATCREPORT2"]["L1"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["L2"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["L3"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["L5"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["L6"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R1"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R2"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R3"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R4"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R5"]={"setpage",""}
fmsFunctionsDefs["ATCREPORT2"]["R6"]={"setpage",""}
]]

