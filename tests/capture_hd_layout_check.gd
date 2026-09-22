extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(752, 640)
	var game := GameScene.instantiate()
	root.add_child(game)
	for frame in 8:
		await process_frame
	var screens := game.get_node("Screens") as Control
	var splash := game.get_node("Screens/Splash") as Control
	var gameplay := game.get_node("Gameplay") as Control
	screens.visible = true
	splash.visible = true
	gameplay.visible = false
	for frame in 2:
		await process_frame
	print("root_size=", root.size)
	print("gameplay pos/scale/size=", gameplay.position, " ", gameplay.scale, " ", gameplay.size)
	print("screens pos/scale/size=", screens.position, " ", screens.scale, " ", screens.size)
	print("splash visible=", splash.visible)
	var image := root.get_texture().get_image()
	var output_dir := ProjectSettings.globalize_path("res://build/tmp/screenshots")
	DirAccess.make_dir_recursive_absolute(output_dir)
	image.save_png(output_dir.path_join("hd-layout-main-menu.png"))
	splash.visible = false
	gameplay.visible = false
	var challenges := game.get_node("Screens/ChallengeSelection") as ChallengeSelection
	challenges.open(
		game.challenge_manager,
		game.achievement_manager.unlocked,
		game.discovered_bonuses,
		game.beaten_special_rules,
		game.bonus_manager.active_levels()
	)
	for frame in 2:
		await process_frame
	image = root.get_texture().get_image()
	image.save_png(output_dir.path_join("hd-layout-challenges.png"))
	print("Saved layout screenshot.")
	quit()
