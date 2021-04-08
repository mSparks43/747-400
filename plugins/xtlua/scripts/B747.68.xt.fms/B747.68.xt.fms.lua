--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks CC-BY-NC4
*****************************************************************************************
]]
simDRTime=find_dataref("sim/time/total_running_time_sec")
simDR_onGround=find_dataref("sim/flightmodel/failures/onground_any")


B747DR_acfType               = find_dataref("laminar/B747/acfType")
B747DR_payload_weight               = find_dataref("sim/flightmodel/weight/m_fixed")
simDR_acf_m_jettison  		=find_dataref("sim/aircraft/weight/acf_m_jettison")
simDR_m_jettison  		=find_dataref("sim/flightmodel/weight/m_jettison")
B747DR_CAS_advisory_status       = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_ap_vnav_system            = find_dataref("laminar/B747/autopilot/vnav_system")
B747DR_ap_vnav_pause            = find_dataref("laminar/B747/autopilot/vnav_pause")
simDR_nav1Freq			 =find_dataref("sim/cockpit/radios/nav1_freq_hz")
simDR_nav2Freq			 =find_dataref("sim/cockpit/radios/nav2_freq_hz")
B747DR_iru_status         	= find_dataref("laminar/B747/flt_mgmt/iru/status")
B747DR_iru_mode_sel_pos         = find_dataref("laminar/B747/flt_mgmt/iru/mode_sel_dial_pos")

B747DR_rtp_C_off 		 = find_dataref("laminar/B747/comm/rtp_C/off_status")
B747DR_pfd_mode_capt		 = find_dataref("laminar/B747/pfd/capt/irs")
B747DR_pfd_mode_fo		 = find_dataref("laminar/B747/pfd/fo/irs")
B747DR_irs_src_fo		 = find_dataref("laminar/B747/flt_inst/irs_src/fo/sel_dial_pos")
B747DR_irs_src_capt		 = find_dataref("laminar/B747/flt_inst/irs_src/capt/sel_dial_pos")
B747DR_ap_fpa	    = find_dataref("laminar/B747/autopilot/navadata/fpa")
B747DR_ap_vb	    = find_dataref("laminar/B747/autopilot/navadata/vb")
simDR_autopilot_vs_fpm         			= find_dataref("sim/cockpit2/autopilot/vvi_dial_fpm")
B747DR_fmc_notifications            = find_dataref("laminar/B747/fms/notification")

B747DR_altimter_ft_adjusted                     = find_dataref("laminar/B747/altimeter/ft_adjusted")
--Workaround for stack overflow in init.lua namespace_read


function replace_char(pos, str, r)
    return str:sub(1, pos-1) .. r .. str:sub(pos+1)
end
function hasChild(parent,childKey)
  if(parent==nil) then
    return false
  end
  local keyFuncs=rawget(parent,'values')
  if keyFuncs==nil then return false end
  local keyFunc=rawget(keyFuncs,childKey)
  if keyFunc==nil then return false end
 
  return true
end
function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
function round(x)
	return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
  end
function cleanFMSLine(line)
    local retval=line:gsub("☐","*")
    retval=retval:gsub("°","`")
    return retval
end 
function getHeadingDifference(desireddirection,current_heading)
	error = current_heading - desireddirection
	if (error >  180) then error =error- 360 end
	if (error < -180) then error =error+ 360 end
	return error
end
function getHeadingDifferenceM(desireddirection,current_heading)
	error = current_heading - desireddirection
	if (error >  180) then error =error- 360 end
	if (error < -180) then error =error+ 360 end
	if error<0 then error = error *-1 end
	return error
end
function getDistance(lat1,lon1,lat2,lon2)
  alat=math.rad(lat1)
  alon=math.rad(lon1)
  blat=math.rad(lat2)
  blon=math.rad(lon2)
  av=math.sin(alat)*math.sin(blat) + math.cos(alat)*math.cos(blat)*math.cos(blon-alon)
  if av > 1 then av=1 end
  retVal=math.acos(av) * 3440
  --print(lat1.." "..lon1.." "..lat2.." "..lon2)
  --print("Distance = "..retVal) 
  return retVal
end

function toDMS(value,isLat)
  degrees=value
  if value<0 then
    degrees=degrees*-1
   end
  minutes=(value-math.floor(value))*60
  seconds=minutes-math.floor(minutes)
  local p="E"
  if isLat==true and value<0 then 
    p="S"
  elseif isLat==true then  
    p="N"
  elseif value<0 then
    p="W"
  end
  retVal=string.format(p .. "%03d`%02d.%1d",degrees,minutes,seconds*10)
  return retVal
end

function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end
--replace deferred_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
dofile("json/json.lua")
hh=find_dataref("sim/cockpit2/clock_timer/zulu_time_hours")
mm=find_dataref("sim/cockpit2/clock_timer/zulu_time_minutes")
ss=find_dataref("sim/cockpit2/clock_timer/zulu_time_seconds")
simDR_bus_volts               = find_dataref("sim/cockpit2/electrical/bus_volts")
simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")

simDR_instrument_brightness_switch  = find_dataref("sim/cockpit2/switches/instrument_brightness_ratio")
simDR_instrument_brightness_ratio   = find_dataref("sim/cockpit2/electrical/instrument_brightness_ratio_manual")

simDR_radio_nav_freq_Mhz            = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_Mhz")
simDR_radio_nav_freq_khz            = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_khz")
simDR_radio_nav_freq_hz             = find_dataref("sim/cockpit2/radios/actuators/nav_frequency_hz")

simDR_radio_nav_course_deg          = find_dataref("sim/cockpit2/radios/actuators/nav_course_deg_mag_pilot")
simDR_radio_nav_obs_deg             = find_dataref("sim/cockpit2/radios/actuators/nav_obs_deg_mag_pilot")
simDR_radio_nav1_obs_deg             = find_dataref("sim/cockpit/radios/nav1_obs_degt")
simDR_radio_nav2_obs_deg             = find_dataref("sim/cockpit/radios/nav2_obs_degt")
simDR_radio_nav_horizontal          = find_dataref("sim/cockpit2/radios/indicators/nav_display_horizontal")
simDR_radio_nav_hasDME              = find_dataref("sim/cockpit2/radios/indicators/nav_has_dme")
simDR_radio_nav_radial		    = find_dataref("sim/cockpit2/radios/indicators/nav_bearing_deg_mag")
simDR_radio_nav01_ID                = find_dataref("sim/cockpit2/radios/indicators/nav1_nav_id")
simDR_radio_nav02_ID                = find_dataref("sim/cockpit2/radios/indicators/nav2_nav_id")
simDR_radio_nav03_ID                = find_dataref("sim/cockpit2/radios/indicators/nav3_nav_id")
simDR_radio_nav04_ID                = find_dataref("sim/cockpit2/radios/indicators/nav4_nav_id")

simDR_radio_adf1_freq_hz            = find_dataref("sim/cockpit2/radios/actuators/adf1_frequency_hz")
simDR_radio_adf2_freq_hz            = find_dataref("sim/cockpit2/radios/actuators/adf2_frequency_hz")

simDR_fueL_tank_weight_total_kg     = find_dataref("sim/flightmodel/weight/m_fuel_total")

navAidsJSON   = find_dataref("xtlua/navaids")
fmsJSON = find_dataref("xtlua/fms")

B747DR_fms1_display_mode            = find_dataref("laminar/B747/fms1/display_mode")

B747DR_init_fmsL_CD                 = find_dataref("laminar/B747/fmsL/init_CD")
ilsData=deferred_dataref("laminar/B747/radio/ilsData", "string")
acars=deferred_dataref("laminar/B747/comm/acars","number")  
toderate=deferred_dataref("laminar/B747/engine/derate/TO","number") 
clbderate=deferred_dataref("laminar/B747/engine/derate/CLB","number")
B747DR_radioModes=deferred_dataref("laminar/B747/radio/tuningmodes", "string")
B747DR_FMSdata=deferred_dataref("laminar/B747/fms/data", "string")
B747DR_ap_vnav_state                = find_dataref("laminar/B747/autopilot/vnav_state")
simDR_autopilot_vs_status          = find_dataref("sim/cockpit2/autopilot/vvi_status")
B747BR_totalDistance 			= find_dataref("laminar/B747/autopilot/dist/remaining_distance")
B747BR_nextDistanceInFeet 		= find_dataref("laminar/B747/autopilot/dist/next_distance_feet")
B747BR_cruiseAlt 			= find_dataref("laminar/B747/autopilot/dist/cruise_alt")
B747BR_tod				= find_dataref("laminar/B747/autopilot/dist/top_of_descent")
B747DR__gear_chocked           = find_dataref("laminar/B747/gear/chocked")
B747DR_fuel_preselect		= find_dataref("laminar/B747/fuel/preselect")
B747DR_refuel				= find_dataref("laminar/B747/fuel/refuel")
B747DR_fuel_add				= find_dataref("laminar/B747/fuel/add_fuel")

B747DR_efis_min_ref_alt_capt_sel_dial_pos       = find_dataref("laminar/B747/efis/min_ref_alt/capt/sel_dial_pos")
B747DR_efis_ref_alt_capt_set_dial_pos           = find_dataref("laminar/B747/efis/ref_alt/capt/set_dial_pos")
B747DR_efis_dh_reset_capt_switch_pos            = find_dataref("laminar/B747/efis/dh_reset/capt/switch_pos")
B747DR_efis_baro_ref_capt_sel_dial_pos          = find_dataref("laminar/B747/efis/baro_ref/capt/sel_dial_pos")
B747DR_efis_baro_std_capt_switch_pos            = find_dataref("laminar/B747/efis/baro_std/capt/switch_pos")
B747DR_efis_baro_capt_set_dial_pos              = find_dataref("laminar/B747/efis/baro/capt/set_dial_pos")
B747DR_efis_baro_capt_preselect                 = find_dataref("laminar/B747/efis/baro/capt/preselect")
B747DR_efis_baro_alt_ref_capt                   = find_dataref("laminar/B747/efis/baro_ref/capt")

B747DR_efis_min_ref_alt_fo_sel_dial_pos         = find_dataref("laminar/B747/efis/min_ref_alt/fo/sel_dial_pos")
B747DR_efis_ref_alt_fo_set_dial_pos             = find_dataref("laminar/B747/efis/ref_alt/fo/set_dial_pos")
B747DR_efis_dh_reset_fo_switch_pos              = find_dataref("laminar/B747/efis/dh_reset/fo/switch_pos")
B747DR_efis_baro_ref_fo_sel_dial_pos            = find_dataref("laminar/B747/efis/baro_ref/fo/sel_dial_pos")
B747DR_efis_baro_std_fo_switch_pos              = find_dataref("laminar/B747/efis/baro_std/fo/switch_pos")
B747DR_efis_baro_fo_set_dial_pos                = find_dataref("laminar/B747/efis/baro/fo/set_dial_pos")
B747DR_efis_baro_fo_preselect                   = find_dataref("laminar/B747/efis/baro/fo/preselect")
B747DR_efis_baro_alt_ref_fo                     = find_dataref("laminar/B747/efis/baro_ref/fo")


simDR_EFIS_1_sel_pilot              = find_dataref("sim/cockpit2/EFIS/EFIS_1_selection_pilot")
simDR_EFIS_1_sel_fo              = find_dataref("sim/cockpit2/EFIS/EFIS_1_selection_copilot")
simDR_EFIS_2_sel_pilot                 = find_dataref("sim/cockpit2/EFIS/EFIS_2_selection_pilot")
simDR_EFIS_2_sel_fo                 = find_dataref("sim/cockpit2/EFIS/EFIS_2_selection_copilot")
B747DR_nd_capt_vor_ndb                          = find_dataref("laminar/B747/nd/data/capt/vor_ndb")
B747DR_nd_capt_wpt							= find_dataref("laminar/B747/nd/data/capt/wpt")
B747DR_nd_fo_vor_ndb                          	= find_dataref("laminar/B747/nd/data/fo/vor_ndb")
B747DR_nd_fo_wpt                          	= find_dataref("laminar/B747/nd/data/fo/wpt")
B747DR_nd_capt_apt	                        = find_dataref("laminar/B747/nd/data/capt/apt")
B747DR_nd_fo_apt	                        = find_dataref("laminar/B747/nd/data/fo/apt")
B747DR_nd_fo_ftc	                        = find_dataref("laminar/B747/nd/fo/tfc")
B747DR_nd_capt_ftc	                        = find_dataref("laminar/B747/nd/capt/tfc")
B747DR_nd_capt_traffic_Selected                 = find_dataref("laminar/B747/nd/traffic/capt/selected")
B747DR_nd_fo_traffic_Selected                   = find_dataref("laminar/B747/nd/traffic/fo/selected")
B747DR_nd_wxr	                        = find_dataref("sim/cockpit2/EFIS/EFIS_weather_on")
simDR_radio_alt_DH_capt             = find_dataref("sim/cockpit2/gauges/actuators/radio_altimeter_bug_ft_pilot")
simDR_radio_alt_DH_fo               = find_dataref("sim/cockpit2/gauges/actuators/radio_altimeter_bug_ft_copilot")

simDR_altimeter_baro_inHg           = find_dataref("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_pilot")
simDR_altimeter_baro_inHg_fo        = find_dataref("sim/cockpit2/gauges/actuators/barometer_setting_in_hg_copilot")

--Marauder28
--Used in ND DISPLAY
simDR_latitude				= find_dataref("sim/flightmodel/position/latitude")
simDR_longitude				= find_dataref("sim/flightmodel/position/longitude")
simDR_navID					= find_dataref("sim/cockpit2/radios/indicators/gps_nav_id")
simDR_range_dial_capt		= find_dataref("laminar/B747/nd/range/capt/sel_dial_pos")
simDR_range_dial_fo			= find_dataref("laminar/B747/nd/range/fo/sel_dial_pos")
simDR_nd_mode_dial_capt		= find_dataref("laminar/B747/nd/mode/capt/sel_dial_pos")
simDR_nd_mode_dial_fo			= find_dataref("laminar/B747/nd/mode/fo/sel_dial_pos")
simDR_nd_center_dial_capt		= find_dataref("laminar/B747/nd/map_center/capt")
simDR_nd_center_dial_fo			= find_dataref("laminar/B747/nd/map_center/fo")
simDR_EFIS_map_mode                 = find_dataref("sim/cockpit2/EFIS/map_mode")
simDR_EFIS_map_range                = find_dataref("sim/cockpit2/EFIS/map_range")

simDR_groundspeed			= find_dataref("sim/flightmodel2/position/groundspeed")
simDR_ias_pilot				= find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
simDR_wind_degrees			= find_dataref("sim/cockpit2/gauges/indicators/wind_heading_deg_mag")
simDR_wind_speed			= find_dataref("sim/cockpit2/gauges/indicators/wind_speed_kts")
simDR_mach_pilot			= find_dataref("sim/cockpit2/gauges/indicators/mach_pilot")
simDR_mach_copilot			= find_dataref("sim/cockpit2/gauges/indicators/mach_copilot")
simDR_total_air_temp		= find_dataref("sim/cockpit2/temperature/outside_air_LE_temp_degc")
simDR_air_temp		= find_dataref("sim/cockpit2/temperature/outside_air_temp_degc")
simDR_aircraft_hdg		 	= find_dataref("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot")

--WB CG Info
simDR_cgZ_ref_point			= find_dataref("sim/aircraft/weight/acf_cgZ_original")
simDR_cgz_ref_to_default	= find_dataref("sim/flightmodel/misc/cgz_ref_to_default")
simDR_empty_weight			= find_dataref("sim/aircraft/weight/acf_m_empty")
simDR_fuel_qty				= find_dataref("sim/flightmodel/weight/m_fuel")
simDR_cg_adjust				= find_dataref("sim/flightmodel/misc/cgz_ref_to_default")
simDR_livery_path			= find_dataref("sim/aircraft/view/acf_livery_path")
simDR_onground				= find_dataref("sim/flightmodel/failures/onground_any")
simDR_payload_weight		= find_dataref("sim/flightmodel/weight/m_fixed")
simDR_fuel_totalizer_kg		= find_dataref("sim/cockpit2/fuel/fuel_totalizer_init_kg")
--Marauder28

--*************************************************************************************--
--** 				        CREATE READ-WRITE CUSTOM DATAREFS                        **--
--*************************************************************************************--

-- CRT BRIGHTNESS DIAL ------------------------------------------------------------------
B747DR_fms1_display_brightness      = deferred_dataref("laminar/B747/fms1/display_brightness", "number", B747_fms1_display_brightness_DRhandler)

--Marauder28
-- Holds all SimConfig options
B747DR_simconfig_data					= deferred_dataref("laminar/B747/simconfig", "string")

-- Temp location for fuel preselect for displaying in correct units
B747DR_fuel_preselect_temp				= deferred_dataref("laminar/B747/fuel/fuel_preselect_temp", "number")

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

--STAB TRIM setting
B747DR_elevator_trim				    = deferred_dataref("laminar/B747/fmc/elevator_trim", "number")

--Sound Options (crazytimtimtim + Matt726)
B747DR_SNDoptions_gpws                  = deferred_dataref("laminar/B747/fmod/options/gpws", "number") -- GPWS sound option
B747DR_SNDoptions_seatBelt              = deferred_dataref("laminar/B747/fmod/options/seatBelt", "number") -- Seatbelt Sound option
B747DR_SNDoptions_pa                    = deferred_dataref("laminar/B747/fmod/options/pa", "number") -- PA sounds
B747DR_SNDoptions_music                 = deferred_dataref("laminar/B747/fmod/options/music", "number") -- Boarding Music
B747DR_SNDoptions_modernAlarms          = deferred_dataref("laminar/B747/fmod/options/modernAlarms", "number") -- 777 sounding alarms
--sound options end						Matt, add another entry here to create another dataref for sound options. Make sure there is an identical line in the xt file.

--Simulator Config Options
simConfigData = {}
if string.len(B747DR_simconfig_data) > 1 then
	simConfigData["data"] = json.decode(B747DR_simconfig_data)
else
	simConfigData["data"] = json.decode("[]")
end
--Marauder28

--Marauder28
--Weight & Balance data
wb = {
		--Weights
		OEW_weight				= 0,
		fuel_CTR_0_weight		= 0,
		fuel_L_main1_weight		= 0,
		fuel_L_main2_weight		= 0,
		fuel_R_main3_weight		= 0,
		fuel_R_main4_weight		= 0,
		fuel_L_rsv5_weight		= 0,
		fuel_R_rsv6_weight		= 0,
		fuel_stab7_weight		= 0,

		-- Passenger Zones are defined A - E, A=First, B=Business, C-D-E=Economy split in 3 zones
		passenger_zoneA_weight	= 0,  --defined via FMC passenger loading function
		passenger_zoneB_weight	= 0,  --defined via FMC passenger loading function
		passenger_zoneC_weight	= 0,  --defined via FMC passenger loading function
		passenger_zoneD_weight	= 0,  --defined via FMC passenger loading function
		passenger_zoneE_weight	= 0,  --defined via FMC passenger loading function
		
		--Payload/Cargo Zones
		fwd_lower_cargo_weight	= 0,  --defined via FMC cargo loading function
		aft_lower_cargo_weight	= 0,  --defined via FMC cargo loading function
		bulk_lower_cargo_weight	= 0,  --defined via FMC cargo loading function
		freight_zoneA_weight	= 0,  --defined via FMC cargo loading function
		freight_zoneB_weight	= 0,  --defined via FMC cargo loading function
		freight_zoneC_weight	= 0,  --defined via FMC cargo loading function
		freight_zoneD_weight	= 0,  --defined via FMC cargo loading function
		freight_zoneE_weight	= 0,  --defined via FMC cargo loading function
		
		--Moment Arm Distances (inches from reference point [aircraft nose] stored in feet in aircraft .acf file)
		OEW_distance				= 1243.32, --103.61 feet
		fuel_CTR_0_distance			= 1008.00, --84.00 feet
		fuel_L_main1_distance		= 1383.60, --115.30 feet
		fuel_L_main2_distance		= 1140.00, --95.00 feet
		fuel_R_main3_distance		= 1140.00, --95.00 feet
		fuel_R_main4_distance		= 1383.60, --115.30 feet
		fuel_L_rsv5_distance		= 1596.00, --133.00 feet
		fuel_R_rsv6_distance		= 1596.00, --133.00 feet
		fuel_stab7_distance			= 2412.00, --201.00 feet
		-- Passenger Zone moment arm distances are an approximation using the middle of the Zone as a reference
		passenger_zoneA_distance	= 285.00, --23.75 feet (23 First Class seats in the nose)
		passenger_zoneB_distance	= 735.00, --61.25 feet (80 Business Class seats behind First Class, including the Upper Deck Business Class seats)
		passenger_zoneC_distance	= 1060.00, --88.33 feet (77 Economy Class seats)
		passenger_zoneD_distance	= 1405.00, --117.08 feet (104 Economy Class seats)
		passenger_zoneE_distance	= 1950.00, --162.5 feet (132 Economy Class seats)
		
		--Payload/Cargo Zone moment arm distances are an approximation using the middle of the Zone as a reference
		fwd_lower_cargo_distance	= 650.00,  --54.16 feet (5 pallets [5035 KGS] or 16 LD1/LD3 [1588 KGS] containers or combination totalling 26,490 KGS).
		aft_lower_cargo_distance	= 1675.00,  --139.58 feet (4 pallets or 14 LD1/LD3 containers or combination totalling 22,938 KGS).
		bulk_lower_cargo_distance	= 1935.00,  --161.25 feet (6,749 KGS).  In the tail of the aircraft beneath the rear galley.
		freight_zoneA_distance		= 290.00,  --24.16 feet (3 pallets [3763 KGS] or equivalent totalling 11,289 KGS).
		freight_zoneB_distance		= 690.00,  --57.50 feet (8 pallets [3763 KGS] or equivalent totalling 30,104 KGS).
		freight_zoneC_distance		= 1135.00,  --94.58 feet (6 pallets [3763 KGS] or equivalent totalling 22,578 KGS).
		freight_zoneD_distance		= 1750.00,  --145.83 feet (12 pallets [3763 KGS] or equivalent totalling 45,156 KGS).
		freight_zoneE_distance		= 2220.00,  --185.00 feet (1 pallet [3763 KGS] or equivalent totalling 3763 KGS).

		--Calculated Results
		stab_trim = 0,
		cg_mac = 0,
}

--Calculate CG %MAC & Trim
function calc_stab_trim(GW, CG_MAC)
	local stab_trim = 0
	
	GW = GW * simConfigData["data"].SIM.kgs_to_lbs  --Formula uses LBS to calculate Stab TRIM.  GW passed in should always be in KGS.
	--print("GWin = "..GW.." MACin = "..CG_MAC)

	if GW > 1000 then
		GW = GW / 1000  --GW must be in 1000s of LBS
	end

	stab_trim = (0.000000717 * GW^2 - 0.001217 * GW + 0.24) * CG_MAC + (-0.0000309 * GW^2 + 0.05558 * GW - 12.24)  --GW must be in 1000s of LBS
	
	--Stab Trim can never be less than zero
	if stab_trim < 0 then
		stab_trim = 0
	end
	
	wb.stab_trim	= stab_trim
	fmsModules["data"].stab_trim 	= string.format("%4.1f", wb.stab_trim)
	B747DR_elevator_trim = fmsModules["data"].stab_trim  --Set STAB TRIM for green band calculation
	--print("Setting trim_mid = "..B747DR_elevator_trim)
	--print("Trim = "..fmsModules["data"].stab_trim)
end

function calc_CGMAC()

	local inch_to_meters	= 39.3700787
	
	--Setup initial weights
	wb.OEW_weight				= simDR_empty_weight
	wb.fuel_CTR_0_weight		= simDR_fuel_qty[0]
	wb.fuel_L_main1_weight		= simDR_fuel_qty[1]
	wb.fuel_L_main2_weight		= simDR_fuel_qty[2]
	wb.fuel_R_main3_weight		= simDR_fuel_qty[3]
	wb.fuel_R_main4_weight		= simDR_fuel_qty[4]
	wb.fuel_L_rsv5_weight		= simDR_fuel_qty[5]
	wb.fuel_R_rsv6_weight		= simDR_fuel_qty[6]
	wb.fuel_stab7_weight		= simDR_fuel_qty[7]

	--CG variables (in inches from reference point)
	local GW				= wb.OEW_weight + wb.fuel_CTR_0_weight + wb.fuel_L_main1_weight + wb.fuel_L_main2_weight + wb.fuel_R_main3_weight + wb.fuel_R_main4_weight
								+ wb.fuel_L_rsv5_weight + wb.fuel_R_rsv6_weight + wb.fuel_stab7_weight + wb.passenger_zoneA_weight + wb.passenger_zoneB_weight
								+ wb.passenger_zoneC_weight + wb.passenger_zoneD_weight + wb.passenger_zoneE_weight
								+ wb.fwd_lower_cargo_weight + wb.aft_lower_cargo_weight + wb.bulk_lower_cargo_weight
								+ wb.freight_zoneA_weight + wb.freight_zoneB_weight + wb.freight_zoneC_weight
								+ wb.freight_zoneD_weight + wb.freight_zoneE_weight
	local total_moment		= (wb.OEW_weight * wb.OEW_distance) + (wb.fuel_CTR_0_weight * wb.fuel_CTR_0_distance) + (wb.fuel_L_main1_weight * wb.fuel_L_main1_distance)
								+ (wb.fuel_L_main2_weight * wb.fuel_L_main2_distance) + (wb.fuel_R_main3_weight * wb.fuel_R_main3_distance)
								+ (wb.fuel_R_main4_weight * wb.fuel_R_main4_distance) + (wb.fuel_L_rsv5_weight * wb.fuel_L_rsv5_distance)
								+ (wb.fuel_R_rsv6_weight * wb.fuel_R_rsv6_distance) + (wb.fuel_stab7_weight * wb.fuel_stab7_distance)
								+ (wb.passenger_zoneA_weight * wb.passenger_zoneA_distance) + (wb.passenger_zoneB_weight * wb.passenger_zoneB_distance)
								+ (wb.passenger_zoneC_weight * wb.passenger_zoneC_distance) + (wb.passenger_zoneD_weight * wb.passenger_zoneD_distance)
								+ (wb.passenger_zoneE_weight * wb.passenger_zoneE_distance) + (wb.fwd_lower_cargo_weight * wb.fwd_lower_cargo_distance)
								+ (wb.aft_lower_cargo_weight * wb.aft_lower_cargo_distance) + (wb.bulk_lower_cargo_weight * wb.bulk_lower_cargo_distance)
								+ (wb.freight_zoneA_weight * wb.freight_zoneA_distance) + (wb.freight_zoneB_weight * wb.freight_zoneB_distance)
								+ (wb.freight_zoneC_weight * wb.freight_zoneC_distance) + (wb.freight_zoneD_weight * wb.freight_zoneD_distance)
								+ (wb.freight_zoneE_weight * wb.freight_zoneE_distance)
	local CG				= total_moment / GW
	local wing_root_chord	= 648.99996  --54.10 feet (from the aircraft .acf file)
	local wing_tip_chord	= 159.99996  --13.40 feet (from the aircraft .acf file)
	local wing_taper		= wing_tip_chord / wing_root_chord
	local MAC				= (2/3) * wing_root_chord * ((1 + wing_taper + wing_taper^2) / (1 + wing_taper))
	local LEMAC				= 1129.87932  --Approximately 94.18 feet as measured by where the default XP CG hits the 25% chord line at MAC and subtracting the 25% from the
										  --default CG reference point of 1243.32 inches (103.61 feet)
	local dist_default_CG	= 1243.32  --103.61 feet (from the aircraft .acf file)
	local dist_aft_LEMAC	= CG - LEMAC
	local CG_shift			= (dist_default_CG - CG) / inch_to_meters  --determine how far ahead or behind the OEW CG we are
	local CG_MAC			= (dist_aft_LEMAC / MAC) * 100
		
	wb.cg_mac 				= CG_MAC
	
	fmsModules["data"].cg_mac 		= string.format("%2.0f", wb.cg_mac)
	calc_stab_trim(GW, CG_MAC)

	simDR_cg_adjust = CG_shift * -1  --Value is flipped from what is in the XP slider
	
	--print("Dist = "..dist_default_CG.." - "..CG)
	--print("CG Shift = "..CG_shift)
	--print("OEW weight = "..wb.OEW_weight)
	--print("OEW distance = "..wb.OEW_distance)
	--print("Fuel = "..simDR_fuel_qty[0])
	--print("Fuel = "..wb.fuel_CTR_0_weight)
	--print("CG %MAC = "..wb.cg_mac)
	--print("Stab Trim = "..wb.stab_trim)
	--print("GW = "..GW)
end

function inflight_update_CG()

	local inch_to_meters	= 39.3700787
	
	--Setup initial weights
	wb.OEW_weight				= simDR_empty_weight
	wb.fuel_CTR_0_weight		= simDR_fuel_qty[0]
	wb.fuel_L_main1_weight		= simDR_fuel_qty[1]
	wb.fuel_L_main2_weight		= simDR_fuel_qty[2]
	wb.fuel_R_main3_weight		= simDR_fuel_qty[3]
	wb.fuel_R_main4_weight		= simDR_fuel_qty[4]
	wb.fuel_L_rsv5_weight		= simDR_fuel_qty[5]
	wb.fuel_R_rsv6_weight		= simDR_fuel_qty[6]
	wb.fuel_stab7_weight		= simDR_fuel_qty[7]

	--CG variables (in inches from reference point)
	local GW				= wb.OEW_weight + wb.fuel_CTR_0_weight + wb.fuel_L_main1_weight + wb.fuel_L_main2_weight + wb.fuel_R_main3_weight + wb.fuel_R_main4_weight
								+ wb.fuel_L_rsv5_weight + wb.fuel_R_rsv6_weight + wb.fuel_stab7_weight + wb.passenger_zoneA_weight + wb.passenger_zoneB_weight
								+ wb.passenger_zoneC_weight + wb.passenger_zoneD_weight + wb.passenger_zoneE_weight
								+ wb.fwd_lower_cargo_weight + wb.aft_lower_cargo_weight + wb.bulk_lower_cargo_weight
								+ wb.freight_zoneA_weight + wb.freight_zoneB_weight + wb.freight_zoneC_weight
								+ wb.freight_zoneD_weight + wb.freight_zoneE_weight
	local total_moment		= (wb.OEW_weight * wb.OEW_distance) + (wb.fuel_CTR_0_weight * wb.fuel_CTR_0_distance) + (wb.fuel_L_main1_weight * wb.fuel_L_main1_distance)
								+ (wb.fuel_L_main2_weight * wb.fuel_L_main2_distance) + (wb.fuel_R_main3_weight * wb.fuel_R_main3_distance)
								+ (wb.fuel_R_main4_weight * wb.fuel_R_main4_distance) + (wb.fuel_L_rsv5_weight * wb.fuel_L_rsv5_distance)
								+ (wb.fuel_R_rsv6_weight * wb.fuel_R_rsv6_distance) + (wb.fuel_stab7_weight * wb.fuel_stab7_distance)
								+ (wb.passenger_zoneA_weight * wb.passenger_zoneA_distance) + (wb.passenger_zoneB_weight * wb.passenger_zoneB_distance)
								+ (wb.passenger_zoneC_weight * wb.passenger_zoneC_distance) + (wb.passenger_zoneD_weight * wb.passenger_zoneD_distance)
								+ (wb.passenger_zoneE_weight * wb.passenger_zoneE_distance) + (wb.fwd_lower_cargo_weight * wb.fwd_lower_cargo_distance)
								+ (wb.aft_lower_cargo_weight * wb.aft_lower_cargo_distance) + (wb.bulk_lower_cargo_weight * wb.bulk_lower_cargo_distance)
								+ (wb.freight_zoneA_weight * wb.freight_zoneA_distance) + (wb.freight_zoneB_weight * wb.freight_zoneB_distance)
								+ (wb.freight_zoneC_weight * wb.freight_zoneC_distance) + (wb.freight_zoneD_weight * wb.freight_zoneD_distance)
								+ (wb.freight_zoneE_weight * wb.freight_zoneE_distance)

	local CG				= total_moment / GW
	local dist_default_CG	= 1243.32  --103.61 feet (from the aircraft .acf file)
	local cg_shift			= (dist_default_CG - CG) / inch_to_meters  --determine how far ahead or behind the OEW CG we are

	simDR_cg_adjust = cg_shift * -1  --Value is flipped from what is in the XP slider

	--print("Dist = "..dist_default_CG.." - "..CG)
	--print("CG Shift = "..cg_shift)
end
--Marauder28

fmsPages={}
--fmsPagesmall={}
fmsFunctionsDefs={}
fmsModules={} --set later

function defaultFMSData()
  return {
  acarsInitString="{}",
  fltno=string.rep("-", 8),
  fltdate="********",
  fltdep="****",
  fltdst="****",
  flttimehh="**",
  flttimemm="**",
  rpttimehh="**",
  rpttimemm="**",
  acarsAddress="*******",
  atc="****",
  grwt="***.*   ",
  crzalt=string.rep("*", 5),
  clbspd="250",
  transpd="272",
  spdtransalt="10000",
  transalt="18000",
  clbrestspd="180",
  maxkts="420",
  clbrestalt="5000 ",
  stepalt="FL360",
  crzspd="810",
  desspdmach="805",
  desspd="270",
  destranspd="250",
  desspdtransalt="10000",
  desrestspd="180",
  desrestalt="5000 ",
  fpa="*.*",
  vb="*.*",
  vs="****",
  fuel="***.*",
  zfw="***.*   ",
  reserves="***.*",
  costindex="****",
  crzcg="20.0",
  thrustsel="26",
  thrustn1="**.*",
  toflap="**",
  v1="***",
  vr="***",
  v2="***",
  runway=string.rep("-", 5),
  coroute=string.rep("-", 10),
  grosswt="***.*",
  vref1="***",
  vref2="***",
  irsLat=string.rep(" ", 9),
  irsLon=string.rep(" ", 9),
  initIRSLat="****`**.*",
  initIRSLon="****`**.*",
  flapspeed="**/***",
  airportpos=string.rep("-", 4),
  airportgate=string.rep(" ", 5),
  preselectLeft=string.rep("-", 6),
  preselectRight=string.rep("-", 6),
  codata = string.rep("-", 6),
  lastpos = string.rep(" ", 18),
  sethdg = string.rep(" ", 4),
  stepsize = "ICAO",
  cg_mac = string.rep("-", 2),
  stab_trim = string.rep(" ", 4),
  paxFirstClassA = string.rep("0", 2),
  paxBusClassB = string.rep("0", 2),
  paxEconClassC = string.rep("0", 2),
  paxEconClassD = string.rep("0", 3),
  paxEconClassE = string.rep("0", 3),
  paxTotal = string.rep("0", 3),
  paxWeightA = string.rep("0", 4),
  paxWeightB = string.rep("0", 5),
  paxWeightC = string.rep("0", 5),
  paxWeightD = string.rep("0", 5),
  paxWeightE = string.rep("0", 5),
  paxWeightTotal = string.rep("0", 6),
  cargoFwd = string.rep("0", 6),
  cargoAft = string.rep("0", 6),
  cargoBulk = string.rep("0", 5),
  cargoTotal = string.rep("0", 6),
  freightZoneA = string.rep("0", 6),
  freightZoneB = string.rep("0", 6),
  freightZoneC = string.rep("0", 6),
  freightZoneD = string.rep("0", 6),
  freightZoneE = string.rep("0", 6),
  freightTotal = string.rep("0", 7),
  --irsAlignTime = string.rep("0", 3),
}
end


fmsModules["data"]=defaultFMSData()
B747DR_FMSdata=json.encode(fmsModules["data"]["values"])--make the fms data available to other modules
fmsModules["setData"]=function(self,id,value)
    --always retain the same length
    if value=="" then 
      local initData=defaultFMSData()
      if initData[id]~=nil then
	print("default for " .. id .. " is " .. initData[id])
	value=initData[id]
      else
	print("default for " .. id .. " is nil")
	self["data"][id]=nil
	return
      end
    end
    len=string.len(self["data"][id])
    if len < string.len(value) then 
      value=string.sub(value,1,len)
    end
    --newVal=string.sub(value,1,len)
    self["data"][id]=string.format("%s%"..(len-string.len(value)).."s",value,"")
	B747DR_FMSdata=json.encode(fmsModules["data"]["values"])--make the fms data available to other modules
end
function setFMSData(id,value)
    --print("setting " .. id .. " to "..value.." curently "..fmsModules["data"][id])
  
   fmsModules:setData(id,value)
end  
function getFMSData(id)
  if hasChild(fmsModules["data"],id) then
    return fmsModules["data"][id]
  end
  return fmsModules["data"][id]
end 
fmsModules["lastcmd"]=" "
fmsModules["cmds"]={}
fmsModules["cmdstrings"]={}
function registerFMCCommand(commandID,dataString)
  fmsModules["cmds"][commandID]=find_command(commandID)
  fmsModules["cmdstrings"][commandID]=dataString
end

function switchCustomMode()
  fmsModules["fmsL"]["inCustomFMC"]=fmsModules["fmsL"]["targetCustomFMC"]
  fmsModules["fmsC"]["inCustomFMC"]=fmsModules["fmsC"]["targetCustomFMC"]
  fmsModules["fmsR"]["inCustomFMC"]=fmsModules["fmsR"]["targetCustomFMC"]
  fmsModules["fmsL"]["currentPage"]=fmsModules["fmsL"]["targetPage"]
  fmsModules["fmsC"]["currentPage"]=fmsModules["fmsC"]["targetPage"]
  fmsModules["fmsR"]["currentPage"]=fmsModules["fmsR"]["targetPage"]
  fmsModules["fmsL"]["pgNo"]=fmsModules["fmsL"]["targetpgNo"]
  fmsModules["fmsC"]["pgNo"]=fmsModules["fmsC"]["targetpgNo"]
  fmsModules["fmsR"]["pgNo"]=fmsModules["fmsR"]["targetpgNo"]
  --print("left cdu blanking")
end
function createPage(page)
  retVal={}
  retVal.name=page
  retVal.template={
  "    " .. page,
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        "
  }  
  retVal.templateSmall={
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        ",
  "                        "
  }
  retVal.getPage=function(self,pgNo) return self.template end
  retVal.getSmallPage=function(self,pgNo) return self.templateSmall end
  retVal.getNumPages=function(self) return 1 end
  fmsFunctionsDefs[page]={}
  return retVal
end
dofile("B744.notifications.lua")
dofile("irs/irs_system.lua")
dofile("B744.fms.pages.lua")

dofile("irs/rnav_system.lua")
dofile("B744.createfms.lua")

fmsC = {}
setmetatable(fmsC, {__index = fms})
fmsC.id="fmsC"
setDREFs(fmsC,"cdu1","fms1","sim/FMS/","fms3")
fmsC.inCustomFMC=true
fmsC.targetCustomFMC=true
fmsC.currentPage="INDEX"
fmsC.targetPage="INDEX"

fmsL = {}
setmetatable(fmsL, {__index = fms})
fmsL.id="fmsL"
setDREFs(fmsL,"cdu1","fms3","sim/FMS/","fms1")
fmsL.inCustomFMC=true
fmsL.targetCustomFMC=true
fmsL.currentPage="INDEX"
fmsL.targetPage="INDEX"

fmsR = {}
setmetatable(fmsR, {__index = fms})
fmsR.id="fmsR"
setDREFs(fmsR,"cdu2","fms2","sim/FMS2/","fms2")
fmsR.inCustomFMC=true
fmsR.targetCustomFMC=true
fmsR.currentPage="INDEX"
fmsR.targetPage="INDEX"

fmsModules.fmsL=fmsL;
fmsModules.fmsC=fmsC;
fmsModules.fmsR=fmsR;


B747DR_CAS_memo_status          = find_dataref("laminar/B747/CAS/memo_status")

--Marauder28
function getCurrentWayPoint(fms,usenext)

	for i=1,table.getn(fms),1 do
    --print("FMS j="..fmsJSON)

		if fms[i][10] == true then
				--print("Found TRUE = "..fms[i][1].." "..fms[i][2].." "..fms[i][8])
				if usenext==false then
				if fms[i][8] == "latlon" then
					return simDR_navID, fms[i][5], fms[i][6]
				else
					return fms[i][8], fms[i][5], fms[i][6]
				end
				elseif i+1<table.getn(fms) then
				  if fms[i+1][8] == "latlon" then
					return "------", fms[i+1][5], fms[i+1][6]
				else
					return fms[i+1][8], fms[i+1][5], fms[i+1][6]
				end
				end
		end		
	end
	return ""  --NOT FOUND
end
function get_waypoint_estimate(latitude,longitude,fms_waypoint, fms_latitude, fms_longitude,additionalTime)
  local meters_per_second_to_kts = 1.94384449
  local hours = 0
  local mins = 0
  local secs = 0
  local default_speed = 275
  local actual_speed = simDR_groundspeed * meters_per_second_to_kts
  local time_to_waypoint = 0
  local fms_distance_to_waypoint = 0
  if fms_waypoint ~= "" and fms_waypoint ~= "VECTOR" and not string.match(fms_waypoint, "%(") then
	--print("Checking distance for waypoint = "..fms_current_waypoint)
	fms_distance_to_waypoint = getDistance(latitude, longitude, fms_latitude, fms_longitude)
	
	time_to_waypoint = additionalTime + (fms_distance_to_waypoint / math.max(default_speed, actual_speed)) * 3600
	
	hours = math.floor((time_to_waypoint % 86400) / 3600)
	mins = math.floor((time_to_waypoint % 3600) / 60)
	secs = (time_to_waypoint % 60) / 60
	--Add to current Zulu time
	hours = hours + hh
	mins = mins + mm
	secs = secs + (ss / 60)
	
	if hours >= 24 then
		hours = hours - 24
	end
		
	if mins >= 60 then
		mins = mins - 60
		hours = hours + 1
	end
	
	if secs >= 1 then
		secs = secs - 1
		mins = mins + 1
	end
  end
  
  return fms_distance_to_waypoint,time_to_waypoint,hours,mins,secs
end
function waypoint_eta_display()
	local hours = 0
	local mins = 0
	local secs = 0
	local nhours = 0
	local nmins = 0
	local nsecs = 0
	local fms = {}
	local fms_current_waypoint = ""
	local fms_next_waypoint = ""
	local fms_latitude = ""
	local fms_longitude = ""
	local fms_next_latitude = ""
	local fms_next_longitude = ""
	local time_to_waypoint = 0
	local fms_distance_to_waypoint = 0
	local fms_distance_to_next_waypoint = 0
	if simDR_onGround ~= 1 and string.len(fmsJSON) > 2 then
		--print(fmsJSON)
		fms = json.decode(fmsJSON)	
		fms_current_waypoint, fms_latitude, fms_longitude = getCurrentWayPoint(fms,false)
		--print(string.match(fms_current_waypoint, "%("))
		fms_distance_to_waypoint,time_to_waypoint,hours,mins,secs = get_waypoint_estimate(simDR_latitude, simDR_longitude,fms_current_waypoint, fms_latitude, fms_longitude,0)
		
		fms_next_waypoint, fms_next_latitude, fms_next_longitude = getCurrentWayPoint(fms,true)
		--print(string.match(fms_current_waypoint, "%("))
		fms_distance_to_next_waypoint,time_to_waypoint,nhours,nmins,nsecs = get_waypoint_estimate(fms_latitude, fms_longitude,fms_next_waypoint, fms_next_latitude, fms_next_longitude,time_to_waypoint)
		
	end
	
	if fms_current_waypoint == "" or string.match(fms_current_waypoint, "%(") then
		B747DR_ND_current_waypoint = "-----"
		B747DR_ND_waypoint_distance = "------NM"
		B747DR_ND_waypoint_eta = "------Z"	
	elseif fms_current_waypoint == "VECTOR" then
		B747DR_ND_current_waypoint = fms_current_waypoint
		B747DR_ND_waypoint_distance = "------NM"
		B747DR_ND_waypoint_eta = "------Z"
	else
	        if B747DR_ND_current_waypoint ~= fms_current_waypoint then
		  B747DR_waypoint_ata = B747DR_ND_waypoint_eta
		  B747DR_last_waypoint = B747DR_ND_current_waypoint
		end
		B747DR_ND_current_waypoint = fms_current_waypoint
		B747DR_ND_waypoint_distance = string.format("%5.1f".."nm", fms_distance_to_waypoint)
		B747DR_ND_waypoint_eta = string.format("%02d%02d.%d".."z", hours, mins, secs * 10)			
	end
	if B747DR_last_waypoint=="" then
	  B747DR_last_waypoint="-----"
	  B747DR_waypoint_ata="------Z"
	end
	if fms_next_waypoint == "" or string.match(fms_next_waypoint, "%(") then
		B747DR_next_waypoint = "------"
		B747DR_next_waypoint_eta = "------Z"	
	elseif fms_next_waypoint == "VECTOR" then
		B747DR_next_waypoint = fms_next_waypoint
		B747DR_next_waypoint_eta = "------Z"
	else
		B747DR_next_waypoint = fms_next_waypoint
		B747DR_next_waypoint_eta = string.format("%02d%02d.%d".."z", nhours, nmins, nsecs * 10)			
	end
end

function nd_range_display ()
	local range = {5, 10, 20, 40, 80, 160, 320}
			
	B747DR_ND_range_display_capt	= range[simDR_range_dial_capt + 1]
	B747DR_ND_range_display_fo		= range[simDR_range_dial_fo + 1]
end



function nd_speed_wind_display()
	local meters_per_second_to_kts = 1.94384449  --Convert meters per second to KTS
	local a0 = 661.47  --Speed of sound at sea level
	local K0 = 273.15  --Kelvin temperature at sea level
	local M_pilot = simDR_mach_pilot  --Current Mach number
	local M_copilot = simDR_mach_copilot  --Current Mach number
	local T0 = 288.15  --Standard air temperature at sea level in Kelvin
	local Tt = K0 + simDR_total_air_temp  --Total air temperature in Kelvin
	local T_pilot = Tt / (1 + (0.2 * math.pow(M_pilot, 2)))  --Static air temperature in Kelvin	
	local T_copilot = Tt / (1 + (0.2 * math.pow(M_copilot, 2)))  --Static air temperature in Kelvin	
	local TAS_pilot = round(a0 * M_pilot * math.sqrt(T_pilot/T0))
	local TAS_copilot = round(a0 * M_copilot * math.sqrt(T_copilot/T0))
	
	local groundspeed = simDR_groundspeed * meters_per_second_to_kts
	local wind_hdg = round(simDR_wind_degrees)
	local wind_hdg_deviation = 360 - wind_hdg + simDR_aircraft_hdg
	local wind_bearing = 360 - wind_hdg_deviation
	local wind_spd = tostring(round(simDR_wind_speed))
	local wind_line_tmp = string.format("%03.0f`/%s", wind_hdg, wind_spd)
	
	if simDR_ias_pilot < 100 then
		B747DR_ND_GS_TAS_Line = "GS"
		B747DR_ND_GS_TAS_Line_Pilot = string.format("%d", groundspeed)
		B747DR_ND_GS_TAS_Line_CoPilot = string.format("%d", groundspeed)
		B747DR_ND_Wind_Line = ""
	else
		B747DR_ND_GS_TAS_Line = "GS     TAS"
		B747DR_ND_GS_TAS_Line_Pilot = string.format("%3.0f    %3.0f", groundspeed, TAS_pilot)
		B747DR_ND_GS_TAS_Line_CoPilot = string.format("%3.0f    %3.0f", groundspeed, TAS_copilot)
		B747DR_ND_Wind_Line = wind_line_tmp:gsub("°", "`")
		if wind_bearing < 0 then
			B747DR_ND_Wind_Bearing = wind_bearing + 180
		else
			B747DR_ND_Wind_Bearing = wind_bearing - 180
		end
	end
end

function aircraft_last_pos(phase)
	file_location = simDR_livery_path.."B747-400_lastpos.dat"
	--print("File = "..file_location)

	if phase == "LOAD" then
		--Load FMC last position
		local file = io.open(file_location, "r")
		if file ~= nil then
			io.input(file)
			fmsModules["data"].lastpos = io.read()
			io.close(file)
		end
	else  --UNLOAD
		local file = io.open(file_location, "w+")
		if file ~= nil then
			io.output(file)
			io.write(irsSystem.getLat("gpsL") .." " .. irsSystem.getLon("gpsL"))
			io.close(file)
		end
	end
end
--Marauder28

function flight_start()
  if simDR_startup_running == 0 then
    irsSystem["irsL"]["aligned"]=false
    irsSystem["irsC"]["aligned"]=false
    irsSystem["irsR"]["aligned"]=false
    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then
      irsSystem["setPos"]=true
      irsSystem.align("irsL",true)
  
      irsSystem.align("irsC",true)
  
      irsSystem.align("irsR",true)
      
    end

	simDR_cg_adjust = 0  --reset CG slider to begin current flight
	
	--Ensure that CG location gets updated periodically so that the CG slider repositions automatically as fuel is burned during flight
	run_at_interval(inflight_update_CG, 60)	
end

debug_fms     = deferred_dataref("laminar/B747/debug/fms", "number")
fms_style = find_dataref("sim/cockpit2/radios/indicators/fms_cdu1_style_line2")
lastNotify=0
function setNotifications()
  local diff=simDRTime-lastNotify
  if diff<10 then return end
  --print("FMS notify")
  lastNotify=simDRTime
  for i =1,53,1 do
    --print("do FMS notify".." ".. i .." " ..B747DR_fmc_notifications[i])
    if B747DR_fmc_notifications[i]>0 then
      fmsModules["fmsL"]["notify"]=B747_FMCAlertMsg[i].name
      fmsModules["fmsC"]["notify"]=B747_FMCAlertMsg[i].name
      fmsModules["fmsR"]["notify"]=B747_FMCAlertMsg[i].name
      print("do FMS notify "..B747_FMCAlertMsg[i].name)
      break
    else
      if fmsModules["fmsL"]["notify"]==B747_FMCAlertMsg[i].name then fmsModules["fmsL"]["notify"]="" end
      if fmsModules["fmsC"]["notify"]==B747_FMCAlertMsg[i].name then fmsModules["fmsC"]["notify"]="" end
      if fmsModules["fmsR"]["notify"]==B747_FMCAlertMsg[i].name then fmsModules["fmsR"]["notify"]="" end
    end
  end

end
function after_physics()
  if debug_fms>0 then return end
--     for i =1,24,1 do
--       print(string.byte(fms_style,i))
--     end
	--refresh time
	local cM=hh
	cM=mm
	cM=ss
    setNotifications()
    B747DR_FMSdata=json.encode(fmsModules["data"]["values"])--make the fms data available to other modules
    --print(B747DR_FMSdata)
    fmsL:B747_fms_display()
    fmsC:B747_fms_display()
    fmsR:B747_fms_display()
    if simDR_bus_volts[0]>24 then
      irsSystem.update()
      B747_setNAVRAD()
    end
    if acarsSystem.provider.online() then
      B747DR_CAS_memo_status[40]=0 --for CAS
      acars=1 --for radio
      acarsSystem.provider.receive()
      local hasNew=0
      for i = table.getn(acarsSystem.messages.values), 1, -1 do
		if not acarsSystem.messages[i]["read"] then 
			hasNew=1
		end 
      end 
      B747DR_CAS_memo_status[0]=hasNew
    else
      
      if B747DR_rtp_C_off==0 then
		B747DR_CAS_memo_status[40]=1 --for CAS
      else
		B747DR_CAS_memo_status[40]=0
      end
      acars=0 --for radio
    end

	--Display Waypoint ETA on ND
	waypoint_eta_display()

	--Display range NM on ND
	nd_range_display ()
	
	--Display speed and wind info on ND
	nd_speed_wind_display()

	--Ensure simConfig data is fresh
	simConfigData["data"] = json.decode(B747DR_simconfig_data)
		
	--Ensure DR's are updated in time for use in calc_CGMAC()
	local payload_weight = B747DR_payload_weight
	local fuel_qty = simDR_fuel_qty
	local simconfig = B747DR_simconfig_data
		
end

function aircraft_load()
	simDR_cg_adjust = 0 --reset CG slider to begin current flight
end

function aircraft_unload()
	aircraft_last_pos("UNLOAD")
	simDR_cg_adjust = 0 --reset CG slider to neutral for future flights
end