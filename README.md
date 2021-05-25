# Boeing 747-400

## Major Overhaul of the Laminar Boeing 747-400

Thank you all for your support! This overhaul is now at the "experimental" version 1 stage. Still more todo but now has enough flight test hours under its belt to be a stable daily driver for your short and long haul needs.

**Is the 747 free?**

Yes! Of course! This project is an open source project, consisting of developers gathering from all over the world wanting to create a 747.

**What happened to the YesAviation 747?**

The YesAviation team now goes under another name, and is developing another aircraft somewhere else. Everyone sends a big thank you to the former team, and wish them good luck in their endeavors.

**What are the differences between the default 747, and the Sparky 747?**

This 747 currently includes new FMOD sounds, realistic textures, new systems and FMC, three variants of engines coming soon, a new UV map for livery creators, and many more big changes in the future.
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


### Installation
Just extract the zip to your aircraft folder, with some caveats:

Windows users:
You need to manually install [C++ support](https://www.microsoft.com/en-us/download/details.aspx?id=13523) and [multithreading support](https://aka.ms/vs/16/release/vc_redist.x64.exe) in order to use this aircraft.

(aka.ms is a microsoft domain - linked from https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads)

### Troubleshooting
**How do I go direct to a waypoint?** flight plan manipulation is currently a "best effort" wrap around the default flightplan fms pages to get it as close to what is in the FCOM without going completely back to square oue.

***Some general notes***:

 - On the ground RTE and LEGS behaves the same as default X-Plane RTE and LEGS, except loading .FMS files (from the X-Plane Output/FMS Plans directory) can be achieved by pressing the right line select key (aka R3) on the RTE page

 - _Once in the air_: the LEGS page becomes the default INTC_DIR page, you can use this to go direct to by pressing L2 to L5 on page one to select the direct to destination, then L1, then exec to make it active.

- If you want to go direct to something on page 2 onwards of the LEGS page in the air, activate heading hold, go direct to the last entry on page 1, and then the entries on page 2 will move up to page one.

 - _Once in the air_, the X-Plane LEGS page can be reached by pressing RTE, and then L6 (marked RTE 2)

**What is the black console window that opens when I start the plane?** Don't close it. The console window is part of the systems monitoring and will give important information needed to report issues for example if the plane crashes to desktop. This and the X-Plane Log.txt are the two primary tools for investigating issues.

**All my cockpit is black and I can't click anything?** Windows users: Please install the installers linked above. Also check that the plugins/xtlua/64/win.xpl extracted correctly. Some users have reported their antivirus blocking it from being extracted. Please send an angry email to your antivirus provider along with a copy of the file if you have your time wasted by this.

**Why is my FMC blank?** certain controllers have their switches automatically bound to avionics power, if these are off it turns off the avionics needed by the FMC, either switch on the switch on your controller, or bind a key to "avionics on" and use that to bring the FMC to life

**Why can't I move?** The aircraft brakes require hydraulic pressure to function, to prevent the aircraft rolling away before the hydraulics are pressurised the wheels are fitted with chocks when starting cold and dark, remove the from the ground services menu in an FMC.

Additionally, the brake lever and X-Plane brakes are now separated, there is a new command to engage the brakes by lifting the parking brake lever.

**Why are my screens half black?** IRS alignment cannot complete until you set the IRS position in the FMC. (INIT REF -> POS -> R4 to copy GPS position, R5 to enter it into current position.

### Changelog:
See the [commit history](https://github.com/mSparks43/747-400/commits/master) for detailed changes.

To 02/11/2020:

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

