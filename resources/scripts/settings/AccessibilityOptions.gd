class_name AccessibilityOptions
extends RefCounted


static func setup(game: GameManager) -> void:
	var config := SaveConfig.load_current()
	game._click_to_place_enabled = bool(config.get_value("accessibility", "click_to_place", true))
	game._drag_and_drop_enabled = bool(config.get_value("accessibility", "drag_and_drop", true))
	if not game._click_to_place_enabled and not game._drag_and_drop_enabled:
		game._click_to_place_enabled = true
	game.click_to_place_button.pressed.connect(toggle.bind(game, true))
	game.drag_and_drop_button.pressed.connect(toggle.bind(game, false))
	refresh(game)


static func toggle(game: GameManager, click_option: bool) -> void:
	if click_option:
		game._click_to_place_enabled = not game._click_to_place_enabled
		if not game._click_to_place_enabled:
			game._drag_and_drop_enabled = true
	else:
		game._drag_and_drop_enabled = not game._drag_and_drop_enabled
		if not game._drag_and_drop_enabled:
			game._click_to_place_enabled = true
	var config := SaveConfig.load_current()
	config.set_value("accessibility", "click_to_place", game._click_to_place_enabled)
	config.set_value("accessibility", "drag_and_drop", game._drag_and_drop_enabled)
	config.save(game.AUDIO_CONFIG_PATH)
	refresh(game)


static func refresh(game: GameManager) -> void:
	game.click_to_place_button.icon = game.SELECTED_TEXTURE if game._click_to_place_enabled else game.UNCHECKED_TEXTURE
	game.drag_and_drop_button.icon = game.SELECTED_TEXTURE if game._drag_and_drop_enabled else game.UNCHECKED_TEXTURE
