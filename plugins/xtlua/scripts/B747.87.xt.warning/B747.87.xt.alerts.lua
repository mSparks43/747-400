-- The crew alerting model (B747.87.alert_model.lua) in the aircraft: reads
-- the messages the systems raise in laminar/B747/CAS/*_status, each with the
-- level it has in the message tables of B747.87.xt.warning.lua, the CANC and
-- RCL pushes (counted by fltInst02), the master reset pushes (counted by the
-- manipulators) and the inputs of the inhibits; runs the model 10 times a
-- second and writes the EICAS lines, the page, the master lights, the 1 s
-- caution pulse and the aural requests, and the STATUS page lines and cue.
-- B747.87.xt.warning.lua loads it after its message tables and bindings and
-- uses their bindings (binding a number dataref again under the same name
-- would write 0 to it).
-- The panel draws page p, line n from CAS/gen_<level>_msg_NNN with
-- NNN = 11 (p - 1) + n - 1 (the custom acf pages 1-10, the stock acf 1-2),
-- and the STATUS page the same way from CAS/gen_status_msg_NNN (custom acf).
dofile("B747.87.alert_model.lua")
local A = B747_alert_model

B747DR_CAS_canc_count           = find_dataref("laminar/B747/CAS/canc_count")
B747DR_CAS_rcl_count            = find_dataref("laminar/B747/CAS/rcl_count")
B747DR_master_reset_count       = find_dataref("laminar/B747/warning/master_reset_count")
B747DR_alert_rcl_switch_pos     = find_dataref("laminar/B747/dsp/rcl/switch_pos")
B747DR_alert_pseu_air           = find_dataref("laminar/B747/gear/air_ground/pri_air")
B747DR_alert_ng_compressed      = find_dataref("laminar/B747/gear/air_ground/ng_compressed")
B747DR_alert_fuel_control       = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")
B747DR_alert_toggle_switch      = find_dataref("laminar/B747/toggle_switch/position")
B747DR_alert_fire_handle_1      = find_dataref("laminar/B747/fire/engine01/ext_switch/pos_arm")
B747DR_alert_fire_handle_2      = find_dataref("laminar/B747/fire/engine02/ext_switch/pos_arm")
B747DR_alert_fire_handle_3      = find_dataref("laminar/B747/fire/engine03/ext_switch/pos_arm")
B747DR_alert_fire_handle_4      = find_dataref("laminar/B747/fire/engine04/ext_switch/pos_arm")
B747DR_alert_V1                 = find_dataref("laminar/B747/airspeed/V1")
B747DR_alert_afds_status        = find_dataref("laminar/B747/autopilot/AFDS/status_annun_pilot")
simDR_alert_engine_N2           = find_dataref("sim/flightmodel/engine/ENGN_N2_")
simDR_alert_pitch               = find_dataref("sim/flightmodel/position/theta")
simDR_alert_radio_alt           = find_dataref("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot")
-- the STATUS page: shown on the secondary EICAS, paged by the STAT switch
-- (fltInst02, in the other plugin)
B747DR_alert_synoptic_display   = find_dataref("laminar/B747/dsp/synoptic_display")
B747DR_STAT_msg_page            = find_dataref("laminar/B747/STAT/msg_page")
B747DR_STAT_num_msg_pages       = find_dataref("laminar/B747/STAT/num_msg_pages")

local ALERT_PERIOD_S = 0.1     -- estimate: the sources give no rate (the old code ran every 2 s)
local START_MAX_S = 300        -- the start inhibit ends 5 min after START is pulled (FCOM p.1587)
local START_IDLE_N2 = 60       -- %, estimate: min idle is 61.6 % N2 on the CF6 (ATA70_80 p.206),
                               -- no value for the PW; starter cutout is at 50 %
local START_SWITCH = 16        -- toggle_switch/position[16-19]: START 1-4 pulled
local SLOTS = 110              -- CAS/gen_*_msg_000-109: 10 pages of 11 lines
local LEVELS = {"warning", "caution", "advisory", "memo"}
local STATUS_PAGE = 2          -- dsp/synoptic_display: the STATUS page
local STATUS_CUE_TEXT = "STATUS"

-- every message of the tables: the status array it is raised in, its slot,
-- and the entry handed to the model (its level may differ from the array's,
-- e.g. ENG FAIL is raised as a warning and is a caution: FCOM p.899)
-- (B747_alert_messages holds the tables, B747.87.xt.warning.lua)
local messages = {}
local function add_messages(list, array)
    for i = 1, #list do
        local m = list[i]
        messages[#messages + 1] = {array = array, index = m.DRindex,
            entry = {name = m.name, level = m.level or array}}
    end
end
add_messages(B747_alert_messages.warning, "warning")
add_messages(B747_alert_messages.caution, "caution")
add_messages(B747_alert_messages.advisory, "advisory")
add_messages(B747_alert_messages.memo, "memo")
-- the STATUS messages: their slot in CAS/status_status and their name
local status_messages = {}
for i = 1, #B747_alert_messages.status do
    local m = B747_alert_messages.status[i]
    status_messages[#status_messages + 1] = {index = m.DRindex, name = m.name}
end

local alert_state = A.new()
local alert_inputs = A.inputs()
local alert_period = 0
local alert_time = 0
local alert_on = false
local caution_audio_until = 0
local start_since = {}         -- engine -> time START was pulled, while its start runs
local start_over = {}          -- engine -> its start ended with START still pulled
local counts = {}              -- last value of each push counter
local pushes = {cancel = 0, recall = 0, master_reset = 0}
local shown = {warning = {}, caution = {}, advisory = {}, memo = {}, status = {}}   -- text written per slot
local arrays = {}

local function flag(v)
    if v then return 1 end
    return 0
end

-- pushes since the last frame; a counter that goes back (a new aircraft
-- load) counts none
local function count_pushes(key, value)
    local last = counts[key]
    counts[key] = value
    if last == nil or value <= last then return end
    pushes[key] = pushes[key] + (value - last)
end

-- an engine start runs from pulling START until the engine reaches idle,
-- the start is aborted (START in and FUEL CONTROL CUTOFF) or 5 min pass
-- (FCOM p.1587); a START left pulled starts no new one
local function engine_start(t)
    local any = false
    for n = 1, 4 do
        local pulled = B747DR_alert_toggle_switch[START_SWITCH + n - 1] > 0.5
        local run = B747DR_alert_fuel_control[n - 1] > 0.5
        if not pulled then start_over[n] = nil end
        if pulled and not start_since[n] and not start_over[n] then start_since[n] = t end
        if start_since[n] then
            if simDR_alert_engine_N2[n - 1] >= START_IDLE_N2 or (not pulled and not run)
                    or t - start_since[n] > START_MAX_S then
                start_since[n] = nil
                start_over[n] = pulled or nil
            else
                any = true
            end
        end
    end
    return any
end

local function read_inputs(inp, t)
    arrays.warning = B747DR_CAS_warning_status
    arrays.caution = B747DR_CAS_caution_status
    arrays.advisory = B747DR_CAS_advisory_status
    arrays.memo = B747DR_CAS_memo_status
    local active = inp.active
    for i = #active, 1, -1 do active[i] = nil end
    for _, m in ipairs(messages) do
        if arrays[m.array][m.index] > 0.5 then active[#active + 1] = m.entry end
    end
    local status_active = inp.status_active
    for i = #status_active, 1, -1 do status_active[i] = nil end
    for _, m in ipairs(status_messages) do
        if B747DR_CAS_status_status[m.index] > 0.5 then status_active[#status_active + 1] = m.name end
    end
    inp.status_page_shown = B747DR_alert_synoptic_display == STATUS_PAGE

    inp.on_ground = B747DR_alert_pseu_air == 0
    inp.nose_gear_down = B747DR_alert_ng_compressed == 1
    for n = 1, 4 do inp.fuel_cutoff[n] = B747DR_alert_fuel_control[n - 1] < 0.5 end
    inp.fire_switch_out[1] = B747DR_alert_fire_handle_1 > 0.5
    inp.fire_switch_out[2] = B747DR_alert_fire_handle_2 > 0.5
    inp.fire_switch_out[3] = B747DR_alert_fire_handle_3 > 0.5
    inp.fire_switch_out[4] = B747DR_alert_fire_handle_4 > 0.5
    inp.engine_start = engine_start(t)
    inp.ias = simDR_ind_airspeed_kts_pilot
    local v1 = B747DR_alert_V1
    if v1 > 0 and v1 < 900 then inp.v1 = v1 else inp.v1 = 0 end   -- 998/999: no V1 (fltInst02)
    inp.pitch = simDR_alert_pitch
    inp.radio_alt = simDR_alert_radio_alt
    local afds = B747DR_alert_afds_status
    inp.land_2_3 = afds == 3 or afds == 4          -- LAND 2, LAND 3 (autopilot init script)
    inp.recall_held = B747DR_alert_rcl_switch_pos > 0.5

    -- one push of each button per update; more wait for the next one
    for _, key in ipairs({"cancel", "recall", "master_reset"}) do
        inp[key] = pushes[key] > 0
        if inp[key] then pushes[key] = pushes[key] - 1 end
    end
end

local function set_slot(level, slot, text)
    local cache = shown[level]
    if cache[slot] == text then return end
    cache[slot] = text
    if level == "warning" then
        B747DR_CAS_gen_warning_msg[slot] = text
    elseif level == "caution" then
        B747DR_CAS_gen_caution_msg[slot] = text
    elseif level == "advisory" then
        B747DR_CAS_gen_advisory_msg[slot] = text
    elseif level == "memo" then
        B747DR_CAS_gen_memo_msg[slot] = text
    else
        B747DR_CAS_gen_status_msg[slot] = text
    end
end

-- the STATUS page lines, and its page count for the STAT switch; the page
-- shown comes back into range when pages go (the STAT datarefs belong to
-- the other plugin: each is read before it is written, TESTING.md §1.2)
local function write_status(pages, num_pages)
    for slot = 0, SLOTS - 1 do
        local page = pages[math.floor(slot / A.LINES) + 1]
        set_slot("status", slot, (page and page[slot % A.LINES + 1]) or " ")
    end
    if B747DR_STAT_num_msg_pages ~= num_pages then B747DR_STAT_num_msg_pages = num_pages end
    if B747DR_STAT_msg_page > num_pages then B747DR_STAT_msg_page = num_pages end
end

-- each line goes to the slot of its level, the other levels' slots blank
local function write_lines(pages)
    for slot = 0, SLOTS - 1 do
        local page = pages[math.floor(slot / A.LINES) + 1]
        local line = page and page[slot % A.LINES + 1]
        for _, level in ipairs(LEVELS) do
            if line and line.level == level then
                set_slot(level, slot, line.text)
            else
                set_slot(level, slot, " ")
            end
        end
    end
end

local function write_outputs(out, t)
    write_lines(out.pages)
    B747DR_CAS_msg_page = out.page
    B747DR_CAS_num_msg_pages = out.num_pages
    B747DR_CAS_caut_adv_display = 1 - flag(out.cancelled)
    B747DR_master_warning = flag(out.master_warning)
    B747DR_master_caution = flag(out.master_caution)
    -- 1 s pulse for each caution that lights master CAUTION and each
    -- advisory with the beeper: the .snd beeper plays it
    if out.caution_beep then caution_audio_until = t + 1 end
    B747DR_master_caution_audio = flag(t < caution_audio_until)
    B747DR_warning_bell = flag(out.aural.bell)
    B747DR_warning_siren = flag(out.aural.siren)
    B747DR_warning_wailer = flag(out.aural.wailer)
    write_status(out.status_pages, out.status_num_pages)
    B747DR_CAS_status_cue = flag(out.status_cue)
    if B747DR_CAS_status_cue_text ~= STATUS_CUE_TEXT then B747DR_CAS_status_cue_text = STATUS_CUE_TEXT end
end

-- a new flight: no messages seen yet
function B747_alerts_reset()
    alert_state = A.new()
    start_since, start_over = {}, {}
    pushes.cancel, pushes.recall, pushes.master_reset = 0, 0, 0
end

-- every frame while the EIUs have power
function B747_alerts()
    count_pushes("cancel", B747DR_CAS_canc_count)
    count_pushes("recall", B747DR_CAS_rcl_count)
    count_pushes("master_reset", B747DR_master_reset_count)
    alert_on = true
    alert_period = alert_period + SIM_PERIOD
    if alert_period < ALERT_PERIOD_S then return end
    local dt = alert_period
    alert_period = 0
    alert_time = alert_time + dt
    read_inputs(alert_inputs, alert_time)
    local out = A.update(alert_state, alert_inputs, dt)
    write_outputs(out, alert_time)
end

-- every frame while the EIUs are not running (no power, or starting): the
-- lines blank, the lights and the aurals off, pushes do nothing, and the
-- messages start again when they run
function B747_alerts_off()
    count_pushes("cancel", B747DR_CAS_canc_count)
    count_pushes("recall", B747DR_CAS_rcl_count)
    count_pushes("master_reset", B747DR_master_reset_count)
    pushes.cancel, pushes.recall, pushes.master_reset = 0, 0, 0
    if not alert_on then return end
    alert_on = false
    B747_alerts_reset()
    alert_period = 0
    write_lines({})
    B747DR_CAS_msg_page = 1
    B747DR_CAS_num_msg_pages = 1
    B747DR_CAS_caut_adv_display = 1
    B747DR_master_warning = 0
    B747DR_master_caution = 0
    B747DR_master_caution_audio = 0
    caution_audio_until = 0
    B747DR_warning_bell = 0
    B747DR_warning_siren = 0
    B747DR_warning_wailer = 0
    write_status({}, 1)
    B747DR_CAS_status_cue = 0
end
