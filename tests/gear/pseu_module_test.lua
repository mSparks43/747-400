-- Run from the repository root with LuaJIT: luajit tests/gear/pseu_module_test.lua
-- The gear module as XTLua runs it (tests/lib/xtlua.lua): X-Plane's gear
-- datarefs in, laminar/B747/gear/air_ground/* out, through the PSEU glue
-- (B747.10.xt.pseu.lua). The formula itself is tested in pseu_model_test.lua;
-- this checks the wiring, above all the X-Plane gear order (0 nose, 1 right
-- body, 2 left body, 3 right wing, 4 left wing).
local T = dofile("tests/lib/check.lua")("pseu_module")
local xtlua = dofile("tests/lib/xtlua.lua")

local rt = xtlua.new()
rt:load("plugins/xtlua/scripts/B747.10.xt.gear/B747.10.xt.gear.lua")
rt:callout("flight_start")

local CLAW = "sim/flightmodel2/gear/eagle_claw_angle_deg"
local function gear(nose_on_ground, claw)
    rt:set("sim/flightmodel2/gear/on_ground", 0, nose_on_ground and 1 or 0)
    for i = 1, 4 do rt:set(CLAW, i, claw[i]) end
    for i = 0, 4 do rt:set("sim/flightmodel2/gear/deploy_ratio", i, 1) end
    for _ = 1, 3 do rt:frame(1 / 30) end
end
local function ag(name) return rt:get("laminar/B747/gear/air_ground/" .. name) end

-- parked, hydraulics off
gear(true, {0, 0, 0, 0})
T.equal(ag("pri_gnd"), 1, "parked: ground")
T.equal(ag("pri_air"), 0, "parked: not air")
T.equal(ag("ng_compressed"), 1, "parked: nose gear compressed")
T.equal(ag("all_gear_down"), 1, "parked: ALL GR DN")
T.equal(ag("lever_unlock"), 0, "parked: lever locked")

-- flight: claw angles by X-Plane index 1 right body, 2 left body, 3 right wing, 4 left wing
rt:set("laminar/B747/hydraulics/pressure_1", 3000)
rt:set("laminar/B747/hydraulics/pressure_4", 3000)
gear(false, {8, 8, 58, 58})
T.equal(ag("pri_air"), 1, "flight: air")
T.equal(ag("pri_gnd"), 0, "flight: not ground")
T.equal(ag("lever_unlock"), 1, "flight: lever unlocked")

-- touchdown on the LEFT main gear only (X-Plane 2 left body, 4 left wing level)
gear(false, {8, 0, 58, 0})
T.equal(ag("pri_air"), 1, "left main gear down: still air")
-- touchdown on the RIGHT main gear only (X-Plane 1 right body, 3 right wing level)
gear(false, {0, 8, 0, 58})
T.equal(ag("pri_air"), 1, "right main gear down: still air")
-- both sides
gear(false, {0, 0, 0, 0})
T.equal(ag("pri_air"), 0, "both main gears down: not air")
T.equal(ag("pri_gnd"), 1, "both main gears down: ground")

T.done()
