#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

varying vec2 tex_coord;
varying vec3 tex_norm;

void main()
{
    gl_FragData[0] = vec4(tex_coord.x, tex_coord.y, 0.0, 1.0);
}

