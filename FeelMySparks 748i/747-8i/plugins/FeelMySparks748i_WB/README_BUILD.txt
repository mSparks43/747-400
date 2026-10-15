FeelMySparks 748i Load Control - Native X-Plane plugin

Build the universal macOS plugin from this directory:

  clang++ -std=c++17 -DGL_SILENCE_DEPRECATION -I source \
          -arch x86_64 -arch arm64 -bundle -undefined dynamic_lookup \
          -framework OpenGL -fvisibility=hidden \
          -o 64/mac.xpl source/feelmysparks748i_wb.cpp
  codesign --force --sign - --timestamp=none 64/mac.xpl
  codesign --verify --strict 64/mac.xpl

The window uses explicit mouse hit targets for payload adjustments, tank
selection, per-tank fuel changes, and fuel presets. All loading controls are
ground-only.
