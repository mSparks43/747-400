fmsPages["IDENT"]=createPage("IDENT")
dofile("activepages/version.lua")

fmsPages["IDENT"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
	local nav_data_from_month = string.sub(B747DR_srcfms[fmsID][5],3,5)
	local nav_data_from_day = string.sub(B747DR_srcfms[fmsID][5],1,2)
	local nav_data_to_month = string.sub(B747DR_srcfms[fmsID][5],11,13)
	local nav_data_to_day = string.sub(B747DR_srcfms[fmsID][5],9,10)
	local nav_data_yr = string.sub(B747DR_srcfms[fmsID][5],14,15)
	simConfigData["data"].active = string.format("%s%s%s%s/%s", nav_data_from_month, nav_data_from_day, nav_data_to_month, nav_data_to_day, nav_data_yr)
	simConfigData["data"].op_program = fmcVersion
    return{

 "       IDENT            ",
 "                        ",
 simConfigData["data"].model.."     "..simConfigData["data"].engines,
 "                        ",
 "           "..simConfigData["data"].active,
 "                        ",
 "                        ",
 "                        ",
 simConfigData["data"].op_program.."       ",
 "                        ",
 simConfigData["data"].drag_ff.."         "..fmsModules["data"].codata,
 "------------------------",
 "<INDEX         POS INIT>"
    }
end

fmsPages["IDENT"]["templateSmall"]={
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


  
  
fmsFunctionsDefs["IDENT"]={}
fmsFunctionsDefs["IDENT"]["L6"]={"setpage","INITREF"}
fmsFunctionsDefs["IDENT"]["R5"]={"setdata","codata"}
fmsFunctionsDefs["IDENT"]["R6"]={"setpage","POSINIT"}

