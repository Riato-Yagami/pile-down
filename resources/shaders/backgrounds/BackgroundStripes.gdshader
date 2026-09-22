shader_type canvas_item;
render_mode unshaded;

global uniform vec2 background_viewport_size;
global uniform vec2 background_reference_size;
global uniform vec4 background_color_a;
global uniform vec4 background_color_b;
global uniform float background_intensity;
uniform vec2 speed = vec2(0.41, 0.0);
uniform float time = 0.0;
global uniform float background_pixelated;
global uniform float background_pixel_size;
uniform float transition_t = 1.0;
uniform float rotation = 0.0;
uniform float line_width = 0.03;
uniform float line_spacing = 8.0;

float line_mask(float value, float width, float softness) {
	float centered = abs(fract(value) - 0.5);
	return 1.0 - smoothstep(width, width + softness, centered);
}

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

void fragment() {
	float effective_time = TIME + time;
	vec2 pixel = UV * background_viewport_size;
	if (background_pixelated > 0.5) {
		float block_size = max(background_pixel_size, 1.0);
		pixel = (floor(pixel / block_size) + vec2(0.5)) * block_size;
	}
	vec2 uv = rotate_uv(pixel / max(background_reference_size, vec2(1.0)), radians(rotation));
	float pattern = line_mask(
		(uv.x + uv.y * 0.65) * line_spacing + dot(speed, vec2(1.0)) * effective_time,
		line_width * 6.66,
		line_width * 1.33
	);
	float amount = pattern * background_color_b.a * background_intensity * 1.45;
	vec3 background = mix(background_color_a.rgb, background_color_b.rgb, amount);
	COLOR = vec4(background, background_color_a.a * transition_reveal(pixel));
}
