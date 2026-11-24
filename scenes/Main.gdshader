
shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.65;
uniform float vignette_radius : hint_range(0.1, 1.0) = 0.55;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.45;

uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = SCREEN_UV;

    // Koreksi rasio layar agar vignette tetap berbentuk proporsional
    vec2 centered_uv = (uv - vec2(0.5)) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);

    float distance_from_center = length(centered_uv);

    // Membuat gradasi gelap dari tengah menuju tepi layar
    float vignette = smoothstep(
        vignette_radius,
        vignette_radius + vignette_softness,
        distance_from_center
    );

    float alpha = vignette * vignette_strength;

    COLOR = vec4(vignette_color.rgb, alpha);
}
