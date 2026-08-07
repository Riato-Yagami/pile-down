class_name FontRegistry
extends RefCounted

const DATA_DIRECTORY := "res://resources/fonts/data"


static func create_all() -> Array[FontData]:
	var result: Array[FontData] = []
	var file_names := DirAccess.get_files_at(DATA_DIRECTORY)
	file_names.sort()
	for file_name in file_names:
		if file_name.get_extension().to_lower() != "tres":
			continue
		var path := DATA_DIRECTORY.path_join(file_name)
		var data := load(path) as FontData
		if data == null:
			push_warning("Ignoring invalid FontData resource: %s" % path)
			continue
		result.append(data)
	return result
