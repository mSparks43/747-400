-- VNAV Page by Garen Evans, Revised 16 April 2021 0718 UTC
----------------------------------------------------------------------------------------------
local conv = 1.0 --converter (pounds to kilos)

fmsPages["LRC"]=createPage("LRC")
fmsPages["LRC"].getPage=function(self,pgNo,fmsID)--dynamic pages need to be this way

if simConfigData["data"].SIM.weight_display_units == "LBS" then
  conv = 1.0
else
  conv = 1 / simConfigData["data"].SIM.kgs_to_lbs
end

fmsFunctionsDefs["LRC"]["L5"]={"setpage","VNAV_2"}
fmsFunctionsDefs["LRC"]["R6"]=nil
fmsFunctionsDefs["LRC"]["R7"]=nil

--Distance to TOD
tds = "****.*z/  **NM"
local dist_to_tod = B747BR_totalDistance - B747BR_tod

if(simDR_TAS_mps == nil) then
  simDR_TAS_mps = find_dataref("sim/flightmodel/position/true_airspeed") -- true airspeed in meters per second
end

if(simDR_TAS_mps == nil) then
  currTAS = 0
else
  currTAS = simDR_TAS_mps * 1.94384
end

if(currTAS == nil or currTAS < 100) then
  currTAS = 400
end

--print(os.date("%c",os.time())) 
--local time_at_tod = os.date("%H%I",os.clock())

time_at_tod = os.date("%H%I",os.time() + 3600 * dist_to_tod / currTAS)

tds = string.format("%s/  %.0f NM",time_at_tod,dist_to_tod);

--local distToTOD  = totalDist - toDist
local gwtk = simDR_GRWT/1000

-- Turbulent Air Penetration N1 (M0.84/290), and LRC mach target 
local czak = -1
local crzaltString = fmsModules["data"]["crzalt"]
local turbN1 = "**.*"
local lrcMach = ".***"
if(crzaltString ~= "*****" and crzaltString ~= nil and gwtk ~= nil) then

  if(string.sub(fmsModules["data"]["crzalt"],1,2) == "FL") then
    czak = string.sub(fmsModules["data"]["crzalt"],3)/10
  else
    czak = fmsModules["data"]["crzalt"]/1000
  end
  turbN1=string.format("%.1f",  46.152762+0.79337*czak + 0.060831*gwtk) -- model derived fcom p.1573

  -- Target speed for long range cruise, model derived from fcom p. 1577
  local lrc = (388.2356 + 0.6203 * gwtk + 7.8061 * czak) / 1000
  lrcMach = string.format("%.3f",lrc)

end

-- Optimum and Maximum Altitudes
local optmax = "FL***/***"
if(gwtk ~= nil) then
  optA = 56.87272727 - 0.07227273 * gwtk -- model derived fcom p. 1576
  maxA = 58.16363636 - 0.06154545  * gwtk -- model derived fcom p. 1576, ISA+10 and below
  if(maxA > 45.1) then maxA=45.1 end -- service ceiling 45100 MSL
  optmax = string.format("FL%.0f/%.0f",optA*10,maxA*10) -- displayed in flight levela
end

-- wind direction and speed
local wind_hdg = round(simDR_wind_degrees)
local wind_spd = tostring(round(simDR_wind_speed))
local wind_string = string.format("%03.0f`/%s", wind_hdg, wind_spd)

-- fuel at destination
local fobLBS = simDR_fueL_tank_weight_total_kg * 2.20462
local fad = conv*((fobLBS - B747BR_totalDistance * 51.6)/1000)
local fad = string.format("%5.1f", fad)


return{
  "      ACT LRC CRZ       ",
  "",
  fmsModules["data"]["crzalt"].."  "..optmax,
  "",
  lrcMach.."      "..tds,
  "",
  turbN1.."/ "..turbN1.."%    "..wind_string,
  "",
  "         "..fad,
  "------------------------",
  "<ECON           ENG OUT>", 
  "                        ",
  "                    RTA>"
  }  

end

fmsPages["LRC"].getSmallPage=function(self,pgNo,fmsID)

  
  return{
    "                        ",
    "CRZ ALT  OPT/MAX        ",
    "                        ",
    " TGT SPD          TO T/D",
    "                        ",
    " TURB N1     ACTUAL WIND",
    "                        ",
    " FUEL AT DEST           ", --..string.sub(B747DR_srcfms[fmsID][3],-4), --fmsModules["data"]["fltdst"],
    "                        ",
    "                        ",
    "                        ",
    "                        ",
    "                        "


  }

end

fmsPages["LRC"].getNumPages=function(self)
  return 1
end