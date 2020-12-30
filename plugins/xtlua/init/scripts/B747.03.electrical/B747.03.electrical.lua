--[[
*****************************************************************************************
* Program Script Name	:	B747.03.electrical
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2016-05-03	0.01a				Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED	    *
*****************************************************************************************
--]]

--[[

ELECTRICAL SYSTEM LOGIC DESCRIPTION:

In planemaker we set up 5 busses.  The battery is assigned to bus 5 making it essentially
the "Battery Bus".  The fifth bus will have power when the battery switch is on.
The 747 has 4 "bus-tie" switches, which can isolate each of the 4 main busses.  This cannot
be done in X-Plane so we require ALL (747) bus-tie switches to be closed in order to close the
X-Plane cross-tie (handled in the code below).  So, in X-Plane we assign the battery and
generators to bus 5.  Therefore, all of these 4 busses will have zero voltage until the
cross-tie is closed.

Since this logic means that all 4 busses either have power or they don't, the assignment of
components to busses in Planemaker is made for amp load distribution, not for power
source.  There should be no assignments made to the fifth bus.

--]]


--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--
function null_command(phase, duration)
end
--replace create_command
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
B747DR_elec_standby_power_sel_pos   = deferred_dataref("laminar/B747/electrical/standby_power/sel_dial_pos", "number")
B747DR_elec_display_power   = deferred_dataref("laminar/B747/electrical/display_has_power", "array[9]")
-- Captain PFD
-- First Officer PFD
-- First Officer ND
-- Captain ND
-- Upper EIACAS
-- Lower EICAS
-- FMS C    
-- FMS R
-- FMS L
B747DR_simDR_captain_display              = deferred_dataref("laminar/B747/electrical/capt_display_power", "number")
B747DR_simDR_fo_display             = deferred_dataref("laminar/B747/electrical/fo_display_power", "number")

B747DR_elec_apu_sel_pos             = deferred_dataref("laminar/B747/electrical/apu/sel_dial_pos", "number")
B747DR_elec_stby_ignit_sel_pos      = deferred_dataref("laminar/B747/electrical/stby_ignit/sel_dial_pos", "number")
B747DR_elec_auto_ignit_sel_pos      = deferred_dataref("laminar/B747/electrical/auto_ignit/sel_dial_pos", "number")

B747DR_elec_apu_inlet_door_pos      = deferred_dataref("laminar/B747/electrical/apu_inlet_door", "number")
B747DR_elec_apu_volts      = deferred_dataref("laminar/B747/electrical/apu_volts", "number")
B747DR_elec_ext_pwr1_available      = deferred_dataref("laminar/B747/electrical/ext_pwr1_avail", "number")
B747DR_elec_ext_pwr2_available      = deferred_dataref("laminar/B747/electrical/ext_pwr2_avail", "number")
B747DR_elec_apu_pwr1_available      = deferred_dataref("laminar/B747/electrical/apu_pwr1_avail", "number")
B747DR_elec_apu_pwr2_available      = deferred_dataref("laminar/B747/electrical/apu_pwr2_avail", "number")
B747DR_elec_ext_pwr1_on      	= deferred_dataref("laminar/B747/electrical/ext_pwr1_on", "number")
B747DR_elec_ext_pwr2_on      	= deferred_dataref("laminar/B747/electrical/ext_pwr2_on", "number")
B747DR_elec_apu_pwr1_on      	= deferred_dataref("laminar/B747/electrical/apu_pwr1_on", "number")
B747DR_elec_apu_pwr2_on      	= deferred_dataref("laminar/B747/electrical/apu_pwr2_on", "number")

B747DR_elec_ssb      		= deferred_dataref("laminar/B747/electrical/ssb", "number")
B747DR_elec_topleftbus      	= deferred_dataref("laminar/B747/electrical/topleftbus", "number")
B747DR_elec_toprightbus      	= deferred_dataref("laminar/B747/electrical/toprightbus", "number")
B747DR_elec_bus1hot      	= deferred_dataref("laminar/B747/electrical/bus1hot", "number")
B747DR_elec_bus2hot      	= deferred_dataref("laminar/B747/electrical/bus2hot", "number")
B747DR_elec_bus3hot      	= deferred_dataref("laminar/B747/electrical/bus3hot", "number")
B747DR_elec_bus4hot      	= deferred_dataref("laminar/B747/electrical/bus4hot", "number")
B747DR_elec_utilityleft1      	= deferred_dataref("laminar/B747/electrical/utilityleft1", "number")
B747DR_elec_utilityright1      	= deferred_dataref("laminar/B747/electrical/utilityright1", "number")
B747DR_elec_utilityleft2      	= deferred_dataref("laminar/B747/electrical/utilityleft2", "number")
B747DR_elec_utilityright2      	= deferred_dataref("laminar/B747/electrical/utilityright2", "number")
B747DR_init_elec_CD                 = deferred_dataref("laminar/B747/elec/init_CD", "number")
B747DR_simDR_esys0              = deferred_dataref("laminar/B747/rel_esys", "number")
B747DR_simDR_esys1              = deferred_dataref("laminar/B747/rel_esys2", "number")
B747DR_simDR_esys2              = deferred_dataref("laminar/B747/rel_esys3", "number")
B747DR_simDR_esys3              = deferred_dataref("laminar/B747/rel_esys4", "number")


-- STANDBY POWER
B747CMD_connect_power          = deferred_command("laminar/B747/electrical/connect_power", "Connect external power", B747_connect_power_CMDhandler)
B747CMD_elec_standby_power_sel_up = deferred_command("laminar/B747/electrical/standby_power/sel_dial_up", "Electrical Standby Power Selector Up", B747_elec_standby_power_sel_up_CMDhandler)
B747CMD_elec_standby_power_sel_dn = deferred_command("laminar/B747/electrical/standby_power/sel_dial_dn", "Electrical Standby Power Selector Down", B747_elec_standby_power_sel_dn_CMDhandler)



-- APU SELECTOR
B747CMD_elec_apu_sel_up = deferred_command("laminar/B747/electrical/apu/sel_dial_up", "Electrical APU Selector Dial Up", B747_elec_apu_sel_up_CMDhandler)
B747CMD_elec_apu_sel_dn = deferred_command("laminar/B747/electrical/apu/sel_dial_dn", "Electrical APU Selector Dial Down", B747_elec_apu_sel_dn_CMDhandler)



-- STANDBY IGNITION
B747CMD_stby_ign_sel_up = deferred_command("laminar/B747/electrical/stby_ignit/sel_dial_up", "Electrical Standby Ignition Selector Dial Up", B747_stby_ign_sel_up_CMDhandler)
B747CMD_stby_ign_sel_dn = deferred_command("laminar/B747/electrical/stby_ignit/sel_dial_dn", "Electrical Standby Ignition Selector Dial Down", B747_stby_ign_sel_dn_CMDhandler)



-- AUTO IGNITION
B747CMD_auto_ign_sel_up = deferred_command("laminar/B747/electrical/auto_ignit/sel_dial_up", "Electrical Auto Ignition Selector Dial Up", B747_auto_ign_sel_up_CMDhandler)
B747CMD_auto_ign_sel_dn = deferred_command("laminar/B747/electrical/auto_ignit/sel_dial_dn", "Electrical Auto Ignition Selector Dial Down", B747_auto_ign_sel_dn_CMDhandler)


-- AI
B747CMD_ai_elec_quick_start			= deferred_command("laminar/B747/ai/elec_quick_start", "number", B747_ai_elec_quick_start_CMDhandler)





