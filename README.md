# FeelMySparks 748i
### Boeing 747-8 Intercontinental — X-Plane 12

**The Queen gets a glow-up.** ✈️

## About

FeelMySparks 748i is a community aircraft project aiming to bring the Boeing 747-8 Intercontinental to X-Plane 12.

The project aims to feature a redesigned exterior inspired by the 747-8I, including its wings, engine nacelles, pylons, and other exterior details. The initial plan is to use the Sparky744 747-400 as a starting point, subject to the necessary permissions.

The goal is to create a standalone aircraft package with its own identity and release branding.

## Project Status

**Status: Early development / planning**

The project is currently in its planning and setup phase.

Planned work includes:
- [ ] Obtain permission to use and redistribute any required Sparky744 assets.
- [ ] Inspect the base aircraft and Enhancement Mod file structure.
- [ ] Develop the 747-8I wing geometry.
- [ ] Model the four GE GEnx-2B engines and their pylons.
- [ ] Create new exterior textures and details.
- [ ] Review aircraft configuration and flight-model requirements.
- [ ] Test the aircraft in X-Plane 12.
- [ ] Prepare documentation and a standalone release.

Features and release dates are not guaranteed and may change during development.

## Planned Features

- Boeing 747-8I-inspired exterior.
- Four GE GEnx-2B engines.
- Redesigned wings and engine pylons.
- Custom exterior textures.
- X-Plane 12 compatibility as the target.
- Standalone aircraft packaging, subject to asset permissions.

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

## Companion Weight and Balance Plugin

The development worktree now includes a standalone native X-Plane 12 Weight and Balance plugin for the 747-8i package.

Current plugin capabilities:

- Native floating window UI with a white notepad-style canvas.
- Standard X-Plane datarefs for live weight, CG, and direct fuel writes.
- Nine-tank fuel priority scheduling.
- `EMPTY`, `STD PAX`, `MAX CARGO`, and `MTOW` fuel presets.
- Live CG status checking and takeoff trim guidance.
- Reopen command from `Plugins -> FeelMySparks W&B -> Show W&B Window`.
- macOS universal (`x86_64` + `arm64`) binary in `FeelMySparks 748i/747-8i/plugins/FeelMySparks748i_WB/64/mac.xpl`.

Platform status:

- macOS: built and tested.
- Windows and Linux: not yet built.
- W&B tank capacities, CG limits, and overall aircraft calibration remain provisional.
