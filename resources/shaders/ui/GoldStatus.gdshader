shader_type canvas_item;
uniform vec4 gold_color : source_color = vec4(0.850980401, 0.647058845, 0.078431375, 1.000000000);
void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float vertical_shine = mix(1.12, 0.82, UV.y);
	COLOR = vec4(gold_color.rgb * vertical_shine, source.a * gold_color.a);
}
