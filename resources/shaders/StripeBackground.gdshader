shader_type canvas_item;
render_mode unshaded;

uniform float effect_enabled : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform vec2 viewport_size = vec2(256.0, 320.0);
uniform vec2 reference_size = vec2(256.0, 320.0);
uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 2.0;
uniform vec4 background_color : source_color = vec4(0.9686, 0.9647, 0.9529, 1.0);
uniform vec4 stripe_color : source_color = vec4(0.31, 0.49, 0.72, 0.13);
uniform float stripe_count : hint_range(1.0, 20.0, 0.5) = 8.0;
uniform float stripe_slope : hint_range(-2.0, 2.0, 0.05) = 0.65;
uniform float stripe_core : hint_range(0.01, 0.45, 0.01) = 0.18;
uniform float stripe_softness : hint_range(0.01, 0.2, 0.01) = 0.05;
uniform float stripe_scroll_speed : hint_range(-1.0, 1.0, 0.005) = 0.035;

void fragment() {
	vec4 source = background_color;
	// Work in reference pixels so changing only one viewport axis adds pattern
	// coverage instead of stretching the existing bands on that axis.
	float block_size = max(pixel_size, 1.0);
	vec2 pixel = (floor(UV * viewport_size / block_size) + vec2(0.5)) * block_size;
	vec2 pattern_uv = pixel / max(reference_size, vec2(1.0));
	float stripe_phase = fract(
		(pattern_uv.x + pattern_uv.y * stripe_slope) * stripe_count
		+ TIME * stripe_scroll_speed
	);
	float stripe_edge = stripe_core + stripe_softness;
	float stripe = 1.0 - smoothstep(
		stripe_core, stripe_edge, abs(stripe_phase - 0.5)
	);
	vec3 background = mix(
		source.rgb, stripe_color.rgb, stripe * stripe_color.a * effect_enabled
	);
	COLOR = vec4(background, source.a);
}
