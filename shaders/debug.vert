#version 410 core

layout(location = 0) in vec3 in_pos;
layout(location = 1) in vec3 in_normal;
layout(location = 2) in vec2 in_uv;

layout(location = 0) out vec3 normal;
layout(location = 1) out vec3 world_pos;
layout(location = 2) out vec2 tex_coords;

uniform mat4 model;

void main() {
    mat3 normal_matrix = transpose(inverse(mat3(model)));
    normal = normal_matrix * in_normal;
    world_pos = vec3(model * vec4(in_pos, 1.0));
    tex_coords = in_uv;
    gl_Position = vec4(world_pos, 1.0);
}
