@tool
class_name ProgressionAchievementCatalog
extends Node

## Achievements shown by the menu and tracked during a game.
@export var achievement_data_catalog: SelectableDataCatalog = AchievementRegistry.CATALOG

var achievements: Array[AchievementData]:
	get:
		return get_achievements()
	set(_value):
		push_warning("Achievements is deprecated. Edit Achievement Data Catalog instead.")


func get_achievements() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	if achievement_data_catalog == null:
		return result
	for entry in achievement_data_catalog.enabled_data:
		var data := entry as AchievementData
		if data == null:
			push_warning("Ignoring non-AchievementData entry in achievement data catalog.")
			continue
		result.append(data)
	ProgressionOrdering.sort_achievements(result)
	return result


func _get_configuration_warnings() -> PackedStringArray:
	if achievement_data_catalog == null:
		return PackedStringArray(["Achievement Data Catalog must be assigned."])
	return PackedStringArray()
