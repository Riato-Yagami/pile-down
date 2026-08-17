class_name CountdownManager
extends Node

signal time_updated(time_left)
signal time_expired()
signal timer_visibility_requested(visible: bool)
signal grace_period_finished()

var duration := 5.0
var time_left := 0.0
var running := false
var _countdown_generation := 0


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(0.0, time_left - delta)
	time_updated.emit(time_left)
	if time_left <= 0.0:
		running = false
		time_expired.emit()


func start_countdown(seconds: float, grace_duration := 0.0) -> void:
	_countdown_generation += 1
	duration = seconds
	time_left = seconds
	running = true
	time_updated.emit(time_left)
	if grace_duration <= 0.0:
		timer_visibility_requested.emit(true)
		return
	timer_visibility_requested.emit(false)
	_finish_grace_period(_countdown_generation, grace_duration)


func stop_countdown() -> void:
	_countdown_generation += 1
	running = false


func resume_countdown() -> void:
	if time_left > 0.0:
		running = true
		time_updated.emit(time_left)


func add_time(seconds: float) -> void:
	time_left = maxf(time_left + seconds, 0.0)
	duration = maxf(duration, time_left)
	time_updated.emit(time_left)


func ratio() -> float:
	return time_left / duration if duration > 0.0 else 0.0


func _finish_grace_period(generation: int, grace_duration: float) -> void:
	await get_tree().create_timer(grace_duration).timeout
	if generation != _countdown_generation or not running:
		return
	timer_visibility_requested.emit(true)
	grace_period_finished.emit()
