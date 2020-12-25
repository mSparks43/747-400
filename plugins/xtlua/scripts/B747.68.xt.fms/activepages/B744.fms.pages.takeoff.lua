B747DR_airspeed_V1                              = deferred_dataref("laminar/B747/airspeed/V1", "number")
B747DR_airspeed_Vr                              = deferred_dataref("laminar/B747/airspeed/Vr", "number")
B747DR_airspeed_V2                              = deferred_dataref("laminar/B747/airspeed/V2", "number")
cg_lineLg	= ""
cg_lineSm	= ""

function roundToIncrement(number, increment)

    local y = number / increment
    local q = math.floor(y + 0.5)
    local z = q * increment

    return z

end
--simDR_wing_flap1_deg                = find_dataref("sim/flightmodel2/wing/flap1_deg")
B747DR_airspeed_flapsRef                              = find_dataref("laminar/B747/airspeed/flapsRef")
fmsPages["TAKEOFF"]=createPage("TAKEOFF")
fmsPages["TAKEOFF"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way
  local flaps = roundToIncrement(B747DR_airspeed_flapsRef, 5)
  local v1="***"
  local vr="***"
  local v2="***"
  
	--Marauder28
	if string.len(cg_lineLg) == 0 then
		if fmsModules["data"].cg_mac == "--" then
			cg_lineSm = string.format("%s%%", fmsModules["data"].cg_mac)
		else
			cg_lineSm = string.format("%2.0f%%>", fmsModules["data"].cg_mac)
		end
	else
		cg_lineLg = string.format("%2.0f%%", tonumber(fmsModules["data"].cg_mac))
		cg_lineSm = ""
	end
	--Marauder28

  if B747DR_airspeed_V1<999 then
    v1=B747DR_airspeed_V1
    vr=B747DR_airspeed_Vr
    v2=B747DR_airspeed_V2
  
      return{

  "      TAKEOFF REF       ",
  "                        ",
  string.format("%02d                %3d",flaps, v1),
  "                        ",
  string.format("                  %3d", vr),
  "                        ",
  string.format("FLAPS *  CLB *    %3d", v2),
  "                        ",
  "                     "..cg_lineLg,
  "                        ",
  "            RW***       ", 
  "-----------------       ",
  "<INDEX         POS INIT>"
      }
  else
    return{

  "      TAKEOFF REF       ",
  "                        ",
  string.format("%02d                ***",flaps),
  "                        ",
  string.format("                  ***"),
  "                        ",
  string.format("FLAPS *  CLB *    ***"),
  "                        ",
  "                     "..cg_lineLg,
  "                        ",
  "            RW***       ", 
  "-----------------       ",
  "<INDEX         POS INIT>"}
    end
  
end

fmsPages["TAKEOFF"].getSmallPage=function(self,pgNo,fmsID)

  --Marauder28
  local stab_trim = ""
  
  if string.len(cg_lineLg) > 0 then
	  if fmsModules["data"].stab_trim ~= "    " then
			stab_trim = string.format("%3.1f", tonumber(fmsModules["data"].stab_trim))
	  else
			stab_trim = fmsModules["data"].stab_trim
	  end
  end
  --Marauder28
  
    return{

"                        ",
" FLAP/ACCEL HT    REF V1",
"  /1500FT            KT>",
" E/O ACCEL HT     REF VR",
"1500FT               KT>",
" THR REDUCTION    REF V2",
"                     KT>",
"               TRIM   CG",
--"                        ",
"                "..stab_trim.."     "..cg_lineSm,
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
fmsFunctionsDefs["TAKEOFF"]["R4"]={"setdata","cg_mac"}
fmsFunctionsDefs["TAKEOFF"]["L1"]={"setDref","flapsRef"}
