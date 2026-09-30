class_name CountdownRing
extends TextureRect

var _reset_tween: Tween
var _reset_from_ratio := 1.0
var _reset_blend := 1.0:
	set(value):
		_reset_blend = value
		if is_node_ready():
			_update_shader()

@export var ratio := 1.0:
	set(value):
		ratio = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_update_shader()

var flash_strength := 0.0:
	set(value):
		flash_strength = clampf(value, 0.0, 1.0)
		if is_node_ready():
			var shader_material := material as ShaderMaterial
			if shader_material != null:
				shader_material.set_shader_parameter(
					"flash_strength",
					flash_strength
				)


func _ready() -> void:
	custom_minimum_size = Vector2(28, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_shader()


func set_ratio(value: float) -> void:
	ratio = value


func play_reset() -> void:
	# Interpolate only the display: the countdown keeps its actual remaining time.
	_reset_from_ratio = lerpf(_reset_from_ratio, ratio, _reset_blend)
	if _reset_tween != null and _reset_tween.is_valid():
		_reset_tween.kill()
	_reset_blend = 0.0
	_reset_tween = create_tween()
	_reset_tween.tween_property(self, "_reset_blend", 1.0, 0.32).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)


func _update_shader() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	var ring_color := GameColors.ACCENT
	if ratio < 0.4:
		ring_color = GameColors.TIMER_DANGER.lerp(GameColors.TIMER_WARNING, clampf((ratio - 0.2) / 0.2, 0.0, 1.0))
	else:
		ring_color = GameColors.TIMER_WARNING.lerp(GameColors.ACCENT, clampf((ratio - 0.4) / 0.25, 0.0, 1.0))
	ring_color = ring_color.lerp(GameColors.TIMER_RESET, (1.0 - _reset_blend) * 0.8)
	shader_material.set_shader_parameter("progress", lerpf(_reset_from_ratio, ratio, _reset_blend))
	shader_material.set_shader_parameter("progress_color", ring_color)
	shader_material.set_shader_parameter("flash_strength", flash_strength)
