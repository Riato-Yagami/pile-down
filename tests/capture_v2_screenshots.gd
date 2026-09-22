extends SceneTree

const OUTPUT := "res://publishing/screenshots/2.0"

var capture_size := Vector2i(1080, 1920)
var capture_mode := "android"
var game: GameManager


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if OS.get_cmdline_user_args().has("classic"):
		capture_mode = "classic"
		capture_size = Vector2i(1280, 1600)
	elif OS.get_cmdline_user_args().has("tablet-7"):
		capture_mode = "tablet-7"
		capture_size = Vector2i(1440, 2560)
	elif OS.get_cmdline_user_args().has("tablet-10"):
		capture_mode = "tablet-10"
		capture_size = Vector2i(1800, 3200)
	root.size = capture_size
	root.gui_embed_subwindows = true
	AudioServer.set_bus_mute(0, true)
	assert(not DebugSettings.ENABLED, "Publishing captures must not show debug mode")
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT.path_join(capture_mode))
	)
	var main := preload("res://resources/scenes/Main.tscn").instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout
	game = main.get_node("GameCenter/Game") as GameManager
	game._global_timer_enabled = false
	GameOptionsController.refresh_gameplay(game)
	ScreenSizeOptions.set_screen_size_mode(game, 0 if capture_mode == "classic" else 2)
	await create_timer(0.5).timeout
	await _capture("07-home")
	game.start_game(false, null, false, "PILE-DOWN-2.0", {}, [], {
		"pile_count": 4, "hand_size": 3, "start_value": 6, "turn_time": 5.0,
	})
	await create_timer(3.0).timeout
	game.timer_manager.stop_countdown()
	await _capture("01-gameplay")
	var choices: Array[BonusData] = []
	for bonus in BonusRegistry.create_all():
		if bonus.id in [&"quick_peek", &"wild_card", &"time_bank"]:
			choices.append(bonus)
	game.bonus_manager.selection.present(choices, [1, 1, 1])
	await create_timer(0.8).timeout
	await _capture("02-bonus-choice")
	game.bonus_manager.selection.hide()
	var rules: Array[SpecialRuleData] = []
	for rule in SpecialRuleRegistry.create_all_rules():
		if rule.id in [&"floor_is_lava", &"hot_potatoes"]:
			rules.append(rule)
	game.special_rule_manager.announcement.show_rules(rules)
	await create_timer(0.8).timeout
	await _capture("03-special-rules")
	game.special_rule_manager.announcement.hide()
	game._return_to_menu()
	await create_timer(1.5).timeout
	# A separate capture profile showcases existing unlockable content.
	for achievement in game.achievement_manager.definitions:
		if not game.achievement_manager.unlocked.has(achievement.id):
			game.achievement_manager.unlocked.append(achievement.id)
	for font in game.font_manager.definitions:
		if not game.font_manager.unlocked.has(font.id):
			game.font_manager.unlocked.append(font.id)
	for palette in game.palette_manager.definitions:
		if not game.palette_manager.unlocked.has(palette.id):
			game.palette_manager.unlocked.append(palette.id)
	game._open_challenge_selection()
	await create_timer(1.0).timeout
	await _capture("04-challenges")
	game._on_challenge_selection_closed()
	await create_timer(1.0).timeout
	game._open_progression_menu()
	game.progression_menu._show_page(ProgressionMenu.Page.ACHIEVEMENTS)
	await create_timer(1.0).timeout
	await _capture("05-achievements")
	game.progression_menu._show_page(ProgressionMenu.Page.FONTS)
	await create_timer(0.8).timeout
	await _capture("06-customization")
	game._on_progression_menu_closed()
	await create_timer(1.0).timeout
	game.start_game(false, null, false, "PILE-DOWN-2.0-BONUS", {
		&"open_book": 3, &"wild_card": 3,
	}, [], {"pile_count": 4, "hand_size": 4, "start_value": 9, "turn_time": 5.0})
	await create_timer(3.0).timeout
	game.timer_manager.stop_countdown()
	await _capture("08-gameplay-bonuses")
	print("V2 screenshots complete")
	quit()


func _capture(file_name: String) -> void:
	var is_gameplay := file_name.contains("gameplay")
	if OS.get_cmdline_user_args().has("bonus-only") and file_name != "08-gameplay-bonuses":
		return
	if OS.get_cmdline_user_args().has("gameplay-only") and not is_gameplay:
		return
	var previous_background: BackgroundThemeData
	if is_gameplay:
		previous_background = game.background_manager.current_layer.data
		var background_id := &"dots" if file_name == "08-gameplay-bonuses" else &"stripes"
		game.background_manager._set_immediate(BackgroundThemeRegistry.find(background_id))
		await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	assert(not game.run_time_label.visible, "Global timer must stay hidden")
	assert(game._screen_size_mode == (&"classic" if capture_mode == "classic" else &"adaptive"))
	assert(capture.get_size() == capture_size, "Unexpected capture resolution")
	capture.convert(Image.FORMAT_RGB8)
	assert(capture.save_png(OUTPUT.path_join(capture_mode).path_join(file_name + ".png")) == OK)
	print("Captured ", file_name, " ", capture.get_size())
	if is_gameplay:
		game.background_manager._set_immediate(previous_background)
