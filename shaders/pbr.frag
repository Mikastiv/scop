#version 410 core

layout(location = 0) out vec4 color;

uniform float pixel_color1;
uniform float pixel_color2;
uniform float pixel_color3;

void main() {
    color = vec4(pixel_color1, pixel_color2, pixel_color3, 1.0);
}
