--[[
*****************************************************************************************
* Program Script Name	:	B747.35.fire
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

B747DR_fire_ovht_button_pos                 = deferred_dataref("laminar/B747/fire/fire_ovht/button_pos", "number")

B747DR_engine01_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine01/ext_switch/pos_arm", "number")
B747DR_engine02_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine02/ext_switch/pos_arm", "number")
B747DR_engine03_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine03/ext_switch/pos_arm", "number")
B747DR_engine04_fire_ext_switch_pos_arm     = deferred_dataref("laminar/B747/fire/engine04/ext_switch/pos_arm", "number")

B747DR_engine01_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine01/ext_switch/pos_disch", "number")
B747DR_engine02_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine02/ext_switch/pos_disch", "number")
B747DR_engine03_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine03/ext_switch/pos_disch", "number")
B747DR_engine04_fire_ext_switch_pos_disch   = deferred_dataref("laminar/B747/fire/engine04/ext_switch/pos_disch", "number")

B747DR_fire_ext_bottle_0102A_psi            = deferred_dataref("laminar/B747/fire/engine01_02A/ext_bottle/psi", "number")
B747DR_fire_ext_bottle_0102B_psi            = deferred_dataref("laminar/B747/fire/engine01_02B/ext_bottle/psi", "number")
B747DR_fire_ext_bottle_0304A_psi            = deferred_dataref("laminar/B747/fire/engine03_04A/ext_bottle/psi", "number")
B747DR_fire_ext_bottle_0304B_psi            = deferred_dataref("laminar/B747/fire/engine03_04B/ext_bottle/psi", "number")

B747DR_init_fire_CD                         = deferred_dataref("laminar/B747/fire/init_CD", "number")
simDR_press_diff_psi        = find_dataref("sim/cockpit2/pressurization/indicators/pressure_diffential_psi")
simDR_cockpit_smoke         = find_dataref("sim/operation/failures/rel_smoke_cpit")
function B747_smoke_evac_handle_DRhandler()

    if B747DR_smoke_evac_handle >= 0.95
        and simDR_press_diff_psi > 1.0
    then
        simDR_cockpit_smoke = 0
    end

end
B747DR_smoke_evac_handle                    = deferred_dataref("laminar/B747/fire/snoke_evac/handle", "number", B747_smoke_evac_handle_DRhandler)


B747CMD_fire_ovht_test_button       = deferred_command("laminar/B747/fire/button/fire_ovht_test", "Fire/Overheat Test", B747_fire_ovht_test_button_CMDhandler)



----- FIRE EXTINGUISHER SWITCHES --------------------------------------------------------
B747CMD_eng01_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine01/ext_switch_arm", "Fire Extinguisher Switch 01 Arm", B747_eng01_fire_ext_switch_arm_CMDhandler)
B747CMD_eng02_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine02/ext_switch_arm", "Fire Extinguisher Switch 02 Arm", B747_eng02_fire_ext_switch_arm_CMDhandler)
B747CMD_eng03_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine03/ext_switch_arm", "Fire Extinguisher Switch 03 Arm", B747_eng03_fire_ext_switch_arm_CMDhandler)
B747CMD_eng04_fire_ext_switch_arm   = deferred_command("laminar/B747/fire/engine04/ext_switch_arm", "Fire Extinguisher Switch 04 Arm", B747_eng04_fire_ext_switch_arm_CMDhandler)


B747CMD_eng01_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine01/ext_switch_A", "Fire Extinguisher Switch A", B747_eng01_fire_ext_switch_A_CMDhandler)
B747CMD_eng01_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine01/ext_switch_B", "Fire Extinguisher Switch B", B747_eng01_fire_ext_switch_B_CMDhandler)
B747CMD_eng02_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine02/ext_switch_A", "Fire Extinguisher Switch A", B747_eng02_fire_ext_switch_A_CMDhandler)
B747CMD_eng02_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine02/ext_switch_B", "Fire Extinguisher Switch B", B747_eng02_fire_ext_switch_B_CMDhandler)
B747CMD_eng03_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine03/ext_switch_A", "Fire Extinguisher Switch A", B747_eng03_fire_ext_switch_A_CMDhandler)
B747CMD_eng03_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine03/ext_switch_B", "Fire Extinguisher Switch B", B747_eng03_fire_ext_switch_B_CMDhandler)
B747CMD_eng04_fire_ext_switch_A     = deferred_command("laminar/B747/fire/engine04/ext_switch_A", "Fire Extinguisher Switch A", B747_eng04_fire_ext_switch_A_CMDhandler)
B747CMD_eng04_fire_ext_switch_B     = deferred_command("laminar/B747/fire/engine04/ext_switch_B", "Fire Extinguisher Switch B", B747_eng04_fire_ext_switch_B_CMDhandler)


-- AI
B747CMD_ai_fire_quick_start			= deferred_command("laminar/B747/ai/fire_quick_start", "number", B747_ai_fire_quick_start_CMDhandler)





