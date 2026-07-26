class_name SpecialRuleAnnouncement
extends Control

signal rule_delete_requested(index: int)

const RULE_DELETE_BUTTON_SCENE := preload(
	"res://resources/scenes/RuleDeleteButton.tscn"
)

@export_category("Timing")
@export var fade_duration := 0.2
@export var display_duration := 1.15
@export var rule_breaker_final_delay := 1.0
@export var rule_delete_confirmation_delay := 0.38
@export var rule_delete_fade_duration := 0.18
@export var delete_counter_fade_duration := 0.25

@onready var combo_label: Label = %ComboLabel
@onready var rules_label: Label = %RulesLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var delete_label: Label = %DeleteLabel
@onready var rule_delete_choices: VBoxContainer = %RuleDeleteChoices


func show_rules(rules: Array[SpecialRuleData]) -> void:
	if rules.is_empty():
		return
	combo_label.text = _combination_title(rules)
	combo_label.visible = not combo_label.text.is_empty()
	var titles: PackedStringArray = []
	for rule in rules:
		titles.append(rule.title)
	rules_label.text = "\n+\n".join(titles)
	subtitle_label.text = rules[0].subtitle if rules.size() == 1 else ""
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_interval(display_duration)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	visible = false


func choose_rules_to_delete(
	rules: Array[SpecialRuleData],
	requested_count: int,
	can_delete_last_rule := false
) -> Array[int]:
	var maximum_deletions := (
		rules.size()
		if can_delete_last_rule
		else maxi(rules.size() - 1, 0)
	)
	var remaining := mini(requested_count, maximum_deletions)
	var removed_indices: Array[int] = []
	if remaining <= 0:
		return removed_indices
	combo_label.text = _combination_title(rules)
	combo_label.visible = not combo_label.text.is_empty()
	rules_label.visible = false
	subtitle_label.visible = false
	delete_label.visible = true
	rule_delete_choices.visible = true
	for child in rule_delete_choices.get_children():
		child.queue_free()
	for index in rules.size():
		var button := (
			RULE_DELETE_BUTTON_SCENE.instantiate()
			as RuleDeleteButton
		)
		button.text = rules[index].title
		button.set_meta("rule_index", index)
		button.pressed.connect(rule_delete_requested.emit.bind(index))
		rule_delete_choices.add_child(button)
		if index < rules.size() - 1:
			var separator := Label.new()
			separator.text = "+"
			separator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			separator.add_theme_font_size_override("font_size", 20)
			separator.set_meta("separator_after", index)
			rule_delete_choices.add_child(separator)
	_update_delete_label(remaining)
	visible = true
	modulate.a = 0.0
	var entrance := create_tween()
	entrance.tween_property(self, "modulate:a", 1.0, fade_duration)
	await entrance.finished
	while remaining > 0:
		var selected_index: int = await rule_delete_requested
		if removed_indices.has(selected_index):
			continue
		var selected_button := _find_delete_button(selected_index)
		if selected_button == null or not selected_button.visible:
			continue
		for child in rule_delete_choices.get_children():
			if child is Button:
				(child as Button).disabled = true
		selected_button.struck_through = true
		selected_button.queue_redraw()
		await get_tree().create_timer(
			rule_delete_confirmation_delay
		).timeout
		var removal := create_tween().set_parallel()
		removal.tween_property(
			selected_button,
			"modulate:a",
			0.0,
			rule_delete_fade_duration
		)
		removal.tween_property(
			selected_button,
			"scale:x",
			0.75,
			rule_delete_fade_duration
		)
		await removal.finished
		selected_button.visible = false
		selected_button.struck_through = false
		selected_button.queue_redraw()
		removed_indices.append(selected_index)
		remaining -= 1
		_refresh_delete_separators()
		_refresh_delete_combo_title(rules, removed_indices)
		if remaining > 0:
			_update_delete_label(remaining)
		for child in rule_delete_choices.get_children():
			if not child is Button:
				continue
			var child_button := child as Button
			if child_button is RuleDeleteButton:
				(child_button as RuleDeleteButton).struck_through = false
				child_button.queue_redraw()
			if child_button.visible and remaining > 0:
				child_button.disabled = false
	if remaining == 0:
		for child in rule_delete_choices.get_children():
			if child is RuleDeleteButton:
				var rule_button := child as RuleDeleteButton
				rule_button.disabled = true
				rule_button.struck_through = false
				rule_button.queue_redraw()
		await _hide_delete_counter()
	await get_tree().create_timer(rule_breaker_final_delay).timeout
	var exit := create_tween()
	exit.tween_property(self, "modulate:a", 0.0, fade_duration)
	await exit.finished
	visible = false
	rules_label.visible = true
	subtitle_label.visible = true
	delete_label.visible = false
	rule_delete_choices.visible = false
	return removed_indices


func _find_delete_button(rule_index: int) -> RuleDeleteButton:
	for child in rule_delete_choices.get_children():
		if int(child.get_meta("rule_index", -1)) == rule_index:
			return child as RuleDeleteButton
	return null


func _update_delete_label(remaining: int) -> void:
	delete_label.text = "DELETE" if remaining == 1 else "DELETE %d" % remaining


func _hide_delete_counter() -> void:
	delete_label.pivot_offset = delete_label.size * 0.5
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_QUAD)
	tween.tween_property(
		delete_label,
		"modulate:a",
		0.0,
		delete_counter_fade_duration
	)
	tween.tween_property(
		delete_label,
		"scale",
		Vector2(0.82, 0.82),
		delete_counter_fade_duration
	)
	await tween.finished
	delete_label.visible = false
	delete_label.modulate = Color.WHITE
	delete_label.scale = Vector2.ONE


func _refresh_delete_separators() -> void:
	var visible_rule_indices: Array[int] = []
	for child in rule_delete_choices.get_children():
		if child is RuleDeleteButton and child.visible:
			visible_rule_indices.append(
				int(child.get_meta("rule_index", -1))
			)
	for child in rule_delete_choices.get_children():
		if not child.has_meta("separator_after"):
			continue
		var preceding_index := int(child.get_meta("separator_after"))
		(child as Control).visible = (
			visible_rule_indices.has(preceding_index)
			and visible_rule_indices.back() != preceding_index
		)


func _refresh_delete_combo_title(
	rules: Array[SpecialRuleData],
	removed_indices: Array[int]
) -> void:
	var remaining_rules: Array[SpecialRuleData] = []
	for index in rules.size():
		if not removed_indices.has(index):
			remaining_rules.append(rules[index])
	combo_label.text = _combination_title(remaining_rules)
	combo_label.visible = not combo_label.text.is_empty()


func _combination_title(rules: Array[SpecialRuleData]) -> String:
	var ids: Array[StringName] = []
	for rule in rules:
		ids.append(rule.id)
	if ids.has(&"lights_out") and ids.has(&"peek_a_card"):
		return "BLIND DATE"
	if ids.has(&"pile_up") and ids.has(&"stack_attack"):
		return "ONE STEP FORWARD..."
	if ids.has(&"roman_holiday") and ids.has(&"pile_up"):
		return "THE EMPIRE RISES"
	if ids.has(&"shell_game") and ids.has(&"roman_holiday"):
		return "ET TU, STACK?"
	if ids.has(&"free_range_cards") and ids.has(&"peek_a_card"):
		return "CARDIO TRAINING"
	if ids.has(&"lights_out") and ids.has(&"stack_attack"):
		return "FEAR OF THE STACK"
	if ids.has(&"musical_stacks") and ids.has(&"mirror_match"):
		return "DANCE LIKE NOBODY'S WATCHING"
	if ids.has(&"sticky_fingers") and ids.has(&"hot_potatoes"):
		return "HANDS FULL"
	if ids.has(&"blind_delivery") and ids.has(&"peek_a_card"):
		return "LOOK, DON'T CARRY"
	if ids.has(&"blind_delivery") and ids.has(&"mirror_match"):
		return "WRONG ADDRESS"
	if ids.has(&"sudden_death") and ids.has(&"grace_period"):
		return "SURPRISE EXAM"
	if ids.has(&"colorblind") and ids.has(&"mirror_match"):
		return "GREY MATTER"
	if ids.has(&"floor_is_lava") and ids.has(&"hot_potatoes"):
		return "TOO HOT TO HANDLE"
	if ids.has(&"floor_is_lava") and ids.has(&"sticky_fingers"):
		return "COMMITMENT ISSUES"
	if ids.has(&"musical_stacks") and ids.has(&"floor_is_lava"):
		return "DANCE FLOOR"
	if ids.has(&"blind_delivery") and ids.has(&"hot_potatoes"):
		return "EXPRESS SHIPPING"
	if ids.has(&"sudden_death") and ids.has(&"floor_is_lava"):
		return "ONE-WAY TICKET"
	return ""
