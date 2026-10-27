class_name ValueStyleManager
extends Node

signal style_changed(style: StringName)

const CATALOG := preload("res://resources/data/value_styles.tres")
var selected_style: StringName = &"numbers"
var achievements: Array[StringName] = []


static func find(style: StringName) -> ValueStyleData:
	for data: ValueStyleData in CATALOG.enabled_data:
		if data.id == style:
			return data
	return null


func is_unlocked(data: ValueStyleData) -> bool:
	return data.default_unlocked or (data.required_achievement != null and achievements.has(data.required_achievement.id))


func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data: ValueStyleData in CATALOG.enabled_data:
		result.append({"id": data.id, "title": data.title, "unlocked": is_unlocked(data)})
	return result


func load_progress() -> void:
	var config := SaveConfig.load_current()
	achievements.assign(config.get_value("progression", "unlocked_achievements", []))
	var saved := StringName(config.get_value("settings", "selected_value_style", "numbers"))
	var data := find(saved)
	selected_style = saved if data != null and is_unlocked(data) else &"numbers"


func select(style: StringName) -> bool:
	var data := find(style)
	if data == null or not is_unlocked(data):
		return false
	selected_style = style
	var config := SaveConfig.load_current()
	config.set_value("settings", "selected_value_style", String(style))
	config.save(SaveConfig.PATH)
	style_changed.emit(style)
	return true
