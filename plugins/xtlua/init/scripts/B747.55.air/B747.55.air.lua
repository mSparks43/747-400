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


B747DR_cabin_alt_auto_sel_pos       = deferred_dataref("laminar/B747/air/cabin_alt_auto/sel_dial_pos", "number")
B747DR_equip_cooling_sel_pos        = deferred_dataref("laminar/B747/air/equip_cooling/sel_dial_pos", "number")
B747DR_pack_ctrl_sel_pos            = deferred_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos", "array[3]")
B747DR_landing_alt_button_pos       = deferred_dataref("laminar/B747/air/landing_alt/button_pos", "number")

B747DR_outflow_valve_pos_L          = deferred_dataref("laminar/B747/air/outflow_valve_left/pos", "number")
B747DR_outflow_valve_pos_R          = deferred_dataref("laminar/B747/air/outflow_valve_right/pos", "number")

B747DR_landing_altitude             = deferred_dataref("laminar/B747/air/landing_altitude", "number")

B747_duct_pressure_C                = deferred_dataref("laminar/B747/air/duct_pressure_C", "number")


B747DR_pressure_EICAS1_display_status = deferred_dataref("laminar/B747/air/pressurization/EICAS1_display_status", "number")

B747DR_init_air_CD                  = deferred_dataref("laminar/B747/air/init_CD", "number")




--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

-- LANDING ALTITUDE SELECTOR
B747DR_landing_alt_sel_rheo     = deferred_dataref("laminar/B747/air/land_alt_sel/rheostat", "number", B747DR_landing_alt_sel_rheo_DRhandler)


-- PASSENGER TEMP CONTROL
B747DR_pass_temp_ctrl__rheo     = deferred_dataref("laminar/B747/air/pass_temp_ctrl/rheostat", "number", B747DR_pass_temp_ctrl_rheo_DRhandler)


-- FLIGHT DECK TEMP CONTROL
B747DR_flt_deck_temp_ctrl_rheo  = deferred_dataref("laminar/B747/air/flt_deck_temp_ctrl/rheostat", "number", B747DR_flt_deck_temp_ctrl_rheo_DRhandler)


-- CARGO TEMP CONTROL
B747DR_cargo_temp_ctrl_rheo     = deferred_dataref("laminar/B747/air/cargo_temp_ctrl/rheostat", "number", B747DR_cargo_temp_ctrl_rheo_DRhandler)



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





