#version 410 core

layout(location = 0) out vec4 out_color;

#define COLOR_COUNT 4

const vec3 triangles_colors[COLOR_COUNT] = vec3[](
    vec3(0.2),
    vec3(0.3),
    vec3(0.4),
    vec3(0.5)
);

void main() {
    vec3 color  = triangles_colors[gl_PrimitiveID % COLOR_COUNT];
    out_color = vec4(color, 1.0);
}
