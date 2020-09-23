#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform float d_t;
uniform sampler2D src;
uniform sampler2D depth;
uniform float rand_seed;
uniform float inertia_in;
uniform float le_temp;
uniform float wind_fact;
uniform float cabin_temp;
uniform float hot_air_radius[2];
uniform vec2 hot_air_src[2];
uniform float hot_air_temp[2];
uniform vec4 heat_zones[4];
uniform float heat_tgt_temps[4];
uniform float precip_intens;

float gold_noise(vec2 coordinate, float seed)
{
    return fract(sin(dot(coordinate * (seed + 0.1618033945560455322265625), vec2(0.1618033945560455322265625, 0.31415927410125732421875))) * 14142.1357421875);
}

float filter_in(float old_val, float new_val, float rate)
{
    float delta = new_val - old_val;
    float abs_delta = abs(delta);
    float inc_val = (delta * d_t) / rate;
    return old_val + clamp(inc_val, -abs_delta, abs_delta);
}

void main()
{
    vec2 my_size = vec2(textureSize2D(src, 0));
    float glass_temp = texture2D(src, gl_FragCoord.xy / my_size).x * 400.0;
    float depth_1 = texture2D(depth, gl_FragCoord.xy / vec2(textureSize2D(depth, 0))).x;
    vec2 param = gl_FragCoord.xy;
    float param_1 = rand_seed;
    float rand_temp = 4.0 * (gold_noise(param, param_1) - 0.5);
    float inertia = inertia_in * (1.0 + (depth_1 / 3.0));
    if ((glass_temp < 200.0) || (glass_temp > 400.0))
    {
        glass_temp = le_temp;
    }
    float param_2 = glass_temp;
    float param_3 = le_temp;
    float param_4 = mix(inertia / 4.0, inertia / 40.0, min(wind_fact, 1.0));
    glass_temp = filter_in(param_2, param_3, param_4);
    float param_5 = glass_temp;
    float param_6 = cabin_temp;
    float param_7 = inertia * 2.0;
    glass_temp = filter_in(param_5, param_6, param_7);
    for (int i = 0; i < 2; i++)
    {
        if (hot_air_radius[i] <= 0.0)
        {
            continue;
        }
        float hot_air_dist = length(gl_FragCoord.xy - (hot_air_src[i] * my_size));
        float radius = hot_air_radius[i] * my_size.x;
        float param_8 = glass_temp;
        float param_9 = hot_air_temp[i];
        float param_10 = 1.5 * max(inertia * (hot_air_dist / radius), 1.0);
        glass_temp = filter_in(param_8, param_9, param_10);
    }
    float param_11 = glass_temp;
    float param_12 = glass_temp + rand_temp;
    float param_13 = 0.5;
    glass_temp = filter_in(param_11, param_12, param_13);
    for (int i_1 = 0; i_1 < 4; i_1++)
    {
        float inertia_out = 100000.0;
        bool _244 = heat_zones[i_1].z == 0.0;
        bool _253;
        if (!_244)
        {
            _253 = heat_zones[i_1].w == 0.0;
        }
        else
        {
            _253 = _244;
        }
        bool _264;
        if (!_253)
        {
            _264 = heat_tgt_temps[i_1] == 0.0;
        }
        else
        {
            _264 = _253;
        }
        if (_264)
        {
            continue;
        }
        float left = heat_zones[i_1].x * my_size.x;
        float right = heat_zones[i_1].y * my_size.x;
        float bottom = heat_zones[i_1].z * my_size.y;
        float top = heat_zones[i_1].w * my_size.y;
        float _297 = left;
        bool _301 = _297 <= gl_FragCoord.x;
        bool _308;
        if (_301)
        {
            _308 = right >= gl_FragCoord.x;
        }
        else
        {
            _308 = _301;
        }
        bool _315;
        if (_308)
        {
            _315 = bottom <= gl_FragCoord.y;
        }
        else
        {
            _315 = _308;
        }
        bool _322;
        if (_315)
        {
            _322 = top >= gl_FragCoord.y;
        }
        else
        {
            _322 = _315;
        }
        if (_322)
        {
            inertia_out = inertia_in;
        }
        else
        {
            float _329 = left;
            bool _330 = gl_FragCoord.x < _329;
            bool _337;
            if (_330)
            {
                _337 = gl_FragCoord.y >= bottom;
            }
            else
            {
                _337 = _330;
            }
            bool _344;
            if (_337)
            {
                _344 = gl_FragCoord.y <= top;
            }
            else
            {
                _344 = _337;
            }
            if (_344)
            {
                inertia_out = max((inertia_in * left) - gl_FragCoord.x, inertia_in);
            }
            else
            {
                float _358 = right;
                bool _359 = gl_FragCoord.x > _358;
                bool _366;
                if (_359)
                {
                    _366 = gl_FragCoord.y >= bottom;
                }
                else
                {
                    _366 = _359;
                }
                bool _373;
                if (_366)
                {
                    _373 = gl_FragCoord.y <= top;
                }
                else
                {
                    _373 = _366;
                }
                if (_373)
                {
                    inertia_out = max((inertia_in * gl_FragCoord.x) - right, inertia_in);
                }
            }
        }
        float param_14 = glass_temp;
        float param_15 = heat_tgt_temps[i_1];
        float param_16 = inertia_out;
        glass_temp = filter_in(param_14, param_15, param_16);
    }
    gl_FragData[0] = vec4(glass_temp / 400.0, 0.0, 0.0, 1.0);
}

