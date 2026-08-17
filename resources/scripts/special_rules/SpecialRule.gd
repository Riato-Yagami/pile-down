class_name SpecialRule
extends Data

@export var title: String
@export var subtitle: String
@export_multiline var description: String
@export var incompatible_rules: Array[StringName] = []
@export var required_rules: Array[StringName] = []
@export var minimum_round := 1
@export var weight := 1.0


func activate(_context: RoundContext) -> void:
	pass


func deactivate(_context: RoundContext) -> void:
	pass
