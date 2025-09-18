--[[
*****************************************************************************************
* Program Script Name	:	B747.15.com
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


--*************************************************************************************--
--** 					              XLUA GLOBALS              				     **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]
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
local NUM_BTN_SW = 30
local NUM_TOGGLE_SW = 3
-- RADIO TUNING PANEL LEFT
B747DR_rtp_L_offside_tuning_status  = deferred_dataref("laminar/B747/comm/rtp_L/offside_tuning_status", "number")
B747DR_rtp_L_off_status             = deferred_dataref("laminar/B747/comm/rtp_L/off_status", "number")
B747DR_rtp_L_vhf_L_status           = deferred_dataref("laminar/B747/comm/rtp_L/vhf_L_status", "number")
B747DR_rtp_L_vhf_C_status           = deferred_dataref("laminar/B747/comm/rtp_L/vhf_C_status", "number")
B747DR_rtp_L_vhf_R_status           = deferred_dataref("laminar/B747/comm/rtp_L/vhf_R_status", "number")
B747DR_rtp_L_hf_L_status            = deferred_dataref("laminar/B747/comm/rtp_L/hf_L_status", "number")
B747DR_rtp_L_am_status              = deferred_dataref("laminar/B747/comm/rtp_L/am_status", "number")
B747DR_rtp_L_hf_R_status            = deferred_dataref("laminar/B747/comm/rtp_L/hf_R_status", "number")
B747DR_rtp_L_freq_MHz_sel_dial_pos  = deferred_dataref("laminar/B747/comm/rtp_L/freq_MHz/sel_dial_pos", "number")
B747DR_rtp_L_freq_khz_sel_dial_pos  = deferred_dataref("laminar/B747/comm/rtp_L/freq_khz/sel_dial_pos", "number")
B747DR_rtp_L_lcd_to_display         = deferred_dataref("laminar/B747/comm/rtp_L/lcd_to_display", "number")


-- RADIO TUNING PANEL CENTER
B747DR_rtp_C_offside_tuning_status  = deferred_dataref("laminar/B747/comm/rtp_C/offside_tuning_status", "number")
B747DR_rtp_C_off_status             = deferred_dataref("laminar/B747/comm/rtp_C/off_status", "number")
B747DR_rtp_C_vhf_L_status           = deferred_dataref("laminar/B747/comm/rtp_C/vhf_L_status", "number")
B747DR_rtp_C_vhf_C_status           = deferred_dataref("laminar/B747/comm/rtp_C/vhf_C_status", "number")
B747DR_rtp_C_vhf_R_status           = deferred_dataref("laminar/B747/comm/rtp_C/vhf_R_status", "number")
B747DR_rtp_C_hf_L_status            = deferred_dataref("laminar/B747/comm/rtp_C/hf_L_status", "number")
B747DR_rtp_C_am_status              = deferred_dataref("laminar/B747/comm/rtp_C/am_status", "number")
B747DR_rtp_C_hf_R_status            = deferred_dataref("laminar/B747/comm/rtp_C/hf_R_status", "number")
B747DR_rtp_C_freq_MHz_sel_dial_pos  = deferred_dataref("laminar/B747/comm/rtp_C/freq_MHz/sel_dial_pos", "number")
B747DR_rtp_C_freq_khz_sel_dial_pos  = deferred_dataref("laminar/B747/comm/rtp_C/freq_khz/sel_dial_pos", "number")
B747DR_rtp_C_lcd_to_display         = deferred_dataref("laminar/B747/comm/rtp_C/lcd_to_display", "number")


-- RADIO TUNING PANEL RIGHT
B747DR_rtp_R_offside_tuning_status  = deferred_dataref("laminar/B747/comm/rtp_R/offside_tuning_status", "number")
B747DR_rtp_R_off_status             = deferred_dataref("laminar/B747/comm/rtp_R/off_status", "number")
B747DR_rtp_R_vhf_L_status           = deferred_dataref("laminar/B747/comm/rtp_R/vhf_L_status", "number")
B747DR_rtp_R_vhf_C_status           = deferred_dataref("laminar/B747/comm/rtp_R/vhf_C_status", "number")
B747DR_rtp_R_vhf_R_status           = deferred_dataref("laminar/B747/comm/rtp_R/vhf_R_status", "number")
B747DR_rtp_R_hf_L_status            = deferred_dataref("laminar/B747/comm/rtp_R/hf_L_status", "number")
B747DR_rtp_R_am_status              = deferred_dataref("laminar/B747/comm/rtp_R/am_status", "number")
B747DR_rtp_R_hf_R_status            = deferred_dataref("laminar/B747/comm/rtp_R/hf_R_status", "number")
B747DR_rtp_R_freq_MHz_sel_dial_pos  = deferred_dataref("laminar/B747/comm/rtp_R/freq_MHz/sel_dial_pos", "number")
B747DR_rtp_R_freq_khz_sel_dial_pos  = deferred_dataref("laminar/B747/comm/rtp_R/freq_khz/sel_dial_pos", "number")
B747DR_rtp_R_lcd_to_display         = deferred_dataref("laminar/B747/comm/rtp_R/lcd_to_display", "number")


-- AUDIO PANEL SWITCHES
B747DR_ap_button_switch_position    = deferred_dataref("laminar/B747/ap/button_sw_pos", "array[" .. tostring(NUM_BTN_SW) .. "]")
B747DR_ap_toggle_switch_pos         = deferred_dataref("laminar/B747/ap/toggle_sw_pos", "array[" .. tostring(NUM_TOGGLE_SW) .. "]")


-- AUDIO PANEL LEFT
B747DR_ap_L_vhf_L_xmt_status       = deferred_dataref("laminar/B747/ap_L/vhf_L/xmt_status", "number")
B747DR_ap_L_vhf_C_xmt_status       = deferred_dataref("laminar/B747/ap_L/vhf_C/xmt_status", "number")
B747DR_ap_L_vhf_R_xmt_status       = deferred_dataref("laminar/B747/ap_L/vhf_R/xmt_status", "number")
B747DR_ap_L_flt_xmt_status         = deferred_dataref("laminar/B747/ap_L/flt/xmt_status", "number")
B747DR_ap_L_cab_xmt_status         = deferred_dataref("laminar/B747/ap_L/cab/xmt_status", "number")
B747DR_ap_L_pa_xmt_status          = deferred_dataref("laminar/B747/ap_L/pa/xmt_status", "number")
B747DR_ap_L_hf_L_xmt_status        = deferred_dataref("laminar/B747/ap_L/hf_L/xmt_status", "number")
B747DR_ap_L_hf_R_xmt_status        = deferred_dataref("laminar/B747/ap_L/hf_R/xmt_status", "number")
B747DR_ap_L_sat_L_xmt_status       = deferred_dataref("laminar/B747/ap_L/sat_L/xmt_status", "number")
B747DR_ap_L_sat_R_xmt_status       = deferred_dataref("laminar/B747/ap_L/sat_R/xmt_status", "number")

B747DR_ap_L_vhf_L_call_status      = deferred_dataref("laminar/B747/ap_L/vhf_L/call_status", "number")
B747DR_ap_L_vhf_C_call_status      = deferred_dataref("laminar/B747/ap_L/vhf_C/call_status", "number")
B747DR_ap_L_vhf_R_call_status      = deferred_dataref("laminar/B747/ap_L/vhf_R/call_status", "number")
B747DR_ap_L_flt_call_status        = deferred_dataref("laminar/B747/ap_L/flt/call_status", "number")
B747DR_ap_L_cab_call_status        = deferred_dataref("laminar/B747/ap_L/cab/call_status", "number")
B747DR_ap_L_pa_call_status         = deferred_dataref("laminar/B747/ap_L/pa/call_status", "number")
B747DR_ap_L_hf_L_call_status       = deferred_dataref("laminar/B747/ap_L/hf_L/call_status", "number")
B747DR_ap_L_hf_R_call_status       = deferred_dataref("laminar/B747/ap_L/hf_R/call_status", "number")
B747DR_ap_L_sat_L_call_status      = deferred_dataref("laminar/B747/ap_L/sat_L/call_status", "number")
B747DR_ap_L_sat_R_call_status      = deferred_dataref("laminar/B747/ap_L/sat_R/call_status", "number")

B747DR_ap_L_vhf_L_audio_status     = deferred_dataref("laminar/B747/ap_L/vhf_L/audio_status", "number")
B747DR_ap_L_vhf_C_audio_status     = deferred_dataref("laminar/B747/ap_L/vhf_C/audio_status", "number")
B747DR_ap_L_vhf_R_audio_status     = deferred_dataref("laminar/B747/ap_L/vhf_R/audio_status", "number")
B747DR_ap_L_flt_audio_status       = deferred_dataref("laminar/B747/ap_L/flt/audio_status", "number")
B747DR_ap_L_cab_audio_status       = deferred_dataref("laminar/B747/ap_L/cab/audio_status", "number")
B747DR_ap_L_pa_audio_status        = deferred_dataref("laminar/B747/ap_L/pa/audio_status", "number")
B747DR_ap_L_hf_L_audio_status      = deferred_dataref("laminar/B747/ap_L/hf_L/audio_status", "number")
B747DR_ap_L_hf_R_audio_status      = deferred_dataref("laminar/B747/ap_L/hf_R/audio_status", "number")
B747DR_ap_L_sat_L_audio_status     = deferred_dataref("laminar/B747/ap_L/sat_L/audio_status", "number")
B747DR_ap_L_sat_R_udio_status      = deferred_dataref("laminar/B747/ap_L/sat_R/audio_status", "number")
B747DR_ap_L_spkr_audio_status      = deferred_dataref("laminar/B747/ap_L/spkr/audio_status", "number")
B747DR_ap_L_vor_adf_audio_status   = deferred_dataref("laminar/B747/ap_L/vor_adf/audio_status", "number")
B747DR_ap_L_app_mkr_audio_status   = deferred_dataref("laminar/B747/ap_L/app_mkr/audio_status", "number")

B747DR_ap_L_vor_adf_rcvr_sel_dial_pos = deferred_dataref("laminar/B747/ap_L/vor_adf_rcvr/sel_dial_pos", "number")
B747DR_ap_L_nav_filter_sel_dial_pos = deferred_dataref("laminar/B747/ap_L/nav_filter/sel_dial_pos", "number")
B747DR_ap_L_app_rcvr_sel_dial_pos  = deferred_dataref("laminar/B747/ap_L/app_rcvr/sel_dial_pos", "number")

B747DR_ap_L_vhf_L_audio_vol      = deferred_dataref("laminar/B747/ap_L/vhf_L/audio_vol", "number")
B747DR_ap_L_vhf_R_audio_vol      = deferred_dataref("laminar/B747/ap_L/vhf_R/audio_vol", "number")
B747DR_ap_L_vhf_C_audio_vol      = deferred_dataref("laminar/B747/ap_L/vhf_C/audio_vol", "number")
B747DR_ap_L_flt_audio_vol        = deferred_dataref("laminar/B747/ap_L/flt/audio_vol", "number")
B747DR_ap_L_cab_audio_vol        = deferred_dataref("laminar/B747/ap_L/cab/audio_vol", "number")
B747DR_ap_L_pa_audio_vol         = deferred_dataref("laminar/B747/ap_L/pa/audio_vol", "number")
B747DR_ap_L_hf_L_audio_vol       = deferred_dataref("laminar/B747/ap_L/hf_L/audio_vol", "number")
B747DR_ap_L_hf_R_audio_vol       = deferred_dataref("laminar/B747/ap_L/hf_R/audio_vol", "number")
B747DR_ap_L_sat_L_audio_vol      = deferred_dataref("laminar/B747/ap_L/sat_L/audio_vol", "number")
B747DR_ap_L_sat_R_audio_vol      = deferred_dataref("laminar/B747/ap_L/sat_R/audio_vol", "number")
B747DR_ap_L_spkr_audio_vol       = deferred_dataref("laminar/B747/ap_L/spkr/audio_vol", "number")
B747DR_ap_L_vor_adf_audio_vol    = deferred_dataref("laminar/B747/ap_L/vor_adf/audio_vol", "number")
B747DR_ap_L_app_mkr_audio_vol    = deferred_dataref("laminar/B747/ap_L/app_mkr/audio_vol", "number")



-- AUDIO PANEL CENTER
B747DR_ap_C_vhf_L_xmt_status       = deferred_dataref("laminar/B747/ap_C/vhf_L/xmt_status", "number")
B747DR_ap_C_vhf_C_xmt_status       = deferred_dataref("laminar/B747/ap_C/vhf_C/xmt_status", "number")
B747DR_ap_C_vhf_R_xmt_status       = deferred_dataref("laminar/B747/ap_C/vhf_R/xmt_status", "number")
B747DR_ap_C_flt_xmt_status         = deferred_dataref("laminar/B747/ap_C/flt/xmt_status", "number")
B747DR_ap_C_cab_xmt_status         = deferred_dataref("laminar/B747/ap_C/cab/xmt_status", "number")
B747DR_ap_C_pa_xmt_status          = deferred_dataref("laminar/B747/ap_C/pa/xmt_status", "number")
B747DR_ap_C_hf_L_xmt_status        = deferred_dataref("laminar/B747/ap_C/hf_L/xmt_status", "number")
B747DR_ap_C_hf_R_xmt_status        = deferred_dataref("laminar/B747/ap_C/hf_R/xmt_status", "number")
B747DR_ap_C_sat_L_xmt_status       = deferred_dataref("laminar/B747/ap_C/sat_L/xmt_status", "number")
B747DR_ap_C_sat_R_xmt_status       = deferred_dataref("laminar/B747/ap_C/sat_R/xmt_status", "number")

B747DR_ap_C_vhf_L_call_status      = deferred_dataref("laminar/B747/ap_C/vhf_L/call_status", "number")
B747DR_ap_C_vhf_C_call_status      = deferred_dataref("laminar/B747/ap_C/vhf_C/call_status", "number")
B747DR_ap_C_vhf_R_call_status      = deferred_dataref("laminar/B747/ap_C/vhf_R/call_status", "number")
B747DR_ap_C_flt_call_status        = deferred_dataref("laminar/B747/ap_C/flt/call_status", "number")
B747DR_ap_C_cab_call_status        = deferred_dataref("laminar/B747/ap_C/cab/call_status", "number")
B747DR_ap_C_pa_call_status         = deferred_dataref("laminar/B747/ap_C/pa/call_status", "number")
B747DR_ap_C_hf_L_call_status       = deferred_dataref("laminar/B747/ap_C/hf_L/call_status", "number")
B747DR_ap_C_hf_R_call_status       = deferred_dataref("laminar/B747/ap_C/hf_R/call_status", "number")
B747DR_ap_C_sat_L_call_status      = deferred_dataref("laminar/B747/ap_C/sat_L/call_status", "number")
B747DR_ap_C_sat_R_call_status      = deferred_dataref("laminar/B747/ap_C/sat_R/call_status", "number")

B747DR_ap_C_vhf_L_audio_status     = deferred_dataref("laminar/B747/ap_C/vhf_L/audio_status", "number")
B747DR_ap_C_vhf_C_audio_status     = deferred_dataref("laminar/B747/ap_C/vhf_C/audio_status", "number")
B747DR_ap_C_vhf_R_audio_status     = deferred_dataref("laminar/B747/ap_C/vhf_R/audio_status", "number")
B747DR_ap_C_flt_audio_status       = deferred_dataref("laminar/B747/ap_C/flt/audio_status", "number")
B747DR_ap_C_cab_audio_status       = deferred_dataref("laminar/B747/ap_C/cab/audio_status", "number")
B747DR_ap_C_pa_audio_status        = deferred_dataref("laminar/B747/ap_C/pa/audio_status", "number")
B747DR_ap_C_hf_L_audio_status      = deferred_dataref("laminar/B747/ap_C/hf_L/audio_status", "number")
B747DR_ap_C_hf_R_audio_status      = deferred_dataref("laminar/B747/ap_C/hf_R/audio_status", "number")
B747DR_ap_C_sat_L_audio_status     = deferred_dataref("laminar/B747/ap_C/sat_L/audio_status", "number")
B747DR_ap_C_sat_R_udio_status      = deferred_dataref("laminar/B747/ap_C/sat_R/audio_status", "number")
B747DR_ap_C_spkr_audio_status      = deferred_dataref("laminar/B747/ap_C/spkr/audio_status", "number")
B747DR_ap_C_vor_adf_audio_status   = deferred_dataref("laminar/B747/ap_C/vor_adf/audio_status", "number")
B747DR_ap_C_app_mkr_audio_status   = deferred_dataref("laminar/B747/ap_C/app_mkr/audio_status", "number")

B747DR_ap_C_vor_adf_rcvr_sel_dial_pos = deferred_dataref("laminar/B747/ap_C/vor_adf_rcvr/sel_dial_pos", "number")
B747DR_ap_C_nav_filter_sel_dial_pos = deferred_dataref("laminar/B747/ap_C/nav_filter/sel_dial_pos", "number")
B747DR_ap_C_app_rcvr_sel_dial_pos  = deferred_dataref("laminar/B747/ap_C/app_rcvr/sel_dial_pos", "number")

B747DR_ap_C_vhf_L_audio_vol      = deferred_dataref("laminar/B747/ap_C/vhf_L/audio_vol", "number")
B747DR_ap_C_vhf_R_audio_vol      = deferred_dataref("laminar/B747/ap_C/vhf_R/audio_vol", "number")
B747DR_ap_C_vhf_C_audio_vol      = deferred_dataref("laminar/B747/ap_C/vhf_C/audio_vol", "number")
B747DR_ap_C_flt_audio_vol        = deferred_dataref("laminar/B747/ap_C/flt/audio_vol", "number")
B747DR_ap_C_cab_audio_vol        = deferred_dataref("laminar/B747/ap_C/cab/audio_vol", "number")
B747DR_ap_C_pa_audio_vol         = deferred_dataref("laminar/B747/ap_C/pa/audio_vol", "number")
B747DR_ap_C_hf_L_audio_vol       = deferred_dataref("laminar/B747/ap_C/hf_L/audio_vol", "number")
B747DR_ap_C_hf_R_audio_vol       = deferred_dataref("laminar/B747/ap_C/hf_R/audio_vol", "number")
B747DR_ap_C_sat_L_audio_vol      = deferred_dataref("laminar/B747/ap_C/sat_L/audio_vol", "number")
B747DR_ap_C_sat_R_audio_vol      = deferred_dataref("laminar/B747/ap_C/sat_R/audio_vol", "number")
B747DR_ap_C_spkr_audio_vol       = deferred_dataref("laminar/B747/ap_C/spkr/audio_vol", "number")
B747DR_ap_C_vor_adf_audio_vol    = deferred_dataref("laminar/B747/ap_C/vor_adf/audio_vol", "number")
B747DR_ap_C_app_mkr_audio_vol    = deferred_dataref("laminar/B747/ap_C/app_mkr/audio_vol", "number")



-- AUDIO PANEL RIGHT
B747DR_ap_R_vhf_L_xmt_status       = deferred_dataref("laminar/B747/ap_R/vhf_L/xmt_status", "number")
B747DR_ap_R_vhf_C_xmt_status       = deferred_dataref("laminar/B747/ap_R/vhf_C/xmt_status", "number")
B747DR_ap_R_vhf_R_xmt_status       = deferred_dataref("laminar/B747/ap_R/vhf_R/xmt_status", "number")
B747DR_ap_R_flt_xmt_status         = deferred_dataref("laminar/B747/ap_R/flt/xmt_status", "number")
B747DR_ap_R_cab_xmt_status         = deferred_dataref("laminar/B747/ap_R/cab/xmt_status", "number")
B747DR_ap_R_pa_xmt_status          = deferred_dataref("laminar/B747/ap_R/pa/xmt_status", "number")
B747DR_ap_R_hf_L_xmt_status        = deferred_dataref("laminar/B747/ap_R/hf_L/xmt_status", "number")
B747DR_ap_R_hf_R_xmt_status        = deferred_dataref("laminar/B747/ap_R/hf_R/xmt_status", "number")
B747DR_ap_R_sat_L_xmt_status       = deferred_dataref("laminar/B747/ap_R/sat_L/xmt_status", "number")
B747DR_ap_R_sat_R_xmt_status       = deferred_dataref("laminar/B747/ap_R/sat_R/xmt_status", "number")

B747DR_ap_R_vhf_L_call_status      = deferred_dataref("laminar/B747/ap_R/vhf_L/call_status", "number")
B747DR_ap_R_vhf_C_call_status      = deferred_dataref("laminar/B747/ap_R/vhf_C/call_status", "number")
B747DR_ap_R_vhf_R_call_status      = deferred_dataref("laminar/B747/ap_R/vhf_R/call_status", "number")
B747DR_ap_R_flt_call_status        = deferred_dataref("laminar/B747/ap_R/flt/call_status", "number")
B747DR_ap_R_cab_call_status        = deferred_dataref("laminar/B747/ap_R/cab/call_status", "number")
B747DR_ap_R_pa_call_status         = deferred_dataref("laminar/B747/ap_R/pa/call_status", "number")
B747DR_ap_R_hf_L_call_status       = deferred_dataref("laminar/B747/ap_R/hf_L/call_status", "number")
B747DR_ap_R_hf_R_call_status       = deferred_dataref("laminar/B747/ap_R/hf_R/call_status", "number")
B747DR_ap_R_sat_L_call_status      = deferred_dataref("laminar/B747/ap_R/sat_L/call_status", "number")
B747DR_ap_R_sat_R_call_status      = deferred_dataref("laminar/B747/ap_R/sat_R/call_status", "number")

B747DR_ap_R_vhf_L_audio_status     = deferred_dataref("laminar/B747/ap_R/vhf_L/audio_status", "number")
B747DR_ap_R_vhf_C_audio_status     = deferred_dataref("laminar/B747/ap_R/vhf_C/audio_status", "number")
B747DR_ap_R_vhf_R_audio_status     = deferred_dataref("laminar/B747/ap_R/vhf_R/audio_status", "number")
B747DR_ap_R_flt_audio_status       = deferred_dataref("laminar/B747/ap_R/flt/audio_status", "number")
B747DR_ap_R_cab_audio_status       = deferred_dataref("laminar/B747/ap_R/cab/audio_status", "number")
B747DR_ap_R_pa_audio_status        = deferred_dataref("laminar/B747/ap_R/pa/audio_status", "number")
B747DR_ap_R_hf_L_audio_status      = deferred_dataref("laminar/B747/ap_R/hf_L/audio_status", "number")
B747DR_ap_R_hf_R_audio_status      = deferred_dataref("laminar/B747/ap_R/hf_R/audio_status", "number")
B747DR_ap_R_sat_L_audio_status     = deferred_dataref("laminar/B747/ap_R/sat_L/audio_status", "number")
B747DR_ap_R_sat_R_udio_status      = deferred_dataref("laminar/B747/ap_R/sat_R/audio_status", "number")
B747DR_ap_R_spkr_audio_status      = deferred_dataref("laminar/B747/ap_R/spkr/audio_status", "number")
B747DR_ap_R_vor_adf_audio_status   = deferred_dataref("laminar/B747/ap_R/vor_adf/audio_status", "number")
B747DR_ap_R_app_mkr_audio_status   = deferred_dataref("laminar/B747/ap_R/app_mkr/audio_status", "number")

B747DR_ap_R_vor_adf_rcvr_sel_dial_pos = deferred_dataref("laminar/B747/ap_R/vor_adf_rcvr/sel_dial_pos", "number")
B747DR_ap_R_nav_filter_sel_dial_pos = deferred_dataref("laminar/B747/ap_R/nav_filter/sel_dial_pos", "number")
B747DR_ap_R_app_rcvr_sel_dial_pos  = deferred_dataref("laminar/B747/ap_R/app_rcvr/sel_dial_pos", "number")

B747DR_ap_R_vhf_L_audio_vol      = deferred_dataref("laminar/B747/ap_R/vhf_L/audio_vol", "number")
B747DR_ap_R_vhf_R_audio_vol      = deferred_dataref("laminar/B747/ap_R/vhf_R/audio_vol", "number")
B747DR_ap_R_vhf_C_audio_vol      = deferred_dataref("laminar/B747/ap_R/vhf_C/audio_vol", "number")
B747DR_ap_R_flt_audio_vol        = deferred_dataref("laminar/B747/ap_R/flt/audio_vol", "number")
B747DR_ap_R_cab_audio_vol        = deferred_dataref("laminar/B747/ap_R/cab/audio_vol", "number")
B747DR_ap_R_pa_audio_vol         = deferred_dataref("laminar/B747/ap_R/pa/audio_vol", "number")
B747DR_ap_R_hf_L_audio_vol       = deferred_dataref("laminar/B747/ap_R/hf_L/audio_vol", "number")
B747DR_ap_R_hf_R_audio_vol       = deferred_dataref("laminar/B747/ap_R/hf_R/audio_vol", "number")
B747DR_ap_R_sat_L_audio_vol      = deferred_dataref("laminar/B747/ap_R/sat_L/audio_vol", "number")
B747DR_ap_R_sat_R_audio_vol      = deferred_dataref("laminar/B747/ap_R/sat_R/audio_vol", "number")
B747DR_ap_R_spkr_audio_vol       = deferred_dataref("laminar/B747/ap_R/spkr/audio_vol", "number")
B747DR_ap_R_vor_adf_audio_vol    = deferred_dataref("laminar/B747/ap_R/vor_adf/audio_vol", "number")
B747DR_ap_R_app_mkr_audio_vol    = deferred_dataref("laminar/B747/ap_R/app_mkr/audio_vol", "number")



-- CALL PANEL
B747DR_call_pnl_ud_call_status     = deferred_dataref("laminar/B747/call_pnl/ud/call_status", "number")
B747DR_call_pnl_crw_rst_L_call_status = deferred_dataref("laminar/B747/call_pnl/crw_rst_L/call_status", "number")
B747DR_call_pnl_crw_rst_R_call_status = deferred_dataref("laminar/B747/call_pnl/crw_rst_R/call_status", "number")
B747DR_call_pnl_cargo_call_status  = deferred_dataref("laminar/B747/call_pnl/cargo/call_status", "number")
B747DR_call_pnl_grnd_call_status   = deferred_dataref("laminar/B747/call_pnl/grnd/call_status", "number")



B747DR_init_com_CD               = deferred_dataref("laminar/B747/com/init_CD", "number")



--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--

-- RADIO TUNING PANEL LEFT
B747DR_rtp_L_hf_sens_ctrl_rheo      = deferred_dataref("laminar/B747/comm/rtp_L/hf_sens_ctrl/rheostat", "number")


-- RADIO TUNING PANEL CENTER
B747DR_rtp_C_hf_sens_ctrl_rheo      = deferred_dataref("laminar/B747/comm/rtp_C/hf_sens_ctrl/rheostat", "number")


-- RADIO TUNING PANEL RIGHT
B747DR_rtp_R_hf_sens_ctrl_rheo      = deferred_dataref("laminar/B747/comm/rtp_R/hf_sens_ctrl/rheostat", "number")



--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--

-- RADIO TUNING PANEL LEFT
B747CMD_rtp_L_off_switch            = deferred_command("laminar/B747/rtp_L/off_switch", "Radio Tuning Panel Left OFF Switch", B747_rtp_L_off_switch_CMDhandler)
B747CMD_rtp_L_vhf_L_sel_switch      = deferred_command("laminar/B747/rtp_L/vhf_L/sel_switch", "Radio Tuning Panel Left VHF L Sel Switch", B747_rtp_L_vhf_L_sel_switch_CMDhandler)
B747CMD_rtp_L_vhf_C_sel_switch      = deferred_command("laminar/B747/rtp_L/vhf_C/sel_switch", "Radio Tuning Panel Left VHF C Sel Switch", B747_rtp_L_vhf_C_sel_switch_CMDhandler)
B747CMD_rtp_L_vhf_R_sel_switch      = deferred_command("laminar/B747/rtp_L/vhf_R/sel_switch", "Radio Tuning Panel Left VHF R Sel Switch", B747_rtp_L_vhf_R_sel_switch_CMDhandler)
B747CMD_rtp_L_hf_L_sel_switch       = deferred_command("laminar/B747/rtp_L/hf_L/sel_switch", "Radio Tuning Panel Left HF L SelSwitch", B747_rtp_L_hf_L_sel_switch_CMDhandler)
B747CMD_rtp_L_am_sel_switch         = deferred_command("laminar/B747/rtp_L/am/sel_switch", "Radio Tuning Panel Left AM Sel Switch", B747_rtp_L_am_sel_switch_CMDhandler)
B747CMD_rtp_L_hf_R_sel_switch       = deferred_command("laminar/B747/rtp_L/hf_R/sel_switch", "Radio Tuning Panel Left HF R Sel Switch", B747_rtp_L_hf_R_sel_switch_CMDhandler)
B747CMD_rtp_L_freq_txfr_switch      = deferred_command("laminar/B747/rtp_L/freq_txfr/sel_switch", "Radio Tuning Panel Left Freq Txfr Switch", B747_rtp_L_freq_txfr_switch_CMDhandler)

B747CMD_rtp_L_freq_MHz_sel_dial_up  = deferred_command("laminar/B747/rtp_L/freq_MHz/sel_dial_up", "Radio Tuning Panel Left Freq MHz Sel Up", B747_rtp_L_freq_MHz_sel_dial_up_CMDhandler)
B747CMD_rtp_L_freq_MHz_sel_dial_dn  = deferred_command("laminar/B747/rtp_L/freq_MHz/sel_dial_dn", "Radio Tuning Panel Left Freq MHz Sel Down", B747_rtp_L_freq_MHz_sel_dial_dn_CMDhandler)

B747CMD_rtp_L_freq_khz_sel_dial_up  = deferred_command("laminar/B747/rtp_L/freq_khz/sel_dial_up", "Radio Tuning Panel Left Freq khz Sel Up", B747_rtp_L_freq_khz_sel_dial_up_CMDhandler)
B747CMD_rtp_L_freq_khz_sel_dial_dn  = deferred_command("laminar/B747/rtp_L/freq_khz/sel_dial_dn", "Radio Tuning Panel Left Freq khz Sel Down", B747_rtp_L_freq_khz_sel_dial_dn_CMDhandler)



-- RADIO TUNING PANEL CENTER
B747CMD_rtp_C_off_switch            = deferred_command("laminar/B747/rtp_C/off_switch", "Radio Tuning Panel Center OFF Switch", B747_rtp_C_off_switch_CMDhandler)
B747CMD_rtp_C_vhf_L_sel_switch      = deferred_command("laminar/B747/rtp_C/vhf_L/sel_switch", "Radio Tuning Panel Center VHF L Sel Switch", B747_rtp_C_vhf_L_sel_switch_CMDhandler)
B747CMD_rtp_C_vhf_C_sel_switch      = deferred_command("laminar/B747/rtp_C/vhf_C/sel_switch", "Radio Tuning Panel Center VHF C Sel Switch", B747_rtp_C_vhf_C_sel_switch_CMDhandler)
B747CMD_rtp_C_vhf_R_sel_switch      = deferred_command("laminar/B747/rtp_C/vhf_R/sel_switch", "Radio Tuning Panel Center VHF R Sel Switch", B747_rtp_C_vhf_R_sel_switch_CMDhandler)
B747CMD_rtp_C_hf_L_sel_switch       = deferred_command("laminar/B747/rtp_C/hf_L/sel_switch", "Radio Tuning Panel Center HF L SelSwitch", B747_rtp_C_hf_L_sel_switch_CMDhandler)
B747CMD_rtp_C_am_sel_switch         = deferred_command("laminar/B747/rtp_C/am/sel_switch", "Radio Tuning Panel Center AM Sel Switch", B747_rtp_C_am_sel_switch_CMDhandler)
B747CMD_rtp_C_hf_R_sel_switch       = deferred_command("laminar/B747/rtp_C/hf_R/sel_switch", "Radio Tuning Panel Center HF R Sel Switch", B747_rtp_C_hf_R_sel_switch_CMDhandler)
B747CMD_rtp_C_freq_txfr_switch      = deferred_command("laminar/B747/rtp_C/freq_txfr/sel_switch", "Radio Tuning Panel Center Freq Txfr Switch", B747_rtp_C_freq_txfr_switch_CMDhandler)

B747CMD_rtp_C_freq_MHz_sel_dial_up  = deferred_command("laminar/B747/rtp_C/freq_MHz/sel_dial_up", "Radio Tuning Panel Center Freq MHz Sel Up", B747_rtp_C_freq_MHz_sel_dial_up_CMDhandler)
B747CMD_rtp_C_freq_MHz_sel_dial_dn  = deferred_command("laminar/B747/rtp_C/freq_MHz/sel_dial_dn", "Radio Tuning Panel Center Freq MHz Sel Down", B747_rtp_C_freq_MHz_sel_dial_dn_CMDhandler)

B747CMD_rtp_C_freq_khz_sel_dial_up  = deferred_command("laminar/B747/rtp_C/freq_khz/sel_dial_up", "Radio Tuning Panel Center Freq khz Sel Up", B747_rtp_C_freq_khz_sel_dial_up_CMDhandler)
B747CMD_rtp_C_freq_khz_sel_dial_dn  = deferred_command("laminar/B747/rtp_C/freq_khz/sel_dial_dn", "Radio Tuning Panel Center Freq khz Sel Down", B747_rtp_C_freq_khz_sel_dial_dn_CMDhandler)



-- RADIO TUNING PANEL RIGHT
B747CMD_rtp_R_off_switch            = deferred_command("laminar/B747/rtp_R/off_switch", "Radio Tuning Panel Right OFF Switch", B747_rtp_R_off_switch_CMDhandler)
B747CMD_rtp_R_vhf_L_sel_switch      = deferred_command("laminar/B747/rtp_R/vhf_L/sel_switch", "Radio Tuning Panel Right VHF L Sel Switch", B747_rtp_R_vhf_L_sel_switch_CMDhandler)
B747CMD_rtp_R_vhf_C_sel_switch      = deferred_command("laminar/B747/rtp_R/vhf_C/sel_switch", "Radio Tuning Panel Right VHF C Sel Switch", B747_rtp_R_vhf_C_sel_switch_CMDhandler)
B747CMD_rtp_R_vhf_R_sel_switch      = deferred_command("laminar/B747/rtp_R/vhf_R/sel_switch", "Radio Tuning Panel Right VHF R Sel Switch", B747_rtp_R_vhf_R_sel_switch_CMDhandler)
B747CMD_rtp_R_hf_L_sel_switch       = deferred_command("laminar/B747/rtp_R/hf_L/sel_switch", "Radio Tuning Panel Right HF L SelSwitch", B747_rtp_R_hf_L_sel_switch_CMDhandler)
B747CMD_rtp_R_am_sel_switch         = deferred_command("laminar/B747/rtp_R/am/sel_switch", "Radio Tuning Panel Right AM Sel Switch", B747_rtp_R_am_sel_switch_CMDhandler)
B747CMD_rtp_R_hf_R_sel_switch       = deferred_command("laminar/B747/rtp_R/hf_R/sel_switch", "Radio Tuning Panel Right HF R Sel Switch", B747_rtp_R_hf_R_sel_switch_CMDhandler)
B747CMD_rtp_R_freq_txfr_switch      = deferred_command("laminar/B747/rtp_R/freq_txfr/sel_switch", "Radio Tuning Panel Right Freq Txfr Switch", B747_rtp_R_freq_txfr_switch_CMDhandler)

B747CMD_rtp_R_freq_MHz_sel_dial_up  = deferred_command("laminar/B747/rtp_R/freq_MHz/sel_dial_up", "Radio Tuning Panel Right Freq MHz Sel Up", B747_rtp_R_freq_MHz_sel_dial_up_CMDhandler)
B747CMD_rtp_R_freq_MHz_sel_dial_dn  = deferred_command("laminar/B747/rtp_R/freq_MHz/sel_dial_dn", "Radio Tuning Panel Right Freq MHz Sel Down", B747_rtp_R_freq_MHz_sel_dial_dn_CMDhandler)

B747CMD_rtp_R_freq_khz_sel_dial_up  = deferred_command("laminar/B747/rtp_R/freq_khz/sel_dial_up", "Radio Tuning Panel Right Freq khz Sel Up", B747_rtp_R_freq_khz_sel_dial_up_CMDhandler)
B747CMD_rtp_R_freq_khz_sel_dial_dn  = deferred_command("laminar/B747/rtp_R/freq_khz/sel_dial_dn", "Radio Tuning Panel Right Freq khz Sel Down", B747_rtp_R_freq_khz_sel_dial_dn_CMDhandler)



-- AUDIO PANEL LEFT
B747CMD_ap_L_vhf_L_xmt_sel_switch   = deferred_command("laminar/B747/ap_L/vhf_L/xmt_sel_switch", "Audio Panel Left VHF L Transmitter Selector Switch", B747_ap_L_vhf_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_vhf_C_xmt_sel_switch   = deferred_command("laminar/B747/ap_L/vhf_C/xmt_sel_switch", "Audio Panel Left VHF C Transmitter Selector Switch", B747_ap_L_vhf_C_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_vhf_R_xmt_sel_switch   = deferred_command("laminar/B747/ap_L/vhf_R/xmt_sel_switch", "Audio Panel Left VHF R Transmitter Selector Switch", B747_ap_L_vhf_R_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_flt_xmt_sel_switch     = deferred_command("laminar/B747/ap_L/flt/xmt_sel_switch", "Audio Panel Left FLT Transmitter Selector Switch", B747_ap_L_flt_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_cab_xmt_sel_switch     = deferred_command("laminar/B747/ap_L/cab/xmt_sel_switch", "Audio Panel Left CAB Transmitter Selector Switch", B747_ap_L_cab_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_pa_xmt_sel_switch      = deferred_command("laminar/B747/ap_L/pa/xmt_sel_switch", "Audio Panel Left PA Transmitter Selector Switch", B747_ap_L_pa_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_hf_L_xmt_sel_switch    = deferred_command("laminar/B747/ap_L/hf_L/xmt_sel_switch", "Audio Panel Left HF LTransmitter Selector Switch", B747_ap_L_hf_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_hf_R_xmt_sel_switch    = deferred_command("laminar/B747/ap_L/hf_R/xmt_sel_switch", "Audio Panel Left HF RTransmitter Selector Switch", B747_ap_L_hf_R_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_sat_L_xmt_sel_switch   = deferred_command("laminar/B747/ap_L/sat_L/xmt_sel_switch", "Audio Panel Left SAT L Transmitter Selector Switch", B747_ap_L_sat_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_L_sat_R_xmt_sel_switch   = deferred_command("laminar/B747/ap_L/sat_R/xmt_sel_switch", "Audio Panel Left SAT R Transmitter Selector Switch", B747_ap_L_sat_R_xmt_sel_switch_CMDhandler)

B747CMD_ap_L_vhf_L_audio_sel_switch = deferred_command("laminar/B747/ap_L/vhf_L/audio_sel_switch", "Audio Panel Left VHF L Audio Selector Switch", B747_ap_L_vhf_L_audio_sel_switch_CMDhandler)
B747CMD_ap_L_vhf_C_audio_sel_switch = deferred_command("laminar/B747/ap_L/vhf_C/audio_sel_switch", "Audio Panel Left VHF C Audio Selector Switch", B747_ap_L_vhf_C_audio_sel_switch_CMDhandler)
B747CMD_ap_L_vhf_R_audio_sel_switch = deferred_command("laminar/B747/ap_L/vhf_R/audio_sel_switch", "Audio Panel Left VHF R Audio Selector Switch", B747_ap_L_vhf_R_audio_sel_switch_CMDhandler)
B747CMD_ap_L_flt_audio_sel_switch   = deferred_command("laminar/B747/ap_L/flt/audio_sel_switch", "Audio Panel Left FLT Audio Selector Switch", B747_ap_L_flt_audio_sel_switch_CMDhandler)
B747CMD_ap_L_cab_audio_sel_switch   = deferred_command("laminar/B747/ap_L/cab/audio_sel_switch", "Audio Panel Left CAB Audio Selector Switch", B747_ap_L_cab_audio_sel_switch_CMDhandler)
B747CMD_ap_L_pa_audio_sel_switch    = deferred_command("laminar/B747/ap_L/pa/audio_sel_switch", "Audio Panel Left PA Audio Selector Switch", B747_ap_L_pa_audio_sel_switch_CMDhandler)
B747CMD_ap_L_hf_L_audio_sel_switch  = deferred_command("laminar/B747/ap_L/hf_L/audio_sel_switch", "Audio Panel Left HF Audio Selector Switch", B747_ap_L_hf_L_audio_sel_switch_CMDhandler)
B747CMD_ap_L_hf_R_audio_sel_switch  = deferred_command("laminar/B747/ap_L/hf_R/audio_sel_switch", "Audio Panel Left HF Audio Selector Switch", B747_ap_L_hf_R_audio_sel_switch_CMDhandler)
B747CMD_ap_L_sat_L_audio_sel_switch = deferred_command("laminar/B747/ap_L/sat_L/audio_sel_switch", "Audio Panel Left SAT L Audio Selector Switch", B747_ap_L_sat_L_audio_sel_switch_CMDhandler)
B747CMD_ap_L_sat_R_audio_sel_switch = deferred_command("laminar/B747/ap_L/sat_R/audio_sel_switch", "Audio Panel Left SAT R Audio Selector Switch", B747_ap_L_sat_R_audio_sel_switch_CMDhandler)
B747CMD_ap_L_spkr_audio_sel_switch  = deferred_command("laminar/B747/ap_L/spkr/audio_sel_switch", "Audio Panel Left Speaker Audio Selector Switch", B747_ap_L_spkr_audio_sel_switch_CMDhandler)
B747CMD_ap_L_vor_adf_audio_sel_switch = deferred_command("laminar/B747/ap_L/vor_adf/audio_sel_switch", "Audio Panel Left VOR/ADF Audio Selector Switch", B747_ap_L_vor_adf_audio_sel_switch_CMDhandler)
B747CMD_ap_L_app_mkr_audio_sel_switch = deferred_command("laminar/B747/ap_L/app_mkr/audio_sel_switch", "Audio Panel Left APP/MKR Audio Selector Switch", B747_ap_L_app_mkr_audio_sel_switch_CMDhandler)

B747CMD_ap_L_ptt_sel_switch_up      = deferred_command("laminar/B747/ap_L/ptt/sel_switch_up", "Audio Panel Left Push-To_Talk Selector Switch Up", B747_ap_L_ptt_sel_switch_up_CMDhandler)
B747CMD_ap_L_ptt_sel_switch_dn      = deferred_command("laminar/B747/ap_L/ptt/sel_switch_dn", "Audio Panel Left Push-To_Talk Selector Switch Down", B747_ap_L_ptt_sel_switch_dn_CMDhandler)

B747CMD_ap_L_vor_adf_rcvr_sel_dial_up = deferred_command("laminar/B747/ap_L/vor_adf_rcvr/sel_dial_up", "Audio Panel VOR/ADF Receiver Selector Dial Up", B747_ap_L_vor_adf_rcvr_sel_dial_up_CMDhandler)
B747CMD_ap_L_vor_adf_rcvr_sel_dial_dn = deferred_command("laminar/B747/ap_L/vor_adf_rcvr/sel_dial_dn", "Audio Panel VOR/ADF Receiver Selector Dial Down", B747_ap_L_vor_adf_rcvr_sel_dial_dn_CMDhandler)

B747CMD_ap_L_nav_filter_sel_dial_up = deferred_command("laminar/B747/ap_L/nav_filter/sel_dial_up", "Audio Panel Nav Filter Selector Dial Up", B747_ap_L_nav_filter_sel_dial_up_CMDhandler)
B747CMD_ap_L_nav_filter_sel_dial_dn = deferred_command("laminar/B747/ap_L/nav_filter/sel_dial_dn", "Audio Panel Nav Filter Selector Dial Down", B747_ap_L_nav_filter_sel_dial_dn_CMDhandler)

B747CMD_ap_L_app_rcvr_sel_dial_up   = deferred_command("laminar/B747/ap_L/app_rcvr/sel_dial_up", "Audio Panel Approach Receiver Selector Dial Up", B747_ap_L_app_rcvr_sel_dial_up_CMDhandler)
B747CMD_ap_L_app_rcvr_sel_dial_dn   = deferred_command("laminar/B747/ap_L/app_rcvr/sel_dial_dn", "Audio Panel Approach Receiver Selector Dial Down", B747_ap_L_app_rcvr_sel_dial_dn_CMDhandler)

B747DR_ap_L_vhf_L_audio_vol_up      = deferred_command("laminar/B747/comm/ap_L/vhf_L_audio/vol_up", "Audio Panel Left VHF L Audio Volume Up", B747_ap_L_vhf_L_audio_vol_up_CMDhandler)
B747DR_ap_L_vhf_L_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_L/vhf_L_audio/vol_dn", "Audio Panel Left VHF L Audio Volume Down", B747_ap_L_vhf_L_audio_vol_dn_CMDhandler)
B747DR_ap_L_vhf_R_audio_vol_up      = deferred_command("laminar/B747/comm/ap_L/vhf_R_audio/vol_up", "Audio Panel Left VHF R Audio Volume Up", B747_ap_L_vhf_R_audio_vol_up_CMDhandler)
B747DR_ap_L_vhf_R_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_L/vhf_R_audio/vol_dn", "Audio Panel Left VHF R Audio Volume Down", B747_ap_L_vhf_R_audio_vol_dn_CMDhandler)
B747DR_ap_L_vhf_C_audio_vol_up      = deferred_command("laminar/B747/comm/ap_L/vhf_C_audio/vol_up", "Audio Panel Left VHF C Audio Volume Up", B747_ap_L_vhf_C_audio_vol_up_CMDhandler)
B747DR_ap_L_vhf_C_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_L/vhf_C_audio/vol_dn", "Audio Panel Left VHF C Audio Volume Down", B747_ap_L_vhf_C_audio_vol_dn_CMDhandler)
B747DR_ap_L_flt_audio_vol_up        = deferred_command("laminar/B747/comm/ap_L/flt_audio/vol_up", "Audio Panel Left FLT Audio Volume Up", B747_ap_L_flt_audio_vol_up_CMDhandler)
B747DR_ap_L_flt_audio_vol_dn        = deferred_command("laminar/B747/comm/ap_L/flt_audio/vol_dn", "Audio Panel Left FLT Audio Volume Down", B747_ap_L_flt_audio_vol_dn_CMDhandler)
B747DR_ap_L_cab_audio_vol_up        = deferred_command("laminar/B747/comm/ap_L/cab_audio/vol_up", "Audio Panel Left CAB Audio Volume Up", B747_ap_L_cab_audio_vol_up_CMDhandler)
B747DR_ap_L_cab_audio_vol_dn        = deferred_command("laminar/B747/comm/ap_L/cab_audio/vol_dn", "Audio Panel Left CAB Audio Volume Down", B747_ap_L_cab_audio_vol_dn_CMDhandler)
B747DR_ap_L_pa_audio_vol_up         = deferred_command("laminar/B747/comm/ap_L/pa_audio/vol_up", "Audio Panel Left PA Audio Volume Up", B747_ap_L_pa_audio_vol_up_CMDhandler)
B747DR_ap_L_pa_audio_vol_dn         = deferred_command("laminar/B747/comm/ap_L/pa_audio/vol_dn", "Audio Panel Left PA Audio Volume Down", B747_ap_L_pa_audio_vol_dn_CMDhandler)
B747DR_ap_L_hf_L_audio_vol_up       = deferred_command("laminar/B747/comm/ap_L/hf_L_audio/vol_up", "Audio Panel Left HF Left Audio Volume Up", B747_ap_L_hf_L_audio_vol_up_CMDhandler)
B747DR_ap_L_hf_L_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_L/hf_L_audio/vol_dn", "Audio Panel Left HF Left Audio Volume Down", B747_ap_L_hf_L_audio_vol_dn_CMDhandler)
B747DR_ap_L_hf_R_audio_vol_up       = deferred_command("laminar/B747/comm/ap_L/hf_R_audio/vol_up", "Audio Panel Left HF Right Audio Volume Up", B747_ap_L_hf_R_audio_vol_up_CMDhandler)
B747DR_ap_L_hf_R_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_L/hf_R_audio/vol_dn", "Audio Panel Left HF Right Audio Volume Down", B747_ap_L_hf_R_audio_vol_dn_CMDhandler)
B747DR_ap_L_sat_L_audio_vol_up      = deferred_command("laminar/B747/comm/ap_L/sat_L_audio/vol_up", "Audio Panel Left SAT Left Audio Volume Up", B747_ap_L_sat_L_audio_vol_up_CMDhandler)
B747DR_ap_L_sat_L_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_L/sat_L_audio/vol_dn", "Audio Panel Left SAT Left Audio Volume Down", B747_ap_L_sat_L_audio_vol_dn_CMDhandler)
B747DR_ap_L_sat_R_audio_vol_up      = deferred_command("laminar/B747/comm/ap_L/sat_R_audio/vol_up", "Audio Panel Left SAT Right Audio Volume Up", B747_ap_L_sat_R_audio_vol_up_CMDhandler)
B747DR_ap_L_sat_R_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_L/sat_R_audio/vol_dn", "Audio Panel Left SAT Right Audio Volume Down", B747_ap_L_sat_R_audio_vol_dn_CMDhandler)
B747DR_ap_L_spkr_audio_vol_up       = deferred_command("laminar/B747/comm/ap_L/spkr_audio/vol_up", "Audio Panel Left SPKR Audio Volume Up", B747_ap_L_spkr_audio_vol_up_CMDhandler)
B747DR_ap_L_spkr_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_L/spkr_audio/vol_dn", "Audio Panel Left SPKR Audio Volume Down", B747_ap_L_spkr_audio_vol_dn_CMDhandler)
B747DR_ap_L_vor_adf_audio_vol_up    = deferred_command("laminar/B747/comm/ap_L/vor_adf_audio/vol_up", "Audio Panel Left VOR/ADF Audio Volume Up", B747_ap_L_vor_adf_audio_vol_up_CMDhandler)
B747DR_ap_L_vor_adf_audio_vol_dn    = deferred_command("laminar/B747/comm/ap_L/vor_adf_audio/vol_dn", "Audio Panel Left VOR/ADF Audio Volume Down", B747_ap_L_vor_adf_audio_vol_dn_CMDhandler)
B747DR_ap_L_app_mkr_audio_vol_up    = deferred_command("laminar/B747/comm/ap_L/app_mkr_audio/vol_up", "Audio Panel Left APP/MKR Audio Volume Up", B747_ap_L_app_mkr_audio_vol_up_CMDhandler)
B747DR_ap_L_app_mkr_audio_vol_dn    = deferred_command("laminar/B747/comm/ap_L/app_mkr_audio/vol_dn", "Audio Panel Left APP/MKR Audio Volume Down", B747_ap_L_app_mkr_audio_vol_dn_CMDhandler)



-- AUDIO PANEL CENTER
B747CMD_ap_C_vhf_L_xmt_sel_switch   = deferred_command("laminar/B747/ap_C/vhf_L/xmt_sel_switch", "Audio Panel Center VHF L Transmitter Selector Switch", B747_ap_C_vhf_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_vhf_C_xmt_sel_switch   = deferred_command("laminar/B747/ap_C/vhf_C/xmt_sel_switch", "Audio Panel Center VHF C Transmitter Selector Switch", B747_ap_C_vhf_C_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_vhf_R_xmt_sel_switch   = deferred_command("laminar/B747/ap_C/vhf_R/xmt_sel_switch", "Audio Panel Center VHF R Transmitter Selector Switch", B747_ap_C_vhf_R_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_flt_xmt_sel_switch     = deferred_command("laminar/B747/ap_C/flt/xmt_sel_switch", "Audio Panel Center FLT Transmitter Selector Switch", B747_ap_C_flt_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_cab_xmt_sel_switch     = deferred_command("laminar/B747/ap_C/cab/xmt_sel_switch", "Audio Panel Center CAB Transmitter Selector Switch", B747_ap_C_cab_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_pa_xmt_sel_switch      = deferred_command("laminar/B747/ap_C/pa/xmt_sel_switch", "Audio Panel Center PA Transmitter Selector Switch", B747_ap_C_pa_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_hf_L_xmt_sel_switch    = deferred_command("laminar/B747/ap_C/hf_L/xmt_sel_switch", "Audio Panel Center HF LTransmitter Selector Switch", B747_ap_C_hf_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_hf_R_xmt_sel_switch    = deferred_command("laminar/B747/ap_C/hf_R/xmt_sel_switch", "Audio Panel Center HF RTransmitter Selector Switch", B747_ap_C_hf_R_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_sat_L_xmt_sel_switch   = deferred_command("laminar/B747/ap_C/sat_L/xmt_sel_switch", "Audio Panel Center SAT L Transmitter Selector Switch", B747_ap_C_sat_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_C_sat_R_xmt_sel_switch   = deferred_command("laminar/B747/ap_C/sat_R/xmt_sel_switch", "Audio Panel Center SAT R Transmitter Selector Switch", B747_ap_C_sat_R_xmt_sel_switch_CMDhandler)

B747CMD_ap_C_vhf_L_audio_sel_switch = deferred_command("laminar/B747/ap_C/vhf_L/audio_sel_switch", "Audio Panel Center VHF L Audio Selector Switch", B747_ap_C_vhf_L_audio_sel_switch_CMDhandler)
B747CMD_ap_C_vhf_C_audio_sel_switch = deferred_command("laminar/B747/ap_C/vhf_C/audio_sel_switch", "Audio Panel Center VHF C Audio Selector Switch", B747_ap_C_vhf_C_audio_sel_switch_CMDhandler)
B747CMD_ap_C_vhf_R_audio_sel_switch = deferred_command("laminar/B747/ap_C/vhf_R/audio_sel_switch", "Audio Panel Center VHF R Audio Selector Switch", B747_ap_C_vhf_R_audio_sel_switch_CMDhandler)
B747CMD_ap_C_flt_audio_sel_switch   = deferred_command("laminar/B747/ap_C/flt/audio_sel_switch", "Audio Panel Center FLT Audio Selector Switch", B747_ap_C_flt_audio_sel_switch_CMDhandler)
B747CMD_ap_C_cab_audio_sel_switch   = deferred_command("laminar/B747/ap_C/cab/audio_sel_switch", "Audio Panel Center CAB Audio Selector Switch", B747_ap_C_cab_audio_sel_switch_CMDhandler)
B747CMD_ap_C_pa_audio_sel_switch    = deferred_command("laminar/B747/ap_C/pa/audio_sel_switch", "Audio Panel Center PA Audio Selector Switch", B747_ap_C_pa_audio_sel_switch_CMDhandler)
B747CMD_ap_C_hf_L_audio_sel_switch  = deferred_command("laminar/B747/ap_C/hf_L/audio_sel_switch", "Audio Panel Center HF Audio Selector Switch", B747_ap_C_hf_L_audio_sel_switch_CMDhandler)
B747CMD_ap_C_hf_R_audio_sel_switch  = deferred_command("laminar/B747/ap_C/hf_R/audio_sel_switch", "Audio Panel Center HF Audio Selector Switch", B747_ap_C_hf_R_audio_sel_switch_CMDhandler)
B747CMD_ap_C_sat_L_audio_sel_switch = deferred_command("laminar/B747/ap_C/sat_L/audio_sel_switch", "Audio Panel Center SAT L Audio Selector Switch", B747_ap_C_sat_L_audio_sel_switch_CMDhandler)
B747CMD_ap_C_sat_R_audio_sel_switch = deferred_command("laminar/B747/ap_C/sat_R/audio_sel_switch", "Audio Panel Center SAT R Audio Selector Switch", B747_ap_C_sat_R_audio_sel_switch_CMDhandler)
B747CMD_ap_C_spkr_audio_sel_switch  = deferred_command("laminar/B747/ap_C/spkr/audio_sel_switch", "Audio Panel Center Speaker Audio Selector Switch", B747_ap_C_spkr_audio_sel_switch_CMDhandler)
B747CMD_ap_C_vor_adf_audio_sel_switch = deferred_command("laminar/B747/ap_C/vor_adf/audio_sel_switch", "Audio Panel Center VOR/ADF Audio Selector Switch", B747_ap_C_vor_adf_audio_sel_switch_CMDhandler)
B747CMD_ap_C_app_mkr_audio_sel_switch = deferred_command("laminar/B747/ap_C/app_mkr/audio_sel_switch", "Audio Panel Center APP/MKR Audio Selector Switch", B747_ap_C_app_mkr_audio_sel_switch_CMDhandler)

B747CMD_ap_C_ptt_sel_switch_up      = deferred_command("laminar/B747/ap_C/ptt/sel_switch_up", "Audio Panel Center Push-To_Talk Selector Switch Up", B747_ap_C_ptt_sel_switch_up_CMDhandler)
B747CMD_ap_C_ptt_sel_switch_dn      = deferred_command("laminar/B747/ap_C/ptt/sel_switch_dn", "Audio Panel Center Push-To_Talk Selector Switch Down", B747_ap_C_ptt_sel_switch_dn_CMDhandler)

B747CMD_ap_C_vor_adf_rcvr_sel_dial_up = deferred_command("laminar/B747/ap_C/vor_adf_rcvr/sel_dial_up", "Audio Panel Center VOR/ADF Receiver Selector Dial Up", B747_ap_C_vor_adf_rcvr_sel_dial_up_CMDhandler)
B747CMD_ap_C_vor_adf_rcvr_sel_dial_dn = deferred_command("laminar/B747/ap_C/vor_adf_rcvr/sel_dial_dn", "Audio Panel Center VOR/ADF Receiver Selector Dial Down", B747_ap_C_vor_adf_rcvr_sel_dial_dn_CMDhandler)

B747CMD_ap_C_nav_filter_sel_dial_up = deferred_command("laminar/B747/ap_C/nav_filter/sel_dial_up", "Audio Panel Center Nav Filter Selector Dial Up", B747_ap_C_nav_filter_sel_dial_up_CMDhandler)
B747CMD_ap_C_nav_filter_sel_dial_dn = deferred_command("laminar/B747/ap_C/nav_filter/sel_dial_dn", "Audio Panel Center Nav Filter Selector Dial Down", B747_ap_C_nav_filter_sel_dial_dn_CMDhandler)

B747CMD_ap_C_app_rcvr_sel_dial_up   = deferred_command("laminar/B747/ap_C/app_rcvr/sel_dial_up", "Audio Panel Center Approach Receiver Selector Dial Up", B747_ap_C_app_rcvr_sel_dial_up_CMDhandler)
B747CMD_ap_C_app_rcvr_sel_dial_dn   = deferred_command("laminar/B747/ap_C/app_rcvr/sel_dial_dn", "Audio Panel Center Approach Receiver Selector Dial Down", B747_ap_C_app_rcvr_sel_dial_dn_CMDhandler)

B747DR_ap_C_vhf_L_audio_vol_up      = deferred_command("laminar/B747/comm/ap_C/vhf_L_audio/vol_up", "Audio Panel Center VHF L Audio Volume Up", B747_ap_C_vhf_L_audio_vol_up_CMDhandler)
B747DR_ap_C_vhf_L_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_C/vhf_L_audio/vol_dn", "Audio Panel Center VHF L Audio Volume Down", B747_ap_C_vhf_L_audio_vol_dn_CMDhandler)
B747DR_ap_C_vhf_R_audio_vol_up      = deferred_command("laminar/B747/comm/ap_C/vhf_R_audio/vol_up", "Audio Panel Center VHF R Audio Volume Up", B747_ap_C_vhf_R_audio_vol_up_CMDhandler)
B747DR_ap_C_vhf_R_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_C/vhf_R_audio/vol_dn", "Audio Panel Center VHF R Audio Volume Down", B747_ap_C_vhf_R_audio_vol_dn_CMDhandler)
B747DR_ap_C_vhf_C_audio_vol_up      = deferred_command("laminar/B747/comm/ap_C/vhf_C_audio/vol_up", "Audio Panel Center VHF C Audio Volume Up", B747_ap_C_vhf_C_audio_vol_up_CMDhandler)
B747DR_ap_C_vhf_C_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_C/vhf_C_audio/vol_dn", "Audio Panel Center VHF C Audio Volume Down", B747_ap_C_vhf_C_audio_vol_dn_CMDhandler)
B747DR_ap_C_flt_audio_vol_up        = deferred_command("laminar/B747/comm/ap_C/flt_audio/vol_up", "Audio Panel Center FLT Audio Volume Up", B747_ap_C_flt_audio_vol_up_CMDhandler)
B747DR_ap_C_flt_audio_vol_dn        = deferred_command("laminar/B747/comm/ap_C/flt_audio/vol_dn", "Audio Panel Center FLT Audio Volume Down", B747_ap_C_flt_audio_vol_dn_CMDhandler)
B747DR_ap_C_cab_audio_vol_up        = deferred_command("laminar/B747/comm/ap_C/cab_audio/vol_up", "Audio Panel Center CAB Audio Volume Up", B747_ap_C_cab_audio_vol_up_CMDhandler)
B747DR_ap_C_cab_audio_vol_dn        = deferred_command("laminar/B747/comm/ap_C/cab_audio/vol_dn", "Audio Panel Center CAB Audio Volume Down", B747_ap_C_cab_audio_vol_dn_CMDhandler)
B747DR_ap_C_pa_audio_vol_up         = deferred_command("laminar/B747/comm/ap_C/pa_audio/vol_up", "Audio Panel Center PA Audio Volume Up", B747_ap_C_pa_audio_vol_up_CMDhandler)
B747DR_ap_C_pa_audio_vol_dn         = deferred_command("laminar/B747/comm/ap_C/pa_audio/vol_dn", "Audio Panel Center PA Audio Volume Down", B747_ap_C_pa_audio_vol_dn_CMDhandler)
B747DR_ap_C_hf_L_audio_vol_up       = deferred_command("laminar/B747/comm/ap_C/hf_L_audio/vol_up", "Audio Panel Center HF Left Audio Volume Up", B747_ap_C_hf_L_audio_vol_up_CMDhandler)
B747DR_ap_C_hf_L_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_C/hf_L_audio/vol_dn", "Audio Panel Center HF Left Audio Volume Down", B747_ap_C_hf_L_audio_vol_dn_CMDhandler)
B747DR_ap_C_hf_R_audio_vol_up       = deferred_command("laminar/B747/comm/ap_C/hf_R_audio/vol_up", "Audio Panel Center HF Right Audio Volume Up", B747_ap_C_hf_R_audio_vol_up_CMDhandler)
B747DR_ap_C_hf_R_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_C/hf_R_audio/vol_dn", "Audio Panel Center HF Right Audio Volume Down", B747_ap_C_hf_R_audio_vol_dn_CMDhandler)
B747DR_ap_C_sat_L_audio_vol_up      = deferred_command("laminar/B747/comm/ap_C/sat_L_audio/vol_up", "Audio Panel Center SAT Left Audio Volume Up", B747_ap_C_sat_L_audio_vol_up_CMDhandler)
B747DR_ap_C_sat_L_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_C/sat_L_audio/vol_dn", "Audio Panel Center SAT Left Audio Volume Down", B747_ap_C_sat_L_audio_vol_dn_CMDhandler)
B747DR_ap_C_sat_R_audio_vol_up      = deferred_command("laminar/B747/comm/ap_C/sat_R_audio/vol_up", "Audio Panel Center SAT Right Audio Volume Up", B747_ap_C_sat_R_audio_vol_up_CMDhandler)
B747DR_ap_C_sat_R_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_C/sat_R_audio/vol_dn", "Audio Panel Center SAT Right Audio Volume Down", B747_ap_C_sat_R_audio_vol_dn_CMDhandler)
B747DR_ap_C_spkr_audio_vol_up       = deferred_command("laminar/B747/comm/ap_C/spkr_audio/vol_up", "Audio Panel Center SPKR Audio Volume Up", B747_ap_C_spkr_audio_vol_up_CMDhandler)
B747DR_ap_C_spkr_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_C/spkr_audio/vol_dn", "Audio Panel Center SPKR Audio Volume Down", B747_ap_C_spkr_audio_vol_dn_CMDhandler)
B747DR_ap_C_vor_adf_audio_vol_up    = deferred_command("laminar/B747/comm/ap_C/vor_adf_audio/vol_up", "Audio Panel Center VOR/ADF Audio Volume Up", B747_ap_C_vor_adf_audio_vol_up_CMDhandler)
B747DR_ap_C_vor_adf_audio_vol_dn    = deferred_command("laminar/B747/comm/ap_C/vor_adf_audio/vol_dn", "Audio Panel Center VOR/ADF Audio Volume Down", B747_ap_C_vor_adf_audio_vol_dn_CMDhandler)
B747DR_ap_C_app_mkr_audio_vol_up    = deferred_command("laminar/B747/comm/ap_C/app_mkr_audio/vol_up", "Audio Panel Center APP/MKR Audio Volume Up", B747_ap_C_app_mkr_audio_vol_up_CMDhandler)
B747DR_ap_C_app_mkr_audio_vol_dn    = deferred_command("laminar/B747/comm/ap_C/app_mkr_audio/vol_dn", "Audio Panel Center APP/MKR Audio Volume Down", B747_ap_C_app_mkr_audio_vol_dn_CMDhandler)



-- AUDIO PANEL RIGHT
B747CMD_ap_R_vhf_L_xmt_sel_switch   = deferred_command("laminar/B747/ap_R/vhf_L/xmt_sel_switch", "Audio Panel Right VHF L Transmitter Selector Switch", B747_ap_R_vhf_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_vhf_C_xmt_sel_switch   = deferred_command("laminar/B747/ap_R/vhf_C/xmt_sel_switch", "Audio Panel Right VHF C Transmitter Selector Switch", B747_ap_R_vhf_C_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_vhf_R_xmt_sel_switch   = deferred_command("laminar/B747/ap_R/vhf_R/xmt_sel_switch", "Audio Panel Right VHF R Transmitter Selector Switch", B747_ap_R_vhf_R_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_flt_xmt_sel_switch     = deferred_command("laminar/B747/ap_R/flt/xmt_sel_switch", "Audio Panel Right FLT Transmitter Selector Switch", B747_ap_R_flt_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_cab_xmt_sel_switch     = deferred_command("laminar/B747/ap_R/cab/xmt_sel_switch", "Audio Panel Right CAB Transmitter Selector Switch", B747_ap_R_cab_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_pa_xmt_sel_switch      = deferred_command("laminar/B747/ap_R/pa/xmt_sel_switch", "Audio Panel Right PA Transmitter Selector Switch", B747_ap_R_pa_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_hf_L_xmt_sel_switch    = deferred_command("laminar/B747/ap_R/hf_L/xmt_sel_switch", "Audio Panel Right HF LTransmitter Selector Switch", B747_ap_R_hf_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_hf_R_xmt_sel_switch    = deferred_command("laminar/B747/ap_R/hf_R/xmt_sel_switch", "Audio Panel Right HF RTransmitter Selector Switch", B747_ap_R_hf_R_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_sat_L_xmt_sel_switch   = deferred_command("laminar/B747/ap_R/sat_L/xmt_sel_switch", "Audio Panel Right SAT L Transmitter Selector Switch", B747_ap_R_sat_L_xmt_sel_switch_CMDhandler)
B747CMD_ap_R_sat_R_xmt_sel_switch   = deferred_command("laminar/B747/ap_R/sat_R/xmt_sel_switch", "Audio Panel Right SAT R Transmitter Selector Switch", B747_ap_R_sat_R_xmt_sel_switch_CMDhandler)

B747CMD_ap_R_vhf_L_audio_sel_switch = deferred_command("laminar/B747/ap_R/vhf_L/audio_sel_switch", "Audio Panel Right VHF L Audio Selector Switch", B747_ap_R_vhf_L_audio_sel_switch_CMDhandler)
B747CMD_ap_R_vhf_C_audio_sel_switch = deferred_command("laminar/B747/ap_R/vhf_C/audio_sel_switch", "Audio Panel Right VHF C Audio Selector Switch", B747_ap_R_vhf_C_audio_sel_switch_CMDhandler)
B747CMD_ap_R_vhf_R_audio_sel_switch = deferred_command("laminar/B747/ap_R/vhf_R/audio_sel_switch", "Audio Panel Right VHF R Audio Selector Switch", B747_ap_R_vhf_R_audio_sel_switch_CMDhandler)
B747CMD_ap_R_flt_audio_sel_switch   = deferred_command("laminar/B747/ap_R/flt/audio_sel_switch", "Audio Panel Right FLT Audio Selector Switch", B747_ap_R_flt_audio_sel_switch_CMDhandler)
B747CMD_ap_R_cab_audio_sel_switch   = deferred_command("laminar/B747/ap_R/cab/audio_sel_switch", "Audio Panel Right CAB Audio Selector Switch", B747_ap_R_cab_audio_sel_switch_CMDhandler)
B747CMD_ap_R_pa_audio_sel_switch    = deferred_command("laminar/B747/ap_R/pa/audio_sel_switch", "Audio Panel Right PA Audio Selector Switch", B747_ap_R_pa_audio_sel_switch_CMDhandler)
B747CMD_ap_R_hf_L_audio_sel_switch  = deferred_command("laminar/B747/ap_R/hf_L/audio_sel_switch", "Audio Panel Right HF Audio Selector Switch", B747_ap_R_hf_L_audio_sel_switch_CMDhandler)
B747CMD_ap_R_hf_R_audio_sel_switch  = deferred_command("laminar/B747/ap_R/hf_R/audio_sel_switch", "Audio Panel Right HF Audio Selector Switch", B747_ap_R_hf_R_audio_sel_switch_CMDhandler)
B747CMD_ap_R_sat_L_audio_sel_switch = deferred_command("laminar/B747/ap_R/sat_L/audio_sel_switch", "Audio Panel Right SAT L Audio Selector Switch", B747_ap_R_sat_L_audio_sel_switch_CMDhandler)
B747CMD_ap_R_sat_R_audio_sel_switch = deferred_command("laminar/B747/ap_R/sat_R/audio_sel_switch", "Audio Panel Right SAT R Audio Selector Switch", B747_ap_R_sat_R_audio_sel_switch_CMDhandler)
B747CMD_ap_R_spkr_audio_sel_switch  = deferred_command("laminar/B747/ap_R/spkr/audio_sel_switch", "Audio Panel Right Speaker Audio Selector Switch", B747_ap_R_spkr_audio_sel_switch_CMDhandler)
B747CMD_ap_R_vor_adf_audio_sel_switch = deferred_command("laminar/B747/ap_R/vor_adf/audio_sel_switch", "Audio Panel Right VOR/ADF Audio Selector Switch", B747_ap_R_vor_adf_audio_sel_switch_CMDhandler)
B747CMD_ap_R_app_mkr_audio_sel_switch = deferred_command("laminar/B747/ap_R/app_mkr/audio_sel_switch", "Audio Panel Right APP/MKR Audio Selector Switch", B747_ap_R_app_mkr_audio_sel_switch_CMDhandler)

B747CMD_ap_R_ptt_sel_switch_up      = deferred_command("laminar/B747/ap_R/ptt/sel_switch_up", "Audio Panel Right Push-To_Talk Selector Switch Up", B747_ap_R_ptt_sel_switch_up_CMDhandler)
B747CMD_ap_R_ptt_sel_switch_dn      = deferred_command("laminar/B747/ap_R/ptt/sel_switch_dn", "Audio Panel Right Push-To_Talk Selector Switch Down", B747_ap_R_ptt_sel_switch_dn_CMDhandler)

B747CMD_ap_R_vor_adf_rcvr_sel_dial_up = deferred_command("laminar/B747/ap_R/vor_adf_rcvr/sel_dial_up", "Audio Panel Right VOR/ADF Receiver Selector Dial Up", B747_ap_R_vor_adf_rcvr_sel_dial_up_CMDhandler)
B747CMD_ap_R_vor_adf_rcvr_sel_dial_dn = deferred_command("laminar/B747/ap_R/vor_adf_rcvr/sel_dial_dn", "Audio Panel Right VOR/ADF Receiver Selector Dial Down", B747_ap_R_vor_adf_rcvr_sel_dial_dn_CMDhandler)

B747CMD_ap_R_nav_filter_sel_dial_up = deferred_command("laminar/B747/ap_R/nav_filter/sel_dial_up", "Audio Panel Right Nav Filter Selector Dial Up", B747_ap_R_nav_filter_sel_dial_up_CMDhandler)
B747CMD_ap_R_nav_filter_sel_dial_dn = deferred_command("laminar/B747/ap_R/nav_filter/sel_dial_dn", "Audio Panel Right Nav Filter Selector Dial Down", B747_ap_R_nav_filter_sel_dial_dn_CMDhandler)

B747CMD_ap_R_app_rcvr_sel_dial_up   = deferred_command("laminar/B747/ap_R/app_rcvr/sel_dial_up", "Audio Panel Right Approach Receiver Selector Dial Up", B747_ap_R_app_rcvr_sel_dial_up_CMDhandler)
B747CMD_ap_R_app_rcvr_sel_dial_dn   = deferred_command("laminar/B747/ap_R/app_rcvr/sel_dial_dn", "Audio Panel Right Approach Receiver Selector Dial Down", B747_ap_R_app_rcvr_sel_dial_dn_CMDhandler)

B747DR_ap_R_vhf_L_audio_vol_up      = deferred_command("laminar/B747/comm/ap_R/vhf_L_audio/vol_up", "Audio Panel Right VHF L Audio Volume Up", B747_ap_R_vhf_L_audio_vol_up_CMDhandler)
B747DR_ap_R_vhf_L_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_R/vhf_L_audio/vol_dn", "Audio Panel Right VHF L Audio Volume Down", B747_ap_R_vhf_L_audio_vol_dn_CMDhandler)
B747DR_ap_R_vhf_R_audio_vol_up      = deferred_command("laminar/B747/comm/ap_R/vhf_R_audio/vol_up", "Audio Panel Right VHF R Audio Volume Up", B747_ap_R_vhf_R_audio_vol_up_CMDhandler)
B747DR_ap_R_vhf_R_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_R/vhf_R_audio/vol_dn", "Audio Panel Right VHF R Audio Volume Down", B747_ap_R_vhf_R_audio_vol_dn_CMDhandler)
B747DR_ap_R_vhf_C_audio_vol_up      = deferred_command("laminar/B747/comm/ap_R/vhf_C_audio/vol_up", "Audio Panel Right VHF C Audio Volume Up", B747_ap_R_vhf_C_audio_vol_up_CMDhandler)
B747DR_ap_R_vhf_C_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_R/vhf_C_audio/vol_dn", "Audio Panel Right VHF C Audio Volume Down", B747_ap_R_vhf_C_audio_vol_dn_CMDhandler)
B747DR_ap_R_flt_audio_vol_up        = deferred_command("laminar/B747/comm/ap_R/flt_audio/vol_up", "Audio Panel Right FLT Audio Volume Up", B747_ap_R_flt_audio_vol_up_CMDhandler)
B747DR_ap_R_flt_audio_vol_dn        = deferred_command("laminar/B747/comm/ap_R/flt_audio/vol_dn", "Audio Panel Right FLT Audio Volume Down", B747_ap_R_flt_audio_vol_dn_CMDhandler)
B747DR_ap_R_cab_audio_vol_up        = deferred_command("laminar/B747/comm/ap_R/cab_audio/vol_up", "Audio Panel Right CAB Audio Volume Up", B747_ap_R_cab_audio_vol_up_CMDhandler)
B747DR_ap_R_cab_audio_vol_dn        = deferred_command("laminar/B747/comm/ap_R/cab_audio/vol_dn", "Audio Panel Right CAB Audio Volume Down", B747_ap_R_cab_audio_vol_dn_CMDhandler)
B747DR_ap_R_pa_audio_vol_up         = deferred_command("laminar/B747/comm/ap_R/pa_audio/vol_up", "Audio Panel Right PA Audio Volume Up", B747_ap_R_pa_audio_vol_up_CMDhandler)
B747DR_ap_R_pa_audio_vol_dn         = deferred_command("laminar/B747/comm/ap_R/pa_audio/vol_dn", "Audio Panel Right PA Audio Volume Down", B747_ap_R_pa_audio_vol_dn_CMDhandler)
B747DR_ap_R_hf_L_audio_vol_up       = deferred_command("laminar/B747/comm/ap_R/hf_L_audio/vol_up", "Audio Panel Right HF Left Audio Volume Up", B747_ap_R_hf_L_audio_vol_up_CMDhandler)
B747DR_ap_R_hf_L_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_R/hf_L_audio/vol_dn", "Audio Panel Right HF Left Audio Volume Down", B747_ap_R_hf_L_audio_vol_dn_CMDhandler)
B747DR_ap_R_hf_R_audio_vol_up       = deferred_command("laminar/B747/comm/ap_R/hf_R_audio/vol_up", "Audio Panel Right HF Right Audio Volume Up", B747_ap_R_hf_R_audio_vol_up_CMDhandler)
B747DR_ap_R_hf_R_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_R/hf_R_audio/vol_dn", "Audio Panel Right HF Right Audio Volume Down", B747_ap_R_hf_R_audio_vol_dn_CMDhandler)
B747DR_ap_R_sat_L_audio_vol_up      = deferred_command("laminar/B747/comm/ap_R/sat_L_audio/vol_up", "Audio Panel Right SAT Left Audio Volume Up", B747_ap_R_sat_L_audio_vol_up_CMDhandler)
B747DR_ap_R_sat_L_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_R/sat_L_audio/vol_dn", "Audio Panel Right SAT Left Audio Volume Down", B747_ap_R_sat_L_audio_vol_dn_CMDhandler)
B747DR_ap_R_sat_R_audio_vol_up      = deferred_command("laminar/B747/comm/ap_R/sat_R_audio/vol_up", "Audio Panel Right SAT Right Audio Volume Up", B747_ap_R_sat_R_audio_vol_up_CMDhandler)
B747DR_ap_R_sat_R_audio_vol_dn      = deferred_command("laminar/B747/comm/ap_R/sat_R_audio/vol_dn", "Audio Panel Right SAT Right Audio Volume Down", B747_ap_R_sat_R_audio_vol_dn_CMDhandler)
B747DR_ap_R_spkr_audio_vol_up       = deferred_command("laminar/B747/comm/ap_R/spkr_audio/vol_up", "Audio Panel Right SPKR Audio Volume Up", B747_ap_R_spkr_audio_vol_up_CMDhandler)
B747DR_ap_R_spkr_audio_vol_dn       = deferred_command("laminar/B747/comm/ap_R/spkr_audio/vol_dn", "Audio Panel Right SPKR Audio Volume Down", B747_ap_R_spkr_audio_vol_dn_CMDhandler)
B747DR_ap_R_vor_adf_audio_vol_up    = deferred_command("laminar/B747/comm/ap_R/vor_adf_audio/vol_up", "Audio Panel Right VOR/ADF Audio Volume Up", B747_ap_R_vor_adf_audio_vol_up_CMDhandler)
B747DR_ap_R_vor_adf_audio_vol_dn    = deferred_command("laminar/B747/comm/ap_R/vor_adf_audio/vol_dn", "Audio Panel Right VOR/ADF Audio Volume Down", B747_ap_R_vor_adf_audio_vol_dn_CMDhandler)
B747DR_ap_R_app_mkr_audio_vol_up    = deferred_command("laminar/B747/comm/ap_R/app_mkr_audio/vol_up", "Audio Panel Right APP/MKR Audio Volume Up", B747_ap_R_app_mkr_audio_vol_up_CMDhandler)
B747DR_ap_R_app_mkr_audio_vol_dn    = deferred_command("laminar/B747/comm/ap_R/app_mkr_audio/vol_dn", "Audio Panel Right APP/MKR Audio Volume Down", B747_ap_R_app_mkr_audio_vol_dn_CMDhandler)



-- AI
B747CMD_ai_elec_quick_start			= deferred_command("laminar/B747/ai/com_quick_start", "number", B747_ai_com_quick_start_CMDhandler)


-- WXR panel

B747CMD_wxr_test  = deferred_command("laminar/B747/wxr/buttons/test", "WXR Test", B747_wxr_test_CMDhandler)
B747CMD_wxr_rr  = deferred_command("laminar/B747/wxr/buttons/rr", "WXR RR", B747_wxr_rr_CMDhandler)
B747CMD_wxr_lr  = deferred_command("laminar/B747/wxr/buttons/lr", "WXR LR", B747_wxr_lr_CMDhandler)
B747CMD_wxr_cpt_ftr  = deferred_command("laminar/B747/wxr/buttons/cpt_ftr", "WXR CPT TFR", B747_wxr_cpt_ftr_CMDhandler)
B747CMD_wxr_fo_ftr  = deferred_command("laminar/B747/wxr/buttons/fo_ftr", "WXR FO TFR", B747_wxr_fo_ftr_CMDhandler)

