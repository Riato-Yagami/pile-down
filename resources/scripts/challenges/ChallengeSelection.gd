@tool
class_name ChallengeSelection
extends "res://resources/scripts/ui/MenuPanelLayout.gd"

signal challenge_selected(id: StringName, endless: bool)
signal seeded_run_requested(
	seed_text: String, challenge_id: StringName,
	bonus_levels: Dictionary, rule_ids: Array[StringName],
	endless: bool, difficulty: Dictionary
)
signal closed()

@onready var list: VBoxContainer = %ChallengeList
@onready var scroll: ScrollContainer = %Scroll
@onready var lock_filter: ProgressionLockFilter = %LockFilter
@onready var page: VBoxContainer = %Page
@onready var seed_page: ScrollContainer = %SeedPage
@onready var seed_content: VBoxContainer = %SeedContent
@onready var challenges_tab_button: TextureButton = %ChallengesTabButton
@onready var seeds_tab_button: TextureButton = %SeedsTabButton

const SeedSelectionBuilderScript := preload(
	"res://resources/scripts/challenges/ui/SeedSelectionBuilder.gd"
)
const SeedControlStyleScript := preload("res://resources/scripts/challenges/ui/SeedControlStyle.gd")

const SELECTED_COLOR := Color("4d82c2")
const SELECTION_TEXT_COLOR := SELECTED_COLOR
const TEXT_COLOR := Color("3c3c3c")
const MUTED_COLOR := Color("8a8882")
const ENTRY_FONT := preload("res://resources/fonts/Tiny5-Regular.ttf")
const CHECKED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/checked.tres"
)
const UNCHECKED_TEXTURE := preload(
	"res://resources/sprites/ui/check/unchecked.png"
)
const SELECTED_TEXTURE := preload(
	"res://resources/materials/textures/ui/check/selected.tres"
)
const SCROLL_TRACK_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/slide-bar/vertical/bar.tres"
)
const SCROLL_SELECTOR_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/slide-bar/vertical/selector.tres"
)
const PixelUiScript := preload("res://resources/scripts/ui/PixelUi.gd")
const DifficultySettings := preload("res://resources/scripts/settings/difficulty.gd")
const REGION_BUTTON_SCENE := preload("res://resources/scenes/ui/RegionButton.tscn")
const SELECTABLE_TEXT_SCENE := preload("res://resources/scenes/ui/SelectableText.tscn")
const PROGRESSION_MENU_SCENE := preload(
	"res://resources/scenes/progression/ProgressionMenu.tscn"
)
const BUTTON_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/button.tres"
)
const MULTI_SELECTION_ARROW_TEXTURE := preload(
	"res://resources/materials/textures/ui/buttons/multiselection-arrow.tres"
)
const ARROW_UP_TEXTURE := preload(
	"res://resources/materials/textures/ui/icons/arrows/up.tres"
)
const ARROW_DOWN_TEXTURE := preload(
	"res://resources/materials/textures/ui/icons/arrows/down.tres"
)
const SubmenuPageAnimatorScript := preload(
	"res://resources/scripts/ui/SubmenuPageAnimator.gd"
)
const PAGE_CHALLENGES := 0
const PAGE_SEEDS := 1
const SEEDED_MAX_PILES := 4
const SEEDED_MIN_CARD_VALUE := 1
const SEED_MENU_HEIGHT := 31.0
const SEED_MENU_POPUP_MAX_HEIGHT := 290.0

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
var _seed_difficulty_limits: Dictionary = {}
var _seed_input: LineEdit
var _seed_mode: OptionButton
var _seed_endless: Button
var _seed_piles: Label
var _seed_hand: Label
var _seed_value: Label
var _seed_timer: Label
var _seed_mode_ids: Array[StringName] = []
var _seed_mode_endless: Array[bool] = []
var _current_page := PAGE_CHALLENGES
var _page_animator := SubmenuPageAnimatorScript.new()
var _selected_bonus_ids: Array[StringName] = []
var _selected_bonus_levels: Dictionary = {}
var _selected_rule_ids: Array[StringName] = []
var _centered_selected_texture: Texture2D
var _centered_unchecked_texture: Texture2D


func _ready() -> void:
	apply_panel_layout()
	_prepare_centered_check_textures()
	_sync_lock_slot_with_progression_template()
	_style_scrollbar(scroll)
	_style_scrollbar(seed_page)
	lock_filter.mode_changed.connect(_on_filter_changed)
	challenges_tab_button.pressed.connect(_show_page.bind(PAGE_CHALLENGES, true))
	seeds_tab_button.pressed.connect(_show_page.bind(PAGE_SEEDS, true))
	_build_seed_controls()
	resized.connect(_constrain_panel_content)
	visibility_changed.connect(preserve_panel_rect)
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
		var button := SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
		button.setup(
			true, entry_heading_font, entry_heading_font_size,
			CHECKED_TEXTURE if index < 2 else UNCHECKED_TEXTURE, UNCHECKED_TEXTURE
		)
		button.custom_minimum_size = Vector2(0, 24)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.flat = true
		button.set_pressed_no_signal(index < 2)
		button.text = "CHALLENGE %d" % (index + 1) if unlocked else "???"
		button.disabled = not unlocked
		_style_card(button)
		_style_selectable_availability(button, unlocked)
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
	SeedSelectionBuilderScript.build_seed_controls(self)


func _build_unlock_selection(section: VBoxContainer) -> void:
	SeedSelectionBuilderScript.build_unlock_selection(self, section)


func _refresh_unlock_selection() -> void:
	SeedSelectionBuilderScript.refresh_unlock_selection(self)


func _clear_children(container: Control) -> void:
	SeedSelectionBuilderScript.clear_children(self, container)


func _add_seed_bonus_menu(
	container: VBoxContainer, definitions: Array[BonusData]
) -> void:
	SeedSelectionBuilderScript.add_seed_bonus_menu(self, container, definitions)


func _on_seed_bonus_check(
	pressed: bool, id: StringName, level: int, activation: Button,
	level_buttons: Array[Button], menu: Button
) -> void:
	SeedSelectionBuilderScript.on_seed_bonus_check(
		self, pressed, id, level, activation, level_buttons, menu
	)


func _refresh_seed_bonus_checks(
	id: StringName, activation: Button, level_buttons: Array[Button]
) -> void:
	SeedSelectionBuilderScript.refresh_seed_bonus_checks(self, id, activation, level_buttons)


func _add_seed_rule_menu(
	container: VBoxContainer, definitions: Array[SpecialRuleData]
) -> void:
	SeedSelectionBuilderScript.add_seed_rule_menu(self, container, definitions)


func _on_seed_rule_check(checked: bool, id: StringName, menu: Button) -> void:
	SeedSelectionBuilderScript.on_seed_rule_check(self, checked, id, menu)


func _refresh_seed_menu_text(menu: Button, title: String, count: int) -> void:
	SeedSelectionBuilderScript.refresh_seed_menu_text(self, menu, title, count)


func _roman_level(level: int) -> String:
	return SeedSelectionBuilderScript.roman_level(self, level)


func _add_empty_selection_label(container: VBoxContainer) -> void:
	SeedSelectionBuilderScript.add_empty_selection_label(self, container)


func _button_style(content_right := 9.0) -> StyleBoxTexture:
	return SeedControlStyleScript.button_style(self, content_right)


func _style_seed_input(input: LineEdit) -> void:
	SeedControlStyleScript.style_seed_input(self, input)


func _style_seed_selector(selector: OptionButton) -> void:
	SeedControlStyleScript.style_seed_selector(self, selector)


func _style_seed_check(check: Button) -> void:
	SeedControlStyleScript.style_seed_check(self, check)


func _style_multi_check(check: Button) -> void:
	SeedControlStyleScript.style_multi_check(self, check)


func _style_selectable_check(
	check: Button,
	base_offset: Vector2,
	autowrap: TextServer.AutowrapMode,
	include_disabled_color: bool,
	include_disabled_style: bool,
	content_margin_top := 0.0
) -> void:
	SeedControlStyleScript.style_selectable_check(
		self, check, base_offset, autowrap, include_disabled_color, include_disabled_style, content_margin_top
	)


func _create_multi_select_button() -> Button:
	return SeedControlStyleScript.create_multi_select_button(self)


func _attach_multi_select_popup(
	menu: Button, popup_content: VBoxContainer
) -> PopupPanel:
	return SeedControlStyleScript.attach_multi_select_popup(self, menu, popup_content)


func _show_multi_select_popup(menu: Button, popup: PopupPanel) -> void:
	await SeedControlStyleScript.show_multi_select_popup(self, menu, popup)


func _popup_has_more_room_above(menu_rect: Rect2, viewport_height: float) -> bool:
	return SeedControlStyleScript.popup_has_more_room_above(self, menu_rect, viewport_height)


func _popup_available_space(
	menu_rect: Rect2, viewport_height: float, open_above: bool
) -> float:
	return SeedControlStyleScript.popup_available_space(self, menu_rect, viewport_height, open_above)


func _scroll_seed_button_to_popup_anchor(menu: Button) -> void:
	await SeedControlStyleScript.scroll_seed_button_to_popup_anchor(self, menu)


func _prepare_centered_check_textures() -> void:
	SeedControlStyleScript.prepare_centered_check_textures(self)


func _centered_check_texture(source: Texture2D) -> Texture2D:
	return SeedControlStyleScript.centered_check_texture(self, source)


func _style_popup_scrollbar(popup: PopupMenu) -> void:
	await SeedControlStyleScript.style_popup_scrollbar(self, popup)


func _connect_seed_control_highlight(control: Control) -> void:
	SeedControlStyleScript.connect_seed_control_highlight(self, control)


func _on_seed_control_mouse_exited(control: Control) -> void:
	SeedControlStyleScript.on_seed_control_mouse_exited(self, control)


func _set_seed_control_highlight(control: Control, highlighted: bool) -> void:
	SeedControlStyleScript.set_seed_control_highlight(self, control, highlighted)


func open(
	manager: ChallengeManager, achievements: Array[StringName],
	unlocked_bonus_ids: Array[StringName] = [],
	unlocked_rule_ids: Array[StringName] = [],
	unlocked_bonus_levels: Dictionary = {},
	seed_difficulty_limits: Dictionary = {}
) -> void:
	_manager = manager
	_achievements = achievements
	_unlocked_bonus_ids.assign(unlocked_bonus_ids)
	_unlocked_bonus_levels = unlocked_bonus_levels.duplicate()
	_unlocked_rule_ids.assign(unlocked_rule_ids)
	_seed_difficulty_limits = seed_difficulty_limits.duplicate()
	lock_filter.set_mode(ProgressionLockFilter.BOTH)
	_refresh_seed_difficulty_limits()
	_refresh_list()
	_refresh_unlock_selection()
	_show_page(PAGE_CHALLENGES)
	visible = true


func _show_page(target_page: int, animate := false) -> void:
	preserve_panel_rect()
	var previous_page := _current_page
	_current_page = clampi(target_page, PAGE_CHALLENGES, PAGE_SEEDS)
	var showing_challenges := _current_page == PAGE_CHALLENGES
	scroll.visible = showing_challenges
	seed_page.visible = not showing_challenges
	lock_filter.visible = showing_challenges
	challenges_tab_button.modulate = SELECTED_COLOR if showing_challenges else Color.WHITE
	seeds_tab_button.modulate = Color.WHITE if showing_challenges else SELECTED_COLOR
	if animate and previous_page != _current_page:
		_page_animator.play(page, signi(_current_page - previous_page))
	_constrain_panel_content()


func _constrain_panel_content() -> void:
	if not is_node_ready():
		return
	var list_width := panel_body_width(30.0, 5.0, 10.0)
	for target in [list, seed_content]:
		target.custom_minimum_size.x = 0.0
		target.size.x = list_width
		_constrain_wrap_labels(target, list_width)


func _constrain_wrap_labels(root: Node, list_width: float) -> void:
	if root is SelectableText:
		return
	for child in root.get_children():
		if child is Control:
			var control := child as Control
			if child is Label:
				control.custom_minimum_size.x = 0.0
				control.size.x = list_width
			elif child is Container:
				control.custom_minimum_size.x = 0.0
		_constrain_wrap_labels(child, list_width)


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
	SeedSelectionBuilderScript.refresh_seed_modes(self)


func _fill_random_seed() -> void:
	SeedSelectionBuilderScript.fill_random_seed(self)


func _play_seed() -> void:
	SeedSelectionBuilderScript.play_seed(self)


func _create_value_selector(
	container: VBoxContainer, label: String, first: int, last: int, default_value: int
) -> Label:
	return SeedSelectionBuilderScript.create_value_selector(
		self, container, label, first, last, default_value
	)


func _configure_value_selector(
	value_label: Label, label: String, first: int, last: int, default_value: int
) -> void:
	SeedSelectionBuilderScript.configure_value_selector(
		self, value_label, label, first, last, default_value
	)


func _create_value_arrow(texture: Texture2D) -> TextureHighlightButton:
	return SeedSelectionBuilderScript.create_value_arrow(self, texture)


func _step_value_selector(value_label: Label, direction: int) -> void:
	SeedSelectionBuilderScript.step_value_selector(self, value_label, direction)


func _refresh_value_selector_text(value_label: Label) -> void:
	SeedSelectionBuilderScript.refresh_value_selector_text(self, value_label)


func _refresh_seed_endless_selection(_index := -1) -> void:
	SeedSelectionBuilderScript.refresh_seed_endless_selection(self, _index)


func _refresh_seed_difficulty_limits() -> void:
	SeedSelectionBuilderScript.refresh_seed_difficulty_limits(self)


func _seed_difficulty_overrides() -> Dictionary:
	return SeedSelectionBuilderScript.seed_difficulty_overrides(self)


func _selected_option_number(selector: Label) -> int:
	return SeedSelectionBuilderScript.selected_option_number(self, selector)


func _sync_lock_slot_with_progression_template() -> void:
	var template := PROGRESSION_MENU_SCENE.instantiate()
	var source_slot := template.get_node_or_null("Margin/Layout/Header/LockSlot") as Control
	var target_slot := lock_filter.get_parent() as Control if lock_filter != null else null
	if source_slot != null and target_slot != null:
		target_slot.custom_minimum_size = source_slot.custom_minimum_size
		target_slot.size_flags_vertical = source_slot.size_flags_vertical
	var source_filter := template.get_node_or_null("Margin/Layout/Header/LockSlot/LockFilter") as Control
	if source_filter != null and lock_filter != null:
		lock_filter.offset_left = source_filter.offset_left
		lock_filter.offset_top = source_filter.offset_top
		lock_filter.offset_right = source_filter.offset_right
		lock_filter.offset_bottom = source_filter.offset_bottom
	template.free()


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
	entry.custom_minimum_size.x = 0.0
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_theme_constant_override("separation", 1)
	var card := SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
	card.setup(
		true, entry_heading_font, entry_heading_font_size,
		CHECKED_TEXTURE, UNCHECKED_TEXTURE
	)
	card.custom_minimum_size = Vector2(0, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.flat = true
	card.set_pressed_no_signal(complete)
	_style_card(card)
	if not unlocked:
		card.text = "???"
		card.disabled = true
	else:
		card.text = data.title
		card.pressed.connect(challenge_selected.emit.bind(data.id, false))
	_style_selectable_availability(card, unlocked)
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
		var endless_button := SELECTABLE_TEXT_SCENE.instantiate() as SelectableText
		endless_button.setup(
			false, entry_heading_font, entry_heading_font_size,
			null, null, entry_heading_text_offset
		)
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
	var selectable := button as SelectableText
	if selectable != null:
		selectable.normal_text_color = TEXT_COLOR
		selectable.selected_text_color = SELECTION_TEXT_COLOR
		selectable.disabled_text_color = MUTED_COLOR
		selectable.checked_uses_selected_text_color = false
	if entry_heading_font != null:
		button.add_theme_font_override("font", entry_heading_font)
	button.add_theme_font_size_override("font_size", entry_heading_font_size)
	var heading_offset_style := StyleBoxEmpty.new()
	heading_offset_style.content_margin_left = entry_heading_text_offset.x
	heading_offset_style.content_margin_top = entry_heading_text_offset.y
	button.add_theme_stylebox_override("normal", heading_offset_style)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", SELECTION_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", SELECTION_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", SELECTION_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", MUTED_COLOR)
	button.add_theme_constant_override("outline_size", 0)


func _style_selectable_availability(button: Button, available: bool) -> void:
	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	)
	if not available:
		button.focus_mode = Control.FOCUS_NONE


func _style_entry_heading(label: Label, accent := false) -> void:
	label.custom_minimum_size.x = 0.0
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
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
	label.custom_minimum_size.x = 0.0
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if entry_details_font != null:
		label.add_theme_font_override("font", entry_details_font)
	label.add_theme_font_size_override("font_size", entry_details_font_size)
	label.add_theme_color_override("font_color", MUTED_COLOR)


func _style_scrollbar(target: ScrollContainer) -> void:
	_style_v_scrollbar(target.get_v_scroll_bar())


func _style_v_scrollbar(scrollbar: VScrollBar) -> void:
	PixelUiScript.style_vertical_scrollbar(
		scrollbar,
		SCROLL_TRACK_TEXTURE,
		SCROLL_SELECTOR_TEXTURE
	)
