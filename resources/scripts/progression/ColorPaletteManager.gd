class_name ColorPaletteManager
extends Node

signal palette_changed(palette_id: StringName)

const SAVE_PATH := SaveConfig.PATH

var definitions: Array[ColorPaletteData] = ColorPaletteRegistry.create_all()
var unlocked: Array[StringName] = []
var selected_palette: StringName = &"arcade"


func load_progress() -> void:
	var config := SaveConfig.load_current()
	for data in definitions:
		if data.default_unlocked and not unlocked.has(data.id):
			unlocked.append(data.id)
	var saved_palettes: Array = config.get_value(
		"progression", "unlocked_palettes", []
	)
	for value in saved_palettes:
		var id := StringName(value)
		if find(id) != null and not unlocked.has(id):
			unlocked.append(id)
	selected_palette = StringName(config.get_value(
		"settings", "selected_palette", selected_palette
	))
	if not unlocked.has(selected_palette):
		selected_palette = unlocked[0] if not unlocked.is_empty() else &"arcade"


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
	if not unlocked.has(id) or find(id) == null:
		return false
	selected_palette = id
	_save()
	palette_changed.emit(id)
	return true


func find(id: StringName) -> ColorPaletteData:
	for data in definitions:
		if data.id == id:
			return data
	return null


func _save() -> void:
	var config := SaveConfig.load_current()
	config.set_value("progression", "unlocked_palettes", unlocked)
	config.set_value("settings", "selected_palette", selected_palette)
	config.save(SAVE_PATH)
