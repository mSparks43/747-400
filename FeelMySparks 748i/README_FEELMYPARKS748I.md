FeelMySparks 748i
==================

This repository contains the FeelMySparks 748i (Boeing 747-8i) aircraft project.
The standalone Weight and Balance plugin has been removed and is no longer supported.

## Experimental Flight-Control Augmentation

The aircraft now has a tunable, approximate FBW-style layer integrated into the existing hydraulic control-surface model. It adds G-load maneuver alleviation through the outboard ailerons and 12 modeled spoiler channels, flap-linked outboard-aileron droop, roll-acceleration damping (an OAMS proxy), low-altitude tail-strike elevator bias, and low-altitude asymmetric-thrust roll compensation. The existing speed-dependent outboard-aileron reduction remains active by default from 232 to 238 KIAS.

All modes and tuning values are exposed under `laminar/B747/fbw/` for DataRefTool/DataRefEditor. Defaults are restored at each aircraft `flight_start`; edit the defaults in `B747.19.xt.hydraulicsmodel.lua` to retain tuning across flights. The OAMS proxy uses aircraft roll acceleration rather than wingtip accelerometers, and all thresholds and deflections are experimental values to refine in X-Plane. Back up the package and test changes at safe altitude. No aircraft geometry or ACF files were changed.
