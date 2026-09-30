extends SceneTree


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(30.0).timeout.connect(func(): quit(1))
	var runtime := root.get_node("RuntimeColors")
	# Change the source values in memory, leaving serialized scenes untouched.
	var sentinel := Color(0.123, 0.456, 0.789, 0.654)
	var original_values: Dictionary = runtime._values.duplicate()
	runtime._values["MENU_BACKGROUND"] = sentinel
	runtime._values["LOADING_TEXT"] = sentinel
	var loading := preload("res://resources/scenes/Loading.tscn").instantiate()
	loading.auto_start = false
	root.add_child(loading)
	assert(loading.get_node("Background").color == sentinel)
	assert(loading.get_node("GameInfo/Title").get_theme_color("font_color") == sentinel)
	loading.queue_free()
	runtime._values["PILE_MORPH_EDGE"] = sentinel
	var pile := preload("res://resources/scenes/gameplay/Pile.tscn").instantiate()
	root.add_child(pile)
	assert(pile.face_sprite.material.get_shader_parameter("morph_edge_color") == sentinel,
		"Local-to-scene materials must use current settings without a file sync")
	runtime._values["AFTERGLOW_TILE"] = sentinel
	var glow := load("res://resources/shaders/ui/TileAfterglow.gdshader") as Shader
	runtime._configured_shaders.erase(glow.get_instance_id())
	runtime._configure_shader(glow)
	assert(glow.code.contains("vec4(%.9f, %.9f, %.9f, %.9f)" % [sentinel.r, sentinel.g, sentinel.b, sentinel.a]))
	runtime._values = original_values
	runtime._configured_shaders.erase(glow.get_instance_id())
	runtime._configure_shader(glow)
	var card := preload("res://resources/scenes/gameplay/Card.tscn").instantiate() as PlayingCard
	# Simulate an old serialized material without regenerating scene files.
	var outline := card.get_node("VisualRoot/SelectionOutline") as TextureRect
	outline.material = outline.material.duplicate()
	var selection := outline.material as ShaderMaterial
	selection.set_shader_parameter("highlight_color", GameColors.TRANSPARENT)
	selection.set_shader_parameter("rim_color", GameColors.TRANSPARENT)
	root.add_child(card)
	card.set_selected_visual(true)
	assert(card.selection_outline.visible)
	assert(selection.get_shader_parameter("highlight_color") == GameColors.SELECTION_HIGHLIGHT)
	assert(selection.get_shader_parameter("rim_color") == GameColors.SELECTION_RIM)
	var original_text_mode := GameColors.tile_text_uses_palette
	GameColors.tile_text_uses_palette = false
	card.setup(2)
	pile.setup(0, 2)
	assert(card.value_label.get_theme_color("font_color") == GameColors.TILE_TEXT)
	assert(pile.value_label.get_theme_color("font_color") == GameColors.TILE_TEXT)
	assert(card.face_sprite.material.get_shader_parameter("tile_color") == card._tile_colors[2])
	GameColors.tile_text_uses_palette = true
	card.setup(2)
	assert(card.value_label.get_theme_color("font_color") == card._tile_colors[2].darkened(GameColors.TILE_TEXT_DARKENING))
	GameColors.tile_text_uses_palette = original_text_mode
	pile.queue_free()
	card.queue_free()
	await process_frame
	# The central settings must never substitute a fixed swatch for data,
	# including when a palette contains the same color as a UI accent.
	for palette in ColorPaletteRegistry.create_all():
		var original := palette.colors.duplicate()
		var expected := palette.normalized_colors()
		var theme := ThemePaletteRegistry.from_color_palette(palette)
		assert(theme.tile_colors == expected)
		if palette.id == &"vaporwave":
			assert(theme.ui_text_color == GameColors.VAPOR_TEXT)
			assert(theme.ui_muted_text_color == GameColors.VAPOR_TEXT_MUTED)
		assert(palette.colors == original)
		theme.tile_colors[0] = GameColors.TRANSPARENT
		assert(palette.colors == original, "Derived themes must own their color array")
	var custom := ColorPaletteData.new()
	custom.colors = [GameColors.ACCENT, GameColors.DANGER]
	var normalized := custom.normalized_colors()
	assert(normalized.size() == 10)
	assert(normalized[0] == custom.colors[0] and normalized[1] == custom.colors[1])
	assert(custom.colors.size() == 2)
	var empty := ColorPaletteData.new()
	var fallback := empty.normalized_colors()
	assert(fallback == GameColors.FALLBACK_TILE_COLORS)
	fallback[0] = GameColors.TRANSPARENT
	assert(empty.normalized_colors() == GameColors.FALLBACK_TILE_COLORS)
	# BBCode uses the setting too, while translation stays independent of it.
	var game := preload("res://resources/scenes/Game.tscn").instantiate() as GameManager
	root.add_child(game)
	game.game_mode = GameManager.GameMode.CHECKPOINT
	game.checkpoint_uses_endless_progression = false
	game.round_number = 0
	await game._finish_game(true)
	assert(game.overlay_title.text.contains("[color=#%s]" % GameColors.VICTORY.to_html(false)))
	assert(game.overlay_title.text.contains(TranslationServer.translate("YOU WIN !")))
	await create_timer(0.5).timeout
	game.queue_free()
	await process_frame
	print("Central color settings preserve palette data, derived themes and fallback isolation.")
	quit()
