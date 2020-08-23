#version 120
#ifdef GL_ARB_shading_language_420pack
#extension GL_ARB_shading_language_420pack : require
#endif
#extension GL_EXT_gpu_shader4 : require

uniform mat4 pvm;

varying vec3 tex_norm;
attribute vec3 vtx_norm;
varying vec2 tex_coord;
attribute vec2 vtx_tex0;
attribute vec3 vtx_pos;

void main()
{
    tex_norm = vtx_norm;
    tex_coord = vtx_tex0;
    gl_Position = pvm * vec4(vtx_pos, 1.0);
}

