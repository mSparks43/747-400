FeelMySparks 748i
==================

This repository currently focuses on the standalone Weight and Balance plugin
for the FeelMySparks 748i (Boeing 747-8i) project.

Aircraft package files were intentionally removed from this repository to avoid
shipping an incompatible avionics set. Re-add the matching baseline aircraft
package separately.

Standalone Weight and Balance plugin:
- Plugin path: plugins/FeelMySparks748i_WB
- Source: plugins/FeelMySparks748i_WB/source/feelmysparks748i_wb.cpp
- macOS binary: plugins/FeelMySparks748i_WB/64/mac.xpl

Features:
- X-Plane 12 native window UI.
- Direct fuel injection into sim/cockpit2/fuel/fuel_quantity.
- 9-tank priority scheduling from preset loads.
- CG safety checks and takeoff trim helper.
- Numeric text-field editing and drag interface.
- Native colorized 3D notepad-style visual sheet.
