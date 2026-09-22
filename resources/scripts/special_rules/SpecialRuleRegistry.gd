class_name SpecialRuleRegistry
extends RefCounted

const CATALOG := preload("res://resources/data/special_rules.tres")


static func create_all_rules() -> Array[SpecialRuleData]:
	var result: Array[SpecialRuleData] = []
	for entry in CATALOG.enabled_data:
		var data := entry as SpecialRuleData
		if data == null:
			push_warning("Ignoring non-SpecialRuleData entry in special-rule catalog.")
			continue
		result.append(data)
	return result
