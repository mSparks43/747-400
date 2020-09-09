#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform sampler2D screenshot_tex;
uniform vec4 vp;
uniform sampler2D ws_tex;
uniform sampler2D depth_tex;

varying vec2 tex_coord;
varying vec3 tex_norm;

vec4 _68;

vec4 get_pixel(inout vec2 pos)
{
    vec2 sz = vec2(textureSize2D(screenshot_tex, 0));
    pos /= sz;
    pos = clamp(pos, vec2(0.0), vec2(vp.zw / sz) - vec2(0.001000000047497451305389404296875));
    vec4 pixel = texture2D(ws_tex, pos);
    if (pixel.w == 1.0)
    {
        return pixel;
    }
    else
    {
        return texture2D(screenshot_tex, pos);
    }
}

void main()
{
    vec4 depth_val = texture2D(depth_tex, tex_coord);
    float depth = depth_val.x;
    float depth_rat = depth / 3.0;
    float depth_rat_fact = 1.0 * pow(depth_rat, 1.2000000476837158203125);
    vec4 out_pixel = vec4(0.0);
    for (float x = 0.0; x < 5.0; x += 1.0)
    {
        for (float y = 0.0; y < 5.0; y += 1.0)
        {
            vec2 param = gl_FragCoord.xy + (vec2(x - 2.0, y - 2.0) * depth_rat_fact);
            vec4 _123 = get_pixel(param);
            vec4 pixel = _123;
            if (pixel.w != 0.0)
            {
                float indexable[25] = float[](0.00999999977648258209228515625, 0.0199999995529651641845703125, 0.039999999105930328369140625, 0.0199999995529651641845703125, 0.00999999977648258209228515625, 0.0199999995529651641845703125, 0.039999999105930328369140625, 0.07999999821186065673828125, 0.039999999105930328369140625, 0.0199999995529651641845703125, 0.039999999105930328369140625, 0.07999999821186065673828125, 0.1599999964237213134765625, 0.07999999821186065673828125, 0.039999999105930328369140625, 0.0199999995529651641845703125, 0.039999999105930328369140625, 0.07999999821186065673828125, 0.039999999105930328369140625, 0.0199999995529651641845703125, 0.00999999977648258209228515625, 0.0199999995529651641845703125, 0.039999999105930328369140625, 0.0199999995529651641845703125, 0.00999999977648258209228515625);
                out_pixel += (pixel * indexable[int((y * 5.0) + x)]);
            }
            else
            {
                discard;
            }
        }
    }
    gl_FragData[0] = vec4(out_pixel.xyz, 1.0);
}

