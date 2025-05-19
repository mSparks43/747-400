--[[
****************************************************************************************
* Program Script Name	:	B747.42.xt.EEC.GE.lua
* Author Name			:	Marauder28
*                   (with SIGNIFICANT contributions from @kudosi for aeronautic formulas)
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2021-01-11	0.01a				      Start of Dev
*	  2021-05-27	0.1					      Initial Release
*   2021-06-16  0.2               Added Engine Idle Control
*	  2021-12-11	0.3				        New Throttle Resolver Angle formula, various bug fixes
*
*****************************************************************************************
]]

--This function calculates the target position of the throttle target on the Upper EICAS
function throttle_resolver_angle_GE(engine_in)
  local throttle_angle = 0.0
  local thrust_ratio_factor = 1.0

  thrust_ratio_factor = B747DR_display_N1_max[engine_in] / 116.0  --117.5

  local N1_target=B747_rescale(0.0, 25.0, 1.0, 116.0, B747DR_throttle[engine_in])
  if B747DR_log_level == -1 then
    print("Thrust Factor = ", thrust_ratio_factor)
    print("TRA = ", throttle_angle)
    print("N1_target = ", N1_target)
  end
  return N1_target
end

function engine_idle_control_GE(altitude_ft_in)
  local N1_low_idle = 25.9
  local N1_high_idle_ratio = 2.625  --target ~42% N1 at SL / 15c

  --Information from FCOM
    --Chapter 7 - Engines, APU
    --Section 20 - Engine System Description
    --Sub-Section - Electronic Engine Control (EEC) / EEC Idle Selection

  --N1 Idle Display (Currently only high idle is implemented for use in the 747 in XP so manipulate the high idle dataref for low idle)

  --------------------
  --MINIMUM (LOW) Idle
  --------------------
  --When on ground and flaps not in landing configuration, low idle fluctuates based on temperature
  if simDR_onGround == 1 then
    if simDR_temperature < 15.0 then
      simDR_engine_high_idle_ratio = B747_rescale(-75.0, 1.04, 14.99, 1.249, simDR_temperature)
    else
      simDR_engine_high_idle_ratio = B747_rescale(15.0, 1.25, 75.0, 1.49, simDR_temperature)
    end
  end

  --Calc in-flight LOW Idle
  if simDR_onGround == 0 then
    --N1_low_idle = -1.03E-08 * altitude_ft_in^2 + 8.85E-04 * altitude_ft_in + 2.52E+01
    N1_low_idle = -1.45E-08 * altitude_ft_in^2 + 0.00121 * altitude_ft_in + 25.9
  end

  ----------------------
  --APPROACH (HIGH) Idle
  ----------------------
  --Conditions:
    --Landing Flaps Selected (25 or 30)
    --CON-tinuous Ignition Selected
    --Engine Anti-Ice Selected
    --Reversers deployed

  if (simDR_onGround == 0 and simDR_flap_ratio > 0.667)
    or (simDR_onGround == 0 and B747DR_button_switch_position[44] == 1)  --CONTinuous Ignition
    or (simDR_onGround == 0 and math.max(B747DR_nacelle_ai_valve_pos[0], B747DR_nacelle_ai_valve_pos[1], B747DR_nacelle_ai_valve_pos[2], B747DR_nacelle_ai_valve_pos[3]) == 1)  --Engine A/I
    or (simDR_onGround == 1 and math.max(simDR_reverser_on[0], simDR_reverser_on[1], simDR_reverser_on[2], simDR_reverser_on[3]) == 1) then  --Reversers deployed
      simDR_engine_high_idle_ratio = N1_high_idle_ratio
      
      --Reset to LOW Idle 5 seconds after touchdown (TBD)
  end
  
  if B747DR_log_level >= 1 then
    print("XP High Idle Ratio = ", simDR_engine_high_idle_ratio)
    print("N1 Low Idle - Flight = ", N1_low_idle)
  end

  return N1_low_idle
end



--[[function take_off_thrust_assumed(altitude_ft_in, temperature_K_in)
  local TOGA_corrected_thrust_lbf = 0.0
  local TOGA_actual_thrust_lbf = 0.0
  local TOGA_actual_thrust_N = 0.0
  local approximate_max_TO_thrust_lbf = 0
  local temperature_K = 0.0

  temperature_K = fmsModules["data"]["thrustsel"] + 274.15

  if temperature_K_in > corner_temperature_K then
      TOGA_corrected_thrust_lbf = (-1.79545 * (temperature_K / corner_temperature_K) + 2.7874) * (-0.0000546 * altitude_ft_in^2 + 1.37 * altitude_ft_in + approximate_max_TO_thrust_lbf)
  else
      TOGA_corrected_thrust_lbf = (-0.0000546 * altitude_ft_in^2 + 1.37 * altitude_ft_in + approximate_max_TO_thrust_lbf)
  end

  TOGA_actual_thrust_lbf = TOGA_corrected_thrust_lbf * pressure_ratio
  TOGA_actual_thrust_N = TOGA_actual_thrust_lbf * lbf_to_N

  if B747DR_log_level >= 1 then
    print("\t\t\t\t\t<<<--- Assumed Temp Takeoff Calcs --->>>")
    print("Altitude IN = ", altitude_ft_in)
    print("Temperature K IN = ", temperature_K_in)
    print("Approximate Takeoff Thrust Required = ", approximate_max_TO_thrust_lbf)
    print("TOGA Corrected LBF = ", TOGA_corrected_thrust_lbf)
    print("TOGA Actual LBF = ", TOGA_actual_thrust_lbf)
    print("TOGA Actual N = ", TOGA_actual_thrust_N)
  end

  return TOGA_corrected_thrust_lbf  --, TOGA_actual_thrust_lbf, TOGA_actual_thrust_N
end]]

function take_off_N1_GE(altitude_ft_in)
  local N1_corrected = 0.0
  local N1_actual = 0.0
  local temperature_K = 0.0
  local temperature_ratio = 0.0

  --locals to hold returned values from take_off_thrust_corrected() function
  local TOGA_corrected_thrust_lbf = 0.0
  local TOGA_actual_thrust_N = 0.0

  --For Takeoff, use actual Sim temperature instead of atmosphere() temperature_K
  --If a derate temperature is entered in the THRUST LIM page of the FMC, use that instead
  --if fmsModules["data"]["thrustsel"] ~= "  " then
  --  temperature_K = tonumber(fmsModules["data"]["thrustsel"]) + 273.15
  --else
    temperature_K = simDR_temperature + 273.15
  --end

  temperature_ratio = temperature_K / 288.15

  --get take_off_thrust_corrected() data
  TOGA_corrected_thrust_lbf, _, TOGA_actual_thrust_N = take_off_thrust_corrected(altitude_ft_in, temperature_K)

  --Mach should always be 0 for purposes of this calculation
  mach = 0.0

  N1_corrected = (-1.4446E-12 * mach^2 + 1.2102E-12 * mach + 4.8911E-13) * TOGA_corrected_thrust_lbf^3 + (1.1197E-07 * mach^2 - 7.8717E-08 * mach - 6.498200000000002E-08)
                  * TOGA_corrected_thrust_lbf^2 + (-0.0027 * mach^2 + 0.0011 * mach + 0.0036) * TOGA_corrected_thrust_lbf + (36.93 * mach + 20.96)

  N1_actual = string.format("%4.1f", N1_corrected * math.sqrt(temperature_ratio))

  if B747DR_log_level >= 1 then
    print("\t\t\t\t\t<<<--- TAKEOFF N1 (GE) --->>>")
    print("Altitude IN = ", altitude_ft_in)
    print("Temperature K = ", temperature_K)
    print("Temperature Ratio = ", temperature_ratio)
    print("Mach = ", mach)
    print("TOGA Corrected Thrust = ", TOGA_corrected_thrust_lbf)
    print("N1 Corrected = ", N1_corrected)
    print("N1 Actual = ", N1_actual)
  end

  return N1_actual, TOGA_actual_thrust_N
end

function in_flight_N1_GE(altitude_ft_in, delta_t_isa_K_in)
    local N1_corrected = 0.0
    local N1_actual = 0.0
    local N1_corrected_raw_max_climb = 0.0
    local N1_corrected_mod_max_climb = 0.0
    local N1_real_max_climb = 0.0
    local N1_corrected_raw_max_cruise = 0.0
    local N1_corrected_mod_max_cruise = 0.0
    local N1_real_max_cruise = 0.0
    local climb_rate_fpm = 0
    local climb_angle_deg = 0.0

    local thrust_per_engine_N = 0.0
    local corrected_thrust_lbf = 0.0

    --Due to modeling differences / deficiencies, the climb rates below are tweaked (higher) to
    --allow for more closely matched real-world performance.  Ideal generic target climb rates are:
    --  >> 0 - 10000 ft = 2200fpm
    --  >> 10000 - 20000ft = 2100fpm
    --  >> 20000 - 30000ft = 1700fpm
    if string.match(simConfigData["data"].PLANE.engines, "B1F") then
      if simDR_altitude < 10000 then
        climb_rate_fpm = 2750
      elseif simDR_altitude <= 20000 then
        --climb_rate_fpm = 2750
        climb_rate_fpm = B747_rescale(10000.0, 2750.0, 20000.0, 2500.0, simDR_altitude)
      elseif simDR_altitude <= 30000 then
        --climb_rate_fpm = 2500
        climb_rate_fpm = B747_rescale(20000.0, 2500.0, 30000.0, 2250.0, simDR_altitude)
      elseif simDR_altitude <= 50000 then
        --climb_rate_fpm = 2000
        climb_rate_fpm = B747_rescale(30000.0, 2250.0, 50000.0, 2250.0, simDR_altitude)
      elseif simDR_altitude > 50000 then
        climb_rate_fpm = 2250
      end
    elseif string.match(simConfigData["data"].PLANE.engines, "B1F1") then
      --For now, use the same climb rates as the B1F until we have specific information for B5F and others
      if simDR_altitude < 10000 then
        climb_rate_fpm = 2875
      elseif simDR_altitude <= 20000 then
        --climb_rate_fpm = 2750
        climb_rate_fpm = B747_rescale(10000.0, 2875.0, 20000.0, 2625.0, simDR_altitude)
      elseif simDR_altitude <= 30000 then
        --climb_rate_fpm = 2500
        climb_rate_fpm = B747_rescale(20000.0, 2625.0, 30000.0, 2375.0, simDR_altitude)
      elseif simDR_altitude <= 50000 then
        --climb_rate_fpm = 2000
        climb_rate_fpm = B747_rescale(30000.0, 2375.0, 50000.0, 2375.0, simDR_altitude)
      elseif simDR_altitude > 50000 then
        climb_rate_fpm = 2375
      end
    elseif string.match(simConfigData["data"].PLANE.engines, "B5F") then
      --For now, use the same climb rates as the B1F until we have specific information for B5F and others
      if simDR_altitude < 10000 then
        climb_rate_fpm = 3000
      elseif simDR_altitude <= 20000 then
        --climb_rate_fpm = 2750
        climb_rate_fpm = B747_rescale(10000.0, 3000.0, 20000.0, 2750.0, simDR_altitude)
      elseif simDR_altitude <= 30000 then
        --climb_rate_fpm = 2500
        climb_rate_fpm = B747_rescale(20000.0, 2750.0, 30000.0, 2500.0, simDR_altitude)
      elseif simDR_altitude <= 50000 then
        --climb_rate_fpm = 2000
        climb_rate_fpm = B747_rescale(30000.0, 2500.0, 50000.0, 2500.0, simDR_altitude)
      elseif simDR_altitude > 50000 then
        climb_rate_fpm = 2250
      end
    else --failsafe option / assume B1F
      if simDR_altitude < 10000 then
        climb_rate_fpm = 2750
      elseif simDR_altitude <= 20000 then
        --climb_rate_fpm = 2750
        climb_rate_fpm = B747_rescale(10000.0, 2750.0, 20000.0, 2500.0, simDR_altitude)
      elseif simDR_altitude <= 30000 then
        --climb_rate_fpm = 2500
        climb_rate_fpm = B747_rescale(20000.0, 2500.0, 30000.0, 2250.0, simDR_altitude)
      elseif simDR_altitude <= 50000 then
        --climb_rate_fpm = 2000
        climb_rate_fpm = B747_rescale(30000.0, 2250.0, 50000.0, 2250.0, simDR_altitude)
      elseif simDR_altitude > 50000 then
        climb_rate_fpm = 2250
      end
  end

    if fmc_alt >= (altitude_ft_in - 200) and B747DR_ref_thr_limit_mode == "CRZ" then
      climb_rate_fpm = 0
    end

    climb_angle_deg = math.asin((0.00508 * climb_rate_fpm) / tas_mtrs_sec) * 180 / math.pi

    --get in_flight_thrust() data
    _, thrust_per_engine_N, _, corrected_thrust_lbf = in_flight_thrust(simDR_acf_weight_total_kg, climb_angle_deg)

    N1_corrected = (-1.4446E-12 * mach^2 + 1.2102E-12 * mach + 4.8911E-13) * corrected_thrust_lbf^3 + (1.1197E-07 * mach^2 - 7.8717E-08 * mach -6.498200000000001E-08)
                    * corrected_thrust_lbf^2 + (-0.0027 * mach^2 + 0.0011 * mach + 0.0036) * corrected_thrust_lbf + (36.93 * mach + 20.96)

    N1_actual = N1_corrected * math.sqrt(temperature_ratio)

    if delta_t_isa_K_in > 0 then
        if delta_t_isa_K_in > 10 then
            N1_corrected_raw_max_climb = -0.25 * delta_t_isa_K_in + 95.8 + (-5.8239E-09 * altitude_ft_in^2 + 0.00077693 * altitude_ft_in)
            N1_corrected_raw_max_cruise = -0.255 * delta_t_isa_K_in + 96 + (-7.5969E-09 * altitude_ft_in^2 + 0.00075761 * altitude_ft_in)
        else
            N1_corrected_raw_max_climb = -0.04 * delta_t_isa_K_in + 96 + (-5.8239E-09 * altitude_ft_in^2 + 0.00077693 * altitude_ft_in)
        end
    else
      N1_corrected_raw_max_climb = 96 + (-5.8239E-09 * altitude_ft_in^2 + 0.00077693 * altitude_ft_in)
      N1_corrected_raw_max_cruise = 93.5 + (-7.5969E-09 * altitude_ft_in^2 + 0.00075761 * altitude_ft_in)
    end
    
    if altitude_ft_in > 24000 then
      N1_corrected_mod_max_climb = N1_corrected_raw_max_climb -3.5722E-08 * altitude_ft_in^2 + 0.002463 * altitude_ft_in - 38.585
      N1_corrected_mod_max_cruise = N1_corrected_raw_max_cruise -3.5722E-08 * altitude_ft_in^2 + 0.002463 * altitude_ft_in - 38.585
    else
      N1_corrected_mod_max_climb = N1_corrected_raw_max_climb
      N1_corrected_mod_max_cruise = N1_corrected_raw_max_cruise
    end
  
    N1_real_max_climb = math.min(N1_corrected_mod_max_climb * math.sqrt(temperature_ratio_adapted), 117.5)
    N1_real_max_cruise = math.min(N1_corrected_mod_max_cruise * math.sqrt(temperature_ratio_adapted), 117.5)
    if N1_actual<89 then
      N1_actual=89
    end
    if B747DR_log_level >= 1 then
      print("\t\t\t\t\t<<<--- IN FLIGHT N1 (GE) --->>>")
      print("Altitude IN = ", altitude_ft_in)
      print("Delta T ISA IN = ", delta_t_isa_K_in)
      print("Temperature Ratio = ", temperature_ratio)
      print("Temperature Ratio Adapted = ", temperature_ratio_adapted)
      print("Mach = ", mach)
      print("Req'd Thrust per Engine N = ", thrust_per_engine_N)
      print("Corrected Thrust LBF = ", corrected_thrust_lbf)
      print("Climb Rate FPM = ", climb_rate_fpm)
      print("Climb Angle = ", climb_angle_deg)
      print("N1 Corrected Raw MAX Climb = ", N1_corrected_raw_max_climb)
      print("N1 Corrected MOD MAX Climb = ", N1_corrected_mod_max_climb)
      print("N1 Real MAX Climb = ", N1_real_max_climb)
      print("N1 Corrected Raw MAX Cruise = ", N1_corrected_raw_max_cruise)
      print("N1 Corrected MOD MAX Cruise = ", N1_corrected_mod_max_cruise)
      print("N1 Real MAX Cruise = ", N1_real_max_cruise)
      print("N1 Corrected = ", N1_corrected)
      print("N1 Actual = ", N1_actual)
    end

    return N1_corrected, N1_actual, N1_corrected_raw_max_climb, N1_corrected_mod_max_climb, N1_real_max_climb, N1_corrected_raw_max_cruise, N1_corrected_mod_max_cruise, N1_real_max_cruise
end

local last_thrust_n = {0.0, 0.0, 0.0, 0.0}
local last_N1 = {0.0, 0.0, 0.0, 0.0}
function N1_display_GE(altitude_ft_in, thrust_N_in, n1_factor_in, engine_in)
    local N1_corrected = 0.0
    local N1_actual = 0.0
    local corrected_thrust_N = 0.0
    local corrected_thrust_lbf = 0.0
    local actual_thrust_lbf = 0.0
    local N1_low_idle = 0.0
    if last_N1[engine_in] == nil then last_N1[engine_in] = 0.0 end
    if last_thrust_n[engine_in] == nil then
      last_thrust_n[engine_in] = 0.0
    end

    --Handle display of an engine shutdown
    --[[if simDR_engine_running[engine_in] == 0 then
      thrust_N_in = last_thrust_n[engine_in]
      n1_factor_in = 1.0
      if last_thrust_n[engine_in] > 0 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] - 100
      elseif last_thrust_n[engine_in] < 0 then
        last_thrust_n[engine_in] = 0.0
      end
    else
      last_thrust_n[engine_in] = thrust_N_in
    end]]
    last_thrust_n[engine_in] = thrust_N_in
    if thrust_N_in < 0.0 then
      thrust_N_in = 0.0
    end

    if n1_factor_in == 0 or n1_factor_in == nil then
      --Failsafe incase n1_factor_in is 0 or nil
      n1_factor_in = 105.0
      takeoff_TOGA_n1 = n1_factor_in
    end

    corrected_thrust_N = thrust_N_in / pressure_ratio
    corrected_thrust_lbf = corrected_thrust_N / lbf_to_N
    
    actual_thrust_lbf = corrected_thrust_lbf * pressure_ratio

    N1_corrected = (-1.4446E-12 * mach^2 + 1.2102E-12 * mach + 4.8911E-13) * corrected_thrust_lbf^3 + (1.1197E-07 * mach^2 - 7.8717E-08 * mach - 6.498200000000002E-08)
    * corrected_thrust_lbf^2 + (-0.0027 * mach^2 + 0.0011 * mach + 0.0036) * corrected_thrust_lbf + (36.93 * mach + 20.96)

    N1_actual = N1_corrected * math.sqrt(temperature_ratio)

    --Keep the N1 display steady during TO until we manage thrust or 2000 AGL unmanaged
    if (string.match(B747DR_ref_thr_limit_mode, "TO") or (simDR_onGround == 1 and B747DR_ref_thr_limit_mode == "GA"))
      or ((B747DR_ref_thr_limit_mode == "NONE" or B747DR_ref_thr_limit_mode == "") and B747DR_radio_altitude < 2000) then
        N1_actual = simDR_N1[engine_in] * n1_factor_in
    end

    --Engine Idle Logic (Minimum / Approach)
    N1_low_idle = engine_idle_control_GE(altitude_ft_in)
    if B747DR_throttle_resolver_angle[engine_in] < tonumber(N1_low_idle) and simDR_engine_running[engine_in] == 1 then
     -- N1_actual = N1_low_idle
      N1_actual = B747_animate_value(last_N1[engine_in],N1_low_idle,0,115,0.1) 
      --print(" pin N1_actual 2 "..N1_actual)
    elseif simDR_engine_running[engine_in] == 0 then
      N1_actual = B747_animate_value(last_N1[engine_in],simDR_N1[engine_in],0,115,0.1) 
      --print(" pin N1_actual 1 "..N1_actual.. " n1 "..simDR_N1[engine_in])
    end

    if B747DR_log_level >= 1 then
      print("\t\t\t\t\t<<<--- N1 DISPLAY (GE) --->>>".."\t\tEngine # "..engine_in + 1)
      print("Altitude IN = ", altitude_ft_in)
      print("Thrust IN = ", thrust_N_in)
      print("Pressure Ratio = ", pressure_ratio)
      print("Temperature K = ", temperature_K)
      print("Temperature Ratio = ", temperature_ratio)
      print("Mach = ", mach)
      print("N1_low_idle = ", N1_low_idle)
      print("Corrected Thrust LBF = ", corrected_thrust_lbf)
      print("Actual Thrust LBF = ", actual_thrust_lbf)
      print("TO Factor = ", n1_factor_in)
      print("N1 Actual = ", N1_actual)
      print("Last Thrust In = ", last_thrust_n[engine_in])
    end
    last_N1[engine_in] = N1_actual
    return N1_actual
end
local last_N2 = {0.0, 0.0, 0.0, 0.0}
function N2_display_GE(engine_N1_in, engine_in)
  local N2_display = 0.0

  --N2_display = (3.47E-04 * engine_N1_in^2 - 8.24E-02 * engine_N1_in + 7.71) * engine_N1_in * (3280 / 9827)  --have to multiply by the 100% rotation speed of N1 / 100% rotation speed of N2
  N2_display = (7.85E-04 * engine_N1_in^2 - 0.162 * engine_N1_in + 11.1) * engine_N1_in * (3280 / 9827)  --have to multiply by the 100% rotation speed of N1 / 100% rotation speed of N2

  --[[--When the XP N2 dataref drops below 35.0, use that instead of the N2 formula due to scaling inefficiencies with N1 as an input
  if simDR_N2[engine_in] < 35.0  then
    N2_display = simDR_N2[engine_in]
  elseif N2_display < 48.0 then
    N2_display = B747_rescale(35.0, 35.0, 65.0, 48.0, simDR_N2[engine_in])
  end]]--
  if last_N2[engine_in] == nil then last_N2[engine_in] = 0.0 end
    if (simDR_engine_running[engine_in] == 0 or simDR_N2[engine_in]<35) then
      N2_display = B747_animate_value(last_N2[engine_in],simDR_N2[engine_in],0,115,0.1) 
    elseif N2_display < simDR_N2[engine_in] then --and N2_display < 30.0 then
      N2_display = B747_animate_value(last_N2[engine_in],simDR_N2[engine_in],0,115,0.1)
    else
      N2_display = B747_animate_value(last_N2[engine_in],N2_display,0,115,10)
    end
  if B747DR_log_level >= 1 then
    print("N1 in, N2, test = ", engine_N1_in, N2_display)
  end
  last_N2[engine_in] = N2_display
  return N2_display
end

function EGT_display_GE(engine_in)
  local EGT_display = 0.0

  --Use a scaled approach from the default XP (PW) EGT calcs to computing EGT.
  if simDR_engn_EGT_c[engine_in] <= simDR_temperature then
    EGT_display = simDR_temperature
  elseif simDR_engn_EGT_c[engine_in] < 375 then
    EGT_display = simDR_engn_EGT_c[engine_in]
  else
    EGT_display = B747_rescale(0.0, 0.0, 985.0, 985.0, simDR_engn_EGT_c[engine_in])
  end

  if B747DR_log_level >= 1 then
    print("EGT = ", EGT_display)
  end

  return EGT_display
end

local takeoff_TOGA_n1 = 0.0
local orig_thrust_n = 0.0
local N1_target_bug={}
local display_N1_ref={}
local display_N1_max={}
function GE(altitude_ft_in)
	local altitude = 0.0  --round_thrustcalc(simDR_altitude, "ALT")
	local temperature = 0
	local nbr_packs_on = 0
	local packs_adjustment_value = 0.0
	local engine_anti_ice_adjustment_value = 0.0
	local wing_anti_ice_adjustment_value = 0.0
	local takeoff_thrust_n1 = 0.0  --100.0
	local takeoff_thrust_n1_throttle = 0.00
  local N1_display = {}
  local N2_display = {}
  local EGT_display = {}
  

  
  --In-flight variables
  local N1_actual = 0.0
  local N1_real_max_climb = 0.0
  local N1_real_max_cruise = 0.0

  --Setup engine factors based on engine type
	if string.match(simConfigData["data"].PLANE.engines, "B1F")  then
    engine_max_thrust_n = 258000
    simDR_throttle_max = 1.0
    if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
      B747_setMaxThrust(258000)  --254260  --(57160 lbf)
    end
    simDR_compressor_area = 4.38251 --(93-inch fan -- 47.17 sq. ft)
	elseif string.match(simConfigData["data"].PLANE.engines, "B5F") then
    engine_max_thrust_n = 276000
    simDR_throttle_max = 1.0
    if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
      B747_setMaxThrust(276000)  --267028  --(60030 lbf)
    end
    simDR_compressor_area = 4.38251 --(93-inch fan -- 47.17 sq. ft)
	elseif string.match(simConfigData["data"].PLANE.engines, "B1F1")  then
    engine_max_thrust_n = 276000
    simDR_throttle_max = 1.0
    if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
      B747_setMaxThrust(276000)  --267028  --(60030 lbf)
    end
    simDR_compressor_area = 4.38251 --(93-inch fan -- 47.17 sq. ft)
  else  --Assume CF6-802C-B1F if all else fails
    engine_max_thrust_n = 258000
    simDR_throttle_max = 1.0
    if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
      B747_setMaxThrust(258000)  --254260  --(57160 lbf)
    end
    simDR_compressor_area = 4.38251 --(93-inch fan -- 47.17 sq. ft)
	end

  --Find current altitude rounded to the closest 1000 feet (for use in table lookups)
  altitude = round_thrustcalc(altitude_ft_in, "ALT")

	--Packs Adjustment
  nbr_packs_on = B747DR_pack_ctrl_sel_pos[0] + B747DR_pack_ctrl_sel_pos[1] + B747DR_pack_ctrl_sel_pos[2]

	if nbr_packs_on == 0 then
		packs_adjustment_value = TOGA_N1_GE_adjustment["3PACKS_OFF"][altitude]
	elseif nbr_packs_on == 1 then
		packs_adjustment_value = TOGA_N1_GE_adjustment["2PACKS_OFF"][altitude]
	else
		packs_adjustment_value = 0.00
	end

	--Engine Anti-Ice Adjustment
	for i = 0, 3 do
		if simDR_engine_anti_ice[i] == 1 then
			engine_anti_ice_adjustment_value = TOGA_N1_GE_adjustment["NACELLE_AI_ON"][altitude]
		end
	end

	--print("Alt = "..altitude)
	--print("Temp = "..temperature)

  if simDR_onGround == 1 or takeoff_thrust_n1==0.0 or B747DR_ref_thr_limit_mode == "" or B747DR_ref_thr_limit_mode == "NONE" then
		--temperature = find_closest_temperature(TOGA_N1_GE, simDR_temperature)
		--airport_altitude = altitude
		--print("Closest Temp = ", temperature)
		--print("Takeoff Parameters = ", temperature, altitude, packs_adjustment_value, engine_anti_ice_adjustment_value)
		takeoff_thrust_n1, _ = take_off_N1_GE(altitude_ft_in)   --TOGA_N1_GE[temperature][altitude] + packs_adjustment_value + engine_anti_ice_adjustment_value
    
    if B747DR_toderate == 0 then
      takeoff_TOGA_n1 = takeoff_thrust_n1
    end

    takeoff_thrust_n1_throttle = B747_rescale(0.0, 0.0, tonumber(takeoff_TOGA_n1), 1.0, tonumber(takeoff_thrust_n1))
    
		-- Set N1 Target Bugs & Reference Indicator
    for i = 0, 3 do
      N1_target_bug[i] = math.min(string.format("%4.1f",takeoff_thrust_n1) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
      display_N1_ref[i] = math.min(string.format("%4.1f",takeoff_thrust_n1) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
      display_N1_max[i] = math.min(string.format("%4.1f",takeoff_thrust_n1) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
    end

		B747DR_TO_throttle = takeoff_thrust_n1_throttle
    --print("did init")
    --simCMD_pause:once() 
  end

  if string.match(B747DR_ref_thr_limit_mode, "TO") or B747DR_ref_thr_limit_mode == "" then
    --Store original max engine output
    if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
      orig_thrust_n = simDR_thrust_max
    end
  elseif string.match(B747DR_ref_thr_limit_mode, "CLB") then
    _, N1_actual, _, _, N1_real_max_climb, _, _, _ = in_flight_N1_GE(altitude_ft_in, 0)

		--Set target bugs
		for i = 0, 3 do
      if N1_actual > N1_real_max_climb and simDR_flap_ratio == 0 or takeoff_TOGA_n1==0  or altitude_ft_in> 20000 then
        N1_target_bug[i] = math.min(string.format("%4.1f", N1_real_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
        display_N1_ref[i] = math.min(string.format("%4.1f", N1_real_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
      else
        N1_target_bug[i] = math.min(string.format("%4.1f", N1_actual) + packs_adjustment_value + engine_anti_ice_adjustment_value, takeoff_TOGA_n1)
        display_N1_ref[i] = math.min(string.format("%4.1f", N1_actual) + packs_adjustment_value + engine_anti_ice_adjustment_value, takeoff_TOGA_n1)
      end
      --pprint(i.." display_N1_ref="..display_N1_ref[i].. "N1_actual "..N1_actual.." N1_real_max_climb ".. N1_real_max_climb .." packs_adjustment_value ".. packs_adjustment_value .." engine_anti_ice_adjustment_value ".. engine_anti_ice_adjustment_value .." takeoff_TOGA_n1 "..takeoff_TOGA_n1)
      if B747DR_display_N1_max[i] < B747DR_display_N1_ref[i] then
        display_N1_max[i] = B747DR_display_N1_ref[i]
      else
        display_N1_max[i] = math.max(display_N1_ref[i],math.min(string.format("%4.1f", N1_real_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5))
      end
    end
  elseif string.match(B747DR_ref_thr_limit_mode, "CRZ") then
      _, N1_actual, _, _, N1_real_max_climb, _, _, N1_real_max_cruise = in_flight_N1_GE(altitude_ft_in, 0)

      --Set target bugs
      for i = 0, 3 do
          N1_target_bug[i] = math.min(string.format("%4.1f", N1_real_max_cruise) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
          display_N1_ref[i] = math.min(string.format("%4.1f", N1_real_max_cruise) + packs_adjustment_value + engine_anti_ice_adjustment_value, 117.5)
          display_N1_max[i] = math.min(string.format("%4.1f", N1_real_max_climb), 117.5)
          
      end
  elseif B747DR_ref_thr_limit_mode == "GA" or (simDR_onGround == 0 and B747DR_ref_thr_limit_mode == "" or B747DR_ref_thr_limit_mode == "NONE") then
    --Find current temperature rounded to the closest 5 degrees (for use in table lookups)
    --temperature = round_thrustcalc(simDR_temperature, "TEMP")

    --Find G/A N1 based on current temperature
    temperature = find_closest_temperature(TOGA_N1_GE, simDR_temperature)

    takeoff_TOGA_n1, _ = take_off_N1_GE(altitude_ft_in)

    --Set G/A N1 targets
    for i = 0, 3 do
			N1_target_bug[i], _ = takeoff_TOGA_n1  --TOGA_N1_GE[temperature][altitude] + packs_adjustment_value + engine_anti_ice_adjustment_value
      display_N1_ref[i] = math.min(simDR_N1_target_bug[i], 117.5)
      display_N1_max[i] = math.min(simDR_N1_target_bug[i], 117.5)
		end
  end

    --Handle minor engine thrust differences where calculated (requested) thrust is less than the defined XP engine model can produce
    --Boost engine output as necessary
    if math.max(simDR_engn_thro_use[0], simDR_engn_thro_use[1], simDR_engn_thro_use[2], simDR_engn_thro_use[3]) == 1
      and math.max(simDR_N1[0], simDR_N1[1], simDR_N1[2], simDR_N1[3]) > 99.99
      and (B747DR_display_N1[0] < simDR_N1_target_bug[0] or B747DR_display_N1[1] < simDR_N1_target_bug[1]
          or B747DR_display_N1[2] < simDR_N1_target_bug[2] or B747DR_display_N1[3] < simDR_N1_target_bug[3]) then
            B747_setMaxThrust(simDR_thrust_max + 200)
    elseif simDR_thrust_max > orig_thrust_n and simDR_onGround == 0 and B747DR_radio_altitude > 1500 then  --slowly reset max engine thrust to normal
      if simDR_thrust_max > orig_thrust_n + 10 then
        B747_setMaxThrust(simDR_thrust_max - 10)
      else
        B747_setMaxThrust(simDR_thrust_max - 1)
      end
    end

	--Failsafe option if takeoff_thrust_n1 isn't set
  if takeoff_thrust_n1 == nil then
    takeoff_thrust_n1 = 105.0
    takeoff_TOGA_n1 = 105.0
  end
  
  for i = 0, 3 do
    if B747DR_ap_FMA_autothrottle_mode==5 and B747DR_ap_flightPhase>2 then
      simDR_N1_target_bug[i]=25
    else
      simDR_N1_target_bug[i] = N1_target_bug[i]
    end
    B747DR_display_N1_ref[i] = display_N1_ref[i]
    B747DR_display_N1_max[i] = display_N1_max[i]
  end
	for i = 0, 3 do
    --takeoff_TOGA_n1 (max TO) is used as a factor to compute N1 for TO based on the simDR_N1 to prevent N1 display loss during TO -- in flight it is calculated based on Newtons
    N1_display[i] = string.format("%4.1f", math.min(N1_display_GE(altitude_ft_in, simDR_thrust_n[i], takeoff_TOGA_n1 / 100, i), 118.0))  --use i as a reference for engine number
    B747DR_display_N1[i] = math.max(N1_display[i], 0.0)

    N2_display[i] = string.format("%4.1f", math.min(N2_display_GE(N1_display[i], i), 112.5))  --use N1 as input for calcs
    B747DR_display_N2[i] = math.max(N2_display[i], 0.0)

    EGT_display[i] = EGT_display_GE(i)
    B747DR_display_GE_EGT[i] =egt_thermal_profile(EGT_display[i],i,B747DR_display_GE_EGT[i])--math.max(EGT_display[i], 0.0)

    B747DR_throttle_resolver_angle[i] = throttle_resolver_angle_GE(i)
	end

  if B747DR_log_level >= 1 then
    print("Takeoff TOGA = ", takeoff_TOGA_n1)
  end
  --Manage Thrust
  throttle_management()
  --thrust_ref_control_N1()
end