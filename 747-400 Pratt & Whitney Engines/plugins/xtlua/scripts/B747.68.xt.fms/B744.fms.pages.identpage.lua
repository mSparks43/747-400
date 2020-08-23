fmsPages["IDENTPAGE"]=createPage("IDENTPAGE")
fmsPages["IDENTPAGE"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

 "       IDENT            ",
 "                        ",
 "747-400         -*******",
 "                        ",
 "********** *************",
 "                        ",
 "           **********/**",
 "                        ",
 "PS4052770-944           ",
 "                        ",
 "+1.1/-3.5         ******", 
 "------------------------",
 "<INDEX         POS INIT>"
    }
end

fmsPages["IDENTPAGE"]["templateSmall"]={
"                        ",
" MODEL           ENGINES",
"                        ",
" NAV DATA         ACTIVE",
"                        ",
"                        ",
"                        ",
" OP PROGRAM             ",
"                        ",
" DRAG/FF         CO DATA",
"                        ", 
"                        ",
"                        "
}


  
  
fmsFunctionsDefs["IDENTPAGE"]={}
fmsFunctionsDefs["IDENTPAGE"]["L1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["L2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["L3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["L5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["IDENTPAGE"]["R1"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["R2"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["R3"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["R4"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["R5"]={"setpage","NOPAGE"}
fmsFunctionsDefs["IDENTPAGE"]["R6"]={"setpage","POSINIT"}

