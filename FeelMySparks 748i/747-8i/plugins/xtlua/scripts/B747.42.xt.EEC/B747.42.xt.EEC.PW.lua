--[[
****************************************************************************************
* Program Script Name	:	B747.42.xt.EEC.PW.lua
* Author Name			:	Marauder28
*                   (with SIGNIFICANT contributions from @kudosi for aeronautic formulas)
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2021-01-11	0.01a				      Start of Dev
*	  2021-08-13	0.1				        Initial Release
*	  2021-12-11	0.2				        New Throttle Resolver Angle formula, various bug fixes
*
*
*****************************************************************************************
]]

--This function calculates the target position of the throttle target on the Upper EICAS
function throttle_resolver_angle_PW(engine_in)
  local EPR_target=B747_rescale(0.0, 0.95, 1.0, B747DR_display_EPR_max[engine_in], B747DR_throttle[engine_in])
  return EPR_target
end

function engine_idle_control_PW(altitude_ft_in)
    local N1_low_idle = 0.0
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
        simDR_engine_high_idle_ratio = B747_rescale(-75.0, 1.00, 14.99, 1.07, simDR_temperature)
      else
        simDR_engine_high_idle_ratio = B747_rescale(15.0, 1.071, 75.0, 1.14, simDR_temperature)
      end
    end
  
    --Calc engine LOW Idle
    --N1_low_idle = -1.03E-08 * altitude_ft_in^2 + 8.85E-04 * altitude_ft_in + 2.52E+01
    N1_low_idle = -1.45E-08 * altitude_ft_in^2 + 0.00121 * altitude_ft_in + 25.9
  
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
  
  function take_off_EPR_PW(altitude_ft_in)
    local EPR_actual = 0.0
    local mach = 0.0
    local TOGA_corrected_thrust_N = 0.0
    local TOGA_corrected_thrust_calibrated_N = 0.0

    --locals to hold returned values from take_off_thrust_corrected() function
    local TOGA_actual_thrust_N = 0.0

  
    --For Takeoff, use actual Sim temperature instead of atmosphere() temperature_K
    --If a derate temperature is entered in the THRUST LIM page of the FMC, use that instead
    --if fmsModules["data"]["thrustsel"] ~= "  " then
    --  temperature_K = tonumber(fmsModules["data"]["thrustsel"]) + 273.15
    --else
      --temperature_K = simDR_temperature + 273.15
    --end
  
    --temperature_ratio = temperature_K / 288.15
  
    --get take_off_thrust_corrected() data
    _, _, TOGA_actual_thrust_N = take_off_thrust_corrected(altitude_ft_in, temperature_K)

    TOGA_corrected_thrust_N = TOGA_actual_thrust_N / (1000 * sigma_density_ratio)
    --TOGA_corrected_thrust_N = TOGA_actual_thrust_N / (1000 * pressure_ratio)
    TOGA_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * TOGA_corrected_thrust_N  --Sigma version 2
    --TOGA_corrected_thrust_calibrated_N = (-0.0811 * mach^2 + 0.2349 * mach + 0.919) * TOGA_corrected_thrust_N  --Sigma version 2
  
    --Mach should always be 0 for purposes of this calculation
    mach = 0.0
    --mach = -0.046  --this seems to give a slightly better calculation as compared to the FCOM tables
  
    EPR_actual = (-1.8E-08 * mach^2 - 5.87E-08 * mach + 7.179999999999999E-08) * TOGA_corrected_thrust_calibrated_N^3 + (-0.0000237 * mach^2 + 0.0000529 * mach - 0.0000218)
      * TOGA_corrected_thrust_calibrated_N^2 + (0.002 * mach^2 - 0.0036 * mach + 0.0034) * TOGA_corrected_thrust_calibrated_N + (-0.3287 * mach^2 - 0.0833 * mach + 0.9932)

    if B747DR_log_level >= 1 then
      print("\t\t\t\t\t<<<--- TAKEOFF EPR (PW) --->>>")
      print("Altitude IN = ", altitude_ft_in)
      print("Temperature K = ", temperature_K)
      print("Temperature Ratio = ", temperature_ratio)
      print("Mach = ", mach)
      print("TOGA Actual Thrust N = ", TOGA_actual_thrust_N)
      print("TOGA Corrected Thrust = ", TOGA_corrected_thrust_N * 1000)
      print("TOGA Corrected Thrust - Calibrated = ", TOGA_corrected_thrust_calibrated_N)
      print("Temp < Corner = ", temperature_K < corner_temperature_K)
      print("EPR Actual = ", EPR_actual)
    end
  
    return EPR_actual, TOGA_actual_thrust_N
  end

  local EPR_initial_climb = 0.0  
  function in_flight_EPR_PW(altitude_ft_in, delta_t_isa_K_in)
    local EPR_corrected_thrust_N = 0.0
    local EPR_corrected_thrust_calibrated_N = 0.0
    local EPR_actual = 0.0
    local EPR_max_climb = 0.0
    local climb_rate_fpm = 0
    local climb_angle_deg = 0.0

    local thrust_per_engine_N = 0.0
    local corrected_thrust_lbf = 0.0
  
      --Due to modeling differences / deficiencies, the climb rates below are tweaked (higher) to
      --allow for more closely matched real-world performance.  Ideal generic target climb rates are:
      --  >> 0 - 10000 ft = 2200fpm
      --  >> 10000 - 20000ft = 2100fpm
      --  >> 20000 - 30000ft = 1700fpm
      if string.match(simConfigData["data"].PLANE.engines, "4056") then --simConfigData["data"].PLANE.engines == "PW4056" then
        if simDR_altitude < 10000 then
          climb_rate_fpm = 2750
        elseif simDR_altitude <= 20000 then
          --climb_rate_fpm = 2750
          climb_rate_fpm = B747_rescale(10000.0, 2750.0, 20000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          --climb_rate_fpm = 2400
          climb_rate_fpm = B747_rescale(20000.0, 2500.0, 30000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          --climb_rate_fpm = 2000
          climb_rate_fpm = B747_rescale(30000.0, 2250.0, 40000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2250
        end
      elseif string.match(simConfigData["data"].PLANE.engines, "4060") then
        --For now, use the same climb rates as the PW4056 until we have specific information for PW4060 and others
        if simDR_altitude < 10000 then
          climb_rate_fpm = 2875
        elseif simDR_altitude <= 20000 then
          --climb_rate_fpm = 2750
          climb_rate_fpm = B747_rescale(10000.0, 2875.0, 20000.0, 2625.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          --climb_rate_fpm = 2500
          climb_rate_fpm = B747_rescale(20000.0, 2625.0, 30000.0, 2375.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          --climb_rate_fpm = 2000
          climb_rate_fpm = B747_rescale(30000.0, 2375.0, 40000.0, 2375.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2375
        end
      elseif string.match(simConfigData["data"].PLANE.engines, "4062") then --simConfigData["data"].PLANE.engines == "PW4062" then
        --For now, use the same climb rates as the PW4056 until we have specific information for PW4060 and others
        if simDR_altitude < 10000 then
          climb_rate_fpm = 3000
        elseif simDR_altitude <= 20000 then
          --climb_rate_fpm = 2750
          climb_rate_fpm = B747_rescale(10000.0, 3000.0, 20000.0, 2750.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          --climb_rate_fpm = 2500
          climb_rate_fpm = B747_rescale(20000.0, 2750.0, 30000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          --climb_rate_fpm = 2000
          climb_rate_fpm = B747_rescale(30000.0, 2500.0, 40000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2500
        end
      else  --Assume PW4056 if all else fails
        if simDR_altitude < 10000 then
          climb_rate_fpm = 2750
        elseif simDR_altitude <= 20000 then
          --climb_rate_fpm = 2750
          climb_rate_fpm = B747_rescale(10000.0, 2750.0, 20000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          --climb_rate_fpm = 2400
          climb_rate_fpm = B747_rescale(20000.0, 2500.0, 30000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          --climb_rate_fpm = 2000
          climb_rate_fpm = B747_rescale(30000.0, 2250.0, 40000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2250
        end
    end
  
      if fmc_alt >= (altitude_ft_in - 200) and B747DR_ref_thr_limit_mode == "CRZ" then
        climb_rate_fpm = 0
      end
  
      climb_angle_deg = math.asin(0.00508 * climb_rate_fpm / tas_mtrs_sec) * 180 / math.pi
  
      --get in_flight_thrust() data
      _, thrust_per_engine_N, _, corrected_thrust_lbf = in_flight_thrust(simDR_acf_weight_total_kg, climb_angle_deg)
  
      EPR_corrected_thrust_N =   thrust_per_engine_N / (1000 * sigma_density_ratio)
      --EPR_corrected_thrust_N =   thrust_per_engine_N / (1000 * pressure_ratio)
      EPR_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * EPR_corrected_thrust_N  --Sigma version 2

      EPR_actual = (-1.8E-08 * mach^2 - 5.87E-08 * mach + 7.179999999999999E-08) * EPR_corrected_thrust_calibrated_N^3 + (-0.0000237 * mach^2 + 0.0000529 * mach - 0.0000218)
        * EPR_corrected_thrust_calibrated_N^2 + (0.002 * mach^2 - 0.0036 * mach + 0.0034) * EPR_corrected_thrust_calibrated_N + (-0.3287 * mach^2 - 0.0833 * mach + 0.9932)

      --Calculate Initial Climb EPR
      if EPR_initial_climb == 0.0 then
        if simDR_TAT > 10 then
          EPR_initial_climb = (3.8422E-15 * simDR_TAT^4 - 6.2166E-13 * simDR_TAT^3 + 3.5174E-11 *simDR_TAT^2 - 7.8614E-10 * simDR_TAT + 5.0804E-09) * altitude_ft_in^2
            + (-7.29E-11 * simDR_TAT^4 + 1.04E-08 * simDR_TAT^3 - 5.06E-07 * simDR_TAT^2 + 9.23E-06 * simDR_TAT - 0.0000389) * altitude_ft_in
            + (-0.0000857 * simDR_TAT^2 + 0.00271 * simDR_TAT + 1.35)
        else
          EPR_initial_climb = 7.4925E-11 * altitude_ft_in^2 + 0.000013082 * altitude_ft_in + 1.3654
        end
      end

      --Calculate Max Climb EPR
      if altitude_ft_in > (-10.336 * simDR_TAT^2 - 278.25 * simDR_TAT + 33812) then
        EPR_max_climb = (-4.97E-11 * simDR_TAT^3 + 4.34E-09 * simDR_TAT^2 + 2.29E-08 * simDR_TAT - 7.19E-06) * altitude_ft_in + (-0.009808 * simDR_TAT + 1.7329)
      else
        EPR_max_climb = 0.0000107 * altitude_ft_in + 1.24
      end

      --Keep the Initial and Max Climb values per the FCOM tables
      if EPR_initial_climb > 1.50 then
        EPR_initial_climb = 1.50
      end

      if EPR_max_climb > 1.64 then
        EPR_max_climb = 1.64
      end

      if B747DR_log_level >= 1 then
        print("\t\t\t\t\t<<<--- IN FLIGHT EPR (PW) --->>>")
        print("Altitude IN = ", altitude_ft_in)
        print("Delta T ISA IN = ", delta_t_isa_K_in)
        print("Temperature Ratio = ", temperature_ratio)
        print("Temperature Ratio Adapted = ", temperature_ratio_adapted)
        print("Mach = ", mach)
        print("Req'd Thrust per Engine N = ", thrust_per_engine_N)
        print("Corrected Thrust N = ", EPR_corrected_thrust_N)
        print("Corrected Thrust N - Calibrated = ", EPR_corrected_thrust_calibrated_N)
        print("Corrected Thrust LBF = ", corrected_thrust_lbf)
        print("Climb Rate FPM = ", climb_rate_fpm)
        print("Climb Angle = ", climb_angle_deg)
        print("EPR Intial Climb = ", EPR_initial_climb)
        print("EPR Max Climb = ", EPR_max_climb)
        print("EPR Actual = ", EPR_actual)
      end
  
      return EPR_actual, EPR_initial_climb, EPR_max_climb
  end
  
  local last_thrust_n = {0.0, 0.0, 0.0, 0.0}
  local last_N1 = {0.0, 0.0, 0.0, 0.0}
  function N1_display_PW(altitude_ft_in, thrust_N_in, engine_in)
    local N1_corrected_rpm = 0.0
    local N1_pct = 0.0
    local N1_actual = 0.0
    local N1_corrected_thrust_calibrated_N = 0.0
    local N1_corrected_thrust_n = 0.0
    local N1_low_idle = 0.0
    local N1_idle_capture = 0.0
    local N1_zero_thrust = 0.0
    if last_N1[engine_in] == nil then last_N1[engine_in] = 0.0 end
    --Handle display of an engine shutdown
    --[[if simDR_engine_running[engine_in] == 0 then
      thrust_N_in = last_thrust_n[engine_in]
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

    N1_corrected_thrust_n = thrust_N_in / (1000 * sigma_density_ratio)
    --N1_corrected_thrust_n = thrust_N_in / (1000 * pressure_ratio)

    --N1_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * N1_corrected_thrust_n  --Sigma version 2
    N1_corrected_thrust_calibrated_N = (-0.0811 * mach^2 + 0.2349 * mach + 0.919) * N1_corrected_thrust_n  --Sigma version 2

    --N1_corrected_rpm = (0.0136 * mach^2 - 0.00905 * mach - 0.0107) * N1_corrected_thrust_calibrated_N^2 + (-5.84 * mach^2 + 0.512 * mach + 13.5) * N1_corrected_thrust_calibrated_N
    --  + (-508 * mach^2 + 1792.2 * mach + 1065.4)

    N1_corrected_rpm = (0.0136 * mach^2 - 0.00905 * mach - 0.0107) * N1_corrected_thrust_calibrated_N^2 + (-5.84 * mach^2 + 0.512 * mach + 13.5) * N1_corrected_thrust_calibrated_N
      + (-508 * mach^2 + 1792.2 * mach + B747_rescale(0.0, 0.0, 750.0, 1065.4, simDR_rpm[engine_in]))

    N1_pct = N1_corrected_rpm / 3600 * 100 * math.sqrt(temperature_K / 288.15)

    --Engine Idle Logic (Minimum / Approach)
    N1_low_idle = engine_idle_control_PW(altitude_ft_in)
    N1_idle_capture = -43.988 * mach^2 + 63.256 * mach + 28.896 + 0.7
    N1_zero_thrust = (-508 * mach^2 + 1792.2 * mach + 1065.4) / 3600 * 100 * math.sqrt(temperature_K / 288.15)    

    --Use slightly different formulas depending on ground versus air to prevent display anomalies
    if simDR_onGround == 0 then
      if N1_pct < N1_idle_capture then
        N1_actual = math.max((N1_idle_capture - N1_low_idle) / (N1_idle_capture - N1_zero_thrust) * (N1_pct - N1_zero_thrust) + N1_low_idle, N1_low_idle)
      else
        N1_actual = N1_pct
      end
    else
      if N1_pct < 51 then
        N1_actual = (51 - N1_low_idle) / (51 - N1_idle_capture) * (N1_pct - N1_idle_capture) + N1_low_idle
      else
        N1_actual = N1_pct
      end
    end

    if N1_actual < N1_low_idle and N1_corrected_rpm >= 1065.4  and simDR_engine_running[engine_in] == 1 then 
      -- N1_actual = N1_low_idle
      N1_actual = B747_animate_value(last_N1[engine_in],N1_low_idle,0,115,0.1) 
      --print(" pin N1_actual 2 "..N1_actual)
    elseif simDR_engine_running[engine_in] == 0 then
      N1_actual = B747_animate_value(last_N1[engine_in],simDR_N1[engine_in],0,115,0.1) 
      --print(" pin N1_actual 1 "..N1_actual.. " n1 "..simDR_N1[engine_in])
    end

    --During Startup / Shutdown track the XP N1 value if the formulas aren't reasonable
    if N1_actual < simDR_N1[engine_in] then
      N1_actual = B747_animate_value(last_N1[engine_in],simDR_N1[engine_in],0,115,0.1) 
    end

    if B747DR_log_level >= 1 then
      print("----- N1 Display -----")
      print("N1 Corrected Thrust = ", N1_corrected_thrust_n)
      print("N1 Calibrated Thrust = ", N1_corrected_thrust_calibrated_N)
      print("N1 Corrected RPM = ", N1_corrected_rpm)
      print("N1% = ", N1_pct)
      print("N1_idle = ", N1_low_idle)
      print("N1 Idle Capture = ", N1_idle_capture)
      print("N1 Actual = ", N1_actual)
      print("ENGINE RUNNING = ", simDR_engine_running[engine_in])
      print("Last Thrust In = ", last_thrust_n[engine_in])
    end
    last_N1[engine_in] = N1_actual
    return N1_actual
  end
  local last_N2 = {0.0, 0.0, 0.0, 0.0}
  function N2_display_PW(engine_N1_in, engine_in)
    local N2_display = 0.0
    N2_display = (0.000798 * engine_N1_in^2 - 0.154 * engine_N1_in + 10.2) * engine_N1_in * (3600/9900)  --have to multiply by the 100% rotation speed of N1 / 100% rotation speed of N2
  
    if last_N2[engine_in] == nil then last_N2[engine_in] = 0.0 end
    if (simDR_engine_running[engine_in] == 0 or simDR_N2[engine_in]<35) then
      N2_display = B747_animate_value(last_N2[engine_in],simDR_N2[engine_in],0,115,0.1) 
    elseif N2_display < simDR_N2[engine_in] then --and N2_display < 30.0 then
      N2_display = B747_animate_value(last_N2[engine_in],simDR_N2[engine_in],0,115,0.1)
    else
      N2_display = B747_animate_value(last_N2[engine_in],N2_display,0,115,10)
    end

    if B747DR_log_level >= 1 then
      print("----- N2 Display -----")
      print("N1 in, N2 = ", engine_N1_in, N2_display)
    end
    last_N2[engine_in] = N2_display
    return N2_display
  end
  
  function EPR_display_PW(altitude_ft_in, thrust_N_in, engine_in)
      local EPR_actual = 0.0
      local EPR_corrected_thrust_N = 0.0
      local EPR_corrected_thrust_calibrated_N = 0.0

      if last_thrust_n[engine_in] == nil then
        last_thrust_n[engine_in] = 0.0
      end

      --Handle display of an engine shutdown
      if simDR_engine_running[engine_in] == 0 then
        thrust_N_in = last_thrust_n[engine_in]  --calculated in N1_display_PW()
      end
  
      EPR_corrected_thrust_N = thrust_N_in / (1000 * sigma_density_ratio)
      --EPR_corrected_thrust_N = thrust_N_in / (1000 * pressure_ratio)
    
      EPR_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * EPR_corrected_thrust_N  --Sigma version 2
      --EPR_corrected_thrust_calibrated_N = (-0.0811 * mach^2 + 0.2349 * mach + 0.919) * EPR_corrected_thrust_N  --Sigma version 2

      EPR_actual = (-1.8E-08 * mach^2 - 5.87E-08 * mach + 7.179999999999999E-08) * EPR_corrected_thrust_calibrated_N^3 + (-0.0000237 * mach^2 + 0.0000529 * mach - 0.0000218)
        * EPR_corrected_thrust_calibrated_N^2 + (0.002 * mach^2 - 0.0036 * mach + 0.0034) * EPR_corrected_thrust_calibrated_N + (-0.3287 * mach^2 - 0.0833 * mach + 0.9932)

        
      --Ensure EPR doesn't drop to an unrealistic value during IDLE descent.  This also ensures that the EPR tapes don't fall off the display.
      if EPR_actual < 0.97 then
        EPR_actual = 0.97
      --try to combat the formula issue where EPR increases due to mach rising faster than thrust decreases during TO
      elseif B747DR_ref_thr_limit_mode ~= "GA" and simDR_flap_ratio > 0.0 then
        if EPR_actual > B747DR_display_EPR_max[engine_in] then
          EPR_actual = B747DR_display_EPR_max[engine_in]
        end
      end

      if B747DR_log_level ==-2 then
        print("\t\t\t\t\t<<<--- EPR DISPLAY (PW) --->>>".."\t\tEngine # "..engine_in + 1)
        print("Altitude IN = ", altitude_ft_in)
        print("Thrust IN = ", thrust_N_in)
        print("Pressure Ratio = ", pressure_ratio)
        print("Temperature K = ", temperature_K)
        print("Temperature Ratio = ", temperature_ratio)
        print("Mach = ", mach)
        print("Corrected Thrust N (1000's) = ", EPR_corrected_thrust_N)
        print("Corrected Thrust Calibrated N (1000's) = ", EPR_corrected_thrust_calibrated_N)
        print("EPR Actual = ", EPR_actual)
        print("Last Thrust In = ", last_thrust_n[engine_in])
      end
      
      return EPR_actual
  end

  function EGT_display_PW(engine_in)
    local EGT_display = 0.0
  
    if simDR_engn_EGT_c[engine_in] <= simDR_temperature then
      EGT_display = simDR_temperature
    else
      EGT_display = B747_rescale(0.0, 0.0, 960, 654, simDR_engn_EGT_c[engine_in])
    end
  
    if B747DR_log_level >= 1 then
      print("EGT = ", EGT_display)
    end
  
    return EGT_display
  end
  
  local orig_thrust_n = 0.0
  function PW(altitude_ft_in)
    local altitude = 0.0  --round_thrustcalc(simDR_altitude, "ALT")
    local nbr_packs_on = 0
    local packs_adjustment_value = 0.0
    local engine_anti_ice_adjustment_value = 0.0
    local wing_anti_ice_adjustment_value = 0.0
    local takeoff_thrust_epr = 1.0  --100.0
    local takeoff_thrust_epr_throttle = 0.00
    local EPR_initial_climb = 0.0
    local EPR_max_climb = 0.0
    local EPR_max_cruise = 0.0
    local EPR_display = {}
    local N1_display = {}
    local N2_display = {}
    local EGT_display = {}
    local target_weight = 0.0
    local target_alt = 0.0
    local EPR_target_bug = {}
    local display_EPR_ref = {}
    local display_EPR_max = {}
    --In-flight variables
    local EPR_actual = 0.0
    for i = 0, 3 do
      EPR_target_bug[i] = simDR_EPR_target_bug[i]
      display_EPR_ref[i] = B747DR_display_EPR_ref[i]
      display_EPR_max[i] = B747DR_display_EPR_max[i]
    end
    --Setup engine factors based on engine type
    if string.match(simConfigData["data"].PLANE.engines, "4056") then
      engine_max_thrust_n = 254000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(254000)  --252437  --(56750 lbf)
      end
      simDR_compressor_area = 4.47727  --(94-inch fan -- 48.19 sq. ft)
    elseif string.match(simConfigData["data"].PLANE.engines, "4060") then
      engine_max_thrust_n = 267000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(267000)  --266893  --(60000 lbf)
      end
      simDR_compressor_area = 4.47727  --(94-inch fan -- 48.19 sq. ft)
    elseif string.match(simConfigData["data"].PLANE.engines, "4062")  then
      engine_max_thrust_n = 276000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(276000)  --275790  --(62000 lbf)
      end
      simDR_compressor_area = 4.47727  --(94-inch fan -- 48.19 sq. ft)
    else  --Assume PW4056 if all else fails
      engine_max_thrust_n = 254000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(254000)  --252437  --(56750 lbf)
      end
      simDR_compressor_area = 4.47727  --(94-inch fan -- 48.19 sq. ft)
    end

    --Find current altitude rounded to the closest 1000 feet (for use in table lookups)
    altitude = round_thrustcalc(altitude_ft_in, "ALT")
  
      --Packs Adjustment
    nbr_packs_on = B747DR_pack_ctrl_sel_pos[0] + B747DR_pack_ctrl_sel_pos[1] + B747DR_pack_ctrl_sel_pos[2]
  
    if nbr_packs_on == 0 then
        packs_adjustment_value = TOGA_epr_PW4056_adjustment["3PACKS_OFF"]
    elseif nbr_packs_on == 1 then
        packs_adjustment_value = TOGA_epr_PW4056_adjustment["2PACKS_OFF"]
    else
        packs_adjustment_value = 0.00
    end
  
    --Engine Anti-Ice Adjustment
    --for i = 0, 3 do
    --    if simDR_engine_anti_ice[i] == 1 then
    --        engine_anti_ice_adjustment_value = TOGA_epr_PW4056_adjustment["NACELLE_AI_ON"][altitude]
    --    end
    --end
  
    --print("Alt = "..altitude)
    --print("Temp = "..temperature)

    --Initialize N1 targets to 100% in case someone starts the flight scenario in the air (i.e. 10nm final, etc.)
    if takeoff_TOGA_epr == 0.0 then
      takeoff_thrust_epr = 1.70
      takeoff_TOGA_epr = 1.70
    end
  
    
    if simDR_onGround == 1 or B747DR_ref_thr_limit_mode == "" or B747DR_ref_thr_limit_mode == "NONE" then
        --temperature = find_closest_temperature(TOGA_N1_GE, simDR_temperature)
        --airport_altitude = altitude
        --print("Closest Temp = ", temperature)
        --print("Takeoff Parameters = ", temperature, altitude, packs_adjustment_value, engine_anti_ice_adjustment_value)
        takeoff_thrust_epr, _ = take_off_EPR_PW(altitude_ft_in)
    
      if B747DR_toderate == 0 then
        takeoff_TOGA_epr = takeoff_thrust_epr
      end

      takeoff_thrust_epr_throttle = B747_rescale(0.0, 0.0, tonumber(takeoff_TOGA_epr), 1.0, tonumber(takeoff_thrust_epr))
      
      -- Set EPR Target Bugs & Reference Indicator
      --Due to display issues on the EICAS, keep the REF and MAX limit lines at a max of 1.70 otherwise they get painted above the EPR tape
      for i = 0, 3 do
        EPR_target_bug[i] = string.format("%3.2f",takeoff_thrust_epr) + packs_adjustment_value + engine_anti_ice_adjustment_value
        display_EPR_ref[i] = math.min(string.format("%3.2f",takeoff_thrust_epr) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.71)
        display_EPR_max[i] = math.min(string.format("%3.2f",takeoff_thrust_epr) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.71)
      end

      B747DR_TO_throttle = takeoff_thrust_epr_throttle
    end
  
    if string.match(B747DR_ref_thr_limit_mode, "TO") or B747DR_ref_thr_limit_mode == "" then
      --Store original max engine output
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        orig_thrust_n = simDR_thrust_max
      end
    elseif string.match(B747DR_ref_thr_limit_mode, "CLB") then
      EPR_actual, EPR_initial_climb, EPR_max_climb = in_flight_EPR_PW(altitude_ft_in, 0)
  
        --Set target bugs
      for i = 0, 3 do
        if EPR_actual > EPR_max_climb then
          if EPR_initial_climb > EPR_max_climb then
            EPR_target_bug[i] = string.format("%3.2f", EPR_initial_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value
            display_EPR_ref[i] = math.min(string.format("%3.2f", EPR_initial_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.71)
          else
            EPR_target_bug[i] = string.format("%3.2f", EPR_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value
            display_EPR_ref[i] = math.min(string.format("%3.2f", EPR_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.71)
          end
        else
          EPR_target_bug[i] = string.format("%3.2f", EPR_actual) + packs_adjustment_value + engine_anti_ice_adjustment_value
          display_EPR_ref[i] = math.min(string.format("%3.2f", EPR_actual) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.71)
        end

        if B747DR_display_EPR_max[i] < B747DR_display_EPR_ref[i] then
          display_EPR_max[i] = B747DR_display_EPR_ref[i]
        end
      end
    elseif string.match(B747DR_ref_thr_limit_mode, "CRZ") then
      EPR_actual, _, EPR_max_climb = in_flight_EPR_PW(altitude_ft_in, 0)

      --Use LRC lookup tables from FCOM to determine approximate CRZ max EPR
      --target_weight = find_closest_weight(LRC_epr_PW4056, math.ceil(simDR_acf_weight_total_kg / 1000))
      --target_alt = find_closest_altitude(LRC_epr_PW4056, math.ceil(altitude_ft_in / 1000))

      --EPR_max_cruise = LRC_epr_PW4056[target_weight][target_alt] + 0.10  --Add 0.10 EPR to the LRC table value as a guess

      target_weight = find_closest_weight(P85M_epr_PW4062, math.ceil(simDR_acf_weight_total_kg / 1000))
      target_alt = find_closest_altitude(P85M_epr_PW4062, math.ceil(altitude_ft_in / 1000))

      EPR_max_cruise = P85M_epr_PW4062[target_weight][target_alt] --+ 0.10  --Add 0.10 EPR to the LRC table value as a guess

      --Set target bugs
      for i = 0, 3 do
          EPR_target_bug[i] = string.format("%3.2f", EPR_max_cruise) + packs_adjustment_value + engine_anti_ice_adjustment_value
          display_EPR_ref[i] = string.format("%3.2f", EPR_max_cruise) + packs_adjustment_value + engine_anti_ice_adjustment_value
          display_EPR_max[i] = EPR_max_climb  --simDR_EPR_target_bug[i]
      end

      if B747DR_log_level >= 1 then
        print("CRZ Lookup - Weight = ", target_weight)
        print("CRZ Lookup - Alt = ", target_alt)
      end
    elseif B747DR_ref_thr_limit_mode == "GA" then
      --Find current temperature rounded to the closest 5 degrees (for use in table lookups)
      --temperature = round_thrustcalc(simDR_temperature, "TEMP")
  
      --Find G/A N1 based on current temperature
      --temperature = find_closest_temperature(TOGA_epr_PW4056, simDR_temperature)
  
      --Set G/A N1 targets
      for i = 0, 3 do
        if altitude_ft_in < (-10.15 * simDR_TAT^2 + 57.654 * simDR_TAT + 9526.4) then
          EPR_target_bug[i] = string.format("%3.2f", 0.000017 * altitude_ft_in + 1.5 + packs_adjustment_value + engine_anti_ice_adjustment_value)
        else
          EPR_target_bug[i] = string.format("%3.2f", -0.00669 * simDR_TAT + 1.74 + packs_adjustment_value + engine_anti_ice_adjustment_value)
        end
        display_EPR_ref[i] = math.min(simDR_EPR_target_bug[i], 1.71)
        display_EPR_max[i] = math.min(simDR_EPR_target_bug[i], 1.71)
      end
    end

    --Handle minor engine thrust differences where calculated (requested) thrust is less than the defined XP engine model can produce
    --Boost engine output as necessary
    if math.max(simDR_engn_thro_use[0], simDR_engn_thro_use[1], simDR_engn_thro_use[2], simDR_engn_thro_use[3]) == 1
      and math.max(simDR_N1[0], simDR_N1[1], simDR_N1[2], simDR_N1[3]) > 99.99
      and (B747DR_display_EPR[0] < simDR_EPR_target_bug[0] or B747DR_display_EPR[1] < simDR_EPR_target_bug[1]
          or B747DR_display_EPR[2] < simDR_EPR_target_bug[2] or B747DR_display_EPR[3] < simDR_EPR_target_bug[3]) then
            B747_setMaxThrust(simDR_thrust_max + 200)
    elseif simDR_thrust_max > orig_thrust_n and simDR_onGround == 0 and B747DR_radio_altitude > 1500 then  --slowly reset max engine thrust to normal
      if simDR_thrust_max > orig_thrust_n + 10 then
        B747_setMaxThrust(simDR_thrust_max - 10)
      else
        B747_setMaxThrust(simDR_thrust_max - 1)
      end
    end

    --After manipulating simDR_thrust_max, ensure that it doesn't go below the max output
    if simDR_thrust_max < engine_max_thrust_n then
      B747_setMaxThrust(engine_max_thrust_n)
    end
  
    --Failsafe option in caser takeoff_thrust_epr isn't set
    if takeoff_thrust_epr == nil then
      takeoff_thrust_epr = 1.70
      takeoff_TOGA_epr = 1.70
    end
  
    for i = 0, 3 do
      if (B747DR_ap_FMA_autothrottle_mode==5 or B747DR_ap_FMA_autothrottle_mode==2) and B747DR_ap_flightPhase>2 then
        simDR_EPR_target_bug[i] = 0.9
      else
        simDR_EPR_target_bug[i] = EPR_target_bug[i]
      end
      B747DR_display_EPR_ref[i] = display_EPR_ref[i]
      B747DR_display_EPR_max[i] = display_EPR_max[i]
     -- EPR_display[i] = string.format("%3.2f", math.min(EPR_display_PW(altitude_ft_in, simDR_thrust_n[i], i), 1.71)) 
      EPR_display[i] = math.min(EPR_display_PW(altitude_ft_in, simDR_thrust_n[i], i), 1.71) --use i as a reference for engine number
      B747DR_display_EPR[i] = math.max(EPR_display[i], 0.0)

      N1_display[i] = string.format("%4.1f", math.min(N1_display_PW(altitude_ft_in, simDR_thrust_n[i], i), 111.5))
      B747DR_display_N1[i] = math.max(N1_display[i], 0.0)

      N2_display[i] = string.format("%3.0f", math.min(N2_display_PW(B747DR_display_N1[i], i), 111.5))
      B747DR_display_N2[i] = math.max(N2_display[i], 0.0)

      EGT_display[i] = EGT_display_PW(i)
      B747DR_display_EGT[i] = egt_thermal_profile(EGT_display[i],i,B747DR_display_EGT[i])--math.max(EGT_display[i], 0.0)
  
      B747DR_throttle_resolver_angle[i] = throttle_resolver_angle_PW(i)

    end
  
    if B747DR_log_level >= 1 then
      print("Takeoff TOGA = ", takeoff_TOGA_epr)
    end
    --Manage Thrust
    throttle_management()
  end