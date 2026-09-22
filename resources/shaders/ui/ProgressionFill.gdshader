shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.302, 0.51, 0.761, 1.0);
uniform vec4 empty_color : source_color = vec4(0.725, 0.765, 0.812, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.427, 0.655, 0.898, 1.0);
uniform float highlighted : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec4 highlighted_fill = mix(fill_color, highlight_color, highlighted);
	vec4 level_color = UV.x <= progress ? highlighted_fill : empty_color;
	bool green_mask = source.g > 0.9 && source.r < 0.1 && source.b < 0.1;
	COLOR = green_mask
		? vec4(level_color.rgb, source.a * level_color.a)
		: source;
}
