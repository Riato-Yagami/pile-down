extends SceneTree
## Configure the isolated build editor from the paths validated by the shell script.


func _initialize() -> void:
	call_deferred("_configure")


func _configure() -> void:
	var config_dir := OS.get_config_dir().path_join("Godot" if OS.has_feature("windows") or OS.has_feature("macos") else "godot")
	var version := Engine.get_version_info()
	var settings_path := config_dir.path_join(
		"editor_settings-%s.%s.tres" % [version.major, version.minor]
	)
	DirAccess.make_dir_recursive_absolute(config_dir)
	var contents := '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
	if FileAccess.file_exists(settings_path):
		contents = FileAccess.get_file_as_string(settings_path)
	# Change only these two serialized string properties; retain all other settings.
	for entry in {
		"export/android/java_sdk_path": OS.get_environment("JAVA_HOME"),
		"export/android/android_sdk_path": OS.get_environment("ANDROID_HOME"),
	}:
		var variable := "JAVA_HOME" if entry.ends_with("java_sdk_path") else "ANDROID_HOME"
		var line: String = entry + " = " + var_to_str(OS.get_environment(variable))
		var pattern := RegEx.new()
		pattern.compile('(?m)^' + entry + '\\s*=\\s*"(?:[^"\\\\]|\\\\.)*"[ \\t]*$')
		var found := pattern.search(contents)
		if found != null:
			contents = contents.substr(0, found.get_start()) + line + contents.substr(found.get_end())
		else:
			contents += "\n" + line + "\n"
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot save Android build editor settings: " + settings_path)
		quit(1)
		return
	file.store_string(contents)
	file.close()
	quit()
