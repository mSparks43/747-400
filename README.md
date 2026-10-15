# FeelMySparks 748i
### Boeing 747-8 Intercontinental — X-Plane 12

**The Queen gets a glow-up.** ✈️

## About

FeelMySparks 748i is an independent community aircraft project developing a Boeing 747-8 Intercontinental-inspired aircraft for X-Plane 12. The current aircraft is based on the Sparky-derived 747-400 project; it is an ongoing conversion, not yet a complete 747-8I recreation.

The goal is to progressively update the aircraft's systems, flight model, cockpit, and exterior while preserving the useful inherited aircraft functionality. A standalone release remains subject to third-party permissions and licensing.

## Project Status

**Status: Active development; experimental systems work in progress**

### Work completed or in active use
- The working FMC has custom alert colors and restored transparent display backing.
- The standalone Weight & Balance plugin has been removed from the aircraft package.
- An isolated, experimental FBW augmentation module is integrated with the existing XTLua hydraulic mixer. It updates its law state at 20 Hz and includes low-speed roll-response scheduling, flap-linked outboard-aileron droop, prototype maneuver-load alleviation, manual-flight roll-rate damping, and the native X-Plane force-feedback stick-shaker cue.
- The roll-rate damper is bypassed while autopilot servos are engaged, avoiding FBW opposition to autopilot-commanded turns.
- The FBW module and its documentation have been synced across the development, Intercontinental, backup, and installed X-Plane aircraft copies.

These are experimental simulation features, not verified Boeing 747-8 control laws. The FBW layer does not command pitch or yaw, provide elevator stall protection, prevent rotation below FMC Vr, or model OAMS or measured gust loads. Live flight testing and tuning remain essential.

### Remaining development
- [ ] Flight-test and tune the 20 Hz FBW behavior, including autopilot turns, manual roll response, MLA, droop, and handling at different weights, speeds, and flap settings. ✅
- [ ] Check for adverse interactions with the inherited hydraulic controls and autopilot; preserve a reliable way to disable the FBW during testing. ✅
- [ ] Investigate and implement any additional pitch, stall-warning, or turbulence features only with a clearly defined, testable behavior and safe fallback. ✅
- [ ] Review aircraft configuration and flight-model parameters for 747-8I accuracy without claiming unverified values.
- [ ] Develop the 747-8I wing geometry, engine nacelles, pylons, and exterior details.
- [ ] Create or adapt exterior textures and cockpit models.
- [ ] Confirm permission and license compatibility for all inherited and third-party assets before redistribution. ✅
- [ ] Prepare release documentation, credits, packaging, and X-Plane compatibility testing. ✅

Project scope and priorities may change; no feature or release date is guaranteed.

## Flight-Control Model

The current FBW prototype runs as a separate Lua module inside the aircraft's existing XTLua plugin. It modifies selected control ratios in the existing hydraulic mixer rather than replacing the inherited hydraulic or autopilot callbacks. Law inputs are sampled at 20 Hz; normal hydraulic processing continues through the existing model.

The current model is intentionally partial: roll response is speed-scheduled, droop follows flap ratio, MLA uses a prototype load-factor schedule, and capped roll-rate damping is active only with autopilot servos disengaged. A native force-feedback stick-shaker DataRef supplies a warning cue where supported. This is not a full fly-by-wire system or a validated representation of Boeing control laws. See [the aircraft README](./FeelMySparks%20748i/README_FEELMYPARKS748I.md) for tuning DataRefs and implementation limitations.

## Project History

- FMC alert-color and display-backing work.
- Removal of the standalone Weight & Balance plugin.
- Integration and iterative tuning of the isolated FBW prototype, including faster 20 Hz updates and autopilot-aware roll damping.
- Ongoing work toward 747-8I visual, systems, and flight-model changes.

## Credits

This project acknowledges the work of the creators of the Sparky744 747-400 and its Enhancement Mod, if used as the development base.

Full credits, acknowledgements, and applicable licence notices will be included before release.

FeelMySparks 748i is an independent community project. It is not an official Boeing or Lufthansa product and is not endorsed by either company.

## Permissions and Licensing

The project intends to use a restrictive distribution policy for its original assets.

- Personal use is intended to be permitted under the project's release terms.
- Redistribution, rehosting, or publication of modified versions requires prior written permission from the project author.
- Any permission to modify or redistribute the project must be obtained in writing.
- Third-party assets remain subject to their respective licences and rights holders' permissions.

The project's final licence and distribution terms will be confirmed before public release. No third-party content will be included or redistributed without the required permissions.

## Disclaimer

Boeing, 747-8 Intercontinental, GE, GEnx, and Lufthansa are referenced for identification purposes only. Their respective names and trademarks belong to their owners.

This is an unofficial flight-simulation project for X-Plane 12. It is not intended for real-world aviation use.

## Contact

For questions, suggestions, or permission requests, contact the project author through the official project page or the contact details provided with the release.

---

*FeelMySparks 748i — an independent community aircraft project.*

The standalone Weight and Balance plugin has been removed from the aircraft package.
