-- 747-400 electrical power (ATA 24) without X-Plane: the power sources, the
-- breakers between them (GCB, BTB, SSB, XPC, APB, DCIR), the buses, the
-- panel lights and the EICAS conditions.
-- Logic and sources: docs/overhaul/notes/ATA-24.md (FCOM 6.10-6.30 and the
-- Lufthansa B1 ATA 24 manual, "LH24"). Reference airplane: FCOM 109.
-- Simplified as the notes §6 allow: no voltages or frequencies (a source is
-- good or not), paralleling is instant, no protective trips (no failures yet),
-- load shedding from the generator count instead of currents.
--
--   local E = B747_elec_model            -- in XTLua, after dofile
--   local E = dofile(".../B747.03.elec_model.lua")   -- in the tests
--   local s = E.new()
--   local inp = E.inputs()                -- fill it every frame
--   local out = E.update(s, inp, dt)      -- also kept in s.out

local M = setmetatable({}, {})
B747_elec_model = M

-- IDG on line (no underspeed) and BCU air mode, % N2 (N3 for RR), by
-- laminar/B747/engines/type: 0 PW, 1 GE, 2 RR. LH24 p.66 (4525 and 6100 rpm).
M.IDG_ONLINE_N2 = {[0] = 54.3, 55.3, 50.0}
M.AIR_MODE_N2 = {[0] = 73.3, 74.6, 67.4}
M.APU_READY_N1 = 95            -- APU generator power ready, LH24 p.146
M.XFR_TO_ALT_S = 0.18          -- transfer bus to AC 1 after 180 ms without its source, LH24 p.228
M.XFR_BACK_S = 1.2             -- and back 1.2 s after its source returns
M.APU_START_RELAY_S = 65       -- APU inverter off while the APU starts, LH24 p.158-159
M.SHED_STEP_S = 1              -- one ELCU shed or restored per second, LH24 p.236
M.BAT_DISCH_AMPS = 2           -- BAT DISCH from 2 A, LH24 p.200 (page 198)
M.BAT_DISCH_DELAY_S = 60       -- estimate: FCOM SP.6.3 (p.181) says "up to 3 minutes"
M.BAT_AH = 40                  -- 24 V 40 Ah NiCd, main and APU, LH24 p.190
M.CHARGE_AMPS = {38, 35}       -- charger current limit, main and APU, LH24 p.192-196
M.CHARGER_VOLTS = 27.75
-- Estimates (no source gives the loads): what a battery supplies when its
-- hot battery bus carries them. Chosen so that a battery keeps its standby
-- bus for about an hour; FCOM p.804 asks for at least 30 minutes.
M.LOAD_AMPS = {
    main_battery_bus = 12, main_inverter = 28, main_apu_start = 10,
    apu_battery_bus = 8, apu_inverter = 15, apu_starter = 250,
}
-- ELCU shed order (galley 1-4, utility 1-4), LH24 p.236
M.SHED_ORDER = {{"galley", 1}, {"galley", 4}, {"galley", 2}, {"galley", 3},
    {"utility", 1}, {"utility", 4}, {"utility", 2}, {"utility", 3}}

local L, R = 1, 2
local SIDE = {L, L, R, R}             -- sync bus side of AC bus / IDG 1-4
local ON_SIDE = {{1, 2}, {3, 4}}

local function count(t, n)
    local c = 0
    for i = 1, n do if t[i] then c = c + 1 end end
    return c
end

local function flags(n, v)
    local t = {}
    for i = 1, n do t[i] = v end
    return t
end

-- What the cockpit and the engines give the model each frame.
function M.inputs()
    return {
        engine_type = 0,
        battery = false,                 -- BATTERY switch ON
        stby_power = 1,                  -- STANDBY POWER selector: 0 OFF, 1 AUTO, 2 BAT
        utility = {false, false},        -- L, R UTILITY ON
        bus_tie = flags(4, true),        -- BUS TIE AUTO
        gen_cont = flags(4, true),       -- GEN CONT ON
        drive_disc = flags(4, false),    -- DRIVE DISC switch pushed (latched by its handler)
        ext_request = {false, false},    -- EXT PWR 1/2 close request (laminar/B747/elec_ext_pwr_N/switch_mode)
        apu_request = {false, false},    -- APU GEN 1/2 close request (laminar/B747/apu_pwr_N/switch_mode)
        ext_available = {false, false},  -- external power plugged in and good
        apu_n1 = 0,
        apu_start = false,               -- the APU starter runs
        n2 = {0, 0, 0, 0},
        on_ground = true,
        fire_handle = flags(4, false),   -- engine fire switch pulled: trips the GCR, LH24 p.108
    }
end

function M.new()
    local bat = function() return {ah = M.BAT_AH, amps = 0, volts = 0, disch_s = 0} end
    return {
        gcb = flags(4, false), btb = flags(4, false), ssb = false,
        xpc = {false, false}, apb = {false, false}, dcir = flags(4, false),
        permit = flags(4, true),         -- GCB close permission latch, LH24 p.102
        gen_cont_prev = flags(4, false),
        idg_connected = flags(4, true),
        drive_disc_prev = flags(4, false),
        ext_request_prev = {false, false}, apu_request_prev = {false, false},
        xfr = {capt = {alt = false, t = 0}, fo = {alt = false, t = 0}},
        shed = 0, shed_t = 0,            -- ELCUs shed so far (from the front of SHED_ORDER)
        apu_start_prev = false, apu_start_relay = 0,
        bat = {main = bat(), apu = bat()},
        out = nil,
    }
end

-- An XPC or APB (EXT or APU on side k) or an IDG through its BTB feeds sync
-- bus side k. Returns "ext"/"apu"/"idg" or nil.
local function side_source(s, k, good)
    if s.xpc[k] then return "ext" end
    if s.apb[k] then return "apu" end
    for _, n in ipairs(ON_SIDE[k]) do
        if s.gcb[n] and s.btb[n] and good[n] then return "idg" end
    end
    return nil
end

-- EXT or APU connected to the system that sync bus side k is part of.
local function external_on_system(s, k)
    if s.xpc[k] or s.apb[k] then return true end
    return s.ssb and (s.xpc[3 - k] or s.apb[3 - k])
end

-- A new EXT/APU source takes side k: the IDGs feeding that side through
-- their BTB lose their GCB and its permission latch, and the other external
-- source of that side is cut. LH24 p.102 (latch), p.123 (figure 64).
local function take_side(s, k, out)
    for _, n in ipairs(ON_SIDE[k]) do
        if s.btb[n] and s.gcb[n] then
            s.gcb[n] = false
            s.permit[n] = false
        end
    end
    if s.xpc[k] then s.xpc[k] = false; out.clear_ext[k] = true end
    if s.apb[k] then s.apb[k] = false; out.clear_apu[k] = true end
end

-- Close XPC/APB k for a new source, following the transfer table of LH24
-- p.123: when the same kind of source is available for the other side and
-- the other side has a source of its own, the SSB opens and the new source
-- takes its side only (FCOM p.796-797). Otherwise it takes everything it is
-- connected to.
local function connect(s, kind, k, other_same_available, good, out)
    if s.ssb and other_same_available and side_source(s, 3 - k, good) then
        s.ssb = false
        take_side(s, k, out)
    else
        take_side(s, k, out)
        if s.ssb then take_side(s, 3 - k, out) end
    end
    if kind == "ext" then s.xpc[k] = true else s.apb[k] = true end
end

-- An IDG came on line through its BTB: the EXT/APU sources it is connected
-- to drop out (LH24 p.102: BCU told to open them; p.123 last row).
local function idg_online(s, n, out)
    if not s.btb[n] then return end
    local k = SIDE[n]
    local sides = s.ssb and {k, 3 - k} or {k}
    for _, j in ipairs(sides) do
        if s.xpc[j] then s.xpc[j] = false; out.clear_ext[j] = true end
        if s.apb[j] then s.apb[j] = false; out.clear_apu[j] = true end
    end
end

-- Transfer bus (IBVSU, LH24 p.228): to AC 1 when the normal source has been
-- lost for 180 ms, back 1.2 s after it returns; without DC 1 (its control
-- power) it stays on, or returns to, the normal source. Returns its power.
local function transfer(x, normal, alternate, dc1, dt)
    if not dc1 then
        x.alt, x.t = false, 0
    elseif not x.alt then
        x.t = normal and 0 or x.t + dt
        if x.t >= M.XFR_TO_ALT_S then x.alt, x.t = true, 0 end
    else
        x.t = normal and x.t + dt or 0
        if x.t >= M.XFR_BACK_S then x.alt, x.t = false, 0 end
    end
    if x.alt then return alternate end
    return normal
end

-- A battery for one frame: charged by its charger (current limited, the
-- charger voltage shown), else discharged by its load. Amps + = discharge.
local function battery_step(b, charger, load, limit, dt)
    if charger then
        b.amps = -math.min(limit, (M.BAT_AH - b.ah) * 10)
        b.volts = M.CHARGER_VOLTS
    else
        b.amps = (b.ah > 0) and load or 0
        local soc = b.ah / M.BAT_AH
        b.volts = (b.ah > 0) and math.max(0, 22 + 3 * soc - 0.004 * b.amps) or 0   -- estimate
    end
    b.ah = math.max(0, math.min(M.BAT_AH, b.ah - b.amps * dt / 3600))
end

-- BAT DISCH: discharging at 2 A or more for the EIU delay.
local function discharging(b, inhibit, dt)
    if b.amps >= M.BAT_DISCH_AMPS and not inhibit then
        b.disch_s = b.disch_s + dt
    else
        b.disch_s = 0
    end
    return b.disch_s >= M.BAT_DISCH_DELAY_S
end

-- SSB after the sources have settled (LH24 p.120; FCOM p.796-797): closed when
-- one side feeds both, or both sides have IDGs (paralleled); open when the
-- sides have separate EXT/APU sources or different kinds, and with no source.
local function settle_ssb(s, good)
    local a, b = side_source(s, L, good), side_source(s, R, good)
    if a and b then
        s.ssb = (a == "idg" and b == "idg")
    else
        s.ssb = (a ~= nil or b ~= nil)
    end
end

-- One frame. dt in seconds.
function M.update(s, inp, dt)
    local out = {clear_ext = {false, false}, clear_apu = {false, false}}
    local prev = s.out or {bat_bus = {main = false, apu = false}, dc = flags(4, false)}
    local online_n2 = M.IDG_ONLINE_N2[inp.engine_type] or M.IDG_ONLINE_N2[0]
    local air_n2 = M.AIR_MODE_N2[inp.engine_type] or M.AIR_MODE_N2[0]

    -- sources ------------------------------------------------------------
    local speed = {}
    local fast = 0
    for n = 1, 4 do
        speed[n] = inp.n2[n] >= online_n2
        if inp.n2[n] >= air_n2 then fast = fast + 1 end
    end
    local air_mode = (not inp.on_ground) or fast >= 3          -- LH24 p.66
    out.air_mode = air_mode

    -- IDG drive: DRIVE DISC disconnects the IDG when the engine is at or above
    -- idle and the disconnect has power (FCOM p.785-786: main battery bus).
    -- Pushed below idle it does nothing here (the real disconnect is
    -- incomplete: estimate). Reconnected on the ground when the switch flag is
    -- reset (the maintenance reset).
    for n = 1, 4 do
        local pushed = inp.drive_disc[n] and not s.drive_disc_prev[n]
        if pushed and s.idg_connected[n] and speed[n] and prev.bat_bus.main then
            s.idg_connected[n] = false
        elseif not inp.drive_disc[n] and s.drive_disc_prev[n] and inp.on_ground then
            s.idg_connected[n] = true
        end
        s.drive_disc_prev[n] = inp.drive_disc[n]
    end
    out.drive_disc_flag = {}
    for n = 1, 4 do out.drive_disc_flag[n] = not s.idg_connected[n] end

    -- GCR closes with GEN CONT ON; DRIVE DISC and the fire switch open it
    -- (LH24 p.108). Good power: GCR closed and no underspeed (LH24 p.66, p.102).
    local good = {}
    for n = 1, 4 do
        local gcr = inp.gen_cont[n] and s.idg_connected[n] and not inp.fire_handle[n]
        good[n] = gcr and speed[n]
    end
    local apu_ready = inp.apu_n1 > M.APU_READY_N1 and inp.on_ground   -- ground only, FCOM p.895
    local ext_ok = {inp.ext_available[1] and true or false, inp.ext_available[2] and true or false}

    -- breakers -------------------------------------------------------------
    for n = 1, 4 do
        s.btb[n] = inp.bus_tie[n]                                   -- FCOM p.785, LH24 p.104
        s.dcir[n] = inp.bus_tie[n]                                  -- FCOM p.819
        if s.gcb[n] and not good[n] then s.gcb[n] = false end       -- GEN CONT OFF, underspeed, GCR trip
    end
    for k = 1, 2 do
        if s.xpc[k] and not (ext_ok[k] and inp.ext_request[k]) then
            s.xpc[k] = false
            if not ext_ok[k] then out.clear_ext[k] = true end
        end
        if s.apb[k] and not (apu_ready and inp.apu_request[k]) then
            s.apb[k] = false
            if not apu_ready then out.clear_apu[k] = true end
        end
    end

    -- GCB (LH24 p.102): the permission latch sets on underspeed, GEN CONT
    -- OFF->ON, BTB open, or when its sync bus is dead or fed by IDGs only
    -- (no EXT/APU on its system). With it, a good IDG closes its GCB and the
    -- EXT/APU it is connected to drop out. Done before the SSB settles, so an
    -- IDG whose side lost its EXT/APU takes the side back (dead bus) instead
    -- of the SSB handing it to the other side's source.
    for n = 1, 4 do
        local cycled = inp.gen_cont[n] and not s.gen_cont_prev[n]
        if not speed[n] or cycled or not s.btb[n] or not external_on_system(s, SIDE[n]) then
            s.permit[n] = true
        end
        s.gen_cont_prev[n] = inp.gen_cont[n]
        if good[n] and s.permit[n] and not s.gcb[n] then
            s.gcb[n] = true
            idg_online(s, n, out)
        end
    end
    settle_ssb(s, good)

    -- EXT/APU switch pushed to connect (FCOM p.783-784): a new request, taken
    -- only when available and not in air mode (LH24 p.218, p.148). A request
    -- that stays set after its breaker tripped does not reconnect. EXT and
    -- APU never share a side.
    for k = 1, 2 do
        if inp.ext_request[k] and not s.ext_request_prev[k] and not s.xpc[k] then
            if ext_ok[k] and not air_mode then
                if s.apb[k] then s.apb[k] = false; out.clear_apu[k] = true end
                connect(s, "ext", k, ext_ok[3 - k], good, out)
            else
                out.clear_ext[k] = true
            end
        end
        if inp.apu_request[k] and not s.apu_request_prev[k] and not s.apb[k] then
            if apu_ready and not air_mode then
                if s.xpc[k] then s.xpc[k] = false; out.clear_ext[k] = true end
                connect(s, "apu", k, apu_ready, good, out)
            else
                out.clear_apu[k] = true
            end
        end
        s.ext_request_prev[k] = inp.ext_request[k]
        s.apu_request_prev[k] = inp.apu_request[k]
    end
    settle_ssb(s, good)

    -- AC buses ---------------------------------------------------------------
    local own = {side_source(s, L, good) ~= nil, side_source(s, R, good) ~= nil}
    local sync = {own[L] or (s.ssb and own[R]), own[R] or (s.ssb and own[L])}
    local ac = {}
    for n = 1, 4 do
        ac[n] = (s.gcb[n] and good[n]) or (s.btb[n] and sync[SIDE[n]])
    end

    -- DC: TRU n on AC n; DCIR to the DC tie bus (FCOM p.819, LH24 p.166)
    local tru = {}
    local tie = false
    for n = 1, 4 do
        tru[n] = ac[n]
        if tru[n] and s.dcir[n] then tie = true end
    end
    local dc = {}
    for n = 1, 4 do dc[n] = tru[n] or (s.dcir[n] and tie) end
    local single_tru = count(tru, 4) == 1                           -- R7225, LH24 p.184

    local xfr_capt = transfer(s.xfr.capt, ac[3], ac[1], dc[1], dt)
    local xfr_fo = transfer(s.xfr.fo, ac[2], ac[1], dc[1], dt)

    -- ground service and ground handling (FCOM p.799, LH24 p.214-216). The
    -- ground service switch on the door 2L panel is not modelled: GSB from AC 1.
    local gsb = ac[1]
    local ghb = inp.on_ground and not air_mode and (ext_ok[1] or apu_ready)

    -- batteries, hot battery buses, battery buses (FCOM p.819-820; LH24
    -- p.155, p.182, p.192-196)
    local bm, ba = s.bat.main, s.bat.apu
    local stby = inp.stby_power
    local main_charger = gsb and stby ~= 2
    local apu_charger = gsb and stby ~= 2 and not inp.apu_start
    local hot_main = main_charger or bm.ah > 0
    local hot_apu = apu_charger or ba.ah > 0
    local r7224 = dc[3] and stby ~= 2 and ac[3] and not single_tru
    local bat_bus_main = (r7224 and dc[3]) or (not r7224 and inp.battery and hot_main)
    local bat_bus_apu = (r7224 and dc[3]) or (not r7224 and inp.battery and hot_apu)

    -- standby (109): main standby from AC 3 or the main inverter, APU standby
    -- from CAPT XFR or the APU inverter; nothing with the selector OFF; only
    -- the inverters at BAT. The APU inverter stops for 65 s when the APU
    -- starts. FCOM p.780-781, p.803-804; LH24 p.150-159.
    if inp.apu_start and not s.apu_start_prev then s.apu_start_relay = M.APU_START_RELAY_S end
    s.apu_start_prev = inp.apu_start
    s.apu_start_relay = math.max(0, s.apu_start_relay - dt)
    local main_inv_in = r7224 or (inp.battery and hot_main)
    local apu_inv_in = inp.battery and hot_apu and s.apu_start_relay <= 0
    local main_from_inv = (stby == 2) or (stby == 1 and not ac[3])
    local apu_from_inv = (stby == 2) or (stby == 1 and not xfr_capt)
    local stby_main = stby ~= 0 and ((stby == 1 and ac[3]) or (main_from_inv and main_inv_in))
    local stby_apu = stby ~= 0 and ((stby == 1 and xfr_capt) or (apu_from_inv and apu_inv_in))
    local main_inv_on = stby_main and main_from_inv and not r7224
    local apu_inv_on = stby_apu and apu_from_inv

    -- battery currents (+ discharge) and charge
    local A = M.LOAD_AMPS
    local main_load = 0
    if not r7224 and inp.battery then main_load = main_load + A.main_battery_bus end
    if main_inv_on then main_load = main_load + A.main_inverter end
    if inp.apu_start and inp.battery then main_load = main_load + A.main_apu_start end
    local apu_load = 0
    if not r7224 and inp.battery then apu_load = apu_load + A.apu_battery_bus end
    if apu_inv_on then apu_load = apu_load + A.apu_inverter end
    if inp.apu_start and inp.battery then apu_load = apu_load + A.apu_starter end
    battery_step(bm, main_charger, main_load, M.CHARGE_AMPS[1], dt)
    battery_step(ba, apu_charger, apu_load, M.CHARGE_AMPS[2], dt)

    -- utility and galley buses (109): ELCUs behind the UTILITY switches,
    -- shed one a second in SHED_ORDER and restored in reverse, by the number
    -- of generators on line (LH24 p.236-242, simplified as notes §6 allows).
    local gens = count(s.gcb, 4)
    local externals = count(s.xpc, 2) + count(s.apb, 2)
    local target = 0
    if gens == 2 then
        target = 3                                  -- utility and galley 3 stay
    elseif gens <= 1 and air_mode and externals == 0 then
        target = #M.SHED_ORDER
    end
    if s.shed == target then
        s.shed_t = 0
    else
        s.shed_t = s.shed_t + dt
        if s.shed_t >= M.SHED_STEP_S then
            s.shed = s.shed + ((target > s.shed) and 1 or -1)
            s.shed_t = 0
        end
    end
    local shed = {galley = flags(4, false), utility = flags(4, false)}
    for i = 1, s.shed do
        local u = M.SHED_ORDER[i]
        shed[u[1]][u[2]] = true
    end
    local util, galley = {}, {}
    for n = 1, 4 do
        local sw = inp.utility[SIDE[n]]
        util[n] = ac[n] and sw and not shed.utility[n]
        galley[n] = ac[n] and sw and not shed.galley[n]
    end

    -- outputs ----------------------------------------------------------------
    out.ac, out.dc, out.tru, out.util, out.galley = ac, dc, tru, util, galley
    out.sync = sync
    out.dc_tie = tie
    out.xfr = {capt = xfr_capt, fo = xfr_fo}
    out.stby = {main = stby_main, apu = stby_apu}
    out.gsb, out.gs_util = gsb, gsb and inp.utility[L]
    out.ghb, out.gh_dc = ghb, ghb
    out.bat_bus = {main = bat_bus_main, apu = bat_bus_apu}
    out.hot_bat_bus = {main = hot_main, apu = hot_apu}
    out.battery = {
        main = {volts = bm.volts, amps = bm.amps, ah = bm.ah},
        apu = {volts = ba.volts, amps = ba.amps, ah = ba.ah},
    }
    out.gcb, out.btb, out.ssb = {}, {}, s.ssb
    out.xpc, out.apb, out.dcir = {s.xpc[1], s.xpc[2]}, {s.apb[1], s.apb[2]}, {}
    for n = 1, 4 do out.gcb[n], out.btb[n], out.dcir[n] = s.gcb[n], s.btb[n], s.dcir[n] end
    out.idg_connected = {}
    for n = 1, 4 do out.idg_connected[n] = s.idg_connected[n] end
    out.load_shed = s.shed > 0

    -- panel lights (FCOM p.781-786)
    local lt = {ext_avail = {}, ext_on = {}, apu_avail = {}, apu_on = {},
        isln = {}, gen_off = {}, drive = {}, util_off = {}}
    for k = 1, 2 do
        lt.ext_avail[k] = ext_ok[k] and not s.xpc[k]
        lt.ext_on[k] = s.xpc[k]
        lt.apu_avail[k] = apu_ready and not s.apb[k]
        lt.apu_on[k] = s.apb[k]
        lt.util_off[k] = not inp.utility[k]
    end
    local drive_low = {}
    for n = 1, 4 do
        lt.isln[n] = not s.btb[n]
        lt.gen_off[n] = not s.gcb[n]
        -- IDG oil pressure builds with input speed: estimate, low below the
        -- on-line speed (DRIVE lights on before start, FCOM p.104 NP.21.10)
        drive_low[n] = not (s.idg_connected[n] and speed[n])
        lt.drive[n] = drive_low[n]
    end
    lt.battery_off = not inp.battery
    out.lights = lt

    -- EICAS (FCOM p.821-823). Levels: ELEC AC BUS caution, the rest advisory
    -- (109). ELEC GEN OFF and ELEC BUS ISLN n are not shown while ELEC AC BUS
    -- n is (FCOM p.802 for ISLN; estimate for GEN OFF).
    local cas = {ac_bus = {}, gen_off = {}, bus_isln = {}, drive = {}, drive_disc = {}}
    for n = 1, 4 do
        cas.ac_bus[n] = not ac[n]
        cas.gen_off[n] = not s.gcb[n] and ac[n]
        cas.bus_isln[n] = not s.btb[n] and ac[n]
        -- ELEC DRIVE: DRIVE light with the engine running and the IDG
        -- connected (LH24 p.72-73); never in normal operation here
        cas.drive[n] = drive_low[n] and speed[n] and s.idg_connected[n]
        cas.drive_disc[n] = not s.idg_connected[n]
    end
    cas.ssb_open = false
    cas.util_bus = {}
    for k = 1, 2 do cas.util_bus[k] = not inp.utility[k] and s.shed == 0 end
    cas.stby_bus_main = not stby_main
    cas.stby_bus_apu = not stby_apu
    cas.bat_disch_main = discharging(bm, false, dt)
    cas.bat_disch_apu = discharging(ba, inp.apu_start, dt)
    cas.battery_off = not inp.battery
    out.cas = cas

    -- X-Plane stand-ins (notes §6): X-Plane's electrics only serve its own
    -- instruments, autopilot and sounds; cross tie stays closed
    out.xp = {
        battery_on = inp.battery,
        gpu_on = s.xpc[1] or s.xpc[2],
        apu_gen_on = s.apb[1] or s.apb[2],
        generator_on = {s.gcb[1], s.gcb[2], s.gcb[3], s.gcb[4]},
        ac_power = ac[1] or ac[2] or ac[3] or ac[4],
    }

    s.out = out
    return out
end

return M
