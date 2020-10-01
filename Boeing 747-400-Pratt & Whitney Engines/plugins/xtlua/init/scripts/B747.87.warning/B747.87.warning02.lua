--[[
*****************************************************************************************
* Program Script Name	:	B747.87.warning
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
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED
*****************************************************************************************
--]]


--#####################################################################################--
--#                   EICAS MESSAGE FUNCTIONALITY & DESCRIPTION                       #--
--#####################################################################################--
--[[

IN ANY SCRIPT THE MESSAGE STATUS DATAREFS "B747DR_CAS_warning_status[X]", 'B747DR_CAS_caution_status[X]",
"B747DR_CAS_advisory_status[X]", OR "B747DR_CAS_memo_status[X]" SHOULD BE SET = 1 (ONE) OR 0 (ZERO),
WHICH INDICATES THAT THE EICAS MESSAGE SHOULD BE ACTIVATED OR DE-ACTIVATED.

THEN, THE SYSTEM AUTOMATICALLY COMPARES THE STATUS DATAREFS WITH THE APPROPRIATE MESSAGE
DATABASE TABLE AND DETERMINES IF THE MESSAGE HAS CHANGED.

IF THE MESSAGE HAS BEEN CHANGED IT IS ADDED OR REMOVED FROM THE DISPLAY "QUEUE" APPROPRIATELY.

FINALLY, THE DISPLAY QUEUE IS ITERATED AND THE DISPLAY PAGES ARE BUILT TO SET UP THE VALUES
FOR THE GENERIC TEXT INSTRUMENTS.

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

local NUM_ALERT_MESSAGES = 109


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
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--

local B747_CASwarning   = {}
local B747_CAScaution   = {}
local B747_CASadvisory  = {}
local B747_CASmemo      = {}



--*************************************************************************************--
--** 				                X-PLANE DATAREFS            			    	 **--
--*************************************************************************************--

simDR_startup_running               = find_dataref("sim/operation/prefs/startup_running")
simDR_all_wheels_on_ground          = find_dataref("sim/flightmodel/failures/onground_all")
simDR_ind_airspeed_kts_pilot        = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")




--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_airspeed_Vmc                 = find_dataref("laminar/B747/airspeed/Vmc")




--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_CAS_warning_status       = deferred_dataref("laminar/B747/CAS/warning_status", string.format("array[%s]", table.getn(B747_CASwarningMsg.values)))
B747DR_CAS_caution_status       = deferred_dataref("laminar/B747/CAS/caution_status", string.format("array[%s]", table.getn(B747_CAScautionMsg.values)))
B747DR_CAS_advisory_status      = deferred_dataref("laminar/B747/CAS/advisory_status", string.format("array[%s]", table.getn(B747_CASadvisoryMsg.values)))
B747DR_CAS_memo_status          = deferred_dataref("laminar/B747/CAS/memo_status", string.format("array[%s]", table.getn(B747_CASmemoMsg.values)))


B747DR_CAS_gen_warning_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_warning_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_warning_msg_%03d", i), "string")
end

B747DR_CAS_gen_caution_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_caution_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_caution_msg_%03d", i), "string")
end

B747DR_CAS_gen_advisory_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_advisory_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_advisory_msg_%03d", i), "string")
end

B747DR_CAS_gen_memo_msg = {}
for i = 0, NUM_ALERT_MESSAGES do
    B747DR_CAS_gen_memo_msg[i] = deferred_dataref(string.format("laminar/B747/CAS/gen_memo_msg_%03d", i), "string")
end


B747DR_CAS_recall_ind           = deferred_dataref("laminar/B747/CAS/recall_ind", "number")
B747DR_CAS_sec_eng_exceed_cue   = deferred_dataref("laminar/B747/CAS/sec_eng_exceed_cue", "number")
B747DR_CAS_status_cue           = deferred_dataref("laminar/B747/CAS/status_cue", "number")
B747DR_CAS_msg_page             = deferred_dataref("laminar/B747/CAS/msg_page", "number")
B747DR_CAS_num_msg_pages        = deferred_dataref("laminar/B747/CAS/num_msg_pages", "number")
B747DR_CAS_caut_adv_display     = deferred_dataref("laminar/B747/CAS/caut_adv_display", "number")


B747DR_master_warning           = find_dataref("laminar/B747/warning/master_warning")
B747DR_master_caution           = find_dataref("laminar/B747/warning/master_caution")

B747DR_init_warning_CD          = deferred_dataref("laminar/B747/warning/init_CD", "number")



-- AI
B747CMD_ai_warning_quick_start			= deferred_command("laminar/B747/ai/warning_quick_start", "number", B747_ai_warning_quick_start_CMDhandler)


--[[
function after_physics()
  B747DR_CAS_gen_warning_msg[0] = "help"
end]]



