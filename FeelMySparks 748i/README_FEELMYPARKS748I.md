FeelMySparks 748i
==================

This repository contains the FeelMySparks 748i (Boeing 747-8i) aircraft project.
The standalone Weight and Balance plugin has been removed and is no longer supported.

## Experimental Flight-Control Augmentation

The experimental FBW test laws are isolated in `B747.19.xt.fbw.lua` and enter the existing hydraulic control mixer before its normal demand calculations. They do not replace hydraulic callbacks. The master switch is `laminar/B747/fbw/enabled` (default `1`); set it to `0` to disable FBW. Maneuver-load alleviation and flap-linked outboard-aileron droop are separately controlled by `laminar/B747/fbw/mla_enabled` and `laminar/B747/fbw/droop_enabled`; the current MLA law is an unvalidated prototype, not a verified reproduction of Boeing's implementation. `laminar/B747/fbw/roll_response_gain` (default `0.12`, clamped to `0–0.25`) tunes a low-speed-only outboard-aileron differential boost that fades out by 220 kt; it does not amplify common-mode droop. The native X-Plane force-feedback stick shaker is enabled by `laminar/B747/fbw/buffet_enabled` (default `1`); it requires compatible force-feedback hardware and is a stall-warning cue, not simulated airframe vibration. Read `laminar/B747/fbw/mla_demand` and `laminar/B747/fbw/aileron_droop_ratio` to observe the existing test-law outputs. Pitch and yaw remain outside this partial-FBW module. This is an unvalidated simulation prototype; test at safe altitude.
