--[[
*****************************************************************************************
*        COPYRIGHT � 2020 Mark Parker/mSparks
*****************************************************************************************
xt.hydraulicsmodel.lua
27/04/2020
]]
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end

function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
B747DR_button_switch_position   = find_dataref("laminar/B747/button_switch/position")
simDR_engine_N1_pct             = find_dataref("sim/cockpit2/engine/indicators/N1_percent")
B747_duct_pressure_L                = deferred_dataref("laminar/B747/air/duct_pressure_L", "number")
B747_duct_pressure_R                = deferred_dataref("laminar/B747/air/duct_pressure_R", "number")
--B747DR_engine1psi    = deferred_dataref("laminar/B747/air/engine1/bleed_air_psi", "number")
--B747DR_engine4psi    = deferred_dataref("laminar/B747/air/engine4/bleed_air_psi", "number")
simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")
B747DR_hyd_temp = find_dataref("sim/physics/earth_temp_c")
B747DR_hyd_sys_pressure_1      = deferred_dataref("laminar/B747/hydraulics/pressure_1", "number")
B747DR_hyd_sys_pressure_2      = deferred_dataref("laminar/B747/hydraulics/pressure_2", "number")
B747DR_hyd_sys_pressure_3      = deferred_dataref("laminar/B747/hydraulics/pressure_3", "number")
B747DR_hyd_sys_pressure_4      = deferred_dataref("laminar/B747/hydraulics/pressure_4", "number")
B747DR_hyd_sys_pressure_12      = deferred_dataref("laminar/B747/hydraulics/pressure_12", "number")
B747DR_hyd_sys_pressure_23      = deferred_dataref("laminar/B747/hydraulics/pressure_23", "number")
B747DR_hyd_sys_pressure_24      = deferred_dataref("laminar/B747/hydraulics/pressure_24", "number")
B747DR_hyd_sys_pressure_234      = deferred_dataref("laminar/B747/hydraulics/pressure_234", "number")
B747DR_hyd_sys_pressure_use_1      = deferred_dataref("laminar/B747/hydraulics/pressure_use_1", "number")
B747DR_hyd_sys_pressure_use_2      = deferred_dataref("laminar/B747/hydraulics/pressure_use_2", "number")
B747DR_hyd_sys_pressure_use_3      = deferred_dataref("laminar/B747/hydraulics/pressure_use_3", "number")
B747DR_hyd_sys_pressure_use_4      = deferred_dataref("laminar/B747/hydraulics/pressure_use_4", "number")

B747DR_hyd_sys_temp_1      = deferred_dataref("laminar/B747/hydraulics/temp_1", "number")
B747DR_hyd_sys_temp_2      = deferred_dataref("laminar/B747/hydraulics/temp_2", "number")
B747DR_hyd_sys_temp_3      = deferred_dataref("laminar/B747/hydraulics/temp_3", "number")
B747DR_hyd_sys_temp_4      = deferred_dataref("laminar/B747/hydraulics/temp_4", "number")

B747DR_hyd_sys_res_1      = deferred_dataref("laminar/B747/hydraulics/res_1", "number")
B747DR_hyd_sys_res_2      = deferred_dataref("laminar/B747/hydraulics/res_2", "number")
B747DR_hyd_sys_res_3      = deferred_dataref("laminar/B747/hydraulics/res_3", "number")
B747DR_hyd_sys_res_4      = deferred_dataref("laminar/B747/hydraulics/res_4", "number")

B747DR_hyd_sys_restotal_1      = deferred_dataref("laminar/B747/hydraulics/restotal_1", "number")
B747DR_hyd_sys_restotal_2      = deferred_dataref("laminar/B747/hydraulics/restotal_2", "number")
B747DR_hyd_sys_restotal_3      = deferred_dataref("laminar/B747/hydraulics/restotal_3", "number")
B747DR_hyd_sys_restotal_4      = deferred_dataref("laminar/B747/hydraulics/restotal_4", "number")

B747DR_hyd_dem_pressure_1      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_1", "number")
B747DR_hyd_dem_pressure_2      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_2", "number")
B747DR_hyd_dem_pressure_3      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_3", "number")
B747DR_hyd_dem_pressure_4      = deferred_dataref("laminar/B747/hydraulics/dem_pressure_4", "number")

B747DR_hyd_edp_pressure_1      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_1", "number")
B747DR_hyd_edp_pressure_2      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_2", "number")
B747DR_hyd_edp_pressure_3      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_3", "number")
B747DR_hyd_edp_pressure_4      = deferred_dataref("laminar/B747/hydraulics/edp_pressure_4", "number")
B747DR_hyd_aux_pressure      = deferred_dataref("laminar/B747/hydraulics/aux_pressure", "number")

B747DR_hyd_dem_mode_1      = deferred_dataref("laminar/B747/hydraulics/dem_mode_1", "number")--off auto on
B747DR_hyd_dem_mode_2      = deferred_dataref("laminar/B747/hydraulics/dem_mode_2", "number")
B747DR_hyd_dem_mode_3      = deferred_dataref("laminar/B747/hydraulics/dem_mode_3", "number")
B747DR_hyd_dem_mode_4      = deferred_dataref("laminar/B747/hydraulics/dem_mode_4", "number")-- -1 aux off auto on
-- CRT Displays/EICAS Lower/HYD/valve_on
B747DR_hyd_valve_1      = deferred_dataref("laminar/B747/hydraulics/valve_1", "number")
B747DR_hyd_valve_2      = deferred_dataref("laminar/B747/hydraulics/valve_2", "number")
B747DR_hyd_valve_3      = deferred_dataref("laminar/B747/hydraulics/valve_3", "number")
B747DR_hyd_valve_4      = deferred_dataref("laminar/B747/hydraulics/valve_4", "number")
simDR_hyd_press_1_2               = deferred_dataref("laminar/B747/hydraulics/indicators/hydraulic_pressure_1_2_4", "number")
--simDR_hyd_press_2               = find_dataref("sim/cockpit2/hydraulics/indicators/hydraulic_pressure_2")


B747DR_hyd_dmd_pmp_sel_pos      = deferred_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos", "array[4]")
function B747_animate_value(current_value, target, min, max, speed)

    local fps_factor = math.min(0.1, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end

function B747_engine_hyd_valves()
-- ENGINE #1
    if B747DR_button_switch_position[30] > 0.95 then
        B747DR_hyd_valve_1 = 1
    elseif B747DR_button_switch_position[30] < 0.05 then
        B747DR_hyd_valve_1  = 0
    end


    -- ENGINE #2
    if B747DR_button_switch_position[31] > 0.95 then
        B747DR_hyd_valve_2  = 1
    elseif B747DR_button_switch_position[31] < 0.05 then
        B747DR_hyd_valve_2  = 0
    end


    -- ENGINE #3
    if B747DR_button_switch_position[32] > 0.95 then
        B747DR_hyd_valve_3  = 1
    elseif B747DR_button_switch_position[32] < 0.05 then
        B747DR_hyd_valve_3  = 0
    end


    -- ENGINE #4
    if B747DR_button_switch_position[33] > 0.95 then
        B747DR_hyd_valve_4  = 1
    elseif B747DR_button_switch_position[33] < 0.05 then
        B747DR_hyd_valve_4  = 0
    end
end
function B747_engine_dem_modes()
  
  B747DR_hyd_dem_mode_1=B747DR_hyd_dmd_pmp_sel_pos[0]
  B747DR_hyd_dem_mode_2=B747DR_hyd_dmd_pmp_sel_pos[1]
  B747DR_hyd_dem_mode_3=B747DR_hyd_dmd_pmp_sel_pos[2]
  B747DR_hyd_dem_mode_4=B747DR_hyd_dmd_pmp_sel_pos[3]
  
end
function B747_edp_pressures()
    if B747DR_hyd_valve_1==1 then
      B747DR_hyd_edp_pressure_1=30*simDR_engine_N1_pct[0]
    else
      B747DR_hyd_edp_pressure_1=0;
    end
    
    if B747DR_hyd_valve_2==1 then
      B747DR_hyd_edp_pressure_2=30*simDR_engine_N1_pct[1]
    else
      B747DR_hyd_edp_pressure_2=0;
    end
    
    if B747DR_hyd_valve_3==1 then
      B747DR_hyd_edp_pressure_3=30*simDR_engine_N1_pct[2]
    else
      B747DR_hyd_edp_pressure_3=0;
    end
    
    if B747DR_hyd_valve_4==1 then
      B747DR_hyd_edp_pressure_4=30*simDR_engine_N1_pct[3]
    else
      B747DR_hyd_edp_pressure_4=0;
    end
end

function B747_dem_pressures()
  if B747DR_hyd_dem_mode_1>0 then 
    if B747DR_hyd_dem_mode_1==2 then
      B747DR_hyd_dem_pressure_1=B747_duct_pressure_L*175
    elseif B747DR_hyd_edp_pressure_1<2000 then
      B747DR_hyd_dem_pressure_1=B747_duct_pressure_L*175
    else
      B747DR_hyd_dem_pressure_1=0
    end
  else
     B747DR_hyd_dem_pressure_1=0  
  end
  
  
  if B747DR_hyd_dem_mode_2>0 then
    if B747DR_hyd_dem_mode_2==2 then
      B747DR_hyd_dem_pressure_2=3000
    elseif B747DR_hyd_edp_pressure_2<2000 then
      B747DR_hyd_dem_pressure_2=3000
    else
      B747DR_hyd_dem_pressure_2=0
    end
   else
     B747DR_hyd_dem_pressure_2=0 
  end
 
  if B747DR_hyd_dem_mode_3>0 then
    if B747DR_hyd_dem_mode_3==2 then
      B747DR_hyd_dem_pressure_3=3000
    elseif B747DR_hyd_edp_pressure_3<2000 then
      B747DR_hyd_dem_pressure_3=3000
    else
      B747DR_hyd_dem_pressure_3=0
    end
   else
     B747DR_hyd_dem_pressure_3=0
  end
  
  if B747DR_hyd_dem_mode_4>0 then
    if B747DR_hyd_dem_mode_4==2 then
      B747DR_hyd_dem_pressure_4=B747_duct_pressure_R*175
    elseif B747DR_hyd_edp_pressure_4<2000 then
      B747DR_hyd_dem_pressure_4=B747_duct_pressure_R*175
    else
      B747DR_hyd_dem_pressure_4=0
    end
    elseif B747DR_hyd_dem_mode_4<0 then
     B747DR_hyd_aux_pressure=2950
     B747DR_hyd_dem_pressure_4=0
    else
     B747DR_hyd_dem_pressure_4=0
     B747DR_hyd_aux_pressure=0
  end
  
end
function B747_system_pressures()
  --B747_animate_value(B747DR_hyd_sys_pressure_1,math.max(B747DR_hyd_dem_pressure_1,B747DR_hyd_edp_pressure_1),0,3000,1)
  B747DR_hyd_sys_pressure_use_1=B747_animate_value(B747DR_hyd_sys_pressure_use_1,((B747DR_hyd_dem_pressure_1/2+B747DR_hyd_edp_pressure_1)/10)-50,-10,30,1)--math.max(B747DR_hyd_dem_pressure_1,B747DR_hyd_edp_pressure_1)
  B747DR_hyd_sys_pressure_use_2=B747_animate_value(B747DR_hyd_sys_pressure_use_2,((B747DR_hyd_dem_pressure_2+B747DR_hyd_edp_pressure_2)/10)-50,-10,30,1)--math.max(B747DR_hyd_dem_pressure_2,B747DR_hyd_edp_pressure_2)
  B747DR_hyd_sys_pressure_use_3=B747_animate_value(B747DR_hyd_sys_pressure_use_3,((B747DR_hyd_dem_pressure_3+B747DR_hyd_edp_pressure_3)/10)-50,-10,30,1)--math.max(B747DR_hyd_dem_pressure_3,B747DR_hyd_edp_pressure_3)
  B747DR_hyd_sys_pressure_use_4=B747_animate_value(B747DR_hyd_sys_pressure_use_4,((B747DR_hyd_dem_pressure_4/2+B747DR_hyd_edp_pressure_4+B747DR_hyd_aux_pressure)/10)-50,-10,30,1)--math.max(B747DR_hyd_dem_pressure_4,B747DR_hyd_edp_pressure_4,B747DR_hyd_aux_pressure)
  
  --sys_pressure_use now contains how much pressure we can put into the system
  B747DR_hyd_sys_pressure_1=B747_animate_value(B747DR_hyd_sys_pressure_1,B747DR_hyd_sys_pressure_1+B747DR_hyd_sys_pressure_use_1,0,3000-math.random()*50,1)
  B747DR_hyd_sys_pressure_2=B747_animate_value(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_2+B747DR_hyd_sys_pressure_use_2,0,3000-math.random()*50,1)
  B747DR_hyd_sys_pressure_3=B747_animate_value(B747DR_hyd_sys_pressure_3,B747DR_hyd_sys_pressure_3+B747DR_hyd_sys_pressure_use_3,0,3000-math.random()*50,1)
  B747DR_hyd_sys_pressure_4=B747_animate_value(B747DR_hyd_sys_pressure_4,B747DR_hyd_sys_pressure_4+B747DR_hyd_sys_pressure_use_4,0,3000-math.random()*50,1)
  B747DR_hyd_sys_pressure_12=math.max(B747DR_hyd_sys_pressure_1,B747DR_hyd_sys_pressure_2)
  B747DR_hyd_sys_pressure_23=math.max(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_3)
  B747DR_hyd_sys_pressure_24=math.max(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_4)
  B747DR_hyd_sys_pressure_234=math.max(B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_3,B747DR_hyd_sys_pressure_4)
  B747DR_hyd_sys_res_1=B747DR_hyd_sys_restotal_1-(B747DR_hyd_sys_pressure_1/3000)*0.1
  B747DR_hyd_sys_res_2=B747DR_hyd_sys_restotal_2-(B747DR_hyd_sys_pressure_2/3000)*0.1
  B747DR_hyd_sys_res_3=B747DR_hyd_sys_restotal_3-(B747DR_hyd_sys_pressure_3/3000)*0.1
  B747DR_hyd_sys_res_4=B747DR_hyd_sys_restotal_4-(B747DR_hyd_sys_pressure_4/3000)*0.1
  simDR_hyd_press_1_2 = math.max(B747DR_hyd_sys_pressure_1,B747DR_hyd_sys_pressure_2,B747DR_hyd_sys_pressure_4)

  B747DR_hyd_sys_temp_1=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_1)*20
  B747DR_hyd_sys_temp_2=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_2)*20
  B747DR_hyd_sys_temp_3=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_3)*20
  B747DR_hyd_sys_temp_4=B747DR_hyd_temp+(1-B747DR_hyd_sys_res_4)*20
end
--*************************************************************************************--
--**                          EVENT CALLBACKS                        **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end
function B747_set_hyd_model_ER()
  B747DR_hyd_sys_pressure_use_1=1700
  B747DR_hyd_sys_pressure_use_2=1700
  B747DR_hyd_sys_pressure_use_3=1700
  B747DR_hyd_sys_pressure_use_4=1700
  B747DR_hyd_sys_pressure_1=1700
  B747DR_hyd_sys_pressure_2=1700
  B747DR_hyd_sys_pressure_3=1700
  B747DR_hyd_sys_pressure_4=1700
end  
function flight_start() 
    B747DR_hyd_sys_restotal_1=math.random()*0.2+0.8
    B747DR_hyd_sys_restotal_2=math.random()*0.2+0.8
    B747DR_hyd_sys_restotal_3=math.random()*0.2+0.8
    B747DR_hyd_sys_restotal_4=math.random()*0.2+0.8
    B747DR_hyd_sys_res_1=B747DR_hyd_sys_restotal_1
    B747DR_hyd_sys_res_2=B747DR_hyd_sys_restotal_2
    B747DR_hyd_sys_res_3=B747DR_hyd_sys_restotal_3
    B747DR_hyd_sys_res_4=B747DR_hyd_sys_restotal_4

    B747DR_hyd_sys_temp_1=B747DR_hyd_temp
    B747DR_hyd_sys_temp_2=B747DR_hyd_temp
    B747DR_hyd_sys_temp_3=B747DR_hyd_temp
    B747DR_hyd_sys_temp_4=B747DR_hyd_temp
    if simDR_startup_running == 1 then

		B747_set_hyd_model_ER() -- pressurise the system if engines start running

    end
end

--function flight_crash() end

--function before_physics() end
debug_hydro     = deferred_dataref("laminar/B747/debug/hydro", "number")
function after_physics()
  if debug_hydro>0 then return end
   B747_engine_hyd_valves()
   B747_engine_dem_modes()
   B747_edp_pressures()
   B747_dem_pressures()
   B747_system_pressures()
end

--function after_replay() end