registerFMCCommand("laminar/B747/dsp/eng_switch","")
registerFMCCommand("laminar/B747/dsp/stat_switch","")
registerFMCCommand("laminar/B747/dsp/canc_switch","")
registerFMCCommand("laminar/B747/dsp/fuel_switch","")
registerFMCCommand("laminar/B747/dsp/gear_switch","")
registerFMCCommand("laminar/B747/dsp/rcl_switch","")
registerFMCCommand("laminar/B747/dsp/elec_switch","")
registerFMCCommand("laminar/B747/dsp/ecs_switch","")
registerFMCCommand("laminar/B747/dsp/hyd_switch","")
registerFMCCommand("laminar/B747/dsp/drs_switch","")
fmsPages["EICASMODES"]=createPage("EICASMODES")
fmsPages["EICASMODES"]["template"]={

"       EICAS MODES      ",
"                        ",
"<ENG               FUEL>",
"                        ",
"<STAT              GEAR>",
"                        ",
"                        ",
"                        ",
"                        ", 
"------------------------",
"<CANC               RCL>",
"                        ",
"              SYNOPTICS>"
}


fmsFunctionsDefs["EICASMODES"]={}

fmsFunctionsDefs["EICASMODES"]["L1"]={"doCMD","laminar/B747/dsp/eng_switch"}
fmsFunctionsDefs["EICASMODES"]["L2"]={"doCMD","laminar/B747/dsp/stat_switch"}
fmsFunctionsDefs["EICASMODES"]["L5"]={"doCMD","laminar/B747/dsp/canc_switch"}
fmsFunctionsDefs["EICASMODES"]["R1"]={"doCMD","laminar/B747/dsp/fuel_switch"}
fmsFunctionsDefs["EICASMODES"]["R2"]={"doCMD","laminar/B747/dsp/gear_switch"}
fmsFunctionsDefs["EICASMODES"]["R5"]={"doCMD","laminar/B747/dsp/rcl_switch"}
fmsFunctionsDefs["EICASMODES"]["R6"]={"setpage","EICASSYN"}

fmsPages["EICASSYN"]=createPage("EICASSYN")
fmsPages["EICASSYN"]["template"]={

"       EICAS MODES      ",
"                        ",
"<ELEC               HYD>",
"                        ",
"<ECS              DOORS>",
"                        ",
"                        ",
"                        ",
"                        ",
"------------------------",
"<CANC               RCL>",
"                        ",
"                  MODES>"
}


fmsFunctionsDefs["EICASSYN"]={}

fmsFunctionsDefs["EICASSYN"]["L1"]={"doCMD","laminar/B747/dsp/elec_switch"}
fmsFunctionsDefs["EICASSYN"]["L2"]={"doCMD","laminar/B747/dsp/ecs_switch"}
fmsFunctionsDefs["EICASSYN"]["L5"]={"doCMD","laminar/B747/dsp/canc_switch"}
fmsFunctionsDefs["EICASSYN"]["R1"]={"doCMD","laminar/B747/dsp/hyd_switch"}
fmsFunctionsDefs["EICASSYN"]["R2"]={"doCMD","laminar/B747/dsp/drs_switch"}
fmsFunctionsDefs["EICASSYN"]["R5"]={"doCMD","laminar/B747/dsp/rcl_switch"}
fmsFunctionsDefs["EICASSYN"]["R6"]={"setpage","EICASMODES"}