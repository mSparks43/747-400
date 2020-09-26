
--**********************************************************************--
--** 				             FIND X-PLANE DATAREFS            	                        **--
--**********************************************************************--

Altitude = find_dataref ("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
Gear = find_dataref ("sim/flightmodel2/gear/deploy_ratio[0]")
Flaps = find_dataref ("sim/cockpit2/controls/flap_handle_deploy_ratio")
Battery = find_dataref("sim/cockpit2/electrical/battery_on[0]")
On_Ground = find_dataref ("sim/flightmodel/failures/onground_any")
ASpeed = find_dataref ("sim/flightmodel/position/indicated_airspeed")
Throttle = find_dataref ("sim/cockpit2/engine/actuators/throttle_ratio_all")
VSpeed = find_dataref("sim/cockpit2/gauges/indicators/vvi_fpm_pilot")
--**********************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS           **--
--***********************************************************************--

Dont_sink = create_dataref("sim/cockpit/Warning/Dont_sink", "number")
Low_Terrain = create_dataref("sim/cockpit/Warning/Low_Terrain", "number")
Low_Gear = create_dataref("sim/cockpit/Warning/Low_Gear", "number")
Low_Flaps = create_dataref("sim/cockpit/Warning/Low_Flaps", "number")
Terrain = create_dataref("sim/cockpit/Warning/Terrain", "number")
Pull_Up = create_dataref("sim/cockpit/Warning/Pull_Up", "number")
Sinkrate = create_dataref("sim/cockpit/Warning/Sinkrate", "number")
Airborne = create_dataref("sim/flightmodel/state/Airborne", "number")
--------------------------------------------------------------------------------------------

function Aircraft_Pos()

-- Flight Phases -----------------------------

	if Altitude > 100 then
		Airborne = 1
	end
end
	
function GPWS()

	if Airborne == 1 and  Battery == 1 and On_Ground == 0 
	then WSys = true
	else WSys = false
	end
	
--Dont_sink-------------------------------------------------------

	if WSys == true  then
		if Altitude > 200 and Altitude < 5000 then
		     if ASpeed < 130 and Flaps < 0.4 then
		          if Throttle > 0.4 and VSpeed < -50  
			     then Dont_sink = 1
		          elseif Throttle < 0.4 or VSpeed > 5
                    then Dont_sink = 0
			     end
		     elseif ASpeed > 140 and Flaps > 0.8 then
		     Dont_sink = 0
			 elseif ASpeed > 150 and Flaps > 0.2 then
		     Dont_sink = 0
		     end
		else Dont_sink = 0
		end
	elseif	WSys == false
	then Dont_sink = 0
	end

--Terrain-------------------------------------------------------

	if WSys == true then
		     if Altitude < 1600 and Altitude > 1100 then
		          if VSpeed < -1500 and VSpeed > -2500 then 
				     if Flaps < 0.2 and Gear < 0.5
			          then Terrain = 1
		              elseif Flaps > 0.2 or Gear > 0.8
					then Terrain = 0
			         end
		         elseif VSpeed > 100 or VSpeed < -2500
				then Terrain = 0
		         end
		 elseif Altitude > 1600 or Altitude < 1100
		 then Terrain = 0
		 end
	 elseif WSys == false
	then Terrain = 0
	end

--Low_Terrain -------------------------------------------------------

	if WSys == true  then
	if ASpeed > 140 then
		if Altitude < 1000 and Flaps < 0.1 then
		          if VSpeed < -500 and VSpeed > -2000
			     then Low_Terrain = 1
		          elseif VSpeed > -50 or VSpeed < -2100
                   then Low_Terrain = 0
			     end
		     elseif Altitude > 1000 or Flaps < 0.1 
			then Low_Terrain = 0
		     end
		 elseif ASpeed < 140
		then Low_Terrain = 0
		 end
	elseif	WSys == false
	then Low_Terrain = 0
	end

	
--Low_Gear -------------------------------------------------------

	if WSys == true  then
		if Altitude < 800  then
		     if Gear < 0.1 then
		          if VSpeed < 300
			     then Low_Gear = 1
		          elseif VSpeed > 400
                    then Low_Gear = 0
			     end
		     elseif Gear > 0.9 then
		     Low_Gear = 0
		     end
		elseif Altitude > 800 then
		Low_Gear = 0
		end
	elseif WSys == false
	then Low_Gear = 0
	end

--Low_Flaps-------------------------------------------------------

	if WSys == true  then
		     if Flaps < 0.6 and Altitude < 1000 then
			     if VSpeed < -50 and VSpeed > -2500 then
		          if Throttle < 0.9 and ASpeed > 140
			     then Low_Flaps = 1
		          elseif Throttle > 0.9 or ASpeed < 140
                    then Low_Flaps = 0
			     end
			elseif	 VSpeed > 5 or VSpeed < -2500
			then Low_Flaps = 0
			end
		     elseif Flaps > 0.6  or Altitude > 1100 then
		     Low_Flaps = 0
		     end
	elseif	WSys == false
	then Low_Flaps = 0
	end

--Pull_Up-------------------------------------------------------

	if WSys == true  then
		 if (Altitude < 4000  and Altitude > 1500)  and ASpeed > 200 and VSpeed < -3500 
		then Pull_Up = 1
		elseif  (Altitude < 4000  and Altitude > 1500)  and ASpeed > 200 and VSpeed > -3400 
		then Pull_Up = 0
		elseif  (Altitude < 4000  and Altitude > 1500)  and ASpeed < 200 and VSpeed > -3400 
          then Pull_Up = 0
		elseif Altitude > 4000
		then Pull_Up = 0
		end
      	if Altitude < 1500  and ASpeed > 190 and VSpeed < -1600
		then Pull_Up = 1
		elseif	Altitude < 1500  and ASpeed > 190 and VSpeed > -1500
           then Pull_Up = 0
		 elseif Altitude < 1500  and ASpeed < 180 and VSpeed > -1500
		then Pull_Up = 0
		elseif Altitude < 1500  and ASpeed < 180 and VSpeed < -1600
		 then Pull_Up = 0
		 end
	elseif WSys == false
	then Pull_Up = 0
	end
	

--Sinkrate-------------------------------------------------------

	if WSys == true  then
		     if Altitude < 2500 then
		          if VSpeed < -2500 and VSpeed > -3450
			     then Sinkrate = 1
		          elseif VSpeed > -2400 or VSpeed < -3500
				then Sinkrate = 0
		          end
			elseif Altitude > 2500 
			then Sinkrate = 0
		     end	  
	elseif WSys == false
	then Sinkrate = 0
	end
end

function after_physics()
	GPWS() 
	Aircraft_Pos() 
end