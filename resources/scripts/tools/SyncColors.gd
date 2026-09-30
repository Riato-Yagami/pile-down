extends SceneTree

## Run with --script res://resources/scripts/tools/SyncColors.gd [-- --check].
## Serialization cannot reference GDScript constants. Keep those copies in sync
## without touching data palettes, runtime palette selection or derived colors.
const COLORS := preload("res://resources/scripts/settings/colors.gd")
const BINDINGS := "res://resources/scripts/tools/color_bindings.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var bindings: Array = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS))
	var colors_script: Script = COLORS
	var constants := colors_script.get_script_constant_map()
	var grouped: Dictionary = {}
	for binding: Dictionary in bindings:
		var relative := str(binding.file)
		if relative.contains("..") or not (
			relative == "project.godot"
			or relative.begins_with("resources/scenes/")
			or relative.begins_with("resources/materials/")
			or relative.begins_with("resources/shaders/")
		):
			push_error("Color synchronization cannot modify data palettes or scripts: " + relative)
			quit(1)
			return
		var path := "res://" + str(binding.file)
		if not grouped.has(path):
			grouped[path] = []
		grouped[path].append(binding)
	var changes: Dictionary = {}
	for path: String in grouped:
		var original := FileAccess.get_file_as_string(path)
		var lines := original.split("\n")
		var section := ""
		var matched: Dictionary = {}
		for index in lines.size():
			var line := lines[index]
			if line.begins_with("["):
				var header := RegEx.create_from_string(" unique_id=[0-9]+")
				section = header.sub(line.strip_edges(), "", true)
			elif section.begins_with("[shader_globals]") and line.ends_with("={"):
				section = "[shader_globals]/" + line.get_slice("=", 0)
			var key := line.get_slice("=" if line.contains("=") else ":", 0).strip_edges()
			for binding: Dictionary in grouped[path]:
				if section != binding.section or key != binding.key:
					continue
				var id := (grouped[path] as Array).find(binding)
				if matched.has(id):
					continue
				var values: Array[Color] = []
				for color_name: String in binding.colors:
					if not constants.get(color_name) is Color:
						push_error("Unknown color: " + color_name)
						quit(1)
						return
					values.append(constants[color_name])
				var expression := "Color\\([^()]*\\)"
				if binding.kind == "vec4":
					expression = "vec4\\([^()]*\\)"
				elif binding.kind == "gradient":
					expression = "PackedColorArray\\([^()]*\\)"
				var matches := RegEx.create_from_string(expression).search_all(line)
				var expected := 1 if binding.kind == "gradient" else values.size()
				if matches.size() != expected:
					push_error("Color binding changed: %s %s %s" % [path, section, key])
					quit(1)
					return
				for match_index in range(matches.size() - 1, -1, -1):
					var result := matches[match_index]
					var replacement := ""
					if binding.kind == "gradient":
						var components := PackedStringArray()
						for color in values:
							components.append(_components(color))
						replacement = "PackedColorArray(" + ", ".join(components) + ")"
					else:
						var constructor := "vec4" if binding.kind == "vec4" else "Color"
						replacement = constructor + "(" + _components(values[match_index]) + ")"
					line = line.left(result.get_start()) + replacement + line.substr(result.get_end())
				lines[index] = line
				matched[id] = true
				break
		if matched.size() != grouped[path].size():
			push_error("Missing color bindings in " + path + "; update color_bindings.json after moving nodes/properties.")
			quit(1)
			return
		var updated := "\n".join(lines)
		if updated != original:
			changes[path] = updated
	if OS.get_cmdline_user_args().has("--check"):
		for path: String in changes:
			push_error("Colors out of sync: " + path)
		quit(0 if changes.is_empty() else 1)
		return
	# Validate all bindings before writing any file.
	for path: String in changes:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write " + path)
			quit(1)
			return
		file.store_string(changes[path])
	print("Synchronized colors in %d files; data palettes untouched." % changes.size())
	quit()


func _components(color: Color) -> String:
	return "%.9f, %.9f, %.9f, %.9f" % [color.r, color.g, color.b, color.a]
