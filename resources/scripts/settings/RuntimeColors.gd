extends Node

## Apply serialized color settings before scene scripts initialize their state.
## Palette Resources are deliberately never traversed or modified.
const COLORS := preload("res://resources/scripts/settings/colors.gd")
const BINDINGS := "res://resources/scripts/tools/color_bindings.json"

var _values: Dictionary
var _nodes: Dictionary = {}
var _resources: Dictionary = {}
var _shaders: Array[Shader] = []
var _configured_shaders: Dictionary = {}


func _enter_tree() -> void:
	var settings: Script = COLORS
	_values = settings.get_script_constant_map()
	var bindings: Array = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS))
	for binding: Dictionary in bindings:
		var file := "res://" + str(binding.file)
		var section := str(binding.section)
		if section.begins_with("[node "):
			var name := _attribute(section, "name")
			var parent := _attribute(section, "parent")
			var path := "." if parent.is_empty() else name if parent == "." else parent + "/" + name
			_append(_nodes, file, {"path": path, "property": binding.key, "colors": binding.colors})
		elif section.begins_with("[sub_resource "):
			_append(_resources, file + "::" + _attribute(section, "id"), binding)
		elif section == "[resource]" or file.ends_with(".gdshader"):
			_append(_resources, file, binding)
	# Standalone shaders can also be used by materials created later in code.
	for path: String in _resources:
		if path.ends_with(".gdshader"):
			var shader := load(path) as Shader
			_configure_shader(shader)
			_shaders.append(shader)
	RenderingServer.set_default_clear_color(GameColors.MENU_BACKGROUND)
	RenderingServer.global_shader_parameter_set("background_color_a", GameColors.BACKGROUND_BASE)
	RenderingServer.global_shader_parameter_set("background_color_b", GameColors.BACKGROUND_PATTERN)
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if not node.scene_file_path.is_empty():
		apply_scene(node)


func apply_scene(root: Node) -> void:
	var path := root.scene_file_path
	for binding: Dictionary in _nodes.get(path, []):
		var target := root.get_node_or_null(NodePath(binding.path))
		if target != null:
			target.set(binding.property, _values[binding.colors[0]])
	# Pair original resources with instantiated copies. Local-to-scene materials
	# lose their resource path, but their packed-scene template retains it.
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var state := packed.get_state()
	var visited: Dictionary = {}
	for index in state.get_node_count():
		var target := root.get_node_or_null(state.get_node_path(index))
		if target == null:
			continue
		for property_index in state.get_node_property_count(index):
			var template: Variant = state.get_node_property_value(index, property_index)
			if template is Resource:
				var actual: Variant = target.get(state.get_node_property_name(index, property_index))
				if actual is Resource:
					_apply_resource(template, actual, visited)


func _apply_resource(template: Resource, actual: Resource, visited: Dictionary) -> void:
	if not (
		actual is ShaderMaterial or actual is Theme or actual is StyleBox
		or actual is Gradient or actual is GradientTexture2D
		or actual is GradientTexture1D or actual is CanvasTexture
	):
		return
	if visited.has(actual.get_instance_id()):
		return
	visited[actual.get_instance_id()] = true
	if actual is ShaderMaterial:
		_configure_shader(actual.shader)
	for binding: Dictionary in _resources.get(template.resource_path, []):
		if binding.kind == "gradient":
			var colors := PackedColorArray()
			for color_name: String in binding.colors:
				colors.append(_values[color_name])
			actual.set(binding.key, colors)
		elif binding.kind == "color":
			actual.set(binding.key, _values[binding.colors[0]])
	for property: Dictionary in template.get_property_list():
		if property.type != TYPE_OBJECT or not property.usage & PROPERTY_USAGE_STORAGE:
			continue
		var original: Variant = template.get(property.name)
		var current: Variant = actual.get(property.name)
		if original is Resource and current is Resource:
			_apply_resource(original, current, visited)


func _configure_shader(shader: Shader) -> void:
	if shader == null or _configured_shaders.has(shader.get_instance_id()):
		return
	_configured_shaders[shader.get_instance_id()] = true
	var code := shader.code
	for binding: Dictionary in _resources.get(shader.resource_path, []):
		if binding.kind != "vec4":
			continue
		var uniform_name := str(binding.key).get_slice(" ", 2)
		var regex := RegEx.create_from_string("(uniform vec4 " + uniform_name + "[^=]*= )vec4\\([^)]*\\)")
		var color: Color = _values[binding.colors[0]]
		code = regex.sub(code, "${1}vec4(%.9f, %.9f, %.9f, %.9f)" % [color.r, color.g, color.b, color.a])
	if shader.code != code:
		shader.code = code


func _attribute(section: String, key: String) -> String:
	var result := RegEx.create_from_string(key + "=\"([^\"]*)\"").search(section)
	return result.get_string(1) if result != null else ""


func _append(target: Dictionary, key: String, value: Dictionary) -> void:
	if not target.has(key):
		target[key] = []
	target[key].append(value)
