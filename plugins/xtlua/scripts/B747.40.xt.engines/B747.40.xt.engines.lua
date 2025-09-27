--[[
*****************************************************************************************
* Program Script Name	:	B747.40.engines
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2016-04-26	0.01a				Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED	        *
*****************************************************************************************
--]]

--Marauder28
dofile("json/json.lua")


--*************************************************************************************--
--** 					              XLUA GLOBALS              				     **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]


--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

--NUM_THRUST_LEVERS = 5




--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--
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
local B747_hold_rev_on_engine		= {0, 0, 0, 0}
local B747_hold_rev_on_all			= 0

--local B747_igniter_status = {0, 0, 0, 0}
local B747_ignition_startup_flag = {1, 1, 1, 1}

math.randomseed(os.time())
local B747_eng1oilStart = math.random(28, 31) * 1.18
local B747_eng2oilStart = math.random(28, 31) * 1.18
local B747_eng3oilStart = math.random(28, 31) * 1.18
local B747_eng4oilStart = math.random(28, 31) * 1.18
local B747_eng1startupOilTxfr = math.random(7, 11) + (math.random()*0.10)
local B747_eng2startupOilTxfr = math.random(7, 11) + (math.random()*0.10)
local B747_eng3startupOilTxfr = math.random(7, 11) + (math.random()*0.10)
local B747_eng4startupOilTxfr = math.random(7, 11) + (math.random()*0.10)

local B747_eng1oilPressVariance = math.random(1, 6) + (math.random()*0.10)
local B747_eng2oilPressVariance = math.random(1, 6) + (math.random()*0.10)
local B747_eng3oilPressVariance = math.random(1, 6) + (math.random()*0.10)
local B747_eng4oilPressVariance = math.random(1, 6) + (math.random()*0.10)

local B747_eng1oilTempVariance = math.random(1, 10) + (math.random()*0.10)
local B747_eng2oilTempVariance = math.random(1, 10) + (math.random()*0.10)
local B747_eng3oilTempVariance = math.random(1, 10) + (math.random()*0.10)
local B747_eng4oilTempVariance = math.random(1, 10) + (math.random()*0.10)

local B747_ref_thr_limit_mode = "NONE"
local B747_ref_thr_limit = {
    ["NONE"]    = 0.00,
    ["TO"]      = 1.40,
    ["TO1"]     = 1.00,
    ["TO2"]     = 1.00,
    ["D-TO"]    = 1.00,
    ["D-TO1"]   = 1.00,
    ["D-TO2"]   = 1.00,
    ["CLB"]     = 1.00,
    ["CLB1"]    = 1.00,
    ["CLB2"]    = 1.00,
    ["CRZ"]     = 1.00,
    ["CON"]     = 1.00,
    ["GA"]      = 1.00
}
toderate=deferred_dataref("laminar/B747/engine/derate/TO","number") 

throttlederate=find_dataref("sim/aircraft/engine/acf_throtmax_FWD")
simDR_version=find_dataref("sim/version/xplane_internal_version")
--Simulator Config Options
simConfigData = {}

--*************************************************************************************--
--** 				              FIND X-PLANE DATAREFS              		    	 **--
--*************************************************************************************--
B747DR_display_EGT					= deferred_dataref("laminar/B747/engines/display_EGT", "array[4]")
simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")
simDR_radarAlt1           	= find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
simDR_all_wheels_on_ground      = find_dataref("sim/flightmodel/failures/onground_any")
simDR_reallyall_wheels_on_ground      = find_dataref("sim/flightmodel/failures/onground_all")
simDR_thrust_rev_deploy_ratio   = find_dataref("sim/flightmodel2/engines/thrust_reverser_deploy_ratio")
simDR_autoReverse=find_dataref("sim/cockpit2/switches/auto_reverse_on")
B747DR_speedbrake_lever     	= find_dataref("laminar/B747/flt_ctrls/speedbrake_lever")
B747DR_reverser_lockout            = deferred_dataref("laminar/B747/engines/reverser_lockout", "number")
--simDR_autothrottle_on           = find_dataref("sim/cockpit2/autopilot/autothrottle_on")

simDR_prop_mode                 = find_dataref("sim/cockpit2/engine/actuators/prop_mode")

simDR_engine_throttle_jet       = find_dataref("sim/cockpit2/engine/actuators/throttle_jet_rev_ratio")
simDR_engine_throttle_jet_all   = find_dataref("sim/cockpit2/engine/actuators/throttle_jet_rev_ratio_all")
--simCMD_autopilot_autothrottle_on		= find_command("sim/autopilot/autothrottle_on")
--simCMD_autopilot_autothrottle_off		= find_command("sim/autopilot/autothrottle_off")
simCMD_autopilot_glideslope_mode		= find_command("sim/autopilot/glide_slope")
B747DR_ap_approach_mode     	= deferred_dataref("laminar/B747/autopilot/approach_mode", "number")

simCMD_autopilot_appr_mode					= find_command("sim/autopilot/approach")
simDR_autopilot_TOGA_vert_status    	= find_dataref("sim/cockpit2/autopilot/TOGA_status")
simDR_autopilot_TOGA_lat_status     	= find_dataref("sim/cockpit2/autopilot/TOGA_lateral_status")
B747DR_autopilot_TOGA_status     	= deferred_dataref("laminar/B747/autopilot/TOGA_status","number")
simCMD_autopilot_TOGA_mode          = find_command("sim/autopilot/take_off_go_around")
simDRTime					= find_dataref("sim/time/total_running_time_sec")
B747DR_ap_lastCommand              		= deferred_dataref("laminar/B747/autopilot/lastCommand", "number")
simDR_hydraulic_sys_press_01    = find_dataref("sim/operation/failures/hydraulic_pressure_ratio")
simDR_hydraulic_sys_press_02    = find_dataref("sim/operation/failures/hydraulic_pressure_ratio2")

simDR_engine_nacelle_heat_on    = find_dataref("sim/cockpit2/ice/ice_inlet_heat_on_per_engine")
simDR_engine_starter_status     = find_dataref("sim/cockpit2/engine/actuators/ignition_key")				-- CHANGE TO STARTER IS RUNNING  ??
simDR_engine_auto_ignite_on     = find_dataref("sim/cockpit2/engine/actuators/auto_ignite_on")
simDR_engine_igniter_on         = find_dataref("sim/cockpit2/engine/actuators/igniter_on")
B747DR_display_N1				= find_dataref("laminar/B747/engines/display_N1")
B747DR_display_N2				= find_dataref("laminar/B747/engines/display_N2")

simDR_engine_EGT_degC           = find_dataref("sim/cockpit2/engine/indicators/EGT_deg_C")
simDR_engine_fuel_mix_ratio     = find_dataref("sim/cockpit2/engine/actuators/mixture_ratio")
simDR_engine_oil_pressure       = find_dataref("sim/cockpit2/engine/indicators/oil_pressure_psi")
simDR_engine_oil_temp           = find_dataref("sim/cockpit2/engine/indicators/oil_temperature_deg_C")
simDR_engine_oil_qty_ratio      = find_dataref("sim/cockpit2/engine/indicators/oil_quantity_ratio")

simDR_engine_fire		= find_dataref("sim/flightmodel2/engines/is_on_fire")
simDR_flap_deploy_ratio         = find_dataref("laminar/B747/cablecontrols/flap_ratio")
--simDR_allThrottle           	= find_dataref("sim/cockpit2/engine/actuators/throttle_ratio_all")
simDR_engine_running            = find_dataref("sim/flightmodel/engine/ENGN_running")
simDR_apu_running            	= find_dataref("sim/cockpit/engine/APU_running")

simDR_thrust_rev_fail_01        = find_dataref("sim/operation/failures/rel_revers0")
simDR_thrust_rev_fail_02        = find_dataref("sim/operation/failures/rel_revers1")
simDR_thrust_rev_fail_03        = find_dataref("sim/operation/failures/rel_revers2")
simDR_thrust_rev_fail_04        = find_dataref("sim/operation/failures/rel_revers3")
simDR_thrust_spoolTime	        = find_dataref("sim/aircraft/engine/acf_spooltime_turbine")
simDR_autopilot_TOGA_vert_status = find_dataref("sim/cockpit2/autopilot/TOGA_status")

    simDR_ind_airspeed_kts_pilot        	= find_dataref("laminar/B747/gauges/indicators/airspeed_kts_pilot")



--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--
B747DR_acfType               = find_dataref("laminar/B747/acfType")
B747DR_button_switch_position               = find_dataref("laminar/B747/button_switch/position")
B747DR_toggle_switch_position               = find_dataref("laminar/B747/toggle_switch/position")

B747DR_fuel_control_toggle_switch_pos       = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")

B747DR_bleedAir_engine1_start_valve_pos     = find_dataref("laminar/B747/air/engine1/bleed_start_valve_pos")
B747DR_bleedAir_engine2_start_valve_pos     = find_dataref("laminar/B747/air/engine2/bleed_start_valve_pos")
B747DR_bleedAir_engine3_start_valve_pos     = find_dataref("laminar/B747/air/engine3/bleed_start_valve_pos")
B747DR_bleedAir_engine4_start_valve_pos     = find_dataref("laminar/B747/air/engine4/bleed_start_valve_pos")

B747DR_engine01_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine01/ext_switch/pos_disch")
B747DR_engine02_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine02/ext_switch/pos_disch")
B747DR_engine03_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine03/ext_switch/pos_disch")
B747DR_engine04_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine04/ext_switch/pos_disch")

B747DR_engine_apu_oil_qty_ratio      	= find_dataref("laminar/B747/apu/oil")
B747DR_engine_apu_n2      	        = find_dataref("laminar/B747/apu/n2")
B747DR_elec_apu_inlet_door_pos      = find_dataref("laminar/B747/electrical/apu_inlet_door")

B747DR_CAS_warning_status           = find_dataref("laminar/B747/CAS/warning_status")
B747DR_CAS_caution_status                   = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status                  = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_CAS_memo_status                      = find_dataref("laminar/B747/CAS/memo_status")
B747DR_ap_autoland            	= find_dataref("laminar/B747/autopilot/autoland")

B747DR_engineType					= deferred_dataref("laminar/B747/engines/type", "number")

B747DR_ap_FMA_autothrottle_mode     = deferred_dataref("laminar/B747/autopilot/FMA/autothrottle_mode", "number")

--*************************************************************************************--
--** 				               FIND X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

simCMD_igniter_on_1         = find_command("sim/igniters/igniter_contin_on_1")
simCMD_igniter_on_2         = find_command("sim/igniters/igniter_contin_on_2")
simCMD_igniter_on_3         = find_command("sim/igniters/igniter_contin_on_3")
simCMD_igniter_on_4         = find_command("sim/igniters/igniter_contin_on_4")

simCMD_igniter_off_1        = find_command("sim/igniters/igniter_contin_off_1")
simCMD_igniter_off_2        = find_command("sim/igniters/igniter_contin_off_2")
simCMD_igniter_off_3        = find_command("sim/igniters/igniter_contin_off_3")
simCMD_igniter_off_4        = find_command("sim/igniters/igniter_contin_off_4")

simCMD_starter_on_1         = find_command("sim/starters/engage_starter_1")
simCMD_starter_on_2         = find_command("sim/starters/engage_starter_2")
simCMD_starter_on_3         = find_command("sim/starters/engage_starter_3")
simCMD_starter_on_4         = find_command("sim/starters/engage_starter_4")

simCMD_starter_off_1        = find_command("sim/starters/shut_down_1")
simCMD_starter_off_2        = find_command("sim/starters/shut_down_2")
simCMD_starter_off_3        = find_command("sim/starters/shut_down_3")
simCMD_starter_off_4        = find_command("sim/starters/shut_down_4")






--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_engine_start_switch1        = find_command("laminar/B747/toggle_switch/engine_start1")
B747CMD_engine_start_switch2        = find_command("laminar/B747/toggle_switch/engine_start2")
B747CMD_engine_start_switch3        = find_command("laminar/B747/toggle_switch/engine_start3")
B747CMD_engine_start_switch4        = find_command("laminar/B747/toggle_switch/engine_start4")

B747CMD_engine_start_switch1_off    = find_command("laminar/B747/toggle_switch/engine_start1_off")
B747CMD_engine_start_switch2_off    = find_command("laminar/B747/toggle_switch/engine_start2_off")
B747CMD_engine_start_switch3_off    = find_command("laminar/B747/toggle_switch/engine_start3_off")
B747CMD_engine_start_switch4_off    = find_command("laminar/B747/toggle_switch/engine_start4_off")

simCMD_ThrottleUp=find_command("sim/engines/throttle_up")



--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--




--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--
local callEngineReverse={}
callEngineReverse[0]=-1
callEngineReverse[1]=-1
callEngineReverse[2]=-1
callEngineReverse[3]=-1

function B747_thrust_rev_toggle_1_CMDhandler(phase, duration)
	if phase == 0 then
			
		if callEngineReverse[0]<=0 then 
            callEngineReverse[0]=1
        else
            callEngineReverse[0]=-1
            run_after_time(canx_revHold, 0.5)
        end					
	end	
end	

function B747_thrust_rev_toggle_2_CMDhandler(phase, duration)
	if phase == 0 then
			
		if callEngineReverse[1]<=0 then 
            callEngineReverse[1]=1
        else
            callEngineReverse[1]=-1
            run_after_time(canx_revHold, 0.5)
        end						
	end		
end	

function B747_thrust_rev_toggle_3_CMDhandler(phase, duration)
	if phase == 0 then
			
		if callEngineReverse[2]<=0 then 
            callEngineReverse[2]=1
        else
            callEngineReverse[2]=-1
            run_after_time(canx_revHold, 0.5)
        end						
	end		
end

function B747_thrust_rev_toggle_4_CMDhandler(phase, duration)
	if phase == 0 then
			
		if callEngineReverse[3]<=0 then 
            callEngineReverse[3]=1
        else
            callEngineReverse[3]=-1
            run_after_time(canx_revHold, 0.5)
        end					
	end	
end

function B747_thrust_rev_toggle_all_CMDhandler(phase, duration)
	if phase == 0 then
		
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS USER TOGGLING "REVERSE" MODE WHEN ENGINE 4 THROTTLE LEVER IS NOT AT IDLE
		print("toggle reverse")
        local canc=false
        for i = 0, 3 do
            if callEngineReverse[i]<=0 then 
                callEngineReverse[i]=1
            else
                callEngineReverse[i]=-1
                canc=true
            end
        end
        if canc then run_after_time(canx_revHold, 0.5) end
	end
end	






function B747_thrust_rev_hold_max_1_CMDhandler(phase, duration)
    callEngineReverse[0]=-1

    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 1 THROTTLE LEVER IS NOT AT IDLE

		if B747DR_reverser_lockout == 0 and simDR_engine_throttle_jet[0] < 0.05 then											-- AIRCRAFT IS ON THE GRUOND

				simDR_prop_mode[0] = 3														
				simDR_engine_throttle_jet[0] = B747_animate_value(simDR_engine_throttle_jet[0],-1,-1,1,1)
				B747_hold_rev_on_engine[0] = 1
		else 
            simDR_engine_throttle_jet[0]=B747_animate_value(simDR_engine_throttle_jet[0],0,0,1,1)	
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[0] == 1 then
			--simDR_prop_mode[0] = 1														
			simDR_engine_throttle_jet[0] = 0.0
			B747_hold_rev_on_engine[0] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_2_CMDhandler(phase, duration)

    callEngineReverse[1]=-1
    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 2 THROTTLE LEVER IS NOT AT IDLE

		if B747DR_reverser_lockout == 0 and simDR_engine_throttle_jet[1] < 0.05 then											-- AIRCRAFT IS ON THE GRUOND
				simDR_prop_mode[1] = 3														
				simDR_engine_throttle_jet[1] = B747_animate_value(simDR_engine_throttle_jet[1],-1,-1,1,1)
				B747_hold_rev_on_engine[1] = 1
		else 
            simDR_engine_throttle_jet[1]=B747_animate_value(simDR_engine_throttle_jet[1],0,0,1,1)	
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[1] == 1 then
			--simDR_prop_mode[1] = 1														
			simDR_engine_throttle_jet[1] = 0.0
			B747_hold_rev_on_engine[1] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_3_CMDhandler(phase, duration)
    callEngineReverse[2]=-1
    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 3 THROTTLE LEVER IS NOT AT IDLE

		if B747DR_reverser_lockout == 0 and simDR_engine_throttle_jet[2] < 0.05 then											-- AIRCRAFT IS ON THE GRUOND
				simDR_prop_mode[2] = 3														
				simDR_engine_throttle_jet[2] = B747_animate_value(simDR_engine_throttle_jet[2],-1,-1,1,1)
				B747_hold_rev_on_engine[2] = 1
		else 
            simDR_engine_throttle_jet[2]=B747_animate_value(simDR_engine_throttle_jet[2],0,0,1,1)		
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[2] == 1 then
			--simDR_prop_mode[2] = 1														
			simDR_engine_throttle_jet[2] = 0.0
			B747_hold_rev_on_engine[2] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_4_CMDhandler(phase, duration)

    callEngineReverse[3]=-1

    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 4 THROTTLE LEVER IS NOT AT IDLE

		if B747DR_reverser_lockout == 0 and simDR_engine_throttle_jet[3] < 0.05 then											-- AIRCRAFT IS ON THE GRUOND
				simDR_prop_mode[3] = 3														
				simDR_engine_throttle_jet[3] = B747_animate_value(simDR_engine_throttle_jet[3],-1,-1,1,1)
				B747_hold_rev_on_engine[3] = 1
		else 
            simDR_engine_throttle_jet[3]=B747_animate_value(simDR_engine_throttle_jet[3],0,0,1,1)		
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[3] == 1 then
			--simDR_prop_mode[3] = 1														
			simDR_engine_throttle_jet[3] = 0.0
			B747_hold_rev_on_engine[3] = 0
		end
					
    end
    
end
function canx_rev()
     simDR_engine_throttle_jet_all = 0.0

     B747_hold_rev_on_all = 0
     
 end
function canx_revHold()
   -- simDR_engine_throttle_jet_all = 0.0
    simDR_engine_throttle_jet_all = -0.01
    B747_hold_rev_on_all = 0
    if is_timer_scheduled(canx_rev) then
        stop_timer(canx_rev)
    end
    run_after_time(canx_rev, 3.0)
end

function B747_thrust_rev_hold_max_all_CMDhandler(phase, duration)
	callEngineReverse[0]=-1
    callEngineReverse[1]=-1
    callEngineReverse[2]=-1
    callEngineReverse[3]=-1
    B747DR_engine_TOGA_mode = 0
    B747DR_autothrottle_active=0
    B747DR_ap_FMA_autothrottle_mode=0
    B747DR_autothrottle_fail = 1
    B747DR_ap_thrust_mode = 0
	B747DR_ap_vnav_state = 0
	B747DR_ap_inVNAVdescent = 0
	B747DR_ap_flightPhase = 2
	B747DR_autopilot_TOGA_status=0 
    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ANY THROTTLE LEVER IS NOT AT IDLE

		if B747DR_reverser_lockout == 0 and simDR_engine_throttle_jet_all <= 0.0 then											-- AIRCRAFT IS ON THE GRUOND
				simDR_prop_mode[0] = 3													
				simDR_prop_mode[1] = 3													
				simDR_prop_mode[2] = 3													
				simDR_prop_mode[3] = 3		
				simDR_engine_throttle_jet_all = -1 --B747_animate_value(simDR_engine_throttle_jet_all,-1,-1,1,1)
				B747_hold_rev_on_all = 1
		--else
		--  simDR_engine_throttle_jet_all=B747_animate_value(simDR_engine_throttle_jet_all,0,0,1,1)
		end
        if is_timer_scheduled(canx_revHold) then
            stop_timer(canx_revHold)
        end
        
		
	end		
	
	--[[if phase == 2 then
		
		if B747_hold_rev_on_all == 1 then
			--simDR_prop_mode[0] = 1													
			--simDR_prop_mode[1] = 1													
			--simDR_prop_mode[2] = 1													
			--simDR_prop_mode[3] = 1	
            --print("canx rev")	
			simDR_engine_throttle_jet_all = -0.01
            run_after_time(canx_revHold,5)
		end
					
    end]]--
    
end












function B747_engine_TOGA_power_CMDhandler(phase, duration)
     
    callEngineReverse[0]=0
    callEngineReverse[1]=0
    callEngineReverse[2]=0
    callEngineReverse[3]=0
    simDR_prop_mode[0] = 1													
    simDR_prop_mode[1] = 1													
    simDR_prop_mode[2] = 1													
    simDR_prop_mode[3] = 1		
	if phase == 0 then
        if simDR_all_wheels_on_ground==0 then
            B747DR_ap_autoland=-2
            if B747DR_autopilot_TOGA_status == 0 										-- TOGA LATERAL MODE IS OFF 
            then	
                    B747DR_ap_lastCommand=simDRTime									
                    B747DR_autopilot_TOGA_status=1												-- ACTIVATE "TOGA" MODE
            end	
            
        end
        B747DR_ap_approach_mode = 0
        if B747DR_engine_TOGA_mode == 0 and (simDR_all_wheels_on_ground==0 or (simDR_all_wheels_on_ground==1 and B747DR_toggle_switch_position[29] == 1)) then
            --[[simDR_engine_throttle_input[0] = 0.95
            simDR_engine_throttle_input[1] = 0.95
            simDR_engine_throttle_input[2] = 0.95
            simDR_engine_throttle_input[3] = 0.95]]
            B747DR_engine_TOGA_mode = 0.9
            
        
        end	
        if B747DR_toggle_switch_position[29] == 1 then
            B747DR_autothrottle_fail = 0
            B747DR_autothrottle_active=1
            
        end		
	end	
end





function B747_ai_engines_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
	  	B747_set_engines_all_modes()
	  	B747_set_engines_CD()
	  	B747_set_engines_ER()
	  	B747_set_engines_all_modes2()
	end    	
end	





--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_thrust_mnp_show				= deferred_dataref("laminar/B747/engine/thrust_mnp_show", "array[4]")
B747DR_thrust_mnp_show_all			= deferred_dataref("laminar/B747/engine/thrust_mnp_show_all", "number")

B747DR_reverse_mnp_show				= deferred_dataref("laminar/B747/engine/rev_mnp_show", "array[4)")
B747DR_reverse_mnp_show_all			= deferred_dataref("laminar/B747/engine/rev_mnp_show_all", "number")

B747DR_engine_fuel_valve_pos        = deferred_dataref("laminar/B747/engines/fuel_valve_pos", "array[4)")
B747DR_EICAS2_fuel_on_ind_status    = deferred_dataref("laminar/B747/engines/fuel_on_indicator_status", "array[4)")
B747DR_EICAS2_oil_press_status      = deferred_dataref("laminar/B747/engines/EICAS2_oil_press_status", "array[4)")
B747DR_EICAS2_engine_vibration      = deferred_dataref("laminar/B747/engines/vibration", "array[4)")
B747DR_EICAS2_engine_disturbance    = deferred_dataref("laminar/B747/engines/disturbance", "number")
B747DR_EICAS2_wingFlex			    =find_dataref("sim/flightmodel2/wing/wing_tip_deflection_deg")
B747DR_engine_vibration_position    = deferred_dataref("laminar/B747/engine/vibration_position", "array[4)")
B747DR_engine_oil_press_psi         = deferred_dataref("laminar/B747/engines/oil_press_psi", "array[4)")
B747DR_engine_oil_temp_degC         = deferred_dataref("laminar/B747/engines/oil_temp_degC", "array[4)")
B747DR_engine_oil_qty_liters        = deferred_dataref("laminar/B747/engines/oil_qty_liters", "array[4)")
B747DR_EPR_max_limit                = deferred_dataref("laminar/B747/engines/EPR/max_limit", "array[4)")
B747DR_EGT_amber_inhibit            = deferred_dataref("laminar/B747/engines/EGT/amber_inhibit", "array[4)")
B747DR_EGT_amber_on                 = deferred_dataref("laminar/B747/engines/EGT/amber_on", "array[4)")
B747DR_EGT_white_on                 = deferred_dataref("laminar/B747/engines/EGT/white_on", "array[4)")

B747DR_init_engines_CD              = deferred_dataref("laminar/B747/engines/init_CD", "number")

B747DR_engine_TOGA_mode             = deferred_dataref("laminar/B747/engines/TOGA_mode", "number")

B747DR_ref_thr_limit_mode           = deferred_dataref("laminar/B747/engines/ref_thr_limit_mode", "string")

B747DR_autothrottle_fail            = deferred_dataref("laminar/B747/engines/autothrottle_fail", "number")


--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--
-- Holds all SimConfig options

B747DR_simconfig_data					= deferred_dataref("laminar/B747/simconfig", "string")
B747DR_newsimconfig_data				= deferred_dataref("laminar/B747/newsimconfig", "number")



--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             REPLACE X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--

B747CMD_thrust_rev_toggle_1      	= replace_command("sim/engines/thrust_reverse_toggle_1", B747_thrust_rev_toggle_1_CMDhandler)
B747CMD_thrust_rev_toggle_2      	= replace_command("sim/engines/thrust_reverse_toggle_2", B747_thrust_rev_toggle_2_CMDhandler)
B747CMD_thrust_rev_toggle_3      	= replace_command("sim/engines/thrust_reverse_toggle_3", B747_thrust_rev_toggle_3_CMDhandler)
B747CMD_thrust_rev_toggle_4     	= replace_command("sim/engines/thrust_reverse_toggle_4", B747_thrust_rev_toggle_4_CMDhandler)

B747CMD_thrust_rev_toggle_all		= replace_command("sim/engines/thrust_reverse_toggle", B747_thrust_rev_toggle_all_CMDhandler)



B747CMD_thrust_rev_hold_1_max    	= replace_command("sim/engines/thrust_reverse_hold_1", B747_thrust_rev_hold_max_1_CMDhandler)
B747CMD_thrust_rev_hold_2_max    	= replace_command("sim/engines/thrust_reverse_hold_2", B747_thrust_rev_hold_max_2_CMDhandler)
B747CMD_thrust_rev_hold_3_max    	= replace_command("sim/engines/thrust_reverse_hold_3", B747_thrust_rev_hold_max_3_CMDhandler)
B747CMD_thrust_rev_hold_4_max    	= replace_command("sim/engines/thrust_reverse_hold_4", B747_thrust_rev_hold_max_4_CMDhandler)

B747CMD_thrust_rev_hold_max_all     = replace_command("sim/engines/thrust_reverse_hold", B747_thrust_rev_hold_max_all_CMDhandler)



B747CMD_TOGA_power					= replace_command("sim/engines/TOGA_power", B747_engine_TOGA_power_CMDhandler)		


-- AI
B747CMD_ai_engines_quick_start		= deferred_command("laminar/B747/ai/engines_quick_start", "number", B747_ai_engines_quick_start_CMDhandler)



--*************************************************************************************--
--** 				              WRAP X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                   CREATE OBJECTS               				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end





----- RESCALE FLOAT AND CLAMP TO OUTER LIMITS -------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end










function B747_set_animation_position(current_value, target, min, max, speed)

    local fps_factor = math.min(1.0, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end
----- PROP MODE -------------------------------------------------------------------------
local LastSpeedBrake=0
local clearingReverse=false
local lastThrottleAll=0
function B747_prop_mode()
    if simDR_radarAlt1 > 25.1 then
        callEngineReverse[0]=0
        callEngineReverse[1]=0
        callEngineReverse[2]=0
        callEngineReverse[3]=0
    end
    -- Mode 0 is feathered, 1 is normal, 2 is in beta, and reverse (prop or jet) is mode 3
    local refreshGroundstate=simDR_all_wheels_on_ground
    if simDR_reallyall_wheels_on_ground==0 then
        B747DR_reverser_lockout = 1
    else 
        B747DR_reverser_lockout = 0
    end
    if simDR_prop_mode[i] == 3 and simDR_engine_throttle_jet_all<0 or
        (simDR_thrust_rev_deploy_ratio[0]<0.01 and simDR_thrust_rev_deploy_ratio[1]<0.01 and simDR_thrust_rev_deploy_ratio[2]<0.01 and simDR_thrust_rev_deploy_ratio[3]<0.01)
        then
        clearingReverse=false
    elseif simDR_engine_throttle_jet_all>-0.0001 and simDR_engine_throttle_jet_all>lastThrottleAll then
        clearingReverse=true
    end
    lastThrottleAll=simDR_engine_throttle_jet_all
    for i = 0, 3 do
       print("in clear prop mode "..i.." with "..callEngineReverse[i])
       if clearingReverse then
        simDR_prop_mode[i] = 1
        callEngineReverse[i]=0
      -- elseif callEngineReverse[i]==0 then 
        --    simDR_prop_mode[i] = 1
         --   print("do clear prop mode "..i.." with "..B747DR_display_N1[i])
        --elseif B747DR_speedbrake_lever<LastSpeedBrake and callEngineReverse[i]==1 and B747DR_reverser_lockout == 0 then
        --    simDR_prop_mode[i] = 1
        --    callEngineReverse[i]=-1
          --  print("alt do clear prop mode "..i.." with "..B747DR_display_N1[i])
          -- 
        elseif (callEngineReverse[i]==1 and B747DR_reverser_lockout == 0 and simDR_engine_throttle_jet_all<=0) or simDR_thrust_rev_deploy_ratio[i]>0.01 and not(clearingReverse) then
            simDR_prop_mode[i] = 3
            B747DR_engine_TOGA_mode = 0
            B747DR_autothrottle_active=0
            B747DR_ap_FMA_autothrottle_mode=0
            B747DR_autothrottle_fail = 1
            B747DR_ap_thrust_mode = 0
            B747DR_ap_vnav_state = 0
            B747DR_ap_inVNAVdescent = 0
            B747DR_ap_flightPhase = 2
            B747DR_autopilot_TOGA_status=0 
        end
    end 
    -- AIRCRAFT IS "ON THE GROUND" 
	LastSpeedBrake=B747DR_speedbrake_lever
end	

			

	
function B747_set_tq_levers_mnp_show()
	
	
	-- THRUST LEVER MANIPULATOR HIDE/SHOW
	B747DR_thrust_mnp_show[0]	= 1-- B747_ternary(simDR_engine_throttle_jet[0] < 0.0 or (B747DR_ap_autothrottle_armed == 1 and B747DR_ap_FMA_autothrottle_mode > 1), 0, 1)
	B747DR_thrust_mnp_show[1]	= 1-- B747_ternary(simDR_engine_throttle_jet[1] < 0.0 or (B747DR_ap_autothrottle_armed == 1 and B747DR_ap_FMA_autothrottle_mode > 1), 0, 1)
	B747DR_thrust_mnp_show[2]	= 1-- B747_ternary(simDR_engine_throttle_jet[2] < 0.0 or (B747DR_ap_autothrottle_armed == 1 and B747DR_ap_FMA_autothrottle_mode > 1), 0, 1)
	B747DR_thrust_mnp_show[3]	= 1-- B747_ternary(simDR_engine_throttle_jet[3] < 0.0 or (B747DR_ap_autothrottle_armed == 1 and B747DR_ap_FMA_autothrottle_mode > 1), 0, 1)
	
	B747DR_thrust_mnp_show_all	= 1 -- B747_ternary(simDR_engine_throttle_jet_all < 0.0 or (B747DR_ap_autothrottle_armed == 1 and B747DR_ap_FMA_autothrottle_mode > 1), 0, 1) -- B747_ternary(B747DR_ap_autothrottle_armed == 1 and B747DR_ap_FMA_autothrottle_mode > 1, 0, 1)
	
	
	
	-- REVERSE LEVER MANIPULATOR HIDE/SHOW
	B747DR_reverse_mnp_show[0] 	= B747_ternary(simDR_engine_throttle_jet[0] > 0.0 or B747DR_reverser_lockout==1, 0, 1)
	B747DR_reverse_mnp_show[1] 	= B747_ternary(simDR_engine_throttle_jet[1] > 0.0 or B747DR_reverser_lockout==1, 0, 1)
	B747DR_reverse_mnp_show[2] 	= B747_ternary(simDR_engine_throttle_jet[2] > 0.0 or B747DR_reverser_lockout==1, 0, 1)
	B747DR_reverse_mnp_show[3] 	= B747_ternary(simDR_engine_throttle_jet[3] > 0.0 or B747DR_reverser_lockout==1, 0, 1)
	
	B747DR_reverse_mnp_show_all	= B747_ternary(simDR_engine_throttle_jet_all > 0.0 or B747DR_reverser_lockout==1, 0, 1)

		    	 	 
end














----- EGT INIDICATOR --------------------------------------------------------------------
local EGT_start_limit       = 535.0                                                     -- RED
local EGT_continuous_limit  = 629.0                                                     -- AMBER
local EGT_max_limit         = 654.0                                                     -- REDLINE
local EGT_check_inhibit     = {1, 1, 1, 1}
local EGT_amber_inhibit     = {0, 0, 0, 0}

function B747_EGT01_5min_inhibit_canx()
    EGT_amber_inhibit[1] = 0
end
function B747_EGT01_10min_inhibit_canx()
    EGT_amber_inhibit[1] = 0
end
function B747_EGT02_5min_inhibit_canx()
    EGT_amber_inhibit[2] = 0
end
function B747_EGT02_10min_inhibit_canx()
    EGT_amber_inhibit[2] = 0
end
function B747_EGT03_5min_inhibit_canx()
    EGT_amber_inhibit[3] = 0
end
function B747_EGT03_10min_inhibit_canx()
    EGT_amber_inhibit[3] = 0
end
function B747_EGT04_5min_inhibit_canx()
    EGT_amber_inhibit[4] = 0
end
function B747_EGT04_10min_inhibit_canx()
    EGT_amber_inhibit[4] = 0
end

function B747_EGT_indicator()

    -- GET NUMBER OF RUNNING ENGINES
    local num_eng_running = 0
    for i = 0, 3 do
        if simDR_engine_running[i] == 1 then
            num_eng_running = num_eng_running + 1
        end
    end
    if num_eng_running==4 then 
      simDR_thrust_spoolTime=5
    elseif num_eng_running==0 then
      simDR_thrust_spoolTime=26
    end
    -- ----------------------------------------------------------------------------------
    -- ENGINE #1
    -- ----------------------------------------------------------------------------------
    if B747DR_display_EGT[0] <= EGT_continuous_limit then
        EGT_amber_inhibit[1] = 0
        EGT_check_inhibit[1] = 1
        if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == true then
            stop_timer(B747_EGT01_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == true then
            stop_timer(B747_EGT01_10min_inhibit_canx)
        end

    elseif B747DR_display_EGT[0] > EGT_continuous_limit
        and B747DR_display_EGT[0] <= EGT_max_limit
        and EGT_check_inhibit[1] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[1] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT01_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT01_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT01_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT01_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[1] = 0
            if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == true then
                stop_timer(B747_EGT01_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == true then
                stop_timer(B747_EGT01_10min_inhibit_canx)
            end

        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[0] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if B747DR_display_EGT[0] > EGT_continuous_limit
        and B747DR_display_EGT[0] <= EGT_max_limit
        and EGT_amber_inhibit[1] == 0
    then
        B747DR_EGT_amber_on[0] = 1
    else
        B747DR_EGT_amber_on[0] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (B747DR_display_EGT[0] <= EGT_continuous_limit)
        or
        ((B747DR_display_EGT[0] > EGT_continuous_limit) and (B747DR_display_EGT[0] <= EGT_max_limit) and (EGT_amber_inhibit[1] == 1))
    then
        B747DR_EGT_white_on[0] = 1
    else
        B747DR_EGT_white_on[0] = 0
    end




    -- ----------------------------------------------------------------------------------
    -- ENGINE #2
    -- ----------------------------------------------------------------------------------
    if B747DR_display_EGT[1] <= EGT_continuous_limit then
        EGT_amber_inhibit[2] = 0
        EGT_check_inhibit[2] = 1
        if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == true then
            stop_timer(B747_EGT02_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == true then
            stop_timer(B747_EGT02_10min_inhibit_canx)
        end

    elseif B747DR_display_EGT[1] > EGT_continuous_limit
        and B747DR_display_EGT[1] <= EGT_max_limit
        and EGT_check_inhibit[2] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[2] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT02_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT02_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT02_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT02_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[2] = 0
            if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == true then
                stop_timer(B747_EGT02_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == true then
                stop_timer(B747_EGT02_10min_inhibit_canx)
            end

        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[1] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if B747DR_display_EGT[1] > EGT_continuous_limit
        and B747DR_display_EGT[1] <= EGT_max_limit
        and EGT_amber_inhibit[2] == 0
    then
        B747DR_EGT_amber_on[1] = 1
    else
        B747DR_EGT_amber_on[1] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (B747DR_display_EGT[1] <= EGT_continuous_limit)
        or ((B747DR_display_EGT[1] > EGT_continuous_limit) and (B747DR_display_EGT[1] <= EGT_max_limit) and (EGT_amber_inhibit[2] == 1))
    then
        B747DR_EGT_white_on[1] = 1
    else
        B747DR_EGT_white_on[1] = 0
    end


    -- ----------------------------------------------------------------------------------
    -- ENGINE #3
    -- ----------------------------------------------------------------------------------
    if B747DR_display_EGT[2] <= EGT_continuous_limit then
        EGT_amber_inhibit[3] = 0
        EGT_check_inhibit[3] = 1
        if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == true then
            stop_timer(B747_EGT03_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == true then
            stop_timer(B747_EGT03_10min_inhibit_canx)
        end

    elseif B747DR_display_EGT[2] > EGT_continuous_limit
        and B747DR_display_EGT[2] <= EGT_max_limit
        and EGT_check_inhibit[3] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[3] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT03_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT03_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT03_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT03_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[3] = 0
            if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == true then
                stop_timer(B747_EGT03_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == true then
                stop_timer(B747_EGT03_10min_inhibit_canx)
            end

        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[2] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if B747DR_display_EGT[2] > EGT_continuous_limit
        and B747DR_display_EGT[2] <= EGT_max_limit
        and EGT_amber_inhibit[3] == 0
    then
        B747DR_EGT_amber_on[2] = 1
    else
        B747DR_EGT_amber_on[2] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (B747DR_display_EGT[2] <= EGT_continuous_limit)
        or ((B747DR_display_EGT[2] > EGT_continuous_limit) and (B747DR_display_EGT[2] <= EGT_max_limit) and (EGT_amber_inhibit[3] == 1))
    then
        B747DR_EGT_white_on[2] = 1
    else
        B747DR_EGT_white_on[2] = 0
    end


    -- ----------------------------------------------------------------------------------
    -- ENGINE #4
    -- ----------------------------------------------------------------------------------
    if B747DR_display_EGT[3] <= EGT_continuous_limit then
        EGT_amber_inhibit[4] = 0
        EGT_check_inhibit[4] = 1
        if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == true then
            stop_timer(B747_EGT04_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == true then
            stop_timer(B747_EGT04_10min_inhibit_canx)
        end
    
    elseif B747DR_display_EGT[3] > EGT_continuous_limit
        and B747DR_display_EGT[3] <= EGT_max_limit
        and EGT_check_inhibit[4] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[4] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT04_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT04_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT04_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT04_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[4] = 0
            if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == true then
                stop_timer(B747_EGT04_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == true then
                stop_timer(B747_EGT04_10min_inhibit_canx)
            end
    
        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[3] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if B747DR_display_EGT[3] > EGT_continuous_limit
        and B747DR_display_EGT[3] <= EGT_max_limit
        and EGT_amber_inhibit[4] == 0
    then
        B747DR_EGT_amber_on[3] = 1
    else
        B747DR_EGT_amber_on[3] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (B747DR_display_EGT[3] <= EGT_continuous_limit)
        or ((B747DR_display_EGT[3] > EGT_continuous_limit) and (B747DR_display_EGT[3] <= EGT_max_limit) and (EGT_amber_inhibit[4] == 1))
    then
        B747DR_EGT_white_on[3] = 1
    else
        B747DR_EGT_white_on[3] = 0
    end

end







----- N2 FUEL-ON INDICATOR --------------------------------------------------------------
function B747_secondary_EICAS2_fuel_on_status()

    B747DR_EICAS2_fuel_on_ind_status[0] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[0] < 0.05), 1, 0)
    B747DR_EICAS2_fuel_on_ind_status[1] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[1] < 0.05), 1, 0)
    B747DR_EICAS2_fuel_on_ind_status[2] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[2] < 0.05), 1, 0)
    B747DR_EICAS2_fuel_on_ind_status[3] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[3] < 0.05), 1, 0)
    
end




----- ENGINE OIL PRESSURE SECONDARY EICAS DISPLAY ---------------------------------------
function B747_secondary_EICAS2_oil_press_status()

    B747DR_engine_oil_press_psi[0] = simDR_engine_oil_pressure[0] + B747_rescale(0.0, 0.0, 100.0, B747_eng1oilPressVariance, B747DR_display_N1[0])
    B747DR_engine_oil_press_psi[1] = simDR_engine_oil_pressure[1] + B747_rescale(0.0, 0.0, 100.0, B747_eng2oilPressVariance, B747DR_display_N1[1])
    B747DR_engine_oil_press_psi[2] = simDR_engine_oil_pressure[2] + B747_rescale(0.0, 0.0, 100.0, B747_eng3oilPressVariance, B747DR_display_N1[2])
    B747DR_engine_oil_press_psi[3] = simDR_engine_oil_pressure[3] + B747_rescale(0.0, 0.0, 100.0, B747_eng4oilPressVariance, B747DR_display_N1[3])

    for i = 0, 3 do
        
        if B747DR_engine_oil_press_psi[i] < 70.0                                            -- PRESURE IS BELOW MINIMUM
            and (simDR_engine_starter_status[i] == 0                                        -- ENGINE STARTER IS NOT ENGAGED
                or B747DR_fuel_control_toggle_switch_pos[i] > 0.95)                         -- ENGINE IS NOT SHUTDOWN
        then
            B747DR_EICAS2_oil_press_status[i] = 1                                           -- SHOW REDLINE OBJECTS
	else
	  B747DR_EICAS2_oil_press_status[i] = 0
        end
    end

end






---- ENGINE OIL TEMPERATURE -------------------------------------------------------------
function B747_engine_oil_temp()

    B747DR_engine_oil_temp_degC[0] = simDR_engine_oil_temp[0] + B747_rescale(0.0, 0.0, 100.0, B747_eng1oilTempVariance, B747DR_display_N1[0])
    B747DR_engine_oil_temp_degC[1] = simDR_engine_oil_temp[1] + B747_rescale(0.0, 0.0, 100.0, B747_eng2oilTempVariance, B747DR_display_N1[1])
    B747DR_engine_oil_temp_degC[2] = simDR_engine_oil_temp[2] + B747_rescale(0.0, 0.0, 100.0, B747_eng3oilTempVariance, B747DR_display_N1[2])
    B747DR_engine_oil_temp_degC[3] = simDR_engine_oil_temp[3] + B747_rescale(0.0, 0.0, 100.0, B747_eng4oilTempVariance, B747DR_display_N1[3])

end





----- ENGINE VIBRATION ------------------------------------------------------------------
local int, frac = math.modf(os.clock())
local seed = math.random(1, frac*1000.0)
math.randomseed(seed)
--local B747_engine1_maxVib = math.min(1.3, math.random(0, 1) + math.random())
--local B747_engine2_maxVib = math.min(1.5, math.random(0, 3) + math.random())
--local B747_engine3_maxVib = math.min(1.4, math.random(0, 2) + math.random())
--local B747_engine4_maxVib = math.min(1.6, math.random(0, 3) + math.random())
local B747_engine_maxVib = {}
local B747_engine_vibPhase = {}
local B747_engine_lastClock = {}
local B747_engine_lastPos = {}
local lastWingFlex=0
for i = 0, 3 do
  B747_engine_maxVib[i]= math.min(1.3, math.random(0, 1) + math.random())
  B747_engine_vibPhase[i] =  math.random(0, 6)
  B747_engine_lastClock[i] = os.clock()
  B747_engine_lastPos[i]=0
end
function B747_animate_value(current_value, target, min, max, speed)

    --[[local fps_factor = math.min(0.1, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end]]--
    local fps_factor = math.min(0.1, speed * SIM_PERIOD)
	local nextValue=current_value + ((target - current_value) * fps_factor)
    if nextValue >= (max - 0.001) then
        return max
    elseif nextValue <= (min + 0.001) then
       return min
    else
        return nextValue
    end

end
local wasFire=false
function B747_secondary_EICAS2_engine_vibration()
    --local vibrationRate=0
    local timeNow=0
    local phaseNow=0
    local thrust=0
    local wingFlex=0
    
    if simDR_version<115602 or simDR_version>=120012 then
        wingFlex=B747DR_EICAS2_wingFlex[0]
    else
        wingFlex=B747DR_EICAS2_wingFlex
    end
    local disturbance=math.sqrt((wingFlex-lastWingFlex)*(wingFlex-lastWingFlex))
    
    B747DR_EICAS2_engine_disturbance=B747_animate_value(B747DR_EICAS2_engine_disturbance,1,1,5,10)+disturbance
    B747DR_EICAS2_engine_disturbance=math.min(B747DR_EICAS2_engine_disturbance,4)
    lastWingFlex=B747_animate_value(lastWingFlex,wingFlex,-30,30,20)
    local airspeedReduction=(400-simDR_ind_airspeed_kts_pilot)/400
    for i = 0, 3 do
        if simDR_engine_fire[i] > 0 then
            B747_engine_maxVib[i]= math.random(2, 3)
        --else
         --   B747_engine_maxVib[i]= math.min(1.3, math.random(0, 1) + math.random())
        end
    B747DR_EICAS2_engine_vibration[i] = B747_rescale(0.0, 0.0, 100.0, B747_engine_maxVib[i], B747DR_display_N2[i])
    timeNow=B747_engine_lastClock[i]+(os.clock()-B747_engine_lastClock[i])
    thrust=math.max((B747DR_display_N2[i]-60)/10,0)
    phaseNow=(timeNow*thrust)-(B747_engine_lastClock[i]*thrust)
    B747_engine_lastPos[i]=B747_engine_lastPos[i]+phaseNow
    
    B747DR_engine_vibration_position[i] =airspeedReduction*B747DR_EICAS2_engine_vibration[i]*(B747DR_EICAS2_engine_disturbance*math.sin(B747_engine_lastPos[i]+ B747_engine_vibPhase[i]))/5

    B747_engine_lastClock[i] = os.clock()
    end
    
end






local initial_apu_oil = 0.75+(math.random()*0.25)
----- ENGINE OIL QUANTITY ---------------------------------------------------------------
function B747_engine_oil_qty()

    B747DR_engine_oil_qty_liters[0] = math.max(0, (B747_eng1oilStart - (B747_eng1startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, B747DR_display_N1[0]))) * simDR_engine_oil_qty_ratio[0])
    B747DR_engine_oil_qty_liters[1] = math.max(0, (B747_eng2oilStart - (B747_eng2startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, B747DR_display_N1[1]))) * simDR_engine_oil_qty_ratio[0])
    B747DR_engine_oil_qty_liters[2] = math.max(0, (B747_eng3oilStart - (B747_eng3startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, B747DR_display_N1[2]))) * simDR_engine_oil_qty_ratio[0]) 
	B747DR_engine_oil_qty_liters[3] = math.max(0, (B747_eng4oilStart - (B747_eng4startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, B747DR_display_N1[3]))) * simDR_engine_oil_qty_ratio[0]) 
    B747DR_engine_apu_oil_qty_ratio=B747_animate_value(B747DR_engine_apu_oil_qty_ratio,initial_apu_oil - (B747DR_engine_apu_n2*0.003),0,1,20)
end




----- EPR -------------------------------------------------------------------------------
function B747_EPR()

    B747_ref_thr_limit_mode = "NONE"

    -- SET EPR MAX LIMIT
    for i = 0, 3 do
        B747DR_EPR_max_limit[i] = 2.0
    end
    B747DR_engine_apu_n2 = 85.5 * B747DR_elec_apu_inlet_door_pos
--[[
    -- TOGA
    if B747DR_engine_TOGA_mode == 1 then
        B747_ref_thr_limit_mode = "TO"
    end
--]]
end




----- THRUST LIMIT MODE -----------------------------------------------------------------
function B747_thrust_limit_mode_label()

    if B747_ref_thr_limit_mode == "NONE" then
        B747DR_ref_thr_limit_mode = " "
    else
        B747DR_ref_thr_limit_mode = B747_ref_thr_limit_mode
    end

end








----- STARTUP IGNITION ------------------------------------------------------------------
function B747_startup_ignition()

    -- IGNITION IS REQUIRED FOR STARTUP WITH ENGINES RUNNING
    -- IF USER SHUTS DOWN AN ENGINE THEY WILL NEED TO MANUALLY RE-START OR RE-LOAD THE SIM
    for i = 0, 3 do
        if B747DR_display_N2[i] < 45.0                                            -- N2 is less than 55.0 %
            and B747_ignition_startup_flag[i+1] == 1                                -- ALLOWS ONLY ONE (1)) AUTO-IGNITE AT SIM LOAD
        then
            simDR_engine_auto_ignite_on[i] = 1                                      -- TURN ON AUTO-IGNITE
        else                                                                        -- ENGINE HAS STARTED
            if simDR_engine_auto_ignite_on[i] == 1 then
                simDR_engine_auto_ignite_on[i] = 0                                  -- TURN AUTO-IGNITE OFF
                B747_ignition_startup_flag[i+1] = 0                                 -- SET FLAG TO PREVENT FUTURE AUTO-IGNITE
            end
        end
    end

end





----- EICAS MESSAGES --------------------------------------------------------------------
function B747_engines_EICAS_msg()

    

    -- ENG 1 FAIL
    
    if (B747DR_display_N1[0]<15.0) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_warning_status[28] = 1
    else
        B747DR_CAS_warning_status[28] = 0
    end

    -- ENG 1 SHUTDOWN
    
    if (B747DR_engine01_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[0] < 0.05) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_caution_status[23] = 1
    else
        B747DR_CAS_caution_status[23] = 0
    end

    -- ENG 1 FAIL
    
    if (B747DR_display_N2[0]<15.0 and  B747DR_CAS_caution_status[23] == 0) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_warning_status[28] = 1
    else
        B747DR_CAS_warning_status[28] = 0
    end

    -- ENG 2 SHUTDOWN
    
    if (B747DR_engine02_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[1] < 0.05) and simDR_all_wheels_on_ground == 0 
    then
        B747DR_CAS_caution_status[24] = 1
    else
      B747DR_CAS_caution_status[24] = 0
    end

    -- ENG 2 FAIL
    
    if (B747DR_display_N2[1]<15.0 and  B747DR_CAS_caution_status[24] == 0) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_warning_status[29] = 1
    else
        B747DR_CAS_warning_status[29] = 0
    end
    -- ENG 3 SHUTDOWN
    
    if (B747DR_engine03_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[2] < 0.05) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_caution_status[25] = 1
    else
      B747DR_CAS_caution_status[25] = 0
    end
    -- ENG 3 FAIL
    
    if (B747DR_display_N2[2]<15.0 and  B747DR_CAS_caution_status[25] == 0) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_warning_status[30] = 1
    else
        B747DR_CAS_warning_status[30] = 0
    end
    -- ENG 4 SHUTDOWN
    
    if (B747DR_engine04_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[3] < 0.05) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_caution_status[26] = 1
    else
      B747DR_CAS_caution_status[26] = 0
    end
    -- ENG 3 FAIL
    
    if (B747DR_display_N2[3]<15.0 and  B747DR_CAS_caution_status[26] == 0) and simDR_all_wheels_on_ground == 0
    then
        B747DR_CAS_warning_status[31] = 1
    else
        B747DR_CAS_warning_status[31] = 0
    end
    -- STARTER CUTOUT 1
    
    if B747DR_bleedAir_engine1_start_valve_pos > 0.05
        and B747DR_display_N2[0] > 45.0
    then
        B747DR_CAS_caution_status[61] = 1
    else
      B747DR_CAS_caution_status[61] = 0
    end

    -- STARTER CUTOUT 2
    
    if B747DR_bleedAir_engine2_start_valve_pos > 0.05
        and B747DR_display_N2[1] > 45.0
    then
        B747DR_CAS_caution_status[62] = 1
    else
      B747DR_CAS_caution_status[62] = 0
    end

    -- STARTER CUTOUT 3
    
    if B747DR_bleedAir_engine3_start_valve_pos > 0.05
        and B747DR_display_N2[2] > 45.0
    then
        B747DR_CAS_caution_status[63] = 1
    else
      B747DR_CAS_caution_status[63] = 0
    end

    -- STARTER CUTOUT 4
    
    if B747DR_bleedAir_engine4_start_valve_pos > 0.05
        and B747DR_display_N2[3] > 45.0
    then
        B747DR_CAS_caution_status[64] = 1
    else
      B747DR_CAS_caution_status[64] = 0
    end

    -- ENG 1 OIL TEMP
    
    if B747DR_engine_oil_temp_degC[0] > 160.0 then B747DR_CAS_advisory_status[118] = 1 else B747DR_CAS_advisory_status[118] = 0 end

    -- ENG 2 OIL TEMP
    
    if B747DR_engine_oil_temp_degC[1] > 160.0 then B747DR_CAS_advisory_status[119] = 1 else B747DR_CAS_advisory_status[119] = 0 end

    -- ENG 3 OIL TEMP
    
    if B747DR_engine_oil_temp_degC[2] > 160.0 then B747DR_CAS_advisory_status[120] = 1 else B747DR_CAS_advisory_status[120] = 0 end

    -- ENG 4 OIL TEMP
    
    if B747DR_engine_oil_temp_degC[3] > 160.0 then B747DR_CAS_advisory_status[121] = 1 else B747DR_CAS_advisory_status[121] = 0 end

    -- ENG 1 REVERSER
    
    if simDR_thrust_rev_fail_01 == 6 then B747DR_CAS_advisory_status[126] = 1 else B747DR_CAS_advisory_status[126] = 0 end

    -- ENG 2 REVERSER
   
    if simDR_thrust_rev_fail_02 == 6 then B747DR_CAS_advisory_status[127] = 1 else B747DR_CAS_advisory_status[127] = 0 end

    -- ENG 3 REVERSER
    
    if simDR_thrust_rev_fail_03 == 6 then B747DR_CAS_advisory_status[128] = 1 else B747DR_CAS_advisory_status[128] = 0 end

    -- ENG 4 REVERSER
    
    if simDR_thrust_rev_fail_04 == 6 then B747DR_CAS_advisory_status[129] = 1 else B747DR_CAS_advisory_status[129] = 0 end

    if B747DR_engineType == 0 then  --PW4000
        -- >ENG 1 RPM LIM

        if B747DR_display_N1[0] >= 111.41 then B747DR_CAS_advisory_status[134] = 1 else B747DR_CAS_advisory_status[134] = 0 end

        -- >ENG 2 RPM LIM
        
        if B747DR_display_N1[1] >= 111.41 then B747DR_CAS_advisory_status[135] = 1 else B747DR_CAS_advisory_status[135] = 0 end

        -- >ENG 3 RPM LIM
        
        if B747DR_display_N1[2] >= 111.41 then B747DR_CAS_advisory_status[136] = 1 else B747DR_CAS_advisory_status[136] = 0 end

        -- >ENG 4 RPM LIM
        
        if B747DR_display_N1[3] >= 111.41 then B747DR_CAS_advisory_status[137] = 1 else B747DR_CAS_advisory_status[137] = 0 end
    end

    if B747DR_engineType == 1 then  --GE CF6
        -- >ENG 1 RPM LIM

        if B747DR_display_N1[0] >= 117.51 then B747DR_CAS_advisory_status[134] = 1 else B747DR_CAS_advisory_status[134] = 0 end

        -- >ENG 2 RPM LIM
        
        if B747DR_display_N1[1] >= 117.51 then B747DR_CAS_advisory_status[135] = 1 else B747DR_CAS_advisory_status[135] = 0 end

        -- >ENG 3 RPM LIM
        
        if B747DR_display_N1[2] >= 117.51 then B747DR_CAS_advisory_status[136] = 1 else B747DR_CAS_advisory_status[136] = 0 end

        -- >ENG 4 RPM LIM
        
        if B747DR_display_N1[3] >= 117.51 then B747DR_CAS_advisory_status[137] = 1 else B747DR_CAS_advisory_status[137] = 0 end
    end

    if B747DR_engineType == 2 then  --RR RB211
        -- >ENG 1 RPM LIM

        if B747DR_display_N1[0] >= 111.51 then B747DR_CAS_advisory_status[134] = 1 else B747DR_CAS_advisory_status[134] = 0 end

        -- >ENG 2 RPM LIM
        
        if B747DR_display_N1[1] >= 111.51 then B747DR_CAS_advisory_status[135] = 1 else B747DR_CAS_advisory_status[135] = 0 end

        -- >ENG 3 RPM LIM
        
        if B747DR_display_N1[2] >= 111.51 then B747DR_CAS_advisory_status[136] = 1 else B747DR_CAS_advisory_status[136] = 0 end

        -- >ENG 4 RPM LIM
        
        if B747DR_display_N1[3] >= 111.51 then B747DR_CAS_advisory_status[137] = 1 else B747DR_CAS_advisory_status[137] = 0 end
    end

    -- CON IGNITION ON
    
    if B747DR_CAS_advisory_status[109] == 0 then
        if B747DR_button_switch_position[44] > 0.95 then B747DR_CAS_memo_status[8] = 1 else B747DR_CAS_memo_status[8] = 0 end
    else
      B747DR_CAS_memo_status[8] = 0
    end

    
end








----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_engines_monitor_AI()

    if B747DR_init_engines_CD == 1 then
        B747_set_engines_all_modes()
        B747_set_engines_CD()
        B747_set_engines_all_modes2()
        B747DR_init_engines_CD = 2
    end
    
end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_engines_all_modes()

	B747DR_init_engines_CD = 0

end





function B747_set_engines_all_modes2()
--[[
    for i = 0, 3 do
        B747_old_throttle_lever_input[i+1] = simDR_engine_throttle_input[i]
    end
--]]
end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_engines_CD()

    B747DR_engine_fuel_valve_pos[0] = 0
    B747DR_engine_fuel_valve_pos[1] = 0
    B747DR_engine_fuel_valve_pos[2] = 0
    B747DR_engine_fuel_valve_pos[3] = 0


end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_engines_ER()
	
    B747DR_engine_fuel_valve_pos[0] = 1
    B747DR_engine_fuel_valve_pos[1] = 1
    B747DR_engine_fuel_valve_pos[2] = 1
    B747DR_engine_fuel_valve_pos[3] = 1  
    simDR_thrust_spoolTime=5
    B747_startup_ignition()
	
end








----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_engines()

    -- ALL MODES ------------------------------------------------------------------------
	B747_set_engines_all_modes()
    B747DR_engine_TOGA_mode = 0


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_engines_CD()



    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then
	
		B747_set_engines_ER()


    end


    -- ALL MODES POST PROCESS -----------------------------------------------------------
    B747_set_engines_all_modes2()

end
local B747_igniter_status = {0, 0, 0, 0}
local B747_starter_status = {0, 0, 0, 0}
-- ENGINE START SWITCH OFF
function B747_engine_start_sw_off(engine)

        if engine == 0 then
            if B747DR_toggle_switch_position[16] > 0 then B747CMD_engine_start_switch1_off:once() end
        end
        if engine == 1 then
            if B747DR_toggle_switch_position[17] > 0 then B747CMD_engine_start_switch2_off:once() end
        end
        if engine == 2 then
            if B747DR_toggle_switch_position[18] > 0 then B747CMD_engine_start_switch3_off:once() end
        end
        if engine == 3 then
            if B747DR_toggle_switch_position[19] > 0 then B747CMD_engine_start_switch4_off:once() end
        end

    end
    -- ENGINE STARTERS ON
    function B747_engine_starter_on(engine)

--         if engine == 0 then
--             if simDR_engine_starter_status[0] < 4 and B747_starter_status[1]==0 then simCMD_starter_on_1:start() B747_starter_status[1]=1 end
--         end
--         if engine == 1 then
--             if simDR_engine_starter_status[1] < 4 and B747_starter_status[2]==0 then simCMD_starter_on_2:start() B747_starter_status[2]=1 end
--         end
--         if engine == 2 then
--             if simDR_engine_starter_status[2] < 4 and B747_starter_status[3]==0 then simCMD_starter_on_3:start() B747_starter_status[3]=1 end
--         end
--         if engine == 3 then
--             if simDR_engine_starter_status[3] < 4 and B747_starter_status[4]==0 then simCMD_starter_on_4:start() B747_starter_status[4]=1 end
--         end
	if engine == 0 then
            if simDR_engine_starter_status[0] < 4 and B747_starter_status[1]==0 then simCMD_starter_on_1:start() simDR_engine_igniter_on[0]=1 B747_starter_status[1]=1 end
        end
        if engine == 1 then
            if simDR_engine_starter_status[1] < 4 and B747_starter_status[2]==0 then simCMD_starter_on_2:start() simDR_engine_igniter_on[1]=1 B747_starter_status[2]=1 end
        end
        if engine == 2 then
            if simDR_engine_starter_status[2] < 4 and B747_starter_status[3]==0 then simCMD_starter_on_3:start() simDR_engine_igniter_on[2]=1 B747_starter_status[3]=1 end
        end
        if engine == 3 then
            if simDR_engine_starter_status[3] < 4 and B747_starter_status[4]==0 then simCMD_starter_on_4:start() simDR_engine_igniter_on[3]=1 B747_starter_status[4]=1 end
        end
    end
    -- ENGINE STARTERS OFF
    function B747_engine_starter_off(engine)

--         if engine == 0 then
--             if simDR_engine_starter_status[0] > 3 and B747_starter_status[1]==1 then simCMD_starter_on_1:stop() simCMD_starter_off_1:once() B747_starter_status[1]=0 end
--         end
--         if engine == 1 then
--             if simDR_engine_starter_status[1] > 3 and B747_starter_status[2]==1 then simCMD_starter_on_2:stop() simCMD_starter_off_2:once() B747_starter_status[2]=0 end
--         end
--         if engine == 2 then
--             if simDR_engine_starter_status[2] > 3 and B747_starter_status[3]==1 then simCMD_starter_on_3:stop() simCMD_starter_off_3:once() B747_starter_status[3]=0 end
--         end
--         if engine == 3 then
--             if simDR_engine_starter_status[3] > 3 and B747_starter_status[4]==1 then simCMD_starter_on_4:stop() simCMD_starter_off_4:once() B747_starter_status[4]=0 end
--         end
	if engine == 0 then
            if simDR_engine_starter_status[0] > 3 and B747_starter_status[1]==1 then simCMD_starter_on_1:stop() simCMD_starter_off_1:once() simDR_engine_igniter_on[0]=0 B747_starter_status[1]=0 end
        end
        if engine == 1 then
            if simDR_engine_starter_status[1] > 3 and B747_starter_status[2]==1 then simCMD_starter_on_2:stop() simCMD_starter_off_2:once() simDR_engine_igniter_on[0]=0 B747_starter_status[2]=0 end
        end
        if engine == 2 then
            if simDR_engine_starter_status[2] > 3 and B747_starter_status[3]==1 then simCMD_starter_on_3:stop() simCMD_starter_off_3:once() simDR_engine_igniter_on[0]=0 B747_starter_status[3]=0 end
        end
        if engine == 3 then
            if simDR_engine_starter_status[3] > 3 and B747_starter_status[4]==1 then simCMD_starter_on_4:stop() simCMD_starter_off_4:once() simDR_engine_igniter_on[0]=0 B747_starter_status[4]=0 end
        end
    end

    B747DR_engine01_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine01/ext_switch/pos_arm", "number")
    B747DR_engine02_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine02/ext_switch/pos_arm", "number")
    B747DR_engine03_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine03/ext_switch/pos_arm", "number")
    B747DR_engine04_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine04/ext_switch/pos_arm", "number")    
function B747_electronic_engine_control()


    -------------------------------------------------------------------------------------
    -----                         E N G I N E   S T A R T                           -----
    -------------------------------------------------------------------------------------



    --============================== ENGINE #1 ====================================--
    if B747DR_display_N2[0] < 45.0 then

        if B747DR_bleedAir_engine1_start_valve_pos > 0.95 then                      -- START VALVE IS OPENED (START SWITCH PULLED) AND SUPPLYING BLEED AIR
            B747_engine_starter_on(0)                                               -- ENGAGE STARTER MOTOR
        else                                                                        -- START VALVE IS CLOSED - TERMNINATE MOTORING
            B747_engine_starter_off(0)                                              -- DISENGAGE STARTER MOTOR	-- TODO:  not needed??  starter is off automagically when not ON !!!!
        end

    -- STARTER CUTOUT @ N2 = 50.0%
    else
        B747_engine_start_sw_off(0)                                                 -- RESET START SWITCH
        B747_engine_starter_off(0)                                                  -- DISENGAGE STARTER MOTOR

    end


    --============================== ENGINE #2 ====================================--
    if B747DR_display_N2[1] < 45.0 then

        if B747DR_bleedAir_engine2_start_valve_pos > 0.95 then                      -- START VALVE IS OPENED (START SWITCH PULLED) AND SUPPLYING BLEED AIR
            B747_engine_starter_on(1)                                               -- ENGAGE STARTER MOTOR
        else                                                                        -- START VALVE IS CLOSED - TERMNINATE MOTORING
            B747_engine_starter_off(1)                                              -- DISENGAGE STARTER MOTOR
        end

    -- STARTER CUTOUT @ N2 = 50.0%
    else
        B747_engine_start_sw_off(1)                                                 -- RESET START SWITCH
        B747_engine_starter_off(1)                                                  -- DISENGAGE STARTER MOTOR

    end


    --============================== ENGINE #3 ====================================--
    if B747DR_display_N2[2] < 45.0 then

        if B747DR_bleedAir_engine3_start_valve_pos > 0.95 then                      -- START VALVE IS OPENED (START SWITCH PULLED) AND SUPPLYING BLEED AIR
            B747_engine_starter_on(2)                                               -- ENGAGE STARTER MOTOR
        else                                                                        -- START VALVE IS CLOSED - TERMNINATE MOTORING
            B747_engine_starter_off(2)                                              -- DISENGAGE STARTER MOTOR
        end

    -- STARTER CUTOUT @ N2 = 50.0%
    else
        B747_engine_start_sw_off(2)                                                 -- RESET START SWITCH
        B747_engine_starter_off(2)                                                  -- DISENGAGE STARTER MOTOR

    end


    --============================== ENGINE #4 ====================================--
    if B747DR_display_N2[3] < 45.0 then

        if B747DR_bleedAir_engine4_start_valve_pos > 0.95 then                      -- START VALVE IS OPENED (START SWITCH PULLED) AND SUPPLYING BLEED AIR
            B747_engine_starter_on(3)                                               -- ENGAGE STARTER MOTOR
        else                                                                        -- START VALVE IS CLOSED - TERMNINATE MOTORING
            B747_engine_starter_off(3)                                              -- DISENGAGE STARTER MOTOR
        end

    -- STARTER CUTOUT @ N2 = 50.0%
    else
        B747_engine_start_sw_off(3)                                                 -- RESET START SWITCH
        B747_engine_starter_off(3)                                                  -- DISENGAGE STARTER MOTOR

    end








    -------------------------------------------------------------------------------------
    -----                             I G N I T E R S                               -----
    -------------------------------------------------------------------------------------

    ----- ENGINE #1 IGNITER STATUS ------------------------------------------------------
    if B747DR_button_switch_position[44] > 0.95                                         -- CONTINUOUS IGNITION SELECTED
        or simDR_flap_deploy_ratio > 0.0                                                -- FLAPS OUT OF "UP" POSITION
        or simDR_engine_nacelle_heat_on[0] == 1                                         -- ENGINE NACELLE HEAT IS ON

        -- MANUAL START
        or (B747DR_button_switch_position[45] < 0.05                                    -- AUTOSTART BUTTON SWITCH IS NOT DEPRESSED
            and B747DR_toggle_switch_position[16] == 1.0                                -- START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[0] == 1.0)                        -- FUEL CONTROL SWITCH SET TO "RUN"

        -- AUTOSTART
        or (B747DR_button_switch_position[45] > 0.95                                    -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[16] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[0] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
            and B747DR_engine_fuel_valve_pos[0] == 1)                                   -- SEQUENCE IGNITER AFTER FUEL INTRO

    then
        B747_igniter_status[1] = 1
    else
        B747_igniter_status[1] = 0
    end

    ----- ENGINE #2 IGNITER STATUS ------------------------------------------------------
    if B747DR_button_switch_position[44] > 0.95                                         -- CONTINUOUS IGNITION SELECTED
        or simDR_flap_deploy_ratio > 0.0                                                -- FLAPS OUT OF "UP" POSITION
        or simDR_engine_nacelle_heat_on[1] == 1                                         -- ENGINE NACELLE HEAT IS ON

        -- MANUAL START
        or (B747DR_button_switch_position[45] < 0.05                                    -- AUTOSTART BUTTON SWITCH IS NOT DEPRESSED
            and B747DR_toggle_switch_position[17] == 1.0                                -- START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[1] == 1.0)                        -- FUEL CONTROL SWITCH SET TO "RUN"

        -- AUTOSTART
        or (B747DR_button_switch_position[45] > 0.95                                    -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[17] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[1] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
            and B747DR_engine_fuel_valve_pos[1] == 1)                                   -- SEQUENCE IGNITER AFTER FUEL INTRO


    then
        B747_igniter_status[2] = 1
    else
        B747_igniter_status[2] = 0
    end

    ----- ENGINE #3 IGNITER STATUS ------------------------------------------------------
    if B747DR_button_switch_position[44] > 0.95                                         -- CONTINUOUS IGNITION SELECTED
        or simDR_flap_deploy_ratio > 0.0                                                -- FLAPS OUT OF "UP" POSITION
        or simDR_engine_nacelle_heat_on[2] == 1                                         -- ENGINE NACELLE HEAT IS ON

        -- MANUAL START
        or (B747DR_button_switch_position[45] < 0.05                                    -- AUTOSTART BUTTON SWITCH IS NOT DEPRESSED
            and B747DR_toggle_switch_position[18] == 1.0                                -- START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[2] == 1.0)                        -- FUEL CONTROL SWITCH SET TO "RUN"

        -- AUTOSTART
        or (B747DR_button_switch_position[45] > 0.95                                    -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[18] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[2] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
            and B747DR_engine_fuel_valve_pos[2] == 1)                                   -- SEQUENCE IGNITER AFTER FUEL INTRO


    then
        B747_igniter_status[3] = 1
    else
        B747_igniter_status[3] = 0
    end

    ----- ENGINE #4 IGNITER STATUS ------------------------------------------------------
    if B747DR_button_switch_position[44] > 0.95                                         -- CONTINUOUS IGNITION SELECTED
        or simDR_flap_deploy_ratio > 0.0                                                -- FLAPS OUT OF "UP" POSITION
        or simDR_engine_nacelle_heat_on[3] == 1                                         -- ENGINE NACELLE HEAT IS ON

        -- MANUAL START
        or (B747DR_button_switch_position[45] < 0.05                                    -- AUTOSTART BUTTON SWITCH IS NOT DEPRESSED
            and B747DR_toggle_switch_position[19] == 1.0                                -- START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[3] == 1.0)                        -- FUEL CONTROL SWITCH SET TO "RUN"

        -- AUTOSTART
        or (B747DR_button_switch_position[45] > 0.95                                    -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[19] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[3] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
            and B747DR_engine_fuel_valve_pos[3] == 1)                                   -- SEQUENCE IGNITER AFTER FUEL INTRO


    then
        B747_igniter_status[4] = 1
    else
        B747_igniter_status[4] = 0
    end




    ----- SET X-PLANE IGNITER STATE -----------------------------------------------------
-- ENGINE 1
    --print(B747_igniter_status[1] .. " " .. B747_starter_status[1].. " " .. simDR_engine_igniter_on[1])
    --if B747_igniter_status[1] == 0 and B747_starter_status[1]==1 then simCMD_starter_on_1:stop() B747_starter_status[1]=0 end
    --[[if B747_igniter_status[1] == 0 and simDR_engine_igniter_on[0] == 1 then
        simCMD_igniter_off_1:once()
    end
    --[[
    -- ENGINE 2
    if B747_igniter_status[2] == 0 and B747_starter_status[2]==1 then simCMD_starter_on_2:stop() B747_starter_status[2]==0 end
    if B747_igniter_status[2] == 0 and simDR_engine_igniter_on[1] == 1 then
        simCMD_igniter_off_2:once()
    end

    -- ENGINE 3
    if B747_igniter_status[3] == 0 and B747_starter_status[3]==1 then simCMD_starter_on_2:stop() B747_starter_status[3]==0 end
    if B747_igniter_status[3] == 0 and simDR_engine_igniter_on[2] == 1 then
        simCMD_igniter_off_3:once()
    end

    -- ENGINE 4
    if B747_igniter_status[4] == 0 and B747_starter_status[4]==1 then simCMD_starter_on_2:stop() B747_starter_status[4]==0 end
    if B747_igniter_status[4] == 0 and simDR_engine_igniter_on[3] == 1 then
        simCMD_igniter_off_4:once()
    end
    --[[
    -- ENGINE 1
    if B747_igniter_status[1] == 1 and simDR_engine_igniter_on[0] == 0 then
        simCMD_igniter_on_1:once()
    elseif B747_igniter_status[1] == 0 and simDR_engine_igniter_on[0] == 1 then
        simCMD_igniter_off_1:once()
    end

    -- ENGINE 2
    if B747_igniter_status[2] == 1 and simDR_engine_igniter_on[1] == 0 then
        simCMD_igniter_on_2:once()
    elseif B747_igniter_status[2] == 0 and simDR_engine_igniter_on[1] == 1 then
        simCMD_igniter_off_2:once()
    end

    -- ENGINE 3
    if B747_igniter_status[3] == 1 and simDR_engine_igniter_on[2] == 0 then
        simCMD_igniter_on_3:once()
    elseif B747_igniter_status[3] == 0 and simDR_engine_igniter_on[2] == 1 then
        simCMD_igniter_off_3:once()
    end

    -- ENGINE 4
    if B747_igniter_status[4] == 1 and simDR_engine_igniter_on[3] == 0 then
        simCMD_igniter_on_4:once()
    elseif B747_igniter_status[4] == 0 and simDR_engine_igniter_on[3] == 1 then
        simCMD_igniter_off_4:once()
    end]]




    -------------------------------------------------------------------------------------
    -----                  E N G I N E   F U E L   V A L V E S                      -----   TODO:  ADD POWER REQUIREMENT FOR VALVE ACTUATION ?
    -------------------------------------------------------------------------------------

    ----- ENGINE #1 ---------------------------------------------------------------------
    

    -- MANUAL START
    if B747DR_engine01_fire_ext_switch_pos_arm==1 then
        B747DR_engine_fuel_valve_pos[0] = 0 
    elseif B747DR_button_switch_position[45] < 0.5                                              -- AUTOSTART BUTTON NOT DEPRESSED
        and B747DR_fuel_control_toggle_switch_pos[0] == 1.0                                 -- FUEL CONTROL SWITCH SET TO "RUN"
    then
        B747DR_engine_fuel_valve_pos[0] = 1                                                 -- OPEN THE VALVE

    -- AUTOSTART
    elseif B747DR_button_switch_position[45] > 0.5                                          -- AUTOSTART BUTTON DEPRESSED
        and B747DR_display_N2[0] > 15.0
    then
        B747DR_engine_fuel_valve_pos[0] = 1                                                 -- OPEN THE VALVE
    else
	    B747DR_engine_fuel_valve_pos[0] = 0                                                     -- VALVE IS NORMALLY CLOSED
    end
    simDR_engine_fuel_mix_ratio[0] =  B747DR_engine_fuel_valve_pos[0]                       -- SET SIM MIXTURE RATIO



    ----- ENGINE #2 ---------------------------------------------------------------------
    

    -- MANUAL START
    if B747DR_engine02_fire_ext_switch_pos_arm==1 then
        B747DR_engine_fuel_valve_pos[1] = 0 
    elseif B747DR_button_switch_position[45] < 0.5                                              -- AUTOSTART BUTTON NOT DEPRESSED
        and B747DR_fuel_control_toggle_switch_pos[1] == 1.0                                 -- FUEL CONTROL SWITCH SET TO "RUN"
    then
        B747DR_engine_fuel_valve_pos[1] = 1                                                 -- OPEN THE VALVE

    -- AUTOSTART
    elseif B747DR_button_switch_position[45] > 0.5                                          -- AUTOSTART BUTTON DEPRESSED
        and B747DR_display_N2[1] > 15.0
    then
        B747DR_engine_fuel_valve_pos[1] = 1                                                 -- OPEN THE VALVE
    else
      B747DR_engine_fuel_valve_pos[1] = 0                                                     -- VALVE IS NORMALLY CLOSED
    end
    simDR_engine_fuel_mix_ratio[1] =  B747DR_engine_fuel_valve_pos[1]                       -- SET SIM MIXTURE RATIO



    ----- ENGINE #3 ---------------------------------------------------------------------
    

    -- MANUAL START
    if B747DR_engine03_fire_ext_switch_pos_arm==1 then
        B747DR_engine_fuel_valve_pos[2] = 0 
    elseif B747DR_button_switch_position[45] < 0.5                                              -- AUTOSTART BUTTON NOT DEPRESSED
        and B747DR_fuel_control_toggle_switch_pos[2] == 1.0                                 -- FUEL CONTROL SWITCH SET TO "RUN"
    then
        B747DR_engine_fuel_valve_pos[2] = 1                                                 -- OPEN THE VALVE

    -- AUTOSTART
    elseif B747DR_button_switch_position[45] > 0.5                                          -- AUTOSTART BUTTON DEPRESSED
        and B747DR_display_N2[2] > 15.0
    then
        B747DR_engine_fuel_valve_pos[2] = 1                                                 -- OPEN THE VALVE
    else
      B747DR_engine_fuel_valve_pos[2] = 0                                                     -- VALVE IS NORMALLY CLOSED
    end
    simDR_engine_fuel_mix_ratio[2] =  B747DR_engine_fuel_valve_pos[2]                       -- SET SIM MIXTURE RATIO



    ----- ENGINE #4 ---------------------------------------------------------------------
    

    -- MANUAL START
    if B747DR_engine04_fire_ext_switch_pos_arm==1 then
        B747DR_engine_fuel_valve_pos[3] = 0 
    elseif B747DR_button_switch_position[45] < 0.5                                              -- AUTOSTART BUTTON NOT DEPRESSED
        and B747DR_fuel_control_toggle_switch_pos[3] == 1.0                                 -- FUEL CONTROL SWITCH SET TO "RUN"
    then
        B747DR_engine_fuel_valve_pos[3] = 1                                                 -- OPEN THE VALVE

    -- AUTOSTART
    elseif B747DR_button_switch_position[45] > 0.5                                          -- AUTOSTART BUTTON DEPRESSED
        and B747DR_display_N2[3] > 15.0
    then
        B747DR_engine_fuel_valve_pos[3] = 1                                                 -- OPEN THE VALVE
    else
      B747DR_engine_fuel_valve_pos[3] = 0                                                     -- VALVE IS NORMALLY CLOSED
    end
    simDR_engine_fuel_mix_ratio[3] =  B747DR_engine_fuel_valve_pos[3]                       -- SET SIM MIXTURE RATIO

end



function B747_engines_monitor_reverse()
    --print("B747_engines_monitor_reverse"..simDR_ind_airspeed_kts_pilot.." "..B747_hold_rev_on_all)
    if simDR_ind_airspeed_kts_pilot<65 and B747_hold_rev_on_all==1 then
        run_after_time(canx_revHold, 5.0) --this timer gets cancelled while B747_hold_rev_on_all is being set to 1 
        B747_hold_rev_on_all=0
    end
end


--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

function aircraft_load() end

function aircraft_unload() end

function flight_start() 
    simDR_autoReverse=0
    B747_flight_start_engines()

end

--function flight_crash() end
debug_engines     = deferred_dataref("laminar/B747/debug/engines", "number")
function before_physics()
    if debug_engines>0 then return end
    B747_electronic_engine_control()

end
local setSimConfig=false
function hasSimConfig()
	if B747DR_newsimconfig_data==1 then
		if string.len(B747DR_simconfig_data) > 1 then
			simConfigData["data"] = json.decode(B747DR_simconfig_data)
			setSimConfig=true
		else
			return false
		end
	end
	return setSimConfig
end
function after_physics()
    if hasSimConfig()==false then return end
    if debug_engines>0 then return end
    local apModeRefresh=B747DR_ap_approach_mode
    --Marauder28

    if string.match(simConfigData["data"].PLANE.engines, "CF6") then
        EGT_start_limit = 870
        EGT_continuous_limit = 925
        EGT_max_limit = 960
    elseif string.match(simConfigData["data"].PLANE.engines, "PW") then
        EGT_start_limit = 535
        EGT_continuous_limit = 629
        EGT_max_limit = 654
    elseif string.match(simConfigData["data"].PLANE.engines, "RB") then
        EGT_start_limit = 600
        EGT_continuous_limit = 733
        EGT_max_limit = 785
    end
     --End Marauder28
    


   

    B747_startup_ignition()

    B747_prop_mode()
    
    B747_set_tq_levers_mnp_show()

    --B747_electronic_engine_control()

    B747_EGT_indicator()

    B747_engine_oil_qty()
    B747_engine_oil_temp()
    B747_secondary_EICAS2_fuel_on_status()
    B747_secondary_EICAS2_oil_press_status()
    B747_secondary_EICAS2_engine_vibration()

    B747_EPR() 
    --B747_thrust_limit_mode_label()

    B747_engines_EICAS_msg()

    B747_engines_monitor_AI()
    
    B747_engines_monitor_reverse()
end

--function after_replay() end





--*************************************************************************************--
--** 				               SUB-MODULE PROCESSING       	        			 **--
--*************************************************************************************--

-- dofile("")



