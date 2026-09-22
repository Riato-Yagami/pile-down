class_name BackgroundThemeRegistry
extends RefCounted

const CATALOG := preload("res://resources/data/backgrounds.tres")


static func catalog() -> BackgroundThemeCatalog:
	return CATALOG as BackgroundThemeCatalog


static func create_all() -> Array[BackgroundThemeData]:
	var result: Array[BackgroundThemeData] = []
	for data in create_available():
		if not data.runtime_enabled:
			continue
		result.append(data)
	return result


static func create_available() -> Array[BackgroundThemeData]:
	var result: Array[BackgroundThemeData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as BackgroundThemeData
		if data == null:
			push_warning("Ignoring non-BackgroundThemeData entry in background catalog.")
			continue
		result.append(data)
	return result


static func find(id: StringName) -> BackgroundThemeData:
	for data in create_available():
		if data.id == id:
			return data
	return null
