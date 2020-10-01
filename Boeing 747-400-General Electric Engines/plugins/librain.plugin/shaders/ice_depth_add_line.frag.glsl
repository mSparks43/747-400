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
    if (tex_coord.x < 0.100000001490116119384765625)
    {
        return length(vec2((0.100000001490116119384765625 - tex_coord.x) * 10.0, tex_coord.y - 0.5));
    }
    if (tex_coord.x > 0.89999997615814208984375)
    {
        return length(vec2((tex_coord.x - 0.89999997615814208984375) * 10.0, tex_coord.y - 0.5));
    }
    return abs(tex_coord.y - 0.5);
}

vec4 add_ice(float prev_depth)
{
    vec2 param = gl_FragCoord.xy;
    float param_1 = seed;
    float rand_val = gold_noise(param, param_1);
    float dist = clamp(1.0 - origin_distance(), 0.0, 1.0);
    float extra_ice = 0.0;
    if (rand_val < (d_t * (((((dist * dist) * dist) * dist) * dist) * dist)))
    {
        extra_ice = max(100.0 * d_ice, 0.0074999998323619365692138671875);
    }
    return vec4(min(prev_depth + extra_ice, 20.0), 0.0, 0.0, 1.0);
}

void main()
{
    float prev_depth = texture2D(prev, tex_coord).x;
    float param = prev_depth;
    gl_FragData[0] = add_ice(param);
}

