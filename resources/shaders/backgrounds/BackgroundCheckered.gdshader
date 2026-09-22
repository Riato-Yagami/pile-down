shader_type canvas_item;
render_mode unshaded;

global uniform vec2 background_viewport_size;
global uniform vec2 background_reference_size;
global uniform vec4 background_color_a;
global uniform vec4 background_color_b;
global uniform float background_intensity;
uniform vec2 speed = vec2(0.02, 0.0);
uniform float time = 0.0;
global uniform float background_pixelated;
global uniform float background_pixel_size;
uniform float transition_t = 1.0;
uniform float rotation = 0.0;
uniform float checker_width = 24.0;
uniform float checker_length = 29.0;
uniform int checker_shape : hint_enum("Rectangle", "Triangle", "Diamond") = 0;

vec2 rotate_uv(vec2 uv, float angle) {
	float c = cos(angle);
	float s = sin(angle);
	vec2 centered = uv - vec2(0.5);
	return vec2(centered.x * c - centered.y * s, centered.x * s + centered.y * c) + vec2(0.5);
}

float transition_hash(vec2 cell) {
	vec2 value = fract(cell * vec2(0.1031, 0.1030));
	value += dot(value, value.yx + 33.33);
	return fract((value.x + value.y) * value.x);
}

float transition_reveal(vec2 pixel) {
	float progress = clamp(transition_t, 0.0, 1.0);
	if (progress <= 0.001) {
		return 0.0;
	}
	if (progress >= 0.999) {
		return 1.0;
	}
	vec2 viewport = max(background_viewport_size, vec2(1.0));
	float diagonal_order = clamp((pixel.x + pixel.y) / (viewport.x + viewport.y), 0.0, 1.0);
	float block_size = max(background_pixel_size * 3.0, 6.0);
	float block_order = transition_hash(floor(pixel / block_size));
	float reveal_order = diagonal_order * 0.72 + block_order * 0.28;
	return smoothstep(reveal_order - 0.14, reveal_order + 0.14, progress);
}

float rectangle_checker(vec2 checker_pixel, vec2 checker_size) {
	vec2 cell = floor(checker_pixel / checker_size);
	return mod(cell.x + cell.y, 2.0);
}

float triangle_checker(vec2 checker_pixel, vec2 checker_size) {
	vec2 scaled = checker_pixel / checker_size;
	vec2 cell = floor(scaled);
	vec2 local = fract(scaled);
	float diagonal_flip = mod(cell.x + cell.y, 2.0);
	float triangle_side = mix(
		step(local.x, local.y),
		step(1.0 - local.x, local.y),
		diagonal_flip
	);
	return mod(cell.x + cell.y + triangle_side, 2.0);
}

float diamond_checker(vec2 checker_pixel, vec2 checker_size) {
	vec2 diamond = vec2(
		checker_pixel.x / checker_size.x + checker_pixel.y / checker_size.y,
		checker_pixel.x / checker_size.x - checker_pixel.y / checker_size.y
	);
	vec2 cell = floor(diamond);
	return mod(cell.x + cell.y, 2.0);
}

float checker_mask(vec2 checker_pixel, vec2 checker_size) {
	if (checker_shape == 1) {
		return triangle_checker(checker_pixel, checker_size);
	}
	if (checker_shape == 2) {
		return diamond_checker(checker_pixel, checker_size);
	}
	return rectangle_checker(checker_pixel, checker_size);
}

void fragment() {
	float effective_time = TIME + time;
	vec2 pixel = UV * background_viewport_size;
	if (background_pixelated > 0.5) {
		float block_size = max(background_pixel_size, 1.0);
		pixel = (floor(pixel / block_size) + vec2(0.5)) * block_size;
	}
	vec2 uv = rotate_uv(pixel / max(background_reference_size, vec2(1.0)), radians(rotation));
	vec2 checker_pixel = (uv + speed * effective_time) * background_reference_size;
	vec2 checker_size = max(vec2(checker_width, checker_length), vec2(1.0));
	float pattern = checker_mask(checker_pixel, checker_size) * 0.62;
	float amount = pattern * background_color_b.a * background_intensity * 1.45;
	vec3 background = mix(background_color_a.rgb, background_color_b.rgb, amount);
	COLOR = vec4(background, background_color_a.a * transition_reveal(pixel));
}
