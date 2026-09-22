class_name BonusSelection
extends Control

const SKIPPED_INDEX := -2

signal bonus_chosen(index: int)
signal rule_chosen(index: int)

@export_category("Entrance Animation")
@export var entrance_duration := 0.18
@export var entrance_scale := Vector2(0.96, 0.96)
@export_category("Selection Animation")
@export var selection_duration := 0.18
@export var selected_lift := 8.0

@onready var first_choice: BonusChoiceCard = %FirstChoice
@onready var choices: VBoxContainer = %Choices
@onready var rule_choices: GridContainer = %RuleChoices
@onready var skip_button: Button = %SkipButton

var _bonus_buttons: Array[BonusChoiceCard] = []
var _presentation_mode := 0
var _presentation_generation := 0
var _animation_tween: Tween


func _ready() -> void:
	visible = false
	_bonus_buttons.assign([first_choice])
	first_choice.pressed.connect(_choose.bind(0))
	skip_button.pressed.connect(_skip)


func present(
	offered_bonuses: Array[BonusData],
	levels: Array[int],
	flawless := false
) -> int:
	_presentation_generation += 1
	var generation := _presentation_generation
	_presentation_mode = 1
	if flawless:
		self.choices.visible = false
		rule_choices.visible = false
		skip_button.visible = false
		visible = true
		modulate.a = 1.0
		scale = Vector2.ONE
		await _show_flawless_feedback()
		if generation != _presentation_generation:
			return -1
	self.choices.visible = true
	rule_choices.visible = false
	skip_button.visible = true
	_ensure_bonus_button_count(offered_bonuses.size())
	for index in _bonus_buttons.size():
		var button := _bonus_buttons[index]
		button.visible = index < offered_bonuses.size()
		button.disabled = not button.visible
		button.modulate = Color.WHITE
		if button.visible:
			button.setup(offered_bonuses[index], levels[index], index)
	visible = true
	modulate.a = 0.0
	scale = entrance_scale
	_animation_tween = create_tween().set_parallel()
	_animation_tween.tween_property(self, "modulate:a", 1.0, entrance_duration)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, entrance_duration)
	return await bonus_chosen


func _show_flawless_feedback() -> void:
	var feedback := Label.new()
	feedback.text = "FLAWLESS!\n+1 BONUS CHOICE"
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 18)
	add_child(feedback)
	feedback.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	feedback.position -= feedback.size * 0.5
	var tween := create_tween()
	tween.tween_interval(0.28)
	tween.tween_property(feedback, "modulate:a", 0.0, 0.12)
	await tween.finished
	feedback.queue_free()


func _ensure_bonus_button_count(count: int) -> void:
	while _bonus_buttons.size() < count:
		var index := _bonus_buttons.size()
		var button := _duplicate_choice_template()
		button.name = "BonusChoice%d" % (index + 1)
		button.pressed.connect(_choose.bind(index))
		choices.add_child(button)
		_bonus_buttons.append(button)


func _duplicate_choice_template() -> BonusChoiceCard:
	return first_choice.duplicate(
		Node.DUPLICATE_GROUPS
		| Node.DUPLICATE_SCRIPTS
		| Node.DUPLICATE_USE_INSTANTIATION
	) as BonusChoiceCard


func present_rules(rules: Array[SpecialRuleData]) -> int:
	_presentation_generation += 1
	_presentation_mode = 2
	choices.visible = false
	rule_choices.visible = true
	skip_button.visible = false
	for child in rule_choices.get_children():
		child.queue_free()
	for index in rules.size():
		var button := _duplicate_choice_template()
		button.text = rules[index].title
		button.pressed.connect(_choose_rule.bind(index))
		rule_choices.add_child(button)
	visible = true
	modulate.a = 0.0
	scale = entrance_scale
	_animation_tween = create_tween().set_parallel()
	_animation_tween.tween_property(self, "modulate:a", 1.0, entrance_duration)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, entrance_duration)
	return await rule_chosen


func cancel() -> void:
	if _presentation_mode == 0 and not visible:
		return
	_presentation_generation += 1
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()
	_animation_tween = null
	visible = false
	skip_button.visible = false
	for button in _bonus_buttons:
		button.disabled = false
		button.modulate = Color.WHITE
	for child in rule_choices.get_children():
		if child is Button:
			(child as Button).disabled = false
	var cancelled_mode := _presentation_mode
	_presentation_mode = 0
	if cancelled_mode == 1:
		bonus_chosen.emit(-1)
	elif cancelled_mode == 2:
		rule_chosen.emit(-1)


func _skip() -> void:
	if _presentation_mode != 1:
		return
	_presentation_generation += 1
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()
	_animation_tween = null
	for button in _bonus_buttons:
		button.disabled = false
		button.modulate = Color.WHITE
	visible = false
	skip_button.visible = false
	_presentation_mode = 0
	bonus_chosen.emit(SKIPPED_INDEX)


func _choose(index: int) -> void:
	if index < 0 or index >= _bonus_buttons.size():
		return
	for button in _bonus_buttons:
		button.disabled = true
	var selected := _bonus_buttons[index]
	var generation := _presentation_generation
	_animation_tween = create_tween().set_parallel()
	_animation_tween.tween_property(
		selected,
		"position:y",
		selected.position.y - selected_lift,
		selection_duration
	)
	for button in _bonus_buttons:
		if button != selected and button.visible:
			_animation_tween.tween_property(
				button,
				"modulate:a",
				0.0,
				selection_duration
			)
	await _animation_tween.finished
	if generation != _presentation_generation:
		return
	visible = false
	_presentation_mode = 0
	_animation_tween = null
	for button in _bonus_buttons:
		button.disabled = false
		button.modulate = Color.WHITE
	bonus_chosen.emit(index)


func _choose_rule(index: int) -> void:
	var generation := _presentation_generation
	for child in rule_choices.get_children():
		(child as Button).disabled = true
	var selected := rule_choices.get_child(index) as Button
	_animation_tween = create_tween().set_parallel()
	_animation_tween.tween_property(
		selected,
		"position:y",
		selected.position.y - selected_lift,
		selection_duration
	)
	for child in rule_choices.get_children():
		if child != selected:
			_animation_tween.tween_property(
				child,
				"modulate:a",
				0.0,
				selection_duration
			)
	await _animation_tween.finished
	if generation != _presentation_generation:
		return
	visible = false
	_presentation_mode = 0
	_animation_tween = null
	rule_chosen.emit(index)
