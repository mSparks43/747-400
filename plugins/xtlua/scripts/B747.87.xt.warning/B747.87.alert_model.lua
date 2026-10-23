-- 747-400 crew alerting without X-Plane: the EICAS message list (order,
-- pages, CANC/RCL), the master WARNING/CAUTION lights, the aural each
-- warning asks for, and the inhibits of FCOM 15.20 for airplane 109. Logic
-- and sources: docs/overhaul/notes/ATA-31-warning.md §3.1-3.4, §4.1, §4.2,
-- §4.4. The sound files (fmod/747-400_custom.snd, the same as the local
-- 747-400.snd) play out.aural (bell, siren, wailer) and the beeper from
-- out.caution_beep, through the datarefs B747.87.xt.alerts.lua writes.
--
--   local A = B747_alert_model            -- in XTLua, after dofile
--   local A = dofile(".../B747.87.alert_model.lua")   -- in the tests
--   local s = A.new()
--   local inp = A.inputs()                -- fill it every frame
--   local out = A.update(s, inp, dt)

local M = setmetatable({}, {})
B747_alert_model = M

M.LINES = 11
M.RECALL_SHOW_S = 1          -- RECALL stays 1 s after RCL is released, FCOM p.1528
-- The STATUS cue waits from engine start until 30 min after lift-off, and
-- from RA 800 ft until 75 kt on landing (FCOM p.1593, p.1600)
M.STATUS_CUE_AFTER_LIFTOFF_S = 1800
M.STATUS_CUE_LANDING_RA, M.STATUS_CUE_LANDING_IAS = 800, 75

-- Message classes, matched on the name without its caret and engine number
-- ("ENG 1 FAIL" and "ELEC GEN OFF 1" both give their class).
-- Hidden on the ground while that engine's FUEL CONTROL is CUTOFF or its fire
-- switch is out (FCOM p.1586):
M.PRESTART_HIDDEN = {["ELEC GEN OFF"] = true, ["ENG CONTROL"] = true, ["ENG SHUTDOWN"] = true,
    ["ENG EEC MODE"] = true, ["ENG FAIL"] = true, ["ENG OIL PRESS"] = true, ["HYD PRESS ENG"] = true,
    ["NAI VALVE"] = true}
-- Still shown during an engine start (FCOM p.1587):
M.START_SHOWN = {["BLEED"] = true, ["ENG AUTOSTART"] = true, ["ENG FUEL VALVE"] = true,
    ["ENG SHUTDOWN"] = true, ["ENG START VLV"] = true, ["STARTER CUTOUT"] = true}
-- Cautions that do not light master CAUTION (FCOM p.902, p.1552):
M.NO_MASTER_CAUTION = {["ENG SHUTDOWN"] = true}
-- Advisories that sound the beeper, without master CAUTION (FCOM p.619):
M.ADVISORY_BEEPER = {["BLEED HP ENG"] = true, ["BLEED ISLN L"] = true, ["BLEED ISLN R"] = true}
-- Cautions that still light master CAUTION during the landing inhibit
-- (FCOM p.1600-1602):
M.LANDING_SHOWN = {["AUTOPILOT"] = true, ["AUTOTHROT DISC"] = true, ["NO AUTOLAND"] = true,
    ["SPEEDBRAKES EXT"] = true}

-- The aural of each warning (FCOM p.1550-1552, airplane 109 before the SB;
-- notes/ATA-31-warning.md §3.4). The bell and the resettable siren stop on
-- a master reset, the other siren only when the condition goes. CONFIG GEAR
-- caused by a closed thrust lever is resettable, by the flaps it is not: the
-- message does not say which, so it is taken as not resettable (estimate).
M.BELL = {["FIRE APU"] = true, ["FIRE CARGO AFT"] = true, ["FIRE CARGO FWD"] = true,
    ["FIRE ENG"] = true, ["FIRE WHEEL WELL"] = true}
M.SIREN_RESETTABLE = {["CABIN ALTITUDE"] = true}
M.SIREN = {["CONFIG FLAPS"] = true, ["CONFIG GEAR"] = true, ["CONFIG GEAR CTR"] = true,
    ["CONFIG PARK BRK"] = true, ["CONFIG SPOILERS"] = true, ["CONFIG STAB"] = true,
    ["OVERSPEED"] = true}
-- The wailer sounds at least 1 s; the autopilot ends the message (second
-- push of the disconnect switch or re-engaging, FCOM p.1550, p.655).
M.WAILER = {["AUTOPILOT DISC"] = true}
M.WAILER_MIN_S = 1

-- the class and engine number (1-4 or nil) of a message name
function M.classify(name)
    local bare = name:gsub("^>", "")
    local engine = tonumber(bare:match("%f[%d]([1-4])%f[%D]"))
    local class = bare:gsub("%s*%f[%d][1-4]%f[%D]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return class, engine
end

function M.inputs()
    return {
        -- the alerts whose condition is true now: {name = "...", level =
        -- "warning"|"caution"|"advisory"|"memo"}
        active = {},
        cancel = false, recall = false,          -- CANC and RCL pushed this frame
        recall_held = false,                     -- RCL held down
        master_reset = false,                    -- master WARNING/CAUTION reset pushed
        on_ground = true,                        -- PSEU
        fuel_cutoff = {true, true, true, true},  -- FUEL CONTROL CUTOFF
        fire_switch_out = {false, false, false, false},
        engine_start = false,                    -- an engine start is in progress (START pulled
                                                 -- until idle, abort or 5 min: FCOM p.1587)
        ias = 0, v1 = 0,                         -- kt; v1 0 = not set
        pitch = 0,                               -- deg, for the takeoff inhibit without V1
        radio_alt = 0,                           -- ft
        nose_gear_down = true,                   -- NG compressed (PSEU)
        land_2_3 = false,                        -- LAND 2 or LAND 3 on the PFD
        status_active = {},                      -- the STATUS messages raised now (names)
        status_page_shown = false,               -- the STATUS page on the secondary EICAS
    }
end

function M.new()
    return {
        t = 0,
        -- name -> {level, since, new, hidden, held (engine start), cancelled,
        -- pending (waits for a takeoff or landing inhibit to end), announced
        -- (lit its master light), silenced (master reset after that)}
        seen = {},
        order = {},           -- caution and advisory names in display order
        page = 1,
        recall_s = 0,
        master_warning = false, master_caution = false,
        wailer_until = 0,
        takeoff_armed = false,   -- slow on the ground since the last flight
        to_caution = false, to_rotated_at = nil,
        to_warning = false, to_warning_at = nil,
        liftoff_at = nil, nose_liftoff_at = nil, was_on_ground = true,
        landing_at = nil,
        -- STATUS: name -> {since, viewed (shown on the STATUS page)}; the cue
        -- windows: since engine start, flown since then, landing
        status_seen = {},
        status_start = false, status_flown = false, status_landing = false,
        out = nil,
    }
end

-- Inhibit windows of this frame. FCOM p.1586-1587, p.1593-1595, p.1600-1602.
local function phases(s, inp)
    local ph = {}
    local all_cutoff = inp.fuel_cutoff[1] and inp.fuel_cutoff[2] and inp.fuel_cutoff[3] and inp.fuel_cutoff[4]
    ph.prestart_caution = inp.on_ground and all_cutoff             -- master CAUTION and beeper
    ph.engine_start = inp.engine_start

    -- the takeoff inhibits arm on a takeoff roll only: the aircraft has been
    -- slow on the ground since it last flew (estimate; the landing roll
    -- passes 80 kt the other way)
    if inp.on_ground and inp.ias < 30 then s.takeoff_armed = true end
    if not inp.on_ground then s.takeoff_armed = false end

    -- takeoff, master CAUTION: from 80 kt to RA 400 ft or 20 s after
    -- rotation; after a rejected takeoff above 80 kt, until below 75 kt
    if s.takeoff_armed and inp.ias >= 80 and not s.to_caution then s.to_caution = true end
    if s.to_caution then
        if inp.on_ground and not inp.nose_gear_down and not s.to_rotated_at then s.to_rotated_at = s.t end
        if (inp.on_ground and inp.ias < 75) or (not inp.on_ground and inp.radio_alt > 400)
                or (s.to_rotated_at and s.t - s.to_rotated_at > 20) then
            s.to_caution, s.to_rotated_at = false, nil
        end
    end
    -- takeoff, master WARNING (siren and bell): from V1 (or 5 deg of pitch
    -- without V1) to RA 400 ft or 25 s later (ATA31 p.180, p.196)
    local at_v1 = (inp.v1 > 0 and inp.ias >= inp.v1) or (inp.v1 <= 0 and inp.pitch > 5)
    if s.takeoff_armed and inp.on_ground and at_v1 and not s.to_warning_at then
        s.to_warning, s.to_warning_at = true, s.t
    end
    if s.to_warning and ((not inp.on_ground and inp.radio_alt > 400) or s.t - s.to_warning_at > 25) then
        s.to_warning = false
    end
    if inp.on_ground and inp.ias < 30 then s.to_warning, s.to_warning_at = false, nil end
    ph.to_caution = s.to_caution
    ph.to_warning = s.to_warning

    -- lift-off and nose gear lift-off, for the message inhibits
    if s.was_on_ground and not inp.on_ground then s.liftoff_at = s.t end
    if inp.on_ground then s.liftoff_at = nil end
    if inp.nose_gear_down then s.nose_liftoff_at = nil
    elseif not s.nose_liftoff_at then s.nose_liftoff_at = s.t end
    s.was_on_ground = inp.on_ground
    -- messages hidden: CONFIG GEAR from lift-off to RA 800 ft or 140 s after
    -- the nose gear lifted off; ENG FAIL on the ground; TCAS OFF on the
    -- ground and below RA 400 ft; WINDSHEAR SYS from 80 kt to RA 400 ft and
    -- back
    ph.config_gear_hidden = s.liftoff_at ~= nil and inp.radio_alt <= 800
        and s.nose_liftoff_at ~= nil and s.t - s.nose_liftoff_at <= 140
    ph.eng_fail_hidden = inp.on_ground
    ph.tcas_off_hidden = inp.on_ground or inp.radio_alt < 400
    ph.windshear_sys_hidden = (inp.on_ground and inp.ias >= 80) or (not inp.on_ground and inp.radio_alt < 400)

    -- landing, master CAUTION: from LAND 2/3 below RA 200 ft until 75 kt,
    -- 40 s, or a go-around through RA 800 ft
    if not s.landing_at and inp.land_2_3 and not inp.on_ground and inp.radio_alt <= 200 then
        s.landing_at = s.t
    end
    if s.landing_at and ((inp.on_ground and inp.ias < 75) or s.t - s.landing_at > 40
            or (not inp.on_ground and inp.radio_alt > 800)) then
        s.landing_at = nil
    end
    ph.landing_caution = s.landing_at ~= nil

    -- STATUS cue: from engine start, taken as a FUEL CONTROL in RUN on the
    -- ground (estimate), until 30 min after lift-off, or until all are
    -- CUTOFF again on the ground; after a flight a new start begins it
    -- again. And from RA 800 ft until 75 kt on landing (FCOM p.1593, p.1600).
    if inp.on_ground then
        if all_cutoff then s.status_flown, s.status_start = false, false
        elseif not s.status_flown then s.status_start = true end
        if inp.ias < M.STATUS_CUE_LANDING_IAS then s.status_landing = false end
    else
        s.status_flown = true
        if s.liftoff_at and s.t - s.liftoff_at >= M.STATUS_CUE_AFTER_LIFTOFF_S then s.status_start = false end
        s.status_landing = not s.status_start and inp.radio_alt < M.STATUS_CUE_LANDING_RA
    end
    ph.status_cue_inhibit = s.status_start or s.status_landing
    return ph
end

-- whether a message is hidden from the list now
local function hidden(name, ph, inp)
    local class, engine = M.classify(name)
    if engine and M.PRESTART_HIDDEN[class] and inp.on_ground
            and (inp.fuel_cutoff[engine] or inp.fire_switch_out[engine]) then
        return true
    end
    if class == "ENG FAIL" and ph.eng_fail_hidden then return true end
    if class == "CONFIG GEAR" and ph.config_gear_hidden then return true end
    if class == "TCAS OFF" and ph.tcas_off_hidden then return true end
    if class == "WINDSHEAR SYS" and ph.windshear_sys_hidden then return true end
    return false
end

-- cautions and advisories: cautions first, each newest first
local function alert_order(s)
    return function(a, b)
        local ra, rb = s.seen[a], s.seen[b]
        if ra.level ~= rb.level then return ra.level == "caution" end
        if ra.since ~= rb.since then return ra.since > rb.since end
        return a < b
    end
end

-- the pages shown: warnings on top of every page, then the page's share of
-- cautions and advisories; memos fill the last page from the bottom, newest
-- lowest (FCOM p.1528, p.1548-1549). Memos that do not fit get a page of
-- their own (estimate: FCOM does not say).
local function layout(warnings, list, memos)
    local W = math.min(#warnings, M.LINES)
    local per_page = M.LINES - W
    local alert_pages = (per_page <= 0) and 1 or math.max(1, math.ceil(#list / per_page))
    local pages = {}
    for p = 1, alert_pages do
        local lines = {}
        for i = 1, W do lines[#lines + 1] = {text = warnings[i], level = "warning"} end
        if per_page > 0 then
            for i = (p - 1) * per_page + 1, math.min(#list, p * per_page) do
                lines[#lines + 1] = {text = list[i].name, level = list[i].level}
            end
        end
        pages[p] = lines
    end
    if per_page > 0 and #memos > 0 then
        local last = pages[#pages]
        if M.LINES - #last < #memos then
            last = {}
            for i = 1, W do last[#last + 1] = {text = warnings[i], level = "warning"} end
            pages[#pages + 1] = last
        end
        local first_memo = math.max(1, #memos - (M.LINES - #last) + 1)
        local blanks = M.LINES - #last - (#memos - first_memo + 1)
        for _ = 1, blanks do last[#last + 1] = false end
        for i = first_memo, #memos do last[#last + 1] = {text = memos[i], level = "memo"} end
    end
    return pages, per_page
end

function M.update(s, inp, dt)
    s.t = s.t + dt
    local ph = phases(s, inp)

    -- new and cleared alerts ---------------------------------------------
    local now = {}
    for _, a in ipairs(inp.active) do now[a.name] = a.level end
    for name in pairs(s.seen) do
        if not now[name] then s.seen[name] = nil end
    end
    for name, level in pairs(now) do
        local rec = s.seen[name]
        if not rec then
            -- a new caution/advisory during an engine start waits for its end
            local held = ph.engine_start and (level == "caution" or level == "advisory")
                and not M.START_SHOWN[(M.classify(name))]
            rec = {level = level, since = s.t, new = true, held = held, cancelled = false}
            s.seen[name] = rec
        elseif rec.held and not ph.engine_start then
            rec.held, rec.since, rec.new = false, s.t, true
        end
        rec.hidden = rec.held or hidden(name, ph, inp)
    end

    -- master lights (FCOM p.1532). During the takeoff and landing inhibits a
    -- new alert does not light them, and lights them when the inhibit ends if
    -- still there (FCOM p.1594-1595); during the pre-start inhibit it does not
    -- light master CAUTION at all. The beeper sounds for each caution that
    -- lights master CAUTION, also when it is lit already (FCOM p.1552), and
    -- for the advisories of M.ADVISORY_BEEPER, which wait out the same
    -- inhibits (estimate: FCOM gives no inhibits for them).
    local beep = false
    local function announce(name, rec)
        rec.announced, rec.pending = true, false
        if rec.level == "warning" then
            s.master_warning = true
            if M.WAILER[(M.classify(name))] then s.wailer_until = s.t + M.WAILER_MIN_S end
        elseif rec.level == "caution" then
            s.master_caution, beep = true, true
        else
            beep = true
        end
    end
    for name, rec in pairs(s.seen) do
        if not rec.hidden then
            local class = M.classify(name)
            -- lights a master light or sounds the beeper
            local calls = rec.level == "warning" or (rec.level == "caution" and not M.NO_MASTER_CAUTION[class])
                or (rec.level == "advisory" and M.ADVISORY_BEEPER[class])
            local inhibited
            if rec.level == "warning" then
                inhibited = ph.to_warning and class ~= "CONFIG GEAR"
            else
                inhibited = ph.to_caution or (ph.landing_caution and not M.LANDING_SHOWN[class])
            end
            if rec.new then
                rec.new = false
                if calls then
                    if inhibited then
                        rec.pending = true
                    elseif rec.level == "warning" or not ph.prestart_caution then
                        announce(name, rec)
                    end
                end
            elseif rec.pending and not inhibited then
                announce(name, rec)
            end
        end
    end
    if inp.master_reset then
        s.master_warning, s.master_caution = false, false
        for _, rec in pairs(s.seen) do
            rec.pending = false
            if rec.announced then rec.silenced = true end
        end
    end
    local any_warning, any_caution = false, false
    for _, rec in pairs(s.seen) do
        if not rec.hidden and rec.level == "warning" then any_warning = true end
        if not rec.hidden and rec.level == "caution" then any_caution = true end
    end
    if not any_warning then s.master_warning = false end
    if not any_caution then s.master_caution = false end

    -- the aurals of the warnings shown (FCOM p.1550-1552)
    local bell, siren = false, false
    local wailer = s.t < s.wailer_until
    for name, rec in pairs(s.seen) do
        if rec.announced and not rec.hidden and rec.level == "warning" then
            local class = M.classify(name)
            if M.BELL[class] and not rec.silenced then bell = true end
            if M.SIREN[class] or (M.SIREN_RESETTABLE[class] and not rec.silenced) then siren = true end
            if M.WAILER[class] then wailer = true end
        end
    end

    -- the list ---------------------------------------------------------------
    local warnings, memos = {}, {}
    for name, rec in pairs(s.seen) do
        if not rec.hidden and rec.level == "warning" then warnings[#warnings + 1] = name end
        if not rec.hidden and rec.level == "memo" then memos[#memos + 1] = name end
    end
    table.sort(warnings, function(a, b)
        if s.seen[a].since ~= s.seen[b].since then return s.seen[a].since > s.seen[b].since end
        return a < b
    end)
    table.sort(memos, function(a, b)       -- oldest first: the newest is the lowest line
        if s.seen[a].since ~= s.seen[b].since then return s.seen[a].since < s.seen[b].since end
        return a < b
    end)
    local per_page = M.LINES - math.min(#warnings, M.LINES)

    -- cautions and advisories keep their place between frames; new ones go
    -- to the top of the page being looked at (FCOM p.1549)
    local list = {}
    local listed = {}
    for _, name in ipairs(s.order) do
        local rec = s.seen[name]
        if rec and not rec.hidden and not rec.cancelled and rec.level ~= "warning" and rec.level ~= "memo" then
            list[#list + 1] = name
            listed[name] = true
        end
    end
    local fresh = {}
    for name, rec in pairs(s.seen) do
        if not listed[name] and not rec.hidden and not rec.cancelled
                and (rec.level == "caution" or rec.level == "advisory") then
            fresh[#fresh + 1] = name
        end
    end
    table.sort(fresh, alert_order(s))
    if #fresh > 0 then
        local at = #list + 1
        if per_page > 0 then at = math.min(at, (s.page - 1) * per_page + 1) end
        for i = #fresh, 1, -1 do table.insert(list, at, fresh[i]) end
    end

    local function entries(names)
        local e = {}
        for i, name in ipairs(names) do e[i] = {name = name, level = s.seen[name].level} end
        return e
    end
    local pages = layout(warnings, entries(list), memos)

    -- CANC: next page, and on the last page the cautions and advisories go
    -- (warnings and memos stay). RCL: everything back, in order, page 1.
    -- With warnings filling the page, CANC does nothing. (FCOM p.1530, p.1549)
    if inp.recall then
        for _, rec in pairs(s.seen) do rec.cancelled = false end
        list = {}
        for name, rec in pairs(s.seen) do
            if not rec.hidden and (rec.level == "caution" or rec.level == "advisory") then list[#list + 1] = name end
        end
        table.sort(list, alert_order(s))
        s.page = 1
        pages = layout(warnings, entries(list), memos)
    elseif inp.cancel and per_page > 0 then
        if s.page < #pages then
            s.page = s.page + 1
        else
            for _, name in ipairs(list) do s.seen[name].cancelled = true end
            list = {}
            s.page = 1
            pages = layout(warnings, {}, memos)
        end
    end
    if inp.recall or inp.recall_held then
        s.recall_s = M.RECALL_SHOW_S
    else
        s.recall_s = math.max(0, s.recall_s - dt)
    end
    s.order = list
    if s.page > #pages then s.page = #pages end
    local cancelled = false
    for _, rec in pairs(s.seen) do
        if rec.cancelled and not rec.hidden then cancelled = true end
    end

    -- STATUS messages: the newest on top, 11 lines a page; the cue while one
    -- has not been shown on the STATUS page, outside its inhibits (FCOM
    -- p.1528, p.1545, p.1549)
    local status_now = {}
    for _, name in ipairs(inp.status_active) do status_now[name] = true end
    for name in pairs(s.status_seen) do
        if not status_now[name] then s.status_seen[name] = nil end
    end
    local status_list = {}
    for name in pairs(status_now) do
        local rec = s.status_seen[name]
        if not rec then
            rec = {since = s.t, viewed = false}
            s.status_seen[name] = rec
        end
        if inp.status_page_shown then rec.viewed = true end
        status_list[#status_list + 1] = name
    end
    table.sort(status_list, function(a, b)
        local ra, rb = s.status_seen[a], s.status_seen[b]
        if ra.since ~= rb.since then return ra.since > rb.since end
        return a < b
    end)
    local status_pages = {}
    for p = 1, math.max(1, math.ceil(#status_list / M.LINES)) do
        local lines = {}
        for i = (p - 1) * M.LINES + 1, math.min(#status_list, p * M.LINES) do lines[#lines + 1] = status_list[i] end
        status_pages[p] = lines
    end
    local status_cue = false
    if not ph.status_cue_inhibit then
        for _, rec in pairs(s.status_seen) do
            if not rec.viewed then status_cue = true end
        end
    end

    local out = {
        pages = pages,
        page = s.page,
        num_pages = #pages,
        show_page_number = #pages > 1,
        recall = s.recall_s > 0,
        cancelled = cancelled,        -- cautions or advisories hidden by CANC
        master_warning = s.master_warning,
        master_caution = s.master_caution,
        caution_beep = beep,          -- a caution lit master CAUTION in this update
        aural = {bell = bell, siren = siren, wailer = wailer},
        status_pages = status_pages,  -- lists of names, 11 a page
        status_num_pages = #status_pages,
        status_cue = status_cue,
        phases = ph,
    }
    s.out = out
    return out
end

return M
