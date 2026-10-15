# FeelMySparks 748i Weight and Balance

Standalone X-Plane 12 native plugin for the FeelMySparks 748i / Boeing 747-8i package.

The aircraft package itself is intentionally not tracked in this development repository.  Only the
Weight and Balance plugin is maintained as source.  The aircraft package can be added separately.

## Important Paths

- Plugin source: `747-8i/plugins/FeelMySparks748i_WB/source/feelmysparks748i_wb.cpp`
- Minimal XPLM header: `747-8i/plugins/FeelMySparks748i_WB/source/xplm_minimal.h`
- Native macOS binary: `747-8i/plugins/FeelMySparks748i_WB/64/mac.xpl`

The original FeelMySparks project remains untouched outside this development folder.

## Runtime Standard DataRefs

The plugin deliberately uses global X-Plane SDK refs for fuel writes, not aircraft-avionics internals:

- `sim/flightmodel/weight/m_total`
- `sim/flightmodel/misc/cgz_ref_to_default` (fallback: `sim/flightmodel/weight/cg_z`)
- `sim/cockpit2/fuel/fuel_quantity`

It also creates isolated datarefs in the plugin-owned namespace:

- `feelmysparks/wb/cg_percent_mac`
- `feelmysparks/wb/status`
- `feelmysparks/wb/target_payload_kg`
- `feelmysparks/wb/cg_forward_limit_m`
- `feelmysparks/wb/cg_aft_limit_m`

Fuel is written only to `sim/cockpit2/fuel/fuel_quantity`, using the 747-8i tank priorities:

```text
0 = center wing, 72000  , priority 1
1 = main reserve #1,17500, priority 2
2 = main reserve #2,17500, priority 3
3 = main reserve #3,17500, priority 4
4 = main reserve #4,17500, priority 0
5 = inboard reserve #1,8500, priority 7
6 = inboard reserve #2,8500, priority 5
7 = tail stabilizer, 12000, priority 6
8 = CWT forward,    15000, priority 8
```

## Features

- X-Plane 12 native floating W&B window.
- White notepad canvas with blue notebook lines.
- Blue text drawing with aliased graphics state for crisp display.
- Direct fuel injection through X-Plane's standard fuel quantity array.
- 9-tank load priority schedule for presets.
- Live weight, CG scale, and safe/warning CG status.
- Takeoff trim guidance based on the current CG scale.
- Fuel and gross-weight text fields.
- Mouse-drag fuel distribution targets.
- Reopen menu item under `Plugins -> FeelMySparks W&B -> Show W&B Window`.
- `EMPTY`, `STD PAX`, `MAX CARGO`, and `MTOW` fuel presets.

## Building

C++ and the supplied minimal XPLM declarations are used:

```sh
clang++ -std=c++17 \
  -DGL_SILENCE_DEPRECATION \
  -I source \
  -arch x86_64 -arch arm64 \
  -bundle -undefined dynamic_lookup -framework OpenGL \
  -fvisibility=hidden \
  -o 64/mac.xpl source/feelmysparks748i_wb.cpp
```

Windows and Linux binaries have not yet been built.

## macOS Quarantine

After copying a fresh aircraft or plugin iteration to the Mac, remove quarantine so X-Plane does
not require manual approval:

```sh
xattr -dr com.apple.quarantine "/path/to/747-8i"
```

## Notes and Limitations

- The avionics package itself is not part of this tracked repository.
- Windows (`64/win.xpl`) and Linux (`64/lin.xpl`) builds are still outstanding.
- X-Plane's SDK exposes only built-in UI fonts, not Arial as a separate native font.  The window uses
  the strongest built-in proportional font available.
- W&B limits are provisional and should be replaced with authoritative values when available.
