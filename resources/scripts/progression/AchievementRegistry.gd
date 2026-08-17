class_name AchievementRegistry
extends RefCounted

const CATALOG: DataCatalog = preload("res://resources/data/achievements.tres")


static func create_all() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as AchievementData
		if data == null:
			push_warning("Ignoring non-AchievementData entry in achievement catalog.")
			continue
		result.append(data)
	return result


static func create_declared() -> Array[AchievementData]:
	return create_all()
