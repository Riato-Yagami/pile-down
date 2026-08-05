class_name StickyFingersRuleController
extends Node

const STICKY_CURSOR := preload("res://resources/sprites/ui/icons/sticky-cursor.svg")

var cursor_enabled := false


func begin_round(enabled: bool) -> void:
	set_cursor_enabled(enabled)


func end_round() -> void:
	set_cursor_enabled(false)


func set_cursor_enabled(enabled: bool) -> void:
	if cursor_enabled == enabled:
		return
	cursor_enabled = enabled
	for cursor_shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND]:
		if enabled:
			Input.set_custom_mouse_cursor(
				STICKY_CURSOR,
				cursor_shape,
				Vector2(2.0, 2.0)
			)
		else:
			Input.set_custom_mouse_cursor(null, cursor_shape)
