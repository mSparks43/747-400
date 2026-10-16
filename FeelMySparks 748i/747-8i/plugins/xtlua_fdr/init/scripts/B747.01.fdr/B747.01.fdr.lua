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
debug_fdr     = deferred_dataref("laminar/B747/debug/fdr", "number")



B747CMD_fdr_log_lnav           = deferred_command("laminar/B747/fdr/lnav", "", B747CMD_fdr_log_lnav_CMDhandler)
B747CMD_fdr_log_vnav           = deferred_command("laminar/B747/fdr/vnav", "", B747CMD_fdr_log_vnav_CMDhandler)
B747CMD_fdr_log_apon           = deferred_command("laminar/B747/fdr/apon", "", B747CMD_fdr_log_apon_CMDhandler)
B747CMD_fdr_log_apdisconnect           = deferred_command("laminar/B747/fdr/apdisconnect", "", B747CMD_fdr_log_apdisconnect_CMDhandler)
B747CMD_fdr_log_flch           = deferred_command("laminar/B747/fdr/flch", "", B747CMD_fdr_log_flch_CMDhandler)
B747CMD_fdr_log_vs           = deferred_command("laminar/B747/fdr/vs", "", B747CMD_fdr_log_vs_CMDhandler)
B747CMD_fdr_log_alt           = deferred_command("laminar/B747/fdr/alt", "", B747CMD_fdr_log_alt_CMDhandler)
B747CMD_fdr_log_toga           = deferred_command("laminar/B747/fdr/toga", "", B747CMD_fdr_log_toga_CMDhandler)
B747CMD_fdr_log_loc           = deferred_command("laminar/B747/fdr/loc", "", B747CMD_fdr_log_loc_CMDhandler)
B747CMD_fdr_log_app           = deferred_command("laminar/B747/fdr/app", "", B747CMD_fdr_log_app_CMDhandler)
B747CMD_fdr_log_altmod           = deferred_command("laminar/B747/fdr/altmod", "", B747CMD_fdr_log_altmod_CMDhandler)
B747CMD_fdr_log_spdmod           = deferred_command("laminar/B747/fdr/spdmod", "", B747CMD_fdr_log_spdmod_CMDhandler)
B747CMD_fdr_log_spd           = deferred_command("laminar/B747/fdr/spd", "", B747CMD_fdr_log_spd_CMDhandler)
B747CMD_fdr_log_headsel           = deferred_command("laminar/B747/fdr/headsel", "", B747CMD_fdr_log_headsel_CMDhandler)
B747CMD_fdr_log_headhold          = deferred_command("laminar/B747/fdr/headhold", "", B747CMD_fdr_log_headhold_CMDhandler)
