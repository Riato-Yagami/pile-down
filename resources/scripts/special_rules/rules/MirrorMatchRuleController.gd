class_name MirrorMatchRuleController
extends Node


func begin_round(target: Control, modifiers: RoundModifiers) -> void:
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2(
		-1.0 if modifiers.mirror_horizontal else 1.0,
		-1.0 if modifiers.mirror_vertical else 1.0
	)


func end_round(target: Control) -> void:
	target.scale = Vector2.ONE
	target.pivot_offset = target.size * 0.5
