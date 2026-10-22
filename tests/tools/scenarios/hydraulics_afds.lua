-- Inputs for tests/tools/same_behaviour.lua: the hydraulics module
-- (B747.19.xt.hydraulicsmodel), which also holds the AFDS control laws, the
-- yaw dampers and the slats (R-1 in docs/overhaul/PLAN.md moves those out).
-- Pumps run, the flight controls move, the autopilot goes through every pitch
-- mode and three roll modes, the yaw dampers come on, and the flaps, slats,
-- speedbrake and parking brake move. Open loop: the attitude and air data are
-- fixed functions of time and do not respond to the controls. The point is to
-- drive every branch with changing values, not to fly.
local HYD = "plugins/xtlua_keysystems/scripts/B747.19.xt.hydraulicsmodel/"
local PITCH_MODES = {0, 1, 2, 4, 5, 6, 7, 8, 9}
local PHASE = 40  -- seconds per autopilot mode
local CABLES = {"lower_rudder", "upper_rudder", "left_inner_elevator", "right_inner_elevator",
    "left_outer_elevator", "right_outer_elevator", "left_inner_aileron", "right_inner_aileron",
    "left_outer_aileron", "right_outer_aileron", "spoiler1", "spoiler2", "spoiler3", "spoiler4",
    "spoiler5", "spoiler8", "spoiler9", "spoiler10", "spoiler11", "spoiler12", "speedbrake67"}

return {
    module = HYD .. "B747.19.xt.hydraulicsmodel.lua",
    seconds = #PITCH_MODES * PHASE,
    dt = {1 / 20, 1 / 30, 1 / 45},
    inputs = function(rt, t)
        local s, c = math.sin, math.cos
        local phase = math.floor(t / PHASE)
        rt:set("sim/version/xplane_internal_version", 120440)
        rt:set("sim/physics/earth_temp_c", 15)
        -- engine-driven pumps on, demand pumps AUTO, bleed in the ducts
        for i = 30, 33 do rt:set("laminar/B747/button_switch/position", i, 1) end
        local n1 = t < 20 and 0 or 30
        rt:set("laminar/B747/engines/display_N1", {[0] = n1, n1, n1, n1})
        rt:set("laminar/B747/hydraulics/dmd_pump/sel_dial_pos", {[0] = 1, 1, 1, phase == 2 and -1 or 1})
        rt:set("laminar/B747/air/duct_pressure_L", 30)
        rt:set("laminar/B747/air/duct_pressure_R", 30)
        -- attitude and air data
        local ias = 250 + 40 * s(0.05 * t)
        rt:set("sim/cockpit2/gauges/indicators/pitch_AHARS_deg_pilot", 2 + 3 * s(0.3 * t))
        rt:set("sim/cockpit2/gauges/indicators/roll_AHARS_deg_pilot", 12 * s(0.15 * t))
        rt:set("sim/cockpit2/gauges/indicators/heading_AHARS_deg_mag_pilot", (100 + 3 * t) % 360)
        rt:set("sim/cockpit2/gauges/indicators/sideslip_degrees", 1.5 * s(0.9 * t))
        rt:set("sim/cockpit2/gauges/indicators/airspeed_kts_pilot", ias)
        rt:set("laminar/B747/gauges/indicators/airspeed_kts_pilot", ias)
        rt:set("sim/cockpit2/gauges/indicators/altitude_ft_pilot", 10000 + 800 * s(0.02 * t))
        rt:set("sim/cockpit2/gauges/indicators/vvi_fpm_pilot", 800 * 0.02 * 60 * c(0.02 * t))
        rt:set("sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot", 2500 + 2200 * s(0.01 * t))
        rt:set("sim/flightmodel2/position/groundspeed", ias * 0.5144)
        rt:set("laminar/B747/airspeed/Vmc", 130)
        rt:set("laminar/B747/airspeed/Vmax", 365)
        -- autopilot
        rt:set("laminar/B747/autopilot/servos_on", t > 5 and 1 or 0)
        rt:set("laminar/B747/autopilot/ap_monitor/servos_on_time", 5)
        rt:set("laminar/B747/autopilot/FMA/active_pitch_mode", PITCH_MODES[phase % #PITCH_MODES + 1])
        rt:set("laminar/B747/autopilot/FMA/active_roll_mode", t > 5 and (phase % 3 + 1) or 0)
        rt:set("laminar/B747/autopilot/altitude_dial_ft", phase % 2 == 0 and 10500 or 9600)
        rt:set("laminar/B747/autopilot/heading/altitude_dial_ft_pfd", 10500)
        rt:set("laminar/B747/autopilot/ap_monitor/alt_capture_window", 300)
        rt:set("sim/cockpit2/autopilot/vvi_dial_fpm", phase % 2 == 0 and 1500 or -1000)
        rt:set("sim/cockpit2/autopilot/airspeed_dial_kts", 260)
        rt:set("sim/cockpit2/autopilot/flight_director_roll_deg", 15 * s(0.07 * t))
        rt:set("sim/cockpit2/autopilot/TOGA_pitch_deg", 8)
        rt:set("laminar/B747/autopilot/actual_nav_status", phase == 3 and 2 or 0)
        rt:set("laminar/B747/autopilot/nav_status", phase >= 3 and 2 or 0)
        rt:set("laminar/B747/autopilot/autoland", phase == 7 and 1 or 0)
        rt:set("laminar/B747/autopilot/autolandPitch", 2.5)
        rt:set("sim/cockpit2/radios/indicators/hsi_vdef_dots_pilot", 2.5 * s(0.1 * t))
        rt:set("sim/cockpit/radios/nav1_slope_degt", 3)
        rt:set("laminar/B747/autopilot/flightPhase", phase % 4)
        rt:set("laminar/B747/autopilot/vnav_descent", phase == 5 and 1 or 0)
        rt:set("laminar/B747/autopilot/att_rate", phase == 8 and 6 or 0)
        rt:set("laminar/B747/autopilot/AFDS/mode_box_status_pilot", phase == 4 and 1 or 0)
        -- yaw dampers
        rt:set("laminar/B747/flt_ctrls/yaw_damper_upr_on", 1)
        rt:set("laminar/B747/flt_ctrls/yaw_damper_lwr_on", t > 100 and 1 or 0)
        -- flaps, slats, speedbrake, reversers, parking brake
        local flap = math.max(0, math.min(1, 0.5 + 0.6 * s(0.02 * t)))
        rt:set("sim/cockpit2/controls/flap_ratio", flap)
        rt:set("laminar/B747/cablecontrols/flap_ratio", flap)
        rt:set("laminar/B747/flt_ctrls/flap_lever_detent", flap < 0.1 and 0 or 1)
        for i = 1, 4 do rt:set("laminar/B747/cablecontrols/flap" .. i, 30 * flap) end
        rt:set("laminar/B747/flt_ctrls/speedbrake_lever", phase == 6 and 0.9 or 0)
        local reverse = phase == 6 and t % PHASE > 20 and 3 or 1
        rt:set("sim/cockpit2/engine/actuators/prop_mode", {[0] = reverse, reverse, reverse, reverse})
        rt:set("sim/cockpit2/controls/parking_brake_ratio", math.floor(t / 7) % 2)
        -- the cable positions the XTLua control mapping sets in X-Plane
        for k, name in ipairs(CABLES) do
            rt:set("laminar/B747/cablecontrols/" .. name, 10 * s(0.4 * t + k))
        end
        rt:set("laminar/B747/flt_ctrls/custom_pitch_ratio", 0.3 * s(0.5 * t))
        rt:set("sim/cockpit2/controls/total_heading_ratio", 0.2 * s(0.3 * t))
    end,
}
