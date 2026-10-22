-- Run from the repository root with LuaJIT: luajit tests/warning/alert_model_test.lua
-- The crew alerting model (plugins/xtlua/scripts/B747.87.xt.warning/B747.87.alert_model.lua)
-- against FCOM 15.10-15.20 (airplane 109): message order and pages
-- (p.1528, p.1548-1549), CANC/RCL (p.1530), master lights (p.1532, p.902),
-- and the inhibits (p.1586-1587, p.1593-1595, p.1600-1602).
local T = dofile("tests/lib/check.lua")("alert_model")
local A = dofile("plugins/xtlua/scripts/B747.87.xt.warning/B747.87.alert_model.lua")

local DT = 1 / 30
local function run(s, inp, seconds)
    local out
    for _ = 1, math.max(1, math.floor(seconds / DT + 0.5)) do out = A.update(s, inp, DT) end
    return out
end
-- one frame with a button pushed
local function push(s, inp, button)
    inp[button] = true
    local out = A.update(s, inp, DT)
    inp[button] = false
    return out
end
local function alerts(inp, list)
    inp.active = {}
    for _, a in ipairs(list) do inp.active[#inp.active + 1] = {name = a[1], level = a[2]} end
end
local function add(inp, name, level) inp.active[#inp.active + 1] = {name = name, level = level} end
local function texts(page)
    local t = {}
    for i, line in ipairs(page) do t[i] = line and line.text or "" end
    return t
end
-- in flight, engines running: no inhibit
local function flying()
    local s, inp = A.new(), A.inputs()
    inp.on_ground = false
    inp.fuel_cutoff = {false, false, false, false}
    inp.nose_gear_down = false
    inp.radio_alt, inp.ias = 10000, 300
    return s, inp
end

-- order: warnings, then cautions, then advisories, each newest first; memos
-- at the bottom of the page, newest lowest (FCOM p.1548-1549)
do
    local s, inp = flying()
    alerts(inp, {{"CABIN ALTITUDE", "warning"}, {"FUEL PRESS ENG 1", "caution"}, {"ELEC BUS ISLN 2", "advisory"},
        {"PARK BRAKE SET", "memo"}})
    run(s, inp, 1)
    add(inp, ">CONFIG GEAR", "warning")
    add(inp, "HYD PRESS SYS 1", "caution")
    add(inp, "PASS SIGNS ON", "memo")
    local out = run(s, inp, 1)
    local t = texts(out.pages[1])
    T.equal(t[1], ">CONFIG GEAR", "order: newest warning first")
    T.equal(t[2], "CABIN ALTITUDE", "order: older warning second")
    T.equal(t[3], "HYD PRESS SYS 1", "order: newest caution after the warnings")
    T.equal(t[4], "FUEL PRESS ENG 1", "order: older caution")
    T.equal(t[5], "ELEC BUS ISLN 2", "order: advisories after the cautions")
    T.equal(t[10], "PARK BRAKE SET", "order: older memo above")
    T.equal(t[11], "PASS SIGNS ON", "order: newest memo on the bottom line")
    T.equal(out.num_pages, 1, "order: one page")
    T.check(not out.show_page_number, "order: no page number on a single page")
end

-- pages: warnings on top of every page, page number with two pages or more
-- (FCOM p.1528, p.1549)
do
    local s, inp = flying()
    alerts(inp, {{"CABIN ALTITUDE", "warning"}, {">CONFIG GEAR", "warning"}, {">OVERSPEED", "warning"}})
    for i = 1, 12 do add(inp, "CAUTION " .. string.char(64 + i), "caution") end
    local out = run(s, inp, 1)
    T.equal(out.num_pages, 2, "pages: 3 warnings and 12 cautions make two pages of 11 lines")
    T.check(out.show_page_number, "pages: page number shown")
    T.equal(#out.pages[1], 11, "pages: page 1 full")
    T.equal(texts(out.pages[2])[1], texts(out.pages[1])[1], "pages: the warnings repeat on page 2")
    T.equal(#out.pages[2], 7, "pages: page 2 has the 3 warnings and 4 cautions")
    -- CANC: next page; on the last page the cautions go, warnings stay (p.1530)
    out = push(s, inp, "cancel")
    T.equal(out.page, 2, "CANC: page 2")
    out = push(s, inp, "cancel")
    T.equal(out.page, 1, "CANC on the last page: back to page 1")
    T.equal(#out.pages[1], 3, "CANC on the last page: only the warnings remain")
    T.equal(out.num_pages, 1, "CANC on the last page: one page")
    -- a caution after the cancel is shown (p.1530)
    add(inp, "NEW CAUTION", "caution")
    out = run(s, inp, 0.5)
    T.equal(texts(out.pages[1])[4], "NEW CAUTION", "after CANC: a new caution is shown")
    -- RCL: all back, page 1, RECALL while held and 1 s after (p.1528, p.1530)
    out = push(s, inp, "recall")
    T.equal(out.num_pages, 2, "RCL: the cancelled cautions are back")
    T.equal(out.page, 1, "RCL: page 1")
    T.check(out.recall, "RCL: RECALL shown")
    out = run(s, inp, 0.9)
    T.check(out.recall, "RCL: RECALL still shown 0.9 s after")
    out = run(s, inp, 0.2)
    T.check(not out.recall, "RCL: RECALL gone after 1 s")
end

-- warnings filling the page: one page, CANC does nothing (FCOM p.1549)
do
    local s, inp = flying()
    alerts(inp, {})
    for i = 1, 12 do add(inp, "WARNING " .. string.char(64 + i), "warning") end
    add(inp, "SOME CAUTION", "caution")
    local out = run(s, inp, 1)
    T.equal(out.num_pages, 1, "12 warnings: one page")
    T.check(not out.show_page_number, "12 warnings: no page number")
    out = push(s, inp, "cancel")
    T.equal(out.page, 1, "12 warnings: CANC stays on page 1")
end

-- a new caution while page 2 is shown appears on page 2, right under the
-- warnings; after RCL it is the top caution of page 1 (FCOM p.1549)
do
    local s, inp = flying()
    alerts(inp, {{"CABIN ALTITUDE", "warning"}})
    for i = 1, 12 do add(inp, "CAUTION " .. string.char(64 + i), "caution") end
    run(s, inp, 1)
    local out = push(s, inp, "cancel")
    T.equal(out.page, 2, "page 2 shown")
    add(inp, "NEW CAUTION", "caution")
    out = run(s, inp, 0.5)
    T.equal(texts(out.pages[2])[2], "NEW CAUTION", "new caution at the top of the page being viewed")
    out = push(s, inp, "recall")
    T.equal(texts(out.pages[1])[2], "NEW CAUTION", "after RCL: the newest caution heads page 1")
end

-- master lights (FCOM p.1532, p.902)
do
    local s, inp = flying()
    alerts(inp, {{"CABIN ALTITUDE", "warning"}})
    local out = run(s, inp, 0.5)
    T.check(out.master_warning, "master WARNING on a new warning")
    out = push(s, inp, "master_reset")
    T.check(not out.master_warning, "master WARNING reset")
    add(inp, ">CONFIG GEAR", "warning")
    out = run(s, inp, 0.5)
    T.check(out.master_warning, "master WARNING again on another new warning")
    alerts(inp, {})
    out = run(s, inp, 0.5)
    T.check(not out.master_warning, "master WARNING out when the warnings are gone")
    alerts(inp, {{">ENG 2 SHUTDOWN", "caution"}})
    out = run(s, inp, 0.5)
    T.check(not out.master_caution, "no master CAUTION for ENG SHUTDOWN (FCOM p.902)")
    add(inp, "HYD PRESS SYS 1", "caution")
    out = run(s, inp, 0.5)
    T.check(out.master_caution, "master CAUTION on a new caution")
    alerts(inp, {{"ELEC BUS ISLN 2", "advisory"}})
    out = run(s, inp, 0.5)
    T.check(not out.master_caution, "master CAUTION out when the cautions are gone")
end

-- before start (FCOM p.1586): on the ground with every FUEL CONTROL CUTOFF,
-- cautions show but master CAUTION stays out; the engine's own messages are
-- hidden while its FUEL CONTROL is CUTOFF
do
    local s, inp = A.new(), A.inputs()
    alerts(inp, {{"HYD PRESS SYS 1", "caution"}, {"ELEC GEN OFF 2", "advisory"}, {"ENG 3 FAIL", "caution"}})
    local out = run(s, inp, 1)
    T.equal(texts(out.pages[1])[1], "HYD PRESS SYS 1", "before start: the caution is shown")
    T.check(not out.master_caution, "before start: no master CAUTION")
    for _, line in ipairs(out.pages[1]) do
        T.check(not line or line.text ~= "ELEC GEN OFF 2", "before start: ELEC GEN OFF 2 hidden")
        T.check(not line or line.text ~= "ENG 3 FAIL", "before start: ENG FAIL hidden on the ground")
    end
    inp.fuel_cutoff[2] = false
    out = run(s, inp, 1)
    local shown = false
    for _, line in ipairs(out.pages[1]) do if line and line.text == "ELEC GEN OFF 2" then shown = true end end
    T.check(shown, "FUEL CONTROL 2 RUN: ELEC GEN OFF 2 shown")
end

-- engine start (FCOM p.1587): new cautions and advisories wait for the start
-- to end, except the start ones
do
    local s, inp = A.new(), A.inputs()
    inp.fuel_cutoff = {false, false, false, false}
    alerts(inp, {})
    run(s, inp, 1)
    inp.engine_start = true
    alerts(inp, {{"HYD PRESS SYS 2", "caution"}, {"ENG 2 START VLV", "caution"}})
    local out = run(s, inp, 1)
    local t = texts(out.pages[1])
    T.equal(t[1], "ENG 2 START VLV", "engine start: ENG START VLV shown")
    T.check(t[2] == nil or t[2] == "", "engine start: HYD PRESS SYS 2 held back")
    inp.engine_start = false
    out = run(s, inp, 0.5)
    T.equal(texts(out.pages[1])[1], "HYD PRESS SYS 2", "start over: the held caution shows, newest first")
    T.check(out.master_caution, "start over: and lights master CAUTION")
end

-- takeoff (FCOM p.1593-1595): from 80 kt a new caution does not light master
-- CAUTION until RA 400 ft; from V1 a new warning does not light master
-- WARNING until RA 400 ft or 25 s
do
    local s, inp = A.new(), A.inputs()
    inp.fuel_cutoff = {false, false, false, false}
    inp.v1 = 150
    alerts(inp, {})
    run(s, inp, 1)                               -- slow on the ground: armed
    inp.ias = 120
    alerts(inp, {{"HYD PRESS SYS 3", "caution"}})
    local out = run(s, inp, 1)
    T.check(not out.master_caution, "takeoff, 120 kt: no master CAUTION")
    T.equal(texts(out.pages[1])[1], "HYD PRESS SYS 3", "takeoff: the message itself is shown")
    inp.ias = 160
    add(inp, "CABIN ALTITUDE", "warning")
    out = run(s, inp, 1)
    T.check(not out.master_warning, "takeoff, past V1: no master WARNING")
    inp.on_ground, inp.nose_gear_down, inp.radio_alt = false, false, 200
    out = run(s, inp, 1)
    T.check(not out.master_caution and not out.master_warning, "takeoff, RA 200 ft: still inhibited")
    inp.radio_alt = 450
    out = run(s, inp, 0.5)
    T.check(out.master_caution and out.master_warning, "takeoff, RA 400 ft: master lights come on")
end

-- rejected takeoff: the warning inhibit ends 25 s after V1, the caution
-- inhibit below 75 kt (FCOM p.1594; ATA31 p.180). The same at 20 and 45 fps.
for _, fps in ipairs({20, 30, 45}) do
    local dt = 1 / fps
    local function go(s, inp, seconds)
        local out
        for _ = 1, math.floor(seconds * fps + 0.5) do out = A.update(s, inp, dt) end
        return out
    end
    local s, inp = A.new(), A.inputs()
    inp.fuel_cutoff = {false, false, false, false}
    inp.v1 = 150
    alerts(inp, {})
    go(s, inp, 1)
    inp.ias = 155
    alerts(inp, {{"CABIN ALTITUDE", "warning"}, {"HYD PRESS SYS 3", "caution"}})
    local out = go(s, inp, 24)
    T.check(not out.master_warning, fps .. " fps RTO: no master WARNING 24 s after V1")
    out = go(s, inp, 2)
    T.check(out.master_warning, fps .. " fps RTO: master WARNING 26 s after V1")
    T.check(not out.master_caution, fps .. " fps RTO: master CAUTION still inhibited above 75 kt")
    inp.ias = 70
    out = go(s, inp, 0.5)
    T.check(out.master_caution, fps .. " fps RTO: master CAUTION below 75 kt")
end

-- the landing roll above 80 kt is not a takeoff (estimate)
do
    local s, inp = flying()
    alerts(inp, {})
    run(s, inp, 1)
    inp.on_ground, inp.nose_gear_down, inp.ias, inp.radio_alt = true, true, 140, 0
    run(s, inp, 1)
    alerts(inp, {{"HYD PRESS SYS 3", "caution"}})
    local out = run(s, inp, 0.5)
    T.check(out.master_caution, "landing roll at 140 kt: master CAUTION lights")
end

-- CONFIG GEAR is hidden from lift-off to RA 800 ft or 140 s after the nose
-- gear lifted off (FCOM p.1594)
do
    local s, inp = A.new(), A.inputs()
    inp.fuel_cutoff = {false, false, false, false}
    alerts(inp, {})
    run(s, inp, 1)
    inp.ias, inp.nose_gear_down = 160, false
    run(s, inp, 1)
    inp.on_ground, inp.radio_alt = false, 300
    alerts(inp, {{">CONFIG GEAR", "warning"}})
    local out = run(s, inp, 1)
    T.check(#out.pages[1] == 0 or out.pages[1][1].text ~= ">CONFIG GEAR", "after lift-off: CONFIG GEAR hidden")
    inp.radio_alt = 900
    out = run(s, inp, 0.5)
    T.equal(texts(out.pages[1])[1], ">CONFIG GEAR", "above RA 800 ft: CONFIG GEAR shown")
end

-- landing (FCOM p.1600-1602): with LAND 2/3 below RA 200 ft, master CAUTION
-- stays out for new cautions (not for >AUTOTHROT DISC and the others) until
-- 75 kt, 40 s or a go-around
do
    local s, inp = flying()
    inp.land_2_3, inp.radio_alt, inp.ias = true, 150, 140
    alerts(inp, {})
    run(s, inp, 1)
    alerts(inp, {{"HYD PRESS SYS 4", "caution"}})
    local out = run(s, inp, 1)
    T.check(not out.master_caution, "landing, LAND 3 below 200 ft: no master CAUTION")
    add(inp, ">AUTOTHROT DISC", "caution")
    out = run(s, inp, 0.5)
    T.check(out.master_caution, "landing: >AUTOTHROT DISC still lights master CAUTION")
    push(s, inp, "master_reset")
    inp.on_ground, inp.nose_gear_down, inp.radio_alt, inp.ias = true, true, 0, 70
    out = run(s, inp, 0.5)
    T.check(not out.master_caution, "landing, below 75 kt: a reset caution stays out")
end

T.done()
