shader_type canvas_item;
render_mode unshaded;

const int MAX_IMPULSES = 8;
const int MAX_TILE_WEIGHTS = 16;

uniform vec2 viewport_size = vec2(256.0, 320.0);
uniform float pixel_size : hint_range(1.0, 8.0, 1.0) = 2.0;
uniform vec4 impulses[MAX_IMPULSES];
uniform vec2 impulse_directions[MAX_IMPULSES];
// xy = centre in viewport pixels, z = bend radius, w = weight strength.
uniform vec4 tile_weights[MAX_TILE_WEIGHTS];
// xy = half-size of the tile, z = rounded-corner radius.
uniform vec4 tile_weight_shapes[MAX_TILE_WEIGHTS];
uniform float effect_enabled = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float wave_inner_width : hint_range(1.0, 30.0, 1.0) = 7.0;
uniform float wave_outer_width : hint_range(2.0, 50.0, 1.0) = 20.0;

void fragment() {
	float block_size = max(pixel_size, 1.0);
	vec2 source_pixel = UV * viewport_size;
	vec2 pixel = (floor(source_pixel / block_size) + vec2(0.5)) * block_size;
	vec2 displacement = vec2(0.0);
	for (int index = 0; index < MAX_TILE_WEIGHTS; index++) {
		vec4 tile_weight = tile_weights[index];
		if (tile_weight.z <= 0.0 || tile_weight.w <= 0.0) {
			continue;
		}
		vec2 offset = pixel - tile_weight.xy;
		vec3 shape = tile_weight_shapes[index].xyz;
		vec2 rounded = abs(offset) - shape.xy + vec2(shape.z);
		float signed_distance = length(max(rounded, vec2(0.0)))
			+ min(max(rounded.x, rounded.y), 0.0) - shape.z;
		float outside_distance = max(signed_distance, 0.0);
		float outer_falloff = 1.0 - smoothstep(
			0.0, tile_weight.z, outside_distance
		);
		// The fabric directly beneath the stone stays visually stable. Tension
		// rises just outside its rounded edge, then relaxes into the background.
		float edge_tension = smoothstep(
			0.0, max(tile_weight.z * 0.2, 0.001), outside_distance
		);
		float profile = outer_falloff * edge_tension;
		if (length(offset) > 0.001 && signed_distance >= 0.0) {
			displacement += normalize(offset) * tile_weight.w * profile;
		}
	}
	for (int index = 0; index < MAX_IMPULSES; index++) {
		vec4 impulse = impulses[index];
		vec2 offset = pixel - impulse.xy;
		float distance_to_center = length(offset);
		vec2 direction = impulse_directions[index];
		float falloff;
		if (length(direction) < 0.001) {
			// A completion wave is a moving ring, not an expanding filled disc.
			falloff = 1.0 - smoothstep(
				wave_inner_width,
				max(wave_outer_width, wave_inner_width + 0.001),
				abs(distance_to_center - impulse.z)
			);
		} else {
			falloff = 1.0 - smoothstep(
				0.0, max(impulse.z, 0.001), distance_to_center
			);
		}
		if (length(direction) < 0.001 && distance_to_center > 0.001) {
			direction = offset / distance_to_center;
		}
		displacement += direction * impulse.w * falloff;
	}
	// The back buffer is expressed in screen space. Artwork now covers the full
	// viewport, so SCREEN_UV remains aligned for every adaptive aspect ratio.
	vec2 deformed_uv = SCREEN_UV + (
		pixel - source_pixel - displacement * effect_enabled
	) / max(viewport_size, vec2(1.0));
	COLOR = texture(screen_texture, deformed_uv);
}
