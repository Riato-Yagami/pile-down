extends "res://tests/audit/functional_probe.gd"
## Diagnostic instrumentation only. No fixed-fps: intervals use monotonic wall time.
var phase := ""
var frames := PackedFloat64Array()
var samples: Array[Dictionary] = []
var last_tick := 0
var last_sample := 0
var seed_text := "PERF-A"
var duration := 3.0
var iterations := 20
var trace_resize := false
var resize_handler_calls: Array[Dictionary] = []
var resize_handler_depth := 0
var trace_render := false
var render_events: Array[Dictionary] = []


func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	if not phase.is_empty() and last_tick > 0:
		frames.append((now - last_tick) / 1000.0)
		if now - last_sample >= 250000:
			samples.append(snapshot())
			last_sample = now
	last_tick = now
	return false


func snapshot() -> Dictionary:
	var result := {
		"time_ms": Time.get_ticks_msec(),
		"static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"video_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"tweens": get_processed_tweens().size(),
	}
	if RenderingServer.has_method("viewport_get_measured_render_time_gpu"):
		result["render_gpu_ms"] = RenderingServer.call("viewport_get_measured_render_time_gpu", root.get_viewport_rid())
		result["render_cpu_ms"] = RenderingServer.call("viewport_get_measured_render_time_cpu", root.get_viewport_rid())
	if is_instance_valid(game):
		var layers := 0
		for node in game.background_manager.layer_parent.get_children():
			if node is BackgroundLayer: layers += 1
		result["background_layers"] = layers
	return result


func begin(label: String) -> void:
	finish()
	phase = label
	render_events.clear()
	frames = PackedFloat64Array()
	samples = [snapshot()]
	last_tick = Time.get_ticks_usec()
	last_sample = last_tick


func finish() -> void:
	if phase.is_empty(): return
	var sorted := frames.duplicate()
	sorted.sort()
	var total := 0.0
	var slow := 0
	for value in frames:
		total += value
		if value > 33.333: slow += 1
	samples.append(snapshot())
	var output := {"phase": phase, "frames": frames.size(), "intervals_ms": frames,
		"samples": samples, "seconds": total / 1000.0}
	if not sorted.is_empty():
		output.merge({"fps": frames.size() * 1000.0 / total,
			"fps_min_interval": 1000.0 / sorted[-1], "mean_ms": total / frames.size(),
			"p95_ms": sorted[int((sorted.size() - 1) * 0.95)],
			"p99_ms": sorted[int((sorted.size() - 1) * 0.99)],
			"max_ms": sorted[-1], "over_33ms": slow})
	phase = ""
	print("PERF " + JSON.stringify(output))
	if trace_render:
		print("PERF_DIAG " + JSON.stringify({"label": "render_events", "phase": output.phase, "events": render_events}))


func dwell(label: String, seconds := -1.0) -> void:
	begin(label)
	await create_timer(duration if seconds < 0 else seconds).timeout
	finish()


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("audit-profiles/"):
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	var config: Dictionary = JSON.parse_string(args[0])
	seed_text = config.get("seed", "PERF-A")
	duration = float(config.get("duration", 3.0))
	iterations = int(config.get("iterations", 20))
	trace_resize = bool(config.get("trace_resize", false))
	trace_render = bool(config.get("trace_render", false))
	if trace_render:
		process_frame.connect(_trace_render_event.bind("process_frame"))
		RenderingServer.frame_pre_draw.connect(_trace_render_event.bind("pre_draw"))
		RenderingServer.frame_post_draw.connect(_trace_render_event.bind("post_draw"))
	Engine.max_fps = int(config.get("cap", 0))
	if RenderingServer.has_method("viewport_set_measure_render_time"):
		RenderingServer.call("viewport_set_measure_render_time", root.get_viewport_rid(), true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if config.get("vsync", false) else DisplayServer.VSYNC_DISABLED)
	if config.get("scenario", "") == "resize_minimal":
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_size = Vector2i(256, 320)
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.size = Vector2i(512, 640)
		var canvas := ColorRect.new()
		canvas.color = Color(0.2, 0.3, 0.4)
		root.add_child(canvas)
		canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await create_timer(1.0).timeout
		print("PERF_META " + JSON.stringify({"engine": Engine.get_version_info(),
			"renderer": RenderingServer.get_current_rendering_method(),
			"display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
			"window": str(root.size), "content_scale_mode": root.content_scale_mode,
			"content_scale_size": str(root.content_scale_size), "content_scale_aspect": root.content_scale_aspect,
			"vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
			"debug_settings_enabled": DebugSettings.ENABLED, "config": config}))
		await dwell("resize_stable_before", 1.0)
		await resize_sequence()
		await dwell("resize_stable_after", 1.0)
		print("PERF_DONE")
		quit()
		return
	begin("boot")
	await boot()
	finish()
	if config.get("warmup", false):
		begin("render_warmup")
		await preload("res://resources/scripts/effects/RenderWarmup.gd").run(game)
		finish()
	if config.has("pixel") or config.has("screen_mode"):
		game._true_pixel_art_enabled = config.get("pixel", true)
		game._screen_size_mode = StringName(config.get("screen_mode", "adaptive"))
		GameOptionsController.apply_resolution(game)
	root.size = Vector2i(int(config.get("width", 512)), int(config.get("height", 640)))
	if config.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	await create_timer(1.0).timeout
	print("PERF_META " + JSON.stringify({"engine": Engine.get_version_info(), "debug_build": OS.is_debug_build(),
		"display": DisplayServer.get_name(), "adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "window": str(root.size),
		"viewport": str(game.get_viewport_rect().size), "content_scale_size": str(root.content_scale_size),
		"content_scale_factor": root.content_scale_factor, "cpu": OS.get_processor_name(),
		"vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
		"content_scale_mode": root.content_scale_mode, "true_pixel_art": game._true_pixel_art_enabled,
		"screen_mode": game._screen_size_mode,
		"debug_settings_enabled": DebugSettings.ENABLED,
		"processors": OS.get_processor_count(), "config": config}))
	var processing := {}
	for node in main.find_children("*", "", true, false):
		if node.is_processing() and node.get_script() != null:
			var path: String = node.get_script().resource_path
			if not processing.has(path): processing[path] = {"count": 0, "hidden": 0}
			processing[path]["count"] += 1
			if node is CanvasItem and not node.is_visible_in_tree(): processing[path]["hidden"] += 1
	print("PERF_DIAG " + JSON.stringify({"label": "menu_processing_scripts", "scripts": processing}))
	match config.get("scenario", "states"):
		"backgrounds": await backgrounds()
		"background_only": await background_only()
		"stress": await stress()
		"overlap": await overlap()
		"resize": await resize_probe()
		"ui": await ui_perf()
		"micro": await micro_perf()
		"challenge": await challenge_perf(config.get("challenge", "shared_clock"))
		"endless": await endless_perf()
		"baseline":
			await dwell("menu")
			await start_measured()
			await dwell("gameplay_idle")
		_: await states()
	finish()
	# Quit normally: freeing a live game then advancing a frame can resume
	# achievement coroutines against a deliberately destroyed host.
	print("PERF_DONE")
	quit()


func start_measured(data: ChallengeData = null, endless := false) -> void:
	begin("start")
	var before := Time.get_ticks_usec()
	game.start_game(endless, data, endless and data != null, seed_text)
	var synchronous_start_ms := (Time.get_ticks_usec() - before) / 1000.0
	var ready := await wait_ready()
	record("ready", ready, true)
	record("initial_signature", signature())
	record("initial_background", String(game.background_manager.last_background_id))
	finish()
	print("PERF_DIAG " + JSON.stringify({"label": "synchronous_start_game", "ms": synchronous_start_ms}))
	game.timer_manager.stop_countdown()


func _trace_render_event(event: String) -> void:
	if not phase.is_empty():
		render_events.append({"event": event, "us": Time.get_ticks_usec(), "frame": Engine.get_process_frames()})


func states() -> void:
	await dwell("menu")
	await start_measured()
	await dwell("gameplay_idle")
	begin("round_played")
	record("round_solved", await solve_round(), true)
	await wait_ready()
	finish()
	game.timer_manager.stop_countdown()
	game._open_quit_popup()
	await dwell("pause_popup")
	game._close_quit_popup()
	await dwell("resume", 1.0)
	begin("damage")
	await game._handle_mistake()
	finish()
	game.timer_manager.stop_countdown()
	game.bonus_manager.grant_starting_bonuses({&"redraw": 1})
	begin("reload")
	await game._on_redraw_pressed()
	await create_timer(0.8).timeout
	finish()
	game.timer_manager.stop_countdown()
	var choices: Array[BonusData] = []
	choices.assign(BonusRegistry.create_all().slice(0, 3))
	begin("flawless")
	game.bonus_selection.present(choices, [1, 1, 1], true)
	await create_timer(0.7).timeout
	finish()
	await dwell("bonus")
	game.bonus_selection.cancel()
	begin("tier_boundary_injected")
	game._apply_special_tier_relief()
	game.background_manager.transition_to_next(game.cosmetic_rng)
	await create_timer(1.2).timeout
	finish()
	begin("game_over_injected")
	await game._finish_game()
	await create_timer(0.7).timeout
	finish()
	begin("restart")
	await game._restart_current_mode()
	await wait_ready()
	finish()
	game.timer_manager.stop_countdown()
	begin("return_menu")
	var before_return := Time.get_ticks_usec()
	game._return_to_menu()
	var synchronous_return_ms := (Time.get_ticks_usec() - before_return) / 1000.0
	while game._screen_transition_active:
		await process_frame
	finish()
	print("PERF_DIAG " + JSON.stringify({"label": "synchronous_return_menu", "ms": synchronous_return_ms}))
	await dwell("menu_after")


func backgrounds() -> void:
	await start_measured()
	game.gameplay_layer.hide()
	game.back_button.hide()
	game.run_time_label.hide()
	game.background_manager.set_enabled(false)
	await dwell("background_disabled")
	game.background_manager.set_enabled(true)
	for data in game.background_manager.definitions:
		begin("transition_" + String(data.id))
		game.background_manager.transition_to(data)
		await create_timer(1.1).timeout
		finish()
		await dwell("background_" + String(data.id))
	begin("palette_changes_30")
	for index in 30:
		game.theme_manager.set_active_theme(game.theme_manager.definitions[index % game.theme_manager.definitions.size()].id)
		await process_frame
	finish()


func background_only() -> void:
	main.queue_free()
	await process_frame
	await process_frame
	var parent := Control.new()
	root.add_child(parent)
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await dwell("empty_renderer")
	for data in BackgroundThemeRegistry.create_all():
		begin("first_background_" + String(data.id))
		var layer := BackgroundLayer.new()
		parent.add_child(layer)
		layer.setup(data, null)
		await create_timer(0.7).timeout
		finish()
		await dwell("isolated_background_" + String(data.id))
		layer.queue_free()
		await process_frame
	parent.queue_free()


func stress() -> void:
	await start_measured()
	await dwell("stress_baseline", 1.0)
	for index in iterations:
		begin("restart_%03d" % index)
		await game._restart_current_mode()
		await wait_ready()
		game.timer_manager.stop_countdown()
		for popup in 5:
			game._open_quit_popup()
			await process_frame
			game._close_quit_popup()
		game.background_manager.transition_to_next(game.cosmetic_rng)
		await create_timer(1.1).timeout
		finish()
		if index % 5 == 4:
			begin("menu_cycle_%03d" % index)
			await game._return_to_menu()
			finish()
			await start_measured()
	await dwell("stress_settled", 3.0)


func overlap() -> void:
	await start_measured()
	await dwell("overlap_before", 1.0)
	for index in iterations:
		game.background_manager.transition_to(game.background_manager.definitions[index % 8])
		await create_timer(0.05).timeout
	await dwell("overlap_settled", 2.0)
	var retained: Array[Dictionary] = []
	for node in game.background_manager.layer_parent.get_children():
		if node is BackgroundLayer:
			retained.append({"name": node.name, "alpha": node.modulate.a, "visible": node.visible})
	record("retained_layers", retained)
	await game._return_to_menu()
	await start_measured()
	await dwell("overlap_after_new_run", 1.0)


func resize_probe() -> void:
	await start_measured()
	await dwell("resize_stable_before", 1.0)
	if trace_resize:
		# Separate diagnostic runs: replacing a connection changes callback order.
		game.get_viewport().size_changed.disconnect(game._resize_dust_distribution)
		game.item_rect_changed.disconnect(game._resize_dust_distribution)
		game.get_viewport().size_changed.connect(_trace_resize_handler.bind("viewport"))
		game.item_rect_changed.connect(_trace_resize_handler.bind("item_rect"))
	await resize_sequence()
	if trace_resize:
		game.get_viewport().size_changed.disconnect(_trace_resize_handler.bind("viewport"))
		game.item_rect_changed.disconnect(_trace_resize_handler.bind("item_rect"))
		game.get_viewport().size_changed.connect(game._resize_dust_distribution)
		game.item_rect_changed.connect(game._resize_dust_distribution)
		print("PERF_DIAG " + JSON.stringify({"label": "resize_handler_calls", "calls": resize_handler_calls}))
	await dwell("resize_stable_after", 1.0)


func _trace_resize_handler(source: String) -> void:
	var depth := resize_handler_depth
	resize_handler_depth += 1
	var before := Time.get_ticks_usec()
	game._resize_dust_distribution()
	var elapsed_ms := (Time.get_ticks_usec() - before) / 1000.0
	resize_handler_depth -= 1
	resize_handler_calls.append({"source": source, "depth": depth, "ms": elapsed_ms,
		"frame": Engine.get_process_frames()})


func resize_sequence() -> void:
	var set_size_ms: Array[float] = []
	var actual_sizes: Array[String] = []
	begin("resize_continuous")
	for index in 180:
		var before := Time.get_ticks_usec()
		root.size = Vector2i(512 + index % 60 * 16, 640 + index % 40 * 8)
		set_size_ms.append((Time.get_ticks_usec() - before) / 1000.0)
		await process_frame
		actual_sizes.append(str(root.size))
	finish()
	print("PERF_DIAG " + JSON.stringify({"label": "resize_set_size",
		"total_ms": set_size_ms, "actual_sizes": actual_sizes}))


func challenge_perf(id: String) -> void:
	await start_measured(challenge(id))
	await dwell("challenge_idle_" + id)
	begin("challenge_round_" + id)
	record("round_solved", await solve_round(), true)
	finish()


func endless_perf() -> void:
	await start_measured(null, true)
	for index in iterations:
		begin("endless_round_%03d" % index)
		record("round_solved", await solve_round(), true)
		while game.bonus_selection.visible:
			if game.bonus_selection.skip_button.visible: game.bonus_selection._skip()
			await process_frame
		await wait_ready()
		game.timer_manager.stop_countdown()
		finish()
	await dwell("endless_settled")


func ui_perf() -> void:
	await dwell("menu")
	begin("open_progression")
	game._open_progression_menu()
	await create_timer(0.7).timeout
	finish()
	await dwell("progression")
	game.progression_menu.close()
	await create_timer(0.7).timeout
	begin("open_options")
	game._open_options_menu()
	await create_timer(0.7).timeout
	finish()
	await dwell("options")
	await game._close_options_menu()


func micro_perf() -> void:
	await start_measured()
	for label in ["tile_weights_500", "sfx_20", "save_30", "music_load"]:
		var timings: Array[float] = []
		for repeat in 3:
			var before := Time.get_ticks_usec()
			match label:
				"tile_weights_500":
					for index in 500: game._update_tile_background_weight()
				"sfx_20":
					for index in 20: game.soft_audio.play_tone(610.0)
				"save_30":
					for index in 30: game._save_high_score()
				"music_load":
					var music := load("res://resources/audio/musics/section-2.wav")
					record("music_loaded", music != null, true)
			timings.append((Time.get_ticks_usec() - before) / 1000.0)
			await create_timer(0.4).timeout
		print("PERF_DIAG " + JSON.stringify({"label": label, "total_ms": timings}))
