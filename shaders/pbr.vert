#version 410 core

layout(location = 0) in vec3 pos;

layout (std140) uniform matrices {
    mat4 view;
    mat4 projection;
};

uniform mat4 model;

void main() {
    gl_Position = projection * view * model * vec4(pos, 1.0);
}
