class_name AchievementManager
extends Node

signal achievement_unlocked(data: AchievementData)

const SAVE_PATH := "user://pile_down.cfg"
var definitions: Array[AchievementData] = AchievementRegistry.create_all()
var unlocked: Array[StringName] = []


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		unlocked.assign(config.get_value("progression", "unlocked_achievements", []))


func unlock(id: StringName, persist := true) -> bool:
	if unlocked.has(id):
		return false
	var data := find(id)
	if data == null:
		return false
	unlocked.append(id)
	if persist:
		_save()
	achievement_unlocked.emit(data)
	return true


func find(id: StringName) -> AchievementData:
	for data in definitions:
		if data.id == id:
			return data
	return null


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("progression", "unlocked_achievements", unlocked)
	config.save(SAVE_PATH)
