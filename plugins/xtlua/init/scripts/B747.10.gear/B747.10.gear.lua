--[[
*****************************************************************************************
* Program Script Name	:	B747.10.gear
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



--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

--sim/operation/failures/rel_lbrakes  int y failure_enum  Left Brakes
--sim/operation/failures/rel_rbrakes  int y failure_enum  Right Brakes
--sim/operation/failures/rel_lagear1  int y failure_enum  Landing Gear 1 retract
--sim/operation/failures/rel_lagear2  int y failure_enum  Landing Gear 2 retract
--sim/operation/failures/rel_lagear3  int y failure_enum  Landing Gear 3 retract
--sim/operation/failures/rel_lagear4  int y failure_enum  Landing Gear 4 retract
--sim/operation/failures/rel_lagear5  int y failure_enum  Landing Gear 5 retract
function null_command(phase, duration)
end
--replace create_command
--[[function deferred_command(name,desc,nilFunc)
	c = XLuaCreateCommand(name,desc)
	print("Deffereed command: "..name)
	XLuaReplaceCommand(c,null_command)
	return make_command_obj(c)
end
--replace create_dataref
function deferred_dataref(name,type,notifier)
	print("Deffereed dataref: "..name)
	dref=XLuaCreateDataRef(name, type,"yes",notifier)
	return wrap_dref_any(dref,type) 
end]]
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

B747DR_gear_lock_override_pos   = deferred_dataref("laminar/B747/gear_lock_ovrd/position", "number")
B747DR_autobrakes_sel_dial_pos  = deferred_dataref("laminar/B747/gear/autobrakes/sel_dial_pos", "number")

B747DR_gear_annun_status        = deferred_dataref("laminar/B747/gear/gear_position/annun_status", "number")
B747DR_EICAS1_gear_display_status = deferred_dataref("laminar/B747/gear/EICAS1_display_status", "number")

B747DR_tire_pressure            = deferred_dataref("laminar/B747/gear/tire_pressure", "array[18]")
B747DR_brake_temp               = deferred_dataref("laminar/B747/gear/brake_temp", "array[18]")
B747DR_brake_temp_ind               = deferred_dataref("laminar/B747/gear/brake_temp_ind", "array[18]")
B747DR_init_gear_CD             = deferred_dataref("laminar/B747/gear/init_CD", "number")
B747DR__gear_chocked           = deferred_dataref("laminar/B747/gear/chocked", "number")
----- GEAR HANDLE DATAREF HANDLER -------------------------------------------------------

local B747_gear_handle_lock_override = 0
local B747_gear_handle_lock = 0
simDR_gear_handle_down      = find_dataref("sim/cockpit2/controls/gear_handle_down")
function B747DR_gear_handle_DRhandler()

    -- GEAR HANDLE LOCK IS DISENGAGED
    if B747_gear_handle_lock == 0 then

        if B747DR_gear_handle <= 0.1 then
            B747DR_gear_handle = 0.0   -- DETENT (GEAR HANDLE "DOWN")
            simDR_gear_handle_down = 1
        elseif B747DR_gear_handle >= 0.9 and B747DR_gear_handle <= 1.1 then
            B747DR_gear_handle = 1.0   -- DETENT (GEAR HANDLE "OFF")
        elseif B747DR_gear_handle >= 1.9 then
            B747DR_gear_handle = 2.0   -- DETENT (GEAR HANDLE "UP")
            simDR_gear_handle_down = 0
        end
        
        
    -- GEAR HANDLE LOCK IS ENGAGED
    else

        if B747DR_gear_handle <= 0.1 then
            B747DR_gear_handle = 0.0   -- DETENT (GEAR HANDLE "DOWN")
            simDR_gear_handle_down = 1
        elseif B747DR_gear_handle >= 0.9 then
            B747DR_gear_handle = 1.0
        end

    end
    
end    



function B747DR_gear_handle_detent_DRhandler() end

B747DR_gear_handle 			= deferred_dataref("laminar/B747/actuator/gear_handle", "number", B747DR_gear_handle_DRhandler)
B747DR_gear_handle_detent 	= deferred_dataref("laminar/B747/actuator/gear_handle_detent", "number", B747DR_gear_handle_detent_DRhandler)





-- GEAR LOCK OVERRIDE
B747CMD_gear_lock_override      = deferred_command("laminar/B747/gear_lock/override", "Gear Lock Override", B747_gear_lock_override_CMDhandler)

B747CMD_gear_up_full      = deferred_command("laminar/B747/gear/overrideUp", "Gear Full Up", B747_gear_lock_override_CMDhandler)
B747CMD_gear_down_full      = deferred_command("laminar/B747/gear/overrideDown", "Gear Full Down", B747_gear_lock_override_CMDhandler)
-- AUTOBRAKES SELECTOR DIAL
B747CMD_autobrakes_sel_dial_up  = deferred_command("laminar/B747/gear/autobrakes/sel_dial_up", "Autobrakes Sel Dial Up", B747_autobrakes_sel_dial_up_CMDhandler)
B747CMD_autobrakes_sel_dial_dn  = deferred_command("laminar/B747/gear/autobrakes/sel_dial_dn", "Autobrakes Sel Dial Down", B747_autobrakes_sel_dial_dn_CMDhandler)


-- AI
B747CMD_ai_gear_quick_start			= deferred_command("laminar/B747/ai/gear_quick_start", "number", B747_ai_gear_quick_start_CMDhandler)


simDR_aircraft_on_ground    = find_dataref("sim/flightmodel/failures/onground_any")



