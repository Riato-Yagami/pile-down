class_name BonusSelection
extends Control

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

var _bonus_buttons: Array[BonusChoiceCard] = []


func _ready() -> void:
	visible = false
	_bonus_buttons.assign([first_choice])
	first_choice.pressed.connect(_choose.bind(0))


func present(offered_bonuses: Array[BonusData], levels: Array[int]) -> int:
	self.choices.visible = true
	rule_choices.visible = false
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
	var entrance := create_tween().set_parallel()
	entrance.tween_property(self, "modulate:a", 1.0, entrance_duration)
	entrance.tween_property(self, "scale", Vector2.ONE, entrance_duration)
	return await bonus_chosen


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
	choices.visible = false
	rule_choices.visible = true
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
	var entrance := create_tween().set_parallel()
	entrance.tween_property(self, "modulate:a", 1.0, entrance_duration)
	entrance.tween_property(self, "scale", Vector2.ONE, entrance_duration)
	return await rule_chosen


func _choose(index: int) -> void:
	if index < 0 or index >= _bonus_buttons.size():
		return
	for button in _bonus_buttons:
		button.disabled = true
	var selected := _bonus_buttons[index]
	var tween := create_tween().set_parallel()
	tween.tween_property(
		selected,
		"position:y",
		selected.position.y - selected_lift,
		selection_duration
	)
	for button in _bonus_buttons:
		if button != selected and button.visible:
			tween.tween_property(
				button,
				"modulate:a",
				0.0,
				selection_duration
			)
	await tween.finished
	visible = false
	for button in _bonus_buttons:
		button.disabled = false
		button.modulate = Color.WHITE
	bonus_chosen.emit(index)


func _choose_rule(index: int) -> void:
	for child in rule_choices.get_children():
		(child as Button).disabled = true
	var selected := rule_choices.get_child(index) as Button
	var tween := create_tween().set_parallel()
	tween.tween_property(
		selected,
		"position:y",
		selected.position.y - selected_lift,
		selection_duration
	)
	for child in rule_choices.get_children():
		if child != selected:
			tween.tween_property(
				child,
				"modulate:a",
				0.0,
				selection_duration
			)
	await tween.finished
	visible = false
	rule_chosen.emit(index)
