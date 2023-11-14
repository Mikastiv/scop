#version 410 core

in VS_OUT {
    vec3 normal;
    vec3 world_pos;
    vec2 tex_coords;
} fs_in;

layout(location = 0) out vec4 out_color;

uniform sampler2D albedo_map;
uniform sampler2D metallic_map;
uniform sampler2D roughness_map;
uniform sampler2D normal_map;
uniform sampler2D ao_map;
uniform int has_normal_map;

#define LIGHT_COUNT 2

uniform vec3 light_positions[LIGHT_COUNT];
uniform vec3 light_colors[LIGHT_COUNT];

uniform vec3 camera_position;

const float PI = 3.14159265359;

vec3 get_normal_from_map() {
    vec3 tangent_normal = texture(normal_map, fs_in.tex_coords).xyz * 2.0 - 1.0;

    vec3 Q1 = dFdx(fs_in.world_pos);
    vec3 Q2 = dFdy(fs_in.world_pos);
    vec2 st1 = dFdx(fs_in.tex_coords);
    vec2 st2 = dFdy(fs_in.tex_coords);

    vec3 N = normalize(fs_in.normal);
    vec3 T = normalize(Q1 * st2.t - Q2 * st1.t);
    vec3 B = -normalize(cross(N, T));
    mat3 TBN = mat3(T, B, N);

    return normalize(TBN * tangent_normal);
}

float distribution_ggx(vec3 n, vec3 h, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float n_dot_h = max(dot(n, h), 0.0);
    float n_dot_h2 = n_dot_h * n_dot_h;

    float numerator = a2;
    float denominator = n_dot_h * (a2 - 1.0) + 1.0;
    denominator = PI * denominator * denominator;

    return numerator / denominator;
}

float geometry_schlick_ggx(float n_dot_v, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;

    float numerator = n_dot_v;
    float denominator = n_dot_v * (1.0 - k) + k;

    return numerator / denominator;
}

float geometry_smith(vec3 n, vec3 v, vec3 l, float roughness) {
    float n_dot_v = max(dot(n, v), 0.000001);
    float n_dot_l = max(dot(n, l), 0.000001);
    float ggx1 = geometry_schlick_ggx(n_dot_v, roughness);
    float ggx2 = geometry_schlick_ggx(n_dot_l, roughness);

    return ggx1 * ggx2;
}

vec3 fresnel_schlick(float cos_theta, vec3 f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

void main() {
    vec3 n;
    if (has_normal_map != 0) {
        n = get_normal_from_map();
    } else {
        n = normalize(fs_in.normal);
    }
    vec3 v = normalize(camera_position - fs_in.world_pos);

    vec3 albedo = pow(texture(albedo_map, fs_in.tex_coords).rgb, vec3(2.2));
    float metallic = texture(metallic_map, fs_in.tex_coords).r;
    float roughness = texture(roughness_map, fs_in.tex_coords).r;
    float ao = texture(ao_map, fs_in.tex_coords).r;

    vec3 f0 = mix(vec3(0.04), albedo, metallic);

    vec3 lo = vec3(0.0);
    for (int i = 0; i < LIGHT_COUNT; ++i) {
        vec3 l = normalize(light_positions[i] - fs_in.world_pos);
        vec3 h = normalize(v + l);
        float dist = length(light_positions[i] - fs_in.world_pos);
        float attenuation = 1.0 / (dist * dist);
        vec3 radiance = light_colors[i] * attenuation;

        float ndf = distribution_ggx(n, h, roughness);
        float g = geometry_smith(n, v, l, roughness);
        vec3 f = fresnel_schlick(clamp(dot(h, v), 0.0, 1.0), f0);

        vec3 numerator = ndf * g * f;
        float denominator = 4.0 * max(dot(n, v), 0.0) * max(dot(n, l), 0.0) + 0.0001;
        vec3 specular = numerator / denominator;

        vec3 ks = f;
        vec3 kd = vec3(1.0) - ks;
        kd *= 1.0 - metallic;

        float n_dot_l = max(dot(n, l), 0.000001);

        lo += (kd * albedo / PI + specular) * radiance * n_dot_l;
    }

    vec3 ambient = vec3(0.03) * albedo * ao;
    vec3 color = ambient + lo;

    color = color / (color + vec3(1.0));
    color = pow(color, vec3(1.0 / 2.2));

    out_color = vec4(color, 1.0);
}
