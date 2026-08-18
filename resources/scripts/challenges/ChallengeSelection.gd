@tool
class_name ChallengeSelection
extends Control

signal challenge_selected(id: StringName, endless: bool)
signal seeded_run_requested(
	seed_text: String, challenge_id: StringName,
	bonus_levels: Dictionary, rule_ids: Array[StringName]
)
signal closed()

@onready var list: VBoxContainer = %ChallengeList
@onready var scroll: ScrollContainer = %Scroll
@onready var lock_filter: ProgressionLockFilter = %LockFilter
@onready var page: VBoxContainer = %Page
@onready var page_title: Label = %PageTitle
@onready var seed_page: ScrollContainer = %SeedPage
@onready var seed_content: VBoxContainer = %SeedContent
@onready var challenges_tab_button: TextureButton = %ChallengesTabButton
@onready var seeds_tab_button: TextureButton = %SeedsTabButton

const SELECTED_COLOR := Color("4d82c2")
const TEXT_COLOR := Color("3c3c3c")
const MUTED_COLOR := Color("8a8882")
const ENTRY_FONT := preload("res://resources/fonts/Tiny5-Regular.ttf")
const CHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/checked.tres"
)
const UNCHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/unchecked.tres"
)
const SCROLL_TRACK_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/slide-bar/vertical/bar.tres"
)
const SCROLL_SELECTOR_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/slide-bar/vertical/selector.tres"
)
const ScrollVisualScript := preload(
	"res://resources/scripts/ui/ProgressionScrollVisual.gd"
)
const REGION_BUTTON_SCENE := preload("res://resources/scenes/ui/RegionButton.tscn")
const BUTTON_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/button.tres"
)
const DOWN_ARROW_TEXTURE := preload(
	"res://resources/materials/textures/ui/icons/arrows/down.tres"
)
const SubmenuPageAnimatorScript := preload(
	"res://resources/scripts/ui/SubmenuPageAnimator.gd"
)
const PAGE_CHALLENGES := 0
const PAGE_SEEDS := 1

@export_category("Editor Preview")
@export var show_editor_preview := false:
	set(value):
		show_editor_preview = value
		if Engine.is_editor_hint() and is_node_ready():
			if show_editor_preview:
				_show_editor_preview()
			else:
				visible = false
@export_enum("Challenges", "Seeds") var editor_preview_page := PAGE_CHALLENGES:
	set(value):
		editor_preview_page = clampi(value, PAGE_CHALLENGES, PAGE_SEEDS)
		_refresh_editor_preview()
@export var preview_all_unlocked := true:
	set(value):
		preview_all_unlocked = value
		_refresh_editor_preview()

@export_category("Entry Style")
@export var entry_heading_font: Font:
	set(value):
		entry_heading_font = value
		_refresh_editor_preview()
@export_range(8, 32, 1) var entry_heading_font_size := 15:
	set(value):
		entry_heading_font_size = value
		_refresh_editor_preview()
@export var entry_heading_text_offset := Vector2(2.0, 2.0):
	set(value):
		entry_heading_text_offset = value
		_refresh_editor_preview()
@export var entry_details_font: Font:
	set(value):
		entry_details_font = value
		_refresh_editor_preview()
@export_range(8, 24, 1) var entry_details_font_size := 11:
	set(value):
		entry_details_font_size = value
		_refresh_editor_preview()

var _manager: ChallengeManager
var _achievements: Array[StringName] = []
var _unlocked_bonus_ids: Array[StringName] = []
var _unlocked_bonus_levels: Dictionary = {}
var _unlocked_rule_ids: Array[StringName] = []
var _seed_input: LineEdit
var _seed_mode: OptionButton
var _seed_mode_ids: Array[StringName] = []
var _current_page := PAGE_CHALLENGES
var _page_animator := SubmenuPageAnimatorScript.new()
var _selected_bonus_ids: Array[StringName] = []
var _selected_bonus_levels: Dictionary = {}
var _selected_rule_ids: Array[StringName] = []


func _ready() -> void:
	_style_scrollbar(scroll)
	_style_scrollbar(seed_page)
	lock_filter.mode_changed.connect(_on_filter_changed)
	challenges_tab_button.pressed.connect(_show_page.bind(PAGE_CHALLENGES, true))
	seeds_tab_button.pressed.connect(_show_page.bind(PAGE_SEEDS, true))
	_build_seed_controls()
	if Engine.is_editor_hint() and show_editor_preview:
		_show_editor_preview()
	else:
		visible = false


func _refresh_editor_preview() -> void:
	if Engine.is_editor_hint() and is_node_ready():
		call_deferred("_show_editor_preview")


func _show_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	visible = show_editor_preview
	if not visible:
		return
	lock_filter.set_mode(ProgressionLockFilter.BOTH)
	_build_editor_challenge_preview()
	_build_editor_seed_preview()
	_show_page(editor_preview_page)


func _build_editor_challenge_preview() -> void:
	_clear_children(list)
	for index in 6:
		var unlocked := preview_all_unlocked or index < 3
		var entry := VBoxContainer.new()
		entry.add_theme_constant_override("separation", 1)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 24)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.flat = true
		button.icon = CHECKED_TEXTURE if index < 2 else UNCHECKED_TEXTURE
		button.text = "CHALLENGE %d" % (index + 1) if unlocked else "???"
		button.disabled = not unlocked
		_style_card(button)
		entry.add_child(button)
		var details := Label.new()
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_entry_details(details)
		details.text = (
			"20 ROUNDS  ·  BEST: 4 ROUNDS LEFT\nEditor preview challenge."
			if unlocked else "Complete an achievement to unlock."
		)
		entry.add_child(details)
		list.add_child(entry)


func _build_editor_seed_preview() -> void:
	_seed_mode.clear()
	_seed_mode_ids.clear()
	for title in ["CLASSIC", "RELOAD REQUIRED", "ONE SHOT", "POOL PARTY"]:
		_seed_mode.add_item(title)
		_seed_mode_ids.append(&"")
	_seed_input.text = "PILE-DOWN"
	var bonuses := seed_content.get_node("PlayASeed/BonusChoices") as VBoxContainer
	var rules := seed_content.get_node("PlayASeed/RuleChoices") as VBoxContainer
	_clear_children(bonuses)
	_clear_children(rules)
	if preview_all_unlocked:
		var preview_bonuses: Array[BonusData] = []
		for index in 5:
			var id := StringName("preview_bonus_%d" % index)
			var preview_bonus := BonusData.new(
				id,
				["OPEN BOOK", "REDRAW", "LUCKY HAND", "TIME BANK", "SAFETY NET"][index],
				"", BonusData.Category.MEMORY, 3
			)
			_unlocked_bonus_levels[id] = 3
			preview_bonuses.append(preview_bonus)
		_add_seed_bonus_menu(bonuses, preview_bonuses)
		var preview_rules: Array[SpecialRuleData] = []
		for index in 5:
			preview_rules.append(SpecialRuleData.new(
				StringName("preview_rule_%d" % index),
				["SHELL GAME", "MERRY-GO-STACK", "WAVY BABY", "PILE UP", "LIGHTS OUT"][index],
			))
		_add_seed_rule_menu(rules, preview_rules)
	else:
		_add_empty_selection_label(bonuses)
		_add_empty_selection_label(rules)


func _build_seed_controls() -> void:
	if is_instance_valid(_seed_input):
		return
	var section := VBoxContainer.new()
	section.name = "PlayASeed"
	section.add_theme_constant_override("separation", 4)
	var seed_caption := Label.new()
	seed_caption.text = "SEED"
	_style_entry_heading(seed_caption, true)
	section.add_child(seed_caption)
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "PILE-DOWN"
	_seed_input.max_length = 80
	_style_seed_input(_seed_input)
	section.add_child(_seed_input)
	var mode_caption := Label.new()
	mode_caption.text = "MODE"
	_style_entry_heading(mode_caption, true)
	section.add_child(mode_caption)
	_seed_mode = OptionButton.new()
	_style_seed_selector(_seed_mode)
	section.add_child(_seed_mode)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	var play := REGION_BUTTON_SCENE.instantiate() as RegionButton
	play.text = "PLAY"
	play.custom_minimum_size = Vector2(70, 31)
	play.add_theme_font_size_override("font_size", 16)
	if entry_heading_font != null:
		play.add_theme_font_override("font", entry_heading_font)
	play.highlight_material = challenges_tab_button.highlight_material
	play.pressed.connect(_play_seed)
	var random_seed := REGION_BUTTON_SCENE.instantiate() as RegionButton
	random_seed.text = "RANDOM SEED"
	random_seed.custom_minimum_size = Vector2(112, 31)
	random_seed.add_theme_font_size_override("font_size", 16)
	if entry_heading_font != null:
		random_seed.add_theme_font_override("font", entry_heading_font)
	random_seed.highlight_material = challenges_tab_button.highlight_material
	random_seed.pressed.connect(_fill_random_seed)
	actions.add_child(play)
	actions.add_child(random_seed)
	section.add_child(actions)
	seed_content.add_child(section)
	_build_unlock_selection(section)


func _build_unlock_selection(section: VBoxContainer) -> void:
	var bonuses_title := Label.new()
	bonuses_title.text = "BONUSES"
	_style_entry_heading(bonuses_title, true)
	section.add_child(bonuses_title)
	var bonuses := VBoxContainer.new()
	bonuses.name = "BonusChoices"
	bonuses.add_theme_constant_override("separation", 3)
	section.add_child(bonuses)
	var rules_title := Label.new()
	rules_title.text = "SPECIAL RULES"
	_style_entry_heading(rules_title, true)
	section.add_child(rules_title)
	var rules := VBoxContainer.new()
	rules.name = "RuleChoices"
	rules.add_theme_constant_override("separation", 3)
	section.add_child(rules)


func _refresh_unlock_selection() -> void:
	var bonuses := seed_content.get_node("PlayASeed/BonusChoices") as VBoxContainer
	var rules := seed_content.get_node("PlayASeed/RuleChoices") as VBoxContainer
	_clear_children(bonuses)
	_clear_children(rules)
	_selected_bonus_ids = _selected_bonus_ids.filter(
		func(id: StringName) -> bool: return _unlocked_bonus_ids.has(id)
	)
	for id in _selected_bonus_levels.keys():
		if not _unlocked_bonus_ids.has(StringName(id)):
			_selected_bonus_levels.erase(id)
	_selected_rule_ids = _selected_rule_ids.filter(
		func(id: StringName) -> bool: return _unlocked_rule_ids.has(id)
	)
	var available_bonuses: Array[BonusData] = []
	for data in BonusRegistry.create_all():
		if _unlocked_bonus_ids.has(data.id):
			available_bonuses.append(data)
	var available_rules: Array[SpecialRuleData] = []
	for data in SpecialRuleRegistry.create_all_rules():
		if _unlocked_rule_ids.has(data.id):
			available_rules.append(data)
	if available_bonuses.is_empty():
		_add_empty_selection_label(bonuses)
	else:
		_add_seed_bonus_menu(bonuses, available_bonuses)
	if available_rules.is_empty():
		_add_empty_selection_label(rules)
	else:
		_add_seed_rule_menu(rules, available_rules)


func _clear_children(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()


func _add_seed_bonus_menu(
	container: VBoxContainer, definitions: Array[BonusData]
) -> void:
	var menu := _create_multi_select_button()
	var popup_content := HFlowContainer.new()
	popup_content.add_theme_constant_override("h_separation", 12)
	popup_content.add_theme_constant_override("v_separation", 4)
	for data in definitions:
		var unlocked_level := clampi(
			int(_unlocked_bonus_levels.get(data.id, 1)), 1, data.max_level
		)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(255, 27)
		row.add_theme_constant_override("separation", 5)
		var activation := CheckBox.new()
		activation.text = data.title
		activation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_multi_check(activation)
		var level_buttons: Array[CheckBox] = []
		for level in range(1, unlocked_level + 1):
			var level_button := CheckBox.new()
			level_button.text = str(level)
			level_button.tooltip_text = "%s · LVL %d" % [data.title, level]
			_style_multi_check(level_button)
			level_buttons.append(level_button)
			row.add_child(level_button)
		activation.toggled.connect(
			_on_seed_bonus_check.bind(data.id, 0, activation, level_buttons, menu)
		)
		for level_index in level_buttons.size():
			level_buttons[level_index].toggled.connect(
				_on_seed_bonus_check.bind(
					data.id, level_index + 1, activation, level_buttons, menu
				)
			)
		row.add_child(activation)
		row.move_child(activation, 0)
		_refresh_seed_bonus_checks(data.id, activation, level_buttons)
		popup_content.add_child(row)
	var popup := _attach_multi_select_popup(menu, popup_content)
	menu.pressed.connect(_show_multi_select_popup.bind(menu, popup))
	_refresh_seed_menu_text(menu, "SELECT BONUSES", _selected_bonus_levels.size())
	container.add_child(menu)


func _on_seed_bonus_check(
	pressed: bool, id: StringName, level: int, activation: CheckBox,
	level_buttons: Array[CheckBox], menu: Button
) -> void:
	if level == 0:
		if pressed:
			_selected_bonus_levels[id] = maxi(
				int(_selected_bonus_levels.get(id, 0)), 1
			)
			if not _selected_bonus_ids.has(id):
				_selected_bonus_ids.append(id)
		else:
			_selected_bonus_levels.erase(id)
			_selected_bonus_ids.erase(id)
	elif pressed:
		_selected_bonus_levels[id] = level
		if not _selected_bonus_ids.has(id):
			_selected_bonus_ids.append(id)
	elif int(_selected_bonus_levels.get(id, 0)) == level:
		_selected_bonus_levels.erase(id)
		_selected_bonus_ids.erase(id)
	_refresh_seed_bonus_checks(id, activation, level_buttons)
	_refresh_seed_menu_text(menu, "SELECT BONUSES", _selected_bonus_levels.size())


func _refresh_seed_bonus_checks(
	id: StringName, activation: CheckBox, level_buttons: Array[CheckBox]
) -> void:
	var selected_level := int(_selected_bonus_levels.get(id, 0))
	activation.set_pressed_no_signal(selected_level > 0)
	for index in level_buttons.size():
		level_buttons[index].set_pressed_no_signal(selected_level == index + 1)


func _add_seed_rule_menu(
	container: VBoxContainer, definitions: Array[SpecialRuleData]
) -> void:
	var menu := _create_multi_select_button()
	var popup_content := HFlowContainer.new()
	popup_content.add_theme_constant_override("h_separation", 12)
	popup_content.add_theme_constant_override("v_separation", 4)
	for data in definitions:
		var check := CheckBox.new()
		check.custom_minimum_size = Vector2(255, 27)
		check.text = data.title
		check.button_pressed = _selected_rule_ids.has(data.id)
		_style_multi_check(check)
		check.toggled.connect(_on_seed_rule_check.bind(data.id, menu))
		popup_content.add_child(check)
	var popup := _attach_multi_select_popup(menu, popup_content)
	menu.pressed.connect(_show_multi_select_popup.bind(menu, popup))
	_refresh_seed_menu_text(menu, "SELECT RULES", _selected_rule_ids.size())
	container.add_child(menu)


func _on_seed_rule_check(checked: bool, id: StringName, menu: Button) -> void:
	if checked:
		_selected_rule_ids.append(id)
	else:
		_selected_rule_ids.erase(id)
	_refresh_seed_menu_text(menu, "SELECT RULES", _selected_rule_ids.size())


func _refresh_seed_menu_text(menu: Button, title: String, count: int) -> void:
	menu.text = title if count == 0 else "%s  ·  %d" % [title, count]


func _add_empty_selection_label(container: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "NONE UNLOCKED"
	_style_entry_details(label)
	container.add_child(label)


func _button_style() -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = BUTTON_TEXTURE
	atlas.region = Rect2(0, 0, 86, 31)
	var style := StyleBoxTexture.new()
	style.texture = atlas
	style.texture_margin_left = 8.0
	style.texture_margin_top = 6.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 6.0
	style.content_margin_left = 9.0
	style.content_margin_top = 4.0
	style.content_margin_right = 9.0
	style.content_margin_bottom = 4.0
	return style


func _style_seed_input(input: LineEdit) -> void:
	input.custom_minimum_size = Vector2(0, 31)
	input.add_theme_font_override("font", ENTRY_FONT)
	input.add_theme_font_size_override("font_size", 16)
	input.add_theme_color_override("font_color", Color.WHITE)
	input.add_theme_color_override("font_placeholder_color", Color(1, 1, 1, 0.62))
	input.add_theme_color_override("caret_color", Color.WHITE)
	input.add_theme_color_override("selection_color", Color("6da7e5"))
	for state in [&"normal", &"focus", &"read_only"]:
		input.add_theme_stylebox_override(state, _button_style())
	_connect_seed_control_highlight(input)


func _style_seed_selector(selector: OptionButton) -> void:
	selector.custom_minimum_size = Vector2(0, 31)
	selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selector.add_theme_font_override("font", ENTRY_FONT)
	selector.add_theme_font_size_override("font_size", 16)
	selector.add_theme_icon_override("arrow", DOWN_ARROW_TEXTURE)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color",
	]:
		selector.add_theme_color_override(color_name, Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		selector.add_theme_stylebox_override(state, _button_style())
	var popup := selector.get_popup()
	popup.add_theme_font_override("font", ENTRY_FONT)
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", TEXT_COLOR)
	popup.add_theme_color_override("font_hover_color", Color.WHITE)
	popup.add_theme_color_override("font_separator_color", SELECTED_COLOR)
	popup.add_theme_icon_override("radio_checked", CHECKED_TEXTURE)
	popup.add_theme_icon_override("radio_unchecked", UNCHECKED_TEXTURE)
	popup.add_theme_icon_override("checked", CHECKED_TEXTURE)
	popup.add_theme_icon_override("unchecked", UNCHECKED_TEXTURE)
	popup.add_theme_stylebox_override("hover", _button_style())
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = Color("f7f6f2")
	popup_panel.border_color = SELECTED_COLOR
	popup_panel.set_border_width_all(2)
	popup_panel.content_margin_left = 4
	popup_panel.content_margin_right = 4
	popup_panel.content_margin_top = 4
	popup_panel.content_margin_bottom = 4
	popup.add_theme_stylebox_override("panel", popup_panel)
	popup.about_to_popup.connect(_style_popup_scrollbar.bind(popup))
	_connect_seed_control_highlight(selector)


func _create_multi_select_button() -> Button:
	var menu := Button.new()
	menu.custom_minimum_size = Vector2(0, 31)
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu.add_theme_font_override("font", ENTRY_FONT)
	menu.add_theme_font_size_override("font_size", 16)
	for color_name in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color",
	]:
		menu.add_theme_color_override(color_name, Color.WHITE)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		menu.add_theme_stylebox_override(state, _button_style())
	var arrow := TextureRect.new()
	arrow.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	arrow.position = Vector2(-18, -4)
	arrow.size = Vector2(10, 8)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.texture = DOWN_ARROW_TEXTURE
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu.add_child(arrow)
	_connect_seed_control_highlight(menu)
	return menu


func _attach_multi_select_popup(
	menu: Button, popup_content: HFlowContainer
) -> PopupPanel:
	var popup := PopupPanel.new()
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = Color("f7f6f2")
	popup_panel.border_color = SELECTED_COLOR
	popup_panel.set_border_width_all(2)
	popup_panel.content_margin_left = 4
	popup_panel.content_margin_right = 4
	popup_panel.content_margin_top = 4
	popup_panel.content_margin_bottom = 4
	popup.add_theme_stylebox_override("panel", popup_panel)
	var scroll_container := ScrollContainer.new()
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.add_child(popup_content)
	popup.add_child(scroll_container)
	menu.add_child(popup)
	popup.about_to_popup.connect(_style_scrollbar.bind(scroll_container))
	return popup


func _show_multi_select_popup(menu: Button, popup: PopupPanel) -> void:
	if popup.visible:
		popup.hide()
		return
	var viewport_width := get_viewport_rect().size.x
	var popup_width := clampf(menu.size.x, 280.0, viewport_width - 24.0)
	var popup_position := menu.get_global_rect().position + Vector2(0, menu.size.y + 2)
	popup_position.x = clampf(popup_position.x, 8.0, viewport_width - popup_width - 8.0)
	popup.popup(Rect2i(
		Vector2i(popup_position), Vector2i(popup_width, 290)
	))


func _style_multi_check(check: CheckBox) -> void:
	check.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	check.add_theme_font_override("font", ENTRY_FONT)
	check.add_theme_font_size_override("font_size", 16)
	check.add_theme_color_override("font_color", TEXT_COLOR)
	check.add_theme_color_override("font_hover_color", SELECTED_COLOR)
	check.add_theme_color_override("font_pressed_color", SELECTED_COLOR)
	check.add_theme_color_override("font_focus_color", SELECTED_COLOR)
	check.add_theme_icon_override("checked", CHECKED_TEXTURE)
	check.add_theme_icon_override("unchecked", UNCHECKED_TEXTURE)
	var empty_style := StyleBoxEmpty.new()
	for state in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus"]:
		check.add_theme_stylebox_override(state, empty_style)


func _style_popup_scrollbar(popup: PopupMenu) -> void:
	await get_tree().process_frame
	for child in popup.find_children("*", "VScrollBar", true, false):
		_style_v_scrollbar(child as VScrollBar)


func _connect_seed_control_highlight(control: Control) -> void:
	control.mouse_entered.connect(_set_seed_control_highlight.bind(control, true))
	control.mouse_exited.connect(_on_seed_control_mouse_exited.bind(control))
	control.focus_entered.connect(_set_seed_control_highlight.bind(control, true))
	control.focus_exited.connect(_set_seed_control_highlight.bind(control, false))


func _on_seed_control_mouse_exited(control: Control) -> void:
	if not control.has_focus():
		_set_seed_control_highlight(control, false)


func _set_seed_control_highlight(control: Control, highlighted: bool) -> void:
	control.material = challenges_tab_button.highlight_material if highlighted else null


func open(
	manager: ChallengeManager, achievements: Array[StringName],
	unlocked_bonus_ids: Array[StringName] = [],
	unlocked_rule_ids: Array[StringName] = [],
	unlocked_bonus_levels: Dictionary = {}
) -> void:
	_manager = manager
	_achievements = achievements
	_unlocked_bonus_ids.assign(unlocked_bonus_ids)
	_unlocked_bonus_levels = unlocked_bonus_levels.duplicate()
	_unlocked_rule_ids.assign(unlocked_rule_ids)
	lock_filter.set_mode(ProgressionLockFilter.BOTH)
	_refresh_list()
	_refresh_unlock_selection()
	_show_page(PAGE_CHALLENGES)
	visible = true


func _show_page(target_page: int, animate := false) -> void:
	var previous_page := _current_page
	_current_page = clampi(target_page, PAGE_CHALLENGES, PAGE_SEEDS)
	var showing_challenges := _current_page == PAGE_CHALLENGES
	page_title.text = "SELECT A CHALLENGE" if showing_challenges else "PLAY A SEED"
	scroll.visible = showing_challenges
	seed_page.visible = not showing_challenges
	lock_filter.visible = showing_challenges
	challenges_tab_button.modulate = SELECTED_COLOR if showing_challenges else Color.WHITE
	seeds_tab_button.modulate = Color.WHITE if showing_challenges else SELECTED_COLOR
	if animate and previous_page != _current_page:
		_page_animator.play(page, signi(_current_page - previous_page))


func _refresh_list() -> void:
	for child in list.get_children():
		child.queue_free()
	if not _manager:
		return
	_refresh_seed_modes()
	for data in _manager.definitions:
		var unlocked := _manager.is_unlocked(data, _achievements)
		if lock_filter.mode == ProgressionLockFilter.UNLOCKED and not unlocked:
			continue
		if lock_filter.mode == ProgressionLockFilter.LOCKED and unlocked:
			continue
		_add_card(data, _manager, _achievements)


func _refresh_seed_modes() -> void:
	_seed_mode.clear()
	_seed_mode_ids.clear()
	_seed_mode.add_item("CLASSIC")
	_seed_mode_ids.append(&"")
	for data in _manager.definitions:
		if not _manager.is_unlocked(data, _achievements):
			continue
		_seed_mode.add_item(data.title)
		_seed_mode_ids.append(data.id)


func _fill_random_seed() -> void:
	_seed_input.text = str(RunRNG.generate_run_seed())


func _play_seed() -> void:
	var seed_text := _seed_input.text.strip_edges()
	if seed_text.is_empty():
		_fill_random_seed()
		seed_text = _seed_input.text
	var selected := _seed_mode.selected
	if selected < 0 or selected >= _seed_mode_ids.size():
		return
	seeded_run_requested.emit(
		seed_text, _seed_mode_ids[selected],
		_selected_bonus_levels.duplicate(), _selected_rule_ids
	)


func _on_filter_changed(_mode: int) -> void:
	_refresh_list()


func close() -> void:
	visible = false
	closed.emit()


func _add_card(
	data: ChallengeData,
	manager: ChallengeManager,
	achievements: Array[StringName]
) -> void:
	var unlocked := manager.is_unlocked(data, achievements)
	var complete := manager.completed.has(data.id)
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 1)
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.flat = true
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.icon = CHECKED_TEXTURE if complete else UNCHECKED_TEXTURE
	_style_card(card)
	if not unlocked:
		card.text = "???"
		card.disabled = true
	else:
		card.text = data.title
		card.pressed.connect(challenge_selected.emit.bind(data.id, false))
	entry.add_child(card)
	var details := Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_style_entry_details(details)
	details.text = (
		"Complete an achievement to unlock."
		if not unlocked
		else "%d ROUNDS  ·  BEST: %s\n%s" % [
			data.target_round - data.start_round,
			_format_standard_score(
				data,
				manager.highscores.get(data.id, -1),
				manager.best_times_ms.get(data.id, -1)
			),
			data.description,
		]
	)
	entry.add_child(details)
	if complete and data.allow_endless:
		var endless_button := Button.new()
		endless_button.custom_minimum_size = Vector2(0, 24)
		endless_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		endless_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		endless_button.flat = true
		endless_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_style_card(endless_button)
		endless_button.text = "ENDLESS  ·  BEST: %s" % str(
			manager.endless_highscores.get(data.id, "--")
		)
		endless_button.pressed.connect(challenge_selected.emit.bind(data.id, true))
		entry.add_child(endless_button)
	list.add_child(entry)


func _format_best_time(value: Variant) -> String:
	var milliseconds := int(value)
	if milliseconds < 0:
		return "--"
	var total_seconds := milliseconds / 1000
	return "%02d:%02d.%03d" % [
		total_seconds / 60, total_seconds % 60, milliseconds % 1000
	]


func _format_rounds_left(data: ChallengeData, reached_round: Variant) -> String:
	var reached := int(reached_round)
	if reached < 0:
		return "--"
	return "%d ROUNDS LEFT" % maxi(data.target_round - reached, 0)


func _format_standard_score(
	data: ChallengeData, reached_round: Variant, elapsed_time_ms: Variant
) -> String:
	var rounds_left := _format_rounds_left(data, reached_round)
	if rounds_left == "--":
		return rounds_left
	return "%s · %s" % [rounds_left, _format_best_time(elapsed_time_ms)]


func _style_card(button: Button) -> void:
	if entry_heading_font != null:
		button.add_theme_font_override("font", entry_heading_font)
	button.add_theme_font_size_override("font_size", entry_heading_font_size)
	var heading_offset_style := StyleBoxEmpty.new()
	heading_offset_style.content_margin_left = entry_heading_text_offset.x
	heading_offset_style.content_margin_top = entry_heading_text_offset.y
	button.add_theme_stylebox_override("normal", heading_offset_style)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", SELECTED_COLOR)
	button.add_theme_color_override("font_pressed_color", SELECTED_COLOR)
	button.add_theme_color_override("font_disabled_color", MUTED_COLOR)
	button.add_theme_constant_override("outline_size", 0)


func _style_entry_heading(label: Label, accent := false) -> void:
	if entry_heading_font != null:
		label.add_theme_font_override("font", entry_heading_font)
	label.add_theme_font_size_override("font_size", entry_heading_font_size)
	var heading_offset_style := StyleBoxEmpty.new()
	heading_offset_style.content_margin_left = entry_heading_text_offset.x
	heading_offset_style.content_margin_top = entry_heading_text_offset.y
	label.add_theme_stylebox_override("normal", heading_offset_style)
	label.add_theme_color_override(
		"font_color", SELECTED_COLOR if accent else TEXT_COLOR
	)


func _style_entry_details(label: Label) -> void:
	if entry_details_font != null:
		label.add_theme_font_override("font", entry_details_font)
	label.add_theme_font_size_override("font_size", entry_details_font_size)
	label.add_theme_color_override("font_color", MUTED_COLOR)


func _style_scrollbar(target: ScrollContainer) -> void:
	_style_v_scrollbar(target.get_v_scroll_bar())


func _style_v_scrollbar(scrollbar: VScrollBar) -> void:
	if scrollbar.get_node_or_null("ScrollVisual") != null:
		return
	scrollbar.custom_minimum_size.x = 8.0
	var empty_style := StyleBoxEmpty.new()
	for style_name in [&"scroll", &"scroll_focus", &"grabber", &"grabber_highlight", &"grabber_pressed"]:
		scrollbar.add_theme_stylebox_override(style_name, empty_style)
	var visual := Control.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_script(ScrollVisualScript)
	scrollbar.add_child(visual)
	visual.call("setup", scrollbar, SCROLL_TRACK_TEXTURE, SCROLL_SELECTOR_TEXTURE)
