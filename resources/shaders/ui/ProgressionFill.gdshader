shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.301960796, 0.509803951, 0.760784328, 1.000000000);
uniform vec4 empty_color : source_color = vec4(0.725000024, 0.764999986, 0.811999977, 1.000000000);
uniform vec4 highlight_color : source_color = vec4(0.427450985, 0.654901981, 0.898039222, 1.000000000);
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
