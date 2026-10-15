FeelMySparks 748i
==================

This repository contains the FeelMySparks 748i (Boeing 747-8i) aircraft project.
The standalone Weight and Balance plugin has been removed and is no longer supported.

## Experimental Flight-Control Augmentation

The experimental partial-FBW test laws are isolated in `B747.19.xt.fbw.lua` and enter the existing hydraulic control mixer before normal hydraulic demand calculations. The FBW master, flap-linked outboard-aileron droop, and prototype G-based MLA are enabled by default; set `laminar/B747/fbw/enabled` to `0` to disable the mixer. Law inputs are sampled at 5 Hz. `laminar/B747/fbw/roll_response_gain` (default `0.05`, clamped to `0–0.15`) schedules a small outboard-aileron differential boost that fades out with speed. `laminar/B747/fbw/roll_rate_damping_gain` (default `0.25`, clamped to `0–1`) adds capped roll-rate opposition only when the aileron command is near neutral, as an experimental gust-response aid. The MLA demand is slew-limited to reduce abrupt changes; it is not a verified Boeing law. Existing high-speed outer-aileron lockout remains in the hydraulic model. The native X-Plane force-feedback stick shaker is enabled by `laminar/B747/fbw/buffet_enabled` (default `1`); compatible hardware is required, and it is a stall-warning cue, not airframe buffet. Pitch and yaw remain mechanical: there is no FBW elevator protection or takeoff rotation interlock, so this module does not prevent rotation below FMC Vr or protect against a hand-flown stall. OAMS and actual gust-load measurement are not modeled. Read `laminar/B747/fbw/mla_demand` and `laminar/B747/fbw/aileron_droop_ratio` to observe outputs. This is an unvalidated simulation prototype; test at safe altitude.
