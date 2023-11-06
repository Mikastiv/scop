#version 410 core

layout(location = 0) in vec3 in_pos;
layout(location = 1) in vec3 in_normal;

layout(location = 0) out vec3 normal;
layout(location = 1) out vec3 world_pos;

layout (std140) uniform matrices {
    mat4 view;
    mat4 projection;
};

uniform mat4 model;

void main() {
    mat3 normal_matrix = transpose(inverse(mat3(model)));
    normal = normal_matrix * in_normal;
    world_pos = vec3(model * vec4(in_pos, 1.0));
    gl_Position = projection * view * vec4(world_pos, 1.0);
}
