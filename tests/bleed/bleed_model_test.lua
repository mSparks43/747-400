-- Run from the repository root with LuaJIT: luajit tests/bleed/bleed_model_test.lua
-- The bleed air model (plugins/xtlua_keysystems/scripts/B747.55.xt.air/B747.55.bleed_model.lua)
-- against FCOM 2.10-2.50 and LH36: the APU bleed valve, the ducts and
-- isolation valves, starting with APU air and crossbleed, the engine valves
-- with the fire switch, the overheat latch and NAI, and the EICAS messages.
local T = dofile("tests/lib/check.lua")("bleed_model")
local B = dofile("plugins/xtlua_keysystems/scripts/B747.55.xt.air/B747.55.bleed_model.lua")

local DT = 1 / 30
local function run(s, inp, seconds, dt)
    dt = dt or DT
    local out
    for _ = 1, math.max(1, math.floor(seconds / dt + 0.5)) do out = B.update(s, inp, dt) end
    return out
end
-- parked, engines off, APU running with its bleed on, isolation valves open
local function apu_air()
    local s, inp = B.new(), B.inputs()
    inp.apu_selector, inp.apu_n1 = 1, 100
    return s, inp
end
local function engines_idle(inp)
    for n = 1, 4 do inp.n2[n], inp.fuel_run[n] = 65, true end
end

-- the APU bleed valve opens with APU RUNNING (N1 95 % for 2 s) and pressurises
-- all three sections through the isolation valves (FCOM p.575, p.897; LH36 p.88)
do
    local s, inp = apu_air()
    inp.apu_n1 = 90
    local out = run(s, inp, 5)
    T.equal(out.apu_pos, 0, "APU below 95 % N1: valve closed")
    T.check(not out.apu_light, "APU below 95 %: no command, no VALVE light")
    inp.apu_n1 = 100
    out = run(s, inp, 1.5)
    T.equal(out.apu_pos, 0, "APU: not before 2 s at 95 %")
    out = run(s, inp, 1.5)
    T.check(out.apu_light and out.apu_pos > 0 and out.apu_pos < 1, "APU: valve moving, VALVE light")
    out = run(s, inp, 5)
    T.check(not out.apu_light, "APU: valve open, VALVE light out")
    T.equal(out.apu_pos, 1, "APU: valve open")
    T.check(out.duct[1] > 40 and out.duct[2] > 40 and out.duct[3] > 40, "APU: all ducts pressurised, no packs")
    inp.packs = {true, true, true}
    out = run(s, inp, 5)
    T.check(out.duct[2] > 28, "APU: three packs keep about 30 psi (FCOM p.895)")
    -- X-Plane's APU air failure: the valve stays open, no air
    inp.apu_air_failed = true
    out = run(s, inp, 5)
    T.check(out.apu_pos == 1 and out.duct[2] < 1, "APU air failed: valve open, ducts empty")
    inp.apu_air_failed = false
    out = run(s, inp, 5)
    T.check(out.duct[2] > 28, "APU air back")
    -- selector OFF closes the valve at once (FCOM p.897)
    inp.apu_selector = 0
    out = run(s, inp, 5)
    T.equal(out.apu_pos, 0, "APU selector OFF: valve closed")
    T.check(out.duct[2] < 1, "APU selector OFF: ducts empty")
end

-- with the isolation valves closed the L and R transmitters, on the wing side,
-- read 0 with APU air only (LH36 p.94)
do
    local s, inp = apu_air()
    inp.isln_on = {false, false}
    local out = run(s, inp, 10)
    T.equal(out.isln_pos[1], 0, "ISLN L closed")
    T.check(out.duct[2] > 40, "ISLN closed: centre duct on APU air")
    T.check(out.duct[1] < 1 and out.duct[3] < 1, "ISLN closed: L and R read 0")
end

-- starting on APU air: not with the three packs on, yes with one pack
-- (FCOM p.123, p.895); the PRV opens 15 s after the start valve closes
-- (LH36 p.48)
do
    local s, inp = apu_air()
    inp.packs = {true, true, true}
    run(s, inp, 10)
    inp.start_pulled[4], inp.fuel_run[4] = true, true
    local out = run(s, inp, 5)
    T.check(not out.eng[4].start_valve_open, "start with three packs on: not enough air")
    T.check(out.eng[4].prsov_open, "start: the PRSOV opens backwards")
    inp.packs = {true, false, false}
    out = run(s, inp, 5)
    T.check(out.eng[4].start_valve_open, "start with one pack: the start valve opens")
    T.check(out.duct[3] >= 25, "start with one pack: duct holds the start pressure")
    -- the engine comes up, START drops out at 50 % N2
    inp.n2[4] = 55
    inp.start_pulled[4] = false
    out = run(s, inp, 1)
    T.check(not out.eng[4].start_valve_open, "starter cutout: start valve closed")
    inp.n2[4] = 65
    out = run(s, inp, 13)
    T.check(not out.eng[4].prv_open, "after the start: PRV still closed at 14 s")
    out = run(s, inp, 2)
    T.check(out.eng[4].prv_open and out.eng[4].prsov_open, "after the start: PRV and PRSOV open at 16 s")
    T.check(out.eng[4].psi > 50, "after the start: engine bleed air")
    T.check(not out.eng[4].off_alert, "after the start: no >BLEED 4 OFF")
end

-- three START switches pulled on APU air (manual start): one start valve
-- opens, the others wait (two starters take more than the APU gives), and
-- nothing flaps around the PRSOV's 10 psi (estimate, notes/ATA-36.md §6)
do
    local s, inp = apu_air()
    inp.autostart = false
    run(s, inp, 10)
    for n = 2, 4 do inp.start_pulled[n] = true end
    local out = run(s, inp, 5)
    local open = 0
    for n = 2, 4 do if out.eng[n].start_valve_open then open = open + 1 end end
    T.equal(open, 1, "three starts on APU air: one start valve open")
    T.check(out.duct[2] > 30, "three starts on APU air: the duct holds")
    local changes, last = 0, out.eng[3].prsov_open
    for _ = 1, 90 do
        out = B.update(s, inp, DT)
        if out.eng[3].prsov_open ~= last then changes, last = changes + 1, out.eng[3].prsov_open end
    end
    T.equal(changes, 0, "three starts on APU air: the PRSOVs stay put")
end

-- crossbleed start: a donor at idle (65 % N2) is not enough, at 70 % it is
-- (FCOM p.183)
do
    local s, inp = B.new(), B.inputs()
    inp.isln_on = {false, false}
    inp.n2[1], inp.fuel_run[1] = 65, true
    run(s, inp, 20)
    inp.start_pulled[2], inp.fuel_run[2] = true, true
    local out = run(s, inp, 5)
    T.check(not out.eng[2].start_valve_open, "crossbleed: donor at idle is not enough")
    inp.n2[1] = 70
    out = run(s, inp, 5)
    T.check(out.eng[2].start_valve_open, "crossbleed: donor at 70 % N2 starts it")
end

-- the bleed switch off with the engine running: PRSOV closed and >BLEED OFF
-- (FCOM p.619; LH36 p.68); the NAI switch still opens the PRV (FCOM p.576)
do
    local s, inp = B.new(), B.inputs()
    engines_idle(inp)
    run(s, inp, 20)
    inp.bleed_on[2] = false
    local out = run(s, inp, 1)
    T.check(not out.eng[2].prsov_open, "bleed 2 off: PRSOV closed")
    T.check(out.eng[2].off_alert, "bleed 2 off: >BLEED 2 OFF")
    T.check(not out.eng[2].prv_open and out.eng[2].psi == 0, "bleed 2 off: PRV closed")
    inp.nai_on[2] = true
    out = run(s, inp, 1)
    T.check(out.eng[2].prv_open and out.eng[2].psi > 50, "bleed 2 off, NAI on: PRV open for the nacelle")
    T.check(not out.eng[2].prsov_open, "bleed 2 off, NAI on: PRSOV still closed")
    inp.n2[2] = 20
    out = run(s, inp, 1)
    T.check(not out.eng[2].off_alert, "engine 2 below 50 % N2: no >BLEED 2 OFF")
end

-- the fire switch closes the engine valves (LH36 p.26)
do
    local s, inp = B.new(), B.inputs()
    engines_idle(inp)
    run(s, inp, 20)
    inp.fire_out[3] = true
    local out = run(s, inp, 1)
    T.check(not out.eng[3].prsov_open and not out.eng[3].prv_open and not out.eng[3].hpsov_open,
        "fire 3: PRSOV, PRV and HPSOV closed")
end

-- without its DC bus the ASCTU cannot pulse the latching solenoids: the
-- valves stay where they were, whatever the switch or the fire switch does;
-- with the power back they follow them (ATA30_32_35_36 p.20, p.66)
do
    local s, inp = B.new(), B.inputs()
    engines_idle(inp)
    run(s, inp, 20)
    inp.dc[2] = false
    local out = run(s, inp, 1)
    T.check(out.eng[2].prsov_open and out.eng[2].prv_open and out.eng[2].psi > 50,
        "DC bus 2 lost: engine 2 valves stay open")
    inp.bleed_on[2], inp.fire_out[2] = false, true
    out = run(s, inp, 1)
    T.check(out.eng[2].prsov_open and out.eng[2].prv_open, "DC bus 2 lost: the switches do nothing")
    inp.dc[2] = true
    out = run(s, inp, 1)
    T.check(not out.eng[2].prsov_open and not out.eng[2].prv_open and not out.eng[2].hpsov_open,
        "DC bus 2 back: the fire switch closes them")
end

-- overheat: latched after 5 s, SYS FAULT and BLD OVHT/PRV; reset by the
-- switch off and ON (LH36 p.100; FCOM p.612)
do
    local s, inp = B.new(), B.inputs()
    engines_idle(inp)
    run(s, inp, 20)
    inp.overheat[1] = true
    local out = run(s, inp, 4)
    T.check(not out.eng[1].sys_fault, "overheat: not before 5 s")
    out = run(s, inp, 2)
    T.check(out.eng[1].sys_fault and out.eng[1].ovht_alert, "overheat: SYS FAULT and BLD 1 OVHT/PRV")
    T.check(not out.eng[1].prsov_open, "overheat: valves closed")
    inp.overheat[1] = false
    out = run(s, inp, 2)
    T.check(out.eng[1].sys_fault, "overheat gone: stays latched")
    inp.bleed_on[1] = false
    run(s, inp, 1)
    inp.bleed_on[1] = true
    out = run(s, inp, 1)
    T.check(not out.eng[1].sys_fault and out.eng[1].prsov_open, "switch off and ON: reset")
end

-- isolation valves: about 2 s to move; without their AC bus they stay put
-- and BLEED ISLN comes after 10 s (FCOM p.619; ATA30_32_35_36 p.22)
for _, fps in ipairs({20, 30, 45}) do
    local dt = 1 / fps
    local s, inp = apu_air()
    run(s, inp, 10, dt)
    inp.isln_on[1] = false
    local out = run(s, inp, 1, dt)
    T.check(out.isln_pos[1] > 0.3 and out.isln_pos[1] < 0.7, fps .. " fps ISLN L moving at 1 s")
    T.check(out.isln_light[1], fps .. " fps ISLN L moving: VALVE light (FCOM p.576)")
    out = run(s, inp, 2, dt)
    T.equal(out.isln_pos[1], 0, fps .. " fps ISLN L closed")
    T.check(not out.isln_light[1], fps .. " fps ISLN L closed: VALVE light out")
    T.check(not out.isln_alert[1], fps .. " fps ISLN L: no BLEED ISLN L")
    inp.ac[3] = false
    inp.isln_on[2] = false
    out = run(s, inp, 9, dt)
    T.equal(out.isln_pos[2], 1, fps .. " fps ISLN R without AC bus 3 stays open")
    T.check(not out.isln_alert[2], fps .. " fps ISLN R: no message at 9 s")
    out = run(s, inp, 2, dt)
    T.check(out.isln_alert[2], fps .. " fps ISLN R: BLEED ISLN R at 11 s")
end

-- the APU valve needs DC bus 2 for its command and AC bus 2 to move;
-- >BLEED ISLN APU after 10 s of disagreement (LH36 p.89; ATA30_32_35_36 p.28)
do
    local s, inp = apu_air()
    inp.ac[2] = false
    local out = run(s, inp, 12)
    T.check(out.apu_valve_cmd and out.apu_pos == 0, "APU valve without AC bus 2: commanded, not moving")
    out = run(s, inp, 1)
    T.check(out.apu_alert, "APU valve: >BLEED ISLN APU")
    inp.ac[2], inp.dc[2] = true, false
    out = run(s, inp, 1)
    T.check(not out.apu_valve_cmd, "APU valve without DC bus 2: no command")
end

-- BLEED ASCTU A, B (status): channel A without DC bus 1, B without DC bus 3,
-- for 20 s (ATA30_32_35_36 p.16; LH36 p.92)
do
    local s, inp = B.new(), B.inputs()
    run(s, inp, 1)
    inp.dc[3] = false
    local out = run(s, inp, 19)
    T.check(not out.asctu_alert[2], "ASCTU B: not before 20 s")
    out = run(s, inp, 2)
    T.check(out.asctu_alert[2] and not out.asctu_alert[1], "ASCTU B after 20 s without DC bus 3, not A")
    inp.dc[3] = true
    out = run(s, inp, 0.1)
    T.check(not out.asctu_alert[2], "ASCTU B gone with DC bus 3 back")
end

T.done()
