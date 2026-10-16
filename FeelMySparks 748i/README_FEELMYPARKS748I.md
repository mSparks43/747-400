FeelMySparks 748i
==================

This repository contains the FeelMySparks 748i (Boeing 747-8i) aircraft project.
The standalone Weight and Balance plugin has been removed and is no longer supported.

## Licensing and Contribution Status

The Sparky744 747-400 base, aircraft material, documentation, and the authorized exterior-only 747-8I beta contribution are documented under CC BY-NC 4.0; see the aircraft [LICENSE](./747-8i/LICENSE). The original standalone FBW Lua module is separately licensed under MIT; see the aircraft [LICENSE-MIT](./747-8i/LICENSE-MIT). Inherited or modified Sparky744 code, XTLua/XLua frameworks, and other third-party components retain their own licenses and notices.

The exterior-only beta contribution by lkoledic does not change internal systems. Its pull request is pending review and has not been accepted or merged. Contribution and upstream permission details are in the top-level project README.

## Experimental Flight-Control Augmentation

The experimental partial-FBW test laws are isolated in `B747.19.xt.fbw.lua` and enter the existing hydraulic control mixer before normal hydraulic demand calculations. The FBW master, flap-linked outboard-aileron droop, and prototype G-based MLA are enabled by default; set `laminar/B747/fbw/enabled` to `0` to disable the mixer. Law inputs are sampled at 20 Hz. `laminar/B747/fbw/roll_response_gain` (default `0.05`, clamped to `0–0.15`) schedules a small outboard-aileron differential boost that fades out with speed. `laminar/B747/fbw/roll_rate_damping_gain` (default `0.25`, clamped to `0–1`) adds capped roll-rate opposition only when the aileron command is near neutral and the autopilot servos are disengaged, so it does not oppose autopilot-commanded turns. The MLA demand remains slew-limited at the faster update rate to reduce abrupt changes; it is not a verified Boeing law. Existing high-speed outer-aileron lockout remains in the hydraulic model. The native X-Plane force-feedback stick shaker is enabled by `laminar/B747/fbw/buffet_enabled` (default `1`); compatible hardware is required, and it is a stall-warning cue, not airframe buffet. Pitch and yaw remain mechanical: there is no FBW elevator protection or takeoff rotation interlock, so this module does not prevent rotation below FMC Vr or protect against a hand-flown stall. OAMS and actual gust-load measurement are not modeled. Read `laminar/B747/fbw/mla_demand` and `laminar/B747/fbw/aileron_droop_ratio` to observe outputs. This is an unvalidated simulation prototype; test at safe altitude.
