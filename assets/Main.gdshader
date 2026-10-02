shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.6;
uniform float vignette_softness : hint_range(0.1, 2.0) = 0.8;

void fragment() {
	vec2 center = UV - vec2(0.5);

	float distance_from_center = length(center);

	float vignette = smoothstep(
		0.25,
		0.25 + vignette_softness,
		distance_from_center
	);

	float alpha = vignette * vignette_strength;

	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}