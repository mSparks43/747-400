fmsPages["WHENCANWE"]=createPage("WHENCANWE")
fmsPages["WHENCANWE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"   WHEN CAN WE EXPECT   ",
"                        ",	               
"-----                   ",
"                        ",
"-----                   ",
"                        ",
"-----                   ",
"                        ",
".--                     ",
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

