class_name BonusRegistry
extends RefCounted

const CATALOG := preload("res://resources/data/bonuses.tres")


static func create_all() -> Array[BonusData]:
	var result: Array[BonusData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as BonusData
		if data == null:
			push_warning("Ignoring non-BonusData entry in bonus catalog.")
			continue
		result.append(data)
	return result


static func get_bonus(id: StringName) -> BonusData:
	for data in create_all():
		if data.id == id:
			return data
	return null
