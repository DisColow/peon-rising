shader_type spatial;
render_mode cull_back, specular_schlick_ggx;

// Procedural cartoon grass: soft color variation + sparse dirt patches, driven
// by world-space noise so it tiles seamlessly across the whole map.

uniform vec4 grass : source_color = vec4(0.36, 0.58, 0.26, 1.0);
uniform vec4 grass_light : source_color = vec4(0.46, 0.68, 0.32, 1.0);
uniform vec4 grass_dark : source_color = vec4(0.26, 0.46, 0.19, 1.0);
uniform vec4 dirt : source_color = vec4(0.58, 0.50, 0.36, 1.0);
uniform float patch_scale : hint_range(0.01, 0.5) = 0.05;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.18;

varying vec3 world_pos;

float hash(vec2 p) {
return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
vec2 i = floor(p);
vec2 f = fract(p);
vec2 u = f * f * (3.0 - 2.0 * f);
return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
           mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
vec2 uv = world_pos.xz * patch_scale;
float n = vnoise(uv);
float n2 = vnoise(uv * 3.7 + vec2(13.0, 7.0));

// Blend the three grass tones, then sprinkle dirt patches.
vec3 col = mix(grass_dark.rgb, grass_light.rgb, n);
col = mix(col, grass.rgb, smoothstep(0.35, 0.65, n2));
float dirt_mask = smoothstep(1.0 - dirt_amount, 1.0, vnoise(uv * 0.4 + vec2(91.0, 37.0)));
col = mix(col, dirt.rgb, dirt_mask);

ALBEDO = col;
ROUGHNESS = 0.95;
METALLIC = 0.0;
}
