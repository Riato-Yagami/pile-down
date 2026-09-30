shader_type canvas_item;
render_mode unshaded;

uniform vec4 highlight_color : source_color = vec4(1.000000000, 0.899999976, 0.319999993, 1.000000000);
uniform vec4 rim_color : source_color = vec4(1.000000000, 0.899999976, 0.319999993, 1.000000000);
varying vec4 vertex_modulate;

void vertex() {
	vertex_modulate = COLOR;
}

float inside_sprite(vec2 pixel, vec2 texture_size) {
	return float(all(greaterThanEqual(pixel, vec2(0.0))) && all(lessThan(pixel, texture_size)));
}

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	// The control adds two logical pixels on each side without stretching the
	// silhouette. Sample texel centers so the outline stays on the sprite grid.
	vec2 pixel = floor(UV * (texture_size + 4.0)) - 2.0;
	float center = step(0.5, texture(TEXTURE, (pixel + 0.5) / texture_size).a)
		* inside_sprite(pixel, texture_size);
	float inner = 0.0;
	float outer = 0.0;
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			vec2 neighbor_pixel = pixel + vec2(float(x), float(y));
			float neighbor = step(0.5, texture(TEXTURE, (neighbor_pixel + 0.5) / texture_size).a)
				* inside_sprite(neighbor_pixel, texture_size);
			outer = max(outer, neighbor);
			if (abs(x) <= 1 && abs(y) <= 1) {
				inner = max(inner, neighbor);
			}
		}
	}
	// Two solid one-pixel rings: a luminous edge and an amber outer rim.
	// Leave the tile itself untouched, including its number and hidden face.
	vec4 highlight = mix(rim_color, highlight_color, inner);
	highlight.a *= outer * (1.0 - center);
	COLOR = highlight * vertex_modulate;
}
