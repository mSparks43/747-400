#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform sampler2D bg;
uniform sampler2D norm;
uniform sampler2D depth;
uniform mat4 acf_orient;
uniform vec3 sun_dir;
uniform float sun_pitch;

varying vec2 tex_coord;
varying vec3 tex_norm;

void main()
{
    vec2 bg_sz = vec2(textureSize2D(bg, 0));
    vec4 bg_pixel = texture2D(bg, gl_FragCoord.xy / bg_sz);
    float white = (bg_pixel.x + bg_pixel.y) + bg_pixel.z;
    vec2 norm_pixel = texture2D(norm, tex_coord).xy - vec2(0.5);
    float depth_val = clamp(texture2D(depth, tex_coord).x, 0.0, 1.5);
    vec3 norm_dir = (acf_orient * vec4(tex_norm, 1.0)).xyz;
    float sun_angle = 1.0 - clamp(dot(norm_dir, sun_dir), 0.0, 1.0);
    float sun_darkening = sin(radians(clamp(sun_angle, 0.0, 90.0)));
    gl_FragData[0] = vec4(1.0, 1.0, 1.0, (((depth_val - (length(norm_pixel) / 2.0)) - (sun_angle / 2.0)) - (sun_darkening / 2.0)) * sqrt(white));
}

