extends SceneTree


func _init() -> void:
	var manager := SaveDataManager.new()
	var config := ConfigFile.new()
	config.set_value("progression", "sample", [1, 2, 3])
	config.set_value("progression", "typed", {&"round": 4, 2: &"bonus"})
	assert(config.save(SaveDataManager.SAVE_PATH) == OK)
	var export_path := "user://test-export.json"
	assert(manager.export_json(export_path) == OK)
	assert(manager.delete_save() == OK)
	assert(not FileAccess.file_exists(SaveDataManager.SAVE_PATH))
	assert(manager.import_json(export_path) == OK)
	var restored := ConfigFile.new()
	assert(restored.load(SaveDataManager.SAVE_PATH) == OK)
	var restored_sample: Array = restored.get_value("progression", "sample", [])
	assert(restored_sample.size() == 3)
	assert(int(restored_sample[0]) == 1)
	assert(int(restored_sample[1]) == 2)
	assert(int(restored_sample[2]) == 3)
	var restored_typed: Dictionary = restored.get_value("progression", "typed", {})
	assert(int(restored_typed[&"round"]) == 4)
	assert(StringName(restored_typed[2]) == &"bonus")
	for invalid_values in [
		{"highscores": "not a dictionary"},
		{"completed": [123]},
		{"highscores": {&"test": -1}},
		{"best_times_ms": {&"test": "invalid"}},
		{"record_seeds": {&"test": {"seed": []}}},
	]:
		var malformed := FileAccess.open(export_path, FileAccess.WRITE)
		malformed.store_string(JSON.stringify({
			"format": SaveDataManager.EXPORT_FORMAT,
			"version": SaveDataManager.EXPORT_VERSION,
			"sections": JSON.from_native({"challenges": invalid_values}),
		}))
		malformed.close()
		assert(manager.import_json(export_path) == ERR_INVALID_DATA)
		assert(restored.load(SaveDataManager.SAVE_PATH) == OK)
		assert(restored.get_value("progression", "sample") == restored_sample)
	config.set_value("challenges", "completed", [&"test"])
	config.set_value("challenges", "highscores", {&"test": 4})
	config.set_value("challenges", "record_seeds", {&"test": {"seed": -42, "seed_label": "TEST"}})
	assert(config.save(SaveDataManager.SAVE_PATH) == OK)
	assert(manager.export_json(export_path) == OK)
	assert(manager.import_json(export_path) == OK)
	var challenges := ChallengeManager.new()
	challenges.load_progress()
	challenges.load_progress()
	assert(challenges.completed == [&"test"])
	assert(challenges.highscores[&"test"] == 4)
	assert(challenges.record_seeds[&"test"]["seed"] == -42)
	challenges.free()
	assert(manager.delete_save() == OK)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(export_path))
	manager.free()
	print("Save data manager tests passed.")
	quit()
