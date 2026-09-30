shader_type canvas_item;
render_mode unshaded;

uniform vec4 tile_color : source_color = vec4(0.400000006, 0.899999976, 0.699999988, 1.000000000);
uniform float phosphorescence = 0.0;
varying vec4 vertex_modulate;

void vertex() {
	vertex_modulate = COLOR;
}

float color_mask(vec4 sample_color) {
	return float(sample_color.g > 0.65 && sample_color.g > sample_color.r * 1.6
		&& sample_color.g > sample_color.b * 1.6) * sample_color.a;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float mask = color_mask(source);
	// Stay inside the original colored pixels: no blur or surrounding light.
	float energy = clamp(phosphorescence, 0.0, 1.0);
	vec3 tint = mix(tile_color.rgb, vec3(1.0), 0.15 + 0.3 * energy * energy);
	COLOR = vec4(tint, mask * tile_color.a * energy) * vertex_modulate;
}
