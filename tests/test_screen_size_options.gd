extends SceneTree

const GameScene := preload("res://resources/scenes/Game.tscn")
const Options := preload("res://resources/scripts/settings/GameOptionsController.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GameScene.instantiate() as GameManager
	root.add_child(game)
	await process_frame
	game._show_options_page(GameManager.OPTION_GRAPHICS)
	var options_margin := game.options_menu.get_node("Margin") as MarginContainer
	assert(options_margin.get_theme_constant(&"margin_left") == 16)
	assert(options_margin.get_theme_constant(&"margin_top") == 12)
	assert(options_margin.get_theme_constant(&"margin_right") == 16)
	assert(options_margin.get_theme_constant(&"margin_bottom") == 16)
	var selector := game.adaptive_resolution_button.get_parent() as HBoxContainer
	var arrows := selector.get_node("ScreenSizeArrows") as Control
	var choices := selector.get_node("ScreenSizeModeSelector") as OptionButton
	assert(arrows.visible == false)
	assert(not game.adaptive_resolution_button.visible)
	assert(game.adaptive_resolution_button.text == "")
	assert(choices.item_count == 3)
	assert(choices.get_item_text(0) == "CLASSIC")
	assert(choices.get_item_text(1) == "SEMI ADAPTIVE")
	assert(choices.get_item_text(2) == "ADAPTIVE")
	var selector_style := choices.get_theme_stylebox("normal") as StyleBoxFlat
	assert(selector_style != null)
	assert(selector_style.get_border_width(SIDE_LEFT) == 2)
	assert(selector_style.border_color == game.OPTIONS_SELECTED_COLOR)
	assert(game.true_pixel_art_button.get_theme_constant("h_separation") == 3)
	assert(game.background_enabled_button.get_theme_constant("h_separation") == 3)
	assert(game.dust_effects_button.get_theme_constant("h_separation") == 3)
	assert(game.background_enabled_button.text == "SHOW BACKGROUND")
	assert(game.dust_effects_button.text == "BACKGROUND DEFORMATION")
	choices.item_selected.emit(0)
	assert(game._screen_size_mode == Options.SCREEN_SIZE_MODE_CLASSIC)
	assert(choices.selected == 0)
	assert(choices.get_popup().is_item_checked(0))
	assert(not choices.get_popup().is_item_checked(1))
	assert(not choices.get_popup().is_item_checked(2))
	choices.item_selected.emit(1)
	assert(game._screen_size_mode == Options.SCREEN_SIZE_MODE_SEMI_ADAPTIVE)
	assert(choices.selected == 1)
	assert(not choices.get_popup().is_item_checked(0))
	assert(choices.get_popup().is_item_checked(1))
	assert(not choices.get_popup().is_item_checked(2))
	choices.item_selected.emit(2)
	assert(game._screen_size_mode == Options.SCREEN_SIZE_MODE_ADAPTIVE)
	assert(choices.selected == 2)
	assert(not choices.get_popup().is_item_checked(0))
	assert(not choices.get_popup().is_item_checked(1))
	assert(choices.get_popup().is_item_checked(2))
	game.queue_free()
	await process_frame
	quit()
