class_name SubmenuSwipeController
extends RefCounted

var duration := 0.28
var _generation := 0
var _active_tween: Tween
var _resting_positions: Dictionary = {}


func open(menu: Control, travel_distance: float) -> void:
	var generation := _begin_transition()
	var resting_position := _resting_position(menu)
	menu.position = resting_position + Vector2(maxf(travel_distance, 1.0), 0.0)
	menu.visible = true
	_active_tween = menu.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	_active_tween.tween_property(menu, "position", resting_position, duration)
	await _active_tween.finished
	if generation == _generation:
		_active_tween = null


func close(menu: Control, travel_distance: float) -> void:
	var generation := _begin_transition()
	var resting_position := _resting_position(menu)
	menu.visible = true
	_active_tween = menu.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN
	)
	_active_tween.tween_property(
		menu,
		"position",
		resting_position + Vector2(maxf(travel_distance, 1.0), 0.0),
		duration
	)
	await _active_tween.finished
	if generation != _generation:
		return
	menu.visible = false
	menu.position = resting_position
	_active_tween = null


func _begin_transition() -> int:
	_generation += 1
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
	return _generation


func _resting_position(menu: Control) -> Vector2:
	var instance_id := menu.get_instance_id()
	if not _resting_positions.has(instance_id):
		_resting_positions[instance_id] = menu.position
	return _resting_positions[instance_id] as Vector2
