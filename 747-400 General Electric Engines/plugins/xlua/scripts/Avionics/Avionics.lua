
--*************************************************************************************--
--** 				             FIND X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

Generator1 = find_dataref("sim/cockpit2/electrical/generator_amps[0]")
Generator2 = find_dataref("sim/cockpit2/electrical/generator_amps[1]")
Generator3 = find_dataref("sim/cockpit2/electrical/generator_amps[2]")
Generator4 = find_dataref("sim/cockpit2/electrical/generator_amps[3]")
Generator_apu = find_dataref("sim/cockpit/electrical/generator_apu_on")
Generator_gpu = find_dataref("sim/cockpit/electrical/gpu_on")
BleedL = find_dataref("laminar/B747/air/duct_pressure_L")
BleedR = find_dataref("laminar/B747/air/duct_pressure_R")
Pack1_Sw = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos[0]")
Pack2_Sw = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos[1]")
Pack3_Sw = find_dataref("laminar/B747/air/pack_ctrl/sel_dial_pos[2]")


--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

Packs_L = create_dataref("sim/cockpit2/Cooling/Packs_L", "number")
Packs_U = create_dataref("sim/cockpit2/Cooling/Packs_U", "number")
Packs_R = create_dataref("sim/cockpit2/Cooling/Packs_R", "number")
Avionics_Power	= create_dataref("sim/cockpit2/electrical/Avionics_Power", "number")

-- Avionics -------------------------------------------------

function Avionics(phase, duration)

   if Generator1 > 5 or Generator2 > 5
     or Generator3 > 5 or Generator4 > 5
	 then Eng_Gen = 1 
	 elseif Generator1 == 0 and Generator2 == 0
     and Generator3 == 0 and Generator4 == 0
	 then Eng_Gen = 0 
end

   if Eng_Gen == 1 or Generator_apu == 1 or Generator_gpu == 1 then
	Avionics_Power = 1 
	elseif Eng_Gen == 0 and Generator_apu == 0 and Generator_gpu == 0  then
	Avionics_Power = 0 
end
end

--  Packs--------------------------------------------------

function Packs (phase, duration)
     if Avionics_Power == 1 then 
	     if BleedL > 10 then  
		     if Pack1_Sw == 1 
			     then Packs_L = 1
				 elseif Pack1_Sw == 0
				 then Packs_L = 0
				 end
		 elseif BleedL < 5
		 then Packs_L = 0
		 end
	elseif Avionics_Power == 0
	then Packs_L = 0
	end
	
	     if Avionics_Power == 1 then 
	     if BleedR > 10 then  
		     if Pack3_Sw == 1 
			     then Packs_R = 1
				 elseif Pack3_Sw == 0
				 then Packs_R = 0
				 end
		 elseif BleedR < 5
		 then Packs_R= 0
		 end
	elseif Avionics_Power == 0
	then Packs_R = 0
	end
	
		     if Avionics_Power == 1 then 
	     if BleedR > 10 or BleedL > 10 then  
		     if Pack2_Sw >= 1 
			     then Packs_U = 1
				 elseif Pack2_Sw == 0
				 then Packs_U = 0
				 end
		 elseif BleedR < 5 and BleedL < 5
		 then Packs_U = 0
		 end
	elseif Avionics_Power == 0
	then Packs_U = 0
	end
end	 
	 


function after_physics()
	Packs()
	Avionics() 
end
