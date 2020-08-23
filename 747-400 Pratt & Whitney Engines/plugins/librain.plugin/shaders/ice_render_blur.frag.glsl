#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform sampler2D bg;
uniform sampler2D norm;
uniform sampler2D depth;
uniform float rand_seed;
uniform float blur_radius;

varying vec2 tex_coord;
varying vec3 tex_norm;

vec2 vec_norm(vec2 v)
{
    return vec2(v.y, -v.x);
}

float gold_noise(vec2 coordinate, float seed)
{
    return fract(sin(dot(coordinate * (seed + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

void main()
{
    vec2 bg_sz = vec2(textureSize2D(bg, 0));
    vec4 bg_pixel = texture2D(bg, gl_FragCoord.xy / bg_sz);
    float white = (bg_pixel.x + bg_pixel.y) + bg_pixel.z;
    vec2 norm_pixel = texture2D(norm, tex_coord).xy - vec2(0.5);
    vec2 c2p = tex_coord - vec2(0.5);
    vec2 param = c2p;
    vec2 param_1 = round(tex_coord * vec2(textureSize2D(depth, 0)));
    float param_2 = rand_seed;
    vec2 blur_v = (vec_norm(param) * 10.0) * gold_noise(param_1, param_2);
    float depth_val = clamp(((texture2D(depth, tex_coord + (blur_v * (-1.0))).x * 0.25) + (texture2D(depth, tex_coord).x * 0.5)) + (texture2D(depth, tex_coord + blur_v).x * 0.25), 0.0, 1.5);
    gl_FragData[0] = vec4(1.0, 1.0, 1.0, (depth_val - (length(norm_pixel) / 2.0)) * sqrt(white));
}

