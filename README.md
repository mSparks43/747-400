---
header-includes:
  - \usepackage{hyperref}
  - \usepackage[utf8]{inputenc}
  - \hypersetup{colorlinks=true,
            urlcolor=blue,
            linkcolor=blue,
            allbordercolors={0 0 0},
            pdfborderstyle={/S/U/W 1}}        
geometry: "left=1.5cm,right=1.5cm,top=2cm,bottom=2cm"
colorlinks: true  

       
---

# Sparky744: The Boeing 747-400 fleet

You can follow progress, make requests and generally chat about the 747 on the 747-400 channel on the [Go Ahead discord server.](https://discord.gg/cStTXy5) and follow the project on [twitter](https://twitter.com/GoAheadFly)

Feel free to join the conversation, fork the github repository, and make the plane your own.

## Major Overhaul of the Laminar Boeing 747-400

This overhaul attempts to capture the life of the 747-400 aircraft in as much realistic, intricate detail as can be achieved by the flight simulator community.

The latest release includes accurately recreated performance and displays for all three engine variants, new object models for RB211 engines, highly performant new systems, cross platform voice commands, VR support and all new FMC with integrated ACARS/CPDLC.

This project is an open source project, consisting of developers gathering from all over the world wanting to recreate the worlds fleet of 747-400s.

Several accurately recreated 744 airframes are included, along with a 744LCF, 744BCF variants can be recreated by downloading an appropriate BCF livery. New fuselage models, including the 744F are a work in progress.

The general concept is to bring each aircraft as close to the real version as is achievable, please refer to original 747-400 material such as the widely distributed FCOM for details on how the aircraft functions.

## Contacts:

Please use the [github issue page](https://github.com/mSparks43/747-400/issues) if you find a problem. If your issue is already listed please add your details, problems that can be recreated are generally fixed quickly.

The 744 project was licenced as CC-BY-NC 4 on the 1st of May 2019, anyone with any confusion as to what this means should review the [licence](https://creativecommons.org/licenses/by-nc/4.0/)

## Installation
To install, extract the zip into your aircraft folder (delete any existing copy, **do not overwite an existing aircraft installation**)

Integration with [Terrain Radar](https://forums.x-plane.org/index.php?/files/file/37864-terrain-radar-vertical-situation-display/) and [AutoATC](https://autoatc.zem-solutions.com) is included which require installing separately. Make sure you are using the latest versions of both for the fullest experience.


### Linux users (and all others)

Extract the contents of the zip file to your aircaft directory

### Windows users:

Two executables are included in the release zip file, these are required to have been installed for the aircraft systems to function.

### MacOS users

After extracting the zip file to your X-Plane aircraft directory you will need to execute

sudo xattr -dr com.apple.quarantine *

From a terminal inside the X-plane folder. 

## Troubleshooting and FAQ

### ***Some general notes***:

 - On the ground RTE and LEGS behaves the same as default X-Plane RTE and LEGS, except loading .FMS files (from the X-Plane Output/FMS Plans directory) can be achieved by pressing the right line select key (aka R3) on the RTE page

 - _Once in the air_: the LEGS page becomes the default INTC_DIR page, you can use this to go direct to by pressing L2 to L5 on page one to select the direct to destination, then L1, then exec to make it active.

- If you want to go direct to something on page 2 onwards of the LEGS page in the air, activate heading hold, go direct to the last entry on page 1, and then the entries on page 2 will move up to page one.

 - _Once in the air_, the X-Plane LEGS page can be reached by pressing RTE, and then L6 (marked RTE 2)


### **Does this aircraft work in VR?**

Yes! Very much so. A complex aircraft simulation working well in VR is a key motivation of many contributors and users. Once you try this plane in VR it is likely you will never want to go back to 2D.

### **How did you achieve such high frame rates?**

This overhaul converts all the existing 744 systems, along with all the numerous additions from XLua, which is single threaded and directly impacts X-Plane frame rates, to XTLua, a fork of XLua which maintains general compatibility with XLua, but takes all the aircraft systems off the X-Plane flight simulation thread and makes full use of a modern multi-threaded operating system (use Linux for the best results, but Microsoft Windows and macOS are also supported).

XTlua is described in more detail [here](https://forums.x-plane.org/index.php?/forums/topic/209883-xtlua-parallel-lua-for-complex-aircraft-systems/)

XTlua source is [here](https://github.com/mSparks43/XLua/tree/xTLua)

### **How do I use ACARS/CPDLC**

ACARS/CPDLC provides real world data to the FMC and as such requires a "provider" to be written and installed. An [AutoATC](https://forums.x-plane.org/index.php?/files/file/45663-main-installation-files-for-autoatc-for-xplane-11/) provider is included (Android connection required) which currently provides full flight planning, METAR and TAF reports along with ATC integration (AI ATC now with discord support a work in progress). Other networks, such as VATSIM/Hoppie and IVAO will require a similar provider integrating with the aircraft systems. You should refer to the [Go Ahead discord server.](https://discord.gg/cStTXy5) and the respective networks support channels for further information and help. 

(Please note; providers that do not support all platforms will not be accepted into the aircraft distribution)

### **How can I remove the boarding music or PA announcements?**

Head to the FMC MENU > AIRCRAFT CONFIG (R6). Here you can find many settings for the aircraft, including sound options.

### **How do I connect ground power?**

The GPU can be connected in the FMS ground handling menu.

### **How do I go direct to a waypoint?** 

Flight plan manipulation is currently a "best effort" wrap around the default flightplan fms pages to get it as close to what is in the FCOM without going completely back to square oue.

### **What is the black console window that opens when I start the plane?** 

Don't close it. The console window is part of the systems monitoring used during development and will give important information needed to report issues. For example if the plane crashes to desktop. This and the X-Plane Log.txt are the two primary tools for investigating issues. **This can be disabled by deleting the xtlua_debugging.txt file from the aircraft's plugins/xtlua/64/ folder.**

### **All my cockpit is black and I can't click anything?**

Windows users: Please install the installers described above. Also check that the plugins/xtlua/64/win.xpl extracted correctly. Some users have reported their antivirus blocking it from being extracted. Please send an angry email to your antivirus provider along with a copy of the file if you have your time wasted by this.

### **Why can't I move?** 

The aircraft brakes require hydraulic pressure to function, to prevent the aircraft rolling away before the hydraulics are pressurized the wheels are fitted with chocks when starting cold and dark, remove the from the ground services menu in an FMC.

Additionally, the brake lever and X-Plane brakes are now separated, there is a new command to engage the brakes by lifting the parking brake lever.

### **Why are half my screens blank?** 

IRS alignment cannot complete until you set the IRS position in the FMC. (INIT REF -> POS -> R4 to copy GPS position, R5 to enter it into current position. Make sure you don't move while it's aligning!

### **Why do I have flickering lights and sounds when connecting to Ground Power?**

You may be experiencing this if you have SAM v3. To fix, disable the "Jetway External Power" option in SAM3 settings.

## Changelog:
See the [commit history](https://github.com/mSparks43/747-400/commits/master) for a detailed change log.

_Thank you all for your support and contributions!_

## Release XP12.3.0-2025/10/27 (OP Program XP12-30-2025/10/27):

### Bug fixes

 - fix systems crashes caused by VNAV profile calculations

## Release XP12.3.0-2025/09/20 (OP Program XP12-30-2025/09/20):

Culmination of fixes to date, Focus on XP12.3 weather radar

### Enhancements

 - XP12.3 Weather Radar support
 - Weather Radar Panel interactions and lighting
 - VNAV profile following
 - Sync baro from either side
 - Improve THR REF animations and targeting

### Bug fixes

 - Throttle becoming unresponsive
 - XP12 ground power unit fixes
 - GE engine fixes
 - dont run parking brake in replay 
 - Added visual enhancements to PW4000 & CF6 (rossf93)
 - Wait for user throttle input before moving throttle lever
 - Fix systems crash reading cruise altitude 
 - VR button fixes for Linux and Windows
 - Wing sweep option for toe brakes (e.g. single VR axis)
 - Fix auto fuel management
 - Fix com power notification when using com 2
 - Optimize all png images using pngquant (ErgerSusha)
 - HDG SEL shouldn't toggle
 - hard off XP AT
 - WXR dont draw over text

## Release XP12.2.0-2025/04/27 (OP Program XP12-10-2025/04/27):

Culmination of fixes to date, put XP11 and XP12 versions into a single package. Focus on ACARs, Throttle and autopilot.

### Bug fixes

 - Overrides not cleared loading a different aircraft (#887)
 - Various throttle and parking brake fixes (#892)
 - Dont set throttle angle while reversers are deployed
 - Update flap display
 - Hide no v spd above 10 feet RA
 - Handle NEXT CTR acars messages
 - Cleanup ACARS page titles
 - Fix vnav autodescend
 - Fix FMS crashing when trying to switch to custom and not in custom
 - VNAV and ACARS testing and fixes
 - Dont call out positive rate if wheels still on ground
 - Update target alt hold in VNAV resume
 - Fix vs button
 - Hoppie ACARS fixes
 - Tidy ACARS message view page
 - Impl range arc for terr/wxr, improve high alt pitch PID
 - Check max cruise altitude, fix dome light, check acarsDataReady in sendCompany
 - Reinstate cruise alt check for cruise alt mode switch
 - Check for AT disconnect button state
 - Fix ACARS message view page numbering
 - Impliment engine fail warnings
 - Set steer hi speed to 20 knots
 - Check isATEnabled in vnav updates
 - Fix AT disabled check
 - Dont set AT FMA to IDLE if not AT enabled
 - Update AP parameters
 - Ensure irsSystem aligned gets set to true when alignment completes
 - Fix typo in irs_system, better cduTarget page logging
 - Make pitch integral less agressive, dont autoset squawk if squaking 7600 or 7500
 - IRS tweeks
 - Set VNAV target to airport for approach
 - Fix VPI
 - Remove spurious find_dataref
 - XP11 sound and throttle fixes
 - Fix line length of POS INIT
 - Fix XP11 compass roses
 - Send current plan with ACARS initialisation
 - Extract arr and dep airports from flightplan for ACARS init

## Release XP12.1.0-2024/06/02 (OP Program XP12-10-2024/06/02 08:57):

Small but meaningful fixes

### Bug fixes

 - Fix reversed strobe light switch
 - EPR PID tuning (cause of redlining in #885)
 - Update animation functions
 - Reinstate SPD mode if switching AT on while on the glideslope
 - Send L1 to default FMC in RTE if not on page one
 - Send R1 to default FMC in RTE if not on page one
 - Fix reverse thrust mode clearance
 - Check have ToD before pausing at ToD


## Release XP12.1.0-2024/05/26 (OP Program XP12-10-2024/05/25 10:35):
Updates focusing on systems, ACARs and autopilot.

### Bug fixes
 - ETA time reports 60 for minutes instead of 00 (#864)
 - Remove floating strobe light in front of cockpit (#863)
 - Fix conflict conflict between X-Plane and custom autopilot
 - Hold all reverse thrust now cancels TOGA
 - Disable flight envelope protection below 15 feet AGL
 - Fix MAIN BATT DISCH message 
 - Replace X-Plane Autothrottle commands
 - Fail A/T is disarmed in active state
 - Set fltno from ATC LOGON/STATUS page
 - Fix pitch hold during TOGA 
 - Reduce yaw damper throw to 3.5 degrees 
 - FMC scratch pad stuck with error message, "Unable 5000 at GIRRR" (#859)
 - Co pilot ND missing waypoint lines (#862)
 - X-Plane 11 wipers, wiper blades not working (#849)
 - Consider prop mode when pinning levers
 - Always use prop mode 3 when reversers deployed 
 - Remove flaps condition from wing anti ice
 - Fix airborne start
 - Remove throttle down command from drag required logic
 - Fix conflict with X-Plane autothrottle.
 - Fix CDU data transfer for android FMC
 - Fix fire handles don’t actually shutoff engines (#337)
 - Some sound fixes

### Enhancements

 - Integrated Hoppie and AutoATC ACARs support
 - Erase ACARS log
 - ACARS downlink messages page and datalink active 
 - Display inforeq downlinks
 - ACARS position reporting
 - ATC REQUEST pages 1-4
 - When can we ACARS pages 
 - ACARS REQUEST VERIFY and SEND
 - Emergency report and verify ATC pages
 - Start windows iced up when cold and dark at a freezing airport
 - Better cabin lighting (thanks to KSB인천국제공항공사)
 - Improve reverse handling
 - Flight Data Recorder visualisations and better logging
 - FLCH tuning
 - Update IAS to mach switch speed to match FCOM section 4.10.4/5 
 - AT during landing tuning
 - Overhaul throttle IO 
 - Add some give to center body gear 
 - Implement Cruise Climb per FCOM section 11.31.22 
 - Manual throttle animation speed increase
 - Incorporate Garen Evans fuel management script (auto tank to engine) 
 - Update ECC thrust targets
 - Improved Flight director
 - Consider ToD for VNAV end descent
 - Flight test analysis framework
 - Add T/C and progress reporting


## Release XP1206-2023/10/01:
Bug fix and enhacements release of issues reported since previous release

### Bug fixes

 - Engine RPM increases at the moment "LAND3" appears on PFD #857 
 - First officer´s ND in XP11 has bugs #851 
 - Fix autothrottle toggle switch bind label
 - Require cruise altitude set for ACARS/CPDLC initialisation
 - Fix DESTINATION NOT SET message
 - Report destination not set if destination is not an airport
 - Hydraulic pressure tuning
 - Better PROG fuel estimate on the ground

### Enhancements

 - Added Cockpit Seats Show/Hide (Silver-Eagle-Cherokee)
 - Reply to ACARS/CPDLC messages initial
 - Add CONFIG GEAR CTR warning
 - ATC LOG page initial

## Release XP1206-2023/08/12:
Bug fix release of issues reported since previous release

### Bug fixes

 - Default HI bright spill lights to off, adjust for nightime
 - Reduce VS rate for maximum capture window 
 - Some lighting tuning (strobe, cabin lights)
 - Some throttle behaviour fixes (only set simDR_engn_thro in ECC if AT active)
 - Reduce spoiler hydraulic consumption
 - Fix arm RTO when no joystick axis mapped (mouse flyers)
 - ACARS view message number of pages FMC isolation 
 - Fix lack of ACARs view message isolation

## Release XP1206-2023/08/05:
XP12 and XP11 release improving XP12 lighting support and updating systems

### Enhancements

 - Smoother TOGA
 - Storm light and FMC options by @Silver-Eagle-Cherokee
 - XP12 Wing flex parameters from calibranr 
 - Increase tint in sun visor
 - Modify lighting exposure when looking at open sun visor (XP12 only)
 - Add ACARS postflight page
 - Go to ATCINDEX from ACARS Inflight
 - ACARS Hoppie initial compatibility changes
 - Autopilot tuning
 - Custom ATT mode
 - Work harder to catch GS if more than 2 dots off
 - Disable range arc on glideslope capture
 - Integrate fltdep and fltdst into RTE
 - Flight plan clearing on new dep or DELETE dep/dst
 - Enhanced LOC capture
 - Hydraulic leak support (XP12+) 
 - Autothrottle tuning
 - ECC thermal tuning
 - Engine spooling and thermal profile tweaking
 - Improve VS mode stability
 

### Bug fixes

 - Fix Go around
 - Clear TOGA when reaching MCP altitude
 - Heading select value not always syncing with FMS
 - Hold ILS once captured, even if flight plan deleted  
 - Keep elevator trim synchronised
 - Fix ACARS cycle reporting 
 - Fix EPR throttle targets 
 - Fix pitch sign error in ALT and FLCH modes 
 - Fix simconfig not synchronising with real time changes
 - Fix reverse throttle animation
 - Dont introduce more fuel during engine run up 
 - Fix synoptic display switching when fuel switch used
 - Revert to v2.4 CG and tank locations
 - Fixes for reverse thrust misbehaving
 - Ignore repoeated gear commands for controllers that spam the gear lever 

## Release XP1205-2023/04/09:
XP12 Milestone release based on extensive flight testing and user feedback. 

### Enhancements

 - Yet more lighting tweeks 
 - Rebalanced system load for smoother performance
 - Updated airfoil and flaps from Laminar to more closely match real world performance
 - Custom autothrottle and 4 independent ECCs
 - AutoATC voice command definitions for flaps and MCP speed/altitude/vspeed
 - EGT thermal profile
 - New Autopilot for glideslope following
 - Automatically turn off/on cabin lighting when <FL100 or groundspeed > 15kts
 - Run GC every system cycle to prevent long GC pauses
 - Version detection for XP11/XP12 systems
 - Handle start airborne on approach automatic AP activation.

### Bug fixes

 - Manual ILS tuning would fail for some airports [issue 838](https://github.com/mSparks43/747-400/issues/838)
 - fixed stabilizer animation
 - ND track/heading inconsistency
 - Throttle target remained on when EICAS display was off
 - Flight data recorder LNAV and VNAV data inverted
 - CTD in VNAV descent when above cruise altitude
 - Skipped frames in throttle and flight directors would corrupt autopilot estimates
 - Ensure LOC and GS remain active once captured
 - Thrust reverse could get out of sync
 - Range Arc using actual rather than target vertical speed
 - Wing flex force feedback causing "bounce of death"
 - CTD when weight below 180,000kg
 - Ensure max power is set on all engines
 - Go Around on TOGA press not functioning.

## Release 3.0a1 for XP12 (OP Program XP1150-2022/10/25):
Release 3.0 brings compatibility with XP12 and starts to incorporate some of the new features now available.

### Enhancements

 - 2 independent ND displays (wip)
 - Autothrottle improvements
 - Much more realistic lighting
 - initial rain and wiper effects (not perfected yet, but better than none)
 - Always use default XP legs page (direct to now possible without switching to INTC_DIR when airborne)
 
### Bug fixes

 - Engine parameters display fixes for PW/GE/RR engines
 - Brakes now cool when engaged but not slowing the plane down
 - fix default XP gear up/off/down commands

## Release 2.4 (OP Program XP1150-2022/09/04):
Release 2.4 is a bug fix release.

RB211 engines repositioned by Andromeda95

### Bug fixes

 - Fix glass
 - remove xtlua_debugging.txt from release zip
 - 813 2.3 | Testflights [LGMK 34 VARI1C VARIX R19 KEA ILS-Z-03L LGAV]
 - 817 During VNAV Descend A/T adds thrust too soon and without caution.
 - 820 AP doesn't function with both FDs off on takeoff
 - 829 A/T issue during descend with VNAV SPD


## Release 2.3 (OP Program XP1150-2022/06/26):
Release 2.3 focuses on flight model enhancements and bug fixes to the existing systems.
A very special thanks to MCCVeen and oMrSmith for their extensive testing and accurate reporting of issues, a very large number of fixes in this release wouldn't have been possible without the detailed breakdowns they provided. 

### Enhancements

 - Completely override all control surfaces
 - VNAV path pointer
 - Rudder Ratio Changer
 - Controls now consume hydraulic systems pressure 
 - Latest textures from PilotMathews
 - Brake heating visualizations and failures
 - "Always on" Flight Data Recorder records flight data for each aircraft livery
 - Improved ground rain effects (Salami002)

### Bug fixes

 - Throttle lockout during toga run up
 - fix cockpit lights voice control definition
 - Door PBR fix (Andromeda95 via org forums)
 - Missing ELEC BUS and brake EICAS messages
 - Engine logic for PW and GE engines
 - ET clock not running
 - Remove brakes from nose gear
 - Nose pitch after touchdown autoland logic
 - Fix "why is my FMS blank" issue
 - Keep speed and ALT bugs on PFDs
 - Fix battery switch guard closing completely when battery switch is off
 - Fix CRT fading
 - ACT and REQ CDU items missing
 - Engine generators disconnect APU
 - Fix AP disconnect disconnecting AT

## Release 2.2:
Release 2.2 focuses on enhancements and bug fixes to the existing systems and flight model.

### Enhancements

- New airfoils based on IRL data (zeta976 with special thanks to kudosi)
- FMOD sounds v3.0 (Matt726-S)
- New flight model for LCF variant
- New wing dynamics and ailerons
- More realistic aileron control surfaces and lockout
- "No Autoland" display logic
- RB211 object and livery updates (Dyno and Pilot Mathews)

### Bug fixes

- RR systems, ECC logic and display fixes (Marauder28)
- Animate N1 when engines aren't running
- Inhibit engine shutdown message on ground
- Fix Go Around logic
- Synchronize flight phase and ECC state
- Prevent fms page numbers less than 1 (stop "prev page" CTD)
- GE and PW ECC fixes
- Flip light switches and windscreen washers (crazytimtimtim - code, Jcsk8 - textures)
- Fix GE engines when starting on 10nm approach
- Reverser fixes and lockout
- Fix CRT fading during screen power up
- Autoland ADFS and throttle fixes (with thanks to MCCVeen for issue reporting)
- Allow thrust reverse toggle while airborne
- Throttle down in vnav if have throttle and accelerating during descent

## Release 2.1 (OP Program XP1150-2021/12/11):

On 11/12/2020 at 13:15 UTC, the last, the very last British Airways 747-400, G-BYGC took to the skies for one last flight from Cardiff (EGFF) to St. Athan (EGSY). Despite the short hop to the breaker's yard, it became an emotional farewell to an aircraft that was used by British Airways for over 50 years.

[G-BYGC](https://forums.x-plane.org/index.php?/files/file/77441-british-airways-747-400-g-bygc-rr-rb211-msparks-747/) is a 747-436 sporting RB211-524G engines- the aircraft first flew on 01/11/1999, and served with British Airways for another 21 years until its retirement on 12/11/20. The aircraft is now preserved at MOD St. Athan, and still lives on despite its official retirement.

The Sparky744 Release 2.1 celebrates this historic aircraft, bringing the RB211-524G engines into the simulator and enabling you to continue the task of recreating [G-BYGC](https://forums.x-plane.org/index.php?/files/file/77441-british-airways-747-400-g-bygc-rr-rb211-msparks-747/), and all the other 694 airframes built, with all their complex detail and history. 

### Special Thanks from **Dyno** (RB211 engine models)

**BottleRocketeer**

Bottle Rocketeer was the quintessential person in allowing me to succeed within 3D graphics, aircraft development, and the RB211's. He single-handedly taught me how to open a new file within Blender, add a cube, and shape it into what is now an engine.

**SamWise**

SamWise was one of the, if not the most important person in getting the visual element of the RB211's to modern-day standards. While I can make a boring, grey, shape, he added life and color to the grey shape- something I fail to do, and am incredibly lucky to have been able to work with him. Thank you for everything Sam!

**Pilot Mathews**

Pilot Mathews- Pilot Mathews breathed completely new air into our 747, despite the limitations imposed by the paint kit. After working many hours a day, he delivered VH-OEJ and VH-OJM to the highest possible standard, picking up the smallest details such as patches on the wings, how straight the lines of the wings are, scuffs caused by jetways, and much more. VH-OEJ and VH-OJM are both included by default in Patch 2.1, but go check out his other excellent liveries on X-Plane ORG forum!


**Changes 24/09/2021 - 11/12/2021:**

- New RB211-524 real-world data values, integration, performance tables, performance, behavior, EICAS indications
- PW, RR, and GE engine code fixes (Marauder28)
- RB211-524 model (Dyno), textures, paint kit
- VH-OEJ, VH-OJM liveries (Pilot Mathews)
- Engines selectable by livery or the FMC
- Fix fuel use during pause
- Fix floating light in LCF model
- APU timing fixes
- Fix engine 4 reverse thrust (new contributor: LuckLP)
- Altitude range arc
- Fix random throttle lever movements
- minor HYD page tweaks

## Release 2:

### Special Thanks
**kudosi**:
kudosi was extremely instrumental in providing all of the complicated engine and atmospheric formulas to calculate N1, N2, EPR, and EGT for both the GE and PW engine variants.  his tireless work to help model the engine behaviors was the key input needed to code the EEC module.  kudosi also helped with review and testing and compared XP results to real-world 747-400 flight data to ensure a realistic experience.

**Dyno**:
Dyno was a great help in testing the engine variants and providing feedback on technical issues and abnormal behaviors.  His efforts were greatly appreciated, especially on last-minute requests to test things prior to release.

**v1rota7e**:
v1rota7e provided valuable insight into real-world operations of a 747-400.  He gave guidance on engine and EICAS behaviors, and gave feedback during test flights on where he saw things that were both good and bad from a realism point of view.

**jcomm**:
jcomm helped considerably resolving vspeed and speed tape and other behaviours which proved difficult to resolve.

**Everyone else**:
A huge thank you to all the others who helped, tested, crashed, took her for long and short hauls and filed issues when they found things awry.

**Changes 02/11/2020 - 23/09/2021:**

- Reworked autopilot logic
- New FMOD sounds (Matt726-S and crazytimtimtim)
- AutoATC integration (beta, WIP) - voice commands/ATC/ACARS/DPDLC/Flightplanning/Live METAR & TAF (full functionality requires Android application, turn off center radio to remove "ACARS NO COMM" message when not connected)
- Updates for Terrain Radar integration (DrGluck)
- Autothrottle improvments, speed up autothrottle to 5 seconds min to max
- Updated approach/loc mode switching
- Panel clipping fixes
- XTlua bug fixes
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
- Transponder/TCAS fixes
- Livery specific aircraft configuration (Marauder28)
- Cockpit panel textures overhaul (Matt726-S)
- VR specific commands for home cockpit
- Accurate slat behavior
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
- "RF" and "LO" lower EICAS warnings (crazytimtimtim)
- Variable IRS align timing

**Release 1: up to 02/11/2020:**

Introduce the LCF model variant by Lee_Hyeon_Seo (with permission) with the existing improvements, check out the working his [A340 developements](https://forums.x-plane.org/index.php?/forums/topic/203381-3d-cockpit-for-a340/&)


Custom sounds from [FTSim+](https://k-akai.blogspot.com/) (with permission)

We greatly thank FTSim+ for the former soundpack, and wish them good luck on other soundpacks! [Check them out!](https://k-akai.blogspot.com/)

- Fuel fixes
- Font, image and texture overhaul
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
- Autolatch flap handle
- Autoland
- Fixed VR manipulators
- Ground handling on FMC
- TOGA implimentation
- Updated lighting
- ILS tuning and autotune
- New TOD implimentation
- Engine sound banks
- Bug fixes to fuel, engines and autopilot
- Numerous CAS and FMC messages
- Speed and altitude knob depress functionality
- Engine vibration
- IRS simulation
- Blackened displays when IRS not aligned
- Nav radio autotuning
- Fix fire test button
- Thrust limiting
- Fixed landing gear through floor
- xlua depreciated for XTLua
- 3 independent FMS objects
- Custom FMS
- Fix autobrake animating parking brake
- Brake source light
- Flight envelope protection
- Added sounds from https://k-akai.blogspot.com/ (with permission)
- Voice commands (cross platform)
- Engine 4 fuel consumption fixed
- Fixed FMS buttons
- Green screen CDUs
- Hydraulic system simulation

