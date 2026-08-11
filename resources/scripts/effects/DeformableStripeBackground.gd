@tool
class_name DeformableStripeBackground
extends Control

const MAX_IMPULSES := 8
const MAX_TILE_WEIGHTS := 16
const BACKGROUND_SHADER := preload(
	"res://resources/shaders/DeformableBackground.gdshader"
)

@export_group("Pixel Filter")
@export_range(1.0, 8.0, 1.0) var background_pixel_size := 2.0:
	set(value):
		background_pixel_size = maxf(value, 1.0)
		_upload_pixel_filter()
@export_group("Deformation Timing")
@export_range(0.1, 2.0, 0.05) var effect_speed := 0.6
@export_range(0.1, 2.0, 0.05) var motion_lifetime := 0.55
@export_range(20.0, 400.0, 5.0) var wave_speed := 150.0
@export_range(0.0, 1.0, 0.01) var wave_tail_duration := 0.22
@export_group("Deformation Shape")
@export_range(8.0, 160.0, 1.0) var motion_radius := 46.0
@export_range(0.01, 0.3, 0.005) var motion_strength := 0.075
@export_range(1.0, 40.0, 0.5) var wave_strength := 12.0
@export_group("Tile Weight")
@export_range(8.0, 80.0, 1.0) var tile_weight_radius := 30.0:
	set(value):
		tile_weight_radius = value
		_refresh_editor_weight_preview()
@export_range(0.0, 8.0, 0.1) var tile_weight_strength := 2.0:
	set(value):
		tile_weight_strength = value
		_refresh_editor_weight_preview()
@export_range(0.0, 3.0, 0.1) var pile_weight_multiplier := 1.4:
	set(value):
		pile_weight_multiplier = value
		_refresh_editor_weight_preview()
@export_range(0.0, 3.0, 0.1) var card_weight_multiplier := 0.65
@export_range(1.0, 4.0, 0.1) var dragged_weight_multiplier := 1.8
@export_group("Tile Impact Wave")
@export_range(0.05, 0.6, 0.01) var tile_impact_wave_lifetime := 0.2
@export_range(20.0, 200.0, 5.0) var tile_impact_wave_speed := 105.0
@export_range(0.0, 8.0, 0.1) var tile_impact_wave_strength := 3.0
@export_group("Editor Preview")
@export var show_pile_weight_preview := true:
	set(value):
		show_pile_weight_preview = value
		_refresh_editor_weight_preview()
var enabled := true:
	set(value):
		enabled = value
		if is_instance_valid(_shader_material):
			_shader_material.set_shader_parameter(
				"effect_enabled", 1.0 if enabled else 0.0
			)
var impulses: Array[Dictionary] = []
var _shader_material: ShaderMaterial
var _stripe_material: ShaderMaterial
var _background_art: ColorRect


func _ready() -> void:
	if Engine.is_editor_hint():
		setup()
		_refresh_editor_weight_preview()


func setup() -> void:
	effect_speed = maxf(effect_speed, 0.01)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_art = get_node("BackgroundArt") as ColorRect
	var deformation_overlay := get_node("DeformationOverlay") as ColorRect
	_shader_material = deformation_overlay.material as ShaderMaterial
	if _shader_material == null:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = BACKGROUND_SHADER
		deformation_overlay.material = _shader_material
	_stripe_material = _background_art.material as ShaderMaterial
	_shader_material.set_shader_parameter("effect_enabled", 1.0 if enabled else 0.0)
	_upload_pixel_filter()
	if not Engine.is_editor_hint():
		var preview := get_node_or_null("EditorPileWeightPreview")
		if preview != null:
			remove_child(preview)
			preview.queue_free()
		# The external material may still contain the editor preview's uniforms.
		set_tile_weights([])
	resize_to_viewport()
	_upload_impulses()
	_refresh_editor_weight_preview()
	set_process(true)


func _upload_pixel_filter() -> void:
	if is_instance_valid(_shader_material):
		_shader_material.set_shader_parameter("pixel_size", background_pixel_size)
	if is_instance_valid(_stripe_material):
		_stripe_material.set_shader_parameter("pixel_size", background_pixel_size)


func _refresh_editor_weight_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var preview := get_node_or_null("EditorPileWeightPreview") as Control
	if preview == null:
		return
	preview.visible = show_pile_weight_preview
	if not is_instance_valid(_shader_material):
		return
	if show_pile_weight_preview:
		set_tile_weights(
			[preview],
			null,
			{preview.get_instance_id(): pile_weight_multiplier}
		)
	else:
		set_tile_weights([])


func resize_to_viewport() -> void:
	# Gameplay deliberately remains centered at 256x320. The background is a
	# viewport-space layer, so detach its rectangle from that centered parent.
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	global_position = Vector2.ZERO
	size = get_viewport_rect().size
	if is_instance_valid(_shader_material):
		_shader_material.set_shader_parameter("viewport_size", size)
	if is_instance_valid(_stripe_material):
		_stripe_material.set_shader_parameter("viewport_size", size)
	_extend_active_waves_to_viewport()


func emit_motion(global_point: Vector2, velocity: Vector2, impulse_scale := 1.0) -> void:
	if not enabled or velocity.length_squared() < 16.0:
		return
	_add_impulse(
		_to_local_point(global_point),
		velocity.normalized(),
		motion_radius + 8.0 * impulse_scale,
		minf(velocity.length(), 90.0) * motion_strength * impulse_scale,
		motion_lifetime,
		false
	)


func set_tile_weights(
	tiles: Array[Control],
	dragged_tile: Control = null,
	strength_multipliers: Dictionary = {}
) -> void:
	if not is_instance_valid(_shader_material):
		return
	var weights := PackedVector4Array()
	var shapes := PackedVector4Array()
	for tile in tiles:
		if weights.size() >= MAX_TILE_WEIGHTS:
			break
		if not is_instance_valid(tile) or not tile.visible:
			continue
		var rect := tile.get_global_rect().abs()
		var radius := maxf(tile_weight_radius, maxf(rect.size.x, rect.size.y) * 0.72)
		var strength := tile_weight_strength * float(
			strength_multipliers.get(tile.get_instance_id(), 1.0)
		)
		if tile == dragged_tile:
			strength *= dragged_weight_multiplier
		var local_center := _to_local_point(rect.get_center())
		weights.append(Vector4(local_center.x, local_center.y, radius, strength))
		var half_size := rect.size * 0.5
		var corner_radius := minf(5.0, minf(half_size.x, half_size.y) * 0.35)
		shapes.append(Vector4(half_size.x, half_size.y, corner_radius, 0.0))
	while weights.size() < MAX_TILE_WEIGHTS:
		weights.append(Vector4.ZERO)
		shapes.append(Vector4.ZERO)
	_shader_material.set_shader_parameter("tile_weights", weights)
	_shader_material.set_shader_parameter("tile_weight_shapes", shapes)


func emit_wave(global_center: Vector2, influence := 1.0) -> void:
	if not enabled or influence <= 0.0:
		return
	var local_center := _to_local_point(global_center)
	var required_radius := _required_wave_exit_radius(local_center)
	var required_lifetime := (
		maxf(required_radius - 1.0, 0.0) / maxf(wave_speed, 0.01)
		+ wave_tail_duration
	)
	_add_impulse(
		local_center,
		Vector2.ZERO,
		1.0,
		wave_strength * influence,
		required_lifetime,
		true,
		required_radius,
		true
	)


func emit_tile_impact_wave(global_center: Vector2) -> void:
	if not enabled or tile_impact_wave_strength <= 0.0:
		return
	_add_impulse(
		_to_local_point(global_center),
		Vector2.ZERO,
		1.0,
		tile_impact_wave_strength,
		tile_impact_wave_lifetime,
		true
	)


func _required_wave_exit_radius(local_center: Vector2) -> float:
	var farthest_corner_distance := 0.0
	for corner in [
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		Vector2(0.0, size.y),
		size,
	]:
		farthest_corner_distance = maxf(
			farthest_corner_distance, local_center.distance_to(corner)
		)
	# Include the shader falloff: the wave is finished only when its outer edge,
	# not merely its centre line, has crossed the farthest viewport corner.
	var wave_outer_width := 20.0
	if is_instance_valid(_shader_material):
		var configured_width: Variant = _shader_material.get_shader_parameter(
			"wave_outer_width"
		)
		if configured_width is float:
			wave_outer_width = configured_width
	return farthest_corner_distance + wave_outer_width


func _extend_active_waves_to_viewport() -> void:
	for impulse in impulses:
		if not bool(impulse["full_viewport_wave"]):
			continue
		var exit_radius := _required_wave_exit_radius(
			impulse["center"] as Vector2
		)
		impulse["exit_radius"] = exit_radius
		var travel_remaining := maxf(
			exit_radius - float(impulse["radius"]), 0.0
		) / maxf(wave_speed, 0.01)
		impulse["remaining"] = maxf(
			float(impulse["remaining"]),
			travel_remaining + wave_tail_duration
		)


func _process(delta: float) -> void:
	if delta <= 0.0 or impulses.is_empty():
		return
	var effect_delta := delta * effect_speed
	for impulse in impulses:
		impulse["remaining"] = float(impulse["remaining"]) - effect_delta
		var lifetime := float(impulse["lifetime"])
		if bool(impulse["wave"]):
			if bool(impulse["full_viewport_wave"]):
				# Keep the completion ring readable until it leaves the viewport.
				var fade := clampf(
					float(impulse["remaining"]) / maxf(wave_tail_duration, 0.001),
					0.0,
					1.0
				)
				impulse["current_strength"] = float(impulse["strength"]) * fade
				impulse["radius"] = (
					float(impulse["radius"]) + wave_speed * effect_delta
				)
			else:
				var ratio := clampf(float(impulse["remaining"]) / lifetime, 0.0, 1.0)
				impulse["current_strength"] = float(impulse["strength"]) * ratio * ratio
				impulse["radius"] = (
					float(impulse["radius"]) + tile_impact_wave_speed * effect_delta
				)
		else:
			var ratio := clampf(float(impulse["remaining"]) / lifetime, 0.0, 1.0)
			impulse["current_strength"] = float(impulse["strength"]) * ratio * ratio
	for impulse_index in range(impulses.size() - 1, -1, -1):
		if float(impulses[impulse_index]["remaining"]) <= 0.0:
			impulses.remove_at(impulse_index)
	_upload_impulses()


func _add_impulse(
	center: Vector2,
	direction: Vector2,
	radius: float,
	strength: float,
	lifetime: float,
	is_wave: bool,
	exit_radius := 0.0,
	full_viewport_wave := false
) -> void:
	if impulses.size() >= MAX_IMPULSES:
		var removable_index := -1
		for impulse_index in impulses.size():
			if not bool(impulses[impulse_index]["full_viewport_wave"]):
				removable_index = impulse_index
				break
		# Frequent pointer/tile motion must never truncate a completion wave.
		if removable_index < 0 and not is_wave:
			return
		impulses.remove_at(maxi(removable_index, 0))
	impulses.append({
		"center": center,
		"direction": direction,
		"radius": radius,
		"strength": strength,
		"current_strength": strength,
		"lifetime": lifetime,
		"remaining": lifetime,
		"wave": is_wave,
		"exit_radius": exit_radius,
		"full_viewport_wave": full_viewport_wave,
	})
	_upload_impulses()


func _upload_impulses() -> void:
	if not is_instance_valid(_shader_material):
		return
	var shader_impulses := PackedVector4Array()
	var shader_directions := PackedVector2Array()
	for impulse_index in MAX_IMPULSES:
		if impulse_index < impulses.size():
			var impulse := impulses[impulse_index]
			var center := impulse["center"] as Vector2
			shader_impulses.append(Vector4(
				center.x,
				center.y,
				float(impulse["radius"]),
				float(impulse["current_strength"])
			))
			shader_directions.append(impulse["direction"] as Vector2)
		else:
			shader_impulses.append(Vector4.ZERO)
			shader_directions.append(Vector2.ZERO)
	_shader_material.set_shader_parameter("impulses", shader_impulses)
	_shader_material.set_shader_parameter("impulse_directions", shader_directions)


func _to_local_point(global_point: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * global_point
