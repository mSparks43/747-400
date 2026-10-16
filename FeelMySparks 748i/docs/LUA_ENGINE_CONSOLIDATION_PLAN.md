# FeelMySparks 748i — Engine/Fuel/Electrical Lua Consolidation Plan

## Current 3-way engine-family implementation (verified)

### 1. Configuration selection
- `plugins/xtlua/scripts/B747.05.xt.simconfig/B747.05.xt.simconfig.lua`
  - `simConfigData["data"].PLANE.engines` currently enumerates PW4056/PW4060/PW4062, CF6-80C2 variants, and RB211-524 variants.
  - `check_thrust_ref()` maps PW/RB to EPR and CF6 to N1.
  - `checkEngineType()` maps the engine string to:
    - 0 = PW4000
    - 1 = GE CF6
    - 2 = RR RB211
    - hides all non-selected visual engine sets using `laminar/B747/engines/hideGE/hidePW/hideRR`.

### 2. Engine instrument and EEC logic
- `plugins/xtlua/scripts/B747.40.xt.engines/B747.40.xt.engines.lua`
  - Uses `B747DR_engineType == 0/1/2` branches for warning thresholds and EPR behaviour.
- `plugins/xtlua/scripts/B747.42.xt.EEC/`
  - Separate `B747.42.xt.EEC.GE.lua`, `.PW.lua`, `.RR.lua` contain 747-400-specific N1/EPR, idle, and takeoff-thrust logic.
  - There is no `GEnx` implementation.

### 3. Visuals and sound
- `747-400.acf` object attachment records use `laminar/B747/engines/hideGE`, `hidePW`, and `hideRR` only.
- ACF assets include CF6/PW/RB-style objects, not GEnx.
- `fmod/747-400.snd` requires `engineGE`, `enginePW`, `engineRR`, and an `/EngineOption` snapshot.

### 4. Warning systems
- `B747.87.xt.warning` has engine-type-dependent N1 redline behaviour at lines ~1552 (PW), ~1570 (GE CF6), and ~1588 (RR).

## Consolidation target
Create a single **GEnx-2B** path:

- Engine token: `GEnx-2B67`
- Engine type ID: `3`
- Thrust reference: N1
- Visual hide family: `laminar/B747/engines/hideGEnx`
- EEC file: `B747.42.xt.EEC.GEnx.lua`
- FMOD bank: `engineGEnx.bank`
- Sound configuration: `/EngineOption` remains selectable, but only GEnx bank/path is active.

## Scaffold already applied (this work session)
- `plugins/xtlua/scripts/B747.05.xt.simconfig/...`:
  - Default `PLANE.model` changed to `747-8I`.
  - Default `PLANE.engines` changed to `GEnx-2B67`.
  - Default `PLANE.thrust_ref` changed to `N1`.
  - `check_thrust_ref()` now maps `GEnx` to N1.
  - `checkEngineType()` now has engine type `3` for `GEnx`, hiding all legacy visual sets.
  - Added `B747DR_hideGEnx` dataref scaffold.
- `plugins/xtlua/init/scripts/B747.05.simconfig/...`:
  - Added `B747DR_hideGEnx` dataref declaration.

## Remaining work to complete consolidation
1. Add `hideGEnx` object hide bindings in `747-400.acf` after a GEnx `.obj` and texture set exist.
2. Create `B747.42.xt.EEC.GEnx.lua`, copied initially from the GE scaffold, but recalibrated for GEnx-2B idle/N1/spool/FF behaviour. Do not reuse 747-400 CF6 thrust curves unchanged.
3. Replace the hard-coded `engineType == 0/1/2` chains with a data table or per-family helper, then add the GEnx case.
4. Add an N1 redline/limit value for GEnx in `B747.87.xt.warning`.
5. Replace or extend `B747.40.xt.engines` N1/EPR max-limit logic for engine family 3.
6. Add GEnx support in `fmod/*.snd` / FDAT and replace engine bank selection.
7. Remove obsolete engine-family strings from livery `B747-400_simconfig.dat` defaults after fleet-wide validation.
8. Update FMS thrust-limit and performance pages to expose only GEnx/N1 references.

## Risk notes
- The current `GEnx` branch hides all legacy engines. Until a GEnx asset set is attached, the aircraft will have no visible engines. This is intentional as a fail-safe scaffold and must be completed before in-simulator testing.
- Default config changes make the package assume a target aircraft not yet fully modelled; simulator testing will expose missing assets immediately.
