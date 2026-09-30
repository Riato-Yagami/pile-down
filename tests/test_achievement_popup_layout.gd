extends SceneTree

const Options := preload("res://resources/scripts/settings/GameOptionsController.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(20.0).timeout.connect(func() -> void: quit(1))
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var game := main.get_node("GameCenter/Game") as GameManager
	for mode in [&"classic", &"semi_adaptive", &"adaptive", &"menu_adaptive"]:
		for pixel_art in [true, false]:
			game._screen_size_mode = mode
			game._true_pixel_art_enabled = pixel_art
			Options.apply_resolution(game)
			for window_size in [Vector2i(1600, 900), Vector2i(900, 1600)]:
				root.size = window_size
				for frame in 5:
					await process_frame
				game.achievement_popup.show()
				game._position_achievement_popup()
				await process_frame
				var popup_rect := game.achievement_popup.get_global_rect()
				var parent_rect := game.screens.get_global_rect()
				assert(absf(popup_rect.get_center().x - parent_rect.get_center().x) <= 1.0)
				assert(parent_rect.encloses(popup_rect))
	main.queue_free()
	await process_frame
	print("Achievement popup layout tests passed.")
	quit()
