--[[
*****************************************************************************************
* Program Script Name	:	B738.95.AI

* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*
*
*
*
*
*****************************************************************************************
*      COPYRIGHT � 2016, 2017 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED
*****************************************************************************************
--]]



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



--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local autoboard = {
    step = -1,
    phase = {},
    sequence_timeout = false,
    in_progress = 0
}

local autostart = {
    step = -1,
    phase = {},
    sequence_timeout = false,
    in_progress = 0
}



--*************************************************************************************--
--** 				             FIND X-PLANE DATAREFS           			    	 **--
--*************************************************************************************--

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")
simDR_autoboard_in_progress         = find_dataref("sim/flightmodel2/misc/auto_board_in_progress")
simDR_autostart_in_progress         = find_dataref("sim/flightmodel2/misc/auto_start_in_progress")
simDR_battery_on                    = find_dataref("sim/cockpit2/electrical/battery_on")
simDR_cross_tie                     = find_dataref("sim/cockpit2/electrical/cross_tie")
simDR_apu_start_switch_mode         = find_dataref("sim/cockpit2/electrical/APU_starter_switch")
simDR_apu_running                   = find_dataref("sim/cockpit2/electrical/APU_running")
simDR_apu_N1_pct                    = find_dataref("sim/cockpit2/electrical/APU_N1_percent")
simDR_nav_lights_switch             = find_dataref("sim/cockpit2/switches/navigation_lights_on")
simDR_strobe_lights_switch			= find_dataref("sim/cockpit2/switches/strobe_lights_on")
simDR_apu_gen_on                    = find_dataref("sim/cockpit2/electrical/APU_generator_on")
simDR_gear_handle_down              = find_dataref("sim/cockpit2/controls/gear_handle_down")
simDR_generator_on                  = find_dataref("sim/cockpit2/electrical/generator_on")
simDR_panel_brightness_switch       = find_dataref("sim/cockpit2/switches/panel_brightness_ratio")
simDR_instrument_brightness_switch  = find_dataref("sim/cockpit2/switches/instrument_brightness_ratio")
simDR_fuel_tank_weight_kg           = find_dataref("sim/flightmodel/weight/m_fuel")



--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_init_manip_CD                = find_dataref("laminar/B747/manip/init_CD")
B747DR_init_elec_CD                 = find_dataref("laminar/B747/elec/init_CD")
B747DR_init_gear_CD                 = find_dataref("laminar/B747/gear/init_CD")
B747DR_init_com_CD                  = find_dataref("laminar/B747/com/init_CD")
B747DR_init_hyd_CD                  = find_dataref("laminar/B747/hyd/init_CD")
B747DR_init_fuel_CD                 = find_dataref("laminar/B747/fuel/init_CD")
B747DR_init_fltmgmt_CD              = find_dataref("laminar/B747/fltmgmt/init_CD")
B747DR_init_fire_CD                 = find_dataref("laminar/B747/fire/init_CD")
B747DR_init_engines_CD              = find_dataref("laminar/B747/engines/init_CD")
B747DR_init_fltctrls_CD             = find_dataref("laminar/B747/fltctrls/init_CD")
B747DR_init_ice_CD                  = find_dataref("laminar/B747/ice/init_CD")
B747DR_init_air_CD                  = find_dataref("laminar/B747/air/init_CD")
B747DR_init_inst_CD                 = find_dataref("laminar/B747/inst/init_CD")
B747DR_init_fmsL_CD                 = find_dataref("laminar/B747/fmsL/init_CD")
B747DR_init_fmsR_CD                 = find_dataref("laminar/B747/fmsR/init_CD")
--B747DR_init_autopilot_CD            = find_dataref("laminar/B747/autopilot/init_CD")
B747DR_init_safety_CD               = find_dataref("laminar/B747/safety/init_CD")
B747DR_init_warning_CD              = find_dataref("laminar/B747/warning/init_CD")
B747DR_init_lighting_CD             = find_dataref("laminar/B747/lighting/init_CD")

B747DR_button_switch_position       = find_dataref("laminar/B747/button_switch/position")
B747DR_toggle_switch_position       = find_dataref("laminar/B747/toggle_switch/position")
B747DR_fuel_control_toggle_switch_pos   = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")
B747DR_elec_apu_sel_pos             = find_dataref("laminar/B747/electrical/apu/sel_dial_pos")
B747DR_gear_handle                  = find_dataref("laminar/B747/actuator/gear_handle")
B747DR_gear_annun_status            = find_dataref("laminar/B747/gear/gear_position/annun_status")
B747DR_hyd_dmd_pmp_sel_pos          = find_dataref("laminar/B747/hydraulics/dmd_pump/sel_dial_pos")
B747DR_pack_ctrl_sel_pos            = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos")

B747DR_flood_light_rheo_overhead    = find_dataref("laminar/B747/light/flood/rheostat/overhead")
B747DR_flood_light_rheo_mcp         = find_dataref("laminar/B747/light/flood/rheostat/mcp_panel")

B747DR_elec_standby_power_sel_pos   = find_dataref("laminar/B747/electrical/standby_power/sel_dial_pos")
B747DR_sfty_no_smoke_sel_dial_pos   = find_dataref("laminar/B747/safety/no_smoking/sel_dial_pos")
B747DR_sfty_seat_belts_sel_dial_pos = find_dataref("laminar/B747/safety/seat_belts/sel_dial_pos")





--*************************************************************************************--
--** 				             FIND X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

simCMD_apu_start                    = find_command("sim/electrical/APU_start")
simCMD_apu_off                      = find_command("sim/electrical/APU_off")




--*************************************************************************************--
--** 				              FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_elec_util_L                 = find_command("laminar/B747/button_switch/elec_util_L")
B747CMD_elec_util_R                 = find_command("laminar/B747/button_switch/elec_util_R")
B747CMD_elec_battery                = find_command("laminar/B747/button_switch/elec_battery")
B747CMD_elec_bus_tie_1              = find_command("laminar/B747/button_switch/elec_bus_tie_1")
B747CMD_elec_bus_tie_2              = find_command("laminar/B747/button_switch/elec_bus_tie_2")
B747CMD_elec_bus_tie_3              = find_command("laminar/B747/button_switch/elec_bus_tie_3")
B747CMD_elec_bus_tie_4              = find_command("laminar/B747/button_switch/elec_bus_tie_4")
B747CMD_elec_apu_sel_up             = find_command("laminar/B747/electrical/apu/sel_dial_up")
B747CMD_elec_apu_gen_1              = find_command("laminar/B747/button_switch/elec_apu_gen_1")
B747CMD_nav_light_switch            = find_command("laminar/B747/toggle_switch/nav_light")
B747CMD_logo_light_switch           = find_command("laminar/B747/toggle_switch/logo_light")
B747CMD_cabin_lights_switch         = find_command("laminar/B747/toggle_switch/cabin_lights")
B747CMD_elec_gen_ctrl_1             = find_command("laminar/B747/button_switch/elec_gen_ctrl_1")
B747CMD_elec_gen_ctrl_2             = find_command("laminar/B747/button_switch/elec_gen_ctrl_2")
B747CMD_elec_gen_ctrl_3             = find_command("laminar/B747/button_switch/elec_gen_ctrl_3")
B747CMD_elec_gen_ctrl_4             = find_command("laminar/B747/button_switch/elec_gen_ctrl_4")
B747CMD_hyd_pump_1                  = find_command("laminar/B747/button_switch/hyd_pump_1")
B747CMD_hyd_pump_2                  = find_command("laminar/B747/button_switch/hyd_pump_2")
B747CMD_hyd_pump_3                  = find_command("laminar/B747/button_switch/hyd_pump_3")
B747CMD_hyd_pump_4                  = find_command("laminar/B747/button_switch/hyd_pump_4")
B747CMD_start_ign_cont              = find_command("laminar/B747/button_switch/start_ign_cont")
B747CMD_start_autostart             = find_command("laminar/B747/button_switch/start_autostart")
B747CMD_fuel_xfeed_vlv_1            = find_command("laminar/B747/button_switch/fuel_xfeed_vlv_1")
B747CMD_fuel_xfeed_vlv_2            = find_command("laminar/B747/button_switch/fuel_xfeed_vlv_2")
B747CMD_fuel_xfeed_vlv_3            = find_command("laminar/B747/button_switch/fuel_xfeed_vlv_3")
B747CMD_fuel_xfeed_vlv_4            = find_command("laminar/B747/button_switch/fuel_xfeed_vlv_4")
B747CMD_fuel_ctr_wing_tnk_pump_L    = find_command("laminar/B747/button_switch/fuel_ctr_wing_tnk_pump_L")
B747CMD_fuel_ctr_wing_tnk_pump_R    = find_command("laminar/B747/button_switch/fuel_ctr_wing_tnk_pump_R")
B747CMD_fuel_stab_tnk_pump_L        = find_command("laminar/B747/button_switch/fuel_stab_tnk_pump_L")
B747CMD_fuel_stab_tnk_pump_R        = find_command("laminar/B747/button_switch/fuel_stab_tnk_pump_R")
B747CMD_fuel_main_pump_fwd_1        = find_command("laminar/B747/button_switch/fuel_main_pump_fwd_1")
B747CMD_fuel_main_pump_fwd_2        = find_command("laminar/B747/button_switch/fuel_main_pump_fwd_2")
B747CMD_fuel_main_pump_fwd_3        = find_command("laminar/B747/button_switch/fuel_main_pump_fwd_3")
B747CMD_fuel_main_pump_fwd_4        = find_command("laminar/B747/button_switch/fuel_main_pump_fwd_4")
B747CMD_fuel_main_pump_aft_1        = find_command("laminar/B747/button_switch/fuel_main_pump_aft_1")
B747CMD_fuel_main_pump_aft_2        = find_command("laminar/B747/button_switch/fuel_main_pump_aft_2")
B747CMD_fuel_main_pump_aft_3        = find_command("laminar/B747/button_switch/fuel_main_pump_aft_3")
B747CMD_fuel_main_pump_aft_4        = find_command("laminar/B747/button_switch/fuel_main_pump_aft_4")
B747CMD_fuel_overd_pump_fwd_2       = find_command("laminar/B747/button_switch/fuel_overd_pump_fwd_2")
B747CMD_fuel_overd_pump_fwd_3       = find_command("laminar/B747/button_switch/fuel_overd_pump_fwd_3")
B747CMD_fuel_overd_pump_aft_2       = find_command("laminar/B747/button_switch/fuel_overd_pump_aft_2")
B747CMD_fuel_overd_pump_aft_3       = find_command("laminar/B747/button_switch/fuel_overd_pump_aft_3")
B747CMD_bleed_air_vlv_engine_1      = find_command("laminar/B747/button_switch/bleed_air_vlv_engine_1")
B747CMD_bleed_air_vlv_engine_2      = find_command("laminar/B747/button_switch/bleed_air_vlv_engine_2")
B747CMD_bleed_air_vlv_engine_3      = find_command("laminar/B747/button_switch/bleed_air_vlv_engine_3")
B747CMD_bleed_air_vlv_engine_4      = find_command("laminar/B747/button_switch/bleed_air_vlv_engine_4")
B747CMD_bleed_air_vlv_apu           = find_command("laminar/B747/button_switch/bleed_air_vlv_apu")
B747CMD_bleed_air_isln_vlv_L        = find_command("laminar/B747/button_switch/bleed_air_isln_vlv_L")
B747CMD_bleed_air_isln_vlv_R        = find_command("laminar/B747/button_switch/bleed_air_isln_vlv_R")
B747CMD_beacon_light_switch_down    = find_command("laminar/B747/toggle_switch/beacon_light_down")
B747CMD_strobe_light_switch         = find_command("laminar/B747/toggle_switch/strobe_light")
B747CMD_engine_start_switch1        = find_command("laminar/B747/toggle_switch/engine_start1")
B747CMD_engine_start_switch2        = find_command("laminar/B747/toggle_switch/engine_start2")
B747CMD_engine_start_switch3        = find_command("laminar/B747/toggle_switch/engine_start3")
B747CMD_engine_start_switch4        = find_command("laminar/B747/toggle_switch/engine_start4")
B747CMD_fuel_control_switch1        = find_command("laminar/B747/fuel/fuel_control_1/toggle_switch")
B747CMD_fuel_control_switch2        = find_command("laminar/B747/fuel/fuel_control_2/toggle_switch")
B747CMD_fuel_control_switch3        = find_command("laminar/B747/fuel/fuel_control_3/toggle_switch")
B747CMD_fuel_control_switch4        = find_command("laminar/B747/fuel/fuel_control_4/toggle_switch")
B747CMD_yaw_damper_upr              = find_command("laminar/B747/button_switch/yaw_damper_upr")
B747CMD_yaw_damper_lwr              = find_command("laminar/B747/button_switch/yaw_damper_lwr")
B747CMD_dsp_rcl_switch              = find_command("laminar/B747/dsp/rcl_switch")
B747CMD_dsp_canc_switch             = find_command("laminar/B747/dsp/canc_switch")

B747CMD_ai_manip_quick_start        = find_command("laminar/B747/ai/manip_quick_start")
B747CMD_ai_elec_quick_start         = find_command("laminar/B747/ai/elec_quick_start")
B747CMD_ai_gear_quick_start         = find_command("laminar/B747/ai/gear_quick_start")
B747CMD_ai_com_quick_start         	= find_command("laminar/B747/ai/com_quick_start")
B747CMD_ai_hyd_quick_start         	= find_command("laminar/B747/ai/hyd_quick_start")
B747CMD_ai_fuel_quick_start         = find_command("laminar/B747/ai/fuel_quick_start")
B747CMD_ai_fltmgmt_quick_start      = find_command("laminar/B747/ai/fltmgmt_quick_start")
B747CMD_ai_fire_quick_start         = find_command("laminar/B747/ai/fire_quick_start")
B747CMD_ai_engines_quick_start      = find_command("laminar/B747/ai/engines_quick_start")
B747CMD_ai_fltctrls_quick_start     = find_command("laminar/B747/ai/fltctrls_quick_start")
B747CMD_ai_antiice_quick_start      = find_command("laminar/B747/ai/antiice_quick_start")
B747CMD_ai_air_quick_start         	= find_command("laminar/B747/ai/air_quick_start")
B747CMD_ai_fltinst_quick_start      = find_command("laminar/B747/ai/fltinst_quick_start")
B747CMD_ai_fmsL_quick_start         = find_command("laminar/B747/ai/fmsL_quick_start")
B747CMD_ai_fmsR_quick_start         = find_command("laminar/B747/ai/fmsR_quick_start")
B747CMD_ai_autopilot_quick_start    = find_command("laminar/B747/ai/autopilot_quick_start")
B747CMD_ai_safety_quick_start       = find_command("laminar/B747/ai/safety_quick_start")
B747CMD_ai_warning_quick_start      = find_command("laminar/B747/ai/warning_quick_start")
B747CMD_ai_lighting_quick_start     = find_command("laminar/B747/ai/lighting_quick_start")








--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--

function sim_autoboard_CMDhandler(phase, duration)
    if phase == 0 then
        print("==> AUTOBOARD COMMAND INVOKED")
        if autoboard.in_progress == 0
        	and autostart.in_progress == 0
        then
	        if autostart.step < 0 then
            	simDR_autoboard_in_progress = 1
            end	
            autoboard.in_progress = 1
            autoboard.step = 0
            autoboard.phase = {}
            autoboard.sequence_timeout = false
        end
    end
end



function sim_autostart_CMDhandler(phase, duration)
    if phase == 0 then
    print("==> AUTOSTART COMMAND INVOKED")
        if autoboard.in_progress == 0
        	and autostart.in_progress == 0
        then
            autostart.step = 0
            simDR_autostart_in_progress = 1
        end
    end
end



function sim_quick_start_beforeCMDhandler(phase, duration) 
	if phase == 0 then
		B747_ai_quick_start()			
	end		
end
function sim_quick_start_afterCMDhandler(phase, duration) end




--*************************************************************************************--
--** 				             CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--






--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--




--*************************************************************************************--
--** 				             REPLACE X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--

simCMD_autoboard                    = replace_command("sim/operation/auto_board", sim_autoboard_CMDhandler)
simCMD_autostart                    = replace_command("sim/operation/auto_start", sim_autostart_CMDhandler)



--*************************************************************************************--
--** 				              WRAP X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--

simCMD_quick_start         			= wrap_command("sim/operation/quick_start", sim_quick_start_beforeCMDhandler, sim_quick_start_afterCMDhandler)



--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  CREATE OBJECTS        	      				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                 SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

function B747_print_sequence_status(step, phase, message)
    local msg = string.format("| Step:%02d/Phase:%02d - %s", step, phase, message)
    print(msg)
end

function B747_print_completed_line()
    print("+----------------------------------------------+")
end






----- AUTO-BOARD SEQUENCE ---------------------------------------------------------------

function B747_autoboard_init()
	if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
	    stop_timer(B747_autoboard_phase_timeout)                               
	end	
    autoboard.step = -1
    autoboard.phase = {}
    autoboard.sequence_timeout = false
    autoboard.in_progress = 0
end

function B747_print_autoboard_begin()
    print("+----------------------------------------------+")
    print("|          AUTO-BOARD SEQUENCE BEGIN           |")
    print("+----------------------------------------------+")
end

function B747_print_autoboard_abort()
    print("+----------------------------------------------+")
    print("|         AUTO-BOARD SEQUENCE ABORTED          |")
    print("+----------------------------------------------+")
end

function B747_print_autoboard_completed()
    print("+----------------------------------------------+")
    print("|        AUTO-BOARD SEQUENCE COMPLETED         |")
    print("+----------------------------------------------+")
end

function B747_print_autoboard_monitor(step, phase)
    B747_print_sequence_status(step, phase, "Monitoring...")
end

function B747_print_autoboard_timer_start(step, phase)
    B747_print_sequence_status(step, phase, "Auto-Board Phase Timer Started...")
end

function B747_autoboard_phase_monitor(time)
    if autoboard.phase[autoboard.step] == 2 then
        B747_print_autoboard_monitor(autoboard.step, autoboard.phase[autoboard.step])       -- PRINT THE MONITOR PHASE MESSAGE
        if is_timer_scheduled(B747_autoboard_phase_timeout) == false then                   -- START MONITOR TIMER
            run_after_time(B747_autoboard_phase_timeout, time)
        end
        autoboard.phase[autoboard.step] = 3                                                 -- INCREMENT THE PHASE
        B747_print_autoboard_timer_start(autoboard.step, autoboard.phase[autoboard.step])   -- PRINT THE TIMER MESSAGE
    end
end

function B747_autoboard_step_failed(step, phase)
    B747_print_sequence_status(step, phase, "***  F A I L E D  ***")
    autoboard.sequence_timeout = false
    autoboard.step = 700
end

function B747_autoboard_step_completed(step, phase, message)
    B747_print_sequence_status(step, phase, message)
    B747_print_completed_line()
    autoboard.step = autoboard.step + 1.0
    autoboard.phase[autoboard.step] = 1
end

function B747_autoboard_seq_aborted()
    B747_print_autoboard_abort()
    autoboard.step = 800
    simDR_autoboard_in_progress = 0
    B747_autoboard_init()
    simDR_autostart_in_progress = 0
    B747_autostart_init()
end

function B747_autoboard_seq_completed()
    B747_print_autoboard_completed()
    autoboard.step = 999
    simDR_autoboard_in_progress = 0
    autoboard.in_progress = 0
end

function B747_autoboard_phase_timeout()
    autoboard.sequence_timeout = true
    B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Step Has Timed Out...")
end




function B747_auto_board()

    ----- AUTO-BOARD STEP 0: COMMAND HAS BEEN INVOKED
    if autoboard.step == 0 then
        B747_print_autoboard_begin()                                                        -- PRINT THE AUTO-BOARD HEADER
        autoboard.step = 1                                                                  -- SET THE STEP
        autoboard.phase[autoboard.step] = 1                                                 -- SET THE PHASE


    ----- AUTO-BOARD STEP 1: INIT COLD & DARK
    elseif autoboard.step == 1 then

        -- PHASE 1: SET THE FLAG
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Initialize Aircraft Cold & Dark...")  -- PRINT THE START PHASE MESSAGE
            B747DR_init_manip_CD = 1
            B747DR_init_elec_CD = 1
            B747DR_init_gear_CD = 1
            B747DR_init_com_CD = 1
            B747DR_init_hyd_CD = 1
            B747DR_init_fuel_CD = 1
            B747DR_init_fltmgmt_CD = 1
            B747DR_init_fire_CD = 1
            B747DR_init_engines_CD = 1
            B747DR_init_fltctrls_CD = 1
            B747DR_init_ice_CD = 1
            B747DR_init_air_CD = 1
            B747DR_init_inst_CD = 1
            B747DR_init_fmsL_CD = 1
            B747DR_init_fmsR_CD = 1
            --B747DR_init_autopilot_CD = 1
            B747DR_init_safety_CD = 1
            B747DR_init_warning_CD = 1
            B747DR_init_lighting_CD = 1        
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif B747DR_init_manip_CD == 2                                                -- PHASE WAS SUCCESSFUL, ALL SCRIPTS HAVE BEEN INITIALIZED TO COLD & DARK
                and B747DR_init_elec_CD == 2
                and B747DR_init_gear_CD == 2
                and B747DR_init_com_CD == 2
                and B747DR_init_hyd_CD == 2
                and B747DR_init_fuel_CD == 2
                and B747DR_init_fltmgmt_CD == 2
                and B747DR_init_fire_CD == 2
                and B747DR_init_engines_CD == 2
                and B747DR_init_fltctrls_CD == 2
                and B747DR_init_ice_CD == 2
                and B747DR_init_air_CD == 2
                and B747DR_init_inst_CD == 2
                and B747DR_init_fmsL_CD == 2
                and B747DR_init_fmsR_CD == 2
                --and B747DR_init_autopilot_CD == 2
                and B747DR_init_safety_CD == 2
                and B747DR_init_warning_CD == 2
                and B747DR_init_lighting_CD == 2
            then
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                B747DR_init_manip_CD = 0
                B747DR_init_elec_CD = 0
                B747DR_init_gear_CD = 0
                B747DR_init_com_CD = 0
                B747DR_init_hyd_CD = 0
                B747DR_init_fuel_CD = 0
                B747DR_init_fltmgmt_CD = 0
                B747DR_init_fire_CD = 0
                B747DR_init_engines_CD = 0
                B747DR_init_fltctrls_CD = 0
                B747DR_init_ice_CD = 0
                B747DR_init_air_CD = 0
                B747DR_init_inst_CD = 0
                B747DR_init_fmsL_CD = 0
                B747DR_init_fmsR_CD = 0
                --B747DR_init_autopilot_CD = 0
                B747DR_init_safety_CD = 0
                B747DR_init_warning_CD = 0
                B747DR_init_lighting_CD = 0                  
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Aircraft is Cold & Dark")
        end    
    

    ----- AUTO-BOARD STEP 2: STANDBY POWER SELECTOR SWITCH TO AUTO
    elseif autoboard.step == 2 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Standby Power Selector Switch to AUTO...")  -- PRINT THE START PHASE MESSAGE
            B747DR_elec_standby_power_sel_pos = 1.0                                         -- PUT SELECTOR IN THE AUTO POSITION
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_elec_standby_power_sel_pos > 0.9
                and B747DR_elec_standby_power_sel_pos < 1.1
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Standby Power Selector Switch is set to AUTO")
        end


    ----- AUTO-BOARD STEP 3: UTILITY POWER SWITCHES TO ON
    elseif autoboard.step == 3 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Utility Power Switches to ON...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[11] < 0.95 then
                B747CMD_elec_util_L:once()                                                  -- TURN THE LEFT UTILITY SWITCH ON
            end
            if B747DR_button_switch_position[12] < 0.95 then
                B747CMD_elec_util_R:once()                                                  -- TURN THE RIGHT UTILITY SWITCH ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif B747DR_button_switch_position[11] > 0.95
                and B747DR_button_switch_position[12] > 0.95
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Utility Switches are ON")
        end


    ----- AUTO-BOARD STEP 4: BATTERY SWITCH TO ON
    elseif autoboard.step == 4 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Battery Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            --if simDR_battery_on[0] == 0 then                                                -- BATTERY IS OFF
                if B747DR_button_switch_position[13] < 0.95 then
                    B747CMD_elec_battery:once()                                             -- TURN THE BATTERY ON
                end
            --end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif simDR_battery_on[0] == 1 then                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Battery Switch is ON")
        end


    ----- AUTO-BOARD STEP 5: BUS-TIE SWITCHES TO ON
    elseif autoboard.step == 5 then

        -- PHASE 1: SET THE SWITCHES
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Cross-Tie Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if simDR_cross_tie == 0 then                                                    -- CROSS TIE IS OFF
                if B747DR_button_switch_position[18] < 0.95 then B747CMD_elec_bus_tie_1:once() end  -- TURN THE BUS TIE SWITCH ON
                if B747DR_button_switch_position[19] < 0.95 then B747CMD_elec_bus_tie_2:once() end  -- TURN THE BUS TIE SWITCH ON
                if B747DR_button_switch_position[20] < 0.95 then B747CMD_elec_bus_tie_3:once() end  -- TURN THE BUS TIE SWITCH ON
                if B747DR_button_switch_position[21] < 0.95 then B747CMD_elec_bus_tie_4:once() end  -- TURN THE BUS TIE SWITCH ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif simDR_cross_tie == 1 then                                                    -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Cross-Tie Switch is ON")
        end


    ----- AUTO-BOARD STEP 6: COCKPIT DOME LIGHT ON
    elseif autoboard.step == 6 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Cockpit Dome Light Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            B747DR_flood_light_rheo_overhead = 1.0                                          -- TURN THE DOME LIGHTS ON
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_flood_light_rheo_overhead > 0.99 then                             -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Cockpit Dome Lights are ON")
        end


    ----- AUTO-BOARD STEP 7: GEN CONT SWITCHES TO ON
    elseif autoboard.step == 7 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Gen Control Switches to ON...")  -- PRINT THE START PHASE MESSAGE
            if simDR_generator_on[0] == 0 then                                              -- GENERATOR #1 IS OFF
                if B747DR_button_switch_position[22] < 0.95 then
                    B747CMD_elec_gen_ctrl_1:once()                                          -- TURN THE GENERATOR ON
                end
            end
            if simDR_generator_on[1] == 0 then                                              -- GENERATOR #2 IS OFF
                if B747DR_button_switch_position[23] < 0.95 then
                    B747CMD_elec_gen_ctrl_2:once()                                          -- TURN THE GENERATOR ON
                end
            end
            if simDR_generator_on[2] == 0 then                                              -- GENERATOR #3 IS OFF
                if B747DR_button_switch_position[24] < 0.95 then
                    B747CMD_elec_gen_ctrl_3:once()                                          -- TURN THE GENERATOR ON
                end
            end
            if simDR_generator_on[3] == 0 then                                              -- GENERATOR #4 IS OFF
                if B747DR_button_switch_position[25] < 0.95 then
                    B747CMD_elec_gen_ctrl_4:once()                                          -- TURN THE GENERATOR ON
                end
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_button_switch_position[22] > 0.05                                 -- PHASE WAS SUCCESSFUL
                and B747DR_button_switch_position[23] > 0.05
                and B747DR_button_switch_position[24] > 0.05
                and B747DR_button_switch_position[25] > 0.05
            then
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Generator Switches are ON")
        end


    ----- AUTO-BOARD STEP 8: APU SELECTOR SWITCH TO START
    elseif autoboard.step == 8 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "APU Selector Switch to START...")  -- PRINT THE START PHASE MESSAGE
            if simDR_apu_start_switch_mode < 2 and simDR_apu_running == 0 then              -- APU SWITCH IS NOT "START" AND APU IS NOT RUNNING
                if B747DR_elec_apu_sel_pos < 2 then simCMD_apu_start:once() end             -- SELECTOR TO START POSITION
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(30.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif simDR_apu_running == 1 and simDR_apu_N1_pct > 95.0 then                  -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
	     
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, APU is Running")
        end


    ----- AUTO-BOARD STEP 9: APU GENERATOR SWITCH TO ON
    elseif autoboard.step == 9 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "APU Generator Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if simDR_apu_gen_on == 0 then                                                   -- APU GENERATOR IS OFF
                B747CMD_elec_apu_gen_1:once()                                               -- ACTUATE THE APU GEN BUTTON SWITCH
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif simDR_apu_gen_on == 1 then                                                   -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, APU Generator is ON")
        end


    ----- AUTO-BOARD STEP 10: CABIN LIGHTS SWITCH
    elseif autoboard.step == 10 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Cabin Lights Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[37] < 0.95 then                                -- CABIN LIGHTS ARE OFF
                B747CMD_cabin_lights_switch:once()                                          -- TURN THE CABIN LIGHTS ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_toggle_switch_position[37] > 0.95 then                             -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Cabin Lights are ON")
        end


    ----- AUTO-BOARD STEP 11: ENGINE HYD PUMP SWITCHES TO ON
    elseif autoboard.step == 11 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Engine Hyd Ppump Switches to ON...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[30] < 0.95 then                                -- PUMP SWITCH IS OFF
                B747CMD_hyd_pump_1:once()                                                   -- TURN THE PUMP ON
            end
            if B747DR_button_switch_position[31] < 0.95 then                                -- PUMP SWITCH IS OFF
                B747CMD_hyd_pump_2:once()                                                   -- TURN THE PUMP ON
            end
            if B747DR_button_switch_position[32] < 0.95 then                                -- PUMP SWITCH IS OFF
                B747CMD_hyd_pump_3:once()                                                   -- TURN THE PUMP ON
            end
            if B747DR_button_switch_position[33] < 0.95 then                                -- PUMP SWITCH IS OFF
                B747CMD_hyd_pump_4:once()                                                   -- TURN THE PUMP ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif B747DR_button_switch_position[30] > 0.95                                     -- PHASE WAS SUCCESSFUL
                and B747DR_button_switch_position[31] > 0.95
                and B747DR_button_switch_position[32] > 0.95
                and B747DR_button_switch_position[33] > 0.95
            then
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Engine Hyd Pump Switches are ON")
        end


    ----- AUTO-BOARD STEP 12: AUTOSTART SWITCH TO ON
    elseif autoboard.step == 12 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Autostart Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[45] < 0.05 then                                -- SWITCH IS OFF
                B747CMD_start_autostart:once()                                              -- TURN THE SWITCH ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_button_switch_position[45] > 0.95 then                                -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Autostart Switch is ON")
        end


    ----- AUTO-BOARD STEP 13: FUEL X-FEED SWITCHES 1&4 TO ON
    elseif autoboard.step == 13 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Fuel Xfeed Switches 1&4 to ON...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[48] < 0.95 then B747CMD_fuel_xfeed_vlv_1:once() end
            if B747DR_button_switch_position[51] < 0.95 then B747CMD_fuel_xfeed_vlv_4:once() end
             autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_button_switch_position[48] > 0.05
                and B747DR_button_switch_position[51] > 0.05
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Fuel Xfeed Switches 1&4 are ON")
        end


     ----- AUTO-BOARD STEP 14: YAW DAMPER SWITCHES TO ON
    elseif autoboard.step == 14 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Fuel System Switches to ON...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[82] < 0.95 then B747CMD_yaw_damper_upr:once() end
            if B747DR_button_switch_position[83] < 0.95 then B747CMD_yaw_damper_lwr:once() end
             autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_button_switch_position[82] > 0.05
                and B747DR_button_switch_position[83] > 0.05
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Fuel System Switches are ON")
        end


     ----- AUTO-BOARD STEP 15: A/C PACK SELECTOR SWITCHES TO NORM
    elseif autoboard.step == 15 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "A/C Pack Selector Switches to NORM...")    -- PRINT THE START PHASE MESSAGE
            B747DR_pack_ctrl_sel_pos[0] = 1
            B747DR_pack_ctrl_sel_pos[1] = 1
            B747DR_pack_ctrl_sel_pos[2] = 1
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_pack_ctrl_sel_pos[0] == 1
                and B747DR_pack_ctrl_sel_pos[1] == 1
                and B747DR_pack_ctrl_sel_pos[2] == 1
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, A/C Pack Selector Switches are set to NORM")
        end


    ----- AUTO-BOARD STEP 16: LEFT & RIGHT BLEED AIR ISOLATION SWITCHES TO ON
    elseif autoboard.step == 16 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "APU Bleed Air Isolation Switches to ON...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[75] < 0.95 then B747CMD_bleed_air_isln_vlv_L:once() end                                    -- SWITCH IS OFF, TURN THE SWITCH ON
            if B747DR_button_switch_position[76] < 0.95 then B747CMD_bleed_air_isln_vlv_R:once() end                                    -- SWITCH IS OFF, TURN THE SWITCH ON
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_button_switch_position[75] > 0.05
                and B747DR_button_switch_position[76] > 0.05
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, APU Bleed Air Isolation Switches are ON")
        end


    ----- AUTO-BOARD STEP 17: APU BLEED AIR SWITCH TO ON
    elseif autoboard.step == 17 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "APU Bleed Air Switch to ON...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[81] < 0.05 then B747CMD_bleed_air_vlv_apu:once() end                           -- SWITCH IS OFF, TURN THE SWITCH ON
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif B747DR_button_switch_position[81] > 0.95 then                                -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, APU Bleed Air Switch is ON")
        end
        
        
    ----- AUTO-BOARD STEP 18: ENGINE BLEED AIR VALVE SWITCHES TO ON
    elseif autoboard.step == 18 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Engine Bleed Air Switches to ON...")   -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[77] < 0.95 then B747CMD_bleed_air_vlv_engine_1:once() end                          -- SWITCH IS OFF, TURN THE SWITCH ON
            if B747DR_button_switch_position[78] < 0.95 then B747CMD_bleed_air_vlv_engine_2:once() end
            if B747DR_button_switch_position[79] < 0.95 then B747CMD_bleed_air_vlv_engine_3:once() end
            if B747DR_button_switch_position[80] < 0.95 then B747CMD_bleed_air_vlv_engine_4:once() end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(7.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif B747DR_button_switch_position[77] > 0.95
                and B747DR_button_switch_position[78] > 0.95
                and B747DR_button_switch_position[79] > 0.95
                and B747DR_button_switch_position[80] > 0.95
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Engine Bleed Air Switches are ON")
        end        
        

    ----- AUTO-BOARD STEP 19: NAV LIGHTS ON
    elseif autoboard.step == 19 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "NAV Lights Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if simDR_nav_lights_switch == 0 then                                            -- NAV LIGHTS ARE OFF
                if B747DR_toggle_switch_position[9] < 0.95 then B747CMD_nav_light_switch:once() end     -- TURN THE NAV LIGHT SWITCH ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif simDR_nav_lights_switch == 1 then                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, NAV Light Switch is ON")
        end


    ----- AUTO-BOARD STEP 20: INSTRUMENT PANEL(S) LIGHT SWITCH(ES)
    elseif autoboard.step == 20 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Panel Backlight Switches to ON...")  -- PRINT THE START PHASE MESSAGE
            simDR_instrument_brightness_switch[7] = 0.75                                    -- OVERHEAAD PANEL LIGHTS ON
            simDR_panel_brightness_switch[3] = 0.75                                         -- GLARESHIELD/MCP PANEL LIGHTS ON
            simDR_instrument_brightness_switch[6] = 0.75                                    -- CAPTAIN PANEL LIGHTS ON
            simDR_instrument_brightness_switch[8] = 0.75                                    -- FIRST OFFICER PANEL LIGHTS ON
            simDR_panel_brightness_switch[2] = 0.75                                         -- AISLE STAND PANEL LIGHTS ON
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif simDR_instrument_brightness_switch[7] >= 0.74
                and simDR_panel_brightness_switch[3] >= 0.74
                and simDR_instrument_brightness_switch[6] >= 0.75
                and simDR_instrument_brightness_switch[8] >= 0.75
                and simDR_panel_brightness_switch[2] >= 0.75
            then                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Panel Light Backlight are ON")
        end


    ----- AUTO-BOARD STEP 21: LOGO LIGHTS SWITCH
    elseif autoboard.step == 21 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Logo Lights Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[12] < 0.95 then                                -- LOGO LIGHTS ARE OFF
                B747CMD_logo_light_switch:once()                                            -- LOGO THE CABIN LIGHTS ON
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_toggle_switch_position[12] > 0.95 then                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Logo Lights are ON")
        end


    ----- AUTO-BOARD STEP 22: GEAR HANDLE DOWN
    elseif autoboard.step == 22 then

        -- PHASE 1: SET THE HANDLE
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Gear Handle to DOWN...")  -- PRINT THE START PHASE MESSAGE
            if simDR_gear_handle_down == 0 then                                             -- GEAR HANDLE IS NOT DOWN
                B747DR_gear_handle = 0.0                                                    -- MOVE THE GEAR HANDLE TO THE DOWN POSITION
            end
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            --end
            elseif simDR_gear_handle_down == 1 then                                             -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Gear Handle is DOWN")
        end


    ----- AUTO-BOARD STEP 23: MCP FLOOD LIGHTS
    elseif autoboard.step == 23 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "MCP Flood Lights Switch: Set...")  -- PRINT THE START PHASE MESSAGE
            B747DR_flood_light_rheo_mcp = 0.75
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_flood_light_rheo_mcp >= 0.74 then                                 -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "LMCP Flood Lights Switch is Set")
        end


     ----- AUTO-BOARD STEP 24: NO SMOKING SELECTOR SWITCH TO AUTO
    elseif autoboard.step == 24 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "No Smoking Selector Switch to AUTO...")    -- PRINT THE START PHASE MESSAGE
            B747DR_sfty_no_smoke_sel_dial_pos = 1
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_sfty_no_smoke_sel_dial_pos == 1 then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, No Smoking Selector Switch is set to AUTO")
        end


     ----- AUTO-BOARD STEP 25: SEAT BELT SELECTOR SWITCH TO AUTO
    elseif autoboard.step == 25 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Seat Belt Selector Switch to AUTO...")    -- PRINT THE START PHASE MESSAGE
            B747DR_sfty_seat_belts_sel_dial_pos = 1
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_sfty_seat_belts_sel_dial_pos == 1 then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Completed, Seat Belt  Selector Switch is set to AUTO")
        end


    ----- AUTO-BOARD STEP 26: COCKPIT DOME LIGHT OFF
    elseif autoboard.step == 26 then

        -- PHASE 1: SET THE SWITCH
        if autoboard.phase[autoboard.step] == 1 then
            B747_print_sequence_status(autoboard.step, autoboard.phase[autoboard.step], "Cockpit Dome Light Switch to OFF...")  -- PRINT THE START PHASE MESSAGE
            B747DR_flood_light_rheo_overhead = 0.0                                          -- TURN THE DOME LIGHTS ON
            autoboard.phase[autoboard.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autoboard_phase_monitor(1.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autoboard.phase[autoboard.step] == 3 then
            if autoboard.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autoboard_step_failed(autoboard.step, autoboard.phase[autoboard.step])
            elseif B747DR_flood_light_rheo_overhead < 0.05 then                             -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autoboard_phase_timeout) == true then
                    stop_timer(B747_autoboard_phase_timeout)                                -- KILL THE TIMER
                end
                autoboard.phase[autoboard.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autoboard.phase[autoboard.step] == 4 then
            B747_autoboard_step_completed(autoboard.step, autoboard.phase[autoboard.step], "Cockpit Dome Lights are OFF")
        end


    ----- AUTOBOARD SEQUENCE COMPLETED
    autoboard.step = 888


   ----- AUTO-BOARD STEP 700: ABORT
   elseif autoboard.step == 700 then
        B747_autoboard_seq_aborted()


    ----- AUTO-BOARD STEP 888: SEQUENCE COMPLETED
    elseif autoboard.step == 888 then
        B747_autoboard_seq_completed()
        --B747_autostart_init()

   end  -- AUTO-BOARD STEPS

end -- AUTO-BOARD SEQUENCE







----- AUTO-START SEQUENCE ---------------------------------------------------------------

function B747_autostart_init()
    if is_timer_scheduled(B747_autostart_phase_timeout) == true then
        stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
    end	
    autostart.step = -1
    autostart.phase = {}
    autostart.sequence_timeout = false
    autostart.in_progress = 0
end

function B747_print_autostart_begin()
    print("+----------------------------------------------+")
    print("|          AUTO-START SEQUENCE BEGIN           |")
    print("+----------------------------------------------+")
end

function B747_print_autostart_abort()
    print("+----------------------------------------------+")
    print("|         AUTO-START SEQUENCE ABORTED          |")
    print("+----------------------------------------------+")
end

function B747_print_autostart_completed()
    print("+----------------------------------------------+")
    print("|        AUTO-START SEQUENCE COMPLETED         |")
    print("+----------------------------------------------+")
end

function B747_print_autostart_monitor(step, phase)
    B747_print_sequence_status(step, phase, "Monitoring...")
end

function B747_print_autostart_timer_start(step, phase)
    B747_print_sequence_status(step, phase, "Auto-Start Phase Timer Started...")
end

function B747_autostart_phase_monitor(time)
    if autostart.phase[autostart.step] == 2 then
        B747_print_autostart_monitor(autostart.step, autostart.phase[autostart.step])       -- PRINT THE MONITOR PHASE MESSAGE
        if is_timer_scheduled(B747_autostart_phase_timeout) == false then                   -- START MONITOR TIMER
            run_after_time(B747_autostart_phase_timeout, time)
        end
        autostart.phase[autostart.step] = 3                                                 -- INCREMENT THE PHASE
        B747_print_autostart_timer_start(autostart.step, autostart.phase[autostart.step])   -- PRINT THE TIMER MESSAGE
    end
end

function B747_autostart_step_failed(step, phase)
    B747_print_sequence_status(step, phase, "***  F A I L E D  ***")
    autostart.sequence_timeout = false
    autostart.step = 700
end

function B747_autostart_step_completed(step, phase, message)
    B747_print_sequence_status(step, phase, message)
    B747_print_completed_line()
    autostart.step = autostart.step + 1.0
    autostart.phase[autostart.step] = 1
end

function B747_autostart_seq_aborted()
    B747_print_autostart_abort()
    autostart.step = 800
    simDR_autoboard_in_progress = 0
    B747_autoboard_init()
    simDR_autostart_in_progress = 0
    B747_autostart_init()
end

function B747_autostart_seq_completed()
    B747_print_autostart_completed()
    autostart.step = 999
    simDR_autostart_in_progress = 0
    B747_autoboard_init()
    B747_autostart_init()
end

function B747_autostart_phase_timeout()
    autostart.sequence_timeout = true
    B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Step Has Timed Out...")
end







function B747_auto_start()

    ----- AUTO-START STEP 0: COMMAND HAS BEEN INVOKED
    if autostart.step == 0 then

        -- RUN AUTOBOARD SEQUENCE IF NOT ALREADY PROCESSED
        if autoboard.step < 0 then
            simCMD_autoboard:once()
        else
            -- AUTOBOARD SEQUENCE COMPLETED: BEGIN AUTOSTART
            if autoboard.step == 999 then
                --simDR_autostart_in_progress = 1
                autostart.in_progress = 1
                B747_print_autostart_begin()
                autostart.step = 1
                autostart.phase[autostart.step] = 1
                B747_autoboard_init()
            end
        end


    ----- AUTO-START STEP 1: INITIALIZE ENGINES
	elseif autostart.step == 1 then
	
		-- PHASE 1: INITIALIZE
		if autostart.phase[autostart.step] == 1 then
		    B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Initializing Engines...")  -- PRINT THE START PHASE MESSAGE
		    B747DR_init_engines_CD = 1														-- SET THE INIT FLAG
		    autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
		end
		
		-- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
		B747_autostart_phase_monitor(2.0)
		
		-- PHASE 3: MONITOR THE STATUS
		if autostart.phase[autostart.step] == 3 then
		    if autostart.sequence_timeout == true then                                      -- PHASE FAILED
		        B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
		    elseif B747DR_init_engines_CD == 2 then                                         -- PHASE WAS SUCCESSFUL
		        if is_timer_scheduled(B747_autostart_phase_timeout) == true then
		            stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
		        end
		        B747DR_init_engines_CD = 0													-- RESET THE INIT FLAG
		        autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
		    end
		end
		
		-- PHASE 4: COMPLETE THE STEP
		if autostart.phase[autostart.step] == 4 then
		    B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engines Initialized")
		end   
	

    ----- AUTO-START STEP 2: HYD DEMAND PUMP #4 SWITCH TO AUX
    elseif autostart.step == 2 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Hyd Demand Pump #4 Switch to AUX...")  -- PRINT THE START PHASE MESSAGE
            B747DR_hyd_dmd_pmp_sel_pos[3] = -1                                              -- SET THE SWITCH TO "AUTO"
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(2.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_hyd_dmd_pmp_sel_pos[3] == -1 then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Hyd Demand Pump #4 Switch to AUX")
        end


    ----- AUTO-START STEP 3: HYD DEMAND PUMP #1, 2, 3 SWITCHES TO AUTO
    elseif autostart.step == 3 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Hyd Demand Pump #1, 2, 3 set to AUTO...")  -- PRINT THE START PHASE MESSAGE
            B747DR_hyd_dmd_pmp_sel_pos[0] = 1                                               -- SET THE SWITCH TO "AUTO"
            B747DR_hyd_dmd_pmp_sel_pos[1] = 1                                               -- SET THE SWITCH TO "AUTO"
            B747DR_hyd_dmd_pmp_sel_pos[2] = 1                                               -- SET THE SWITCH TO "AUTO"
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(2.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_hyd_dmd_pmp_sel_pos[0] == 1
                and B747DR_hyd_dmd_pmp_sel_pos[1] == 1
                and B747DR_hyd_dmd_pmp_sel_pos[2] == 1
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Hyd Demand Pumps #1, 2, 3 are set to AUTO")
        end


     ----- AUTO-START STEP 4: ALL MAIN TANK FUEL PUMP SWITCHES TO ON
    elseif autostart.step == 4 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Main Tank Fuel Pump Switches to ON...")    -- PRINT THE START PHASE MESSAGE
            --if B747DR_button_switch_position[54] < 0.05 then B747CMD_fuel_stab_tnk_pump_L:once() end
            --if B747DR_button_switch_position[55] < 0.05 then B747CMD_fuel_stab_tnk_pump_R:once() end
            if B747DR_button_switch_position[56] < 0.05 then B747CMD_fuel_main_pump_fwd_1:once() end
            if B747DR_button_switch_position[57] < 0.05 then B747CMD_fuel_main_pump_fwd_2:once() end
            if B747DR_button_switch_position[58] < 0.05 then B747CMD_fuel_main_pump_fwd_3:once() end
            if B747DR_button_switch_position[59] < 0.05 then B747CMD_fuel_main_pump_fwd_4:once() end
            if B747DR_button_switch_position[60] < 0.05 then B747CMD_fuel_main_pump_aft_1:once() end
            if B747DR_button_switch_position[61] < 0.05 then B747CMD_fuel_main_pump_aft_2:once() end
            if B747DR_button_switch_position[62] < 0.05 then B747CMD_fuel_main_pump_aft_3:once() end
            if B747DR_button_switch_position[63] < 0.05 then B747CMD_fuel_main_pump_aft_4:once() end
            if B747DR_button_switch_position[64] < 0.05 then B747CMD_fuel_overd_pump_fwd_2:once() end
            if B747DR_button_switch_position[65] < 0.05 then B747CMD_fuel_overd_pump_fwd_3:once() end
            if B747DR_button_switch_position[66] < 0.05 then B747CMD_fuel_overd_pump_aft_2:once() end
            if B747DR_button_switch_position[67] < 0.05 then B747CMD_fuel_overd_pump_aft_3:once() end
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_button_switch_position[56] > 0.95
                and B747DR_button_switch_position[57] > 0.95
                and B747DR_button_switch_position[58] > 0.95
                and B747DR_button_switch_position[59] > 0.95
                and B747DR_button_switch_position[60] > 0.95
                and B747DR_button_switch_position[61] > 0.95
                and B747DR_button_switch_position[62] > 0.95
                and B747DR_button_switch_position[63] > 0.95
                and B747DR_button_switch_position[64] > 0.95
                and B747DR_button_switch_position[65] > 0.95
                and B747DR_button_switch_position[66] > 0.95
                and B747DR_button_switch_position[67] > 0.95
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Main Tank Fuel Pump Switches are ON")
        end


     ----- AUTO-START STEP 5: CENTER TANK FUEL PUMP SWITCHES TO ON
    elseif autostart.step == 5 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Center Tank Fuel Pump Switches to ON...")    -- PRINT THE START PHASE MESSAGE
            if simDR_fuel_tank_weight_kg[0] > 7700.0 then
                if B747DR_button_switch_position[52] < 0.05 then B747CMD_fuel_ctr_wing_tnk_pump_L:once() end
                if B747DR_button_switch_position[53] < 0.05 then B747CMD_fuel_ctr_wing_tnk_pump_R:once() end
            end
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif (simDR_fuel_tank_weight_kg[0] > 7700.0
                and B747DR_button_switch_position[52] > 0.95
                and B747DR_button_switch_position[53] > 0.95)
                or
                simDR_fuel_tank_weight_kg[0] < 7700.0
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Center Tank Fuel Pump Switches are ON")
        end


    ----- AUTO-START STEP 6: BEACON LIGHT SWITCH TO BOTH
    elseif autostart.step == 6 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Beacon Light Switch to BOTH...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[8] == 0.0 then                                 -- SET THE SWITCH
                B747CMD_beacon_light_switch_down:once()
            elseif B747DR_toggle_switch_position[8] == 1.0 then                                 -- SET THE SWITCH
                B747CMD_beacon_light_switch_down:once()
                B747CMD_beacon_light_switch_down:once()
            end
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(2.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_toggle_switch_position[8] == -1 then                            	-- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Beacon Light Switch is set to BOTH")
        end
        

    ----- AUTO-START STEP 7: PUSH RECALL SWITCH BUTTON
    elseif autostart.step == 7 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "RECALL Button: PUSH...")  -- PRINT THE START PHASE MESSAGE
            B747CMD_dsp_rcl_switch:once()                                                   -- PUSH THE SWITCH
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(2.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            else                                                                            -- PHASE WAS SUCCESSFUL
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, RECALL Button was Pushed")
        end


    ----- AUTO-START STEP 8: PUSH CANX SWITCH BUTTON
    elseif autostart.step == 8 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "CANX Button: PUSH...")  -- PRINT THE START PHASE MESSAGE
            B747CMD_dsp_canc_switch:once()                                                  -- PUSH THE SWITCH
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(2.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            else                                                                            -- PHASE WAS SUCCESSFUL
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, CANX Button was Pushed")
        end
        
       
     ----- AUTO-START STEP 9: A/C PACK SELECTOR SWITCHES TO OFF
    elseif autostart.step == 9 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "A/C Pack Selector Switches to OFF...")    -- PRINT THE START PHASE MESSAGE
            B747DR_pack_ctrl_sel_pos[0] = 0
            B747DR_pack_ctrl_sel_pos[1] = 0
            B747DR_pack_ctrl_sel_pos[2] = 0
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_pack_ctrl_sel_pos[0] == 0
                and B747DR_pack_ctrl_sel_pos[1] == 0
                and B747DR_pack_ctrl_sel_pos[2] == 0
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, A/C Pack Selector Switches are set to OFF")
        end        
        
       
    ----------------------------------------------------------------------------
    ---                          ENGINE #4 STARTUP                           ---
    ----------------------------------------------------------------------------

    ----- AUTO-START STEP 10: ENGINE #4 START SWITCH - PULL
    elseif autostart.step == 10 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 4 Start Switch - Pull...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[19] < 0.05 then B747CMD_engine_start_switch4:once() end                            -- SWITCH IS SET TO OFF, PULL IT OUT
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[19] > 0.95 then                                -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 4 Start Switch Pulled")
        end


    ----- AUTO-START STEP 11: ENGINE #4 FUEL CONTROL SWITCH TO RUN
    elseif autostart.step == 11 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 4 Fuel Control Switch to RUN...")     -- PRINT THE START PHASE MESSAGE
            if B747DR_fuel_control_toggle_switch_pos[3] < 0.05 then B747CMD_fuel_control_switch4:once() end                             -- SWITCH IS SET TO OFF, SET IT TO RUN
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_fuel_control_toggle_switch_pos[3] > 0.95 then                         -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 4 Fuel Control Switch set to RUN")
        end


    ----- AUTO-START STEP 12: ENGINE #4 SPOOLUP
    elseif autostart.step == 12 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 4 Spoolup...")  -- PRINT THE START PHASE MESSAGE
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(120.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[19] < 0.05 then                                -- PHASE WAS SUCCESSFUL, ENGINE HAS STARTED
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 4 is Running")
        end


    ----------------------------------------------------------------------------
    ---                          ENGINE #1 STARTUP                           ---
    ----------------------------------------------------------------------------

    ----- AUTO-START STEP 13: ENGINE #1 START SWITCH - PULL
    elseif autostart.step == 13 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 1 Start Switch - Pull...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[16] < 0.05 then B747CMD_engine_start_switch1:once() end                            -- SWITCH IS SET TO OFF, PULL IT OUT
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[16] > 0.95 then                                -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 1 Start Switch Pulled")
        end


    ----- AUTO-START STEP 14: ENGINE #1 FUEL CONTROL SWITCH TO RUN
    elseif autostart.step == 14 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 1 Fuel Control Switch to RUN...")     -- PRINT THE START PHASE MESSAGE
            if B747DR_fuel_control_toggle_switch_pos[0] < 0.05 then B747CMD_fuel_control_switch1:once() end                             -- SWITCH IS SET TO OFF, SET IT TO RUN
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_fuel_control_toggle_switch_pos[0] > 0.95 then                         -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 1 Fuel Control Switch set to RUN")
        end


    ----- AUTO-START STEP 15: ENGINE #1 SPOOLUP
    elseif autostart.step == 15 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 1 Spoolup...")  -- PRINT THE START PHASE MESSAGE
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(120.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[16] < 0.05 then                                -- PHASE WAS SUCCESSFUL, ENGINE HAS STARTED
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 1 is Running")
        end


    ----------------------------------------------------------------------------
    ---                          ENGINE #2 STARTUP                           ---
    ----------------------------------------------------------------------------

    ----- AUTO-START STEP 16: ENGINE #2 START SWITCH - PULL
    elseif autostart.step == 16 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 2 Start Switch - Pull...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[17] < 0.05 then B747CMD_engine_start_switch2:once() end    -- SWITCH IS SET TO OFF, PULL IT OUT
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[17] > 0.95 then                                -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 2 Start Switch Pulled")
        end


    ----- AUTO-START STEP 17: ENGINE #2 FUEL CONTROL SWITCH TO RUN
    elseif autostart.step == 17 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 2 Fuel Control Switch to RUN...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_fuel_control_toggle_switch_pos[1] < 0.05 then B747CMD_fuel_control_switch2:once() end    -- SWITCH IS SET TO OFF, SET IT TO RUN
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_fuel_control_toggle_switch_pos[1] > 0.95 then                         -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 2 Fuel Control Switch set to RUN")
        end


    ----- AUTO-START STEP 18: ENGINE #2 SPOOLUP
    elseif autostart.step == 18 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 2 Spoolup...")  -- PRINT THE START PHASE MESSAGE
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(120.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[17] < 0.05 then                                -- PHASE WAS SUCCESSFUL, ENGINE HAS STARTED
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 2 is Running")
        end


    ----------------------------------------------------------------------------
    ---                          ENGINE #3 STARTUP                           ---
    ----------------------------------------------------------------------------

    ----- AUTO-START STEP 19: ENGINE #3 START SWITCH - PULL
    elseif autostart.step == 19 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 3 Start Switch - Pull...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_toggle_switch_position[18] < 0.05 then B747CMD_engine_start_switch3:once() end    -- SWITCH IS SET TO OFF, PULL IT OUT
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[18] > 0.95 then                                -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 3 Start Switch Pulled")
        end


    ----- AUTO-START STEP 20: ENGINE #3 FUEL CONTROL SWITCH TO RUN
    elseif autostart.step == 20 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 3 Fuel Control Switch to RUN...")  -- PRINT THE START PHASE MESSAGE
            if B747DR_fuel_control_toggle_switch_pos[2] < 0.05 then B747CMD_fuel_control_switch3:once() end    -- SWITCH IS SET TO OFF, SET IT TO RUN
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_fuel_control_toggle_switch_pos[2] > 0.95 then                         -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 3 Fuel Control Switch set to RUN")
        end


    ----- AUTO-START STEP 21: ENGINE #3 SPOOLUP
    elseif autostart.step == 21 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Engine # 3 Spoolup...")  -- PRINT THE START PHASE MESSAGE
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(120.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_toggle_switch_position[18] < 0.05 then                                -- PHASE WAS SUCCESSFUL, ENGINE HAS STARTED
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Engine # 3 is Running")
        end


    ----- AUTO-START STEP 22: APU GENERATOR SWITCH TO OFF
    elseif autostart.step == 22 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "APU Generator Switch to OFF...")  -- PRINT THE START PHASE MESSAGE
            if simDR_apu_gen_on == 1 then                                                   -- APU GENERATOR IS OFF
                B747CMD_elec_apu_gen_1:once()                                               -- ACTUATE THE APU GEN BUTTON SWITCH (OFF)
            end
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif simDR_apu_gen_on == 0 then                                               -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, APU Generator is OFF")
        end


    ----- AUTO-START STEP 23: APU SELECTOR SWITCH TO OFF
    elseif autostart.step == 23 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "APU Selector Switch to OFF...")  -- PRINT THE START PHASE MESSAGE
            if simDR_apu_start_switch_mode > 0 and simDR_apu_running == 1 then              -- APU SWITCH IS NOT "OFF" AND APU IS RUNNING
                if B747DR_elec_apu_sel_pos > 0 then simCMD_apu_off:once() end               -- SELECTOR TO OFF POSITION
            end
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE SIM STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            --end
            elseif B747DR_elec_apu_sel_pos == 0 then                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
         end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, APU Selector Switch is OFF")
        end


    ----- AUTO-START STEP 24: APU BLEED AIR SWITCH TO OFF
    elseif autostart.step == 24 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "APU Bleed Air Switch to OFF...")    -- PRINT THE START PHASE MESSAGE
            if B747DR_button_switch_position[81] > 0.95 then B747CMD_bleed_air_vlv_apu:once() end                           -- SWITCH IS OFF, TURN THE SWITCH ON
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_button_switch_position[81] < 0.05 then                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, APU Bleed Air Switch is OFF")
        end


    ----- AUTO-START STEP 25: HYD DEMAND PUMP SELECTOR SWITCHES TO AUTO
    elseif autostart.step == 25 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Hyd Demand Pump #1, 2, 3 set to AUTO...")  -- PRINT THE START PHASE MESSAGE
            B747DR_hyd_dmd_pmp_sel_pos[0] = 1                                               -- SET THE SWITCH TO "AUTO"
            B747DR_hyd_dmd_pmp_sel_pos[1] = 1                                               -- SET THE SWITCH TO "AUTO"
            B747DR_hyd_dmd_pmp_sel_pos[2] = 1                                               -- SET THE SWITCH TO "AUTO"
            B747DR_hyd_dmd_pmp_sel_pos[3] = 1                                               -- SET THE SWITCH TO "AUTO"
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(2.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_hyd_dmd_pmp_sel_pos[0] == 1
                and B747DR_hyd_dmd_pmp_sel_pos[1] == 1
                and B747DR_hyd_dmd_pmp_sel_pos[2] == 1
                and B747DR_hyd_dmd_pmp_sel_pos[3] == 1
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Hyd Demand Pumps #1, 2, 3 are set to AUTO")
        end


     ----- AUTO-START STEP 26: A/C PACK SELECTOR SWITCHES TO OFF
    elseif autostart.step == 26 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "A/C Pack Selector Switches to NORM...")    -- PRINT THE START PHASE MESSAGE
            B747DR_pack_ctrl_sel_pos[0] = 1
            B747DR_pack_ctrl_sel_pos[1] = 1
            B747DR_pack_ctrl_sel_pos[2] = 1
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(10.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_pack_ctrl_sel_pos[0] == 1
                and B747DR_pack_ctrl_sel_pos[1] == 1
                and B747DR_pack_ctrl_sel_pos[2] == 1
            then                                                                            -- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, A/C Pack Selector Switches are set to NORM")
        end
        
          
     ----- AUTO-START STEP 27: STROBE LIGHT SWITCH TO ON
    elseif autostart.step == 27 then

        -- PHASE 1: SET THE SWITCH
        if autostart.phase[autostart.step] == 1 then
            B747_print_sequence_status(autostart.step, autostart.phase[autostart.step], "Strobe Light Switch to ON...")  -- PRINT THE START PHASE MESSAGE
            if simDR_strobe_lights_switch == 0 then                                        -- STROBE LIGHTS ARE OFF
                if B747DR_toggle_switch_position[10] < 0.95 then B747CMD_strobe_light_switch:once() end     -- TURN THE STROBE LIGHT SWITCH ON
            end
            autostart.phase[autostart.step] = 2                                             -- INCREMENT THE PHASE
        end

        -- PHASE 2: PRINT MONITOR STATUS AND START PHASE TIMER
        B747_autostart_phase_monitor(5.0)

        -- PHASE 3: MONITOR THE STATUS
        if autostart.phase[autostart.step] == 3 then
            if autostart.sequence_timeout == true then                                      -- PHASE FAILED
                B747_autostart_step_failed(autostart.step, autostart.phase[autostart.step])
            elseif B747DR_toggle_switch_position[10] > 0.95 then                           	-- PHASE WAS SUCCESSFUL
                if is_timer_scheduled(B747_autostart_phase_timeout) == true then
                    stop_timer(B747_autostart_phase_timeout)                                -- KILL THE TIMER
                end	            
                autostart.phase[autostart.step] = 4                                         -- INCREMENT THE PHASE
            end
        end

        -- PHASE 4: COMPLETE THE STEP
        if autostart.phase[autostart.step] == 4 then
            B747_autostart_step_completed(autostart.step, autostart.phase[autostart.step], "Completed, Strobe Light Switch is set to ON")
        end
                
        
       
    ----- AUTO-START SEQUENCE COMPLETED
    elseif autostart.step == 28 then
        autostart.step = 888


    ----- AUTO-START STEP 700: ABORT
    elseif autostart.step == 700 then
        B747_autostart_seq_aborted()


    ----- AUTO-START STEP 888: SEQUENCE COMPLETED
    elseif autostart.step == 888 then
        B747_autostart_seq_completed()


    end -- AUTO-START STEPS

end -- AUTO-START SEQUENCE









function B747_ai_quick_start()
	
	-- AI
	B747_set_ai_all_modes()	
	B747_set_ai_CD()
	B747_set_ai_ER()
    
    -- MANIPULATORS
	B747CMD_ai_manip_quick_start:once()
	
	-- ELECTRICAL
	B747CMD_ai_elec_quick_start:once()
	
	-- GEAR
	B747CMD_ai_gear_quick_start:once()
	
	-- COMMUNICATIONS
	B747CMD_ai_com_quick_start:once()
	
	-- HYDRAULICS
	B747CMD_ai_hyd_quick_start:once()
	
	-- FUEL
	B747CMD_ai_fuel_quick_start:once()
	
	-- FLIGHT MANAGEMENT
	B747CMD_ai_fltmgmt_quick_start:once()
	
	-- FIRE
	B747CMD_ai_fire_quick_start:once()
	
	-- ENGINES
	B747CMD_ai_engines_quick_start:once()
	
	-- FLIGHT CONTROLS
	B747CMD_ai_fltctrls_quick_start:once()
	
	-- ANTI-ICE
	B747CMD_ai_antiice_quick_start:once()
	
	-- AIR
	B747CMD_ai_air_quick_start:once()
	
	-- FLIGHT INSTRUMENTS
	B747CMD_ai_fltinst_quick_start:once()
	
	-- FMS L
	B747CMD_ai_fmsL_quick_start:once()
	
	-- FMS R
	B747CMD_ai_fmsR_quick_start:once()
	
	-- AUTOPILOT
	B747CMD_ai_ap_quick_start:once()
	
	-- SAFTEY
	B747CMD_ai_safety_quick_start:once()
	
	-- WARNING
	B747CMD_ai_warning_quick_start:once()
	
	-- LIGHTING
	B747CMD_ai_lighting_quick_start:once()
	
end







----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_ai_all_modes()

	B747_autoboard_init()
    simDR_autoboard_in_progress = 0
    B747_autostart_init()
    simDR_autostart_in_progress = 0

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_ai_CD()



end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_ai_ER()
	
	
	
end












----- FLIGHT START AI -------------------------------------------------------------------
function B747_flight_start_ai()

    -- ALL MODES ------------------------------------------------------------------------
	B747_set_ai_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

		B747_set_ai_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_ai_ER()

    end

end



--*************************************************************************************--
--** 				                 EVENT CALLBACKS           	        			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start()

    B747_flight_start_ai()

end

--function flight_crash() end

--function before_physics() end
debug_ai     = deferred_dataref("laminar/B747/debug/ai", "number")
function after_physics()
if debug_ai>0 then return end
    B747_auto_board()
    B747_auto_start()

end

--function after_replay() end




--*************************************************************************************--
--** 				                SUB-SCRIPT LOADING                  			 **--
--*************************************************************************************--


print(collectgarbage("count")*1024)
print("^^^^^^MEMORY USAGE OF B747.95.AI.lua IN BYTES BEFORE GARBAGE COLLECT")
collectgarbage("collect")
print(collectgarbage("count")*1024)
print("^^^^^^MEMORY USAGE OF B747.95.AI.lua IN BYTES AFTER GARBAGE COLLECT")



-- dofile("")



