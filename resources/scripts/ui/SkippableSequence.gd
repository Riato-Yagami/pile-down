class_name SkippableSequence
extends Control

signal skipped()

var can_skip := false
var is_skipping := false
var active_tween: Tween


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func begin(tween: Tween) -> void:
	active_tween = tween
	is_skipping = false
	can_skip = true
	visible = true


func finish() -> void:
	can_skip = false
	is_skipping = false
	active_tween = null
	visible = false


func _gui_input(event: InputEvent) -> void:
	if not can_skip or is_skipping or not _is_skip_event(event):
		return
	skip_to_end()
	accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not can_skip or is_skipping or not _is_skip_event(event):
		return
	skip_to_end()
	get_viewport().set_input_as_handled()


func skip_to_end() -> void:
	if not can_skip or is_skipping:
		return
	is_skipping = true
	can_skip = false
	if active_tween != null and active_tween.is_valid():
		active_tween.custom_step(1000000.0)
	skipped.emit()


func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventKey:
		return (
			event.pressed
			and not event.echo
			and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
		)
	return false
