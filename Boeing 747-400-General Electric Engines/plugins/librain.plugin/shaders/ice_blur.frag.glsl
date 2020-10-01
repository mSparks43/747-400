#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform float blur_radius;
uniform float rand_seed;
uniform sampler2D tex;

varying vec2 tex_coord;
varying vec3 tex_norm;

float gold_noise(vec2 coordinate, float seed)
{
    return fract(sin(dot(coordinate * (seed + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

vec2 vec_rot(vec2 v, float a)
{
    float sin_a = sin(-a);
    float cos_a = cos(-a);
    return vec2((v.x * cos_a) - (v.y * sin_a), (v.x * sin_a) + (v.y * cos_a));
}

void main()
{
    vec2 c2p = tex_coord - vec2(0.5);
    float l = max(length(c2p), 0.0500000007450580596923828125);
    float radius = 4.0;
    vec2 param = gl_FragCoord.xy;
    float param_1 = rand_seed;
    float rand_val = ((2.0 * blur_radius) * gold_noise(param, param_1)) / l;
    vec2 param_2 = c2p;
    float param_3 = radians((-radius) - rand_val);
    vec2 v[5];
    v[0] = vec2(0.5) + vec_rot(param_2, param_3);
    vec2 param_4 = c2p;
    float param_5 = radians(((-radius) - rand_val) / 2.0);
    v[1] = vec2(0.5) + vec_rot(param_4, param_5);
    vec2 param_6 = c2p;
    float param_7 = radians(rand_val);
    v[2] = vec2(0.5) + vec_rot(param_6, param_7);
    vec2 param_8 = c2p;
    float param_9 = radians((radius + rand_val) / 2.0);
    v[3] = vec2(0.5) + vec_rot(param_8, param_9);
    vec2 param_10 = c2p;
    float param_11 = radians(radius + rand_val);
    v[4] = vec2(0.5) + vec_rot(param_10, param_11);
    gl_FragData[0] += (((((texture2D(tex, v[0]) * 0.100000001490116119384765625) + (texture2D(tex, v[1]) * 0.20000000298023223876953125)) + (texture2D(tex, v[2]) * 0.4000000059604644775390625)) + (texture2D(tex, v[3]) * 0.20000000298023223876953125)) + (texture2D(tex, v[4]) * 0.100000001490116119384765625));
}

