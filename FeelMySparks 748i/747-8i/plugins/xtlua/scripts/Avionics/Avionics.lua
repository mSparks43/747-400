
--*************************************************************************************--
--** 				             FIND X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--


Generator1_on	= find_dataref("sim/cockpit2/electrical/generator_amps[0]")
Generator2_on	= find_dataref("sim/cockpit2/electrical/generator_amps[1]")
Generator3_on	= find_dataref("sim/cockpit2/electrical/generator_amps[2]")
Generator4_on	= find_dataref("sim/cockpit2/electrical/generator_amps[3]")
Generator_on_apu	= find_dataref("sim/cockpit/electrical/generator_apu_on")
Generator_on_gpu = find_dataref("sim/cockpit/electrical/gpu_on")
Pack1_Sw = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos[0]")
Pack2_Sw = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos[1]")
Pack3_Sw = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos[2]")
simDR_version=find_dataref("sim/version/xplane_internal_version")
simDR_gpuvolts=find_dataref("sim/cockpit2/electrical/GPU_generator_volts")
--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

function sim_avionics1_off_CMDhandler() end
function sim_avionics1_on_CMDhandler() end

--*************************************************************************************--
--** 				               REPLACE X-PLANE COMMANDS                   	     **--
--*************************************************************************************--

simCMD_avionics_1_on = replace_command("sim/systems/avionics_on", sim_avionics1_on_CMDhandler)
simCMD_avionics_1_off = replace_command("sim/systems/avionics_off", sim_avionics1_off_CMDhandler)

--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--


Packs_EXT = find_dataref("sim/cockpit2/Cooling/Packs_EXT")
Avionics_Power_on	= find_dataref("sim/cockpit/electrical/avionics_on")
B747DR_button_switch_position       = find_dataref("laminar/B747/button_switch/position")
-- Exterior Packs--------------------------------------------------

function Packs_EXT_On (phase, duration)
   if Pack2_Sw == 1 or Pack1_Sw == 1 or Pack3_Sw == 1 
   then
   	Packs_EXT = 1
	elseif Pack2_Sw == 0 and (Pack1_Sw == 0 and Pack3_Sw == 0) 
	then
	Packs_EXT = 0
	end
end

-- Bus Power -------------------------------------------------

function Eng_Gen(phase, duration)

   if Generator1_on > 5 or Generator2_on > 5
     or Generator3_on > 5 or Generator4_on > 5
	 then Eng_Gen_on = 1 
	 elseif Generator1_on == 0 and Generator2_on == 0
     and Generator3_on == 0 and Generator4_on == 0
	 then Eng_Gen_on = 0 
end
end


function Ext_Power_Available(phase, duration)
	local gpuOn=false

	if simDR_version>=120012 then
		puOn=(Generator_on_gpu == 1) and (simDR_gpuvolts>=24)
	else
		gpuOn=(Generator_on_gpu == 1)
	end
   if Generator_on_apu == 1 or
		gpuOn
     then Ext_Power_Av = 1 
   elseif Generator_on_apu == 0
   	 and not(gpuOn) 
	 then Ext_Power_Av = 0 
end
end

function Avionics_Power(phase, duration)
	local cAV=Avionics_Power_on
  if B747DR_button_switch_position[13]==1  then
		Avionics_Power_on = 1 
	else
		Avionics_Power_on = 0 
  end
end

function after_physics() 
    Eng_Gen()
    Ext_Power_Available()
	Packs_EXT_On()
	Avionics_Power() 

end
