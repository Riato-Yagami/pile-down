class_name CountdownManager
extends Node

signal time_updated(time_left)
signal time_expired()

var duration := 5.0
var time_left := 0.0
var running := false


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(0.0, time_left - delta)
	time_updated.emit(time_left)
	if time_left <= 0.0:
		running = false
		time_expired.emit()


func start_countdown(seconds: float) -> void:
	duration = seconds
	time_left = seconds
	running = true
	time_updated.emit(time_left)


func stop_countdown() -> void:
	running = false


func ratio() -> float:
	return time_left / duration if duration > 0.0 else 0.0
