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


--*************************************************************************************--
--** 					              XLUA GLOBALS              				     **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

--]]


--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

--NUM_THRUST_LEVERS = 5


function null_command(phase, duration)
end
--replace create command
function deferred_command(name,desc,nilFunc)
	c = XLuaCreateCommand(name,desc)
	--print("Deferred command: "..name)
	--XLuaReplaceCommand(c,null_command)
	return nil --make_command_obj(c)
end
--replace create_dataref
function deferred_dataref(name,type,notifier)
	--print("Deffereed dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end




--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--
B747DR_throttle						= deferred_dataref("laminar/B747/engine/throttle", "array[4]")
B747DR_throttle_reversor			= deferred_dataref("laminar/B747/engine/throttle_reversor", "array[4]")
B747DR_thrust_mnp_show				= deferred_dataref("laminar/B747/engine/thrust_mnp_show", "array[4]")
B747DR_thrust_mnp_show_all			= deferred_dataref("laminar/B747/engine/thrust_mnp_show_all", "number")

B747DR_reverse_mnp_show				= deferred_dataref("laminar/B747/engine/rev_mnp_show", "array[4)")
B747DR_reverse_mnp_show_all			= deferred_dataref("laminar/B747/engine/rev_mnp_show_all", "number")

B747DR_engine_fuel_valve_pos        = deferred_dataref("laminar/B747/engines/fuel_valve_pos", "array[4)")
B747DR_EICAS2_fuel_on_ind_status    = deferred_dataref("laminar/B747/engines/fuel_on_indicator_status", "array[4)")
B747DR_EICAS2_oil_press_status      = deferred_dataref("laminar/B747/engines/EICAS2_oil_press_status", "array[4)")
B747DR_EICAS2_engine_vibration      = deferred_dataref("laminar/B747/engines/vibration", "array[4)")
B747DR_EICAS2_engine_disturbance    = deferred_dataref("laminar/B747/engines/disturbance", "number")
B747DR_engine_vibration_position    = deferred_dataref("laminar/B747/engine/vibration_position", "array[4)")
B747DR_engine_oil_press_psi         = deferred_dataref("laminar/B747/engines/oil_press_psi", "array[4)")
B747DR_engine_oil_temp_degC         = deferred_dataref("laminar/B747/engines/oil_temp_degC", "array[4)")
B747DR_engine_oil_qty_liters        = deferred_dataref("laminar/B747/engines/oil_qty_liters", "array[4)")
B747DR_elec_apu_oil      			= deferred_dataref("laminar/B747/apu/oil", "number")
B747DR_engine_apu_n2      	        = deferred_dataref("laminar/B747/apu/n2", "number")
B747DR_EPR_max_limit                = deferred_dataref("laminar/B747/engines/EPR/max_limit", "array[4)")
B747DR_EGT_amber_inhibit            = deferred_dataref("laminar/B747/engines/EGT/amber_inhibit", "array[4)")
B747DR_EGT_amber_on                 = deferred_dataref("laminar/B747/engines/EGT/amber_on", "array[4)")
B747DR_EGT_white_on                 = deferred_dataref("laminar/B747/engines/EGT/white_on", "array[4)")

B747DR_init_engines_CD              = deferred_dataref("laminar/B747/engines/init_CD", "number")

B747DR_engine_TOGA_mode             = deferred_dataref("laminar/B747/engines/TOGA_mode", "number")

B747DR_ref_thr_limit_mode           = deferred_dataref("laminar/B747/engines/ref_thr_limit_mode", "string")

B747DR_autothrottle_fail            = deferred_dataref("laminar/B747/engines/autothrottle_fail", "number")
B747DR_autothrottle_active            = deferred_dataref("laminar/B747/engines/autothrottle_active", "number")
B747DR_reverser_lockout            = deferred_dataref("laminar/B747/engines/reverser_lockout", "number")


-- AI
B747CMD_ai_engines_quick_start		= deferred_command("laminar/B747/ai/engines_quick_start", "number", B747_ai_engines_quick_start_CMDhandler)


B747DR_engine_fire				= deferred_dataref("laminar/B747/annunciators/engine_fires", "array[5)")






