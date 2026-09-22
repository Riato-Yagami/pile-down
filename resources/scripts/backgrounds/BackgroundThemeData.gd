@tool
class_name BackgroundThemeData
extends Data

@export var display_name: String
@export var shader_scene: PackedScene
@export var material: ShaderMaterial:
	set(value):
		material = value
		emit_changed()
@export var weight := 1.0:
	set(value):
		weight = value
		emit_changed()
@export var runtime_enabled := true:
	set(value):
		runtime_enabled = value
		emit_changed()
@export_category("Debug")
@export var debug_force_next_launch := false
@export var debug_editor_preview := false


func _init(
	background_id: StringName = &"",
	name := ""
) -> void:
	id = background_id
	display_name = name
