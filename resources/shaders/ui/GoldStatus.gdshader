shader_type canvas_item;
uniform vec4 gold_color : source_color = vec4(0.851, 0.647, 0.078, 1.0);
void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float vertical_shine = mix(1.12, 0.82, UV.y);
	COLOR = vec4(gold_color.rgb * vertical_shine, source.a * gold_color.a);
}
