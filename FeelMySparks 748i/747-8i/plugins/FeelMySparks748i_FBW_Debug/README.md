FeelMySparks 748i FBW Debug Instrumentation
===========================================

Read-only instrumentation plugin for the experimental 747-8i fly-by-wire prototype.

- The plugin does not alter the control law.
- It displays flight, FBW, control-surface, hydraulic, and timing data.
- The bottom-left SNAPSHOT button writes one diagnostics line to X-Plane's `Log.txt`.
- The black-background window can be reopened from `Plugins -> FeelMySparks 748i FBW Debug`.
- Tabs switch measurement groups without changing aircraft state.

Build:
```
clang++ -std=c++17 -DGL_SILENCE_DEPRECATION -I source -arch x86_64 -arch arm64 -bundle -undefined dynamic_lookup -framework OpenGL -fvisibility=hidden -o 64/mac.xpl source/feelmysparks748i_fbw_debug.cpp
```
