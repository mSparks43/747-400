B747DR_airspeed_V1                              = deferred_dataref("laminar/B747/airspeed/V1", "number")
B747DR_airspeed_Vr                              = deferred_dataref("laminar/B747/airspeed/Vr", "number")
B747DR_airspeed_V2                              = deferred_dataref("laminar/B747/airspeed/V2", "number")
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
  "               **.*  **%",
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
  "               **.*  **%",
  "                        ",
  "            RW***       ", 
  "-----------------       ",
  "<INDEX         POS INIT>"}
    end
  
end

fmsPages["TAKEOFF"].getSmallPage=function(self,pgNo,fmsID)
    return{

"                        ",
" FLAP/ACCEL HT    REF V1",
"  /1500FT            KT>",
" E/O ACCEL HT     REF VR",
"1500FT               KT>",
" THR REDUCTION    REF V2",
"                     KT>",
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
fmsFunctionsDefs["TAKEOFF"]["L1"]={"setDref","flapsRef"}
