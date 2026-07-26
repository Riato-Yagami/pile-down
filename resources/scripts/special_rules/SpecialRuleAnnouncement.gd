class_name SpecialRuleAnnouncement
extends Control

@onready var combo_label: Label = %ComboLabel
@onready var rules_label: Label = %RulesLabel
@onready var subtitle_label: Label = %SubtitleLabel


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
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	visible = false


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
