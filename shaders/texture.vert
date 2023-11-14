#version 410 core

layout(location = 0) in vec3 in_pos;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;

out VS_OUT {
    vec2 tex_coords;
} vs_out;

layout (std140) uniform matrices {
    mat4 view;
    mat4 projection;
};

uniform mat4 model;

void main() {
    vs_out.tex_coords = in_uv;
    gl_Position = projection * view * model * vec4(in_pos, 1.0);
}
