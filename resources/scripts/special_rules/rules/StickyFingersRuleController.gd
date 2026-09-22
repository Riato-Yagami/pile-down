class_name StickyFingersRuleController
extends Node

var cursor_enabled := false


func begin_round(enabled: bool) -> void:
	set_cursor_enabled(enabled)


func end_round() -> void:
	set_cursor_enabled(false)


func set_cursor_enabled(enabled: bool) -> void:
	if cursor_enabled == enabled:
		return
	cursor_enabled = enabled
	CustomCursor.set_sticky_cursor_enabled(enabled)
