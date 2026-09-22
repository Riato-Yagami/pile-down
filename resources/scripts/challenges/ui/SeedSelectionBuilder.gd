class_name SeedSelectionBuilder
extends RefCounted

## Seed controls, unlock selections and difficulty bounds.
## State and signal bindings stay on the scene node to preserve coroutine ordering.


static func build_seed_controls(host: ChallengeSelection) -> void:
	if is_instance_valid(host._seed_input):
		return
	var section := VBoxContainer.new()
	section.name = "PlayASeed"
	section.add_theme_constant_override("separation", 4)
	var seed_caption := Label.new()
	seed_caption.text = "SEED"
	host._style_entry_heading(seed_caption, true)
	section.add_child(seed_caption)
	host._seed_input = LineEdit.new()
	host._seed_input.placeholder_text = "PILE-DOWN"
	host._seed_input.max_length = 80
	host._style_seed_input(host._seed_input)
	section.add_child(host._seed_input)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	var play := host.REGION_BUTTON_SCENE.instantiate() as RegionButton
	play.text = "PLAY"
	play.custom_minimum_size = Vector2(70, 31)
	play.add_theme_font_size_override("font_size", 16)
	if host.entry_heading_font != null:
		play.add_theme_font_override("font", host.entry_heading_font)
	play.highlight_material = host.challenges_tab_button.highlight_material
	play.pressed.connect(host._play_seed)
	var random_seed := host.REGION_BUTTON_SCENE.instantiate() as RegionButton
	random_seed.text = "RANDOM SEED"
	random_seed.custom_minimum_size = Vector2(112, 31)
	random_seed.add_theme_font_size_override("font_size", 16)
	if host.entry_heading_font != null:
		random_seed.add_theme_font_override("font", host.entry_heading_font)
	random_seed.highlight_material = host.challenges_tab_button.highlight_material
	random_seed.pressed.connect(host._fill_random_seed)
	actions.add_child(play)
	actions.add_child(random_seed)
	section.add_child(actions)
	var mode_caption := Label.new()
	mode_caption.text = "MODE"
	host._style_entry_heading(mode_caption, true)
	section.add_child(mode_caption)
	host._seed_mode = OptionButton.new()
	host._style_seed_selector(host._seed_mode)
	host._seed_mode.item_selected.connect(host._refresh_seed_endless_selection)
	section.add_child(host._seed_mode)
	host._seed_endless = host.SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
	host._seed_endless.text = "ENDLESS"
	host._style_seed_check(host._seed_endless)
	section.add_child(host._seed_endless)
	var difficulty_caption := Label.new()
	difficulty_caption.text = "DIFFICULTY"
	host._style_entry_heading(difficulty_caption, true)
	section.add_child(difficulty_caption)
	host._seed_piles = host._create_value_selector(
		section, "PILES", host.DifficultySettings.START_PILES,
		host.SEEDED_MAX_PILES, host.DifficultySettings.START_PILES
	)
	host._seed_hand = host._create_value_selector(
		section, "HAND", host.DifficultySettings.START_HAND_SIZE,
		host.DifficultySettings.MAX_HAND_SIZE, host.DifficultySettings.START_HAND_SIZE
	)
	host._seed_value = host._create_value_selector(
		section, "VALUE", host.SEEDED_MIN_CARD_VALUE,
		host.DifficultySettings.MAX_CARD_VALUE, host.DifficultySettings.START_CARD_VALUE
	)
	host._seed_timer = host._create_value_selector(
		section, "TIMER", int(host.DifficultySettings.MIN_TURN_TIME),
		int(host.DifficultySettings.START_TURN_TIME),
		int(host.DifficultySettings.START_TURN_TIME)
	)
	host.seed_content.add_child(section)
	host._build_unlock_selection(section)


static func build_unlock_selection(host: ChallengeSelection, section: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "MODIFICATION"
	host._style_entry_heading(title, true)
	section.add_child(title)
	var bonuses := VBoxContainer.new()
	bonuses.name = "BonusChoices"
	bonuses.add_theme_constant_override("separation", 3)
	section.add_child(bonuses)
	var rules := VBoxContainer.new()
	rules.name = "RuleChoices"
	rules.add_theme_constant_override("separation", 3)
	section.add_child(rules)


static func refresh_unlock_selection(host: ChallengeSelection) -> void:
	var bonuses := host.seed_content.get_node("PlayASeed/BonusChoices") as VBoxContainer
	var rules := host.seed_content.get_node("PlayASeed/RuleChoices") as VBoxContainer
	host._clear_children(bonuses)
	host._clear_children(rules)
	host._selected_bonus_ids = host._selected_bonus_ids.filter(
		func(id: StringName) -> bool: return host._unlocked_bonus_ids.has(id)
	)
	for id in host._selected_bonus_levels.keys():
		if not host._unlocked_bonus_ids.has(StringName(id)):
			host._selected_bonus_levels.erase(id)
	host._selected_rule_ids = host._selected_rule_ids.filter(
		func(id: StringName) -> bool: return host._unlocked_rule_ids.has(id)
	)
	var available_bonuses: Array[BonusData] = []
	for data in BonusRegistry.create_all():
		if host._unlocked_bonus_ids.has(data.id):
			available_bonuses.append(data)
	var available_rules: Array[SpecialRuleData] = []
	for data in SpecialRuleRegistry.create_all_rules():
		if host._unlocked_rule_ids.has(data.id):
			available_rules.append(data)
	if available_bonuses.is_empty():
		host._add_empty_selection_label(bonuses)
	else:
		host._add_seed_bonus_menu(bonuses, available_bonuses)
	if available_rules.is_empty():
		host._add_empty_selection_label(rules)
	else:
		host._add_seed_rule_menu(rules, available_rules)


static func clear_children(host: ChallengeSelection, container: Control) -> void:
	host.PixelUiScript.queue_free_children(container)


static func add_seed_bonus_menu(
	host: ChallengeSelection,
	container: VBoxContainer, definitions: Array[BonusData]
) -> void:
	var menu := host._create_multi_select_button()
	var popup_content := VBoxContainer.new()
	popup_content.add_theme_constant_override("separation", 4)
	for data in definitions:
		var unlocked_level := clampi(
			int(host._unlocked_bonus_levels.get(data.id, 1)), 1, data.max_level
		)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 29)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 2)
		var activation := host.SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
		activation.text = data.title
		activation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		host._style_multi_check(activation)
		row.add_child(activation)
		var level_buttons: Array[Button] = []
		if data.max_level > 1:
			for level in range(1, unlocked_level + 1):
				var level_button := (
					host.SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
				)
				level_button.text = host._roman_level(level)
				level_button.custom_minimum_size = Vector2(32, 29)
				level_button.fit_select_zone_to_content = false
				level_button.size_flags_horizontal = Control.SIZE_SHRINK_END
				level_button.tooltip_text = ""
				host._style_multi_check(level_button)
				level_buttons.append(level_button)
				row.add_child(level_button)
		activation.toggled.connect(
			host._on_seed_bonus_check.bind(data.id, 0, activation, level_buttons, menu)
		)
		for level_index in level_buttons.size():
			level_buttons[level_index].toggled.connect(
				host._on_seed_bonus_check.bind(
					data.id, level_index + 1, activation, level_buttons, menu
				)
			)
		host._refresh_seed_bonus_checks(data.id, activation, level_buttons)
		popup_content.add_child(row)
	var popup := host._attach_multi_select_popup(menu, popup_content)
	menu.pressed.connect(host._show_multi_select_popup.bind(menu, popup))
	host._refresh_seed_menu_text(menu, "BONUSES", host._selected_bonus_levels.size())
	container.add_child(menu)


static func on_seed_bonus_check(
	host: ChallengeSelection,
	pressed: bool, id: StringName, level: int, activation: Button,
	level_buttons: Array[Button], menu: Button
) -> void:
	if level == 0:
		if pressed:
			host._selected_bonus_levels[id] = maxi(
				int(host._selected_bonus_levels.get(id, 0)), 1
			)
			if not host._selected_bonus_ids.has(id):
				host._selected_bonus_ids.append(id)
		else:
			host._selected_bonus_levels.erase(id)
			host._selected_bonus_ids.erase(id)
	elif pressed:
		host._selected_bonus_levels[id] = level
		if not host._selected_bonus_ids.has(id):
			host._selected_bonus_ids.append(id)
	elif int(host._selected_bonus_levels.get(id, 0)) == level:
		host._selected_bonus_levels.erase(id)
		host._selected_bonus_ids.erase(id)
	host._refresh_seed_bonus_checks(id, activation, level_buttons)
	host._refresh_seed_menu_text(menu, "BONUSES", host._selected_bonus_levels.size())


static func refresh_seed_bonus_checks(
	host: ChallengeSelection,
	id: StringName, activation: Button, level_buttons: Array[Button]
) -> void:
	var selected_level := int(host._selected_bonus_levels.get(id, 0))
	activation.set_pressed_no_signal(selected_level > 0)
	for index in level_buttons.size():
		level_buttons[index].set_pressed_no_signal(selected_level == index + 1)


static func add_seed_rule_menu(
	host: ChallengeSelection,
	container: VBoxContainer, definitions: Array[SpecialRuleData]
) -> void:
	var menu := host._create_multi_select_button()
	var popup_content := VBoxContainer.new()
	popup_content.add_theme_constant_override("separation", 4)
	for data in definitions:
		var check := host.SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
		check.custom_minimum_size = Vector2(0, 27)
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.text = data.title
		check.button_pressed = host._selected_rule_ids.has(data.id)
		host._style_multi_check(check)
		check.toggled.connect(host._on_seed_rule_check.bind(data.id, menu))
		popup_content.add_child(check)
	var popup := host._attach_multi_select_popup(menu, popup_content)
	menu.pressed.connect(host._show_multi_select_popup.bind(menu, popup))
	host._refresh_seed_menu_text(menu, "RULES", host._selected_rule_ids.size())
	container.add_child(menu)


static func on_seed_rule_check(
	host: ChallengeSelection, checked: bool, id: StringName, menu: Button
) -> void:
	if checked:
		host._selected_rule_ids.append(id)
	else:
		host._selected_rule_ids.erase(id)
	host._refresh_seed_menu_text(menu, "RULES", host._selected_rule_ids.size())


static func refresh_seed_menu_text(
	host: ChallengeSelection, menu: Button, title: String, count: int
) -> void:
	menu.text = title if count == 0 else "%s  ·  %d" % [title, count]


static func roman_level(host: ChallengeSelection, level: int) -> String:
	match level:
		1:
			return "I"
		2:
			return "II"
		3:
			return "III"
		_:
			return str(level)


static func add_empty_selection_label(host: ChallengeSelection, container: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "NONE UNLOCKED"
	host._style_entry_details(label)
	container.add_child(label)


static func refresh_seed_modes(host: ChallengeSelection) -> void:
	host._seed_mode.clear()
	host._seed_mode_ids.clear()
	host._seed_mode_endless.clear()
	host._seed_mode.add_item("CLASSIC")
	host._seed_mode_ids.append(&"")
	host._seed_mode_endless.append(true)
	for data in host._manager.definitions:
		if not host._manager.is_unlocked(data, host._achievements):
			continue
		host._seed_mode.add_item(data.title)
		host._seed_mode_ids.append(data.id)
		host._seed_mode_endless.append(data.allow_endless and host._manager.completed.has(data.id))
	host._refresh_seed_endless_selection()


static func fill_random_seed(host: ChallengeSelection) -> void:
	host._seed_input.text = str(RunRNG.generate_run_seed())


static func play_seed(host: ChallengeSelection) -> void:
	var seed_text := host._seed_input.text.strip_edges()
	if seed_text.is_empty():
		host._fill_random_seed()
		seed_text = host._seed_input.text
	var selected := host._seed_mode.selected
	if selected < 0 or selected >= host._seed_mode_ids.size():
		return
	host.seeded_run_requested.emit(
		seed_text, host._seed_mode_ids[selected],
		host._selected_bonus_levels.duplicate(), host._selected_rule_ids,
		host._seed_endless.button_pressed,
		host._seed_difficulty_overrides()
	)


static func create_value_selector(
	host: ChallengeSelection,
	container: VBoxContainer, label: String, first: int, last: int, default_value: int
) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	var arrows := HBoxContainer.new()
	arrows.add_theme_constant_override("separation", 0)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(0, 20)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_override("font", host.ENTRY_FONT)
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", host.SELECTED_COLOR)
	host._configure_value_selector(value_label, label, first, last, default_value)
	var up := host._create_value_arrow(host.ARROW_UP_TEXTURE)
	var down := host._create_value_arrow(host.ARROW_DOWN_TEXTURE)
	up.pressed.connect(host._step_value_selector.bind(value_label, 1))
	down.pressed.connect(host._step_value_selector.bind(value_label, -1))
	arrows.add_child(up)
	arrows.add_child(down)
	row.add_child(arrows)
	row.add_child(value_label)
	container.add_child(row)
	return value_label


static func configure_value_selector(
	host: ChallengeSelection,
	value_label: Label, label: String, first: int, last: int, default_value: int
) -> void:
	value_label.set_meta("label", label)
	value_label.set_meta("min_value", first)
	value_label.set_meta("max_value", maxi(first, last))
	value_label.set_meta("value", clampi(default_value, first, maxi(first, last)))
	host._refresh_value_selector_text(value_label)


static func create_value_arrow(
	host: ChallengeSelection, texture: Texture2D
) -> TextureHighlightButton:
	var arrow := TextureHighlightButton.new()
	arrow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arrow.custom_minimum_size = Vector2(14, 20)
	arrow.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	arrow.texture_normal = texture
	arrow.ignore_texture_size = true
	arrow.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	arrow.highlight_material = host.challenges_tab_button.highlight_material
	return arrow


static func step_value_selector(
	host: ChallengeSelection, value_label: Label, direction: int
) -> void:
	var value := int(value_label.get_meta("value", 0))
	var min_value := int(value_label.get_meta("min_value", value))
	var max_value := int(value_label.get_meta("max_value", value))
	value_label.set_meta("value", wrapi(value + direction, min_value, max_value + 1))
	host._refresh_value_selector_text(value_label)


static func refresh_value_selector_text(host: ChallengeSelection, value_label: Label) -> void:
	var label := String(value_label.get_meta("label", ""))
	var value := int(value_label.get_meta("value", 0))
	var min_value := int(value_label.get_meta("min_value", value))
	var max_value := int(value_label.get_meta("max_value", value))
	if label == "TIMER":
		value_label.text = "Timer : %ds" % value
	else:
		value_label.text = "%s : %d/%d" % [label.capitalize(), value, max_value]


static func refresh_seed_endless_selection(host: ChallengeSelection, _index := -1) -> void:
	if host._seed_endless == null:
		return
	if host._seed_mode_endless.is_empty():
		host._seed_endless.disabled = true
		host._seed_endless.set_pressed_no_signal(false)
		return
	var mode_index := clampi(host._seed_mode.selected, 0, host._seed_mode_endless.size() - 1)
	var can_endless := bool(host._seed_mode_endless[mode_index])
	host._seed_endless.disabled = not can_endless
	if not can_endless:
		host._seed_endless.set_pressed_no_signal(false)


static func refresh_seed_difficulty_limits(host: ChallengeSelection) -> void:
	if host._seed_piles == null:
		return
	host._configure_value_selector(
		host._seed_piles, "PILES",
		host.DifficultySettings.START_PILES,
		int(host._seed_difficulty_limits.get("max_pile_count", host.DifficultySettings.START_PILES)),
		host.DifficultySettings.START_PILES
	)
	host._configure_value_selector(
		host._seed_hand, "HAND",
		host.DifficultySettings.START_HAND_SIZE,
		int(host._seed_difficulty_limits.get("max_hand_size", host.DifficultySettings.START_HAND_SIZE)),
		host.DifficultySettings.START_HAND_SIZE
	)
	host._configure_value_selector(
		host._seed_value, "VALUE",
		host.SEEDED_MIN_CARD_VALUE,
		int(host._seed_difficulty_limits.get("max_start_value", host.DifficultySettings.START_CARD_VALUE)),
		host.DifficultySettings.START_CARD_VALUE
	)
	host._configure_value_selector(
		host._seed_timer, "TIMER",
		int(host._seed_difficulty_limits.get("min_turn_time", host.DifficultySettings.START_TURN_TIME)),
		int(host.DifficultySettings.START_TURN_TIME),
		int(host.DifficultySettings.START_TURN_TIME)
	)


static func seed_difficulty_overrides(host: ChallengeSelection) -> Dictionary:
	return {
		"pile_count": host._selected_option_number(host._seed_piles),
		"hand_size": host._selected_option_number(host._seed_hand),
		"start_value": host._selected_option_number(host._seed_value),
		"turn_time": float(host._selected_option_number(host._seed_timer)),
	}


static func selected_option_number(host: ChallengeSelection, selector: Label) -> int:
	if selector == null:
		return 0
	return int(selector.get_meta("value", 0))
