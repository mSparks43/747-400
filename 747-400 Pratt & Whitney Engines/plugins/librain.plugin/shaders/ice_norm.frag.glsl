#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform sampler2D depth;

varying vec3 tex_norm;
varying vec2 tex_coord;

void main()
{
    vec2 sz = vec2(textureSize2D(depth, 0));
    float x1 = texture2D(depth, vec2(max((gl_FragCoord.x - 1.0) / sz.x, 0.0), gl_FragCoord.y / sz.y)).x;
    float x2 = texture2D(depth, vec2(min((gl_FragCoord.x + 1.0) / sz.x, 1.0), gl_FragCoord.y / sz.y)).x;
    float y1 = texture2D(depth, vec2(gl_FragCoord.x / sz.x, max((gl_FragCoord.y - 1.0) / sz.y, 0.0))).x;
    float y2 = texture2D(depth, vec2(gl_FragCoord.x / sz.x, min((gl_FragCoord.y + 1.0) / sz.y, 1.0))).x;
    gl_FragData[0] = vec4(((x2 - x1) / 2.0) + 0.5, ((y2 - y1) / 2.0) + 0.5, 0.0, 1.0);
}

