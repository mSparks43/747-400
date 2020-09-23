#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform float seed;
uniform float d_t;
uniform sampler2D prev;
uniform float ice;
uniform float d_ice;

varying vec2 tex_coord;
varying vec3 tex_norm;

float gold_noise(vec2 coordinate, float seed_1)
{
    return fract(sin(dot(coordinate * (seed_1 + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

vec4 remove_ice(float prev_depth)
{
    vec2 coord = round(vec2((gl_FragCoord.x / 10.0) + (gl_FragCoord.y / (1.0 + (seed * 5.30000019073486328125))), (gl_FragCoord.y / 10.0) - (gl_FragCoord.x / (1.0 + (seed * 4.69999980926513671875)))));
    vec2 param = coord;
    float param_1 = seed;
    float rand_val = gold_noise(param, param_1);
    if (rand_val < (3.0 * d_t))
    {
        return vec4(0.0, 0.0, 0.0, 1.0);
    }
    return vec4(prev_depth, 0.0, 0.0, 1.0);
}

void main()
{
    float prev_depth = texture2D(prev, tex_coord).x;
    float param = prev_depth;
    gl_FragData[0] = remove_ice(param);
}

