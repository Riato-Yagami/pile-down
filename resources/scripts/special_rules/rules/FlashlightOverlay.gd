class_name FlashlightOverlay
extends ColorRect

const Difficulty := preload("res://resources/scripts/settings/difficulty.gd")
const TileAfterglow := preload("res://resources/scripts/special_rules/rules/TileAfterglow.gd")

var flashlight_radius := Difficulty.LIGHTS_OUT_RADIUS
@export var flashlight_softness := 14.0
@export_range(0.0, 1.0, 0.005) var darkness_alpha := 0.985

var target_position := Vector2(128.0, 160.0)
var light_position := Vector2(128.0, 160.0)
var animated_radius := 54.0
var _transition_tween: Tween
var _using_touch_input := false
var _appearance_generation := 0


func illuminate_appearance(tile: Control, delay := 0.0) -> void:
	var generation := _appearance_generation
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if generation != _appearance_generation or not visible or not is_instance_valid(tile):
		return
	var glow := TileAfterglow.new()
	add_child(glow)
	if tile is PlayingCard or tile is MemoryPile:
		glow.setup(tile.face_sprite, tile.back_sprite, tile.value_label)
	else:
		glow.queue_free()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	animated_radius = flashlight_radius
	_update_shader()


func _process(delta: float) -> void:
	if not visible:
		return
	# A touch does not move Godot's mouse position when mouse emulation is off.
	# Keep the last finger position instead of replacing it with a stale cursor.
	if not _using_touch_input:
		var viewport := get_viewport()
		if viewport == null:
			return
		target_position = get_global_transform_with_canvas().affine_inverse() * viewport.get_mouse_position()
	light_position = light_position.lerp(target_position, minf(delta * 14.0, 1.0)).round()
	_update_shader()


func follow_touch(position: Vector2) -> void:
	_using_touch_input = true
	target_position = (get_global_transform_with_canvas().affine_inverse() * position).round()
	# A trailing light hides the card beneath a fast-moving finger. Touch input
	# therefore updates immediately while mouse input keeps its soft easing.
	light_position = target_position
	_update_shader()


func close_in(touchscreen := DisplayServer.is_touchscreen_available()) -> void:
	_clear_afterglows()
	_kill_transition()
	visible = true
	_using_touch_input = touchscreen
	var viewport := get_viewport()
	target_position = (
		size * 0.5 if touchscreen or viewport == null
		else get_global_transform_with_canvas().affine_inverse() * viewport.get_mouse_position()
	)
	light_position = target_position
	animated_radius = _fully_open_radius()
	_update_shader()
	_transition_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_transition_tween.tween_property(self, "animated_radius", flashlight_radius, 0.65)


func open_out(animated := true) -> void:
	_clear_afterglows()
	if not visible:
		return
	_kill_transition()
	if not animated:
		visible = false
		animated_radius = flashlight_radius
		_update_shader()
		return
	_transition_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_transition_tween.tween_property(self, "animated_radius", _fully_open_radius(), 0.55)
	await _transition_tween.finished
	visible = false
	animated_radius = flashlight_radius
	_update_shader()


func _fully_open_radius() -> float:
	return size.length() + flashlight_softness


func _clear_afterglows() -> void:
	_appearance_generation += 1
	for child in get_children():
		if child is TileAfterglow:
			child.queue_free()


func _kill_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()


func _update_shader() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("light_position", light_position)
	shader_material.set_shader_parameter("viewport_size", size)
	shader_material.set_shader_parameter("radius", animated_radius)
	shader_material.set_shader_parameter("softness", flashlight_softness)
	shader_material.set_shader_parameter("darkness_alpha", darkness_alpha)
