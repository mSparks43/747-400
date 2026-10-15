--[[
****************************************************************************************
* Program Script Name	:	B747.42.xt.EEC.RR.lua
* Author Name			:	Marauder28
*                   (with SIGNIFICANT contributions from @kudosi for aeronautic formulas)
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2021-01-11	0.01a				      Start of Dev
*	  2021-12-11	0.1				        Initial Release
*
*
*
*****************************************************************************************
]]

--This function calculates the target position of the throttle target on the Upper EICAS
function throttle_resolver_angle_RR(engine_in)
  local EPR_target=B747_rescale(0.0, 0.95, 1.0, B747DR_display_EPR_max[engine_in]*0.99, B747DR_throttle[engine_in])
  return EPR_target
end

function engine_idle_control_RR(altitude_ft_in)
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
    N1_low_idle = -1.45E-08 * altitude_ft_in^2 + 0.00121 * altitude_ft_in + 21.9
  
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
    
    if B747DR_log_level >= 2 then
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
  
    if B747DR_log_level >= 2 then
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
  
  function take_off_EPR_RR(altitude_ft_in)
    local EPR_actual = 0.0
    local mach = 0.0
    local TOGA_corrected_thrust_N = 0.0
    local TOGA_corrected_thrust_calibrated_N = 0.0
    local RR_EPR_factor = 1.00

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
    --TOGA_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * TOGA_corrected_thrust_N  --Sigma version 2
    TOGA_corrected_thrust_calibrated_N = TOGA_corrected_thrust_N  --no calibration needed
    
    --Mach should always be 0 for purposes of this calculation
    mach = 0.0
  
    --NEW RR EPR formula (11/3/21)
    RR_EPR_factor = B747_rescale(4.0, 1.00, 50.0, 1.05, TOGA_corrected_thrust_N)
    EPR_actual = (2.8E-08 * mach^2 + 1.86E-08 * mach - 3.33E-08) * TOGA_corrected_thrust_N^3 + (-0.0000143 * mach^2 - 9.38E-06 * mach + 7.32E-06)
      * TOGA_corrected_thrust_N^2 + (0.0021 * mach^2 + 0.0015 * mach + 0.0029) * TOGA_corrected_thrust_N + (-0.1773 * mach^2 - 0.0283 * mach + RR_EPR_factor)  --1.05)
  
    if B747DR_log_level >= 2 then
      print("\t\t\t\t\t<<<--- TAKEOFF EPR (RR) --->>>")
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
  local last_climb_rate_fpm = 0.0
  function in_flight_EPR_RR(altitude_ft_in, delta_t_isa_K_in)
    local EPR_corrected_thrust_N = 0.0
    local EPR_corrected_thrust_calibrated_N = 0.0
    local EPR_actual = 0.0
    local EPR_max_climb = 0.0
    local climb_rate_fpm = 0
    local climb_angle_deg = 0.0
    local thrust_per_engine_N = 0.0
    local corrected_thrust_lbf = 0.0
    local RR_EPR_factor = 1.00
    local RR_EPR_correction = 0.0
  
      --Due to modeling differences / deficiencies, the climb rates below are tweaked (higher) to
      --allow for more closely matched real-world performance.  Ideal generic target climb rates are:
      --  >> 0 - 10000 ft = 2200fpm
      --  >> 10000 - 20000ft = 2100fpm
      --  >> 20000 - 30000ft = 1700fpm
      if string.match(simConfigData["data"].PLANE.engines, "524G") then
        --V/S mode / use what the pilot has input on the MCP for V/S
        if B747DR_ap_FMA_active_pitch_mode == 7 then
          if B747DR_ap_vvi_fpm > 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm + 500
          elseif B747DR_ap_vvi_fpm <= 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm
          end

          if B747DR_airspeed_pilot < (simDR_ind_airspeed_kts_pilot - 3) then
            if last_climb_rate_fpm <= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm + 1, B747DR_ap_vvi_fpm + 1000)
            end
            climb_rate_fpm = last_climb_rate_fpm
          elseif B747DR_airspeed_pilot > simDR_ind_airspeed_kts_pilot then
            if last_climb_rate_fpm >= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm - 1, B747DR_ap_vvi_fpm)
            end
            climb_rate_fpm = last_climb_rate_fpm
          end
        elseif simDR_altitude < 10000 then
          climb_rate_fpm = 2750
        elseif simDR_altitude <= 20000 then
          climb_rate_fpm = B747_rescale(10000.0, 2750.0, 20000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          climb_rate_fpm = B747_rescale(20000.0, 2500.0, 30000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          climb_rate_fpm = B747_rescale(30000.0, 2250.0, 40000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2250
        end
      elseif string.match(simConfigData["data"].PLANE.engines, "524H") then
        --V/S mode / use what the pilot has input on the MCP for V/S
        if B747DR_ap_FMA_active_pitch_mode == 7 then
          if B747DR_ap_vvi_fpm > 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm + 500
          elseif B747DR_ap_vvi_fpm <= 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm
          end

          if B747DR_airspeed_pilot < (simDR_ind_airspeed_kts_pilot - 3) then
            if last_climb_rate_fpm <= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm + 1, B747DR_ap_vvi_fpm + 1000)
            end
            climb_rate_fpm = last_climb_rate_fpm
          elseif B747DR_airspeed_pilot > simDR_ind_airspeed_kts_pilot then
            if last_climb_rate_fpm >= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm - 1, B747DR_ap_vvi_fpm)
            end
            climb_rate_fpm = last_climb_rate_fpm
          end
        elseif simDR_altitude < 10000 then
          climb_rate_fpm = 2875
        elseif simDR_altitude <= 20000 then
          climb_rate_fpm = B747_rescale(10000.0, 2875.0, 20000.0, 2625.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          climb_rate_fpm = B747_rescale(20000.0, 2625.0, 30000.0, 2375.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          climb_rate_fpm = B747_rescale(30000.0, 2375.0, 40000.0, 2375.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2375
        end
      elseif string.match(simConfigData["data"].PLANE.engines, "524H8T") then
        --V/S mode / use what the pilot has input on the MCP for V/S
        if B747DR_ap_FMA_active_pitch_mode == 7 then
          if B747DR_ap_vvi_fpm > 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm + 500
          elseif B747DR_ap_vvi_fpm <= 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm
          end

          if B747DR_airspeed_pilot < (simDR_ind_airspeed_kts_pilot - 3) then
            if last_climb_rate_fpm <= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm + 1, B747DR_ap_vvi_fpm + 1000)
            end
            climb_rate_fpm = last_climb_rate_fpm
          elseif B747DR_airspeed_pilot > simDR_ind_airspeed_kts_pilot then
            if last_climb_rate_fpm >= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm - 1, B747DR_ap_vvi_fpm)
            end
            climb_rate_fpm = last_climb_rate_fpm
          end
        elseif simDR_altitude < 10000 then
          climb_rate_fpm = 3000
        elseif simDR_altitude <= 20000 then
          climb_rate_fpm = B747_rescale(10000.0, 3000.0, 20000.0, 2750.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          climb_rate_fpm = B747_rescale(20000.0, 2750.0, 30000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          climb_rate_fpm = B747_rescale(30000.0, 2500.0, 40000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2500
        end
      else  --Assume 524G if all else fails
        if B747DR_ap_FMA_active_pitch_mode == 7 then
          if B747DR_ap_vvi_fpm > 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm + 500
          elseif B747DR_ap_vvi_fpm <= 0 then
            climb_rate_fpm = B747DR_ap_vvi_fpm
          end

          if B747DR_airspeed_pilot < (simDR_ind_airspeed_kts_pilot - 3) then
            if last_climb_rate_fpm <= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm + 1, B747DR_ap_vvi_fpm + 1000)
            end
            climb_rate_fpm = last_climb_rate_fpm
          elseif B747DR_airspeed_pilot > simDR_ind_airspeed_kts_pilot then
            if last_climb_rate_fpm >= climb_rate_fpm then
              last_climb_rate_fpm = climb_rate_fpm
            else
              last_climb_rate_fpm = math.min(last_climb_rate_fpm - 1, B747DR_ap_vvi_fpm)
            end
            climb_rate_fpm = last_climb_rate_fpm
          end
        elseif simDR_altitude < 10000 then
          climb_rate_fpm = 2750
        elseif simDR_altitude <= 20000 then
          climb_rate_fpm = B747_rescale(10000.0, 2750.0, 20000.0, 2500.0, simDR_altitude)
        elseif simDR_altitude <= 30000 then
          climb_rate_fpm = B747_rescale(20000.0, 2500.0, 30000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 40000 then
          climb_rate_fpm = B747_rescale(30000.0, 2250.0, 40000.0, 2250.0, simDR_altitude)
        elseif simDR_altitude <= 50000 then
          climb_rate_fpm = 2250
        end
      end
  
      if fmc_alt >= (altitude_ft_in - 200) and B747DR_ref_thr_limit_mode == "CRZ" then
        climb_rate_fpm = 0
      end
  
      last_climb_rate_fpm = climb_rate_fpm

      climb_angle_deg = math.asin(0.00508 * climb_rate_fpm / tas_mtrs_sec) * 180 / math.pi
  
      --get in_flight_thrust() data
      _, thrust_per_engine_N, _, corrected_thrust_lbf = in_flight_thrust(simDR_acf_weight_total_kg, climb_angle_deg)
  
      EPR_corrected_thrust_N =   thrust_per_engine_N / (1000 * sigma_density_ratio)
      --EPR_corrected_thrust_N =   thrust_per_engine_N / (1000 * pressure_ratio)
      --EPR_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * EPR_corrected_thrust_N  --Sigma version 2
      EPR_corrected_thrust_calibrated_N = EPR_corrected_thrust_N  --no calibration needed

      --NEW RR EPR formula (11/3/21)
      RR_EPR_factor = B747_rescale(4.0, 1.00, 50.0, 1.05, EPR_corrected_thrust_N)
      EPR_actual = (2.8E-08 * mach^2 + 1.86E-08 * mach - 3.33E-08) * EPR_corrected_thrust_N^3 + (-0.0000143 * mach^2 - 9.38E-06 * mach + 7.32E-06)
        * EPR_corrected_thrust_N^2 + (0.0021 * mach^2 + 0.0015 * mach + 0.0029) * EPR_corrected_thrust_N + (-0.1773 * mach^2 - 0.0283 * mach + RR_EPR_factor)  --1.05)

      if simDR_TAT > -13.0 then
        RR_EPR_correction = (-13.0 - simDR_TAT) / 10 * 0.06
      else
        RR_EPR_correction = 0.0
      end

      --Calculate Initial Climb EPR
      if EPR_initial_climb == 0.0 then
        EPR_initial_climb = -4.38E-06 * simDR_altitude + 1.87 + RR_EPR_correction - 0.05  --reduce max climb by 0.05 EPR as a target for initial climb
      end

      --Calculate Max Climb EPR
      EPR_max_climb = -4.38E-06 * simDR_altitude + 1.87 + RR_EPR_correction

      --Keep the Initial and Max Climb values per the FCOM tables
      --if EPR_initial_climb > 1.50 then
      --  EPR_initial_climb = 1.50
      --end

      if EPR_max_climb > 1.90 then
        EPR_max_climb = 1.90
      end

      --Temporary correction until a better initial climb formula can be implemented
      if EPR_initial_climb > EPR_actual then
        EPR_initial_climb = EPR_actual
      end

      if B747DR_log_level >= 2 then
        print("\t\t\t\t\t<<<--- IN FLIGHT EPR (RR) --->>>")
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
  local N1_engine_start = {0.0, 0.0, 0.0, 0.0}
  local last_N1 = {0.0, 0.0, 0.0, 0.0}
  function N1_display_RR(altitude_ft_in, thrust_N_in, engine_in)
    local N1_corrected_rpm = 0.0
    local N1_pct = 0.0
    local N1_actual = 0.0
    local N1_corrected_thrust_calibrated_N = 0.0
    local N1_corrected_thrust_n = 0.0
    local N1_low_idle = 0.0
    local N1_idle_capture = 0.0
    local N1_zero_thrust = 0.0

    if N1_engine_start[engine_in] == nil then N1_engine_start[engine_in] = 0.0 end
    if last_N1[engine_in] == nil then last_N1[engine_in] = 0.0 end

    if simDR_engine_running[engine_in] == 0 and thrust_N_in >= 0.0  and simDR_engine_starter_status[engine_in] == 0 then
      thrust_N_in = last_thrust_n[engine_in]-25
    end

    if simDR_engine_running[engine_in] == 1 and last_thrust_n[engine_in] < thrust_N_in and last_thrust_n[engine_in] < 3500 then
      thrust_N_in = last_thrust_n[engine_in]
    end

    if thrust_N_in < 0.0 and simDR_engine_running[engine_in] == 1 then
      thrust_N_in = 0.0
    end
    N1_corrected_thrust_n = thrust_N_in / (1000 * sigma_density_ratio)
    --N1_corrected_thrust_n = thrust_N_in / (1000 * pressure_ratio)

    --N1_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * N1_corrected_thrust_n  --Sigma version 2
    N1_corrected_thrust_calibrated_N = N1_corrected_thrust_n  --no calibration needed

    N1_corrected_rpm = (0.0136 * mach^2 - 0.00905 * mach - 0.0107) * N1_corrected_thrust_calibrated_N^2 + (-5.84 * mach^2 + 0.512 * mach + 13.5) * N1_corrected_thrust_calibrated_N
      + (-508 * mach^2 + 1792.2 * mach + 1065.4)
    
    --N1_corrected_rpm = (0.0136 * mach^2 - 0.00905 * mach - 0.0107) * N1_corrected_thrust_calibrated_N^2 + (-5.84 * mach^2 + 0.512 * mach + 13.5) * N1_corrected_thrust_calibrated_N
    --  + (-508 * mach^2 + 1792.2 * mach + B747_rescale(0.0, 0.0, 750.0, 1065.4, simDR_rpm[engine_in]))  -- + 1065.4)

    N1_pct = N1_corrected_rpm / 3600 * 100 * math.sqrt(temperature_K / 288.15)

    --Engine Idle Logic (Minimum / Approach)
    N1_low_idle = engine_idle_control_RR(altitude_ft_in)
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

    if N1_actual < N1_low_idle and N1_corrected_rpm >= 1065.4 and simDR_engine_running[engine_in] == 1 then
      
      N1_actual = B747_animate_value(last_N1[engine_in],N1_low_idle,0,115,0.1) 
      --print(" pin N1_actual 2 "..N1_actual)
    elseif simDR_engine_running[engine_in] == 0 then
      N1_actual = B747_animate_value(last_N1[engine_in],simDR_N1[engine_in],0,115,0.1) 
      --print(" pin N1_actual 1 "..N1_actual.. " n1 "..simDR_N1[engine_in])
    end

    --Handle display of an engine startup
    if simDR_engine_running[engine_in] == 0 and simDR_engine_starter_status[engine_in] == 1 and last_thrust_n[engine_in] <= -37500 then
      if last_thrust_n[engine_in] < -50000 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] + 125
      elseif last_thrust_n[engine_in] < -40000 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] + 50  --+ 1000
      elseif last_thrust_n[engine_in] < -30000 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] + 5  --+ 500
      end
    elseif simDR_engine_running[engine_in] == 1 and last_thrust_n[engine_in] <= thrust_N_in and last_thrust_n[engine_in] < 3500 then
      last_thrust_n[engine_in] = last_thrust_n[engine_in] + 50  --+ 100
    --Handle display of an engine shutdown
    elseif simDR_engine_running[engine_in] == 0 and simDR_engine_starter_status[engine_in] == 0 and simDR_N1[engine_in] < 10 then
      thrust_N_in = last_thrust_n[engine_in]
      if N1_actual >= 20 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] - 75
      elseif N1_actual > 10 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] - 50
      elseif N1_actual > 0 then
        last_thrust_n[engine_in] = last_thrust_n[engine_in] - 25
      else
        last_thrust_n[engine_in] = -75000
      end
    else
      last_thrust_n[engine_in] = thrust_N_in
    end

    --Because of the way the N1 formula calculates based on thrust, this sends the correct value to the N2 & N3 functions during startup
    if simDR_engine_running[engine_in] == 0 and simDR_engine_starter_status[engine_in] == 1 or N1_pct < 51 then
      if (simDR_engine_running[engine_in] == 0 and simDR_engine_starter_status[engine_in] == 0) then
        if N1_engine_start[engine_in] > N1_actual then
          N1_engine_start[engine_in] = N1_engine_start[engine_in] - 0.1
        end
      else
        N1_engine_start[engine_in] = N1_pct
      end
      --print("<<<*** STARTUP ***>>>")
    elseif simDR_engine_running[engine_in] == 1 and N1_actual < N1_engine_start[engine_in] and N1_actual < N1_low_idle then
      N1_engine_start[engine_in] = N1_engine_start[engine_in] + 0.05
      --print("<<<### EXTENDED STARTUP ###>>> -- N1_engine_start = ", N1_engine_start[engine_in])
    end

    --Try to keep REVERSER N1 at or below 91% per the engine TCDS
    if simDR_onGround == 1 and math.max(simDR_reverser_on[0], simDR_reverser_on[1], simDR_reverser_on[2], simDR_reverser_on[3]) == 1 then
      if N1_actual > 91.0 then
        B747_setMaxThrust( simDR_thrust_max - 250)
      end
    elseif simDR_onGround == 1 and math.max(simDR_reverser_deploy_ratio[0], simDR_reverser_deploy_ratio[1], simDR_reverser_deploy_ratio[2], simDR_reverser_deploy_ratio[3]) > 0.0
      and math.max(simDR_reverser_deploy_ratio[0], simDR_reverser_deploy_ratio[1], simDR_reverser_deploy_ratio[2], simDR_reverser_deploy_ratio[3]) < 0.1
      and simDR_thrust_max ~= engine_max_thrust_n then
        B747_setMaxThrust(engine_max_thrust_n)
    end

    if B747DR_log_level >= 2 then
      print("----- N1 Display ----- "..engine_in)
      print("N1 Corrected Thrust = ", N1_corrected_thrust_n)
      print("N1 Calibrated Thrust = ", N1_corrected_thrust_calibrated_N)
      print("N1 Corrected RPM = ", N1_corrected_rpm)
      print("N1% = ", N1_pct)
      print("N1_idle = ", N1_low_idle)
      print("N1 Idle Capture = ", N1_idle_capture)
      print("N1 Actual = ", N1_actual)
      print("ENGINE RUNNING = ", simDR_engine_running[engine_in])
      print("Last Thrust In = ", last_thrust_n[engine_in])
      print("Last N1 = ", last_N1[engine_in])
      print("N1 Engine Start = ", N1_engine_start[engine_in])
    end

    last_N1[engine_in] = N1_actual

    return N1_actual
  end

  local last_N2 = {0.0, 0.0, 0.0, 0.0}
  function N2_display_RR(engine_N1_in, engine_in)
    local N2_display = 0.0
    local N1_low_idle = engine_idle_control_RR(simDR_altitude)

    if N1_engine_start[engine_in] == nil then N1_engine_start[engine_in] = 0.0 end

    --print("++++++ N2 Engine Start +++++  N1-in -> ", engine_N1_in, N1_engine_start[engine_in])

    --Handle display of engine startup
    if (simDR_engine_running[engine_in] == 0 and simDR_engine_starter_status[engine_in] == 1)
      or (simDR_engine_running[engine_in] == 1 and (engine_N1_in < N1_engine_start[engine_in] and engine_N1_in < N1_low_idle) or (engine_N1_in < 51)) then
      engine_N1_in = N1_engine_start[engine_in]
    end

    N2_display_target = 0.0000663 * engine_N1_in^3 - 0.0163 * engine_N1_in^2 + 1.94 * engine_N1_in
    
    if last_N2[engine_in] == nil then last_N2[engine_in] = 0.0 end
    if (simDR_engine_running[engine_in] == 0 or simDR_N2[engine_in]<35) then
      N2_display = B747_animate_value(last_N2[engine_in],simDR_N2[engine_in],0,115,0.1) 
    elseif N2_display < simDR_N2[engine_in] then --and N2_display < 30.0 then
      N2_display = B747_animate_value(last_N2[engine_in],simDR_N2[engine_in],0,115,0.1)
    else
      N2_display = B747_animate_value(last_N2[engine_in],N2_display_target,0,115,10)
    end
    
    if B747DR_log_level >= 2 then
      print("----- N2 Display -----")
      print("N1 in, N2 = ", engine_N1_in, N2_display)
      print("************ LAST N2 = ", last_N2[engine_in])
    end

    last_N2[engine_in] = N2_display

    return N2_display
  end

  local last_N3 = {0.0, 0.0, 0.0, 0.0}
  function N3_display_RR(engine_N1_in, engine_in)
    local N3_display = 0.0
    local N1_low_idle = engine_idle_control_RR(simDR_altitude)

    --Handle display of engine startup
    if (simDR_engine_running[engine_in] == 0 and simDR_engine_starter_status[engine_in] == 1)
      or (simDR_engine_running[engine_in] == 1 and (engine_N1_in < N1_engine_start[engine_in] and engine_N1_in < N1_low_idle) or (engine_N1_in < 51)) then
      engine_N1_in = N1_engine_start[engine_in]
    end

    N3_display = 0.000164 * engine_N1_in^3 - 0.035 * engine_N1_in^2 + 2.8 * engine_N1_in
    
    if last_N3[engine_in] == nil then last_N3[engine_in] = 0.0 end

    if B747DR_log_level >= 2 then
      print("----- N3 Display -----")
      print("N1 in, N3 = ", engine_N1_in, N3_display)
      print("************ LAST N3 = ", last_N3[engine_in])
    end

    last_N3[engine_in] = N3_display

    return N3_display
  end

  function EPR_display_RR(altitude_ft_in, thrust_N_in, engine_in)
      local EPR_actual = 0.0
      local EPR_corrected_thrust_N = 0.0
      local EPR_corrected_thrust_calibrated_N = 0.0
      local RR_EPR_factor = 1.00

      if last_thrust_n[engine_in] == nil then
        last_thrust_n[engine_in] = 0.0
      end

      EPR_corrected_thrust_N = thrust_N_in / (1000 * sigma_density_ratio)
      --EPR_corrected_thrust_N = thrust_N_in / (1000 * pressure_ratio)
    
      --EPR_corrected_thrust_calibrated_N = (-0.4795 * mach^2 + 0.5903 * mach + 0.925) * EPR_corrected_thrust_N  --Sigma version 2
      EPR_corrected_thrust_calibrated_N = EPR_corrected_thrust_N

      --NEW RR EPR formula (11/3/21)
      RR_EPR_factor = B747_rescale(4.0, 1.00, 50.0, 1.05, EPR_corrected_thrust_N)
      EPR_actual = (2.8E-08 * mach^2 + 1.86E-08 * mach - 3.33E-08) * EPR_corrected_thrust_N^3 + (-0.0000143 * mach^2 - 9.38E-06 * mach + 7.32E-06)
        * EPR_corrected_thrust_N^2 + (0.0021 * mach^2 + 0.0015 * mach + 0.0029) * EPR_corrected_thrust_N + (-0.1773 * mach^2 - 0.0283 * mach + RR_EPR_factor)  --1.05)
      
      --Ensure EPR doesn't drop to an unrealistic value during IDLE descent.  This also ensures that the EPR tapes don't fall off the display.
      if EPR_actual < 0.97 then
        EPR_actual = 0.97
      --try to combat the formula issue where EPR increases due to mach rising faster than thrust decreases during TO
    elseif B747DR_ref_thr_limit_mode ~= "GA" and simDR_flap_ratio > 0.0 then
      if EPR_actual > B747DR_display_EPR_max[engine_in] then
        EPR_actual = B747DR_display_EPR_max[engine_in]
      end
    end

      if B747DR_log_level >= 2 then
        print("\t\t\t\t\t<<<--- EPR DISPLAY (RR) --->>>".."\t\tEngine # "..engine_in + 1)
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

  function EGT_display_RR(engine_in)
    local EGT_display = 0.0
  
    if simDR_engn_EGT_c[engine_in] <= simDR_temperature then
      EGT_display = simDR_temperature
    else
      EGT_display = B747_rescale(0.0, 0.0, 960, 785, simDR_engn_EGT_c[engine_in])--simDR_engn_EGT_c[engine_in]
    end
  
    if B747DR_log_level >= 2 then
      print("EGT = "..engine_in.." ".. EGT_display)
    end
  
    return EGT_display
  end
  
  local orig_thrust_n = 0.0
  function RR(altitude_ft_in)
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
    local N3_display = {}
    local EGT_display = {}
    local target_weight = 0.0
    local target_alt = 0.0
    local RR_EPR_correction = 0.0
  
    --In-flight variables
    local EPR_actual = 0.0
    local EPR_target_bug = {}
    local display_EPR_ref = {}
    local display_EPR_max = {}
    for i = 0, 3 do
      EPR_target_bug[i] = simDR_EPR_target_bug[i]
      display_EPR_ref[i] = B747DR_display_EPR_ref[i]
      display_EPR_max[i] = B747DR_display_EPR_max[i]
    end
    --Setup engine factors based on engine type
    if string.match(simConfigData["data"].PLANE.engines, "524G") then
      engine_max_thrust_n = 258000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(258000)  --252970  --(56870 lbf)
        simDR_reverser_max = 0.75
      end
      simDR_compressor_area = 3.54136  --(86.3-inch fan -- 38.12 sq. ft)
    elseif string.match(simConfigData["data"].PLANE.engines, "524H") then
      engine_max_thrust_n = 270000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(270000)  --264450  --(59450 lbf)
        simDR_reverser_max = 0.75
      end
      simDR_compressor_area = 3.54136  --(86.3-inch fan -- 38.12 sq. ft)
    elseif string.match(simConfigData["data"].PLANE.engines, "524H8T")  then
      engine_max_thrust_n = 270000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust( 270000 ) --264450  --(59450 lbf)
        simDR_reverser_max = 0.75
      end
      simDR_compressor_area = 3.54136  --(86.3-inch fan -- 38.12 sq. ft)
    else  --Assume 524G if all else fails
      engine_max_thrust_n = 258000
      simDR_throttle_max = 1.0
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        B747_setMaxThrust(258000)  --252970  --(56870 lbf)
        simDR_reverser_max = 0.75
      end
      simDR_compressor_area = 3.54136  --(86.3-inch fan -- 48.19 sq. ft)
    end

    --Find current altitude rounded to the closest 1000 feet (for use in table lookups)
    altitude = round_thrustcalc(altitude_ft_in, "ALT")
  
      --Packs Adjustment
    nbr_packs_on = B747DR_pack_ctrl_sel_pos[0] + B747DR_pack_ctrl_sel_pos[1] + B747DR_pack_ctrl_sel_pos[2]
  
    if nbr_packs_on == 0 then
        packs_adjustment_value = 0.01
    elseif nbr_packs_on == 1 then
        packs_adjustment_value = 0.01
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
        takeoff_thrust_epr, _ = take_off_EPR_RR(altitude_ft_in)
    
      if B747DR_toderate == 0 then
        takeoff_TOGA_epr = takeoff_thrust_epr
      end

      takeoff_thrust_epr_throttle = B747_rescale(0.0, 0.0, tonumber(takeoff_TOGA_epr), 1.0, tonumber(takeoff_thrust_epr))
      
      -- Set EPR Target Bugs & Reference Indicator
      --Due to display issues on the EICAS, keep the REF and MAX limit lines at a max of 1.90 otherwise they get painted above the EPR tape
      for i = 0, 3 do
        EPR_target_bug[i] = string.format("%3.2f",takeoff_thrust_epr) + packs_adjustment_value + engine_anti_ice_adjustment_value
        display_EPR_ref[i] = math.min(string.format("%3.2f",takeoff_thrust_epr) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.90)
        display_EPR_max[i] = math.min(string.format("%3.2f",takeoff_thrust_epr) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.90)
      end

      B747DR_TO_throttle = takeoff_thrust_epr_throttle
    end
  
    if simDR_TAT > -13.0 then
      RR_EPR_correction = (-13.0 - simDR_TAT) / 10 * 0.06
    else
      RR_EPR_correction = 0.0
    end

    if string.match(B747DR_ref_thr_limit_mode, "TO") or B747DR_ref_thr_limit_mode == "" then
      --Store original max engine output
      
      if orig_thrust_n == 0.0 or B747DR_newsimconfig_data == 1 then
        orig_thrust_n = simDR_thrust_max
      end
    elseif string.match(B747DR_ref_thr_limit_mode, "CLB") then
      EPR_actual, EPR_initial_climb, EPR_max_climb = in_flight_EPR_RR(altitude_ft_in, 0)
  
        --Set target bugs
      for i = 0, 3 do
        if EPR_actual > EPR_max_climb then
          if EPR_initial_climb > EPR_max_climb then
            EPR_target_bug[i] = string.format("%3.2f", EPR_initial_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value
            display_EPR_ref[i] = math.min(string.format("%3.2f", EPR_initial_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.90)
          else
            EPR_target_bug[i] = string.format("%3.2f", EPR_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value
            display_EPR_ref[i] = math.min(string.format("%3.2f", EPR_max_climb) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.90)
          end
        else
          EPR_target_bug[i] = string.format("%3.2f", EPR_actual) + packs_adjustment_value + engine_anti_ice_adjustment_value
          display_EPR_ref[i] = math.min(string.format("%3.2f", EPR_actual) + packs_adjustment_value + engine_anti_ice_adjustment_value, 1.90)
        end

        if B747DR_display_EPR_max[i] < B747DR_display_EPR_ref[i] then
          display_EPR_max[i] = B747DR_display_EPR_ref[i]
        end
      end
    elseif string.match(B747DR_ref_thr_limit_mode, "CRZ") then
      EPR_actual, _, EPR_max_climb = in_flight_EPR_RR(altitude_ft_in, 0)

      target_weight = find_closest_weight(P85M_epr_RR, math.ceil(simDR_acf_weight_total_kg / 1000))
      target_alt = find_closest_altitude(P85M_epr_RR, math.ceil(altitude_ft_in / 1000))

      EPR_max_cruise = P85M_epr_RR[target_weight][target_alt]

      --Set target bugs
      for i = 0, 3 do
          EPR_target_bug[i] = string.format("%3.2f", EPR_max_cruise) + packs_adjustment_value + engine_anti_ice_adjustment_value
          display_EPR_ref[i] = string.format("%3.2f", EPR_max_cruise) + packs_adjustment_value + engine_anti_ice_adjustment_value
          display_EPR_max[i] = EPR_max_climb  --simDR_EPR_target_bug[i]
      end

      if B747DR_log_level >= 2 then
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
        if simDR_TAT < 5 then
          EPR_target_bug[i] = -7.640000000000001E-10 * altitude_ft_in^2 + 0.000014 * altitude_ft_in + 1.7078
        else
          if simDR_TAT > 39 then
            EPR_target_bug[i] = -0.00504 * simDR_TAT + 1.84
          else
            EPR_target_bug[i] = (3.81E-12 * simDR_TAT^2 - 1.39E-10 * simDR_TAT - 1.08E-10) * altitude_ft_in^2 + (-2.91E-08 * simDR_TAT^2 + 7.24E-07 * simDR_TAT + 0.0000111)
                                      * altitude_ft_in + (-0.0000727 * simDR_TAT^2 + 0.0022 * simDR_TAT + 1.7)
          end
        end
        display_EPR_ref[i] = math.min(simDR_EPR_target_bug[i], 1.90)
        display_EPR_max[i] = math.min(simDR_EPR_target_bug[i], 1.90)
      end
    end

    --Handle minor engine thrust differences where calculated (requested) thrust is less than the defined XP engine model can produce
    --Boost engine output as necessary
    if math.max(simDR_engn_thro_use[0], simDR_engn_thro_use[1], simDR_engn_thro_use[2], simDR_engn_thro_use[3]) == 1
      and math.max(simDR_N1[0], simDR_N1[1], simDR_N1[2], simDR_N1[3]) > 99.99
      and (B747DR_display_EPR[0] < simDR_EPR_target_bug[0] or B747DR_display_EPR[1] < simDR_EPR_target_bug[1]
          or B747DR_display_EPR[2] < simDR_EPR_target_bug[2] or B747DR_display_EPR[3] < simDR_EPR_target_bug[3]) --then
      and math.max(simDR_EPR_target_bug[0] - B747DR_display_EPR[0], simDR_EPR_target_bug[1] - B747DR_display_EPR[1], simDR_EPR_target_bug[2] - B747DR_display_EPR[2],
                    simDR_EPR_target_bug[3] - B747DR_display_EPR[3]) > 0.045 then  --set a tolerance to ensure the engines don't overboost unnecessarily
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

    --Failsafe option in case takeoff_thrust_epr isn't set
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
      EPR_display[i] = math.min(EPR_display_RR(altitude_ft_in, simDR_thrust_n[i], i), 1.90)--string.format("%3.2f", math.min(EPR_display_RR(altitude_ft_in, simDR_thrust_n[i], i), 1.90))  --use i as a reference for engine number
      B747DR_display_EPR[i] = math.max(EPR_display[i], 0.0)

      N1_display[i] = string.format("%4.1f", math.min(N1_display_RR(altitude_ft_in, simDR_thrust_n[i], i), 112.5))
      B747DR_display_N1[i] = math.max(N1_display[i], 0.0)

      N2_display[i] = string.format("%3.0f", math.min(N2_display_RR(B747DR_display_N1[i], i), 111.5))
      B747DR_display_N2[i] = math.max(N2_display[i], 0.0)

      N3_display[i] = string.format("%4.1f", math.min(N3_display_RR(B747DR_display_N1[i], i), 102.5))
      B747DR_display_N3[i] = math.max(N3_display[i], 0.0)
     -- print("RR EGT 1 "..i.." "..B747DR_display_EGT[i])
      EGT_display[i] = EGT_display_RR(i)
      B747DR_display_EGT[i] = egt_thermal_profile(EGT_display[i],i,B747DR_display_EGT[i])--math.max(EGT_display[i], 0.0)
     -- print("RR EGT 2 "..i.." "..B747DR_display_EGT[i])
      B747DR_throttle_resolver_angle[i] = throttle_resolver_angle_RR(i)

    end
  
    if B747DR_log_level >= 2 then
      print("Takeoff TOGA = ", takeoff_TOGA_epr)
    end
    --Manage Thrust
    throttle_management()
  end