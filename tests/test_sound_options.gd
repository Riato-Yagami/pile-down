extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	game._show_options_page(GameManager.OPTION_SOUND)
	await process_frame
	var music_row := game.music_volume_slider.get_parent() as HBoxContainer
	var sound_row := game.sound_volume_slider.get_parent() as HBoxContainer
	var music_label := music_row.get_child(0) as Label
	var sound_label := sound_row.get_child(0) as Label
	var music_margin := music_row.get_node("RightMargin") as Control
	var sound_margin := sound_row.get_node("RightMargin") as Control
	assert(music_label.get_theme_color("font_color") == game.OPTION_TEXT_COLOR)
	assert(sound_label.get_theme_color("font_color") == game.OPTION_TEXT_COLOR)
	assert(music_margin.custom_minimum_size.x == 8.0)
	assert(sound_margin.custom_minimum_size.x == 8.0)
	assert(
		game.music_volume_slider.get_global_rect().end.x
		<= music_row.get_global_rect().end.x - 8.0
	)
	assert(
		game.sound_volume_slider.get_global_rect().end.x
		<= sound_row.get_global_rect().end.x - 8.0
	)
	game.music_volume_slider.grab_focus()
	await process_frame
	assert(music_label.get_theme_color("font_color") == game.OPTIONS_SELECTED_COLOR)
	assert(sound_label.get_theme_color("font_color") == game.OPTION_TEXT_COLOR)
	game.sound_volume_slider.grab_focus()
	await process_frame
	assert(music_label.get_theme_color("font_color") == game.OPTION_TEXT_COLOR)
	assert(sound_label.get_theme_color("font_color") == game.OPTIONS_SELECTED_COLOR)
	game.queue_free()
	await process_frame
	print("Sound options tests passed.")
	quit()
