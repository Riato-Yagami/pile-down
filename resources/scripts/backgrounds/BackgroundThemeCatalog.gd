@tool
class_name BackgroundThemeCatalog
extends SelectableDataCatalog

@export var supports_morph := true:
	set(value):
		supports_morph = value
		emit_changed()
@export var viewport_size := Vector2(256.0, 320.0):
	set(value):
		viewport_size = value
		emit_changed()
@export var reference_size := Vector2(256.0, 320.0):
	set(value):
		reference_size = value
		emit_changed()
@export var background_color := Color(0.9686, 0.9647, 0.9529, 1.0):
	set(value):
		background_color = value
		emit_changed()
@export var pattern_color := Color(0.31, 0.49, 0.72, 0.16):
	set(value):
		pattern_color = value
		emit_changed()
@export_range(0.0, 1.0) var intensity := 1.0:
	set(value):
		intensity = value
		emit_changed()
@export var pixelated := true:
	set(value):
		pixelated = value
		emit_changed()
@export_range(1.0, 8.0, 1.0) var pixel_size := 2.0:
	set(value):
		pixel_size = value
		emit_changed()
@export_tool_button("Next Background Preview", "Forward")
var next_background_preview_action: Callable = next_background_preview


func next_background_preview() -> void:
	var pool := get_selection_pool()
	if pool.is_empty():
		return
	var current_index := pool.find(get_selected_data())
	if current_index < 0:
		current_index = selected_index
	selected_index = (current_index + 1) % pool.size()
