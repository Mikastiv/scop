#version 410 core

layout(location = 0) in vec3 normal;
layout(location = 1) in vec3 world_pos;
layout(location = 2) in vec2 tex_coords;

layout(location = 0) out vec4 out_color;

uniform sampler2D tex;

void main() {
    vec3 color  = texture(tex, tex_coords).rgb;
    color = pow(color, vec3(1.0 / 2.2));
    out_color = vec4(color, 1.0);
}
