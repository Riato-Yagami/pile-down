extends SceneTree

const BACKGROUNDS: SelectableDataCatalog = preload("res://resources/data/backgrounds.tres")
const FONTS: SelectableDataCatalog = preload("res://resources/data/fonts.tres")
const PALETTES: SelectableDataCatalog = preload("res://resources/data/palettes.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var backgrounds := BACKGROUNDS.duplicate() as SelectableDataCatalog
	assert(backgrounds.enabled_data.size() == 8)
	assert(backgrounds.get_selection_pool().size() == backgrounds.enabled_data.size())
	assert(backgrounds.get_selected_data().id == &"stripes")
	assert(DebugSettings.get_editor_background_preview_id() == &"stripes")
	backgrounds.selected_index = 2
	assert(backgrounds.get_selected_data().id == &"dots")
	var dots := backgrounds.get_selected_data() as BackgroundThemeData
	assert(dots.material != null)
	assert(dots.material.resource_path == "res://resources/materials/backgrounds/02_dots.tres")
	assert(dots.material.shader != null)
	var parent := Control.new()
	parent.size = Vector2(256, 320)
	root.add_child(parent)
	var layer := BackgroundLayer.new()
	parent.add_child(layer)
	var theme := ThemePaletteData.new()
	theme.bg_base_color = Color("123456")
	theme.bg_secondary_color = Color(0.8, 0.2, 0.1, 0.42)
	layer.setup(dots, theme)
	assert(layer.catalog == BackgroundThemeRegistry.catalog())
	assert(
		layer.shader_material.get_shader_parameter("dot_radius")
		== dots.material.get_shader_parameter("dot_radius")
	)
	assert(
		layer.shader_material.get_shader_parameter("dot_spacing")
		== dots.material.get_shader_parameter("dot_spacing")
	)
	layer.set_pixelated(false)
	assert(not layer._pixelated_override)
	parent.queue_free()
	assert(FONTS.get_selected_data().id == &"vcr")
	assert(PALETTES.get_selected_data().id == &"arcade")
	print("Selectable data catalog tests passed.")
	quit()
