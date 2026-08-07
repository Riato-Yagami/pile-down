@tool
class_name FontData
extends Resource

@export var id: StringName
@export var display_name: String
@export var font: Font
@export var tile_font_size := 20:
	set(value):
		tile_font_size = value
		emit_changed()
@export var tile_font_offset := Vector2.ZERO:
	set(value):
		tile_font_offset = value
		emit_changed()
@export var title_font_offset := Vector2.ZERO:
	set(value):
		title_font_offset = value
		emit_changed()
## Zero keeps the title synchronized with Tile Font Size.
@export_range(0, 32, 1) var title_font_size := 0:
	set(value):
		title_font_size = value
		emit_changed()
@export var override_hidden_tile_with_font := true:
	set(value):
		override_hidden_tile_with_font = value
		emit_changed()
@export var default_unlocked := false
@export var required_achievement: AchievementData


func _init(
	font_id: StringName = &"", name := "", resource: Font = null,
	unlocked := false, achievement: AchievementData = null, font_size := 20
) -> void:
	id = font_id
	display_name = name
	font = resource
	tile_font_size = font_size
	default_unlocked = unlocked
	required_achievement = achievement
