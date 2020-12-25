--[[
*****************************************************************************************
* Program Script Name	:	B747.55.air
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
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED	    *
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
B747bleedAir            = {}

B747bleedAir.engine1    = {}
B747bleedAir.engine2    = {}
B747bleedAir.engine3    = {}
B747bleedAir.engine4    = {}
B747bleedAir.apu        = {}
B747bleedAir.grnd_cart  = {}

B747bleedAir.engine1.psi    = deferred_dataref("laminar/B747/air/engine1/bleed_air_psi", "number")
B747bleedAir.engine2.psi    = deferred_dataref("laminar/B747/air/engine2/bleed_air_psi", "number")
B747bleedAir.engine3.psi    = deferred_dataref("laminar/B747/air/engine3/bleed_air_psi", "number")
B747bleedAir.engine4.psi    = deferred_dataref("laminar/B747/air/engine4/bleed_air_psi", "number")
B747bleedAir.apu.psi        = 0
B747bleedAir.grnd_cart.psi  =   0

B747bleedAir.engine1.bleed_air_valve        = {}
B747bleedAir.engine2.bleed_air_valve        = {}
B747bleedAir.engine3.bleed_air_valve        = {}
B747bleedAir.engine4.bleed_air_valve        = {}
B747bleedAir.engine1.bleed_air_start_valve  = {}
B747bleedAir.engine2.bleed_air_start_valve  = {}
B747bleedAir.engine3.bleed_air_start_valve  = {}
B747bleedAir.engine4.bleed_air_start_valve  = {}
B747bleedAir.apu.bleed_air_valve            = {}
B747bleedAir.isolation_valve_L              = {}
B747bleedAir.isolation_valve_R              = {}

B747bleedAir.engine1.bleed_air_valve.target_pos = 0.0
B747bleedAir.engine2.bleed_air_valve.target_pos = 0.0
B747bleedAir.engine3.bleed_air_valve.target_pos = 0.0
B747bleedAir.engine4.bleed_air_valve.target_pos = 0.0
B747bleedAir.engine1.bleed_air_start_valve.target_pos = 0.0
B747bleedAir.engine2.bleed_air_start_valve.target_pos = 0.0
B747bleedAir.engine3.bleed_air_start_valve.target_pos = 0.0
B747bleedAir.engine4.bleed_air_start_valve.target_pos = 0.0
B747bleedAir.apu.bleed_air_valve.target_pos     = 0.0
B747bleedAir.isolation_valve_L.target_pos       = 0.0
B747bleedAir.isolation_valve_R.target_pos       = 0.0

B747bleedAir.engine1.bleed_air_valve.pos        = deferred_dataref("laminar/B747/air/engine1/bleed_valve_pos", "number")
B747bleedAir.engine2.bleed_air_valve.pos        = deferred_dataref("laminar/B747/air/engine2/bleed_valve_pos", "number")
B747bleedAir.engine3.bleed_air_valve.pos        = deferred_dataref("laminar/B747/air/engine3/bleed_valve_pos", "number")
B747bleedAir.engine4.bleed_air_valve.pos        = deferred_dataref("laminar/B747/air/engine4/bleed_valve_pos", "number")
B747bleedAir.engine1.bleed_air_start_valve.pos  = deferred_dataref("laminar/B747/air/engine1/bleed_start_valve_pos", "number")
B747bleedAir.engine2.bleed_air_start_valve.pos  = deferred_dataref("laminar/B747/air/engine2/bleed_start_valve_pos", "number")
B747bleedAir.engine3.bleed_air_start_valve.pos  = deferred_dataref("laminar/B747/air/engine3/bleed_start_valve_pos", "number")
B747bleedAir.engine4.bleed_air_start_valve.pos  = deferred_dataref("laminar/B747/air/engine4/bleed_start_valve_pos", "number")
B747bleedAir.apu.bleed_air_valve.pos            = deferred_dataref("laminar/B747/air/apu/bleed_valve_pos", "number")
B747bleedAir.isolation_valve_L.pos              = deferred_dataref("laminar/B747/air/isolation_valve_L_pos", "number")
B747bleedAir.isolation_valve_R.pos              = deferred_dataref("laminar/B747/air/isolation_valve_R_pos", "number")




--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local B747_outflow_valve_pos_L_target   = 0
local B747_outflow_valve_pos_R_target   = 0




--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")

simDR_bleed_air_mode                = find_dataref("sim/cockpit2/pressurization/actuators/bleed_air_mode")

simDR_elec_bus_volts                = find_dataref("sim/cockpit2/electrical/bus_volts")

simDR_indicated_altitude_pilot      = find_dataref("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
simDR_indicated_vvi_fpm_pilot       = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")

--simDR_press_act_dump_all_on         = find_dataref("sim/cockpit2/pressurization/actuators/dump_all_on")
--simDR_press_act_dump_to_alt_on      = find_dataref("sim/cockpit2/pressurization/actuators/dump_to_altitude_on")
simDR_press_act_cabin_alt_ft        = find_dataref("sim/cockpit2/pressurization/actuators/cabin_altitude_ft")
simDR_press_act_cabin_vvi_fpm       = find_dataref("sim/cockpit2/pressurization/actuators/cabin_vvi_fpm")
simDR_press_act_max_cabin_alt_ft    = find_dataref("sim/cockpit2/pressurization/actuators/max_allowable_altitude_ft")
simDR_press_cabin_alt_ft            = find_dataref("sim/cockpit2/pressurization/indicators/cabin_altitude_ft")
simDR_press_cabin_vvi_fpm           = find_dataref("sim/cockpit2/pressurization/indicators/cabin_vvi_fpm")
simDR_press_diff_psi                = find_dataref("sim/cockpit2/pressurization/indicators/pressure_diffential_psi")

--simDR_apu_running                   = find_dataref("sim/cockpit2/electrical/APU_running")
simDR_apu_N1_pct                    = find_dataref("sim/cockpit2/electrical/APU_N1_percent")
simDR_engine_running                = find_dataref("sim/flightmodel/engine/ENGN_running")
simDR_engine_N1_pct                 = find_dataref("sim/cockpit2/engine/indicators/N1_percent")
--simDR_engine_N2_pct                 = find_dataref("sim/cockpit2/engine/indicators/N2_percent")





--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_button_switch_position           = find_dataref("laminar/B747/button_switch/position")
B747DR_toggle_switch_position           = find_dataref("laminar/B747/toggle_switch/position")
B747DR_fuel_control_toggle_switch_pos   = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")
B747DR_dsp_synoptic_display             = find_dataref("laminar/B747/dsp/synoptic_display")

B747DR_CAS_warning_status               = find_dataref("laminar/B747/CAS/warning_status")
B747DR_CAS_caution_status               = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status              = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_CAS_memo_status                  = find_dataref("laminar/B747/CAS/memo_status")



--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_cabin_alt_auto_sel_pos       = deferred_dataref("laminar/B747/air/cabin_alt_auto/sel_dial_pos", "number")
B747DR_equip_cooling_sel_pos        = deferred_dataref("laminar/B747/air/equip_cooling/sel_dial_pos", "number")
B747DR_pack_ctrl_sel_pos            = deferred_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos", "array[3]")
B747DR_landing_alt_button_pos       = deferred_dataref("laminar/B747/air/landing_alt/button_pos", "number")

B747DR_outflow_valve_pos_L          = deferred_dataref("laminar/B747/air/outflow_valve_left/pos", "number")
B747DR_outflow_valve_pos_R          = deferred_dataref("laminar/B747/air/outflow_valve_right/pos", "number")

B747DR_landing_altitude             = deferred_dataref("laminar/B747/air/landing_altitude", "number")

B747_duct_pressure_L                = find_dataref("laminar/B747/air/duct_pressure_L")
B747_duct_pressure_C                = find_dataref("laminar/B747/air/duct_pressure_C")
B747_duct_pressure_R                = find_dataref("laminar/B747/air/duct_pressure_R")

B747DR_pressure_EICAS1_display_status = deferred_dataref("laminar/B747/air/pressurization/EICAS1_display_status", "number")

B747DR_init_air_CD                  = deferred_dataref("laminar/B747/air/init_CD", "number")



--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--






--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

-- LANDING ALTITUDE SELECTOR
B747DR_landing_alt_sel_rheo     = deferred_dataref("laminar/B747/air/land_alt_sel/rheostat", "number")


-- PASSENGER TEMP CONTROL
B747DR_pass_temp_ctrl__rheo     = deferred_dataref("laminar/B747/air/pass_temp_ctrl/rheostat", "number")


-- FLIGHT DECK TEMP CONTROL
B747DR_flt_deck_temp_ctrl_rheo  = deferred_dataref("laminar/B747/air/flt_deck_temp_ctrl/rheostat", "number")


-- CARGO TEMP CONTROL
B747DR_cargo_temp_ctrl_rheo     = deferred_dataref("laminar/B747/air/cargo_temp_ctrl/rheostat", "number")





--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

-- CABIN ALTITUDE AUTO SELECTOR
function B747_cabin_alt_auto_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_cabin_alt_auto_sel_pos = math.min(B747DR_cabin_alt_auto_sel_pos+1, 2)
    end
end
function B747_cabin_alt_auto_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_cabin_alt_auto_sel_pos = math.max(B747DR_cabin_alt_auto_sel_pos-1, 0)
    end
end




-- EQUIPMENT COOLING SELECTOR
function B747_equip_cooling_sel_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_equip_cooling_sel_pos = math.min(B747DR_equip_cooling_sel_pos+1, 2)
    end
end
function B747_equip_cooling_sel_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_equip_cooling_sel_pos = math.max(B747DR_equip_cooling_sel_pos-1, 0)
    end
end




-- PACK CONTROL SELECTOR 01
function B747_pack_ctrl_sel_01_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_pack_ctrl_sel_pos[0] = math.min(B747DR_pack_ctrl_sel_pos[0]+1, 3)
    end
end
function B747_pack_ctrl_sel_01_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_pack_ctrl_sel_pos[0] = math.max(B747DR_pack_ctrl_sel_pos[0]-1, 0)
    end
end



-- PACK CONTROL SELECTOR 02
function B747_pack_ctrl_sel_02_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_pack_ctrl_sel_pos[1] = math.min(B747DR_pack_ctrl_sel_pos[1]+1, 3)
    end
end
function B747_pack_ctrl_sel_02_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_pack_ctrl_sel_pos[1] = math.max(B747DR_pack_ctrl_sel_pos[1]-1, 0)
    end
end



-- PACK CONTROL SELECTOR 03
function B747_pack_ctrl_sel_03_up_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_pack_ctrl_sel_pos[2] = math.min(B747DR_pack_ctrl_sel_pos[2]+1, 3)
    end
end
function B747_pack_ctrl_sel_03_dn_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_pack_ctrl_sel_pos[2] = math.max(B747DR_pack_ctrl_sel_pos[2]-1, 0)
    end
end




-- LANDING ALTITUDE BUTTON
function B747_landing_alt_button_CMDhandler(phase, duration)
    if phase == 0 then
        B747DR_landing_alt_button_pos = 1.0 - B747DR_landing_alt_button_pos
    end
end




function B747_ai_air_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
		B747_set_air_all_modes()
		B747_set_air_CD()
		B747_set_air_ER()	        
    end	
end	




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- CABIN ALTITUDE AUTO SELECTOR
B747CMD_cabin_alt_auto_sel_up = deferred_command("laminar/B747/air/cabin_alt_auto/sel_dial_up", "Cabin Altitude Selector Dial Up", B747_cabin_alt_auto_sel_up_CMDhandler)
B747CMD_cabin_alt_auto_sel_dn = deferred_command("laminar/B747/air/cabin_alt_auto/sel_dial_dn", "Cabin Altitude Selector Dial Down", B747_cabin_alt_auto_sel_dn_CMDhandler)



-- EQUIPMENT COOLING SELECTOR
B747CMD_equip_cooling_sel_up = deferred_command("laminar/B747/air/equip_cooling/sel_dial_up", "Equipment Coooling Selector Dial Up", B747_equip_cooling_sel_up_CMDhandler)
B747CMD_equip_cooling_sel_dn = deferred_command("laminar/B747/air/equip_cooling/sel_dial_dn", "Equipment Coooling Selector Dial Down", B747_equip_cooling_sel_dn_CMDhandler)



-- PACK CONTROL SELECTOR
B747CMD_pack_ctrl_sel_01_up = deferred_command("laminar/B747/air/pack_ctrl_01/sel_dial_up", "Equipment Coooling Selector 1 Dial Up", B747_pack_ctrl_sel_01_up_CMDhandler)
B747CMD_pack_ctrl_sel_01_dn = deferred_command("laminar/B747/air/pack_ctrl_01/sel_dial_dn", "Equipment Coooling Selector 1 Dial Down", B747_pack_ctrl_sel_01_dn_CMDhandler)

B747CMD_pack_ctrl_sel_02_up = deferred_command("laminar/B747/air/pack_ctrl_02/sel_dial_up", "Equipment Coooling Selector 2 Dial Up", B747_pack_ctrl_sel_02_up_CMDhandler)
B747CMD_pack_ctrl_sel_02_dn = deferred_command("laminar/B747/air/pack_ctrl_02/sel_dial_dn", "Equipment Coooling Selector 2 Dial Down", B747_pack_ctrl_sel_02_dn_CMDhandler)

B747CMD_pack_ctrl_sel_03_up = deferred_command("laminar/B747/air/pack_ctrl_03/sel_dial_up", "Equipment Coooling Selector 3 Dial Up", B747_pack_ctrl_sel_03_up_CMDhandler)
B747CMD_pack_ctrl_sel_03_dn = deferred_command("laminar/B747/air/pack_ctrl_03/sel_dial_dn", "Equipment Coooling Selector 3 Dial Down", B747_pack_ctrl_sel_03_dn_CMDhandler)


-- LANDING ALTITUDE SWITCH
B747CMD_landing_alt_button = deferred_command("laminar/B747/air/landing_alt/button", "Landing Altitude Button", B747_landing_alt_button_CMDhandler)


-- AI
B747CMD_ai_air_quick_start = deferred_command("laminar/B747/ai/air_quick_start", "number", B747_ai_air_quick_start_CMDhandler)




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end



----- RESCALE ---------------------------------------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end



----- ANIMATION UTILITY -----------------------------------------------------------------
function B747_set_anim_value(current_value, target, min, max, speed)

    local fps_factor = math.min(1.0, speed * SIM_PERIOD)

    if target >= (max - 0.001) and current_value >= (max - 0.01) then
        return max
    elseif target <= (min + 0.001) and current_value <= (min + 0.01) then
       return min
    else
        return current_value + ((target - current_value) * fps_factor)
    end

end





----- BLEED AIR SUPPLY ------------------------------------------------------------------
local int, frac = math.modf(os.clock())
local seed = math.random(1, frac*1000.0)
math.randomseed(seed)
local rndm_max_apu_bleed_psi    = math.random(35, 40) + math.random()
local rndm_max_eng1_bleed_psi   = math.random(35, 37) + math.random()
local rndm_max_eng2_bleed_psi   = math.random(35, 38) + math.random()
local rndm_max_eng3_bleed_psi   = math.random(35, 36) + math.random()
local rndm_max_eng4_bleed_psi   = math.random(35, 39) + math.random()
function B747_bleed_air_supply()

    -- GROUND AIR CART
    -- TODO: NOT MODELED - REQUEST FROM LAMINAR
    B747bleedAir.grnd_cart.psi = 0

    -- APU
    B747bleedAir.apu.psi = B747_rescale(0, 0, 80.0, rndm_max_apu_bleed_psi, simDR_apu_N1_pct)

    -- ENGINE 1
    B747bleedAir.engine1.psi = B747_rescale(0, 0, 50.0, rndm_max_eng1_bleed_psi, simDR_engine_N1_pct[0])

    -- ENGINE 1
    B747bleedAir.engine2.psi = B747_rescale(0, 0, 50.0, rndm_max_eng2_bleed_psi, simDR_engine_N1_pct[1])

    -- ENGINE 1
    B747bleedAir.engine3.psi = B747_rescale(0, 0, 50.0, rndm_max_eng3_bleed_psi, simDR_engine_N1_pct[2])

    -- ENGINE 1
    B747bleedAir.engine4.psi = B747_rescale(0, 0, 50.0, rndm_max_eng4_bleed_psi, simDR_engine_N1_pct[3])

end






----- BLEED AIR VALVES ------------------------------------------------------------------
function B747_bleed_air_valves()

    -- POWER REQUIRED - ELECTRIC VALVES ARE NORMALLY CLOSED WHEN THERE IS NO POWER
    local power = B747_ternary((simDR_elec_bus_volts[0] > 0.0), 1, 0)
    local min_engine_start_duct_pressure = 25.0
    local bleed_valve_min_act_press = 12.0

    ----- ISOLATION VALVES --------------------------------------------------------------
    
    if B747DR_button_switch_position[75] > 0.95 then
        B747bleedAir.isolation_valve_L.target_pos = 1.0 * power
    else
        B747bleedAir.isolation_valve_L.target_pos = 0.0                                     -- NORMALLY CLOSED
    end

    
    if B747DR_button_switch_position[76] > 0.95 then
        B747bleedAir.isolation_valve_R.target_pos = 1.0 * power
    else
        B747bleedAir.isolation_valve_R.target_pos = 0.0
    end


    ----- APU VALVE ---------------------------------------------------------------------
    
    if B747DR_button_switch_position[81] > 0.95                                         -- APU BLEED AIR BUTTON SWITCH
        and B747bleedAir.apu.psi > bleed_valve_min_act_press                            -- BLEED AIR REQUIRED TO OPEN THE VALVE
    then
        B747bleedAir.apu.bleed_air_valve.target_pos = 1.0                               -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
    else
        B747bleedAir.apu.bleed_air_valve.target_pos = 0.0                                   -- NORMALLY CLOSED
    end


    ----- ENGINE #1 BLEED AIR VALVE -----------------------------------------------------
    
    if B747DR_button_switch_position[77] > 0.95 then                                    -- ENGINE #1 BLEED AIR BUTTON SWITCH
        if B747bleedAir.engine1.psi >= bleed_valve_min_act_press                        -- BLEED AIR REQUIRED TO OPEN THE VALVE
            or
            -- ENGINE START
            (B747DR_toggle_switch_position[16] > 0.95                                   -- ENGINE START SWITCH "PULLED"
            and
            B747_duct_pressure_L > bleed_valve_min_act_press)                           -- WE HAVE ENOUGH PRESS TO OPEN THE VALVE
        then
            B747bleedAir.engine1.bleed_air_valve.target_pos = 1.0                       -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine1.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine1.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
    end

    ----- ENGINE #1 BLEED AIR START VALVE -----------------------------------------------
    
    if B747bleedAir.engine1.bleed_air_valve.pos > 0.95 then                             -- ENGINE BLEED VALVE OPEN FOR REVERSE FLOW
        -- MANUAL START
        if B747DR_button_switch_position[45] < 0.05                                     -- AUTOSTART BUTTON NOT DEPRESSED
            and B747DR_toggle_switch_position[16] > 0.95                                -- ENGINE START SWITCH "PULLED"
        then
            B747bleedAir.engine1.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        -- AUTOSTART
        elseif B747DR_button_switch_position[45] > 0.95                                 -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[16] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[0] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        then
            B747bleedAir.engine1.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine1.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine1.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
    end



    ----- ENGINE #2 BLEED AIR VALVE -----------------------------------------------------
    
    if B747DR_button_switch_position[78] > 0.95 then                                    -- ENGINE #2 BLEED AIR BUTTON SWITCH
        if B747bleedAir.engine2.psi >= bleed_valve_min_act_press                        -- BLEED AIR REQUIRED TO OPEN THE VALVE
            or
            -- ENGINE START
            (B747DR_toggle_switch_position[17] > 0.95                                   -- ENGINE START SWITCH "PULLED"
            and
            B747_duct_pressure_L > bleed_valve_min_act_press)                           -- WE HAVE ENOUGH PRESS TO OPEN THE VALVE
        then
            B747bleedAir.engine2.bleed_air_valve.target_pos = 1.0                       -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine2.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine2.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
    end

    ----- ENGINE #2 BLEED AIR START VALVE -----------------------------------------------
    
    if B747bleedAir.engine2.bleed_air_valve.pos > 0.95 then                             -- ENGINE BLEED VALVE OPEN FOR REVERSE FLOW
        -- MANUAL START
        if B747DR_button_switch_position[45] < 0.05                                     -- AUTOSTART BUTTON NOT DEPRESSED
            and B747DR_toggle_switch_position[17] > 0.95                                -- ENGINE START SWITCH "PULLED"
        then
            B747bleedAir.engine2.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        -- AUTOSTART
        elseif B747DR_button_switch_position[45] > 0.95                                 -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[17] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[1] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        then
            B747bleedAir.engine2.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine2.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED    
        end
    else
        B747bleedAir.engine2.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
    end



    ----- ENGINE #3 BLEED AIR VALVE -----------------------------------------------------
    
    if B747DR_button_switch_position[79] > 0.95 then                                    -- ENGINE #3 BLEED AIR BUTTON SWITCH
        if B747bleedAir.engine3.psi >= bleed_valve_min_act_press                        -- BLEED AIR REQUIRED TO OPEN THE VALVE
            or
            -- ENGINE START
            (B747DR_toggle_switch_position[18] > 0.95                                   -- ENGINE START SWITCH "PULLED"
            and
            B747_duct_pressure_R > bleed_valve_min_act_press)                           -- WE HAVE ENOUGH PRESS TO OPEN THE VALVE
        then
            B747bleedAir.engine3.bleed_air_valve.target_pos = 1.0                       -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine3.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine3.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
    end

    ----- ENGINE #3 BLEED AIR START VALVE -----------------------------------------------
    
    if B747bleedAir.engine3.bleed_air_valve.pos > 0.95 then                             -- ENGINE BLEED VALVE OPEN FOR REVERSE FLOW
        -- MANUAL START
        if B747DR_button_switch_position[45] < 0.05                                     -- AUTOSTART BUTTON NOT DEPRESSED
            and B747DR_toggle_switch_position[18] > 0.95                                -- ENGINE START SWITCH "PULLED"
        then
            B747bleedAir.engine3.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        -- AUTOSTART
        elseif B747DR_button_switch_position[45] > 0.95                                 -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[18] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[2] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        then
            B747bleedAir.engine3.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine3.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine3.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
    end



    ----- ENGINE #4 BLEED AIR VALVE -----------------------------------------------------
    
    if B747DR_button_switch_position[80] > 0.95 then                                    -- ENGINE #4 BLEED AIR BUTTON SWITCH
        if B747bleedAir.engine4.psi >= bleed_valve_min_act_press                        -- BLEED AIR REQUIRED TO OPEN THE VALVE
            or
            -- ENGINE START
            (B747DR_toggle_switch_position[19] > 0.95                                   -- ENGINE START SWITCH "PULLED"
            and
            B747_duct_pressure_R > bleed_valve_min_act_press)                           -- WE HAVE ENOUGH PRESS TO OPEN THE VALVE
        then
            B747bleedAir.engine4.bleed_air_valve.target_pos = 1.0                       -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine4.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine4.bleed_air_valve.target_pos = 0.0                               -- NORMALLY CLOSED
    end

    ----- ENGINE #4 BLEED AIR START VALVE -----------------------------------------------
    
    if B747bleedAir.engine4.bleed_air_valve.pos > 0.95 then                             -- ENGINE BLEED VALVE OPEN FOR REVERSE FLOW
        -- MANUAL START
        if B747DR_button_switch_position[45] < 0.05                                     -- AUTOSTART BUTTON NOT DEPRESSED
            and B747DR_toggle_switch_position[19] > 0.95                                -- ENGINE START SWITCH "PULLED"
        then
            B747bleedAir.engine4.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        -- AUTOSTART
        elseif B747DR_button_switch_position[45] > 0.95                                 -- AUTOSTART BUTTON DEPRESSED
            and B747DR_toggle_switch_position[19] > 0.95                                -- ENGINE START SWITCH "PULLED"
            and B747DR_fuel_control_toggle_switch_pos[3] > 0.95                         -- FUEL CUTOFF SWITCH IS IN THE "RUN" POSITION
        then
            B747bleedAir.engine4.bleed_air_start_valve.target_pos = 1.0                 -- OPERATED BY BLEED AIR PRESSURE (NO ELECTRIC REQUIREMENT)
        else
            B747bleedAir.engine4.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
        end
    else
        B747bleedAir.engine4.bleed_air_start_valve.target_pos = 0.0                         -- NORMALLY CLOSED
    end

 end








----- BLEED AIR VALVE ANIMATION ---------------------------------------------------------
function B747_bleed_air_valve_animation()

    local valve_anm_speed = 20.0

    -- ISOLATION VALVES
    B747bleedAir.isolation_valve_L.pos	            = B747_set_anim_value(B747bleedAir.isolation_valve_L.pos, B747bleedAir.isolation_valve_L.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.isolation_valve_R.pos	            = B747_set_anim_value(B747bleedAir.isolation_valve_R.pos, B747bleedAir.isolation_valve_R.target_pos, 0.0, 1.0, valve_anm_speed)

    -- APU BLEED VALVE
    B747bleedAir.apu.bleed_air_valve.pos	        = B747_set_anim_value(B747bleedAir.apu.bleed_air_valve.pos, B747bleedAir.apu.bleed_air_valve.target_pos, 0.0, 1.0, valve_anm_speed)

    -- ENGINE BLEED VALVES
    B747bleedAir.engine1.bleed_air_valve.pos        = B747_set_anim_value(B747bleedAir.engine1.bleed_air_valve.pos, B747bleedAir.engine1.bleed_air_valve.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.engine2.bleed_air_valve.pos        = B747_set_anim_value(B747bleedAir.engine2.bleed_air_valve.pos, B747bleedAir.engine2.bleed_air_valve.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.engine3.bleed_air_valve.pos        = B747_set_anim_value(B747bleedAir.engine3.bleed_air_valve.pos, B747bleedAir.engine3.bleed_air_valve.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.engine4.bleed_air_valve.pos        = B747_set_anim_value(B747bleedAir.engine4.bleed_air_valve.pos, B747bleedAir.engine4.bleed_air_valve.target_pos, 0.0, 1.0, valve_anm_speed)

    -- ENGINE BLEED START VALVES
    B747bleedAir.engine1.bleed_air_start_valve.pos  = B747_set_anim_value(B747bleedAir.engine1.bleed_air_start_valve.pos, B747bleedAir.engine1.bleed_air_start_valve.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.engine2.bleed_air_start_valve.pos  = B747_set_anim_value(B747bleedAir.engine2.bleed_air_start_valve.pos, B747bleedAir.engine2.bleed_air_start_valve.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.engine3.bleed_air_start_valve.pos  = B747_set_anim_value(B747bleedAir.engine3.bleed_air_start_valve.pos, B747bleedAir.engine3.bleed_air_start_valve.target_pos, 0.0, 1.0, valve_anm_speed)
    B747bleedAir.engine4.bleed_air_start_valve.pos  = B747_set_anim_value(B747bleedAir.engine4.bleed_air_start_valve.pos, B747bleedAir.engine4.bleed_air_start_valve.target_pos, 0.0, 1.0, valve_anm_speed)

end





----- BLEED AIR DUCT PRESSURE -----------------------------------------------------------
function B747_bleed_air_duct_pressure()

    -- CENTER DUCT
    B747_duct_pressure_C = math.max((B747bleedAir.apu.psi * B747bleedAir.apu.bleed_air_valve.pos), B747bleedAir.grnd_cart.psi,
    B747_duct_pressure_L*B747bleedAir.isolation_valve_L.pos,B747_duct_pressure_R*B747bleedAir.isolation_valve_R.pos)


    -- LEFT DUCT
    --B747_duct_pressure_L = 0
    if B747bleedAir.isolation_valve_L.pos < 0.01 then                                   -- LEFT ISOLATION VALVE IS CLOSED
        B747_duct_pressure_L = math.max(
            (B747bleedAir.engine1.psi * B747bleedAir.engine1.bleed_air_valve.pos),
            (B747bleedAir.engine2.psi * B747bleedAir.engine2.bleed_air_valve.pos))
    else                                                                                -- LEFT ISOLATION VALVE IS OPEN
        if B747bleedAir.isolation_valve_R.pos < 0.01 then                               -- RIGHT ISOLATION VALVE IS CLOSED
            B747_duct_pressure_L = math.max(
                (B747bleedAir.engine1.psi * B747bleedAir.engine1.bleed_air_valve.pos),
                (B747bleedAir.engine2.psi * B747bleedAir.engine2.bleed_air_valve.pos),
                (B747bleedAir.apu.psi * B747bleedAir.apu.bleed_air_valve.pos),
                B747bleedAir.grnd_cart.psi)
        else                                                                            -- RIGHT ISOLATION VALVE IS OPEN
            B747_duct_pressure_L = math.max(
                (B747bleedAir.engine1.psi * B747bleedAir.engine1.bleed_air_valve.pos),
                (B747bleedAir.engine2.psi * B747bleedAir.engine2.bleed_air_valve.pos),
                (B747bleedAir.engine3.psi * B747bleedAir.engine3.bleed_air_valve.pos),
                (B747bleedAir.engine4.psi * B747bleedAir.engine4.bleed_air_valve.pos),
                (B747bleedAir.apu.psi * B747bleedAir.apu.bleed_air_valve.pos),
                B747bleedAir.grnd_cart.psi)
        end
    end


    -- RIGHT DUCT
    --B747_duct_pressure_R = 0
    if B747bleedAir.isolation_valve_R.pos < 0.01 then                                   -- RIGHT ISOLATION VALVE IS CLOSED
        B747_duct_pressure_R = math.max(
            (B747bleedAir.engine3.psi * B747bleedAir.engine3.bleed_air_valve.pos),
            (B747bleedAir.engine4.psi * B747bleedAir.engine4.bleed_air_valve.pos))
    else                                                                                -- RIGHT ISOLATION VALVE IS OPEN
        if B747bleedAir.isolation_valve_L.pos < 0.01 then                               -- LEFT ISOLATION VALVE IS CLOSED
            B747_duct_pressure_R = math.max(
                (B747bleedAir.engine3.psi * B747bleedAir.engine3.bleed_air_valve.pos),
                (B747bleedAir.engine4.psi * B747bleedAir.engine4.bleed_air_valve.pos),
                (B747bleedAir.apu.psi * B747bleedAir.apu.bleed_air_valve.pos),
                B747bleedAir.grnd_cart.psi)
        else                                                                            -- LEFT ISOLATION VALVE IS OPEN
            B747_duct_pressure_R = math.max(
                (B747bleedAir.engine1.psi * B747bleedAir.engine1.bleed_air_valve.pos),
                (B747bleedAir.engine2.psi * B747bleedAir.engine2.bleed_air_valve.pos),
                (B747bleedAir.engine3.psi * B747bleedAir.engine3.bleed_air_valve.pos),
                (B747bleedAir.engine4.psi * B747bleedAir.engine4.bleed_air_valve.pos),
                (B747bleedAir.apu.psi * B747bleedAir.apu.bleed_air_valve.pos),
                B747bleedAir.grnd_cart.psi)
        end
    end

end






----- ENGINE BLEED AIR MODE -------------------------------------------------------------
function B747_bleed_air_mode()

    -- simDR_bleed_air_mode    0=off, 1=left, 2=both, 3=right, 4=apu, 5=auto

    if B747_duct_pressure_C + B747_duct_pressure_L + B747_duct_pressure_R <= 0.0 then
        simDR_bleed_air_mode = 0

    elseif B747_duct_pressure_C > math.max(
        (B747bleedAir.engine1.psi * B747bleedAir.engine1.bleed_air_valve.pos),
        (B747bleedAir.engine2.psi * B747bleedAir.engine2.bleed_air_valve.pos),
        (B747bleedAir.engine3.psi * B747bleedAir.engine3.bleed_air_valve.pos),
        (B747bleedAir.engine4.psi * B747bleedAir.engine4.bleed_air_valve.pos)) and B747bleedAir.apu.psi * B747bleedAir.apu.bleed_air_valve.pos > 5
        --and B747bleedAir.isolation_valve_L.pos > 0.95
        --and B747bleedAir.isolation_valve_R.pos > 0.95
    then
        simDR_bleed_air_mode = 4

    else
        simDR_bleed_air_mode = 2
    end

end







----- PRESSURIZATION --------------------------------------------------------------------
function B747_pressurization()

    simDR_press_act_cabin_alt_ft = math.min(simDR_press_act_max_cabin_alt_ft, simDR_indicated_altitude_pilot)

    -- OUTFLOW VALVE MANUAL MODE
    if B747DR_button_switch_position[34] > 0.95 or B747DR_button_switch_position[35] > 0.95 then

        -- DECREASE VALVE POSITION
        if B747DR_toggle_switch_position[22] < -0.95 then

            if B747DR_button_switch_position[34] > 0.95 then
                B747_outflow_valve_pos_L_target = math.max(B747_outflow_valve_pos_L_target - 0.005, -1.0)
            end

            if B747DR_button_switch_position[35] > 0.95 then
                B747_outflow_valve_pos_R_target = math.max(B747_outflow_valve_pos_R_target - 0.005, -1.0)
            end


        -- INCREASE VALVE POSITION
        elseif B747DR_toggle_switch_position[22] > 0.95 then

            if B747DR_button_switch_position[34] > 0.95 then
                B747_outflow_valve_pos_L_target = math.min(B747_outflow_valve_pos_L_target + 0.005, 1.0)
            end

            if B747DR_button_switch_position[35] > 0.95 then
                B747_outflow_valve_pos_R_target = math.min(B747_outflow_valve_pos_R_target + 0.005, 1.0)
            end

        end

        simDR_press_act_max_cabin_alt_ft = simDR_indicated_altitude_pilot
        simDR_press_act_cabin_vvi_fpm = B747_rescale(-1.0, 2000.0, 1.0, -2000.0, math.max(math.abs(B747DR_outflow_valve_pos_L), math.abs(B747DR_outflow_valve_pos_R)))

    -- OUTFLOW VALVE AUTO MODE
    else

        simDR_press_act_max_cabin_alt_ft = 8000.0
        simDR_press_act_cabin_vvi_fpm = math.min(2000.0, math.max(500, simDR_indicated_vvi_fpm_pilot))
        B747_outflow_valve_pos_L_target = B747_rescale(-2000.0, 1.0, 2000.0, -1.0, simDR_press_cabin_vvi_fpm)
        B747_outflow_valve_pos_R_target = B747_outflow_valve_pos_L_target

    end



    -- LIMITER
    if simDR_press_cabin_alt_ft > 11000.0 then
        simDR_press_act_max_cabin_alt_ft = 11000.00
        B747_outflow_valve_pos_L_target = -1.0
        B747_outflow_valve_pos_R_target = -1.0
        simDR_press_act_cabin_vvi_fpm = 2000.0
    end


    -- SET VALVE POSITION
    B747DR_outflow_valve_pos_L = B747_set_anim_value(B747DR_outflow_valve_pos_L, B747_outflow_valve_pos_L_target, -1.0, 1.0, 10.0)
    B747DR_outflow_valve_pos_R = B747_set_anim_value(B747DR_outflow_valve_pos_R, B747_outflow_valve_pos_R_target, -1.0, 1.0, 10.0)

end





----- LANDING ALTITUDE -------------------------------------------------------------------
function B747_landing_alt()

    -- MANUAL
    if B747DR_landing_alt_button_pos < 0.5 then
        B747DR_landing_altitude = B747DR_landing_alt_sel_rheo

    -- AUTO
    else
        B747DR_landing_altitude = 2000 -- DEFAULT WHEN NO ALTITUDE AVAIL FROM FMC   TODO:  ADD FMC VALUE WHEN AVAILABLE

    end

end





----- PRIMARY EICAS PRESSURIZATION DISPLAY -----------------------------------------------
function B747_primary_EICAS_ECS_display()

    if B747DR_dsp_synoptic_display == 1
        -- or CAUTION MESSAGE: BLD DUCT LEAK L  (NOT MODEELED)
        -- or CAUTION MESSAGE: BLD DUCT LEAK R  (NOT MODELED)
        or
        -- CAUTION MESSAGE: CABIN ALT AUTO
        B747DR_CAS_caution_status[10] == 1
        or
        -- ADVISORY MESSAGE: OUTFLOW VLV (L/R)
        B747DR_button_switch_position[34] < 0.05 or B747DR_button_switch_position[35] < 0.05
        or
        -- LANDING ALT CONTROL IS "MAN"
        B747DR_landing_alt_button_pos < 0.5
        or
        -- DUCT PRESSURE IS LOW
        B747_duct_pressure_L < 11 or B747_duct_pressure_R < 11
        or
        -- CABIN ALTITUDE LIMIT
        simDR_press_cabin_alt_ft >= 8500.00
        or
        -- CABIN DIFF PRESS LIMIT
        simDR_press_diff_psi >= 8.9
        or
        -- RATE OF CHANGE LIMIT
        simDR_press_cabin_vvi_fpm < -500.0 or simDR_press_cabin_vvi_fpm > 700.0
    then
        B747DR_pressure_EICAS1_display_status = 1
    else
        -- ONLY CLEAR THE ECS DATA BLOCK WHEN ADVERSE CONDITIONS NO LONGER EXIST
        -- AND THE FLIGHT CREW HAS 'BLANKED" THE "ENG" DISPLAY
        if B747DR_dsp_synoptic_display ~= 1 then
            B747DR_pressure_EICAS1_display_status = 0
        end
    end

end






----- EICAS MESSAGS ---------------------------------------------------------------------
function B747_air_EICAS_msg()

    -- CABIN ALTITUDE
    
    if simDR_press_cabin_alt_ft > 10000.0 then B747DR_CAS_warning_status[1] = 1 else B747DR_CAS_warning_status[1] = 0 end

    -- CABIN ALT AUTO
    
    if B747DR_button_switch_position[34] > 0.95
        or B747DR_button_switch_position[35] > 0.95
    then
        B747DR_CAS_caution_status[10] = 1
    else
        B747DR_CAS_caution_status[10] = 0
    end

    -- >BLEED 1 OFF
    
    if B747DR_button_switch_position[77] < 0.05
        and simDR_engine_running[0] == 1
        and B747bleedAir.engine1.bleed_air_valve.pos < 0.05
    then
        B747DR_CAS_advisory_status[39] = 1
    else
        B747DR_CAS_advisory_status[39] = 0
    end

    -- >BLEED 2 OFF
    
    if B747DR_button_switch_position[78] < 0.05
        and simDR_engine_running[1] == 1
        and B747bleedAir.engine2.bleed_air_valve.pos < 0.05
    then
        B747DR_CAS_advisory_status[40] = 1
    else
        B747DR_CAS_advisory_status[40] = 0
    end

    -- >BLEED 3 OFF
    
    if B747DR_button_switch_position[79] < 0.05
        and simDR_engine_running[2] == 1
        and B747bleedAir.engine3.bleed_air_valve.pos < 0.05
    then
        B747DR_CAS_advisory_status[41] = 1
    else
        B747DR_CAS_advisory_status[41] = 0
    end

    -- >BLEED 4 OFF
    
    if B747DR_button_switch_position[80] < 0.05
        and simDR_engine_running[3] == 1
        and B747bleedAir.engine4.bleed_air_valve.pos < 0.05
    then
        B747DR_CAS_advisory_status[42] = 1
    else
        B747DR_CAS_advisory_status[42] = 0
    end

    -- OUTFLOW VLV L
    
    if B747DR_button_switch_position[34] > 0.95 then B747DR_CAS_advisory_status[249] = 1 else B747DR_CAS_advisory_status[249] = 0 end

    -- OUTFLOW VLV R
    
    if B747DR_button_switch_position[35] > 0.95 then B747DR_CAS_advisory_status[250] = 1 else B747DR_CAS_advisory_status[250] = 0 end

    -- PACKS OFF
    
    if B747DR_pack_ctrl_sel_pos[0] == 0 and B747DR_pack_ctrl_sel_pos[1] == 0 and B747DR_pack_ctrl_sel_pos[2] == 0 then 
        B747DR_CAS_memo_status[25] = 1 
    else 
        B747DR_CAS_memo_status[25] = 0
        
    end

    -- PACKS 1 + 2 OFF
    
    if B747DR_CAS_memo_status[25] == 0 and B747DR_pack_ctrl_sel_pos[0] == 0 and B747DR_pack_ctrl_sel_pos[1] == 0 then
        B747DR_CAS_memo_status[21] = 1
    else 
        B747DR_CAS_memo_status[21] = 0 
    end

    -- PACKS 1 + 3 OFF
    
    if B747DR_CAS_memo_status[25] == 0 and B747DR_pack_ctrl_sel_pos[0] == 0 and B747DR_pack_ctrl_sel_pos[2] == 0 then 
        B747DR_CAS_memo_status[22] = 1 
    else 
        B747DR_CAS_memo_status[22] = 0 
    end

    -- PACKS 2 + 3 OFF
    
    if B747DR_CAS_memo_status[25] == 0 and B747DR_pack_ctrl_sel_pos[1] == 0 and B747DR_pack_ctrl_sel_pos[2] == 0 then 
        B747DR_CAS_memo_status[23] = 1 
    else 
        B747DR_CAS_memo_status[23] = 0 
    end

    -- PACK 1 OFF
    
    if B747DR_pack_ctrl_sel_pos[0] == 0 and B747DR_CAS_memo_status[25] == 0 and B747DR_CAS_memo_status[21] == 0 and B747DR_CAS_memo_status[22] == 0 and B747DR_CAS_memo_status[23] == 0 then 
        B747DR_CAS_memo_status[18] = 1 
    else 
        B747DR_CAS_memo_status[18] = 0 
    end

    -- PACK 2 OFF
    
    if B747DR_pack_ctrl_sel_pos[1] == 0 and B747DR_CAS_memo_status[25] == 0 and B747DR_CAS_memo_status[21] == 0 and B747DR_CAS_memo_status[22] == 0 and B747DR_CAS_memo_status[23] == 0 then 
        B747DR_CAS_memo_status[19] = 1 
    else 
        B747DR_CAS_memo_status[19] = 0 
    end

    -- PACK 3 OFF
    
    if B747DR_pack_ctrl_sel_pos[2] == 0 and B747DR_CAS_memo_status[25] == 0 and B747DR_CAS_memo_status[21] == 0 and B747DR_CAS_memo_status[22] == 0 and B747DR_CAS_memo_status[23] == 0 then 
        B747DR_CAS_memo_status[20] = 1 
    else 
        B747DR_CAS_memo_status[20] = 0 
    end

    

    

    

end











----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_air_monitor_AI()

    if B747DR_init_air_CD == 1 then
        B747_set_air_all_modes()
        B747_set_air_CD()
        B747DR_init_air_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_air_all_modes()

	B747DR_init_air_CD = 0
    B747DR_pass_temp_ctrl__rheo = 0.5
    B747DR_flt_deck_temp_ctrl_rheo = 0.5
    B747DR_cargo_temp_ctrl_rheo = 0.5
    B747DR_landing_alt_button_pos = 1.0
    B747DR_pressure_EICAS1_display_status = 0

end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_air_CD()

    B747DR_pack_ctrl_sel_pos[0] = 0
    B747DR_pack_ctrl_sel_pos[1] = 0
    B747DR_pack_ctrl_sel_pos[2] = 0

    B747DR_equip_cooling_sel_pos = 0
    B747DR_cabin_alt_auto_sel_pos = 0

end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_air_ER()
	
    B747DR_pack_ctrl_sel_pos[0] = 1
    B747DR_pack_ctrl_sel_pos[1] = 1
    B747DR_pack_ctrl_sel_pos[2] = 1
	
end








----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_air()

    -- ALL MODES ------------------------------------------------------------------------
    B747_set_air_all_modes()


    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_air_CD()


    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then

		B747_set_air_ER()

    end

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

--function aircraft_load() end

--function aircraft_unload() end

function flight_start() 

    B747_flight_start_air()

end

--function flight_crash() end

--function before_physics() end
debug_air     = deferred_dataref("laminar/B747/debug/air", "number")
function after_physics()
  if debug_air>0 then return end

    B747_bleed_air_supply()
    B747_bleed_air_valves()
    B747_bleed_air_valve_animation()
    B747_bleed_air_duct_pressure()
    B747_bleed_air_mode()

    B747_pressurization()
    B747_landing_alt()
    B747_primary_EICAS_ECS_display()

    B747_air_EICAS_msg()

    B747_air_monitor_AI()

end

--function after_replay() end



