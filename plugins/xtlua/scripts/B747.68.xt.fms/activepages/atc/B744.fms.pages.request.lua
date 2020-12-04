fmsPages["ATCREQUEST"]=createPage("ATCREQUEST")
fmsPages["ATCREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"       ATC REQUEST      ",
"                        ",	               
"<FL---                  ",
"                        ",
"<.--                    ",
"                        ",
"<---                    ",
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
fmsFunctionsDefs["ATCREQUEST"]["L1"]={"setpage","ATCALTREQUEST"}
fmsFunctionsDefs["ATCREQUEST"]["L6"]={"setpage","ATCINDEX"}
fmsFunctionsDefs["ATCREQUEST"]["R6"]={"setpage","ATCVERIFYREQUEST"}

fmsPages["ATCALTREQUEST"]=createPage("ATCALTREQUEST")
fmsPages["ATCALTREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"     ATC ALT REQUEST    ",
"                        ",	               
"<FL---                  ",
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
end

fmsPages["ATCALTREQUEST"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{
"                        ",      
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
end


  
fmsFunctionsDefs["ATCALTREQUEST"]={}
fmsFunctionsDefs["ATCALTREQUEST"]["L6"]={"setpage","ATCREQUEST"}
fmsFunctionsDefs["ATCALTREQUEST"]["R6"]={"setpage","ATCVERIFYREQUEST"}

fmsPages["ATCVERIFYREQUEST"]=createPage("ATCVERIFYREQUEST")
fmsPages["ATCVERIFYREQUEST"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then 
    return{

"     VERIFY REQUEST     ",
"                        ",	               
" ----                   ",
"                        ",
" ---                    ",
"                        ",
" FL---                  ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"<REQUEST                "
    }
    elseif pgNo==2 then
      return{

"     VERIFY REQUEST     ",
"                        ",	               
"<                       ",
"                        ",
"<                       ",
"                        ",
"<                       ",
"                        ",
"<                       ",
"                        ",
"                   SEND>",
"                        ",
"<REQUEST                "
    }
    end
end

fmsPages["ATCVERIFYREQUEST"].getSmallPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    if pgNo==1 then 
    return{
"                     1/2",      
" AT                     ",
"                        ",	               
" REQUEST OFFSET         ",
"    NM                  ",
"/REQUEST CLIMB TO       ",
"                        ",
"/DUE TO                 ",
"                        ",
"/REQUEST                ",
"                        ",
"--------CONTINUED-------",
"                        "
    }
    elseif pgNo==2 then
      return{
"                     2/2",      
"/FREE TEXT              ",
"                        ",	               
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"                 REQUEST",
"                        ",
"------------------------",
"                        "
    }
    end
end
fmsPages["ATCVERIFYREQUEST"].getNumPages=function(self)
  return 2 
end

  
fmsFunctionsDefs["ATCVERIFYREQUEST"]={}
fmsFunctionsDefs["ATCVERIFYREQUEST"]["L6"]={"setpage","ATCREQUEST"}