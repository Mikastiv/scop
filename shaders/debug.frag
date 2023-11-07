#version 410 core

layout(location = 0) in vec3 normal;
layout(location = 1) in vec3 world_pos;
layout(location = 2) in vec2 tex_coords;

layout(location = 0) out vec4 out_color;

uniform sampler2D tex;

void main() {
    out_color = texture(tex, tex_coords);
}
