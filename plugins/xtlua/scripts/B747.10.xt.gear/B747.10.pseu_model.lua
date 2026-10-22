-- 747-400 air/ground sensing (PSEU, ATA 32-09) without X-Plane: the primary
-- and alternate air and ground signals from the main gear truck tilt, the
-- nose gear compression, and the discretes the PSEU gives other systems.
-- Logic and sources: docs/overhaul/notes/ATA-32.md §2.3, §4.1, §6.1
-- (Boeing ATA 29/32 training manual "ATA29_32", PDF pages).
--
--   local P = B747_pseu_model             -- in XTLua, after dofile
--   local P = dofile(".../B747.10.pseu_model.lua")   -- in the tests
--   local inp = P.inputs()               -- fill it every frame
--   local out = P.update(inp)

local M = setmetatable({}, {})
B747_pseu_model = M

-- Main gears in the order of the formula: left wing, left body, right body,
-- right wing.
M.LWG, M.LBG, M.RBG, M.RWG = 1, 2, 3, 4
M.TILT_DEG = 1.0           -- estimate: a truck tilted more than this is "tilted"
M.HYD_HIGH_PSI = 1500      -- estimate: HYDIM 1/4 pressure high (no figure in the sources)
M.DOWN_LOCKED = 0.99       -- gear extension ratio taken as down and locked

function M.inputs()
    return {
        tilt_deg = {0, 0, 0, 0},       -- truck angle of LWG, LBG, RBG, RWG
        down = {1, 1, 1, 1},           -- extension ratio of LWG, LBG, RBG, RWG
        nose_down = 1,                 -- nose gear extension ratio
        nose_on_ground = true,         -- nose strut compressed (estimate: the wheel on the ground)
        hyd_psi = {0, 0, 0, 0},        -- hydraulic system 1-4 pressure
        body_steering_locked = true,   -- body gear steering actuators locked (centred)
    }
end

-- One evaluation of the formula of ATA29_32 p.322 (figure p.323), for one
-- subsystem (primary and alternate are the same without failures):
--   AIR = (LWG tilted and LBG tilted) or (RWG tilted and RBG tilted)
--   GND = [(LWG level and H4 high) or (LBG down and LBG level and H1 high)]
--     and [(RWG level and H4 high) or (RBG down and RBG level and H1 high)]
--     or [(H1 low or H4 low) and nose gear compressed]
-- One main gear side on the ground leaves AIR set; both sides make GND.
local function subsystem(inp)
    local tilted, level, body_down = {}, {}, {}
    for i = 1, 4 do
        tilted[i] = inp.tilt_deg[i] > M.TILT_DEG
        level[i] = not tilted[i]
        body_down[i] = inp.down[i] >= M.DOWN_LOCKED
    end
    local h1 = inp.hyd_psi[1] >= M.HYD_HIGH_PSI
    local h4 = inp.hyd_psi[4] >= M.HYD_HIGH_PSI
    local air = (tilted[M.LWG] and tilted[M.LBG]) or (tilted[M.RWG] and tilted[M.RBG])
    local left = (level[M.LWG] and h4) or (body_down[M.LBG] and level[M.LBG] and h1)
    local right = (level[M.RWG] and h4) or (body_down[M.RBG] and level[M.RBG] and h1)
    local gnd = (left and right) or ((not h1 or not h4) and inp.nose_on_ground)
    local all_tilted = tilted[1] and tilted[2] and tilted[3] and tilted[4]
    return air, gnd, all_tilted
end

function M.update(inp)
    local air, gnd, all_tilted = subsystem(inp)
    local all_down = inp.nose_down >= M.DOWN_LOCKED
    for i = 1, 4 do
        if inp.down[i] < M.DOWN_LOCKED then all_down = false end
    end
    return {
        pri_air = air, pri_gnd = gnd,
        alt_air = air, alt_gnd = gnd,
        ng_compressed = inp.nose_on_ground,        -- separate output, ATA29_32 p.310, p.320
        all_gear_down = all_down,                  -- ALL GR DN to the warning (CONFIG GEAR), p.320
        nose_not_down = inp.nose_down < M.DOWN_LOCKED,
        -- LG LVR UNLK: all four trucks tilted and the body gear steering locked
        -- (FCOM p.1512, ATA29_32 p.224-225)
        lever_unlock = all_tilted and inp.body_steering_locked,
    }
end

return M
