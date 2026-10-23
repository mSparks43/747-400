-- 747-400 bleed air without X-Plane: the valves of the four engines (HPSOV,
-- PRV, PRSOV), the start valves, the left, centre and right ducts with the
-- L and R isolation valves, the APU bleed valve and ground air, the duct
-- pressures from what the sources give and the users take, and the P5
-- lights and EICAS messages of the system. Logic and sources:
-- docs/overhaul/notes/ATA-36.md §2-§4 (FCOM 2.10-2.50, LH36, ATA30_32_35_36).
--
--   local B = B747_bleed_model             -- in XTLua, after dofile
--   local B = dofile(".../B747.55.bleed_model.lua")   -- in the tests
--   local s = B.new()
--   local inp = B.inputs()                 -- fill it every frame
--   local out = B.update(s, inp, dt)       -- the same table every frame

local M = setmetatable({}, {})
B747_bleed_model = M

M.PRSOV_REG_PSI = 45            -- PRSOV regulates the duct side (LH36 p.64)
M.PRSOV_MIN_PSI = 10            -- PRSOV needs 10 psi to open (LH36 p.74)
M.PRV_START_DELAY_S = 15        -- PRV opens 15 s after the start valve closed (LH36 p.48)
M.OVHT_DELAY_S = 5              -- overheat switch (LH36 p.100)
M.DISAGREE_S = 10               -- BLEED ISLN L/R, >BLEED ISLN APU (ATA30_32_35_36 p.22, p.28)
M.ASCTU_BUS, M.ASCTU_DELAY_S = {1, 3}, 20  -- BLEED ASCTU A, B (status): channel A on DC bus 1,
                                -- B on DC bus 3, 20 s without (ATA30_32_35_36 p.16; LH36 p.92)
M.APU_N1, M.APU_DELAY_S = 95, 2 -- APU bleed valve: N1 95 % + 2 s (LH36 p.88-89)
M.N2_RUNNING = 50               -- >BLEED n OFF with the engine above 50 % N2 (LH36 p.68)
M.START_SL_PSI, M.START_PER_KFT = 25, 1   -- start air needed: estimate from FCOM p.183 (30 psi
                                -- of ground air at sea level, 1 psi less per 1,000 ft)

-- estimates: the sources give no numbers for these (notes/ATA-36.md §6).
-- Flow is in "packs": one pack at normal flow is 1.0.
M.ENG_PSI_N2 = {25, 65}         -- engine bleed (PRV side) from 0 at 25 % N2 to full at 65 %
M.ENG_FULL_PSI = 60
M.ENG_CAP_N2 = {50, 90}         -- engine flow: 0 at 50 % N2, M.ENG_CAP_MAX at 90 %
M.ENG_CAP_MAX = 4.0             -- 1.5 at idle (65 %), 2.0 at 70 %: a crossbleed start needs the
                                -- donor at about 70 % N2 (FCOM p.183)
M.APU_PSI, M.APU_CAP = 42, 3.2  -- the APU runs all three packs, not three packs and a start
                                -- (FCOM p.895)
M.GND_CAP = 3.0                 -- ground air cart
M.STARTER_FLOW = 1.8
M.WAI_FLOW, M.ADP_FLOW = 0.5, 0.3
M.DROOP = 0.3                   -- the duct falls by 30 % from no flow to full flow
M.DUCT_LAG_S = 1.0
M.ISLN_TRAVEL_S, M.APU_TRAVEL_S = 2, 2    -- motor valves (no value in the sources)

-- sections: 1 left (engines 1, 2, pack 1), 2 centre (APU, ground air,
-- pack 2), 3 right (engines 3, 4, pack 3) (FCOM p.611-615)
M.ENGINE_SECTION = {1, 1, 3, 3}

function M.inputs()
    return {
        bleed_on = {true, true, true, true},       -- ENGINE BLEED switches
        fire_out = {false, false, false, false},   -- engine fire switches
        n2 = {0, 0, 0, 0},                         -- %
        nai_on = {false, false, false, false},     -- NAI switches
        start_pulled = {false, false, false, false},
        autostart = true,                          -- AUTOSTART switch
        fuel_run = {false, false, false, false},   -- FUEL CONTROL RUN
        overheat = {false, false, false, false},   -- failure: bleed overheat
        isln_on = {true, true},                    -- L, R isolation switches
        apu_bleed_on = true,
        apu_selector = 0,                          -- 0 OFF, 1 ON, 2 START
        apu_n1 = 0,                                -- %
        apu_fire_out = false,
        apu_air_failed = false,                    -- failure: the APU gives no air
        ground_air_psi = 0,                        -- a connected air cart
        dc = {true, true, true, true},             -- DC bus 1-4 (ASCTU, APU valve control)
        ac = {true, true, true, true},             -- AC bus 1-4 (ISLN, APU valve motors)
        packs = {false, false, false},             -- packs 1-3 taking air
        wai = {false, false},                      -- wing anti-ice valves L, R
        adp = {false, false},                      -- demand pumps 1 (left) and 4 (right)
        altitude = 0,                              -- ft
    }
end

function M.new()
    local s = {t = 0, first = true, eng = {}, isln = {1, 1}, apu_pos = 0, apu_ready_t = 0,
        duct = {0, 0, 0}, isln_disagree_t = {0, 0}, apu_disagree_t = 0, demand = {0, 0, 0},
        target = {0, 0, 0},
        -- per section, its group (index) and the group's pressure, flow and use
        grp = {1, 1, 1}, grp_psi = {0, 0, 0}, grp_cap = {0, 0, 0}, grp_use = {0, 0, 0},
        asctu_t = {0, 0}}
    local out = {eng = {}, isln_pos = {1, 1}, apu_pos = 0, duct = {0, 0, 0},
        isln_alert = {false, false}, apu_alert = false, apu_valve_cmd = false,
        isln_light = {false, false}, apu_light = false, asctu_alert = {false, false}}
    for n = 1, 4 do
        s.eng[n] = {ovht_t = 0, ovht_latch = false, last_on = true, start_closed_t = M.PRV_START_DELAY_S,
            start_open = false, hpsov_cmd = true, prv_cmd = true, prsov_cmd = true}
        out.eng[n] = {psi = 0, prsov_open = false, prv_open = false, hpsov_open = false,
            start_valve_open = false, start_cmd = false, off_alert = false, sys_fault = false,
            ovht_alert = false, forward = false}
    end
    s.out = out
    return s
end

local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function ramp(x, from, to) return clamp((x - from) / (to - from), 0, 1) end

local function travel(pos, target, seconds, dt, powered)
    if not powered then return pos end
    local step = dt / seconds
    if pos < target then return math.min(target, pos + step) end
    return math.max(target, pos - step)
end

-- the pressure a group of sections holds: its highest source pressure,
-- falling by M.DROOP as the use reaches what the sources give, and fast
-- beyond (estimate, notes/ATA-36.md §6)
local function duct_psi(psi, cap, use)
    if cap <= 0 then return 0 end
    if use <= cap then return psi * (1 - M.DROOP * use / cap) end
    return psi * (1 - M.DROOP) * (cap / use) ^ 2
end

-- the groups of sections the isolation valves join: GROUPS[L open][R open]
local GROUPS = {
    [true] = {[true] = {{1, 2, 3}}, [false] = {{1, 2}, {3}}},
    [false] = {[true] = {{1}, {2, 3}}, [false] = {{1}, {2}, {3}}},
}

function M.update(s, inp, dt)
    s.t = s.t + dt
    local out = s.out
    local start_need = math.max(0, M.START_SL_PSI - M.START_PER_KFT * inp.altitude / 1000)

    -- isolation valves: the switch drives the motor (L on AC bus 1, R on AC
    -- bus 3); without power the valve stays where it is (LH36 p.86-87)
    s.isln[1] = travel(s.isln[1], inp.isln_on[1] and 1 or 0, M.ISLN_TRAVEL_S, dt, inp.ac[1])
    s.isln[2] = travel(s.isln[2], inp.isln_on[2] and 1 or 0, M.ISLN_TRAVEL_S, dt, inp.ac[3])

    -- APU bleed valve: switch ON with APU RUNNING (selector ON or START, N1
    -- 95 % for 2 s), no APU fire; motor on AC bus 2, control on DC bus 2
    -- (FCOM p.575, p.897; LH36 p.88-89)
    if inp.apu_n1 >= M.APU_N1 and inp.apu_selector > 0 then
        s.apu_ready_t = s.apu_ready_t + dt
    else
        s.apu_ready_t = 0
    end
    local apu_cmd = inp.apu_bleed_on and s.apu_ready_t >= M.APU_DELAY_S and not inp.apu_fire_out and inp.dc[2]
    out.apu_valve_cmd = apu_cmd
    s.apu_pos = travel(s.apu_pos, apu_cmd and 1 or 0, M.APU_TRAVEL_S, dt, inp.ac[2])

    -- the start commands: START pulled (with AUTOSTART, once the FUEL CONTROL
    -- is RUN); the PRSOV opens backwards to let duct air to the start valve
    -- with the bleed switch ON and the fire switch in (FCOM p.612, p.862,
    -- p.879; LH36 p.64, p.74)
    local prev = s.duct
    for n = 1, 4 do
        local se, oe = s.eng[n], out.eng[n]
        local sect = M.ENGINE_SECTION[n]
        oe.start_cmd = inp.start_pulled[n] and (not inp.autostart or inp.fuel_run[n])
        se.reverse = inp.bleed_on[n] and not inp.fire_out[n] and inp.start_pulled[n] and inp.dc[n]
            and prev[sect] >= M.PRSOV_MIN_PSI
    end

    -- duct pressure of each group of sections: the highest source pressure,
    -- falling as the users take what the sources give; an open start valve
    -- takes the starter's flow (estimate, notes/ATA-36.md §6)
    local demand = s.demand
    for p = 1, 3 do demand[p] = inp.packs[p] and 1 or 0 end
    if inp.wai[1] then demand[1] = demand[1] + M.WAI_FLOW end
    if inp.wai[2] then demand[3] = demand[3] + M.WAI_FLOW end
    if inp.adp[1] then demand[1] = demand[1] + M.ADP_FLOW end
    if inp.adp[2] then demand[3] = demand[3] + M.ADP_FLOW end
    for n = 1, 4 do
        if s.eng[n].start_open then
            demand[M.ENGINE_SECTION[n]] = demand[M.ENGINE_SECTION[n]] + M.STARTER_FLOW
        end
    end
    local target = s.target
    for gi, g in ipairs(GROUPS[s.isln[1] > 0.5][s.isln[2] > 0.5]) do
        local cap, psi, use = 0, 0, 0
        for _, sect in ipairs(g) do
            use = use + demand[sect]
            for n = 1, 4 do
                local oe = out.eng[n]
                if M.ENGINE_SECTION[n] == sect and oe.forward then   -- last frame's valve
                    cap = cap + M.ENG_CAP_MAX * ramp(inp.n2[n], M.ENG_CAP_N2[1], M.ENG_CAP_N2[2])
                    psi = math.max(psi, math.min(M.PRSOV_REG_PSI, oe.psi))
                end
            end
            if sect == 2 then
                if s.apu_pos > 0.5 and inp.apu_n1 > 0 and not inp.apu_air_failed then
                    cap = cap + M.APU_CAP * s.apu_pos
                    psi = math.max(psi, M.APU_PSI)
                end
                if inp.ground_air_psi > 0 then
                    cap = cap + M.GND_CAP
                    psi = math.max(psi, inp.ground_air_psi)
                end
            end
        end
        for _, sect in ipairs(g) do
            target[sect] = duct_psi(psi, cap, use)
            s.grp[sect], s.grp_psi[sect], s.grp_cap[sect], s.grp_use[sect] = gi, psi, cap, use
        end
    end
    for i = 1, 3 do
        if s.first then s.duct[i] = target[i]
        else s.duct[i] = s.duct[i] + (target[i] - s.duct[i]) * math.min(1, dt / M.DUCT_LAG_S) end
        out.duct[i] = s.duct[i]
    end

    -- the engine valves (notes/ATA-36.md §4.1)
    for n = 1, 4 do
        local se, oe = s.eng[n], out.eng[n]
        local sect = M.ENGINE_SECTION[n]
        local on, fire = inp.bleed_on[n], inp.fire_out[n]
        local asctu = inp.dc[n]
        -- overheat latch in the ASCTU, reset by the switch going off and ON
        -- (LH36 p.100, FCOM p.612)
        if asctu then
            if inp.overheat[n] then se.ovht_t = se.ovht_t + dt else se.ovht_t = 0 end
            if se.ovht_t >= M.OVHT_DELAY_S then se.ovht_latch = true end
            if on and not se.last_on then se.ovht_latch = false end
            se.last_on = on
        end

        -- the start valve opens when the duct would still hold the start
        -- pressure with this starter's flow added, and stays open until the
        -- command ends or the duct is lost (estimate: the sources give no
        -- starter numbers)
        if oe.start_cmd and se.reverse then
            if not se.start_open
                and duct_psi(s.grp_psi[sect], s.grp_cap[sect], s.grp_use[sect] + M.STARTER_FLOW) >= start_need then
                se.start_open = true
                for k = 1, 3 do     -- another start in this frame sees this one
                    if s.grp[k] == s.grp[sect] then s.grp_use[k] = s.grp_use[k] + M.STARTER_FLOW end
                end
            end
            if s.duct[sect] < M.PRSOV_MIN_PSI then se.start_open = false end
        else
            se.start_open = false
        end
        oe.start_valve_open = se.start_open
        if se.start_open then se.start_closed_t = 0 else se.start_closed_t = se.start_closed_t + dt end

        -- the ASCTU pulses the latching open and close solenoids of the HPSOV,
        -- PRV and PRSOV; without its DC bus each keeps its last position
        -- (ATA30_32_35_36 p.20, p.54, p.66; LH36 p.74). It closes them with
        -- the fire switch and the HPSOV and PRV with the overheat latch, keeps
        -- the PRV closed while the start valve is open and 15 s after, and
        -- opens the PRV for the NAI switch with the bleed switch off (FCOM
        -- p.576, p.612; LH36 p.26, p.48, p.53). Power back: they follow the
        -- switches again (simplified: the ASCTU pulses on switch changes).
        if asctu then
            local ok = not fire and not se.ovht_latch
            se.hpsov_cmd = ok and on
            se.prv_cmd = ok and (on or inp.nai_on[n]) and se.start_closed_t >= M.PRV_START_DELAY_S
            se.prsov_cmd = on and not fire
        end
        oe.hpsov_open = se.hpsov_cmd and inp.n2[n] < 85  -- HP port at low power (estimate)
        oe.prv_open = se.prv_cmd
        if oe.prv_open then
            oe.psi = M.ENG_FULL_PSI * ramp(inp.n2[n], M.ENG_PSI_N2[1], M.ENG_PSI_N2[2])
        else
            oe.psi = 0
        end
        -- PRSOV: forward when commanded open while the engine side is above
        -- the duct (no flow back, 0.13 psi), or back to the starter
        -- (LH36 p.64-76)
        oe.forward = se.prsov_cmd and oe.psi >= M.PRSOV_MIN_PSI
            and math.min(M.PRSOV_REG_PSI, oe.psi) + 0.13 >= s.duct[sect]
        oe.prsov_open = oe.forward or se.reverse
        oe.off_alert = not on and inp.n2[n] > M.N2_RUNNING and not oe.prsov_open
        oe.sys_fault = se.ovht_latch
        oe.ovht_alert = se.ovht_latch
    end

    -- VALVE lights: moving or not where commanded (FCOM p.576; LH36 p.78);
    -- after 10 s, BLEED ISLN L/R and >BLEED ISLN APU (ATA30_32_35_36 p.22, p.28)
    for i = 1, 2 do
        local want = inp.isln_on[i] and 1 or 0
        out.isln_light[i] = s.isln[i] ~= want
        if out.isln_light[i] then s.isln_disagree_t[i] = s.isln_disagree_t[i] + dt
        else s.isln_disagree_t[i] = 0 end
        out.isln_alert[i] = s.isln_disagree_t[i] >= M.DISAGREE_S
        out.isln_pos[i] = s.isln[i]
    end
    out.apu_light = s.apu_pos ~= (apu_cmd and 1 or 0)
    if out.apu_light then s.apu_disagree_t = s.apu_disagree_t + dt
    else s.apu_disagree_t = 0 end
    out.apu_alert = s.apu_disagree_t >= M.DISAGREE_S
    out.apu_pos = s.apu_pos

    -- BLEED ASCTU A, B: a channel without its DC bus for 20 s
    for c = 1, 2 do
        if inp.dc[M.ASCTU_BUS[c]] then s.asctu_t[c] = 0 else s.asctu_t[c] = s.asctu_t[c] + dt end
        out.asctu_alert[c] = s.asctu_t[c] >= M.ASCTU_DELAY_S
    end

    s.first = false
    return out
end

return M
