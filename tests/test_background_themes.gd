extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := BackgroundThemeRegistry.catalog()
	assert(catalog != null)
	assert(catalog.supports_morph)
	var selected_before := catalog.get_selected_data()
	catalog.next_background_preview()
	assert(catalog.get_selected_data() != selected_before)
	var backgrounds := BackgroundThemeRegistry.create_all()
	assert(backgrounds.size() == 8)
	assert(BackgroundThemeRegistry.find(&"stripes") != null)
	assert(BackgroundThemeRegistry.find(&"grid") != null)
	assert(BackgroundThemeRegistry.find(&"dots") != null)
	assert(BackgroundThemeRegistry.find(&"brick") != null)
	assert(BackgroundThemeRegistry.find(&"checkered") != null)
	assert(BackgroundThemeRegistry.find(&"circles") != null)
	assert(not _has_property(backgrounds[0], &"pixel_size"))
	assert(not _has_property(backgrounds[0], &"supports_morph"))

	var clean := RunRNG.new()
	var cosmetic_consumed := RunRNG.new()
	clean.initialize(987654321, "987654321")
	cosmetic_consumed.initialize(987654321, "987654321")
	var manager := BackgroundManager.new()
	for index in 16:
		var picked := manager._pick(cosmetic_consumed.get_stream(&"cosmetic"))
		assert(picked != null)
		manager.last_background_id = picked.id
	for stream_id in [&"difficulty", &"hands", &"bonuses", &"special_rules"]:
		for index in 16:
			assert(
				clean.get_stream(stream_id).randi()
				== cosmetic_consumed.get_stream(stream_id).randi()
			)

	var repeated := BackgroundThemeRegistry.find(&"stripes")
	manager.last_background_id = repeated.id
	assert(manager._weight_for(repeated) < repeated.weight)

	var parent := Control.new()
	parent.name = "BackgroundParent"
	parent.size = Vector2(512, 640)
	var copy := BackBufferCopy.new()
	copy.name = "BackgroundCopy"
	parent.add_child(copy)
	root.add_child(parent)
	manager.setup(parent, ThemePaletteRegistry.from_color_palette(
		ColorPaletteRegistry.create_all()[0]
	), true, false)
	manager._set_immediate(BackgroundThemeRegistry.find(&"stripes"))
	await process_frame
	assert(manager.current_layer != null)
	assert(manager.current_layer.size == parent.size)
	assert(manager.current_layer.shader_material != null)
	assert(not _has_property(
		manager.current_layer.shader_material,
		&"shader_parameter/viewport_size"
	))
	assert(not _has_property(
		manager.current_layer.shader_material,
		&"shader_parameter/background_viewport_size"
	))
	assert(_has_property(manager.current_layer.shader_material, &"shader_parameter/speed"))
	assert(_has_property(
		manager.current_layer.shader_material,
		&"shader_parameter/transition_t"
	))
	parent.queue_free()
	await process_frame
	manager.free()
	backgrounds.clear()
	repeated = null
	print("Background theme tests passed.")
	quit()


func _has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if property.name == property_name:
			return true
	return false
