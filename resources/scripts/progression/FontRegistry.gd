class_name FontRegistry
extends RefCounted

const PRESS_START := preload("res://resources/fonts/PressStart2P-Regular.ttf")
const TINY5 := preload("res://resources/fonts/Tiny5-Regular.ttf")
const VCR := preload("res://resources/fonts/VCR_OSD_MONO_1.001.ttf")


static func create_all() -> Array[FontData]:
	var achievements := AchievementRegistry.create_all()
	return [
		FontData.new(&"press_start_2p", "PRESS START 2P", PRESS_START, true),
		FontData.new(
			&"tiny5", "TINY5", TINY5, false,
			_find_achievement(achievements, &"complete_10_rounds")
		),
		FontData.new(
			&"vcr", "VCR OSD MONO", VCR, false,
			_find_achievement(achievements, &"complete_no_life_lost")
		),
	]


static func _find_achievement(
	achievements: Array[AchievementData], id: StringName
) -> AchievementData:
	for achievement in achievements:
		if achievement.id == id:
			return achievement
	return null
