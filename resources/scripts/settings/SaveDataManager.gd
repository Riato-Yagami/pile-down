class_name SaveDataManager
extends Node

const SAVE_PATH := SaveConfig.PATH
const EXPORT_FORMAT := "pile-down-save"
const EXPORT_VERSION := 1


func export_json(path: String) -> Error:
	var config := ConfigFile.new()
	var load_error := config.load(SAVE_PATH)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error
	var sections := {}
	for section in config.get_sections():
		var values := {}
		for key in config.get_section_keys(section):
			values[str(key)] = config.get_value(section, key)
		sections[str(section)] = values
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"format": EXPORT_FORMAT,
		"version": EXPORT_VERSION,
		"sections": JSON.from_native(sections),
	}, "\t"))
	return OK


func import_json(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return parse_error
	if not json.data is Dictionary:
		return ERR_INVALID_DATA
	var payload := json.data as Dictionary
	if str(payload.get("format", "")) != EXPORT_FORMAT:
		return ERR_INVALID_DATA
	if int(payload.get("version", 0)) > EXPORT_VERSION:
		return ERR_INVALID_DATA
	var sections_value: Variant = JSON.to_native(payload.get("sections"))
	if not sections_value is Dictionary:
		return ERR_INVALID_DATA
	var imported := ConfigFile.new()
	for section_value in (sections_value as Dictionary):
		var section := str(section_value)
		var values: Variant = (sections_value as Dictionary)[section_value]
		if not values is Dictionary:
			return ERR_INVALID_DATA
		for key_value in (values as Dictionary):
			if section == "challenges" and not ChallengeManager.is_valid_progress_value(
				str(key_value), values[key_value]
			):
				return ERR_INVALID_DATA
			imported.set_value(
				section, str(key_value), (values as Dictionary)[key_value]
			)
	return imported.save(SAVE_PATH)


func delete_save() -> Error:
	if not FileAccess.file_exists(SAVE_PATH):
		return OK
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
