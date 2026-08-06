class_name ColorPaletteData
extends Resource

@export var id: StringName
@export var display_name: String
@export var colors: Array[Color] = []
@export var default_unlocked := false
@export var required_achievement: AchievementData


func _init(
	palette_id: StringName = &"",
	name := "",
	palette_colors: Array[Color] = [],
	unlocked := false,
	achievement: AchievementData = null
) -> void:
	id = palette_id
	display_name = name
	colors = palette_colors
	default_unlocked = unlocked
	required_achievement = achievement


func normalized_colors() -> Array[Color]:
	var result := colors.duplicate()
	if result.is_empty():
		result.assign(GameSettings.TILE_COLORS.slice(0, 10))
	while result.size() < 10:
		result.append(result[result.size() % maxi(result.size(), 1)])
	result.resize(10)
	return result
