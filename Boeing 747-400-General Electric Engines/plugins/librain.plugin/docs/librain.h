/*
 * CDDL HEADER START
 *
 * This file and its contents are supplied under the terms of the
 * Common Development and Distribution License ("CDDL"), version 1.0.
 * You may only use this file in accordance with the terms of version
 * 1.0 of the CDDL.
 *
 * A full copy of the text of the CDDL should have accompanied this
 * source.  A copy of the CDDL is also available via the Internet at
 * http://www.illumos.org/license/CDDL.
 *
 * CDDL HEADER END
 */
/*
 * Copyright 2018 Saso Kiselkov. All rights reserved.
 */

#ifndef	_LIBRAIN_H_
#define	_LIBRAIN_H_

#include <acfutils/types.h>

#include "librain_common.h"
#include "obj8.h"

#ifdef __cplusplus
extern "C" {
#endif

#define	MAX_WIPERS	2

/*
 * Grand Theory Description:
 *
 * librain uses custom rendering inside of X-Plane's OpenGL engine to draw
 * rain using a complicated multi-stage set of shaders. You need to pass
 * some configuration structures to librain and drive it via some plugin
 * callbacks.
 *
 * The primary configuration mechanism for the rain-on-glass and ice-on-glass
 * portion of librain is via the librain_glass_t structure. To control
 * airframe icing simulation, see surf_ice.h.
 *
 * At plugin load time, you will want to call librain_init() to initialize
 * the library. This call takes three arguments:
 * - a path to the directory containing librain's compiled shader programs
 *   (you need to ship this with your plugin)
 * - an array of librain_glass_t structures describing the individual
 *   glass surfaces you want to simulate individually
 * - the number of items in the above array
 *
 * See below for a description of each field in the librain_glass_t
 * structure. To avoid leaking memory, you MUST call librain_fini() when
 * your plugin is being unloaded.
 *
 * To get librain to draw the glass surface, you must register a custom
 * post-draw callback in the xplm_Phase_LastScene phase, like this:
 *	XPLMRegisterDrawCallback(draw_effects, xplm_Phase_LastScene, 0, NULL);
 *
 * Inside the draw_effects() function, you will need to call the following
 * 4 functions:
 *
 * - librain_draw_prepare()
 * - librain_draw_z_depth() as many times as necessary to populate the Z-buffer
 * - librain_draw_exec()
 * - librain_draw_finish()
 *
 * Here's a rough description of what each of these functions does:
 *
 * 1) librain_draw_prepare()
 *	librain applies screen-space warping to simulate light refraction
 *	through individual water masses. To do so, it must first capture
 *	a "snapshot" of the scene rendered thus far. That's why all of
 *	librain's processing takes place after the "last scene" draw call,
 *	as no more 3D drawing can occur afterwards.
 * 2) librain_draw_z_depth()
 *	To obtain close-in rendering of the water effects using the X-Plane
 *	projection matrix, librain does some tricks by modifying the near-
 *	field clipping plane in the projection matrix. This unfortunately
 *	also trashes the existing Z-buffer of X-Plane. So librain uses its
 *	own Z-buffer, but in order to obtain proper depth-masking of the
 *	rendered rain effects by the aircraft interior & exterior geometry,
 *	we need redo the depth pass of many of the aircraft OBJs.
 *	librain_draw_z_depth() takes an OBJ argument and does a quick
 *	render pass to populate its depth buffer. See librain_draw_z_depth
 *	for more information.
 * 3) librain_draw_exec()
 *	This is the actual rain effect output stage. librain will already
 *	have run its internal passes earlier to move water droplets around.
 *	Here, the renderer just outputs the final 3D stages onto the
 *	screen.
 * 4) librain_draw_finish()
 *	Cleanup call that restores X-Plane's drawing state and releases
 *	any temporary resources that will not be required anymore.
 */

/*
 * This structure configures a single glass "surface" for librain and tells
 * it how to move water around on it in response to various factors. It
 * also informs librain how to finally project the surface onto an aircraft
 * OBJ.
 *
 * Everything physics-related that librain does happens in a virtual square
 * area:
 *                [0,1]                   [1,1]
 *                  +-----------------------+
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  |                       |
 *                  +-----------------------+
 *                [0,0]                   [1,0]
 *
 * In this space, librain generates water droplets when it detects
 * precipitation on the aircraft (by monitoring the
 * sim/weather/precipitation_on_aircraft_ratio dataref). It also moves
 * them around in response to three points, that you define in the
 * librain_glass_t data structure:
 *
 * - gravity_point: defines the position from which gravity "pushes"
 *	(yes, in librain gravity pushes away from a single point, instead
 *	of pulling toward it).
 * - thrust_point: defines from which point engine thrust pushes the
 *	water droplets. On multi-engine aircraft you can easily disable
 *	this, as their engines do not blow engine thrust onto the glass.
 * - wind_point: relative wind origin point. This source of force onto
 *	the water droplets represents the relative wind to the aircraft,
 *	i.e. motion of the aircraft through the air.
 *
 * Please note that the position of these points is ONLY used to
 * determine the force vector direction and NOT its strength. The force
 * imparted by each of these effects is equally strong over the entire
 * glass surface. You can set the position of these points to be away
 * from the glass 0-1 range of the coordinates as well, to simulate
 * a more uniform direction, instead of a radial force:
 *
 *                          [0.5,1.3]
 *                              G
 *                          grav_point
 *
 *                [0,1]                   [1,1]    .      .      .
 *                  +-----------------------+       .     .     .
 *                  |                       |        ^    ^    ^
 *                  |                       |         \   |   /
 *                  |                       |          \  |  /
 *                  |                       |           \ | /
 *                  |                       |         [1.5,0.5]
 *                  |                       |.. <------   W   ------> ..
 *                  |                       |         wind_point
 *                  |                       |           / | \
 *                  |                       |          /  |  \
 *                  |                       |         /   |   \
 *                  |                       |        v    V    v
 *                  +-----------------------+       .     .     .
 *                [0,0]                   [1,0]    .      .      .
 *
 *                          [0.5,-0.3]
 *                              T
 *                         thrust_point
 *
 * The relative strength of each of these forces is configured via the
 * associated "_factor" field (0.0 - 1.0), so thrust_factor,
 * gravity_factor and wind_factor.
 *
 * Once all physics computations are done on the water movement,
 * temperature and icing behavior, this space is projected as a texture
 * onto an OBJ referenced from the data structure. For example, on the
 * TBM-900, we use a separate OBJ that holds a version of the windshield
 * just for the rain effects (this OBJ is NOT placed into the
 * Miscellaneous Objects list in Plane Maker, librain completely bypasses
 * that):
 *                          [0.5,1.2]
 *                              G
 *                        gravity_point
 *                [0,1]                   [1,1]
 *                  +-----------------------+
 *                  |                       |
 *                  |                       |
 *                  |+                     +|
 *                  ||\                   /||
 *                  || --------- --------- ||
 *                  ||    R    | |   L     ||
 *                  ||   wind  | |  wind   ||
 *                  ||  shield | | shield  ||
 *                  | \________| |________/ |
 *                  |                       |
 *                  |                       |
 *                  +-----------------------+
 *                [0,0]         |         [1,0]
 *                              V
 *                        (nose of acf)
 *
 *
 *                              X
 *                    (thrust & wind point)
 *                          [0.5,-2]
 */
typedef struct {
	/*
	 * Each glass surface has an associated OBJ object which it is
	 * projected onto. Please note that librain doesn't render
	 * any material onto this OBJ and it is NOT required to be in
	 * PlaneMaker. This OBJ is simply used as a guide how to map
	 * the flat water physics model into the 3D spaces around the
	 * aircraft on final render.
	 */
	obj8_t		*obj;
	/*
	 * An optional array of strings (last element must be a NULL
	 * pointer) of X-GROUP-ID tags inside the above OBJ to render.
	 * See obj8_draw_group in obj8.h for more information on what
	 * group IDs are. When not used, you can set this pointer to
	 * NULL.
	 */
	const char	**group_ids;
	/*
	 * A relative value between 0.0 and 1.0 that controls how much
	 * water has a tendency to fall onto the glass panel as a result
	 * of its slanting backwards:
	 * - completely vertical pane (zero rain drops): slant_factor = 0
	 * - completely horizontal pane (max rain drops): slant_factor = 1
	 * You will probably want to use a slant_factor=1 for your
	 * windshield and around slant_factor=0.5 for your fuselage side
	 * windows.
	 */
	double		slant_factor;
	/*
	 * Thrust point position in relative coordinates in the physics
	 * square. See above for details on how to place this. All water
	 * droplets will be pushed AWAY from this point depending on the
	 * amount of thrust being applied.
	 */
	vect2_t		thrust_point;
	/*
	 * Controls how powerful the thrust force is on the droplets.
	 * A value of 1.0 applies the full force and a value of 0.0
	 * completely eliminates thrust-effect on the water droplets.
	 * Set this to 0.0 when your aircraft is multi-engined and thus
	 * no engine thrust hits the windows.
	 */
	double		thrust_factor;
	/*
	 * Maximum thrust value in sim/flightmodel/engine/POINT_thrust[0]
	 * which should be considered 100% thrust. This depends on your
	 * aircraft engine design. If you set thrust_factor=0, then you
	 * can leave this set to zero.
	 */
	double		max_thrust;
	/*
	 * Point from which all droplets are being pushed away due to
	 * gravity. This is in physics space coordinates.
	 */
	vect2_t		gravity_point;
	/*
	 * Relative factor controlling the strength of the gravity force.
	 * On slanted windshields, you will want to use a reduced force,
	 * such as gravity_factor=0.2, whereas on vertical panes of glass
	 * feel free to set gravity_factor=1.0 or even higher.
	 */
	double		gravity_factor;
	/*
	 * Point from which all droplets are being pushed away due to
	 * the relative wind. This is in physics space coordinates.
	 */
	vect2_t		wind_point;
	/*
	 * Relative factor controlling the strength of the wind force.
	 * You will typically want to set this to 1.0 for all glass panes,
	 * unless one of them is shielded from the direct wind effect by
	 * something.
	 */
	double		wind_factor;
	/*
	 * When the aircraft is yawing strongly, or skidding/slipping, the
	 * relative wind can come from a direction that is not directly at
	 * the wind_point, but instead can be displaced sideways. This
	 * parameter controls how strongly this occurs for this glass pane.
	 * Set this to 1.0 for fairly flat windshields, which respond to
	 * relative wind origin shifts strongly (i.e. the user will see the
	 * droplets moving side-to-side instead of just straight up or down),
	 * and to 0.0 on side windows (you don't want yawing to start
	 * moving the droplets up or down the windshield in weird ways).
	 */
	double		wind_normal;
	/*
	 * Maximum airspeed (in m/s) at which the relative wind effect
	 * reaches its maximum. A good value is around 90 to 100 (around
	 * 180 - 200 knots). The relative wind effect increases with the
	 * square between 10% of the max_tas value and the max_tas value.
	 * Above that max_tas value, the effect isn't amplified anymore:
	 *
	 *   wind   ^
	 *  effect  |
	 * strength |
	 *          |
	 * max_wind +----------------------+.........
	 *          |                     .|
	 *          |                    . |
	 *          |                  ..  |
	 *          |                ..    |
	 *          |             ...      |
	 *          |         ....         |
	 *          |    .....             |
	 *          +--+-------------------+--------->
	 *            10%               max_tas    true
	 *                                       airspeed
	 */
	double		max_tas;
	/*
	 * Controls how quickly the windshield adapts to outside wind
	 * temperatures or how quickly it heats up in response to heat
	 * from the cabin. This parameter expresses, in seconds, how
	 * quickly the windshield approaches the new temperature value
	 * to about 2/3 of the delta. A good value is 20 to 30. This
	 * means, that if the outside air temperature is 10 degrees
	 * higher than the windshield, the windshield will heat up by
	 * approximately 7 degrees in 20 seconds, then 2 degrees in
	 * the next 20 seconds, etc. The higher the value, the more
	 * "thermal inertia" the windshield has and the slower it is
	 * to respond to temperature changes either due to heating or
	 * cooling.
	 */
	float		therm_inertia;
	/*
	 * This array defines 4 optional electric heating zones that
	 * serve to melt any accumulated ice on the windshield. Each
	 * zone is defined by a 4-coordinate tuple of:
	 * [X, Y, WIDTH, HEIGHT]
	 * Each of these coordinates is in the physics space and is
	 * applied as an even heating source. You can use this to
	 * simulate an electric heating element embedded in the
	 * windshield. If the entire windshield contains an electric
	 * heating element, then simply set a single zone like this:
	 * [0, 0, 1, 1].
	 * To disable heating of a particular zone, simply set its
	 * coordinates to all zeroes. This simulates the electric
	 * heating system being switched off.
	 */
	float		heat_zones[16];
	/*
	 * Provided you have defined the appropriate heating zone
	 * coordinates in the heat_zones field above, you can set the
	 * temperature (in KELVIN!) of the heating element in this
	 * field. A value of around 600 Kelvin (320 degrees Celsius)
	 * will work quite well with a thermal inertia of around 20.
	 */
	float		heat_tgt_temps[4];
	/*
	 * Ambient cabin temperature in Kelvin. This is used to
	 * control ambient airflow defrosting. IF you don't want
	 * to simulate cabin temperature defrosting, simply set this
	 * to some sensible fixed cabin temperature value (e.g. 295
	 * Kelvin = 22 degrees Celsius).
	 */
	float		cabin_temp;
	/*
	 * This allows simulating hot air blowing onto the windshield.
	 * This mechanism is currently rather clumsily defined and is
	 * subject to reworking of the interface, so it will not be
	 * documented.
	 */
	float		hot_air_src[4];
	float		hot_air_radius[2];
	float		hot_air_temp[2];

	/*
	 * WIPER LOGIC
	 *
	 * Wipers are defined as circular areas in water texture space
	 * with a center around which the wiper blade pivots and an
	 * outer an inner radius. You then notify the library of the
	 * position of each wiper blade using the librain_set_wiper_angle
	 * function. All angles are in RADIANS and increase clockwise.
	 * An angle of 0 radians is straight up along the water texture.
	 *
	 *              0
	 *           _..-.._
	 *         /    |    \
	 *        .     |     .
	 * -PI/2  |-----+-----| +PI/2
	 *
	 * Wipers MUST only be moved between -PI and +PI. Rollover between
	 * PI and -PI is NOT handled, so be sure to only move the wiper
	 * through the upright zero value.
	 *
	 * Please note that you must call librain_set_wiper_angle from
	 * a flight loop callback, not a draw callback.
	 *
	 * You don't need to declare a particular speed at which the wiper
	 * moves. Wiper movement between simulator frames is entirely up
	 * to you. But you must observe the following speed limit: the
	 * wiper must not move between the edges of travel in less than
	 * 0.5 seconds, otherwise visual artifacts can result. The library
	 * fades out water droplets behind the wiper's path of travel in
	 * 0.5 seconds, so if you move it faster, it could hit its own
	 * fadeout tail and it's not going to look nice.
	 *
	 * If you are unsure where on the texture region your wiper is
	 * located, you can turn on visible drawing of the wiper blades
	 * and inner/outer radii by calling librain_set_wipers_visible.
	 */
	/*
	 * Wiper pivot point. This is in texturing space.
	 */
	vect2_t		wiper_pivot[MAX_WIPERS];
	/*
	 * Wiper area outer radius in texturing space.
	 * If a wiper is unused, leave this set to 0.
	 */
	double		wiper_radius_outer[MAX_WIPERS];
	/*
	 * Wiper area outer radius in texturing space.
	 * If a wiper is unused, leave this set to 0.
	 */
	double		wiper_radius_inner[MAX_WIPERS];
} librain_glass_t;

/*
 * Initialization & teardown functions. See librain.c for more information.
 */
LIBRAIN_EXPORT bool_t librain_init(const char *the_shaderpath,
    const librain_glass_t *glass, size_t num);
LIBRAIN_EXPORT void librain_fini(void);

/*
 * Rendering pipeline functions. See librain.c for more information.
 */
LIBRAIN_EXPORT void librain_draw_prepare(bool_t force);
LIBRAIN_EXPORT void librain_draw_z_depth(obj8_t *obj,
    const char **z_depth_group_ids);
LIBRAIN_EXPORT void librain_draw_exec(void);
LIBRAIN_EXPORT void librain_draw_finish(void);

/*
 * Wiper control.
 */
LIBRAIN_EXPORT void librain_set_wiper_angle(const librain_glass_t *glass,
    unsigned wiper_nr, double angle_radians, bool_t is_moving);

/*
 * Helper functions for more advanced effects rendering.
 */
LIBRAIN_EXPORT void librain_get_pvm(mat4 pvm);
LIBRAIN_EXPORT GLuint librain_get_screenshot_tex(void);
LIBRAIN_EXPORT void librain_refresh_screenshot(void);
LIBRAIN_EXPORT bool_t librain_reload_gl_progs(void);

/*
 * Debugging support.
 */
LIBRAIN_EXPORT void librain_set_debug_draw(bool_t flag);
LIBRAIN_EXPORT void librain_set_wipers_visible(bool_t flag);

/*
 * librain-internal
 */
bool_t librain_glob_init(void);

#ifdef __cplusplus
}
#endif

#endif	/* _LIBRAIN_H_ */
