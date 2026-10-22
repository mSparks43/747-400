-- Run from the repository root with LuaJIT: luajit tests/gear/pseu_model_test.lua
-- The air/ground sensing model (plugins/xtlua/scripts/B747.10.xt.gear/B747.10.pseu_model.lua)
-- against ATA29_32 p.322-323 (the AIR and GND formula), p.310/p.320 (nose
-- gear compressed, ALL GR DN) and FCOM p.1512 (lever lock).
local T = dofile("tests/lib/check.lua")("pseu_model")
local P = dofile("plugins/xtlua/scripts/B747.10.xt.gear/B747.10.pseu_model.lua")

-- truck angles of LWG, LBG, RBG, RWG; acf eagle claw: wing 58 deg, body 8 deg
local IN_AIR = {58, 8, 8, 58}
local LEVEL = {0, 0, 0, 0}

local function state(tilt, nose_on_ground, psi)
    local inp = P.inputs()
    inp.tilt_deg = {tilt[1], tilt[2], tilt[3], tilt[4]}
    inp.nose_on_ground = nose_on_ground
    inp.hyd_psi = {psi, psi, psi, psi}
    return inp
end

-- parked, hydraulics off: the trucks cannot be trusted, the compressed nose
-- gear with a system low makes GND (p.322)
local out = P.update(state(LEVEL, true, 0))
T.check(out.pri_gnd and not out.pri_air, "parked, no hydraulics: ground (nose gear compressed)")
T.check(out.alt_gnd and not out.alt_air, "parked: alternate the same")
T.check(out.ng_compressed, "parked: NG COMPRESSED")

-- parked, hydraulics on: ground from the level trucks
out = P.update(state(LEVEL, true, 3000))
T.check(out.pri_gnd and not out.pri_air, "parked, hydraulics on: ground")

-- in flight: all trucks tilted, nose gear extended
out = P.update(state(IN_AIR, false, 3000))
T.check(out.pri_air and not out.pri_gnd, "flight: air")
T.check(not out.ng_compressed, "flight: nose gear not compressed")
out = P.update(state(IN_AIR, false, 0))
T.check(out.pri_air and not out.pri_gnd, "flight, hydraulics lost: still air")

-- landing on the left main gear only: air until both sides are down (p.322)
out = P.update(state({0, 0, 8, 58}, false, 3000))
T.check(out.pri_air and not out.pri_gnd, "left main gear on the ground: still air")
out = P.update(state({0, 0, 0, 0}, false, 3000))
T.check(out.pri_gnd and not out.pri_air, "both sides on the ground: ground, before the nose gear")

-- one truck of each side is enough: left wing and right body gear level
out = P.update(state({0, 8, 0, 58}, false, 3000))
T.check(out.pri_gnd and not out.pri_air, "one level truck per side: ground")

-- the body gear counts only when down and locked (p.334)
local inp = state({58, 0, 0, 58}, false, 3000)
inp.down[P.LBG], inp.down[P.RBG] = 0.5, 0.5
out = P.update(inp)
T.check(not out.pri_gnd, "body gear level but not down and locked: not ground")
T.check(not out.all_gear_down, "body gear not down: ALL GR DN off")

-- ALL GR DN and the nose gear
inp = state(IN_AIR, false, 3000)
out = P.update(inp)
T.check(out.all_gear_down and not out.nose_not_down, "all gear down: ALL GR DN")
inp.nose_down = 0.3
out = P.update(inp)
T.check(not out.all_gear_down and out.nose_not_down, "nose gear in transit: NG NOT DN")

-- lever lock (FCOM p.1512): released only with all four trucks tilted and the
-- body gear steering locked
out = P.update(state(IN_AIR, false, 3000))
T.check(out.lever_unlock, "flight, trucks tilted, steering locked: lever unlocked")
out = P.update(state({58, 8, 0, 58}, false, 3000))
T.check(not out.lever_unlock, "one truck level: lever locked")
inp = state(IN_AIR, false, 3000)
inp.body_steering_locked = false
out = P.update(inp)
T.check(not out.lever_unlock, "body gear steering not locked: lever locked")
out = P.update(state(LEVEL, true, 3000))
T.check(not out.lever_unlock, "on the ground: lever locked")

T.done()
