#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform float seed;
uniform float d_t;
uniform float d_ice;
uniform sampler2D prev;
uniform float ice;

varying vec2 tex_coord;
varying vec3 tex_norm;

float gold_noise(vec2 coordinate, float seed_1)
{
    return fract(sin(dot(coordinate * (seed_1 + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

float origin_distance()
{
    return 2.0 * length(vec2(tex_coord.x - 0.5, tex_coord.y - 0.5));
}

vec4 remove_ice(float prev_depth)
{
    vec2 param = gl_FragCoord.xy;
    float param_1 = seed;
    float rand_val = gold_noise(param, param_1);
    float dist = clamp(1.0 - origin_distance(), 0.0, 1.0);
    float extra_ice = 0.0;
    if (rand_val < (d_t * (((((dist * dist) * dist) * dist) * dist) * dist)))
    {
        extra_ice = min(100.0 * d_ice, -0.001000000047497451305389404296875);
    }
    return vec4(max(prev_depth + extra_ice, 0.0), 0.0, 0.0, 1.0);
}

void main()
{
    float prev_depth = texture2D(prev, tex_coord).x;
    float param = prev_depth;
    gl_FragData[0] = remove_ice(param);
}

