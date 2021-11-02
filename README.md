# Boeing 747-400

## Major Overhaul of the Laminar Boeing 747-400

Thank you all for your support! This overhaul is now at the "experimental" version 1 stage. Still more todo but now has enough flight test hours under its belt to be a stable daily driver for your short and long haul needs.

**Is the 747 free?**

Yes! Of course! This project is an open source project, consisting of developers gathering from all over the world wanting to create a 747.


**What are the differences between the default 747, and the Sparky 747?**

This 747 currently includes new FMOD sounds, realistic textures, new systems and FMC, two of three engines variants are now accurately impliemented. Future changes will focus on fully simulating failures and continually focus on accurately recreating various 747-400 variants .
The github repository contains the latest versions, including the LCF model variant by Lee_Hyeon_Seo (with permission) with the existing improvements, check out the working his [A340 developements](https://forums.x-plane.org/index.php?/forums/topic/203381-3d-cockpit-for-a340/&)

Custom sounds and display textures by [Matt726](https://youtube.com/c/matt726)

Old custom sounds from [FTSim+](https://k-akai.blogspot.com/) (with permission)

We greatly thank FTSim+ for the former soundpack, and wish them good luck on other soundpacks! [Check them out!](https://k-akai.blogspot.com/)

The general concept is to bring the aircraft as close to the real version as is achievable, please refer to original 747-400 material such as the widely distributed FCOM for details on how the aircraft functions.

**How did you acheive such high framerates?**

This overhaul converts all the existing 744 systems, along with all the numerous additions from XLua, which is single threaded and directly impacts X-Plane framerates, to XTLua, a fork of XLua which maintains general compatibility with XLua, but takes all the aircraft systems off the X-Plane flight simulation thread and makes full use of a modern multithreaded operating system (use Linux for the best results, but Microsoft Windows and macOS are also supported).

XTlua is described in more detail [here](https://forums.x-plane.org/index.php?/forums/topic/209883-xtlua-parallel-lua-for-complex-aircraft-systems/)

XTlua source is [here](https://github.com/mSparks43/XLua/tree/xTLua)

**How can I contribute?**

Please use the [github issue page](https://github.com/mSparks43/747-400/issues) if you find a problem. If your issue is already listed please add your details, problems that can be recreated are generally fixed quickly.

The 744 project was licenced as CC-BY-NC 4 on the 1st of May 2019, anyone with any confusion as to what this means should review the [licence](https://creativecommons.org/licenses/by-nc/4.0/)

You can follow progress, make requests and generally chat about the 747 on the 747-400 channel on the [Go Ahead discord server.](https://discord.gg/cStTXy5)

Feel free to join the conversation, fork this repository, and make the plane your own.

**How can I remove the boarding music or PA announcements?**

Head to the FMC MENU > ACMS > MAINT > SIMCONFIG. Here you can find many settings for the aircraft, including sound options.

**How do I connect the GPU?**
GPU can be connected in the Ground Handling menu in the FMS.


### Installation
Just extract the zip to your aircraft folder (delete any existing copy, **do not overwite an existing aircraft installation**)

Integration with [Terrain Radar](https://forums.x-plane.org/index.php?/files/file/37864-terrain-radar-vertical-situation-display/) and [AutoATC](https://forums.x-plane.org/index.php?/files/file/45663-main-installation-files-for-autoatc-for-xplane-11/) is included which require installing seperately. Make sure you are using the latest versions of both for the fullest experience.

Windows users:
Two executables are included in the release zip file, these are required to have been installed for the aircraft systems to function.

### Troubleshooting
**How do I go direct to a waypoint?** flight plan manipulation is currently a "best effort" wrap around the default flightplan fms pages to get it as close to what is in the FCOM without going completely back to square oue.

***Some general notes***:

 - On the ground RTE and LEGS behaves the same as default X-Plane RTE and LEGS, except loading .FMS files (from the X-Plane Output/FMS Plans directory) can be achieved by pressing the right line select key (aka R3) on the RTE page

 - _Once in the air_: the LEGS page becomes the default INTC_DIR page, you can use this to go direct to by pressing L2 to L5 on page one to select the direct to destination, then L1, then exec to make it active.

- If you want to go direct to something on page 2 onwards of the LEGS page in the air, activate heading hold, go direct to the last entry on page 1, and then the entries on page 2 will move up to page one.

 - _Once in the air_, the X-Plane LEGS page can be reached by pressing RTE, and then L6 (marked RTE 2)

**What is the black console window that opens when I start the plane?** Don't close it. The console window is part of the systems monitoring and will give important information needed to report issues for example if the plane crashes to desktop. This and the X-Plane Log.txt are the two primary tools for investigating issues. **This can be disabled by deleting the xtlua_debugging.txt file from the aircrafts plugins/xtlua/64/ folder.**

**All my cockpit is black and I can't click anything?** Windows users: Please install the installers described above. Also check that the plugins/xtlua/64/win.xpl extracted correctly. Some users have reported their antivirus blocking it from being extracted. Please send an angry email to your antivirus provider along with a copy of the file if you have your time wasted by this.

**Why is my FMC blank?** certain controllers have their switches automatically bound to avionics power, if these are off it turns off the avionics needed by the FMC, either switch on the switch on your controller, or bind a key to "avionics on" and use that to bring the FMC to life

**Why can't I move?** The aircraft brakes require hydraulic pressure to function, to prevent the aircraft rolling away before the hydraulics are pressurised the wheels are fitted with chocks when starting cold and dark, remove the from the ground services menu in an FMC.

Additionally, the brake lever and X-Plane brakes are now separated, there is a new command to engage the brakes by lifting the parking brake lever.

**Why are my screens half blank?** IRS alignment cannot complete until you set the IRS position in the FMC. (INIT REF -> POS -> R4 to copy GPS position, R5 to enter it into current position. Make sure you don't move while it's aligning!

**Why do I have flickering lights and sounds when connecting to Ground Power?**
You may be experiencing this if you have SAM v3. To fix, disable the "Jetway External Power" option in SAM3 settings.

### Changelog:
See the [commit history](https://github.com/mSparks43/747-400/commits/master) for detailed changes.

## Release 2:

### Special Thanks
**kudosi**:
kudosi was extremely instrumental in providing all of the complicated engine and atmospheric formulas to calculate N1, N2, EPR, and EGT for both the GE and PW engine variants.  his tireless work to help model the engine behaviors was the key input needed to code the EEC module.  kudosi also helped with review and testing and compared XP results to real-world 747-400 flight data to ensure a realistic experience.

**dyno**:
dyno was a great help in testing the engine variants and providing feedback on technical issues and abnormal behaviors.  His efforts were greatly appreciated, especially on last-minute requests to test things prior to release.

**v1rota7e**:
v1rota7e provided valuable insight into real-world operations of a 747-400.  He gave guidance on engine and EICAS behaviors, and gave feedback during test flights on where he saw things that were both good and bad from a realism point of view.

**jcomm**:
jcomm helped considerably resolving vspeed and speed tape and other behaviours which proved difficult to resolve.

**Everyone else**:
A huge thank you to all the others who helped, tested, crashed, took her for long and short hauls and filed issues when they found things awry.

**Changes 02/11/2020 - 23/09/2021:**

- Reworked autopilot logic
- New fmod sounds (Matt726-S and crazytimtimtim)
- AutoATC integration (beta, WIP) - voice commands/ATC/ACARS/DPDLC/Flightplanning/Live METAR & TAF (full functionality requires Android application, turn off center radio to remove "ACARS NO COMM" message when not connected)
- Updates for Terrain Radar integration (DrGluck)
- Autothrottle improvments, speed up autothrottle to 5 seconds min to max
- Updated approach/loc mode switching
- Panel clipping fixes
- xtlua bug fixes
- ND updates - textures and icons (MCCVeen, Matt726-S)
- Engines
  - spool up times (assistance from kudosi)
  - accurate by type engine performance and display (Marauder28 and kudosi)
- Updated landing gear
  - body gear steering
  - increased shock absorption (reduce/prevent bouncing)
- Spoiler fixes
- CMC/ACMS  (Matt726-S)
- ECS page
- Autobrake CAS msgs (flfy)
- Split rudder
- transponder/tcas fixes
- Livery specific aircraft configuration (Marauder28)
- cockpit panel textures overhaul (Matt726-S)
- VR specific commands for home cockpit
- Accurate slat behaviour
- New VR configuration file. (bigoil7 Valtime)
- CG% & TRIM calcs (Marauder28)
- Slip/skid indicator fixes (flfy)
- PAX/CARGO loading (Marauder28)
- Accurate Vspeed minimums (jcomm)
- ILS manual/autotune logic 
- ILS LOC/GS dots
- Fix CDU swipe and electrical CAS
- Main batt discharge warning
- Antiicing fixes
- Tank to engine logic
- Top of descent distance calculation and icon
- Numerous flight director behaviour fixes
- Liveries by fscabral
- Saudia livery (aboodilatif)
- Made cockpit lighting more orange and other lighting fixes
- Comm 1 and 2, and display power logic
- Checklist (Matt726-S)
- Door page (crazytimtimtim)
- Cost indexing to vnav cruise (gHashFlyer)
- Pull up and windshear on PFD (Matt726-S)
- APU
  - Battery
  - Inlet door logic (Juppie902)
  - power logic (crazytimtimtim)
- Font updates (Matt726-S)
- Yaw damper only on when IRU aligned (crazytimtimtim)
- Clear takeoff flaps ref after 1000 feet
- Sound Options (crazytimtimtim)
- VNAV LRC page (gHashFlyer)
- Added support for metric fuel weight displays (gHashFlyer)
- HOLD FMA logic
- Always deploy speedbrake when reverse thrust is applied
- Numerous PFD and FMA fixes
- "RF" and "LO" lower eicas warnings (crazytimtimtim)
- Variable IRS align timing

**Release 1: up to 02/11/2020:**

- fuel fixes
- font, image and texture overhaul
- Fuel Weights & ND Waypoint Display Tweaks
- Speed tapes
- CRT display selectors
- Global Supertanker support
- VNAV overhaul to 747-400 specification
- Electrical Synoptic
- Fuel Units - Selectable by LSK
- Thrust references
- Hydraulic synoptic
- Split rudder
- VR move commands
- Custom parking brake command
- Chocks
- CRT selector implementation
- autolatch flap handle
- Autoland
- Fixed VR manipulators
- ground handling on FMC
- TOGA implimentation
- updated lighting
- ILS tuning and autotune
- new TOD implimentation
- engine sound banks
- bug fixes to fuel, engines and autopilot
- Numerous CAS and FMC messages
- speed and altitude knob depress functionality
- engine vibration
- IRS simulation
- blackened displays when IRS not aligned
- Nav radio autotuning
- fix fire test button
- Thrust limiting
- fixed landing gear through floor
- xlua depreciated for XTLua
- 3 indpendant FMS objects
- custom FMS
- fix autobrake animating parking brake
- brake source light
- flight envelope protection
- Added sounds from https://k-akai.blogspot.com/ (with permission)
- voice commands
- engine 4 fuel consumption fixed
- fixed FMS buttons
- green screen CDUs
- Hydraulic system simulation

