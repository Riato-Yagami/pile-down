class_name FontRegistry
extends RefCounted

const CATALOG: DataCatalog = preload("res://resources/data/fonts.tres")


static func create_all() -> Array[FontData]:
	var result: Array[FontData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as FontData
		if data == null:
			push_warning("Ignoring non-FontData entry in font catalog.")
			continue
		result.append(data)
	return result
