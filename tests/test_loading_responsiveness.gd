extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	# Do not preload or type-reference gameplay here: this must exercise a cold
	# script load, not hide its cost in the test's own compilation.
	var loading := load("res://resources/scenes/Loading.tscn").instantiate() as Control
	var stack := loading.get_node("Stack")
	if OS.get_cmdline_user_args().has("--face-up"):
		stack.show_face_up_tiles = true
		stack.first_value = 9
		stack.animation_speed = 2.0
		stack._prepare_face_textures()
		assert(stack._face_textures.size() == 10)
		assert(stack._tile_value(0) == 9 and stack._tile_value(1) == 8 and stack._tile_value(10) == 9)
		var fitted: Vector2 = stack._fitted_tile_size()
		assert(is_equal_approx(fitted.x / fitted.y, 34.0 / 37.0))
		stack.animation_speed = 0.0
		stack._process(0.1)
		assert(is_zero_approx(stack._elapsed))
		stack.animation_speed = 2.0
		stack._process(0.1)
		assert(is_equal_approx(stack._elapsed, 0.2))
		var config := ConfigFile.new()
		stack.configure_from_progress(config)
		assert(stack.first_value == 3, "A new save starts with tile three")
		for index in 9:
			assert(stack._tile_value(index) == [3, 2, 1, 0][index % 4])
		for maximum in [3, 6, 9]:
			config.set_value("progression", "max_discovered_tile_value", maximum)
			stack.configure_from_progress(config)
			assert(stack.first_value == maximum)
			for sequence in range(-12, 50):
				assert(stack._tile_value(sequence) >= 0 and stack._tile_value(sequence) <= maximum,
					"Neither incoming tiles nor existing stack layers may reveal undiscovered values")
		stack._elapsed = 0.0
	root.add_child(loading)
	current_scene = loading
	if OS.get_cmdline_user_args().has("--close-during-load"):
		while loading._script_loader == null:
			await process_frame
		loading.queue_free()
		await process_frame
		assert(not is_instance_valid(loading))
		print("Closing during script preparation joins the worker safely.")
		quit()
		return
	if OS.get_cmdline_user_args().has("--close-during-scene-load"):
		while not loading._resource_requested:
			assert(not loading._failed)
			await process_frame
		loading.queue_free()
		await process_frame
		assert(not is_instance_valid(loading))
		print("Closing during scene loading drains the resource request safely.")
		quit()
		return
	var animated_frames := 0
	var previous_ticks := Time.get_ticks_msec()
	var worst_gap := 0
	while is_instance_valid(loading):
		var now := Time.get_ticks_msec()
		worst_gap = maxi(worst_gap, now - previous_ticks)
		previous_ticks = now
		assert(not loading._failed, "The background load must finish successfully")
		if loading._script_loader != null and loading._script_loader.is_alive():
			var phase: float = stack._elapsed
			await process_frame
			if is_instance_valid(stack) and stack._elapsed > phase:
				animated_frames += 1
		else:
			await process_frame
	assert(current_scene != null and current_scene.scene_file_path == "res://resources/scenes/Main.tscn")
	assert(animated_frames > 0, "The stack must animate while gameplay scripts load")
	print("Loading completed; animated worker frames: %d; longest frame gap: %d ms" % [animated_frames, worst_gap])
	current_scene.queue_free()
	await process_frame
	quit()
