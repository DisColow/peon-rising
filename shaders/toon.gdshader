shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_back;

// Toon / cel shader: quantized diffuse lighting + fresnel rim.
// Keeps the cartoon look consistent across every mesh in the game.

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.65;
uniform float toon_steps : hint_range(1.0, 8.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	// Fresnel rim light for a soft cartoon outline/glow.
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
	EMISSION = rim_color.rgb * fresnel * rim_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float steps = max(toon_steps, 1.0);
	// Band the light into discrete steps.
	float banded = floor(clamp(ndl * 0.5 + 0.5, 0.0, 1.0) * steps) / steps;
	DIFFUSE_LIGHT += banded * ATTENUATION * LIGHT_COLOR * albedo.rgb;
}
