# Implementing librain to your project

## Prerequisites
 - librain latest release (https://github.com/skiselkov/librain/releases)
 - libacfutils latest release (https://github.com/skiselkov/libacfutils/releases)
 - X-Plane SDK (https://developer.x-plane.com/sdk/plugin-sdk-downloads/)
 - Understanding basic plugin structure for X-Plane and X-Plane's SDK
 - Adding a DLL (or similar on other platforms) to your project

### Adding headers
After you copied all the required inclues to their place you can include the required headers.
```cpp
#include "include/librain.h"
#include "include/obj8.h"
```

### Define window/windshield object(s)
```cpp
const char *windShieldObjPath = "path/to/your/windshield.obj";
```

### Define object's position offset

This is added to the object's basic origin point. Set this if you are using
object position offsets in Plane Maker under the Misc Objects window.

```cpp
vect3_t pos_offset = { 0, 0, 0 };
```

### Parse the object 

This must be done before calling ``librain_init``.

```cpp
obj8_t *windShieldObj = obj8_parse(windShieldObjPath, pos_offset);
```

### Specify the shader's directory

Be sure to ship the contents of the shader directory in your product.
The library needs to load these shaders during ``librain_init``.

```cpp
const char *shaderDir = "librain-shaders";
```

### Define glass elements
Define all glass elements which should get the rain animation. You should have separate properties for each glass element, like front windshield, side window, etc. See the `librain_glass_t` below.
To get all available properties and how to use them, see https://github.com/skiselkov/librain/blob/master/src/librain.h

```cpp
static const vect2_t tp = { 0.5, -0.3 };
static const vect2_t gp = { 0.5, 1.3 };
static const vect2_t wp = { 1.5, 0.5 };

static librain_glass_t windShield = {
	.group_ids = NULL,     // const char **
	.slant_factor = 1.0,   // double
	.thrust_point = tp,    // vect2_t
	.gravity_point = gp,   // vect2_t
	.gravity_factor = 0.5, // double
	.wind_point = wp,      // vect2_t
	.wind_factor = 1.0,    // double
	.wind_normal = 1.0,    // double
	.max_tas = 100.0,      // double
	.therm_inertia = 20.0, // float
	.cabin_temp = 22.0     // float
};

static librain_glass_t sideWindow = { ... };

static librain_glass_t glassElementsArray[2] = { windShield, sideWindow };
...
```

### Init
```cpp

PLUGIN_API int XPluginStart(
	char *outName,
	char *outSig,
	char *outDesc)
{

	librain_set_debug_draw(TRUE);
	...
	librain_init(shaderDir, glassElementsArray, 1);
	XPLMRegisterDrawCallback(draw_rain_effects, xplm_Phase_LastScene,
	    0, NULL);
	...
	return g_window != NULL;
}
```

Don't forget to unregister the callback when the plugin in unloaded and
de-initialize the library. Otherwise you will be leaking memory.
```cpp
PLUGIN_API void XPluginStop(void)
{
	librain_fini();
	XPLMUnregisterDrawCallback(draw_rain_effects, xplm_Phase_LastScene,
	    0, NULL);
}

```

### Adding callback for drawing rain
```cpp
static int draw_rain_effects(
	XPLMDrawingPhase inPhase,
	int              inIsBefore,
	void             *inRefcon)
{
	librain_draw_prepare(FALSE);
	/*
	 * Since the windshield effect needs to be manually occluded, we
	 * would now call ``librain_draw_z_depth`` with additional OBJs
	 * that serve as the masking objects. Typically this would be things
	 * like the cockpit interior and/or exterior fuselage model - anything
	 * that could cover the windshield.
	 */
	librain_draw_exec();
	librain_draw_finish();
	return 1;
}
```

You have to call `librain_draw_z_depth(...)` for all the objects which can
block the view of the glass element that receives the rain animation. This
is used to populate the z-buffer of the scene and occlude the rendered
rain effect.

As the library only requires the outline of the objects to be correct, you
are encouraged to use low-poly versions of these objects to improve
rendering performance.

---

### Very basic sample plugin
```cpp
#include "include/librain.h"
#include "include/obj8.h"
#include "XPLMDisplay.h"
#include "XPLMGraphics.h"
#include "XPLMUtilities.h"
#include <string.h>
#include <math.h>

#if IBM
# include <windows.h>
#endif
#if LIN
# include <GL/gl.h>
#elif __GNUC__
# include <OpenGL/gl.h>
#else
# include <GL/gl.h>
#endif

#ifndef XPLM300
# error This is made to be compiled against the XPLM300 SDK
#endif

static const char *windShieldObjPath = "path/to/your/windshield.obj";
static const vect3_t pos_offset = { 0, 0, 0 };

char *shaderDir = "librain-shaders";

vect2_t tp = { 0.5, -0.3 };
vect2_t gp = { 0.5, 1.3 };
vect2_t wp = { 1.5, 0.5 };

static librain_glass_t windShield = {
	.slant_factor = 1.0,
	.thrust_point = tp,
	.gravity_point = gp,
	.gravity_factor = 0.5,
	.wind_point = wp,
	.wind_factor = 1.0,
	.wind_normal = 1.0,
	.max_tas = 100.0,
	.therm_inertia = 20.0,
	.cabin_temp = 22.0
};

static librain_glass_t glassElementsArray[1] = { windShield };

static int draw_rain_effects(
	XPLMDrawingPhase inPhase,
	int              inIsBefore,
	void             *inRefcon)
{
	librain_draw_prepare(FALSE);
	/* Load these OBJs using obj8_parse as necessary */
	librain_draw_z_depth(compassObj, NULL);
	librain_draw_z_depth(fuselageObj, NULL);
	librain_draw_exec();
	librain_draw_finish();
	return 1;
}

PLUGIN_API int XPluginStart(
	char *outName,
	char *outSig,
	char *outDesc)
{
	strcpy(outName, "HelloWorld3RainPlugin");
	strcpy(outSig, "librain.hello.world");
	strcpy(outDesc, "A Hello World plug-in for librain");

	/*
	 * Load our windshield object. You will also want to load
	 * any additional objects used for z-buffer filling.
	 */
	glassElementsArray[0].obj = obj8_parse(windShieldObjPath, pos_offset);
	if (glassElementsArray[0].obj == NULL) {
		XPLMDebugString("Oh noes, failed to load the windshield OBJ!");
		librain_fini();
		return (0);
	}

	/* Once we have loaded all OBJs, initialize the glass structures. */
	if (!librain_init(shaderDir, glassElementsArray, 1)) {
		XPLMDebugString("Oh noes, failed to initialize librain!");
		return (0);
	}
	/*
	 * Turn on debug drawing. This makes all z-buffer drawing
	 * visible to verify it's working right. When you are satisfied
	 * it is working as intended, remove this line.
	 */
	librain_set_debug_draw(TRUE);

	XPLMRegisterDrawCallback(draw_rain_effects, xplm_Phase_LastScene,
	    0, NULL);

	return (1);
}

PLUGIN_API void XPluginStop(void)
{
	librain_fini();
	XPLMUnregisterDrawCallback(draw_rain_effects, xplm_Phase_LastScene,
	    0, NULL);
}

PLUGIN_API void XPluginDisable(void)
{
}

PLUGIN_API int XPluginEnable(void)
{
	return 1;
}

PLUGIN_API void XPluginReceiveMessage(XPLMPluginID inFrom, int inMsg,
    void *inParam)
{
}
```

### How to add wipers

Wipers are defined using 3 parameters:

* Wiper pivot point XY-coordinate in rain texturing space. That means
  the value will be something like {0.5, 0.4}.
* Outer radius of swept area.
* Inner radius of swept area.

You also need to register a flight loop callback and tell the library
each frame how each wiper is moving.

Below is a simple sample implementation that should be added onto the
examples above. Please note that all angles are in radians and increase
in the clockwise direction. An angle of 0 means straight up along the Y
axis of the texture. The wiper animation code below is simply a
minimalistic implementation. Use it as inspiration to tie into your
systems simulation.

```cpp
/* Wiper pivot positions - the wipers spin around these points. */
static const vect2_t wiper1_pivot = { 0.4, 0.2 };
static const vect2_t wiper2_pivot = { 0.6, 0.2 };

/*
 * Define the glass object as usual and add the wiper definitions.
 * A single glass object can hold up to 2 wipers.
 */
static librain_glass_t windShield = {
	...
	.wiper_pivot = { wiper1_pivot, wiper2_pivot },
	/*
	 * Both wipers have an outer radius of 0.4 and an inner radius of 0.05.
	 * If you only need one wiper, leave the second inner and outer radius
	 * set to 0.
	 */
	.wiper_radius_outer = { 0.4, 0.4 },
	.wiper_radius_inner = { 0.05, 0.05 },
};

static librain_glass_t glassElementsArray[1] = { windShield };

/* We use this to track where each wiper is currently located. */
static double wiper_angle[2] = { 0, 0 };

/*
 * Wiper angular velocity in radians per second. We use this to control
 * animation rate. Wiper [0] will be going twice as fast as wiper [1].
 * Please note that the speed of the wipers must be limited so that the
 * wiper doesn't complete a full sweep in less than 0.5 seconds,
 * otherwise some animation artifacting might occur.
 */
static double wiper_ang_vel[2] = { -M_PI * 0.8, M_PI * 0.4};

/*
 * Wiper edge positions. Wiper [0] goes _| and wiper [1] goes |_
 */
static const double wiper_edge[2][2] = {
    {	-M_PI / 2,	0		},
    {	0,		M_PI / 2	}
};

/* We'll be animating the wipers in this flight loop callback. */
static float wiper_floop(float delta_t, float time2, int counter, void *refcon);

PLUGIN_API int XPluginStart(
	char *outName,
	char *outSig,
	char *outDesc)
{
	...
	/*
	 * For debugging purposes, we'll enable visible wiper drawing.
	 * Remove this to get rid of the red outlines.
	 */
	librain_set_wipers_visible(TRUE);
	/*
	 * Register the animation callback. Execute every flight loop.
	 */
	XPLMRegisterFlightLoopCallback(wiper_floop, -1, NULL);
	...
}

PLUGIN_API void XPluginStop(void)
{
	...
	XPLMUnregisterFlightLoopCallback(wiper_floop, NULL);
}

static float
wiper_floop(float delta_t, float time2, int counter, void *refcon);
{
	for (int i = 0; i < 2; i++) {
		wiper_angle[i] += wiper_ang_vel[i] * delta_t;

		/* Wiper hit edge of movement? Reverse direction. */
		if (wiper_angle[i] < wiper_edge[i][0]) {
			wiper_ang_vel[i] = -wiper_ang_vel[i];
			wiper_angle[i] = wiper_edge[i][0];
		} else if (wiper_angle[i] > wiper_edge[i][1]) {
			wiper_ang_vel[i] = -wiper_ang_vel[i]
			wiper_angle[i] = wiper_edge[i][1];
		}
		/*
		 * Even if the wiper is not moving, you MUST call this function
		 * with the angle unchanged and the last element set to FALSE.
		 * Otherwise the animation is not going to look right when the
		 * wipers are stopped.
		 */
		librain_set_wiper_angle(&glassElementsArray[0], i,
		    wiper_angle[i], TRUE);
	}
	/* This needs to execute every flight loop. */
	return (-1.0);
}
```
