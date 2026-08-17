class_name ColorPaletteRegistry
extends RefCounted

const CATALOG: DataCatalog = preload("res://resources/data/palettes.tres")


static func create_all() -> Array[ColorPaletteData]:
	var result: Array[ColorPaletteData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as ColorPaletteData
		if data == null:
			push_warning("Ignoring non-ColorPaletteData entry in palette catalog.")
			continue
		result.append(data)
	return result
