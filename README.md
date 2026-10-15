# FeelMySparks 748i
### Boeing 747-8 Intercontinental — X-Plane 12

**The Queen gets a glow-up.** ✈️

## About

FeelMySparks 748i is an independent community aircraft project developing a Boeing 747-8 Intercontinental-inspired aircraft for X-Plane 12. The current aircraft is based on the Sparky-derived 747-400 project; it is an ongoing conversion, not yet a complete 747-8I recreation.

The goal is to progressively update the aircraft's systems, flight model, cockpit, and exterior while preserving the useful inherited aircraft functionality. The current aircraft uses a Sparky744-derived 747-400 base. In the Discord exchange shared with this project on 15 October 2026, mSparks stated that the 744 project is licensed CC BY-NC 4.0 and invited contributions through pull requests with README credit.

## Project Status

**Status: Active development; experimental systems work in progress**

### Work completed or in active use
- The working FMC has custom alert colors and restored transparent display backing.
- The standalone Weight & Balance plugin has been removed from the aircraft package.
- An isolated, experimental FBW augmentation module is integrated with the existing XTLua hydraulic mixer. It updates its law state at 20 Hz and includes low-speed roll-response scheduling, flap-linked outboard-aileron droop, prototype maneuver-load alleviation, manual-flight roll-rate damping, and the native X-Plane force-feedback stick-shaker cue.
- The roll-rate damper is bypassed while autopilot servos are engaged, avoiding FBW opposition to autopilot-commanded turns.
- The FBW module and its documentation have been synced across the development, Intercontinental, backup, and installed X-Plane aircraft copies.
- An exterior-only 747-8I mod by lkoledic has been prepared as an initial beta contribution and submitted as a pull request. It changes the exterior only; it does not modify internal systems. The pull request is pending review and has not yet been accepted or merged.

These are experimental simulation features, not verified Boeing 747-8 control laws. The FBW layer does not command pitch or yaw, provide elevator stall protection, prevent rotation below FMC Vr, or model OAMS or measured gust loads. Live flight testing and tuning remain essential.

### Remaining development
- [ ] Flight-test and tune the 20 Hz FBW behavior, including autopilot turns, manual roll response, MLA, droop, and handling at different weights, speeds, and flap settings.
- [ ] Check for adverse interactions with the inherited hydraulic controls and autopilot; preserve a reliable way to disable the FBW during testing.
- [ ] Investigate and implement any additional pitch, stall-warning, or turbulence features only with a clearly defined, testable behavior and safe fallback.
- [ ] Review aircraft configuration and flight-model parameters for 747-8I accuracy without claiming unverified values.
- [ ] Develop the 747-8I wing geometry, engine nacelles, pylons, and exterior details.
- [ ] Create or adapt exterior textures and cockpit models.
- [ ] Confirm permission and license compatibility for all inherited and third-party assets before redistribution.
- [ ] Prepare release documentation, credits, packaging, and X-Plane compatibility testing.

Project scope and priorities may change; no feature or release date is guaranteed.

## Flight-Control Model

The current FBW prototype runs as a separate Lua module inside the aircraft's existing XTLua plugin. It modifies selected control ratios in the existing hydraulic mixer rather than replacing the inherited hydraulic or autopilot callbacks. Law inputs are sampled at 20 Hz; normal hydraulic processing continues through the existing model.

The current model is intentionally partial: roll response is speed-scheduled, droop follows flap ratio, MLA uses a prototype load-factor schedule, and capped roll-rate damping is active only with autopilot servos disengaged. A native force-feedback stick-shaker DataRef supplies a warning cue where supported. This is not a full fly-by-wire system or a validated representation of Boeing control laws. See [the aircraft README](./FeelMySparks%20748i/README_FEELMYPARKS748I.md) for tuning DataRefs and implementation limitations.

## Project History

- FMC alert-color and display-backing work.
- Removal of the standalone Weight & Balance plugin.
- Integration and iterative tuning of the isolated FBW prototype, including faster 20 Hz updates and autopilot-aware roll damping.
- Ongoing work toward 747-8I visual, systems, and flight-model changes.

## Licensing and Contributions

The Sparky744-derived aircraft package, project documentation, and authorized exterior-only mod contribution are licensed under **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**, as reflected in the permission exchange shared with this project. The original standalone FBW module is separately licensed under MIT. See [LICENSE.md](./LICENSE.md) and [LICENSE-MIT.md](./LICENSE-MIT.md) for scope, attribution, and third-party exceptions.

This is not a blanket relicensing of every file in the aircraft. Inherited or modified Sparky744 scripts, XTLua/XLua frameworks, embedded libraries, and other third-party assets remain under their applicable notices and licenses; see the corresponding in-tree license files. The exterior contribution is pending pull-request review; submission does not imply acceptance, and no dev-team membership is claimed by this notice.

Pull requests are welcome for review. Contributors should identify their changes, preserve all applicable notices, and confirm that submitted material may be included under CC BY-NC 4.0 or its applicable component license.

## Credits

This project acknowledges mSparks / Sparky744 for the 747-400 project used as the development base and the creators of the Sparky744 Enhancement Mod.

The project's 747-8I exterior-only beta contribution is by lkoledic and is pending review. It does not alter the aircraft's internal systems.

FeelMySparks 748i is an independent community project. It is not an official Boeing or Lufthansa product and is not endorsed by either company.

## Disclaimer

Boeing, 747-8 Intercontinental, GE, GEnx, and Lufthansa are referenced for identification purposes only. Their respective names and trademarks belong to their owners.

This is an unofficial flight-simulation project for X-Plane 12. It is not intended for real-world aviation use.

## Contact

For questions, suggestions, or permission requests, contact the project author through the official project page or the contact details provided with the release.

---

*FeelMySparks 748i — an independent community aircraft project.*

The standalone Weight and Balance plugin has been removed from the aircraft package.
