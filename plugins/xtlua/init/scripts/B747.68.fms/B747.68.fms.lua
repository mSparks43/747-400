--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
 
function deferred_dataref(name,type,notifier)
	print("Deffered dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end
B747DR_ap_vnav_pause            = deferred_dataref("laminar/B747/autopilot/vnav_pause","number")
B747DR_fmc_notifications            = deferred_dataref("laminar/B747/fms/notification","array[53]")
ilsData=deferred_dataref("laminar/B747/radio/ilsData", "string")
acars=create_dataref("laminar/B747/comm/acars","number")  
toderate=deferred_dataref("laminar/B747/engine/derate/TO","number") 
clbderate=deferred_dataref("laminar/B747/engine/derate/CLB","number")
radioModes=deferred_dataref("laminar/B747/radio/tuningmodes", "string")
radioModes="AAAMM" --ils,vor l/r,adf l/r (ADF is manual only
B747DR_FMSdata=deferred_dataref("laminar/B747/fms/data", "string")
B747DR_FMSdata="{}"
irs_line1=deferred_dataref("laminar/B747/irs/line1", "string")
irs_line2=deferred_dataref("laminar/B747/irs/line2", "string") 
irs_line3=deferred_dataref("laminar/B747/irs/line3", "string") 
irs_line4=deferred_dataref("laminar/B747/irs/line4", "string") 
irs_line1="TIME TO ALIGN"
irs_line2="L OFF"
irs_line3="C OFF"
irs_line4="R OFF"
function createFMSDatarefs(fmsid)
create_dataref("laminar/B747/"..fmsid.."/Line01_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line02_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line03_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line04_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line05_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line06_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line07_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line08_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line09_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line10_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line11_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line12_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line13_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line14_L", "string")
create_dataref("laminar/B747/"..fmsid.."/Line01_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line02_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line03_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line04_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line05_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line06_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line07_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line08_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line09_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line10_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line11_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line12_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line13_S", "string")
create_dataref("laminar/B747/"..fmsid.."/Line14_S", "string")
end
createFMSDatarefs("fms1")
createFMSDatarefs("fms2")
createFMSDatarefs("fms3")
--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--

-- CRT BRIGHTNESS DIAL ------------------------------------------------------------------
B747DR_fms1_display_brightness      = create_dataref("laminar/B747/fms1/display_brightness", "number", B747_fms1_display_brightness_DRhandler)

--pos data
B747DR_waypoint_ata					= deferred_dataref("laminar/B747/nd/waypoint_ata", "string")
B747DR_last_waypoint				= deferred_dataref("laminar/B747/nd/last_waypoint", "string")
B747DR_next_waypoint_eta					= deferred_dataref("laminar/B747/nd/next_waypoint_eta", "string")
B747DR_next_waypoint				= deferred_dataref("laminar/B747/nd/next_waypoint", "string")

--Waypoint info for ND DISPLAY
B747DR_ND_waypoint_eta					= deferred_dataref("laminar/B747/nd/waypoint_eta", "string")
B747DR_ND_current_waypoint				= deferred_dataref("laminar/B747/nd/current_waypoint", "string")
B747DR_ND_waypoint_distance				= deferred_dataref("laminar/B747/nd/waypoint_distance", "string")

--ND Range DISPLAY
B747DR_ND_range_display_capt			= deferred_dataref("laminar/B747/nd/range_display_capt", "number")
B747DR_ND_range_display_fo				= deferred_dataref("laminar/B747/nd/range_display_fo", "number")

--IRS ND DISPLAY
B747DR_ND_GPS_Line						= deferred_dataref("laminar/B747/irs/gps_display_line", "string")
B747DR_ND_IRS_Line						= deferred_dataref("laminar/B747/irs/irs_display_line", "string")

--SPEED ND DISPLAY
B747DR_ND_GS_TAS_Line					= deferred_dataref("laminar/B747/nd/gs_tas_line", "string")
B747DR_ND_GS_TAS_Line_Pilot				= deferred_dataref("laminar/B747/nd/gs_tas_line_pilot", "string")
B747DR_ND_GS_TAS_Line_CoPilot			= deferred_dataref("laminar/B747/nd/gs_tas_line_copilot", "string")
B747DR_ND_Wind_Line						= deferred_dataref("laminar/B747/nd/wind_line", "string")
B747DR_ND_Wind_Bearing					= deferred_dataref("laminar/B747/nd/wind_bearing", "number")

function createFMSCommands(fmsO,cduid,fmsid,keyid,fmskeyid)
B747CMD_fms1_ls_key_L1              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/L1", fmsO.." Line Select Key 1-Left")
  B747CMD_fms1_ls_key_L2            = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/L2", fmsO.." Line Select Key 2-Left")
  B747CMD_fms1_ls_key_L3            = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/L3", fmsO.." Line Select Key 3-Left")
B747CMD_fms1_ls_key_L4              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/L4", fmsO.." Line Select Key 4-Left")
B747CMD_fms1_ls_key_L5              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/L5", fmsO.." Line Select Key 5-Left")
B747CMD_fms1_ls_key_L6              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/L6", fmsO.." Line Select Key 6-Left")

B747CMD_fms1_ls_key_R1              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/R1", fmsO.." Line Select Key 1-Right")
B747CMD_fms1_ls_key_R2              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/R2", fmsO.." Line Select Key 2-Right")
B747CMD_fms1_ls_key_R3              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/R3", fmsO.." Line Select Key 3-Right")
B747CMD_fms1_ls_key_R4              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/R4", fmsO.." Line Select Key 4-Right")
B747CMD_fms1_ls_key_R5              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/R5", fmsO.." Line Select Key 5-Right")
B747CMD_fms1_ls_key_R6              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/ls_key/R6", fmsO.." Line Select Key 6-Right")


-- FUNCTION KEYS ------------------------------------------------------------------------
B747CMD_fms1_func_key_index         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/index", fmsO.." Function Key INDEX")
B747CMD_fms1_func_key_fpln          = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/fpln", fmsO.." Function Key FPLN")
B747CMD_fms1_func_key_navrad        = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/navrad", fmsO.." Function Key FPLN")
B747CMD_fms1_func_key_clb           = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/clb", fmsO.." Function Key CLB")
B747CMD_fms1_func_key_crz           = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/crz", fmsO.." Function Key CRZ")
B747CMD_fms1_func_key_des           = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/des", fmsO.." Function Key DES")
B747CMD_fms1_func_key_dir_intc      = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/dir_intc", fmsO.." Function Key DIR/INTC")
B747CMD_fms1_func_key_legs          = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/legs", fmsO.." Function Key LEGS")
B747CMD_fms1_func_key_dep_arr       = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/dep_arr", fmsO.." Function Key DEP/ARR")
B747CMD_fms1_func_key_hold          = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/hold", fmsO.." Function Key HOLD")
B747CMD_fms1_func_key_prog          = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/prog", fmsO.." Function Key PROG")
B747CMD_fms1_key_execute            = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/execute", fmsO.." KEY EXEC")
B747CMD_fms1_func_key_fix           = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/fix", fmsO.." Function Key FIX")
B747CMD_fms1_func_key_prev_pg       = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/prev_pg", fmsO.." Function Key PREV PAGE")
B747CMD_fms1_func_key_next_pg       = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/func_key/next_pg", fmsO.." Function Key NEXT PAGE")


-- ALPHA-NUMERIC KEYS -------------------------------------------------------------------
B747CMD_fms1_alphanum_key_0         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/0", fmsO.." Alpha/Numeric Key 0")
B747CMD_fms1_alphanum_key_1         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/1", fmsO.." Alpha/Numeric Key 1")
B747CMD_fms1_alphanum_key_2         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/2", fmsO.." Alpha/Numeric Key 2")
B747CMD_fms1_alphanum_key_3         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/3", fmsO.." Alpha/Numeric Key 3")
B747CMD_fms1_alphanum_key_4         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/4", fmsO.." Alpha/Numeric Key 4")
B747CMD_fms1_alphanum_key_5         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/5", fmsO.." Alpha/Numeric Key 5")
B747CMD_fms1_alphanum_key_6         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/6", fmsO.." Alpha/Numeric Key 6")
B747CMD_fms1_alphanum_key_7         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/7", fmsO.." Alpha/Numeric Key 7")
B747CMD_fms1_alphanum_key_8         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/8", fmsO.." Alpha/Numeric Key 8")
B747CMD_fms1_alphanum_key_9         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/9", fmsO.." Alpha/Numeric Key 9")

B747CMD_fms1_key_period             = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/period", fmsO.." Key '.'")
B747CMD_fms1_key_minus              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/minus", fmsO.." Key '+/-'")

B747CMD_fms1_alphanum_key_A         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/A", fmsO.." Alpha/Numeric Key A")
B747CMD_fms1_alphanum_key_B         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/B", fmsO.." Alpha/Numeric Key B")
B747CMD_fms1_alphanum_key_C         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/C", fmsO.." Alpha/Numeric Key C")
B747CMD_fms1_alphanum_key_D         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/D", fmsO.." Alpha/Numeric Key D")
B747CMD_fms1_alphanum_key_E         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/E", fmsO.." Alpha/Numeric Key E")
B747CMD_fms1_alphanum_key_F         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/F", fmsO.." Alpha/Numeric Key F")
B747CMD_fms1_alphanum_key_G         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/G", fmsO.." Alpha/Numeric Key G")
B747CMD_fms1_alphanum_key_H         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/H", fmsO.." Alpha/Numeric Key H")
B747CMD_fms1_alphanum_key_I         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/I", fmsO.." Alpha/Numeric Key I")
B747CMD_fms1_alphanum_key_J         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/J", fmsO.." Alpha/Numeric Key J")
B747CMD_fms1_alphanum_key_K         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/K", fmsO.." Alpha/Numeric Key K")
B747CMD_fms1_alphanum_key_L         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/L", fmsO.." Alpha/Numeric Key L")
B747CMD_fms1_alphanum_key_M         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/M", fmsO.." Alpha/Numeric Key M")
B747CMD_fms1_alphanum_key_N         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/N", fmsO.." Alpha/Numeric Key N")
B747CMD_fms1_alphanum_key_O         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/O", fmsO.." Alpha/Numeric Key O")
B747CMD_fms1_alphanum_key_P         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/P", fmsO.." Alpha/Numeric Key P")
B747CMD_fms1_alphanum_key_Q         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/Q", fmsO.." Alpha/Numeric Key Q")
B747CMD_fms1_alphanum_key_R         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/R", fmsO.." Alpha/Numeric Key R")
B747CMD_fms1_alphanum_key_S         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/S", fmsO.." Alpha/Numeric Key S")
B747CMD_fms1_alphanum_key_T         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/T", fmsO.." Alpha/Numeric Key T")
B747CMD_fms1_alphanum_key_U         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/U", fmsO.." Alpha/Numeric Key U")
B747CMD_fms1_alphanum_key_V         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/V", fmsO.." Alpha/Numeric Key V")
B747CMD_fms1_alphanum_key_W         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/W", fmsO.." Alpha/Numeric Key W")
B747CMD_fms1_alphanum_key_X         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/X", fmsO.." Alpha/Numeric Key X")
B747CMD_fms1_alphanum_key_Y         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/Y", fmsO.." Alpha/Numeric Key Y")
B747CMD_fms1_alphanum_key_Z         = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/alphanum_key/Z", fmsO.." Alpha/Numeric Key Z")

B747CMD_fms1_key_space              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/space", fmsO.." KEY SP")
B747CMD_fms1_key_del                = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/del", fmsO.." KEY DEL")
B747CMD_fms1_key_slash              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/slash", fmsO.." Key '/'")
B747CMD_fms1_key_clear              = XLuaCreateCommand("laminar/B747/".. fmskeyid .. "/key/clear", fmsO.." KEY CLR")
end  

createFMSCommands("FMS C","cdu1","fms1","sim/FMS/","fms3")

createFMSCommands("FMS L","cdu1","fms3","sim/FMS/","fms1")
 
createFMSCommands("FMS R","cdu2","fms2","sim/FMS2/","fms2")
