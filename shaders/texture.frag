#version 410 core

in VS_OUT {
    vec2 tex_coords;
} fs_in;

layout(location = 0) out vec4 out_color;

uniform sampler2D color_texture;

void main() {
    out_color = texture(color_texture, fs_in.tex_coords);
}
