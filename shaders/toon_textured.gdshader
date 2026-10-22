shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

// Cel/toon shader for textured (artist-made) meshes: samples an albedo texture
// then applies the same stylized lighting as toon.gdshader (banded diffuse,
// cool shadow tint, fresnel rim, soft specular). Used to give real KayKit
// models the cohesive "cartoon clay" look of the procedurally-built world.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float toon_steps : hint_range(1.0, 6.0) = 3.0;
uniform float band_softness : hint_range(0.0, 1.0) = 0.35;
uniform vec4 shadow_tint : source_color = vec4(0.30, 0.38, 0.55, 1.0);
uniform float shadow_mix : hint_range(0.0, 1.0) = 0.45;
uniform vec4 rim_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.45;
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float specular_strength : hint_range(0.0, 1.0) = 0.12;

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = tex.rgb;
	ROUGHNESS = 0.65;
	METALLIC = 0.0;
}

void light() {
	vec3 albedo_color = ALBEDO;
	float ndl = dot(NORMAL, LIGHT);
	float atten = ATTENUATION;
	vec3 light_col = LIGHT_COLOR;

	float n = clamp(ndl, 0.0, 1.0);
	float banded = floor(n * toon_steps) / max(toon_steps - 1.0, 1.0);
	float shade = mix(n, banded, 1.0 - band_softness);
	shade = clamp(shade, 0.0, 1.0);

	vec3 lit_color = albedo_color;
	vec3 shaded_color = mix(albedo_color, shadow_tint.rgb, shadow_mix);
	vec3 diffuse = mix(shaded_color, lit_color, shade) * light_col;
	DIFFUSE_LIGHT += diffuse * atten;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	DIFFUSE_LIGHT += rim_color.rgb * rim * rim_strength * atten;

	vec3 h = normalize(VIEW + LIGHT);
	float spec = pow(clamp(dot(NORMAL, h), 0.0, 1.0), 24.0);
	SPECULAR_LIGHT += light_col * spec * specular_strength * atten;
}
