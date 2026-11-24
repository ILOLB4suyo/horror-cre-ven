shader_type canvas_item;

uniform sampler2D screen_texture :
    hint_screen_texture,
    filter_linear_mipmap;

uniform float blur_amount = 1.0;

void fragment() {
    vec4 screen_color = textureLod(
        screen_texture,
        SCREEN_UV,
        blur_amount
    );

    COLOR = screen_color;
}
