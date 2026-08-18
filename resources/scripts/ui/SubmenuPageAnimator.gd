class_name SubmenuPageAnimator
extends RefCounted

var duration := 0.18
var travel_distance := 18.0

var _active_tween: Tween
var _active_target: Control
var _resting_position := Vector2.ZERO


func play(target: Control, direction: int) -> void:
	_stop()
	_active_target = target
	_resting_position = target.position
	var direction_sign := signi(direction)
	if direction_sign == 0 or duration <= 0.0:
		return
	target.position = _resting_position + Vector2(
		travel_distance * float(direction_sign), 0.0
	)
	target.modulate.a = 0.0
	_active_tween = target.create_tween().set_parallel(true)
	_active_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(target, "position", _resting_position, duration)
	_active_tween.tween_property(target, "modulate:a", 1.0, duration)
	_active_tween.finished.connect(_finish.bind(target))


func _stop() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	if is_instance_valid(_active_target):
		_active_target.position = _resting_position
		_active_target.modulate.a = 1.0
	_active_tween = null
	_active_target = null


func _finish(target: Control) -> void:
	if target != _active_target:
		return
	target.position = _resting_position
	target.modulate.a = 1.0
	_active_tween = null
	_active_target = null
