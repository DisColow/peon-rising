shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

// Stylized cel/toon shader: banded diffuse with a cool shadow tint, fresnel rim
// and a soft specular. Gives every mesh a cohesive "cartoon clay" look.

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.6;
uniform float toon_steps : hint_range(1.0, 6.0) = 3.0;
uniform float band_softness : hint_range(0.0, 1.0) = 0.35;
uniform vec4 shadow_tint : source_color = vec4(0.30, 0.38, 0.55, 1.0);
uniform float shadow_mix : hint_range(0.0, 1.0) = 0.5;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.45;
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.16;

void fragment() {
ALBEDO = albedo.rgb;
ROUGHNESS = roughness;
METALLIC = 0.0;
}

void light() {
float ndl = dot(NORMAL, LIGHT);
float atten = ATTENUATION;
vec3 light_col = LIGHT_COLOR;

// Quantize the diffuse into toon bands, then soften the band edges.
float n = clamp(ndl, 0.0, 1.0);
float banded = floor(n * toon_steps) / max(toon_steps - 1.0, 1.0);
float shade = mix(n, banded, 1.0 - band_softness);
shade = clamp(shade, 0.0, 1.0);

// Cool, dark tint in the shadow side for depth.
vec3 lit_color = albedo.rgb;
vec3 shaded_color = mix(albedo.rgb, shadow_tint.rgb, shadow_mix);
vec3 diffuse = mix(shaded_color, lit_color, shade) * light_col;
DIFFUSE_LIGHT += diffuse * atten;

// Fresnel rim light for a soft cartoon edge glow.
float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
DIFFUSE_LIGHT += rim_color.rgb * rim * rim_strength * atten;

// Blinn-Phong specular highlight.
vec3 h = normalize(VIEW + LIGHT);
float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 24.0);
SPECULAR_LIGHT += light_col * spec * specular_strength * atten;
}
