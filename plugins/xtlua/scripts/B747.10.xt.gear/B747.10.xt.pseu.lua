-- The air/ground sensing model (B747.10.pseu_model.lua) in the aircraft:
-- reads X-Plane's gear, runs the model every frame and writes
-- laminar/B747/gear/air_ground/*. B747.10.xt.gear.lua loads it after binding
-- its datarefs and uses its bindings (simDR_gear_claw_angle,
-- simDR_gear_deploy_ratio, simDR_tire_steer_deg).
dofile("B747.10.pseu_model.lua")
local P = B747_pseu_model

simDR_pseu_gear_on_ground       = find_dataref("sim/flightmodel2/gear/on_ground")
B747DR_pseu_hyd_pressure_1      = find_dataref("laminar/B747/hydraulics/pressure_1")
B747DR_pseu_hyd_pressure_4      = find_dataref("laminar/B747/hydraulics/pressure_4")
B747DR_pseu_pri_air             = find_dataref("laminar/B747/gear/air_ground/pri_air")
B747DR_pseu_pri_gnd             = find_dataref("laminar/B747/gear/air_ground/pri_gnd")
B747DR_pseu_alt_air             = find_dataref("laminar/B747/gear/air_ground/alt_air")
B747DR_pseu_alt_gnd             = find_dataref("laminar/B747/gear/air_ground/alt_gnd")
B747DR_pseu_ng_compressed       = find_dataref("laminar/B747/gear/air_ground/ng_compressed")
B747DR_pseu_all_gear_down       = find_dataref("laminar/B747/gear/air_ground/all_gear_down")
B747DR_pseu_nose_not_down       = find_dataref("laminar/B747/gear/air_ground/nose_not_down")
B747DR_pseu_lever_unlock        = find_dataref("laminar/B747/gear/air_ground/lever_unlock")

-- X-Plane gear index of LWG, LBG, RBG, RWG (acf: 0 nose, 1 right body,
-- 2 left body, 3 right wing, 4 left wing)
local XP_GEAR = {4, 2, 1, 3}
local pseu_inputs = P.inputs()

local function flag(v)
    if v then return 1 end
    return 0
end

function B747_pseu()
    local inp = pseu_inputs
    for i = 1, 4 do
        inp.tilt_deg[i] = simDR_gear_claw_angle[XP_GEAR[i]]
        inp.down[i] = simDR_gear_deploy_ratio[XP_GEAR[i]]
    end
    inp.nose_down = simDR_gear_deploy_ratio[0]
    inp.nose_on_ground = simDR_pseu_gear_on_ground[0] == 1
    inp.hyd_psi[1] = B747DR_pseu_hyd_pressure_1
    inp.hyd_psi[4] = B747DR_pseu_hyd_pressure_4
    -- body gear steering locked: estimate, the body gear wheels centred
    inp.body_steering_locked = simDR_tire_steer_deg[1] == 0 and simDR_tire_steer_deg[2] == 0
    local out = P.update(inp)
    B747DR_pseu_pri_air = flag(out.pri_air)
    B747DR_pseu_pri_gnd = flag(out.pri_gnd)
    B747DR_pseu_alt_air = flag(out.alt_air)
    B747DR_pseu_alt_gnd = flag(out.alt_gnd)
    B747DR_pseu_ng_compressed = flag(out.ng_compressed)
    B747DR_pseu_all_gear_down = flag(out.all_gear_down)
    B747DR_pseu_nose_not_down = flag(out.nose_not_down)
    B747DR_pseu_lever_unlock = flag(out.lever_unlock)
end
