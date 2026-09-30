extends Node

const CHOICES := ["en", "fr"]
var preference := "en"
signal language_changed


func _enter_tree() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://resources/data/localization/fr.json"
	))
	var translation := Translation.new()
	translation.locale = "fr"
	for source: String in catalog:
		translation.add_message(source, str(catalog[source]))
	TranslationServer.add_translation(translation)
	var config := SaveConfig.load_current()
	var saved := str(config.get_value("interface", "language", ""))
	var detected := OS.get_locale_language()
	var previous_detection := str(config.get_value("interface", "detected_language", ""))
	var was_supported := bool(config.get_value("interface", "detected_language_supported", false))
	# Retry detection when a formerly unavailable system language is added.
	if not CHOICES.has(saved) or (previous_detection == detected and not was_supported and CHOICES.has(detected)):
		saved = detected if CHOICES.has(detected) else "en"
	config.set_value("interface", "language", saved)
	config.set_value("interface", "detected_language", detected)
	config.set_value("interface", "detected_language_supported", CHOICES.has(detected))
	config.save(SaveConfig.PATH)
	apply_language(saved, false)


func apply_language(value: String, save := true) -> void:
	preference = value if CHOICES.has(value) else "en"
	TranslationServer.set_locale(preference)
	language_changed.emit()
	if save:
		var config := SaveConfig.load_current()
		config.set_value("interface", "language", preference)
		config.save(SaveConfig.PATH)


func setup_options(game: Node) -> void:
	var label := Label.new()
	label.text = "LANGUAGE"
	game.gameplay_options.add_child(label)
	var selector := OptionButton.new()
	selector.name = "LanguageSelector"
	game.gameplay_options.add_child(selector)
	game.GameOptionsControllerScript.ScreenSizeOptionsScript._style_screen_size_selector(game, selector)
	selector.add_item("ENGLISH")
	selector.add_item("FRANÇAIS")
	selector.select(CHOICES.find(preference))
	selector.item_selected.connect(func(index: int): apply_language(CHOICES[index]))
	language_changed.connect(func():
		game._refresh_high_score()
		game._refresh_checkpoint_button()
		game.bonus_manager._refresh_bar()
	)
