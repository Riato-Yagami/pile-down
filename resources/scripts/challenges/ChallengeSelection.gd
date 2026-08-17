class_name ChallengeSelection
extends Control

signal challenge_selected(id: StringName, endless: bool)
signal closed()

@onready var list: VBoxContainer = %ChallengeList
@onready var scroll: ScrollContainer = %Scroll

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


func _ready() -> void:
	_style_scrollbar()


func open(manager: ChallengeManager, achievements: Array[StringName]) -> void:
	for child in list.get_children():
		child.queue_free()
	for data in manager.definitions:
		_add_card(data, manager, achievements)
	visible = true


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
	details.add_theme_font_override("font", ENTRY_FONT)
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", MUTED_COLOR)
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
	button.add_theme_font_override("font", ENTRY_FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", SELECTED_COLOR)
	button.add_theme_color_override("font_pressed_color", SELECTED_COLOR)
	button.add_theme_color_override("font_disabled_color", MUTED_COLOR)
	button.add_theme_constant_override("outline_size", 0)


func _style_scrollbar() -> void:
	var scrollbar := scroll.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 8.0
	var empty_style := StyleBoxEmpty.new()
	for style_name in [&"scroll", &"scroll_focus", &"grabber", &"grabber_highlight", &"grabber_pressed"]:
		scrollbar.add_theme_stylebox_override(style_name, empty_style)
	var visual := Control.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_script(ScrollVisualScript)
	scrollbar.add_child(visual)
	visual.call("setup", scrollbar, SCROLL_TRACK_TEXTURE, SCROLL_SELECTOR_TEXTURE)
