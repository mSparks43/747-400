--[[
*****************************************************************************************
* Program Script Name	:	B747.60.fltInst03 (first officer clock)
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2017-10-30	0.01a				Start of Dev
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

local B747_chrono_mode_fo		= 0															-- 0=RESET, 1=START, 2=STOP
local B747_chrono_seconds_fo	= 0

local sim_ch_old_time_fo 		= 0
local sim_ch_new_time_fo 		= 0	
														
local B747_et_seconds_fo		= 0

local sim_et_old_time_fo 		= 0
local sim_et_new_time_fo 		= 0




--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_fltInst_fo_clock_CHR_switch_pos		= deferred_dataref("laminar/B747/fltInst/fo/clock_chr_sw_pos", "number")
B747DR_fltInst_fo_clock_DATE_switch_pos		= deferred_dataref("laminar/B747/fltInst/fo/clock_date_sw_pos", "number")
B747DR_fltInst_fo_clock_ET_sel_pos			= deferred_dataref("laminar/B747/fltInst/fo/clock_et_sel_pos", "number")				-- 0=HLD, 1=RUN, 2=RESET 
B747DR_fltInst_fo_clock_SET_sel_pos			= deferred_dataref("laminar/B747/fltInst/fo/clock_set_sel_pos", "number")		
B747DR_fltInst_fo_clock_UTC_display			= deferred_dataref("laminar/B747/fltInst/fo/clock_utc_display", "number")				-- 0=TIME, 1=DATE
B747DR_fltInst_fo_clock_DATE_display_mode	= deferred_dataref("laminar/B747/fltInst/fo/clock_date_display_mode", "number")		-- 0=DAY/MONTH, 1=YEAR	
B747DR_fltInst_fo_clock_ET_CHR_display		= deferred_dataref("laminar/B747/fltInst/fo/clock_et_chr_display", "number")			-- 0=ET, 1=CHR	
B747DR_fltInst_fo_clock_ET_minutes			= deferred_dataref("laminar/B747/fltInst/fo/clock_et_minutes", "number")
B747DR_fltInst_fo_clock_ET_hours			= deferred_dataref("laminar/B747/fltInst/fo/clock_et_hours", "number")
B747DR_fltInst_fo_clock_CHR_seconds			= deferred_dataref("laminar/B747/fltInst/fo/clock_chr_seconds", "number")
B747DR_fltInst_fo_clock_CHR_minutes			= deferred_dataref("laminar/B747/fltInst/fo/clock_chr_minutes", "number")
B747DR_fltInst_fo_clock_year				= deferred_dataref("laminar/B747/fltInst/fo/clock_year", "number")
B747DR_et_seconds_fo                          = deferred_dataref("laminar/B747/fltInst/fo/clock_et_seconds", "number")




--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             X-PLANE COMMAND HANDLERS               	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                 X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

function B747_fo_clock_chrono_switch_CMDhandler(phase, duration) 
	if phase == 0 then
		
		B747DR_fltInst_fo_clock_CHR_switch_pos = 1
		
		-- START
		if B747_chrono_mode_fo == 0 then
			sim_ch_old_time_fo = simDR_time_now
			sim_ch_new_time_fo = sim_et_old_time_fo + 0.001
			B747DR_fltInst_fo_clock_ET_CHR_display = 1
			B747_chrono_mode_fo = 1
			
		-- STOP
		elseif B747_chrono_mode_fo == 1 then
			B747DR_fltInst_fo_clock_ET_CHR_display = 1
			B747_chrono_mode_fo = 2
				
		-- RESET	
		elseif B747_chrono_mode_fo == 2 then
			B747_fltInst_fo_chrono_timer_reset()
			B747DR_fltInst_fo_clock_ET_CHR_display = 0
			B747_chrono_mode_fo = 0	
		end	
		
	elseif phase == 2 then
		
		B747DR_fltInst_fo_clock_CHR_switch_pos = 0
							
	end				
end



function B747_fo_set_date_display()
	B747DR_fltInst_fo_clock_DATE_display_mode = 1 - B747DR_fltInst_fo_clock_DATE_display_mode		
end	
function B747_fo_clock_date_switch_CMDhandler(phase, duration) 
	if phase == 0 then
		
		B747DR_fltInst_fo_clock_DATE_switch_pos = 1
		
		B747DR_fltInst_fo_clock_UTC_display = 1 - B747DR_fltInst_fo_clock_UTC_display
		if B747DR_fltInst_fo_clock_UTC_display == 0 then
			if is_timer_scheduled(B747_fo_set_date_display) == true then
				stop_timer(B747_fo_set_date_display)
			end				
		elseif B747DR_fltInst_fo_clock_UTC_display == 1 then
			if is_timer_scheduled(B747_fo_set_date_display) == false then 
				B747DR_fltInst_fo_clock_DATE_display_mode = 1
				run_at_interval(B747_fo_set_date_display, 1.0)
			end			
		end
		
	elseif phase == 2 then
	
		B747DR_fltInst_fo_clock_DATE_switch_pos = 0
			
	end				
end




function B747_fo_clock_ET_sel_up_CMDhandler(phase, duration) 
	if phase == 0 then
		B747DR_fltInst_fo_clock_ET_sel_pos = math.min(2, B747DR_fltInst_fo_clock_ET_sel_pos + 1)
		if B747DR_fltInst_fo_clock_ET_CHR_display == 0 then
			if B747DR_fltInst_fo_clock_ET_sel_pos == 1 then		
				sim_et_old_time_fo = simDR_time_now
				sim_et_new_time_fo = sim_et_old_time_fo + 0.001
			elseif B747DR_fltInst_fo_clock_ET_sel_pos == 2 then
				B747_fltInst_fo_elapsed_timer_reset()		
			end	
		end
	elseif phase == 2 then	
		if B747DR_fltInst_fo_clock_ET_sel_pos == 2 then B747DR_fltInst_fo_clock_ET_sel_pos = 0 end						
	end			
end
function B747_fo_clock_ET_sel_dn_CMDhandler(phase, duration) 
	if phase == 0 then
		B747DR_fltInst_fo_clock_ET_sel_pos = math.max(0, B747DR_fltInst_fo_clock_ET_sel_pos - 1)			
	end			
end






function B747_fo_clock_SET_sel_up_CMDhandler(phase, duration) 
	if phase == 0 then
		B747DR_fltInst_fo_clock_SET_sel_pos = math.min(3, B747DR_fltInst_fo_clock_SET_sel_pos + 1)	
	end				
end
function B747_fo_clock_SET_sel_dn_CMDhandler(phase, duration) 
	if phase == 0 then
		B747DR_fltInst_fo_clock_SET_sel_pos = math.max(0, B747DR_fltInst_fo_clock_SET_sel_pos - 1)
	end				
end




--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_fltInst_fo_clock_chrono_switch	= deferred_command("laminar/B747/fltInst/fo/clock_chrono_switch", "First Officer Clock Chronograph Switch", B747_fo_clock_chrono_switch_CMDhandler)
B747CMD_fltInst_fo_clock_date_switch	= deferred_command("laminar/B747/fltInst/fo/clock_date_switch", "First Officer Clock Date Switch", B747_fo_clock_date_switch_CMDhandler)
B747CMD_fltInst_fo_clock_ET_sel_up		= deferred_command("laminar/B747/fltInst/fo/clock_et_sel_up", "First Officer Clock ET Selector Up", B747_fo_clock_ET_sel_up_CMDhandler)
B747CMD_fltInst_fo_clock_ET_sel_dn		= deferred_command("laminar/B747/fltInst/fo/clock_et_sel_down", "First Officer Clock ET Selector Down", B747_fo_clock_ET_sel_dn_CMDhandler)
B747CMD_fltInst_fo_clock_SET_sel_up		= deferred_command("laminar/B747/fltInst/fo/clock_set_sel_up", "First Officer Clock SET Selector Up", B747_fo_clock_SET_sel_up_CMDhandler)
B747CMD_fltInst_fo_clock_SET_sel_dn		= deferred_command("laminar/B747/fltInst/fo/clock_set_sel_down", "First Officer Clock SET Selector Down", B747_fo_clock_SET_sel_dn_CMDhandler)




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				               CREATE SYSTEM OBJECTS            				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

function B747_fltInst_fo_get_clock_year()
	B747DR_fltInst_fo_clock_year = tonumber((string.sub(os.date("%Y"), -2, -1)))	
end	




function B747_fltInst_fo_elapsed_timer()
	
	local power = B747_rescale(0, 0, 5, 1.0, simDR_elec_bus_volts[0]) 
	
	if power > 0.5 then
	
		if B747DR_fltInst_fo_clock_ET_sel_pos == 1 then
			
			if B747DR_fltInst_fo_clock_ET_hours < 100 then
				
				B747DR_et_seconds_fo = B747DR_et_seconds_fo + ((simDR_time_now - sim_et_old_time_fo) / (sim_et_new_time_fo - sim_et_old_time_fo) * 0.001)
				B747DR_fltInst_fo_clock_ET_hours 		= math.modf(B747DR_et_seconds_fo / 3600)
				B747DR_fltInst_fo_clock_ET_minutes	= math.modf((B747DR_et_seconds_fo % 3600) / 60)
		
				sim_et_old_time_fo = simDR_time_now
				sim_et_new_time_fo = sim_et_old_time_fo + 0.001
				
			else
				
				B747DR_fltInst_fo_clock_ET_hours 		= 99
				B747DR_fltInst_fo_clock_ET_minutes	= 59		
				
			end		
			
		end	
		
	end		
	
end




function B747_fltInst_fo_elapsed_timer_reset()
		
	sim_et_old_time_fo 						= 0
	sim_et_new_time_fo 						= 0
	B747DR_et_seconds_fo 						= 0		
	B747DR_fltInst_fo_clock_ET_minutes 		= 0
	B747DR_fltInst_fo_clock_ET_hours 		= 0		
	
end	





function B747_fltInst_fo_chrono_timer()
	
	local power = B747_rescale(0, 0, 5, 1.0, simDR_elec_bus_volts[0]) 
	
	if power > 0.5 then	
	
		if B747_chrono_mode_fo == 1 then
			
			if B747DR_fltInst_fo_clock_CHR_minutes < 60 then
			
				B747_chrono_seconds_fo = B747_chrono_seconds_fo + ((simDR_time_now - sim_ch_old_time_fo) / (sim_ch_new_time_fo - sim_ch_old_time_fo) * 0.001)
				B747DR_fltInst_fo_clock_CHR_minutes 	= math.modf((B747_chrono_seconds_fo % 3600) / 60)
				B747DR_fltInst_fo_clock_CHR_seconds	= B747_chrono_seconds_fo % 60
		
				sim_ch_old_time_fo = simDR_time_now
				sim_ch_new_time_fo = sim_ch_old_time_fo + 0.001
				
			else
				
				B747DR_fltInst_fo_clock_CHR_minutes 	= 59
				B747DR_fltInst_fo_clock_CHR_seconds	= 99		
				
			end	
			
		end	
		
	end		
	
end	





function B747_fltInst_fo_chrono_timer_reset()
	
	B747_chrono_mode_fo 					= 0	
	sim_ch_old_time_fo 					= 0
	sim_ch_new_time_fo 					= 0
	B747_chrono_seconds_fo 				= 0		
	B747DR_fltInst_fo_clock_CHR_seconds 	= 0
	B747DR_fltInst_fo_clock_CHR_minutes 	= 0	
	
end	





--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

