#version 410 core

layout(location = 0) in vec3 in_pos;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;

out VS_OUT {
    vec3 normal;
    vec3 world_pos;
    vec2 tex_coords;
} vs_out;

layout (std140) uniform matrices {
    mat4 view;
    mat4 projection;
};

uniform mat4 model;

void main() {
    mat3 normal_matrix = transpose(inverse(mat3(model)));
    vs_out.normal = normal_matrix * in_normal;
    vs_out.world_pos = vec3(model * vec4(in_pos, 1.0));
    vs_out.tex_coords = in_uv;
    gl_Position = projection * view * vec4(vs_out.world_pos, 1.0);
}
