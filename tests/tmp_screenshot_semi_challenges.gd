extends SceneTree

const MainScene := preload("res://resources/scenes/Main.tscn")
const Options := preload("res://resources/scripts/settings/GameOptionsController.gd")

const MODES := [
	Options.SCREEN_SIZE_MODE_CLASSIC,
	Options.SCREEN_SIZE_MODE_SEMI_ADAPTIVE,
	Options.SCREEN_SIZE_MODE_ADAPTIVE,
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(752, 640)
	for mode in MODES:
		await _capture_mode(mode, true)
	await _capture_mode(Options.SCREEN_SIZE_MODE_SEMI_ADAPTIVE, false)
	quit()


func _capture_mode(mode: StringName, unlock_everything: bool) -> void:
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	var game := main.get_node("GameCenter/Game") as GameManager
	game._true_pixel_art_enabled = true
	game._screen_size_mode = mode
	Options.apply_resolution(game)
	await process_frame
	if unlock_everything and not DebugSettings.is_unlock_everything_enabled():
		DebugSettings.toggle_unlock_everything()
	elif not unlock_everything and DebugSettings.is_unlock_everything_enabled():
		DebugSettings.toggle_unlock_everything()
	game._apply_debug_unlock_everything()
	game._open_challenge_selection()
	for index in 40:
		await process_frame
	var center_x := game.challenge_selection.get_global_rect().get_center().x
	print(
		"challenge screenshot mode=", mode,
		" unlocked=", unlock_everything,
		" game=", game.get_global_rect(),
		" screens=", game.screens.get_global_rect(),
		" challenge=", game.challenge_selection.get_global_rect(),
		" center_delta=", center_x - root.size.x * 0.5
	)
	var suffix := "-locked" if not unlock_everything else ""
	var path := "res://wip/challenges-%s%s.png" % [String(mode), suffix]
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	assert(error == OK)
	print("Saved screenshot: ", path)
	main.queue_free()
	for index in 4:
		await process_frame
