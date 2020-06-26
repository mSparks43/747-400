fmsPages["TAKEOFF"]=createPage("TAKEOFF")
fmsPages["TAKEOFF"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
    return{

"      TAKEOFF REF       ",
"                        ",
"                        ",
"                        ",
"                        ",
"                        ",
"FLAPS *  CLB *          ",
"                        ",
"               **.*  **%",
"                        ",
"            RW***       ", 
"-----------------       ",
"<INDEX         POS INIT>"
    }
end

fmsPages["TAKEOFF"].getSmallPage=function(self,pgNo,fmsID)
    return{

"                        ",
" FLAP/ACCEL HT    REF V1",
""..fmsModules["data"]["toflap"] .."/1500FT         "..fmsModules["data"]["v1"] .."KT>",
" E/O ACCEL HT     REF VR",
"1500FT            "..fmsModules["data"]["vr"] .."KT>",
" THR REDUCTION    REF V2",
"                  "..fmsModules["data"]["v2"] .."KT>",
"               TRIM   CG",
"                        ",
"               POS SHIFT",
"                   --00M", 
"-----------------PRE-FLT",
"                        "
    }
end


fmsFunctionsDefs["TAKEOFF"]={}
fmsFunctionsDefs["TAKEOFF"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["TAKEOFF"]["R6"]={"setpage","POSINIT"}
fmsFunctionsDefs["TAKEOFF"]["R1"]={"setdata","v1"}
fmsFunctionsDefs["TAKEOFF"]["R2"]={"setdata","vr"}
fmsFunctionsDefs["TAKEOFF"]["R3"]={"setdata","v2"}
fmsFunctionsDefs["TAKEOFF"]["L1"]={"setdata","toflap"}
