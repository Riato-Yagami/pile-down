shader_type canvas_item;
void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float bevel = mix(0.72, 0.34, UV.y);
	float shine = smoothstep(0.0, 0.12, 1.0 - abs(UV.x - 0.38));
	vec3 silver = mix(
		vec3(0.24, 0.28, 0.33),
		vec3(0.66, 0.71, 0.76),
		clamp(bevel + shine * 0.16, 0.0, 1.0)
	);
	COLOR = vec4(silver, source.a);
}
