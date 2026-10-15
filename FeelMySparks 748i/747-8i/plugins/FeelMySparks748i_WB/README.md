FeelMySparks 748i Load Control
==============================

This is a fresh native X-Plane plugin with direct mouse controls; it does not
use keyboard-focus text fields or draggable sliders.

Controls:
- Payload buttons change `sim/flightmodel/weight/m_fixed` by 500 or 1000 kg.
- Select a fuel tank, then change it by 250 or 1000 kg.
- Fuel presets set the X-Plane tank array directly.
- Payload and fuel controls are disabled while airborne.
- The panel reports whether the relevant X-Plane datarefs are writable and
  confirms or reports rejection for every load adjustment.

The modern window uses X-Plane global boxel coordinates for both drawing and
mouse hit testing. The window is centered within the current global screen
bounds.

Build on macOS:
```sh
clang++ -std=c++17 -DGL_SILENCE_DEPRECATION -I source \
  -arch x86_64 -arch arm64 -bundle -undefined dynamic_lookup \
  -framework OpenGL -fvisibility=hidden \
  -o 64/mac.xpl source/feelmysparks748i_wb.cpp
codesign --force --sign - --timestamp=none 64/mac.xpl
codesign --verify --strict 64/mac.xpl
```
