--[[
*****************************************************************************************
* Program Script Name	:	B747.90.lighting
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

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]


--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

NUM_SPILL_LIGHT_INDICES = 9
NUM_LANDING_LIGHTS      = 4
NUM_ANNUN_LIGHTS        = 270


--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--





--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--
local annun = {}
annun.a = {}
annun.b = {}
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
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

----- SPILL LIGHTS ----------------------------------------------------------------------
B747DR_spill_light_capt_panel_flood     = deferred_dataref("laminar/B747/light/spill/ratio/captain_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_center_panel_flood   = deferred_dataref("laminar/B747/light/spill/ratio/center_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_capt_map             = deferred_dataref("laminar/B747/light/spill/ratio/captain_map", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_capt_chart           = deferred_dataref("laminar/B747/light/spill/ratio/captain_chart", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_fo_panel_flood       = deferred_dataref("laminar/B747/light/spill/ratio/first_officer_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_fo_map               = deferred_dataref("laminar/B747/light/spill/ratio/first_officer_map", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_fo_chart             = deferred_dataref("laminar/B747/light/spill/ratio/first_officer_chart", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_observer_map         = deferred_dataref("laminar/B747/light/spill/ratio/observer_map", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_mcp_flood            = deferred_dataref("laminar/B747/light/spill/ratio/mcp_panel", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_aisle_stand_flood    = deferred_dataref("laminar/B747/light/spill/ratio/aisle_stand", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_spill_light_mag_compass_flood    = deferred_dataref("laminar/B747/light/spill/ratio/mag_compass", "array[" .. tostring(NUM_SPILL_LIGHT_INDICES) .. "]")
B747DR_instrument_brightness_ratio      = deferred_dataref("laminar/B747/switches/instrument_brightness_ratio", "array[32]")
B747DR_init_lighting_CD                 = deferred_dataref("laminar/B747/lighting/init_CD", "number")

--wxr lighting
B747DR_wxr_left_GCS             = deferred_dataref("laminar/B747/wxr/left/GCS", "number")
B747DR_wxr_left_TFR             = deferred_dataref("laminar/B747/wxr/left/TFR", "number")
B747DR_wxr_left_WX             = deferred_dataref("laminar/B747/wxr/left/WX", "number")
B747DR_wxr_left_WX_T            = deferred_dataref("laminar/B747/wxr/left/WX_T", "number")
B747DR_wxr_left_MAP            = deferred_dataref("laminar/B747/wxr/left/MAP", "number")
B747DR_wxr_right_GCS             = deferred_dataref("laminar/B747/wxr/right/GCS", "number")
B747DR_wxr_right_TFR             = deferred_dataref("laminar/B747/wxr/right/TFR", "number")
B747DR_wxr_right_WX             = deferred_dataref("laminar/B747/wxr/right/WX", "number")
B747DR_wxr_right_WX_T            = deferred_dataref("laminar/B747/wxr/right/WX_T", "number")
B747DR_wxr_right_MAP            = deferred_dataref("laminar/B747/wxr/right/MAP", "number")

B747DR_wxr_test            = deferred_dataref("laminar/B747/wxr/test", "number")
B747DR_wxr_RR            = deferred_dataref("laminar/B747/wxr/RR", "number")
B747DR_wxr_LR            = deferred_dataref("laminar/B747/wxr/LR", "number")

----- LIT -------------------------------------------------------------------------------
--B747DR_LIT_capt_panel_flood             = deferred_dataref("laminar/B747/light/LIT/capt_panel_flood", "number")
--B747DR_LIT_fo_panel_flood               = deferred_dataref("laminar/B747/light/LIT/fo_panel_flood", "number")



----- ANNUNCIATORS ----------------------------------------------------------------------
B747DR_annun_brightness_ratio           = deferred_dataref("laminar/B747/annunciator/brightness_ratio", "array[" .. tostring(NUM_ANNUN_LIGHTS) .. "]")





--*************************************************************************************--
--** 				         READ-WRITE CUSTOM DATAREF HANDLERS     	    	     **--
--*************************************************************************************--

----- LIGHTING RHEOSTATS ----------------------------------------------------------------
function B747DR_flood_light_rheo_capt_panel_DRhandler() end
function B747DR_map_light_rheo_capt_DRhandler() end
function B747DR_chart_light_rheo_capt_DRhandler() end
function B747DR_flood_light_rheo_fo_panel_DRhandler() end
function B747DR_map_light_rheo_fo_DRhandler() end
function B747DR_chart_light_rheo_fo_DRhandler() end
function B747DR_map_light_rheo_observer_DRhandler() end
function B747DR_flood_light_rheo_mcp_DRhandler() end
function B747DR_flood_light_rheo_aisle_stand_DRhandler() end
function B747DR_flood_light_rheo_overhead_DRhandler() end




--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

----- LIGHTING RHEOSTATS ----------------------------------------------------------------
B747DR_flood_light_rheo_capt_panel      = deferred_dataref("laminar/B747/light/flood/rheostat/captain_panel", "number", B747DR_flood_light_rheo_capt_panel_DRhandler)
B747DR_map_light_rheo_capt              = deferred_dataref("laminar/B747/light/map/rheostat/captain", "number", B747DR_map_light_rheo_capt_DRhandler)
B747DR_chart_light_rheo_capt            = deferred_dataref("laminar/B747/light/chart/rheostat/captain", "number", B747DR_chart_light_rheo_capt_DRhandler)
B747DR_flood_light_rheo_fo_panel        = deferred_dataref("laminar/B747/light/flood/rheostat/first_officer_panel", "number", B747DR_flood_light_rheo_fo_panel_DRhandler)
B747DR_map_light_rheo_fo                = deferred_dataref("laminar/B747/light/map/rheostat/first_officer", "number", B747DR_map_light_rheo_fo_DRhandler)
B747DR_chart_light_rheo_fo              = deferred_dataref("laminar/B747/light/chart/rheostat/first_officer", "number", B747DR_chart_light_rheo_fo_DRhandler)
B747DR_map_light_rheo_observer          = deferred_dataref("laminar/B747/light/map/rheostat/observer", "number", B747DR_map_light_rheo_observer_DRhandler)
B747DR_flood_light_rheo_mcp             = deferred_dataref("laminar/B747/light/flood/rheostat/mcp_panel", "number", B747DR_flood_light_rheo_mcp_DRhandler)
B747DR_flood_light_rheo_aisle_stand     = deferred_dataref("laminar/B747/light/flood/rheostat/aisle_stand", "number", B747DR_flood_light_rheo_aisle_stand_DRhandler)
B747DR_flood_light_rheo_overhead        = deferred_dataref("laminar/B747/light/flood/rheostat/overhead", "number", B747DR_flood_light_rheo_overhead_DRhandler)

----- SPILL LIGHTS ----------------------------------------------------------------------
B747DR_fmc_spill_lights			= deferred_dataref("laminar/B747/fmc/spill_lights", "number") --silvereagle

B747CMD_cockpitLightsOn		= deferred_command("laminar/B747/light/cockpit_lightsOn", "cockpit lights On", B747CMD_cockpitLightsOn_CMDhandler)
B747CMD_cockpitLightsOff		= deferred_command("laminar/B747/light/cockpit_lightsOff", "cockpit lights Off", B747CMD_cockpitLightsOff_CMDhandler)

--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--







--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--






--*************************************************************************************--
--** 				               CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- AI
B747CMD_ai_lighting_quick_start			= deferred_command("laminar/B747/ai/lighting_quick_start", "quickstart lighting", B747_ai_lighting_quick_start_CMDhandler)



--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--




--*************************************************************************************--
--** 				              CREATE SYSTEM OBJECTS            	    			 **--
--*************************************************************************************--




--*************************************************************************************--
--** 				                 SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------




