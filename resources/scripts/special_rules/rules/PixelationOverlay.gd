class_name PixelationOverlay
extends ColorRect

@export_range(0.0, 2.0, 0.05) var transition_duration := 0.4

var pixel_size := 1.0
var _transition_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_shader_pixel_size(pixel_size)


func show_pixelation(requested_pixel_size: float) -> void:
	var target_size := maxf(requested_pixel_size, 1.0)
	_kill_transition()
	var starting_size := pixel_size if visible else 1.0
	_apply_pixel_size(starting_size)
	visible = target_size > 1.0
	if not visible:
		return
	if transition_duration <= 0.0:
		_apply_pixel_size(target_size)
		return
	_transition_tween = (
		create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN_OUT)
	)
	_transition_tween.tween_method(
		_apply_pixel_size,
		starting_size,
		target_size,
		transition_duration
	)


func hide_pixelation(animated := true) -> void:
	_kill_transition()
	if not visible or not animated or transition_duration <= 0.0:
		_apply_pixel_size(1.0)
		visible = false
		return
	var tween := (
		create_tween()
		.set_trans(Tween.TRANS_QUAD)
		.set_ease(Tween.EASE_IN_OUT)
	)
	_transition_tween = tween
	tween.tween_method(
		_apply_pixel_size,
		pixel_size,
		1.0,
		transition_duration
	)
	await tween.finished
	if _transition_tween != tween:
		return
	visible = false
	_transition_tween = null


func _apply_pixel_size(value: float) -> void:
	pixel_size = maxf(value, 1.0)
	_set_shader_pixel_size(pixel_size)


func _kill_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null


func _set_shader_pixel_size(value: float) -> void:
	var shader_material := material as ShaderMaterial
	if shader_material != null:
		shader_material.set_shader_parameter(&"pixel_size", value)
