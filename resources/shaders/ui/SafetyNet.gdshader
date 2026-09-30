shader_type canvas_item;
uniform vec4 dark_color : source_color = vec4(0.239999995, 0.280000001, 0.330000013, 1.000000000);
uniform vec4 light_color : source_color = vec4(0.660000026, 0.709999979, 0.759999990, 1.000000000);
void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float bevel = mix(0.72, 0.34, UV.y);
	float shine = smoothstep(0.0, 0.12, 1.0 - abs(UV.x - 0.38));
	vec3 silver = mix(
		dark_color.rgb,
		light_color.rgb,
		clamp(bevel + shine * 0.16, 0.0, 1.0)
	);
	COLOR = vec4(silver, source.a);
}
