class_name FontManager
extends Node

signal font_changed(font_id: StringName)

const SAVE_PATH := SaveConfig.PATH
var definitions: Array[FontData] = FontRegistry.create_all()
var unlocked: Array[StringName] = []
var selected_font: StringName = &"press_start_2p"


func load_progress() -> void:
	var config := SaveConfig.load_current()
	for data in definitions:
		if data.default_unlocked and not unlocked.has(data.id):
			unlocked.append(data.id)
	var saved_fonts: Array = config.get_value("progression", "unlocked_fonts", [])
	for value in saved_fonts:
		var id := StringName(value)
		if not unlocked.has(id):
			unlocked.append(id)
	selected_font = StringName(config.get_value("settings", "selected_font", selected_font))
	if not unlocked.has(selected_font):
		selected_font = &"press_start_2p"


func unlock_for_achievement(achievement_id: StringName) -> Array[StringName]:
	var newly_unlocked: Array[StringName] = []
	for data in definitions:
		if (
			data.required_achievement != null
			and data.required_achievement.id == achievement_id
			and not unlocked.has(data.id)
		):
			unlocked.append(data.id)
			newly_unlocked.append(data.id)
	if not newly_unlocked.is_empty():
		_save()
	return newly_unlocked


func select(id: StringName) -> bool:
	if not unlocked.has(id):
		return false
	var data := find(id)
	if data == null:
		return false
	selected_font = id
	_save()
	font_changed.emit(id)
	return true


func find(id: StringName) -> FontData:
	for data in definitions:
		if data.id == id:
			return data
	return null


func _save() -> void:
	var config := SaveConfig.load_current()
	config.set_value("progression", "unlocked_fonts", unlocked)
	config.set_value("settings", "selected_font", selected_font)
	config.save(SAVE_PATH)
