class_name AchievementRegistry
extends RefCounted

const DATA_DIRECTORY := "res://resources/achievements"


static func create_all() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	var file_names := DirAccess.get_files_at(DATA_DIRECTORY)
	file_names.sort()
	for file_name in file_names:
		if file_name.get_extension().to_lower() != "tres":
			continue
		var path := DATA_DIRECTORY.path_join(file_name)
		var data := load(path) as AchievementData
		if data == null:
			push_warning("Ignoring invalid AchievementData resource: %s" % path)
			continue
		result.append(data)
	return result


static func create_declared() -> Array[AchievementData]:
	return create_all()
