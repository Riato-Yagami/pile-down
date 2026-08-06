class_name FontData
extends Resource

@export var id: StringName
@export var display_name: String
@export var font: Font
@export_range(8, 32, 1) var tile_font_size := 20
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
