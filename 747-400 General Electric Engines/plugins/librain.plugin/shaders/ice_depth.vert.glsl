#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require
#extension GL_ARB_shader_texture_lod : require

uniform sampler2D depth;
uniform float growth_mult;
uniform mat4 pvm;

attribute vec2 vtx_tex0;
attribute vec3 vtx_norm;
varying vec3 tex_norm;
varying vec2 tex_coord;
attribute vec3 vtx_pos;

float gold_noise(vec2 coordinate, float seed)
{
    return fract(sin(dot(coordinate * (seed + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

void main()
{
    float depth_val = texture2DLod(depth, vtx_tex0, 0.0).x;
    float depth_rat = depth_val / 1.5;
    vec2 param = vtx_tex0 * vec2(textureSize2D(depth, 0));
    float param_1 = 1.0;
    float rand_val = gold_noise(param, param_1);
    vec3 rand_pos = vtx_norm * max((9.9999997473787516355514526367188e-05 * growth_mult) * ((depth_rat * depth_rat) * depth_rat), 0.001000000047497451305389404296875);
    tex_norm = vtx_norm;
    tex_coord = vtx_tex0;
    gl_Position = pvm * vec4(vtx_pos + rand_pos, 1.0);
}

