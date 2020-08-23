#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform sampler2D tex;
uniform sampler2D temp_tex;
uniform vec2 my_tex_sz;
uniform vec2 tp;
uniform float window_ice;
uniform float thrust;
uniform float precip_intens;

float read_depth(vec2 pos)
{
    return texture2D(tex, pos / vec2(textureSize2D(tex, 0))).x;
}

float gold_noise(vec2 coordinate, float seed)
{
    return fract(sin(dot(coordinate * (seed + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

void main()
{
    float temp = texture2D(temp_tex, gl_FragCoord.xy / my_tex_sz).x * 400.0;
    vec2 thrust_v = gl_FragCoord.xy - tp;
    vec2 ice_displace = vec2(0.0);
    float window_ice_fact = sqrt(min(window_ice, 1.0));
    if (temp < 275.0)
    {
        float fact = min((temp - 275.0) / (-4.0), 1.0);
        vec2 param = gl_FragCoord.xy;
        float depth = pow(read_depth(param) / 3.0, 0.300000011920928955078125);
        fact *= depth;
        vec2 param_1 = gl_FragCoord.xy;
        float param_2 = 0.0;
        vec2 param_3 = gl_FragCoord.xy;
        float param_4 = 1.0;
        ice_displace = vec2((gold_noise(param_1, param_2) - 0.5) * fact, (gold_noise(param_3, param_4) - 0.5) * fact);
    }
    thrust_v /= vec2(length(thrust_v));
    thrust_v *= ((20.0 * thrust) + 1.0);
    vec2 param_5 = gl_FragCoord.xy + (vec2(-1.0, 0.0) * thrust_v);
    float depth_left = read_depth(param_5);
    vec2 param_6 = gl_FragCoord.xy + (vec2(1.0, 0.0) * thrust_v);
    float depth_right = read_depth(param_6);
    vec2 param_7 = gl_FragCoord.xy + (vec2(0.0, 1.0) * thrust_v);
    float depth_up = read_depth(param_7);
    vec2 param_8 = gl_FragCoord.xy + (vec2(0.0, -1.0) * thrust_v);
    float depth_down = read_depth(param_8);
    float d_lr = ((atan(depth_left - depth_right) / 1.5707499980926513671875) * (1.0 + ice_displace.x)) + 0.5;
    d_lr = clamp(d_lr + (window_ice_fact * ice_displace.x), 0.0, 1.0);
    float d_ud = ((atan(depth_up - depth_down) / 1.5707499980926513671875) * (1.0 + ice_displace.y)) + 0.5;
    d_ud = clamp(d_ud + (window_ice_fact * ice_displace.y), 0.0, 1.0);
    gl_FragData[0] = vec4(d_lr, d_ud, 0.0, 1.0);
}

