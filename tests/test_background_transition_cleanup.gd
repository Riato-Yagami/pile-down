extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var parent := Control.new()
	parent.size = Vector2(512, 640)
	root.add_child(parent)
	var manager := BackgroundManager.new()
	root.add_child(manager)
	manager.setup(parent, ThemePaletteRegistry.from_color_palette(
		ColorPaletteRegistry.create_all()[0]
	), true, false)
	manager._set_immediate(manager.definitions[0])
	for index in range(1, 31):
		var target := manager.definitions[index % manager.definitions.size()]
		var transition := manager.transition_to(target)
		assert(transition != null)
		assert(manager.transition_to(target) == null)
		await create_timer(0.05).timeout
		assert(parent.get_child_count() == 2, "Interrupted fades retain old layers")
	await create_timer(1.1).timeout
	assert(parent.get_child_count() == 1)
	assert(manager.previous_layer == null)
	assert(manager.current_layer.modulate.a == 1.0)
	manager.transition_to(manager.definitions[0])
	manager.skip_transition()
	await process_frame
	await process_frame
	assert(parent.get_child_count() == 1)
	manager.transition_to(manager.definitions[1])
	manager._set_immediate(manager.definitions[2])
	await process_frame
	await process_frame
	assert(parent.get_child_count() == 1)
	manager.queue_free()
	parent.queue_free()
	await process_frame
	print("Background transition cleanup tests passed.")
	quit()
